package config

import (
	"context"
	"fmt"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	App             AppConfig
	HTTP            HTTPConfig
	GRPC            GRPCConfig
	DB              DBConfig
	Log             LogConfig
	Security        SecurityConfig
	NATS            NATSConfig
	Redis           RedisConfig
	UserService     UserServiceConfig
	ActivityService ActivityServiceConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=chat-service"`
	Env  string `env:"APP_ENV, default=development"`
}

type HTTPConfig struct {
	Port         int           `env:"HTTP_PORT, default=8088"`
	ReadTimeout  time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout time.Duration `env:"HTTP_WRITE_TIMEOUT, default=120s"`
	IdleTimeout  time.Duration `env:"HTTP_IDLE_TIMEOUT, default=120s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

type GRPCConfig struct {
	Port int `env:"GRPC_PORT, default=9097"`
}

func (g GRPCConfig) Address() string {
	return fmt.Sprintf(":%d", g.Port)
}

type DBConfig struct {
	Host            string `env:"DB_HOST, default=localhost"`
	Port            int    `env:"DB_PORT, default=5432"`
	Name            string `env:"DB_NAME, default=chat_service_db"`
	User            string `env:"DB_USER, default=postgres"`
	Password        string `env:"DB_PASSWORD, default=postgres"`
	SSLMode         string `env:"DB_SSLMODE, default=disable"`
	MaxConns        int32  `env:"DB_MAX_CONNS, default=50"`
	MinConns        int32  `env:"DB_MIN_CONNS, default=5"`
	MaxConnIdleTime string `env:"DB_MAX_CONN_IDLE, default=5m"`
	MaxConnLifetime string `env:"DB_MAX_CONN_LIFETIME, default=1h"`
}

func (p DBConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		p.User, p.Password, p.Host, p.Port, p.Name, p.SSLMode,
	)
}

func (p DBConfig) ParsedMaxConnLifetime() time.Duration {
	d, err := time.ParseDuration(p.MaxConnLifetime)
	if err != nil {
		return time.Hour
	}
	return d
}

func (p DBConfig) ParsedMaxConnIdleTime() time.Duration {
	d, err := time.ParseDuration(p.MaxConnIdleTime)
	if err != nil {
		return 5 * time.Minute
	}
	return d
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type SecurityConfig struct {
	InternalServiceToken       string `env:"INTERNAL_SERVICE_TOKEN, required"`
	RequireAuthenticatedWrites bool   `env:"REQUIRE_AUTHENTICATED_WRITES, default=true"`
	TrustedGatewayHeaderUserID string `env:"TRUSTED_GATEWAY_HEADER_USER_ID, default=X-User-Id"`
	TrustedGatewayHeaderRoles  string `env:"TRUSTED_GATEWAY_HEADER_ROLES, default=X-User-Roles"`
	TrustedGatewayHeaderSub    string `env:"TRUSTED_GATEWAY_HEADER_SUB, default=X-Auth-Subject"`
	RequestIDHeader            string `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
}

type NATSConfig struct {
	URL string `env:"NATS_URL, default=nats://localhost:4222"`
}

type RedisConfig struct {
	Addr string `env:"REDIS_ADDR, default=localhost:6379"`
	DB   int    `env:"REDIS_DB, default=2"`
}

type UserServiceConfig struct {
	GRPCAddress string `env:"USER_SERVICE_GRPC_ADDR, default=user-service:9094"`
}

type ActivityServiceConfig struct {
	GRPCAddress string `env:"ACTIVITY_SERVICE_GRPC_ADDR, default=activity-service:9096"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	return &cfg, nil
}
