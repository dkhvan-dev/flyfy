package http

import (
	"encoding/json"
	"fmt"
	"net/url"
	"strings"
	"time"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

const (
	OperationsTabDomain       = "domain"
	OperationsTabFeatureFlags = "feature-flags"
	OperationsTabTechBreaks   = "tech-breaks"
	OperationsTabScopes       = "scopes"
)

type OperationsDomainFilterViewData struct {
	Search string
	Page   int
	Size   int
	Query  string
}

type OperationsResourceFilterViewData struct {
	Search          string
	Group           string
	ActionStartDate *time.Time
	ActionEndDate   *time.Time
	InArchive       bool
	Page            int
	Size            int
	Query           string
}

type OperationsHistoryPaginationFilterViewData struct {
	Page   int
	Size   int
	Cursor string
}

type OperationsDomainListViewData struct {
	Domains  []model.OperationDomain
	Filters  OperationsDomainFilterViewData
	Page     model.OperationDomainPage
	ResetURL string
}

type OperationsDomainDetailViewData struct {
	Domain            model.OperationDomain
	ActiveTab         string
	Tabs              []OperationsTabViewData
	Filters           OperationsResourceFilterViewData
	FeatureFlags      model.OperationPage[model.OperationFeatureFlag]
	TechBreaks        model.OperationPage[model.OperationTechBreak]
	Scopes            []model.OperationTechBreakScope
	DomainActionURL   string
	FeatureFlagNewURL string
	TechBreakNewURL   string
	ScopeNewURL       string
	BackURL           string
}

type OperationsTabViewData struct {
	Key    string
	Label  string
	URL    string
	Active bool
}

type OperationsFeatureFlagFormViewData struct {
	Domain      model.OperationDomain
	Flag        model.OperationFeatureFlag
	IsNew       bool
	ActiveTab   string
	SubmitURL   string
	DeleteURL   string
	RecoverURL  string
	BackURL     string
	HistoryURL  string
	TypeOptions []string
	ValueRows   []string
}

type OperationsFeatureFlagHistoryViewData struct {
	Domain     model.OperationDomain
	Flag       model.OperationFeatureFlag
	History    model.OperationPage[model.OperationFeatureFlagHistory]
	BackURL    string
	DetailURL  string
	Pagination OperationsHistoryPaginationViewData
}

type OperationsHistoryPaginationViewData struct {
	TotalPages       int
	CurrentPageLabel int
	HasPrevious      bool
	PreviousURL      string
	HasNext          bool
	NextURL          string
}

type OperationsTechBreakFormViewData struct {
	Domain        model.OperationDomain
	Break         model.OperationTechBreak
	Scopes        []model.OperationTechBreakScope
	IsNew         bool
	SubmitURL     string
	DeleteURL     string
	BackURL       string
	EmailsText    string
	NicknamesText string
}

type OperationsScopeFormViewData struct {
	Domain    model.OperationDomain
	Scope     model.OperationTechBreakScope
	IsNew     bool
	SubmitURL string
	DeleteURL string
	BackURL   string
}

func NewOperationsDomainListViewData(page model.OperationDomainPage, filters OperationsDomainFilterViewData) OperationsDomainListViewData {
	filters = normalizeOperationsDomainFilterViewData(filters)
	return OperationsDomainListViewData{
		Domains:  page.Content,
		Filters:  filters,
		Page:     page,
		ResetURL: "/admin/operations",
	}
}

func NewOperationsDomainDetailViewData(
	page app.OperationsDomainDetailPage,
	activeTab string,
	filters OperationsResourceFilterViewData,
) OperationsDomainDetailViewData {
	activeTab = normalizeOperationsTab(activeTab)
	filters = normalizeOperationsResourceFilterViewData(filters)
	baseURL := operationsDomainURL(page.Domain.Code)
	scopes := page.Scopes
	if activeTab == OperationsTabScopes {
		scopes = filterOperationScopes(scopes, filters.Search)
	}
	return OperationsDomainDetailViewData{
		Domain:            page.Domain,
		ActiveTab:         activeTab,
		Tabs:              operationsTabs(baseURL, activeTab),
		Filters:           filters,
		FeatureFlags:      page.FeatureFlags,
		TechBreaks:        page.TechBreaks,
		Scopes:            scopes,
		DomainActionURL:   baseURL,
		FeatureFlagNewURL: baseURL + "/feature-flags/new",
		TechBreakNewURL:   baseURL + "/tech-breaks/new",
		ScopeNewURL:       baseURL + "/scopes/new",
		BackURL:           "/admin/operations",
	}
}

func NewOperationsFeatureFlagFormViewData(
	page app.OperationsFeatureFlagDetailPage,
	isNew bool,
) OperationsFeatureFlagFormViewData {
	domainCode := firstNonEmpty(page.Domain.Code, page.Flag.DomainCode)
	baseURL := operationsDomainURL(domainCode)
	flagCode := strings.ToUpper(strings.TrimSpace(page.Flag.Code))
	submitURL := baseURL + "/feature-flags"
	deleteURL := ""
	recoverURL := ""
	if !isNew {
		submitURL += "/" + url.PathEscape(flagCode)
		deleteURL = submitURL + "/archive"
		recoverURL = submitURL + "/recover"
	}
	return OperationsFeatureFlagFormViewData{
		Domain:      page.Domain,
		Flag:        page.Flag,
		IsNew:       isNew,
		ActiveTab:   OperationsTabFeatureFlags,
		SubmitURL:   submitURL,
		DeleteURL:   deleteURL,
		RecoverURL:  recoverURL,
		BackURL:     baseURL + "?tab=" + OperationsTabFeatureFlags,
		HistoryURL:  operationFeatureFlagHistoryURL(domainCode, flagCode),
		TypeOptions: []string{"TOGGLE", "ARRAY_STRING", "ARRAY_INTEGER"},
		ValueRows:   operationValueRows(page.Flag.Type, page.Flag.Value),
	}
}

func NewOperationsFeatureFlagHistoryViewData(
	page app.OperationsFeatureFlagDetailPage,
	filters OperationsHistoryPaginationFilterViewData,
) OperationsFeatureFlagHistoryViewData {
	domainCode := firstNonEmpty(page.Domain.Code, page.Flag.DomainCode)
	flagCode := strings.ToUpper(strings.TrimSpace(page.Flag.Code))
	baseURL := operationFeatureFlagHistoryURL(domainCode, flagCode)
	return OperationsFeatureFlagHistoryViewData{
		Domain:     page.Domain,
		Flag:       page.Flag,
		History:    page.History,
		BackURL:    operationsDomainURL(domainCode) + "?tab=" + OperationsTabFeatureFlags,
		DetailURL:  operationFeatureFlagURL(domainCode, flagCode),
		Pagination: newOperationsHistoryPaginationViewData(baseURL, page.History, filters),
	}
}

func NewOperationsTechBreakFormViewData(
	page app.OperationsTechBreakDetailPage,
	isNew bool,
) OperationsTechBreakFormViewData {
	domainCode := firstNonEmpty(page.Domain.Code, page.Break.DomainCode)
	baseURL := operationsDomainURL(domainCode)
	submitURL := baseURL + "/tech-breaks"
	deleteURL := ""
	if !isNew {
		submitURL += "/" + fmt.Sprintf("%d", page.Break.ID)
		deleteURL = submitURL + "/archive"
	}
	return OperationsTechBreakFormViewData{
		Domain:        page.Domain,
		Break:         page.Break,
		Scopes:        page.Scopes,
		IsNew:         isNew,
		SubmitURL:     submitURL,
		DeleteURL:     deleteURL,
		BackURL:       baseURL + "?tab=" + OperationsTabTechBreaks,
		EmailsText:    strings.Join(page.Break.ExcludeEmails, "\n"),
		NicknamesText: strings.Join(page.Break.ExcludeNicknames, "\n"),
	}
}

func NewOperationsScopeFormViewData(page app.OperationsScopeDetailPage, isNew bool) OperationsScopeFormViewData {
	domainCode := firstNonEmpty(page.Domain.Code, page.Scope.DomainCode)
	baseURL := operationsDomainURL(domainCode)
	submitURL := baseURL + "/scopes"
	deleteURL := ""
	if !isNew {
		submitURL += "/" + fmt.Sprintf("%d", page.Scope.ID)
		deleteURL = submitURL + "/archive"
	}
	return OperationsScopeFormViewData{
		Domain:    page.Domain,
		Scope:     page.Scope,
		IsNew:     isNew,
		SubmitURL: submitURL,
		DeleteURL: deleteURL,
		BackURL:   baseURL + "?tab=" + OperationsTabScopes,
	}
}

func normalizeOperationsDomainFilterViewData(filters OperationsDomainFilterViewData) OperationsDomainFilterViewData {
	filters.Search = strings.TrimSpace(filters.Search)
	if filters.Size <= 0 {
		filters.Size = 20
	}
	query := url.Values{}
	setOperationQuery(query, "q", filters.Search)
	if filters.Page > 0 {
		query.Set("page", fmt.Sprintf("%d", filters.Page))
	}
	if filters.Size != 20 {
		query.Set("size", fmt.Sprintf("%d", filters.Size))
	}
	filters.Query = query.Encode()
	return filters
}

func normalizeOperationsResourceFilterViewData(filters OperationsResourceFilterViewData) OperationsResourceFilterViewData {
	filters.Search = strings.TrimSpace(filters.Search)
	filters.Group = strings.TrimSpace(filters.Group)
	if filters.Size <= 0 {
		filters.Size = 20
	}
	query := url.Values{}
	setOperationQuery(query, "q", filters.Search)
	setOperationQuery(query, "group", filters.Group)
	setOperationDateQuery(query, "action_start_date", filters.ActionStartDate)
	setOperationDateQuery(query, "action_end_date", filters.ActionEndDate)
	if filters.InArchive {
		query.Set("in_archive", "true")
	}
	if filters.Page > 0 {
		query.Set("page", fmt.Sprintf("%d", filters.Page))
	}
	if filters.Size != 20 {
		query.Set("size", fmt.Sprintf("%d", filters.Size))
	}
	filters.Query = query.Encode()
	return filters
}

func operationsTabs(baseURL string, activeTab string) []OperationsTabViewData {
	tabs := []OperationsTabViewData{
		{Key: OperationsTabDomain, Label: "operations.tab.domain", URL: baseURL},
		{Key: OperationsTabFeatureFlags, Label: "operations.tab.featureFlags", URL: baseURL + "?tab=" + OperationsTabFeatureFlags},
		{Key: OperationsTabTechBreaks, Label: "operations.tab.techBreaks", URL: baseURL + "?tab=" + OperationsTabTechBreaks},
		{Key: OperationsTabScopes, Label: "operations.tab.scopes", URL: baseURL + "?tab=" + OperationsTabScopes},
	}
	for i := range tabs {
		tabs[i].Active = tabs[i].Key == activeTab
	}
	return tabs
}

func normalizeOperationsTab(tab string) string {
	switch strings.ToLower(strings.TrimSpace(tab)) {
	case OperationsTabFeatureFlags:
		return OperationsTabFeatureFlags
	case OperationsTabTechBreaks:
		return OperationsTabTechBreaks
	case OperationsTabScopes:
		return OperationsTabScopes
	default:
		return OperationsTabDomain
	}
}

func operationsDomainURL(code string) string {
	code = strings.ToUpper(strings.TrimSpace(code))
	if code == "" {
		return "/admin/operations"
	}
	return "/admin/operations/domains/" + url.PathEscape(code)
}

func operationFeatureFlagURL(domainCode string, code string) string {
	return operationsDomainURL(domainCode) + "/feature-flags/" + url.PathEscape(strings.ToUpper(strings.TrimSpace(code)))
}

func operationFeatureFlagHistoryURL(domainCode string, code string) string {
	return operationFeatureFlagURL(domainCode, code) + "/history"
}

func operationTechBreakURL(domainCode string, id int64) string {
	return operationsDomainURL(domainCode) + "/tech-breaks/" + fmt.Sprintf("%d", id)
}

func operationScopeURL(domainCode string, id int64) string {
	return operationsDomainURL(domainCode) + "/scopes/" + fmt.Sprintf("%d", id)
}

func operationValueText(value []any) string {
	if len(value) == 0 {
		return ""
	}
	if len(value) == 1 {
		return strings.TrimSpace(fmt.Sprint(value[0]))
	}
	raw, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return fmt.Sprint(value)
	}
	return string(raw)
}

func operationValueRows(flagType string, value []any) []string {
	if strings.EqualFold(flagType, "TOGGLE") {
		return nil
	}
	if len(value) == 0 {
		return []string{""}
	}
	rows := make([]string, 0, len(value))
	for _, item := range value {
		rows = append(rows, strings.TrimSpace(fmt.Sprint(item)))
	}
	return rows
}

func newOperationsHistoryPaginationViewData(
	baseURL string,
	page model.OperationPage[model.OperationFeatureFlagHistory],
	filters OperationsHistoryPaginationFilterViewData,
) OperationsHistoryPaginationViewData {
	currentPage := page.Page
	if currentPage < 0 {
		currentPage = 0
	}
	pageSize := filters.Size
	if pageSize <= 0 {
		pageSize = page.Size
	}
	if pageSize <= 0 {
		pageSize = 20
	}
	totalPages := page.TotalPages
	if totalPages < 0 {
		totalPages = 0
	}
	view := OperationsHistoryPaginationViewData{
		TotalPages:       totalPages,
		CurrentPageLabel: currentPage + 1,
		HasPrevious:      currentPage > 0,
		HasNext:          strings.TrimSpace(page.NextCursor) != "" || (totalPages > 0 && currentPage+1 < totalPages),
	}
	if view.HasPrevious {
		view.PreviousURL = operationHistoryPageURL(baseURL, currentPage-1, pageSize)
	}
	if view.HasNext {
		view.NextURL = operationHistoryPageURLWithCursor(baseURL, currentPage+1, pageSize, page.NextCursor)
	}
	return view
}

func operationHistoryPageURL(baseURL string, page int, size int) string {
	return operationHistoryPageURLWithCursor(baseURL, page, size, "")
}

func operationHistoryPageURLWithCursor(baseURL string, page int, size int, cursor string) string {
	if page < 0 {
		page = 0
	}
	query := url.Values{}
	query.Set("page", fmt.Sprintf("%d", page))
	if size > 0 && size != 20 {
		query.Set("size", fmt.Sprintf("%d", size))
	}
	if cursor = strings.TrimSpace(cursor); cursor != "" {
		query.Set("cursor", cursor)
	}
	return baseURL + "?" + query.Encode()
}

func operationStringListText(values []string) string {
	if len(values) == 0 {
		return ""
	}
	return strings.Join(values, ", ")
}

func operationDateTimeInput(value time.Time) string {
	if value.IsZero() {
		return ""
	}
	return value.Format("2006-01-02T15:04")
}

func operationOptionalDateTimeInput(value *time.Time) string {
	if value == nil {
		return ""
	}
	return operationDateTimeInput(*value)
}

func operationDateInput(value *time.Time) string {
	if value == nil || value.IsZero() {
		return ""
	}
	return value.UTC().Format("2006-01-02")
}

func operationBoolText(locale any, value bool) string {
	if value {
		return translate(fmt.Sprint(locale), "label.yes")
	}
	return translate(fmt.Sprint(locale), "label.no")
}

func operationBoolBadgeClass(value bool) string {
	if value {
		return "badge badge-success"
	}
	return "badge badge-danger"
}

func operationScopeSelected(scopes []model.OperationTechBreakScope, code string) bool {
	for _, scope := range scopes {
		if strings.EqualFold(scope.Code, code) {
			return true
		}
	}
	return false
}

func operationTechBreakScopeSelected(item model.OperationTechBreak, code string) bool {
	for _, scope := range item.Scopes {
		if strings.EqualFold(scope.Code, code) {
			return true
		}
	}
	for _, scopeCode := range item.ScopeCodes {
		if strings.EqualFold(scopeCode, code) {
			return true
		}
	}
	return false
}

func operationGroupFilterMissing(groups []string, selected string) bool {
	selected = strings.TrimSpace(selected)
	if selected == "" {
		return false
	}
	for _, group := range groups {
		if strings.EqualFold(strings.TrimSpace(group), selected) {
			return false
		}
	}
	return true
}

func setOperationQuery(values url.Values, key string, value string) {
	if value = strings.TrimSpace(value); value != "" {
		values.Set(key, value)
	}
}

func setOperationDateQuery(values url.Values, key string, value *time.Time) {
	if formatted := operationDateInput(value); formatted != "" {
		values.Set(key, formatted)
	}
}

func filterOperationScopes(scopes []model.OperationTechBreakScope, search string) []model.OperationTechBreakScope {
	search = strings.ToLower(strings.TrimSpace(search))
	if search == "" {
		return scopes
	}
	out := make([]model.OperationTechBreakScope, 0, len(scopes))
	for _, scope := range scopes {
		if strings.Contains(strings.ToLower(scope.Code), search) ||
			strings.Contains(strings.ToLower(scope.Name), search) {
			out = append(out, scope)
		}
	}
	return out
}
