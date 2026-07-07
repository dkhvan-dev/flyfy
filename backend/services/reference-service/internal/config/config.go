package config

import (
	"context"
	"fmt"
	"time"

	"github.com/sethvargo/go-envconfig"

	"kz/inflap/backend/pkg/transportauth"
)

type Config struct {
	App  AppConfig
	HTTP HTTPConfig
	Log  LogConfig
	MTLS transportauth.EnvConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=reference-service"`
	Env  string `env:"APP_ENV, default=development"`
}

type HTTPConfig struct {
	Port            int           `env:"HTTP_PORT, default=8089"`
	InternalTLSPort int           `env:"INTERNAL_HTTP_TLS_PORT, default=0"`
	ReadTimeout     time.Duration `env:"HTTP_READ_TIMEOUT, default=10s"`
	WriteTimeout    time.Duration `env:"HTTP_WRITE_TIMEOUT, default=10s"`
	IdleTimeout     time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

func (h HTTPConfig) InternalTLSAddress() string {
	return fmt.Sprintf(":%d", h.InternalTLSPort)
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	return &cfg, nil
}
