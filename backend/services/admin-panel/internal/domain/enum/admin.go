package enum

type StaffStatus string

const (
	StaffStatusActive                StaffStatus = "ACTIVE"
	StaffStatusPasswordResetRequired StaffStatus = "PASSWORD_RESET_REQUIRED"
	StaffStatusLocked                StaffStatus = "LOCKED"
	StaffStatusDisabled              StaffStatus = "DISABLED"
)

func (s StaffStatus) IsValid() bool {
	switch s {
	case StaffStatusActive,
		StaffStatusPasswordResetRequired,
		StaffStatusLocked,
		StaffStatusDisabled:
		return true
	default:
		return false
	}
}

type StaffRole string

const (
	StaffRoleSuperAdmin           StaffRole = "SUPER_ADMIN"
	StaffRoleAdmin                StaffRole = "ADMIN"
	StaffRoleModerationLead       StaffRole = "MODERATION_LEAD"
	StaffRoleExcursionModerator   StaffRole = "EXCURSION_MODERATOR"
	StaffRoleActivityModerator    StaffRole = "ACTIVITY_MODERATOR"
	StaffRoleGuideModerator       StaffRole = "GUIDE_MODERATOR"
	StaffRoleChatModerator        StaffRole = "CHAT_MODERATOR"
	StaffRoleSupportViewer        StaffRole = "SUPPORT_VIEWER"
	StaffRoleSupportAgent         StaffRole = "SUPPORT_AGENT"
	StaffRoleSupportLead          StaffRole = "SUPPORT_LEAD"
	StaffRoleSupportAdmin         StaffRole = "SUPPORT_ADMIN"
	StaffRoleHelpContentEditor    StaffRole = "HELP_CONTENT_EDITOR"
	StaffRoleHelpContentPublisher StaffRole = "HELP_CONTENT_PUBLISHER"
	StaffRoleReadOnlyAuditor      StaffRole = "READ_ONLY_AUDITOR"
)

func (r StaffRole) IsValid() bool {
	switch r {
	case StaffRoleSuperAdmin,
		StaffRoleAdmin,
		StaffRoleModerationLead,
		StaffRoleExcursionModerator,
		StaffRoleActivityModerator,
		StaffRoleGuideModerator,
		StaffRoleChatModerator,
		StaffRoleSupportViewer,
		StaffRoleSupportAgent,
		StaffRoleSupportLead,
		StaffRoleSupportAdmin,
		StaffRoleHelpContentEditor,
		StaffRoleHelpContentPublisher,
		StaffRoleReadOnlyAuditor:
		return true
	default:
		return false
	}
}

type Permission string

const (
	PermissionDashboardRead      Permission = "dashboard.read"
	PermissionStaffManage        Permission = "staff.manage"
	PermissionAuditRead          Permission = "audit.read"
	PermissionModerationRead     Permission = "moderation.read"
	PermissionModerationAssign   Permission = "moderation.assign"
	PermissionExcursionModerate  Permission = "excursion.moderate"
	PermissionActivityModerate   Permission = "activity.moderate"
	PermissionGuideModerate      Permission = "guide.moderate"
	PermissionChatModerate       Permission = "chat.moderate"
	PermissionPlaceManage        Permission = "place.manage"
	PermissionFraudReview        Permission = "fraud.review"
	PermissionUsersRead          Permission = "users.read"
	PermissionUsersModerate      Permission = "users.moderate"
	PermissionUsersRestrict      Permission = "users.restrict"
	PermissionUsersSensitiveRead Permission = "users.sensitive.read"
	PermissionSupportRead        Permission = "support.read"
	PermissionSupportReply       Permission = "support.reply"
	PermissionSupportManage      Permission = "support.manage"
	PermissionHelpContentEdit    Permission = "help_content.edit"
	PermissionHelpContentPublish Permission = "help_content.publish"
)

type ModerationCaseStatus string

const (
	ModerationCaseStatusOpen             ModerationCaseStatus = "OPEN"
	ModerationCaseStatusInReview         ModerationCaseStatus = "IN_REVIEW"
	ModerationCaseStatusApproved         ModerationCaseStatus = "APPROVED"
	ModerationCaseStatusRejected         ModerationCaseStatus = "REJECTED"
	ModerationCaseStatusRevoked          ModerationCaseStatus = "REVOKED"
	ModerationCaseStatusChangesRequested ModerationCaseStatus = "CHANGES_REQUESTED"
	ModerationCaseStatusEscalated        ModerationCaseStatus = "ESCALATED"
	ModerationCaseStatusCancelled        ModerationCaseStatus = "CANCELLED"
)

type ModerationDecisionType string

const (
	ModerationDecisionApprove        ModerationDecisionType = "APPROVE"
	ModerationDecisionReject         ModerationDecisionType = "REJECT"
	ModerationDecisionRevoke         ModerationDecisionType = "REVOKE"
	ModerationDecisionRequestChanges ModerationDecisionType = "REQUEST_CHANGES"
	ModerationDecisionEscalate       ModerationDecisionType = "ESCALATE"
)

type ModerationApplyStatus string

const (
	ModerationApplyPending    ModerationApplyStatus = "PENDING"
	ModerationApplyApplied    ModerationApplyStatus = "APPLIED"
	ModerationApplyFailed     ModerationApplyStatus = "FAILED"
	ModerationApplySuperseded ModerationApplyStatus = "SUPERSEDED"
)
