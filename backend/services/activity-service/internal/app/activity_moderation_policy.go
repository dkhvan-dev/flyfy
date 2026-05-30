package app

import (
	"context"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
)

const (
	moderationReasonExternalContact = "external_contact"
	moderationReasonHighPrice       = "high_price"
	moderationReasonBurstCreated    = "burst_created"
)

var externalContactPattern = regexp.MustCompile(`(?i)(whatsapp|telegram|t\.me/|instagram|@[\w.]{3,}|(?:\+?7|8)[\s\-]?\(?\d{3}\)?[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2})`)

type activityModerationAssessment struct {
	RiskScore   int
	ReasonCodes []string
}

type activityModerationSubject struct {
	HostUserID uuid.UUID

	Title       string
	Description string

	PriceType   enum.ActivityPriceType
	PriceAmount *float64
	Currency    *string

	IncludeBurstCreated bool
}

func (u *ActivityUseCase) assessCreateModeration(ctx context.Context, input CreateActivityInput) activityModerationAssessment {
	return u.assessActivityModeration(ctx, activityModerationSubject{
		HostUserID:          input.HostUserID,
		Title:               input.Title,
		Description:         input.Description,
		PriceType:           input.PriceType,
		PriceAmount:         input.PriceAmount,
		Currency:            input.Currency,
		IncludeBurstCreated: true,
	})
}

func (u *ActivityUseCase) assessActivityModeration(
	ctx context.Context,
	subject activityModerationSubject,
) activityModerationAssessment {
	assessment := activityModerationAssessment{}
	text := strings.TrimSpace(subject.Title + " " + subject.Description)
	if externalContactPattern.MatchString(text) {
		assessment.add(60, moderationReasonExternalContact)
	}
	if isHighRiskActivityPrice(subject.PriceType, subject.PriceAmount, subject.Currency) {
		assessment.add(25, moderationReasonHighPrice)
	}
	if subject.IncludeBurstCreated && u.policy != nil && subject.HostUserID != uuid.Nil {
		count, err := u.repo.CountActivitiesCreatedSince(ctx, subject.HostUserID, time.Now().UTC().Add(-1*time.Hour))
		if err == nil && count >= 2 {
			assessment.add(30, moderationReasonBurstCreated)
		}
	}
	if assessment.RiskScore > 100 {
		assessment.RiskScore = 100
	}
	return assessment
}

func (a *activityModerationAssessment) add(score int, reason string) {
	a.RiskScore += score
	a.ReasonCodes = append(a.ReasonCodes, reason)
}

func isHighRiskActivityPrice(priceType enum.ActivityPriceType, amount *float64, currency *string) bool {
	if priceType != enum.ActivityPriceTypePaid && priceType != enum.ActivityPriceTypeDeposit {
		return false
	}
	if amount == nil {
		return false
	}
	code := strings.ToUpper(strings.TrimSpace(valueOrEmpty(currency)))
	switch code {
	case "KZT", "":
		return *amount >= 100000
	case "USD":
		return *amount >= 200
	case "EUR":
		return *amount >= 200
	default:
		return *amount >= 100000
	}
}

func valueOrEmpty(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}
