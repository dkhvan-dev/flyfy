package model

import (
	"github.com/google/uuid"
	"time"
)

type Conversation struct {
	ID                      uuid.UUID
	Type                    string // "group" or "direct"
	Title                   *string
	AvatarFileID            *string
	ActivityID              *uuid.UUID
	PinnedMessageID         *uuid.UUID
	MessagingAvailableUntil *time.Time
	CreatedAt               time.Time
	LastActivityAt          time.Time

	// Populated on read (not stored in conversations table)
	Participants     []*Participant
	PinnedMessage    *Message
	UnreadCount      int
	ParticipantCount int
	LastMessage      *Message
	MutedUntil       *time.Time
}

func (c *Conversation) IsMessagingClosed(now time.Time) bool {
	if c == nil || c.MessagingAvailableUntil == nil {
		return false
	}
	return !now.UTC().Before(c.MessagingAvailableUntil.UTC())
}
