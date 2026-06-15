package http

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/feed-service/internal/app"
)

const (
	errorKindBusiness  = "business"
	errorKindTechnical = "technical"

	errorCodeTechnical                    = "technical_error"
	errorCodeInvalidAuthorID              = "invalid_author_id"
	errorCodeInvalidRequestBody           = "invalid_request_body"
	errorCodeInvalidCoverFileID           = "invalid_cover_file_id"
	errorCodeInvalidCommunityID           = "invalid_community_id"
	errorCodeNotFound                     = "not_found"
	errorCodeInvalidPostID                = "invalid_post_id"
	errorCodeInvalidCommentID             = "invalid_comment_id"
	errorCodeInvalidUserID                = "invalid_user_id"
	errorCodeInvalidLimit                 = "invalid_limit"
	errorCodeInvalidOffset                = "invalid_offset"
	errorCodeInvalidFeedCursor            = "invalid_feed_cursor"
	errorCodeInvalidFeedEvent             = "invalid_feed_event"
	errorCodeInvalidPostAuthorID          = "invalid_post_author_id"
	errorCodeInvalidPostTitle             = "invalid_post_title"
	errorCodeInvalidPostContent           = "invalid_post_content"
	errorCodeInvalidPostFormat            = "invalid_post_format"
	errorCodeInvalidPostCategory          = "invalid_post_category"
	errorCodeInvalidPostStatus            = "invalid_post_status"
	errorCodeInvalidPostTags              = "invalid_post_tags"
	errorCodeInvalidPostPlace             = "invalid_post_place"
	errorCodeInvalidPostCover             = "invalid_post_cover"
	errorCodeInvalidPostMedia             = "invalid_post_media"
	errorCodePostValidationFailed         = "post_validation_failed"
	errorCodePostRevisionConflict         = "post_revision_conflict"
	errorCodePostRateLimited              = "post_rate_limited"
	errorCodeInvalidCommentBody           = "invalid_comment_body"
	errorCodeCommentRateLimited           = "post_comment_rate_limited"
	errorCodeUnauthenticatedWriter        = "missing_authenticated_subject"
	errorCodePostAccessDenied             = "post_access_denied"
	errorCodeCommunityPostingDenied       = "community_posting_denied"
	errorCodeCommunityModerationDenied    = "community_moderation_denied"
	errorCodeCommunityFollowDenied        = "community_follow_denied"
	errorCodeCommunityInteractionDenied   = "community_interaction_denied"
	errorCodeCommunityRoleChangeDenied    = "community_role_change_denied"
	errorCodeCommunityMemberManageDenied  = "community_member_management_denied"
	errorCodeCommunityMembershipNotFound  = "community_membership_not_found"
	errorCodeCommentAccessDenied          = "post_comment_access_denied"
	errorCodeInvalidModerationDecision    = "invalid_moderation_decision"
	errorCodeInvalidPostReportReason      = "invalid_post_report_reason"
	errorCodeInvalidPostReportStatus      = "invalid_post_report_status"
	errorCodeInvalidPostReportDetails     = "invalid_post_report_details"
	errorCodeInvalidPostReportDecision    = "invalid_post_report_decision"
	errorCodeInvalidPostReportResolution  = "invalid_post_report_resolution"
	errorCodeDeprecatedEndpoint           = "deprecated_endpoint"
	errorCodePostReportOwnContent         = "post_report_own_content"
	errorCodePostReportNotFound           = "post_report_not_found"
	errorCodePostReportAlreadyResolved    = "post_report_already_resolved"
	errorCodeInvalidCommunityMemberRole   = "invalid_community_member_role"
	errorCodeInvalidCommunityMemberStatus = "invalid_community_member_status"
	errorCodePostNotFound                 = "post_not_found"
	errorCodeCommunityNotFound            = "community_not_found"
	errorCodeCommentNotFound              = "post_comment_not_found"
	errorCodeUserNotFound                 = "user_not_found"
	errorCodeCannotLikeOwnPost            = "cannot_like_own_post"
	errorCodeCannotLikeOwnStory           = "cannot_like_own_story"
	errorCodeCannotCommentDeleted         = "cannot_comment_deleted_post"
	errorCodeCannotViewOwnPost            = "cannot_view_own_post"
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
	var validationErr *app.PostValidationError
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
		event.Msg("feed-service technical error")
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
	case errors.Is(err, app.ErrInvalidPostID):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostID}, true
	case errors.Is(err, app.ErrInvalidCommunityID):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidCommunityID}, true
	case errors.Is(err, app.ErrInvalidUserID):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidUserID}, true
	case errors.Is(err, app.ErrInvalidFeedCursor):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidFeedCursor}, true
	case errors.Is(err, app.ErrInvalidFeedEvent):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidFeedEvent}, true
	case errors.Is(err, app.ErrInvalidPostAuthorID):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostAuthorID}, true
	case errors.Is(err, app.ErrInvalidCommentID):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidCommentID}, true
	case errors.Is(err, app.ErrPostValidationFailed):
		return mappedError{status: http.StatusBadRequest, code: errorCodePostValidationFailed}, true
	case errors.Is(err, app.ErrInvalidPostTitle):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostTitle}, true
	case errors.Is(err, app.ErrInvalidPostContent):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostContent}, true
	case errors.Is(err, app.ErrInvalidPostFormat):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostFormat}, true
	case errors.Is(err, app.ErrInvalidPostCategory):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostCategory}, true
	case errors.Is(err, app.ErrInvalidPostStatus):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostStatus}, true
	case errors.Is(err, app.ErrInvalidPostTags):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostTags}, true
	case errors.Is(err, app.ErrInvalidPostPlace):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostPlace}, true
	case errors.Is(err, app.ErrInvalidPostCover):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostCover}, true
	case errors.Is(err, app.ErrInvalidPostMedia):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostMedia}, true
	case errors.Is(err, app.ErrPostRevisionConflict):
		return mappedError{status: http.StatusConflict, code: errorCodePostRevisionConflict}, true
	case errors.Is(err, app.ErrPostRateLimited):
		return mappedError{status: http.StatusTooManyRequests, code: errorCodePostRateLimited}, true
	case errors.Is(err, app.ErrInvalidCommentBody):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidCommentBody}, true
	case errors.Is(err, app.ErrPostCommentRateLimited):
		return mappedError{status: http.StatusBadRequest, code: errorCodeCommentRateLimited}, true
	case errors.Is(err, app.ErrCannotLikeOwnPost):
		return mappedError{status: http.StatusBadRequest, code: errorCodeCannotLikeOwnPost}, true
	case errors.Is(err, app.ErrCannotLikeOwnStory):
		return mappedError{status: http.StatusBadRequest, code: errorCodeCannotLikeOwnStory}, true
	case errors.Is(err, app.ErrCannotCommentOwnDeleted):
		return mappedError{status: http.StatusBadRequest, code: errorCodeCannotCommentDeleted}, true
	case errors.Is(err, app.ErrCannotViewOwnPostAsViewer):
		return mappedError{status: http.StatusBadRequest, code: errorCodeCannotViewOwnPost}, true
	case errors.Is(err, app.ErrUnauthenticatedWriter):
		return mappedError{status: http.StatusUnauthorized, code: errorCodeUnauthenticatedWriter}, true
	case errors.Is(err, app.ErrPostAccessDenied):
		return mappedError{status: http.StatusForbidden, code: errorCodePostAccessDenied}, true
	case errors.Is(err, app.ErrCommunityPostingDenied):
		return mappedError{status: http.StatusForbidden, code: errorCodeCommunityPostingDenied}, true
	case errors.Is(err, app.ErrCommunityModerationDenied):
		return mappedError{status: http.StatusForbidden, code: errorCodeCommunityModerationDenied}, true
	case errors.Is(err, app.ErrCommunityFollowDenied):
		return mappedError{status: http.StatusForbidden, code: errorCodeCommunityFollowDenied}, true
	case errors.Is(err, app.ErrCommunityInteractionDenied):
		return mappedError{status: http.StatusForbidden, code: errorCodeCommunityInteractionDenied}, true
	case errors.Is(err, app.ErrCommunityRoleChangeDenied):
		return mappedError{status: http.StatusForbidden, code: errorCodeCommunityRoleChangeDenied}, true
	case errors.Is(err, app.ErrCommunityMemberManageDenied):
		return mappedError{status: http.StatusForbidden, code: errorCodeCommunityMemberManageDenied}, true
	case errors.Is(err, app.ErrCommunityMembershipNotFound):
		return mappedError{status: http.StatusNotFound, code: errorCodeCommunityMembershipNotFound}, true
	case errors.Is(err, app.ErrPostCommentAccessDenied):
		return mappedError{status: http.StatusForbidden, code: errorCodeCommentAccessDenied}, true
	case errors.Is(err, app.ErrInvalidModerationDecision):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidModerationDecision}, true
	case errors.Is(err, app.ErrInvalidPostReportReason):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostReportReason}, true
	case errors.Is(err, app.ErrInvalidPostReportStatus):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostReportStatus}, true
	case errors.Is(err, app.ErrInvalidPostReportDetails):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostReportDetails}, true
	case errors.Is(err, app.ErrInvalidPostReportDecision):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostReportDecision}, true
	case errors.Is(err, app.ErrInvalidPostReportResolution):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidPostReportResolution}, true
	case errors.Is(err, app.ErrPostReportOwnContent):
		return mappedError{status: http.StatusBadRequest, code: errorCodePostReportOwnContent}, true
	case errors.Is(err, app.ErrPostReportNotFound):
		return mappedError{status: http.StatusNotFound, code: errorCodePostReportNotFound}, true
	case errors.Is(err, app.ErrPostReportAlreadyResolved):
		return mappedError{status: http.StatusConflict, code: errorCodePostReportAlreadyResolved}, true
	case errors.Is(err, app.ErrInvalidCommunityMemberRole):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidCommunityMemberRole}, true
	case errors.Is(err, app.ErrInvalidCommunityMemberStatus):
		return mappedError{status: http.StatusBadRequest, code: errorCodeInvalidCommunityMemberStatus}, true
	case errors.Is(err, app.ErrPostNotFound), errors.Is(err, app.ErrStoryNotFound):
		return mappedError{status: http.StatusNotFound, code: errorCodePostNotFound}, true
	case errors.Is(err, app.ErrCommunityNotFound):
		return mappedError{status: http.StatusNotFound, code: errorCodeCommunityNotFound}, true
	case errors.Is(err, app.ErrPostCommentNotFound):
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
	errorCodeInvalidCommunityID: {
		"ru": "Некорректное сообщество.",
		"en": "Invalid community.",
		"kk": "Қауымдастық дұрыс емес.",
	},
	errorCodeNotFound: {
		"ru": "Не найдено.",
		"en": "Not found.",
		"kk": "Табылмады.",
	},
	errorCodeInvalidPostID: {
		"ru": "Некорректная история.",
		"en": "Invalid post.",
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
	errorCodeInvalidFeedCursor: {
		"ru": "Некорректный курсор ленты.",
		"en": "Invalid feed cursor.",
		"kk": "Лента курсоры дұрыс емес.",
	},
	errorCodeInvalidFeedEvent: {
		"ru": "Некорректное событие ленты.",
		"en": "Invalid feed event.",
		"kk": "Лента оқиғасы дұрыс емес.",
	},
	errorCodeInvalidPostAuthorID: {
		"ru": "Некорректный автор истории.",
		"en": "Invalid post author.",
		"kk": "Оқиға авторы дұрыс емес.",
	},
	errorCodeInvalidPostTitle: {
		"ru": "Проверьте заголовок истории.",
		"en": "Check the post title.",
		"kk": "Оқиға тақырыбын тексеріңіз.",
	},
	errorCodeInvalidPostContent: {
		"ru": "Проверьте текст истории.",
		"en": "Check the post text.",
		"kk": "Оқиға мәтінін тексеріңіз.",
	},
	errorCodeInvalidPostCategory: {
		"ru": "Некорректная категория истории.",
		"en": "Invalid post category.",
		"kk": "Оқиға санаты дұрыс емес.",
	},
	errorCodeInvalidPostFormat: {
		"ru": "Некорректный тип материала.",
		"en": "Invalid post format.",
		"kk": "Материал түрі дұрыс емес.",
	},
	errorCodeInvalidPostStatus: {
		"ru": "Некорректный статус истории.",
		"en": "Invalid post status.",
		"kk": "Оқиға мәртебесі дұрыс емес.",
	},
	errorCodeInvalidPostTags: {
		"ru": "Проверьте теги истории.",
		"en": "Check the post tags.",
		"kk": "Оқиға тегтерін тексеріңіз.",
	},
	errorCodeInvalidPostPlace: {
		"ru": "Проверьте место истории.",
		"en": "Check the post place.",
		"kk": "Оқиға орнын тексеріңіз.",
	},
	errorCodeInvalidPostCover: {
		"ru": "Для публикации нужна обложка.",
		"en": "A cover image is required to publish.",
		"kk": "Жариялау үшін мұқаба қажет.",
	},
	errorCodeInvalidPostMedia: {
		"ru": "Проверьте медиафайлы истории.",
		"en": "Check post media attachments.",
		"kk": "Оқиғаның медиафайлдарын тексеріңіз.",
	},
	errorCodePostValidationFailed: {
		"ru": "Проверьте обязательные поля истории.",
		"en": "Check the required post fields.",
		"kk": "Оқиғаның міндетті өрістерін тексеріңіз.",
	},
	errorCodePostRevisionConflict: {
		"ru": "История была изменена. Обновите данные и попробуйте снова.",
		"en": "The post was changed. Refresh it and try again.",
		"kk": "Оқиға өзгертілді. Деректерді жаңартып, қайталап көріңіз.",
	},
	errorCodePostRateLimited: {
		"ru": "Слишком много публикаций за короткое время. Попробуйте позже.",
		"en": "Too many posts in a short time. Try again later.",
		"kk": "Қысқа уақыт ішінде тым көп жарияланым жасалды. Кейінірек қайталап көріңіз.",
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
	errorCodePostAccessDenied: {
		"ru": "Нет доступа к истории.",
		"en": "You do not have access to this post.",
		"kk": "Бұл оқиғаға қолжетімділік жоқ.",
	},
	errorCodeCommunityPostingDenied: {
		"ru": "Вы не можете публиковать в этом сообществе.",
		"en": "You cannot publish to this community.",
		"kk": "Бұл қауымдастықта жариялай алмайсыз.",
	},
	errorCodeCommunityModerationDenied: {
		"ru": "Нет прав на модерацию этого сообщества.",
		"en": "You cannot moderate this community.",
		"kk": "Бұл қауымдастықты модерациялауға құқығыңыз жоқ.",
	},
	errorCodeCommunityFollowDenied: {
		"ru": "Вы не можете подписаться на это сообщество.",
		"en": "You cannot follow this community.",
		"kk": "Бұл қауымдастыққа жазыла алмайсыз.",
	},
	errorCodeCommunityInteractionDenied: {
		"ru": "Вы не можете взаимодействовать с этим сообществом.",
		"en": "You cannot interact with this community.",
		"kk": "Бұл қауымдастықпен әрекеттесе алмайсыз.",
	},
	errorCodeCommunityRoleChangeDenied: {
		"ru": "Нет прав на изменение ролей в этом сообществе.",
		"en": "You cannot change roles in this community.",
		"kk": "Бұл қауымдастықтағы рөлдерді өзгертуге құқығыңыз жоқ.",
	},
	errorCodeCommunityMemberManageDenied: {
		"ru": "Нет прав на управление участниками этого сообщества.",
		"en": "You cannot manage members in this community.",
		"kk": "Бұл қауымдастықтың қатысушыларын басқаруға құқығыңыз жоқ.",
	},
	errorCodeCommunityMembershipNotFound: {
		"ru": "Участник сообщества не найден.",
		"en": "Community member not found.",
		"kk": "Қауымдастық қатысушысы табылмады.",
	},
	errorCodeCommentAccessDenied: {
		"ru": "Нет доступа к комментарию.",
		"en": "You do not have access to this comment.",
		"kk": "Бұл пікірге қолжетімділік жоқ.",
	},
	errorCodeInvalidModerationDecision: {
		"ru": "Некорректное решение модерации.",
		"en": "Invalid moderation decision.",
		"kk": "Модерация шешімі дұрыс емес.",
	},
	errorCodeInvalidPostReportReason: {
		"ru": "Некорректная причина жалобы.",
		"en": "Invalid report reason.",
		"kk": "Шағым себебі дұрыс емес.",
	},
	errorCodeInvalidPostReportStatus: {
		"ru": "Некорректный статус жалобы.",
		"en": "Invalid report status.",
		"kk": "Шағым күйі дұрыс емес.",
	},
	errorCodeInvalidPostReportDetails: {
		"ru": "Описание жалобы слишком длинное.",
		"en": "Report details are too long.",
		"kk": "Шағым сипаттамасы тым ұзын.",
	},
	errorCodeInvalidPostReportDecision: {
		"ru": "Некорректное решение по жалобе.",
		"en": "Invalid report decision.",
		"kk": "Шағым шешімі дұрыс емес.",
	},
	errorCodeInvalidPostReportResolution: {
		"ru": "Комментарий к решению по жалобе слишком длинный.",
		"en": "Report resolution note is too long.",
		"kk": "Шағым шешімінің түсіндірмесі тым ұзын.",
	},
	errorCodeDeprecatedEndpoint: {
		"ru": "Этот endpoint больше не поддерживается. Обновите клиент на актуальный контракт.",
		"en": "This endpoint is no longer supported. Update the client to the current contract.",
		"kk": "Бұл endpoint енді қолдау көрсетпейді. Клиентті ағымдағы келісімшартқа жаңартыңыз.",
	},
	errorCodePostReportOwnContent: {
		"ru": "Нельзя пожаловаться на собственную историю.",
		"en": "You cannot report your own post.",
		"kk": "Өз оқиғаңызға шағымдана алмайсыз.",
	},
	errorCodePostReportNotFound: {
		"ru": "Жалоба не найдена.",
		"en": "Report not found.",
		"kk": "Шағым табылмады.",
	},
	errorCodePostReportAlreadyResolved: {
		"ru": "Жалоба уже закрыта.",
		"en": "Report is already resolved.",
		"kk": "Шағым бұрын жабылған.",
	},
	errorCodeInvalidCommunityMemberRole: {
		"ru": "Некорректная роль участника сообщества.",
		"en": "Invalid community member role.",
		"kk": "Қауымдастық қатысушысының рөлі дұрыс емес.",
	},
	errorCodeInvalidCommunityMemberStatus: {
		"ru": "Некорректный статус участника сообщества.",
		"en": "Invalid community member status.",
		"kk": "Қауымдастық қатысушысының мәртебесі дұрыс емес.",
	},
	errorCodePostNotFound: {
		"ru": "История не найдена.",
		"en": "Post not found.",
		"kk": "Оқиға табылмады.",
	},
	errorCodeCommunityNotFound: {
		"ru": "Сообщество не найдено.",
		"en": "Community not found.",
		"kk": "Қауымдастық табылмады.",
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
	errorCodeCannotLikeOwnPost: {
		"ru": "Нельзя лайкнуть свою историю.",
		"en": "You cannot like your own post.",
		"kk": "Өз оқиғаңызға лайк қоюға болмайды.",
	},
	errorCodeCannotCommentDeleted: {
		"ru": "Нельзя комментировать удалённую историю.",
		"en": "You cannot comment on a deleted post.",
		"kk": "Жойылған оқиғаға пікір қалдыруға болмайды.",
	},
	errorCodeCannotViewOwnPost: {
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
