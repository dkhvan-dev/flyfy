package repository

import (
	"context"
	"sort"
	"strings"
	"sync"
	"time"

	"kz/inflap/backend/services/support-service/internal/app"
)

type MemoryRepository struct {
	mu            sync.RWMutex
	categories    []app.HelpCategory
	savedReplies  []app.SupportSavedReply
	articles      []app.HelpArticle
	articleEvents []app.HelpArticleEvent
	searchEvents  []app.HelpSearchEvent
	feedback      []app.ArticleFeedback
	csat          []app.SupportTicketCSAT
	tickets       []app.SupportTicket
	events        []app.SupportTicketEvent
	userSegments  map[string]app.SupportUserSegment
	supportAgents []app.SupportAgent
}

func NewMemoryRepository(articles []app.HelpArticle) *MemoryRepository {
	return &MemoryRepository{
		articles: append([]app.HelpArticle(nil), articles...),
	}
}

func (r *MemoryRepository) ListArticles(context.Context) ([]app.HelpArticle, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return append([]app.HelpArticle(nil), r.articles...), nil
}

func (r *MemoryRepository) SearchArticles(_ context.Context, filter app.SearchArticleFilter) ([]app.HelpArticle, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	query := normalizeMemorySearchText(filter.Query)
	if query == "" {
		return []app.HelpArticle{}, nil
	}
	matches := make([]memoryArticleSearchMatch, 0, len(r.articles))
	for _, article := range r.articles {
		if article.Status != app.ArticleStatusPublished {
			continue
		}
		if filter.Surface != "" && !memoryArticleHasSurface(article, filter.Surface) {
			continue
		}
		translation, ok := memoryLocalizedArticle(article, filter.Locale)
		if !ok {
			continue
		}
		score := memoryArticleSearchScore(article, translation, query)
		if score == 0 {
			continue
		}
		matches = append(matches, memoryArticleSearchMatch{
			article: article,
			score:   score,
		})
	}
	sort.SliceStable(matches, func(i, j int) bool {
		if matches[i].score != matches[j].score {
			return matches[i].score > matches[j].score
		}
		if !matches[i].article.UpdatedAt.Equal(matches[j].article.UpdatedAt) {
			return matches[i].article.UpdatedAt.After(matches[j].article.UpdatedAt)
		}
		return matches[i].article.ID < matches[j].article.ID
	})
	limit := filter.Limit
	if limit <= 0 {
		limit = 10
	}
	if len(matches) < limit {
		limit = len(matches)
	}
	result := make([]app.HelpArticle, 0, limit)
	for i := 0; i < limit; i++ {
		result = append(result, matches[i].article)
	}
	return result, nil
}

func (r *MemoryRepository) ListCategories(_ context.Context, filter app.HelpCategoryFilter) ([]app.HelpCategory, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	result := make([]app.HelpCategory, 0, len(r.categories))
	for _, category := range r.categories {
		if filter.Status != "" && category.Status != filter.Status {
			continue
		}
		result = append(result, category)
	}
	sort.SliceStable(result, func(i, j int) bool {
		if result[i].SortOrder != result[j].SortOrder {
			return result[i].SortOrder < result[j].SortOrder
		}
		if result[i].Slug != result[j].Slug {
			return result[i].Slug < result[j].Slug
		}
		return result[i].ID < result[j].ID
	})
	if filter.Offset >= len(result) {
		return []app.HelpCategory{}, nil
	}
	result = result[filter.Offset:]
	if filter.Limit > 0 && len(result) > filter.Limit {
		result = result[:filter.Limit]
	}
	return append([]app.HelpCategory(nil), result...), nil
}

func (r *MemoryRepository) UpsertCategory(_ context.Context, category app.HelpCategory) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for index := range r.categories {
		if r.categories[index].ID != category.ID {
			continue
		}
		if !r.categories[index].CreatedAt.IsZero() {
			category.CreatedAt = r.categories[index].CreatedAt
		}
		r.categories[index] = category
		return nil
	}
	r.categories = append(r.categories, category)
	return nil
}

func (r *MemoryRepository) ListSavedReplies(_ context.Context, filter app.SupportSavedReplyFilter) ([]app.SupportSavedReply, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	result := make([]app.SupportSavedReply, 0, len(r.savedReplies))
	for _, reply := range r.savedReplies {
		if filter.Status != "" && reply.Status != filter.Status {
			continue
		}
		if filter.Category != "" && reply.Category != filter.Category {
			continue
		}
		result = append(result, reply)
	}
	sort.SliceStable(result, func(i, j int) bool {
		if result[i].SortOrder != result[j].SortOrder {
			return result[i].SortOrder < result[j].SortOrder
		}
		return result[i].ID < result[j].ID
	})
	if filter.Offset >= len(result) {
		return []app.SupportSavedReply{}, nil
	}
	result = result[filter.Offset:]
	if filter.Limit > 0 && len(result) > filter.Limit {
		result = result[:filter.Limit]
	}
	return append([]app.SupportSavedReply(nil), result...), nil
}

func (r *MemoryRepository) UpsertSavedReply(_ context.Context, reply app.SupportSavedReply) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for index := range r.savedReplies {
		if r.savedReplies[index].ID != reply.ID {
			continue
		}
		if !r.savedReplies[index].CreatedAt.IsZero() {
			reply.CreatedAt = r.savedReplies[index].CreatedAt
		}
		r.savedReplies[index] = reply
		return nil
	}
	r.savedReplies = append(r.savedReplies, reply)
	return nil
}

func (r *MemoryRepository) ListAdminArticles(_ context.Context, filter app.HelpArticleFilter) ([]app.HelpArticle, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	result := make([]app.HelpArticle, 0, len(r.articles))
	for _, article := range r.articles {
		if filter.Status != "" && article.Status != filter.Status {
			continue
		}
		result = append(result, article)
	}
	if filter.Offset >= len(result) {
		return []app.HelpArticle{}, nil
	}
	result = result[filter.Offset:]
	if filter.Limit > 0 && len(result) > filter.Limit {
		result = result[:filter.Limit]
	}
	return append([]app.HelpArticle(nil), result...), nil
}

func (r *MemoryRepository) GetArticle(_ context.Context, articleID string) (app.HelpArticle, []app.HelpArticleEvent, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, article := range r.articles {
		if article.ID != articleID {
			continue
		}
		events := make([]app.HelpArticleEvent, 0)
		for _, event := range r.articleEvents {
			if event.ArticleID == articleID {
				events = append(events, event)
			}
		}
		return article, events, nil
	}
	return app.HelpArticle{}, nil, app.ErrArticleNotFound
}

func (r *MemoryRepository) UpsertArticle(_ context.Context, article app.HelpArticle, event app.HelpArticleEvent) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for index := range r.articles {
		if r.articles[index].ID == article.ID {
			r.articles[index] = article
			r.articleEvents = append(r.articleEvents, event)
			return nil
		}
	}
	r.articles = append(r.articles, article)
	r.articleEvents = append(r.articleEvents, event)
	return nil
}

func (r *MemoryRepository) SaveHelpSearchEvent(_ context.Context, event app.HelpSearchEvent) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.searchEvents = append(r.searchEvents, event)
	return nil
}

func (r *MemoryRepository) SaveArticleFeedback(_ context.Context, feedback app.ArticleFeedback) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for index := range r.feedback {
		if r.feedback[index].ArticleID == feedback.ArticleID &&
			r.feedback[index].UserID == feedback.UserID {
			r.feedback[index] = feedback
			return nil
		}
	}
	r.feedback = append(r.feedback, feedback)
	return nil
}

func (r *MemoryRepository) CreateSupportTicket(_ context.Context, ticket app.SupportTicket) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if ticket.IdempotencyKey != "" {
		for _, existing := range r.tickets {
			if existing.UserID == ticket.UserID && existing.IdempotencyKey == ticket.IdempotencyKey {
				return app.ErrSupportTicketAlreadyExists
			}
		}
	}
	r.tickets = append(r.tickets, ticket)
	r.events = append(r.events, app.SupportTicketEvent{
		TicketID:  ticket.ID,
		ActorID:   ticket.UserID,
		ActorType: app.SupportActorTypeUser,
		EventType: "ticket_created",
		Payload: map[string]string{
			"category": string(ticket.Category),
			"source":   ticket.Source,
		},
		CreatedAt: ticket.CreatedAt,
	})
	return nil
}

func (r *MemoryRepository) FindSupportTicketByIdempotencyKey(_ context.Context, userID string, idempotencyKey string) (app.SupportTicket, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, ticket := range r.tickets {
		if ticket.UserID == userID && ticket.IdempotencyKey == idempotencyKey {
			return ticket, nil
		}
	}
	return app.SupportTicket{}, app.ErrSupportTicketNotFound
}

func (r *MemoryRepository) ListSupportTickets(_ context.Context, filter app.SupportTicketFilter) ([]app.SupportTicket, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	result := make([]app.SupportTicket, 0, len(r.tickets))
	for _, ticket := range r.tickets {
		if filter.UserID != "" && ticket.UserID != filter.UserID {
			continue
		}
		if filter.Status != "" && ticket.Status != filter.Status {
			continue
		}
		if filter.Category != "" && ticket.Category != filter.Category {
			continue
		}
		if filter.Priority != "" && ticket.Priority != filter.Priority {
			continue
		}
		if filter.AssigneeID != "" && ticket.AssigneeID != filter.AssigneeID {
			continue
		}
		if filter.SLABreached && !app.SupportTicketSLABreached(ticket, time.Now().UTC()) {
			continue
		}
		ticket.LastMessagePreview = supportTicketLastMessagePreview(ticket.ID, r.events)
		result = append(result, ticket)
	}
	if filter.Offset >= len(result) {
		return []app.SupportTicket{}, nil
	}
	result = result[filter.Offset:]
	if filter.Limit > 0 && len(result) > filter.Limit {
		result = result[:filter.Limit]
	}
	return append([]app.SupportTicket(nil), result...), nil
}

func (r *MemoryRepository) GetSupportTicket(_ context.Context, ticketID string) (app.SupportTicket, []app.SupportTicketEvent, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, ticket := range r.tickets {
		if ticket.ID != ticketID {
			continue
		}
		events := make([]app.SupportTicketEvent, 0)
		for _, event := range r.events {
			if event.TicketID == ticketID {
				events = append(events, event)
			}
		}
		ticket.LastMessagePreview = supportTicketLastMessagePreview(ticket.ID, events)
		return ticket, events, nil
	}
	return app.SupportTicket{}, nil, app.ErrSupportTicketNotFound
}

func supportTicketLastMessagePreview(ticketID string, events []app.SupportTicketEvent) string {
	for index := len(events) - 1; index >= 0; index-- {
		event := events[index]
		if event.TicketID != ticketID {
			continue
		}
		if event.EventType != "user_replied" &&
			event.EventType != "agent_replied" &&
			event.EventType != "ticket_resolved" {
			continue
		}
		for _, key := range []string{"message_preview", "message", "resolution"} {
			if value := strings.TrimSpace(event.Payload[key]); value != "" {
				return value
			}
		}
	}
	return ""
}

func (r *MemoryRepository) UpdateSupportTicket(_ context.Context, ticket app.SupportTicket, event app.SupportTicketEvent) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for index := range r.tickets {
		if r.tickets[index].ID == ticket.ID {
			r.tickets[index] = ticket
			r.events = append(r.events, event)
			return nil
		}
	}
	return app.ErrSupportTicketNotFound
}

func (r *MemoryRepository) AppendSupportTicketEvent(_ context.Context, event app.SupportTicketEvent) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.events = append(r.events, event)
	return nil
}

func (r *MemoryRepository) SaveSupportTicketCSAT(_ context.Context, csat app.SupportTicketCSAT, event app.SupportTicketEvent) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for index := range r.csat {
		if r.csat[index].TicketID == csat.TicketID {
			r.csat[index] = csat
			r.events = append(r.events, event)
			return nil
		}
	}
	r.csat = append(r.csat, csat)
	r.events = append(r.events, event)
	return nil
}

func (r *MemoryRepository) GetSupportUserSegment(_ context.Context, userID string) (app.SupportUserSegment, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if r.userSegments == nil {
		return app.SupportUserSegment{}, app.ErrSupportUserSegmentNotFound
	}
	segment, ok := r.userSegments[userID]
	if !ok {
		return app.SupportUserSegment{}, app.ErrSupportUserSegmentNotFound
	}
	return segment, nil
}

func (r *MemoryRepository) UpsertSupportUserSegment(_ context.Context, segment app.SupportUserSegment) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.userSegments == nil {
		r.userSegments = map[string]app.SupportUserSegment{}
	}
	r.userSegments[segment.UserID] = segment
	return nil
}

func (r *MemoryRepository) ListSupportAgents(_ context.Context, filter app.SupportAgentFilter) ([]app.SupportAgent, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	result := make([]app.SupportAgent, 0, len(r.supportAgents))
	for _, agent := range r.supportAgents {
		if filter.Status != "" && agent.Status != filter.Status {
			continue
		}
		result = append(result, agent)
	}
	if filter.Offset >= len(result) {
		return []app.SupportAgent{}, nil
	}
	result = result[filter.Offset:]
	if filter.Limit > 0 && len(result) > filter.Limit {
		result = result[:filter.Limit]
	}
	return append([]app.SupportAgent(nil), result...), nil
}

func (r *MemoryRepository) UpsertSupportAgent(_ context.Context, agent app.SupportAgent) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for index := range r.supportAgents {
		if r.supportAgents[index].StaffID == agent.StaffID {
			r.supportAgents[index] = agent
			return nil
		}
	}
	r.supportAgents = append(r.supportAgents, agent)
	return nil
}

func (r *MemoryRepository) GetHelpAnalytics(_ context.Context, filter app.HelpAnalyticsFilter) (app.HelpAnalyticsSummary, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	limit := filter.Limit
	if limit <= 0 {
		limit = 10
	}
	summary := app.HelpAnalyticsSummary{}
	summary.Searches = buildSearchAnalytics(r.searchEvents, limit)
	summary.Feedback = buildFeedbackAnalytics(r.feedback, limit)
	summary.Tickets = buildTicketAnalytics(r.tickets, r.csat)
	return summary, nil
}

func (r *MemoryRepository) Feedback() []app.ArticleFeedback {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return append([]app.ArticleFeedback(nil), r.feedback...)
}

func (r *MemoryRepository) Tickets() []app.SupportTicket {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return append([]app.SupportTicket(nil), r.tickets...)
}

func (r *MemoryRepository) Events() []app.SupportTicketEvent {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return append([]app.SupportTicketEvent(nil), r.events...)
}

func (r *MemoryRepository) CSAT() []app.SupportTicketCSAT {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return append([]app.SupportTicketCSAT(nil), r.csat...)
}

func buildSearchAnalytics(events []app.HelpSearchEvent, limit int) app.HelpSearchAnalytics {
	result := app.HelpSearchAnalytics{Total: len(events)}
	noResultByQuery := make(map[string]int)
	repeatedByQuery := make(map[string]int)
	for _, event := range events {
		repeatedByQuery[event.Query]++
		if event.ResultCount == 0 {
			result.WithoutResults++
			noResultByQuery[event.Query]++
		}
	}
	if result.Total > 0 {
		result.SuccessRate = float64(result.Total-result.WithoutResults) / float64(result.Total)
	}
	result.TopNoResultQueries = buildQueryStats(noResultByQuery, limit, false)
	result.RepeatedQueries = buildQueryStats(repeatedByQuery, limit, true)
	return result
}

func buildQueryStats(counts map[string]int, limit int, onlyRepeated bool) []app.HelpSearchQueryStat {
	stats := make([]app.HelpSearchQueryStat, 0, len(counts))
	for query, count := range counts {
		if onlyRepeated && count < 2 {
			continue
		}
		stats = append(stats, app.HelpSearchQueryStat{Query: query, Count: count})
	}
	sort.Slice(stats, func(i, j int) bool {
		if stats[i].Count != stats[j].Count {
			return stats[i].Count > stats[j].Count
		}
		return stats[i].Query < stats[j].Query
	})
	if len(stats) > limit {
		stats = stats[:limit]
	}
	return stats
}

func buildFeedbackAnalytics(feedback []app.ArticleFeedback, limit int) app.HelpFeedbackAnalytics {
	result := app.HelpFeedbackAnalytics{Total: len(feedback)}
	statsByArticleID := make(map[string]app.HelpArticleFeedbackStat)
	for _, item := range feedback {
		if item.Helpful {
			result.Helpful++
			continue
		}
		result.NotHelpful++
		if item.EscalatedToSupport {
			result.Escalations++
		}
		stat := statsByArticleID[item.ArticleID]
		stat.ArticleID = item.ArticleID
		stat.Count++
		if item.EscalatedToSupport {
			stat.Escalations++
		}
		statsByArticleID[item.ArticleID] = stat
	}
	if result.Total > 0 {
		result.NotHelpfulRate = float64(result.NotHelpful) / float64(result.Total)
	}
	result.TopNotHelpfulArticles = make([]app.HelpArticleFeedbackStat, 0, len(statsByArticleID))
	for _, stat := range statsByArticleID {
		result.TopNotHelpfulArticles = append(result.TopNotHelpfulArticles, stat)
	}
	sort.Slice(result.TopNotHelpfulArticles, func(i, j int) bool {
		if result.TopNotHelpfulArticles[i].Count != result.TopNotHelpfulArticles[j].Count {
			return result.TopNotHelpfulArticles[i].Count > result.TopNotHelpfulArticles[j].Count
		}
		return result.TopNotHelpfulArticles[i].ArticleID < result.TopNotHelpfulArticles[j].ArticleID
	})
	if len(result.TopNotHelpfulArticles) > limit {
		result.TopNotHelpfulArticles = result.TopNotHelpfulArticles[:limit]
	}
	return result
}

func buildTicketAnalytics(tickets []app.SupportTicket, csat []app.SupportTicketCSAT) app.SupportTicketAnalytics {
	result := app.SupportTicketAnalytics{Total: len(tickets)}
	var firstResponseTotalSeconds int64
	var firstResponseCount int64
	var resolutionTotalSeconds int64
	var resolutionCount int64
	for _, ticket := range tickets {
		switch ticket.Status {
		case app.SupportTicketStatusResolved:
			result.Resolved++
		case app.SupportTicketStatusClosed:
			result.Closed++
		default:
			result.Open++
		}
		if ticket.Status == app.SupportTicketStatusWaitingSupport {
			result.WaitingSupport++
		}
		if ticket.Priority == app.SupportTicketPriorityUrgent {
			result.Urgent++
		}
		if ticket.FirstResponseAt != nil {
			firstResponseTotalSeconds += int64(ticket.FirstResponseAt.Sub(ticket.CreatedAt).Seconds())
			firstResponseCount++
		}
		if ticket.ResolvedAt != nil {
			resolutionTotalSeconds += int64(ticket.ResolvedAt.Sub(ticket.CreatedAt).Seconds())
			resolutionCount++
		}
	}
	if firstResponseCount > 0 {
		result.AverageFirstResponseSeconds = firstResponseTotalSeconds / firstResponseCount
	}
	if resolutionCount > 0 {
		result.AverageResolutionSeconds = resolutionTotalSeconds / resolutionCount
	}
	result.CSATResponses = len(csat)
	if len(csat) > 0 {
		var ratingTotal int
		for _, item := range csat {
			ratingTotal += item.Rating
		}
		result.AverageCSAT = float64(ratingTotal) / float64(len(csat))
	}
	return result
}

type memoryArticleSearchMatch struct {
	article app.HelpArticle
	score   int
}

func memoryLocalizedArticle(article app.HelpArticle, locale string) (app.ArticleTranslation, bool) {
	if len(article.Translations) == 0 {
		return app.ArticleTranslation{}, false
	}
	normalized := normalizeMemoryLocale(locale)
	if translation, ok := article.Translations[normalized]; ok && translation.Title != "" {
		return translation, true
	}
	if dash := strings.IndexByte(normalized, '-'); dash > 0 {
		if translation, ok := article.Translations[normalized[:dash]]; ok && translation.Title != "" {
			return translation, true
		}
	}
	for _, fallback := range []string{"en", "ru", "kk"} {
		if translation, ok := article.Translations[fallback]; ok && translation.Title != "" {
			return translation, true
		}
	}
	return app.ArticleTranslation{}, false
}

func memoryArticleHasSurface(article app.HelpArticle, surface app.HelpSurface) bool {
	for _, item := range article.Surfaces {
		if item == surface {
			return true
		}
	}
	return false
}

func memoryArticleSearchScore(article app.HelpArticle, translation app.ArticleTranslation, query string) int {
	terms := strings.Fields(query)
	if len(terms) == 0 {
		return 0
	}
	score := 0
	tagText := strings.Join(article.Tags, " ")
	for _, term := range terms {
		termScore := memoryWeightedFieldScore(translation.Title, term, 5) +
			memoryWeightedFieldScore(translation.ShortAnswer, term, 4) +
			memoryWeightedFieldScore(translation.Body, term, 2) +
			memoryWeightedFieldScore(tagText, term, 1)
		if termScore == 0 {
			return 0
		}
		score += termScore
	}
	return score
}

func memoryWeightedFieldScore(value string, term string, weight int) int {
	text := normalizeMemorySearchText(value)
	switch {
	case text == "":
		return 0
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

func normalizeMemoryLocale(locale string) string {
	normalized := strings.ToLower(strings.TrimSpace(locale))
	if normalized == "" {
		return "en"
	}
	return strings.ReplaceAll(normalized, "_", "-")
}

func normalizeMemorySearchText(value string) string {
	return strings.Join(strings.Fields(strings.ToLower(strings.TrimSpace(value))), " ")
}
