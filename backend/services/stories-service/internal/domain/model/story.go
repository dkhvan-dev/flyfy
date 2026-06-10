package model

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/stories-service/internal/domain/enum"
)

type Story struct {
	ID                   uuid.UUID
	Slug                 string
	AuthorUserID         uuid.UUID
	Title                string
	Excerpt              string
	Content              string
	Format               enum.StoryFormat
	ContentSchemaVersion int
	ContentBlocks        json.RawMessage
	ContentPlainText     string
	Category             enum.StoryCategory
	Status               enum.StoryStatus
	ModerationStatus     enum.ModerationStatus
	Revision             int64
	CoverFileID          *uuid.UUID
	PlaceName            *string
	PlaceCountryCode     *string
	PlaceCityID          *string
	Tags                 []string
	ViewCount            int
	LikeCount            int
	CommentCount         int
	ShareCount           int
	ViewHLL              []byte
	PublishedAt          *time.Time
	LastAutosavedAt      *time.Time
	ArchivedAt           *time.Time
	CreatedAt            time.Time
	UpdatedAt            time.Time
	DeletedAt            *time.Time
}

func (s *Story) IsPublished() bool {
	return s != nil && s.Status == enum.StoryStatusPublished && s.DeletedAt == nil
}

func (s *Story) IsPubliclyVisible() bool {
	if s == nil || !s.IsPublished() || s.ArchivedAt != nil {
		return false
	}

	switch s.ModerationStatus {
	case enum.ModerationStatusNotRequired, enum.ModerationStatusApproved:
		return true
	default:
		return false
	}
}

func (s *Story) IsOwnedBy(userID uuid.UUID) bool {
	return s != nil && userID != uuid.Nil && s.AuthorUserID == userID
}

type StoryListFilter struct {
	Search            string
	Formats           []enum.StoryFormat
	Categories        []enum.StoryCategory
	AuthorUserID      *uuid.UUID
	ViewerUserID      *uuid.UUID
	IncludeDrafts     bool
	IncludeDeleted    bool
	OnlyPublished     bool
	Status            *enum.StoryStatus
	ArchivedOnly      bool
	ExcludeArchived   bool
	PlaceQuery        string
	PlaceCountryCode  string
	PlaceCityID       string
	Sort              string
	Limit             int
	Offset            int
	ExcludeStoryID    *uuid.UUID
	RelatedToAuthor   *uuid.UUID
	RelatedToFormat   *enum.StoryFormat
	RelatedToCategory *enum.StoryCategory
	RelatedToCountry  string
	RelatedToCityID   string
	RelatedToTags     []string
}
