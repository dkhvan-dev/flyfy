package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/model"
)

func TestListAttractionsUsesReadThroughCache(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	repo := &cacheAttractionRepoStub{
		listAttractions: []*model.Attraction{testCacheAttraction(attractionID, "First title")},
		listTotal:       1,
	}
	cache := newMemoryAttractionCacheStub()
	uc := NewAttractionUseCase(
		repo,
		&cacheUserClientStub{},
		WithAttractionCache(cache, time.Minute, time.Minute),
	)

	ctx := context.Background()
	input := ListAttractionsInput{CountryCode: "KZ", CityID: "almaty", Locale: "ru", Limit: 20}

	first, firstTotal, err := uc.ListAttractions(ctx, input)
	if err != nil {
		t.Fatalf("first ListAttractions() error = %v", err)
	}
	if firstTotal != 1 || len(first) != 1 || first[0].Attraction.Title != "First title" {
		t.Fatalf("first list = total %d items %#v, want cached source title", firstTotal, first)
	}

	repo.listAttractions = []*model.Attraction{testCacheAttraction(attractionID, "Stale repository title")}
	second, secondTotal, err := uc.ListAttractions(ctx, input)
	if err != nil {
		t.Fatalf("second ListAttractions() error = %v", err)
	}
	if repo.listCalls != 1 {
		t.Fatalf("repository list calls = %d, want 1", repo.listCalls)
	}
	if secondTotal != 1 || len(second) != 1 || second[0].Attraction.Title != "First title" {
		t.Fatalf("second list = total %d items %#v, want cached first response", secondTotal, second)
	}
}

func TestListAttractionsTreatsBaliCityAliasAsIndonesiaRegion(t *testing.T) {
	t.Parallel()

	repo := &cacheAttractionRepoStub{
		listAttractions: []*model.Attraction{testCacheAttraction(uuid.New(), "Bali attraction")},
		listTotal:       1,
	}
	uc := NewAttractionUseCase(repo, &cacheUserClientStub{})

	_, _, err := uc.ListAttractions(context.Background(), ListAttractionsInput{
		CountryCode: "ID",
		CityID:      "bali",
		Locale:      "ru",
	})
	if err != nil {
		t.Fatalf("ListAttractions() error = %v", err)
	}

	if repo.lastListFilter.CountryCode != "ID" || repo.lastListFilter.CityID != "" || repo.lastListFilter.RegionID != "bali" {
		t.Fatalf("repository filter = %#v, want country ID, empty city and Bali region", repo.lastListFilter)
	}
}

func TestGetAttractionUsesReadThroughCache(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	repo := &cacheAttractionRepoStub{
		attractionsByID: map[uuid.UUID]*model.Attraction{
			attractionID: testCacheAttraction(attractionID, "Medeu"),
		},
	}
	cache := newMemoryAttractionCacheStub()
	uc := NewAttractionUseCase(
		repo,
		&cacheUserClientStub{},
		WithAttractionCache(cache, time.Minute, time.Minute),
	)

	ctx := context.Background()
	first, err := uc.GetAttraction(ctx, attractionID, "ru")
	if err != nil {
		t.Fatalf("first GetAttraction() error = %v", err)
	}
	if first.Attraction.Title != "Medeu" {
		t.Fatalf("first title = %q, want Medeu", first.Attraction.Title)
	}

	repo.attractionsByID[attractionID] = testCacheAttraction(attractionID, "Repository changed")
	second, err := uc.GetAttraction(ctx, attractionID, "ru")
	if err != nil {
		t.Fatalf("second GetAttraction() error = %v", err)
	}
	if repo.getCalls != 1 {
		t.Fatalf("repository get calls = %d, want 1", repo.getCalls)
	}
	if second.Attraction.Title != "Medeu" {
		t.Fatalf("second title = %q, want cached Medeu", second.Attraction.Title)
	}
}

func TestAttractionMutationsInvalidateCachedReads(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	repo := &cacheAttractionRepoStub{
		attractionsByID: map[uuid.UUID]*model.Attraction{
			attractionID: testCacheAttraction(attractionID, "Before update"),
		},
		listAttractions: []*model.Attraction{testCacheAttraction(attractionID, "Before update")},
		listTotal:       1,
	}
	cache := newMemoryAttractionCacheStub()
	uc := NewAttractionUseCase(
		repo,
		&cacheUserClientStub{},
		WithAttractionCache(cache, time.Minute, time.Minute),
	)

	ctx := context.Background()
	_, _, err := uc.ListAttractions(ctx, ListAttractionsInput{CountryCode: "KZ", CityID: "almaty", Locale: "ru"})
	if err != nil {
		t.Fatalf("ListAttractions() warmup error = %v", err)
	}
	_, err = uc.GetAttraction(ctx, attractionID, "ru")
	if err != nil {
		t.Fatalf("GetAttraction() warmup error = %v", err)
	}

	updateInput := UpdateAttractionInput{
		Title:         "After update",
		Description:   "Updated description",
		DefaultLocale: "en",
		Translations: map[string]AttractionTranslationInput{
			"en": {Title: "After update", Description: "Updated description"},
		},
		CountryCode: "KZ",
		CityID:      "almaty",
		Category:    "NATURE",
		Status:      "PUBLISHED",
	}
	if _, err = uc.UpdateAttractionByAdmin(ctx, attractionID, updateInput); err != nil {
		t.Fatalf("UpdateAttractionByAdmin() error = %v", err)
	}

	repo.listAttractions = []*model.Attraction{testCacheAttraction(attractionID, "After update")}
	list, _, err := uc.ListAttractions(ctx, ListAttractionsInput{CountryCode: "KZ", CityID: "almaty", Locale: "ru"})
	if err != nil {
		t.Fatalf("ListAttractions() after update error = %v", err)
	}
	if list[0].Attraction.Title != "After update" {
		t.Fatalf("list title after update = %q, want fresh repository value", list[0].Attraction.Title)
	}

	detail, err := uc.GetAttraction(ctx, attractionID, "ru")
	if err != nil {
		t.Fatalf("GetAttraction() after update error = %v", err)
	}
	if detail.Attraction.Title != "After update" {
		t.Fatalf("detail title after update = %q, want fresh repository value", detail.Attraction.Title)
	}

	if cache.bumpCalls == 0 {
		t.Fatal("cache version was not bumped after mutation")
	}
}

func testCacheAttraction(id uuid.UUID, title string) *model.Attraction {
	now := time.Now().UTC()
	return &model.Attraction{
		ID:            id,
		AuthorUserID:  uuid.New(),
		DefaultLocale: "en",
		Locale:        "en",
		Title:         title,
		Description:   "Description",
		CountryCode:   "KZ",
		CityID:        "almaty",
		Category:      enum.CategoryNature,
		Status:        enum.StatusPublished,
		Source:        enum.SourceImport,
		CreatedAt:     now,
		UpdatedAt:     now,
		Translations: map[string]model.AttractionTranslation{
			"en": {AttractionID: id, Locale: "en", Title: title, Description: "Description"},
		},
	}
}

type memoryAttractionCacheStub struct {
	attractions map[string]*model.Attraction
	lists       map[string]cachedAttractionListStub
	versions    map[string]int64
	bumpCalls   int
}

type cachedAttractionListStub struct {
	attractions []*model.Attraction
	total       int
}

func newMemoryAttractionCacheStub() *memoryAttractionCacheStub {
	return &memoryAttractionCacheStub{
		attractions: make(map[string]*model.Attraction),
		lists:       make(map[string]cachedAttractionListStub),
		versions:    make(map[string]int64),
	}
}

func (c *memoryAttractionCacheStub) GetAttraction(_ context.Context, key string) (*model.Attraction, bool, error) {
	item, ok := c.attractions[key]
	if !ok {
		return nil, false, nil
	}
	return cloneCacheAttraction(item), true, nil
}

func (c *memoryAttractionCacheStub) SetAttraction(_ context.Context, key string, attraction *model.Attraction, _ time.Duration) error {
	c.attractions[key] = cloneCacheAttraction(attraction)
	return nil
}

func (c *memoryAttractionCacheStub) GetAttractionList(_ context.Context, key string) ([]*model.Attraction, int, bool, error) {
	item, ok := c.lists[key]
	if !ok {
		return nil, 0, false, nil
	}
	return cloneCacheAttractions(item.attractions), item.total, true, nil
}

func (c *memoryAttractionCacheStub) SetAttractionList(_ context.Context, key string, attractions []*model.Attraction, total int, _ time.Duration) error {
	c.lists[key] = cachedAttractionListStub{
		attractions: cloneCacheAttractions(attractions),
		total:       total,
	}
	return nil
}

func (c *memoryAttractionCacheStub) CurrentVersion(_ context.Context, scope string) (int64, error) {
	version := c.versions[scope]
	return version, nil
}

func (c *memoryAttractionCacheStub) BumpVersion(_ context.Context, scopes ...string) error {
	c.bumpCalls++
	for _, scope := range scopes {
		c.versions[scope]++
	}
	return nil
}

type cacheAttractionRepoStub struct {
	attractionsByID map[uuid.UUID]*model.Attraction
	listAttractions []*model.Attraction
	listTotal       int
	lastListFilter  model.AttractionListFilter
	getCalls        int
	listCalls       int
}

func (r *cacheAttractionRepoStub) CreateAttraction(_ context.Context, attraction *model.Attraction) error {
	if r.attractionsByID == nil {
		r.attractionsByID = make(map[uuid.UUID]*model.Attraction)
	}
	r.attractionsByID[attraction.ID] = cloneCacheAttraction(attraction)
	return nil
}

func (r *cacheAttractionRepoStub) UpdateAttraction(_ context.Context, attraction *model.Attraction) error {
	if r.attractionsByID == nil {
		r.attractionsByID = make(map[uuid.UUID]*model.Attraction)
	}
	r.attractionsByID[attraction.ID] = cloneCacheAttraction(attraction)
	return nil
}

func (r *cacheAttractionRepoStub) SoftDeleteAttraction(_ context.Context, id uuid.UUID) error {
	if attraction := r.attractionsByID[id]; attraction != nil {
		now := time.Now().UTC()
		attraction.DeletedAt = &now
	}
	return nil
}

func (r *cacheAttractionRepoStub) RecoverAttraction(_ context.Context, id uuid.UUID) error {
	if attraction := r.attractionsByID[id]; attraction != nil {
		attraction.DeletedAt = nil
	}
	return nil
}

func (r *cacheAttractionRepoStub) GetAttractionByID(_ context.Context, id uuid.UUID, locale string) (*model.Attraction, error) {
	r.getCalls++
	attraction := r.attractionsByID[id]
	if attraction == nil {
		return nil, nil
	}
	copied := cloneCacheAttraction(attraction)
	copied.Locale = locale
	return copied, nil
}

func (r *cacheAttractionRepoStub) ListAttractions(_ context.Context, filter model.AttractionListFilter) ([]*model.Attraction, int, error) {
	r.listCalls++
	r.lastListFilter = filter
	return cloneCacheAttractions(r.listAttractions), r.listTotal, nil
}

func (r *cacheAttractionRepoStub) ReplaceAttractionMedia(_ context.Context, id uuid.UUID, media []model.AttractionMedia) error {
	if attraction := r.attractionsByID[id]; attraction != nil {
		attraction.Media = append([]model.AttractionMedia(nil), media...)
	}
	return nil
}

func (r *cacheAttractionRepoStub) ReplaceTags(context.Context, uuid.UUID, []string) error { return nil }
func (r *cacheAttractionRepoStub) CreateReview(context.Context, *model.AttractionReview) error {
	return nil
}
func (r *cacheAttractionRepoStub) SoftDeleteReview(context.Context, uuid.UUID, uuid.UUID) error {
	return nil
}
func (r *cacheAttractionRepoStub) GetReviewByID(context.Context, uuid.UUID) (*model.AttractionReview, error) {
	return nil, nil
}
func (r *cacheAttractionRepoStub) GetReviewByAttractionAndAuthor(context.Context, uuid.UUID, uuid.UUID) (*model.AttractionReview, error) {
	return nil, nil
}
func (r *cacheAttractionRepoStub) ListReviews(context.Context, uuid.UUID, int, int) ([]*model.AttractionReview, int, error) {
	return nil, 0, nil
}
func (r *cacheAttractionRepoStub) ReplaceReviewMedia(context.Context, uuid.UUID, []model.ReviewMedia) error {
	return nil
}
func (r *cacheAttractionRepoStub) RecalcRating(context.Context, uuid.UUID) (float64, int, error) {
	return 0, 0, nil
}
func (r *cacheAttractionRepoStub) ApplyRatingSourceSnapshot(context.Context, uuid.UUID, string, float64, int) (float64, int, error) {
	return 0, 0, nil
}

type cacheUserClientStub struct{}

func (c *cacheUserClientStub) ResolveUserIDBySubject(context.Context, string) (uuid.UUID, error) {
	return uuid.New(), nil
}

func (c *cacheUserClientStub) GetPublicUserProfiles(_ context.Context, userIDs []uuid.UUID) (map[uuid.UUID]PublicUserProfile, error) {
	profiles := make(map[uuid.UUID]PublicUserProfile, len(userIDs))
	for _, id := range userIDs {
		profiles[id] = PublicUserProfile{UserID: id}
	}
	return profiles, nil
}

func cloneCacheAttractions(items []*model.Attraction) []*model.Attraction {
	copied := make([]*model.Attraction, 0, len(items))
	for _, item := range items {
		copied = append(copied, cloneCacheAttraction(item))
	}
	return copied
}

func cloneCacheAttraction(item *model.Attraction) *model.Attraction {
	if item == nil {
		return nil
	}
	copied := *item
	copied.AccessCities = append([]model.AttractionCityLink(nil), item.AccessCities...)
	copied.DepartureCities = append([]model.AttractionCityLink(nil), item.DepartureCities...)
	copied.Tags = append([]string(nil), item.Tags...)
	copied.Media = append([]model.AttractionMedia(nil), item.Media...)
	if item.Translations != nil {
		copied.Translations = make(map[string]model.AttractionTranslation, len(item.Translations))
		for locale, translation := range item.Translations {
			copied.Translations[locale] = translation
		}
	}
	return &copied
}
