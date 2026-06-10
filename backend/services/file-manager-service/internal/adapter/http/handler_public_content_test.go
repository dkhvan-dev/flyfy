package http

import (
	"context"
	"io"
	stdhttp "net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/app"
	"kz/inflap/backend/services/file-manager-service/internal/domain/model"
)

func TestPublicContentRedirectsToPublicObjectURL(t *testing.T) {
	fileID := uuid.New()
	files := &fakeFileUseCase{
		publicContentURL: &app.PublicContentURLOutput{
			URL:          "https://cdn.inflap.test/activity/2026/05/28/image.jpg",
			ContentType:  "image/jpeg",
			CacheControl: "public, max-age=86400, immutable",
		},
	}
	handler := NewHandler(files, nil)
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		stdhttp.MethodGet,
		"/v1/public/files/"+fileID.String()+"/content",
		nil,
	)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != stdhttp.StatusFound {
		t.Fatalf("status = %d body=%s, want %d", rec.Code, rec.Body.String(), stdhttp.StatusFound)
	}
	if got := rec.Header().Get("Location"); got != files.publicContentURL.URL {
		t.Fatalf("Location = %q, want %q", got, files.publicContentURL.URL)
	}
	if got := rec.Header().Get("Cache-Control"); got != files.publicContentURL.CacheControl {
		t.Fatalf("Cache-Control = %q, want %q", got, files.publicContentURL.CacheControl)
	}
	if got := rec.Header().Get("Content-Type"); got != files.publicContentURL.ContentType {
		t.Fatalf("Content-Type = %q, want %q", got, files.publicContentURL.ContentType)
	}
	if files.openPublicContentCalled {
		t.Fatal("OpenPublicContent was called; public content should redirect without proxying bytes")
	}
}

func TestPublicContentFallsBackToStreamingWhenPublicObjectURLIsDisabled(t *testing.T) {
	fileID := uuid.New()
	files := &fakeFileUseCase{
		publicContentBody:        "image-bytes",
		publicContentContentType: "image/webp",
	}
	handler := NewHandler(files, nil)
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		stdhttp.MethodGet,
		"/v1/public/files/"+fileID.String()+"/content",
		nil,
	)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != stdhttp.StatusOK {
		t.Fatalf("status = %d body=%s, want %d", rec.Code, rec.Body.String(), stdhttp.StatusOK)
	}
	if got := rec.Body.String(); got != files.publicContentBody {
		t.Fatalf("body = %q, want %q", got, files.publicContentBody)
	}
	if got := rec.Header().Get("Content-Type"); got != files.publicContentContentType {
		t.Fatalf("Content-Type = %q, want %q", got, files.publicContentContentType)
	}
	if !files.openPublicContentCalled {
		t.Fatal("OpenPublicContent was not called for streaming fallback")
	}
}

type fakeFileUseCase struct {
	publicContentURL         *app.PublicContentURLOutput
	publicContentURLErr      error
	publicContentBody        string
	publicContentContentType string
	openPublicContentCalled  bool
}

func (f *fakeFileUseCase) CreateUploadRequest(
	context.Context,
	app.CreateUploadRequestInput,
) (*app.CreateUploadRequestOutput, error) {
	return nil, nil
}

func (f *fakeFileUseCase) CompleteUpload(context.Context, uuid.UUID) (*app.CompleteUploadOutput, error) {
	return nil, nil
}

func (f *fakeFileUseCase) MaxUploadSizeBytes() int64 {
	return 10 << 20
}

func (f *fakeFileUseCase) UploadBinary(context.Context, uuid.UUID, string, []byte) error {
	return nil
}

func (f *fakeFileUseCase) GetFile(context.Context, uuid.UUID) (*model.File, error) {
	return nil, nil
}

func (f *fakeFileUseCase) CreateDownloadURL(context.Context, uuid.UUID) (string, time.Time, error) {
	return "", time.Time{}, nil
}

func (f *fakeFileUseCase) CreatePublicContentURL(
	context.Context,
	uuid.UUID,
) (*app.PublicContentURLOutput, error) {
	return f.publicContentURL, f.publicContentURLErr
}

func (f *fakeFileUseCase) OpenContent(context.Context, uuid.UUID) (io.ReadCloser, string, error) {
	return nil, "", nil
}

func (f *fakeFileUseCase) OpenPublicContent(context.Context, uuid.UUID) (io.ReadCloser, string, error) {
	f.openPublicContentCalled = true
	return io.NopCloser(strings.NewReader(f.publicContentBody)), f.publicContentContentType, nil
}

func (f *fakeFileUseCase) SoftDelete(context.Context, uuid.UUID) error {
	return nil
}

func (f *fakeFileUseCase) ReleaseUnboundUpload(context.Context, uuid.UUID, string) error {
	return nil
}
