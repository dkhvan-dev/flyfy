package dto

type FeedResponse struct {
	Items      []*FeedBlockResponse    `json:"items"`
	NextCursor *string                 `json:"nextCursor,omitempty"`
	Assignment *FeedAssignmentResponse `json:"assignment,omitempty"`
}

type FeedAssignmentResponse struct {
	RankingExperiment string `json:"rankingExperiment,omitempty"`
}

type FeedBlockResponse struct {
	ID   string `json:"id"`
	Type string `json:"type"`
	Data any    `json:"data"`
}

type TrackFeedEventsRequest struct {
	Events []FeedEventRequest `json:"events"`
}

type FeedEventRequest struct {
	EventID     string         `json:"eventId"`
	Type        string         `json:"type"`
	Surface     string         `json:"surface"`
	Tab         string         `json:"tab"`
	BlockID     string         `json:"blockId"`
	BlockType   string         `json:"blockType"`
	PostID      *string        `json:"postId,omitempty"`
	CommunityID *string        `json:"communityId,omitempty"`
	Rank        int            `json:"rank"`
	OccurredAt  string         `json:"occurredAt,omitempty"`
	Metadata    map[string]any `json:"metadata,omitempty"`
}

type TrackFeedEventsResponse struct {
	Accepted int `json:"accepted"`
}
