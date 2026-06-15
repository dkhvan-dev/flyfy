package grpc

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"kz/inflap/backend/services/trust-service/internal/app"
	"kz/inflap/backend/services/trust-service/internal/domain/model"
	"kz/inflap/backend/services/trust-service/internal/domain/port"
	trustv1 "kz/inflap/proto/gen/go/trust/v1"
)

func TestCheckActionPolicyMapsDenyResponse(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	restrictionID := uuid.New()
	repo := newGRPCTrustRepoFake()
	repo.profiles[userID] = model.TrustProfile{
		UserID: userID,
		Score:  650,
		Band:   model.TrustBandNormal,
		Status: model.TrustStatusActive,
	}
	repo.restrictions[userID] = []model.RuntimeRestriction{
		{
			ID:              restrictionID,
			UserID:          userID,
			RestrictionCode: model.RestrictionCodeChat,
			Status:          model.RuntimeRestrictionActive,
			ReasonCode:      "spam",
			SourceEventID:   uuid.New(),
			CreatedAt:       time.Now().UTC(),
		},
	}
	server := NewServer(app.NewPolicyUseCase(repo))

	resp, err := server.CheckActionPolicy(ctx, &trustv1.CheckActionPolicyRequest{
		UserId: userID.String(),
		Action: trustv1.PolicyAction_POLICY_ACTION_CHAT_SEND,
	})

	if err != nil {
		t.Fatalf("CheckActionPolicy returned error: %v", err)
	}
	if resp.GetDecision() != trustv1.PolicyDecision_POLICY_DECISION_DENY {
		t.Fatalf("expected DENY response, got %s", resp.GetDecision())
	}
	if resp.GetReasonCode() != "spam" {
		t.Fatalf("expected reason code from restriction, got %q", resp.GetReasonCode())
	}
	if len(resp.GetRestrictionIds()) != 1 || resp.GetRestrictionIds()[0] != restrictionID.String() {
		t.Fatalf("unexpected restriction ids: %#v", resp.GetRestrictionIds())
	}
}

func TestApplyUserRestrictionEventRejectsInvalidUUID(t *testing.T) {
	server := NewServer(app.NewPolicyUseCase(newGRPCTrustRepoFake()))

	_, err := server.ApplyUserRestrictionEvent(context.Background(), &trustv1.ApplyUserRestrictionEventRequest{
		EventId:       "not-a-uuid",
		EventType:     trustv1.RestrictionEventType_RESTRICTION_EVENT_TYPE_CREATED,
		RestrictionId: uuid.NewString(),
		UserId:        uuid.NewString(),
	})

	if status.Code(err) != codes.InvalidArgument {
		t.Fatalf("expected InvalidArgument, got err=%v code=%s", err, status.Code(err))
	}
}

func TestGetTrustProfileMapsProfile(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	repo := newGRPCTrustRepoFake()
	repo.profiles[userID] = model.TrustProfile{
		UserID: userID,
		Score:  820,
		Band:   model.TrustBandTrusted,
		Status: model.TrustStatusActive,
	}
	server := NewServer(app.NewPolicyUseCase(repo))

	resp, err := server.GetTrustProfile(ctx, &trustv1.GetTrustProfileRequest{
		UserId: userID.String(),
	})

	if err != nil {
		t.Fatalf("GetTrustProfile returned error: %v", err)
	}
	if resp.GetProfile().GetUserId() != userID.String() {
		t.Fatalf("expected user id %s, got %s", userID, resp.GetProfile().GetUserId())
	}
	if resp.GetProfile().GetScore() != 820 {
		t.Fatalf("expected score 820, got %d", resp.GetProfile().GetScore())
	}
	if resp.GetProfile().GetBand() != trustv1.TrustBand_TRUST_BAND_TRUSTED {
		t.Fatalf("expected TRUSTED band, got %s", resp.GetProfile().GetBand())
	}
}

func TestSubmitRestrictionAppealMapsPendingAppeal(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	restrictionID := uuid.New()
	repo := newGRPCTrustRepoFake()
	repo.profiles[userID] = model.TrustProfile{
		UserID: userID,
		Score:  640,
		Band:   model.TrustBandNormal,
		Status: model.TrustStatusRestricted,
	}
	repo.restrictions[userID] = []model.RuntimeRestriction{{
		ID:              restrictionID,
		UserID:          userID,
		RestrictionCode: model.RestrictionCodeChat,
		Status:          model.RuntimeRestrictionActive,
		ReasonCode:      "spam_report",
		SourceEventID:   uuid.New(),
		CreatedAt:       time.Now().UTC().Add(-time.Hour),
	}}
	server := NewServer(app.NewPolicyUseCase(repo))

	resp, err := server.SubmitRestrictionAppeal(ctx, &trustv1.SubmitRestrictionAppealRequest{
		UserId:         userID.String(),
		RestrictionId:  restrictionID.String(),
		ReasonCode:     "mistake",
		UserMessage:    "Please review this restriction.",
		IdempotencyKey: "appeal-chat-1",
	})
	if err != nil {
		t.Fatalf("SubmitRestrictionAppeal returned error: %v", err)
	}
	if resp.GetAppeal().GetUserId() != userID.String() {
		t.Fatalf("appeal user id = %q, want %s", resp.GetAppeal().GetUserId(), userID)
	}
	if resp.GetAppeal().GetRestrictionId() != restrictionID.String() {
		t.Fatalf("appeal restriction id = %q, want %s", resp.GetAppeal().GetRestrictionId(), restrictionID)
	}
	if resp.GetAppeal().GetStatus() != trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_PENDING {
		t.Fatalf("appeal status = %s, want pending", resp.GetAppeal().GetStatus())
	}
}

func TestListRestrictionAppealsMapsStatusAndUserFilters(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	pendingAppeal := model.RestrictionAppeal{
		ID:            uuid.New(),
		UserID:        userID,
		RestrictionID: uuid.New(),
		Status:        model.RestrictionAppealStatusPending,
		ReasonCode:    "mistake",
		UserMessage:   "Please review.",
		CreatedAt:     time.Now().UTC().Add(-time.Minute),
		UpdatedAt:     time.Now().UTC().Add(-time.Minute),
	}
	repo := newGRPCTrustRepoFake()
	repo.appeals[pendingAppeal.ID] = pendingAppeal
	repo.appeals[uuid.New()] = model.RestrictionAppeal{
		ID:            uuid.New(),
		UserID:        userID,
		RestrictionID: uuid.New(),
		Status:        model.RestrictionAppealStatusRejected,
		ReasonCode:    "duplicate",
		UserMessage:   "Rejected.",
		CreatedAt:     time.Now().UTC().Add(-time.Hour),
		UpdatedAt:     time.Now().UTC().Add(-time.Hour),
	}
	server := NewServer(app.NewPolicyUseCase(repo))

	resp, err := server.ListRestrictionAppeals(ctx, &trustv1.ListRestrictionAppealsRequest{
		Status: trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_PENDING,
		UserId: userID.String(),
	})
	if err != nil {
		t.Fatalf("ListRestrictionAppeals returned error: %v", err)
	}
	if len(resp.GetAppeals()) != 1 {
		t.Fatalf("appeals = %d, want one", len(resp.GetAppeals()))
	}
	if resp.GetAppeals()[0].GetAppealId() != pendingAppeal.ID.String() {
		t.Fatalf("appeal id = %q, want %s", resp.GetAppeals()[0].GetAppealId(), pendingAppeal.ID)
	}
}

func TestDecideRestrictionAppealMapsApprovedAppeal(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	restrictionID := uuid.New()
	appealID := uuid.New()
	staffID := uuid.New()
	repo := newGRPCTrustRepoFake()
	repo.profiles[userID] = model.TrustProfile{
		UserID: userID,
		Score:  640,
		Band:   model.TrustBandNormal,
		Status: model.TrustStatusUnderReview,
	}
	repo.restrictions[userID] = []model.RuntimeRestriction{{
		ID:              restrictionID,
		UserID:          userID,
		RestrictionCode: model.RestrictionCodeChat,
		Status:          model.RuntimeRestrictionActive,
		ReasonCode:      "spam_report",
		SourceEventID:   uuid.New(),
		CreatedAt:       time.Now().UTC().Add(-time.Hour),
	}}
	repo.appeals[appealID] = model.RestrictionAppeal{
		ID:            appealID,
		UserID:        userID,
		RestrictionID: restrictionID,
		Status:        model.RestrictionAppealStatusPending,
		ReasonCode:    "mistake",
		UserMessage:   "Please review.",
		CreatedAt:     time.Now().UTC().Add(-time.Minute),
		UpdatedAt:     time.Now().UTC().Add(-time.Minute),
	}
	server := NewServer(app.NewPolicyUseCase(repo))

	resp, err := server.DecideRestrictionAppeal(ctx, &trustv1.DecideRestrictionAppealRequest{
		AppealId:        appealID.String(),
		ActorStaffId:    staffID.String(),
		Decision:        trustv1.RestrictionAppealDecision_RESTRICTION_APPEAL_DECISION_APPROVE,
		ReasonCode:      "restriction_mistake",
		StaffComment:    "Evidence supports the appeal.",
		DecisionEventId: uuid.NewString(),
	})
	if err != nil {
		t.Fatalf("DecideRestrictionAppeal returned error: %v", err)
	}
	if resp.GetAppeal().GetStatus() != trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_APPROVED {
		t.Fatalf("appeal status = %s, want approved", resp.GetAppeal().GetStatus())
	}
	if repo.restrictions[userID][0].Status != model.RuntimeRestrictionLifted {
		t.Fatalf("restriction status = %q, want lifted", repo.restrictions[userID][0].Status)
	}
}

type grpcTrustRepoFake struct {
	profiles     map[uuid.UUID]model.TrustProfile
	restrictions map[uuid.UUID][]model.RuntimeRestriction
	events       map[uuid.UUID]struct{}
	decisions    []model.PolicyDecisionRecord
	appeals      map[uuid.UUID]model.RestrictionAppeal
}

func newGRPCTrustRepoFake() *grpcTrustRepoFake {
	return &grpcTrustRepoFake{
		profiles:     make(map[uuid.UUID]model.TrustProfile),
		restrictions: make(map[uuid.UUID][]model.RuntimeRestriction),
		events:       make(map[uuid.UUID]struct{}),
		appeals:      make(map[uuid.UUID]model.RestrictionAppeal),
	}
}

func (r *grpcTrustRepoFake) GetTrustProfile(_ context.Context, userID uuid.UUID) (model.TrustProfile, error) {
	profile, ok := r.profiles[userID]
	if !ok {
		return model.TrustProfile{}, port.ErrNotFound
	}
	return profile, nil
}

func (r *grpcTrustRepoFake) UpsertTrustProfile(_ context.Context, profile model.TrustProfile) error {
	r.profiles[profile.UserID] = profile
	return nil
}

func (r *grpcTrustRepoFake) ListActiveRestrictions(_ context.Context, userID uuid.UUID, now time.Time) ([]model.RuntimeRestriction, error) {
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

func (r *grpcTrustRepoFake) SavePolicyDecision(_ context.Context, decision model.PolicyDecisionRecord) error {
	r.decisions = append(r.decisions, decision)
	return nil
}

func (r *grpcTrustRepoFake) HasProcessedEvent(_ context.Context, eventID uuid.UUID) (bool, error) {
	_, ok := r.events[eventID]
	return ok, nil
}

func (r *grpcTrustRepoFake) MarkProcessedEvent(_ context.Context, eventID uuid.UUID, _ string, _ time.Time) error {
	r.events[eventID] = struct{}{}
	return nil
}

func (r *grpcTrustRepoFake) UpsertRuntimeRestriction(_ context.Context, restriction model.RuntimeRestriction) error {
	r.restrictions[restriction.UserID] = append(r.restrictions[restriction.UserID], restriction)
	return nil
}

func (r *grpcTrustRepoFake) GetRuntimeRestrictionByID(_ context.Context, restrictionID uuid.UUID) (model.RuntimeRestriction, error) {
	for _, restrictions := range r.restrictions {
		for _, restriction := range restrictions {
			if restriction.ID == restrictionID {
				return restriction, nil
			}
		}
	}
	return model.RuntimeRestriction{}, port.ErrNotFound
}

func (r *grpcTrustRepoFake) LiftRuntimeRestriction(_ context.Context, restrictionID uuid.UUID, _ uuid.UUID, liftedBy *uuid.UUID, liftedAt time.Time, reasonCode string) error {
	for userID, restrictions := range r.restrictions {
		for idx := range restrictions {
			if restrictions[idx].ID != restrictionID {
				continue
			}
			restrictions[idx].Status = model.RuntimeRestrictionLifted
			restrictions[idx].LiftedByStaffID = liftedBy
			restrictions[idx].LiftedAt = &liftedAt
			restrictions[idx].ReasonCode = reasonCode
			r.restrictions[userID] = restrictions
			return nil
		}
	}
	return errors.New("restriction not found")
}

func (r *grpcTrustRepoFake) CreateRestrictionAppeal(_ context.Context, appeal model.RestrictionAppeal) (model.RestrictionAppeal, error) {
	r.appeals[appeal.ID] = appeal
	return appeal, nil
}

func (r *grpcTrustRepoFake) GetRestrictionAppeal(_ context.Context, appealID uuid.UUID) (model.RestrictionAppeal, error) {
	appeal, ok := r.appeals[appealID]
	if !ok {
		return model.RestrictionAppeal{}, port.ErrNotFound
	}
	return appeal, nil
}

func (r *grpcTrustRepoFake) SaveRestrictionAppealDecision(_ context.Context, appeal model.RestrictionAppeal) (model.RestrictionAppeal, error) {
	r.appeals[appeal.ID] = appeal
	return appeal, nil
}

func (r *grpcTrustRepoFake) ListRestrictionAppeals(_ context.Context, input model.ListRestrictionAppealsInput) ([]model.RestrictionAppeal, error) {
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
