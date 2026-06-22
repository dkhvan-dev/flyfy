package http

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"kz/inflap/backend/services/user-route-service/internal/app"
	"kz/inflap/backend/services/user-route-service/internal/domain/model"
)

type Handler struct {
	uc *app.UserRouteUseCase
}

func NewHandler(uc *app.UserRouteUseCase) *Handler {
	return &Handler{uc: uc}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /v1/admin/user-routes", h.ListAdminRoutes)
	mux.HandleFunc("POST /v1/admin/user-routes/{routeID}/review", h.ReviewRoute)
	mux.HandleFunc("GET /v1/user-routes", h.ListRoutes)
	mux.HandleFunc("POST /v1/user-routes", h.CreateRoute)
	mux.HandleFunc("GET /v1/user-routes/{routeID}", h.GetRoute)
	mux.HandleFunc("PATCH /v1/user-routes/{routeID}", h.UpdateRoute)
	mux.HandleFunc("POST /v1/user-routes/{routeID}/save", h.SaveRoute)
	mux.HandleFunc("DELETE /v1/user-routes/{routeID}/save", h.UnsaveRoute)
	mux.HandleFunc("POST /v1/user-routes/{routeID}/copy", h.CopyRoute)
	mux.HandleFunc("GET /", h.NotFound)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) NotFound(w http.ResponseWriter, _ *http.Request) {
	writeError(w, http.StatusNotFound, "user_route.route_not_found", "business", "Route not found")
}

type createRouteRequest struct {
	Title       string                 `json:"title"`
	Description string                 `json:"description"`
	Visibility  model.RouteVisibility  `json:"visibility"`
	Profile     model.RouteProfile     `json:"profile"`
	CityCode    string                 `json:"cityCode"`
	Tags        []string               `json:"tags"`
	Points      []model.UserRoutePoint `json:"points"`
	Snapshot    model.RouteSnapshot    `json:"snapshot"`
}

type updateRouteRequest struct {
	Title       *string                 `json:"title"`
	Description *string                 `json:"description"`
	Visibility  *model.RouteVisibility  `json:"visibility"`
	Profile     *model.RouteProfile     `json:"profile"`
	CityCode    *string                 `json:"cityCode"`
	Tags        *[]string               `json:"tags"`
	Points      *[]model.UserRoutePoint `json:"points"`
	Snapshot    *model.RouteSnapshot    `json:"snapshot"`
}

type routeListResponse struct {
	Items []model.UserRoute `json:"items"`
}

type reviewRouteRequest struct {
	Decision string `json:"decision"`
	Reason   string `json:"reason"`
}

func (h *Handler) CreateRoute(w http.ResponseWriter, r *http.Request) {
	actorUserID := trustedUserID(r)
	if actorUserID == "" {
		writeAppError(w, app.ErrUserRouteAuthRequired)
		return
	}
	var req createRouteRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "user_route.invalid_json", "business", "Invalid JSON body")
		return
	}
	route, err := h.uc.CreateRoute(r.Context(), app.CreateRouteInput{
		ActorUserID: actorUserID,
		Title:       req.Title,
		Description: req.Description,
		Visibility:  req.Visibility,
		Profile:     req.Profile,
		CityCode:    req.CityCode,
		Tags:        req.Tags,
		Points:      req.Points,
		Snapshot:    req.Snapshot,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, route)
}

func (h *Handler) UpdateRoute(w http.ResponseWriter, r *http.Request) {
	actorUserID := trustedUserID(r)
	if actorUserID == "" {
		writeAppError(w, app.ErrUserRouteAuthRequired)
		return
	}
	var req updateRouteRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "user_route.invalid_json", "business", "Invalid JSON body")
		return
	}
	route, err := h.uc.UpdateRoute(r.Context(), app.UpdateRouteInput{
		ActorUserID: actorUserID,
		RouteID:     r.PathValue("routeID"),
		Title:       req.Title,
		Description: req.Description,
		Visibility:  req.Visibility,
		Profile:     req.Profile,
		CityCode:    req.CityCode,
		Tags:        req.Tags,
		Points:      req.Points,
		Snapshot:    req.Snapshot,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, route)
}

func (h *Handler) ListRoutes(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	actorUserID := trustedUserID(r)
	scope := strings.ToLower(strings.TrimSpace(query.Get("scope")))
	visibility := strings.ToLower(strings.TrimSpace(query.Get("visibility")))
	limit, _ := strconv.Atoi(query.Get("limit"))
	offset, _ := strconv.Atoi(query.Get("offset"))

	input := app.ListRoutesInput{
		ActorUserID: actorUserID,
		PublicOnly:  visibility == "public" || actorUserID == "",
		CityCode:    query.Get("cityCode"),
		Limit:       limit,
		Offset:      offset,
	}
	switch scope {
	case "my":
		if actorUserID == "" {
			writeAppError(w, app.ErrUserRouteAuthRequired)
			return
		}
		input.OwnerUserID = actorUserID
		input.PublicOnly = false
	case "saved":
		if actorUserID == "" {
			writeAppError(w, app.ErrUserRouteAuthRequired)
			return
		}
		input.SavedByUserID = actorUserID
		input.PublicOnly = false
	default:
		input.PublicOnly = true
	}

	routes, err := h.uc.ListRoutes(r.Context(), input)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, routeListResponse{Items: routes})
}

func (h *Handler) ListAdminRoutes(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := requireAdminRouteModerator(w, r)
	if !ok {
		return
	}
	query := r.URL.Query()
	limit, _ := strconv.Atoi(query.Get("limit"))
	offset, _ := strconv.Atoi(query.Get("offset"))
	routes, err := h.uc.ListAdminRoutes(r.Context(), app.ListAdminRoutesInput{
		ActorUserID:      actorUserID,
		OwnerUserID:      query.Get("ownerUserId"),
		CityCode:         query.Get("cityCode"),
		ModerationStatus: model.RouteModerationStatus(strings.TrimSpace(query.Get("status"))),
		Limit:            limit,
		Offset:           offset,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, routeListResponse{Items: routes})
}

func (h *Handler) ReviewRoute(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := requireAdminRouteModerator(w, r)
	if !ok {
		return
	}
	var req reviewRouteRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "user_route.invalid_json", "business", "Invalid JSON body")
		return
	}
	route, err := h.uc.ReviewRoute(r.Context(), app.ReviewRouteInput{
		ActorUserID: actorUserID,
		RouteID:     r.PathValue("routeID"),
		Decision:    req.Decision,
		Reason:      req.Reason,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, route)
}

func (h *Handler) GetRoute(w http.ResponseWriter, r *http.Request) {
	route, err := h.uc.GetRoute(r.Context(), app.GetRouteInput{
		ActorUserID: trustedUserID(r),
		RouteID:     r.PathValue("routeID"),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, route)
}

func (h *Handler) SaveRoute(w http.ResponseWriter, r *http.Request) {
	route, err := h.uc.SaveRoute(r.Context(), app.SaveRouteInput{
		ActorUserID: trustedUserID(r),
		RouteID:     r.PathValue("routeID"),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, route)
}

func (h *Handler) UnsaveRoute(w http.ResponseWriter, r *http.Request) {
	route, err := h.uc.UnsaveRoute(r.Context(), app.SaveRouteInput{
		ActorUserID: trustedUserID(r),
		RouteID:     r.PathValue("routeID"),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, route)
}

func (h *Handler) CopyRoute(w http.ResponseWriter, r *http.Request) {
	route, err := h.uc.CopyRoute(r.Context(), app.CopyRouteInput{
		ActorUserID: trustedUserID(r),
		RouteID:     r.PathValue("routeID"),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, route)
}

func decodeBody(r *http.Request, dst any) error {
	decoder := json.NewDecoder(http.MaxBytesReader(nil, r.Body, 1<<20))
	decoder.DisallowUnknownFields()
	return decoder.Decode(dst)
}

func trustedUserID(r *http.Request) string {
	return strings.TrimSpace(r.Header.Get("X-User-Id"))
}

func requireAdminRouteModerator(w http.ResponseWriter, r *http.Request) (string, bool) {
	actorUserID := trustedUserID(r)
	if actorUserID == "" {
		writeAppError(w, app.ErrUserRouteAuthRequired)
		return "", false
	}
	if !hasAdminRouteModeratorRole(r.Header.Get("X-User-Roles")) {
		writeAppError(w, app.ErrUserRouteForbidden)
		return "", false
	}
	return actorUserID, true
}

func hasAdminRouteModeratorRole(rawRoles string) bool {
	for _, role := range strings.Split(rawRoles, ",") {
		switch strings.ToUpper(strings.TrimSpace(role)) {
		case "ADMIN", "MODERATOR":
			return true
		}
	}
	return false
}
