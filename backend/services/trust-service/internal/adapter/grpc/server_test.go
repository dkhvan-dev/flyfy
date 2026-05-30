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

type grpcTrustRepoFake struct {
	profiles     map[uuid.UUID]model.TrustProfile
	restrictions map[uuid.UUID][]model.RuntimeRestriction
	events       map[uuid.UUID]struct{}
	decisions    []model.PolicyDecisionRecord
}

func newGRPCTrustRepoFake() *grpcTrustRepoFake {
	return &grpcTrustRepoFake{
		profiles:     make(map[uuid.UUID]model.TrustProfile),
		restrictions: make(map[uuid.UUID][]model.RuntimeRestriction),
		events:       make(map[uuid.UUID]struct{}),
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
