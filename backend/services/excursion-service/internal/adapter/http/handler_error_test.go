package http

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"kz/inflap/backend/services/excursion-service/internal/app"
	"kz/inflap/backend/services/excursion-service/internal/domain/model"
)

func TestWriteUseCaseErrorMapsInvalidExcursionLocationToBadRequest(t *testing.T) {
	handler := &Handler{}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/v1/me/excursions", nil)

	handler.writeUseCaseError(rec, req, model.ErrInvalidExcursionLocation, "failed to create excursion")

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), `"code":"excursion.invalid_excursion_location"`) {
		t.Fatalf("body = %s, want stable invalid location code", rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), `"kind":"business"`) {
		t.Fatalf("body = %s, want business error kind", rec.Body.String())
	}
}

func TestWriteUseCaseErrorMapsExcursionGalleryLimitToBadRequest(t *testing.T) {
	handler := &Handler{}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/v1/me/excursions", nil)

	handler.writeUseCaseError(rec, req, app.ErrExcursionGalleryTooManyPhotos, "failed to create excursion")

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), `"code":"excursion.excursion_gallery_too_many_photos"`) {
		t.Fatalf("body = %s, want stable gallery limit code", rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), `"kind":"business"`) {
		t.Fatalf("body = %s, want business error kind", rec.Body.String())
	}
}

func TestWriteUseCaseErrorExplainsDuplicateGuideLandmarkConflict(t *testing.T) {
	handler := &Handler{}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/v1/me/excursions", nil)

	handler.writeUseCaseError(
		rec,
		req,
		model.ErrExcursionGuideLandmarkAlreadyExists,
		"failed to create excursion",
	)

	if rec.Code != http.StatusConflict {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), `"code":"excursion.excursion_already_exists_for_this_guide_and_place"`) {
		t.Fatalf("body = %s, want stable duplicate excursion code", rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), `"error":"Экскурсия уже существует"`) {
		t.Fatalf("body = %s, want actionable duplicate excursion title", rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), `"message":"Для этого места у вас уже есть активная экскурсия. Откройте ее в кабинете гида."`) {
		t.Fatalf("body = %s, want actionable duplicate excursion message", rec.Body.String())
	}
}

func TestWriteUseCaseErrorMapsGRPCDeadlineToServiceUnavailable(t *testing.T) {
	handler := &Handler{}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/v1/me/excursions", nil)

	handler.writeUseCaseError(
		rec,
		req,
		status.Error(codes.DeadlineExceeded, "context deadline exceeded"),
		"failed to create excursion",
	)

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), `"kind":"technical"`) {
		t.Fatalf("body = %s, want technical error kind", rec.Body.String())
	}
}
