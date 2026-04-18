package port

import (
	"context"
	"time"
	"github.com/google/uuid"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/model"
)

type ConversationFilter struct {
	UserID *uuid.UUID
	Type   *string
	Limit  int
	Cursor *time.Time
}

type MessageFilter struct {
	ConversationID uuid.UUID
	Limit          int
	Cursor         *uuid.UUID
	Direction      string // "older" or "newer"
}

type ChatTxRepository interface {
	CreateConversation(ctx context.Context, conv *model.Conversation) error
	UpdateConversation(ctx context.Context, conv *model.Conversation) error
	GetConversationByIDForUpdate(ctx context.Context, conversationID uuid.UUID) (*model.Conversation, error)
	CreateParticipant(ctx context.Context, p *model.Participant) error
	UpdateParticipant(ctx context.Context, p *model.Participant) error
	CreateMessage(ctx context.Context, msg *model.Message) error
	UpdateMessage(ctx context.Context, msg *model.Message) error
	CreateMessageFiles(ctx context.Context, messageID uuid.UUID, fileIDs []string) error
}

type ChatRepository interface {
	GetConversationByID(ctx context.Context, conversationID uuid.UUID) (*model.Conversation, error)
	ListConversationsByUserID(ctx context.Context, filter ConversationFilter) ([]*model.Conversation, error)
	FindDirectConversation(ctx context.Context, userID1, userID2 uuid.UUID) (*model.Conversation, error)
	GetConversationByActivityID(ctx context.Context, activityID uuid.UUID) (*model.Conversation, error)
	GetMessageByID(ctx context.Context, messageID uuid.UUID) (*model.Message, error)
	ListMessages(ctx context.Context, filter MessageFilter) ([]*model.Message, error)
	ListParticipantsByConversationID(ctx context.Context, conversationID uuid.UUID) ([]*model.Participant, error)
	GetParticipant(ctx context.Context, conversationID, userID uuid.UUID) (*model.Participant, error)
	CountActiveParticipants(ctx context.Context, conversationID uuid.UUID) (int, error)
	GetUnreadCount(ctx context.Context, conversationID, userID uuid.UUID) (int, error)
	GetLastMessage(ctx context.Context, conversationID uuid.UUID) (*model.Message, error)
	GetMessageFileIDs(ctx context.Context, messageID uuid.UUID) ([]string, error)
	WithTx(ctx context.Context, fn func(repo ChatTxRepository) error) error
}
