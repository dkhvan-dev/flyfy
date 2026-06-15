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

func TestSubmitRestrictionAppealCreatesPendingAppealAndMarksProfileUnderReview(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	restrictionID := uuid.New()
	now := time.Date(2026, 6, 12, 15, 0, 0, 0, time.UTC)
	repo := newTrustRepoFake()
	repo.profiles[userID] = model.TrustProfile{
		UserID:       userID,
		Score:        540,
		Band:         model.TrustBandNormal,
		Status:       model.TrustStatusRestricted,
		CalculatedAt: now.Add(-time.Hour),
		CreatedAt:    now.Add(-time.Hour),
		UpdatedAt:    now.Add(-time.Hour),
	}
	repo.restrictions[userID] = []model.RuntimeRestriction{{
		ID:              restrictionID,
		UserID:          userID,
		RestrictionCode: model.RestrictionCodeChat,
		Status:          model.RuntimeRestrictionActive,
		ReasonCode:      "spam_report",
		SourceEventID:   uuid.New(),
		CreatedAt:       now.Add(-time.Hour),
	}}
	usecase := NewPolicyUseCase(repo)
	input := model.SubmitRestrictionAppealInput{
		UserID:         userID,
		RestrictionID:  restrictionID,
		ReasonCode:     "mistake",
		UserMessage:    " Please review this restriction. ",
		IdempotencyKey: "appeal-chat-1",
		SubmittedAt:    now,
	}

	appeal, err := usecase.SubmitRestrictionAppeal(ctx, input)
	if err != nil {
		t.Fatalf("SubmitRestrictionAppeal returned error: %v", err)
	}
	if appeal.Status != model.RestrictionAppealStatusPending {
		t.Fatalf("appeal status = %q, want pending", appeal.Status)
	}
	if appeal.UserMessage != "Please review this restriction." {
		t.Fatalf("appeal user message = %q, want trimmed message", appeal.UserMessage)
	}
	if repo.profiles[userID].Status != model.TrustStatusUnderReview {
		t.Fatalf("profile status = %q, want under review", repo.profiles[userID].Status)
	}

	duplicate, err := usecase.SubmitRestrictionAppeal(ctx, input)
	if err != nil {
		t.Fatalf("duplicate SubmitRestrictionAppeal returned error: %v", err)
	}
	if duplicate.ID != appeal.ID {
		t.Fatalf("duplicate appeal id = %s, want %s", duplicate.ID, appeal.ID)
	}
	if len(repo.appeals) != 1 {
		t.Fatalf("appeals = %d, want idempotent single appeal", len(repo.appeals))
	}
}

func TestDecideRestrictionAppealApproveLiftsRestrictionAndRestoresActiveProfile(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	restrictionID := uuid.New()
	appealID := uuid.New()
	staffID := uuid.New()
	now := time.Date(2026, 6, 12, 15, 30, 0, 0, time.UTC)
	repo := newTrustRepoFake()
	repo.profiles[userID] = model.TrustProfile{
		UserID:       userID,
		Score:        610,
		Band:         model.TrustBandNormal,
		Status:       model.TrustStatusUnderReview,
		CalculatedAt: now.Add(-time.Hour),
		CreatedAt:    now.Add(-time.Hour),
		UpdatedAt:    now.Add(-time.Hour),
	}
	repo.restrictions[userID] = []model.RuntimeRestriction{{
		ID:              restrictionID,
		UserID:          userID,
		RestrictionCode: model.RestrictionCodeChat,
		Status:          model.RuntimeRestrictionActive,
		ReasonCode:      "spam_report",
		SourceEventID:   uuid.New(),
		CreatedAt:       now.Add(-time.Hour),
	}}
	repo.appeals[appealID] = model.RestrictionAppeal{
		ID:            appealID,
		UserID:        userID,
		RestrictionID: restrictionID,
		Status:        model.RestrictionAppealStatusPending,
		ReasonCode:    "mistake",
		CreatedAt:     now.Add(-time.Minute),
		UpdatedAt:     now.Add(-time.Minute),
	}
	usecase := NewPolicyUseCase(repo)

	appeal, err := usecase.DecideRestrictionAppeal(ctx, model.DecideRestrictionAppealInput{
		AppealID:        appealID,
		ActorStaffID:    staffID,
		Decision:        model.RestrictionAppealDecisionApprove,
		ReasonCode:      "restriction_mistake",
		StaffComment:    "Evidence supports the appeal.",
		DecisionEventID: uuid.New(),
		DecidedAt:       now,
	})
	if err != nil {
		t.Fatalf("DecideRestrictionAppeal returned error: %v", err)
	}
	if appeal.Status != model.RestrictionAppealStatusApproved {
		t.Fatalf("appeal status = %q, want approved", appeal.Status)
	}
	restrictions := repo.restrictions[userID]
	if restrictions[0].Status != model.RuntimeRestrictionLifted {
		t.Fatalf("restriction status = %q, want lifted", restrictions[0].Status)
	}
	if repo.profiles[userID].Status != model.TrustStatusActive {
		t.Fatalf("profile status = %q, want active", repo.profiles[userID].Status)
	}
}

func TestListRestrictionAppealsFiltersByStatusAndUser(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	otherUserID := uuid.New()
	repo := newTrustRepoFake()
	pendingAppeal := model.RestrictionAppeal{
		ID:            uuid.New(),
		UserID:        userID,
		RestrictionID: uuid.New(),
		Status:        model.RestrictionAppealStatusPending,
		ReasonCode:    "mistake",
		UserMessage:   "Please review.",
		CreatedAt:     time.Date(2026, 6, 12, 16, 0, 0, 0, time.UTC),
		UpdatedAt:     time.Date(2026, 6, 12, 16, 0, 0, 0, time.UTC),
	}
	repo.appeals[pendingAppeal.ID] = pendingAppeal
	repo.appeals[uuid.New()] = model.RestrictionAppeal{
		ID:            uuid.New(),
		UserID:        userID,
		RestrictionID: uuid.New(),
		Status:        model.RestrictionAppealStatusRejected,
		ReasonCode:    "duplicate",
		UserMessage:   "Rejected appeal.",
		CreatedAt:     time.Date(2026, 6, 12, 15, 0, 0, 0, time.UTC),
		UpdatedAt:     time.Date(2026, 6, 12, 15, 0, 0, 0, time.UTC),
	}
	repo.appeals[uuid.New()] = model.RestrictionAppeal{
		ID:            uuid.New(),
		UserID:        otherUserID,
		RestrictionID: uuid.New(),
		Status:        model.RestrictionAppealStatusPending,
		ReasonCode:    "mistake",
		UserMessage:   "Other user appeal.",
		CreatedAt:     time.Date(2026, 6, 12, 17, 0, 0, 0, time.UTC),
		UpdatedAt:     time.Date(2026, 6, 12, 17, 0, 0, 0, time.UTC),
	}
	usecase := NewPolicyUseCase(repo)

	appeals, err := usecase.ListRestrictionAppeals(ctx, model.ListRestrictionAppealsInput{
		Status: model.RestrictionAppealStatusPending,
		UserID: &userID,
	})
	if err != nil {
		t.Fatalf("ListRestrictionAppeals returned error: %v", err)
	}
	if len(appeals) != 1 {
		t.Fatalf("appeals = %d, want one pending appeal for user", len(appeals))
	}
	if appeals[0].ID != pendingAppeal.ID {
		t.Fatalf("appeal id = %s, want %s", appeals[0].ID, pendingAppeal.ID)
	}
}

type trustRepoFake struct {
	profiles     map[uuid.UUID]model.TrustProfile
	restrictions map[uuid.UUID][]model.RuntimeRestriction
	events       map[uuid.UUID]struct{}
	decisions    []model.PolicyDecisionRecord
	appeals      map[uuid.UUID]model.RestrictionAppeal
}

func newTrustRepoFake() *trustRepoFake {
	return &trustRepoFake{
		profiles:     make(map[uuid.UUID]model.TrustProfile),
		restrictions: make(map[uuid.UUID][]model.RuntimeRestriction),
		events:       make(map[uuid.UUID]struct{}),
		appeals:      make(map[uuid.UUID]model.RestrictionAppeal),
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

func (r *trustRepoFake) GetRuntimeRestrictionByID(_ context.Context, restrictionID uuid.UUID) (model.RuntimeRestriction, error) {
	for _, restrictions := range r.restrictions {
		for _, restriction := range restrictions {
			if restriction.ID == restrictionID {
				return restriction, nil
			}
		}
	}
	return model.RuntimeRestriction{}, port.ErrNotFound
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

func (r *trustRepoFake) CreateRestrictionAppeal(_ context.Context, appeal model.RestrictionAppeal) (model.RestrictionAppeal, error) {
	if appeal.IdempotencyKey != "" {
		for _, existing := range r.appeals {
			if existing.UserID == appeal.UserID &&
				existing.RestrictionID == appeal.RestrictionID &&
				existing.IdempotencyKey == appeal.IdempotencyKey {
				return existing, nil
			}
		}
	}
	r.appeals[appeal.ID] = appeal
	return appeal, nil
}

func (r *trustRepoFake) GetRestrictionAppeal(_ context.Context, appealID uuid.UUID) (model.RestrictionAppeal, error) {
	appeal, ok := r.appeals[appealID]
	if !ok {
		return model.RestrictionAppeal{}, port.ErrNotFound
	}
	return appeal, nil
}

func (r *trustRepoFake) SaveRestrictionAppealDecision(_ context.Context, appeal model.RestrictionAppeal) (model.RestrictionAppeal, error) {
	if _, ok := r.appeals[appeal.ID]; !ok {
		return model.RestrictionAppeal{}, port.ErrNotFound
	}
	r.appeals[appeal.ID] = appeal
	return appeal, nil
}

func (r *trustRepoFake) ListRestrictionAppeals(_ context.Context, input model.ListRestrictionAppealsInput) ([]model.RestrictionAppeal, error) {
	var appeals []model.RestrictionAppeal
	for _, appeal := range r.appeals {
		if input.Status != "" && appeal.Status != input.Status {
			continue
		}
		if input.UserID != nil && appeal.UserID != *input.UserID {
			continue
		}
		appeals = append(appeals, appeal)
	}
	return appeals, nil
}
