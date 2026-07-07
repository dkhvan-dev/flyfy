package config

import (
	"context"
	"fmt"
	"time"

	"github.com/sethvargo/go-envconfig"

	"kz/inflap/backend/pkg/transportauth"
)

type Config struct {
	// Server
	GRPCPort            int    `env:"GRPC_PORT, default=50051"`
	InternalGRPCTLSPort int    `env:"INTERNAL_GRPC_TLS_PORT, default=0"`
	HTTPPort            int    `env:"HTTP_PORT, default=8081"`
	InternalHTTPTLSPort int    `env:"INTERNAL_HTTP_TLS_PORT, default=0"`
	Env                 string `env:"APP_ENV, default=development"`
	MTLS                transportauth.EnvConfig

	// JWT
	JWT JWTConfig

	// Sessions
	Session SessionConfig

	// Database
	Postgres PostgresConfig
	Redis    RedisConfig

	// Telemetry
	OTELEndpoint string `env:"OTEL_ENDPOINT, default=localhost:4317"`

	// Integrations
	Notification NotificationConfig
}

// SessionConfig controls user-session lifecycle:
//   - InactivityTTL: a refresh token whose session has not been used for
//     longer than this is treated as expired (re-login required). Set
//     extremely high for "infinite session" UX (Booking/AirBnB style).
//   - EnforceSingle: when true (default), every successful login revokes
//     the user's previous session.
//   - RevokedCacheTTLBuffer: extra TTL added on top of the access TTL when
//     marking a revoked session in Redis — guarantees that any access token
//     issued just before the revoke cannot outlive the cache entry.
type SessionConfig struct {
	InactivityTTL         time.Duration `env:"SESSION_INACTIVITY_TTL, default=8760h"` // 365 days
	EnforceSingle         bool          `env:"SESSION_ENFORCE_SINGLE, default=true"`
	RevokedCacheTTLBuffer time.Duration `env:"SESSION_REVOKED_CACHE_TTL_BUFFER, default=10m"`
}

type JWTConfig struct {
	Issuer              string        `env:"JWT_ISSUER, default=tourism-inflap/token-service"`
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

type NotificationConfig struct {
	HTTPURL              string        `env:"NOTIFICATION_SERVICE_HTTP_URL, default="`
	InternalServiceToken string        `env:"NOTIFICATION_INTERNAL_SERVICE_TOKEN, default="`
	Timeout              time.Duration `env:"NOTIFICATION_SERVICE_TIMEOUT, default=2s"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("loading config: %w", err)
	}
	return &cfg, nil
}
