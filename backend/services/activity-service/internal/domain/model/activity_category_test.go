package model

import "testing"

func TestNormalizeAndValidateActivityCategorySlug(t *testing.T) {
	t.Parallel()

	slug, err := NormalizeAndValidateActivityCategorySlug("  Adventure-Sports ")
	if err != nil {
		t.Fatalf("NormalizeAndValidateActivityCategorySlug() error = %v", err)
	}

	if slug != "adventure-sports" {
		t.Fatalf("NormalizeAndValidateActivityCategorySlug() = %q, want %q", slug, "adventure-sports")
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
	if len(items) != 4 {
		t.Fatalf("ListActivityCategories() len = %d, want 4", len(items))
	}

	items[0].Slug = "mutated"

	fresh := ListActivityCategories()
	if fresh[0].Slug == "mutated" {
		t.Fatal("ListActivityCategories() returned shared slice")
	}
}
