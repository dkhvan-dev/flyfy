package model

import (
	"time"
	"github.com/google/uuid"
)

type Conversation struct {
	ID              uuid.UUID
	Type            string // "group" or "direct"
	Title           *string
	AvatarFileID    *string
	ActivityID      *uuid.UUID
	PinnedMessageID *uuid.UUID
	CreatedAt       time.Time
	LastActivityAt  time.Time

	// Populated on read (not stored in conversations table)
	Participants     []*Participant
	PinnedMessage    *Message
	UnreadCount      int
	ParticipantCount int
	LastMessage      *Message
	MutedUntil       *time.Time
}
