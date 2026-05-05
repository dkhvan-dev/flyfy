package app

import "errors"

var (
	ErrPaymentNotFound             = errors.New("payment transaction not found")
	ErrInvalidPaymentID            = errors.New("invalid payment transaction id")
	ErrInvalidAmount               = errors.New("invalid payment amount")
	ErrInvalidActorUserID          = errors.New("invalid actor user id")
	ErrInvalidParentPayment        = errors.New("invalid parent payment transaction")
	ErrPaymentCurrencyMismatch     = errors.New("payment currency mismatch")
	ErrPaymentSubjectMismatch      = errors.New("payment subject mismatch")
	ErrPaymentAlreadyFinalized     = errors.New("payment transaction is already finalized")
	ErrPaymentAmountExceeded       = errors.New("payment amount exceeds available balance")
	ErrPaymentOperationUnsupported = errors.New("payment operation is unsupported for this transaction")
)
