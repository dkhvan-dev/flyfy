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

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/transport/dto"
)

type Handler struct {
	useCase        fileUseCase
	bindingUseCase bindingUseCase
}

type fileUseCase interface {
	CreateUploadRequest(context.Context, app.CreateUploadRequestInput) (*app.CreateUploadRequestOutput, error)
	CompleteUpload(context.Context, uuid.UUID) (*app.CompleteUploadOutput, error)
	MaxUploadSizeBytes() int64
	UploadBinary(context.Context, uuid.UUID, string, []byte) error
	GetFile(context.Context, uuid.UUID) (*model.File, error)
	CreateDownloadURL(context.Context, uuid.UUID) (string, time.Time, error)
	CreatePublicContentURL(context.Context, uuid.UUID) (*app.PublicContentURLOutput, error)
	OpenContent(context.Context, uuid.UUID) (io.ReadCloser, string, error)
	OpenPublicContent(context.Context, uuid.UUID) (io.ReadCloser, string, error)
	SoftDelete(context.Context, uuid.UUID) error
}

type bindingUseCase interface {
	BindFile(context.Context, app.BindFileInput) (*model.FileBinding, error)
	ListByFileID(context.Context, uuid.UUID) ([]*model.FileBinding, error)
	ListByOwnerAndPurpose(context.Context, app.ListFileBindingsInput) ([]*model.FileBinding, error)
}

func NewHandler(useCase fileUseCase, bindingUseCase bindingUseCase) *Handler {
	return &Handler{
		useCase:        useCase,
		bindingUseCase: bindingUseCase,
	}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("POST /v1/files/upload-requests", h.CreateUploadRequest)
	mux.HandleFunc("GET /v1/public/files/", h.handlePublicFileActions)
	mux.HandleFunc("GET /v1/files/my-bindings", h.ListMyBindings)
	mux.HandleFunc("POST /v1/internal/files/", h.handleInternalFileActions)
	mux.HandleFunc("POST /v1/files/", h.handleFileActions)
	mux.HandleFunc("GET /v1/files/", h.handleFileActions)
	mux.HandleFunc("PUT /v1/files/", h.handleFileActions)
	mux.HandleFunc("DELETE /v1/files/", h.handleFileActions)
	mux.HandleFunc("GET /health", h.Health)
}

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status": "ok",
	})
}

func (h *Handler) CreateUploadRequest(w http.ResponseWriter, r *http.Request) {
	var req dto.CreateUploadRequestRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	uploadedByUserID := userIDFromContext(r.Context())

	idempotencyKey := strings.TrimSpace(r.Header.Get("Idempotency-Key"))
	var idemPtr *string
	if idempotencyKey != "" {
		idemPtr = &idempotencyKey
	}

	resp, err := h.useCase.CreateUploadRequest(r.Context(), app.CreateUploadRequestInput{
		OriginalName:     req.OriginalName,
		ContentType:      req.ContentType,
		SizeBytes:        req.SizeBytes,
		Purpose:          req.Purpose,
		Visibility:       req.Visibility,
		OwnerType:        req.OwnerType,
		OwnerID:          req.OwnerID,
		UploadedByUserID: uploadedByUserID,
		IdempotencyKey:   idemPtr,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrUploadTooLarge),
			errors.Is(err, app.ErrForbiddenPurpose),
			errors.Is(err, app.ErrForbiddenVisibility),
			errors.Is(err, app.ErrForbiddenOwnerType),
			errors.Is(err, app.ErrInvalidOwnerID),
			errors.Is(err, app.ErrExtensionNotAllowed),
			errors.Is(err, app.ErrContentTypeNotAllowed),
			errors.Is(err, app.ErrFilenameRequired),
			errors.Is(err, app.ErrContentTypeRequired),
			errors.Is(err, app.ErrInvalidFileSize):
			writeError(w, http.StatusBadRequest, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to create upload request")
		}
		return
	}

	writeJSON(w, http.StatusCreated, dto.CreateUploadRequestResponse{
		FileID:    resp.FileID.String(),
		ObjectKey: resp.ObjectKey,
		Status:    resp.Status,
		Upload: dto.UploadDescriptor{
			Method:    resp.Method,
			URL:       resp.URL,
			Headers:   resp.Headers,
			ExpiresAt: resp.ExpiresAt.UTC().Format(time.RFC3339),
		},
	})
}

func (h *Handler) handleFileActions(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/files/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	parts := strings.Split(path, "/")
	fileID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid file id")
		return
	}

	switch {
	case r.Method == http.MethodGet && len(parts) == 1:
		h.GetFile(w, r, fileID)
		return
	case r.Method == http.MethodGet && len(parts) == 2 && parts[1] == "content":
		h.GetContent(w, r, fileID)
		return
	case r.Method == http.MethodDelete && len(parts) == 1:
		h.DeleteFile(w, r, fileID)
		return
	case r.Method == http.MethodPut && len(parts) == 2 && parts[1] == "binary":
		h.UploadBinary(w, r, fileID)
		return
	case r.Method == http.MethodPost && len(parts) == 2 && parts[1] == "complete":
		h.CompleteUpload(w, r, fileID)
		return
	case r.Method == http.MethodPost && len(parts) == 2 && parts[1] == "download-url":
		h.CreateDownloadURL(w, r, fileID)
		return
	case r.Method == http.MethodPost && len(parts) == 2 && parts[1] == "bindings":
		h.BindFile(w, r, fileID)
		return
	case r.Method == http.MethodGet && len(parts) == 2 && parts[1] == "bindings":
		h.ListBindings(w, r, fileID)
		return
	default:
		writeError(w, http.StatusNotFound, "not found")
		return
	}
}

func (h *Handler) handlePublicFileActions(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/public/files/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	parts := strings.Split(path, "/")
	fileID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid file id")
		return
	}

	if r.Method == http.MethodGet && len(parts) == 2 && parts[1] == "content" {
		h.GetPublicContent(w, r, fileID)
		return
	}

	writeError(w, http.StatusNotFound, "not found")
}

func (h *Handler) handleInternalFileActions(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/internal/files/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	parts := strings.Split(path, "/")
	fileID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid file id")
		return
	}

	if r.Method == http.MethodPost && len(parts) == 2 && parts[1] == "bindings" {
		h.BindFileInternal(w, r, fileID)
		return
	}

	writeError(w, http.StatusNotFound, "not found")
}

func (h *Handler) CompleteUpload(w http.ResponseWriter, r *http.Request, fileID uuid.UUID) {
	resp, err := h.useCase.CompleteUpload(r.Context(), fileID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrFileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		case errors.Is(err, app.ErrUploadTooLarge):
			writeError(w, http.StatusBadRequest, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to complete upload")
		}
		return
	}

	writeJSON(w, http.StatusOK, dto.CompleteUploadResponse{
		FileID:              resp.FileID.String(),
		Status:              resp.Status,
		DetectedContentType: resp.DetectedContentType,
		SizeBytes:           resp.SizeBytes,
	})
}

func (h *Handler) UploadBinary(w http.ResponseWriter, r *http.Request, fileID uuid.UUID) {
	bodyReader := http.MaxBytesReader(w, r.Body, h.useCase.MaxUploadSizeBytes()+1)
	defer bodyReader.Close()

	body, err := io.ReadAll(bodyReader)
	if err != nil {
		var maxBytesErr *http.MaxBytesError
		if errors.As(err, &maxBytesErr) {
			writeError(w, http.StatusRequestEntityTooLarge, app.ErrUploadTooLarge.Error())
			return
		}
		writeError(w, http.StatusBadRequest, "failed to read upload body")
		return
	}

	if err = h.useCase.UploadBinary(r.Context(), fileID, r.Header.Get("Content-Type"), body); err != nil {
		switch {
		case errors.Is(err, app.ErrFileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		case errors.Is(err, app.ErrUploadTooLarge):
			writeError(w, http.StatusRequestEntityTooLarge, err.Error())
		case errors.Is(err, app.ErrInvalidFileID),
			errors.Is(err, app.ErrInvalidFileSize),
			errors.Is(err, app.ErrContentTypeRequired):
			writeError(w, http.StatusBadRequest, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to upload file binary")
		}
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetFile(w http.ResponseWriter, r *http.Request, fileID uuid.UUID) {
	file, err := h.useCase.GetFile(r.Context(), fileID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrFileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to get file")
		}
		return
	}

	writeJSON(w, http.StatusOK, toFileResponse(file))
}

func (h *Handler) CreateDownloadURL(w http.ResponseWriter, r *http.Request, fileID uuid.UUID) {
	url, expiresAt, err := h.useCase.CreateDownloadURL(r.Context(), fileID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrFileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to create download url")
		}
		return
	}

	writeJSON(w, http.StatusOK, dto.CreateDownloadURLResponse{
		URL:       url,
		ExpiresAt: expiresAt.UTC().Format(time.RFC3339),
	})
}

func (h *Handler) GetContent(w http.ResponseWriter, r *http.Request, fileID uuid.UUID) {
	authenticated := UserIDFromContext(r.Context()) != ""
	cacheControl := "public, max-age=300"

	var (
		body        io.ReadCloser
		contentType string
		err         error
	)
	if authenticated {
		body, contentType, err = h.useCase.OpenContent(r.Context(), fileID)
		cacheControl = "private, max-age=300"
	} else {
		body, contentType, err = h.useCase.OpenPublicContent(r.Context(), fileID)
	}
	if err != nil {
		switch {
		case errors.Is(err, app.ErrFileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		case errors.Is(err, app.ErrFileNotReady), errors.Is(err, app.ErrFileNotPublic):
			writeError(w, http.StatusForbidden, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to load file content")
		}
		return
	}
	defer body.Close()

	writeFileContent(w, body, contentType, cacheControl)
}

func (h *Handler) GetPublicContent(w http.ResponseWriter, r *http.Request, fileID uuid.UUID) {
	publicURL, err := h.useCase.CreatePublicContentURL(r.Context(), fileID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrFileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		case errors.Is(err, app.ErrFileNotReady), errors.Is(err, app.ErrFileNotPublic):
			writeError(w, http.StatusForbidden, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to create public file content url")
		}
		return
	}
	if publicURL != nil && strings.TrimSpace(publicURL.URL) != "" {
		writeFileRedirect(w, publicURL.URL, publicURL.ContentType, publicURL.CacheControl)
		return
	}

	body, contentType, err := h.useCase.OpenPublicContent(r.Context(), fileID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrFileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		case errors.Is(err, app.ErrFileNotReady), errors.Is(err, app.ErrFileNotPublic):
			writeError(w, http.StatusForbidden, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to load file content")
		}
		return
	}
	defer body.Close()

	writeFileContent(w, body, contentType, "public, max-age=300")
}

func writeFileRedirect(w http.ResponseWriter, location string, contentType string, cacheControl string) {
	if strings.TrimSpace(contentType) != "" {
		w.Header().Set("Content-Type", contentType)
	}
	if strings.TrimSpace(cacheControl) != "" {
		w.Header().Set("Cache-Control", cacheControl)
	}
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Location", location)
	w.WriteHeader(http.StatusFound)
}

func writeFileContent(w http.ResponseWriter, body io.Reader, contentType string, cacheControl string) {
	if strings.TrimSpace(contentType) != "" {
		w.Header().Set("Content-Type", contentType)
	}
	w.Header().Set("Cache-Control", cacheControl)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	_, _ = io.Copy(w, body)
}

func (h *Handler) DeleteFile(w http.ResponseWriter, r *http.Request, fileID uuid.UUID) {
	if err := h.useCase.SoftDelete(r.Context(), fileID); err != nil {
		switch {
		case errors.Is(err, app.ErrFileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to delete file")
		}
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func toFileResponse(file *model.File) dto.FileResponse {
	var ownerType *string
	if file.OwnerType != nil {
		v := string(*file.OwnerType)
		ownerType = &v
	}

	var ownerID *string
	if file.OwnerID != nil {
		v := file.OwnerID.String()
		ownerID = &v
	}

	var uploadedByUserID *string
	if file.UploadedByUserID != nil {
		v := file.UploadedByUserID.String()
		uploadedByUserID = &v
	}

	var uploadExpiresAt *string
	if file.UploadExpiresAt != nil {
		v := file.UploadExpiresAt.UTC().Format(time.RFC3339)
		uploadExpiresAt = &v
	}

	var deletedAt *string
	if file.DeletedAt != nil {
		v := file.DeletedAt.UTC().Format(time.RFC3339)
		deletedAt = &v
	}

	return dto.FileResponse{
		ID:                  file.ID.String(),
		Provider:            file.Provider,
		Bucket:              file.Bucket,
		ObjectKey:           file.ObjectKey,
		OriginalName:        file.OriginalName,
		StoredName:          file.StoredName,
		Extension:           file.Extension,
		ContentType:         file.ContentType,
		DetectedContentType: file.DetectedContentType,
		SizeBytes:           file.SizeBytes,
		ChecksumSHA256:      file.ChecksumSHA256,
		Visibility:          string(file.Visibility),
		Purpose:             string(file.Purpose),
		Status:              string(file.Status),
		OwnerType:           ownerType,
		OwnerID:             ownerID,
		UploadedByUserID:    uploadedByUserID,
		UploadExpiresAt:     uploadExpiresAt,
		IsDeleted:           file.IsDeleted,
		DeletedAt:           deletedAt,
		CreatedAt:           file.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:           file.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func userIDFromHeader(r *http.Request) *string {
	userID := strings.TrimSpace(r.Header.Get("X-User-Id"))
	if userID == "" {
		return nil
	}
	return &userID
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

func userIDFromContext(ctx context.Context) *string {
	userID := strings.TrimSpace(UserIDFromContext(ctx))
	if userID == "" {
		return nil
	}
	return &userID
}

func (h *Handler) BindFile(w http.ResponseWriter, r *http.Request, fileID uuid.UUID) {
	h.bindFile(w, r, fileID, true)
}

func (h *Handler) BindFileInternal(w http.ResponseWriter, r *http.Request, fileID uuid.UUID) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, http.StatusUnauthorized, "missing internal service token")
		return
	}

	h.bindFile(w, r, fileID, false)
}

func (h *Handler) bindFile(w http.ResponseWriter, r *http.Request, fileID uuid.UUID, enforceUserOwner bool) {
	var req dto.BindFileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	createdByUserID := userIDFromContext(r.Context())
	if enforceUserOwner && strings.EqualFold(strings.TrimSpace(req.OwnerType), "USER") {
		currentUserID := strings.TrimSpace(UserIDFromContext(r.Context()))
		if currentUserID == "" || strings.TrimSpace(req.OwnerID) != currentUserID {
			writeError(w, http.StatusForbidden, "cannot bind file to another user")
			return
		}
	}

	binding, err := h.bindingUseCase.BindFile(r.Context(), app.BindFileInput{
		FileID:          fileID,
		OwnerType:       req.OwnerType,
		OwnerID:         req.OwnerID,
		Purpose:         req.Purpose,
		IsPrimary:       req.IsPrimary,
		CreatedByUserID: createdByUserID,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidFileID),
			errors.Is(err, app.ErrInvalidOwnerID),
			errors.Is(err, app.ErrForbiddenOwnerType),
			errors.Is(err, app.ErrForbiddenPurpose):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrFileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to bind file")
		}
		return
	}

	writeJSON(w, http.StatusCreated, toFileBindingResponse(binding))
}

func toFileBindingResponse(binding *model.FileBinding) dto.FileBindingResponse {
	var deletedAt *string
	if binding.DeletedAt != nil {
		v := binding.DeletedAt.UTC().Format(time.RFC3339)
		deletedAt = &v
	}

	var createdByUserID *string
	if binding.CreatedByUserID != nil {
		v := binding.CreatedByUserID.String()
		createdByUserID = &v
	}

	return dto.FileBindingResponse{
		ID:              binding.ID.String(),
		FileID:          binding.FileID.String(),
		OwnerType:       string(binding.OwnerType),
		OwnerID:         binding.OwnerID.String(),
		Purpose:         string(binding.Purpose),
		IsPrimary:       binding.IsPrimary,
		IsDeleted:       binding.IsDeleted,
		DeletedAt:       deletedAt,
		CreatedByUserID: createdByUserID,
		CreatedAt:       binding.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:       binding.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func (h *Handler) ListBindings(w http.ResponseWriter, r *http.Request, fileID uuid.UUID) {
	items, err := h.bindingUseCase.ListByFileID(r.Context(), fileID)
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidFileID):
			writeError(w, http.StatusBadRequest, err.Error())
		case errors.Is(err, app.ErrFileNotFound):
			writeError(w, http.StatusNotFound, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to list bindings")
		}
		return
	}

	resp := make([]dto.FileBindingResponse, 0, len(items))
	for _, item := range items {
		resp = append(resp, toFileBindingResponse(item))
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"bindings": resp,
	})
}

func (h *Handler) ListMyBindings(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(UserIDFromContext(r.Context()))
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return
	}

	purpose := strings.TrimSpace(r.URL.Query().Get("purpose"))
	if purpose == "" {
		writeError(w, http.StatusBadRequest, "purpose is required")
		return
	}

	limit := 100
	if rawLimit := strings.TrimSpace(r.URL.Query().Get("limit")); rawLimit != "" {
		parsed, err := strconv.Atoi(rawLimit)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid limit")
			return
		}
		limit = parsed
	}

	items, err := h.bindingUseCase.ListByOwnerAndPurpose(r.Context(), app.ListFileBindingsInput{
		OwnerType: "USER",
		OwnerID:   userID,
		Purpose:   purpose,
		Limit:     limit,
	})
	if err != nil {
		switch {
		case errors.Is(err, app.ErrInvalidOwnerID),
			errors.Is(err, app.ErrForbiddenOwnerType),
			errors.Is(err, app.ErrForbiddenPurpose):
			writeError(w, http.StatusBadRequest, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to list bindings")
		}
		return
	}

	resp := make([]dto.FileBindingResponse, 0, len(items))
	for _, item := range items {
		resp = append(resp, toFileBindingResponse(item))
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"bindings": resp,
	})
}
