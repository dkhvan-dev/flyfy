package grpc

import (
	"errors"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
)

func mapError(err error) error {
	switch {
	case err == nil:
		return nil

	case errors.Is(err, app.ErrInvalidActivityID),
		errors.Is(err, app.ErrInvalidActorUserID),
		errors.Is(err, app.ErrInvalidParticipantUserID),
		errors.Is(err, app.ErrActivityCancellationReasonRequired),
		errors.Is(err, app.ErrActivityCompletionReasonRequired),
		errors.Is(err, app.ErrActivityNotPublishable),
		errors.Is(err, app.ErrActivityNotStartable),
		errors.Is(err, app.ErrActivityNotCompletable),
		errors.Is(err, app.ErrActivityNotCancellable),
		errors.Is(err, app.ErrActivityNotExtendable),
		errors.Is(err, app.ErrActivityExtendDurationInvalid),
		errors.Is(err, app.ErrActivityJoinClosed),
		errors.Is(err, app.ErrActivityFull),
		errors.Is(err, app.ErrAlreadyJoined),
		errors.Is(err, app.ErrParticipantStateInvalid),
		errors.Is(err, app.ErrPriceChangeForbidden),
		errors.Is(err, app.ErrCriticalFieldsUpdateForbidden),
		errors.Is(err, app.ErrActivityMediaFileNotReady),
		errors.Is(err, app.ErrActivityMediaFileNotAllowed),

		errors.Is(err, model.ErrInvalidActivityTitle),
		errors.Is(err, model.ErrInvalidActivityDescription),
		errors.Is(err, model.ErrInvalidActivityFormat),
		errors.Is(err, model.ErrInvalidActivityStatus),
		errors.Is(err, model.ErrInvalidActivityVisibility),
		errors.Is(err, model.ErrInvalidActivityJoinMode),
		errors.Is(err, model.ErrInvalidActivityModerationStatus),
		errors.Is(err, model.ErrInvalidCategorySlug),
		errors.Is(err, model.ErrInvalidLanguageCode),
		errors.Is(err, model.ErrInvalidTimezone),
		errors.Is(err, model.ErrInvalidActivityTimeRange),
		errors.Is(err, model.ErrInvalidRegistrationDeadline),
		errors.Is(err, model.ErrActivityStartTooFar),
		errors.Is(err, model.ErrActivityDurationTooLong),
		errors.Is(err, model.ErrActivityTooSoon),
		errors.Is(err, model.ErrInvalidCapacityType),
		errors.Is(err, model.ErrInvalidCapacity),
		errors.Is(err, model.ErrInvalidPriceType),
		errors.Is(err, model.ErrInvalidPrice),
		errors.Is(err, model.ErrInvalidCurrency),
		errors.Is(err, model.ErrInvalidMeetingURL),
		errors.Is(err, model.ErrInvalidOfflineLocation),
		errors.Is(err, model.ErrPriceLocked),
		errors.Is(err, model.ErrOnlyAuthorCanDuplicate),
		errors.Is(err, model.ErrActivityCannotBePublished),
		errors.Is(err, model.ErrCriticalFieldsLocked):
		return status.Error(codes.InvalidArgument, err.Error())

	case errors.Is(err, app.ErrActivityNotFound),
		errors.Is(err, app.ErrParticipantNotFound),
		errors.Is(err, app.ErrActivityMediaFileNotFound):
		return status.Error(codes.NotFound, err.Error())

	case errors.Is(err, app.ErrActivityAlreadyPublished),
		errors.Is(err, app.ErrActivityAlreadyStarted),
		errors.Is(err, app.ErrActivityAlreadyCompleted),
		errors.Is(err, app.ErrActivityAlreadyCancelled),
		errors.Is(err, app.ErrActivityTooEarlyToComplete),
		errors.Is(err, app.ErrActivityShouldBeCancelledInstead),
		errors.Is(err, app.ErrParticipantScheduleConflict),
		errors.Is(err, app.ErrParticipantAlreadyCancelled),
		errors.Is(err, app.ErrModerationStateInvalid):
		return status.Error(codes.FailedPrecondition, err.Error())

	default:
		return status.Error(codes.Internal, err.Error())
	}
}
