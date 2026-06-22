package http

import (
	"net/http"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func (s *Server) UserRouteQueue(w http.ResponseWriter, r *http.Request) {
	filter, viewFilter := parseUserRouteQueueFilter(r)
	data := NewUserRouteQueueViewData(nil, viewFilter, staffFromContext(r.Context()))
	if s.userRoutes == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "user_routes/index", "userRoute.title", "user_routes", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	items, err := s.userRoutes.ListRoutes(r.Context(), staffFromContext(r.Context()), filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "user_routes/index", "userRoute.title", "user_routes", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "user_routes/index", "userRoute.title", "user_routes", NewUserRouteQueueViewData(items, viewFilter, staffFromContext(r.Context())), "")
}

func (s *Server) ApproveUserRoute(w http.ResponseWriter, r *http.Request) {
	s.reviewUserRoute(w, r, model.UserRouteReviewApprove)
}

func (s *Server) RejectUserRoute(w http.ResponseWriter, r *http.Request) {
	s.reviewUserRoute(w, r, model.UserRouteReviewReject)
}

func (s *Server) HideUserRoute(w http.ResponseWriter, r *http.Request) {
	s.reviewUserRoute(w, r, model.UserRouteReviewHide)
}

func (s *Server) reviewUserRoute(w http.ResponseWriter, r *http.Request, decision model.UserRouteReviewDecision) {
	returnQuery := strings.TrimSpace(r.URL.RawQuery)
	if err := r.ParseForm(); err != nil {
		s.renderUserRouteQueueError(w, r, returnQuery, app.ErrInvalidInput)
		return
	}
	routeID, err := userRouteIDFromRequest(r, decision)
	if err != nil {
		s.renderUserRouteQueueError(w, r, returnQuery, app.ErrInvalidInput)
		return
	}
	if s.userRoutes == nil {
		s.renderUserRouteQueueError(w, r, returnQuery, app.ErrIntegrationNotReady)
		return
	}
	_, err = s.userRoutes.ReviewRoute(r.Context(), staffFromContext(r.Context()), model.AdminUserRouteReviewInput{
		RouteID:  routeID,
		Decision: decision,
		Reason:   r.Form.Get("reason"),
	}, requestMetadata(r))
	if err != nil {
		s.renderUserRouteQueueError(w, r, returnQuery, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(userRouteQueueURL(returnQuery), "userRoutes.reviewed"), http.StatusSeeOther)
}

func (s *Server) renderUserRouteQueueError(w http.ResponseWriter, r *http.Request, returnQuery string, err error) {
	filter, viewFilter := parseUserRouteQueueFilter(r)
	viewFilter.Query = strings.TrimSpace(returnQuery)
	items := []model.AdminUserRoute{}
	if s.userRoutes != nil {
		if listed, listErr := s.userRoutes.ListRoutes(r.Context(), staffFromContext(r.Context()), filter); listErr == nil {
			items = listed
		}
	}
	s.renderPage(w, errorStatus(err), r, "user_routes/index", "userRoute.title", "user_routes", NewUserRouteQueueViewData(items, viewFilter, staffFromContext(r.Context())), publicError(localeFromContext(r.Context()), err))
}

func parseUserRouteQueueFilter(r *http.Request) (model.AdminUserRouteListFilter, UserRouteFilterViewData) {
	query := r.URL.Query()
	status := strings.ToLower(strings.TrimSpace(query.Get("status")))
	if status == "" {
		status = string(model.UserRouteModerationPending)
	}
	ownerUserID := strings.TrimSpace(query.Get("ownerUserId"))
	cityCode := strings.ToLower(strings.TrimSpace(query.Get("cityCode")))

	filterStatus := model.NormalizeUserRouteModerationStatus(status)
	if status == "all" {
		filterStatus = ""
	} else if !filterStatus.IsValid() {
		status = string(model.UserRouteModerationPending)
		filterStatus = model.UserRouteModerationPending
	}

	return model.AdminUserRouteListFilter{
			ModerationStatus: filterStatus,
			OwnerUserID:      ownerUserID,
			CityCode:         cityCode,
			Limit:            100,
			Offset:           0,
		}, UserRouteFilterViewData{
			Status:      status,
			OwnerUserID: ownerUserID,
			CityCode:    cityCode,
			Query:       userRouteFilterQuery(status, ownerUserID, cityCode),
		}
}

func userRouteIDFromRequest(r *http.Request, decision model.UserRouteReviewDecision) (uuid.UUID, error) {
	rawID := strings.TrimSpace(r.PathValue("routeID"))
	if rawID == "" {
		rawID = userRouteIDFromActionPath(r.URL.Path, string(decision))
	}
	return uuid.Parse(rawID)
}

func userRouteIDFromActionPath(path string, action string) string {
	path = strings.Trim(strings.TrimSpace(path), "/")
	parts := strings.Split(path, "/")
	if len(parts) < 5 {
		return ""
	}
	if parts[len(parts)-1] != strings.TrimSpace(action) {
		return ""
	}
	return parts[len(parts)-2]
}
