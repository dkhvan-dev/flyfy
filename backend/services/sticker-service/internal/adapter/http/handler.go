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

	"kz/inflap/backend/services/sticker-service/internal/app"
	"kz/inflap/backend/services/sticker-service/internal/domain/model"
)

type stickerUseCase interface {
	ListDefaultPacks(ctx context.Context) ([]*model.StickerPackWithStickers, error)
	ListOfficialCatalog(ctx context.Context, input app.ListOfficialCatalogInput) (*app.OfficialCatalogOutput, error)
	ListPackStickers(ctx context.Context, input app.ListPackStickersInput) (*app.StickerListOutput, error)
	SearchOfficialStickers(ctx context.Context, input app.SearchOfficialStickersInput) (*app.StickerListOutput, error)
	ListRecentStickers(ctx context.Context, input app.ListRecentStickersInput) (*app.StickerListOutput, error)
	ListMyPacks(ctx context.Context, userID string) ([]*model.StickerPackWithStickers, error)
	EnsureMyCustomPack(ctx context.Context, userID string) (*model.StickerPack, error)
	InstallPack(ctx context.Context, input app.InstallStickerPackInput) error
	RemovePack(ctx context.Context, input app.RemoveStickerPackInput) error
	CreateStickerUploadRequest(
		ctx context.Context,
		input app.CreateStickerUploadInput,
	) (*app.CreateStickerUploadOutput, error)
	FinalizeStickerUpload(ctx context.Context, input app.FinalizeStickerUploadInput) (*model.Sticker, error)
	ValidateSend(ctx context.Context, input app.ValidateStickerSendInput) (*app.ValidateStickerSendOutput, error)
}

type Handler struct {
	useCase              stickerUseCase
	internalServiceToken string
}

func NewHandler(useCase stickerUseCase, internalServiceToken string) *Handler {
	return &Handler{
		useCase:              useCase,
		internalServiceToken: strings.TrimSpace(internalServiceToken),
	}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /v1/stickers/catalog", h.ListOfficialCatalog)
	mux.HandleFunc("GET /v1/stickers/packs/{packID}/stickers", h.ListPackStickers)
	mux.HandleFunc("GET /v1/stickers/search", h.SearchOfficialStickers)
	mux.HandleFunc("GET /v1/stickers/recent", h.ListRecentStickers)
	mux.HandleFunc("GET /v1/sticker-packs/default", h.ListDefaultPacks)
	mux.HandleFunc("GET /v1/sticker-packs/my", h.ListMyPacks)
	mux.HandleFunc("POST /v1/sticker-packs/my/custom", h.EnsureMyCustomPack)
	mux.HandleFunc("POST /v1/sticker-packs/{packID}/install", h.InstallPack)
	mux.HandleFunc("DELETE /v1/sticker-packs/{packID}/install", h.RemovePack)
	mux.HandleFunc("POST /v1/sticker-packs/{packID}/upload-requests", h.CreateStickerUploadRequest)
	mux.HandleFunc("POST /v1/sticker-packs/{packID}/uploads/{uploadSessionID}/finalize", h.FinalizeStickerUpload)
	mux.HandleFunc("POST /v1/internal/stickers/validate-send", h.ValidateSend)
	mux.HandleFunc("POST /internal/v1/stickers/validate-send", h.ValidateSend)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) ListDefaultPacks(w http.ResponseWriter, r *http.Request) {
	packs, err := h.useCase.ListDefaultPacks(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list sticker packs")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"packs": toPackResponses(packs)})
}

func (h *Handler) ListOfficialCatalog(w http.ResponseWriter, r *http.Request) {
	if UserIDFromContext(r.Context()) == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return
	}

	catalog, err := h.useCase.ListOfficialCatalog(r.Context(), app.ListOfficialCatalogInput{
		Locale: r.URL.Query().Get("locale"),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, toOfficialCatalogResponse(catalog))
}

func (h *Handler) ListPackStickers(w http.ResponseWriter, r *http.Request) {
	userID := UserIDFromContext(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return
	}

	result, err := h.useCase.ListPackStickers(r.Context(), app.ListPackStickersInput{
		UserID: userID,
		PackID: r.PathValue("packID"),
		Limit:  queryInt(r, "limit", 50),
		Offset: queryInt(r, "offset", 0),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, toStickerListResponse(result))
}

func (h *Handler) SearchOfficialStickers(w http.ResponseWriter, r *http.Request) {
	userID := UserIDFromContext(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return
	}

	result, err := h.useCase.SearchOfficialStickers(r.Context(), app.SearchOfficialStickersInput{
		UserID: userID,
		Query:  r.URL.Query().Get("q"),
		Locale: r.URL.Query().Get("locale"),
		Limit:  queryInt(r, "limit", 50),
		Offset: queryInt(r, "offset", 0),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, toStickerListResponse(result))
}

func (h *Handler) ListRecentStickers(w http.ResponseWriter, r *http.Request) {
	userID := UserIDFromContext(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return
	}

	result, err := h.useCase.ListRecentStickers(r.Context(), app.ListRecentStickersInput{
		UserID: userID,
		Limit:  queryInt(r, "limit", 40),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, toStickerListResponse(result))
}

func (h *Handler) ListMyPacks(w http.ResponseWriter, r *http.Request) {
	userID := UserIDFromContext(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return
	}

	packs, err := h.useCase.ListMyPacks(r.Context(), userID)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"packs": toPackResponses(packs)})
}

func (h *Handler) EnsureMyCustomPack(w http.ResponseWriter, r *http.Request) {
	userID := UserIDFromContext(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return
	}

	pack, err := h.useCase.EnsureMyCustomPack(r.Context(), userID)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, toPackResponse(&model.StickerPackWithStickers{Pack: pack}))
}

func (h *Handler) InstallPack(w http.ResponseWriter, r *http.Request) {
	userID := UserIDFromContext(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return
	}

	if err := h.useCase.InstallPack(r.Context(), app.InstallStickerPackInput{
		UserID: userID,
		PackID: r.PathValue("packID"),
	}); err != nil {
		writeAppError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemovePack(w http.ResponseWriter, r *http.Request) {
	userID := UserIDFromContext(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return
	}

	if err := h.useCase.RemovePack(r.Context(), app.RemoveStickerPackInput{
		UserID: userID,
		PackID: r.PathValue("packID"),
	}); err != nil {
		writeAppError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

type createStickerUploadRequest struct {
	OriginalName string `json:"originalName"`
	ContentType  string `json:"contentType"`
	SizeBytes    int64  `json:"sizeBytes"`
}

type createStickerUploadResponse struct {
	UploadSessionID string            `json:"uploadSessionId"`
	FileID          string            `json:"fileId"`
	Method          string            `json:"method"`
	URL             string            `json:"url"`
	Headers         map[string]string `json:"headers"`
	ExpiresAt       string            `json:"expiresAt"`
}

func (h *Handler) CreateStickerUploadRequest(w http.ResponseWriter, r *http.Request) {
	userID := UserIDFromContext(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return
	}

	var req createStickerUploadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	idempotencyKey := strings.TrimSpace(r.Header.Get("Idempotency-Key"))
	var idemPtr *string
	if idempotencyKey != "" {
		idemPtr = &idempotencyKey
	}

	result, err := h.useCase.CreateStickerUploadRequest(r.Context(), app.CreateStickerUploadInput{
		UserID:         userID,
		PackID:         r.PathValue("packID"),
		OriginalName:   req.OriginalName,
		ContentType:    req.ContentType,
		SizeBytes:      req.SizeBytes,
		IdempotencyKey: idemPtr,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, createStickerUploadResponse{
		UploadSessionID: result.UploadSessionID.String(),
		FileID:          result.FileID.String(),
		Method:          result.Method,
		URL:             result.URL,
		Headers:         result.Headers,
		ExpiresAt:       formatTime(result.ExpiresAt),
	})
}

type finalizeStickerUploadRequest struct {
	Emoji    *string  `json:"emoji,omitempty"`
	Keywords []string `json:"keywords,omitempty"`
}

func (h *Handler) FinalizeStickerUpload(w http.ResponseWriter, r *http.Request) {
	userID := UserIDFromContext(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return
	}

	var req finalizeStickerUploadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	sticker, err := h.useCase.FinalizeStickerUpload(r.Context(), app.FinalizeStickerUploadInput{
		UserID:          userID,
		PackID:          r.PathValue("packID"),
		UploadSessionID: r.PathValue("uploadSessionID"),
		Emoji:           req.Emoji,
		Keywords:        req.Keywords,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, toStickerResponse(sticker))
}

type validateSendRequest struct {
	UserID       string `json:"userId"`
	SenderUserID string `json:"senderUserId"`
	StickerID    string `json:"stickerId"`
}

type validateSendResponse struct {
	StickerID      string  `json:"stickerId"`
	PackID         string  `json:"packId"`
	Slug           string  `json:"slug"`
	FileID         string  `json:"fileId"`
	FallbackFileID string  `json:"fallbackFileId,omitempty"`
	PreviewFileID  *string `json:"previewFileId,omitempty"`
	ContentType    string  `json:"contentType,omitempty"`
	Width          int     `json:"width,omitempty"`
	Height         int     `json:"height,omitempty"`
	DurationMS     int     `json:"durationMs,omitempty"`
	Status         string  `json:"status"`
}

func (h *Handler) ValidateSend(w http.ResponseWriter, r *http.Request) {
	if !h.isTrustedInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "missing internal service token")
		return
	}

	var req validateSendRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	senderUserID := strings.TrimSpace(req.SenderUserID)
	if senderUserID == "" {
		senderUserID = req.UserID
	}

	result, err := h.useCase.ValidateSend(r.Context(), app.ValidateStickerSendInput{
		SenderUserID: senderUserID,
		StickerID:    req.StickerID,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, toValidateSendResponse(result))
}

func (h *Handler) isTrustedInternalRequest(r *http.Request) bool {
	expected := h.internalServiceToken
	if expected == "" {
		return false
	}
	return strings.TrimSpace(r.Header.Get("X-Internal-Service-Token")) == expected
}

type packResponse struct {
	ID             string            `json:"id"`
	Slug           string            `json:"slug"`
	Type           string            `json:"type"`
	Visibility     string            `json:"visibility"`
	Status         string            `json:"status"`
	OwnerUserID    *string           `json:"ownerUserId,omitempty"`
	Title          map[string]string `json:"title"`
	Description    map[string]string `json:"description,omitempty"`
	CoverStickerID *string           `json:"coverStickerId,omitempty"`
	SortOrder      int               `json:"sortOrder"`
	Stickers       []stickerResponse `json:"stickers"`
	CreatedAt      string            `json:"createdAt"`
	UpdatedAt      string            `json:"updatedAt"`
}

type officialCatalogResponse struct {
	Version int64                  `json:"version"`
	Groups  []stickerGroupResponse `json:"groups"`
}

type stickerGroupResponse struct {
	ID    string                `json:"id"`
	Slug  string                `json:"slug"`
	Title string                `json:"title"`
	Packs []catalogPackResponse `json:"packs"`
}

type catalogPackResponse struct {
	ID              string `json:"id"`
	Slug            string `json:"slug"`
	Title           string `json:"title"`
	Description     string `json:"description,omitempty"`
	Version         int    `json:"version"`
	ThumbnailFileID string `json:"thumbnailFileId,omitempty"`
}

type stickerResponse struct {
	ID             string   `json:"id"`
	PackID         string   `json:"packId"`
	Slug           string   `json:"slug,omitempty"`
	FileID         string   `json:"fileId"`
	FallbackFileID string   `json:"fallbackFileId,omitempty"`
	PreviewFileID  *string  `json:"previewFileId,omitempty"`
	ContentType    string   `json:"contentType,omitempty"`
	Width          int      `json:"width,omitempty"`
	Height         int      `json:"height,omitempty"`
	DurationMS     int      `json:"durationMs,omitempty"`
	Emoji          *string  `json:"emoji,omitempty"`
	Keywords       []string `json:"keywords"`
	Status         string   `json:"status"`
	SortOrder      int      `json:"sortOrder"`
	CreatedAt      string   `json:"createdAt"`
	UpdatedAt      string   `json:"updatedAt"`
}

func toOfficialCatalogResponse(output *app.OfficialCatalogOutput) officialCatalogResponse {
	if output == nil {
		return officialCatalogResponse{Groups: []stickerGroupResponse{}}
	}
	groups := make([]stickerGroupResponse, 0, len(output.Groups))
	for _, group := range output.Groups {
		packs := make([]catalogPackResponse, 0, len(group.Packs))
		for _, pack := range group.Packs {
			thumbnailFileID := ""
			if pack.ThumbnailFileID != uuid.Nil {
				thumbnailFileID = pack.ThumbnailFileID.String()
			}
			packs = append(packs, catalogPackResponse{
				ID:              pack.ID.String(),
				Slug:            pack.Slug,
				Title:           pack.Title,
				Description:     pack.Description,
				Version:         pack.Version,
				ThumbnailFileID: thumbnailFileID,
			})
		}
		groups = append(groups, stickerGroupResponse{
			ID:    group.ID.String(),
			Slug:  group.Slug,
			Title: group.Title,
			Packs: packs,
		})
	}
	return officialCatalogResponse{Version: output.Version, Groups: groups}
}

func toValidateSendResponse(result *app.ValidateStickerSendOutput) validateSendResponse {
	if result == nil {
		return validateSendResponse{}
	}
	var previewFileID *string
	if result.PreviewFileID != nil && *result.PreviewFileID != uuid.Nil {
		value := result.PreviewFileID.String()
		previewFileID = &value
	}
	fallbackFileID := ""
	if result.FallbackFileID != uuid.Nil {
		fallbackFileID = result.FallbackFileID.String()
	}
	return validateSendResponse{
		StickerID:      result.StickerID.String(),
		PackID:         result.PackID.String(),
		Slug:           result.Slug,
		FileID:         result.FileID.String(),
		FallbackFileID: fallbackFileID,
		PreviewFileID:  previewFileID,
		ContentType:    result.ContentType,
		Width:          result.Width,
		Height:         result.Height,
		DurationMS:     result.DurationMS,
		Status:         result.Status,
	}
}

func toPackResponses(items []*model.StickerPackWithStickers) []packResponse {
	result := make([]packResponse, 0, len(items))
	for _, item := range items {
		result = append(result, toPackResponse(item))
	}
	return result
}

func toPackResponse(item *model.StickerPackWithStickers) packResponse {
	if item == nil || item.Pack == nil {
		return packResponse{}
	}

	pack := item.Pack
	var ownerUserID *string
	if pack.OwnerUserID != nil && *pack.OwnerUserID != uuid.Nil {
		value := pack.OwnerUserID.String()
		ownerUserID = &value
	}
	var coverStickerID *string
	if pack.CoverStickerID != nil && *pack.CoverStickerID != uuid.Nil {
		value := pack.CoverStickerID.String()
		coverStickerID = &value
	}

	stickers := make([]stickerResponse, 0, len(item.Stickers))
	for _, sticker := range item.Stickers {
		stickers = append(stickers, toStickerResponse(sticker))
	}

	return packResponse{
		ID:             pack.ID.String(),
		Slug:           pack.Slug,
		Type:           string(pack.Type),
		Visibility:     string(pack.Visibility),
		Status:         string(pack.Status),
		OwnerUserID:    ownerUserID,
		Title:          pack.Title,
		Description:    pack.Description,
		CoverStickerID: coverStickerID,
		SortOrder:      pack.SortOrder,
		Stickers:       stickers,
		CreatedAt:      formatTime(pack.CreatedAt),
		UpdatedAt:      formatTime(pack.UpdatedAt),
	}
}

func toStickerResponse(sticker *model.Sticker) stickerResponse {
	if sticker == nil {
		return stickerResponse{}
	}
	var previewFileID *string
	if sticker.PreviewFileID != nil && *sticker.PreviewFileID != uuid.Nil {
		value := sticker.PreviewFileID.String()
		previewFileID = &value
	}
	fallbackFileID := ""
	if sticker.FallbackFileID != nil && *sticker.FallbackFileID != uuid.Nil {
		fallbackFileID = sticker.FallbackFileID.String()
	}
	return stickerResponse{
		ID:             sticker.ID.String(),
		PackID:         sticker.PackID.String(),
		Slug:           sticker.Slug,
		FileID:         sticker.FileID.String(),
		FallbackFileID: fallbackFileID,
		PreviewFileID:  previewFileID,
		ContentType:    sticker.ContentType,
		Width:          sticker.Width,
		Height:         sticker.Height,
		DurationMS:     sticker.DurationMS,
		Emoji:          sticker.Emoji,
		Keywords:       sticker.Keywords,
		Status:         string(sticker.Status),
		SortOrder:      sticker.SortOrder,
		CreatedAt:      formatTime(sticker.CreatedAt),
		UpdatedAt:      formatTime(sticker.UpdatedAt),
	}
}

func toStickerListResponse(output *app.StickerListOutput) map[string][]stickerResponse {
	if output == nil {
		return map[string][]stickerResponse{"stickers": []stickerResponse{}}
	}
	stickers := make([]stickerResponse, 0, len(output.Stickers))
	for _, sticker := range output.Stickers {
		stickers = append(stickers, toStickerOutputResponse(sticker))
	}
	return map[string][]stickerResponse{"stickers": stickers}
}

func toStickerOutputResponse(sticker app.StickerOutput) stickerResponse {
	var previewFileID *string
	if sticker.PreviewFileID != nil && *sticker.PreviewFileID != uuid.Nil {
		value := sticker.PreviewFileID.String()
		previewFileID = &value
	}
	fallbackFileID := ""
	if sticker.FallbackFileID != uuid.Nil {
		fallbackFileID = sticker.FallbackFileID.String()
	}
	return stickerResponse{
		ID:             sticker.ID.String(),
		PackID:         sticker.PackID.String(),
		Slug:           sticker.Slug,
		FileID:         sticker.FileID.String(),
		FallbackFileID: fallbackFileID,
		PreviewFileID:  previewFileID,
		ContentType:    sticker.ContentType,
		Width:          sticker.Width,
		Height:         sticker.Height,
		DurationMS:     sticker.DurationMS,
		Emoji:          sticker.Emoji,
		Keywords:       sticker.Keywords,
		Status:         sticker.Status,
		SortOrder:      sticker.SortOrder,
		CreatedAt:      formatTime(sticker.CreatedAt),
		UpdatedAt:      formatTime(sticker.UpdatedAt),
	}
}

func writeAppError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, app.ErrInvalidUserID),
		errors.Is(err, app.ErrInvalidPackID),
		errors.Is(err, app.ErrInvalidStickerID),
		errors.Is(err, app.ErrInvalidUploadSessionID),
		errors.Is(err, app.ErrUnsupportedMedia):
		writeError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, app.ErrPackNotFound),
		errors.Is(err, app.ErrStickerNotFound),
		errors.Is(err, app.ErrUploadSessionNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, app.ErrCustomStickersDisabled):
		writeError(w, http.StatusGone, err.Error())
	case errors.Is(err, app.ErrPackNotAccessible),
		errors.Is(err, app.ErrStickerNotAccessible),
		errors.Is(err, app.ErrStickerBlocked),
		errors.Is(err, app.ErrUploadSessionExpired),
		errors.Is(err, app.ErrFileNotReady):
		writeError(w, http.StatusForbidden, err.Error())
	default:
		writeError(w, http.StatusInternalServerError, "sticker operation failed")
	}
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, buildErrorResponse("sticker", status, message))
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
	case http.StatusGone:
		return "Действие недоступно", "Эта возможность больше не поддерживается."
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

func queryInt(r *http.Request, key string, fallback int) int {
	value, err := strconv.Atoi(strings.TrimSpace(r.URL.Query().Get(key)))
	if err != nil {
		return fallback
	}
	return value
}

func formatTime(value time.Time) string {
	if value.IsZero() {
		return ""
	}
	return value.UTC().Format(time.RFC3339)
}
