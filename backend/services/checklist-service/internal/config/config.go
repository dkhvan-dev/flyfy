package config

import (
	"context"
	"fmt"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	App           AppConfig
	HTTP          HTTPConfig
	DB            DBConfig
	Log           LogConfig
	Notifications NotificationConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=checklist-service"`
	Env  string `env:"APP_ENV, default=development"`
}

type HTTPConfig struct {
	Port         int           `env:"HTTP_PORT, default=8099"`
	ReadTimeout  time.Duration `env:"HTTP_READ_TIMEOUT, default=10s"`
	WriteTimeout time.Duration `env:"HTTP_WRITE_TIMEOUT, default=10s"`
	IdleTimeout  time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type NotificationConfig struct {
	ServiceBaseURL       string        `env:"NOTIFICATION_SERVICE_BASE_URL"`
	InternalServiceToken string        `env:"NOTIFICATION_INTERNAL_SERVICE_TOKEN"`
	DispatchServiceToken string        `env:"CHECKLIST_INTERNAL_SERVICE_TOKEN"`
	HTTPTimeout          time.Duration `env:"NOTIFICATION_HTTP_TIMEOUT, default=3s"`
	DispatchEnabled      bool          `env:"CHECKLIST_NOTIFICATION_DISPATCH_ENABLED, default=true"`
	DispatchInterval     time.Duration `env:"CHECKLIST_NOTIFICATION_DISPATCH_INTERVAL, default=1h"`
	DispatchBatchSize    int           `env:"CHECKLIST_NOTIFICATION_DISPATCH_BATCH_SIZE, default=100"`
	DispatchDefaultLang  string        `env:"CHECKLIST_NOTIFICATION_DEFAULT_LANG, default=ru"`
}

func (n NotificationConfig) IsSenderConfigured() bool {
	return n.ServiceBaseURL != "" && n.InternalServiceToken != ""
}

type DBConfig struct {
	Host            string `env:"DB_HOST, default=localhost"`
	Port            int    `env:"DB_PORT, default=5432"`
	Name            string `env:"DB_NAME, default=checklist_service_db"`
	User            string `env:"DB_USER, default=postgres"`
	Password        string `env:"DB_PASSWORD, default=postgres"`
	SSLMode         string `env:"DB_SSLMODE, default=disable"`
	MaxConns        int32  `env:"DB_MAX_CONNS, default=10"`
	MinConns        int32  `env:"DB_MIN_CONNS, default=2"`
	MaxConnIdleTime string `env:"DB_MAX_CONN_IDLE, default=5m"`
	MaxConnLifetime string `env:"DB_MAX_CONN_LIFETIME, default=1h"`
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

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	return &cfg, nil
}
