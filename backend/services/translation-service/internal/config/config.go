package config

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/sethvargo/go-envconfig"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/translation-service/internal/domain/model"
)

type Config struct {
	App         AppConfig
	HTTP        HTTPConfig
	Log         LogConfig
	Database    DatabaseConfig
	Translation TranslationConfig
	Provider    ProviderConfig
	Security    SecurityConfig
	MTLS        transportauth.EnvConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=translation-service"`
	Env  string `env:"APP_ENV, default=development"`
}

type HTTPConfig struct {
	Port            int           `env:"HTTP_PORT, default=8094"`
	InternalTLSPort int           `env:"INTERNAL_HTTP_TLS_PORT, default=0"`
	ReadTimeout     time.Duration `env:"HTTP_READ_TIMEOUT, default=10s"`
	WriteTimeout    time.Duration `env:"HTTP_WRITE_TIMEOUT, default=20s"`
	IdleTimeout     time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

func (h HTTPConfig) InternalTLSAddress() string {
	return fmt.Sprintf(":%d", h.InternalTLSPort)
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type DatabaseConfig struct {
	URL string `env:"DATABASE_URL"`
}

type TranslationConfig struct {
	BillingMode            model.BillingMode `env:"TRANSLATION_BILLING_MODE, default=free_only"`
	MonthlyCharacterLimit  int               `env:"TRANSLATION_MONTHLY_CHARACTER_LIMIT, default=2000000"`
	QuotaWarningThreshold  float64           `env:"TRANSLATION_QUOTA_WARNING_THRESHOLD, default=0.80"`
	QuotaCriticalThreshold float64           `env:"TRANSLATION_QUOTA_CRITICAL_THRESHOLD, default=0.95"`
	GlossaryVersion        string            `env:"TRANSLATION_GLOSSARY_VERSION"`
}

type ProviderConfig struct {
	Name  string `env:"TRANSLATION_PROVIDER, default=azure_translator"`
	Azure AzureConfig
}

type AzureConfig struct {
	Endpoint string        `env:"AZURE_TRANSLATOR_ENDPOINT, default=https://api.cognitive.microsofttranslator.com"`
	Key      string        `env:"AZURE_TRANSLATOR_KEY"`
	Region   string        `env:"AZURE_TRANSLATOR_REGION"`
	Timeout  time.Duration `env:"AZURE_TRANSLATOR_TIMEOUT, default=5s"`
}

type SecurityConfig struct {
	InternalServiceToken string        `env:"INTERNAL_SERVICE_TOKEN"`
	ServiceAuthIssuer    string        `env:"SERVICE_AUTH_ISSUER, default=tourism-inflap/token-service"`
	ServiceAuthJWKSURL   string        `env:"SERVICE_AUTH_JWKS_URL, default=http://token-service:8081/.well-known/jwks.json"`
	ServiceAuthCacheTTL  time.Duration `env:"SERVICE_AUTH_JWKS_CACHE_TTL, default=5m"`
}

func (s SecurityConfig) ServiceAuthEnabled() bool {
	return strings.TrimSpace(s.ServiceAuthIssuer) != "" && strings.TrimSpace(s.ServiceAuthJWKSURL) != ""
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	cfg.normalize()
	return &cfg, nil
}

func (cfg *Config) normalize() {
	cfg.App.Name = strings.TrimSpace(cfg.App.Name)
	cfg.App.Env = strings.TrimSpace(cfg.App.Env)
	cfg.Database.URL = strings.TrimSpace(cfg.Database.URL)
	cfg.Provider.Name = strings.ToLower(strings.TrimSpace(cfg.Provider.Name))
	cfg.Provider.Azure.Endpoint = strings.TrimRight(strings.TrimSpace(cfg.Provider.Azure.Endpoint), "/")
	cfg.Provider.Azure.Key = strings.TrimSpace(cfg.Provider.Azure.Key)
	cfg.Provider.Azure.Region = strings.TrimSpace(cfg.Provider.Azure.Region)
	cfg.Security.InternalServiceToken = strings.TrimSpace(cfg.Security.InternalServiceToken)
	cfg.Security.ServiceAuthIssuer = strings.TrimSpace(cfg.Security.ServiceAuthIssuer)
	cfg.Security.ServiceAuthJWKSURL = strings.TrimSpace(cfg.Security.ServiceAuthJWKSURL)
	cfg.Translation.BillingMode = model.NormalizeBillingMode(string(cfg.Translation.BillingMode))
	cfg.Translation.GlossaryVersion = strings.TrimSpace(cfg.Translation.GlossaryVersion)
	if cfg.Translation.MonthlyCharacterLimit < 0 {
		cfg.Translation.MonthlyCharacterLimit = 0
	}
	if cfg.Translation.QuotaWarningThreshold <= 0 || cfg.Translation.QuotaWarningThreshold >= 1 {
		cfg.Translation.QuotaWarningThreshold = 0.80
	}
	if cfg.Translation.QuotaCriticalThreshold <= 0 || cfg.Translation.QuotaCriticalThreshold > 1 {
		cfg.Translation.QuotaCriticalThreshold = 0.95
	}
	if cfg.Translation.QuotaCriticalThreshold < cfg.Translation.QuotaWarningThreshold {
		cfg.Translation.QuotaCriticalThreshold = cfg.Translation.QuotaWarningThreshold
	}
}
