package app

import "testing"

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
