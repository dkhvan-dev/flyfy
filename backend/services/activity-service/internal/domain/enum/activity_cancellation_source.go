package enum

type ActivityCancellationSource string

const (
	ActivityCancellationSourceSystem        ActivityCancellationSource = "SYSTEM"
	ActivityCancellationSourceAdmin         ActivityCancellationSource = "ADMIN"
	ActivityCancellationSourceHost          ActivityCancellationSource = "HOST"
	ActivityCancellationSourcePaymentSystem ActivityCancellationSource = "PAYMENT_SYSTEM"
)

func (v ActivityCancellationSource) IsValid() bool {
	switch v {
	case ActivityCancellationSourceSystem,
		ActivityCancellationSourceAdmin,
		ActivityCancellationSourceHost,
		ActivityCancellationSourcePaymentSystem:
		return true
	default:
		return false
	}
}
