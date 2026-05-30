package http

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"kz/inflap/backend/services/excursion-service/internal/app"
	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
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

func TestListGuideReviewsParsesGuideFilterAndRatingSort(t *testing.T) {
	guideUserID := uuid.New()
	repo := &excursionOffersRepoStub{}
	handler := NewHandler(app.NewExcursionUseCase(repo, nil, nil), nil)

	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/guide-reviews?guideUserId="+guideUserID.String()+"&sort=rating_desc&limit=10",
		nil,
	)
	rec := httptest.NewRecorder()

	handler.ListGuideReviews(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", rec.Code)
	}
	filter := repo.listGuideReviewFilter
	if filter.GuideUserID == nil || *filter.GuideUserID != guideUserID {
		t.Fatalf("guide user filter = %v, want %s", filter.GuideUserID, guideUserID)
	}
	if filter.Sort != port.GuideReviewSortRatingDesc {
		t.Fatalf("sort = %q, want %q", filter.Sort, port.GuideReviewSortRatingDesc)
	}
	if filter.Limit != 11 {
		t.Fatalf("limit = %d, want requested limit + 1", filter.Limit)
	}
}

func TestPutBookingReviewsCreatesBothReviewTypesFromAuthenticatedActor(t *testing.T) {
	actorUserID := uuid.New()
	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       uuid.New(),
		OfferID:         uuid.New(),
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		TouristUserID:   actorUserID,
		ScheduledFor:    time.Now().UTC().Add(-24 * time.Hour),
		Adults:          1,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionOffersRepoStub{booking: booking}
	handler := NewHandler(app.NewExcursionUseCase(repo, nil, nil), nil)
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{
		"excursionReview":{"rating":4.5,"comment":"Updated route review"},
		"guideReview":{"rating":5,"comment":"Excellent guide"}
	}`)
	req := httptest.NewRequest(http.MethodPut, "/v1/me/excursion-bookings/"+booking.ID.String()+"/reviews", body)
	req = req.WithContext(withUserID(req.Context(), actorUserID.String()))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if repo.createdReview == nil || repo.createdGuideReview == nil {
		t.Fatalf("created excursion/guide reviews = %+v / %+v", repo.createdReview, repo.createdGuideReview)
	}
	if repo.createdReview.TouristUserID != actorUserID || repo.createdGuideReview.TouristUserID != actorUserID {
		t.Fatalf("review authors = %s / %s, want actor %s",
			repo.createdReview.TouristUserID, repo.createdGuideReview.TouristUserID, actorUserID)
	}

	var payload struct {
		ExcursionReview *struct {
			Rating float64 `json:"rating"`
		} `json:"excursionReview"`
		GuideReview *struct {
			Rating float64 `json:"rating"`
		} `json:"guideReview"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if payload.ExcursionReview == nil || payload.ExcursionReview.Rating != 4.5 ||
		payload.GuideReview == nil || payload.GuideReview.Rating != 5 {
		t.Fatalf("payload = %+v", payload)
	}
}
