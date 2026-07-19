package config

import (
	"crypto/tls"
	"errors"
	"fmt"
	"net"
	"net/url"
	"path/filepath"
	"strconv"
	"strings"
	"time"
	"unicode"

	gonats "github.com/nats-io/nats.go"
)

const (
	developmentNATSURL       = "nats://localhost:4222"
	maximumNATSServerCount   = 8
	maximumNATSURLBytes      = 2_048
	maximumNATSPathBytes     = 4_096
	minimumSecureNATSReplica = 3
)

// NATSConfig contains transport settings only. Credentials are loaded from a
// mounted NATS credentials file and are never accepted inline in NATS_URL.
type NATSConfig struct {
	URL             string        `env:"NATS_URL, default="`
	CredentialsFile string        `env:"NATS_CREDENTIALS_FILE, default="`
	CACertPath      string        `env:"NATS_CA_CERT_PATH, default="`
	ClientCertPath  string        `env:"NATS_CLIENT_CERT_PATH, default="`
	ClientKeyPath   string        `env:"NATS_CLIENT_KEY_PATH, default="`
	TLSServerName   string        `env:"NATS_TLS_SERVER_NAME, default="`
	ConnectTimeout  time.Duration `env:"NATS_CONNECT_TIMEOUT, default=3s"`
	ReconnectWait   time.Duration `env:"NATS_RECONNECT_WAIT, default=1s"`
	MaxReconnects   int           `env:"NATS_MAX_RECONNECTS, default=120"`
	PingInterval    time.Duration `env:"NATS_PING_INTERVAL, default=20s"`
	MaxPingsOut     int           `env:"NATS_MAX_PINGS_OUT, default=2"`
	StreamReplicas  int           `env:"SAVED_DOMAIN_STREAM_REPLICAS, default=1"`
}

func (NATSConfig) String() string {
	return "NATSConfig{endpoints=redacted credentials=redacted tls=redacted}"
}

func (cfg NATSConfig) GoString() string {
	return cfg.String()
}

func (cfg NATSConfig) Validate(secureEnvironment bool) error {
	usesTLS, err := validateNATSServers(cfg.URL, secureEnvironment)
	if err != nil {
		return err
	}
	if err = validateNATSTransportLimits(cfg, secureEnvironment); err != nil {
		return err
	}

	tlsValues := []struct {
		name  string
		value string
	}{
		{name: "NATS_CREDENTIALS_FILE", value: cfg.CredentialsFile},
		{name: "NATS_CA_CERT_PATH", value: cfg.CACertPath},
		{name: "NATS_CLIENT_CERT_PATH", value: cfg.ClientCertPath},
		{name: "NATS_CLIENT_KEY_PATH", value: cfg.ClientKeyPath},
	}
	if !usesTLS {
		for _, item := range tlsValues {
			if item.value != "" {
				return fmt.Errorf("%s requires TLS NATS endpoints", item.name)
			}
		}
		if cfg.TLSServerName != "" {
			return errors.New("NATS_TLS_SERVER_NAME requires TLS NATS endpoints")
		}
		return nil
	}

	for _, item := range tlsValues {
		if err = validateAbsoluteSecretPath(item.name, item.value); err != nil {
			return err
		}
	}
	if cfg.TLSServerName != strings.TrimSpace(cfg.TLSServerName) ||
		validateTLSServerName(cfg.TLSServerName, secureEnvironment) != nil {
		return errors.New("NATS_TLS_SERVER_NAME is invalid")
	}
	return nil
}

// NATSConnectionOptions returns bounded, reconnecting NATS options. Config
// validation is repeated so callers cannot accidentally bypass TLS policy.
func (cfg Config) NATSConnectionOptions() ([]gonats.Option, error) {
	environment := strings.ToLower(strings.TrimSpace(cfg.App.Env))
	if !isAllowedEnvironment(environment) {
		return nil, errors.New("APP_ENV is invalid for NATS transport policy")
	}
	if err := cfg.NATS.Validate(cfg.App.IsSecureEnvironment()); err != nil {
		return nil, err
	}

	options := []gonats.Option{
		gonats.Name(serviceName),
		gonats.Timeout(cfg.NATS.ConnectTimeout),
		gonats.ReconnectWait(cfg.NATS.ReconnectWait),
		gonats.MaxReconnects(cfg.NATS.MaxReconnects),
		gonats.PingInterval(cfg.NATS.PingInterval),
		gonats.MaxPingsOutstanding(cfg.NATS.MaxPingsOut),
		gonats.NoEcho(),
	}
	if !natsURLUsesTLS(cfg.NATS.URL) {
		return options, nil
	}

	options = append(options,
		gonats.Secure(cfg.NATS.clientTLSConfig()),
		gonats.RootCAs(cfg.NATS.CACertPath),
		gonats.ClientCert(cfg.NATS.ClientCertPath, cfg.NATS.ClientKeyPath),
		gonats.UserCredentials(cfg.NATS.CredentialsFile),
	)
	return options, nil
}

func (cfg NATSConfig) clientTLSConfig() *tls.Config {
	return &tls.Config{
		MinVersion: tls.VersionTLS13,
		ServerName: cfg.TLSServerName,
	}
}

func validateNATSServers(rawServers string, secureEnvironment bool) (bool, error) {
	if rawServers == "" || rawServers != strings.TrimSpace(rawServers) ||
		len(rawServers) > maximumNATSURLBytes || strings.IndexFunc(rawServers, unicode.IsControl) >= 0 {
		return false, errors.New("NATS_URL is invalid")
	}

	servers := strings.Split(rawServers, ",")
	if len(servers) == 0 || len(servers) > maximumNATSServerCount {
		return false, fmt.Errorf("NATS_URL must contain between 1 and %d endpoints", maximumNATSServerCount)
	}

	seen := make(map[string]struct{}, len(servers))
	var expectedScheme string
	for _, rawServer := range servers {
		if rawServer == "" || rawServer != strings.TrimSpace(rawServer) {
			return false, errors.New("NATS_URL endpoints must not contain surrounding whitespace")
		}
		parsed, err := url.ParseRequestURI(rawServer)
		if err != nil || parsed == nil || !parsed.IsAbs() || parsed.Host == "" || parsed.Hostname() == "" {
			return false, errors.New("NATS_URL must contain absolute NATS endpoints")
		}
		scheme := strings.ToLower(parsed.Scheme)
		if scheme != "nats" && scheme != "tls" {
			return false, errors.New("NATS_URL endpoints must use nats or tls scheme")
		}
		if secureEnvironment && scheme != "tls" {
			return false, errors.New("NATS_URL must use TLS endpoints in staging and production")
		}
		if expectedScheme == "" {
			expectedScheme = scheme
		} else if scheme != expectedScheme {
			return false, errors.New("NATS_URL must not mix plaintext and TLS endpoints")
		}
		if parsed.User != nil || parsed.Path != "" || parsed.RawQuery != "" || parsed.ForceQuery || parsed.Fragment != "" {
			return false, errors.New("NATS_URL endpoints must not contain credentials, path, query, or fragment")
		}
		host, portText, err := net.SplitHostPort(parsed.Host)
		if err != nil || host == "" || host == "*" {
			return false, errors.New("NATS_URL endpoints must contain an explicit host and port")
		}
		port, err := strconv.Atoi(portText)
		if err != nil || !isValidPort(port) {
			return false, errors.New("NATS_URL endpoint port is invalid")
		}
		if secureEnvironment && isUnsafeProductionHost(parsed.Hostname()) {
			return false, errors.New("NATS_URL must not use loopback or unspecified hosts in staging and production")
		}
		normalized := strings.ToLower(parsed.String())
		if _, duplicate := seen[normalized]; duplicate {
			return false, errors.New("NATS_URL endpoints must be unique")
		}
		seen[normalized] = struct{}{}
	}
	return expectedScheme == "tls", nil
}

func validateNATSTransportLimits(cfg NATSConfig, secureEnvironment bool) error {
	switch {
	case cfg.ConnectTimeout < 100*time.Millisecond || cfg.ConnectTimeout > 10*time.Second:
		return errors.New("NATS_CONNECT_TIMEOUT must be within [100ms, 10s]")
	case cfg.ReconnectWait < 100*time.Millisecond || cfg.ReconnectWait > 30*time.Second:
		return errors.New("NATS_RECONNECT_WAIT must be within [100ms, 30s]")
	case cfg.MaxReconnects < 1 || cfg.MaxReconnects > 10_000:
		return errors.New("NATS_MAX_RECONNECTS must be within [1, 10000]")
	case cfg.PingInterval < 5*time.Second || cfg.PingInterval > 2*time.Minute:
		return errors.New("NATS_PING_INTERVAL must be within [5s, 2m]")
	case cfg.MaxPingsOut < 1 || cfg.MaxPingsOut > 10:
		return errors.New("NATS_MAX_PINGS_OUT must be within [1, 10]")
	case cfg.StreamReplicas != 1 && cfg.StreamReplicas != 3 && cfg.StreamReplicas != 5:
		return errors.New("SAVED_DOMAIN_STREAM_REPLICAS must be 1, 3, or 5")
	case secureEnvironment && cfg.StreamReplicas < minimumSecureNATSReplica:
		return errors.New("SAVED_DOMAIN_STREAM_REPLICAS must be at least 3 in staging and production")
	default:
		return nil
	}
}

func validateAbsoluteSecretPath(name, value string) error {
	if value == "" || value != strings.TrimSpace(value) || len(value) > maximumNATSPathBytes ||
		strings.IndexFunc(value, unicode.IsControl) >= 0 || !filepath.IsAbs(value) || filepath.Clean(value) != value {
		return fmt.Errorf("%s must be a clean absolute mounted-secret path", name)
	}
	return nil
}

func natsURLUsesTLS(rawServers string) bool {
	first, _, _ := strings.Cut(rawServers, ",")
	parsed, err := url.ParseRequestURI(first)
	return err == nil && parsed != nil && strings.EqualFold(parsed.Scheme, "tls")
}
