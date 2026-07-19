package http

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/app"
	"kz/inflap/backend/services/place-service/internal/domain/model"
	"kz/inflap/backend/services/place-service/internal/mediabackfill"
	"kz/inflap/backend/services/place-service/internal/transport/dto"
)

type mediaBackfillStarter interface {
	StartCountry(countryCode string) (string, error)
}

type savedAttractionCoverDelivery interface {
	CreatePublicSavedAttractionCoverDownloadURL(
		ctx context.Context,
		attractionID uuid.UUID,
		savedRevision uint64,
	) (string, error)
}

type Handler struct {
	useCase                      *app.PlaceUseCase
	mediaBackfill                mediaBackfillStarter
	savedAttractionCoverDelivery savedAttractionCoverDelivery
}

func NewHandler(
	useCase *app.PlaceUseCase,
	savedCoverDelivery ...savedAttractionCoverDelivery,
) *Handler {
	handler := &Handler{useCase: useCase}
	if len(savedCoverDelivery) > 0 {
		handler.savedAttractionCoverDelivery = savedCoverDelivery[0]
	}
	return handler
}

func (h *Handler) SetMediaBackfillStarter(starter mediaBackfillStarter) {
	h.mediaBackfill = starter
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)

	// Places.
	mux.HandleFunc("GET /v1/places", h.ListPlaces)
	mux.HandleFunc("POST /v1/places", h.CreatePlace)
	mux.HandleFunc("HEAD /v1/places/{id}/saved-cover", h.RejectPublicSavedAttractionCoverHEAD)
	mux.HandleFunc("GET /v1/places/{id}/saved-cover", h.GetPublicSavedAttractionCover)
	mux.HandleFunc("GET /v1/places/{id}", h.GetPlace)
	mux.HandleFunc("PUT /v1/places/{id}", h.UpdatePlace)
	mux.HandleFunc("DELETE /v1/places/{id}", h.DeletePlace)
	mux.HandleFunc("POST /v1/places/{id}/recover", h.RecoverPlace)
	mux.HandleFunc("PUT /v1/places/{id}/media", h.ReplacePlaceMedia)

	mux.HandleFunc("GET /v1/places/{id}/reviews", h.ListReviews)
	mux.HandleFunc("GET /v1/places/{id}/reviews/me", h.GetMyReview)
	mux.HandleFunc("POST /v1/places/{id}/reviews", h.CreateReview)

	mux.HandleFunc("GET /internal/v1/admin/places", h.ListPlaces)
	mux.HandleFunc("POST /internal/v1/admin/places", h.AdminCreatePlace)
	mux.HandleFunc("GET /internal/v1/admin/place-visit-references", h.ListPlaceVisitReferences)
	mux.HandleFunc("POST /internal/v1/admin/places/media/backfill", h.StartPlaceMediaBackfill)
	mux.HandleFunc("GET /internal/v1/admin/places/{id}", h.GetPlace)
	mux.HandleFunc("PUT /internal/v1/admin/places/{id}", h.AdminUpdatePlace)
	mux.HandleFunc("PUT /internal/v1/admin/places/{id}/media", h.AdminReplacePlaceMedia)
	mux.HandleFunc("POST /internal/v1/places/{id}/rating/recalculate", h.RecalculateRating)
	mux.HandleFunc("POST /internal/v1/places/{id}/rating/sources", h.ApplyRatingSourceSnapshot)

	mux.HandleFunc("DELETE /v1/reviews/{id}", h.DeleteReview)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) RejectPublicSavedAttractionCoverHEAD(w http.ResponseWriter, _ *http.Request) {
	setPublicSavedAttractionCoverHeaders(w.Header())
	w.Header().Set("Allow", http.MethodGet)
	w.WriteHeader(http.StatusMethodNotAllowed)
}

func (h *Handler) GetPublicSavedAttractionCover(w http.ResponseWriter, r *http.Request) {
	setPublicSavedAttractionCoverHeaders(w.Header())

	attractionID, savedRevision, err := parsePublicSavedAttractionCoverRequest(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid Saved attraction cover request")
		return
	}
	if h.savedAttractionCoverDelivery == nil {
		writeError(w, http.StatusServiceUnavailable, "Saved attraction cover delivery unavailable")
		return
	}

	downloadURL, err := h.savedAttractionCoverDelivery.CreatePublicSavedAttractionCoverDownloadURL(
		r.Context(),
		attractionID,
		savedRevision,
	)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrPublicSavedAttractionCoverNotFound):
			writeError(w, http.StatusNotFound, "Saved attraction cover not found")
		case errors.Is(err, app.ErrPublicSavedAttractionCoverUnavailable):
			writeError(w, http.StatusServiceUnavailable, "Saved attraction cover delivery unavailable")
		default:
			writeError(w, http.StatusBadGateway, "Saved attraction cover dependency failed")
		}
		return
	}

	w.Header().Set("Location", downloadURL)
	w.Header().Set("Content-Length", "0")
	w.WriteHeader(http.StatusTemporaryRedirect)
}

func parsePublicSavedAttractionCoverRequest(r *http.Request) (uuid.UUID, uint64, error) {
	if r == nil || r.URL == nil {
		return uuid.Nil, 0, errors.New("invalid Saved attraction cover request")
	}

	rawAttractionID := r.PathValue("id")
	attractionID, err := uuid.Parse(rawAttractionID)
	if err != nil || attractionID == uuid.Nil || attractionID.String() != rawAttractionID {
		return uuid.Nil, 0, errors.New("invalid Saved attraction cover request")
	}

	query, err := url.ParseQuery(r.URL.RawQuery)
	if err != nil || len(query) != 1 {
		return uuid.Nil, 0, errors.New("invalid Saved attraction cover request")
	}
	rawRevisions, ok := query["saved_revision"]
	if !ok || len(rawRevisions) != 1 {
		return uuid.Nil, 0, errors.New("invalid Saved attraction cover request")
	}
	rawRevision := rawRevisions[0]
	savedRevision, err := strconv.ParseUint(rawRevision, 10, 64)
	if err != nil || savedRevision == 0 || strconv.FormatUint(savedRevision, 10) != rawRevision ||
		r.URL.RawQuery != "saved_revision="+rawRevision {
		return uuid.Nil, 0, errors.New("invalid Saved attraction cover request")
	}

	if r.Body != nil {
		bodyPrefix, readErr := io.ReadAll(io.LimitReader(r.Body, 1))
		if readErr != nil || len(bodyPrefix) != 0 {
			return uuid.Nil, 0, errors.New("invalid Saved attraction cover request")
		}
	}
	return attractionID, savedRevision, nil
}

func setPublicSavedAttractionCoverHeaders(header http.Header) {
	header.Set("Cache-Control", "no-store")
	header.Set("Referrer-Policy", "no-referrer")
	header.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'; sandbox")
	header.Set("X-Content-Type-Options", "nosniff")
}

func (h *Handler) ListPlaceVisitReferences(w http.ResponseWriter, r *http.Request) {
	items, err := h.useCase.ListPlaceVisitReferences(r.Context(), localeFromRequest(r))
	if err != nil {
		h.writeUseCaseError(w, err, "failed to list place visit references")
		return
	}
	writeJSON(w, http.StatusOK, toPlaceVisitReferenceListResponse(items))
}

// ---------------------------------------------------------------------------
// Places
// ---------------------------------------------------------------------------

func (h *Handler) CreatePlace(w http.ResponseWriter, r *http.Request) {
	var req dto.CreatePlaceRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	view, err := h.useCase.CreatePlace(r.Context(), SubjectFromContext(r.Context()), app.CreatePlaceInput{
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
		h.writeUseCaseError(w, err, "failed to create place")
		return
	}

	writeJSON(w, http.StatusCreated, toPlaceResponse(view))
}

func (h *Handler) AdminCreatePlace(w http.ResponseWriter, r *http.Request) {
	var req dto.CreatePlaceRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	view, err := h.useCase.CreatePlaceByAdmin(r.Context(), app.CreatePlaceInput{
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
		h.writeUseCaseError(w, err, "failed to create place")
		return
	}

	writeJSON(w, http.StatusCreated, toAdminPlaceResponse(view))
}

func (h *Handler) GetPlace(w http.ResponseWriter, r *http.Request) {
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
		return
	}

	isAdminRead := strings.HasPrefix(r.URL.Path, "/internal/v1/admin/")
	var view *app.PlaceView
	if isAdminRead {
		view, err = h.useCase.GetPlace(r.Context(), placeID, localeFromRequest(r))
	} else {
		view, err = h.useCase.GetPublicPlace(r.Context(), placeID, localeFromRequest(r))
	}
	if err != nil {
		h.writeUseCaseError(w, err, "failed to get place")
		return
	}

	if isAdminRead {
		writeJSON(w, http.StatusOK, toAdminPlaceResponse(view))
		return
	}
	writeJSON(w, http.StatusOK, toPlaceResponse(view))
}

func (h *Handler) UpdatePlace(w http.ResponseWriter, r *http.Request) {
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
		return
	}

	var req dto.UpdatePlaceRequest
	if err = decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	view, err := h.useCase.UpdatePlace(r.Context(), SubjectFromContext(r.Context()), placeID, app.UpdatePlaceInput{
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
		h.writeUseCaseError(w, err, "failed to update place")
		return
	}

	writeJSON(w, http.StatusOK, toPlaceResponse(view))
}

func (h *Handler) AdminUpdatePlace(w http.ResponseWriter, r *http.Request) {
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
		return
	}

	var req dto.UpdatePlaceRequest
	if err = decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	view, err := h.useCase.UpdatePlaceByAdmin(r.Context(), placeID, app.UpdatePlaceInput{
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
	})
	if err != nil {
		h.writeUseCaseError(w, err, "failed to update place")
		return
	}

	writeJSON(w, http.StatusOK, toAdminPlaceResponse(view))
}

func (h *Handler) DeletePlace(w http.ResponseWriter, r *http.Request) {
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
		return
	}

	if err = h.useCase.DeletePlace(r.Context(), SubjectFromContext(r.Context()), placeID, UserRolesFromContext(r.Context())); err != nil {
		h.writeUseCaseError(w, err, "failed to delete place")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RecoverPlace(w http.ResponseWriter, r *http.Request) {
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
		return
	}

	view, err := h.useCase.RecoverPlace(r.Context(), placeID, UserRolesFromContext(r.Context()))
	if err != nil {
		h.writeUseCaseError(w, err, "failed to recover place")
		return
	}

	writeJSON(w, http.StatusOK, toPlaceResponse(view))
}

func (h *Handler) ListPlaces(w http.ResponseWriter, r *http.Request) {
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
	latitude := parseOptionalFloat(query.Get("latitude"))
	longitude := parseOptionalFloat(query.Get("longitude"))

	var durationUnit *string
	if raw := strings.TrimSpace(query.Get("durationUnit")); raw != "" {
		durationUnit = &raw
	}

	includeDeleted := query.Get("includeDeleted") == "true"

	views, total, err := h.useCase.ListPlaces(r.Context(), app.ListPlacesInput{
		Search:          query.Get("search"),
		Locale:          localeFromRequest(r),
		Category:        query.Get("category"),
		CountryCode:     query.Get("countryCode"),
		CityID:          query.Get("cityId"),
		RegionID:        firstNonEmpty(query.Get("regionId"), query.Get("destinationId")),
		AccessCityID:    query.Get("accessCityId"),
		DepartureCityID: query.Get("departureCityId"),
		PriceMin:        priceMin,
		PriceMax:        priceMax,
		DurationMin:     durationMin,
		DurationMax:     durationMax,
		DurationUnit:    durationUnit,
		SpotsMin:        spotsMin,
		MinRating:       minRating,
		Latitude:        latitude,
		Longitude:       longitude,
		AuthorID:        authorID,
		Sort:            query.Get("sort"),
		Limit:           limit,
		Offset:          offset,
		IncludeDeleted:  includeDeleted,
	})
	if err != nil {
		h.writeUseCaseError(w, err, "failed to list places")
		return
	}

	resp := &dto.PlaceListResponse{
		Items: make([]*dto.PlaceResponse, 0, len(views)),
		Total: total,
	}
	for _, v := range views {
		resp.Items = append(resp.Items, toPlaceResponse(v))
	}

	writeJSON(w, http.StatusOK, resp)
}

// ---------------------------------------------------------------------------
// Media
// ---------------------------------------------------------------------------

func (h *Handler) ReplacePlaceMedia(w http.ResponseWriter, r *http.Request) {
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
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

	if err = h.useCase.ReplacePlaceMedia(r.Context(), SubjectFromContext(r.Context()), placeID, media, UserRolesFromContext(r.Context())); err != nil {
		h.writeUseCaseError(w, err, "failed to replace place media")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) AdminReplacePlaceMedia(w http.ResponseWriter, r *http.Request) {
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
		return
	}

	media, ok := h.parseReplaceMediaRequest(w, r)
	if !ok {
		return
	}

	if err = h.useCase.ReplacePlaceMediaByAdmin(r.Context(), placeID, media); err != nil {
		h.writeUseCaseError(w, err, "failed to replace place media")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) StartPlaceMediaBackfill(w http.ResponseWriter, r *http.Request) {
	if h.mediaBackfill == nil {
		writeError(w, http.StatusServiceUnavailable, "media backfill runner is not configured")
		return
	}

	var req struct {
		CountryCode string `json:"countryCode"`
	}
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	countryCode := strings.ToUpper(strings.TrimSpace(req.CountryCode))
	if countryCode == "" {
		writeError(w, http.StatusBadRequest, mediabackfill.ErrInvalidCountryCode.Error())
		return
	}

	jobID, err := h.mediaBackfill.StartCountry(countryCode)
	if err != nil {
		switch {
		case errors.Is(err, mediabackfill.ErrInvalidCountryCode):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, mediabackfill.ErrAlreadyRunning):
			writeError(w, http.StatusConflict, err.Error())
		default:
			writeError(w, http.StatusServiceUnavailable, "failed to start media backfill")
		}
		return
	}

	writeJSON(w, http.StatusAccepted, map[string]string{
		"jobId":       jobID,
		"countryCode": countryCode,
		"status":      "STARTED",
	})
}

func (h *Handler) parseReplaceMediaRequest(w http.ResponseWriter, r *http.Request) ([]app.ReplaceMediaInput, bool) {
	var req dto.ReplaceMediaRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return nil, false
	}

	media := make([]app.ReplaceMediaInput, 0, len(req.Media))
	for _, m := range req.Media {
		fileID, parseErr := uuid.Parse(m.FileID)
		if parseErr != nil {
			writeError(w, http.StatusBadRequest, "invalid file id in media")
			return nil, false
		}
		media = append(media, app.ReplaceMediaInput{
			FileID:      fileID,
			ExternalURL: strings.TrimSpace(m.ExternalURL),
			SourceURL:   strings.TrimSpace(m.SourceURL),
			Credit:      strings.TrimSpace(m.Credit),
			License:     strings.TrimSpace(m.License),
			MediaType:   m.MediaType,
			Position:    m.Position,
		})
	}
	return media, true
}

// ---------------------------------------------------------------------------
// Reviews
// ---------------------------------------------------------------------------

func (h *Handler) CreateReview(w http.ResponseWriter, r *http.Request) {
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
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

	view, err := h.useCase.CreateReview(r.Context(), SubjectFromContext(r.Context()), placeID, app.CreateReviewInput{
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
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
		return
	}

	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	views, total, err := h.useCase.ListReviews(r.Context(), placeID, limit, offset)
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
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
		return
	}

	view, err := h.useCase.GetMyReview(r.Context(), SubjectFromContext(r.Context()), placeID)
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
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
		return
	}

	rating, reviewCount, err := h.useCase.RecalculateRating(r.Context(), placeID)
	if err != nil {
		h.writeUseCaseError(w, err, "failed to recalculate place rating")
		return
	}

	writeJSON(w, http.StatusOK, dto.RecalculateRatingResponse{
		PlaceID:     placeID.String(),
		Rating:      rating,
		ReviewCount: reviewCount,
	})
}

func (h *Handler) ApplyRatingSourceSnapshot(w http.ResponseWriter, r *http.Request) {
	placeID, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid place id")
		return
	}

	var req dto.ApplyRatingSourceSnapshotRequest
	if err = decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	rating, reviewCount, err := h.useCase.ApplyRatingSourceSnapshot(r.Context(), app.RatingSourceSnapshotInput{
		PlaceID:     placeID,
		Source:      req.Source,
		RatingAvg:   req.RatingAvg,
		ReviewCount: req.ReviewCount,
	})
	if err != nil {
		h.writeUseCaseError(w, err, "failed to apply place rating source snapshot")
		return
	}

	writeJSON(w, http.StatusOK, dto.RecalculateRatingResponse{
		PlaceID:     placeID.String(),
		Rating:      rating,
		ReviewCount: reviewCount,
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
		errors.Is(err, app.ErrInvalidPlaceID),
		errors.Is(err, app.ErrInvalidReviewID),
		errors.Is(err, app.ErrCannotReviewOwn),
		errors.Is(err, app.ErrPlaceDeleted),
		errors.Is(err, app.ErrPlaceNotPublished):
		writeError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, app.ErrUnauthenticated):
		writeError(w, http.StatusUnauthorized, err.Error())
	case errors.Is(err, app.ErrAccessDenied):
		writeError(w, http.StatusForbidden, err.Error())
	case errors.Is(err, app.ErrPlaceNotFound),
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

func toPlaceVisitReferenceListResponse(items []model.PlaceVisitReferenceValue) dto.PlaceVisitReferenceListResponse {
	resp := dto.PlaceVisitReferenceListResponse{
		Categories: make(map[string][]dto.PlaceVisitReferenceValueResponse),
	}
	for _, item := range items {
		category := strings.TrimSpace(item.Category)
		code := strings.TrimSpace(item.Code)
		if category == "" || code == "" {
			continue
		}
		resp.Categories[category] = append(resp.Categories[category], dto.PlaceVisitReferenceValueResponse{
			Code:      code,
			Label:     strings.TrimSpace(item.Label),
			Labels:    item.Labels,
			SortOrder: item.SortOrder,
			Active:    item.Active,
		})
	}
	return resp
}

func toPlaceResponse(v *app.PlaceView) *dto.PlaceResponse {
	if v == nil || v.Place == nil {
		return nil
	}

	a := v.Place

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

	return &dto.PlaceResponse{
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
		PriceSummaryLabel: placePriceSummaryLabel(a),
		DurationValue:     a.DurationValue,
		DurationUnit:      durationUnit,
		Rating:            a.Rating,
		ReviewCount:       a.ReviewCount,
		Spots:             a.Spots,
		Source:            string(a.Source),
		Status:            string(a.Status),
		Tags:              a.Tags,
		VisitInfo:         toVisitInfoResponse(a.VisitInfo, a.Locale, a.DefaultLocale),
		Translations:      toTranslationResponses(a.Translations),
		Media:             media,
		Author: dto.AuthorResponse{
			UserID:       v.Author.UserID.String(),
			Nickname:     v.Author.Nickname,
			AvatarFileID: avatarFileID,
		},
		CreatedAt: a.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt: a.UpdatedAt.UTC().Format(time.RFC3339),
		DeletedAt: deletedAt,
	}
}

func toAdminPlaceResponse(v *app.PlaceView) *dto.PlaceResponse {
	response := toPlaceResponse(v)
	if response == nil || v == nil || v.Place == nil {
		return response
	}
	response.VisitInfoLocales = toVisitInfoLocalizedResponse(v.Place.VisitInfo)
	return response
}

func placePriceSummaryLabel(place *model.Place) string {
	if place == nil {
		return ""
	}
	amount, currency, isFree, ok := placePriceSummaryValue(place)
	locale := app.NormalizePlaceLocale(place.Locale)
	if isFree {
		return localizedPriceSummaryFree(locale)
	}
	if !ok {
		return localizedPriceSummaryUnknown(locale)
	}
	formatted := formatPriceSummaryAmount(amount, currency)
	if formatted == "" {
		return localizedPriceSummaryUnknown(locale)
	}
	return localizedPriceSummaryFrom(locale, formatted)
}

func placePriceSummaryValue(place *model.Place) (amount float64, currency string, isFree bool, ok bool) {
	if place.PriceAmount != nil {
		if *place.PriceAmount <= 0 {
			return 0, "", true, true
		}
		return *place.PriceAmount, priceSummaryCurrency(place.PriceCurrency, ""), false, true
	}
	if amount, currency, ok := placeFeeItemSummaryValue(place.VisitInfo.FeeItems, true); ok {
		if amount <= 0 {
			return 0, "", true, true
		}
		return amount, currency, false, true
	}
	if amount, currency, ok := placeFeeItemSummaryValue(place.VisitInfo.FeeItems, false); ok {
		if amount <= 0 {
			return 0, "", true, true
		}
		return amount, currency, false, true
	}
	if amount, currency, ok := placeFeeDetailSummaryValue(place.VisitInfo.FeeDetails); ok {
		if amount <= 0 {
			return 0, "", true, true
		}
		return amount, currency, false, true
	}
	return 0, "", false, false
}

func placeFeeItemSummaryValue(items []model.PlaceFeeItem, requiredOnly bool) (float64, string, bool) {
	var bestAmount float64
	var bestCurrency string
	found := false
	for _, item := range items {
		if requiredOnly && !item.Required {
			continue
		}
		amount := item.MinAmount
		if amount == nil {
			amount = item.Amount
		}
		if amount == nil || item.Currency == "" {
			continue
		}
		if !found || *amount < bestAmount {
			bestAmount = *amount
			bestCurrency = item.Currency
			found = true
		}
	}
	return bestAmount, bestCurrency, found
}

func placeFeeDetailSummaryValue(items []model.PlaceFeeDetail) (float64, string, bool) {
	var bestAmount float64
	var bestCurrency string
	found := false
	for _, item := range items {
		if item.Amount == nil || item.Currency == "" {
			continue
		}
		if !found || *item.Amount < bestAmount {
			bestAmount = *item.Amount
			bestCurrency = item.Currency
			found = true
		}
	}
	return bestAmount, bestCurrency, found
}

func priceSummaryCurrency(primary *string, fallback string) string {
	if primary != nil && strings.TrimSpace(*primary) != "" {
		return strings.ToUpper(strings.TrimSpace(*primary))
	}
	return strings.ToUpper(strings.TrimSpace(fallback))
}

func formatPriceSummaryAmount(amount float64, currency string) string {
	currency = strings.ToUpper(strings.TrimSpace(currency))
	if currency == "" {
		return ""
	}
	amountText := strconv.FormatFloat(amount, 'f', 2, 64)
	amountText = strings.TrimRight(strings.TrimRight(amountText, "0"), ".")
	switch currency {
	case "USD":
		return "$" + amountText
	case "EUR":
		return amountText + " €"
	case "KZT":
		return amountText + " ₸"
	case "RUB":
		return amountText + " ₽"
	default:
		return amountText + " " + currency
	}
}

func localizedPriceSummaryFree(locale string) string {
	switch app.NormalizePlaceLocale(locale) {
	case "ru":
		return "Бесплатно"
	case "kk":
		return "Тегін"
	default:
		return "Free"
	}
}

func localizedPriceSummaryUnknown(locale string) string {
	switch app.NormalizePlaceLocale(locale) {
	case "ru":
		return "цена уточняется"
	case "kk":
		return "баға нақтыланады"
	default:
		return "price to confirm"
	}
}

func localizedPriceSummaryFrom(locale string, amount string) string {
	switch app.NormalizePlaceLocale(locale) {
	case "ru":
		return "от " + amount
	case "kk":
		return amount + " бастап"
	default:
		return "from " + amount
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
		ID:      r.ID.String(),
		PlaceID: r.PlaceID.String(),
		Rating:  r.Rating,
		Comment: r.Comment,
		Media:   media,
		Author: dto.AuthorResponse{
			UserID:       v.Author.UserID.String(),
			Nickname:     v.Author.Nickname,
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
		return app.NormalizePlaceLocale(locale)
	}

	for _, rawPart := range strings.Split(r.Header.Get("Accept-Language"), ",") {
		part := strings.TrimSpace(rawPart)
		if part == "" {
			continue
		}
		if idx := strings.Index(part, ";"); idx >= 0 {
			part = part[:idx]
		}
		locale := app.NormalizePlaceLocale(part)
		if locale != "en" || strings.HasPrefix(strings.ToLower(part), "en") {
			return locale
		}
	}

	return app.NormalizePlaceLocale("")
}

func toAppTranslationInputs(input map[string]dto.PlaceTranslationRequest) map[string]app.PlaceTranslationInput {
	if len(input) == 0 {
		return nil
	}
	result := make(map[string]app.PlaceTranslationInput, len(input))
	for locale, translation := range input {
		result[locale] = app.PlaceTranslationInput{
			Title:       translation.Title,
			Description: translation.Description,
		}
	}
	return result
}

func toAppCityLinkInputs(input []dto.PlaceCityLinkRequest) []app.PlaceCityLinkInput {
	if len(input) == 0 {
		return nil
	}
	result := make([]app.PlaceCityLinkInput, 0, len(input))
	for _, item := range input {
		result = append(result, app.PlaceCityLinkInput{
			CountryCode: item.CountryCode,
			CityID:      item.CityID,
		})
	}
	return result
}

func toAppVisitInfoInput(input *dto.PlaceVisitInfoRequest) *app.PlaceVisitInfoInput {
	if input == nil {
		return nil
	}
	return &app.PlaceVisitInfoInput{
		BestTime:        input.BestTime,
		Accessibility:   input.Accessibility,
		BookingRequired: input.BookingRequired,
		OpeningHours:    toModelOpeningHours(input.OpeningHours),
		Amenities:       input.Amenities,
		Audience:        input.Audience,
		SafetyNotes:     input.SafetyNotes,
		NearbyIDs:       input.NearbyIDs,
		LocalizedTips:   input.LocalizedTips,
		Season:          toModelSeason(input.Season),
		GettingThere:    model.LocalizedText(input.GettingThere),
		Included:        toModelLocalizedList(input.Included),
		Excluded:        toModelLocalizedList(input.Excluded),
		Links:           toModelLinks(input.Links),
		FeeDetails:      toAppFeeDetailInputs(input.FeeDetails),
		PriceNote:       model.LocalizedText(input.PriceNote),
		TimeOnSite:      toModelVisitDuration(input.TimeOnSite),
		CarTravelTime:   toModelVisitDuration(input.CarTravelTime),
		RoadCondition:   input.RoadCondition,
		FeeItems:        toAppFeeDetailInputs(input.FeeItems),
		AccessOptions:   toModelAccessOptions(input.AccessOptions),
		PracticalNotes:  toModelPracticalNotes(input.PracticalNotes),
		RecommendedItems: toModelRecommendedItems(
			input.RecommendedItems,
		),
	}
}

func toModelOpeningHours(in *dto.OpeningHoursRequest) *model.PlaceOpeningHours {
	if in == nil {
		return nil
	}
	return &model.PlaceOpeningHours{
		Is24Hours: in.Is24Hours,
		Days:      in.Days,
		Seasonal:  model.LocalizedText(in.Seasonal),
		Summary:   model.LocalizedText(in.Summary),
	}
}

func toModelSeason(in *dto.SeasonRequest) *model.PlaceSeason {
	if in == nil {
		return nil
	}
	return &model.PlaceSeason{Months: in.Months, Note: model.LocalizedText(in.Note)}
}

func toModelVisitDuration(in *dto.VisitDurationRequest) *model.PlaceVisitDuration {
	if in == nil {
		return nil
	}
	return &model.PlaceVisitDuration{
		MinMinutes: in.MinMinutes,
		MaxMinutes: in.MaxMinutes,
		Note:       model.LocalizedText(in.Note),
	}
}

func toModelAccessOptions(in []dto.AccessOptionRequest) []model.PlaceAccessOption {
	if len(in) == 0 {
		return nil
	}
	result := make([]model.PlaceAccessOption, 0, len(in))
	for _, item := range in {
		result = append(result, model.PlaceAccessOption{
			TransportType:      item.TransportType,
			DurationMinMinutes: item.DurationMinMinutes,
			DurationMaxMinutes: item.DurationMaxMinutes,
			DistanceKm:         item.DistanceKm,
			RouteHint:          model.LocalizedText(item.RouteHint),
			RoadCondition:      item.RoadCondition,
			Requires4x4:        item.Requires4x4,
			ParkingNote:        model.LocalizedText(item.ParkingNote),
			LastSegmentNote:    model.LocalizedText(item.LastSegmentNote),
			Note:               model.LocalizedText(item.Note),
			SortOrder:          item.SortOrder,
		})
	}
	return result
}

func toModelPracticalNotes(in []dto.PracticalNoteRequest) []model.PlacePracticalNote {
	if len(in) == 0 {
		return nil
	}
	result := make([]model.PlacePracticalNote, 0, len(in))
	for _, item := range in {
		result = append(result, model.PlacePracticalNote{
			NoteType:  item.NoteType,
			Title:     model.LocalizedText(item.Title),
			Body:      model.LocalizedText(item.Body),
			Priority:  item.Priority,
			SortOrder: item.SortOrder,
		})
	}
	return result
}

func toModelRecommendedItems(in []dto.RecommendedItemRequest) []model.PlaceRecommendedItem {
	if len(in) == 0 {
		return nil
	}
	result := make([]model.PlaceRecommendedItem, 0, len(in))
	for _, item := range in {
		result = append(result, model.PlaceRecommendedItem{
			ItemType:   item.ItemType,
			Title:      model.LocalizedText(item.Title),
			Note:       model.LocalizedText(item.Note),
			Importance: item.Importance,
			Season:     item.Season,
			SortOrder:  item.SortOrder,
		})
	}
	return result
}

func toModelLocalizedList(in []map[string]string) []model.LocalizedText {
	if len(in) == 0 {
		return nil
	}
	result := make([]model.LocalizedText, 0, len(in))
	for _, item := range in {
		result = append(result, model.LocalizedText(item))
	}
	return result
}

func toModelLinks(in []dto.LinkDTO) []model.PlaceLink {
	if len(in) == 0 {
		return nil
	}
	result := make([]model.PlaceLink, 0, len(in))
	for _, item := range in {
		result = append(result, model.PlaceLink{Kind: item.Kind, URL: item.URL})
	}
	return result
}

func toCityLinkResponses(input []model.PlaceCityLink) []dto.PlaceCityLinkResponse {
	if len(input) == 0 {
		return nil
	}
	result := make([]dto.PlaceCityLinkResponse, 0, len(input))
	for _, item := range input {
		result = append(result, dto.PlaceCityLinkResponse{
			CountryCode: item.CountryCode,
			CityID:      item.CityID,
		})
	}
	return result
}

func toTranslationResponses(input map[string]model.PlaceTranslation) map[string]dto.PlaceTranslationResponse {
	if len(input) == 0 {
		return nil
	}
	result := make(map[string]dto.PlaceTranslationResponse, len(input))
	for locale, translation := range input {
		result[locale] = dto.PlaceTranslationResponse{
			Title:       translation.Title,
			Description: translation.Description,
		}
	}
	return result
}

func toVisitInfoResponse(input model.PlaceVisitInfo, locale string, defaultLocale string) dto.PlaceVisitInfoResponse {
	nearbyIDs := make([]string, 0, len(input.NearbyIDs))
	for _, id := range input.NearbyIDs {
		nearbyIDs = append(nearbyIDs, id.String())
	}
	return dto.PlaceVisitInfoResponse{
		BestTime:        input.BestTime,
		Accessibility:   input.Accessibility,
		BookingRequired: input.BookingRequired,
		OpeningHours:    toOpeningHoursResponse(input.OpeningHours, locale, defaultLocale),
		Amenities:       input.Amenities,
		Audience:        input.Audience,
		SafetyNotes:     input.SafetyNotes,
		NearbyIDs:       nearbyIDs,
		LocalizedTips:   input.LocalizedTips,
		Season:          toSeasonResponse(input.Season, locale, defaultLocale),
		GettingThere:    localizedFeeDetailText(input.GettingThere, locale, defaultLocale),
		Included:        localizedTextList(input.Included, locale, defaultLocale),
		Excluded:        localizedTextList(input.Excluded, locale, defaultLocale),
		Links:           toLinkResponses(input.Links),
		FeeDetails:      toFeeDetailResponses(input.FeeDetails, locale, defaultLocale),
		PriceNote:       localizedFeeDetailText(input.PriceNote, locale, defaultLocale),
		TimeOnSite:      toVisitDurationResponse(input.TimeOnSite, locale, defaultLocale),
		CarTravelTime:   toVisitDurationResponse(input.CarTravelTime, locale, defaultLocale),
		RoadCondition:   input.RoadCondition,
		FeeItems:        toFeeItemResponses(input.FeeItems, locale, defaultLocale),
		AccessOptions:   toAccessOptionResponses(input.AccessOptions, locale, defaultLocale),
		PracticalNotes:  toPracticalNoteResponses(input.PracticalNotes, locale, defaultLocale),
		RecommendedItems: toRecommendedItemResponses(
			input.RecommendedItems,
			locale,
			defaultLocale,
		),
	}
}

func toVisitInfoLocalizedResponse(input model.PlaceVisitInfo) *dto.PlaceVisitInfoLocalizedResponse {
	return &dto.PlaceVisitInfoLocalizedResponse{
		OpeningHours:     localizedOpeningHoursSummary(input.OpeningHours),
		PriceNote:        copyLocalizedTextMap(input.PriceNote),
		TimeOnSite:       toVisitDurationLocalizedResponse(input.TimeOnSite),
		CarTravelTime:    toVisitDurationLocalizedResponse(input.CarTravelTime),
		FeeDetails:       toFeeDetailLocalizedResponses(input.FeeDetails),
		FeeItems:         toFeeItemLocalizedResponses(input.FeeItems),
		AccessOptions:    toAccessOptionLocalizedResponses(input.AccessOptions),
		PracticalNotes:   toPracticalNoteLocalizedResponses(input.PracticalNotes),
		RecommendedItems: toRecommendedItemLocalizedResponses(input.RecommendedItems),
	}
}

func toOpeningHoursResponse(in *model.PlaceOpeningHours, locale, defaultLocale string) *dto.OpeningHoursResponse {
	if in == nil {
		return nil
	}
	return &dto.OpeningHoursResponse{
		Is24Hours: in.Is24Hours,
		Days:      in.Days,
		Seasonal:  localizedFeeDetailText(in.Seasonal, locale, defaultLocale),
		Summary:   localizedFeeDetailText(in.Summary, locale, defaultLocale),
	}
}

func localizedOpeningHoursSummary(in *model.PlaceOpeningHours) map[string]string {
	if in == nil {
		return nil
	}
	if summary := copyLocalizedTextMap(in.Summary); len(summary) > 0 {
		return summary
	}
	return copyLocalizedTextMap(in.Seasonal)
}

func toSeasonResponse(in *model.PlaceSeason, locale, defaultLocale string) *dto.SeasonResponse {
	if in == nil {
		return nil
	}
	return &dto.SeasonResponse{
		Months: in.Months,
		Note:   localizedFeeDetailText(in.Note, locale, defaultLocale),
	}
}

func toVisitDurationResponse(in *model.PlaceVisitDuration, locale, defaultLocale string) *dto.VisitDurationResponse {
	if in == nil {
		return nil
	}
	return &dto.VisitDurationResponse{
		MinMinutes: in.MinMinutes,
		MaxMinutes: in.MaxMinutes,
		Note:       localizedFeeDetailText(in.Note, locale, defaultLocale),
	}
}

func toVisitDurationLocalizedResponse(in *model.PlaceVisitDuration) *dto.VisitDurationLocalizedResponse {
	if in == nil {
		return nil
	}
	return &dto.VisitDurationLocalizedResponse{
		MinMinutes: in.MinMinutes,
		MaxMinutes: in.MaxMinutes,
		Note:       copyLocalizedTextMap(in.Note),
	}
}

func toFeeDetailLocalizedResponses(in []model.PlaceFeeDetail) []dto.FeeDetailLocalizedResponse {
	if len(in) == 0 {
		return nil
	}
	result := make([]dto.FeeDetailLocalizedResponse, 0, len(in))
	for _, item := range in {
		result = append(result, dto.FeeDetailLocalizedResponse{
			Title:         copyLocalizedTextMap(item.Title),
			Description:   copyLocalizedTextMap(item.Description),
			Amount:        item.Amount,
			Currency:      item.Currency,
			Unit:          item.Unit,
			IsApproximate: item.IsApproximate,
			SortOrder:     item.SortOrder,
		})
	}
	return result
}

func toFeeItemLocalizedResponses(in []model.PlaceFeeItem) []dto.FeeDetailLocalizedResponse {
	if len(in) == 0 {
		return nil
	}
	result := make([]dto.FeeDetailLocalizedResponse, 0, len(in))
	for _, item := range in {
		result = append(result, dto.FeeDetailLocalizedResponse{
			Title:         copyLocalizedTextMap(item.Title),
			Description:   copyLocalizedTextMap(item.Description),
			Amount:        item.Amount,
			Type:          item.Type,
			MinAmount:     item.MinAmount,
			MaxAmount:     item.MaxAmount,
			Currency:      item.Currency,
			Unit:          item.Unit,
			Required:      item.Required,
			IsApproximate: item.IsApproximate,
			Note:          copyLocalizedTextMap(item.Note),
			SortOrder:     item.SortOrder,
		})
	}
	return result
}

func toAccessOptionLocalizedResponses(in []model.PlaceAccessOption) []dto.AccessOptionLocalizedResponse {
	if len(in) == 0 {
		return nil
	}
	result := make([]dto.AccessOptionLocalizedResponse, 0, len(in))
	for _, item := range in {
		result = append(result, dto.AccessOptionLocalizedResponse{
			TransportType:      item.TransportType,
			DurationMinMinutes: item.DurationMinMinutes,
			DurationMaxMinutes: item.DurationMaxMinutes,
			DistanceKm:         item.DistanceKm,
			RouteHint:          copyLocalizedTextMap(item.RouteHint),
			RoadCondition:      item.RoadCondition,
			Requires4x4:        item.Requires4x4,
			ParkingNote:        copyLocalizedTextMap(item.ParkingNote),
			LastSegmentNote:    copyLocalizedTextMap(item.LastSegmentNote),
			Note:               copyLocalizedTextMap(item.Note),
			SortOrder:          item.SortOrder,
		})
	}
	return result
}

func toPracticalNoteLocalizedResponses(in []model.PlacePracticalNote) []dto.PracticalNoteLocalizedResponse {
	if len(in) == 0 {
		return nil
	}
	result := make([]dto.PracticalNoteLocalizedResponse, 0, len(in))
	for _, item := range in {
		result = append(result, dto.PracticalNoteLocalizedResponse{
			NoteType:  item.NoteType,
			Title:     copyLocalizedTextMap(item.Title),
			Body:      copyLocalizedTextMap(item.Body),
			Priority:  item.Priority,
			SortOrder: item.SortOrder,
		})
	}
	return result
}

func toRecommendedItemLocalizedResponses(in []model.PlaceRecommendedItem) []dto.RecommendedItemLocalizedResponse {
	if len(in) == 0 {
		return nil
	}
	result := make([]dto.RecommendedItemLocalizedResponse, 0, len(in))
	for _, item := range in {
		result = append(result, dto.RecommendedItemLocalizedResponse{
			ItemType:   item.ItemType,
			Title:      copyLocalizedTextMap(item.Title),
			Note:       copyLocalizedTextMap(item.Note),
			Importance: item.Importance,
			Season:     item.Season,
			SortOrder:  item.SortOrder,
		})
	}
	return result
}

func copyLocalizedTextMap(values model.LocalizedText) map[string]string {
	if len(values) == 0 {
		return nil
	}
	out := make(map[string]string, len(values))
	for locale, value := range values {
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		out[app.NormalizePlaceLocale(locale)] = value
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

func localizedTextList(in []model.LocalizedText, locale, defaultLocale string) []string {
	if len(in) == 0 {
		return nil
	}
	result := make([]string, 0, len(in))
	for _, item := range in {
		text := localizedFeeDetailText(item, locale, defaultLocale)
		if strings.TrimSpace(text) == "" {
			continue
		}
		result = append(result, text)
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

func toLinkResponses(in []model.PlaceLink) []dto.LinkDTO {
	if len(in) == 0 {
		return nil
	}
	result := make([]dto.LinkDTO, 0, len(in))
	for _, item := range in {
		result = append(result, dto.LinkDTO{Kind: item.Kind, URL: item.URL})
	}
	return result
}

func toAppFeeDetailInputs(input []dto.FeeDetailRequest) []app.PlaceFeeDetailInput {
	if len(input) == 0 {
		return nil
	}
	result := make([]app.PlaceFeeDetailInput, 0, len(input))
	for _, item := range input {
		result = append(result, app.PlaceFeeDetailInput{
			Title:         item.Title,
			Description:   item.Description,
			Amount:        item.Amount,
			Type:          item.Type,
			MinAmount:     item.MinAmount,
			MaxAmount:     item.MaxAmount,
			Currency:      item.Currency,
			Unit:          item.Unit,
			Required:      item.Required,
			IsApproximate: item.IsApproximate,
			Note:          item.Note,
			SortOrder:     item.SortOrder,
		})
	}
	return result
}

func toFeeDetailResponses(input []model.PlaceFeeDetail, locale string, defaultLocale string) []dto.FeeDetailResponse {
	if len(input) == 0 {
		return nil
	}
	result := make([]dto.FeeDetailResponse, 0, len(input))
	for _, item := range input {
		title := localizedFeeDetailText(item.Title, locale, defaultLocale)
		description := localizedFeeDetailText(item.Description, locale, defaultLocale)
		if strings.TrimSpace(title) == "" && strings.TrimSpace(description) == "" {
			continue
		}
		result = append(result, dto.FeeDetailResponse{
			Title:         title,
			Description:   description,
			Amount:        item.Amount,
			Currency:      item.Currency,
			Unit:          item.Unit,
			IsApproximate: item.IsApproximate,
			SortOrder:     item.SortOrder,
		})
	}
	return result
}

func toFeeItemResponses(input []model.PlaceFeeItem, locale string, defaultLocale string) []dto.FeeDetailResponse {
	if len(input) == 0 {
		return nil
	}
	result := make([]dto.FeeDetailResponse, 0, len(input))
	for _, item := range input {
		title := localizedFeeDetailText(item.Title, locale, defaultLocale)
		description := localizedFeeDetailText(item.Description, locale, defaultLocale)
		note := localizedFeeDetailText(item.Note, locale, defaultLocale)
		if strings.TrimSpace(title) == "" &&
			strings.TrimSpace(description) == "" &&
			strings.TrimSpace(note) == "" &&
			item.Amount == nil &&
			item.MinAmount == nil &&
			item.MaxAmount == nil {
			continue
		}
		result = append(result, dto.FeeDetailResponse{
			Title:         title,
			Description:   description,
			Amount:        item.Amount,
			Type:          item.Type,
			MinAmount:     item.MinAmount,
			MaxAmount:     item.MaxAmount,
			Currency:      item.Currency,
			Unit:          item.Unit,
			Required:      item.Required,
			IsApproximate: item.IsApproximate,
			Note:          note,
			SortOrder:     item.SortOrder,
		})
	}
	return result
}

func toAccessOptionResponses(input []model.PlaceAccessOption, locale string, defaultLocale string) []dto.AccessOptionResponse {
	if len(input) == 0 {
		return nil
	}
	result := make([]dto.AccessOptionResponse, 0, len(input))
	for _, item := range input {
		resp := dto.AccessOptionResponse{
			TransportType:      item.TransportType,
			DurationMinMinutes: item.DurationMinMinutes,
			DurationMaxMinutes: item.DurationMaxMinutes,
			DistanceKm:         item.DistanceKm,
			RouteHint:          localizedFeeDetailText(item.RouteHint, locale, defaultLocale),
			RoadCondition:      item.RoadCondition,
			Requires4x4:        item.Requires4x4,
			ParkingNote:        localizedFeeDetailText(item.ParkingNote, locale, defaultLocale),
			LastSegmentNote:    localizedFeeDetailText(item.LastSegmentNote, locale, defaultLocale),
			Note:               localizedFeeDetailText(item.Note, locale, defaultLocale),
			SortOrder:          item.SortOrder,
		}
		if resp.TransportType == "" &&
			resp.DurationMinMinutes == nil &&
			resp.DurationMaxMinutes == nil &&
			resp.DistanceKm == nil &&
			resp.RouteHint == "" &&
			resp.RoadCondition == "" &&
			!resp.Requires4x4 &&
			resp.ParkingNote == "" &&
			resp.LastSegmentNote == "" &&
			resp.Note == "" {
			continue
		}
		result = append(result, resp)
	}
	return result
}

func toPracticalNoteResponses(input []model.PlacePracticalNote, locale string, defaultLocale string) []dto.PracticalNoteResponse {
	if len(input) == 0 {
		return nil
	}
	result := make([]dto.PracticalNoteResponse, 0, len(input))
	for _, item := range input {
		resp := dto.PracticalNoteResponse{
			NoteType:  item.NoteType,
			Title:     localizedFeeDetailText(item.Title, locale, defaultLocale),
			Body:      localizedFeeDetailText(item.Body, locale, defaultLocale),
			Priority:  item.Priority,
			SortOrder: item.SortOrder,
		}
		if resp.NoteType == "" && resp.Title == "" && resp.Body == "" {
			continue
		}
		result = append(result, resp)
	}
	return result
}

func toRecommendedItemResponses(input []model.PlaceRecommendedItem, locale string, defaultLocale string) []dto.RecommendedItemResponse {
	if len(input) == 0 {
		return nil
	}
	result := make([]dto.RecommendedItemResponse, 0, len(input))
	for _, item := range input {
		resp := dto.RecommendedItemResponse{
			ItemType:   item.ItemType,
			Title:      localizedFeeDetailText(item.Title, locale, defaultLocale),
			Note:       localizedFeeDetailText(item.Note, locale, defaultLocale),
			Importance: item.Importance,
			Season:     item.Season,
			SortOrder:  item.SortOrder,
		}
		if resp.ItemType == "" && resp.Title == "" && resp.Note == "" {
			continue
		}
		result = append(result, resp)
	}
	return result
}

func localizedFeeDetailText(values map[string]string, locale string, defaultLocale string) string {
	if len(values) == 0 {
		return ""
	}
	candidates := []string{
		app.NormalizePlaceLocale(locale),
		app.NormalizePlaceLocale(defaultLocale),
		"en",
		"ru",
		"kk",
	}
	seen := make(map[string]struct{}, len(candidates))
	for _, candidate := range candidates {
		if candidate == "" {
			continue
		}
		if _, ok := seen[candidate]; ok {
			continue
		}
		seen[candidate] = struct{}{}
		if text := strings.TrimSpace(values[candidate]); text != "" {
			return text
		}
	}
	for _, text := range values {
		if text = strings.TrimSpace(text); text != "" {
			return text
		}
	}
	return ""
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
	writeJSON(w, status, buildErrorResponse("place", status, message))
}

type errorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    string `json:"code"`
	Kind    string `json:"kind"`
}

func buildErrorResponse(service string, status int, message string) errorResponse {
	if status >= http.StatusInternalServerError {
		return errorResponse{
			Error:   "Техническая ошибка",
			Message: "На сервере возникла проблема. Попробуйте позже.",
			Code:    service + ".technical",
			Kind:    "technical",
		}
	}
	title, publicMessage := localizedBusinessError(status)
	return errorResponse{
		Error:   title,
		Message: publicMessage,
		Code:    service + "." + errorCodeFromMessage(message),
		Kind:    "business",
	}
}

func localizedBusinessError(status int) (string, string) {
	switch status {
	case http.StatusUnauthorized:
		return "Требуется авторизация", "Войдите в аккаунт и повторите запрос."
	case http.StatusForbidden:
		return "Недостаточно прав", "У вас нет доступа к этому действию."
	case http.StatusNotFound:
		return "Данные не найдены", "Запрошенные данные не найдены."
	case http.StatusConflict:
		return "Конфликт данных", "Данные уже изменились или действие недоступно в текущем состоянии."
	case http.StatusTooManyRequests:
		return "Слишком много запросов", "Попробуйте повторить запрос чуть позже."
	default:
		return "Некорректный запрос", "Проверьте данные запроса и попробуйте снова."
	}
}

func errorCodeFromMessage(message string) string {
	message = strings.ToLower(strings.TrimSpace(message))
	var builder strings.Builder
	previousUnderscore := false
	for _, r := range message {
		isAlphaNumeric := (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9')
		if isAlphaNumeric {
			builder.WriteRune(r)
			previousUnderscore = false
			continue
		}
		if !previousUnderscore && builder.Len() > 0 {
			builder.WriteByte('_')
			previousUnderscore = true
		}
	}
	code := strings.Trim(builder.String(), "_")
	if code == "" {
		return "business_error"
	}
	return code
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
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
