package app

import (
	"context"
	"encoding/json"
	"errors"
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
	uc := NewModerationUseCase(repo, excursion, &moderationActivityClientStub{}, &moderationAuditRepoStub{})

	_, err := uc.DecideExcursion(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionApprove,
		InternalComment: "Повторная проверка пройдена.",
		IdempotencyKey:  "approve-again",
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

func TestSyncActivityQueueUpsertsActiveFlaggedActivityCases(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "activity-moderator@flyfy.local",
		DisplayName: "Activity Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
		},
	}
	activityID := uuid.New()
	repo := &moderationRepoStub{}
	activity := &moderationActivityClientStub{
		items: []model.ActivityModerationItem{
			{
				ID:                    activityID,
				Title:                 "VIP hiking trip",
				Status:                "ENROLLMENT_OPEN",
				ModerationStatus:      "FLAGGED",
				ModerationRiskScore:   70,
				ModerationReasonCodes: []string{"external_contact"},
				Revision:              3,
			},
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, activity, &moderationAuditRepoStub{})

	if err := uc.SyncActivityQueue(context.Background(), actor); err != nil {
		t.Fatalf("SyncActivityQueue() error = %v", err)
	}
	if len(repo.upsertedActivities) != 1 {
		t.Fatalf("upserted activities = %d, want 1", len(repo.upsertedActivities))
	}
	if repo.upsertedActivities[0].ID != activityID {
		t.Fatalf("upserted activity id = %s, want %s", repo.upsertedActivities[0].ID, activityID)
	}
	if len(repo.cancelledActivityIDs) != 1 || repo.cancelledActivityIDs[0] != activityID {
		t.Fatalf("cancelled stale active ids = %#v, want [%s]", repo.cancelledActivityIDs, activityID)
	}
}

func TestDecideActivityApproveKeepsCaseAuditedAndApplied(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "activity-moderator@flyfy.local",
		DisplayName: "Activity Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionActivityModerate,
		},
	}
	caseID := uuid.New()
	activityID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetActivity,
			TargetID:       activityID,
			SourceRevision: 3,
			Status:         enum.ModerationCaseStatusOpen,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	activity := &moderationActivityClientStub{
		item: &model.ActivityModerationItem{
			ID:               activityID,
			Revision:         3,
			Status:           "ENROLLMENT_OPEN",
			ModerationStatus: "APPROVED",
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, activity, &moderationAuditRepoStub{})

	_, err := uc.DecideActivity(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionApprove,
		InternalComment: "Signals reviewed.",
		IdempotencyKey:  "activity-approve",
	})

	if err != nil {
		t.Fatalf("DecideActivity() error = %v", err)
	}
	if repo.createdDecision == nil {
		t.Fatal("DecideActivity() did not create moderation decision")
	}
	if repo.createdDecision.DecisionType != enum.ModerationDecisionApprove {
		t.Fatalf("decision type = %s, want %s", repo.createdDecision.DecisionType, enum.ModerationDecisionApprove)
	}
	if repo.item.Status != enum.ModerationCaseStatusApproved {
		t.Fatalf("case status = %s, want %s", repo.item.Status, enum.ModerationCaseStatusApproved)
	}
}

func TestDecideActivityRejectRequiresPublicAndInternalComments(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "activity-moderator@flyfy.local",
		DisplayName: "Activity Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionActivityModerate,
		},
	}
	caseID := uuid.New()
	activityID := uuid.New()

	for _, tc := range []struct {
		name            string
		publicComment   string
		internalComment string
	}{
		{name: "missing public comment", internalComment: "External contact confirmed."},
		{name: "missing internal comment", publicComment: "Уберите контактные данные из описания."},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			repo := &moderationRepoStub{
				item: &model.ModerationCase{
					ID:             caseID,
					TargetType:     model.ModerationTargetActivity,
					TargetID:       activityID,
					SourceRevision: 3,
					Status:         enum.ModerationCaseStatusOpen,
					CreatedAt:      time.Now().UTC(),
					UpdatedAt:      time.Now().UTC(),
				},
			}
			activity := &moderationActivityClientStub{
				item: &model.ActivityModerationItem{
					ID:               activityID,
					Revision:         3,
					Status:           "ENROLLMENT_OPEN",
					ModerationStatus: "FLAGGED",
				},
			}
			uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, activity, &moderationAuditRepoStub{})

			_, err := uc.DecideActivity(context.Background(), ModerationDecisionInput{
				Actor:           actor,
				CaseID:          caseID,
				Decision:        enum.ModerationDecisionReject,
				ReasonCodes:     []string{"external_contact"},
				PublicComment:   tc.publicComment,
				InternalComment: tc.internalComment,
				IdempotencyKey:  "activity-reject",
			})

			if !errors.Is(err, ErrInvalidInput) {
				t.Fatalf("DecideActivity() error = %v, want %v", err, ErrInvalidInput)
			}
			if repo.createdDecision != nil {
				t.Fatal("DecideActivity() created decision without mandatory comments")
			}
			if activity.lastRejectInput.ActivityID != uuid.Nil {
				t.Fatal("DecideActivity() called activity service without mandatory comments")
			}
		})
	}
}

func TestDecideActivityRejectSendsPublicCommentToActivityService(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "activity-moderator@flyfy.local",
		DisplayName: "Activity Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionActivityModerate,
		},
	}
	caseID := uuid.New()
	activityID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetActivity,
			TargetID:       activityID,
			SourceRevision: 3,
			Status:         enum.ModerationCaseStatusOpen,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	activity := &moderationActivityClientStub{
		item: &model.ActivityModerationItem{
			ID:               activityID,
			Revision:         3,
			Status:           "CANCELLED",
			ModerationStatus: "REJECTED",
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, activity, &moderationAuditRepoStub{})

	_, err := uc.DecideActivity(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionReject,
		ReasonCodes:     []string{"external_contact"},
		PublicComment:   "Уберите контактный номер из описания активности.",
		InternalComment: "Контактный номер подтвержден вручную.",
		IdempotencyKey:  "activity-reject",
	})

	if err != nil {
		t.Fatalf("DecideActivity() error = %v", err)
	}
	if activity.lastRejectInput.PublicComment != "Уберите контактный номер из описания активности." {
		t.Fatalf("public comment sent to activity service = %q", activity.lastRejectInput.PublicComment)
	}
}

type moderationRepoStub struct {
	item                       *model.ModerationCase
	decisions                  []*model.ModerationDecision
	createdDecision            *model.ModerationDecision
	supersededCaseID           uuid.UUID
	supersededRevision         int
	supersededExceptDecisionID uuid.UUID
	upsertedActivities         []model.ActivityModerationItem
	cancelledActivityIDs       []uuid.UUID
}

func (r *moderationRepoStub) UpsertExcursionCase(context.Context, model.ExcursionModerationItem) (*model.ModerationCase, error) {
	return nil, nil
}

func (r *moderationRepoStub) CancelStaleExcursionCases(context.Context, []uuid.UUID, time.Time) error {
	return nil
}

func (r *moderationRepoStub) UpsertActivityCase(_ context.Context, item model.ActivityModerationItem) (*model.ModerationCase, error) {
	r.upsertedActivities = append(r.upsertedActivities, item)
	return nil, nil
}

func (r *moderationRepoStub) CancelStaleActivityCases(_ context.Context, activeTargetIDs []uuid.UUID, _ time.Time) error {
	r.cancelledActivityIDs = append([]uuid.UUID(nil), activeTargetIDs...)
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
	item             *model.ExcursionModerationItem
	lastApproveInput port.ExcursionDecisionInput
	lastRejectInput  port.ExcursionDecisionInput
}

func (c *moderationExcursionClientStub) ListPendingReview(context.Context, int, int) ([]model.ExcursionModerationItem, error) {
	return nil, nil
}

func (c *moderationExcursionClientStub) GetExcursion(context.Context, uuid.UUID) (*model.ExcursionModerationItem, error) {
	return c.item, nil
}

func (c *moderationExcursionClientStub) Approve(_ context.Context, input port.ExcursionDecisionInput) (*model.ExcursionModerationItem, []byte, error) {
	c.lastApproveInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

func (c *moderationExcursionClientStub) Reject(_ context.Context, input port.ExcursionDecisionInput) (*model.ExcursionModerationItem, []byte, error) {
	c.lastRejectInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

type moderationActivityClientStub struct {
	item             *model.ActivityModerationItem
	items            []model.ActivityModerationItem
	lastApproveInput port.ActivityDecisionInput
	lastRejectInput  port.ActivityDecisionInput
}

func (c *moderationActivityClientStub) ListFlagged(context.Context, int, int) ([]model.ActivityModerationItem, error) {
	return c.items, nil
}

func (c *moderationActivityClientStub) GetActivity(context.Context, uuid.UUID) (*model.ActivityModerationItem, error) {
	return c.item, nil
}

func (c *moderationActivityClientStub) Approve(_ context.Context, input port.ActivityDecisionInput) (*model.ActivityModerationItem, []byte, error) {
	c.lastApproveInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

func (c *moderationActivityClientStub) Reject(_ context.Context, input port.ActivityDecisionInput) (*model.ActivityModerationItem, []byte, error) {
	c.lastRejectInput = input
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
