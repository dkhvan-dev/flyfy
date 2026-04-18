package model

import (
	"time"
	"github.com/google/uuid"
)

type Message struct {
	ID                uuid.UUID
	ConversationID    uuid.UUID
	SenderUserID      uuid.UUID
	Type              string // "text", "file", "system"
	Content           string
	ReplyToMessageID  *uuid.UUID
	EditedAt          *time.Time
	DeletedAt         *time.Time
	SentAt            time.Time

	// Populated on read
	FileIDs           []string
	SenderDisplayName string
}
