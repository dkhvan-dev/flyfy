package app

import (
	"context"
	"strings"
	"time"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

const (
	defaultFeedQualityWindow = 7 * 24 * time.Hour
	defaultFeedQualityLimit  = 50
	maxFeedQualityLimit      = 200
)

type FeedQualityDashboardInput struct {
	Since   time.Time
	Until   time.Time
	Surface string
	Limit   int
}

type FeedQualityDashboardPage struct {
	Metrics []model.FeedQualityMetric
	Totals  model.FeedQualityMetric
	Since   time.Time
	Until   time.Time
	Surface string
}

func (u *ModerationUseCase) FeedQualityDashboard(
	ctx context.Context,
	actor *model.StaffUser,
	input FeedQualityDashboardInput,
) (FeedQualityDashboardPage, error) {
	if actor == nil || !actor.HasPermission(enum.PermissionModerationRead) {
		return FeedQualityDashboardPage{}, ErrPermissionDenied
	}
	if u.feedQuality == nil {
		return FeedQualityDashboardPage{}, ErrIntegrationNotReady
	}

	until := input.Until.UTC()
	if until.IsZero() {
		until = time.Now().UTC()
	}
	since := input.Since.UTC()
	if since.IsZero() {
		since = until.Add(-defaultFeedQualityWindow)
	}
	if !since.Before(until) {
		return FeedQualityDashboardPage{}, ErrInvalidInput
	}

	filter := model.FeedQualityMetricFilter{
		Since:   since,
		Until:   until,
		Surface: normalizeFeedQualitySurface(input.Surface),
		Limit:   normalizeFeedQualityLimit(input.Limit),
	}
	metrics, err := u.feedQuality.ListFeedQualityMetrics(ctx, filter)
	if err != nil {
		return FeedQualityDashboardPage{}, err
	}

	return FeedQualityDashboardPage{
		Metrics: metrics,
		Totals:  feedQualityTotals(metrics),
		Since:   since,
		Until:   until,
		Surface: filter.Surface,
	}, nil
}

func normalizeFeedQualityLimit(limit int) int {
	if limit <= 0 {
		return defaultFeedQualityLimit
	}
	if limit > maxFeedQualityLimit {
		return maxFeedQualityLimit
	}
	return limit
}

func normalizeFeedQualitySurface(surface string) string {
	switch strings.ToLower(strings.TrimSpace(surface)) {
	case "home", "content":
		return strings.ToLower(strings.TrimSpace(surface))
	default:
		return ""
	}
}

func feedQualityTotals(metrics []model.FeedQualityMetric) model.FeedQualityMetric {
	var totals model.FeedQualityMetric
	for _, metric := range metrics {
		totals.EventCount += metric.EventCount
		totals.UniqueViewers += metric.UniqueViewers
		totals.ConversionCount += metric.ConversionCount
		totals.HideCount += metric.HideCount
		totals.NotInterestedCount += metric.NotInterestedCount
	}
	return totals
}
