package main

import (
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/place-service/internal/config"
)

func TestNewSearchIndexHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newSearchIndexHTTPClient(&config.Config{
		SearchService: config.SearchServiceConfig{
			HTTPURL: "http://search-service:8101",
			Timeout: 250 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newSearchIndexHTTPClient() error = %v", err)
	}
	if client.Timeout != 250*time.Millisecond {
		t.Fatalf("client timeout = %s, want 250ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("client transport = %#v, want nil default transport for disabled mTLS", client.Transport)
	}
}

func TestNewSearchIndexHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newSearchIndexHTTPClient(&config.Config{
		SearchService: config.SearchServiceConfig{
			HTTPURL: "https://search-service:8101",
			Timeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newSearchIndexHTTPClient() error = nil, want missing CA error")
	}
}
