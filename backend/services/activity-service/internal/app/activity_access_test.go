package app

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

func TestGetActivityForViewerEnforcesPublicOwnerAndParticipantCapabilities(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name              string
		mutate            func(*model.Activity, uuid.UUID)
		participantStatus *enum.ParticipantStatus
		wantErr           error
		wantParticipant   bool
	}{
		{name: "public activity", mutate: func(*model.Activity, uuid.UUID) {}},
		{
			name: "private owner",
			mutate: func(item *model.Activity, actorID uuid.UUID) {
				item.Visibility = enum.ActivityVisibilityPrivate
				item.HostUserID = actorID
			},
		},
		{
			name: "private active participant",
			mutate: func(item *model.Activity, _ uuid.UUID) {
				item.Visibility = enum.ActivityVisibilityPrivate
			},
			participantStatus: participantStatusPtr(enum.ParticipantStatusConfirmed),
			wantParticipant:   true,
		},
		{
			name: "private unauthorized",
			mutate: func(item *model.Activity, _ uuid.UUID) {
				item.Visibility = enum.ActivityVisibilityPrivate
			},
			wantErr:         ErrActivityNotFound,
			wantParticipant: true,
		},
		{
			name: "unlisted unauthorized",
			mutate: func(item *model.Activity, _ uuid.UUID) {
				item.Visibility = enum.ActivityVisibilityUnlisted
			},
			wantErr:         ErrActivityNotFound,
			wantParticipant: true,
		},
		{
			name: "cancelled public unauthorized",
			mutate: func(item *model.Activity, _ uuid.UUID) {
				item.Status = enum.ActivityStatusCancelled
			},
			wantErr:         ErrActivityNotFound,
			wantParticipant: true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()

			actorID := uuid.New()
			item := savedSourceTestActivity()
			test.mutate(item, actorID)
			participantLookedUp := false
			repo := &activityRepoStub{
				getActivityByID: func(context.Context, uuid.UUID) (*model.Activity, error) {
					return item, nil
				},
				getParticipantByActivityAndUser: func(_ context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error) {
					participantLookedUp = true
					if test.participantStatus == nil {
						return nil, nil
					}
					return &model.ActivityParticipant{
						ActivityID: activityID,
						UserID:     userID,
						Status:     *test.participantStatus,
					}, nil
				},
			}

			got, err := NewActivityUseCase(repo).GetActivityForViewer(context.Background(), item.ID, actorID)
			if !errors.Is(err, test.wantErr) {
				t.Fatalf("GetActivityForViewer() error = %v, want %v", err, test.wantErr)
			}
			if test.wantErr == nil && got != item {
				t.Fatalf("GetActivityForViewer() = %p, want %p", got, item)
			}
			if participantLookedUp != test.wantParticipant {
				t.Fatalf("participant lookup = %v, want %v", participantLookedUp, test.wantParticipant)
			}
		})
	}
}

func participantStatusPtr(value enum.ParticipantStatus) *enum.ParticipantStatus {
	return &value
}
