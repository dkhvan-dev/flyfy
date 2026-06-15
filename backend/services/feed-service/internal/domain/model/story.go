package model

import (
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
)

type Story struct {
	ID           uuid.UUID
	AuthorUserID uuid.UUID
	Caption      string
	MediaFileID  uuid.UUID
	CoverFileID  uuid.UUID
	MediaType    enum.StoryMediaType
	ViewCount    int
	LikeCount    int
	ReplyCount   int
	ExpiresAt    time.Time
	CreatedAt    time.Time
	UpdatedAt    time.Time
	DeletedAt    *time.Time
}

func (c *Story) IsActive(now time.Time) bool {
	return c != nil &&
		c.DeletedAt == nil &&
		c.ExpiresAt.After(now.UTC())
}

func (c *Story) IsOwnedBy(userID uuid.UUID) bool {
	return c != nil && userID != uuid.Nil && c.AuthorUserID == userID
}

type StoryListFilter struct {
	StoryID          *uuid.UUID
	AuthorUserID     *uuid.UUID
	ViewerUserID     *uuid.UUID
	FollowedByUserID *uuid.UUID
	Limit            int
	Offset           int
	IncludeExpired   bool
	OnlyExpired      bool
}
