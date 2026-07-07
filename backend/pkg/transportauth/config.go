package transportauth

import (
	"crypto/tls"
	"crypto/x509"
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
)

type Mode string

const (
	ModeDisabled   Mode = "disabled"
	ModePermissive Mode = "permissive"
	ModeEnforce    Mode = "enforce"
)

type Config struct {
	Mode Mode

	CACertPath string

	ServerCertPath string
	ServerKeyPath  string

	ClientCertPath string
	ClientKeyPath  string
	ServerName     string
	MinVersion     string

	AllowedSPIFFEIDs []string
	AllowedDNSNames  []string
}

type EnvConfig struct {
	Mode string `env:"MTLS_MODE, default=disabled"`

	CACertPath string `env:"MTLS_CA_CERT_PATH, default="`

	ServerCertPath string `env:"MTLS_SERVER_CERT_PATH, default="`
	ServerKeyPath  string `env:"MTLS_SERVER_KEY_PATH, default="`

	ClientCertPath string `env:"MTLS_CLIENT_CERT_PATH, default="`
	ClientKeyPath  string `env:"MTLS_CLIENT_KEY_PATH, default="`
	ServerName     string `env:"MTLS_SERVER_NAME, default="`
	MinVersion     string `env:"MTLS_MIN_VERSION, default=1.3"`

	AllowedSPIFFEIDs string `env:"MTLS_ALLOWED_SPIFFE_IDS, default="`
	AllowedDNSNames  string `env:"MTLS_ALLOWED_DNS_NAMES, default="`
}

func (e EnvConfig) ServerConfig() Config {
	return Config{
		Mode:             Mode(strings.TrimSpace(e.Mode)),
		CACertPath:       e.CACertPath,
		ServerCertPath:   e.ServerCertPath,
		ServerKeyPath:    e.ServerKeyPath,
		ClientCertPath:   e.ClientCertPath,
		ClientKeyPath:    e.ClientKeyPath,
		ServerName:       strings.TrimSpace(e.ServerName),
		MinVersion:       strings.TrimSpace(e.MinVersion),
		AllowedSPIFFEIDs: splitList(e.AllowedSPIFFEIDs),
		AllowedDNSNames:  splitList(e.AllowedDNSNames),
	}
}

func (e EnvConfig) ClientConfig(defaultServerName string) Config {
	cfg := e.ServerConfig()
	cfg.ServerName = strings.TrimSpace(e.ServerName)
	if cfg.ServerName == "" {
		cfg.ServerName = strings.TrimSpace(defaultServerName)
	}
	return cfg
}

func (c Config) ServerTLSConfig() (*tls.Config, error) {
	mode := normalizeMode(c.Mode)
	if mode == ModeDisabled {
		return nil, nil
	}

	minVersion, err := parseTLSMinVersion(c.MinVersion)
	if err != nil {
		return nil, err
	}
	serverCertificate, err := newKeyPairReloader(c.ServerCertPath, c.ServerKeyPath)
	if err != nil {
		return nil, err
	}
	certificate, err := serverCertificate.get()
	if err != nil {
		return nil, err
	}
	clientCAs, err := loadCertPool(c.CACertPath)
	if err != nil {
		return nil, err
	}

	clientAuth := tls.VerifyClientCertIfGiven
	if mode == ModeEnforce {
		clientAuth = tls.RequireAndVerifyClientCert
	}

	return &tls.Config{
		MinVersion:   minVersion,
		Certificates: []tls.Certificate{certificate},
		ClientCAs:    clientCAs,
		ClientAuth:   clientAuth,
		GetCertificate: func(*tls.ClientHelloInfo) (*tls.Certificate, error) {
			certificate, err := serverCertificate.get()
			if err != nil {
				return nil, err
			}
			return &certificate, nil
		},
		VerifyConnection: func(state tls.ConnectionState) error {
			return verifyPeerIdentity(state, mode, c.AllowedSPIFFEIDs, c.AllowedDNSNames)
		},
	}, nil
}

func (c Config) ClientTLSConfig() (*tls.Config, error) {
	mode := normalizeMode(c.Mode)
	if mode == ModeDisabled {
		return nil, nil
	}

	minVersion, err := parseTLSMinVersion(c.MinVersion)
	if err != nil {
		return nil, err
	}
	rootCAs, err := loadCertPool(c.CACertPath)
	if err != nil {
		return nil, err
	}

	tlsConfig := &tls.Config{
		MinVersion: minVersion,
		RootCAs:    rootCAs,
		ServerName: strings.TrimSpace(c.ServerName),
	}

	if strings.TrimSpace(c.ClientCertPath) != "" || strings.TrimSpace(c.ClientKeyPath) != "" {
		clientCertificate, err := newKeyPairReloader(c.ClientCertPath, c.ClientKeyPath)
		if err != nil {
			return nil, err
		}
		certificate, err := clientCertificate.get()
		if err != nil {
			return nil, err
		}
		tlsConfig.Certificates = []tls.Certificate{certificate}
		tlsConfig.GetClientCertificate = func(*tls.CertificateRequestInfo) (*tls.Certificate, error) {
			certificate, err := clientCertificate.get()
			if err != nil {
				return nil, err
			}
			return &certificate, nil
		}
	}

	return tlsConfig, nil
}

func NewHTTPClient(cfg Config, timeout time.Duration) (*http.Client, error) {
	if timeout <= 0 {
		timeout = 10 * time.Second
	}

	tlsConfig, err := cfg.ClientTLSConfig()
	if err != nil {
		return nil, err
	}
	if tlsConfig == nil {
		return &http.Client{Timeout: timeout}, nil
	}
	transport, err := NewHTTPTransport(cfg, nil)
	if err != nil {
		return nil, err
	}
	return &http.Client{
		Timeout:   timeout,
		Transport: transport,
	}, nil
}

func NewHTTPTransport(cfg Config, base *http.Transport) (*http.Transport, error) {
	tlsConfig, err := cfg.ClientTLSConfig()
	if err != nil {
		return nil, err
	}

	if base == nil {
		if defaultTransport, ok := http.DefaultTransport.(*http.Transport); ok {
			base = defaultTransport
		} else {
			base = &http.Transport{}
		}
	}
	transport := base.Clone()
	if tlsConfig != nil {
		transport.TLSClientConfig = tlsConfig
	}
	return transport, nil
}

func GRPCDialOptions(cfg Config) ([]grpc.DialOption, error) {
	tlsConfig, err := cfg.ClientTLSConfig()
	if err != nil {
		return nil, err
	}
	if tlsConfig == nil {
		return []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}, nil
	}
	return []grpc.DialOption{grpc.WithTransportCredentials(credentials.NewTLS(tlsConfig))}, nil
}

func GRPCServerOptions(cfg Config) ([]grpc.ServerOption, error) {
	tlsConfig, err := cfg.ServerTLSConfig()
	if err != nil {
		return nil, err
	}
	if tlsConfig == nil {
		return nil, nil
	}
	return []grpc.ServerOption{grpc.Creds(credentials.NewTLS(tlsConfig))}, nil
}

func ServerNameFromTarget(target string) string {
	target = strings.TrimSpace(target)
	if target == "" {
		return ""
	}

	if strings.Contains(target, "://") {
		parsed, err := url.Parse(target)
		if err == nil {
			return strings.Trim(parsed.Hostname(), "[]")
		}
	}

	if host, _, err := net.SplitHostPort(target); err == nil {
		return strings.Trim(host, "[]")
	}

	if idx := strings.IndexAny(target, "/?"); idx >= 0 {
		target = target[:idx]
	}
	return strings.Trim(target, "[]")
}

func normalizeMode(mode Mode) Mode {
	switch Mode(strings.ToLower(strings.TrimSpace(string(mode)))) {
	case ModePermissive:
		return ModePermissive
	case ModeEnforce:
		return ModeEnforce
	default:
		return ModeDisabled
	}
}

func parseTLSMinVersion(version string) (uint16, error) {
	version = strings.ToLower(strings.TrimSpace(version))
	if version == "" {
		return tls.VersionTLS13, nil
	}
	switch strings.ReplaceAll(version, " ", "") {
	case "1.3", "tls1.3", "tls13", "tlsv1.3":
		return tls.VersionTLS13, nil
	default:
		return 0, fmt.Errorf("unsupported mTLS minimum TLS version %q: only TLS 1.3 is allowed", version)
	}
}

type keyPairReloader struct {
	certPath string
	keyPath  string

	mu          sync.Mutex
	certificate tls.Certificate
	certModTime time.Time
	keyModTime  time.Time
}

func newKeyPairReloader(certPath string, keyPath string) (*keyPairReloader, error) {
	certPath = strings.TrimSpace(certPath)
	keyPath = strings.TrimSpace(keyPath)
	if certPath == "" || keyPath == "" {
		return nil, errors.New("mTLS certificate and key paths are required")
	}
	reloader := &keyPairReloader{
		certPath: certPath,
		keyPath:  keyPath,
	}
	if _, err := reloader.get(); err != nil {
		return nil, err
	}
	return reloader, nil
}

func (r *keyPairReloader) get() (tls.Certificate, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	certInfo, err := os.Stat(r.certPath)
	if err != nil {
		return tls.Certificate{}, fmt.Errorf("stat mTLS certificate: %w", err)
	}
	keyInfo, err := os.Stat(r.keyPath)
	if err != nil {
		return tls.Certificate{}, fmt.Errorf("stat mTLS key: %w", err)
	}
	if len(r.certificate.Certificate) > 0 &&
		certInfo.ModTime().Equal(r.certModTime) &&
		keyInfo.ModTime().Equal(r.keyModTime) {
		return r.certificate, nil
	}

	certificate, err := tls.LoadX509KeyPair(r.certPath, r.keyPath)
	if err != nil {
		return tls.Certificate{}, fmt.Errorf("load mTLS key pair: %w", err)
	}
	r.certificate = certificate
	r.certModTime = certInfo.ModTime()
	r.keyModTime = keyInfo.ModTime()
	return certificate, nil
}

func loadCertPool(path string) (*x509.CertPool, error) {
	path = strings.TrimSpace(path)
	if path == "" {
		return nil, errors.New("mTLS CA certificate path is required")
	}
	pemBytes, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read mTLS CA certificate: %w", err)
	}
	pool := x509.NewCertPool()
	if !pool.AppendCertsFromPEM(pemBytes) {
		return nil, errors.New("parse mTLS CA certificate: no PEM certificates found")
	}
	return pool, nil
}

func verifyPeerIdentity(state tls.ConnectionState, mode Mode, allowedSPIFFEIDs []string, allowedDNSNames []string) error {
	if len(state.PeerCertificates) == 0 {
		if mode == ModeEnforce {
			return errors.New("mTLS client certificate is required")
		}
		log.Printf("mTLS peer identity absent mode=%s tls_version=%s", mode, tlsVersionName(state.Version))
		return nil
	}
	leaf := state.PeerCertificates[0]
	spiffeIDs := peerSPIFFEIDs(leaf)
	if len(allowedSPIFFEIDs) == 0 && len(allowedDNSNames) == 0 {
		log.Printf(
			"mTLS peer identity accepted spiffe_ids=%s dns_names=%s tls_version=%s",
			strings.Join(spiffeIDs, ","),
			strings.Join(leaf.DNSNames, ","),
			tlsVersionName(state.Version),
		)
		return nil
	}

	allowedSPIFFE := stringSet(allowedSPIFFEIDs)
	for _, uri := range leaf.URIs {
		if _, ok := allowedSPIFFE[uri.String()]; ok {
			log.Printf(
				"mTLS peer identity accepted spiffe_ids=%s dns_names=%s tls_version=%s",
				strings.Join(spiffeIDs, ","),
				strings.Join(leaf.DNSNames, ","),
				tlsVersionName(state.Version),
			)
			return nil
		}
	}

	allowedDNS := stringSet(allowedDNSNames)
	for _, dnsName := range leaf.DNSNames {
		if _, ok := allowedDNS[dnsName]; ok {
			log.Printf(
				"mTLS peer identity accepted spiffe_ids=%s dns_names=%s tls_version=%s",
				strings.Join(spiffeIDs, ","),
				strings.Join(leaf.DNSNames, ","),
				tlsVersionName(state.Version),
			)
			return nil
		}
	}

	err := fmt.Errorf(
		"mTLS peer identity is not allowed: spiffe_ids=%s dns_names=%s tls_version=%s",
		strings.Join(spiffeIDs, ","),
		strings.Join(leaf.DNSNames, ","),
		tlsVersionName(state.Version),
	)
	log.Print(err.Error())
	return err
}

func stringSet(values []string) map[string]struct{} {
	result := make(map[string]struct{}, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value != "" {
			result[value] = struct{}{}
		}
	}
	return result
}

func peerSPIFFEIDs(certificate *x509.Certificate) []string {
	result := make([]string, 0, len(certificate.URIs))
	for _, uri := range certificate.URIs {
		result = append(result, uri.String())
	}
	return result
}

func tlsVersionName(version uint16) string {
	switch version {
	case tls.VersionTLS13:
		return "TLS1.3"
	case tls.VersionTLS12:
		return "TLS1.2"
	case tls.VersionTLS11:
		return "TLS1.1"
	case tls.VersionTLS10:
		return "TLS1.0"
	default:
		return fmt.Sprintf("0x%x", version)
	}
}

func splitList(raw string) []string {
	if strings.TrimSpace(raw) == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			result = append(result, part)
		}
	}
	return result
}
