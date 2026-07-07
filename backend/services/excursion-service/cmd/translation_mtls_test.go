package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/excursion-service/internal/config"
)

func TestNewTranslationClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newTranslationClient(&config.Config{
		Translation: config.TranslationServiceConfig{
			BaseURL: "http://translation-service:8094",
		},
	})
	if err != nil {
		t.Fatalf("newTranslationClient() error = %v", err)
	}
	if client == nil {
		t.Fatal("newTranslationClient() = nil, want client")
	}
}

func TestNewTranslationClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newTranslationClient(&config.Config{
		Translation: config.TranslationServiceConfig{
			BaseURL: "https://translation-service:9497",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newTranslationClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize translation-service mTLS transport") {
		t.Fatalf("error = %q, want translation-service mTLS context", err)
	}
}
