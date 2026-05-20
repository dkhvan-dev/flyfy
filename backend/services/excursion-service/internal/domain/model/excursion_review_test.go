package model

import (
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestExcursionAndGuideReviewsAllowEmptyComments(t *testing.T) {
	booking, err := NewExcursionBooking(NewExcursionBookingParams{
		ProductID:       uuid.New(),
		OfferID:         uuid.New(),
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		TouristUserID:   uuid.New(),
		ScheduledFor:    time.Now().UTC().Add(-24 * time.Hour),
		Adults:          1,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}

	excursionReview, err := NewExcursionReview(NewExcursionReviewParams{
		Booking: booking,
		Rating:  5,
		Comment: "   ",
	})
	if err != nil {
		t.Fatalf("NewExcursionReview() with empty comment error = %v", err)
	}
	if excursionReview.Comment != "" {
		t.Fatalf("excursion review comment = %q, want empty", excursionReview.Comment)
	}

	guideReview, err := NewGuideReview(NewGuideReviewParams{
		Booking: booking,
		Rating:  4,
		Comment: "",
	})
	if err != nil {
		t.Fatalf("NewGuideReview() with empty comment error = %v", err)
	}
	if guideReview.Comment != "" {
		t.Fatalf("guide review comment = %q, want empty", guideReview.Comment)
	}
}

func TestExcursionAndGuideReviewsRejectOverlongComments(t *testing.T) {
	booking, err := NewExcursionBooking(NewExcursionBookingParams{
		ProductID:       uuid.New(),
		OfferID:         uuid.New(),
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		TouristUserID:   uuid.New(),
		ScheduledFor:    time.Now().UTC().Add(-24 * time.Hour),
		Adults:          1,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	overlong := strings.Repeat("a", maxExcursionReviewCommentLength+1)

	if _, err = NewExcursionReview(NewExcursionReviewParams{
		Booking: booking,
		Rating:  5,
		Comment: overlong,
	}); err != ErrInvalidExcursionReviewComment {
		t.Fatalf("NewExcursionReview() error = %v, want ErrInvalidExcursionReviewComment", err)
	}
	if _, err = NewGuideReview(NewGuideReviewParams{
		Booking: booking,
		Rating:  5,
		Comment: overlong,
	}); err != ErrInvalidExcursionReviewComment {
		t.Fatalf("NewGuideReview() error = %v, want ErrInvalidExcursionReviewComment", err)
	}
}
