package event

import (
	"github.com/google/uuid"
	"time"
)

type Event struct {
	EventID        uuid.UUID `json:"eventId"`
	Type           string    `json:"type"`
	ConversationID uuid.UUID `json:"conversationId"`
	Payload        any       `json:"payload"`
	Timestamp      time.Time `json:"timestamp"`
}

func New(eventType string, conversationID uuid.UUID, payload any) Event {
	return Event{
		EventID:        uuid.New(),
		Type:           eventType,
		ConversationID: conversationID,
		Payload:        payload,
		Timestamp:      time.Now().UTC(),
	}
}

type MessageSentPayload struct {
	MessageID                 uuid.UUID  `json:"messageId"`
	SenderUserID              uuid.UUID  `json:"senderUserId"`
	SenderDisplayName         string     `json:"senderDisplayName"`
	SenderAvatarFileID        *string    `json:"senderAvatarFileId,omitempty"`
	Type                      string     `json:"type"`
	Content                   string     `json:"content"`
	FileIDs                   []string   `json:"fileIds,omitempty"`
	StickerID                 *uuid.UUID `json:"stickerId,omitempty"`
	StickerFileID             *string    `json:"stickerFileId,omitempty"`
	ReplyToMessageID          *uuid.UUID `json:"replyToMessageId,omitempty"`
	ForwardedFromMessageID    *uuid.UUID `json:"forwardedFromMessageId,omitempty"`
	ForwardedFromSenderUserID *uuid.UUID `json:"forwardedFromSenderUserId,omitempty"`
	ForwardedFromSenderName   string     `json:"forwardedFromSenderName,omitempty"`
	ForwardCount              int        `json:"forwardCount"`
	SentAt                    time.Time  `json:"sentAt"`
}

type MessageForwardedPayload struct {
	MessageID    uuid.UUID `json:"messageId"`
	ForwardCount int       `json:"forwardCount"`
}

type MessageEditedPayload struct {
	MessageID uuid.UUID `json:"messageId"`
	Content   string    `json:"content"`
	EditedAt  time.Time `json:"editedAt"`
}

type MessageDeletedPayload struct {
	MessageID               uuid.UUID  `json:"messageId"`
	DeletedAt               *time.Time `json:"deletedAt,omitempty"`
	HardDeleted             bool       `json:"hardDeleted"`
	ModerationStatus        string     `json:"moderationStatus,omitempty"`
	ModerationPublicComment string     `json:"moderationPublicComment,omitempty"`
}

type MessageReactionUpdatedPayload struct {
	MessageID   uuid.UUID             `json:"messageId"`
	ActorUserID uuid.UUID             `json:"actorUserId"`
	Reactions   []MessageReactionInfo `json:"reactions"`
}

type MessageReactionInfo struct {
	Emoji   string                    `json:"emoji"`
	Count   int                       `json:"count"`
	UserIDs []string                  `json:"userIds,omitempty"`
	Users   []MessageReactionUserInfo `json:"users,omitempty"`
}

type MessageReactionUserInfo struct {
	UserID    string `json:"userId"`
	ReactedAt string `json:"reactedAt"`
}

type ReadUpdatedPayload struct {
	UserID        uuid.UUID `json:"userId"`
	LastReadMsgID uuid.UUID `json:"lastReadMsgId"`
	ReadAt        string    `json:"readAt"`
}

type TypingPayload struct {
	UserID uuid.UUID `json:"userId"`
}

type ParticipantJoinedPayload struct {
	UserID      uuid.UUID `json:"userId"`
	DisplayName string    `json:"displayName"`
}

type ParticipantLeftPayload struct {
	UserID uuid.UUID `json:"userId"`
}

type MessagePinnedPayload struct {
	PinnedMessages []PinnedMessageInfo `json:"pinnedMessages"`
}

type PinnedMessageInfo struct {
	MessageID          uuid.UUID  `json:"id"`
	SenderUserID       uuid.UUID  `json:"senderUserId"`
	SenderDisplayName  string     `json:"senderDisplayName"`
	SenderAvatarFileID *string    `json:"senderAvatarFileId,omitempty"`
	Type               string     `json:"type"`
	Content            string     `json:"content"`
	FileIDs            []string   `json:"fileIds,omitempty"`
	StickerID          *uuid.UUID `json:"stickerId,omitempty"`
	StickerFileID      *string    `json:"stickerFileId,omitempty"`
	SentAt             time.Time  `json:"sentAt"`
	PinnedAt           time.Time  `json:"pinnedAt"`
}
