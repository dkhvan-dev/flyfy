package model

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
)

type Post struct {
	ID                     uuid.UUID
	Slug                   string
	AuthorUserID           uuid.UUID
	Title                  string
	Excerpt                string
	Content                string
	Format                 enum.PostFormat
	ContentSchemaVersion   int
	ContentBlocks          json.RawMessage
	ContentPlainText       string
	Category               enum.PostCategory
	Status                 enum.PostStatus
	MediaStatus            enum.PostMediaStatus
	ModerationStatus       enum.ModerationStatus
	Revision               int64
	CommunityID            *uuid.UUID
	CommunityInstanceID    *uuid.UUID
	PostKind               enum.PostKind
	PostProfileKey         enum.PostProfileKey
	PostProfileVersion     int
	StructuredData         json.RawMessage
	ModerationMode         enum.ModerationMode
	SourceActivityID       *uuid.UUID
	ActivityCreationStatus *enum.ActivityCreationStatus
	ActivityCreationError  *string
	CoverFileID            *uuid.UUID
	PlaceName              *string
	PlaceCountryCode       *string
	PlaceCityID            *string
	Tags                   []string
	ViewCount              int
	LikeCount              int
	CommentCount           int
	ShareCount             int
	ViewHLL                []byte
	PublishedAt            *time.Time
	ExpiresAt              *time.Time
	LastAutosavedAt        *time.Time
	ArchivedAt             *time.Time
	CreatedAt              time.Time
	UpdatedAt              time.Time
	DeletedAt              *time.Time
	FeedRankedAt           *time.Time
	Media                  []PostMedia
}

func (s *Post) RequiresActivityIntent() bool {
	if s == nil {
		return false
	}
	switch s.PostProfileKey {
	case enum.PostProfileEventAnnouncementV1:
		return true
	case enum.PostProfileTripPlanV1:
		return postStructuredBool(s.StructuredData, "createActivity") ||
			postStructuredBool(s.StructuredData, "create_activity")
	default:
		return false
	}
}

func (s *Post) IsPublished() bool {
	return s != nil && s.Status == enum.PostStatusPublished && s.DeletedAt == nil
}

func (s *Post) IsPubliclyVisible() bool {
	if s == nil || !s.IsPublished() || s.ArchivedAt != nil {
		return false
	}
	if enum.NormalizePostMediaStatus(s.MediaStatus) != enum.PostMediaStatusReady {
		return false
	}
	if s.ExpiresAt != nil && !s.ExpiresAt.After(time.Now().UTC()) {
		return false
	}

	switch s.ModerationStatus {
	case enum.ModerationStatusNotRequired, enum.ModerationStatusApproved:
		return true
	default:
		return false
	}
}

func (s *Post) IsOwnedBy(userID uuid.UUID) bool {
	return s != nil && userID != uuid.Nil && s.AuthorUserID == userID
}

type PostListFilter struct {
	Search                string
	Formats               []enum.PostFormat
	Categories            []enum.PostCategory
	AuthorUserID          *uuid.UUID
	ViewerUserID          *uuid.UUID
	IncludeDrafts         bool
	IncludeDeleted        bool
	OnlyPublished         bool
	Status                *enum.PostStatus
	ModerationStatuses    []enum.ModerationStatus
	ArchivedOnly          bool
	ExcludeArchived       bool
	PlaceQuery            string
	PlaceCountryCode      string
	PlaceCityID           string
	Sort                  string
	Limit                 int
	Offset                int
	ExcludePostID         *uuid.UUID
	RelatedToAuthor       *uuid.UUID
	RelatedToFormat       *enum.PostFormat
	RelatedToCategory     *enum.PostCategory
	RelatedToCountry      string
	RelatedToCityID       string
	RelatedToTags         []string
	CommunityIDs          []uuid.UUID
	OnlyCommunityPosts    bool
	FollowedByUserID      *uuid.UUID
	FeedCursorPublishedAt *time.Time
	FeedCursorPostID      *uuid.UUID
	OnlyExpiring          bool
	ExcludeExpiring       bool
}

func postStructuredBool(raw json.RawMessage, key string) bool {
	if len(raw) == 0 {
		return false
	}
	var values map[string]any
	if err := json.Unmarshal(raw, &values); err != nil {
		return false
	}
	value, ok := values[key]
	if !ok {
		return false
	}
	switch typed := value.(type) {
	case bool:
		return typed
	case string:
		return typed == "true" || typed == "1" || typed == "yes"
	default:
		return false
	}
}
