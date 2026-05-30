package app

import (
	"context"
	"fmt"
	"math"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

const (
	fraudActionExcursionCreate              = "EXCURSION_CREATE"
	fraudActionExcursionUpdate              = "EXCURSION_UPDATE"
	fraudActionExcursionPublish             = "EXCURSION_PUBLISH"
	fraudActionExcursionPriceChange         = "EXCURSION_PRICE_CHANGE"
	fraudActionExcursionScheduleSlotCreate  = "EXCURSION_SCHEDULE_SLOT_CREATE"
	fraudActionExcursionScheduleSlotCancel  = "EXCURSION_SCHEDULE_SLOT_CANCEL"
	fraudActionExcursionBookingCreate       = "EXCURSION_BOOKING_CREATE"
	fraudActionExcursionBookingGuestsUpdate = "EXCURSION_BOOKING_GUESTS_UPDATE"
	fraudActionExcursionBookingCancel       = "EXCURSION_BOOKING_CANCEL"
	fraudActionExcursionAttendanceCheckIn   = "EXCURSION_ATTENDANCE_CHECK_IN"

	fraudSubjectExcursion            = "EXCURSION"
	fraudSubjectExcursionSchedule    = "EXCURSION_SCHEDULE"
	fraudSubjectExcursionBooking     = "EXCURSION_BOOKING"
	fraudSubjectExcursionProductCard = "EXCURSION_PRODUCT"
)

type FraudSignals struct {
	ClientIP  string
	DeviceID  string
	UserAgent string
}

type fraudSignalsContextKey struct{}

func WithFraudSignals(ctx context.Context, signals FraudSignals) context.Context {
	signals.ClientIP = strings.TrimSpace(signals.ClientIP)
	signals.DeviceID = strings.TrimSpace(signals.DeviceID)
	signals.UserAgent = strings.TrimSpace(signals.UserAgent)
	if signals.ClientIP == "" && signals.DeviceID == "" && signals.UserAgent == "" {
		return ctx
	}
	return context.WithValue(ctx, fraudSignalsContextKey{}, signals)
}

func FraudSignalsFromContext(ctx context.Context) FraudSignals {
	signals, _ := ctx.Value(fraudSignalsContextKey{}).(FraudSignals)
	return signals
}

func (u *ExcursionUseCase) WithFraudEvaluator(fraud port.FraudEvaluator) *ExcursionUseCase {
	u.fraud = fraud
	return u
}

func (u *ExcursionUseCase) enforceExcursionFraud(ctx context.Context, input port.FraudAssessmentInput) error {
	if u.fraud == nil {
		return nil
	}
	signals := FraudSignalsFromContext(ctx)
	input.ClientIP = signals.ClientIP
	input.DeviceID = signals.DeviceID
	input.UserAgent = signals.UserAgent
	if input.Metadata == nil {
		input.Metadata = map[string]any{}
	}

	decision, err := u.fraud.AssessExcursion(ctx, input)
	if err != nil {
		return fmt.Errorf("assess excursion fraud: %w", err)
	}
	if decision == nil ||
		decision.ShadowMode ||
		decision.Decision == "" ||
		decision.Decision == port.FraudDecisionAllow {
		return nil
	}
	return ErrFraudRejected
}

func excursionFraudInput(
	action string,
	actorUserID uuid.UUID,
	subjectType string,
	subjectID uuid.UUID,
	amountMinor *int64,
	currency string,
	metadata map[string]any,
) port.FraudAssessmentInput {
	return port.FraudAssessmentInput{
		Action:      action,
		ActorUserID: actorUserID,
		SubjectType: subjectType,
		SubjectID:   subjectID,
		AmountMinor: amountMinor,
		Currency:    strings.ToUpper(strings.TrimSpace(currency)),
		Metadata:    metadata,
	}
}

func excursionMetadata(item *model.Excursion, permission *port.GuideExcursionPermission) map[string]any {
	if item == nil {
		return map[string]any{}
	}
	metadata := map[string]any{
		"guideProfileId": item.GuideProfileID.String(),
		"guideUserId":    item.GuideUserID.String(),
		"status":         string(item.Status),
		"visibility":     string(item.Visibility),
		"categorySlug":   item.CategorySlug,
		"priceMinor":     moneyMinor(item.PriceAmount),
		"amountMinor":    moneyMinor(item.PriceAmount),
		"currency":       strings.ToUpper(strings.TrimSpace(item.Currency)),
		"maxGroupSize":   item.MaxGroupSize,
	}
	if item.CountryCode != nil {
		metadata["countryCode"] = *item.CountryCode
	}
	if item.CityName != nil {
		metadata["cityName"] = *item.CityName
	}
	if permission != nil {
		metadata["guideAllowed"] = permission.Allowed
		if permission.Allowed {
			metadata["guideVerificationStatus"] = "VERIFIED"
		} else {
			metadata["guideVerificationStatus"] = "REJECTED"
		}
	}
	return metadata
}

func bookingMetadata(booking *model.ExcursionBooking, extra map[string]any) map[string]any {
	metadata := map[string]any{}
	if booking != nil {
		metadata["productId"] = booking.ProductID.String()
		metadata["offerId"] = booking.OfferID.String()
		metadata["guideUserId"] = booking.GuideUserID.String()
		metadata["touristUserId"] = booking.TouristUserID.String()
		metadata["status"] = string(booking.Status)
		metadata["adults"] = booking.Adults
		metadata["children"] = booking.Children
		metadata["totalSeats"] = booking.TotalSeats
		metadata["priceMinor"] = moneyMinor(booking.TotalPriceAmount)
		metadata["amountMinor"] = moneyMinor(booking.TotalPriceAmount)
		metadata["currency"] = strings.ToUpper(strings.TrimSpace(booking.Currency))
		if booking.ScheduleSlotID != nil {
			metadata["scheduleSlotId"] = booking.ScheduleSlotID.String()
		}
		if !booking.ScheduledFor.IsZero() {
			metadata["scheduledFor"] = booking.ScheduledFor.UTC().Format(timeRFC3339)
		}
	}
	for key, value := range extra {
		if strings.TrimSpace(key) == "" {
			continue
		}
		metadata[key] = value
	}
	return metadata
}

func moneyMinor(amount float64) int64 {
	return int64(math.Round(amount * 100))
}

func moneyMinorPtr(amount float64) *int64 {
	value := moneyMinor(amount)
	if value <= 0 {
		return nil
	}
	return &value
}

const timeRFC3339 = "2006-01-02T15:04:05Z07:00"
