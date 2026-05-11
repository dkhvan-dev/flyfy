package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/transport/dto"
)

type Handler struct {
	useCase *app.GuideUseCase
}

func NewHandler(useCase *app.GuideUseCase) *Handler {
	return &Handler{useCase: useCase}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("POST /v1/guides/me/init", h.InitMyGuideProfile)
	mux.HandleFunc("GET /v1/guides/me", h.GetMyGuideProfile)
	mux.HandleFunc("PUT /v1/guides/me/profile", h.UpdateMyGuideProfile)
	mux.HandleFunc("POST /v1/guides/me/application", h.SubmitMyGuideApplication)
	mux.HandleFunc("POST /v1/guides/me/verification-requests", h.CreateMyVerificationRequest)
	mux.HandleFunc("POST /v1/guides/me/verification-requests/", h.AttachMyGuideDocument)
	mux.HandleFunc("GET /v1/guides/public", h.ListPublicGuides)
	mux.HandleFunc("GET /v1/guides/by-user/", h.GetGuideByUserID)
	mux.HandleFunc("GET /v1/guides/", h.GetGuideByID)
	mux.HandleFunc("POST /v1/admin/guides/verification-requests/", h.handleAdminVerificationActions)
	mux.HandleFunc("POST /v1/admin/guides/", h.handleAdminGuideActions)
	mux.HandleFunc("GET /v1/admin/guides/verification-requests", h.ListPendingVerificationRequests)
}

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status": "ok",
	})
}

func (h *Handler) InitMyGuideProfile(w http.ResponseWriter, r *http.Request) {
	userID, err := h.resolveCurrentUserID(r)
	if err != nil {
		h.handleCurrentUserError(w, err)
		return
	}

	var req dto.InitGuideProfileRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	aggregate, err := h.useCase.GetOrCreateGuideProfile(r.Context(), app.InitGuideProfileInput{
		UserID: userID,
		Type:   req.Type,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidGuideUserID),
			errors.Is(err, model.ErrInvalidGuideType):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to init guide profile")
		}
		return
	}

	writeJSON(w, http.StatusOK, toGuideAggregateResponse(aggregate))
}

func (h *Handler) GetMyGuideProfile(w http.ResponseWriter, r *http.Request) {
	userID, err := h.resolveCurrentUserID(r)
	if err != nil {
		h.handleCurrentUserError(w, err)
		return
	}

	aggregate, err := h.useCase.GetGuideAggregateByUserID(r.Context(), userID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidGuideUserID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrGuideProfileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to get guide profile")
		}
		return
	}

	writeJSON(w, http.StatusOK, toGuideAggregateResponse(aggregate))
}

func (h *Handler) UpdateMyGuideProfile(w http.ResponseWriter, r *http.Request) {
	aggregate, err := h.getCurrentGuideAggregate(r)
	if err != nil {
		handleGuideAggregateError(w, err)
		return
	}

	var req dto.UpdateGuideProfileRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	baseCityID, err := parseOptionalUUID(req.BaseCityID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid baseCityId")
		return
	}

	langs := make([]app.GuideLanguageInput, 0, len(req.Languages))
	for _, item := range req.Languages {
		langs = append(langs, app.GuideLanguageInput{
			LanguageCode:     item.LanguageCode,
			ProficiencyLevel: item.ProficiencyLevel,
		})
	}

	specs := make([]app.GuideSpecializationInput, 0, len(req.Specializations))
	for _, item := range req.Specializations {
		specs = append(specs, app.GuideSpecializationInput{
			SpecializationCode: item.SpecializationCode,
		})
	}

	updated, err := h.useCase.UpdateGuideProfile(r.Context(), app.UpdateGuideProfileInput{
		ProfileID:               aggregate.Profile.ID,
		Headline:                req.Headline,
		About:                   req.About,
		ExperienceYears:         req.ExperienceYears,
		BaseCityID:              baseCityID,
		IsPrivateGuideAvailable: req.IsPrivateGuideAvailable,
		IsActivityHostAvailable: req.IsActivityHostAvailable,
		IsTourGuideAvailable:    req.IsTourGuideAvailable,
		Languages:               langs,
		Specializations:         specs,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidGuideProfileID),
			errors.Is(err, model.ErrInvalidExperienceYears),
			errors.Is(err, model.ErrInvalidGuideLanguageCode),
			errors.Is(err, model.ErrInvalidGuideLanguageProficiencyLevel),
			errors.Is(err, model.ErrInvalidGuideSpecializationCode):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrGuideProfileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to update guide profile")
		}
		return
	}

	writeJSON(w, http.StatusOK, toGuideAggregateResponse(updated))
}

func (h *Handler) CreateMyVerificationRequest(w http.ResponseWriter, r *http.Request) {
	aggregate, err := h.getCurrentGuideAggregate(r)
	if err != nil {
		handleGuideAggregateError(w, err)
		return
	}

	var req dto.CreateVerificationRequestRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	item, err := h.useCase.CreateVerificationRequest(r.Context(), app.CreateVerificationRequestInput{
		GuideProfileID: aggregate.Profile.ID,
		Comment:        req.Comment,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidGuideProfileID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrGuideProfileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to create verification request")
		}
		return
	}

	writeJSON(w, http.StatusCreated, toVerificationRequestResponse(item))
}

func (h *Handler) SubmitMyGuideApplication(w http.ResponseWriter, r *http.Request) {
	userID, err := h.resolveCurrentUserID(r)
	if err != nil {
		h.handleCurrentUserError(w, err)
		return
	}

	var req dto.SubmitGuideApplicationRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	baseCityID, err := parseOptionalUUID(req.BaseCityID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid baseCityId")
		return
	}

	identityDocumentFileID, err := uuid.Parse(strings.TrimSpace(req.IdentityDocumentFileID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid identityDocumentFileId")
		return
	}

	professionalDocumentFileID, err := uuid.Parse(strings.TrimSpace(req.ProfessionalDocumentFileID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid professionalDocumentFileId")
		return
	}

	firstAidCertificateFileID, err := parseOptionalUUID(req.FirstAidCertificateFileID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid firstAidCertificateFileId")
		return
	}

	languageCertificateFileID, err := parseOptionalUUID(req.LanguageCertificateFileID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid languageCertificateFileId")
		return
	}

	aggregate, err := h.useCase.SubmitGuideApplication(r.Context(), app.SubmitGuideApplicationInput{
		UserID:                     userID,
		Type:                       req.Type,
		Headline:                   req.Headline,
		About:                      req.About,
		ExperienceYears:            req.ExperienceYears,
		BaseCityID:                 baseCityID,
		IsPrivateGuideAvailable:    req.IsPrivateGuideAvailable,
		IsActivityHostAvailable:    req.IsActivityHostAvailable,
		IsTourGuideAvailable:       req.IsTourGuideAvailable,
		Comment:                    req.Comment,
		IdentityDocumentFileID:     identityDocumentFileID,
		IdentityDocumentType:       req.IdentityDocumentType,
		ProfessionalDocumentFileID: professionalDocumentFileID,
		ProfessionalDocumentType:   req.ProfessionalDocumentType,
		FirstAidCertificateFileID:  firstAidCertificateFileID,
		LanguageCertificateFileID:  languageCertificateFileID,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidGuideUserID),
			errors.Is(err, model.ErrInvalidGuideType),
			errors.Is(err, model.ErrInvalidExperienceYears),
			errors.Is(err, model.ErrInvalidGuideDocumentType),
			errors.Is(err, app.ErrGuideDocumentFileNotFound),
			errors.Is(err, app.ErrGuideDocumentFileNotReady),
			errors.Is(err, app.ErrGuideDocumentFileNotAllowed),
			errors.Is(err, app.ErrGuideDocumentsRequired):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrGuideApplicationPending),
			errors.Is(err, app.ErrGuideProfileAlreadyActive):
			writeError(w, http.StatusConflict, err.Error())
		case errors.Is(err, app.ErrUserNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			log.Error().
				Err(err).
				Str("request_id", RequestIDFromContext(r.Context())).
				Str("user_id", userID.String()).
				Msg("failed to submit guide application")
			writeError(w, http.StatusInternalServerError, "failed to submit guide application")
		}
		return
	}

	writeJSON(w, http.StatusCreated, toGuideAggregateResponse(aggregate))
}

func (h *Handler) AttachMyGuideDocument(w http.ResponseWriter, r *http.Request) {
	userID, err := h.resolveCurrentUserID(r)
	if err != nil {
		h.handleCurrentUserError(w, err)
		return
	}

	aggregate, err := h.useCase.GetGuideAggregateByUserID(r.Context(), userID)
	if err != nil {
		handleGuideAggregateError(w, err)
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/v1/guides/me/verification-requests/")
	path = strings.Trim(path, "/")
	parts := strings.Split(path, "/")
	if len(parts) != 2 || parts[1] != "documents" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	requestID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid verification request id")
		return
	}

	if aggregate.VerificationRequest == nil || aggregate.VerificationRequest.ID != requestID {
		writeError(w, http.StatusNotFound, "verification request not found")
		return
	}

	var req dto.AttachGuideDocumentRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	fileID, err := uuid.Parse(strings.TrimSpace(req.FileID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid fileId")
		return
	}

	doc, err := h.useCase.AttachGuideDocument(r.Context(), app.AttachGuideDocumentInput{
		VerificationRequestID: requestID,
		FileID:                fileID,
		DocumentType:          req.DocumentType,
		CreatedByUserID:       &userID,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrGuideDocumentFileNotFound),
			errors.Is(err, app.ErrGuideDocumentFileNotReady),
			errors.Is(err, app.ErrGuideDocumentFileNotAllowed),
			errors.Is(err, model.ErrInvalidGuideDocumentType):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrVerificationRequestNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to attach guide document")
		}
		return
	}

	writeJSON(w, http.StatusCreated, toGuideDocumentResponse(doc))
}

func (h *Handler) ListPublicGuides(w http.ResponseWriter, r *http.Request) {
	input, err := parsePublicGuideListInput(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	result, err := h.useCase.ListPublicGuideCards(r.Context(), input)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list public guides")
		return
	}

	resp := make([]dto.PublicGuideCardResponse, 0, len(result.Items))
	for _, item := range result.Items {
		resp = append(resp, toPublicGuideCardResponse(item))
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"items":  resp,
		"total":  result.Total,
		"limit":  result.Limit,
		"offset": result.Offset,
	})
}

func (h *Handler) GetGuideByID(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/guides/")
	path = strings.Trim(path, "/")
	if path == "" || path == "me" || path == "public" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	profileID, err := uuid.Parse(path)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid guide profile id")
		return
	}

	aggregate, err := h.useCase.GetGuideAggregateByProfileID(r.Context(), profileID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidGuideProfileID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrGuideProfileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to get guide profile")
		}
		return
	}

	writeJSON(w, http.StatusOK, toGuideAggregateResponse(aggregate))
}

func (h *Handler) GetGuideByUserID(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/guides/by-user/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	userID, err := uuid.Parse(path)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid user id")
		return
	}

	aggregate, err := h.useCase.GetGuideAggregateByUserID(r.Context(), userID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidGuideUserID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrGuideProfileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to get guide profile")
		}
		return
	}

	writeJSON(w, http.StatusOK, toGuideAggregateResponse(aggregate))
}

func (h *Handler) getCurrentGuideAggregate(r *http.Request) (*app.GuideAggregate, error) {
	userID, err := h.resolveCurrentUserID(r)
	if err != nil {
		return nil, err
	}
	return h.useCase.GetGuideAggregateByUserID(r.Context(), userID)
}

func (h *Handler) resolveCurrentUserID(r *http.Request) (uuid.UUID, error) {
	subject := strings.TrimSpace(SubjectFromContext(r.Context()))
	if subject == "" {
		return uuid.Nil, errors.New("missing authenticated subject")
	}

	return h.useCase.ResolveUserIDBySubject(r.Context(), subject)
}

func (h *Handler) handleCurrentUserError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, app.ErrUserNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, app.ErrInvalidGuideUserID):
		writeError(w, http.StatusBadRequest, err.Error())
	default:
		writeError(w, http.StatusUnauthorized, "missing authenticated user id")
	}
}

func handleGuideAggregateError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, app.ErrInvalidGuideUserID):
		writeError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, app.ErrUserNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, app.ErrGuideProfileNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	default:
		writeError(w, http.StatusInternalServerError, "failed to resolve current guide profile")
	}
}

func toGuideAggregateResponse(aggregate *app.GuideAggregate) dto.GuideAggregateResponse {
	resp := dto.GuideAggregateResponse{
		Profile:         toGuideProfileResponse(aggregate.Profile),
		Documents:       make([]dto.GuideDocumentResponse, 0, len(aggregate.Documents)),
		Languages:       make([]dto.GuideLanguageResponse, 0, len(aggregate.Languages)),
		Specializations: make([]dto.GuideSpecializationResponse, 0, len(aggregate.Specializations)),
	}

	if aggregate.VerificationRequest != nil {
		item := toVerificationRequestResponse(aggregate.VerificationRequest)
		resp.VerificationRequest = &item
	}

	for _, item := range aggregate.Documents {
		resp.Documents = append(resp.Documents, toGuideDocumentResponse(item))
	}
	for _, item := range aggregate.Languages {
		resp.Languages = append(resp.Languages, toGuideLanguageResponse(item))
	}
	for _, item := range aggregate.Specializations {
		resp.Specializations = append(resp.Specializations, toGuideSpecializationResponse(item))
	}

	return resp
}

func toPublicGuideCardResponse(item *app.PublicGuideCard) dto.PublicGuideCardResponse {
	card := dto.PublicGuideCardResponse{
		GuideProfile:    toGuideProfileResponse(item.GuideProfile),
		Languages:       make([]dto.GuideLanguageResponse, 0, len(item.Languages)),
		Specializations: make([]dto.GuideSpecializationResponse, 0, len(item.Specializations)),
	}

	for _, lang := range item.Languages {
		card.Languages = append(card.Languages, toGuideLanguageResponse(lang))
	}
	for _, spec := range item.Specializations {
		card.Specializations = append(card.Specializations, toGuideSpecializationResponse(spec))
	}

	if item.UserProfile != nil {
		var avatarFileID *string
		if item.UserProfile.AvatarFileID != nil {
			v := item.UserProfile.AvatarFileID.String()
			avatarFileID = &v
		}

		card.UserProfile = &dto.PublicUserCard{
			UserID:       item.UserProfile.UserID.String(),
			DisplayName:  item.UserProfile.DisplayName,
			AvatarFileID: avatarFileID,
			CountryCode:  item.UserProfile.CountryCode,
			Locale:       item.UserProfile.Locale,
			Timezone:     item.UserProfile.Timezone,
			IsPublic:     item.UserProfile.IsPublic,
		}
	}

	return card
}

func toGuideProfileResponse(profile *model.GuideProfile) dto.GuideProfileResponse {
	var baseCityID *string
	if profile.BaseCityID != nil {
		v := profile.BaseCityID.String()
		baseCityID = &v
	}

	return dto.GuideProfileResponse{
		ID:                      profile.ID.String(),
		UserID:                  profile.UserID.String(),
		Type:                    string(profile.Type),
		Status:                  string(profile.Status),
		Headline:                profile.Headline,
		About:                   profile.About,
		ExperienceYears:         profile.ExperienceYears,
		BaseCityID:              baseCityID,
		IsPrivateGuideAvailable: profile.IsPrivateGuideAvailable,
		IsActivityHostAvailable: profile.IsActivityHostAvailable,
		IsTourGuideAvailable:    profile.IsTourGuideAvailable,
		RatingAvg:               profile.RatingAvg,
		ReviewsCount:            profile.ReviewsCount,
		CreatedAt:               profile.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:               profile.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toVerificationRequestResponse(item *model.GuideVerificationRequest) dto.GuideVerificationRequestResponse {
	var submittedAt *string
	if item.SubmittedAt != nil {
		v := item.SubmittedAt.UTC().Format(time.RFC3339)
		submittedAt = &v
	}

	var reviewedAt *string
	if item.ReviewedAt != nil {
		v := item.ReviewedAt.UTC().Format(time.RFC3339)
		reviewedAt = &v
	}

	var reviewedBy *string
	if item.ReviewedBy != nil {
		v := item.ReviewedBy.String()
		reviewedBy = &v
	}

	return dto.GuideVerificationRequestResponse{
		ID:             item.ID.String(),
		GuideProfileID: item.GuideProfileID.String(),
		Status:         string(item.Status),
		Comment:        item.Comment,
		ReviewComment:  item.ReviewComment,
		SubmittedAt:    submittedAt,
		ReviewedAt:     reviewedAt,
		ReviewedBy:     reviewedBy,
		CreatedAt:      item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:      item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toGuideDocumentResponse(item *model.GuideDocument) dto.GuideDocumentResponse {
	return dto.GuideDocumentResponse{
		ID:                    item.ID.String(),
		VerificationRequestID: item.VerificationRequestID.String(),
		FileID:                item.FileID.String(),
		DocumentType:          item.DocumentType,
		CreatedAt:             item.CreatedAt.UTC().Format(time.RFC3339),
	}
}

func toGuideLanguageResponse(item *model.GuideLanguage) dto.GuideLanguageResponse {
	return dto.GuideLanguageResponse{
		ID:               item.ID.String(),
		GuideProfileID:   item.GuideProfileID.String(),
		LanguageCode:     item.LanguageCode,
		ProficiencyLevel: item.ProficiencyLevel,
		CreatedAt:        item.CreatedAt.UTC().Format(time.RFC3339),
	}
}

func toGuideSpecializationResponse(item *model.GuideSpecialization) dto.GuideSpecializationResponse {
	return dto.GuideSpecializationResponse{
		ID:                 item.ID.String(),
		GuideProfileID:     item.GuideProfileID.String(),
		SpecializationCode: item.SpecializationCode,
		CreatedAt:          item.CreatedAt.UTC().Format(time.RFC3339),
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

func parsePublicGuideListInput(r *http.Request) (app.ListPublicGuidesInput, error) {
	q := r.URL.Query()

	limit, err := parseOptionalIntQuery(q.Get("limit"), "limit")
	if err != nil {
		return app.ListPublicGuidesInput{}, err
	}
	offset, err := parseOptionalIntQuery(q.Get("offset"), "offset")
	if err != nil {
		return app.ListPublicGuidesInput{}, err
	}

	var minRating *float64
	if raw := strings.TrimSpace(q.Get("minRating")); raw != "" {
		parsed, parseErr := strconv.ParseFloat(raw, 64)
		if parseErr != nil || parsed < 0 || parsed > 5 {
			return app.ListPublicGuidesInput{}, errors.New("invalid minRating")
		}
		minRating = &parsed
	}

	var minExperienceYears *int
	if raw := strings.TrimSpace(q.Get("minExperienceYears")); raw != "" {
		parsed, parseErr := strconv.Atoi(raw)
		if parseErr != nil || parsed < 0 {
			return app.ListPublicGuidesInput{}, errors.New("invalid minExperienceYears")
		}
		minExperienceYears = &parsed
	}

	return app.ListPublicGuidesInput{
		Query:               q.Get("q"),
		CountryCodes:        splitQueryList(q["countries"]),
		LanguageCodes:       splitQueryList(q["languages"]),
		SpecializationCodes: splitQueryList(q["specializations"]),
		MinRating:           minRating,
		MinExperienceYears:  minExperienceYears,
		Sort:                q.Get("sort"),
		Limit:               limit,
		Offset:              offset,
	}, nil
}

func parseOptionalIntQuery(raw string, field string) (int, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return 0, nil
	}

	parsed, err := strconv.Atoi(raw)
	if err != nil || parsed < 0 {
		return 0, errors.New("invalid " + field)
	}
	return parsed, nil
}

func splitQueryList(values []string) []string {
	result := make([]string, 0, len(values))
	for _, rawValue := range values {
		for _, part := range strings.Split(rawValue, ",") {
			item := strings.TrimSpace(part)
			if item != "" {
				result = append(result, item)
			}
		}
	}
	return result
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

func (h *Handler) handleAdminVerificationActions(w http.ResponseWriter, r *http.Request) {
	if !hasRole(r.Context(), "ADMIN") && !hasRole(r.Context(), "MODERATOR") {
		writeError(w, http.StatusForbidden, "admin or moderator role is required")
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/v1/admin/guides/verification-requests/")
	path = strings.Trim(path, "/")
	parts := strings.Split(path, "/")
	if len(parts) != 2 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	requestID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid verification request id")
		return
	}

	switch {
	case r.Method == http.MethodPost && parts[1] == "approve":
		h.ApproveVerificationRequest(w, r, requestID)
		return
	case r.Method == http.MethodPost && parts[1] == "reject":
		h.RejectVerificationRequest(w, r, requestID)
		return
	default:
		writeError(w, http.StatusNotFound, "not found")
		return
	}
}

func (h *Handler) handleAdminGuideActions(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/admin/guides/")
	path = strings.Trim(path, "/")
	parts := strings.Split(path, "/")
	if len(parts) != 2 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	profileID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid guide profile id")
		return
	}

	switch {
	case r.Method == http.MethodPost && parts[1] == "suspend":
		if !hasRole(r.Context(), "ADMIN") && !hasRole(r.Context(), "MODERATOR") {
			writeError(w, http.StatusForbidden, "admin or moderator role is required")
			return
		}
		h.SuspendGuideProfile(w, r, profileID)
		return

	case r.Method == http.MethodPost && parts[1] == "activate":
		if !hasRole(r.Context(), "ADMIN") {
			writeError(w, http.StatusForbidden, "admin role is required")
			return
		}
		h.ActivateGuideProfile(w, r, profileID)
		return

	default:
		writeError(w, http.StatusNotFound, "not found")
		return
	}
}

func (h *Handler) ApproveVerificationRequest(w http.ResponseWriter, r *http.Request, requestID uuid.UUID) {
	var req dto.ReviewVerificationRequestRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil && err.Error() != "EOF" {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	reviewerID := reviewerIDFromContext(r.Context())

	aggregate, err := h.useCase.ApproveVerificationRequest(r.Context(), app.ReviewVerificationRequestInput{
		VerificationRequestID: requestID,
		ReviewerID:            reviewerID,
		ReviewComment:         req.ReviewComment,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrVerificationRequestNotFound),
			errors.Is(err, app.ErrGuideProfileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to approve verification request")
		}
		return
	}

	writeJSON(w, http.StatusOK, toGuideAggregateResponse(aggregate))
}

func (h *Handler) RejectVerificationRequest(w http.ResponseWriter, r *http.Request, requestID uuid.UUID) {
	var req dto.ReviewVerificationRequestRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil && err.Error() != "EOF" {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	reviewerID := reviewerIDFromContext(r.Context())

	aggregate, err := h.useCase.RejectVerificationRequest(r.Context(), app.ReviewVerificationRequestInput{
		VerificationRequestID: requestID,
		ReviewerID:            reviewerID,
		ReviewComment:         req.ReviewComment,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrVerificationRequestNotFound),
			errors.Is(err, app.ErrGuideProfileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to reject verification request")
		}
		return
	}

	writeJSON(w, http.StatusOK, toGuideAggregateResponse(aggregate))
}

func (h *Handler) SuspendGuideProfile(w http.ResponseWriter, r *http.Request, profileID uuid.UUID) {
	aggregate, err := h.useCase.SuspendGuideProfile(r.Context(), profileID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidGuideProfileID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrGuideProfileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to suspend guide profile")
		}
		return
	}

	writeJSON(w, http.StatusOK, toGuideAggregateResponse(aggregate))
}

func (h *Handler) ActivateGuideProfile(w http.ResponseWriter, r *http.Request, profileID uuid.UUID) {
	aggregate, err := h.useCase.ActivateGuideProfile(r.Context(), profileID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidGuideProfileID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrGuideProfileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to activate guide profile")
		}
		return
	}

	writeJSON(w, http.StatusOK, toGuideAggregateResponse(aggregate))
}

func reviewerIDFromContext(ctx context.Context) *uuid.UUID {
	raw := strings.TrimSpace(UserIDFromContext(ctx))
	if raw == "" {
		return nil
	}

	parsed, err := uuid.Parse(raw)
	if err != nil {
		return nil
	}
	return &parsed
}

func (h *Handler) ListPendingVerificationRequests(w http.ResponseWriter, r *http.Request) {
	if !hasRole(r.Context(), "ADMIN") && !hasRole(r.Context(), "MODERATOR") {
		writeError(w, http.StatusForbidden, "admin or moderator role is required")
		return
	}

	items, err := h.useCase.ListPendingVerificationRequests(r.Context(), 20, 0)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list pending verification requests")
		return
	}

	resp := make([]dto.VerificationQueueItemResponse, 0, len(items))
	for _, item := range items {
		var submittedAt *string
		if item.SubmittedAt != nil {
			v := item.SubmittedAt.UTC().Format(time.RFC3339)
			submittedAt = &v
		}

		resp = append(resp, dto.VerificationQueueItemResponse{
			ID:             item.ID.String(),
			GuideProfileID: item.GuideProfileID.String(),
			Status:         string(item.Status),
			Comment:        item.Comment,
			SubmittedAt:    submittedAt,
			CreatedAt:      item.CreatedAt.UTC().Format(time.RFC3339),
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"items": resp,
	})
}
