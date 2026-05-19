package http

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
)

func TestListExcursionProductOffersParsesSearchSortPaginationAndPinnedGuide(t *testing.T) {
	productID := uuid.New()
	preferredGuideUserID := uuid.New()
	repo := &excursionOffersRepoStub{}
	handler := NewHandler(app.NewExcursionUseCase(repo, nil, nil), nil)

	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/excursion-products/"+productID.String()+"/offers?limit=8&offset=16&q=aruzhan&sort=rating&sortDirection=asc&languageCode=ru&priceMax=50000&maxGroupSizeMin=3&preferredGuideUserId="+preferredGuideUserID.String(),
		nil,
	)
	req.SetPathValue("id", productID.String())
	rec := httptest.NewRecorder()

	handler.ListExcursionProductOffers(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if repo.lastOfferFilter.ProductID != productID {
		t.Fatalf("product id = %s, want %s", repo.lastOfferFilter.ProductID, productID)
	}
	if repo.lastOfferFilter.Limit != 9 || repo.lastOfferFilter.Offset != 16 {
		t.Fatalf("limit/offset = %d/%d, want 9/16", repo.lastOfferFilter.Limit, repo.lastOfferFilter.Offset)
	}
	if repo.lastOfferFilter.SearchQuery == nil || *repo.lastOfferFilter.SearchQuery != "aruzhan" {
		t.Fatalf("search query = %#v, want aruzhan", repo.lastOfferFilter.SearchQuery)
	}
	if repo.lastOfferFilter.Sort != "rating" {
		t.Fatalf("sort = %q, want rating", repo.lastOfferFilter.Sort)
	}
	if repo.lastOfferFilter.SortDirection != "asc" {
		t.Fatalf("sort direction = %q, want asc", repo.lastOfferFilter.SortDirection)
	}
	if repo.lastOfferFilter.PreferredGuideUserID == nil || *repo.lastOfferFilter.PreferredGuideUserID != preferredGuideUserID {
		t.Fatalf("preferred guide = %#v, want %s", repo.lastOfferFilter.PreferredGuideUserID, preferredGuideUserID)
	}
	if repo.lastOfferFilter.LanguageCode == nil || *repo.lastOfferFilter.LanguageCode != "ru" {
		t.Fatalf("language = %#v, want ru", repo.lastOfferFilter.LanguageCode)
	}
	if repo.lastOfferFilter.PriceMax == nil || *repo.lastOfferFilter.PriceMax != 50000 {
		t.Fatalf("price max = %#v, want 50000", repo.lastOfferFilter.PriceMax)
	}
	if repo.lastOfferFilter.MaxGroupSizeMin == nil || *repo.lastOfferFilter.MaxGroupSizeMin != 3 {
		t.Fatalf("max group min = %#v, want 3", repo.lastOfferFilter.MaxGroupSizeMin)
	}

	var payload struct {
		Items   []any `json:"items"`
		HasMore bool  `json:"hasMore"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if len(payload.Items) != 0 || payload.HasMore {
		t.Fatalf("unexpected payload: %+v", payload)
	}
}

func TestListGuideExcursionLanguagesParsesGuideUserIDsAndReturnsLanguages(t *testing.T) {
	guideUserID := uuid.New()
	repo := &excursionOffersRepoStub{
		guideLanguageCodes: map[uuid.UUID][]string{
			guideUserID: []string{"kk", "ru"},
		},
	}
	handler := NewHandler(app.NewExcursionUseCase(repo, nil, nil), nil)

	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/guides/excursion-languages?guideUserIds="+guideUserID.String()+","+guideUserID.String(),
		nil,
	)
	rec := httptest.NewRecorder()

	handler.ListGuideExcursionLanguages(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	if len(repo.lastGuideUserIDs) != 1 || repo.lastGuideUserIDs[0] != guideUserID {
		t.Fatalf("guide user ids = %#v, want only %s", repo.lastGuideUserIDs, guideUserID)
	}

	var payload struct {
		Items []struct {
			GuideUserID   string   `json:"guideUserId"`
			LanguageCodes []string `json:"languageCodes"`
		} `json:"items"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if len(payload.Items) != 1 {
		t.Fatalf("items = %d, want 1: %s", len(payload.Items), rec.Body.String())
	}
	if payload.Items[0].GuideUserID != guideUserID.String() {
		t.Fatalf("guide user id = %q, want %s", payload.Items[0].GuideUserID, guideUserID)
	}
	if got := fmt.Sprint(payload.Items[0].LanguageCodes); got != "[kk ru]" {
		t.Fatalf("languages = %s, want [kk ru]", got)
	}
}

func TestListGuideExcursionLanguagesRejectsTooManyGuideUserIDs(t *testing.T) {
	repo := &excursionOffersRepoStub{}
	handler := NewHandler(app.NewExcursionUseCase(repo, nil, nil), nil)

	ids := make([]string, 0, 101)
	for i := 0; i < 101; i++ {
		ids = append(ids, uuid.NewString())
	}
	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/guides/excursion-languages?guideUserIds="+strings.Join(ids, ","),
		nil,
	)
	rec := httptest.NewRecorder()

	handler.ListGuideExcursionLanguages(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", rec.Code)
	}
	if len(repo.lastGuideUserIDs) != 0 {
		t.Fatalf("repository was called with %#v", repo.lastGuideUserIDs)
	}
}

type excursionOffersRepoStub struct {
	lastOfferFilter    port.ExcursionOfferFilter
	listReviewFilter   port.ExcursionReviewFilter
	lastGuideUserIDs   []uuid.UUID
	guideLanguageCodes map[uuid.UUID][]string
}

func (s *excursionOffersRepoStub) CreateExcursionAggregate(context.Context, *model.Excursion, port.ExcursionRelations) error {
	return nil
}

func (s *excursionOffersRepoStub) UpdateExcursionAggregate(context.Context, *model.Excursion, port.ExcursionRelations) error {
	return nil
}

func (s *excursionOffersRepoStub) UpdateExcursion(context.Context, *model.Excursion) error {
	return nil
}

func (s *excursionOffersRepoStub) GetExcursionByID(context.Context, uuid.UUID) (*model.Excursion, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) ListExcursions(context.Context, port.ExcursionFilter) ([]*model.Excursion, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) LoadExcursionRelations(context.Context, uuid.UUID) (port.ExcursionRelations, error) {
	return port.ExcursionRelations{}, nil
}

func (s *excursionOffersRepoStub) CreateExcursionEvent(context.Context, *model.ExcursionEvent) error {
	return nil
}

func (s *excursionOffersRepoStub) ListExcursionProductCards(context.Context, port.ExcursionProductFilter) ([]*model.ExcursionProductCard, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) GetExcursionProductCardByID(context.Context, uuid.UUID) (*model.ExcursionProductCard, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) ListExcursionOffers(_ context.Context, filter port.ExcursionOfferFilter) ([]*model.ExcursionOffer, error) {
	s.lastOfferFilter = filter
	return nil, nil
}

func (s *excursionOffersRepoStub) ListExcursionLanguageCodesByGuideUserIDs(_ context.Context, guideUserIDs []uuid.UUID) (map[uuid.UUID][]string, error) {
	s.lastGuideUserIDs = append([]uuid.UUID(nil), guideUserIDs...)
	return s.guideLanguageCodes, nil
}

func (s *excursionOffersRepoStub) HasActiveExcursionForGuideLandmark(context.Context, uuid.UUID, uuid.UUID) (bool, error) {
	return false, nil
}

func (s *excursionOffersRepoStub) GetExcursionOfferByID(context.Context, uuid.UUID) (*model.ExcursionOffer, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) GetExcursionOfferByLegacyExcursionID(context.Context, uuid.UUID) (*model.ExcursionOffer, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) LoadExcursionOfferRelations(context.Context, uuid.UUID) (port.ExcursionOfferRelations, error) {
	return port.ExcursionOfferRelations{}, nil
}

func (s *excursionOffersRepoStub) CreateExcursionBooking(context.Context, *model.ExcursionBooking) error {
	return nil
}

func (s *excursionOffersRepoStub) ListExcursionBookings(context.Context, port.ExcursionBookingFilter) ([]*model.ExcursionBookingListItem, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) GetExcursionBookingByID(context.Context, uuid.UUID) (*model.ExcursionBooking, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) GetExcursionBookingByTouristIDAndIdempotencyKey(context.Context, uuid.UUID, string) (*model.ExcursionBooking, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) UpdateExcursionBookingGuests(context.Context, *model.ExcursionBooking, int) error {
	return nil
}

func (s *excursionOffersRepoStub) CancelExcursionBooking(context.Context, *model.ExcursionBooking) error {
	return nil
}

func (s *excursionOffersRepoStub) CreateExcursionReview(context.Context, *model.ExcursionReview) error {
	return nil
}

func (s *excursionOffersRepoStub) GetExcursionReviewByBookingID(context.Context, uuid.UUID) (*model.ExcursionReview, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) ListExcursionReviews(_ context.Context, filter port.ExcursionReviewFilter) ([]*model.ExcursionReview, error) {
	s.listReviewFilter = filter
	return nil, nil
}

func (s *excursionOffersRepoStub) CalculateLandmarkReviewStats(context.Context, uuid.UUID) (float64, int, error) {
	return 0, 0, nil
}

func (s *excursionOffersRepoStub) CreateExcursionScheduleSlot(context.Context, *model.ExcursionScheduleSlot) error {
	return nil
}

func (s *excursionOffersRepoStub) CreateExcursionScheduleSeriesWithSlots(context.Context, *model.ExcursionScheduleSeries, []*model.ExcursionScheduleSlot) error {
	return nil
}

func (s *excursionOffersRepoStub) UpdateExcursionScheduleSlot(context.Context, *model.ExcursionScheduleSlot) error {
	return nil
}

func (s *excursionOffersRepoStub) DeleteExcursionScheduleSlot(context.Context, uuid.UUID, uuid.UUID) error {
	return nil
}

func (s *excursionOffersRepoStub) GetExcursionScheduleSlotByID(context.Context, uuid.UUID) (*model.ExcursionScheduleSlot, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) ListExcursionScheduleSlots(context.Context, port.ExcursionScheduleFilter) ([]*model.ExcursionScheduleSlot, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) ReserveExcursionScheduleSlotSeats(context.Context, uuid.UUID, int) error {
	return nil
}

func (s *excursionOffersRepoStub) ExpireUnbookedExcursionScheduleSlots(context.Context, time.Time, string) error {
	return nil
}

func (s *excursionOffersRepoStub) CompleteDueExcursionScheduleSlots(context.Context, time.Time, string, int) (int, error) {
	return 0, nil
}

func (s *excursionOffersRepoStub) CreateExcursionAttendanceQRIssue(context.Context, *model.ExcursionAttendanceQRIssue) error {
	return nil
}

func (s *excursionOffersRepoStub) WithTx(context.Context, func(port.ExcursionTxRepository) error) error {
	return nil
}
