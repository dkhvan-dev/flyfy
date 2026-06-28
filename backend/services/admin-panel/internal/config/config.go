package config

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	App          AppConfig
	HTTP         HTTPConfig
	DB           DBConfig
	Log          LogConfig
	Security     SecurityConfig
	Excursion    ExcursionServiceConfig
	Activity     ActivityServiceConfig
	Guide        GuideServiceConfig
	Chat         ChatServiceConfig
	Support      SupportServiceConfig
	FeedService  FeedServiceConfig
	UserRoute    UserRouteServiceConfig
	User         UserServiceConfig
	Trust        TrustServiceConfig
	AntiFraud    AntiFraudServiceConfig
	Notification NotificationServiceConfig
	Place        PlaceServiceConfig
	FileManager  FileManagerServiceConfig
	FeatureFlag  FeatureFlagServiceConfig
	TechBreak    TechBreakServiceConfig
	Switches     SwitchesServiceConfig
	Bootstrap    BootstrapConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=admin-panel"`
	Env  string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(a.Env, "production")
}

type HTTPConfig struct {
	Port         int           `env:"HTTP_PORT, default=8095"`
	ReadTimeout  time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout time.Duration `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout  time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

type DBConfig struct {
	Host            string `env:"DB_HOST, default=localhost"`
	Port            int    `env:"DB_PORT, default=5445"`
	Name            string `env:"DB_NAME, default=admin_panel_db"`
	User            string `env:"DB_USER, default=admin_panel"`
	Password        string `env:"DB_PASSWORD, default=admin_panel_secret_dev"`
	SSLMode         string `env:"DB_SSLMODE, default=disable"`
	MaxConns        int32  `env:"DB_MAX_CONNS, default=10"`
	MinConns        int32  `env:"DB_MIN_CONNS, default=2"`
	MaxConnIdleTime string `env:"DB_MAX_CONN_IDLE, default=15m"`
	MaxConnLifetime string `env:"DB_MAX_CONN_LIFETIME, default=1h"`
}

func (d DBConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		d.User,
		d.Password,
		d.Host,
		d.Port,
		d.Name,
		d.SSLMode,
	)
}

func (d DBConfig) ParsedMaxConnLifetime() time.Duration {
	value, err := time.ParseDuration(d.MaxConnLifetime)
	if err != nil {
		return time.Hour
	}
	return value
}

func (d DBConfig) ParsedMaxConnIdleTime() time.Duration {
	value, err := time.ParseDuration(d.MaxConnIdleTime)
	if err != nil {
		return 30 * time.Minute
	}
	return value
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type SecurityConfig struct {
	SessionCookieName         string        `env:"SESSION_COOKIE_NAME, default=inflap_admin_session"`
	CSRFCookieName            string        `env:"CSRF_COOKIE_NAME, default=inflap_admin_csrf"`
	CookieSecure              bool          `env:"COOKIE_SECURE, default=false"`
	SessionIdleTimeout        time.Duration `env:"SESSION_IDLE_TIMEOUT, default=30m"`
	SessionAbsoluteTimeout    time.Duration `env:"SESSION_ABSOLUTE_TIMEOUT, default=12h"`
	BootstrapTokenTTL         time.Duration `env:"BOOTSTRAP_TOKEN_TTL, default=24h"`
	LoginRateLimitWindow      time.Duration `env:"LOGIN_RATE_LIMIT_WINDOW, default=15m"`
	LoginRateLimitMaxFailures int           `env:"LOGIN_RATE_LIMIT_MAX_FAILURES, default=8"`
	RequestIDHeader           string        `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
	TrustedAdminHeaderUserID  string        `env:"ADMIN_TRUSTED_HEADER_USER_ID, default=X-User-Id"`
	TrustedAdminHeaderRoles   string        `env:"ADMIN_TRUSTED_HEADER_ROLES, default=X-User-Roles"`
	TrustedInternalToken      string        `env:"INTERNAL_SERVICE_TOKEN"`
}

type ExcursionServiceConfig struct {
	BaseURL string        `env:"EXCURSION_SERVICE_URL, default=http://excursion-service:8093"`
	Timeout time.Duration `env:"EXCURSION_SERVICE_TIMEOUT, default=5s"`
}

type ActivityServiceConfig struct {
	BaseURL string        `env:"ACTIVITY_SERVICE_URL, default=http://activity-service:8086"`
	Timeout time.Duration `env:"ACTIVITY_SERVICE_TIMEOUT, default=5s"`
}

type GuideServiceConfig struct {
	BaseURL string        `env:"GUIDE_SERVICE_URL, default=http://guide-service:8085"`
	Timeout time.Duration `env:"GUIDE_SERVICE_TIMEOUT, default=5s"`
}

type ChatServiceConfig struct {
	BaseURL string        `env:"CHAT_SERVICE_URL, default=http://chat-service:8088"`
	Timeout time.Duration `env:"CHAT_SERVICE_TIMEOUT, default=5s"`
}

type SupportServiceConfig struct {
	BaseURL string        `env:"SUPPORT_SERVICE_URL, default=http://support-service:8100"`
	Timeout time.Duration `env:"SUPPORT_SERVICE_TIMEOUT, default=5s"`
}

type FeedServiceConfig struct {
	BaseURL string        `env:"FEED_SERVICE_URL, default=http://feed-service:8087"`
	Timeout time.Duration `env:"FEED_SERVICE_TIMEOUT, default=5s"`
}

type UserRouteServiceConfig struct {
	BaseURL string        `env:"USER_ROUTE_SERVICE_HTTP_URL, default=http://user-route-service:8096"`
	Timeout time.Duration `env:"USER_ROUTE_SERVICE_REQUEST_TIMEOUT, default=3s"`
}

type UserServiceConfig struct {
	Target  string        `env:"USER_SERVICE_GRPC_TARGET, default=user-service:9094"`
	Timeout time.Duration `env:"USER_SERVICE_TIMEOUT, default=3s"`
}

type TrustServiceConfig struct {
	Target             string        `env:"TRUST_SERVICE_GRPC_TARGET, default=trust-service:9096"`
	Timeout            time.Duration `env:"TRUST_SERVICE_TIMEOUT, default=3s"`
	OutboxPollInterval time.Duration `env:"TRUST_OUTBOX_POLL_INTERVAL, default=5s"`
	OutboxBatchSize    int           `env:"TRUST_OUTBOX_BATCH_SIZE, default=50"`
	OutboxMaxAttempts  int           `env:"TRUST_OUTBOX_MAX_ATTEMPTS, default=20"`
	OutboxBaseBackoff  time.Duration `env:"TRUST_OUTBOX_BASE_BACKOFF, default=1s"`
}

type AntiFraudServiceConfig struct {
	BaseURL string        `env:"ANTI_FRAUD_SERVICE_URL, default=http://anti-fraud-service:8096"`
	Timeout time.Duration `env:"ANTI_FRAUD_SERVICE_TIMEOUT, default=5s"`
}

type NotificationServiceConfig struct {
	HTTPURL        string        `env:"NOTIFICATION_SERVICE_HTTP_URL, default=http://notification-service:8097"`
	RequestTimeout time.Duration `env:"NOTIFICATION_SERVICE_REQUEST_TIMEOUT, default=3s"`
}

type PlaceServiceConfig struct {
	BaseURL string        `env:"PLACE_SERVICE_URL, default=http://place-service:8090"`
	Timeout time.Duration `env:"PLACE_SERVICE_TIMEOUT, default=5s"`
}

type FileManagerServiceConfig struct {
	BaseURL            string        `env:"FILE_MANAGER_SERVICE_URL, default=http://file-manager-service:8083"`
	Timeout            time.Duration `env:"FILE_MANAGER_SERVICE_TIMEOUT, default=15s"`
	MaxPlaceImageBytes int64         `env:"MAX_PLACE_IMAGE_BYTES, default=20971520"`
}

type FeatureFlagServiceConfig struct {
	BaseURL string        `env:"FEATURE_FLAG_SERVICE_URL, default=http://switches-service:8096"`
	Timeout time.Duration `env:"FEATURE_FLAG_SERVICE_TIMEOUT, default=5s"`
}

type TechBreakServiceConfig struct {
	BaseURL string        `env:"TECH_BREAK_SERVICE_URL, default=http://switches-service:8096"`
	Timeout time.Duration `env:"TECH_BREAK_SERVICE_TIMEOUT, default=5s"`
}

type SwitchesServiceConfig struct {
	HTTPURL              string        `env:"SWITCHES_SERVICE_URL, default=http://switches-service:8096"`
	InternalServiceToken string        `env:"SWITCHES_INTERNAL_SERVICE_TOKEN"`
	RequestTimeout       time.Duration `env:"SWITCHES_SERVICE_TIMEOUT, default=800ms"`
}

type BootstrapConfig struct {
	SuperAdminEmail       string `env:"BOOTSTRAP_SUPERADMIN_EMAIL"`
	SuperAdminDisplayName string `env:"BOOTSTRAP_SUPERADMIN_DISPLAY_NAME, default=Super Admin"`
	SuperAdminPassword    string `env:"BOOTSTRAP_SUPERADMIN_PASSWORD"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	return &cfg, nil
}
