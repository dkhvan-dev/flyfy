package http

import (
	"fmt"
	"net/http"
	"net/url"
	"strings"
)

const (
	localeEN         = "en"
	localeRU         = "ru"
	localeCookieName = "flyfy_admin_locale"
	defaultLocale    = localeEN
)

var supportedLocales = map[string]struct{}{
	localeEN: {},
	localeRU: {},
}

var translations = map[string]map[string]string{
	localeEN: {
		"app.title": "FlyFy Admin",

		"lang.en": "EN",
		"lang.ru": "RU",

		"nav.primary":    "Primary",
		"nav.dashboard":  "Dashboard",
		"nav.excursions": "Excursions",
		"nav.staff":      "Staff",
		"nav.audit":      "Audit",
		"nav.language":   "Language",

		"action.signIn":             "Sign in",
		"action.signOut":            "Sign out",
		"action.updatePassword":     "Update password",
		"action.openQueue":          "Open excursion queue",
		"action.refreshQueue":       "Refresh queue",
		"action.review":             "Review",
		"action.backToQueue":        "Back to queue",
		"action.approve":            "Approve",
		"action.reject":             "Reject",
		"action.createUser":         "Create user",
		"action.edit":               "Edit",
		"action.backToStaff":        "Back to staff",
		"action.saveChanges":        "Save changes",
		"action.updateStatus":       "Update status",
		"action.regeneratePassword": "Regenerate password",
		"action.applyFilters":       "Apply filters",
		"action.resetFilters":       "Reset",
		"action.openHistory":        "Open history",
		"action.confirm":            "Confirm",
		"action.cancel":             "Cancel",

		"field.email":           "Email",
		"field.password":        "Password",
		"field.currentPassword": "Current password",
		"field.newPassword":     "New password",
		"field.confirmPassword": "Confirm password",
		"field.displayName":     "Display name",
		"field.internalComment": "Internal comment",
		"field.reasonCodes":     "Reason codes",
		"field.publicComment":   "Public comment",
		"field.status":          "Status",
		"field.reason":          "Reason",
		"field.city":            "City",
		"field.search":          "Search",
		"field.signal":          "Signal",
		"field.risk":            "Risk",
		"field.sort":            "Sort",

		"placeholder.reasonCodes":      "quality, safety, duplicate",
		"placeholder.city":             "Almaty",
		"placeholder.searchExcursions": "Title, landmark, guide",
		"placeholder.signal":           "new_guide",
		"placeholder.statusReason":     "Why this staff account status is changing",

		"flash.moderationDecisionSaved":  "Moderation decision saved.",
		"flash.moderationQueueSynced":    "Moderation queue refreshed.",
		"flash.staffCreated":             "Staff user created.",
		"flash.staffPasswordRegenerated": "Temporary password generated.",
		"flash.staffStatusChanged":       "Staff status updated.",
		"flash.staffUpdated":             "Changes saved.",

		"filter.status.active": "Active queue",
		"filter.status.all":    "All statuses",
		"filter.risk.all":      "Any risk",
		"filter.risk.flagged":  "Has risk",
		"filter.risk.high":     "High risk",

		"sort.default":       "Default priority",
		"sort.priorityDesc":  "Priority first",
		"sort.riskDesc":      "Risk first",
		"sort.submittedDesc": "Submitted newest",
		"sort.openedDesc":    "Opened newest",
		"sort.openedAsc":     "Opened oldest",

		"login.title":     "Admin sign in",
		"login.staffOnly": "Staff only",

		"security.account": "Account security",

		"password.changeTitle": "Change password",

		"dashboard.title":               "Dashboard",
		"dashboard.eyebrow":             "Operations",
		"dashboard.excursionModeration": "Excursion moderation",
		"dashboard.queue":               "Queue",
		"dashboard.accessControl":       "Access control",
		"dashboard.staff":               "Staff",
		"dashboard.compliance":          "Compliance",
		"dashboard.auditLog":            "Audit log",

		"moderation.eyebrow":            "Moderation",
		"moderation.excursionQueue":     "Excursion queue",
		"moderation.excursionHistory":   "Excursion moderation history",
		"moderation.case":               "Moderation case",
		"moderation.caseTitle":          "Moderation case",
		"moderation.excursion":          "Excursion",
		"moderation.noExcursionCases":   "No excursion cases are waiting for moderation.",
		"moderation.noExcursionHistory": "No excursion moderation history matches the selected filters.",

		"staff.eyebrow":                  "Security",
		"staff.title":                    "Staff",
		"staff.tempPassword":             "Temporary password",
		"staff.createUser":               "Create staff user",
		"staff.editUser":                 "Edit staff user",
		"staff.list":                     "Staff list",
		"staff.regeneratePasswordHelp":   "The current sessions will be revoked. Show the new temporary password to the employee once.",
		"staff.roles":                    "Roles",
		"staff.noUsers":                  "No staff users yet.",
		"staff.role.SUPER_ADMIN":         "Super admin",
		"staff.role.ADMIN":               "Admin",
		"staff.role.MODERATION_LEAD":     "Moderation lead",
		"staff.role.EXCURSION_MODERATOR": "Excursion moderator",
		"staff.role.ACTIVITY_MODERATOR":  "Activity moderator",
		"staff.role.CHAT_MODERATOR":      "Chat moderator",
		"staff.role.READ_ONLY_AUDITOR":   "Read-only auditor",
		"staff.role.SUPPORT_VIEWER":      "Support viewer",

		"audit.eyebrow":                                    "Compliance",
		"audit.title":                                      "Audit log",
		"audit.noEvents":                                   "No audit events yet.",
		"audit.action.staff.created":                       "Staff user created",
		"audit.action.staff.updated":                       "Staff profile updated",
		"audit.action.staff.status.changed":                "Staff status changed",
		"audit.action.staff.password.regenerated":          "Staff password reset",
		"audit.action.staff.bootstrap_super_admin.created": "Super admin created",
		"audit.action.staff.password.changed":              "Password changed",
		"audit.action.staff.password.change_denied":        "Password change denied",
		"audit.action.admin.login.succeeded":               "Sign-in succeeded",
		"audit.action.admin.login.failed":                  "Sign-in failed",
		"audit.action.admin.login.denied_rate_limited":     "Sign-in blocked by rate limit",
		"audit.action.admin.login.denied_disabled":         "Sign-in blocked for disabled account",
		"audit.action.admin.login.denied_locked":           "Sign-in blocked for locked account",
		"audit.action.admin.logout":                        "Signed out",
		"audit.action.moderation.decision.applied":         "Moderation decision applied",
		"audit.action.moderation.decision.apply_failed":    "Moderation decision failed",
		"audit.action.unknown":                             "System event",
		"audit.actorUnknown":                               "Staff member",
		"audit.entity.staffUser":                           "Staff user",
		"audit.entity.staffSession":                        "Staff session",
		"audit.entity.moderationCase":                      "Moderation case",
		"audit.entity.unknown":                             "Object",
		"audit.request":                                    "Request",
		"audit.detail.displayNameChanged":                  "Name: %s -> %s",
		"audit.detail.rolesChanged":                        "Roles: %s -> %s",
		"audit.detail.statusChanged":                       "Status: %s -> %s",
		"audit.detail.reason":                              "Reason: %s",
		"audit.detail.passwordRegenerated":                 "Employee must change the temporary password on next sign-in.",
		"audit.detail.staffCreated":                        "Email: %s",
		"audit.detail.moderationDecision":                  "Decision: %s",
		"audit.detail.error":                               "Error: %s",
		"audit.detail.failedLoginCount":                    "Failed attempts: %s",
		"audit.detail.noExtraData":                         "No additional details.",

		"table.case":      "Case",
		"table.status":    "Status",
		"table.priority":  "Priority",
		"table.target":    "Target",
		"table.excursion": "Excursion",
		"table.guide":     "Guide",
		"table.city":      "City",
		"table.opened":    "Opened",
		"table.user":      "User",
		"table.roles":     "Roles",
		"table.lastLogin": "Last login",
		"table.time":      "Time",
		"table.action":    "Action",
		"table.actor":     "Actor",
		"table.entity":    "Entity",
		"table.request":   "Request",
		"table.decision":  "Decision",
		"table.apply":     "Apply",
		"table.comment":   "Comment",
		"table.by":        "By",
		"table.created":   "Created",
		"table.actions":   "Actions",
		"table.details":   "Details",

		"label.status":               "Status",
		"label.visibility":           "Visibility",
		"label.guide":                "Guide",
		"label.trust":                "trust",
		"label.riskScore":            "Risk score",
		"label.landmark":             "Landmark",
		"label.city":                 "City",
		"label.price":                "Price",
		"label.submitted":            "Submitted",
		"label.priority":             "Priority",
		"label.revision":             "Revision",
		"label.signals":              "Signals",
		"label.duration":             "Duration",
		"label.groupSize":            "Group",
		"label.languages":            "Languages",
		"label.meetingPoint":         "Meeting point",
		"label.stops":                "Stops",
		"label.system":               "system",
		"section.summary":            "Summary",
		"section.description":        "Description",
		"section.routeSchedule":      "Route and schedule",
		"section.includedItems":      "Included",
		"section.decision":           "Decision",
		"section.decisionHistory":    "Decision history",
		"section.profile":            "Profile and roles",
		"section.status":             "Status",
		"section.password":           "Password",
		"empty.noDecisions":          "No decisions have been recorded.",
		"empty.noItinerary":          "No route steps were provided.",
		"empty.noIncludedItems":      "No included services were provided.",
		"modal.confirmDecisionTitle": "Confirm action",
		"modal.confirmDecisionText":  "This moderation action will be applied immediately.",

		"status.OPEN":                    "Open",
		"status.IN_REVIEW":               "In review",
		"status.APPROVED":                "Approved",
		"status.REJECTED":                "Rejected",
		"status.CHANGES_REQUESTED":       "Changes requested",
		"status.ESCALATED":               "Escalated",
		"status.CANCELLED":               "Cancelled",
		"status.PENDING_REVIEW":          "Pending review",
		"status.PUBLISHED":               "Published",
		"status.PUBLIC":                  "Public",
		"status.ACTIVE":                  "Active",
		"status.PASSWORD_RESET_REQUIRED": "Password reset required",
		"status.LOCKED":                  "Locked",
		"status.DISABLED":                "Disabled",
		"status.APPROVE":                 "Approve",
		"status.REJECT":                  "Reject",
		"status.REQUEST_CHANGES":         "Request changes",
		"status.ESCALATE":                "Escalate",
		"status.PENDING":                 "Pending",
		"status.APPLIED":                 "Applied",
		"status.FAILED":                  "Failed",
		"status.SUPERSEDED":              "Superseded",

		"error.invalidLoginForm":    "Invalid login form.",
		"error.invalidCredentials":  "Invalid credentials or access is not allowed.",
		"error.passwordsDoNotMatch": "Passwords do not match.",
		"error.permissionDenied":    "You do not have permission to perform this action.",
		"error.caseNotFound":        "Moderation case was not found.",
		"error.duplicateDecision":   "This moderation decision was already submitted.",
		"error.caseConflict":        "This moderation case has already changed. Refresh the queue and try again.",
		"error.staffNotFound":       "Staff user was not found.",
		"error.invalidInput":        "Please check the submitted form and try again.",
		"error.generic":             "The request could not be completed. Please try again.",
		"error.invalidForm":         "Invalid form.",
		"error.invalidCSRF":         "Invalid CSRF token.",
		"error.invalidID":           "Invalid id.",
	},
	localeRU: {
		"app.title": "FlyFy Admin",

		"lang.en": "EN",
		"lang.ru": "RU",

		"nav.primary":    "Основная навигация",
		"nav.dashboard":  "Панель",
		"nav.excursions": "Экскурсии",
		"nav.staff":      "Сотрудники",
		"nav.audit":      "Аудит",
		"nav.language":   "Язык",

		"action.signIn":             "Войти",
		"action.signOut":            "Выйти",
		"action.updatePassword":     "Обновить пароль",
		"action.openQueue":          "Открыть очередь экскурсий",
		"action.refreshQueue":       "Обновить очередь",
		"action.review":             "Проверить",
		"action.backToQueue":        "Назад к очереди",
		"action.approve":            "Одобрить",
		"action.reject":             "Отклонить",
		"action.createUser":         "Создать пользователя",
		"action.edit":               "Редактировать",
		"action.backToStaff":        "Назад к сотрудникам",
		"action.saveChanges":        "Сохранить изменения",
		"action.updateStatus":       "Изменить статус",
		"action.regeneratePassword": "Сгенерировать пароль",
		"action.applyFilters":       "Применить фильтры",
		"action.resetFilters":       "Сбросить",
		"action.openHistory":        "Открыть историю",
		"action.confirm":            "Подтвердить",
		"action.cancel":             "Отмена",

		"field.email":           "Почта",
		"field.password":        "Пароль",
		"field.currentPassword": "Текущий пароль",
		"field.newPassword":     "Новый пароль",
		"field.confirmPassword": "Повторите пароль",
		"field.displayName":     "Имя сотрудника",
		"field.internalComment": "Внутренний комментарий",
		"field.reasonCodes":     "Коды причин",
		"field.publicComment":   "Публичный комментарий",
		"field.status":          "Статус",
		"field.reason":          "Причина",
		"field.city":            "Город",
		"field.search":          "Поиск",
		"field.signal":          "Сигнал",
		"field.risk":            "Риск",
		"field.sort":            "Сортировка",

		"placeholder.reasonCodes":      "quality, safety, duplicate",
		"placeholder.city":             "Алматы",
		"placeholder.searchExcursions": "Название, место, гид",
		"placeholder.signal":           "new_guide",
		"placeholder.statusReason":     "Почему меняется статус учетной записи сотрудника",

		"flash.moderationDecisionSaved":  "Решение модерации сохранено.",
		"flash.moderationQueueSynced":    "Очередь модерации обновлена.",
		"flash.staffCreated":             "Сотрудник создан.",
		"flash.staffPasswordRegenerated": "Временный пароль сгенерирован.",
		"flash.staffStatusChanged":       "Статус сотрудника обновлен.",
		"flash.staffUpdated":             "Изменения сохранены.",

		"filter.status.active": "Активная очередь",
		"filter.status.all":    "Все статусы",
		"filter.risk.all":      "Любой риск",
		"filter.risk.flagged":  "Есть риск",
		"filter.risk.high":     "Высокий риск",

		"sort.default":       "По приоритету",
		"sort.priorityDesc":  "Сначала приоритетные",
		"sort.riskDesc":      "Сначала рискованные",
		"sort.submittedDesc": "Новые отправки",
		"sort.openedDesc":    "Новые кейсы",
		"sort.openedAsc":     "Старые кейсы",

		"login.title":     "Вход в админку",
		"login.staffOnly": "Только для сотрудников",

		"security.account": "Безопасность аккаунта",

		"password.changeTitle": "Смена пароля",

		"dashboard.title":               "Панель",
		"dashboard.eyebrow":             "Операции",
		"dashboard.excursionModeration": "Модерация экскурсий",
		"dashboard.queue":               "Очередь",
		"dashboard.accessControl":       "Доступы",
		"dashboard.staff":               "Сотрудники",
		"dashboard.compliance":          "Контроль",
		"dashboard.auditLog":            "Журнал аудита",

		"moderation.eyebrow":            "Модерация",
		"moderation.excursionQueue":     "Очередь экскурсий",
		"moderation.excursionHistory":   "История модерации экскурсий",
		"moderation.case":               "Кейс модерации",
		"moderation.caseTitle":          "Кейс модерации",
		"moderation.excursion":          "Экскурсия",
		"moderation.noExcursionCases":   "Нет экскурсий, ожидающих модерации.",
		"moderation.noExcursionHistory": "История модерации экскурсий по выбранным фильтрам пуста.",

		"staff.eyebrow":                  "Безопасность",
		"staff.title":                    "Сотрудники",
		"staff.tempPassword":             "Временный пароль",
		"staff.createUser":               "Создать сотрудника",
		"staff.editUser":                 "Редактировать сотрудника",
		"staff.list":                     "Список сотрудников",
		"staff.regeneratePasswordHelp":   "Текущие сессии будут отозваны. Новый временный пароль нужно показать сотруднику один раз.",
		"staff.roles":                    "Роли",
		"staff.noUsers":                  "Сотрудников пока нет.",
		"staff.role.SUPER_ADMIN":         "Суперадмин",
		"staff.role.ADMIN":               "Администратор",
		"staff.role.MODERATION_LEAD":     "Руководитель модерации",
		"staff.role.EXCURSION_MODERATOR": "Модератор экскурсий",
		"staff.role.ACTIVITY_MODERATOR":  "Модератор активностей",
		"staff.role.CHAT_MODERATOR":      "Модератор чатов",
		"staff.role.READ_ONLY_AUDITOR":   "Аудитор только для чтения",
		"staff.role.SUPPORT_VIEWER":      "Сотрудник поддержки",

		"audit.eyebrow":                                    "Контроль",
		"audit.title":                                      "Журнал аудита",
		"audit.noEvents":                                   "Событий аудита пока нет.",
		"audit.action.staff.created":                       "Сотрудник создан",
		"audit.action.staff.updated":                       "Профиль сотрудника обновлен",
		"audit.action.staff.status.changed":                "Статус сотрудника изменен",
		"audit.action.staff.password.regenerated":          "Пароль сотрудника сброшен",
		"audit.action.staff.bootstrap_super_admin.created": "Суперадмин создан",
		"audit.action.staff.password.changed":              "Пароль изменен",
		"audit.action.staff.password.change_denied":        "Смена пароля отклонена",
		"audit.action.admin.login.succeeded":               "Вход выполнен",
		"audit.action.admin.login.failed":                  "Неудачный вход",
		"audit.action.admin.login.denied_rate_limited":     "Вход заблокирован лимитом",
		"audit.action.admin.login.denied_disabled":         "Вход заблокирован для отключенного аккаунта",
		"audit.action.admin.login.denied_locked":           "Вход заблокирован для заблокированного аккаунта",
		"audit.action.admin.logout":                        "Выход из системы",
		"audit.action.moderation.decision.applied":         "Решение модерации применено",
		"audit.action.moderation.decision.apply_failed":    "Решение модерации не применилось",
		"audit.action.unknown":                             "Системное событие",
		"audit.actorUnknown":                               "Сотрудник",
		"audit.entity.staffUser":                           "Сотрудник",
		"audit.entity.staffSession":                        "Сессия сотрудника",
		"audit.entity.moderationCase":                      "Кейс модерации",
		"audit.entity.unknown":                             "Объект",
		"audit.request":                                    "Запрос",
		"audit.detail.displayNameChanged":                  "ФИО: %s -> %s",
		"audit.detail.rolesChanged":                        "Роли: %s -> %s",
		"audit.detail.statusChanged":                       "Статус: %s -> %s",
		"audit.detail.reason":                              "Причина: %s",
		"audit.detail.passwordRegenerated":                 "Сотрудник должен сменить временный пароль при следующем входе.",
		"audit.detail.staffCreated":                        "Почта: %s",
		"audit.detail.moderationDecision":                  "Решение: %s",
		"audit.detail.error":                               "Ошибка: %s",
		"audit.detail.failedLoginCount":                    "Неудачных попыток: %s",
		"audit.detail.noExtraData":                         "Дополнительных деталей нет.",

		"table.case":      "Кейс",
		"table.status":    "Статус",
		"table.priority":  "Приоритет",
		"table.target":    "Объект",
		"table.excursion": "Экскурсия",
		"table.guide":     "Гид",
		"table.city":      "Город",
		"table.opened":    "Открыт",
		"table.user":      "Пользователь",
		"table.roles":     "Роли",
		"table.lastLogin": "Последний вход",
		"table.time":      "Время",
		"table.action":    "Действие",
		"table.actor":     "Сотрудник",
		"table.entity":    "Сущность",
		"table.request":   "Запрос",
		"table.decision":  "Решение",
		"table.apply":     "Применение",
		"table.comment":   "Комментарий",
		"table.by":        "Кем принято",
		"table.created":   "Создано",
		"table.actions":   "Действия",
		"table.details":   "Детали",

		"label.status":               "Статус",
		"label.visibility":           "Видимость",
		"label.guide":                "Гид",
		"label.trust":                "доверие",
		"label.riskScore":            "Риск",
		"label.landmark":             "Достопримечательность",
		"label.city":                 "Город",
		"label.price":                "Цена",
		"label.submitted":            "Отправлено",
		"label.priority":             "Приоритет",
		"label.revision":             "Ревизия",
		"label.signals":              "Сигналы",
		"label.duration":             "Длительность",
		"label.groupSize":            "Группа",
		"label.languages":            "Языки",
		"label.meetingPoint":         "Место встречи",
		"label.stops":                "Остановки",
		"label.system":               "система",
		"section.summary":            "Краткое описание",
		"section.description":        "Описание",
		"section.routeSchedule":      "Маршрут и расписание",
		"section.includedItems":      "Что включено",
		"section.decision":           "Решение",
		"section.decisionHistory":    "История решений",
		"section.profile":            "Профиль и роли",
		"section.status":             "Статус",
		"section.password":           "Пароль",
		"empty.noDecisions":          "Решения пока не зафиксированы.",
		"empty.noItinerary":          "Пункты маршрута не указаны.",
		"empty.noIncludedItems":      "Включенные услуги не указаны.",
		"modal.confirmDecisionTitle": "Подтвердить действие",
		"modal.confirmDecisionText":  "Это действие модерации будет применено сразу.",

		"status.OPEN":                    "Открыт",
		"status.IN_REVIEW":               "На проверке",
		"status.APPROVED":                "Одобрено",
		"status.REJECTED":                "Отклонено",
		"status.CHANGES_REQUESTED":       "Нужны правки",
		"status.ESCALATED":               "Эскалировано",
		"status.CANCELLED":               "Отменено",
		"status.PENDING_REVIEW":          "Ожидает проверки",
		"status.PUBLISHED":               "Опубликовано",
		"status.PUBLIC":                  "Публично",
		"status.ACTIVE":                  "Активен",
		"status.PASSWORD_RESET_REQUIRED": "Требуется смена пароля",
		"status.LOCKED":                  "Заблокирован",
		"status.DISABLED":                "Отключен",
		"status.APPROVE":                 "Одобрение",
		"status.REJECT":                  "Отклонение",
		"status.REQUEST_CHANGES":         "Запрос правок",
		"status.ESCALATE":                "Эскалация",
		"status.PENDING":                 "Ожидает",
		"status.APPLIED":                 "Применено",
		"status.FAILED":                  "Ошибка",
		"status.SUPERSEDED":              "Заменено",

		"error.invalidLoginForm":    "Некорректная форма входа.",
		"error.invalidCredentials":  "Неверные учетные данные или доступ запрещен.",
		"error.passwordsDoNotMatch": "Пароли не совпадают.",
		"error.permissionDenied":    "У вас нет прав для выполнения этого действия.",
		"error.caseNotFound":        "Кейс модерации не найден.",
		"error.duplicateDecision":   "Это решение модерации уже было отправлено.",
		"error.caseConflict":        "Кейс модерации уже изменился. Обновите очередь и попробуйте снова.",
		"error.staffNotFound":       "Сотрудник не найден.",
		"error.invalidInput":        "Проверьте отправленную форму и попробуйте снова.",
		"error.generic":             "Не удалось выполнить запрос. Попробуйте еще раз.",
		"error.invalidForm":         "Некорректная форма.",
		"error.invalidCSRF":         "Некорректный CSRF-токен.",
		"error.invalidID":           "Некорректный идентификатор.",
	},
}

func normalizeLocale(value string) (string, bool) {
	normalized := strings.ToLower(strings.TrimSpace(value))
	if len(normalized) > 2 {
		normalized = normalized[:2]
	}
	_, ok := supportedLocales[normalized]
	return normalized, ok
}

func resolveLocale(r *http.Request) string {
	if locale, ok := normalizeLocale(r.URL.Query().Get("lang")); ok {
		return locale
	}
	if cookie, err := r.Cookie(localeCookieName); err == nil {
		if locale, ok := normalizeLocale(cookie.Value); ok {
			return locale
		}
	}
	if locale, ok := localeFromAcceptLanguage(r.Header.Get("Accept-Language")); ok {
		return locale
	}
	return defaultLocale
}

func localeFromAcceptLanguage(header string) (string, bool) {
	for _, part := range strings.Split(header, ",") {
		raw := strings.TrimSpace(strings.Split(part, ";")[0])
		if locale, ok := normalizeLocale(raw); ok {
			return locale, true
		}
	}
	return "", false
}

func translate(locale string, key string) string {
	locale, ok := normalizeLocale(locale)
	if !ok {
		locale = defaultLocale
	}
	if value := translations[locale][key]; value != "" {
		return value
	}
	if value := translations[defaultLocale][key]; value != "" {
		return value
	}
	return key
}

func translateStatus(locale string, value any) string {
	raw := strings.ToUpper(strings.TrimSpace(toString(value)))
	if raw == "" {
		return "-"
	}
	key := "status." + raw
	translated := translate(locale, key)
	if translated == key {
		return raw
	}
	return translated
}

func translateRole(locale string, value any) string {
	raw := strings.ToUpper(strings.TrimSpace(toString(value)))
	if raw == "" {
		return "-"
	}
	key := "staff.role." + raw
	translated := translate(locale, key)
	if translated == key {
		return raw
	}
	return translated
}

func localeURL(path string, locale string) string {
	if strings.TrimSpace(path) == "" {
		path = "/admin"
	}
	query := url.Values{}
	query.Set("lang", locale)
	return path + "?" + query.Encode()
}

func toString(value any) string {
	switch typed := value.(type) {
	case string:
		return typed
	default:
		return fmt.Sprint(value)
	}
}
