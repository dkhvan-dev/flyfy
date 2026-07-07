package app

import (
	"context"
	"crypto/sha1"
	"encoding/hex"
	"errors"
	"log/slog"
	"sort"
	"strconv"
	"strings"
	"time"
)

const (
	defaultContextualLimit = 5
	defaultSearchLimit     = 10
	maxHelpResultLimit     = 20
	supportNotificationTTL = 24 * time.Hour
)

var (
	ErrArticleNotFound            = errors.New("help article not found")
	ErrInvalidUser                = errors.New("invalid user")
	ErrInvalidTicket              = errors.New("invalid support ticket")
	ErrInvalidFeedback            = errors.New("invalid article feedback")
	ErrInvalidHelpArticle         = errors.New("invalid help article")
	ErrInvalidSupportAdminAction  = errors.New("invalid support admin action")
	ErrSupportTicketNotFound      = errors.New("support ticket not found")
	ErrSupportTicketAlreadyExists = errors.New("support ticket already exists")
	ErrSupportUserSegmentNotFound = errors.New("support user segment not found")
	ErrSupportChatFailed          = errors.New("support chat delivery failed")
	ErrRepositoryFailed           = errors.New("support repository failed")
)

type ArticleStatus string

const (
	ArticleStatusDraft     ArticleStatus = "draft"
	ArticleStatusReview    ArticleStatus = "review"
	ArticleStatusPublished ArticleStatus = "published"
	ArticleStatusArchived  ArticleStatus = "archived"
)

type HelpSurface string

const (
	HelpSurfaceHelpCenter        HelpSurface = "help_center"
	HelpSurfacePlaces            HelpSurface = "places"
	HelpSurfaceActivityDetails   HelpSurface = "activity_details"
	HelpSurfaceExcursionDetails  HelpSurface = "excursion_details"
	HelpSurfacePlaceDetails      HelpSurface = "place_details"
	HelpSurfaceCurrencyConverter HelpSurface = "currency_converter"
)

type ArticleActionType string

const (
	ArticleActionOpenChat       ArticleActionType = "open_chat"
	ArticleActionContactSupport ArticleActionType = "contact_support"
	ArticleActionOpenRoute      ArticleActionType = "open_route"
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

type SupportSegmentRefreshStatus string

const (
	SupportSegmentRefreshStatusFresh SupportSegmentRefreshStatus = "fresh"
	SupportSegmentRefreshStatusStale SupportSegmentRefreshStatus = "stale"
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

type SupportAgentLevel string

const (
	SupportAgentLevelAgent  SupportAgentLevel = "agent"
	SupportAgentLevelSenior SupportAgentLevel = "senior"
	SupportAgentLevelLead   SupportAgentLevel = "lead"
)

type SupportActorType string

const (
	SupportActorTypeSystem SupportActorType = "system"
	SupportActorTypeUser   SupportActorType = "user"
	SupportActorTypeAgent  SupportActorType = "support_agent"
	SupportActorTypeAdmin  SupportActorType = "support_admin"
)

type HelpArticle struct {
	ID                string
	CategoryID        string
	Slug              string
	Status            ArticleStatus
	Version           int
	OwnerID           string
	ReviewerID        string
	Tags              []string
	Surfaces          []HelpSurface
	Visibility        ArticleVisibility
	Translations      map[string]ArticleTranslation
	Actions           []ArticleAction
	RelatedArticleIDs []string
	PublishedAt       *time.Time
	LastReviewedAt    *time.Time
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type HelpCategory struct {
	ID           string
	Slug         string
	Title        string
	Status       ArticleStatus
	SortOrder    int
	ArticleCount int
	Translations map[string]HelpCategoryTranslation
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type HelpCategoryTranslation struct {
	Title string
}

type SupportSavedReply struct {
	ID           string
	Category     string
	Status       ArticleStatus
	Tags         []string
	SortOrder    int
	Translations map[string]SupportSavedReplyTranslation
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type SupportSavedReplyTranslation struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

type ArticleVisibility struct {
	UserStates      []string `json:"userStates"`
	PaymentStatuses []string `json:"paymentStatuses"`
}

type ArticleTranslation struct {
	Title       string
	ShortAnswer string
	Body        string
}

type ArticleAction struct {
	Type   ArticleActionType `json:"type"`
	Target string            `json:"target"`
	Label  string            `json:"label,omitempty"`
}

type HelpArticleListItem struct {
	ID                string          `json:"id"`
	Slug              string          `json:"slug"`
	Title             string          `json:"title"`
	ShortAnswer       string          `json:"shortAnswer"`
	Body              string          `json:"body"`
	Actions           []ArticleAction `json:"actions"`
	RelatedArticleIDs []string        `json:"relatedArticleIds"`
	Tags              []string        `json:"tags"`
	UpdatedAt         time.Time       `json:"updatedAt"`
}

type HelpArticleFilter struct {
	Status ArticleStatus
	Limit  int
	Offset int
}

type SearchArticleFilter struct {
	Locale  string
	Query   string
	Surface HelpSurface
	Limit   int
}

type HelpCategoryFilter struct {
	Status ArticleStatus
	Locale string
	Limit  int
	Offset int
}

type SupportSavedReplyFilter struct {
	Category string
	Status   ArticleStatus
	Limit    int
	Offset   int
}

type HelpArticleEvent struct {
	ArticleID string
	ActorID   string
	ActorType SupportActorType
	EventType string
	Payload   map[string]string
	CreatedAt time.Time
}

type ArticleFeedback struct {
	ArticleID          string
	UserID             string
	Locale             string
	Helpful            bool
	Reason             string
	EscalatedToSupport bool
	CreatedAt          time.Time
}

type SupportTicketCSAT struct {
	TicketID  string
	UserID    string
	Rating    int
	Comment   string
	CreatedAt time.Time
}

type HelpSearchEvent struct {
	Query       string
	Locale      string
	Surface     HelpSurface
	ResultCount int
	CreatedAt   time.Time
}

type SupportTicket struct {
	ID                         string
	UserID                     string
	ConversationID             string
	IdempotencyKey             string
	Category                   SupportTicketCategory
	Status                     SupportTicketStatus
	Priority                   SupportTicketPriority
	PriorityReasonCodes        []string
	CustomerSegment            SupportCustomerSegment
	CustomerSegmentReasonCodes []string
	SegmentRefreshStatus       SupportSegmentRefreshStatus
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
	CreatedAt                  time.Time
	UpdatedAt                  time.Time
	LastMessageAt              time.Time
}

type SupportTicketEvent struct {
	TicketID  string
	ActorID   string
	ActorType SupportActorType
	EventType string
	Payload   map[string]string
	CreatedAt time.Time
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
	RefreshStatus    SupportSegmentRefreshStatus
	UpdatedAt        time.Time
	SourceVersion    string
}

type SupportAgent struct {
	StaffID       string
	DisplayName   string
	FirstName     string
	LastName      string
	MiddleName    string
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

type SupportTicketFilter struct {
	Status      SupportTicketStatus
	Category    SupportTicketCategory
	Priority    SupportTicketPriority
	AssigneeID  string
	UserID      string
	SLABreached bool
	Limit       int
	Offset      int
}

type SupportTicketDetail struct {
	Ticket SupportTicket
	Events []SupportTicketEvent
}

type ListSupportAgentsInput struct {
	Status SupportAgentStatus
	Limit  int
	Offset int
}

type UpsertSupportAgentInput struct {
	ActorID       string
	StaffID       string
	DisplayName   string
	FirstName     string
	LastName      string
	MiddleName    string
	Status        SupportAgentStatus
	Languages     []string
	Skills        []SupportAgentSkill
	Level         SupportAgentLevel
	MaxActiveLoad float64
	Timezone      string
}

type UpsertSupportUserSegmentInput struct {
	ActorID          string
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
}

type HelpAnalyticsFilter struct {
	Limit int
}

type RefreshStaleSupportTicketSegmentsInput struct {
	Limit int
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

type HelpRepository interface {
	ListArticles(ctx context.Context) ([]HelpArticle, error)
	SearchArticles(ctx context.Context, filter SearchArticleFilter) ([]HelpArticle, error)
	ListCategories(ctx context.Context, filter HelpCategoryFilter) ([]HelpCategory, error)
	UpsertCategory(ctx context.Context, category HelpCategory) error
	ListSavedReplies(ctx context.Context, filter SupportSavedReplyFilter) ([]SupportSavedReply, error)
	UpsertSavedReply(ctx context.Context, reply SupportSavedReply) error
	ListAdminArticles(ctx context.Context, filter HelpArticleFilter) ([]HelpArticle, error)
	GetArticle(ctx context.Context, articleID string) (HelpArticle, []HelpArticleEvent, error)
	UpsertArticle(ctx context.Context, article HelpArticle, event HelpArticleEvent) error
	SaveHelpSearchEvent(ctx context.Context, event HelpSearchEvent) error
	SaveArticleFeedback(ctx context.Context, feedback ArticleFeedback) error
	CreateSupportTicket(ctx context.Context, ticket SupportTicket) error
	FindSupportTicketByIdempotencyKey(ctx context.Context, userID string, idempotencyKey string) (SupportTicket, error)
	ListSupportTickets(ctx context.Context, filter SupportTicketFilter) ([]SupportTicket, error)
	GetSupportTicket(ctx context.Context, ticketID string) (SupportTicket, []SupportTicketEvent, error)
	UpdateSupportTicket(ctx context.Context, ticket SupportTicket, event SupportTicketEvent) error
	AppendSupportTicketEvent(ctx context.Context, event SupportTicketEvent) error
	SaveSupportTicketCSAT(ctx context.Context, csat SupportTicketCSAT, event SupportTicketEvent) error
	GetSupportUserSegment(ctx context.Context, userID string) (SupportUserSegment, error)
	UpsertSupportUserSegment(ctx context.Context, segment SupportUserSegment) error
	ListSupportAgents(ctx context.Context, filter SupportAgentFilter) ([]SupportAgent, error)
	UpsertSupportAgent(ctx context.Context, agent SupportAgent) error
	GetHelpAnalytics(ctx context.Context, filter HelpAnalyticsFilter) (HelpAnalyticsSummary, error)
}

type SupportChatGateway interface {
	EnsureSupportConversation(ctx context.Context, userID string) (SupportChatConversationResult, error)
	SendSupportMessage(ctx context.Context, input SupportChatMessageInput) (SupportChatMessageResult, error)
}

type SupportOperatorNotifier interface {
	NotifySupportOperators(ctx context.Context, input SupportOperatorNotificationInput) error
}

type SupportUserNotifier interface {
	NotifySupportUser(ctx context.Context, userID string, input SupportUserNotificationInput) error
}

type SupportUserSegmentResolver interface {
	ResolveSupportUserSegment(ctx context.Context, userID string) (SupportUserSegment, error)
}

type SupportOperatorNotificationInput struct {
	IdempotencyKey string
	Category       string
	Priority       string
	Title          string
	Body           string
	DeepLink       string
	Data           map[string]string
	CollapseKey    string
	TTL            time.Duration
}

type SupportUserNotificationInput struct {
	IdempotencyKey string
	Category       string
	Priority       string
	Title          string
	Body           string
	DeepLink       string
	Data           map[string]string
	CollapseKey    string
	TTL            time.Duration
}

type SupportChatConversationResult struct {
	ConversationID string
}

type SupportChatMessageInput struct {
	ConversationID   string
	ActorID          string
	ActorDisplayName string
	Message          string
	FileIDs          []string
	ClientMessageID  string
}

type SupportChatMessageResult struct {
	MessageID string
}

type HelpUseCase struct {
	repo             HelpRepository
	now              func() time.Time
	chat             SupportChatGateway
	operatorNotifier SupportOperatorNotifier
	userNotifier     SupportUserNotifier
	segmentResolver  SupportUserSegmentResolver
	searchIndexer    HelpSearchIndexer
}

func NewHelpUseCase(repo HelpRepository, now func() time.Time) *HelpUseCase {
	if now == nil {
		now = func() time.Time { return time.Now().UTC() }
	}
	return &HelpUseCase{repo: repo, now: now}
}

func (uc *HelpUseCase) SetSupportChatGateway(chat SupportChatGateway) {
	uc.chat = chat
}

func (uc *HelpUseCase) SetSupportOperatorNotifier(notifier SupportOperatorNotifier) {
	uc.operatorNotifier = notifier
}

func (uc *HelpUseCase) SetSupportUserNotifier(notifier SupportUserNotifier) {
	uc.userNotifier = notifier
}

func (uc *HelpUseCase) SetSupportUserSegmentResolver(resolver SupportUserSegmentResolver) {
	uc.segmentResolver = resolver
}

type ListContextualArticlesInput struct {
	Locale        string
	Surface       HelpSurface
	CategoryID    string
	Tags          []string
	UserState     string
	PaymentStatus string
	Limit         int
	Offset        int
}

type SearchArticlesInput struct {
	Locale  string
	Query   string
	Surface HelpSurface
	Limit   int
}

type HelpArticleListResult struct {
	Items      []HelpArticleListItem `json:"items"`
	Total      int                   `json:"total"`
	Limit      int                   `json:"limit"`
	Offset     int                   `json:"offset"`
	NextOffset int                   `json:"nextOffset,omitempty"`
	HasMore    bool                  `json:"hasMore"`
}

type ListHelpCategoriesInput struct {
	Locale  string
	Surface HelpSurface
	Limit   int
	Offset  int
}

type HelpCategoryListResult struct {
	Items []HelpCategory `json:"items"`
}

func (uc *HelpUseCase) ListContextualArticles(ctx context.Context, input ListContextualArticlesInput) (HelpArticleListResult, error) {
	articles, err := uc.repo.ListArticles(ctx)
	if err != nil {
		return HelpArticleListResult{}, ErrRepositoryFailed
	}

	matches := make([]rankedArticle, 0, len(articles))
	for _, article := range articles {
		translation, ok := localizedArticle(article, input.Locale)
		if !ok || article.Status != ArticleStatusPublished {
			continue
		}
		if input.Surface != "" && !containsSurface(article.Surfaces, input.Surface) {
			continue
		}
		if strings.TrimSpace(input.CategoryID) != "" && article.CategoryID != strings.TrimSpace(input.CategoryID) {
			continue
		}
		if !matchesVisibility(article.Visibility, input.UserState, input.PaymentStatus) {
			continue
		}
		tagScore := countTagMatches(article.Tags, input.Tags)
		if len(input.Tags) > 0 && tagScore == 0 {
			continue
		}
		matches = append(matches, rankedArticle{
			article:     article,
			translation: translation,
			score:       contextualArticleScore(article, input, tagScore),
		})
	}

	sortRankedArticles(matches)
	limit := normalizeLimit(input.Limit, defaultContextualLimit)
	offset := normalizeOffset(input.Offset)
	items := collectRankedArticlesPage(matches, limit, offset)
	nextOffset := offset + len(items)
	hasMore := nextOffset < len(matches)
	result := HelpArticleListResult{
		Items:   items,
		Total:   len(matches),
		Limit:   limit,
		Offset:  offset,
		HasMore: hasMore,
	}
	if hasMore {
		result.NextOffset = nextOffset
	}
	return result, nil
}

func (uc *HelpUseCase) SearchArticles(ctx context.Context, input SearchArticlesInput) (HelpArticleListResult, error) {
	query := normalizeSearchText(input.Query)
	if query == "" {
		return HelpArticleListResult{Items: []HelpArticleListItem{}, Limit: normalizeLimit(input.Limit, defaultSearchLimit)}, nil
	}

	limit := normalizeLimit(input.Limit, defaultSearchLimit)
	articles, err := uc.repo.SearchArticles(ctx, SearchArticleFilter{
		Locale:  normalizeLocale(input.Locale),
		Query:   query,
		Surface: normalizeHelpSurface(input.Surface),
		Limit:   limit,
	})
	if err != nil {
		return HelpArticleListResult{}, ErrRepositoryFailed
	}

	items := collectLocalizedArticles(articles, input.Locale, limit)
	uc.recordHelpSearchEvent(ctx, HelpSearchEvent{
		Query:       query,
		Locale:      normalizeLocale(input.Locale),
		Surface:     normalizeHelpSurface(input.Surface),
		ResultCount: len(items),
		CreatedAt:   uc.now().UTC(),
	})
	return HelpArticleListResult{Items: items, Total: len(items), Limit: limit}, nil
}

func (uc *HelpUseCase) ListHelpCategories(ctx context.Context, input ListHelpCategoriesInput) (HelpCategoryListResult, error) {
	categories, err := uc.repo.ListCategories(ctx, HelpCategoryFilter{
		Status: ArticleStatusPublished,
		Limit:  normalizeLimit(input.Limit, 100),
		Offset: normalizeOffset(input.Offset),
	})
	if err != nil {
		return HelpCategoryListResult{}, ErrRepositoryFailed
	}
	articles, err := uc.repo.ListArticles(ctx)
	if err != nil {
		return HelpCategoryListResult{}, ErrRepositoryFailed
	}

	counts := make(map[string]int)
	for _, article := range articles {
		if article.Status != ArticleStatusPublished || strings.TrimSpace(article.CategoryID) == "" {
			continue
		}
		if input.Surface != "" && !containsSurface(article.Surfaces, input.Surface) {
			continue
		}
		if _, ok := localizedArticle(article, input.Locale); !ok {
			continue
		}
		counts[article.CategoryID]++
	}

	items := make([]HelpCategory, 0, len(categories))
	for _, category := range categories {
		count := counts[category.ID]
		if count == 0 {
			continue
		}
		category.ArticleCount = count
		category.Title = localizedCategoryTitle(category, input.Locale)
		items = append(items, category)
	}
	return HelpCategoryListResult{Items: items}, nil
}

type ListAdminHelpArticlesInput struct {
	Status ArticleStatus
	Limit  int
	Offset int
}

type ListAdminHelpCategoriesInput struct {
	Status ArticleStatus
	Limit  int
	Offset int
}

func (uc *HelpUseCase) ListAdminHelpCategories(ctx context.Context, input HelpCategoryFilter) ([]HelpCategory, error) {
	categories, err := uc.repo.ListCategories(ctx, HelpCategoryFilter{
		Status: input.Status,
		Limit:  normalizeLimit(input.Limit, 50),
		Offset: normalizeOffset(input.Offset),
	})
	if err != nil {
		return nil, ErrRepositoryFailed
	}
	for i := range categories {
		categories[i].Title = localizedCategoryTitle(categories[i], input.Locale)
	}
	return categories, nil
}

func (uc *HelpUseCase) ListAdminHelpArticles(ctx context.Context, input ListAdminHelpArticlesInput) ([]HelpArticle, error) {
	articles, err := uc.repo.ListAdminArticles(ctx, HelpArticleFilter{
		Status: input.Status,
		Limit:  normalizeLimit(input.Limit, 50),
		Offset: normalizeOffset(input.Offset),
	})
	if err != nil {
		return nil, ErrRepositoryFailed
	}
	return articles, nil
}

func (uc *HelpUseCase) GetAdminHelpArticle(ctx context.Context, articleID string) (HelpArticle, []HelpArticleEvent, error) {
	articleID = strings.TrimSpace(articleID)
	if articleID == "" {
		return HelpArticle{}, nil, ErrInvalidHelpArticle
	}
	article, events, err := uc.repo.GetArticle(ctx, articleID)
	if err != nil {
		if errors.Is(err, ErrArticleNotFound) {
			return HelpArticle{}, nil, ErrArticleNotFound
		}
		return HelpArticle{}, nil, ErrRepositoryFailed
	}
	return article, events, nil
}

type UpsertHelpArticleInput struct {
	ActorID string
	Article HelpArticle
}

type UpsertHelpCategoryInput struct {
	CategoryID string
	Slug       string
	Status     ArticleStatus
	SortOrder  int
	ActorID    string
}

type UpsertSupportSavedReplyInput struct {
	ReplyID      string
	ActorID      string
	Category     string
	Status       ArticleStatus
	Tags         []string
	SortOrder    int
	Translations map[string]SupportSavedReplyTranslation
}

func (uc *HelpUseCase) UpsertAdminHelpCategory(ctx context.Context, input UpsertHelpCategoryInput) (HelpCategory, error) {
	actorID := strings.TrimSpace(input.ActorID)
	if actorID == "" {
		return HelpCategory{}, ErrInvalidSupportAdminAction
	}
	now := uc.now().UTC()
	category, err := normalizeHelpCategory(input, now)
	if err != nil {
		return HelpCategory{}, err
	}
	if err := uc.repo.UpsertCategory(ctx, category); err != nil {
		return HelpCategory{}, ErrRepositoryFailed
	}
	return category, nil
}

func (uc *HelpUseCase) ListSupportSavedReplies(ctx context.Context, input SupportSavedReplyFilter) ([]SupportSavedReply, error) {
	replies, err := uc.repo.ListSavedReplies(ctx, SupportSavedReplyFilter{
		Category: strings.TrimSpace(input.Category),
		Status:   input.Status,
		Limit:    normalizeLimit(input.Limit, 50),
		Offset:   normalizeOffset(input.Offset),
	})
	if err != nil {
		return nil, ErrRepositoryFailed
	}
	return replies, nil
}

func (uc *HelpUseCase) UpsertSupportSavedReply(ctx context.Context, input UpsertSupportSavedReplyInput) (SupportSavedReply, error) {
	if strings.TrimSpace(input.ActorID) == "" {
		return SupportSavedReply{}, ErrInvalidSupportAdminAction
	}
	reply, err := normalizeSupportSavedReply(input, uc.now().UTC())
	if err != nil {
		return SupportSavedReply{}, err
	}
	if err := uc.repo.UpsertSavedReply(ctx, reply); err != nil {
		return SupportSavedReply{}, ErrRepositoryFailed
	}
	return reply, nil
}

func (uc *HelpUseCase) UpsertHelpArticle(ctx context.Context, input UpsertHelpArticleInput) (HelpArticle, error) {
	actorID := strings.TrimSpace(input.ActorID)
	if actorID == "" {
		return HelpArticle{}, ErrInvalidSupportAdminAction
	}
	article, err := normalizeHelpArticleDraft(input.Article, actorID, uc.now().UTC())
	if err != nil {
		return HelpArticle{}, err
	}

	existing, _, err := uc.repo.GetArticle(ctx, article.ID)
	switch {
	case err == nil:
		article.CreatedAt = existing.CreatedAt
		if article.CreatedAt.IsZero() {
			article.CreatedAt = article.UpdatedAt
		}
		if strings.TrimSpace(existing.OwnerID) != "" {
			article.OwnerID = existing.OwnerID
		}
		article.Version = existing.Version + 1
		if article.Version <= 1 {
			article.Version = 2
		}
	case errors.Is(err, ErrArticleNotFound):
		article.Version = 1
		article.CreatedAt = article.UpdatedAt
	default:
		return HelpArticle{}, ErrRepositoryFailed
	}

	event := helpArticleEvent(article.ID, actorID, "article_upserted", map[string]string{
		"status": string(article.Status),
		"slug":   article.Slug,
	}, article.UpdatedAt)
	if err := uc.repo.UpsertArticle(ctx, article, event); err != nil {
		return HelpArticle{}, ErrRepositoryFailed
	}
	uc.syncHelpArticleSearchDocument(ctx, article)
	return article, nil
}

func (uc *HelpUseCase) SubmitHelpArticleForReview(ctx context.Context, articleID string, actorID string) (HelpArticle, error) {
	article, err := uc.helpArticleForTransition(ctx, articleID, actorID)
	if err != nil {
		return HelpArticle{}, err
	}
	if err := validatePublishableArticle(article, false); err != nil {
		return HelpArticle{}, err
	}
	now := uc.now().UTC()
	article.Status = ArticleStatusReview
	article.UpdatedAt = now
	event := helpArticleEvent(article.ID, actorID, "article_submitted_for_review", map[string]string{"status": string(article.Status)}, now)
	if err := uc.repo.UpsertArticle(ctx, article, event); err != nil {
		return HelpArticle{}, ErrRepositoryFailed
	}
	uc.syncHelpArticleSearchDocument(ctx, article)
	return article, nil
}

func (uc *HelpUseCase) PublishHelpArticle(ctx context.Context, articleID string, actorID string) (HelpArticle, error) {
	article, err := uc.helpArticleForTransition(ctx, articleID, actorID)
	if err != nil {
		return HelpArticle{}, err
	}
	if err := validatePublishableArticle(article, true); err != nil {
		return HelpArticle{}, err
	}
	now := uc.now().UTC()
	article.Status = ArticleStatusPublished
	article.ReviewerID = strings.TrimSpace(actorID)
	article.PublishedAt = &now
	article.LastReviewedAt = &now
	article.UpdatedAt = now
	event := helpArticleEvent(article.ID, actorID, "article_published", map[string]string{"status": string(article.Status)}, now)
	if err := uc.repo.UpsertArticle(ctx, article, event); err != nil {
		return HelpArticle{}, ErrRepositoryFailed
	}
	uc.syncHelpArticleSearchDocument(ctx, article)
	return article, nil
}

func (uc *HelpUseCase) ArchiveHelpArticle(ctx context.Context, articleID string, actorID string) (HelpArticle, error) {
	article, err := uc.helpArticleForTransition(ctx, articleID, actorID)
	if err != nil {
		return HelpArticle{}, err
	}
	now := uc.now().UTC()
	article.Status = ArticleStatusArchived
	article.UpdatedAt = now
	event := helpArticleEvent(article.ID, actorID, "article_archived", map[string]string{"status": string(article.Status)}, now)
	if err := uc.repo.UpsertArticle(ctx, article, event); err != nil {
		return HelpArticle{}, ErrRepositoryFailed
	}
	uc.syncHelpArticleSearchDocument(ctx, article)
	return article, nil
}

func (uc *HelpUseCase) helpArticleForTransition(ctx context.Context, articleID string, actorID string) (HelpArticle, error) {
	if strings.TrimSpace(articleID) == "" || strings.TrimSpace(actorID) == "" {
		return HelpArticle{}, ErrInvalidSupportAdminAction
	}
	article, _, err := uc.repo.GetArticle(ctx, strings.TrimSpace(articleID))
	if err != nil {
		if errors.Is(err, ErrArticleNotFound) {
			return HelpArticle{}, ErrArticleNotFound
		}
		return HelpArticle{}, ErrRepositoryFailed
	}
	return article, nil
}

type SubmitArticleFeedbackInput struct {
	ArticleID          string
	UserID             string
	Locale             string
	Helpful            bool
	Reason             string
	EscalatedToSupport bool
}

func (uc *HelpUseCase) SubmitArticleFeedback(ctx context.Context, input SubmitArticleFeedbackInput) error {
	if strings.TrimSpace(input.ArticleID) == "" || strings.TrimSpace(input.UserID) == "" {
		return ErrInvalidFeedback
	}
	return uc.repo.SaveArticleFeedback(ctx, ArticleFeedback{
		ArticleID:          strings.TrimSpace(input.ArticleID),
		UserID:             strings.TrimSpace(input.UserID),
		Locale:             normalizeLocale(input.Locale),
		Helpful:            input.Helpful,
		Reason:             strings.TrimSpace(input.Reason),
		EscalatedToSupport: input.EscalatedToSupport,
		CreatedAt:          uc.now().UTC(),
	})
}

type GetHelpAnalyticsInput struct {
	Limit int
}

func (uc *HelpUseCase) GetHelpAnalytics(ctx context.Context, input GetHelpAnalyticsInput) (HelpAnalyticsSummary, error) {
	summary, err := uc.repo.GetHelpAnalytics(ctx, HelpAnalyticsFilter{Limit: normalizeLimit(input.Limit, 10)})
	if err != nil {
		return HelpAnalyticsSummary{}, ErrRepositoryFailed
	}
	if summary.GeneratedAt.IsZero() {
		summary.GeneratedAt = uc.now().UTC()
	}
	return summary, nil
}

func (uc *HelpUseCase) recordHelpSearchEvent(ctx context.Context, event HelpSearchEvent) {
	event.Query = truncateEventValue(strings.TrimSpace(event.Query), 300)
	if event.Query == "" {
		return
	}
	if err := uc.repo.SaveHelpSearchEvent(ctx, event); err != nil {
		return
	}
}

type CreateSupportTicketInput struct {
	UserID         string
	Category       SupportTicketCategory
	Source         string
	Locale         string
	Context        map[string]string
	IdempotencyKey string
}

func (uc *HelpUseCase) CreateSupportTicket(ctx context.Context, input CreateSupportTicketInput) (SupportTicket, error) {
	userID := strings.TrimSpace(input.UserID)
	if userID == "" {
		return SupportTicket{}, ErrInvalidUser
	}
	idempotencyKey := normalizeIdempotencyKey(input.IdempotencyKey)
	if idempotencyKey != "" {
		existing, err := uc.repo.FindSupportTicketByIdempotencyKey(ctx, userID, idempotencyKey)
		switch {
		case err == nil:
			return existing, nil
		case errors.Is(err, ErrSupportTicketNotFound):
		default:
			return SupportTicket{}, ErrRepositoryFailed
		}
	}
	category := input.Category
	if category == "" {
		category = SupportTicketCategoryTechnical
	}
	now := uc.now().UTC()
	context := sanitizeSupportContext(input.Context)
	conversationID := strings.TrimSpace(context["conversation_id"])
	if conversationID == "" && uc.chat != nil {
		result, err := uc.chat.EnsureSupportConversation(ctx, userID)
		if err != nil {
			slog.Warn("support chat conversation unavailable; creating ticket without chat mirror", "error", err, "user_id", userID)
		} else if strings.TrimSpace(result.ConversationID) == "" {
			slog.Warn("support chat conversation returned empty id; creating ticket without chat mirror", "user_id", userID)
		} else {
			conversationID = strings.TrimSpace(result.ConversationID)
			context["conversation_id"] = conversationID
		}
	}
	segment := uc.resolveSupportUserSegment(ctx, userID, now)
	priorityDecision := applySupportSegmentPriorityDecision(
		inferSupportTicketPriorityDecision("", category, SupportTicketPriorityNormal),
		segment.CustomerSegment,
	)
	ticket := SupportTicket{
		ID:                         generateTicketID(userID, now),
		UserID:                     userID,
		ConversationID:             conversationID,
		IdempotencyKey:             idempotencyKey,
		Category:                   category,
		Status:                     SupportTicketStatusNew,
		Priority:                   priorityDecision.Priority,
		PriorityReasonCodes:        priorityDecision.ReasonCodes,
		CustomerSegment:            segment.CustomerSegment,
		CustomerSegmentReasonCodes: segment.ReasonCodes,
		SegmentRefreshStatus:       segment.RefreshStatus,
		UserNicknameSnapshot:       segment.Nickname,
		FollowersCountSnapshot:     segment.FollowersCount,
		GuideStatusSnapshot:        segment.GuideStatus,
		SubscriptionTierSnapshot:   segment.SubscriptionTier,
		Source:                     nonEmpty(input.Source, "unknown"),
		Locale:                     normalizeLocale(input.Locale),
		AssignmentStatus:           SupportAssignmentStatusNeedsAssignment,
		Context:                    context,
		CreatedAt:                  now,
		UpdatedAt:                  now,
		LastMessageAt:              now,
	}
	if err := uc.repo.CreateSupportTicket(ctx, ticket); err != nil {
		if errors.Is(err, ErrSupportTicketAlreadyExists) && idempotencyKey != "" {
			existing, findErr := uc.repo.FindSupportTicketByIdempotencyKey(ctx, userID, idempotencyKey)
			if findErr == nil {
				return existing, nil
			}
		}
		slog.Error("create support ticket failed", "error", err, "user_id", userID)
		return SupportTicket{}, ErrRepositoryFailed
	}
	uc.recordSupportTicketDecisionEvents(ctx, ticket, priorityDecision.ReasonCodes, segment.ReasonCodes)
	assignedTicket, assignmentEvent, assignmentChanged := uc.autoAssignSupportTicket(ctx, ticket, now)
	if assignmentChanged {
		if updated, err := uc.updateTicket(ctx, assignedTicket, assignmentEvent); err != nil {
			return SupportTicket{}, err
		} else {
			ticket = updated
		}
	}
	uc.notifySupportTicketCreated(ctx, ticket)
	return ticket, nil
}

type ListUserSupportTicketsInput struct {
	UserID string
	Status SupportTicketStatus
	Limit  int
	Offset int
}

func (uc *HelpUseCase) ListUserSupportTickets(ctx context.Context, input ListUserSupportTicketsInput) ([]SupportTicket, error) {
	userID := strings.TrimSpace(input.UserID)
	if userID == "" {
		return nil, ErrInvalidUser
	}
	tickets, err := uc.repo.ListSupportTickets(ctx, SupportTicketFilter{
		UserID: userID,
		Status: input.Status,
		Limit:  normalizeLimit(input.Limit, 50),
		Offset: normalizeOffset(input.Offset),
	})
	if err != nil {
		return nil, ErrRepositoryFailed
	}
	return tickets, nil
}

func (uc *HelpUseCase) GetUserSupportTicket(ctx context.Context, userID string, ticketID string) (SupportTicketDetail, error) {
	userID = strings.TrimSpace(userID)
	ticketID = strings.TrimSpace(ticketID)
	if userID == "" {
		return SupportTicketDetail{}, ErrInvalidUser
	}
	if ticketID == "" {
		return SupportTicketDetail{}, ErrInvalidTicket
	}
	ticket, events, err := uc.repo.GetSupportTicket(ctx, ticketID)
	if err != nil {
		if errors.Is(err, ErrSupportTicketNotFound) {
			return SupportTicketDetail{}, ErrSupportTicketNotFound
		}
		return SupportTicketDetail{}, ErrRepositoryFailed
	}
	if ticket.UserID != userID {
		return SupportTicketDetail{}, ErrSupportTicketNotFound
	}
	return SupportTicketDetail{Ticket: ticket, Events: events}, nil
}

type GetOrCreateUserSupportConversationInput struct {
	UserID string
	Locale string
}

func (uc *HelpUseCase) GetOrCreateUserSupportConversation(ctx context.Context, input GetOrCreateUserSupportConversationInput) (SupportTicketDetail, error) {
	userID := strings.TrimSpace(input.UserID)
	if userID == "" {
		return SupportTicketDetail{}, ErrInvalidUser
	}
	tickets, err := uc.ListUserSupportTickets(ctx, ListUserSupportTicketsInput{
		UserID: userID,
		Limit:  maxHelpResultLimit,
	})
	if err != nil {
		return SupportTicketDetail{}, err
	}
	if len(tickets) > 0 {
		latest := latestSupportConversationTicket(tickets)
		detail, err := uc.GetUserSupportTicket(ctx, userID, latest.ID)
		if err != nil {
			return SupportTicketDetail{}, err
		}
		detail.Events, err = uc.supportConversationEvents(ctx, tickets)
		if err != nil {
			return SupportTicketDetail{}, err
		}
		return detail, nil
	}
	ticket, err := uc.CreateSupportTicket(ctx, CreateSupportTicketInput{
		UserID:         userID,
		Category:       SupportTicketCategoryTechnical,
		Source:         "support_chat",
		Locale:         input.Locale,
		IdempotencyKey: "support-conversation:" + userID,
		Context: map[string]string{
			"source_route": "/help/support",
		},
	})
	if err != nil {
		return SupportTicketDetail{}, err
	}
	detail, err := uc.GetUserSupportTicket(ctx, userID, ticket.ID)
	if err != nil {
		return SupportTicketDetail{Ticket: ticket}, nil
	}
	return detail, nil
}

func (uc *HelpUseCase) supportConversationEvents(ctx context.Context, tickets []SupportTicket) ([]SupportTicketEvent, error) {
	events := make([]SupportTicketEvent, 0)
	for _, ticket := range tickets {
		if strings.TrimSpace(ticket.ID) == "" {
			continue
		}
		_, ticketEvents, err := uc.repo.GetSupportTicket(ctx, ticket.ID)
		if err != nil {
			if errors.Is(err, ErrSupportTicketNotFound) {
				continue
			}
			return nil, ErrRepositoryFailed
		}
		events = append(events, ticketEvents...)
	}
	sort.SliceStable(events, func(left int, right int) bool {
		leftAt := events[left].CreatedAt
		rightAt := events[right].CreatedAt
		if leftAt.Equal(rightAt) {
			if events[left].TicketID == events[right].TicketID {
				return events[left].EventType < events[right].EventType
			}
			return events[left].TicketID < events[right].TicketID
		}
		return leftAt.Before(rightAt)
	})
	return events, nil
}

func latestSupportConversationTicket(tickets []SupportTicket) SupportTicket {
	latest := tickets[0]
	for _, ticket := range tickets[1:] {
		if supportTicketActivityTime(ticket).After(supportTicketActivityTime(latest)) {
			latest = ticket
		}
	}
	return latest
}

func supportTicketActivityTime(ticket SupportTicket) time.Time {
	if !ticket.LastMessageAt.IsZero() {
		return ticket.LastMessageAt
	}
	if !ticket.UpdatedAt.IsZero() {
		return ticket.UpdatedAt
	}
	return ticket.CreatedAt
}

type CloseUserSupportTicketInput struct {
	UserID   string
	TicketID string
	Reason   string
}

func (uc *HelpUseCase) CloseUserSupportTicket(ctx context.Context, input CloseUserSupportTicketInput) (SupportTicket, error) {
	detail, err := uc.GetUserSupportTicket(ctx, input.UserID, input.TicketID)
	if err != nil {
		return SupportTicket{}, err
	}
	now := uc.now().UTC()
	ticket := detail.Ticket
	ticket.Status = SupportTicketStatusClosed
	ticket.UpdatedAt = now
	event := supportUserEvent(ticket.ID, strings.TrimSpace(input.UserID), "ticket_closed_by_user", map[string]string{
		"reason": truncateEventValue(strings.TrimSpace(input.Reason), 400),
	}, now)
	return uc.updateTicket(ctx, ticket, event)
}

type ReplyToUserSupportTicketInput struct {
	UserID         string
	TicketID       string
	Message        string
	ActorNickname  string
	FileIDs        []string
	MessageID      string
	IdempotencyKey string
}

func (uc *HelpUseCase) ReplyToUserSupportTicket(ctx context.Context, input ReplyToUserSupportTicketInput) (SupportTicket, error) {
	userID := strings.TrimSpace(input.UserID)
	message := strings.TrimSpace(input.Message)
	if userID == "" {
		return SupportTicket{}, ErrInvalidUser
	}
	if strings.TrimSpace(input.TicketID) == "" || message == "" {
		return SupportTicket{}, ErrInvalidTicket
	}
	detail, err := uc.GetUserSupportTicket(ctx, userID, input.TicketID)
	if err != nil {
		return SupportTicket{}, err
	}
	ticket := detail.Ticket
	clientMessageID := supportClientMessageID(ticket.ID, userID, input.IdempotencyKey)
	if supportReplyEventRecorded(detail.Events, "user_replied", clientMessageID) {
		return ticket, nil
	}
	now := uc.now().UTC()
	fileIDs := normalizeSupportFileIDs(input.FileIDs)
	chatMessageID := strings.TrimSpace(input.MessageID)
	if uc.chat != nil && strings.TrimSpace(ticket.ConversationID) != "" {
		result, err := uc.chat.SendSupportMessage(ctx, SupportChatMessageInput{
			ConversationID:  ticket.ConversationID,
			ActorID:         userID,
			Message:         message,
			FileIDs:         fileIDs,
			ClientMessageID: clientMessageID,
		})
		if err != nil {
			slog.Warn("support chat send failed; storing user reply in ticket events only", "error", err, "ticket_id", ticket.ID)
		} else if result.MessageID != "" {
			chatMessageID = strings.TrimSpace(result.MessageID)
		}
	} else if uc.chat != nil {
		slog.Warn("support chat conversation missing; storing user reply in ticket events only", "ticket_id", ticket.ID)
	}
	ticket.Status = SupportTicketStatusWaitingSupport
	priorityDecision := applySupportSegmentPriorityDecision(
		inferSupportTicketPriorityDecision(message, ticket.Category, ticket.Priority),
		ticket.CustomerSegment,
	)
	ticket.Priority = priorityDecision.Priority
	ticket.PriorityReasonCodes = mergeSupportReasonCodes(ticket.PriorityReasonCodes, priorityDecision.ReasonCodes)
	ticket.ResolvedAt = nil
	ticket.LastMessageAt = now
	ticket.UpdatedAt = now
	payload := map[string]string{"message_preview": truncateEventValue(message, 160)}
	if actorNickname := sanitizeSupportActorName(input.ActorNickname); actorNickname != "" {
		payload["actor_nickname"] = actorNickname
	}
	if ticket.ConversationID != "" {
		payload["conversation_id"] = ticket.ConversationID
	}
	if chatMessageID != "" {
		payload["message_id"] = chatMessageID
	}
	if clientMessageID != "" {
		payload["client_message_id"] = clientMessageID
	}
	if len(fileIDs) > 0 {
		payload["file_ids"] = strings.Join(fileIDs, ",")
		payload["attachment_count"] = strconv.Itoa(len(fileIDs))
	}
	event := supportUserEvent(ticket.ID, userID, "user_replied", payload, now)
	updated, err := uc.updateTicket(ctx, ticket, event)
	if err != nil {
		return SupportTicket{}, err
	}
	if strings.TrimSpace(updated.AssigneeID) == "" && updated.AssignmentStatus == SupportAssignmentStatusNeedsAssignment {
		assignedTicket, assignmentEvent, assignmentChanged := uc.autoAssignSupportTicket(ctx, updated, now)
		if assignmentChanged {
			return uc.updateTicket(ctx, assignedTicket, assignmentEvent)
		}
	}
	return updated, nil
}

type SubmitSupportTicketCSATInput struct {
	UserID   string
	TicketID string
	Rating   int
	Comment  string
}

func (uc *HelpUseCase) SubmitSupportTicketCSAT(ctx context.Context, input SubmitSupportTicketCSATInput) error {
	userID := strings.TrimSpace(input.UserID)
	ticketID := strings.TrimSpace(input.TicketID)
	if userID == "" {
		return ErrInvalidUser
	}
	if ticketID == "" {
		return ErrInvalidTicket
	}
	if input.Rating < 1 || input.Rating > 5 {
		return ErrInvalidFeedback
	}
	detail, err := uc.GetUserSupportTicket(ctx, userID, ticketID)
	if err != nil {
		return err
	}
	if detail.Ticket.Status != SupportTicketStatusResolved && detail.Ticket.Status != SupportTicketStatusClosed {
		return ErrInvalidFeedback
	}

	now := uc.now().UTC()
	comment := truncateEventValue(strings.TrimSpace(input.Comment), 1200)
	csat := SupportTicketCSAT{
		TicketID:  detail.Ticket.ID,
		UserID:    userID,
		Rating:    input.Rating,
		Comment:   comment,
		CreatedAt: now,
	}
	event := supportUserEvent(detail.Ticket.ID, userID, "ticket_csat_submitted", map[string]string{
		"rating": strconv.Itoa(input.Rating),
	}, now)
	if comment != "" {
		event.Payload["comment"] = comment
	}
	if err := uc.repo.SaveSupportTicketCSAT(ctx, csat, event); err != nil {
		return ErrRepositoryFailed
	}
	return nil
}

func (uc *HelpUseCase) ListSupportAgents(ctx context.Context, input ListSupportAgentsInput) ([]SupportAgent, error) {
	if uc == nil || uc.repo == nil {
		return nil, ErrRepositoryFailed
	}
	if input.Status != "" && !isValidSupportAgentStatus(input.Status) {
		return nil, ErrInvalidSupportAdminAction
	}
	agents, err := uc.repo.ListSupportAgents(ctx, SupportAgentFilter{
		Status: input.Status,
		Limit:  normalizeLimit(input.Limit, 100),
		Offset: normalizeOffset(input.Offset),
	})
	if err != nil {
		return nil, ErrRepositoryFailed
	}
	now := uc.now().UTC()
	for index := range agents {
		agents[index] = normalizeSupportAgent(agents[index], now)
	}
	return agents, nil
}

func (uc *HelpUseCase) UpsertSupportAgent(ctx context.Context, input UpsertSupportAgentInput) (SupportAgent, error) {
	if uc == nil || uc.repo == nil {
		return SupportAgent{}, ErrRepositoryFailed
	}
	if strings.TrimSpace(input.ActorID) == "" || strings.TrimSpace(input.StaffID) == "" {
		return SupportAgent{}, ErrInvalidSupportAdminAction
	}
	now := uc.now().UTC()
	agent := normalizeSupportAgent(SupportAgent{
		StaffID:       input.StaffID,
		DisplayName:   input.DisplayName,
		FirstName:     input.FirstName,
		LastName:      input.LastName,
		MiddleName:    input.MiddleName,
		Status:        input.Status,
		Languages:     input.Languages,
		Skills:        input.Skills,
		Level:         input.Level,
		MaxActiveLoad: input.MaxActiveLoad,
		Timezone:      strings.TrimSpace(input.Timezone),
		UpdatedAt:     now,
	}, now)
	if agent.FirstName == "" || agent.LastName == "" {
		return SupportAgent{}, ErrInvalidSupportAdminAction
	}
	if !isValidSupportAgentStatus(agent.Status) ||
		!isValidSupportAgentLevel(agent.Level) ||
		!supportAgentSkillsAreValid(agent.Skills) ||
		agent.MaxActiveLoad < 0 {
		return SupportAgent{}, ErrInvalidSupportAdminAction
	}
	if err := uc.repo.UpsertSupportAgent(ctx, agent); err != nil {
		return SupportAgent{}, ErrRepositoryFailed
	}
	return agent, nil
}

func (uc *HelpUseCase) GetSupportUserSegment(ctx context.Context, userID string) (SupportUserSegment, error) {
	if uc == nil || uc.repo == nil {
		return SupportUserSegment{}, ErrRepositoryFailed
	}
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return SupportUserSegment{}, ErrInvalidUser
	}
	now := uc.now().UTC()
	return uc.resolveSupportUserSegment(ctx, userID, now), nil
}

func (uc *HelpUseCase) UpsertSupportUserSegment(ctx context.Context, input UpsertSupportUserSegmentInput) (SupportUserSegment, error) {
	if uc == nil || uc.repo == nil {
		return SupportUserSegment{}, ErrRepositoryFailed
	}
	if strings.TrimSpace(input.ActorID) == "" || strings.TrimSpace(input.UserID) == "" {
		return SupportUserSegment{}, ErrInvalidSupportAdminAction
	}
	if input.FollowersCount < 0 || !isValidSupportCustomerSegmentOrEmpty(input.ManualSegment) {
		return SupportUserSegment{}, ErrInvalidSupportAdminAction
	}
	now := uc.now().UTC()
	segment := normalizeSupportUserSegment(SupportUserSegment{
		UserID:           input.UserID,
		Nickname:         input.Nickname,
		FollowersCount:   input.FollowersCount,
		IsGuide:          input.IsGuide,
		GuideStatus:      input.GuideStatus,
		IsPublicFigure:   input.IsPublicFigure,
		IsPartner:        input.IsPartner,
		ManualSegment:    input.ManualSegment,
		ManualReason:     input.ManualReason,
		SubscriptionTier: input.SubscriptionTier,
		RefreshStatus:    SupportSegmentRefreshStatusFresh,
		UpdatedAt:        now,
		SourceVersion:    strings.TrimSpace(input.SourceVersion),
	}, input.UserID, now)
	if err := uc.repo.UpsertSupportUserSegment(ctx, segment); err != nil {
		return SupportUserSegment{}, ErrRepositoryFailed
	}
	return segment, nil
}

func (uc *HelpUseCase) RefreshStaleSupportTicketSegments(ctx context.Context, input RefreshStaleSupportTicketSegmentsInput) (int, error) {
	if uc == nil || uc.repo == nil {
		return 0, ErrRepositoryFailed
	}
	tickets, err := uc.repo.ListSupportTickets(ctx, SupportTicketFilter{Limit: normalizeLimit(input.Limit, 50)})
	if err != nil {
		return 0, ErrRepositoryFailed
	}
	now := uc.now().UTC()
	updatedCount := 0
	for _, ticket := range tickets {
		if ticket.SegmentRefreshStatus != SupportSegmentRefreshStatusStale || supportTicketIsTerminal(ticket.Status) {
			continue
		}
		segment := uc.resolveSupportUserSegment(ctx, ticket.UserID, now)
		if segment.RefreshStatus == SupportSegmentRefreshStatusStale {
			continue
		}
		previousSegment := ticket.CustomerSegment
		priorityDecision := applySupportSegmentPriorityDecision(
			inferSupportTicketPriorityDecision("", ticket.Category, ticket.Priority),
			segment.CustomerSegment,
		)
		ticket.Priority = priorityDecision.Priority
		ticket.PriorityReasonCodes = priorityDecision.ReasonCodes
		ticket.CustomerSegment = segment.CustomerSegment
		ticket.CustomerSegmentReasonCodes = segment.ReasonCodes
		ticket.SegmentRefreshStatus = segment.RefreshStatus
		ticket.UserNicknameSnapshot = segment.Nickname
		ticket.FollowersCountSnapshot = segment.FollowersCount
		ticket.GuideStatusSnapshot = segment.GuideStatus
		ticket.SubscriptionTierSnapshot = segment.SubscriptionTier
		ticket.UpdatedAt = now
		event := supportSystemEvent(ticket.ID, "ticket_segment_calculated", map[string]string{
			"previous_customer_segment": string(previousSegment),
			"customer_segment":          string(ticket.CustomerSegment),
			"reason_codes":              strings.Join(ticket.CustomerSegmentReasonCodes, ","),
			"refresh_status":            string(ticket.SegmentRefreshStatus),
			"source_version":            segment.SourceVersion,
		}, now)
		updated, err := uc.updateTicket(ctx, ticket, event)
		if err != nil {
			return updatedCount, err
		}
		updatedCount++
		assignedTicket, assignmentEvent, assignmentChanged := uc.autoAssignSupportTicket(ctx, updated, now)
		if assignmentChanged {
			if _, err := uc.updateTicket(ctx, assignedTicket, assignmentEvent); err != nil {
				return updatedCount, err
			}
		}
	}
	return updatedCount, nil
}

func supportTicketIsTerminal(status SupportTicketStatus) bool {
	return status == SupportTicketStatusResolved || status == SupportTicketStatusClosed
}

type ListSupportTicketsInput struct {
	Status      SupportTicketStatus
	Category    SupportTicketCategory
	Priority    SupportTicketPriority
	AssigneeID  string
	SLABreached bool
	Limit       int
	Offset      int
}

func (uc *HelpUseCase) ListSupportTickets(ctx context.Context, input ListSupportTicketsInput) ([]SupportTicket, error) {
	tickets, err := uc.repo.ListSupportTickets(ctx, SupportTicketFilter{
		Status:      input.Status,
		Category:    input.Category,
		Priority:    input.Priority,
		AssigneeID:  strings.TrimSpace(input.AssigneeID),
		SLABreached: input.SLABreached,
		Limit:       normalizeLimit(input.Limit, 50),
		Offset:      normalizeOffset(input.Offset),
	})
	if err != nil {
		return nil, ErrRepositoryFailed
	}
	return tickets, nil
}

type NotifySLABreachedTicketsInput struct {
	Limit int
}

func (uc *HelpUseCase) NotifySLABreachedTickets(ctx context.Context, input NotifySLABreachedTicketsInput) (int, error) {
	if uc.operatorNotifier == nil {
		return 0, nil
	}
	tickets, err := uc.repo.ListSupportTickets(ctx, SupportTicketFilter{
		SLABreached: true,
		Limit:       normalizeLimit(input.Limit, maxHelpResultLimit),
	})
	if err != nil {
		return 0, ErrRepositoryFailed
	}
	now := uc.now().UTC()
	count := 0
	for _, ticket := range tickets {
		if !SupportTicketSLABreached(ticket, now) {
			continue
		}
		uc.notifySupportTicketSLABreached(ctx, ticket)
		count++
	}
	return count, nil
}

func SupportTicketSLABreached(ticket SupportTicket, now time.Time) bool {
	if ticket.ID == "" || ticket.CreatedAt.IsZero() {
		return false
	}
	if ticket.Status == SupportTicketStatusResolved || ticket.Status == SupportTicketStatusClosed {
		return false
	}
	if ticket.FirstResponseAt == nil {
		return now.After(ticket.CreatedAt.Add(supportTicketFirstResponseSLA(ticket.Priority)))
	}
	return now.After(ticket.CreatedAt.Add(supportTicketResolutionSLA(ticket.Priority)))
}

func supportTicketFirstResponseSLA(priority SupportTicketPriority) time.Duration {
	switch priority {
	case SupportTicketPriorityUrgent:
		return 10 * time.Minute
	case SupportTicketPriorityHigh:
		return 20 * time.Minute
	default:
		return 30 * time.Minute
	}
}

func supportTicketResolutionSLA(priority SupportTicketPriority) time.Duration {
	switch priority {
	case SupportTicketPriorityUrgent:
		return 4 * time.Hour
	case SupportTicketPriorityHigh:
		return 12 * time.Hour
	default:
		return 24 * time.Hour
	}
}

type supportPriorityDecision struct {
	Priority     SupportTicketPriority
	ReasonCodes  []string
	RoutingSkill SupportAgentSkill
}

func inferSupportTicketPriority(message string, category SupportTicketCategory, _ map[string]string, current SupportTicketPriority) SupportTicketPriority {
	return inferSupportTicketPriorityDecision(message, category, current).Priority
}

func inferSupportTicketPriorityDecision(message string, category SupportTicketCategory, current SupportTicketPriority) supportPriorityDecision {
	score := supportPriorityRank(current)
	reasons := make([]string, 0, 3)
	routingSkill := supportRoutingSkillForCategory(category)
	text := normalizeSearchText(message)
	if containsAnySupportPriorityTerm(text, []string{
		"payment", "paid", "charge", "charged", "refund", "card", "bank", "invoice",
		"оплат", "платеж", "платёж", "списал", "возврат", "карта", "банк", "чек",
		"төлем", "қайтар", "карта",
	}) {
		score = maxSupportPriorityRank(score, supportPriorityRank(SupportTicketPriorityHigh))
		reasons = appendUniqueString(reasons, "payment_keyword")
		routingSkill = SupportAgentSkillPayments
	}
	if containsAnySupportPriorityTerm(text, []string{
		"safety", "danger", "injury", "medical", "police", "fraud", "scam", "stolen",
		"опасн", "травм", "полици", "мошен", "украл", "безопас",
		"қауіп", "жарақат", "алаяқ",
	}) {
		score = maxSupportPriorityRank(score, supportPriorityRank(SupportTicketPriorityUrgent))
		reasons = appendUniqueString(reasons, "safety_keyword")
		routingSkill = SupportAgentSkillSafety
	}
	if category == SupportTicketCategoryPayments {
		score = maxSupportPriorityRank(score, supportPriorityRank(SupportTicketPriorityHigh))
		reasons = appendUniqueString(reasons, "payment_category")
		routingSkill = SupportAgentSkillPayments
	}
	return supportPriorityDecision{Priority: supportPriorityFromRank(score), ReasonCodes: reasons, RoutingSkill: routingSkill}
}

func applySupportSegmentPriorityDecision(decision supportPriorityDecision, segment SupportCustomerSegment) supportPriorityDecision {
	switch segment {
	case SupportCustomerSegmentGuide:
		decision.Priority = supportPriorityFromRank(maxSupportPriorityRank(supportPriorityRank(decision.Priority), supportPriorityRank(SupportTicketPriorityHigh)))
		decision.ReasonCodes = appendUniqueString(decision.ReasonCodes, "segment_guide")
	case SupportCustomerSegmentCreator:
		decision.Priority = supportPriorityFromRank(maxSupportPriorityRank(supportPriorityRank(decision.Priority), supportPriorityRank(SupportTicketPriorityHigh)))
		decision.ReasonCodes = appendUniqueString(decision.ReasonCodes, "segment_creator")
	case SupportCustomerSegmentVIP:
		decision.Priority = supportPriorityFromRank(maxSupportPriorityRank(supportPriorityRank(decision.Priority), supportPriorityRank(SupportTicketPriorityHigh)))
		decision.ReasonCodes = appendUniqueString(decision.ReasonCodes, "segment_vip")
	case SupportCustomerSegmentPartner:
		decision.Priority = supportPriorityFromRank(maxSupportPriorityRank(supportPriorityRank(decision.Priority), supportPriorityRank(SupportTicketPriorityHigh)))
		decision.ReasonCodes = appendUniqueString(decision.ReasonCodes, "segment_partner")
	}
	return decision
}

func supportRoutingSkillForCategory(category SupportTicketCategory) SupportAgentSkill {
	switch category {
	case SupportTicketCategoryPayments:
		return SupportAgentSkillPayments
	case SupportTicketCategoryActivities:
		return SupportAgentSkillActivities
	case SupportTicketCategoryExcursions:
		return SupportAgentSkillExcursions
	case SupportTicketCategoryPlaces:
		return SupportAgentSkillPlaces
	case SupportTicketCategoryCurrency:
		return SupportAgentSkillCurrency
	case SupportTicketCategoryAccount:
		return SupportAgentSkillAccount
	default:
		return SupportAgentSkillTechnical
	}
}

func supportContextValues(context map[string]string) []string {
	values := make([]string, 0, len(context))
	for _, value := range context {
		if strings.TrimSpace(value) != "" {
			values = append(values, value)
		}
	}
	return values
}

func firstSupportContextValue(context map[string]string, keys ...string) string {
	for _, key := range keys {
		if value := strings.TrimSpace(context[key]); value != "" {
			return value
		}
	}
	return ""
}

func parseSupportContextInt(context map[string]string, keys ...string) int {
	value := firstSupportContextValue(context, keys...)
	if value == "" {
		return 0
	}
	parsed, err := strconv.Atoi(strings.ReplaceAll(value, " ", ""))
	if err != nil {
		return 0
	}
	return parsed
}

func containsAnySupportPriorityTerm(text string, terms []string) bool {
	if strings.TrimSpace(text) == "" {
		return false
	}
	for _, term := range terms {
		if strings.Contains(text, strings.ToLower(term)) {
			return true
		}
	}
	return false
}

func supportPriorityRank(priority SupportTicketPriority) int {
	switch priority {
	case SupportTicketPriorityUrgent:
		return 3
	case SupportTicketPriorityHigh:
		return 2
	case SupportTicketPriorityLow:
		return 0
	default:
		return 1
	}
}

func supportPriorityFromRank(rank int) SupportTicketPriority {
	switch {
	case rank >= 3:
		return SupportTicketPriorityUrgent
	case rank == 2:
		return SupportTicketPriorityHigh
	case rank <= 0:
		return SupportTicketPriorityLow
	default:
		return SupportTicketPriorityNormal
	}
}

func maxSupportPriorityRank(left int, right int) int {
	if left > right {
		return left
	}
	return right
}

func (uc *HelpUseCase) resolveSupportUserSegment(ctx context.Context, userID string, now time.Time) SupportUserSegment {
	fallback := defaultSupportUserSegment(userID, now)
	if uc == nil {
		return fallback
	}
	var stored SupportUserSegment
	storedFound := false
	if uc.repo != nil {
		if trusted, err := uc.repo.GetSupportUserSegment(ctx, userID); err == nil {
			stored = normalizeSupportUserSegment(trusted, userID, now)
			storedFound = true
			fallback = stored
		} else if err != nil && !errors.Is(err, ErrSupportUserSegmentNotFound) {
			slog.Warn("support user segment read-model unavailable", "error", err, "user_id", userID)
		}
	}
	if uc.segmentResolver == nil {
		return fallback
	}
	resolved, err := uc.segmentResolver.ResolveSupportUserSegment(ctx, userID)
	if err != nil {
		slog.Warn("trusted support user segment resolver unavailable", "error", err, "user_id", userID)
		return fallback
	}
	segment := normalizeSupportUserSegment(resolved, userID, now)
	if storedFound {
		segment = mergeSupportUserSegmentOverrides(segment, stored, now)
	}
	if uc.repo != nil {
		if err := uc.repo.UpsertSupportUserSegment(ctx, segment); err != nil {
			slog.Warn("support user segment read-model refresh failed", "error", err, "user_id", userID)
		}
	}
	return segment
}

func defaultSupportUserSegment(userID string, now time.Time) SupportUserSegment {
	return SupportUserSegment{
		UserID:          strings.TrimSpace(userID),
		CustomerSegment: SupportCustomerSegmentStandard,
		ReasonCodes:     []string{"segment_unavailable"},
		RefreshStatus:   SupportSegmentRefreshStatusStale,
		UpdatedAt:       now,
	}
}

func normalizeSupportUserSegment(segment SupportUserSegment, userID string, now time.Time) SupportUserSegment {
	segment.UserID = nonEmpty(segment.UserID, strings.TrimSpace(userID))
	segment.Nickname = sanitizeSupportActorName(segment.Nickname)
	segment.GuideStatus = normalizeToken(segment.GuideStatus)
	segment.SubscriptionTier = normalizeToken(segment.SubscriptionTier)
	segment.ManualReason = truncateEventValue(strings.TrimSpace(segment.ManualReason), 300)
	if segment.FollowersCount < 0 {
		segment.FollowersCount = 0
	}
	segment.CustomerSegment = inferSupportCustomerSegment(segment)
	segment.ReasonCodes = supportCustomerSegmentReasonCodes(segment)
	if segment.RefreshStatus == "" {
		segment.RefreshStatus = SupportSegmentRefreshStatusFresh
	}
	if segment.UpdatedAt.IsZero() {
		segment.UpdatedAt = now
	}
	return segment
}

func mergeSupportUserSegmentOverrides(resolved SupportUserSegment, stored SupportUserSegment, now time.Time) SupportUserSegment {
	if resolved.Nickname == "" {
		resolved.Nickname = stored.Nickname
	}
	if resolved.FollowersCount == 0 && stored.FollowersCount > 0 {
		resolved.FollowersCount = stored.FollowersCount
	}
	if !resolved.IsGuide && stored.IsGuide {
		resolved.IsGuide = true
	}
	if resolved.GuideStatus == "" {
		resolved.GuideStatus = stored.GuideStatus
	}
	if stored.IsPublicFigure {
		resolved.IsPublicFigure = true
	}
	if stored.IsPartner {
		resolved.IsPartner = true
	}
	if stored.ManualSegment != "" {
		resolved.ManualSegment = stored.ManualSegment
		resolved.ManualReason = stored.ManualReason
	}
	if resolved.SubscriptionTier == "" {
		resolved.SubscriptionTier = stored.SubscriptionTier
	}
	if resolved.SourceVersion == "" {
		resolved.SourceVersion = stored.SourceVersion
	}
	return normalizeSupportUserSegment(resolved, resolved.UserID, now)
}

func inferSupportCustomerSegment(segment SupportUserSegment) SupportCustomerSegment {
	if segment.ManualSegment == SupportCustomerSegmentPartner ||
		segment.ManualSegment == SupportCustomerSegmentVIP ||
		segment.ManualSegment == SupportCustomerSegmentCreator ||
		segment.ManualSegment == SupportCustomerSegmentGuide {
		return segment.ManualSegment
	}
	if segment.IsPartner {
		return SupportCustomerSegmentPartner
	}
	if segment.IsPublicFigure || segment.FollowersCount >= 100000 {
		return SupportCustomerSegmentVIP
	}
	if supportSegmentHasVerifiedGuideStatus(segment) {
		return SupportCustomerSegmentGuide
	}
	if segment.FollowersCount >= 10000 {
		return SupportCustomerSegmentCreator
	}
	return SupportCustomerSegmentStandard
}

func supportCustomerSegmentReasonCodes(segment SupportUserSegment) []string {
	reasons := make([]string, 0, 4)
	if segment.ManualSegment != "" && segment.ManualSegment != SupportCustomerSegmentStandard {
		reasons = appendUniqueString(reasons, "manual_"+string(segment.ManualSegment))
	}
	if segment.IsPartner || segment.CustomerSegment == SupportCustomerSegmentPartner {
		reasons = appendUniqueString(reasons, "partner")
	}
	if segment.IsPublicFigure {
		reasons = appendUniqueString(reasons, "public_figure")
	}
	if segment.FollowersCount >= 100000 {
		reasons = appendUniqueString(reasons, "followers_100k")
	} else if segment.FollowersCount >= 10000 {
		reasons = appendUniqueString(reasons, "followers_10k")
	}
	if supportSegmentHasVerifiedGuideStatus(segment) {
		reasons = appendUniqueString(reasons, "verified_guide")
	}
	if len(reasons) == 0 {
		reasons = append(reasons, "standard")
	}
	return reasons
}

func supportSegmentHasVerifiedGuideStatus(segment SupportUserSegment) bool {
	status := normalizeToken(segment.GuideStatus)
	if status == "" {
		return segment.IsGuide
	}
	switch status {
	case "active", "verified", "approved":
		return true
	default:
		return false
	}
}

func (uc *HelpUseCase) recordSupportTicketDecisionEvents(ctx context.Context, ticket SupportTicket, priorityReasons []string, segmentReasons []string) {
	if uc == nil || uc.repo == nil || ticket.ID == "" {
		return
	}
	now := ticket.CreatedAt
	if now.IsZero() {
		now = uc.now().UTC()
	}
	_ = uc.repo.AppendSupportTicketEvent(ctx, supportSystemEvent(ticket.ID, "ticket_priority_calculated", map[string]string{
		"priority":     string(ticket.Priority),
		"reason_codes": strings.Join(priorityReasons, ","),
	}, now))
	_ = uc.repo.AppendSupportTicketEvent(ctx, supportSystemEvent(ticket.ID, "ticket_segment_calculated", map[string]string{
		"customer_segment": string(ticket.CustomerSegment),
		"reason_codes":     strings.Join(segmentReasons, ","),
		"refresh_status":   string(ticket.SegmentRefreshStatus),
	}, now))
}

func (uc *HelpUseCase) autoAssignSupportTicket(ctx context.Context, ticket SupportTicket, now time.Time) (SupportTicket, SupportTicketEvent, bool) {
	if strings.TrimSpace(ticket.AssigneeID) != "" || ticket.AssignmentStatus == SupportAssignmentStatusManual {
		return ticket, SupportTicketEvent{}, false
	}
	if uc == nil || uc.repo == nil {
		return ticket, SupportTicketEvent{}, false
	}
	agents, err := uc.repo.ListSupportAgents(ctx, SupportAgentFilter{Status: SupportAgentStatusActive, Limit: 200})
	if err != nil {
		slog.Warn("support agents unavailable for auto assignment", "error", err, "ticket_id", ticket.ID)
		return uc.markSupportTicketAssignmentFailed(ticket, now, "agent_catalog_unavailable"), supportSystemEvent(ticket.ID, "ticket_assignment_failed", map[string]string{"reason_codes": "agent_catalog_unavailable"}, now), true
	}
	openTickets, err := uc.repo.ListSupportTickets(ctx, SupportTicketFilter{Limit: 1000})
	if err != nil {
		slog.Warn("support ticket load unavailable for auto assignment", "error", err, "ticket_id", ticket.ID)
		openTickets = nil
	}
	decision := selectSupportAgentForTicket(ticket, agents, openTickets, now)
	if decision.agent.StaffID == "" {
		failed := uc.markSupportTicketAssignmentFailed(ticket, now, "no_available_agent")
		return failed, supportSystemEvent(ticket.ID, "ticket_assignment_failed", map[string]string{"reason_codes": strings.Join(failed.AssignmentReasonCodes, ",")}, now), true
	}
	ticket.AssigneeID = decision.agent.StaffID
	ticket.AssignmentStatus = SupportAssignmentStatusAssigned
	ticket.AssignmentReason = decision.reason
	ticket.AssignmentReasonCodes = decision.reasonCodes
	ticket.AssignedAt = &now
	ticket.Status = SupportTicketStatusAssigned
	ticket.UpdatedAt = now
	return ticket, supportSystemEvent(ticket.ID, "ticket_auto_assigned", map[string]string{
		"assignee_id":  decision.agent.StaffID,
		"reason":       decision.reason,
		"reason_codes": strings.Join(decision.reasonCodes, ","),
		"score":        strconv.FormatFloat(decision.score, 'f', 2, 64),
	}, now), true
}

func (uc *HelpUseCase) markSupportTicketAssignmentFailed(ticket SupportTicket, now time.Time, reason string) SupportTicket {
	ticket.AssignmentStatus = SupportAssignmentStatusNeedsAssignment
	ticket.AssignmentReason = reason
	ticket.AssignmentReasonCodes = []string{reason}
	ticket.UpdatedAt = now
	return ticket
}

type supportAssignmentCandidate struct {
	agent       SupportAgent
	score       float64
	reason      string
	reasonCodes []string
}

func selectSupportAgentForTicket(ticket SupportTicket, agents []SupportAgent, openTickets []SupportTicket, now time.Time) supportAssignmentCandidate {
	requiredSkill := supportTicketRequiredSkill(ticket)
	loadByAgent := supportAgentWeightedLoad(openTickets, now)
	candidates := make([]supportAssignmentCandidate, 0, len(agents))
	for _, agent := range agents {
		agent = normalizeSupportAgent(agent, now)
		if agent.StaffID == "" || agent.Status != SupportAgentStatusActive {
			continue
		}
		if !supportAgentMatchesLanguage(agent, ticket.Locale) {
			continue
		}
		if !supportAgentHasSkill(agent, requiredSkill) {
			continue
		}
		if agent.MaxActiveLoad > 0 && loadByAgent[agent.StaffID] >= agent.MaxActiveLoad {
			continue
		}
		if supportTicketNeedsSenior(ticket) && !supportAgentIsSenior(agent) {
			continue
		}
		load := loadByAgent[agent.StaffID]
		score := load
		if supportAgentIsSenior(agent) {
			score -= 0.1
		}
		reasons := []string{"skill_" + string(requiredSkill), "language_" + normalizeLocale(ticket.Locale)}
		if supportAgentIsSenior(agent) {
			reasons = append(reasons, "senior_or_lead")
		}
		candidates = append(candidates, supportAssignmentCandidate{
			agent:       agent,
			score:       score,
			reason:      "auto_assignment",
			reasonCodes: reasons,
		})
	}
	if len(candidates) == 0 {
		return supportAssignmentCandidate{}
	}
	sort.SliceStable(candidates, func(i, j int) bool {
		if candidates[i].score != candidates[j].score {
			return candidates[i].score < candidates[j].score
		}
		return candidates[i].agent.StaffID < candidates[j].agent.StaffID
	})
	return candidates[0]
}

func normalizeSupportAgent(agent SupportAgent, now time.Time) SupportAgent {
	agent.StaffID = strings.TrimSpace(agent.StaffID)
	agent.DisplayName = strings.TrimSpace(agent.DisplayName)
	agent.FirstName = strings.TrimSpace(agent.FirstName)
	agent.LastName = strings.TrimSpace(agent.LastName)
	agent.MiddleName = strings.TrimSpace(agent.MiddleName)
	if fullName := supportAgentFullName(agent); fullName != "" {
		agent.DisplayName = fullName
	}
	if agent.DisplayName == "" {
		agent.DisplayName = agent.StaffID
	}
	if agent.Status == "" {
		agent.Status = SupportAgentStatusActive
	}
	if agent.Level == "" {
		agent.Level = SupportAgentLevelAgent
	}
	agent.Languages = normalizeStringList(agent.Languages)
	normalizedSkills := make([]SupportAgentSkill, 0, len(agent.Skills))
	seen := map[SupportAgentSkill]struct{}{}
	for _, skill := range agent.Skills {
		skill = SupportAgentSkill(normalizeToken(string(skill)))
		if skill == "" {
			continue
		}
		if _, ok := seen[skill]; ok {
			continue
		}
		seen[skill] = struct{}{}
		normalizedSkills = append(normalizedSkills, skill)
	}
	agent.Skills = normalizedSkills
	if agent.UpdatedAt.IsZero() {
		agent.UpdatedAt = now
	}
	return agent
}

func supportAgentFullName(agent SupportAgent) string {
	parts := make([]string, 0, 3)
	if value := strings.TrimSpace(agent.LastName); value != "" {
		parts = append(parts, value)
	}
	if value := strings.TrimSpace(agent.FirstName); value != "" {
		parts = append(parts, value)
	}
	if value := strings.TrimSpace(agent.MiddleName); value != "" {
		parts = append(parts, value)
	}
	return strings.Join(parts, " ")
}

func isValidSupportAgentStatus(status SupportAgentStatus) bool {
	switch status {
	case SupportAgentStatusActive, SupportAgentStatusPaused, SupportAgentStatusOffline, SupportAgentStatusOnLeave:
		return true
	default:
		return false
	}
}

func isValidSupportAgentLevel(level SupportAgentLevel) bool {
	switch level {
	case SupportAgentLevelAgent, SupportAgentLevelSenior, SupportAgentLevelLead:
		return true
	default:
		return false
	}
}

func supportAgentSkillsAreValid(skills []SupportAgentSkill) bool {
	if len(skills) == 0 {
		return false
	}
	for _, skill := range skills {
		if !isValidSupportAgentSkill(skill) {
			return false
		}
	}
	return true
}

func isValidSupportAgentSkill(skill SupportAgentSkill) bool {
	switch skill {
	case SupportAgentSkillAccount,
		SupportAgentSkillActivities,
		SupportAgentSkillExcursions,
		SupportAgentSkillPlaces,
		SupportAgentSkillPayments,
		SupportAgentSkillCurrency,
		SupportAgentSkillSafety,
		SupportAgentSkillTechnical:
		return true
	default:
		return false
	}
}

func isValidSupportCustomerSegmentOrEmpty(segment SupportCustomerSegment) bool {
	switch segment {
	case "", SupportCustomerSegmentStandard, SupportCustomerSegmentGuide, SupportCustomerSegmentCreator, SupportCustomerSegmentVIP, SupportCustomerSegmentPartner:
		return true
	default:
		return false
	}
}

func supportTicketRequiredSkill(ticket SupportTicket) SupportAgentSkill {
	for _, reason := range ticket.PriorityReasonCodes {
		if reason == "safety_keyword" {
			return SupportAgentSkillSafety
		}
	}
	return supportRoutingSkillForCategory(ticket.Category)
}

func supportAgentMatchesLanguage(agent SupportAgent, locale string) bool {
	language := normalizeLocale(locale)
	for _, candidate := range agent.Languages {
		if normalizeLocale(candidate) == language || normalizeLocale(candidate) == "all" {
			return true
		}
	}
	return len(agent.Languages) == 0
}

func supportAgentHasSkill(agent SupportAgent, skill SupportAgentSkill) bool {
	for _, candidate := range agent.Skills {
		if candidate == skill {
			return true
		}
	}
	return false
}

func supportAgentIsSenior(agent SupportAgent) bool {
	return agent.Level == SupportAgentLevelSenior || agent.Level == SupportAgentLevelLead
}

func supportTicketNeedsSenior(ticket SupportTicket) bool {
	if ticket.Priority == SupportTicketPriorityUrgent {
		return true
	}
	switch ticket.CustomerSegment {
	case SupportCustomerSegmentGuide, SupportCustomerSegmentCreator, SupportCustomerSegmentVIP, SupportCustomerSegmentPartner:
		return true
	default:
		return false
	}
}

func supportAgentWeightedLoad(tickets []SupportTicket, now time.Time) map[string]float64 {
	load := make(map[string]float64)
	for _, ticket := range tickets {
		assigneeID := strings.TrimSpace(ticket.AssigneeID)
		if assigneeID == "" || ticket.Status == SupportTicketStatusResolved || ticket.Status == SupportTicketStatusClosed {
			continue
		}
		weight := 0.8
		switch ticket.Status {
		case SupportTicketStatusWaitingSupport:
			weight = 1.0
		case SupportTicketStatusWaitingUser:
			weight = 0.25
		}
		switch ticket.Priority {
		case SupportTicketPriorityUrgent:
			weight += 1.5
		case SupportTicketPriorityHigh:
			weight += 0.5
		}
		if SupportTicketSLABreached(ticket, now) {
			weight += 1.0
		}
		load[assigneeID] += weight
	}
	return load
}

func appendUniqueString(items []string, value string) []string {
	value = strings.TrimSpace(value)
	if value == "" {
		return items
	}
	for _, item := range items {
		if item == value {
			return items
		}
	}
	return append(items, value)
}

func (uc *HelpUseCase) notifySupportTicketCreated(ctx context.Context, ticket SupportTicket) {
	if uc.operatorNotifier == nil || ticket.ID == "" {
		return
	}
	_ = uc.operatorNotifier.NotifySupportOperators(ctx, SupportOperatorNotificationInput{
		IdempotencyKey: "support:ticket:" + ticket.ID + ":created",
		Category:       "support",
		Priority:       supportOperatorNotificationPriority(ticket.Priority),
		Title:          "New support ticket",
		Body:           supportTicketNotificationBody("New", ticket),
		DeepLink:       supportTicketAdminDeepLink(ticket.ID),
		Data:           supportTicketNotificationData("support_ticket_created", ticket, ""),
		CollapseKey:    "support:ticket:" + ticket.ID,
		TTL:            supportNotificationTTL,
	})
}

func (uc *HelpUseCase) notifySupportTicketSLABreached(ctx context.Context, ticket SupportTicket) {
	if uc.operatorNotifier == nil || ticket.ID == "" {
		return
	}
	_ = uc.operatorNotifier.NotifySupportOperators(ctx, SupportOperatorNotificationInput{
		IdempotencyKey: "support:ticket:" + ticket.ID + ":sla_breached",
		Category:       "support",
		Priority:       "high",
		Title:          "Support SLA breached",
		Body:           supportTicketNotificationBody("SLA breached for", ticket),
		DeepLink:       supportTicketAdminDeepLink(ticket.ID),
		Data:           supportTicketNotificationData("support_ticket_sla_breached", ticket, "breached"),
		CollapseKey:    "support:ticket:" + ticket.ID + ":sla",
		TTL:            supportNotificationTTL,
	})
}

func (uc *HelpUseCase) notifySupportTicketReplied(ctx context.Context, ticket SupportTicket, messageID string, clientMessageID string) {
	if uc.userNotifier == nil || strings.TrimSpace(ticket.ID) == "" || strings.TrimSpace(ticket.UserID) == "" {
		return
	}
	messageKey := nonEmpty(messageID, clientMessageID)
	if messageKey == "" {
		messageKey = strconv.FormatInt(ticket.UpdatedAt.UTC().UnixNano(), 10)
	}
	notificationText := supportReplyNotificationText(ticket.Locale)
	_ = uc.userNotifier.NotifySupportUser(ctx, ticket.UserID, SupportUserNotificationInput{
		IdempotencyKey: "support:ticket:" + ticket.ID + ":reply:" + messageKey,
		Category:       "support",
		Priority:       "normal",
		Title:          notificationText.Title,
		Body:           notificationText.Body,
		DeepLink:       supportTicketUserDeepLink(ticket.ID),
		Data:           supportTicketUserNotificationData("support_ticket_replied", ticket, messageID, clientMessageID),
		CollapseKey:    "support:ticket:" + ticket.ID,
		TTL:            supportNotificationTTL,
	})
}

type localizedSupportNotificationText struct {
	Title string
	Body  string
}

func supportReplyNotificationText(locale string) localizedSupportNotificationText {
	switch supportNotificationLanguage(locale) {
	case "ru":
		return localizedSupportNotificationText{
			Title: "Поддержка ответила",
			Body:  "Поддержка ответила в вашем обращении.",
		}
	case "kk":
		return localizedSupportNotificationText{
			Title: "Қолдау жауап берді",
			Body:  "Қолдау сұрауыңызға жауап берді.",
		}
	default:
		return localizedSupportNotificationText{
			Title: "Support replied",
			Body:  "Support replied to your ticket.",
		}
	}
}

func supportNotificationLanguage(locale string) string {
	normalized := normalizeLocale(locale)
	if idx := strings.Index(normalized, "-"); idx > 0 {
		normalized = normalized[:idx]
	}
	switch normalized {
	case "ru", "kk":
		return normalized
	default:
		return "en"
	}
}

func supportOperatorNotificationPriority(priority SupportTicketPriority) string {
	switch priority {
	case SupportTicketPriorityUrgent, SupportTicketPriorityHigh:
		return "high"
	default:
		return "normal"
	}
}

func supportTicketNotificationBody(prefix string, ticket SupportTicket) string {
	category := strings.TrimSpace(string(ticket.Category))
	if category == "" {
		category = "technical"
	}
	source := strings.TrimSpace(ticket.Source)
	if source == "" {
		return prefix + " " + category + " support ticket."
	}
	return prefix + " " + category + " support ticket from " + source + "."
}

func supportTicketAdminDeepLink(ticketID string) string {
	return "/admin/support/tickets/" + strings.TrimSpace(ticketID)
}

func supportTicketUserDeepLink(_ string) string {
	return "/help/support"
}

func supportTicketNotificationData(event string, ticket SupportTicket, sla string) map[string]string {
	data := make(map[string]string, len(ticket.Context)+9)
	data["event"] = event
	data["ticketId"] = ticket.ID
	data["userId"] = ticket.UserID
	data["category"] = string(ticket.Category)
	data["status"] = string(ticket.Status)
	data["priority"] = string(ticket.Priority)
	data["source"] = ticket.Source
	data["locale"] = ticket.Locale
	if ticket.ConversationID != "" {
		data["conversationId"] = ticket.ConversationID
	}
	if sla != "" {
		data["sla"] = sla
	}
	for key, value := range ticket.Context {
		key = strings.TrimSpace(key)
		value = truncateEventValue(strings.TrimSpace(value), 180)
		if key == "" || value == "" {
			continue
		}
		data[key] = value
	}
	return data
}

func supportTicketUserNotificationData(event string, ticket SupportTicket, messageID string, clientMessageID string) map[string]string {
	data := map[string]string{
		"event":    event,
		"ticketId": ticket.ID,
		"category": string(ticket.Category),
		"status":   string(ticket.Status),
		"priority": string(ticket.Priority),
		"source":   ticket.Source,
		"locale":   ticket.Locale,
	}
	if ticket.ConversationID != "" {
		data["conversationId"] = ticket.ConversationID
	}
	if messageID = strings.TrimSpace(messageID); messageID != "" {
		data["messageId"] = messageID
	}
	if clientMessageID = strings.TrimSpace(clientMessageID); clientMessageID != "" {
		data["clientMessageId"] = clientMessageID
	}
	if event == "support_ticket_replied" {
		addLocalizedSupportReplyNotificationData(data)
	}
	return data
}

func addLocalizedSupportReplyNotificationData(data map[string]string) {
	for _, locale := range []string{"en", "ru", "kk"} {
		text := supportReplyNotificationText(locale)
		data["title."+locale] = text.Title
		data["body."+locale] = text.Body
	}
}

func (uc *HelpUseCase) GetSupportTicket(ctx context.Context, ticketID string) (SupportTicket, []SupportTicketEvent, error) {
	ticketID = strings.TrimSpace(ticketID)
	if ticketID == "" {
		return SupportTicket{}, nil, ErrInvalidSupportAdminAction
	}
	ticket, events, err := uc.repo.GetSupportTicket(ctx, ticketID)
	if err != nil {
		if errors.Is(err, ErrSupportTicketNotFound) {
			return SupportTicket{}, nil, ErrSupportTicketNotFound
		}
		return SupportTicket{}, nil, ErrRepositoryFailed
	}
	return ticket, events, nil
}

type AssignSupportTicketInput struct {
	TicketID   string
	ActorID    string
	AssigneeID string
	Reason     string
}

func (uc *HelpUseCase) AssignSupportTicket(ctx context.Context, input AssignSupportTicketInput) (SupportTicket, error) {
	actorID := strings.TrimSpace(input.ActorID)
	assigneeID := strings.TrimSpace(input.AssigneeID)
	reason := truncateEventValue(strings.TrimSpace(input.Reason), 400)
	if actorID == "" || assigneeID == "" || reason == "" || strings.TrimSpace(input.TicketID) == "" {
		return SupportTicket{}, ErrInvalidSupportAdminAction
	}
	ticket, _, err := uc.GetSupportTicket(ctx, input.TicketID)
	if err != nil {
		return SupportTicket{}, err
	}
	now := uc.now().UTC()
	previousAssigneeID := strings.TrimSpace(ticket.AssigneeID)
	ticket.AssigneeID = assigneeID
	ticket.Status = SupportTicketStatusAssigned
	ticket.AssignmentStatus = SupportAssignmentStatusManual
	ticket.AssignmentReason = reason
	ticket.AssignmentReasonCodes = []string{"manual_assignment"}
	ticket.AssignedAt = &now
	ticket.UpdatedAt = now
	event := supportEvent(ticket.ID, actorID, "ticket_manually_reassigned", map[string]string{
		"assignee_id":          assigneeID,
		"previous_assignee_id": previousAssigneeID,
		"reason":               reason,
		"reason_codes":         "manual_assignment",
	}, now)
	return uc.updateTicket(ctx, ticket, event)
}

type ReplyToSupportTicketInput struct {
	TicketID         string
	ActorID          string
	ActorDisplayName string
	Message          string
	ConversationID   string
	MessageID        string
	FileIDs          []string
	IdempotencyKey   string
}

func (uc *HelpUseCase) ReplyToSupportTicket(ctx context.Context, input ReplyToSupportTicketInput) (SupportTicket, error) {
	actorID := strings.TrimSpace(input.ActorID)
	message := strings.TrimSpace(input.Message)
	if actorID == "" || strings.TrimSpace(input.TicketID) == "" || message == "" {
		return SupportTicket{}, ErrInvalidSupportAdminAction
	}
	ticket, events, err := uc.GetSupportTicket(ctx, input.TicketID)
	if err != nil {
		return SupportTicket{}, err
	}
	clientMessageID := supportClientMessageID(ticket.ID, actorID, input.IdempotencyKey)
	if supportReplyEventRecorded(events, "agent_replied", clientMessageID) {
		return ticket, nil
	}
	now := uc.now().UTC()
	fileIDs := normalizeSupportFileIDs(input.FileIDs)
	if ticket.FirstResponseAt == nil {
		firstResponseAt := now
		ticket.FirstResponseAt = &firstResponseAt
	}
	actorDisplayName := sanitizeSupportActorName(input.ActorDisplayName)
	conversationID := strings.TrimSpace(input.ConversationID)
	if conversationID != "" {
		ticket.ConversationID = conversationID
	}
	chatMessageID := strings.TrimSpace(input.MessageID)
	if uc.chat != nil && ticket.ConversationID != "" {
		result, err := uc.chat.SendSupportMessage(ctx, SupportChatMessageInput{
			ConversationID:   ticket.ConversationID,
			ActorID:          actorID,
			ActorDisplayName: actorDisplayName,
			Message:          message,
			FileIDs:          fileIDs,
			ClientMessageID:  clientMessageID,
		})
		if err != nil {
			slog.Warn("support chat send failed; storing agent reply in ticket events only", "error", err, "ticket_id", ticket.ID)
		} else {
			chatMessageID = strings.TrimSpace(result.MessageID)
		}
	} else if uc.chat != nil {
		slog.Warn("support chat conversation missing; storing agent reply in ticket events only", "ticket_id", ticket.ID)
	}
	ticket.Status = SupportTicketStatusWaitingUser
	ticket.LastMessageAt = now
	ticket.UpdatedAt = now
	payload := map[string]string{"message_preview": truncateEventValue(message, 160)}
	if actorDisplayName != "" {
		payload["actor_display_name"] = actorDisplayName
	}
	if ticket.ConversationID != "" {
		payload["conversation_id"] = ticket.ConversationID
	}
	if chatMessageID != "" {
		payload["message_id"] = chatMessageID
	}
	if clientMessageID != "" {
		payload["client_message_id"] = clientMessageID
	}
	if len(fileIDs) > 0 {
		payload["file_ids"] = strings.Join(fileIDs, ",")
		payload["attachment_count"] = strconv.Itoa(len(fileIDs))
	}
	event := supportEvent(ticket.ID, actorID, "agent_replied", payload, now)
	updated, err := uc.updateTicket(ctx, ticket, event)
	if err != nil {
		return SupportTicket{}, err
	}
	uc.notifySupportTicketReplied(ctx, updated, chatMessageID, clientMessageID)
	return updated, nil
}

type ResolveSupportTicketInput struct {
	TicketID   string
	ActorID    string
	Resolution string
}

func (uc *HelpUseCase) ResolveSupportTicket(ctx context.Context, input ResolveSupportTicketInput) (SupportTicket, error) {
	actorID := strings.TrimSpace(input.ActorID)
	if actorID == "" || strings.TrimSpace(input.TicketID) == "" {
		return SupportTicket{}, ErrInvalidSupportAdminAction
	}
	ticket, _, err := uc.GetSupportTicket(ctx, input.TicketID)
	if err != nil {
		return SupportTicket{}, err
	}
	now := uc.now().UTC()
	resolvedAt := now
	ticket.Status = SupportTicketStatusResolved
	ticket.ResolvedAt = &resolvedAt
	ticket.UpdatedAt = now
	event := supportEvent(ticket.ID, actorID, "ticket_resolved", map[string]string{
		"resolution": truncateEventValue(strings.TrimSpace(input.Resolution), 400),
	}, now)
	return uc.updateTicket(ctx, ticket, event)
}

type ReopenSupportTicketInput struct {
	TicketID string
	ActorID  string
	Reason   string
}

func (uc *HelpUseCase) ReopenSupportTicket(ctx context.Context, input ReopenSupportTicketInput) (SupportTicket, error) {
	actorID := strings.TrimSpace(input.ActorID)
	if actorID == "" || strings.TrimSpace(input.TicketID) == "" {
		return SupportTicket{}, ErrInvalidSupportAdminAction
	}
	ticket, _, err := uc.GetSupportTicket(ctx, input.TicketID)
	if err != nil {
		return SupportTicket{}, err
	}
	now := uc.now().UTC()
	ticket.Status = SupportTicketStatusReopened
	ticket.ResolvedAt = nil
	ticket.UpdatedAt = now
	event := supportEvent(ticket.ID, actorID, "ticket_reopened", map[string]string{
		"reason": truncateEventValue(strings.TrimSpace(input.Reason), 400),
	}, now)
	updated, err := uc.updateTicket(ctx, ticket, event)
	if err != nil {
		return SupportTicket{}, err
	}
	if strings.TrimSpace(updated.AssigneeID) == "" && updated.AssignmentStatus == SupportAssignmentStatusNeedsAssignment {
		assignedTicket, assignmentEvent, assignmentChanged := uc.autoAssignSupportTicket(ctx, updated, now)
		if assignmentChanged {
			return uc.updateTicket(ctx, assignedTicket, assignmentEvent)
		}
	}
	return updated, nil
}

type AddSupportTicketNoteInput struct {
	TicketID string
	ActorID  string
	Note     string
}

func (uc *HelpUseCase) AddSupportTicketNote(ctx context.Context, input AddSupportTicketNoteInput) error {
	actorID := strings.TrimSpace(input.ActorID)
	note := strings.TrimSpace(input.Note)
	if actorID == "" || strings.TrimSpace(input.TicketID) == "" || note == "" {
		return ErrInvalidSupportAdminAction
	}
	if _, _, err := uc.GetSupportTicket(ctx, input.TicketID); err != nil {
		return err
	}
	event := supportEvent(strings.TrimSpace(input.TicketID), actorID, "internal_note_added", map[string]string{
		"note": truncateEventValue(note, 1200),
	}, uc.now().UTC())
	if err := uc.repo.AppendSupportTicketEvent(ctx, event); err != nil {
		return ErrRepositoryFailed
	}
	return nil
}

func (uc *HelpUseCase) updateTicket(ctx context.Context, ticket SupportTicket, event SupportTicketEvent) (SupportTicket, error) {
	if err := uc.repo.UpdateSupportTicket(ctx, ticket, event); err != nil {
		if errors.Is(err, ErrSupportTicketNotFound) {
			return SupportTicket{}, ErrSupportTicketNotFound
		}
		return SupportTicket{}, ErrRepositoryFailed
	}
	return ticket, nil
}

func supportEvent(ticketID string, actorID string, eventType string, payload map[string]string, now time.Time) SupportTicketEvent {
	if payload == nil {
		payload = map[string]string{}
	}
	return SupportTicketEvent{
		TicketID:  ticketID,
		ActorID:   actorID,
		ActorType: SupportActorTypeAgent,
		EventType: eventType,
		Payload:   payload,
		CreatedAt: now,
	}
}

func supportUserEvent(ticketID string, actorID string, eventType string, payload map[string]string, now time.Time) SupportTicketEvent {
	if payload == nil {
		payload = map[string]string{}
	}
	return SupportTicketEvent{
		TicketID:  ticketID,
		ActorID:   actorID,
		ActorType: SupportActorTypeUser,
		EventType: eventType,
		Payload:   payload,
		CreatedAt: now,
	}
}

func supportSystemEvent(ticketID string, eventType string, payload map[string]string, now time.Time) SupportTicketEvent {
	if payload == nil {
		payload = map[string]string{}
	}
	return SupportTicketEvent{
		TicketID:  strings.TrimSpace(ticketID),
		ActorID:   "system",
		ActorType: SupportActorTypeSystem,
		EventType: strings.TrimSpace(eventType),
		Payload:   payload,
		CreatedAt: now,
	}
}

func mergeSupportReasonCodes(left []string, right []string) []string {
	merged := make([]string, 0, len(left)+len(right))
	for _, item := range left {
		merged = appendUniqueString(merged, item)
	}
	for _, item := range right {
		merged = appendUniqueString(merged, item)
	}
	return merged
}

func supportReplyEventRecorded(events []SupportTicketEvent, eventType string, clientMessageID string) bool {
	clientMessageID = strings.TrimSpace(clientMessageID)
	if clientMessageID == "" {
		return false
	}
	for _, event := range events {
		if event.EventType != eventType {
			continue
		}
		if strings.TrimSpace(event.Payload["client_message_id"]) == clientMessageID {
			return true
		}
	}
	return false
}

func supportClientMessageID(ticketID string, actorID string, idempotencyKey string) string {
	idempotencyKey = strings.TrimSpace(idempotencyKey)
	if idempotencyKey == "" {
		return ""
	}
	sum := sha1.Sum([]byte("support-reply:" + strings.TrimSpace(ticketID) + ":" + strings.TrimSpace(actorID) + ":" + idempotencyKey))
	bytes := make([]byte, 16)
	copy(bytes, sum[:16])
	bytes[6] = (bytes[6] & 0x0f) | 0x50
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	encoded := hex.EncodeToString(bytes)
	return encoded[0:8] + "-" + encoded[8:12] + "-" + encoded[12:16] + "-" + encoded[16:20] + "-" + encoded[20:32]
}

type rankedArticle struct {
	article     HelpArticle
	translation ArticleTranslation
	score       int
}

func sortRankedArticles(items []rankedArticle) {
	sort.SliceStable(items, func(i, j int) bool {
		if items[i].score != items[j].score {
			return items[i].score > items[j].score
		}
		return items[i].article.UpdatedAt.After(items[j].article.UpdatedAt)
	})
}

func contextualArticleScore(article HelpArticle, input ListContextualArticlesInput, tagScore int) int {
	score := tagScore * 10
	if normalizeHelpSurface(input.Surface) == HelpSurfaceHelpCenter && containsNormalized(article.Tags, "popular") {
		score++
	}
	return score
}

func collectRankedArticles(items []rankedArticle, limit int) []HelpArticleListItem {
	return collectRankedArticlesPage(items, limit, 0)
}

func collectRankedArticlesPage(items []rankedArticle, limit int, offset int) []HelpArticleListItem {
	offset = normalizeOffset(offset)
	if offset >= len(items) {
		return []HelpArticleListItem{}
	}
	items = items[offset:]
	if len(items) < limit {
		limit = len(items)
	}
	result := make([]HelpArticleListItem, 0, limit)
	for i := 0; i < limit; i++ {
		item := items[i]
		result = append(result, HelpArticleListItem{
			ID:                item.article.ID,
			Slug:              item.article.Slug,
			Title:             item.translation.Title,
			ShortAnswer:       item.translation.ShortAnswer,
			Body:              item.translation.Body,
			Actions:           append([]ArticleAction(nil), item.article.Actions...),
			RelatedArticleIDs: append([]string(nil), item.article.RelatedArticleIDs...),
			Tags:              append([]string(nil), item.article.Tags...),
			UpdatedAt:         item.article.UpdatedAt,
		})
	}
	return result
}

func collectLocalizedArticles(articles []HelpArticle, locale string, limit int) []HelpArticleListItem {
	if len(articles) < limit {
		limit = len(articles)
	}
	result := make([]HelpArticleListItem, 0, limit)
	for _, article := range articles {
		if len(result) >= limit {
			break
		}
		translation, ok := localizedArticle(article, locale)
		if !ok {
			continue
		}
		result = append(result, HelpArticleListItem{
			ID:                article.ID,
			Slug:              article.Slug,
			Title:             translation.Title,
			ShortAnswer:       translation.ShortAnswer,
			Body:              translation.Body,
			Actions:           append([]ArticleAction(nil), article.Actions...),
			RelatedArticleIDs: append([]string(nil), article.RelatedArticleIDs...),
			Tags:              append([]string(nil), article.Tags...),
			UpdatedAt:         article.UpdatedAt,
		})
	}
	return result
}

func localizedArticle(article HelpArticle, locale string) (ArticleTranslation, bool) {
	if len(article.Translations) == 0 {
		return ArticleTranslation{}, false
	}
	normalized := normalizeLocale(locale)
	if value, ok := article.Translations[normalized]; ok && value.Title != "" {
		return value, true
	}
	if dash := strings.IndexByte(normalized, '-'); dash > 0 {
		if value, ok := article.Translations[normalized[:dash]]; ok && value.Title != "" {
			return value, true
		}
	}
	for _, fallback := range []string{"en", "ru", "kk"} {
		if value, ok := article.Translations[fallback]; ok && value.Title != "" {
			return value, true
		}
	}
	return ArticleTranslation{}, false
}

func localizedCategoryTitle(category HelpCategory, locale string) string {
	if category.Title != "" {
		return strings.TrimSpace(category.Title)
	}
	normalized := normalizeLocale(locale)
	if value, ok := category.Translations[normalized]; ok && strings.TrimSpace(value.Title) != "" {
		return strings.TrimSpace(value.Title)
	}
	if dash := strings.IndexByte(normalized, '-'); dash > 0 {
		if value, ok := category.Translations[normalized[:dash]]; ok && strings.TrimSpace(value.Title) != "" {
			return strings.TrimSpace(value.Title)
		}
	}
	for _, fallback := range []string{"en", "ru", "kk"} {
		if value, ok := category.Translations[fallback]; ok && strings.TrimSpace(value.Title) != "" {
			return strings.TrimSpace(value.Title)
		}
	}
	return humanizeHelpCategorySlug(category.Slug, category.ID)
}

func humanizeHelpCategorySlug(slug string, fallback string) string {
	value := strings.TrimSpace(slug)
	if value == "" {
		value = strings.TrimSpace(fallback)
	}
	parts := strings.FieldsFunc(value, func(r rune) bool {
		return r == '-' || r == '_'
	})
	for index, part := range parts {
		part = strings.ToLower(strings.TrimSpace(part))
		if part == "" {
			continue
		}
		parts[index] = strings.ToUpper(part[:1]) + part[1:]
	}
	return strings.Join(parts, " ")
}

func normalizeLocale(locale string) string {
	normalized := strings.ToLower(strings.TrimSpace(locale))
	if normalized == "" {
		return "en"
	}
	normalized = strings.ReplaceAll(normalized, "_", "-")
	return normalized
}

func containsSurface(surfaces []HelpSurface, surface HelpSurface) bool {
	for _, item := range surfaces {
		if item == surface {
			return true
		}
	}
	return false
}

func normalizeHelpSurface(surface HelpSurface) HelpSurface {
	if surface == "" {
		return HelpSurfaceHelpCenter
	}
	return surface
}

func matchesVisibility(visibility ArticleVisibility, userState string, paymentStatus string) bool {
	if len(visibility.UserStates) > 0 && !containsNormalized(visibility.UserStates, userState) {
		return false
	}
	if len(visibility.PaymentStatuses) > 0 && !containsNormalized(visibility.PaymentStatuses, paymentStatus) {
		return false
	}
	return true
}

func countTagMatches(articleTags []string, inputTags []string) int {
	if len(articleTags) == 0 || len(inputTags) == 0 {
		return 0
	}
	lookup := make(map[string]struct{}, len(articleTags))
	for _, tag := range articleTags {
		lookup[normalizeToken(tag)] = struct{}{}
	}
	count := 0
	for _, tag := range inputTags {
		if _, ok := lookup[normalizeToken(tag)]; ok {
			count++
		}
	}
	return count
}

func containsNormalized(items []string, value string) bool {
	needle := normalizeToken(value)
	for _, item := range items {
		if normalizeToken(item) == needle {
			return true
		}
	}
	return false
}

func normalizeLimit(limit int, fallback int) int {
	if limit <= 0 {
		limit = fallback
	}
	if limit > maxHelpResultLimit {
		return maxHelpResultLimit
	}
	return limit
}

func normalizeOffset(offset int) int {
	if offset < 0 {
		return 0
	}
	return offset
}

func normalizeSearchText(value string) string {
	return strings.Join(strings.Fields(strings.ToLower(strings.TrimSpace(value))), " ")
}

func normalizeToken(value string) string {
	return strings.ToLower(strings.TrimSpace(value))
}

func normalizeIdempotencyKey(value string) string {
	return truncateEventValue(strings.TrimSpace(value), 180)
}

func articleSearchScore(article HelpArticle, translation ArticleTranslation, query string) int {
	terms := strings.Fields(query)
	if len(terms) == 0 {
		return 0
	}
	score := 0
	for _, term := range terms {
		termScore := weightedFieldScore(translation.Title, term, 5) +
			weightedFieldScore(translation.ShortAnswer, term, 4) +
			weightedFieldScore(translation.Body, term, 2) +
			weightedFieldScore(strings.Join(article.Tags, " "), term, 1)
		if termScore == 0 {
			return 0
		}
		score += termScore
	}
	return score
}

func weightedFieldScore(value string, term string, weight int) int {
	text := normalizeSearchText(value)
	if text == "" {
		return 0
	}
	switch {
	case strings.HasPrefix(text, term):
		return weight * 3
	case strings.Contains(text, " "+term):
		return weight * 2
	case strings.Contains(text, term):
		return weight
	default:
		return 0
	}
}

func normalizeHelpArticleDraft(article HelpArticle, actorID string, now time.Time) (HelpArticle, error) {
	article.ID = strings.TrimSpace(article.ID)
	article.Slug = strings.TrimSpace(article.Slug)
	if article.ID == "" && article.Slug != "" {
		article.ID = article.Slug
	}
	if article.Slug == "" && article.ID != "" {
		article.Slug = article.ID
	}
	if article.ID == "" || article.Slug == "" {
		return HelpArticle{}, ErrInvalidHelpArticle
	}
	if article.Status == "" {
		article.Status = ArticleStatusDraft
	}
	if article.Status != ArticleStatusDraft && article.Status != ArticleStatusReview {
		article.Status = ArticleStatusDraft
	}
	article.CategoryID = strings.TrimSpace(article.CategoryID)
	article.OwnerID = nonEmpty(article.OwnerID, strings.TrimSpace(actorID))
	article.ReviewerID = ""
	article.PublishedAt = nil
	article.LastReviewedAt = nil
	article.Tags = normalizeStringList(article.Tags)
	article.Surfaces = normalizeSurfaces(article.Surfaces)
	article.RelatedArticleIDs = normalizeStringList(article.RelatedArticleIDs)
	article.Translations = normalizeTranslations(article.Translations)
	article.Actions = normalizeActions(article.Actions)
	article.UpdatedAt = now
	if len(article.Translations) == 0 {
		return HelpArticle{}, ErrInvalidHelpArticle
	}
	if len(article.Surfaces) == 0 {
		article.Surfaces = []HelpSurface{HelpSurfaceHelpCenter}
	}
	return article, nil
}

func normalizeHelpCategory(input UpsertHelpCategoryInput, now time.Time) (HelpCategory, error) {
	id := strings.TrimSpace(input.CategoryID)
	slug := strings.TrimSpace(input.Slug)
	if id == "" && slug != "" {
		id = slug
	}
	if slug == "" && id != "" {
		slug = id
	}
	if id == "" || slug == "" {
		return HelpCategory{}, ErrInvalidHelpArticle
	}
	status := input.Status
	if status == "" {
		status = ArticleStatusDraft
	}
	if status != ArticleStatusDraft &&
		status != ArticleStatusReview &&
		status != ArticleStatusPublished &&
		status != ArticleStatusArchived {
		return HelpCategory{}, ErrInvalidHelpArticle
	}
	return HelpCategory{
		ID:        id,
		Slug:      slug,
		Status:    status,
		SortOrder: input.SortOrder,
		CreatedAt: now,
		UpdatedAt: now,
	}, nil
}

func normalizeSupportSavedReply(input UpsertSupportSavedReplyInput, now time.Time) (SupportSavedReply, error) {
	replyID := strings.TrimSpace(input.ReplyID)
	if replyID == "" {
		return SupportSavedReply{}, ErrInvalidSupportAdminAction
	}
	status := input.Status
	if status == "" {
		status = ArticleStatusPublished
	}
	if status != ArticleStatusDraft &&
		status != ArticleStatusReview &&
		status != ArticleStatusPublished &&
		status != ArticleStatusArchived {
		return SupportSavedReply{}, ErrInvalidSupportAdminAction
	}
	translations := normalizeSavedReplyTranslations(input.Translations)
	if len(translations) == 0 {
		return SupportSavedReply{}, ErrInvalidSupportAdminAction
	}
	return SupportSavedReply{
		ID:           replyID,
		Category:     strings.TrimSpace(input.Category),
		Status:       status,
		Tags:         normalizeStringList(input.Tags),
		SortOrder:    input.SortOrder,
		Translations: translations,
		CreatedAt:    now,
		UpdatedAt:    now,
	}, nil
}

func normalizeSavedReplyTranslations(input map[string]SupportSavedReplyTranslation) map[string]SupportSavedReplyTranslation {
	if len(input) == 0 {
		return map[string]SupportSavedReplyTranslation{}
	}
	allowed := map[string]struct{}{}
	for _, locale := range supportedArticleLocales() {
		allowed[locale] = struct{}{}
	}
	out := make(map[string]SupportSavedReplyTranslation, len(input))
	for locale, translation := range input {
		locale = normalizeLocale(locale)
		if _, ok := allowed[locale]; !ok {
			continue
		}
		title := strings.TrimSpace(translation.Title)
		body := strings.TrimSpace(translation.Body)
		if title == "" && body == "" {
			continue
		}
		if title == "" || body == "" {
			return map[string]SupportSavedReplyTranslation{}
		}
		out[locale] = SupportSavedReplyTranslation{Title: title, Body: body}
	}
	return out
}

func validatePublishableArticle(article HelpArticle, requireAllLocales bool) error {
	if strings.TrimSpace(article.ID) == "" || strings.TrimSpace(article.Slug) == "" {
		return ErrInvalidHelpArticle
	}
	if len(article.Surfaces) == 0 || len(article.Translations) == 0 {
		return ErrInvalidHelpArticle
	}
	if requireAllLocales {
		for _, locale := range supportedArticleLocales() {
			translation, ok := article.Translations[locale]
			if !ok || !translationUseful(translation) {
				return ErrInvalidHelpArticle
			}
		}
		return nil
	}
	for _, translation := range article.Translations {
		if translationUseful(translation) {
			return nil
		}
	}
	return ErrInvalidHelpArticle
}

func supportedArticleLocales() []string {
	return []string{"en", "ru", "kk"}
}

func normalizeTranslations(input map[string]ArticleTranslation) map[string]ArticleTranslation {
	if len(input) == 0 {
		return map[string]ArticleTranslation{}
	}
	allowed := map[string]struct{}{}
	for _, locale := range supportedArticleLocales() {
		allowed[locale] = struct{}{}
	}
	out := make(map[string]ArticleTranslation, len(input))
	for locale, translation := range input {
		locale = normalizeLocale(locale)
		if _, ok := allowed[locale]; !ok {
			continue
		}
		translation.Title = strings.TrimSpace(translation.Title)
		translation.ShortAnswer = strings.TrimSpace(translation.ShortAnswer)
		translation.Body = strings.TrimSpace(translation.Body)
		if translationUseful(translation) {
			out[locale] = translation
		}
	}
	return out
}

func translationUseful(translation ArticleTranslation) bool {
	return strings.TrimSpace(translation.Title) != "" &&
		strings.TrimSpace(translation.ShortAnswer) != "" &&
		strings.TrimSpace(translation.Body) != ""
}

func normalizeStringList(items []string) []string {
	if len(items) == 0 {
		return nil
	}
	seen := make(map[string]struct{}, len(items))
	out := make([]string, 0, len(items))
	for _, item := range items {
		item = normalizeToken(item)
		if item == "" {
			continue
		}
		if _, ok := seen[item]; ok {
			continue
		}
		seen[item] = struct{}{}
		out = append(out, item)
	}
	return out
}

func normalizeSurfaces(items []HelpSurface) []HelpSurface {
	if len(items) == 0 {
		return nil
	}
	allowed := map[HelpSurface]struct{}{
		HelpSurfaceHelpCenter:        {},
		HelpSurfacePlaces:            {},
		HelpSurfaceActivityDetails:   {},
		HelpSurfaceExcursionDetails:  {},
		HelpSurfacePlaceDetails:      {},
		HelpSurfaceCurrencyConverter: {},
	}
	seen := make(map[HelpSurface]struct{}, len(items))
	out := make([]HelpSurface, 0, len(items))
	for _, item := range items {
		item = HelpSurface(normalizeToken(string(item)))
		if _, ok := allowed[item]; !ok {
			continue
		}
		if _, ok := seen[item]; ok {
			continue
		}
		seen[item] = struct{}{}
		out = append(out, item)
	}
	return out
}

func normalizeActions(actions []ArticleAction) []ArticleAction {
	if len(actions) == 0 {
		return nil
	}
	allowed := map[ArticleActionType]struct{}{
		ArticleActionOpenChat:       {},
		ArticleActionContactSupport: {},
		ArticleActionOpenRoute:      {},
	}
	out := make([]ArticleAction, 0, len(actions))
	for _, action := range actions {
		action.Type = ArticleActionType(normalizeToken(string(action.Type)))
		action.Target = strings.TrimSpace(action.Target)
		action.Label = strings.TrimSpace(action.Label)
		if action.Target == "" {
			continue
		}
		if _, ok := allowed[action.Type]; !ok {
			continue
		}
		out = append(out, action)
	}
	return out
}

func helpArticleEvent(articleID string, actorID string, eventType string, payload map[string]string, now time.Time) HelpArticleEvent {
	if payload == nil {
		payload = map[string]string{}
	}
	return HelpArticleEvent{
		ArticleID: strings.TrimSpace(articleID),
		ActorID:   strings.TrimSpace(actorID),
		ActorType: SupportActorTypeAdmin,
		EventType: eventType,
		Payload:   payload,
		CreatedAt: now,
	}
}

func sanitizeSupportContext(context map[string]string) map[string]string {
	if len(context) == 0 {
		return map[string]string{}
	}
	allowed := map[string]struct{}{
		"activity_id":        {},
		"amount":             {},
		"article_id":         {},
		"city_id":            {},
		"city_name":          {},
		"conversation_id":    {},
		"converted_amount":   {},
		"country_code":       {},
		"currency_pair":      {},
		"entity_id":          {},
		"excursion_id":       {},
		"failed_search":      {},
		"from_currency":      {},
		"locale":             {},
		"payment_id":         {},
		"place_id":           {},
		"previous_ticket_id": {},
		"screen":             {},
		"search_query":       {},
		"sort":               {},
		"source_route":       {},
		"to_currency":        {},
		"user_nickname":      {},
	}
	sanitized := make(map[string]string)
	for key, value := range context {
		normalizedKey := normalizeToken(key)
		if _, ok := allowed[normalizedKey]; !ok {
			continue
		}
		trimmed := strings.TrimSpace(value)
		if trimmed == "" {
			continue
		}
		sanitized[normalizedKey] = trimmed
	}
	return sanitized
}

func sanitizeSupportActorName(value string) string {
	return truncateEventValue(strings.TrimSpace(value), 120)
}

func normalizeSupportFileIDs(values []string) []string {
	if len(values) == 0 {
		return nil
	}
	const maxFileIDs = 10
	normalized := make([]string, 0, min(len(values), maxFileIDs))
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		fileID := truncateEventValue(strings.TrimSpace(value), 128)
		if fileID == "" {
			continue
		}
		if _, ok := seen[fileID]; ok {
			continue
		}
		seen[fileID] = struct{}{}
		normalized = append(normalized, fileID)
		if len(normalized) >= maxFileIDs {
			break
		}
	}
	return normalized
}

func nonEmpty(value string, fallback string) string {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return fallback
	}
	return trimmed
}

func truncateEventValue(value string, limit int) string {
	if limit <= 0 || len(value) <= limit {
		return value
	}
	return value[:limit]
}

func generateTicketID(userID string, now time.Time) string {
	safeUserID := strings.NewReplacer(" ", "-", "/", "-", "\\", "-").Replace(strings.TrimSpace(userID))
	if safeUserID == "" {
		safeUserID = "user"
	}
	return "support-" + safeUserID + "-" + now.Format("20060102150405.000000000")
}
