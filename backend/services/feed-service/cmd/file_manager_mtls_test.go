package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/feed-service/internal/config"
)

func TestNewFileManagerClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newFileManagerClient(&config.Config{
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		FileManager: config.FileManagerConfig{
			Target: "dns:///file-manager-service:9093",
		},
	})
	if err != nil {
		t.Fatalf("newFileManagerClient() error = %v", err)
	}
	if err := client.Close(); err != nil {
		t.Fatalf("client.Close() error = %v", err)
	}
}

func TestNewFileManagerClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newFileManagerClient(&config.Config{
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		FileManager: config.FileManagerConfig{
			Target: "dns:///file-manager-service:9093",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newFileManagerClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize file-manager mTLS transport") {
		t.Fatalf("error = %q, want file-manager mTLS context", err)
	}
}
