package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

type ActivityTranslationRequest struct {
	SourceLocale    string
	TargetLocales   []string
	Texts           []string
	AllowIncomplete bool
}

type ActivityTranslationTextStatus string

const (
	ActivityTranslationTextTranslated          ActivityTranslationTextStatus = "translated"
	ActivityTranslationTextCached              ActivityTranslationTextStatus = "cached"
	ActivityTranslationTextSameLanguage        ActivityTranslationTextStatus = "same_language"
	ActivityTranslationTextQuotaExhausted      ActivityTranslationTextStatus = "quota_exhausted"
	ActivityTranslationTextDisabled            ActivityTranslationTextStatus = "disabled"
	ActivityTranslationTextProviderUnavailable ActivityTranslationTextStatus = "provider_unavailable"
)

type ActivityTranslationTextResult struct {
	Text     string
	Status   ActivityTranslationTextStatus
	Provider string
	CacheHit bool
}

type ActivityTranslationResult struct {
	Translations map[string][]string
	Items        map[string][]ActivityTranslationTextResult
	Provider     string
}

type ActivityTranslator interface {
	TranslateTexts(ctx context.Context, input ActivityTranslationRequest) (ActivityTranslationResult, error)
}

type ActivityTranslationJobRepository interface {
	EnqueueActivityTranslationJobs(ctx context.Context, jobs []model.ActivityTranslationJob) error
	ClaimActivityTranslationJobs(ctx context.Context, workerID string, limit int, lockTimeout time.Duration) ([]model.ActivityTranslationJob, error)
	ApplyActivityTranslationJob(ctx context.Context, jobID uuid.UUID, translatedFields map[string]string, provider string) (model.ActivityTranslationApplyResult, error)
	FailActivityTranslationJob(ctx context.Context, jobID uuid.UUID, retryable bool, nextRunAt time.Time, lastError string) error
	GetActivityTranslationQueueStats(ctx context.Context) (model.ActivityTranslationQueueStats, error)
}

type ActivityTranslationMutationRepository interface {
	CreateActivityWithTranslationJobs(
		ctx context.Context,
		activity *model.Activity,
		jobs []model.ActivityTranslationJob,
	) error
	UpdateActivityWithTranslationJobs(
		ctx context.Context,
		activity *model.Activity,
		jobs []model.ActivityTranslationJob,
	) error
}

type ActivityTranslationBackfillRepository interface {
	ActivityTranslationJobRepository
	ListActivityTranslationBackfillCandidates(
		ctx context.Context,
		afterID uuid.UUID,
		limit int,
	) ([]model.ActivityTranslationBackfillCandidate, error)
}
