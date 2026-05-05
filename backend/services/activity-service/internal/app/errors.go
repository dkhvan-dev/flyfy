package app

import "errors"

var (
	ErrInvalidActivityID        = errors.New("invalid activity id")
	ErrInvalidActorUserID       = errors.New("invalid actor user id")
	ErrInvalidParticipantUserID = errors.New("invalid participant user id")

	ErrActivityNotFound    = errors.New("activity not found")
	ErrParticipantNotFound = errors.New("participant not found")

	ErrActivityAlreadyPublished           = errors.New("activity already published")
	ErrActivityAlreadyStarted             = errors.New("activity already started")
	ErrActivityAlreadyCompleted           = errors.New("activity already completed")
	ErrActivityAlreadyCancelled           = errors.New("activity already cancelled")
	ErrActivityCancellationReasonRequired = errors.New("activity cancellation reason is required")
	ErrActivityCompletionReasonRequired   = errors.New("activity completion reason is required")

	ErrActivityNotPublishable           = errors.New("activity is not publishable")
	ErrActivityNotStartable             = errors.New("activity is not startable")
	ErrActivityNotCompletable           = errors.New("activity is not completable")
	ErrActivityNotCancellable           = errors.New("activity is not cancellable")
	ErrActivityNotExtendable            = errors.New("activity is not extendable")
	ErrActivityTooEarlyToComplete       = errors.New("activity can be completed only during the final 25 percent of its duration")
	ErrActivityShouldBeCancelledInstead = errors.New("activity should be cancelled instead of completed")
	ErrActivityExtendDurationInvalid    = errors.New("activity can only be extended by 30 or 60 minutes")

	ErrActivityJoinClosed          = errors.New("activity join is closed")
	ErrActivityFull                = errors.New("activity is full")
	ErrAlreadyJoined               = errors.New("user already joined activity")
	ErrParticipantScheduleConflict = errors.New("user already joined another activity with overlapping time")
	ErrParticipantAlreadyCancelled = errors.New("participant already cancelled")
	ErrParticipantStateInvalid     = errors.New("participant state is invalid for this action")
	ErrActivityLeaveClosed         = errors.New("activity cannot be left after it has started")

	ErrModerationReviewRequired = errors.New("moderation review is required")
	ErrModerationStateInvalid   = errors.New("activity moderation state is invalid")

	ErrCriticalFieldsUpdateForbidden = errors.New("critical fields cannot be changed after publication")
	ErrPriceChangeForbidden          = errors.New("price change is forbidden")

	ErrBlockedURLDetected          = errors.New("blocked url detected")
	ErrSuspiciousURLRequiresReview = errors.New("suspicious url requires review")
	ErrActivityCreationRateLimited = errors.New("activity creation rate limited")

	ErrActivityMediaFileNotFound   = errors.New("activity media file not found")
	ErrActivityMediaFileNotReady   = errors.New("activity media file is not ready")
	ErrActivityMediaFileNotAllowed = errors.New("activity media file is not allowed")

	ErrAttendanceAccessDenied       = errors.New("attendance access denied")
	ErrAttendanceQRUnavailable      = errors.New("attendance qr is unavailable for this activity")
	ErrAttendanceQRInvalid          = errors.New("attendance qr is invalid")
	ErrAttendanceQRVersionInvalid   = errors.New("attendance qr version is not supported")
	ErrAttendanceQRExpired          = errors.New("attendance qr is no longer usable")
	ErrAttendanceAlreadyCheckedIn   = errors.New("participant already checked in")
	ErrAttendanceParticipantInvalid = errors.New("participant is not eligible for attendance check-in")
)
