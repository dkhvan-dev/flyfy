package http

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
)

func TestCreateGuideScheduleSlotParsesRequest(t *testing.T) {
	actorUserID := uuid.New()
	offerID := uuid.New()
	startAt := time.Now().UTC().Add(24 * time.Hour).Truncate(time.Second)
	repo := &excursionScheduleHTTPRepoStub{
		offer: &model.ExcursionOffer{
			ID:              offerID,
			ProductID:       uuid.New(),
			GuideProfileID:  uuid.New(),
			GuideUserID:     actorUserID,
			Status:          enum.ExcursionStatusPublished,
			Visibility:      enum.ExcursionVisibilityPublic,
			DurationMinutes: 240,
			MaxGroupSize:    6,
			MeetingPoint:    "Medeu entrance",
			PriceAmount:     120,
			Currency:        "KZT",
		},
	}
	handler := NewHandler(app.NewExcursionUseCase(repo, nil, nil), nil)
	body := bytes.NewBufferString(`{"offerId":"` + offerID.String() + `","startAt":"` + startAt.Format(time.RFC3339) + `","timezone":"Asia/Almaty","capacity":6}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/me/excursion-schedule/slots", body)
	req = req.WithContext(withUserID(req.Context(), actorUserID.String()))
	rec := httptest.NewRecorder()

	handler.CreateGuideScheduleSlot(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	var payload struct {
		ID       string `json:"id"`
		OfferID  string `json:"offerId"`
		StartAt  string `json:"startAt"`
		EndAt    string `json:"endAt"`
		Status   string `json:"status"`
		Capacity int    `json:"capacity"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if payload.ID == "" || payload.OfferID != offerID.String() || payload.Status != "AVAILABLE" || payload.Capacity != 6 {
		t.Fatalf("payload = %+v", payload)
	}
	if repo.createdScheduleSlot == nil || repo.createdScheduleSlot.StartAt != startAt {
		t.Fatalf("created slot = %#v, want start %v", repo.createdScheduleSlot, startAt)
	}
}

func TestUpdateGuideScheduleSlotParsesRequest(t *testing.T) {
	actorUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	startAt := time.Date(2026, 5, 29, 9, 30, 0, 0, time.UTC)
	repo := &excursionScheduleHTTPRepoStub{
		offer: &model.ExcursionOffer{
			ID:              offerID,
			ProductID:       uuid.New(),
			GuideProfileID:  uuid.New(),
			GuideUserID:     actorUserID,
			Status:          enum.ExcursionStatusPublished,
			Visibility:      enum.ExcursionVisibilityPublic,
			DurationMinutes: 180,
			MaxGroupSize:    8,
			MeetingPoint:    "Medeu entrance",
			PriceAmount:     120,
			Currency:        "KZT",
		},
		scheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			OfferID:        uuid.New(),
			ProductID:      uuid.New(),
			StartAt:        time.Date(2026, 5, 22, 9, 0, 0, 0, time.UTC),
			EndAt:          time.Date(2026, 5, 22, 11, 0, 0, 0, time.UTC),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			Status:         enum.ExcursionScheduleSlotStatusAvailable,
		},
	}
	handler := NewHandler(app.NewExcursionUseCase(repo, nil, nil), nil)
	mux := http.NewServeMux()
	handler.Register(mux)
	body := bytes.NewBufferString(`{"offerId":"` + offerID.String() + `","startAt":"` + startAt.Format(time.RFC3339) + `","timezone":"Asia/Almaty","capacity":5}`)
	req := httptest.NewRequest(http.MethodPatch, "/v1/me/excursion-schedule/slots/"+slotID.String(), body)
	req = req.WithContext(withUserID(req.Context(), actorUserID.String()))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if repo.updatedScheduleSlot == nil || repo.updatedScheduleSlot.StartAt != startAt {
		t.Fatalf("updated slot = %#v, want start %v", repo.updatedScheduleSlot, startAt)
	}
	if repo.updatedScheduleSlot.OfferID != offerID || repo.updatedScheduleSlot.Capacity != 5 {
		t.Fatalf("updated offer/capacity = %s/%d, want %s/5", repo.updatedScheduleSlot.OfferID, repo.updatedScheduleSlot.Capacity, offerID)
	}
}

func TestListPublicExcursionScheduleParsesQuery(t *testing.T) {
	productID := uuid.New()
	offerID := uuid.New()
	startAt := time.Date(2026, 6, 2, 9, 0, 0, 0, time.UTC)
	repo := &excursionScheduleHTTPRepoStub{
		offer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    uuid.New(),
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   8,
			PriceAmount:    120,
			Currency:       "KZT",
		},
		scheduleSlots: []*model.ExcursionScheduleSlot{
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    uuid.New(),
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        startAt,
				EndAt:          startAt.Add(3 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				BookedSeats:    2,
				Status:         enum.ExcursionScheduleSlotStatusBooked,
				Title:          "Medeu sunrise walk",
			},
		},
	}
	handler := NewHandler(app.NewExcursionUseCase(repo, nil, nil), nil)
	mux := http.NewServeMux()
	handler.Register(mux)
	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/excursion-products/"+productID.String()+"/schedule?offerId="+offerID.String()+"&from=2026-06-01T00:00:00Z&to=2026-06-08T00:00:00Z&seats=3",
		nil,
	)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	var payload struct {
		Items []struct {
			OfferID     string `json:"offerId"`
			ProductID   string `json:"productId"`
			BookedSeats int    `json:"bookedSeats"`
			Title       string `json:"title"`
		} `json:"items"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if len(payload.Items) != 1 {
		t.Fatalf("items len = %d, want 1", len(payload.Items))
	}
	if payload.Items[0].OfferID != offerID.String() || payload.Items[0].ProductID != productID.String() {
		t.Fatalf("payload item = %+v", payload.Items[0])
	}
	if repo.listScheduleFilter.OfferID == nil || *repo.listScheduleFilter.OfferID != offerID {
		t.Fatalf("offer filter = %v, want %s", repo.listScheduleFilter.OfferID, offerID)
	}
}

func TestListPublicGuideScheduleParsesPathAndQuery(t *testing.T) {
	guideUserID := uuid.New()
	startAt := time.Date(2026, 6, 3, 9, 0, 0, 0, time.UTC)
	repo := &excursionScheduleHTTPRepoStub{
		scheduleSlots: []*model.ExcursionScheduleSlot{
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        uuid.New(),
				ProductID:      uuid.New(),
				StartAt:        startAt,
				EndAt:          startAt.Add(2 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				Status:         enum.ExcursionScheduleSlotStatusAvailable,
				Title:          "Almaty old town",
			},
		},
	}
	handler := NewHandler(app.NewExcursionUseCase(repo, nil, nil), nil)
	mux := http.NewServeMux()
	handler.Register(mux)
	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/excursion-guides/"+guideUserID.String()+"/schedule?from=2026-06-01T00:00:00Z&to=2026-06-08T00:00:00Z",
		nil,
	)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	var payload struct {
		Items []struct {
			Title string `json:"title"`
		} `json:"items"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if len(payload.Items) != 1 || payload.Items[0].Title != "Almaty old town" {
		t.Fatalf("payload = %+v", payload)
	}
	if repo.listScheduleFilter.GuideUserID == nil || *repo.listScheduleFilter.GuideUserID != guideUserID {
		t.Fatalf("guide filter = %v, want %s", repo.listScheduleFilter.GuideUserID, guideUserID)
	}
}

type excursionScheduleHTTPRepoStub struct {
	offer               *model.ExcursionOffer
	scheduleSlot        *model.ExcursionScheduleSlot
	scheduleSlots       []*model.ExcursionScheduleSlot
	createdScheduleSlot *model.ExcursionScheduleSlot
	updatedScheduleSlot *model.ExcursionScheduleSlot
	listScheduleFilter  port.ExcursionScheduleFilter
}

func (s *excursionScheduleHTTPRepoStub) CreateExcursionAggregate(context.Context, *model.Excursion, port.ExcursionRelations) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) UpdateExcursionAggregate(context.Context, *model.Excursion, port.ExcursionRelations) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) UpdateExcursion(context.Context, *model.Excursion) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) GetExcursionByID(context.Context, uuid.UUID) (*model.Excursion, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) ListExcursions(context.Context, port.ExcursionFilter) ([]*model.Excursion, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) LoadExcursionRelations(context.Context, uuid.UUID) (port.ExcursionRelations, error) {
	return port.ExcursionRelations{}, nil
}

func (s *excursionScheduleHTTPRepoStub) CreateExcursionEvent(context.Context, *model.ExcursionEvent) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) ListExcursionProductCards(context.Context, port.ExcursionProductFilter) ([]*model.ExcursionProductCard, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) GetExcursionProductCardByID(context.Context, uuid.UUID) (*model.ExcursionProductCard, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) ListExcursionOffers(context.Context, port.ExcursionOfferFilter) ([]*model.ExcursionOffer, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) ListExcursionLanguageCodesByGuideUserIDs(context.Context, []uuid.UUID) (map[uuid.UUID][]string, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) ListGuideUserIDsByExcursionCity(context.Context, port.GuideExcursionCityFilter) ([]uuid.UUID, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) HasActiveExcursionForGuideLandmark(context.Context, uuid.UUID, uuid.UUID) (bool, error) {
	return false, nil
}

func (s *excursionScheduleHTTPRepoStub) ArchiveGuideExcursionOffers(context.Context, uuid.UUID) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) GetExcursionOfferByID(context.Context, uuid.UUID) (*model.ExcursionOffer, error) {
	return s.offer, nil
}

func (s *excursionScheduleHTTPRepoStub) GetExcursionOfferByLegacyExcursionID(context.Context, uuid.UUID) (*model.ExcursionOffer, error) {
	return s.offer, nil
}

func (s *excursionScheduleHTTPRepoStub) LoadExcursionOfferRelations(context.Context, uuid.UUID) (port.ExcursionOfferRelations, error) {
	return port.ExcursionOfferRelations{}, nil
}

func (s *excursionScheduleHTTPRepoStub) CreateExcursionBooking(context.Context, *model.ExcursionBooking) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) ListExcursionBookings(context.Context, port.ExcursionBookingFilter) ([]*model.ExcursionBookingListItem, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) GetExcursionBookingByID(context.Context, uuid.UUID) (*model.ExcursionBooking, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) GetExcursionBookingByTouristIDAndIdempotencyKey(context.Context, uuid.UUID, string) (*model.ExcursionBooking, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) UpdateExcursionBookingGuests(context.Context, *model.ExcursionBooking, int) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) CancelExcursionBooking(context.Context, *model.ExcursionBooking) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) CreateExcursionReview(context.Context, *model.ExcursionReview) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) UpdateExcursionReview(context.Context, *model.ExcursionReview) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) DeleteExcursionReview(context.Context, *model.ExcursionReview) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) GetExcursionReviewByBookingID(context.Context, uuid.UUID) (*model.ExcursionReview, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) CreateGuideReview(context.Context, *model.GuideReview) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) UpdateGuideReview(context.Context, *model.GuideReview) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) DeleteGuideReview(context.Context, *model.GuideReview) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) GetGuideReviewByBookingID(context.Context, uuid.UUID) (*model.GuideReview, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) ListExcursionReviews(context.Context, port.ExcursionReviewFilter) ([]*model.ExcursionReview, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) ListGuideReviews(context.Context, port.GuideReviewFilter) ([]*model.GuideReview, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) CalculateLandmarkReviewStats(context.Context, uuid.UUID) (float64, int, error) {
	return 0, 0, nil
}

func (s *excursionScheduleHTTPRepoStub) CreateExcursionScheduleSlot(_ context.Context, slot *model.ExcursionScheduleSlot) error {
	s.createdScheduleSlot = slot
	return nil
}

func (s *excursionScheduleHTTPRepoStub) CreateExcursionScheduleSeriesWithSlots(context.Context, *model.ExcursionScheduleSeries, []*model.ExcursionScheduleSlot) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) UpdateExcursionScheduleSlot(_ context.Context, slot *model.ExcursionScheduleSlot) error {
	s.updatedScheduleSlot = slot
	return nil
}

func (s *excursionScheduleHTTPRepoStub) DeleteExcursionScheduleSlot(context.Context, uuid.UUID, uuid.UUID) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) GetExcursionScheduleSlotByID(context.Context, uuid.UUID) (*model.ExcursionScheduleSlot, error) {
	return s.scheduleSlot, nil
}

func (s *excursionScheduleHTTPRepoStub) ListExcursionScheduleSlots(_ context.Context, filter port.ExcursionScheduleFilter) ([]*model.ExcursionScheduleSlot, error) {
	s.listScheduleFilter = filter
	return s.scheduleSlots, nil
}

func (s *excursionScheduleHTTPRepoStub) ReserveExcursionScheduleSlotSeats(context.Context, uuid.UUID, int) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) ExpireUnbookedExcursionScheduleSlots(context.Context, time.Time, string) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) CloseBookedExcursionScheduleSlots(context.Context, time.Time, int) ([]*model.ExcursionScheduleSlot, error) {
	return nil, nil
}

func (s *excursionScheduleHTTPRepoStub) CompleteDueExcursionScheduleSlots(context.Context, time.Time, string, int) (int, error) {
	return 0, nil
}

func (s *excursionScheduleHTTPRepoStub) CreateExcursionAttendanceQRIssue(context.Context, *model.ExcursionAttendanceQRIssue) error {
	return nil
}

func (s *excursionScheduleHTTPRepoStub) WithTx(context.Context, func(port.ExcursionTxRepository) error) error {
	return nil
}
