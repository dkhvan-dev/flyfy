package model

import "testing"

func TestNormalizeAndValidateActivityCategorySlug(t *testing.T) {
	t.Parallel()

	slug, err := NormalizeAndValidateActivityCategorySlug("  Nature-Outdoor ")
	if err != nil {
		t.Fatalf("NormalizeAndValidateActivityCategorySlug() error = %v", err)
	}

	if slug != "nature-outdoor" {
		t.Fatalf("NormalizeAndValidateActivityCategorySlug() = %q, want %q", slug, "nature-outdoor")
	}
}

func TestNormalizeAndValidateActivityCategorySlugMapsLegacySlugs(t *testing.T) {
	t.Parallel()

	tests := map[string]string{
		"health-wellness":  "sports-wellness",
		"adventure-sports": "nature-outdoor",
		"social-nightlife": "social-nightlife",
	}

	for raw, want := range tests {
		raw, want := raw, want
		t.Run(raw, func(t *testing.T) {
			t.Parallel()

			got, err := NormalizeAndValidateActivityCategorySlug(raw)
			if err != nil {
				t.Fatalf("NormalizeAndValidateActivityCategorySlug(%q) error = %v", raw, err)
			}
			if got != want {
				t.Fatalf("NormalizeAndValidateActivityCategorySlug(%q) = %q, want %q", raw, got, want)
			}
		})
	}
}

func TestNormalizeAndValidateActivityCategorySlugRejectsUnknownSlug(t *testing.T) {
	t.Parallel()

	if _, err := NormalizeAndValidateActivityCategorySlug("football"); err != ErrInvalidCategorySlug {
		t.Fatalf("NormalizeAndValidateActivityCategorySlug() error = %v, want %v", err, ErrInvalidCategorySlug)
	}
}

func TestListActivityCategoriesReturnsCopy(t *testing.T) {
	t.Parallel()

	items := ListActivityCategories()
	if len(items) != 10 {
		t.Fatalf("ListActivityCategories() len = %d, want 10", len(items))
	}

	items[0].Slug = "mutated"
	items[0].Subcategories[0].Slug = "mutated-subcategory"
	items[0].SystemTags[0].Slug = "mutated-tag"

	fresh := ListActivityCategories()
	if fresh[0].Slug == "mutated" {
		t.Fatal("ListActivityCategories() returned shared slice")
	}
	if fresh[0].Subcategories[0].Slug == "mutated-subcategory" {
		t.Fatal("ListActivityCategories() returned shared subcategory slice")
	}
	if fresh[0].SystemTags[0].Slug == "mutated-tag" {
		t.Fatal("ListActivityCategories() returned shared tag slice")
	}
}

func TestListActivityCategoriesReturnsLocalizedTaxonomy(t *testing.T) {
	t.Parallel()

	items := ListActivityCategories()
	seen := map[string]ActivityCategory{}
	for _, item := range items {
		seen[item.Slug] = item
		if item.Name == "" || item.NameRu == "" || item.NameKk == "" {
			t.Fatalf("category %q is missing localized names", item.Slug)
		}
		if len(item.Subcategories) == 0 {
			t.Fatalf("category %q has no subcategories", item.Slug)
		}
		if len(item.SystemTags) == 0 {
			t.Fatalf("category %q has no system tags", item.Slug)
		}
	}

	if seen["food-drinks"].Subcategories[0].Slug != "coffee-meetup" {
		t.Fatalf("food-drinks first subcategory = %q, want coffee-meetup", seen["food-drinks"].Subcategories[0].Slug)
	}
	if seen["social-nightlife"].SystemTags[0].Slug != "solo-friendly" {
		t.Fatalf("social-nightlife first tag = %q, want solo-friendly", seen["social-nightlife"].SystemTags[0].Slug)
	}
}

func TestNormalizeAndValidateActivitySubCategorySlug(t *testing.T) {
	t.Parallel()

	slug, err := NormalizeAndValidateActivitySubCategorySlug("food-drinks", " Coffee-Meetup ")
	if err != nil {
		t.Fatalf("NormalizeAndValidateActivitySubCategorySlug() error = %v", err)
	}
	if slug != "coffee-meetup" {
		t.Fatalf("NormalizeAndValidateActivitySubCategorySlug() = %q, want coffee-meetup", slug)
	}

	if _, err := NormalizeAndValidateActivitySubCategorySlug("food-drinks", "karaoke"); err != ErrInvalidActivitySubcategorySlug {
		t.Fatalf("NormalizeAndValidateActivitySubCategorySlug() error = %v, want %v", err, ErrInvalidActivitySubcategorySlug)
	}
}

func TestNormalizeActivityTagSlug(t *testing.T) {
	t.Parallel()

	if got := NormalizeActivityTagSlug(" Solo Friendly "); got != "solo-friendly" {
		t.Fatalf("NormalizeActivityTagSlug() = %q, want solo-friendly", got)
	}
}
