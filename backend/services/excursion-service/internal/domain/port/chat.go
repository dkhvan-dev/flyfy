package port

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type SyncExcursionScheduleSlotConversationInput struct {
	ScheduleSlotID          uuid.UUID
	ExcursionTitle          string
	ExcursionAvatarFileID   string
	MessagingAvailableUntil *time.Time
	GuideUserID             uuid.UUID
	ParticipantUserIDs      []uuid.UUID
}

type ExcursionChatGateway interface {
	SyncExcursionScheduleSlotConversation(ctx context.Context, input SyncExcursionScheduleSlotConversationInput) error
}
