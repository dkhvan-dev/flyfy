package http

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/rs/zerolog"

	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/port"
)

// JWKSHandler serves the /.well-known/jwks.json endpoint.
type JWKSHandler struct {
	keyManager port.KeyManager
	logger     zerolog.Logger
}

func NewJWKSHandler(km port.KeyManager, logger zerolog.Logger) *JWKSHandler {
	return &JWKSHandler{
		keyManager: km,
		logger:     logger.With().Str("component", "jwks_http").Logger(),
	}
}

// Router returns an http.Handler with the JWKS and health endpoints.
func (h *JWKSHandler) Router() http.Handler {
	r := chi.NewRouter()

	r.Use(chimw.RequestID)
	r.Use(chimw.RealIP)
	r.Use(chimw.Recoverer)
	r.Use(chimw.Timeout(5 * time.Second))
	r.Use(cacheControl(300)) // Cache JWKS for 5 minutes

	r.Get("/.well-known/jwks.json", h.handleJWKS)
	r.Get("/health", h.handleHealth)
	r.Get("/ready", h.handleReady)

	return r
}

func (h *JWKSHandler) handleJWKS(w http.ResponseWriter, r *http.Request) {
	jwks, err := h.keyManager.GetJWKS(r.Context())
	if err != nil {
		h.logger.Error().Err(err).Msg("failed to get JWKS")
		writeTechnicalError(w, r)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(jwks); err != nil {
		h.logger.Error().Err(err).Msg("failed to encode JWKS response")
	}
}

func (h *JWKSHandler) handleHealth(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "healthy",
		"service": "token-service",
	})
}

func (h *JWKSHandler) handleReady(w http.ResponseWriter, _ *http.Request) {
	// In production, check DB and Redis connectivity here
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ready"})
}

type errorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    string `json:"code"`
	Kind    string `json:"kind"`
}

func writeTechnicalError(w http.ResponseWriter, r *http.Request) {
	title, message := technicalErrorText(tokenLocaleFromRequest(r))
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusInternalServerError)
	_ = json.NewEncoder(w).Encode(errorResponse{
		Error:   title,
		Message: message,
		Code:    "token.technical",
		Kind:    "technical",
	})
}

func technicalErrorText(locale string) (string, string) {
	switch locale {
	case "en":
		return "Technical error", "A server problem occurred. Please try again later."
	case "kk":
		return "Техникалық қате", "Серверде мәселе туындады. Кейінірек қайталап көріңіз."
	default:
		return "Техническая ошибка", "На сервере возникла проблема. Попробуйте позже."
	}
}

func tokenLocaleFromRequest(r *http.Request) string {
	if r == nil {
		return "ru"
	}
	for _, part := range strings.Split(r.Header.Get("Accept-Language"), ",") {
		tag := strings.ToLower(strings.TrimSpace(strings.Split(part, ";")[0]))
		if idx := strings.IndexByte(tag, '-'); idx >= 0 {
			tag = tag[:idx]
		}
		switch tag {
		case "ru", "en", "kk":
			return tag
		}
	}
	return "ru"
}

// cacheControl sets Cache-Control header.
func cacheControl(maxAgeSec int) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Cache-Control", "public, max-age="+http.StatusText(maxAgeSec))
			next.ServeHTTP(w, r)
		})
	}
}
