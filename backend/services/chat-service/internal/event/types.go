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
	MessageID          uuid.UUID  `json:"messageId"`
	SenderUserID       uuid.UUID  `json:"senderUserId"`
	SenderDisplayName  string     `json:"senderDisplayName"`
	SenderAvatarFileID *string    `json:"senderAvatarFileId,omitempty"`
	Type               string     `json:"type"`
	Content            string     `json:"content"`
	FileIDs            []string   `json:"fileIds,omitempty"`
	ReplyToMessageID   *uuid.UUID `json:"replyToMessageId,omitempty"`
	SentAt             time.Time  `json:"sentAt"`
}

type MessageEditedPayload struct {
	MessageID uuid.UUID `json:"messageId"`
	Content   string    `json:"content"`
	EditedAt  time.Time `json:"editedAt"`
}

type MessageDeletedPayload struct {
	MessageID   uuid.UUID  `json:"messageId"`
	DeletedAt   *time.Time `json:"deletedAt,omitempty"`
	HardDeleted bool       `json:"hardDeleted"`
}

type ReadUpdatedPayload struct {
	UserID        uuid.UUID `json:"userId"`
	LastReadMsgID uuid.UUID `json:"lastReadMsgId"`
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
	MessageID          uuid.UUID `json:"id"`
	SenderUserID       uuid.UUID `json:"senderUserId"`
	SenderDisplayName  string    `json:"senderDisplayName"`
	SenderAvatarFileID *string   `json:"senderAvatarFileId,omitempty"`
	Type               string    `json:"type"`
	Content            string    `json:"content"`
	FileIDs            []string  `json:"fileIds,omitempty"`
	SentAt             time.Time `json:"sentAt"`
	PinnedAt           time.Time `json:"pinnedAt"`
}
