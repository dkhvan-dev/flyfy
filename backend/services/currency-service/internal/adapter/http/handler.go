package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"kz/inflap/backend/services/currency-service/internal/app"
)

type Handler struct {
	uc *app.ConverterUseCase
}

func NewHandler(uc *app.ConverterUseCase) *Handler {
	return &Handler{uc: uc}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /v1/currencies", h.ListCurrencies)
	mux.HandleFunc("GET /v1/exchange-rates/latest", h.GetLatestRates)
	mux.HandleFunc("POST /v1/currency/convert", h.Convert)
	mux.HandleFunc("GET /", h.NotFound)
	mux.HandleFunc("POST /", h.NotFound)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) NotFound(w http.ResponseWriter, _ *http.Request) {
	writeError(w, http.StatusNotFound, "route_not_found")
}

func (h *Handler) ListCurrencies(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"items": h.uc.ListCurrencies(),
	})
}

func (h *Handler) GetLatestRates(w http.ResponseWriter, r *http.Request) {
	base := r.URL.Query().Get("base")
	quotes := splitSymbols(r.URL.Query().Get("quotes"))
	if base == "" || len(quotes) == 0 {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}

	result, err := h.uc.LatestRates(r.Context(), base, quotes)
	if err != nil {
		writeAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"baseCurrency": result.BaseCurrency,
		"rates":        result.Rates,
		"rateAsOf":     result.AsOf,
		"provider":     result.Provider,
		"stale":        result.Stale,
	})
}

func (h *Handler) Convert(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	var req convertRequest
	decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, 16*1024))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}

	result, err := h.uc.Convert(r.Context(), app.ConvertInput{
		Amount:       req.Amount,
		FromCurrency: req.FromCurrency,
		ToCurrency:   req.ToCurrency,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, convertResponse{
		SourceAmount:    result.SourceAmount,
		SourceCurrency:  result.SourceCurrency,
		ConvertedAmount: result.ConvertedAmount,
		TargetCurrency:  result.TargetCurrency,
		Rate:            result.Rate,
		RateAsOf:        result.RateAsOf,
		Provider:        result.Provider,
		Stale:           result.Stale,
	})
}

type convertRequest struct {
	Amount       string `json:"amount"`
	FromCurrency string `json:"fromCurrency"`
	ToCurrency   string `json:"toCurrency"`
}

type convertResponse struct {
	SourceAmount    string `json:"sourceAmount"`
	SourceCurrency  string `json:"sourceCurrency"`
	ConvertedAmount string `json:"convertedAmount"`
	TargetCurrency  string `json:"targetCurrency"`
	Rate            string `json:"rate"`
	RateAsOf        any    `json:"rateAsOf"`
	Provider        string `json:"provider"`
	Stale           bool   `json:"stale"`
}

func splitSymbols(value string) []string {
	parts := strings.Split(value, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func writeAppError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, app.ErrInvalidAmount):
		writeError(w, http.StatusBadRequest, "invalid_amount")
	case errors.Is(err, app.ErrUnsupportedCurrency):
		writeError(w, http.StatusBadRequest, "unsupported_currency")
	case errors.Is(err, app.ErrRateUnavailable):
		writeError(w, http.StatusServiceUnavailable, "rate_unavailable")
	default:
		writeError(w, http.StatusInternalServerError, "internal_error")
	}
}

func writeError(w http.ResponseWriter, status int, code string) {
	writeJSON(w, status, map[string]string{"error": code})
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}
