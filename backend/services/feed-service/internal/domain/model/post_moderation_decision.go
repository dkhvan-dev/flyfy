package model

import (
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
)

type PostModerationDecision struct {
	ID              uuid.UUID
	PostID          uuid.UUID
	CommunityID     uuid.UUID
	ModeratorUserID uuid.UUID
	Decision        enum.PostModerationDecision
	PreviousStatus  enum.ModerationStatus
	NextStatus      enum.ModerationStatus
	PostRevision    int64
	Reason          string
	CreatedAt       time.Time
}

type PostModerationDecisionListFilter struct {
	PostID      uuid.UUID
	CommunityID uuid.UUID
	Limit       int
	Offset      int
}
