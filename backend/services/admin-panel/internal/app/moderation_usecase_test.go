package app

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/port"
)

func TestDecideExcursionSupersedesPreviousAppliedDecision(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "moderator@flyfy.local",
		DisplayName: "Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionExcursionModerate,
		},
	}
	caseID := uuid.New()
	excursionID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetExcursion,
			TargetID:       excursionID,
			SourceRevision: 2,
			Status:         enum.ModerationCaseStatusRejected,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	excursion := &moderationExcursionClientStub{
		item: &model.ExcursionModerationItem{
			ID:       excursionID,
			Revision: 2,
			Status:   "PUBLISHED",
		},
	}
	uc := NewModerationUseCase(repo, excursion, &moderationAuditRepoStub{})

	_, err := uc.DecideExcursion(context.Background(), ModerationDecisionInput{
		Actor:          actor,
		CaseID:         caseID,
		Decision:       enum.ModerationDecisionApprove,
		IdempotencyKey: "approve-again",
	})

	if err != nil {
		t.Fatalf("DecideExcursion() error = %v", err)
	}
	if repo.supersededCaseID != caseID {
		t.Fatalf("supersededCaseID = %s, want %s", repo.supersededCaseID, caseID)
	}
	if repo.supersededRevision != 2 {
		t.Fatalf("supersededRevision = %d, want 2", repo.supersededRevision)
	}
	if repo.supersededExceptDecisionID == uuid.Nil {
		t.Fatal("new decision id was not excluded from superseding")
	}
}

type moderationRepoStub struct {
	item                       *model.ModerationCase
	decisions                  []*model.ModerationDecision
	createdDecision            *model.ModerationDecision
	supersededCaseID           uuid.UUID
	supersededRevision         int
	supersededExceptDecisionID uuid.UUID
}

func (r *moderationRepoStub) UpsertExcursionCase(context.Context, model.ExcursionModerationItem) (*model.ModerationCase, error) {
	return nil, nil
}

func (r *moderationRepoStub) CancelStaleExcursionCases(context.Context, []uuid.UUID, time.Time) error {
	return nil
}

func (r *moderationRepoStub) ListCases(context.Context, model.ModerationQueueFilter) ([]*model.ModerationCase, error) {
	return []*model.ModerationCase{r.item}, nil
}

func (r *moderationRepoStub) GetCase(context.Context, uuid.UUID) (*model.ModerationCase, error) {
	return r.item, nil
}

func (r *moderationRepoStub) ListDecisions(context.Context, uuid.UUID) ([]*model.ModerationDecision, error) {
	return r.decisions, nil
}

func (r *moderationRepoStub) CreateDecision(_ context.Context, decision *model.ModerationDecision) error {
	r.createdDecision = decision
	r.decisions = append([]*model.ModerationDecision{decision}, r.decisions...)
	return nil
}

func (r *moderationRepoStub) MarkDecisionApplied(context.Context, uuid.UUID, []byte, time.Time) error {
	return nil
}

func (r *moderationRepoStub) MarkDecisionFailed(context.Context, uuid.UUID, []byte, time.Time) error {
	return nil
}

func (r *moderationRepoStub) SupersedeAppliedDecisions(_ context.Context, caseID uuid.UUID, sourceRevision int, exceptDecisionID uuid.UUID, _ time.Time) error {
	r.supersededCaseID = caseID
	r.supersededRevision = sourceRevision
	r.supersededExceptDecisionID = exceptDecisionID
	return nil
}

func (r *moderationRepoStub) UpdateCaseStatus(_ context.Context, _ uuid.UUID, status enum.ModerationCaseStatus, _ *time.Time, _ time.Time) error {
	r.item.Status = status
	return nil
}

type moderationExcursionClientStub struct {
	item *model.ExcursionModerationItem
}

func (c *moderationExcursionClientStub) ListPendingReview(context.Context, int, int) ([]model.ExcursionModerationItem, error) {
	return nil, nil
}

func (c *moderationExcursionClientStub) GetExcursion(context.Context, uuid.UUID) (*model.ExcursionModerationItem, error) {
	return c.item, nil
}

func (c *moderationExcursionClientStub) Approve(context.Context, port.ExcursionDecisionInput) (*model.ExcursionModerationItem, []byte, error) {
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

func (c *moderationExcursionClientStub) Reject(context.Context, port.ExcursionDecisionInput) (*model.ExcursionModerationItem, []byte, error) {
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

type moderationAuditRepoStub struct{}

func (r *moderationAuditRepoStub) Append(context.Context, *model.AuditEvent) error {
	return nil
}

func (r *moderationAuditRepoStub) List(context.Context, model.AuditFilter) ([]*model.AuditEvent, error) {
	return nil, nil
}
