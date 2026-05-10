package repository

import "testing"

func TestAttractionListOrderBySupportsSortDirections(t *testing.T) {
	tests := map[string]string{
		"rating":        "a.rating DESC, a.review_count DESC, a.created_at DESC",
		"rating_desc":   "a.rating DESC, a.review_count DESC, a.created_at DESC",
		"rating_asc":    "a.rating ASC, a.review_count DESC, a.created_at DESC",
		"price_asc":     "a.price_amount ASC NULLS LAST, a.created_at DESC",
		"price_desc":    "a.price_amount DESC NULLS LAST, a.created_at DESC",
		"duration_asc":  "CASE WHEN a.duration_unit = 'DAYS' THEN a.duration_value * 24 ELSE a.duration_value END ASC NULLS LAST, a.created_at DESC",
		"duration_desc": "CASE WHEN a.duration_unit = 'DAYS' THEN a.duration_value * 24 ELSE a.duration_value END DESC NULLS LAST, a.created_at DESC",
		"unknown":       "a.created_at DESC",
	}

	for sort, expected := range tests {
		t.Run(sort, func(t *testing.T) {
			if got := attractionListOrderBy(sort); got != expected {
				t.Fatalf("order by mismatch\nexpected: %s\nactual:   %s", expected, got)
			}
		})
	}
}
