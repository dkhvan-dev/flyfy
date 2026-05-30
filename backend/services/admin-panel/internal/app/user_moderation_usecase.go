package app

import (
	"context"
	"encoding/json"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/port"
)

type UserModerationUseCase struct {
	users port.UserAdminClient
	repo  port.UserModerationRepository
	audit port.AuditRepository
}

func NewUserModerationUseCase(
	users port.UserAdminClient,
	repo port.UserModerationRepository,
	audit port.AuditRepository,
) *UserModerationUseCase {
	return &UserModerationUseCase{users: users, repo: repo, audit: audit}
}

func (u *UserModerationUseCase) ListAdminUsers(
	ctx context.Context,
	actor *model.StaffUser,
	filter model.AdminUserListFilter,
) (model.AdminUserListPage, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionUsersRead) {
		return model.AdminUserListPage{}, ErrPermissionDenied
	}
	filter.PageSize = clampLimit(filter.PageSize)
	filter.Query = strings.TrimSpace(filter.Query)
	filter.Status = strings.TrimSpace(filter.Status)
	filter.Role = strings.TrimSpace(filter.Role)
	filter.CountryCode = strings.ToUpper(strings.TrimSpace(filter.CountryCode))
	return u.users.ListAdminUsers(ctx, filter)
}

func (u *UserModerationUseCase) GetAdminUserDetail(
	ctx context.Context,
	actor *model.StaffUser,
	userID uuid.UUID,
	meta RequestMetadata,
) (model.AdminUserDetailPage, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionUsersRead) {
		return model.AdminUserDetailPage{}, ErrPermissionDenied
	}
	if userID == uuid.Nil {
		return model.AdminUserDetailPage{}, ErrInvalidInput
	}

	detail, err := u.users.GetAdminUserDetail(ctx, userID)
	if err != nil {
		return model.AdminUserDetailPage{}, err
	}
	cases, err := u.repo.ListUserModerationCases(ctx, userID)
	if err != nil {
		return model.AdminUserDetailPage{}, err
	}
	restrictions, err := u.repo.ListActiveUserRestrictions(ctx, userID)
	if err != nil {
		return model.AdminUserDetailPage{}, err
	}

	u.appendUserAudit(ctx, actor.ID, "user.detail.viewed", userID, meta, nil)
	return model.AdminUserDetailPage{
		User:               detail,
		ModerationCases:    cases,
		ActiveRestrictions: restrictions,
	}, nil
}

func (u *UserModerationUseCase) CreateUserModerationCase(
	ctx context.Context,
	actor *model.StaffUser,
	params model.CreateUserModerationCaseParams,
	meta RequestMetadata,
) (model.UserModerationCase, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionUsersModerate) {
		return model.UserModerationCase{}, ErrPermissionDenied
	}
	if params.TargetUserID == uuid.Nil ||
		strings.TrimSpace(params.ReasonCode) == "" ||
		strings.TrimSpace(params.StaffComment) == "" {
		return model.UserModerationCase{}, ErrInvalidInput
	}
	if params.Source == "" {
		params.Source = model.UserModerationSourceStaff
	}
	if params.Priority == "" {
		params.Priority = model.UserModerationPriorityNormal
	}
	params.ReasonCode = strings.TrimSpace(params.ReasonCode)
	params.StaffComment = strings.TrimSpace(params.StaffComment)
	params.CreatedByStaffID = actor.ID

	item, err := u.repo.CreateUserModerationCase(ctx, params)
	if err != nil {
		return model.UserModerationCase{}, err
	}
	u.appendUserAudit(ctx, actor.ID, "user_moderation.case.created", params.TargetUserID, meta, map[string]any{
		"caseId":     item.ID,
		"reasonCode": params.ReasonCode,
		"priority":   params.Priority,
	})
	return item, nil
}

func (u *UserModerationUseCase) ResolveUserModerationCase(
	ctx context.Context,
	actor *model.StaffUser,
	params model.ResolveUserModerationCaseParams,
	meta RequestMetadata,
) (model.UserModerationCase, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionUsersModerate) {
		return model.UserModerationCase{}, ErrPermissionDenied
	}
	if params.CaseID == uuid.Nil ||
		strings.TrimSpace(params.ReasonCode) == "" ||
		strings.TrimSpace(params.StaffComment) == "" {
		return model.UserModerationCase{}, ErrInvalidInput
	}
	if params.Decision == model.UserModerationDecisionPermanentBlock && !isSeniorUserModerator(actor) {
		return model.UserModerationCase{}, ErrPermissionDenied
	}

	existing, err := u.repo.GetUserModerationCase(ctx, params.CaseID)
	if err != nil {
		return model.UserModerationCase{}, err
	}
	if existing.ID == uuid.Nil {
		return model.UserModerationCase{}, ErrInvalidInput
	}

	params.ActorStaffID = actor.ID
	params.ReasonCode = strings.TrimSpace(params.ReasonCode)
	params.StaffComment = strings.TrimSpace(params.StaffComment)
	item, err := u.repo.ResolveUserModerationCase(ctx, params)
	if err != nil {
		return model.UserModerationCase{}, err
	}
	u.appendUserAudit(ctx, actor.ID, "user_moderation.case.resolved", existing.TargetUserID, meta, map[string]any{
		"caseId":     params.CaseID,
		"decision":   params.Decision,
		"reasonCode": params.ReasonCode,
	})
	return item, nil
}

func (u *UserModerationUseCase) CreateUserRestriction(
	ctx context.Context,
	actor *model.StaffUser,
	params model.CreateUserRestrictionParams,
	meta RequestMetadata,
) (model.UserManualRestriction, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionUsersRestrict) {
		return model.UserManualRestriction{}, ErrPermissionDenied
	}
	if params.UserID == uuid.Nil ||
		params.RestrictionCode == "" ||
		strings.TrimSpace(params.ReasonCode) == "" ||
		strings.TrimSpace(params.StaffComment) == "" {
		return model.UserManualRestriction{}, ErrInvalidInput
	}
	params.CreatedByStaffID = actor.ID
	params.ReasonCode = strings.TrimSpace(params.ReasonCode)
	params.StaffComment = strings.TrimSpace(params.StaffComment)

	item, err := u.repo.CreateUserRestriction(ctx, params)
	if err != nil {
		return model.UserManualRestriction{}, err
	}
	u.appendUserAudit(ctx, actor.ID, "user_moderation.restriction.created", params.UserID, meta, map[string]any{
		"restrictionId":   item.ID,
		"restrictionCode": params.RestrictionCode,
		"reasonCode":      params.ReasonCode,
	})
	return item, nil
}

func (u *UserModerationUseCase) LiftUserRestriction(
	ctx context.Context,
	actor *model.StaffUser,
	params model.LiftUserRestrictionParams,
	meta RequestMetadata,
) (model.UserManualRestriction, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionUsersRestrict) {
		return model.UserManualRestriction{}, ErrPermissionDenied
	}
	if params.RestrictionID == uuid.Nil ||
		strings.TrimSpace(params.ReasonCode) == "" ||
		strings.TrimSpace(params.StaffComment) == "" {
		return model.UserManualRestriction{}, ErrInvalidInput
	}
	params.LiftedByStaffID = actor.ID
	params.ReasonCode = strings.TrimSpace(params.ReasonCode)
	params.StaffComment = strings.TrimSpace(params.StaffComment)

	item, err := u.repo.LiftUserRestriction(ctx, params)
	if err != nil {
		return model.UserManualRestriction{}, err
	}
	u.appendUserAudit(ctx, actor.ID, "user_moderation.restriction.lifted", item.UserID, meta, map[string]any{
		"restrictionId": params.RestrictionID,
		"reasonCode":    params.ReasonCode,
	})
	return item, nil
}

func isSeniorUserModerator(actor *model.StaffUser) bool {
	return actor.HasRole(enum.StaffRoleSuperAdmin) ||
		actor.HasRole(enum.StaffRoleAdmin) ||
		actor.HasRole(enum.StaffRoleModerationLead)
}

func (u *UserModerationUseCase) appendUserAudit(
	ctx context.Context,
	actorID uuid.UUID,
	action string,
	userID uuid.UUID,
	meta RequestMetadata,
	metadata map[string]any,
) {
	if u.audit == nil {
		return
	}
	var metadataJSON []byte
	if metadata != nil {
		metadataJSON, _ = json.Marshal(metadata)
	}
	_ = u.audit.Append(ctx, &model.AuditEvent{
		ID:            uuid.New(),
		ActorStaffID:  &actorID,
		Action:        action,
		EntityType:    "user",
		EntityID:      &userID,
		RequestID:     strings.TrimSpace(meta.RequestID),
		IPAddressHash: HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash: HashPassiveIdentifier(meta.UserAgent),
		Metadata:      metadataJSON,
		CreatedAt:     time.Now().UTC(),
	})
}
