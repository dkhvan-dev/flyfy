package repository

import (
	"math"
	"testing"
)

func TestActivityOrganizerRatingWithDefault(t *testing.T) {
	tests := []struct {
		name          string
		defaultRating float64
		reviewSum     float64
		reviewCount   int
		want          float64
	}{
		{
			name:          "returns default rating without reviews",
			defaultRating: 5,
			reviewSum:     0,
			reviewCount:   0,
			want:          5,
		},
		{
			name:          "keeps default rating as baseline after first review",
			defaultRating: 5,
			reviewSum:     3,
			reviewCount:   1,
			want:          4,
		},
		{
			name:          "includes default rating with multiple reviews",
			defaultRating: 5,
			reviewSum:     8,
			reviewCount:   2,
			want:          13.0 / 3.0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := activityOrganizerRatingWithDefault(
				tt.defaultRating,
				tt.reviewSum,
				tt.reviewCount,
			)
			if math.Abs(got-tt.want) > 0.000001 {
				t.Fatalf("activityOrganizerRatingWithDefault() = %f, want %f", got, tt.want)
			}
		})
	}
}
