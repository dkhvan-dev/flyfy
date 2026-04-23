package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/port"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/event"
)

func loadPinnedMessages(
	ctx context.Context,
	repo port.ChatRepository,
	profileResolver port.UserProfileResolver,
	conversationID uuid.UUID,
) ([]*model.ConversationPin, error) {
	pins, err := repo.ListPinnedMessagesByConversationID(ctx, conversationID)
	if err != nil {
		return nil, err
	}

	messages := make([]*model.Message, 0, len(pins))
	for _, pin := range pins {
		if pin == nil || pin.Message == nil {
			continue
		}
		pin.Message.FileIDs, _ = repo.GetMessageFileIDs(ctx, pin.Message.ID)
		messages = append(messages, pin.Message)
	}
	enrichMessages(ctx, profileResolver, messages)

	return pins, nil
}

func publishPinnedMessages(
	ctx context.Context,
	publisher port.EventPublisher,
	conversationID uuid.UUID,
	pins []*model.ConversationPin,
) error {
	evt := event.New("message.pinned", conversationID, event.MessagePinnedPayload{
		PinnedMessages: eventPinnedMessagesFromModel(pins),
	})
	return publisher.Publish(ctx, "chat.message.pinned", evt)
}

func eventPinnedMessagesFromModel(
	pins []*model.ConversationPin,
) []event.PinnedMessageInfo {
	items := make([]event.PinnedMessageInfo, 0, len(pins))
	for _, pin := range pins {
		if pin == nil || pin.Message == nil {
			continue
		}

		items = append(items, event.PinnedMessageInfo{
			MessageID:          pin.Message.ID,
			SenderUserID:       pin.Message.SenderUserID,
			SenderDisplayName:  pin.Message.SenderDisplayName,
			SenderAvatarFileID: pin.Message.SenderAvatarFileID,
			Type:               pin.Message.Type,
			Content:            pin.Message.Content,
			FileIDs:            append([]string(nil), pin.Message.FileIDs...),
			SentAt:             pin.Message.SentAt,
			PinnedAt:           pin.PinnedAt,
		})
	}
	return items
}
