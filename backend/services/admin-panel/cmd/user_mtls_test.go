package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/admin-panel/internal/config"
)

func TestNewUserClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newUserClient(&config.Config{
		App:      config.AppConfig{Name: "admin-panel"},
		Security: config.SecurityConfig{TrustedInternalToken: "internal-token"},
		User: config.UserServiceConfig{
			Target:  "user-service:9094",
			Timeout: time.Second,
		},
	})
	if err != nil {
		t.Fatalf("newUserClient() error = %v", err)
	}
	if err := client.Close(); err != nil {
		t.Fatalf("client.Close() error = %v", err)
	}
}

func TestNewUserClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newUserClient(&config.Config{
		App:      config.AppConfig{Name: "admin-panel"},
		Security: config.SecurityConfig{TrustedInternalToken: "internal-token"},
		User: config.UserServiceConfig{
			Target:  "user-service:9094",
			Timeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newUserClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize user-service mTLS transport") {
		t.Fatalf("error = %q, want user-service mTLS context", err)
	}
}
