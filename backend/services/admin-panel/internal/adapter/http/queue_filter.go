package http

import (
	"net/http"
	"net/url"
	"strings"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

const (
	excursionQueueStatusActive = "active"
	excursionQueueStatusAll    = "all"
)

var activeModerationCaseStatuses = []enum.ModerationCaseStatus{
	enum.ModerationCaseStatusOpen,
	enum.ModerationCaseStatusInReview,
	enum.ModerationCaseStatusEscalated,
}

var allModerationCaseStatuses = []enum.ModerationCaseStatus{
	enum.ModerationCaseStatusOpen,
	enum.ModerationCaseStatusInReview,
	enum.ModerationCaseStatusEscalated,
	enum.ModerationCaseStatusApproved,
	enum.ModerationCaseStatusRejected,
	enum.ModerationCaseStatusRevoked,
	enum.ModerationCaseStatusChangesRequested,
	enum.ModerationCaseStatusCancelled,
}

func parseExcursionQueueFilter(r *http.Request) (model.ModerationQueueFilter, QueueFilterViewData) {
	query := r.URL.Query()
	status := normalizeExcursionQueueStatus(query.Get("status"))
	risk := normalizeExcursionQueueRisk(query.Get("risk"))
	sort := normalizeExcursionQueueSort(query.Get("sort"))
	view := QueueFilterViewData{
		Status: status,
		City:   strings.TrimSpace(query.Get("city")),
		Search: strings.TrimSpace(query.Get("q")),
		Signal: strings.TrimSpace(query.Get("signal")),
		Risk:   string(risk),
		Sort:   string(sort),
	}
	view.Query = excursionQueueFilterQuery(view)
	return model.ModerationQueueFilter{
		Statuses: statusesForExcursionQueueStatus(status),
		Search:   view.Search,
		City:     view.City,
		Signal:   view.Signal,
		Risk:     risk,
		Sort:     sort,
	}, view
}

func parseExcursionHistoryFilter(r *http.Request) (model.ModerationQueueFilter, QueueFilterViewData) {
	filter, view := parseExcursionQueueFilter(r)
	if strings.TrimSpace(r.URL.Query().Get("status")) == "" {
		view.Status = excursionQueueStatusAll
		filter.Statuses = statusesForExcursionQueueStatus(view.Status)
	}
	if strings.TrimSpace(r.URL.Query().Get("sort")) == "" {
		view.Sort = string(model.ModerationQueueSortOpenedDesc)
		filter.Sort = model.ModerationQueueSortOpenedDesc
	}
	view.Query = excursionQueueFilterQuery(view)
	return filter, view
}

func normalizeExcursionQueueStatus(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case excursionQueueStatusAll:
		return excursionQueueStatusAll
	case "open":
		return "open"
	case "in_review":
		return "in_review"
	case "escalated":
		return "escalated"
	case "approved":
		return "approved"
	case "rejected":
		return "rejected"
	case "revoked":
		return "revoked"
	case "changes_requested":
		return "changes_requested"
	case "cancelled":
		return "cancelled"
	default:
		return excursionQueueStatusActive
	}
}

func statusesForExcursionQueueStatus(status string) []enum.ModerationCaseStatus {
	switch status {
	case excursionQueueStatusAll:
		return allModerationCaseStatuses
	case "open":
		return []enum.ModerationCaseStatus{enum.ModerationCaseStatusOpen}
	case "in_review":
		return []enum.ModerationCaseStatus{enum.ModerationCaseStatusInReview}
	case "escalated":
		return []enum.ModerationCaseStatus{enum.ModerationCaseStatusEscalated}
	case "approved":
		return []enum.ModerationCaseStatus{enum.ModerationCaseStatusApproved}
	case "rejected":
		return []enum.ModerationCaseStatus{enum.ModerationCaseStatusRejected}
	case "revoked":
		return []enum.ModerationCaseStatus{enum.ModerationCaseStatusRevoked}
	case "changes_requested":
		return []enum.ModerationCaseStatus{enum.ModerationCaseStatusChangesRequested}
	case "cancelled":
		return []enum.ModerationCaseStatus{enum.ModerationCaseStatusCancelled}
	default:
		return activeModerationCaseStatuses
	}
}

func normalizeExcursionQueueRisk(value string) model.ModerationRiskFilter {
	switch model.ModerationRiskFilter(strings.ToLower(strings.TrimSpace(value))) {
	case model.ModerationRiskFilterFlagged:
		return model.ModerationRiskFilterFlagged
	case model.ModerationRiskFilterHigh:
		return model.ModerationRiskFilterHigh
	default:
		return model.ModerationRiskFilterAll
	}
}

func normalizeExcursionQueueSort(value string) model.ModerationQueueSort {
	switch model.ModerationQueueSort(strings.ToLower(strings.TrimSpace(value))) {
	case model.ModerationQueueSortPriorityDesc:
		return model.ModerationQueueSortPriorityDesc
	case model.ModerationQueueSortOpenedDesc:
		return model.ModerationQueueSortOpenedDesc
	case model.ModerationQueueSortOpenedAsc:
		return model.ModerationQueueSortOpenedAsc
	case model.ModerationQueueSortRiskDesc:
		return model.ModerationQueueSortRiskDesc
	case model.ModerationQueueSortSubmittedDesc:
		return model.ModerationQueueSortSubmittedDesc
	default:
		return model.ModerationQueueSortDefault
	}
}

func excursionQueueFilterQuery(filter QueueFilterViewData) string {
	values := url.Values{}
	if filter.Status != "" && filter.Status != excursionQueueStatusActive {
		values.Set("status", filter.Status)
	}
	if filter.City != "" {
		values.Set("city", filter.City)
	}
	if filter.Search != "" {
		values.Set("q", filter.Search)
	}
	if filter.Signal != "" {
		values.Set("signal", filter.Signal)
	}
	if filter.Risk != "" {
		values.Set("risk", filter.Risk)
	}
	if filter.Sort != "" {
		values.Set("sort", filter.Sort)
	}
	return values.Encode()
}
