package savedsearchmigration

import (
	"context"
	"errors"
	"testing"
	"time"
)

func TestBackfillIsBoundedAndResumable(t *testing.T) {
	t.Parallel()
	store := &fakeStore{batches: []int64{2, 2, 1}, status: readyExpandedStatus(true)}
	service, err := NewService(store, Config{BatchSize: 2, MaxBatches: 2})
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}

	first, err := service.Backfill(context.Background())
	if err != nil {
		t.Fatalf("first Backfill() error = %v", err)
	}
	if first.Batches != 2 || first.Rows != 4 || first.Complete {
		t.Fatalf("first Backfill() = %+v", first)
	}

	store.status.Pending = false
	second, err := service.Backfill(context.Background())
	if err != nil {
		t.Fatalf("second Backfill() error = %v", err)
	}
	if second.Batches != 2 || second.Rows != 1 || !second.Complete {
		t.Fatalf("second Backfill() = %+v", second)
	}
	if store.calls != 4 {
		t.Fatalf("BackfillBatch() calls = %d, want 4", store.calls)
	}
}

func TestBackfillFailsClosedWithoutTemporaryIndex(t *testing.T) {
	t.Parallel()
	store := &fakeStore{status: readyExpandedStatus(true)}
	store.status.BackfillIndexPresent = false
	store.status.BackfillIndexReady = false
	service, err := NewService(store, Config{BatchSize: 10, MaxBatches: 1})
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	result, err := service.Backfill(context.Background())
	if !errors.Is(err, ErrBackfillPrerequisite) {
		t.Fatalf("Backfill() error = %v, want %v", err, ErrBackfillPrerequisite)
	}
	if result.Status.BackfillIndexPresent || store.calls != 0 {
		t.Fatalf("Backfill() result = %+v, calls = %d", result, store.calls)
	}
}

func TestContractFailsClosedUntilBackfillAndIndexesAreReady(t *testing.T) {
	t.Parallel()
	store := &fakeStore{status: readyExpandedStatus(true)}
	store.status.OwnerIndexReady = false
	service, err := NewService(store, Config{BatchSize: 10, MaxBatches: 1})
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}

	if _, err := service.Contract(context.Background()); !errors.Is(err, ErrContractPrerequisite) {
		t.Fatalf("Contract() error = %v, want %v", err, ErrContractPrerequisite)
	}
	store.status.OwnerIndexReady = true
	if _, err := service.Contract(context.Background()); !errors.Is(err, ErrBackfillIncomplete) {
		t.Fatalf("Contract() error = %v, want %v", err, ErrBackfillIncomplete)
	}
	store.status.Pending = false
	store.validate = func() {
		store.status.ParityConstraintValidated = true
		store.status.BackfillIndexPresent = false
		store.status.BackfillIndexReady = false
	}
	status, err := service.Contract(context.Background())
	if err != nil {
		t.Fatalf("Contract() error = %v", err)
	}
	if !status.Ready() || store.validations != 1 {
		t.Fatalf("Contract() status = %+v, validations = %d", status, store.validations)
	}
}

func TestContractIsIdempotentAfterTemporaryIndexWasDropped(t *testing.T) {
	t.Parallel()
	store := &fakeStore{status: readyExpandedStatus(false)}
	store.status.ParityConstraintValidated = true
	store.status.BackfillIndexPresent = false
	store.status.BackfillIndexReady = false
	service, err := NewService(store, Config{BatchSize: 10, MaxBatches: 1})
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	status, err := service.Contract(context.Background())
	if err != nil {
		t.Fatalf("Contract() error = %v", err)
	}
	if !status.Ready() || store.validations != 0 {
		t.Fatalf("Contract() status = %+v, validations = %d", status, store.validations)
	}
}

func TestRolloutBackfillsAndContractsExpandedSchema(t *testing.T) {
	t.Parallel()
	store := &fakeStore{
		batches:            []int64{2, 0},
		status:             readyExpandedStatus(true),
		completeAfterCalls: 2,
	}
	store.validate = func() {
		store.status.ParityConstraintValidated = true
		store.status.BackfillIndexPresent = false
		store.status.BackfillIndexReady = false
	}
	service, err := NewService(store, Config{BatchSize: 2, MaxBatches: 3})
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}

	result, err := service.Rollout(context.Background())
	if err != nil {
		t.Fatalf("Rollout() error = %v", err)
	}
	if !result.Ready || result.Backfill == nil || !result.Backfill.Complete ||
		result.Backfill.Rows != 2 || store.validations != 1 {
		t.Fatalf("Rollout() result = %+v, validations = %d", result, store.validations)
	}
}

func TestRolloutIsIdempotentAfterContract(t *testing.T) {
	t.Parallel()
	store := &fakeStore{status: readyExpandedStatus(false)}
	store.status.ParityConstraintValidated = true
	store.status.BackfillIndexPresent = false
	store.status.BackfillIndexReady = false
	service, err := NewService(store, Config{BatchSize: 10, MaxBatches: 1})
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}

	result, err := service.Rollout(context.Background())
	if err != nil {
		t.Fatalf("Rollout() error = %v", err)
	}
	if !result.Ready || result.Backfill != nil || store.calls != 0 || store.validations != 0 {
		t.Fatalf("Rollout() result = %+v, calls = %d, validations = %d", result, store.calls, store.validations)
	}
}

func TestRolloutFailsClosedWhenBoundedBackfillIsIncomplete(t *testing.T) {
	t.Parallel()
	store := &fakeStore{batches: []int64{2}, status: readyExpandedStatus(true)}
	service, err := NewService(store, Config{BatchSize: 2, MaxBatches: 1})
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}

	result, err := service.Rollout(context.Background())
	if !errors.Is(err, ErrBackfillIncomplete) {
		t.Fatalf("Rollout() error = %v, want %v", err, ErrBackfillIncomplete)
	}
	if result.Ready || result.Backfill == nil || result.Backfill.Complete || store.validations != 0 {
		t.Fatalf("Rollout() result = %+v, validations = %d", result, store.validations)
	}
}

func TestBackfillHonorsCancellationDuringPause(t *testing.T) {
	t.Parallel()
	store := &fakeStore{batches: []int64{1, 1}, status: readyExpandedStatus(true)}
	service, err := NewService(store, Config{BatchSize: 1, MaxBatches: 2, Pause: time.Second})
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := service.Backfill(ctx); !errors.Is(err, context.Canceled) {
		t.Fatalf("Backfill() error = %v, want cancellation", err)
	}
}

func TestConfigRejectsUnboundedValues(t *testing.T) {
	t.Parallel()
	for _, config := range []Config{
		{BatchSize: 0, MaxBatches: 1},
		{BatchSize: MaxBatchSize + 1, MaxBatches: 1},
		{BatchSize: 1, MaxBatches: 0},
		{BatchSize: 1, MaxBatches: MaxRunBatches + 1},
		{BatchSize: 1, MaxBatches: 1, Pause: MaxBatchPause + time.Nanosecond},
	} {
		if _, err := NewService(&fakeStore{}, config); !errors.Is(err, ErrInvalidConfig) {
			t.Fatalf("NewService(%+v) error = %v", config, err)
		}
	}
}

func readyExpandedStatus(pending bool) Status {
	return Status{
		ColumnsReady:            true,
		TriggerReady:            true,
		ParityConstraintPresent: true,
		OwnerIndexReady:         true,
		ProjectionIndexReady:    true,
		BackfillIndexPresent:    true,
		BackfillIndexReady:      true,
		Pending:                 pending,
	}
}

type fakeStore struct {
	batches            []int64
	status             Status
	calls              int
	completeAfterCalls int
	validations        int
	validate           func()
}

func (f *fakeStore) BackfillBatch(context.Context, int) (int64, error) {
	f.calls++
	if f.completeAfterCalls > 0 && f.calls >= f.completeAfterCalls {
		f.status.Pending = false
	}
	if len(f.batches) == 0 {
		return 0, nil
	}
	rows := f.batches[0]
	f.batches = f.batches[1:]
	return rows, nil
}

func (f *fakeStore) Status(context.Context) (Status, error) {
	return f.status, nil
}

func (f *fakeStore) ValidateContract(context.Context) error {
	f.validations++
	if f.validate != nil {
		f.validate()
	}
	return nil
}
