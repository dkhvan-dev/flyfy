package http

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/port"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/transport/dto"
	"github.com/google/uuid"
)

type Handler struct {
	useCase     *app.TourUseCase
	fileManager port.TourCoverFileManager
}

func NewHandler(useCase *app.TourUseCase, fileManager port.TourCoverFileManager) *Handler {
	return &Handler{useCase: useCase, fileManager: fileManager}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /v1/tours", h.ListTours)
	mux.HandleFunc("GET /v1/tours/{id}", h.GetTour)
	mux.HandleFunc("GET /v1/tours/{id}/cover", h.GetTourCover)

	mux.HandleFunc("POST /v1/me/tours", h.CreateTour)
	mux.HandleFunc("GET /v1/me/tours", h.ListMyTours)
	mux.HandleFunc("GET /v1/me/tours/{id}", h.GetMyTour)
	mux.HandleFunc("PUT /v1/me/tours/{id}", h.UpdateTour)
	mux.HandleFunc("DELETE /v1/me/tours/{id}", h.DeleteTour)
	mux.HandleFunc("POST /v1/me/tours/{id}/publish", h.PublishTour)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) CreateTour(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	var req dto.CreateTourRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	input, err := toCreateInput(actorUserID, req)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	aggregate, err := h.useCase.CreateTour(r.Context(), input)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to create tour")
		return
	}
	writeJSON(w, http.StatusCreated, toTourResponse(aggregate))
}

func (h *Handler) UpdateTour(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	tourID, ok := parsePathUUID(w, r, "id", "invalid tour id")
	if !ok {
		return
	}
	var req dto.UpdateTourRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	input, err := toUpdateInput(actorUserID, tourID, req)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	aggregate, err := h.useCase.UpdateTour(r.Context(), input)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to update tour")
		return
	}
	writeJSON(w, http.StatusOK, toTourResponse(aggregate))
}

func (h *Handler) PublishTour(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	tourID, ok := parsePathUUID(w, r, "id", "invalid tour id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.PublishTour(r.Context(), tourID, actorUserID)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to publish tour")
		return
	}
	writeJSON(w, http.StatusOK, toTourResponse(aggregate))
}

func (h *Handler) DeleteTour(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	tourID, ok := parsePathUUID(w, r, "id", "invalid tour id")
	if !ok {
		return
	}
	if err := h.useCase.DeleteTour(r.Context(), tourID, actorUserID); err != nil {
		h.writeUseCaseError(w, err, "failed to delete tour")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetTour(w http.ResponseWriter, r *http.Request) {
	tourID, ok := parsePathUUID(w, r, "id", "invalid tour id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.GetPublicTour(r.Context(), tourID)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to get tour")
		return
	}
	writeJSON(w, http.StatusOK, toTourResponse(aggregate))
}

func (h *Handler) GetMyTour(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	tourID, ok := parsePathUUID(w, r, "id", "invalid tour id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.GetMyTour(r.Context(), tourID, actorUserID)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to get tour")
		return
	}
	writeJSON(w, http.StatusOK, toTourResponse(aggregate))
}

func (h *Handler) ListTours(w http.ResponseWriter, r *http.Request) {
	requestedLimit := clampLimit(parseIntOrDefault(r.URL.Query().Get("limit"), 20))
	filter, ok := parseTourFilter(w, r, requestedLimit+1)
	if !ok {
		return
	}
	aggregates, err := h.useCase.ListTours(r.Context(), filter)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to list tours")
		return
	}
	writeJSON(w, http.StatusOK, toTourListResponse(aggregates, requestedLimit))
}

func (h *Handler) ListMyTours(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	requestedLimit := clampLimit(parseIntOrDefault(r.URL.Query().Get("limit"), 20))
	statuses := splitCSV(r.URL.Query().Get("status"))
	aggregates, err := h.useCase.ListMyTours(
		r.Context(),
		actorUserID,
		requestedLimit+1,
		parseIntOrDefault(r.URL.Query().Get("offset"), 0),
		statuses,
	)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to list my tours")
		return
	}
	writeJSON(w, http.StatusOK, toTourListResponse(aggregates, requestedLimit))
}

func (h *Handler) GetTourCover(w http.ResponseWriter, r *http.Request) {
	tourID, ok := parsePathUUID(w, r, "id", "invalid tour id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.GetPublicTour(r.Context(), tourID)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to get tour")
		return
	}
	if aggregate.CoverFileID == nil {
		writeError(w, http.StatusNotFound, "tour cover not found")
		return
	}
	if h.fileManager == nil {
		writeError(w, http.StatusServiceUnavailable, "file manager unavailable")
		return
	}
	downloadURL, err := h.fileManager.CreateDownloadURL(r.Context(), *aggregate.CoverFileID)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to resolve tour cover")
		return
	}
	proxyReq, err := http.NewRequestWithContext(r.Context(), http.MethodGet, downloadURL, nil)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build cover request")
		return
	}
	resp, err := http.DefaultClient.Do(proxyReq)
	if err != nil {
		writeError(w, http.StatusBadGateway, "failed to fetch tour cover")
		return
	}
	defer resp.Body.Close()
	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		writeError(w, http.StatusBadGateway, "failed to fetch tour cover")
		return
	}
	if contentType := strings.TrimSpace(resp.Header.Get("Content-Type")); contentType != "" {
		w.Header().Set("Content-Type", contentType)
	}
	w.Header().Set("Cache-Control", "public, max-age=300")
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, resp.Body)
}

func parseTourFilter(w http.ResponseWriter, r *http.Request, limit int) (port.TourFilter, bool) {
	query := r.URL.Query()
	filter := port.TourFilter{
		Limit:  limit,
		Offset: parseIntOrDefault(query.Get("offset"), 0),
	}
	publicVisibility := string(enum.TourVisibilityPublic)
	filter.Visibility = &publicVisibility
	if raw := strings.TrimSpace(query.Get("visibility")); raw != "" {
		switch enum.TourVisibility(raw) {
		case enum.TourVisibilityPublic, enum.TourVisibilityUnlisted:
			filter.Visibility = &raw
		default:
			writeError(w, http.StatusBadRequest, "invalid visibility")
			return port.TourFilter{}, false
		}
	}
	filter.CategorySlug = optionalString(query.Get("categorySlug"))
	filter.CountryCode = optionalString(query.Get("countryCode"))
	filter.CityName = optionalString(query.Get("cityName"))
	filter.LanguageCode = optionalString(query.Get("languageCode"))
	filter.SearchQuery = optionalString(query.Get("q"))
	filter.PriceMin = optionalFloat(query.Get("priceMin"))
	filter.PriceMax = optionalFloat(query.Get("priceMax"))
	filter.DurationMin = optionalInt(query.Get("durationMin"))
	filter.DurationMax = optionalInt(query.Get("durationMax"))
	filter.MaxGroupSizeMin = optionalInt(query.Get("maxGroupSizeMin"))
	return filter, true
}

func toCreateInput(actorUserID uuid.UUID, req dto.CreateTourRequest) (app.CreateTourInput, error) {
	landmarkID, err := parseOptionalUUIDString(req.LandmarkID)
	if err != nil {
		return app.CreateTourInput{}, fmt.Errorf("invalid landmarkId")
	}
	coverFileID, err := parseOptionalUUIDString(req.CoverFileID)
	if err != nil {
		return app.CreateTourInput{}, fmt.Errorf("invalid coverFileId")
	}
	return app.CreateTourInput{
		ActorUserID:     actorUserID,
		LandmarkID:      landmarkID,
		LandmarkName:    req.LandmarkName,
		Title:           req.Title,
		Summary:         req.Summary,
		Description:     req.Description,
		CategorySlug:    req.CategorySlug,
		Tags:            req.Tags,
		Visibility:      req.Visibility,
		DurationMinutes: req.DurationMinutes,
		MaxGroupSize:    req.MaxGroupSize,
		LanguageCodes:   req.LanguageCodes,
		CountryCode:     req.CountryCode,
		CityName:        req.CityName,
		MeetingPoint:    req.MeetingPoint,
		Latitude:        req.Latitude,
		Longitude:       req.Longitude,
		MapURL:          req.MapURL,
		PriceAmount:     req.PriceAmount,
		Currency:        req.Currency,
		CoverFileID:     coverFileID,
		IncludedItems:   req.IncludedItems,
		Itinerary:       toAppItinerary(req.Itinerary),
	}, nil
}

func toUpdateInput(actorUserID uuid.UUID, tourID uuid.UUID, req dto.UpdateTourRequest) (app.UpdateTourInput, error) {
	createInput, err := toCreateInput(actorUserID, req)
	if err != nil {
		return app.UpdateTourInput{}, err
	}
	return app.UpdateTourInput{
		ActorUserID:     createInput.ActorUserID,
		TourID:          tourID,
		LandmarkID:      createInput.LandmarkID,
		LandmarkName:    createInput.LandmarkName,
		Title:           createInput.Title,
		Summary:         createInput.Summary,
		Description:     createInput.Description,
		CategorySlug:    createInput.CategorySlug,
		Tags:            createInput.Tags,
		Visibility:      createInput.Visibility,
		DurationMinutes: createInput.DurationMinutes,
		MaxGroupSize:    createInput.MaxGroupSize,
		LanguageCodes:   createInput.LanguageCodes,
		CountryCode:     createInput.CountryCode,
		CityName:        createInput.CityName,
		MeetingPoint:    createInput.MeetingPoint,
		Latitude:        createInput.Latitude,
		Longitude:       createInput.Longitude,
		MapURL:          createInput.MapURL,
		PriceAmount:     createInput.PriceAmount,
		Currency:        createInput.Currency,
		CoverFileID:     createInput.CoverFileID,
		IncludedItems:   createInput.IncludedItems,
		Itinerary:       createInput.Itinerary,
	}, nil
}

func toAppItinerary(items []dto.TourItineraryItemRequest) []app.TourItineraryItemInput {
	result := make([]app.TourItineraryItemInput, 0, len(items))
	for _, item := range items {
		result = append(result, app.TourItineraryItemInput{
			StartOffsetMinutes: item.StartOffsetMinutes,
			DurationMinutes:    item.DurationMinutes,
			Title:              item.Title,
			Description:        item.Description,
		})
	}
	return result
}

func toTourListResponse(items []*app.TourAggregate, requestedLimit int) dto.TourListResponse {
	hasMore := len(items) > requestedLimit
	if hasMore {
		items = items[:requestedLimit]
	}
	resp := dto.TourListResponse{
		Items:   make([]dto.TourResponse, 0, len(items)),
		HasMore: hasMore,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toTourResponse(item))
	}
	return resp
}

func toTourResponse(aggregate *app.TourAggregate) dto.TourResponse {
	item := aggregate.Tour
	coverImageURL := (*string)(nil)
	if aggregate.CoverFileID != nil {
		value := fmt.Sprintf("/api/v1/tours/%s/cover", item.ID)
		coverImageURL = &value
	}
	return dto.TourResponse{
		ID:              item.ID.String(),
		GuideProfileID:  item.GuideProfileID.String(),
		GuideUserID:     item.GuideUserID.String(),
		LandmarkID:      formatOptionalUUID(item.LandmarkID),
		LandmarkName:    item.LandmarkName,
		Title:           item.Title,
		Summary:         item.Summary,
		Description:     item.Description,
		CategorySlug:    item.CategorySlug,
		Tags:            aggregate.Tags,
		Status:          string(item.Status),
		Visibility:      string(item.Visibility),
		DurationMinutes: item.DurationMinutes,
		MaxGroupSize:    item.MaxGroupSize,
		LanguageCodes:   aggregate.LanguageCodes,
		CountryCode:     item.CountryCode,
		CityName:        item.CityName,
		MeetingPoint:    item.MeetingPoint,
		Latitude:        item.Latitude,
		Longitude:       item.Longitude,
		MapURL:          item.MapURL,
		PriceAmount:     item.PriceAmount,
		Currency:        item.Currency,
		CoverFileID:     formatOptionalUUID(aggregate.CoverFileID),
		CoverImageURL:   coverImageURL,
		IncludedItems:   aggregate.IncludedItems,
		Itinerary:       toItineraryResponse(aggregate.Itinerary),
		PublishedAt:     formatOptionalTime(item.PublishedAt),
		DeletedAt:       formatOptionalTime(item.DeletedAt),
		Revision:        item.Revision,
		CreatedAt:       item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:       item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toItineraryResponse(items []*model.TourItineraryItem) []dto.TourItineraryItemResponse {
	result := make([]dto.TourItineraryItemResponse, 0, len(items))
	for _, item := range items {
		result = append(result, dto.TourItineraryItemResponse{
			ID:                 item.ID.String(),
			SortOrder:          item.SortOrder,
			StartOffsetMinutes: item.StartOffsetMinutes,
			DurationMinutes:    item.DurationMinutes,
			Title:              item.Title,
			Description:        item.Description,
			CreatedAt:          item.CreatedAt.UTC().Format(time.RFC3339),
			UpdatedAt:          item.UpdatedAt.UTC().Format(time.RFC3339),
		})
	}
	return result
}

func (h *Handler) writeUseCaseError(w http.ResponseWriter, err error, fallback string) {
	switch {
	case errors.Is(err, app.ErrInvalidActorUserID):
		writeError(w, http.StatusUnauthorized, err.Error())
	case errors.Is(err, app.ErrTourAccessDenied),
		errors.Is(err, app.ErrGuideNotAllowed):
		writeError(w, http.StatusForbidden, err.Error())
	case errors.Is(err, app.ErrTourNotFound),
		errors.Is(err, app.ErrTourCoverFileNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, model.ErrTourAlreadyArchived):
		writeError(w, http.StatusConflict, err.Error())
	case errors.Is(err, app.ErrInvalidTourID),
		errors.Is(err, app.ErrTourCoverFileNotReady),
		errors.Is(err, app.ErrTourCoverFileNotAllowed),
		errors.Is(err, model.ErrInvalidTourID),
		errors.Is(err, model.ErrInvalidGuideProfileID),
		errors.Is(err, model.ErrInvalidGuideUserID),
		errors.Is(err, model.ErrInvalidTourTitle),
		errors.Is(err, model.ErrInvalidTourSummary),
		errors.Is(err, model.ErrInvalidTourDescription),
		errors.Is(err, model.ErrInvalidTourCategory),
		errors.Is(err, model.ErrInvalidTourStatus),
		errors.Is(err, model.ErrInvalidTourVisibility),
		errors.Is(err, model.ErrInvalidTourDuration),
		errors.Is(err, model.ErrInvalidTourGroupSize),
		errors.Is(err, model.ErrInvalidTourMeeting),
		errors.Is(err, model.ErrInvalidTourPrice),
		errors.Is(err, model.ErrInvalidTourCurrency),
		errors.Is(err, model.ErrTourLanguageRequired),
		errors.Is(err, model.ErrTourItineraryRequired),
		errors.Is(err, model.ErrInvalidTourItineraryID),
		errors.Is(err, model.ErrInvalidTourItineraryOffset),
		errors.Is(err, model.ErrInvalidTourItineraryTitle),
		errors.Is(err, model.ErrInvalidTourItineraryDescription),
		errors.Is(err, model.ErrInvalidTourItineraryDuration):
		writeError(w, http.StatusBadRequest, err.Error())
	default:
		writeError(w, http.StatusInternalServerError, fallback)
	}
}

func parseActorUserID(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	raw := UserIDFromContext(r.Context())
	if raw == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return uuid.Nil, false
	}
	parsed, err := uuid.Parse(raw)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "invalid authenticated user")
		return uuid.Nil, false
	}
	return parsed, true
}

func parsePathUUID(w http.ResponseWriter, r *http.Request, key string, message string) (uuid.UUID, bool) {
	parsed, err := uuid.Parse(strings.TrimSpace(r.PathValue(key)))
	if err != nil {
		writeError(w, http.StatusBadRequest, message)
		return uuid.Nil, false
	}
	return parsed, true
}

func decodeBody(r *http.Request, dest any) error {
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(dest); err != nil {
		if errors.Is(err, io.EOF) {
			return errors.New("empty request body")
		}
		return errors.New("invalid request body")
	}
	return nil
}

func parseOptionalUUIDString(v *string) (*uuid.UUID, error) {
	if v == nil || strings.TrimSpace(*v) == "" {
		return nil, nil
	}
	parsed, err := uuid.Parse(strings.TrimSpace(*v))
	if err != nil {
		return nil, err
	}
	return &parsed, nil
}

func optionalString(v string) *string {
	if strings.TrimSpace(v) == "" {
		return nil
	}
	trimmed := strings.TrimSpace(v)
	return &trimmed
}

func optionalFloat(v string) *float64 {
	if strings.TrimSpace(v) == "" {
		return nil
	}
	parsed, err := strconv.ParseFloat(strings.TrimSpace(v), 64)
	if err != nil {
		return nil
	}
	return &parsed
}

func optionalInt(v string) *int {
	if strings.TrimSpace(v) == "" {
		return nil
	}
	parsed, err := strconv.Atoi(strings.TrimSpace(v))
	if err != nil {
		return nil
	}
	return &parsed
}

func parseIntOrDefault(v string, fallback int) int {
	parsed := optionalInt(v)
	if parsed == nil {
		return fallback
	}
	return *parsed
}

func clampLimit(limit int) int {
	if limit <= 0 {
		return 20
	}
	if limit > 100 {
		return 100
	}
	return limit
}

func splitCSV(v string) []string {
	parts := strings.Split(v, ",")
	result := make([]string, 0, len(parts))
	seen := make(map[string]struct{}, len(parts))
	for _, part := range parts {
		part = strings.ToUpper(strings.TrimSpace(part))
		if part == "" {
			continue
		}
		if _, ok := seen[part]; ok {
			continue
		}
		seen[part] = struct{}{}
		result = append(result, part)
	}
	return result
}

func formatOptionalTime(v *time.Time) *string {
	if v == nil {
		return nil
	}
	value := v.UTC().Format(time.RFC3339)
	return &value
}

func formatOptionalUUID(v *uuid.UUID) *string {
	if v == nil {
		return nil
	}
	value := v.String()
	return &value
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
