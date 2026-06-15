package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

func TestCreateActivityFromPostReturnsExistingCompletedActivity(t *testing.T) {
	activityID := uuid.New()
	existing := validIdempotentActivity(t, activityID, uuid.New())
	repo := &activityRepoStub{
		acquireActivityIdempotencyKey: func(ctx context.Context, item *model.ActivityIdempotencyKey) (*model.ActivityIdempotencyKey, bool, error) {
			return &model.ActivityIdempotencyKey{
				Key:         item.Key,
				RequestHash: item.RequestHash,
				Status:      model.ActivityIdempotencyStatusCompleted,
				ActivityID:  &activityID,
			}, false, nil
		},
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() id = %s, want %s", requestedID, activityID)
			}
			return existing, nil
		},
		createActivity: func(ctx context.Context, item *model.Activity) error {
			t.Fatal("CreateActivity() should not be called for completed idempotency key")
			return nil
		},
	}
	uc := NewActivityUseCase(repo, nil)

	got, err := uc.CreateActivityFromPost(context.Background(), CreateActivityFromPostInput{
		IdempotencyKey: "post:123:activity:v1",
		SourceService:  "feed-service",
		SourcePostID:   "123",
		Input:          validCreateActivityInput(),
	})
	if err != nil {
		t.Fatalf("CreateActivityFromPost() error = %v", err)
	}
	if got.ID != activityID {
		t.Fatalf("CreateActivityFromPost() id = %s, want %s", got.ID, activityID)
	}
}

func TestCreateActivityFromPostCompletesIdempotencyKeyAfterCreate(t *testing.T) {
	var createCount int
	var completedActivityID uuid.UUID
	repo := &activityRepoStub{
		acquireActivityIdempotencyKey: func(ctx context.Context, item *model.ActivityIdempotencyKey) (*model.ActivityIdempotencyKey, bool, error) {
			if item.Key != "post:456:activity:v1" {
				t.Fatalf("idempotency key = %q, want post:456:activity:v1", item.Key)
			}
			if item.SourceService != "feed-service" || item.SourceResourceID != "456" {
				t.Fatalf("source = %q/%q, want feed-service/456", item.SourceService, item.SourceResourceID)
			}
			if item.RequestHash == "" {
				t.Fatal("request hash is empty")
			}
			return item, true, nil
		},
		createActivity: func(ctx context.Context, item *model.Activity) error {
			createCount++
			completedActivityID = item.ID
			return nil
		},
		completeActivityIdempotencyKey: func(ctx context.Context, key string, activityID uuid.UUID) error {
			if key != "post:456:activity:v1" {
				t.Fatalf("complete key = %q, want post:456:activity:v1", key)
			}
			if activityID != completedActivityID {
				t.Fatalf("complete activity id = %s, want %s", activityID, completedActivityID)
			}
			return nil
		},
	}
	uc := NewActivityUseCase(repo, nil)

	got, err := uc.CreateActivityFromPost(context.Background(), CreateActivityFromPostInput{
		IdempotencyKey: "post:456:activity:v1",
		SourceService:  "feed-service",
		SourcePostID:   "456",
		Input:          validCreateActivityInput(),
	})
	if err != nil {
		t.Fatalf("CreateActivityFromPost() error = %v", err)
	}
	if got == nil || got.ID == uuid.Nil {
		t.Fatal("CreateActivityFromPost() returned nil activity")
	}
	if createCount != 1 {
		t.Fatalf("CreateActivity() calls = %d, want 1", createCount)
	}
}

func validIdempotentActivity(t *testing.T, activityID uuid.UUID, hostUserID uuid.UUID) *model.Activity {
	t.Helper()
	startAt := time.Now().UTC().Add(24 * time.Hour)
	item, err := model.NewActivity(model.NewActivityParams{
		HostUserID:                     hostUserID,
		Title:                          "City walk",
		Description:                    "A relaxed city walk",
		Format:                         "OFFLINE",
		Visibility:                     "PUBLIC",
		CategorySlug:                   "city-walks",
		LanguageCode:                   "en",
		Timezone:                       "UTC",
		StartAt:                        startAt,
		EndAt:                          startAt.Add(2 * time.Hour),
		RegistrationDeadline:           startAt.Add(-time.Hour),
		CapacityType:                   "UNLIMITED",
		PriceType:                      "FREE",
		RequiresProfileCompletion:      true,
		RequiresAttendanceConfirmation: false,
		AllowsParticipantInvites:       true,
		AddressText:                    stringPtrForActivityTest("Central square"),
	})
	if err != nil {
		t.Fatalf("build valid activity: %v", err)
	}
	item.ID = activityID
	return item
}

func stringPtrForActivityTest(value string) *string {
	return &value
}
