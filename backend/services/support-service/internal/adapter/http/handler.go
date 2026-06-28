package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"kz/inflap/backend/services/support-service/internal/app"
)

const maxRequestBodyBytes = 64 * 1024

type Handler struct {
	uc *app.HelpUseCase
}

func NewHandler(uc *app.HelpUseCase) *Handler {
	return &Handler{uc: uc}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /v1/help/categories", h.ListHelpCategories)
	mux.HandleFunc("GET /v1/help/articles/contextual", h.ListContextualArticles)
	mux.HandleFunc("GET /v1/help/articles/search", h.SearchArticles)
	mux.HandleFunc("PUT /v1/help/articles/{articleID}/feedback", h.SubmitArticleFeedback)
	mux.HandleFunc("POST /v1/help/articles/{articleID}/feedback", h.SubmitArticleFeedback)
	mux.HandleFunc("POST /v1/support/tickets", h.CreateSupportTicket)
	mux.HandleFunc("GET /v1/support/conversation", h.GetUserSupportConversation)
	mux.HandleFunc("GET /v1/support/tickets", h.ListUserSupportTickets)
	mux.HandleFunc("GET /v1/support/tickets/{ticketID}", h.GetUserSupportTicket)
	mux.HandleFunc("POST /v1/support/tickets/{ticketID}/reply", h.ReplyToUserSupportTicket)
	mux.HandleFunc("POST /v1/support/tickets/{ticketID}/close", h.CloseUserSupportTicket)
	mux.HandleFunc("POST /v1/support/tickets/{ticketID}/csat", h.SubmitSupportTicketCSAT)
	mux.HandleFunc("GET /v1/admin/help/analytics", h.GetAdminHelpAnalytics)
	mux.HandleFunc("GET /v1/admin/help/categories", h.ListAdminHelpCategories)
	mux.HandleFunc("PUT /v1/admin/help/categories/{categoryID}", h.UpsertAdminHelpCategory)
	mux.HandleFunc("GET /v1/admin/help/articles", h.ListAdminHelpArticles)
	mux.HandleFunc("GET /v1/admin/help/articles/{articleID}", h.GetAdminHelpArticle)
	mux.HandleFunc("PUT /v1/admin/help/articles/{articleID}", h.UpsertAdminHelpArticle)
	mux.HandleFunc("POST /v1/admin/help/articles/{articleID}/submit-review", h.SubmitAdminHelpArticleForReview)
	mux.HandleFunc("POST /v1/admin/help/articles/{articleID}/publish", h.PublishAdminHelpArticle)
	mux.HandleFunc("POST /v1/admin/help/articles/{articleID}/archive", h.ArchiveAdminHelpArticle)
	mux.HandleFunc("GET /v1/admin/support/tickets", h.ListAdminSupportTickets)
	mux.HandleFunc("GET /v1/admin/support/agents", h.ListAdminSupportAgents)
	mux.HandleFunc("PUT /v1/admin/support/agents/{staffID}", h.UpsertAdminSupportAgent)
	mux.HandleFunc("GET /v1/admin/support/user-segments/{userID}", h.GetAdminSupportUserSegment)
	mux.HandleFunc("PUT /v1/admin/support/user-segments/{userID}", h.UpsertAdminSupportUserSegment)
	mux.HandleFunc("GET /v1/admin/support/saved-replies", h.ListAdminSupportSavedReplies)
	mux.HandleFunc("PUT /v1/admin/support/saved-replies/{replyID}", h.UpsertAdminSupportSavedReply)
	mux.HandleFunc("GET /v1/admin/support/tickets/{ticketID}", h.GetAdminSupportTicket)
	mux.HandleFunc("POST /v1/admin/support/tickets/{ticketID}/assign", h.AssignAdminSupportTicket)
	mux.HandleFunc("POST /v1/admin/support/tickets/{ticketID}/reply", h.ReplyToAdminSupportTicket)
	mux.HandleFunc("POST /v1/admin/support/tickets/{ticketID}/notes", h.AddAdminSupportTicketNote)
	mux.HandleFunc("POST /v1/admin/support/tickets/{ticketID}/resolve", h.ResolveAdminSupportTicket)
	mux.HandleFunc("POST /v1/admin/support/tickets/{ticketID}/reopen", h.ReopenAdminSupportTicket)
	mux.HandleFunc("GET /", h.NotFound)
	mux.HandleFunc("POST /", h.NotFound)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) NotFound(w http.ResponseWriter, _ *http.Request) {
	writeError(w, http.StatusNotFound, "route_not_found")
}

func (h *Handler) ListContextualArticles(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	result, err := h.uc.ListContextualArticles(r.Context(), app.ListContextualArticlesInput{
		Locale:        query.Get("locale"),
		Surface:       app.HelpSurface(query.Get("surface")),
		CategoryID:    query.Get("categoryId"),
		Tags:          splitCSV(query.Get("tags")),
		UserState:     query.Get("userState"),
		PaymentStatus: query.Get("paymentStatus"),
		Limit:         parseLimit(query.Get("limit")),
		Offset:        parseLimit(query.Get("offset")),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) ListHelpCategories(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	result, err := h.uc.ListHelpCategories(r.Context(), app.ListHelpCategoriesInput{
		Locale:  query.Get("locale"),
		Surface: app.HelpSurface(query.Get("surface")),
		Limit:   parseLimit(query.Get("limit")),
		Offset:  parseLimit(query.Get("offset")),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	items := make([]helpCategoryResponse, 0, len(result.Items))
	for _, category := range result.Items {
		items = append(items, helpCategoryPayload(category))
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (h *Handler) SearchArticles(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	result, err := h.uc.SearchArticles(r.Context(), app.SearchArticlesInput{
		Locale:  query.Get("locale"),
		Query:   query.Get("q"),
		Surface: app.HelpSurface(query.Get("surface")),
		Limit:   parseLimit(query.Get("limit")),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) SubmitArticleFeedback(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	var req articleFeedbackRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}

	if err := h.uc.SubmitArticleFeedback(r.Context(), app.SubmitArticleFeedbackInput{
		ArticleID:          r.PathValue("articleID"),
		UserID:             trustedUserID(r),
		Locale:             req.Locale,
		Helpful:            req.Helpful,
		Reason:             req.Reason,
		EscalatedToSupport: req.EscalatedToSupport,
	}); err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusAccepted, map[string]string{"status": "accepted"})
}

func (h *Handler) CreateSupportTicket(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	var req createSupportTicketRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}

	ticket, err := h.uc.CreateSupportTicket(r.Context(), app.CreateSupportTicketInput{
		UserID:         trustedUserID(r),
		Category:       app.SupportTicketCategory(req.Category),
		Source:         req.Source,
		Locale:         req.Locale,
		Context:        req.Context,
		IdempotencyKey: r.Header.Get("Idempotency-Key"),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, supportTicketPayload(ticket))
}

func (h *Handler) ListUserSupportTickets(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	tickets, err := h.uc.ListUserSupportTickets(r.Context(), app.ListUserSupportTicketsInput{
		UserID: trustedUserID(r),
		Status: app.SupportTicketStatus(query.Get("status")),
		Limit:  parseLimit(query.Get("limit")),
		Offset: parseLimit(query.Get("offset")),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	items := make([]supportTicketResponse, 0, len(tickets))
	for _, ticket := range tickets {
		items = append(items, supportTicketPayload(ticket))
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (h *Handler) GetUserSupportConversation(w http.ResponseWriter, r *http.Request) {
	detail, err := h.uc.GetOrCreateUserSupportConversation(r.Context(), app.GetOrCreateUserSupportConversationInput{
		UserID: trustedUserID(r),
		Locale: r.URL.Query().Get("locale"),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ticket": supportTicketPayload(detail.Ticket),
		"events": supportTicketEventsPayload(detail.Events),
	})
}

func (h *Handler) GetUserSupportTicket(w http.ResponseWriter, r *http.Request) {
	detail, err := h.uc.GetUserSupportTicket(r.Context(), trustedUserID(r), r.PathValue("ticketID"))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ticket": supportTicketPayload(detail.Ticket),
		"events": supportTicketEventsPayload(detail.Events),
	})
}

func (h *Handler) CloseUserSupportTicket(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()
	var req closeSupportTicketRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	ticket, err := h.uc.CloseUserSupportTicket(r.Context(), app.CloseUserSupportTicketInput{
		UserID:   trustedUserID(r),
		TicketID: r.PathValue("ticketID"),
		Reason:   req.Reason,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ticket": supportTicketPayload(ticket)})
}

func (h *Handler) ReplyToUserSupportTicket(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()
	var req replySupportTicketRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	ticket, err := h.uc.ReplyToUserSupportTicket(r.Context(), app.ReplyToUserSupportTicketInput{
		UserID:         trustedUserID(r),
		TicketID:       r.PathValue("ticketID"),
		Message:        req.Message,
		ActorNickname:  req.ActorNickname,
		FileIDs:        req.FileIDs,
		MessageID:      req.MessageID,
		IdempotencyKey: r.Header.Get("Idempotency-Key"),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ticket": supportTicketPayload(ticket)})
}

func (h *Handler) SubmitSupportTicketCSAT(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()
	var req supportTicketCSATRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	if err := h.uc.SubmitSupportTicketCSAT(r.Context(), app.SubmitSupportTicketCSATInput{
		UserID:   trustedUserID(r),
		TicketID: r.PathValue("ticketID"),
		Rating:   req.Rating,
		Comment:  req.Comment,
	}); err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusAccepted, map[string]string{"status": "accepted"})
}

func (h *Handler) GetAdminHelpAnalytics(w http.ResponseWriter, r *http.Request) {
	if !requireHelpAnalyticsRead(w, r) {
		return
	}
	summary, err := h.uc.GetHelpAnalytics(r.Context(), app.GetHelpAnalyticsInput{
		Limit: parseLimit(r.URL.Query().Get("limit")),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, helpAnalyticsPayload(summary))
}

func (h *Handler) ListAdminHelpCategories(w http.ResponseWriter, r *http.Request) {
	if !requireHelpContentRead(w, r) {
		return
	}
	query := r.URL.Query()
	categories, err := h.uc.ListAdminHelpCategories(r.Context(), app.HelpCategoryFilter{
		Status: app.ArticleStatus(query.Get("status")),
		Locale: query.Get("locale"),
		Limit:  parseLimit(query.Get("limit")),
		Offset: parseLimit(query.Get("offset")),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	items := make([]helpCategoryResponse, 0, len(categories))
	for _, category := range categories {
		items = append(items, helpCategoryPayload(category))
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (h *Handler) UpsertAdminHelpCategory(w http.ResponseWriter, r *http.Request) {
	if !requireHelpContentEdit(w, r) {
		return
	}
	defer r.Body.Close()
	var req upsertHelpCategoryRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	category, err := h.uc.UpsertAdminHelpCategory(r.Context(), app.UpsertHelpCategoryInput{
		CategoryID: r.PathValue("categoryID"),
		Slug:       req.Slug,
		Status:     app.ArticleStatus(req.Status),
		SortOrder:  req.SortOrder,
		ActorID:    trustedUserID(r),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"category": helpCategoryPayload(category)})
}

func (h *Handler) ListAdminHelpArticles(w http.ResponseWriter, r *http.Request) {
	if !requireHelpContentRead(w, r) {
		return
	}
	query := r.URL.Query()
	articles, err := h.uc.ListAdminHelpArticles(r.Context(), app.ListAdminHelpArticlesInput{
		Status: app.ArticleStatus(query.Get("status")),
		Limit:  parseLimit(query.Get("limit")),
		Offset: parseLimit(query.Get("offset")),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	items := make([]helpArticleResponse, 0, len(articles))
	for _, article := range articles {
		items = append(items, helpArticlePayload(article))
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (h *Handler) GetAdminHelpArticle(w http.ResponseWriter, r *http.Request) {
	if !requireHelpContentRead(w, r) {
		return
	}
	article, events, err := h.uc.GetAdminHelpArticle(r.Context(), r.PathValue("articleID"))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"article": helpArticlePayload(article),
		"events":  helpArticleEventsPayload(events),
	})
}

func (h *Handler) UpsertAdminHelpArticle(w http.ResponseWriter, r *http.Request) {
	if !requireHelpContentEdit(w, r) {
		return
	}
	defer r.Body.Close()
	var req upsertHelpArticleRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	article, err := h.uc.UpsertHelpArticle(r.Context(), app.UpsertHelpArticleInput{
		ActorID: trustedUserID(r),
		Article: req.toArticle(r.PathValue("articleID")),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"article": helpArticlePayload(article)})
}

func (h *Handler) SubmitAdminHelpArticleForReview(w http.ResponseWriter, r *http.Request) {
	if !requireHelpContentEdit(w, r) {
		return
	}
	article, err := h.uc.SubmitHelpArticleForReview(r.Context(), r.PathValue("articleID"), trustedUserID(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"article": helpArticlePayload(article)})
}

func (h *Handler) PublishAdminHelpArticle(w http.ResponseWriter, r *http.Request) {
	if !requireHelpContentPublish(w, r) {
		return
	}
	article, err := h.uc.PublishHelpArticle(r.Context(), r.PathValue("articleID"), trustedUserID(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"article": helpArticlePayload(article)})
}

func (h *Handler) ArchiveAdminHelpArticle(w http.ResponseWriter, r *http.Request) {
	if !requireHelpContentPublish(w, r) {
		return
	}
	article, err := h.uc.ArchiveHelpArticle(r.Context(), r.PathValue("articleID"), trustedUserID(r))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"article": helpArticlePayload(article)})
}

func (h *Handler) ListAdminSupportTickets(w http.ResponseWriter, r *http.Request) {
	if !requireSupportRead(w, r) {
		return
	}
	query := r.URL.Query()
	tickets, err := h.uc.ListSupportTickets(r.Context(), app.ListSupportTicketsInput{
		Status:      app.SupportTicketStatus(query.Get("status")),
		Category:    app.SupportTicketCategory(query.Get("category")),
		Priority:    app.SupportTicketPriority(query.Get("priority")),
		AssigneeID:  query.Get("assigneeId"),
		SLABreached: strings.EqualFold(strings.TrimSpace(query.Get("sla")), "breached"),
		Limit:       parseLimit(query.Get("limit")),
		Offset:      parseLimit(query.Get("offset")),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	items := make([]supportTicketResponse, 0, len(tickets))
	for _, ticket := range tickets {
		items = append(items, supportTicketPayload(ticket))
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (h *Handler) ListAdminSupportAgents(w http.ResponseWriter, r *http.Request) {
	if !requireSupportManage(w, r) {
		return
	}
	query := r.URL.Query()
	agents, err := h.uc.ListSupportAgents(r.Context(), app.ListSupportAgentsInput{
		Status: app.SupportAgentStatus(query.Get("status")),
		Limit:  parseLimit(query.Get("limit")),
		Offset: parseLimit(query.Get("offset")),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	items := make([]supportAgentResponse, 0, len(agents))
	for _, agent := range agents {
		items = append(items, supportAgentPayload(agent))
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (h *Handler) UpsertAdminSupportAgent(w http.ResponseWriter, r *http.Request) {
	if !requireSupportManage(w, r) {
		return
	}
	defer r.Body.Close()
	var req upsertSupportAgentRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	agent, err := h.uc.UpsertSupportAgent(r.Context(), app.UpsertSupportAgentInput{
		ActorID:       trustedUserID(r),
		StaffID:       r.PathValue("staffID"),
		DisplayName:   req.DisplayName,
		FirstName:     req.FirstName,
		LastName:      req.LastName,
		MiddleName:    req.MiddleName,
		Status:        app.SupportAgentStatus(req.Status),
		Languages:     req.Languages,
		Skills:        supportAgentSkillsFromStrings(req.Skills),
		Level:         app.SupportAgentLevel(req.Level),
		MaxActiveLoad: req.MaxActiveLoad,
		Timezone:      req.Timezone,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"agent": supportAgentPayload(agent)})
}

func (h *Handler) GetAdminSupportUserSegment(w http.ResponseWriter, r *http.Request) {
	if !requireSupportManage(w, r) {
		return
	}
	segment, err := h.uc.GetSupportUserSegment(r.Context(), r.PathValue("userID"))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"segment": supportUserSegmentPayload(segment)})
}

func (h *Handler) UpsertAdminSupportUserSegment(w http.ResponseWriter, r *http.Request) {
	if !requireSupportManage(w, r) {
		return
	}
	defer r.Body.Close()
	var req upsertSupportUserSegmentRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	segment, err := h.uc.UpsertSupportUserSegment(r.Context(), app.UpsertSupportUserSegmentInput{
		ActorID:          trustedUserID(r),
		UserID:           r.PathValue("userID"),
		Nickname:         req.Nickname,
		FollowersCount:   req.FollowersCount,
		IsGuide:          req.IsGuide,
		GuideStatus:      req.GuideStatus,
		IsPublicFigure:   req.IsPublicFigure,
		IsPartner:        req.IsPartner,
		ManualSegment:    app.SupportCustomerSegment(req.ManualSegment),
		ManualReason:     req.ManualReason,
		SubscriptionTier: req.SubscriptionTier,
		SourceVersion:    req.SourceVersion,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"segment": supportUserSegmentPayload(segment)})
}

func (h *Handler) ListAdminSupportSavedReplies(w http.ResponseWriter, r *http.Request) {
	if !requireSupportRead(w, r) {
		return
	}
	query := r.URL.Query()
	replies, err := h.uc.ListSupportSavedReplies(r.Context(), app.SupportSavedReplyFilter{
		Category: query.Get("category"),
		Status:   app.ArticleStatus(query.Get("status")),
		Limit:    parseLimit(query.Get("limit")),
		Offset:   parseLimit(query.Get("offset")),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	items := make([]supportSavedReplyResponse, 0, len(replies))
	for _, reply := range replies {
		items = append(items, supportSavedReplyPayload(reply))
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (h *Handler) UpsertAdminSupportSavedReply(w http.ResponseWriter, r *http.Request) {
	if !requireSupportManage(w, r) {
		return
	}
	defer r.Body.Close()
	var req upsertSupportSavedReplyRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	reply, err := h.uc.UpsertSupportSavedReply(r.Context(), app.UpsertSupportSavedReplyInput{
		ReplyID:      r.PathValue("replyID"),
		ActorID:      trustedUserID(r),
		Category:     req.Category,
		Status:       app.ArticleStatus(req.Status),
		Tags:         req.Tags,
		SortOrder:    req.SortOrder,
		Translations: req.Translations,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"reply": supportSavedReplyPayload(reply)})
}

func (h *Handler) GetAdminSupportTicket(w http.ResponseWriter, r *http.Request) {
	if !requireSupportRead(w, r) {
		return
	}
	ticket, events, err := h.uc.GetSupportTicket(r.Context(), r.PathValue("ticketID"))
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"ticket": supportTicketPayload(ticket),
		"events": supportTicketEventsPayload(events),
	})
}

func (h *Handler) AssignAdminSupportTicket(w http.ResponseWriter, r *http.Request) {
	if !requireSupportWrite(w, r) {
		return
	}
	defer r.Body.Close()
	var req assignSupportTicketRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	ticket, err := h.uc.AssignSupportTicket(r.Context(), app.AssignSupportTicketInput{
		TicketID:   r.PathValue("ticketID"),
		ActorID:    trustedUserID(r),
		AssigneeID: req.AssigneeID,
		Reason:     req.Reason,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ticket": supportTicketPayload(ticket)})
}

func (h *Handler) ReplyToAdminSupportTicket(w http.ResponseWriter, r *http.Request) {
	if !requireSupportWrite(w, r) {
		return
	}
	defer r.Body.Close()
	var req replySupportTicketRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	ticket, err := h.uc.ReplyToSupportTicket(r.Context(), app.ReplyToSupportTicketInput{
		TicketID:         r.PathValue("ticketID"),
		ActorID:          trustedUserID(r),
		ActorDisplayName: trustedActorDisplayName(r),
		Message:          req.Message,
		ConversationID:   req.ConversationID,
		MessageID:        req.MessageID,
		FileIDs:          req.FileIDs,
		IdempotencyKey:   r.Header.Get("Idempotency-Key"),
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ticket": supportTicketPayload(ticket)})
}

func (h *Handler) AddAdminSupportTicketNote(w http.ResponseWriter, r *http.Request) {
	if !requireSupportWrite(w, r) {
		return
	}
	defer r.Body.Close()
	var req supportTicketNoteRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	if err := h.uc.AddSupportTicketNote(r.Context(), app.AddSupportTicketNoteInput{
		TicketID: r.PathValue("ticketID"),
		ActorID:  trustedUserID(r),
		Note:     req.Note,
	}); err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusAccepted, map[string]string{"status": "accepted"})
}

func (h *Handler) ResolveAdminSupportTicket(w http.ResponseWriter, r *http.Request) {
	if !requireSupportWrite(w, r) {
		return
	}
	defer r.Body.Close()
	var req resolveSupportTicketRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	ticket, err := h.uc.ResolveSupportTicket(r.Context(), app.ResolveSupportTicketInput{
		TicketID:   r.PathValue("ticketID"),
		ActorID:    trustedUserID(r),
		Resolution: req.Resolution,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ticket": supportTicketPayload(ticket)})
}

func (h *Handler) ReopenAdminSupportTicket(w http.ResponseWriter, r *http.Request) {
	if !requireSupportWrite(w, r) {
		return
	}
	defer r.Body.Close()
	var req reopenSupportTicketRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request")
		return
	}
	ticket, err := h.uc.ReopenSupportTicket(r.Context(), app.ReopenSupportTicketInput{
		TicketID: r.PathValue("ticketID"),
		ActorID:  trustedUserID(r),
		Reason:   req.Reason,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ticket": supportTicketPayload(ticket)})
}

type articleFeedbackRequest struct {
	Locale             string `json:"locale"`
	Helpful            bool   `json:"helpful"`
	Reason             string `json:"reason"`
	EscalatedToSupport bool   `json:"escalatedToSupport"`
}

type createSupportTicketRequest struct {
	Category string            `json:"category"`
	Source   string            `json:"source"`
	Locale   string            `json:"locale"`
	Context  map[string]string `json:"context"`
}

type upsertHelpCategoryRequest struct {
	Slug      string `json:"slug"`
	Status    string `json:"status"`
	SortOrder int    `json:"sortOrder"`
}

type upsertHelpArticleRequest struct {
	Slug              string                               `json:"slug"`
	CategoryID        string                               `json:"categoryId"`
	Status            string                               `json:"status"`
	Tags              []string                             `json:"tags"`
	Surfaces          []string                             `json:"surfaces"`
	Visibility        app.ArticleVisibility                `json:"visibility"`
	Translations      map[string]articleTranslationRequest `json:"translations"`
	Actions           []app.ArticleAction                  `json:"actions"`
	RelatedArticleIDs []string                             `json:"relatedArticleIds"`
}

type articleTranslationRequest struct {
	Title       string `json:"title"`
	ShortAnswer string `json:"shortAnswer"`
	Body        string `json:"body"`
}

func (r upsertHelpArticleRequest) toArticle(articleID string) app.HelpArticle {
	translations := make(map[string]app.ArticleTranslation, len(r.Translations))
	for locale, translation := range r.Translations {
		translations[locale] = app.ArticleTranslation{
			Title:       translation.Title,
			ShortAnswer: translation.ShortAnswer,
			Body:        translation.Body,
		}
	}
	surfaces := make([]app.HelpSurface, 0, len(r.Surfaces))
	for _, surface := range r.Surfaces {
		surfaces = append(surfaces, app.HelpSurface(surface))
	}
	return app.HelpArticle{
		ID:                articleID,
		Slug:              r.Slug,
		CategoryID:        r.CategoryID,
		Status:            app.ArticleStatus(r.Status),
		Tags:              r.Tags,
		Surfaces:          surfaces,
		Visibility:        r.Visibility,
		Translations:      translations,
		Actions:           r.Actions,
		RelatedArticleIDs: r.RelatedArticleIDs,
	}
}

type helpArticleResponse struct {
	ID                string                            `json:"id"`
	CategoryID        string                            `json:"categoryId,omitempty"`
	Slug              string                            `json:"slug"`
	Status            string                            `json:"status"`
	Version           int                               `json:"version"`
	OwnerID           string                            `json:"ownerId,omitempty"`
	ReviewerID        string                            `json:"reviewerId,omitempty"`
	Tags              []string                          `json:"tags"`
	Surfaces          []string                          `json:"surfaces"`
	Visibility        app.ArticleVisibility             `json:"visibility"`
	Translations      map[string]articleTranslationItem `json:"translations"`
	Actions           []app.ArticleAction               `json:"actions"`
	RelatedArticleIDs []string                          `json:"relatedArticleIds"`
	PublishedAt       string                            `json:"publishedAt,omitempty"`
	LastReviewedAt    string                            `json:"lastReviewedAt,omitempty"`
	CreatedAt         string                            `json:"createdAt,omitempty"`
	UpdatedAt         string                            `json:"updatedAt,omitempty"`
}

type articleTranslationItem struct {
	Title       string `json:"title"`
	ShortAnswer string `json:"shortAnswer"`
	Body        string `json:"body"`
}

type helpCategoryResponse struct {
	ID           string `json:"id"`
	Slug         string `json:"slug"`
	Title        string `json:"title,omitempty"`
	Status       string `json:"status"`
	SortOrder    int    `json:"sortOrder"`
	ArticleCount int    `json:"articleCount,omitempty"`
	CreatedAt    string `json:"createdAt,omitempty"`
	UpdatedAt    string `json:"updatedAt,omitempty"`
}

type helpArticleEventResponse struct {
	ArticleID string            `json:"articleId"`
	ActorID   string            `json:"actorId"`
	ActorType string            `json:"actorType"`
	EventType string            `json:"eventType"`
	Payload   map[string]string `json:"payload"`
	CreatedAt string            `json:"createdAt"`
}

type supportTicketResponse struct {
	ID                         string            `json:"id"`
	UserID                     string            `json:"userId,omitempty"`
	ConversationID             string            `json:"conversationId,omitempty"`
	Status                     string            `json:"status"`
	Category                   string            `json:"category"`
	Priority                   string            `json:"priority"`
	PriorityReasonCodes        []string          `json:"priorityReasonCodes,omitempty"`
	CustomerSegment            string            `json:"customerSegment"`
	CustomerSegmentReasonCodes []string          `json:"customerSegmentReasonCodes,omitempty"`
	SegmentRefreshStatus       string            `json:"segmentRefreshStatus,omitempty"`
	UserNicknameSnapshot       string            `json:"userNicknameSnapshot,omitempty"`
	FollowersCountSnapshot     int               `json:"followersCountSnapshot,omitempty"`
	GuideStatusSnapshot        string            `json:"guideStatusSnapshot,omitempty"`
	SubscriptionTierSnapshot   string            `json:"subscriptionTierSnapshot,omitempty"`
	Source                     string            `json:"source,omitempty"`
	Locale                     string            `json:"locale,omitempty"`
	AssigneeID                 string            `json:"assigneeId,omitempty"`
	AssignmentStatus           string            `json:"assignmentStatus,omitempty"`
	AssignmentReason           string            `json:"assignmentReason,omitempty"`
	AssignmentReasonCodes      []string          `json:"assignmentReasonCodes,omitempty"`
	AssignedAt                 string            `json:"assignedAt,omitempty"`
	Context                    map[string]string `json:"context"`
	FirstResponseAt            string            `json:"firstResponseAt,omitempty"`
	ResolvedAt                 string            `json:"resolvedAt,omitempty"`
	LastMessagePreview         string            `json:"lastMessagePreview,omitempty"`
	LastMessageAt              string            `json:"lastMessageAt,omitempty"`
	CreatedAt                  string            `json:"createdAt,omitempty"`
	UpdatedAt                  string            `json:"updatedAt,omitempty"`
}

type supportTicketEventResponse struct {
	TicketID  string            `json:"ticketId"`
	ActorID   string            `json:"actorId"`
	ActorType string            `json:"actorType"`
	EventType string            `json:"eventType"`
	Payload   map[string]string `json:"payload"`
	CreatedAt string            `json:"createdAt"`
}

type supportSavedReplyResponse struct {
	ID           string                                      `json:"id"`
	Category     string                                      `json:"category"`
	Status       string                                      `json:"status"`
	Tags         []string                                    `json:"tags"`
	SortOrder    int                                         `json:"sortOrder"`
	Translations map[string]app.SupportSavedReplyTranslation `json:"translations"`
	CreatedAt    string                                      `json:"createdAt,omitempty"`
	UpdatedAt    string                                      `json:"updatedAt,omitempty"`
}

type supportAgentResponse struct {
	StaffID       string   `json:"staffId"`
	DisplayName   string   `json:"displayName"`
	FirstName     string   `json:"firstName"`
	LastName      string   `json:"lastName"`
	MiddleName    string   `json:"middleName,omitempty"`
	Status        string   `json:"status"`
	Languages     []string `json:"languages"`
	Skills        []string `json:"skills"`
	Level         string   `json:"level"`
	MaxActiveLoad float64  `json:"maxActiveLoad"`
	Timezone      string   `json:"timezone,omitempty"`
	UpdatedAt     string   `json:"updatedAt,omitempty"`
}

type supportUserSegmentResponse struct {
	UserID           string   `json:"userId"`
	Nickname         string   `json:"nickname,omitempty"`
	CustomerSegment  string   `json:"customerSegment"`
	FollowersCount   int      `json:"followersCount"`
	IsGuide          bool     `json:"isGuide"`
	GuideStatus      string   `json:"guideStatus,omitempty"`
	IsPublicFigure   bool     `json:"isPublicFigure"`
	IsPartner        bool     `json:"isPartner"`
	ManualSegment    string   `json:"manualSegment,omitempty"`
	ManualReason     string   `json:"manualReason,omitempty"`
	SubscriptionTier string   `json:"subscriptionTier,omitempty"`
	ReasonCodes      []string `json:"reasonCodes"`
	RefreshStatus    string   `json:"refreshStatus"`
	UpdatedAt        string   `json:"updatedAt,omitempty"`
	SourceVersion    string   `json:"sourceVersion,omitempty"`
}

type helpAnalyticsResponse struct {
	GeneratedAt string                         `json:"generatedAt"`
	Searches    helpSearchAnalyticsResponse    `json:"searches"`
	Feedback    helpFeedbackAnalyticsResponse  `json:"feedback"`
	Tickets     supportTicketAnalyticsResponse `json:"tickets"`
}

type helpSearchAnalyticsResponse struct {
	Total              int                       `json:"total"`
	WithoutResults     int                       `json:"withoutResults"`
	SuccessRate        float64                   `json:"successRate"`
	TopNoResultQueries []helpSearchQueryResponse `json:"topNoResultQueries"`
	RepeatedQueries    []helpSearchQueryResponse `json:"repeatedQueries"`
}

type helpSearchQueryResponse struct {
	Query string `json:"query"`
	Count int    `json:"count"`
}

type helpFeedbackAnalyticsResponse struct {
	Total                 int                           `json:"total"`
	Helpful               int                           `json:"helpful"`
	NotHelpful            int                           `json:"notHelpful"`
	Escalations           int                           `json:"escalations"`
	NotHelpfulRate        float64                       `json:"notHelpfulRate"`
	TopNotHelpfulArticles []helpArticleFeedbackResponse `json:"topNotHelpfulArticles"`
}

type helpArticleFeedbackResponse struct {
	ArticleID   string `json:"articleId"`
	Count       int    `json:"count"`
	Escalations int    `json:"escalations"`
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

type assignSupportTicketRequest struct {
	AssigneeID string `json:"assigneeId"`
	Reason     string `json:"reason"`
}

type upsertSupportSavedReplyRequest struct {
	Category     string                                      `json:"category"`
	Status       string                                      `json:"status"`
	Tags         []string                                    `json:"tags"`
	SortOrder    int                                         `json:"sortOrder"`
	Translations map[string]app.SupportSavedReplyTranslation `json:"translations"`
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

type replySupportTicketRequest struct {
	Message        string   `json:"message"`
	ActorNickname  string   `json:"actorNickname"`
	ConversationID string   `json:"conversationId"`
	MessageID      string   `json:"messageId"`
	FileIDs        []string `json:"fileIds"`
}

type supportTicketNoteRequest struct {
	Note string `json:"note"`
}

type resolveSupportTicketRequest struct {
	Resolution string `json:"resolution"`
}

type reopenSupportTicketRequest struct {
	Reason string `json:"reason"`
}

type closeSupportTicketRequest struct {
	Reason string `json:"reason"`
}

type supportTicketCSATRequest struct {
	Rating  int    `json:"rating"`
	Comment string `json:"comment"`
}

func decodeJSON(w http.ResponseWriter, r *http.Request, out any) error {
	decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, maxRequestBodyBytes))
	decoder.DisallowUnknownFields()
	return decoder.Decode(out)
}

func trustedUserID(r *http.Request) string {
	return strings.TrimSpace(r.Header.Get("X-User-Id"))
}

func trustedActorDisplayName(r *http.Request) string {
	return strings.TrimSpace(r.Header.Get("X-Actor-Display-Name"))
}

func requireSupportRead(w http.ResponseWriter, r *http.Request) bool {
	if trustedUserID(r) == "" {
		writeError(w, http.StatusUnauthorized, "auth_required")
		return false
	}
	if hasAnyRole(r, "SUPER_ADMIN", "ADMIN", "SUPPORT_VIEWER", "SUPPORT_AGENT", "SUPPORT_LEAD", "SUPPORT_ADMIN") {
		return true
	}
	writeError(w, http.StatusForbidden, "support_role_required")
	return false
}

func requireSupportWrite(w http.ResponseWriter, r *http.Request) bool {
	if trustedUserID(r) == "" {
		writeError(w, http.StatusUnauthorized, "auth_required")
		return false
	}
	if hasAnyRole(r, "SUPER_ADMIN", "ADMIN", "SUPPORT_AGENT", "SUPPORT_LEAD", "SUPPORT_ADMIN") {
		return true
	}
	writeError(w, http.StatusForbidden, "support_role_required")
	return false
}

func requireSupportManage(w http.ResponseWriter, r *http.Request) bool {
	if trustedUserID(r) == "" {
		writeError(w, http.StatusUnauthorized, "auth_required")
		return false
	}
	if hasAnyRole(r, "SUPER_ADMIN", "ADMIN", "SUPPORT_LEAD", "SUPPORT_ADMIN") {
		return true
	}
	writeError(w, http.StatusForbidden, "support_manage_role_required")
	return false
}

func requireHelpContentRead(w http.ResponseWriter, r *http.Request) bool {
	if trustedUserID(r) == "" {
		writeError(w, http.StatusUnauthorized, "auth_required")
		return false
	}
	if hasAnyRole(r, "SUPER_ADMIN", "ADMIN", "HELP_CONTENT_EDITOR", "HELP_CONTENT_PUBLISHER") {
		return true
	}
	writeError(w, http.StatusForbidden, "help_content_role_required")
	return false
}

func requireHelpContentEdit(w http.ResponseWriter, r *http.Request) bool {
	if trustedUserID(r) == "" {
		writeError(w, http.StatusUnauthorized, "auth_required")
		return false
	}
	if hasAnyRole(r, "SUPER_ADMIN", "ADMIN", "HELP_CONTENT_EDITOR", "HELP_CONTENT_PUBLISHER") {
		return true
	}
	writeError(w, http.StatusForbidden, "help_content_role_required")
	return false
}

func requireHelpContentPublish(w http.ResponseWriter, r *http.Request) bool {
	if trustedUserID(r) == "" {
		writeError(w, http.StatusUnauthorized, "auth_required")
		return false
	}
	if hasAnyRole(r, "SUPER_ADMIN", "ADMIN", "HELP_CONTENT_PUBLISHER") {
		return true
	}
	writeError(w, http.StatusForbidden, "help_content_publisher_role_required")
	return false
}

func requireHelpAnalyticsRead(w http.ResponseWriter, r *http.Request) bool {
	if trustedUserID(r) == "" {
		writeError(w, http.StatusUnauthorized, "auth_required")
		return false
	}
	if hasAnyRole(
		r,
		"SUPER_ADMIN",
		"ADMIN",
		"SUPPORT_VIEWER",
		"SUPPORT_AGENT",
		"SUPPORT_LEAD",
		"SUPPORT_ADMIN",
		"HELP_CONTENT_EDITOR",
		"HELP_CONTENT_PUBLISHER",
	) {
		return true
	}
	writeError(w, http.StatusForbidden, "help_analytics_role_required")
	return false
}

func hasAnyRole(r *http.Request, allowed ...string) bool {
	lookup := make(map[string]struct{}, len(allowed))
	for _, role := range allowed {
		lookup[strings.ToUpper(strings.TrimSpace(role))] = struct{}{}
	}
	for _, role := range splitCSV(r.Header.Get("X-User-Roles")) {
		if _, ok := lookup[strings.ToUpper(role)]; ok {
			return true
		}
	}
	return false
}

func splitCSV(value string) []string {
	parts := strings.Split(value, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func parseLimit(value string) int {
	limit, err := strconv.Atoi(strings.TrimSpace(value))
	if err != nil {
		return 0
	}
	return limit
}

func writeAppError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, app.ErrInvalidUser):
		writeError(w, http.StatusUnauthorized, "auth_required")
	case errors.Is(err, app.ErrInvalidSupportAdminAction):
		writeError(w, http.StatusBadRequest, "invalid_request")
	case errors.Is(err, app.ErrInvalidFeedback), errors.Is(err, app.ErrInvalidTicket), errors.Is(err, app.ErrInvalidHelpArticle):
		writeError(w, http.StatusBadRequest, "invalid_request")
	case errors.Is(err, app.ErrArticleNotFound):
		writeError(w, http.StatusNotFound, "article_not_found")
	case errors.Is(err, app.ErrSupportTicketNotFound):
		writeError(w, http.StatusNotFound, "ticket_not_found")
	case errors.Is(err, app.ErrRepositoryFailed):
		writeError(w, http.StatusServiceUnavailable, "service_unavailable")
	default:
		writeError(w, http.StatusInternalServerError, "internal_error")
	}
}

func writeError(w http.ResponseWriter, status int, code string) {
	writeJSON(w, status, map[string]string{"error": code})
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func helpCategoryPayload(category app.HelpCategory) helpCategoryResponse {
	return helpCategoryResponse{
		ID:           category.ID,
		Slug:         category.Slug,
		Title:        category.Title,
		Status:       string(category.Status),
		SortOrder:    category.SortOrder,
		ArticleCount: category.ArticleCount,
		CreatedAt:    formatTime(category.CreatedAt),
		UpdatedAt:    formatTime(category.UpdatedAt),
	}
}

func helpArticlePayload(article app.HelpArticle) helpArticleResponse {
	translations := make(map[string]articleTranslationItem, len(article.Translations))
	for locale, translation := range article.Translations {
		translations[locale] = articleTranslationItem{
			Title:       translation.Title,
			ShortAnswer: translation.ShortAnswer,
			Body:        translation.Body,
		}
	}
	surfaces := make([]string, 0, len(article.Surfaces))
	for _, surface := range article.Surfaces {
		surfaces = append(surfaces, string(surface))
	}
	payload := helpArticleResponse{
		ID:                article.ID,
		CategoryID:        article.CategoryID,
		Slug:              article.Slug,
		Status:            string(article.Status),
		Version:           article.Version,
		OwnerID:           article.OwnerID,
		ReviewerID:        article.ReviewerID,
		Tags:              article.Tags,
		Surfaces:          surfaces,
		Visibility:        article.Visibility,
		Translations:      translations,
		Actions:           article.Actions,
		RelatedArticleIDs: article.RelatedArticleIDs,
		CreatedAt:         formatTime(article.CreatedAt),
		UpdatedAt:         formatTime(article.UpdatedAt),
	}
	if article.PublishedAt != nil {
		payload.PublishedAt = formatTime(*article.PublishedAt)
	}
	if article.LastReviewedAt != nil {
		payload.LastReviewedAt = formatTime(*article.LastReviewedAt)
	}
	return payload
}

func helpArticleEventsPayload(events []app.HelpArticleEvent) []helpArticleEventResponse {
	payload := make([]helpArticleEventResponse, 0, len(events))
	for _, event := range events {
		payload = append(payload, helpArticleEventResponse{
			ArticleID: event.ArticleID,
			ActorID:   event.ActorID,
			ActorType: string(event.ActorType),
			EventType: event.EventType,
			Payload:   event.Payload,
			CreatedAt: formatTime(event.CreatedAt),
		})
	}
	return payload
}

func supportTicketPayload(ticket app.SupportTicket) supportTicketResponse {
	payload := supportTicketResponse{
		ID:                         ticket.ID,
		UserID:                     ticket.UserID,
		ConversationID:             ticket.ConversationID,
		Status:                     string(ticket.Status),
		Category:                   string(ticket.Category),
		Priority:                   string(ticket.Priority),
		PriorityReasonCodes:        append([]string(nil), ticket.PriorityReasonCodes...),
		CustomerSegment:            string(ticket.CustomerSegment),
		CustomerSegmentReasonCodes: append([]string(nil), ticket.CustomerSegmentReasonCodes...),
		SegmentRefreshStatus:       string(ticket.SegmentRefreshStatus),
		UserNicknameSnapshot:       ticket.UserNicknameSnapshot,
		FollowersCountSnapshot:     ticket.FollowersCountSnapshot,
		GuideStatusSnapshot:        ticket.GuideStatusSnapshot,
		SubscriptionTierSnapshot:   ticket.SubscriptionTierSnapshot,
		Source:                     ticket.Source,
		Locale:                     ticket.Locale,
		AssigneeID:                 ticket.AssigneeID,
		AssignmentStatus:           string(ticket.AssignmentStatus),
		AssignmentReason:           ticket.AssignmentReason,
		AssignmentReasonCodes:      append([]string(nil), ticket.AssignmentReasonCodes...),
		Context:                    ticket.Context,
		LastMessagePreview:         ticket.LastMessagePreview,
		LastMessageAt:              formatTime(ticket.LastMessageAt),
		CreatedAt:                  formatTime(ticket.CreatedAt),
		UpdatedAt:                  formatTime(ticket.UpdatedAt),
	}
	if ticket.AssignedAt != nil {
		payload.AssignedAt = formatTime(*ticket.AssignedAt)
	}
	if ticket.FirstResponseAt != nil {
		payload.FirstResponseAt = formatTime(*ticket.FirstResponseAt)
	}
	if ticket.ResolvedAt != nil {
		payload.ResolvedAt = formatTime(*ticket.ResolvedAt)
	}
	return payload
}

func supportTicketEventsPayload(events []app.SupportTicketEvent) []supportTicketEventResponse {
	payload := make([]supportTicketEventResponse, 0, len(events))
	for _, event := range events {
		payload = append(payload, supportTicketEventResponse{
			TicketID:  event.TicketID,
			ActorID:   event.ActorID,
			ActorType: string(event.ActorType),
			EventType: event.EventType,
			Payload:   event.Payload,
			CreatedAt: formatTime(event.CreatedAt),
		})
	}
	return payload
}

func supportSavedReplyPayload(reply app.SupportSavedReply) supportSavedReplyResponse {
	return supportSavedReplyResponse{
		ID:           reply.ID,
		Category:     reply.Category,
		Status:       string(reply.Status),
		Tags:         reply.Tags,
		SortOrder:    reply.SortOrder,
		Translations: reply.Translations,
		CreatedAt:    formatTime(reply.CreatedAt),
		UpdatedAt:    formatTime(reply.UpdatedAt),
	}
}

func supportAgentPayload(agent app.SupportAgent) supportAgentResponse {
	skills := make([]string, 0, len(agent.Skills))
	for _, skill := range agent.Skills {
		skills = append(skills, string(skill))
	}
	return supportAgentResponse{
		StaffID:       agent.StaffID,
		DisplayName:   agent.DisplayName,
		FirstName:     agent.FirstName,
		LastName:      agent.LastName,
		MiddleName:    agent.MiddleName,
		Status:        string(agent.Status),
		Languages:     append([]string(nil), agent.Languages...),
		Skills:        skills,
		Level:         string(agent.Level),
		MaxActiveLoad: agent.MaxActiveLoad,
		Timezone:      agent.Timezone,
		UpdatedAt:     formatTime(agent.UpdatedAt),
	}
}

func supportUserSegmentPayload(segment app.SupportUserSegment) supportUserSegmentResponse {
	return supportUserSegmentResponse{
		UserID:           segment.UserID,
		Nickname:         segment.Nickname,
		CustomerSegment:  string(segment.CustomerSegment),
		FollowersCount:   segment.FollowersCount,
		IsGuide:          segment.IsGuide,
		GuideStatus:      segment.GuideStatus,
		IsPublicFigure:   segment.IsPublicFigure,
		IsPartner:        segment.IsPartner,
		ManualSegment:    string(segment.ManualSegment),
		ManualReason:     segment.ManualReason,
		SubscriptionTier: segment.SubscriptionTier,
		ReasonCodes:      append([]string(nil), segment.ReasonCodes...),
		RefreshStatus:    string(segment.RefreshStatus),
		UpdatedAt:        formatTime(segment.UpdatedAt),
		SourceVersion:    segment.SourceVersion,
	}
}

func supportAgentSkillsFromStrings(values []string) []app.SupportAgentSkill {
	skills := make([]app.SupportAgentSkill, 0, len(values))
	for _, value := range values {
		if skill := app.SupportAgentSkill(strings.TrimSpace(value)); skill != "" {
			skills = append(skills, skill)
		}
	}
	return skills
}

func helpAnalyticsPayload(summary app.HelpAnalyticsSummary) helpAnalyticsResponse {
	noResultQueries := make([]helpSearchQueryResponse, 0, len(summary.Searches.TopNoResultQueries))
	for _, stat := range summary.Searches.TopNoResultQueries {
		noResultQueries = append(noResultQueries, helpSearchQueryResponse{
			Query: stat.Query,
			Count: stat.Count,
		})
	}
	repeatedQueries := make([]helpSearchQueryResponse, 0, len(summary.Searches.RepeatedQueries))
	for _, stat := range summary.Searches.RepeatedQueries {
		repeatedQueries = append(repeatedQueries, helpSearchQueryResponse{
			Query: stat.Query,
			Count: stat.Count,
		})
	}
	notHelpfulArticles := make([]helpArticleFeedbackResponse, 0, len(summary.Feedback.TopNotHelpfulArticles))
	for _, stat := range summary.Feedback.TopNotHelpfulArticles {
		notHelpfulArticles = append(notHelpfulArticles, helpArticleFeedbackResponse{
			ArticleID:   stat.ArticleID,
			Count:       stat.Count,
			Escalations: stat.Escalations,
		})
	}
	return helpAnalyticsResponse{
		GeneratedAt: formatTime(summary.GeneratedAt),
		Searches: helpSearchAnalyticsResponse{
			Total:              summary.Searches.Total,
			WithoutResults:     summary.Searches.WithoutResults,
			SuccessRate:        summary.Searches.SuccessRate,
			TopNoResultQueries: noResultQueries,
			RepeatedQueries:    repeatedQueries,
		},
		Feedback: helpFeedbackAnalyticsResponse{
			Total:                 summary.Feedback.Total,
			Helpful:               summary.Feedback.Helpful,
			NotHelpful:            summary.Feedback.NotHelpful,
			Escalations:           summary.Feedback.Escalations,
			NotHelpfulRate:        summary.Feedback.NotHelpfulRate,
			TopNotHelpfulArticles: notHelpfulArticles,
		},
		Tickets: supportTicketAnalyticsResponse{
			Total:                       summary.Tickets.Total,
			Open:                        summary.Tickets.Open,
			WaitingSupport:              summary.Tickets.WaitingSupport,
			Resolved:                    summary.Tickets.Resolved,
			Closed:                      summary.Tickets.Closed,
			Urgent:                      summary.Tickets.Urgent,
			AverageFirstResponseSeconds: summary.Tickets.AverageFirstResponseSeconds,
			AverageResolutionSeconds:    summary.Tickets.AverageResolutionSeconds,
			CSATResponses:               summary.Tickets.CSATResponses,
			AverageCSAT:                 summary.Tickets.AverageCSAT,
		},
	}
}

func formatTime(value time.Time) string {
	if value.IsZero() {
		return ""
	}
	return value.UTC().Format(time.RFC3339Nano)
}
