package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/support-service/internal/config"
)

func TestNewUserContextHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newUserContextHTTPClient(config.UserContextConfig{
		UserServiceURL:  "http://user-service:8084",
		GuideServiceURL: "http://guide-service:8085",
		Timeout:         1500 * time.Millisecond,
	}, transportauth.EnvConfig{})
	if err != nil {
		t.Fatalf("newUserContextHTTPClient() error = %v", err)
	}
	if client.Timeout != 1500*time.Millisecond {
		t.Fatalf("timeout = %s, want 1500ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("transport = %#v, want default transport in disabled mode", client.Transport)
	}
}

func TestNewUserContextHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newUserContextHTTPClient(config.UserContextConfig{
		UserServiceURL:  "https://user-service:9484",
		GuideServiceURL: "https://guide-service:9485",
		Timeout:         time.Second,
	}, transportauth.EnvConfig{Mode: "enforce"})
	if err == nil {
		t.Fatal("newUserContextHTTPClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize support user-context mTLS transport") {
		t.Fatalf("error = %q, want user-context transport context", err)
	}
}
