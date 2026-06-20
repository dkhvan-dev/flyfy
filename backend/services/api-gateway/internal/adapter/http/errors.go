package http

import (
	"encoding/json"
	"net/http"
	"strings"
)

const (
	errorKindBusiness    = "business"
	errorKindTechnical   = "technical"
	errorKindMaintenance = "maintenance"

	errorCodeRouteNotFound       = "gateway.route_not_found"
	errorCodeRateLimitExceeded   = "gateway.rate_limit_exceeded"
	errorCodeAuthRequired        = "gateway.auth_required"
	errorCodeInvalidAccessToken  = "gateway.invalid_access_token"
	errorCodeInsufficientRole    = "gateway.insufficient_role"
	errorCodeInvalidRequest      = "gateway.invalid_request"
	errorCodeResourceNotFound    = "gateway.resource_not_found"
	errorCodeUpstreamUnavailable = "gateway.downstream_unavailable"
	errorCodeUserResolution      = "gateway.user_resolution_failed"
	errorCodeTechnical           = "gateway.technical"

	downstreamCodeAuthRequired   = "auth_required"
	downstreamCodeInvalidRequest = "invalid_request_body"
	downstreamCodeForbidden      = "forbidden"
	downstreamCodeNotFound       = "not_found"
	downstreamCodeRateLimited    = "rate_limited"
	downstreamCodeConflict       = "conflict"
	downstreamCodeMaintenance    = "technical_maintenance"
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
		errorCodeInvalidRequest: {
			title:   "Некорректный запрос",
			message: "Проверьте данные и повторите запрос.",
		},
		errorCodeResourceNotFound: {
			title:   "Данные не найдены",
			message: "Запрошенный объект не найден.",
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
		errorCodeInvalidRequest: {
			title:   "Invalid request",
			message: "Check the request data and try again.",
		},
		errorCodeResourceNotFound: {
			title:   "Not found",
			message: "The requested resource was not found.",
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
		errorCodeInvalidRequest: {
			title:   "Сұрау қате",
			message: "Деректерді тексеріп, қайта көріңіз.",
		},
		errorCodeResourceNotFound: {
			title:   "Деректер табылмады",
			message: "Сұралған объект табылмады.",
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

var localizedDownstreamErrors = map[string]map[string]localizedError{
	"ru": {
		downstreamCodeAuthRequired: {
			title:   "Требуется авторизация",
			message: "Войдите в аккаунт и повторите запрос.",
		},
		downstreamCodeInvalidRequest: {
			title:   "Некорректный запрос",
			message: "Проверьте данные и повторите запрос.",
		},
		downstreamCodeForbidden: {
			title:   "Доступ запрещён",
			message: "У вас нет доступа к этому действию.",
		},
		downstreamCodeNotFound: {
			title:   "Данные не найдены",
			message: "Запрошенный объект не найден.",
		},
		downstreamCodeRateLimited: {
			title:   "Слишком много запросов",
			message: "Попробуйте повторить запрос чуть позже.",
		},
		downstreamCodeConflict: {
			title:   "Конфликт данных",
			message: "Данные уже изменились. Обновите экран и попробуйте снова.",
		},
		downstreamCodeMaintenance: {
			title:   "Технические работы",
			message: "Сейчас проводятся технические работы. Попробуйте позже.",
		},
	},
	"en": {
		downstreamCodeAuthRequired: {
			title:   "Authentication required",
			message: "Sign in and try again.",
		},
		downstreamCodeInvalidRequest: {
			title:   "Invalid request",
			message: "Check the request data and try again.",
		},
		downstreamCodeForbidden: {
			title:   "Access denied",
			message: "You do not have access to this action.",
		},
		downstreamCodeNotFound: {
			title:   "Not found",
			message: "The requested resource was not found.",
		},
		downstreamCodeRateLimited: {
			title:   "Too many requests",
			message: "Please try again a little later.",
		},
		downstreamCodeConflict: {
			title:   "Data conflict",
			message: "The data has changed. Refresh the screen and try again.",
		},
		downstreamCodeMaintenance: {
			title:   "Maintenance",
			message: "Maintenance is in progress. Please try again later.",
		},
	},
	"kk": {
		downstreamCodeAuthRequired: {
			title:   "Авторизация қажет",
			message: "Аккаунтқа кіріп, сұрауды қайталаңыз.",
		},
		downstreamCodeInvalidRequest: {
			title:   "Сұрау қате",
			message: "Сұрауды тексеріп, қайталап көріңіз.",
		},
		downstreamCodeForbidden: {
			title:   "Қолжетімділікке тыйым салынды",
			message: "Бұл әрекетке қол жеткізу құқығыңыз жоқ.",
		},
		downstreamCodeNotFound: {
			title:   "Деректер табылмады",
			message: "Сұралған объект табылмады.",
		},
		downstreamCodeRateLimited: {
			title:   "Сұраулар тым көп",
			message: "Сәл кейінірек қайталап көріңіз.",
		},
		downstreamCodeConflict: {
			title:   "Деректер қақтығысы",
			message: "Деректер өзгерді. Экранды жаңартып, қайта көріңіз.",
		},
		downstreamCodeMaintenance: {
			title:   "Техникалық жұмыстар",
			message: "Қазір техникалық жұмыстар жүріп жатыр. Кейінірек қайталап көріңіз.",
		},
	},
}

var downstreamErrorAliases = map[string]string{
	"authentication_required":                   downstreamCodeAuthRequired,
	"auth_required":                             downstreamCodeAuthRequired,
	"gateway.auth_required":                     downstreamCodeAuthRequired,
	"invalid_access_token":                      downstreamCodeAuthRequired,
	"gateway.invalid_access_token":              downstreamCodeAuthRequired,
	"missing_authenticated_subject":             downstreamCodeAuthRequired,
	"missing authenticated subject":             downstreamCodeAuthRequired,
	"missing authenticated user":                downstreamCodeAuthRequired,
	"missing authenticated user context":        downstreamCodeAuthRequired,
	"request must come through trusted gateway": downstreamCodeAuthRequired,
	"unauthorized":                              downstreamCodeAuthRequired,

	"invalid_request":      downstreamCodeInvalidRequest,
	"invalid_request_body": downstreamCodeInvalidRequest,
	"invalid request":      downstreamCodeInvalidRequest,
	"invalid request body": downstreamCodeInvalidRequest,
	"invalid json body":    downstreamCodeInvalidRequest,

	"access_denied":           downstreamCodeForbidden,
	"forbidden":               downstreamCodeForbidden,
	"payment access denied":   downstreamCodeForbidden,
	"admin role is required":  downstreamCodeForbidden,
	"admin role required":     downstreamCodeForbidden,
	"moderator role required": downstreamCodeForbidden,

	"not_found":       downstreamCodeNotFound,
	"not found":       downstreamCodeNotFound,
	"route_not_found": downstreamCodeNotFound,

	"rate_limited":        downstreamCodeRateLimited,
	"rate_limit_exceeded": downstreamCodeRateLimited,
	"too many requests":   downstreamCodeRateLimited,

	"conflict":       downstreamCodeConflict,
	"data_conflict":  downstreamCodeConflict,
	"already_exists": downstreamCodeConflict,

	"technical_maintenance":          downstreamCodeMaintenance,
	"activity.technical_maintenance": downstreamCodeMaintenance,
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

func buildDownstreamErrorResponse(r *http.Request, status int, payload map[string]any) (errorResponse, bool) {
	if status < http.StatusBadRequest || payload == nil {
		return errorResponse{}, false
	}

	code := stringPayloadField(payload, "code")
	kind := stringPayloadField(payload, "kind")
	canonical, ok := canonicalDownstreamError(code)
	if !ok {
		canonical, ok = canonicalDownstreamError(stringPayloadField(payload, "error"))
	}
	if !ok {
		canonical, ok = canonicalDownstreamError(stringPayloadField(payload, "message"))
	}

	if kind == errorKindMaintenance || strings.HasSuffix(strings.ToLower(strings.TrimSpace(code)), ".technical_maintenance") {
		canonical = downstreamCodeMaintenance
		ok = true
		kind = errorKindMaintenance
	}
	if !ok {
		return errorResponse{}, false
	}

	entry, ok := lookupLocalizedDownstreamError(localeFromRequest(r), canonical)
	if !ok {
		return errorResponse{}, false
	}

	if strings.TrimSpace(code) == "" {
		code = canonical
	}
	if strings.TrimSpace(kind) == "" {
		kind = errorKindBusiness
	}

	return errorResponse{
		Error:   entry.title,
		Message: entry.message,
		Code:    code,
		Kind:    kind,
	}, true
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

func lookupLocalizedDownstreamError(locale string, code string) (localizedError, bool) {
	if messages, ok := localizedDownstreamErrors[locale]; ok {
		if entry, ok := messages[code]; ok {
			return entry, true
		}
	}
	if entry, ok := localizedDownstreamErrors["ru"][code]; ok {
		return entry, true
	}
	return localizedError{}, false
}

func canonicalDownstreamError(value string) (string, bool) {
	key := strings.ToLower(strings.TrimSpace(value))
	if key == "" {
		return "", false
	}
	if strings.HasSuffix(key, ".technical_maintenance") {
		return downstreamCodeMaintenance, true
	}
	canonical, ok := downstreamErrorAliases[key]
	return canonical, ok
}

func stringPayloadField(payload map[string]any, key string) string {
	value, ok := payload[key]
	if !ok {
		return ""
	}
	if text, ok := value.(string); ok {
		return strings.TrimSpace(text)
	}
	return ""
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
