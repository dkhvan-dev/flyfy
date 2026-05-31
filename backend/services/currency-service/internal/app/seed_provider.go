package app

import (
	"context"
	"math/big"
	"time"
)

type SeedRateProvider struct {
	asOf time.Time
}

var seedKZTPerUnit = map[string]string{
	"AED": "138",
	"AMD": "1.31",
	"AUD": "331",
	"AZN": "298",
	"BRL": "91",
	"CAD": "371",
	"CHF": "556",
	"CNY": "70",
	"EUR": "580",
	"GBP": "681",
	"GEL": "187",
	"HKD": "65",
	"IDR": "0.031",
	"INR": "5.93",
	"JPY": "3.53",
	"KGS": "5.80",
	"KRW": "0.37",
	"KZT": "1",
	"MYR": "120",
	"NZD": "306",
	"PLN": "136",
	"RUB": "6.4",
	"SGD": "392",
	"THB": "15.6",
	"TJS": "48",
	"TMT": "145",
	"TRY": "12.4",
	"UAH": "12.2",
	"USD": "507",
	"UZS": "0.040",
	"VND": "0.0195",
}

func NewSeedRateProvider(asOf time.Time) *SeedRateProvider {
	if asOf.IsZero() {
		asOf = time.Date(2026, 5, 31, 0, 0, 0, 0, time.UTC)
	}
	return &SeedRateProvider{asOf: asOf.UTC()}
}

func (p *SeedRateProvider) LatestRates(_ context.Context, baseCurrency string, quoteCurrencies []string) (RateTable, error) {
	base, err := normalizeCurrency(baseCurrency)
	if err != nil {
		return RateTable{}, err
	}
	baseKZT, ok := seedKZTPerUnit[base]
	if !ok {
		return RateTable{}, unsupportedCurrencyError(base)
	}

	rates := make(map[string]string, len(quoteCurrencies))
	for _, quoteValue := range quoteCurrencies {
		quote, err := normalizeCurrency(quoteValue)
		if err != nil {
			return RateTable{}, err
		}
		quoteKZT, ok := seedKZTPerUnit[quote]
		if !ok {
			return RateTable{}, unsupportedCurrencyError(quote)
		}
		rate := new(big.Rat).Quo(mustSeedRat(baseKZT), mustSeedRat(quoteKZT))
		rates[quote] = formatRate(rate)
	}

	return RateTable{
		BaseCurrency: base,
		Rates:        rates,
		Provider:     "seed",
		AsOf:         p.asOf,
		Stale:        true,
	}, nil
}

func mustSeedRat(value string) *big.Rat {
	rat, ok := new(big.Rat).SetString(value)
	if !ok {
		panic("invalid seed rate: " + value)
	}
	return rat
}
