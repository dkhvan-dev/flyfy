package savedoutbox

import "errors"

var (
	ErrInvalidConfig         = errors.New("invalid saved outbox dispatcher configuration")
	ErrInvalidDependencies   = errors.New("invalid saved outbox dependencies")
	ErrInvalidClock          = errors.New("invalid saved outbox clock")
	ErrInvalidRecord         = errors.New("invalid saved outbox record")
	ErrInvalidRequest        = errors.New("invalid saved outbox repository request")
	ErrPersistenceInvariant  = errors.New("saved outbox persistence invariant violated")
	ErrRepositoryUnavailable = errors.New("saved outbox repository unavailable")
	ErrLeaseLost             = errors.New("saved outbox lease lost")
)
