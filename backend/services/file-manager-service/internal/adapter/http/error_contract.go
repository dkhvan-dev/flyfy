package http

import (
	"net/http"
	"strings"

	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/app"
)

const (
	errorKindBusiness  = "business"
	errorKindTechnical = "technical"

	errorCodeTechnical          = "technical_error"
	errorCodeNotFound           = "not_found"
	errorCodeInvalidRequestBody = "invalid_request_body"
	errorCodeUnauthorized       = "unauthorized"
	errorCodeForbidden          = "forbidden"
	errorCodePurposeRequired    = "purpose_required"
	errorCodeInvalidLimit       = "invalid_limit"
)

type errorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    string `json:"code"`
	Kind    string `json:"kind"`
}

type localizedError struct {
	Error   string
	Message string
}

var technicalErrorMessages = map[string]localizedError{
	"ru": {
		Error:   "Техническая ошибка",
		Message: "На сервере возникла проблема. Попробуйте позже.",
	},
	"en": {
		Error:   "Technical error",
		Message: "A server problem occurred. Please try again later.",
	},
	"kk": {
		Error:   "Техникалық қате",
		Message: "Серверде мәселе туындады. Кейінірек қайталап көріңіз.",
	},
}

var businessErrorMessages = map[string]map[string]string{
	"ru": {
		app.ErrorCodeFileNotFound:          "Файл не найден",
		app.ErrorCodeFileNotReady:          "Файл еще не готов",
		app.ErrorCodeFileNotPublic:         "Файл не публичный",
		app.ErrorCodeUploadTooLarge:        "Файл слишком большой",
		app.ErrorCodeInvalidOwnerID:        "Некорректный владелец",
		app.ErrorCodeInvalidFileID:         "Некорректный идентификатор файла",
		app.ErrorCodeForbiddenPurpose:      "Некорректное назначение файла",
		app.ErrorCodeForbiddenVisibility:   "Некорректная видимость файла",
		app.ErrorCodeForbiddenOwnerType:    "Некорректный тип владельца",
		app.ErrorCodeExtensionNotAllowed:   "Расширение файла не разрешено",
		app.ErrorCodeContentTypeNotAllowed: "Тип файла не разрешен",
		app.ErrorCodeFilenameRequired:      "Укажите имя файла",
		app.ErrorCodeContentTypeRequired:   "Укажите тип файла",
		app.ErrorCodeInvalidFileSize:       "Некорректный размер файла",
		app.ErrorCodeIdempotencyConflict:   "Конфликт идемпотентности",
		errorCodeNotFound:                  "Не найдено",
		errorCodeInvalidRequestBody:        "Некорректное тело запроса",
		errorCodeUnauthorized:              "Требуется авторизация",
		errorCodeForbidden:                 "Доступ запрещен",
		errorCodePurposeRequired:           "Укажите назначение файла",
		errorCodeInvalidLimit:              "Некорректный лимит",
	},
	"en": {
		app.ErrorCodeFileNotFound:          "File not found",
		app.ErrorCodeFileNotReady:          "File is not ready yet",
		app.ErrorCodeFileNotPublic:         "File is not public",
		app.ErrorCodeUploadTooLarge:        "File is too large",
		app.ErrorCodeInvalidOwnerID:        "Invalid owner",
		app.ErrorCodeInvalidFileID:         "Invalid file id",
		app.ErrorCodeForbiddenPurpose:      "Invalid file purpose",
		app.ErrorCodeForbiddenVisibility:   "Invalid file visibility",
		app.ErrorCodeForbiddenOwnerType:    "Invalid owner type",
		app.ErrorCodeExtensionNotAllowed:   "File extension is not allowed",
		app.ErrorCodeContentTypeNotAllowed: "File type is not allowed",
		app.ErrorCodeFilenameRequired:      "File name is required",
		app.ErrorCodeContentTypeRequired:   "Content type is required",
		app.ErrorCodeInvalidFileSize:       "Invalid file size",
		app.ErrorCodeIdempotencyConflict:   "Idempotency conflict",
		errorCodeNotFound:                  "Not found",
		errorCodeInvalidRequestBody:        "Invalid request body",
		errorCodeUnauthorized:              "Authentication is required",
		errorCodeForbidden:                 "Access denied",
		errorCodePurposeRequired:           "File purpose is required",
		errorCodeInvalidLimit:              "Invalid limit",
	},
	"kk": {
		app.ErrorCodeFileNotFound:          "Файл табылмады",
		app.ErrorCodeFileNotReady:          "Файл әлі дайын емес",
		app.ErrorCodeFileNotPublic:         "Файл ашық емес",
		app.ErrorCodeUploadTooLarge:        "Файл тым үлкен",
		app.ErrorCodeInvalidOwnerID:        "Иесі некоррект",
		app.ErrorCodeInvalidFileID:         "Файл идентификаторы некоррект",
		app.ErrorCodeForbiddenPurpose:      "Файл мақсаты некоррект",
		app.ErrorCodeForbiddenVisibility:   "Файл көрінуі некоррект",
		app.ErrorCodeForbiddenOwnerType:    "Ие түрі некоррект",
		app.ErrorCodeExtensionNotAllowed:   "Файл кеңейтіміне рұқсат жоқ",
		app.ErrorCodeContentTypeNotAllowed: "Файл түріне рұқсат жоқ",
		app.ErrorCodeFilenameRequired:      "Файл атауын көрсетіңіз",
		app.ErrorCodeContentTypeRequired:   "Файл түрін көрсетіңіз",
		app.ErrorCodeInvalidFileSize:       "Файл өлшемі некоррект",
		app.ErrorCodeIdempotencyConflict:   "Идемпотенттілік қақтығысы",
		errorCodeNotFound:                  "Табылмады",
		errorCodeInvalidRequestBody:        "Сұрау денесі некоррект",
		errorCodeUnauthorized:              "Авторизация қажет",
		errorCodeForbidden:                 "Қолжетімділікке тыйым салынған",
		errorCodePurposeRequired:           "Файл мақсатын көрсетіңіз",
		errorCodeInvalidLimit:              "Лимит некоррект",
	},
}

func writeBusinessError(w http.ResponseWriter, r *http.Request, status int, code string) {
	lang := preferredLanguage(r)
	message := localizedBusinessMessage(lang, code)
	writeJSON(w, status, errorResponse{
		Error:   message,
		Message: message,
		Code:    code,
		Kind:    errorKindBusiness,
	})
}

func writeAppError(w http.ResponseWriter, r *http.Request, status int, err error) {
	code, ok := app.BusinessErrorCode(err)
	if !ok {
		writeTechnicalError(w, r, status, err)
		return
	}
	writeBusinessError(w, r, status, code)
}

func writeTechnicalError(w http.ResponseWriter, r *http.Request, status int, err error) {
	log.Error().
		Err(err).
		Str("transport", "http").
		Str("method", r.Method).
		Str("path", r.URL.Path).
		Str("request_id", RequestIDFromContext(r.Context())).
		Int("status", status).
		Msg("http technical error")

	msg := technicalErrorMessages[preferredLanguage(r)]
	writeJSON(w, status, errorResponse{
		Error:   msg.Error,
		Message: msg.Message,
		Code:    errorCodeTechnical,
		Kind:    errorKindTechnical,
	})
}

func preferredLanguage(r *http.Request) string {
	if r == nil {
		return "ru"
	}
	for _, candidate := range strings.Split(r.Header.Get("Accept-Language"), ",") {
		tag := strings.ToLower(strings.TrimSpace(candidate))
		if tag == "" {
			continue
		}
		if i := strings.Index(tag, ";"); i >= 0 {
			tag = strings.TrimSpace(tag[:i])
		}
		if i := strings.Index(tag, "-"); i >= 0 {
			tag = tag[:i]
		}
		switch tag {
		case "ru", "en", "kk":
			return tag
		}
	}
	return "ru"
}

func localizedBusinessMessage(lang string, code string) string {
	if messages, ok := businessErrorMessages[lang]; ok {
		if message, ok := messages[code]; ok {
			return message
		}
	}
	if message, ok := businessErrorMessages["ru"][code]; ok {
		return message
	}
	return businessErrorMessages["ru"][errorCodeInvalidRequestBody]
}
