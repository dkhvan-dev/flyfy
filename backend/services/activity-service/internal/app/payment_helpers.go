package app

import (
	"fmt"
	"math"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

const (
	activityPaymentSubjectType = "ACTIVITY_PARTICIPANT"
	activityPaymentPurposeJoin = "ACTIVITY_JOIN"

	ParticipantEventTypePaymentAuthorizationSucceeded = "PAYMENT_AUTHORIZATION_SUCCEEDED"
	ParticipantEventTypePaymentCaptureSucceeded       = "PAYMENT_CAPTURE_SUCCEEDED"
	ParticipantEventTypePaymentRefundSucceeded        = "PAYMENT_REFUND_SUCCEEDED"
	ParticipantEventTypePaymentRefundDenied           = "PAYMENT_REFUND_DENIED"
	ParticipantEventTypePaymentAuthorizationVoided    = "PAYMENT_AUTHORIZATION_VOIDED"
)

func ensurePaymentGateway(gateway port.ActivityPaymentGateway) error {
	if gateway == nil {
		return ErrPaymentGatewayUnavailable
	}
	return nil
}

func activityPaymentAmountMinor(item *model.Activity) (int64, error) {
	if item == nil || item.PriceAmount == nil || *item.PriceAmount <= 0 {
		return 0, ErrPaymentAuthorizationFailed
	}
	amount := int64(math.Round(*item.PriceAmount * 100))
	if amount <= 0 {
		return 0, ErrPaymentAuthorizationFailed
	}
	return amount, nil
}

func activityCurrency(item *model.Activity) string {
	if item == nil || item.Currency == nil {
		return ""
	}
	return strings.ToUpper(strings.TrimSpace(*item.Currency))
}

func paymentSucceeded(tx *port.PaymentTransaction) bool {
	return tx != nil && tx.ID != uuid.Nil && tx.Status == port.PaymentStatusSucceeded
}

func paymentPending(tx *port.PaymentTransaction) bool {
	return tx != nil && tx.ID != uuid.Nil && tx.Status == port.PaymentStatusPending
}

func paymentIDFromParticipant(participant *model.ActivityParticipant) (uuid.UUID, error) {
	if participant == nil || participant.PaymentTransactionID == nil || *participant.PaymentTransactionID == uuid.Nil {
		return uuid.Nil, ErrPaymentGatewayUnavailable
	}
	return *participant.PaymentTransactionID, nil
}

func paymentMetadata(activity *model.Activity, participant *model.ActivityParticipant, policy string) map[string]any {
	metadata := map[string]any{
		"policy": policy,
	}
	if activity != nil {
		metadata["activityId"] = activity.ID.String()
		metadata["hostUserId"] = activity.HostUserID.String()
	}
	if participant != nil {
		metadata["participantId"] = participant.ID.String()
		metadata["participantUserId"] = participant.UserID.String()
	}
	return metadata
}

func paymentDescription(activity *model.Activity, participant *model.ActivityParticipant, operation string) *string {
	if activity == nil || participant == nil {
		return nil
	}
	value := fmt.Sprintf("%s for activity %s participant %s", operation, activity.ID, participant.ID)
	return &value
}

func paymentModeForParticipant(item *model.Activity, status enum.ParticipantStatus) *string {
	if !isPaidActivity(item) {
		return nil
	}

	var value string
	switch status {
	case enum.ParticipantStatusPendingPayment:
		value = "authorization_pending"
	case enum.ParticipantStatusConfirmed:
		value = "authorized"
	default:
		return nil
	}
	return &value
}

func wrapPaymentStatusError(base error, tx *port.PaymentTransaction) error {
	if tx == nil {
		return base
	}
	if tx.Status == "" {
		return base
	}
	return fmt.Errorf("%w: status %s", base, tx.Status)
}
