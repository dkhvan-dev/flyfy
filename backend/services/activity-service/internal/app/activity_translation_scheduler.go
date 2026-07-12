package app

import (
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

type ActivityTranslationScheduler struct {
	maxAttempts int
}

func NewActivityTranslationScheduler(maxAttempts int) *ActivityTranslationScheduler {
	if maxAttempts <= 0 {
		maxAttempts = 5
	}
	return &ActivityTranslationScheduler{maxAttempts: maxAttempts}
}

func (s *ActivityTranslationScheduler) BuildJobs(
	activityID uuid.UUID,
	sourceLanguage string,
	title string,
	description string,
	translations model.ActivityTranslations,
	now time.Time,
) ([]model.ActivityTranslationJob, error) {
	if activityID == uuid.Nil {
		return nil, model.ErrInvalidActivityID
	}
	normalizedSource, ok := model.NormalizeActivityTranslationLanguage(sourceLanguage)
	if !ok {
		return nil, model.ErrInvalidActivityTranslationLanguage
	}

	fields := map[string]string{
		"title":       strings.TrimSpace(title),
		"description": strings.TrimSpace(description),
	}
	if fields["title"] == "" || fields["description"] == "" {
		return nil, fmt.Errorf("activity translation source fields are required")
	}
	sourceHash := model.HashActivityTranslationSource(normalizedSource, fields)
	translations = model.NormalizeActivityTranslations(translations)
	createdAt := now.UTC()
	jobs := make([]model.ActivityTranslationJob, 0, len(model.SupportedActivityTranslationLanguages())-1)
	for _, targetLanguage := range model.SupportedActivityTranslationLanguages() {
		if targetLanguage == normalizedSource {
			continue
		}
		copy := translations[targetLanguage]
		if strings.TrimSpace(copy.Title) != "" && strings.TrimSpace(copy.Description) != "" {
			continue
		}
		jobs = append(jobs, model.ActivityTranslationJob{
			ID:             uuid.New(),
			ActivityID:     activityID,
			SourceLanguage: normalizedSource,
			TargetLanguage: targetLanguage,
			SourceFields:   fields,
			SourceHash:     sourceHash,
			Status:         model.ActivityTranslationJobPending,
			MaxAttempts:    s.maxAttempts,
			NextRunAt:      createdAt,
			CreatedAt:      createdAt,
			UpdatedAt:      createdAt,
		})
	}
	return jobs, nil
}
