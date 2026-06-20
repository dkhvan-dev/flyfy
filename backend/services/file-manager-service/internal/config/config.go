package config

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	App       AppConfig
	HTTP      HTTPConfig
	GRPC      GRPCConfig
	Postgres  PostgresConfig
	Storage   StorageConfig
	Log       LogConfig
	Security  SecurityConfig
	AntiFraud AntiFraudConfig
	Trust     TrustServiceConfig
	Switches  SwitchesServiceConfig
}

type AppConfig struct {
	Env string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(a.Env, "production")
}

type HTTPConfig struct {
	Port         int           `env:"HTTP_PORT, default=8083"`
	ReadTimeout  time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout time.Duration `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout  time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

type GRPCConfig struct {
	Port int `env:"GRPC_PORT, default=9093"`
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

type StorageConfig struct {
	Provider        string `env:"STORAGE_PROVIDER, default=s3"`
	Endpoint        string `env:"STORAGE_ENDPOINT, required"`
	Region          string `env:"STORAGE_REGION, default=auto"`
	AccessKeyID     string `env:"STORAGE_ACCESS_KEY_ID, required"`
	SecretAccessKey string `env:"STORAGE_SECRET_ACCESS_KEY, required"`
	Bucket          string `env:"STORAGE_BUCKET, required"`

	PresignTTL   string `env:"STORAGE_PRESIGN_TTL, default=15m"`
	PublicURL    string `env:"STORAGE_PUBLIC_URL"`
	UsePathStyle bool   `env:"STORAGE_USE_PATH_STYLE, default=true"`

	MaxUploadSizeBytes int64 `env:"STORAGE_MAX_UPLOAD_SIZE_BYTES, default=10485760"` // 10 MB

	PublicContentCacheMaxAge string `env:"STORAGE_PUBLIC_CONTENT_CACHE_MAX_AGE, default=24h"`
	HTTPMaxIdleConns         int    `env:"STORAGE_HTTP_MAX_IDLE_CONNS, default=4096"`
	HTTPMaxIdleConnsPerHost  int    `env:"STORAGE_HTTP_MAX_IDLE_CONNS_PER_HOST, default=2048"`
	HTTPMaxConnsPerHost      int    `env:"STORAGE_HTTP_MAX_CONNS_PER_HOST, default=0"`
	HTTPIdleConnTimeout      string `env:"STORAGE_HTTP_IDLE_CONN_TIMEOUT, default=90s"`
}

func (s StorageConfig) ParsedPresignTTL() time.Duration {
	d, err := time.ParseDuration(s.PresignTTL)
	if err != nil {
		return 15 * time.Minute
	}
	return d
}

func (s StorageConfig) ParsedPublicContentCacheMaxAge() time.Duration {
	d, err := time.ParseDuration(s.PublicContentCacheMaxAge)
	if err != nil {
		return 24 * time.Hour
	}
	return d
}

func (s StorageConfig) ParsedHTTPIdleConnTimeout() time.Duration {
	d, err := time.ParseDuration(s.HTTPIdleConnTimeout)
	if err != nil {
		return 90 * time.Second
	}
	return d
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}

	if cfg.Storage.MaxUploadSizeBytes <= 0 {
		return nil, fmt.Errorf("STORAGE_MAX_UPLOAD_SIZE_BYTES must be greater than 0")
	}

	return &cfg, nil
}

type SecurityConfig struct {
	InternalServiceToken       string `env:"INTERNAL_SERVICE_TOKEN, required"`
	RequireAuthenticatedWrites bool   `env:"REQUIRE_AUTHENTICATED_WRITES, default=true"`
	TrustedGatewayHeaderUserID string `env:"TRUSTED_GATEWAY_HEADER_USER_ID, default=X-User-Id"`
	TrustedGatewayHeaderRoles  string `env:"TRUSTED_GATEWAY_HEADER_ROLES, default=X-User-Roles"`
	RequestIDHeader            string `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
}

type AntiFraudConfig struct {
	Enabled              bool          `env:"ANTI_FRAUD_ENABLED, default=false"`
	BaseURL              string        `env:"ANTI_FRAUD_BASE_URL, default=http://anti-fraud-service:8096"`
	InternalServiceToken string        `env:"ANTI_FRAUD_INTERNAL_SERVICE_TOKEN"`
	SignalHashKey        string        `env:"ANTI_FRAUD_SIGNAL_HASH_KEY"`
	Timeout              time.Duration `env:"ANTI_FRAUD_TIMEOUT, default=800ms"`
}

type TrustServiceConfig struct {
	Enabled bool          `env:"TRUST_POLICY_ENABLED, default=true"`
	Target  string        `env:"TRUST_SERVICE_GRPC_TARGET, default=trust-service:9096"`
	Timeout time.Duration `env:"TRUST_SERVICE_TIMEOUT, default=250ms"`
}

type SwitchesServiceConfig struct {
	HTTPURL              string        `env:"SWITCHES_SERVICE_URL, default=http://switches-service:8096"`
	InternalServiceToken string        `env:"SWITCHES_INTERNAL_SERVICE_TOKEN"`
	RequestTimeout       time.Duration `env:"SWITCHES_SERVICE_TIMEOUT, default=800ms"`
}
