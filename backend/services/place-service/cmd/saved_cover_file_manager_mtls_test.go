package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/place-service/internal/config"
)

func TestNewSavedCoverFileManagerClientSupportsPlainDevelopmentTransport(t *testing.T) {
	t.Parallel()

	client, err := newSavedCoverFileManagerClient(&config.Config{
		App:      config.AppConfig{Name: "place-service"},
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		FileManager: config.FileManagerConfig{
			GRPCTarget:     "dns:///file-manager-service:9093",
			RequestTimeout: 3 * time.Second,
		},
	})
	if err != nil {
		t.Fatalf("newSavedCoverFileManagerClient() error = %v", err)
	}
	if err = client.Close(); err != nil {
		t.Fatalf("client.Close() error = %v", err)
	}
}

func TestNewSavedCoverFileManagerClientFailsFastForInvalidMTLSConfig(t *testing.T) {
	t.Parallel()

	_, err := newSavedCoverFileManagerClient(&config.Config{
		App:      config.AppConfig{Name: "place-service"},
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		FileManager: config.FileManagerConfig{
			GRPCTarget:     "dns:///file-manager-service:9093",
			RequestTimeout: 3 * time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newSavedCoverFileManagerClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "Saved cover file-manager mTLS transport") {
		t.Fatalf("error = %q, want Saved cover mTLS context", err)
	}
}
