package port

import (
	"context"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/model"
	"github.com/google/uuid"
	"time"
)

type ActivityLifecycle struct {
	ActivityID  uuid.UUID
	EndAt       time.Time
	CancelledAt *time.Time
	CompletedAt *time.Time
}

type ActivityLifecycleResolver interface {
	GetActivityLifecycle(ctx context.Context, activityID uuid.UUID) (*ActivityLifecycle, error)
}

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
	GetConversationByActivityIDForUpdate(ctx context.Context, activityID uuid.UUID) (*model.Conversation, error)
	GetParticipantForUpdate(ctx context.Context, conversationID, userID uuid.UUID) (*model.Participant, error)
	CountActiveParticipants(ctx context.Context, conversationID uuid.UUID) (int, error)
	CreateParticipant(ctx context.Context, p *model.Participant) error
	UpdateParticipant(ctx context.Context, p *model.Participant) error
	CreateMessage(ctx context.Context, msg *model.Message) error
	UpdateMessage(ctx context.Context, msg *model.Message) error
	DeleteMessage(ctx context.Context, messageID uuid.UUID) error
	GetMessageReactionForUpdate(
		ctx context.Context,
		messageID uuid.UUID,
		userID uuid.UUID,
	) (*model.MessageReaction, error)
	SetMessageReaction(ctx context.Context, reaction *model.MessageReaction) error
	DeleteMessageReaction(ctx context.Context, messageID uuid.UUID, userID uuid.UUID) error
	CreateConversationPin(ctx context.Context, pin *model.ConversationPin) error
	DeleteConversationPin(ctx context.Context, conversationID, messageID uuid.UUID) (bool, error)
	DeleteConversationPinsByMessageID(ctx context.Context, messageID uuid.UUID) (int64, error)
	GetLastMessage(ctx context.Context, conversationID uuid.UUID) (*model.Message, error)
	GetPreviousMessage(
		ctx context.Context,
		conversationID uuid.UUID,
		sentAt time.Time,
		messageID uuid.UUID,
	) (*model.Message, error)
	HasReadByOtherParticipant(
		ctx context.Context,
		conversationID uuid.UUID,
		messageID uuid.UUID,
		actorUserID uuid.UUID,
	) (bool, error)
	ReplaceLastReadMessageID(
		ctx context.Context,
		conversationID uuid.UUID,
		fromMessageID uuid.UUID,
		toMessageID *uuid.UUID,
	) error
	CreateMessageFiles(ctx context.Context, messageID uuid.UUID, fileIDs []string) error
}

type ChatRepository interface {
	GetConversationByID(ctx context.Context, conversationID uuid.UUID) (*model.Conversation, error)
	ListConversationsByUserID(ctx context.Context, filter ConversationFilter) ([]*model.Conversation, error)
	FindDirectConversation(ctx context.Context, userID1, userID2 uuid.UUID) (*model.Conversation, error)
	GetConversationByActivityID(ctx context.Context, activityID uuid.UUID) (*model.Conversation, error)
	GetMessageByID(ctx context.Context, messageID uuid.UUID) (*model.Message, error)
	ListMessages(ctx context.Context, filter MessageFilter) ([]*model.Message, error)
	ListMessageReactionSummaries(
		ctx context.Context,
		messageIDs []uuid.UUID,
		actorUserID uuid.UUID,
	) (map[uuid.UUID][]model.MessageReactionSummary, error)
	ListParticipantsByConversationID(ctx context.Context, conversationID uuid.UUID) ([]*model.Participant, error)
	GetParticipant(ctx context.Context, conversationID, userID uuid.UUID) (*model.Participant, error)
	CountActiveParticipants(ctx context.Context, conversationID uuid.UUID) (int, error)
	GetUnreadCount(ctx context.Context, conversationID, userID uuid.UUID) (int, error)
	GetLastMessage(ctx context.Context, conversationID uuid.UUID) (*model.Message, error)
	GetMessageFileIDs(ctx context.Context, messageID uuid.UUID) ([]string, error)
	ListPinnedMessagesByConversationID(ctx context.Context, conversationID uuid.UUID) ([]*model.ConversationPin, error)
	WithTx(ctx context.Context, fn func(repo ChatTxRepository) error) error
}
