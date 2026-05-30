package port

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/trust-service/internal/domain/model"
)

var ErrNotFound = errors.New("not found")

type TrustRepository interface {
	GetTrustProfile(ctx context.Context, userID uuid.UUID) (model.TrustProfile, error)
	UpsertTrustProfile(ctx context.Context, profile model.TrustProfile) error
	ListActiveRestrictions(ctx context.Context, userID uuid.UUID, now time.Time) ([]model.RuntimeRestriction, error)
	SavePolicyDecision(ctx context.Context, decision model.PolicyDecisionRecord) error
	HasProcessedEvent(ctx context.Context, eventID uuid.UUID) (bool, error)
	MarkProcessedEvent(ctx context.Context, eventID uuid.UUID, eventType string, occurredAt time.Time) error
	UpsertRuntimeRestriction(ctx context.Context, restriction model.RuntimeRestriction) error
	LiftRuntimeRestriction(ctx context.Context, restrictionID uuid.UUID, eventID uuid.UUID, liftedBy *uuid.UUID, liftedAt time.Time, reasonCode string) error
}
