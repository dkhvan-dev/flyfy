package main

import (
	"testing"
	"time"

	"kz/inflap/backend/services/translation-service/internal/config"
)

func TestNewTranslationProviderAcceptsAzureAlias(t *testing.T) {
	for _, name := range []string{"azure", "azure_translator"} {
		t.Run(name, func(t *testing.T) {
			translationProvider, err := newTranslationProvider(config.Config{
				Provider: config.ProviderConfig{
					Name: name,
					Azure: config.AzureConfig{
						Endpoint: "https://api.cognitive.microsofttranslator.com",
						Key:      "test-key",
						Region:   "centralus",
						Timeout:  time.Second,
					},
				},
			})
			if err != nil {
				t.Fatalf("newTranslationProvider() error = %v", err)
			}
			if translationProvider == nil {
				t.Fatal("newTranslationProvider() returned nil provider")
			}
		})
	}
}
