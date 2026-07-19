package config

import (
	"context"
	"fmt"
	"net/url"
	"strings"
	"time"

	"github.com/sethvargo/go-envconfig"

	"kz/inflap/backend/pkg/platformpolicy"
	"kz/inflap/backend/pkg/transportauth"
)

type Config struct {
	App            AppConfig
	HTTP           HTTPConfig
	Log            LogConfig
	Security       SecurityConfig
	Routes         RoutesConfig
	Downstreams    DownstreamsConfig
	SavedService   SavedServiceConfig
	PlatformPolicy PlatformPolicyConfig
	TokenService   TokenServiceConfig
	TrustService   TrustServiceConfig
	CORS           CORSConfig
	RateLimit      RateLimitConfig
	Redis          RedisConfig
	MTLS           transportauth.EnvConfig
}

type AppConfig struct {
	Env string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(strings.TrimSpace(a.Env), "production")
}

func (a AppConfig) AllowsInsecureLocalTransport() bool {
	switch strings.ToLower(strings.TrimSpace(a.Env)) {
	case "dev", "development", "local", "test":
		return true
	default:
		return false
	}
}

type HTTPConfig struct {
	Port         int           `env:"HTTP_PORT, default=8080"`
	ReadTimeout  time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout time.Duration `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout  time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type SecurityConfig struct {
	InternalServiceToken string `env:"INTERNAL_SERVICE_TOKEN"`
	RequestIDHeader      string `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
	TrustedHeaderUser    string `env:"TRUSTED_HEADER_USER_ID, default=X-User-Id"`
	TrustedHeaderRoles   string `env:"TRUSTED_HEADER_ROLES, default=X-User-Roles"`
	TrustedHeaderSub     string `env:"TRUSTED_HEADER_SUB, default=X-Auth-Subject"`
}

type RoutesConfig struct {
	APIPrefix string `env:"API_PREFIX, default=/api/v1"`
}

type DownstreamsConfig struct {
	AuthService         string `env:"AUTH_SERVICE_HTTP_URL, default=http://auth-service:8081"`
	UserService         string `env:"USER_SERVICE_HTTP_URL, default=http://user-service:8084"`
	GuideService        string `env:"GUIDE_SERVICE_HTTP_URL, default=http://guide-service:8085"`
	FileManagerService  string `env:"FILE_MANAGER_HTTP_URL, default=http://file-manager-service:8083"`
	ActivityService     string `env:"ACTIVITY_SERVICE_HTTP_URL, default=http://activity-service:8086"`
	ExcursionService    string `env:"EXCURSION_SERVICE_HTTP_URL, default=http://excursion-service:8093"`
	FeedService         string `env:"FEED_SERVICE_HTTP_URL, default=http://feed-service:8087"`
	ChatService         string `env:"CHAT_SERVICE_HTTP_URL, default=http://chat-service:8088"`
	ReferenceService    string `env:"REFERENCE_SERVICE_HTTP_URL, default=http://reference-service:8089"`
	ChecklistService    string `env:"CHECKLIST_SERVICE_HTTP_URL, default=http://checklist-service:8099"`
	CurrencyService     string `env:"CURRENCY_SERVICE_HTTP_URL, default=http://currency-service:8098"`
	PlaceService        string `env:"PLACE_SERVICE_HTTP_URL, default=http://place-service:8090"`
	RoutingService      string `env:"ROUTING_SERVICE_HTTP_URL, default=http://routing-service:8094"`
	UserRouteService    string `env:"USER_ROUTE_SERVICE_HTTP_URL, default=http://user-route-service:8096"`
	SearchService       string `env:"SEARCH_SERVICE_HTTP_URL, default=http://search-service:8101"`
	PaymentService      string `env:"PAYMENT_SERVICE_HTTP_URL, default=http://payment-service:8091"`
	StickerService      string `env:"STICKER_SERVICE_HTTP_URL, default=http://sticker-service:8092"`
	NotificationService string `env:"NOTIFICATION_SERVICE_HTTP_URL, default=http://notification-service:8097"`
	SupportService      string `env:"SUPPORT_SERVICE_HTTP_URL, default=http://support-service:8100"`
	AdminPanelService   string `env:"ADMIN_PANEL_SERVICE_HTTP_URL, default=http://admin-panel:8095"`
}

const (
	defaultSavedServiceRequestTimeout = 10 * time.Second
	maxSavedServiceRequestTimeout     = 30 * time.Second
)

type SavedServiceConfig struct {
	URL            string        `env:"SAVED_SERVICE_URL, default=http://saved-service:8102"`
	RequestTimeout time.Duration `env:"SAVED_SERVICE_REQUEST_TIMEOUT, default=10s"`
}

type PlatformPolicyConfig struct {
	BaseURL              string        `env:"PLATFORM_POLICY_BASE_URL, default=http://switches-service:8096"`
	InternalServiceToken string        `env:"PLATFORM_POLICY_INTERNAL_SERVICE_TOKEN, required"`
	HTTPTimeout          time.Duration `env:"PLATFORM_POLICY_HTTP_TIMEOUT, default=750ms"`
	RefreshTimeout       time.Duration `env:"PLATFORM_POLICY_REFRESH_TIMEOUT, default=1s"`
	MaxResponseBytes     int64         `env:"PLATFORM_POLICY_MAX_RESPONSE_BYTES, default=4096"`
	AllowInsecureHTTP    bool          `env:"PLATFORM_POLICY_ALLOW_INSECURE_HTTP, default=false"`
}

func (s SavedServiceConfig) EffectiveRequestTimeout() time.Duration {
	if s.RequestTimeout <= 0 {
		return defaultSavedServiceRequestTimeout
	}
	if s.RequestTimeout > maxSavedServiceRequestTimeout {
		return maxSavedServiceRequestTimeout
	}
	return s.RequestTimeout
}

type RedisConfig struct {
	Addr string        `env:"REDIS_ADDR, default=localhost:6379"`
	DB   int           `env:"REDIS_CACHE_DB, default=3"`
	TTL  time.Duration `env:"REDIS_CACHE_TTL, default=1h"`
}

type TokenServiceConfig struct {
	Target        string        `env:"TOKEN_SERVICE_GRPC_TARGET, default=dns:///token-service:50051"`
	ServiceID     string        `env:"TOKEN_SERVICE_ID, required"`
	ServiceSecret string        `env:"TOKEN_SERVICE_SECRET, required"`
	CallTimeout   time.Duration `env:"TOKEN_SERVICE_CALL_TIMEOUT, default=3s"`
}

type TrustServiceConfig struct {
	Target      string        `env:"TRUST_SERVICE_GRPC_TARGET, default=dns:///trust-service:9096"`
	ServiceName string        `env:"TRUST_SERVICE_CALLER_NAME, default=api-gateway"`
	CallTimeout time.Duration `env:"TRUST_SERVICE_CALL_TIMEOUT, default=3s"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	cfg.SavedService.URL = strings.TrimSpace(cfg.SavedService.URL)
	cfg.PlatformPolicy.BaseURL = strings.TrimSpace(cfg.PlatformPolicy.BaseURL)
	cfg.PlatformPolicy.InternalServiceToken = strings.TrimSpace(cfg.PlatformPolicy.InternalServiceToken)
	if err := cfg.Validate(); err != nil {
		return nil, err
	}
	return &cfg, nil
}

func (c *Config) Validate() error {
	if c == nil {
		return fmt.Errorf("config is required")
	}
	if err := validateSavedServiceURL(c.SavedService.URL); err != nil {
		return fmt.Errorf("validate saved-service config: %w", err)
	}
	if c.SavedService.RequestTimeout <= 0 || c.SavedService.RequestTimeout > maxSavedServiceRequestTimeout {
		return fmt.Errorf(
			"validate saved-service config: request timeout must be greater than zero and at most %s",
			maxSavedServiceRequestTimeout,
		)
	}
	if err := validatePlatformPolicyConfig(c.App, c.SavedService, c.PlatformPolicy); err != nil {
		return fmt.Errorf("validate platform policy config: %w", err)
	}
	return nil
}

func validatePlatformPolicyConfig(app AppConfig, saved SavedServiceConfig, policy PlatformPolicyConfig) error {
	parsed, err := validateHTTPOrigin(policy.BaseURL)
	if err != nil {
		return fmt.Errorf("base URL: %w", err)
	}
	if strings.TrimSpace(policy.InternalServiceToken) == "" {
		return fmt.Errorf("internal service token is required")
	}
	if policy.HTTPTimeout <= 0 || policy.HTTPTimeout > platformpolicy.MaximumHTTPTimeout {
		return fmt.Errorf("HTTP timeout must be within (0, %s]", platformpolicy.MaximumHTTPTimeout)
	}
	if policy.RefreshTimeout <= 0 || policy.RefreshTimeout > platformpolicy.MaximumRefreshTimeout {
		return fmt.Errorf("refresh timeout must be within (0, %s]", platformpolicy.MaximumRefreshTimeout)
	}
	if policy.HTTPTimeout >= policy.RefreshTimeout {
		return fmt.Errorf("HTTP timeout must be shorter than refresh timeout")
	}
	if policy.RefreshTimeout >= saved.EffectiveRequestTimeout() {
		return fmt.Errorf("refresh timeout must be shorter than the Saved request timeout")
	}
	if policy.MaxResponseBytes < 1 || policy.MaxResponseBytes > platformpolicy.MaximumResponseBytes {
		return fmt.Errorf("maximum response bytes must be within [1, %d]", platformpolicy.MaximumResponseBytes)
	}

	isPlainHTTP := strings.EqualFold(parsed.Scheme, "http")
	if app.IsProduction() {
		if isPlainHTTP || policy.AllowInsecureHTTP {
			return fmt.Errorf("production policy transport requires HTTPS and forbids insecure HTTP opt-in")
		}
		return nil
	}
	if isPlainHTTP && (!app.AllowsInsecureLocalTransport() || !policy.AllowInsecureHTTP) {
		return fmt.Errorf("plaintext HTTP is limited to dev/test/local with explicit PLATFORM_POLICY_ALLOW_INSECURE_HTTP opt-in")
	}
	return nil
}

func validateSavedServiceURL(rawURL string) error {
	_, err := validateHTTPOrigin(rawURL)
	return err
}

func validateHTTPOrigin(rawURL string) (*url.URL, error) {
	parsed, err := url.ParseRequestURI(strings.TrimSpace(rawURL))
	if err != nil {
		return nil, fmt.Errorf("URL must be an absolute HTTP(S) origin: %w", err)
	}
	if !parsed.IsAbs() || parsed.Host == "" || parsed.Hostname() == "" {
		return nil, fmt.Errorf("URL must be an absolute HTTP(S) origin")
	}
	if !strings.EqualFold(parsed.Scheme, "http") && !strings.EqualFold(parsed.Scheme, "https") {
		return nil, fmt.Errorf("URL scheme must be http or https")
	}
	if parsed.User != nil {
		return nil, fmt.Errorf("URL must not contain user information")
	}
	if parsed.Path != "" && parsed.Path != "/" {
		return nil, fmt.Errorf("URL must not contain a path")
	}
	if parsed.RawQuery != "" || parsed.ForceQuery || parsed.Fragment != "" {
		return nil, fmt.Errorf("URL must not contain a query or fragment")
	}
	return parsed, nil
}

type CORSConfig struct {
	AllowedOrigins   string `env:"CORS_ALLOWED_ORIGINS, default=*"`
	AllowedMethods   string `env:"CORS_ALLOWED_METHODS, default=GET,POST,PUT,PATCH,DELETE,OPTIONS"`
	AllowedHeaders   string `env:"CORS_ALLOWED_HEADERS, default=Authorization,Content-Type,X-Request-Id,Operation-Id,Idempotency-Key,Saved-Source-Surface,X-Client-Platform,X-App-Build"`
	ExposeHeaders    string `env:"CORS_EXPOSE_HEADERS, default=X-Request-Id"`
	AllowCredentials bool   `env:"CORS_ALLOW_CREDENTIALS, default=false"`
	MaxAgeSeconds    int    `env:"CORS_MAX_AGE_SECONDS, default=600"`
}

type RateLimitConfig struct {
	Enabled           bool          `env:"RATE_LIMIT_ENABLED, default=true"`
	RequestsPerMinute int           `env:"RATE_LIMIT_REQUESTS_PER_MINUTE, default=120"`
	CleanupInterval   time.Duration `env:"RATE_LIMIT_CLEANUP_INTERVAL, default=1m"`
}
