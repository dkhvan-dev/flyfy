package model

import "time"

type FeedQualityMetricFilter struct {
	Since   time.Time
	Until   time.Time
	Surface string
	Limit   int
}

type FeedQualityMetric struct {
	Surface            string
	Tab                string
	BlockType          string
	Action             string
	RankingExperiment  string
	CandidateSource    string
	PostProfile        string
	CommunityID        string
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

func (m FeedQualityMetric) NegativeFeedbackCount() int64 {
	return m.HideCount + m.NotInterestedCount + m.ReportCount
}

func (m FeedQualityMetric) EngagementCount() int64 {
	return m.LikeCount + m.CommentCount + m.ShareCount + m.SubscribeCount
}
