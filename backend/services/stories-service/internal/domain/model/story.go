package model

import (
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/stories-service/internal/domain/enum"
)

type Story struct {
	ID               uuid.UUID
	Slug             string
	AuthorUserID     uuid.UUID
	Title            string
	Excerpt          string
	Content          string
	Category         enum.StoryCategory
	Status           enum.StoryStatus
	CoverFileID      *uuid.UUID
	PlaceName        *string
	PlaceCountryCode *string
	PlaceCityID      *string
	Tags             []string
	ViewCount        int
	LikeCount        int
	CommentCount     int
	ShareCount       int
	ViewHLL          []byte
	PublishedAt      *time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
	DeletedAt        *time.Time
}

func (s *Story) IsPublished() bool {
	return s != nil && s.Status == enum.StoryStatusPublished && s.DeletedAt == nil
}

func (s *Story) IsOwnedBy(userID uuid.UUID) bool {
	return s != nil && userID != uuid.Nil && s.AuthorUserID == userID
}

type StoryListFilter struct {
	Search           string
	Categories       []enum.StoryCategory
	AuthorUserID     *uuid.UUID
	ViewerUserID     *uuid.UUID
	IncludeDrafts    bool
	IncludeDeleted   bool
	OnlyPublished    bool
	PlaceQuery       string
	PlaceCountryCode string
	PlaceCityID      string
	Sort             string
	Limit            int
	Offset           int
	ExcludeStoryID   *uuid.UUID
	RelatedToAuthor  *uuid.UUID
}
