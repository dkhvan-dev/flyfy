package app

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/port"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/event"
)

const maxMessageSize = 4096
const maxFilesPerMessage = 10
const editWindowHours = 24
const maxReactionLength = 32

const (
	messageTypeText    = "text"
	messageTypeFile    = "file"
	messageTypeSticker = "sticker"
)

var allowedReactionEmojis = map[string]struct{}{
	"👍":  {},
	"❤️": {},
	"😂":  {},
	"😮":  {},
	"😢":  {},
	"🙏":  {},
	"🔥":  {},
}

type MessageUseCase struct {
	repo             port.ChatRepository
	publisher        port.EventPublisher
	profileResolver  port.UserProfileResolver
	activityResolver port.ActivityLifecycleResolver
	stickerResolver  port.StickerResolver
}

func NewMessageUseCase(
	repo port.ChatRepository,
	publisher port.EventPublisher,
	profileResolver port.UserProfileResolver,
	activityResolver ...port.ActivityLifecycleResolver,
) *MessageUseCase {
	return newMessageUseCase(repo, publisher, profileResolver, nil, activityResolver...)
}

func NewMessageUseCaseWithStickerResolver(
	repo port.ChatRepository,
	publisher port.EventPublisher,
	profileResolver port.UserProfileResolver,
	stickerResolver port.StickerResolver,
	activityResolver ...port.ActivityLifecycleResolver,
) *MessageUseCase {
	return newMessageUseCase(repo, publisher, profileResolver, stickerResolver, activityResolver...)
}

func newMessageUseCase(
	repo port.ChatRepository,
	publisher port.EventPublisher,
	profileResolver port.UserProfileResolver,
	stickerResolver port.StickerResolver,
	activityResolver ...port.ActivityLifecycleResolver,
) *MessageUseCase {
	var resolver port.ActivityLifecycleResolver
	if len(activityResolver) > 0 {
		resolver = activityResolver[0]
	}

	return &MessageUseCase{
		repo:             repo,
		publisher:        publisher,
		profileResolver:  profileResolver,
		activityResolver: resolver,
		stickerResolver:  stickerResolver,
	}
}

type SendMessageInput struct {
	ConversationID      uuid.UUID
	SenderUserID        uuid.UUID
	StickerAccessUserID *uuid.UUID
	SenderDisplayName   string
	Type                string
	Content             string
	FileIDs             []string
	StickerID           *uuid.UUID
	ReplyToMessageID    *uuid.UUID
}

type DeleteMessageResult struct {
	HardDeleted bool
	DeletedAt   *time.Time
}

type ToggleMessageReactionResult struct {
	MessageID uuid.UUID
	Reactions []model.MessageReactionSummary
}

func (u *MessageUseCase) SendMessage(ctx context.Context, input SendMessageInput) (*model.Message, error) {
	messageType := strings.ToLower(strings.TrimSpace(input.Type))
	if messageType == "" {
		messageType = messageTypeText
	}

	fileIDs := normalizeMessageFileIDs(input.FileIDs)
	stickerID := input.StickerID
	if stickerID != nil {
		messageType = messageTypeSticker
	}
	if messageType == messageTypeText && len(fileIDs) > 0 {
		messageType = messageTypeFile
	}
	if messageType != messageTypeText && messageType != messageTypeFile && messageType != messageTypeSticker {
		return nil, ErrInvalidMessageType
	}
	var stickerFileID *string
	var stickerPayload *model.StickerPayload
	if messageType == messageTypeSticker {
		if stickerID == nil && len(fileIDs) == 1 {
			parsed, err := uuid.Parse(fileIDs[0])
			if err != nil || parsed == uuid.Nil {
				return nil, ErrInvalidStickerID
			}
			stickerID = &parsed
		}
		if stickerID == nil || *stickerID == uuid.Nil {
			return nil, ErrInvalidStickerID
		}
		if u.stickerResolver == nil {
			return nil, ErrStickerNotAvailable
		}

		stickerAccessUserID := input.SenderUserID
		if input.StickerAccessUserID != nil && *input.StickerAccessUserID != uuid.Nil {
			stickerAccessUserID = *input.StickerAccessUserID
		}
		sticker, err := u.stickerResolver.ValidateSend(ctx, stickerAccessUserID, *stickerID)
		if err != nil || sticker == nil || sticker.FileID == uuid.Nil {
			return nil, ErrStickerNotAvailable
		}
		stickerID = &sticker.StickerID
		fileID := sticker.FileID.String()
		fallbackFileID := sticker.FallbackFileID
		if fallbackFileID == uuid.Nil {
			fallbackFileID = sticker.FileID
		}
		displayFileID := fallbackFileID.String()
		stickerFileID = &displayFileID
		var previewFileID *string
		if sticker.PreviewFileID != nil && *sticker.PreviewFileID != uuid.Nil {
			value := sticker.PreviewFileID.String()
			previewFileID = &value
		}
		stickerPayload = &model.StickerPayload{
			ID:             sticker.StickerID,
			PackID:         sticker.PackID,
			PackSlug:       sticker.PackSlug,
			Slug:           sticker.Slug,
			FileID:         fileID,
			FallbackFileID: fallbackFileID.String(),
			PreviewFileID:  previewFileID,
			ContentType:    sticker.ContentType,
			Width:          sticker.Width,
			Height:         sticker.Height,
			DurationMS:     sticker.DurationMS,
		}
		fileIDs = nil
	}
	if len(input.Content) > maxMessageSize {
		return nil, ErrMessageTooLong
	}
	if len(fileIDs) > maxFilesPerMessage {
		return nil, ErrTooManyFiles
	}

	conv, err := u.repo.GetConversationByID(ctx, input.ConversationID)
	if err != nil {
		return nil, err
	}
	if conv == nil {
		return nil, ErrConversationNotFound
	}
	conv, err = refreshActivityMessagingWindow(ctx, u.repo, u.activityResolver, conv, true)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	if conv.IsMessagingClosed(now) {
		return nil, ErrConversationMessagingClosed
	}

	participant, err := u.repo.GetParticipant(ctx, input.ConversationID, input.SenderUserID)
	if err != nil {
		return nil, err
	}
	if participant == nil || participant.LeftAt != nil {
		return nil, ErrNotParticipant
	}

	msg := &model.Message{
		ID:               uuid.New(),
		ConversationID:   input.ConversationID,
		SenderUserID:     input.SenderUserID,
		Type:             messageType,
		Content:          input.Content,
		StickerID:        stickerID,
		StickerFileID:    stickerFileID,
		StickerPayload:   stickerPayload,
		ReplyToMessageID: input.ReplyToMessageID,
		SentAt:           now,
	}

	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		if err := txRepo.CreateMessage(ctx, msg); err != nil {
			return err
		}

		if len(fileIDs) > 0 {
			if err := txRepo.CreateMessageFiles(ctx, msg.ID, fileIDs); err != nil {
				return err
			}
		}

		conv, err := txRepo.GetConversationByIDForUpdate(ctx, input.ConversationID)
		if err != nil {
			return err
		}
		conv.LastActivityAt = now
		return txRepo.UpdateConversation(ctx, conv)
	})
	if err != nil {
		return nil, err
	}

	msg.FileIDs = fileIDs
	msg.SenderDisplayName = input.SenderDisplayName
	enrichMessages(ctx, u.profileResolver, []*model.Message{msg})

	go func() {
		evt := event.New("message.sent", input.ConversationID, event.MessageSentPayload{
			MessageID:          msg.ID,
			SenderUserID:       msg.SenderUserID,
			SenderDisplayName:  msg.SenderDisplayName,
			SenderAvatarFileID: msg.SenderAvatarFileID,
			Type:               msg.Type,
			Content:            msg.Content,
			FileIDs:            fileIDs,
			StickerID:          msg.StickerID,
			StickerFileID:      msg.StickerFileID,
			ReplyToMessageID:   input.ReplyToMessageID,
			SentAt:             msg.SentAt,
		})
		if pubErr := u.publisher.Publish(context.Background(), "chat.message.sent", evt); pubErr != nil {
			log.Error().Err(pubErr).Msg("failed to publish message.sent event")
		}
	}()

	return msg, nil
}

func normalizeMessageFileIDs(fileIDs []string) []string {
	if len(fileIDs) == 0 {
		return nil
	}

	seen := make(map[string]struct{}, len(fileIDs))
	normalized := make([]string, 0, len(fileIDs))
	for _, raw := range fileIDs {
		fileID := strings.TrimSpace(raw)
		if fileID == "" {
			continue
		}
		if _, ok := seen[fileID]; ok {
			continue
		}
		seen[fileID] = struct{}{}
		normalized = append(normalized, fileID)
	}
	return normalized
}

func (u *MessageUseCase) EditMessage(ctx context.Context, conversationID, messageID, actorUserID uuid.UUID, newContent string) (*model.Message, error) {
	if len(newContent) > maxMessageSize {
		return nil, ErrMessageTooLong
	}

	msg, err := u.repo.GetMessageByID(ctx, messageID)
	if err != nil {
		return nil, err
	}
	if msg == nil || msg.ConversationID != conversationID {
		return nil, ErrMessageNotFound
	}
	if msg.SenderUserID != actorUserID {
		return nil, ErrNotMessageAuthor
	}
	if msg.DeletedAt != nil {
		return nil, ErrMessageAlreadyDeleted
	}
	if time.Since(msg.SentAt) > editWindowHours*time.Hour {
		return nil, ErrMessageEditExpired
	}

	now := time.Now().UTC()
	msg.Content = newContent
	msg.EditedAt = &now

	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		return txRepo.UpdateMessage(ctx, msg)
	})
	if err != nil {
		return nil, err
	}

	go func() {
		evt := event.New("message.edited", conversationID, event.MessageEditedPayload{
			MessageID: messageID,
			Content:   newContent,
			EditedAt:  now,
		})
		_ = u.publisher.Publish(context.Background(), "chat.message.edited", evt)
	}()

	return msg, nil
}

func (u *MessageUseCase) DeleteMessage(
	ctx context.Context,
	conversationID,
	messageID,
	actorUserID uuid.UUID,
) (*DeleteMessageResult, error) {
	msg, err := u.repo.GetMessageByID(ctx, messageID)
	if err != nil {
		return nil, err
	}
	if msg == nil || msg.ConversationID != conversationID {
		return nil, ErrMessageNotFound
	}
	if msg.DeletedAt != nil {
		return nil, ErrMessageAlreadyDeleted
	}

	if msg.SenderUserID != actorUserID {
		return nil, ErrNotMessageAuthor
	}

	now := time.Now().UTC()
	result := &DeleteMessageResult{}
	var pinsChanged bool

	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		removedPinsCount, err := txRepo.DeleteConversationPinsByMessageID(ctx, msg.ID)
		if err != nil {
			return err
		}
		pinsChanged = removedPinsCount > 0

		readByOthers, err := txRepo.HasReadByOtherParticipant(
			ctx,
			conversationID,
			messageID,
			actorUserID,
		)
		if err != nil {
			return err
		}

		if readByOthers {
			msg.DeletedAt = &now
			if err := txRepo.UpdateMessage(ctx, msg); err != nil {
				return err
			}
			result.HardDeleted = false
			result.DeletedAt = &now
			return nil
		}

		previousMsg, err := txRepo.GetPreviousMessage(
			ctx,
			conversationID,
			msg.SentAt,
			msg.ID,
		)
		if err != nil {
			return err
		}

		var previousMessageID *uuid.UUID
		if previousMsg != nil {
			previousMessageID = &previousMsg.ID
		}
		if err := txRepo.ReplaceLastReadMessageID(
			ctx,
			conversationID,
			msg.ID,
			previousMessageID,
		); err != nil {
			return err
		}

		if err := txRepo.DeleteMessage(ctx, msg.ID); err != nil {
			return err
		}

		conv, err := txRepo.GetConversationByIDForUpdate(ctx, conversationID)
		if err != nil {
			return err
		}
		if conv != nil {
			lastMessage, err := txRepo.GetLastMessage(ctx, conversationID)
			if err != nil {
				return err
			}
			if lastMessage != nil {
				conv.LastActivityAt = lastMessage.SentAt
			} else {
				conv.LastActivityAt = conv.CreatedAt
			}
			if err := txRepo.UpdateConversation(ctx, conv); err != nil {
				return err
			}
		}

		result.HardDeleted = true
		result.DeletedAt = nil
		return nil
	})
	if err != nil {
		return nil, err
	}

	var pinnedMessages []*model.ConversationPin
	if pinsChanged {
		pinnedMessages, _ = loadPinnedMessages(
			ctx,
			u.repo,
			u.profileResolver,
			conversationID,
		)
	}

	publishedPins := pinnedMessages
	go func() {
		evt := event.New("message.deleted", conversationID, event.MessageDeletedPayload{
			MessageID:   messageID,
			DeletedAt:   result.DeletedAt,
			HardDeleted: result.HardDeleted,
		})
		_ = u.publisher.Publish(context.Background(), "chat.message.deleted", evt)
		if pinsChanged {
			_ = publishPinnedMessages(
				context.Background(),
				u.publisher,
				conversationID,
				publishedPins,
			)
		}
	}()

	return result, nil
}

func (u *MessageUseCase) ToggleReaction(
	ctx context.Context,
	conversationID,
	messageID,
	actorUserID uuid.UUID,
	emoji string,
) (*ToggleMessageReactionResult, error) {
	reactionEmoji := strings.TrimSpace(emoji)
	if reactionEmoji == "" || len(reactionEmoji) > maxReactionLength {
		return nil, ErrInvalidReaction
	}
	if _, ok := allowedReactionEmojis[reactionEmoji]; !ok {
		return nil, ErrInvalidReaction
	}

	conv, err := u.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return nil, err
	}
	if conv == nil {
		return nil, ErrConversationNotFound
	}
	conv, err = refreshActivityMessagingWindow(ctx, u.repo, u.activityResolver, conv, true)
	if err != nil {
		return nil, err
	}
	if conv.IsMessagingClosed(time.Now().UTC()) {
		return nil, ErrConversationMessagingClosed
	}

	msg, err := u.repo.GetMessageByID(ctx, messageID)
	if err != nil {
		return nil, err
	}
	if msg == nil || msg.ConversationID != conversationID {
		return nil, ErrMessageNotFound
	}
	if msg.DeletedAt != nil || msg.Type == "system" {
		return nil, ErrInvalidReaction
	}

	participant, err := u.repo.GetParticipant(ctx, conversationID, actorUserID)
	if err != nil {
		return nil, err
	}
	if participant == nil || participant.LeftAt != nil {
		return nil, ErrNotParticipant
	}

	now := time.Now().UTC()
	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		current, err := txRepo.GetMessageReactionForUpdate(ctx, messageID, actorUserID)
		if err != nil {
			return err
		}
		if current != nil && current.Emoji == reactionEmoji {
			return txRepo.DeleteMessageReaction(ctx, messageID, actorUserID)
		}
		return txRepo.SetMessageReaction(ctx, &model.MessageReaction{
			MessageID: messageID,
			UserID:    actorUserID,
			Emoji:     reactionEmoji,
			ReactedAt: now,
		})
	})
	if err != nil {
		return nil, err
	}

	reactionsByMessage, err := u.repo.ListMessageReactionSummaries(
		ctx,
		[]uuid.UUID{messageID},
		actorUserID,
	)
	if err != nil {
		return nil, err
	}
	reactions := reactionsByMessage[messageID]

	go func() {
		evt := event.New(
			"message.reaction_updated",
			conversationID,
			event.MessageReactionUpdatedPayload{
				MessageID:   messageID,
				ActorUserID: actorUserID,
				Reactions:   reactionSummariesForEvent(reactions),
			},
		)
		_ = u.publisher.Publish(context.Background(), "chat.message.reaction_updated", evt)
	}()

	return &ToggleMessageReactionResult{
		MessageID: messageID,
		Reactions: reactions,
	}, nil
}

func (u *MessageUseCase) ListMessages(ctx context.Context, conversationID, actorUserID uuid.UUID, limit int, cursor *uuid.UUID, direction string) ([]*model.Message, error) {
	participant, err := u.repo.GetParticipant(ctx, conversationID, actorUserID)
	if err != nil {
		return nil, err
	}
	if participant == nil || participant.LeftAt != nil {
		return nil, ErrNotParticipant
	}

	if limit <= 0 || limit > 100 {
		limit = 50
	}
	if direction == "" {
		direction = "older"
	}

	msgs, err := u.repo.ListMessages(ctx, port.MessageFilter{
		ConversationID: conversationID,
		Limit:          limit,
		Cursor:         cursor,
		Direction:      direction,
	})
	if err != nil {
		return nil, err
	}

	for _, msg := range msgs {
		msg.FileIDs, _ = u.repo.GetMessageFileIDs(ctx, msg.ID)
	}
	if len(msgs) > 0 {
		messageIDs := make([]uuid.UUID, 0, len(msgs))
		for _, msg := range msgs {
			messageIDs = append(messageIDs, msg.ID)
		}
		reactions, err := u.repo.ListMessageReactionSummaries(ctx, messageIDs, actorUserID)
		if err != nil {
			return nil, err
		}
		for _, msg := range msgs {
			msg.Reactions = reactions[msg.ID]
		}
	}
	enrichMessages(ctx, u.profileResolver, msgs)

	return msgs, nil
}

func reactionSummariesForEvent(
	reactions []model.MessageReactionSummary,
) []event.MessageReactionInfo {
	items := make([]event.MessageReactionInfo, 0, len(reactions))
	for _, reaction := range reactions {
		items = append(items, event.MessageReactionInfo{
			Emoji: reaction.Emoji,
			Count: reaction.Count,
		})
	}
	return items
}

func (u *MessageUseCase) MarkRead(ctx context.Context, conversationID, actorUserID, lastReadMsgID uuid.UUID) error {
	msg, err := u.repo.GetMessageByID(ctx, lastReadMsgID)
	if err != nil {
		return err
	}
	if msg == nil || msg.ConversationID != conversationID {
		return ErrMessageNotFound
	}

	participant, err := u.repo.GetParticipant(ctx, conversationID, actorUserID)
	if err != nil {
		return err
	}
	if participant == nil || participant.LeftAt != nil {
		return ErrNotParticipant
	}

	participant.LastReadMsgID = &lastReadMsgID

	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		return txRepo.UpdateParticipant(ctx, participant)
	})
	if err != nil {
		return err
	}

	go func() {
		evt := event.New("read.updated", conversationID, event.ReadUpdatedPayload{
			UserID:        actorUserID,
			LastReadMsgID: lastReadMsgID,
		})
		_ = u.publisher.Publish(context.Background(), "chat.read.updated", evt)
	}()

	return nil
}

func (u *MessageUseCase) PublishTyping(ctx context.Context, conversationID, actorUserID uuid.UUID) error {
	evt := event.New("typing", conversationID, event.TypingPayload{UserID: actorUserID})
	return u.publisher.Publish(ctx, "chat.typing."+conversationID.String(), evt)
}
