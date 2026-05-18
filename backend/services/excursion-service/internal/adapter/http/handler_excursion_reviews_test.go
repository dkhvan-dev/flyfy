package http

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
	"github.com/google/uuid"
)

func TestListExcursionReviewsParsesGuideFilterAndRatingSort(t *testing.T) {
	guideUserID := uuid.New()
	repo := &excursionOffersRepoStub{}
	handler := NewHandler(app.NewExcursionUseCase(repo, nil, nil), nil)

	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/excursion-reviews?guideUserId="+guideUserID.String()+"&sort=rating_desc&limit=10",
		nil,
	)
	rec := httptest.NewRecorder()

	handler.ListExcursionReviews(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", rec.Code)
	}
	filter := repo.listReviewFilter
	if filter.GuideUserID == nil || *filter.GuideUserID != guideUserID {
		t.Fatalf("guide user filter = %v, want %s", filter.GuideUserID, guideUserID)
	}
	if filter.Sort != port.ExcursionReviewSortRatingDesc {
		t.Fatalf("sort = %q, want %q", filter.Sort, port.ExcursionReviewSortRatingDesc)
	}
	if filter.Limit != 11 {
		t.Fatalf("limit = %d, want requested limit + 1", filter.Limit)
	}
}
