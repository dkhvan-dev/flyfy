package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	App  AppConfig
	HTTP HTTPConfig
	GRPC GRPCConfig
	DB   DBConfig
	Log  LogConfig
}

type AppConfig struct {
	Name string
	Env  string
}

type HTTPConfig struct {
	Port string
}

type GRPCConfig struct {
	Port string
}

type DBConfig struct {
	Host        string
	Port        string
	Name        string
	User        string
	Password    string
	SSLMode     string
	MaxConns    int32
	MinConns    int32
	MaxConnIdle time.Duration
	MaxConnLife time.Duration
}

type LogConfig struct {
	Level string
}

func Load() (*Config, error) {
	cfg := &Config{
		App: AppConfig{
			Name: getEnv("APP_NAME", "activity-service"),
			Env:  getEnv("APP_ENV", "local"),
		},
		HTTP: HTTPConfig{
			Port: getEnv("HTTP_PORT", "8080"),
		},
		GRPC: GRPCConfig{
			Port: getEnv("GRPC_PORT", "9090"),
		},
		DB: DBConfig{
			Host:        getEnv("DB_HOST", "localhost"),
			Port:        getEnv("DB_PORT", "5432"),
			Name:        getEnv("DB_NAME", "activity_service"),
			User:        getEnv("DB_USER", "postgres"),
			Password:    getEnv("DB_PASSWORD", "postgres"),
			SSLMode:     getEnv("DB_SSLMODE", "disable"),
			MaxConns:    getEnvAsInt32("DB_MAX_CONNS", 10),
			MinConns:    getEnvAsInt32("DB_MIN_CONNS", 2),
			MaxConnIdle: getEnvAsDuration("DB_MAX_CONN_IDLE", 15*time.Minute),
			MaxConnLife: getEnvAsDuration("DB_MAX_CONN_LIFETIME", time.Hour),
		},
		Log: LogConfig{
			Level: strings.ToLower(getEnv("LOG_LEVEL", "info")),
		},
	}

	if err := cfg.Validate(); err != nil {
		return nil, err
	}

	return cfg, nil
}

func (c *Config) Validate() error {
	if strings.TrimSpace(c.HTTP.Port) == "" {
		return fmt.Errorf("http port is required")
	}
	if strings.TrimSpace(c.GRPC.Port) == "" {
		return fmt.Errorf("grpc port is required")
	}
	if strings.TrimSpace(c.DB.Host) == "" {
		return fmt.Errorf("db host is required")
	}
	if strings.TrimSpace(c.DB.Port) == "" {
		return fmt.Errorf("db port is required")
	}
	if strings.TrimSpace(c.DB.Name) == "" {
		return fmt.Errorf("db name is required")
	}
	if strings.TrimSpace(c.DB.User) == "" {
		return fmt.Errorf("db user is required")
	}
	if c.DB.MaxConns <= 0 {
		return fmt.Errorf("db max conns must be > 0")
	}
	if c.DB.MinConns < 0 {
		return fmt.Errorf("db min conns must be >= 0")
	}
	return nil
}

func (c *Config) DatabaseURL() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=%s",
		c.DB.User,
		c.DB.Password,
		c.DB.Host,
		c.DB.Port,
		c.DB.Name,
		c.DB.SSLMode,
	)
}

func getEnv(key string, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

func getEnvAsInt32(key string, fallback int32) int32 {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}

	parsed, err := strconv.ParseInt(value, 10, 32)
	if err != nil {
		return fallback
	}

	return int32(parsed)
}

func getEnvAsDuration(key string, fallback time.Duration) time.Duration {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}

	parsed, err := time.ParseDuration(value)
	if err != nil {
		return fallback
	}

	return parsed
}
