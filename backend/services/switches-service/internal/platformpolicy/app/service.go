package app

import (
	"context"
	"errors"
	"fmt"
	"time"
)

type Service struct {
	repository Repository
	clock      Clock
}

func NewService(repository Repository, clock Clock) *Service {
	if clock == nil {
		clock = systemClock{}
	}
	return &Service{repository: repository, clock: clock}
}

// ReadDecision always consults the authoritative repository. The service has
// deliberately no in-memory allow cache.
func (service *Service) ReadDecision(ctx context.Context) (Decision, error) {
	if service == nil || service.repository == nil || service.clock == nil {
		return Decision{}, ErrUnavailable
	}
	decision, err := service.repository.ReadDecision(ctx)
	if err != nil {
		return Decision{}, unavailable(err)
	}
	decision = normalizeDecision(decision)
	if err = validateDecision(decision, service.clock.Now()); err != nil {
		return Decision{}, unavailable(err)
	}
	return decision, nil
}

func (service *Service) ChangeState(ctx context.Context, command ChangeCommand) (Decision, error) {
	if service == nil || service.repository == nil || service.clock == nil {
		return Decision{}, ErrUnavailable
	}
	command = command.normalized()
	if !command.valid() {
		return Decision{}, ErrInvalidCommand
	}

	decision, err := service.repository.ChangeState(ctx, command)
	if err != nil {
		if errors.Is(err, ErrRevisionConflict) || errors.Is(err, ErrStateUnchanged) {
			return Decision{}, err
		}
		return Decision{}, unavailable(err)
	}
	decision = normalizeDecision(decision)
	if err = validateDecision(decision, service.clock.Now()); err != nil {
		return Decision{}, unavailable(err)
	}
	return decision, nil
}

func normalizeDecision(decision Decision) Decision {
	decision.IssuedAt = decision.IssuedAt.UTC()
	decision.ValidUntil = decision.ValidUntil.UTC()
	return decision
}

func validateDecision(decision Decision, now time.Time) error {
	if decision.Revision == 0 || !decision.State.Valid() || decision.IssuedAt.IsZero() || decision.ValidUntil.IsZero() {
		return errors.New("invalid policy decision shape")
	}
	window := decision.ValidUntil.Sub(decision.IssuedAt)
	if window <= 0 || window > MaxValidityWindow {
		return errors.New("invalid policy decision validity window")
	}
	if decision.IssuedAt.After(now.Add(MaxClockSkew)) {
		return errors.New("policy decision was issued in the future")
	}
	if !now.Before(decision.ValidUntil) {
		return errors.New("policy decision is expired")
	}
	return nil
}

func unavailable(cause error) error {
	if cause == nil {
		return ErrUnavailable
	}
	return fmt.Errorf("%w: %v", ErrUnavailable, cause)
}
