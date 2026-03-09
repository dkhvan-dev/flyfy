package app

import "errors"

var (
	ErrInvalidActivityID        = errors.New("invalid activity id")
	ErrInvalidActorUserID       = errors.New("invalid actor user id")
	ErrInvalidParticipantUserID = errors.New("invalid participant user id")

	ErrActivityNotFound    = errors.New("activity not found")
	ErrParticipantNotFound = errors.New("participant not found")

	ErrActivityAlreadyPublished = errors.New("activity already published")
	ErrActivityAlreadyStarted   = errors.New("activity already started")
	ErrActivityAlreadyCompleted = errors.New("activity already completed")
	ErrActivityAlreadyCancelled = errors.New("activity already cancelled")

	ErrActivityNotPublishable = errors.New("activity is not publishable")
	ErrActivityNotStartable   = errors.New("activity is not startable")
	ErrActivityNotCompletable = errors.New("activity is not completable")
	ErrActivityNotCancellable = errors.New("activity is not cancellable")

	ErrActivityJoinClosed          = errors.New("activity join is closed")
	ErrActivityFull                = errors.New("activity is full")
	ErrAlreadyJoined               = errors.New("user already joined activity")
	ErrParticipantAlreadyCancelled = errors.New("participant already cancelled")
	ErrParticipantStateInvalid     = errors.New("participant state is invalid for this action")

	ErrModerationReviewRequired = errors.New("moderation review is required")
	ErrModerationStateInvalid   = errors.New("activity moderation state is invalid")

	ErrCriticalFieldsUpdateForbidden = errors.New("critical fields cannot be changed after publication")
	ErrPriceChangeForbidden          = errors.New("price change is forbidden")

	ErrBlockedURLDetected          = errors.New("blocked url detected")
	ErrSuspiciousURLRequiresReview = errors.New("suspicious url requires review")
	ErrActivityCreationRateLimited = errors.New("activity creation rate limited")
)
