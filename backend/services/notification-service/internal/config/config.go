package config

import (
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/sethvargo/go-envconfig"

	"kz/inflap/backend/pkg/transportauth"
)

type Config struct {
	App       AppConfig
	HTTP      HTTPConfig
	DB        DBConfig
	Log       LogConfig
	Security  SecurityConfig
	NATS      NATSConfig
	Workers   WorkerConfig
	Providers ProviderConfig
	MTLS      transportauth.EnvConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=notification-service"`
	Env  string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(strings.TrimSpace(a.Env), "production")
}

type HTTPConfig struct {
	Port            int           `env:"HTTP_PORT, default=8097"`
	InternalTLSPort int           `env:"INTERNAL_HTTP_TLS_PORT, default=0"`
	ReadTimeout     time.Duration `env:"HTTP_READ_TIMEOUT, default=10s"`
	WriteTimeout    time.Duration `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout     time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
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
	Name            string `env:"DB_NAME, default=notification_service_db"`
	User            string `env:"DB_USER, default=postgres"`
	Password        string `env:"DB_PASSWORD, default=postgres"`
	SSLMode         string `env:"DB_SSLMODE, default=disable"`
	MaxConns        int32  `env:"DB_MAX_CONNS, default=60"`
	MinConns        int32  `env:"DB_MIN_CONNS, default=5"`
	MaxConnIdleTime string `env:"DB_MAX_CONN_IDLE, default=5m"`
	MaxConnLifetime string `env:"DB_MAX_CONN_LIFETIME, default=1h"`
}

func (d DBConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		d.User,
		d.Password,
		d.Host,
		d.Port,
		d.Name,
		d.SSLMode,
	)
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
	InternalServiceToken       string `env:"INTERNAL_SERVICE_TOKEN"`
	TrustedGatewayHeaderUserID string `env:"TRUSTED_GATEWAY_HEADER_USER_ID, default=X-User-Id"`
	TrustedGatewayHeaderRoles  string `env:"TRUSTED_GATEWAY_HEADER_ROLES, default=X-User-Roles"`
	TrustedGatewayHeaderSub    string `env:"TRUSTED_GATEWAY_HEADER_SUB, default=X-Auth-Subject"`
	RequestIDHeader            string `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
	TokenEncryptionKeyBase64   string `env:"NOTIFICATION_TOKEN_ENCRYPTION_KEY_BASE64"`
	TokenHashKeyBase64         string `env:"NOTIFICATION_TOKEN_HASH_KEY_BASE64"`
}

type NATSConfig struct {
	URL                 string        `env:"NATS_URL, default=nats://localhost:4222"`
	BatchSize           int           `env:"NATS_BATCH_SIZE, default=500"`
	FanoutConcurrency   int           `env:"NATS_FANOUT_CONCURRENCY, default=8"`
	DeliveryConcurrency int           `env:"NATS_DELIVERY_CONCURRENCY, default=64"`
	MaxDeliver          int           `env:"NATS_MAX_DELIVER, default=10"`
	MaxAckPending       int           `env:"NATS_MAX_ACK_PENDING, default=8192"`
	StreamMaxBytes      int64         `env:"NATS_STREAM_MAX_BYTES, default=536870912"`
	AckWait             time.Duration `env:"NATS_ACK_WAIT, default=30s"`
	NakDelay            time.Duration `env:"NATS_NAK_DELAY, default=1s"`
	FetchMaxWait        time.Duration `env:"NATS_FETCH_MAX_WAIT, default=500ms"`
}

type WorkerConfig struct {
	Enabled            bool          `env:"NOTIFICATION_WORKERS_ENABLED, default=true"`
	RetryScanInterval  time.Duration `env:"NOTIFICATION_RETRY_SCAN_INTERVAL, default=5s"`
	RetryScanBatchSize int           `env:"NOTIFICATION_RETRY_SCAN_BATCH_SIZE, default=500"`
}

type ProviderConfig struct {
	FCM  FCMConfig
	APNS APNSConfig
	HMS  HMSConfig
}

type FCMConfig struct {
	Enabled                bool          `env:"FCM_ENABLED, default=false"`
	ProjectID              string        `env:"FCM_PROJECT_ID"`
	ServiceAccountJSONPath string        `env:"FCM_SERVICE_ACCOUNT_JSON_PATH"`
	TokenURL               string        `env:"FCM_TOKEN_URL, default=https://oauth2.googleapis.com/token"`
	Timeout                time.Duration `env:"FCM_TIMEOUT, default=5s"`
}

type APNSConfig struct {
	Enabled     bool          `env:"APNS_ENABLED, default=false"`
	Environment string        `env:"APNS_ENV, default=sandbox"`
	TeamID      string        `env:"APNS_TEAM_ID"`
	KeyID       string        `env:"APNS_KEY_ID"`
	BundleID    string        `env:"APNS_BUNDLE_ID"`
	AuthKeyPath string        `env:"APNS_AUTH_KEY_PATH"`
	Timeout     time.Duration `env:"APNS_TIMEOUT, default=5s"`
}

type HMSConfig struct {
	Enabled      bool          `env:"HMS_ENABLED, default=false"`
	AppID        string        `env:"HMS_APP_ID"`
	ClientID     string        `env:"HMS_CLIENT_ID"`
	ClientSecret string        `env:"HMS_CLIENT_SECRET"`
	TokenURL     string        `env:"HMS_TOKEN_URL, default=https://oauth-login.cloud.huawei.com/oauth2/v3/token"`
	SendURL      string        `env:"HMS_SEND_URL"`
	Timeout      time.Duration `env:"HMS_TIMEOUT, default=5s"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	if err := applySecretFiles(&cfg); err != nil {
		return nil, err
	}
	if strings.TrimSpace(cfg.Security.InternalServiceToken) == "" {
		return nil, fmt.Errorf("INTERNAL_SERVICE_TOKEN is required")
	}
	if strings.TrimSpace(cfg.Security.TokenEncryptionKeyBase64) == "" {
		return nil, fmt.Errorf("NOTIFICATION_TOKEN_ENCRYPTION_KEY_BASE64 is required")
	}
	if strings.TrimSpace(cfg.Security.TokenHashKeyBase64) == "" {
		return nil, fmt.Errorf("NOTIFICATION_TOKEN_HASH_KEY_BASE64 is required")
	}
	if cfg.NATS.BatchSize <= 0 {
		return nil, fmt.Errorf("NATS_BATCH_SIZE must be greater than 0")
	}
	if cfg.NATS.FanoutConcurrency <= 0 {
		return nil, fmt.Errorf("NATS_FANOUT_CONCURRENCY must be greater than 0")
	}
	if cfg.NATS.DeliveryConcurrency <= 0 {
		return nil, fmt.Errorf("NATS_DELIVERY_CONCURRENCY must be greater than 0")
	}
	if cfg.NATS.MaxDeliver <= 0 {
		return nil, fmt.Errorf("NATS_MAX_DELIVER must be greater than 0")
	}
	if cfg.NATS.MaxAckPending <= 0 {
		return nil, fmt.Errorf("NATS_MAX_ACK_PENDING must be greater than 0")
	}
	if cfg.NATS.StreamMaxBytes <= 0 {
		return nil, fmt.Errorf("NATS_STREAM_MAX_BYTES must be greater than 0")
	}
	if cfg.NATS.AckWait <= 0 {
		return nil, fmt.Errorf("NATS_ACK_WAIT must be greater than 0")
	}
	if cfg.NATS.NakDelay <= 0 {
		return nil, fmt.Errorf("NATS_NAK_DELAY must be greater than 0")
	}
	if cfg.NATS.FetchMaxWait <= 0 {
		return nil, fmt.Errorf("NATS_FETCH_MAX_WAIT must be greater than 0")
	}
	if cfg.Workers.RetryScanInterval <= 0 {
		return nil, fmt.Errorf("NOTIFICATION_RETRY_SCAN_INTERVAL must be greater than 0")
	}
	if cfg.Workers.RetryScanBatchSize <= 0 {
		return nil, fmt.Errorf("NOTIFICATION_RETRY_SCAN_BATCH_SIZE must be greater than 0")
	}
	if cfg.DB.MaxConns <= 0 {
		return nil, fmt.Errorf("DB_MAX_CONNS must be greater than 0")
	}
	return &cfg, nil
}

func applySecretFiles(cfg *Config) error {
	secrets := []struct {
		envName string
		target  *string
	}{
		{envName: "DB_PASSWORD_FILE", target: &cfg.DB.Password},
		{envName: "INTERNAL_SERVICE_TOKEN_FILE", target: &cfg.Security.InternalServiceToken},
		{envName: "NOTIFICATION_TOKEN_ENCRYPTION_KEY_BASE64_FILE", target: &cfg.Security.TokenEncryptionKeyBase64},
		{envName: "NOTIFICATION_TOKEN_HASH_KEY_BASE64_FILE", target: &cfg.Security.TokenHashKeyBase64},
		{envName: "HMS_CLIENT_SECRET_FILE", target: &cfg.Providers.HMS.ClientSecret},
	}
	for _, secret := range secrets {
		path := strings.TrimSpace(os.Getenv(secret.envName))
		if path == "" {
			continue
		}
		value, err := readSecretFile(path)
		if err != nil {
			return fmt.Errorf("read %s: %w", secret.envName, err)
		}
		*secret.target = value
	}
	return nil
}

func readSecretFile(path string) (string, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return strings.TrimRight(string(data), "\r\n"), nil
}
