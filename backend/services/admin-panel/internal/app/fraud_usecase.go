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

type FraudUseCase struct {
	client port.AntiFraudClient
	audit  port.AuditRepository
}

type ReviewFraudBlockInput struct {
	Actor           *model.StaffUser
	AssessmentID    uuid.UUID
	Status          model.FraudBlockReviewStatus
	ReasonCodes     []string
	InternalComment string
	RequestMetadata RequestMetadata
}

func NewFraudUseCase(client port.AntiFraudClient, audit port.AuditRepository) *FraudUseCase {
	return &FraudUseCase{client: client, audit: audit}
}

func (u *FraudUseCase) ListBlocks(ctx context.Context, actor *model.StaffUser, target model.FraudBlockTarget, limit int, offset int) ([]model.FraudBlock, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionModerationRead) {
		return nil, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return nil, ErrInvalidInput
	}
	target = normalizeFraudBlockTarget(target)
	if target == "" {
		return nil, ErrInvalidInput
	}
	return u.client.ListFraudBlocks(ctx, target, clampLimit(limit), normalizeOffset(offset))
}

func (u *FraudUseCase) ReviewBlock(ctx context.Context, input ReviewFraudBlockInput) (*model.FraudBlock, error) {
	if input.Actor == nil || !input.Actor.HasPermission(enum.PermissionFraudReview) {
		return nil, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return nil, ErrInvalidInput
	}
	status := normalizeFraudReviewStatus(input.Status)
	comment := strings.TrimSpace(input.InternalComment)
	if input.AssessmentID == uuid.Nil || status == "" || status == model.FraudBlockReviewStatusOpen || comment == "" {
		return nil, ErrInvalidInput
	}
	reasonCodes := normalizeReasonCodes(input.ReasonCodes)
	updated, err := u.client.ReviewFraudBlock(ctx, model.FraudBlockReviewInput{
		AssessmentID:      input.AssessmentID,
		Status:            status,
		ReviewedByStaffID: input.Actor.ID,
		ReasonCodes:       reasonCodes,
		Comment:           comment,
	})
	if err != nil {
		u.appendFraudAudit(ctx, input.Actor.ID, "fraud.block.review_failed", input.AssessmentID, input.RequestMetadata, map[string]any{
			"status": status,
			"error":  err.Error(),
		})
		return nil, err
	}
	u.appendFraudAudit(ctx, input.Actor.ID, fraudAuditAction(status), input.AssessmentID, input.RequestMetadata, map[string]any{
		"status":       status,
		"reasonCodes":  reasonCodes,
		"targetType":   updated.SubjectType,
		"targetId":     optionalUUIDString(updated.SubjectID),
		"decision":     updated.Decision,
		"riskScore":    updated.RiskScore,
		"fraudReasons": updated.Reasons,
	})
	return updated, nil
}

func normalizeFraudBlockTarget(target model.FraudBlockTarget) model.FraudBlockTarget {
	switch model.FraudBlockTarget(strings.ToUpper(strings.TrimSpace(string(target)))) {
	case model.FraudBlockTargetActivity:
		return model.FraudBlockTargetActivity
	case model.FraudBlockTargetExcursion:
		return model.FraudBlockTargetExcursion
	case model.FraudBlockTargetGuideApplication:
		return model.FraudBlockTargetGuideApplication
	default:
		return ""
	}
}

func normalizeFraudReviewStatus(status model.FraudBlockReviewStatus) model.FraudBlockReviewStatus {
	switch model.FraudBlockReviewStatus(strings.ToUpper(strings.TrimSpace(string(status)))) {
	case model.FraudBlockReviewStatusConfirmedFraud:
		return model.FraudBlockReviewStatusConfirmedFraud
	case model.FraudBlockReviewStatusFalsePositive:
		return model.FraudBlockReviewStatusFalsePositive
	case model.FraudBlockReviewStatusEscalated:
		return model.FraudBlockReviewStatusEscalated
	default:
		return ""
	}
}

func fraudAuditAction(status model.FraudBlockReviewStatus) string {
	switch status {
	case model.FraudBlockReviewStatusConfirmedFraud:
		return "fraud.block.confirmed"
	case model.FraudBlockReviewStatusFalsePositive:
		return "fraud.block.false_positive"
	case model.FraudBlockReviewStatusEscalated:
		return "fraud.block.escalated"
	default:
		return "fraud.block.reviewed"
	}
}

func optionalUUIDString(value *uuid.UUID) string {
	if value == nil {
		return ""
	}
	return value.String()
}

func (u *FraudUseCase) appendFraudAudit(
	ctx context.Context,
	actorID uuid.UUID,
	action string,
	assessmentID uuid.UUID,
	meta RequestMetadata,
	metadata map[string]any,
) {
	if u == nil || u.audit == nil {
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
		EntityType:    "fraud_assessment",
		EntityID:      &assessmentID,
		RequestID:     strings.TrimSpace(meta.RequestID),
		IPAddressHash: HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash: HashPassiveIdentifier(meta.UserAgent),
		Metadata:      metadataJSON,
		CreatedAt:     time.Now().UTC(),
	})
}
