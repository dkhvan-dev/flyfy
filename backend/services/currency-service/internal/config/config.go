package config

import (
	"context"
	"fmt"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	App      AppConfig
	HTTP     HTTPConfig
	Log      LogConfig
	Provider ProviderConfig
	Switches SwitchesServiceConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=currency-service"`
	Env  string `env:"APP_ENV, default=development"`
}

type HTTPConfig struct {
	Port         int           `env:"HTTP_PORT, default=8098"`
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

type ProviderConfig struct {
	BaseURL  string        `env:"CURRENCY_PROVIDER_BASE_URL, default=https://open.er-api.com/v6/latest"`
	Timeout  time.Duration `env:"CURRENCY_PROVIDER_TIMEOUT, default=5s"`
	CacheTTL time.Duration `env:"CURRENCY_RATE_CACHE_TTL, default=1h"`
}

type SwitchesServiceConfig struct {
	HTTPURL              string        `env:"SWITCHES_SERVICE_URL, default=http://switches-service:8096"`
	InternalServiceToken string        `env:"SWITCHES_INTERNAL_SERVICE_TOKEN"`
	RequestTimeout       time.Duration `env:"SWITCHES_SERVICE_TIMEOUT, default=800ms"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	return &cfg, nil
}
