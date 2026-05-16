package http

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

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

type excursionOffersRepoStub struct {
	lastOfferFilter port.ExcursionOfferFilter
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

func (s *excursionOffersRepoStub) GetExcursionOfferByID(context.Context, uuid.UUID) (*model.ExcursionOffer, error) {
	return nil, nil
}

func (s *excursionOffersRepoStub) LoadExcursionOfferRelations(context.Context, uuid.UUID) (port.ExcursionOfferRelations, error) {
	return port.ExcursionOfferRelations{}, nil
}

func (s *excursionOffersRepoStub) CreateExcursionBooking(context.Context, *model.ExcursionBooking) error {
	return nil
}
