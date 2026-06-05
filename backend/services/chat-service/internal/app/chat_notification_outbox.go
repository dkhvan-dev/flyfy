package app

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/chat-service/internal/domain/model"
	"kz/inflap/backend/services/chat-service/internal/domain/port"
)

const (
	defaultChatNotificationOutboxLimit       = 100
	defaultChatNotificationOutboxMaxAttempts = 8
	defaultChatNotificationOutboxBaseDelay   = 2 * time.Second
	defaultChatNotificationOutboxMaxDelay    = 5 * time.Minute
)

type ChatNotificationDispatcherConfig struct {
	BatchSize      int
	MaxAttempts    int
	BaseRetryDelay time.Duration
	MaxRetryDelay  time.Duration
}

type ChatNotificationDispatcher struct {
	repo            port.ChatRepository
	sender          port.ChatNotificationSender
	profileResolver port.UserProfileResolver
	config          ChatNotificationDispatcherConfig
}

func NewChatNotificationDispatcher(
	repo port.ChatRepository,
	sender port.ChatNotificationSender,
	profileResolver port.UserProfileResolver,
	config ChatNotificationDispatcherConfig,
) *ChatNotificationDispatcher {
	if config.BatchSize <= 0 {
		config.BatchSize = defaultChatNotificationOutboxLimit
	}
	if config.MaxAttempts <= 0 {
		config.MaxAttempts = defaultChatNotificationOutboxMaxAttempts
	}
	if config.BaseRetryDelay <= 0 {
		config.BaseRetryDelay = defaultChatNotificationOutboxBaseDelay
	}
	if config.MaxRetryDelay <= 0 {
		config.MaxRetryDelay = defaultChatNotificationOutboxMaxDelay
	}
	return &ChatNotificationDispatcher{
		repo:            repo,
		sender:          sender,
		profileResolver: profileResolver,
		config:          config,
	}
}

func (d *ChatNotificationDispatcher) DispatchDue(ctx context.Context, now time.Time, limit int) (int, error) {
	if d == nil || d.repo == nil {
		return 0, nil
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}
	if limit <= 0 {
		limit = d.config.BatchSize
	}
	items, err := d.repo.ClaimDueChatNotificationOutbox(ctx, now, limit)
	if err != nil {
		return 0, err
	}

	sent := 0
	for _, item := range items {
		if item == nil || item.ID == uuid.Nil {
			continue
		}
		if err := d.dispatchOne(ctx, item, now); err != nil {
			d.scheduleRetry(ctx, item, now, err)
			continue
		}
		if err := d.repo.MarkChatNotificationOutboxSent(ctx, item.ID, now); err != nil {
			log.Error().Err(err).Str("outbox_id", item.ID.String()).Msg("failed to mark chat notification outbox sent")
			continue
		}
		sent++
	}
	return sent, nil
}

func (d *ChatNotificationDispatcher) dispatchOne(
	ctx context.Context,
	item *model.ChatNotificationOutbox,
	now time.Time,
) error {
	if d.sender == nil {
		return nil
	}

	conv, err := d.repo.GetConversationByID(ctx, item.ConversationID)
	if err != nil || conv == nil {
		return err
	}
	msg, err := d.repo.GetMessageByID(ctx, item.MessageID)
	if err != nil || msg == nil || msg.ConversationID != item.ConversationID {
		return err
	}
	msg.FileIDs, _ = d.repo.GetMessageFileIDs(ctx, msg.ID)
	enrichMessages(ctx, d.profileResolver, []*model.Message{msg})

	notification, ok, err := d.notificationForOutbox(ctx, conv, msg, item)
	if err != nil || !ok {
		return err
	}
	return d.sender.SendChatMessageNotification(ctx, notification)
}

func (d *ChatNotificationDispatcher) notificationForOutbox(
	ctx context.Context,
	conv *model.Conversation,
	msg *model.Message,
	item *model.ChatNotificationOutbox,
) (port.ChatNotification, bool, error) {
	switch strings.TrimSpace(item.EventType) {
	case chatNotificationEventMessage:
		recipients, err := resolveChatNotificationRecipients(ctx, d.repo, conv.ID, msg.SenderUserID, nil)
		if err != nil || len(recipients) == 0 {
			return port.ChatNotification{}, false, err
		}
		return chatMessageNotification(conv, msg, recipients), true, nil
	case chatNotificationEventPin:
		if item.ActorUserID == uuid.Nil {
			return port.ChatNotification{}, false, nil
		}
		recipients, err := resolveChatNotificationRecipients(ctx, d.repo, conv.ID, item.ActorUserID, nil)
		if err != nil || len(recipients) == 0 {
			return port.ChatNotification{}, false, err
		}
		actorDisplayName := displayNameForUser(ctx, d.profileResolver, item.ActorUserID, "User")
		return chatPinNotification(conv, msg, item.ActorUserID, actorDisplayName, recipients), true, nil
	case chatNotificationEventReaction:
		if item.ActorUserID == uuid.Nil || strings.TrimSpace(item.ReactionEmoji) == "" {
			return port.ChatNotification{}, false, nil
		}
		recipients, err := resolveChatNotificationRecipients(
			ctx,
			d.repo,
			conv.ID,
			item.ActorUserID,
			[]uuid.UUID{msg.SenderUserID},
		)
		if err != nil || len(recipients) == 0 {
			return port.ChatNotification{}, false, err
		}
		actorDisplayName := displayNameForUser(ctx, d.profileResolver, item.ActorUserID, "User")
		return chatReactionNotification(conv, msg, item.ActorUserID, actorDisplayName, item.ReactionEmoji, recipients), true, nil
	default:
		return port.ChatNotification{}, false, nil
	}
}

func (d *ChatNotificationDispatcher) scheduleRetry(
	ctx context.Context,
	item *model.ChatNotificationOutbox,
	now time.Time,
	err error,
) {
	lastError := strings.TrimSpace(err.Error())
	if item.Attempts >= d.config.MaxAttempts {
		if failErr := d.repo.FailChatNotificationOutbox(ctx, item.ID, now, lastError); failErr != nil {
			log.Error().Err(failErr).Str("outbox_id", item.ID.String()).Msg("failed to mark chat notification outbox failed")
		}
		return
	}
	delay := d.retryDelay(item.Attempts)
	if retryErr := d.repo.RetryChatNotificationOutbox(ctx, item.ID, now.Add(delay), lastError); retryErr != nil {
		log.Error().Err(retryErr).Str("outbox_id", item.ID.String()).Msg("failed to schedule chat notification outbox retry")
	}
}

func (d *ChatNotificationDispatcher) retryDelay(attempts int) time.Duration {
	if attempts < 1 {
		attempts = 1
	}
	delay := d.config.BaseRetryDelay
	for i := 1; i < attempts; i++ {
		delay *= 2
		if delay >= d.config.MaxRetryDelay {
			return d.config.MaxRetryDelay
		}
	}
	return delay
}

func newChatNotificationOutbox(
	eventType string,
	conversationID uuid.UUID,
	messageID uuid.UUID,
	actorUserID uuid.UUID,
	reactionEmoji string,
	now time.Time,
) *model.ChatNotificationOutbox {
	if now.IsZero() {
		now = time.Now().UTC()
	}
	return &model.ChatNotificationOutbox{
		ID:             uuid.New(),
		EventType:      eventType,
		ConversationID: conversationID,
		MessageID:      messageID,
		ActorUserID:    actorUserID,
		ReactionEmoji:  strings.TrimSpace(reactionEmoji),
		NextAttemptAt:  now,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
}
