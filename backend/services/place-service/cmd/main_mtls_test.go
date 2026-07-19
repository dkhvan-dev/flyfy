package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/place-service/internal/config"
)

func TestValidatePlaceServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validatePlaceServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validatePlaceServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidatePlaceServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validatePlaceServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8090}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validatePlaceServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidatePlaceServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validatePlaceServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8090, InternalTLSPort: 8090}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validatePlaceServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestNewInternalPlaceMTLSServerUsesDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalPlaceMTLSServer(
		&config.Config{HTTP: config.HTTPConfig{Port: 8090, InternalTLSPort: 9490}},
		http.NewServeMux(),
		tlsConfig,
		2*time.Second,
		3*time.Second,
		4*time.Second,
	)

	if server == nil {
		t.Fatal("newInternalPlaceMTLSServer() = nil, want server")
	}
	if server.Addr != ":9490" {
		t.Fatalf("server addr = %q, want :9490", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
	if server.ReadTimeout != 2*time.Second || server.WriteTimeout != 3*time.Second || server.IdleTimeout != 4*time.Second {
		t.Fatalf("server timeouts = %s/%s/%s, want 2s/3s/4s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}

func TestValidatePlaceServiceGRPCPort(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		config  *config.Config
		wantErr string
	}{
		{
			name: "valid",
			config: &config.Config{
				HTTP: config.HTTPConfig{Port: 8090, InternalTLSPort: 9490},
				GRPC: config.GRPCConfig{Port: 9099},
			},
		},
		{
			name: "missing",
			config: &config.Config{
				HTTP: config.HTTPConfig{Port: 8090},
			},
			wantErr: "GRPC_PORT must be between",
		},
		{
			name: "http collision",
			config: &config.Config{
				HTTP: config.HTTPConfig{Port: 8090},
				GRPC: config.GRPCConfig{Port: 8090},
			},
			wantErr: "different from HTTP_PORT",
		},
		{
			name: "internal tls collision",
			config: &config.Config{
				HTTP: config.HTTPConfig{Port: 8090, InternalTLSPort: 9099},
				GRPC: config.GRPCConfig{Port: 9099},
			},
			wantErr: "different from INTERNAL_HTTP_TLS_PORT",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			err := validatePlaceServiceGRPCPort(test.config)
			if test.wantErr == "" {
				if err != nil {
					t.Fatalf("validatePlaceServiceGRPCPort() error = %v", err)
				}
				return
			}
			if err == nil || !strings.Contains(err.Error(), test.wantErr) {
				t.Fatalf("error = %v, want containing %q", err, test.wantErr)
			}
		})
	}
}
