package model

import (
	"time"

	"github.com/google/uuid"
)

type ConversationPin struct {
	ID             uuid.UUID
	ConversationID uuid.UUID
	MessageID      uuid.UUID
	PinnedByUserID uuid.UUID
	PinnedAt       time.Time

	// Populated on read
	Message *Message
}
