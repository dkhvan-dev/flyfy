package app

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

func TestActivityTranslationSchedulerSkipsCompleteTarget(t *testing.T) {
	scheduler := NewActivityTranslationScheduler(3)
	activityID := uuid.New()
	jobs, err := scheduler.BuildJobs(
		activityID,
		"ru",
		"Поход в горы",
		"Подробное описание похода в горы.",
		model.ActivityTranslations{
			"en": {Title: "Mountain hike", Description: "Detailed mountain hike description."},
		},
		time.Date(2026, 7, 11, 10, 0, 0, 0, time.UTC),
	)
	if err != nil {
		t.Fatalf("BuildJobs() error = %v", err)
	}
	if len(jobs) != 1 || jobs[0].TargetLanguage != "kk" {
		t.Fatalf("jobs = %#v, want only kk target", jobs)
	}
	if jobs[0].SourceFields["title"] != "Поход в горы" || jobs[0].SourceHash == "" {
		t.Fatalf("job source = %#v, want normalized title and hash", jobs[0])
	}
}
