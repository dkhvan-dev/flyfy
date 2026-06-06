package model

import (
	"errors"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
)

func TestNewActivityReviewAllowsRatingOnlyReview(t *testing.T) {
	activityID := uuid.New()
	participant := validReviewParticipant(t, activityID, uuid.New(), enum.ParticipantStatusCheckedIn)
	activity := validReviewActivity(activityID, uuid.New())

	review, err := NewActivityReview(NewActivityReviewParams{
		Activity:    activity,
		Participant: participant,
		Rating:      4.5,
		Comment:     "   ",
	})

	if err != nil {
		t.Fatalf("NewActivityReview() error = %v", err)
	}
	if review.Comment != "" {
		t.Fatalf("Comment = %q, want empty trimmed comment", review.Comment)
	}
	if review.ActivityID != activityID {
		t.Fatalf("ActivityID = %s, want %s", review.ActivityID, activityID)
	}
	if review.AuthorUserID != participant.UserID {
		t.Fatalf("AuthorUserID = %s, want %s", review.AuthorUserID, participant.UserID)
	}
}

func TestNewActivityReviewRejectsInvalidRatingAndLongComment(t *testing.T) {
	activityID := uuid.New()
	participant := validReviewParticipant(t, activityID, uuid.New(), enum.ParticipantStatusCheckedIn)
	activity := validReviewActivity(activityID, uuid.New())

	_, err := NewActivityReview(NewActivityReviewParams{
		Activity:    activity,
		Participant: participant,
		Rating:      0.5,
		Comment:     "",
	})
	if !errors.Is(err, ErrInvalidActivityReviewRating) {
		t.Fatalf("NewActivityReview() error = %v, want %v", err, ErrInvalidActivityReviewRating)
	}

	_, err = NewActivityReview(NewActivityReviewParams{
		Activity:    activity,
		Participant: participant,
		Rating:      5,
		Comment:     strings.Repeat("ы", maxActivityReviewCommentLength+1),
	})
	if !errors.Is(err, ErrInvalidActivityReviewComment) {
		t.Fatalf("NewActivityReview() error = %v, want %v", err, ErrInvalidActivityReviewComment)
	}
}

func TestActivityOrganizerReviewRejectsSelfReview(t *testing.T) {
	hostUserID := uuid.New()
	activityID := uuid.New()
	participant := validReviewParticipant(t, activityID, hostUserID, enum.ParticipantStatusCheckedIn)
	activity := validReviewActivity(activityID, hostUserID)

	_, err := NewActivityOrganizerReview(NewActivityOrganizerReviewParams{
		Activity:    activity,
		Participant: participant,
		Rating:      5,
		Comment:     "great hosting",
	})

	if !errors.Is(err, ErrActivityOrganizerReviewSelfReview) {
		t.Fatalf("NewActivityOrganizerReview() error = %v, want %v", err, ErrActivityOrganizerReviewSelfReview)
	}
}

func TestActivityReviewUpdateAndSoftDelete(t *testing.T) {
	activityID := uuid.New()
	participant := validReviewParticipant(t, activityID, uuid.New(), enum.ParticipantStatusCheckedIn)
	activity := validReviewActivity(activityID, uuid.New())
	review, err := NewActivityReview(NewActivityReviewParams{
		Activity:    activity,
		Participant: participant,
		Rating:      3,
		Comment:     "ok",
	})
	if err != nil {
		t.Fatalf("NewActivityReview() error = %v", err)
	}

	if err = review.Update(5, "  excellent  "); err != nil {
		t.Fatalf("Update() error = %v", err)
	}
	if review.Rating != 5 || review.Comment != "excellent" {
		t.Fatalf("updated review = rating %.1f comment %q", review.Rating, review.Comment)
	}

	review.SoftDelete()
	if review.DeletedAt == nil {
		t.Fatal("DeletedAt is nil after SoftDelete()")
	}
}

func validReviewActivity(activityID uuid.UUID, hostUserID uuid.UUID) *Activity {
	return &Activity{
		ID:         activityID,
		HostUserID: hostUserID,
		Status:     enum.ActivityStatusCompleted,
	}
}

func validReviewParticipant(
	t *testing.T,
	activityID uuid.UUID,
	userID uuid.UUID,
	status enum.ParticipantStatus,
) *ActivityParticipant {
	t.Helper()

	participant, err := NewActivityParticipant(NewActivityParticipantParams{
		ActivityID: activityID,
		UserID:     userID,
		Status:     status,
	})
	if err != nil {
		t.Fatalf("NewActivityParticipant() error = %v", err)
	}
	return participant
}
