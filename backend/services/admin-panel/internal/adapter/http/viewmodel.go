package http

import (
	"encoding/json"
	"fmt"
	"strings"

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

type QueueViewData struct {
	Items        []ModerationQueueItemView
	Filters      QueueFilterViewData
	IsHistory    bool
	FilterAction string
	ResetURL     string
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
	Case           *model.ModerationCase
	Excursion      *model.ExcursionModerationItem
	TargetTitle    string
	TargetSubtitle string
	GuideName      string
	GuideFullName  string
}

type CaseDetailViewData struct {
	Detail *app.ModerationCaseDetail
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
		return translate(locale, "audit.entity.moderationCase")
	default:
		return translate(locale, "audit.entity.unknown")
	}
}

func auditEntitySubtitle(event *model.AuditEvent, before auditStaffSnapshot, after auditStaffSnapshot) string {
	switch event.EntityType {
	case "staff_user":
		return firstNonEmpty(after.Email, before.Email)
	case "moderation_case":
		if event.EntityID != nil {
			return "ID " + shortTemplateID(event.EntityID)
		}
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
	}
	if len(details) == 0 {
		details = append(details, translate(locale, "audit.detail.noExtraData"))
	}
	return details
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
	items := make([]ModerationQueueItemView, 0, len(cases))
	for _, item := range cases {
		if item == nil {
			continue
		}
		excursion := excursionFromSnapshot(item)
		view := ModerationQueueItemView{
			Case:      item,
			Excursion: excursion,
		}
		view.TargetTitle = queueTargetTitle(item, excursion)
		view.TargetSubtitle = queueTargetSubtitle(excursion)
		if excursion != nil {
			view.GuideName = excursionGuidePrimaryText(excursion)
			view.GuideFullName = excursionGuideFullNameText(excursion)
		}
		if view.GuideName == "" {
			view.GuideName = "-"
		}
		items = append(items, view)
	}
	viewFilters := QueueFilterViewData{Status: excursionQueueStatusActive}
	if len(filters) > 0 {
		viewFilters = filters[0]
	}
	return QueueViewData{
		Items:        items,
		Filters:      viewFilters,
		FilterAction: "/admin/moderation/excursions",
		ResetURL:     "/admin/moderation/excursions",
	}
}

func NewQueueHistoryViewData(cases []*model.ModerationCase, filters QueueFilterViewData) QueueViewData {
	data := NewQueueViewData(cases, filters)
	data.IsHistory = true
	data.FilterAction = "/admin/moderation/excursions/history"
	data.ResetURL = "/admin/moderation/excursions/history"
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

func queueTargetTitle(item *model.ModerationCase, excursion *model.ExcursionModerationItem) string {
	if excursion != nil {
		if title := strings.TrimSpace(excursion.Title); title != "" {
			return title
		}
		if landmarks := excursionAttractionsText(defaultLocale, excursion); landmarks != "" {
			return landmarks
		}
	}
	if item == nil {
		return "-"
	}
	return string(item.TargetType) + " " + shortString(item.TargetID.String())
}

func queueTargetSubtitle(excursion *model.ExcursionModerationItem) string {
	if excursion == nil {
		return ""
	}
	return excursionAttractionsText(defaultLocale, excursion)
}

func shortString(value string) string {
	if len(value) > 8 {
		return value[:8]
	}
	return value
}
