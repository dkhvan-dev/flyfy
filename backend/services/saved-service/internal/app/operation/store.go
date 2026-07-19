package operation

import (
	"context"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

// CreateOrFindResult is the result of one atomic identity check and insert.
type CreateOrFindResult struct {
	Receipt *domain.SavedOperation
	Created bool
}

// OperationStore atomically creates a PENDING receipt or returns a receipt
// found by either scoped identity. Both operation ID and idempotency key are
// scoped by subject and session generation. If the two identities collide with
// different receipts, the store returns either existing receipt with Created
// false; the application rejects the binding as a replay mismatch.
type OperationStore interface {
	CreateOrFind(ctx context.Context, pending *domain.SavedOperation) (CreateOrFindResult, error)
}
