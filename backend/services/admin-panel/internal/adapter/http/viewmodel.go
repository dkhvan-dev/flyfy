package http

import (
	"encoding/json"
	"fmt"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type PageData struct {
	Title            string
	Locale           string
	Path             string
	Staff            *model.StaffUser
	CSRFToken        string
	Error            string
	MaintenanceError bool
	Flash            string
	ActiveNav        string
	Data             any
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
	FraudBlocksURL       string
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
	Countries            []AttractionOptionView
	Cities               []AttractionOptionView
}

type QueueFilterViewData struct {
	Status      string
	CountryCode string
	CityID      string
	City        string
	Search      string
	Signal      string
	Risk        string
	Sort        string
	Query       string
}

type ModerationQueueItemView struct {
	Case             *model.ModerationCase
	Excursion        *model.ExcursionModerationItem
	Activity         *model.ActivityModerationItem
	GuideApplication *model.GuideApplicationModerationItem
	ChatMessage      *model.ChatMessageModerationItem
	Post             *model.PostModerationItem
	PostReport       *model.PostReportModerationItem
	TargetTitle      string
	TargetSubtitle   string
	GuideName        string
	GuideFullName    string
	DetailURL        string
}

type CaseDetailViewData struct {
	Detail      *app.ModerationCaseDetail
	QueueURL    string
	ReturnQuery string
}

type GuideListViewData struct {
	Items      []model.GuideApplicationModerationItem
	QueueURL   string
	HistoryURL string
}

type FraudBlockListViewData struct {
	Target        model.FraudBlockTarget
	Items         []FraudBlockView
	QueueURL      string
	ReviewBaseURL string
	TitleKey      string
	EmptyKey      string
}

type FeedQualityFilterViewData struct {
	Surface string
	Window  string
	Query   string
}

type FeedQualityDashboardViewData struct {
	Page                  app.FeedQualityDashboardPage
	Filters               FeedQualityFilterViewData
	Items                 []FeedQualityMetricView
	ExperimentSummaries   []FeedQualityExperimentSummaryView
	ShowTab               bool
	ShowCommunity         bool
	ShowPostProfile       bool
	ShowRankingExperiment bool
	ShowCandidateSource   bool
	ResetURL              string
}

type FeedQualityMetricView struct {
	Item               model.FeedQualityMetric
	NegativeFeedback   int64
	Engagement         int64
	ClickRateText      string
	DwellRateText      string
	EngagementRateText string
	SubscribeRateText  string
	ConversionRateText string
	NegativeRateText   string
	ReportRateText     string
}

type FeedQualityExperimentSummaryView struct {
	Item                    app.FeedQualityExperimentSummary
	MetricView              FeedQualityMetricView
	Baseline                bool
	ClickRateDeltaText      string
	DwellRateDeltaText      string
	EngagementRateDeltaText string
	SubscribeRateDeltaText  string
	ConversionRateDeltaText string
	NegativeRateDeltaText   string
	ReportRateDeltaText     string
}

type FraudBlockView struct {
	Item          model.FraudBlock
	SubjectText   string
	ActorText     string
	ReasonText    string
	MetadataText  string
	ReviewBaseURL string
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
	ReturnQuery string
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
	Pages         []AttractionPaginationPageViewData
}

type AttractionPaginationPageViewData struct {
	Page      int
	Query     string
	IsCurrent bool
	IsDots    bool
}

type AttractionFormViewData struct {
	Item                 *model.AdminAttraction
	Input                model.AttractionInput
	IsEdit               bool
	SubmitURL            string
	MediaURL             string
	ListURL              string
	Categories           []AttractionOptionView
	Statuses             []AttractionOptionView
	Locales              []AttractionOptionView
	Countries            []AttractionOptionView
	Cities               []AttractionOptionView
	Currencies           []AttractionOptionView
	AccessCityOptions    []AttractionCityLinkOptionView
	DepartureCityOptions []AttractionCityLinkOptionView
}

type CommunityFormViewData struct {
	Input           CommunityFormInput
	Item            *model.AdminCommunity
	IsEdit          bool
	SubmitURL       string
	Locales         []AttractionOptionView
	SlugOptions     []AttractionOptionView
	Topics          []AttractionOptionView
	Visibilities    []AttractionOptionView
	PostingPolicies []AttractionOptionView
	Statuses        []AttractionOptionView
	Countries       []AttractionOptionView
	Cities          []AttractionOptionView
}

type CommunityPlatformViewData struct {
	Catalog                      model.CommunityPlatformCatalog
	Filters                      CommunityPlatformFilterViewData
	PostProfiles                 []CommunityPostProfileView
	Blueprints                   []CommunityBlueprintView
	GeoHubs                      []CommunityGeoHubView
	Instances                    []CommunityInstanceView
	ScopeOptions                 []AttractionOptionView
	Countries                    []AttractionOptionView
	Cities                       []AttractionOptionView
	BlueprintCategoryFilters     []CommunityTableFilterOption
	BlueprintStatusFilters       []CommunityTableFilterOption
	GeoHubTierFilters            []CommunityTableFilterOption
	GeoHubMaterializationFilters []CommunityTableFilterOption
	InstanceScopeFilters         []CommunityTableFilterOption
	InstanceStatusFilters        []CommunityTableFilterOption
	PostProfileKindFilters       []CommunityTableFilterOption
	PostProfileModeFilters       []CommunityTableFilterOption
	MaterializeActionURL         string
	CreateCommunityURL           string
	ResetURL                     string
}

type CommunityPlatformFilterViewData struct {
	CountryCode string
	CityID      string
	ScopeType   string
	Search      string
	Limit       int
	Offset      int
	Query       string
}

const maxCommunityPlatformPageSize = 500

type CommunityPostProfileView struct {
	Item                     model.CommunityPostProfile
	KeyText                  string
	PostKindText             string
	ComposerPresetText       string
	RenderPresetText         string
	ModerationModeText       string
	ActivityCreationModeText string
	Meta                     string
}

type CommunityBlueprintView struct {
	Item                      model.CommunityBlueprint
	Title                     string
	Description               string
	CategoryText              string
	DefaultPostProfileText    string
	AllowedPostProfilesText   string
	EnabledTabsText           string
	SubcategoriesText         string
	PromotionSegmentsText     string
	RolloutPolicyText         string
	DefaultModerationModeText string
	AllowedScopesText         string
}

type CommunityGeoHubView struct {
	Item          model.CommunityGeoHub
	LocationText  string
	EffectiveText string
	ParentText    string
	HubTierText   string
	ReasonText    string
}

type CommunityInstanceView struct {
	Item         model.CommunityInstance
	Title        string
	LocationText string
	ScopeText    string
}

type CommunityTableFilterOption struct {
	Value string
	Text  string
}

type CommunityFormInput struct {
	ID              string
	Slug            string
	TitleI18n       map[string]string
	DescriptionI18n map[string]string
	RulesTextI18n   map[string]string
	Topic           string
	CityID          string
	CountryCode     string
	AvatarFileID    string
	CoverFileID     string
	Visibility      string
	PostingPolicy   string
	Status          string
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
	Hidden      bool
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

type AdminUsersFilterViewData struct {
	Search      string
	Status      string
	Role        string
	CountryCode string
	PageToken   string
	PageSize    int
	Query       string
}

type AdminUsersListViewData struct {
	Items       []AdminUserListItemView
	Filters     AdminUsersFilterViewData
	Countries   []AttractionOptionView
	RoleOptions []AttractionOptionView
	NextPageURL string
	ResetURL    string
	CanModerate bool
	CanRestrict bool
}

type AdminUserListItemView struct {
	Item      model.AdminUserListItem
	DetailURL string
	RolesText string
	TrustText string
}

type AdminUserDetailViewData struct {
	User               model.AdminUserDetail
	Cases              []UserModerationCaseView
	ActiveRestrictions []UserManualRestrictionView
	CanModerate        bool
	CanRestrict        bool
	CaseActionURL      string
	RestrictionURL     string
	PriorityOptions    []string
	DecisionOptions    []string
	RestrictionOptions []string
}

type UserModerationCaseView struct {
	Item       model.UserModerationCase
	ResolveURL string
}

type UserManualRestrictionView struct {
	Item    model.UserManualRestriction
	LiftURL string
}

type TrustAppealFilterViewData struct {
	Status    string
	Search    string
	PageSize  int
	PageToken string
	Query     string
}

type TrustAppealListViewData struct {
	Items       []TrustAppealItemView
	Filters     TrustAppealFilterViewData
	NextPageURL string
	ResetURL    string
	CanDecide   bool
}

type TrustAppealItemView struct {
	Item      model.TrustRestrictionAppeal
	DetailURL string
	UserURL   string
}

type TrustAppealDetailViewData struct {
	Item         model.TrustRestrictionAppeal
	ListURL      string
	ApproveURL   string
	RejectURL    string
	CanDecide    bool
	IsActionable bool
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

func NewTrustAppealListViewData(
	page model.TrustRestrictionAppealListPage,
	filters TrustAppealFilterViewData,
	staff *model.StaffUser,
) TrustAppealListViewData {
	filters = normalizeTrustAppealFilter(filters)
	items := make([]TrustAppealItemView, 0, len(page.Items))
	for _, item := range page.Items {
		items = append(items, TrustAppealItemView{
			Item:      item,
			DetailURL: trustAppealDetailURL(item.ID, filters.Query),
			UserURL:   adminUserDetailURL(item.UserID),
		})
	}
	nextPageURL := ""
	if strings.TrimSpace(page.NextPageToken) != "" {
		nextFilters := filters
		nextFilters.PageToken = page.NextPageToken
		nextPageURL = trustAppealListURL(nextFilters)
	}
	return TrustAppealListViewData{
		Items:       items,
		Filters:     filters,
		NextPageURL: nextPageURL,
		ResetURL:    "/admin/trust/appeals",
		CanDecide:   staff != nil && staff.HasPermission(enum.PermissionUsersRestrict),
	}
}

func NewTrustAppealDetailViewData(
	item model.TrustRestrictionAppeal,
	filters TrustAppealFilterViewData,
	staff *model.StaffUser,
) TrustAppealDetailViewData {
	filters = normalizeTrustAppealFilter(filters)
	return TrustAppealDetailViewData{
		Item:         item,
		ListURL:      trustAppealListURL(filters),
		ApproveURL:   trustAppealDecisionURL(item.ID, "approve", filters.Query),
		RejectURL:    trustAppealDecisionURL(item.ID, "reject", filters.Query),
		CanDecide:    staff != nil && staff.HasPermission(enum.PermissionUsersRestrict),
		IsActionable: item.Status == model.TrustRestrictionAppealStatusOpen,
	}
}

func NewAdminUsersListViewData(
	page model.AdminUserListPage,
	filters AdminUsersFilterViewData,
	staff *model.StaffUser,
) AdminUsersListViewData {
	filters = normalizeAdminUsersFilter(filters)
	items := make([]AdminUserListItemView, 0, len(page.Items))
	for _, item := range page.Items {
		items = append(items, AdminUserListItemView{
			Item:      item,
			DetailURL: "/admin/users/" + item.UserID.String(),
			RolesText: strings.Join(item.Roles, ", "),
			TrustText: adminUserTrustText(item.TrustBand, item.TrustScore),
		})
	}
	nextPageURL := ""
	if strings.TrimSpace(page.NextPageToken) != "" {
		nextFilters := filters
		nextFilters.PageToken = page.NextPageToken
		nextPageURL = adminUsersListURL(nextFilters)
	}
	return AdminUsersListViewData{
		Items:       items,
		Filters:     filters,
		Countries:   attractionCountryFilterOptions(filters.CountryCode),
		RoleOptions: adminUserRoleFilterOptions(filters.Role),
		NextPageURL: nextPageURL,
		ResetURL:    "/admin/users",
		CanModerate: staff != nil && staff.HasPermission(enum.PermissionUsersModerate),
		CanRestrict: staff != nil && staff.HasPermission(enum.PermissionUsersRestrict),
	}
}

func NewAdminUserDetailViewData(page model.AdminUserDetailPage, staff *model.StaffUser) AdminUserDetailViewData {
	userID := page.User.UserID.String()
	baseURL := "/admin/users/" + userID
	cases := make([]UserModerationCaseView, 0, len(page.ModerationCases))
	for _, item := range page.ModerationCases {
		cases = append(cases, UserModerationCaseView{
			Item:       item,
			ResolveURL: baseURL + "/moderation-cases/" + item.ID.String() + "/resolve",
		})
	}
	restrictions := make([]UserManualRestrictionView, 0, len(page.ActiveRestrictions))
	for _, item := range page.ActiveRestrictions {
		restrictions = append(restrictions, UserManualRestrictionView{
			Item:    item,
			LiftURL: baseURL + "/restrictions/" + item.ID.String() + "/lift",
		})
	}
	return AdminUserDetailViewData{
		User:               page.User,
		Cases:              cases,
		ActiveRestrictions: restrictions,
		CanModerate:        staff != nil && staff.HasPermission(enum.PermissionUsersModerate),
		CanRestrict:        staff != nil && staff.HasPermission(enum.PermissionUsersRestrict),
		CaseActionURL:      baseURL + "/moderation-cases",
		RestrictionURL:     baseURL + "/restrictions",
		PriorityOptions:    []string{"NORMAL", "HIGH", "CRITICAL", "LOW"},
		DecisionOptions:    []string{"NO_ACTION", "INTERNAL_NOTE", "WARNING", "REQUEST_VERIFICATION", "RESTRICT", "SUSPEND", "ESCALATE", "PERMANENT_BLOCK"},
		RestrictionOptions: []string{"CHAT", "ACTIVITY_CREATION", "TOUR_PUBLISHING", "FILE_UPLOAD", "PAYOUT", "GUIDE_APPLICATION", "ACCOUNT_SUSPENSION"},
	}
}

func NewGuideListViewData(items []model.GuideApplicationModerationItem) GuideListViewData {
	return GuideListViewData{
		Items:      items,
		QueueURL:   "/admin/moderation/guides",
		HistoryURL: "/admin/moderation/guides/history",
	}
}

func NewFraudBlockListViewData(target model.FraudBlockTarget, blocks []model.FraudBlock) FraudBlockListViewData {
	target = normalizeFraudBlockViewTarget(target)
	reviewBaseURL := fraudBlockBaseURL(target)
	items := make([]FraudBlockView, 0, len(blocks))
	for _, block := range blocks {
		items = append(items, FraudBlockView{
			Item:          block,
			SubjectText:   fraudBlockSubjectText(block),
			ActorText:     fraudBlockActorText(block),
			ReasonText:    fraudBlockReasonsText(block.Reasons),
			MetadataText:  fraudBlockMetadataText(block.Metadata),
			ReviewBaseURL: reviewBaseURL,
		})
	}
	return FraudBlockListViewData{
		Target:        target,
		Items:         items,
		QueueURL:      fraudBlockQueueURL(target),
		ReviewBaseURL: reviewBaseURL,
		TitleKey:      fraudBlockTitleKey(target),
		EmptyKey:      fraudBlockEmptyKey(target),
	}
}

func NewFeedQualityDashboardViewData(
	page app.FeedQualityDashboardPage,
	filters FeedQualityFilterViewData,
) FeedQualityDashboardViewData {
	filters = normalizeFeedQualityFilterView(filters)
	items := make([]FeedQualityMetricView, 0, len(page.Metrics))
	experimentSummaries := make([]FeedQualityExperimentSummaryView, 0, len(page.ExperimentSummaries))
	showTab := false
	showCommunity := false
	showPostProfile := false
	showRankingExperiment := false
	showCandidateSource := false
	for _, item := range page.Metrics {
		items = append(items, newFeedQualityMetricView(item))
		if strings.TrimSpace(item.Tab) != "" {
			showTab = true
		}
		if strings.TrimSpace(item.CommunityID) != "" {
			showCommunity = true
		}
		if strings.TrimSpace(item.PostProfile) != "" {
			showPostProfile = true
		}
		if strings.TrimSpace(item.RankingExperiment) != "" {
			showRankingExperiment = true
		}
		if strings.TrimSpace(item.CandidateSource) != "" {
			showCandidateSource = true
		}
	}
	for _, item := range page.ExperimentSummaries {
		experimentSummaries = append(experimentSummaries, newFeedQualityExperimentSummaryView(item))
	}
	return FeedQualityDashboardViewData{
		Page:                  page,
		Filters:               filters,
		Items:                 items,
		ExperimentSummaries:   experimentSummaries,
		ShowTab:               showTab,
		ShowCommunity:         showCommunity,
		ShowPostProfile:       showPostProfile,
		ShowRankingExperiment: showRankingExperiment,
		ShowCandidateSource:   showCandidateSource,
		ResetURL:              "/admin/feed-quality",
	}
}

func newFeedQualityExperimentSummaryView(item app.FeedQualityExperimentSummary) FeedQualityExperimentSummaryView {
	return FeedQualityExperimentSummaryView{
		Item:                    item,
		MetricView:              newFeedQualityMetricView(item.Totals),
		Baseline:                item.Baseline,
		ClickRateDeltaText:      signedPercentagePointText(item.ClickRateDeltaBasisPoints, item.Baseline),
		DwellRateDeltaText:      signedPercentagePointText(item.DwellRateDeltaBasisPoints, item.Baseline),
		EngagementRateDeltaText: signedPercentagePointText(item.EngagementRateDeltaBasisPoints, item.Baseline),
		SubscribeRateDeltaText:  signedPercentagePointText(item.SubscribeRateDeltaBasisPoints, item.Baseline),
		ConversionRateDeltaText: signedPercentagePointText(item.ConversionRateDeltaBasisPoints, item.Baseline),
		NegativeRateDeltaText:   signedPercentagePointText(item.NegativeRateDeltaBasisPoints, item.Baseline),
		ReportRateDeltaText:     signedPercentagePointText(item.ReportRateDeltaBasisPoints, item.Baseline),
	}
}

func newFeedQualityMetricView(item model.FeedQualityMetric) FeedQualityMetricView {
	basis := item.EventCount
	qualityRateBasis := item.ImpressionCount
	if qualityRateBasis <= 0 {
		qualityRateBasis = basis
	}
	return FeedQualityMetricView{
		Item:               item,
		NegativeFeedback:   item.NegativeFeedbackCount(),
		Engagement:         item.EngagementCount(),
		ClickRateText:      percentText(item.ClickCount, qualityRateBasis),
		DwellRateText:      percentText(item.DwellCount, qualityRateBasis),
		EngagementRateText: percentText(item.EngagementCount(), qualityRateBasis),
		SubscribeRateText:  percentText(item.SubscribeCount, qualityRateBasis),
		ConversionRateText: percentText(item.ConversionCount, qualityRateBasis),
		NegativeRateText:   percentText(item.NegativeFeedbackCount(), qualityRateBasis),
		ReportRateText:     percentText(item.ReportCount, qualityRateBasis),
	}
}

func normalizeFeedQualityFilterView(filters FeedQualityFilterViewData) FeedQualityFilterViewData {
	filters.Surface = strings.ToLower(strings.TrimSpace(filters.Surface))
	if filters.Surface != "home" && filters.Surface != "content" {
		filters.Surface = ""
	}
	switch strings.ToLower(strings.TrimSpace(filters.Window)) {
	case "24h", "30d":
		filters.Window = strings.ToLower(strings.TrimSpace(filters.Window))
	default:
		filters.Window = "7d"
	}
	values := url.Values{}
	if filters.Surface != "" {
		values.Set("surface", filters.Surface)
	}
	if filters.Window != "" && filters.Window != "7d" {
		values.Set("window", filters.Window)
	}
	filters.Query = values.Encode()
	return filters
}

func percentText(numerator int64, denominator int64) string {
	if denominator <= 0 {
		return "0.0%"
	}
	return fmt.Sprintf("%.1f%%", float64(numerator)*100/float64(denominator))
}

func signedPercentagePointText(deltaBasisPoints int64, baseline bool) string {
	if baseline {
		return "-"
	}
	sign := "+"
	if deltaBasisPoints < 0 {
		sign = "-"
		deltaBasisPoints = -deltaBasisPoints
	}
	return fmt.Sprintf("%s%.1f pp", sign, float64(deltaBasisPoints)/100)
}

func NewCaseDetailViewData(detail *app.ModerationCaseDetail, returnQuery string) CaseDetailViewData {
	returnQuery = strings.TrimSpace(returnQuery)
	queueURL := queueURLWithQuery(queueBaseURL(caseDetailTargetType(detail)), returnQuery)
	return CaseDetailViewData{
		Detail:      detail,
		QueueURL:    queueURL,
		ReturnQuery: returnQuery,
	}
}

func NewAttractionListViewData(items []model.AdminAttraction, total int, filters AttractionFilterViewData) AttractionListViewData {
	return AttractionListViewData{
		Items:      items,
		Total:      total,
		Filters:    filters,
		Pagination: attractionPagination(total, filters),
		Countries:  attractionCountryFilterOptions(filters.CountryCode),
		Cities:     attractionCityFilterOptions(filters.CityID),
	}
}

func NewAttractionFormViewData(item *model.AdminAttraction, input model.AttractionInput, listURL ...string) AttractionFormViewData {
	isEdit := item != nil && item.ID != uuid.Nil
	if isEdit && input.Title == "" {
		input = attractionInputFromItem(item)
	}
	input.CountryCode = strings.ToUpper(strings.TrimSpace(input.CountryCode))
	if input.CountryCode == "" {
		input.CountryCode = "KZ"
	}
	input.DefaultLocale = strings.ToLower(strings.TrimSpace(input.DefaultLocale))
	if input.DefaultLocale == "" {
		input.DefaultLocale = "ru"
	}
	input.Category = strings.ToUpper(strings.TrimSpace(input.Category))
	if input.Category == "" {
		input.Category = "NATURE"
	}
	input.Status = strings.ToUpper(strings.TrimSpace(input.Status))
	if input.Status == "" {
		input.Status = "PUBLISHED"
	}
	backURL := "/admin/attractions"
	if len(listURL) > 0 {
		if candidate := strings.TrimSpace(listURL[0]); candidate != "" {
			backURL = candidate
		}
	}
	actionQuerySuffix := ""
	if _, query, ok := strings.Cut(backURL, "?"); ok && strings.TrimSpace(query) != "" {
		actionQuerySuffix = "?" + query
	}
	submitURL := "/admin/attractions"
	mediaURL := ""
	if isEdit {
		submitURL = "/admin/attractions/" + item.ID.String() + actionQuerySuffix
		mediaURL = "/admin/attractions/" + item.ID.String() + "/media" + actionQuerySuffix
	}
	return AttractionFormViewData{
		Item:                 item,
		Input:                input,
		IsEdit:               isEdit,
		SubmitURL:            submitURL,
		MediaURL:             mediaURL,
		ListURL:              backURL,
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

var communityFormLocales = []string{"ru", "en", "kk"}

func NewCommunityPlatformViewData(
	catalog model.CommunityPlatformCatalog,
	filters CommunityPlatformFilterViewData,
	localeArg ...string,
) CommunityPlatformViewData {
	filters = normalizeCommunityPlatformFilters(filters)
	locale := firstCommunityLocale(localeArg...)
	postProfiles := make([]CommunityPostProfileView, 0, len(catalog.PostProfiles))
	for _, item := range catalog.PostProfiles {
		keyText := communityCodeText(locale, "community.postProfile.", item.Key)
		postKindText := communityCodeText(locale, "community.postKind.", item.PostKind)
		moderationModeText := communityCodeText(locale, "community.moderationMode.", item.ModerationMode)
		activityCreationModeText := communityCodeText(locale, "community.activityCreationMode.", item.ActivityCreationMode)
		postProfiles = append(postProfiles, CommunityPostProfileView{
			Item:                     item,
			KeyText:                  keyText,
			PostKindText:             postKindText,
			ComposerPresetText:       communityCodeText(locale, "community.composerPreset.", item.ComposerPreset),
			RenderPresetText:         communityCodeText(locale, "community.renderPreset.", item.RenderPreset),
			ModerationModeText:       moderationModeText,
			ActivityCreationModeText: activityCreationModeText,
			Meta: strings.Trim(strings.Join([]string{
				postKindText,
				moderationModeText,
				activityCreationModeText,
			}, " · "), " ·"),
		})
	}
	blueprints := make([]CommunityBlueprintView, 0, len(catalog.Blueprints))
	for _, item := range catalog.Blueprints {
		blueprints = append(blueprints, CommunityBlueprintView{
			Item:                      item,
			Title:                     localizedCommunityText(item.TitleI18n, locale),
			Description:               localizedCommunityText(item.DescriptionI18n, locale),
			CategoryText:              communityCodeText(locale, "community.category.", item.Category),
			DefaultPostProfileText:    communityCodeText(locale, "community.postProfile.", item.DefaultPostProfileKey),
			AllowedPostProfilesText:   communityCodeListText(locale, "community.postProfile.", item.AllowedPostProfileKeys),
			EnabledTabsText:           communityCodeListText(locale, "community.tab.", item.EnabledTabs),
			SubcategoriesText:         communityCodeListText(locale, "community.subcategory.", item.SubcategoryKeys),
			PromotionSegmentsText:     communityCodeListText(locale, "community.promotionSegment.", item.PromotionSegmentKeys),
			RolloutPolicyText:         communityCodeText(locale, "community.rolloutPolicy.", item.RolloutPolicy),
			DefaultModerationModeText: communityCodeText(locale, "community.moderationMode.", item.DefaultModerationMode),
			AllowedScopesText:         communityScopeListText(locale, item.AllowedScopeTypes),
		})
	}
	geoHubs := make([]CommunityGeoHubView, 0, len(catalog.GeoHubs))
	for _, item := range catalog.GeoHubs {
		geoHubs = append(geoHubs, CommunityGeoHubView{
			Item:          item,
			LocationText:  communityLocationText(locale, item.CountryCode, item.CityID),
			EffectiveText: communityLocationText(locale, item.EffectiveCountry, item.EffectiveCityID),
			ParentText:    communityOptionalLocationText(locale, item.ParentCountryCode, item.ParentCityID),
			HubTierText:   communityCodeText(locale, "community.hubTier.", item.HubTier),
			ReasonText:    communityCodeText(locale, "community.geoHubReason.", item.Reason),
		})
	}
	instances := make([]CommunityInstanceView, 0, len(catalog.Instances))
	for _, item := range catalog.Instances {
		cityID := ""
		if item.CityID != nil {
			cityID = *item.CityID
		}
		locationText := communityLocationText(locale, item.CountryCode, cityID)
		instances = append(instances, CommunityInstanceView{
			Item:         item,
			Title:        communityInstanceTitleText(localizedCommunityText(item.TitleI18n, locale), locationText),
			LocationText: locationText,
			ScopeText:    communityScopeText(locale, item.ScopeType),
		})
	}
	return CommunityPlatformViewData{
		Catalog:                      catalog,
		Filters:                      filters,
		PostProfiles:                 postProfiles,
		Blueprints:                   blueprints,
		GeoHubs:                      geoHubs,
		Instances:                    instances,
		ScopeOptions:                 communityScopeOptions(filters.ScopeType),
		Countries:                    attractionCountryFilterOptions(filters.CountryCode),
		Cities:                       attractionCityFilterOptions(filters.CityID),
		BlueprintCategoryFilters:     communityBlueprintCategoryFilters(blueprints),
		BlueprintStatusFilters:       communityBlueprintStatusFilters(locale, blueprints),
		GeoHubTierFilters:            communityGeoHubTierFilters(geoHubs),
		GeoHubMaterializationFilters: communityGeoHubMaterializationFilters(locale, geoHubs),
		InstanceScopeFilters:         communityInstanceScopeFilters(instances),
		InstanceStatusFilters:        communityInstanceStatusFilters(locale, instances),
		PostProfileKindFilters:       communityPostProfileKindFilters(postProfiles),
		PostProfileModeFilters:       communityPostProfileModeFilters(postProfiles),
		MaterializeActionURL:         "/admin/communities/materialize",
		CreateCommunityURL:           "/admin/communities/new",
		ResetURL:                     "/admin/communities",
	}
}

func NewCommunityFormViewData(input CommunityFormInput, items ...*model.AdminCommunity) CommunityFormViewData {
	var item *model.AdminCommunity
	if len(items) > 0 {
		item = items[0]
	}
	isEdit := item != nil && item.ID != uuid.Nil
	if isEdit && strings.TrimSpace(input.Slug) == "" {
		input = communityFormInputFromItem(item)
	}
	if isEdit {
		input.ID = item.ID.String()
	}
	input.Slug = strings.TrimSpace(input.Slug)
	input.Topic = strings.ToUpper(strings.TrimSpace(input.Topic))
	if input.Topic == "" {
		input.Topic = "GENERAL"
	}
	input.CountryCode = strings.ToUpper(strings.TrimSpace(input.CountryCode))
	input.Visibility = strings.ToUpper(strings.TrimSpace(input.Visibility))
	if input.Visibility == "" {
		input.Visibility = "PUBLIC"
	}
	input.PostingPolicy = strings.ToUpper(strings.TrimSpace(input.PostingPolicy))
	if input.PostingPolicy == "" {
		input.PostingPolicy = "MEMBERS_AFTER_MODERATION"
	}
	input.Status = strings.ToUpper(strings.TrimSpace(input.Status))
	if input.Status == "" {
		input.Status = "ACTIVE"
	}
	input.TitleI18n = normalizeCommunityFormTextMap(input.TitleI18n)
	input.DescriptionI18n = normalizeCommunityFormTextMap(input.DescriptionI18n)
	input.RulesTextI18n = normalizeCommunityFormTextMap(input.RulesTextI18n)
	submitURL := "/admin/communities"
	if isEdit {
		submitURL = "/admin/communities/" + item.ID.String()
	}
	return CommunityFormViewData{
		Input:           input,
		Item:            item,
		IsEdit:          isEdit,
		SubmitURL:       submitURL,
		Locales:         communityLocaleOptions(),
		SlugOptions:     communitySlugOptions(input.Slug),
		Topics:          communityOptionViews(input.Topic, communityTopicOptions()),
		Visibilities:    communityOptionViews(input.Visibility, map[string]string{"PUBLIC": "community.visibility.PUBLIC", "HIDDEN": "community.visibility.HIDDEN", "INVITE_ONLY": "community.visibility.INVITE_ONLY"}),
		PostingPolicies: communityOptionViews(input.PostingPolicy, map[string]string{"ADMINS_ONLY": "community.postingPolicy.ADMINS_ONLY", "MEMBERS_AFTER_MODERATION": "community.postingPolicy.MEMBERS_AFTER_MODERATION", "TRUSTED_MEMBERS": "community.postingPolicy.TRUSTED_MEMBERS", "OPEN_MEMBERS": "community.postingPolicy.OPEN_MEMBERS"}),
		Statuses:        communityOptionViews(input.Status, map[string]string{"ACTIVE": "community.status.ACTIVE", "ARCHIVED": "community.status.ARCHIVED", "HIDDEN": "community.status.HIDDEN"}),
		Countries:       attractionCountryFilterOptions(input.CountryCode),
		Cities:          attractionCityFilterOptions(input.CityID),
	}
}

func communityFormInputFromItem(item *model.AdminCommunity) CommunityFormInput {
	if item == nil {
		return CommunityFormInput{}
	}
	cityID := ""
	if item.CityID != nil {
		cityID = *item.CityID
	}
	countryCode := ""
	if item.CountryCode != nil {
		countryCode = *item.CountryCode
	}
	avatarFileID := ""
	if item.AvatarFileID != nil {
		avatarFileID = item.AvatarFileID.String()
	}
	coverFileID := ""
	if item.CoverFileID != nil {
		coverFileID = item.CoverFileID.String()
	}
	return CommunityFormInput{
		ID:              item.ID.String(),
		Slug:            item.Slug,
		TitleI18n:       cloneStringMap(item.TitleI18n),
		DescriptionI18n: cloneStringMap(item.DescriptionI18n),
		RulesTextI18n:   communityRulesTextMap(item.RulesI18n),
		Topic:           item.Topic,
		CityID:          cityID,
		CountryCode:     countryCode,
		AvatarFileID:    avatarFileID,
		CoverFileID:     coverFileID,
		Visibility:      item.Visibility,
		PostingPolicy:   item.PostingPolicy,
		Status:          item.Status,
	}
}

func communityRulesTextMap(input map[string][]string) map[string]string {
	out := make(map[string]string, len(communityFormLocales))
	for _, locale := range communityFormLocales {
		out[locale] = strings.Join(input[locale], "\n")
	}
	return out
}

func cloneStringMap(input map[string]string) map[string]string {
	out := make(map[string]string, len(input))
	for key, value := range input {
		out[key] = value
	}
	return out
}

func communitySlugOptions(selected string) []AttractionOptionView {
	templates := []string{
		"general",
		"city-guides",
		"news",
		"real-estate",
		"transport",
		"sports",
		"events",
		"pets",
	}
	selected = strings.TrimSpace(selected)
	values := make([]string, 0, len(templates)+1)
	if selected != "" {
		values = append(values, selected)
	}
	for _, value := range templates {
		if value != selected {
			values = append(values, value)
		}
	}
	out := make([]AttractionOptionView, 0, len(values))
	for _, value := range values {
		out = append(out, AttractionOptionView{
			Value:    value,
			LabelKey: value,
			Selected: value == selected,
		})
	}
	return out
}

func normalizeCommunityFormTextMap(input map[string]string) map[string]string {
	out := make(map[string]string, len(communityFormLocales))
	for _, locale := range communityFormLocales {
		out[locale] = strings.TrimSpace(input[locale])
	}
	return out
}

func normalizeCommunityPlatformFilters(filters CommunityPlatformFilterViewData) CommunityPlatformFilterViewData {
	filters.CountryCode = strings.ToUpper(strings.TrimSpace(filters.CountryCode))
	filters.CityID = strings.TrimSpace(filters.CityID)
	filters.ScopeType = strings.ToUpper(strings.TrimSpace(filters.ScopeType))
	if filters.ScopeType != "CITY" && filters.ScopeType != "GLOBAL" {
		filters.ScopeType = ""
	}
	filters.Search = strings.TrimSpace(filters.Search)
	if filters.Limit <= 0 {
		filters.Limit = 50
	}
	if filters.Limit > maxCommunityPlatformPageSize {
		filters.Limit = maxCommunityPlatformPageSize
	}
	if filters.Offset < 0 {
		filters.Offset = 0
	}
	values := url.Values{}
	if filters.CountryCode != "" {
		values.Set("country_code", filters.CountryCode)
	}
	if filters.CityID != "" {
		values.Set("city_id", filters.CityID)
	}
	if filters.ScopeType != "" {
		values.Set("scope_type", filters.ScopeType)
	}
	if filters.Search != "" {
		values.Set("q", filters.Search)
	}
	if filters.Limit != 50 {
		values.Set("limit", strconv.Itoa(filters.Limit))
	}
	if filters.Offset > 0 {
		values.Set("offset", strconv.Itoa(filters.Offset))
	}
	filters.Query = values.Encode()
	return filters
}

func communityScopeOptions(selected string) []AttractionOptionView {
	return communityOptionViews(selected, map[string]string{
		"":       "community.scope.all",
		"CITY":   "community.scope.CITY",
		"GLOBAL": "community.scope.GLOBAL",
	})
}

func firstCommunityLocale(values ...string) string {
	for _, value := range values {
		value = strings.ToLower(strings.TrimSpace(value))
		if value != "" {
			return value
		}
	}
	return defaultLocale
}

func localizedCommunityText(values map[string]string, preferredLocale string) string {
	preferredLocale = strings.ToLower(strings.TrimSpace(preferredLocale))
	for _, locale := range []string{preferredLocale, "ru", "en", "kk"} {
		if value := strings.TrimSpace(values[locale]); value != "" {
			return value
		}
	}
	return ""
}

func communityLocationText(locale string, countryCode string, cityID string) string {
	countryCode = strings.ToUpper(strings.TrimSpace(countryCode))
	cityID = strings.TrimSpace(cityID)
	switch {
	case countryCode != "" && cityID != "":
		return countryText(locale, countryCode) + " · " + attractionCityNameText(locale, cityID)
	case countryCode != "":
		return countryText(locale, countryCode)
	case cityID != "":
		return attractionCityNameText(locale, cityID)
	default:
		return "-"
	}
}

func communityOptionalLocationText(locale string, countryCode *string, cityID *string) string {
	country := ""
	if countryCode != nil {
		country = *countryCode
	}
	city := ""
	if cityID != nil {
		city = *cityID
	}
	return communityLocationText(locale, country, city)
}

func communityCodeText(locale string, prefix string, raw string) string {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return "-"
	}
	if value := translate(locale, prefix+raw); value != prefix+raw {
		return value
	}
	return humanizeCode(raw)
}

func communityScopeText(locale string, raw string) string {
	raw = strings.ToUpper(strings.TrimSpace(raw))
	if raw == "" {
		return "-"
	}
	return communityCodeText(locale, "community.scope.", raw)
}

func communityCodeListText(locale string, prefix string, values []string) string {
	out := make([]string, 0, len(values))
	for _, value := range values {
		text := communityCodeText(locale, prefix, value)
		if text != "-" {
			out = append(out, text)
		}
	}
	if len(out) == 0 {
		return "-"
	}
	return strings.Join(out, ", ")
}

func communityScopeListText(locale string, values []string) string {
	out := make([]string, 0, len(values))
	for _, value := range values {
		text := communityScopeText(locale, value)
		if text != "-" {
			out = append(out, text)
		}
	}
	if len(out) == 0 {
		return "-"
	}
	return strings.Join(out, ", ")
}

func communityInstanceTitleText(title string, locationText string) string {
	title = strings.TrimSpace(title)
	if title == "" {
		return "-"
	}
	parts := strings.Split(title, "·")
	if len(parts) > 1 {
		if first := strings.TrimSpace(parts[0]); first != "" {
			return first
		}
	}
	return strings.TrimSpace(strings.TrimSuffix(title, strings.TrimSpace(locationText)))
}

func communityBlueprintCategoryFilters(items []CommunityBlueprintView) []CommunityTableFilterOption {
	return communityFilterOptions(func(add func(string, string)) {
		for _, item := range items {
			add(item.Item.Category, item.CategoryText)
		}
	})
}

func communityBlueprintStatusFilters(locale string, items []CommunityBlueprintView) []CommunityTableFilterOption {
	return communityFilterOptions(func(add func(string, string)) {
		for _, item := range items {
			add(item.Item.Status, translateStatus(locale, item.Item.Status))
		}
	})
}

func communityGeoHubTierFilters(items []CommunityGeoHubView) []CommunityTableFilterOption {
	return communityFilterOptions(func(add func(string, string)) {
		for _, item := range items {
			add(item.Item.HubTier, item.HubTierText)
		}
	})
}

func communityGeoHubMaterializationFilters(locale string, items []CommunityGeoHubView) []CommunityTableFilterOption {
	return communityFilterOptions(func(add func(string, string)) {
		for _, item := range items {
			if item.Item.CanMaterialize {
				add("can_materialize", translate(locale, "community.canMaterialize"))
			} else {
				add("alias_only", translate(locale, "community.aliasOnly"))
			}
		}
	})
}

func communityInstanceScopeFilters(items []CommunityInstanceView) []CommunityTableFilterOption {
	return communityFilterOptions(func(add func(string, string)) {
		for _, item := range items {
			add(item.Item.ScopeType, item.ScopeText)
		}
	})
}

func communityInstanceStatusFilters(locale string, items []CommunityInstanceView) []CommunityTableFilterOption {
	return communityFilterOptions(func(add func(string, string)) {
		for _, item := range items {
			add(item.Item.Status, translateStatus(locale, item.Item.Status))
		}
	})
}

func communityPostProfileKindFilters(items []CommunityPostProfileView) []CommunityTableFilterOption {
	return communityFilterOptions(func(add func(string, string)) {
		for _, item := range items {
			add(item.Item.PostKind, item.PostKindText)
		}
	})
}

func communityPostProfileModeFilters(items []CommunityPostProfileView) []CommunityTableFilterOption {
	return communityFilterOptions(func(add func(string, string)) {
		for _, item := range items {
			add(item.Item.ModerationMode, item.ModerationModeText)
		}
	})
}

func communityFilterOptions(collect func(func(string, string))) []CommunityTableFilterOption {
	seen := make(map[string]string)
	collect(func(value string, text string) {
		value = strings.TrimSpace(value)
		text = strings.TrimSpace(text)
		if value == "" || text == "" || text == "-" {
			return
		}
		if _, ok := seen[value]; !ok {
			seen[value] = text
		}
	})
	values := make([]string, 0, len(seen))
	for value := range seen {
		values = append(values, value)
	}
	sort.Slice(values, func(i, j int) bool {
		return strings.ToLower(seen[values[i]]) < strings.ToLower(seen[values[j]])
	})
	out := make([]CommunityTableFilterOption, 0, len(values))
	for _, value := range values {
		out = append(out, CommunityTableFilterOption{Value: value, Text: seen[value]})
	}
	return out
}

func humanizeCode(raw string) string {
	value := strings.TrimSpace(raw)
	if value == "" {
		return "-"
	}
	value = strings.NewReplacer("_", " ", "-", " ").Replace(value)
	words := strings.Fields(strings.ToLower(value))
	for i, word := range words {
		if word == "" {
			continue
		}
		words[i] = strings.ToUpper(word[:1]) + word[1:]
	}
	if len(words) == 0 {
		return raw
	}
	return strings.Join(words, " ")
}

func communityLocaleOptions() []AttractionOptionView {
	return []AttractionOptionView{
		{Value: "ru", LabelKey: "attraction.locale.ru"},
		{Value: "en", LabelKey: "attraction.locale.en"},
		{Value: "kk", LabelKey: "attraction.locale.kk"},
	}
}

func communityTopicOptions() map[string]string {
	return map[string]string{
		"GENERAL":  "community.topic.GENERAL",
		"TRAVEL":   "community.topic.TRAVEL",
		"CITY":     "community.topic.CITY",
		"GUIDES":   "community.topic.GUIDES",
		"APP_NEWS": "community.topic.APP_NEWS",
	}
}

func communityOptionViews(selected string, labels map[string]string) []AttractionOptionView {
	order := make([]string, 0, len(labels))
	for value := range labels {
		order = append(order, value)
	}
	sort.Strings(order)
	out := make([]AttractionOptionView, 0, len(order))
	for _, value := range order {
		out = append(out, AttractionOptionView{
			Value:    value,
			LabelKey: labels[value],
			Selected: strings.EqualFold(selected, value),
		})
	}
	return out
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
	case "fraud_assessment":
		return translate(locale, "audit.entity.fraudAssessment")
	case "trust_restriction_appeal":
		return translate(locale, "audit.entity.trustRestrictionAppeal")
	case "user":
		if event.EntityID != nil {
			return fmt.Sprintf("%s %s", translate(locale, "audit.entity.user"), shortTemplateID(event.EntityID))
		}
		return translate(locale, "audit.entity.user")
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
	case "fraud.block.confirmed", "fraud.block.false_positive", "fraud.block.escalated", "fraud.block.review_failed":
		if status := auditMetadataValue(event.Metadata, "status"); status != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.fraudReviewStatus"), translateStatus(locale, status)))
		}
		if decision := auditMetadataValue(event.Metadata, "decision"); decision != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.fraudDecision"), translateStatus(locale, decision)))
		}
		if riskScore := auditMetadataValue(event.Metadata, "riskScore"); riskScore != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.fraudRiskScore"), riskScore))
		}
		if value := auditMetadataValue(event.Metadata, "error"); value != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.error"), value))
		}
	case "user.detail.viewed":
		details = append(details, translate(locale, "audit.detail.userViewed"))
	case "user_moderation.case.created", "user_moderation.case.resolved", "user_moderation.restriction.created", "user_moderation.restriction.lifted":
		if reason := auditMetadataValue(event.Metadata, "reasonCode"); reason != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.reason"), reason))
		}
		if decision := auditMetadataValue(event.Metadata, "decision"); decision != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.moderationDecision"), translateStatus(locale, decision)))
		}
	case "trust.appeal.viewed", "trust.appeal.decided", "trust.appeal.decision_failed":
		if reason := auditMetadataValue(event.Metadata, "reasonCode"); reason != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.reason"), reason))
		}
		if decision := auditMetadataValue(event.Metadata, "decision"); decision != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.moderationDecision"), translateStatus(locale, decision)))
		}
		if value := auditMetadataValue(event.Metadata, "error"); value != "" {
			details = append(details, fmt.Sprintf(translate(locale, "audit.detail.error"), value))
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
	case model.ModerationTargetPost:
		return translate(locale, "moderation.post")
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

func normalizeAdminUsersFilter(filters AdminUsersFilterViewData) AdminUsersFilterViewData {
	filters.Search = strings.TrimSpace(filters.Search)
	filters.Status = strings.ToUpper(strings.TrimSpace(filters.Status))
	filters.Role = strings.ToUpper(strings.TrimSpace(filters.Role))
	filters.CountryCode = strings.ToUpper(strings.TrimSpace(filters.CountryCode))
	filters.PageToken = strings.TrimSpace(filters.PageToken)
	if filters.PageSize <= 0 {
		filters.PageSize = 50
	}
	filters.Query = adminUsersQuery(filters)
	return filters
}

func adminUsersListURL(filters AdminUsersFilterViewData) string {
	query := adminUsersQuery(filters)
	if query == "" {
		return "/admin/users"
	}
	return "/admin/users?" + query
}

func adminUsersQuery(filters AdminUsersFilterViewData) string {
	values := url.Values{}
	if filters.Search != "" {
		values.Set("q", filters.Search)
	}
	if filters.Status != "" {
		values.Set("status", filters.Status)
	}
	if filters.Role != "" {
		values.Set("role", filters.Role)
	}
	if filters.CountryCode != "" {
		values.Set("country", filters.CountryCode)
	}
	if filters.PageToken != "" {
		values.Set("page_token", filters.PageToken)
	}
	if filters.PageSize > 0 && filters.PageSize != 50 {
		values.Set("page_size", strconv.Itoa(filters.PageSize))
	}
	return values.Encode()
}

func adminUserRoleFilterOptions(selected string) []AttractionOptionView {
	selected = strings.ToUpper(strings.TrimSpace(selected))
	values := []string{"USER", "GUIDE", "ADMIN", "MODERATOR", "SUPPORT"}
	out := make([]AttractionOptionView, 0, len(values)+1)
	var found bool
	for _, value := range values {
		option := AttractionOptionView{
			Value:    value,
			LabelKey: value,
			Selected: selected == value,
		}
		if option.Selected {
			found = true
		}
		out = append(out, option)
	}
	if selected != "" && !found {
		out = append(out, AttractionOptionView{
			Value:    selected,
			LabelKey: selected,
			Selected: true,
		})
	}
	return out
}

func adminUserTrustText(band string, score *int) string {
	band = strings.TrimSpace(band)
	if score == nil {
		if band == "" {
			return "-"
		}
		return band
	}
	if band == "" {
		return strconv.Itoa(*score)
	}
	return fmt.Sprintf("%s · %d", band, *score)
}

func normalizeTrustAppealFilter(filters TrustAppealFilterViewData) TrustAppealFilterViewData {
	filters.Search = strings.TrimSpace(filters.Search)
	filters.Status = strings.ToUpper(strings.TrimSpace(filters.Status))
	switch model.TrustRestrictionAppealStatus(filters.Status) {
	case model.TrustRestrictionAppealStatusApproved,
		model.TrustRestrictionAppealStatusRejected:
	default:
		filters.Status = string(model.TrustRestrictionAppealStatusOpen)
	}
	filters.PageToken = strings.TrimSpace(filters.PageToken)
	if filters.PageSize <= 0 {
		filters.PageSize = 50
	}
	filters.Query = trustAppealQuery(filters)
	return filters
}

func trustAppealListURL(filters TrustAppealFilterViewData) string {
	query := trustAppealQuery(filters)
	if query == "" {
		return "/admin/trust/appeals"
	}
	return "/admin/trust/appeals?" + query
}

func trustAppealDetailURL(id uuid.UUID, returnQuery string) string {
	base := "/admin/trust/appeals/" + id.String()
	if strings.TrimSpace(returnQuery) == "" {
		return base
	}
	return base + "?" + strings.TrimSpace(returnQuery)
}

func trustAppealDecisionURL(id uuid.UUID, action string, returnQuery string) string {
	base := "/admin/trust/appeals/" + id.String() + "/" + action
	if strings.TrimSpace(returnQuery) == "" {
		return base
	}
	return base + "?" + strings.TrimSpace(returnQuery)
}

func trustAppealQuery(filters TrustAppealFilterViewData) string {
	values := url.Values{}
	if filters.Search != "" {
		values.Set("q", filters.Search)
	}
	if filters.Status != "" && filters.Status != string(model.TrustRestrictionAppealStatusOpen) {
		values.Set("status", filters.Status)
	}
	if filters.PageToken != "" {
		values.Set("page_token", filters.PageToken)
	}
	if filters.PageSize > 0 && filters.PageSize != 50 {
		values.Set("page_size", strconv.Itoa(filters.PageSize))
	}
	return values.Encode()
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

func NewPostReportQueueViewData(cases []*model.ModerationCase, filters ...QueueFilterViewData) QueueViewData {
	return newQueueViewData(cases, model.ModerationTargetPost, filters...)
}

func newQueueViewData(cases []*model.ModerationCase, targetType model.ModerationTargetType, filters ...QueueFilterViewData) QueueViewData {
	viewFilters := QueueFilterViewData{Status: excursionQueueStatusActive}
	if len(filters) > 0 {
		viewFilters = filters[0]
	}
	items := make([]ModerationQueueItemView, 0, len(cases))
	for _, item := range cases {
		if item == nil {
			continue
		}
		excursion := excursionFromSnapshot(item)
		activity := activityFromSnapshot(item)
		guideApplication := guideApplicationFromSnapshot(item)
		chatMessage := chatMessageFromSnapshot(item)
		post := storyFromSnapshot(item)
		postReport := postReportFromSnapshot(item)
		view := ModerationQueueItemView{
			Case:             item,
			Excursion:        excursion,
			Activity:         activity,
			GuideApplication: guideApplication,
			ChatMessage:      chatMessage,
			Post:             post,
			PostReport:       postReport,
		}
		view.TargetTitle = queueTargetTitle(item, excursion, activity, guideApplication, chatMessage, post, postReport)
		view.TargetSubtitle = queueTargetSubtitle(excursion, activity, guideApplication, chatMessage, post, postReport)
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
		} else if post != nil {
			view.GuideName = "Author " + shortString(post.AuthorUserID.String())
			view.GuideFullName = strings.TrimSpace(post.Category)
		} else if postReport != nil {
			view.GuideName = "Reporter " + shortString(postReport.ReporterUserID.String())
			view.GuideFullName = "Author " + shortString(postReport.AuthorUserID.String())
		}
		if view.GuideName == "" {
			view.GuideName = "-"
		}
		view.DetailURL = queueURLWithQuery(queueDetailBaseURL(targetType)+"/"+item.ID.String(), viewFilters.Query)
		items = append(items, view)
	}
	data := QueueViewData{
		Items:                items,
		Filters:              viewFilters,
		FilterAction:         queueBaseURL(targetType),
		ResetURL:             queueBaseURL(targetType),
		OpenQueueURL:         queueBaseURL(targetType),
		HistoryURL:           queueBaseURL(targetType) + "/history",
		FraudBlocksURL:       queueFraudBlocksURL(targetType),
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
		Countries:            attractionCountryFilterOptions(viewFilters.CountryCode),
		Cities:               attractionCityFilterOptions(viewFilters.CityID),
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

func NewPostReportHistoryViewData(cases []*model.ModerationCase, filters QueueFilterViewData) QueueViewData {
	data := NewPostReportQueueViewData(cases, filters)
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

func postReportFromSnapshot(item *model.ModerationCase) *model.PostReportModerationItem {
	if moderationCaseKind(item) == "community_post" {
		return nil
	}
	if item == nil || item.TargetType != model.ModerationTargetPost || len(item.Snapshot) == 0 {
		return nil
	}
	var postReport model.PostReportModerationItem
	if err := json.Unmarshal(item.Snapshot, &postReport); err != nil {
		return nil
	}
	if postReport.ID.String() == "00000000-0000-0000-0000-000000000000" {
		postReport.ID = item.TargetID
	}
	return &postReport
}

func moderationCaseKind(item *model.ModerationCase) string {
	if item == nil || len(item.Metadata) == 0 {
		return "post_report"
	}
	var metadata map[string]string
	if err := json.Unmarshal(item.Metadata, &metadata); err != nil {
		return "post_report"
	}
	kind := strings.TrimSpace(metadata["moderationKind"])
	if kind == "" {
		return "post_report"
	}
	return kind
}

func storyFromSnapshot(item *model.ModerationCase) *model.PostModerationItem {
	if moderationCaseKind(item) != "community_post" {
		return nil
	}
	if item == nil || item.TargetType != model.ModerationTargetPost || len(item.Snapshot) == 0 {
		return nil
	}
	var post model.PostModerationItem
	if err := json.Unmarshal(item.Snapshot, &post); err != nil {
		return nil
	}
	if post.ID.String() == "00000000-0000-0000-0000-000000000000" {
		post.ID = item.TargetID
	}
	return &post
}

func queueTargetTitle(item *model.ModerationCase, excursion *model.ExcursionModerationItem, activity *model.ActivityModerationItem, guideApplication *model.GuideApplicationModerationItem, chatMessage *model.ChatMessageModerationItem, post *model.PostModerationItem, postReport *model.PostReportModerationItem) string {
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
	if post != nil {
		title := strings.TrimSpace(post.Title)
		if title == "" {
			title = "Community post"
		}
		return title
	}
	if postReport != nil {
		reason := strings.TrimSpace(postReport.Reason)
		if reason == "" {
			reason = "REPORT"
		}
		return "Post report: " + reason
	}
	if item == nil {
		return "-"
	}
	return string(item.TargetType) + " " + shortString(item.TargetID.String())
}

func queueTargetSubtitle(excursion *model.ExcursionModerationItem, activity *model.ActivityModerationItem, guideApplication *model.GuideApplicationModerationItem, chatMessage *model.ChatMessageModerationItem, post *model.PostModerationItem, postReport *model.PostReportModerationItem) string {
	if excursion == nil {
		if activity == nil {
			if guideApplication == nil {
				if chatMessage == nil {
					if post != nil {
						return strings.TrimSpace(post.Excerpt)
					}
					if postReport != nil {
						return strings.TrimSpace(postReport.Details)
					}
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
	if targetType == model.ModerationTargetPost {
		return "/admin/moderation/posts"
	}
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

func queueFraudBlocksURL(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetChatMessage || targetType == model.ModerationTargetPost {
		return ""
	}
	return queueBaseURL(targetType) + "/fraud-blocks"
}

func queueURLWithQuery(path string, query string) string {
	query = strings.TrimSpace(query)
	if query == "" {
		return path
	}
	if strings.Contains(path, "?") {
		return path + "&" + query
	}
	return path + "?" + query
}

func caseDetailTargetType(detail *app.ModerationCaseDetail) model.ModerationTargetType {
	if detail == nil {
		return model.ModerationTargetExcursion
	}
	if detail.Case != nil {
		return detail.Case.TargetType
	}
	if detail.Post != nil {
		return model.ModerationTargetPost
	}
	if detail.PostReport != nil {
		return model.ModerationTargetPost
	}
	if detail.ChatMessage != nil {
		return model.ModerationTargetChatMessage
	}
	if detail.Activity != nil {
		return model.ModerationTargetActivity
	}
	if detail.GuideApplication != nil {
		return model.ModerationTargetGuideApplication
	}
	return model.ModerationTargetExcursion
}

func queueDetailBaseURL(targetType model.ModerationTargetType) string {
	return queueBaseURL(targetType)
}

func queueTitleKey(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetPost {
		return "moderation.postReportQueue"
	}
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
	if targetType == model.ModerationTargetPost {
		return "moderation.postReportHistory"
	}
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
	if targetType == model.ModerationTargetPost {
		return "moderation.noPostReportCases"
	}
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
	if targetType == model.ModerationTargetPost {
		return "moderation.noPostReportHistory"
	}
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
	if targetType == model.ModerationTargetPost {
		return "table.postReport"
	}
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
	if targetType == model.ModerationTargetPost {
		return "table.reporter"
	}
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
	if targetType == model.ModerationTargetPost {
		return "table.community"
	}
	if targetType == model.ModerationTargetChatMessage {
		return "table.conversation"
	}
	return "table.city"
}

func queueSearchPlaceholderKey(targetType model.ModerationTargetType) string {
	if targetType == model.ModerationTargetPost {
		return "placeholder.searchPostReports"
	}
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

func normalizeFraudBlockViewTarget(target model.FraudBlockTarget) model.FraudBlockTarget {
	switch target {
	case model.FraudBlockTargetActivity, model.FraudBlockTargetGuideApplication:
		return target
	default:
		return model.FraudBlockTargetExcursion
	}
}

func fraudBlockBaseURL(target model.FraudBlockTarget) string {
	return fraudBlockQueueURL(target) + "/fraud-blocks"
}

func fraudBlockQueueURL(target model.FraudBlockTarget) string {
	switch normalizeFraudBlockViewTarget(target) {
	case model.FraudBlockTargetActivity:
		return "/admin/moderation/activities"
	case model.FraudBlockTargetGuideApplication:
		return "/admin/moderation/guides"
	default:
		return "/admin/moderation/excursions"
	}
}

func fraudBlockTitleKey(target model.FraudBlockTarget) string {
	switch normalizeFraudBlockViewTarget(target) {
	case model.FraudBlockTargetActivity:
		return "fraud.activityBlocks"
	case model.FraudBlockTargetGuideApplication:
		return "fraud.guideBlocks"
	default:
		return "fraud.excursionBlocks"
	}
}

func fraudBlockEmptyKey(target model.FraudBlockTarget) string {
	switch normalizeFraudBlockViewTarget(target) {
	case model.FraudBlockTargetActivity:
		return "fraud.noActivityBlocks"
	case model.FraudBlockTargetGuideApplication:
		return "fraud.noGuideBlocks"
	default:
		return "fraud.noExcursionBlocks"
	}
}

func fraudBlockSubjectText(block model.FraudBlock) string {
	if block.SubjectID == nil {
		return strings.TrimSpace(block.SubjectType)
	}
	subjectType := strings.TrimSpace(block.SubjectType)
	if subjectType == "" {
		subjectType = "subject"
	}
	return fmt.Sprintf("%s %s", subjectType, shortString(block.SubjectID.String()))
}

func fraudBlockActorText(block model.FraudBlock) string {
	if block.ActorUserID == nil {
		return "-"
	}
	return shortString(block.ActorUserID.String())
}

func fraudBlockReasonsText(reasons []string) string {
	clean := make([]string, 0, len(reasons))
	for _, reason := range reasons {
		reason = strings.TrimSpace(reason)
		if reason != "" {
			clean = append(clean, reason)
		}
	}
	if len(clean) == 0 {
		return "-"
	}
	return strings.Join(clean, ", ")
}

func fraudBlockMetadataText(metadata map[string]any) string {
	if len(metadata) == 0 {
		return ""
	}
	keys := make([]string, 0, len(metadata))
	for key := range metadata {
		if strings.TrimSpace(key) != "" {
			keys = append(keys, key)
		}
	}
	sort.Strings(keys)
	parts := make([]string, 0, len(keys))
	for _, key := range keys {
		value := strings.TrimSpace(fmt.Sprint(metadata[key]))
		if value != "" {
			parts = append(parts, fmt.Sprintf("%s=%s", key, value))
		}
	}
	return strings.Join(parts, ", ")
}
