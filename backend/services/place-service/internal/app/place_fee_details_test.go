package app

import (
	"testing"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestNormalizeVisitInfoPreservesExistingFeeDetailsWhenInputOmitsThem(t *testing.T) {
	t.Parallel()

	amount := 1297.5
	existing := &model.PlaceVisitInfo{
		FeeDetails: []model.PlaceFeeDetail{
			{
				Title: map[string]string{
					"en": "Car access",
					"ru": "Въезд на авто",
				},
				Amount:        &amount,
				Currency:      "KZT",
				Unit:          "CAR",
				IsApproximate: true,
				SortOrder:     20,
			},
		},
	}

	normalized, err := normalizeVisitInfo(&PlaceVisitInfoInput{
		BestTime: "morning",
	}, existing)
	if err != nil {
		t.Fatalf("normalizeVisitInfo() error = %v", err)
	}

	if len(normalized.FeeDetails) != 1 {
		t.Fatalf("fee details length = %d, want 1", len(normalized.FeeDetails))
	}
	if normalized.FeeDetails[0].Title["ru"] != "Въезд на авто" {
		t.Fatalf("preserved fee title = %q", normalized.FeeDetails[0].Title["ru"])
	}
}
