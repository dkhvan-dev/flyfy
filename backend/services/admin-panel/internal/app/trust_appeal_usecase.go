package app

import (
	"context"
	"encoding/json"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

type TrustAppealUseCase struct {
	client port.TrustRestrictionAppealClient
	audit  port.AuditRepository
}

func NewTrustAppealUseCase(
	client port.TrustRestrictionAppealClient,
	audit port.AuditRepository,
) *TrustAppealUseCase {
	return &TrustAppealUseCase{client: client, audit: audit}
}

func (u *TrustAppealUseCase) ListRestrictionAppeals(
	ctx context.Context,
	actor *model.StaffUser,
	filter model.TrustRestrictionAppealFilter,
) (model.TrustRestrictionAppealListPage, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionUsersRead) {
		return model.TrustRestrictionAppealListPage{}, ErrPermissionDenied
	}
	if u.client == nil {
		return model.TrustRestrictionAppealListPage{}, ErrIntegrationNotReady
	}
	filter.Query = strings.TrimSpace(filter.Query)
	filter.PageSize = clampLimit(filter.PageSize)
	filter.PageToken = strings.TrimSpace(filter.PageToken)
	filter.Status = normalizeTrustAppealStatus(filter.Status)
	return u.client.ListRestrictionAppeals(ctx, filter)
}

func (u *TrustAppealUseCase) GetRestrictionAppeal(
	ctx context.Context,
	actor *model.StaffUser,
	appealID uuid.UUID,
	meta RequestMetadata,
) (model.TrustRestrictionAppeal, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionUsersRead) {
		return model.TrustRestrictionAppeal{}, ErrPermissionDenied
	}
	if appealID == uuid.Nil {
		return model.TrustRestrictionAppeal{}, ErrInvalidInput
	}
	if u.client == nil {
		return model.TrustRestrictionAppeal{}, ErrIntegrationNotReady
	}
	item, err := u.client.GetRestrictionAppeal(ctx, appealID)
	if err != nil {
		return model.TrustRestrictionAppeal{}, err
	}
	u.appendTrustAppealAudit(ctx, actor.ID, "trust.appeal.viewed", appealID, meta, map[string]any{
		"userId":        item.UserID,
		"restrictionId": item.RestrictionID,
	})
	return item, nil
}

func (u *TrustAppealUseCase) DecideRestrictionAppeal(
	ctx context.Context,
	actor *model.StaffUser,
	input model.TrustRestrictionAppealDecisionInput,
	meta RequestMetadata,
) (model.TrustRestrictionAppeal, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionUsersRestrict) {
		return model.TrustRestrictionAppeal{}, ErrPermissionDenied
	}
	if u.client == nil {
		return model.TrustRestrictionAppeal{}, ErrIntegrationNotReady
	}
	input.Decision = normalizeTrustAppealDecision(input.Decision)
	input.ReasonCode = strings.TrimSpace(input.ReasonCode)
	input.StaffComment = strings.TrimSpace(input.StaffComment)
	input.IdempotencyKey = strings.TrimSpace(input.IdempotencyKey)
	input.RequestID = strings.TrimSpace(meta.RequestID)
	if input.AppealID == uuid.Nil ||
		input.Decision == "" ||
		input.ReasonCode == "" ||
		input.StaffComment == "" {
		return model.TrustRestrictionAppeal{}, ErrInvalidInput
	}
	if input.IdempotencyKey == "" {
		input.IdempotencyKey = uuid.NewString()
	}
	input.ActorStaffID = actor.ID

	item, err := u.client.DecideRestrictionAppeal(ctx, input)
	if err != nil {
		u.appendTrustAppealAudit(ctx, actor.ID, "trust.appeal.decision_failed", input.AppealID, meta, map[string]any{
			"decision":   input.Decision,
			"reasonCode": input.ReasonCode,
			"error":      err.Error(),
		})
		return model.TrustRestrictionAppeal{}, err
	}
	u.appendTrustAppealAudit(ctx, actor.ID, "trust.appeal.decided", input.AppealID, meta, map[string]any{
		"decision":      input.Decision,
		"reasonCode":    input.ReasonCode,
		"userId":        item.UserID,
		"restrictionId": item.RestrictionID,
	})
	return item, nil
}

func normalizeTrustAppealStatus(status model.TrustRestrictionAppealStatus) model.TrustRestrictionAppealStatus {
	switch status {
	case model.TrustRestrictionAppealStatusApproved,
		model.TrustRestrictionAppealStatusRejected:
		return status
	default:
		return model.TrustRestrictionAppealStatusOpen
	}
}

func normalizeTrustAppealDecision(decision model.TrustRestrictionAppealDecision) model.TrustRestrictionAppealDecision {
	switch decision {
	case model.TrustRestrictionAppealDecisionApprove,
		model.TrustRestrictionAppealDecisionReject:
		return decision
	default:
		return ""
	}
}

func (u *TrustAppealUseCase) appendTrustAppealAudit(
	ctx context.Context,
	actorID uuid.UUID,
	action string,
	appealID uuid.UUID,
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
		EntityType:    "trust_restriction_appeal",
		EntityID:      &appealID,
		RequestID:     strings.TrimSpace(meta.RequestID),
		IPAddressHash: HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash: HashPassiveIdentifier(meta.UserAgent),
		Metadata:      metadataJSON,
		CreatedAt:     time.Now().UTC(),
	})
}
