package repository

import "testing"

func TestStoryListOrderBySupportsSortDirections(t *testing.T) {
	tests := map[string]string{
		"latest":         "published_at DESC NULLS LAST, created_at DESC",
		"latest_desc":    "published_at DESC NULLS LAST, created_at DESC",
		"latest_asc":     "published_at ASC NULLS LAST, created_at ASC",
		"popular":        "view_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"popular_desc":   "view_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"popular_asc":    "view_count ASC, published_at ASC NULLS LAST, created_at ASC",
		"discussed":      "comment_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"discussed_desc": "comment_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"discussed_asc":  "comment_count ASC, published_at ASC NULLS LAST, created_at ASC",
		"unknown":        "published_at DESC NULLS LAST, created_at DESC",
	}

	for sort, expected := range tests {
		t.Run(sort, func(t *testing.T) {
			if got := storyListOrderBy(sort); got != expected {
				t.Fatalf("order by mismatch\nexpected: %s\nactual:   %s", expected, got)
			}
		})
	}
}
