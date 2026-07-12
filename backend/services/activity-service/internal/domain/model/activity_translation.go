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

var ErrInvalidActivityTranslationLanguage = errors.New("invalid activity translation language")

type ActivityTranslationStatus string

const (
	ActivityTranslationNone      ActivityTranslationStatus = "NONE"
	ActivityTranslationPending   ActivityTranslationStatus = "PENDING"
	ActivityTranslationPartial   ActivityTranslationStatus = "PARTIAL"
	ActivityTranslationCompleted ActivityTranslationStatus = "COMPLETED"
	ActivityTranslationFailed    ActivityTranslationStatus = "FAILED"
	ActivityTranslationDisabled  ActivityTranslationStatus = "DISABLED"
)

type ActivityTranslationJobStatus string

const (
	ActivityTranslationJobPending    ActivityTranslationJobStatus = "PENDING"
	ActivityTranslationJobProcessing ActivityTranslationJobStatus = "PROCESSING"
	ActivityTranslationJobCompleted  ActivityTranslationJobStatus = "COMPLETED"
	ActivityTranslationJobFailed     ActivityTranslationJobStatus = "FAILED"
	ActivityTranslationJobStale      ActivityTranslationJobStatus = "STALE"
	ActivityTranslationJobCancelled  ActivityTranslationJobStatus = "CANCELLED"
)

type ActivityLocalizedCopy struct {
	Title       string `json:"title,omitempty"`
	Description string `json:"description,omitempty"`
}

type ActivityTranslations map[string]ActivityLocalizedCopy

type ActivityTranslationJob struct {
	ID             uuid.UUID
	ActivityID     uuid.UUID
	SourceLanguage string
	TargetLanguage string
	SourceFields   map[string]string
	SourceHash     string
	Status         ActivityTranslationJobStatus
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

type ActivityTranslationApplyResult string

const (
	ActivityTranslationApplied ActivityTranslationApplyResult = "APPLIED"
	ActivityTranslationStale   ActivityTranslationApplyResult = "STALE"
	ActivityTranslationNoop    ActivityTranslationApplyResult = "NOOP"
)

type ActivityTranslationQueueStats struct {
	PendingCount            int64
	ProcessingCount         int64
	OldestPendingAgeSeconds float64
}

type ActivityTranslationBackfillCandidate struct {
	ActivityID     uuid.UUID
	SourceLanguage string
	Title          string
	Description    string
	Translations   ActivityTranslations
}

func SupportedActivityTranslationLanguages() []string {
	return []string{"ru", "kk", "en"}
}

func NormalizeActivityTranslationLanguage(value string) (string, bool) {
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

func NormalizeActivityTranslationStatus(value string) ActivityTranslationStatus {
	switch ActivityTranslationStatus(strings.ToUpper(strings.TrimSpace(value))) {
	case ActivityTranslationPending:
		return ActivityTranslationPending
	case ActivityTranslationPartial:
		return ActivityTranslationPartial
	case ActivityTranslationCompleted:
		return ActivityTranslationCompleted
	case ActivityTranslationFailed:
		return ActivityTranslationFailed
	case ActivityTranslationDisabled:
		return ActivityTranslationDisabled
	default:
		return ActivityTranslationNone
	}
}

func NormalizeActivityTranslations(input ActivityTranslations) ActivityTranslations {
	result := make(ActivityTranslations, len(input))
	for language, copy := range input {
		normalizedLanguage, ok := NormalizeActivityTranslationLanguage(language)
		if !ok {
			continue
		}
		copy.Title = strings.TrimSpace(copy.Title)
		copy.Description = strings.TrimSpace(copy.Description)
		if copy.Title == "" && copy.Description == "" {
			continue
		}
		result[normalizedLanguage] = copy
	}
	return result
}

func HashActivityTranslationSource(sourceLanguage string, fields map[string]string) string {
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

func (a *Activity) ResetTranslations(sourceLanguage string, status ActivityTranslationStatus) error {
	normalizedSource, ok := NormalizeActivityTranslationLanguage(sourceLanguage)
	if !ok {
		return ErrInvalidActivityTranslationLanguage
	}
	a.SourceLanguage = normalizedSource
	a.TranslationStatus = NormalizeActivityTranslationStatus(string(status))
	a.Translations = ActivityTranslations{
		normalizedSource: {
			Title:       strings.TrimSpace(a.Title),
			Description: strings.TrimSpace(a.Description),
		},
	}
	return nil
}

func (a *Activity) LocalizedCopy(language string) ActivityLocalizedCopy {
	if a == nil {
		return ActivityLocalizedCopy{}
	}
	normalizedLanguage, ok := NormalizeActivityTranslationLanguage(language)
	if ok {
		copy := NormalizeActivityTranslations(a.Translations)[normalizedLanguage]
		if strings.TrimSpace(copy.Title) != "" && strings.TrimSpace(copy.Description) != "" {
			return copy
		}
	}
	return ActivityLocalizedCopy{
		Title:       strings.TrimSpace(a.Title),
		Description: strings.TrimSpace(a.Description),
	}
}
