package session

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

// Validator is the narrow application port used immediately before a Saved
// write is committed. Implementations must fail closed when validity cannot be
// established authoritatively.
type Validator interface {
	Validate(ctx context.Context, subject, sessionGeneration string) (bool, error)
}

var (
	// Input errors intentionally contain no rejected value.
	ErrInvalidSubject           = errors.New("invalid session subject")
	ErrInvalidSessionGeneration = errors.New("invalid session generation")

	// Dependency failures reuse Saved's stable, externally safe classification.
	ErrDependencyUnavailable = domain.ErrDependencyUnavailable
	ErrContractViolation     = fmt.Errorf("session validation contract violation: %w", ErrDependencyUnavailable)
)

// ValidateInput accepts only canonical, lowercase, hyphenated, non-zero UUIDs.
// It is shared by adapters so malformed trusted-header data never reaches the
// token service.
func ValidateInput(subject, sessionGeneration string) error {
	if !isCanonicalNonZeroUUID(subject) {
		return ErrInvalidSubject
	}
	if !isCanonicalNonZeroUUID(sessionGeneration) {
		return ErrInvalidSessionGeneration
	}
	return nil
}

func isCanonicalNonZeroUUID(raw string) bool {
	parsed, err := uuid.Parse(raw)
	return err == nil && parsed != uuid.Nil && parsed.String() == raw
}
