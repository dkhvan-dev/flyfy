package port

import (
	"context"

	"github.com/google/uuid"
)

type ChatNotification struct {
	IdempotencyKey    string
	EventType         string
	ConversationID    uuid.UUID
	MessageID         uuid.UUID
	SenderUserID      uuid.UUID
	SenderDisplayName string
	ConversationType  string
	MessageType       string
	ReactionEmoji     string
	Body              string
	RecipientUserIDs  []uuid.UUID
}

type ChatNotificationSender interface {
	SendChatMessageNotification(ctx context.Context, notification ChatNotification) error
}
