package app

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

type notificationGatewayStub struct {
	send func(ctx context.Context, input port.ActivityNotificationInput) error
}

func (s notificationGatewayStub) SendActivityNotification(
	ctx context.Context,
	input port.ActivityNotificationInput,
) error {
	if s.send != nil {
		return s.send(ctx, input)
	}
	return nil
}

func TestJoinActivityNotifiesHostWhenParticipantJoins(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	participantUserID := uuid.New()
	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusEnrollmentOpen

	notifications := make(chan port.ActivityNotificationInput, 1)
	repo := &activityRepoStub{
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			txRepo := &activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					if requestedID != activityID {
						t.Fatalf("GetActivityByIDForUpdate() requestedID = %s, want %s", requestedID, activityID)
					}
					return activity, nil
				},
				getParticipantByActivityAndUserForUpdate: func(ctx context.Context, requestedID uuid.UUID, requestedUserID uuid.UUID) (*model.ActivityParticipant, error) {
					return nil, nil
				},
				countOccupiedSlotsForUpdate: func(ctx context.Context, requestedID uuid.UUID) (int, error) {
					return 0, nil
				},
				createParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
					return nil
				},
			}
			return fn(txRepo)
		},
	}
	uc := NewJoinUseCase(repo, nil)
	uc.SetNotificationGateway(notificationGatewayStub{
		send: func(ctx context.Context, input port.ActivityNotificationInput) error {
			notifications <- input
			return nil
		},
	})

	participant, err := uc.JoinActivity(context.Background(), JoinActivityInput{
		ActivityID: activityID,
		UserID:     participantUserID,
	})
	if err != nil {
		t.Fatalf("JoinActivity() error = %v", err)
	}
	if participant == nil {
		t.Fatal("JoinActivity() participant is nil")
	}

	got := waitActivityNotification(t, notifications)
	if len(got.RecipientUserIDs) != 1 || got.RecipientUserIDs[0] != hostUserID {
		t.Fatalf("recipient user ids = %v, want host %s", got.RecipientUserIDs, hostUserID)
	}
	if got.Category != "activity" || got.Priority != "normal" {
		t.Fatalf("category/priority = %q/%q, want activity/normal", got.Category, got.Priority)
	}
	if got.DeepLink != "/activities/"+activityID.String() {
		t.Fatalf("deep link = %q", got.DeepLink)
	}
	if got.Data["activityEvent"] != "participant_joined" ||
		got.Data["activityId"] != activityID.String() ||
		got.Data["participantUserId"] != participantUserID.String() {
		t.Fatalf("notification data = %#v", got.Data)
	}
	assertActivityNotificationScheduleData(t, got.Data, activity)
	if !strings.Contains(strings.ToLower(got.Title), "joined") {
		t.Fatalf("title = %q, want join wording", got.Title)
	}
}

func TestCancelActivityNotifiesParticipantsExceptHostActor(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	participantOneID := uuid.New()
	participantTwoID := uuid.New()
	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusConfirmed
	participants := []*model.ActivityParticipant{
		validParticipant(t, activityID, participantOneID, enum.ParticipantStatusApproved),
		validParticipant(t, activityID, participantTwoID, enum.ParticipantStatusConfirmed),
	}

	notifications := make(chan port.ActivityNotificationInput, 1)
	repo := &activityRepoStub{
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			txRepo := &activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					if requestedID != activityID {
						t.Fatalf("GetActivityByIDForUpdate() requestedID = %s, want %s", requestedID, activityID)
					}
					return activity, nil
				},
				listParticipantsByActivityIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) ([]*model.ActivityParticipant, error) {
					if requestedID != activityID {
						t.Fatalf("ListParticipantsByActivityIDForUpdate() requestedID = %s, want %s", requestedID, activityID)
					}
					return participants, nil
				},
				updateActivity: func(ctx context.Context, item *model.Activity) error {
					return nil
				},
				updateParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
					return nil
				},
			}
			return fn(txRepo)
		},
	}
	uc := NewActivityUseCase(repo)
	uc.SetNotificationGateway(notificationGatewayStub{
		send: func(ctx context.Context, input port.ActivityNotificationInput) error {
			notifications <- input
			return nil
		},
	})

	_, err := uc.CancelActivity(context.Background(), activityID, hostUserID, "Weather changed")
	if err != nil {
		t.Fatalf("CancelActivity() error = %v", err)
	}

	got := waitActivityNotification(t, notifications)
	if !sameUUIDSet(got.RecipientUserIDs, []uuid.UUID{participantOneID, participantTwoID}) {
		t.Fatalf("recipient user ids = %v, want participants only", got.RecipientUserIDs)
	}
	if got.Priority != "high" {
		t.Fatalf("priority = %q, want high", got.Priority)
	}
	if got.Data["activityEvent"] != "activity_cancelled" ||
		got.Data["cancelledByUserId"] != hostUserID.String() {
		t.Fatalf("notification data = %#v", got.Data)
	}
	assertActivityNotificationScheduleData(t, got.Data, activity)
}

func TestCompleteActivityNotifiesParticipantsAndExcludesHostActor(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	participantUserID := uuid.New()
	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusStarted
	activity.StartAt = time.Now().UTC().Add(-40 * time.Minute)
	activity.EndAt = time.Now().UTC().Add(10 * time.Minute)
	participant := validParticipant(t, activityID, participantUserID, enum.ParticipantStatusConfirmed)

	notifications := make(chan port.ActivityNotificationInput, 1)
	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			return activity, nil
		},
		updateActivity: func(ctx context.Context, item *model.Activity) error {
			return nil
		},
		listParticipantsByActivityID: func(ctx context.Context, requestedID uuid.UUID, limit int, offset int) ([]*model.ActivityParticipant, error) {
			if requestedID != activityID {
				t.Fatalf("ListParticipantsByActivityID() requestedID = %s, want %s", requestedID, activityID)
			}
			return []*model.ActivityParticipant{participant}, nil
		},
	}
	uc := NewActivityUseCase(repo)
	uc.SetNotificationGateway(notificationGatewayStub{
		send: func(ctx context.Context, input port.ActivityNotificationInput) error {
			notifications <- input
			return nil
		},
	})

	_, err := uc.CompleteActivity(context.Background(), activityID, hostUserID, "Finished early")
	if err != nil {
		t.Fatalf("CompleteActivity() error = %v", err)
	}

	got := waitActivityNotification(t, notifications)
	if len(got.RecipientUserIDs) != 1 || got.RecipientUserIDs[0] != participantUserID {
		t.Fatalf("recipient user ids = %v, want participant %s", got.RecipientUserIDs, participantUserID)
	}
	if got.Data["activityEvent"] != "activity_completed" ||
		got.Data["activityId"] != activityID.String() {
		t.Fatalf("notification data = %#v", got.Data)
	}
	assertActivityNotificationScheduleData(t, got.Data, activity)
}

func assertActivityNotificationScheduleData(
	t *testing.T,
	data map[string]string,
	activity *model.Activity,
) {
	t.Helper()

	if data["activityId"] != activity.ID.String() {
		t.Fatalf("activityId = %q, want %s", data["activityId"], activity.ID)
	}
	startAt := activity.StartAt.UTC().Format(timeRFC3339)
	if data["eventStartAt"] != startAt || data["startAt"] != startAt {
		t.Fatalf("start time data = %#v, want %s", data, startAt)
	}
	endAt := activity.EndAt.UTC().Format(timeRFC3339)
	if data["eventEndAt"] != endAt || data["endAt"] != endAt {
		t.Fatalf("end time data = %#v, want %s", data, endAt)
	}
	if data["eventTimezone"] != activity.Timezone || data["timezone"] != activity.Timezone {
		t.Fatalf("timezone data = %#v, want %s", data, activity.Timezone)
	}
}

func waitActivityNotification(
	t *testing.T,
	ch <-chan port.ActivityNotificationInput,
) port.ActivityNotificationInput {
	t.Helper()

	select {
	case got := <-ch:
		return got
	case <-time.After(time.Second):
		t.Fatal("timed out waiting for activity notification")
	}
	return port.ActivityNotificationInput{}
}

func sameUUIDSet(got []uuid.UUID, want []uuid.UUID) bool {
	if len(got) != len(want) {
		return false
	}
	seen := make(map[uuid.UUID]int, len(got))
	for _, id := range got {
		seen[id]++
	}
	for _, id := range want {
		if seen[id] == 0 {
			return false
		}
		seen[id]--
	}
	return true
}
