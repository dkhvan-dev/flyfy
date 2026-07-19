package savedmaintenance

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
)

var ErrInvalidDependencies = errors.New("invalid saved maintenance dependencies")

type Clock func() time.Time

type Runner struct {
	repository Repository
	config     Config
	now        Clock
}

func NewRunner(repository Repository, config Config, clock Clock) (*Runner, error) {
	if repository == nil || clock == nil {
		return nil, ErrInvalidDependencies
	}
	if err := config.Validate(); err != nil {
		return nil, err
	}
	return &Runner{repository: repository, config: config, now: clock}, nil
}

func NewDefaultRunner(repository Repository) (*Runner, error) {
	return NewRunner(repository, DefaultConfig(), func() time.Time { return time.Now().UTC() })
}

// Tick executes at most one bounded transaction per maintenance stage.
func (r *Runner) Tick(ctx context.Context) (Stats, error) {
	if err := ctx.Err(); err != nil {
		return Stats{}, err
	}
	if r == nil || r.repository == nil || r.now == nil {
		return Stats{}, ErrInvalidDependencies
	}

	startedAt := r.now().UTC()
	if startedAt.IsZero() {
		return Stats{}, ErrInvalidDependencies
	}
	request := BatchRequest{
		Now:                 startedAt,
		Limit:               r.config.BatchSize,
		OperationRetention:  r.config.OperationRetention,
		ProjectionRetention: r.config.ProjectionRetention,
	}
	stats := Stats{StartedAt: startedAt, Ticks: 1}

	purgeResult, err := r.repository.ProcessSubjectPurge(ctx, SubjectPurgeBatchRequest{Batch: request})
	if err != nil {
		stats.FinishedAt = r.now().UTC()
		return stats, classifyTaskError("process subject purge", err)
	}
	if err := purgeResult.Validate(request.Limit); err != nil {
		stats.FinishedAt = r.now().UTC()
		return stats, NewError("process subject purge", ErrorKindInvariant, false, err)
	}
	stats.SubjectPurgeRowsPurged = purgeResult.RowsPurged
	if purgeResult.PhaseAdvanced {
		stats.SubjectPurgePhasesAdvanced = 1
	}
	if purgeResult.Completed {
		stats.SubjectPurgesCompleted = 1
	}
	stats.HasMore = purgeResult.HasMore

	tasks := []struct {
		name  string
		run   func(context.Context, BatchRequest) (BatchResult, error)
		apply func(*Stats, int64)
	}{
		{"expire pending operations", r.repository.ExpirePendingOperations, func(s *Stats, n int64) { s.PendingOperationsExpired += n }},
		{"purge terminal operations", r.repository.PurgeTerminalOperations, func(s *Stats, n int64) { s.TerminalOperationsPurged += n }},
		{"purge terminal outbox", r.repository.PurgeTerminalOutbox, func(s *Stats, n int64) { s.TerminalOutboxPurged += n }},
		{"purge inbox dedup", r.repository.PurgeInboxDedup, func(s *Stats, n int64) { s.InboxDedupPurged += n }},
		{"cleanup deleted collection children", r.repository.CleanupDeletedCollectionChildren, func(s *Stats, n int64) { s.DeletedCollectionChildren += n }},
		{"purge removed collection items", r.repository.PurgeRemovedCollectionItems, func(s *Stats, n int64) { s.RemovedCollectionItemsPurged += n }},
		{"purge deleted collections", r.repository.PurgeDeletedCollections, func(s *Stats, n int64) { s.DeletedCollectionsPurged += n }},
		{"purge removed saved items", r.repository.PurgeRemovedSavedItems, func(s *Stats, n int64) { s.RemovedSavedItemsPurged += n }},
		{"mark projection GC candidates", r.repository.MarkProjectionGCCandidates, func(s *Stats, n int64) { s.ProjectionCandidatesMarked += n }},
		{"purge ephemeral projections", r.repository.PurgeEphemeralProjections, func(s *Stats, n int64) { s.EphemeralProjectionsPurged += n }},
		{"purge standard projections", r.repository.PurgeStandardProjections, func(s *Stats, n int64) { s.StandardProjectionsPurged += n }},
		{"purge completed subject purges", r.repository.PurgeCompletedSubjectPurges, func(s *Stats, n int64) { s.CompletedSubjectPurgesPurged += n }},
	}

	for _, task := range tasks {
		if err := ctx.Err(); err != nil {
			stats.FinishedAt = r.now().UTC()
			return stats, err
		}
		result, err := task.run(ctx, request)
		if err != nil {
			stats.FinishedAt = r.now().UTC()
			return stats, classifyTaskError(task.name, err)
		}
		if err := result.Validate(request.Limit); err != nil {
			stats.FinishedAt = r.now().UTC()
			return stats, NewError(task.name, ErrorKindInvariant, false, err)
		}
		task.apply(&stats, result.Affected)
		stats.HasMore = stats.HasMore || result.HasMore
	}

	stats.FinishedAt = r.now().UTC()
	return stats, nil
}

func (r *Runner) StartSubjectPurge(ctx context.Context, start SubjectPurgeStart) (SubjectPurgeJob, error) {
	if err := ctx.Err(); err != nil {
		return SubjectPurgeJob{}, err
	}
	if r == nil || r.repository == nil || r.now == nil {
		return SubjectPurgeJob{}, ErrInvalidDependencies
	}
	if err := start.Validate(); err != nil {
		return SubjectPurgeJob{}, err
	}
	job, err := r.repository.StartSubjectPurge(ctx, start, r.now().UTC())
	if err != nil {
		return SubjectPurgeJob{}, classifyTaskError("start subject purge", err)
	}
	if err := job.Validate(); err != nil || job.OperationID != start.OperationID ||
		job.Subject != start.Subject || job.OwnerUserID != start.OwnerUserID {
		if err == nil {
			err = ErrSubjectPurgeIdentityClash
		}
		return SubjectPurgeJob{}, NewError("start subject purge", ErrorKindInvariant, false, err)
	}
	return job, nil
}

func (r *Runner) SubjectPurge(ctx context.Context, operationID uuid.UUID) (SubjectPurgeJob, error) {
	if err := ctx.Err(); err != nil {
		return SubjectPurgeJob{}, err
	}
	if r == nil || r.repository == nil || operationID == uuid.Nil {
		return SubjectPurgeJob{}, ErrInvalidDependencies
	}
	job, err := r.repository.GetSubjectPurge(ctx, operationID)
	if err != nil {
		if errors.Is(err, ErrSubjectPurgeNotFound) {
			return SubjectPurgeJob{}, ErrSubjectPurgeNotFound
		}
		return SubjectPurgeJob{}, classifyTaskError("get subject purge", err)
	}
	if err := job.Validate(); err != nil {
		return SubjectPurgeJob{}, NewError("get subject purge", ErrorKindInvariant, false, err)
	}
	return job, nil
}

func (r *Runner) TickSubjectPurge(ctx context.Context, operationID uuid.UUID) (SubjectPurgeStats, error) {
	if err := ctx.Err(); err != nil {
		return SubjectPurgeStats{}, err
	}
	if r == nil || r.repository == nil || r.now == nil || operationID == uuid.Nil {
		return SubjectPurgeStats{}, ErrInvalidDependencies
	}
	startedAt := r.now().UTC()
	request := BatchRequest{
		Now:                 startedAt,
		Limit:               r.config.BatchSize,
		OperationRetention:  r.config.OperationRetention,
		ProjectionRetention: r.config.ProjectionRetention,
	}
	result, err := r.repository.ProcessSubjectPurge(ctx, SubjectPurgeBatchRequest{
		Batch:       request,
		OperationID: &operationID,
	})
	stats := SubjectPurgeStats{StartedAt: startedAt, FinishedAt: r.now().UTC(), Ticks: 1}
	if err != nil {
		return stats, classifyTaskError("process subject purge", err)
	}
	if err := result.Validate(request.Limit); err != nil {
		return stats, NewError("process subject purge", ErrorKindInvariant, false, err)
	}
	if !result.Found {
		return stats, ErrSubjectPurgeNotFound
	}
	stats.RowsPurged = result.RowsPurged
	if result.PhaseAdvanced {
		stats.PhasesAdvanced = 1
	}
	stats.Completed = result.Completed
	stats.HasMore = result.HasMore
	return stats, nil
}

func (r *Runner) RunSubjectPurgeOnce(ctx context.Context, operationID uuid.UUID) (SubjectPurgeStats, error) {
	if err := ctx.Err(); err != nil {
		return SubjectPurgeStats{}, err
	}
	if r == nil {
		return SubjectPurgeStats{}, ErrInvalidDependencies
	}
	var aggregate SubjectPurgeStats
	for batch := 0; batch < r.config.MaxBatchesPerRun; batch++ {
		stats, err := r.TickSubjectPurge(ctx, operationID)
		if aggregate.StartedAt.IsZero() {
			aggregate.StartedAt = stats.StartedAt
		}
		aggregate.FinishedAt = stats.FinishedAt
		aggregate.Ticks += stats.Ticks
		aggregate.RowsPurged += stats.RowsPurged
		aggregate.PhasesAdvanced += stats.PhasesAdvanced
		aggregate.Completed = stats.Completed
		aggregate.HasMore = stats.HasMore
		if err != nil || stats.Completed || !stats.HasMore {
			return aggregate, err
		}
	}
	aggregate.Capped = aggregate.HasMore
	return aggregate, nil
}

// RunOnce drains ready work for a bounded number of ticks. Capped tells the
// scheduler to arrange another run without turning normal backlog into an error.
func (r *Runner) RunOnce(ctx context.Context) (Stats, error) {
	if err := ctx.Err(); err != nil {
		return Stats{}, err
	}
	if r == nil {
		return Stats{}, ErrInvalidDependencies
	}

	var aggregate Stats
	for batch := 0; batch < r.config.MaxBatchesPerRun; batch++ {
		stats, err := r.Tick(ctx)
		aggregate.add(stats)
		if err != nil {
			return aggregate, err
		}
		if !stats.HasMore {
			return aggregate, nil
		}
	}
	aggregate.Capped = aggregate.HasMore
	return aggregate, nil
}

func classifyTaskError(operation string, err error) error {
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}
	var maintenanceError *Error
	if errors.As(err, &maintenanceError) {
		return err
	}
	return NewError(operation, ErrorKindUnavailable, true, fmt.Errorf("repository: %w", err))
}
