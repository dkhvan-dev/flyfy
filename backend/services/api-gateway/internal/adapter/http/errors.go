package http

import (
	"encoding/json"
	"net/http"
	"strings"
)

const (
	errorKindBusiness  = "business"
	errorKindTechnical = "technical"

	errorCodeRouteNotFound       = "gateway.route_not_found"
	errorCodeRateLimitExceeded   = "gateway.rate_limit_exceeded"
	errorCodeAuthRequired        = "gateway.auth_required"
	errorCodeInvalidAccessToken  = "gateway.invalid_access_token"
	errorCodeInsufficientRole    = "gateway.insufficient_role"
	errorCodeUpstreamUnavailable = "gateway.downstream_unavailable"
	errorCodeUserResolution      = "gateway.user_resolution_failed"
	errorCodeTechnical           = "gateway.technical"
)

type errorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    string `json:"code"`
	Kind    string `json:"kind"`
}

type localizedError struct {
	title   string
	message string
}

var localizedErrors = map[string]map[string]localizedError{
	"ru": {
		errorCodeRouteNotFound: {
			title:   "Маршрут не найден",
			message: "Запрошенный API-маршрут не найден.",
		},
		errorCodeRateLimitExceeded: {
			title:   "Слишком много запросов",
			message: "Попробуйте повторить запрос чуть позже.",
		},
		errorCodeAuthRequired: {
			title:   "Требуется авторизация",
			message: "Войдите в аккаунт и повторите запрос.",
		},
		errorCodeInvalidAccessToken: {
			title:   "Сессия недействительна",
			message: "Войдите в аккаунт заново.",
		},
		errorCodeInsufficientRole: {
			title:   "Недостаточно прав",
			message: "У вас нет доступа к этому действию.",
		},
		errorCodeUpstreamUnavailable: {
			title:   "Техническая ошибка",
			message: "На сервере возникла проблема. Попробуйте позже.",
		},
		errorCodeUserResolution: {
			title:   "Техническая ошибка",
			message: "На сервере возникла проблема. Попробуйте позже.",
		},
		errorCodeTechnical: {
			title:   "Техническая ошибка",
			message: "На сервере возникла проблема. Попробуйте позже.",
		},
	},
	"en": {
		errorCodeRouteNotFound: {
			title:   "Route not found",
			message: "The requested API route was not found.",
		},
		errorCodeRateLimitExceeded: {
			title:   "Too many requests",
			message: "Please try again a little later.",
		},
		errorCodeAuthRequired: {
			title:   "Authentication required",
			message: "Sign in and try again.",
		},
		errorCodeInvalidAccessToken: {
			title:   "Session is invalid",
			message: "Sign in again.",
		},
		errorCodeInsufficientRole: {
			title:   "Insufficient permissions",
			message: "You do not have access to this action.",
		},
		errorCodeUpstreamUnavailable: {
			title:   "Technical error",
			message: "A server problem occurred. Please try again later.",
		},
		errorCodeUserResolution: {
			title:   "Technical error",
			message: "A server problem occurred. Please try again later.",
		},
		errorCodeTechnical: {
			title:   "Technical error",
			message: "A server problem occurred. Please try again later.",
		},
	},
	"kk": {
		errorCodeRouteNotFound: {
			title:   "Бағыт табылмады",
			message: "Сұралған API бағыты табылмады.",
		},
		errorCodeRateLimitExceeded: {
			title:   "Сұраулар тым көп",
			message: "Сәл кейінірек қайталап көріңіз.",
		},
		errorCodeAuthRequired: {
			title:   "Авторизация қажет",
			message: "Аккаунтқа кіріп, сұрауды қайталаңыз.",
		},
		errorCodeInvalidAccessToken: {
			title:   "Сессия жарамсыз",
			message: "Аккаунтқа қайта кіріңіз.",
		},
		errorCodeInsufficientRole: {
			title:   "Құқық жеткіліксіз",
			message: "Бұл әрекетке қол жеткізу құқығыңыз жоқ.",
		},
		errorCodeUpstreamUnavailable: {
			title:   "Техникалық қате",
			message: "Серверде мәселе туындады. Кейінірек қайталап көріңіз.",
		},
		errorCodeUserResolution: {
			title:   "Техникалық қате",
			message: "Серверде мәселе туындады. Кейінірек қайталап көріңіз.",
		},
		errorCodeTechnical: {
			title:   "Техникалық қате",
			message: "Серверде мәселе туындады. Кейінірек қайталап көріңіз.",
		},
	},
}

func writeBusinessError(w http.ResponseWriter, r *http.Request, status int, code string) {
	writeErrorResponse(w, r, status, code, errorKindBusiness)
}

func writeTechnicalError(w http.ResponseWriter, r *http.Request, status int, code string) {
	writeErrorResponse(w, r, status, code, errorKindTechnical)
}

func writeErrorResponse(w http.ResponseWriter, r *http.Request, status int, code string, kind string) {
	writeJSON(w, status, buildErrorResponse(r, code, kind))
}

func buildErrorResponse(r *http.Request, code string, kind string) errorResponse {
	locale := localeFromRequest(r)
	entry := lookupLocalizedError(locale, code)
	if kind == errorKindTechnical {
		entry = lookupLocalizedError(locale, errorCodeTechnical)
	}

	return errorResponse{
		Error:   entry.title,
		Message: entry.message,
		Code:    code,
		Kind:    kind,
	}
}

func lookupLocalizedError(locale string, code string) localizedError {
	if messages, ok := localizedErrors[locale]; ok {
		if entry, ok := messages[code]; ok {
			return entry
		}
		if entry, ok := messages[errorCodeTechnical]; ok {
			return entry
		}
	}
	return localizedErrors["ru"][errorCodeTechnical]
}

func localeFromRequest(r *http.Request) string {
	if r != nil {
		if locale := supportedLocale(r.URL.Query().Get("lang")); locale != "" {
			return locale
		}
		for _, part := range strings.Split(r.Header.Get("Accept-Language"), ",") {
			tag := strings.TrimSpace(strings.Split(part, ";")[0])
			if locale := supportedLocale(tag); locale != "" {
				return locale
			}
		}
	}
	return "ru"
}

func supportedLocale(tag string) string {
	tag = strings.ToLower(strings.TrimSpace(tag))
	if tag == "" {
		return ""
	}
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

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
