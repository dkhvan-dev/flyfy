package http

import (
	"testing"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestFeedQualityMetricViewUsesImpressionsAsQualityRateDenominator(t *testing.T) {
	t.Parallel()

	view := newFeedQualityMetricView(model.FeedQualityMetric{
		EventCount:         100,
		ImpressionCount:    20,
		ClickCount:         8,
		DwellCount:         5,
		LikeCount:          3,
		CommentCount:       2,
		ShareCount:         1,
		SubscribeCount:     4,
		ConversionCount:    4,
		HideCount:          1,
		NotInterestedCount: 2,
		ReportCount:        3,
	})

	if view.ClickRateText != "40.0%" {
		t.Fatalf("ClickRateText = %q, want 40.0%%", view.ClickRateText)
	}
	if view.DwellRateText != "25.0%" {
		t.Fatalf("DwellRateText = %q, want 25.0%%", view.DwellRateText)
	}
	if view.EngagementRateText != "50.0%" {
		t.Fatalf("EngagementRateText = %q, want 50.0%%", view.EngagementRateText)
	}
	if view.SubscribeRateText != "20.0%" {
		t.Fatalf("SubscribeRateText = %q, want 20.0%%", view.SubscribeRateText)
	}
	if view.ConversionRateText != "20.0%" {
		t.Fatalf("ConversionRateText = %q, want 20.0%%", view.ConversionRateText)
	}
	if view.NegativeRateText != "30.0%" {
		t.Fatalf("NegativeRateText = %q, want 30.0%%", view.NegativeRateText)
	}
	if view.ReportRateText != "15.0%" {
		t.Fatalf("ReportRateText = %q, want 15.0%%", view.ReportRateText)
	}
}

func TestFeedQualityExperimentSummaryViewFormatsControlDeltas(t *testing.T) {
	t.Parallel()

	view := newFeedQualityExperimentSummaryView(app.FeedQualityExperimentSummary{
		Experiment:                     "rank-v2",
		ClickRateDeltaBasisPoints:      830,
		DwellRateDeltaBasisPoints:      330,
		EngagementRateDeltaBasisPoints: -130,
		ConversionRateDeltaBasisPoints: 670,
		NegativeRateDeltaBasisPoints:   2170,
		ReportRateDeltaBasisPoints:     -50,
	})

	if view.ClickRateDeltaText != "+8.3 pp" ||
		view.DwellRateDeltaText != "+3.3 pp" ||
		view.EngagementRateDeltaText != "-1.3 pp" ||
		view.ConversionRateDeltaText != "+6.7 pp" ||
		view.NegativeRateDeltaText != "+21.7 pp" ||
		view.ReportRateDeltaText != "-0.5 pp" {
		t.Fatalf("delta texts = %+v, want signed percentage points", view)
	}

	controlView := newFeedQualityExperimentSummaryView(app.FeedQualityExperimentSummary{
		Experiment: "control",
		Baseline:   true,
	})
	if !controlView.Baseline || controlView.ClickRateDeltaText != "-" {
		t.Fatalf("control delta view = %+v, want baseline with empty deltas", controlView)
	}
}
