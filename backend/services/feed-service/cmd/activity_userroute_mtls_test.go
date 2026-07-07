package main

import (
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/feed-service/internal/config"
)

func TestNewActivityServiceHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newActivityServiceHTTPClient(&config.Config{
		Activity: config.ActivityServiceConfig{
			HTTPURL:        "http://activity-service:8086",
			RequestTimeout: 250 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newActivityServiceHTTPClient() error = %v", err)
	}
	if client.Timeout != 250*time.Millisecond {
		t.Fatalf("client timeout = %s, want 250ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("client transport = %#v, want nil default transport for disabled mTLS", client.Transport)
	}
}

func TestNewActivityServiceHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newActivityServiceHTTPClient(&config.Config{
		Activity: config.ActivityServiceConfig{
			HTTPURL:        "https://activity-service:9486",
			RequestTimeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newActivityServiceHTTPClient() error = nil, want missing CA error")
	}
}

func TestNewUserRouteServiceHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newUserRouteServiceHTTPClient(&config.Config{
		UserRoute: config.UserRouteServiceConfig{
			HTTPURL:        "http://user-route-service:8096",
			RequestTimeout: 250 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newUserRouteServiceHTTPClient() error = %v", err)
	}
	if client.Timeout != 250*time.Millisecond {
		t.Fatalf("client timeout = %s, want 250ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("client transport = %#v, want nil default transport for disabled mTLS", client.Transport)
	}
}

func TestNewUserRouteServiceHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newUserRouteServiceHTTPClient(&config.Config{
		UserRoute: config.UserRouteServiceConfig{
			HTTPURL:        "https://user-route-service:9496",
			RequestTimeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newUserRouteServiceHTTPClient() error = nil, want missing CA error")
	}
}
