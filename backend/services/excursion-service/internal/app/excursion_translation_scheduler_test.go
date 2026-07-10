package app

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/model"
)

func TestBuildItineraryJobsContainsOnlyGuideAuthoredItineraryFields(t *testing.T) {
	t.Parallel()

	excursionID := uuid.New()
	itemID := uuid.New()
	jobs, err := NewExcursionTranslationScheduler(5).BuildItineraryJobs(
		excursionID,
		"ru",
		[]*model.ExcursionItineraryItem{
			{
				ID:          itemID,
				Title:       "Исходное название этапа",
				Description: "Авторское описание этапа маршрута",
			},
		},
		time.Date(2026, time.July, 10, 12, 0, 0, 0, time.UTC),
	)
	if err != nil {
		t.Fatalf("BuildItineraryJobs() error = %v", err)
	}
	if len(jobs) != 2 {
		t.Fatalf("jobs count = %d, want 2 target-language jobs", len(jobs))
	}

	for _, job := range jobs {
		if job.ExcursionID != excursionID || job.EntityID != itemID {
			t.Fatalf("job identity = %s/%s, want %s/%s", job.ExcursionID, job.EntityID, excursionID, itemID)
		}
		if job.EntityType != model.ExcursionTranslationEntityItineraryItem {
			t.Fatalf("entity type = %q, want itinerary_item", job.EntityType)
		}
		if len(job.SourceFields) != 2 {
			t.Fatalf("source fields = %#v, want only title and description", job.SourceFields)
		}
		if job.SourceFields["title"] != "Исходное название этапа" {
			t.Fatalf("title = %q", job.SourceFields["title"])
		}
		if job.SourceFields["description"] != "Авторское описание этапа маршрута" {
			t.Fatalf("description = %q", job.SourceFields["description"])
		}
	}
}
