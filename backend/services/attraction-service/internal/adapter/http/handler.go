package http

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/transport/dto"
)

type Handler struct {
	useCase *app.AttractionUseCase
}

func NewHandler(useCase *app.AttractionUseCase) *Handler {
	return &Handler{useCase: useCase}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)

	// Attractions
	mux.HandleFunc("GET /v1/attractions", h.ListAttractions)
	mux.HandleFunc("POST /v1/attractions", h.CreateAttraction)
	mux.HandleFunc("GET /v1/attractions/{id}", h.GetAttraction)
	mux.HandleFunc("PUT /v1/attractions/{id}", h.UpdateAttraction)
	mux.HandleFunc("DELETE /v1/attractions/{id}", h.DeleteAttraction)
	mux.HandleFunc("POST /v1/attractions/{id}/recover", h.RecoverAttraction)
	mux.HandleFunc("PUT /v1/attractions/{id}/media", h.ReplaceAttractionMedia)

	// Reviews
	mux.HandleFunc("GET /v1/attractions/{id}/reviews", h.ListReviews)
	mux.HandleFunc("GET /v1/attractions/{id}/reviews/me", h.GetMyReview)
	mux.HandleFunc("POST /v1/attractions/{id}/reviews", h.CreateReview)
	mux.HandleFunc("DELETE /v1/reviews/{id}", h.DeleteReview)

	// Internal commands
	mux.HandleFunc("POST /internal/v1/attractions/{id}/rating/recalculate", h.RecalculateRating)
	mux.HandleFunc("POST /internal/v1/attractions/{id}/rating/sources", h.ApplyRatingSourceSnapshot)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// ---------------------------------------------------------------------------
// Attractions
// ---------------------------------------------------------------------------

func (h *Handler) CreateAttraction(w http.ResponseWriter, r *http.Request) {
	var req dto.CreateAttractionRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	view, err := h.useCase.CreateAttraction(r.Context(), SubjectFromContext(r.Context()), app.CreateAttractionInput{
		Title:             req.Title,
		Description:       req.Description,
		DefaultLocale:     req.DefaultLocale,
		Translations:      toAppTranslationInputs(req.Translations),
		CountryCode:       req.CountryCode,
		CityID:            req.CityID,
		AccessCities:      toAppCityLinkInputs(req.AccessCities),
		DepartureCities:   toAppCityLinkInputs(req.DepartureCities),
		Latitude:          req.Latitude,
		Longitude:         req.Longitude,
		LocationSourceURL: req.LocationSourceURL,
		Category:          req.Category,
		PriceAmount:       req.PriceAmount,
		PriceCurrency:     req.PriceCurrency,
		DurationValue:     req.DurationValue,
		DurationUnit:      req.DurationUnit,
		Rating:            req.Rating,
		Spots:             req.Spots,
		Status:            req.Status,
		Tags:              req.Tags,
		VisitInfo:         toAppVisitInfoInput(req.VisitInfo),
	})
	if err != nil {
		h.writeUseCaseError(w, err, "failed to create attraction")
		return
	}

	writeJSON(w, http.StatusCreated, toAttractionResponse(view))
}

func (h *Handler) GetAttraction(w http.ResponseWriter, r *http.Request) {
	attractionID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid attraction id")
		return
	}

	view, err := h.useCase.GetAttraction(r.Context(), attractionID, localeFromRequest(r))
	if err != nil {
		h.writeUseCaseError(w, err, "failed to get attraction")
		return
	}

	writeJSON(w, http.StatusOK, toAttractionResponse(view))
}

func (h *Handler) UpdateAttraction(w http.ResponseWriter, r *http.Request) {
	attractionID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid attraction id")
		return
	}

	var req dto.UpdateAttractionRequest
	if err = decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	view, err := h.useCase.UpdateAttraction(r.Context(), SubjectFromContext(r.Context()), attractionID, app.UpdateAttractionInput{
		Title:             req.Title,
		Description:       req.Description,
		DefaultLocale:     req.DefaultLocale,
		Translations:      toAppTranslationInputs(req.Translations),
		CountryCode:       req.CountryCode,
		CityID:            req.CityID,
		AccessCities:      toAppCityLinkInputs(req.AccessCities),
		DepartureCities:   toAppCityLinkInputs(req.DepartureCities),
		Latitude:          req.Latitude,
		Longitude:         req.Longitude,
		LocationSourceURL: req.LocationSourceURL,
		Category:          req.Category,
		PriceAmount:       req.PriceAmount,
		PriceCurrency:     req.PriceCurrency,
		DurationValue:     req.DurationValue,
		DurationUnit:      req.DurationUnit,
		Spots:             req.Spots,
		Status:            req.Status,
		Tags:              req.Tags,
		VisitInfo:         toAppVisitInfoInput(req.VisitInfo),
	}, UserRolesFromContext(r.Context()))
	if err != nil {
		h.writeUseCaseError(w, err, "failed to update attraction")
		return
	}

	writeJSON(w, http.StatusOK, toAttractionResponse(view))
}

func (h *Handler) DeleteAttraction(w http.ResponseWriter, r *http.Request) {
	attractionID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid attraction id")
		return
	}

	if err = h.useCase.DeleteAttraction(r.Context(), SubjectFromContext(r.Context()), attractionID, UserRolesFromContext(r.Context())); err != nil {
		h.writeUseCaseError(w, err, "failed to delete attraction")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RecoverAttraction(w http.ResponseWriter, r *http.Request) {
	attractionID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid attraction id")
		return
	}

	view, err := h.useCase.RecoverAttraction(r.Context(), attractionID, UserRolesFromContext(r.Context()))
	if err != nil {
		h.writeUseCaseError(w, err, "failed to recover attraction")
		return
	}

	writeJSON(w, http.StatusOK, toAttractionResponse(view))
}

func (h *Handler) ListAttractions(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()

	limit, offset, ok := parsePagination(w, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	var authorID *uuid.UUID
	if raw := strings.TrimSpace(query.Get("authorId")); raw != "" {
		parsed, err := uuid.Parse(raw)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid authorId")
			return
		}
		authorID = &parsed
	}

	priceMin := parseOptionalFloat(query.Get("priceMin"))
	priceMax := parseOptionalFloat(query.Get("priceMax"))
	durationMin := parseOptionalInt(query.Get("durationMin"))
	durationMax := parseOptionalInt(query.Get("durationMax"))
	spotsMin := parseOptionalInt(query.Get("spotsMin"))
	minRating := parseOptionalFloat(query.Get("minRating"))

	var durationUnit *string
	if raw := strings.TrimSpace(query.Get("durationUnit")); raw != "" {
		durationUnit = &raw
	}

	includeDeleted := query.Get("includeDeleted") == "true"

	views, total, err := h.useCase.ListAttractions(r.Context(), app.ListAttractionsInput{
		Search:          query.Get("search"),
		Locale:          localeFromRequest(r),
		Category:        query.Get("category"),
		CountryCode:     query.Get("countryCode"),
		CityID:          query.Get("cityId"),
		AccessCityID:    query.Get("accessCityId"),
		DepartureCityID: query.Get("departureCityId"),
		PriceMin:        priceMin,
		PriceMax:        priceMax,
		DurationMin:     durationMin,
		DurationMax:     durationMax,
		DurationUnit:    durationUnit,
		SpotsMin:        spotsMin,
		MinRating:       minRating,
		AuthorID:        authorID,
		Sort:            query.Get("sort"),
		Limit:           limit,
		Offset:          offset,
		IncludeDeleted:  includeDeleted,
	})
	if err != nil {
		h.writeUseCaseError(w, err, "failed to list attractions")
		return
	}

	resp := &dto.AttractionListResponse{
		Items: make([]*dto.AttractionResponse, 0, len(views)),
		Total: total,
	}
	for _, v := range views {
		resp.Items = append(resp.Items, toAttractionResponse(v))
	}

	writeJSON(w, http.StatusOK, resp)
}

// ---------------------------------------------------------------------------
// Media
// ---------------------------------------------------------------------------

func (h *Handler) ReplaceAttractionMedia(w http.ResponseWriter, r *http.Request) {
	attractionID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid attraction id")
		return
	}

	var req dto.ReplaceMediaRequest
	if err = decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	media := make([]app.ReplaceMediaInput, 0, len(req.Media))
	for _, m := range req.Media {
		fileID, parseErr := uuid.Parse(m.FileID)
		if parseErr != nil {
			writeError(w, http.StatusBadRequest, "invalid file id in media")
			return
		}
		media = append(media, app.ReplaceMediaInput{
			FileID:    fileID,
			MediaType: m.MediaType,
			Position:  m.Position,
		})
	}

	if err = h.useCase.ReplaceAttractionMedia(r.Context(), SubjectFromContext(r.Context()), attractionID, media, UserRolesFromContext(r.Context())); err != nil {
		h.writeUseCaseError(w, err, "failed to replace attraction media")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ---------------------------------------------------------------------------
// Reviews
// ---------------------------------------------------------------------------

func (h *Handler) CreateReview(w http.ResponseWriter, r *http.Request) {
	attractionID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid attraction id")
		return
	}

	var req dto.CreateReviewRequest
	if err = decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	media := make([]app.ReplaceMediaInput, 0, len(req.Media))
	for _, m := range req.Media {
		fileID, parseErr := uuid.Parse(m.FileID)
		if parseErr != nil {
			writeError(w, http.StatusBadRequest, "invalid file id in review media")
			return
		}
		media = append(media, app.ReplaceMediaInput{
			FileID:    fileID,
			MediaType: m.MediaType,
			Position:  m.Position,
		})
	}

	view, err := h.useCase.CreateReview(r.Context(), SubjectFromContext(r.Context()), attractionID, app.CreateReviewInput{
		Rating:  req.Rating,
		Comment: req.Comment,
	}, media)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to create review")
		return
	}

	writeJSON(w, http.StatusCreated, toReviewResponse(view))
}

func (h *Handler) ListReviews(w http.ResponseWriter, r *http.Request) {
	attractionID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid attraction id")
		return
	}

	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	views, total, err := h.useCase.ListReviews(r.Context(), attractionID, limit, offset)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to list reviews")
		return
	}

	resp := &dto.ReviewListResponse{
		Items: make([]*dto.ReviewResponse, 0, len(views)),
		Total: total,
	}
	for _, v := range views {
		resp.Items = append(resp.Items, toReviewResponse(v))
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) GetMyReview(w http.ResponseWriter, r *http.Request) {
	attractionID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid attraction id")
		return
	}

	view, err := h.useCase.GetMyReview(r.Context(), SubjectFromContext(r.Context()), attractionID)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to get current user review")
		return
	}

	writeJSON(w, http.StatusOK, toReviewResponse(view))
}

func (h *Handler) DeleteReview(w http.ResponseWriter, r *http.Request) {
	reviewID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid review id")
		return
	}

	if err = h.useCase.DeleteReview(r.Context(), SubjectFromContext(r.Context()), reviewID); err != nil {
		h.writeUseCaseError(w, err, "failed to delete review")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RecalculateRating(w http.ResponseWriter, r *http.Request) {
	attractionID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid attraction id")
		return
	}

	rating, reviewCount, err := h.useCase.RecalculateRating(r.Context(), attractionID)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to recalculate attraction rating")
		return
	}

	writeJSON(w, http.StatusOK, dto.RecalculateRatingResponse{
		AttractionID: attractionID.String(),
		Rating:       rating,
		ReviewCount:  reviewCount,
	})
}

func (h *Handler) ApplyRatingSourceSnapshot(w http.ResponseWriter, r *http.Request) {
	attractionID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid attraction id")
		return
	}

	var req dto.ApplyRatingSourceSnapshotRequest
	if err = decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	rating, reviewCount, err := h.useCase.ApplyRatingSourceSnapshot(r.Context(), app.RatingSourceSnapshotInput{
		AttractionID: attractionID,
		Source:       req.Source,
		RatingAvg:    req.RatingAvg,
		ReviewCount:  req.ReviewCount,
	})
	if err != nil {
		h.writeUseCaseError(w, err, "failed to apply attraction rating source snapshot")
		return
	}

	writeJSON(w, http.StatusOK, dto.RecalculateRatingResponse{
		AttractionID: attractionID.String(),
		Rating:       rating,
		ReviewCount:  reviewCount,
	})
}

// ---------------------------------------------------------------------------
// Error mapping
// ---------------------------------------------------------------------------

func (h *Handler) writeUseCaseError(w http.ResponseWriter, err error, fallback string) {
	switch {
	case errors.Is(err, app.ErrInvalidTitle),
		errors.Is(err, app.ErrInvalidLocale),
		errors.Is(err, app.ErrInvalidCategory),
		errors.Is(err, app.ErrInvalidStatus),
		errors.Is(err, app.ErrInvalidCountryCode),
		errors.Is(err, app.ErrInvalidCityID),
		errors.Is(err, app.ErrInvalidRating),
		errors.Is(err, app.ErrInvalidRatingSource),
		errors.Is(err, app.ErrInvalidMediaType),
		errors.Is(err, app.ErrInvalidDuration),
		errors.Is(err, app.ErrInvalidPrice),
		errors.Is(err, app.ErrInvalidLocation),
		errors.Is(err, app.ErrInvalidVisitInfo),
		errors.Is(err, app.ErrInvalidAttractionID),
		errors.Is(err, app.ErrInvalidReviewID),
		errors.Is(err, app.ErrCannotReviewOwn),
		errors.Is(err, app.ErrAttractionDeleted),
		errors.Is(err, app.ErrAttractionNotPublished):
		writeError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, app.ErrUnauthenticated):
		writeError(w, http.StatusUnauthorized, err.Error())
	case errors.Is(err, app.ErrAccessDenied):
		writeError(w, http.StatusForbidden, err.Error())
	case errors.Is(err, app.ErrAttractionNotFound),
		errors.Is(err, app.ErrReviewNotFound),
		errors.Is(err, app.ErrUserNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, app.ErrReviewConflict):
		writeError(w, http.StatusConflict, err.Error())
	default:
		writeError(w, http.StatusInternalServerError, fallback)
	}
}

// ---------------------------------------------------------------------------
// Response mappers
// ---------------------------------------------------------------------------

func toAttractionResponse(v *app.AttractionView) *dto.AttractionResponse {
	if v == nil || v.Attraction == nil {
		return nil
	}

	a := v.Attraction

	media := make([]dto.MediaResponse, 0, len(a.Media))
	for _, m := range a.Media {
		media = append(media, dto.MediaResponse{
			ID:          m.ID.String(),
			FileID:      m.FileID.String(),
			ExternalURL: m.ExternalURL,
			SourceURL:   m.SourceURL,
			Credit:      m.Credit,
			License:     m.License,
			MediaType:   string(m.MediaType),
			Position:    m.Position,
		})
	}

	var durationUnit *string
	if a.DurationUnit != nil {
		s := string(*a.DurationUnit)
		durationUnit = &s
	}

	var deletedAt *string
	if a.DeletedAt != nil {
		s := a.DeletedAt.UTC().Format(time.RFC3339)
		deletedAt = &s
	}

	var avatarFileID *string
	if v.Author.AvatarFileID != nil {
		s := v.Author.AvatarFileID.String()
		avatarFileID = &s
	}

	return &dto.AttractionResponse{
		ID:                a.ID.String(),
		Locale:            a.Locale,
		DefaultLocale:     a.DefaultLocale,
		Title:             a.Title,
		Description:       a.Description,
		CountryCode:       a.CountryCode,
		CityID:            a.CityID,
		AccessCities:      toCityLinkResponses(a.AccessCities),
		DepartureCities:   toCityLinkResponses(a.DepartureCities),
		Latitude:          a.Latitude,
		Longitude:         a.Longitude,
		LocationSourceURL: a.LocationSourceURL,
		Category:          string(a.Category),
		PriceAmount:       a.PriceAmount,
		PriceCurrency:     a.PriceCurrency,
		DurationValue:     a.DurationValue,
		DurationUnit:      durationUnit,
		Rating:            a.Rating,
		ReviewCount:       a.ReviewCount,
		Spots:             a.Spots,
		Source:            string(a.Source),
		Status:            string(a.Status),
		Tags:              a.Tags,
		VisitInfo:         toVisitInfoResponse(a.VisitInfo),
		Translations:      toTranslationResponses(a.Translations),
		Media:             media,
		Author: dto.AuthorResponse{
			UserID:       v.Author.UserID.String(),
			DisplayName:  v.Author.DisplayName,
			AvatarFileID: avatarFileID,
		},
		CreatedAt: a.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt: a.UpdatedAt.UTC().Format(time.RFC3339),
		DeletedAt: deletedAt,
	}
}

func toReviewResponse(v *app.ReviewView) *dto.ReviewResponse {
	if v == nil || v.Review == nil {
		return nil
	}

	r := v.Review

	media := make([]dto.MediaResponse, 0, len(r.Media))
	for _, m := range r.Media {
		media = append(media, dto.MediaResponse{
			ID:        m.ID.String(),
			FileID:    m.FileID.String(),
			MediaType: string(m.MediaType),
			Position:  m.Position,
		})
	}

	var avatarFileID *string
	if v.Author.AvatarFileID != nil {
		s := v.Author.AvatarFileID.String()
		avatarFileID = &s
	}

	return &dto.ReviewResponse{
		ID:           r.ID.String(),
		AttractionID: r.AttractionID.String(),
		Rating:       r.Rating,
		Comment:      r.Comment,
		Media:        media,
		Author: dto.AuthorResponse{
			UserID:       v.Author.UserID.String(),
			DisplayName:  v.Author.DisplayName,
			AvatarFileID: avatarFileID,
		},
		CreatedAt: r.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt: r.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

func parsePagination(w http.ResponseWriter, rawLimit string, rawOffset string) (int, int, bool) {
	limit := 20
	offset := 0

	if strings.TrimSpace(rawLimit) != "" {
		parsed, err := strconv.Atoi(strings.TrimSpace(rawLimit))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid limit")
			return 0, 0, false
		}
		limit = parsed
	}

	if strings.TrimSpace(rawOffset) != "" {
		parsed, err := strconv.Atoi(strings.TrimSpace(rawOffset))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid offset")
			return 0, 0, false
		}
		offset = parsed
	}

	return limit, offset, true
}

func parseOptionalFloat(raw string) *float64 {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil
	}
	v, err := strconv.ParseFloat(raw, 64)
	if err != nil {
		return nil
	}
	return &v
}

func parseOptionalInt(raw string) *int {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil
	}
	v, err := strconv.Atoi(raw)
	if err != nil {
		return nil
	}
	return &v
}

func localeFromRequest(r *http.Request) string {
	if locale := strings.TrimSpace(r.URL.Query().Get("locale")); locale != "" {
		return app.NormalizeAttractionLocale(locale)
	}

	for _, rawPart := range strings.Split(r.Header.Get("Accept-Language"), ",") {
		part := strings.TrimSpace(rawPart)
		if part == "" {
			continue
		}
		if idx := strings.Index(part, ";"); idx >= 0 {
			part = part[:idx]
		}
		locale := app.NormalizeAttractionLocale(part)
		if locale != "en" || strings.HasPrefix(strings.ToLower(part), "en") {
			return locale
		}
	}

	return app.NormalizeAttractionLocale("")
}

func toAppTranslationInputs(input map[string]dto.AttractionTranslationRequest) map[string]app.AttractionTranslationInput {
	if len(input) == 0 {
		return nil
	}
	result := make(map[string]app.AttractionTranslationInput, len(input))
	for locale, translation := range input {
		result[locale] = app.AttractionTranslationInput{
			Title:       translation.Title,
			Description: translation.Description,
		}
	}
	return result
}

func toAppCityLinkInputs(input []dto.AttractionCityLinkRequest) []app.AttractionCityLinkInput {
	if len(input) == 0 {
		return nil
	}
	result := make([]app.AttractionCityLinkInput, 0, len(input))
	for _, item := range input {
		result = append(result, app.AttractionCityLinkInput{
			CountryCode: item.CountryCode,
			CityID:      item.CityID,
		})
	}
	return result
}

func toAppVisitInfoInput(input *dto.AttractionVisitInfoRequest) *app.AttractionVisitInfoInput {
	if input == nil {
		return nil
	}
	return &app.AttractionVisitInfoInput{
		BestTime:        input.BestTime,
		Accessibility:   input.Accessibility,
		BookingRequired: input.BookingRequired,
		OpeningHours:    input.OpeningHours,
		Amenities:       input.Amenities,
		Audience:        input.Audience,
		SafetyNotes:     input.SafetyNotes,
		NearbyIDs:       input.NearbyIDs,
		LocalizedTips:   input.LocalizedTips,
	}
}

func toCityLinkResponses(input []model.AttractionCityLink) []dto.AttractionCityLinkResponse {
	if len(input) == 0 {
		return nil
	}
	result := make([]dto.AttractionCityLinkResponse, 0, len(input))
	for _, item := range input {
		result = append(result, dto.AttractionCityLinkResponse{
			CountryCode: item.CountryCode,
			CityID:      item.CityID,
		})
	}
	return result
}

func toTranslationResponses(input map[string]model.AttractionTranslation) map[string]dto.AttractionTranslationResponse {
	if len(input) == 0 {
		return nil
	}
	result := make(map[string]dto.AttractionTranslationResponse, len(input))
	for locale, translation := range input {
		result[locale] = dto.AttractionTranslationResponse{
			Title:       translation.Title,
			Description: translation.Description,
		}
	}
	return result
}

func toVisitInfoResponse(input model.AttractionVisitInfo) dto.AttractionVisitInfoResponse {
	nearbyIDs := make([]string, 0, len(input.NearbyIDs))
	for _, id := range input.NearbyIDs {
		nearbyIDs = append(nearbyIDs, id.String())
	}
	return dto.AttractionVisitInfoResponse{
		BestTime:        input.BestTime,
		Accessibility:   input.Accessibility,
		BookingRequired: input.BookingRequired,
		OpeningHours:    input.OpeningHours,
		Amenities:       input.Amenities,
		Audience:        input.Audience,
		SafetyNotes:     input.SafetyNotes,
		NearbyIDs:       nearbyIDs,
		LocalizedTips:   input.LocalizedTips,
	}
}

func decodeBody(r *http.Request, target any) error {
	if r.Body == nil {
		return errors.New("missing request body")
	}
	if err := json.NewDecoder(r.Body).Decode(target); err != nil {
		if errors.Is(err, io.EOF) {
			return errors.New("missing request body")
		}
		return errors.New("invalid request body")
	}
	return nil
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(statusCode int) {
	rw.statusCode = statusCode
	rw.ResponseWriter.WriteHeader(statusCode)
}
