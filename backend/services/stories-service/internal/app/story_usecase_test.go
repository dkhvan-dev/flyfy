package app

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/stories-service/internal/domain/port"
)

func TestSanitizeTagsReturnsEmptySliceForEmptyInput(t *testing.T) {
	tags, err := sanitizeTags(nil)
	if err != nil {
		t.Fatalf("sanitizeTags returned error: %v", err)
	}
	if tags == nil {
		t.Fatal("sanitizeTags returned nil slice for empty input")
	}
	if len(tags) != 0 {
		t.Fatalf("sanitizeTags returned %d tags, want 0", len(tags))
	}
}

func TestNormalizePlaceFiltersUsesCountryCodeWhenPlaceLooksLikeISOCode(t *testing.T) {
	query, countryCode := normalizePlaceFilters(" kz ")

	if query != "" {
		t.Fatalf("normalizePlaceFilters query = %q, want empty", query)
	}
	if countryCode != "KZ" {
		t.Fatalf("normalizePlaceFilters countryCode = %q, want KZ", countryCode)
	}
}

func TestNormalizePlaceFiltersKeepsLocalizedCountryNameAsTextQuery(t *testing.T) {
	query, countryCode := normalizePlaceFilters("Казахстан")

	if query != "Казахстан" {
		t.Fatalf("normalizePlaceFilters query = %q, want localized country name", query)
	}
	if countryCode != "" {
		t.Fatalf("normalizePlaceFilters countryCode = %q, want empty", countryCode)
	}
}

func TestNormalizeListInputMapsSelectedCountryToCountryCodeFilter(t *testing.T) {
	viewerID := uuid.New()
	filter, err := (&StoryUseCase{}).normalizeListInput(
		ListStoriesInput{Place: "KZ"},
		&viewerID,
	)
	if err != nil {
		t.Fatalf("normalizeListInput returned error: %v", err)
	}

	if filter.PlaceCountryCode != "KZ" {
		t.Fatalf("filter.PlaceCountryCode = %q, want KZ", filter.PlaceCountryCode)
	}
	if filter.PlaceQuery != "" {
		t.Fatalf("filter.PlaceQuery = %q, want empty", filter.PlaceQuery)
	}
}

func TestNormalizeListInputMapsSelectedCityToCityIDFilter(t *testing.T) {
	filter, err := (&StoryUseCase{}).normalizeListInput(
		ListStoriesInput{CountryCode: " kz ", CityID: " almaty "},
		nil,
	)
	if err != nil {
		t.Fatalf("normalizeListInput returned error: %v", err)
	}

	if filter.PlaceCountryCode != "KZ" {
		t.Fatalf("filter.PlaceCountryCode = %q, want KZ", filter.PlaceCountryCode)
	}
	if filter.PlaceCityID != "almaty" {
		t.Fatalf("filter.PlaceCityID = %q, want almaty", filter.PlaceCityID)
	}
}

func TestNormalizeListInputPreservesStorySortDirection(t *testing.T) {
	tests := map[string]string{
		"latest_asc":    "latest_asc",
		"latest_desc":   "latest_desc",
		"popular_asc":   "popular_asc",
		"popular_desc":  "popular_desc",
		"discussed_asc": "discussed_asc",
		"discussed":     "discussed_desc",
		"":              "latest_desc",
	}

	for input, expected := range tests {
		t.Run(input, func(t *testing.T) {
			filter, err := (&StoryUseCase{}).normalizeListInput(
				ListStoriesInput{Sort: input},
				nil,
			)
			if err != nil {
				t.Fatalf("normalizeListInput returned error: %v", err)
			}
			if filter.Sort != expected {
				t.Fatalf("filter.Sort = %q, want %q", filter.Sort, expected)
			}
		})
	}
}

func TestCountPublishedStoriesByAuthorIDUsesRepository(t *testing.T) {
	authorID := uuid.New()
	repo := &countingStoryRepository{count: 7}
	useCase := NewStoryUseCase(repo, nil, "")

	count, err := useCase.CountPublishedStoriesByAuthorID(context.Background(), authorID)
	if err != nil {
		t.Fatalf("CountPublishedStoriesByAuthorID returned error: %v", err)
	}

	if count != 7 {
		t.Fatalf("count = %d, want 7", count)
	}
	if repo.authorID != authorID {
		t.Fatalf("authorID = %s, want %s", repo.authorID, authorID)
	}
}

type countingStoryRepository struct {
	port.StoryRepository
	count    int
	authorID uuid.UUID
}

func (r *countingStoryRepository) CountPublishedStoriesByAuthorID(
	_ context.Context,
	authorID uuid.UUID,
) (int, error) {
	r.authorID = authorID
	return r.count, nil
}
