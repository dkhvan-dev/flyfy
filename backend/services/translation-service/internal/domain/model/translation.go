package model

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"
)

type BillingMode string

const (
	BillingModeFreeOnly    BillingMode = "free_only"
	BillingModePaidAllowed BillingMode = "paid_allowed"
	BillingModeDisabled    BillingMode = "disabled"
)

func NormalizeBillingMode(value string) BillingMode {
	switch BillingMode(strings.ToLower(strings.TrimSpace(value))) {
	case BillingModePaidAllowed:
		return BillingModePaidAllowed
	case BillingModeDisabled:
		return BillingModeDisabled
	default:
		return BillingModeFreeOnly
	}
}

type TranslationStatus string

const (
	TranslationStatusTranslated          TranslationStatus = "translated"
	TranslationStatusCached              TranslationStatus = "cached"
	TranslationStatusSameLanguage        TranslationStatus = "same_language"
	TranslationStatusQuotaExhausted      TranslationStatus = "quota_exhausted"
	TranslationStatusDisabled            TranslationStatus = "disabled"
	TranslationStatusProviderUnavailable TranslationStatus = "provider_unavailable"
)

type QualityStatus string

const (
	QualityStatusMachine  QualityStatus = "machine"
	QualityStatusReviewed QualityStatus = "reviewed"
)

type CacheKey struct {
	SourceHash      string
	SourceLanguage  Language
	TargetLanguage  Language
	Provider        string
	GlossaryVersion string
}

func NewCacheKey(sourceText string, sourceLanguage Language, targetLanguage Language, provider string, glossaryVersion string) CacheKey {
	normalizedSource := NormalizeSourceText(sourceText)
	digest := sha256.Sum256([]byte(normalizedSource))
	return CacheKey{
		SourceHash:      hex.EncodeToString(digest[:]),
		SourceLanguage:  sourceLanguage,
		TargetLanguage:  targetLanguage,
		Provider:        strings.TrimSpace(provider),
		GlossaryVersion: strings.TrimSpace(glossaryVersion),
	}
}

func (k CacheKey) String() string {
	return fmt.Sprintf("%s:%s:%s:%s:%s", k.Provider, k.SourceLanguage, k.TargetLanguage, k.GlossaryVersion, k.SourceHash)
}

func NormalizeSourceText(value string) string {
	return strings.TrimSpace(value)
}

func CountBillableCharacters(values []string) int {
	total := 0
	for _, value := range values {
		total += utf8.RuneCountInString(value)
	}
	return total
}

type CachedTranslation struct {
	Key                  CacheKey
	NormalizedSourceText string
	TranslatedText       string
	Provider             string
	ProviderModelLabel   string
	QualityStatus        QualityStatus
	CreatedAt            time.Time
	UpdatedAt            time.Time
}

type TranslatedText struct {
	Text     string
	Status   TranslationStatus
	Provider string
	CacheHit bool
}

type TranslationJobStatus string

const (
	TranslationJobStatusPending    TranslationJobStatus = "pending"
	TranslationJobStatusProcessing TranslationJobStatus = "processing"
	TranslationJobStatusCompleted  TranslationJobStatus = "completed"
	TranslationJobStatusFailed     TranslationJobStatus = "failed"
	TranslationJobStatusCancelled  TranslationJobStatus = "cancelled"
)

type TranslationJob struct {
	ID              string
	IdempotencyKey  string
	SourceLanguage  Language
	TargetLanguages []Language
	ContentType     ContentType
	Texts           []string
	Status          TranslationJobStatus
	Result          map[Language][]TranslatedText
	ErrorCode       string
	ErrorMessage    string
	AttemptCount    int
	CreatedAt       time.Time
	UpdatedAt       time.Time
	CompletedAt     *time.Time
}

type TranslationJobCompletion struct {
	ID          string
	Result      map[Language][]TranslatedText
	CompletedAt time.Time
}

type TranslationJobFailure struct {
	ID           string
	ErrorCode    string
	ErrorMessage string
	FailedAt     time.Time
}

type MonthlyUsageRow struct {
	Provider           string
	Environment        string
	YearMonth          string
	SourceLanguage     Language
	TargetLanguage     Language
	ContentType        ContentType
	BillingMode        BillingMode
	ReservedCharacters int
	BilledCharacters   int
	RequestCount       int
	MonthlyLimit       int
	WarningReached     bool
	CriticalReached    bool
}

type UsageReservation struct {
	Provider               string
	Environment            string
	YearMonth              string
	SourceLanguage         Language
	TargetLanguage         Language
	ContentType            ContentType
	BillingMode            BillingMode
	Characters             int
	MonthlyLimit           int
	QuotaWarningThreshold  float64
	QuotaCriticalThreshold float64
	ReservedAt             time.Time
}

type UsageReservationResult struct {
	Allowed            bool
	ReservedCharacters int
	UsedCharacters     int
	LimitCharacters    int
	WarningReached     bool
	CriticalReached    bool
}

type UsageCommit struct {
	Provider           string
	Environment        string
	YearMonth          string
	SourceLanguage     Language
	TargetLanguage     Language
	ContentType        ContentType
	ReservedCharacters int
	BilledCharacters   int
	RequestCount       int
	CommittedAt        time.Time
}

type UsageRelease struct {
	Provider       string
	Environment    string
	YearMonth      string
	SourceLanguage Language
	TargetLanguage Language
	ContentType    ContentType
	Characters     int
	ReleasedAt     time.Time
}

func YearMonth(value time.Time) string {
	return value.UTC().Format("2006-01")
}
