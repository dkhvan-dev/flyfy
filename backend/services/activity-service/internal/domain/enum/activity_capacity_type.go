package enum

type ActivityCapacityType string

const (
	ActivityCapacityTypeLimited   ActivityCapacityType = "LIMITED"
	ActivityCapacityTypeUnlimited ActivityCapacityType = "UNLIMITED"
)

func (v ActivityCapacityType) IsValid() bool {
	switch v {
	case ActivityCapacityTypeLimited, ActivityCapacityTypeUnlimited:
		return true
	default:
		return false
	}
}
