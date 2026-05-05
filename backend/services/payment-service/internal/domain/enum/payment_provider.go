package enum

type PaymentProvider string

const (
	PaymentProviderMock PaymentProvider = "MOCK"
)

func (v PaymentProvider) IsValid() bool {
	switch v {
	case PaymentProviderMock:
		return true
	default:
		return false
	}
}
