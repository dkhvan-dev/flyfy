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

type ConversationUseCase struct {
	repo      port.ChatRepository
	publisher port.EventPublisher
}

func NewConversationUseCase(repo port.ChatRepository, publisher port.EventPublisher) *ConversationUseCase {
	return &ConversationUseCase{repo: repo, publisher: publisher}
}

type CreateDirectConversationInput struct {
	ActorUserID      uuid.UUID
	ParticipantUserID uuid.UUID
}

func (u *ConversationUseCase) CreateDirectConversation(ctx context.Context, input CreateDirectConversationInput) (*model.Conversation, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidUserID
	}
	if input.ParticipantUserID == uuid.Nil {
		return nil, ErrInvalidUserID
	}

	existing, err := u.repo.FindDirectConversation(ctx, input.ActorUserID, input.ParticipantUserID)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return existing, nil
	}

	convType := "direct"
	now := time.Now().UTC()

	var conv *model.Conversation
	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		conv = &model.Conversation{
			ID:             uuid.New(),
			Type:           convType,
			CreatedAt:      now,
			LastActivityAt: now,
		}
		if err := txRepo.CreateConversation(ctx, conv); err != nil {
			return err
		}

		for _, uid := range []uuid.UUID{input.ActorUserID, input.ParticipantUserID} {
			if err := txRepo.CreateParticipant(ctx, &model.Participant{
				ID:             uuid.New(),
				ConversationID: conv.ID,
				UserID:         uid,
				Role:           "member",
				JoinedAt:       now,
			}); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	go func() {
		evt := event.New("conversation.created", conv.ID, nil)
		if pubErr := u.publisher.Publish(context.Background(), "chat.conversation.created", evt); pubErr != nil {
			log.Error().Err(pubErr).Str("conversation_id", conv.ID.String()).Msg("failed to publish conversation.created event")
		}
	}()

	return conv, nil
}

type CreateActivityConversationInput struct {
	ActivityID uuid.UUID
	Title      string
	HostUserID uuid.UUID
}

func (u *ConversationUseCase) CreateActivityConversation(ctx context.Context, input CreateActivityConversationInput) (*model.Conversation, error) {
	existing, err := u.repo.GetConversationByActivityID(ctx, input.ActivityID)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return existing, nil
	}

	convType := "group"
	title := strings.TrimSpace(input.Title)
	now := time.Now().UTC()

	var conv *model.Conversation
	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		conv = &model.Conversation{
			ID:             uuid.New(),
			Type:           convType,
			Title:          &title,
			ActivityID:     &input.ActivityID,
			CreatedAt:      now,
			LastActivityAt: now,
		}
		if err := txRepo.CreateConversation(ctx, conv); err != nil {
			return err
		}

		if err := txRepo.CreateParticipant(ctx, &model.Participant{
			ID:             uuid.New(),
			ConversationID: conv.ID,
			UserID:         input.HostUserID,
			Role:           "admin",
			JoinedAt:       now,
		}); err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	return conv, nil
}

func (u *ConversationUseCase) GetConversationByID(ctx context.Context, conversationID, actorUserID uuid.UUID) (*model.Conversation, error) {
	conv, err := u.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return nil, err
	}
	if conv == nil {
		return nil, ErrConversationNotFound
	}

	participant, err := u.repo.GetParticipant(ctx, conversationID, actorUserID)
	if err != nil {
		return nil, err
	}
	if participant == nil || participant.LeftAt != nil {
		return nil, ErrNotParticipant
	}

	conv.Participants, err = u.repo.ListParticipantsByConversationID(ctx, conversationID)
	if err != nil {
		return nil, err
	}

	conv.UnreadCount, err = u.repo.GetUnreadCount(ctx, conversationID, actorUserID)
	if err != nil {
		return nil, err
	}

	if conv.PinnedMessageID != nil {
		conv.PinnedMessage, _ = u.repo.GetMessageByID(ctx, *conv.PinnedMessageID)
	}

	return conv, nil
}

func (u *ConversationUseCase) ListConversations(ctx context.Context, actorUserID uuid.UUID, convType *string, limit int, cursor *time.Time) ([]*model.Conversation, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}

	convs, err := u.repo.ListConversationsByUserID(ctx, port.ConversationFilter{
		UserID: &actorUserID,
		Type:   convType,
		Limit:  limit,
		Cursor: cursor,
	})
	if err != nil {
		return nil, err
	}

	for _, conv := range convs {
		conv.LastMessage, _ = u.repo.GetLastMessage(ctx, conv.ID)
		conv.UnreadCount, _ = u.repo.GetUnreadCount(ctx, conv.ID, actorUserID)
		count, _ := u.repo.CountActiveParticipants(ctx, conv.ID)
		conv.ParticipantCount = count

		participant, _ := u.repo.GetParticipant(ctx, conv.ID, actorUserID)
		if participant != nil {
			conv.MutedUntil = participant.MutedUntil
		}
	}

	return convs, nil
}

func (u *ConversationUseCase) AddParticipant(ctx context.Context, conversationID, userID uuid.UUID, displayName string) error {
	conv, err := u.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return err
	}
	if conv == nil {
		return ErrConversationNotFound
	}

	count, err := u.repo.CountActiveParticipants(ctx, conversationID)
	if err != nil {
		return err
	}
	if count >= 200 {
		return ErrConversationFull
	}

	now := time.Now().UTC()
	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		if err := txRepo.CreateParticipant(ctx, &model.Participant{
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         userID,
			Role:           "member",
			JoinedAt:       now,
		}); err != nil {
			return err
		}

		systemMsg := &model.Message{
			ID:             uuid.New(),
			ConversationID: conversationID,
			SenderUserID:   userID,
			Type:           "system",
			Content:        displayName + " joined",
			SentAt:         now,
		}
		if err := txRepo.CreateMessage(ctx, systemMsg); err != nil {
			return err
		}

		conv.LastActivityAt = now
		return txRepo.UpdateConversation(ctx, conv)
	})
	if err != nil {
		return err
	}

	go func() {
		evt := event.New("participant.joined", conversationID, event.ParticipantJoinedPayload{
			UserID:      userID,
			DisplayName: displayName,
		})
		_ = u.publisher.Publish(context.Background(), "chat.participant.joined", evt)
	}()

	return nil
}

func (u *ConversationUseCase) RemoveParticipant(ctx context.Context, conversationID, userID uuid.UUID) error {
	participant, err := u.repo.GetParticipant(ctx, conversationID, userID)
	if err != nil {
		return err
	}
	if participant == nil || participant.LeftAt != nil {
		return ErrParticipantNotFound
	}

	now := time.Now().UTC()
	participant.LeftAt = &now

	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		if err := txRepo.UpdateParticipant(ctx, participant); err != nil {
			return err
		}

		systemMsg := &model.Message{
			ID:             uuid.New(),
			ConversationID: conversationID,
			SenderUserID:   userID,
			Type:           "system",
			Content:        "User left",
			SentAt:         now,
		}
		return txRepo.CreateMessage(ctx, systemMsg)
	})
	if err != nil {
		return err
	}

	go func() {
		evt := event.New("participant.left", conversationID, event.ParticipantLeftPayload{UserID: userID})
		_ = u.publisher.Publish(context.Background(), "chat.participant.left", evt)
	}()

	return nil
}

func (u *ConversationUseCase) LeaveConversation(ctx context.Context, conversationID, actorUserID uuid.UUID) error {
	conv, err := u.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return err
	}
	if conv == nil {
		return ErrConversationNotFound
	}
	if conv.Type == "direct" {
		return ErrDirectChatCannotLeave
	}

	return u.RemoveParticipant(ctx, conversationID, actorUserID)
}

type MuteInput struct {
	ConversationID uuid.UUID
	ActorUserID    uuid.UUID
	Until          *time.Time
}

func (u *ConversationUseCase) MuteConversation(ctx context.Context, input MuteInput) error {
	participant, err := u.repo.GetParticipant(ctx, input.ConversationID, input.ActorUserID)
	if err != nil {
		return err
	}
	if participant == nil || participant.LeftAt != nil {
		return ErrNotParticipant
	}

	participant.MutedUntil = input.Until

	return u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		return txRepo.UpdateParticipant(ctx, participant)
	})
}

func (u *ConversationUseCase) PinMessage(ctx context.Context, conversationID, messageID, actorUserID uuid.UUID) error {
	conv, err := u.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return err
	}
	if conv == nil {
		return ErrConversationNotFound
	}
	if conv.Type == "direct" {
		return ErrCannotPinInDirectChat
	}

	participant, err := u.repo.GetParticipant(ctx, conversationID, actorUserID)
	if err != nil {
		return err
	}
	if participant == nil || participant.LeftAt != nil {
		return ErrNotParticipant
	}
	if participant.Role != "admin" {
		return ErrNotAdmin
	}

	msg, err := u.repo.GetMessageByID(ctx, messageID)
	if err != nil {
		return err
	}
	if msg == nil || msg.ConversationID != conversationID {
		return ErrMessageNotFound
	}

	conv.PinnedMessageID = &messageID
	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		return txRepo.UpdateConversation(ctx, conv)
	})
	if err != nil {
		return err
	}

	go func() {
		evt := event.New("message.pinned", conversationID, event.MessagePinnedPayload{
			PinnedMessage: &event.PinnedMessageInfo{
				MessageID:         msg.ID,
				SenderUserID:      msg.SenderUserID,
				SenderDisplayName: msg.SenderDisplayName,
				Content:           msg.Content,
				SentAt:            msg.SentAt,
			},
		})
		_ = u.publisher.Publish(context.Background(), "chat.message.pinned", evt)
	}()

	return nil
}

func (u *ConversationUseCase) UnpinMessage(ctx context.Context, conversationID, actorUserID uuid.UUID) error {
	conv, err := u.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return err
	}
	if conv == nil {
		return ErrConversationNotFound
	}

	participant, err := u.repo.GetParticipant(ctx, conversationID, actorUserID)
	if err != nil {
		return err
	}
	if participant == nil || participant.LeftAt != nil {
		return ErrNotParticipant
	}
	if participant.Role != "admin" {
		return ErrNotAdmin
	}

	conv.PinnedMessageID = nil
	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		return txRepo.UpdateConversation(ctx, conv)
	})
	if err != nil {
		return err
	}

	go func() {
		evt := event.New("message.pinned", conversationID, event.MessagePinnedPayload{PinnedMessage: nil})
		_ = u.publisher.Publish(context.Background(), "chat.message.pinned", evt)
	}()

	return nil
}
