package config

import (
	"crypto/tls"
	"fmt"
	"strings"
	"testing"
	"time"

	gonats "github.com/nats-io/nats.go"
)

func TestNATSConfigAcceptsProductionTLSPolicy(t *testing.T) {
	cfg := validSecureNATSConfig()

	if err := cfg.Validate(true); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
}

func TestNATSConfigRejectsInsecureProductionTransport(t *testing.T) {
	tests := []struct {
		name    string
		mutate  func(*NATSConfig)
		wantErr string
	}{
		{
			name: "plaintext endpoint",
			mutate: func(cfg *NATSConfig) {
				cfg.URL = "nats://nats.internal:4222"
			},
			wantErr: "TLS endpoints",
		},
		{
			name: "inline credentials",
			mutate: func(cfg *NATSConfig) {
				cfg.URL = "tls://saved:secret@nats.internal:4222"
			},
			wantErr: "must not contain credentials",
		},
		{
			name: "missing credentials file",
			mutate: func(cfg *NATSConfig) {
				cfg.CredentialsFile = ""
			},
			wantErr: "NATS_CREDENTIALS_FILE",
		},
		{
			name: "missing CA",
			mutate: func(cfg *NATSConfig) {
				cfg.CACertPath = ""
			},
			wantErr: "NATS_CA_CERT_PATH",
		},
		{
			name: "missing client certificate",
			mutate: func(cfg *NATSConfig) {
				cfg.ClientCertPath = ""
			},
			wantErr: "NATS_CLIENT_CERT_PATH",
		},
		{
			name: "missing client key",
			mutate: func(cfg *NATSConfig) {
				cfg.ClientKeyPath = ""
			},
			wantErr: "NATS_CLIENT_KEY_PATH",
		},
		{
			name: "unsafe server name",
			mutate: func(cfg *NATSConfig) {
				cfg.TLSServerName = "localhost"
			},
			wantErr: "NATS_TLS_SERVER_NAME",
		},
		{
			name: "single replica",
			mutate: func(cfg *NATSConfig) {
				cfg.StreamReplicas = 1
			},
			wantErr: "at least 3",
		},
		{
			name: "relative secret path",
			mutate: func(cfg *NATSConfig) {
				cfg.CredentialsFile = "secrets/saved.creds"
			},
			wantErr: "absolute mounted-secret path",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			cfg := validSecureNATSConfig()
			test.mutate(&cfg)

			err := cfg.Validate(true)
			if err == nil || !strings.Contains(err.Error(), test.wantErr) {
				t.Fatalf("Validate() error = %v, want %q", err, test.wantErr)
			}
		})
	}
}

func TestNATSConfigRejectsMixedOrDuplicateEndpoints(t *testing.T) {
	tests := []struct {
		name string
		url  string
	}{
		{
			name: "mixed transport",
			url:  "tls://nats-a.internal:4222,nats://nats-b.internal:4222",
		},
		{
			name: "duplicate endpoint",
			url:  "tls://nats.internal:4222,tls://nats.internal:4222",
		},
		{
			name: "query",
			url:  "tls://nats.internal:4222?token=secret",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			cfg := validSecureNATSConfig()
			cfg.URL = test.url
			if err := cfg.Validate(true); err == nil {
				t.Fatal("Validate() error = nil, want rejection")
			}
		})
	}
}

func TestNATSConfigAllowsLocalPlaintextWithoutCredentials(t *testing.T) {
	cfg := NATSConfig{
		URL:            developmentNATSURL,
		ConnectTimeout: 3 * time.Second,
		ReconnectWait:  time.Second,
		MaxReconnects:  120,
		PingInterval:   20 * time.Second,
		MaxPingsOut:    2,
		StreamReplicas: 1,
	}

	if err := cfg.Validate(false); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
}

func TestNATSConnectionOptionsApplyBoundedDevelopmentSettings(t *testing.T) {
	natsConfig := NATSConfig{
		URL:            developmentNATSURL,
		ConnectTimeout: 4 * time.Second,
		ReconnectWait:  2 * time.Second,
		MaxReconnects:  77,
		PingInterval:   15 * time.Second,
		MaxPingsOut:    3,
		StreamReplicas: 1,
	}
	cfg := Config{App: AppConfig{Name: serviceName, Env: "development"}, NATS: natsConfig}

	options, err := cfg.NATSConnectionOptions()
	if err != nil {
		t.Fatalf("NATSConnectionOptions() error = %v", err)
	}
	applied := gonats.GetDefaultOptions()
	for _, option := range options {
		if err = option(&applied); err != nil {
			t.Fatalf("apply NATS option: %v", err)
		}
	}
	if applied.Name != serviceName || applied.Timeout != natsConfig.ConnectTimeout ||
		applied.ReconnectWait != natsConfig.ReconnectWait ||
		applied.MaxReconnect != natsConfig.MaxReconnects ||
		applied.PingInterval != natsConfig.PingInterval ||
		applied.MaxPingsOut != natsConfig.MaxPingsOut || !applied.NoEcho || applied.Secure {
		t.Fatalf("unexpected applied NATS options: %+v", applied)
	}
}

func TestNATSConnectionOptionsRejectsUnknownEnvironment(t *testing.T) {
	cfg := Config{
		App: AppConfig{Name: serviceName, Env: "prodution"},
		NATS: NATSConfig{
			URL:            developmentNATSURL,
			ConnectTimeout: 3 * time.Second,
			ReconnectWait:  time.Second,
			MaxReconnects:  120,
			PingInterval:   20 * time.Second,
			MaxPingsOut:    2,
			StreamReplicas: 1,
		},
	}

	if _, err := cfg.NATSConnectionOptions(); err == nil || !strings.Contains(err.Error(), "APP_ENV") {
		t.Fatalf("NATSConnectionOptions() error = %v", err)
	}
}

func TestNATSClientTLSConfigRequiresTLS13AndVerification(t *testing.T) {
	cfg := validSecureNATSConfig()
	tlsConfig := cfg.clientTLSConfig()

	if tlsConfig.MinVersion != tls.VersionTLS13 ||
		tlsConfig.ServerName != cfg.TLSServerName || tlsConfig.InsecureSkipVerify {
		t.Fatalf("unexpected NATS TLS config: %+v", tlsConfig)
	}
}

func TestNATSConfigFormattingRedactsTransportDetails(t *testing.T) {
	cfg := validSecureNATSConfig()
	formatted := fmt.Sprintf("%+v %#v", cfg, cfg)

	for _, value := range []string{
		cfg.URL,
		cfg.CredentialsFile,
		cfg.CACertPath,
		cfg.ClientCertPath,
		cfg.ClientKeyPath,
		cfg.TLSServerName,
	} {
		if strings.Contains(formatted, value) {
			t.Fatalf("formatted NATS config disclosed transport detail: %s", formatted)
		}
	}
}

func validSecureNATSConfig() NATSConfig {
	return NATSConfig{
		URL:             "tls://nats-a.internal:4222,tls://nats-b.internal:4222",
		CredentialsFile: "/run/secrets/saved-nats.creds",
		CACertPath:      "/run/secrets/nats-ca.crt",
		ClientCertPath:  "/run/secrets/saved-nats.crt",
		ClientKeyPath:   "/run/secrets/saved-nats.key",
		TLSServerName:   "nats.internal",
		ConnectTimeout:  3 * time.Second,
		ReconnectWait:   time.Second,
		MaxReconnects:   120,
		PingInterval:    20 * time.Second,
		MaxPingsOut:     2,
		StreamReplicas:  3,
	}
}
