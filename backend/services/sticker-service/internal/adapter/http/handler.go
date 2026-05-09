package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/model"
)

type stickerUseCase interface {
	ListDefaultPacks(ctx context.Context) ([]*model.StickerPackWithStickers, error)
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
	mux.HandleFunc("GET /v1/sticker-packs/default", h.ListDefaultPacks)
	mux.HandleFunc("GET /v1/sticker-packs/my", h.ListMyPacks)
	mux.HandleFunc("POST /v1/sticker-packs/my/custom", h.EnsureMyCustomPack)
	mux.HandleFunc("POST /v1/sticker-packs/{packID}/install", h.InstallPack)
	mux.HandleFunc("DELETE /v1/sticker-packs/{packID}/install", h.RemovePack)
	mux.HandleFunc("POST /v1/sticker-packs/{packID}/upload-requests", h.CreateStickerUploadRequest)
	mux.HandleFunc("POST /v1/sticker-packs/{packID}/uploads/{uploadSessionID}/finalize", h.FinalizeStickerUpload)
	mux.HandleFunc("POST /v1/internal/stickers/validate-send", h.ValidateSend)
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
	SenderUserID string `json:"senderUserId"`
	StickerID    string `json:"stickerId"`
}

type validateSendResponse struct {
	StickerID string `json:"stickerId"`
	PackID    string `json:"packId"`
	FileID    string `json:"fileId"`
	Status    string `json:"status"`
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

	result, err := h.useCase.ValidateSend(r.Context(), app.ValidateStickerSendInput{
		SenderUserID: req.SenderUserID,
		StickerID:    req.StickerID,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, validateSendResponse{
		StickerID: result.StickerID.String(),
		PackID:    result.PackID.String(),
		FileID:    result.FileID.String(),
		Status:    result.Status,
	})
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

type stickerResponse struct {
	ID        string   `json:"id"`
	PackID    string   `json:"packId"`
	FileID    string   `json:"fileId"`
	Emoji     *string  `json:"emoji,omitempty"`
	Keywords  []string `json:"keywords"`
	Status    string   `json:"status"`
	SortOrder int      `json:"sortOrder"`
	CreatedAt string   `json:"createdAt"`
	UpdatedAt string   `json:"updatedAt"`
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
	return stickerResponse{
		ID:        sticker.ID.String(),
		PackID:    sticker.PackID.String(),
		FileID:    sticker.FileID.String(),
		Emoji:     sticker.Emoji,
		Keywords:  sticker.Keywords,
		Status:    string(sticker.Status),
		SortOrder: sticker.SortOrder,
		CreatedAt: formatTime(sticker.CreatedAt),
		UpdatedAt: formatTime(sticker.UpdatedAt),
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
	writeJSON(w, status, map[string]string{"error": message})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func formatTime(value time.Time) string {
	if value.IsZero() {
		return ""
	}
	return value.UTC().Format(time.RFC3339)
}
