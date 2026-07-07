package config

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/sethvargo/go-envconfig"

	"kz/inflap/backend/pkg/transportauth"
)

type Config struct {
	App            AppConfig
	HTTP           HTTPConfig
	Log            LogConfig
	Database       DatabaseConfig
	Redis          RedisConfig
	Security       SecurityConfig
	MTLS           transportauth.EnvConfig
	DocumentEvents DocumentEventConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=search-service"`
	Env  string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(a.Env, "production")
}

type HTTPConfig struct {
	Port            int           `env:"HTTP_PORT, default=8101"`
	InternalTLSPort int           `env:"INTERNAL_HTTP_TLS_PORT, default=0"`
	ReadTimeout     time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout    time.Duration `env:"HTTP_WRITE_TIMEOUT, default=15s"`
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
	DSN string `env:"DATABASE_DSN"`
}

type RedisConfig struct {
	Enabled   bool          `env:"SEARCH_CACHE_ENABLED, default=true"`
	Addr      string        `env:"REDIS_ADDR, default=localhost:6379"`
	Password  string        `env:"REDIS_PASSWORD, default="`
	DB        int           `env:"REDIS_CACHE_DB, default=7"`
	KeyPrefix string        `env:"SEARCH_CACHE_KEY_PREFIX, default=search-service:search-cache:"`
	TTL       time.Duration `env:"SEARCH_CACHE_TTL, default=45s"`
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

type DocumentEventConfig struct {
	WorkerEnabled      bool          `env:"SEARCH_DOCUMENT_EVENT_WORKER_ENABLED, default=true"`
	WorkerPollInterval time.Duration `env:"SEARCH_DOCUMENT_EVENT_WORKER_POLL_INTERVAL, default=5s"`
	WorkerBatchSize    int           `env:"SEARCH_DOCUMENT_EVENT_WORKER_BATCH_SIZE, default=50"`
	WorkerMaxAttempts  int           `env:"SEARCH_DOCUMENT_EVENT_WORKER_MAX_ATTEMPTS, default=20"`
	WorkerBaseBackoff  time.Duration `env:"SEARCH_DOCUMENT_EVENT_WORKER_BASE_BACKOFF, default=1s"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	return &cfg, nil
}
