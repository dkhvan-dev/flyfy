package http

import (
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func (s *Server) SupportTicketQueue(w http.ResponseWriter, r *http.Request) {
	filter, viewFilter := parseSupportTicketFilter(r)
	locale := localeFromContext(r.Context())
	data := NewSupportTicketQueueViewData(nil, viewFilter, staffFromContext(r.Context()), locale)
	if s.support == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "support/index", "support.title", "support", data, publicError(locale, app.ErrIntegrationNotReady))
		return
	}
	items, err := s.support.ListTickets(r.Context(), staffFromContext(r.Context()), filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "support/index", "support.title", "support", data, publicError(locale, err))
		return
	}
	staff := staffFromContext(r.Context())
	assigneeLabels := s.supportTicketQueueAssigneeDisplayNames(r, staff, items)
	s.renderPage(w, http.StatusOK, r, "support/index", "support.title", "support", NewSupportTicketQueueViewDataWithAssignees(items, viewFilter, staff, locale, assigneeLabels), "")
}

func (s *Server) SupportTicketDetail(w http.ResponseWriter, r *http.Request) {
	ticketID := strings.TrimSpace(r.PathValue("ticketID"))
	staff := staffFromContext(r.Context())
	if s.support == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "support/detail", "support.detailTitle", "support", NewSupportTicketDetailViewDataWithSavedRepliesForLocale(model.SupportTicketDetail{}, "", nil, staff, localeFromContext(r.Context())), publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	detail, err := s.support.GetTicket(r.Context(), staff, ticketID)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "support/detail", "support.detailTitle", "support", NewSupportTicketDetailViewDataWithSavedRepliesForLocale(model.SupportTicketDetail{}, "", nil, staff, localeFromContext(r.Context())), publicError(localeFromContext(r.Context()), err))
		return
	}
	var savedReplies []model.SupportSavedReply
	if staffCanSupportReply(staff) {
		if loaded, loadErr := s.support.ListSupportSavedReplies(r.Context(), staff, model.SupportSavedReplyFilter{
			Category: string(detail.Ticket.Category),
			Status:   model.HelpArticleStatusPublished,
			Limit:    20,
		}); loadErr == nil {
			savedReplies = loaded
		}
	}
	var assigneeAgents []model.SupportAgent
	if staffCanSupportManage(staff) {
		assigneeAgents = s.supportAssignableAgents(r, staff)
	}
	assigneeLabel := s.supportTicketAssigneeDisplayName(r, staff, detail)
	s.renderPage(w, http.StatusOK, r, "support/detail", "support.detailTitle", "support", NewSupportTicketDetailViewDataWithSavedRepliesForLocaleAndAssignee(detail, supportQueueURL(r.URL.RawQuery), savedReplies, staff, localeFromContext(r.Context()), assigneeLabel, assigneeAgents...), "")
}

func (s *Server) SupportTicketAttachment(w http.ResponseWriter, r *http.Request) {
	locale := localeFromContext(r.Context())
	if s.support == nil {
		http.Error(w, publicError(locale, app.ErrIntegrationNotReady), http.StatusServiceUnavailable)
		return
	}
	eventIndex, err := strconv.Atoi(strings.TrimSpace(r.PathValue("eventIndex")))
	if err != nil {
		http.Error(w, publicError(locale, app.ErrInvalidInput), http.StatusBadRequest)
		return
	}
	attachmentIndex, err := strconv.Atoi(strings.TrimSpace(r.PathValue("attachmentIndex")))
	if err != nil {
		http.Error(w, publicError(locale, app.ErrInvalidInput), http.StatusBadRequest)
		return
	}
	download, err := s.support.CreateAttachmentDownloadURL(r.Context(), staffFromContext(r.Context()), r.PathValue("ticketID"), eventIndex, attachmentIndex)
	if err != nil {
		http.Error(w, publicError(locale, err), errorStatus(err))
		return
	}
	location := safeExternalURL(download.URL)
	if location == "" {
		http.Error(w, publicError(locale, app.ErrIntegrationNotReady), http.StatusServiceUnavailable)
		return
	}
	http.Redirect(w, r, location, http.StatusFound)
}

func (s *Server) supportTicketAssigneeDisplayName(r *http.Request, actor *model.StaffUser, detail model.SupportTicketDetail) string {
	if s == nil || s.staff == nil {
		return ""
	}
	assigneeID := strings.TrimSpace(detail.Ticket.AssigneeID)
	if assigneeID == "" {
		return ""
	}
	parsedID, err := uuid.Parse(assigneeID)
	if err != nil {
		return ""
	}
	displayName, err := s.staff.ResolveStaffDisplayName(r.Context(), actor, parsedID)
	if err != nil {
		return ""
	}
	return displayName
}

func (s *Server) supportTicketQueueAssigneeDisplayNames(r *http.Request, actor *model.StaffUser, tickets []model.SupportTicket) map[string]string {
	if s == nil || s.staff == nil || len(tickets) == 0 {
		return nil
	}
	labels := make(map[string]string)
	for _, ticket := range tickets {
		assigneeID := strings.TrimSpace(ticket.AssigneeID)
		if assigneeID == "" {
			continue
		}
		if _, ok := labels[assigneeID]; ok {
			continue
		}
		parsedID, err := uuid.Parse(assigneeID)
		if err != nil {
			continue
		}
		displayName, err := s.staff.ResolveStaffDisplayName(r.Context(), actor, parsedID)
		if err != nil {
			continue
		}
		if displayName = strings.TrimSpace(displayName); displayName != "" {
			labels[assigneeID] = displayName
		}
	}
	return labels
}

func (s *Server) AssignSupportTicket(w http.ResponseWriter, r *http.Request) {
	returnQuery := strings.TrimSpace(r.URL.RawQuery)
	if err := r.ParseForm(); err != nil {
		s.renderSupportTicketActionError(w, r, returnQuery, app.ErrInvalidInput)
		return
	}
	if s.support == nil {
		s.renderSupportTicketActionError(w, r, returnQuery, app.ErrIntegrationNotReady)
		return
	}
	assigneeID, err := s.resolveSupportAssigneeID(r, staffFromContext(r.Context()), r.Form.Get("assignee_id"), r.Form.Get("assignee_query"))
	if err != nil {
		s.renderSupportTicketActionError(w, r, returnQuery, err)
		return
	}
	_, err = s.support.AssignTicket(r.Context(), staffFromContext(r.Context()), r.PathValue("ticketID"), assigneeID, r.Form.Get("assignment_reason"), requestMetadata(r))
	if err != nil {
		s.renderSupportTicketActionError(w, r, returnQuery, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(supportTicketDetailURL(r.PathValue("ticketID"), returnQuery), "support.ticketUpdated"), http.StatusSeeOther)
}

func (s *Server) resolveSupportAssigneeID(r *http.Request, staff *model.StaffUser, rawAssigneeID string, rawQuery string) (string, error) {
	assigneeID := strings.TrimSpace(rawAssigneeID)
	query := strings.TrimSpace(rawQuery)
	if query == "" {
		if assigneeID == "" {
			return "", app.ErrInvalidInput
		}
		return assigneeID, nil
	}
	if assigneeID != "" && strings.EqualFold(query, assigneeID) {
		return assigneeID, nil
	}
	if s == nil || s.support == nil {
		return "", app.ErrIntegrationNotReady
	}
	agents := s.supportAssignableAgents(r, staff)
	if resolved := supportAssigneeIDFromQuery(query, agents); resolved != "" {
		return resolved, nil
	}
	return "", app.ErrInvalidInput
}

func (s *Server) supportAssignableAgents(r *http.Request, staff *model.StaffUser) []model.SupportAgent {
	if s == nil || s.support == nil {
		return nil
	}
	agents, err := s.support.ListSupportAgents(r.Context(), staff, model.SupportAgentFilter{
		Status: model.SupportAgentStatusActive,
		Limit:  100,
	})
	if err != nil {
		return nil
	}
	if s.staff == nil {
		return agents
	}
	for index := range agents {
		staffID, parseErr := uuid.Parse(strings.TrimSpace(agents[index].StaffID))
		if parseErr != nil {
			continue
		}
		contact, resolveErr := s.staff.ResolveStaffDisplayContact(r.Context(), staff, staffID)
		if resolveErr != nil {
			continue
		}
		agents[index].Email = strings.TrimSpace(contact.Email)
	}
	return agents
}

func (s *Server) ReplySupportTicket(w http.ResponseWriter, r *http.Request) {
	returnQuery := strings.TrimSpace(r.URL.RawQuery)
	if err := r.ParseForm(); err != nil {
		s.renderSupportTicketActionError(w, r, returnQuery, app.ErrInvalidInput)
		return
	}
	if s.support == nil {
		s.renderSupportTicketActionError(w, r, returnQuery, app.ErrIntegrationNotReady)
		return
	}
	_, err := s.support.ReplyTicket(r.Context(), staffFromContext(r.Context()), model.SupportTicketReplyInput{
		TicketID:       strings.TrimSpace(r.PathValue("ticketID")),
		Message:        r.Form.Get("message"),
		ConversationID: r.Form.Get("conversation_id"),
		MessageID:      r.Form.Get("message_id"),
	}, requestMetadata(r))
	if err != nil {
		s.renderSupportTicketActionError(w, r, returnQuery, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(supportTicketChatComposerURL(r.PathValue("ticketID"), returnQuery), "support.ticketUpdated"), http.StatusSeeOther)
}

func (s *Server) AddSupportTicketNote(w http.ResponseWriter, r *http.Request) {
	returnQuery := strings.TrimSpace(r.URL.RawQuery)
	if err := r.ParseForm(); err != nil {
		s.renderSupportTicketActionError(w, r, returnQuery, app.ErrInvalidInput)
		return
	}
	if s.support == nil {
		s.renderSupportTicketActionError(w, r, returnQuery, app.ErrIntegrationNotReady)
		return
	}
	err := s.support.AddTicketNote(r.Context(), staffFromContext(r.Context()), r.PathValue("ticketID"), r.Form.Get("note"), requestMetadata(r))
	if err != nil {
		s.renderSupportTicketActionError(w, r, returnQuery, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(supportTicketDetailURL(r.PathValue("ticketID"), returnQuery), "support.ticketUpdated"), http.StatusSeeOther)
}

func (s *Server) ResolveSupportTicket(w http.ResponseWriter, r *http.Request) {
	returnQuery := strings.TrimSpace(r.URL.RawQuery)
	if err := r.ParseForm(); err != nil {
		s.renderSupportTicketActionError(w, r, returnQuery, app.ErrInvalidInput)
		return
	}
	if s.support == nil {
		s.renderSupportTicketActionError(w, r, returnQuery, app.ErrIntegrationNotReady)
		return
	}
	_, err := s.support.ResolveTicket(r.Context(), staffFromContext(r.Context()), r.PathValue("ticketID"), r.Form.Get("resolution"), requestMetadata(r))
	if err != nil {
		s.renderSupportTicketActionError(w, r, returnQuery, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(supportTicketDetailURL(r.PathValue("ticketID"), returnQuery), "support.ticketUpdated"), http.StatusSeeOther)
}

func (s *Server) ReopenSupportTicket(w http.ResponseWriter, r *http.Request) {
	returnQuery := strings.TrimSpace(r.URL.RawQuery)
	if err := r.ParseForm(); err != nil {
		s.renderSupportTicketActionError(w, r, returnQuery, app.ErrInvalidInput)
		return
	}
	if s.support == nil {
		s.renderSupportTicketActionError(w, r, returnQuery, app.ErrIntegrationNotReady)
		return
	}
	_, err := s.support.ReopenTicket(r.Context(), staffFromContext(r.Context()), r.PathValue("ticketID"), r.Form.Get("reason"), requestMetadata(r))
	if err != nil {
		s.renderSupportTicketActionError(w, r, returnQuery, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(supportTicketDetailURL(r.PathValue("ticketID"), returnQuery), "support.ticketUpdated"), http.StatusSeeOther)
}

func (s *Server) SupportAgentList(w http.ResponseWriter, r *http.Request) {
	filter, viewFilter := parseSupportAgentFilter(r)
	input := SupportAgentFormInput{Status: string(model.SupportAgentStatusActive), Level: string(model.SupportAgentLevelAgent), MaxActiveLoad: 8, Timezone: "Asia/Almaty"}
	staff := staffFromContext(r.Context())
	staffOptions := s.supportAgentStaffOptions(r, staff)
	data := NewSupportAgentListViewData(nil, viewFilter, input, staff, staffOptions)
	if s.support == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "support_agents/index", "support.agentsTitle", "support_agents", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	items, err := s.support.ListSupportAgents(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "support_agents/index", "support.agentsTitle", "support_agents", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "support_agents/index", "support.agentsTitle", "support_agents", NewSupportAgentListViewData(items, viewFilter, input, staff, staffOptions), "")
}

func (s *Server) SaveSupportAgent(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		s.renderSupportAgentListError(w, r, app.ErrInvalidInput)
		return
	}
	if s.support == nil {
		s.renderSupportAgentListError(w, r, app.ErrIntegrationNotReady)
		return
	}
	input := parseSupportAgentUpsertInput(r)
	staffID, err := s.resolveSupportAgentStaffID(r, staffFromContext(r.Context()), input)
	if err != nil {
		s.renderSupportAgentListError(w, r, err)
		return
	}
	input.StaffID = staffID.String()
	if strings.TrimSpace(input.LastName) == "" || strings.TrimSpace(input.FirstName) == "" {
		s.renderSupportAgentListError(w, r, app.ErrInvalidInput)
		return
	}
	if _, err := s.support.UpsertSupportAgent(r.Context(), staffFromContext(r.Context()), input, requestMetadata(r)); err != nil {
		s.renderSupportAgentListError(w, r, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash("/admin/support/agents", "support.agentSaved"), http.StatusSeeOther)
}

func (s *Server) SupportSavedReplyList(w http.ResponseWriter, r *http.Request) {
	filter, viewFilter := parseSupportSavedReplyFilter(r)
	input := SupportSavedReplyFormInput{Status: string(model.HelpArticleStatusPublished)}
	locale := localeFromContext(r.Context())
	data := NewSupportSavedReplyListViewDataForLocale(nil, viewFilter, input, staffFromContext(r.Context()), locale)
	if s.support == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "support_saved_replies/index", "support.savedRepliesTitle", "support_saved_replies", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	items, err := s.support.ListSupportSavedReplies(r.Context(), staffFromContext(r.Context()), filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "support_saved_replies/index", "support.savedRepliesTitle", "support_saved_replies", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "support_saved_replies/index", "support.savedRepliesTitle", "support_saved_replies", NewSupportSavedReplyListViewDataForLocale(items, viewFilter, input, staffFromContext(r.Context()), locale), "")
}

func (s *Server) SaveSupportSavedReply(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		s.renderSupportSavedReplyListError(w, r, app.ErrInvalidInput)
		return
	}
	if s.support == nil {
		s.renderSupportSavedReplyListError(w, r, app.ErrIntegrationNotReady)
		return
	}
	input := parseSupportSavedReplyUpsertInput(r)
	if _, err := s.support.UpsertSupportSavedReply(r.Context(), staffFromContext(r.Context()), input, requestMetadata(r)); err != nil {
		s.renderSupportSavedReplyListError(w, r, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash("/admin/support/saved-replies", "support.savedReplySaved"), http.StatusSeeOther)
}

func (s *Server) renderSupportSavedReplyListError(w http.ResponseWriter, r *http.Request, err error) {
	filter, viewFilter := parseSupportSavedReplyFilter(r)
	input := parseSupportSavedReplyFormInput(r)
	var items []model.SupportSavedReply
	if s.support != nil {
		loaded, loadErr := s.support.ListSupportSavedReplies(r.Context(), staffFromContext(r.Context()), filter)
		if loadErr == nil {
			items = loaded
		}
	}
	data := NewSupportSavedReplyListViewDataForLocale(items, viewFilter, input, staffFromContext(r.Context()), localeFromContext(r.Context()))
	s.renderPage(w, errorStatus(err), r, "support_saved_replies/index", "support.savedRepliesTitle", "support_saved_replies", data, publicError(localeFromContext(r.Context()), err))
}

func (s *Server) renderSupportTicketActionError(w http.ResponseWriter, r *http.Request, returnQuery string, err error) {
	ticketID := strings.TrimSpace(r.PathValue("ticketID"))
	detail := model.SupportTicketDetail{}
	if s.support != nil && ticketID != "" {
		if loaded, loadErr := s.support.GetTicket(r.Context(), staffFromContext(r.Context()), ticketID); loadErr == nil {
			detail = loaded
		}
	}
	s.renderPage(w, errorStatus(err), r, "support/detail", "support.detailTitle", "support", NewSupportTicketDetailViewDataWithSavedRepliesForLocale(detail, supportQueueURL(returnQuery), nil, staffFromContext(r.Context()), localeFromContext(r.Context())), publicError(localeFromContext(r.Context()), err))
}

func (s *Server) renderSupportAgentListError(w http.ResponseWriter, r *http.Request, err error) {
	filter, viewFilter := parseSupportAgentFilter(r)
	input := parseSupportAgentFormInput(r)
	staff := staffFromContext(r.Context())
	var items []model.SupportAgent
	if s.support != nil {
		loaded, loadErr := s.support.ListSupportAgents(r.Context(), staff, filter)
		if loadErr == nil {
			items = loaded
		}
	}
	data := NewSupportAgentListViewData(items, viewFilter, input, staff, s.supportAgentStaffOptions(r, staff))
	s.renderPage(w, errorStatus(err), r, "support_agents/index", "support.agentsTitle", "support_agents", data, publicError(localeFromContext(r.Context()), err))
}

func parseSupportAgentFilter(r *http.Request) (model.SupportAgentFilter, SupportAgentFilterViewData) {
	query := r.URL.Query()
	status := strings.TrimSpace(query.Get("status"))
	filter := model.SupportAgentFilter{
		Status: model.SupportAgentStatus(status),
		Limit:  parsePositiveInt(query.Get("limit"), 100),
		Offset: parsePositiveInt(query.Get("offset"), 0),
	}
	return filter, SupportAgentFilterViewData{
		Status: status,
		Query:  supportAgentFilterQuery(status),
	}
}

func supportAgentFilterQuery(status string) string {
	values := url.Values{}
	if strings.TrimSpace(status) != "" {
		values.Set("status", strings.TrimSpace(status))
	}
	return values.Encode()
}

func (s *Server) supportAgentStaffOptions(r *http.Request, staff *model.StaffUser) []*model.StaffUser {
	if s.staff == nil {
		return nil
	}
	items, err := s.staff.ListSupportAssignableStaff(r.Context(), staff, 200, 0)
	if err != nil {
		return nil
	}
	return items
}

func (s *Server) resolveSupportAgentStaffID(r *http.Request, staff *model.StaffUser, input model.SupportAgentUpsertInput) (uuid.UUID, error) {
	if s.staff == nil {
		return uuid.Nil, app.ErrIntegrationNotReady
	}
	options, err := s.staff.ListSupportAssignableStaff(r.Context(), staff, 200, 0)
	if err != nil {
		return uuid.Nil, err
	}
	if staffID := strings.TrimSpace(input.StaffID); staffID != "" {
		parsed, err := uuid.Parse(staffID)
		if err != nil {
			return uuid.Nil, app.ErrInvalidInput
		}
		for _, option := range options {
			if option != nil && option.ID == parsed {
				return parsed, nil
			}
		}
		return uuid.Nil, app.ErrInvalidInput
	}
	lookup := strings.TrimSpace(parseSupportAgentFormInput(r).StaffLookup)
	if lookup == "" {
		return uuid.Nil, app.ErrInvalidInput
	}
	needle := strings.ToLower(lookup)
	for _, option := range options {
		if option == nil || option.ID == uuid.Nil {
			continue
		}
		candidates := []string{
			option.ID.String(),
			option.DisplayName,
			option.Email,
			supportAgentStaffSearchValue(option),
		}
		for _, candidate := range candidates {
			if strings.ToLower(strings.TrimSpace(candidate)) == needle {
				return option.ID, nil
			}
		}
	}
	return uuid.Nil, app.ErrInvalidInput
}

func parseSupportAgentUpsertInput(r *http.Request) model.SupportAgentUpsertInput {
	input := parseSupportAgentFormInput(r)
	return model.SupportAgentUpsertInput{
		StaffID:       input.StaffID,
		FirstName:     input.FirstName,
		LastName:      input.LastName,
		MiddleName:    input.MiddleName,
		Status:        model.SupportAgentStatus(input.Status),
		Languages:     splitCSV(input.Languages),
		Skills:        input.Skills,
		Level:         model.SupportAgentLevel(input.Level),
		MaxActiveLoad: input.MaxActiveLoad,
		Timezone:      input.Timezone,
	}
}

func parseSupportAgentFormInput(r *http.Request) SupportAgentFormInput {
	maxActiveLoad, err := strconv.ParseFloat(strings.TrimSpace(r.Form.Get("max_active_load")), 64)
	if err != nil {
		maxActiveLoad = 8
	}
	return SupportAgentFormInput{
		StaffID:       strings.TrimSpace(r.Form.Get("staff_id")),
		StaffLookup:   strings.TrimSpace(r.Form.Get("staff_lookup")),
		FirstName:     strings.TrimSpace(r.Form.Get("first_name")),
		LastName:      strings.TrimSpace(r.Form.Get("last_name")),
		MiddleName:    strings.TrimSpace(r.Form.Get("middle_name")),
		Status:        strings.TrimSpace(r.Form.Get("status")),
		Languages:     parseSupportAgentLanguages(r.Form["languages"]),
		Skills:        parseSupportAgentSkills(r.Form["skills"]),
		Level:         strings.TrimSpace(r.Form.Get("level")),
		MaxActiveLoad: maxActiveLoad,
		Timezone:      strings.TrimSpace(r.Form.Get("timezone")),
	}
}

func parseSupportAgentLanguages(values []string) string {
	languages := make([]string, 0, len(values))
	for _, value := range values {
		for _, part := range splitCSV(value) {
			if part != "" && !stringInSlice(languages, part) {
				languages = append(languages, part)
			}
		}
	}
	return strings.Join(languages, ",")
}

func parseSupportAgentSkills(values []string) []model.SupportAgentSkill {
	skills := make([]model.SupportAgentSkill, 0, len(values))
	for _, value := range values {
		for _, part := range splitCSV(value) {
			if part != "" {
				skills = append(skills, model.SupportAgentSkill(part))
			}
		}
	}
	return skills
}

func parseSupportSavedReplyFilter(r *http.Request) (model.SupportSavedReplyFilter, SupportSavedReplyFilterViewData) {
	query := r.URL.Query()
	category := strings.TrimSpace(query.Get("category"))
	status := strings.TrimSpace(query.Get("status"))
	if status == "" {
		status = "all"
	}
	filter := model.SupportSavedReplyFilter{
		Category: category,
		Status:   model.HelpArticleStatus(status),
		Limit:    parsePositiveInt(query.Get("limit"), 100),
		Offset:   parsePositiveInt(query.Get("offset"), 0),
	}
	if status == "all" {
		filter.Status = ""
	}
	return filter, SupportSavedReplyFilterViewData{
		Category: category,
		Status:   status,
		Query:    supportSavedReplyFilterQuery(category, status),
	}
}

func supportSavedReplyFilterQuery(category string, status string) string {
	values := url.Values{}
	if strings.TrimSpace(category) != "" {
		values.Set("category", strings.TrimSpace(category))
	}
	if strings.TrimSpace(status) != "" {
		values.Set("status", strings.TrimSpace(status))
	}
	return values.Encode()
}

func parseSupportSavedReplyUpsertInput(r *http.Request) model.SupportSavedReplyUpsertInput {
	input := parseSupportSavedReplyFormInput(r)
	return model.SupportSavedReplyUpsertInput{
		ReplyID:      input.ReplyID,
		Category:     input.Category,
		Status:       model.HelpArticleStatus(input.Status),
		Tags:         splitCSV(input.Tags),
		Translations: supportSavedReplyTranslationsFromInput(input),
		SortOrder:    input.SortOrder,
	}
}

func parseSupportSavedReplyFormInput(r *http.Request) SupportSavedReplyFormInput {
	status := strings.TrimSpace(r.Form.Get("status"))
	if status == "" {
		status = string(model.HelpArticleStatusPublished)
	}
	return SupportSavedReplyFormInput{
		ReplyID:   strings.TrimSpace(r.Form.Get("reply_id")),
		Category:  strings.TrimSpace(r.Form.Get("category")),
		Status:    status,
		Tags:      strings.TrimSpace(r.Form.Get("tags")),
		SortOrder: parsePositiveInt(r.Form.Get("sort_order"), 0),
		EN:        parseSupportSavedReplyLocaleInput(r, "en"),
		RU:        parseSupportSavedReplyLocaleInput(r, "ru"),
		KK:        parseSupportSavedReplyLocaleInput(r, "kk"),
	}
}

func parseSupportSavedReplyLocaleInput(r *http.Request, locale string) SupportSavedReplyLocaleInput {
	return SupportSavedReplyLocaleInput{
		Title: strings.TrimSpace(r.Form.Get("title_" + locale)),
		Body:  strings.TrimSpace(r.Form.Get("body_" + locale)),
	}
}

func supportSavedReplyTranslationsFromInput(input SupportSavedReplyFormInput) map[string]model.SupportSavedReplyTranslation {
	return map[string]model.SupportSavedReplyTranslation{
		"en": {Title: input.EN.Title, Body: input.EN.Body},
		"ru": {Title: input.RU.Title, Body: input.RU.Body},
		"kk": {Title: input.KK.Title, Body: input.KK.Body},
	}
}

func parseSupportTicketFilter(r *http.Request) (model.SupportTicketFilter, SupportTicketFilterViewData) {
	query := r.URL.Query()
	status := strings.TrimSpace(query.Get("status"))
	if status == "" {
		status = "all"
	}
	priority := strings.TrimSpace(query.Get("priority"))
	assigneeID := strings.TrimSpace(query.Get("assigneeId"))
	sla := strings.TrimSpace(query.Get("sla"))
	limit := parsePositiveInt(query.Get("limit"), 100)
	offset := parsePositiveInt(query.Get("offset"), 0)

	filter := model.SupportTicketFilter{
		Status:      model.SupportTicketStatus(status),
		Priority:    model.SupportTicketPriority(priority),
		AssigneeID:  assigneeID,
		SLABreached: strings.EqualFold(sla, "breached"),
		Limit:       limit,
		Offset:      offset,
	}
	if status == "all" {
		filter.Status = ""
	}
	return filter, SupportTicketFilterViewData{
		Status:     status,
		Priority:   priority,
		AssigneeID: assigneeID,
		SLA:        sla,
		Query:      supportTicketFilterQuery(status, priority, assigneeID, sla),
	}
}

func supportTicketFilterQuery(status string, priority string, assigneeID string, sla string) string {
	values := url.Values{}
	if strings.TrimSpace(status) != "" {
		values.Set("status", strings.TrimSpace(status))
	}
	if strings.TrimSpace(priority) != "" {
		values.Set("priority", strings.TrimSpace(priority))
	}
	if strings.TrimSpace(assigneeID) != "" {
		values.Set("assigneeId", strings.TrimSpace(assigneeID))
	}
	if strings.TrimSpace(sla) != "" {
		values.Set("sla", strings.TrimSpace(sla))
	}
	return values.Encode()
}

func parsePositiveInt(raw string, fallback int) int {
	parsed, err := strconv.Atoi(strings.TrimSpace(raw))
	if err != nil || parsed < 0 {
		return fallback
	}
	return parsed
}

func supportQueueURL(query string) string {
	query = strings.TrimSpace(query)
	if query == "" {
		return "/admin/support/tickets"
	}
	return "/admin/support/tickets?" + query
}

func supportTicketDetailURL(ticketID string, query string) string {
	path := "/admin/support/tickets/" + url.PathEscape(strings.TrimSpace(ticketID))
	query = strings.TrimSpace(query)
	if query == "" {
		return path
	}
	return path + "?" + query
}

func supportTicketChatComposerURL(ticketID string, query string) string {
	return supportTicketDetailURL(ticketID, query) + "#support-chat-composer"
}
