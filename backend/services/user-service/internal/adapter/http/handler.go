package http

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/app"
	"kz/inflap/backend/services/user-service/internal/domain/enum"
	"kz/inflap/backend/services/user-service/internal/domain/model"
	"kz/inflap/backend/services/user-service/internal/transport/dto"
)

type Handler struct {
	useCase           *app.UserUseCase
	phoneVerification *app.PhoneVerificationUseCase
}

func NewHandler(useCase *app.UserUseCase, phoneVerification ...*app.PhoneVerificationUseCase) *Handler {
	var phoneUseCase *app.PhoneVerificationUseCase
	if len(phoneVerification) > 0 {
		phoneUseCase = phoneVerification[0]
	}
	return &Handler{
		useCase:           useCase,
		phoneVerification: phoneUseCase,
	}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("POST /v1/users/me/init", h.InitMe)
	mux.HandleFunc("GET /v1/users/me/friends", h.ListMyFriends)
	mux.HandleFunc("GET /v1/users/me/friend-requests/incoming", h.ListMyIncomingFriendRequests)
	mux.HandleFunc("GET /v1/users/me/following", h.ListMyFollowing)
	mux.HandleFunc("GET /v1/users/me", h.GetMe)
	mux.HandleFunc("POST /v1/users/me/presence", h.UpdateMyPresence)
	mux.HandleFunc("PUT /v1/users/me/profile", h.UpdateMyProfile)
	mux.HandleFunc("POST /v1/users/me/phone/verification/start", h.StartMyPhoneVerification)
	mux.HandleFunc("POST /v1/users/me/phone/verification/verify", h.VerifyMyPhoneVerification)
	mux.HandleFunc("POST /v1/users/me/phone/verification/resend", h.ResendMyPhoneVerification)
	mux.HandleFunc("DELETE /v1/users/me/phone/pending", h.CancelMyPendingPhoneVerification)
	mux.HandleFunc("GET /v1/users/nickname-availability", h.CheckNicknameAvailability)
	mux.HandleFunc("GET /v1/users/", h.GetUserByID)
	mux.HandleFunc("POST /v1/users/", h.handleUserActions)
	mux.HandleFunc("DELETE /v1/users/", h.handleUserActions)
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

func (h *Handler) CheckNicknameAvailability(w http.ResponseWriter, r *http.Request) {
	subject := strings.TrimSpace(SubjectFromContext(r.Context()))
	if subject == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated subject")
		return
	}

	nickname := strings.TrimSpace(r.URL.Query().Get("nickname"))
	available, err := h.useCase.CheckNicknameAvailability(r.Context(), subject, nickname)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrNicknameRequired):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrInvalidSubjectID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to check nickname availability")
		}
		return
	}

	writeJSON(w, http.StatusOK, map[string]bool{
		"available": available,
	})
}

func (h *Handler) UpdateMyPresence(w http.ResponseWriter, r *http.Request) {
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
			writeError(w, http.StatusInternalServerError, "failed to resolve current user")
		}
		return
	}

	user, err := h.useCase.UpdateLastSeen(r.Context(), aggregate.User.ID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidUserID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to update presence")
		}
		return
	}

	writeJSON(w, http.StatusOK, toUserResponse(user))
}

func (h *Handler) StartMyPhoneVerification(w http.ResponseWriter, r *http.Request) {
	subject, ok := h.phoneVerificationSubject(w, r)
	if !ok {
		return
	}

	var req dto.StartPhoneVerificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	result, err := h.phoneVerification.Start(r.Context(), subject, req.Phone)
	if err != nil {
		h.writePhoneVerificationError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, toPhoneVerificationStartResponse(result))
}

func (h *Handler) VerifyMyPhoneVerification(w http.ResponseWriter, r *http.Request) {
	subject, ok := h.phoneVerificationSubject(w, r)
	if !ok {
		return
	}

	var req dto.VerifyPhoneVerificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	challengeID, err := uuid.Parse(strings.TrimSpace(req.ChallengeID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid challengeId")
		return
	}

	state, err := h.phoneVerification.Verify(
		r.Context(),
		subject,
		challengeID,
		req.Code,
	)
	if err != nil {
		h.writePhoneVerificationError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, toPhoneVerificationStateResponse(state))
}

func (h *Handler) ResendMyPhoneVerification(w http.ResponseWriter, r *http.Request) {
	subject, ok := h.phoneVerificationSubject(w, r)
	if !ok {
		return
	}

	var req dto.ResendPhoneVerificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	challengeID, err := uuid.Parse(strings.TrimSpace(req.ChallengeID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid challengeId")
		return
	}

	result, err := h.phoneVerification.Resend(r.Context(), subject, challengeID)
	if err != nil {
		h.writePhoneVerificationError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, toPhoneVerificationStartResponse(result))
}

func (h *Handler) CancelMyPendingPhoneVerification(w http.ResponseWriter, r *http.Request) {
	subject, ok := h.phoneVerificationSubject(w, r)
	if !ok {
		return
	}

	if err := h.phoneVerification.Cancel(r.Context(), subject); err != nil {
		h.writePhoneVerificationError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]bool{"cancelled": true})
}

func (h *Handler) phoneVerificationSubject(
	w http.ResponseWriter,
	r *http.Request,
) (string, bool) {
	if h.phoneVerification == nil {
		writeError(w, http.StatusServiceUnavailable, "phone verification is temporarily unavailable")
		return "", false
	}

	subject := strings.TrimSpace(SubjectFromContext(r.Context()))
	if subject == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated subject")
		return "", false
	}
	return subject, true
}

func (h *Handler) writePhoneVerificationError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, app.ErrInvalidSubjectID):
		writeError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, app.ErrPhoneRequired):
		writeError(w, http.StatusBadRequest, "phone is required")
	case errors.Is(err, app.ErrPhoneInvalid):
		writeError(w, http.StatusBadRequest, "invalid phone")
	case errors.Is(err, app.ErrPhoneAlreadyVerified):
		writeError(w, http.StatusConflict, "phone is already verified for this account")
	case errors.Is(err, app.ErrPhoneAlreadyTaken):
		writeError(w, http.StatusConflict, "phone is unavailable")
	case errors.Is(err, app.ErrPhoneVerificationNotFound):
		writeError(w, http.StatusNotFound, "phone verification challenge not found")
	case errors.Is(err, app.ErrPhoneVerificationExpired):
		writeError(w, http.StatusGone, "phone verification code expired")
	case errors.Is(err, app.ErrInvalidPhoneVerificationCode):
		writeError(w, http.StatusUnauthorized, "invalid phone verification code")
	case errors.Is(err, app.ErrPhoneVerificationLocked):
		writeError(w, http.StatusTooManyRequests, "phone verification locked")
	case errors.Is(err, app.ErrPhoneVerificationRateLimited):
		writeError(w, http.StatusTooManyRequests, "phone verification rate limited")
	case errors.Is(err, app.ErrUserNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	default:
		writeError(w, http.StatusInternalServerError, "phone verification failed")
	}
}

func (h *Handler) GetUserByID(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/users/")
	path = strings.Trim(path, "/")
	if path == "" || path == "me" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	parts := strings.Split(path, "/")
	if len(parts) == 2 && parts[1] == "followers" {
		userID, err := uuid.Parse(parts[0])
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid user id")
			return
		}
		h.ListFollowers(w, r, userID)
		return
	}
	if len(parts) != 1 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	userID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid user id")
		return
	}

	aggregate, err := h.useCase.GetAggregateByUserIDForSubject(
		r.Context(),
		userID,
		strings.TrimSpace(SubjectFromContext(r.Context())),
	)
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

func (h *Handler) ListFollowers(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
	limit := 20
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}

	offset := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("offset")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			offset = parsed
		}
	}

	page, err := h.useCase.ListFollowers(
		r.Context(),
		userID,
		limit,
		offset,
		r.URL.Query().Get("q"),
	)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidUserID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to list followers")
		}
		return
	}

	h.writeProfileConnectionsPage(w, page)
}

func (h *Handler) ListMyFriends(w http.ResponseWriter, r *http.Request) {
	currentUserID, ok := h.currentUserIDFromRequest(w, r)
	if !ok {
		return
	}

	page, err := h.useCase.ListFriends(
		r.Context(),
		currentUserID,
		parseProfileConnectionsListInput(r),
	)
	if err != nil {
		h.writeProfileConnectionsError(w, err, "failed to list friends")
		return
	}

	h.writeProfileConnectionsPage(w, page)
}

func (h *Handler) ListMyIncomingFriendRequests(w http.ResponseWriter, r *http.Request) {
	currentUserID, ok := h.currentUserIDFromRequest(w, r)
	if !ok {
		return
	}

	page, err := h.useCase.ListIncomingFriendRequests(
		r.Context(),
		currentUserID,
		parseProfileConnectionsListInput(r),
	)
	if err != nil {
		h.writeProfileConnectionsError(w, err, "failed to list incoming friend requests")
		return
	}

	h.writeFriendRequestsPage(w, page)
}

func (h *Handler) ListMyFollowing(w http.ResponseWriter, r *http.Request) {
	currentUserID, ok := h.currentUserIDFromRequest(w, r)
	if !ok {
		return
	}

	page, err := h.useCase.ListFollowing(
		r.Context(),
		currentUserID,
		parseProfileConnectionsListInput(r),
	)
	if err != nil {
		h.writeProfileConnectionsError(w, err, "failed to list following")
		return
	}

	h.writeProfileConnectionsPage(w, page)
}

func (h *Handler) currentUserIDFromRequest(
	w http.ResponseWriter,
	r *http.Request,
) (uuid.UUID, bool) {
	subject := strings.TrimSpace(SubjectFromContext(r.Context()))
	if subject == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated subject")
		return uuid.Nil, false
	}

	aggregate, err := h.useCase.GetAggregateBySubject(r.Context(), subject)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidSubjectID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to resolve current user")
		}
		return uuid.Nil, false
	}

	return aggregate.User.ID, true
}

func parseProfileConnectionsListInput(r *http.Request) app.ProfileConnectionsListInput {
	limit := 20
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}

	offset := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("offset")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			offset = parsed
		}
	}

	onlineOnly := false
	if raw := strings.TrimSpace(r.URL.Query().Get("onlineOnly")); raw != "" {
		onlineOnly = strings.EqualFold(raw, "true") || raw == "1"
	}

	return app.ProfileConnectionsListInput{
		Limit:         limit,
		Offset:        offset,
		SearchQuery:   r.URL.Query().Get("q"),
		Sort:          r.URL.Query().Get("sort"),
		SortDirection: r.URL.Query().Get("sortDirection"),
		OnlineOnly:    onlineOnly,
	}
}

func (h *Handler) writeProfileConnectionsError(
	w http.ResponseWriter,
	err error,
	message string,
) {
	switch {
	case errors.Is(err, app.ErrInvalidUserID):
		writeError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, app.ErrUserNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	default:
		writeError(w, http.StatusInternalServerError, message)
	}
}

func (h *Handler) writeProfileConnectionsPage(
	w http.ResponseWriter,
	page *app.FollowersPage,
) {
	resp := make([]dto.FollowersListItemResponse, 0, len(page.Items))
	for _, item := range page.Items {
		var avatarFileID *string
		if item.AvatarFileID != nil {
			v := item.AvatarFileID.String()
			avatarFileID = &v
		}
		var lastSeenAt *string
		if item.LastSeenAt != nil {
			v := item.LastSeenAt.UTC().Format(time.RFC3339)
			lastSeenAt = &v
		}

		resp = append(resp, dto.FollowersListItemResponse{
			UserID:       item.UserID.String(),
			Nickname:     item.Nickname,
			AvatarFileID: avatarFileID,
			IsOnline:     item.IsOnline,
			LastSeenAt:   lastSeenAt,
		})
	}

	writeJSON(w, http.StatusOK, dto.FollowersListResponse{
		Items:      resp,
		NextOffset: page.NextOffset,
	})
}

func (h *Handler) writeFriendRequestsPage(
	w http.ResponseWriter,
	page *app.FriendRequestsPage,
) {
	resp := make([]dto.FollowersListItemResponse, 0, len(page.Items))
	for _, item := range page.Items {
		if item == nil || item.Profile == nil {
			continue
		}

		var avatarFileID *string
		if item.Profile.AvatarFileID != nil {
			v := item.Profile.AvatarFileID.String()
			avatarFileID = &v
		}
		var lastSeenAt *string
		if item.Profile.LastSeenAt != nil {
			v := item.Profile.LastSeenAt.UTC().Format(time.RFC3339)
			lastSeenAt = &v
		}
		requestedAt := item.RequestedAt.UTC().Format(time.RFC3339)

		resp = append(resp, dto.FollowersListItemResponse{
			UserID:       item.Profile.UserID.String(),
			Nickname:     item.Profile.Nickname,
			AvatarFileID: avatarFileID,
			IsOnline:     item.Profile.IsOnline,
			LastSeenAt:   lastSeenAt,
			RequestedAt:  &requestedAt,
		})
	}

	writeJSON(w, http.StatusOK, dto.FollowersListResponse{
		Items:      resp,
		NextOffset: page.NextOffset,
	})
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

	updatedAggregate, err := h.useCase.UpdateProfile(r.Context(), aggregate.User.ID, app.UpdateProfileInput{
		UserID:       aggregate.User.ID,
		FirstName:    req.FirstName,
		LastName:     req.LastName,
		Nickname:     req.Nickname,
		Bio:          req.Bio,
		BirthDate:    birthDate,
		AvatarFileID: avatarFileID,
		CityID:       cityID,
		CountryCode:  req.CountryCode,
		Locale:       req.Locale,
		Timezone:     req.Timezone,
		Currency:     req.Currency,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidUserID),
			errors.Is(err, model.ErrInvalidLocale),
			errors.Is(err, model.ErrInvalidTimezone),
			errors.Is(err, model.ErrInvalidCurrency),
			errors.Is(err, app.ErrAvatarFileNotFound),
			errors.Is(err, app.ErrAvatarFileNotReady),
			errors.Is(err, app.ErrAvatarFileNotAllowed),
			errors.Is(err, app.ErrNicknameRequired),
			errors.Is(err, app.ErrNicknameImmutable),
			errors.Is(err, app.ErrNicknameAlreadyTaken):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrProfileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to update profile")
		}
		return
	}

	writeJSON(w, http.StatusOK, toInitMeResponse(updatedAggregate))
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
		Followers: dto.UserFollowResponse{
			Count:          aggregate.Followers.FollowersCount,
			IsFollowedByMe: aggregate.Followers.IsFollowedByMe,
		},
		Friendship: toUserFriendshipResponse(aggregate.Friendship),
	}
}

func toUserFriendshipResponse(friendship app.UserFriendshipSummary) dto.UserFriendshipResponse {
	status := friendship.Status
	if status == "" {
		status = app.FriendshipStatusNone
	}
	return dto.UserFriendshipResponse{Status: string(status)}
}

func toPhoneVerificationStartResponse(
	result *app.PhoneVerificationStartResult,
) dto.PhoneVerificationResponse {
	if result == nil {
		return dto.PhoneVerificationResponse{}
	}
	return dto.PhoneVerificationResponse{
		ChallengeID:        result.ChallengeID.String(),
		MaskedPhone:        result.MaskedPhone,
		ResendAfterSeconds: result.ResendAfterSeconds,
		ExpiresAt:          result.ExpiresAt.UTC().Format(time.RFC3339),
		Verified:           false,
	}
}

func toPhoneVerificationStateResponse(
	state *app.PhoneVerificationState,
) dto.PhoneVerificationResponse {
	if state == nil {
		return dto.PhoneVerificationResponse{}
	}
	resp := dto.PhoneVerificationResponse{
		MaskedPhone: state.MaskedPhone,
		Verified:    state.Verified,
	}
	if state.VerifiedAt != nil {
		resp.VerifiedAt = state.VerifiedAt.UTC().Format(time.RFC3339)
	}
	return resp
}

func toUserResponse(user *model.User) dto.UserResponse {
	var primaryPhoneMasked *string
	if user.PrimaryPhone != nil {
		if masked := app.MaskPhoneForDisplay(*user.PrimaryPhone); masked != "" {
			primaryPhoneMasked = &masked
		}
	}

	var primaryPhoneVerifiedAt *string
	if user.PrimaryPhoneVerifiedAt != nil {
		v := user.PrimaryPhoneVerifiedAt.UTC().Format(time.RFC3339)
		primaryPhoneVerifiedAt = &v
	}

	var deletedAt *string
	if user.DeletedAt != nil {
		v := user.DeletedAt.UTC().Format(time.RFC3339)
		deletedAt = &v
	}

	var lastSeenAt *string
	if user.LastSeenAt != nil {
		v := user.LastSeenAt.UTC().Format(time.RFC3339)
		lastSeenAt = &v
	}

	return dto.UserResponse{
		ID:                     user.ID.String(),
		AuthSubjectID:          user.AuthSubjectID,
		Status:                 string(user.Status),
		PrimaryPhone:           nil,
		PrimaryPhoneMasked:     primaryPhoneMasked,
		PrimaryPhoneVerified:   user.PrimaryPhoneVerifiedAt != nil,
		PrimaryPhoneVerifiedAt: primaryPhoneVerifiedAt,
		PrimaryEmail:           user.PrimaryEmail,
		IsDeleted:              user.IsDeleted,
		DeletedAt:              deletedAt,
		LastSeenAt:             lastSeenAt,
		CreatedAt:              user.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:              user.UpdatedAt.UTC().Format(time.RFC3339),
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
		UserID:             profile.UserID.String(),
		FirstName:          profile.FirstName,
		LastName:           profile.LastName,
		Nickname:           profile.Nickname,
		Bio:                profile.Bio,
		BirthDate:          birthDate,
		AvatarFileID:       avatarFileID,
		CityID:             cityID,
		CountryCode:        profile.CountryCode,
		Locale:             profile.Locale,
		Timezone:           profile.Timezone,
		Currency:           profile.Currency,
		IsProfileCompleted: profile.IsProfileCompleted,
		CreatedAt:          profile.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:          profile.UpdatedAt.UTC().Format(time.RFC3339),
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
	writeJSON(w, status, buildErrorResponse("user", status, message))
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

func (h *Handler) handleUserActions(w http.ResponseWriter, r *http.Request) {
	subject := strings.TrimSpace(SubjectFromContext(r.Context()))
	if subject == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated subject")
		return
	}

	currentUser, err := h.useCase.GetAggregateBySubject(r.Context(), subject)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to resolve current user")
		}
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/v1/users/")
	path = strings.Trim(path, "/")
	parts := strings.Split(path, "/")
	if len(parts) != 2 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	targetUserID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid user id")
		return
	}

	switch r.Method {
	case http.MethodPost:
		switch parts[1] {
		case "follow":
			h.FollowUser(w, r, currentUser.User.ID, targetUserID)
		case "friend-request":
			h.SendFriendRequest(w, r, currentUser.User.ID, targetUserID)
		case "friendship":
			h.AcceptFriendRequest(w, r, currentUser.User.ID, targetUserID)
		default:
			writeError(w, http.StatusNotFound, "not found")
		}
	case http.MethodDelete:
		switch parts[1] {
		case "follow":
			h.UnfollowUser(w, r, currentUser.User.ID, targetUserID)
		case "friend-request":
			h.CancelFriendRequest(w, r, currentUser.User.ID, targetUserID)
		case "friendship":
			h.RemoveFriend(w, r, currentUser.User.ID, targetUserID)
		default:
			writeError(w, http.StatusNotFound, "not found")
		}
	default:
		writeError(w, http.StatusNotFound, "not found")
	}
}

func (h *Handler) FollowUser(
	w http.ResponseWriter,
	r *http.Request,
	followerUserID uuid.UUID,
	followedUserID uuid.UUID,
) {
	if err := h.useCase.FollowUser(r.Context(), followerUserID, followedUserID); err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidUserID),
			errors.Is(err, app.ErrCannotFollowSelf):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrFollowFeatureUnavailable):
			writeError(w, http.StatusServiceUnavailable, err.Error())
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to follow user")
		}
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) UnfollowUser(
	w http.ResponseWriter,
	r *http.Request,
	followerUserID uuid.UUID,
	followedUserID uuid.UUID,
) {
	if err := h.useCase.UnfollowUser(r.Context(), followerUserID, followedUserID); err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidUserID),
			errors.Is(err, app.ErrCannotFollowSelf):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrFollowFeatureUnavailable):
			writeError(w, http.StatusServiceUnavailable, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to unfollow user")
		}
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) SendFriendRequest(
	w http.ResponseWriter,
	r *http.Request,
	requesterUserID uuid.UUID,
	addresseeUserID uuid.UUID,
) {
	summary, err := h.useCase.SendFriendRequest(r.Context(), requesterUserID, addresseeUserID)
	if err != nil {
		h.writeFriendshipActionError(w, err, "failed to send friend request")
		return
	}

	writeJSON(w, http.StatusOK, toUserFriendshipResponse(summary))
}

func (h *Handler) CancelFriendRequest(
	w http.ResponseWriter,
	r *http.Request,
	requesterUserID uuid.UUID,
	addresseeUserID uuid.UUID,
) {
	summary, err := h.useCase.CancelFriendRequest(r.Context(), requesterUserID, addresseeUserID)
	if err != nil {
		h.writeFriendshipActionError(w, err, "failed to cancel friend request")
		return
	}

	writeJSON(w, http.StatusOK, toUserFriendshipResponse(summary))
}

func (h *Handler) AcceptFriendRequest(
	w http.ResponseWriter,
	r *http.Request,
	addresseeUserID uuid.UUID,
	requesterUserID uuid.UUID,
) {
	summary, err := h.useCase.AcceptFriendRequest(r.Context(), addresseeUserID, requesterUserID)
	if err != nil {
		h.writeFriendshipActionError(w, err, "failed to accept friend request")
		return
	}

	writeJSON(w, http.StatusOK, toUserFriendshipResponse(summary))
}

func (h *Handler) RemoveFriend(
	w http.ResponseWriter,
	r *http.Request,
	viewerUserID uuid.UUID,
	targetUserID uuid.UUID,
) {
	summary, err := h.useCase.RemoveFriend(r.Context(), viewerUserID, targetUserID)
	if err != nil {
		h.writeFriendshipActionError(w, err, "failed to remove friend")
		return
	}

	writeJSON(w, http.StatusOK, toUserFriendshipResponse(summary))
}

func (h *Handler) writeFriendshipActionError(w http.ResponseWriter, err error, fallback string) {
	switch {
	case errors.Is(err, app.ErrInvalidUserID),
		errors.Is(err, app.ErrCannotFriendSelf):
		writeError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, app.ErrFriendshipFeatureUnavailable):
		writeError(w, http.StatusServiceUnavailable, err.Error())
	case errors.Is(err, app.ErrFriendRequestNotFound):
		writeError(w, http.StatusConflict, err.Error())
	case errors.Is(err, app.ErrUserNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	default:
		writeError(w, http.StatusInternalServerError, fallback)
	}
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
	if r.Method == http.MethodDelete {
		h.RevokeRole(w, r, userID)
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

func (h *Handler) RevokeRole(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
	var req dto.GrantRoleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	role := enum.SystemRole(strings.TrimSpace(req.Role))
	if err := h.useCase.RevokeRole(r.Context(), userID, role); err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidUserID),
			errors.Is(err, model.ErrInvalidSystemRole):
			writeError(w, http.StatusBadRequest, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to revoke role")
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
		var lastSeenAt *string
		if item.LastSeenAt != nil {
			v := item.LastSeenAt.UTC().Format(time.RFC3339)
			lastSeenAt = &v
		}

		resp = append(resp, dto.PublicProfileResponse{
			UserID:       item.UserID.String(),
			Nickname:     item.Nickname,
			Bio:          item.Bio,
			AvatarFileID: avatarFileID,
			CountryCode:  item.CountryCode,
			Locale:       item.Locale,
			Timezone:     item.Timezone,
			IsOnline:     item.IsOnline,
			LastSeenAt:   lastSeenAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"items": resp,
	})
}
