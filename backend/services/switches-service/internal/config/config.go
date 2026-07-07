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
	App       AppConfig
	HTTP      HTTPConfig
	DB        DBConfig
	Cache     CacheConfig
	Runtime   RuntimeConfig
	Log       LogConfig
	Security  SecurityConfig
	Scheduler SchedulerConfig
	MTLS      transportauth.EnvConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=switches-service"`
	Env  string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(strings.TrimSpace(a.Env), "production")
}

type HTTPConfig struct {
	Port            int           `env:"HTTP_PORT, default=8096"`
	InternalTLSPort int           `env:"INTERNAL_HTTP_TLS_PORT, default=0"`
	ReadTimeout     time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout    time.Duration `env:"HTTP_WRITE_TIMEOUT, default=30s"`
	IdleTimeout     time.Duration `env:"HTTP_IDLE_TIMEOUT, default=120s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

func (h HTTPConfig) InternalTLSAddress() string {
	return fmt.Sprintf(":%d", h.InternalTLSPort)
}

type DBConfig struct {
	Host            string `env:"DB_HOST, default=localhost"`
	Port            int    `env:"DB_PORT, default=5432"`
	Name            string `env:"DB_NAME, default=switches_service_db"`
	User            string `env:"DB_USER, default=postgres"`
	Password        string `env:"DB_PASSWORD, default=postgres"`
	SSLMode         string `env:"DB_SSLMODE, default=disable"`
	MaxConns        int32  `env:"DB_MAX_CONNS, default=12"`
	MinConns        int32  `env:"DB_MIN_CONNS, default=2"`
	MaxConnIdleTime string `env:"DB_MAX_CONN_IDLE, default=5m"`
	MaxConnLifetime string `env:"DB_MAX_CONN_LIFETIME, default=1h"`
}

type CacheConfig struct {
	TTL     time.Duration `env:"CACHE_TTL, default=10s"`
	MissTTL time.Duration `env:"CACHE_MISS_TTL, default=2s"`
}

type RuntimeConfig struct {
	CacheInvalidationListenerEnabled bool `env:"CACHE_INVALIDATION_LISTENER_ENABLED, default=true"`
}

func (d DBConfig) DSN() string {
	return fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=%s", d.User, d.Password, d.Host, d.Port, d.Name, d.SSLMode)
}

func (d DBConfig) ParsedMaxConnLifetime() time.Duration {
	value, err := time.ParseDuration(d.MaxConnLifetime)
	if err != nil {
		return time.Hour
	}
	return value
}

func (d DBConfig) ParsedMaxConnIdleTime() time.Duration {
	value, err := time.ParseDuration(d.MaxConnIdleTime)
	if err != nil {
		return 5 * time.Minute
	}
	return value
}

type LogConfig struct {
	Level  string `env:"LOG_LEVEL, default=info"`
	Pretty bool   `env:"LOG_PRETTY, default=false"`
}

type SecurityConfig struct {
	InternalServiceToken       string `env:"INTERNAL_SERVICE_TOKEN, required"`
	TrustedGatewayHeaderUserID string `env:"TRUSTED_GATEWAY_HEADER_USER_ID, default=X-User-Id"`
	TrustedGatewayHeaderRoles  string `env:"TRUSTED_GATEWAY_HEADER_ROLES, default=X-User-Roles"`
	TrustedGatewayHeaderSub    string `env:"TRUSTED_GATEWAY_HEADER_SUB, default=X-Auth-Subject"`
	RequestIDHeader            string `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
}

type SchedulerConfig struct {
	Enabled  bool          `env:"SCHEDULER_ENABLED, default=true"`
	Interval time.Duration `env:"SCHEDULER_INTERVAL, default=1m"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	return &cfg, nil
}
