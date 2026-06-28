package support

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type Client struct {
	baseURL       string
	httpClient    *http.Client
	internalToken string
}

func NewClient(baseURL string, timeout time.Duration, internalToken string) *Client {
	baseURL = strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	return &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: timeout,
		},
		internalToken: strings.TrimSpace(internalToken),
	}
}

func (c *Client) ListTickets(ctx context.Context, filter model.SupportTicketFilter) ([]model.SupportTicket, error) {
	values := url.Values{}
	if filter.Status != "" {
		values.Set("status", string(filter.Status))
	}
	if filter.Category != "" {
		values.Set("category", string(filter.Category))
	}
	if filter.Priority != "" {
		values.Set("priority", string(filter.Priority))
	}
	if strings.TrimSpace(filter.AssigneeID) != "" {
		values.Set("assigneeId", strings.TrimSpace(filter.AssigneeID))
	}
	if filter.SLABreached {
		values.Set("sla", "breached")
	}
	values.Set("limit", fmt.Sprintf("%d", filter.Limit))
	values.Set("offset", fmt.Sprintf("%d", filter.Offset))

	var resp supportTicketListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/support/tickets?"+values.Encode(), nil, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.SupportTicket, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) GetTicket(ctx context.Context, ticketID string) (model.SupportTicketDetail, error) {
	var resp supportTicketDetailResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/support/tickets/"+url.PathEscape(ticketID), nil, nil, &resp); err != nil {
		return model.SupportTicketDetail{}, err
	}
	events := make([]model.SupportTicketEvent, 0, len(resp.Events))
	for _, event := range resp.Events {
		events = append(events, event.toModel())
	}
	return model.SupportTicketDetail{Ticket: resp.Ticket.toModel(), Events: events}, nil
}

func (c *Client) AssignTicket(ctx context.Context, input model.SupportTicketAssignInput) (model.SupportTicket, error) {
	body := map[string]string{"assigneeId": input.AssigneeID, "reason": input.Reason}
	return c.ticketAction(ctx, http.MethodPost, input.TicketID, "assign", supportActorHeaders(input.ActorStaffID, input.IdempotencyKey, input.RequestID), body)
}

func (c *Client) ReplyTicket(ctx context.Context, input model.SupportTicketReplyInput) (model.SupportTicket, error) {
	body := map[string]any{
		"message":        input.Message,
		"conversationId": input.ConversationID,
		"messageId":      input.MessageID,
	}
	if fileIDs := normalizeSupportFileIDs(input.FileIDs); len(fileIDs) > 0 {
		body["fileIds"] = fileIDs
	}
	return c.ticketAction(ctx, http.MethodPost, input.TicketID, "reply", supportActorHeaders(input.ActorStaffID, input.IdempotencyKey, input.RequestID, input.ActorDisplayName), body)
}

func (c *Client) AddTicketNote(ctx context.Context, input model.SupportTicketNoteInput) error {
	body := map[string]string{"note": input.Note}
	_, err := c.ticketAction(ctx, http.MethodPost, input.TicketID, "notes", supportActorHeaders(input.ActorStaffID, input.IdempotencyKey, input.RequestID), body)
	return err
}

func (c *Client) ResolveTicket(ctx context.Context, input model.SupportTicketResolveInput) (model.SupportTicket, error) {
	body := map[string]string{"resolution": input.Resolution}
	return c.ticketAction(ctx, http.MethodPost, input.TicketID, "resolve", supportActorHeaders(input.ActorStaffID, input.IdempotencyKey, input.RequestID), body)
}

func (c *Client) ReopenTicket(ctx context.Context, input model.SupportTicketReopenInput) (model.SupportTicket, error) {
	body := map[string]string{"reason": input.Reason}
	return c.ticketAction(ctx, http.MethodPost, input.TicketID, "reopen", supportActorHeaders(input.ActorStaffID, input.IdempotencyKey, input.RequestID), body)
}

func (c *Client) ListSupportAgents(ctx context.Context, filter model.SupportAgentFilter) ([]model.SupportAgent, error) {
	values := url.Values{}
	if filter.Status != "" {
		values.Set("status", string(filter.Status))
	}
	values.Set("limit", fmt.Sprintf("%d", filter.Limit))
	values.Set("offset", fmt.Sprintf("%d", filter.Offset))

	var resp supportAgentListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/support/agents?"+values.Encode(), supportActorHeaders("admin-panel", "", ""), nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.SupportAgent, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) UpsertSupportAgent(ctx context.Context, input model.SupportAgentUpsertInput) (model.SupportAgent, error) {
	body := upsertSupportAgentRequest{
		DisplayName:   input.DisplayName,
		FirstName:     input.FirstName,
		LastName:      input.LastName,
		MiddleName:    input.MiddleName,
		Status:        string(input.Status),
		Languages:     input.Languages,
		Skills:        supportAgentSkillsToStrings(input.Skills),
		Level:         string(input.Level),
		MaxActiveLoad: input.MaxActiveLoad,
		Timezone:      input.Timezone,
	}
	var resp supportAgentActionResponse
	path := "/v1/admin/support/agents/" + url.PathEscape(input.StaffID)
	if err := c.doJSON(ctx, http.MethodPut, path, supportActorHeaders(input.ActorStaffID, input.IdempotencyKey, input.RequestID), body, &resp); err != nil {
		return model.SupportAgent{}, err
	}
	return resp.Agent.toModel(), nil
}

func (c *Client) GetSupportUserSegment(ctx context.Context, userID string) (model.SupportUserSegment, error) {
	var resp supportUserSegmentActionResponse
	path := "/v1/admin/support/user-segments/" + url.PathEscape(userID)
	if err := c.doJSON(ctx, http.MethodGet, path, supportActorHeaders("admin-panel", "", ""), nil, &resp); err != nil {
		return model.SupportUserSegment{}, err
	}
	return resp.Segment.toModel(), nil
}

func (c *Client) UpsertSupportUserSegment(ctx context.Context, input model.SupportUserSegmentUpsertInput) (model.SupportUserSegment, error) {
	body := upsertSupportUserSegmentRequest{
		Nickname:         input.Nickname,
		FollowersCount:   input.FollowersCount,
		IsGuide:          input.IsGuide,
		GuideStatus:      input.GuideStatus,
		IsPublicFigure:   input.IsPublicFigure,
		IsPartner:        input.IsPartner,
		ManualSegment:    string(input.ManualSegment),
		ManualReason:     input.ManualReason,
		SubscriptionTier: input.SubscriptionTier,
		SourceVersion:    input.SourceVersion,
	}
	var resp supportUserSegmentActionResponse
	path := "/v1/admin/support/user-segments/" + url.PathEscape(input.UserID)
	if err := c.doJSON(ctx, http.MethodPut, path, supportActorHeaders(input.ActorStaffID, input.IdempotencyKey, input.RequestID), body, &resp); err != nil {
		return model.SupportUserSegment{}, err
	}
	return resp.Segment.toModel(), nil
}

func (c *Client) ListSupportSavedReplies(ctx context.Context, filter model.SupportSavedReplyFilter) ([]model.SupportSavedReply, error) {
	values := url.Values{}
	if strings.TrimSpace(filter.Category) != "" {
		values.Set("category", strings.TrimSpace(filter.Category))
	}
	if filter.Status != "" {
		values.Set("status", string(filter.Status))
	}
	values.Set("limit", fmt.Sprintf("%d", filter.Limit))
	values.Set("offset", fmt.Sprintf("%d", filter.Offset))

	var resp supportSavedReplyListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/support/saved-replies?"+values.Encode(), supportActorHeaders("admin-panel", "", ""), nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.SupportSavedReply, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) UpsertSupportSavedReply(ctx context.Context, input model.SupportSavedReplyUpsertInput) (model.SupportSavedReply, error) {
	body := upsertSupportSavedReplyRequest{
		Category:     input.Category,
		Status:       string(input.Status),
		Tags:         input.Tags,
		Translations: input.Translations,
		SortOrder:    input.SortOrder,
	}
	var resp supportSavedReplyActionResponse
	path := "/v1/admin/support/saved-replies/" + url.PathEscape(input.ReplyID)
	headers := supportActorHeaders(input.ActorStaffID, input.IdempotencyKey, input.RequestID)
	if err := c.doJSON(ctx, http.MethodPut, path, headers, body, &resp); err != nil {
		return model.SupportSavedReply{}, err
	}
	return resp.Reply.toModel(), nil
}

func (c *Client) ListHelpCategories(ctx context.Context, filter model.HelpCategoryFilter) ([]model.HelpCategory, error) {
	values := url.Values{}
	if filter.Status != "" {
		values.Set("status", string(filter.Status))
	}
	if strings.TrimSpace(filter.Locale) != "" {
		values.Set("locale", strings.TrimSpace(filter.Locale))
	}
	values.Set("limit", fmt.Sprintf("%d", filter.Limit))
	values.Set("offset", fmt.Sprintf("%d", filter.Offset))

	var resp helpCategoryListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/help/categories?"+values.Encode(), helpContentActorHeaders("admin-panel", "", ""), nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.HelpCategory, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) UpsertHelpCategory(ctx context.Context, input model.HelpCategoryUpsertInput) (model.HelpCategory, error) {
	body := upsertHelpCategoryRequest{
		Slug:      input.Slug,
		Status:    string(input.Status),
		SortOrder: input.SortOrder,
	}
	var resp helpCategoryActionResponse
	path := "/v1/admin/help/categories/" + url.PathEscape(input.CategoryID)
	headers := helpContentActorHeaders(input.ActorStaffID, input.IdempotencyKey, input.RequestID)
	if err := c.doJSON(ctx, http.MethodPut, path, headers, body, &resp); err != nil {
		return model.HelpCategory{}, err
	}
	return resp.Category.toModel(), nil
}

func (c *Client) ListHelpArticles(ctx context.Context, filter model.HelpArticleFilter) ([]model.HelpArticle, error) {
	values := url.Values{}
	if filter.Status != "" {
		values.Set("status", string(filter.Status))
	}
	values.Set("limit", fmt.Sprintf("%d", filter.Limit))
	values.Set("offset", fmt.Sprintf("%d", filter.Offset))

	var resp helpArticleListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/help/articles?"+values.Encode(), helpContentActorHeaders("admin-panel", "", ""), nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.HelpArticle, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) GetHelpArticle(ctx context.Context, articleID string) (model.HelpArticleDetail, error) {
	var resp helpArticleDetailResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/help/articles/"+url.PathEscape(articleID), helpContentActorHeaders("admin-panel", "", ""), nil, &resp); err != nil {
		return model.HelpArticleDetail{}, err
	}
	events := make([]model.HelpArticleEvent, 0, len(resp.Events))
	for _, event := range resp.Events {
		events = append(events, event.toModel())
	}
	return model.HelpArticleDetail{Article: resp.Article.toModel(), Events: events}, nil
}

func (c *Client) GetHelpAnalytics(ctx context.Context, limit int) (model.HelpAnalyticsSummary, error) {
	values := url.Values{}
	if limit <= 0 {
		limit = 10
	}
	values.Set("limit", fmt.Sprintf("%d", limit))
	var resp helpAnalyticsResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/help/analytics?"+values.Encode(), helpAnalyticsActorHeaders(), nil, &resp); err != nil {
		return model.HelpAnalyticsSummary{}, err
	}
	return resp.toModel(), nil
}

func (c *Client) UpsertHelpArticle(ctx context.Context, input model.HelpArticleUpsertInput) (model.HelpArticle, error) {
	body := upsertHelpArticleRequest{
		Slug:              input.Slug,
		CategoryID:        input.CategoryID,
		Status:            string(input.Status),
		Tags:              input.Tags,
		Surfaces:          input.Surfaces,
		Visibility:        input.Visibility,
		Translations:      input.Translations,
		Actions:           input.Actions,
		RelatedArticleIDs: input.RelatedArticleIDs,
	}
	var resp helpArticleActionResponse
	path := "/v1/admin/help/articles/" + url.PathEscape(input.ArticleID)
	headers := helpContentActorHeaders(input.ActorStaffID, input.IdempotencyKey, input.RequestID)
	if err := c.doJSON(ctx, http.MethodPut, path, headers, body, &resp); err != nil {
		return model.HelpArticle{}, err
	}
	return resp.Article.toModel(), nil
}

func (c *Client) SubmitHelpArticleForReview(ctx context.Context, articleID string, input model.HelpArticleActionInput) (model.HelpArticle, error) {
	return c.helpArticleAction(ctx, articleID, "submit-review", input)
}

func (c *Client) PublishHelpArticle(ctx context.Context, articleID string, input model.HelpArticleActionInput) (model.HelpArticle, error) {
	return c.helpArticleAction(ctx, articleID, "publish", input)
}

func (c *Client) ArchiveHelpArticle(ctx context.Context, articleID string, input model.HelpArticleActionInput) (model.HelpArticle, error) {
	return c.helpArticleAction(ctx, articleID, "archive", input)
}

func (c *Client) ticketAction(ctx context.Context, method string, ticketID string, action string, headers map[string]string, body any) (model.SupportTicket, error) {
	var resp supportTicketActionResponse
	path := "/v1/admin/support/tickets/" + url.PathEscape(ticketID) + "/" + action
	if err := c.doJSON(ctx, method, path, headers, body, &resp); err != nil {
		return model.SupportTicket{}, err
	}
	return resp.Ticket.toModel(), nil
}

func (c *Client) helpArticleAction(ctx context.Context, articleID string, action string, input model.HelpArticleActionInput) (model.HelpArticle, error) {
	var resp helpArticleActionResponse
	path := "/v1/admin/help/articles/" + url.PathEscape(articleID) + "/" + action
	headers := helpContentActorHeaders(input.ActorStaffID, input.IdempotencyKey, input.RequestID)
	if err := c.doJSON(ctx, http.MethodPost, path, headers, nil, &resp); err != nil {
		return model.HelpArticle{}, err
	}
	return resp.Article.toModel(), nil
}

func supportActorHeaders(actorStaffID string, idempotencyKey string, requestID string, actorDisplayName ...string) map[string]string {
	headers := map[string]string{
		"X-Auth-Subject":  "admin-panel:" + actorStaffID,
		"X-User-Id":       actorStaffID,
		"X-User-Roles":    "SUPER_ADMIN,SUPPORT_AGENT,SUPPORT_ADMIN",
		"Idempotency-Key": idempotencyKey,
	}
	if strings.TrimSpace(requestID) != "" {
		headers["X-Request-Id"] = strings.TrimSpace(requestID)
	}
	if len(actorDisplayName) > 0 && strings.TrimSpace(actorDisplayName[0]) != "" {
		headers["X-Actor-Display-Name"] = strings.TrimSpace(actorDisplayName[0])
	}
	return headers
}

func helpContentActorHeaders(actorStaffID string, idempotencyKey string, requestID string) map[string]string {
	actorStaffID = strings.TrimSpace(actorStaffID)
	if actorStaffID == "" {
		actorStaffID = "admin-panel"
	}
	headers := map[string]string{
		"X-Auth-Subject": "admin-panel:" + actorStaffID,
		"X-User-Id":      actorStaffID,
		"X-User-Roles":   "SUPER_ADMIN,HELP_CONTENT_EDITOR,HELP_CONTENT_PUBLISHER",
	}
	if strings.TrimSpace(idempotencyKey) != "" {
		headers["Idempotency-Key"] = strings.TrimSpace(idempotencyKey)
	}
	if strings.TrimSpace(requestID) != "" {
		headers["X-Request-Id"] = strings.TrimSpace(requestID)
	}
	return headers
}

func helpAnalyticsActorHeaders() map[string]string {
	return map[string]string{
		"X-Auth-Subject": "admin-panel:help-analytics",
		"X-User-Id":      "admin-panel",
		"X-User-Roles":   "SUPER_ADMIN,SUPPORT_LEAD,SUPPORT_ADMIN,HELP_CONTENT_EDITOR,HELP_CONTENT_PUBLISHER",
	}
}

func (c *Client) doJSON(ctx context.Context, method string, path string, headers map[string]string, body any, dest any) error {
	var reader io.Reader
	if body != nil {
		payload, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reader = bytes.NewReader(payload)
	}
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, reader)
	if err != nil {
		return err
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Accept", "application/json")
	if c.internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.internalToken)
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
		req.Header.Set("X-Internal-Service", "admin-panel")
		req.Header.Set("X-Auth-Subject", "admin-panel")
		req.Header.Set("X-User-Id", "admin-panel")
		req.Header.Set("X-User-Roles", "SUPER_ADMIN,SUPPORT_AGENT,SUPPORT_ADMIN")
	}
	for key, value := range headers {
		if strings.TrimSpace(value) != "" {
			req.Header.Set(key, value)
		}
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("support-service %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	if dest != nil {
		if err = json.Unmarshal(raw, dest); err != nil {
			return err
		}
	}
	return nil
}

type supportTicketListResponse struct {
	Items []supportTicketResponse `json:"items"`
}

type supportTicketDetailResponse struct {
	Ticket supportTicketResponse        `json:"ticket"`
	Events []supportTicketEventResponse `json:"events"`
}

type supportTicketActionResponse struct {
	Ticket supportTicketResponse `json:"ticket"`
}

type supportSavedReplyListResponse struct {
	Items []supportSavedReplyResponse `json:"items"`
}

type supportSavedReplyActionResponse struct {
	Reply supportSavedReplyResponse `json:"reply"`
}

type supportAgentListResponse struct {
	Items []supportAgentResponse `json:"items"`
}

type supportAgentActionResponse struct {
	Agent supportAgentResponse `json:"agent"`
}

type supportUserSegmentActionResponse struct {
	Segment supportUserSegmentResponse `json:"segment"`
}

type helpArticleListResponse struct {
	Items []helpArticleResponse `json:"items"`
}

type helpArticleDetailResponse struct {
	Article helpArticleResponse        `json:"article"`
	Events  []helpArticleEventResponse `json:"events"`
}

type helpArticleActionResponse struct {
	Article helpArticleResponse `json:"article"`
}

type helpAnalyticsResponse struct {
	GeneratedAt string                         `json:"generatedAt"`
	Searches    helpSearchAnalyticsResponse    `json:"searches"`
	Feedback    helpFeedbackAnalyticsResponse  `json:"feedback"`
	Tickets     supportTicketAnalyticsResponse `json:"tickets"`
}

func (r helpAnalyticsResponse) toModel() model.HelpAnalyticsSummary {
	return model.HelpAnalyticsSummary{
		GeneratedAt: parseTime(r.GeneratedAt),
		Searches:    r.Searches.toModel(),
		Feedback:    r.Feedback.toModel(),
		Tickets:     r.Tickets.toModel(),
	}
}

type helpSearchAnalyticsResponse struct {
	Total              int                       `json:"total"`
	WithoutResults     int                       `json:"withoutResults"`
	SuccessRate        float64                   `json:"successRate"`
	TopNoResultQueries []helpSearchQueryResponse `json:"topNoResultQueries"`
	RepeatedQueries    []helpSearchQueryResponse `json:"repeatedQueries"`
}

func (r helpSearchAnalyticsResponse) toModel() model.HelpSearchAnalytics {
	return model.HelpSearchAnalytics{
		Total:              r.Total,
		WithoutResults:     r.WithoutResults,
		SuccessRate:        r.SuccessRate,
		TopNoResultQueries: helpSearchQueriesToModel(r.TopNoResultQueries),
		RepeatedQueries:    helpSearchQueriesToModel(r.RepeatedQueries),
	}
}

type helpSearchQueryResponse struct {
	Query string `json:"query"`
	Count int    `json:"count"`
}

func helpSearchQueriesToModel(items []helpSearchQueryResponse) []model.HelpSearchQueryStat {
	out := make([]model.HelpSearchQueryStat, 0, len(items))
	for _, item := range items {
		out = append(out, model.HelpSearchQueryStat{Query: item.Query, Count: item.Count})
	}
	return out
}

type helpFeedbackAnalyticsResponse struct {
	Total                 int                           `json:"total"`
	Helpful               int                           `json:"helpful"`
	NotHelpful            int                           `json:"notHelpful"`
	Escalations           int                           `json:"escalations"`
	NotHelpfulRate        float64                       `json:"notHelpfulRate"`
	TopNotHelpfulArticles []helpArticleFeedbackResponse `json:"topNotHelpfulArticles"`
}

func (r helpFeedbackAnalyticsResponse) toModel() model.HelpFeedbackAnalytics {
	return model.HelpFeedbackAnalytics{
		Total:                 r.Total,
		Helpful:               r.Helpful,
		NotHelpful:            r.NotHelpful,
		Escalations:           r.Escalations,
		NotHelpfulRate:        r.NotHelpfulRate,
		TopNotHelpfulArticles: helpArticleFeedbackToModel(r.TopNotHelpfulArticles),
	}
}

type helpArticleFeedbackResponse struct {
	ArticleID   string `json:"articleId"`
	Count       int    `json:"count"`
	Escalations int    `json:"escalations"`
}

func helpArticleFeedbackToModel(items []helpArticleFeedbackResponse) []model.HelpArticleFeedbackStat {
	out := make([]model.HelpArticleFeedbackStat, 0, len(items))
	for _, item := range items {
		out = append(out, model.HelpArticleFeedbackStat{
			ArticleID:   item.ArticleID,
			Count:       item.Count,
			Escalations: item.Escalations,
		})
	}
	return out
}

type supportTicketAnalyticsResponse struct {
	Total                       int     `json:"total"`
	Open                        int     `json:"open"`
	WaitingSupport              int     `json:"waitingSupport"`
	Resolved                    int     `json:"resolved"`
	Closed                      int     `json:"closed"`
	Urgent                      int     `json:"urgent"`
	AverageFirstResponseSeconds int64   `json:"averageFirstResponseSeconds"`
	AverageResolutionSeconds    int64   `json:"averageResolutionSeconds"`
	CSATResponses               int     `json:"csatResponses"`
	AverageCSAT                 float64 `json:"averageCSAT"`
}

func (r supportTicketAnalyticsResponse) toModel() model.SupportTicketAnalytics {
	return model.SupportTicketAnalytics{
		Total:                       r.Total,
		Open:                        r.Open,
		WaitingSupport:              r.WaitingSupport,
		Resolved:                    r.Resolved,
		Closed:                      r.Closed,
		Urgent:                      r.Urgent,
		AverageFirstResponseSeconds: r.AverageFirstResponseSeconds,
		AverageResolutionSeconds:    r.AverageResolutionSeconds,
		CSATResponses:               r.CSATResponses,
		AverageCSAT:                 r.AverageCSAT,
	}
}

type upsertHelpArticleRequest struct {
	Slug              string                                  `json:"slug"`
	CategoryID        string                                  `json:"categoryId"`
	Status            string                                  `json:"status"`
	Tags              []string                                `json:"tags"`
	Surfaces          []string                                `json:"surfaces"`
	Visibility        model.HelpArticleVisibility             `json:"visibility"`
	Translations      map[string]model.HelpArticleTranslation `json:"translations"`
	Actions           []model.HelpArticleAction               `json:"actions"`
	RelatedArticleIDs []string                                `json:"relatedArticleIds"`
}

type upsertSupportSavedReplyRequest struct {
	Category     string                                        `json:"category"`
	Status       string                                        `json:"status"`
	Tags         []string                                      `json:"tags"`
	Translations map[string]model.SupportSavedReplyTranslation `json:"translations"`
	SortOrder    int                                           `json:"sortOrder"`
}

type upsertHelpCategoryRequest struct {
	Slug      string `json:"slug"`
	Status    string `json:"status"`
	SortOrder int    `json:"sortOrder"`
}

type helpCategoryListResponse struct {
	Items []helpCategoryResponse `json:"items"`
}

type helpCategoryActionResponse struct {
	Category helpCategoryResponse `json:"category"`
}

type helpCategoryResponse struct {
	ID        string `json:"id"`
	Slug      string `json:"slug"`
	Title     string `json:"title"`
	Status    string `json:"status"`
	SortOrder int    `json:"sortOrder"`
	CreatedAt string `json:"createdAt"`
	UpdatedAt string `json:"updatedAt"`
}

func (r helpCategoryResponse) toModel() model.HelpCategory {
	return model.HelpCategory{
		ID:        r.ID,
		Slug:      r.Slug,
		Title:     r.Title,
		Status:    model.HelpArticleStatus(r.Status),
		SortOrder: r.SortOrder,
		CreatedAt: parseTime(r.CreatedAt),
		UpdatedAt: parseTime(r.UpdatedAt),
	}
}

type supportSavedReplyResponse struct {
	ID           string                                        `json:"id"`
	Category     string                                        `json:"category"`
	Status       string                                        `json:"status"`
	Tags         []string                                      `json:"tags"`
	Translations map[string]model.SupportSavedReplyTranslation `json:"translations"`
	SortOrder    int                                           `json:"sortOrder"`
	CreatedAt    string                                        `json:"createdAt"`
	UpdatedAt    string                                        `json:"updatedAt"`
}

type upsertSupportAgentRequest struct {
	DisplayName   string   `json:"displayName"`
	FirstName     string   `json:"firstName"`
	LastName      string   `json:"lastName"`
	MiddleName    string   `json:"middleName"`
	Status        string   `json:"status"`
	Languages     []string `json:"languages"`
	Skills        []string `json:"skills"`
	Level         string   `json:"level"`
	MaxActiveLoad float64  `json:"maxActiveLoad"`
	Timezone      string   `json:"timezone"`
}

type supportAgentResponse struct {
	StaffID       string   `json:"staffId"`
	DisplayName   string   `json:"displayName"`
	FirstName     string   `json:"firstName"`
	LastName      string   `json:"lastName"`
	MiddleName    string   `json:"middleName"`
	Email         string   `json:"email,omitempty"`
	Status        string   `json:"status"`
	Languages     []string `json:"languages"`
	Skills        []string `json:"skills"`
	Level         string   `json:"level"`
	MaxActiveLoad float64  `json:"maxActiveLoad"`
	Timezone      string   `json:"timezone"`
	UpdatedAt     string   `json:"updatedAt"`
}

func (r supportAgentResponse) toModel() model.SupportAgent {
	return model.SupportAgent{
		StaffID:       r.StaffID,
		DisplayName:   r.DisplayName,
		FirstName:     r.FirstName,
		LastName:      r.LastName,
		MiddleName:    r.MiddleName,
		Email:         r.Email,
		Status:        model.SupportAgentStatus(r.Status),
		Languages:     append([]string(nil), r.Languages...),
		Skills:        supportAgentSkillsFromStrings(r.Skills),
		Level:         model.SupportAgentLevel(r.Level),
		MaxActiveLoad: r.MaxActiveLoad,
		Timezone:      r.Timezone,
		UpdatedAt:     parseTime(r.UpdatedAt),
	}
}

type upsertSupportUserSegmentRequest struct {
	Nickname         string `json:"nickname"`
	FollowersCount   int    `json:"followersCount"`
	IsGuide          bool   `json:"isGuide"`
	GuideStatus      string `json:"guideStatus"`
	IsPublicFigure   bool   `json:"isPublicFigure"`
	IsPartner        bool   `json:"isPartner"`
	ManualSegment    string `json:"manualSegment"`
	ManualReason     string `json:"manualReason"`
	SubscriptionTier string `json:"subscriptionTier"`
	SourceVersion    string `json:"sourceVersion"`
}

type supportUserSegmentResponse struct {
	UserID           string   `json:"userId"`
	Nickname         string   `json:"nickname"`
	CustomerSegment  string   `json:"customerSegment"`
	FollowersCount   int      `json:"followersCount"`
	IsGuide          bool     `json:"isGuide"`
	GuideStatus      string   `json:"guideStatus"`
	IsPublicFigure   bool     `json:"isPublicFigure"`
	IsPartner        bool     `json:"isPartner"`
	ManualSegment    string   `json:"manualSegment"`
	ManualReason     string   `json:"manualReason"`
	SubscriptionTier string   `json:"subscriptionTier"`
	ReasonCodes      []string `json:"reasonCodes"`
	RefreshStatus    string   `json:"refreshStatus"`
	UpdatedAt        string   `json:"updatedAt"`
	SourceVersion    string   `json:"sourceVersion"`
}

func (r supportUserSegmentResponse) toModel() model.SupportUserSegment {
	return model.SupportUserSegment{
		UserID:           r.UserID,
		Nickname:         r.Nickname,
		CustomerSegment:  model.SupportCustomerSegment(r.CustomerSegment),
		FollowersCount:   r.FollowersCount,
		IsGuide:          r.IsGuide,
		GuideStatus:      r.GuideStatus,
		IsPublicFigure:   r.IsPublicFigure,
		IsPartner:        r.IsPartner,
		ManualSegment:    model.SupportCustomerSegment(r.ManualSegment),
		ManualReason:     r.ManualReason,
		SubscriptionTier: r.SubscriptionTier,
		ReasonCodes:      append([]string(nil), r.ReasonCodes...),
		RefreshStatus:    r.RefreshStatus,
		UpdatedAt:        parseTime(r.UpdatedAt),
		SourceVersion:    r.SourceVersion,
	}
}

func (r supportSavedReplyResponse) toModel() model.SupportSavedReply {
	return model.SupportSavedReply{
		ID:           r.ID,
		Category:     r.Category,
		Status:       model.HelpArticleStatus(r.Status),
		Tags:         r.Tags,
		Translations: r.Translations,
		SortOrder:    r.SortOrder,
		CreatedAt:    parseTime(r.CreatedAt),
		UpdatedAt:    parseTime(r.UpdatedAt),
	}
}

type helpArticleResponse struct {
	ID                string                                  `json:"id"`
	CategoryID        string                                  `json:"categoryId"`
	Slug              string                                  `json:"slug"`
	Status            string                                  `json:"status"`
	Version           int                                     `json:"version"`
	OwnerID           string                                  `json:"ownerId"`
	ReviewerID        string                                  `json:"reviewerId"`
	Tags              []string                                `json:"tags"`
	Surfaces          []string                                `json:"surfaces"`
	Visibility        model.HelpArticleVisibility             `json:"visibility"`
	Translations      map[string]model.HelpArticleTranslation `json:"translations"`
	Actions           []model.HelpArticleAction               `json:"actions"`
	RelatedArticleIDs []string                                `json:"relatedArticleIds"`
	PublishedAt       string                                  `json:"publishedAt"`
	LastReviewedAt    string                                  `json:"lastReviewedAt"`
	CreatedAt         string                                  `json:"createdAt"`
	UpdatedAt         string                                  `json:"updatedAt"`
}

func (r helpArticleResponse) toModel() model.HelpArticle {
	return model.HelpArticle{
		ID:                r.ID,
		CategoryID:        r.CategoryID,
		Slug:              r.Slug,
		Status:            model.HelpArticleStatus(r.Status),
		Version:           r.Version,
		OwnerID:           r.OwnerID,
		ReviewerID:        r.ReviewerID,
		Tags:              r.Tags,
		Surfaces:          r.Surfaces,
		Visibility:        r.Visibility,
		Translations:      r.Translations,
		Actions:           r.Actions,
		RelatedArticleIDs: r.RelatedArticleIDs,
		PublishedAt:       parseOptionalTime(r.PublishedAt),
		LastReviewedAt:    parseOptionalTime(r.LastReviewedAt),
		CreatedAt:         parseTime(r.CreatedAt),
		UpdatedAt:         parseTime(r.UpdatedAt),
	}
}

type helpArticleEventResponse struct {
	ArticleID string            `json:"articleId"`
	ActorID   string            `json:"actorId"`
	ActorType string            `json:"actorType"`
	EventType string            `json:"eventType"`
	Payload   map[string]string `json:"payload"`
	CreatedAt string            `json:"createdAt"`
}

func (r helpArticleEventResponse) toModel() model.HelpArticleEvent {
	return model.HelpArticleEvent{
		ArticleID: r.ArticleID,
		ActorID:   r.ActorID,
		ActorType: r.ActorType,
		EventType: r.EventType,
		Payload:   r.Payload,
		CreatedAt: parseTime(r.CreatedAt),
	}
}

type supportTicketResponse struct {
	ID                         string            `json:"id"`
	UserID                     string            `json:"userId"`
	ConversationID             string            `json:"conversationId"`
	Status                     string            `json:"status"`
	Category                   string            `json:"category"`
	Priority                   string            `json:"priority"`
	PriorityReasonCodes        []string          `json:"priorityReasonCodes"`
	CustomerSegment            string            `json:"customerSegment"`
	CustomerSegmentReasonCodes []string          `json:"customerSegmentReasonCodes"`
	SegmentRefreshStatus       string            `json:"segmentRefreshStatus"`
	UserNicknameSnapshot       string            `json:"userNicknameSnapshot"`
	FollowersCountSnapshot     int               `json:"followersCountSnapshot"`
	GuideStatusSnapshot        string            `json:"guideStatusSnapshot"`
	SubscriptionTierSnapshot   string            `json:"subscriptionTierSnapshot"`
	Source                     string            `json:"source"`
	Locale                     string            `json:"locale"`
	AssigneeID                 string            `json:"assigneeId"`
	AssignmentStatus           string            `json:"assignmentStatus"`
	AssignmentReason           string            `json:"assignmentReason"`
	AssignmentReasonCodes      []string          `json:"assignmentReasonCodes"`
	AssignedAt                 string            `json:"assignedAt"`
	Context                    map[string]string `json:"context"`
	FirstResponseAt            string            `json:"firstResponseAt"`
	ResolvedAt                 string            `json:"resolvedAt"`
	LastMessagePreview         string            `json:"lastMessagePreview"`
	LastMessageAt              string            `json:"lastMessageAt"`
	CreatedAt                  string            `json:"createdAt"`
	UpdatedAt                  string            `json:"updatedAt"`
}

func (r supportTicketResponse) toModel() model.SupportTicket {
	return model.SupportTicket{
		ID:                         r.ID,
		UserID:                     r.UserID,
		ConversationID:             r.ConversationID,
		Category:                   model.SupportTicketCategory(r.Category),
		Status:                     model.SupportTicketStatus(r.Status),
		Priority:                   model.SupportTicketPriority(r.Priority),
		PriorityReasonCodes:        append([]string(nil), r.PriorityReasonCodes...),
		CustomerSegment:            model.SupportCustomerSegment(r.CustomerSegment),
		CustomerSegmentReasonCodes: append([]string(nil), r.CustomerSegmentReasonCodes...),
		SegmentRefreshStatus:       r.SegmentRefreshStatus,
		UserNicknameSnapshot:       r.UserNicknameSnapshot,
		FollowersCountSnapshot:     r.FollowersCountSnapshot,
		GuideStatusSnapshot:        r.GuideStatusSnapshot,
		SubscriptionTierSnapshot:   r.SubscriptionTierSnapshot,
		Source:                     r.Source,
		Locale:                     r.Locale,
		AssigneeID:                 r.AssigneeID,
		AssignmentStatus:           model.SupportAssignmentStatus(r.AssignmentStatus),
		AssignmentReason:           r.AssignmentReason,
		AssignmentReasonCodes:      append([]string(nil), r.AssignmentReasonCodes...),
		AssignedAt:                 parseOptionalTime(r.AssignedAt),
		Context:                    r.Context,
		FirstResponseAt:            parseOptionalTime(r.FirstResponseAt),
		ResolvedAt:                 parseOptionalTime(r.ResolvedAt),
		LastMessagePreview:         r.LastMessagePreview,
		LastMessageAt:              parseTime(r.LastMessageAt),
		CreatedAt:                  parseTime(r.CreatedAt),
		UpdatedAt:                  parseTime(r.UpdatedAt),
	}
}

type supportTicketEventResponse struct {
	TicketID  string            `json:"ticketId"`
	ActorID   string            `json:"actorId"`
	ActorType string            `json:"actorType"`
	EventType string            `json:"eventType"`
	Payload   map[string]string `json:"payload"`
	CreatedAt string            `json:"createdAt"`
}

func (r supportTicketEventResponse) toModel() model.SupportTicketEvent {
	return model.SupportTicketEvent{
		TicketID:  r.TicketID,
		ActorID:   r.ActorID,
		ActorType: r.ActorType,
		EventType: r.EventType,
		Payload:   r.Payload,
		CreatedAt: parseTime(r.CreatedAt),
	}
}

func supportAgentSkillsToStrings(skills []model.SupportAgentSkill) []string {
	values := make([]string, 0, len(skills))
	for _, skill := range skills {
		if strings.TrimSpace(string(skill)) != "" {
			values = append(values, string(skill))
		}
	}
	return values
}

func supportAgentSkillsFromStrings(values []string) []model.SupportAgentSkill {
	skills := make([]model.SupportAgentSkill, 0, len(values))
	for _, value := range values {
		if skill := model.SupportAgentSkill(strings.TrimSpace(value)); skill != "" {
			skills = append(skills, skill)
		}
	}
	return skills
}

func normalizeSupportFileIDs(values []string) []string {
	if len(values) == 0 {
		return nil
	}
	const maxFileIDs = 10
	out := make([]string, 0, min(len(values), maxFileIDs))
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		fileID := strings.TrimSpace(value)
		if fileID == "" {
			continue
		}
		if len(fileID) > 128 {
			fileID = fileID[:128]
		}
		if _, ok := seen[fileID]; ok {
			continue
		}
		seen[fileID] = struct{}{}
		out = append(out, fileID)
		if len(out) >= maxFileIDs {
			break
		}
	}
	return out
}

func parseOptionalTime(raw string) *time.Time {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil
	}
	value := parseTime(raw)
	if value.IsZero() {
		return nil
	}
	return &value
}

func parseTime(raw string) time.Time {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return time.Time{}
	}
	value, err := time.Parse(time.RFC3339Nano, raw)
	if err != nil {
		return time.Time{}
	}
	return value
}
