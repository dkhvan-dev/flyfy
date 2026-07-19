package savedaccess

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const MaxUserTargets = 200

var (
	ErrInvalidRequest    = errors.New("invalid Saved user access request")
	ErrPolicyUnavailable = errors.New("Saved user access policy unavailable")
)

// Policy returns the candidate users that deny access to the owner. It never
// returns profile data or a user-facing reason for denial.
type Policy interface {
	DeniedUserIDs(
		context.Context,
		uuid.UUID,
		[]uuid.UUID,
	) (map[uuid.UUID]struct{}, error)
}

// DeniedTargets applies Saved-owned invariants and delegates only foreign USER
// targets to the relationship policy. Saving one's own profile is always
// denied locally and does not require a dependency call.
func DeniedTargets(
	ctx context.Context,
	policy Policy,
	ownerUserID uuid.UUID,
	targets []domain.SavedTarget,
) (map[domain.SavedTarget]struct{}, error) {
	if ctx == nil || ownerUserID == uuid.Nil || len(targets) > MaxUserTargets {
		return nil, ErrInvalidRequest
	}
	denied := make(map[domain.SavedTarget]struct{})
	userTargetByID := make(map[uuid.UUID]domain.SavedTarget)
	userIDs := make([]uuid.UUID, 0, len(targets))
	seenTargets := make(map[domain.SavedTarget]struct{}, len(targets))
	for _, target := range targets {
		if target.IsZero() {
			return nil, ErrInvalidRequest
		}
		if _, duplicate := seenTargets[target]; duplicate {
			continue
		}
		seenTargets[target] = struct{}{}
		if target.EntityType() != domain.EntityTypeUser {
			continue
		}
		userID, err := uuid.Parse(target.EntityID())
		if err != nil || userID == uuid.Nil || userID.String() != target.EntityID() {
			return nil, ErrInvalidRequest
		}
		if userID == ownerUserID {
			denied[target] = struct{}{}
			continue
		}
		if _, duplicate := userTargetByID[userID]; duplicate {
			continue
		}
		userTargetByID[userID] = target
		userIDs = append(userIDs, userID)
	}
	if len(userIDs) == 0 {
		return denied, nil
	}
	if err := ctx.Err(); err != nil {
		return denied, err
	}
	if policy == nil {
		return denied, ErrPolicyUnavailable
	}

	deniedUserIDs, err := policy.DeniedUserIDs(ctx, ownerUserID, userIDs)
	if err != nil {
		if ctxErr := ctx.Err(); ctxErr != nil {
			return denied, ctxErr
		}
		return denied, ErrPolicyUnavailable
	}
	for deniedUserID := range deniedUserIDs {
		target, expected := userTargetByID[deniedUserID]
		if !expected {
			return denied, ErrPolicyUnavailable
		}
		denied[target] = struct{}{}
	}
	return denied, nil
}

func FailClosedUserTargets(
	targets []domain.SavedTarget,
	denied map[domain.SavedTarget]struct{},
) map[domain.SavedTarget]struct{} {
	if denied == nil {
		denied = make(map[domain.SavedTarget]struct{})
	}
	for _, target := range targets {
		if target.EntityType() == domain.EntityTypeUser {
			denied[target] = struct{}{}
		}
	}
	return denied
}

// ExpansionCause converts relationship-policy outcomes into the intentionally
// neutral Saved mutation contract. A denied target is indistinguishable from
// any other unavailable target; a dependency failure never permits expansion.
func ExpansionCause(
	ctx context.Context,
	policy Policy,
	ownerUserID uuid.UUID,
	target domain.SavedTarget,
) *domain.DomainError {
	denied, err := DeniedTargets(ctx, policy, ownerUserID, []domain.SavedTarget{target})
	if err != nil {
		if errors.Is(err, ErrInvalidRequest) {
			return domain.ErrTargetUnavailable
		}
		return domain.ErrDependencyUnavailable
	}
	if _, unavailable := denied[target]; unavailable {
		return domain.ErrTargetUnavailable
	}
	return nil
}

// DeniedTargetsFailClosed preserves read availability for non-USER Saved
// items while scrubbing every USER target whenever the relationship policy is
// unavailable. Cancellation is still returned to the caller.
func DeniedTargetsFailClosed(
	ctx context.Context,
	policy Policy,
	ownerUserID uuid.UUID,
	targets []domain.SavedTarget,
) (map[domain.SavedTarget]struct{}, error) {
	denied, err := DeniedTargets(ctx, policy, ownerUserID, targets)
	if err == nil {
		return denied, nil
	}
	if ctx != nil && ctx.Err() != nil {
		return nil, ctx.Err()
	}
	return FailClosedUserTargets(targets, denied), nil
}
