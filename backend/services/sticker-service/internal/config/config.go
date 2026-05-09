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
	DB          DBConfig
	Log         LogConfig
	Security    SecurityConfig
	FileManager FileManagerConfig
	Sticker     StickerConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=sticker-service"`
	Env  string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(strings.TrimSpace(a.Env), "production")
}

type HTTPConfig struct {
	Port         int           `env:"HTTP_PORT, default=8092"`
	ReadTimeout  time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout time.Duration `env:"HTTP_WRITE_TIMEOUT, default=30s"`
	IdleTimeout  time.Duration `env:"HTTP_IDLE_TIMEOUT, default=120s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

type DBConfig struct {
	Host            string `env:"DB_HOST, default=localhost"`
	Port            int    `env:"DB_PORT, default=5432"`
	Name            string `env:"DB_NAME, default=sticker_service_db"`
	User            string `env:"DB_USER, default=postgres"`
	Password        string `env:"DB_PASSWORD, default=postgres"`
	SSLMode         string `env:"DB_SSLMODE, default=disable"`
	MaxConns        int32  `env:"DB_MAX_CONNS, default=20"`
	MinConns        int32  `env:"DB_MIN_CONNS, default=2"`
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
	InternalServiceToken       string `env:"INTERNAL_SERVICE_TOKEN, required"`
	TrustedGatewayHeaderUserID string `env:"TRUSTED_GATEWAY_HEADER_USER_ID, default=X-User-Id"`
	TrustedGatewayHeaderRoles  string `env:"TRUSTED_GATEWAY_HEADER_ROLES, default=X-User-Roles"`
	TrustedGatewayHeaderSub    string `env:"TRUSTED_GATEWAY_HEADER_SUB, default=X-Auth-Subject"`
	RequestIDHeader            string `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
}

type FileManagerConfig struct {
	BaseURL              string        `env:"FILE_MANAGER_BASE_URL, default=http://localhost:8083"`
	Timeout              time.Duration `env:"FILE_MANAGER_TIMEOUT, default=5s"`
	InternalServiceToken string        `env:"FILE_MANAGER_INTERNAL_SERVICE_TOKEN"`
}

func (f FileManagerConfig) EffectiveInternalServiceToken(fallback string) string {
	if strings.TrimSpace(f.InternalServiceToken) != "" {
		return strings.TrimSpace(f.InternalServiceToken)
	}
	return strings.TrimSpace(fallback)
}

type StickerConfig struct {
	PostModerationEnabled bool          `env:"POST_MODERATION_ENABLED, default=true"`
	UploadSessionTTL      time.Duration `env:"STICKER_UPLOAD_SESSION_TTL, default=15m"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}

	if strings.TrimSpace(cfg.FileManager.BaseURL) == "" {
		return nil, fmt.Errorf("FILE_MANAGER_BASE_URL is required")
	}
	if cfg.FileManager.Timeout <= 0 {
		return nil, fmt.Errorf("FILE_MANAGER_TIMEOUT must be greater than 0")
	}
	if cfg.Sticker.UploadSessionTTL <= 0 {
		return nil, fmt.Errorf("STICKER_UPLOAD_SESSION_TTL must be greater than 0")
	}

	return &cfg, nil
}
