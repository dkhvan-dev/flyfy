package app

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/chat-service/internal/domain/model"
	"kz/inflap/backend/services/chat-service/internal/domain/port"
)

const (
	chatNotificationEventMessage  = "chat_message"
	chatNotificationEventPin      = "chat_pin"
	chatNotificationEventReaction = "chat_reaction"

	chatNotificationPinBody = "Pinned a message"
)

func resolveChatNotificationRecipients(
	ctx context.Context,
	repo port.ChatRepository,
	conversationID uuid.UUID,
	actorUserID uuid.UUID,
	targetUserIDs []uuid.UUID,
) ([]uuid.UUID, error) {
	participants, err := repo.ListParticipantsByConversationID(ctx, conversationID)
	if err != nil {
		return nil, err
	}

	var targetSet map[uuid.UUID]struct{}
	if len(targetUserIDs) > 0 {
		targetSet = make(map[uuid.UUID]struct{}, len(targetUserIDs))
		for _, userID := range targetUserIDs {
			if userID != uuid.Nil {
				targetSet[userID] = struct{}{}
			}
		}
	}

	now := time.Now().UTC()
	candidates := make([]uuid.UUID, 0, len(participants))
	seen := make(map[uuid.UUID]struct{}, len(participants))
	for _, participant := range participants {
		if participant == nil ||
			participant.UserID == uuid.Nil ||
			participant.UserID == actorUserID ||
			participant.LeftAt != nil {
			continue
		}
		if targetSet != nil {
			if _, ok := targetSet[participant.UserID]; !ok {
				continue
			}
		}
		if participant.MutedUntil != nil && participant.MutedUntil.UTC().After(now) {
			continue
		}
		if _, ok := seen[participant.UserID]; ok {
			continue
		}
		seen[participant.UserID] = struct{}{}
		candidates = append(candidates, participant.UserID)
	}
	if len(candidates) == 0 {
		return nil, nil
	}

	blockedByCandidate, err := repo.ListUserIDsBlockingUser(ctx, actorUserID, candidates)
	if err != nil {
		return nil, err
	}
	recipients := make([]uuid.UUID, 0, len(candidates))
	for _, candidateID := range candidates {
		if blockedByCandidate[candidateID] {
			continue
		}
		recipients = append(recipients, candidateID)
	}
	return recipients, nil
}

func chatMessageNotification(
	conv *model.Conversation,
	msg *model.Message,
	recipients []uuid.UUID,
) port.ChatNotification {
	return port.ChatNotification{
		IdempotencyKey:    fmt.Sprintf("chat-message-%s", msg.ID),
		EventType:         chatNotificationEventMessage,
		ConversationID:    conv.ID,
		MessageID:         msg.ID,
		SenderUserID:      msg.SenderUserID,
		SenderDisplayName: strings.TrimSpace(msg.SenderDisplayName),
		ConversationType:  conv.Type,
		MessageType:       msg.Type,
		Body:              chatNotificationBody(msg),
		RecipientUserIDs:  recipients,
	}
}

func chatPinNotification(
	conv *model.Conversation,
	msg *model.Message,
	actorUserID uuid.UUID,
	actorDisplayName string,
	recipients []uuid.UUID,
) port.ChatNotification {
	return port.ChatNotification{
		IdempotencyKey: fmt.Sprintf(
			"chat-pin-%s-%s-%s",
			conv.ID,
			msg.ID,
			actorUserID,
		),
		EventType:         chatNotificationEventPin,
		ConversationID:    conv.ID,
		MessageID:         msg.ID,
		SenderUserID:      actorUserID,
		SenderDisplayName: strings.TrimSpace(actorDisplayName),
		ConversationType:  conv.Type,
		MessageType:       msg.Type,
		Body:              chatNotificationPinBody,
		RecipientUserIDs:  recipients,
	}
}

func chatReactionNotification(
	conv *model.Conversation,
	msg *model.Message,
	actorUserID uuid.UUID,
	actorDisplayName string,
	reactionEmoji string,
	recipients []uuid.UUID,
) port.ChatNotification {
	reactionEmoji = strings.TrimSpace(reactionEmoji)
	return port.ChatNotification{
		IdempotencyKey: fmt.Sprintf(
			"chat-reaction-%s-%s-%s",
			msg.ID,
			actorUserID,
			reactionEmoji,
		),
		EventType:         chatNotificationEventReaction,
		ConversationID:    conv.ID,
		MessageID:         msg.ID,
		SenderUserID:      actorUserID,
		SenderDisplayName: strings.TrimSpace(actorDisplayName),
		ConversationType:  conv.Type,
		MessageType:       msg.Type,
		ReactionEmoji:     reactionEmoji,
		Body:              fmt.Sprintf("Reacted %s to your message", reactionEmoji),
		RecipientUserIDs:  recipients,
	}
}
