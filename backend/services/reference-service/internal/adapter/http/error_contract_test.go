package http

import (
	"encoding/json"
	stdhttp "net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/data"
	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/internal/app"
)

type errorContractResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    string `json:"code"`
	Kind    string `json:"kind"`
}

func TestParseErrorLangUsesQueryThenAcceptLanguageThenRussianFallback(t *testing.T) {
	tests := []struct {
		name           string
		target         string
		acceptLanguage string
		want           string
	}{
		{
			name:           "query parameter has priority",
			target:         "/v1/countries/ZZ?lang=kk",
			acceptLanguage: "en-US,en;q=0.9",
			want:           "kk",
		},
		{
			name:           "accept language supports english region",
			target:         "/v1/countries/ZZ",
			acceptLanguage: "en-US,en;q=0.9",
			want:           "en",
		},
		{
			name:           "accept language supports kazakh region",
			target:         "/v1/countries/ZZ",
			acceptLanguage: "kk-KZ,kk;q=0.9",
			want:           "kk",
		},
		{
			name:           "unsupported query falls back to accept language",
			target:         "/v1/countries/ZZ?lang=de",
			acceptLanguage: "en",
			want:           "en",
		},
		{
			name:           "unsupported accept language falls back to russian",
			target:         "/v1/countries/ZZ",
			acceptLanguage: "fr-FR,fr;q=0.9",
			want:           "ru",
		},
		{
			name:   "empty locale falls back to russian",
			target: "/v1/countries/ZZ",
			want:   "ru",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(stdhttp.MethodGet, tt.target, nil)
			if tt.acceptLanguage != "" {
				req.Header.Set("Accept-Language", tt.acceptLanguage)
			}

			if got := parseErrorLang(req); got != tt.want {
				t.Fatalf("parseErrorLang() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestHandlerKeepsSuccessfulDTOsDefaultingToEnglish(t *testing.T) {
	handler := newTestHandler(t)
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(stdhttp.MethodGet, "/v1/countries/KZ", nil)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != stdhttp.StatusOK {
		t.Fatalf("status = %d, want %d; body = %s", rec.Code, stdhttp.StatusOK, rec.Body.String())
	}

	var got struct {
		Country struct {
			Name string `json:"name"`
		} `json:"country"`
	}
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode country response: %v; body = %s", err, rec.Body.String())
	}
	if got.Country.Name != "Kazakhstan" {
		t.Fatalf("country name = %q, want default English name", got.Country.Name)
	}
}

func TestHandlerWritesBusinessErrorContract(t *testing.T) {
	handler := newTestHandler(t)
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	tests := []struct {
		name           string
		target         string
		acceptLanguage string
		wantStatus     int
		want           errorContractResponse
	}{
		{
			name:       "country not found uses kazakh from query",
			target:     "/v1/countries/ZZ?lang=kk",
			wantStatus: stdhttp.StatusNotFound,
			want: errorContractResponse{
				Error:   "Ел табылмады",
				Message: "Көрсетілген код бойынша ел табылмады.",
				Code:    "reference.country_not_found",
				Kind:    "business",
			},
		},
		{
			name:           "city not found uses english from accept language",
			target:         "/v1/cities/missing-city",
			acceptLanguage: "en-US,en;q=0.9",
			wantStatus:     stdhttp.StatusNotFound,
			want: errorContractResponse{
				Error:   "City not found",
				Message: "No city found for the requested id.",
				Code:    "reference.city_not_found",
				Kind:    "business",
			},
		},
		{
			name:       "currency not found falls back to russian",
			target:     "/v1/currencies/ZZZ",
			wantStatus: stdhttp.StatusNotFound,
			want: errorContractResponse{
				Error:   "Валюта не найдена",
				Message: "Валюта с указанным кодом не найдена.",
				Code:    "reference.currency_not_found",
				Kind:    "business",
			},
		},
		{
			name:           "currency for country not found is separated from currency lookup",
			target:         "/v1/countries/ZZ/currency",
			acceptLanguage: "en",
			wantStatus:     stdhttp.StatusNotFound,
			want: errorContractResponse{
				Error:   "Currency for country not found",
				Message: "No currency found for the requested country.",
				Code:    "reference.currency_for_country_not_found",
				Kind:    "business",
			},
		},
		{
			name:           "route not found has own code",
			target:         "/v1/unknown",
			acceptLanguage: "en",
			wantStatus:     stdhttp.StatusNotFound,
			want: errorContractResponse{
				Error:   "Route not found",
				Message: "The requested reference route does not exist.",
				Code:    "reference.route_not_found",
				Kind:    "business",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(stdhttp.MethodGet, tt.target, nil)
			if tt.acceptLanguage != "" {
				req.Header.Set("Accept-Language", tt.acceptLanguage)
			}
			rec := httptest.NewRecorder()

			mux.ServeHTTP(rec, req)

			if rec.Code != tt.wantStatus {
				t.Fatalf("status = %d, want %d; body = %s", rec.Code, tt.wantStatus, rec.Body.String())
			}

			got := decodeErrorContract(t, rec)
			if got != tt.want {
				t.Fatalf("error contract = %#v, want %#v", got, tt.want)
			}
		})
	}
}

func TestWriteErrorHidesTechnicalDetails(t *testing.T) {
	rec := httptest.NewRecorder()

	writeError(rec, stdhttp.StatusInternalServerError, "sql: password=secret")

	if rec.Code != stdhttp.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", rec.Code, stdhttp.StatusInternalServerError)
	}

	got := decodeErrorContract(t, rec)
	want := errorContractResponse{
		Error:   "Техническая ошибка",
		Message: "На сервере возникла проблема. Попробуйте позже.",
		Code:    "reference.technical",
		Kind:    "technical",
	}
	if got != want {
		t.Fatalf("error contract = %#v, want %#v", got, want)
	}
	if strings.Contains(rec.Body.String(), "secret") || strings.Contains(rec.Body.String(), "sql") {
		t.Fatalf("technical response leaked raw error: %s", rec.Body.String())
	}
}

func TestUnknownErrorCodeFallsBackToTechnicalContract(t *testing.T) {
	rec := httptest.NewRecorder()

	writeErrorResponse(rec, stdhttp.StatusInternalServerError, "reference.unexpected", errorKindBusiness, "en")

	got := decodeErrorContract(t, rec)
	want := errorContractResponse{
		Error:   "Technical error",
		Message: "A server problem occurred. Please try again later.",
		Code:    "reference.technical",
		Kind:    "technical",
	}
	if got != want {
		t.Fatalf("error contract = %#v, want %#v", got, want)
	}
}

func TestRecoverPanicHidesPanicDetails(t *testing.T) {
	req := httptest.NewRequest(stdhttp.MethodGet, "/panic?lang=en", nil)
	rec := httptest.NewRecorder()
	next := stdhttp.HandlerFunc(func(stdhttp.ResponseWriter, *stdhttp.Request) {
		panic("database password=secret")
	})

	recoverPanic(next).ServeHTTP(rec, req)

	if rec.Code != stdhttp.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", rec.Code, stdhttp.StatusInternalServerError)
	}

	got := decodeErrorContract(t, rec)
	want := errorContractResponse{
		Error:   "Technical error",
		Message: "A server problem occurred. Please try again later.",
		Code:    "reference.technical",
		Kind:    "technical",
	}
	if got != want {
		t.Fatalf("error contract = %#v, want %#v", got, want)
	}
	if strings.Contains(rec.Body.String(), "secret") || strings.Contains(rec.Body.String(), "password") {
		t.Fatalf("panic response leaked raw error: %s", rec.Body.String())
	}
}

func newTestHandler(t *testing.T) *Handler {
	t.Helper()

	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	return NewHandler(app.NewReferenceUseCase(repo))
}

func decodeErrorContract(t *testing.T, rec *httptest.ResponseRecorder) errorContractResponse {
	t.Helper()

	var got errorContractResponse
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode error contract: %v; body = %s", err, rec.Body.String())
	}
	return got
}
