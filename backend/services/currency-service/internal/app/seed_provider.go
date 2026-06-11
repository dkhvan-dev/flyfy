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
	"ARS": "0.332139",
	"AUD": "331",
	"AZN": "298",
	"BRL": "91",
	"BYN": "163.934426",
	"CAD": "371",
	"CHF": "556",
	"CNY": "70",
	"CUP": "19.293473",
	"CZK": "22.421022",
	"DKK": "73.078047",
	"EGP": "8.774624",
	"EUR": "580",
	"GBP": "681",
	"GEL": "187",
	"HKD": "65",
	"IDR": "0.031",
	"INR": "5.93",
	"ISK": "3.789946",
	"JPY": "3.53",
	"KES": "3.588512",
	"KGS": "5.80",
	"KRW": "0.37",
	"KZT": "1",
	"LKR": "1.445952",
	"MAD": "50.740816",
	"MDL": "26.87233",
	"MNT": "0.129765",
	"MVR": "29.974222",
	"MXN": "26.831232",
	"MYR": "120",
	"NZD": "306",
	"PHP": "7.643098",
	"PLN": "136",
	"RSD": "4.64697",
	"RUB": "6.4",
	"SCR": "31.91727",
	"SEK": "50.200803",
	"SGD": "392",
	"THB": "15.6",
	"TJS": "48",
	"TMT": "145",
	"TRY": "12.4",
	"TZS": "0.178301",
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
