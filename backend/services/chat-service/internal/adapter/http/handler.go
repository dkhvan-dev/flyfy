package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/adapter/ws"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/transport/dto"
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
	mux.HandleFunc("GET /v1/conversations/", h.handleConversationRoutes)
	mux.HandleFunc("POST /v1/conversations/", h.handleConversationRoutes)
	mux.HandleFunc("PATCH /v1/conversations/", h.handleConversationRoutes)
	mux.HandleFunc("DELETE /v1/conversations/", h.handleConversationRoutes)

	mux.HandleFunc("GET /v1/ws", h.WebSocketUpgrade)
}

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) WebSocketUpgrade(w http.ResponseWriter, r *http.Request) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}
	h.wsHandler.HandleUpgrade(w, r, actorUserID)
}

func (h *Handler) ListConversations(w http.ResponseWriter, r *http.Request) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
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
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	items := make([]dto.ConversationListItem, 0, len(convs))
	for _, c := range convs {
		item := dto.ConversationListItem{
			ID:               c.ID.String(),
			Type:             c.Type,
			Title:            c.Title,
			AvatarFileID:     c.AvatarFileID,
			UnreadCount:      c.UnreadCount,
			ParticipantCount: c.ParticipantCount,
			LastActivityAt:   c.LastActivityAt.Format(time.RFC3339),
		}
		if c.MutedUntil != nil {
			s := c.MutedUntil.Format(time.RFC3339)
			item.MutedUntil = &s
		}
		if c.LastMessage != nil {
			preview := c.LastMessage.Content
			if len(preview) > 100 {
				preview = preview[:100]
			}
			item.LastMessage = &dto.LastMessagePreview{
				ID:                c.LastMessage.ID.String(),
				SenderUserID:      c.LastMessage.SenderUserID.String(),
				SenderDisplayName: c.LastMessage.SenderDisplayName,
				ContentPreview:    preview,
				SentAt:            c.LastMessage.SentAt.Format(time.RFC3339),
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
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.CreateConversationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if strings.TrimSpace(req.Type) != "direct" {
		writeError(w, http.StatusBadRequest, "only direct conversations can be created via this endpoint")
		return
	}

	if len(req.ParticipantUserIDs) != 1 {
		writeError(w, http.StatusBadRequest, "exactly one participant is required for direct chats")
		return
	}

	participantID, err := uuid.Parse(strings.TrimSpace(req.ParticipantUserIDs[0]))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid participant user id")
		return
	}

	conv, err := h.conversationUC.CreateDirectConversation(r.Context(), app.CreateDirectConversationInput{
		ActorUserID:       actorUserID,
		ParticipantUserID: participantID,
	})
	if err != nil {
		h.writeAppError(w, err, "create conversation failed")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"id": conv.ID.String()})
}

func (h *Handler) handleConversationRoutes(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/conversations/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	parts := strings.Split(path, "/")
	convID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid conversation id")
		return
	}

	if len(parts) == 1 {
		if r.Method == http.MethodGet {
			h.GetConversation(w, r, convID)
			return
		}
		if r.Method == http.MethodDelete {
			writeError(w, http.StatusNotImplemented, "not implemented")
			return
		}
		writeError(w, http.StatusNotFound, "not found")
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
				writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			}
			return
		}
		if len(parts) == 3 {
			msgID, err := uuid.Parse(parts[2])
			if err != nil {
				writeError(w, http.StatusBadRequest, "invalid message id")
				return
			}
			switch r.Method {
			case http.MethodPatch:
				h.EditMessage(w, r, convID, msgID)
			case http.MethodDelete:
				h.DeleteMessage(w, r, convID, msgID)
			default:
				writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			}
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
		switch r.Method {
		case http.MethodPost:
			h.PinMessage(w, r, convID)
			return
		case http.MethodDelete:
			h.UnpinMessage(w, r, convID)
			return
		}
	}

	writeError(w, http.StatusNotFound, "not found")
}

func (h *Handler) GetConversation(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	conv, err := h.conversationUC.GetConversationByID(r.Context(), convID, actorUserID)
	if err != nil {
		h.writeAppError(w, err, "get conversation failed")
		return
	}

	detail := dto.ConversationDetail{
		ID:             conv.ID.String(),
		Type:           conv.Type,
		Title:          conv.Title,
		AvatarFileID:   conv.AvatarFileID,
		CreatedAt:      conv.CreatedAt.Format(time.RFC3339),
		UnreadCount:    conv.UnreadCount,
		LastActivityAt: conv.LastActivityAt.Format(time.RFC3339),
	}
	if conv.ActivityID != nil {
		s := conv.ActivityID.String()
		detail.ActivityID = &s
	}
	if conv.MutedUntil != nil {
		s := conv.MutedUntil.Format(time.RFC3339)
		detail.MutedUntil = &s
	}

	detail.Participants = make([]dto.ParticipantInfo, 0, len(conv.Participants))
	for _, p := range conv.Participants {
		detail.Participants = append(detail.Participants, dto.ParticipantInfo{
			UserID:       p.UserID.String(),
			DisplayName:  p.DisplayName,
			AvatarFileID: p.AvatarFileID,
			Role:         p.Role,
			JoinedAt:     p.JoinedAt.Format(time.RFC3339),
		})
	}

	if conv.PinnedMessage != nil {
		detail.PinnedMessage = &dto.PinnedMessageInfo{
			ID:                conv.PinnedMessage.ID.String(),
			SenderUserID:      conv.PinnedMessage.SenderUserID.String(),
			SenderDisplayName: conv.PinnedMessage.SenderDisplayName,
			Content:           conv.PinnedMessage.Content,
			SentAt:            conv.PinnedMessage.SentAt.Format(time.RFC3339),
		}
	}

	writeJSON(w, http.StatusOK, detail)
}

func (h *Handler) SendMessage(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.SendMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	var replyTo *uuid.UUID
	if req.ReplyToMessageID != nil {
		parsed, err := uuid.Parse(strings.TrimSpace(*req.ReplyToMessageID))
		if err == nil {
			replyTo = &parsed
		}
	}

	msg, err := h.messageUC.SendMessage(r.Context(), app.SendMessageInput{
		ConversationID:   convID,
		SenderUserID:     actorUserID,
		Type:             req.Type,
		Content:          req.Content,
		FileIDs:          req.FileIDs,
		ReplyToMessageID: replyTo,
	})
	if err != nil {
		h.writeAppError(w, err, "send message failed")
		return
	}

	writeJSON(w, http.StatusCreated, dto.MessageResponse{
		ID:           msg.ID.String(),
		SenderUserID: msg.SenderUserID.String(),
		Type:         msg.Type,
		Content:      msg.Content,
		FileIDs:      msg.FileIDs,
		SentAt:       msg.SentAt.Format(time.RFC3339),
	})
}

func (h *Handler) ListMessages(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
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
		if err == nil {
			cursor = &parsed
		}
	}

	msgs, err := h.messageUC.ListMessages(r.Context(), convID, actorUserID, limit, cursor, direction)
	if err != nil {
		h.writeAppError(w, err, "list messages failed")
		return
	}

	items := make([]dto.MessageResponse, 0, len(msgs))
	for _, m := range msgs {
		item := dto.MessageResponse{
			ID:                m.ID.String(),
			SenderUserID:      m.SenderUserID.String(),
			SenderDisplayName: m.SenderDisplayName,
			Type:              m.Type,
			Content:           m.Content,
			FileIDs:           m.FileIDs,
			SentAt:            m.SentAt.Format(time.RFC3339),
		}
		if m.ReplyToMessageID != nil {
			s := m.ReplyToMessageID.String()
			item.ReplyToMessageID = &s
		}
		if m.EditedAt != nil {
			s := m.EditedAt.Format(time.RFC3339)
			item.EditedAt = &s
		}
		if m.DeletedAt != nil {
			s := m.DeletedAt.Format(time.RFC3339)
			item.DeletedAt = &s
		}
		items = append(items, item)
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
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.EditMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	msg, err := h.messageUC.EditMessage(r.Context(), convID, msgID, actorUserID, req.Content)
	if err != nil {
		h.writeAppError(w, err, "edit message failed")
		return
	}

	writeJSON(w, http.StatusOK, dto.MessageResponse{
		ID:           msg.ID.String(),
		SenderUserID: msg.SenderUserID.String(),
		Type:         msg.Type,
		Content:      msg.Content,
		SentAt:       msg.SentAt.Format(time.RFC3339),
	})
}

func (h *Handler) DeleteMessage(w http.ResponseWriter, r *http.Request, convID, msgID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	if err := h.messageUC.DeleteMessage(r.Context(), convID, msgID, actorUserID); err != nil {
		h.writeAppError(w, err, "delete message failed")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) MarkRead(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.MarkReadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	msgID, err := uuid.Parse(strings.TrimSpace(req.LastReadMessageID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid message id")
		return
	}

	if err := h.messageUC.MarkRead(r.Context(), convID, actorUserID, msgID); err != nil {
		h.writeAppError(w, err, "mark read failed")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) Typing(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	_ = h.messageUC.PublishTyping(r.Context(), convID, actorUserID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) MuteConversation(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.MuteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	var until *time.Time
	if req.Until != nil {
		parsed, err := time.Parse(time.RFC3339, *req.Until)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid until time")
			return
		}
		until = &parsed
	}

	if err := h.conversationUC.MuteConversation(r.Context(), app.MuteInput{
		ConversationID: convID,
		ActorUserID:    actorUserID,
		Until:          until,
	}); err != nil {
		h.writeAppError(w, err, "mute conversation failed")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) LeaveConversation(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	if err := h.conversationUC.LeaveConversation(r.Context(), convID, actorUserID); err != nil {
		h.writeAppError(w, err, "leave conversation failed")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) PinMessage(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.PinRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	msgID, err := uuid.Parse(strings.TrimSpace(req.MessageID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid message id")
		return
	}

	if err := h.conversationUC.PinMessage(r.Context(), convID, msgID, actorUserID); err != nil {
		h.writeAppError(w, err, "pin message failed")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) UnpinMessage(w http.ResponseWriter, r *http.Request, convID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	if err := h.conversationUC.UnpinMessage(r.Context(), convID, actorUserID); err != nil {
		h.writeAppError(w, err, "unpin message failed")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) writeAppError(w http.ResponseWriter, err error, fallback string) {
	switch {
	case errors.Is(err, app.ErrInvalidConversationID),
		errors.Is(err, app.ErrInvalidMessageID),
		errors.Is(err, app.ErrInvalidUserID),
		errors.Is(err, app.ErrMessageTooLong),
		errors.Is(err, app.ErrTooManyFiles),
		errors.Is(err, app.ErrDirectChatCannotLeave),
		errors.Is(err, app.ErrCannotPinInDirectChat),
		errors.Is(err, app.ErrMessageEditExpired),
		errors.Is(err, app.ErrMessageAlreadyDeleted):
		writeError(w, http.StatusBadRequest, err.Error())

	case errors.Is(err, app.ErrConversationNotFound),
		errors.Is(err, app.ErrMessageNotFound),
		errors.Is(err, app.ErrParticipantNotFound):
		writeError(w, http.StatusNotFound, err.Error())

	case errors.Is(err, app.ErrAccessDenied),
		errors.Is(err, app.ErrNotParticipant),
		errors.Is(err, app.ErrNotAdmin),
		errors.Is(err, app.ErrNotMessageAuthor):
		writeError(w, http.StatusForbidden, err.Error())

	case errors.Is(err, app.ErrConversationFull):
		writeError(w, http.StatusConflict, err.Error())

	default:
		log.Error().Err(err).Msg(fallback)
		writeError(w, http.StatusInternalServerError, "internal error")
	}
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
