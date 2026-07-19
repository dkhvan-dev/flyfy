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
	Redis          RedisConfig
	Security       SecurityConfig
	UserService    UserServiceConfig
	FileManager    FileManagerConfig
	Admin          AdminConfig
	MediaBackfill  MediaBackfillConfig
	Switches       SwitchesServiceConfig
	TokenService   TokenServiceConfig
	SearchService  SearchServiceConfig
	SavedLifecycle SavedLifecycleConfig
	MTLS           transportauth.EnvConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=place-service"`
	Env  string `env:"APP_ENV, default=development"`
}

func (c AppConfig) IsProduction() bool {
	return strings.EqualFold(strings.TrimSpace(c.Env), "production")
}

type HTTPConfig struct {
	Port            int    `env:"HTTP_PORT, default=8090"`
	InternalTLSPort int    `env:"INTERNAL_HTTP_TLS_PORT, default=0"`
	ReadTimeout     string `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout    string `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout     string `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (c HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", c.Port)
}

func (c HTTPConfig) InternalTLSAddress() string {
	return fmt.Sprintf(":%d", c.InternalTLSPort)
}

type GRPCConfig struct {
	Port int `env:"GRPC_PORT, default=9099"`
}

func (c GRPCConfig) Address() string {
	return fmt.Sprintf(":%d", c.Port)
}

type PostgresConfig struct {
	Host     string `env:"POSTGRES_HOST, default=localhost"`
	Port     int    `env:"POSTGRES_PORT, default=5441"`
	User     string `env:"POSTGRES_USER, default=place_service"`
	Password string `env:"POSTGRES_PASSWORD, default=place_secret_dev"`
	DB       string `env:"POSTGRES_DB, default=place_service_db"`
	SSLMode  string `env:"POSTGRES_SSLMODE, default=disable"`
	MaxConns int32  `env:"POSTGRES_MAX_CONNS, default=10"`
	MinConns int32  `env:"POSTGRES_MIN_CONNS, default=2"`
}

func (c PostgresConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		c.User, c.Password, c.Host, c.Port, c.DB, c.SSLMode,
	)
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type RedisConfig struct {
	Enabled   bool          `env:"PLACE_CACHE_ENABLED, default=true"`
	Addr      string        `env:"REDIS_ADDR"`
	Password  string        `env:"REDIS_PASSWORD"`
	DB        int           `env:"REDIS_CACHE_DB, default=4"`
	KeyPrefix string        `env:"PLACE_CACHE_KEY_PREFIX, default=place-service:cache:"`
	DetailTTL time.Duration `env:"PLACE_DETAIL_CACHE_TTL, default=15m"`
	ListTTL   time.Duration `env:"PLACE_LIST_CACHE_TTL, default=5m"`
}

type SecurityConfig struct {
	InternalServiceToken       string        `env:"INTERNAL_SERVICE_TOKEN, required"`
	RequireAuthenticatedWrites bool          `env:"REQUIRE_AUTHENTICATED_WRITES, default=true"`
	TrustedHeaderUserID        string        `env:"TRUSTED_GATEWAY_HEADER_USER_ID, default=X-User-Id"`
	TrustedHeaderRoles         string        `env:"TRUSTED_GATEWAY_HEADER_ROLES, default=X-User-Roles"`
	TrustedHeaderSubject       string        `env:"TRUSTED_GATEWAY_HEADER_SUB, default=X-Auth-Subject"`
	RequestIDHeader            string        `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
	ServiceAuthIssuer          string        `env:"SERVICE_AUTH_ISSUER, default=tourism-inflap/token-service"`
	ServiceAuthJWKSURL         string        `env:"SERVICE_AUTH_JWKS_URL, default=http://token-service:8081/.well-known/jwks.json"`
	ServiceAuthCacheTTL        time.Duration `env:"SERVICE_AUTH_JWKS_CACHE_TTL, default=5m"`
}

func (c SecurityConfig) ServiceAuthEnabled() bool {
	return strings.TrimSpace(c.ServiceAuthIssuer) != "" &&
		strings.TrimSpace(c.ServiceAuthJWKSURL) != ""
}

type UserServiceConfig struct {
	GRPCTarget string `env:"USER_SERVICE_GRPC_TARGET, default=dns:///user-service:9094"`
}

type FileManagerConfig struct {
	GRPCTarget     string        `env:"FILE_MANAGER_GRPC_TARGET, default=dns:///file-manager-service:9093"`
	RequestTimeout time.Duration `env:"SAVED_COVER_FILE_MANAGER_TIMEOUT, default=3s"`
}

func (c FileManagerConfig) Validate() error {
	switch {
	case strings.TrimSpace(c.GRPCTarget) == "":
		return fmt.Errorf("FILE_MANAGER_GRPC_TARGET is required")
	case c.RequestTimeout < 100*time.Millisecond || c.RequestTimeout > 10*time.Second:
		return fmt.Errorf("SAVED_COVER_FILE_MANAGER_TIMEOUT must be in [100ms,10s]")
	default:
		return nil
	}
}

type MediaBackfillConfig struct {
	FileManagerURL          string        `env:"PLACE_MEDIA_BACKFILL_FILE_MANAGER_URL, default=http://file-manager-service:8083"`
	HTTPTimeout             time.Duration `env:"PLACE_MEDIA_BACKFILL_HTTP_TIMEOUT, default=30s"`
	RowDelay                time.Duration `env:"PLACE_MEDIA_BACKFILL_ROW_DELAY, default=250ms"`
	RunTimeout              time.Duration `env:"PLACE_MEDIA_BACKFILL_RUN_TIMEOUT, default=30m"`
	CommonsMinMediaPerPlace int           `env:"PLACE_MEDIA_BACKFILL_COMMONS_MIN_MEDIA_PER_PLACE, default=0"`
}

type SwitchesServiceConfig struct {
	HTTPURL              string        `env:"SWITCHES_SERVICE_URL, default=http://switches-service:8096"`
	InternalServiceToken string        `env:"SWITCHES_INTERNAL_SERVICE_TOKEN"`
	RequestTimeout       time.Duration `env:"SWITCHES_SERVICE_TIMEOUT, default=800ms"`
}

type SearchServiceConfig struct {
	Enabled bool          `env:"SEARCH_INDEXING_ENABLED, default=false"`
	HTTPURL string        `env:"SEARCH_SERVICE_HTTP_URL, default=http://search-service:8101"`
	Timeout time.Duration `env:"SEARCH_SERVICE_TIMEOUT, default=800ms"`
}

type TokenServiceConfig struct {
	Target        string        `env:"TOKEN_SERVICE_GRPC_TARGET, default=dns:///token-service:50051"`
	ServiceID     string        `env:"TOKEN_SERVICE_ID, default=place-service"`
	ServiceSecret string        `env:"TOKEN_SERVICE_SECRET"`
	CallTimeout   time.Duration `env:"TOKEN_SERVICE_CALL_TIMEOUT, default=3s"`
}

type SavedLifecycleConfig struct {
	Enabled         bool `env:"SAVED_LIFECYCLE_EVENTS_ENABLED, default=false"`
	NATS            natstransport.EnvConfig
	BatchSize       int           `env:"SAVED_LIFECYCLE_BATCH_SIZE, default=50"`
	Concurrency     int           `env:"SAVED_LIFECYCLE_CONCURRENCY, default=8"`
	PollInterval    time.Duration `env:"SAVED_LIFECYCLE_POLL_INTERVAL, default=500ms"`
	LeaseDuration   time.Duration `env:"SAVED_LIFECYCLE_LEASE_DURATION, default=2m"`
	PublishTimeout  time.Duration `env:"SAVED_LIFECYCLE_PUBLISH_TIMEOUT, default=3s"`
	MaxAttempts     int           `env:"SAVED_LIFECYCLE_MAX_ATTEMPTS, default=20"`
	RetryBase       time.Duration `env:"SAVED_LIFECYCLE_RETRY_BASE, default=1s"`
	RetryMax        time.Duration `env:"SAVED_LIFECYCLE_RETRY_MAX, default=5m"`
	CleanupInterval time.Duration `env:"SAVED_LIFECYCLE_CLEANUP_INTERVAL, default=1h"`
	CleanupBatch    int           `env:"SAVED_LIFECYCLE_CLEANUP_BATCH, default=500"`
}

func (c SavedLifecycleConfig) NATSConfig(environment string) (natstransport.Config, error) {
	return c.NATS.Build(environment, "nats://localhost:4222")
}

func (c SavedLifecycleConfig) Validate(environment string) error {
	if strings.EqualFold(strings.TrimSpace(environment), "production") && !c.Enabled {
		return fmt.Errorf("SAVED_LIFECYCLE_EVENTS_ENABLED must be true in production")
	}
	if !c.Enabled {
		return nil
	}
	if _, err := c.NATSConfig(environment); err != nil {
		return fmt.Errorf("invalid Saved lifecycle NATS transport: %w", err)
	}
	switch {
	case c.BatchSize <= 0 || c.BatchSize > 500:
		return fmt.Errorf("SAVED_LIFECYCLE_BATCH_SIZE must be in [1,500]")
	case c.Concurrency <= 0 || c.Concurrency > c.BatchSize:
		return fmt.Errorf("SAVED_LIFECYCLE_CONCURRENCY must be in [1,batch size]")
	case c.PollInterval <= 0 || c.PollInterval > time.Minute ||
		c.PublishTimeout <= 0 || c.PublishTimeout > 30*time.Second:
		return fmt.Errorf("Saved lifecycle poll or publish duration is outside bounded limits")
	case c.LeaseDuration < minimumSavedLifecycleLease(c) || c.LeaseDuration > time.Hour:
		return fmt.Errorf("SAVED_LIFECYCLE_LEASE_DURATION does not cover a bounded batch")
	case c.MaxAttempts <= 0 || c.MaxAttempts > 100:
		return fmt.Errorf("SAVED_LIFECYCLE_MAX_ATTEMPTS must be in [1,100]")
	case c.RetryBase <= 0 || c.RetryMax < c.RetryBase || c.RetryMax > 24*time.Hour:
		return fmt.Errorf("Saved lifecycle retry bounds are invalid")
	case c.CleanupInterval <= 0 || c.CleanupInterval > 24*time.Hour ||
		c.CleanupBatch <= 0 || c.CleanupBatch > 5000:
		return fmt.Errorf("Saved lifecycle cleanup configuration is invalid")
	default:
		return nil
	}
}

func minimumSavedLifecycleLease(c SavedLifecycleConfig) time.Duration {
	waves := (c.BatchSize + c.Concurrency - 1) / c.Concurrency
	return 2 * time.Duration(waves) * c.PublishTimeout
}

func (c TokenServiceConfig) Enabled() bool {
	return strings.TrimSpace(c.Target) != "" &&
		strings.TrimSpace(c.ServiceID) != "" &&
		strings.TrimSpace(c.ServiceSecret) != ""
}

type AdminConfig struct {
	PlaceAuthorUserID string `env:"ADMIN_PLACE_AUTHOR_USER_ID, default=00000000-0000-4000-8000-000000000001"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("load config: %w", err)
	}
	if err := cfg.SavedLifecycle.Validate(cfg.App.Env); err != nil {
		return nil, fmt.Errorf("validate Saved lifecycle config: %w", err)
	}
	if err := cfg.FileManager.Validate(); err != nil {
		return nil, fmt.Errorf("validate Saved cover file-manager config: %w", err)
	}
	return &cfg, nil
}
