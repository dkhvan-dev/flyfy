package model

import (
	"time"

	"github.com/google/uuid"
)

const (
	FeedBlockTypeStoriesTray          = "stories_tray"
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
	FeedEventTypeHide          = "hide"
	FeedEventTypeNotInterested = "not_interested"
)

const (
	FeedInterestEntityTypePost       = "post"
	FeedInterestEntityTypeCommunity  = "community"
	FeedInterestEntityTypeActivity   = "activity"
	FeedInterestEntityTypeAttraction = "attraction"
	FeedInterestEntityTypeTour       = "tour"
	FeedInterestEntityTypeGuide      = "guide"
	FeedInterestEntityTypeProfile    = "profile"
	FeedInterestEntityTypeCity       = "city"
	FeedInterestEntityTypeCountry    = "country"
	FeedInterestEntityTypeCategory   = "category"
	FeedInterestEntityTypeTag        = "tag"
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
	BlockType          string
	Action             string
	EventCount         int64
	UniqueViewers      int64
	ConversionCount    int64
	HideCount          int64
	NotInterestedCount int64
}
