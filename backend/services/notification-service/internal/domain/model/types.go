package model

import (
	"strings"
	"time"

	"github.com/google/uuid"
)

type Platform string

const (
	PlatformAndroid Platform = "android"
	PlatformIOS     Platform = "ios"
)

func (p Platform) IsValid() bool {
	switch p {
	case PlatformAndroid, PlatformIOS:
		return true
	default:
		return false
	}
}

type Provider string

const (
	ProviderFCM  Provider = "fcm"
	ProviderAPNS Provider = "apns"
	ProviderHMS  Provider = "hms"
)

func (p Provider) IsValid() bool {
	switch p {
	case ProviderFCM, ProviderAPNS, ProviderHMS:
		return true
	default:
		return false
	}
}

func IsProviderCompatible(platform Platform, provider Provider) bool {
	switch platform {
	case PlatformIOS:
		return provider == ProviderAPNS
	case PlatformAndroid:
		return provider == ProviderFCM || provider == ProviderHMS
	default:
		return false
	}
}

type Environment string

const (
	EnvironmentSandbox    Environment = "sandbox"
	EnvironmentProduction Environment = "production"
)

func (e Environment) IsValid() bool {
	switch e {
	case EnvironmentSandbox, EnvironmentProduction:
		return true
	default:
		return false
	}
}

type Priority string

const (
	PriorityNormal Priority = "normal"
	PriorityHigh   Priority = "high"
)

func (p Priority) Normalize() Priority {
	if p == PriorityHigh {
		return PriorityHigh
	}
	return PriorityNormal
}

type DeliveryStatus string

const (
	DeliveryPending        DeliveryStatus = "pending"
	DeliverySucceeded      DeliveryStatus = "succeeded"
	DeliveryRetryScheduled DeliveryStatus = "retry_scheduled"
	DeliveryFailed         DeliveryStatus = "failed"
	DeliveryInvalidToken   DeliveryStatus = "invalid_token"
)

type DeviceToken struct {
	ID                 uuid.UUID
	UserID             uuid.UUID
	Platform           Platform
	Provider           Provider
	Environment        Environment
	AppBundleID        string
	AppVersion         string
	DeviceModel        string
	Manufacturer       string
	Locale             string
	Timezone           string
	Token              string
	TokenHash          string
	Enabled            bool
	CreatedAt          time.Time
	UpdatedAt          time.Time
	LastSeenAt         time.Time
	InvalidatedAt      *time.Time
	InvalidationReason string
}

type NotificationPayload struct {
	Title       string
	Body        string
	ImageURL    string
	DeepLink    string
	Data        map[string]string
	CollapseKey string
	TTL         time.Duration
}

type NotificationRequest struct {
	ID               uuid.UUID
	IdempotencyKey   string
	SourceService    string
	RecipientUserIDs []uuid.UUID
	Category         string
	Priority         Priority
	Payload          NotificationPayload
	Status           string
	ScheduledAt      time.Time
	CreatedAt        time.Time
}

type UserNotification struct {
	ID        uuid.UUID
	Category  string
	Priority  Priority
	Payload   NotificationPayload
	CreatedAt time.Time
	ReadAt    *time.Time
}

type NotificationCategorySummary struct {
	Category    string
	Latest      UserNotification
	UnreadCount int
	TotalCount  int
}

type Delivery struct {
	ID            uuid.UUID
	RequestID     uuid.UUID
	DeviceTokenID uuid.UUID
	UserID        uuid.UUID
	Platform      Platform
	Provider      Provider
	Environment   Environment
	Category      string
	Token         string
	Payload       NotificationPayload
	Priority      Priority
	Status        DeliveryStatus
	AttemptCount  int
	MaxAttempts   int
	NextAttemptAt time.Time
	LastErrorCode string
	LastError     string
}

type ProviderSendStatus string

const (
	ProviderSendSucceeded    ProviderSendStatus = "succeeded"
	ProviderSendRetryable    ProviderSendStatus = "retryable"
	ProviderSendInvalidToken ProviderSendStatus = "invalid_token"
	ProviderSendTerminal     ProviderSendStatus = "terminal"
)

type ProviderSendResult struct {
	Status            ProviderSendStatus
	ProviderMessageID string
	ErrorCode         string
	ErrorMessage      string
	RetryAfter        time.Duration
}

func NormalizeLocale(value string) string {
	value = strings.TrimSpace(strings.ToLower(value))
	if value == "" {
		return "en"
	}
	return value
}
