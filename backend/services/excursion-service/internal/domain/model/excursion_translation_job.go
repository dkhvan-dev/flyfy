package model

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var ErrInvalidExcursionTranslationLanguage = errors.New("invalid excursion translation language")

type ExcursionTranslationStatus string

const (
	ExcursionTranslationNone      ExcursionTranslationStatus = "NONE"
	ExcursionTranslationPending   ExcursionTranslationStatus = "PENDING"
	ExcursionTranslationPartial   ExcursionTranslationStatus = "PARTIAL"
	ExcursionTranslationCompleted ExcursionTranslationStatus = "COMPLETED"
	ExcursionTranslationFailed    ExcursionTranslationStatus = "FAILED"
	ExcursionTranslationDisabled  ExcursionTranslationStatus = "DISABLED"
)

type ExcursionTranslationJobStatus string

const (
	ExcursionTranslationJobPending    ExcursionTranslationJobStatus = "PENDING"
	ExcursionTranslationJobProcessing ExcursionTranslationJobStatus = "PROCESSING"
	ExcursionTranslationJobCompleted  ExcursionTranslationJobStatus = "COMPLETED"
	ExcursionTranslationJobFailed     ExcursionTranslationJobStatus = "FAILED"
	ExcursionTranslationJobStale      ExcursionTranslationJobStatus = "STALE"
	ExcursionTranslationJobCancelled  ExcursionTranslationJobStatus = "CANCELLED"
)

type ExcursionTranslationEntityType string

const ExcursionTranslationEntityItineraryItem ExcursionTranslationEntityType = "itinerary_item"

type ExcursionTranslationJob struct {
	ID             uuid.UUID
	ExcursionID    uuid.UUID
	EntityType     ExcursionTranslationEntityType
	EntityID       uuid.UUID
	SourceLanguage string
	TargetLanguage string
	SourceFields   map[string]string
	SourceHash     string
	Status         ExcursionTranslationJobStatus
	Attempts       int
	MaxAttempts    int
	NextRunAt      time.Time
	LockedAt       *time.Time
	LockedBy       *string
	LastError      *string
	Provider       *string
	CreatedAt      time.Time
	UpdatedAt      time.Time
	CompletedAt    *time.Time
}

type ExcursionTranslationApplyResult string

const (
	ExcursionTranslationApplied ExcursionTranslationApplyResult = "APPLIED"
	ExcursionTranslationStale   ExcursionTranslationApplyResult = "STALE"
	ExcursionTranslationNoop    ExcursionTranslationApplyResult = "NOOP"
)

type ExcursionTranslationQueueStats struct {
	PendingCount            int64
	ProcessingCount         int64
	OldestPendingAgeSeconds float64
}

type ExcursionTranslationBackfillCandidate struct {
	ExcursionID    uuid.UUID
	SourceLanguage string
	Itinerary      []*ExcursionItineraryItem
}

func SupportedExcursionTranslationLanguages() []string {
	return []string{"ru", "kk", "en"}
}

func NormalizeExcursionTranslationLanguage(value string) (string, bool) {
	normalized := strings.ToLower(strings.TrimSpace(value))
	if index := strings.IndexAny(normalized, "-_"); index >= 0 {
		normalized = normalized[:index]
	}
	switch normalized {
	case "ru", "kk", "en":
		return normalized, true
	default:
		return "", false
	}
}

func NormalizeExcursionTranslationStatus(value string) ExcursionTranslationStatus {
	switch ExcursionTranslationStatus(strings.ToUpper(strings.TrimSpace(value))) {
	case ExcursionTranslationPending:
		return ExcursionTranslationPending
	case ExcursionTranslationPartial:
		return ExcursionTranslationPartial
	case ExcursionTranslationCompleted:
		return ExcursionTranslationCompleted
	case ExcursionTranslationFailed:
		return ExcursionTranslationFailed
	case ExcursionTranslationDisabled:
		return ExcursionTranslationDisabled
	default:
		return ExcursionTranslationNone
	}
}

func HashExcursionTranslationSource(sourceLanguage string, fields map[string]string) string {
	normalizedFields := make(map[string]string, len(fields))
	for key, value := range fields {
		normalizedFields[strings.TrimSpace(key)] = strings.TrimSpace(value)
	}
	payload := struct {
		Language string            `json:"language"`
		Fields   map[string]string `json:"fields"`
	}{
		Language: strings.ToLower(strings.TrimSpace(sourceLanguage)),
		Fields:   normalizedFields,
	}
	encoded, _ := json.Marshal(payload)
	sum := sha256.Sum256(encoded)
	return hex.EncodeToString(sum[:])
}
