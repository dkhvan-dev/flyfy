package http

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/rs/zerolog"

	"github.com/dkhvan-dev/flyfy/token-service/internal/domain/port"
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
		http.Error(w, "internal server error", http.StatusInternalServerError)
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

// cacheControl sets Cache-Control header.
func cacheControl(maxAgeSec int) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Cache-Control", "public, max-age="+http.StatusText(maxAgeSec))
			next.ServeHTTP(w, r)
		})
	}
}
