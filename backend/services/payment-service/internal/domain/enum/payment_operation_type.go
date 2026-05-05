package enum

type PaymentOperationType string

const (
	PaymentOperationTypeAuthorize PaymentOperationType = "AUTHORIZE"
	PaymentOperationTypeCharge    PaymentOperationType = "CHARGE"
	PaymentOperationTypeCapture   PaymentOperationType = "CAPTURE"
	PaymentOperationTypeRefund    PaymentOperationType = "REFUND"
	PaymentOperationTypeVoid      PaymentOperationType = "VOID"
)

func (v PaymentOperationType) IsValid() bool {
	switch v {
	case PaymentOperationTypeAuthorize,
		PaymentOperationTypeCharge,
		PaymentOperationTypeCapture,
		PaymentOperationTypeRefund,
		PaymentOperationTypeVoid:
		return true
	default:
		return false
	}
}
