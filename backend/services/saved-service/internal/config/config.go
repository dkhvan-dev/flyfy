package config

import (
	"context"
	"fmt"
	"net"
	"net/url"
	"strings"
	"time"
	"unicode"

	"github.com/sethvargo/go-envconfig"

	"kz/inflap/backend/pkg/transportauth"
)

const serviceName = "saved-service"

type Config struct {
	App            AppConfig
	HTTP           HTTPConfig
	Log            LogConfig
	DB             DBConfig
	TokenService   TokenServiceConfig
	GatewayAuth    GatewayAuthConfig
	Sources        SourceConfig
	InternalAuth   InternalAuthConfig
	UserAccess     UserAccessConfig
	PlatformPolicy PlatformPolicyConfig
	Dependencies   DependencyTimeoutConfig
	Crypto         CryptoConfig
	Limits         OwnerLimitsConfig
	Features       FeatureConfig
	Rollout        RolloutConfig
	PublicAPI      PublicAPIConfig
	NATS           NATSConfig
	Compliance     ComplianceConfig
	MTLS           transportauth.EnvConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=saved-service"`
	Env  string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsDevelopmentLike() bool {
	switch strings.ToLower(strings.TrimSpace(a.Env)) {
	case "development", "test":
		return true
	default:
		return false
	}
}

func (a AppConfig) IsSecureEnvironment() bool {
	switch strings.ToLower(strings.TrimSpace(a.Env)) {
	case "staging", "production":
		return true
	default:
		return false
	}
}

type HTTPConfig struct {
	Port              int           `env:"HTTP_PORT, default=8102"`
	InternalTLSPort   int           `env:"INTERNAL_HTTP_TLS_PORT, default=0"`
	ReadHeaderTimeout time.Duration `env:"HTTP_READ_HEADER_TIMEOUT, default=5s"`
	ReadTimeout       time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout      time.Duration `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout       time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
	ShutdownTimeout   time.Duration `env:"HTTP_SHUTDOWN_TIMEOUT, default=10s"`
	ReadinessTimeout  time.Duration `env:"READINESS_TIMEOUT, default=2s"`
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

type DBConfig struct {
	Host            string        `env:"POSTGRES_HOST, default=localhost"`
	Port            int           `env:"POSTGRES_PORT, default=5432"`
	User            string        `env:"POSTGRES_USER, default=saved_service"`
	Password        string        `env:"POSTGRES_PASSWORD"`
	Database        string        `env:"POSTGRES_DB, default=saved_service_db"`
	SSLMode         string        `env:"POSTGRES_SSLMODE, default=disable"`
	MaxConns        int32         `env:"POSTGRES_MAX_CONNS, default=10"`
	MinConns        int32         `env:"POSTGRES_MIN_CONNS, default=1"`
	MaxConnLifetime time.Duration `env:"POSTGRES_MAX_CONN_LIFETIME, default=30m"`
	MaxConnIdleTime time.Duration `env:"POSTGRES_MAX_CONN_IDLE_TIME, default=5m"`
}

func (d DBConfig) DSN() string {
	query := url.Values{}
	query.Set("sslmode", d.SSLMode)

	return (&url.URL{
		Scheme:   "postgres",
		User:     url.UserPassword(d.User, d.Password),
		Host:     net.JoinHostPort(d.Host, fmt.Sprintf("%d", d.Port)),
		Path:     d.Database,
		RawQuery: query.Encode(),
	}).String()
}

func (d DBConfig) String() string {
	return "DBConfig{redacted}"
}

func (d DBConfig) GoString() string {
	return d.String()
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process environment config: %w", err)
	}
	cfg.applyDevelopmentDefaults()
	if err := cfg.Validate(); err != nil {
		return nil, err
	}
	return &cfg, nil
}

func (c Config) Validate() error {
	env := strings.ToLower(strings.TrimSpace(c.App.Env))
	if strings.TrimSpace(c.App.Name) != serviceName {
		return fmt.Errorf("APP_NAME must be %q", serviceName)
	}
	if !isAllowedEnvironment(env) {
		return fmt.Errorf("APP_ENV must be one of development, test, staging, production")
	}
	if err := validateHTTP(c.HTTP); err != nil {
		return err
	}
	if err := validateLogLevel(c.Log.Level); err != nil {
		return err
	}
	if err := validateDB(c.DB, env); err != nil {
		return err
	}
	if err := c.NATS.Validate(c.App.IsSecureEnvironment()); err != nil {
		return err
	}
	if err := c.Compliance.Validate(c.App.IsSecureEnvironment()); err != nil {
		return err
	}
	if err := validateMTLS(c.MTLS, c.HTTP, c.App.IsSecureEnvironment()); err != nil {
		return err
	}
	if err := validateDependencies(c); err != nil {
		return err
	}
	if err := c.Crypto.Validate(c.App); err != nil {
		return err
	}
	if err := c.Limits.Validate(); err != nil {
		return err
	}
	if err := c.Features.Validate(c.Limits); err != nil {
		return err
	}
	if err := c.Rollout.Validate(); err != nil {
		return err
	}
	if err := c.PublicAPI.Validate(c.App.IsSecureEnvironment()); err != nil {
		return err
	}
	return nil
}

func (c Config) String() string {
	return "Config{app=saved-service secrets=redacted}"
}

func (c Config) GoString() string {
	return c.String()
}

func isAllowedEnvironment(env string) bool {
	switch env {
	case "development", "test", "staging", "production":
		return true
	default:
		return false
	}
}

func validateHTTP(cfg HTTPConfig) error {
	if !isValidPort(cfg.Port) {
		return fmt.Errorf("HTTP_PORT must be between 1 and 65535")
	}
	if cfg.InternalTLSPort != 0 && !isValidPort(cfg.InternalTLSPort) {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be 0 or between 1 and 65535")
	}
	if cfg.ReadHeaderTimeout <= 0 || cfg.ReadTimeout <= 0 || cfg.WriteTimeout <= 0 || cfg.IdleTimeout <= 0 || cfg.ShutdownTimeout <= 0 {
		return fmt.Errorf("HTTP timeouts must be positive")
	}
	if cfg.ReadinessTimeout <= 0 || cfg.ReadinessTimeout > 10*time.Second {
		return fmt.Errorf("READINESS_TIMEOUT must be greater than zero and no more than 10s")
	}
	return nil
}

func validateLogLevel(level string) error {
	switch strings.ToLower(strings.TrimSpace(level)) {
	case "trace", "debug", "info", "warn", "error", "fatal", "disabled":
		return nil
	default:
		return fmt.Errorf("LOG_LEVEL is invalid")
	}
}

func validateDB(cfg DBConfig, env string) error {
	if strings.TrimSpace(cfg.Host) == "" || strings.TrimSpace(cfg.User) == "" || strings.TrimSpace(cfg.Password) == "" || strings.TrimSpace(cfg.Database) == "" {
		return fmt.Errorf("PostgreSQL host, user, password, and database are required")
	}
	if !isValidPort(cfg.Port) {
		return fmt.Errorf("POSTGRES_PORT must be between 1 and 65535")
	}
	if cfg.MaxConns <= 0 || cfg.MinConns < 0 || cfg.MinConns > cfg.MaxConns {
		return fmt.Errorf("PostgreSQL pool requires 0 <= POSTGRES_MIN_CONNS <= POSTGRES_MAX_CONNS")
	}
	if cfg.MaxConnLifetime <= 0 || cfg.MaxConnIdleTime <= 0 {
		return fmt.Errorf("PostgreSQL connection lifetimes must be positive")
	}

	sslMode := strings.ToLower(strings.TrimSpace(cfg.SSLMode))
	switch sslMode {
	case "disable", "require", "verify-ca", "verify-full":
	default:
		return fmt.Errorf("POSTGRES_SSLMODE is invalid")
	}
	if (env == "staging" || env == "production") && sslMode != "verify-full" {
		return fmt.Errorf("POSTGRES_SSLMODE must be verify-full in staging and production")
	}
	if env == "staging" || env == "production" {
		if len(cfg.Password) < 16 || len(cfg.Password) > 4096 ||
			strings.IndexFunc(cfg.Password, unicode.IsControl) >= 0 || isPlaceholderSecret(cfg.Password) {
			return fmt.Errorf("POSTGRES_PASSWORD must be a non-placeholder secret between 16 and 4096 bytes")
		}
	}
	return nil
}

func validateMTLS(cfg transportauth.EnvConfig, httpCfg HTTPConfig, secureEnvironment bool) error {
	switch strings.ToLower(strings.TrimSpace(cfg.Mode)) {
	case "disabled":
		if secureEnvironment {
			return fmt.Errorf("MTLS_MODE must be enforce in staging and production")
		}
		if httpCfg.InternalTLSPort != 0 {
			return fmt.Errorf("INTERNAL_HTTP_TLS_PORT requires MTLS_MODE=enforce")
		}
	case "enforce":
		if httpCfg.InternalTLSPort == 0 {
			return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when MTLS_MODE=enforce")
		}
		if httpCfg.InternalTLSPort == httpCfg.Port {
			return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
		}
		if strings.TrimSpace(cfg.CACertPath) == "" ||
			strings.TrimSpace(cfg.ServerCertPath) == "" ||
			strings.TrimSpace(cfg.ServerKeyPath) == "" ||
			strings.TrimSpace(cfg.ClientCertPath) == "" ||
			strings.TrimSpace(cfg.ClientKeyPath) == "" {
			return fmt.Errorf("mTLS CA, server certificate/key, and client certificate/key paths are required")
		}
		if strings.TrimSpace(cfg.MinVersion) != "1.3" {
			return fmt.Errorf("MTLS_MIN_VERSION must be 1.3")
		}
	default:
		return fmt.Errorf("MTLS_MODE must be disabled or enforce")
	}
	return nil
}

func isValidPort(port int) bool {
	return port >= 1 && port <= 65535
}
