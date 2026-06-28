package http

import (
	"fmt"
	"time"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type HelpAnalyticsDashboardViewData struct {
	GeneratedAt           time.Time
	Metrics               []HelpAnalyticsMetricView
	TopNoResultQueries    []HelpAnalyticsQueryView
	RepeatedQueries       []HelpAnalyticsQueryView
	TopNotHelpfulArticles []HelpAnalyticsArticleView
}

type HelpAnalyticsMetricView struct {
	LabelKey string
	Value    string
}

type HelpAnalyticsQueryView struct {
	Query string
	Count int
}

type HelpAnalyticsArticleView struct {
	ArticleID   string
	Count       int
	Escalations int
}

func NewHelpAnalyticsDashboardViewData(summary model.HelpAnalyticsSummary) HelpAnalyticsDashboardViewData {
	return HelpAnalyticsDashboardViewData{
		GeneratedAt: summary.GeneratedAt,
		Metrics: []HelpAnalyticsMetricView{
			{LabelKey: "help.analytics.metric.searchSuccess", Value: formatAnalyticsPercent(summary.Searches.SuccessRate)},
			{LabelKey: "help.analytics.metric.noResultSearches", Value: fmt.Sprintf("%d", summary.Searches.WithoutResults)},
			{LabelKey: "help.analytics.metric.notHelpful", Value: fmt.Sprintf("%d", summary.Feedback.NotHelpful)},
			{LabelKey: "help.analytics.metric.escalations", Value: fmt.Sprintf("%d", summary.Feedback.Escalations)},
			{LabelKey: "help.analytics.metric.openTickets", Value: fmt.Sprintf("%d", summary.Tickets.Open)},
			{LabelKey: "help.analytics.metric.waitingSupport", Value: fmt.Sprintf("%d", summary.Tickets.WaitingSupport)},
			{LabelKey: "help.analytics.metric.firstResponse", Value: formatAnalyticsDuration(summary.Tickets.AverageFirstResponseSeconds)},
			{LabelKey: "help.analytics.metric.resolution", Value: formatAnalyticsDuration(summary.Tickets.AverageResolutionSeconds)},
			{LabelKey: "help.analytics.metric.csat", Value: formatAnalyticsRating(summary.Tickets.AverageCSAT)},
			{LabelKey: "help.analytics.metric.csatResponses", Value: fmt.Sprintf("%d", summary.Tickets.CSATResponses)},
		},
		TopNoResultQueries:    helpAnalyticsQueries(summary.Searches.TopNoResultQueries),
		RepeatedQueries:       helpAnalyticsQueries(summary.Searches.RepeatedQueries),
		TopNotHelpfulArticles: helpAnalyticsArticles(summary.Feedback.TopNotHelpfulArticles),
	}
}

func helpAnalyticsQueries(items []model.HelpSearchQueryStat) []HelpAnalyticsQueryView {
	out := make([]HelpAnalyticsQueryView, 0, len(items))
	for _, item := range items {
		out = append(out, HelpAnalyticsQueryView{Query: item.Query, Count: item.Count})
	}
	return out
}

func helpAnalyticsArticles(items []model.HelpArticleFeedbackStat) []HelpAnalyticsArticleView {
	out := make([]HelpAnalyticsArticleView, 0, len(items))
	for _, item := range items {
		out = append(out, HelpAnalyticsArticleView{
			ArticleID:   item.ArticleID,
			Count:       item.Count,
			Escalations: item.Escalations,
		})
	}
	return out
}

func formatAnalyticsPercent(value float64) string {
	return fmt.Sprintf("%.0f%%", value*100)
}

func formatAnalyticsDuration(seconds int64) string {
	if seconds <= 0 {
		return "-"
	}
	duration := time.Duration(seconds) * time.Second
	hours := int(duration / time.Hour)
	duration -= time.Duration(hours) * time.Hour
	minutes := int(duration / time.Minute)
	if hours > 0 && minutes > 0 {
		return fmt.Sprintf("%dh %dm", hours, minutes)
	}
	if hours > 0 {
		return fmt.Sprintf("%dh", hours)
	}
	if minutes > 0 {
		return fmt.Sprintf("%dm", minutes)
	}
	return fmt.Sprintf("%ds", seconds)
}

func formatAnalyticsRating(value float64) string {
	if value <= 0 {
		return "-"
	}
	return fmt.Sprintf("%.1f", value)
}
