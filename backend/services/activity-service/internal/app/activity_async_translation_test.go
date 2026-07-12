package app

import (
	"context"
	"testing"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

type activityTranslationMutationRepoStub struct {
	*activityRepoStub
	createdActivity *model.Activity
	createdJobs     []model.ActivityTranslationJob
	updatedActivity *model.Activity
	updatedJobs     []model.ActivityTranslationJob
}

func (s *activityTranslationMutationRepoStub) CreateActivityWithTranslationJobs(
	ctx context.Context,
	activity *model.Activity,
	jobs []model.ActivityTranslationJob,
) error {
	if err := s.activityRepoStub.CreateActivity(ctx, activity); err != nil {
		return err
	}
	s.createdActivity = activity
	s.createdJobs = append([]model.ActivityTranslationJob(nil), jobs...)
	return nil
}

func (s *activityTranslationMutationRepoStub) UpdateActivityWithTranslationJobs(
	ctx context.Context,
	activity *model.Activity,
	jobs []model.ActivityTranslationJob,
) error {
	if err := s.activityRepoStub.UpdateActivity(ctx, activity); err != nil {
		return err
	}
	s.updatedActivity = activity
	s.updatedJobs = append([]model.ActivityTranslationJob(nil), jobs...)
	return nil
}

func TestCreateActivityQueuesTranslationsWithoutCallingTranslator(t *testing.T) {
	repo := &activityTranslationMutationRepoStub{activityRepoStub: &activityRepoStub{}}
	uc := NewActivityUseCase(repo).WithAsyncTranslationConfig(true, 4)
	input := validCreateActivityInput()
	input.SourceLanguage = "kk-KZ"

	created, err := uc.CreateActivity(context.Background(), input)
	if err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
	}
	if repo.createdActivity != created {
		t.Fatal("activity and translation jobs were not persisted through the atomic repository path")
	}
	if created.SourceLanguage != "kk" {
		t.Fatalf("source language = %q, want kk", created.SourceLanguage)
	}
	if created.TranslationStatus != model.ActivityTranslationPending {
		t.Fatalf("translation status = %q, want PENDING", created.TranslationStatus)
	}
	if sourceCopy := created.Translations["kk"]; sourceCopy.Title != created.Title || sourceCopy.Description != created.Description {
		t.Fatalf("source translation = %#v, want original copy", sourceCopy)
	}
	if len(repo.createdJobs) != 2 {
		t.Fatalf("translation jobs = %d, want 2", len(repo.createdJobs))
	}
	targets := map[string]bool{}
	for _, job := range repo.createdJobs {
		targets[job.TargetLanguage] = true
		if job.SourceLanguage != "kk" || job.MaxAttempts != 4 || job.SourceHash == "" {
			t.Fatalf("unexpected translation job: %#v", job)
		}
	}
	if !targets["ru"] || !targets["en"] {
		t.Fatalf("translation targets = %#v, want ru and en", targets)
	}
}

func TestCreateActivityKeepsWritesAvailableWhenAsyncTranslationDisabled(t *testing.T) {
	repo := &activityTranslationMutationRepoStub{activityRepoStub: &activityRepoStub{}}
	uc := NewActivityUseCase(repo).WithAsyncTranslationConfig(false, 4)
	input := validCreateActivityInput()
	input.SourceLanguage = "en"

	created, err := uc.CreateActivity(context.Background(), input)
	if err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
	}
	if created.TranslationStatus != model.ActivityTranslationDisabled {
		t.Fatalf("translation status = %q, want DISABLED", created.TranslationStatus)
	}
	if len(repo.createdJobs) != 0 {
		t.Fatalf("translation jobs = %d, want 0", len(repo.createdJobs))
	}
}
