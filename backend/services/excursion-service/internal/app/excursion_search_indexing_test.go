package app

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/enum"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

func TestCreateDraftExcursionDeletesSearchDocument(t *testing.T) {
	t.Parallel()

	actorUserID := uuid.New()
	indexer := &excursionSearchIndexerStub{}
	uc := NewExcursionUseCase(&excursionRepoStub{}, guideVerifierStub{
		result: trustedGuidePermission(actorUserID),
	}, nil)
	uc.SetSearchIndexer(indexer)

	aggregate, err := uc.CreateExcursion(context.Background(), validSearchCreateExcursionInput(actorUserID))
	if err != nil {
		t.Fatalf("CreateExcursion() error = %v", err)
	}

	if len(indexer.upserts) != 0 {
		t.Fatalf("search upserts = %d, want 0", len(indexer.upserts))
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("search deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].Domain != "excursion" || indexer.deletes[0].EntityID != aggregate.Excursion.ID.String() {
		t.Fatalf("delete request = %#v", indexer.deletes[0])
	}
}

func TestPublishPublicExcursionIndexesSearchDocument(t *testing.T) {
	t.Parallel()

	guideProfileID := uuid.New()
	guideUserID := uuid.New()
	excursion := mustNewAppTestExcursion(t, guideProfileID, guideUserID)
	departureCityID := "almaty"
	excursion.DepartureCityID = &departureCityID
	relations := validAppTestExcursionRelations(excursion.ID)
	relations.Tags = []string{"mountain", "private"}
	relations.LanguageCodes = []string{"en", "ru"}

	indexer := &excursionSearchIndexerStub{}
	repo := &excursionRepoStub{
		gotExcursion:    excursion,
		loadedRelations: relations,
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: trustedGuidePermission(guideUserID),
	}, nil)
	uc.SetSearchIndexer(indexer)

	aggregate, err := uc.PublishExcursion(context.Background(), excursion.ID, guideUserID)
	if err != nil {
		t.Fatalf("PublishExcursion() error = %v", err)
	}

	if aggregate.Excursion.Status != enum.ExcursionStatusPublished {
		t.Fatalf("status = %s, want PUBLISHED", aggregate.Excursion.Status)
	}
	if len(indexer.upserts) != 1 {
		t.Fatalf("search upserts = %d, want 1", len(indexer.upserts))
	}
	if len(indexer.deletes) != 0 {
		t.Fatalf("search deletes = %d, want 0", len(indexer.deletes))
	}

	doc := indexer.upserts[0]
	if doc.Domain != "excursion" || doc.EntityID != excursion.ID.String() {
		t.Fatalf("domain/entity = %q/%q, want excursion/%s", doc.Domain, doc.EntityID, excursion.ID)
	}
	if doc.Locale != "en" || doc.Title["en"] != "Medeu tour" {
		t.Fatalf("locale/title = %q/%#v", doc.Locale, doc.Title)
	}
	if doc.DeepLink != "/excursions/"+excursion.ID.String() {
		t.Fatalf("deep link = %q", doc.DeepLink)
	}
	if doc.CityID != "almaty" || doc.CountryCode != "KZ" {
		t.Fatalf("location = %q/%q, want almaty/KZ", doc.CityID, doc.CountryCode)
	}
	if doc.PriceMin == nil || *doc.PriceMin != 120 || doc.Currency != "KZT" {
		t.Fatalf("price = %#v %q", doc.PriceMin, doc.Currency)
	}
	if doc.Rating == nil || *doc.Rating != trustedGuidePermission(guideUserID).RatingAvg {
		t.Fatalf("rating = %#v", doc.Rating)
	}
	if !containsString(doc.Tags, "mountain") || !containsString(doc.CategoryCodes, "nature") {
		t.Fatalf("tags/categories = %#v/%#v", doc.Tags, doc.CategoryCodes)
	}
	if doc.Visibility != "public" || doc.ModerationStatus != "approved" {
		t.Fatalf("visibility/moderation = %q/%q", doc.Visibility, doc.ModerationStatus)
	}
	if doc.SearchTextNormalized == "" {
		t.Fatal("search text normalized is empty")
	}
}

func TestDeleteDraftExcursionDeletesSearchDocument(t *testing.T) {
	t.Parallel()

	guideProfileID := uuid.New()
	guideUserID := uuid.New()
	excursion := mustNewAppTestExcursion(t, guideProfileID, guideUserID)
	indexer := &excursionSearchIndexerStub{}
	repo := &excursionRepoStub{
		gotExcursion:    excursion,
		loadedRelations: validAppTestExcursionRelations(excursion.ID),
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)
	uc.SetSearchIndexer(indexer)

	err := uc.DeleteExcursion(context.Background(), excursion.ID, guideUserID)
	if err != nil {
		t.Fatalf("DeleteExcursion() error = %v", err)
	}

	if len(indexer.deletes) != 1 {
		t.Fatalf("search deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].Domain != "excursion" || indexer.deletes[0].EntityID != excursion.ID.String() {
		t.Fatalf("delete request = %#v", indexer.deletes[0])
	}
}

type excursionSearchIndexerStub struct {
	upserts []SearchIndexDocument
	deletes []SearchIndexDelete
}

func (s *excursionSearchIndexerStub) UpsertSearchDocument(_ context.Context, document SearchIndexDocument) error {
	s.upserts = append(s.upserts, document)
	return nil
}

func (s *excursionSearchIndexerStub) DeleteSearchDocument(_ context.Context, deletion SearchIndexDelete) error {
	s.deletes = append(s.deletes, deletion)
	return nil
}

func trustedGuidePermission(guideUserID uuid.UUID) port.GuideExcursionPermission {
	return port.GuideExcursionPermission{
		GuideProfileID:   uuid.New(),
		GuideUserID:      guideUserID,
		Allowed:          true,
		RatingAvg:        4.8,
		ReviewsCount:     12,
		ExperienceYears:  3,
		GuideDisplayName: "Aruzhan Guide",
		GuideSearchText:  "aruzhan almaty mountains",
	}
}

func validSearchCreateExcursionInput(actorUserID uuid.UUID) CreateExcursionInput {
	latitude := 43.157
	longitude := 77.058
	departureCityID := "almaty"
	landmarkID := uuid.New()

	return CreateExcursionInput{
		ActorUserID:     actorUserID,
		LandmarkID:      &landmarkID,
		LandmarkName:    stringPtr("Medeu"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 180,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     stringPtr("KZ"),
		CityName:        stringPtr("Almaty"),
		DepartureCityID: &departureCityID,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &latitude,
		Longitude:       &longitude,
		PriceAmount:     45000,
		Currency:        "KZT",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, PlaceID: uuidPtr(uuid.New()), PlaceName: stringPtr("Medeu"), Title: "Medeu", Description: "Start with the mountain view."},
		},
	}
}
