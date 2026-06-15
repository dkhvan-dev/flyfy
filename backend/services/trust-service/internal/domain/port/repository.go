package port

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/trust-service/internal/domain/model"
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
	GetRuntimeRestrictionByID(ctx context.Context, restrictionID uuid.UUID) (model.RuntimeRestriction, error)
	LiftRuntimeRestriction(ctx context.Context, restrictionID uuid.UUID, eventID uuid.UUID, liftedBy *uuid.UUID, liftedAt time.Time, reasonCode string) error
	CreateRestrictionAppeal(ctx context.Context, appeal model.RestrictionAppeal) (model.RestrictionAppeal, error)
	GetRestrictionAppeal(ctx context.Context, appealID uuid.UUID) (model.RestrictionAppeal, error)
	ListRestrictionAppeals(ctx context.Context, input model.ListRestrictionAppealsInput) ([]model.RestrictionAppeal, error)
	SaveRestrictionAppealDecision(ctx context.Context, appeal model.RestrictionAppeal) (model.RestrictionAppeal, error)
}
