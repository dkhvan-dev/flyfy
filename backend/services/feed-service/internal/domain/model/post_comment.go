package model

import (
	"time"

	"github.com/google/uuid"
)

type PostComment struct {
	ID           uuid.UUID
	PostID       uuid.UUID
	AuthorUserID uuid.UUID
	Body         string
	LikeCount    int
	CreatedAt    time.Time
	UpdatedAt    time.Time
	DeletedAt    *time.Time
}

func (c *PostComment) IsOwnedBy(userID uuid.UUID) bool {
	return c != nil && userID != uuid.Nil && c.AuthorUserID == userID
}

func (c *PostComment) IsEdited() bool {
	return c != nil && c.UpdatedAt.After(c.CreatedAt.Add(time.Second))
}
