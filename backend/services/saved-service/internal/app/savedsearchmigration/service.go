package savedsearchmigration

import (
	"context"
	"errors"
	"fmt"
	"time"
)

const (
	MaxBatchSize  = 1_000
	MaxRunBatches = 10_000
	MaxBatchPause = time.Second
)

var (
	ErrInvalidConfig        = errors.New("invalid saved search migration config")
	ErrBackfillPrerequisite = errors.New("saved search backfill prerequisites are not ready")
	ErrBackfillIncomplete   = errors.New("saved search backfill is incomplete")
	ErrContractPrerequisite = errors.New("saved search contract prerequisites are not ready")
	ErrContractNotReady     = errors.New("saved search contract is not ready")
)

type Store interface {
	BackfillBatch(ctx context.Context, batchSize int) (int64, error)
	Status(ctx context.Context) (Status, error)
	ValidateContract(ctx context.Context) error
}

type Status struct {
	ColumnsReady              bool `json:"columns_ready"`
	TriggerReady              bool `json:"trigger_ready"`
	ParityConstraintPresent   bool `json:"parity_constraint_present"`
	ParityConstraintValidated bool `json:"parity_constraint_validated"`
	OwnerIndexReady           bool `json:"owner_index_ready"`
	ProjectionIndexReady      bool `json:"projection_index_ready"`
	BackfillIndexPresent      bool `json:"backfill_index_present"`
	BackfillIndexReady        bool `json:"backfill_index_ready"`
	Pending                   bool `json:"pending"`
}

func (s Status) Expanded() bool {
	return s.ColumnsReady && s.TriggerReady && s.ParityConstraintPresent
}

func (s Status) ContractPrerequisitesReady() bool {
	return s.Expanded() && s.OwnerIndexReady && s.ProjectionIndexReady && s.BackfillIndexReady
}

func (s Status) Ready() bool {
	return s.Expanded() && s.OwnerIndexReady && s.ProjectionIndexReady &&
		s.ParityConstraintValidated && !s.BackfillIndexPresent && !s.Pending
}

type Config struct {
	BatchSize  int
	MaxBatches int
	Pause      time.Duration
}

func (c Config) Validate() error {
	if c.BatchSize < 1 || c.BatchSize > MaxBatchSize {
		return fmt.Errorf("%w: batch size must be between 1 and %d", ErrInvalidConfig, MaxBatchSize)
	}
	if c.MaxBatches < 1 || c.MaxBatches > MaxRunBatches {
		return fmt.Errorf("%w: max batches must be between 1 and %d", ErrInvalidConfig, MaxRunBatches)
	}
	if c.Pause < 0 || c.Pause > MaxBatchPause {
		return fmt.Errorf("%w: pause must be between 0 and %s", ErrInvalidConfig, MaxBatchPause)
	}
	return nil
}

type BackfillResult struct {
	Batches  int    `json:"batches"`
	Rows     int64  `json:"rows"`
	Complete bool   `json:"complete"`
	Status   Status `json:"status"`
}

type RolloutResult struct {
	Ready    bool            `json:"ready"`
	Backfill *BackfillResult `json:"backfill,omitempty"`
	Status   Status          `json:"status"`
}

type Service struct {
	store  Store
	config Config
}

func NewService(store Store, config Config) (*Service, error) {
	if store == nil {
		return nil, fmt.Errorf("%w: store is required", ErrInvalidConfig)
	}
	if err := config.Validate(); err != nil {
		return nil, err
	}
	return &Service{store: store, config: config}, nil
}

func (s *Service) Backfill(ctx context.Context) (BackfillResult, error) {
	if ctx == nil || s == nil || s.store == nil {
		return BackfillResult{}, fmt.Errorf("%w: service is unavailable", ErrInvalidConfig)
	}
	initial, err := s.store.Status(ctx)
	if err != nil {
		return BackfillResult{}, fmt.Errorf("inspect saved search backfill prerequisites: %w", err)
	}
	result := BackfillResult{Status: initial}
	if !initial.Expanded() || !initial.BackfillIndexReady {
		return result, ErrBackfillPrerequisite
	}
	for batch := 0; batch < s.config.MaxBatches; batch++ {
		rows, err := s.store.BackfillBatch(ctx, s.config.BatchSize)
		if err != nil {
			return result, fmt.Errorf("backfill saved search batch %d: %w", batch+1, err)
		}
		result.Batches++
		result.Rows += rows
		if rows == 0 {
			break
		}
		if s.config.Pause > 0 && batch+1 < s.config.MaxBatches {
			if err := wait(ctx, s.config.Pause); err != nil {
				return result, err
			}
		}
	}

	status, err := s.store.Status(ctx)
	if err != nil {
		return result, fmt.Errorf("inspect saved search backfill: %w", err)
	}
	result.Status = status
	result.Complete = status.Expanded() && status.BackfillIndexReady && !status.Pending
	return result, nil
}

func (s *Service) Contract(ctx context.Context) (Status, error) {
	if ctx == nil || s == nil || s.store == nil {
		return Status{}, fmt.Errorf("%w: service is unavailable", ErrInvalidConfig)
	}
	status, err := s.store.Status(ctx)
	if err != nil {
		return Status{}, fmt.Errorf("inspect saved search contract: %w", err)
	}
	if status.Ready() {
		return status, nil
	}
	if !status.ContractPrerequisitesReady() {
		return status, ErrContractPrerequisite
	}
	if status.Pending {
		return status, ErrBackfillIncomplete
	}
	if err := s.store.ValidateContract(ctx); err != nil {
		return status, fmt.Errorf("validate saved search contract: %w", err)
	}
	status, err = s.store.Status(ctx)
	if err != nil {
		return Status{}, fmt.Errorf("verify saved search contract: %w", err)
	}
	if !status.Ready() {
		return status, ErrContractNotReady
	}
	return status, nil
}

// Rollout idempotently advances an expanded search schema through bounded
// backfill and contract validation. A capped backfill fails closed so a
// deployment cannot expose search against a partially prepared database.
func (s *Service) Rollout(ctx context.Context) (RolloutResult, error) {
	status, err := s.Status(ctx)
	if err != nil {
		return RolloutResult{}, fmt.Errorf("inspect saved search rollout: %w", err)
	}
	result := RolloutResult{Ready: status.Ready(), Status: status}
	if result.Ready {
		return result, nil
	}

	backfill, err := s.Backfill(ctx)
	result.Backfill = &backfill
	result.Status = backfill.Status
	if err != nil {
		return result, fmt.Errorf("run saved search rollout backfill: %w", err)
	}
	if !backfill.Complete {
		return result, ErrBackfillIncomplete
	}

	status, err = s.Contract(ctx)
	result.Status = status
	result.Ready = status.Ready()
	if err != nil {
		return result, fmt.Errorf("run saved search rollout contract: %w", err)
	}
	if !result.Ready {
		return result, ErrContractNotReady
	}
	return result, nil
}

func (s *Service) Status(ctx context.Context) (Status, error) {
	if ctx == nil || s == nil || s.store == nil {
		return Status{}, fmt.Errorf("%w: service is unavailable", ErrInvalidConfig)
	}
	return s.store.Status(ctx)
}

func wait(ctx context.Context, duration time.Duration) error {
	timer := time.NewTimer(duration)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-timer.C:
		return nil
	}
}
