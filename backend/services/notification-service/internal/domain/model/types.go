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
	ID                   uuid.UUID
	UserID               uuid.UUID
	Platform             Platform
	Provider             Provider
	Environment          Environment
	SessionID            string
	DeviceInstallationID string
	AppBundleID          string
	AppVersion           string
	DeviceModel          string
	Manufacturer         string
	Locale               string
	Timezone             string
	Token                string
	TokenHash            string
	Enabled              bool
	CreatedAt            time.Time
	UpdatedAt            time.Time
	LastSeenAt           time.Time
	InvalidatedAt        *time.Time
	InvalidationReason   string
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

type NotificationPreferences struct {
	UserID                 uuid.UUID
	PushEnabled            bool
	ActivityEnabled        bool
	ExcursionEnabled       bool
	ChatEnabled            bool
	MarketingEnabled       bool
	QuietHoursEnabled      bool
	QuietHoursStartMinutes int
	QuietHoursEndMinutes   int
	Timezone               string
	CreatedAt              time.Time
	UpdatedAt              time.Time
}

type UpdateNotificationPreferencesParams struct {
	PushEnabled            *bool
	ActivityEnabled        *bool
	ExcursionEnabled       *bool
	ChatEnabled            *bool
	MarketingEnabled       *bool
	QuietHoursEnabled      *bool
	QuietHoursStartMinutes *int
	QuietHoursEndMinutes   *int
	Timezone               *string
}

func DefaultNotificationPreferences(userID uuid.UUID) NotificationPreferences {
	now := time.Now().UTC()
	return NotificationPreferences{
		UserID:                 userID,
		PushEnabled:            true,
		ActivityEnabled:        true,
		ExcursionEnabled:       true,
		ChatEnabled:            true,
		MarketingEnabled:       false,
		QuietHoursEnabled:      false,
		QuietHoursStartMinutes: 22 * 60,
		QuietHoursEndMinutes:   8 * 60,
		Timezone:               "UTC",
		CreatedAt:              now,
		UpdatedAt:              now,
	}
}

func (p NotificationPreferences) ApplyUpdate(params UpdateNotificationPreferencesParams) NotificationPreferences {
	if params.PushEnabled != nil {
		p.PushEnabled = *params.PushEnabled
	}
	if params.ActivityEnabled != nil {
		p.ActivityEnabled = *params.ActivityEnabled
	}
	if params.ExcursionEnabled != nil {
		p.ExcursionEnabled = *params.ExcursionEnabled
	}
	if params.ChatEnabled != nil {
		p.ChatEnabled = *params.ChatEnabled
	}
	if params.MarketingEnabled != nil {
		p.MarketingEnabled = *params.MarketingEnabled
	}
	if params.QuietHoursEnabled != nil {
		p.QuietHoursEnabled = *params.QuietHoursEnabled
	}
	if params.QuietHoursStartMinutes != nil {
		p.QuietHoursStartMinutes = *params.QuietHoursStartMinutes
	}
	if params.QuietHoursEndMinutes != nil {
		p.QuietHoursEndMinutes = *params.QuietHoursEndMinutes
	}
	if params.Timezone != nil {
		p.Timezone = strings.TrimSpace(*params.Timezone)
	}
	p.Normalize()
	p.UpdatedAt = time.Now().UTC()
	return p
}

func (p *NotificationPreferences) Normalize() {
	p.QuietHoursStartMinutes = clampMinuteOfDay(p.QuietHoursStartMinutes, 22*60)
	p.QuietHoursEndMinutes = clampMinuteOfDay(p.QuietHoursEndMinutes, 8*60)
	p.Timezone = strings.TrimSpace(p.Timezone)
	if p.Timezone == "" {
		p.Timezone = "UTC"
	}
	if p.CreatedAt.IsZero() {
		p.CreatedAt = time.Now().UTC()
	}
	if p.UpdatedAt.IsZero() {
		p.UpdatedAt = p.CreatedAt
	}
}

func (p NotificationPreferences) AllowsPush(category string, priority Priority, now time.Time) bool {
	p.Normalize()
	if !p.PushEnabled {
		return false
	}

	switch normalizeNotificationCategory(category) {
	case "activity":
		if !p.ActivityEnabled {
			return false
		}
	case "excursion":
		if !p.ExcursionEnabled {
			return false
		}
	case "chat":
		if !p.ChatEnabled {
			return false
		}
	case "marketing":
		if !p.MarketingEnabled {
			return false
		}
	}

	if priority.Normalize() == PriorityHigh || !p.QuietHoursEnabled {
		return true
	}
	return !p.isInQuietHours(now)
}

func (p NotificationPreferences) isInQuietHours(now time.Time) bool {
	location, err := time.LoadLocation(p.Timezone)
	if err != nil {
		location = time.UTC
	}
	local := now.In(location)
	minute := local.Hour()*60 + local.Minute()
	start := clampMinuteOfDay(p.QuietHoursStartMinutes, 22*60)
	end := clampMinuteOfDay(p.QuietHoursEndMinutes, 8*60)
	if start == end {
		return false
	}
	if start < end {
		return minute >= start && minute < end
	}
	return minute >= start || minute < end
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

func normalizeNotificationCategory(category string) string {
	switch strings.TrimSpace(strings.ToLower(category)) {
	case "activity", "activities":
		return "activity"
	case "excursion", "excursions", "tour", "tours", "booking", "bookings":
		return "excursion"
	case "chat", "message", "messages":
		return "chat"
	case "content", "story", "stories", "post", "posts":
		return "content"
	case "marketing", "promotion", "promotions", "offer", "offers":
		return "marketing"
	case "system", "security":
		return "system"
	default:
		return "general"
	}
}

func clampMinuteOfDay(value int, fallback int) int {
	if value < 0 || value >= 24*60 {
		return fallback
	}
	return value
}
