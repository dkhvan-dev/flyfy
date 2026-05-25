package app

import (
	"context"
	"regexp"
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
const moderationContextWindow = 5

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

var phoneLikePattern = regexp.MustCompile(`(?i)(?:\+?\d[\d\s().-]{6,}\d)`)

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

type ForwardMessageInput struct {
	SourceConversationID uuid.UUID
	TargetConversationID uuid.UUID
	MessageID            uuid.UUID
	SenderUserID         uuid.UUID
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
	moderationStatus := model.MessageModerationStatusVisible
	moderationReasonCodes, moderationRiskScore := detectMessageModerationSignals(input.Content)
	var moderationTriggeredAt *time.Time
	if moderationRiskScore > 0 {
		moderationStatus = model.MessageModerationStatusFlagged
		moderationTriggeredAt = &now
	}
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
		ID:                    uuid.New(),
		ConversationID:        input.ConversationID,
		SenderUserID:          input.SenderUserID,
		Type:                  messageType,
		Content:               input.Content,
		StickerID:             stickerID,
		StickerFileID:         stickerFileID,
		StickerPayload:        stickerPayload,
		ReplyToMessageID:      input.ReplyToMessageID,
		ModerationStatus:      moderationStatus,
		ModerationReasonCodes: moderationReasonCodes,
		ModerationRiskScore:   moderationRiskScore,
		ModerationTriggeredAt: moderationTriggeredAt,
		ModerationRevision:    1,
		SentAt:                now,
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
			MessageID:                 msg.ID,
			SenderUserID:              msg.SenderUserID,
			SenderDisplayName:         msg.SenderDisplayName,
			SenderAvatarFileID:        msg.SenderAvatarFileID,
			Type:                      msg.Type,
			Content:                   msg.Content,
			FileIDs:                   fileIDs,
			StickerID:                 msg.StickerID,
			StickerFileID:             msg.StickerFileID,
			ReplyToMessageID:          input.ReplyToMessageID,
			ForwardedFromMessageID:    msg.ForwardedFromMessageID,
			ForwardedFromSenderUserID: msg.ForwardedFromSenderUserID,
			ForwardedFromSenderName:   msg.ForwardedFromSenderName,
			ForwardCount:              msg.ForwardCount,
			SentAt:                    msg.SentAt,
		})
		if pubErr := u.publisher.Publish(context.Background(), "chat.message.sent", evt); pubErr != nil {
			log.Error().Err(pubErr).Msg("failed to publish message.sent event")
		}
	}()

	return msg, nil
}

func (u *MessageUseCase) ForwardMessage(ctx context.Context, input ForwardMessageInput) (*model.Message, error) {
	sourceMessage, err := u.repo.GetMessageByID(ctx, input.MessageID)
	if err != nil {
		return nil, err
	}
	if sourceMessage == nil ||
		sourceMessage.ConversationID != input.SourceConversationID ||
		sourceMessage.DeletedAt != nil ||
		sourceMessage.Type == "system" {
		return nil, ErrMessageNotFound
	}
	sourceParticipant, err := u.repo.GetParticipant(ctx, input.SourceConversationID, input.SenderUserID)
	if err != nil {
		return nil, err
	}
	if sourceParticipant == nil || sourceParticipant.LeftAt != nil {
		return nil, ErrNotParticipant
	}

	targetConversation, err := u.repo.GetConversationByID(ctx, input.TargetConversationID)
	if err != nil {
		return nil, err
	}
	if targetConversation == nil {
		return nil, ErrConversationNotFound
	}
	targetConversation, err = refreshActivityMessagingWindow(ctx, u.repo, u.activityResolver, targetConversation, true)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	if targetConversation.IsMessagingClosed(now) {
		return nil, ErrConversationMessagingClosed
	}

	targetParticipant, err := u.repo.GetParticipant(ctx, input.TargetConversationID, input.SenderUserID)
	if err != nil {
		return nil, err
	}
	if targetParticipant == nil || targetParticipant.LeftAt != nil {
		return nil, ErrNotParticipant
	}

	fileIDs, err := u.repo.GetMessageFileIDs(ctx, sourceMessage.ID)
	if err != nil {
		return nil, err
	}
	sourceMessage.FileIDs = fileIDs
	enrichMessages(ctx, u.profileResolver, []*model.Message{sourceMessage})

	forwardedFromMessageID := sourceMessage.ID
	forwardedFromSenderUserID := sourceMessage.SenderUserID
	forwardedFromSenderName := strings.TrimSpace(sourceMessage.SenderDisplayName)
	if sourceMessage.ForwardedFromMessageID != nil && *sourceMessage.ForwardedFromMessageID != uuid.Nil {
		forwardedFromMessageID = *sourceMessage.ForwardedFromMessageID
	}
	if sourceMessage.ForwardedFromSenderUserID != nil && *sourceMessage.ForwardedFromSenderUserID != uuid.Nil {
		forwardedFromSenderUserID = *sourceMessage.ForwardedFromSenderUserID
	}
	if strings.TrimSpace(sourceMessage.ForwardedFromSenderName) != "" {
		forwardedFromSenderName = strings.TrimSpace(sourceMessage.ForwardedFromSenderName)
	}
	if forwardedFromSenderName == "" {
		forwardedFromSenderName = forwardedFromSenderUserID.String()
	}

	forwarded := &model.Message{
		ID:                        uuid.New(),
		ConversationID:            input.TargetConversationID,
		SenderUserID:              input.SenderUserID,
		Type:                      sourceMessage.Type,
		Content:                   sourceMessage.Content,
		StickerID:                 sourceMessage.StickerID,
		StickerFileID:             sourceMessage.StickerFileID,
		StickerPayload:            sourceMessage.StickerPayload,
		ForwardedFromMessageID:    &forwardedFromMessageID,
		ForwardedFromSenderUserID: &forwardedFromSenderUserID,
		ForwardedFromSenderName:   forwardedFromSenderName,
		SentAt:                    now,
	}

	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		if err := txRepo.CreateMessage(ctx, forwarded); err != nil {
			return err
		}
		if len(fileIDs) > 0 {
			if err := txRepo.CreateMessageFiles(ctx, forwarded.ID, fileIDs); err != nil {
				return err
			}
		}

		sourceForUpdate := *sourceMessage
		sourceForUpdate.ForwardCount++
		if err := txRepo.UpdateMessage(ctx, &sourceForUpdate); err != nil {
			return err
		}
		sourceMessage.ForwardCount = sourceForUpdate.ForwardCount

		conv, err := txRepo.GetConversationByIDForUpdate(ctx, input.TargetConversationID)
		if err != nil {
			return err
		}
		if conv == nil {
			return ErrConversationNotFound
		}
		conv.LastActivityAt = now
		return txRepo.UpdateConversation(ctx, conv)
	})
	if err != nil {
		return nil, err
	}

	forwarded.FileIDs = fileIDs
	enrichMessages(ctx, u.profileResolver, []*model.Message{forwarded})

	go func() {
		evt := event.New("message.sent", input.TargetConversationID, event.MessageSentPayload{
			MessageID:                 forwarded.ID,
			SenderUserID:              forwarded.SenderUserID,
			SenderDisplayName:         forwarded.SenderDisplayName,
			SenderAvatarFileID:        forwarded.SenderAvatarFileID,
			Type:                      forwarded.Type,
			Content:                   forwarded.Content,
			FileIDs:                   fileIDs,
			StickerID:                 forwarded.StickerID,
			StickerFileID:             forwarded.StickerFileID,
			ForwardedFromMessageID:    forwarded.ForwardedFromMessageID,
			ForwardedFromSenderUserID: forwarded.ForwardedFromSenderUserID,
			ForwardedFromSenderName:   forwarded.ForwardedFromSenderName,
			ForwardCount:              forwarded.ForwardCount,
			SentAt:                    forwarded.SentAt,
		})
		if pubErr := u.publisher.Publish(context.Background(), "chat.message.sent", evt); pubErr != nil {
			log.Error().Err(pubErr).Msg("failed to publish forwarded message.sent event")
		}
		sourceEvt := event.New("message.forwarded", input.SourceConversationID, event.MessageForwardedPayload{
			MessageID:    sourceMessage.ID,
			ForwardCount: sourceMessage.ForwardCount,
		})
		if pubErr := u.publisher.Publish(context.Background(), "chat.message.forwarded", sourceEvt); pubErr != nil {
			log.Error().Err(pubErr).Msg("failed to publish message.forwarded event")
		}
	}()

	return forwarded, nil
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
		readReceipts, err := u.repo.ListMessageReadReceipts(ctx, messageIDs)
		if err != nil {
			return nil, err
		}
		for _, msg := range msgs {
			if msg.SenderUserID == actorUserID {
				msg.ReadReceipts = readReceipts[msg.ID]
			}
		}
	}
	enrichMessages(ctx, u.profileResolver, msgs)

	return msgs, nil
}

func (u *MessageUseCase) ListFlaggedMessagesForModeration(ctx context.Context, limit int, offset int) ([]*model.ChatMessageModerationItem, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	if offset < 0 {
		offset = 0
	}
	items, err := u.repo.ListFlaggedMessagesForModeration(ctx, port.ChatModerationFilter{
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		return nil, err
	}
	enrichModerationItems(ctx, u.profileResolver, items)
	return items, nil
}

func (u *MessageUseCase) GetMessageForModeration(ctx context.Context, messageID uuid.UUID) (*model.ChatMessageModerationItem, error) {
	if messageID == uuid.Nil {
		return nil, ErrInvalidMessageID
	}
	item, err := u.repo.GetMessageForModeration(ctx, messageID, moderationContextWindow, moderationContextWindow)
	if err != nil {
		return nil, err
	}
	if item == nil {
		return nil, ErrMessageNotFound
	}
	enrichModerationItems(ctx, u.profileResolver, []*model.ChatMessageModerationItem{item})
	return item, nil
}

func (u *MessageUseCase) ApproveMessageForModeration(
	ctx context.Context,
	messageID uuid.UUID,
	actorStaffID uuid.UUID,
	internalComment string,
) (*model.ChatMessageModerationItem, error) {
	if strings.TrimSpace(internalComment) == "" {
		return nil, ErrInvalidModerationDecision
	}
	msg, err := u.repo.UpdateMessageModeration(
		ctx,
		messageID,
		model.MessageModerationStatusCleared,
		nil,
		"",
		internalComment,
		actorStaffID,
		time.Now().UTC(),
	)
	if err != nil {
		return nil, err
	}
	if msg == nil {
		return nil, ErrMessageNotFound
	}
	return u.GetMessageForModeration(ctx, messageID)
}

func (u *MessageUseCase) HideMessageForModeration(
	ctx context.Context,
	messageID uuid.UUID,
	actorStaffID uuid.UUID,
	reasonCodes []string,
	publicComment string,
	internalComment string,
) (*model.ChatMessageModerationItem, error) {
	reasonCodes = normalizeModerationReasonCodes(reasonCodes)
	if len(reasonCodes) == 0 ||
		strings.TrimSpace(publicComment) == "" ||
		strings.TrimSpace(internalComment) == "" {
		return nil, ErrInvalidModerationDecision
	}
	msg, err := u.repo.UpdateMessageModeration(
		ctx,
		messageID,
		model.MessageModerationStatusHiddenByModeration,
		reasonCodes,
		publicComment,
		internalComment,
		actorStaffID,
		time.Now().UTC(),
	)
	if err != nil {
		return nil, err
	}
	if msg == nil {
		return nil, ErrMessageNotFound
	}
	if u.publisher != nil {
		go func() {
			deletedAt := msg.ModerationReviewedAt
			evt := event.New("message.deleted", msg.ConversationID, event.MessageDeletedPayload{
				MessageID:               messageID,
				DeletedAt:               deletedAt,
				HardDeleted:             false,
				ModerationStatus:        model.MessageModerationStatusHiddenByModeration,
				ModerationPublicComment: strings.TrimSpace(msg.ModerationPublicComment),
			})
			_ = u.publisher.Publish(context.Background(), "chat.message.deleted", evt)
		}()
	}
	return u.GetMessageForModeration(ctx, messageID)
}

func detectMessageModerationSignals(content string) ([]string, int) {
	content = strings.TrimSpace(content)
	if content == "" {
		return nil, 0
	}
	lower := strings.ToLower(content)
	codes := make([]string, 0, 3)
	risk := 0
	if strings.Contains(lower, "whatsapp") ||
		strings.Contains(lower, "telegram") ||
		strings.Contains(lower, "instagram") ||
		strings.Contains(lower, "wa.me/") ||
		strings.Contains(lower, "t.me/") {
		codes = append(codes, "off_platform_contact")
		risk += 60
	}
	if phoneLikePattern.MatchString(content) {
		codes = append(codes, "phone_number")
		risk += 30
	}
	if strings.Contains(lower, "http://") || strings.Contains(lower, "https://") {
		codes = append(codes, "external_link")
		risk += 20
	}
	codes = normalizeModerationReasonCodes(codes)
	if risk > 100 {
		risk = 100
	}
	return codes, risk
}

func normalizeModerationReasonCodes(input []string) []string {
	seen := make(map[string]struct{}, len(input))
	out := make([]string, 0, len(input))
	for _, code := range input {
		code = strings.ToLower(strings.TrimSpace(code))
		if code == "" {
			continue
		}
		if _, ok := seen[code]; ok {
			continue
		}
		seen[code] = struct{}{}
		out = append(out, code)
	}
	return out
}

func enrichModerationItems(ctx context.Context, resolver port.UserProfileResolver, items []*model.ChatMessageModerationItem) {
	if resolver == nil || len(items) == 0 {
		return
	}
	userIDs := make([]uuid.UUID, 0, len(items)*3)
	for _, item := range items {
		if item == nil {
			continue
		}
		if item.SenderUserID != uuid.Nil {
			userIDs = append(userIDs, item.SenderUserID)
		}
		for _, participant := range item.Participants {
			if participant.UserID != uuid.Nil {
				userIDs = append(userIDs, participant.UserID)
			}
		}
		for _, message := range item.ContextBefore {
			if message.SenderUserID != uuid.Nil {
				userIDs = append(userIDs, message.SenderUserID)
			}
		}
		for _, message := range item.ContextAfter {
			if message.SenderUserID != uuid.Nil {
				userIDs = append(userIDs, message.SenderUserID)
			}
		}
	}
	profiles := loadPublicProfiles(ctx, resolver, userIDs)
	for _, item := range items {
		if item == nil {
			continue
		}
		if profile, ok := profiles[item.SenderUserID]; ok && strings.TrimSpace(profile.DisplayName) != "" {
			item.SenderDisplayName = profile.DisplayName
		}
		for idx := range item.Participants {
			if profile, ok := profiles[item.Participants[idx].UserID]; ok && strings.TrimSpace(profile.DisplayName) != "" {
				item.Participants[idx].DisplayName = profile.DisplayName
			}
		}
		enrichModerationContextMessages(profiles, item.ContextBefore)
		enrichModerationContextMessages(profiles, item.ContextAfter)
	}
}

func enrichModerationContextMessages(profiles map[uuid.UUID]port.PublicUserProfile, messages []model.ChatMessageContextItem) {
	for idx := range messages {
		if profile, ok := profiles[messages[idx].SenderUserID]; ok && strings.TrimSpace(profile.DisplayName) != "" {
			messages[idx].SenderDisplayName = profile.DisplayName
		}
	}
}

func reactionSummariesForEvent(
	reactions []model.MessageReactionSummary,
) []event.MessageReactionInfo {
	items := make([]event.MessageReactionInfo, 0, len(reactions))
	for _, reaction := range reactions {
		items = append(items, event.MessageReactionInfo{
			Emoji:   reaction.Emoji,
			Count:   reaction.Count,
			UserIDs: reaction.UserIDs,
			Users:   reactionUsersForEvent(reaction.Users),
		})
	}
	return items
}

func reactionUsersForEvent(
	users []model.MessageReactionUserSummary,
) []event.MessageReactionUserInfo {
	items := make([]event.MessageReactionUserInfo, 0, len(users))
	for _, user := range users {
		items = append(items, event.MessageReactionUserInfo{
			UserID:    user.UserID,
			ReactedAt: user.ReactedAt.UTC().Format(time.RFC3339Nano),
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

	readAt := time.Now().UTC()
	participant.LastReadMsgID = &lastReadMsgID

	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		if err := txRepo.UpdateParticipant(ctx, participant); err != nil {
			return err
		}
		return txRepo.CreateReadReceiptsUpToMessage(
			ctx,
			conversationID,
			actorUserID,
			lastReadMsgID,
			readAt,
		)
	})
	if err != nil {
		return err
	}

	go func() {
		evt := event.New("read.updated", conversationID, event.ReadUpdatedPayload{
			UserID:        actorUserID,
			LastReadMsgID: lastReadMsgID,
			ReadAt:        readAt.Format(time.RFC3339),
		})
		_ = u.publisher.Publish(context.Background(), "chat.read.updated", evt)
	}()

	return nil
}

func (u *MessageUseCase) PublishTyping(ctx context.Context, conversationID, actorUserID uuid.UUID) error {
	evt := event.New("typing", conversationID, event.TypingPayload{UserID: actorUserID})
	return u.publisher.Publish(ctx, "chat.typing."+conversationID.String(), evt)
}
