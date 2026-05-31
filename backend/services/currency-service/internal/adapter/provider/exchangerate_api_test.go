package provider

import (
	"bytes"
	"context"
	"io"
	"net/http"
	"testing"
	"time"
)

func TestExchangeRateAPIProviderParsesLatestRates(t *testing.T) {
	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.URL.Path != "/KZT" {
			t.Fatalf("path = %q, want /KZT", r.URL.Path)
		}
		return &http.Response{
			StatusCode: http.StatusOK,
			Header: http.Header{
				"Content-Type": []string{"application/json"},
			},
			Body: io.NopCloser(bytes.NewBufferString(`{
			"result": "success",
			"base_code": "KZT",
			"time_last_update_utc": "Sun, 31 May 2026 00:00:01 +0000",
			"rates": {
				"USD": 0.001972386587771203,
				"EUR": 0.001724137931034483
			}
		}`)),
		}, nil
	})

	provider := NewExchangeRateAPIProvider(
		"http://currency-provider.test",
		&http.Client{Transport: transport},
		time.Minute,
	)

	table, err := provider.LatestRates(
		context.Background(),
		"kzt",
		[]string{"usd", "eur"},
	)
	if err != nil {
		t.Fatalf("LatestRates returned error: %v", err)
	}

	if table.Provider != "ExchangeRate-API" {
		t.Fatalf("provider = %q, want ExchangeRate-API", table.Provider)
	}
	if table.BaseCurrency != "KZT" {
		t.Fatalf("base = %q, want KZT", table.BaseCurrency)
	}
	if table.Rates["USD"] != "0.001972386587771203" {
		t.Fatalf("USD rate = %q", table.Rates["USD"])
	}
	if table.Rates["EUR"] != "0.001724137931034483" {
		t.Fatalf("EUR rate = %q", table.Rates["EUR"])
	}
	if table.Stale {
		t.Fatal("provider result should be fresh")
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (fn roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return fn(r)
}
