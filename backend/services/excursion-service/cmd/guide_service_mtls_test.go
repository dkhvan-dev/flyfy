package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/excursion-service/internal/config"
)

func TestNewGuideServiceClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newGuideServiceClient(&config.Config{
		App:      config.AppConfig{Name: "excursion-service"},
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		GuideService: config.GuideServiceConfig{
			Target: "dns:///guide-service:9095",
		},
	})
	if err != nil {
		t.Fatalf("newGuideServiceClient() error = %v", err)
	}
	if err := client.Close(); err != nil {
		t.Fatalf("client.Close() error = %v", err)
	}
}

func TestNewGuideServiceClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newGuideServiceClient(&config.Config{
		App:      config.AppConfig{Name: "excursion-service"},
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		GuideService: config.GuideServiceConfig{
			Target: "dns:///guide-service:9095",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newGuideServiceClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize guide-service mTLS transport") {
		t.Fatalf("error = %q, want guide-service mTLS context", err)
	}
}
