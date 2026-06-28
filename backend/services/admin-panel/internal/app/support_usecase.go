package app

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

type SupportUseCase struct {
	client port.SupportClient
	audit  port.AuditRepository
	files  port.FileDownloadClient
}

func NewSupportUseCase(client port.SupportClient, audit port.AuditRepository) *SupportUseCase {
	return &SupportUseCase{client: client, audit: audit}
}

func (u *SupportUseCase) SetFileDownloadClient(files port.FileDownloadClient) {
	if u == nil {
		return
	}
	u.files = files
}

func (u *SupportUseCase) ListTickets(ctx context.Context, actor *model.StaffUser, filter model.SupportTicketFilter) ([]model.SupportTicket, error) {
	if !canReadSupport(actor) {
		return nil, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return nil, ErrIntegrationNotReady
	}
	filter.Limit = clampSupportLimit(filter.Limit)
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	return u.client.ListTickets(ctx, filter)
}

func (u *SupportUseCase) GetTicket(ctx context.Context, actor *model.StaffUser, ticketID string) (model.SupportTicketDetail, error) {
	if !canReadSupport(actor) {
		return model.SupportTicketDetail{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.SupportTicketDetail{}, ErrIntegrationNotReady
	}
	ticketID = strings.TrimSpace(ticketID)
	if ticketID == "" {
		return model.SupportTicketDetail{}, ErrInvalidInput
	}
	return u.client.GetTicket(ctx, ticketID)
}

func (u *SupportUseCase) CreateAttachmentDownloadURL(ctx context.Context, actor *model.StaffUser, ticketID string, eventIndex int, attachmentIndex int) (model.FileDownloadURL, error) {
	if !canReadSupport(actor) {
		return model.FileDownloadURL{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil || u.files == nil {
		return model.FileDownloadURL{}, ErrIntegrationNotReady
	}
	ticketID = strings.TrimSpace(ticketID)
	if ticketID == "" || eventIndex < 0 || attachmentIndex < 0 {
		return model.FileDownloadURL{}, ErrInvalidInput
	}
	detail, err := u.client.GetTicket(ctx, ticketID)
	if err != nil {
		return model.FileDownloadURL{}, err
	}
	fileID, err := supportTicketAttachmentFileID(detail, eventIndex, attachmentIndex)
	if err != nil {
		return model.FileDownloadURL{}, err
	}
	return u.files.CreateDownloadURL(ctx, fileID)
}

func (u *SupportUseCase) AssignTicket(ctx context.Context, actor *model.StaffUser, ticketID string, assigneeID string, reason string, meta RequestMetadata) (model.SupportTicket, error) {
	if !canManageSupport(actor) {
		return model.SupportTicket{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.SupportTicket{}, ErrIntegrationNotReady
	}
	if strings.TrimSpace(ticketID) == "" || strings.TrimSpace(assigneeID) == "" {
		return model.SupportTicket{}, ErrInvalidInput
	}
	reason = strings.TrimSpace(reason)
	if reason == "" {
		return model.SupportTicket{}, ErrInvalidInput
	}
	ticket, err := u.client.AssignTicket(ctx, model.SupportTicketAssignInput{
		TicketID:       strings.TrimSpace(ticketID),
		ActorStaffID:   actor.ID.String(),
		AssigneeID:     strings.TrimSpace(assigneeID),
		Reason:         reason,
		IdempotencyKey: supportIdempotencyKey(meta, ticketID, "assign"),
		RequestID:      strings.TrimSpace(meta.RequestID),
	})
	if err != nil {
		return model.SupportTicket{}, err
	}
	u.appendSupportAudit(ctx, actor, "support.ticket.assign", ticket.ID, meta, map[string]any{"assigneeId": ticket.AssigneeID})
	return ticket, nil
}

func (u *SupportUseCase) ReplyTicket(ctx context.Context, actor *model.StaffUser, input model.SupportTicketReplyInput, meta RequestMetadata) (model.SupportTicket, error) {
	if !canReplySupport(actor) {
		return model.SupportTicket{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.SupportTicket{}, ErrIntegrationNotReady
	}
	input.TicketID = strings.TrimSpace(input.TicketID)
	input.Message = strings.TrimSpace(input.Message)
	if input.TicketID == "" || input.Message == "" {
		return model.SupportTicket{}, ErrInvalidInput
	}
	input.ActorStaffID = actor.ID.String()
	input.ActorDisplayName = u.supportActorChatDisplayName(ctx, actor)
	input.IdempotencyKey = supportIdempotencyKey(meta, input.TicketID, "reply")
	input.RequestID = strings.TrimSpace(meta.RequestID)
	ticket, err := u.client.ReplyTicket(ctx, input)
	if err != nil {
		return model.SupportTicket{}, err
	}
	u.appendSupportAudit(ctx, actor, "support.ticket.reply", ticket.ID, meta, map[string]any{"conversationId": ticket.ConversationID})
	return ticket, nil
}

func (u *SupportUseCase) supportActorChatDisplayName(ctx context.Context, actor *model.StaffUser) string {
	if actor == nil {
		return ""
	}
	actorID := actor.ID.String()
	if u != nil && u.client != nil && actorID != "" {
		if agents, err := u.client.ListSupportAgents(ctx, model.SupportAgentFilter{Limit: 1000}); err == nil {
			for _, agent := range agents {
				if strings.TrimSpace(agent.StaffID) != actorID {
					continue
				}
				if value := supportAgentChatGivenName(agent); value != "" {
					return value
				}
				break
			}
		}
	}
	return supportGivenNameFromFullName(actor.DisplayName)
}

func supportAgentChatGivenName(agent model.SupportAgent) string {
	firstName := strings.TrimSpace(agent.FirstName)
	lastName := strings.TrimSpace(agent.LastName)
	if firstName != "" {
		parts := strings.Fields(strings.TrimSpace(agent.DisplayName))
		if lastName != "" && len(parts) >= 2 && parts[0] == firstName && parts[1] == lastName {
			return lastName
		}
		return firstName
	}
	return supportGivenNameFromFullName(agent.DisplayName)
}

func supportGivenNameFromFullName(value string) string {
	parts := strings.Fields(strings.TrimSpace(value))
	if len(parts) == 0 {
		return ""
	}
	if len(parts) >= 2 {
		return parts[1]
	}
	return parts[0]
}

func (u *SupportUseCase) AddTicketNote(ctx context.Context, actor *model.StaffUser, ticketID string, note string, meta RequestMetadata) error {
	if !canReplySupport(actor) {
		return ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return ErrIntegrationNotReady
	}
	ticketID = strings.TrimSpace(ticketID)
	note = strings.TrimSpace(note)
	if ticketID == "" || note == "" {
		return ErrInvalidInput
	}
	err := u.client.AddTicketNote(ctx, model.SupportTicketNoteInput{
		TicketID:       ticketID,
		ActorStaffID:   actor.ID.String(),
		Note:           note,
		IdempotencyKey: supportIdempotencyKey(meta, ticketID, "note"),
		RequestID:      strings.TrimSpace(meta.RequestID),
	})
	if err != nil {
		return err
	}
	u.appendSupportAudit(ctx, actor, "support.ticket.note", ticketID, meta, nil)
	return nil
}

func (u *SupportUseCase) ResolveTicket(ctx context.Context, actor *model.StaffUser, ticketID string, resolution string, meta RequestMetadata) (model.SupportTicket, error) {
	if !canReplySupport(actor) {
		return model.SupportTicket{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.SupportTicket{}, ErrIntegrationNotReady
	}
	ticketID = strings.TrimSpace(ticketID)
	if ticketID == "" {
		return model.SupportTicket{}, ErrInvalidInput
	}
	ticket, err := u.client.ResolveTicket(ctx, model.SupportTicketResolveInput{
		TicketID:       ticketID,
		ActorStaffID:   actor.ID.String(),
		Resolution:     strings.TrimSpace(resolution),
		IdempotencyKey: supportIdempotencyKey(meta, ticketID, "resolve"),
		RequestID:      strings.TrimSpace(meta.RequestID),
	})
	if err != nil {
		return model.SupportTicket{}, err
	}
	u.appendSupportAudit(ctx, actor, "support.ticket.resolve", ticket.ID, meta, nil)
	return ticket, nil
}

func (u *SupportUseCase) ReopenTicket(ctx context.Context, actor *model.StaffUser, ticketID string, reason string, meta RequestMetadata) (model.SupportTicket, error) {
	if !canReplySupport(actor) {
		return model.SupportTicket{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.SupportTicket{}, ErrIntegrationNotReady
	}
	ticketID = strings.TrimSpace(ticketID)
	if ticketID == "" {
		return model.SupportTicket{}, ErrInvalidInput
	}
	ticket, err := u.client.ReopenTicket(ctx, model.SupportTicketReopenInput{
		TicketID:       ticketID,
		ActorStaffID:   actor.ID.String(),
		Reason:         strings.TrimSpace(reason),
		IdempotencyKey: supportIdempotencyKey(meta, ticketID, "reopen"),
		RequestID:      strings.TrimSpace(meta.RequestID),
	})
	if err != nil {
		return model.SupportTicket{}, err
	}
	u.appendSupportAudit(ctx, actor, "support.ticket.reopen", ticket.ID, meta, nil)
	return ticket, nil
}

func (u *SupportUseCase) ListSupportAgents(ctx context.Context, actor *model.StaffUser, filter model.SupportAgentFilter) ([]model.SupportAgent, error) {
	if !canManageSupport(actor) {
		return nil, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return nil, ErrIntegrationNotReady
	}
	filter.Limit = clampSupportLimit(filter.Limit)
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	return u.client.ListSupportAgents(ctx, filter)
}

func (u *SupportUseCase) UpsertSupportAgent(ctx context.Context, actor *model.StaffUser, input model.SupportAgentUpsertInput, meta RequestMetadata) (model.SupportAgent, error) {
	if !canManageSupport(actor) {
		return model.SupportAgent{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.SupportAgent{}, ErrIntegrationNotReady
	}
	input.StaffID = strings.TrimSpace(input.StaffID)
	input.DisplayName = strings.TrimSpace(input.DisplayName)
	input.FirstName = strings.TrimSpace(input.FirstName)
	input.LastName = strings.TrimSpace(input.LastName)
	input.MiddleName = strings.TrimSpace(input.MiddleName)
	if input.StaffID == "" || input.FirstName == "" || input.LastName == "" {
		return model.SupportAgent{}, ErrInvalidInput
	}
	input.ActorStaffID = actor.ID.String()
	input.IdempotencyKey = supportIdempotencyKey(meta, input.StaffID, "agent-upsert")
	input.RequestID = strings.TrimSpace(meta.RequestID)
	agent, err := u.client.UpsertSupportAgent(ctx, input)
	if err != nil {
		return model.SupportAgent{}, err
	}
	u.appendSupportAudit(ctx, actor, "support.agent.upsert", agent.StaffID, meta, map[string]any{
		"status":        string(agent.Status),
		"level":         string(agent.Level),
		"maxActiveLoad": agent.MaxActiveLoad,
	})
	return agent, nil
}

func (u *SupportUseCase) GetSupportUserSegment(ctx context.Context, actor *model.StaffUser, userID string) (model.SupportUserSegment, error) {
	if !canManageSupport(actor) {
		return model.SupportUserSegment{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.SupportUserSegment{}, ErrIntegrationNotReady
	}
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return model.SupportUserSegment{}, ErrInvalidInput
	}
	return u.client.GetSupportUserSegment(ctx, userID)
}

func (u *SupportUseCase) UpsertSupportUserSegment(ctx context.Context, actor *model.StaffUser, input model.SupportUserSegmentUpsertInput, meta RequestMetadata) (model.SupportUserSegment, error) {
	if !canManageSupport(actor) {
		return model.SupportUserSegment{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.SupportUserSegment{}, ErrIntegrationNotReady
	}
	input.UserID = strings.TrimSpace(input.UserID)
	input.Nickname = strings.TrimSpace(input.Nickname)
	input.GuideStatus = strings.TrimSpace(input.GuideStatus)
	input.ManualReason = strings.TrimSpace(input.ManualReason)
	if input.UserID == "" || input.FollowersCount < 0 {
		return model.SupportUserSegment{}, ErrInvalidInput
	}
	input.ActorStaffID = actor.ID.String()
	input.IdempotencyKey = supportIdempotencyKey(meta, input.UserID, "segment-upsert")
	input.RequestID = strings.TrimSpace(meta.RequestID)
	segment, err := u.client.UpsertSupportUserSegment(ctx, input)
	if err != nil {
		return model.SupportUserSegment{}, err
	}
	u.appendSupportAudit(ctx, actor, "support.user_segment.upsert", segment.UserID, meta, map[string]any{
		"customerSegment": string(segment.CustomerSegment),
		"manualSegment":   string(segment.ManualSegment),
		"reasonCodes":     segment.ReasonCodes,
	})
	return segment, nil
}

func (u *SupportUseCase) ListSupportSavedReplies(ctx context.Context, actor *model.StaffUser, filter model.SupportSavedReplyFilter) ([]model.SupportSavedReply, error) {
	if !canReplySupport(actor) {
		return nil, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return nil, ErrIntegrationNotReady
	}
	filter.Category = strings.TrimSpace(filter.Category)
	filter.Limit = clampSupportLimit(filter.Limit)
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	return u.client.ListSupportSavedReplies(ctx, filter)
}

func (u *SupportUseCase) UpsertSupportSavedReply(ctx context.Context, actor *model.StaffUser, input model.SupportSavedReplyUpsertInput, meta RequestMetadata) (model.SupportSavedReply, error) {
	if !canManageSupport(actor) {
		return model.SupportSavedReply{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.SupportSavedReply{}, ErrIntegrationNotReady
	}
	input.ReplyID = strings.TrimSpace(input.ReplyID)
	input.Category = strings.TrimSpace(input.Category)
	if input.ReplyID == "" {
		return model.SupportSavedReply{}, ErrInvalidInput
	}
	input.ActorStaffID = actor.ID.String()
	input.IdempotencyKey = supportSavedReplyIdempotencyKey(meta, input.ReplyID, "upsert")
	input.RequestID = strings.TrimSpace(meta.RequestID)
	reply, err := u.client.UpsertSupportSavedReply(ctx, input)
	if err != nil {
		return model.SupportSavedReply{}, err
	}
	u.appendSupportSavedReplyAudit(ctx, actor, "support.saved_reply.upsert", reply.ID, meta, map[string]any{
		"category":  reply.Category,
		"status":    string(reply.Status),
		"sortOrder": reply.SortOrder,
	})
	return reply, nil
}

func (u *SupportUseCase) ListHelpCategories(ctx context.Context, actor *model.StaffUser, filter model.HelpCategoryFilter) ([]model.HelpCategory, error) {
	if !canReadHelpContent(actor) {
		return nil, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return nil, ErrIntegrationNotReady
	}
	filter.Limit = clampSupportLimit(filter.Limit)
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	return u.client.ListHelpCategories(ctx, filter)
}

func (u *SupportUseCase) UpsertHelpCategory(ctx context.Context, actor *model.StaffUser, input model.HelpCategoryUpsertInput, meta RequestMetadata) (model.HelpCategory, error) {
	if !canEditHelpContent(actor) {
		return model.HelpCategory{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.HelpCategory{}, ErrIntegrationNotReady
	}
	input.CategoryID = strings.TrimSpace(input.CategoryID)
	input.Slug = strings.TrimSpace(input.Slug)
	if input.CategoryID == "" {
		input.CategoryID = input.Slug
	}
	if input.Slug == "" {
		input.Slug = input.CategoryID
	}
	if input.CategoryID == "" || input.Slug == "" {
		return model.HelpCategory{}, ErrInvalidInput
	}
	input.ActorStaffID = actor.ID.String()
	input.IdempotencyKey = helpCategoryIdempotencyKey(meta, input.CategoryID, "upsert")
	input.RequestID = strings.TrimSpace(meta.RequestID)
	category, err := u.client.UpsertHelpCategory(ctx, input)
	if err != nil {
		return model.HelpCategory{}, err
	}
	u.appendHelpCategoryAudit(ctx, actor, "help.category.upsert", category.ID, meta, map[string]any{
		"status":    string(category.Status),
		"slug":      category.Slug,
		"sortOrder": category.SortOrder,
	})
	return category, nil
}

func (u *SupportUseCase) ListHelpArticles(ctx context.Context, actor *model.StaffUser, filter model.HelpArticleFilter) ([]model.HelpArticle, error) {
	if !canReadHelpContent(actor) {
		return nil, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return nil, ErrIntegrationNotReady
	}
	filter.Limit = clampSupportLimit(filter.Limit)
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	return u.client.ListHelpArticles(ctx, filter)
}

func (u *SupportUseCase) GetHelpAnalytics(ctx context.Context, actor *model.StaffUser, limit int) (model.HelpAnalyticsSummary, error) {
	if !canReadHelpAnalytics(actor) {
		return model.HelpAnalyticsSummary{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.HelpAnalyticsSummary{}, ErrIntegrationNotReady
	}
	return u.client.GetHelpAnalytics(ctx, clampSupportLimit(limit))
}

func (u *SupportUseCase) GetHelpArticle(ctx context.Context, actor *model.StaffUser, articleID string) (model.HelpArticleDetail, error) {
	if !canReadHelpContent(actor) {
		return model.HelpArticleDetail{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.HelpArticleDetail{}, ErrIntegrationNotReady
	}
	articleID = strings.TrimSpace(articleID)
	if articleID == "" {
		return model.HelpArticleDetail{}, ErrInvalidInput
	}
	return u.client.GetHelpArticle(ctx, articleID)
}

func (u *SupportUseCase) UpsertHelpArticle(ctx context.Context, actor *model.StaffUser, input model.HelpArticleUpsertInput, meta RequestMetadata) (model.HelpArticle, error) {
	if !canEditHelpContent(actor) {
		return model.HelpArticle{}, ErrPermissionDenied
	}
	if u == nil || u.client == nil {
		return model.HelpArticle{}, ErrIntegrationNotReady
	}
	input.ArticleID = strings.TrimSpace(input.ArticleID)
	input.Slug = strings.TrimSpace(input.Slug)
	if input.ArticleID == "" || input.Slug == "" {
		return model.HelpArticle{}, ErrInvalidInput
	}
	input.ActorStaffID = actor.ID.String()
	input.IdempotencyKey = helpArticleIdempotencyKey(meta, input.ArticleID, "upsert")
	input.RequestID = strings.TrimSpace(meta.RequestID)
	article, err := u.client.UpsertHelpArticle(ctx, input)
	if err != nil {
		return model.HelpArticle{}, err
	}
	u.appendHelpArticleAudit(ctx, actor, "help.article.upsert", article.ID, meta, map[string]any{
		"status": string(article.Status),
		"slug":   article.Slug,
	})
	return article, nil
}

func (u *SupportUseCase) SubmitHelpArticleForReview(ctx context.Context, actor *model.StaffUser, articleID string, meta RequestMetadata) (model.HelpArticle, error) {
	if !canEditHelpContent(actor) {
		return model.HelpArticle{}, ErrPermissionDenied
	}
	return u.helpArticleAction(ctx, actor, articleID, "submit_review", meta)
}

func (u *SupportUseCase) PublishHelpArticle(ctx context.Context, actor *model.StaffUser, articleID string, meta RequestMetadata) (model.HelpArticle, error) {
	if !canPublishHelpContent(actor) {
		return model.HelpArticle{}, ErrPermissionDenied
	}
	return u.helpArticleAction(ctx, actor, articleID, "publish", meta)
}

func (u *SupportUseCase) ArchiveHelpArticle(ctx context.Context, actor *model.StaffUser, articleID string, meta RequestMetadata) (model.HelpArticle, error) {
	if !canPublishHelpContent(actor) {
		return model.HelpArticle{}, ErrPermissionDenied
	}
	return u.helpArticleAction(ctx, actor, articleID, "archive", meta)
}

func (u *SupportUseCase) helpArticleAction(ctx context.Context, actor *model.StaffUser, articleID string, action string, meta RequestMetadata) (model.HelpArticle, error) {
	if u == nil || u.client == nil {
		return model.HelpArticle{}, ErrIntegrationNotReady
	}
	articleID = strings.TrimSpace(articleID)
	if actor == nil || articleID == "" {
		return model.HelpArticle{}, ErrInvalidInput
	}
	input := model.HelpArticleActionInput{
		ArticleID:      articleID,
		ActorStaffID:   actor.ID.String(),
		IdempotencyKey: helpArticleIdempotencyKey(meta, articleID, action),
		RequestID:      strings.TrimSpace(meta.RequestID),
	}
	var (
		article model.HelpArticle
		err     error
	)
	switch action {
	case "submit_review":
		article, err = u.client.SubmitHelpArticleForReview(ctx, articleID, input)
	case "publish":
		article, err = u.client.PublishHelpArticle(ctx, articleID, input)
	case "archive":
		article, err = u.client.ArchiveHelpArticle(ctx, articleID, input)
	default:
		return model.HelpArticle{}, ErrInvalidInput
	}
	if err != nil {
		return model.HelpArticle{}, err
	}
	u.appendHelpArticleAudit(ctx, actor, "help.article."+action, article.ID, meta, map[string]any{"status": string(article.Status)})
	return article, nil
}

func canReadSupport(actor *model.StaffUser) bool {
	return actor != nil && (actor.HasPermission(enum.PermissionSupportRead) || canReplySupport(actor) || canManageSupport(actor))
}

func supportTicketAttachmentFileID(detail model.SupportTicketDetail, eventIndex int, attachmentIndex int) (uuid.UUID, error) {
	if eventIndex < 0 || eventIndex >= len(detail.Events) || attachmentIndex < 0 {
		return uuid.Nil, ErrInvalidInput
	}
	fileIDs := supportEventFileIDs(detail.Events[eventIndex])
	if attachmentIndex >= len(fileIDs) {
		return uuid.Nil, ErrInvalidInput
	}
	fileID, err := uuid.Parse(fileIDs[attachmentIndex])
	if err != nil {
		return uuid.Nil, ErrInvalidInput
	}
	return fileID, nil
}

func supportEventFileIDs(event model.SupportTicketEvent) []string {
	raw := strings.TrimSpace(event.Payload["file_ids"])
	if raw == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	fileIDs := make([]string, 0, len(parts))
	for _, part := range parts {
		fileID := strings.TrimSpace(part)
		if fileID != "" {
			fileIDs = append(fileIDs, fileID)
		}
	}
	return fileIDs
}

func canReplySupport(actor *model.StaffUser) bool {
	return actor != nil && (actor.HasPermission(enum.PermissionSupportReply) || canManageSupport(actor))
}

func canManageSupport(actor *model.StaffUser) bool {
	return actor != nil && (actor.HasPermission(enum.PermissionSupportManage) ||
		actor.HasRole(enum.StaffRoleSupportLead) ||
		actor.HasRole(enum.StaffRoleSupportAdmin) ||
		actor.HasRole(enum.StaffRoleSuperAdmin))
}

func canReadHelpContent(actor *model.StaffUser) bool {
	return actor != nil && (canEditHelpContent(actor) || canPublishHelpContent(actor))
}

func canEditHelpContent(actor *model.StaffUser) bool {
	return actor != nil && (actor.HasPermission(enum.PermissionHelpContentEdit) || canPublishHelpContent(actor))
}

func canPublishHelpContent(actor *model.StaffUser) bool {
	return actor != nil && actor.HasPermission(enum.PermissionHelpContentPublish)
}

func canReadHelpAnalytics(actor *model.StaffUser) bool {
	return canReadSupport(actor) || canReadHelpContent(actor)
}

func clampSupportLimit(limit int) int {
	if limit <= 0 {
		return 50
	}
	if limit > 100 {
		return 100
	}
	return limit
}

func supportIdempotencyKey(meta RequestMetadata, ticketID string, action string) string {
	requestID := strings.TrimSpace(meta.RequestID)
	if requestID == "" {
		requestID = time.Now().UTC().Format("20060102150405.000000000")
	}
	return "admin:support:" + strings.TrimSpace(ticketID) + ":" + strings.TrimSpace(action) + ":" + requestID
}

func helpArticleIdempotencyKey(meta RequestMetadata, articleID string, action string) string {
	requestID := strings.TrimSpace(meta.RequestID)
	if requestID == "" {
		requestID = time.Now().UTC().Format("20060102150405.000000000")
	}
	return "admin:help_article:" + strings.TrimSpace(articleID) + ":" + strings.TrimSpace(action) + ":" + requestID
}

func helpCategoryIdempotencyKey(meta RequestMetadata, categoryID string, action string) string {
	requestID := strings.TrimSpace(meta.RequestID)
	if requestID == "" {
		requestID = time.Now().UTC().Format("20060102150405.000000000")
	}
	return "admin:help_category:" + strings.TrimSpace(categoryID) + ":" + strings.TrimSpace(action) + ":" + requestID
}

func supportSavedReplyIdempotencyKey(meta RequestMetadata, replyID string, action string) string {
	requestID := strings.TrimSpace(meta.RequestID)
	if requestID == "" {
		requestID = time.Now().UTC().Format("20060102150405.000000000")
	}
	return "admin:support_saved_reply:" + strings.TrimSpace(replyID) + ":" + strings.TrimSpace(action) + ":" + requestID
}

func (u *SupportUseCase) appendSupportAudit(
	ctx context.Context,
	actor *model.StaffUser,
	action string,
	ticketID string,
	meta RequestMetadata,
	metadata map[string]any,
) {
	if u == nil || u.audit == nil || actor == nil {
		return
	}
	if metadata == nil {
		metadata = map[string]any{}
	}
	metadata["ticketId"] = ticketID
	_ = u.audit.Append(ctx, &model.AuditEvent{
		ID:               uuid.New(),
		ActorStaffID:     &actor.ID,
		ActorDisplayName: actor.DisplayName,
		ActorEmail:       actor.Email,
		Action:           action,
		EntityType:       "support_ticket",
		RequestID:        strings.TrimSpace(meta.RequestID),
		IPAddressHash:    HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash:    HashPassiveIdentifier(meta.UserAgent),
		Metadata:         auditJSON(metadata),
		CreatedAt:        time.Now().UTC(),
	})
}

func (u *SupportUseCase) appendSupportSavedReplyAudit(
	ctx context.Context,
	actor *model.StaffUser,
	action string,
	replyID string,
	meta RequestMetadata,
	metadata map[string]any,
) {
	if u == nil || u.audit == nil || actor == nil {
		return
	}
	if metadata == nil {
		metadata = map[string]any{}
	}
	metadata["replyId"] = replyID
	_ = u.audit.Append(ctx, &model.AuditEvent{
		ID:               uuid.New(),
		ActorStaffID:     &actor.ID,
		ActorDisplayName: actor.DisplayName,
		ActorEmail:       actor.Email,
		Action:           action,
		EntityType:       "support_saved_reply",
		RequestID:        strings.TrimSpace(meta.RequestID),
		IPAddressHash:    HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash:    HashPassiveIdentifier(meta.UserAgent),
		Metadata:         auditJSON(metadata),
		CreatedAt:        time.Now().UTC(),
	})
}

func (u *SupportUseCase) appendHelpCategoryAudit(
	ctx context.Context,
	actor *model.StaffUser,
	action string,
	categoryID string,
	meta RequestMetadata,
	metadata map[string]any,
) {
	if u == nil || u.audit == nil || actor == nil {
		return
	}
	if metadata == nil {
		metadata = map[string]any{}
	}
	metadata["categoryId"] = categoryID
	_ = u.audit.Append(ctx, &model.AuditEvent{
		ID:               uuid.New(),
		ActorStaffID:     &actor.ID,
		ActorDisplayName: actor.DisplayName,
		ActorEmail:       actor.Email,
		Action:           action,
		EntityType:       "help_category",
		RequestID:        strings.TrimSpace(meta.RequestID),
		IPAddressHash:    HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash:    HashPassiveIdentifier(meta.UserAgent),
		Metadata:         auditJSON(metadata),
		CreatedAt:        time.Now().UTC(),
	})
}

func (u *SupportUseCase) appendHelpArticleAudit(
	ctx context.Context,
	actor *model.StaffUser,
	action string,
	articleID string,
	meta RequestMetadata,
	metadata map[string]any,
) {
	if u == nil || u.audit == nil || actor == nil {
		return
	}
	if metadata == nil {
		metadata = map[string]any{}
	}
	metadata["articleId"] = articleID
	_ = u.audit.Append(ctx, &model.AuditEvent{
		ID:               uuid.New(),
		ActorStaffID:     &actor.ID,
		ActorDisplayName: actor.DisplayName,
		ActorEmail:       actor.Email,
		Action:           action,
		EntityType:       "help_article",
		RequestID:        strings.TrimSpace(meta.RequestID),
		IPAddressHash:    HashPassiveIdentifier(meta.IPAddress),
		UserAgentHash:    HashPassiveIdentifier(meta.UserAgent),
		Metadata:         auditJSON(metadata),
		CreatedAt:        time.Now().UTC(),
	})
}
