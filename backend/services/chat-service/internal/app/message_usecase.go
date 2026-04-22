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

type MessageUseCase struct {
	repo             port.ChatRepository
	publisher        port.EventPublisher
	profileResolver  port.UserProfileResolver
	activityResolver port.ActivityLifecycleResolver
}

func NewMessageUseCase(
	repo port.ChatRepository,
	publisher port.EventPublisher,
	profileResolver port.UserProfileResolver,
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
	}
}

type SendMessageInput struct {
	ConversationID    uuid.UUID
	SenderUserID      uuid.UUID
	SenderDisplayName string
	Type              string
	Content           string
	FileIDs           []string
	ReplyToMessageID  *uuid.UUID
}

func (u *MessageUseCase) SendMessage(ctx context.Context, input SendMessageInput) (*model.Message, error) {
	messageType := strings.TrimSpace(input.Type)
	if messageType == "" {
		messageType = "text"
	}
	if messageType != "text" && messageType != "file" {
		return nil, ErrInvalidMessageType
	}
	if len(input.Content) > maxMessageSize {
		return nil, ErrMessageTooLong
	}
	if len(input.FileIDs) > maxFilesPerMessage {
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
		ReplyToMessageID: input.ReplyToMessageID,
		SentAt:           now,
	}

	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		if err := txRepo.CreateMessage(ctx, msg); err != nil {
			return err
		}

		if len(input.FileIDs) > 0 {
			if err := txRepo.CreateMessageFiles(ctx, msg.ID, input.FileIDs); err != nil {
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

	msg.FileIDs = input.FileIDs
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
			FileIDs:            input.FileIDs,
			ReplyToMessageID:   input.ReplyToMessageID,
			SentAt:             msg.SentAt,
		})
		if pubErr := u.publisher.Publish(context.Background(), "chat.message.sent", evt); pubErr != nil {
			log.Error().Err(pubErr).Msg("failed to publish message.sent event")
		}
	}()

	return msg, nil
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

func (u *MessageUseCase) DeleteMessage(ctx context.Context, conversationID, messageID, actorUserID uuid.UUID) error {
	msg, err := u.repo.GetMessageByID(ctx, messageID)
	if err != nil {
		return err
	}
	if msg == nil || msg.ConversationID != conversationID {
		return ErrMessageNotFound
	}
	if msg.DeletedAt != nil {
		return ErrMessageAlreadyDeleted
	}

	if msg.SenderUserID != actorUserID {
		participant, err := u.repo.GetParticipant(ctx, conversationID, actorUserID)
		if err != nil {
			return err
		}
		if participant == nil || participant.Role != "admin" {
			return ErrNotMessageAuthor
		}
	}

	now := time.Now().UTC()
	msg.DeletedAt = &now

	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		return txRepo.UpdateMessage(ctx, msg)
	})
	if err != nil {
		return err
	}

	go func() {
		evt := event.New("message.deleted", conversationID, event.MessageDeletedPayload{
			MessageID: messageID,
			DeletedAt: now,
		})
		_ = u.publisher.Publish(context.Background(), "chat.message.deleted", evt)
	}()

	return nil
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
	enrichMessages(ctx, u.profileResolver, msgs)

	return msgs, nil
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
