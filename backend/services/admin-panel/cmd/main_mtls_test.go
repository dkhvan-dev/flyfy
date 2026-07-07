package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/admin-panel/internal/config"
)

func TestValidateAdminPanelMTLSPortRequiresDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}

	if err := validateAdminPanelMTLSPort(&config.Config{}, tlsConfig); err == nil {
		t.Fatal("validateAdminPanelMTLSPort() error = nil, want missing port error")
	}

	err := validateAdminPanelMTLSPort(&config.Config{
		HTTP: config.HTTPConfig{
			Port:            8095,
			InternalTLSPort: 8095,
		},
	}, tlsConfig)
	if err == nil {
		t.Fatal("validateAdminPanelMTLSPort() error = nil, want reused port error")
	}
	if !strings.Contains(err.Error(), "different from HTTP_PORT") {
		t.Fatalf("error = %q, want different port context", err)
	}
}

func TestNewInternalAdminPanelMTLSServer(t *testing.T) {
	t.Parallel()

	handler := http.NewServeMux()
	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalAdminPanelMTLSServer(&config.Config{
		HTTP: config.HTTPConfig{
			InternalTLSPort: 9495,
			ReadTimeout:     time.Second,
			WriteTimeout:    2 * time.Second,
			IdleTimeout:     3 * time.Second,
		},
	}, handler, tlsConfig)

	if server == nil {
		t.Fatal("newInternalAdminPanelMTLSServer() = nil, want server")
	}
	if server.Addr != ":9495" {
		t.Fatalf("server addr = %q, want :9495", server.Addr)
	}
	if server.Handler != handler {
		t.Fatal("server handler was not preserved")
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLS config was not preserved")
	}
	if server.ReadTimeout != time.Second || server.WriteTimeout != 2*time.Second || server.IdleTimeout != 3*time.Second {
		t.Fatalf("timeouts = %s/%s/%s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}

func TestNewAdminPanelDefaultHTTPTransportKeepsPlainTransportWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	transport, err := newAdminPanelDefaultHTTPTransport(&config.Config{})
	if err != nil {
		t.Fatalf("newAdminPanelDefaultHTTPTransport() error = %v", err)
	}
	if transport == nil {
		t.Fatal("newAdminPanelDefaultHTTPTransport() = nil, want transport")
	}
	if transport.TLSClientConfig != nil &&
		(transport.TLSClientConfig.RootCAs != nil ||
			transport.TLSClientConfig.ServerName != "" ||
			len(transport.TLSClientConfig.Certificates) != 0) {
		t.Fatalf("TLSClientConfig = %#v, want no custom mTLS material", transport.TLSClientConfig)
	}
}

func TestNewAdminPanelDefaultHTTPTransportFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newAdminPanelDefaultHTTPTransport(&config.Config{
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newAdminPanelDefaultHTTPTransport() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize admin-panel default mTLS transport") {
		t.Fatalf("error = %q, want admin-panel transport context", err)
	}
}
