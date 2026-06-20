package config

import (
	"context"
	"fmt"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	App         AppConfig
	HTTP        HTTPConfig
	Postgres    PostgresConfig
	Log         LogConfig
	Redis       RedisConfig
	Security    SecurityConfig
	UserService UserServiceConfig
	Admin       AdminConfig
	Switches    SwitchesServiceConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=place-service"`
	Env  string `env:"APP_ENV, default=development"`
}

func (c AppConfig) IsProduction() bool {
	return c.Env == "production"
}

type HTTPConfig struct {
	Port         int    `env:"HTTP_PORT, default=8090"`
	ReadTimeout  string `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout string `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout  string `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (c HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", c.Port)
}

type PostgresConfig struct {
	Host     string `env:"POSTGRES_HOST, default=localhost"`
	Port     int    `env:"POSTGRES_PORT, default=5441"`
	User     string `env:"POSTGRES_USER, default=place_service"`
	Password string `env:"POSTGRES_PASSWORD, default=place_secret_dev"`
	DB       string `env:"POSTGRES_DB, default=place_service_db"`
	SSLMode  string `env:"POSTGRES_SSLMODE, default=disable"`
	MaxConns int32  `env:"POSTGRES_MAX_CONNS, default=10"`
	MinConns int32  `env:"POSTGRES_MIN_CONNS, default=2"`
}

func (c PostgresConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		c.User, c.Password, c.Host, c.Port, c.DB, c.SSLMode,
	)
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type RedisConfig struct {
	Enabled   bool          `env:"PLACE_CACHE_ENABLED, default=true"`
	Addr      string        `env:"REDIS_ADDR"`
	Password  string        `env:"REDIS_PASSWORD"`
	DB        int           `env:"REDIS_CACHE_DB, default=4"`
	KeyPrefix string        `env:"PLACE_CACHE_KEY_PREFIX, default=place-service:cache:"`
	DetailTTL time.Duration `env:"PLACE_DETAIL_CACHE_TTL, default=15m"`
	ListTTL   time.Duration `env:"PLACE_LIST_CACHE_TTL, default=5m"`
}

type SecurityConfig struct {
	InternalServiceToken       string `env:"INTERNAL_SERVICE_TOKEN, required"`
	RequireAuthenticatedWrites bool   `env:"REQUIRE_AUTHENTICATED_WRITES, default=true"`
	TrustedHeaderUserID        string `env:"TRUSTED_GATEWAY_HEADER_USER_ID, default=X-User-Id"`
	TrustedHeaderRoles         string `env:"TRUSTED_GATEWAY_HEADER_ROLES, default=X-User-Roles"`
	TrustedHeaderSubject       string `env:"TRUSTED_GATEWAY_HEADER_SUB, default=X-Auth-Subject"`
	RequestIDHeader            string `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
}

type UserServiceConfig struct {
	GRPCTarget string `env:"USER_SERVICE_GRPC_TARGET, default=dns:///user-service:9094"`
}

type SwitchesServiceConfig struct {
	HTTPURL              string        `env:"SWITCHES_SERVICE_URL, default=http://switches-service:8096"`
	InternalServiceToken string        `env:"SWITCHES_INTERNAL_SERVICE_TOKEN"`
	RequestTimeout       time.Duration `env:"SWITCHES_SERVICE_TIMEOUT, default=800ms"`
}

type AdminConfig struct {
	PlaceAuthorUserID string `env:"ADMIN_PLACE_AUTHOR_USER_ID, default=00000000-0000-4000-8000-000000000001"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("load config: %w", err)
	}
	return &cfg, nil
}
