package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/excursion-service/internal/config"
)

func TestNewUserServiceClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newUserServiceClient(&config.Config{
		App:      config.AppConfig{Name: "excursion-service"},
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		UserService: config.UserServiceConfig{
			Target: "dns:///user-service:9094",
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
		App:      config.AppConfig{Name: "excursion-service"},
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		UserService: config.UserServiceConfig{
			Target: "dns:///user-service:9094",
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
