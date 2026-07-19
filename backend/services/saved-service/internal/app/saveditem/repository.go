package saveditem

import (
	"context"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

// Repository owns the final mutation transaction. Eligibility resolution and
// operation creation happen before this boundary; no request payload is stored.
type Repository interface {
	PrepareProjectionShell(context.Context, PrepareProjectionShellCommand) (*domain.SavedOperation, error)
	Save(context.Context, SaveCommand) (*domain.SavedOperation, error)
	GlobalUnsave(context.Context, GlobalUnsaveCommand) (*domain.SavedOperation, error)
	RejectPending(context.Context, RejectPendingCommand) (*domain.SavedOperation, error)
	GetOperation(context.Context, OperationLookup) (*domain.SavedOperation, error)
}
