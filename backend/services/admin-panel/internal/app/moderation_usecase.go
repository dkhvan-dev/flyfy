package app

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

type ModerationUseCase struct {
	repo      port.ModerationRepository
	excursion port.ExcursionClient
	activity  port.ActivityClient
	guide     port.GuideApplicationClient
	chat      port.ChatClient
	audit     port.AuditRepository
	notify    port.UserNotificationGateway
}

type ModerationDashboard struct {
	PendingExcursions int
	AssignedToMe      int
	ApprovedToday     int
	RejectedToday     int
}

type ModerationDecisionInput struct {
	Actor           *model.StaffUser
	CaseID          uuid.UUID
	Decision        enum.ModerationDecisionType
	ReasonCodes     []string
	PublicComment   string
	InternalComment string
	IdempotencyKey  string
	RequestMetadata RequestMetadata
}

type RevokeActiveGuideInput struct {
	Actor           *model.StaffUser
	GuideProfileID  uuid.UUID
	ReasonCodes     []string
	PublicComment   string
	InternalComment string
	IdempotencyKey  string
	RequestMetadata RequestMetadata
}

type ModerationCaseDetail struct {
	Case             *model.ModerationCase
	Excursion        *model.ExcursionModerationItem
	Activity         *model.ActivityModerationItem
	GuideApplication *model.GuideApplicationModerationItem
	ChatMessage      *model.ChatMessageModerationItem
	Decisions        []*model.ModerationDecision
}

func NewModerationUseCase(
	repo port.ModerationRepository,
	excursion port.ExcursionClient,
	activity port.ActivityClient,
	guide port.GuideApplicationClient,
	chat port.ChatClient,
	audit port.AuditRepository,
) *ModerationUseCase {
	return &ModerationUseCase{repo: repo, excursion: excursion, activity: activity, guide: guide, chat: chat, audit: audit}
}

func (u *ModerationUseCase) SyncExcursionQueue(ctx context.Context, actor *model.StaffUser) error {
	if actor == nil || !actor.HasPermission(enum.PermissionModerationRead) {
		return ErrPermissionDenied
	}
	items, err := u.excursion.ListPendingReview(ctx, 100, 0)
	if err != nil {
		return err
	}
	activeIDs := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		if _, err = u.repo.UpsertExcursionCase(ctx, item); err != nil {
			return err
		}
		activeIDs = append(activeIDs, item.ID)
	}
	return u.repo.CancelStaleExcursionCases(ctx, activeIDs, time.Now().UTC())
}

func (u *ModerationUseCase) SyncActivityQueue(ctx context.Context, actor *model.StaffUser) error {
	if actor == nil || !actor.HasPermission(enum.PermissionModerationRead) {
		return ErrPermissionDenied
	}
	items, err := u.activity.ListFlagged(ctx, 100, 0)
	if err != nil {
		return err
	}
	activeIDs := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		if _, err = u.repo.UpsertActivityCase(ctx, item); err != nil {
			return err
		}
		activeIDs = append(activeIDs, item.ID)
	}
	return u.repo.CancelStaleActivityCases(ctx, activeIDs, time.Now().UTC())
}

func (u *ModerationUseCase) SyncGuideApplicationQueue(ctx context.Context, actor *model.StaffUser) error {
	if actor == nil || !actor.HasPermission(enum.PermissionModerationRead) {
		return ErrPermissionDenied
	}
	items, err := u.guide.ListPendingApplications(ctx, 100, 0)
	if err != nil {
		return err
	}
	activeIDs := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		if _, err = u.repo.UpsertGuideApplicationCase(ctx, item); err != nil {
			return err
		}
		activeIDs = append(activeIDs, item.ID)
	}
	return u.repo.CancelStaleGuideApplicationCases(ctx, activeIDs, time.Now().UTC())
}

func (u *ModerationUseCase) SyncChatMessageQueue(ctx context.Context, actor *model.StaffUser) error {
	if actor == nil || !actor.HasPermission(enum.PermissionModerationRead) {
		return ErrPermissionDenied
	}
	items, err := u.chat.ListFlaggedMessages(ctx, 100, 0)
	if err != nil {
		return err
	}
	activeIDs := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		if _, err = u.repo.UpsertChatMessageCase(ctx, item); err != nil {
			return err
		}
		activeIDs = append(activeIDs, item.ID)
	}
	return u.repo.CancelStaleChatMessageCases(ctx, activeIDs, time.Now().UTC())
}

func (u *ModerationUseCase) ListActiveGuides(ctx context.Context, actor *model.StaffUser, limit int, offset int) ([]model.GuideApplicationModerationItem, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionGuideModerate) {
		return nil, ErrPermissionDenied
	}
	return u.guide.ListActiveGuides(ctx, clampLimit(limit), normalizeOffset(offset))
}

func (u *ModerationUseCase) ListQueue(ctx context.Context, actor *model.StaffUser, filter model.ModerationQueueFilter) ([]*model.ModerationCase, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionModerationRead) {
		return nil, ErrPermissionDenied
	}
	filter.Limit = clampLimit(filter.Limit)
	filter.Offset = normalizeOffset(filter.Offset)
	filter.Search = strings.TrimSpace(filter.Search)
	filter.City = strings.TrimSpace(filter.City)
	filter.Signal = strings.TrimSpace(filter.Signal)
	filter.Risk = normalizeModerationRiskFilter(filter.Risk)
	filter.Sort = normalizeModerationQueueSort(filter.Sort)
	if len(filter.Statuses) == 0 {
		filter.Statuses = []enum.ModerationCaseStatus{
			enum.ModerationCaseStatusOpen,
			enum.ModerationCaseStatusInReview,
			enum.ModerationCaseStatusEscalated,
		}
	}
	return u.repo.ListCases(ctx, filter)
}

func normalizeModerationRiskFilter(value model.ModerationRiskFilter) model.ModerationRiskFilter {
	switch value {
	case model.ModerationRiskFilterFlagged, model.ModerationRiskFilterHigh:
		return value
	default:
		return model.ModerationRiskFilterAll
	}
}

func normalizeModerationQueueSort(value model.ModerationQueueSort) model.ModerationQueueSort {
	switch value {
	case model.ModerationQueueSortPriorityDesc,
		model.ModerationQueueSortOpenedDesc,
		model.ModerationQueueSortOpenedAsc,
		model.ModerationQueueSortRiskDesc,
		model.ModerationQueueSortSubmittedDesc:
		return value
	default:
		return model.ModerationQueueSortDefault
	}
}

func (u *ModerationUseCase) GetCaseDetail(ctx context.Context, actor *model.StaffUser, caseID uuid.UUID) (*ModerationCaseDetail, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionModerationRead) {
		return nil, ErrPermissionDenied
	}
	item, err := u.repo.GetCase(ctx, caseID)
	if err != nil {
		return nil, err
	}
	if item == nil {
		return nil, ErrModerationCaseNotFound
	}
	decisions, err := u.repo.ListDecisions(ctx, caseID)
	if err != nil {
		return nil, err
	}
	var excursion *model.ExcursionModerationItem
	var activity *model.ActivityModerationItem
	var guideApplication *model.GuideApplicationModerationItem
	var chatMessage *model.ChatMessageModerationItem
	if item.TargetType == model.ModerationTargetExcursion {
		excursion, err = u.excursion.GetExcursion(ctx, item.TargetID)
		if err != nil {
			return nil, err
		}
	} else if item.TargetType == model.ModerationTargetActivity {
		activity, err = u.activity.GetActivity(ctx, item.TargetID)
		if err != nil {
			return nil, err
		}
	} else if item.TargetType == model.ModerationTargetGuideApplication {
		guideApplication, err = u.guide.GetApplication(ctx, item.TargetID)
		if err != nil {
			return nil, err
		}
	} else if item.TargetType == model.ModerationTargetChatMessage {
		chatMessage, err = u.chat.GetMessage(ctx, item.TargetID)
		if err != nil {
			return nil, err
		}
	}
	return &ModerationCaseDetail{
		Case:             item,
		Excursion:        excursion,
		Activity:         activity,
		GuideApplication: guideApplication,
		ChatMessage:      chatMessage,
		Decisions:        decisions,
	}, nil
}

func (u *ModerationUseCase) DecideExcursion(ctx context.Context, input ModerationDecisionInput) (*ModerationCaseDetail, error) {
	if input.Actor == nil || !input.Actor.HasPermission(enum.PermissionExcursionModerate) {
		return nil, ErrPermissionDenied
	}
	caseItem, err := u.repo.GetCase(ctx, input.CaseID)
	if err != nil {
		return nil, err
	}
	if caseItem == nil || caseItem.TargetType != model.ModerationTargetExcursion {
		return nil, ErrModerationCaseNotFound
	}
	reasonCodes := normalizeReasonCodes(input.ReasonCodes)
	publicComment := strings.TrimSpace(input.PublicComment)
	internalComment := strings.TrimSpace(input.InternalComment)
	if internalComment == "" || (requiresPublicModerationComment(input.Decision) && publicComment == "") {
		return nil, ErrInvalidInput
	}
	idempotencyKey := strings.TrimSpace(input.IdempotencyKey)
	if idempotencyKey == "" {
		idempotencyKey = uuid.NewString()
	}
	now := time.Now().UTC()
	decision := &model.ModerationDecision{
		ID:              uuid.New(),
		CaseID:          caseItem.ID,
		DecisionType:    input.Decision,
		SourceRevision:  caseItem.SourceRevision,
		ReasonCodes:     reasonCodes,
		PublicComment:   publicComment,
		InternalComment: internalComment,
		IdempotencyKey:  idempotencyKey,
		DecidedBy:       input.Actor.ID,
		ApplyStatus:     enum.ModerationApplyPending,
		CreatedAt:       now,
	}
	if err = u.repo.CreateDecision(ctx, decision); err != nil {
		if errors.Is(err, ErrDuplicateDecision) {
			return u.GetCaseDetail(ctx, input.Actor, caseItem.ID)
		}
		return nil, err
	}
	clientInput := port.ExcursionDecisionInput{
		ExcursionID:    caseItem.TargetID,
		ActorStaffID:   input.Actor.ID,
		ReasonCodes:    decision.ReasonCodes,
		PublicComment:  decision.PublicComment,
		IdempotencyKey: idempotencyKey,
		RequestID:      input.RequestMetadata.RequestID,
	}
	var updated *model.ExcursionModerationItem
	var raw []byte
	switch input.Decision {
	case enum.ModerationDecisionApprove:
		updated, raw, err = u.excursion.Approve(ctx, clientInput)
	case enum.ModerationDecisionReject, enum.ModerationDecisionRequestChanges:
		updated, raw, err = u.excursion.Reject(ctx, clientInput)
	default:
		return nil, ErrInvalidInput
	}
	if err != nil {
		_ = u.repo.MarkDecisionFailed(ctx, decision.ID, errorResponseJSON(err), now)
		u.appendModerationAudit(ctx, input.Actor.ID, "moderation.decision.apply_failed", caseItem.ID, input.RequestMetadata, map[string]any{"decision": input.Decision, "error_code": "downstream_failure"})
		return nil, err
	}
	if err = u.repo.MarkDecisionApplied(ctx, decision.ID, raw, now); err != nil {
		return nil, err
	}
	if err = u.repo.SupersedeAppliedDecisions(ctx, caseItem.ID, caseItem.SourceRevision, decision.ID, now); err != nil {
		return nil, err
	}
	status := enum.ModerationCaseStatusApproved
	if input.Decision != enum.ModerationDecisionApprove {
		status = enum.ModerationCaseStatusRejected
	}
	if err = u.repo.UpdateCaseStatus(ctx, caseItem.ID, status, &now, now); err != nil {
		return nil, err
	}
	u.appendModerationAudit(ctx, input.Actor.ID, "moderation.decision.applied", caseItem.ID, input.RequestMetadata, map[string]any{"decision": input.Decision, "targetId": caseItem.TargetID})
	u.notifyExcursionModerationDecision(ctx, caseItem, input.Decision, decision.ReasonCodes, idempotencyKey, updated)
	detail, err := u.GetCaseDetail(ctx, input.Actor, caseItem.ID)
	if err != nil {
		return nil, err
	}
	detail.Excursion = updated
	return detail, nil
}

func (u *ModerationUseCase) DecideActivity(ctx context.Context, input ModerationDecisionInput) (*ModerationCaseDetail, error) {
	if input.Actor == nil || !input.Actor.HasPermission(enum.PermissionActivityModerate) {
		return nil, ErrPermissionDenied
	}
	caseItem, err := u.repo.GetCase(ctx, input.CaseID)
	if err != nil {
		return nil, err
	}
	if caseItem == nil || caseItem.TargetType != model.ModerationTargetActivity {
		return nil, ErrModerationCaseNotFound
	}
	reasonCodes := normalizeReasonCodes(input.ReasonCodes)
	publicComment := strings.TrimSpace(input.PublicComment)
	internalComment := strings.TrimSpace(input.InternalComment)
	if internalComment == "" || (requiresPublicModerationComment(input.Decision) && publicComment == "") {
		return nil, ErrInvalidInput
	}
	idempotencyKey := strings.TrimSpace(input.IdempotencyKey)
	if idempotencyKey == "" {
		idempotencyKey = uuid.NewString()
	}
	now := time.Now().UTC()
	decision := &model.ModerationDecision{
		ID:              uuid.New(),
		CaseID:          caseItem.ID,
		DecisionType:    input.Decision,
		SourceRevision:  caseItem.SourceRevision,
		ReasonCodes:     reasonCodes,
		PublicComment:   publicComment,
		InternalComment: internalComment,
		IdempotencyKey:  idempotencyKey,
		DecidedBy:       input.Actor.ID,
		ApplyStatus:     enum.ModerationApplyPending,
		CreatedAt:       now,
	}
	if err = u.repo.CreateDecision(ctx, decision); err != nil {
		if errors.Is(err, ErrDuplicateDecision) {
			return u.GetCaseDetail(ctx, input.Actor, caseItem.ID)
		}
		return nil, err
	}
	clientInput := port.ActivityDecisionInput{
		ActivityID:     caseItem.TargetID,
		ActorStaffID:   input.Actor.ID,
		ReasonCodes:    decision.ReasonCodes,
		PublicComment:  decision.PublicComment,
		IdempotencyKey: idempotencyKey,
		RequestID:      input.RequestMetadata.RequestID,
	}
	var updated *model.ActivityModerationItem
	var raw []byte
	switch input.Decision {
	case enum.ModerationDecisionApprove:
		updated, raw, err = u.activity.Approve(ctx, clientInput)
	case enum.ModerationDecisionReject, enum.ModerationDecisionRequestChanges:
		updated, raw, err = u.activity.Reject(ctx, clientInput)
	default:
		return nil, ErrInvalidInput
	}
	if err != nil {
		_ = u.repo.MarkDecisionFailed(ctx, decision.ID, errorResponseJSON(err), now)
		u.appendModerationAudit(ctx, input.Actor.ID, "moderation.decision.apply_failed", caseItem.ID, input.RequestMetadata, map[string]any{"decision": input.Decision, "targetId": caseItem.TargetID, "targetType": caseItem.TargetType, "error": err.Error()})
		return nil, err
	}
	if err = u.repo.MarkDecisionApplied(ctx, decision.ID, raw, now); err != nil {
		return nil, err
	}
	if err = u.repo.SupersedeAppliedDecisions(ctx, caseItem.ID, caseItem.SourceRevision, decision.ID, now); err != nil {
		return nil, err
	}
	status := enum.ModerationCaseStatusApproved
	if input.Decision != enum.ModerationDecisionApprove {
		status = enum.ModerationCaseStatusRejected
	}
	if err = u.repo.UpdateCaseStatus(ctx, caseItem.ID, status, &now, now); err != nil {
		return nil, err
	}
	u.appendModerationAudit(ctx, input.Actor.ID, "moderation.decision.applied", caseItem.ID, input.RequestMetadata, map[string]any{"decision": input.Decision, "targetId": caseItem.TargetID, "targetType": caseItem.TargetType})
	u.notifyActivityModerationDecision(ctx, caseItem, input.Decision, decision.ReasonCodes, idempotencyKey, updated)
	detail, err := u.GetCaseDetail(ctx, input.Actor, caseItem.ID)
	if err != nil {
		return nil, err
	}
	detail.Activity = updated
	return detail, nil
}

func (u *ModerationUseCase) DecideChatMessage(ctx context.Context, input ModerationDecisionInput) (*ModerationCaseDetail, error) {
	if input.Actor == nil || !input.Actor.HasPermission(enum.PermissionChatModerate) {
		return nil, ErrPermissionDenied
	}
	caseItem, err := u.repo.GetCase(ctx, input.CaseID)
	if err != nil {
		return nil, err
	}
	if caseItem == nil || caseItem.TargetType != model.ModerationTargetChatMessage {
		return nil, ErrModerationCaseNotFound
	}
	if input.Decision != enum.ModerationDecisionApprove && input.Decision != enum.ModerationDecisionReject {
		return nil, ErrInvalidInput
	}
	reasonCodes := normalizeReasonCodes(input.ReasonCodes)
	publicComment := strings.TrimSpace(input.PublicComment)
	internalComment := strings.TrimSpace(input.InternalComment)
	if internalComment == "" || (requiresPublicModerationComment(input.Decision) && publicComment == "") {
		return nil, ErrInvalidInput
	}
	if input.Decision == enum.ModerationDecisionReject && len(reasonCodes) == 0 {
		return nil, ErrInvalidInput
	}
	idempotencyKey := strings.TrimSpace(input.IdempotencyKey)
	if idempotencyKey == "" {
		idempotencyKey = uuid.NewString()
	}
	now := time.Now().UTC()
	decision := &model.ModerationDecision{
		ID:              uuid.New(),
		CaseID:          caseItem.ID,
		DecisionType:    input.Decision,
		SourceRevision:  caseItem.SourceRevision,
		ReasonCodes:     reasonCodes,
		PublicComment:   publicComment,
		InternalComment: internalComment,
		IdempotencyKey:  idempotencyKey,
		DecidedBy:       input.Actor.ID,
		ApplyStatus:     enum.ModerationApplyPending,
		CreatedAt:       now,
	}
	if err = u.repo.CreateDecision(ctx, decision); err != nil {
		if errors.Is(err, ErrDuplicateDecision) {
			return u.GetCaseDetail(ctx, input.Actor, caseItem.ID)
		}
		return nil, err
	}
	clientInput := port.ChatMessageDecisionInput{
		MessageID:       caseItem.TargetID,
		ActorStaffID:    input.Actor.ID,
		ReasonCodes:     decision.ReasonCodes,
		PublicComment:   decision.PublicComment,
		InternalComment: decision.InternalComment,
		IdempotencyKey:  idempotencyKey,
		RequestID:       input.RequestMetadata.RequestID,
	}
	var updated *model.ChatMessageModerationItem
	var raw []byte
	switch input.Decision {
	case enum.ModerationDecisionApprove:
		updated, raw, err = u.chat.ApproveMessage(ctx, clientInput)
	case enum.ModerationDecisionReject:
		updated, raw, err = u.chat.HideMessage(ctx, clientInput)
	default:
		return nil, ErrInvalidInput
	}
	if err != nil {
		_ = u.repo.MarkDecisionFailed(ctx, decision.ID, errorResponseJSON(err), now)
		u.appendModerationAudit(ctx, input.Actor.ID, "moderation.decision.apply_failed", caseItem.ID, input.RequestMetadata, map[string]any{"decision": input.Decision, "targetId": caseItem.TargetID, "targetType": caseItem.TargetType, "error": err.Error()})
		return nil, err
	}
	if err = u.repo.MarkDecisionApplied(ctx, decision.ID, raw, now); err != nil {
		return nil, err
	}
	if err = u.repo.SupersedeAppliedDecisions(ctx, caseItem.ID, caseItem.SourceRevision, decision.ID, now); err != nil {
		return nil, err
	}
	status := enum.ModerationCaseStatusApproved
	if input.Decision == enum.ModerationDecisionReject {
		status = enum.ModerationCaseStatusRejected
	}
	if err = u.repo.UpdateCaseStatus(ctx, caseItem.ID, status, &now, now); err != nil {
		return nil, err
	}
	u.appendModerationAudit(ctx, input.Actor.ID, "moderation.decision.applied", caseItem.ID, input.RequestMetadata, map[string]any{"decision": input.Decision, "targetId": caseItem.TargetID, "targetType": caseItem.TargetType})
	u.notifyChatMessageModerationDecision(ctx, caseItem, input.Decision, decision.ReasonCodes, idempotencyKey, updated)
	detail, err := u.GetCaseDetail(ctx, input.Actor, caseItem.ID)
	if err != nil {
		return nil, err
	}
	detail.ChatMessage = updated
	return detail, nil
}

func (u *ModerationUseCase) DecideGuideApplication(ctx context.Context, input ModerationDecisionInput) (*ModerationCaseDetail, error) {
	if input.Actor == nil || !input.Actor.HasPermission(enum.PermissionGuideModerate) {
		return nil, ErrPermissionDenied
	}
	caseItem, err := u.repo.GetCase(ctx, input.CaseID)
	if err != nil {
		return nil, err
	}
	if caseItem == nil || caseItem.TargetType != model.ModerationTargetGuideApplication {
		return nil, ErrModerationCaseNotFound
	}
	if input.Decision == enum.ModerationDecisionRevoke && caseItem.Status != enum.ModerationCaseStatusApproved {
		return nil, ErrInvalidInput
	}
	reasonCodes := normalizeReasonCodes(input.ReasonCodes)
	publicComment := strings.TrimSpace(input.PublicComment)
	internalComment := strings.TrimSpace(input.InternalComment)
	if internalComment == "" || (requiresPublicModerationComment(input.Decision) && publicComment == "") {
		return nil, ErrInvalidInput
	}
	idempotencyKey := strings.TrimSpace(input.IdempotencyKey)
	if idempotencyKey == "" {
		idempotencyKey = uuid.NewString()
	}
	now := time.Now().UTC()
	decision := &model.ModerationDecision{
		ID:              uuid.New(),
		CaseID:          caseItem.ID,
		DecisionType:    input.Decision,
		SourceRevision:  caseItem.SourceRevision,
		ReasonCodes:     reasonCodes,
		PublicComment:   publicComment,
		InternalComment: internalComment,
		IdempotencyKey:  idempotencyKey,
		DecidedBy:       input.Actor.ID,
		ApplyStatus:     enum.ModerationApplyPending,
		CreatedAt:       now,
	}
	if err = u.repo.CreateDecision(ctx, decision); err != nil {
		if errors.Is(err, ErrDuplicateDecision) {
			return u.GetCaseDetail(ctx, input.Actor, caseItem.ID)
		}
		return nil, err
	}
	clientInput := port.GuideApplicationDecisionInput{
		GuideApplicationID: caseItem.TargetID,
		ActorStaffID:       input.Actor.ID,
		ReasonCodes:        decision.ReasonCodes,
		PublicComment:      decision.PublicComment,
		IdempotencyKey:     idempotencyKey,
		RequestID:          input.RequestMetadata.RequestID,
	}
	var updated *model.GuideApplicationModerationItem
	var raw []byte
	switch input.Decision {
	case enum.ModerationDecisionApprove:
		updated, raw, err = u.guide.Approve(ctx, clientInput)
	case enum.ModerationDecisionReject, enum.ModerationDecisionRequestChanges:
		updated, raw, err = u.guide.Reject(ctx, clientInput)
	case enum.ModerationDecisionRevoke:
		updated, raw, err = u.guide.Revoke(ctx, clientInput)
	default:
		return nil, ErrInvalidInput
	}
	if err != nil {
		_ = u.repo.MarkDecisionFailed(ctx, decision.ID, errorResponseJSON(err), now)
		u.appendModerationAudit(ctx, input.Actor.ID, "moderation.decision.apply_failed", caseItem.ID, input.RequestMetadata, map[string]any{"decision": input.Decision, "targetId": caseItem.TargetID, "targetType": caseItem.TargetType, "error": err.Error()})
		return nil, err
	}
	if err = u.repo.MarkDecisionApplied(ctx, decision.ID, raw, now); err != nil {
		return nil, err
	}
	if err = u.repo.SupersedeAppliedDecisions(ctx, caseItem.ID, caseItem.SourceRevision, decision.ID, now); err != nil {
		return nil, err
	}
	status := enum.ModerationCaseStatusApproved
	if input.Decision == enum.ModerationDecisionRevoke {
		status = enum.ModerationCaseStatusRevoked
	} else if input.Decision != enum.ModerationDecisionApprove {
		status = enum.ModerationCaseStatusRejected
	}
	if err = u.repo.UpdateCaseStatus(ctx, caseItem.ID, status, &now, now); err != nil {
		return nil, err
	}
	u.appendModerationAudit(ctx, input.Actor.ID, "moderation.decision.applied", caseItem.ID, input.RequestMetadata, map[string]any{"decision": input.Decision, "targetId": caseItem.TargetID, "targetType": caseItem.TargetType})
	u.notifyGuideApplicationModerationDecision(ctx, caseItem, input.Decision, decision.ReasonCodes, idempotencyKey, updated)
	detail, err := u.GetCaseDetail(ctx, input.Actor, caseItem.ID)
	if err != nil {
		return nil, err
	}
	detail.GuideApplication = updated
	return detail, nil
}

func (u *ModerationUseCase) RevokeActiveGuide(ctx context.Context, input RevokeActiveGuideInput) (*model.GuideApplicationModerationItem, error) {
	if input.Actor == nil || !input.Actor.HasPermission(enum.PermissionGuideModerate) {
		return nil, ErrPermissionDenied
	}
	if input.GuideProfileID == uuid.Nil {
		return nil, ErrInvalidInput
	}
	reasonCodes := normalizeReasonCodes(input.ReasonCodes)
	publicComment := strings.TrimSpace(input.PublicComment)
	internalComment := strings.TrimSpace(input.InternalComment)
	if len(reasonCodes) == 0 || publicComment == "" || internalComment == "" {
		return nil, ErrInvalidInput
	}
	idempotencyKey := strings.TrimSpace(input.IdempotencyKey)
	if idempotencyKey == "" {
		idempotencyKey = uuid.NewString()
	}
	clientInput := port.GuideProfileDecisionInput{
		GuideProfileID: input.GuideProfileID,
		ActorStaffID:   input.Actor.ID,
		ReasonCodes:    reasonCodes,
		PublicComment:  publicComment,
		IdempotencyKey: idempotencyKey,
		RequestID:      input.RequestMetadata.RequestID,
	}
	item, _, err := u.guide.RevokeProfile(ctx, clientInput)
	if err != nil {
		u.appendGuideProfileAudit(ctx, input.Actor.ID, "guide.status.revoke_failed", input.GuideProfileID, input.RequestMetadata, map[string]any{"reasonCodes": reasonCodes, "error_code": "downstream_failure"})
		return nil, err
	}
	u.appendGuideProfileAudit(ctx, input.Actor.ID, "guide.status.revoked", input.GuideProfileID, input.RequestMetadata, map[string]any{"reasonCodes": reasonCodes, "internalComment": internalComment})
	u.notifyGuideStatusRevoked(ctx, input.GuideProfileID, reasonCodes, idempotencyKey, item)
	return item, nil
}

func requiresPublicModerationComment(decision enum.ModerationDecisionType) bool {
	return decision == enum.ModerationDecisionReject ||
		decision == enum.ModerationDecisionRevoke ||
		decision == enum.ModerationDecisionRequestChanges
}

func errorResponseJSON(err error) []byte {
	if err == nil {
		return nil
	}
	payload, marshalErr := json.Marshal(map[string]string{
		"error":      "technical_error",
		"error_code": "downstream_failure",
	})
	if marshalErr != nil {
		return []byte(`{"error":"technical_error","error_code":"downstream_failure"}`)
	}
	return payload
}

func normalizeReasonCodes(input []string) []string {
	seen := make(map[string]struct{}, len(input))
	out := make([]string, 0, len(input))
	for _, value := range input {
		value = strings.ToLower(strings.TrimSpace(value))
		if value == "" {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		out = append(out, value)
	}
	return out
}

func (u *ModerationUseCase) appendModerationAudit(
	ctx context.Context,
	actorID uuid.UUID,
	action string,
	caseID uuid.UUID,
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
		EntityType:    "moderation_case",
		EntityID:      &caseID,
		RequestID:     strings.TrimSpace(meta.RequestID),
		IPAddressHash: HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash: HashPassiveIdentifier(meta.UserAgent),
		Metadata:      metadataJSON,
		CreatedAt:     time.Now().UTC(),
	})
}

func (u *ModerationUseCase) appendGuideProfileAudit(
	ctx context.Context,
	actorID uuid.UUID,
	action string,
	guideProfileID uuid.UUID,
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
		EntityType:    "guide_profile",
		EntityID:      &guideProfileID,
		RequestID:     strings.TrimSpace(meta.RequestID),
		IPAddressHash: HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash: HashPassiveIdentifier(meta.UserAgent),
		Metadata:      metadataJSON,
		CreatedAt:     time.Now().UTC(),
	})
}
