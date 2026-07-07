package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/guide-service/internal/config"
)

func TestNewExcursionServiceHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newExcursionServiceHTTPClient(&config.Config{
		Excursion: config.ExcursionServiceConfig{
			BaseURL: "http://excursion-service:8093",
			Timeout: 1500 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newExcursionServiceHTTPClient() error = %v", err)
	}
	if client.Timeout != 1500*time.Millisecond {
		t.Fatalf("timeout = %s, want 1500ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("transport = %#v, want default transport in disabled mode", client.Transport)
	}
}

func TestNewExcursionServiceHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newExcursionServiceHTTPClient(&config.Config{
		Excursion: config.ExcursionServiceConfig{
			BaseURL: "http://excursion-service:8093",
			Timeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newExcursionServiceHTTPClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize excursion-service mTLS transport") {
		t.Fatalf("error = %q, want excursion-service transport context", err)
	}
}
