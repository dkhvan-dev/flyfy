package app

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

const (
	adminNotificationCategoryAccount   = "account"
	adminNotificationCategoryActivity  = "activity"
	adminNotificationCategoryChat      = "chat"
	adminNotificationCategoryExcursion = "excursion"
	adminNotificationCategoryGuide     = "guide"

	adminNotificationPriorityNormal = "normal"
	adminNotificationPriorityHigh   = "high"

	adminNotificationTimeout = 3 * time.Second
	adminNotificationTTL     = 24 * time.Hour
)

func (u *ModerationUseCase) SetNotificationGateway(gateway port.UserNotificationGateway) {
	u.notify = gateway
}

func (u *UserModerationUseCase) SetNotificationGateway(gateway port.UserNotificationGateway) {
	u.notify = gateway
}

func (u *ModerationUseCase) notifyActivityModerationDecision(
	ctx context.Context,
	caseItem *model.ModerationCase,
	decision enum.ModerationDecisionType,
	reasonCodes []string,
	idempotencyKey string,
	item *model.ActivityModerationItem,
) {
	if u.notify == nil || caseItem == nil || item == nil || item.HostUserID == uuid.Nil {
		return
	}

	event := "activity_approved"
	title := "Activity approved"
	body := fmt.Sprintf("%s is now visible to travelers.", adminActivityTitle(item))
	priority := adminNotificationPriorityNormal
	if decision == enum.ModerationDecisionRequestChanges {
		event = "activity_changes_requested"
		title = "Activity needs changes"
		body = fmt.Sprintf("Please update %s before publishing.", adminActivityTitle(item))
		priority = adminNotificationPriorityHigh
	} else if decision == enum.ModerationDecisionReject {
		event = "activity_rejected"
		title = "Activity rejected"
		body = fmt.Sprintf("%s was rejected after moderation.", adminActivityTitle(item))
		priority = adminNotificationPriorityHigh
	}

	dispatchAdminNotification(ctx, u.notify, port.UserNotificationInput{
		IdempotencyKey:   adminModerationNotificationKey(idempotencyKey, event),
		RecipientUserIDs: []uuid.UUID{item.HostUserID},
		Category:         adminNotificationCategoryActivity,
		Priority:         priority,
		Title:            title,
		Body:             body,
		DeepLink:         adminActivityDeepLink(item.ID),
		Data:             adminModerationNotificationData(event, caseItem, decision, reasonCodes),
		CollapseKey:      fmt.Sprintf("admin:moderation:activity:%s", item.ID),
		TTL:              adminNotificationTTL,
	})
}

func (u *ModerationUseCase) notifyExcursionModerationDecision(
	ctx context.Context,
	caseItem *model.ModerationCase,
	decision enum.ModerationDecisionType,
	reasonCodes []string,
	idempotencyKey string,
	item *model.ExcursionModerationItem,
) {
	if u.notify == nil || caseItem == nil || item == nil || item.GuideUserID == uuid.Nil {
		return
	}

	event := "excursion_approved"
	title := "Excursion approved"
	body := fmt.Sprintf("%s is now visible to travelers.", adminExcursionTitle(item))
	priority := adminNotificationPriorityNormal
	if decision == enum.ModerationDecisionRequestChanges {
		event = "excursion_changes_requested"
		title = "Excursion needs changes"
		body = fmt.Sprintf("Please update %s before publishing.", adminExcursionTitle(item))
		priority = adminNotificationPriorityHigh
	} else if decision == enum.ModerationDecisionReject {
		event = "excursion_rejected"
		title = "Excursion rejected"
		body = fmt.Sprintf("%s was rejected after moderation.", adminExcursionTitle(item))
		priority = adminNotificationPriorityHigh
	}

	dispatchAdminNotification(ctx, u.notify, port.UserNotificationInput{
		IdempotencyKey:   adminModerationNotificationKey(idempotencyKey, event),
		RecipientUserIDs: []uuid.UUID{item.GuideUserID},
		Category:         adminNotificationCategoryExcursion,
		Priority:         priority,
		Title:            title,
		Body:             body,
		DeepLink:         adminExcursionDeepLink(item.ID),
		Data:             adminModerationNotificationData(event, caseItem, decision, reasonCodes),
		CollapseKey:      fmt.Sprintf("admin:moderation:excursion:%s", item.ID),
		TTL:              adminNotificationTTL,
	})
}

func (u *ModerationUseCase) notifyGuideApplicationModerationDecision(
	ctx context.Context,
	caseItem *model.ModerationCase,
	decision enum.ModerationDecisionType,
	reasonCodes []string,
	idempotencyKey string,
	item *model.GuideApplicationModerationItem,
) {
	if u.notify == nil || caseItem == nil || item == nil || item.GuideUserID == uuid.Nil {
		return
	}

	event := "guide_application_approved"
	title := "Guide profile approved"
	body := "Your guide profile is approved."
	priority := adminNotificationPriorityNormal
	if decision == enum.ModerationDecisionRequestChanges {
		event = "guide_application_changes_requested"
		title = "Guide profile needs changes"
		body = "Please update your guide profile and submit it again."
		priority = adminNotificationPriorityHigh
	} else if decision == enum.ModerationDecisionReject {
		event = "guide_application_rejected"
		title = "Guide profile rejected"
		body = "Your guide profile was rejected after moderation."
		priority = adminNotificationPriorityHigh
	} else if decision == enum.ModerationDecisionRevoke {
		event = "guide_status_revoked"
		title = "Guide status revoked"
		body = "Your guide status was revoked after moderation."
		priority = adminNotificationPriorityHigh
	}

	data := adminModerationNotificationData(event, caseItem, decision, reasonCodes)
	if item.GuideProfileID != uuid.Nil {
		data["guideProfileId"] = item.GuideProfileID.String()
	}
	dispatchAdminNotification(ctx, u.notify, port.UserNotificationInput{
		IdempotencyKey:   adminModerationNotificationKey(idempotencyKey, event),
		RecipientUserIDs: []uuid.UUID{item.GuideUserID},
		Category:         adminNotificationCategoryGuide,
		Priority:         priority,
		Title:            title,
		Body:             body,
		DeepLink:         adminNotificationCategoryDeepLink(adminNotificationCategoryGuide),
		Data:             data,
		CollapseKey:      fmt.Sprintf("admin:moderation:guide:%s", item.GuideUserID),
		TTL:              adminNotificationTTL,
	})
}

func (u *ModerationUseCase) notifyChatMessageModerationDecision(
	ctx context.Context,
	caseItem *model.ModerationCase,
	decision enum.ModerationDecisionType,
	reasonCodes []string,
	idempotencyKey string,
	item *model.ChatMessageModerationItem,
) {
	if u.notify == nil || caseItem == nil || item == nil || item.SenderUserID == uuid.Nil {
		return
	}
	if decision != enum.ModerationDecisionReject {
		return
	}

	event := "chat_message_hidden"
	data := adminModerationNotificationData(event, caseItem, decision, reasonCodes)
	data["conversationId"] = item.ConversationID.String()
	dispatchAdminNotification(ctx, u.notify, port.UserNotificationInput{
		IdempotencyKey:   adminModerationNotificationKey(idempotencyKey, event),
		RecipientUserIDs: []uuid.UUID{item.SenderUserID},
		Category:         adminNotificationCategoryChat,
		Priority:         adminNotificationPriorityHigh,
		Title:            "Message hidden",
		Body:             "A message was hidden because it violated community rules.",
		DeepLink:         adminNotificationCategoryDeepLink(adminNotificationCategoryChat),
		Data:             data,
		CollapseKey:      fmt.Sprintf("admin:moderation:chat:%s", item.ConversationID),
		TTL:              adminNotificationTTL,
	})
}

func (u *ModerationUseCase) notifyGuideStatusRevoked(
	ctx context.Context,
	guideProfileID uuid.UUID,
	reasonCodes []string,
	idempotencyKey string,
	item *model.GuideApplicationModerationItem,
) {
	if u.notify == nil || item == nil || item.GuideUserID == uuid.Nil {
		return
	}

	data := map[string]string{
		"adminEvent":     "guide_status_revoked",
		"targetType":     "GUIDE_PROFILE",
		"targetId":       guideProfileID.String(),
		"guideProfileId": guideProfileID.String(),
	}
	if len(reasonCodes) > 0 {
		data["reasonCodes"] = strings.Join(reasonCodes, ",")
	}
	dispatchAdminNotification(ctx, u.notify, port.UserNotificationInput{
		IdempotencyKey:   fmt.Sprintf("admin:guide_profile:%s:%s", nonEmptyNotificationKey(idempotencyKey), "guide_status_revoked"),
		RecipientUserIDs: []uuid.UUID{item.GuideUserID},
		Category:         adminNotificationCategoryGuide,
		Priority:         adminNotificationPriorityHigh,
		Title:            "Guide status revoked",
		Body:             "Your guide status was revoked after moderation.",
		DeepLink:         adminNotificationCategoryDeepLink(adminNotificationCategoryGuide),
		Data:             data,
		CollapseKey:      fmt.Sprintf("admin:moderation:guide:%s", item.GuideUserID),
		TTL:              adminNotificationTTL,
	})
}

func (u *UserModerationUseCase) notifyUserModerationDecision(
	ctx context.Context,
	item model.UserModerationCase,
	params model.ResolveUserModerationCaseParams,
) {
	if u.notify == nil || item.TargetUserID == uuid.Nil {
		return
	}

	event, title, body, priority, ok := userModerationDecisionNotification(params.Decision)
	if !ok {
		return
	}
	data := map[string]string{
		"adminEvent": event,
		"targetType": "USER",
		"targetId":   item.TargetUserID.String(),
		"caseId":     item.ID.String(),
		"decision":   string(params.Decision),
		"reasonCode": params.ReasonCode,
	}
	dispatchAdminNotification(ctx, u.notify, port.UserNotificationInput{
		IdempotencyKey:   fmt.Sprintf("admin:user_moderation_case:%s:%s", item.ID, strings.ToLower(string(params.Decision))),
		RecipientUserIDs: []uuid.UUID{item.TargetUserID},
		Category:         adminNotificationCategoryAccount,
		Priority:         priority,
		Title:            title,
		Body:             body,
		DeepLink:         adminNotificationCategoryDeepLink(adminNotificationCategoryAccount),
		Data:             data,
		CollapseKey:      fmt.Sprintf("admin:user:%s:account", item.TargetUserID),
		TTL:              adminNotificationTTL,
	})
}

type userRestrictionNotificationPayload struct {
	RestrictionID   uuid.UUID                 `json:"restrictionId"`
	UserID          uuid.UUID                 `json:"userId"`
	RestrictionCode model.UserRestrictionCode `json:"restrictionCode"`
	ReasonCode      string                    `json:"reasonCode"`
}

func userRestrictionNotificationInput(
	event model.UserRestrictionOutboxEvent,
) (port.UserNotificationInput, error) {
	payload := userRestrictionNotificationPayload{
		RestrictionID: event.AggregateID,
		UserID:        event.UserID,
	}
	if len(event.Payload) > 0 {
		if err := json.Unmarshal(event.Payload, &payload); err != nil {
			return port.UserNotificationInput{}, fmt.Errorf("%w: decode restriction notification payload", ErrInvalidInput)
		}
	}
	if payload.RestrictionID == uuid.Nil {
		payload.RestrictionID = event.AggregateID
	}
	if payload.UserID == uuid.Nil {
		payload.UserID = event.UserID
	}
	if payload.RestrictionID == uuid.Nil || payload.UserID == uuid.Nil || payload.RestrictionCode == "" {
		return port.UserNotificationInput{}, fmt.Errorf("%w: incomplete restriction notification payload", ErrInvalidInput)
	}

	input := port.UserNotificationInput{
		RecipientUserIDs: []uuid.UUID{payload.UserID},
		Category:         adminNotificationCategoryAccount,
		DeepLink:         adminNotificationCategoryDeepLink(adminNotificationCategoryAccount),
		Data: map[string]string{
			"targetType":      "USER",
			"targetId":        payload.UserID.String(),
			"restrictionId":   payload.RestrictionID.String(),
			"restrictionCode": string(payload.RestrictionCode),
			"reasonCode":      strings.TrimSpace(payload.ReasonCode),
		},
		CollapseKey: fmt.Sprintf("admin:user:%s:account", payload.UserID),
		TTL:         adminNotificationTTL,
	}

	switch event.EventType {
	case model.UserRestrictionOutboxEventCreated:
		input.IdempotencyKey = fmt.Sprintf("admin:user_restriction:%s:created", payload.RestrictionID)
		input.Priority = adminNotificationPriorityHigh
		input.Title = "Account restriction applied"
		input.Body = userRestrictionCreatedBody(payload.RestrictionCode)
		input.Data["adminEvent"] = "user_restriction_created"
	case model.UserRestrictionOutboxEventLifted:
		input.IdempotencyKey = fmt.Sprintf("admin:user_restriction:%s:lifted", payload.RestrictionID)
		input.Priority = adminNotificationPriorityNormal
		input.Title = "Account restriction lifted"
		input.Body = "A restriction on your account has been lifted."
		input.Data["adminEvent"] = "user_restriction_lifted"
	default:
		return port.UserNotificationInput{}, fmt.Errorf("%w: unsupported restriction outbox event %q", ErrInvalidInput, event.EventType)
	}

	return input, nil
}

func dispatchAdminNotification(
	ctx context.Context,
	gateway port.UserNotificationGateway,
	input port.UserNotificationInput,
) {
	if gateway == nil || len(input.RecipientUserIDs) == 0 {
		return
	}

	go func() {
		notifyCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), adminNotificationTimeout)
		defer cancel()

		if err := gateway.SendUserNotification(notifyCtx, input); err != nil {
			log.Warn().
				Err(err).
				Str("idempotency_key", input.IdempotencyKey).
				Str("category", input.Category).
				Msg("failed to send admin user notification")
		}
	}()
}

func adminModerationNotificationData(
	event string,
	caseItem *model.ModerationCase,
	decision enum.ModerationDecisionType,
	reasonCodes []string,
) map[string]string {
	data := map[string]string{
		"adminEvent": event,
		"decision":   string(decision),
	}
	if caseItem != nil {
		data["caseId"] = caseItem.ID.String()
		data["targetType"] = string(caseItem.TargetType)
		data["targetId"] = caseItem.TargetID.String()
	}
	if len(reasonCodes) > 0 {
		data["reasonCodes"] = strings.Join(reasonCodes, ",")
	}
	return data
}

func adminModerationNotificationKey(commandKey string, event string) string {
	return fmt.Sprintf("admin:moderation:%s:%s", nonEmptyNotificationKey(commandKey), event)
}

func nonEmptyNotificationKey(value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return uuid.NewString()
	}
	return value
}

func adminActivityDeepLink(activityID uuid.UUID) string {
	return "/activities/" + activityID.String()
}

func adminExcursionDeepLink(excursionID uuid.UUID) string {
	return "/excursions/" + excursionID.String()
}

func adminNotificationCategoryDeepLink(category string) string {
	return "/notifications/" + category
}

func adminActivityTitle(item *model.ActivityModerationItem) string {
	if item == nil {
		return "Activity"
	}
	title := strings.TrimSpace(item.Title)
	if title == "" {
		return "Activity"
	}
	return title
}

func adminExcursionTitle(item *model.ExcursionModerationItem) string {
	if item == nil {
		return "Excursion"
	}
	title := strings.TrimSpace(item.Title)
	if title == "" {
		return "Excursion"
	}
	return title
}

func userModerationDecisionNotification(
	decision model.UserModerationDecision,
) (event string, title string, body string, priority string, ok bool) {
	switch decision {
	case model.UserModerationDecisionWarning:
		return "user_warning_issued", "Account warning", "A moderator has issued a warning for your account.", adminNotificationPriorityNormal, true
	case model.UserModerationDecisionRequestVerify:
		return "user_verification_requested", "Verification required", "Please complete verification to keep using all features.", adminNotificationPriorityHigh, true
	case model.UserModerationDecisionRestrict:
		return "user_restricted", "Account restricted", "Some account features were restricted after moderation.", adminNotificationPriorityHigh, true
	case model.UserModerationDecisionSuspend:
		return "user_suspended", "Account suspended", "Your account was suspended after moderation.", adminNotificationPriorityHigh, true
	case model.UserModerationDecisionPermanentBlock:
		return "user_permanently_blocked", "Account blocked", "Your account was blocked after moderation.", adminNotificationPriorityHigh, true
	case model.UserModerationDecisionRemoveRestriction:
		return "user_restriction_removed", "Account restriction removed", "A restriction on your account has been removed.", adminNotificationPriorityNormal, true
	default:
		return "", "", "", "", false
	}
}

func userRestrictionCreatedBody(code model.UserRestrictionCode) string {
	switch code {
	case model.UserRestrictionChat:
		return "Chat access was restricted after moderation."
	case model.UserRestrictionActivityCreation:
		return "Activity creation was restricted after moderation."
	case model.UserRestrictionTourPublishing:
		return "Tour publishing was restricted after moderation."
	case model.UserRestrictionFileUpload:
		return "File uploads were restricted after moderation."
	case model.UserRestrictionPayout:
		return "Payout access was restricted after moderation."
	case model.UserRestrictionGuideApplication:
		return "Guide applications were restricted after moderation."
	case model.UserRestrictionAccountSuspension:
		return "Your account was suspended after moderation."
	default:
		return "A restriction was applied to your account."
	}
}
