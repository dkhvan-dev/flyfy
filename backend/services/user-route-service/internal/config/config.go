package config

import (
	"context"
	"fmt"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	App  AppConfig
	HTTP HTTPConfig
	Log  LogConfig
	DB   DBConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=user-route-service"`
	Env  string `env:"APP_ENV, default=development"`
}

type HTTPConfig struct {
	Port         int           `env:"HTTP_PORT, default=8096"`
	ReadTimeout  time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout time.Duration `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout  time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type DBConfig struct {
	Host            string        `env:"POSTGRES_HOST, default=localhost"`
	Port            int           `env:"POSTGRES_PORT, default=5446"`
	User            string        `env:"POSTGRES_USER, default=user_route_service"`
	Password        string        `env:"POSTGRES_PASSWORD, default=user_route_secret_dev"`
	Database        string        `env:"POSTGRES_DB, default=user_route_service_db"`
	SSLMode         string        `env:"POSTGRES_SSLMODE, default=disable"`
	MaxConns        int32         `env:"POSTGRES_MAX_CONNS, default=10"`
	MinConns        int32         `env:"POSTGRES_MIN_CONNS, default=1"`
	MaxConnLifetime time.Duration `env:"POSTGRES_MAX_CONN_LIFETIME, default=30m"`
	MaxConnIdleTime time.Duration `env:"POSTGRES_MAX_CONN_IDLE_TIME, default=5m"`
}

func (d DBConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		d.User,
		d.Password,
		d.Host,
		d.Port,
		d.Database,
		d.SSLMode,
	)
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	if cfg.DB.MaxConns < cfg.DB.MinConns {
		cfg.DB.MaxConns = cfg.DB.MinConns
	}
	return &cfg, nil
}
