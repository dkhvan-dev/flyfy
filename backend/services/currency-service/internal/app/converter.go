package app

import (
	"context"
	"errors"
	"fmt"
	"math/big"
	"sort"
	"strings"
	"time"
)

var (
	ErrInvalidAmount       = errors.New("invalid amount")
	ErrUnsupportedCurrency = errors.New("unsupported currency")
	ErrRateUnavailable     = errors.New("exchange rate unavailable")
)

type Currency struct {
	Code       string `json:"code"`
	Name       string `json:"name"`
	Symbol     string `json:"symbol"`
	MinorUnits int    `json:"minorUnits"`
}

type ConvertInput struct {
	Amount       string
	FromCurrency string
	ToCurrency   string
}

type ConversionResult struct {
	SourceAmount    string
	SourceCurrency  string
	ConvertedAmount string
	TargetCurrency  string
	Rate            string
	RateAsOf        time.Time
	Provider        string
	Stale           bool
}

type RateTable struct {
	BaseCurrency string
	Rates        map[string]string
	Provider     string
	AsOf         time.Time
	Stale        bool
}

type RateProvider interface {
	LatestRates(ctx context.Context, baseCurrency string, quoteCurrencies []string) (RateTable, error)
}

type ConverterUseCase struct {
	primary  RateProvider
	fallback RateProvider
}

func NewConverterUseCase(primary RateProvider, fallback RateProvider) *ConverterUseCase {
	return &ConverterUseCase{primary: primary, fallback: fallback}
}

func (uc *ConverterUseCase) ListCurrencies() []Currency {
	items := make([]Currency, 0, len(supportedCurrencies))
	for _, currency := range supportedCurrencies {
		items = append(items, currency)
	}
	sort.Slice(items, func(i, j int) bool {
		return items[i].Code < items[j].Code
	})
	return items
}

func (uc *ConverterUseCase) LatestRates(ctx context.Context, baseCurrency string, quoteCurrencies []string) (RateTable, error) {
	base, err := normalizeCurrency(baseCurrency)
	if err != nil {
		return RateTable{}, err
	}
	quotes := make([]string, 0, len(quoteCurrencies))
	for _, value := range quoteCurrencies {
		quote, err := normalizeCurrency(value)
		if err != nil {
			return RateTable{}, err
		}
		if quote != base {
			quotes = append(quotes, quote)
		}
	}
	if len(quotes) == 0 {
		return RateTable{
			BaseCurrency: base,
			Rates:        map[string]string{base: "1"},
			Provider:     "identity",
			AsOf:         time.Now().UTC(),
			Stale:        false,
		}, nil
	}
	return uc.latestRates(ctx, base, quotes)
}

func (uc *ConverterUseCase) Convert(ctx context.Context, input ConvertInput) (ConversionResult, error) {
	sourceCurrency, err := normalizeCurrency(input.FromCurrency)
	if err != nil {
		return ConversionResult{}, err
	}
	targetCurrency, err := normalizeCurrency(input.ToCurrency)
	if err != nil {
		return ConversionResult{}, err
	}

	amount, err := parseDecimal(input.Amount)
	if err != nil || amount.Sign() < 0 {
		return ConversionResult{}, ErrInvalidAmount
	}

	sourceInfo := supportedCurrencies[sourceCurrency]
	targetInfo := supportedCurrencies[targetCurrency]
	if sourceCurrency == targetCurrency {
		formatted := formatMoney(amount, sourceInfo.MinorUnits)
		return ConversionResult{
			SourceAmount:    formatted,
			SourceCurrency:  sourceCurrency,
			ConvertedAmount: formatted,
			TargetCurrency:  targetCurrency,
			Rate:            "1",
			RateAsOf:        time.Now().UTC(),
			Provider:        "identity",
			Stale:           false,
		}, nil
	}

	table, err := uc.latestRates(ctx, sourceCurrency, []string{targetCurrency})
	if err != nil {
		return ConversionResult{}, err
	}
	rateValue, ok := table.Rates[targetCurrency]
	if !ok {
		return ConversionResult{}, ErrRateUnavailable
	}
	rate, err := parseDecimal(rateValue)
	if err != nil || rate.Sign() <= 0 {
		return ConversionResult{}, ErrRateUnavailable
	}

	converted := new(big.Rat).Mul(amount, rate)
	return ConversionResult{
		SourceAmount:    formatMoney(amount, sourceInfo.MinorUnits),
		SourceCurrency:  sourceCurrency,
		ConvertedAmount: formatMoney(converted, targetInfo.MinorUnits),
		TargetCurrency:  targetCurrency,
		Rate:            formatRate(rate),
		RateAsOf:        table.AsOf.UTC(),
		Provider:        table.Provider,
		Stale:           table.Stale,
	}, nil
}

func (uc *ConverterUseCase) latestRates(ctx context.Context, base string, quotes []string) (RateTable, error) {
	if uc.primary != nil {
		table, err := uc.primary.LatestRates(ctx, base, quotes)
		if err == nil && hasAllRates(table, quotes) {
			return normalizeRateTable(table), nil
		}
	}
	if uc.fallback != nil {
		table, err := uc.fallback.LatestRates(ctx, base, quotes)
		if err == nil && hasAllRates(table, quotes) {
			table.Stale = true
			return normalizeRateTable(table), nil
		}
	}
	return RateTable{}, ErrRateUnavailable
}

func hasAllRates(table RateTable, quotes []string) bool {
	for _, quote := range quotes {
		if _, ok := table.Rates[quote]; !ok {
			return false
		}
	}
	return true
}

func normalizeRateTable(table RateTable) RateTable {
	table.BaseCurrency = strings.ToUpper(strings.TrimSpace(table.BaseCurrency))
	if table.Provider == "" {
		table.Provider = "unknown"
	}
	if table.AsOf.IsZero() {
		table.AsOf = time.Now().UTC()
	}
	normalized := make(map[string]string, len(table.Rates))
	for key, value := range table.Rates {
		normalized[strings.ToUpper(strings.TrimSpace(key))] = value
	}
	table.Rates = normalized
	return table
}

func normalizeCurrency(value string) (string, error) {
	code := strings.ToUpper(strings.TrimSpace(value))
	if _, ok := supportedCurrencies[code]; !ok {
		return "", ErrUnsupportedCurrency
	}
	return code, nil
}

func parseDecimal(value string) (*big.Rat, error) {
	normalized := strings.TrimSpace(value)
	if normalized == "" {
		return nil, ErrInvalidAmount
	}
	amount, ok := new(big.Rat).SetString(normalized)
	if !ok {
		return nil, ErrInvalidAmount
	}
	return amount, nil
}

func formatMoney(value *big.Rat, decimalPlaces int) string {
	if decimalPlaces < 0 {
		decimalPlaces = 2
	}
	return value.FloatString(decimalPlaces)
}

func formatRate(value *big.Rat) string {
	formatted := value.FloatString(18)
	formatted = strings.TrimRight(formatted, "0")
	formatted = strings.TrimRight(formatted, ".")
	if formatted == "" {
		return "0"
	}
	return formatted
}

func unsupportedCurrencyError(code string) error {
	return fmt.Errorf("%w: %s", ErrUnsupportedCurrency, strings.ToUpper(strings.TrimSpace(code)))
}
