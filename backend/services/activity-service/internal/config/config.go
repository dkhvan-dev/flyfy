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
	DB             DBConfig
	Log            LogConfig
	Security       SecurityConfig
	Attendance     AttendanceConfig
	UserService    UserServiceConfig
	FileManager    FileManagerConfig
	ChatService    ChatServiceConfig
	Notification   NotificationServiceConfig
	Payment        PaymentServiceConfig
	Switches       SwitchesServiceConfig
	AntiFraud      AntiFraudConfig
	Trust          TrustServiceConfig
	TokenService   TokenServiceConfig
	SearchService  SearchServiceConfig
	Translation    TranslationServiceConfig
	SavedLifecycle SavedLifecycleConfig
	MTLS           transportauth.EnvConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=activity-service"`
	Env  string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(a.Env, "production")
}

type HTTPConfig struct {
	Port            int           `env:"HTTP_PORT, default=8080"`
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
	Port            int `env:"GRPC_PORT, default=9090"`
	InternalTLSPort int `env:"INTERNAL_GRPC_TLS_PORT, default=0"`
}

func (g GRPCConfig) Address() string {
	return fmt.Sprintf(":%d", g.Port)
}

func (g GRPCConfig) InternalTLSAddress() string {
	return fmt.Sprintf(":%d", g.InternalTLSPort)
}

type DBConfig struct {
	Host            string `env:"DB_HOST, default=localhost"`
	Port            int    `env:"DB_PORT, default=5432"`
	Name            string `env:"DB_NAME, default=activity_service"`
	User            string `env:"DB_USER, default=postgres"`
	Password        string `env:"DB_PASSWORD, default=postgres"`
	SSLMode         string `env:"DB_SSLMODE, default=disable"`
	MaxConns        int32  `env:"DB_MAX_CONNS, default=10"`
	MinConns        int32  `env:"DB_MIN_CONNS, default=2"`
	MaxConnIdleTime string `env:"DB_MAX_CONN_IDLE, default=15m"`
	MaxConnLifetime string `env:"DB_MAX_CONN_LIFETIME, default=1h"`
}

func (p DBConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		p.User,
		p.Password,
		p.Host,
		p.Port,
		p.Name,
		p.SSLMode,
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
		return 30 * time.Minute
	}
	return d
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type UserServiceConfig struct {
	GRPCAddress string `env:"USER_SERVICE_GRPC_ADDR, default=user-service:9092"`
}

type FileManagerConfig struct {
	Target string `env:"FILE_MANAGER_GRPC_TARGET, default=dns:///file-manager-service:9093"`
}

type ChatServiceConfig struct {
	HTTPURL        string        `env:"CHAT_SERVICE_HTTP_URL, default=http://chat-service:8088"`
	RequestTimeout time.Duration `env:"CHAT_SERVICE_REQUEST_TIMEOUT, default=5s"`
}

type NotificationServiceConfig struct {
	HTTPURL        string        `env:"NOTIFICATION_SERVICE_HTTP_URL, default=http://notification-service:8097"`
	RequestTimeout time.Duration `env:"NOTIFICATION_SERVICE_REQUEST_TIMEOUT, default=3s"`
}

type PaymentServiceConfig struct {
	HTTPURL        string        `env:"PAYMENT_SERVICE_HTTP_URL, default=http://payment-service:8091"`
	RequestTimeout time.Duration `env:"PAYMENT_SERVICE_REQUEST_TIMEOUT, default=5s"`
}

type SwitchesServiceConfig struct {
	HTTPURL              string        `env:"SWITCHES_SERVICE_URL, default=http://switches-service:8096"`
	InternalServiceToken string        `env:"SWITCHES_INTERNAL_SERVICE_TOKEN"`
	RequestTimeout       time.Duration `env:"SWITCHES_SERVICE_TIMEOUT, default=800ms"`
}

func (c SwitchesServiceConfig) Enabled() bool {
	return c.HTTPURL != "" && c.InternalServiceToken != ""
}

type AntiFraudConfig struct {
	Enabled              bool          `env:"ANTI_FRAUD_ENABLED, default=false"`
	BaseURL              string        `env:"ANTI_FRAUD_BASE_URL, default=http://anti-fraud-service:8096"`
	InternalServiceToken string        `env:"ANTI_FRAUD_INTERNAL_SERVICE_TOKEN"`
	SignalHashKey        string        `env:"ANTI_FRAUD_SIGNAL_HASH_KEY"`
	Timeout              time.Duration `env:"ANTI_FRAUD_TIMEOUT, default=800ms"`
}

type TrustServiceConfig struct {
	Enabled bool          `env:"TRUST_POLICY_ENABLED, default=true"`
	Target  string        `env:"TRUST_SERVICE_GRPC_TARGET, default=trust-service:9096"`
	Timeout time.Duration `env:"TRUST_SERVICE_TIMEOUT, default=250ms"`
}

type SearchServiceConfig struct {
	Enabled bool          `env:"SEARCH_INDEXING_ENABLED, default=false"`
	HTTPURL string        `env:"SEARCH_SERVICE_HTTP_URL, default=http://search-service:8101"`
	Timeout time.Duration `env:"SEARCH_SERVICE_TIMEOUT, default=800ms"`
}

type TranslationServiceConfig struct {
	BaseURL           string        `env:"TRANSLATION_SERVICE_URL"`
	AsyncEnabled      bool          `env:"ACTIVITY_ASYNC_TRANSLATION_ENABLED, default=true"`
	WorkerEnabled     bool          `env:"ACTIVITY_TRANSLATION_WORKER_ENABLED, default=false"`
	WorkerBatchSize   int           `env:"ACTIVITY_TRANSLATION_WORKER_BATCH_SIZE, default=10"`
	WorkerInterval    time.Duration `env:"ACTIVITY_TRANSLATION_WORKER_INTERVAL, default=2s"`
	MaxAttempts       int           `env:"ACTIVITY_TRANSLATION_MAX_ATTEMPTS, default=5"`
	RetryBaseDelay    time.Duration `env:"ACTIVITY_TRANSLATION_RETRY_BASE_DELAY, default=30s"`
	RequestTimeout    time.Duration `env:"ACTIVITY_TRANSLATION_REQUEST_TIMEOUT, default=8s"`
	WorkerLockTimeout time.Duration `env:"ACTIVITY_TRANSLATION_LOCK_TIMEOUT, default=2m"`
}

type SavedLifecycleConfig struct {
	Enabled          bool `env:"ACTIVITY_SAVED_LIFECYCLE_ENABLED, default=true"`
	NATS             natstransport.EnvConfig
	WorkerBatchSize  int           `env:"ACTIVITY_SAVED_LIFECYCLE_BATCH_SIZE, default=50"`
	PollInterval     time.Duration `env:"ACTIVITY_SAVED_LIFECYCLE_POLL_INTERVAL, default=1s"`
	LeaseDuration    time.Duration `env:"ACTIVITY_SAVED_LIFECYCLE_LEASE_DURATION, default=2m"`
	PublishTimeout   time.Duration `env:"ACTIVITY_SAVED_LIFECYCLE_PUBLISH_TIMEOUT, default=2s"`
	RetryBaseDelay   time.Duration `env:"ACTIVITY_SAVED_LIFECYCLE_RETRY_BASE_DELAY, default=1s"`
	RetryMaxDelay    time.Duration `env:"ACTIVITY_SAVED_LIFECYCLE_RETRY_MAX_DELAY, default=5m"`
	CleanupInterval  time.Duration `env:"ACTIVITY_SAVED_LIFECYCLE_CLEANUP_INTERVAL, default=1m"`
	CleanupBatchSize int           `env:"ACTIVITY_SAVED_LIFECYCLE_CLEANUP_BATCH_SIZE, default=200"`
}

func (c SavedLifecycleConfig) NATSConfig(environment string) (natstransport.Config, error) {
	return c.NATS.Build(environment, "nats://localhost:4222")
}

type TokenServiceConfig struct {
	Target        string        `env:"TOKEN_SERVICE_GRPC_TARGET, default=dns:///token-service:50051"`
	ServiceID     string        `env:"TOKEN_SERVICE_ID, default=activity-service"`
	ServiceSecret string        `env:"TOKEN_SERVICE_SECRET"`
	CallTimeout   time.Duration `env:"TOKEN_SERVICE_CALL_TIMEOUT, default=3s"`
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
	if cfg.SavedLifecycle.Enabled {
		if _, err := cfg.SavedLifecycle.NATSConfig(cfg.App.Env); err != nil {
			return nil, fmt.Errorf("validate activity Saved lifecycle NATS transport: %w", err)
		}
		if cfg.SavedLifecycle.WorkerBatchSize <= 0 || cfg.SavedLifecycle.WorkerBatchSize > 100 ||
			cfg.SavedLifecycle.PollInterval <= 0 ||
			cfg.SavedLifecycle.LeaseDuration <= 0 || cfg.SavedLifecycle.LeaseDuration > 10*time.Minute ||
			cfg.SavedLifecycle.PublishTimeout <= 0 ||
			cfg.SavedLifecycle.RetryBaseDelay <= 0 ||
			cfg.SavedLifecycle.RetryMaxDelay < cfg.SavedLifecycle.RetryBaseDelay ||
			cfg.SavedLifecycle.CleanupInterval <= 0 ||
			cfg.SavedLifecycle.CleanupBatchSize <= 0 || cfg.SavedLifecycle.CleanupBatchSize > 1000 ||
			!savedLifecycleLeaseCoversBatch(cfg.SavedLifecycle) {
			return nil, fmt.Errorf("invalid activity Saved lifecycle worker configuration")
		}
	}
	return &cfg, nil
}

func savedLifecycleLeaseCoversBatch(cfg SavedLifecycleConfig) bool {
	if cfg.WorkerBatchSize <= 0 || cfg.LeaseDuration <= 0 || cfg.PublishTimeout <= 0 {
		return false
	}
	safetyMargin := min(10*time.Second, cfg.LeaseDuration/5)
	processingBudget := cfg.LeaseDuration - safetyMargin
	if processingBudget <= 0 {
		return false
	}
	return cfg.PublishTimeout <= processingBudget/time.Duration(cfg.WorkerBatchSize)
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
}

func (s SecurityConfig) ServiceAuthEnabled() bool {
	return strings.TrimSpace(s.ServiceAuthIssuer) != "" &&
		strings.TrimSpace(s.ServiceAuthJWKSURL) != ""
}

type AttendanceConfig struct {
	QRSigningSecret string        `env:"ATTENDANCE_QR_SIGNING_SECRET, default=dev-attendance-qr-secret"`
	QRTTL           time.Duration `env:"ATTENDANCE_QR_TTL, default=45s"`
	OfflineWindow   time.Duration `env:"ATTENDANCE_QR_OFFLINE_WINDOW, default=6h"`
}
