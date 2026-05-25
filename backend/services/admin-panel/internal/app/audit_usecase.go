package app

import (
	"context"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/port"
)

type AuditUseCase struct {
	audit port.AuditRepository
}

func NewAuditUseCase(audit port.AuditRepository) *AuditUseCase {
	return &AuditUseCase{audit: audit}
}

func (u *AuditUseCase) List(ctx context.Context, actor *model.StaffUser, filter model.AuditFilter) ([]*model.AuditEvent, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionAuditRead) {
		return nil, ErrPermissionDenied
	}
	filter.Limit = clampLimit(filter.Limit)
	filter.Offset = normalizeOffset(filter.Offset)
	return u.audit.List(ctx, filter)
}

func (u *AuditUseCase) ListOwn(ctx context.Context, actor *model.StaffUser, filter model.AuditFilter) ([]*model.AuditEvent, error) {
	if actor == nil {
		return nil, ErrPermissionDenied
	}
	filter.ActorStaffID = &actor.ID
	filter.Limit = clampLimit(filter.Limit)
	filter.Offset = normalizeOffset(filter.Offset)
	return u.audit.List(ctx, filter)
}
