package http

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/port"
)

func TestListTourProductOffersParsesSearchSortPaginationAndPinnedGuide(t *testing.T) {
	productID := uuid.New()
	preferredGuideUserID := uuid.New()
	repo := &tourOffersRepoStub{}
	handler := NewHandler(app.NewTourUseCase(repo, nil, nil), nil)

	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/tour-products/"+productID.String()+"/offers?limit=8&offset=16&q=aruzhan&sort=rating&sortDirection=asc&languageCode=ru&priceMax=50000&maxGroupSizeMin=3&preferredGuideUserId="+preferredGuideUserID.String(),
		nil,
	)
	req.SetPathValue("id", productID.String())
	rec := httptest.NewRecorder()

	handler.ListTourProductOffers(rec, req)

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

type tourOffersRepoStub struct {
	lastOfferFilter port.TourOfferFilter
}

func (s *tourOffersRepoStub) CreateTourAggregate(context.Context, *model.Tour, port.TourRelations) error {
	return nil
}

func (s *tourOffersRepoStub) UpdateTourAggregate(context.Context, *model.Tour, port.TourRelations) error {
	return nil
}

func (s *tourOffersRepoStub) UpdateTour(context.Context, *model.Tour) error { return nil }

func (s *tourOffersRepoStub) GetTourByID(context.Context, uuid.UUID) (*model.Tour, error) {
	return nil, nil
}

func (s *tourOffersRepoStub) ListTours(context.Context, port.TourFilter) ([]*model.Tour, error) {
	return nil, nil
}

func (s *tourOffersRepoStub) LoadTourRelations(context.Context, uuid.UUID) (port.TourRelations, error) {
	return port.TourRelations{}, nil
}

func (s *tourOffersRepoStub) CreateTourEvent(context.Context, *model.TourEvent) error { return nil }

func (s *tourOffersRepoStub) ListTourProductCards(context.Context, port.TourProductFilter) ([]*model.TourProductCard, error) {
	return nil, nil
}

func (s *tourOffersRepoStub) GetTourProductCardByID(context.Context, uuid.UUID) (*model.TourProductCard, error) {
	return nil, nil
}

func (s *tourOffersRepoStub) ListTourOffers(_ context.Context, filter port.TourOfferFilter) ([]*model.TourOffer, error) {
	s.lastOfferFilter = filter
	return nil, nil
}

func (s *tourOffersRepoStub) GetTourOfferByID(context.Context, uuid.UUID) (*model.TourOffer, error) {
	return nil, nil
}

func (s *tourOffersRepoStub) LoadTourOfferRelations(context.Context, uuid.UUID) (port.TourOfferRelations, error) {
	return port.TourOfferRelations{}, nil
}

func (s *tourOffersRepoStub) CreateTourBooking(context.Context, *model.TourBooking) error {
	return nil
}
