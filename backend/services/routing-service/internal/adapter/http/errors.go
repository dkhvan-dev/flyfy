package http

import (
	"errors"
	"net/http"
	"strings"

	"golang.org/x/text/language"

	"kz/inflap/backend/services/routing-service/internal/app"
	"kz/inflap/backend/services/routing-service/internal/domain/model"
)

const (
	errorKindBusiness  = "business"
	errorKindTechnical = "technical"

	errorCodeInvalidRequest     = "routing.invalid_request"
	errorCodeRouteNotFound      = "routing.route_not_found"
	errorCodeTransitUnavailable = "routing.transit_unavailable"
	errorCodeEngineUnavailable  = "routing.engine_unavailable"
	errorCodeTechnical          = "routing.technical"

	defaultErrorLang = "ru"
)

var acceptLanguageMatcher = language.NewMatcher([]language.Tag{
	language.Russian,
	language.English,
	language.Kazakh,
})

type errorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    string `json:"code"`
	Kind    string `json:"kind"`
}

type localizedErrorMessage struct {
	Error   string
	Message string
}

var errorMessages = map[string]map[string]localizedErrorMessage{
	errorCodeInvalidRequest: {
		"ru": {Error: "Некорректный маршрут", Message: "Проверьте точки маршрута и выбранный режим."},
		"en": {Error: "Invalid route request", Message: "Check route points and selected travel mode."},
		"kk": {Error: "Маршрут сұрауы қате", Message: "Маршрут нүктелері мен қозғалыс режимін тексеріңіз."},
	},
	errorCodeRouteNotFound: {
		"ru": {Error: "Маршрут не найден", Message: "Запрошенный routing-маршрут не существует."},
		"en": {Error: "Route not found", Message: "The requested routing route does not exist."},
		"kk": {Error: "Маршрут табылмады", Message: "Сұралған routing маршруты жоқ."},
	},
	errorCodeTransitUnavailable: {
		"ru": {Error: "Транспорт недоступен", Message: "Маршруты на общественном транспорте пока недоступны для этого города."},
		"en": {Error: "Transit unavailable", Message: "Public transport routing is not available for this city yet."},
		"kk": {Error: "Қоғамдық көлік қолжетімсіз", Message: "Бұл қалада қоғамдық көлік маршруты әзірге қолжетімсіз."},
	},
	errorCodeEngineUnavailable: {
		"ru": {Error: "Маршрутизация недоступна", Message: "Сервис маршрутов временно недоступен. Попробуйте позже или откройте внешнюю карту."},
		"en": {Error: "Routing unavailable", Message: "Routing is temporarily unavailable. Try later or open an external map."},
		"kk": {Error: "Маршруттау қолжетімсіз", Message: "Маршруттау уақытша қолжетімсіз. Кейінірек қайталаңыз немесе сыртқы картаны ашыңыз."},
	},
	errorCodeTechnical: {
		"ru": {Error: "Техническая ошибка", Message: "На сервере возникла проблема. Попробуйте позже."},
		"en": {Error: "Technical error", Message: "A server problem occurred. Please try again later."},
		"kk": {Error: "Техникалық қате", Message: "Серверде мәселе туындады. Кейінірек қайталап көріңіз."},
	},
}

func writeAppError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, model.ErrInvalidRequest), errors.Is(err, model.ErrInvalidCoordinates):
		writeErrorResponse(w, http.StatusBadRequest, errorCodeInvalidRequest, errorKindBusiness, parseErrorLang(r))
	case errors.Is(err, app.ErrTransitUnavailable):
		writeErrorResponse(w, http.StatusServiceUnavailable, errorCodeTransitUnavailable, errorKindBusiness, parseErrorLang(r))
	case errors.Is(err, app.ErrEngineUnavailable):
		writeErrorResponse(w, http.StatusServiceUnavailable, errorCodeEngineUnavailable, errorKindTechnical, parseErrorLang(r))
	default:
		writeErrorResponse(w, http.StatusInternalServerError, errorCodeTechnical, errorKindTechnical, parseErrorLang(r))
	}
}

func writeBusinessError(w http.ResponseWriter, r *http.Request, status int, code string) {
	writeErrorResponse(w, status, code, errorKindBusiness, parseErrorLang(r))
}

func writeTechnicalError(w http.ResponseWriter, r *http.Request) {
	writeErrorResponse(w, http.StatusInternalServerError, errorCodeTechnical, errorKindTechnical, parseErrorLang(r))
}

func writeErrorResponse(w http.ResponseWriter, status int, code string, kind string, lang string) {
	if kind != errorKindBusiness && kind != errorKindTechnical {
		kind = errorKindTechnical
	}
	if _, ok := errorMessages[code]; !ok {
		kind = errorKindTechnical
	}
	if kind == errorKindTechnical && code != errorCodeEngineUnavailable {
		code = errorCodeTechnical
	}

	message := localizedError(code, lang)
	writeJSON(w, status, errorResponse{
		Error:   message.Error,
		Message: message.Message,
		Code:    code,
		Kind:    kind,
	})
}

func localizedError(code string, lang string) localizedErrorMessage {
	byLang, ok := errorMessages[code]
	if !ok {
		byLang = errorMessages[errorCodeTechnical]
	}

	lang = normalizeSupportedLang(lang)
	message, ok := byLang[lang]
	if ok {
		return message
	}

	return byLang[defaultErrorLang]
}

func parseErrorLang(r *http.Request) string {
	if lang, ok := supportedLang(r.URL.Query().Get("lang")); ok {
		return lang
	}
	return parseAcceptLanguage(r.Header.Get("Accept-Language"))
}

func normalizeSupportedLang(lang string) string {
	if supported, ok := supportedLang(lang); ok {
		return supported
	}
	return defaultErrorLang
}

func supportedLang(lang string) (string, bool) {
	normalized := strings.ToLower(strings.TrimSpace(lang))
	switch normalized {
	case "ru", "en", "kk":
		return normalized, true
	default:
		return "", false
	}
}

func parseAcceptLanguage(header string) string {
	tags, _, err := language.ParseAcceptLanguage(header)
	if err != nil || len(tags) == 0 {
		return defaultErrorLang
	}

	tag, _, confidence := acceptLanguageMatcher.Match(tags...)
	if confidence == language.No {
		return defaultErrorLang
	}

	base, _ := tag.Base()
	return normalizeSupportedLang(base.String())
}
