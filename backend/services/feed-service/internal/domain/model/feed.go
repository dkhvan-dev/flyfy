package model

import (
	"time"

	"github.com/google/uuid"
)

const (
	FeedBlockTypeStoriesTray          = "stories_tray"
	FeedBlockTypeCommunityCard        = "community_card"
	FeedBlockTypeSuggestedCommunities = "suggested_communities"
	FeedBlockTypeMySubscriptions      = "my_subscriptions"
	FeedBlockTypePostCard             = "post_card"
	FeedBlockTypeActivityCard         = "activity_card"
	FeedBlockTypeAttractionCard       = "attraction_card"
	FeedBlockTypeTourCard             = "tour_card"
	FeedBlockTypeGuideCard            = "guide_card"
	FeedBlockTypeProfileCard          = "profile_card"
	FeedBlockTypeOfficialNewsCard     = "official_news_card"
)

const (
	FeedEventTypeImpression    = "impression"
	FeedEventTypeClick         = "click"
	FeedEventTypeDwell         = "dwell"
	FeedEventTypeLike          = "like"
	FeedEventTypeComment       = "comment"
	FeedEventTypeShare         = "share"
	FeedEventTypeSubscribe     = "subscribe"
	FeedEventTypeHide          = "hide"
	FeedEventTypeNotInterested = "not_interested"
	FeedEventTypeReport        = "report"
)

const (
	FeedInterestEntityTypePost        = "post"
	FeedInterestEntityTypePostProfile = "post_profile"
	FeedInterestEntityTypeCommunity   = "community"
	FeedInterestEntityTypeActivity    = "activity"
	FeedInterestEntityTypeAttraction  = "attraction"
	FeedInterestEntityTypeTour        = "tour"
	FeedInterestEntityTypeGuide       = "guide"
	FeedInterestEntityTypeProfile     = "profile"
	FeedInterestEntityTypeCity        = "city"
	FeedInterestEntityTypeCountry     = "country"
	FeedInterestEntityTypeCategory    = "category"
	FeedInterestEntityTypeTag         = "tag"
)

const (
	FeedSocialEdgeTypeFriend    = "friend"
	FeedSocialEdgeTypeFollowing = "following"
)

const (
	PostCandidateSourceGlobal    = "global"
	PostCandidateSourceFollowing = "following"
	PostCandidateSourceFollowed  = "followed"
	PostCandidateSourceSocial    = "social"
	PostCandidateSourceSystem    = "system"
	PostCandidateSourceGeo       = "geo"
	PostCandidateSourceInterest  = "interest"
	PostCandidateSourceColdStart = "cold_start"
	PostCandidateSourcePopular   = "popular"
)

type FeedEvent struct {
	ID           uuid.UUID
	EventID      uuid.UUID
	ViewerUserID *uuid.UUID
	EventType    string
	Surface      string
	Tab          string
	BlockID      string
	BlockType    string
	PostID       *uuid.UUID
	CommunityID  *uuid.UUID
	Rank         int
	OccurredAt   time.Time
	ReceivedAt   time.Time
	RequestID    string
	Metadata     map[string]any
}

type FeedUserInterest struct {
	ViewerUserID       uuid.UUID
	EntityType         string
	EntityID           string
	RepresentativeID   string
	Score              float64
	ImpressionCount    int64
	ClickCount         int64
	ConversionCount    int64
	HideCount          int64
	NotInterestedCount int64
	LastEventAt        time.Time
	UpdatedAt          time.Time
	Metadata           map[string]any
}

type FeedUserInterestListFilter struct {
	ViewerUserID uuid.UUID
	EntityTypes  []string
	Limit        int
}

type FeedQualityMetricsFilter struct {
	Since   time.Time
	Until   time.Time
	Surface string
	Limit   int
}

type FeedQualityMetric struct {
	Surface            string
	Tab                string
	BlockType          string
	RankingExperiment  string
	CandidateSource    string
	PostProfile        string
	CommunityID        string
	Action             string
	EventCount         int64
	UniqueViewers      int64
	ImpressionCount    int64
	ClickCount         int64
	DwellCount         int64
	AvgDwellMs         int64
	LikeCount          int64
	CommentCount       int64
	ShareCount         int64
	SubscribeCount     int64
	ConversionCount    int64
	HideCount          int64
	NotInterestedCount int64
	ReportCount        int64
}

type FeedSocialEdge struct {
	ViewerUserID    uuid.UUID
	TargetUserID    uuid.UUID
	EdgeType        string
	SourceEventID   *uuid.UUID
	SourceUpdatedAt time.Time
}

type FeedSocialEdgeSet struct {
	Friend    bool
	Following bool
}
