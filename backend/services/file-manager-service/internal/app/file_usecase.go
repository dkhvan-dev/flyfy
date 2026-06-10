package app

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/url"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/config"
	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
	"kz/inflap/backend/services/file-manager-service/internal/domain/model"
	"kz/inflap/backend/services/file-manager-service/internal/domain/port"
)

type FileUseCase struct {
	repo        port.FileRepository
	storage     port.StorageProvider
	cfg         *config.Config
	validator   *FileValidator
	idempotency *IdempotencyService
	fraud       port.FraudEvaluator
	trustPolicy port.TrustPolicyClient
}

const expiredUnboundUploadRetention = 24 * time.Hour

func NewFileUseCase(
	repo port.FileRepository,
	storage port.StorageProvider,
	cfg *config.Config,
	idempotencyRepo port.IdempotencyRepository,
) *FileUseCase {
	return NewFileUseCaseWithFraud(repo, storage, cfg, idempotencyRepo, nil)
}

func NewFileUseCaseWithFraud(
	repo port.FileRepository,
	storage port.StorageProvider,
	cfg *config.Config,
	idempotencyRepo port.IdempotencyRepository,
	fraud port.FraudEvaluator,
) *FileUseCase {
	return &FileUseCase{
		repo:        repo,
		storage:     storage,
		cfg:         cfg,
		validator:   NewFileValidator(DefaultUploadPolicies(cfg.Storage.MaxUploadSizeBytes)),
		idempotency: NewIdempotencyService(idempotencyRepo),
		fraud:       fraud,
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
	ClientIP         string
	DeviceID         string
	UserAgent        string
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

	if err := u.enforceFileFraud(ctx, port.FraudAssessmentInput{
		Action:      "FILE_UPLOAD_REQUEST",
		ActorUserID: uploadedByUserID,
		OwnerType:   ownerType,
		OwnerID:     ownerID,
		Purpose:     purpose,
		ContentType: normalizeContentType(input.ContentType),
		SizeBytes:   input.SizeBytes,
		ClientIP:    input.ClientIP,
		DeviceID:    input.DeviceID,
		UserAgent:   input.UserAgent,
		Metadata: map[string]any{
			"visibility":   string(visibility),
			"originalName": filepath.Base(input.OriginalName),
		},
	}); err != nil {
		return nil, err
	}

	var fingerprint string
	idempotencyKey := ""
	if input.IdempotencyKey != nil {
		idempotencyKey = strings.TrimSpace(*input.IdempotencyKey)
	}

	trustResult, trustErr := checkTrustPolicy(ctx, u.trustPolicy, port.TrustPolicyCheck{
		UserID:         valueOrNilUUID(uploadedByUserID),
		Action:         trustActionFileUpload,
		ResourceType:   "file",
		IdempotencyKey: idempotencyKey,
		Metadata: map[string]any{
			"purpose":      string(purpose),
			"visibility":   string(visibility),
			"contentType":  normalizeContentType(input.ContentType),
			"sizeBytes":    input.SizeBytes,
			"originalName": filepath.Base(input.OriginalName),
		},
	})
	if trustErr != nil {
		trustResult = quarantinedPolicyResult("TRUST_POLICY_UNAVAILABLE")
	}
	if trustResult.Decision == port.TrustPolicyDeny {
		return nil, ErrTrustPolicyRejected
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
	if err = file.ApplyPolicyDecision(
		filePolicyStatusFromDecision(trustResult),
		trustResult.ReasonCode,
		trustResult.DecisionID,
	); err != nil {
		return nil, err
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

type PublicContentURLOutput struct {
	URL          string
	ContentType  string
	CacheControl string
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

	if err = u.enforceFileFraud(ctx, port.FraudAssessmentInput{
		Action:      "FILE_UPLOAD_COMPLETE",
		ActorUserID: file.UploadedByUserID,
		FileID:      &file.ID,
		OwnerType:   file.OwnerType,
		OwnerID:     file.OwnerID,
		Purpose:     file.Purpose,
		ContentType: normalizeContentType(meta.ContentType),
		SizeBytes:   meta.SizeBytes,
		Metadata: map[string]any{
			"bucket":    meta.Bucket,
			"objectKey": meta.ObjectKey,
		},
	}); err != nil {
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

func (u *FileUseCase) enforceFileFraud(ctx context.Context, input port.FraudAssessmentInput) error {
	if u.fraud == nil {
		return nil
	}

	decision, err := u.fraud.AssessFile(ctx, input)
	if err != nil {
		return fmt.Errorf("assess file fraud: %w", err)
	}
	if decision == nil || decision.ShadowMode || decision.Decision == "" || decision.Decision == port.FraudDecisionAllow {
		return nil
	}
	return ErrFraudRejected
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

func (u *FileUseCase) CreatePublicContentURL(ctx context.Context, fileID uuid.UUID) (*PublicContentURLOutput, error) {
	if strings.TrimSpace(u.cfg.Storage.PublicURL) == "" {
		return nil, nil
	}

	file, err := u.getReadableFile(ctx, fileID, true)
	if err != nil {
		return nil, err
	}

	publicURL, err := buildPublicObjectURL(u.cfg.Storage.PublicURL, file.ObjectKey)
	if err != nil {
		return nil, err
	}
	if strings.TrimSpace(publicURL) == "" {
		return nil, nil
	}

	return &PublicContentURLOutput{
		URL:          publicURL,
		ContentType:  contentTypeForFile(file),
		CacheControl: publicContentCacheControl(u.cfg.Storage.ParsedPublicContentCacheMaxAge()),
	}, nil
}

func (u *FileUseCase) OpenContent(ctx context.Context, fileID uuid.UUID) (io.ReadCloser, string, error) {
	return u.openContent(ctx, fileID, false)
}

func (u *FileUseCase) OpenPublicContent(ctx context.Context, fileID uuid.UUID) (io.ReadCloser, string, error) {
	return u.openContent(ctx, fileID, true)
}

func (u *FileUseCase) openContent(ctx context.Context, fileID uuid.UUID, requirePublic bool) (io.ReadCloser, string, error) {
	file, err := u.getReadableFile(ctx, fileID, requirePublic)
	if err != nil {
		return nil, "", err
	}

	body, contentType, err := u.storage.GetObject(ctx, file.Bucket, file.ObjectKey)
	if err != nil {
		return nil, "", fmt.Errorf("get object content: %w", err)
	}

	if strings.TrimSpace(contentType) == "" {
		contentType = contentTypeForFile(file)
	}

	return body, contentType, nil
}

func (u *FileUseCase) getReadableFile(
	ctx context.Context,
	fileID uuid.UUID,
	requirePublic bool,
) (*model.File, error) {
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
	if file.Status != enum.FileStatusReady {
		return nil, ErrFileNotReady
	}
	if requirePublic && file.Visibility != enum.FileVisibilityPublic {
		return nil, ErrFileNotPublic
	}

	return file, nil
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

func (u *FileUseCase) ReleaseUnboundUpload(ctx context.Context, fileID uuid.UUID, userID string) error {
	if fileID == uuid.Nil {
		return ErrInvalidFileID
	}

	actorUserID, err := uuid.Parse(strings.TrimSpace(userID))
	if err != nil || actorUserID == uuid.Nil {
		return ErrInvalidOwnerID
	}

	file, err := u.repo.GetByID(ctx, fileID)
	if err != nil {
		return fmt.Errorf("get file by id: %w", err)
	}
	if file == nil || file.IsDeleted {
		return ErrFileNotFound
	}
	if file.UploadedByUserID == nil || *file.UploadedByUserID != actorUserID {
		return ErrFileOwnershipMismatch
	}

	hasBinding, err := u.repo.HasActiveBinding(ctx, fileID)
	if err != nil {
		return fmt.Errorf("check active file binding: %w", err)
	}
	if hasBinding {
		return ErrFileAlreadyBound
	}

	deleted, err := u.repo.SoftDeleteUnbound(ctx, fileID)
	if err != nil {
		return fmt.Errorf("soft delete unbound file: %w", err)
	}
	if !deleted {
		return ErrFileAlreadyBound
	}

	if err = u.storage.DeleteObject(ctx, file.Bucket, file.ObjectKey); err != nil {
		return fmt.Errorf("delete released object: %w", err)
	}

	return nil
}

func (u *FileUseCase) CleanupExpiredUnboundUploads(
	ctx context.Context,
	purpose enum.FilePurpose,
	limit int,
) (int, error) {
	if !purpose.IsValid() {
		return 0, ErrForbiddenPurpose
	}
	if limit <= 0 {
		limit = 100
	}

	expiredBefore := time.Now().UTC().Add(-expiredUnboundUploadRetention)
	files, err := u.repo.ListExpiredUnboundUploads(ctx, purpose, expiredBefore, limit)
	if err != nil {
		return 0, fmt.Errorf("list expired unbound uploads: %w", err)
	}

	deleted := 0
	var cleanupErrors []error
	for _, file := range files {
		if file == nil || file.ID == uuid.Nil || file.IsDeleted {
			continue
		}
		softDeleted, err := u.repo.SoftDeleteUnbound(ctx, file.ID)
		if err != nil {
			cleanupErrors = append(cleanupErrors, fmt.Errorf("soft delete expired file %s: %w", file.ID, err))
			continue
		}
		if !softDeleted {
			continue
		}
		if err = u.storage.DeleteObject(ctx, file.Bucket, file.ObjectKey); err != nil {
			cleanupErrors = append(cleanupErrors, fmt.Errorf("delete expired object %s: %w", file.ID, err))
			continue
		}
		deleted++
	}

	return deleted, errors.Join(cleanupErrors...)
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

func buildPublicObjectURL(publicBaseURL string, objectKey string) (string, error) {
	base := strings.TrimSpace(publicBaseURL)
	key := strings.Trim(strings.TrimSpace(objectKey), "/")
	if base == "" || key == "" {
		return "", nil
	}

	joined, err := url.JoinPath(base, key)
	if err != nil {
		return "", fmt.Errorf("join public object url: %w", err)
	}
	return joined, nil
}

func publicContentCacheControl(maxAge time.Duration) string {
	seconds := int64(maxAge.Seconds())
	if seconds <= 0 {
		seconds = int64((24 * time.Hour).Seconds())
	}
	return fmt.Sprintf("public, max-age=%d, immutable", seconds)
}

func contentTypeForFile(file *model.File) string {
	contentType := normalizeContentType(valueOrEmpty(file.DetectedContentType))
	if contentType == "" {
		contentType = normalizeContentType(file.ContentType)
	}
	if contentType == "" {
		return "application/octet-stream"
	}
	return contentType
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
