package config

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	App         AppConfig
	HTTP        HTTPConfig
	GRPC        GRPCConfig
	Postgres    PostgresConfig
	Log         LogConfig
	Security    SecurityConfig
	Phone       PhoneVerificationConfig
	FileManager FileManagerConfig
}

type AppConfig struct {
	Env string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(a.Env, "production")
}

type HTTPConfig struct {
	Port         int           `env:"HTTP_PORT, default=8084"`
	ReadTimeout  time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout time.Duration `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout  time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

type GRPCConfig struct {
	Port int `env:"GRPC_PORT, default=9094"`
}

func (g GRPCConfig) Address() string {
	return fmt.Sprintf(":%d", g.Port)
}

type PostgresConfig struct {
	Host            string `env:"POSTGRES_HOST, required"`
	Port            int    `env:"POSTGRES_PORT, default=5432"`
	User            string `env:"POSTGRES_USER, required"`
	Password        string `env:"POSTGRES_PASSWORD, required"`
	DBName          string `env:"POSTGRES_DB, required"`
	SSLMode         string `env:"POSTGRES_SSLMODE, default=disable"`
	MaxOpenConns    int32  `env:"POSTGRES_MAX_OPEN_CONNS, default=10"`
	MinOpenConns    int32  `env:"POSTGRES_MIN_OPEN_CONNS, default=2"`
	MaxConnLifetime string `env:"POSTGRES_MAX_CONN_LIFETIME, default=1h"`
	MaxConnIdleTime string `env:"POSTGRES_MAX_CONN_IDLE_TIME, default=30m"`
}

func (p PostgresConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		p.User,
		p.Password,
		p.Host,
		p.Port,
		p.DBName,
		p.SSLMode,
	)
}

func (p PostgresConfig) ParsedMaxConnLifetime() time.Duration {
	d, err := time.ParseDuration(p.MaxConnLifetime)
	if err != nil {
		return time.Hour
	}
	return d
}

func (p PostgresConfig) ParsedMaxConnIdleTime() time.Duration {
	d, err := time.ParseDuration(p.MaxConnIdleTime)
	if err != nil {
		return 30 * time.Minute
	}
	return d
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type SecurityConfig struct {
	InternalServiceToken       string `env:"INTERNAL_SERVICE_TOKEN, required"`
	RequireAuthenticatedWrites bool   `env:"REQUIRE_AUTHENTICATED_WRITES, default=true"`
	TrustedGatewayHeaderUserID string `env:"TRUSTED_GATEWAY_HEADER_USER_ID, default=X-User-Id"`
	TrustedGatewayHeaderRoles  string `env:"TRUSTED_GATEWAY_HEADER_ROLES, default=X-User-Roles"`
	TrustedGatewayHeaderSub    string `env:"TRUSTED_GATEWAY_HEADER_SUB, default=X-Auth-Subject"`
	RequestIDHeader            string `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
}

type PhoneVerificationConfig struct {
	Provider              string        `env:"PHONE_VERIFICATION_PROVIDER, default=log"`
	CodeLength            int           `env:"PHONE_VERIFICATION_CODE_LENGTH, default=6"`
	CodeTTL               time.Duration `env:"PHONE_VERIFICATION_CODE_TTL, default=5m"`
	ResendCooldown        time.Duration `env:"PHONE_VERIFICATION_RESEND_COOLDOWN, default=1m"`
	MaxVerifyAttempts     int           `env:"PHONE_VERIFICATION_MAX_VERIFY_ATTEMPTS, default=5"`
	CodeHashSecret        string        `env:"PHONE_VERIFICATION_CODE_HASH_SECRET, default="`
	DevelopmentStaticCode string        `env:"PHONE_VERIFICATION_DEV_STATIC_CODE, default="`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	return &cfg, nil
}

type FileManagerConfig struct {
	Target string `env:"FILE_MANAGER_GRPC_TARGET, default=dns:///file-manager-service:9093"`
}
