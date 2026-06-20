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
	Log          LogConfig
	Security     SecurityConfig
	Routes       RoutesConfig
	Downstreams  DownstreamsConfig
	TokenService TokenServiceConfig
	TrustService TrustServiceConfig
	CORS         CORSConfig
	RateLimit    RateLimitConfig
	Redis        RedisConfig
}

type AppConfig struct {
	Env string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(a.Env, "production")
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
	CurrencyService     string `env:"CURRENCY_SERVICE_HTTP_URL, default=http://currency-service:8098"`
	PlaceService        string `env:"PLACE_SERVICE_HTTP_URL, default=http://place-service:8090"`
	PaymentService      string `env:"PAYMENT_SERVICE_HTTP_URL, default=http://payment-service:8091"`
	StickerService      string `env:"STICKER_SERVICE_HTTP_URL, default=http://sticker-service:8092"`
	NotificationService string `env:"NOTIFICATION_SERVICE_HTTP_URL, default=http://notification-service:8097"`
	AdminPanelService   string `env:"ADMIN_PANEL_SERVICE_HTTP_URL, default=http://admin-panel:8095"`
}

type RedisConfig struct {
	Addr string        `env:"REDIS_ADDR, default=localhost:6379"`
	DB   int           `env:"REDIS_CACHE_DB, default=3"`
	TTL  time.Duration `env:"REDIS_CACHE_TTL, default=1h"`
}

type TokenServiceConfig struct {
	Target        string        `env:"TOKEN_SERVICE_GRPC_TARGET, default=dns:///token-service:9092"`
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
	return &cfg, nil
}

type CORSConfig struct {
	AllowedOrigins   string `env:"CORS_ALLOWED_ORIGINS, default=*"`
	AllowedMethods   string `env:"CORS_ALLOWED_METHODS, default=GET,POST,PUT,PATCH,DELETE,OPTIONS"`
	AllowedHeaders   string `env:"CORS_ALLOWED_HEADERS, default=Authorization,Content-Type,X-Request-Id"`
	ExposeHeaders    string `env:"CORS_EXPOSE_HEADERS, default=X-Request-Id"`
	AllowCredentials bool   `env:"CORS_ALLOW_CREDENTIALS, default=false"`
	MaxAgeSeconds    int    `env:"CORS_MAX_AGE_SECONDS, default=600"`
}

type RateLimitConfig struct {
	Enabled           bool          `env:"RATE_LIMIT_ENABLED, default=true"`
	RequestsPerMinute int           `env:"RATE_LIMIT_REQUESTS_PER_MINUTE, default=120"`
	CleanupInterval   time.Duration `env:"RATE_LIMIT_CLEANUP_INTERVAL, default=1m"`
}
