package model

import (
	"time"

	"github.com/google/uuid"
)

type UserBlock struct {
	BlockerUserID uuid.UUID
	BlockedUserID uuid.UUID
	CreatedAt     time.Time
}

type UserBlockStatus struct {
	UserID        uuid.UUID
	IsBlockedByMe bool
	HasBlockedMe  bool
}
