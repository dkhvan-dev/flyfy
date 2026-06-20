package http

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"kz/inflap/backend/services/switches-service/internal/techbreak/app"
)

type Handler struct {
	breaks               *app.TechBreakService
	scopes               *app.TechBreakScopeService
	domains              *app.DomainService
	internalServiceToken string
}

func NewHandler(
	breaks *app.TechBreakService,
	scopes *app.TechBreakScopeService,
	domains *app.DomainService,
	internalServiceToken string,
) *Handler {
	return &Handler{
		breaks:               breaks,
		scopes:               scopes,
		domains:              domains,
		internalServiceToken: strings.TrimSpace(internalServiceToken),
	}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.Handle("POST /api/v1/tech-breaks", h.requireOperationsAccess(http.HandlerFunc(h.CreateTechBreak)))
	mux.Handle("GET /api/v1/tech-breaks", h.requireOperationsAccess(http.HandlerFunc(h.SearchTechBreaks)))
	mux.Handle("PUT /api/v1/tech-breaks/{techBreakId}", h.requireOperationsAccess(http.HandlerFunc(h.UpdateTechBreak)))
	mux.Handle("GET /api/v1/tech-breaks/{techBreakId}", h.requireOperationsAccess(http.HandlerFunc(h.GetTechBreak)))
	mux.Handle("DELETE /api/v1/tech-breaks/{techBreakId}", h.requireOperationsAccess(http.HandlerFunc(h.DeleteTechBreak)))
	mux.HandleFunc("GET /api/v1/internal/tech-breaks/has-active", h.HasActiveTechBreak)
	mux.Handle("POST /api/v1/dict/tech-break-scopes", h.requireOperationsAccess(http.HandlerFunc(h.CreateScope)))
	mux.Handle("GET /api/v1/dict/tech-break-scopes", h.requireOperationsAccess(http.HandlerFunc(h.ListScopes)))
	mux.Handle("PUT /api/v1/dict/tech-break-scopes/{techBreakScopeId}", h.requireOperationsAccess(http.HandlerFunc(h.UpdateScope)))
	mux.Handle("GET /api/v1/dict/tech-break-scopes/{techBreakScopeId}", h.requireOperationsAccess(http.HandlerFunc(h.GetScope)))
	mux.Handle("DELETE /api/v1/dict/tech-break-scopes/{techBreakScopeId}", h.requireOperationsAccess(http.HandlerFunc(h.DeleteScope)))
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
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

type techBreakUpsertRequest struct {
	DomainCode       string     `json:"domainCode"`
	Name             string     `json:"name"`
	ActionStartDate  localTime  `json:"actionStartDate"`
	ActionEndDate    *localTime `json:"actionEndDate"`
	ExcludeEmails    []string   `json:"excludeEmails"`
	ExcludeNicknames []string   `json:"excludeNicknames"`
	ScopeCodes       []string   `json:"scopeCodes"`
}

func (r techBreakUpsertRequest) toApp() app.TechBreakUpsertRequest {
	return app.TechBreakUpsertRequest{
		DomainCode:       r.DomainCode,
		Name:             r.Name,
		ActionStartDate:  r.ActionStartDate.Time,
		ActionEndDate:    localTimePtr(r.ActionEndDate),
		ExcludeEmails:    r.ExcludeEmails,
		ExcludeNicknames: r.ExcludeNicknames,
		ScopeCodes:       r.ScopeCodes,
	}
}

func (h *Handler) CreateTechBreak(w http.ResponseWriter, r *http.Request) {
	var req techBreakUpsertRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.breaks.Create(r.Context(), req.toApp(), actorFromRequest(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) UpdateTechBreak(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt64(w, r, "techBreakId")
	if !ok {
		return
	}
	var req techBreakUpsertRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.breaks.Update(r.Context(), id, req.toApp(), actorFromRequest(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) SearchTechBreaks(w http.ResponseWriter, r *http.Request) {
	req, err := techBreakSearchFromQuery(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	result, err := h.breaks.Search(r.Context(), req)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) GetTechBreak(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt64(w, r, "techBreakId")
	if !ok {
		return
	}
	result, err := h.breaks.FindByID(r.Context(), id, r.URL.Query().Get("domainCode"))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) DeleteTechBreak(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt64(w, r, "techBreakId")
	if !ok {
		return
	}
	if err := h.breaks.Delete(r.Context(), id, r.URL.Query().Get("domainCode")); err != nil {
		writeAppError(w, err)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func (h *Handler) HasActiveTechBreak(w http.ResponseWriter, r *http.Request) {
	if !h.isTrustedInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "missing internal service token")
		return
	}
	query := r.URL.Query()
	result, err := h.breaks.HasActive(r.Context(), app.TechBreakCheckRequest{
		DomainCode: query.Get("domainCode"),
		Nickname:   query.Get("nickname"),
		Email:      query.Get("email"),
		ScopeCodes: query["scopeCodes"],
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

type scopeCreateRequest struct {
	DomainCode string `json:"domainCode"`
	Code       string `json:"code"`
	Name       string `json:"name"`
}

type scopeUpdateRequest struct {
	DomainCode string `json:"domainCode"`
	Name       string `json:"name"`
}

func (h *Handler) CreateScope(w http.ResponseWriter, r *http.Request) {
	var req scopeCreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.scopes.Create(r.Context(), app.TechBreakScopeCreateRequest(req), actorFromRequest(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) UpdateScope(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt64(w, r, "techBreakScopeId")
	if !ok {
		return
	}
	var req scopeUpdateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.scopes.Update(r.Context(), id, app.TechBreakScopeUpdateRequest(req), actorFromRequest(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) ListScopes(w http.ResponseWriter, r *http.Request) {
	result, err := h.scopes.FindAll(r.Context(), r.URL.Query().Get("domainCode"))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) GetScope(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt64(w, r, "techBreakScopeId")
	if !ok {
		return
	}
	result, err := h.scopes.FindByID(r.Context(), id, r.URL.Query().Get("domainCode"))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) DeleteScope(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt64(w, r, "techBreakScopeId")
	if !ok {
		return
	}
	if err := h.scopes.Delete(r.Context(), id); err != nil {
		writeAppError(w, err)
		return
	}
	w.WriteHeader(http.StatusOK)
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
	result, err := h.domains.Create(r.Context(), app.DomainCreateRequest{Code: req.Code, Description: req.Description}, actorFromRequest(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) UpdateDomain(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt64(w, r, "teamId")
	if !ok {
		return
	}
	var req domainRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.domains.Update(r.Context(), id, app.DomainUpdateRequest{Code: req.Code, Description: req.Description}, actorFromRequest(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) GetDomain(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt64(w, r, "teamId")
	if !ok {
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

func techBreakSearchFromQuery(r *http.Request) (app.TechBreakSearchRequest, error) {
	query := r.URL.Query()
	start, err := parseOptionalLocalTime(query.Get("actionStartDate"))
	if err != nil {
		return app.TechBreakSearchRequest{}, err
	}
	end, err := parseOptionalLocalTime(query.Get("actionEndDate"))
	if err != nil {
		return app.TechBreakSearchRequest{}, err
	}
	return app.TechBreakSearchRequest{
		Page:            queryInt(r, "page", 0),
		Size:            queryInt(r, "size", 10),
		OrderBy:         query.Get("orderBy"),
		Direction:       query.Get("direction"),
		DomainCode:      query.Get("domainCode"),
		ActionStartDate: start,
		ActionEndDate:   end,
		Search:          query.Get("search"),
	}, nil
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

func pathInt64(w http.ResponseWriter, r *http.Request, name string) (int64, bool) {
	value, err := strconv.ParseInt(r.PathValue(name), 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid "+name)
		return 0, false
	}
	return value, true
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
