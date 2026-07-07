package config

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/sethvargo/go-envconfig"

	"kz/inflap/backend/pkg/transportauth"
)

type Config struct {
	App     AppConfig
	HTTP    HTTPConfig
	Log     LogConfig
	Engines EngineConfig
	Cache   CacheConfig
	Data    DataConfig
	MTLS    transportauth.EnvConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=routing-service"`
	Env  string `env:"APP_ENV, default=development"`
}

type HTTPConfig struct {
	Port            int           `env:"HTTP_PORT, default=8094"`
	InternalTLSPort int           `env:"INTERNAL_HTTP_TLS_PORT, default=0"`
	ReadTimeout     time.Duration `env:"HTTP_READ_TIMEOUT, default=10s"`
	WriteTimeout    time.Duration `env:"HTTP_WRITE_TIMEOUT, default=20s"`
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

type EngineConfig struct {
	ValhallaURL string        `env:"VALHALLA_URL, default=http://valhalla:8002"`
	OSRMURL     string        `env:"OSRM_URL, default=http://osrm:5000"`
	OTPURL      string        `env:"OTP_URL"`
	Timeout     time.Duration `env:"ROUTING_ENGINE_TIMEOUT, default=5s"`
	EnableOSRM  bool          `env:"ROUTING_ENABLE_OSRM, default=true"`
	EnableOTP   bool          `env:"ROUTING_ENABLE_OTP, default=false"`
}

type CacheConfig struct {
	RedisURL  string        `env:"REDIS_URL"`
	KeyPrefix string        `env:"ROUTING_CACHE_KEY_PREFIX, default=routing-service:cache:"`
	TTL       time.Duration `env:"ROUTING_CACHE_TTL, default=15m"`
}

type DataConfig struct {
	Region              string `env:"ROUTING_DATA_REGION, default=unknown"`
	OSMSource           string `env:"ROUTING_OSM_SOURCE"`
	OSMDataVersion      string `env:"ROUTING_OSM_DATA_VERSION"`
	TransitEnabled      bool   `env:"ROUTING_TRANSIT_ENABLED, default=false"`
	TransitCityCode     string `env:"ROUTING_TRANSIT_CITY_CODE"`
	GTFSVersion         string `env:"ROUTING_TRANSIT_GTFS_VERSION"`
	LegacyGTFSVersion   string `env:"ROUTING_GTFS_VERSION"`
	GeneratedAt         string `env:"ROUTING_DATA_GENERATED_AT"`
	AttributionRequired bool   `env:"ROUTING_ATTRIBUTION_REQUIRED, default=true"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	cfg.normalize()
	return &cfg, nil
}

func (cfg *Config) TransitRuntimeEnabled() bool {
	if cfg == nil {
		return false
	}
	return cfg.Data.TransitEnabled &&
		strings.TrimSpace(cfg.Data.TransitCityCode) != "" &&
		strings.TrimSpace(cfg.Data.GTFSVersion) != "" &&
		cfg.Engines.EnableOTP &&
		strings.TrimSpace(cfg.Engines.OTPURL) != ""
}

func (cfg *Config) normalize() {
	cfg.Data.Region = strings.TrimSpace(cfg.Data.Region)
	cfg.Data.OSMSource = strings.TrimSpace(cfg.Data.OSMSource)
	cfg.Data.OSMDataVersion = strings.TrimSpace(cfg.Data.OSMDataVersion)
	cfg.Data.TransitCityCode = strings.TrimSpace(cfg.Data.TransitCityCode)
	cfg.Data.GTFSVersion = strings.TrimSpace(cfg.Data.GTFSVersion)
	if cfg.Data.GTFSVersion == "" {
		cfg.Data.GTFSVersion = strings.TrimSpace(cfg.Data.LegacyGTFSVersion)
	}
	cfg.Data.GeneratedAt = strings.TrimSpace(cfg.Data.GeneratedAt)
	cfg.Engines.OTPURL = strings.TrimSpace(cfg.Engines.OTPURL)
	cfg.Engines.ValhallaURL = strings.TrimSpace(cfg.Engines.ValhallaURL)
	cfg.Engines.OSRMURL = strings.TrimSpace(cfg.Engines.OSRMURL)
}
