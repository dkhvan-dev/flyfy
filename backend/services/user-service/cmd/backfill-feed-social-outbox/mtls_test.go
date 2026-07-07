package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/user-service/internal/config"
)

func TestNewFeedServiceHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newFeedServiceHTTPClient(&config.Config{
		FeedService: config.FeedServiceConfig{
			HTTPURL:        "http://feed-service:8087",
			RequestTimeout: 1500 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newFeedServiceHTTPClient() error = %v", err)
	}
	if client.Timeout != 1500*time.Millisecond {
		t.Fatalf("timeout = %s, want 1500ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("transport = %#v, want default transport in disabled mode", client.Transport)
	}
}

func TestNewFeedServiceHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newFeedServiceHTTPClient(&config.Config{
		FeedService: config.FeedServiceConfig{
			HTTPURL:        "https://feed-service:9487",
			RequestTimeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newFeedServiceHTTPClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize feed-service mTLS transport") {
		t.Fatalf("error = %q, want feed-service transport context", err)
	}
}
