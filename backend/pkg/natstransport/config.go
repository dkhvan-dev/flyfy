package natstransport

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/nats-io/nkeys"
)

// EnvConfig is the shared environment contract for Saved lifecycle NATS clients.
type EnvConfig struct {
	URLs            string        `env:"NATS_URL"`
	CredentialsPath string        `env:"NATS_CREDS_PATH"`
	CACertPath      string        `env:"NATS_CA_CERT_PATH"`
	ClientCertPath  string        `env:"NATS_CLIENT_CERT_PATH"`
	ClientKeyPath   string        `env:"NATS_CLIENT_KEY_PATH"`
	TLSServerName   string        `env:"NATS_TLS_SERVER_NAME"`
	TLSMinVersion   string        `env:"NATS_TLS_MIN_VERSION, default=1.3"`
	ConnectTimeout  time.Duration `env:"SAVED_LIFECYCLE_NATS_CONNECT_TIMEOUT, default=3s"`
	ReconnectWait   time.Duration `env:"SAVED_LIFECYCLE_NATS_RECONNECT_WAIT, default=1s"`
	MaxReconnects   int           `env:"SAVED_LIFECYCLE_NATS_MAX_RECONNECTS, default=30"`
	PingInterval    time.Duration `env:"SAVED_LIFECYCLE_NATS_PING_INTERVAL, default=20s"`
	MaxPingsOut     int           `env:"SAVED_LIFECYCLE_NATS_MAX_PINGS_OUT, default=2"`
	DrainTimeout    time.Duration `env:"SAVED_LIFECYCLE_NATS_DRAIN_TIMEOUT, default=5s"`
}

// Config is a validated, redaction-safe connection configuration.
type Config struct {
	Environment     string
	URLs            string
	CredentialsPath string
	CACertPath      string
	ClientCertPath  string
	ClientKeyPath   string
	TLSServerName   string
	TLSMinVersion   string
	ConnectTimeout  time.Duration
	ReconnectWait   time.Duration
	MaxReconnects   int
	PingInterval    time.Duration
	MaxPingsOut     int
	DrainTimeout    time.Duration
}

type preparedConfig struct {
	endpoints []string
	secure    bool
	tls       *tls.Config
}

// Build applies the service's existing local endpoint only in explicitly local
// environments. Staging and production never inherit a plaintext default.
func (e EnvConfig) Build(environment, developmentURL string) (Config, error) {
	secureEnvironment, err := environmentRequiresTLS(environment)
	if err != nil {
		return Config{}, err
	}
	urls := strings.TrimSpace(e.URLs)
	if urls == "" && !secureEnvironment {
		urls = strings.TrimSpace(developmentURL)
	}
	cfg := Config{
		Environment:     environment,
		URLs:            urls,
		CredentialsPath: strings.TrimSpace(e.CredentialsPath),
		CACertPath:      strings.TrimSpace(e.CACertPath),
		ClientCertPath:  strings.TrimSpace(e.ClientCertPath),
		ClientKeyPath:   strings.TrimSpace(e.ClientKeyPath),
		TLSServerName:   strings.TrimSpace(e.TLSServerName),
		TLSMinVersion:   strings.TrimSpace(e.TLSMinVersion),
		ConnectTimeout:  e.ConnectTimeout,
		ReconnectWait:   e.ReconnectWait,
		MaxReconnects:   e.MaxReconnects,
		PingInterval:    e.PingInterval,
		MaxPingsOut:     e.MaxPingsOut,
		DrainTimeout:    e.DrainTimeout,
	}
	if err := cfg.Validate(); err != nil {
		return Config{}, err
	}
	return cfg, nil
}

func (c Config) Validate() error {
	_, err := c.prepare()
	return err
}

func (e EnvConfig) String() string {
	return redactedConfigString(e.URLs, e.CredentialsPath != "", e.CACertPath != "")
}

func (e EnvConfig) GoString() string {
	return e.String()
}

func (c Config) String() string {
	return redactedConfigString(c.URLs, c.CredentialsPath != "", c.CACertPath != "")
}

func (c Config) GoString() string {
	return c.String()
}

func redactedConfigString(rawURLs string, hasCredentials, hasTLSMaterial bool) string {
	endpointCount := 0
	for _, endpoint := range strings.Split(rawURLs, ",") {
		if strings.TrimSpace(endpoint) != "" {
			endpointCount++
		}
	}
	return fmt.Sprintf(
		"natstransport.Config{endpoints:%d, credentials:%t, tls_material:%t, secrets:<redacted>}",
		endpointCount,
		hasCredentials,
		hasTLSMaterial,
	)
}

func (c Config) prepare() (preparedConfig, error) {
	secureEnvironment, err := environmentRequiresTLS(c.Environment)
	if err != nil {
		return preparedConfig{}, err
	}
	if err := validateBounds(c); err != nil {
		return preparedConfig{}, err
	}
	endpoints, scheme, err := parseEndpoints(c.URLs)
	if err != nil {
		return preparedConfig{}, err
	}
	secure := scheme == "tls"
	if secureEnvironment && !secure {
		return preparedConfig{}, errors.New("NATS_URL must contain only tls:// endpoints in staging and production")
	}
	if !secure {
		if hasSecurityMaterial(c) {
			return preparedConfig{}, errors.New("NATS credentials and TLS material require tls:// endpoints")
		}
		return preparedConfig{endpoints: endpoints}, nil
	}
	if c.TLSMinVersion != "1.3" {
		return preparedConfig{}, errors.New("NATS_TLS_MIN_VERSION must be 1.3")
	}
	if c.CredentialsPath == "" || c.CACertPath == "" ||
		c.ClientCertPath == "" || c.ClientKeyPath == "" || c.TLSServerName == "" {
		return preparedConfig{}, errors.New("tls NATS requires creds, CA, client certificate, client key, and server name")
	}
	if err := validateServerName(c.TLSServerName); err != nil {
		return preparedConfig{}, err
	}
	if err := validateCredentials(c.CredentialsPath); err != nil {
		return preparedConfig{}, err
	}
	tlsConfig, err := loadTLSConfig(c)
	if err != nil {
		return preparedConfig{}, err
	}
	return preparedConfig{endpoints: endpoints, secure: true, tls: tlsConfig}, nil
}

func environmentRequiresTLS(environment string) (bool, error) {
	switch strings.ToLower(strings.TrimSpace(environment)) {
	case "production", "prod", "staging", "stage":
		return true, nil
	case "development", "dev", "local", "test", "testing":
		return false, nil
	default:
		return false, errors.New("unsupported application environment for NATS transport")
	}
}

func validateBounds(c Config) error {
	switch {
	case c.ConnectTimeout < 100*time.Millisecond || c.ConnectTimeout > 30*time.Second:
		return errors.New("SAVED_LIFECYCLE_NATS_CONNECT_TIMEOUT must be in [100ms,30s]")
	case c.ReconnectWait < 100*time.Millisecond || c.ReconnectWait > 30*time.Second:
		return errors.New("SAVED_LIFECYCLE_NATS_RECONNECT_WAIT must be in [100ms,30s]")
	case c.MaxReconnects < 0 || c.MaxReconnects > 100:
		return errors.New("SAVED_LIFECYCLE_NATS_MAX_RECONNECTS must be in [0,100]")
	case c.PingInterval < time.Second || c.PingInterval > 2*time.Minute:
		return errors.New("SAVED_LIFECYCLE_NATS_PING_INTERVAL must be in [1s,2m]")
	case c.MaxPingsOut < 1 || c.MaxPingsOut > 10:
		return errors.New("SAVED_LIFECYCLE_NATS_MAX_PINGS_OUT must be in [1,10]")
	case c.DrainTimeout < time.Second || c.DrainTimeout > 30*time.Second:
		return errors.New("SAVED_LIFECYCLE_NATS_DRAIN_TIMEOUT must be in [1s,30s]")
	default:
		return nil
	}
}

func parseEndpoints(raw string) ([]string, string, error) {
	if strings.TrimSpace(raw) == "" {
		return nil, "", errors.New("NATS_URL is required")
	}
	parts := strings.Split(raw, ",")
	if len(parts) > 8 {
		return nil, "", errors.New("NATS_URL supports at most 8 endpoints")
	}
	endpoints := make([]string, 0, len(parts))
	seen := make(map[string]struct{}, len(parts))
	scheme := ""
	for _, part := range parts {
		endpoint, endpointScheme, err := parseEndpoint(strings.TrimSpace(part))
		if err != nil {
			return nil, "", err
		}
		if scheme != "" && scheme != endpointScheme {
			return nil, "", errors.New("NATS_URL cannot mix plaintext and TLS endpoint schemes")
		}
		scheme = endpointScheme
		if _, exists := seen[endpoint]; exists {
			return nil, "", errors.New("NATS_URL contains duplicate endpoints")
		}
		seen[endpoint] = struct{}{}
		endpoints = append(endpoints, endpoint)
	}
	return endpoints, scheme, nil
}

func parseEndpoint(raw string) (string, string, error) {
	if raw == "" {
		return "", "", errors.New("NATS_URL contains an empty endpoint")
	}
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Opaque != "" {
		return "", "", errors.New("NATS_URL contains a malformed endpoint")
	}
	scheme := strings.ToLower(parsed.Scheme)
	if scheme != "nats" && scheme != "tls" {
		return "", "", errors.New("NATS_URL endpoints must use nats:// or tls://")
	}
	if parsed.User != nil {
		return "", "", errors.New("inline NATS URL credentials are forbidden")
	}
	if parsed.RawQuery != "" || parsed.Fragment != "" || (parsed.Path != "" && parsed.Path != "/") {
		return "", "", errors.New("NATS_URL contains unsupported endpoint components")
	}
	hostname := strings.ToLower(strings.TrimSuffix(parsed.Hostname(), "."))
	if hostname == "" || strings.ContainsAny(hostname, " \t\r\n") {
		return "", "", errors.New("NATS_URL endpoint host is invalid")
	}
	port := parsed.Port()
	if port == "" {
		port = "4222"
	}
	portNumber, err := strconv.Atoi(port)
	if err != nil || portNumber < 1 || portNumber > 65535 {
		return "", "", errors.New("NATS_URL endpoint port is invalid")
	}
	return scheme + "://" + net.JoinHostPort(hostname, port), scheme, nil
}

func hasSecurityMaterial(c Config) bool {
	return c.CredentialsPath != "" || c.CACertPath != "" || c.ClientCertPath != "" ||
		c.ClientKeyPath != "" || c.TLSServerName != ""
}

func validateCredentials(path string) error {
	contents, err := readSecretFile(path, "NATS_CREDS_PATH")
	if err != nil {
		return err
	}
	jwt, err := nkeys.ParseDecoratedJWT(contents)
	if err != nil {
		return errors.New("NATS_CREDS_PATH contains malformed credentials")
	}
	parts := strings.Split(strings.TrimSpace(jwt), ".")
	if len(parts) != 3 || parts[0] == "" || parts[1] == "" || parts[2] == "" {
		return errors.New("NATS_CREDS_PATH contains malformed credentials")
	}
	var header struct {
		Type      string `json:"typ"`
		Algorithm string `json:"alg"`
	}
	var claims struct {
		Issuer  string `json:"iss"`
		Subject string `json:"sub"`
	}
	headerBytes, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil || json.Unmarshal(headerBytes, &header) != nil ||
		header.Type != "jwt" || header.Algorithm != "ed25519-nkey" {
		return errors.New("NATS_CREDS_PATH contains malformed credentials")
	}
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil || json.Unmarshal(payload, &claims) != nil || claims.Issuer == "" || claims.Subject == "" {
		return errors.New("NATS_CREDS_PATH contains malformed credentials")
	}
	signature, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil || len(signature) == 0 {
		return errors.New("NATS_CREDS_PATH contains malformed credentials")
	}
	issuerKey, err := nkeys.FromPublicKey(claims.Issuer)
	if err != nil {
		return errors.New("NATS_CREDS_PATH contains malformed credentials")
	}
	defer issuerKey.Wipe()
	if err = issuerKey.Verify([]byte(parts[0]+"."+parts[1]), signature); err != nil {
		return errors.New("NATS_CREDS_PATH contains invalid credentials")
	}
	keyPair, err := nkeys.ParseDecoratedUserNKey(contents)
	if err != nil {
		return errors.New("NATS_CREDS_PATH contains malformed credentials")
	}
	defer keyPair.Wipe()
	publicKey, err := keyPair.PublicKey()
	if err != nil || publicKey != claims.Subject {
		return errors.New("NATS_CREDS_PATH contains mismatched credentials")
	}
	return nil
}

func loadTLSConfig(c Config) (*tls.Config, error) {
	caPEM, err := readSecretFile(c.CACertPath, "NATS_CA_CERT_PATH")
	if err != nil {
		return nil, err
	}
	roots := x509.NewCertPool()
	if !roots.AppendCertsFromPEM(caPEM) {
		return nil, errors.New("NATS_CA_CERT_PATH does not contain a valid CA certificate")
	}
	certPEM, err := readSecretFile(c.ClientCertPath, "NATS_CLIENT_CERT_PATH")
	if err != nil {
		return nil, err
	}
	keyPEM, err := readSecretFile(c.ClientKeyPath, "NATS_CLIENT_KEY_PATH")
	if err != nil {
		return nil, err
	}
	certificate, err := tls.X509KeyPair(certPEM, keyPEM)
	if err != nil || len(certificate.Certificate) == 0 {
		return nil, errors.New("NATS client certificate or key is malformed")
	}
	leaf, err := x509.ParseCertificate(certificate.Certificate[0])
	if err != nil {
		return nil, errors.New("NATS client certificate is malformed")
	}
	intermediates := x509.NewCertPool()
	for _, encoded := range certificate.Certificate[1:] {
		intermediate, parseErr := x509.ParseCertificate(encoded)
		if parseErr != nil {
			return nil, errors.New("NATS client certificate chain is malformed")
		}
		intermediates.AddCert(intermediate)
	}
	if _, err = leaf.Verify(x509.VerifyOptions{
		Roots:         roots,
		Intermediates: intermediates,
		KeyUsages:     []x509.ExtKeyUsage{x509.ExtKeyUsageClientAuth},
	}); err != nil {
		return nil, errors.New("NATS client certificate is not valid for the configured CA")
	}
	certificate.Leaf = leaf
	return &tls.Config{
		MinVersion:   tls.VersionTLS13,
		ServerName:   c.TLSServerName,
		RootCAs:      roots,
		Certificates: []tls.Certificate{certificate},
	}, nil
}

func readSecretFile(path, variable string) ([]byte, error) {
	if path == "" || !filepath.IsAbs(path) {
		return nil, fmt.Errorf("%s must be an absolute mounted file path", variable)
	}
	info, err := os.Stat(path)
	if err != nil || !info.Mode().IsRegular() || info.Size() == 0 {
		return nil, fmt.Errorf("%s must reference a readable non-empty regular file", variable)
	}
	contents, err := os.ReadFile(path)
	if err != nil || len(contents) == 0 {
		return nil, fmt.Errorf("%s must reference a readable non-empty regular file", variable)
	}
	return contents, nil
}

func validateServerName(serverName string) error {
	if len(serverName) > 253 || strings.ContainsAny(serverName, " /:@\t\r\n") {
		return errors.New("NATS_TLS_SERVER_NAME is invalid")
	}
	if net.ParseIP(serverName) != nil {
		return nil
	}
	for _, label := range strings.Split(serverName, ".") {
		if label == "" || len(label) > 63 || label[0] == '-' || label[len(label)-1] == '-' {
			return errors.New("NATS_TLS_SERVER_NAME is invalid")
		}
		for _, character := range label {
			if (character < 'a' || character > 'z') &&
				(character < 'A' || character > 'Z') &&
				(character < '0' || character > '9') && character != '-' {
				return errors.New("NATS_TLS_SERVER_NAME is invalid")
			}
		}
	}
	return nil
}
