package app

import (
	"context"
	"errors"
	"strings"
	"testing"

	"kz/inflap/backend/services/search-service/internal/domain/model"
)

func TestIndexingUpsertRejectsUnsupportedDomainBeforeRepositoryCall(t *testing.T) {
	repo := &fakeIndexRepository{}
	uc := NewIndexingUseCase(repo)

	err := uc.UpsertDocument(context.Background(), IndexDocumentInput{
		Domain:   "routes",
		EntityID: "route-1",
		Title:    map[string]string{"en": "Hidden route"},
		DeepLink: "/routes/route-1",
	})

	if !errors.Is(err, model.ErrUnsupportedDomain) {
		t.Fatalf("UpsertDocument error = %v, want ErrUnsupportedDomain", err)
	}
	if repo.upsertCalls != 0 {
		t.Fatalf("repository upsert calls = %d, want 0", repo.upsertCalls)
	}
}

func TestIndexingUpsertNormalizesDocumentDefaultsAndCallsRepository(t *testing.T) {
	repo := &fakeIndexRepository{}
	uc := NewIndexingUseCase(repo)

	err := uc.UpsertDocument(context.Background(), IndexDocumentInput{
		Domain:           "place",
		EntityID:         "place-1",
		Locale:           "RU",
		Title:            map[string]string{"ru": " Алматы "},
		Subtitle:         map[string]string{"ru": "Горы"},
		Tags:             []string{"Nature", "mountain"},
		DeepLink:         "/places/place-1",
		PopularityScore:  4.2,
		FreshnessScore:   -1,
		TrustScore:       0.75,
		EntityVersion:    0,
		Visibility:       "",
		ModerationStatus: "",
	})

	if err != nil {
		t.Fatalf("UpsertDocument returned error: %v", err)
	}
	if repo.upsertCalls != 1 {
		t.Fatalf("repository upsert calls = %d, want 1", repo.upsertCalls)
	}
	got := repo.lastDocument
	if got.Domain != model.DomainPlace {
		t.Fatalf("domain = %q, want place", got.Domain)
	}
	if got.Locale != "ru" {
		t.Fatalf("locale = %q, want ru", got.Locale)
	}
	if got.EntityVersion != 1 {
		t.Fatalf("entity version = %d, want 1", got.EntityVersion)
	}
	if got.Visibility != "public" {
		t.Fatalf("visibility = %q, want public", got.Visibility)
	}
	if got.ModerationStatus != "approved" {
		t.Fatalf("moderation status = %q, want approved", got.ModerationStatus)
	}
	if got.PopularityScore != 1 || got.FreshnessScore != 0 || got.TrustScore != 0.75 {
		t.Fatalf(
			"scores = popularity %.2f freshness %.2f trust %.2f, want 1/0/0.75",
			got.PopularityScore,
			got.FreshnessScore,
			got.TrustScore,
		)
	}
	assertContainsTokens(t, got.SearchTextNormalized, "алматы", "горы", "nature", "mountain", "алмата", "almaty", "almty", "gory")
}

func TestIndexingUpsertNormalizesAccentsAndCityAliases(t *testing.T) {
	repo := &fakeIndexRepository{}
	uc := NewIndexingUseCase(repo)

	err := uc.UpsertDocument(context.Background(), IndexDocumentInput{
		Domain:   "place",
		EntityID: "place-2",
		Locale:   "en",
		Title:    map[string]string{"en": "Álmty viewpoint"},
		DeepLink: "/places/place-2",
	})

	if err != nil {
		t.Fatalf("UpsertDocument returned error: %v", err)
	}
	got := repo.lastDocument.SearchTextNormalized
	assertContainsTokens(t, got, "almty", "viewpoint", "алматы", "алмата", "almaty", "almata")
}

func TestIndexingUpsertAddsLatinAliasesForCyrillicSearchText(t *testing.T) {
	repo := &fakeIndexRepository{}
	uc := NewIndexingUseCase(repo)

	err := uc.UpsertDocument(context.Background(), IndexDocumentInput{
		Domain:   "place",
		EntityID: "place-charyn",
		Locale:   "ru",
		Title:    map[string]string{"ru": "Чарынский каньон"},
		DeepLink: "/places/place-charyn",
	})

	if err != nil {
		t.Fatalf("UpsertDocument returned error: %v", err)
	}
	got := repo.lastDocument.SearchTextNormalized
	if !strings.Contains(got, "charyn") {
		t.Fatalf("search text normalized = %q, want latin alias containing charyn", got)
	}
}

func TestIndexingUpsertNormalizesEmptyArrayFieldsForRepository(t *testing.T) {
	repo := &fakeIndexRepository{}
	uc := NewIndexingUseCase(repo)

	err := uc.UpsertDocument(context.Background(), IndexDocumentInput{
		Domain:   "place",
		EntityID: "place-without-variants",
		Title:    map[string]string{"en": "Charyn Canyon"},
		DeepLink: "/places/place-without-variants",
	})

	if err != nil {
		t.Fatalf("UpsertDocument returned error: %v", err)
	}
	if repo.lastDocument.Tags == nil {
		t.Fatal("tags = nil, want empty slice")
	}
	if repo.lastDocument.CategoryCodes == nil {
		t.Fatal("category codes = nil, want empty slice")
	}
	if repo.lastDocument.SearchVariants == nil {
		t.Fatal("search variants = nil, want empty slice")
	}
}

func TestIndexingDeleteNormalizesIdentityAndCallsRepository(t *testing.T) {
	repo := &fakeIndexRepository{}
	uc := NewIndexingUseCase(repo)

	err := uc.DeleteDocument(context.Background(), DeleteDocumentInput{
		Domain:   "guide",
		EntityID: " guide-1 ",
		Locale:   "KK",
	})

	if err != nil {
		t.Fatalf("DeleteDocument returned error: %v", err)
	}
	if repo.deleteCalls != 1 {
		t.Fatalf("repository delete calls = %d, want 1", repo.deleteCalls)
	}
	if repo.lastDeleteDomain != model.DomainGuide ||
		repo.lastDeleteEntityID != "guide-1" ||
		repo.lastDeleteLocale != "kk" {
		t.Fatalf(
			"delete identity = %q/%q/%q, want guide/guide-1/kk",
			repo.lastDeleteDomain,
			repo.lastDeleteEntityID,
			repo.lastDeleteLocale,
		)
	}
}

type fakeIndexRepository struct {
	upsertCalls        int
	deleteCalls        int
	lastDocument       model.SearchDocument
	lastDeleteDomain   model.Domain
	lastDeleteEntityID string
	lastDeleteLocale   string
	upsertErr          error
	deleteErr          error
}

func (r *fakeIndexRepository) UpsertDocument(_ context.Context, document model.SearchDocument) error {
	r.upsertCalls++
	r.lastDocument = document
	return r.upsertErr
}

func (r *fakeIndexRepository) DeleteDocument(_ context.Context, domain model.Domain, entityID string, locale string) error {
	r.deleteCalls++
	r.lastDeleteDomain = domain
	r.lastDeleteEntityID = entityID
	r.lastDeleteLocale = locale
	return r.deleteErr
}

func assertContainsTokens(t *testing.T, value string, tokens ...string) {
	t.Helper()

	fields := strings.Fields(value)
	seen := make(map[string]struct{}, len(fields))
	for _, field := range fields {
		seen[field] = struct{}{}
	}
	for _, token := range tokens {
		if _, ok := seen[token]; !ok {
			t.Fatalf("search text normalized = %q, missing token %q", value, token)
		}
	}
}
