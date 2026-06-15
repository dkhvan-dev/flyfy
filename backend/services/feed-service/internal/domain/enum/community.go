package enum

import "strings"

type CommunityVisibility string

const (
	CommunityVisibilityPublic     CommunityVisibility = "PUBLIC"
	CommunityVisibilityHidden     CommunityVisibility = "HIDDEN"
	CommunityVisibilityInviteOnly CommunityVisibility = "INVITE_ONLY"
)

func (v CommunityVisibility) IsValid() bool {
	switch v {
	case CommunityVisibilityPublic, CommunityVisibilityHidden, CommunityVisibilityInviteOnly:
		return true
	default:
		return false
	}
}

func NormalizeCommunityVisibility(v CommunityVisibility) CommunityVisibility {
	normalized := CommunityVisibility(strings.ToUpper(strings.TrimSpace(string(v))))
	if normalized == "" {
		return CommunityVisibilityPublic
	}
	return normalized
}

type CommunityPostingPolicy string

const (
	CommunityPostingPolicyAdminsOnly             CommunityPostingPolicy = "ADMINS_ONLY"
	CommunityPostingPolicyMembersAfterModeration CommunityPostingPolicy = "MEMBERS_AFTER_MODERATION"
	CommunityPostingPolicyTrustedMembers         CommunityPostingPolicy = "TRUSTED_MEMBERS"
	CommunityPostingPolicyOpenMembers            CommunityPostingPolicy = "OPEN_MEMBERS"
)

func (p CommunityPostingPolicy) IsValid() bool {
	switch p {
	case CommunityPostingPolicyAdminsOnly,
		CommunityPostingPolicyMembersAfterModeration,
		CommunityPostingPolicyTrustedMembers,
		CommunityPostingPolicyOpenMembers:
		return true
	default:
		return false
	}
}

func NormalizeCommunityPostingPolicy(p CommunityPostingPolicy) CommunityPostingPolicy {
	normalized := CommunityPostingPolicy(strings.ToUpper(strings.TrimSpace(string(p))))
	if normalized == "" {
		return CommunityPostingPolicyMembersAfterModeration
	}
	return normalized
}

type CommunityStatus string

const (
	CommunityStatusActive   CommunityStatus = "ACTIVE"
	CommunityStatusArchived CommunityStatus = "ARCHIVED"
	CommunityStatusHidden   CommunityStatus = "HIDDEN"
)

func (s CommunityStatus) IsValid() bool {
	switch s {
	case CommunityStatusActive, CommunityStatusArchived, CommunityStatusHidden:
		return true
	default:
		return false
	}
}

func NormalizeCommunityStatus(s CommunityStatus) CommunityStatus {
	normalized := CommunityStatus(strings.ToUpper(strings.TrimSpace(string(s))))
	if normalized == "" {
		return CommunityStatusActive
	}
	return normalized
}

type CommunityMembershipRole string

const (
	CommunityMembershipRoleMember        CommunityMembershipRole = "MEMBER"
	CommunityMembershipRoleTrustedMember CommunityMembershipRole = "TRUSTED_MEMBER"
	CommunityMembershipRoleModerator     CommunityMembershipRole = "MODERATOR"
	CommunityMembershipRoleAdmin         CommunityMembershipRole = "ADMIN"
)

func (r CommunityMembershipRole) IsValid() bool {
	switch r {
	case CommunityMembershipRoleMember,
		CommunityMembershipRoleTrustedMember,
		CommunityMembershipRoleModerator,
		CommunityMembershipRoleAdmin:
		return true
	default:
		return false
	}
}

type CommunityMembershipStatus string

const (
	CommunityMembershipStatusActive CommunityMembershipStatus = "ACTIVE"
	CommunityMembershipStatusMuted  CommunityMembershipStatus = "MUTED"
	CommunityMembershipStatusBanned CommunityMembershipStatus = "BANNED"
	CommunityMembershipStatusLeft   CommunityMembershipStatus = "LEFT"
)

func (s CommunityMembershipStatus) IsValid() bool {
	switch s {
	case CommunityMembershipStatusActive,
		CommunityMembershipStatusMuted,
		CommunityMembershipStatusBanned,
		CommunityMembershipStatusLeft:
		return true
	default:
		return false
	}
}
