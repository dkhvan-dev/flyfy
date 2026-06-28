package http

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/chat-service/internal/adapter/ws"
	"kz/inflap/backend/services/chat-service/internal/app"
	"kz/inflap/backend/services/chat-service/internal/domain/model"
	"kz/inflap/backend/services/chat-service/internal/transport/dto"
)

type Handler struct {
	conversationUC *app.ConversationUseCase
	messageUC      *app.MessageUseCase
	wsHandler      *ws.WSHandler
	actorResolver  ActorResolver
}

func NewHandler(
	conversationUC *app.ConversationUseCase,
	messageUC *app.MessageUseCase,
	wsHandler *ws.WSHandler,
	actorResolver ActorResolver,
) *Handler {
	return &Handler{
		conversationUC: conversationUC,
		messageUC:      messageUC,
		wsHandler:      wsHandler,
		actorResolver:  actorResolver,
	}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)

	mux.HandleFunc("GET /v1/conversations", h.ListConversations)
	mux.HandleFunc("POST /v1/conversations", h.CreateConversation)
	mux.HandleFunc("GET /v1/admin/chat/messages/moderation/flagged", h.ListFlaggedChatMessages)
	mux.HandleFunc("GET /v1/admin/chat/messages/", h.handleAdminChatMessageRoutes)
	mux.HandleFunc("POST /v1/admin/chat/messages/", h.handleAdminChatMessageRoutes)
	mux.HandleFunc("POST /v1/internal/activity-conversations/participants", h.EnsureActivityParticipant)
	mux.HandleFunc("POST /v1/internal/activity-conversations/sync", h.SyncActivityConversation)
	mux.HandleFunc("POST /v1/internal/excursion-schedule-slot-conversations/sync", h.SyncExcursionScheduleSlotConversation)
	mux.HandleFunc("GET /v1/conversations/", h.handleConversationRoutes)
	mux.HandleFunc("POST /v1/conversations/", h.handleConversationRoutes)
	mux.HandleFunc("PATCH /v1/conversations/", h.handleConversationRoutes)
	mux.HandleFunc("DELETE /v1/conversations/", h.handleConversationRoutes)
	mux.HandleFunc("GET /v1/users/", h.handleUserRoutes)
	mux.HandleFunc("POST /v1/users/", h.handleUserRoutes)
	mux.HandleFunc("DELETE /v1/users/", h.handleUserRoutes)

	mux.HandleFunc("GET /v1/ws", h.WebSocketUpgrade)
}

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) ListFlaggedChatMessages(w http.ResponseWriter, r *http.Request) {
	if !requireChatModerationAccess(w, r) {
		return
	}
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	items, err := h.messageUC.ListFlaggedMessagesForModeration(r.Context(), limit, offset)
	if err != nil {
		h.writeAppError(w, r, err, "list flagged chat messages failed")
		return
	}
	response := dto.ChatMessageModerationListResponse{
		Items: make([]dto.ChatMessageModerationResponse, 0, len(items)),
	}
	for _, item := range items {
		response.Items = append(response.Items, chatMessageModerationResponseFromModel(item))
	}
	writeJSON(w, http.StatusOK, response)
}

func (h *Handler) handleAdminChatMessageRoutes(w http.ResponseWriter, r *http.Request) {
	if !requireChatModerationAccess(w, r) {
		return
	}
	path := strings.TrimPrefix(r.URL.Path, "/v1/admin/chat/messages/")
	path = strings.Trim(path, "/")
	parts := strings.Split(path, "/")
	if len(parts) == 0 || strings.TrimSpace(parts[0]) == "" {
		writeError(w, r, http.StatusNotFound, "not found")
		return
	}
	messageID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid message id")
		return
	}
	if len(parts) == 1 && r.Method == http.MethodGet {
		item, err := h.messageUC.GetMessageForModeration(r.Context(), messageID)
		if err != nil {
			h.writeAppError(w, r, err, "get chat message moderation item failed")
			return
		}
		writeJSON(w, http.StatusOK, chatMessageModerationResponseFromModel(item))
		return
	}
	if len(parts) == 3 && parts[1] == "moderation" && r.Method == http.MethodPost {
		var req dto.ChatModerationDecisionRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeError(w, r, http.StatusBadRequest, "invalid request body")
			return
		}
		actorID, ok := adminActorIDFromRequest(w, r)
		if !ok {
			return
		}
		var item *model.ChatMessageModerationItem
		switch parts[2] {
		case "approve":
			item, err = h.messageUC.ApproveMessageForModeration(
				r.Context(),
				messageID,
				actorID,
				req.InternalComment,
			)
		case "reject", "hide":
			item, err = h.messageUC.HideMessageForModeration(
				r.Context(),
				messageID,
				actorID,
				req.ReasonCodes,
				req.PublicComment,
				req.InternalComment,
			)
		default:
			writeError(w, r, http.StatusNotFound, "not found")
			return
		}
		if err != nil {
			h.writeAppError(w, r, err, "apply chat message moderation decision failed")
			return
		}
		writeJSON(w, http.StatusOK, chatMessageModerationResponseFromModel(item))
		return
	}
	writeError(w, r, http.StatusNotFound, "not found")
}

func (h *Handler) WebSocketUpgrade(w http.ResponseWriter, r *http.Request) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}
	h.wsHandler.HandleUpgrade(w, r, actorUserID)
}

func (h *Handler) ListConversations(w http.ResponseWriter, r *http.Request) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit <= 0 {
		limit = 20
	}

	var convType *string
	if t := strings.TrimSpace(r.URL.Query().Get("type")); t != "" {
		convType = &t
	}

	var cursor *time.Time
	if c := strings.TrimSpace(r.URL.Query().Get("cursor")); c != "" {
		parsed, err := time.Parse(time.RFC3339, c)
		if err == nil {
			cursor = &parsed
		}
	}

	convs, err := h.conversationUC.ListConversations(r.Context(), actorUserID, convType, limit, cursor)
	if err != nil {
		log.Error().Err(err).Msg("list conversations")
		writeError(w, r, http.StatusInternalServerError, "internal error")
		return
	}

	items := make([]dto.ConversationListItem, 0, len(convs))
	for _, c := range convs {
		item := dto.ConversationListItem{
			ID:               c.ID.String(),
			Type:             c.Type,
			Title:            c.Title,
			AvatarFileID:     c.AvatarFileID,
			Participants:     participantInfosFromModel(c.Participants),
			UnreadCount:      c.UnreadCount,
			ParticipantCount: c.ParticipantCount,
			CanSendMessages:  !c.IsMessagingClosed(time.Now().UTC()),
			LastActivityAt:   c.LastActivityAt.Format(time.RFC3339),
		}
		if c.ActivityID != nil {
			s := c.ActivityID.String()
			item.ActivityID = &s
		}
		if c.ExcursionScheduleSlotID != nil {
			s := c.ExcursionScheduleSlotID.String()
			item.ExcursionScheduleSlotID = &s
		}
		if c.MutedUntil != nil {
			s := c.MutedUntil.Format(time.RFC3339)
			item.MutedUntil = &s
		}
		if c.MessagingAvailableUntil != nil {
			s := c.MessagingAvailableUntil.Format(time.RFC3339)
			item.MessagingAvailableUntil = &s
		}
		if c.LastMessage != nil {
			preview := c.LastMessage.Content
			fileIDs := c.LastMessage.FileIDs
			deletedAt := c.LastMessage.DeletedAt
			moderationStatus := ""
			var moderationPublicComment *string
			if c.LastMessage.IsHiddenByModeration() {
				preview = ""
				fileIDs = nil
				deletedAt = c.LastMessage.ModerationReviewedAt
				moderationStatus = model.MessageModerationStatusHiddenByModeration
				if comment := strings.TrimSpace(c.LastMessage.ModerationPublicComment); comment != "" {
					moderationPublicComment = &comment
				}
			}
			if len(preview) > 100 {
				preview = preview[:100]
			}
			item.LastMessage = &dto.LastMessagePreview{
				ID:                      c.LastMessage.ID.String(),
				SenderUserID:            c.LastMessage.SenderUserID.String(),
				SenderDisplayName:       c.LastMessage.SenderDisplayName,
				Type:                    c.LastMessage.Type,
				ContentPreview:          preview,
				FileIDs:                 append([]string(nil), fileIDs...),
				StickerID:               uuidPtrToString(c.LastMessage.StickerID),
				StickerFileID:           c.LastMessage.StickerFileID,
				ModerationStatus:        moderationStatus,
				ModerationPublicComment: moderationPublicComment,
				SentAt:                  c.LastMessage.SentAt.Format(time.RFC3339),
			}
			if deletedAt != nil {
				s := deletedAt.UTC().Format(time.RFC3339)
				item.LastMessage.DeletedAt = &s
			}
		}
		items = append(items, item)
	}

	var nextCursor *string
	if len(convs) == limit {
		last := convs[len(convs)-1].LastActivityAt.Format(time.RFC3339)
		nextCursor = &last
	}

	writeJSON(w, http.StatusOK, dto.ConversationListResponse{Items: items, NextCursor: nextCursor})
}

func (h *Handler) CreateConversation(w http.ResponseWriter, r *http.Request) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.CreateConversationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	switch strings.TrimSpace(req.Type) {
	case "direct":
		if len(req.ParticipantUserIDs) != 1 {
			writeError(w, r, http.StatusBadRequest, "exactly one participant is required for direct chats")
			return
		}

		participantID, err := uuid.Parse(strings.TrimSpace(req.ParticipantUserIDs[0]))
		if err != nil {
			writeError(w, r, http.StatusBadRequest, "invalid participant user id")
			return
		}

		conv, err := h.conversationUC.CreateDirectConversation(r.Context(), app.CreateDirectConversationInput{
			ActorUserID:       actorUserID,
			ParticipantUserID: participantID,
		})
		if err != nil {
			h.writeAppError(w, r, err, "create conversation failed")
			return
		}

		writeJSON(w, http.StatusCreated, map[string]string{"id": conv.ID.String()})

	case "activity":
		activityID, err := uuid.Parse(strings.TrimSpace(req.ActivityID))
		if err != nil {
			writeError(w, r, http.StatusBadRequest, "invalid activity id")
			return
		}

		conv, err := h.conversationUC.CreateActivityConversation(r.Context(), app.CreateActivityConversationInput{
			ActivityID: activityID,
			Title:      strings.TrimSpace(req.Title),
			HostUserID: actorUserID,
		})
		if err != nil {
			h.writeAppError(w, r, err, "create activity conversation failed")
			return
		}

		writeJSON(w, http.StatusCreated, map[string]string{"id": conv.ID.String()})

	default:
		writeError(w, r, http.StatusBadRequest, "unsupported conversation type")
	}
}

func (h *Handler) EnsureActivityParticipant(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusUnauthorized, "missing internal service token")
		return
	}

	var req dto.EnsureActivityParticipantRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	activityID, err := uuid.Parse(strings.TrimSpace(req.ActivityID))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid activity id")
		return
	}

	hostUserID, err := uuid.Parse(strings.TrimSpace(req.HostUserID))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid host user id")
		return
	}

	userID, err := uuid.Parse(strings.TrimSpace(req.UserID))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid user id")
		return
	}

	conv, err := h.conversationUC.EnsureActivityParticipant(r.Context(), app.EnsureActivityParticipantInput{
		ActivityID:              activityID,
		ActivityTitle:           req.ActivityTitle,
		ActivityAvatarFileID:    req.ActivityAvatarFileID,
		MessagingAvailableUntil: parseOptionalTime(req.MessagingAvailableUntil),
		HostUserID:              hostUserID,
		UserID:                  userID,
		DisplayName:             req.DisplayName,
	})
	if err != nil {
		h.writeAppError(w, r, err, "ensure activity participant failed")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"id": conv.ID.String()})
}

func (h *Handler) SyncActivityConversation(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusUnauthorized, "missing internal service token")
		return
	}

	var req dto.SyncActivityConversationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	activityID, err := uuid.Parse(strings.TrimSpace(req.ActivityID))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid activity id")
		return
	}

	conv, err := h.conversationUC.SyncActivityConversation(r.Context(), app.SyncActivityConversationInput{
		ActivityID:              activityID,
		ActivityTitle:           req.ActivityTitle,
		ActivityAvatarFileID:    req.ActivityAvatarFileID,
		MessagingAvailableUntil: parseOptionalTime(req.MessagingAvailableUntil),
	})
	if err != nil {
		h.writeAppError(w, r, err, "sync activity conversation failed")
		return
	}
	if conv == nil {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"id": conv.ID.String()})
}

func (h *Handler) SyncExcursionScheduleSlotConversation(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusUnauthorized, "missing internal service token")
		return
	}

	var req dto.SyncExcursionScheduleSlotConversationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	slotID, err := uuid.Parse(strings.TrimSpace(req.ScheduleSlotID))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid schedule slot id")
		return
	}
	guideUserID, err := uuid.Parse(strings.TrimSpace(req.GuideUserID))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid guide user id")
		return
	}
	participantUserIDs := make([]uuid.UUID, 0, len(req.ParticipantUserIDs))
	for _, rawUserID := range req.ParticipantUserIDs {
		userID, parseErr := uuid.Parse(strings.TrimSpace(rawUserID))
		if parseErr != nil {
			writeError(w, r, http.StatusBadRequest, "invalid participant user id")
			return
		}
		participantUserIDs = append(participantUserIDs, userID)
	}

	conv, err := h.conversationUC.SyncExcursionScheduleSlotConversation(r.Context(), app.SyncExcursionScheduleSlotConversationInput{
		ScheduleSlotID:          slotID,
		ExcursionTitle:          req.ExcursionTitle,
		ExcursionAvatarFileID:   req.ExcursionAvatarFileID,
		MessagingAvailableUntil: parseOptionalTime(req.MessagingAvailableUntil),
		GuideUserID:             guideUserID,
		ParticipantUserIDs:      participantUserIDs,
	})
	if err != nil {
		h.writeAppError(w, r, err, "sync excursion schedule slot conversation failed")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"id": conv.ID.String()})
}

func (h *Handler) handleConversationRoutes(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/conversations/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, r, http.StatusNotFound, "not found")
		return
	}

	parts := strings.Split(path, "/")

	// GET /v1/conversations/by-activity/{activityId}
	if parts[0] == "by-activity" && r.Method == http.MethodGet {
		if len(parts) < 2 {
			writeError(w, r, http.StatusBadRequest, "missing activity id")
			return
		}
		activityID, err := uuid.Parse(parts[1])
		if err != nil {
			writeError(w, r, http.StatusBadRequest, "invalid activity id")
			return
		}
		h.GetConversationByActivity(w, r, activityID)
		return
	}

	convID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid conversation id")
		return
	}

	if len(parts) == 1 {
		if r.Method == http.MethodGet {
			h.GetConversation(w, r, convID)
			return
		}
		if r.Method == http.MethodDelete {
			writeError(w, r, http.StatusNotImplemented, "not implemented")
			return
		}
		writeError(w, r, http.StatusNotFound, "not found")
		return
	}

	switch parts[1] {
	case "messages":
		if len(parts) == 2 {
			switch r.Method {
			case http.MethodGet:
				h.ListMessages(w, r, convID)
			case http.MethodPost:
				h.SendMessage(w, r, convID)
			default:
				writeError(w, r, http.StatusMethodNotAllowed, "method not allowed")
			}
			return
		}
		if len(parts) == 3 {
			msgID, err := uuid.Parse(parts[2])
			if err != nil {
				writeError(w, r, http.StatusBadRequest, "invalid message id")
				return
			}
			switch r.Method {
			case http.MethodPatch:
				h.EditMessage(w, r, convID, msgID)
			case http.MethodDelete:
				h.DeleteMessage(w, r, convID, msgID)
			default:
				writeError(w, r, http.StatusMethodNotAllowed, "method not allowed")
			}
			return
		}
		if len(parts) == 4 && parts[3] == "reaction" {
			msgID, err := uuid.Parse(parts[2])
			if err != nil {
				writeError(w, r, http.StatusBadRequest, "invalid message id")
				return
			}
			if r.Method == http.MethodPost {
				h.ReactToMessage(w, r, convID, msgID)
				return
			}
			writeError(w, r, http.StatusMethodNotAllowed, "method not allowed")
			return
		}
		if len(parts) == 4 && parts[3] == "forward" {
			msgID, err := uuid.Parse(parts[2])
			if err != nil {
				writeError(w, r, http.StatusBadRequest, "invalid message id")
				return
			}
			if r.Method == http.MethodPost {
				h.ForwardMessage(w, r, convID, msgID)
				return
			}
			writeError(w, r, http.StatusMethodNotAllowed, "method not allowed")
			return
		}
	case "read":
		if r.Method == http.MethodPost {
			h.MarkRead(w, r, convID)
			return
		}
	case "typing":
		if r.Method == http.MethodPost {
			h.Typing(w, r, convID)
			return
		}
	case "mute":
		if r.Method == http.MethodPost {
			h.MuteConversation(w, r, convID)
			return
		}
	case "leave":
		if r.Method == http.MethodPost {
			h.LeaveConversation(w, r, convID)
			return
		}
	case "pin":
		switch {
		case len(parts) == 2 && r.Method == http.MethodPost:
			h.PinMessage(w, r, convID)
			return
		case len(parts) == 3 && r.Method == http.MethodDelete:
			msgID, err := uuid.Parse(parts[2])
			if err != nil {
				writeError(w, r, http.StatusBadRequest, "invalid message id")
				return
			}
			h.UnpinMessage(w, r, convID, msgID)
			return
		case len(parts) == 2 && r.Method == http.MethodDelete:
			msgID, err := uuid.Parse(strings.TrimSpace(r.URL.Query().Get("messageId")))
			if err != nil {
				writeError(w, r, http.StatusBadRequest, "invalid message id")
				return
			}
			h.UnpinMessage(w, r, convID, msgID)
			return
		}
	}

	writeError(w, r, http.StatusNotFound, "not found")
}

func (h *Handler) handleUserRoutes(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/users/")
	path = strings.Trim(path, "/")
	parts := strings.Split(path, "/")
	if len(parts) != 2 {
		writeError(w, r, http.StatusNotFound, "not found")
		return
	}

	targetUserID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid user id")
		return
	}

	switch parts[1] {
	case "block-status":
		if r.Method == http.MethodGet {
			h.GetUserBlockStatus(w, r, targetUserID)
			return
		}
	case "block":
		switch r.Method {
		case http.MethodPost:
			h.BlockUser(w, r, targetUserID)
			return
		case http.MethodDelete:
			h.UnblockUser(w, r, targetUserID)
			return
		}
	}

	writeError(w, r, http.StatusMethodNotAllowed, "method not allowed")
}

func (h *Handler) GetConversation(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	conv, err := h.conversationUC.GetConversationByID(r.Context(), convID, actorUserID)
	if err != nil {
		h.writeAppError(w, r, err, "get conversation failed")
		return
	}

	detail := dto.ConversationDetail{
		ID:              conv.ID.String(),
		Type:            conv.Type,
		Title:           conv.Title,
		AvatarFileID:    conv.AvatarFileID,
		CreatedAt:       conv.CreatedAt.Format(time.RFC3339),
		UnreadCount:     conv.UnreadCount,
		CanSendMessages: !conv.IsMessagingClosed(time.Now().UTC()) && !conv.HasBlockedMe,
		IsBlockedByMe:   conv.IsBlockedByMe,
		HasBlockedMe:    conv.HasBlockedMe,
		LastActivityAt:  conv.LastActivityAt.Format(time.RFC3339),
	}
	if conv.ActivityID != nil {
		s := conv.ActivityID.String()
		detail.ActivityID = &s
	}
	if conv.ExcursionScheduleSlotID != nil {
		s := conv.ExcursionScheduleSlotID.String()
		detail.ExcursionScheduleSlotID = &s
	}
	if conv.MutedUntil != nil {
		s := conv.MutedUntil.Format(time.RFC3339)
		detail.MutedUntil = &s
	}
	if conv.MessagingAvailableUntil != nil {
		s := conv.MessagingAvailableUntil.Format(time.RFC3339)
		detail.MessagingAvailableUntil = &s
	}

	detail.Participants = participantInfosFromModel(conv.Participants)
	detail.PinnedMessages = pinnedMessageInfosFromModel(conv.PinnedMessages)

	writeJSON(w, http.StatusOK, detail)
}

func (h *Handler) GetConversationByActivity(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	conv, err := h.conversationUC.GetConversationByActivityID(r.Context(), activityID, actorUserID)
	if err != nil {
		h.writeAppError(w, r, err, "get conversation by activity failed")
		return
	}

	detail := dto.ConversationDetail{
		ID:              conv.ID.String(),
		Type:            conv.Type,
		Title:           conv.Title,
		AvatarFileID:    conv.AvatarFileID,
		CreatedAt:       conv.CreatedAt.Format(time.RFC3339),
		UnreadCount:     conv.UnreadCount,
		CanSendMessages: !conv.IsMessagingClosed(time.Now().UTC()) && !conv.HasBlockedMe,
		IsBlockedByMe:   conv.IsBlockedByMe,
		HasBlockedMe:    conv.HasBlockedMe,
		LastActivityAt:  conv.LastActivityAt.Format(time.RFC3339),
	}
	if conv.ActivityID != nil {
		s := conv.ActivityID.String()
		detail.ActivityID = &s
	}
	if conv.ExcursionScheduleSlotID != nil {
		s := conv.ExcursionScheduleSlotID.String()
		detail.ExcursionScheduleSlotID = &s
	}
	if conv.MutedUntil != nil {
		s := conv.MutedUntil.Format(time.RFC3339)
		detail.MutedUntil = &s
	}
	if conv.MessagingAvailableUntil != nil {
		s := conv.MessagingAvailableUntil.Format(time.RFC3339)
		detail.MessagingAvailableUntil = &s
	}

	detail.Participants = participantInfosFromModel(conv.Participants)
	detail.PinnedMessages = pinnedMessageInfosFromModel(conv.PinnedMessages)

	writeJSON(w, http.StatusOK, detail)
}

func (h *Handler) SendMessage(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.SendMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	var clientMessageID *uuid.UUID
	if req.ClientMessageID != nil && strings.TrimSpace(*req.ClientMessageID) != "" {
		parsed, err := uuid.Parse(strings.TrimSpace(*req.ClientMessageID))
		if err != nil || parsed == uuid.Nil {
			writeError(w, r, http.StatusBadRequest, "invalid client message id")
			return
		}
		clientMessageID = &parsed
	}

	var replyTo *uuid.UUID
	if req.ReplyToMessageID != nil {
		parsed, err := uuid.Parse(strings.TrimSpace(*req.ReplyToMessageID))
		if err == nil {
			replyTo = &parsed
		}
	}
	storyReply, ok := storyReplyContextFromRequest(req.StoryReply, w, r)
	if !ok {
		return
	}
	var stickerID *uuid.UUID
	var stickerAccessUserID *uuid.UUID
	if req.StickerID != nil && strings.TrimSpace(*req.StickerID) != "" {
		parsed, err := uuid.Parse(strings.TrimSpace(*req.StickerID))
		if err != nil {
			writeError(w, r, http.StatusBadRequest, "invalid sticker id")
			return
		}
		stickerID = &parsed

		if gatewayUserID := UserIDFromContext(r.Context()); gatewayUserID != "" {
			parsedGatewayUserID, err := uuid.Parse(gatewayUserID)
			if err != nil || parsedGatewayUserID == uuid.Nil {
				writeError(w, r, http.StatusUnauthorized, "invalid authenticated user")
				return
			}
			stickerAccessUserID = &parsedGatewayUserID
		}
	}

	msg, err := h.messageUC.SendMessage(r.Context(), app.SendMessageInput{
		ConversationID:      convID,
		SenderUserID:        actorUserID,
		ClientMessageID:     clientMessageID,
		StickerAccessUserID: stickerAccessUserID,
		SenderDisplayName:   supportSenderDisplayNameFromRequest(r, req.SenderDisplayName),
		Type:                req.Type,
		Content:             req.Content,
		FileIDs:             req.FileIDs,
		StickerID:           stickerID,
		ReplyToMessageID:    replyTo,
		StoryReply:          storyReply,
	})
	if err != nil {
		h.writeAppError(w, r, err, "send message failed")
		return
	}

	writeJSON(w, http.StatusCreated, messageResponseFromModel(msg))
}

func (h *Handler) ListMessages(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit <= 0 {
		limit = 50
	}

	direction := r.URL.Query().Get("direction")
	if direction == "" {
		direction = "older"
	}

	var cursor *uuid.UUID
	if c := strings.TrimSpace(r.URL.Query().Get("cursor")); c != "" {
		parsed, err := uuid.Parse(c)
		if err != nil {
			writeError(w, r, http.StatusBadRequest, "invalid message cursor")
			return
		}
		cursor = &parsed
	}

	msgs, err := h.messageUC.ListMessages(r.Context(), convID, actorUserID, limit, cursor, direction)
	if err != nil {
		h.writeAppError(w, r, err, "list messages failed")
		return
	}

	items := make([]dto.MessageResponse, 0, len(msgs))
	for _, m := range msgs {
		items = append(items, messageResponseFromModel(m))
	}

	var nextCursor *string
	if len(msgs) == limit {
		last := msgs[len(msgs)-1].ID.String()
		nextCursor = &last
	}

	writeJSON(w, http.StatusOK, dto.MessageListResponse{Items: items, NextCursor: nextCursor})
}

func (h *Handler) EditMessage(w http.ResponseWriter, r *http.Request, convID, msgID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.EditMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	msg, err := h.messageUC.EditMessage(r.Context(), convID, msgID, actorUserID, req.Content)
	if err != nil {
		h.writeAppError(w, r, err, "edit message failed")
		return
	}

	writeJSON(w, http.StatusOK, messageResponseFromModel(msg))
}

func (h *Handler) ReactToMessage(w http.ResponseWriter, r *http.Request, convID, msgID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.ReactMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	result, err := h.messageUC.ToggleReaction(
		r.Context(),
		convID,
		msgID,
		actorUserID,
		req.Emoji,
	)
	if err != nil {
		h.writeAppError(w, r, err, "toggle message reaction failed")
		return
	}

	writeJSON(w, http.StatusOK, dto.MessageReactionResponse{
		MessageID: result.MessageID.String(),
		Reactions: reactionInfosFromModel(result.Reactions),
	})
}

func (h *Handler) ForwardMessage(w http.ResponseWriter, r *http.Request, convID, msgID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.ForwardMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	targetConversationID, err := uuid.Parse(strings.TrimSpace(req.TargetConversationID))
	if err != nil || targetConversationID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, "invalid target conversation id")
		return
	}

	msg, err := h.messageUC.ForwardMessage(r.Context(), app.ForwardMessageInput{
		SourceConversationID: convID,
		TargetConversationID: targetConversationID,
		MessageID:            msgID,
		SenderUserID:         actorUserID,
	})
	if err != nil {
		h.writeAppError(w, r, err, "forward message failed")
		return
	}

	writeJSON(w, http.StatusCreated, messageResponseFromModel(msg))
}

func (h *Handler) DeleteMessage(w http.ResponseWriter, r *http.Request, convID, msgID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	result, err := h.messageUC.DeleteMessage(r.Context(), convID, msgID, actorUserID)
	if err != nil {
		h.writeAppError(w, r, err, "delete message failed")
		return
	}

	var deletedAt *string
	if result.DeletedAt != nil {
		value := result.DeletedAt.UTC().Format(time.RFC3339)
		deletedAt = &value
	}

	writeJSON(w, http.StatusOK, dto.DeleteMessageResponse{
		HardDeleted: result.HardDeleted,
		DeletedAt:   deletedAt,
	})
}

func (h *Handler) MarkRead(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.MarkReadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	msgID, err := uuid.Parse(strings.TrimSpace(req.LastReadMessageID))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid message id")
		return
	}

	if err := h.messageUC.MarkRead(r.Context(), convID, actorUserID, msgID); err != nil {
		h.writeAppError(w, r, err, "mark read failed")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) Typing(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	_ = h.messageUC.PublishTyping(r.Context(), convID, actorUserID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) MuteConversation(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.MuteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	var until *time.Time
	if req.Until != nil {
		parsed, err := time.Parse(time.RFC3339, *req.Until)
		if err != nil {
			writeError(w, r, http.StatusBadRequest, "invalid until time")
			return
		}
		until = &parsed
	}

	if err := h.conversationUC.MuteConversation(r.Context(), app.MuteInput{
		ConversationID: convID,
		ActorUserID:    actorUserID,
		Until:          until,
	}); err != nil {
		h.writeAppError(w, r, err, "mute conversation failed")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetUserBlockStatus(w http.ResponseWriter, r *http.Request, targetUserID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	status, err := h.conversationUC.GetUserBlockStatus(r.Context(), actorUserID, targetUserID)
	if err != nil {
		h.writeAppError(w, r, err, "get user block status failed")
		return
	}

	writeJSON(w, http.StatusOK, userBlockStatusResponseFromModel(status))
}

func (h *Handler) BlockUser(w http.ResponseWriter, r *http.Request, targetUserID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	status, err := h.conversationUC.BlockUser(r.Context(), actorUserID, targetUserID)
	if err != nil {
		h.writeAppError(w, r, err, "block user failed")
		return
	}

	writeJSON(w, http.StatusOK, userBlockStatusResponseFromModel(status))
}

func (h *Handler) UnblockUser(w http.ResponseWriter, r *http.Request, targetUserID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	status, err := h.conversationUC.UnblockUser(r.Context(), actorUserID, targetUserID)
	if err != nil {
		h.writeAppError(w, r, err, "unblock user failed")
		return
	}

	writeJSON(w, http.StatusOK, userBlockStatusResponseFromModel(status))
}

func userBlockStatusResponseFromModel(status *model.UserBlockStatus) dto.UserBlockStatusResponse {
	if status == nil {
		return dto.UserBlockStatusResponse{}
	}
	return dto.UserBlockStatusResponse{
		UserID:        status.UserID.String(),
		IsBlockedByMe: status.IsBlockedByMe,
		HasBlockedMe:  status.HasBlockedMe,
	}
}

func (h *Handler) LeaveConversation(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	if err := h.conversationUC.LeaveConversation(r.Context(), convID, actorUserID); err != nil {
		h.writeAppError(w, r, err, "leave conversation failed")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) PinMessage(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.PinRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid request body")
		return
	}

	msgID, err := uuid.Parse(strings.TrimSpace(req.MessageID))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid message id")
		return
	}

	pins, err := h.conversationUC.PinMessage(r.Context(), convID, msgID, actorUserID)
	if err != nil {
		h.writeAppError(w, r, err, "pin message failed")
		return
	}

	writeJSON(w, http.StatusOK, dto.PinnedMessagesResponse{
		Items: pinnedMessageInfosFromModel(pins),
	})
}

func (h *Handler) UnpinMessage(w http.ResponseWriter, r *http.Request, convID, msgID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, r, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	pins, err := h.conversationUC.UnpinMessage(r.Context(), convID, msgID, actorUserID)
	if err != nil {
		h.writeAppError(w, r, err, "unpin message failed")
		return
	}

	writeJSON(w, http.StatusOK, dto.PinnedMessagesResponse{
		Items: pinnedMessageInfosFromModel(pins),
	})
}

func requireChatModerationAccess(w http.ResponseWriter, r *http.Request) bool {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusUnauthorized, "missing internal service token")
		return false
	}
	for _, role := range RolesFromContext(r.Context()) {
		switch strings.ToUpper(strings.TrimSpace(role)) {
		case "SUPER_ADMIN", "MODERATION_LEAD", "CHAT_MODERATOR":
			return true
		}
	}
	writeError(w, r, http.StatusForbidden, "missing chat moderation role")
	return false
}

func supportSenderDisplayNameFromRequest(r *http.Request, value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return ""
	}
	for _, role := range RolesFromContext(r.Context()) {
		switch strings.ToUpper(strings.TrimSpace(role)) {
		case "SUPPORT_AGENT", "SUPPORT_ADMIN":
			return value
		}
	}
	return ""
}

func adminActorIDFromRequest(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	actorID, err := uuid.Parse(UserIDFromContext(r.Context()))
	if err != nil || actorID == uuid.Nil {
		writeError(w, r, http.StatusUnauthorized, "invalid authenticated admin")
		return uuid.Nil, false
	}
	return actorID, true
}

func messageResponseFromModel(m *model.Message) dto.MessageResponse {
	content := m.Content
	fileIDs := m.FileIDs
	deletedAt := m.DeletedAt
	if m.IsHiddenByModeration() {
		content = ""
		fileIDs = nil
		deletedAt = m.ModerationReviewedAt
	}
	item := dto.MessageResponse{
		ID:                        m.ID.String(),
		ClientMessageID:           uuidPtrToString(m.ClientMessageID),
		SenderUserID:              m.SenderUserID.String(),
		SenderDisplayName:         m.SenderDisplayName,
		SenderAvatarFileID:        m.SenderAvatarFileID,
		Type:                      m.Type,
		Content:                   content,
		FileIDs:                   fileIDs,
		StickerID:                 uuidPtrToString(m.StickerID),
		StickerFileID:             m.StickerFileID,
		ForwardedFromMessageID:    uuidPtrToString(m.ForwardedFromMessageID),
		ForwardedFromSenderUserID: uuidPtrToString(m.ForwardedFromSenderUserID),
		StoryReply:                storyReplyResponseFromModel(m.StoryReply),
		ForwardCount:              m.ForwardCount,
		Reactions:                 reactionInfosFromModel(m.Reactions),
		ReadReceipts:              readReceiptInfosFromModel(m.ReadReceipts),
		SentAt:                    m.SentAt.Format(time.RFC3339),
	}
	if m.IsHiddenByModeration() {
		item.ModerationStatus = model.MessageModerationStatusHiddenByModeration
		if comment := strings.TrimSpace(m.ModerationPublicComment); comment != "" {
			item.ModerationPublicComment = &comment
		}
	}
	if strings.TrimSpace(m.ForwardedFromSenderName) != "" {
		name := strings.TrimSpace(m.ForwardedFromSenderName)
		item.ForwardedFromSenderName = &name
	}
	if m.ReplyToMessageID != nil {
		s := m.ReplyToMessageID.String()
		item.ReplyToMessageID = &s
	}
	if m.EditedAt != nil {
		s := m.EditedAt.Format(time.RFC3339)
		item.EditedAt = &s
	}
	if deletedAt != nil {
		s := deletedAt.Format(time.RFC3339)
		item.DeletedAt = &s
	}
	return item
}

func storyReplyContextFromRequest(
	req *dto.StoryReplyContextRequest,
	w http.ResponseWriter,
	r *http.Request,
) (*model.StoryReplyContext, bool) {
	if req == nil {
		return nil, true
	}
	storyID, err := uuid.Parse(strings.TrimSpace(req.StoryID))
	if err != nil || storyID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, "invalid story reply story id")
		return nil, false
	}
	authorUserID, err := uuid.Parse(strings.TrimSpace(req.StoryAuthorUserID))
	if err != nil || authorUserID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, "invalid story reply author id")
		return nil, false
	}
	var expiresAt *time.Time
	if req.StoryExpiresAt != nil && strings.TrimSpace(*req.StoryExpiresAt) != "" {
		parsed, err := time.Parse(time.RFC3339, strings.TrimSpace(*req.StoryExpiresAt))
		if err != nil {
			writeError(w, r, http.StatusBadRequest, "invalid story reply expiration")
			return nil, false
		}
		expiresAt = &parsed
	}
	return &model.StoryReplyContext{
		StoryID:            storyID,
		StoryAuthorUserID:  authorUserID,
		StoryTitle:         strings.TrimSpace(req.StoryTitle),
		StoryPreviewFileID: strings.TrimSpace(req.StoryPreviewFileID),
		StoryPreviewURL:    strings.TrimSpace(req.StoryPreviewURL),
		StoryExpiresAt:     expiresAt,
	}, true
}

func storyReplyResponseFromModel(context *model.StoryReplyContext) *dto.StoryReplyContextResponse {
	if context == nil || context.IsZero() {
		return nil
	}
	var expiresAt *string
	if context.StoryExpiresAt != nil {
		value := context.StoryExpiresAt.Format(time.RFC3339)
		expiresAt = &value
	}
	return &dto.StoryReplyContextResponse{
		StoryID:            context.StoryID.String(),
		StoryAuthorUserID:  context.StoryAuthorUserID.String(),
		StoryTitle:         context.StoryTitle,
		StoryPreviewFileID: context.StoryPreviewFileID,
		StoryPreviewURL:    context.StoryPreviewURL,
		StoryExpiresAt:     expiresAt,
	}
}

func chatMessageModerationResponseFromModel(item *model.ChatMessageModerationItem) dto.ChatMessageModerationResponse {
	if item == nil {
		return dto.ChatMessageModerationResponse{}
	}
	response := dto.ChatMessageModerationResponse{
		ID:                    item.ID.String(),
		ConversationID:        item.ConversationID.String(),
		ConversationType:      item.ConversationType,
		ConversationTitle:     item.ConversationTitle,
		SenderUserID:          item.SenderUserID.String(),
		SenderDisplayName:     item.SenderDisplayName,
		Type:                  item.Type,
		Content:               item.Content,
		FileIDs:               append([]string(nil), item.FileIDs...),
		ModerationStatus:      item.ModerationStatus,
		ModerationRiskScore:   item.ModerationRiskScore,
		ModerationReasonCodes: append([]string(nil), item.ModerationReasonCodes...),
		ContextBefore:         chatMessageContextResponses(item.ContextBefore),
		ContextAfter:          chatMessageContextResponses(item.ContextAfter),
		Participants:          chatParticipantModerationResponses(item.Participants),
		Revision:              item.Revision,
		SentAt:                item.SentAt.Format(time.RFC3339),
		CreatedAt:             item.CreatedAt.Format(time.RFC3339),
		UpdatedAt:             item.UpdatedAt.Format(time.RFC3339),
	}
	response.ActivityID = uuidPtrToString(item.ActivityID)
	response.ExcursionScheduleSlotID = uuidPtrToString(item.ExcursionScheduleSlotID)
	response.ModerationTriggeredAt = timePtrToString(item.ModerationTriggeredAt)
	response.ModerationReviewedAt = timePtrToString(item.ModerationReviewedAt)
	response.EditedAt = timePtrToString(item.EditedAt)
	response.DeletedAt = timePtrToString(item.DeletedAt)
	return response
}

func chatMessageContextResponses(items []model.ChatMessageContextItem) []dto.ChatMessageContextResponse {
	out := make([]dto.ChatMessageContextResponse, 0, len(items))
	for _, item := range items {
		out = append(out, dto.ChatMessageContextResponse{
			ID:                item.ID.String(),
			SenderUserID:      item.SenderUserID.String(),
			SenderDisplayName: item.SenderDisplayName,
			Type:              item.Type,
			Content:           item.Content,
			FileIDs:           append([]string(nil), item.FileIDs...),
			EditedAt:          timePtrToString(item.EditedAt),
			DeletedAt:         timePtrToString(item.DeletedAt),
			SentAt:            item.SentAt.Format(time.RFC3339),
		})
	}
	return out
}

func chatParticipantModerationResponses(items []model.ChatParticipantModerationItem) []dto.ChatParticipantModerationResponse {
	out := make([]dto.ChatParticipantModerationResponse, 0, len(items))
	for _, item := range items {
		out = append(out, dto.ChatParticipantModerationResponse{
			UserID:      item.UserID.String(),
			DisplayName: item.DisplayName,
			Role:        item.Role,
		})
	}
	return out
}

func timePtrToString(value *time.Time) *string {
	if value == nil {
		return nil
	}
	formatted := value.UTC().Format(time.RFC3339)
	return &formatted
}

func reactionInfosFromModel(
	reactions []model.MessageReactionSummary,
) []dto.MessageReactionInfo {
	items := make([]dto.MessageReactionInfo, 0, len(reactions))
	for _, reaction := range reactions {
		items = append(items, dto.MessageReactionInfo{
			Emoji:       reaction.Emoji,
			Count:       reaction.Count,
			ReactedByMe: reaction.ReactedByMe,
			UserIDs:     reaction.UserIDs,
			Users:       reactionUserInfosFromModel(reaction.Users),
		})
	}
	return items
}

func reactionUserInfosFromModel(
	users []model.MessageReactionUserSummary,
) []dto.MessageReactionUserInfo {
	items := make([]dto.MessageReactionUserInfo, 0, len(users))
	for _, user := range users {
		items = append(items, dto.MessageReactionUserInfo{
			UserID:    user.UserID,
			ReactedAt: user.ReactedAt.UTC().Format(time.RFC3339Nano),
		})
	}
	return items
}

func readReceiptInfosFromModel(
	receipts []model.MessageReadReceipt,
) []dto.MessageReadReceiptInfo {
	items := make([]dto.MessageReadReceiptInfo, 0, len(receipts))
	for _, receipt := range receipts {
		items = append(items, dto.MessageReadReceiptInfo{
			UserID: receipt.UserID.String(),
			ReadAt: receipt.ReadAt.UTC().Format(time.RFC3339),
		})
	}
	return items
}

func participantInfosFromModel(participants []*model.Participant) []dto.ParticipantInfo {
	items := make([]dto.ParticipantInfo, 0, len(participants))
	for _, p := range participants {
		if p == nil {
			continue
		}

		item := dto.ParticipantInfo{
			UserID:       p.UserID.String(),
			DisplayName:  p.DisplayName,
			AvatarFileID: p.AvatarFileID,
			Role:         p.Role,
			JoinedAt:     p.JoinedAt.Format(time.RFC3339),
			IsOnline:     p.IsOnline,
		}
		if p.LastSeenAt != nil {
			s := p.LastSeenAt.UTC().Format(time.RFC3339)
			item.LastSeenAt = &s
		}
		if p.LastReadMsgID != nil {
			s := p.LastReadMsgID.String()
			item.LastReadMessageID = &s
		}
		items = append(items, item)
	}
	return items
}

func pinnedMessageInfosFromModel(
	pins []*model.ConversationPin,
) []dto.PinnedMessageInfo {
	items := make([]dto.PinnedMessageInfo, 0, len(pins))
	for _, pin := range pins {
		if pin == nil || pin.Message == nil {
			continue
		}

		items = append(items, dto.PinnedMessageInfo{
			ID:                 pin.Message.ID.String(),
			SenderUserID:       pin.Message.SenderUserID.String(),
			SenderDisplayName:  pin.Message.SenderDisplayName,
			SenderAvatarFileID: pin.Message.SenderAvatarFileID,
			Type:               pin.Message.Type,
			Content:            pin.Message.Content,
			FileIDs:            append([]string(nil), pin.Message.FileIDs...),
			StickerID:          uuidPtrToString(pin.Message.StickerID),
			StickerFileID:      pin.Message.StickerFileID,
			SentAt:             pin.Message.SentAt.Format(time.RFC3339),
			PinnedAt:           pin.PinnedAt.Format(time.RFC3339),
		})
	}
	return items
}

func (h *Handler) writeAppError(w http.ResponseWriter, r *http.Request, err error, fallback string) {
	language := requestErrorLanguage(r)
	if definition, ok := appHTTPErrorContract(err); ok {
		writeErrorContract(
			w,
			definition.status,
			localizedBusinessError(definition.code, language),
			definition.code,
			errorKindBusiness,
		)
		return
	}

	log.Error().Err(err).Msg(fallback)
	writeErrorContract(
		w,
		http.StatusInternalServerError,
		localizedTechnicalError(language),
		errorCodeTechnical,
		errorKindTechnical,
	)
}

func uuidPtrToString(value *uuid.UUID) *string {
	if value == nil {
		return nil
	}
	str := value.String()
	return &str
}

func writeError(w http.ResponseWriter, r *http.Request, status int, message string) {
	language := requestErrorLanguage(r)
	if status >= http.StatusInternalServerError {
		writeErrorContract(
			w,
			status,
			localizedTechnicalError(language),
			errorCodeTechnical,
			errorKindTechnical,
		)
		return
	}

	writeErrorContract(
		w,
		status,
		localizedLegacyBusinessError(message, language),
		legacyErrorCode(status, message),
		errorKindBusiness,
	)
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func parseOptionalTime(value string) *time.Time {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		return nil
	}
	parsed = parsed.UTC()
	return &parsed
}
