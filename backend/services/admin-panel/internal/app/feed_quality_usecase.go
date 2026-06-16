package app

import (
	"context"
	"sort"
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
	Metrics             []model.FeedQualityMetric
	ExperimentSummaries []FeedQualityExperimentSummary
	Totals              model.FeedQualityMetric
	Since               time.Time
	Until               time.Time
	Surface             string
}

type FeedQualityExperimentSummary struct {
	Experiment                     string
	Totals                         model.FeedQualityMetric
	Baseline                       bool
	ClickRateDeltaBasisPoints      int64
	DwellRateDeltaBasisPoints      int64
	EngagementRateDeltaBasisPoints int64
	SubscribeRateDeltaBasisPoints  int64
	ConversionRateDeltaBasisPoints int64
	NegativeRateDeltaBasisPoints   int64
	ReportRateDeltaBasisPoints     int64
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
		Metrics:             metrics,
		ExperimentSummaries: feedQualityExperimentSummaries(metrics),
		Totals:              feedQualityTotals(metrics),
		Since:               since,
		Until:               until,
		Surface:             filter.Surface,
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
		totals.ImpressionCount += metric.ImpressionCount
		totals.ClickCount += metric.ClickCount
		totals.DwellCount += metric.DwellCount
		totals.AvgDwellMs += metric.AvgDwellMs * metric.DwellCount
		totals.LikeCount += metric.LikeCount
		totals.CommentCount += metric.CommentCount
		totals.ShareCount += metric.ShareCount
		totals.SubscribeCount += metric.SubscribeCount
		totals.ConversionCount += metric.ConversionCount
		totals.HideCount += metric.HideCount
		totals.NotInterestedCount += metric.NotInterestedCount
		totals.ReportCount += metric.ReportCount
	}
	if totals.DwellCount > 0 {
		totals.AvgDwellMs = totals.AvgDwellMs / totals.DwellCount
	}
	return totals
}

func feedQualityExperimentSummaries(metrics []model.FeedQualityMetric) []FeedQualityExperimentSummary {
	grouped := make(map[string][]model.FeedQualityMetric)
	for _, metric := range metrics {
		experiment := normalizeFeedQualityExperiment(metric.RankingExperiment)
		grouped[experiment] = append(grouped[experiment], metric)
	}

	summaries := make([]FeedQualityExperimentSummary, 0, len(grouped))
	for experiment, items := range grouped {
		totals := feedQualityTotals(items)
		totals.RankingExperiment = experiment
		summaries = append(summaries, FeedQualityExperimentSummary{
			Experiment: experiment,
			Totals:     totals,
			Baseline:   experiment == "control",
		})
	}
	applyFeedQualityExperimentBaselineDeltas(summaries)
	sort.SliceStable(summaries, func(i, j int) bool {
		if summaries[i].Totals.EventCount != summaries[j].Totals.EventCount {
			return summaries[i].Totals.EventCount > summaries[j].Totals.EventCount
		}
		return summaries[i].Experiment < summaries[j].Experiment
	})
	return summaries
}

func applyFeedQualityExperimentBaselineDeltas(summaries []FeedQualityExperimentSummary) {
	controlIndex := -1
	for idx, summary := range summaries {
		if summary.Experiment == "control" {
			controlIndex = idx
			break
		}
	}
	if controlIndex < 0 {
		return
	}
	control := summaries[controlIndex].Totals
	controlClickRate := feedQualityRateBasisPoints(control.ClickCount, control)
	controlDwellRate := feedQualityRateBasisPoints(control.DwellCount, control)
	controlEngagementRate := feedQualityRateBasisPoints(control.EngagementCount(), control)
	controlSubscribeRate := feedQualityRateBasisPoints(control.SubscribeCount, control)
	controlConversionRate := feedQualityRateBasisPoints(control.ConversionCount, control)
	controlNegativeRate := feedQualityRateBasisPoints(control.NegativeFeedbackCount(), control)
	controlReportRate := feedQualityRateBasisPoints(control.ReportCount, control)

	for idx := range summaries {
		summaries[idx].Baseline = summaries[idx].Experiment == "control"
		if summaries[idx].Baseline {
			continue
		}
		totals := summaries[idx].Totals
		summaries[idx].ClickRateDeltaBasisPoints = feedQualityRateBasisPoints(totals.ClickCount, totals) - controlClickRate
		summaries[idx].DwellRateDeltaBasisPoints = feedQualityRateBasisPoints(totals.DwellCount, totals) - controlDwellRate
		summaries[idx].EngagementRateDeltaBasisPoints = feedQualityRateBasisPoints(totals.EngagementCount(), totals) - controlEngagementRate
		summaries[idx].SubscribeRateDeltaBasisPoints = feedQualityRateBasisPoints(totals.SubscribeCount, totals) - controlSubscribeRate
		summaries[idx].ConversionRateDeltaBasisPoints = feedQualityRateBasisPoints(totals.ConversionCount, totals) - controlConversionRate
		summaries[idx].NegativeRateDeltaBasisPoints = feedQualityRateBasisPoints(totals.NegativeFeedbackCount(), totals) - controlNegativeRate
		summaries[idx].ReportRateDeltaBasisPoints = feedQualityRateBasisPoints(totals.ReportCount, totals) - controlReportRate
	}
}

func feedQualityRateBasisPoints(numerator int64, metric model.FeedQualityMetric) int64 {
	basis := metric.ImpressionCount
	if basis <= 0 {
		basis = metric.EventCount
	}
	if basis <= 0 {
		return 0
	}
	return (numerator*10000 + basis/2) / basis
}

func normalizeFeedQualityExperiment(experiment string) string {
	experiment = strings.TrimSpace(experiment)
	if experiment == "" {
		return "control"
	}
	return experiment
}
