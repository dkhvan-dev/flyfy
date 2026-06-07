package config

import (
	"context"
	"fmt"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	App          AppConfig
	HTTP         HTTPConfig
	DB           DBConfig
	Log          LogConfig
	Security     SecurityConfig
	GuideService GuideServiceConfig
	UserService  UserServiceConfig
	Attraction   AttractionServiceConfig
	FileManager  FileManagerConfig
	ChatService  ChatServiceConfig
	Notification NotificationServiceConfig
	Payment      PaymentServiceConfig
	Translation  TranslationServiceConfig
	Attendance   AttendanceConfig
	AntiFraud    AntiFraudConfig
	Trust        TrustServiceConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=excursion-service"`
	Env  string `env:"APP_ENV, default=development"`
}

type HTTPConfig struct {
	Port         int           `env:"HTTP_PORT, default=8093"`
	ReadTimeout  time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout time.Duration `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout  time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

type DBConfig struct {
	Host            string `env:"DB_HOST, default=localhost"`
	Port            int    `env:"DB_PORT, default=5432"`
	Name            string `env:"DB_NAME, default=excursion_service_db"`
	User            string `env:"DB_USER, default=excursion_service"`
	Password        string `env:"DB_PASSWORD, default=excursion_secret_dev"`
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
	InternalServiceToken       string `env:"INTERNAL_SERVICE_TOKEN, required"`
	RequireAuthenticatedWrites bool   `env:"REQUIRE_AUTHENTICATED_WRITES, default=true"`
	TrustedGatewayHeaderUserID string `env:"TRUSTED_GATEWAY_HEADER_USER_ID, default=X-User-Id"`
	TrustedGatewayHeaderRoles  string `env:"TRUSTED_GATEWAY_HEADER_ROLES, default=X-User-Roles"`
	TrustedGatewayHeaderSub    string `env:"TRUSTED_GATEWAY_HEADER_SUB, default=X-Auth-Subject"`
	RequestIDHeader            string `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
}

type GuideServiceConfig struct {
	Target  string `env:"GUIDE_SERVICE_GRPC_TARGET, default=dns:///guide-service:9095"`
	BaseURL string `env:"GUIDE_SERVICE_URL, default=http://guide-service:8085"`
}

type UserServiceConfig struct {
	Target string `env:"USER_SERVICE_GRPC_TARGET, default=dns:///user-service:9094"`
}

type AttractionServiceConfig struct {
	BaseURL string `env:"ATTRACTION_SERVICE_URL, default=http://attraction-service:8090"`
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

type TranslationServiceConfig struct {
	BaseURL string        `env:"TRANSLATION_SERVICE_URL"`
	Timeout time.Duration `env:"TRANSLATION_SERVICE_TIMEOUT, default=8s"`
}

type AttendanceConfig struct {
	QRSigningSecret          string        `env:"EXCURSION_ATTENDANCE_QR_SIGNING_SECRET"`
	QRTTL                    time.Duration `env:"EXCURSION_ATTENDANCE_QR_TTL, default=5m"`
	OfflineWindow            time.Duration `env:"EXCURSION_ATTENDANCE_OFFLINE_WINDOW, default=4h"`
	CompletionTickerInterval time.Duration `env:"EXCURSION_SCHEDULE_COMPLETION_TICKER_INTERVAL, default=1m"`
	CompletionBatchSize      int           `env:"EXCURSION_SCHEDULE_COMPLETION_BATCH_SIZE, default=100"`
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

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	return &cfg, nil
}
