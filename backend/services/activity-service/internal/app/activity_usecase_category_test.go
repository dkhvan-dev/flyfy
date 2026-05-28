package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

type activityRepoStub struct {
	getActivityByID                              func(ctx context.Context, activityID uuid.UUID) (*model.Activity, error)
	createActivity                               func(ctx context.Context, item *model.Activity) error
	updateActivity                               func(ctx context.Context, item *model.Activity) error
	createParticipant                            func(ctx context.Context, item *model.ActivityParticipant) error
	listParticipantsByActivityID                 func(ctx context.Context, activityID uuid.UUID, limit int, offset int) ([]*model.ActivityParticipant, error)
	countActivityCompletionStatsByUserID         func(ctx context.Context, userID uuid.UUID) (port.ActivityCompletionStats, error)
	countActivitiesCreatedSince                  func(ctx context.Context, hostUserID uuid.UUID, since time.Time) (int, error)
	listActivitiesDueForRegistrationFinalization func(ctx context.Context, before time.Time, limit int) ([]*model.Activity, error)
	withTx                                       func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error
}

func (s *activityRepoStub) CreateActivity(ctx context.Context, item *model.Activity) error {
	if s.createActivity != nil {
		return s.createActivity(ctx, item)
	}
	return nil
}

func (s *activityRepoStub) UpdateActivity(ctx context.Context, item *model.Activity) error {
	if s.updateActivity != nil {
		return s.updateActivity(ctx, item)
	}
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

func (s *activityRepoStub) ListActivitiesDueForRegistrationFinalization(
	ctx context.Context,
	before time.Time,
	limit int,
) ([]*model.Activity, error) {
	if s.listActivitiesDueForRegistrationFinalization != nil {
		return s.listActivitiesDueForRegistrationFinalization(ctx, before, limit)
	}
	return nil, nil
}

func (s *activityRepoStub) ListActivitiesDueForStart(
	ctx context.Context,
	before time.Time,
	limit int,
) ([]*model.Activity, error) {
	return nil, nil
}

func (s *activityRepoStub) ListActivitiesDueForCompletion(
	ctx context.Context,
	before time.Time,
	limit int,
) ([]*model.Activity, error) {
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

func (s *activityRepoStub) CreateAttendanceQRIssue(ctx context.Context, item *model.AttendanceQRIssue) error {
	return nil
}

func (s *activityRepoStub) GetParticipantByActivityAndUser(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error) {
	return nil, nil
}

func (s *activityRepoStub) ListParticipantsByActivityID(ctx context.Context, activityID uuid.UUID, limit int, offset int) ([]*model.ActivityParticipant, error) {
	if s.listParticipantsByActivityID != nil {
		return s.listParticipantsByActivityID(ctx, activityID, limit, offset)
	}
	return nil, nil
}

func (s *activityRepoStub) ListHostedActivitiesByUserID(ctx context.Context, userID uuid.UUID, limit int, offset int) ([]*model.Activity, error) {
	return nil, nil
}

func (s *activityRepoStub) ListJoinedActivitiesByUserID(ctx context.Context, userID uuid.UUID, limit int, offset int) ([]*model.Activity, error) {
	return nil, nil
}

func (s *activityRepoStub) ListPublicProfileHostedActivities(ctx context.Context, filter port.PublicProfileActivityFilter) ([]*model.Activity, error) {
	return nil, nil
}

func (s *activityRepoStub) ListPublicProfileJoinedActivities(ctx context.Context, filter port.PublicProfileActivityFilter) ([]*model.Activity, error) {
	return nil, nil
}

func (s *activityRepoStub) CountActivityCompletionStatsByUserID(ctx context.Context, userID uuid.UUID) (port.ActivityCompletionStats, error) {
	if s.countActivityCompletionStatsByUserID != nil {
		return s.countActivityCompletionStatsByUserID(ctx, userID)
	}
	return port.ActivityCompletionStats{}, nil
}

func (s *activityRepoStub) CreateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	if s.createParticipant != nil {
		return s.createParticipant(ctx, item)
	}
	return nil
}

func (s *activityRepoStub) UpdateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	return nil
}

func (s *activityRepoStub) CreateParticipantEvent(ctx context.Context, item *model.ParticipantEvent) error {
	return nil
}

func (s *activityRepoStub) WithTx(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
	if s.withTx != nil {
		return s.withTx(ctx, fn)
	}
	return errors.New("not implemented")
}

func (s *activityRepoStub) ListActiveBlockedURLPatterns(ctx context.Context) ([]*model.BlockedURLPattern, error) {
	return nil, nil
}

func (s *activityRepoStub) CountActivitiesCreatedSince(ctx context.Context, hostUserID uuid.UUID, since time.Time) (int, error) {
	if s.countActivitiesCreatedSince != nil {
		return s.countActivitiesCreatedSince(ctx, hostUserID, since)
	}
	return 0, nil
}

type activityTxRepoStub struct {
	getActivityByIDForUpdate                 func(ctx context.Context, activityID uuid.UUID) (*model.Activity, error)
	getParticipantByActivityAndUserForUpdate func(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error)
	listParticipantsByActivityIDForUpdate    func(ctx context.Context, activityID uuid.UUID) ([]*model.ActivityParticipant, error)
	updateActivity                           func(ctx context.Context, item *model.Activity) error
	createParticipant                        func(ctx context.Context, item *model.ActivityParticipant) error
	updateParticipant                        func(ctx context.Context, item *model.ActivityParticipant) error
	createActivityEvent                      func(ctx context.Context, item *model.ActivityEvent) error
	createParticipantEvent                   func(ctx context.Context, item *model.ParticipantEvent) error
	countOccupiedSlotsForUpdate              func(ctx context.Context, activityID uuid.UUID) (int, error)
}

type paymentGatewayStub struct {
	authorize func(ctx context.Context, input port.PaymentCreateInput) (*port.PaymentTransaction, error)
	capture   func(ctx context.Context, input port.PaymentChildInput) (*port.PaymentTransaction, error)
	refund    func(ctx context.Context, input port.PaymentChildInput) (*port.PaymentTransaction, error)
	void      func(ctx context.Context, input port.PaymentChildInput) (*port.PaymentTransaction, error)
}

type userProfileResolverStub struct {
	displayNameForUserID func(ctx context.Context, userID uuid.UUID) (string, error)
	filterFriendUserIDs  func(ctx context.Context, userID uuid.UUID, candidateUserIDs []uuid.UUID) ([]uuid.UUID, error)
}

func (s userProfileResolverStub) DisplayNameForUserID(ctx context.Context, userID uuid.UUID) (string, error) {
	if s.displayNameForUserID != nil {
		return s.displayNameForUserID(ctx, userID)
	}
	return "", nil
}

func (s userProfileResolverStub) FilterFriendUserIDs(ctx context.Context, userID uuid.UUID, candidateUserIDs []uuid.UUID) ([]uuid.UUID, error) {
	if s.filterFriendUserIDs != nil {
		return s.filterFriendUserIDs(ctx, userID, candidateUserIDs)
	}
	return candidateUserIDs, nil
}

func (s paymentGatewayStub) Authorize(ctx context.Context, input port.PaymentCreateInput) (*port.PaymentTransaction, error) {
	if s.authorize != nil {
		return s.authorize(ctx, input)
	}
	return &port.PaymentTransaction{ID: uuid.New(), Status: port.PaymentStatusSucceeded}, nil
}

func (s paymentGatewayStub) Capture(ctx context.Context, input port.PaymentChildInput) (*port.PaymentTransaction, error) {
	if s.capture != nil {
		return s.capture(ctx, input)
	}
	return &port.PaymentTransaction{ID: uuid.New(), Status: port.PaymentStatusSucceeded}, nil
}

func (s paymentGatewayStub) Refund(ctx context.Context, input port.PaymentChildInput) (*port.PaymentTransaction, error) {
	if s.refund != nil {
		return s.refund(ctx, input)
	}
	return &port.PaymentTransaction{ID: uuid.New(), Status: port.PaymentStatusSucceeded}, nil
}

func (s paymentGatewayStub) Void(ctx context.Context, input port.PaymentChildInput) (*port.PaymentTransaction, error) {
	if s.void != nil {
		return s.void(ctx, input)
	}
	return &port.PaymentTransaction{ID: uuid.New(), Status: port.PaymentStatusSucceeded}, nil
}

func (s *activityTxRepoStub) GetActivityByIDForUpdate(ctx context.Context, activityID uuid.UUID) (*model.Activity, error) {
	if s.getActivityByIDForUpdate != nil {
		return s.getActivityByIDForUpdate(ctx, activityID)
	}
	return nil, nil
}

func (s *activityTxRepoStub) GetParticipantByActivityAndUserForUpdate(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error) {
	if s.getParticipantByActivityAndUserForUpdate != nil {
		return s.getParticipantByActivityAndUserForUpdate(ctx, activityID, userID)
	}
	return nil, nil
}

func (s *activityTxRepoStub) GetAttendanceQRIssueByJTIForUpdate(ctx context.Context, jti uuid.UUID) (*model.AttendanceQRIssue, error) {
	return nil, nil
}

func (s *activityTxRepoStub) GetAttendanceSyncAttemptByScanIDForUpdate(ctx context.Context, scanID uuid.UUID) (*model.AttendanceSyncAttempt, error) {
	return nil, nil
}

func (s *activityTxRepoStub) HasActiveOverlappingJoinedActivity(ctx context.Context, userID uuid.UUID, excludeActivityID uuid.UUID, startAt time.Time, endAt time.Time) (bool, error) {
	return false, nil
}

func (s *activityTxRepoStub) CountOccupiedSlotsForUpdate(ctx context.Context, activityID uuid.UUID) (int, error) {
	if s.countOccupiedSlotsForUpdate != nil {
		return s.countOccupiedSlotsForUpdate(ctx, activityID)
	}
	return 0, nil
}

func (s *activityTxRepoStub) ListParticipantsByActivityIDForUpdate(ctx context.Context, activityID uuid.UUID) ([]*model.ActivityParticipant, error) {
	if s.listParticipantsByActivityIDForUpdate != nil {
		return s.listParticipantsByActivityIDForUpdate(ctx, activityID)
	}
	return nil, nil
}

func (s *activityTxRepoStub) CreateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	if s.createParticipant != nil {
		return s.createParticipant(ctx, item)
	}
	return nil
}

func (s *activityTxRepoStub) UpdateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	if s.updateParticipant != nil {
		return s.updateParticipant(ctx, item)
	}
	return nil
}

func (s *activityTxRepoStub) CreateAttendanceSyncAttempt(ctx context.Context, item *model.AttendanceSyncAttempt) error {
	return nil
}

func (s *activityTxRepoStub) UpdateAttendanceSyncAttempt(ctx context.Context, item *model.AttendanceSyncAttempt) error {
	return nil
}

func (s *activityTxRepoStub) CreateParticipantEvent(ctx context.Context, item *model.ParticipantEvent) error {
	if s.createParticipantEvent != nil {
		return s.createParticipantEvent(ctx, item)
	}
	return nil
}

func (s *activityTxRepoStub) CreateActivityEvent(ctx context.Context, item *model.ActivityEvent) error {
	if s.createActivityEvent != nil {
		return s.createActivityEvent(ctx, item)
	}
	return nil
}

func (s *activityTxRepoStub) UpdateActivity(ctx context.Context, item *model.Activity) error {
	if s.updateActivity != nil {
		return s.updateActivity(ctx, item)
	}
	return nil
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

func TestCreateActivityNormalizesSubcategorySlug(t *testing.T) {
	t.Parallel()

	var createdItem *model.Activity
	repo := &activityRepoStub{
		createActivity: func(ctx context.Context, item *model.Activity) error {
			createdItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	input := validCreateActivityInput()
	input.CategorySlug = "food-drinks"
	input.SubcategorySlug = stringPtr(" Coffee-Meetup ")

	item, err := uc.CreateActivity(context.Background(), input)
	if err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
	}
	if item == nil || createdItem == nil {
		t.Fatal("CreateActivity() did not persist activity")
	}
	if createdItem.SubcategorySlug == nil || *createdItem.SubcategorySlug != "coffee-meetup" {
		t.Fatalf("CreateActivity() subcategory = %v, want coffee-meetup", createdItem.SubcategorySlug)
	}
}

func TestCreateActivityRejectsSubcategoryFromAnotherCategory(t *testing.T) {
	t.Parallel()

	uc := NewActivityUseCase(&activityRepoStub{})
	input := validCreateActivityInput()
	input.CategorySlug = "food-drinks"
	input.SubcategorySlug = stringPtr("karaoke")

	_, err := uc.CreateActivity(context.Background(), input)
	if !errors.Is(err, model.ErrInvalidActivitySubcategorySlug) {
		t.Fatalf("CreateActivity() error = %v, want %v", err, model.ErrInvalidActivitySubcategorySlug)
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

func TestUpdateActivityClearsSubcategoryWhenCategoryChangesWithoutReplacement(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	var updatedItem *model.Activity
	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			item := validActivity(t, activityID, actorUserID)
			item.CategorySlug = "food-drinks"
			item.SubcategorySlug = stringPtr("coffee-meetup")
			return item, nil
		},
		updateActivity: func(ctx context.Context, item *model.Activity) error {
			updatedItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	categorySlug := "games-entertainment"

	_, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID:  actorUserID,
		ActivityID:   activityID,
		CategorySlug: &categorySlug,
	})
	if err != nil {
		t.Fatalf("UpdateActivity() error = %v", err)
	}
	if updatedItem == nil {
		t.Fatal("UpdateActivity() did not persist activity")
	}
	if updatedItem.CategorySlug != "games-entertainment" {
		t.Fatalf("UpdateActivity() category = %q, want games-entertainment", updatedItem.CategorySlug)
	}
	if updatedItem.SubcategorySlug != nil {
		t.Fatalf("UpdateActivity() subcategory = %v, want nil", updatedItem.SubcategorySlug)
	}
}

func TestCreateActivityRejectsDepositPriceType(t *testing.T) {
	t.Parallel()

	uc := NewActivityUseCase(&activityRepoStub{})
	input := validCreateActivityInput()
	input.PriceType = enum.ActivityPriceTypeDeposit

	_, err := uc.CreateActivity(context.Background(), input)
	if !errors.Is(err, model.ErrInvalidPriceType) {
		t.Fatalf("CreateActivity() error = %v, want %v", err, model.ErrInvalidPriceType)
	}
}

func TestUpdateActivityRejectsDepositPriceType(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	var updated bool
	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			return validActivity(t, activityID, actorUserID), nil
		},
		updateActivity: func(ctx context.Context, item *model.Activity) error {
			updated = true
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	priceType := enum.ActivityPriceTypeDeposit

	_, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID: actorUserID,
		ActivityID:  activityID,
		PriceType:   &priceType,
	})
	if !errors.Is(err, model.ErrInvalidPriceType) {
		t.Fatalf("UpdateActivity() error = %v, want %v", err, model.ErrInvalidPriceType)
	}
	if updated {
		t.Fatal("UpdateActivity() persisted activity with deposit price type")
	}
}

func TestCreateActivityDefaultsRegistrationDeadlineToOneHourBeforeStart(t *testing.T) {
	t.Parallel()

	var createdItem *model.Activity
	repo := &activityRepoStub{
		createActivity: func(ctx context.Context, item *model.Activity) error {
			createdItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	input := validCreateActivityInput()

	item, err := uc.CreateActivity(context.Background(), input)
	if err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
	}
	if item == nil || createdItem == nil {
		t.Fatal("CreateActivity() did not persist activity")
	}

	wantDeadline := input.StartAt.UTC().Add(-1 * time.Hour)
	if !createdItem.RegistrationDeadline.Equal(wantDeadline) {
		t.Fatalf(
			"CreateActivity() registrationDeadline = %s, want %s",
			createdItem.RegistrationDeadline,
			wantDeadline,
		)
	}
}

func TestCreateActivityPublishesByDefault(t *testing.T) {
	t.Parallel()

	var createdItem *model.Activity
	repo := &activityRepoStub{
		createActivity: func(ctx context.Context, item *model.Activity) error {
			createdItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	input := validCreateActivityInput()

	item, err := uc.CreateActivity(context.Background(), input)
	if err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
	}
	if item == nil || createdItem == nil {
		t.Fatal("CreateActivity() did not persist activity")
	}
	if createdItem.Status != enum.ActivityStatusEnrollmentOpen {
		t.Fatalf("CreateActivity() status = %s, want %s", createdItem.Status, enum.ActivityStatusEnrollmentOpen)
	}
	if createdItem.ModerationStatus != enum.ActivityModerationStatusApproved {
		t.Fatalf("CreateActivity() moderation status = %s, want %s", createdItem.ModerationStatus, enum.ActivityModerationStatusApproved)
	}
	if createdItem.ModerationReasonCodes == nil {
		t.Fatal("CreateActivity() moderation reason codes is nil, want empty slice")
	}
	if createdItem.PublishedAt == nil {
		t.Fatal("CreateActivity() publishedAt is nil")
	}
}

func TestCreateActivityFlagsSuspiciousContentWithoutHidingIt(t *testing.T) {
	t.Parallel()

	var createdItem *model.Activity
	repo := &activityRepoStub{
		createActivity: func(ctx context.Context, item *model.Activity) error {
			createdItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	input := validCreateActivityInput()
	input.Title = "VIP hiking trip"
	input.Description = "Message me on WhatsApp +77011234567 before joining this premium activity."

	item, err := uc.CreateActivity(context.Background(), input)
	if err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
	}
	if item == nil || createdItem == nil {
		t.Fatal("CreateActivity() did not persist activity")
	}
	if createdItem.Status != enum.ActivityStatusEnrollmentOpen {
		t.Fatalf("CreateActivity() status = %s, want %s", createdItem.Status, enum.ActivityStatusEnrollmentOpen)
	}
	if createdItem.ModerationStatus != enum.ActivityModerationStatusFlagged {
		t.Fatalf("CreateActivity() moderation status = %s, want %s", createdItem.ModerationStatus, enum.ActivityModerationStatusFlagged)
	}
	if createdItem.ModerationRiskScore <= 0 {
		t.Fatalf("CreateActivity() moderation risk score = %d, want positive", createdItem.ModerationRiskScore)
	}
	if len(createdItem.ModerationReasonCodes) == 0 {
		t.Fatal("CreateActivity() did not persist moderation reason codes")
	}
	if createdItem.ModerationTriggeredAt == nil {
		t.Fatal("CreateActivity() moderationTriggeredAt is nil")
	}
	if createdItem.PublishedAt == nil {
		t.Fatal("CreateActivity() publishedAt is nil")
	}
}

func TestUpdateActivityFlagsSuspiciousContentWithoutHidingIt(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	var updatedItem *model.Activity
	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			return validActivity(t, activityID, actorUserID), nil
		},
		updateActivity: func(ctx context.Context, item *model.Activity) error {
			updatedItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	description := "Напишите мне в WhatsApp +77011234567 перед участием"

	item, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID: actorUserID,
		ActivityID:  activityID,
		Description: &description,
	})
	if err != nil {
		t.Fatalf("UpdateActivity() error = %v", err)
	}
	if item == nil || updatedItem == nil {
		t.Fatal("UpdateActivity() did not persist activity")
	}
	if updatedItem.Status != enum.ActivityStatusEnrollmentOpen {
		t.Fatalf("UpdateActivity() status = %s, want %s", updatedItem.Status, enum.ActivityStatusEnrollmentOpen)
	}
	if updatedItem.ModerationStatus != enum.ActivityModerationStatusFlagged {
		t.Fatalf("UpdateActivity() moderation status = %s, want %s", updatedItem.ModerationStatus, enum.ActivityModerationStatusFlagged)
	}
	if updatedItem.ModerationRiskScore <= 0 {
		t.Fatalf("UpdateActivity() moderation risk score = %d, want positive", updatedItem.ModerationRiskScore)
	}
	if len(updatedItem.ModerationReasonCodes) == 0 {
		t.Fatal("UpdateActivity() did not persist moderation reason codes")
	}
	if updatedItem.ModerationTriggeredAt == nil {
		t.Fatal("UpdateActivity() moderationTriggeredAt is nil")
	}
	if updatedItem.PublishedAt == nil {
		t.Fatal("UpdateActivity() publishedAt is nil")
	}
}

func TestRejectModerationUsesPublicCommentAsCancellationReason(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	moderatorUserID := uuid.New()
	hostUserID := uuid.New()
	activity := validActivity(t, activityID, hostUserID)
	activity.FlagForModeration(70, []string{"external_contact"}, time.Now().UTC())
	publicComment := "Уберите контактный номер из описания активности."
	var updatedItem *model.Activity
	repo := &activityRepoStub{
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			return fn(&activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					if requestedID != activityID {
						t.Fatalf("GetActivityByIDForUpdate() requestedID = %s, want %s", requestedID, activityID)
					}
					return activity, nil
				},
				listParticipantsByActivityIDForUpdate: func(context.Context, uuid.UUID) ([]*model.ActivityParticipant, error) {
					return nil, nil
				},
				updateActivity: func(ctx context.Context, item *model.Activity) error {
					updatedItem = item
					return nil
				},
			})
		},
	}

	uc := NewActivityUseCase(repo)
	item, err := uc.RejectModeration(context.Background(), activityID, moderatorUserID, publicComment)
	if err != nil {
		t.Fatalf("RejectModeration() error = %v", err)
	}
	if item == nil || updatedItem == nil {
		t.Fatal("RejectModeration() did not persist activity")
	}
	if updatedItem.Status != enum.ActivityStatusCancelled {
		t.Fatalf("activity status = %s, want %s", updatedItem.Status, enum.ActivityStatusCancelled)
	}
	if updatedItem.CancellationReason == nil || *updatedItem.CancellationReason != publicComment {
		t.Fatalf("cancellation reason = %v, want public comment", updatedItem.CancellationReason)
	}
}

func TestCreateActivityPersistsParticipantInviteSetting(t *testing.T) {
	t.Parallel()

	var createdItem *model.Activity
	repo := &activityRepoStub{
		createActivity: func(ctx context.Context, item *model.Activity) error {
			createdItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	input := validCreateActivityInput()
	input.AllowsParticipantInvites = true

	item, err := uc.CreateActivity(context.Background(), input)
	if err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
	}
	if item == nil || createdItem == nil {
		t.Fatal("CreateActivity() did not persist activity")
	}
	if !createdItem.AllowsParticipantInvites {
		t.Fatal("CreateActivity() did not persist AllowsParticipantInvites=true")
	}
}

func TestCreateActivityCreatesHostParticipantAsCheckedIn(t *testing.T) {
	t.Parallel()

	var createdParticipant *model.ActivityParticipant
	repo := &activityRepoStub{
		createParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
			createdParticipant = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	input := validCreateActivityInput()

	_, err := uc.CreateActivity(context.Background(), input)
	if err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
	}
	if createdParticipant == nil {
		t.Fatal("CreateActivity() did not create host participant")
	}
	if createdParticipant.UserID != input.HostUserID {
		t.Fatalf("CreateActivity() host participant userID = %s, want %s", createdParticipant.UserID, input.HostUserID)
	}
	if createdParticipant.Status != enum.ParticipantStatusCheckedIn {
		t.Fatalf("CreateActivity() host participant status = %s, want %s", createdParticipant.Status, enum.ParticipantStatusCheckedIn)
	}
	if createdParticipant.ApprovedAt == nil {
		t.Fatal("CreateActivity() host participant approvedAt is nil")
	}
	if createdParticipant.CheckedInAt == nil {
		t.Fatal("CreateActivity() host participant checkedInAt is nil")
	}
}

func TestUpdateActivityChangesParticipantInviteSetting(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	var updatedItem *model.Activity
	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			item := validActivity(t, activityID, actorUserID)
			item.AllowsParticipantInvites = false
			return item, nil
		},
		updateActivity: func(ctx context.Context, item *model.Activity) error {
			updatedItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	allowInvites := true

	_, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID:              actorUserID,
		ActivityID:               activityID,
		AllowsParticipantInvites: &allowInvites,
	})
	if err != nil {
		t.Fatalf("UpdateActivity() error = %v", err)
	}
	if updatedItem == nil {
		t.Fatal("UpdateActivity() did not persist activity")
	}
	if !updatedItem.AllowsParticipantInvites {
		t.Fatal("UpdateActivity() did not set AllowsParticipantInvites=true")
	}
}

func TestUpdateActivityRecalculatesRegistrationDeadlineWhenStartChanges(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	var updatedItem *model.Activity

	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			return validActivity(t, activityID, actorUserID), nil
		},
		updateActivity: func(ctx context.Context, item *model.Activity) error {
			updatedItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	newStartAt := time.Now().UTC().Add(5 * time.Hour)
	newEndAt := newStartAt.Add(2 * time.Hour)

	_, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID: actorUserID,
		ActivityID:  activityID,
		StartAt:     &newStartAt,
		EndAt:       &newEndAt,
	})
	if err != nil {
		t.Fatalf("UpdateActivity() error = %v", err)
	}
	if updatedItem == nil {
		t.Fatal("UpdateActivity() did not persist activity")
	}

	wantDeadline := newStartAt.UTC().Add(-1 * time.Hour)
	if !updatedItem.RegistrationDeadline.Equal(wantDeadline) {
		t.Fatalf(
			"UpdateActivity() registrationDeadline = %s, want %s",
			updatedItem.RegistrationDeadline,
			wantDeadline,
		)
	}
}

func TestCreateActivityRejectsStartAtBeyondPlanningWindow(t *testing.T) {
	t.Parallel()

	uc := NewActivityUseCase(&activityRepoStub{})
	input := validCreateActivityInput()
	input.StartAt = time.Now().UTC().AddDate(0, 0, 40)
	input.EndAt = input.StartAt.Add(2 * time.Hour)

	_, err := uc.CreateActivity(context.Background(), input)
	if !errors.Is(err, model.ErrActivityStartTooFar) {
		t.Fatalf("CreateActivity() error = %v, want %v", err, model.ErrActivityStartTooFar)
	}
}

func TestUpdateActivityRejectsDurationLongerThanOneMonth(t *testing.T) {
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
	item := validActivity(t, activityID, actorUserID)
	tooLongEndAt := item.StartAt.AddDate(0, 1, 1)

	_, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID: actorUserID,
		ActivityID:  activityID,
		EndAt:       &tooLongEndAt,
	})
	if !errors.Is(err, model.ErrActivityDurationTooLong) {
		t.Fatalf("UpdateActivity() error = %v, want %v", err, model.ErrActivityDurationTooLong)
	}
}

func TestCreateActivityPrivateRequiresPassword(t *testing.T) {
	t.Parallel()

	uc := NewActivityUseCase(&activityRepoStub{})
	input := validCreateActivityInput()
	input.Visibility = enum.ActivityVisibilityPrivate

	_, err := uc.CreateActivity(context.Background(), input)
	if !errors.Is(err, model.ErrInvalidVisibilityPassword) {
		t.Fatalf("CreateActivity() error = %v, want %v", err, model.ErrInvalidVisibilityPassword)
	}
}

func TestCreateActivityPrivateRejectsNonASCIIVisibilityPassword(t *testing.T) {
	t.Parallel()

	uc := NewActivityUseCase(&activityRepoStub{})
	input := validCreateActivityInput()
	input.Visibility = enum.ActivityVisibilityPrivate
	password := "пароль123!"
	input.VisibilityPassword = &password

	_, err := uc.CreateActivity(context.Background(), input)
	if !errors.Is(err, model.ErrInvalidVisibilityPassword) {
		t.Fatalf("CreateActivity() error = %v, want %v", err, model.ErrInvalidVisibilityPassword)
	}
}

func TestCreateActivityPrivateHashesPassword(t *testing.T) {
	t.Parallel()

	var createdItem *model.Activity
	repo := &activityRepoStub{
		createActivity: func(ctx context.Context, item *model.Activity) error {
			createdItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	input := validCreateActivityInput()
	input.Visibility = enum.ActivityVisibilityPrivate
	password := "private-pass-2026"
	input.VisibilityPassword = &password

	_, err := uc.CreateActivity(context.Background(), input)
	if err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
	}
	if createdItem == nil || createdItem.VisibilityPasswordHash == nil {
		t.Fatal("CreateActivity() did not store visibility password hash")
	}
	if *createdItem.VisibilityPasswordHash == password {
		t.Fatal("CreateActivity() stored plaintext password instead of hash")
	}
	if err := bcrypt.CompareHashAndPassword(
		[]byte(*createdItem.VisibilityPasswordHash),
		[]byte(password),
	); err != nil {
		t.Fatalf("stored visibility password hash mismatch: %v", err)
	}
}

func TestUpdateActivityClearsPrivatePasswordWhenVisibilityChanges(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	var updatedItem *model.Activity

	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			item := validActivity(t, activityID, actorUserID)
			item.Visibility = enum.ActivityVisibilityPrivate
			hash := "$2a$10$abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ12"
			item.VisibilityPasswordHash = &hash
			return item, nil
		},
		updateActivity: func(ctx context.Context, item *model.Activity) error {
			updatedItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	nextVisibility := enum.ActivityVisibilityPublic

	_, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID: actorUserID,
		ActivityID:  activityID,
		Visibility:  &nextVisibility,
	})
	if err != nil {
		t.Fatalf("UpdateActivity() error = %v", err)
	}
	if updatedItem == nil {
		t.Fatal("UpdateActivity() did not persist activity")
	}
	if updatedItem.VisibilityPasswordHash != nil {
		t.Fatalf("UpdateActivity() visibilityPasswordHash = %v, want nil", *updatedItem.VisibilityPasswordHash)
	}
}

func TestUpdateActivityAllowsPriceChangeWhenOnlyHostParticipantExists(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	var updatedItem *model.Activity

	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			item := validActivity(t, activityID, actorUserID)
			item.Status = enum.ActivityStatusEnrollmentOpen
			return item, nil
		},
		listParticipantsByActivityID: func(ctx context.Context, requestedID uuid.UUID, limit int, offset int) ([]*model.ActivityParticipant, error) {
			if requestedID != activityID {
				t.Fatalf("ListParticipantsByActivityID() requestedID = %s, want %s", requestedID, activityID)
			}
			return []*model.ActivityParticipant{
				validParticipant(t, activityID, actorUserID, enum.ParticipantStatusApproved),
			}, nil
		},
		updateActivity: func(ctx context.Context, item *model.Activity) error {
			updatedItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	nextPriceType := enum.ActivityPriceTypePaid
	nextPriceAmount := 2500.0
	nextCurrency := "KZT"

	_, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID:    actorUserID,
		ActivityID:     activityID,
		PriceType:      &nextPriceType,
		PriceAmount:    &nextPriceAmount,
		HasPriceAmount: true,
		Currency:       &nextCurrency,
		HasCurrency:    true,
	})
	if err != nil {
		t.Fatalf("UpdateActivity() error = %v", err)
	}
	if updatedItem == nil {
		t.Fatal("UpdateActivity() did not persist activity")
	}
	if updatedItem.PriceAmount == nil || *updatedItem.PriceAmount != nextPriceAmount {
		t.Fatalf("UpdateActivity() priceAmount = %+v, want %v", updatedItem.PriceAmount, nextPriceAmount)
	}
}

func TestUpdateActivityRejectsPriceChangeWhenOtherParticipantExists(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	otherUserID := uuid.New()

	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			item := validActivity(t, activityID, actorUserID)
			item.Status = enum.ActivityStatusEnrollmentOpen
			return item, nil
		},
		listParticipantsByActivityID: func(ctx context.Context, requestedID uuid.UUID, limit int, offset int) ([]*model.ActivityParticipant, error) {
			if requestedID != activityID {
				t.Fatalf("ListParticipantsByActivityID() requestedID = %s, want %s", requestedID, activityID)
			}
			return []*model.ActivityParticipant{
				validParticipant(t, activityID, actorUserID, enum.ParticipantStatusApproved),
				validParticipant(t, activityID, otherUserID, enum.ParticipantStatusApproved),
			}, nil
		},
	}

	uc := NewActivityUseCase(repo)
	nextPriceType := enum.ActivityPriceTypePaid
	nextPriceAmount := 2500.0
	nextCurrency := "KZT"

	_, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID:    actorUserID,
		ActivityID:     activityID,
		PriceType:      &nextPriceType,
		PriceAmount:    &nextPriceAmount,
		HasPriceAmount: true,
		Currency:       &nextCurrency,
		HasCurrency:    true,
	})
	if !errors.Is(err, ErrPriceChangeForbidden) {
		t.Fatalf("UpdateActivity() error = %v, want %v", err, ErrPriceChangeForbidden)
	}
}

func TestUpdateActivityAllowsMeetingAddressChangeMoreThanOneHourBeforeStart(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	nextAddress := "Алматы, Казахстан, улица Байзакова 128"
	var updatedItem *model.Activity

	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			item := validActivity(t, activityID, actorUserID)
			item.Format = enum.ActivityFormatOffline
			item.Status = enum.ActivityStatusConfirmed
			item.MeetingURL = nil
			item.CountryCode = stringPtr("KZ")
			item.CityName = stringPtr("Алматы")
			item.AddressText = stringPtr("Алматы, Казахстан, улица Байзакова 127")
			item.Latitude = floatPtr(43.248)
			item.Longitude = floatPtr(76.912)
			item.MapURL = stringPtr("https://www.openstreetmap.org/?mlat=43.248&mlon=76.912")
			item.StartAt = time.Now().UTC().Add(2 * time.Hour)
			item.EndAt = item.StartAt.Add(2 * time.Hour)
			item.RegistrationDeadline = item.StartAt.Add(-1 * time.Hour)
			return item, nil
		},
		updateActivity: func(ctx context.Context, item *model.Activity) error {
			updatedItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	_, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID:    actorUserID,
		ActivityID:     activityID,
		AddressText:    &nextAddress,
		HasAddressText: true,
	})
	if err != nil {
		t.Fatalf("UpdateActivity() error = %v", err)
	}
	if updatedItem == nil {
		t.Fatal("UpdateActivity() did not persist activity")
	}
	if updatedItem.AddressText == nil || *updatedItem.AddressText != nextAddress {
		t.Fatalf("UpdateActivity() addressText = %v, want %q", updatedItem.AddressText, nextAddress)
	}
}

func TestUpdateActivityRejectsMeetingAddressChangeWithinOneHourBeforeStart(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	nextAddress := "Алматы, Казахстан, улица Байзакова 128"
	var updatedItem *model.Activity

	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			item := validActivity(t, activityID, actorUserID)
			item.Format = enum.ActivityFormatOffline
			item.Status = enum.ActivityStatusConfirmed
			item.MeetingURL = nil
			item.CountryCode = stringPtr("KZ")
			item.CityName = stringPtr("Алматы")
			item.AddressText = stringPtr("Алматы, Казахстан, улица Байзакова 127")
			item.Latitude = floatPtr(43.248)
			item.Longitude = floatPtr(76.912)
			item.MapURL = stringPtr("https://www.openstreetmap.org/?mlat=43.248&mlon=76.912")
			item.StartAt = time.Now().UTC().Add(45 * time.Minute)
			item.EndAt = item.StartAt.Add(2 * time.Hour)
			item.RegistrationDeadline = item.StartAt.Add(-1 * time.Hour)
			return item, nil
		},
		updateActivity: func(ctx context.Context, item *model.Activity) error {
			updatedItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	_, err := uc.UpdateActivity(context.Background(), UpdateActivityInput{
		ActorUserID:    actorUserID,
		ActivityID:     activityID,
		AddressText:    &nextAddress,
		HasAddressText: true,
	})
	if !errors.Is(err, ErrMeetingAddressUpdateClosed) {
		t.Fatalf("UpdateActivity() error = %v, want %v", err, ErrMeetingAddressUpdateClosed)
	}
	if updatedItem != nil {
		t.Fatal("UpdateActivity() persisted forbidden meeting address change")
	}
}

func TestGetActivityByIDAutoStartsActivityWhenStartTimePassed(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	var updatedItem *model.Activity

	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			item := validActivity(t, activityID, actorUserID)
			item.Status = enum.ActivityStatusConfirmed
			item.StartAt = time.Now().UTC().Add(-15 * time.Minute)
			item.EndAt = time.Now().UTC().Add(45 * time.Minute)
			return item, nil
		},
		updateActivity: func(ctx context.Context, item *model.Activity) error {
			updatedItem = item
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	item, err := uc.GetActivityByID(context.Background(), activityID)
	if err != nil {
		t.Fatalf("GetActivityByID() error = %v", err)
	}
	if item == nil {
		t.Fatal("GetActivityByID() returned nil activity")
	}
	if item.Status != enum.ActivityStatusStarted {
		t.Fatalf("GetActivityByID() status = %s, want %s", item.Status, enum.ActivityStatusStarted)
	}
	if item.StartedAt == nil || !item.StartedAt.Equal(item.StartAt) {
		t.Fatalf("GetActivityByID() startedAt = %v, want %v", item.StartedAt, item.StartAt)
	}
	if updatedItem == nil || updatedItem.Status != enum.ActivityStatusStarted {
		t.Fatalf("UpdateActivity() item = %+v, want started activity", updatedItem)
	}
}

func TestAutoFinalizeRegistrationCancelsWhenMinimumParticipantsNotMet(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	userID := uuid.New()
	minParticipants := 2

	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusEnrollmentOpen
	activity.MinParticipants = &minParticipants
	activity.RegistrationDeadline = time.Now().UTC().Add(-5 * time.Minute)
	activity.StartAt = time.Now().UTC().Add(45 * time.Minute)
	activity.EndAt = activity.StartAt.Add(90 * time.Minute)

	hostParticipant := validParticipant(t, activityID, hostUserID, enum.ParticipantStatusCheckedIn)
	userParticipant := validParticipant(t, activityID, userID, enum.ParticipantStatusApproved)
	participants := []*model.ActivityParticipant{hostParticipant, userParticipant}

	var updatedActivity *model.Activity
	repo := &activityRepoStub{
		listActivitiesDueForRegistrationFinalization: func(ctx context.Context, before time.Time, limit int) ([]*model.Activity, error) {
			return []*model.Activity{activity}, nil
		},
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
					updatedActivity = item
					return nil
				},
			}
			return fn(txRepo)
		},
	}

	uc := NewActivityUseCase(repo)
	stats, err := uc.AutoFinalizeRegistrationDueActivities(context.Background(), 100)
	if err != nil {
		t.Fatalf("AutoFinalizeRegistrationDueActivities() error = %v", err)
	}
	if stats.Cancelled != 1 || stats.Confirmed != 0 || stats.Finalized != 1 {
		t.Fatalf("AutoFinalizeRegistrationDueActivities() stats = %+v, want one cancelled", stats)
	}
	if updatedActivity == nil || updatedActivity.Status != enum.ActivityStatusCancelled {
		t.Fatalf("updated activity = %+v, want cancelled", updatedActivity)
	}
	if updatedActivity.CancellationSource == nil ||
		*updatedActivity.CancellationSource != enum.ActivityCancellationSourceSystem {
		t.Fatalf("cancellation source = %+v, want SYSTEM", updatedActivity.CancellationSource)
	}
	if updatedActivity.CancellationReason == nil ||
		*updatedActivity.CancellationReason != CancellationReasonMinParticipantsNotMet {
		t.Fatalf("cancellation reason = %+v, want %s", updatedActivity.CancellationReason, CancellationReasonMinParticipantsNotMet)
	}
	if userParticipant.Status != enum.ParticipantStatusCancelledByActivity {
		t.Fatalf("participant status = %s, want %s", userParticipant.Status, enum.ParticipantStatusCancelledByActivity)
	}
}

func TestGetActivityCompletionStatsCountsHostedAndJoinedWithoutSelfHostedDuplicates(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	repo := &activityRepoStub{
		countActivityCompletionStatsByUserID: func(ctx context.Context, requestedUserID uuid.UUID) (port.ActivityCompletionStats, error) {
			if requestedUserID != userID {
				t.Fatalf("CountActivityCompletionStatsByUserID() userID = %s, want %s", requestedUserID, userID)
			}
			return port.ActivityCompletionStats{
				HostedCompleted: 9,
				JoinedCompleted: 2,
			}, nil
		},
	}

	uc := NewActivityUseCase(repo)
	stats, err := uc.GetActivityCompletionStats(context.Background(), userID)
	if err != nil {
		t.Fatalf("GetActivityCompletionStats() error = %v", err)
	}

	if stats.HostedCompleted != 9 || stats.JoinedCompleted != 2 || stats.TotalCompleted != 11 {
		t.Fatalf("GetActivityCompletionStats() = %+v, want hosted=9 joined=2 total=11", stats)
	}
}

func TestAutoFinalizeRegistrationCapturesAuthorizedPaidParticipants(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	userID := uuid.New()
	minParticipants := 1
	priceAmount := 2500.0
	currency := "KZT"
	authPaymentID := uuid.New()
	capturePaymentID := uuid.New()

	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusEnrollmentOpen
	activity.MinParticipants = &minParticipants
	activity.PriceType = enum.ActivityPriceTypePaid
	activity.PriceAmount = &priceAmount
	activity.Currency = &currency
	activity.RegistrationDeadline = time.Now().UTC().Add(-5 * time.Minute)
	activity.StartAt = time.Now().UTC().Add(45 * time.Minute)
	activity.EndAt = activity.StartAt.Add(90 * time.Minute)

	participant := validParticipant(t, activityID, userID, enum.ParticipantStatusConfirmed)
	participant.PaymentTransactionID = &authPaymentID
	participants := []*model.ActivityParticipant{participant}

	var updatedActivity *model.Activity
	createdEventTypes := make([]string, 0)
	repo := &activityRepoStub{
		listActivitiesDueForRegistrationFinalization: func(ctx context.Context, before time.Time, limit int) ([]*model.Activity, error) {
			return []*model.Activity{activity}, nil
		},
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			txRepo := &activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					return activity, nil
				},
				listParticipantsByActivityIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) ([]*model.ActivityParticipant, error) {
					return participants, nil
				},
				getParticipantByActivityAndUserForUpdate: func(ctx context.Context, requestedID uuid.UUID, requestedUserID uuid.UUID) (*model.ActivityParticipant, error) {
					return participant, nil
				},
				updateActivity: func(ctx context.Context, item *model.Activity) error {
					updatedActivity = item
					return nil
				},
				updateParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
					participant = item
					return nil
				},
				createActivityEvent: func(ctx context.Context, item *model.ActivityEvent) error {
					return nil
				},
				createParticipantEvent: func(ctx context.Context, item *model.ParticipantEvent) error {
					createdEventTypes = append(createdEventTypes, item.EventType)
					return nil
				},
			}
			return fn(txRepo)
		},
	}

	uc := NewActivityUseCase(repo)
	uc.SetPaymentGateway(paymentGatewayStub{
		capture: func(ctx context.Context, input port.PaymentChildInput) (*port.PaymentTransaction, error) {
			if input.ParentTransactionID != authPaymentID {
				t.Fatalf("capture parent id = %s, want %s", input.ParentTransactionID, authPaymentID)
			}
			return &port.PaymentTransaction{ID: capturePaymentID, Status: port.PaymentStatusSucceeded}, nil
		},
	})

	stats, err := uc.AutoFinalizeRegistrationDueActivities(context.Background(), 100)
	if err != nil {
		t.Fatalf("AutoFinalizeRegistrationDueActivities() error = %v", err)
	}
	if stats.Confirmed != 1 || stats.Cancelled != 0 || stats.Finalized != 1 {
		t.Fatalf("AutoFinalizeRegistrationDueActivities() stats = %+v, want confirmed", stats)
	}
	if updatedActivity == nil || updatedActivity.Status != enum.ActivityStatusConfirmed {
		t.Fatalf("updated activity = %+v, want confirmed", updatedActivity)
	}
	if participant.PaymentTransactionID == nil || *participant.PaymentTransactionID != capturePaymentID {
		t.Fatalf("participant payment id = %+v, want capture id %s", participant.PaymentTransactionID, capturePaymentID)
	}
	if participant.PaidAt == nil {
		t.Fatal("participant PaidAt is nil after capture")
	}
	if !containsString(createdEventTypes, ParticipantEventTypePaymentCaptureSucceeded) {
		t.Fatalf("created event types = %v, want capture event", createdEventTypes)
	}
}

func TestJoinPaidActivityAuthorizesPaymentAndConfirmsParticipant(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	userID := uuid.New()
	priceAmount := 2500.0
	currency := "KZT"

	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusEnrollmentOpen
	activity.PriceType = enum.ActivityPriceTypePaid
	activity.PriceAmount = &priceAmount
	activity.Currency = &currency

	var createdParticipant *model.ActivityParticipant
	createdEventTypes := make([]string, 0)

	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			return activity, nil
		},
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			txRepo := &activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					return activity, nil
				},
				getParticipantByActivityAndUserForUpdate: func(ctx context.Context, requestedID uuid.UUID, requestedUserID uuid.UUID) (*model.ActivityParticipant, error) {
					return createdParticipant, nil
				},
				countOccupiedSlotsForUpdate: func(ctx context.Context, requestedID uuid.UUID) (int, error) {
					return 0, nil
				},
				createParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
					createdParticipant = item
					return nil
				},
				updateParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
					createdParticipant = item
					return nil
				},
				createParticipantEvent: func(ctx context.Context, item *model.ParticipantEvent) error {
					createdEventTypes = append(createdEventTypes, item.EventType)
					return nil
				},
			}
			return fn(txRepo)
		},
	}

	uc := NewJoinUseCase(repo, nil)
	uc.SetPaymentGateway(paymentGatewayStub{})
	participant, err := uc.JoinActivity(context.Background(), JoinActivityInput{
		ActivityID: activityID,
		UserID:     userID,
	})
	if err != nil {
		t.Fatalf("JoinActivity() error = %v", err)
	}
	if participant == nil || createdParticipant == nil {
		t.Fatal("JoinActivity() did not create participant")
	}
	if participant.Status != enum.ParticipantStatusConfirmed {
		t.Fatalf("participant status = %s, want %s", participant.Status, enum.ParticipantStatusConfirmed)
	}
	if participant.PaymentTransactionID == nil {
		t.Fatal("paid participant PaymentTransactionID is nil")
	}
	if participant.PaidAt != nil {
		t.Fatal("paid participant PaidAt should stay nil until capture")
	}
	if !containsString(createdEventTypes, ParticipantEventTypePaymentAuthorizationSucceeded) {
		t.Fatalf("created event types = %v, want authorization event", createdEventTypes)
	}
}

func TestInviteFriendsCreatesInvitedParticipantsAndSkipsExistingParticipants(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	actorUserID := uuid.New()
	inviteeUserID := uuid.New()
	existingParticipantUserID := uuid.New()

	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusEnrollmentOpen
	activity.AllowsParticipantInvites = true

	existingParticipant := validParticipant(
		t,
		activityID,
		existingParticipantUserID,
		enum.ParticipantStatusApproved,
	)
	createdParticipants := make([]*model.ActivityParticipant, 0)
	createdEventTypes := make([]string, 0)

	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			return activity, nil
		},
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			txRepo := &activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					return activity, nil
				},
				getParticipantByActivityAndUserForUpdate: func(ctx context.Context, requestedID uuid.UUID, requestedUserID uuid.UUID) (*model.ActivityParticipant, error) {
					if requestedUserID == existingParticipantUserID {
						return existingParticipant, nil
					}
					return nil, nil
				},
				createParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
					createdParticipants = append(createdParticipants, item)
					return nil
				},
				createParticipantEvent: func(ctx context.Context, item *model.ParticipantEvent) error {
					createdEventTypes = append(createdEventTypes, item.EventType)
					return nil
				},
			}
			return fn(txRepo)
		},
	}

	resolver := userProfileResolverStub{
		filterFriendUserIDs: func(ctx context.Context, userID uuid.UUID, candidateUserIDs []uuid.UUID) ([]uuid.UUID, error) {
			return []uuid.UUID{inviteeUserID, existingParticipantUserID}, nil
		},
	}

	uc := NewJoinUseCase(repo, nil, resolver)
	result, err := uc.InviteFriends(context.Background(), InviteFriendsInput{
		ActivityID:  activityID,
		ActorUserID: actorUserID,
		InviteeUserIDs: []uuid.UUID{
			inviteeUserID,
			existingParticipantUserID,
			inviteeUserID,
			actorUserID,
			uuid.Nil,
		},
	})
	if err != nil {
		t.Fatalf("InviteFriends() error = %v", err)
	}
	if result == nil {
		t.Fatal("InviteFriends() result is nil")
	}
	if len(createdParticipants) != 1 {
		t.Fatalf("created participants = %d, want 1", len(createdParticipants))
	}
	if createdParticipants[0].UserID != inviteeUserID {
		t.Fatalf("created participant user = %s, want %s", createdParticipants[0].UserID, inviteeUserID)
	}
	if createdParticipants[0].Status != enum.ParticipantStatusInvited {
		t.Fatalf("created participant status = %s, want %s", createdParticipants[0].Status, enum.ParticipantStatusInvited)
	}
	if createdParticipants[0].Status.OccupiesSlot() {
		t.Fatal("invited participant must not occupy capacity slot")
	}
	if len(result.SkippedUserIDs) != 1 || result.SkippedUserIDs[0] != existingParticipantUserID {
		t.Fatalf("skipped users = %v, want [%s]", result.SkippedUserIDs, existingParticipantUserID)
	}
	if !containsString(createdEventTypes, string(enum.ParticipantStatusInvited)) {
		t.Fatalf("created event types = %v, want invited event", createdEventTypes)
	}
}

func TestInviteFriendsSkipsUsersWhoAreNotActorFriends(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	actorUserID := uuid.New()
	friendUserID := uuid.New()
	nonFriendUserID := uuid.New()

	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusEnrollmentOpen
	activity.AllowsParticipantInvites = true

	createdParticipants := make([]*model.ActivityParticipant, 0)
	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			return activity, nil
		},
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			txRepo := &activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					return activity, nil
				},
				getParticipantByActivityAndUserForUpdate: func(ctx context.Context, requestedID uuid.UUID, requestedUserID uuid.UUID) (*model.ActivityParticipant, error) {
					return nil, nil
				},
				createParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
					createdParticipants = append(createdParticipants, item)
					return nil
				},
			}
			return fn(txRepo)
		},
	}
	resolver := userProfileResolverStub{
		filterFriendUserIDs: func(ctx context.Context, userID uuid.UUID, candidateUserIDs []uuid.UUID) ([]uuid.UUID, error) {
			if userID != actorUserID {
				t.Fatalf("FilterFriendUserIDs() userID = %s, want %s", userID, actorUserID)
			}
			return []uuid.UUID{friendUserID}, nil
		},
	}

	uc := NewJoinUseCase(repo, nil, resolver)
	result, err := uc.InviteFriends(context.Background(), InviteFriendsInput{
		ActivityID:     activityID,
		ActorUserID:    actorUserID,
		InviteeUserIDs: []uuid.UUID{friendUserID, nonFriendUserID},
	})
	if err != nil {
		t.Fatalf("InviteFriends() error = %v", err)
	}
	if len(createdParticipants) != 1 || createdParticipants[0].UserID != friendUserID {
		t.Fatalf("created participants = %v, want only friend %s", createdParticipants, friendUserID)
	}
	if result == nil || len(result.SkippedUserIDs) != 1 || result.SkippedUserIDs[0] != nonFriendUserID {
		t.Fatalf("skipped users = %v, want [%s]", result.SkippedUserIDs, nonFriendUserID)
	}
}

func TestInviteFriendsRejectsNonHostWhenParticipantInvitesDisabled(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	actorUserID := uuid.New()
	inviteeUserID := uuid.New()

	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusEnrollmentOpen
	activity.AllowsParticipantInvites = false

	var createdParticipant *model.ActivityParticipant
	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			return activity, nil
		},
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			txRepo := &activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					return activity, nil
				},
				createParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
					createdParticipant = item
					return nil
				},
			}
			return fn(txRepo)
		},
	}

	uc := NewJoinUseCase(repo, nil)
	_, err := uc.InviteFriends(context.Background(), InviteFriendsInput{
		ActivityID:     activityID,
		ActorUserID:    actorUserID,
		InviteeUserIDs: []uuid.UUID{inviteeUserID},
	})
	if !errors.Is(err, ErrActivityInvitationForbidden) {
		t.Fatalf("InviteFriends() error = %v, want %v", err, ErrActivityInvitationForbidden)
	}
	if createdParticipant != nil {
		t.Fatal("InviteFriends() created participant even though participant invites are disabled")
	}
}

func TestInviteFriendsAllowsHostWhenParticipantInvitesDisabled(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	inviteeUserID := uuid.New()

	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusEnrollmentOpen
	activity.AllowsParticipantInvites = false

	var createdParticipant *model.ActivityParticipant
	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			return activity, nil
		},
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			txRepo := &activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					return activity, nil
				},
				createParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
					createdParticipant = item
					return nil
				},
			}
			return fn(txRepo)
		},
	}

	resolver := userProfileResolverStub{
		filterFriendUserIDs: func(ctx context.Context, userID uuid.UUID, candidateUserIDs []uuid.UUID) ([]uuid.UUID, error) {
			return []uuid.UUID{inviteeUserID}, nil
		},
	}

	uc := NewJoinUseCase(repo, nil, resolver)
	_, err := uc.InviteFriends(context.Background(), InviteFriendsInput{
		ActivityID:     activityID,
		ActorUserID:    hostUserID,
		InviteeUserIDs: []uuid.UUID{inviteeUserID},
	})
	if err != nil {
		t.Fatalf("InviteFriends() error = %v", err)
	}
	if createdParticipant == nil {
		t.Fatal("InviteFriends() did not create host invitation")
	}
	if createdParticipant.UserID != inviteeUserID {
		t.Fatalf("invited user = %s, want %s", createdParticipant.UserID, inviteeUserID)
	}
}

func TestJoinActivityAcceptsExistingInvitation(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	userID := uuid.New()

	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusEnrollmentOpen
	invitation := validParticipant(t, activityID, userID, enum.ParticipantStatusInvited)

	var createdParticipant *model.ActivityParticipant
	var updatedParticipant *model.ActivityParticipant
	createdEventTypes := make([]string, 0)

	repo := &activityRepoStub{
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			txRepo := &activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					return activity, nil
				},
				getParticipantByActivityAndUserForUpdate: func(ctx context.Context, requestedID uuid.UUID, requestedUserID uuid.UUID) (*model.ActivityParticipant, error) {
					return invitation, nil
				},
				countOccupiedSlotsForUpdate: func(ctx context.Context, requestedID uuid.UUID) (int, error) {
					return 0, nil
				},
				createParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
					createdParticipant = item
					return nil
				},
				updateParticipant: func(ctx context.Context, item *model.ActivityParticipant) error {
					updatedParticipant = item
					return nil
				},
				createParticipantEvent: func(ctx context.Context, item *model.ParticipantEvent) error {
					createdEventTypes = append(createdEventTypes, item.EventType)
					return nil
				},
			}
			return fn(txRepo)
		},
	}

	uc := NewJoinUseCase(repo, nil)
	participant, err := uc.JoinActivity(context.Background(), JoinActivityInput{
		ActivityID: activityID,
		UserID:     userID,
	})
	if err != nil {
		t.Fatalf("JoinActivity() error = %v", err)
	}
	if createdParticipant != nil {
		t.Fatal("JoinActivity() created duplicate participant for existing invitation")
	}
	if updatedParticipant == nil {
		t.Fatal("JoinActivity() did not update invited participant")
	}
	if participant.ID != invitation.ID {
		t.Fatalf("participant id = %s, want invitation id %s", participant.ID, invitation.ID)
	}
	if participant.Status != enum.ParticipantStatusApproved {
		t.Fatalf("participant status = %s, want %s", participant.Status, enum.ParticipantStatusApproved)
	}
	if participant.ApprovedAt == nil {
		t.Fatal("accepted invited participant ApprovedAt is nil")
	}
	if !containsString(createdEventTypes, string(enum.ParticipantStatusApproved)) {
		t.Fatalf("created event types = %v, want approved event", createdEventTypes)
	}
}

func TestLeavePaidActivityAfterDeadlineMarksLateCancellationWithoutRefund(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	userID := uuid.New()
	priceAmount := 2500.0
	currency := "KZT"
	now := time.Now().UTC()

	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusConfirmed
	activity.PriceType = enum.ActivityPriceTypePaid
	activity.PriceAmount = &priceAmount
	activity.Currency = &currency
	activity.RegistrationDeadline = now.Add(-10 * time.Minute)
	activity.StartAt = now.Add(50 * time.Minute)
	activity.EndAt = activity.StartAt.Add(90 * time.Minute)

	participant := validParticipant(t, activityID, userID, enum.ParticipantStatusConfirmed)
	paidAt := now.Add(-20 * time.Minute)
	paymentTransactionID := uuid.New()
	participant.PaidAt = &paidAt
	participant.PaymentTransactionID = &paymentTransactionID

	createdEventTypes := make([]string, 0)
	repo := &activityRepoStub{
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			txRepo := &activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					return activity, nil
				},
				getParticipantByActivityAndUserForUpdate: func(ctx context.Context, requestedID uuid.UUID, requestedUserID uuid.UUID) (*model.ActivityParticipant, error) {
					return participant, nil
				},
				createParticipantEvent: func(ctx context.Context, item *model.ParticipantEvent) error {
					createdEventTypes = append(createdEventTypes, item.EventType)
					return nil
				},
			}
			return fn(txRepo)
		},
	}

	uc := NewJoinUseCase(repo, nil)
	updated, err := uc.LeaveActivity(context.Background(), LeaveActivityInput{
		ActivityID: activityID,
		UserID:     userID,
	})
	if err != nil {
		t.Fatalf("LeaveActivity() error = %v", err)
	}
	if updated.Status != enum.ParticipantStatusLateCancelled {
		t.Fatalf("participant status = %s, want %s", updated.Status, enum.ParticipantStatusLateCancelled)
	}
	if !containsString(createdEventTypes, ParticipantEventTypePaymentRefundDenied) {
		t.Fatalf("created event types = %v, want refund denied event", createdEventTypes)
	}
}

func TestExtendActivityRejectsBeforeStart(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()

	repo := &activityRepoStub{
		getActivityByID: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
			if requestedID != activityID {
				t.Fatalf("GetActivityByID() requestedID = %s, want %s", requestedID, activityID)
			}
			item := validActivity(t, activityID, actorUserID)
			item.Status = enum.ActivityStatusPublished
			item.StartAt = time.Now().UTC().Add(30 * time.Minute)
			item.EndAt = item.StartAt.Add(90 * time.Minute)
			return item, nil
		},
	}

	uc := NewActivityUseCase(repo)
	_, err := uc.ExtendActivity(context.Background(), activityID, actorUserID, 30)
	if !errors.Is(err, ErrActivityNotExtendable) {
		t.Fatalf("ExtendActivity() error = %v, want %v", err, ErrActivityNotExtendable)
	}
}

func validCreateActivityInput() CreateActivityInput {
	startAt := time.Now().UTC().Add(2 * time.Hour)
	endAt := startAt.Add(2 * time.Hour)
	meetingURL := "https://meet.example.com/flyfy"

	return CreateActivityInput{
		HostUserID:   uuid.New(),
		Title:        "Sunrise breathing session",
		Description:  "Guided morning practice with breathing and stretching.",
		Format:       enum.ActivityFormatOnline,
		Visibility:   enum.ActivityVisibilityPublic,
		CategorySlug: "health-wellness",
		LanguageCode: "en",
		Timezone:     "Asia/Almaty",
		StartAt:      startAt,
		EndAt:        endAt,
		CapacityType: enum.ActivityCapacityTypeUnlimited,
		PriceType:    enum.ActivityPriceTypeFree,
		MeetingURL:   &meetingURL,
	}
}

func TestCreateActivityStoresAuthorLocationSnapshotSeparatelyFromActivityLocation(t *testing.T) {
	t.Parallel()

	authorCountryCode := "KZ"
	authorCityID := "almaty"
	authorCityName := "Almaty"
	input := validCreateActivityInput()
	input.AuthorCountryCode = &authorCountryCode
	input.AuthorCityID = &authorCityID
	input.AuthorCityName = &authorCityName

	repo := &activityRepoStub{
		createActivity: func(ctx context.Context, item *model.Activity) error {
			if item.CountryCode != nil || item.CityID != nil || item.CityName != nil {
				t.Fatalf("online activity location = %v/%v/%v, want nil meeting location", item.CountryCode, item.CityID, item.CityName)
			}
			if item.AuthorCountryCode == nil || *item.AuthorCountryCode != authorCountryCode {
				t.Fatalf("AuthorCountryCode = %v, want %q", item.AuthorCountryCode, authorCountryCode)
			}
			if item.AuthorCityID == nil || *item.AuthorCityID != authorCityID {
				t.Fatalf("AuthorCityID = %v, want %q", item.AuthorCityID, authorCityID)
			}
			if item.AuthorCityName == nil || *item.AuthorCityName != authorCityName {
				t.Fatalf("AuthorCityName = %v, want %q", item.AuthorCityName, authorCityName)
			}
			if item.AuthorLocationCapturedAt == nil {
				t.Fatal("AuthorLocationCapturedAt = nil, want server-side capture timestamp")
			}
			return nil
		},
	}

	uc := NewActivityUseCase(repo)
	if _, err := uc.CreateActivity(context.Background(), input); err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
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
		CategorySlug:                   input.CategorySlug,
		LanguageCode:                   input.LanguageCode,
		Timezone:                       input.Timezone,
		StartAt:                        input.StartAt,
		EndAt:                          input.EndAt,
		RegistrationDeadline:           input.StartAt.UTC().Add(-1 * time.Hour),
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

func stringPtr(value string) *string {
	return &value
}

func floatPtr(value float64) *float64 {
	return &value
}

func validParticipant(
	t *testing.T,
	activityID uuid.UUID,
	userID uuid.UUID,
	status enum.ParticipantStatus,
) *model.ActivityParticipant {
	t.Helper()

	item, err := model.NewActivityParticipant(model.NewActivityParticipantParams{
		ActivityID: activityID,
		UserID:     userID,
		Status:     status,
	})
	if err != nil {
		t.Fatalf("model.NewActivityParticipant() error = %v", err)
	}

	return item
}

func containsString(items []string, needle string) bool {
	for _, item := range items {
		if item == needle {
			return true
		}
	}
	return false
}
