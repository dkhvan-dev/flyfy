package dto

import "encoding/json"

type CreateStoryRequest struct {
	Title                string          `json:"title"`
	Content              string          `json:"content"`
	Format               string          `json:"format"`
	ContentBlocks        json.RawMessage `json:"contentBlocks"`
	ContentSchemaVersion int             `json:"contentSchemaVersion"`
	Revision             int64           `json:"revision"`
	Category             string          `json:"category"`
	Status               string          `json:"status"`
	CoverFileID          *string         `json:"coverFileId"`
	PlaceName            *string         `json:"placeName"`
	PlaceCountryCode     *string         `json:"placeCountryCode"`
	PlaceCityID          *string         `json:"placeCityId"`
	Tags                 []string        `json:"tags"`
}

type UpdateStoryRequest struct {
	Title                *string          `json:"title"`
	Content              *string          `json:"content"`
	Format               *string          `json:"format"`
	ContentBlocks        *json.RawMessage `json:"contentBlocks"`
	ContentSchemaVersion *int             `json:"contentSchemaVersion"`
	Revision             int64            `json:"revision"`
	Category             *string          `json:"category"`
	Status               *string          `json:"status"`
	CoverFileID          *string          `json:"coverFileId"`
	PlaceName            *string          `json:"placeName"`
	PlaceCountryCode     *string          `json:"placeCountryCode"`
	PlaceCityID          *string          `json:"placeCityId"`
	Tags                 *[]string        `json:"tags"`
	Present              map[string]bool  `json:"-"`
}

func (r *UpdateStoryRequest) UnmarshalJSON(data []byte) error {
	type updateStoryRequestAlias UpdateStoryRequest
	var raw map[string]json.RawMessage
	if err := json.Unmarshal(data, &raw); err != nil {
		return err
	}

	var alias updateStoryRequestAlias
	if err := json.Unmarshal(data, &alias); err != nil {
		return err
	}
	*r = UpdateStoryRequest(alias)
	r.Present = make(map[string]bool, len(raw))
	for field := range raw {
		r.Present[field] = true
	}
	return nil
}

type CreateCommentRequest struct {
	Body string `json:"body"`
}

type UpdateCommentRequest = CreateCommentRequest

type AuthorResponse struct {
	UserID       string  `json:"userId"`
	Nickname     *string `json:"nickname,omitempty"`
	AvatarFileID *string `json:"avatarFileId,omitempty"`
	CountryCode  *string `json:"countryCode,omitempty"`
	Locale       string  `json:"locale"`
	Timezone     string  `json:"timezone"`
}

type StoryStatsResponse struct {
	Views    int `json:"views"`
	Likes    int `json:"likes"`
	Comments int `json:"comments"`
	Shares   int `json:"shares"`
}

type StoryResponse struct {
	ID                   string             `json:"id"`
	Slug                 string             `json:"slug"`
	Title                string             `json:"title"`
	Excerpt              string             `json:"excerpt"`
	Content              *string            `json:"content,omitempty"`
	Format               string             `json:"format"`
	ContentBlocks        json.RawMessage    `json:"contentBlocks,omitempty"`
	ContentSchemaVersion int                `json:"contentSchemaVersion"`
	Revision             int64              `json:"revision"`
	Category             string             `json:"category"`
	Status               string             `json:"status"`
	ModerationStatus     string             `json:"moderationStatus"`
	CoverFileID          *string            `json:"coverFileId,omitempty"`
	PlaceName            *string            `json:"placeName,omitempty"`
	PlaceCountryCode     *string            `json:"placeCountryCode,omitempty"`
	PlaceCityID          *string            `json:"placeCityId,omitempty"`
	Tags                 []string           `json:"tags,omitempty"`
	Stats                StoryStatsResponse `json:"stats"`
	Author               AuthorResponse     `json:"author"`
	LikedByViewer        bool               `json:"likedByViewer"`
	ShareURL             string             `json:"shareUrl"`
	PublishedAt          *string            `json:"publishedAt,omitempty"`
	LastAutosavedAt      *string            `json:"lastAutosavedAt,omitempty"`
	ArchivedAt           *string            `json:"archivedAt,omitempty"`
	CreatedAt            string             `json:"createdAt"`
	UpdatedAt            string             `json:"updatedAt"`
}

type StoryCommentResponse struct {
	ID        string         `json:"id"`
	StoryID   string         `json:"storyId"`
	Body      string         `json:"body"`
	Editable  bool           `json:"editable"`
	Deletable bool           `json:"deletable"`
	Edited    bool           `json:"edited"`
	Likes     int            `json:"likes"`
	LikedByMe bool           `json:"likedByMe"`
	ShareURL  string         `json:"shareUrl"`
	Author    AuthorResponse `json:"author"`
	CreatedAt string         `json:"createdAt"`
	UpdatedAt string         `json:"updatedAt"`
}

type StoryListResponse struct {
	Items   []*StoryResponse `json:"items"`
	Total   int              `json:"total"`
	Limit   int              `json:"limit"`
	Offset  int              `json:"offset"`
	HasMore bool             `json:"hasMore"`
}

type PublishedStoryCountResponse struct {
	UserID           string `json:"userId"`
	PublishedStories int    `json:"publishedStories"`
}

type StoryDetailResponse struct {
	Story    *StoryResponse          `json:"story"`
	Related  []*StoryResponse        `json:"related"`
	Comments []*StoryCommentResponse `json:"comments"`
}

type ViewResponse struct {
	Views int `json:"views"`
}

type LikeResponse struct {
	Likes int `json:"likes"`
}

type CommentLikeResponse struct {
	Likes     int  `json:"likes"`
	LikedByMe bool `json:"likedByMe"`
}

type ShareResponse struct {
	ShareURL string `json:"shareUrl"`
	Shares   int    `json:"shares"`
}
