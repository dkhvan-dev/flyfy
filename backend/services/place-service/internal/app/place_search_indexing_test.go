package app

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestCreatePublishedPlaceIndexesSearchDocument(t *testing.T) {
	t.Parallel()

	indexer := &placeSearchIndexerStub{}
	repo := &adminPlaceRepoStub{}
	uc := NewPlaceUseCase(
		repo,
		&adminPlaceUserClientStub{},
		WithPlaceSearchIndexer(indexer),
	)

	view, err := uc.CreatePlaceByAdmin(context.Background(), CreatePlaceInput{
		Title:         "Big Almaty Lake",
		Description:   "High-mountain lake near Almaty.",
		DefaultLocale: "en",
		Translations: map[string]PlaceTranslationInput{
			"ru": {Title: "Большое Алматинское озеро", Description: "Озеро рядом с Алматы."},
			"kk": {Title: "Үлкен Алматы көлі", Description: "Алматы маңындағы көл."},
		},
		CountryCode:   "KZ",
		CityID:        "almaty",
		Latitude:      ptrFloat64(43.05),
		Longitude:     ptrFloat64(76.98),
		Category:      "NATURE",
		PriceAmount:   ptrFloat64(1500),
		PriceCurrency: ptrString("kzt"),
		Rating:        4.7,
		Tags:          []string{"lake", "mountains"},
		Status:        "PUBLISHED",
	})
	if err != nil {
		t.Fatalf("CreatePlaceByAdmin() error = %v", err)
	}

	if len(indexer.upserts) != 1 {
		t.Fatalf("search upserts = %d, want 1", len(indexer.upserts))
	}
	doc := indexer.upserts[0]
	if doc.EntityID != view.Place.ID.String() {
		t.Fatalf("entity id = %q, want %s", doc.EntityID, view.Place.ID)
	}
	if doc.Domain != "place" || doc.Locale != "en" {
		t.Fatalf("domain/locale = %q/%q, want place/en", doc.Domain, doc.Locale)
	}
	if doc.Title["ru"] != "Большое Алматинское озеро" || doc.Title["kk"] != "Үлкен Алматы көлі" {
		t.Fatalf("localized titles = %#v", doc.Title)
	}
	if doc.DeepLink != "/places/"+view.Place.ID.String() {
		t.Fatalf("deep link = %q", doc.DeepLink)
	}
	if doc.Visibility != "public" || doc.ModerationStatus != "approved" {
		t.Fatalf("visibility/moderation = %q/%q", doc.Visibility, doc.ModerationStatus)
	}
	if doc.PriceMin == nil || *doc.PriceMin != 1500 || doc.Currency != "KZT" {
		t.Fatalf("price = %#v %q", doc.PriceMin, doc.Currency)
	}
	if doc.Rating == nil || *doc.Rating != 4.7 {
		t.Fatalf("rating = %#v", doc.Rating)
	}
	if doc.SearchTextNormalized == "" {
		t.Fatal("search text normalized is empty")
	}
}

func TestCreateDraftPlaceDeletesSearchDocument(t *testing.T) {
	t.Parallel()

	indexer := &placeSearchIndexerStub{}
	uc := NewPlaceUseCase(
		&adminPlaceRepoStub{},
		&adminPlaceUserClientStub{},
		WithPlaceSearchIndexer(indexer),
	)

	view, err := uc.CreatePlaceByAdmin(context.Background(), CreatePlaceInput{
		Title:         "Draft place",
		Description:   "Hidden draft",
		DefaultLocale: "en",
		CountryCode:   "KZ",
		CityID:        "almaty",
		Category:      "NATURE",
		Status:        "DRAFT",
	})
	if err != nil {
		t.Fatalf("CreatePlaceByAdmin() error = %v", err)
	}

	if len(indexer.upserts) != 0 {
		t.Fatalf("search upserts = %d, want 0", len(indexer.upserts))
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("search deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].EntityID != view.Place.ID.String() {
		t.Fatalf("deleted entity id = %q, want %s", indexer.deletes[0].EntityID, view.Place.ID)
	}
}

func TestDeletePlaceDeletesSearchDocument(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	ownerID := uuid.New()
	indexer := &placeSearchIndexerStub{}
	repo := &adminPlaceRepoStub{
		created: &model.Place{
			ID:           placeID,
			AuthorUserID: ownerID,
			Status:       enum.StatusPublished,
		},
	}
	uc := NewPlaceUseCase(
		repo,
		&adminPlaceUserClientStub{resolvedUserID: ownerID},
		WithPlaceSearchIndexer(indexer),
	)

	err := uc.DeletePlace(context.Background(), ownerID.String(), placeID, nil)
	if err != nil {
		t.Fatalf("DeletePlace() error = %v", err)
	}

	if len(indexer.deletes) != 1 {
		t.Fatalf("search deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].EntityID != placeID.String() || indexer.deletes[0].Domain != "place" {
		t.Fatalf("delete request = %#v", indexer.deletes[0])
	}
}

type placeSearchIndexerStub struct {
	upserts []SearchIndexDocument
	deletes []SearchIndexDelete
}

func (s *placeSearchIndexerStub) UpsertSearchDocument(_ context.Context, document SearchIndexDocument) error {
	s.upserts = append(s.upserts, document)
	return nil
}

func (s *placeSearchIndexerStub) DeleteSearchDocument(_ context.Context, deletion SearchIndexDelete) error {
	s.deletes = append(s.deletes, deletion)
	return nil
}

func ptrString(value string) *string {
	return &value
}

func ptrFloat64(value float64) *float64 {
	return &value
}
