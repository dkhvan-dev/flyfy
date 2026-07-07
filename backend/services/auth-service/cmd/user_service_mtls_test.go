package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/auth-service/internal/config"
)

func TestNewUserServiceClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newUserServiceClient(&config.Config{
		UserService: config.UserServiceConfig{
			GRPCTarget:           "dns:///user-service:9094",
			InternalServiceToken: "internal-token",
			ServiceName:          "auth-service",
		},
	})
	if err != nil {
		t.Fatalf("newUserServiceClient() error = %v", err)
	}
	if err := client.Close(); err != nil {
		t.Fatalf("client.Close() error = %v", err)
	}
}

func TestNewUserServiceClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newUserServiceClient(&config.Config{
		UserService: config.UserServiceConfig{
			GRPCTarget:           "dns:///user-service:9094",
			InternalServiceToken: "internal-token",
			ServiceName:          "auth-service",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newUserServiceClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize user-service mTLS transport") {
		t.Fatalf("error = %q, want user-service mTLS context", err)
	}
}
