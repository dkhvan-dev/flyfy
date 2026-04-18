package model

import (
	"time"
	"github.com/google/uuid"
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
}
