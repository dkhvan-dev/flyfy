package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/chat-service/internal/config"
)

func TestNewActivityServiceConnKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	conn, err := newActivityServiceConn(&config.Config{
		App:      config.AppConfig{Name: "chat-service"},
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		ActivityService: config.ActivityServiceConfig{
			GRPCAddress: "dns:///activity-service:9096",
		},
	})
	if err != nil {
		t.Fatalf("newActivityServiceConn() error = %v", err)
	}
	if err := conn.Close(); err != nil {
		t.Fatalf("conn.Close() error = %v", err)
	}
}

func TestNewActivityServiceConnFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newActivityServiceConn(&config.Config{
		App:      config.AppConfig{Name: "chat-service"},
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		ActivityService: config.ActivityServiceConfig{
			GRPCAddress: "dns:///activity-service:9096",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newActivityServiceConn() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize activity-service mTLS transport") {
		t.Fatalf("error = %q, want activity-service mTLS context", err)
	}
}
