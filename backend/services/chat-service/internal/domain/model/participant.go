package model

import (
	"github.com/google/uuid"
	"time"
)

type Participant struct {
	ID             uuid.UUID
	ConversationID uuid.UUID
	UserID         uuid.UUID
	Role           string // "member" or "admin"
	LastReadMsgID  *uuid.UUID
	MutedUntil     *time.Time
	JoinedAt       time.Time
	LeftAt         *time.Time

	// Populated on read
	DisplayName  string
	AvatarFileID *string
	IsOnline     bool
	LastSeenAt   *time.Time
}
