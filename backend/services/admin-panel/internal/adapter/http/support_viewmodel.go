package http

import (
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type SupportTicketQueueViewData struct {
	Items           []SupportTicketRowView
	Filters         SupportTicketFilterViewData
	StatusOptions   []SupportOptionView
	CategoryOptions []SupportOptionView
	PriorityOptions []SupportOptionView
	SLAOptions      []SupportOptionView
	FilterAction    string
	ResetURL        string
	CanReply        bool
	CanManage       bool
}

type SupportSavedReplyListViewData struct {
	Items               []SupportSavedReplyRowView
	Filters             SupportSavedReplyFilterViewData
	Input               SupportSavedReplyFormInput
	StatusOptions       []SupportOptionView
	CategoryOptions     []SupportOptionView
	FormStatusOptions   []SupportOptionView
	FormCategoryOptions []SupportOptionView
	FilterAction        string
	ResetURL            string
	SubmitURL           string
	CanManage           bool
}

type SupportAgentListViewData struct {
	Items             []SupportAgentRowView
	Filters           SupportAgentFilterViewData
	Input             SupportAgentFormInput
	StaffOptions      []SupportAgentStaffOptionView
	LanguageOptions   []SupportOptionView
	TimezoneOptions   []TimezoneOptionView
	StatusOptions     []SupportOptionView
	FormStatusOptions []SupportOptionView
	LevelOptions      []SupportOptionView
	SkillOptions      []SupportOptionView
	FilterAction      string
	ResetURL          string
	AgentSubmitURL    string
	CanManage         bool
}

type SupportTicketFilterViewData struct {
	Status     string
	Category   string
	Priority   string
	AssigneeID string
	SLA        string
	Query      string
}

type SupportSavedReplyFilterViewData struct {
	Category string
	Status   string
	Query    string
}

type SupportAgentFilterViewData struct {
	Status string
	Query  string
}

type SupportOptionView struct {
	Value    string
	LabelKey string
	Selected bool
}

type SupportTicketRowView struct {
	Item                 model.SupportTicket
	DetailURL            string
	DisplayID            string
	BadgeClass           string
	SLA                  SupportTicketSLAView
	RelatedEntityID      string
	ContextSummary       string
	UserLabel            string
	AssigneeLabel        string
	LastMessagePreview   string
	PriorityReasonLabels []string
}

type SupportSavedReplyRowView struct {
	Item         model.SupportSavedReply
	Title        string
	Body         string
	BodyPreview  string
	BadgeClass   string
	Tags         string
	Translations string
}

type SupportAgentRowView struct {
	Item       model.SupportAgent
	Languages  string
	Skills     string
	BadgeClass string
}

type SupportTicketDetailViewData struct {
	Detail                      model.SupportTicketDetail
	QueueURL                    string
	DisplayID                   string
	Context                     []SupportKeyValueView
	Events                      []SupportTicketEventView
	CSAT                        SupportTicketCSATView
	SavedReplies                []SupportSavedReplyRowView
	SLA                         SupportTicketSLAView
	CanReply                    bool
	CanManage                   bool
	AssigneeID                  string
	AssigneeInputValue          string
	AssigneeLabel               string
	AssigneeOptions             []SupportAssigneeOptionView
	UserLabel                   string
	LocaleLabel                 string
	PriorityReasonLabels        []string
	CustomerSegmentReasonLabels []string
	SegmentRefreshLabel         string
	AssignmentReasonLabels      []string
}

type SupportTicketCSATView struct {
	Rating      int
	RatingLabel string
	Comment     string
	CreatedAt   time.Time
}

type SupportTicketSLAView struct {
	LabelKey     string
	StateKey     string
	DisplayLabel string
	BadgeClass   string
	Breached     bool
}

type SupportTicketEventView struct {
	Item            model.SupportTicketEvent
	Payload         []SupportKeyValueView
	ActorLabel      string
	Message         string
	AttachmentCount int
	Attachments     []SupportTicketAttachmentView
	BubbleClass     string
}

type SupportTicketAttachmentView struct {
	Label string
	URL   string
}

type SupportAssigneeOptionView struct {
	StaffID     string
	DisplayName string
	Email       string
	SearchValue string
	Meta        string
}

type SupportAgentStaffOptionView struct {
	StaffID     string
	DisplayName string
	Email       string
	SearchValue string
}

type SupportKeyValueView struct {
	Key   string
	Value string
}

type SupportSavedReplyFormInput struct {
	ReplyID   string
	Category  string
	Status    string
	Tags      string
	SortOrder int
	EN        SupportSavedReplyLocaleInput
	RU        SupportSavedReplyLocaleInput
	KK        SupportSavedReplyLocaleInput
}

type SupportSavedReplyLocaleInput struct {
	Title string
	Body  string
}

type SupportAgentFormInput struct {
	StaffID       string
	StaffLookup   string
	FirstName     string
	LastName      string
	MiddleName    string
	Status        string
	Languages     string
	Skills        []model.SupportAgentSkill
	Level         string
	MaxActiveLoad float64
	Timezone      string
}

func NewSupportTicketQueueViewData(items []model.SupportTicket, filters SupportTicketFilterViewData, staff *model.StaffUser, locale string) SupportTicketQueueViewData {
	return NewSupportTicketQueueViewDataWithAssignees(items, filters, staff, locale, nil)
}

func NewSupportTicketQueueViewDataWithAssignees(items []model.SupportTicket, filters SupportTicketFilterViewData, staff *model.StaffUser, locale string, assigneeLabels map[string]string) SupportTicketQueueViewData {
	rows := make([]SupportTicketRowView, 0, len(items))
	now := time.Now().UTC()
	for _, item := range items {
		rows = append(rows, SupportTicketRowView{
			Item:                 item,
			DetailURL:            supportTicketDetailURL(item.ID, filters.Query),
			DisplayID:            supportTicketDisplayID(item.ID),
			BadgeClass:           supportTicketStatusBadgeClass(item.Status),
			SLA:                  supportTicketSLAView(item, now, locale),
			RelatedEntityID:      supportTicketRelatedEntityID(item.Context),
			ContextSummary:       supportContextSummary(item.Context),
			UserLabel:            supportTicketQueueUserLabel(item),
			AssigneeLabel:        supportTicketQueueAssigneeLabel(locale, item, assigneeLabels),
			LastMessagePreview:   supportTicketLastMessagePreview(item),
			PriorityReasonLabels: supportTranslatedCodeList(locale, "support.priorityReason.", item.PriorityReasonCodes),
		})
	}
	return SupportTicketQueueViewData{
		Items:           rows,
		Filters:         filters,
		StatusOptions:   supportStatusOptions(filters.Status),
		CategoryOptions: supportCategoryOptions(filters.Category),
		PriorityOptions: supportPriorityOptions(filters.Priority),
		SLAOptions:      supportSLAOptions(filters.SLA),
		FilterAction:    "/admin/support/tickets",
		ResetURL:        "/admin/support/tickets",
		CanReply:        staffCanSupportReply(staff),
		CanManage:       staffCanSupportManage(staff),
	}
}

func NewSupportSavedReplyListViewData(items []model.SupportSavedReply, filters SupportSavedReplyFilterViewData, input SupportSavedReplyFormInput, staff *model.StaffUser) SupportSavedReplyListViewData {
	return NewSupportSavedReplyListViewDataForLocale(items, filters, input, staff, "en")
}

func NewSupportSavedReplyListViewDataForLocale(items []model.SupportSavedReply, filters SupportSavedReplyFilterViewData, input SupportSavedReplyFormInput, staff *model.StaffUser, locale string) SupportSavedReplyListViewData {
	rows := make([]SupportSavedReplyRowView, 0, len(items))
	for _, item := range items {
		title := supportSavedReplyTitle(item, locale)
		body := supportSavedReplyBody(item, locale)
		rows = append(rows, SupportSavedReplyRowView{
			Item:         item,
			Title:        title,
			Body:         body,
			BodyPreview:  supportSavedReplyPreview(body),
			BadgeClass:   statusBadgeClass(string(item.Status)),
			Tags:         strings.Join(item.Tags, ", "),
			Translations: supportSavedReplyLocales(item.Translations),
		})
	}
	if strings.TrimSpace(input.Status) == "" {
		input.Status = string(model.HelpArticleStatusPublished)
	}
	return SupportSavedReplyListViewData{
		Items:               rows,
		Filters:             filters,
		Input:               input,
		StatusOptions:       helpArticleStatusOptions(filters.Status),
		CategoryOptions:     supportCategoryOptions(filters.Category),
		FormStatusOptions:   helpCategoryFormStatusOptions(input.Status),
		FormCategoryOptions: supportSavedReplyFormCategoryOptions(input.Category),
		FilterAction:        "/admin/support/saved-replies",
		ResetURL:            "/admin/support/saved-replies",
		SubmitURL:           "/admin/support/saved-replies",
		CanManage:           staffCanSupportManage(staff),
	}
}

func NewSupportAgentListViewData(items []model.SupportAgent, filters SupportAgentFilterViewData, input SupportAgentFormInput, staff *model.StaffUser, staffOptions []*model.StaffUser) SupportAgentListViewData {
	rows := make([]SupportAgentRowView, 0, len(items))
	for _, item := range items {
		rows = append(rows, SupportAgentRowView{
			Item:       item,
			Languages:  strings.Join(item.Languages, ", "),
			Skills:     supportAgentSkillsText(item.Skills),
			BadgeClass: supportAgentStatusBadgeClass(item.Status),
		})
	}
	if strings.TrimSpace(input.Status) == "" {
		input.Status = string(model.SupportAgentStatusActive)
	}
	if strings.TrimSpace(input.Level) == "" {
		input.Level = string(model.SupportAgentLevelAgent)
	}
	if input.MaxActiveLoad <= 0 {
		input.MaxActiveLoad = 8
	}
	if strings.TrimSpace(input.Timezone) == "" {
		input.Timezone = "Asia/Almaty"
	}
	return SupportAgentListViewData{
		Items:             rows,
		Filters:           filters,
		Input:             input,
		StaffOptions:      supportAgentStaffOptionViews(staffOptions),
		LanguageOptions:   supportAgentLanguageOptions(input.Languages),
		TimezoneOptions:   staffTimezoneOptions(input.Timezone),
		StatusOptions:     supportAgentFilterStatusOptions(filters.Status),
		FormStatusOptions: supportAgentStatusOptions(input.Status),
		LevelOptions:      supportAgentLevelOptions(input.Level),
		SkillOptions:      supportAgentSkillOptions(input.Skills),
		FilterAction:      "/admin/support/agents",
		ResetURL:          "/admin/support/agents",
		AgentSubmitURL:    "/admin/support/agents",
		CanManage:         staffCanSupportManage(staff),
	}
}

func NewSupportTicketDetailViewData(detail model.SupportTicketDetail, queueURL string, staff *model.StaffUser) SupportTicketDetailViewData {
	return NewSupportTicketDetailViewDataWithSavedReplies(detail, queueURL, nil, staff)
}

func NewSupportTicketDetailViewDataWithSavedReplies(detail model.SupportTicketDetail, queueURL string, savedReplies []model.SupportSavedReply, staff *model.StaffUser) SupportTicketDetailViewData {
	return NewSupportTicketDetailViewDataWithSavedRepliesForLocale(detail, queueURL, savedReplies, staff, "en")
}

func NewSupportTicketDetailViewDataWithSavedRepliesForLocale(detail model.SupportTicketDetail, queueURL string, savedReplies []model.SupportSavedReply, staff *model.StaffUser, locale string) SupportTicketDetailViewData {
	return NewSupportTicketDetailViewDataWithSavedRepliesForLocaleAndAssignee(detail, queueURL, savedReplies, staff, locale, "")
}

func NewSupportTicketDetailViewDataWithSavedRepliesForLocaleAndAssignee(detail model.SupportTicketDetail, queueURL string, savedReplies []model.SupportSavedReply, staff *model.StaffUser, locale string, assigneeLabel string, assigneeAgents ...model.SupportAgent) SupportTicketDetailViewData {
	if queueURL == "" {
		queueURL = "/admin/support/tickets"
	}
	resolvedAssigneeLabel := supportTicketAssigneeLabel(detail, staff, assigneeLabel)
	events := make([]SupportTicketEventView, 0, len(detail.Events))
	for eventIndex, event := range detail.Events {
		events = append(events, SupportTicketEventView{
			Item:            event,
			Payload:         supportKeyValues(event.Payload),
			ActorLabel:      supportTicketEventActorLabel(locale, detail, event, resolvedAssigneeLabel),
			Message:         supportTicketEventMessage(locale, event),
			AttachmentCount: supportTicketEventAttachmentCount(event),
			Attachments:     supportTicketEventAttachments(detail.Ticket.ID, eventIndex, event),
			BubbleClass:     supportTicketEventBubbleClass(event),
		})
	}
	replyRows := make([]SupportSavedReplyRowView, 0, len(savedReplies))
	for _, reply := range savedReplies {
		title := supportSavedReplyTitle(reply, locale)
		body := supportSavedReplyBody(reply, locale)
		replyRows = append(replyRows, SupportSavedReplyRowView{
			Item:         reply,
			Title:        title,
			Body:         body,
			BodyPreview:  supportSavedReplyPreview(body),
			BadgeClass:   statusBadgeClass(string(reply.Status)),
			Tags:         strings.Join(reply.Tags, ", "),
			Translations: supportSavedReplyLocales(reply.Translations),
		})
	}
	return SupportTicketDetailViewData{
		Detail:                      detail,
		QueueURL:                    queueURL,
		DisplayID:                   supportTicketDisplayID(detail.Ticket.ID),
		Context:                     supportTicketDisplayContext(detail.Ticket.Context),
		Events:                      events,
		CSAT:                        supportTicketCSATView(detail.Events),
		SavedReplies:                replyRows,
		SLA:                         supportTicketSLAView(detail.Ticket, time.Now().UTC(), locale),
		CanReply:                    staffCanSupportReply(staff),
		CanManage:                   staffCanSupportManage(staff),
		AssigneeID:                  defaultSupportAssigneeID(detail.Ticket, staff),
		AssigneeInputValue:          supportAssigneeInputValue(detail.Ticket, resolvedAssigneeLabel),
		AssigneeLabel:               resolvedAssigneeLabel,
		AssigneeOptions:             supportAssigneeOptions(assigneeAgents),
		UserLabel:                   supportTicketUserLabel(detail, locale),
		LocaleLabel:                 supportTicketLocaleLabel(string(detail.Ticket.Locale), locale),
		PriorityReasonLabels:        supportTranslatedCodeList(locale, "support.priorityReason.", detail.Ticket.PriorityReasonCodes),
		CustomerSegmentReasonLabels: supportTranslatedCodeList(locale, "support.segmentReason.", detail.Ticket.CustomerSegmentReasonCodes),
		SegmentRefreshLabel:         supportTranslatedCode(locale, "support.segmentRefresh.", detail.Ticket.SegmentRefreshStatus),
		AssignmentReasonLabels:      supportTranslatedCodeList(locale, "support.assignmentReasonCode.", detail.Ticket.AssignmentReasonCodes),
	}
}

func supportStatusOptions(selected string) []SupportOptionView {
	values := []string{
		"waiting_support",
		"new",
		"assigned",
		"waiting_user",
		"resolved",
		"reopened",
		"closed",
		"all",
	}
	return supportOptions("support.status.", values, selected)
}

func supportCategoryOptions(selected string) []SupportOptionView {
	values := []string{"", "account", "activities", "excursions", "places", "payments", "currency", "technical"}
	return supportOptions("support.category.", values, selected)
}

func supportPriorityOptions(selected string) []SupportOptionView {
	values := []string{"", "urgent", "high", "normal", "low"}
	return supportOptions("support.priority.", values, selected)
}

func supportSLAOptions(selected string) []SupportOptionView {
	values := []string{"", "breached"}
	return supportOptions("support.slaFilter.", values, selected)
}

func supportAgentFilterStatusOptions(selected string) []SupportOptionView {
	values := []string{"", "active", "paused", "offline", "on_leave"}
	return supportOptions("support.agentStatus.", values, selected)
}

func supportAgentStatusOptions(selected string) []SupportOptionView {
	values := []string{"active", "paused", "offline", "on_leave"}
	return supportOptions("support.agentStatus.", values, selected)
}

func supportAgentLevelOptions(selected string) []SupportOptionView {
	values := []string{"agent", "senior", "lead"}
	return supportOptions("support.agentLevel.", values, selected)
}

func supportAgentSkillOptions(selected []model.SupportAgentSkill) []SupportOptionView {
	values := []string{"account", "activities", "excursions", "places", "payments", "currency", "safety", "technical"}
	selectedSet := make(map[string]struct{}, len(selected))
	for _, skill := range selected {
		selectedSet[string(skill)] = struct{}{}
	}
	options := make([]SupportOptionView, 0, len(values))
	for _, value := range values {
		_, ok := selectedSet[value]
		options = append(options, SupportOptionView{
			Value:    value,
			LabelKey: "support.agentSkill." + value,
			Selected: ok,
		})
	}
	return options
}

func supportAgentLanguageOptions(selected string) []SupportOptionView {
	values := []string{"ru", "en", "kk"}
	selectedValues := splitCSV(selected)
	options := make([]SupportOptionView, 0, len(values))
	for _, value := range values {
		options = append(options, SupportOptionView{
			Value:    value,
			LabelKey: "support.agentLanguage." + value,
			Selected: stringInSlice(selectedValues, value),
		})
	}
	return options
}

func supportSavedReplyFormCategoryOptions(selected string) []SupportOptionView {
	values := []string{"account", "activities", "excursions", "places", "payments", "currency", "technical"}
	return supportOptions("support.category.", values, selected)
}

func supportOptions(prefix string, values []string, selected string) []SupportOptionView {
	options := make([]SupportOptionView, 0, len(values))
	for _, value := range values {
		labelValue := value
		if labelValue == "" {
			labelValue = "all"
		}
		options = append(options, SupportOptionView{
			Value:    value,
			LabelKey: prefix + labelValue,
			Selected: value == selected,
		})
	}
	return options
}

func staffCanSupportRead(staff *model.StaffUser) bool {
	return staff != nil && (staff.HasPermission(enum.PermissionSupportRead) || staffCanSupportReply(staff) || staffCanSupportManage(staff))
}

func staffCanSupportReply(staff *model.StaffUser) bool {
	return staff != nil && (staff.HasPermission(enum.PermissionSupportReply) || staffCanSupportManage(staff))
}

func staffCanSupportManage(staff *model.StaffUser) bool {
	return staff != nil && (staff.HasPermission(enum.PermissionSupportManage) ||
		staff.HasRole(enum.StaffRoleSupportLead) ||
		staff.HasRole(enum.StaffRoleSupportAdmin) ||
		staff.HasRole(enum.StaffRoleSuperAdmin))
}

func supportTicketStatusBadgeClass(status model.SupportTicketStatus) string {
	switch status {
	case model.SupportTicketStatusResolved, model.SupportTicketStatusClosed:
		return "badge badge-success"
	case model.SupportTicketStatusNew, model.SupportTicketStatusWaitingSupport, model.SupportTicketStatusReopened:
		return "badge badge-warn"
	case model.SupportTicketStatusAssigned, model.SupportTicketStatusOpen:
		return "badge badge-info"
	default:
		return "badge"
	}
}

func supportAgentStatusBadgeClass(status model.SupportAgentStatus) string {
	switch status {
	case model.SupportAgentStatusActive:
		return "badge badge-success"
	case model.SupportAgentStatusPaused, model.SupportAgentStatusOnLeave:
		return "badge badge-warn"
	case model.SupportAgentStatusOffline:
		return "badge"
	default:
		return "badge"
	}
}

func supportTicketSLAView(ticket model.SupportTicket, now time.Time, locale string) SupportTicketSLAView {
	if ticket.ID == "" || ticket.CreatedAt.IsZero() {
		return SupportTicketSLAView{}
	}
	if supportTicketIsTerminal(ticket.Status) {
		return SupportTicketSLAView{
			LabelKey:     "support.sla.completed",
			StateKey:     "support.sla.completed",
			DisplayLabel: supportSLACompletedLabel(locale),
			BadgeClass:   "badge badge-success",
		}
	}
	if ticket.FirstResponseAt == nil {
		target := supportTicketFirstResponseSLA(ticket.Priority)
		firstResponseDueAt := ticket.CreatedAt.Add(target)
		if now.After(firstResponseDueAt) {
			return SupportTicketSLAView{
				LabelKey:     "support.sla.firstResponseOverdue",
				StateKey:     "support.sla.breached",
				DisplayLabel: supportSLAFirstResponseOverdueLabel(locale),
				BadgeClass:   "badge badge-danger",
				Breached:     true,
			}
		}
		return SupportTicketSLAView{
			LabelKey:     "support.sla.firstResponseDue",
			StateKey:     "support.sla.onTrack",
			DisplayLabel: supportSLAFirstResponseTargetLabel(locale, target),
			BadgeClass:   "badge badge-info",
		}
	}

	target := supportTicketResolutionSLA(ticket.Priority)
	resolutionDueAt := ticket.CreatedAt.Add(target)
	if now.After(resolutionDueAt) {
		return SupportTicketSLAView{
			LabelKey:     "support.sla.resolutionOverdue",
			StateKey:     "support.sla.breached",
			DisplayLabel: supportSLAResolutionOverdueLabel(locale),
			BadgeClass:   "badge badge-danger",
			Breached:     true,
		}
	}
	return SupportTicketSLAView{
		LabelKey:     "support.sla.resolutionDue",
		StateKey:     "support.sla.onTrack",
		DisplayLabel: supportSLAResolutionTargetLabel(locale, target),
		BadgeClass:   "badge badge-info",
	}
}

func supportSLAFirstResponseTargetLabel(locale string, target time.Duration) string {
	switch normalizeLocaleOrDefault(locale) {
	case localeRU:
		return "Ответ за " + supportSLADurationLabel(locale, target)
	default:
		return "Answer within " + supportSLADurationLabel(locale, target)
	}
}

func supportSLAResolutionTargetLabel(locale string, target time.Duration) string {
	switch normalizeLocaleOrDefault(locale) {
	case localeRU:
		return "Решение за " + supportSLADurationLabel(locale, target)
	default:
		return "Resolve within " + supportSLADurationLabel(locale, target)
	}
}

func supportSLAFirstResponseOverdueLabel(locale string) string {
	switch normalizeLocaleOrDefault(locale) {
	case localeRU:
		return "Ответ просрочен"
	default:
		return "Answer overdue"
	}
}

func supportSLAResolutionOverdueLabel(locale string) string {
	switch normalizeLocaleOrDefault(locale) {
	case localeRU:
		return "Решение просрочено"
	default:
		return "Resolution overdue"
	}
}

func supportSLACompletedLabel(locale string) string {
	switch normalizeLocaleOrDefault(locale) {
	case localeRU:
		return "Завершен"
	default:
		return "Completed"
	}
}

func supportSLADurationLabel(locale string, duration time.Duration) string {
	minutes := int(duration.Minutes())
	if minutes < 60 {
		if normalizeLocaleOrDefault(locale) == localeEN {
			return strconv.Itoa(minutes) + " min"
		}
		return strconv.Itoa(minutes) + " мин"
	}
	hours := int(duration.Hours())
	if normalizeLocaleOrDefault(locale) == localeEN {
		return strconv.Itoa(hours) + " h"
	}
	return strconv.Itoa(hours) + " ч"
}

func supportTicketIsTerminal(status model.SupportTicketStatus) bool {
	return status == model.SupportTicketStatusResolved || status == model.SupportTicketStatusClosed
}

func supportTicketFirstResponseSLA(priority model.SupportTicketPriority) time.Duration {
	switch priority {
	case model.SupportTicketPriorityUrgent:
		return 10 * time.Minute
	case model.SupportTicketPriorityHigh:
		return 20 * time.Minute
	default:
		return 30 * time.Minute
	}
}

func supportTicketResolutionSLA(priority model.SupportTicketPriority) time.Duration {
	switch priority {
	case model.SupportTicketPriorityUrgent:
		return 4 * time.Hour
	case model.SupportTicketPriorityHigh:
		return 12 * time.Hour
	default:
		return 24 * time.Hour
	}
}

func supportKeyValues(values map[string]string) []SupportKeyValueView {
	if len(values) == 0 {
		return nil
	}
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	out := make([]SupportKeyValueView, 0, len(keys))
	for _, key := range keys {
		out = append(out, SupportKeyValueView{Key: key, Value: values[key]})
	}
	return out
}

func supportContextKeyHiddenFromQueue(key string) bool {
	normalized := strings.ToLower(strings.TrimSpace(key))
	return normalized == "entity_id" || normalized == "previous_ticket_id"
}

func supportTicketDisplayContext(values map[string]string) []SupportKeyValueView {
	rawItems := supportKeyValues(values)
	items := make([]SupportKeyValueView, 0, len(rawItems))
	for _, item := range rawItems {
		if supportContextKeyHiddenFromQueue(item.Key) {
			continue
		}
		items = append(items, item)
	}
	return items
}

func supportTicketRelatedEntityID(values map[string]string) string {
	value := strings.TrimSpace(values["entity_id"])
	if supportTicketIDHasInternalPrefix(value) {
		return ""
	}
	return value
}

func supportTicketDisplayID(ticketID string) string {
	value := strings.TrimSpace(ticketID)
	if value == "" {
		return "-"
	}
	if trimmed := strings.TrimPrefix(value, "support-"); trimmed != "" && trimmed != value {
		return trimmed
	}
	return value
}

func supportTicketIDHasInternalPrefix(value string) bool {
	return strings.HasPrefix(strings.TrimSpace(value), "support-")
}

func supportContextSummary(values map[string]string) string {
	items := supportTicketDisplayContext(values)
	if len(items) == 0 {
		return "-"
	}
	if len(items) > 2 {
		items = items[:2]
	}
	summary := ""
	for index, item := range items {
		if index > 0 {
			summary += " · "
		}
		summary += item.Key + ": " + item.Value
	}
	return summary
}

func supportTicketQueueUserLabel(ticket model.SupportTicket) string {
	if value := strings.TrimSpace(ticket.UserNicknameSnapshot); value != "" {
		return value
	}
	if value := strings.TrimSpace(ticket.Context["user_nickname"]); value != "" {
		return value
	}
	return "User"
}

func supportTicketLastMessagePreview(ticket model.SupportTicket) string {
	value := strings.TrimSpace(ticket.LastMessagePreview)
	if value == "" {
		return "-"
	}
	if len([]rune(value)) <= 140 {
		return value
	}
	runes := []rune(value)
	return string(runes[:140]) + "..."
}

func supportTicketQueueAssignmentLabel(locale string, ticket model.SupportTicket) string {
	status := strings.TrimSpace(string(ticket.AssignmentStatus))
	if status == "" {
		if strings.TrimSpace(ticket.AssigneeID) != "" {
			status = "assigned"
		} else {
			status = "needs_assignment"
		}
	}
	return supportTranslatedCode(locale, "support.assignment.", status)
}

func supportTicketQueueAssigneeLabel(locale string, ticket model.SupportTicket, labels map[string]string) string {
	assigneeID := strings.TrimSpace(ticket.AssigneeID)
	if assigneeID == "" {
		return supportTranslatedCode(locale, "support.assignment.", "needs_assignment")
	}
	if labels != nil {
		if label := strings.TrimSpace(labels[assigneeID]); label != "" {
			return label
		}
	}
	return supportTranslatedCode(locale, "support.assignment.", "assigned")
}

func defaultSupportAssigneeID(ticket model.SupportTicket, staff *model.StaffUser) string {
	if ticket.AssigneeID != "" {
		return ticket.AssigneeID
	}
	if staff == nil {
		return ""
	}
	return staff.ID.String()
}

func supportTicketUserLabel(detail model.SupportTicketDetail, locale string) string {
	if value := strings.TrimSpace(detail.Ticket.UserNicknameSnapshot); value != "" {
		return value
	}
	for _, event := range detail.Events {
		if event.ActorType != "user" {
			continue
		}
		if value := firstSupportPayloadValue(event.Payload, "actor_nickname", "actorNickname", "nickname"); value != "" {
			return value
		}
	}
	if value := strings.TrimSpace(detail.Ticket.Context["user_nickname"]); value != "" {
		return value
	}
	return supportTranslatedCode(locale, "support.actor.", "user")
}

func supportTicketAssigneeLabel(detail model.SupportTicketDetail, staff *model.StaffUser, assigneeLabel string) string {
	assigneeID := strings.TrimSpace(detail.Ticket.AssigneeID)
	if assigneeID == "" {
		return "-"
	}
	if value := strings.TrimSpace(assigneeLabel); value != "" {
		return value
	}
	if staff != nil && assigneeID == staff.ID.String() {
		if value := strings.TrimSpace(staff.DisplayName); value != "" {
			return value
		}
		if value := strings.TrimSpace(staff.Email); value != "" {
			return value
		}
	}
	for _, event := range detail.Events {
		if strings.TrimSpace(event.ActorID) != assigneeID {
			continue
		}
		if value := firstSupportPayloadValue(event.Payload, "actor_display_name", "actorDisplayName", "display_name"); value != "" {
			return value
		}
	}
	return "-"
}

func supportAssigneeOptions(agents []model.SupportAgent) []SupportAssigneeOptionView {
	options := make([]SupportAssigneeOptionView, 0, len(agents))
	seen := make(map[string]struct{}, len(agents))
	for _, agent := range agents {
		staffID := strings.TrimSpace(agent.StaffID)
		if staffID == "" || agent.Status != model.SupportAgentStatusActive {
			continue
		}
		if _, ok := seen[staffID]; ok {
			continue
		}
		seen[staffID] = struct{}{}
		displayName := strings.TrimSpace(agent.DisplayName)
		email := strings.TrimSpace(agent.Email)
		if email == "" && (displayName == "" || displayName == staffID) {
			continue
		}
		if displayName == "" || displayName == staffID {
			displayName = email
		}
		options = append(options, SupportAssigneeOptionView{
			StaffID:     staffID,
			DisplayName: displayName,
			Email:       email,
			SearchValue: supportAssigneeSearchValue(agent),
			Meta:        supportAssigneeMeta(agent),
		})
	}
	sort.SliceStable(options, func(left int, right int) bool {
		return strings.ToLower(options[left].DisplayName) < strings.ToLower(options[right].DisplayName)
	})
	return options
}

func supportAssigneeInputValue(ticket model.SupportTicket, assigneeLabel string) string {
	assigneeID := strings.TrimSpace(ticket.AssigneeID)
	label := strings.TrimSpace(assigneeLabel)
	if assigneeID == "" {
		return ""
	}
	if label == "" || label == "-" || label == assigneeID {
		return ""
	}
	return label
}

func supportAssigneeSearchValue(agent model.SupportAgent) string {
	staffID := strings.TrimSpace(agent.StaffID)
	displayName := strings.TrimSpace(agent.DisplayName)
	email := strings.TrimSpace(agent.Email)
	if displayName != "" && displayName != staffID {
		return displayName
	}
	if email != "" {
		return email
	}
	if displayName == "" || displayName == staffID {
		return ""
	}
	return displayName
}

func supportAssigneeMeta(agent model.SupportAgent) string {
	parts := make([]string, 0, 3)
	if len(agent.Languages) > 0 {
		parts = append(parts, strings.Join(agent.Languages, ", "))
	}
	if strings.TrimSpace(agent.Email) != "" {
		parts = append(parts, strings.TrimSpace(agent.Email))
	}
	if len(agent.Skills) > 0 {
		parts = append(parts, supportAgentSkillsText(agent.Skills))
	}
	if agent.Level != "" {
		parts = append(parts, string(agent.Level))
	}
	if len(parts) == 0 {
		return "-"
	}
	return strings.Join(parts, " · ")
}

func supportAgentStaffOptionViews(staff []*model.StaffUser) []SupportAgentStaffOptionView {
	options := make([]SupportAgentStaffOptionView, 0, len(staff))
	for _, item := range staff {
		if item == nil || item.ID == uuid.Nil {
			continue
		}
		displayName := strings.TrimSpace(item.DisplayName)
		email := strings.TrimSpace(item.Email)
		if displayName == "" && email == "" {
			continue
		}
		options = append(options, SupportAgentStaffOptionView{
			StaffID:     item.ID.String(),
			DisplayName: displayName,
			Email:       email,
			SearchValue: supportAgentStaffSearchValue(item),
		})
	}
	sort.SliceStable(options, func(left int, right int) bool {
		return strings.ToLower(options[left].SearchValue) < strings.ToLower(options[right].SearchValue)
	})
	return options
}

func supportAgentStaffSearchValue(staff *model.StaffUser) string {
	if staff == nil {
		return ""
	}
	displayName := strings.TrimSpace(staff.DisplayName)
	email := strings.TrimSpace(staff.Email)
	if displayName == "" {
		return email
	}
	if email == "" || strings.EqualFold(displayName, email) {
		return displayName
	}
	return displayName + " · " + email
}

func supportAssigneeIDFromQuery(query string, agents []model.SupportAgent) string {
	normalizedQuery := normalizeSupportAssigneeSearch(query)
	if normalizedQuery == "" {
		return ""
	}
	for _, agent := range agents {
		if agent.Status != model.SupportAgentStatusActive {
			continue
		}
		candidates := []string{
			agent.StaffID,
			agent.DisplayName,
			agent.Email,
			supportAssigneeSearchValue(agent),
		}
		for _, candidate := range candidates {
			if normalizeSupportAssigneeSearch(candidate) == normalizedQuery {
				return strings.TrimSpace(agent.StaffID)
			}
		}
	}
	return ""
}

func normalizeSupportAssigneeSearch(value string) string {
	return strings.ToLower(strings.Join(strings.Fields(strings.TrimSpace(value)), " "))
}

func supportTranslatedCodeList(locale string, prefix string, codes []string) []string {
	labels := make([]string, 0, len(codes))
	for _, code := range codes {
		if label := supportTranslatedCode(locale, prefix, code); label != "" && label != "-" {
			labels = append(labels, label)
		}
	}
	return labels
}

func supportTranslatedCode(locale string, prefix string, code any) string {
	raw := strings.TrimSpace(toString(code))
	if raw == "" {
		return "-"
	}
	key := prefix + raw
	value := translate(locale, key)
	if value != key {
		return value
	}
	return humanizeSupportCode(raw)
}

func humanizeSupportCode(raw string) string {
	words := strings.Fields(strings.NewReplacer("_", " ", "-", " ").Replace(strings.TrimSpace(raw)))
	for index, word := range words {
		if word == "" {
			continue
		}
		lower := strings.ToLower(word)
		words[index] = strings.ToUpper(lower[:1]) + lower[1:]
	}
	if len(words) == 0 {
		return "-"
	}
	return strings.Join(words, " ")
}

func supportTicketEventActorLabel(locale string, detail model.SupportTicketDetail, event model.SupportTicketEvent, assigneeLabel string) string {
	switch event.ActorType {
	case "user":
		if value := firstSupportPayloadValue(event.Payload, "actor_nickname", "actorNickname", "nickname"); value != "" {
			return value
		}
		if value := strings.TrimSpace(detail.Ticket.UserNicknameSnapshot); value != "" {
			return value
		}
		if value := strings.TrimSpace(detail.Ticket.Context["user_nickname"]); value != "" {
			return value
		}
		return supportTranslatedCode(locale, "support.actor.", "user")
	case "support_agent", "support_admin":
		if value := firstSupportPayloadValue(event.Payload, "actor_display_name", "actorDisplayName", "display_name"); value != "" {
			return value
		}
		if strings.TrimSpace(event.ActorID) != "" &&
			strings.TrimSpace(event.ActorID) == strings.TrimSpace(detail.Ticket.AssigneeID) {
			label := strings.TrimSpace(assigneeLabel)
			if label != "" && label != "-" && label != strings.TrimSpace(event.ActorID) {
				return label
			}
		}
		return supportTranslatedCode(locale, "support.actor.", "agent")
	default:
		if value := firstSupportPayloadValue(event.Payload, "actor_display_name", "actorDisplayName", "display_name"); value != "" {
			return value
		}
		return supportTranslatedCode(locale, "support.actor.", "system")
	}
}

func supportTicketEventMessage(locale string, event model.SupportTicketEvent) string {
	if strings.TrimSpace(event.EventType) == "ticket_csat_submitted" {
		return supportTranslatedCode(locale, "support.event.", "ticket_csat_submitted")
	}
	if value := firstSupportPayloadValue(event.Payload, "message_preview", "message", "note", "resolution", "comment"); value != "" {
		return value
	}
	switch strings.TrimSpace(event.EventType) {
	case "ticket_created":
		return supportTranslatedCode(locale, "support.event.", "ticket_created")
	case "ticket_segment_calculated":
		return supportTranslatedCode(locale, "support.event.", "ticket_segment_calculated")
	case "ticket_priority_calculated":
		return supportTranslatedCode(locale, "support.event.", "ticket_priority_calculated")
	case "ticket_auto_assigned":
		return supportTranslatedCode(locale, "support.event.", "ticket_auto_assigned")
	case "ticket_assignment_failed":
		return supportTranslatedCode(locale, "support.event.", "ticket_assignment_failed")
	case "ticket_closed_by_user":
		return supportTranslatedCode(locale, "support.event.", "ticket_closed_by_user")
	case "ticket_csat_submitted":
		return supportTranslatedCode(locale, "support.event.", "ticket_csat_submitted")
	case "ticket_resolved":
		return supportTranslatedCode(locale, "support.event.", "ticket_resolved")
	case "ticket_reopened":
		return supportTranslatedCode(locale, "support.event.", "ticket_reopened")
	case "user_replied":
		return supportTranslatedCode(locale, "support.event.", "user_replied")
	case "agent_replied":
		return supportTranslatedCode(locale, "support.event.", "agent_replied")
	default:
		return supportTranslatedCode(locale, "support.event.", event.EventType)
	}
}

func supportTicketCSATView(events []model.SupportTicketEvent) SupportTicketCSATView {
	var result SupportTicketCSATView
	for _, event := range events {
		if strings.TrimSpace(event.EventType) != "ticket_csat_submitted" {
			continue
		}
		rating, ok := supportTicketCSATRating(event.Payload)
		if !ok {
			continue
		}
		if result.Rating != 0 && !event.CreatedAt.After(result.CreatedAt) {
			continue
		}
		result = SupportTicketCSATView{
			Rating:      rating,
			RatingLabel: strconv.Itoa(rating) + "/5",
			Comment:     firstSupportPayloadValue(event.Payload, "comment", "feedback", "csat_comment"),
			CreatedAt:   event.CreatedAt,
		}
	}
	return result
}

func supportTicketCSATRating(payload map[string]string) (int, bool) {
	value := firstSupportPayloadValue(payload, "rating", "csat_rating")
	rating, err := strconv.Atoi(value)
	if err != nil || rating < 1 || rating > 5 {
		return 0, false
	}
	return rating, true
}

func supportTicketEventAttachmentCount(event model.SupportTicketEvent) int {
	if count, err := strconv.Atoi(strings.TrimSpace(event.Payload["attachment_count"])); err == nil && count > 0 {
		return count
	}
	return len(supportTicketEventFileIDs(event))
}

func supportTicketEventAttachments(ticketID string, eventIndex int, event model.SupportTicketEvent) []SupportTicketAttachmentView {
	ticketID = strings.TrimSpace(ticketID)
	if ticketID == "" {
		ticketID = strings.TrimSpace(event.TicketID)
	}
	if ticketID == "" || eventIndex < 0 {
		return nil
	}
	fileIDs := supportTicketEventFileIDs(event)
	attachments := make([]SupportTicketAttachmentView, 0, len(fileIDs))
	for attachmentIndex := range fileIDs {
		attachments = append(attachments, SupportTicketAttachmentView{
			Label: "Attachment " + strconv.Itoa(attachmentIndex+1),
			URL:   supportTicketAttachmentURL(ticketID, eventIndex, attachmentIndex),
		})
	}
	return attachments
}

func supportTicketEventFileIDs(event model.SupportTicketEvent) []string {
	raw := strings.TrimSpace(event.Payload["file_ids"])
	if raw == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	fileIDs := make([]string, 0, len(parts))
	for _, part := range parts {
		fileID := strings.TrimSpace(part)
		if fileID != "" {
			fileIDs = append(fileIDs, fileID)
		}
	}
	return fileIDs
}

func supportTicketAttachmentURL(ticketID string, eventIndex int, attachmentIndex int) string {
	return "/admin/support/tickets/" + url.PathEscape(strings.TrimSpace(ticketID)) + "/attachments/" + strconv.Itoa(eventIndex) + "/" + strconv.Itoa(attachmentIndex)
}

func supportTicketEventBubbleClass(event model.SupportTicketEvent) string {
	switch event.ActorType {
	case "user":
		return "support-chat-bubble support-chat-bubble-user"
	case "support_agent", "support_admin":
		return "support-chat-bubble support-chat-bubble-agent"
	default:
		return "support-chat-bubble support-chat-bubble-system"
	}
}

func supportTicketLocaleLabel(ticketLocale string, pageLocale string) string {
	normalized := strings.ToLower(strings.TrimSpace(ticketLocale))
	if dash := strings.IndexAny(normalized, "-_"); dash > 0 {
		normalized = normalized[:dash]
	}
	pageLocale = strings.ToLower(strings.TrimSpace(pageLocale))
	if dash := strings.IndexAny(pageLocale, "-_"); dash > 0 {
		pageLocale = pageLocale[:dash]
	}
	labels := map[string]map[string]string{
		"en": {"en": "English", "ru": "Russian", "kk": "Kazakh"},
		"ru": {"en": "Английский", "ru": "Русский", "kk": "Казахский"},
		"kk": {"en": "Ағылшын", "ru": "Орыс", "kk": "Қазақша"},
	}
	if pageLabels, ok := labels[pageLocale]; ok {
		if value := pageLabels[normalized]; value != "" {
			return value
		}
	}
	if value := labels["en"][normalized]; value != "" {
		return value
	}
	return strings.TrimSpace(ticketLocale)
}

func firstSupportPayloadValue(payload map[string]string, keys ...string) string {
	for _, key := range keys {
		if value := strings.TrimSpace(payload[key]); value != "" {
			return value
		}
	}
	return ""
}

func supportSavedReplyTitle(reply model.SupportSavedReply, locale string) string {
	for _, locale := range supportSavedReplyLocaleOrder(locale) {
		if translation, ok := reply.Translations[locale]; ok && strings.TrimSpace(translation.Title) != "" {
			return strings.TrimSpace(translation.Title)
		}
	}
	return reply.ID
}

func supportSavedReplyBody(reply model.SupportSavedReply, locale string) string {
	for _, locale := range supportSavedReplyLocaleOrder(locale) {
		if translation, ok := reply.Translations[locale]; ok && strings.TrimSpace(translation.Body) != "" {
			return strings.TrimSpace(translation.Body)
		}
	}
	return "-"
}

func supportSavedReplyLocaleOrder(locale string) []string {
	normalized, ok := normalizeLocale(locale)
	if !ok {
		normalized = "en"
	}
	order := make([]string, 0, 3)
	add := func(candidate string) {
		for _, existing := range order {
			if existing == candidate {
				return
			}
		}
		order = append(order, candidate)
	}
	add(normalized)
	for _, fallback := range []string{"ru", "kk", "en"} {
		add(fallback)
	}
	return order
}

func supportSavedReplyPreview(body string) string {
	const maxRunes = 80
	value := strings.TrimSpace(body)
	runes := []rune(value)
	if len(runes) <= maxRunes {
		return value
	}
	return strings.TrimSpace(string(runes[:maxRunes])) + "..."
}

func supportSavedReplyLocales(translations map[string]model.SupportSavedReplyTranslation) string {
	locales := make([]string, 0, 3)
	for _, locale := range []string{"en", "ru", "kk"} {
		if translation, ok := translations[locale]; ok && strings.TrimSpace(translation.Title) != "" {
			locales = append(locales, locale)
		}
	}
	if len(locales) == 0 {
		return "-"
	}
	return strings.Join(locales, ", ")
}

func supportAgentSkillsText(skills []model.SupportAgentSkill) string {
	labels := make([]string, 0, len(skills))
	for _, skill := range skills {
		if strings.TrimSpace(string(skill)) != "" {
			labels = append(labels, string(skill))
		}
	}
	sort.Strings(labels)
	if len(labels) == 0 {
		return "-"
	}
	return strings.Join(labels, ", ")
}
