package policy

import (
	"context"
	"errors"

	"kz/inflap/backend/pkg/platformpolicy"
	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

var ErrInvalidPolicyGate = errors.New("invalid Saved policy gate configuration")

type checker interface {
	Guard(context.Context) (platformpolicy.Grant, error)
	ValidateCommit(context.Context, uint64) (platformpolicy.Grant, error)
}

type Gate struct {
	checker checker
}

var _ saveditem.PolicyGate = (*Gate)(nil)

func NewGate(policyChecker checker) (*Gate, error) {
	if policyChecker == nil {
		return nil, ErrInvalidPolicyGate
	}
	return &Gate{checker: policyChecker}, nil
}

func (gate *Gate) Guard(ctx context.Context) (saveditem.PolicyGrant, error) {
	if ctx == nil || gate == nil || gate.checker == nil {
		return saveditem.PolicyGrant{}, domain.ErrDependencyUnavailable
	}
	grant, err := gate.checker.Guard(ctx)
	if err != nil {
		return saveditem.PolicyGrant{}, mapPolicyError(err)
	}
	if grant.Revision == 0 {
		return saveditem.PolicyGrant{}, domain.ErrDependencyUnavailable
	}
	return saveditem.PolicyGrant{Revision: grant.Revision}, nil
}

func (gate *Gate) ValidateCommit(ctx context.Context, minimumRevision uint64) error {
	if ctx == nil || gate == nil || gate.checker == nil || minimumRevision == 0 {
		return domain.ErrDependencyUnavailable
	}
	grant, err := gate.checker.ValidateCommit(ctx, minimumRevision)
	if err != nil {
		return mapPolicyError(err)
	}
	if grant.Revision < minimumRevision {
		return domain.ErrDependencyUnavailable
	}
	return nil
}

func mapPolicyError(err error) *domain.DomainError {
	reason, ok := platformpolicy.DenialReason(err)
	if ok && reason == platformpolicy.ReasonLocked {
		return domain.ErrPlatformPersonalDataLocked
	}
	return domain.ErrDependencyUnavailable
}

func (*Gate) String() string {
	return "PolicyGate{checker=redacted}"
}

func (gate *Gate) GoString() string {
	return gate.String()
}
