package config

import (
	"context"
	"testing"
	"time"
)

func TestLoadNotificationServiceDefaults(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load error: %v", err)
	}
	if cfg.Notification.HTTPURL != "http://notification-service:8097" {
		t.Fatalf("Notification.HTTPURL = %q", cfg.Notification.HTTPURL)
	}
	if cfg.Notification.RequestTimeout != 3*time.Second {
		t.Fatalf("Notification.RequestTimeout = %s", cfg.Notification.RequestTimeout)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/chat-service/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/chat-service/server-key.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/chat-service/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/chat-service/client-key.pem")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load error: %v", err)
	}

	transport := cfg.MTLS.ClientConfig("trust-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ClientCertPath != "/run/mtls/chat-service/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/chat-service/client-key.pem" ||
		transport.ServerName != "trust-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}

	serverTransport := cfg.MTLS.ServerConfig()
	if serverTransport.ServerCertPath != "/run/mtls/chat-service/server.pem" ||
		serverTransport.ServerKeyPath != "/run/mtls/chat-service/server-key.pem" {
		t.Fatalf("server mTLS transport config = %+v", serverTransport)
	}
}

func TestLoadInternalGRPCTLSPortFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("INTERNAL_GRPC_TLS_PORT", "9447")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9488")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load error: %v", err)
	}
	if cfg.GRPC.InternalTLSPort != 9447 {
		t.Fatalf("InternalTLSPort = %d, want 9447", cfg.GRPC.InternalTLSPort)
	}
	if cfg.GRPC.InternalTLSAddress() != ":9447" {
		t.Fatalf("InternalTLSAddress() = %q, want :9447", cfg.GRPC.InternalTLSAddress())
	}
	if cfg.HTTP.InternalTLSPort != 9488 {
		t.Fatalf("HTTP.InternalTLSPort = %d, want 9488", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9488" {
		t.Fatalf("HTTP.InternalTLSAddress() = %q, want :9488", cfg.HTTP.InternalTLSAddress())
	}
}
