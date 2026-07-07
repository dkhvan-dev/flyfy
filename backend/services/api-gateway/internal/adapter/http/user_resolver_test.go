package http

import (
	nethttp "net/http"
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/api-gateway/internal/config"
)

func TestNewUserServiceUserIDResolverBuildsMTLSClientPerTarget(t *testing.T) {
	caPath := writeTestCA(t)

	resolver, err := newUserServiceUserIDResolver(&config.Config{
		Downstreams: config.DownstreamsConfig{
			UserService: "https://user-service:9484",
		},
		MTLS: transportauth.EnvConfig{
			Mode:       string(transportauth.ModeEnforce),
			CACertPath: caPath,
		},
	})
	if err != nil {
		t.Fatalf("newUserServiceUserIDResolver() error = %v", err)
	}
	if resolver.endpoint != "https://user-service:9484/v1/users/me/init" {
		t.Fatalf("endpoint = %q, want user init endpoint", resolver.endpoint)
	}

	transport, ok := resolver.client.Transport.(*nethttp.Transport)
	if !ok {
		t.Fatalf("client transport type = %T, want *http.Transport", resolver.client.Transport)
	}
	if transport.TLSClientConfig == nil {
		t.Fatal("TLSClientConfig is nil, want mTLS client config")
	}
	if got := transport.TLSClientConfig.ServerName; got != "user-service" {
		t.Fatalf("TLS server name = %q, want user-service", got)
	}
}

func TestNewUserServiceUserIDResolverFailsFastWhenMTLSEnforceConfigInvalid(t *testing.T) {
	_, err := newUserServiceUserIDResolver(&config.Config{
		Downstreams: config.DownstreamsConfig{
			UserService: "https://user-service:9484",
		},
		MTLS: transportauth.EnvConfig{Mode: string(transportauth.ModeEnforce)},
	})
	if err == nil {
		t.Fatal("newUserServiceUserIDResolver() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize user-service mTLS client") {
		t.Fatalf("error = %q, want user-service mTLS context", err)
	}
}
