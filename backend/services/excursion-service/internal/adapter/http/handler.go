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
	mux.HandleFunc("GET /v1/excursion-products/{id}/schedule", h.ListPublicExcursionSchedule)
	mux.HandleFunc("GET /v1/excursion-products/{id}/offers", h.ListExcursionProductOffers)
	mux.HandleFunc("GET /v1/excursion-products/{id}/reviews", h.ListExcursionProductReviews)
	mux.HandleFunc("GET /v1/excursion-products/{id}/cover", h.GetExcursionProductCover)
	mux.HandleFunc("GET /v1/excursion-reviews", h.ListExcursionReviews)
	mux.HandleFunc("GET /v1/guide-reviews", h.ListGuideReviews)

	mux.HandleFunc("GET /v1/excursions", h.ListExcursions)
	mux.HandleFunc("GET /v1/excursions/{id}", h.GetExcursion)
	mux.HandleFunc("GET /v1/excursions/{id}/cover", h.GetExcursionCover)
	mux.HandleFunc("GET /v1/admin/excursions/moderation/pending", h.ListPendingReviewExcursions)
	mux.HandleFunc("GET /v1/admin/excursions/{id}", h.GetModerationExcursion)
	mux.HandleFunc("POST /v1/admin/excursion-guides/{guideUserId}/archive-offers", h.ArchiveGuideExcursionOffers)
	mux.HandleFunc("GET /v1/guides/excursion-languages", h.ListGuideExcursionLanguages)
	mux.HandleFunc("GET /v1/guides/by-excursion-city", h.ListGuideUserIDsByExcursionCity)
	mux.HandleFunc("GET /v1/excursion-guides/{guideUserId}/schedule", h.ListPublicGuideSchedule)

	mux.HandleFunc("POST /v1/me/excursions", h.CreateExcursion)
	mux.HandleFunc("GET /v1/me/excursions", h.ListMyExcursions)
	mux.HandleFunc("GET /v1/me/excursions/{id}", h.GetMyExcursion)
	mux.HandleFunc("PUT /v1/me/excursions/{id}", h.UpdateExcursion)
	mux.HandleFunc("DELETE /v1/me/excursions/{id}", h.DeleteExcursion)
	mux.HandleFunc("POST /v1/me/excursions/{id}/archive", h.ArchiveExcursion)
	mux.HandleFunc("POST /v1/me/excursions/{id}/publish", h.PublishExcursion)
	mux.HandleFunc("POST /v1/me/excursions/{id}/submit-for-publish", h.PublishExcursion)
	mux.HandleFunc("POST /v1/me/excursions/{id}/submit-for-review", h.PublishExcursion)
	mux.HandleFunc("POST /v1/admin/excursions/{id}/moderation/approve", h.ApproveExcursionModeration)
	mux.HandleFunc("POST /v1/admin/excursions/{id}/moderation/reject", h.RejectExcursionModeration)
	mux.HandleFunc("GET /v1/me/excursion-schedule", h.ListGuideSchedule)
	mux.HandleFunc("POST /v1/me/excursion-schedule/slots", h.CreateGuideScheduleSlot)
	mux.HandleFunc("PATCH /v1/me/excursion-schedule/slots/{id}", h.UpdateGuideScheduleSlot)
	mux.HandleFunc("POST /v1/me/excursion-schedule/series", h.CreateGuideScheduleSeries)
	mux.HandleFunc("POST /v1/me/excursion-schedule/slots/{id}/close", h.CloseGuideScheduleSlot)
	mux.HandleFunc("POST /v1/me/excursion-schedule/slots/{id}/cancel", h.CancelGuideScheduleSlot)
	mux.HandleFunc("GET /v1/me/excursion-schedule/slots/{id}/attendance-qr", h.GetGuideScheduleSlotAttendanceQR)
	mux.HandleFunc("POST /v1/me/excursion-schedule/attendance/sync", h.SyncExcursionAttendanceProofs)
	mux.HandleFunc("DELETE /v1/me/excursion-schedule/slots/{id}", h.DeleteGuideScheduleSlot)
	mux.HandleFunc("GET /v1/me/excursion-bookings", h.ListMyExcursionBookings)
	mux.HandleFunc("GET /v1/me/guide-excursion-bookings", h.ListMyGuideExcursionBookings)
	mux.HandleFunc("POST /v1/me/excursion-bookings", h.CreateExcursionBooking)
	mux.HandleFunc("PATCH /v1/me/excursion-bookings/{id}", h.UpdateExcursionBookingGuests)
	mux.HandleFunc("POST /v1/me/excursion-bookings/{id}/cancel", h.CancelExcursionBooking)
	mux.HandleFunc("POST /v1/me/excursion-bookings/{id}/review", h.CreateExcursionReview)
	mux.HandleFunc("PUT /v1/me/excursion-bookings/{id}/reviews", h.SaveBookingReviews)
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

func (h *Handler) ApproveExcursionModeration(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	if !requireModeratorRole(w, r) {
		return
	}
	excursionID, ok := parsePathUUID(w, r, "id", "invalid excursion id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.ApproveExcursionModeration(r.Context(), excursionID, actorUserID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to approve excursion moderation")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionResponse(aggregate))
}

func (h *Handler) RejectExcursionModeration(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	if !requireModeratorRole(w, r) {
		return
	}
	excursionID, ok := parsePathUUID(w, r, "id", "invalid excursion id")
	if !ok {
		return
	}
	var req struct {
		ReasonCodes   []string `json:"reasonCodes"`
		PublicComment string   `json:"publicComment"`
	}
	if r.Body != nil && r.Body != http.NoBody {
		if err := decodeBody(r, &req); err != nil && !errors.Is(err, io.EOF) {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
	}
	aggregate, err := h.useCase.RejectExcursionModeration(r.Context(), excursionID, actorUserID, req.ReasonCodes)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to reject excursion moderation")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionResponse(aggregate))
}

func (h *Handler) ArchiveExcursion(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	excursionID, ok := parsePathUUID(w, r, "id", "invalid excursion id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.ArchiveExcursion(r.Context(), excursionID, actorUserID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to archive excursion")
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

func (h *Handler) ListPendingReviewExcursions(w http.ResponseWriter, r *http.Request) {
	if !requireModeratorRole(w, r) {
		return
	}
	requestedLimit := clampLimit(parseIntOrDefault(r.URL.Query().Get("limit"), 20))
	aggregates, err := h.useCase.ListPendingReviewExcursions(
		r.Context(),
		requestedLimit+1,
		parseIntOrDefault(r.URL.Query().Get("offset"), 0),
	)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list pending review excursions")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionListResponse(aggregates, requestedLimit))
}

func (h *Handler) GetModerationExcursion(w http.ResponseWriter, r *http.Request) {
	if !requireModeratorRole(w, r) {
		return
	}
	excursionID, ok := parsePathUUID(w, r, "id", "invalid excursion id")
	if !ok {
		return
	}
	aggregate, err := h.useCase.GetModerationExcursion(r.Context(), excursionID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to get moderation excursion")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionResponse(aggregate))
}

func (h *Handler) ArchiveGuideExcursionOffers(w http.ResponseWriter, r *http.Request) {
	if !requireModeratorRole(w, r) {
		return
	}
	guideUserID, ok := parsePathUUID(w, r, "guideUserId", "invalid guide user id")
	if !ok {
		return
	}
	if err := h.useCase.ArchiveGuideExcursionOffers(r.Context(), guideUserID); err != nil {
		h.writeUseCaseError(w, r, err, "failed to archive guide excursion offers")
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"success": true})
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

func (h *Handler) ListGuideUserIDsByExcursionCity(w http.ResponseWriter, r *http.Request) {
	cityName := strings.TrimSpace(r.URL.Query().Get("cityName"))
	if cityName == "" {
		writeError(w, http.StatusBadRequest, "cityName is required")
		return
	}
	var countryCode *string
	if raw := strings.TrimSpace(r.URL.Query().Get("countryCode")); raw != "" {
		normalized := strings.ToUpper(raw)
		countryCode = &normalized
	}

	guideUserIDs, err := h.useCase.ListGuideUserIDsByExcursionCity(
		r.Context(),
		port.GuideExcursionCityFilter{
			CityName:    &cityName,
			CountryCode: countryCode,
		},
	)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list guide user ids by excursion city")
		return
	}
	writeJSON(w, http.StatusOK, toGuideUserIDListResponse(guideUserIDs))
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

func (h *Handler) ListGuideSchedule(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	from, err := time.Parse(time.RFC3339, strings.TrimSpace(r.URL.Query().Get("from")))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid from")
		return
	}
	to, err := time.Parse(time.RFC3339, strings.TrimSpace(r.URL.Query().Get("to")))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid to")
		return
	}
	items, err := h.useCase.ListGuideSchedule(r.Context(), app.ListGuideScheduleInput{
		ActorUserID: actorUserID,
		From:        from,
		To:          to,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list guide schedule")
		return
	}
	response := make([]dto.GuideScheduleSlotResponse, 0, len(items))
	for _, item := range items {
		response = append(response, toGuideScheduleSlotResponse(item))
	}
	writeJSON(w, http.StatusOK, dto.GuideScheduleListResponse{Items: response})
}

func (h *Handler) ListPublicGuideSchedule(w http.ResponseWriter, r *http.Request) {
	guideUserID, ok := parsePathUUID(w, r, "guideUserId", "invalid guide user id")
	if !ok {
		return
	}
	from, err := time.Parse(time.RFC3339, strings.TrimSpace(r.URL.Query().Get("from")))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid from")
		return
	}
	to, err := time.Parse(time.RFC3339, strings.TrimSpace(r.URL.Query().Get("to")))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid to")
		return
	}
	items, err := h.useCase.ListPublicGuideSchedule(r.Context(), app.ListPublicGuideScheduleInput{
		GuideUserID: guideUserID,
		From:        from,
		To:          to,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list public guide schedule")
		return
	}
	response := make([]dto.GuideScheduleSlotResponse, 0, len(items))
	for _, item := range items {
		response = append(response, toGuideScheduleSlotResponse(item))
	}
	writeJSON(w, http.StatusOK, dto.GuideScheduleListResponse{Items: response})
}

func (h *Handler) ListPublicExcursionSchedule(w http.ResponseWriter, r *http.Request) {
	productID, ok := parsePathUUID(w, r, "id", "invalid excursion product id")
	if !ok {
		return
	}
	offerID, err := uuid.Parse(strings.TrimSpace(r.URL.Query().Get("offerId")))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid offerId")
		return
	}
	from, err := time.Parse(time.RFC3339, strings.TrimSpace(r.URL.Query().Get("from")))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid from")
		return
	}
	to, err := time.Parse(time.RFC3339, strings.TrimSpace(r.URL.Query().Get("to")))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid to")
		return
	}
	seats := 1
	if rawSeats := strings.TrimSpace(r.URL.Query().Get("seats")); rawSeats != "" {
		parsed, parseErr := strconv.Atoi(rawSeats)
		if parseErr != nil {
			writeError(w, http.StatusBadRequest, "invalid seats")
			return
		}
		seats = parsed
	}
	items, err := h.useCase.ListPublicExcursionSchedule(r.Context(), app.ListPublicExcursionScheduleInput{
		ProductID: productID,
		OfferID:   offerID,
		From:      from,
		To:        to,
		Seats:     seats,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list excursion schedule")
		return
	}
	response := make([]dto.GuideScheduleSlotResponse, 0, len(items))
	for _, item := range items {
		response = append(response, toGuideScheduleSlotResponse(item))
	}
	writeJSON(w, http.StatusOK, dto.GuideScheduleListResponse{Items: response})
}

func (h *Handler) CreateGuideScheduleSlot(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	var req dto.CreateGuideScheduleSlotRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	offerID, err := uuid.Parse(strings.TrimSpace(req.OfferID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid offer id")
		return
	}
	startAt, err := time.Parse(time.RFC3339, strings.TrimSpace(req.StartAt))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid startAt")
		return
	}
	slot, err := h.useCase.CreateGuideScheduleSlot(r.Context(), app.CreateGuideScheduleSlotInput{
		ActorUserID: actorUserID,
		OfferID:     offerID,
		StartAt:     startAt,
		Timezone:    req.Timezone,
		Capacity:    req.Capacity,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to create guide schedule slot")
		return
	}
	writeJSON(w, http.StatusCreated, toGuideScheduleSlotResponse(slot))
}

func (h *Handler) UpdateGuideScheduleSlot(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	slotID, ok := parsePathUUID(w, r, "id", "invalid schedule slot id")
	if !ok {
		return
	}
	var req dto.UpdateGuideScheduleSlotRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	var offerID uuid.UUID
	if strings.TrimSpace(req.OfferID) != "" {
		parsed, err := uuid.Parse(strings.TrimSpace(req.OfferID))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid offer id")
			return
		}
		offerID = parsed
	}
	var startAt time.Time
	if strings.TrimSpace(req.StartAt) != "" {
		parsed, err := time.Parse(time.RFC3339, strings.TrimSpace(req.StartAt))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid startAt")
			return
		}
		startAt = parsed
	}
	slot, err := h.useCase.UpdateGuideScheduleSlot(r.Context(), app.UpdateGuideScheduleSlotInput{
		ActorUserID: actorUserID,
		SlotID:      slotID,
		OfferID:     offerID,
		StartAt:     startAt,
		Timezone:    req.Timezone,
		Capacity:    req.Capacity,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to update guide schedule slot")
		return
	}
	writeJSON(w, http.StatusOK, toGuideScheduleSlotResponse(slot))
}

func (h *Handler) CreateGuideScheduleSeries(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	var req dto.CreateGuideScheduleSeriesRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	offerID, err := uuid.Parse(strings.TrimSpace(req.OfferID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid offer id")
		return
	}
	startsOn, err := time.Parse("2006-01-02", strings.TrimSpace(req.StartsOn))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid startsOn")
		return
	}
	var endsOn *time.Time
	if strings.TrimSpace(req.EndsOn) != "" {
		parsed, parseErr := time.Parse("2006-01-02", strings.TrimSpace(req.EndsOn))
		if parseErr != nil {
			writeError(w, http.StatusBadRequest, "invalid endsOn")
			return
		}
		endsOn = &parsed
	}
	var occurrenceLimit *int
	if req.OccurrenceLimit > 0 {
		occurrenceLimit = &req.OccurrenceLimit
	}
	slots, err := h.useCase.CreateGuideScheduleSeries(r.Context(), app.CreateGuideScheduleSeriesInput{
		ActorUserID:     actorUserID,
		OfferID:         offerID,
		StartsOn:        startsOn,
		EndsOn:          endsOn,
		OccurrenceLimit: occurrenceLimit,
		StartTime:       req.StartTime,
		Timezone:        req.Timezone,
		Weekdays:        req.Weekdays,
		Capacity:        req.Capacity,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to create guide schedule series")
		return
	}
	response := make([]dto.GuideScheduleSlotResponse, 0, len(slots))
	for _, slot := range slots {
		response = append(response, toGuideScheduleSlotResponse(slot))
	}
	writeJSON(w, http.StatusCreated, dto.GuideScheduleListResponse{Items: response})
}

func (h *Handler) CloseGuideScheduleSlot(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	slotID, ok := parsePathUUID(w, r, "id", "invalid schedule slot id")
	if !ok {
		return
	}
	slot, err := h.useCase.CloseGuideScheduleSlot(r.Context(), actorUserID, slotID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to close guide schedule slot")
		return
	}
	writeJSON(w, http.StatusOK, toGuideScheduleSlotResponse(slot))
}

func (h *Handler) CancelGuideScheduleSlot(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	slotID, ok := parsePathUUID(w, r, "id", "invalid schedule slot id")
	if !ok {
		return
	}
	var req dto.CancelGuideScheduleSlotRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	slot, err := h.useCase.CancelGuideScheduleSlot(r.Context(), actorUserID, slotID, req.Reason)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to cancel guide schedule slot")
		return
	}
	writeJSON(w, http.StatusOK, toGuideScheduleSlotResponse(slot))
}

func (h *Handler) DeleteGuideScheduleSlot(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	slotID, ok := parsePathUUID(w, r, "id", "invalid schedule slot id")
	if !ok {
		return
	}
	if err := h.useCase.DeleteGuideScheduleSlot(r.Context(), actorUserID, slotID); err != nil {
		h.writeUseCaseError(w, r, err, "failed to delete guide schedule slot")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetGuideScheduleSlotAttendanceQR(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	slotID, ok := parsePathUUID(w, r, "id", "invalid schedule slot id")
	if !ok {
		return
	}

	item, err := h.useCase.GenerateExcursionAttendanceQR(r.Context(), slotID, actorUserID)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to generate excursion attendance qr")
		return
	}

	writeJSON(w, http.StatusOK, dto.ExcursionAttendanceQRResponse{
		ScheduleSlotID: item.ScheduleSlotID,
		Token:          item.Token,
		ExpiresAt:      item.ExpiresAt.UTC().Format(time.RFC3339),
		RefreshAt:      item.RefreshAt.UTC().Format(time.RFC3339),
	})
}

func (h *Handler) SyncExcursionAttendanceProofs(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}

	var req dto.ExcursionAttendanceSyncRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid attendance sync payload")
		return
	}
	if len(req.Items) == 0 {
		writeError(w, http.StatusBadRequest, "attendance sync items are required")
		return
	}

	inputs := make([]app.ExcursionAttendanceProofInput, 0, len(req.Items))
	for _, item := range req.Items {
		scanID, err := uuid.Parse(strings.TrimSpace(item.ScanID))
		if err != nil {
			inputs = append(inputs, app.ExcursionAttendanceProofInput{
				QRToken:        item.QRToken,
				InstallationID: item.InstallationID,
			})
			continue
		}
		var scannedAtDevice *time.Time
		if strings.TrimSpace(item.ScannedAtDevice) != "" {
			if parsed, parseErr := time.Parse(time.RFC3339, strings.TrimSpace(item.ScannedAtDevice)); parseErr == nil {
				parsed = parsed.UTC()
				scannedAtDevice = &parsed
			}
		}
		inputs = append(inputs, app.ExcursionAttendanceProofInput{
			ScanID:          scanID,
			QRToken:         item.QRToken,
			InstallationID:  item.InstallationID,
			ScannedAtDevice: scannedAtDevice,
		})
	}

	results, err := h.useCase.SyncExcursionAttendanceProofs(r.Context(), actorUserID, inputs)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to sync excursion attendance proofs")
		return
	}

	items := make([]dto.ExcursionAttendanceSyncItemResponse, 0, len(results))
	for _, result := range results {
		items = append(items, dto.ExcursionAttendanceSyncItemResponse{
			ScanID:         result.ScanID.String(),
			ScheduleSlotID: formatOptionalUUID(result.ScheduleSlotID),
			Status:         result.Status,
			Code:           result.Code,
			Message:        result.Message,
			CheckedInAt:    formatOptionalTime(result.CheckedInAt),
			SyncedAt:       result.SyncedAt.UTC().Format(time.RFC3339),
		})
	}
	writeJSON(w, http.StatusOK, dto.ExcursionAttendanceSyncResponse{Items: items})
}

func (h *Handler) ListMyExcursionBookings(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	requestedLimit := clampLimit(parseIntOrDefault(r.URL.Query().Get("limit"), 20))
	items, err := h.useCase.ListMyExcursionBookings(
		r.Context(),
		actorUserID,
		requestedLimit+1,
		parseIntOrDefault(r.URL.Query().Get("offset"), 0),
	)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list excursion bookings")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionBookingListResponse(items, requestedLimit))
}

func (h *Handler) ListMyGuideExcursionBookings(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	requestedLimit := clampLimit(parseIntOrDefault(r.URL.Query().Get("limit"), 20))
	items, err := h.useCase.ListMyGuideExcursionBookings(
		r.Context(),
		actorUserID,
		requestedLimit+1,
		parseIntOrDefault(r.URL.Query().Get("offset"), 0),
	)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list guide excursion bookings")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionBookingListResponse(items, requestedLimit))
}

func (h *Handler) UpdateExcursionBookingGuests(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	bookingID, ok := parsePathUUID(w, r, "id", "invalid excursion booking id")
	if !ok {
		return
	}
	var req dto.UpdateExcursionBookingGuestsRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	booking, err := h.useCase.UpdateExcursionBookingGuests(r.Context(), app.UpdateExcursionBookingGuestsInput{
		ActorUserID: actorUserID,
		BookingID:   bookingID,
		Adults:      req.Adults,
		Children:    req.Children,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to update excursion booking")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionBookingResponse(booking))
}

func (h *Handler) CancelExcursionBooking(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	bookingID, ok := parsePathUUID(w, r, "id", "invalid excursion booking id")
	if !ok {
		return
	}
	var req dto.CancelExcursionBookingRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	booking, err := h.useCase.CancelExcursionBooking(r.Context(), app.CancelExcursionBookingInput{
		ActorUserID: actorUserID,
		BookingID:   bookingID,
		Reason:      req.Reason,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to cancel excursion booking")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionBookingResponse(booking))
}

func (h *Handler) CreateExcursionReview(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	bookingID, ok := parsePathUUID(w, r, "id", "invalid excursion booking id")
	if !ok {
		return
	}
	var req dto.CreateExcursionReviewRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	review, err := h.useCase.CreateExcursionReview(r.Context(), app.CreateExcursionReviewInput{
		ActorUserID: actorUserID,
		BookingID:   bookingID,
		Rating:      req.Rating,
		Comment:     req.Comment,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to create excursion review")
		return
	}
	writeJSON(w, http.StatusCreated, toExcursionReviewResponse(review, ""))
}

func (h *Handler) SaveBookingReviews(w http.ResponseWriter, r *http.Request) {
	actorUserID, ok := parseActorUserID(w, r)
	if !ok {
		return
	}
	bookingID, ok := parsePathUUID(w, r, "id", "invalid excursion booking id")
	if !ok {
		return
	}
	var req dto.SaveBookingReviewsRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	result, err := h.useCase.SaveBookingReviews(r.Context(), app.SaveBookingReviewsInput{
		ActorUserID:     actorUserID,
		BookingID:       bookingID,
		ExcursionReview: toReviewMutationInput(req.ExcursionReview),
		GuideReview:     toReviewMutationInput(req.GuideReview),
	})
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to save booking reviews")
		return
	}
	writeJSON(w, http.StatusOK, toBookingReviewsResponse(result))
}

func (h *Handler) ListExcursionProductReviews(w http.ResponseWriter, r *http.Request) {
	productID, ok := parsePathUUID(w, r, "id", "invalid excursion product id")
	if !ok {
		return
	}
	h.writeExcursionReviews(w, r, port.ExcursionReviewFilter{ProductID: &productID})
}

func (h *Handler) ListExcursionReviews(w http.ResponseWriter, r *http.Request) {
	var filter port.ExcursionReviewFilter
	if rawProductID := strings.TrimSpace(r.URL.Query().Get("productId")); rawProductID != "" {
		productID, err := uuid.Parse(rawProductID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid excursion product id")
			return
		}
		filter.ProductID = &productID
	}
	if rawLandmarkID := strings.TrimSpace(r.URL.Query().Get("landmarkId")); rawLandmarkID != "" {
		landmarkID, err := uuid.Parse(rawLandmarkID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid landmark id")
			return
		}
		filter.LandmarkID = &landmarkID
	}
	if rawGuideUserID := strings.TrimSpace(r.URL.Query().Get("guideUserId")); rawGuideUserID != "" {
		guideUserID, err := uuid.Parse(rawGuideUserID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid guide user id")
			return
		}
		filter.GuideUserID = &guideUserID
	}
	if rawSort := strings.TrimSpace(r.URL.Query().Get("sort")); rawSort != "" {
		switch port.ExcursionReviewSort(rawSort) {
		case port.ExcursionReviewSortLatest, port.ExcursionReviewSortRatingDesc:
			filter.Sort = port.ExcursionReviewSort(rawSort)
		default:
			writeError(w, http.StatusBadRequest, "invalid excursion review sort")
			return
		}
	}
	h.writeExcursionReviews(w, r, filter)
}

func (h *Handler) ListGuideReviews(w http.ResponseWriter, r *http.Request) {
	var filter port.GuideReviewFilter
	rawGuideUserID := strings.TrimSpace(r.URL.Query().Get("guideUserId"))
	if rawGuideUserID == "" {
		writeError(w, http.StatusBadRequest, "guide user id is required")
		return
	}
	guideUserID, err := uuid.Parse(rawGuideUserID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid guide user id")
		return
	}
	filter.GuideUserID = &guideUserID
	if rawSort := strings.TrimSpace(r.URL.Query().Get("sort")); rawSort != "" {
		switch port.GuideReviewSort(rawSort) {
		case port.GuideReviewSortLatest, port.GuideReviewSortRatingDesc:
			filter.Sort = port.GuideReviewSort(rawSort)
		default:
			writeError(w, http.StatusBadRequest, "invalid guide review sort")
			return
		}
	}
	h.writeGuideReviews(w, r, filter)
}

func (h *Handler) writeExcursionReviews(w http.ResponseWriter, r *http.Request, filter port.ExcursionReviewFilter) {
	requestedLimit := clampLimit(parseIntOrDefault(r.URL.Query().Get("limit"), 20))
	filter.Limit = requestedLimit + 1
	filter.Offset = parseIntOrDefault(r.URL.Query().Get("offset"), 0)
	items, err := h.useCase.ListExcursionReviews(r.Context(), filter)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list excursion reviews")
		return
	}
	writeJSON(w, http.StatusOK, toExcursionReviewListResponse(items, requestedLimit))
}

func (h *Handler) writeGuideReviews(w http.ResponseWriter, r *http.Request, filter port.GuideReviewFilter) {
	requestedLimit := clampLimit(parseIntOrDefault(r.URL.Query().Get("limit"), 20))
	filter.Limit = requestedLimit + 1
	filter.Offset = parseIntOrDefault(r.URL.Query().Get("offset"), 0)
	items, err := h.useCase.ListGuideReviews(r.Context(), filter)
	if err != nil {
		h.writeUseCaseError(w, r, err, "failed to list guide reviews")
		return
	}
	writeJSON(w, http.StatusOK, toGuideReviewListResponse(items, requestedLimit))
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
		LandmarkID:      optionalUUID(query.Get("landmarkId")),
		CountryCode:     optionalString(query.Get("countryCode")),
		CityName:        optionalString(query.Get("cityName")),
		DepartureCityID: optionalReferenceCityID(query.Get("departureCityId")),
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
	filter.DepartureCityID = optionalReferenceCityID(query.Get("departureCityId"))
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
	departureCityID, err := parseOptionalReferenceCityID(req.DepartureCityID)
	if err != nil {
		return app.CreateExcursionInput{}, fmt.Errorf("invalid departureCityId")
	}
	itinerary, err := toAppItinerary(req.Itinerary)
	if err != nil {
		return app.CreateExcursionInput{}, err
	}
	return app.CreateExcursionInput{
		ActorUserID:          actorUserID,
		LandmarkID:           landmarkID,
		LandmarkName:         req.LandmarkName,
		CategorySlug:         req.CategorySlug,
		ProductTranslations:  toModelTranslations(req.ProductTranslations),
		Visibility:           req.Visibility,
		DurationMinutes:      req.DurationMinutes,
		MaxGroupSize:         req.MaxGroupSize,
		LanguageCodes:        req.LanguageCodes,
		CountryCode:          req.CountryCode,
		CityName:             req.CityName,
		DepartureCityID:      departureCityID,
		MeetingPoint:         req.MeetingPoint,
		Latitude:             req.Latitude,
		Longitude:            req.Longitude,
		MapURL:               req.MapURL,
		PriceAmount:          req.PriceAmount,
		Currency:             req.Currency,
		CoverFileID:          coverFileID,
		ProductCoverFileID:   productCoverFileID,
		ProductCoverImageURL: req.ProductCoverImageURL,
		IncludedItems:        toIncludedItemInputs(req.IncludedItems, req.IncludedItemTranslations),
		Itinerary:            itinerary,
	}, nil
}

func toUpdateInput(actorUserID uuid.UUID, excursionID uuid.UUID, req dto.UpdateExcursionRequest) (app.UpdateExcursionInput, error) {
	createInput, err := toCreateInput(actorUserID, req)
	if err != nil {
		return app.UpdateExcursionInput{}, err
	}
	return app.UpdateExcursionInput{
		ActorUserID:          createInput.ActorUserID,
		ExcursionID:          excursionID,
		LandmarkID:           createInput.LandmarkID,
		LandmarkName:         createInput.LandmarkName,
		CategorySlug:         createInput.CategorySlug,
		ProductTranslations:  createInput.ProductTranslations,
		Visibility:           createInput.Visibility,
		DurationMinutes:      createInput.DurationMinutes,
		MaxGroupSize:         createInput.MaxGroupSize,
		LanguageCodes:        createInput.LanguageCodes,
		CountryCode:          createInput.CountryCode,
		CityName:             createInput.CityName,
		DepartureCityID:      createInput.DepartureCityID,
		MeetingPoint:         createInput.MeetingPoint,
		Latitude:             createInput.Latitude,
		Longitude:            createInput.Longitude,
		MapURL:               createInput.MapURL,
		PriceAmount:          createInput.PriceAmount,
		Currency:             createInput.Currency,
		CoverFileID:          createInput.CoverFileID,
		ProductCoverFileID:   createInput.ProductCoverFileID,
		ProductCoverImageURL: createInput.ProductCoverImageURL,
		IncludedItems:        createInput.IncludedItems,
		Itinerary:            createInput.Itinerary,
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
	var scheduleSlotID *uuid.UUID
	if req.ScheduleSlotID != nil && strings.TrimSpace(*req.ScheduleSlotID) != "" {
		parsed, parseErr := uuid.Parse(strings.TrimSpace(*req.ScheduleSlotID))
		if parseErr != nil {
			return app.CreateExcursionBookingInput{}, fmt.Errorf("invalid scheduleSlotId")
		}
		scheduleSlotID = &parsed
	}
	var scheduledFor time.Time
	if strings.TrimSpace(req.ScheduledFor) != "" {
		scheduledFor, err = time.Parse(time.RFC3339, strings.TrimSpace(req.ScheduledFor))
		if err != nil {
			return app.CreateExcursionBookingInput{}, fmt.Errorf("invalid scheduledFor")
		}
	} else if scheduleSlotID == nil {
		return app.CreateExcursionBookingInput{}, fmt.Errorf("invalid scheduledFor")
	}
	return app.CreateExcursionBookingInput{
		ActorUserID:    actorUserID,
		ProductID:      productID,
		OfferID:        offerID,
		ScheduleSlotID: scheduleSlotID,
		ScheduledFor:   scheduledFor,
		Adults:         req.Adults,
		Children:       req.Children,
		IdempotencyKey: req.IdempotencyKey,
	}, nil
}

func toAppItinerary(items []dto.ExcursionItineraryItemRequest) ([]app.ExcursionItineraryItemInput, error) {
	result := make([]app.ExcursionItineraryItemInput, 0, len(items))
	for index, item := range items {
		attractionID, err := parseOptionalRouteStopUUID(item.AttractionID)
		if err != nil {
			return nil, fmt.Errorf("invalid itinerary[%d].attractionId", index)
		}
		result = append(result, app.ExcursionItineraryItemInput{
			StartOffsetMinutes:        item.StartOffsetMinutes,
			DurationMinutes:           item.DurationMinutes,
			AttractionID:              attractionID,
			AttractionName:            item.AttractionName,
			Latitude:                  item.Latitude,
			Longitude:                 item.Longitude,
			TravelFromPreviousMinutes: item.TravelFromPreviousMinutes,
			Title:                     item.Title,
			Description:               item.Description,
			Translations:              toModelItineraryTranslations(item.Translations),
		})
	}
	return result, nil
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
	} else if item.CoverImageURL != nil && strings.TrimSpace(*item.CoverImageURL) != "" {
		value := strings.TrimSpace(*item.CoverImageURL)
		coverImageURL = &value
	}
	return dto.ExcursionProductCardResponse{
		ID:                   item.ID.String(),
		LandmarkID:           formatOptionalUUID(item.LandmarkID),
		LandmarkName:         item.LandmarkName,
		RouteKind:            string(item.RouteKind),
		RouteFingerprint:     item.RouteFingerprint,
		AttractionIDs:        uuidStrings(item.AttractionIDs),
		AttractionNames:      item.AttractionNames,
		StopCount:            item.StopCount,
		TransportMode:        item.TransportMode,
		RouteTheme:           item.RouteTheme,
		DurationBucket:       item.DurationBucket,
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
		DepartureCityID:      formatOptionalString(item.DepartureCityID),
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

func toGuideUserIDListResponse(guideUserIDs []uuid.UUID) dto.GuideUserIDListResponse {
	resp := dto.GuideUserIDListResponse{
		Items: make([]dto.GuideUserIDResponse, 0, len(guideUserIDs)),
	}
	for _, guideUserID := range guideUserIDs {
		if guideUserID == uuid.Nil {
			continue
		}
		resp.Items = append(resp.Items, dto.GuideUserIDResponse{
			GuideUserID: guideUserID.String(),
		})
	}
	return resp
}

func toExcursionResponse(aggregate *app.ExcursionAggregate) dto.ExcursionResponse {
	item := aggregate.Excursion
	effectiveCoverFileID := aggregate.CoverFileID
	if effectiveCoverFileID == nil {
		effectiveCoverFileID = aggregate.ProductCoverFileID
	}
	coverImageURL := (*string)(nil)
	if aggregate.CoverFileID != nil {
		value := fmt.Sprintf("/api/v1/excursions/%s/cover", item.ID)
		coverImageURL = &value
	} else if aggregate.ProductCoverImageURL != nil && strings.TrimSpace(*aggregate.ProductCoverImageURL) != "" {
		value := strings.TrimSpace(*aggregate.ProductCoverImageURL)
		coverImageURL = &value
	}
	return dto.ExcursionResponse{
		ID:                       item.ID.String(),
		GuideProfileID:           item.GuideProfileID.String(),
		GuideUserID:              item.GuideUserID.String(),
		GuideDisplayName:         strings.TrimSpace(item.GuideDisplayName),
		GuideNickname:            strings.TrimSpace(item.GuideNickname),
		GuideFirstName:           strings.TrimSpace(item.GuideFirstName),
		GuideLastName:            strings.TrimSpace(item.GuideLastName),
		LandmarkID:               formatOptionalUUID(item.LandmarkID),
		LandmarkName:             item.LandmarkName,
		Title:                    item.Title,
		Summary:                  item.Summary,
		Description:              item.Description,
		Translations:             toDTOTranslations(item.Translations),
		ProductTranslations:      toDTOTranslations(item.ProductTranslations),
		CategorySlug:             item.CategorySlug,
		Tags:                     aggregate.Tags,
		Status:                   string(item.Status),
		Visibility:               string(item.Visibility),
		DurationMinutes:          item.DurationMinutes,
		MaxGroupSize:             item.MaxGroupSize,
		LanguageCodes:            aggregate.LanguageCodes,
		CountryCode:              item.CountryCode,
		CityName:                 item.CityName,
		DepartureCityID:          formatOptionalString(item.DepartureCityID),
		MeetingPoint:             item.MeetingPoint,
		Latitude:                 item.Latitude,
		Longitude:                item.Longitude,
		MapURL:                   item.MapURL,
		PriceAmount:              item.PriceAmount,
		Currency:                 item.Currency,
		CoverFileID:              formatOptionalUUID(effectiveCoverFileID),
		CoverImageURL:            coverImageURL,
		IncludedItems:            includedItemTexts(aggregate.IncludedItems),
		IncludedItemTranslations: includedItemTranslations(aggregate.IncludedItems),
		Itinerary:                toItineraryResponse(aggregate.Itinerary),
		PublishingDecision:       string(item.PublishingDecision),
		GuideTrustScore:          item.GuideTrustScore,
		PublishRiskScore:         item.PublishRiskScore,
		ModerationReasonCodes:    item.ModerationReasonCodes,
		SubmittedForReviewAt:     formatOptionalTime(item.SubmittedForReviewAt),
		PublishedAt:              formatOptionalTime(item.PublishedAt),
		DeletedAt:                formatOptionalTime(item.DeletedAt),
		Revision:                 item.Revision,
		CreatedAt:                item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:                item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toExcursionBookingResponse(item *model.ExcursionBooking) dto.ExcursionBookingResponse {
	var cancelledBy *string
	if item.CancelledBy != nil {
		value := string(*item.CancelledBy)
		cancelledBy = &value
	}
	return dto.ExcursionBookingResponse{
		ID:                item.ID.String(),
		ProductID:         item.ProductID.String(),
		OfferID:           item.OfferID.String(),
		ScheduleSlotID:    formatOptionalUUID(item.ScheduleSlotID),
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
		CancelledAt:       formatOptionalTime(item.CancelledAt),
		CancelledBy:       cancelledBy,
		CancelReason:      formatOptionalString(item.CancelReason),
		RefundPercent:     item.RefundPercent,
		RefundAmount:      item.RefundAmount,
		RefundCurrency:    formatOptionalString(item.RefundCurrency),
		RefundPolicyCode:  formatOptionalString(item.RefundPolicyCode),
		RefundStatus:      formatOptionalString(item.RefundStatus),
		CheckedInAt:       formatOptionalTime(item.CheckedInAt),
		CreatedAt:         item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:         item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toGuideScheduleSlotResponse(slot *model.ExcursionScheduleSlot) dto.GuideScheduleSlotResponse {
	return dto.GuideScheduleSlotResponse{
		ID:                slot.ID.String(),
		SeriesID:          formatOptionalUUID(slot.SeriesID),
		OfferID:           slot.OfferID.String(),
		ProductID:         slot.ProductID.String(),
		LegacyExcursionID: formatOptionalUUID(slot.LegacyExcursionID),
		StartAt:           slot.StartAt.UTC().Format(time.RFC3339),
		EndAt:             slot.EndAt.UTC().Format(time.RFC3339),
		Timezone:          slot.Timezone,
		Capacity:          slot.Capacity,
		BookedSeats:       slot.BookedSeats,
		Status:            string(slot.Status),
		Title:             strings.TrimSpace(slot.Title),
		CancelReason:      formatOptionalString(slot.CancelReason),
	}
}

func toExcursionBookingListResponse(items []*model.ExcursionBookingListItem, requestedLimit int) dto.ExcursionBookingListResponse {
	hasMore := len(items) > requestedLimit
	if hasMore {
		items = items[:requestedLimit]
	}
	result := make([]dto.ExcursionBookingResponse, 0, len(items))
	for _, item := range items {
		if item == nil || item.Booking == nil {
			continue
		}
		result = append(result, toExcursionBookingListItemResponse(item))
	}
	return dto.ExcursionBookingListResponse{Items: result, HasMore: hasMore}
}

func toExcursionBookingListItemResponse(item *model.ExcursionBookingListItem) dto.ExcursionBookingResponse {
	response := toExcursionBookingResponse(item.Booking)
	response.GuideDisplayName = strings.TrimSpace(item.GuideDisplayName)
	response.Title = strings.TrimSpace(item.Title)
	response.Summary = strings.TrimSpace(item.Summary)
	response.LandmarkID = formatOptionalUUID(item.LandmarkID)
	response.LandmarkName = formatOptionalString(item.LandmarkName)
	response.CategorySlug = strings.TrimSpace(item.CategorySlug)
	response.CountryCode = formatOptionalString(item.CountryCode)
	response.CityName = formatOptionalString(item.CityName)
	response.CoverFileID = formatOptionalUUID(item.CoverFileID)
	response.MaxGroupSize = item.MaxGroupSize
	if item.Author.UserID != uuid.Nil {
		var avatarFileID *string
		if item.Author.AvatarFileID != nil {
			value := item.Author.AvatarFileID.String()
			avatarFileID = &value
		}
		response.Author = &dto.ReviewAuthorResponse{
			UserID:       item.Author.UserID.String(),
			DisplayName:  item.Author.DisplayName,
			AvatarFileID: avatarFileID,
		}
	}
	if item.Review != nil {
		response.Review = toExcursionReviewResponse(item.Review, response.GuideDisplayName)
	}
	if item.GuideReview != nil {
		response.GuideReview = toGuideReviewResponse(item.GuideReview)
	}
	return response
}

func toExcursionReviewListResponse(items []*model.ExcursionReview, requestedLimit int) dto.ExcursionReviewListResponse {
	hasMore := len(items) > requestedLimit
	if hasMore {
		items = items[:requestedLimit]
	}
	result := make([]dto.ExcursionReviewResponse, 0, len(items))
	for _, item := range items {
		if item == nil {
			continue
		}
		response := toExcursionReviewResponse(item, item.GuideDisplayName)
		if response == nil {
			continue
		}
		result = append(result, *response)
	}
	return dto.ExcursionReviewListResponse{Items: result, HasMore: hasMore}
}

func toGuideReviewListResponse(items []*model.GuideReview, requestedLimit int) dto.GuideReviewListResponse {
	hasMore := len(items) > requestedLimit
	if hasMore {
		items = items[:requestedLimit]
	}
	result := make([]dto.GuideReviewResponse, 0, len(items))
	for _, item := range items {
		if item == nil {
			continue
		}
		response := toGuideReviewResponse(item)
		if response == nil {
			continue
		}
		result = append(result, *response)
	}
	return dto.GuideReviewListResponse{Items: result, HasMore: hasMore}
}

func toReviewMutationInput(req *dto.ReviewMutationRequest) *app.ReviewMutationInput {
	if req == nil {
		return nil
	}
	return &app.ReviewMutationInput{
		Rating:  req.Rating,
		Comment: req.Comment,
		Delete:  req.Delete,
	}
}

func toBookingReviewsResponse(result *app.BookingReviewsResult) dto.BookingReviewsResponse {
	if result == nil {
		return dto.BookingReviewsResponse{}
	}
	return dto.BookingReviewsResponse{
		ExcursionReview: toExcursionReviewResponse(result.ExcursionReview, ""),
		GuideReview:     toGuideReviewResponse(result.GuideReview),
	}
}

func toExcursionReviewResponse(item *model.ExcursionReview, guideDisplayName string) *dto.ExcursionReviewResponse {
	if item == nil {
		return nil
	}
	resolvedGuideDisplayName := strings.TrimSpace(guideDisplayName)
	if resolvedGuideDisplayName == "" {
		resolvedGuideDisplayName = strings.TrimSpace(item.GuideDisplayName)
	}
	authorUserID := item.Author.UserID
	if authorUserID == uuid.Nil {
		authorUserID = item.TouristUserID
	}
	var authorAvatarFileID *string
	if item.Author.AvatarFileID != nil {
		value := item.Author.AvatarFileID.String()
		authorAvatarFileID = &value
	}
	return &dto.ExcursionReviewResponse{
		ID:                item.ID.String(),
		BookingID:         item.BookingID.String(),
		ProductID:         item.ProductID.String(),
		OfferID:           item.OfferID.String(),
		LegacyExcursionID: formatOptionalUUID(item.LegacyExcursionID),
		LandmarkID:        formatOptionalUUID(item.LandmarkID),
		LandmarkName:      formatOptionalString(item.LandmarkName),
		GuideProfileID:    item.GuideProfileID.String(),
		GuideUserID:       item.GuideUserID.String(),
		GuideDisplayName:  resolvedGuideDisplayName,
		TouristUserID:     item.TouristUserID.String(),
		Author: dto.ReviewAuthorResponse{
			UserID:       authorUserID.String(),
			DisplayName:  item.Author.DisplayName,
			AvatarFileID: authorAvatarFileID,
		},
		Rating:      item.Rating,
		Comment:     item.Comment,
		SourceLabel: "EXCURSION",
		CreatedAt:   item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:   item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toGuideReviewResponse(item *model.GuideReview) *dto.GuideReviewResponse {
	if item == nil {
		return nil
	}
	authorUserID := item.Author.UserID
	if authorUserID == uuid.Nil {
		authorUserID = item.TouristUserID
	}
	var authorAvatarFileID *string
	if item.Author.AvatarFileID != nil {
		value := item.Author.AvatarFileID.String()
		authorAvatarFileID = &value
	}
	return &dto.GuideReviewResponse{
		ID:             item.ID.String(),
		BookingID:      item.BookingID.String(),
		ProductID:      item.ProductID.String(),
		OfferID:        item.OfferID.String(),
		GuideProfileID: item.GuideProfileID.String(),
		GuideUserID:    item.GuideUserID.String(),
		TouristUserID:  item.TouristUserID.String(),
		Author: dto.ReviewAuthorResponse{
			UserID:       authorUserID.String(),
			DisplayName:  item.Author.DisplayName,
			AvatarFileID: authorAvatarFileID,
		},
		Rating:      item.Rating,
		Comment:     item.Comment,
		SourceLabel: "GUIDE",
		CreatedAt:   item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:   item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toItineraryResponse(items []*model.ExcursionItineraryItem) []dto.ExcursionItineraryItemResponse {
	result := make([]dto.ExcursionItineraryItemResponse, 0, len(items))
	for _, item := range items {
		var attractionID *string
		if item.AttractionID != nil && *item.AttractionID != uuid.Nil {
			value := item.AttractionID.String()
			attractionID = &value
		}
		result = append(result, dto.ExcursionItineraryItemResponse{
			ID:                        item.ID.String(),
			SortOrder:                 item.SortOrder,
			StartOffsetMinutes:        item.StartOffsetMinutes,
			DurationMinutes:           item.DurationMinutes,
			AttractionID:              attractionID,
			AttractionName:            item.AttractionName,
			Latitude:                  item.Latitude,
			Longitude:                 item.Longitude,
			TravelFromPreviousMinutes: item.TravelFromPreviousMinutes,
			Title:                     item.Title,
			Description:               item.Description,
			Translations:              toDTOItineraryTranslations(item.Translations),
			CreatedAt:                 item.CreatedAt.UTC().Format(time.RFC3339),
			UpdatedAt:                 item.UpdatedAt.UTC().Format(time.RFC3339),
		})
	}
	return result
}

func (h *Handler) writeUseCaseError(w http.ResponseWriter, r *http.Request, err error, fallback string) {
	switch {
	case errors.Is(err, app.ErrInvalidActorUserID):
		writeError(w, http.StatusUnauthorized, err.Error())
	case errors.Is(err, app.ErrExcursionAccessDenied),
		errors.Is(err, app.ErrExcursionAttendanceAccessDenied),
		errors.Is(err, app.ErrGuideNotAllowed):
		writeError(w, http.StatusForbidden, err.Error())
	case errors.Is(err, app.ErrExcursionNotFound),
		errors.Is(err, app.ErrExcursionOfferNotFound),
		errors.Is(err, app.ErrExcursionBookingNotFound),
		errors.Is(err, app.ErrExcursionCoverFileNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, model.ErrExcursionAlreadyArchived),
		errors.Is(err, model.ErrExcursionGuideLandmarkAlreadyExists),
		errors.Is(err, model.ErrExcursionReviewAlreadyExists),
		errors.Is(err, model.ErrGuideReviewAlreadyExists),
		errors.Is(err, app.ErrExcursionBookingIdempotencyConflict),
		errors.Is(err, app.ErrExcursionScheduleConflict):
		writeError(w, http.StatusConflict, err.Error())
	case errors.Is(err, app.ErrExcursionTranslationFailed):
		writeError(w, http.StatusServiceUnavailable, err.Error())
	case errors.Is(err, app.ErrInvalidExcursionID),
		errors.Is(err, app.ErrExcursionAttractionRequired),
		errors.Is(err, app.ErrCombinedExcursionRouteRequiresTwoStops),
		errors.Is(err, app.ErrCombinedExcursionRouteTooManyStops),
		errors.Is(err, app.ErrCombinedExcursionRouteDuplicateStop),
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
		errors.Is(err, model.ErrInvalidExcursionLocation),
		errors.Is(err, model.ErrInvalidExcursionPrice),
		errors.Is(err, model.ErrInvalidExcursionCurrency),
		errors.Is(err, model.ErrInvalidExcursionPublishingDecision),
		errors.Is(err, model.ErrExcursionLanguageRequired),
		errors.Is(err, model.ErrExcursionItineraryRequired),
		errors.Is(err, model.ErrExcursionNotPendingReview),
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
		errors.Is(err, model.ErrInvalidExcursionReviewID),
		errors.Is(err, model.ErrInvalidExcursionReviewBooking),
		errors.Is(err, model.ErrInvalidExcursionReviewUser),
		errors.Is(err, model.ErrInvalidExcursionReviewRating),
		errors.Is(err, model.ErrInvalidExcursionReviewComment),
		errors.Is(err, model.ErrInvalidExcursionScheduleID),
		errors.Is(err, model.ErrInvalidExcursionScheduleGuide),
		errors.Is(err, model.ErrInvalidExcursionScheduleOffer),
		errors.Is(err, model.ErrInvalidExcursionScheduleInterval),
		errors.Is(err, model.ErrInvalidExcursionScheduleTimezone),
		errors.Is(err, model.ErrInvalidExcursionScheduleCapacity),
		errors.Is(err, model.ErrExcursionScheduleCancelReasonRequired),
		errors.Is(err, model.ErrExcursionScheduleBookedDeleteDenied),
		errors.Is(err, app.ErrExcursionBookingNotEditable),
		errors.Is(err, app.ErrExcursionBookingNotReviewable),
		errors.Is(err, app.ErrExcursionOfferNotBookable),
		errors.Is(err, app.ErrExcursionNotPublished),
		errors.Is(err, app.ErrExcursionScheduleStartTooSoon),
		errors.Is(err, app.ErrExcursionScheduleUnavailable),
		errors.Is(err, app.ErrExcursionAttendanceQRUnavailable),
		errors.Is(err, app.ErrExcursionAttendanceQRInvalid),
		errors.Is(err, app.ErrExcursionAttendanceQRVersionInvalid),
		errors.Is(err, app.ErrExcursionAttendanceQRExpired),
		errors.Is(err, app.ErrExcursionAttendanceAlreadyCheckedIn),
		errors.Is(err, app.ErrExcursionAttendanceBookingInvalid),
		errors.Is(err, model.ErrInvalidExcursionAttendanceQRJTI),
		errors.Is(err, model.ErrInvalidExcursionAttendanceQRSlot),
		errors.Is(err, model.ErrInvalidExcursionAttendanceQRGuide),
		errors.Is(err, model.ErrInvalidExcursionAttendanceQRRange),
		errors.Is(err, model.ErrInvalidAttendanceSyncScanID),
		errors.Is(err, model.ErrInvalidAttendanceSyncScheduleSlot),
		errors.Is(err, model.ErrInvalidAttendanceSyncParticipantID),
		errors.Is(err, model.ErrInvalidAttendanceSyncQRJTI),
		errors.Is(err, model.ErrInvalidAttendanceSyncInstallID),
		errors.Is(err, model.ErrInvalidAttendanceSyncStatus):
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

func requireModeratorRole(w http.ResponseWriter, r *http.Request) bool {
	for _, role := range RolesFromContext(r.Context()) {
		switch strings.ToLower(strings.TrimSpace(role)) {
		case "admin",
			"super_admin",
			"moderator",
			"content_moderator",
			"excursion_moderator",
			"guide_moderator",
			"moderation_lead":
			return true
		}
	}
	writeError(w, http.StatusForbidden, "moderator role required")
	return false
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

func parseOptionalReferenceCityID(v *string) (*string, error) {
	if v == nil || strings.TrimSpace(*v) == "" {
		return nil, nil
	}
	normalized := strings.ToLower(strings.TrimSpace(*v))
	if len(normalized) > 64 {
		return nil, fmt.Errorf("city id too long")
	}
	for i, r := range normalized {
		isLowerAlpha := r >= 'a' && r <= 'z'
		isDigit := r >= '0' && r <= '9'
		isHyphen := r == '-'
		if i == 0 {
			if !isLowerAlpha && !isDigit {
				return nil, fmt.Errorf("city id must start with latin letter or digit")
			}
			continue
		}
		if !isLowerAlpha && !isDigit && !isHyphen {
			return nil, fmt.Errorf("city id contains invalid character")
		}
	}
	return &normalized, nil
}

func parseOptionalRouteStopUUID(value *string) (*uuid.UUID, error) {
	if value == nil || strings.TrimSpace(*value) == "" {
		return nil, nil
	}
	parsed, err := uuid.Parse(strings.TrimSpace(*value))
	if err != nil {
		return nil, err
	}
	if parsed == uuid.Nil {
		return nil, fmt.Errorf("nil uuid")
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

func optionalReferenceCityID(v string) *string {
	parsed, err := parseOptionalReferenceCityID(&v)
	if err != nil {
		return nil
	}
	return parsed
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

func formatOptionalString(v *string) *string {
	if v == nil {
		return nil
	}
	value := strings.TrimSpace(*v)
	if value == "" {
		return nil
	}
	return &value
}

func uuidStrings(values []uuid.UUID) []string {
	if len(values) == 0 {
		return nil
	}
	result := make([]string, 0, len(values))
	for _, value := range values {
		if value == uuid.Nil {
			continue
		}
		result = append(result, value.String())
	}
	return result
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
