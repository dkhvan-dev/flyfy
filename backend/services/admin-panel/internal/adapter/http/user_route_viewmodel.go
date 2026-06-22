package http

import (
	"fmt"
	"net/url"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

const userRouteQueuePath = "/admin/moderation/user-routes"

type UserRouteQueueViewData struct {
	Items         []UserRouteView
	Filters       UserRouteFilterViewData
	StatusOptions []UserRouteStatusOptionView
	FilterAction  string
	ResetURL      string
	CanReview     bool
}

type UserRouteView struct {
	Item          model.AdminUserRoute
	DistanceText  string
	DurationText  string
	BadgeClass    string
	ApproveURL    string
	RejectURL     string
	HideURL       string
	PointsSummary string
}

type UserRouteFilterViewData struct {
	Status      string
	OwnerUserID string
	CityCode    string
	Query       string
}

type UserRouteStatusOptionView struct {
	Value    string
	LabelKey string
	Selected bool
}

func NewUserRouteQueueViewData(
	items []model.AdminUserRoute,
	filters UserRouteFilterViewData,
	staff *model.StaffUser,
) UserRouteQueueViewData {
	query := strings.TrimSpace(filters.Query)
	views := make([]UserRouteView, 0, len(items))
	for _, item := range items {
		views = append(views, UserRouteView{
			Item:          item,
			DistanceText:  userRouteDistanceText(item.DistanceMeters),
			DurationText:  userRouteDurationText(item.DurationSeconds),
			BadgeClass:    userRouteStatusBadgeClass(item.ModerationStatus),
			ApproveURL:    userRouteReviewURL(item.ID, "approve", query),
			RejectURL:     userRouteReviewURL(item.ID, "reject", query),
			HideURL:       userRouteReviewURL(item.ID, "hide", query),
			PointsSummary: userRoutePointsSummary(item.Points),
		})
	}
	return UserRouteQueueViewData{
		Items:         views,
		Filters:       filters,
		StatusOptions: userRouteStatusOptions(filters.Status),
		FilterAction:  userRouteQueuePath,
		ResetURL:      userRouteQueuePath,
		CanReview:     staff != nil && staff.HasPermission(enum.PermissionModerationAssign),
	}
}

func userRouteStatusOptions(selected string) []UserRouteStatusOptionView {
	selected = strings.ToLower(strings.TrimSpace(selected))
	if selected == "" {
		selected = string(model.UserRouteModerationPending)
	}
	options := []UserRouteStatusOptionView{
		{Value: string(model.UserRouteModerationPending), LabelKey: "userRoute.status.pending"},
		{Value: string(model.UserRouteModerationApproved), LabelKey: "userRoute.status.approved"},
		{Value: string(model.UserRouteModerationRejected), LabelKey: "userRoute.status.rejected"},
		{Value: string(model.UserRouteModerationHidden), LabelKey: "userRoute.status.hidden"},
		{Value: "all", LabelKey: "filter.status.all"},
	}
	for i := range options {
		options[i].Selected = options[i].Value == selected
	}
	return options
}

func userRouteDistanceText(meters float64) string {
	if meters <= 0 {
		return "-"
	}
	if meters >= 1000 {
		return fmt.Sprintf("%.1f km", meters/1000)
	}
	return fmt.Sprintf("%.0f m", meters)
}

func userRouteDurationText(seconds int) string {
	if seconds <= 0 {
		return "-"
	}
	minutes := (seconds + 59) / 60
	if minutes < 60 {
		return fmt.Sprintf("%d min", minutes)
	}
	hours := minutes / 60
	minutes = minutes % 60
	if minutes == 0 {
		return fmt.Sprintf("%d h", hours)
	}
	return fmt.Sprintf("%d h %d min", hours, minutes)
}

func userRouteStatusBadgeClass(status model.UserRouteModerationStatus) string {
	switch status {
	case model.UserRouteModerationApproved:
		return "badge badge-success"
	case model.UserRouteModerationRejected, model.UserRouteModerationHidden:
		return "badge badge-danger"
	case model.UserRouteModerationPending:
		return "badge badge-warn"
	default:
		return "badge"
	}
}

func userRouteReviewURL(id uuid.UUID, action string, query string) string {
	return queueURLWithQuery(userRouteQueuePath+"/"+id.String()+"/"+strings.TrimSpace(action), query)
}

func userRouteQueueURL(query string) string {
	return queueURLWithQuery(userRouteQueuePath, query)
}

func userRoutePointsSummary(points []model.AdminUserRoutePoint) string {
	if len(points) == 0 {
		return "-"
	}
	labels := make([]string, 0, len(points))
	for _, point := range points {
		label := strings.TrimSpace(point.Label)
		if label == "" {
			label = fmt.Sprintf("%.5f, %.5f", point.Latitude, point.Longitude)
		}
		labels = append(labels, label)
	}
	return strings.Join(labels, " -> ")
}

func userRouteFilterQuery(status string, ownerUserID string, cityCode string) string {
	values := url.Values{}
	status = strings.ToLower(strings.TrimSpace(status))
	if status == "" {
		status = string(model.UserRouteModerationPending)
	}
	values.Set("status", status)
	if ownerUserID = strings.TrimSpace(ownerUserID); ownerUserID != "" {
		values.Set("ownerUserId", ownerUserID)
	}
	if cityCode = strings.ToLower(strings.TrimSpace(cityCode)); cityCode != "" {
		values.Set("cityCode", cityCode)
	}
	return values.Encode()
}
