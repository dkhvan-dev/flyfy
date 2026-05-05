package enum

type PaymentStatus string

const (
	PaymentStatusPending   PaymentStatus = "PENDING"
	PaymentStatusSucceeded PaymentStatus = "SUCCEEDED"
	PaymentStatusFailed    PaymentStatus = "FAILED"
	PaymentStatusCancelled PaymentStatus = "CANCELLED"
)

func (v PaymentStatus) IsValid() bool {
	switch v {
	case PaymentStatusPending,
		PaymentStatusSucceeded,
		PaymentStatusFailed,
		PaymentStatusCancelled:
		return true
	default:
		return false
	}
}
