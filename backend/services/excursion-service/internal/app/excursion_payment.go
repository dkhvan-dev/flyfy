package app

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

func (u *ExcursionUseCase) chargeExcursionBooking(ctx context.Context, booking *model.ExcursionBooking) error {
	if booking == nil || booking.ID == uuid.Nil {
		return model.ErrInvalidExcursionBookingID
	}
	if u.paymentGateway == nil || booking.TotalPriceAmount <= 0 {
		return nil
	}
	amountMinor := moneyMinor(booking.TotalPriceAmount)
	if amountMinor <= 0 {
		return nil
	}

	tx, err := u.paymentGateway.Charge(ctx, port.PaymentCreateInput{
		IdempotencyKey: excursionPaymentIdempotencyKey(booking, "charge"),
		SubjectType:    excursionPaymentSubjectType,
		SubjectID:      booking.ID,
		Purpose:        excursionPaymentPurposeBooking,
		PayerUserID:    booking.TouristUserID,
		AmountMinor:    amountMinor,
		Currency:       strings.ToUpper(strings.TrimSpace(booking.Currency)),
		Description:    excursionPaymentDescription(booking, "Charge"),
		Metadata:       excursionPaymentMetadata(booking, "booking_charge"),
	})
	if err != nil {
		return fmt.Errorf("%w: %v", ErrPaymentChargeFailed, err)
	}
	if !excursionPaymentSucceeded(tx) {
		return wrapExcursionPaymentStatusError(ErrPaymentChargeFailed, tx)
	}
	return nil
}

func (u *ExcursionUseCase) settleExcursionBookingGuestPayment(
	ctx context.Context,
	booking *model.ExcursionBooking,
	deltaAmount float64,
) error {
	if u.paymentGateway == nil || booking == nil || deltaAmount == 0 {
		return nil
	}
	amountMinor := moneyMinor(absMoney(deltaAmount))
	if amountMinor <= 0 {
		return nil
	}
	if deltaAmount > 0 {
		tx, err := u.paymentGateway.Charge(ctx, port.PaymentCreateInput{
			IdempotencyKey: excursionPaymentIdempotencyKey(booking, fmt.Sprintf("guest-charge-%d", amountMinor)),
			SubjectType:    excursionPaymentSubjectType,
			SubjectID:      booking.ID,
			Purpose:        excursionPaymentPurposeGuestEdit,
			PayerUserID:    booking.TouristUserID,
			AmountMinor:    amountMinor,
			Currency:       strings.ToUpper(strings.TrimSpace(booking.Currency)),
			Description:    excursionPaymentDescription(booking, "Guest adjustment charge"),
			Metadata:       excursionPaymentMetadata(booking, "guest_increase_charge"),
		})
		if err != nil {
			return fmt.Errorf("%w: %v", ErrPaymentChargeFailed, err)
		}
		if !excursionPaymentSucceeded(tx) {
			return wrapExcursionPaymentStatusError(ErrPaymentChargeFailed, tx)
		}
		return nil
	}
	_, err := u.refundExcursionBookingAmount(ctx, booking, amountMinor)
	return err
}

func (u *ExcursionUseCase) refundExcursionBookingAmount(ctx context.Context, booking *model.ExcursionBooking, amountMinor int64) (bool, error) {
	if u.paymentGateway == nil || booking == nil || amountMinor <= 0 {
		return false, nil
	}
	operationType := port.PaymentOperationTypeCharge
	status := port.PaymentStatusSucceeded
	transactions, err := u.paymentGateway.ListTransactions(ctx, port.PaymentTransactionFilter{
		SubjectType:   excursionPaymentSubjectType,
		SubjectID:     &booking.ID,
		OperationType: &operationType,
		Status:        &status,
		Limit:         100,
	})
	if err != nil {
		return false, fmt.Errorf("%w: %v", ErrPaymentRefundFailed, err)
	}
	remaining := amountMinor
	for _, tx := range transactions {
		if tx == nil || tx.ID == uuid.Nil || !excursionPaymentSucceeded(tx) || tx.AmountMinor <= 0 {
			continue
		}
		part := tx.AmountMinor
		if part > remaining {
			part = remaining
		}
		refundTx, refundErr := u.paymentGateway.Refund(ctx, port.PaymentChildInput{
			ParentTransactionID: tx.ID,
			IdempotencyKey:      excursionPaymentIdempotencyKey(booking, fmt.Sprintf("refund-%s-%d", tx.ID, part)),
			AmountMinor:         &part,
			Description:         excursionPaymentDescription(booking, "Refund"),
			Metadata:            excursionPaymentMetadata(booking, "booking_refund"),
		})
		if refundErr != nil {
			return false, fmt.Errorf("%w: %v", ErrPaymentRefundFailed, refundErr)
		}
		if !excursionPaymentSucceeded(refundTx) {
			return false, wrapExcursionPaymentStatusError(ErrPaymentRefundFailed, refundTx)
		}
		remaining -= part
		if remaining <= 0 {
			return true, nil
		}
	}
	return false, nil
}

func excursionBookingGuestQuoteStatus(deltaAmount float64, hasPaymentGateway bool) string {
	if deltaAmount == 0 {
		return excursionBookingGuestsStatusNoPaymentChange
	}
	if !hasPaymentGateway {
		return excursionBookingRefundStatusPendingPaymentIntegration
	}
	if deltaAmount > 0 {
		return excursionBookingGuestsStatusPaymentRequired
	}
	return excursionBookingGuestsStatusRefundAvailable
}

func excursionBookingCancellationQuoteStatus(amount float64, hasPaymentGateway bool) string {
	if amount <= 0 {
		return excursionBookingRefundStatusNotRefundable
	}
	if hasPaymentGateway {
		return excursionBookingRefundStatusAvailable
	}
	return excursionBookingRefundStatusPendingPaymentIntegration
}

func excursionPaymentSucceeded(tx *port.PaymentTransaction) bool {
	return tx != nil && tx.ID != uuid.Nil && tx.Status == port.PaymentStatusSucceeded
}

func excursionPaymentIdempotencyKey(booking *model.ExcursionBooking, suffix string) string {
	base := booking.ID.String()
	if booking.IdempotencyKey != nil && strings.TrimSpace(*booking.IdempotencyKey) != "" {
		base = strings.TrimSpace(*booking.IdempotencyKey)
	}
	return fmt.Sprintf("excursion_booking:%s:%s", base, strings.TrimSpace(suffix))
}

func excursionPaymentMetadata(booking *model.ExcursionBooking, policy string) map[string]any {
	metadata := map[string]any{
		"policy":    policy,
		"bookingId": booking.ID.String(),
	}
	if booking.ProductID != uuid.Nil {
		metadata["productId"] = booking.ProductID.String()
	}
	if booking.OfferID != uuid.Nil {
		metadata["offerId"] = booking.OfferID.String()
	}
	if booking.GuideUserID != uuid.Nil {
		metadata["guideUserId"] = booking.GuideUserID.String()
	}
	if booking.TouristUserID != uuid.Nil {
		metadata["touristUserId"] = booking.TouristUserID.String()
	}
	return metadata
}

func excursionPaymentDescription(booking *model.ExcursionBooking, operation string) *string {
	if booking == nil || booking.ID == uuid.Nil {
		return nil
	}
	value := fmt.Sprintf("%s for excursion booking %s", strings.TrimSpace(operation), booking.ID)
	return &value
}

func wrapExcursionPaymentStatusError(base error, tx *port.PaymentTransaction) error {
	if tx == nil || strings.TrimSpace(tx.Status) == "" {
		return base
	}
	return fmt.Errorf("%w: status %s", base, tx.Status)
}

func absMoney(value float64) float64 {
	if value < 0 {
		return -value
	}
	return value
}
