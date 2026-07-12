package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/activity-service/internal/config"
)

func TestNewActivityTranslationClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, closeClient, err := newActivityTranslationClient(&config.Config{
		Translation: config.TranslationServiceConfig{
			BaseURL: "http://translation-service:8094",
		},
	})
	if err != nil {
		t.Fatalf("newActivityTranslationClient() error = %v", err)
	}
	defer closeClient()
	if client == nil {
		t.Fatal("newActivityTranslationClient() = nil, want client")
	}
}

func TestNewActivityTranslationClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, _, err := newActivityTranslationClient(&config.Config{
		Translation: config.TranslationServiceConfig{
			BaseURL: "https://translation-service:9497",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newActivityTranslationClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize translation-service mTLS transport") {
		t.Fatalf("error = %q, want translation-service mTLS context", err)
	}
}
