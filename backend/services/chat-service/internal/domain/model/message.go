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
	StickerPayload   *StickerPayload
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

type StickerPayload struct {
	ID             uuid.UUID `json:"id"`
	PackID         uuid.UUID `json:"packId"`
	PackSlug       string    `json:"packSlug"`
	Slug           string    `json:"slug"`
	FileID         string    `json:"fileId"`
	FallbackFileID string    `json:"fallbackFileId"`
	PreviewFileID  *string   `json:"previewFileId,omitempty"`
	ContentType    string    `json:"contentType"`
	Width          int       `json:"width"`
	Height         int       `json:"height"`
	DurationMS     int       `json:"durationMs"`
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
