package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/trust-service/internal/domain/model"
	"kz/inflap/backend/services/trust-service/internal/domain/port"
)

func TestCheckActionPolicyAllowsNormalUserWithoutRestriction(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	now := time.Date(2026, 5, 30, 9, 0, 0, 0, time.UTC)
	repo := newTrustRepoFake()
	repo.profiles[userID] = model.TrustProfile{
		UserID:       userID,
		Score:        720,
		Band:         model.TrustBandNormal,
		Status:       model.TrustStatusActive,
		CalculatedAt: now.Add(-time.Hour),
		CreatedAt:    now.Add(-time.Hour),
		UpdatedAt:    now.Add(-time.Hour),
	}
	usecase := NewPolicyUseCase(repo)

	decision, err := usecase.CheckActionPolicy(ctx, model.PolicyCheckInput{
		UserID:      userID,
		Action:      model.PolicyActionActivityCreate,
		ResourceID:  uuid.NewString(),
		RequestedAt: now,
	})

	if err != nil {
		t.Fatalf("CheckActionPolicy returned error: %v", err)
	}
	if decision.Decision != model.PolicyDecisionAllow {
		t.Fatalf("expected ALLOW decision, got %q", decision.Decision)
	}
	if decision.Score != 720 || decision.TrustBand != model.TrustBandNormal {
		t.Fatalf("expected normal profile copied into decision, got score=%d band=%q", decision.Score, decision.TrustBand)
	}
	if len(repo.decisions) != 1 {
		t.Fatalf("expected one saved decision, got %d", len(repo.decisions))
	}
}

func TestCheckActionPolicyDeniesMatchingActiveRestriction(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	restrictionID := uuid.New()
	now := time.Date(2026, 5, 30, 9, 10, 0, 0, time.UTC)
	repo := newTrustRepoFake()
	repo.profiles[userID] = model.TrustProfile{
		UserID:       userID,
		Score:        640,
		Band:         model.TrustBandNormal,
		Status:       model.TrustStatusActive,
		CalculatedAt: now,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	repo.restrictions[userID] = []model.RuntimeRestriction{
		{
			ID:              restrictionID,
			UserID:          userID,
			RestrictionCode: model.RestrictionCodeActivityCreation,
			Status:          model.RuntimeRestrictionActive,
			ReasonCode:      "manual_review_required",
			SourceEventID:   uuid.New(),
			CreatedAt:       now.Add(-time.Minute),
		},
	}
	usecase := NewPolicyUseCase(repo)

	decision, err := usecase.CheckActionPolicy(ctx, model.PolicyCheckInput{
		UserID:      userID,
		Action:      model.PolicyActionActivityCreate,
		ResourceID:  uuid.NewString(),
		RequestedAt: now,
	})

	if err != nil {
		t.Fatalf("CheckActionPolicy returned error: %v", err)
	}
	if decision.Decision != model.PolicyDecisionDeny {
		t.Fatalf("expected DENY decision, got %q", decision.Decision)
	}
	if decision.ReasonCode != "manual_review_required" {
		t.Fatalf("expected restriction reason code, got %q", decision.ReasonCode)
	}
	if len(decision.RestrictionIDs) != 1 || decision.RestrictionIDs[0] != restrictionID {
		t.Fatalf("expected matching restriction id, got %#v", decision.RestrictionIDs)
	}
}

func TestCheckActionPolicyQuarantinesFileUploadForRiskyBand(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	now := time.Date(2026, 5, 30, 9, 20, 0, 0, time.UTC)
	repo := newTrustRepoFake()
	repo.profiles[userID] = model.TrustProfile{
		UserID:       userID,
		Score:        180,
		Band:         model.TrustBandRisky,
		Status:       model.TrustStatusUnderReview,
		CalculatedAt: now,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	usecase := NewPolicyUseCase(repo)

	decision, err := usecase.CheckActionPolicy(ctx, model.PolicyCheckInput{
		UserID:      userID,
		Action:      model.PolicyActionFileUpload,
		ResourceID:  uuid.NewString(),
		RequestedAt: now,
	})

	if err != nil {
		t.Fatalf("CheckActionPolicy returned error: %v", err)
	}
	if decision.Decision != model.PolicyDecisionQuarantine {
		t.Fatalf("expected QUARANTINE decision, got %q", decision.Decision)
	}
	if decision.ReasonCode == "" || decision.PublicMessageKey == "" {
		t.Fatalf("expected safe reason/public message, got reason=%q key=%q", decision.ReasonCode, decision.PublicMessageKey)
	}
}

func TestApplyUserRestrictionEventIsIdempotent(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	eventID := uuid.New()
	restrictionID := uuid.New()
	now := time.Date(2026, 5, 30, 9, 30, 0, 0, time.UTC)
	repo := newTrustRepoFake()
	usecase := NewPolicyUseCase(repo)
	input := model.RestrictionEventInput{
		EventID:         eventID,
		EventType:       model.RestrictionEventTypeCreated,
		RestrictionID:   restrictionID,
		UserID:          userID,
		RestrictionCode: model.RestrictionCodeChat,
		ReasonCode:      "abuse_report",
		OccurredAt:      now,
	}

	applied, err := usecase.ApplyUserRestrictionEvent(ctx, input)
	if err != nil {
		t.Fatalf("ApplyUserRestrictionEvent returned error: %v", err)
	}
	if !applied {
		t.Fatal("expected first restriction event to be applied")
	}

	applied, err = usecase.ApplyUserRestrictionEvent(ctx, input)
	if err != nil {
		t.Fatalf("duplicate ApplyUserRestrictionEvent returned error: %v", err)
	}
	if applied {
		t.Fatal("expected duplicate restriction event to be ignored")
	}
	if got := len(repo.restrictions[userID]); got != 1 {
		t.Fatalf("expected one runtime restriction, got %d", got)
	}
}

func TestGetTrustProfileCreatesDefaultProfile(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	repo := newTrustRepoFake()
	usecase := NewPolicyUseCase(repo)

	profile, err := usecase.GetTrustProfile(ctx, userID)

	if err != nil {
		t.Fatalf("GetTrustProfile returned error: %v", err)
	}
	if profile.UserID != userID {
		t.Fatalf("expected user id %s, got %s", userID, profile.UserID)
	}
	if profile.Score != 500 || profile.Band != model.TrustBandNew || profile.Status != model.TrustStatusActive {
		t.Fatalf("unexpected default profile: score=%d band=%q status=%q", profile.Score, profile.Band, profile.Status)
	}
	if _, ok := repo.profiles[userID]; !ok {
		t.Fatal("expected default profile to be persisted")
	}
}

type trustRepoFake struct {
	profiles     map[uuid.UUID]model.TrustProfile
	restrictions map[uuid.UUID][]model.RuntimeRestriction
	events       map[uuid.UUID]struct{}
	decisions    []model.PolicyDecisionRecord
}

func newTrustRepoFake() *trustRepoFake {
	return &trustRepoFake{
		profiles:     make(map[uuid.UUID]model.TrustProfile),
		restrictions: make(map[uuid.UUID][]model.RuntimeRestriction),
		events:       make(map[uuid.UUID]struct{}),
	}
}

func (r *trustRepoFake) GetTrustProfile(_ context.Context, userID uuid.UUID) (model.TrustProfile, error) {
	profile, ok := r.profiles[userID]
	if !ok {
		return model.TrustProfile{}, port.ErrNotFound
	}
	return profile, nil
}

func (r *trustRepoFake) UpsertTrustProfile(_ context.Context, profile model.TrustProfile) error {
	r.profiles[profile.UserID] = profile
	return nil
}

func (r *trustRepoFake) ListActiveRestrictions(_ context.Context, userID uuid.UUID, now time.Time) ([]model.RuntimeRestriction, error) {
	var active []model.RuntimeRestriction
	for _, restriction := range r.restrictions[userID] {
		if restriction.Status != model.RuntimeRestrictionActive {
			continue
		}
		if restriction.ExpiresAt != nil && !restriction.ExpiresAt.After(now) {
			continue
		}
		active = append(active, restriction)
	}
	return active, nil
}

func (r *trustRepoFake) SavePolicyDecision(_ context.Context, decision model.PolicyDecisionRecord) error {
	r.decisions = append(r.decisions, decision)
	return nil
}

func (r *trustRepoFake) HasProcessedEvent(_ context.Context, eventID uuid.UUID) (bool, error) {
	_, ok := r.events[eventID]
	return ok, nil
}

func (r *trustRepoFake) MarkProcessedEvent(_ context.Context, eventID uuid.UUID, _ string, _ time.Time) error {
	r.events[eventID] = struct{}{}
	return nil
}

func (r *trustRepoFake) UpsertRuntimeRestriction(_ context.Context, restriction model.RuntimeRestriction) error {
	restrictions := r.restrictions[restriction.UserID]
	for idx := range restrictions {
		if restrictions[idx].ID == restriction.ID {
			restrictions[idx] = restriction
			r.restrictions[restriction.UserID] = restrictions
			return nil
		}
	}
	r.restrictions[restriction.UserID] = append(restrictions, restriction)
	return nil
}

func (r *trustRepoFake) LiftRuntimeRestriction(_ context.Context, restrictionID uuid.UUID, _ uuid.UUID, liftedBy *uuid.UUID, liftedAt time.Time, reasonCode string) error {
	for userID, restrictions := range r.restrictions {
		for idx := range restrictions {
			if restrictions[idx].ID != restrictionID {
				continue
			}
			restrictions[idx].Status = model.RuntimeRestrictionLifted
			restrictions[idx].LiftedAt = &liftedAt
			restrictions[idx].LiftedByStaffID = liftedBy
			restrictions[idx].ReasonCode = reasonCode
			r.restrictions[userID] = restrictions
			return nil
		}
	}
	return errors.New("restriction not found")
}
