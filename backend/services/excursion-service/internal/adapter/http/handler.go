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

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/transport/dto"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
)

type Handler struct {
	useCase     *app.ExcursionUseCase
	fileManager port.ExcursionCoverFileManager
}

func NewHandler(useCase *app.ExcursionUseCase, fileManager port.ExcursionCoverFileManager) *Handler {
	return &Handler{useCase: useCase, fileManager: fileManager}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /v1/excursion-products", h.ListExcursionProducts)
	mux.HandleFunc("GET /v1/excursion-products/{id}", h.GetExcursionProduct)
	mux.HandleFunc("GET /v1/excursion-products/{id}/offers", h.ListExcursionProductOffers)
	mux.HandleFunc("GET /v1/excursion-products/{id}/cover", h.GetExcursionProductCover)

	mux.HandleFunc("GET /v1/excursions", h.ListExcursions)
	mux.HandleFunc("GET /v1/excursions/{id}", h.GetExcursion)
	mux.HandleFunc("GET /v1/excursions/{id}/cover", h.GetExcursionCover)
	mux.HandleFunc("GET /v1/guides/excursion-languages", h.ListGuideExcursionLanguages)

	mux.HandleFunc("POST /v1/me/excursions", h.CreateExcursion)
	mux.HandleFunc("GET /v1/me/excursions", h.ListMyExcursions)
	mux.HandleFunc("GET /v1/me/excursions/{id}", h.GetMyExcursion)
	mux.HandleFunc("PUT /v1/me/excursions/{id}", h.UpdateExcursion)
	mux.HandleFunc("DELETE /v1/me/excursions/{id}", h.DeleteExcursion)
	mux.HandleFunc("POST /v1/me/excursions/{id}/publish", h.PublishExcursion)
	mux.HandleFunc("POST /v1/me/excursion-bookings", h.CreateExcursionBooking)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) CreateExcursion(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	var req dto.CreateExcursionRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	input, err := toCreateInput(actorUserID, req)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	aggregate, err := h.useCase.CreateExcursion(r.Context(), input)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to create excursion")
		return
	}
	writeJSON(w, http.StatusCreated, toExcursionResponse(aggregate))
}

func (h *Handler) UpdateExcursion(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	excursionID, ok := parsePathUUID(w, r, "id", "invalid excursion id")
	if !ok {
		return
	}
	var req dto.UpdateExcursionRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	input, err := toUpdateInput(actorUserID, excursionID, req)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	aggregate, err := h.useCase.UpdateExcursion(r.Context(), input)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to update excursion")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionResponse(aggregate))
}

func (h *Handler) PublishExcursion(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	excursionID, ok := parsePathUUID(w, r, "id", "invalid excursion id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.PublishExcursion(r.Context(), excursionID, actorUserID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to publish excursion")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionResponse(aggregate))
}

func (h *Handler) DeleteExcursion(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	excursionID, ok := parsePathUUID(w, r, "id", "invalid excursion id")
	if !ok {
		return
	}
	if err := h.useCase.DeleteExcursion(r.Context(), excursionID, actorUserID); err != nil {
		h.writeUseCaseError(w, r, err, "failed to delete excursion")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetExcursion(w http.ResponseWriter, r *http.Request) {
	excursionID, ok := parsePathUUID(w, r, "id", "invalid excursion id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.GetPublicExcursion(r.Context(), excursionID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to get excursion")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionResponse(aggregate))
}

func (h *Handler) GetMyExcursion(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	excursionID, ok := parsePathUUID(w, r, "id", "invalid excursion id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.GetMyExcursion(r.Context(), excursionID, actorUserID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to get excursion")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionResponse(aggregate))
}

func (h *Handler) ListExcursions(w http.ResponseWriter, r *http.Request) {
	requestedLimit := clampLimit(parseIntOrDefault(r.URL.Query().Get("limit"), 20))
	filter, ok := parseExcursionFilter(w, r, requestedLimit+1)
	if !ok {
		return
	}
	aggregates, err := h.useCase.ListExcursions(r.Context(), filter)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list excursions")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionListResponse(aggregates, requestedLimit))
}

func (h *Handler) ListExcursionProducts(w http.ResponseWriter, r *http.Request) {
	requestedLimit := clampLimit(parseIntOrDefault(r.URL.Query().Get("limit"), 20))
	filter := parseExcursionProductFilter(r, requestedLimit+1)
	aggregates, err := h.useCase.ListExcursionProducts(r.Context(), filter)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list excursion products")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionProductListResponse(aggregates, requestedLimit))
}

func (h *Handler) GetExcursionProduct(w http.ResponseWriter, r *http.Request) {
	productID, ok := parsePathUUID(w, r, "id", "invalid excursion product id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.GetExcursionProduct(r.Context(), productID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to get excursion product")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionProductCardResponse(aggregate))
}

func (h *Handler) ListExcursionProductOffers(w http.ResponseWriter, r *http.Request) {
	productID, ok := parsePathUUID(w, r, "id", "invalid excursion product id")
	if !ok {
		return
	}
	requestedLimit := clampLimit(parseIntOrDefault(r.URL.Query().Get("limit"), 20))
	filter := parseExcursionOfferFilter(r, productID, requestedLimit+1)
	aggregates, err := h.useCase.ListExcursionProductOffers(r.Context(), filter)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list excursion offers")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionOfferListResponse(aggregates, requestedLimit))
}

func (h *Handler) ListGuideExcursionLanguages(w http.ResponseWriter, r *http.Request) {
	guideUserIDs, ok := parseGuideUserIDs(w, r.URL.Query().Get("guideUserIds"))
	if !ok {
		return
	}
	languages, err := h.useCase.ListGuideExcursionLanguageCodes(r.Context(), guideUserIDs)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list guide excursion languages")
		return
	}
	writeJSON(w, http.StatusOK, toGuideExcursionLanguageListResponse(guideUserIDs, languages))
}

func (h *Handler) ListMyExcursions(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	requestedLimit := clampLimit(parseIntOrDefault(r.URL.Query().Get("limit"), 20))
	statuses := splitCSV(r.URL.Query().Get("status"))
	aggregates, err := h.useCase.ListMyExcursions(
		r.Context(),
		actorUserID,
		requestedLimit+1,
		parseIntOrDefault(r.URL.Query().Get("offset"), 0),
		statuses,
	)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list my excursions")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionListResponse(aggregates, requestedLimit))
}

func (h *Handler) CreateExcursionBooking(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	var req dto.CreateExcursionBookingRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	input, err := toCreateExcursionBookingInput(actorUserID, req)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	booking, err := h.useCase.CreateExcursionBooking(r.Context(), input)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to create excursion booking")
		return
	}
	writeJSON(w, http.StatusCreated, toExcursionBookingResponse(booking))
}

func (h *Handler) GetExcursionCover(w http.ResponseWriter, r *http.Request) {
	excursionID, ok := parsePathUUID(w, r, "id", "invalid excursion id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.GetPublicExcursion(r.Context(), excursionID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to get excursion")
		return
	}
	if aggregate.CoverFileID == nil {
		writeError(w, http.StatusNotFound, "excursion cover not found")
		return
	}
	if h.fileManager == nil {
		writeError(w, http.StatusServiceUnavailable, "file manager unavailable")
		return
	}
	h.writeCoverImage(w, r, *aggregate.CoverFileID)
}

func (h *Handler) GetExcursionProductCover(w http.ResponseWriter, r *http.Request) {
	productID, ok := parsePathUUID(w, r, "id", "invalid excursion product id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.GetExcursionProduct(r.Context(), productID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to get excursion product")
		return
	}
	if aggregate.Product.CoverFileID == nil {
		writeError(w, http.StatusNotFound, "excursion product cover not found")
		return
	}
	if h.fileManager == nil {
		writeError(w, http.StatusServiceUnavailable, "file manager unavailable")
		return
	}
	h.writeCoverImage(w, r, *aggregate.Product.CoverFileID)
}

func (h *Handler) writeCoverImage(w http.ResponseWriter, r *http.Request, fileID uuid.UUID) {
	downloadURL, err := h.fileManager.CreateDownloadURL(r.Context(), fileID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to resolve excursion cover")
		return
	}
	proxyReq, err := http.NewRequestWithContext(r.Context(), http.MethodGet, downloadURL, nil)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build cover request")
		return
	}
	resp, err := http.DefaultClient.Do(proxyReq)
	if err != nil {
		writeError(w, http.StatusBadGateway, "failed to fetch excursion cover")
		return
	}
	defer resp.Body.Close()
	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		writeError(w, http.StatusBadGateway, "failed to fetch excursion cover")
		return
	}
	if contentType := strings.TrimSpace(resp.Header.Get("Content-Type")); contentType != "" {
		w.Header().Set("Content-Type", contentType)
	}
	w.Header().Set("Cache-Control", "public, max-age=300")
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, resp.Body)
}

func parseExcursionProductFilter(r *http.Request, limit int) port.ExcursionProductFilter {
	query := r.URL.Query()
	return port.ExcursionProductFilter{
		CategorySlug:    optionalString(query.Get("categorySlug")),
		CountryCode:     optionalString(query.Get("countryCode")),
		CityName:        optionalString(query.Get("cityName")),
		LanguageCode:    optionalString(query.Get("languageCode")),
		SearchQuery:     optionalString(query.Get("q")),
		PriceMin:        optionalFloat(query.Get("priceMin")),
		PriceMax:        optionalFloat(query.Get("priceMax")),
		DurationMin:     optionalInt(query.Get("durationMin")),
		DurationMax:     optionalInt(query.Get("durationMax")),
		MaxGroupSizeMin: optionalInt(query.Get("maxGroupSizeMin")),
		Limit:           limit,
		Offset:          parseIntOrDefault(query.Get("offset"), 0),
	}
}

func parseExcursionOfferFilter(r *http.Request, productID uuid.UUID, limit int) port.ExcursionOfferFilter {
	query := r.URL.Query()
	return port.ExcursionOfferFilter{
		ProductID:            productID,
		LanguageCode:         optionalString(query.Get("languageCode")),
		SearchQuery:          optionalString(query.Get("q")),
		PriceMin:             optionalFloat(query.Get("priceMin")),
		PriceMax:             optionalFloat(query.Get("priceMax")),
		MaxGroupSizeMin:      optionalInt(query.Get("maxGroupSizeMin")),
		PreferredGuideUserID: optionalUUID(query.Get("preferredGuideUserId")),
		Sort:                 strings.TrimSpace(query.Get("sort")),
		SortDirection:        strings.TrimSpace(query.Get("sortDirection")),
		Limit:                limit,
		Offset:               parseIntOrDefault(query.Get("offset"), 0),
	}
}

func parseExcursionFilter(w http.ResponseWriter, r *http.Request, limit int) (port.ExcursionFilter, bool) {
	query := r.URL.Query()
	filter := port.ExcursionFilter{
		Limit:  limit,
		Offset: parseIntOrDefault(query.Get("offset"), 0),
	}
	publicVisibility := string(enum.ExcursionVisibilityPublic)
	filter.Visibility = &publicVisibility
	if raw := strings.TrimSpace(query.Get("visibility")); raw != "" {
		switch enum.ExcursionVisibility(raw) {
		case enum.ExcursionVisibilityPublic, enum.ExcursionVisibilityUnlisted:
			filter.Visibility = &raw
		default:
			writeError(w, http.StatusBadRequest, "invalid visibility")
			return port.ExcursionFilter{}, false
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

func toCreateInput(actorUserID uuid.UUID, req dto.CreateExcursionRequest) (app.CreateExcursionInput, error) {
	landmarkID, err := parseOptionalUUIDString(req.LandmarkID)
	if err != nil {
		return app.CreateExcursionInput{}, fmt.Errorf("invalid landmarkId")
	}
	coverFileID, err := parseOptionalUUIDString(req.CoverFileID)
	if err != nil {
		return app.CreateExcursionInput{}, fmt.Errorf("invalid coverFileId")
	}
	productCoverFileID, err := parseOptionalUUIDString(req.ProductCoverFileID)
	if err != nil {
		return app.CreateExcursionInput{}, fmt.Errorf("invalid productCoverFileId")
	}
	return app.CreateExcursionInput{
		ActorUserID:         actorUserID,
		LandmarkID:          landmarkID,
		LandmarkName:        req.LandmarkName,
		CategorySlug:        req.CategorySlug,
		ProductTranslations: toModelTranslations(req.ProductTranslations),
		Visibility:          req.Visibility,
		DurationMinutes:     req.DurationMinutes,
		MaxGroupSize:        req.MaxGroupSize,
		LanguageCodes:       req.LanguageCodes,
		CountryCode:         req.CountryCode,
		CityName:            req.CityName,
		MeetingPoint:        req.MeetingPoint,
		Latitude:            req.Latitude,
		Longitude:           req.Longitude,
		MapURL:              req.MapURL,
		PriceAmount:         req.PriceAmount,
		Currency:            req.Currency,
		CoverFileID:         coverFileID,
		ProductCoverFileID:  productCoverFileID,
		IncludedItems:       toIncludedItemInputs(req.IncludedItems, req.IncludedItemTranslations),
		Itinerary:           toAppItinerary(req.Itinerary),
	}, nil
}

func toUpdateInput(actorUserID uuid.UUID, excursionID uuid.UUID, req dto.UpdateExcursionRequest) (app.UpdateExcursionInput, error) {
	createInput, err := toCreateInput(actorUserID, req)
	if err != nil {
		return app.UpdateExcursionInput{}, err
	}
	return app.UpdateExcursionInput{
		ActorUserID:         createInput.ActorUserID,
		ExcursionID:         excursionID,
		LandmarkID:          createInput.LandmarkID,
		LandmarkName:        createInput.LandmarkName,
		CategorySlug:        createInput.CategorySlug,
		ProductTranslations: createInput.ProductTranslations,
		Visibility:          createInput.Visibility,
		DurationMinutes:     createInput.DurationMinutes,
		MaxGroupSize:        createInput.MaxGroupSize,
		LanguageCodes:       createInput.LanguageCodes,
		CountryCode:         createInput.CountryCode,
		CityName:            createInput.CityName,
		MeetingPoint:        createInput.MeetingPoint,
		Latitude:            createInput.Latitude,
		Longitude:           createInput.Longitude,
		MapURL:              createInput.MapURL,
		PriceAmount:         createInput.PriceAmount,
		Currency:            createInput.Currency,
		CoverFileID:         createInput.CoverFileID,
		ProductCoverFileID:  createInput.ProductCoverFileID,
		IncludedItems:       createInput.IncludedItems,
		Itinerary:           createInput.Itinerary,
	}, nil
}

func toCreateExcursionBookingInput(actorUserID uuid.UUID, req dto.CreateExcursionBookingRequest) (app.CreateExcursionBookingInput, error) {
	productID, err := uuid.Parse(strings.TrimSpace(req.ProductID))
	if err != nil {
		return app.CreateExcursionBookingInput{}, fmt.Errorf("invalid productId")
	}
	offerID, err := uuid.Parse(strings.TrimSpace(req.OfferID))
	if err != nil {
		return app.CreateExcursionBookingInput{}, fmt.Errorf("invalid offerId")
	}
	scheduledFor, err := time.Parse(time.RFC3339, strings.TrimSpace(req.ScheduledFor))
	if err != nil {
		return app.CreateExcursionBookingInput{}, fmt.Errorf("invalid scheduledFor")
	}
	return app.CreateExcursionBookingInput{
		ActorUserID:    actorUserID,
		ProductID:      productID,
		OfferID:        offerID,
		ScheduledFor:   scheduledFor,
		Adults:         req.Adults,
		Children:       req.Children,
		IdempotencyKey: req.IdempotencyKey,
	}, nil
}

func toAppItinerary(items []dto.ExcursionItineraryItemRequest) []app.ExcursionItineraryItemInput {
	result := make([]app.ExcursionItineraryItemInput, 0, len(items))
	for _, item := range items {
		result = append(result, app.ExcursionItineraryItemInput{
			StartOffsetMinutes: item.StartOffsetMinutes,
			DurationMinutes:    item.DurationMinutes,
			Title:              item.Title,
			Description:        item.Description,
			Translations:       toModelItineraryTranslations(item.Translations),
		})
	}
	return result
}

func toIncludedItemInputs(items []string, translations map[string][]string) []app.ExcursionIncludedItemInput {
	if len(items) == 0 {
		return nil
	}
	result := make([]app.ExcursionIncludedItemInput, 0, len(items))
	for index, item := range items {
		itemTranslations := make(model.ExcursionLocalizedText)
		for locale, values := range translations {
			if index >= len(values) {
				continue
			}
			itemTranslations[locale] = values[index]
		}
		result = append(result, app.ExcursionIncludedItemInput{
			Text:         item,
			Translations: itemTranslations,
		})
	}
	return result
}

func toModelTranslations(items map[string]dto.ExcursionLocalizedCopy) model.ExcursionTranslations {
	if len(items) == 0 {
		return nil
	}
	result := make(model.ExcursionTranslations, len(items))
	for locale, item := range items {
		result[locale] = model.ExcursionLocalizedCopy{
			Title:       item.Title,
			Summary:     item.Summary,
			Description: item.Description,
		}
	}
	return model.NormalizeExcursionTranslations(result)
}

func toDTOTranslations(items model.ExcursionTranslations) map[string]dto.ExcursionLocalizedCopy {
	normalized := model.NormalizeExcursionTranslations(items)
	if len(normalized) == 0 {
		return nil
	}
	result := make(map[string]dto.ExcursionLocalizedCopy, len(normalized))
	for locale, item := range normalized {
		result[locale] = dto.ExcursionLocalizedCopy{
			Title:       item.Title,
			Summary:     item.Summary,
			Description: item.Description,
		}
	}
	return result
}

func toModelItineraryTranslations(items map[string]dto.ExcursionItineraryLocalizedCopy) model.ExcursionItineraryTranslations {
	if len(items) == 0 {
		return nil
	}
	result := make(model.ExcursionItineraryTranslations, len(items))
	for locale, item := range items {
		result[locale] = model.ExcursionItineraryLocalizedCopy{
			Title:       item.Title,
			Description: item.Description,
		}
	}
	return model.NormalizeExcursionItineraryTranslations(result)
}

func toDTOItineraryTranslations(items model.ExcursionItineraryTranslations) map[string]dto.ExcursionItineraryLocalizedCopy {
	normalized := model.NormalizeExcursionItineraryTranslations(items)
	if len(normalized) == 0 {
		return nil
	}
	result := make(map[string]dto.ExcursionItineraryLocalizedCopy, len(normalized))
	for locale, item := range normalized {
		result[locale] = dto.ExcursionItineraryLocalizedCopy{
			Title:       item.Title,
			Description: item.Description,
		}
	}
	return result
}

func includedItemTexts(items []model.ExcursionIncludedItem) []string {
	if len(items) == 0 {
		return nil
	}
	result := make([]string, 0, len(items))
	for _, item := range items {
		text := strings.TrimSpace(item.Text)
		if text == "" {
			continue
		}
		result = append(result, text)
	}
	return result
}

func includedItemTranslations(items []model.ExcursionIncludedItem) map[string][]string {
	if len(items) == 0 {
		return nil
	}
	localeValues := make(map[string][]string)
	for index, item := range items {
		for locale, text := range model.NormalizeExcursionLocalizedText(item.Translations) {
			if _, ok := localeValues[locale]; !ok {
				localeValues[locale] = make([]string, len(items))
			}
			localeValues[locale][index] = text
		}
	}
	for locale, values := range localeValues {
		nonEmpty := false
		for _, value := range values {
			if strings.TrimSpace(value) != "" {
				nonEmpty = true
				break
			}
		}
		if !nonEmpty {
			delete(localeValues, locale)
		}
	}
	if len(localeValues) == 0 {
		return nil
	}
	return localeValues
}

func toExcursionListResponse(items []*app.ExcursionAggregate, requestedLimit int) dto.ExcursionListResponse {
	hasMore := len(items) > requestedLimit
	if hasMore {
		items = items[:requestedLimit]
	}
	resp := dto.ExcursionListResponse{
		Items:   make([]dto.ExcursionResponse, 0, len(items)),
		HasMore: hasMore,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toExcursionResponse(item))
	}
	return resp
}

func toExcursionProductListResponse(items []*app.ExcursionProductCardAggregate, requestedLimit int) dto.ExcursionProductListResponse {
	hasMore := len(items) > requestedLimit
	if hasMore {
		items = items[:requestedLimit]
	}
	resp := dto.ExcursionProductListResponse{
		Items:   make([]dto.ExcursionProductCardResponse, 0, len(items)),
		HasMore: hasMore,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toExcursionProductCardResponse(item))
	}
	return resp
}

func toExcursionProductCardResponse(aggregate *app.ExcursionProductCardAggregate) dto.ExcursionProductCardResponse {
	item := aggregate.Product
	coverImageURL := (*string)(nil)
	if item.CoverFileID != nil {
		value := fmt.Sprintf("/api/v1/excursion-products/%s/cover", item.ID)
		coverImageURL = &value
	}
	return dto.ExcursionProductCardResponse{
		ID:                   item.ID.String(),
		LandmarkID:           formatOptionalUUID(item.LandmarkID),
		LandmarkName:         item.LandmarkName,
		Title:                item.Title,
		Summary:              item.Summary,
		Description:          item.Description,
		Translations:         toDTOTranslations(item.Translations),
		CategorySlug:         item.CategorySlug,
		Status:               string(item.Status),
		Visibility:           string(item.Visibility),
		DurationMinutes:      item.DurationMinutes,
		CountryCode:          item.CountryCode,
		CityName:             item.CityName,
		Latitude:             item.Latitude,
		Longitude:            item.Longitude,
		MapURL:               item.MapURL,
		CoverFileID:          formatOptionalUUID(item.CoverFileID),
		CoverImageURL:        coverImageURL,
		MinPriceAmount:       item.MinPriceAmount,
		Currency:             item.Currency,
		OffersCount:          item.OffersCount,
		PublishedOffersCount: item.PublishedOffersCount,
		NextAvailableAt:      formatOptionalTime(item.NextAvailableAt),
		CreatedAt:            item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:            item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toExcursionOfferListResponse(items []*app.ExcursionOfferAggregate, requestedLimit int) dto.ExcursionOfferListResponse {
	hasMore := len(items) > requestedLimit
	if hasMore {
		items = items[:requestedLimit]
	}
	resp := dto.ExcursionOfferListResponse{
		Items:   make([]dto.ExcursionOfferResponse, 0, len(items)),
		HasMore: hasMore,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toExcursionOfferResponse(item))
	}
	return resp
}

func toExcursionOfferResponse(aggregate *app.ExcursionOfferAggregate) dto.ExcursionOfferResponse {
	item := aggregate.Offer
	return dto.ExcursionOfferResponse{
		ID:                       item.ID.String(),
		ProductID:                item.ProductID.String(),
		LegacyExcursionID:        formatOptionalUUID(item.LegacyExcursionID),
		GuideProfileID:           item.GuideProfileID.String(),
		GuideUserID:              item.GuideUserID.String(),
		GuideRatingAvg:           item.GuideRatingAvg,
		GuideReviewsCount:        item.GuideReviewsCount,
		GuideExperienceYears:     item.GuideExperienceYears,
		GuideDisplayName:         item.GuideDisplayName,
		Title:                    item.Title,
		Summary:                  item.Summary,
		Description:              item.Description,
		Translations:             toDTOTranslations(item.Translations),
		Status:                   string(item.Status),
		Visibility:               string(item.Visibility),
		DurationMinutes:          item.DurationMinutes,
		MaxGroupSize:             item.MaxGroupSize,
		MeetingPoint:             item.MeetingPoint,
		Latitude:                 item.Latitude,
		Longitude:                item.Longitude,
		MapURL:                   item.MapURL,
		PriceAmount:              item.PriceAmount,
		Currency:                 item.Currency,
		CoverFileID:              formatOptionalUUID(item.CoverFileID),
		LanguageCodes:            aggregate.LanguageCodes,
		IncludedItems:            includedItemTexts(aggregate.IncludedItems),
		IncludedItemTranslations: includedItemTranslations(aggregate.IncludedItems),
		Itinerary:                toItineraryResponse(aggregate.Itinerary),
		PublishedAt:              formatOptionalTime(item.PublishedAt),
		DeletedAt:                formatOptionalTime(item.DeletedAt),
		Revision:                 item.Revision,
		CreatedAt:                item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:                item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toGuideExcursionLanguageListResponse(guideUserIDs []uuid.UUID, languages map[uuid.UUID][]string) dto.GuideExcursionLanguageListResponse {
	resp := dto.GuideExcursionLanguageListResponse{
		Items: make([]dto.GuideExcursionLanguageResponse, 0, len(guideUserIDs)),
	}
	for _, guideUserID := range guideUserIDs {
		codes := languages[guideUserID]
		if len(codes) == 0 {
			continue
		}
		resp.Items = append(resp.Items, dto.GuideExcursionLanguageResponse{
			GuideUserID:   guideUserID.String(),
			LanguageCodes: append([]string(nil), codes...),
		})
	}
	return resp
}

func toExcursionResponse(aggregate *app.ExcursionAggregate) dto.ExcursionResponse {
	item := aggregate.Excursion
	coverImageURL := (*string)(nil)
	if aggregate.CoverFileID != nil {
		value := fmt.Sprintf("/api/v1/excursions/%s/cover", item.ID)
		coverImageURL = &value
	}
	return dto.ExcursionResponse{
		ID:                       item.ID.String(),
		GuideProfileID:           item.GuideProfileID.String(),
		GuideUserID:              item.GuideUserID.String(),
		LandmarkID:               formatOptionalUUID(item.LandmarkID),
		LandmarkName:             item.LandmarkName,
		Title:                    item.Title,
		Summary:                  item.Summary,
		Description:              item.Description,
		Translations:             toDTOTranslations(item.Translations),
		CategorySlug:             item.CategorySlug,
		Tags:                     aggregate.Tags,
		Status:                   string(item.Status),
		Visibility:               string(item.Visibility),
		DurationMinutes:          item.DurationMinutes,
		MaxGroupSize:             item.MaxGroupSize,
		LanguageCodes:            aggregate.LanguageCodes,
		CountryCode:              item.CountryCode,
		CityName:                 item.CityName,
		MeetingPoint:             item.MeetingPoint,
		Latitude:                 item.Latitude,
		Longitude:                item.Longitude,
		MapURL:                   item.MapURL,
		PriceAmount:              item.PriceAmount,
		Currency:                 item.Currency,
		CoverFileID:              formatOptionalUUID(aggregate.CoverFileID),
		CoverImageURL:            coverImageURL,
		IncludedItems:            includedItemTexts(aggregate.IncludedItems),
		IncludedItemTranslations: includedItemTranslations(aggregate.IncludedItems),
		Itinerary:                toItineraryResponse(aggregate.Itinerary),
		PublishedAt:              formatOptionalTime(item.PublishedAt),
		DeletedAt:                formatOptionalTime(item.DeletedAt),
		Revision:                 item.Revision,
		CreatedAt:                item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:                item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toExcursionBookingResponse(item *model.ExcursionBooking) dto.ExcursionBookingResponse {
	return dto.ExcursionBookingResponse{
		ID:                item.ID.String(),
		ProductID:         item.ProductID.String(),
		OfferID:           item.OfferID.String(),
		LegacyExcursionID: formatOptionalUUID(item.LegacyExcursionID),
		GuideProfileID:    item.GuideProfileID.String(),
		GuideUserID:       item.GuideUserID.String(),
		TouristUserID:     item.TouristUserID.String(),
		ScheduledFor:      item.ScheduledFor.UTC().Format(time.RFC3339),
		Adults:            item.Adults,
		Children:          item.Children,
		TotalSeats:        item.TotalSeats,
		UnitPriceAmount:   item.UnitPriceAmount,
		ServiceFeeAmount:  item.ServiceFeeAmount,
		TotalPriceAmount:  item.TotalPriceAmount,
		Currency:          item.Currency,
		Status:            string(item.Status),
		CreatedAt:         item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:         item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toItineraryResponse(items []*model.ExcursionItineraryItem) []dto.ExcursionItineraryItemResponse {
	result := make([]dto.ExcursionItineraryItemResponse, 0, len(items))
	for _, item := range items {
		result = append(result, dto.ExcursionItineraryItemResponse{
			ID:                 item.ID.String(),
			SortOrder:          item.SortOrder,
			StartOffsetMinutes: item.StartOffsetMinutes,
			DurationMinutes:    item.DurationMinutes,
			Title:              item.Title,
			Description:        item.Description,
			Translations:       toDTOItineraryTranslations(item.Translations),
			CreatedAt:          item.CreatedAt.UTC().Format(time.RFC3339),
			UpdatedAt:          item.UpdatedAt.UTC().Format(time.RFC3339),
		})
	}
	return result
}

func (h *Handler) writeUseCaseError(w http.ResponseWriter, r *http.Request, err error, fallback string) {
	switch {
	case errors.Is(err, app.ErrInvalidActorUserID):
		writeError(w, http.StatusUnauthorized, err.Error())
	case errors.Is(err, app.ErrExcursionAccessDenied),
		errors.Is(err, app.ErrGuideNotAllowed):
		writeError(w, http.StatusForbidden, err.Error())
	case errors.Is(err, app.ErrExcursionNotFound),
		errors.Is(err, app.ErrExcursionOfferNotFound),
		errors.Is(err, app.ErrExcursionCoverFileNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, model.ErrExcursionAlreadyArchived),
		errors.Is(err, model.ErrExcursionGuideLandmarkAlreadyExists):
		writeError(w, http.StatusConflict, err.Error())
	case errors.Is(err, app.ErrExcursionTranslationFailed):
		writeError(w, http.StatusServiceUnavailable, err.Error())
	case errors.Is(err, app.ErrInvalidExcursionID),
		errors.Is(err, app.ErrExcursionAttractionRequired),
		errors.Is(err, app.ErrInvalidExcursionIncludedItem),
		errors.Is(err, app.ErrExcursionCoverFileNotReady),
		errors.Is(err, app.ErrExcursionCoverFileNotAllowed),
		errors.Is(err, model.ErrInvalidExcursionID),
		errors.Is(err, model.ErrInvalidGuideProfileID),
		errors.Is(err, model.ErrInvalidGuideUserID),
		errors.Is(err, model.ErrInvalidExcursionTitle),
		errors.Is(err, model.ErrInvalidExcursionSummary),
		errors.Is(err, model.ErrInvalidExcursionDescription),
		errors.Is(err, model.ErrInvalidExcursionCategory),
		errors.Is(err, model.ErrInvalidExcursionStatus),
		errors.Is(err, model.ErrInvalidExcursionVisibility),
		errors.Is(err, model.ErrInvalidExcursionDuration),
		errors.Is(err, model.ErrInvalidExcursionGroupSize),
		errors.Is(err, model.ErrInvalidExcursionMeeting),
		errors.Is(err, model.ErrInvalidExcursionPrice),
		errors.Is(err, model.ErrInvalidExcursionCurrency),
		errors.Is(err, model.ErrExcursionLanguageRequired),
		errors.Is(err, model.ErrExcursionItineraryRequired),
		errors.Is(err, model.ErrInvalidExcursionItineraryID),
		errors.Is(err, model.ErrInvalidExcursionItineraryOffset),
		errors.Is(err, model.ErrInvalidExcursionItineraryTitle),
		errors.Is(err, model.ErrInvalidExcursionItineraryDescription),
		errors.Is(err, model.ErrInvalidExcursionItineraryDuration),
		errors.Is(err, model.ErrInvalidExcursionBookingID),
		errors.Is(err, model.ErrInvalidExcursionBookingOfferID),
		errors.Is(err, model.ErrInvalidExcursionBookingUserID),
		errors.Is(err, model.ErrInvalidExcursionBookingSchedule),
		errors.Is(err, model.ErrInvalidExcursionBookingGuests),
		errors.Is(err, model.ErrInvalidExcursionBookingPrice),
		errors.Is(err, model.ErrInvalidExcursionBookingStatus),
		errors.Is(err, app.ErrExcursionOfferNotBookable):
		writeError(w, http.StatusBadRequest, err.Error())
	default:
		log.Error().
			Err(err).
			Str("request_id", RequestIDFromContext(r.Context())).
			Str("method", r.Method).
			Str("path", r.URL.Path).
			Msg(fallback)
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

func optionalUUID(v string) *uuid.UUID {
	if strings.TrimSpace(v) == "" {
		return nil
	}
	parsed, err := uuid.Parse(strings.TrimSpace(v))
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

func parseGuideUserIDs(w http.ResponseWriter, value string) ([]uuid.UUID, bool) {
	const maxGuideUserIDs = 100
	parts := strings.Split(value, ",")
	result := make([]uuid.UUID, 0, len(parts))
	seen := make(map[uuid.UUID]struct{}, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		guideUserID, err := uuid.Parse(part)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid guide user id")
			return nil, false
		}
		if guideUserID == uuid.Nil {
			continue
		}
		if _, ok := seen[guideUserID]; ok {
			continue
		}
		if len(result) >= maxGuideUserIDs {
			writeError(w, http.StatusBadRequest, "too many guide user ids")
			return nil, false
		}
		seen[guideUserID] = struct{}{}
		result = append(result, guideUserID)
	}
	return result, true
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
