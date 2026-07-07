package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/place-service/internal/config"
)

func TestNewMediaBackfillFileManagerHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newMediaBackfillFileManagerHTTPClient(&config.Config{
		MediaBackfill: config.MediaBackfillConfig{
			FileManagerURL: "http://file-manager-service:8083",
			HTTPTimeout:    1500 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newMediaBackfillFileManagerHTTPClient() error = %v", err)
	}
	if client.Timeout != 1500*time.Millisecond {
		t.Fatalf("timeout = %s, want 1500ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("transport = %#v, want default transport in disabled mode", client.Transport)
	}
}

func TestNewMediaBackfillFileManagerHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newMediaBackfillFileManagerHTTPClient(&config.Config{
		MediaBackfill: config.MediaBackfillConfig{
			FileManagerURL: "https://file-manager-service:9483",
			HTTPTimeout:    time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newMediaBackfillFileManagerHTTPClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize file-manager mTLS transport") {
		t.Fatalf("error = %q, want file-manager transport context", err)
	}
}
