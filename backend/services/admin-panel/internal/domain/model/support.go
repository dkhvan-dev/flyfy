package model

import "time"

type HelpArticleStatus string

const (
	HelpArticleStatusDraft     HelpArticleStatus = "draft"
	HelpArticleStatusReview    HelpArticleStatus = "review"
	HelpArticleStatusPublished HelpArticleStatus = "published"
	HelpArticleStatusArchived  HelpArticleStatus = "archived"
)

type HelpCategory struct {
	ID        string
	Slug      string
	Title     string
	Status    HelpArticleStatus
	SortOrder int
	CreatedAt time.Time
	UpdatedAt time.Time
}

type HelpCategoryFilter struct {
	Status HelpArticleStatus
	Locale string
	Limit  int
	Offset int
}

type HelpCategoryUpsertInput struct {
	CategoryID     string
	ActorStaffID   string
	Slug           string
	Status         HelpArticleStatus
	SortOrder      int
	IdempotencyKey string
	RequestID      string
}

type SupportSavedReply struct {
	ID           string
	Category     string
	Status       HelpArticleStatus
	Tags         []string
	Translations map[string]SupportSavedReplyTranslation
	SortOrder    int
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type SupportSavedReplyTranslation struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

type SupportSavedReplyFilter struct {
	Category string
	Status   HelpArticleStatus
	Limit    int
	Offset   int
}

type SupportSavedReplyUpsertInput struct {
	ReplyID        string
	ActorStaffID   string
	Category       string
	Status         HelpArticleStatus
	Tags           []string
	Translations   map[string]SupportSavedReplyTranslation
	SortOrder      int
	IdempotencyKey string
	RequestID      string
}

type HelpArticle struct {
	ID                string
	CategoryID        string
	Slug              string
	Status            HelpArticleStatus
	Version           int
	OwnerID           string
	ReviewerID        string
	Tags              []string
	Surfaces          []string
	Visibility        HelpArticleVisibility
	Translations      map[string]HelpArticleTranslation
	Actions           []HelpArticleAction
	RelatedArticleIDs []string
	PublishedAt       *time.Time
	LastReviewedAt    *time.Time
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type HelpArticleVisibility struct {
	UserStates      []string `json:"userStates"`
	PaymentStatuses []string `json:"paymentStatuses"`
}

type HelpArticleTranslation struct {
	Title       string `json:"title"`
	ShortAnswer string `json:"shortAnswer"`
	Body        string `json:"body"`
}

type HelpArticleAction struct {
	Type   string `json:"type"`
	Target string `json:"target"`
	Label  string `json:"label,omitempty"`
}

type HelpArticleEvent struct {
	ArticleID string
	ActorID   string
	ActorType string
	EventType string
	Payload   map[string]string
	CreatedAt time.Time
}

type HelpArticleDetail struct {
	Article HelpArticle
	Events  []HelpArticleEvent
}

type HelpArticleFilter struct {
	Status HelpArticleStatus
	Limit  int
	Offset int
}

type HelpArticleUpsertInput struct {
	ArticleID         string
	ActorStaffID      string
	Slug              string
	CategoryID        string
	Status            HelpArticleStatus
	Tags              []string
	Surfaces          []string
	Visibility        HelpArticleVisibility
	Translations      map[string]HelpArticleTranslation
	Actions           []HelpArticleAction
	RelatedArticleIDs []string
	IdempotencyKey    string
	RequestID         string
}

type HelpArticleActionInput struct {
	ArticleID      string
	ActorStaffID   string
	IdempotencyKey string
	RequestID      string
}

type HelpAnalyticsSummary struct {
	GeneratedAt time.Time
	Searches    HelpSearchAnalytics
	Feedback    HelpFeedbackAnalytics
	Tickets     SupportTicketAnalytics
}

type HelpSearchAnalytics struct {
	Total              int
	WithoutResults     int
	SuccessRate        float64
	TopNoResultQueries []HelpSearchQueryStat
	RepeatedQueries    []HelpSearchQueryStat
}

type HelpSearchQueryStat struct {
	Query string
	Count int
}

type HelpFeedbackAnalytics struct {
	Total                 int
	Helpful               int
	NotHelpful            int
	Escalations           int
	NotHelpfulRate        float64
	TopNotHelpfulArticles []HelpArticleFeedbackStat
}

type HelpArticleFeedbackStat struct {
	ArticleID   string
	Count       int
	Escalations int
}

type SupportTicketAnalytics struct {
	Total                       int
	Open                        int
	WaitingSupport              int
	Resolved                    int
	Closed                      int
	Urgent                      int
	AverageFirstResponseSeconds int64
	AverageResolutionSeconds    int64
	CSATResponses               int
	AverageCSAT                 float64
}

type SupportTicketStatus string

const (
	SupportTicketStatusNew            SupportTicketStatus = "new"
	SupportTicketStatusOpen           SupportTicketStatus = "open"
	SupportTicketStatusAssigned       SupportTicketStatus = "assigned"
	SupportTicketStatusWaitingUser    SupportTicketStatus = "waiting_user"
	SupportTicketStatusWaitingSupport SupportTicketStatus = "waiting_support"
	SupportTicketStatusResolved       SupportTicketStatus = "resolved"
	SupportTicketStatusClosed         SupportTicketStatus = "closed"
	SupportTicketStatusReopened       SupportTicketStatus = "reopened"
)

type SupportTicketPriority string

const (
	SupportTicketPriorityLow    SupportTicketPriority = "low"
	SupportTicketPriorityNormal SupportTicketPriority = "normal"
	SupportTicketPriorityHigh   SupportTicketPriority = "high"
	SupportTicketPriorityUrgent SupportTicketPriority = "urgent"
)

type SupportCustomerSegment string

const (
	SupportCustomerSegmentStandard SupportCustomerSegment = "standard"
	SupportCustomerSegmentGuide    SupportCustomerSegment = "guide"
	SupportCustomerSegmentCreator  SupportCustomerSegment = "creator"
	SupportCustomerSegmentVIP      SupportCustomerSegment = "vip"
	SupportCustomerSegmentPartner  SupportCustomerSegment = "partner"
)

type SupportAssignmentStatus string

const (
	SupportAssignmentStatusNeedsAssignment SupportAssignmentStatus = "needs_assignment"
	SupportAssignmentStatusAssigned        SupportAssignmentStatus = "assigned"
	SupportAssignmentStatusManual          SupportAssignmentStatus = "manual"
)

type SupportAgentStatus string

const (
	SupportAgentStatusActive  SupportAgentStatus = "active"
	SupportAgentStatusPaused  SupportAgentStatus = "paused"
	SupportAgentStatusOffline SupportAgentStatus = "offline"
	SupportAgentStatusOnLeave SupportAgentStatus = "on_leave"
)

type SupportAgentLevel string

const (
	SupportAgentLevelAgent  SupportAgentLevel = "agent"
	SupportAgentLevelSenior SupportAgentLevel = "senior"
	SupportAgentLevelLead   SupportAgentLevel = "lead"
)

type SupportAgentSkill string

const (
	SupportAgentSkillAccount    SupportAgentSkill = "account"
	SupportAgentSkillActivities SupportAgentSkill = "activities"
	SupportAgentSkillExcursions SupportAgentSkill = "excursions"
	SupportAgentSkillPlaces     SupportAgentSkill = "places"
	SupportAgentSkillPayments   SupportAgentSkill = "payments"
	SupportAgentSkillCurrency   SupportAgentSkill = "currency"
	SupportAgentSkillSafety     SupportAgentSkill = "safety"
	SupportAgentSkillTechnical  SupportAgentSkill = "technical"
)

type SupportTicketCategory string

const (
	SupportTicketCategoryAccount    SupportTicketCategory = "account"
	SupportTicketCategoryActivities SupportTicketCategory = "activities"
	SupportTicketCategoryExcursions SupportTicketCategory = "excursions"
	SupportTicketCategoryPlaces     SupportTicketCategory = "places"
	SupportTicketCategoryPayments   SupportTicketCategory = "payments"
	SupportTicketCategoryCurrency   SupportTicketCategory = "currency"
	SupportTicketCategoryTechnical  SupportTicketCategory = "technical"
)

type SupportTicket struct {
	ID                         string
	UserID                     string
	ConversationID             string
	Category                   SupportTicketCategory
	Status                     SupportTicketStatus
	Priority                   SupportTicketPriority
	PriorityReasonCodes        []string
	CustomerSegment            SupportCustomerSegment
	CustomerSegmentReasonCodes []string
	SegmentRefreshStatus       string
	UserNicknameSnapshot       string
	FollowersCountSnapshot     int
	GuideStatusSnapshot        string
	SubscriptionTierSnapshot   string
	Source                     string
	Locale                     string
	AssigneeID                 string
	AssignmentStatus           SupportAssignmentStatus
	AssignmentReason           string
	AssignmentReasonCodes      []string
	AssignedAt                 *time.Time
	Context                    map[string]string
	FirstResponseAt            *time.Time
	ResolvedAt                 *time.Time
	LastMessagePreview         string
	LastMessageAt              time.Time
	CreatedAt                  time.Time
	UpdatedAt                  time.Time
}

type SupportTicketEvent struct {
	TicketID  string
	ActorID   string
	ActorType string
	EventType string
	Payload   map[string]string
	CreatedAt time.Time
}

type SupportTicketDetail struct {
	Ticket SupportTicket
	Events []SupportTicketEvent
}

type SupportTicketFilter struct {
	Status      SupportTicketStatus
	Category    SupportTicketCategory
	Priority    SupportTicketPriority
	AssigneeID  string
	SLABreached bool
	Limit       int
	Offset      int
}

type SupportTicketAssignInput struct {
	TicketID       string
	ActorStaffID   string
	AssigneeID     string
	Reason         string
	IdempotencyKey string
	RequestID      string
}

type SupportTicketReplyInput struct {
	TicketID         string
	ActorStaffID     string
	ActorDisplayName string
	Message          string
	ConversationID   string
	MessageID        string
	FileIDs          []string
	IdempotencyKey   string
	RequestID        string
}

type SupportTicketNoteInput struct {
	TicketID       string
	ActorStaffID   string
	Note           string
	IdempotencyKey string
	RequestID      string
}

type SupportTicketResolveInput struct {
	TicketID       string
	ActorStaffID   string
	Resolution     string
	IdempotencyKey string
	RequestID      string
}

type SupportTicketReopenInput struct {
	TicketID       string
	ActorStaffID   string
	Reason         string
	IdempotencyKey string
	RequestID      string
}

type SupportAgent struct {
	StaffID       string
	DisplayName   string
	FirstName     string
	LastName      string
	MiddleName    string
	Email         string
	Status        SupportAgentStatus
	Languages     []string
	Skills        []SupportAgentSkill
	Level         SupportAgentLevel
	MaxActiveLoad float64
	Timezone      string
	UpdatedAt     time.Time
}

type SupportAgentFilter struct {
	Status SupportAgentStatus
	Limit  int
	Offset int
}

type SupportAgentUpsertInput struct {
	ActorStaffID   string
	StaffID        string
	DisplayName    string
	FirstName      string
	LastName       string
	MiddleName     string
	Status         SupportAgentStatus
	Languages      []string
	Skills         []SupportAgentSkill
	Level          SupportAgentLevel
	MaxActiveLoad  float64
	Timezone       string
	IdempotencyKey string
	RequestID      string
}

type SupportUserSegment struct {
	UserID           string
	Nickname         string
	CustomerSegment  SupportCustomerSegment
	FollowersCount   int
	IsGuide          bool
	GuideStatus      string
	IsPublicFigure   bool
	IsPartner        bool
	ManualSegment    SupportCustomerSegment
	ManualReason     string
	SubscriptionTier string
	ReasonCodes      []string
	RefreshStatus    string
	UpdatedAt        time.Time
	SourceVersion    string
}

type SupportUserSegmentUpsertInput struct {
	ActorStaffID     string
	UserID           string
	Nickname         string
	FollowersCount   int
	IsGuide          bool
	GuideStatus      string
	IsPublicFigure   bool
	IsPartner        bool
	ManualSegment    SupportCustomerSegment
	ManualReason     string
	SubscriptionTier string
	SourceVersion    string
	IdempotencyKey   string
	RequestID        string
}
