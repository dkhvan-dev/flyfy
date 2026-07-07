package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/excursion-service/internal/config"
)

func TestNewPlaceServiceHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newPlaceServiceHTTPClient(&config.Config{
		Place: config.PlaceServiceConfig{
			BaseURL: "http://place-service:8090",
			Timeout: 600 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newPlaceServiceHTTPClient() error = %v", err)
	}
	if client.Timeout != 600*time.Millisecond {
		t.Fatalf("client timeout = %s, want 600ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("client transport = %#v, want nil default transport for disabled mTLS", client.Transport)
	}
}

func TestNewPlaceServiceHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newPlaceServiceHTTPClient(&config.Config{
		Place: config.PlaceServiceConfig{
			BaseURL: "https://place-service:9490",
			Timeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newPlaceServiceHTTPClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize place-service mTLS transport") {
		t.Fatalf("error = %q, want place-service mTLS context", err)
	}
}
