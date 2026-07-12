package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/trust-service/internal/domain/model"
	"kz/inflap/backend/services/trust-service/internal/domain/port"
)

const (
	defaultTrustScore = 500

	reasonAllowed                  = "allowed"
	reasonRiskyBand                = "trust_band_risky"
	reasonBlockedBand              = "trust_band_blocked"
	reasonAccountSuspension        = "account_suspension"
	publicMessageAllowed           = "trust.policy.allowed"
	publicMessageRestricted        = "trust.policy.restricted"
	publicMessageNeedsReview       = "trust.policy.needs_review"
	publicMessageQuarantined       = "trust.policy.quarantined"
	publicMessageTemporarilyDenied = "trust.policy.temporarily_denied"
	maxAppealReasonCodeLength      = 80
	maxAppealMessageLength         = 2000
	maxAppealIdempotencyKeyLength  = 128
	maxAppealStaffCommentLength    = 2000
)

type PolicyUseCase struct {
	repo port.TrustRepository
}

func NewPolicyUseCase(repo port.TrustRepository) *PolicyUseCase {
	return &PolicyUseCase{repo: repo}
}

func (u *PolicyUseCase) CheckActionPolicy(ctx context.Context, input model.PolicyCheckInput) (model.PolicyDecisionRecord, error) {
	if u == nil || u.repo == nil {
		return model.PolicyDecisionRecord{}, fmt.Errorf("%w: trust repository is required", ErrInvalidInput)
	}
	if input.UserID == uuid.Nil {
		return model.PolicyDecisionRecord{}, fmt.Errorf("%w: user id is required", ErrInvalidInput)
	}
	if !isSupportedAction(input.Action) {
		return model.PolicyDecisionRecord{}, fmt.Errorf("%w: unsupported policy action", ErrInvalidInput)
	}

	now := input.RequestedAt
	if now.IsZero() {
		now = time.Now().UTC()
	} else {
		now = now.UTC()
	}

	profile, err := u.GetTrustProfile(ctx, input.UserID)
	if err != nil {
		return model.PolicyDecisionRecord{}, err
	}

	restrictions, err := u.repo.ListActiveRestrictions(ctx, input.UserID, now)
	if err != nil {
		return model.PolicyDecisionRecord{}, err
	}

	decision, reasonCode, publicMessageKey, internalMessage, restrictionIDs := evaluatePolicy(input.Action, profile, restrictions)
	record := model.PolicyDecisionRecord{
		ID:               uuid.New(),
		UserID:           input.UserID,
		Action:           input.Action,
		ResourceType:     input.ResourceType,
		ResourceID:       input.ResourceID,
		IdempotencyKey:   input.IdempotencyKey,
		Decision:         decision,
		ReasonCode:       reasonCode,
		PublicMessageKey: publicMessageKey,
		InternalMessage:  internalMessage,
		TrustBand:        profile.Band,
		Score:            profile.Score,
		RestrictionIDs:   restrictionIDs,
		CreatedAt:        now,
	}
	if err := u.repo.SavePolicyDecision(ctx, record); err != nil {
		return model.PolicyDecisionRecord{}, err
	}
	return record, nil
}

func (u *PolicyUseCase) ApplyUserRestrictionEvent(ctx context.Context, input model.RestrictionEventInput) (bool, error) {
	if u == nil || u.repo == nil {
		return false, fmt.Errorf("%w: trust repository is required", ErrInvalidInput)
	}
	if input.EventID == uuid.Nil {
		return false, fmt.Errorf("%w: event id is required", ErrInvalidInput)
	}
	if input.RestrictionID == uuid.Nil {
		return false, fmt.Errorf("%w: restriction id is required", ErrInvalidInput)
	}
	if input.UserID == uuid.Nil {
		return false, fmt.Errorf("%w: user id is required", ErrInvalidInput)
	}
	if input.EventType != model.RestrictionEventTypeCreated && input.EventType != model.RestrictionEventTypeLifted {
		return false, fmt.Errorf("%w: unsupported restriction event type", ErrInvalidInput)
	}
	if input.RestrictionCode == "" && input.EventType == model.RestrictionEventTypeCreated {
		return false, fmt.Errorf("%w: restriction code is required", ErrInvalidInput)
	}

	processed, err := u.repo.HasProcessedEvent(ctx, input.EventID)
	if err != nil {
		return false, err
	}
	if processed {
		return false, nil
	}

	occurredAt := input.OccurredAt
	if occurredAt.IsZero() {
		occurredAt = time.Now().UTC()
	} else {
		occurredAt = occurredAt.UTC()
	}

	switch input.EventType {
	case model.RestrictionEventTypeCreated:
		restriction := model.RuntimeRestriction{
			ID:               input.RestrictionID,
			UserID:           input.UserID,
			CaseID:           input.CaseID,
			RestrictionCode:  input.RestrictionCode,
			Status:           model.RuntimeRestrictionActive,
			ReasonCode:       input.ReasonCode,
			SourceEventID:    input.EventID,
			CreatedByStaffID: input.CreatedByStaffID,
			ExpiresAt:        input.ExpiresAt,
			CreatedAt:        occurredAt,
		}
		if err := u.repo.UpsertRuntimeRestriction(ctx, restriction); err != nil {
			return false, err
		}
		if err := u.setProfileStatus(ctx, input.UserID, model.TrustStatusRestricted, occurredAt); err != nil {
			return false, err
		}
	case model.RestrictionEventTypeLifted:
		if err := u.repo.LiftRuntimeRestriction(ctx, input.RestrictionID, input.EventID, input.LiftedByStaffID, occurredAt, input.ReasonCode); err != nil {
			return false, err
		}
	}

	if err := u.repo.MarkProcessedEvent(ctx, input.EventID, input.EventType, occurredAt); err != nil {
		return false, err
	}
	return true, nil
}

func (u *PolicyUseCase) SubmitRestrictionAppeal(ctx context.Context, input model.SubmitRestrictionAppealInput) (model.RestrictionAppeal, error) {
	if u == nil || u.repo == nil {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: trust repository is required", ErrInvalidInput)
	}
	if input.UserID == uuid.Nil {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: user id is required", ErrInvalidInput)
	}
	if input.RestrictionID == uuid.Nil {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: restriction id is required", ErrInvalidInput)
	}
	reasonCode := strings.TrimSpace(input.ReasonCode)
	userMessage := strings.TrimSpace(input.UserMessage)
	idempotencyKey := strings.TrimSpace(input.IdempotencyKey)
	if reasonCode == "" || userMessage == "" {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: appeal reason and message are required", ErrInvalidInput)
	}
	if len(reasonCode) > maxAppealReasonCodeLength ||
		len(userMessage) > maxAppealMessageLength ||
		len(idempotencyKey) > maxAppealIdempotencyKeyLength {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: appeal fields are too long", ErrInvalidInput)
	}

	restriction, err := u.repo.GetRuntimeRestrictionByID(ctx, input.RestrictionID)
	if err != nil {
		return model.RestrictionAppeal{}, err
	}
	if restriction.UserID != input.UserID || restriction.Status != model.RuntimeRestrictionActive {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: active restriction is required", ErrInvalidInput)
	}

	now := input.SubmittedAt
	if now.IsZero() {
		now = time.Now().UTC()
	} else {
		now = now.UTC()
	}
	appeal := model.RestrictionAppeal{
		ID:             uuid.New(),
		UserID:         input.UserID,
		RestrictionID:  input.RestrictionID,
		Status:         model.RestrictionAppealStatusPending,
		ReasonCode:     reasonCode,
		UserMessage:    userMessage,
		IdempotencyKey: idempotencyKey,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
	stored, err := u.repo.CreateRestrictionAppeal(ctx, appeal)
	if err != nil {
		return model.RestrictionAppeal{}, err
	}
	if err := u.setProfileStatus(ctx, input.UserID, model.TrustStatusUnderReview, now); err != nil {
		return model.RestrictionAppeal{}, err
	}
	return stored, nil
}

func (u *PolicyUseCase) DecideRestrictionAppeal(ctx context.Context, input model.DecideRestrictionAppealInput) (model.RestrictionAppeal, error) {
	if u == nil || u.repo == nil {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: trust repository is required", ErrInvalidInput)
	}
	if input.AppealID == uuid.Nil {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: appeal id is required", ErrInvalidInput)
	}
	if input.ActorStaffID == uuid.Nil {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: actor staff id is required", ErrInvalidInput)
	}
	if input.Decision != model.RestrictionAppealDecisionApprove && input.Decision != model.RestrictionAppealDecisionReject {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: unsupported appeal decision", ErrInvalidInput)
	}
	reasonCode := strings.TrimSpace(input.ReasonCode)
	staffComment := strings.TrimSpace(input.StaffComment)
	if reasonCode == "" || staffComment == "" {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: decision reason and staff comment are required", ErrInvalidInput)
	}
	if len(reasonCode) > maxAppealReasonCodeLength || len(staffComment) > maxAppealStaffCommentLength {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: appeal decision fields are too long", ErrInvalidInput)
	}

	appeal, err := u.repo.GetRestrictionAppeal(ctx, input.AppealID)
	if err != nil {
		return model.RestrictionAppeal{}, err
	}
	if appeal.Status != model.RestrictionAppealStatusPending {
		return model.RestrictionAppeal{}, fmt.Errorf("%w: appeal already decided", ErrInvalidInput)
	}

	now := input.DecidedAt
	if now.IsZero() {
		now = time.Now().UTC()
	} else {
		now = now.UTC()
	}
	appeal.UpdatedAt = now
	appeal.DecidedAt = &now
	appeal.DecidedByStaffID = &input.ActorStaffID
	appeal.DecisionReasonCode = reasonCode
	appeal.StaffComment = staffComment
	if input.Decision == model.RestrictionAppealDecisionApprove {
		appeal.Status = model.RestrictionAppealStatusApproved
		eventID := input.DecisionEventID
		if eventID == uuid.Nil {
			eventID = uuid.New()
		}
		if err := u.repo.LiftRuntimeRestriction(ctx, appeal.RestrictionID, eventID, &input.ActorStaffID, now, reasonCode); err != nil {
			return model.RestrictionAppeal{}, err
		}
	} else {
		appeal.Status = model.RestrictionAppealStatusRejected
	}

	stored, err := u.repo.SaveRestrictionAppealDecision(ctx, appeal)
	if err != nil {
		return model.RestrictionAppeal{}, err
	}
	if err := u.refreshProfileStatusFromActiveRestrictions(ctx, appeal.UserID, now); err != nil {
		return model.RestrictionAppeal{}, err
	}
	return stored, nil
}

func (u *PolicyUseCase) ListRestrictionAppeals(ctx context.Context, input model.ListRestrictionAppealsInput) ([]model.RestrictionAppeal, error) {
	if u == nil || u.repo == nil {
		return nil, fmt.Errorf("%w: trust repository is required", ErrInvalidInput)
	}
	if input.UserID != nil && *input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user id is required", ErrInvalidInput)
	}
	if input.Status != "" && !isSupportedRestrictionAppealStatus(input.Status) {
		return nil, fmt.Errorf("%w: unsupported appeal status", ErrInvalidInput)
	}
	if input.Status == "" && input.UserID == nil {
		return nil, fmt.Errorf("%w: status or user id filter is required", ErrInvalidInput)
	}
	return u.repo.ListRestrictionAppeals(ctx, input)
}

func (u *PolicyUseCase) GetTrustProfile(ctx context.Context, userID uuid.UUID) (model.TrustProfile, error) {
	if u == nil || u.repo == nil {
		return model.TrustProfile{}, fmt.Errorf("%w: trust repository is required", ErrInvalidInput)
	}
	if userID == uuid.Nil {
		return model.TrustProfile{}, fmt.Errorf("%w: user id is required", ErrInvalidInput)
	}

	profile, err := u.repo.GetTrustProfile(ctx, userID)
	if err == nil {
		return profile, nil
	}
	if !errors.Is(err, port.ErrNotFound) {
		return model.TrustProfile{}, err
	}

	now := time.Now().UTC()
	profile = model.TrustProfile{
		UserID:       userID,
		Score:        defaultTrustScore,
		Band:         model.TrustBandNew,
		Status:       model.TrustStatusActive,
		CalculatedAt: now,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	if err := u.repo.UpsertTrustProfile(ctx, profile); err != nil {
		return model.TrustProfile{}, err
	}
	return profile, nil
}

func (u *PolicyUseCase) GetTrustContext(ctx context.Context, userID uuid.UUID) (model.TrustContext, error) {
	profile, err := u.GetTrustProfile(ctx, userID)
	if err != nil {
		return model.TrustContext{}, err
	}
	restrictions, err := u.repo.ListActiveRestrictions(ctx, userID, time.Now().UTC())
	if err != nil {
		return model.TrustContext{}, err
	}
	return model.TrustContext{
		Profile:            profile,
		ActiveRestrictions: restrictions,
	}, nil
}

func (u *PolicyUseCase) setProfileStatus(ctx context.Context, userID uuid.UUID, status model.TrustStatus, now time.Time) error {
	profile, err := u.GetTrustProfile(ctx, userID)
	if err != nil {
		return err
	}
	profile.Status = status
	profile.UpdatedAt = now
	return u.repo.UpsertTrustProfile(ctx, profile)
}

func (u *PolicyUseCase) refreshProfileStatusFromActiveRestrictions(ctx context.Context, userID uuid.UUID, now time.Time) error {
	restrictions, err := u.repo.ListActiveRestrictions(ctx, userID, now)
	if err != nil {
		return err
	}
	status := model.TrustStatusActive
	if len(restrictions) > 0 {
		status = model.TrustStatusRestricted
	}
	return u.setProfileStatus(ctx, userID, status, now)
}

func evaluatePolicy(action model.PolicyAction, profile model.TrustProfile, restrictions []model.RuntimeRestriction) (model.PolicyDecision, string, string, string, []uuid.UUID) {
	for _, restriction := range restrictions {
		if restriction.RestrictionCode == model.RestrictionCodeAccountSuspension && isRiskyAction(action) {
			return restrictedDecision(restriction, reasonAccountSuspension, "user has an active account suspension")
		}
		if restrictionApplies(restriction.RestrictionCode, action) {
			reason := restriction.ReasonCode
			if reason == "" {
				reason = restrictionReasonCode(restriction.RestrictionCode)
			}
			return restrictedDecision(restriction, reason, "user has an active action restriction")
		}
	}

	switch profile.Band {
	case model.TrustBandBlocked:
		if isRiskyAction(action) {
			return model.PolicyDecisionDeny, reasonBlockedBand, publicMessageRestricted, "user trust band blocks risky action", nil
		}
	case model.TrustBandRisky:
		switch action {
		case model.PolicyActionActivityCreate, model.PolicyActionTourPublish, model.PolicyActionGuideApplicationSubmit:
			return model.PolicyDecisionReview, reasonRiskyBand, publicMessageNeedsReview, "risky trust band requires manual review", nil
		case model.PolicyActionChatSend, model.PolicyActionFileUpload, model.PolicyActionFileBind:
			return model.PolicyDecisionQuarantine, reasonRiskyBand, publicMessageQuarantined, "risky trust band requires quarantine", nil
		case model.PolicyActionPayoutRequest:
			return model.PolicyDecisionDeny, reasonRiskyBand, publicMessageTemporarilyDenied, "risky trust band blocks payout request", nil
		}
	}

	return model.PolicyDecisionAllow, reasonAllowed, publicMessageAllowed, "policy allowed action", nil
}

func restrictedDecision(restriction model.RuntimeRestriction, reasonCode string, internalMessage string) (model.PolicyDecision, string, string, string, []uuid.UUID) {
	return model.PolicyDecisionDeny, reasonCode, publicMessageRestricted, internalMessage, []uuid.UUID{restriction.ID}
}

func restrictionApplies(code string, action model.PolicyAction) bool {
	switch code {
	case model.RestrictionCodeChat:
		return action == model.PolicyActionChatSend
	case model.RestrictionCodeActivityCreation:
		return action == model.PolicyActionActivityCreate
	case model.RestrictionCodeTourPublishing:
		return action == model.PolicyActionTourPublish
	case model.RestrictionCodeFileUpload:
		return action == model.PolicyActionFileUpload || action == model.PolicyActionFileBind
	case model.RestrictionCodePayout:
		return action == model.PolicyActionPayoutRequest
	case model.RestrictionCodeGuideApplication:
		return action == model.PolicyActionGuideApplicationSubmit
	default:
		return false
	}
}

func restrictionReasonCode(code string) string {
	switch code {
	case model.RestrictionCodeChat:
		return "restriction_chat"
	case model.RestrictionCodeActivityCreation:
		return "restriction_activity_creation"
	case model.RestrictionCodeTourPublishing:
		return "restriction_tour_publishing"
	case model.RestrictionCodeFileUpload:
		return "restriction_file_upload"
	case model.RestrictionCodePayout:
		return "restriction_payout"
	case model.RestrictionCodeGuideApplication:
		return "restriction_guide_application"
	case model.RestrictionCodeAccountSuspension:
		return reasonAccountSuspension
	default:
		return "restriction_active"
	}
}

func isSupportedAction(action model.PolicyAction) bool {
	switch action {
	case model.PolicyActionActivityCreate,
		model.PolicyActionTourPublish,
		model.PolicyActionChatSend,
		model.PolicyActionFileUpload,
		model.PolicyActionFileBind,
		model.PolicyActionPayoutRequest,
		model.PolicyActionGuideApplicationSubmit:
		return true
	default:
		return false
	}
}

func isRiskyAction(action model.PolicyAction) bool {
	return isSupportedAction(action)
}

func isSupportedRestrictionAppealStatus(status model.RestrictionAppealStatus) bool {
	switch status {
	case model.RestrictionAppealStatusPending,
		model.RestrictionAppealStatusApproved,
		model.RestrictionAppealStatusRejected:
		return true
	default:
		return false
	}
}
