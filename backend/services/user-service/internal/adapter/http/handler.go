package http

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/transport/dto"
)

type Handler struct {
	useCase *app.UserUseCase
}

func NewHandler(useCase *app.UserUseCase) *Handler {
	return &Handler{useCase: useCase}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("POST /v1/users/me/init", h.InitMe)
	mux.HandleFunc("GET /v1/users/me", h.GetMe)
	mux.HandleFunc("PUT /v1/users/me/profile", h.UpdateMyProfile)
	mux.HandleFunc("GET /v1/users/", h.GetUserByID)
	mux.HandleFunc("PUT /v1/users/me/settings", h.UpdateMySettings)
	mux.HandleFunc("POST /v1/admin/users/", h.handleAdminActions)
	mux.HandleFunc("GET /v1/public/users", h.ListPublicProfiles)
}

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status": "ok",
	})
}

func (h *Handler) InitMe(w http.ResponseWriter, r *http.Request) {
	subject := strings.TrimSpace(SubjectFromContext(r.Context()))
	if subject == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated subject")
		return
	}

	var req dto.InitMeRequest
	if r.Body != nil {
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil && !errors.Is(err, io.EOF) {
			writeError(w, http.StatusBadRequest, "invalid request body")
			return
		}
	}

	aggregate, err := h.useCase.GetOrCreateBySubjectWithIdentity(
		r.Context(),
		app.InitUserInput{
			SubjectID: subject,
		},
		app.InitIdentityHints{
			PrimaryPhone: req.PrimaryPhone,
			PrimaryEmail: req.PrimaryEmail,
		},
	)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidSubjectID):
			writeError(w, http.StatusBadRequest, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to initialize user")
		}
		return
	}

	writeJSON(w, http.StatusOK, toInitMeResponse(aggregate))
}

func (h *Handler) GetMe(w http.ResponseWriter, r *http.Request) {
	subject := strings.TrimSpace(SubjectFromContext(r.Context()))
	if subject == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated subject")
		return
	}

	aggregate, err := h.useCase.GetAggregateBySubject(r.Context(), subject)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidSubjectID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to get current user")
		}
		return
	}

	writeJSON(w, http.StatusOK, toInitMeResponse(aggregate))
}

func (h *Handler) GetUserByID(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/users/")
	path = strings.Trim(path, "/")
	if path == "" || path == "me" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	userID, err := uuid.Parse(path)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid user id")
		return
	}

	aggregate, err := h.useCase.GetAggregateByUserID(r.Context(), userID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidUserID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to get user")
		}
		return
	}

	writeJSON(w, http.StatusOK, toInitMeResponse(aggregate))
}

func (h *Handler) UpdateMyProfile(w http.ResponseWriter, r *http.Request) {
	subject := strings.TrimSpace(SubjectFromContext(r.Context()))
	if subject == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated subject")
		return
	}

	aggregate, err := h.useCase.GetAggregateBySubject(r.Context(), subject)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to resolve current user")
		}
		return
	}

	var req dto.UpdateMyProfileRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	birthDate, err := parseOptionalDate(req.BirthDate)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid birthDate, expected YYYY-MM-DD")
		return
	}

	avatarFileID, err := parseOptionalUUID(req.AvatarFileID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid avatarFileId")
		return
	}

	cityID, err := parseOptionalUUID(req.CityID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid cityId")
		return
	}

	profile, err := h.useCase.UpdateProfile(r.Context(), app.UpdateProfileInput{
		UserID:       aggregate.User.ID,
		FirstName:    req.FirstName,
		LastName:     req.LastName,
		DisplayName:  req.DisplayName,
		Bio:          req.Bio,
		BirthDate:    birthDate,
		AvatarFileID: avatarFileID,
		CityID:       cityID,
		CountryCode:  req.CountryCode,
		Locale:       req.Locale,
		Timezone:     req.Timezone,
		Currency:     req.Currency,
		IsPublic:     req.IsPublic,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidUserID),
			errors.Is(err, model.ErrInvalidLocale),
			errors.Is(err, model.ErrInvalidTimezone),
			errors.Is(err, model.ErrInvalidCurrency):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrProfileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		case errors.Is(err, app.ErrInvalidUserID),
			errors.Is(err, model.ErrInvalidLocale),
			errors.Is(err, model.ErrInvalidTimezone),
			errors.Is(err, model.ErrInvalidCurrency),
			errors.Is(err, app.ErrAvatarFileNotFound),
			errors.Is(err, app.ErrAvatarFileNotReady),
			errors.Is(err, app.ErrAvatarFileNotAllowed):
			writeError(w, http.StatusBadRequest, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to update profile")
		}
		return
	}

	writeJSON(w, http.StatusOK, toUserProfileResponse(profile))
}

func toInitMeResponse(aggregate *app.UserAggregate) dto.InitMeResponse {
	roles := make([]string, 0, len(aggregate.Roles))
	for _, role := range aggregate.Roles {
		roles = append(roles, string(role.Role))
	}

	return dto.InitMeResponse{
		User:       toUserResponse(aggregate.User),
		Profile:    toUserProfileResponse(aggregate.Profile),
		Settings:   toUserSettingsResponse(aggregate.Settings),
		Reputation: toUserReputationResponse(aggregate.Reputation),
		Roles:      roles,
	}
}

func toUserResponse(user *model.User) dto.UserResponse {
	var deletedAt *string
	if user.DeletedAt != nil {
		v := user.DeletedAt.UTC().Format(time.RFC3339)
		deletedAt = &v
	}

	return dto.UserResponse{
		ID:            user.ID.String(),
		AuthSubjectID: user.AuthSubjectID,
		Status:        string(user.Status),
		PrimaryPhone:  user.PrimaryPhone,
		PrimaryEmail:  user.PrimaryEmail,
		IsDeleted:     user.IsDeleted,
		DeletedAt:     deletedAt,
		CreatedAt:     user.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:     user.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toUserProfileResponse(profile *model.UserProfile) dto.UserProfileResponse {
	var birthDate *string
	if profile.BirthDate != nil {
		v := profile.BirthDate.UTC().Format("2006-01-02")
		birthDate = &v
	}

	var avatarFileID *string
	if profile.AvatarFileID != nil {
		v := profile.AvatarFileID.String()
		avatarFileID = &v
	}

	var cityID *string
	if profile.CityID != nil {
		v := profile.CityID.String()
		cityID = &v
	}

	return dto.UserProfileResponse{
		UserID:       profile.UserID.String(),
		FirstName:    profile.FirstName,
		LastName:     profile.LastName,
		DisplayName:  profile.DisplayName,
		Bio:          profile.Bio,
		BirthDate:    birthDate,
		AvatarFileID: avatarFileID,
		CityID:       cityID,
		CountryCode:  profile.CountryCode,
		Locale:       profile.Locale,
		Timezone:     profile.Timezone,
		Currency:     profile.Currency,
		IsPublic:     profile.IsPublic,
		CreatedAt:    profile.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:    profile.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toUserSettingsResponse(settings *model.UserSettings) dto.UserSettingsResponse {
	return dto.UserSettingsResponse{
		UserID:                    settings.UserID.String(),
		NotificationsPushEnabled:  settings.NotificationsPushEnabled,
		NotificationsEmailEnabled: settings.NotificationsEmailEnabled,
		NotificationsSMSEnabled:   settings.NotificationsSMSEnabled,
		MarketingEnabled:          settings.MarketingEnabled,
		DarkModeEnabled:           settings.DarkModeEnabled,
		CreatedAt:                 settings.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:                 settings.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toUserReputationResponse(rep *model.UserReputation) dto.UserReputationResponse {
	return dto.UserReputationResponse{
		UserID:              rep.UserID.String(),
		TrustScore:          rep.TrustScore,
		RiskScore:           rep.RiskScore,
		CompletedBookings:   rep.CompletedBookings,
		CompletedActivities: rep.CompletedActivities,
		CancellationsCount:  rep.CancellationsCount,
		ReportsCount:        rep.ReportsCount,
		CreatedAt:           rep.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:           rep.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func parseOptionalUUID(v *string) (*uuid.UUID, error) {
	if v == nil || strings.TrimSpace(*v) == "" {
		return nil, nil
	}

	parsed, err := uuid.Parse(strings.TrimSpace(*v))
	if err != nil {
		return nil, err
	}
	return &parsed, nil
}

func parseOptionalDate(v *string) (*time.Time, error) {
	if v == nil || strings.TrimSpace(*v) == "" {
		return nil, nil
	}

	parsed, err := time.Parse("2006-01-02", strings.TrimSpace(*v))
	if err != nil {
		return nil, err
	}
	t := parsed.UTC()
	return &t, nil
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

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(statusCode int) {
	rw.statusCode = statusCode
	rw.ResponseWriter.WriteHeader(statusCode)
}

func userIDFromContext(ctx context.Context) *string {
	userID := strings.TrimSpace(UserIDFromContext(ctx))
	if userID == "" {
		return nil
	}
	return &userID
}

func (h *Handler) UpdateMySettings(w http.ResponseWriter, r *http.Request) {
	subject := strings.TrimSpace(SubjectFromContext(r.Context()))
	if subject == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated subject")
		return
	}

	aggregate, err := h.useCase.GetAggregateBySubject(r.Context(), subject)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to resolve current user")
		}
		return
	}

	var req dto.UpdateMySettingsRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	settings, err := h.useCase.UpdateSettings(r.Context(), aggregate.User.ID, model.UpdateUserSettingsParams{
		NotificationsPushEnabled:  req.NotificationsPushEnabled,
		NotificationsEmailEnabled: req.NotificationsEmailEnabled,
		NotificationsSMSEnabled:   req.NotificationsSMSEnabled,
		MarketingEnabled:          req.MarketingEnabled,
		DarkModeEnabled:           req.DarkModeEnabled,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidUserID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrSettingsNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to update settings")
		}
		return
	}

	writeJSON(w, http.StatusOK, toUserSettingsResponse(settings))
}

func (h *Handler) handleAdminActions(w http.ResponseWriter, r *http.Request) {
	if !hasRole(r.Context(), "ADMIN") {
		writeError(w, http.StatusForbidden, "admin role is required")
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/v1/admin/users/")
	path = strings.Trim(path, "/")
	parts := strings.Split(path, "/")
	if len(parts) != 2 || parts[1] != "roles" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	userID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid user id")
		return
	}

	if r.Method == http.MethodPost {
		h.GrantRole(w, r, userID)
		return
	}

	writeError(w, http.StatusNotFound, "not found")
}

func (h *Handler) GrantRole(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
	var req dto.GrantRoleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	role := enum.SystemRole(strings.TrimSpace(req.Role))

	var grantedBy *uuid.UUID
	if userIDStr := strings.TrimSpace(UserIDFromContext(r.Context())); userIDStr != "" {
		if parsed, err := uuid.Parse(userIDStr); err == nil {
			grantedBy = &parsed
		}
	}

	if err := h.useCase.GrantRole(r.Context(), userID, role, grantedBy); err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidUserID),
			errors.Is(err, model.ErrInvalidSystemRole):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrRoleAlreadyGranted):
			writeError(w, http.StatusConflict, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to grant role")
		}
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListPublicProfiles(w http.ResponseWriter, r *http.Request) {
	items, err := h.useCase.ListPublicProfiles(r.Context(), 20, 0)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list public profiles")
		return
	}

	resp := make([]dto.PublicProfileResponse, 0, len(items))
	for _, item := range items {
		var avatarFileID *string
		if item.AvatarFileID != nil {
			v := item.AvatarFileID.String()
			avatarFileID = &v
		}

		resp = append(resp, dto.PublicProfileResponse{
			UserID:       item.UserID.String(),
			DisplayName:  item.DisplayName,
			Bio:          item.Bio,
			AvatarFileID: avatarFileID,
			CountryCode:  item.CountryCode,
			Locale:       item.Locale,
			Timezone:     item.Timezone,
			IsPublic:     item.IsPublic,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"items": resp,
	})
}
