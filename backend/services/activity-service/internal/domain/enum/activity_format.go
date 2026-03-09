package enum

type ActivityFormat string

const (
	ActivityFormatOffline ActivityFormat = "OFFLINE"
	ActivityFormatOnline  ActivityFormat = "ONLINE"
	ActivityFormatHybrid  ActivityFormat = "HYBRID"
)

func (v ActivityFormat) IsValid() bool {
	switch v {
	case ActivityFormatOffline, ActivityFormatOnline, ActivityFormatHybrid:
		return true
	default:
		return false
	}
}
