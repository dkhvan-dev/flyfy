package model

import (
	"errors"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
)

var (
	ErrInvalidPricingModel = errors.New("invalid activity pricing model")
)

type ActivityPricing struct {
	PriceType   enum.ActivityPriceType
	PriceAmount *float64
	Currency    *string
}

func NewActivityPricing(
	priceType enum.ActivityPriceType,
	priceAmount *float64,
	currency *string,
) (*ActivityPricing, error) {
	item := &ActivityPricing{
		PriceType:   priceType,
		PriceAmount: priceAmount,
		Currency:    NormalizeOptionalString(currency),
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

func (p *ActivityPricing) Validate() error {
	if !p.PriceType.IsValid() {
		return ErrInvalidPriceType
	}

	switch p.PriceType {
	case enum.ActivityPriceTypeFree:
		if p.PriceAmount != nil || p.Currency != nil {
			return ErrInvalidPrice
		}
	case enum.ActivityPriceTypePaid, enum.ActivityPriceTypeDeposit:
		if p.PriceAmount == nil || *p.PriceAmount < 0 {
			return ErrInvalidPrice
		}
		if p.Currency == nil || *p.Currency == "" {
			return ErrInvalidCurrency
		}
	default:
		return ErrInvalidPricingModel
	}

	return nil
}

func (p *ActivityPricing) IsFree() bool {
	return p.PriceType == enum.ActivityPriceTypeFree
}

func (p *ActivityPricing) IsPaid() bool {
	return p.PriceType == enum.ActivityPriceTypePaid || p.PriceType == enum.ActivityPriceTypeDeposit
}
