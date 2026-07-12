package dto

import "encoding/json"

type CreatePostRequest struct {
	Title                string          `json:"title"`
	Content              string          `json:"content"`
	Format               string          `json:"format"`
	ContentBlocks        json.RawMessage `json:"contentBlocks"`
	ContentSchemaVersion int             `json:"contentSchemaVersion"`
	Revision             int64           `json:"revision"`
	CommunityID          *string         `json:"communityId"`
	CommunityInstanceID  *string         `json:"communityInstanceId"`
	PostProfileKey       string          `json:"postProfileKey"`
	StructuredData       json.RawMessage `json:"structuredData"`
	Category             string          `json:"category"`
	Status               string          `json:"status"`
	CoverFileID          *string         `json:"coverFileId"`
	PlaceName            *string         `json:"placeName"`
	PlaceCountryCode     *string         `json:"placeCountryCode"`
	PlaceCityID          *string         `json:"placeCityId"`
	Tags                 []string        `json:"tags"`
	ExpiresAt            *string         `json:"expiresAt"`
}

type CreateStoryRequest struct {
	Caption     string  `json:"caption"`
	MediaFileID string  `json:"mediaFileId"`
	CoverFileID string  `json:"coverFileId"`
	MediaType   string  `json:"mediaType"`
	ExpiresAt   *string `json:"expiresAt"`
}

type PostCreateEligibilityResponse struct {
	CanCreate         bool    `json:"canCreate"`
	Limit             int     `json:"limit"`
	Remaining         int     `json:"remaining"`
	WindowSeconds     int64   `json:"windowSeconds"`
	CooldownSeconds   int64   `json:"cooldownSeconds"`
	BlockReason       string  `json:"blockReason,omitempty"`
	RetryAfterSeconds int64   `json:"retryAfterSeconds"`
	NextAvailableAt   *string `json:"nextAvailableAt,omitempty"`
}

type UpdatePostRequest struct {
	Title                *string          `json:"title"`
	Content              *string          `json:"content"`
	Format               *string          `json:"format"`
	ContentBlocks        *json.RawMessage `json:"contentBlocks"`
	ContentSchemaVersion *int             `json:"contentSchemaVersion"`
	Revision             int64            `json:"revision"`
	CommunityID          *string          `json:"communityId"`
	CommunityInstanceID  *string          `json:"communityInstanceId"`
	PostProfileKey       *string          `json:"postProfileKey"`
	StructuredData       *json.RawMessage `json:"structuredData"`
	Category             *string          `json:"category"`
	Status               *string          `json:"status"`
	CoverFileID          *string          `json:"coverFileId"`
	PlaceName            *string          `json:"placeName"`
	PlaceCountryCode     *string          `json:"placeCountryCode"`
	PlaceCityID          *string          `json:"placeCityId"`
	Tags                 *[]string        `json:"tags"`
	ExpiresAt            *string          `json:"expiresAt"`
	Present              map[string]bool  `json:"-"`
}

func (r *UpdatePostRequest) UnmarshalJSON(data []byte) error {
	type updatePostRequestAlias UpdatePostRequest
	var raw map[string]json.RawMessage
	if err := json.Unmarshal(data, &raw); err != nil {
		return err
	}

	var alias updatePostRequestAlias
	if err := json.Unmarshal(data, &alias); err != nil {
		return err
	}
	*r = UpdatePostRequest(alias)
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

type ReviewCommunityPostRequest struct {
	Reason string `json:"reason"`
}

type ReportPostRequest struct {
	Reason  string `json:"reason"`
	Details string `json:"details"`
}

type ResolvePostReportRequest struct {
	ResolutionNote string `json:"resolutionNote"`
}

type AuthorResponse struct {
	UserID           string  `json:"userId"`
	Nickname         *string `json:"nickname,omitempty"`
	AvatarFileID     *string `json:"avatarFileId,omitempty"`
	CountryCode      *string `json:"countryCode,omitempty"`
	Locale           string  `json:"locale"`
	Timezone         string  `json:"timezone"`
	IsFriendOfViewer bool    `json:"isFriendOfViewer"`
}

type PostStatsResponse struct {
	Views    int `json:"views"`
	Likes    int `json:"likes"`
	Comments int `json:"comments"`
	Shares   int `json:"shares"`
}

type PostResponse struct {
	ID                     string            `json:"id"`
	Slug                   string            `json:"slug"`
	Title                  string            `json:"title"`
	Excerpt                string            `json:"excerpt"`
	Content                *string           `json:"content,omitempty"`
	Format                 string            `json:"format"`
	ContentBlocks          json.RawMessage   `json:"contentBlocks,omitempty"`
	ContentSchemaVersion   int               `json:"contentSchemaVersion"`
	Revision               int64             `json:"revision"`
	CommunityID            *string           `json:"communityId,omitempty"`
	CommunityInstanceID    *string           `json:"communityInstanceId,omitempty"`
	PostKind               string            `json:"postKind"`
	PostProfileKey         string            `json:"postProfileKey"`
	PostProfileVersion     int               `json:"postProfileVersion"`
	StructuredData         json.RawMessage   `json:"structuredData,omitempty"`
	ModerationMode         string            `json:"moderationMode"`
	ActivityCreationStatus *string           `json:"activityCreationStatus,omitempty"`
	SourceActivityID       *string           `json:"sourceActivityId,omitempty"`
	Category               string            `json:"category"`
	Status                 string            `json:"status"`
	ModerationStatus       string            `json:"moderationStatus"`
	CoverFileID            *string           `json:"coverFileId,omitempty"`
	CoverImageURL          *string           `json:"coverImageUrl,omitempty"`
	PlaceName              *string           `json:"placeName,omitempty"`
	PlaceCountryCode       *string           `json:"placeCountryCode,omitempty"`
	PlaceCityID            *string           `json:"placeCityId,omitempty"`
	Tags                   []string          `json:"tags,omitempty"`
	Stats                  PostStatsResponse `json:"stats"`
	Author                 AuthorResponse    `json:"author"`
	LikedByViewer          bool              `json:"likedByViewer"`
	Editable               bool              `json:"editable"`
	SeenByViewer           bool              `json:"seenByViewer"`
	SeenAt                 *string           `json:"seenAt,omitempty"`
	ShareURL               string            `json:"shareUrl"`
	PublishedAt            *string           `json:"publishedAt,omitempty"`
	ExpiresAt              *string           `json:"expiresAt,omitempty"`
	LastAutosavedAt        *string           `json:"lastAutosavedAt,omitempty"`
	ArchivedAt             *string           `json:"archivedAt,omitempty"`
	CreatedAt              string            `json:"createdAt"`
	UpdatedAt              string            `json:"updatedAt"`
}

type StoryStatsResponse struct {
	Views   int `json:"views"`
	Likes   int `json:"likes"`
	Replies int `json:"replies"`
}

type StoryResponse struct {
	ID            string             `json:"id"`
	Caption       string             `json:"caption"`
	MediaFileID   string             `json:"mediaFileId"`
	MediaURL      string             `json:"mediaUrl"`
	CoverFileID   string             `json:"coverFileId"`
	CoverImageURL string             `json:"coverImageUrl"`
	MediaType     string             `json:"mediaType"`
	Stats         StoryStatsResponse `json:"stats"`
	Author        AuthorResponse     `json:"author"`
	SeenByViewer  bool               `json:"seenByViewer"`
	SeenAt        *string            `json:"seenAt,omitempty"`
	ShareURL      string             `json:"shareUrl"`
	ExpiresAt     string             `json:"expiresAt"`
	CreatedAt     string             `json:"createdAt"`
	UpdatedAt     string             `json:"updatedAt"`
}

type StoryListResponse struct {
	Items   []*StoryResponse `json:"items"`
	Limit   int              `json:"limit"`
	Offset  int              `json:"offset"`
	HasMore bool             `json:"hasMore"`
}

type PostCommentResponse struct {
	ID        string         `json:"id"`
	PostID    string         `json:"postId"`
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

type PostListResponse struct {
	Items   []*PostResponse `json:"items"`
	Total   int             `json:"total"`
	Limit   int             `json:"limit"`
	Offset  int             `json:"offset"`
	HasMore bool            `json:"hasMore"`
}

type CommunityModerationPostListResponse struct {
	Items   []*PostResponse `json:"items"`
	Limit   int             `json:"limit"`
	Offset  int             `json:"offset"`
	HasMore bool            `json:"hasMore"`
}

type PostModerationDecisionResponse struct {
	ID              string `json:"id"`
	PostID          string `json:"postId"`
	CommunityID     string `json:"communityId"`
	ModeratorUserID string `json:"moderatorUserId"`
	Decision        string `json:"decision"`
	PreviousStatus  string `json:"previousStatus"`
	NextStatus      string `json:"nextStatus"`
	PostRevision    int64  `json:"postRevision"`
	Reason          string `json:"reason"`
	CreatedAt       string `json:"createdAt"`
}

type PostModerationDecisionListResponse struct {
	Items   []*PostModerationDecisionResponse `json:"items"`
	Limit   int                               `json:"limit"`
	Offset  int                               `json:"offset"`
	HasMore bool                              `json:"hasMore"`
}

type PostReportResponse struct {
	ID               string  `json:"id"`
	PostID           string  `json:"postId"`
	CommunityID      *string `json:"communityId,omitempty"`
	ReporterUserID   string  `json:"reporterUserId"`
	AuthorUserID     string  `json:"authorUserId"`
	Reason           string  `json:"reason"`
	Details          string  `json:"details"`
	Status           string  `json:"status"`
	ResolvedByUserID *string `json:"resolvedByUserId,omitempty"`
	ResolutionNote   string  `json:"resolutionNote,omitempty"`
	CreatedAt        string  `json:"createdAt"`
	UpdatedAt        string  `json:"updatedAt"`
	ResolvedAt       *string `json:"resolvedAt,omitempty"`
}

type PostReportSubmissionResponse struct {
	Report           *PostReportResponse `json:"report"`
	Post             *PostResponse       `json:"post"`
	OpenReportsCount int                 `json:"openReportsCount"`
	AutoHidden       bool                `json:"autoHidden"`
}

type PostReportListResponse struct {
	Items   []*PostReportResponse `json:"items"`
	Limit   int                   `json:"limit"`
	Offset  int                   `json:"offset"`
	HasMore bool                  `json:"hasMore"`
}

type PublishedPostCountResponse struct {
	UserID         string `json:"userId"`
	PublishedPosts int    `json:"publishedPosts"`
}

type PostDetailResponse struct {
	Post     *PostResponse          `json:"post"`
	Related  []*PostResponse        `json:"related"`
	Comments []*PostCommentResponse `json:"comments"`
}

type ViewResponse struct {
	Views int `json:"views"`
}

type PostSeenResponse struct {
	SeenAt string `json:"seenAt"`
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
