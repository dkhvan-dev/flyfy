package config

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/sethvargo/go-envconfig"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/anti-fraud-service/internal/app"
)

type Config struct {
	App      AppConfig
	HTTP     HTTPConfig
	Postgres PostgresConfig
	Log      LogConfig
	Security SecurityConfig
	Policy   PolicyConfig
	MTLS     transportauth.EnvConfig
}

type AppConfig struct {
	Name string `env:"APP_NAME, default=anti-fraud-service"`
	Env  string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(a.Env, "production")
}

type HTTPConfig struct {
	Port            int           `env:"HTTP_PORT, default=8096"`
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
	InternalServiceToken string `env:"INTERNAL_SERVICE_TOKEN, required"`
}

type PolicyConfig struct {
	Version                 string        `env:"FRAUD_POLICY_VERSION, default=2026-05-29.v1"`
	ShadowMode              bool          `env:"FRAUD_SHADOW_MODE, default=true"`
	Window                  time.Duration `env:"FRAUD_WINDOW, default=1h"`
	OTPSendPhoneLimit       int           `env:"FRAUD_OTP_SEND_PHONE_LIMIT, default=5"`
	OTPSendIPLimit          int           `env:"FRAUD_OTP_SEND_IP_LIMIT, default=25"`
	OTPVerifyPhoneLimit     int           `env:"FRAUD_OTP_VERIFY_PHONE_LIMIT, default=8"`
	OTPVerifyDeviceLimit    int           `env:"FRAUD_OTP_VERIFY_DEVICE_LIMIT, default=12"`
	TokenRefreshUserLimit   int           `env:"FRAUD_REFRESH_USER_LIMIT, default=120"`
	PaymentUserLimit        int           `env:"FRAUD_PAYMENT_USER_LIMIT, default=20"`
	HighPaymentAmountMinor  int64         `env:"FRAUD_HIGH_PAYMENT_AMOUNT_MINOR, default=1000000"`
	PaymentCurrency         string        `env:"FRAUD_PAYMENT_CURRENCY, default=KZT"`
	UploadUserLimit         int           `env:"FRAUD_UPLOAD_USER_LIMIT, default=60"`
	UploadIPLimit           int           `env:"FRAUD_UPLOAD_IP_LIMIT, default=250"`
	SensitiveDocumentReview bool          `env:"FRAUD_SENSITIVE_DOCUMENT_REVIEW, default=true"`

	ActivityCreateUserLimit       int   `env:"FRAUD_ACTIVITY_CREATE_USER_LIMIT, default=10"`
	ActivityJoinUserLimit         int   `env:"FRAUD_ACTIVITY_JOIN_USER_LIMIT, default=30"`
	ActivityCancellationUserLimit int   `env:"FRAUD_ACTIVITY_CANCELLATION_USER_LIMIT, default=12"`
	ActivityAttendanceUserLimit   int   `env:"FRAUD_ACTIVITY_ATTENDANCE_USER_LIMIT, default=40"`
	ActivityHighRiskAmountMinor   int64 `env:"FRAUD_ACTIVITY_HIGH_RISK_AMOUNT_MINOR, default=500000"`

	ExcursionPublishUserLimit     int     `env:"FRAUD_EXCURSION_PUBLISH_USER_LIMIT, default=8"`
	ExcursionBookingUserLimit     int     `env:"FRAUD_EXCURSION_BOOKING_USER_LIMIT, default=20"`
	ExcursionCancelUserLimit      int     `env:"FRAUD_EXCURSION_CANCEL_USER_LIMIT, default=10"`
	ExcursionHighRiskAmountMinor  int64   `env:"FRAUD_EXCURSION_HIGH_RISK_AMOUNT_MINOR, default=750000"`
	HighPriceChangePercent        float64 `env:"FRAUD_HIGH_PRICE_CHANGE_PERCENT, default=50"`
	HighPriceChangeAmountMinor    int64   `env:"FRAUD_HIGH_PRICE_CHANGE_AMOUNT_MINOR, default=50000"`
	RequireVerifiedGuideToPublish bool    `env:"FRAUD_REQUIRE_VERIFIED_GUIDE_TO_PUBLISH, default=true"`
}

func (p PolicyConfig) ToPolicy() app.Policy {
	return app.Policy{
		Version:                 p.Version,
		ShadowMode:              p.ShadowMode,
		Window:                  p.Window,
		OTPSendPhoneLimit:       p.OTPSendPhoneLimit,
		OTPSendIPLimit:          p.OTPSendIPLimit,
		OTPVerifyPhoneLimit:     p.OTPVerifyPhoneLimit,
		OTPVerifyDeviceLimit:    p.OTPVerifyDeviceLimit,
		TokenRefreshUserLimit:   p.TokenRefreshUserLimit,
		PaymentUserLimit:        p.PaymentUserLimit,
		HighPaymentAmountMinor:  p.HighPaymentAmountMinor,
		PaymentCurrency:         p.PaymentCurrency,
		UploadUserLimit:         p.UploadUserLimit,
		UploadIPLimit:           p.UploadIPLimit,
		SensitiveDocumentReview: p.SensitiveDocumentReview,

		ActivityCreateUserLimit:       p.ActivityCreateUserLimit,
		ActivityJoinUserLimit:         p.ActivityJoinUserLimit,
		ActivityCancellationUserLimit: p.ActivityCancellationUserLimit,
		ActivityAttendanceUserLimit:   p.ActivityAttendanceUserLimit,
		ActivityHighRiskAmountMinor:   p.ActivityHighRiskAmountMinor,
		ExcursionPublishUserLimit:     p.ExcursionPublishUserLimit,
		ExcursionBookingUserLimit:     p.ExcursionBookingUserLimit,
		ExcursionCancelUserLimit:      p.ExcursionCancelUserLimit,
		ExcursionHighRiskAmountMinor:  p.ExcursionHighRiskAmountMinor,
		HighPriceChangePercent:        p.HighPriceChangePercent,
		HighPriceChangeAmountMinor:    p.HighPriceChangeAmountMinor,
		RequireVerifiedGuideToPublish: p.RequireVerifiedGuideToPublish,
	}
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	return &cfg, nil
}
