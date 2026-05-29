package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/anti-fraud-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/anti-fraud-service/internal/domain/port"
)

const (
	ActionAuthOTPRequest      = "AUTH_OTP_REQUEST"
	ActionAuthOTPVerify       = "AUTH_OTP_VERIFY"
	ActionAuthTokenRefresh    = "AUTH_TOKEN_REFRESH"
	ActionPaymentCharge       = "PAYMENT_CHARGE"
	ActionPaymentAuthorize    = "PAYMENT_AUTHORIZE"
	ActionPaymentCapture      = "PAYMENT_CAPTURE"
	ActionPaymentRefund       = "PAYMENT_REFUND"
	ActionPaymentVoid         = "PAYMENT_VOID"
	ActionFileUploadRequest   = "FILE_UPLOAD_REQUEST"
	ActionFileUploadComplete  = "FILE_UPLOAD_COMPLETE"
	ActionFileBind            = "FILE_BIND"
	ActionGuideApplication    = "GUIDE_APPLICATION"
	ActionGuideDocumentAttach = "GUIDE_DOCUMENT_ATTACH"

	ActionActivityCreate            = "ACTIVITY_CREATE"
	ActionActivityUpdate            = "ACTIVITY_UPDATE"
	ActionActivityPublish           = "ACTIVITY_PUBLISH"
	ActionActivityJoin              = "ACTIVITY_JOIN"
	ActionActivityInvite            = "ACTIVITY_INVITE"
	ActionActivityLeave             = "ACTIVITY_LEAVE"
	ActionActivityCancel            = "ACTIVITY_CANCEL"
	ActionActivityAttendanceCheckIn = "ACTIVITY_ATTENDANCE_CHECK_IN"
	ActionActivityMediaBind         = "ACTIVITY_MEDIA_BIND"

	ActionExcursionCreate              = "EXCURSION_CREATE"
	ActionExcursionUpdate              = "EXCURSION_UPDATE"
	ActionExcursionPublish             = "EXCURSION_PUBLISH"
	ActionExcursionPriceChange         = "EXCURSION_PRICE_CHANGE"
	ActionExcursionScheduleSlotCreate  = "EXCURSION_SCHEDULE_SLOT_CREATE"
	ActionExcursionOfferCreate         = "EXCURSION_OFFER_CREATE"
	ActionExcursionBookingCreate       = "EXCURSION_BOOKING_CREATE"
	ActionExcursionBookingGuestsUpdate = "EXCURSION_BOOKING_GUESTS_UPDATE"
	ActionExcursionBookingCancel       = "EXCURSION_BOOKING_CANCEL"
	ActionExcursionScheduleSlotCancel  = "EXCURSION_SCHEDULE_SLOT_CANCEL"
	ActionExcursionAttendanceCheckIn   = "EXCURSION_ATTENDANCE_CHECK_IN"
	ActionExcursionMediaBind           = "EXCURSION_MEDIA_BIND"
)

const (
	ReasonOTPPhoneVelocity       = "OTP_PHONE_VELOCITY"
	ReasonOTPIPVelocity          = "OTP_IP_VELOCITY"
	ReasonOTPDeviceVelocity      = "OTP_DEVICE_VELOCITY"
	ReasonAuthVerifyVelocity     = "AUTH_VERIFY_VELOCITY"
	ReasonRefreshVelocity        = "TOKEN_REFRESH_VELOCITY"
	ReasonHighPaymentAmount      = "HIGH_PAYMENT_AMOUNT"
	ReasonPaymentSubjectVelocity = "PAYMENT_SUBJECT_VELOCITY"
	ReasonUploadUserVelocity     = "UPLOAD_USER_VELOCITY"
	ReasonUploadIPVelocity       = "UPLOAD_IP_VELOCITY"
	ReasonSensitiveDocument      = "SENSITIVE_DOCUMENT"
	ReasonActivityCreateVelocity = "ACTIVITY_CREATE_VELOCITY"
	ReasonActivityJoinVelocity   = "ACTIVITY_JOIN_VELOCITY"
	ReasonActivityCancelVelocity = "ACTIVITY_CANCEL_VELOCITY"
	ReasonActivityHighRiskValue  = "ACTIVITY_HIGH_RISK_VALUE"
	ReasonAttendanceVelocity     = "ATTENDANCE_CHECK_IN_VELOCITY"

	ReasonExcursionPublishVelocity = "EXCURSION_PUBLISH_VELOCITY"
	ReasonExcursionBookingVelocity = "EXCURSION_BOOKING_VELOCITY"
	ReasonExcursionCancelVelocity  = "EXCURSION_CANCEL_VELOCITY"
	ReasonExcursionHighRiskValue   = "EXCURSION_HIGH_RISK_VALUE"
	ReasonHighPriceChange          = "HIGH_PRICE_CHANGE"
	ReasonUnverifiedGuidePublish   = "UNVERIFIED_GUIDE_PUBLISH"
)

type Policy struct {
	Version string

	ShadowMode bool
	Window     time.Duration

	OTPSendPhoneLimit     int
	OTPSendIPLimit        int
	OTPVerifyPhoneLimit   int
	OTPVerifyDeviceLimit  int
	TokenRefreshUserLimit int

	PaymentUserLimit        int
	HighPaymentAmountMinor  int64
	PaymentCurrency         string
	UploadUserLimit         int
	UploadIPLimit           int
	SensitiveDocumentReview bool

	ActivityCreateUserLimit       int
	ActivityJoinUserLimit         int
	ActivityCancellationUserLimit int
	ActivityAttendanceUserLimit   int
	ActivityHighRiskAmountMinor   int64

	ExcursionPublishUserLimit     int
	ExcursionBookingUserLimit     int
	ExcursionCancelUserLimit      int
	ExcursionHighRiskAmountMinor  int64
	HighPriceChangePercent        float64
	HighPriceChangeAmountMinor    int64
	RequireVerifiedGuideToPublish bool
}

func DefaultPolicy() Policy {
	return Policy{
		Version:                 "2026-05-29.v1",
		Window:                  time.Hour,
		OTPSendPhoneLimit:       5,
		OTPSendIPLimit:          25,
		OTPVerifyPhoneLimit:     8,
		OTPVerifyDeviceLimit:    12,
		TokenRefreshUserLimit:   120,
		PaymentUserLimit:        20,
		HighPaymentAmountMinor:  1_000_000,
		PaymentCurrency:         "KZT",
		UploadUserLimit:         60,
		UploadIPLimit:           250,
		SensitiveDocumentReview: true,

		ActivityCreateUserLimit:       10,
		ActivityJoinUserLimit:         30,
		ActivityCancellationUserLimit: 12,
		ActivityAttendanceUserLimit:   40,
		ActivityHighRiskAmountMinor:   500_000,

		ExcursionPublishUserLimit:     8,
		ExcursionBookingUserLimit:     20,
		ExcursionCancelUserLimit:      10,
		ExcursionHighRiskAmountMinor:  750_000,
		HighPriceChangePercent:        50,
		HighPriceChangeAmountMinor:    50_000,
		RequireVerifiedGuideToPublish: true,
	}
}

type RiskUseCase struct {
	repo   port.RiskRepository
	policy Policy
}

type AssessActionInput struct {
	Action      string
	ActorUserID *uuid.UUID
	SubjectType string
	SubjectID   *uuid.UUID

	SourceService  string
	IdempotencyKey string
	SignalHashes   map[string]string
	AmountMinor    *int64
	Currency       string
	Metadata       map[string]any
}

func NewRiskUseCase(repo port.RiskRepository, policy Policy) *RiskUseCase {
	return &RiskUseCase{
		repo:   repo,
		policy: normalizePolicy(policy),
	}
}

func (u *RiskUseCase) AssessAction(ctx context.Context, input AssessActionInput) (*model.RiskAssessment, error) {
	if u == nil || u.repo == nil {
		return nil, errors.New("risk use case is not configured")
	}

	now := time.Now().UTC()
	action := model.NormalizeCode(input.Action)
	if action == "" {
		return nil, errors.New("risk action is required")
	}

	event := &model.RiskEvent{
		ID:             uuid.New(),
		Action:         action,
		ActorUserID:    input.ActorUserID,
		SubjectType:    model.NormalizeCode(input.SubjectType),
		SubjectID:      input.SubjectID,
		SourceService:  strings.TrimSpace(input.SourceService),
		IdempotencyKey: strings.TrimSpace(input.IdempotencyKey),
		AmountMinor:    input.AmountMinor,
		Currency:       model.NormalizeCode(input.Currency),
		SignalHashes:   copyStringMap(input.SignalHashes),
		Metadata:       copyAnyMap(input.Metadata),
		CreatedAt:      now,
	}
	if event.SignalHashes == nil {
		event.SignalHashes = map[string]string{}
	}
	if event.Metadata == nil {
		event.Metadata = map[string]any{}
	}

	if err := u.repo.CreateEvent(ctx, event); err != nil {
		return nil, fmt.Errorf("create risk event: %w", err)
	}

	decision := model.RiskDecisionAllow
	score := 0
	reasons := make([]string, 0, 4)
	since := now.Add(-u.policy.Window)

	addReason := func(reason string, candidate model.RiskDecision, candidateScore int) {
		if !containsReason(reasons, reason) {
			reasons = append(reasons, reason)
		}
		if candidateScore > score {
			score = candidateScore
		}
		if decisionRank(candidate) > decisionRank(decision) {
			decision = candidate
		}
	}

	switch action {
	case ActionAuthOTPRequest:
		if event.SignalHashes["phone"] != "" {
			count, err := u.countBySignal(ctx, since, action, "phone", event.SignalHashes["phone"])
			if err != nil {
				return nil, err
			}
			if count >= u.policy.OTPSendPhoneLimit {
				addReason(ReasonOTPPhoneVelocity, model.RiskDecisionBlock, 95)
			}
		}
		if event.SignalHashes["ip"] != "" {
			count, err := u.countBySignal(ctx, since, action, "ip", event.SignalHashes["ip"])
			if err != nil {
				return nil, err
			}
			if count >= u.policy.OTPSendIPLimit {
				addReason(ReasonOTPIPVelocity, model.RiskDecisionBlock, 90)
			}
		}
	case ActionAuthOTPVerify:
		if event.SignalHashes["phone"] != "" {
			count, err := u.countBySignal(ctx, since, action, "phone", event.SignalHashes["phone"])
			if err != nil {
				return nil, err
			}
			if count >= u.policy.OTPVerifyPhoneLimit {
				addReason(ReasonAuthVerifyVelocity, model.RiskDecisionBlock, 92)
			}
		}
		if event.SignalHashes["device"] != "" {
			count, err := u.countBySignal(ctx, since, action, "device", event.SignalHashes["device"])
			if err != nil {
				return nil, err
			}
			if count >= u.policy.OTPVerifyDeviceLimit {
				addReason(ReasonOTPDeviceVelocity, model.RiskDecisionBlock, 88)
			}
		}
	case ActionAuthTokenRefresh:
		if event.ActorUserID != nil {
			count, err := u.countByActor(ctx, since, action, event.ActorUserID)
			if err != nil {
				return nil, err
			}
			if count >= u.policy.TokenRefreshUserLimit {
				addReason(ReasonRefreshVelocity, model.RiskDecisionReview, 70)
			}
		}
	case ActionPaymentCharge, ActionPaymentAuthorize, ActionPaymentCapture, ActionPaymentRefund, ActionPaymentVoid:
		if input.AmountMinor != nil &&
			*input.AmountMinor >= u.policy.HighPaymentAmountMinor &&
			(u.policy.PaymentCurrency == "" || event.Currency == u.policy.PaymentCurrency) {
			addReason(ReasonHighPaymentAmount, model.RiskDecisionReview, 65)
		}
		if event.ActorUserID != nil {
			count, err := u.countByActor(ctx, since, action, event.ActorUserID)
			if err != nil {
				return nil, err
			}
			if count >= u.policy.PaymentUserLimit {
				addReason(ReasonPaymentSubjectVelocity, model.RiskDecisionReview, 72)
			}
		}
	case ActionFileUploadRequest, ActionFileUploadComplete, ActionFileBind, ActionGuideDocumentAttach:
		if event.ActorUserID != nil {
			count, err := u.countByActor(ctx, since, action, event.ActorUserID)
			if err != nil {
				return nil, err
			}
			if count >= u.policy.UploadUserLimit {
				addReason(ReasonUploadUserVelocity, model.RiskDecisionReview, 75)
			}
		}
		if event.SignalHashes["ip"] != "" {
			count, err := u.countBySignal(ctx, since, action, "ip", event.SignalHashes["ip"])
			if err != nil {
				return nil, err
			}
			if count >= u.policy.UploadIPLimit {
				addReason(ReasonUploadIPVelocity, model.RiskDecisionReview, 70)
			}
		}
		if u.policy.SensitiveDocumentReview && isSensitiveDocument(event.Metadata) {
			addReason(ReasonSensitiveDocument, model.RiskDecisionReview, 55)
		}
	case ActionGuideApplication:
		if u.policy.SensitiveDocumentReview {
			addReason(ReasonSensitiveDocument, model.RiskDecisionReview, 55)
		}
	case ActionActivityCreate, ActionActivityUpdate, ActionActivityPublish:
		if action == ActionActivityCreate && event.ActorUserID != nil {
			count, err := u.countByActor(ctx, since, action, event.ActorUserID)
			if err != nil {
				return nil, err
			}
			if count >= u.policy.ActivityCreateUserLimit {
				addReason(ReasonActivityCreateVelocity, model.RiskDecisionReview, 72)
			}
		}
		if amountMinorForRisk(event) >= u.policy.ActivityHighRiskAmountMinor {
			addReason(ReasonActivityHighRiskValue, model.RiskDecisionReview, 62)
		}
	case ActionActivityJoin, ActionActivityInvite:
		if event.ActorUserID != nil {
			count, err := u.countByActor(ctx, since, action, event.ActorUserID)
			if err != nil {
				return nil, err
			}
			if count >= u.policy.ActivityJoinUserLimit {
				addReason(ReasonActivityJoinVelocity, model.RiskDecisionReview, 70)
			}
		}
	case ActionActivityLeave, ActionActivityCancel:
		if event.ActorUserID != nil {
			count, err := u.countByActor(ctx, since, action, event.ActorUserID)
			if err != nil {
				return nil, err
			}
			if count >= u.policy.ActivityCancellationUserLimit {
				addReason(ReasonActivityCancelVelocity, model.RiskDecisionReview, 72)
			}
		}
	case ActionActivityAttendanceCheckIn, ActionExcursionAttendanceCheckIn:
		if event.ActorUserID != nil {
			count, err := u.countByActor(ctx, since, action, event.ActorUserID)
			if err != nil {
				return nil, err
			}
			if count >= u.policy.ActivityAttendanceUserLimit {
				addReason(ReasonAttendanceVelocity, model.RiskDecisionReview, 68)
			}
		}
	case ActionActivityMediaBind:
		if u.policy.SensitiveDocumentReview && isSensitiveDocument(event.Metadata) {
			addReason(ReasonSensitiveDocument, model.RiskDecisionReview, 55)
		}
	case ActionExcursionCreate, ActionExcursionUpdate, ActionExcursionScheduleSlotCreate, ActionExcursionOfferCreate:
		if amountMinorForRisk(event) >= u.policy.ExcursionHighRiskAmountMinor {
			addReason(ReasonExcursionHighRiskValue, model.RiskDecisionReview, 64)
		}
	case ActionExcursionPublish:
		if event.ActorUserID != nil {
			count, err := u.countByActor(ctx, since, action, event.ActorUserID)
			if err != nil {
				return nil, err
			}
			if count >= u.policy.ExcursionPublishUserLimit {
				addReason(ReasonExcursionPublishVelocity, model.RiskDecisionReview, 74)
			}
		}
		if u.policy.RequireVerifiedGuideToPublish && !isVerifiedGuide(event.Metadata) {
			addReason(ReasonUnverifiedGuidePublish, model.RiskDecisionReview, 80)
		}
		if amountMinorForRisk(event) >= u.policy.ExcursionHighRiskAmountMinor {
			addReason(ReasonExcursionHighRiskValue, model.RiskDecisionReview, 64)
		}
	case ActionExcursionBookingCreate, ActionExcursionBookingGuestsUpdate:
		if event.ActorUserID != nil {
			count, err := u.countByActor(ctx, since, action, event.ActorUserID)
			if err != nil {
				return nil, err
			}
			if count >= u.policy.ExcursionBookingUserLimit {
				addReason(ReasonExcursionBookingVelocity, model.RiskDecisionReview, 72)
			}
		}
	case ActionExcursionBookingCancel, ActionExcursionScheduleSlotCancel:
		if event.ActorUserID != nil {
			count, err := u.countByActor(ctx, since, action, event.ActorUserID)
			if err != nil {
				return nil, err
			}
			if count >= u.policy.ExcursionCancelUserLimit {
				addReason(ReasonExcursionCancelVelocity, model.RiskDecisionReview, 72)
			}
		}
	case ActionExcursionPriceChange:
		if isHighPriceChange(event.Metadata, u.policy.HighPriceChangePercent, u.policy.HighPriceChangeAmountMinor) {
			addReason(ReasonHighPriceChange, model.RiskDecisionReview, 75)
		}
	case ActionExcursionMediaBind:
		if u.policy.SensitiveDocumentReview && isSensitiveDocument(event.Metadata) {
			addReason(ReasonSensitiveDocument, model.RiskDecisionReview, 55)
		}
	}

	assessment := &model.RiskAssessment{
		ID:            uuid.New(),
		EventID:       event.ID,
		Action:        event.Action,
		ActorUserID:   event.ActorUserID,
		SubjectType:   event.SubjectType,
		SubjectID:     event.SubjectID,
		Decision:      decision,
		RiskScore:     score,
		Reasons:       reasons,
		PolicyVersion: u.policy.Version,
		ShadowMode:    u.policy.ShadowMode,
		Metadata: map[string]any{
			"sourceService":  event.SourceService,
			"idempotencyKey": event.IdempotencyKey,
		},
		CreatedAt: now,
	}

	if err := u.repo.CreateAssessment(ctx, assessment); err != nil {
		return nil, fmt.Errorf("create risk assessment: %w", err)
	}

	return assessment, nil
}

func (u *RiskUseCase) countBySignal(ctx context.Context, since time.Time, action, signalKey, signalHash string) (int, error) {
	count, err := u.repo.CountEvents(ctx, port.RiskEventFilter{
		Since:      since,
		Action:     action,
		SignalKey:  signalKey,
		SignalHash: signalHash,
	})
	if err != nil {
		return 0, fmt.Errorf("count risk events by %s: %w", signalKey, err)
	}
	return count, nil
}

func (u *RiskUseCase) countByActor(ctx context.Context, since time.Time, action string, actorUserID *uuid.UUID) (int, error) {
	count, err := u.repo.CountEvents(ctx, port.RiskEventFilter{
		Since:       since,
		Action:      action,
		ActorUserID: actorUserID,
	})
	if err != nil {
		return 0, fmt.Errorf("count risk events by actor: %w", err)
	}
	return count, nil
}

func normalizePolicy(policy Policy) Policy {
	defaultPolicy := DefaultPolicy()
	if strings.TrimSpace(policy.Version) == "" {
		policy.Version = defaultPolicy.Version
	}
	if policy.Window <= 0 {
		policy.Window = defaultPolicy.Window
	}
	if policy.OTPSendPhoneLimit <= 0 {
		policy.OTPSendPhoneLimit = defaultPolicy.OTPSendPhoneLimit
	}
	if policy.OTPSendIPLimit <= 0 {
		policy.OTPSendIPLimit = defaultPolicy.OTPSendIPLimit
	}
	if policy.OTPVerifyPhoneLimit <= 0 {
		policy.OTPVerifyPhoneLimit = defaultPolicy.OTPVerifyPhoneLimit
	}
	if policy.OTPVerifyDeviceLimit <= 0 {
		policy.OTPVerifyDeviceLimit = defaultPolicy.OTPVerifyDeviceLimit
	}
	if policy.TokenRefreshUserLimit <= 0 {
		policy.TokenRefreshUserLimit = defaultPolicy.TokenRefreshUserLimit
	}
	if policy.PaymentUserLimit <= 0 {
		policy.PaymentUserLimit = defaultPolicy.PaymentUserLimit
	}
	if policy.HighPaymentAmountMinor <= 0 {
		policy.HighPaymentAmountMinor = defaultPolicy.HighPaymentAmountMinor
	}
	if strings.TrimSpace(policy.PaymentCurrency) == "" {
		policy.PaymentCurrency = defaultPolicy.PaymentCurrency
	}
	policy.PaymentCurrency = model.NormalizeCode(policy.PaymentCurrency)
	if policy.UploadUserLimit <= 0 {
		policy.UploadUserLimit = defaultPolicy.UploadUserLimit
	}
	if policy.UploadIPLimit <= 0 {
		policy.UploadIPLimit = defaultPolicy.UploadIPLimit
	}
	if policy.ActivityCreateUserLimit <= 0 {
		policy.ActivityCreateUserLimit = defaultPolicy.ActivityCreateUserLimit
	}
	if policy.ActivityJoinUserLimit <= 0 {
		policy.ActivityJoinUserLimit = defaultPolicy.ActivityJoinUserLimit
	}
	if policy.ActivityCancellationUserLimit <= 0 {
		policy.ActivityCancellationUserLimit = defaultPolicy.ActivityCancellationUserLimit
	}
	if policy.ActivityAttendanceUserLimit <= 0 {
		policy.ActivityAttendanceUserLimit = defaultPolicy.ActivityAttendanceUserLimit
	}
	if policy.ActivityHighRiskAmountMinor <= 0 {
		policy.ActivityHighRiskAmountMinor = defaultPolicy.ActivityHighRiskAmountMinor
	}
	if policy.ExcursionPublishUserLimit <= 0 {
		policy.ExcursionPublishUserLimit = defaultPolicy.ExcursionPublishUserLimit
	}
	if policy.ExcursionBookingUserLimit <= 0 {
		policy.ExcursionBookingUserLimit = defaultPolicy.ExcursionBookingUserLimit
	}
	if policy.ExcursionCancelUserLimit <= 0 {
		policy.ExcursionCancelUserLimit = defaultPolicy.ExcursionCancelUserLimit
	}
	if policy.ExcursionHighRiskAmountMinor <= 0 {
		policy.ExcursionHighRiskAmountMinor = defaultPolicy.ExcursionHighRiskAmountMinor
	}
	if policy.HighPriceChangePercent <= 0 {
		policy.HighPriceChangePercent = defaultPolicy.HighPriceChangePercent
	}
	if policy.HighPriceChangeAmountMinor <= 0 {
		policy.HighPriceChangeAmountMinor = defaultPolicy.HighPriceChangeAmountMinor
	}
	return policy
}

func decisionRank(decision model.RiskDecision) int {
	switch decision {
	case model.RiskDecisionBlock:
		return 4
	case model.RiskDecisionChallenge:
		return 3
	case model.RiskDecisionReview:
		return 2
	case model.RiskDecisionAllow:
		return 1
	default:
		return 0
	}
}

func isSensitiveDocument(metadata map[string]any) bool {
	for _, key := range []string{"purpose", "bindingPurpose", "documentType"} {
		value, ok := metadata[key]
		if !ok {
			continue
		}
		text := model.NormalizeCode(fmt.Sprint(value))
		if strings.Contains(text, "GUIDE") ||
			strings.Contains(text, "DOCUMENT") ||
			strings.Contains(text, "PASSPORT") ||
			strings.Contains(text, "LICENSE") ||
			strings.Contains(text, "VERIFICATION") {
			return true
		}
	}
	return false
}

func isVerifiedGuide(metadata map[string]any) bool {
	value, ok := metadata["guideVerificationStatus"]
	if !ok {
		return false
	}
	text := model.NormalizeCode(fmt.Sprint(value))
	return text == "VERIFIED" || text == "APPROVED" || text == "ACTIVE"
}

func priceMinorFromMetadata(metadata map[string]any) int64 {
	for _, key := range []string{"priceMinor", "amountMinor", "newPriceMinor"} {
		if value, ok := metadata[key]; ok {
			if amount, ok := numericInt64(value); ok {
				return amount
			}
		}
	}
	return 0
}

func amountMinorForRisk(event *model.RiskEvent) int64 {
	if event == nil {
		return 0
	}
	if event.AmountMinor != nil && *event.AmountMinor > 0 {
		return *event.AmountMinor
	}
	return priceMinorFromMetadata(event.Metadata)
}

func isHighPriceChange(metadata map[string]any, thresholdPercent float64, thresholdAmountMinor int64) bool {
	oldPrice, oldOK := numericInt64(metadata["oldPriceMinor"])
	newPrice, newOK := numericInt64(metadata["newPriceMinor"])
	if !oldOK || !newOK || oldPrice <= 0 || newPrice <= oldPrice {
		return false
	}

	diff := newPrice - oldPrice
	if diff < thresholdAmountMinor {
		return false
	}

	changePercent := (float64(diff) / float64(oldPrice)) * 100
	return changePercent >= thresholdPercent
}

func numericInt64(value any) (int64, bool) {
	switch v := value.(type) {
	case int64:
		return v, true
	case int:
		return int64(v), true
	case int32:
		return int64(v), true
	case float64:
		return int64(v), true
	case float32:
		return int64(v), true
	case string:
		if strings.TrimSpace(v) == "" {
			return 0, false
		}
		var parsed int64
		if _, err := fmt.Sscan(strings.TrimSpace(v), &parsed); err != nil {
			return 0, false
		}
		return parsed, true
	default:
		return 0, false
	}
}

func containsReason(reasons []string, want string) bool {
	for _, reason := range reasons {
		if reason == want {
			return true
		}
	}
	return false
}

func copyStringMap(in map[string]string) map[string]string {
	if in == nil {
		return nil
	}
	out := make(map[string]string, len(in))
	for key, value := range in {
		key = strings.TrimSpace(key)
		value = strings.TrimSpace(value)
		if key == "" || value == "" {
			continue
		}
		out[key] = value
	}
	return out
}

func copyAnyMap(in map[string]any) map[string]any {
	if in == nil {
		return nil
	}
	out := make(map[string]any, len(in))
	for key, value := range in {
		if strings.TrimSpace(key) == "" {
			continue
		}
		out[key] = value
	}
	return out
}
