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
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Phone == "" {
		h.writeError(w, r, http.StatusBadRequest, "phone is required")
		return
	}

	if err := h.auth.SendOTP(r.Context(), req.Phone); err != nil {
		switch err {
		case model.ErrOTPRateLimit:
			h.writeError(w, r, http.StatusTooManyRequests, "too many requests, try again later")
		case model.ErrPhoneRequired:
			h.writeError(w, r, http.StatusBadRequest, "phone number is required")
		default:
			h.logger.Error().Err(err).Msg("send OTP failed")
			h.writeError(w, r, http.StatusInternalServerError, "failed to send OTP")
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
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Phone == "" || req.Code == "" {
		h.writeError(w, r, http.StatusBadRequest, "phone and code are required")
		return
	}

	result, err := h.auth.VerifyOTPAndLogin(r.Context(), req.Phone, req.Code, deviceFromRequest(r))
	if err != nil {
		switch err {
		case model.ErrInvalidOTP:
			h.writeError(w, r, http.StatusUnauthorized, "invalid or expired OTP code")
		case model.ErrUserBlocked:
			h.writeError(w, r, http.StatusForbidden, "account is blocked")
		case model.ErrTokenServiceUnavailable:
			h.writeError(w, r, http.StatusServiceUnavailable, "service temporarily unavailable")
		default:
			h.logger.Error().Err(err).Msg("verify OTP failed")
			h.writeError(w, r, http.StatusInternalServerError, "verification failed")
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
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.IDToken == "" {
		h.writeError(w, r, http.StatusBadRequest, "id_token is required")
		return
	}

	result, err := h.auth.GoogleLogin(r.Context(), req.IDToken, deviceFromRequest(r))
	if err != nil {
		h.handleOAuthError(w, r, err)
		return
	}

	h.writeJSON(w, http.StatusOK, result)
}

func (h *AuthHandler) handleAppleLogin(w http.ResponseWriter, r *http.Request) {
	var req oauthLoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.IDToken == "" {
		h.writeError(w, r, http.StatusBadRequest, "id_token is required")
		return
	}

	result, err := h.auth.AppleLogin(r.Context(), req.IDToken, deviceFromRequest(r))
	if err != nil {
		h.handleOAuthError(w, r, err)
		return
	}

	h.writeJSON(w, http.StatusOK, result)
}

func (h *AuthHandler) handleOAuthError(w http.ResponseWriter, r *http.Request, err error) {
	switch err {
	case model.ErrOAuthFailed:
		h.writeError(w, r, http.StatusUnauthorized, "invalid OAuth token")
	case model.ErrUserBlocked:
		h.writeError(w, r, http.StatusForbidden, "account is blocked")
	case model.ErrTokenServiceUnavailable:
		h.writeError(w, r, http.StatusServiceUnavailable, "service temporarily unavailable")
	default:
		h.logger.Error().Err(err).Msg("OAuth login failed")
		h.writeError(w, r, http.StatusInternalServerError, "authentication failed")
	}
}

// --- Token Management ---

type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

func (h *AuthHandler) handleRefresh(w http.ResponseWriter, r *http.Request) {
	var req refreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.RefreshToken == "" {
		h.writeError(w, r, http.StatusBadRequest, "refresh_token is required")
		return
	}

	result, err := h.auth.RefreshTokens(r.Context(), req.RefreshToken, deviceFromRequest(r))
	if err != nil {
		switch err {
		case model.ErrInvalidRefreshToken:
			h.writeError(w, r, http.StatusUnauthorized, "invalid or expired refresh token")
		default:
			h.logger.Error().Err(err).Msg("token refresh failed")
			h.writeError(w, r, http.StatusInternalServerError, "refresh failed")
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
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := h.auth.Logout(r.Context(), req.AccessToken, req.RefreshToken); err != nil {
		h.logger.Error().Err(err).Msg("logout failed")
		h.writeError(w, r, http.StatusInternalServerError, "logout failed")
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
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    string `json:"code"`
	Kind    string `json:"kind"`
}

type localizedError struct {
	title   string
	message string
	code    string
}

var authErrorMessages = map[string]map[string]localizedError{
	"ru": {
		"invalid request body": {
			title:   "Некорректный запрос",
			message: "Проверьте данные запроса и попробуйте снова.",
			code:    "auth.invalid_request_body",
		},
		"phone is required": {
			title:   "Укажите телефон",
			message: "Номер телефона обязателен.",
			code:    "auth.phone_required",
		},
		"phone number is required": {
			title:   "Укажите телефон",
			message: "Номер телефона обязателен.",
			code:    "auth.phone_required",
		},
		"phone and code are required": {
			title:   "Укажите телефон и код",
			message: "Телефон и код подтверждения обязательны.",
			code:    "auth.phone_code_required",
		},
		"id_token is required": {
			title:   "Токен обязателен",
			message: "OAuth id_token обязателен.",
			code:    "auth.id_token_required",
		},
		"refresh_token is required": {
			title:   "Refresh token обязателен",
			message: "Передайте refresh token и повторите запрос.",
			code:    "auth.refresh_token_required",
		},
		"too many requests, try again later": {
			title:   "Слишком много запросов",
			message: "Попробуйте повторить запрос чуть позже.",
			code:    "auth.rate_limited",
		},
		"invalid or expired OTP code": {
			title:   "Код недействителен",
			message: "Введите новый код подтверждения.",
			code:    "auth.invalid_otp",
		},
		"invalid OAuth token": {
			title:   "OAuth токен недействителен",
			message: "Повторите вход через провайдера.",
			code:    "auth.invalid_oauth_token",
		},
		"invalid or expired refresh token": {
			title:   "Сессия недействительна",
			message: "Войдите в аккаунт заново.",
			code:    "auth.invalid_refresh_token",
		},
		"account is blocked": {
			title:   "Аккаунт заблокирован",
			message: "Доступ к аккаунту ограничен.",
			code:    "auth.account_blocked",
		},
	},
	"en": {
		"invalid request body": {
			title:   "Invalid request",
			message: "Check the request data and try again.",
			code:    "auth.invalid_request_body",
		},
		"phone is required": {
			title:   "Phone is required",
			message: "Phone number is required.",
			code:    "auth.phone_required",
		},
		"phone number is required": {
			title:   "Phone is required",
			message: "Phone number is required.",
			code:    "auth.phone_required",
		},
		"phone and code are required": {
			title:   "Phone and code are required",
			message: "Phone and verification code are required.",
			code:    "auth.phone_code_required",
		},
		"id_token is required": {
			title:   "Token is required",
			message: "OAuth id_token is required.",
			code:    "auth.id_token_required",
		},
		"refresh_token is required": {
			title:   "Refresh token is required",
			message: "Send a refresh token and try again.",
			code:    "auth.refresh_token_required",
		},
		"too many requests, try again later": {
			title:   "Too many requests",
			message: "Please try again a little later.",
			code:    "auth.rate_limited",
		},
		"invalid or expired OTP code": {
			title:   "Code is invalid",
			message: "Enter a new verification code.",
			code:    "auth.invalid_otp",
		},
		"invalid OAuth token": {
			title:   "OAuth token is invalid",
			message: "Sign in with the provider again.",
			code:    "auth.invalid_oauth_token",
		},
		"invalid or expired refresh token": {
			title:   "Session is invalid",
			message: "Sign in again.",
			code:    "auth.invalid_refresh_token",
		},
		"account is blocked": {
			title:   "Account is blocked",
			message: "Access to this account is restricted.",
			code:    "auth.account_blocked",
		},
	},
	"kk": {
		"invalid request body": {
			title:   "Сұрау қате",
			message: "Сұрау деректерін тексеріп, қайта көріңіз.",
			code:    "auth.invalid_request_body",
		},
		"phone is required": {
			title:   "Телефон қажет",
			message: "Телефон нөмірі міндетті.",
			code:    "auth.phone_required",
		},
		"phone number is required": {
			title:   "Телефон қажет",
			message: "Телефон нөмірі міндетті.",
			code:    "auth.phone_required",
		},
		"phone and code are required": {
			title:   "Телефон мен код қажет",
			message: "Телефон және растау коды міндетті.",
			code:    "auth.phone_code_required",
		},
		"id_token is required": {
			title:   "Токен қажет",
			message: "OAuth id_token міндетті.",
			code:    "auth.id_token_required",
		},
		"refresh_token is required": {
			title:   "Refresh token қажет",
			message: "Refresh token жіберіп, сұрауды қайталаңыз.",
			code:    "auth.refresh_token_required",
		},
		"too many requests, try again later": {
			title:   "Сұраулар тым көп",
			message: "Сәл кейінірек қайталап көріңіз.",
			code:    "auth.rate_limited",
		},
		"invalid or expired OTP code": {
			title:   "Код жарамсыз",
			message: "Жаңа растау кодын енгізіңіз.",
			code:    "auth.invalid_otp",
		},
		"invalid OAuth token": {
			title:   "OAuth токені жарамсыз",
			message: "Провайдер арқылы қайта кіріңіз.",
			code:    "auth.invalid_oauth_token",
		},
		"invalid or expired refresh token": {
			title:   "Сессия жарамсыз",
			message: "Аккаунтқа қайта кіріңіз.",
			code:    "auth.invalid_refresh_token",
		},
		"account is blocked": {
			title:   "Аккаунт бұғатталған",
			message: "Бұл аккаунтқа кіру шектелген.",
			code:    "auth.account_blocked",
		},
	},
}

func (h *AuthHandler) writeJSON(w http.ResponseWriter, status int, v any) {
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		h.logger.Error().Err(err).Msg("failed to encode JSON response")
	}
}

func (h *AuthHandler) writeError(w http.ResponseWriter, r *http.Request, status int, msg string) {
	kind := "business"
	entry := localizedAuthError(r, msg)
	if status >= http.StatusInternalServerError {
		kind = "technical"
		entry = technicalAuthError(r)
	}
	h.writeJSON(w, status, errorResponse{
		Error:   entry.title,
		Message: entry.message,
		Code:    entry.code,
		Kind:    kind,
	})
}

func localizedAuthError(r *http.Request, msg string) localizedError {
	locale := authLocaleFromRequest(r)
	if messages, ok := authErrorMessages[locale]; ok {
		if entry, ok := messages[msg]; ok {
			return entry
		}
	}
	if entry, ok := authErrorMessages["ru"][msg]; ok {
		return entry
	}
	return localizedError{
		title:   "Некорректный запрос",
		message: "Проверьте данные запроса и попробуйте снова.",
		code:    "auth.bad_request",
	}
}

func technicalAuthError(r *http.Request) localizedError {
	switch authLocaleFromRequest(r) {
	case "en":
		return localizedError{
			title:   "Technical error",
			message: "A server problem occurred. Please try again later.",
			code:    "auth.technical",
		}
	case "kk":
		return localizedError{
			title:   "Техникалық қате",
			message: "Серверде мәселе туындады. Кейінірек қайталап көріңіз.",
			code:    "auth.technical",
		}
	default:
		return localizedError{
			title:   "Техническая ошибка",
			message: "На сервере возникла проблема. Попробуйте позже.",
			code:    "auth.technical",
		}
	}
}

func authLocaleFromRequest(r *http.Request) string {
	if r == nil {
		return "ru"
	}
	if locale := supportedAuthLocale(r.URL.Query().Get("lang")); locale != "" {
		return locale
	}
	for _, part := range strings.Split(r.Header.Get("Accept-Language"), ",") {
		tag := strings.TrimSpace(strings.Split(part, ";")[0])
		if locale := supportedAuthLocale(tag); locale != "" {
			return locale
		}
	}
	return "ru"
}

func supportedAuthLocale(tag string) string {
	tag = strings.ToLower(strings.TrimSpace(tag))
	if idx := strings.IndexByte(tag, '-'); idx >= 0 {
		tag = tag[:idx]
	}
	switch tag {
	case "ru", "en", "kk":
		return tag
	default:
		return ""
	}
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
