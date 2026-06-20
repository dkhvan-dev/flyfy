package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestListPlacesUsesReadThroughCache(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	repo := &cachePlaceRepoStub{
		listPlaces: []*model.Place{testCachePlace(placeID, "First title")},
		listTotal:  1,
	}
	cache := newMemoryPlaceCacheStub()
	uc := NewPlaceUseCase(
		repo,
		&cacheUserClientStub{},
		WithPlaceCache(cache, time.Minute, time.Minute),
	)

	ctx := context.Background()
	input := ListPlacesInput{CountryCode: "KZ", CityID: "almaty", Locale: "ru", Limit: 20}

	first, firstTotal, err := uc.ListPlaces(ctx, input)
	if err != nil {
		t.Fatalf("first ListPlaces() error = %v", err)
	}
	if firstTotal != 1 || len(first) != 1 || first[0].Place.Title != "First title" {
		t.Fatalf("first list = total %d items %#v, want cached source title", firstTotal, first)
	}

	repo.listPlaces = []*model.Place{testCachePlace(placeID, "Stale repository title")}
	second, secondTotal, err := uc.ListPlaces(ctx, input)
	if err != nil {
		t.Fatalf("second ListPlaces() error = %v", err)
	}
	if repo.listCalls != 1 {
		t.Fatalf("repository list calls = %d, want 1", repo.listCalls)
	}
	if secondTotal != 1 || len(second) != 1 || second[0].Place.Title != "First title" {
		t.Fatalf("second list = total %d items %#v, want cached first response", secondTotal, second)
	}
}

func TestListPlacesTreatsBaliCityAliasAsIndonesiaRegion(t *testing.T) {
	t.Parallel()

	repo := &cachePlaceRepoStub{
		listPlaces: []*model.Place{testCachePlace(uuid.New(), "Bali place")},
		listTotal:  1,
	}
	uc := NewPlaceUseCase(repo, &cacheUserClientStub{})

	_, _, err := uc.ListPlaces(context.Background(), ListPlacesInput{
		CountryCode: "ID",
		CityID:      "bali",
		Locale:      "ru",
	})
	if err != nil {
		t.Fatalf("ListPlaces() error = %v", err)
	}

	if repo.lastListFilter.CountryCode != "ID" || repo.lastListFilter.CityID != "" || repo.lastListFilter.RegionID != "bali" {
		t.Fatalf("repository filter = %#v, want country ID, empty city and Bali region", repo.lastListFilter)
	}
}

func TestListPlacesTreatsHainanCityAliasAsChinaRegion(t *testing.T) {
	t.Parallel()

	repo := &cachePlaceRepoStub{
		listPlaces: []*model.Place{testCachePlace(uuid.New(), "Hainan place")},
		listTotal:  1,
	}
	uc := NewPlaceUseCase(repo, &cacheUserClientStub{})

	_, _, err := uc.ListPlaces(context.Background(), ListPlacesInput{
		CountryCode: "CN",
		CityID:      "hainan",
		Locale:      "ru",
	})
	if err != nil {
		t.Fatalf("ListPlaces() error = %v", err)
	}

	if repo.lastListFilter.CountryCode != "CN" || repo.lastListFilter.CityID != "" || repo.lastListFilter.RegionID != "hainan" {
		t.Fatalf("repository filter = %#v, want country CN, empty city and Hainan region", repo.lastListFilter)
	}
}

func TestGetPlaceUsesReadThroughCache(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	repo := &cachePlaceRepoStub{
		placesByID: map[uuid.UUID]*model.Place{
			placeID: testCachePlace(placeID, "Medeu"),
		},
	}
	cache := newMemoryPlaceCacheStub()
	uc := NewPlaceUseCase(
		repo,
		&cacheUserClientStub{},
		WithPlaceCache(cache, time.Minute, time.Minute),
	)

	ctx := context.Background()
	first, err := uc.GetPlace(ctx, placeID, "ru")
	if err != nil {
		t.Fatalf("first GetPlace() error = %v", err)
	}
	if first.Place.Title != "Medeu" {
		t.Fatalf("first title = %q, want Medeu", first.Place.Title)
	}

	repo.placesByID[placeID] = testCachePlace(placeID, "Repository changed")
	second, err := uc.GetPlace(ctx, placeID, "ru")
	if err != nil {
		t.Fatalf("second GetPlace() error = %v", err)
	}
	if repo.getCalls != 1 {
		t.Fatalf("repository get calls = %d, want 1", repo.getCalls)
	}
	if second.Place.Title != "Medeu" {
		t.Fatalf("second title = %q, want cached Medeu", second.Place.Title)
	}
}

func TestPlaceMutationsInvalidateCachedReads(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	repo := &cachePlaceRepoStub{
		placesByID: map[uuid.UUID]*model.Place{
			placeID: testCachePlace(placeID, "Before update"),
		},
		listPlaces: []*model.Place{testCachePlace(placeID, "Before update")},
		listTotal:  1,
	}
	cache := newMemoryPlaceCacheStub()
	uc := NewPlaceUseCase(
		repo,
		&cacheUserClientStub{},
		WithPlaceCache(cache, time.Minute, time.Minute),
	)

	ctx := context.Background()
	_, _, err := uc.ListPlaces(ctx, ListPlacesInput{CountryCode: "KZ", CityID: "almaty", Locale: "ru"})
	if err != nil {
		t.Fatalf("ListPlaces() warmup error = %v", err)
	}
	_, err = uc.GetPlace(ctx, placeID, "ru")
	if err != nil {
		t.Fatalf("GetPlace() warmup error = %v", err)
	}

	updateInput := UpdatePlaceInput{
		Title:         "After update",
		Description:   "Updated description",
		DefaultLocale: "en",
		Translations: map[string]PlaceTranslationInput{
			"en": {Title: "After update", Description: "Updated description"},
		},
		CountryCode: "KZ",
		CityID:      "almaty",
		Category:    "NATURE",
		Status:      "PUBLISHED",
	}
	if _, err = uc.UpdatePlaceByAdmin(ctx, placeID, updateInput); err != nil {
		t.Fatalf("UpdatePlaceByAdmin() error = %v", err)
	}

	repo.listPlaces = []*model.Place{testCachePlace(placeID, "After update")}
	list, _, err := uc.ListPlaces(ctx, ListPlacesInput{CountryCode: "KZ", CityID: "almaty", Locale: "ru"})
	if err != nil {
		t.Fatalf("ListPlaces() after update error = %v", err)
	}
	if list[0].Place.Title != "After update" {
		t.Fatalf("list title after update = %q, want fresh repository value", list[0].Place.Title)
	}

	detail, err := uc.GetPlace(ctx, placeID, "ru")
	if err != nil {
		t.Fatalf("GetPlace() after update error = %v", err)
	}
	if detail.Place.Title != "After update" {
		t.Fatalf("detail title after update = %q, want fresh repository value", detail.Place.Title)
	}

	if cache.bumpCalls == 0 {
		t.Fatal("cache version was not bumped after mutation")
	}
}

func testCachePlace(id uuid.UUID, title string) *model.Place {
	now := time.Now().UTC()
	return &model.Place{
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
		Translations: map[string]model.PlaceTranslation{
			"en": {PlaceID: id, Locale: "en", Title: title, Description: "Description"},
		},
	}
}

type memoryPlaceCacheStub struct {
	places    map[string]*model.Place
	lists     map[string]cachedPlaceListStub
	versions  map[string]int64
	bumpCalls int
}

type cachedPlaceListStub struct {
	places []*model.Place
	total  int
}

func newMemoryPlaceCacheStub() *memoryPlaceCacheStub {
	return &memoryPlaceCacheStub{
		places:   make(map[string]*model.Place),
		lists:    make(map[string]cachedPlaceListStub),
		versions: make(map[string]int64),
	}
}

func (c *memoryPlaceCacheStub) GetPlace(_ context.Context, key string) (*model.Place, bool, error) {
	item, ok := c.places[key]
	if !ok {
		return nil, false, nil
	}
	return cloneCachePlace(item), true, nil
}

func (c *memoryPlaceCacheStub) SetPlace(_ context.Context, key string, place *model.Place, _ time.Duration) error {
	c.places[key] = cloneCachePlace(place)
	return nil
}

func (c *memoryPlaceCacheStub) GetPlaceList(_ context.Context, key string) ([]*model.Place, int, bool, error) {
	item, ok := c.lists[key]
	if !ok {
		return nil, 0, false, nil
	}
	return cloneCachePlaces(item.places), item.total, true, nil
}

func (c *memoryPlaceCacheStub) SetPlaceList(_ context.Context, key string, places []*model.Place, total int, _ time.Duration) error {
	c.lists[key] = cachedPlaceListStub{
		places: cloneCachePlaces(places),
		total:  total,
	}
	return nil
}

func (c *memoryPlaceCacheStub) CurrentVersion(_ context.Context, scope string) (int64, error) {
	version := c.versions[scope]
	return version, nil
}

func (c *memoryPlaceCacheStub) BumpVersion(_ context.Context, scopes ...string) error {
	c.bumpCalls++
	for _, scope := range scopes {
		c.versions[scope]++
	}
	return nil
}

type cachePlaceRepoStub struct {
	placesByID     map[uuid.UUID]*model.Place
	listPlaces     []*model.Place
	listTotal      int
	lastListFilter model.PlaceListFilter
	getCalls       int
	listCalls      int
}

func (r *cachePlaceRepoStub) CreatePlace(_ context.Context, place *model.Place) error {
	if r.placesByID == nil {
		r.placesByID = make(map[uuid.UUID]*model.Place)
	}
	r.placesByID[place.ID] = cloneCachePlace(place)
	return nil
}

func (r *cachePlaceRepoStub) UpdatePlace(_ context.Context, place *model.Place) error {
	if r.placesByID == nil {
		r.placesByID = make(map[uuid.UUID]*model.Place)
	}
	r.placesByID[place.ID] = cloneCachePlace(place)
	return nil
}

func (r *cachePlaceRepoStub) SoftDeletePlace(_ context.Context, id uuid.UUID) error {
	if place := r.placesByID[id]; place != nil {
		now := time.Now().UTC()
		place.DeletedAt = &now
	}
	return nil
}

func (r *cachePlaceRepoStub) RecoverPlace(_ context.Context, id uuid.UUID) error {
	if place := r.placesByID[id]; place != nil {
		place.DeletedAt = nil
	}
	return nil
}

func (r *cachePlaceRepoStub) GetPlaceByID(_ context.Context, id uuid.UUID, locale string) (*model.Place, error) {
	r.getCalls++
	place := r.placesByID[id]
	if place == nil {
		return nil, nil
	}
	copied := cloneCachePlace(place)
	copied.Locale = locale
	return copied, nil
}

func (r *cachePlaceRepoStub) ListPlaces(_ context.Context, filter model.PlaceListFilter) ([]*model.Place, int, error) {
	r.listCalls++
	r.lastListFilter = filter
	return cloneCachePlaces(r.listPlaces), r.listTotal, nil
}

func (r *cachePlaceRepoStub) ReplacePlaceMedia(_ context.Context, id uuid.UUID, media []model.PlaceMedia) error {
	if place := r.placesByID[id]; place != nil {
		place.Media = append([]model.PlaceMedia(nil), media...)
	}
	return nil
}

func (r *cachePlaceRepoStub) ReplaceTags(context.Context, uuid.UUID, []string) error { return nil }
func (r *cachePlaceRepoStub) CreateReview(context.Context, *model.PlaceReview) error {
	return nil
}
func (r *cachePlaceRepoStub) SoftDeleteReview(context.Context, uuid.UUID, uuid.UUID) error {
	return nil
}
func (r *cachePlaceRepoStub) GetReviewByID(context.Context, uuid.UUID) (*model.PlaceReview, error) {
	return nil, nil
}
func (r *cachePlaceRepoStub) GetReviewByPlaceAndAuthor(context.Context, uuid.UUID, uuid.UUID) (*model.PlaceReview, error) {
	return nil, nil
}
func (r *cachePlaceRepoStub) ListReviews(context.Context, uuid.UUID, int, int) ([]*model.PlaceReview, int, error) {
	return nil, 0, nil
}
func (r *cachePlaceRepoStub) ReplaceReviewMedia(context.Context, uuid.UUID, []model.ReviewMedia) error {
	return nil
}
func (r *cachePlaceRepoStub) RecalcRating(context.Context, uuid.UUID) (float64, int, error) {
	return 0, 0, nil
}
func (r *cachePlaceRepoStub) ApplyRatingSourceSnapshot(context.Context, uuid.UUID, string, float64, int) (float64, int, error) {
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

func cloneCachePlaces(items []*model.Place) []*model.Place {
	copied := make([]*model.Place, 0, len(items))
	for _, item := range items {
		copied = append(copied, cloneCachePlace(item))
	}
	return copied
}

func cloneCachePlace(item *model.Place) *model.Place {
	if item == nil {
		return nil
	}
	copied := *item
	copied.AccessCities = append([]model.PlaceCityLink(nil), item.AccessCities...)
	copied.DepartureCities = append([]model.PlaceCityLink(nil), item.DepartureCities...)
	copied.Tags = append([]string(nil), item.Tags...)
	copied.Media = append([]model.PlaceMedia(nil), item.Media...)
	if item.Translations != nil {
		copied.Translations = make(map[string]model.PlaceTranslation, len(item.Translations))
		for locale, translation := range item.Translations {
			copied.Translations[locale] = translation
		}
	}
	return &copied
}
