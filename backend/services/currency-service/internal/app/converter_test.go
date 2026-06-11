package app

import (
	"context"
	"errors"
	"testing"
	"time"
)

func TestConvertUsesProviderRateAndMarksResultFresh(t *testing.T) {
	asOf := time.Date(2026, 5, 31, 10, 0, 0, 0, time.UTC)
	uc := NewConverterUseCase(stubRateProvider{
		rates: RateTable{
			BaseCurrency: "KZT",
			Rates:        map[string]string{"USD": "0.00197"},
			Provider:     "test-provider",
			AsOf:         asOf,
			Stale:        false,
		},
	}, nil)

	result, err := uc.Convert(context.Background(), ConvertInput{
		Amount:       "15000",
		FromCurrency: "KZT",
		ToCurrency:   "USD",
	})
	if err != nil {
		t.Fatalf("Convert returned error: %v", err)
	}

	if result.SourceAmount != "15000.00" {
		t.Fatalf("source amount = %q, want 15000.00", result.SourceAmount)
	}
	if result.ConvertedAmount != "29.55" {
		t.Fatalf("converted amount = %q, want 29.55", result.ConvertedAmount)
	}
	if result.Rate != "0.00197" {
		t.Fatalf("rate = %q, want 0.00197", result.Rate)
	}
	if result.Provider != "test-provider" {
		t.Fatalf("provider = %q, want test-provider", result.Provider)
	}
	if result.Stale {
		t.Fatal("expected fresh provider result")
	}
	if !result.RateAsOf.Equal(asOf) {
		t.Fatalf("rate as of = %s, want %s", result.RateAsOf, asOf)
	}
}

func TestConvertFallsBackToSeedRatesWhenProviderFails(t *testing.T) {
	asOf := time.Date(2026, 5, 31, 0, 0, 0, 0, time.UTC)
	uc := NewConverterUseCase(
		stubRateProvider{err: errors.New("provider unavailable")},
		NewSeedRateProvider(asOf),
	)

	result, err := uc.Convert(context.Background(), ConvertInput{
		Amount:       "10",
		FromCurrency: "USD",
		ToCurrency:   "KZT",
	})
	if err != nil {
		t.Fatalf("Convert returned error: %v", err)
	}

	if result.ConvertedAmount != "5070.00" {
		t.Fatalf("converted amount = %q, want 5070.00", result.ConvertedAmount)
	}
	if result.Rate != "507" {
		t.Fatalf("rate = %q, want 507", result.Rate)
	}
	if result.Provider != "seed" {
		t.Fatalf("provider = %q, want seed", result.Provider)
	}
	if !result.Stale {
		t.Fatal("expected fallback result to be marked stale")
	}
	if !result.RateAsOf.Equal(asOf) {
		t.Fatalf("rate as of = %s, want %s", result.RateAsOf, asOf)
	}
}

func TestSeedFallbackSupportsReferenceTravelCurrencies(t *testing.T) {
	uc := NewConverterUseCase(nil, NewSeedRateProvider(time.Date(2026, 5, 31, 0, 0, 0, 0, time.UTC)))
	listed := map[string]bool{}
	for _, currency := range uc.ListCurrencies() {
		listed[currency.Code] = true
	}

	for _, code := range referenceTravelCurrencyCodes() {
		if !listed[code] {
			t.Fatalf("ListCurrencies missing %s", code)
		}

		_, err := uc.Convert(context.Background(), ConvertInput{
			Amount:       "1",
			FromCurrency: code,
			ToCurrency:   "KZT",
		})
		if err != nil {
			t.Fatalf("Convert(%s -> KZT) returned error: %v", code, err)
		}
	}
}

func TestConvertRejectsUnsupportedCurrency(t *testing.T) {
	uc := NewConverterUseCase(NewSeedRateProvider(time.Now()), nil)

	_, err := uc.Convert(context.Background(), ConvertInput{
		Amount:       "100",
		FromCurrency: "KZT",
		ToCurrency:   "XXX",
	})
	if !errors.Is(err, ErrUnsupportedCurrency) {
		t.Fatalf("error = %v, want ErrUnsupportedCurrency", err)
	}
}

func referenceTravelCurrencyCodes() []string {
	return []string{
		"AED",
		"AMD",
		"ARS",
		"AUD",
		"AZN",
		"BRL",
		"BYN",
		"CAD",
		"CHF",
		"CNY",
		"CUP",
		"CZK",
		"DKK",
		"EGP",
		"EUR",
		"GBP",
		"GEL",
		"IDR",
		"INR",
		"ISK",
		"JPY",
		"KES",
		"KGS",
		"KRW",
		"KZT",
		"LKR",
		"MAD",
		"MDL",
		"MNT",
		"MVR",
		"MXN",
		"MYR",
		"NZD",
		"PHP",
		"PLN",
		"RSD",
		"RUB",
		"SCR",
		"SEK",
		"SGD",
		"THB",
		"TJS",
		"TMT",
		"TRY",
		"TZS",
		"UAH",
		"USD",
		"UZS",
		"VND",
	}
}

type stubRateProvider struct {
	rates RateTable
	err   error
}

func (p stubRateProvider) LatestRates(
	context.Context,
	string,
	[]string,
) (RateTable, error) {
	return p.rates, p.err
}
