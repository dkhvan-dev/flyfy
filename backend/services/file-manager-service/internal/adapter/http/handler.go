package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/transport/dto"
)

type Handler struct {
	useCase        *app.FileUseCase
	bindingUseCase *app.FileBindingUseCase
}

func NewHandler(useCase *app.FileUseCase, bindingUseCase *app.FileBindingUseCase) *Handler {
	return &Handler{
		useCase:        useCase,
		bindingUseCase: bindingUseCase,
	}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("POST /v1/files/upload-requests", h.CreateUploadRequest)
	mux.HandleFunc("POST /v1/files/", h.handleFileActions)
	mux.HandleFunc("GET /v1/files/", h.handleFileActions)
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
	case r.Method == http.MethodDelete && len(parts) == 1:
		h.DeleteFile(w, r, fileID)
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
	var req dto.BindFileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	createdByUserID := userIDFromContext(r.Context())

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
