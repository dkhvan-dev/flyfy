package http

import (
	"encoding/json"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

type PageData struct {
	Title     string
	Locale    string
	Path      string
	Staff     *model.StaffUser
	CSRFToken string
	Error     string
	Flash     string
	ActiveNav string
	Data      any
}

type LoginViewData struct {
	Email string
}

type DashboardViewData struct {
	Sections []DashboardSectionView
}

type DashboardSectionView struct {
	TitleKey   string
	EmptyKey   string
	ViewAllURL string
	Items      []ModerationQueueItemView
}

type QueueViewData struct {
	Items                []ModerationQueueItemView
	Filters              QueueFilterViewData
	IsHistory            bool
	FilterAction         string
	ResetURL             string
	OpenQueueURL         string
	HistoryURL           string
	CurrentGuidesURL     string
	SyncAction           string
	DetailBaseURL        string
	TitleKey             string
	HistoryTitleKey      string
	EmptyQueueKey        string
	EmptyHistoryKey      string
	TargetHeaderKey      string
	HostHeaderKey        string
	LocationHeaderKey    string
	SearchPlaceholderKey string
}

type QueueFilterViewData struct {
	Status string
	City   string
	Search string
	Signal string
	Risk   string
	Sort   string
	Query  string
}

type ModerationQueueItemView struct {
	Case             *model.ModerationCase
	Excursion        *model.ExcursionModerationItem
	Activity         *model.ActivityModerationItem
	GuideApplication *model.GuideApplicationModerationItem
	ChatMessage      *model.ChatMessageModerationItem
	TargetTitle      string
	TargetSubtitle   string
	GuideName        string
	GuideFullName    string
	DetailURL        string
}

type CaseDetailViewData struct {
	Detail *app.ModerationCaseDetail
}

type GuideListViewData struct {
	Items      []model.GuideApplicationModerationItem
	QueueURL   string
	HistoryURL string
}

type AttractionListViewData struct {
	Items      []model.AdminAttraction
	Filters    AttractionFilterViewData
	Total      int
	Pagination AttractionPaginationViewData
	Countries  []AttractionOptionView
	Cities     []AttractionOptionView
}

type AttractionFilterViewData struct {
	Search      string
	Category    string
	Status      string
	CountryCode string
	CityID      string
	Page        int
	Query       string
}

type AttractionPaginationViewData struct {
	Page          int
	PageSize      int
	Total         int
	TotalPages    int
	From          int
	To            int
	HasPrevious   bool
	HasNext       bool
	PreviousQuery string
	NextQuery     string
}

type AttractionFormViewData struct {
	Item                 *model.AdminAttraction
	Input                model.AttractionInput
	IsEdit               bool
	SubmitURL            string
	MediaURL             string
	Categories           []AttractionOptionView
	Statuses             []AttractionOptionView
	Locales              []AttractionOptionView
	Countries            []AttractionOptionView
	Cities               []AttractionOptionView
	Currencies           []AttractionOptionView
	AccessCityOptions    []AttractionCityLinkOptionView
	DepartureCityOptions []AttractionCityLinkOptionView
}

type AttractionOptionView struct {
	Value       string
	LabelKey    string
	Selected    bool
	CountryCode string
}

type AttractionCityLinkOptionView struct {
	Value       string
	CountryCode string
	CityID      string
	Selected    bool
}

type StaffListViewData struct {
	Staff             []*model.StaffUser
	AssignableRoles   []enum.StaffRole
	TemporaryPassword string
}

type StaffEditViewData struct {
	Staff             *model.StaffUser
	AssignableRoles   []enum.StaffRole
	Statuses          []enum.StaffStatus
	TemporaryPassword string
}

type StaffProfileViewData struct {
	Staff            *model.StaffUser
	TimezoneOptions  []TimezoneOptionView
	CurrentLocalTime string
	Items            []AuditEventView
}

type TimezoneOptionView struct {
	Value    string
	Label    string
	Selected bool
}

type AuditViewData struct {
	Events []*model.AuditEvent
	Items  []AuditEventView
}

type AuditEventView struct {
	Event          *model.AuditEvent
	ActionText     string
	ActorTitle     string
	ActorSubtitle  string
	EntityTitle    string
	EntitySubtitle string
	Details        []string
	RequestText    string
}

func NewStaffListViewData(actor *model.StaffUser, staff []*model.StaffUser, temporaryPassword ...string) StaffListViewData {
	value := ""
	if len(temporaryPassword) > 0 {
		value = temporaryPassword[0]
	}
	return StaffListViewData{
		Staff:             staff,
		AssignableRoles:   assignableStaffRoles(actor),
		TemporaryPassword: value,
	}
}

func NewStaffEditViewData(actor *model.StaffUser, staff *model.StaffUser, temporaryPassword ...string) StaffEditViewData {
	value := ""
	if len(temporaryPassword) > 0 {
		value = temporaryPassword[0]
	}
	return StaffEditViewData{
		Staff:             staff,
		AssignableRoles:   assignableStaffRoles(actor),
		Statuses:          editableStaffStatuses(),
		TemporaryPassword: value,
	}
}

func NewStaffProfileViewData(locale string, staff *model.StaffUser, events []*model.AuditEvent) StaffProfileViewData {
	items := make([]AuditEventView, 0, len(events))
	for _, event := range events {
		if event == nil {
			continue
		}
		items = append(items, newAuditEventView(locale, event))
	}
	timezone := model.DefaultStaffTimezone
	if staff != nil {
		timezone = staff.EffectiveTimezone()
	}
	return StaffProfileViewData{
		Staff:            staff,
		TimezoneOptions:  staffTimezoneOptions(timezone),
		CurrentLocalTime: formatTemplateTime(time.Now().UTC(), timezone),
		Items:            items,
	}
}

func NewAuditViewData(locale string, events []*model.AuditEvent) AuditViewData {
	items := make([]AuditEventView, 0, len(events))
	for _, event := range events {
		if event == nil {
			continue
		}
		items = append(items, newAuditEventView(locale, event))
	}
	return AuditViewData{Events: events, Items: items}
}

func NewGuideListViewData(items []model.GuideApplicationModerationItem) GuideListViewData {
	return GuideListViewData{
		Items:      items,
		QueueURL:   "/admin/moderation/guides",
		HistoryURL: "/admin/moderation/guides/history",
	}
}

func NewAttractionListViewData(items []model.AdminAttraction, total int, filters AttractionFilterViewData) AttractionListViewData {
	return AttractionListViewData{
		Items:      items,
		Total:      total,
		Filters:    filters,
		Pagination: attractionPagination(total, filters),
		Countries:  attractionCountryFilterOptions(filters.CountryCode),
		Cities:     attractionCityOptions(filters.CityID),
	}
}

func NewAttractionFormViewData(item *model.AdminAttraction, input model.AttractionInput) AttractionFormViewData {
	isEdit := item != nil && item.ID != uuid.Nil
	if isEdit && input.Title == "" {
		input = attractionInputFromItem(item)
	}
	submitURL := "/admin/attractions"
	mediaURL := ""
	if isEdit {
		submitURL = "/admin/attractions/" + item.ID.String()
		mediaURL = submitURL + "/media"
	}
	return AttractionFormViewData{
		Item:                 item,
		Input:                input,
		IsEdit:               isEdit,
		SubmitURL:            submitURL,
		MediaURL:             mediaURL,
		Categories:           attractionCategoryOptions(input.Category),
		Statuses:             attractionStatusOptions(input.Status),
		Locales:              attractionLocaleOptions(input.DefaultLocale),
		Countries:            attractionCountryOptions(input.CountryCode),
		Cities:               attractionCityOptions(input.CityID),
		Currencies:           attractionCurrencyOptions(input.PriceCurrency),
		AccessCityOptions:    attractionCityLinkOptions(input.AccessCities, input.CountryCode),
		DepartureCityOptions: attractionCityLinkOptions(input.DepartureCities, input.CountryCode),
	}
}

func NewDashboardViewData(
	excursions []*model.ModerationCase,
	activities []*model.ModerationCase,
	guideApplications []*model.ModerationCase,
	chatMessages []*model.ModerationCase,
) DashboardViewData {
	return DashboardViewData{
		Sections: []DashboardSectionView{
			newDashboardSection(model.ModerationTargetExcursion, excursions),
			newDashboardSection(model.ModerationTargetActivity, activities),
			newDashboardSection(model.ModerationTargetGuideApplication, guideApplications),
			newDashboardSection(model.ModerationTargetChatMessage, chatMessages),
		},
	}
}

func newDashboardSection(targetType model.ModerationTargetType, cases []*model.ModerationCase) DashboardSectionView {
	latest := latestDashboardCases(cases, 5)
	return DashboardSectionView{
		TitleKey:   dashboardSectionTitleKey(targetType),
		EmptyKey:   queueEmptyQueueKey(targetType),
		ViewAllURL: queueBaseURL(targetType),
		Items:      newQueueViewData(latest, targetType).Items,
	}
}

func latestDashboardCases(cases []*model.ModerationCase, limit int) []*model.ModerationCase {
	if limit <= 0 {
		return nil
	}
	latest := make([]*model.ModerationCase, 0, len(cases))
	for _, item := range cases {
		if item != nil {
			latest = append(latest, item)
		}
	}
	sort.SliceStable(latest, func(i, j int) bool {
		return latest[i].OpenedAt.After(latest[j].OpenedAt)
	})
	if len(latest) > limit {
		latest = latest[:limit]
	}
	return latest
}

func dashboardSectionTitleKey(targetType model.ModerationTargetType) string {
	switch targetType {
	case model.ModerationTargetActivity:
		return "dashboard.activityModeration"
	case model.ModerationTargetGuideApplication:
		return "dashboard.guideModeration"
	case model.ModerationTargetChatMessage:
		return "dashboard.chatModeration"
	default:
		return "dashboard.excursionModeration"
	}
}

func newAuditEventView(locale string, event *model.AuditEvent) AuditEventView {
	beforeStaff := auditStaffSnapshotFromJSON(event.BeforeJSON)
	afterStaff := auditStaffSnapshotFromJSON(event.AfterJSON)
	view := AuditEventView{
		Event:         event,
		ActionText:    auditActionText(locale, event.Action),
		ActorTitle:    auditActorTitle(locale, event),
		ActorSubtitle: auditActorSubtitle(event),
		EntityTitle:   auditEntityTitle(locale, event, beforeStaff, afterStaff),
		RequestText:   auditRequestText(locale, event.RequestID),
	}
	view.EntitySubtitle = auditEntitySubtitle(event, beforeStaff, afterStaff)
	view.Details = auditDetails(locale, event, beforeStaff, afterStaff)
	return view
}

type auditStaffSnapshot struct {
	Email       string           `json:"email"`
	DisplayName string           `json:"displayName"`
	Status      enum.StaffStatus `json:"status"`
	Timezone    string           `json:"timezone"`
	Roles       []enum.StaffRole `json:"roles"`
}

func auditStaffSnapshotFromJSON(raw []byte) auditStaffSnapshot {
	var snapshot auditStaffSnapshot
	if len(raw) == 0 {
		return snapshot
	}
	_ = json.Unmarshal(raw, &snapshot)
	return snapshot
}

func auditActionText(locale string, action string) string {
	key := "audit.action." + strings.TrimSpace(action)
	translated := translate(locale, key)
	if translated != key {
		return translated
	}
	return translate(locale, "audit.action.unknown")
}

func auditActorTitle(locale string, event *model.AuditEvent) string {
	if strings.TrimSpace(event.ActorDisplayName) != "" {
		return strings.TrimSpace(event.ActorDisplayName)
	}
	if strings.TrimSpace(event.ActorEmail) != "" {
		return strings.TrimSpace(event.ActorEmail)
	}
	if event.ActorStaffID == nil {
		return translate(locale, "label.system")
	}
	return translate(locale, "audit.actorUnknown")
}

func auditActorSubtitle(event *model.AuditEvent) string {
	if strings.TrimSpace(event.ActorEmail) != "" && strings.TrimSpace(event.ActorEmail) != strings.TrimSpace(event.ActorDisplayName) {
		return strings.TrimSpace(event.ActorEmail)
	}
	return ""
}

func auditEntityTitle(locale string, event *model.AuditEvent, before auditStaffSnapshot, after auditStaffSnapshot) string {
	switch event.EntityType {
	case "staff_user":
		name := firstNonEmpty(after.DisplayName, before.DisplayName, after.Email, before.Email)
		if name == "" {
			return translate(locale, "audit.entity.staffUser")
		}
		return fmt.Sprintf("%s: %s", translate(locale, "audit.entity.staffUser"), name)
	case "staff_session":
		return translate(locale, "audit.entity.staffSession")
	case "moderation_case":
		if target := auditModerationTargetText(locale, event); target != "" {
			return fmt.Sprintf("%s: %s", translate(locale, "audit.entity.moderationCase"), target)
		}
		return translate(locale, "audit.entity.moderationCase")
	case "guide_profile":
		return translate(locale, "audit.entity.guideProfile")
	case "attraction":
		if title := auditMetadataValue(event.Metadata, "title"); title != "" {
			return fmt.Sprintf("%s: %s", translate(locale, "audit.entity.attraction"), title)
		}
		return translate(locale, "audit.entity.attraction")
	default:
		return translate(locale, "audit.entity.unknown")
	}
}

func auditEntitySubtitle(event *model.AuditEvent, before auditStaffSnapshot, after auditStaffSnapshot) string {
	switch event.EntityType {
	case "staff_user":
		return firstNonEmpty(after.Email, before.Email)
	}
	return ""
}

func auditDetails(locale string, event *model.AuditEvent, before auditStaffSnapshot, after auditStaffSnapshot) []string {
	details := make([]string, 0, 3)
	switch event.Action {
	case "staff.updated":
		if strings.TrimSpace(before.DisplayName) != strings.TrimSpace(after.DisplayName) && firstNonEmpty(before.DisplayName, after.DisplayName) != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.displayNameChanged"), emptyDash(before.DisplayName), emptyDash(after.DisplayName)))
		}
		if !sameRoleList(before.Roles, after.Roles) {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.rolesChanged"), auditRoleList(locale, before.Roles), auditRoleList(locale, after.Roles)))
		}
	case "staff.status.changed":
		if before.Status != after.Status {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.statusChanged"), translateStatus(locale, before.Status), translateStatus(locale, after.Status)))
		}
		if reason := auditMetadataValue(event.Metadata, "reason"); reason != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.reason"), reason))
		}
	case "staff.timezone.updated":
		if strings.TrimSpace(before.Timezone) != strings.TrimSpace(after.Timezone) {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.timezoneChanged"), emptyDash(before.Timezone), emptyDash(after.Timezone)))
		}
	case "staff.password.regenerated":
		details = append(details, translate(locale, "audit.detail.passwordRegenerated"))
	case "staff.created", "staff.bootstrap_super_admin.created":
		details = append(details, fmt.Sprintf(translate(locale, "audit.detail.staffCreated"), firstNonEmpty(after.Email, before.Email)))
	case "moderation.decision.applied", "moderation.decision.apply_failed":
		if decision := auditMetadataValue(event.Metadata, "decision"); decision != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.moderationDecision"), translateStatus(locale, decision)))
		}
		if event.Action == "moderation.decision.apply_failed" {
			if value := auditMetadataValue(event.Metadata, "error"); value != "" {
				details = append(details, fmt.Sprintf(translate(locale, "audit.detail.error"), value))
			}
		}
	case "admin.login.failed":
		if value := auditMetadataValue(event.Metadata, "failedCount"); value != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.failedLoginCount"), value))
		}
	case "attraction.created", "attraction.updated", "attraction.media.replaced", "attraction.media.updated":
		if title := auditMetadataValue(event.Metadata, "title"); title != "" {
			details = append(details, fmt.Sprintf("%s: %s", translate(locale, "field.title"), title))
		}
		if category := auditMetadataValue(event.Metadata, "category"); category != "" {
			details = append(details, fmt.Sprintf("%s: %s", translate(locale, "field.category"), attractionCategoryText(locale, category)))
		}
	}
	if len(details) == 0 {
		details = append(details, translate(locale, "audit.detail.noExtraData"))
	}
	return details
}

func auditModerationTargetText(locale string, event *model.AuditEvent) string {
	targetType := model.ModerationTargetType(strings.ToUpper(strings.TrimSpace(auditMetadataValue(event.Metadata, "targetType"))))
	switch targetType {
	case model.ModerationTargetExcursion:
		return translate(locale, "moderation.excursion")
	case model.ModerationTargetActivity:
		return translate(locale, "moderation.activity")
	case model.ModerationTargetGuideApplication:
		return translate(locale, "moderation.guideApplication")
	case model.ModerationTargetChatMessage:
		return translate(locale, "moderation.chatMessage")
	case model.ModerationTargetStory:
		return translate(locale, "moderation.story")
	default:
		return ""
	}
}

func auditMetadataValue(raw []byte, key string) string {
	if len(raw) == 0 {
		return ""
	}
	var metadata map[string]any
	if err := json.Unmarshal(raw, &metadata); err != nil {
		return ""
	}
	value, ok := metadata[key]
	if !ok || value == nil {
		return ""
	}
	return strings.TrimSpace(fmt.Sprint(value))
}

var staffTimezoneValues = []string{
	"Asia/Almaty",
	"Asia/Aqtau",
	"Asia/Aqtobe",
	"Asia/Atyrau",
	"Asia/Oral",
	"Asia/Qyzylorda",
	"Asia/Bishkek",
	"Asia/Tashkent",
	"Asia/Dubai",
	"Asia/Istanbul",
	"Asia/Tokyo",
	"Europe/Moscow",
	"Europe/Berlin",
	"Europe/London",
	"America/New_York",
	"America/Los_Angeles",
	"UTC",
}

func staffTimezoneOptions(selected string) []TimezoneOptionView {
	selected = strings.TrimSpace(selected)
	if selected == "" {
		selected = model.DefaultStaffTimezone
	}
	values := append([]string(nil), staffTimezoneValues...)
	if !stringInSlice(values, selected) {
		values = append([]string{selected}, values...)
	}
	options := make([]TimezoneOptionView, 0, len(values))
	now := time.Now()
	for _, value := range values {
		options = append(options, TimezoneOptionView{
			Value:    value,
			Label:    timezoneOptionLabel(value, now),
			Selected: value == selected,
		})
	}
	return options
}

func timezoneOptionLabel(value string, now time.Time) string {
	location, err := time.LoadLocation(value)
	if err != nil {
		return value
	}
	_, offsetSeconds := now.In(location).Zone()
	sign := "+"
	if offsetSeconds < 0 {
		sign = "-"
		offsetSeconds = -offsetSeconds
	}
	hours := offsetSeconds / 3600
	minutes := (offsetSeconds % 3600) / 60
	return fmt.Sprintf("%s (UTC%s%02d:%02d)", value, sign, hours, minutes)
}

func stringInSlice(values []string, expected string) bool {
	for _, value := range values {
		if value == expected {
			return true
		}
	}
	return false
}

func auditRoleList(locale string, roles []enum.StaffRole) string {
	if len(roles) == 0 {
		return "-"
	}
	labels := make([]string, 0, len(roles))
	for _, role := range roles {
		labels = append(labels, translateRole(locale, role))
	}
	return strings.Join(labels, ", ")
}

func sameRoleList(left []enum.StaffRole, right []enum.StaffRole) bool {
	if len(left) != len(right) {
		return false
	}
	seen := make(map[enum.StaffRole]int, len(left))
	for _, role := range left {
		seen[role]++
	}
	for _, role := range right {
		if seen[role] == 0 {
			return false
		}
		seen[role]--
	}
	return true
}

func auditRequestText(locale string, requestID string) string {
	requestID = strings.TrimSpace(requestID)
	if requestID == "" {
		return ""
	}
	return fmt.Sprintf("%s %s", translate(locale, "audit.request"), shortTemplateID(requestID))
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return strings.TrimSpace(value)
		}
	}
	return ""
}

func emptyDash(value string) string {
	if strings.TrimSpace(value) == "" {
		return "-"
	}
	return strings.TrimSpace(value)
}

func assignableStaffRoles(actor *model.StaffUser) []enum.StaffRole {
	roles := []enum.StaffRole{
		enum.StaffRoleAdmin,
		enum.StaffRoleModerationLead,
		enum.StaffRoleExcursionModerator,
		enum.StaffRoleActivityModerator,
		enum.StaffRoleGuideModerator,
		enum.StaffRoleChatModerator,
		enum.StaffRoleReadOnlyAuditor,
		enum.StaffRoleSupportViewer,
	}
	if actor != nil && actor.HasRole(enum.StaffRoleSuperAdmin) {
		return append([]enum.StaffRole{enum.StaffRoleSuperAdmin}, roles...)
	}
	return roles
}

func editableStaffStatuses() []enum.StaffStatus {
	return []enum.StaffStatus{
		enum.StaffStatusActive,
		enum.StaffStatusPasswordResetRequired,
		enum.StaffStatusLocked,
		enum.StaffStatusDisabled,
	}
}

func NewQueueViewData(cases []*model.ModerationCase, filters ...QueueFilterViewData) QueueViewData {
	return newQueueViewData(cases, model.ModerationTargetExcursion, filters...)
}

func NewActivityQueueViewData(cases []*model.ModerationCase, filters ...QueueFilterViewData) QueueViewData {
	return newQueueViewData(cases, model.ModerationTargetActivity, filters...)
}

func NewGuideApplicationQueueViewData(cases []*model.ModerationCase, filters ...QueueFilterViewData) QueueViewData {
	return newQueueViewData(cases, model.ModerationTargetGuideApplication, filters...)
}

func NewChatMessageQueueViewData(cases []*model.ModerationCase, filters ...QueueFilterViewData) QueueViewData {
	return newQueueViewData(cases, model.ModerationTargetChatMessage, filters...)
}

func newQueueViewData(cases []*model.ModerationCase, targetType model.ModerationTargetType, filters ...QueueFilterViewData) QueueViewData {
	items := make([]ModerationQueueItemView, 0, len(cases))
	for _, item := range cases {
		if item == nil {
			continue
		}
		excursion := excursionFromSnapshot(item)
		activity := activityFromSnapshot(item)
		guideApplication := guideApplicationFromSnapshot(item)
		chatMessage := chatMessageFromSnapshot(item)
		view := ModerationQueueItemView{
			Case:             item,
			Excursion:        excursion,
			Activity:         activity,
			GuideApplication: guideApplication,
			ChatMessage:      chatMessage,
		}
		view.TargetTitle = queueTargetTitle(item, excursion, activity, guideApplication, chatMessage)
		view.TargetSubtitle = queueTargetSubtitle(excursion, activity, guideApplication, chatMessage)
		if excursion != nil {
			view.GuideName = excursionGuidePrimaryText(excursion)
			view.GuideFullName = excursionGuideFullNameText(excursion)
		} else if activity != nil {
			view.GuideName = activityHostPrimaryText(activity)
			view.GuideFullName = activityHostSecondaryText(activity)
		} else if guideApplication != nil {
			view.GuideName = guideApplicationPrimaryText(guideApplication)
			view.GuideFullName = guideApplicationFullNameText(guideApplication)
		} else if chatMessage != nil {
			view.GuideName = chatMessageSenderText(chatMessage)
			view.GuideFullName = chatMessageConversationText(defaultLocale, chatMessage)
		}
		if view.GuideName == "" {
			view.GuideName = "-"
		}
		view.DetailURL = queueDetailBaseURL(targetType) + "/" + item.ID.String()
		items = append(items, view)
	}
	viewFilters := QueueFilterViewData{Status: excursionQueueStatusActive}
	if len(filters) > 0 {
		viewFilters = filters[0]
	}
	data := QueueViewData{
		Items:                items,
		Filters:              viewFilters,
		FilterAction:         queueBaseURL(targetType),
		ResetURL:             queueBaseURL(targetType),
		OpenQueueURL:         queueBaseURL(targetType),
		HistoryURL:           queueBaseURL(targetType) + "/history",
		SyncAction:           queueBaseURL(targetType) + "/sync",
		DetailBaseURL:        queueBaseURL(targetType),
		TitleKey:             queueTitleKey(targetType),
		HistoryTitleKey:      queueHistoryTitleKey(targetType),
		EmptyQueueKey:        queueEmptyQueueKey(targetType),
		EmptyHistoryKey:      queueEmptyHistoryKey(targetType),
		TargetHeaderKey:      queueTargetHeaderKey(targetType),
		HostHeaderKey:        queueHostHeaderKey(targetType),
		LocationHeaderKey:    queueLocationHeaderKey(targetType),
		SearchPlaceholderKey: queueSearchPlaceholderKey(targetType),
	}
	if targetType == model.ModerationTargetGuideApplication {
		data.CurrentGuidesURL = "/admin/moderation/guides/current"
	}
	return data
}

func NewQueueHistoryViewData(cases []*model.ModerationCase, filters QueueFilterViewData) QueueViewData {
	data := NewQueueViewData(cases, filters)
	data.IsHistory = true
	data.FilterAction = data.HistoryURL
	data.ResetURL = data.HistoryURL
	return data
}

func NewActivityHistoryViewData(cases []*model.ModerationCase, filters QueueFilterViewData) QueueViewData {
	data := NewActivityQueueViewData(cases, filters)
	data.IsHistory = true
	data.FilterAction = data.HistoryURL
	data.ResetURL = data.HistoryURL
	return data
}

func NewGuideApplicationHistoryViewData(cases []*model.ModerationCase, filters QueueFilterViewData) QueueViewData {
	data := NewGuideApplicationQueueViewData(cases, filters)
	data.IsHistory = true
	data.FilterAction = data.HistoryURL
	data.ResetURL = data.HistoryURL
	return data
}

func NewChatMessageHistoryViewData(cases []*model.ModerationCase, filters QueueFilterViewData) QueueViewData {
	data := NewChatMessageQueueViewData(cases, filters)
	data.IsHistory = true
	data.FilterAction = data.HistoryURL
	data.ResetURL = data.HistoryURL
	return data
}

func excursionFromSnapshot(item *model.ModerationCase) *model.ExcursionModerationItem {
	if item == nil || item.TargetType != model.ModerationTargetExcursion || len(item.Snapshot) == 0 {
		return nil
	}
	var excursion model.ExcursionModerationItem
	if err := json.Unmarshal(item.Snapshot, &excursion); err != nil {
		return nil
	}
	if excursion.ID.String() == "00000000-0000-0000-0000-000000000000" {
		excursion.ID = item.TargetID
	}
	return &excursion
}

func activityFromSnapshot(item *model.ModerationCase) *model.ActivityModerationItem {
	if item == nil || item.TargetType != model.ModerationTargetActivity || len(item.Snapshot) == 0 {
		return nil
	}
	var activity model.ActivityModerationItem
	if err := json.Unmarshal(item.Snapshot, &activity); err != nil {
		return nil
	}
	if activity.ID.String() == "00000000-0000-0000-0000-000000000000" {
		activity.ID = item.TargetID
	}
	return &activity
}

func guideApplicationFromSnapshot(item *model.ModerationCase) *model.GuideApplicationModerationItem {
	if item == nil || item.TargetType != model.ModerationTargetGuideApplication || len(item.Snapshot) == 0 {
		return nil
	}
	var application model.GuideApplicationModerationItem
	if err := json.Unmarshal(item.Snapshot, &application); err != nil {
		return nil
	}
	if application.ID.String() == "00000000-0000-0000-0000-000000000000" {
		application.ID = item.TargetID
	}
	return &application
}

func chatMessageFromSnapshot(item *model.ModerationCase) *model.ChatMessageModerationItem {
	if item == nil || item.TargetType != model.ModerationTargetChatMessage || len(item.Snapshot) == 0 {
		return nil
	}
	var chatMessage model.ChatMessageModerationItem
	if err := json.Unmarshal(item.Snapshot, &chatMessage); err != nil {
		return nil
	}
	if chatMessage.ID.String() == "00000000-0000-0000-0000-000000000000" {
		chatMessage.ID = item.TargetID
	}
	return &chatMessage
}

func queueTargetTitle(item *model.ModerationCase, excursion *model.ExcursionModerationItem, activity *model.ActivityModerationItem, guideApplication *model.GuideApplicationModerationItem, chatMessage *model.ChatMessageModerationItem) string {
	if excursion != nil {
		if title := strings.TrimSpace(excursion.Title); title != "" {
			return title
		}
		if landmarks := excursionAttractionsText(defaultLocale, excursion); landmarks != "" {
			return landmarks
		}
	}
	if activity != nil {
		if title := strings.TrimSpace(activity.Title); title != "" {
			return title
		}
	}
	if guideApplication != nil {
		if title := strings.TrimSpace(guideApplication.Headline); title != "" {
			return title
		}
		if title := guideApplicationTypeText(defaultLocale, guideApplication); title != "" {
			return title
		}
	}
	if chatMessage != nil {
		return chatMessagePreviewText(defaultLocale, chatMessage)
	}
	if item == nil {
		return "-"
	}
	return string(item.TargetType) + " " + shortString(item.TargetID.String())
}

func queueTargetSubtitle(excursion *model.ExcursionModerationItem, activity *model.ActivityModerationItem, guideApplication *model.GuideApplicationModerationItem, chatMessage *model.ChatMessageModerationItem) string {
	if excursion == nil {
		if activity == nil {
			if guideApplication == nil {
				if chatMessage == nil {
					return ""
				}
				return chatMessageSignalsText(defaultLocale, chatMessage)
			}
			return guideApplicationTypeText(defaultLocale, guideApplication)
		}
		return activityLocationText(defaultLocale, activity)
	}
	return excursionAttractionsText(defaultLocale, excursion)
}

func activityHostPrimaryText(item *model.ActivityModerationItem) string {
	if item == nil {
		return "-"
	}
	if name := strings.TrimSpace(item.HostDisplayName); name != "" {
		return name
	}
	return "-"
}

func activityHostSecondaryText(item *model.ActivityModerationItem) string {
	return ""
}

func queueBaseURL(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetChatMessage {
		return "/admin/moderation/chats"
	}
	if targetType == model.ModerationTargetActivity {
		return "/admin/moderation/activities"
	}
	if targetType == model.ModerationTargetGuideApplication {
		return "/admin/moderation/guides"
	}
	return "/admin/moderation/excursions"
}

func queueDetailBaseURL(targetType model.ModerationTargetType) string {
	return queueBaseURL(targetType)
}

func queueTitleKey(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetChatMessage {
		return "moderation.chatQueue"
	}
	if targetType == model.ModerationTargetActivity {
		return "moderation.activityQueue"
	}
	if targetType == model.ModerationTargetGuideApplication {
		return "moderation.guideApplicationQueue"
	}
	return "moderation.excursionQueue"
}

func queueHistoryTitleKey(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetChatMessage {
		return "moderation.chatHistory"
	}
	if targetType == model.ModerationTargetActivity {
		return "moderation.activityHistory"
	}
	if targetType == model.ModerationTargetGuideApplication {
		return "moderation.guideApplicationHistory"
	}
	return "moderation.excursionHistory"
}

func queueEmptyQueueKey(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetChatMessage {
		return "moderation.noChatCases"
	}
	if targetType == model.ModerationTargetActivity {
		return "moderation.noActivityCases"
	}
	if targetType == model.ModerationTargetGuideApplication {
		return "moderation.noGuideApplicationCases"
	}
	return "moderation.noExcursionCases"
}

func queueEmptyHistoryKey(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetChatMessage {
		return "moderation.noChatHistory"
	}
	if targetType == model.ModerationTargetActivity {
		return "moderation.noActivityHistory"
	}
	if targetType == model.ModerationTargetGuideApplication {
		return "moderation.noGuideApplicationHistory"
	}
	return "moderation.noExcursionHistory"
}

func queueTargetHeaderKey(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetChatMessage {
		return "table.message"
	}
	if targetType == model.ModerationTargetActivity {
		return "table.activity"
	}
	if targetType == model.ModerationTargetGuideApplication {
		return "table.application"
	}
	return "table.excursion"
}

func queueHostHeaderKey(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetChatMessage {
		return "table.sender"
	}
	if targetType == model.ModerationTargetActivity {
		return "table.host"
	}
	if targetType == model.ModerationTargetGuideApplication {
		return "table.applicant"
	}
	return "table.guide"
}

func queueLocationHeaderKey(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetChatMessage {
		return "table.conversation"
	}
	return "table.city"
}

func queueSearchPlaceholderKey(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetChatMessage {
		return "placeholder.searchChats"
	}
	if targetType == model.ModerationTargetActivity {
		return "placeholder.searchActivities"
	}
	if targetType == model.ModerationTargetGuideApplication {
		return "placeholder.searchGuideApplications"
	}
	return "placeholder.searchExcursions"
}

func shortString(value string) string {
	if len(value) > 8 {
		return value[:8]
	}
	return value
}
