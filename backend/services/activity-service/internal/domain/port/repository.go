package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
)

type ActivityFilter struct {
	HostUserID   *uuid.UUID
	Statuses     []string
	Visibility   *string
	CategorySlug *string
	CountryCode  *string
	CityName     *string
	LanguageCode *string
	SearchQuery  *string
	Limit        int
	Offset       int
}

type JoinAvailability struct {
	OccupiedSlots int
	HasWaitlist   bool
}

type ActivityTxRepository interface {
	GetActivityByIDForUpdate(ctx context.Context, activityID uuid.UUID) (*model.Activity, error)
	GetParticipantByActivityAndUserForUpdate(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error)
	HasActiveOverlappingJoinedActivity(
		ctx context.Context,
		userID uuid.UUID,
		excludeActivityID uuid.UUID,
		startAt time.Time,
		endAt time.Time,
	) (bool, error)
	CountOccupiedSlotsForUpdate(ctx context.Context, activityID uuid.UUID) (int, error)

	CreateParticipant(ctx context.Context, item *model.ActivityParticipant) error
	UpdateParticipant(ctx context.Context, item *model.ActivityParticipant) error

	CreateParticipantEvent(ctx context.Context, item *model.ParticipantEvent) error
	CreateActivityEvent(ctx context.Context, item *model.ActivityEvent) error

	UpdateActivity(ctx context.Context, item *model.Activity) error
}

type ActivityRepository interface {
	CreateActivity(ctx context.Context, item *model.Activity) error
	UpdateActivity(ctx context.Context, item *model.Activity) error
	GetActivityByID(ctx context.Context, activityID uuid.UUID) (*model.Activity, error)
	ListActivities(ctx context.Context, filter ActivityFilter) ([]*model.Activity, error)

	CreateActivityEvent(ctx context.Context, item *model.ActivityEvent) error

	ListTagsByActivityID(ctx context.Context, activityID uuid.UUID) ([]string, error)
	ReplaceTags(ctx context.Context, activityID uuid.UUID, tags []string) error

	ListMediaByActivityID(ctx context.Context, activityID uuid.UUID) ([]*model.ActivityMedia, error)
	ReplaceMedia(ctx context.Context, activityID uuid.UUID, items []*model.ActivityMedia) error

	GetParticipantByActivityAndUser(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error)
	ListParticipantsByActivityID(ctx context.Context, activityID uuid.UUID, limit int, offset int) ([]*model.ActivityParticipant, error)

	ListHostedActivitiesByUserID(ctx context.Context, userID uuid.UUID, limit int, offset int) ([]*model.Activity, error)
	ListJoinedActivitiesByUserID(ctx context.Context, userID uuid.UUID, limit int, offset int) ([]*model.Activity, error)

	CreateParticipant(ctx context.Context, item *model.ActivityParticipant) error
	UpdateParticipant(ctx context.Context, item *model.ActivityParticipant) error
	CreateParticipantEvent(ctx context.Context, item *model.ParticipantEvent) error

	WithTx(ctx context.Context, fn func(repo ActivityTxRepository) error) error

	ListActiveBlockedURLPatterns(ctx context.Context) ([]*model.BlockedURLPattern, error)
	CountActivitiesCreatedSince(ctx context.Context, hostUserID uuid.UUID, since time.Time) (int, error)
}
