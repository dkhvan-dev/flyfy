package app

import (
	"context"
	"errors"
	"io"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/config"
	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
	"kz/inflap/backend/services/file-manager-service/internal/domain/model"
	"kz/inflap/backend/services/file-manager-service/internal/domain/port"
)

func TestReleaseUnboundUploadDeletesOwnObjectAndSoftDeletesMetadata(t *testing.T) {
	fileID := uuid.New()
	userID := uuid.New()
	file := releaseTestFile(fileID, userID, enum.FilePurposeStoryMedia)
	repo := &releaseFileRepository{file: file}
	storage := &releaseStorage{}
	useCase := NewFileUseCase(repo, storage, releaseTestConfig(), nil)

	err := useCase.ReleaseUnboundUpload(context.Background(), fileID, userID.String())

	if err != nil {
		t.Fatalf("ReleaseUnboundUpload error = %v", err)
	}
	if storage.deletedObjectKeys[0] != file.ObjectKey {
		t.Fatalf("deleted object key = %q, want %q", storage.deletedObjectKeys[0], file.ObjectKey)
	}
	if repo.softDeletedFileIDs[0] != fileID {
		t.Fatalf("soft deleted file id = %s, want %s", repo.softDeletedFileIDs[0], fileID)
	}
}

func TestReleaseUnboundUploadRejectsBoundFile(t *testing.T) {
	fileID := uuid.New()
	userID := uuid.New()
	repo := &releaseFileRepository{
		file:             releaseTestFile(fileID, userID, enum.FilePurposeStoryMedia),
		hasActiveBinding: true,
	}
	storage := &releaseStorage{}
	useCase := NewFileUseCase(repo, storage, releaseTestConfig(), nil)

	err := useCase.ReleaseUnboundUpload(context.Background(), fileID, userID.String())

	if !errors.Is(err, ErrFileAlreadyBound) {
		t.Fatalf("ReleaseUnboundUpload error = %v, want ErrFileAlreadyBound", err)
	}
	if len(storage.deletedObjectKeys) != 0 {
		t.Fatalf("deleted objects = %v, want none", storage.deletedObjectKeys)
	}
	if len(repo.softDeletedFileIDs) != 0 {
		t.Fatalf("soft deleted files = %v, want none", repo.softDeletedFileIDs)
	}
}

func TestReleaseUnboundUploadRejectsAnotherUserFile(t *testing.T) {
	fileID := uuid.New()
	ownerID := uuid.New()
	actorID := uuid.New()
	repo := &releaseFileRepository{
		file: releaseTestFile(fileID, ownerID, enum.FilePurposeStoryMedia),
	}
	storage := &releaseStorage{}
	useCase := NewFileUseCase(repo, storage, releaseTestConfig(), nil)

	err := useCase.ReleaseUnboundUpload(context.Background(), fileID, actorID.String())

	if !errors.Is(err, ErrFileOwnershipMismatch) {
		t.Fatalf("ReleaseUnboundUpload error = %v, want ErrFileOwnershipMismatch", err)
	}
	if len(storage.deletedObjectKeys) != 0 {
		t.Fatalf("deleted objects = %v, want none", storage.deletedObjectKeys)
	}
}

func TestCleanupExpiredStoryMediaReleasesUnboundUploads(t *testing.T) {
	first := releaseTestFileWithExpiry(uuid.New(), uuid.New(), enum.FilePurposeStoryMedia, time.Now().UTC().Add(-25*time.Hour))
	second := releaseTestFileWithExpiry(uuid.New(), uuid.New(), enum.FilePurposeStoryMedia, time.Now().UTC().Add(-26*time.Hour))
	repo := &releaseFileRepository{expiredUnboundFiles: []*model.File{first, second}}
	storage := &releaseStorage{}
	useCase := NewFileUseCase(repo, storage, releaseTestConfig(), nil)

	deleted, err := useCase.CleanupExpiredUnboundUploads(
		context.Background(),
		enum.FilePurposeStoryMedia,
		10,
	)

	if err != nil {
		t.Fatalf("CleanupExpiredUnboundUploads error = %v", err)
	}
	if deleted != 2 {
		t.Fatalf("deleted = %d, want 2", deleted)
	}
	if storage.deletedObjectKeys[0] != first.ObjectKey || storage.deletedObjectKeys[1] != second.ObjectKey {
		t.Fatalf("deleted object keys = %v, want [%s %s]", storage.deletedObjectKeys, first.ObjectKey, second.ObjectKey)
	}
	if len(repo.softDeletedFileIDs) != 2 {
		t.Fatalf("soft deleted files = %v, want 2 files", repo.softDeletedFileIDs)
	}
	if repo.cleanupPurpose != enum.FilePurposeStoryMedia {
		t.Fatalf("cleanup purpose = %s, want %s", repo.cleanupPurpose, enum.FilePurposeStoryMedia)
	}
}

func releaseTestConfig() *config.Config {
	return &config.Config{
		Storage: config.StorageConfig{
			Provider:                 "noop",
			Bucket:                   "test-bucket",
			PresignTTL:               "15m",
			MaxUploadSizeBytes:       20 * 1024 * 1024,
			PublicContentCacheMaxAge: "24h",
		},
	}
}

func releaseTestFile(fileID uuid.UUID, uploadedByUserID uuid.UUID, purpose enum.FilePurpose) *model.File {
	return releaseTestFileWithExpiry(
		fileID,
		uploadedByUserID,
		purpose,
		time.Now().UTC().Add(-time.Hour),
	)
}

func releaseTestFileWithExpiry(
	fileID uuid.UUID,
	uploadedByUserID uuid.UUID,
	purpose enum.FilePurpose,
	expiresAt time.Time,
) *model.File {
	return &model.File{
		ID:               fileID,
		Provider:         "noop",
		Bucket:           "test-bucket",
		ObjectKey:        "story_media/2026/06/09/" + fileID.String() + ".jpg",
		OriginalName:     "story.jpg",
		StoredName:       fileID.String() + ".jpg",
		ContentType:      "image/jpeg",
		SizeBytes:        1024,
		Visibility:       enum.FileVisibilityPublic,
		Purpose:          purpose,
		Status:           enum.FileStatusReady,
		UploadedByUserID: &uploadedByUserID,
		UploadExpiresAt:  &expiresAt,
		PolicyStatus:     model.FilePolicyAllowed,
		CreatedAt:        time.Now().UTC().Add(-2 * time.Hour),
		UpdatedAt:        time.Now().UTC().Add(-time.Hour),
	}
}

type releaseFileRepository struct {
	file                *model.File
	hasActiveBinding    bool
	expiredUnboundFiles []*model.File
	cleanupPurpose      enum.FilePurpose
	softDeletedFileIDs  []uuid.UUID
}

func (r *releaseFileRepository) Create(context.Context, *model.File) error {
	return nil
}

func (r *releaseFileRepository) GetByID(context.Context, uuid.UUID) (*model.File, error) {
	return r.file, nil
}

func (r *releaseFileRepository) GetByObjectKey(context.Context, string) (*model.File, error) {
	return nil, nil
}

func (r *releaseFileRepository) Update(context.Context, *model.File) error {
	return nil
}

func (r *releaseFileRepository) SoftDelete(_ context.Context, id uuid.UUID) error {
	r.softDeletedFileIDs = append(r.softDeletedFileIDs, id)
	return nil
}

func (r *releaseFileRepository) SoftDeleteUnbound(_ context.Context, id uuid.UUID) (bool, error) {
	if r.hasActiveBinding {
		return false, nil
	}
	r.softDeletedFileIDs = append(r.softDeletedFileIDs, id)
	return true, nil
}

func (r *releaseFileRepository) HasActiveBinding(context.Context, uuid.UUID) (bool, error) {
	return r.hasActiveBinding, nil
}

func (r *releaseFileRepository) ListExpiredUnboundUploads(
	_ context.Context,
	purpose enum.FilePurpose,
	_ time.Time,
	limit int,
) ([]*model.File, error) {
	r.cleanupPurpose = purpose
	if limit > 0 && limit < len(r.expiredUnboundFiles) {
		return r.expiredUnboundFiles[:limit], nil
	}
	return r.expiredUnboundFiles, nil
}

type releaseStorage struct {
	deletedObjectKeys []string
}

func (s *releaseStorage) CreatePresignedUpload(context.Context, port.PresignUploadRequest) (*port.PresignUploadResponse, error) {
	return nil, nil
}

func (s *releaseStorage) PutObject(context.Context, port.PutObjectRequest) error {
	return nil
}

func (s *releaseStorage) StatObject(context.Context, string, string) (*port.ObjectMeta, error) {
	return nil, nil
}

func (s *releaseStorage) CreatePresignedDownload(context.Context, string, string, time.Duration) (string, error) {
	return "", nil
}

func (s *releaseStorage) GetObject(context.Context, string, string) (io.ReadCloser, string, error) {
	return nil, "", nil
}

func (s *releaseStorage) DeleteObject(_ context.Context, _ string, objectKey string) error {
	s.deletedObjectKeys = append(s.deletedObjectKeys, objectKey)
	return nil
}
