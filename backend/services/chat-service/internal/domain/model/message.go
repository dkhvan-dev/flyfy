package model

import (
	"github.com/google/uuid"
	"time"
)

type Message struct {
	ID                        uuid.UUID
	ConversationID            uuid.UUID
	SenderUserID              uuid.UUID
	ClientMessageID           *uuid.UUID
	Type                      string // "text", "file", "sticker", "system"
	Content                   string
	StickerID                 *uuid.UUID
	StickerFileID             *string
	StickerPayload            *StickerPayload
	ReplyToMessageID          *uuid.UUID
	StoryReply                *StoryReplyContext
	ForwardedFromMessageID    *uuid.UUID
	ForwardedFromSenderUserID *uuid.UUID
	ForwardedFromSenderName   string
	ForwardCount              int
	EditedAt                  *time.Time
	DeletedAt                 *time.Time
	ModerationStatus          string
	ModerationReasonCodes     []string
	ModerationRiskScore       int
	ModerationTriggeredAt     *time.Time
	ModerationReviewedAt      *time.Time
	ModerationReviewedBy      *uuid.UUID
	ModerationPublicComment   string
	ModerationInternalComment string
	ModerationRevision        int
	SentAt                    time.Time

	// Populated on read
	FileIDs            []string
	Reactions          []MessageReactionSummary
	ReadReceipts       []MessageReadReceipt
	SenderDisplayName  string
	SenderAvatarFileID *string
}

type StoryReplyContext struct {
	StoryID            uuid.UUID  `json:"storyId"`
	StoryAuthorUserID  uuid.UUID  `json:"storyAuthorUserId"`
	StoryTitle         string     `json:"storyTitle,omitempty"`
	StoryPreviewFileID string     `json:"storyPreviewFileId,omitempty"`
	StoryPreviewURL    string     `json:"storyPreviewUrl,omitempty"`
	StoryExpiresAt     *time.Time `json:"storyExpiresAt,omitempty"`
}

func (c StoryReplyContext) IsZero() bool {
	return c.StoryID == uuid.Nil && c.StoryAuthorUserID == uuid.Nil
}

const (
	MessageModerationStatusVisible            = "VISIBLE"
	MessageModerationStatusFlagged            = "FLAGGED"
	MessageModerationStatusCleared            = "CLEARED"
	MessageModerationStatusHiddenByModeration = "HIDDEN_BY_MODERATION"
)

func (m Message) IsHiddenByModeration() bool {
	return m.ModerationStatus == MessageModerationStatusHiddenByModeration
}

type ChatParticipantModerationItem struct {
	UserID      uuid.UUID `json:"userId"`
	DisplayName string    `json:"displayName,omitempty"`
	Role        string    `json:"role,omitempty"`
}

type ChatMessageContextItem struct {
	ID                uuid.UUID  `json:"id"`
	SenderUserID      uuid.UUID  `json:"senderUserId"`
	SenderDisplayName string     `json:"senderDisplayName,omitempty"`
	Type              string     `json:"type"`
	Content           string     `json:"content"`
	FileIDs           []string   `json:"fileIds,omitempty"`
	EditedAt          *time.Time `json:"editedAt,omitempty"`
	DeletedAt         *time.Time `json:"deletedAt,omitempty"`
	SentAt            time.Time  `json:"sentAt"`
}

type ChatMessageModerationItem struct {
	ID                      uuid.UUID
	ConversationID          uuid.UUID
	ConversationType        string
	ConversationTitle       string
	ActivityID              *uuid.UUID
	ExcursionScheduleSlotID *uuid.UUID

	SenderUserID      uuid.UUID
	SenderDisplayName string
	Type              string
	Content           string
	FileIDs           []string

	ModerationStatus      string
	ModerationRiskScore   int
	ModerationReasonCodes []string
	ModerationTriggeredAt *time.Time
	ModerationReviewedAt  *time.Time

	ContextBefore []ChatMessageContextItem
	ContextAfter  []ChatMessageContextItem
	Participants  []ChatParticipantModerationItem

	Revision  int
	EditedAt  *time.Time
	DeletedAt *time.Time
	SentAt    time.Time
	CreatedAt time.Time
	UpdatedAt time.Time
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
	UserIDs     []string
	Users       []MessageReactionUserSummary
}

type MessageReactionUserSummary struct {
	UserID    string
	ReactedAt time.Time
}

type MessageReadReceipt struct {
	MessageID uuid.UUID
	UserID    uuid.UUID
	ReadAt    time.Time
}
