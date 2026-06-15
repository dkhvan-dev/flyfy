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
	BlockType          string
	Action             string
	EventCount         int64
	UniqueViewers      int64
	ConversionCount    int64
	HideCount          int64
	NotInterestedCount int64
}

func (m FeedQualityMetric) NegativeFeedbackCount() int64 {
	return m.HideCount + m.NotInterestedCount
}
