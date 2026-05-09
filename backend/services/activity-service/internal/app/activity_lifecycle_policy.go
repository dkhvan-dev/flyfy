package app

import (
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
)

const (
	CancellationReasonMinParticipantsNotMet = "MIN_PARTICIPANTS_NOT_MET"
	CancellationReasonHostCancelled         = "HOST_CANCELLED"
	CancellationReasonModerationRejected    = "MODERATION_REJECTED"

	ParticipantCancelReasonActivityCancelled = "ACTIVITY_CANCELLED"
	ParticipantCancelReasonLateCancellation  = "LATE_CANCELLATION"
)

func isPaidActivity(item *model.Activity) bool {
	if item == nil {
		return false
	}
	return item.PriceType == enum.ActivityPriceTypePaid ||
		item.PriceType == enum.ActivityPriceTypeDeposit
}

func isParticipantCancellationTerminal(status enum.ParticipantStatus) bool {
	switch status {
	case enum.ParticipantStatusCancelled,
		enum.ParticipantStatusLateCancelled,
		enum.ParticipantStatusCancelledByActivity:
		return true
	default:
		return false
	}
}

func participantEligibleForMinimum(item *model.Activity, participant *model.ActivityParticipant) bool {
	if item == nil || participant == nil || participant.UserID == item.HostUserID {
		return false
	}

	if isPaidActivity(item) {
		switch participant.Status {
		case enum.ParticipantStatusConfirmed, enum.ParticipantStatusCheckedIn:
			return participant.PaidAt != nil || participant.PaymentTransactionID != nil
		default:
			return false
		}
	}

	switch participant.Status {
	case enum.ParticipantStatusApproved,
		enum.ParticipantStatusConfirmed,
		enum.ParticipantStatusCheckedIn:
		return true
	default:
		return false
	}
}

func countEligibleParticipantsForMinimum(
	item *model.Activity,
	participants []*model.ActivityParticipant,
) int {
	count := 0
	for _, participant := range participants {
		if participantEligibleForMinimum(item, participant) {
			count++
		}
	}
	return count
}

func minimumParticipants(item *model.Activity) int {
	if item == nil || item.MinParticipants == nil {
		return 0
	}
	if *item.MinParticipants < 0 {
		return 0
	}
	return *item.MinParticipants
}

func isLateParticipantCancellation(item *model.Activity, now time.Time) bool {
	if item == nil {
		return false
	}
	return !now.UTC().Before(item.RegistrationDeadline.UTC())
}
