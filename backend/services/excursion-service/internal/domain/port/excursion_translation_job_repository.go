package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/model"
)

type ExcursionTranslationJobRepository interface {
	EnqueueExcursionTranslationJobs(ctx context.Context, jobs []model.ExcursionTranslationJob) error
	MarkExcursionTranslationJobsStale(ctx context.Context, excursionID uuid.UUID, entityIDs []uuid.UUID) error
	ClaimExcursionTranslationJobs(ctx context.Context, workerID string, limit int, lockTimeout time.Duration) ([]model.ExcursionTranslationJob, error)
	ApplyExcursionTranslationJob(ctx context.Context, jobID uuid.UUID, translatedFields map[string]string, provider string) (model.ExcursionTranslationApplyResult, error)
	CompleteExcursionTranslationJob(ctx context.Context, jobID uuid.UUID, provider string) error
	FailExcursionTranslationJob(ctx context.Context, jobID uuid.UUID, retryable bool, nextRunAt time.Time, lastError string) error
	MarkExcursionTranslationJobStale(ctx context.Context, jobID uuid.UUID) error
	GetExcursionTranslationQueueStats(ctx context.Context) (model.ExcursionTranslationQueueStats, error)
}

type ExcursionTranslationBackfillRepository interface {
	ExcursionTranslationJobRepository
	ListExcursionTranslationBackfillCandidates(
		ctx context.Context,
		afterID uuid.UUID,
		limit int,
	) ([]model.ExcursionTranslationBackfillCandidate, error)
}
