package http

import (
	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type AdminNavigationPageViewData struct {
	Sections []AdminNavigationSectionView
}

type AdminNavigationSectionView struct {
	TitleKey string
	Items    []AdminNavigationItemView
}

type AdminNavigationItemView struct {
	Key      string
	LabelKey string
	URL      string
}

func NewAdminNavigationPageViewData(staff *model.StaffUser) AdminNavigationPageViewData {
	return AdminNavigationPageViewData{
		Sections: adminNavigationSections(staff),
	}
}

func adminNavigationSections(staff *model.StaffUser) []AdminNavigationSectionView {
	if staff == nil {
		return nil
	}
	sections := []AdminNavigationSectionView{
		{
			TitleKey: "navigation.section.core",
			Items: []AdminNavigationItemView{
				{Key: "dashboard", LabelKey: "nav.dashboard", URL: "/admin"},
				{Key: "communities", LabelKey: "nav.communities", URL: "/admin/communities"},
			},
		},
		{
			TitleKey: "navigation.section.moderation",
			Items: []AdminNavigationItemView{
				{Key: "moderation", LabelKey: "nav.excursions", URL: "/admin/moderation/excursions"},
				{Key: "activities", LabelKey: "nav.activities", URL: "/admin/moderation/activities"},
				{Key: "guides", LabelKey: "nav.guides", URL: "/admin/moderation/guides"},
				{Key: "chats", LabelKey: "nav.chats", URL: "/admin/moderation/chats"},
				{Key: "posts", LabelKey: "nav.posts", URL: "/admin/moderation/posts"},
				{Key: "user_routes", LabelKey: "nav.userRoutes", URL: "/admin/moderation/user-routes"},
			},
		},
	}
	management := []AdminNavigationItemView{}
	if staff.HasPermission(enum.PermissionModerationRead) {
		management = append(management, AdminNavigationItemView{Key: "feed_quality", LabelKey: "nav.feedQuality", URL: "/admin/feed-quality"})
	}
	if staff.HasPermission(enum.PermissionUsersRead) {
		management = append(management,
			AdminNavigationItemView{Key: "users", LabelKey: "nav.users", URL: "/admin/users"},
			AdminNavigationItemView{Key: "trust", LabelKey: "nav.trust", URL: "/admin/trust/appeals"},
		)
	}
	if staff.HasPermission(enum.PermissionPlaceManage) {
		management = append(management, AdminNavigationItemView{Key: "places", LabelKey: "nav.places", URL: "/admin/places"})
	}
	if len(management) > 0 {
		sections = append(sections, AdminNavigationSectionView{TitleKey: "navigation.section.management", Items: management})
	}

	helpCenter := []AdminNavigationItemView{}
	if staffCanSupportRead(staff) {
		helpCenter = append(helpCenter, AdminNavigationItemView{Key: "support", LabelKey: "nav.support", URL: "/admin/support/tickets"})
	}
	if staffCanSupportReply(staff) {
		helpCenter = append(helpCenter, AdminNavigationItemView{Key: "support_saved_replies", LabelKey: "nav.supportSavedReplies", URL: "/admin/support/saved-replies"})
	}
	if staffCanSupportManage(staff) {
		helpCenter = append(helpCenter, AdminNavigationItemView{Key: "support_agents", LabelKey: "nav.supportAgents", URL: "/admin/support/agents"})
	}
	if staffCanSupportRead(staff) || staff.HasPermission(enum.PermissionHelpContentEdit) || staff.HasPermission(enum.PermissionHelpContentPublish) {
		helpCenter = append(helpCenter, AdminNavigationItemView{Key: "help_analytics", LabelKey: "nav.helpAnalytics", URL: "/admin/help/analytics"})
	}
	if staff.HasPermission(enum.PermissionHelpContentEdit) || staff.HasPermission(enum.PermissionHelpContentPublish) {
		helpCenter = append(helpCenter,
			AdminNavigationItemView{Key: "help_categories", LabelKey: "nav.helpCategories", URL: "/admin/help/categories"},
			AdminNavigationItemView{Key: "help_content", LabelKey: "nav.helpContent", URL: "/admin/help/articles"},
		)
	}
	if len(helpCenter) > 0 {
		sections = append(sections, AdminNavigationSectionView{TitleKey: "navigation.section.helpCenter", Items: helpCenter})
	}

	administration := []AdminNavigationItemView{{Key: "staff", LabelKey: "nav.staff", URL: "/admin/staff"}}
	if staff.HasRole(enum.StaffRoleSuperAdmin) {
		administration = append(administration, AdminNavigationItemView{Key: "operations", LabelKey: "nav.operations", URL: "/admin/operations"})
	}
	if staff.HasPermission(enum.PermissionAuditRead) {
		administration = append(administration, AdminNavigationItemView{Key: "audit", LabelKey: "nav.audit", URL: "/admin/audit"})
	}
	sections = append(sections, AdminNavigationSectionView{TitleKey: "navigation.section.administration", Items: administration})
	return sections
}
