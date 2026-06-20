package http

import (
	"encoding/json"
	"errors"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/rs/zerolog"

	"kz/inflap/backend/services/auth-service/internal/domain/model"
	"kz/inflap/backend/services/auth-service/internal/domain/port"
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

		// Email/password
		r.Post("/register/email/start", h.handleStartEmailRegistration)
		r.Post("/register/email/verify", h.handleVerifyEmailRegistration)
		r.Post("/login/password", h.handlePasswordLogin)
		r.Post("/password/change/start", h.handleStartPasswordChange)
		r.Post("/password/change/verify", h.handleVerifyPasswordChange)
		r.Post("/password/reset/start", h.handleStartPasswordReset)
		r.Post("/password/reset/verify", h.handleVerifyPasswordReset)

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

	if err := h.auth.SendOTP(r.Context(), req.Phone, deviceFromRequest(r)); err != nil {
		switch err {
		case model.ErrOTPRateLimit:
			h.writeError(w, r, http.StatusTooManyRequests, "too many requests, try again later")
		case model.ErrPhoneRequired:
			h.writeError(w, r, http.StatusBadRequest, "phone number is required")
		case model.ErrTechnicalMaintenance:
			h.writeMaintenanceError(w, r)
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
		case model.ErrRateLimited:
			h.writeError(w, r, http.StatusTooManyRequests, "too many requests, try again later")
		case model.ErrUserBlocked:
			h.writeError(w, r, http.StatusForbidden, "account is blocked")
		case model.ErrTokenServiceUnavailable:
			h.writeError(w, r, http.StatusServiceUnavailable, "service temporarily unavailable")
		case model.ErrTechnicalMaintenance:
			h.writeMaintenanceError(w, r)
		default:
			h.logger.Error().Err(err).Msg("verify OTP failed")
			h.writeError(w, r, http.StatusInternalServerError, "verification failed")
		}
		return
	}

	h.writeJSON(w, http.StatusOK, result)
}

// --- Email/Password ---

type startEmailRegistrationRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *AuthHandler) handleStartEmailRegistration(w http.ResponseWriter, r *http.Request) {
	var req startEmailRegistrationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := h.auth.StartEmailRegistration(r.Context(), req.Email, req.Password, deviceFromRequest(r)); err != nil {
		switch {
		case errors.Is(err, model.ErrEmailRequired):
			h.writeError(w, r, http.StatusBadRequest, "email is required")
		case errors.Is(err, model.ErrEmailInvalid):
			h.writeError(w, r, http.StatusBadRequest, "email is invalid")
		case errors.Is(err, model.ErrPasswordRequired):
			h.writeError(w, r, http.StatusBadRequest, "password is required")
		case errors.Is(err, model.ErrPasswordWeak):
			h.writeError(w, r, http.StatusBadRequest, "password is too weak")
		case errors.Is(err, model.ErrEmailAlreadyExists):
			h.writeError(w, r, http.StatusConflict, "email is already registered")
		case errors.Is(err, model.ErrRateLimited), errors.Is(err, model.ErrOTPRateLimit):
			h.writeError(w, r, http.StatusTooManyRequests, "too many requests, try again later")
		case errors.Is(err, model.ErrTechnicalMaintenance):
			h.writeMaintenanceError(w, r)
		default:
			h.logger.Error().Err(err).Msg("start email registration failed")
			h.writeError(w, r, http.StatusInternalServerError, "registration failed")
		}
		return
	}

	h.writeJSON(w, http.StatusOK, map[string]string{
		"message": "OTP code sent successfully",
	})
}

type verifyEmailRegistrationRequest struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

func (h *AuthHandler) handleVerifyEmailRegistration(w http.ResponseWriter, r *http.Request) {
	var req verifyEmailRegistrationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	result, err := h.auth.VerifyEmailRegistration(r.Context(), req.Email, req.Code, deviceFromRequest(r))
	if err != nil {
		switch {
		case errors.Is(err, model.ErrEmailRequired):
			h.writeError(w, r, http.StatusBadRequest, "email is required")
		case errors.Is(err, model.ErrEmailInvalid):
			h.writeError(w, r, http.StatusBadRequest, "email is invalid")
		case errors.Is(err, model.ErrInvalidOTP), errors.Is(err, model.ErrInvalidCredentials):
			h.writeError(w, r, http.StatusUnauthorized, "invalid or expired OTP code")
		case errors.Is(err, model.ErrUserBlocked):
			h.writeError(w, r, http.StatusForbidden, "account is blocked")
		case errors.Is(err, model.ErrRateLimited):
			h.writeError(w, r, http.StatusTooManyRequests, "too many requests, try again later")
		case errors.Is(err, model.ErrTokenServiceUnavailable):
			h.writeError(w, r, http.StatusServiceUnavailable, "service temporarily unavailable")
		case errors.Is(err, model.ErrTechnicalMaintenance):
			h.writeMaintenanceError(w, r)
		default:
			h.logger.Error().Err(err).Msg("verify email registration failed")
			h.writeError(w, r, http.StatusInternalServerError, "verification failed")
		}
		return
	}

	h.writeJSON(w, http.StatusOK, result)
}

type passwordLoginRequest struct {
	Identifier string `json:"identifier"`
	Password   string `json:"password"`
}

func (h *AuthHandler) handlePasswordLogin(w http.ResponseWriter, r *http.Request) {
	var req passwordLoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	result, err := h.auth.PasswordLogin(r.Context(), req.Identifier, req.Password, deviceFromRequest(r))
	if err != nil {
		switch {
		case errors.Is(err, model.ErrInvalidCredentials):
			h.writeError(w, r, http.StatusUnauthorized, "invalid credentials")
		case errors.Is(err, model.ErrRateLimited):
			h.writeError(w, r, http.StatusTooManyRequests, "too many requests, try again later")
		case errors.Is(err, model.ErrTokenServiceUnavailable):
			h.writeError(w, r, http.StatusServiceUnavailable, "service temporarily unavailable")
		case errors.Is(err, model.ErrTechnicalMaintenance):
			h.writeMaintenanceError(w, r)
		default:
			h.logger.Error().Err(err).Msg("password login failed")
			h.writeError(w, r, http.StatusInternalServerError, "authentication failed")
		}
		return
	}

	h.writeJSON(w, http.StatusOK, result)
}

type startPasswordResetRequest struct {
	Identifier string `json:"identifier"`
}

func (h *AuthHandler) handleStartPasswordReset(w http.ResponseWriter, r *http.Request) {
	var req startPasswordResetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	if strings.TrimSpace(req.Identifier) == "" {
		h.writeError(w, r, http.StatusBadRequest, "identifier is required")
		return
	}

	if err := h.auth.StartPasswordReset(r.Context(), req.Identifier, deviceFromRequest(r)); err != nil {
		switch {
		case errors.Is(err, model.ErrRateLimited), errors.Is(err, model.ErrOTPRateLimit):
			h.writeError(w, r, http.StatusTooManyRequests, "too many requests, try again later")
		case errors.Is(err, model.ErrInvalidCredentials):
			h.writeError(w, r, http.StatusBadRequest, "identifier is required")
		default:
			h.logger.Error().Err(err).Msg("start password reset failed")
			h.writeError(w, r, http.StatusInternalServerError, "password reset failed")
		}
		return
	}

	h.writeJSON(w, http.StatusOK, map[string]string{
		"message": "if the account exists, a password reset code was sent",
	})
}

type verifyPasswordResetRequest struct {
	Identifier string `json:"identifier"`
	Code       string `json:"code"`
	Password   string `json:"password"`
}

func (h *AuthHandler) handleVerifyPasswordReset(w http.ResponseWriter, r *http.Request) {
	var req verifyPasswordResetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := h.auth.VerifyPasswordReset(r.Context(), req.Identifier, req.Code, req.Password, deviceFromRequest(r)); err != nil {
		switch {
		case errors.Is(err, model.ErrPasswordRequired):
			h.writeError(w, r, http.StatusBadRequest, "password is required")
		case errors.Is(err, model.ErrPasswordWeak):
			h.writeError(w, r, http.StatusBadRequest, "password is too weak")
		case errors.Is(err, model.ErrInvalidCredentials):
			h.writeError(w, r, http.StatusBadRequest, "identifier is required")
		case errors.Is(err, model.ErrInvalidOTP):
			h.writeError(w, r, http.StatusUnauthorized, "invalid or expired OTP code")
		case errors.Is(err, model.ErrRateLimited):
			h.writeError(w, r, http.StatusTooManyRequests, "too many requests, try again later")
		default:
			h.logger.Error().Err(err).Msg("verify password reset failed")
			h.writeError(w, r, http.StatusInternalServerError, "password reset failed")
		}
		return
	}

	h.writeJSON(w, http.StatusOK, map[string]string{
		"message": "password reset successfully",
	})
}

type startPasswordChangeRequest struct {
	CurrentPassword string `json:"current_password"`
}

func (h *AuthHandler) handleStartPasswordChange(w http.ResponseWriter, r *http.Request) {
	var req startPasswordChangeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := h.auth.StartPasswordChange(r.Context(), bearerTokenFromRequest(r), req.CurrentPassword, deviceFromRequest(r)); err != nil {
		h.handlePasswordChangeError(w, r, err, "start password change failed")
		return
	}

	h.writeJSON(w, http.StatusOK, map[string]string{
		"message": "password change code sent successfully",
	})
}

type verifyPasswordChangeRequest struct {
	CurrentPassword string `json:"current_password"`
	Code            string `json:"code"`
	NewPassword     string `json:"new_password"`
}

func (h *AuthHandler) handleVerifyPasswordChange(w http.ResponseWriter, r *http.Request) {
	var req verifyPasswordChangeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := h.auth.VerifyPasswordChange(r.Context(), bearerTokenFromRequest(r), req.CurrentPassword, req.Code, req.NewPassword, deviceFromRequest(r)); err != nil {
		h.handlePasswordChangeError(w, r, err, "verify password change failed")
		return
	}

	h.writeJSON(w, http.StatusOK, map[string]string{
		"message": "password changed successfully",
	})
}

func (h *AuthHandler) handlePasswordChangeError(w http.ResponseWriter, r *http.Request, err error, logMessage string) {
	switch {
	case errors.Is(err, model.ErrPasswordRequired):
		h.writeError(w, r, http.StatusBadRequest, "password is required")
	case errors.Is(err, model.ErrPasswordWeak):
		h.writeError(w, r, http.StatusBadRequest, "password is too weak")
	case errors.Is(err, model.ErrPasswordUnchanged):
		h.writeError(w, r, http.StatusBadRequest, "new password must differ from current password")
	case errors.Is(err, model.ErrInvalidOTP):
		h.writeError(w, r, http.StatusUnauthorized, "invalid or expired OTP code")
	case errors.Is(err, model.ErrInvalidCredentials):
		h.writeError(w, r, http.StatusUnauthorized, "invalid credentials")
	case errors.Is(err, model.ErrEmailNotVerified):
		h.writeError(w, r, http.StatusConflict, "verified email is required")
	case errors.Is(err, model.ErrUserBlocked):
		h.writeError(w, r, http.StatusForbidden, "account is blocked")
	case errors.Is(err, model.ErrRateLimited), errors.Is(err, model.ErrOTPRateLimit):
		h.writeError(w, r, http.StatusTooManyRequests, "too many requests, try again later")
	default:
		h.logger.Error().Err(err).Msg(logMessage)
		h.writeError(w, r, http.StatusInternalServerError, "password change failed")
	}
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
		case model.ErrRateLimited:
			h.writeError(w, r, http.StatusTooManyRequests, "too many requests, try again later")
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
		"email is required": {
			title:   "Укажите email",
			message: "Электронная почта обязательна.",
			code:    "auth.email_required",
		},
		"email is invalid": {
			title:   "Некорректный email",
			message: "Проверьте адрес электронной почты.",
			code:    "auth.email_invalid",
		},
		"password is required": {
			title:   "Укажите пароль",
			message: "Пароль обязателен.",
			code:    "auth.password_required",
		},
		"password is too weak": {
			title:   "Слабый пароль",
			message: "Пароль должен содержать минимум 8 символов, буквы и цифры.",
			code:    "auth.password_weak",
		},
		"email is already registered": {
			title:   "Email уже зарегистрирован",
			message: "Войдите в аккаунт или используйте другой email.",
			code:    "auth.email_already_registered",
		},
		"invalid credentials": {
			title:   "Неверные данные входа",
			message: "Проверьте никнейм или email и пароль.",
			code:    "auth.invalid_credentials",
		},
		"identifier is required": {
			title:   "Укажите email или никнейм",
			message: "Введите email или никнейм аккаунта.",
			code:    "auth.identifier_required",
		},
		"password reset failed": {
			title:   "Не удалось восстановить пароль",
			message: "Попробуйте повторить восстановление чуть позже.",
			code:    "auth.password_reset_failed",
		},
		"password change failed": {
			title:   "Не удалось сменить пароль",
			message: "Попробуйте повторить смену пароля чуть позже.",
			code:    "auth.password_change_failed",
		},
		"new password must differ from current password": {
			title:   "Пароль уже используется",
			message: "Новый пароль должен отличаться от текущего.",
			code:    "auth.password_unchanged",
		},
		"verified email is required": {
			title:   "Нужен подтвержденный email",
			message: "Сменить пароль можно только для аккаунта с подтвержденной почтой.",
			code:    "auth.verified_email_required",
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
		"email is required": {
			title:   "Email is required",
			message: "Email address is required.",
			code:    "auth.email_required",
		},
		"email is invalid": {
			title:   "Email is invalid",
			message: "Check the email address.",
			code:    "auth.email_invalid",
		},
		"password is required": {
			title:   "Password is required",
			message: "Password is required.",
			code:    "auth.password_required",
		},
		"password is too weak": {
			title:   "Password is too weak",
			message: "Use at least 8 characters with letters and digits.",
			code:    "auth.password_weak",
		},
		"email is already registered": {
			title:   "Email is already registered",
			message: "Sign in or use another email address.",
			code:    "auth.email_already_registered",
		},
		"invalid credentials": {
			title:   "Invalid sign-in details",
			message: "Check your nickname or email and password.",
			code:    "auth.invalid_credentials",
		},
		"identifier is required": {
			title:   "Email or nickname is required",
			message: "Enter the account email or nickname.",
			code:    "auth.identifier_required",
		},
		"password reset failed": {
			title:   "Password reset failed",
			message: "Please try resetting the password again later.",
			code:    "auth.password_reset_failed",
		},
		"password change failed": {
			title:   "Password change failed",
			message: "Please try changing the password again later.",
			code:    "auth.password_change_failed",
		},
		"new password must differ from current password": {
			title:   "Password is already in use",
			message: "The new password must be different from the current one.",
			code:    "auth.password_unchanged",
		},
		"verified email is required": {
			title:   "Verified email required",
			message: "Password changes require a verified account email.",
			code:    "auth.verified_email_required",
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
		"email is required": {
			title:   "Email қажет",
			message: "Электрондық пошта міндетті.",
			code:    "auth.email_required",
		},
		"email is invalid": {
			title:   "Email қате",
			message: "Электрондық пошта мекенжайын тексеріңіз.",
			code:    "auth.email_invalid",
		},
		"password is required": {
			title:   "Құпиясөз қажет",
			message: "Құпиясөз міндетті.",
			code:    "auth.password_required",
		},
		"password is too weak": {
			title:   "Құпиясөз әлсіз",
			message: "Кемінде 8 таңба, әріптер және сандар қолданыңыз.",
			code:    "auth.password_weak",
		},
		"email is already registered": {
			title:   "Email тіркелген",
			message: "Аккаунтқа кіріңіз немесе басқа email қолданыңыз.",
			code:    "auth.email_already_registered",
		},
		"invalid credentials": {
			title:   "Кіру деректері қате",
			message: "Никнейм немесе email және құпиясөзді тексеріңіз.",
			code:    "auth.invalid_credentials",
		},
		"identifier is required": {
			title:   "Email немесе никнейм қажет",
			message: "Аккаунт email-ін немесе никнеймін енгізіңіз.",
			code:    "auth.identifier_required",
		},
		"password reset failed": {
			title:   "Құпиясөзді қалпына келтіру сәтсіз",
			message: "Құпиясөзді қалпына келтіруді кейінірек қайталаңыз.",
			code:    "auth.password_reset_failed",
		},
		"password change failed": {
			title:   "Құпиясөзді ауыстыру сәтсіз",
			message: "Құпиясөзді ауыстыруды кейінірек қайталаңыз.",
			code:    "auth.password_change_failed",
		},
		"new password must differ from current password": {
			title:   "Құпиясөз қолданылып тұр",
			message: "Жаңа құпиясөз қазіргі құпиясөзден өзгеше болуы керек.",
			code:    "auth.password_unchanged",
		},
		"verified email is required": {
			title:   "Расталған email қажет",
			message: "Құпиясөзді ауыстыру үшін аккаунт email-і расталған болуы керек.",
			code:    "auth.verified_email_required",
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

func (h *AuthHandler) writeMaintenanceError(w http.ResponseWriter, r *http.Request) {
	entry := maintenanceAuthError(r)
	h.writeJSON(w, http.StatusServiceUnavailable, errorResponse{
		Error:   entry.title,
		Message: entry.message,
		Code:    entry.code,
		Kind:    "maintenance",
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

func maintenanceAuthError(r *http.Request) localizedError {
	switch authLocaleFromRequest(r) {
	case "en":
		return localizedError{
			title:   "Maintenance in progress",
			message: "Technical maintenance is in progress. Please try again later.",
			code:    "auth.technical_maintenance",
		}
	case "kk":
		return localizedError{
			title:   "Техникалық жұмыстар",
			message: "Қазір техникалық жұмыстар жүріп жатыр. Кейінірек қайталап көріңіз.",
			code:    "auth.technical_maintenance",
		}
	default:
		return localizedError{
			title:   "Технические работы",
			message: "Сейчас проводятся технические работы. Попробуйте позже.",
			code:    "auth.technical_maintenance",
		}
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

func bearerTokenFromRequest(r *http.Request) string {
	header := strings.TrimSpace(r.Header.Get("Authorization"))
	if header == "" {
		return ""
	}
	parts := strings.Fields(header)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return ""
	}
	return strings.TrimSpace(parts[1])
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
