package app

import (
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/model"
)

type ExcursionTranslationScheduler struct {
	maxAttempts int
}

func NewExcursionTranslationScheduler(maxAttempts int) *ExcursionTranslationScheduler {
	if maxAttempts <= 0 {
		maxAttempts = 5
	}
	return &ExcursionTranslationScheduler{maxAttempts: maxAttempts}
}

func (s *ExcursionTranslationScheduler) BuildItineraryJobs(
	excursionID uuid.UUID,
	sourceLanguage string,
	itinerary []*model.ExcursionItineraryItem,
	now time.Time,
) ([]model.ExcursionTranslationJob, error) {
	normalizedSource, ok := model.NormalizeExcursionTranslationLanguage(sourceLanguage)
	if !ok {
		return nil, model.ErrInvalidExcursionTranslationLanguage
	}
	if now.IsZero() {
		now = time.Now().UTC()
	} else {
		now = now.UTC()
	}

	targets := excursionTranslationTargets(normalizedSource)
	jobs := make([]model.ExcursionTranslationJob, 0, len(itinerary)*len(targets))
	for _, item := range itinerary {
		if item == nil || item.ID == uuid.Nil {
			continue
		}
		sourceCopy := item.SourceCopyForLanguage(normalizedSource)
		fields := map[string]string{
			"title":       strings.TrimSpace(sourceCopy.Title),
			"description": strings.TrimSpace(sourceCopy.Description),
		}
		if fields["title"] == "" && fields["description"] == "" {
			continue
		}

		sourceHash := model.HashExcursionTranslationSource(normalizedSource, fields)
		for _, target := range targets {
			if item.HasCompleteTranslationForLanguage(target) {
				continue
			}
			jobs = append(jobs, model.ExcursionTranslationJob{
				ID:             uuid.New(),
				ExcursionID:    excursionID,
				EntityType:     model.ExcursionTranslationEntityItineraryItem,
				EntityID:       item.ID,
				SourceLanguage: normalizedSource,
				TargetLanguage: target,
				SourceFields:   fields,
				SourceHash:     sourceHash,
				Status:         model.ExcursionTranslationJobPending,
				MaxAttempts:    s.maxAttempts,
				NextRunAt:      now,
				CreatedAt:      now,
				UpdatedAt:      now,
			})
		}
	}
	return jobs, nil
}

func excursionTranslationTargets(sourceLanguage string) []string {
	languages := model.SupportedExcursionTranslationLanguages()
	targets := make([]string, 0, len(languages)-1)
	for _, language := range languages {
		if language != sourceLanguage {
			targets = append(targets, language)
		}
	}
	return targets
}
