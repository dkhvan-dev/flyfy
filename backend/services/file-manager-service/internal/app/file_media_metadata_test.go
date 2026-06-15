package app

import (
	"bytes"
	"context"
	"image"
	"image/png"
	"io"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
	"kz/inflap/backend/services/file-manager-service/internal/domain/model"
	"kz/inflap/backend/services/file-manager-service/internal/domain/port"
)

func TestCompleteUploadStoresImageDimensions(t *testing.T) {
	fileID := uuid.New()
	body := mustPNG(t, 37, 21)
	file := metadataTestFile(fileID, "story.png", "image/png", int64(len(body)))
	repo := &metadataFileRepository{file: file}
	storage := &metadataStorage{
		body: body,
		meta: &port.ObjectMeta{
			Bucket:      file.Bucket,
			ObjectKey:   file.ObjectKey,
			ContentType: "image/png",
			SizeBytes:   int64(len(body)),
			ETag:        "png-etag",
		},
	}
	useCase := NewFileUseCase(repo, storage, releaseTestConfig(), nil)

	out, err := useCase.CompleteUpload(context.Background(), fileID)

	if err != nil {
		t.Fatalf("CompleteUpload error = %v", err)
	}
	if out.Width == nil || *out.Width != 37 {
		t.Fatalf("output width = %v, want 37", out.Width)
	}
	if out.Height == nil || *out.Height != 21 {
		t.Fatalf("output height = %v, want 21", out.Height)
	}
	if repo.updated == nil {
		t.Fatal("repository update was not called")
	}
	if repo.updated.Width == nil || *repo.updated.Width != 37 {
		t.Fatalf("stored width = %v, want 37", repo.updated.Width)
	}
	if repo.updated.Height == nil || *repo.updated.Height != 21 {
		t.Fatalf("stored height = %v, want 21", repo.updated.Height)
	}
}

func metadataTestFile(fileID uuid.UUID, name string, contentType string, sizeBytes int64) *model.File {
	return &model.File{
		ID:               fileID,
		Provider:         "noop",
		Bucket:           "test-bucket",
		ObjectKey:        "story_media/2026/06/12/" + fileID.String() + ".png",
		OriginalName:     name,
		StoredName:       fileID.String() + ".png",
		ContentType:      contentType,
		SizeBytes:        sizeBytes,
		Visibility:       enum.FileVisibilityPublic,
		Purpose:          enum.FilePurposeStoryMedia,
		Status:           enum.FileStatusPendingUpload,
		UploadedByUserID: uuidPtr(uuid.New()),
		UploadExpiresAt:  timePtr(time.Now().UTC().Add(time.Hour)),
		PolicyStatus:     model.FilePolicyAllowed,
		CreatedAt:        time.Now().UTC(),
		UpdatedAt:        time.Now().UTC(),
	}
}

func mustPNG(t testing.TB, width int, height int) []byte {
	t.Helper()

	var buf bytes.Buffer
	if err := png.Encode(&buf, image.NewRGBA(image.Rect(0, 0, width, height))); err != nil {
		t.Fatalf("encode png: %v", err)
	}
	return buf.Bytes()
}

func uuidPtr(v uuid.UUID) *uuid.UUID {
	return &v
}

func timePtr(v time.Time) *time.Time {
	return &v
}

type metadataFileRepository struct {
	file    *model.File
	updated *model.File
}

func (r *metadataFileRepository) Create(context.Context, *model.File) error {
	return nil
}

func (r *metadataFileRepository) GetByID(context.Context, uuid.UUID) (*model.File, error) {
	return r.file, nil
}

func (r *metadataFileRepository) GetByObjectKey(context.Context, string) (*model.File, error) {
	return nil, nil
}

func (r *metadataFileRepository) Update(_ context.Context, file *model.File) error {
	copied := *file
	r.updated = &copied
	return nil
}

func (r *metadataFileRepository) SoftDelete(context.Context, uuid.UUID) error {
	return nil
}

func (r *metadataFileRepository) SoftDeleteUnbound(context.Context, uuid.UUID) (bool, error) {
	return true, nil
}

func (r *metadataFileRepository) HasActiveBinding(context.Context, uuid.UUID) (bool, error) {
	return false, nil
}

func (r *metadataFileRepository) ListExpiredUnboundUploads(
	context.Context,
	enum.FilePurpose,
	time.Time,
	int,
) ([]*model.File, error) {
	return nil, nil
}

type metadataStorage struct {
	meta *port.ObjectMeta
	body []byte
}

func (s *metadataStorage) CreatePresignedUpload(context.Context, port.PresignUploadRequest) (*port.PresignUploadResponse, error) {
	return nil, nil
}

func (s *metadataStorage) PutObject(context.Context, port.PutObjectRequest) error {
	return nil
}

func (s *metadataStorage) StatObject(context.Context, string, string) (*port.ObjectMeta, error) {
	return s.meta, nil
}

func (s *metadataStorage) CreatePresignedDownload(context.Context, string, string, time.Duration) (string, error) {
	return "", nil
}

func (s *metadataStorage) GetObject(context.Context, string, string) (io.ReadCloser, string, error) {
	return io.NopCloser(bytes.NewReader(s.body)), s.meta.ContentType, nil
}

func (s *metadataStorage) DeleteObject(context.Context, string, string) error {
	return nil
}
