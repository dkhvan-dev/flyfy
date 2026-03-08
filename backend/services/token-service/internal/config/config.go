package config

import (
	"context"
	"fmt"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	// Server
	GRPCPort int    `env:"GRPC_PORT, default=50051"`
	HTTPPort int    `env:"HTTP_PORT, default=8081"`
	Env      string `env:"APP_ENV, default=development"`

	// JWT
	JWT JWTConfig

	// Database
	Postgres PostgresConfig
	Redis    RedisConfig

	// Telemetry
	OTELEndpoint string `env:"OTEL_ENDPOINT, default=localhost:4317"`
}

type JWTConfig struct {
	Issuer              string        `env:"JWT_ISSUER, default=tourism-superapp/token-service"`
	AccessTokenTTL      time.Duration `env:"JWT_ACCESS_TTL, default=30m"`
	RefreshTokenTTL     time.Duration `env:"JWT_REFRESH_TTL, default=720h"`
	ServiceTokenTTL     time.Duration `env:"JWT_SERVICE_TTL, default=1h"`
	KeyRotationInterval time.Duration `env:"JWT_KEY_ROTATION_INTERVAL, default=168h"`
	RSAKeySize          int           `env:"JWT_RSA_KEY_SIZE, default=2048"`
	PrivateKeyPath      string        `env:"JWT_PRIVATE_KEY_PATH, default="`
	MaxKeysInJWKS       int           `env:"JWT_MAX_KEYS_JWKS, default=3"`
}

type PostgresConfig struct {
	Host     string `env:"PG_HOST, default=localhost"`
	Port     int    `env:"PG_PORT, default=5432"`
	User     string `env:"PG_USER, default=token_service"`
	Password string `env:"PG_PASSWORD, default=secret"`
	DBName   string `env:"PG_DBNAME, default=token_service"`
	SSLMode  string `env:"PG_SSLMODE, default=disable"`
	MaxConns int    `env:"PG_MAX_CONNS, default=20"`
}

func (p PostgresConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		p.User, p.Password, p.Host, p.Port, p.DBName, p.SSLMode,
	)
}

type RedisConfig struct {
	Addr     string `env:"REDIS_ADDR, default=localhost:6379"`
	Password string `env:"REDIS_PASSWORD, default="`
	DB       int    `env:"REDIS_DB, default=0"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("loading config: %w", err)
	}
	return &cfg, nil
}
