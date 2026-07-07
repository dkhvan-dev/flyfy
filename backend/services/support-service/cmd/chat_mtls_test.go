package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/support-service/internal/config"
)

func TestNewChatServiceHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newChatServiceHTTPClient(config.ChatConfig{
		ServiceURL: "http://chat-service:8088",
		Timeout:    250 * time.Millisecond,
	}, transportauth.EnvConfig{})
	if err != nil {
		t.Fatalf("newChatServiceHTTPClient() error = %v", err)
	}
	if client.Timeout != 250*time.Millisecond {
		t.Fatalf("client timeout = %s, want 250ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("client transport = %#v, want nil default transport for disabled mTLS", client.Transport)
	}
}

func TestNewChatServiceHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newChatServiceHTTPClient(config.ChatConfig{
		ServiceURL: "https://chat-service:9488",
		Timeout:    time.Second,
	}, transportauth.EnvConfig{Mode: "enforce"})
	if err == nil {
		t.Fatal("newChatServiceHTTPClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize chat-service mTLS transport") {
		t.Fatalf("error = %q, want chat-service mTLS context", err)
	}
}
