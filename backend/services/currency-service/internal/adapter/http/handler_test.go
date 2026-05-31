package http

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"kz/inflap/backend/services/currency-service/internal/app"
)

func TestConvertEndpointReturnsIndicativeConversion(t *testing.T) {
	uc := app.NewConverterUseCase(app.NewSeedRateProvider(
		time.Date(2026, 5, 31, 0, 0, 0, 0, time.UTC),
	), nil)
	handler := NewHandler(uc)
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{
		"amount": "15000",
		"fromCurrency": "KZT",
		"toCurrency": "USD"
	}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/currency/convert", body)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body=%s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if payload["sourceCurrency"] != "KZT" {
		t.Fatalf("sourceCurrency = %v, want KZT", payload["sourceCurrency"])
	}
	if payload["targetCurrency"] != "USD" {
		t.Fatalf("targetCurrency = %v, want USD", payload["targetCurrency"])
	}
	if payload["convertedAmount"] != "29.59" {
		t.Fatalf("convertedAmount = %v, want 29.59", payload["convertedAmount"])
	}
	if payload["stale"] != true {
		t.Fatalf("stale = %v, want true for seed fallback", payload["stale"])
	}
}
