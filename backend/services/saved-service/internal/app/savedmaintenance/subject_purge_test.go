package savedmaintenance

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestSubjectPurgeRequiresWriteFenceAndStartsIdempotently(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	repository := newFakeMaintenanceRepository()
	runner, err := NewRunner(repository, DefaultConfig(), func() time.Time { return now })
	if err != nil {
		t.Fatalf("NewRunner() error = %v", err)
	}
	start := SubjectPurgeStart{
		OperationID: uuid.New(),
		Subject:     uuid.NewString(),
		OwnerUserID: uuid.New(),
	}
	if _, err := runner.SubjectPurge(context.Background(), start.OperationID); !errors.Is(err, ErrSubjectPurgeNotFound) ||
		IsRetryable(err) {
		t.Fatalf("SubjectPurge(missing) error = %v", err)
	}
	if _, err := runner.StartSubjectPurge(context.Background(), start); !errors.Is(err, ErrInvalidSubjectPurge) {
		t.Fatalf("StartSubjectPurge(unfenced) error = %v", err)
	}

	start.WritesFenced = true
	first, err := runner.StartSubjectPurge(context.Background(), start)
	if err != nil {
		t.Fatalf("StartSubjectPurge() error = %v", err)
	}
	second, err := runner.StartSubjectPurge(context.Background(), start)
	if err != nil {
		t.Fatalf("StartSubjectPurge(retry) error = %v", err)
	}
	if first.OperationID != second.OperationID || first.Phase != SubjectPurgePhaseOutbox {
		t.Fatalf("idempotent jobs = (%+v, %+v)", first, second)
	}
}

func TestRunSubjectPurgeOnceResumesAndCompletes(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	operationID := uuid.New()
	repository := newFakeMaintenanceRepository()
	repository.subjectResults = []SubjectPurgeBatchResult{
		{
			Found:       true,
			OperationID: operationID,
			PhaseBefore: SubjectPurgePhaseOutbox,
			PhaseAfter:  SubjectPurgePhaseOutbox,
			RowsPurged:  2,
			HasMore:     true,
		},
		{
			Found:         true,
			OperationID:   operationID,
			PhaseBefore:   SubjectPurgePhaseOutbox,
			PhaseAfter:    SubjectPurgePhaseCollectionItems,
			RowsPurged:    1,
			PhaseAdvanced: true,
			HasMore:       true,
		},
		{
			Found:         true,
			OperationID:   operationID,
			PhaseBefore:   SubjectPurgePhaseUserUsage,
			PhaseAfter:    SubjectPurgePhaseCompleted,
			PhaseAdvanced: true,
			Completed:     true,
		},
	}
	config := DefaultConfig()
	config.BatchSize = 2
	config.MaxBatchesPerRun = 4
	runner, err := NewRunner(repository, config, func() time.Time { return now })
	if err != nil {
		t.Fatalf("NewRunner() error = %v", err)
	}

	stats, err := runner.RunSubjectPurgeOnce(context.Background(), operationID)
	if err != nil {
		t.Fatalf("RunSubjectPurgeOnce() error = %v", err)
	}
	if stats.Ticks != 3 || stats.RowsPurged != 3 || stats.PhasesAdvanced != 2 || !stats.Completed || stats.Capped {
		t.Fatalf("RunSubjectPurgeOnce() stats = %+v", stats)
	}
}
