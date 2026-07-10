package config

import (
	"context"
	"testing"
	"time"
)

func TestLoadParsesTranslationServiceRuntimeConfig(t *testing.T) {
	t.Setenv("APP_ENV", "production")
	t.Setenv("HTTP_PORT", "8094")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9497")
	t.Setenv("DATABASE_URL", "postgres://translation:secret@postgres:5432/translation?sslmode=disable")
	t.Setenv("TRANSLATION_BILLING_MODE", "free_only")
	t.Setenv("TRANSLATION_MONTHLY_CHARACTER_LIMIT", "2000000")
	t.Setenv("TRANSLATION_QUOTA_WARNING_THRESHOLD", "0.75")
	t.Setenv("TRANSLATION_QUOTA_CRITICAL_THRESHOLD", "0.90")
	t.Setenv("TRANSLATION_PROVIDER", "azure_translator")
	t.Setenv("AZURE_TRANSLATOR_ENDPOINT", "https://api.cognitive.microsofttranslator.com")
	t.Setenv("AZURE_TRANSLATOR_KEY", "secret")
	t.Setenv("AZURE_TRANSLATOR_REGION", "centralus")
	t.Setenv("AZURE_TRANSLATOR_TIMEOUT", "4s")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.crt")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/translation-service/server.crt")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/translation-service/server.key")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/excursion-service")
	t.Setenv("MTLS_ALLOWED_DNS_NAMES", "excursion-service")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.App.Name != "translation-service" || cfg.App.Env != "production" {
		t.Fatalf("app config = %+v", cfg.App)
	}
	if cfg.HTTP.Port != 8094 || cfg.HTTP.InternalTLSPort != 9497 {
		t.Fatalf("http config = %+v", cfg.HTTP)
	}
	if cfg.Database.URL == "" {
		t.Fatal("database URL was not loaded")
	}
	if cfg.Translation.BillingMode != "free_only" || cfg.Translation.MonthlyCharacterLimit != 2_000_000 {
		t.Fatalf("translation config = %+v", cfg.Translation)
	}
	if cfg.Translation.QuotaWarningThreshold != 0.75 || cfg.Translation.QuotaCriticalThreshold != 0.90 {
		t.Fatalf("quota thresholds = %v/%v", cfg.Translation.QuotaWarningThreshold, cfg.Translation.QuotaCriticalThreshold)
	}
	if cfg.Provider.Name != "azure_translator" || cfg.Provider.Azure.Key != "secret" || cfg.Provider.Azure.Region != "centralus" {
		t.Fatalf("provider config = %+v", cfg.Provider)
	}
	if cfg.Provider.Azure.Timeout != 4*time.Second {
		t.Fatalf("azure timeout = %s, want 4s", cfg.Provider.Azure.Timeout)
	}
	if cfg.Security.InternalServiceToken != "internal-token" {
		t.Fatalf("internal token = %q", cfg.Security.InternalServiceToken)
	}
	serverTransport := cfg.MTLS.ServerConfig()
	if serverTransport.ServerCertPath != "/run/mtls/translation-service/server.crt" ||
		serverTransport.ServerKeyPath != "/run/mtls/translation-service/server.key" {
		t.Fatalf("mTLS server config = %+v", serverTransport)
	}
}
