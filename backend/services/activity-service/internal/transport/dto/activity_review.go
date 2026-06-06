package dto

type SaveActivityReviewsRequest struct {
	ActivityReview  *ActivityReviewMutationRequest `json:"activityReview,omitempty"`
	OrganizerReview *ActivityReviewMutationRequest `json:"organizerReview,omitempty"`
}

type ActivityReviewMutationRequest struct {
	Rating  float64 `json:"rating"`
	Comment string  `json:"comment"`
	Delete  bool    `json:"delete,omitempty"`
}

type ActivityReviewsResponse struct {
	ActivityReview  *ActivityReviewResponse          `json:"activityReview,omitempty"`
	OrganizerReview *ActivityOrganizerReviewResponse `json:"organizerReview,omitempty"`
}

type ActivityReviewAuthorResponse struct {
	UserID       string  `json:"userId"`
	Nickname     *string `json:"nickname,omitempty"`
	AvatarFileID *string `json:"avatarFileId,omitempty"`
}

type ActivityReviewResponse struct {
	ID            string                       `json:"id"`
	ParticipantID string                       `json:"participantId"`
	ActivityID    string                       `json:"activityId"`
	HostUserID    string                       `json:"hostUserId"`
	AuthorUserID  string                       `json:"authorUserId"`
	Author        ActivityReviewAuthorResponse `json:"author"`
	Rating        float64                      `json:"rating"`
	Comment       string                       `json:"comment"`
	SourceLabel   string                       `json:"sourceLabel"`
	CreatedAt     string                       `json:"createdAt"`
	UpdatedAt     string                       `json:"updatedAt"`
}

type ActivityOrganizerReviewResponse struct {
	ID            string                       `json:"id"`
	ParticipantID string                       `json:"participantId"`
	ActivityID    string                       `json:"activityId"`
	HostUserID    string                       `json:"hostUserId"`
	AuthorUserID  string                       `json:"authorUserId"`
	Author        ActivityReviewAuthorResponse `json:"author"`
	Rating        float64                      `json:"rating"`
	Comment       string                       `json:"comment"`
	SourceLabel   string                       `json:"sourceLabel"`
	CreatedAt     string                       `json:"createdAt"`
	UpdatedAt     string                       `json:"updatedAt"`
}

type ActivityReviewListResponse struct {
	Items   []ActivityReviewResponse `json:"items"`
	HasMore bool                     `json:"hasMore"`
}

type ActivityOrganizerReviewListResponse struct {
	Items   []ActivityOrganizerReviewResponse `json:"items"`
	HasMore bool                              `json:"hasMore"`
}
