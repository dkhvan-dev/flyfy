package model

import (
	"github.com/google/uuid"
	"time"
)

type Message struct {
	ID               uuid.UUID
	ConversationID   uuid.UUID
	SenderUserID     uuid.UUID
	Type             string // "text", "file", "sticker", "system"
	Content          string
	StickerID        *uuid.UUID
	StickerFileID    *string
	ReplyToMessageID *uuid.UUID
	EditedAt         *time.Time
	DeletedAt        *time.Time
	SentAt           time.Time

	// Populated on read
	FileIDs            []string
	Reactions          []MessageReactionSummary
	SenderDisplayName  string
	SenderAvatarFileID *string
}

type MessageReaction struct {
	MessageID uuid.UUID
	UserID    uuid.UUID
	Emoji     string
	ReactedAt time.Time
}

type MessageReactionSummary struct {
	Emoji       string
	Count       int
	ReactedByMe bool
}
