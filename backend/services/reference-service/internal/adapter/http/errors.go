package http

import (
	"net/http"
	"strings"

	"golang.org/x/text/language"
)

const (
	errorKindBusiness  = "business"
	errorKindTechnical = "technical"

	errorCodeCountryNotFound            = "reference.country_not_found"
	errorCodeCityNotFound               = "reference.city_not_found"
	errorCodeCurrencyNotFound           = "reference.currency_not_found"
	errorCodeCurrencyForCountryNotFound = "reference.currency_for_country_not_found"
	errorCodeRouteNotFound              = "reference.route_not_found"
	errorCodeTechnical                  = "reference.technical"

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
	errorCodeCountryNotFound: {
		"ru": {Error: "Страна не найдена", Message: "Страна с указанным кодом не найдена."},
		"en": {Error: "Country not found", Message: "No country found for the requested code."},
		"kk": {Error: "Ел табылмады", Message: "Көрсетілген код бойынша ел табылмады."},
	},
	errorCodeCityNotFound: {
		"ru": {Error: "Город не найден", Message: "Город с указанным id не найден."},
		"en": {Error: "City not found", Message: "No city found for the requested id."},
		"kk": {Error: "Қала табылмады", Message: "Көрсетілген id бойынша қала табылмады."},
	},
	errorCodeCurrencyNotFound: {
		"ru": {Error: "Валюта не найдена", Message: "Валюта с указанным кодом не найдена."},
		"en": {Error: "Currency not found", Message: "No currency found for the requested code."},
		"kk": {Error: "Валюта табылмады", Message: "Көрсетілген код бойынша валюта табылмады."},
	},
	errorCodeCurrencyForCountryNotFound: {
		"ru": {Error: "Валюта страны не найдена", Message: "Валюта для указанной страны не найдена."},
		"en": {Error: "Currency for country not found", Message: "No currency found for the requested country."},
		"kk": {Error: "Ел валютасы табылмады", Message: "Көрсетілген ел үшін валюта табылмады."},
	},
	errorCodeRouteNotFound: {
		"ru": {Error: "Маршрут не найден", Message: "Запрошенный reference-маршрут не существует."},
		"en": {Error: "Route not found", Message: "The requested reference route does not exist."},
		"kk": {Error: "Маршрут табылмады", Message: "Сұралған reference маршруты жоқ."},
	},
	errorCodeTechnical: {
		"ru": {Error: "Техническая ошибка", Message: "На сервере возникла проблема. Попробуйте позже."},
		"en": {Error: "Technical error", Message: "A server problem occurred. Please try again later."},
		"kk": {Error: "Техникалық қате", Message: "Серверде мәселе туындады. Кейінірек қайталап көріңіз."},
	},
}

func writeBusinessError(w http.ResponseWriter, r *http.Request, status int, code string) {
	writeErrorResponse(w, status, code, errorKindBusiness, parseErrorLang(r))
}

func writeTechnicalError(w http.ResponseWriter, r *http.Request) {
	writeErrorResponse(w, http.StatusInternalServerError, errorCodeTechnical, errorKindTechnical, parseErrorLang(r))
}

func writeError(w http.ResponseWriter, status int, _ string) {
	writeErrorResponse(w, status, errorCodeTechnical, errorKindTechnical, defaultErrorLang)
}

func writeErrorResponse(w http.ResponseWriter, status int, code string, kind string, lang string) {
	if kind != errorKindBusiness && kind != errorKindTechnical {
		kind = errorKindTechnical
	}
	if _, ok := errorMessages[code]; !ok {
		kind = errorKindTechnical
	}
	if kind == errorKindTechnical {
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

func recoverPanic(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if recover() != nil {
				writeTechnicalError(w, r)
			}
		}()

		next.ServeHTTP(w, r)
	})
}

func RecoverPanic(next http.Handler) http.Handler {
	return recoverPanic(next)
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
