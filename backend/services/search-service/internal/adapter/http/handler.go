package http

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/search-service/internal/app"
	"kz/inflap/backend/services/search-service/internal/domain/model"
)

const roleSearchIndex = "search:index"

type serviceAuthorizer interface {
	ValidateBearer(ctx context.Context, authHeader string, requiredRoles []string) (*serviceauth.Claims, error)
}

type Handler struct {
	searchUC          *app.SearchUseCase
	indexUC           *app.IndexingUseCase
	eventUC           *app.SearchEventUseCase
	documentUC        *app.DocumentEventUseCase
	internalToken     string
	serviceAuthorizer serviceAuthorizer
}

type Option func(*Handler)

func WithIndexing(indexUC *app.IndexingUseCase) Option {
	return func(h *Handler) {
		h.indexUC = indexUC
	}
}

func WithInternalToken(token string) Option {
	return func(h *Handler) {
		h.internalToken = strings.TrimSpace(token)
	}
}

func WithServiceAuthorizer(authorizer serviceAuthorizer) Option {
	return func(h *Handler) {
		h.serviceAuthorizer = authorizer
	}
}

func WithEvents(eventUC *app.SearchEventUseCase) Option {
	return func(h *Handler) {
		h.eventUC = eventUC
	}
}

func WithDocumentEvents(documentUC *app.DocumentEventUseCase) Option {
	return func(h *Handler) {
		h.documentUC = documentUC
	}
}

func NewHandler(searchUC *app.SearchUseCase, opts ...Option) *Handler {
	h := &Handler{searchUC: searchUC}
	for _, opt := range opts {
		opt(h)
	}
	return h
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /v1/search", h.Search)
	mux.HandleFunc("GET /v1/search/suggest", h.Suggest)
	mux.HandleFunc("GET /v1/search/trending", h.Trending)
	mux.HandleFunc("POST /v1/search/events", h.TrackEvent)
	mux.HandleFunc("POST /v1/search/index/events", h.IndexEvent)
	mux.HandleFunc("POST /v1/search/index/documents", h.IndexDocument)
	mux.HandleFunc("DELETE /v1/search/index/documents/{domain}/{entityID}", h.DeleteIndexDocument)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) Search(w http.ResponseWriter, r *http.Request) {
	h.searchWithQuery(w, r, r.URL.Query().Get("q"))
}

func (h *Handler) Suggest(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	page, err := h.search(r, app.SearchInput{
		Scope:   query.Get("scope"),
		Domains: query["domains"],
		Query:   query.Get("q"),
		Locale:  firstNonEmpty(query.Get("locale"), query.Get("lang")),
		Limit:   parsePositiveInt(firstNonEmpty(query.Get("limit"), "5")),
	})
	if err != nil {
		h.writeSearchError(w, err)
		return
	}

	suggestions := make([]searchSuggestionResponse, 0, len(page.Items))
	for _, item := range page.Items {
		suggestions = append(suggestions, searchSuggestionResponse{
			Domain:   string(item.Domain),
			EntityID: item.EntityID,
			Text:     item.Title,
			DeepLink: item.DeepLink,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"query":       query.Get("q"),
		"suggestions": suggestions,
	})
}

func (h *Handler) Trending(w http.ResponseWriter, r *http.Request) {
	h.searchWithQuery(w, r, "")
}

func (h *Handler) TrackEvent(w http.ResponseWriter, r *http.Request) {
	var payload searchEventRequest
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid event payload"})
		return
	}
	if !app.IsKnownSearchEvent(payload.EventType) {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "unsupported event type"})
		return
	}
	if h.eventUC != nil {
		err := h.eventUC.TrackEvent(r.Context(), app.TrackSearchEventInput{
			EventType:       payload.EventType,
			SearchSessionID: payload.SearchSessionID,
			Query:           payload.Query,
			Scope:           payload.Scope,
			Domain:          payload.Domain,
			EntityID:        payload.EntityID,
			ResultPosition:  payload.ResultPosition,
			Locale:          payload.Locale,
			RequestID:       firstNonEmpty(r.Header.Get("X-Request-Id"), r.Header.Get("X-Correlation-Id")),
			UserID:          r.Header.Get("X-User-Id"),
			AnonymousID:     payload.AnonymousID,
			Metadata:        payload.Metadata,
		})
		if err != nil {
			h.writeEventError(w, err)
			return
		}
	}
	writeJSON(w, http.StatusAccepted, map[string]string{"status": "accepted"})
}

func (h *Handler) IndexDocument(w http.ResponseWriter, r *http.Request) {
	if !h.authorizeInternal(w, r) {
		return
	}
	if h.indexUC == nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "indexing is not configured"})
		return
	}

	var payload indexDocumentRequest
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid index document payload"})
		return
	}

	err := h.indexUC.UpsertDocument(r.Context(), app.IndexDocumentInput{
		Domain:               payload.Domain,
		EntityID:             payload.EntityID,
		EntityVersion:        payload.EntityVersion,
		Locale:               payload.Locale,
		Title:                payload.Title,
		Subtitle:             payload.Subtitle,
		Description:          payload.Description,
		Tags:                 payload.Tags,
		CategoryCodes:        payload.CategoryCodes,
		CityID:               payload.CityID,
		CountryCode:          payload.CountryCode,
		Latitude:             payload.Latitude,
		Longitude:            payload.Longitude,
		PriceMin:             payload.PriceMin,
		PriceMax:             payload.PriceMax,
		Currency:             payload.Currency,
		Rating:               payload.Rating,
		ReviewCount:          payload.ReviewCount,
		PopularityScore:      payload.PopularityScore,
		FreshnessScore:       payload.FreshnessScore,
		TrustScore:           payload.TrustScore,
		AvailabilityStatus:   payload.AvailabilityStatus,
		Visibility:           payload.Visibility,
		ModerationStatus:     payload.ModerationStatus,
		OwnerUserID:          payload.OwnerUserID,
		PreviewImageFileID:   payload.PreviewImageFileID,
		DeepLink:             payload.DeepLink,
		SearchText:           payload.SearchText,
		SearchTextNormalized: payload.SearchTextNormalized,
		SearchVariants:       payload.SearchVariants,
	})
	if err != nil {
		h.writeIndexError(w, err)
		return
	}

	writeJSON(w, http.StatusAccepted, map[string]string{"status": "accepted"})
}

func (h *Handler) IndexEvent(w http.ResponseWriter, r *http.Request) {
	if !h.authorizeInternal(w, r) {
		return
	}
	if h.documentUC == nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "document event indexing is not configured"})
		return
	}

	var payload indexEventRequest
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid index event payload"})
		return
	}
	err := h.documentUC.EnqueueDocumentEvent(r.Context(), app.EnqueueDocumentEventInput{
		SourceService: payload.SourceService,
		SourceEventID: payload.SourceEventID,
		AggregateType: payload.AggregateType,
		AggregateID:   payload.AggregateID,
		EventType:     payload.EventType,
		Payload:       payload.Payload,
	})
	if err != nil {
		h.writeDocumentEventError(w, err)
		return
	}

	writeJSON(w, http.StatusAccepted, map[string]string{"status": "accepted"})
}

func (h *Handler) DeleteIndexDocument(w http.ResponseWriter, r *http.Request) {
	if !h.authorizeInternal(w, r) {
		return
	}
	if h.indexUC == nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "indexing is not configured"})
		return
	}

	entityID, err := url.PathUnescape(r.PathValue("entityID"))
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid entity id"})
		return
	}
	err = h.indexUC.DeleteDocument(r.Context(), app.DeleteDocumentInput{
		Domain:   r.PathValue("domain"),
		EntityID: entityID,
		Locale:   r.URL.Query().Get("locale"),
	})
	if err != nil {
		h.writeIndexError(w, err)
		return
	}

	writeJSON(w, http.StatusAccepted, map[string]string{"status": "accepted"})
}

func (h *Handler) searchWithQuery(w http.ResponseWriter, r *http.Request, searchQuery string) {
	query := r.URL.Query()
	input := app.SearchInput{
		Scope:     query.Get("scope"),
		Domains:   query["domains"],
		Query:     searchQuery,
		Locale:    firstNonEmpty(query.Get("locale"), query.Get("lang")),
		Limit:     parsePositiveInt(query.Get("page_size")),
		PageToken: query.Get("page_token"),
	}
	groupPageSize := parsePositiveInt(firstNonEmpty(query.Get("group_page_size"), query.Get("group_limit")))

	page, err := h.searchGrouped(r, input, groupPageSize)
	if err != nil {
		h.writeSearchError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, searchResponseFromGroupedPage(input, page))
}

func (h *Handler) search(r *http.Request, input app.SearchInput) (app.SearchPage, error) {
	return h.searchUC.Search(r.Context(), input)
}

func (h *Handler) searchGrouped(r *http.Request, input app.SearchInput, groupPageSize int) (app.GroupedSearchPage, error) {
	return h.searchUC.SearchGrouped(r.Context(), input, groupPageSize)
}

func (h *Handler) writeSearchError(w http.ResponseWriter, err error) {
	if errors.Is(err, model.ErrUnsupportedDomain) ||
		errors.Is(err, model.ErrUnsupportedScope) ||
		errors.Is(err, model.ErrScopeDomainMismatch) ||
		errors.Is(err, app.ErrInvalidSearchPageToken) {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "search failed"})
}

func (h *Handler) writeIndexError(w http.ResponseWriter, err error) {
	if errors.Is(err, model.ErrUnsupportedDomain) ||
		errors.Is(err, app.ErrInvalidSearchDocument) {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "indexing failed"})
}

func (h *Handler) writeDocumentEventError(w http.ResponseWriter, err error) {
	if errors.Is(err, app.ErrInvalidDocumentEvent) {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "document event indexing failed"})
}

func (h *Handler) writeEventError(w http.ResponseWriter, err error) {
	if errors.Is(err, app.ErrUnsupportedSearchEvent) ||
		errors.Is(err, model.ErrUnsupportedDomain) ||
		errors.Is(err, model.ErrUnsupportedScope) {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "event tracking failed"})
}

func (h *Handler) authorizeInternal(w http.ResponseWriter, r *http.Request) bool {
	if h.serviceAuthorizer != nil {
		authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
		if authHeader != "" {
			if _, err := h.serviceAuthorizer.ValidateBearer(r.Context(), authHeader, []string{roleSearchIndex}); err == nil {
				return true
			} else if serviceauth.IsForbidden(err) {
				writeJSON(w, http.StatusForbidden, map[string]string{"error": "service is not allowed"})
				return false
			} else if serviceauth.IsUnauthorized(err) {
				writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "missing or invalid service token"})
				return false
			} else {
				writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "service auth is unavailable"})
				return false
			}
		}
	}

	expected := strings.TrimSpace(h.internalToken)
	if expected == "" {
		if h.serviceAuthorizer != nil {
			writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "missing or invalid service token"})
			return false
		}
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "service auth is not configured"})
		return false
	}
	if tokenMatches(r.Header.Get("X-Internal-Service-Token"), expected) {
		return true
	}
	const bearerPrefix = "bearer "
	auth := strings.TrimSpace(r.Header.Get("Authorization"))
	if len(auth) > len(bearerPrefix) &&
		strings.EqualFold(auth[:len(bearerPrefix)], bearerPrefix) &&
		tokenMatches(strings.TrimSpace(auth[len(bearerPrefix):]), expected) {
		return true
	}
	writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "missing or invalid internal token"})
	return false
}

func tokenMatches(actual string, expected string) bool {
	actual = strings.TrimSpace(actual)
	if actual == "" || expected == "" {
		return false
	}
	return subtle.ConstantTimeCompare([]byte(actual), []byte(expected)) == 1
}

type searchResponse struct {
	Query         string                 `json:"query"`
	Locale        string                 `json:"locale"`
	TopResults    []searchResultResponse `json:"topResults"`
	Groups        searchGroupsResponse   `json:"groups"`
	NextPageToken string                 `json:"nextPageToken,omitempty"`
}

type searchGroupsResponse struct {
	Places      searchGroupResponse `json:"places"`
	Activities  searchGroupResponse `json:"activities"`
	Excursions  searchGroupResponse `json:"excursions"`
	Guides      searchGroupResponse `json:"guides"`
	Communities searchGroupResponse `json:"communities"`
	Users       searchGroupResponse `json:"users"`
}

type searchGroupResponse struct {
	Items         []searchResultResponse `json:"items"`
	NextPageToken string                 `json:"nextPageToken,omitempty"`
	HasMore       bool                   `json:"hasMore"`
}

type searchResultResponse struct {
	Domain   string  `json:"domain"`
	EntityID string  `json:"entityId"`
	Title    string  `json:"title"`
	Subtitle string  `json:"subtitle,omitempty"`
	DeepLink string  `json:"deepLink"`
	Score    float64 `json:"score"`
}

type searchSuggestionResponse struct {
	Domain   string `json:"domain"`
	EntityID string `json:"entityId"`
	Text     string `json:"text"`
	DeepLink string `json:"deepLink"`
}

type searchEventRequest struct {
	EventType       string         `json:"eventType"`
	SearchSessionID string         `json:"searchSessionId"`
	Query           string         `json:"query"`
	Scope           string         `json:"scope"`
	Domain          string         `json:"domain"`
	EntityID        string         `json:"entityId"`
	ResultPosition  int            `json:"resultPosition"`
	Locale          string         `json:"locale"`
	AnonymousID     string         `json:"anonymousId"`
	Metadata        map[string]any `json:"metadata"`
}

type indexEventRequest struct {
	SourceService string          `json:"sourceService"`
	SourceEventID string          `json:"sourceEventId"`
	AggregateType string          `json:"aggregateType"`
	AggregateID   string          `json:"aggregateId"`
	EventType     string          `json:"eventType"`
	Payload       json.RawMessage `json:"payload"`
}

type indexDocumentRequest struct {
	Domain               string            `json:"domain"`
	EntityID             string            `json:"entityId"`
	EntityVersion        int64             `json:"entityVersion"`
	Locale               string            `json:"locale"`
	Title                map[string]string `json:"title"`
	Subtitle             map[string]string `json:"subtitle"`
	Description          map[string]string `json:"description"`
	Tags                 []string          `json:"tags"`
	CategoryCodes        []string          `json:"categoryCodes"`
	CityID               string            `json:"cityId"`
	CountryCode          string            `json:"countryCode"`
	Latitude             *float64          `json:"latitude"`
	Longitude            *float64          `json:"longitude"`
	PriceMin             *float64          `json:"priceMin"`
	PriceMax             *float64          `json:"priceMax"`
	Currency             string            `json:"currency"`
	Rating               *float64          `json:"rating"`
	ReviewCount          int               `json:"reviewCount"`
	PopularityScore      float64           `json:"popularityScore"`
	FreshnessScore       float64           `json:"freshnessScore"`
	TrustScore           float64           `json:"trustScore"`
	AvailabilityStatus   string            `json:"availabilityStatus"`
	Visibility           string            `json:"visibility"`
	ModerationStatus     string            `json:"moderationStatus"`
	OwnerUserID          string            `json:"ownerUserId"`
	PreviewImageFileID   string            `json:"previewImageFileId"`
	DeepLink             string            `json:"deepLink"`
	SearchText           string            `json:"searchText"`
	SearchTextNormalized string            `json:"searchTextNormalized"`
	SearchVariants       []string          `json:"searchVariants"`
}

func searchResponseFromPage(input app.SearchInput, page app.SearchPage) searchResponse {
	resp := searchResponse{
		Query:         input.Query,
		Locale:        firstNonEmpty(input.Locale, "en"),
		TopResults:    make([]searchResultResponse, 0, len(page.Items)),
		NextPageToken: page.NextPageToken,
	}

	for _, item := range page.Items {
		mapped := searchResultResponse{
			Domain:   string(item.Domain),
			EntityID: item.EntityID,
			Title:    item.Title,
			Subtitle: item.Subtitle,
			DeepLink: item.DeepLink,
			Score:    item.Score,
		}
		resp.TopResults = append(resp.TopResults, mapped)

		switch item.Domain {
		case model.DomainActivity:
			resp.Groups.Activities.Items = append(resp.Groups.Activities.Items, mapped)
		case model.DomainExcursion:
			resp.Groups.Excursions.Items = append(resp.Groups.Excursions.Items, mapped)
		case model.DomainPlace:
			resp.Groups.Places.Items = append(resp.Groups.Places.Items, mapped)
		case model.DomainGuide:
			resp.Groups.Guides.Items = append(resp.Groups.Guides.Items, mapped)
		case model.DomainCommunity:
			resp.Groups.Communities.Items = append(resp.Groups.Communities.Items, mapped)
		case model.DomainUser:
			resp.Groups.Users.Items = append(resp.Groups.Users.Items, mapped)
		}
	}

	resp.Groups.Activities.Items = ensureSlice(resp.Groups.Activities.Items)
	resp.Groups.Excursions.Items = ensureSlice(resp.Groups.Excursions.Items)
	resp.Groups.Places.Items = ensureSlice(resp.Groups.Places.Items)
	resp.Groups.Guides.Items = ensureSlice(resp.Groups.Guides.Items)
	resp.Groups.Communities.Items = ensureSlice(resp.Groups.Communities.Items)
	resp.Groups.Users.Items = ensureSlice(resp.Groups.Users.Items)

	return resp
}

func searchResponseFromGroupedPage(input app.SearchInput, page app.GroupedSearchPage) searchResponse {
	resp := searchResponseFromPage(input, page.TopResults)
	resp.Groups.Places = searchGroupResponseFromPage(page.Groups[model.DomainPlace])
	resp.Groups.Activities = searchGroupResponseFromPage(page.Groups[model.DomainActivity])
	resp.Groups.Excursions = searchGroupResponseFromPage(page.Groups[model.DomainExcursion])
	resp.Groups.Guides = searchGroupResponseFromPage(page.Groups[model.DomainGuide])
	resp.Groups.Communities = searchGroupResponseFromPage(page.Groups[model.DomainCommunity])
	resp.Groups.Users = searchGroupResponseFromPage(page.Groups[model.DomainUser])
	return resp
}

func searchGroupResponseFromPage(page app.SearchPage) searchGroupResponse {
	items := make([]searchResultResponse, 0, len(page.Items))
	for _, item := range page.Items {
		items = append(items, searchResultResponse{
			Domain:   string(item.Domain),
			EntityID: item.EntityID,
			Title:    item.Title,
			Subtitle: item.Subtitle,
			DeepLink: item.DeepLink,
			Score:    item.Score,
		})
	}
	return searchGroupResponse{
		Items:         ensureSlice(items),
		NextPageToken: page.NextPageToken,
		HasMore:       page.NextPageToken != "",
	}
}

func ensureSlice(items []searchResultResponse) []searchResultResponse {
	if items == nil {
		return []searchResultResponse{}
	}
	return items
}

func parsePositiveInt(raw string) int {
	value, _ := strconv.Atoi(raw)
	if value < 0 {
		return 0
	}
	return value
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}
