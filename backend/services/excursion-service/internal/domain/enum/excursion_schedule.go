package enum

type ExcursionScheduleRecurrenceType string

const (
	ExcursionScheduleRecurrenceTypeNone   ExcursionScheduleRecurrenceType = "NONE"
	ExcursionScheduleRecurrenceTypeWeekly ExcursionScheduleRecurrenceType = "WEEKLY"
)

func (value ExcursionScheduleRecurrenceType) IsValid() bool {
	switch value {
	case ExcursionScheduleRecurrenceTypeNone, ExcursionScheduleRecurrenceTypeWeekly:
		return true
	default:
		return false
	}
}

type ExcursionScheduleSeriesStatus string

const (
	ExcursionScheduleSeriesStatusActive    ExcursionScheduleSeriesStatus = "ACTIVE"
	ExcursionScheduleSeriesStatusPaused    ExcursionScheduleSeriesStatus = "PAUSED"
	ExcursionScheduleSeriesStatusCancelled ExcursionScheduleSeriesStatus = "CANCELLED"
)

func (value ExcursionScheduleSeriesStatus) IsValid() bool {
	switch value {
	case ExcursionScheduleSeriesStatusActive,
		ExcursionScheduleSeriesStatusPaused,
		ExcursionScheduleSeriesStatusCancelled:
		return true
	default:
		return false
	}
}

type ExcursionScheduleSlotStatus string

const (
	ExcursionScheduleSlotStatusAvailable ExcursionScheduleSlotStatus = "AVAILABLE"
	ExcursionScheduleSlotStatusBooked    ExcursionScheduleSlotStatus = "BOOKED"
	ExcursionScheduleSlotStatusFull      ExcursionScheduleSlotStatus = "FULL"
	ExcursionScheduleSlotStatusClosed    ExcursionScheduleSlotStatus = "CLOSED"
	ExcursionScheduleSlotStatusCancelled ExcursionScheduleSlotStatus = "CANCELLED"
	ExcursionScheduleSlotStatusCompleted ExcursionScheduleSlotStatus = "COMPLETED"
)

func (value ExcursionScheduleSlotStatus) IsValid() bool {
	switch value {
	case ExcursionScheduleSlotStatusAvailable,
		ExcursionScheduleSlotStatusBooked,
		ExcursionScheduleSlotStatusFull,
		ExcursionScheduleSlotStatusClosed,
		ExcursionScheduleSlotStatusCancelled,
		ExcursionScheduleSlotStatusCompleted:
		return true
	default:
		return false
	}
}
