package http

import (
	"encoding/json"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/rs/zerolog"

	"github.com/dkhvan-dev/flyfy/backend/services/auth-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/auth-service/internal/domain/port"
)

// AuthHandler handles HTTP requests for authentication.
type AuthHandler struct {
	auth   port.Authenticator
	logger zerolog.Logger
}

func NewAuthHandler(auth port.Authenticator, logger zerolog.Logger) *AuthHandler {
	return &AuthHandler{
		auth:   auth,
		logger: logger.With().Str("component", "http_handler").Logger(),
	}
}

// Router returns an http.Handler with all auth endpoints.
func (h *AuthHandler) Router() http.Handler {
	r := chi.NewRouter()

	// Middleware
	r.Use(chimw.RequestID)
	r.Use(chimw.RealIP)
	r.Use(chimw.Recoverer)
	r.Use(chimw.Timeout(10 * time.Second))
	r.Use(jsonContentType)

	// Health
	r.Get("/health", h.handleHealth)
	r.Get("/ready", h.handleReady)

	// Auth API v1
	r.Route("/api/v1/auth", func(r chi.Router) {
		// Phone OTP
		r.Post("/phone/send-code", h.handleSendOTP)
		r.Post("/phone/verify", h.handleVerifyOTP)

		// OAuth
		r.Post("/google", h.handleGoogleLogin)
		r.Post("/apple", h.handleAppleLogin)

		// Token management
		r.Post("/refresh", h.handleRefresh)
		r.Post("/logout", h.handleLogout)
	})

	return r
}

// --- Phone OTP ---

type sendOTPRequest struct {
	Phone string `json:"phone"`
}

func (h *AuthHandler) handleSendOTP(w http.ResponseWriter, r *http.Request) {
	var req sendOTPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Phone == "" {
		h.writeError(w, http.StatusBadRequest, "phone is required")
		return
	}

	if err := h.auth.SendOTP(r.Context(), req.Phone); err != nil {
		switch err {
		case model.ErrOTPRateLimit:
			h.writeError(w, http.StatusTooManyRequests, "too many requests, try again later")
		case model.ErrPhoneRequired:
			h.writeError(w, http.StatusBadRequest, "phone number is required")
		default:
			h.logger.Error().Err(err).Msg("send OTP failed")
			h.writeError(w, http.StatusInternalServerError, "failed to send OTP")
		}
		return
	}

	h.writeJSON(w, http.StatusOK, map[string]string{
		"message": "OTP code sent successfully",
	})
}

type verifyOTPRequest struct {
	Phone string `json:"phone"`
	Code  string `json:"code"`
}

func (h *AuthHandler) handleVerifyOTP(w http.ResponseWriter, r *http.Request) {
	var req verifyOTPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Phone == "" || req.Code == "" {
		h.writeError(w, http.StatusBadRequest, "phone and code are required")
		return
	}

	result, err := h.auth.VerifyOTPAndLogin(r.Context(), req.Phone, req.Code, deviceFromRequest(r))
	if err != nil {
		switch err {
		case model.ErrInvalidOTP:
			h.writeError(w, http.StatusUnauthorized, "invalid or expired OTP code")
		case model.ErrUserBlocked:
			h.writeError(w, http.StatusForbidden, "account is blocked")
		case model.ErrTokenServiceUnavailable:
			h.writeError(w, http.StatusServiceUnavailable, "service temporarily unavailable")
		default:
			h.logger.Error().Err(err).Msg("verify OTP failed")
			h.writeError(w, http.StatusInternalServerError, "verification failed")
		}
		return
	}

	h.writeJSON(w, http.StatusOK, result)
}

// --- OAuth ---

type oauthLoginRequest struct {
	IDToken string `json:"id_token"`
}

func (h *AuthHandler) handleGoogleLogin(w http.ResponseWriter, r *http.Request) {
	var req oauthLoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.IDToken == "" {
		h.writeError(w, http.StatusBadRequest, "id_token is required")
		return
	}

	result, err := h.auth.GoogleLogin(r.Context(), req.IDToken, deviceFromRequest(r))
	if err != nil {
		h.handleOAuthError(w, err)
		return
	}

	h.writeJSON(w, http.StatusOK, result)
}

func (h *AuthHandler) handleAppleLogin(w http.ResponseWriter, r *http.Request) {
	var req oauthLoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.IDToken == "" {
		h.writeError(w, http.StatusBadRequest, "id_token is required")
		return
	}

	result, err := h.auth.AppleLogin(r.Context(), req.IDToken, deviceFromRequest(r))
	if err != nil {
		h.handleOAuthError(w, err)
		return
	}

	h.writeJSON(w, http.StatusOK, result)
}

func (h *AuthHandler) handleOAuthError(w http.ResponseWriter, err error) {
	switch err {
	case model.ErrOAuthFailed:
		h.writeError(w, http.StatusUnauthorized, "invalid OAuth token")
	case model.ErrUserBlocked:
		h.writeError(w, http.StatusForbidden, "account is blocked")
	case model.ErrTokenServiceUnavailable:
		h.writeError(w, http.StatusServiceUnavailable, "service temporarily unavailable")
	default:
		h.logger.Error().Err(err).Msg("OAuth login failed")
		h.writeError(w, http.StatusInternalServerError, "authentication failed")
	}
}

// --- Token Management ---

type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

func (h *AuthHandler) handleRefresh(w http.ResponseWriter, r *http.Request) {
	var req refreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.RefreshToken == "" {
		h.writeError(w, http.StatusBadRequest, "refresh_token is required")
		return
	}

	result, err := h.auth.RefreshTokens(r.Context(), req.RefreshToken, deviceFromRequest(r))
	if err != nil {
		switch err {
		case model.ErrInvalidRefreshToken:
			h.writeError(w, http.StatusUnauthorized, "invalid or expired refresh token")
		default:
			h.logger.Error().Err(err).Msg("token refresh failed")
			h.writeError(w, http.StatusInternalServerError, "refresh failed")
		}
		return
	}

	h.writeJSON(w, http.StatusOK, result)
}

type logoutRequest struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

func (h *AuthHandler) handleLogout(w http.ResponseWriter, r *http.Request) {
	var req logoutRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := h.auth.Logout(r.Context(), req.AccessToken, req.RefreshToken); err != nil {
		h.logger.Error().Err(err).Msg("logout failed")
		h.writeError(w, http.StatusInternalServerError, "logout failed")
		return
	}

	h.writeJSON(w, http.StatusOK, map[string]string{
		"message": "logged out successfully",
	})
}

// --- Health ---

func (h *AuthHandler) handleHealth(w http.ResponseWriter, _ *http.Request) {
	h.writeJSON(w, http.StatusOK, map[string]string{
		"status":  "healthy",
		"service": "auth-service",
	})
}

func (h *AuthHandler) handleReady(w http.ResponseWriter, _ *http.Request) {
	h.writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

// --- Helpers ---

type errorResponse struct {
	Error string `json:"error"`
}

func (h *AuthHandler) writeJSON(w http.ResponseWriter, status int, v any) {
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		h.logger.Error().Err(err).Msg("failed to encode JSON response")
	}
}

func (h *AuthHandler) writeError(w http.ResponseWriter, status int, msg string) {
	h.writeJSON(w, status, errorResponse{Error: msg})
}

func jsonContentType(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		next.ServeHTTP(w, r)
	})
}

// deviceFromRequest extracts client device metadata. Mobile is expected to send
// X-Device-* headers; web/legacy clients fall back to User-Agent + IP.
// All fields are optional — missing headers are stored as empty strings.
func deviceFromRequest(r *http.Request) model.DeviceInfo {
	return model.DeviceInfo{
		DeviceID:   r.Header.Get("X-Device-Id"),
		Platform:   r.Header.Get("X-Device-Platform"),
		OSVersion:  r.Header.Get("X-Device-Os"),
		AppVersion: r.Header.Get("X-App-Version"),
		Model:      r.Header.Get("X-Device-Model"),
		UserAgent:  r.UserAgent(),
		IPAddress:  clientIP(r),
	}
}

// clientIP returns the best-effort client IP. Honors X-Forwarded-For (first
// hop) and X-Real-IP if present; otherwise falls back to RemoteAddr.
func clientIP(r *http.Request) string {
	if xff := strings.TrimSpace(r.Header.Get("X-Forwarded-For")); xff != "" {
		if comma := strings.Index(xff, ","); comma > 0 {
			return strings.TrimSpace(xff[:comma])
		}
		return xff
	}
	if xri := strings.TrimSpace(r.Header.Get("X-Real-IP")); xri != "" {
		return xri
	}
	if host, _, err := net.SplitHostPort(r.RemoteAddr); err == nil {
		return host
	}
	return r.RemoteAddr
}
