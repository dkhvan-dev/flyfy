package app

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/config"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/port"
)

type FileUseCase struct {
	repo        port.FileRepository
	storage     port.StorageProvider
	cfg         *config.Config
	validator   *FileValidator
	idempotency *IdempotencyService
}

func NewFileUseCase(
	repo port.FileRepository,
	storage port.StorageProvider,
	cfg *config.Config,
	idempotencyRepo port.IdempotencyRepository,
) *FileUseCase {
	return &FileUseCase{
		repo:        repo,
		storage:     storage,
		cfg:         cfg,
		validator:   NewFileValidator(DefaultUploadPolicies(cfg.Storage.MaxUploadSizeBytes)),
		idempotency: NewIdempotencyService(idempotencyRepo),
	}
}

type CreateUploadRequestInput struct {
	OriginalName     string
	ContentType      string
	SizeBytes        int64
	Purpose          string
	Visibility       string
	OwnerType        *string
	OwnerID          *string
	UploadedByUserID *string
	IdempotencyKey   *string
}

type CreateUploadRequestOutput struct {
	FileID    uuid.UUID         `json:"fileId"`
	ObjectKey string            `json:"objectKey"`
	Status    string            `json:"status"`
	Method    string            `json:"method"`
	URL       string            `json:"url"`
	Headers   map[string]string `json:"headers"`
	ExpiresAt time.Time         `json:"expiresAt"`
}

func (u *FileUseCase) CreateUploadRequest(
	ctx context.Context,
	input CreateUploadRequestInput,
) (*CreateUploadRequestOutput, error) {
	purpose := enum.FilePurpose(strings.TrimSpace(input.Purpose))
	if !purpose.IsValid() {
		return nil, ErrForbiddenPurpose
	}

	visibility := enum.FileVisibility(strings.TrimSpace(input.Visibility))
	if !visibility.IsValid() {
		return nil, ErrForbiddenVisibility
	}

	if err := u.validator.ValidateForCreate(
		input.OriginalName,
		input.ContentType,
		input.SizeBytes,
		purpose,
	); err != nil {
		return nil, err
	}

	var ownerType *enum.OwnerType
	if input.OwnerType != nil {
		v := enum.OwnerType(strings.TrimSpace(*input.OwnerType))
		if !v.IsValid() {
			return nil, ErrForbiddenOwnerType
		}
		ownerType = &v
	}

	var ownerID *uuid.UUID
	if input.OwnerID != nil {
		parsed, err := uuid.Parse(strings.TrimSpace(*input.OwnerID))
		if err != nil {
			return nil, ErrInvalidOwnerID
		}
		ownerID = &parsed
	}

	var uploadedByUserID *uuid.UUID
	if input.UploadedByUserID != nil {
		parsed, err := uuid.Parse(strings.TrimSpace(*input.UploadedByUserID))
		if err != nil {
			return nil, ErrInvalidOwnerID
		}
		uploadedByUserID = &parsed
	}

	var fingerprint string
	idempotencyKey := ""
	if input.IdempotencyKey != nil {
		idempotencyKey = strings.TrimSpace(*input.IdempotencyKey)
	}
	if idempotencyKey != "" {
		var err error
		fingerprint, err = u.idempotency.BuildFingerprint(map[string]any{
			"original_name": input.OriginalName,
			"content_type":  normalizeContentType(input.ContentType),
			"size_bytes":    input.SizeBytes,
			"purpose":       input.Purpose,
			"visibility":    input.Visibility,
			"owner_type":    input.OwnerType,
			"owner_id":      input.OwnerID,
			"user_id":       input.UploadedByUserID,
		})
		if err != nil {
			return nil, fmt.Errorf("build idempotency fingerprint: %w", err)
		}

		replay, err := u.idempotency.TryGetReplay(ctx, OperationCreateUploadRequest, idempotencyKey, fingerprint)
		if err != nil {
			return nil, err
		}
		if replay != nil && len(replay.ResponseBody) > 0 {
			var cached CreateUploadRequestOutput
			if err = json.Unmarshal(replay.ResponseBody, &cached); err != nil {
				return nil, fmt.Errorf("unmarshal idempotent response: %w", err)
			}
			return &cached, nil
		}

		if err = u.idempotency.Reserve(
			ctx,
			OperationCreateUploadRequest,
			idempotencyKey,
			fingerprint,
			uploadedByUserID,
		); err != nil {
			return nil, err
		}
	}

	objectKey := buildObjectKey(purpose, input.OriginalName)
	expiresAt := time.Now().UTC().Add(u.cfg.Storage.ParsedPresignTTL())

	file, err := model.NewFile(model.NewFileParams{
		Provider:         u.cfg.Storage.Provider,
		Bucket:           u.cfg.Storage.Bucket,
		ObjectKey:        objectKey,
		OriginalName:     input.OriginalName,
		ContentType:      input.ContentType,
		SizeBytes:        input.SizeBytes,
		Visibility:       visibility,
		Purpose:          purpose,
		OwnerType:        ownerType,
		OwnerID:          ownerID,
		UploadedByUserID: uploadedByUserID,
		UploadExpiresAt:  &expiresAt,
	})
	if err != nil {
		return nil, fmt.Errorf("new file: %w", err)
	}

	if err = u.repo.Create(ctx, file); err != nil {
		return nil, fmt.Errorf("create file metadata: %w", err)
	}

	presigned, err := u.storage.CreatePresignedUpload(ctx, port.PresignUploadRequest{
		Bucket:      file.Bucket,
		ObjectKey:   file.ObjectKey,
		ContentType: normalizeContentType(file.ContentType),
		ExpiresIn:   u.cfg.Storage.ParsedPresignTTL(),
	})
	if err != nil {
		return nil, fmt.Errorf("create presigned upload: %w", err)
	}

	output := &CreateUploadRequestOutput{
		FileID:    file.ID,
		ObjectKey: file.ObjectKey,
		Status:    string(file.Status),
		Method:    presigned.Method,
		URL:       presigned.URL,
		Headers:   presigned.Headers,
		ExpiresAt: presigned.ExpiresAt,
	}

	if idempotencyKey != "" {
		payload, _ := json.Marshal(output)
		resourceType := "FILE"
		resourceID := file.ID.String()

		_ = u.idempotency.repo.UpdateResponse(
			ctx,
			OperationCreateUploadRequest,
			idempotencyKey,
			fingerprint,
			201,
			payload,
			&resourceType,
			&resourceID,
		)
	}

	return output, nil
}

type CompleteUploadOutput struct {
	FileID              uuid.UUID
	Status              string
	DetectedContentType string
	SizeBytes           int64
}

func (u *FileUseCase) CompleteUpload(ctx context.Context, fileID uuid.UUID) (*CompleteUploadOutput, error) {
	if fileID == uuid.Nil {
		return nil, ErrInvalidFileID
	}

	file, err := u.repo.GetByID(ctx, fileID)
	if err != nil {
		return nil, fmt.Errorf("get file by id: %w", err)
	}
	if file == nil || file.IsDeleted {
		return nil, ErrFileNotFound
	}

	meta, err := u.storage.StatObject(ctx, file.Bucket, file.ObjectKey)
	if err != nil {
		return nil, fmt.Errorf("stat object: %w", err)
	}

	if err = u.validator.ValidateUploadedObject(
		file.OriginalName,
		meta.ContentType,
		meta.SizeBytes,
		file.Purpose,
	); err != nil {
		_ = file.MarkFailed()
		_ = u.repo.Update(ctx, file)
		return nil, err
	}

	checksum := sha256String(
		fmt.Sprintf("%s:%s:%d:%s", meta.Bucket, meta.ObjectKey, meta.SizeBytes, meta.ETag),
	)

	if err = file.MarkUploaded(normalizeContentType(meta.ContentType), meta.SizeBytes, &checksum); err != nil {
		return nil, fmt.Errorf("mark uploaded: %w", err)
	}

	if err = file.MarkReady(); err != nil {
		return nil, fmt.Errorf("mark ready: %w", err)
	}

	if err = u.repo.Update(ctx, file); err != nil {
		return nil, fmt.Errorf("update file after complete upload: %w", err)
	}

	return &CompleteUploadOutput{
		FileID:              file.ID,
		Status:              string(file.Status),
		DetectedContentType: valueOrEmpty(file.DetectedContentType),
		SizeBytes:           file.SizeBytes,
	}, nil
}

func (u *FileUseCase) UploadBinary(
	ctx context.Context,
	fileID uuid.UUID,
	contentType string,
	body []byte,
) error {
	if fileID == uuid.Nil {
		return ErrInvalidFileID
	}

	file, err := u.repo.GetByID(ctx, fileID)
	if err != nil {
		return fmt.Errorf("get file by id: %w", err)
	}
	if file == nil || file.IsDeleted {
		return ErrFileNotFound
	}

	if int64(len(body)) > u.cfg.Storage.MaxUploadSizeBytes {
		return ErrUploadTooLarge
	}
	if int64(len(body)) != file.SizeBytes {
		return ErrInvalidFileSize
	}

	resolvedContentType := normalizeContentType(contentType)
	if resolvedContentType == "" {
		resolvedContentType = normalizeContentType(file.ContentType)
	}
	if resolvedContentType == "" {
		return ErrContentTypeRequired
	}

	if err = u.storage.PutObject(ctx, port.PutObjectRequest{
		Bucket:      file.Bucket,
		ObjectKey:   file.ObjectKey,
		ContentType: resolvedContentType,
		Body:        body,
	}); err != nil {
		return fmt.Errorf("put object: %w", err)
	}

	return nil
}

func (u *FileUseCase) GetFile(ctx context.Context, fileID uuid.UUID) (*model.File, error) {
	if fileID == uuid.Nil {
		return nil, ErrInvalidFileID
	}

	file, err := u.repo.GetByID(ctx, fileID)
	if err != nil {
		return nil, fmt.Errorf("get file by id: %w", err)
	}
	if file == nil || file.IsDeleted {
		return nil, ErrFileNotFound
	}
	return file, nil
}

func (u *FileUseCase) MaxUploadSizeBytes() int64 {
	return u.cfg.Storage.MaxUploadSizeBytes
}

func (u *FileUseCase) CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, time.Time, error) {
	if fileID == uuid.Nil {
		return "", time.Time{}, ErrInvalidFileID
	}

	file, err := u.repo.GetByID(ctx, fileID)
	if err != nil {
		return "", time.Time{}, fmt.Errorf("get file by id: %w", err)
	}
	if file == nil || file.IsDeleted {
		return "", time.Time{}, ErrFileNotFound
	}

	expiresIn := u.cfg.Storage.ParsedPresignTTL()
	url, err := u.storage.CreatePresignedDownload(ctx, file.Bucket, file.ObjectKey, expiresIn)
	if err != nil {
		return "", time.Time{}, fmt.Errorf("create presigned download: %w", err)
	}

	return url, time.Now().UTC().Add(expiresIn), nil
}

func (u *FileUseCase) SoftDelete(ctx context.Context, fileID uuid.UUID) error {
	if fileID == uuid.Nil {
		return ErrInvalidFileID
	}

	file, err := u.repo.GetByID(ctx, fileID)
	if err != nil {
		return fmt.Errorf("get file by id: %w", err)
	}
	if file == nil || file.IsDeleted {
		return ErrFileNotFound
	}

	if err = file.SoftDelete(); err != nil {
		return fmt.Errorf("soft delete in domain: %w", err)
	}

	if err = u.repo.SoftDelete(ctx, fileID); err != nil {
		return fmt.Errorf("soft delete in repository: %w", err)
	}

	return nil
}

func buildObjectKey(purpose enum.FilePurpose, originalName string) string {
	now := time.Now().UTC()
	ext := strings.ToLower(strings.TrimPrefix(filepath.Ext(strings.TrimSpace(originalName)), "."))
	base := uuid.NewString()

	if ext == "" {
		return fmt.Sprintf(
			"%s/%04d/%02d/%02d/%s",
			strings.ToLower(string(purpose)),
			now.Year(),
			now.Month(),
			now.Day(),
			base,
		)
	}

	return fmt.Sprintf(
		"%s/%04d/%02d/%02d/%s.%s",
		strings.ToLower(string(purpose)),
		now.Year(),
		now.Month(),
		now.Day(),
		base,
		ext,
	)
}

func valueOrEmpty(v *string) string {
	if v == nil {
		return ""
	}
	return *v
}

func sha256String(v string) string {
	sum := sha256.Sum256([]byte(v))
	return hex.EncodeToString(sum[:])
}
