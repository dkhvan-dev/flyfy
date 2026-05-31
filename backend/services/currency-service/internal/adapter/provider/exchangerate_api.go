package provider

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"sync"
	"time"

	"kz/inflap/backend/services/currency-service/internal/app"
)

type ExchangeRateAPIProvider struct {
	baseURL  string
	client   *http.Client
	cacheTTL time.Duration

	mu    sync.Mutex
	cache map[string]cachedRateTable
}

type cachedRateTable struct {
	value     app.RateTable
	expiresAt time.Time
}

func NewExchangeRateAPIProvider(baseURL string, client *http.Client, cacheTTL time.Duration) *ExchangeRateAPIProvider {
	baseURL = strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if baseURL == "" {
		baseURL = "https://open.er-api.com/v6/latest"
	}
	if client == nil {
		client = &http.Client{Timeout: 5 * time.Second}
	}
	if cacheTTL <= 0 {
		cacheTTL = time.Hour
	}
	return &ExchangeRateAPIProvider{
		baseURL:  baseURL,
		client:   client,
		cacheTTL: cacheTTL,
		cache:    map[string]cachedRateTable{},
	}
}

func (p *ExchangeRateAPIProvider) LatestRates(ctx context.Context, baseCurrency string, quoteCurrencies []string) (app.RateTable, error) {
	base := strings.ToUpper(strings.TrimSpace(baseCurrency))
	quotes := normalizeQuotes(quoteCurrencies)
	cacheKey := base + ":" + strings.Join(quotes, ",")

	if cached, ok := p.getCached(cacheKey); ok {
		return cached, nil
	}

	endpoint, err := url.Parse(p.baseURL + "/" + url.PathEscape(base))
	if err != nil {
		return app.RateTable{}, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint.String(), nil)
	if err != nil {
		return app.RateTable{}, err
	}

	resp, err := p.client.Do(req)
	if err != nil {
		return app.RateTable{}, err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return app.RateTable{}, fmt.Errorf("exchange rate api status: %d", resp.StatusCode)
	}

	var payload exchangeRateAPIResponse
	decoder := json.NewDecoder(resp.Body)
	decoder.UseNumber()
	if err := decoder.Decode(&payload); err != nil {
		return app.RateTable{}, err
	}
	if !strings.EqualFold(payload.Result, "success") {
		return app.RateTable{}, fmt.Errorf("exchange rate api result: %s", payload.Result)
	}

	rates := make(map[string]string, len(quotes))
	for _, quote := range quotes {
		if value, ok := payload.Rates[quote]; ok {
			rates[quote] = value.String()
		}
	}

	asOf := time.Now().UTC()
	if payload.TimeLastUpdateUTC != "" {
		if parsed, err := time.Parse(time.RFC1123Z, payload.TimeLastUpdateUTC); err == nil {
			asOf = parsed.UTC()
		}
	}

	table := app.RateTable{
		BaseCurrency: base,
		Rates:        rates,
		Provider:     "ExchangeRate-API",
		AsOf:         asOf,
		Stale:        false,
	}
	p.setCached(cacheKey, table)
	return table, nil
}

func (p *ExchangeRateAPIProvider) getCached(key string) (app.RateTable, bool) {
	p.mu.Lock()
	defer p.mu.Unlock()

	cached, ok := p.cache[key]
	if !ok || time.Now().After(cached.expiresAt) {
		return app.RateTable{}, false
	}
	return cached.value, true
}

func (p *ExchangeRateAPIProvider) setCached(key string, table app.RateTable) {
	p.mu.Lock()
	defer p.mu.Unlock()

	p.cache[key] = cachedRateTable{
		value:     table,
		expiresAt: time.Now().Add(p.cacheTTL),
	}
}

type exchangeRateAPIResponse struct {
	Result            string                 `json:"result"`
	BaseCode          string                 `json:"base_code"`
	TimeLastUpdateUTC string                 `json:"time_last_update_utc"`
	Rates             map[string]json.Number `json:"rates"`
}

func normalizeQuotes(values []string) []string {
	seen := map[string]struct{}{}
	result := make([]string, 0, len(values))
	for _, value := range values {
		code := strings.ToUpper(strings.TrimSpace(value))
		if code == "" {
			continue
		}
		if _, ok := seen[code]; ok {
			continue
		}
		seen[code] = struct{}{}
		result = append(result, code)
	}
	sort.Strings(result)
	return result
}
