package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

type activityRepoStub struct {
	getActivityByID func(ctx context.Context, activityID uuid.UUID) (*model.Activity, error)
}

func (s *activityRepoStub) CreateActivity(ctx context.Context, item *model.Activity) error {
	return nil
}

func (s *activityRepoStub) UpdateActivity(ctx context.Context, item *model.Activity) error {
	return nil
}

func (s *activityRepoStub) GetActivityByID(ctx context.Context, activityID uuid.UUID) (*model.Activity, error) {
	if s.getActivityByID != nil {
		return s.getActivityByID(ctx, activityID)
	}
	return nil, nil
}

func (s *activityRepoStub) ListActivities(ctx context.Context, filter port.ActivityFilter) ([]*model.Activity, error) {
	return nil, nil
}

func (s *activityRepoStub) CreateActivityEvent(ctx context.Context, item *model.ActivityEvent) error {
	return nil
}

func (s *activityRepoStub) ListTagsByActivityID(ctx context.Context, activityID uuid.UUID) ([]string, error) {
	return nil, nil
}

func (s *activityRepoStub) ReplaceTags(ctx context.Context, activityID uuid.UUID, tags []string) error {
	return nil
}

func (s *activityRepoStub) ListMediaByActivityID(ctx context.Context, activityID uuid.UUID) ([]*model.ActivityMedia, error) {
	return nil, nil
}

func (s *activityRepoStub) ReplaceMedia(ctx context.Context, activityID uuid.UUID, items []*model.ActivityMedia) error {
	return nil
}

func (s *activityRepoStub) GetParticipantByActivityAndUser(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error) {
	return nil, nil
}

func (s *activityRepoStub) ListParticipantsByActivityID(ctx context.Context, activityID uuid.UUID, limit int, offset int) ([]*model.ActivityParticipant, error) {
	return nil, nil
}

func (s *activityRepoStub) ListHostedActivitiesByUserID(ctx context.Context, userID uuid.UUID, limit int, offset int) ([]*model.Activity, error) {
	return nil, nil
}

func (s *activityRepoStub) ListJoinedActivitiesByUserID(ctx context.Context, userID uuid.UUID, limit int, offset int) ([]*model.Activity, error) {
	return nil, nil
}

func (s *activityRepoStub) CreateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	return nil
}

func (s *activityRepoStub) UpdateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	return nil
}

func (s *activityRepoStub) CreateParticipantEvent(ctx context.Context, item *model.ParticipantEvent) error {
	return nil
}

func (s *activityRepoStub) WithTx(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
	return errors.New("not implemented")
}

func (s *activityRepoStub) ListActiveBlockedURLPatterns(ctx context.Context) ([]*model.BlockedURLPattern, error) {
	return nil, nil
}

func (s *activityRepoStub) CountActivitiesCreatedSince(ctx context.Context, hostUserID uuid.UUID, since time.Time) (int, error) {
	return 0, nil
}

func TestCreateActivityRejectsUnsupportedCategory(t *testing.T) {
	t.Parallel()

	uc := NewActivityUseCase(&activityRepoStub{})
	input := validCreateActivityInput()
	input.CategorySlug = "football"

	_, err := uc.CreateActivity(context.Background(), input)
	if !errors.Is(err, model.ErrInvalidCategorySlug) {
		t.Fatalf("CreateActivity() error = %v, want %v", err, model.ErrInvalidCategorySlug)
	}
}

func TestUpdateActivityRejectsUnsupportedCategory(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			return validActivity(t, activityID, actorUserID), nil
		},
	}

	uc := NewActivityUseCase(repo)
	invalidCategory := "football"

	_, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID:  actorUserID,
		ActivityID:   activityID,
		CategorySlug: &invalidCategory,
	})
	if !errors.Is(err, model.ErrInvalidCategorySlug) {
		t.Fatalf("UpdateActivity() error = %v, want %v", err, model.ErrInvalidCategorySlug)
	}
}

func validCreateActivityInput() CreateActivityInput {
	startAt := time.Now().UTC().Add(2 * time.Hour)
	endAt := startAt.Add(2 * time.Hour)
	registrationDeadline := startAt.Add(-30 * time.Minute)
	meetingURL := "https://meet.example.com/flyfy"

	return CreateActivityInput{
		HostUserID:           uuid.New(),
		Title:                "Sunrise breathing session",
		Description:          "Guided morning practice with breathing and stretching.",
		Format:               enum.ActivityFormatOnline,
		Visibility:           enum.ActivityVisibilityPublic,
		JoinMode:             enum.ActivityJoinModeAutoApprove,
		CategorySlug:         "health-wellness",
		LanguageCode:         "en",
		Timezone:             "Asia/Almaty",
		StartAt:              startAt,
		EndAt:                endAt,
		RegistrationDeadline: registrationDeadline,
		CapacityType:         enum.ActivityCapacityTypeUnlimited,
		PriceType:            enum.ActivityPriceTypeFree,
		MeetingURL:           &meetingURL,
	}
}

func validActivity(t *testing.T, activityID uuid.UUID, actorUserID uuid.UUID) *model.Activity {
	t.Helper()

	input := validCreateActivityInput()
	input.HostUserID = actorUserID

	item, err := model.NewActivity(model.NewActivityParams{
		HostUserID:                     input.HostUserID,
		Title:                          input.Title,
		Description:                    input.Description,
		Format:                         input.Format,
		Visibility:                     input.Visibility,
		JoinMode:                       input.JoinMode,
		CategorySlug:                   input.CategorySlug,
		LanguageCode:                   input.LanguageCode,
		Timezone:                       input.Timezone,
		StartAt:                        input.StartAt,
		EndAt:                          input.EndAt,
		RegistrationDeadline:           input.RegistrationDeadline,
		CapacityType:                   input.CapacityType,
		PriceType:                      input.PriceType,
		RequiresProfileCompletion:      true,
		RequiresAttendanceConfirmation: false,
		MeetingURL:                     input.MeetingURL,
	})
	if err != nil {
		t.Fatalf("model.NewActivity() error = %v", err)
	}

	item.ID = activityID
	return item
}
