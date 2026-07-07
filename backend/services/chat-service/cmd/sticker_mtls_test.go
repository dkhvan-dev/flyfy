package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/chat-service/internal/config"
)

func TestNewStickerServiceHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newStickerServiceHTTPClient(&config.Config{
		StickerService: config.StickerServiceConfig{
			HTTPURL: "http://sticker-service:8092",
			Timeout: 750 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newStickerServiceHTTPClient() error = %v", err)
	}
	if client.Timeout != 750*time.Millisecond {
		t.Fatalf("timeout = %s, want 750ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("transport = %#v, want default transport in disabled mode", client.Transport)
	}
}

func TestNewStickerServiceHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newStickerServiceHTTPClient(&config.Config{
		StickerService: config.StickerServiceConfig{
			HTTPURL: "http://sticker-service:8092",
			Timeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newStickerServiceHTTPClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize sticker-service mTLS transport") {
		t.Fatalf("error = %q, want sticker-service transport context", err)
	}
}
