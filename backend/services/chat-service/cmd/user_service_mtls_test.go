package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/chat-service/internal/config"
)

func TestNewUserServiceConnKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	conn, err := newUserServiceConn(&config.Config{
		App:      config.AppConfig{Name: "chat-service"},
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		UserService: config.UserServiceConfig{
			GRPCAddress: "dns:///user-service:9094",
		},
	})
	if err != nil {
		t.Fatalf("newUserServiceConn() error = %v", err)
	}
	if err := conn.Close(); err != nil {
		t.Fatalf("conn.Close() error = %v", err)
	}
}

func TestNewUserServiceConnFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newUserServiceConn(&config.Config{
		App:      config.AppConfig{Name: "chat-service"},
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		UserService: config.UserServiceConfig{
			GRPCAddress: "dns:///user-service:9094",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newUserServiceConn() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize user-service mTLS transport") {
		t.Fatalf("error = %q, want user-service mTLS context", err)
	}
}
