package app

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

const (
	activityNotificationCategory = "activity"
	activityNotificationNormal   = "normal"
	activityNotificationHigh     = "high"

	activityNotificationTimeout = 3 * time.Second
	activityNotificationTTL     = 6 * time.Hour
)

func (u *ActivityUseCase) SetNotificationGateway(gateway port.ActivityNotificationGateway) {
	u.notificationGateway = gateway
}

func (u *JoinUseCase) SetNotificationGateway(gateway port.ActivityNotificationGateway) {
	u.notificationGateway = gateway
}

func (u *JoinUseCase) notifyParticipantJoined(
	ctx context.Context,
	activity *model.Activity,
	participant *model.ActivityParticipant,
) {
	if u.notificationGateway == nil || activity == nil || participant == nil {
		return
	}
	if activity.HostUserID == uuid.Nil ||
		participant.UserID == uuid.Nil ||
		activity.HostUserID == participant.UserID {
		return
	}
	if participant.Status == enum.ParticipantStatusPendingPayment ||
		(!participant.Status.IsActive() && participant.Status != enum.ParticipantStatusWaitlisted) {
		return
	}

	status := string(participant.Status)
	title := "New participant joined"
	body := fmt.Sprintf("%s has a new participant.", activityNotificationTitle(activity))
	event := "participant_joined"
	if participant.Status == enum.ParticipantStatusWaitlisted {
		title = "Participant joined the waitlist"
		body = fmt.Sprintf("%s has a new waitlisted participant.", activityNotificationTitle(activity))
		event = "participant_waitlisted"
	}

	dispatchActivityNotification(ctx, u.notificationGateway, port.ActivityNotificationInput{
		IdempotencyKey: fmt.Sprintf(
			"activity:%s:participant:%s:%s",
			activity.ID,
			participant.ID,
			event,
		),
		RecipientUserIDs: []uuid.UUID{activity.HostUserID},
		Category:         activityNotificationCategory,
		Priority:         activityNotificationNormal,
		Title:            title,
		Body:             body,
		DeepLink:         activityDeepLink(activity.ID),
		Data: map[string]string{
			"activityEvent":     event,
			"activityId":        activity.ID.String(),
			"participantId":     participant.ID.String(),
			"participantUserId": participant.UserID.String(),
			"status":            status,
		},
		CollapseKey: fmt.Sprintf("activity:%s:participants", activity.ID),
		TTL:         activityNotificationTTL,
	})
}

func (u *JoinUseCase) notifyParticipantLeft(
	ctx context.Context,
	activity *model.Activity,
	participant *model.ActivityParticipant,
	lateCancellation bool,
) {
	if u.notificationGateway == nil || activity == nil || participant == nil {
		return
	}
	if activity.HostUserID == uuid.Nil ||
		participant.UserID == uuid.Nil ||
		activity.HostUserID == participant.UserID {
		return
	}

	event := "participant_left"
	title := "Participant left activity"
	body := fmt.Sprintf("%s has one fewer participant.", activityNotificationTitle(activity))
	if lateCancellation {
		event = "participant_late_cancelled"
		title = "Late cancellation"
		body = fmt.Sprintf("A participant cancelled late for %s.", activityNotificationTitle(activity))
	}

	dispatchActivityNotification(ctx, u.notificationGateway, port.ActivityNotificationInput{
		IdempotencyKey: fmt.Sprintf(
			"activity:%s:participant:%s:%s",
			activity.ID,
			participant.ID,
			event,
		),
		RecipientUserIDs: []uuid.UUID{activity.HostUserID},
		Category:         activityNotificationCategory,
		Priority:         activityNotificationNormal,
		Title:            title,
		Body:             body,
		DeepLink:         activityDeepLink(activity.ID),
		Data: map[string]string{
			"activityEvent":     event,
			"activityId":        activity.ID.String(),
			"participantId":     participant.ID.String(),
			"participantUserId": participant.UserID.String(),
			"status":            string(participant.Status),
		},
		CollapseKey: fmt.Sprintf("activity:%s:participants", activity.ID),
		TTL:         activityNotificationTTL,
	})
}

func (u *ActivityUseCase) notifyActivityCancelled(
	ctx context.Context,
	activity *model.Activity,
	participants []*model.ActivityParticipant,
	actorUserID *uuid.UUID,
	source enum.ActivityCancellationSource,
) {
	if u.notificationGateway == nil || activity == nil {
		return
	}

	recipients := activityCancellationNotificationRecipients(activity, participants, actorUserID)
	if len(recipients) == 0 {
		return
	}

	data := map[string]string{
		"activityEvent": "activity_cancelled",
		"activityId":    activity.ID.String(),
		"source":        string(source),
	}
	if activity.CancellationReason != nil {
		data["reason"] = strings.TrimSpace(*activity.CancellationReason)
	}
	if actorUserID != nil && *actorUserID != uuid.Nil {
		data["cancelledByUserId"] = actorUserID.String()
	}

	dispatchActivityNotification(ctx, u.notificationGateway, port.ActivityNotificationInput{
		IdempotencyKey:   fmt.Sprintf("activity:%s:cancelled:%d", activity.ID, activity.Revision),
		RecipientUserIDs: recipients,
		Category:         activityNotificationCategory,
		Priority:         activityNotificationHigh,
		Title:            "Activity cancelled",
		Body:             fmt.Sprintf("%s was cancelled.", activityNotificationTitle(activity)),
		DeepLink:         activityDeepLink(activity.ID),
		Data:             data,
		CollapseKey:      fmt.Sprintf("activity:%s:lifecycle", activity.ID),
		TTL:              24 * time.Hour,
	})
}

func (u *ActivityUseCase) notifyActivityConfirmed(
	ctx context.Context,
	activity *model.Activity,
	participants []*model.ActivityParticipant,
) {
	if u.notificationGateway == nil || activity == nil {
		return
	}

	recipients := activityNotificationRecipients(activity, participants, nil, true)
	if len(recipients) == 0 {
		return
	}

	dispatchActivityNotification(ctx, u.notificationGateway, port.ActivityNotificationInput{
		IdempotencyKey:   fmt.Sprintf("activity:%s:confirmed:%d", activity.ID, activity.Revision),
		RecipientUserIDs: recipients,
		Category:         activityNotificationCategory,
		Priority:         activityNotificationNormal,
		Title:            "Activity confirmed",
		Body:             fmt.Sprintf("%s is confirmed.", activityNotificationTitle(activity)),
		DeepLink:         activityDeepLink(activity.ID),
		Data: map[string]string{
			"activityEvent": "activity_confirmed",
			"activityId":    activity.ID.String(),
			"status":        string(activity.Status),
		},
		CollapseKey: fmt.Sprintf("activity:%s:lifecycle", activity.ID),
		TTL:         activityNotificationTTL,
	})
}

func (u *ActivityUseCase) notifyActivityCompleted(
	ctx context.Context,
	activity *model.Activity,
	actorUserID *uuid.UUID,
) {
	if u.notificationGateway == nil || activity == nil {
		return
	}

	go func() {
		notifyCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), activityNotificationTimeout)
		defer cancel()

		participants, err := u.repo.ListParticipantsByActivityID(notifyCtx, activity.ID, 1000, 0)
		if err != nil {
			log.Warn().
				Err(err).
				Str("activity_id", activity.ID.String()).
				Msg("failed to load participants for activity completion notification")
			return
		}

		recipients := activityNotificationRecipients(activity, participants, actorUserID, true)
		if len(recipients) == 0 {
			return
		}

		if err = u.notificationGateway.SendActivityNotification(notifyCtx, port.ActivityNotificationInput{
			IdempotencyKey:   fmt.Sprintf("activity:%s:completed:%d", activity.ID, activity.Revision),
			RecipientUserIDs: recipients,
			Category:         activityNotificationCategory,
			Priority:         activityNotificationNormal,
			Title:            "Activity completed",
			Body:             fmt.Sprintf("%s is complete. You can review your experience.", activityNotificationTitle(activity)),
			DeepLink:         activityDeepLink(activity.ID),
			Data: map[string]string{
				"activityEvent": "activity_completed",
				"activityId":    activity.ID.String(),
				"status":        string(activity.Status),
			},
			CollapseKey: fmt.Sprintf("activity:%s:lifecycle", activity.ID),
			TTL:         activityNotificationTTL,
		}); err != nil {
			log.Warn().
				Err(err).
				Str("activity_id", activity.ID.String()).
				Msg("failed to send activity completion notification")
		}
	}()
}

func activityNotificationRecipients(
	activity *model.Activity,
	participants []*model.ActivityParticipant,
	actorUserID *uuid.UUID,
	includeHost bool,
) []uuid.UUID {
	seen := make(map[uuid.UUID]struct{}, len(participants)+1)
	recipients := make([]uuid.UUID, 0, len(participants)+1)
	add := func(userID uuid.UUID) {
		if userID == uuid.Nil {
			return
		}
		if actorUserID != nil && *actorUserID == userID {
			return
		}
		if _, ok := seen[userID]; ok {
			return
		}
		seen[userID] = struct{}{}
		recipients = append(recipients, userID)
	}

	if includeHost && activity != nil {
		add(activity.HostUserID)
	}
	for _, participant := range participants {
		if participant == nil {
			continue
		}
		if !participant.Status.IsActive() {
			continue
		}
		add(participant.UserID)
	}
	return recipients
}

func activityCancellationNotificationRecipients(
	activity *model.Activity,
	participants []*model.ActivityParticipant,
	actorUserID *uuid.UUID,
) []uuid.UUID {
	seen := make(map[uuid.UUID]struct{}, len(participants)+1)
	recipients := make([]uuid.UUID, 0, len(participants)+1)
	add := func(userID uuid.UUID) {
		if userID == uuid.Nil {
			return
		}
		if actorUserID != nil && *actorUserID == userID {
			return
		}
		if _, ok := seen[userID]; ok {
			return
		}
		seen[userID] = struct{}{}
		recipients = append(recipients, userID)
	}

	if activity != nil {
		add(activity.HostUserID)
	}
	for _, participant := range participants {
		if participant == nil {
			continue
		}
		if !participant.Status.IsActive() &&
			participant.Status != enum.ParticipantStatusInvited &&
			participant.Status != enum.ParticipantStatusWaitlisted &&
			participant.Status != enum.ParticipantStatusCancelledByActivity {
			continue
		}
		add(participant.UserID)
	}
	return recipients
}

func cloneActivityParticipants(
	participants []*model.ActivityParticipant,
) []*model.ActivityParticipant {
	if len(participants) == 0 {
		return nil
	}
	cloned := make([]*model.ActivityParticipant, 0, len(participants))
	for _, participant := range participants {
		if participant == nil {
			continue
		}
		copyValue := *participant
		cloned = append(cloned, &copyValue)
	}
	return cloned
}

func dispatchActivityNotification(
	ctx context.Context,
	gateway port.ActivityNotificationGateway,
	input port.ActivityNotificationInput,
) {
	if gateway == nil || len(input.RecipientUserIDs) == 0 {
		return
	}

	go func() {
		notifyCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), activityNotificationTimeout)
		defer cancel()

		if err := gateway.SendActivityNotification(notifyCtx, input); err != nil {
			log.Warn().
				Err(err).
				Str("idempotency_key", input.IdempotencyKey).
				Msg("failed to send activity notification")
		}
	}()
}

func activityDeepLink(activityID uuid.UUID) string {
	return "/activities/" + activityID.String()
}

func activityNotificationTitle(activity *model.Activity) string {
	if activity == nil {
		return "Activity"
	}
	title := strings.TrimSpace(activity.Title)
	if title == "" {
		return "Activity"
	}
	return title
}
