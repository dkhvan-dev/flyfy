package http

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/stories-service/internal/app"
)

const (
	errorKindBusiness  = "business"
	errorKindTechnical = "technical"

	errorCodeTechnical             = "technical_error"
	errorCodeInvalidAuthorID       = "invalid_author_id"
	errorCodeInvalidRequestBody    = "invalid_request_body"
	errorCodeInvalidCoverFileID    = "invalid_cover_file_id"
	errorCodeNotFound              = "not_found"
	errorCodeInvalidStoryID        = "invalid_story_id"
	errorCodeInvalidCommentID      = "invalid_comment_id"
	errorCodeInvalidUserID         = "invalid_user_id"
	errorCodeInvalidLimit          = "invalid_limit"
	errorCodeInvalidOffset         = "invalid_offset"
	errorCodeInvalidStoryAuthorID  = "invalid_story_author_id"
	errorCodeInvalidStoryTitle     = "invalid_story_title"
	errorCodeInvalidStoryContent   = "invalid_story_content"
	errorCodeInvalidStoryFormat    = "invalid_story_format"
	errorCodeInvalidStoryCategory  = "invalid_story_category"
	errorCodeInvalidStoryStatus    = "invalid_story_status"
	errorCodeInvalidStoryTags      = "invalid_story_tags"
	errorCodeInvalidStoryPlace     = "invalid_story_place"
	errorCodeInvalidStoryCover     = "invalid_story_cover"
	errorCodeStoryValidationFailed = "story_validation_failed"
	errorCodeStoryRevisionConflict = "story_revision_conflict"
	errorCodeInvalidCommentBody    = "invalid_comment_body"
	errorCodeCommentRateLimited    = "story_comment_rate_limited"
	errorCodeUnauthenticatedWriter = "missing_authenticated_subject"
	errorCodeStoryAccessDenied     = "story_access_denied"
	errorCodeCommentAccessDenied   = "story_comment_access_denied"
	errorCodeStoryNotFound         = "story_not_found"
	errorCodeCommentNotFound       = "story_comment_not_found"
	errorCodeUserNotFound          = "user_not_found"
	errorCodeCannotLikeOwnStory    = "cannot_like_own_story"
	errorCodeCannotCommentDeleted  = "cannot_comment_deleted_story"
	errorCodeCannotViewOwnStory    = "cannot_view_own_story"
)

type errorResponse struct {
	Error   string            `json:"error"`
	Message string            `json:"message"`
	Code    string            `json:"code"`
	Kind    string            `json:"kind"`
	Fields  map[string]string `json:"fields,omitempty"`
}

type localizedError struct {
	Error   string
	Message string
}

type mappedError struct {
	status int
	code   string
}

func (h *Handler) writeUseCaseError(w http.ResponseWriter, r *http.Request, err error) {
	if mapped, ok := mapBusinessError(err); ok {
		if validationFields := validationFieldsForError(err); len(validationFields) > 0 {
			writeErrorWithFields(w, r, mapped.status, mapped.code, validationFields)
			return
		}
		writeError(w, r, mapped.status, mapped.code)
		return
	}

	writeTechnicalError(w, r, err)
}

func validationFieldsForError(err error) map[string]string {
	var validationErr *app.StoryValidationError
	if !errors.As(err, &validationErr) {
		return nil
	}
	return validationErr.Fields
}

func writeError(w http.ResponseWriter, r *http.Request, status int, code string) {
	writeErrorWithFields(w, r, status, code, nil)
}

func writeErrorWithFields(w http.ResponseWriter, r *http.Request, status int, code string, fields map[string]string) {
	text := businessErrorText(code, localeFromRequest(r))
	writeJSON(w, status, errorResponse{
		Error:   text.Error,
		Message: text.Message,
		Code:    code,
		Kind:    errorKindBusiness,
		Fields:  fields,
	})
}

func writeTechnicalError(w http.ResponseWriter, r *http.Request, err error) {
	if err != nil {
		event := log.Error().
			Err(err).
			Str("transport", "http")
		if r != nil {
			event = event.
				Str("method", r.Method).
				Str("path", r.URL.Path).
				Str("request_id", RequestIDFromContext(r.Context()))
		}
		event.Msg("stories-service technical error")
	}

	text := technicalErrorText(localeFromRequest(r))
	writeJSON(w, http.StatusInternalServerError, errorResponse{
		Error:   text.Error,
		Message: text.Message,
		Code:    errorCodeTechnical,
		Kind:    errorKindTechnical,
	})
}

func mapBusinessError(err error) (mappedError, bool) {
	switch {
	case errors.Is(err, app.ErrInvalidStoryID):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidStoryID}, true
	case errors.Is(err, app.ErrInvalidStoryAuthorID):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidStoryAuthorID}, true
	case errors.Is(err, app.ErrInvalidCommentID):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidCommentID}, true
	case errors.Is(err, app.ErrStoryValidationFailed):
		return mappedError{status: http.StatusBadRequest, code: errorCodeStoryValidationFailed}, true
	case errors.Is(err, app.ErrInvalidStoryTitle):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidStoryTitle}, true
	case errors.Is(err, app.ErrInvalidStoryContent):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidStoryContent}, true
	case errors.Is(err, app.ErrInvalidStoryFormat):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidStoryFormat}, true
	case errors.Is(err, app.ErrInvalidStoryCategory):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidStoryCategory}, true
	case errors.Is(err, app.ErrInvalidStoryStatus):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidStoryStatus}, true
	case errors.Is(err, app.ErrInvalidStoryTags):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidStoryTags}, true
	case errors.Is(err, app.ErrInvalidStoryPlace):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidStoryPlace}, true
	case errors.Is(err, app.ErrInvalidStoryCover):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidStoryCover}, true
	case errors.Is(err, app.ErrStoryRevisionConflict):
		return mappedError{status: http.StatusConflict, code: errorCodeStoryRevisionConflict}, true
	case errors.Is(err, app.ErrInvalidCommentBody):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidCommentBody}, true
	case errors.Is(err, app.ErrStoryCommentRateLimited):
		return mappedError{status: http.StatusBadRequest, code: errorCodeCommentRateLimited}, true
	case errors.Is(err, app.ErrCannotLikeOwnStory):
		return mappedError{status: http.StatusBadRequest, code: errorCodeCannotLikeOwnStory}, true
	case errors.Is(err, app.ErrCannotCommentOwnDeleted):
		return mappedError{status: http.StatusBadRequest, code: errorCodeCannotCommentDeleted}, true
	case errors.Is(err, app.ErrCannotViewOwnStoryAsViewer):
		return mappedError{status: http.StatusBadRequest, code: errorCodeCannotViewOwnStory}, true
	case errors.Is(err, app.ErrUnauthenticatedWriter):
		return mappedError{status: http.StatusUnauthorized, code: errorCodeUnauthenticatedWriter}, true
	case errors.Is(err, app.ErrStoryAccessDenied):
		return mappedError{status: http.StatusForbidden, code: errorCodeStoryAccessDenied}, true
	case errors.Is(err, app.ErrStoryCommentAccessDenied):
		return mappedError{status: http.StatusForbidden, code: errorCodeCommentAccessDenied}, true
	case errors.Is(err, app.ErrStoryNotFound):
		return mappedError{status: http.StatusNotFound, code: errorCodeStoryNotFound}, true
	case errors.Is(err, app.ErrStoryCommentNotFound):
		return mappedError{status: http.StatusNotFound, code: errorCodeCommentNotFound}, true
	case errors.Is(err, app.ErrUserNotFound):
		return mappedError{status: http.StatusNotFound, code: errorCodeUserNotFound}, true
	default:
		return mappedError{}, false
	}
}

func localeFromRequest(r *http.Request) string {
	if r == nil {
		return "ru"
	}

	selected := ""
	selectedQuality := -1.0
	for _, item := range strings.Split(r.Header.Get("Accept-Language"), ",") {
		lang, quality := parseAcceptLanguageItem(item)
		if quality <= 0 || quality <= selectedQuality {
			continue
		}

		switch lang {
		case "ru", "en", "kk":
			selected = lang
			selectedQuality = quality
		}
	}

	if selected != "" {
		return selected
	}
	return "ru"
}

func parseAcceptLanguageItem(item string) (string, float64) {
	parts := strings.Split(item, ";")
	lang := strings.ToLower(strings.ReplaceAll(strings.TrimSpace(parts[0]), "_", "-"))
	if idx := strings.Index(lang, "-"); idx >= 0 {
		lang = lang[:idx]
	}
	if lang == "" {
		return "", 0
	}

	quality := 1.0
	for _, rawParam := range parts[1:] {
		param := strings.ToLower(strings.TrimSpace(rawParam))
		if !strings.HasPrefix(param, "q=") {
			continue
		}
		parsed, err := strconv.ParseFloat(strings.TrimSpace(strings.TrimPrefix(param, "q=")), 64)
		if err != nil || parsed < 0 || parsed > 1 {
			return "", 0
		}
		quality = parsed
	}

	return lang, quality
}

var businessErrorMessages = map[string]map[string]string{
	errorCodeInvalidAuthorID: {
		"ru": "Некорректный автор.",
		"en": "Invalid author.",
		"kk": "Автор дұрыс емес.",
	},
	errorCodeInvalidRequestBody: {
		"ru": "Некорректное тело запроса.",
		"en": "Invalid request body.",
		"kk": "Сұрау денесі дұрыс емес.",
	},
	errorCodeInvalidCoverFileID: {
		"ru": "Некорректная обложка.",
		"en": "Invalid cover image.",
		"kk": "Мұқаба дұрыс емес.",
	},
	errorCodeNotFound: {
		"ru": "Не найдено.",
		"en": "Not found.",
		"kk": "Табылмады.",
	},
	errorCodeInvalidStoryID: {
		"ru": "Некорректная история.",
		"en": "Invalid story.",
		"kk": "Оқиға дұрыс емес.",
	},
	errorCodeInvalidCommentID: {
		"ru": "Некорректный комментарий.",
		"en": "Invalid comment.",
		"kk": "Пікір дұрыс емес.",
	},
	errorCodeInvalidUserID: {
		"ru": "Некорректный пользователь.",
		"en": "Invalid user.",
		"kk": "Пайдаланушы дұрыс емес.",
	},
	errorCodeInvalidLimit: {
		"ru": "Некорректный лимит.",
		"en": "Invalid limit.",
		"kk": "Лимит дұрыс емес.",
	},
	errorCodeInvalidOffset: {
		"ru": "Некорректное смещение.",
		"en": "Invalid offset.",
		"kk": "Ығысу дұрыс емес.",
	},
	errorCodeInvalidStoryAuthorID: {
		"ru": "Некорректный автор истории.",
		"en": "Invalid story author.",
		"kk": "Оқиға авторы дұрыс емес.",
	},
	errorCodeInvalidStoryTitle: {
		"ru": "Проверьте заголовок истории.",
		"en": "Check the story title.",
		"kk": "Оқиға тақырыбын тексеріңіз.",
	},
	errorCodeInvalidStoryContent: {
		"ru": "Проверьте текст истории.",
		"en": "Check the story text.",
		"kk": "Оқиға мәтінін тексеріңіз.",
	},
	errorCodeInvalidStoryCategory: {
		"ru": "Некорректная категория истории.",
		"en": "Invalid story category.",
		"kk": "Оқиға санаты дұрыс емес.",
	},
	errorCodeInvalidStoryFormat: {
		"ru": "Некорректный тип материала.",
		"en": "Invalid story format.",
		"kk": "Материал түрі дұрыс емес.",
	},
	errorCodeInvalidStoryStatus: {
		"ru": "Некорректный статус истории.",
		"en": "Invalid story status.",
		"kk": "Оқиға мәртебесі дұрыс емес.",
	},
	errorCodeInvalidStoryTags: {
		"ru": "Проверьте теги истории.",
		"en": "Check the story tags.",
		"kk": "Оқиға тегтерін тексеріңіз.",
	},
	errorCodeInvalidStoryPlace: {
		"ru": "Проверьте место истории.",
		"en": "Check the story place.",
		"kk": "Оқиға орнын тексеріңіз.",
	},
	errorCodeInvalidStoryCover: {
		"ru": "Для публикации нужна обложка.",
		"en": "A cover image is required to publish.",
		"kk": "Жариялау үшін мұқаба қажет.",
	},
	errorCodeStoryValidationFailed: {
		"ru": "Проверьте обязательные поля истории.",
		"en": "Check the required story fields.",
		"kk": "Оқиғаның міндетті өрістерін тексеріңіз.",
	},
	errorCodeStoryRevisionConflict: {
		"ru": "История была изменена. Обновите данные и попробуйте снова.",
		"en": "The story was changed. Refresh it and try again.",
		"kk": "Оқиға өзгертілді. Деректерді жаңартып, қайталап көріңіз.",
	},
	errorCodeInvalidCommentBody: {
		"ru": "Проверьте текст комментария.",
		"en": "Check the comment text.",
		"kk": "Пікір мәтінін тексеріңіз.",
	},
	errorCodeCommentRateLimited: {
		"ru": "Комментарий можно оставить позже.",
		"en": "You can comment later.",
		"kk": "Пікірді кейінірек қалдыра аласыз.",
	},
	errorCodeUnauthenticatedWriter: {
		"ru": "Необходима авторизация.",
		"en": "Authentication is required.",
		"kk": "Авторизация қажет.",
	},
	errorCodeStoryAccessDenied: {
		"ru": "Нет доступа к истории.",
		"en": "You do not have access to this story.",
		"kk": "Бұл оқиғаға қолжетімділік жоқ.",
	},
	errorCodeCommentAccessDenied: {
		"ru": "Нет доступа к комментарию.",
		"en": "You do not have access to this comment.",
		"kk": "Бұл пікірге қолжетімділік жоқ.",
	},
	errorCodeStoryNotFound: {
		"ru": "История не найдена.",
		"en": "Story not found.",
		"kk": "Оқиға табылмады.",
	},
	errorCodeCommentNotFound: {
		"ru": "Комментарий не найден.",
		"en": "Comment not found.",
		"kk": "Пікір табылмады.",
	},
	errorCodeUserNotFound: {
		"ru": "Пользователь не найден.",
		"en": "User not found.",
		"kk": "Пайдаланушы табылмады.",
	},
	errorCodeCannotLikeOwnStory: {
		"ru": "Нельзя лайкнуть свою историю.",
		"en": "You cannot like your own story.",
		"kk": "Өз оқиғаңызға лайк қоюға болмайды.",
	},
	errorCodeCannotCommentDeleted: {
		"ru": "Нельзя комментировать удалённую историю.",
		"en": "You cannot comment on a deleted story.",
		"kk": "Жойылған оқиғаға пікір қалдыруға болмайды.",
	},
	errorCodeCannotViewOwnStory: {
		"ru": "Просмотры автора не учитываются.",
		"en": "Author views are not counted.",
		"kk": "Автордың қаралымдары есептелмейді.",
	},
}

func businessErrorText(code string, locale string) localizedError {
	message := localizedMessage(businessErrorMessages, code, locale)
	return localizedError{Error: message, Message: message}
}

func technicalErrorText(locale string) localizedError {
	switch locale {
	case "en":
		return localizedError{
			Error:   "Technical error",
			Message: "Something went wrong on the server. Please try again later.",
		}
	case "kk":
		return localizedError{
			Error:   "Техникалық қате",
			Message: "Серверде мәселе туындады. Кейінірек қайталап көріңіз.",
		}
	default:
		return localizedError{
			Error:   "Техническая ошибка",
			Message: "На сервере возникла проблема. Попробуйте позже.",
		}
	}
}

func localizedMessage(texts map[string]map[string]string, code string, locale string) string {
	if byLocale, ok := texts[code]; ok {
		if message, ok := byLocale[locale]; ok {
			return message
		}
		if message, ok := byLocale["ru"]; ok {
			return message
		}
	}
	return texts[errorCodeInvalidRequestBody]["ru"]
}
