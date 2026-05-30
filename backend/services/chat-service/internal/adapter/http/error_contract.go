package http

import (
	"errors"
	"net/http"
	"strings"

	"kz/inflap/backend/services/chat-service/internal/app"
)

const (
	errorKindBusiness  = "business"
	errorKindTechnical = "technical"

	errorCodeTechnical = "technical_error"

	defaultErrorLanguage = "ru"
)

type errorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    string `json:"code"`
	Kind    string `json:"kind"`
}

type localizedErrorText struct {
	Error   string
	Message string
}

type appHTTPErrorDefinition struct {
	err    error
	status int
	code   string
}

var appHTTPErrorDefinitions = []appHTTPErrorDefinition{
	{err: app.ErrInvalidConversationID, status: http.StatusBadRequest, code: "invalid_conversation_id"},
	{err: app.ErrInvalidActivityID, status: http.StatusBadRequest, code: "invalid_activity_id"},
	{err: app.ErrInvalidMessageID, status: http.StatusBadRequest, code: "invalid_message_id"},
	{err: app.ErrInvalidUserID, status: http.StatusBadRequest, code: "invalid_user_id"},
	{err: app.ErrMessageTooLong, status: http.StatusBadRequest, code: "message_too_long"},
	{err: app.ErrInvalidMessageType, status: http.StatusBadRequest, code: "invalid_message_type"},
	{err: app.ErrInvalidStickerID, status: http.StatusBadRequest, code: "invalid_sticker_id"},
	{err: app.ErrInvalidReaction, status: http.StatusBadRequest, code: "invalid_reaction"},
	{err: app.ErrTooManyFiles, status: http.StatusBadRequest, code: "too_many_files"},
	{err: app.ErrDirectChatCannotLeave, status: http.StatusBadRequest, code: "direct_chat_cannot_leave"},
	{err: app.ErrCannotPinInDirectChat, status: http.StatusBadRequest, code: "cannot_pin_in_direct_chat"},
	{err: app.ErrMessageEditExpired, status: http.StatusBadRequest, code: "message_edit_expired"},
	{err: app.ErrMessageAlreadyDeleted, status: http.StatusBadRequest, code: "message_already_deleted"},
	{err: app.ErrInvalidModerationDecision, status: http.StatusBadRequest, code: "invalid_moderation_decision"},

	{err: app.ErrConversationNotFound, status: http.StatusNotFound, code: "conversation_not_found"},
	{err: app.ErrMessageNotFound, status: http.StatusNotFound, code: "message_not_found"},
	{err: app.ErrParticipantNotFound, status: http.StatusNotFound, code: "participant_not_found"},

	{err: app.ErrAccessDenied, status: http.StatusForbidden, code: "access_denied"},
	{err: app.ErrNotParticipant, status: http.StatusForbidden, code: "not_participant"},
	{err: app.ErrNotAdmin, status: http.StatusForbidden, code: "not_admin"},
	{err: app.ErrNotMessageAuthor, status: http.StatusForbidden, code: "not_message_author"},
	{err: app.ErrConversationMessagingClosed, status: http.StatusForbidden, code: "conversation_messaging_closed"},
	{err: app.ErrStickerNotAvailable, status: http.StatusForbidden, code: "sticker_not_available"},

	{err: app.ErrConversationFull, status: http.StatusConflict, code: "conversation_full"},
}

var businessErrorMessages = map[string]map[string]string{
	"invalid_conversation_id": {
		"ru": "Некорректный идентификатор чата",
		"en": "Invalid conversation id",
		"kk": "Чат идентификаторы жарамсыз",
	},
	"invalid_activity_id": {
		"ru": "Некорректный идентификатор активности",
		"en": "Invalid activity id",
		"kk": "Белсенділік идентификаторы жарамсыз",
	},
	"invalid_message_id": {
		"ru": "Некорректный идентификатор сообщения",
		"en": "Invalid message id",
		"kk": "Хабарлама идентификаторы жарамсыз",
	},
	"invalid_user_id": {
		"ru": "Некорректный идентификатор пользователя",
		"en": "Invalid user id",
		"kk": "Пайдаланушы идентификаторы жарамсыз",
	},
	"conversation_not_found": {
		"ru": "Чат не найден",
		"en": "Chat not found",
		"kk": "Чат табылмады",
	},
	"message_not_found": {
		"ru": "Сообщение не найдено",
		"en": "Message not found",
		"kk": "Хабарлама табылмады",
	},
	"participant_not_found": {
		"ru": "Участник не найден",
		"en": "Participant not found",
		"kk": "Қатысушы табылмады",
	},
	"access_denied": {
		"ru": "Доступ запрещен",
		"en": "Access denied",
		"kk": "Қолжетімділікке тыйым салынды",
	},
	"not_participant": {
		"ru": "Вы не участник этого чата",
		"en": "You are not a participant of this chat",
		"kk": "Сіз бұл чаттың қатысушысы емессіз",
	},
	"not_admin": {
		"ru": "Нужны права администратора чата",
		"en": "Chat admin rights are required",
		"kk": "Чат әкімшісі құқықтары қажет",
	},
	"not_message_author": {
		"ru": "Вы не автор этого сообщения",
		"en": "You are not the author of this message",
		"kk": "Сіз бұл хабарламаның авторы емессіз",
	},
	"direct_chat_cannot_leave": {
		"ru": "Нельзя выйти из личного чата",
		"en": "Direct chats cannot be left",
		"kk": "Жеке чаттан шығуға болмайды",
	},
	"message_too_long": {
		"ru": "Сообщение слишком длинное",
		"en": "Message is too long",
		"kk": "Хабарлама тым ұзын",
	},
	"invalid_message_type": {
		"ru": "Некорректный тип сообщения",
		"en": "Invalid message type",
		"kk": "Хабарлама түрі жарамсыз",
	},
	"invalid_sticker_id": {
		"ru": "Некорректный идентификатор стикера",
		"en": "Invalid sticker id",
		"kk": "Стикер идентификаторы жарамсыз",
	},
	"sticker_not_available": {
		"ru": "Стикер недоступен",
		"en": "Sticker is not available",
		"kk": "Стикер қолжетімді емес",
	},
	"invalid_reaction": {
		"ru": "Некорректная реакция",
		"en": "Invalid message reaction",
		"kk": "Хабарлама реакциясы жарамсыз",
	},
	"message_edit_expired": {
		"ru": "Время редактирования сообщения истекло",
		"en": "Message edit time has expired",
		"kk": "Хабарламаны өңдеу уақыты аяқталды",
	},
	"message_already_deleted": {
		"ru": "Сообщение уже удалено",
		"en": "Message is already deleted",
		"kk": "Хабарлама жойылған",
	},
	"cannot_pin_in_direct_chat": {
		"ru": "В личном чате нельзя закреплять сообщения",
		"en": "Messages cannot be pinned in direct chats",
		"kk": "Жеке чатта хабарламаларды бекітуге болмайды",
	},
	"invalid_moderation_decision": {
		"ru": "Некорректное решение модерации",
		"en": "Invalid moderation decision",
		"kk": "Модерация шешімі жарамсыз",
	},
	"too_many_files": {
		"ru": "Слишком много файлов в сообщении",
		"en": "Too many files in the message",
		"kk": "Хабарламада файл тым көп",
	},
	"conversation_full": {
		"ru": "В чате достигнут лимит участников",
		"en": "Chat participant limit has been reached",
		"kk": "Чаттағы қатысушылар шегіне жетті",
	},
	"conversation_messaging_closed": {
		"ru": "Переписка в этом чате закрыта",
		"en": "Messaging in this chat is closed",
		"kk": "Бұл чатта жазысу жабық",
	},
}

var legacyBusinessErrorMessages = map[string]map[string]string{
	"not found": {
		"ru": "Не найдено",
		"en": "Not found",
		"kk": "Табылмады",
	},
	"invalid request body": {
		"ru": "Некорректное тело запроса",
		"en": "Invalid request body",
		"kk": "Сұрау денесі жарамсыз",
	},
	"missing authenticated user": {
		"ru": "Пользователь не аутентифицирован",
		"en": "Authenticated user is missing",
		"kk": "Аутентификацияланған пайдаланушы жоқ",
	},
	"invalid authenticated user": {
		"ru": "Некорректный аутентифицированный пользователь",
		"en": "Invalid authenticated user",
		"kk": "Аутентификацияланған пайдаланушы жарамсыз",
	},
	"missing internal service token": {
		"ru": "Отсутствует внутренний сервисный токен",
		"en": "Internal service token is missing",
		"kk": "Ішкі сервис токені жоқ",
	},
	"invalid internal service token": {
		"ru": "Некорректный внутренний сервисный токен",
		"en": "Invalid internal service token",
		"kk": "Ішкі сервис токені жарамсыз",
	},
	"missing authenticated subject": {
		"ru": "Отсутствует аутентифицированный субъект",
		"en": "Authenticated subject is missing",
		"kk": "Аутентификацияланған субъект жоқ",
	},
	"missing chat moderation role": {
		"ru": "Нет роли модератора чата",
		"en": "Chat moderation role is missing",
		"kk": "Чат модераторы рөлі жоқ",
	},
	"invalid authenticated admin": {
		"ru": "Некорректный аутентифицированный администратор",
		"en": "Invalid authenticated admin",
		"kk": "Аутентификацияланған әкімші жарамсыз",
	},
	"invalid conversation id": {
		"ru": "Некорректный идентификатор чата",
		"en": "Invalid conversation id",
		"kk": "Чат идентификаторы жарамсыз",
	},
	"invalid message id": {
		"ru": "Некорректный идентификатор сообщения",
		"en": "Invalid message id",
		"kk": "Хабарлама идентификаторы жарамсыз",
	},
	"invalid activity id": {
		"ru": "Некорректный идентификатор активности",
		"en": "Invalid activity id",
		"kk": "Белсенділік идентификаторы жарамсыз",
	},
	"missing activity id": {
		"ru": "Не указан идентификатор активности",
		"en": "Activity id is missing",
		"kk": "Белсенділік идентификаторы жоқ",
	},
	"invalid host user id": {
		"ru": "Некорректный идентификатор организатора",
		"en": "Invalid host user id",
		"kk": "Ұйымдастырушы идентификаторы жарамсыз",
	},
	"invalid user id": {
		"ru": "Некорректный идентификатор пользователя",
		"en": "Invalid user id",
		"kk": "Пайдаланушы идентификаторы жарамсыз",
	},
	"invalid participant user id": {
		"ru": "Некорректный идентификатор участника",
		"en": "Invalid participant user id",
		"kk": "Қатысушы идентификаторы жарамсыз",
	},
	"invalid guide user id": {
		"ru": "Некорректный идентификатор гида",
		"en": "Invalid guide user id",
		"kk": "Гид идентификаторы жарамсыз",
	},
	"invalid schedule slot id": {
		"ru": "Некорректный идентификатор слота расписания",
		"en": "Invalid schedule slot id",
		"kk": "Кесте слотының идентификаторы жарамсыз",
	},
	"invalid sticker id": {
		"ru": "Некорректный идентификатор стикера",
		"en": "Invalid sticker id",
		"kk": "Стикер идентификаторы жарамсыз",
	},
	"invalid message cursor": {
		"ru": "Некорректный курсор сообщений",
		"en": "Invalid message cursor",
		"kk": "Хабарлама курсоры жарамсыз",
	},
	"invalid target conversation id": {
		"ru": "Некорректный идентификатор целевого чата",
		"en": "Invalid target conversation id",
		"kk": "Мақсатты чат идентификаторы жарамсыз",
	},
	"invalid until time": {
		"ru": "Некорректное время окончания",
		"en": "Invalid end time",
		"kk": "Аяқталу уақыты жарамсыз",
	},
	"exactly one participant is required for direct chats": {
		"ru": "Для личного чата нужен ровно один участник",
		"en": "Exactly one participant is required for direct chats",
		"kk": "Жеке чат үшін дәл бір қатысушы қажет",
	},
	"unsupported conversation type": {
		"ru": "Неподдерживаемый тип чата",
		"en": "Unsupported conversation type",
		"kk": "Чат түріне қолдау көрсетілмейді",
	},
	"method not allowed": {
		"ru": "Метод не поддерживается",
		"en": "Method not allowed",
		"kk": "Әдіске рұқсат жоқ",
	},
}

var technicalErrorMessages = map[string]localizedErrorText{
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

func appHTTPErrorContract(err error) (appHTTPErrorDefinition, bool) {
	for _, definition := range appHTTPErrorDefinitions {
		if errors.Is(err, definition.err) {
			return definition, true
		}
	}
	return appHTTPErrorDefinition{}, false
}

func localizedBusinessError(code string, language string) localizedErrorText {
	messages, ok := businessErrorMessages[code]
	if !ok {
		return localizedErrorText{Error: code, Message: code}
	}
	message, ok := messages[language]
	if !ok {
		message = messages[defaultErrorLanguage]
	}
	return localizedErrorText{Error: message, Message: message}
}

func localizedLegacyBusinessError(message string, language string) localizedErrorText {
	messages, ok := legacyBusinessErrorMessages[message]
	if !ok {
		return localizedErrorText{Error: message, Message: message}
	}
	localized, ok := messages[language]
	if !ok {
		localized = messages[defaultErrorLanguage]
	}
	return localizedErrorText{Error: localized, Message: localized}
}

func localizedTechnicalError(language string) localizedErrorText {
	if text, ok := technicalErrorMessages[language]; ok {
		return text
	}
	return technicalErrorMessages[defaultErrorLanguage]
}

func preferredErrorLanguage(acceptLanguage string) string {
	for _, candidate := range strings.Split(acceptLanguage, ",") {
		tag := strings.ToLower(strings.TrimSpace(strings.Split(candidate, ";")[0]))
		switch {
		case tag == "ru" || strings.HasPrefix(tag, "ru-"):
			return "ru"
		case tag == "en" || strings.HasPrefix(tag, "en-"):
			return "en"
		case tag == "kk" || strings.HasPrefix(tag, "kk-"):
			return "kk"
		}
	}
	return defaultErrorLanguage
}

func requestErrorLanguage(r *http.Request) string {
	if r == nil {
		return defaultErrorLanguage
	}
	return preferredErrorLanguage(r.Header.Get("Accept-Language"))
}

func writeErrorContract(w http.ResponseWriter, status int, text localizedErrorText, code string, kind string) {
	writeJSON(w, status, errorResponse{
		Error:   text.Error,
		Message: text.Message,
		Code:    code,
		Kind:    kind,
	})
}

func legacyErrorCode(status int, message string) string {
	if status >= http.StatusInternalServerError {
		return errorCodeTechnical
	}

	normalized := strings.ToLower(strings.TrimSpace(message))
	var b strings.Builder
	lastUnderscore := false
	for _, r := range normalized {
		isAlphaNum := (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9')
		if isAlphaNum {
			b.WriteRune(r)
			lastUnderscore = false
			continue
		}
		if !lastUnderscore && b.Len() > 0 {
			b.WriteByte('_')
			lastUnderscore = true
		}
	}

	code := strings.Trim(b.String(), "_")
	if code == "" {
		return strings.ToLower(strings.ReplaceAll(http.StatusText(status), " ", "_"))
	}
	return code
}
