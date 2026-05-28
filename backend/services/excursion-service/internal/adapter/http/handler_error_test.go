package http

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
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
