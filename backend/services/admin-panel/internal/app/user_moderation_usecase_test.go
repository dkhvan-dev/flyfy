package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

func TestCreateUserModerationCaseRequiresPermission(t *testing.T) {
	ctx := context.Background()
	actor := &model.StaffUser{ID: uuid.New(), Permissions: []enum.Permission{enum.PermissionDashboardRead}}
	uc := NewUserModerationUseCase(&userAdminClientStub{}, &userModerationRepoStub{}, &userModerationAuditRepoStub{})

	_, err := uc.CreateUserModerationCase(ctx, actor, model.CreateUserModerationCaseParams{
		TargetUserID: uuid.New(),
		Source:       model.UserModerationSourceStaff,
		ReasonCode:   "spam",
		Priority:     model.UserModerationPriorityNormal,
		StaffComment: "Reported by support.",
	}, RequestMetadata{RequestID: "req-1"})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("error = %v, want %v", err, ErrPermissionDenied)
	}
}

func TestCreateUserModerationCaseWritesAudit(t *testing.T) {
	ctx := context.Background()
	actor := &model.StaffUser{
		ID:          uuid.New(),
		Permissions: []enum.Permission{enum.PermissionUsersModerate},
	}
	targetUserID := uuid.New()
	repo := &userModerationRepoStub{}
	audit := &userModerationAuditRepoStub{}
	uc := NewUserModerationUseCase(&userAdminClientStub{}, repo, audit)

	item, err := uc.CreateUserModerationCase(ctx, actor, model.CreateUserModerationCaseParams{
		TargetUserID: targetUserID,
		Source:       model.UserModerationSourceStaff,
		ReasonCode:   "spam",
		Priority:     model.UserModerationPriorityNormal,
		StaffComment: "Repeated spam reports.",
	}, RequestMetadata{RequestID: "req-2", IPAddress: "127.0.0.1", UserAgent: "test"})

	if err != nil {
		t.Fatalf("CreateUserModerationCase returned error: %v", err)
	}
	if item.TargetUserID != targetUserID {
		t.Fatalf("target user id = %s, want %s", item.TargetUserID, targetUserID)
	}
	if len(audit.events) != 1 {
		t.Fatalf("audit events = %d, want 1", len(audit.events))
	}
	if audit.events[0].Action != "user_moderation.case.created" {
		t.Fatalf("audit action = %q", audit.events[0].Action)
	}
	if audit.events[0].EntityID == nil || *audit.events[0].EntityID != targetUserID {
		t.Fatalf("audit entity id = %v, want target user id", audit.events[0].EntityID)
	}
}

func TestCreateUserRestrictionRequiresReasonAndComment(t *testing.T) {
	ctx := context.Background()
	actor := &model.StaffUser{
		ID:          uuid.New(),
		Permissions: []enum.Permission{enum.PermissionUsersRestrict},
	}
	uc := NewUserModerationUseCase(&userAdminClientStub{}, &userModerationRepoStub{}, &userModerationAuditRepoStub{})

	_, err := uc.CreateUserRestriction(ctx, actor, model.CreateUserRestrictionParams{
		UserID:          uuid.New(),
		RestrictionCode: model.UserRestrictionChat,
		ReasonCode:      "spam",
	}, RequestMetadata{})

	if !errors.Is(err, ErrInvalidInput) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidInput)
	}
}

func TestCreateUserRestrictionNotifiesUser(t *testing.T) {
	ctx := context.Background()
	actor := &model.StaffUser{
		ID:          uuid.New(),
		Permissions: []enum.Permission{enum.PermissionUsersRestrict},
	}
	targetUserID := uuid.New()
	repo := &userModerationRepoStub{}
	notifications := make(chan port.UserNotificationInput, 1)
	uc := NewUserModerationUseCase(&userAdminClientStub{}, repo, &userModerationAuditRepoStub{})
	uc.SetNotificationGateway(adminNotificationGatewayStub{
		send: func(ctx context.Context, input port.UserNotificationInput) error {
			notifications <- input
			return nil
		},
	})

	item, err := uc.CreateUserRestriction(ctx, actor, model.CreateUserRestrictionParams{
		UserID:          targetUserID,
		RestrictionCode: model.UserRestrictionChat,
		ReasonCode:      "spam",
		StaffComment:    "Repeated spam reports.",
	}, RequestMetadata{RequestID: "req-restrict"})

	if err != nil {
		t.Fatalf("CreateUserRestriction() error = %v", err)
	}
	got := waitAdminNotification(t, notifications)
	if len(got.RecipientUserIDs) != 1 || got.RecipientUserIDs[0] != targetUserID {
		t.Fatalf("recipient user ids = %v, want user %s", got.RecipientUserIDs, targetUserID)
	}
	if got.Category != "account" || got.Priority != "high" {
		t.Fatalf("category/priority = %q/%q, want account/high", got.Category, got.Priority)
	}
	if got.DeepLink != "/notifications/account" {
		t.Fatalf("deep link = %q", got.DeepLink)
	}
	if got.IdempotencyKey == "" {
		t.Fatal("idempotency key must be set for restriction notification")
	}
	if got.Data["adminEvent"] != "user_restriction_created" ||
		got.Data["targetType"] != "USER" ||
		got.Data["targetId"] != targetUserID.String() ||
		got.Data["restrictionId"] != item.ID.String() ||
		got.Data["restrictionCode"] != string(model.UserRestrictionChat) ||
		got.Data["reasonCode"] != "spam" {
		t.Fatalf("notification data = %#v", got.Data)
	}
}

func TestPermanentBlockRequiresSeniorRole(t *testing.T) {
	ctx := context.Background()
	actor := &model.StaffUser{
		ID:          uuid.New(),
		Permissions: []enum.Permission{enum.PermissionUsersModerate},
		Roles:       []enum.StaffRole{enum.StaffRoleSupportViewer},
	}
	uc := NewUserModerationUseCase(&userAdminClientStub{}, &userModerationRepoStub{}, &userModerationAuditRepoStub{})

	_, err := uc.ResolveUserModerationCase(ctx, actor, model.ResolveUserModerationCaseParams{
		CaseID:       uuid.New(),
		ActorStaffID: actor.ID,
		Decision:     model.UserModerationDecisionPermanentBlock,
		ReasonCode:   "confirmed_fraud",
		StaffComment: "Confirmed ban evasion.",
	}, RequestMetadata{})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("error = %v, want %v", err, ErrPermissionDenied)
	}
}

type userAdminClientStub struct {
	page   model.AdminUserListPage
	detail model.AdminUserDetail
}

func (c *userAdminClientStub) ListAdminUsers(
	context.Context,
	model.AdminUserListFilter,
) (model.AdminUserListPage, error) {
	return c.page, nil
}

func (c *userAdminClientStub) GetAdminUserDetail(
	_ context.Context,
	userID uuid.UUID,
) (model.AdminUserDetail, error) {
	c.detail.UserID = userID
	return c.detail, nil
}

type userModerationRepoStub struct {
	cases        []model.UserModerationCase
	restrictions []model.UserManualRestriction
}

func (r *userModerationRepoStub) CreateUserModerationCase(
	_ context.Context,
	params model.CreateUserModerationCaseParams,
) (model.UserModerationCase, error) {
	item := model.UserModerationCase{
		ID:              uuid.New(),
		TargetUserID:    params.TargetUserID,
		Source:          params.Source,
		ReasonCode:      params.ReasonCode,
		Priority:        params.Priority,
		Status:          model.UserModerationStatusOpen,
		AssignedStaffID: params.AssignedStaffID,
		StaffComment:    params.StaffComment,
		CreatedAt:       time.Now().UTC(),
		UpdatedAt:       time.Now().UTC(),
	}
	r.cases = append(r.cases, item)
	return item, nil
}

func (r *userModerationRepoStub) GetUserModerationCase(
	context.Context,
	uuid.UUID,
) (model.UserModerationCase, error) {
	return model.UserModerationCase{}, nil
}

func (r *userModerationRepoStub) ListUserModerationCases(
	context.Context,
	uuid.UUID,
) ([]model.UserModerationCase, error) {
	return r.cases, nil
}

func (r *userModerationRepoStub) ResolveUserModerationCase(
	_ context.Context,
	params model.ResolveUserModerationCaseParams,
) (model.UserModerationCase, error) {
	decision := params.Decision
	item := model.UserModerationCase{
		ID:           params.CaseID,
		Status:       model.UserModerationStatusResolved,
		Decision:     &decision,
		ReasonCode:   params.ReasonCode,
		StaffComment: params.StaffComment,
		ResolvedAt:   timePtr(time.Now().UTC()),
	}
	return item, nil
}

func (r *userModerationRepoStub) CreateUserRestriction(
	_ context.Context,
	params model.CreateUserRestrictionParams,
) (model.UserManualRestriction, error) {
	item := model.UserManualRestriction{
		ID:               uuid.New(),
		UserID:           params.UserID,
		RestrictionCode:  params.RestrictionCode,
		Status:           model.UserRestrictionStatusActive,
		ReasonCode:       params.ReasonCode,
		StaffComment:     params.StaffComment,
		CreatedByStaffID: params.CreatedByStaffID,
		ExpiresAt:        params.ExpiresAt,
		CreatedAt:        time.Now().UTC(),
	}
	r.restrictions = append(r.restrictions, item)
	return item, nil
}

func (r *userModerationRepoStub) LiftUserRestriction(
	_ context.Context,
	params model.LiftUserRestrictionParams,
) (model.UserManualRestriction, error) {
	return model.UserManualRestriction{
		ID:              params.RestrictionID,
		Status:          model.UserRestrictionStatusLifted,
		LiftedByStaffID: &params.LiftedByStaffID,
		LiftedAt:        timePtr(time.Now().UTC()),
	}, nil
}

func (r *userModerationRepoStub) ListActiveUserRestrictions(
	context.Context,
	uuid.UUID,
) ([]model.UserManualRestriction, error) {
	return r.restrictions, nil
}

type userModerationAuditRepoStub struct {
	events []*model.AuditEvent
}

func (r *userModerationAuditRepoStub) Append(_ context.Context, event *model.AuditEvent) error {
	r.events = append(r.events, event)
	return nil
}

func (r *userModerationAuditRepoStub) List(context.Context, model.AuditFilter) ([]*model.AuditEvent, error) {
	return r.events, nil
}
