package model

import (
	"time"

	"github.com/google/uuid"
)

type ChatNotificationOutbox struct {
	ID             uuid.UUID
	EventType      string
	ConversationID uuid.UUID
	MessageID      uuid.UUID
	ActorUserID    uuid.UUID
	ReactionEmoji  string
	Attempts       int
	NextAttemptAt  time.Time
	LockedAt       *time.Time
	ProcessedAt    *time.Time
	FailedAt       *time.Time
	LastError      string
	CreatedAt      time.Time
	UpdatedAt      time.Time
}
