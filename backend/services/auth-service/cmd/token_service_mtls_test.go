package main

import (
	"strings"
	"testing"

	"github.com/rs/zerolog"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/auth-service/internal/config"
)

func TestNewTokenServiceClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newTokenServiceClient(&config.Config{
		TokenService: config.TokenServiceConfig{
			Addr:          "dns:///token-service:50051",
			ServiceID:     "auth-service",
			ServiceSecret: "secret",
		},
	}, zerolog.Nop())
	if err != nil {
		t.Fatalf("newTokenServiceClient() error = %v", err)
	}
	if err := client.Close(); err != nil {
		t.Fatalf("client.Close() error = %v", err)
	}
}

func TestNewTokenServiceClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newTokenServiceClient(&config.Config{
		TokenService: config.TokenServiceConfig{
			Addr:          "dns:///token-service:50051",
			ServiceID:     "auth-service",
			ServiceSecret: "secret",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	}, zerolog.Nop())
	if err == nil {
		t.Fatal("newTokenServiceClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize token-service mTLS transport") {
		t.Fatalf("error = %q, want token-service mTLS context", err)
	}
}
