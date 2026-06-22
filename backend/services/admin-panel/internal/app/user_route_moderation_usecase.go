package app

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

type UserRouteModerationUseCase struct {
	routes port.UserRouteAdminClient
	audit  port.AuditRepository
}

func NewUserRouteModerationUseCase(
	routes port.UserRouteAdminClient,
	audit port.AuditRepository,
) *UserRouteModerationUseCase {
	return &UserRouteModerationUseCase{routes: routes, audit: audit}
}

func (u *UserRouteModerationUseCase) ListRoutes(
	ctx context.Context,
	actor *model.StaffUser,
	filter model.AdminUserRouteListFilter,
) ([]model.AdminUserRoute, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionModerationRead) {
		return nil, ErrPermissionDenied
	}
	if u.routes == nil {
		return nil, ErrIntegrationNotReady
	}
	filter = normalizeUserRouteListFilter(filter)
	return u.routes.ListUserRoutes(ctx, model.AdminUserRouteAdminListRequest{
		ActorUserID:      actor.ID.String(),
		ActorRoles:       userRouteGatewayRoles(actor),
		ModerationStatus: filter.ModerationStatus,
		OwnerUserID:      filter.OwnerUserID,
		CityCode:         filter.CityCode,
		Limit:            filter.Limit,
		Offset:           filter.Offset,
	})
}

func (u *UserRouteModerationUseCase) ReviewRoute(
	ctx context.Context,
	actor *model.StaffUser,
	input model.AdminUserRouteReviewInput,
	meta RequestMetadata,
) (*model.AdminUserRoute, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionModerationAssign) {
		return nil, ErrPermissionDenied
	}
	if u.routes == nil {
		return nil, ErrIntegrationNotReady
	}
	if input.RouteID == uuid.Nil {
		return nil, ErrInvalidInput
	}
	decision := model.NormalizeUserRouteReviewDecision(string(input.Decision))
	if !decision.IsValid() {
		return nil, ErrInvalidInput
	}
	reason := strings.TrimSpace(input.Reason)
	if (decision == model.UserRouteReviewReject || decision == model.UserRouteReviewHide) && reason == "" {
		return nil, ErrInvalidInput
	}
	item, err := u.routes.ReviewUserRoute(ctx, model.AdminUserRouteAdminReviewRequest{
		ActorUserID: actor.ID.String(),
		ActorRoles:  userRouteGatewayRoles(actor),
		RouteID:     input.RouteID,
		Decision:    decision,
		Reason:      reason,
	})
	if err != nil {
		return nil, err
	}
	u.appendUserRouteAudit(ctx, actor, userRouteReviewAuditAction(decision), input.RouteID, meta, map[string]any{
		"decision": decision,
		"reason":   reason,
	})
	return item, nil
}

func normalizeUserRouteListFilter(filter model.AdminUserRouteListFilter) model.AdminUserRouteListFilter {
	filter.ModerationStatus = model.NormalizeUserRouteModerationStatus(string(filter.ModerationStatus))
	filter.OwnerUserID = strings.TrimSpace(filter.OwnerUserID)
	filter.CityCode = strings.ToLower(strings.TrimSpace(filter.CityCode))
	filter.Limit = clampLimit(filter.Limit)
	filter.Offset = normalizeOffset(filter.Offset)
	return filter
}

func userRouteGatewayRoles(actor *model.StaffUser) []string {
	if actor == nil {
		return nil
	}
	if actor.HasRole(enum.StaffRoleSuperAdmin) || actor.HasRole(enum.StaffRoleAdmin) {
		return []string{"ADMIN"}
	}
	return []string{"MODERATOR"}
}

func userRouteReviewAuditAction(decision model.UserRouteReviewDecision) string {
	switch decision {
	case model.UserRouteReviewApprove:
		return "user_route.review.approved"
	case model.UserRouteReviewReject:
		return "user_route.review.rejected"
	case model.UserRouteReviewHide:
		return "user_route.review.hidden"
	default:
		return "user_route.review.unknown"
	}
}

func (u *UserRouteModerationUseCase) appendUserRouteAudit(
	ctx context.Context,
	actor *model.StaffUser,
	action string,
	routeID uuid.UUID,
	meta RequestMetadata,
	metadata map[string]any,
) {
	if u.audit == nil || actor == nil {
		return
	}
	_ = u.audit.Append(ctx, &model.AuditEvent{
		ID:               uuid.New(),
		ActorStaffID:     &actor.ID,
		ActorDisplayName: actor.DisplayName,
		ActorEmail:       actor.Email,
		Action:           action,
		EntityType:       "user_route",
		EntityID:         &routeID,
		RequestID:        strings.TrimSpace(meta.RequestID),
		IPAddressHash:    HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash:    HashPassiveIdentifier(meta.UserAgent),
		Metadata:         auditJSON(metadata),
		CreatedAt:        time.Now().UTC(),
	})
}
