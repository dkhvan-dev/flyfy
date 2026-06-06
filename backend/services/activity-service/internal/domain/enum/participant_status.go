package enum

type ParticipantStatus string

const (
	ParticipantStatusInvited             ParticipantStatus = "INVITED"
	ParticipantStatusRequested           ParticipantStatus = "REQUESTED"
	ParticipantStatusApproved            ParticipantStatus = "APPROVED"
	ParticipantStatusWaitlisted          ParticipantStatus = "WAITLISTED"
	ParticipantStatusPendingPayment      ParticipantStatus = "PENDING_PAYMENT"
	ParticipantStatusConfirmed           ParticipantStatus = "CONFIRMED"
	ParticipantStatusDeclined            ParticipantStatus = "DECLINED"
	ParticipantStatusCancelled           ParticipantStatus = "CANCELLED"
	ParticipantStatusLateCancelled       ParticipantStatus = "LATE_CANCELLED"
	ParticipantStatusCancelledByActivity ParticipantStatus = "CANCELLED_BY_ACTIVITY"
	ParticipantStatusExpired             ParticipantStatus = "EXPIRED"
	ParticipantStatusCheckedIn           ParticipantStatus = "CHECKED_IN"
	ParticipantStatusNoShow              ParticipantStatus = "NO_SHOW"
)

func (v ParticipantStatus) IsValid() bool {
	switch v {
	case ParticipantStatusInvited,
		ParticipantStatusRequested,
		ParticipantStatusApproved,
		ParticipantStatusWaitlisted,
		ParticipantStatusPendingPayment,
		ParticipantStatusConfirmed,
		ParticipantStatusDeclined,
		ParticipantStatusCancelled,
		ParticipantStatusLateCancelled,
		ParticipantStatusCancelledByActivity,
		ParticipantStatusExpired,
		ParticipantStatusCheckedIn,
		ParticipantStatusNoShow:
		return true
	default:
		return false
	}
}

func (v ParticipantStatus) OccupiesSlot() bool {
	switch v {
	case ParticipantStatusApproved,
		ParticipantStatusPendingPayment,
		ParticipantStatusConfirmed,
		ParticipantStatusCheckedIn:
		return true
	default:
		return false
	}
}

func (v ParticipantStatus) IsActive() bool {
	switch v {
	case ParticipantStatusRequested,
		ParticipantStatusApproved,
		ParticipantStatusWaitlisted,
		ParticipantStatusPendingPayment,
		ParticipantStatusConfirmed,
		ParticipantStatusCheckedIn:
		return true
	default:
		return false
	}
}
