package config

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/sethvargo/go-envconfig"

	"kz/inflap/backend/pkg/natstransport"
	"kz/inflap/backend/pkg/transportauth"
)

type Config struct {
	App            AppConfig
	HTTP           HTTPConfig
	GRPC           GRPCConfig
	Postgres       PostgresConfig
	Log            LogConfig
	Security       SecurityConfig
	UserService    UserServiceConfig
	FileManager    FileManagerConfig
	Excursion      ExcursionServiceConfig
	AntiFraud      AntiFraudConfig
	TokenService   TokenServiceConfig
	SearchService  SearchServiceConfig
	SavedLifecycle SavedLifecycleConfig
	MTLS           transportauth.EnvConfig
}

type AppConfig struct {
	Env string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(a.Env, "production")
}

type HTTPConfig struct {
	Port            int           `env:"HTTP_PORT, default=8085"`
	InternalTLSPort int           `env:"INTERNAL_HTTP_TLS_PORT, default=0"`
	ReadTimeout     time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout    time.Duration `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout     time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

func (h HTTPConfig) InternalTLSAddress() string {
	return fmt.Sprintf(":%d", h.InternalTLSPort)
}

type GRPCConfig struct {
	Port            int `env:"GRPC_PORT, default=9095"`
	InternalTLSPort int `env:"INTERNAL_GRPC_TLS_PORT, default=0"`
}

func (g GRPCConfig) Address() string {
	return fmt.Sprintf(":%d", g.Port)
}

func (g GRPCConfig) InternalTLSAddress() string {
	return fmt.Sprintf(":%d", g.InternalTLSPort)
}

type PostgresConfig struct {
	Host            string `env:"POSTGRES_HOST, required"`
	Port            int    `env:"POSTGRES_PORT, default=5432"`
	User            string `env:"POSTGRES_USER, required"`
	Password        string `env:"POSTGRES_PASSWORD, required"`
	DBName          string `env:"POSTGRES_DB, required"`
	SSLMode         string `env:"POSTGRES_SSLMODE, default=disable"`
	MaxOpenConns    int32  `env:"POSTGRES_MAX_OPEN_CONNS, default=10"`
	MinOpenConns    int32  `env:"POSTGRES_MIN_OPEN_CONNS, default=2"`
	MaxConnLifetime string `env:"POSTGRES_MAX_CONN_LIFETIME, default=1h"`
	MaxConnIdleTime string `env:"POSTGRES_MAX_CONN_IDLE_TIME, default=30m"`
}

func (p PostgresConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		p.User,
		p.Password,
		p.Host,
		p.Port,
		p.DBName,
		p.SSLMode,
	)
}

func (p PostgresConfig) ParsedMaxConnLifetime() time.Duration {
	d, err := time.ParseDuration(p.MaxConnLifetime)
	if err != nil {
		return time.Hour
	}
	return d
}

func (p PostgresConfig) ParsedMaxConnIdleTime() time.Duration {
	d, err := time.ParseDuration(p.MaxConnIdleTime)
	if err != nil {
		return 30 * time.Minute
	}
	return d
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type SecurityConfig struct {
	InternalServiceToken       string        `env:"INTERNAL_SERVICE_TOKEN, required"`
	RequireAuthenticatedWrites bool          `env:"REQUIRE_AUTHENTICATED_WRITES, default=true"`
	TrustedGatewayHeaderUserID string        `env:"TRUSTED_GATEWAY_HEADER_USER_ID, default=X-User-Id"`
	TrustedGatewayHeaderRoles  string        `env:"TRUSTED_GATEWAY_HEADER_ROLES, default=X-User-Roles"`
	TrustedGatewayHeaderSub    string        `env:"TRUSTED_GATEWAY_HEADER_SUB, default=X-Auth-Subject"`
	RequestIDHeader            string        `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
	ServiceAuthIssuer          string        `env:"SERVICE_AUTH_ISSUER, default=tourism-inflap/token-service"`
	ServiceAuthJWKSURL         string        `env:"SERVICE_AUTH_JWKS_URL, default=http://token-service:8081/.well-known/jwks.json"`
	ServiceAuthCacheTTL        time.Duration `env:"SERVICE_AUTH_JWKS_CACHE_TTL, default=5m"`
	SavedSourceAllowedCaller   string        `env:"SAVED_SOURCE_ALLOWED_CALLER, default=saved-service"`
}

func (c SecurityConfig) SavedSourceAuthEnabled() bool {
	return strings.TrimSpace(c.ServiceAuthIssuer) != "" &&
		strings.TrimSpace(c.ServiceAuthJWKSURL) != "" &&
		strings.TrimSpace(c.SavedSourceAllowedCaller) != ""
}

type UserServiceConfig struct {
	Target string `env:"USER_SERVICE_GRPC_TARGET, default=dns:///user-service:9094"`
}

type FileManagerConfig struct {
	Target string `env:"FILE_MANAGER_GRPC_TARGET, default=dns:///file-manager-service:9093"`
}

type ExcursionServiceConfig struct {
	BaseURL string        `env:"EXCURSION_SERVICE_HTTP_URL, default=http://excursion-service:8093"`
	Timeout time.Duration `env:"EXCURSION_SERVICE_TIMEOUT, default=3s"`
}

type AntiFraudConfig struct {
	Enabled              bool          `env:"ANTI_FRAUD_ENABLED, default=false"`
	BaseURL              string        `env:"ANTI_FRAUD_BASE_URL, default=http://anti-fraud-service:8096"`
	InternalServiceToken string        `env:"ANTI_FRAUD_INTERNAL_SERVICE_TOKEN"`
	SignalHashKey        string        `env:"ANTI_FRAUD_SIGNAL_HASH_KEY"`
	Timeout              time.Duration `env:"ANTI_FRAUD_TIMEOUT, default=800ms"`
}

type SearchServiceConfig struct {
	Enabled bool          `env:"SEARCH_INDEXING_ENABLED, default=false"`
	HTTPURL string        `env:"SEARCH_SERVICE_HTTP_URL, default=http://search-service:8101"`
	Timeout time.Duration `env:"SEARCH_SERVICE_TIMEOUT, default=800ms"`
}

type TokenServiceConfig struct {
	Target        string        `env:"TOKEN_SERVICE_GRPC_TARGET, default=dns:///token-service:50051"`
	ServiceID     string        `env:"TOKEN_SERVICE_ID, default=guide-service"`
	ServiceSecret string        `env:"TOKEN_SERVICE_SECRET"`
	CallTimeout   time.Duration `env:"TOKEN_SERVICE_CALL_TIMEOUT, default=3s"`
}

type SavedLifecycleConfig struct {
	Enabled                bool `env:"SAVED_LIFECYCLE_ENABLED, default=false"`
	NATS                   natstransport.EnvConfig
	Subject                string        `env:"SAVED_LIFECYCLE_SUBJECT, default=saved.source.guide.lifecycle.v1"`
	BatchSize              int           `env:"SAVED_LIFECYCLE_BATCH_SIZE, default=50"`
	Concurrency            int           `env:"SAVED_LIFECYCLE_CONCURRENCY, default=8"`
	PollInterval           time.Duration `env:"SAVED_LIFECYCLE_POLL_INTERVAL, default=250ms"`
	LeaseDuration          time.Duration `env:"SAVED_LIFECYCLE_LEASE_DURATION, default=30s"`
	PublishTimeout         time.Duration `env:"SAVED_LIFECYCLE_PUBLISH_TIMEOUT, default=3s"`
	DeliveredRetention     time.Duration `env:"SAVED_LIFECYCLE_DELIVERED_RETENTION, default=336h"`
	DeadRetention          time.Duration `env:"SAVED_LIFECYCLE_DEAD_RETENTION, default=2160h"`
	CleanupInterval        time.Duration `env:"SAVED_LIFECYCLE_CLEANUP_INTERVAL, default=1h"`
	ReconcileBatchSize     int           `env:"SAVED_USER_RECONCILE_BATCH_SIZE, default=25"`
	ReconcileConcurrency   int           `env:"SAVED_USER_RECONCILE_CONCURRENCY, default=4"`
	ReconcilePollInterval  time.Duration `env:"SAVED_USER_RECONCILE_POLL_INTERVAL, default=500ms"`
	ReconcileLeaseDuration time.Duration `env:"SAVED_USER_RECONCILE_LEASE_DURATION, default=15s"`
	ReconcileSourceTimeout time.Duration `env:"SAVED_USER_RECONCILE_SOURCE_TIMEOUT, default=3s"`
	ReconcileInterval      time.Duration `env:"SAVED_USER_RECONCILE_INTERVAL, default=1m"`
	ReconcileFailureBase   time.Duration `env:"SAVED_USER_RECONCILE_FAILURE_BASE, default=5s"`
	ReconcileFailureMax    time.Duration `env:"SAVED_USER_RECONCILE_FAILURE_MAX, default=5m"`
}

func (c SavedLifecycleConfig) NATSConfig(environment string) (natstransport.Config, error) {
	return c.NATS.Build(environment, "nats://nats:4222")
}

func (c SavedLifecycleConfig) Validate(environment string) error {
	if !c.Enabled {
		return nil
	}
	if _, err := c.NATSConfig(environment); err != nil {
		return fmt.Errorf("invalid Saved lifecycle NATS transport: %w", err)
	}
	if !strings.HasPrefix(strings.TrimSpace(c.Subject), "saved.source.") ||
		c.BatchSize < 1 || c.BatchSize > 200 || c.Concurrency < 1 || c.Concurrency > 32 ||
		c.PollInterval < 50*time.Millisecond || c.PublishTimeout <= 0 ||
		c.LeaseDuration <= c.PublishTimeout || c.DeliveredRetention <= 0 ||
		c.DeadRetention <= 0 || c.CleanupInterval <= 0 ||
		c.ReconcileBatchSize < 1 || c.ReconcileBatchSize > 200 ||
		c.ReconcileConcurrency < 1 || c.ReconcileConcurrency > 16 ||
		c.ReconcilePollInterval < 50*time.Millisecond || c.ReconcileSourceTimeout <= 0 ||
		c.ReconcileLeaseDuration <= c.ReconcileSourceTimeout || c.ReconcileInterval <= 0 ||
		c.ReconcileFailureBase <= 0 || c.ReconcileFailureMax < c.ReconcileFailureBase {
		return fmt.Errorf("invalid Saved lifecycle configuration")
	}
	return nil
}

func (c TokenServiceConfig) Enabled() bool {
	return strings.TrimSpace(c.Target) != "" &&
		strings.TrimSpace(c.ServiceID) != "" &&
		strings.TrimSpace(c.ServiceSecret) != ""
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	if err := cfg.SavedLifecycle.Validate(cfg.App.Env); err != nil {
		return nil, err
	}
	return &cfg, nil
}
