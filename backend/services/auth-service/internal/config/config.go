package config

import (
	"context"
	"fmt"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	// Server
	GRPCPort int    `env:"GRPC_PORT, default=50052"`
	HTTPPort int    `env:"HTTP_PORT, default=8082"`
	Env      string `env:"APP_ENV, default=development"`

	// Database
	Postgres PostgresConfig
	Redis    RedisConfig

	// Token Service (S2S)
	TokenService TokenServiceConfig
	UserService  UserServiceConfig

	// OTP
	OTP      OTPConfig
	Email    EmailConfig
	Security AuthSecurityConfig

	// OAuth
	Google    GoogleConfig
	Apple     AppleConfig
	AntiFraud AntiFraudConfig

	// Telemetry
	OTELEndpoint string `env:"OTEL_ENDPOINT, default=localhost:4317"`
}

type PostgresConfig struct {
	Host     string `env:"PG_HOST, default=localhost"`
	Port     int    `env:"PG_PORT, default=5432"`
	User     string `env:"PG_USER, default=auth_service"`
	Password string `env:"PG_PASSWORD, default=auth_secret_dev"`
	DBName   string `env:"PG_DBNAME, default=auth_db"`
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
	DB       int    `env:"REDIS_DB, default=1"`
}

type TokenServiceConfig struct {
	Addr          string `env:"TOKEN_SERVICE_ADDR, default=localhost:50051"`
	ServiceID     string `env:"TOKEN_SERVICE_ID, default=auth-service"`
	ServiceSecret string `env:"TOKEN_SERVICE_SECRET, default=auth-service-secret"`
}

type UserServiceConfig struct {
	GRPCTarget           string `env:"USER_SERVICE_GRPC_TARGET, default=dns:///user-service:9094"`
	InternalServiceToken string `env:"USER_SERVICE_INTERNAL_SERVICE_TOKEN"`
	ServiceName          string `env:"USER_SERVICE_CALLER_NAME, default=auth-service"`
}

type OTPConfig struct {
	Length      int           `env:"OTP_LENGTH, default=6"`
	TTL         time.Duration `env:"OTP_TTL, default=5m"`
	MaxAttempts int           `env:"OTP_MAX_ATTEMPTS, default=5"`
}

type EmailConfig struct {
	OTPFromAddress string        `env:"EMAIL_OTP_FROM_ADDRESS, default=dkhvan.developer@gmail.com"`
	SMTPHost       string        `env:"EMAIL_SMTP_HOST, default="`
	SMTPPort       int           `env:"EMAIL_SMTP_PORT, default=587"`
	SMTPUsername   string        `env:"EMAIL_SMTP_USERNAME, default="`
	SMTPPassword   string        `env:"EMAIL_SMTP_PASSWORD, default="`
	SMTPTimeout    time.Duration `env:"EMAIL_SMTP_TIMEOUT, default=8s"`
}

type AuthSecurityConfig struct {
	TestOTPBypassEnabled bool   `env:"AUTH_TEST_OTP_BYPASS_ENABLED, default=false"`
	TestOTPBypassPhones  string `env:"AUTH_TEST_OTP_BYPASS_PHONES, default="`
	TestOTPBypassCode    string `env:"AUTH_TEST_OTP_BYPASS_CODE, default="`
}

type GoogleConfig struct {
	ClientID string `env:"GOOGLE_CLIENT_ID, default="`
}

type AppleConfig struct {
	TeamID   string `env:"APPLE_TEAM_ID, default="`
	BundleID string `env:"APPLE_BUNDLE_ID, default="`
}

type AntiFraudConfig struct {
	Enabled              bool          `env:"ANTI_FRAUD_ENABLED, default=false"`
	BaseURL              string        `env:"ANTI_FRAUD_BASE_URL, default=http://anti-fraud-service:8096"`
	InternalServiceToken string        `env:"ANTI_FRAUD_INTERNAL_SERVICE_TOKEN"`
	SignalHashKey        string        `env:"ANTI_FRAUD_SIGNAL_HASH_KEY"`
	Timeout              time.Duration `env:"ANTI_FRAUD_TIMEOUT, default=800ms"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("loading config: %w", err)
	}
	return &cfg, nil
}
