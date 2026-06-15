package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestListTrustRestrictionAppealsRequiresUsersReadPermission(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Permissions: []enum.Permission{enum.PermissionDashboardRead},
	}
	uc := NewTrustAppealUseCase(&trustAppealClientStub{}, &trustAppealAuditRepoStub{})

	_, err := uc.ListRestrictionAppeals(context.Background(), actor, model.TrustRestrictionAppealFilter{})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("ListRestrictionAppeals() error = %v, want %v", err, ErrPermissionDenied)
	}
}

func TestDecideTrustRestrictionAppealSendsDecisionAndWritesAudit(t *testing.T) {
	t.Parallel()

	actorID := uuid.New()
	appealID := uuid.New()
	restrictionID := uuid.New()
	userID := uuid.New()
	actor := &model.StaffUser{
		ID: actorID,
		Permissions: []enum.Permission{
			enum.PermissionUsersRestrict,
		},
	}
	client := &trustAppealClientStub{
		appeal: model.TrustRestrictionAppeal{
			ID:              appealID,
			RestrictionID:   restrictionID,
			UserID:          userID,
			RestrictionCode: model.UserRestrictionChat,
			Status:          model.TrustRestrictionAppealStatusApproved,
			ReasonCode:      "false_positive",
			UserMessage:     "I shared a local emergency contact, not off-platform sales.",
			CreatedAt:       time.Now().UTC(),
			UpdatedAt:       time.Now().UTC(),
		},
	}
	audit := &trustAppealAuditRepoStub{}
	uc := NewTrustAppealUseCase(client, audit)

	got, err := uc.DecideRestrictionAppeal(context.Background(), actor, model.TrustRestrictionAppealDecisionInput{
		AppealID:       appealID,
		Decision:       model.TrustRestrictionAppealDecisionApprove,
		ReasonCode:     "false_positive",
		StaffComment:   "Restriction was too broad for this user message.",
		IdempotencyKey: "appeal-approve-1",
	}, RequestMetadata{RequestID: "req-appeal-1", IPAddress: "127.0.0.1", UserAgent: "test"})

	if err != nil {
		t.Fatalf("DecideRestrictionAppeal() error = %v", err)
	}
	if got.ID != appealID {
		t.Fatalf("appeal id = %s, want %s", got.ID, appealID)
	}
	if client.lastDecision.ActorStaffID != actorID {
		t.Fatalf("actor staff id = %s, want %s", client.lastDecision.ActorStaffID, actorID)
	}
	if client.lastDecision.RequestID != "req-appeal-1" {
		t.Fatalf("request id = %q, want req-appeal-1", client.lastDecision.RequestID)
	}
	if len(audit.events) != 1 {
		t.Fatalf("audit events = %d, want 1", len(audit.events))
	}
	if audit.events[0].Action != "trust.appeal.decided" {
		t.Fatalf("audit action = %q", audit.events[0].Action)
	}
	if audit.events[0].EntityType != "trust_restriction_appeal" {
		t.Fatalf("audit entity type = %q", audit.events[0].EntityType)
	}
	if audit.events[0].EntityID == nil || *audit.events[0].EntityID != appealID {
		t.Fatalf("audit entity id = %v, want %s", audit.events[0].EntityID, appealID)
	}
}

func TestDecideTrustRestrictionAppealRequiresComment(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Permissions: []enum.Permission{enum.PermissionUsersRestrict},
	}
	client := &trustAppealClientStub{}
	uc := NewTrustAppealUseCase(client, &trustAppealAuditRepoStub{})

	_, err := uc.DecideRestrictionAppeal(context.Background(), actor, model.TrustRestrictionAppealDecisionInput{
		AppealID:   uuid.New(),
		Decision:   model.TrustRestrictionAppealDecisionReject,
		ReasonCode: "restriction_still_valid",
	}, RequestMetadata{})

	if !errors.Is(err, ErrInvalidInput) {
		t.Fatalf("DecideRestrictionAppeal() error = %v, want %v", err, ErrInvalidInput)
	}
	if client.lastDecision.AppealID != uuid.Nil {
		t.Fatal("DecideRestrictionAppeal() called trust client without mandatory staff comment")
	}
}

type trustAppealClientStub struct {
	page         model.TrustRestrictionAppealListPage
	appeal       model.TrustRestrictionAppeal
	lastFilter   model.TrustRestrictionAppealFilter
	lastDecision model.TrustRestrictionAppealDecisionInput
}

func (c *trustAppealClientStub) ListRestrictionAppeals(
	_ context.Context,
	filter model.TrustRestrictionAppealFilter,
) (model.TrustRestrictionAppealListPage, error) {
	c.lastFilter = filter
	return c.page, nil
}

func (c *trustAppealClientStub) GetRestrictionAppeal(
	_ context.Context,
	id uuid.UUID,
) (model.TrustRestrictionAppeal, error) {
	c.appeal.ID = id
	return c.appeal, nil
}

func (c *trustAppealClientStub) DecideRestrictionAppeal(
	_ context.Context,
	input model.TrustRestrictionAppealDecisionInput,
) (model.TrustRestrictionAppeal, error) {
	c.lastDecision = input
	c.appeal.ID = input.AppealID
	c.appeal.StaffDecision = &input.Decision
	c.appeal.StaffComment = input.StaffComment
	if input.Decision == model.TrustRestrictionAppealDecisionApprove {
		c.appeal.Status = model.TrustRestrictionAppealStatusApproved
	} else {
		c.appeal.Status = model.TrustRestrictionAppealStatusRejected
	}
	return c.appeal, nil
}

type trustAppealAuditRepoStub struct {
	events []*model.AuditEvent
}

func (r *trustAppealAuditRepoStub) Append(_ context.Context, event *model.AuditEvent) error {
	r.events = append(r.events, event)
	return nil
}

func (r *trustAppealAuditRepoStub) List(context.Context, model.AuditFilter) ([]*model.AuditEvent, error) {
	return r.events, nil
}
