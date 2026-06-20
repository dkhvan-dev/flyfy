package http

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"kz/inflap/backend/services/switches-service/internal/featureflag/app"
)

type Handler struct {
	features             *app.FeatureFlagService
	domains              *app.DomainService
	internalServiceToken string
	readiness            func(context.Context) error
}

func NewHandler(features *app.FeatureFlagService, domains *app.DomainService, internalServiceToken string, readiness func(context.Context) error) *Handler {
	return &Handler{
		features:             features,
		domains:              domains,
		internalServiceToken: strings.TrimSpace(internalServiceToken),
		readiness:            readiness,
	}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Ready)
	mux.HandleFunc("GET /live", h.Live)
	mux.HandleFunc("GET /ready", h.Ready)
	mux.Handle("POST /api/v1/feature-flags", h.requireOperationsAccess(http.HandlerFunc(h.CreateFeatureFlag)))
	mux.Handle("GET /api/v1/feature-flags", h.requireOperationsAccess(http.HandlerFunc(h.SearchFeatureFlags)))
	mux.Handle("PUT /api/v1/feature-flags/{code}", h.requireOperationsAccess(http.HandlerFunc(h.UpdateFeatureFlag)))
	mux.Handle("GET /api/v1/feature-flags/{code}", h.requireOperationsAccess(http.HandlerFunc(h.GetFeatureFlag)))
	mux.Handle("DELETE /api/v1/feature-flags/{code}", h.requireOperationsAccess(http.HandlerFunc(h.DeleteFeatureFlag)))
	mux.Handle("PATCH /api/v1/feature-flags/{code}/recover", h.requireOperationsAccess(http.HandlerFunc(h.RecoverFeatureFlag)))
	mux.Handle("GET /api/v1/feature-flags/history", h.requireOperationsAccess(http.HandlerFunc(h.SearchFeatureFlagHistory)))
	mux.HandleFunc("GET /api/v1/internal/feature-flags/{code}", h.GetInternalFeatureFlag)
	mux.Handle("POST /api/v1/dict/teams", h.requireOperationsAccess(http.HandlerFunc(h.CreateDomain)))
	mux.Handle("GET /api/v1/dict/teams", h.requireOperationsAccess(http.HandlerFunc(h.SearchDomains)))
	mux.Handle("PUT /api/v1/dict/teams/{teamId}", h.requireOperationsAccess(http.HandlerFunc(h.UpdateDomain)))
	mux.Handle("GET /api/v1/dict/teams/{teamId}", h.requireOperationsAccess(http.HandlerFunc(h.GetDomain)))
}

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	h.Ready(w, r)
}

func (h *Handler) Live(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) Ready(w http.ResponseWriter, r *http.Request) {
	if h.readiness != nil {
		if err := h.readiness(r.Context()); err != nil {
			writeJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "unavailable"})
			return
		}
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) requireOperationsAccess(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !h.isTrustedInternalRequest(r) {
			writeError(w, http.StatusUnauthorized, "missing internal service token")
			return
		}
		requireOperationsRole(next).ServeHTTP(w, r)
	})
}

type featureFlagCreateRequest struct {
	DomainCode      string              `json:"domainCode"`
	Code            string              `json:"code"`
	Name            string              `json:"name"`
	Group           string              `json:"group"`
	Type            app.FeatureFlagType `json:"type"`
	ActionStartDate localTime           `json:"actionStartDate"`
	ActionEndDate   *localTime          `json:"actionEndDate"`
	Enabled         *bool               `json:"enabled"`
	Value           []any               `json:"value"`
}

func (r featureFlagCreateRequest) toApp() app.FeatureFlagCreateRequest {
	enabled := false
	if r.Enabled != nil {
		enabled = *r.Enabled
	}
	return app.FeatureFlagCreateRequest{
		DomainCode:      r.DomainCode,
		Code:            r.Code,
		Name:            r.Name,
		Group:           r.Group,
		Type:            r.Type,
		ActionStartDate: r.ActionStartDate.Time,
		ActionEndDate:   localTimePtr(r.ActionEndDate),
		Enabled:         enabled,
		Value:           r.Value,
	}
}

type featureFlagUpdateRequest struct {
	DomainCode      string              `json:"domainCode"`
	Name            string              `json:"name"`
	Group           string              `json:"group"`
	Type            app.FeatureFlagType `json:"type"`
	ActionStartDate localTime           `json:"actionStartDate"`
	ActionEndDate   *localTime          `json:"actionEndDate"`
	Enabled         *bool               `json:"enabled"`
	Value           []any               `json:"value"`
}

func (r featureFlagUpdateRequest) toApp() app.FeatureFlagUpdateRequest {
	enabled := false
	if r.Enabled != nil {
		enabled = *r.Enabled
	}
	return app.FeatureFlagUpdateRequest{
		DomainCode:      r.DomainCode,
		Name:            r.Name,
		Group:           r.Group,
		Type:            r.Type,
		ActionStartDate: r.ActionStartDate.Time,
		ActionEndDate:   localTimePtr(r.ActionEndDate),
		Enabled:         enabled,
		Value:           r.Value,
	}
}

func (h *Handler) CreateFeatureFlag(w http.ResponseWriter, r *http.Request) {
	var req featureFlagCreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.features.Create(r.Context(), req.toApp(), actorFromRequest(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) UpdateFeatureFlag(w http.ResponseWriter, r *http.Request) {
	var req featureFlagUpdateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.features.Update(r.Context(), r.PathValue("code"), req.toApp(), actorFromRequest(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) SearchFeatureFlags(w http.ResponseWriter, r *http.Request) {
	req, err := featureFlagSearchFromQuery(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	result, err := h.features.Search(r.Context(), req)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) GetFeatureFlag(w http.ResponseWriter, r *http.Request) {
	result, err := h.features.FindByCode(r.Context(), r.PathValue("code"), r.URL.Query().Get("domainCode"))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) DeleteFeatureFlag(w http.ResponseWriter, r *http.Request) {
	if err := h.features.Delete(r.Context(), r.PathValue("code"), r.URL.Query().Get("domainCode"), actorFromRequest(r)); err != nil {
		writeAppError(w, err)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func (h *Handler) RecoverFeatureFlag(w http.ResponseWriter, r *http.Request) {
	result, err := h.features.Recover(r.Context(), r.PathValue("code"), r.URL.Query().Get("domainCode"), actorFromRequest(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) SearchFeatureFlagHistory(w http.ResponseWriter, r *http.Request) {
	req := featureFlagHistorySearchFromQuery(r)
	result, err := h.features.SearchHistory(r.Context(), req)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) GetInternalFeatureFlag(w http.ResponseWriter, r *http.Request) {
	if !h.isTrustedInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "missing internal service token")
		return
	}
	result, err := h.features.FindInternalByCode(r.Context(), r.PathValue("code"), r.URL.Query().Get("domainCode"))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

type domainRequest struct {
	Code        string `json:"code"`
	Description string `json:"description"`
}

func (h *Handler) CreateDomain(w http.ResponseWriter, r *http.Request) {
	var req domainRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.domains.Create(r.Context(), app.DomainCreateRequest(req), actorFromRequest(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) UpdateDomain(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(r.PathValue("teamId"), 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid team id")
		return
	}
	var req domainRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.domains.Update(r.Context(), id, app.DomainUpdateRequest(req), actorFromRequest(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) GetDomain(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(r.PathValue("teamId"), 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid team id")
		return
	}
	result, err := h.domains.FindByID(r.Context(), id)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) SearchDomains(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	result, err := h.domains.Search(r.Context(), app.DomainSearchRequest{
		Page:      queryInt(r, "page", 0),
		Size:      queryInt(r, "size", 10),
		OrderBy:   query.Get("orderBy"),
		Direction: query.Get("direction"),
		Search:    query.Get("search"),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func featureFlagSearchFromQuery(r *http.Request) (app.FeatureFlagSearchRequest, error) {
	query := r.URL.Query()
	start, err := parseOptionalLocalTime(query.Get("actionStartDate"))
	if err != nil {
		return app.FeatureFlagSearchRequest{}, err
	}
	end, err := parseOptionalLocalTime(query.Get("actionEndDate"))
	if err != nil {
		return app.FeatureFlagSearchRequest{}, err
	}
	inArchive, _ := strconv.ParseBool(query.Get("inArchive"))
	return app.FeatureFlagSearchRequest{
		Page:            queryInt(r, "page", 0),
		Size:            queryInt(r, "size", 10),
		OrderBy:         query.Get("orderBy"),
		Direction:       query.Get("direction"),
		DomainCode:      query.Get("domainCode"),
		Group:           query.Get("group"),
		ActionStartDate: start,
		ActionEndDate:   end,
		Search:          query.Get("search"),
		InArchive:       inArchive,
	}, nil
}

func featureFlagHistorySearchFromQuery(r *http.Request) app.FeatureFlagHistorySearchRequest {
	query := r.URL.Query()
	return app.FeatureFlagHistorySearchRequest{
		Page:            queryInt(r, "page", 0),
		Size:            queryInt(r, "size", 10),
		Cursor:          query.Get("cursor"),
		OrderBy:         query.Get("orderBy"),
		Direction:       query.Get("direction"),
		Code:            query.Get("code"),
		DomainCode:      query.Get("domainCode"),
		FeatureFlagType: app.FeatureFlagType(query.Get("featureFlagType")),
	}
}

func (h *Handler) isTrustedInternalRequest(r *http.Request) bool {
	if h.internalServiceToken == "" {
		return false
	}
	return strings.TrimSpace(r.Header.Get("X-Internal-Service-Token")) == h.internalServiceToken
}

func actorFromRequest(r *http.Request) string {
	if subject := strings.TrimSpace(SubjectFromContext(r.Context())); subject != "" {
		return subject
	}
	return "system"
}

func queryInt(r *http.Request, key string, fallback int) int {
	raw := strings.TrimSpace(r.URL.Query().Get(key))
	if raw == "" {
		return fallback
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		return fallback
	}
	return value
}

func localTimePtr(value *localTime) *time.Time {
	if value == nil {
		return nil
	}
	return &value.Time
}
