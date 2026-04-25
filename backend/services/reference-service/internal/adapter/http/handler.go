package http

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/internal/transport/dto"
)

type Handler struct {
	uc *app.ReferenceUseCase
}

func NewHandler(uc *app.ReferenceUseCase) *Handler {
	return &Handler{uc: uc}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)

	mux.HandleFunc("GET /v1/countries", h.ListCountries)
	mux.HandleFunc("GET /v1/countries/search", h.SearchCountries)
	mux.HandleFunc("GET /v1/countries/{code}", h.GetCountry)
	mux.HandleFunc("GET /v1/countries/{code}/cities", h.ListCitiesByCountry)
	mux.HandleFunc("GET /v1/countries/{code}/currency", h.GetCurrencyByCountry)

	mux.HandleFunc("GET /v1/cities", h.ListCities)
	mux.HandleFunc("GET /v1/cities/search", h.SearchCities)
	mux.HandleFunc("GET /v1/cities/{id}", h.GetCity)

	mux.HandleFunc("GET /v1/currencies", h.ListCurrencies)
	mux.HandleFunc("GET /v1/currencies/search", h.SearchCurrencies)
	mux.HandleFunc("GET /v1/currencies/{code}", h.GetCurrency)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// --- Countries ---

func (h *Handler) ListCountries(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r)
	countries := h.uc.ListCountries()
	setCacheControl(w, 86400)
	writeJSON(w, http.StatusOK, dto.MapCountries(countries, lang))
}

func (h *Handler) SearchCountries(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r)
	query := r.URL.Query().Get("q")
	limit := parseLimit(r)
	if query == "" {
		writeJSON(w, http.StatusOK, []dto.CountryResponse{})
		return
	}
	countries := h.uc.SearchCountries(query, limit)
	writeJSON(w, http.StatusOK, dto.MapCountries(countries, lang))
}

func (h *Handler) GetCountry(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r)
	code := r.PathValue("code")
	country := h.uc.GetCountry(code)
	if country == nil {
		writeError(w, http.StatusNotFound, "country not found")
		return
	}

	cities := h.uc.ListCities(code)
	currency := h.uc.GetCurrency(country.CurrencyCode)

	resp := dto.CountryDetailResponse{
		Country: dto.MapCountry(*country, lang),
		Cities:  dto.MapCities(cities, lang),
	}
	if currency != nil {
		resp.Currency = dto.MapCurrency(*currency, lang)
	}

	setCacheControl(w, 86400)
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListCitiesByCountry(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r)
	code := r.PathValue("code")
	country := h.uc.GetCountry(code)
	if country == nil {
		writeError(w, http.StatusNotFound, "country not found")
		return
	}
	cities := h.uc.ListCities(code)
	setCacheControl(w, 86400)
	writeJSON(w, http.StatusOK, dto.MapCities(cities, lang))
}

func (h *Handler) GetCurrencyByCountry(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r)
	code := r.PathValue("code")
	currency := h.uc.GetCurrencyByCountry(code)
	if currency == nil {
		writeError(w, http.StatusNotFound, "currency not found for country")
		return
	}
	setCacheControl(w, 86400)
	writeJSON(w, http.StatusOK, dto.MapCurrency(*currency, lang))
}

// --- Cities ---

func (h *Handler) ListCities(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r)
	countryCode := r.URL.Query().Get("country")
	cities := h.uc.ListCities(countryCode)
	setCacheControl(w, 86400)
	writeJSON(w, http.StatusOK, dto.MapCities(cities, lang))
}

func (h *Handler) SearchCities(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r)
	query := r.URL.Query().Get("q")
	countryCode := r.URL.Query().Get("country")
	limit := parseLimit(r)
	if query == "" {
		writeJSON(w, http.StatusOK, []dto.CityResponse{})
		return
	}
	cities := h.uc.SearchCities(query, countryCode, limit)
	writeJSON(w, http.StatusOK, dto.MapCities(cities, lang))
}

func (h *Handler) GetCity(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r)
	id := r.PathValue("id")
	city := h.uc.GetCity(id)
	if city == nil {
		writeError(w, http.StatusNotFound, "city not found")
		return
	}
	setCacheControl(w, 86400)
	writeJSON(w, http.StatusOK, dto.MapCity(*city, lang))
}

// --- Currencies ---

func (h *Handler) ListCurrencies(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r)
	currencies := h.uc.ListCurrencies()
	setCacheControl(w, 86400)
	writeJSON(w, http.StatusOK, dto.MapCurrencies(currencies, lang))
}

func (h *Handler) SearchCurrencies(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r)
	query := r.URL.Query().Get("q")
	limit := parseLimit(r)
	if query == "" {
		writeJSON(w, http.StatusOK, []dto.CurrencyResponse{})
		return
	}
	currencies := h.uc.SearchCurrencies(query, limit)
	writeJSON(w, http.StatusOK, dto.MapCurrencies(currencies, lang))
}

func (h *Handler) GetCurrency(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r)
	code := r.PathValue("code")
	currency := h.uc.GetCurrency(code)
	if currency == nil {
		writeError(w, http.StatusNotFound, "currency not found")
		return
	}
	setCacheControl(w, 86400)
	writeJSON(w, http.StatusOK, dto.MapCurrency(*currency, lang))
}

// --- Helpers ---

func parseLang(r *http.Request) string {
	lang := strings.TrimSpace(r.URL.Query().Get("lang"))
	switch lang {
	case "ru", "kk":
		return lang
	default:
		return "en"
	}
}

func parseLimit(r *http.Request) int {
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit <= 0 || limit > 100 {
		return 20
	}
	return limit
}

func setCacheControl(w http.ResponseWriter, maxAge int) {
	w.Header().Set("Cache-Control", "public, max-age="+strconv.Itoa(maxAge))
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
