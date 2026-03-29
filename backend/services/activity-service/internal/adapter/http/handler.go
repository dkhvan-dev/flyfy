package http

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/transport/dto"
)

type Handler struct {
	activityUC    *app.ActivityUseCase
	attendanceUC  *app.AttendanceUseCase
	joinUC        *app.JoinUseCase
	repo          port.ActivityRepository
	fileManager   port.ActivityMediaFileManager
	actorResolver ActorResolver
}

func NewHandler(
	activityUC *app.ActivityUseCase,
	attendanceUC *app.AttendanceUseCase,
	joinUC *app.JoinUseCase,
	repo port.ActivityRepository,
	fileManager port.ActivityMediaFileManager,
	actorResolver ActorResolver,
) *Handler {
	return &Handler{
		activityUC:    activityUC,
		attendanceUC:  attendanceUC,
		joinUC:        joinUC,
		repo:          repo,
		fileManager:   fileManager,
		actorResolver: actorResolver,
	}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)

	mux.HandleFunc("GET /v1/activity-categories", h.ListActivityCategories)
	mux.HandleFunc("POST /v1/activities", h.CreateActivity)
	mux.HandleFunc("GET /v1/activities", h.ListActivities)

	mux.HandleFunc("POST /v1/me/activities", h.CreateActivity)
	mux.HandleFunc("GET /v1/me/activities/joined", h.ListMyJoinedActivities)
	mux.HandleFunc("GET /v1/me/activities/hosted", h.ListMyHostedActivities)
	mux.HandleFunc("POST /v1/me/attendance/sync", h.SyncAttendanceProofs)

	mux.HandleFunc("GET /v1/activities/", h.handleActivityRoutes)
	mux.HandleFunc("PATCH /v1/activities/", h.handleActivityRoutes)
	mux.HandleFunc("POST /v1/activities/", h.handleActivityRoutes)

	mux.HandleFunc("GET /v1/me/activities/", h.handleMyActivityRoutes)
	mux.HandleFunc("PATCH /v1/me/activities/", h.handleMyActivityRoutes)
	mux.HandleFunc("POST /v1/me/activities/", h.handleMyActivityRoutes)
}

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) handleActivityRoutes(w http.ResponseWriter, r *http.Request) {
	h.dispatchActivitySubRoutes(w, r, "/v1/activities/")
}

func (h *Handler) handleMyActivityRoutes(w http.ResponseWriter, r *http.Request) {
	h.dispatchActivitySubRoutes(w, r, "/v1/me/activities/")
}

func (h *Handler) dispatchActivitySubRoutes(w http.ResponseWriter, r *http.Request, prefix string) {
	path := strings.TrimPrefix(r.URL.Path, prefix)
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	parts := strings.Split(path, "/")
	activityID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid activity id")
		return
	}

	if len(parts) == 1 {
		switch r.Method {
		case http.MethodGet:
			h.GetActivityByID(w, r, activityID)
		case http.MethodPatch:
			h.UpdateActivity(w, r, activityID)
		default:
			writeError(w, http.StatusNotFound, "not found")
		}
		return
	}

	if len(parts) != 2 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	switch parts[1] {
	case "participants":
		if r.Method == http.MethodGet {
			h.ListActivityParticipants(w, r, activityID)
			return
		}
	case "attendance-qr":
		if r.Method == http.MethodGet {
			h.GetAttendanceQR(w, r, activityID)
			return
		}
	case "cover":
		if r.Method == http.MethodGet {
			h.GetActivityCover(w, r, activityID)
			return
		}
	case "publish":
		if r.Method == http.MethodPost {
			h.PublishActivity(w, r, activityID)
			return
		}
	case "approve":
		if r.Method == http.MethodPost {
			h.ApproveModeration(w, r, activityID)
			return
		}
	case "reject":
		if r.Method == http.MethodPost {
			h.RejectModeration(w, r, activityID)
			return
		}
	case "duplicate":
		if r.Method == http.MethodPost {
			h.DuplicateActivity(w, r, activityID)
			return
		}
	case "start":
		if r.Method == http.MethodPost {
			h.StartActivity(w, r, activityID)
			return
		}
	case "complete":
		if r.Method == http.MethodPost {
			h.CompleteActivity(w, r, activityID)
			return
		}
	case "cancel":
		if r.Method == http.MethodPost {
			h.CancelActivity(w, r, activityID)
			return
		}
	case "join":
		if r.Method == http.MethodPost {
			h.JoinActivity(w, r, activityID)
			return
		}
	case "leave":
		if r.Method == http.MethodPost {
			h.LeaveActivity(w, r, activityID)
			return
		}
	}

	writeError(w, http.StatusNotFound, "not found")
}

func (h *Handler) GetAttendanceQR(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "GetAttendanceQR::missing authenticated user")
		return
	}

	item, err := h.attendanceUC.GenerateAttendanceQR(r.Context(), activityID, actorUserID)
	if err != nil {
		h.writeAppError(w, err, "failed to generate attendance qr")
		return
	}

	writeJSON(
		w,
		http.StatusOK,
		dto.AttendanceQRResponse{
			ActivityID: item.ActivityID,
			Token:      item.Token,
			ExpiresAt:  item.ExpiresAt.Format(time.RFC3339),
			RefreshAt:  item.RefreshAt.Format(time.RFC3339),
		},
	)
}

func (h *Handler) SyncAttendanceProofs(w http.ResponseWriter, r *http.Request) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "SyncAttendanceProofs::missing authenticated user")
		return
	}

	var req dto.AttendanceSyncRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if len(req.Items) == 0 {
		writeError(w, http.StatusBadRequest, "attendance sync items are required")
		return
	}

	inputs := make([]app.AttendanceProofInput, 0, len(req.Items))
	for _, item := range req.Items {
		scanID, scanErr := uuid.Parse(strings.TrimSpace(item.ScanID))
		if scanErr != nil {
			inputs = append(inputs, app.AttendanceProofInput{
				QRToken:         item.QRToken,
				InstallationID:  item.InstallationID,
				ScannedAtDevice: nil,
			})
			continue
		}

		scannedAtDevice, parseErr := parseOptionalRFC3339(item.ScannedAtDevice)
		if parseErr != nil {
			writeError(w, http.StatusBadRequest, "invalid scannedAtDevice")
			return
		}

		inputs = append(inputs, app.AttendanceProofInput{
			ScanID:          scanID,
			QRToken:         item.QRToken,
			InstallationID:  item.InstallationID,
			ScannedAtDevice: scannedAtDevice,
		})
	}

	results, err := h.attendanceUC.SyncAttendanceProofs(r.Context(), actorUserID, inputs)
	if err != nil {
		h.writeAppError(w, err, "failed to sync attendance proofs")
		return
	}

	items := make([]dto.AttendanceSyncItemResponse, 0, len(results))
	for _, result := range results {
		var activityID *string
		if result.ActivityID != nil {
			value := result.ActivityID.String()
			activityID = &value
		}

		items = append(items, dto.AttendanceSyncItemResponse{
			ScanID:      result.ScanID.String(),
			ActivityID:  activityID,
			Status:      result.Status,
			Code:        result.Code,
			Message:     result.Message,
			CheckedInAt: formatOptionalTime(result.CheckedInAt),
			SyncedAt:    result.SyncedAt.Format(time.RFC3339),
		})
	}

	writeJSON(w, http.StatusOK, dto.AttendanceSyncResponse{Items: items})
}

func (h *Handler) CreateActivity(w http.ResponseWriter, r *http.Request) {
	log.Info().
		Str("ctx_user_id", UserIDFromContext(r.Context())).
		Str("ctx_subject", SubjectFromContext(r.Context())).
		Str("ctx_role", RoleFromContext(r.Context())).
		Strs("ctx_roles", RolesFromContext(r.Context())).
		Msg("CreateActivity context values")

	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		log.Error().
			Err(err).
			Str("ctx_user_id", UserIDFromContext(r.Context())).
			Str("ctx_subject", SubjectFromContext(r.Context())).
			Str("ctx_role", RoleFromContext(r.Context())).
			Strs("ctx_roles", RolesFromContext(r.Context())).
			Msg("CreateActivity failed to resolve actor user id")

		writeError(w, http.StatusUnauthorized, "CreateActivity::missing authenticated user")
		return
	}

	var req dto.CreateActivityRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	startAt, err := parseRFC3339(req.StartAt)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid startAt")
		return
	}
	endAt, err := parseRFC3339(req.EndAt)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid endAt")
		return
	}

	confirmationDeadline, err := parseOptionalRFC3339(req.ConfirmationDeadline)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid confirmationDeadline")
		return
	}
	coverFileID, err := parseOptionalUUIDString(req.CoverFileID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid coverFileId")
		return
	}

	input := app.CreateActivityInput{
		HostUserID:                     actorUserID,
		Title:                          req.Title,
		Description:                    req.Description,
		Format:                         enum.ActivityFormat(strings.TrimSpace(req.Format)),
		Visibility:                     enum.ActivityVisibility(strings.TrimSpace(req.Visibility)),
		JoinMode:                       enum.ActivityJoinMode(strings.TrimSpace(req.JoinMode)),
		CategorySlug:                   req.CategorySlug,
		Tags:                           req.Tags,
		LanguageCode:                   req.LanguageCode,
		Timezone:                       req.Timezone,
		StartAt:                        startAt,
		EndAt:                          endAt,
		CapacityType:                   enum.ActivityCapacityType(strings.TrimSpace(req.CapacityType)),
		MinParticipants:                req.MinParticipants,
		MaxParticipants:                req.MaxParticipants,
		PriceType:                      enum.ActivityPriceType(strings.TrimSpace(req.PriceType)),
		PriceAmount:                    req.PriceAmount,
		Currency:                       req.Currency,
		RequiresProfileCompletion:      valueOrDefaultBool(req.RequiresProfileCompletion, true),
		RequiresAttendanceConfirmation: valueOrDefaultBool(req.RequiresAttendanceConfirmation, false),
		ConfirmationDeadline:           confirmationDeadline,
		CountryCode:                    req.CountryCode,
		CityName:                       req.CityName,
		AddressText:                    req.AddressText,
		Latitude:                       req.Latitude,
		Longitude:                      req.Longitude,
		MapURL:                         req.MapURL,
		MeetingURL:                     req.MeetingURL,
		CoverFileID:                    coverFileID,
		VisibilityPassword:             req.VisibilityPassword,
		ReviewRequired:                 valueOrDefaultBool(req.ReviewRequired, false),
	}

	item, err := h.activityUC.CreateActivity(r.Context(), input)
	if err != nil {
		h.writeAppError(w, err, "failed to create activity")
		return
	}

	resp, err := h.toActivityResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity response")
		return
	}

	writeJSON(w, http.StatusCreated, resp)
}

func (h *Handler) GetActivityByID(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	_, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		log.Error().
			Err(err).
			Str("ctx_user_id", UserIDFromContext(r.Context())).
			Str("ctx_subject", SubjectFromContext(r.Context())).
			Str("ctx_role", RoleFromContext(r.Context())).
			Strs("ctx_roles", RolesFromContext(r.Context())).
			Msg("GetActivityByID failed to resolve actor user id")

		writeError(w, http.StatusUnauthorized, "GetActivityByID::missing authenticated user")
		return
	}

	item, err := h.activityUC.GetActivityByID(r.Context(), activityID)
	if err != nil {
		h.writeAppError(w, err, "failed to get activity")
		return
	}

	resp, err := h.toActivityResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity response")
		return
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListActivityCategories(w http.ResponseWriter, r *http.Request) {
	items := h.activityUC.ListActivityCategories()
	resp := dto.ActivityCategoryListResponse{
		Items: make([]dto.ActivityCategoryResponse, 0, len(items)),
	}

	for _, item := range items {
		resp.Items = append(resp.Items, dto.ActivityCategoryResponse{
			Slug:   item.Slug,
			Name:   item.Name,
			NameRu: item.NameRu,
			NameKk: item.NameKk,
		})
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListActivities(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()

	requestedLimit := parseIntOrDefault(q.Get("limit"), 20)
	if requestedLimit > 100 {
		requestedLimit = 100
	}

	filter := port.ActivityFilter{
		Limit:  requestedLimit + 1,
		Offset: parseIntOrDefault(q.Get("offset"), 0),
	}

	if v := strings.TrimSpace(q.Get("hostUserId")); v != "" {
		if parsed, err := uuid.Parse(v); err == nil {
			filter.HostUserID = &parsed
		}
	}
	if v := strings.TrimSpace(q.Get("status")); v != "" {
		filter.Statuses = splitCSV(v)
	} else {
		filter.Statuses = []string{
			string(enum.ActivityStatusPublished),
			string(enum.ActivityStatusEnrollmentOpen),
			string(enum.ActivityStatusFull),
			string(enum.ActivityStatusStarted),
			string(enum.ActivityStatusCompleted),
		}
	}

	if v := strings.TrimSpace(q.Get("visibility")); v != "" {
		filter.Visibility = &v
	}
	if v := strings.TrimSpace(q.Get("categorySlug")); v != "" {
		filter.CategorySlug = &v
	}
	if v := strings.TrimSpace(q.Get("countryCode")); v != "" {
		filter.CountryCode = &v
	}
	if v := strings.TrimSpace(q.Get("cityName")); v != "" {
		filter.CityName = &v
	}
	if v := strings.TrimSpace(q.Get("q")); v != "" {
		filter.SearchQuery = &v
	}

	items, err := h.activityUC.ListActivities(r.Context(), filter)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list activities")
		return
	}

	hasMore := len(items) > requestedLimit
	if hasMore {
		items = items[:requestedLimit]
	}

	resp := dto.ActivityListResponse{
		Items:   make([]dto.ActivityResponse, 0, len(items)),
		HasMore: hasMore,
	}

	for _, item := range items {
		mapped, mapErr := h.toActivityResponse(r.Context(), item)
		if mapErr != nil {
			writeError(w, http.StatusInternalServerError, "failed to build activity response")
			return
		}
		resp.Items = append(resp.Items, mapped)
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) UpdateActivity(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.UpdateActivityRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	startAt, err := parseOptionalRFC3339(req.StartAt)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid startAt")
		return
	}
	endAt, err := parseOptionalRFC3339(req.EndAt)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid endAt")
		return
	}
	confirmationDeadline, err := parseOptionalRFC3339(req.ConfirmationDeadline)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid confirmationDeadline")
		return
	}
	coverFileID, err := parseOptionalUUIDString(req.CoverFileID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid coverFileId")
		return
	}

	var visibility *enum.ActivityVisibility
	if req.Visibility != nil {
		v := enum.ActivityVisibility(strings.TrimSpace(*req.Visibility))
		visibility = &v
	}

	var joinMode *enum.ActivityJoinMode
	if req.JoinMode != nil {
		v := enum.ActivityJoinMode(strings.TrimSpace(*req.JoinMode))
		joinMode = &v
	}

	var capacityType *enum.ActivityCapacityType
	if req.CapacityType != nil {
		v := enum.ActivityCapacityType(strings.TrimSpace(*req.CapacityType))
		capacityType = &v
	}

	var priceType *enum.ActivityPriceType
	if req.PriceType != nil {
		v := enum.ActivityPriceType(strings.TrimSpace(*req.PriceType))
		priceType = &v
	}

	item, err := h.activityUC.UpdateActivity(r.Context(), app.UpdateActivityInput{
		ActorUserID:                    actorUserID,
		ActivityID:                     activityID,
		Title:                          req.Title,
		Description:                    req.Description,
		Visibility:                     visibility,
		JoinMode:                       joinMode,
		CategorySlug:                   req.CategorySlug,
		Tags:                           req.Tags,
		HasTags:                        req.HasTags,
		LanguageCode:                   req.LanguageCode,
		Timezone:                       req.Timezone,
		StartAt:                        startAt,
		EndAt:                          endAt,
		CapacityType:                   capacityType,
		MinParticipants:                req.MinParticipants,
		HasMinParticipants:             req.HasMinParticipants,
		MaxParticipants:                req.MaxParticipants,
		HasMaxParticipants:             req.HasMaxParticipants,
		PriceType:                      priceType,
		PriceAmount:                    req.PriceAmount,
		HasPriceAmount:                 req.HasPriceAmount,
		Currency:                       req.Currency,
		HasCurrency:                    req.HasCurrency,
		RequiresProfileCompletion:      req.RequiresProfileCompletion,
		RequiresAttendanceConfirmation: req.RequiresAttendanceConfirmation,
		ConfirmationDeadline:           confirmationDeadline,
		HasConfirmationDeadline:        req.HasConfirmationDeadline,
		CountryCode:                    req.CountryCode,
		HasCountryCode:                 req.HasCountryCode,
		CityName:                       req.CityName,
		HasCityName:                    req.HasCityName,
		AddressText:                    req.AddressText,
		HasAddressText:                 req.HasAddressText,
		Latitude:                       req.Latitude,
		HasLatitude:                    req.HasLatitude,
		Longitude:                      req.Longitude,
		HasLongitude:                   req.HasLongitude,
		MapURL:                         req.MapURL,
		HasMapURL:                      req.HasMapURL,
		MeetingURL:                     req.MeetingURL,
		HasMeetingURL:                  req.HasMeetingURL,
		CoverFileID:                    coverFileID,
		HasCoverFileID:                 req.HasCoverFileID,
		VisibilityPassword:             req.VisibilityPassword,
		HasVisibilityPassword:          req.HasVisibilityPassword,
	})
	if err != nil {
		h.writeAppError(w, err, "failed to update activity")
		return
	}

	resp, err := h.toActivityResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity response")
		return
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) PublishActivity(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.PublishActivityRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	item, err := h.activityUC.PublishActivity(
		r.Context(),
		activityID,
		actorUserID,
		valueOrDefaultBool(req.ReviewRequired, false),
	)
	if err != nil {
		h.writeAppError(w, err, "failed to publish activity")
		return
	}

	resp, err := h.toActivityResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity response")
		return
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ApproveModeration(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	item, err := h.activityUC.ApproveModeration(r.Context(), activityID, actorUserID)
	if err != nil {
		h.writeAppError(w, err, "failed to approve moderation")
		return
	}

	resp, err := h.toActivityResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity response")
		return
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) RejectModeration(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	item, err := h.activityUC.RejectModeration(r.Context(), activityID, actorUserID)
	if err != nil {
		h.writeAppError(w, err, "failed to reject moderation")
		return
	}

	resp, err := h.toActivityResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity response")
		return
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) DuplicateActivity(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.DuplicateActivityRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	startAt, err := parseRFC3339(req.StartAt)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid startAt")
		return
	}
	endAt, err := parseRFC3339(req.EndAt)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid endAt")
		return
	}
	registrationDeadline, err := parseRFC3339(req.RegistrationDeadline)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid registrationDeadline")
		return
	}

	item, err := h.activityUC.DuplicateActivity(
		r.Context(),
		activityID,
		actorUserID,
		startAt,
		endAt,
		registrationDeadline,
	)
	if err != nil {
		h.writeAppError(w, err, "failed to duplicate activity")
		return
	}

	resp, err := h.toActivityResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity response")
		return
	}

	writeJSON(w, http.StatusCreated, resp)
}

func (h *Handler) StartActivity(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	item, err := h.activityUC.StartActivity(r.Context(), activityID, actorUserID)
	if err != nil {
		h.writeAppError(w, err, "failed to start activity")
		return
	}

	resp, err := h.toActivityResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity response")
		return
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) CompleteActivity(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	item, err := h.activityUC.CompleteActivity(r.Context(), activityID, actorUserID)
	if err != nil {
		h.writeAppError(w, err, "failed to complete activity")
		return
	}

	resp, err := h.toActivityResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity response")
		return
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) CancelActivity(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.CancelActivityRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	item, err := h.activityUC.CancelActivity(r.Context(), activityID, actorUserID, req.Reason)
	if err != nil {
		h.writeAppError(w, err, "failed to cancel activity")
		return
	}

	resp, err := h.toActivityResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity response")
		return
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) JoinActivity(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.JoinActivityRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil &&
		!errors.Is(err, io.EOF) {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	item, err := h.joinUC.JoinActivity(r.Context(), app.JoinActivityInput{
		ActivityID:         activityID,
		UserID:             actorUserID,
		VisibilityPassword: req.Password,
	})
	if err != nil {
		h.writeAppError(w, err, "failed to join activity")
		return
	}

	writeJSON(w, http.StatusOK, toParticipantResponse(item))
}

func (h *Handler) LeaveActivity(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.LeaveActivityRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	item, err := h.joinUC.LeaveActivity(r.Context(), app.LeaveActivityInput{
		ActivityID: activityID,
		UserID:     actorUserID,
		Reason:     req.Reason,
	})
	if err != nil {
		h.writeAppError(w, err, "failed to leave activity")
		return
	}

	writeJSON(w, http.StatusOK, toParticipantResponse(item))
}

func (h *Handler) ListActivityParticipants(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	limit := parseIntOrDefault(r.URL.Query().Get("limit"), 50)
	offset := parseIntOrDefault(r.URL.Query().Get("offset"), 0)

	items, err := h.repo.ListParticipantsByActivityID(r.Context(), activityID, limit, offset)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list activity participants")
		return
	}

	resp := struct {
		Items []dto.ParticipantResponse `json:"items"`
	}{
		Items: make([]dto.ParticipantResponse, 0, len(items)),
	}

	for _, item := range items {
		resp.Items = append(resp.Items, toParticipantResponse(item))
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListMyJoinedActivities(w http.ResponseWriter, r *http.Request) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	joinedLimit := parseIntOrDefault(r.URL.Query().Get("limit"), 20)
	if joinedLimit > 100 {
		joinedLimit = 100
	}
	offset := parseIntOrDefault(r.URL.Query().Get("offset"), 0)

	items, err := h.activityUC.ListJoinedActivities(r.Context(), actorUserID, joinedLimit+1, offset)
	if err != nil {
		h.writeAppError(w, err, "failed to list joined activities")
		return
	}

	hasMore := len(items) > joinedLimit
	if hasMore {
		items = items[:joinedLimit]
	}

	resp := dto.ActivityListResponse{
		Items:   make([]dto.ActivityResponse, 0, len(items)),
		HasMore: hasMore,
	}

	for _, item := range items {
		mapped, mapErr := h.toActivityResponse(r.Context(), item)
		if mapErr != nil {
			writeError(w, http.StatusInternalServerError, "failed to build activity response")
			return
		}
		resp.Items = append(resp.Items, mapped)
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListMyHostedActivities(w http.ResponseWriter, r *http.Request) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	hostedLimit := parseIntOrDefault(r.URL.Query().Get("limit"), 20)
	if hostedLimit > 100 {
		hostedLimit = 100
	}
	offset := parseIntOrDefault(r.URL.Query().Get("offset"), 0)

	items, err := h.activityUC.ListHostedActivities(r.Context(), actorUserID, hostedLimit+1, offset)
	if err != nil {
		h.writeAppError(w, err, "failed to list hosted activities")
		return
	}

	hasMore := len(items) > hostedLimit
	if hasMore {
		items = items[:hostedLimit]
	}

	resp := dto.ActivityListResponse{
		Items:   make([]dto.ActivityResponse, 0, len(items)),
		HasMore: hasMore,
	}

	for _, item := range items {
		mapped, mapErr := h.toActivityResponse(r.Context(), item)
		if mapErr != nil {
			writeError(w, http.StatusInternalServerError, "failed to build activity response")
			return
		}
		resp.Items = append(resp.Items, mapped)
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) toActivityResponse(ctx context.Context, item *model.Activity) (dto.ActivityResponse, error) {
	tags, err := h.repo.ListTagsByActivityID(ctx, item.ID)
	if err != nil {
		return dto.ActivityResponse{}, err
	}
	media, err := h.repo.ListMediaByActivityID(ctx, item.ID)
	if err != nil {
		return dto.ActivityResponse{}, err
	}

	var sourceActivityID *string
	if item.SourceActivityID != nil {
		v := item.SourceActivityID.String()
		sourceActivityID = &v
	}
	coverMedia := selectCoverMedia(media)
	var coverFileID *string
	var coverImageURL *string
	if coverMedia != nil {
		v := coverMedia.FileID.String()
		coverFileID = &v
		coverURL := fmt.Sprintf("/api/v1/activities/%s/cover", item.ID.String())
		coverImageURL = &coverURL
	}

	return dto.ActivityResponse{
		ID:                             item.ID.String(),
		HostUserID:                     item.HostUserID.String(),
		SourceActivityID:               sourceActivityID,
		Title:                          item.Title,
		Description:                    item.Description,
		Format:                         string(item.Format),
		Status:                         string(item.Status),
		Visibility:                     string(item.Visibility),
		JoinMode:                       string(item.JoinMode),
		ModerationStatus:               string(item.ModerationStatus),
		CategorySlug:                   item.CategorySlug,
		Tags:                           tags,
		LanguageCode:                   item.LanguageCode,
		Timezone:                       item.Timezone,
		StartAt:                        item.StartAt.UTC().Format(time.RFC3339),
		EndAt:                          item.EndAt.UTC().Format(time.RFC3339),
		RegistrationDeadline:           item.RegistrationDeadline.UTC().Format(time.RFC3339),
		CapacityType:                   string(item.CapacityType),
		MinParticipants:                item.MinParticipants,
		MaxParticipants:                item.MaxParticipants,
		PriceType:                      string(item.PriceType),
		PriceAmount:                    item.PriceAmount,
		Currency:                       item.Currency,
		PriceLockedAt:                  formatOptionalTime(item.PriceLockedAt),
		RequiresProfileCompletion:      item.RequiresProfileCompletion,
		RequiresAttendanceConfirmation: item.RequiresAttendanceConfirmation,
		ConfirmationDeadline:           formatOptionalTime(item.ConfirmationDeadline),
		CountryCode:                    item.CountryCode,
		CityName:                       item.CityName,
		AddressText:                    item.AddressText,
		Latitude:                       item.Latitude,
		Longitude:                      item.Longitude,
		MapURL:                         item.MapURL,
		MeetingURL:                     item.MeetingURL,
		CoverFileID:                    coverFileID,
		CoverImageURL:                  coverImageURL,
		CancellationReason:             item.CancellationReason,
		CancelledAt:                    formatOptionalTime(item.CancelledAt),
		StartedAt:                      formatOptionalTime(item.StartedAt),
		CompletedAt:                    formatOptionalTime(item.CompletedAt),
		PublishedAt:                    formatOptionalTime(item.PublishedAt),
		Revision:                       item.Revision,
		CreatedAt:                      item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:                      item.UpdatedAt.UTC().Format(time.RFC3339),
	}, nil
}

func (h *Handler) GetActivityCover(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	if _, err := h.activityUC.GetActivityByID(r.Context(), activityID); err != nil {
		switch {
		case errors.Is(err, app.ErrActivityNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to load activity")
		}
		return
	}

	media, err := h.repo.ListMediaByActivityID(r.Context(), activityID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load activity cover")
		return
	}

	coverMedia := selectCoverMedia(media)
	if coverMedia == nil {
		writeError(w, http.StatusNotFound, "activity cover not found")
		return
	}
	if h.fileManager == nil {
		writeError(w, http.StatusServiceUnavailable, "file manager unavailable")
		return
	}

	downloadURL, err := h.fileManager.CreateDownloadURL(r.Context(), coverMedia.FileID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrActivityMediaFileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusBadGateway, "failed to resolve activity cover")
		}
		return
	}

	proxyReq, err := http.NewRequestWithContext(r.Context(), http.MethodGet, downloadURL, nil)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build cover request")
		return
	}

	resp, err := http.DefaultClient.Do(proxyReq)
	if err != nil {
		writeError(w, http.StatusBadGateway, "failed to fetch activity cover")
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		writeError(w, http.StatusNotFound, "activity cover not found")
		return
	}
	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		writeError(w, http.StatusBadGateway, "failed to fetch activity cover")
		return
	}

	if contentType := strings.TrimSpace(resp.Header.Get("Content-Type")); contentType != "" {
		w.Header().Set("Content-Type", contentType)
	}
	if contentLength := strings.TrimSpace(resp.Header.Get("Content-Length")); contentLength != "" {
		w.Header().Set("Content-Length", contentLength)
	}
	w.Header().Set("Cache-Control", "public, max-age=300")
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, resp.Body)
}

func toParticipantResponse(item *model.ActivityParticipant) dto.ParticipantResponse {
	return dto.ParticipantResponse{
		ID:                    item.ID.String(),
		ActivityID:            item.ActivityID.String(),
		UserID:                item.UserID.String(),
		Status:                string(item.Status),
		JoinedAt:              item.JoinedAt.UTC().Format(time.RFC3339),
		ApprovedAt:            formatOptionalTime(item.ApprovedAt),
		WaitlistedAt:          formatOptionalTime(item.WaitlistedAt),
		PaymentDueAt:          formatOptionalTime(item.PaymentDueAt),
		PaidAt:                formatOptionalTime(item.PaidAt),
		AttendanceConfirmedAt: formatOptionalTime(item.AttendanceConfirmedAt),
		CheckedInAt:           formatOptionalTime(item.CheckedInAt),
		AttendedAt:            formatOptionalTime(item.AttendedAt),
		CancelledAt:           formatOptionalTime(item.CancelledAt),
		CancelledByUserID:     formatOptionalUUID(item.CancelledByUserID),
		CancelReason:          item.CancelReason,
		CreatedAt:             item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:             item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func (h *Handler) writeAppError(w http.ResponseWriter, err error, fallback string) {
	switch {
	case errors.Is(err, app.ErrInvalidActivityID),
		errors.Is(err, app.ErrInvalidActorUserID),
		errors.Is(err, app.ErrInvalidParticipantUserID),
		errors.Is(err, app.ErrActivityCancellationReasonRequired),
		errors.Is(err, app.ErrActivityNotPublishable),
		errors.Is(err, app.ErrActivityNotStartable),
		errors.Is(err, app.ErrActivityNotCompletable),
		errors.Is(err, app.ErrActivityNotCancellable),
		errors.Is(err, app.ErrActivityJoinClosed),
		errors.Is(err, app.ErrActivityFull),
		errors.Is(err, app.ErrAlreadyJoined),
		errors.Is(err, app.ErrParticipantStateInvalid),
		errors.Is(err, app.ErrPriceChangeForbidden),
		errors.Is(err, app.ErrCriticalFieldsUpdateForbidden),
		errors.Is(err, app.ErrActivityMediaFileNotReady),
		errors.Is(err, app.ErrActivityMediaFileNotAllowed),
		errors.Is(err, app.ErrAttendanceQRUnavailable),
		errors.Is(err, app.ErrAttendanceQRInvalid),
		errors.Is(err, app.ErrAttendanceQRVersionInvalid),
		errors.Is(err, app.ErrAttendanceQRExpired),
		errors.Is(err, app.ErrAttendanceAlreadyCheckedIn),
		errors.Is(err, app.ErrAttendanceParticipantInvalid),

		errors.Is(err, model.ErrInvalidActivityTitle),
		errors.Is(err, model.ErrInvalidActivityDescription),
		errors.Is(err, model.ErrInvalidActivityFormat),
		errors.Is(err, model.ErrInvalidActivityStatus),
		errors.Is(err, model.ErrInvalidActivityVisibility),
		errors.Is(err, model.ErrInvalidActivityJoinMode),
		errors.Is(err, model.ErrInvalidActivityModerationStatus),
		errors.Is(err, model.ErrInvalidCategorySlug),
		errors.Is(err, model.ErrInvalidLanguageCode),
		errors.Is(err, model.ErrInvalidTimezone),
		errors.Is(err, model.ErrInvalidActivityTimeRange),
		errors.Is(err, model.ErrInvalidRegistrationDeadline),
		errors.Is(err, model.ErrActivityTooSoon),
		errors.Is(err, model.ErrInvalidCapacityType),
		errors.Is(err, model.ErrInvalidCapacity),
		errors.Is(err, model.ErrInvalidPriceType),
		errors.Is(err, model.ErrInvalidPrice),
		errors.Is(err, model.ErrInvalidCurrency),
		errors.Is(err, model.ErrInvalidMeetingURL),
		errors.Is(err, model.ErrInvalidOfflineLocation),
		errors.Is(err, model.ErrInvalidVisibilityPassword),
		errors.Is(err, model.ErrPriceLocked),
		errors.Is(err, model.ErrOnlyAuthorCanDuplicate),
		errors.Is(err, model.ErrActivityCannotBePublished),
		errors.Is(err, model.ErrCriticalFieldsLocked),
		errors.Is(err, app.ErrBlockedURLDetected),
		errors.Is(err, app.ErrSuspiciousURLRequiresReview),
		errors.Is(err, app.ErrActivityCreationRateLimited):
		writeError(w, http.StatusBadRequest, err.Error())

	case errors.Is(err, app.ErrActivityNotFound),
		errors.Is(err, app.ErrParticipantNotFound),
		errors.Is(err, app.ErrActivityMediaFileNotFound):
		writeError(w, http.StatusNotFound, err.Error())

	case errors.Is(err, app.ErrAttendanceAccessDenied):
		writeError(w, http.StatusForbidden, err.Error())

	case errors.Is(err, app.ErrActivityAlreadyPublished),
		errors.Is(err, app.ErrActivityAlreadyStarted),
		errors.Is(err, app.ErrActivityAlreadyCompleted),
		errors.Is(err, app.ErrActivityAlreadyCancelled),
		errors.Is(err, app.ErrParticipantScheduleConflict),
		errors.Is(err, app.ErrParticipantAlreadyCancelled),
		errors.Is(err, app.ErrModerationStateInvalid):
		writeError(w, http.StatusConflict, err.Error())

	default:
		writeError(w, http.StatusInternalServerError, fallback)
	}
}

func parseActorUserID(r *http.Request) (uuid.UUID, error) {
	raw := UserIDFromContext(r.Context())
	if raw == "" {
		return uuid.Nil, errors.New("missing user id")
	}
	return uuid.Parse(raw)
}

func parseRFC3339(v string) (time.Time, error) {
	return time.Parse(time.RFC3339, strings.TrimSpace(v))
}

func parseOptionalRFC3339(v *string) (*time.Time, error) {
	if v == nil || strings.TrimSpace(*v) == "" {
		return nil, nil
	}
	parsed, err := time.Parse(time.RFC3339, strings.TrimSpace(*v))
	if err != nil {
		return nil, err
	}
	t := parsed.UTC()
	return &t, nil
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

func parseIntOrDefault(v string, fallback int) int {
	if strings.TrimSpace(v) == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(strings.TrimSpace(v))
	if err != nil {
		return fallback
	}
	return parsed
}

func splitCSV(v string) []string {
	parts := strings.Split(v, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			result = append(result, part)
		}
	}
	return result
}

func valueOrDefaultBool(v *bool, fallback bool) bool {
	if v == nil {
		return fallback
	}
	return *v
}

func formatOptionalTime(v *time.Time) *string {
	if v == nil {
		return nil
	}
	s := v.UTC().Format(time.RFC3339)
	return &s
}

func formatOptionalUUID(v *uuid.UUID) *string {
	if v == nil {
		return nil
	}
	s := v.String()
	return &s
}

func selectCoverMedia(items []*model.ActivityMedia) *model.ActivityMedia {
	if len(items) == 0 {
		return nil
	}

	for _, item := range items {
		if item != nil && item.IsCover {
			return item
		}
	}

	return items[0]
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{
		"error": message,
	})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
