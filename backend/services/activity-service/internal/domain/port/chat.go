package port

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type EnsureActivityParticipantInput struct {
	ActivityID              uuid.UUID
	ActivityTitle           string
	ActivityAvatarFileID    string
	MessagingAvailableUntil *time.Time
	HostUserID              uuid.UUID
	UserID                  uuid.UUID
	DisplayName             string
}

type SyncActivityConversationInput struct {
	ActivityID              uuid.UUID
	ActivityTitle           string
	ActivityAvatarFileID    string
	MessagingAvailableUntil *time.Time
}

type ActivityChatGateway interface {
	EnsureActivityParticipant(ctx context.Context, input EnsureActivityParticipantInput) error
	SyncActivityConversation(ctx context.Context, input SyncActivityConversationInput) error
}
