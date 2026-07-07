package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/excursion-service/internal/config"
)

func TestNewGuideRatingHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newGuideRatingHTTPClient(&config.Config{
		GuideService: config.GuideServiceConfig{
			BaseURL:     "http://guide-service:8085",
			HTTPTimeout: 1500 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newGuideRatingHTTPClient() error = %v", err)
	}
	if client.Timeout != 1500*time.Millisecond {
		t.Fatalf("timeout = %s, want 1500ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("transport = %#v, want default transport in disabled mode", client.Transport)
	}
}

func TestNewGuideRatingHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newGuideRatingHTTPClient(&config.Config{
		GuideService: config.GuideServiceConfig{
			BaseURL:     "https://guide-service:9485",
			HTTPTimeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newGuideRatingHTTPClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize guide-service rating mTLS transport") {
		t.Fatalf("error = %q, want guide rating transport context", err)
	}
}
