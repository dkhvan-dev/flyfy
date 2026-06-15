package enum

import "strings"

type CommunityScopeType string

const (
	CommunityScopeTypeCity   CommunityScopeType = "CITY"
	CommunityScopeTypeGlobal CommunityScopeType = "GLOBAL"
)

func (s CommunityScopeType) IsValid() bool {
	switch s {
	case CommunityScopeTypeCity, CommunityScopeTypeGlobal:
		return true
	default:
		return false
	}
}

func NormalizeCommunityScopeType(value CommunityScopeType) CommunityScopeType {
	normalized := CommunityScopeType(strings.ToUpper(strings.TrimSpace(string(value))))
	if normalized == "" {
		return CommunityScopeTypeCity
	}
	return normalized
}

type CommunityRolloutPolicy string

const (
	CommunityRolloutPolicyEligibleHubs CommunityRolloutPolicy = "ELIGIBLE_HUBS"
	CommunityRolloutPolicyPriorityHubs CommunityRolloutPolicy = "PRIORITY_HUBS"
	CommunityRolloutPolicyOnDemand     CommunityRolloutPolicy = "ON_DEMAND"
)

func (p CommunityRolloutPolicy) IsValid() bool {
	switch p {
	case CommunityRolloutPolicyEligibleHubs,
		CommunityRolloutPolicyPriorityHubs,
		CommunityRolloutPolicyOnDemand:
		return true
	default:
		return false
	}
}

type CommunityGeoHubTier string

const (
	CommunityGeoHubTierGlobal    CommunityGeoHubTier = "GLOBAL"
	CommunityGeoHubTierNational  CommunityGeoHubTier = "NATIONAL"
	CommunityGeoHubTierRegional  CommunityGeoHubTier = "REGIONAL"
	CommunityGeoHubTierTourist   CommunityGeoHubTier = "TOURIST"
	CommunityGeoHubTierAliasOnly CommunityGeoHubTier = "ALIAS_ONLY"
)

func (t CommunityGeoHubTier) IsValid() bool {
	switch t {
	case CommunityGeoHubTierGlobal,
		CommunityGeoHubTierNational,
		CommunityGeoHubTierRegional,
		CommunityGeoHubTierTourist,
		CommunityGeoHubTierAliasOnly:
		return true
	default:
		return false
	}
}

type PostKind string

const (
	PostKindArticle           PostKind = "ARTICLE"
	PostKindQuickPost         PostKind = "QUICK_POST"
	PostKindListing           PostKind = "LISTING"
	PostKindEventAnnouncement PostKind = "EVENT_ANNOUNCEMENT"
	PostKindQuestionAnswer    PostKind = "QUESTION_ANSWER"
	PostKindTripPlan          PostKind = "TRIP_PLAN"
)

func (k PostKind) IsValid() bool {
	switch k {
	case PostKindArticle,
		PostKindQuickPost,
		PostKindListing,
		PostKindEventAnnouncement,
		PostKindQuestionAnswer,
		PostKindTripPlan:
		return true
	default:
		return false
	}
}

type PostProfileKey string

const (
	PostProfileArticleV1           PostProfileKey = "article_v1"
	PostProfileQuickPostV1         PostProfileKey = "quick_post_v1"
	PostProfileListingV1           PostProfileKey = "listing_v1"
	PostProfileEventAnnouncementV1 PostProfileKey = "event_announcement_v1"
	PostProfileQuestionAnswerV1    PostProfileKey = "question_answer_v1"
	PostProfileTripPlanV1          PostProfileKey = "trip_plan_v1"
)

func (k PostProfileKey) IsValid() bool {
	switch k {
	case PostProfileArticleV1,
		PostProfileQuickPostV1,
		PostProfileListingV1,
		PostProfileEventAnnouncementV1,
		PostProfileQuestionAnswerV1,
		PostProfileTripPlanV1:
		return true
	default:
		return false
	}
}

func NormalizePostProfileKey(value PostProfileKey) PostProfileKey {
	normalized := PostProfileKey(strings.ToLower(strings.TrimSpace(string(value))))
	if normalized == "" {
		return PostProfileArticleV1
	}
	return normalized
}

type ModerationMode string

const (
	ModerationModePremoderation            ModerationMode = "PREMODERATION"
	ModerationModePublishFirst             ModerationMode = "PUBLISH_FIRST"
	ModerationModePublishFirstWithRiskHold ModerationMode = "PUBLISH_FIRST_WITH_RISK_HOLD"
	ModerationModeTrustedPublishElseReview ModerationMode = "TRUSTED_PUBLISH_ELSE_REVIEW"
)

func (m ModerationMode) IsValid() bool {
	switch m {
	case ModerationModePremoderation,
		ModerationModePublishFirst,
		ModerationModePublishFirstWithRiskHold,
		ModerationModeTrustedPublishElseReview:
		return true
	default:
		return false
	}
}

type ActivityCreationMode string

const (
	ActivityCreationModeDisabled ActivityCreationMode = "DISABLED"
	ActivityCreationModeOptional ActivityCreationMode = "OPTIONAL"
	ActivityCreationModeRequired ActivityCreationMode = "REQUIRED"
)

func (m ActivityCreationMode) IsValid() bool {
	switch m {
	case ActivityCreationModeDisabled, ActivityCreationModeOptional, ActivityCreationModeRequired:
		return true
	default:
		return false
	}
}

type ActivityCreationStatus string

const (
	ActivityCreationStatusPending ActivityCreationStatus = "PENDING"
	ActivityCreationStatusCreated ActivityCreationStatus = "CREATED"
	ActivityCreationStatusFailed  ActivityCreationStatus = "FAILED"
)

func (s ActivityCreationStatus) IsValid() bool {
	switch s {
	case ActivityCreationStatusPending, ActivityCreationStatusCreated, ActivityCreationStatusFailed:
		return true
	default:
		return false
	}
}
