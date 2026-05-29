package app

import (
	"context"
	"fmt"
	"math"
	"strings"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

const (
	fraudActionActivityCreate            = "ACTIVITY_CREATE"
	fraudActionActivityUpdate            = "ACTIVITY_UPDATE"
	fraudActionActivityPublish           = "ACTIVITY_PUBLISH"
	fraudActionActivityJoin              = "ACTIVITY_JOIN"
	fraudActionActivityInvite            = "ACTIVITY_INVITE"
	fraudActionActivityLeave             = "ACTIVITY_LEAVE"
	fraudActionActivityCancel            = "ACTIVITY_CANCEL"
	fraudActionActivityAttendanceCheckIn = "ACTIVITY_ATTENDANCE_CHECK_IN"

	fraudSubjectActivity            = "ACTIVITY"
	fraudSubjectActivityParticipant = "ACTIVITY_PARTICIPANT"
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

func (u *ActivityUseCase) SetFraudEvaluator(fraud port.FraudEvaluator) {
	u.fraud = fraud
}

func (u *JoinUseCase) SetFraudEvaluator(fraud port.FraudEvaluator) {
	u.fraud = fraud
}

func (u *AttendanceUseCase) SetFraudEvaluator(fraud port.FraudEvaluator) {
	u.fraud = fraud
}

func (u *ActivityUseCase) enforceActivityFraud(ctx context.Context, input port.FraudAssessmentInput) error {
	if u.fraud == nil {
		return nil
	}
	return enforceActivityFraudDecision(ctx, u.fraud, input)
}

func (u *JoinUseCase) enforceActivityFraud(ctx context.Context, input port.FraudAssessmentInput) error {
	if u.fraud == nil {
		return nil
	}
	return enforceActivityFraudDecision(ctx, u.fraud, input)
}

func (u *AttendanceUseCase) enforceActivityFraud(ctx context.Context, input port.FraudAssessmentInput) error {
	if u.fraud == nil {
		return nil
	}
	return enforceActivityFraudDecision(ctx, u.fraud, input)
}

func enforceActivityFraudDecision(
	ctx context.Context,
	fraud port.FraudEvaluator,
	input port.FraudAssessmentInput,
) error {
	signals := FraudSignalsFromContext(ctx)
	input.ClientIP = signals.ClientIP
	input.DeviceID = signals.DeviceID
	input.UserAgent = signals.UserAgent
	if input.Metadata == nil {
		input.Metadata = map[string]any{}
	}

	decision, err := fraud.AssessActivity(ctx, input)
	if err != nil {
		return fmt.Errorf("assess activity fraud: %w", err)
	}
	if decision == nil ||
		decision.ShadowMode ||
		decision.Decision == "" ||
		decision.Decision == port.FraudDecisionAllow {
		return nil
	}
	return ErrFraudRejected
}

func activityFraudInput(
	action string,
	actorUserID uuid.UUID,
	subjectID uuid.UUID,
	item *model.Activity,
	metadata map[string]any,
) port.FraudAssessmentInput {
	amountMinor := activityPriceAmountMinor(item)
	currency := activityFraudCurrency(item)
	return port.FraudAssessmentInput{
		Action:      action,
		ActorUserID: actorUserID,
		SubjectType: fraudSubjectActivity,
		SubjectID:   subjectID,
		AmountMinor: amountMinor,
		Currency:    currency,
		Metadata:    mergeFraudMetadata(activityFraudMetadata(item), metadata),
	}
}

func activityParticipantFraudInput(
	action string,
	actorUserID uuid.UUID,
	activityID uuid.UUID,
	item *model.Activity,
	idempotencyKey string,
	metadata map[string]any,
) port.FraudAssessmentInput {
	amountMinor := activityPriceAmountMinor(item)
	currency := activityFraudCurrency(item)
	return port.FraudAssessmentInput{
		Action:         action,
		ActorUserID:    actorUserID,
		SubjectType:    fraudSubjectActivityParticipant,
		SubjectID:      activityID,
		IdempotencyKey: strings.TrimSpace(idempotencyKey),
		AmountMinor:    amountMinor,
		Currency:       currency,
		Metadata:       mergeFraudMetadata(activityFraudMetadata(item), metadata),
	}
}

func activityFraudMetadata(item *model.Activity) map[string]any {
	if item == nil {
		return map[string]any{}
	}
	metadata := map[string]any{
		"hostUserId":                     item.HostUserID.String(),
		"status":                         string(item.Status),
		"moderationStatus":               string(item.ModerationStatus),
		"format":                         string(item.Format),
		"visibility":                     string(item.Visibility),
		"categorySlug":                   item.CategorySlug,
		"priceType":                      string(item.PriceType),
		"requiresAttendanceConfirmation": item.RequiresAttendanceConfirmation,
		"allowsParticipantInvites":       item.AllowsParticipantInvites,
	}
	if item.StartAt.IsZero() {
		metadata["startAt"] = ""
	} else {
		metadata["startAt"] = item.StartAt.UTC().Format(timeRFC3339)
	}
	if item.EndAt.IsZero() {
		metadata["endAt"] = ""
	} else {
		metadata["endAt"] = item.EndAt.UTC().Format(timeRFC3339)
	}
	if amount := activityPriceAmountMinor(item); amount != nil {
		metadata["priceMinor"] = *amount
		metadata["amountMinor"] = *amount
	}
	if currency := activityFraudCurrency(item); currency != "" {
		metadata["currency"] = currency
	}
	if item.CountryCode != nil {
		metadata["countryCode"] = *item.CountryCode
	}
	if item.CityID != nil {
		metadata["cityId"] = *item.CityID
	}
	if item.CityName != nil {
		metadata["cityName"] = *item.CityName
	}
	if item.MaxParticipants != nil {
		metadata["maxParticipants"] = *item.MaxParticipants
	}
	return metadata
}

func mergeFraudMetadata(base map[string]any, extra map[string]any) map[string]any {
	if base == nil {
		base = map[string]any{}
	}
	for key, value := range extra {
		if strings.TrimSpace(key) == "" {
			continue
		}
		base[key] = value
	}
	return base
}

func activityPriceAmountMinor(item *model.Activity) *int64 {
	if item == nil || item.PriceAmount == nil {
		return nil
	}
	return activityPriceAmountMinorFromParts(item.PriceType, item.PriceAmount)
}

func activityPriceAmountMinorFromParts(priceType enum.ActivityPriceType, amountValue *float64) *int64 {
	if amountValue == nil {
		return nil
	}
	if priceType != enum.ActivityPriceTypePaid && priceType != enum.ActivityPriceTypeDeposit {
		return nil
	}
	amount := int64(math.Round(*amountValue * 100))
	if amount <= 0 {
		return nil
	}
	return &amount
}

func activityFraudCurrency(item *model.Activity) string {
	if item == nil || item.Currency == nil {
		return ""
	}
	return strings.ToUpper(strings.TrimSpace(*item.Currency))
}

const timeRFC3339 = "2006-01-02T15:04:05Z07:00"
