package savedmaintenance

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var ErrInvalidBatch = errors.New("invalid saved maintenance batch")

// BatchRequest carries one immutable cutoff to every transaction in a tick.
type BatchRequest struct {
	Now                 time.Time
	Limit               int
	OperationRetention  time.Duration
	ProjectionRetention time.Duration
}

func (r BatchRequest) Validate() error {
	if r.Now.IsZero() || r.Limit < 1 || r.Limit > maxBatchSize ||
		r.OperationRetention != DefaultOperationRetention ||
		r.ProjectionRetention < minimumRetentionAge {
		return ErrInvalidBatch
	}
	return nil
}

type BatchResult struct {
	Affected int64
	HasMore  bool
}

func (r BatchResult) Validate(limit int) error {
	if limit < 1 || r.Affected < 0 || r.Affected > int64(limit) {
		return fmt.Errorf("%w: invalid batch result", ErrInvalidBatch)
	}
	return nil
}

// Repository owns short, independent transactions. Implementations must use
// bounded candidate selection and may not start workers or retain cursors.
type Repository interface {
	SubjectPurgeRepository

	ExpirePendingOperations(context.Context, BatchRequest) (BatchResult, error)
	PurgeTerminalOperations(context.Context, BatchRequest) (BatchResult, error)
	PurgeTerminalOutbox(context.Context, BatchRequest) (BatchResult, error)
	PurgeInboxDedup(context.Context, BatchRequest) (BatchResult, error)
	CleanupDeletedCollectionChildren(context.Context, BatchRequest) (BatchResult, error)
	PurgeRemovedCollectionItems(context.Context, BatchRequest) (BatchResult, error)
	PurgeDeletedCollections(context.Context, BatchRequest) (BatchResult, error)
	PurgeRemovedSavedItems(context.Context, BatchRequest) (BatchResult, error)
	MarkProjectionGCCandidates(context.Context, BatchRequest) (BatchResult, error)
	PurgeEphemeralProjections(context.Context, BatchRequest) (BatchResult, error)
	PurgeStandardProjections(context.Context, BatchRequest) (BatchResult, error)
	PurgeCompletedSubjectPurges(context.Context, BatchRequest) (BatchResult, error)
}
