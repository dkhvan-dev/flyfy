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
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/model"
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
	mux.HandleFunc("POST /v1/internal/activity-conversations/participants", h.EnsureActivityParticipant)
	mux.HandleFunc("POST /v1/internal/activity-conversations/sync", h.SyncActivityConversation)
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
			if len(preview) > 100 {
				preview = preview[:100]
			}
			item.LastMessage = &dto.LastMessagePreview{
				ID:                c.LastMessage.ID.String(),
				SenderUserID:      c.LastMessage.SenderUserID.String(),
				SenderDisplayName: c.LastMessage.SenderDisplayName,
				Type:              c.LastMessage.Type,
				ContentPreview:    preview,
				FileIDs:           append([]string(nil), c.LastMessage.FileIDs...),
				StickerID:         uuidPtrToString(c.LastMessage.StickerID),
				StickerFileID:     c.LastMessage.StickerFileID,
				SentAt:            c.LastMessage.SentAt.Format(time.RFC3339),
			}
			if c.LastMessage.DeletedAt != nil {
				s := c.LastMessage.DeletedAt.UTC().Format(time.RFC3339)
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
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.CreateConversationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	switch strings.TrimSpace(req.Type) {
	case "direct":
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

	case "activity":
		activityID, err := uuid.Parse(strings.TrimSpace(req.ActivityID))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid activity id")
			return
		}

		conv, err := h.conversationUC.CreateActivityConversation(r.Context(), app.CreateActivityConversationInput{
			ActivityID: activityID,
			Title:      strings.TrimSpace(req.Title),
			HostUserID: actorUserID,
		})
		if err != nil {
			h.writeAppError(w, err, "create activity conversation failed")
			return
		}

		writeJSON(w, http.StatusCreated, map[string]string{"id": conv.ID.String()})

	default:
		writeError(w, http.StatusBadRequest, "unsupported conversation type")
	}
}

func (h *Handler) EnsureActivityParticipant(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, http.StatusUnauthorized, "missing internal service token")
		return
	}

	var req dto.EnsureActivityParticipantRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	activityID, err := uuid.Parse(strings.TrimSpace(req.ActivityID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid activity id")
		return
	}

	hostUserID, err := uuid.Parse(strings.TrimSpace(req.HostUserID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid host user id")
		return
	}

	userID, err := uuid.Parse(strings.TrimSpace(req.UserID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid user id")
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
		h.writeAppError(w, err, "ensure activity participant failed")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"id": conv.ID.String()})
}

func (h *Handler) SyncActivityConversation(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, http.StatusUnauthorized, "missing internal service token")
		return
	}

	var req dto.SyncActivityConversationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	activityID, err := uuid.Parse(strings.TrimSpace(req.ActivityID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid activity id")
		return
	}

	conv, err := h.conversationUC.SyncActivityConversation(r.Context(), app.SyncActivityConversationInput{
		ActivityID:              activityID,
		ActivityTitle:           req.ActivityTitle,
		ActivityAvatarFileID:    req.ActivityAvatarFileID,
		MessagingAvailableUntil: parseOptionalTime(req.MessagingAvailableUntil),
	})
	if err != nil {
		h.writeAppError(w, err, "sync activity conversation failed")
		return
	}
	if conv == nil {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"id": conv.ID.String()})
}

func (h *Handler) handleConversationRoutes(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/conversations/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	parts := strings.Split(path, "/")

	// GET /v1/conversations/by-activity/{activityId}
	if parts[0] == "by-activity" && r.Method == http.MethodGet {
		if len(parts) < 2 {
			writeError(w, http.StatusBadRequest, "missing activity id")
			return
		}
		activityID, err := uuid.Parse(parts[1])
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid activity id")
			return
		}
		h.GetConversationByActivity(w, r, activityID)
		return
	}

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
		if len(parts) == 4 && parts[3] == "reaction" {
			msgID, err := uuid.Parse(parts[2])
			if err != nil {
				writeError(w, http.StatusBadRequest, "invalid message id")
				return
			}
			if r.Method == http.MethodPost {
				h.ReactToMessage(w, r, convID, msgID)
				return
			}
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
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
				writeError(w, http.StatusBadRequest, "invalid message id")
				return
			}
			h.UnpinMessage(w, r, convID, msgID)
			return
		case len(parts) == 2 && r.Method == http.MethodDelete:
			msgID, err := uuid.Parse(strings.TrimSpace(r.URL.Query().Get("messageId")))
			if err != nil {
				writeError(w, http.StatusBadRequest, "invalid message id")
				return
			}
			h.UnpinMessage(w, r, convID, msgID)
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
		ID:              conv.ID.String(),
		Type:            conv.Type,
		Title:           conv.Title,
		AvatarFileID:    conv.AvatarFileID,
		CreatedAt:       conv.CreatedAt.Format(time.RFC3339),
		UnreadCount:     conv.UnreadCount,
		CanSendMessages: !conv.IsMessagingClosed(time.Now().UTC()),
		LastActivityAt:  conv.LastActivityAt.Format(time.RFC3339),
	}
	if conv.ActivityID != nil {
		s := conv.ActivityID.String()
		detail.ActivityID = &s
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
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	conv, err := h.conversationUC.GetConversationByActivityID(r.Context(), activityID, actorUserID)
	if err != nil {
		h.writeAppError(w, err, "get conversation by activity failed")
		return
	}

	detail := dto.ConversationDetail{
		ID:              conv.ID.String(),
		Type:            conv.Type,
		Title:           conv.Title,
		AvatarFileID:    conv.AvatarFileID,
		CreatedAt:       conv.CreatedAt.Format(time.RFC3339),
		UnreadCount:     conv.UnreadCount,
		CanSendMessages: !conv.IsMessagingClosed(time.Now().UTC()),
		LastActivityAt:  conv.LastActivityAt.Format(time.RFC3339),
	}
	if conv.ActivityID != nil {
		s := conv.ActivityID.String()
		detail.ActivityID = &s
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
	var stickerID *uuid.UUID
	var stickerAccessUserID *uuid.UUID
	if req.StickerID != nil && strings.TrimSpace(*req.StickerID) != "" {
		parsed, err := uuid.Parse(strings.TrimSpace(*req.StickerID))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid sticker id")
			return
		}
		stickerID = &parsed

		if gatewayUserID := UserIDFromContext(r.Context()); gatewayUserID != "" {
			parsedGatewayUserID, err := uuid.Parse(gatewayUserID)
			if err != nil || parsedGatewayUserID == uuid.Nil {
				writeError(w, http.StatusUnauthorized, "invalid authenticated user")
				return
			}
			stickerAccessUserID = &parsedGatewayUserID
		}
	}

	msg, err := h.messageUC.SendMessage(r.Context(), app.SendMessageInput{
		ConversationID:      convID,
		SenderUserID:        actorUserID,
		StickerAccessUserID: stickerAccessUserID,
		Type:                req.Type,
		Content:             req.Content,
		FileIDs:             req.FileIDs,
		StickerID:           stickerID,
		ReplyToMessageID:    replyTo,
	})
	if err != nil {
		h.writeAppError(w, err, "send message failed")
		return
	}

	writeJSON(w, http.StatusCreated, messageResponseFromModel(msg))
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
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid message cursor")
			return
		}
		cursor = &parsed
	}

	msgs, err := h.messageUC.ListMessages(r.Context(), convID, actorUserID, limit, cursor, direction)
	if err != nil {
		h.writeAppError(w, err, "list messages failed")
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

	writeJSON(w, http.StatusOK, messageResponseFromModel(msg))
}

func (h *Handler) ReactToMessage(w http.ResponseWriter, r *http.Request, convID, msgID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.ReactMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
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
		h.writeAppError(w, err, "toggle message reaction failed")
		return
	}

	writeJSON(w, http.StatusOK, dto.MessageReactionResponse{
		MessageID: result.MessageID.String(),
		Reactions: reactionInfosFromModel(result.Reactions),
	})
}

func (h *Handler) DeleteMessage(w http.ResponseWriter, r *http.Request, convID, msgID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	result, err := h.messageUC.DeleteMessage(r.Context(), convID, msgID, actorUserID)
	if err != nil {
		h.writeAppError(w, err, "delete message failed")
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

	pins, err := h.conversationUC.PinMessage(r.Context(), convID, msgID, actorUserID)
	if err != nil {
		h.writeAppError(w, err, "pin message failed")
		return
	}

	writeJSON(w, http.StatusOK, dto.PinnedMessagesResponse{
		Items: pinnedMessageInfosFromModel(pins),
	})
}

func (h *Handler) UnpinMessage(w http.ResponseWriter, r *http.Request, convID, msgID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	pins, err := h.conversationUC.UnpinMessage(r.Context(), convID, msgID, actorUserID)
	if err != nil {
		h.writeAppError(w, err, "unpin message failed")
		return
	}

	writeJSON(w, http.StatusOK, dto.PinnedMessagesResponse{
		Items: pinnedMessageInfosFromModel(pins),
	})
}

func messageResponseFromModel(m *model.Message) dto.MessageResponse {
	item := dto.MessageResponse{
		ID:                 m.ID.String(),
		SenderUserID:       m.SenderUserID.String(),
		SenderDisplayName:  m.SenderDisplayName,
		SenderAvatarFileID: m.SenderAvatarFileID,
		Type:               m.Type,
		Content:            m.Content,
		FileIDs:            m.FileIDs,
		StickerID:          uuidPtrToString(m.StickerID),
		StickerFileID:      m.StickerFileID,
		Reactions:          reactionInfosFromModel(m.Reactions),
		SentAt:             m.SentAt.Format(time.RFC3339),
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
	return item
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

func (h *Handler) writeAppError(w http.ResponseWriter, err error, fallback string) {
	switch {
	case errors.Is(err, app.ErrInvalidConversationID),
		errors.Is(err, app.ErrInvalidActivityID),
		errors.Is(err, app.ErrInvalidMessageID),
		errors.Is(err, app.ErrInvalidUserID),
		errors.Is(err, app.ErrMessageTooLong),
		errors.Is(err, app.ErrInvalidMessageType),
		errors.Is(err, app.ErrInvalidStickerID),
		errors.Is(err, app.ErrInvalidReaction),
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
		errors.Is(err, app.ErrNotMessageAuthor),
		errors.Is(err, app.ErrConversationMessagingClosed):
		writeError(w, http.StatusForbidden, err.Error())

	case errors.Is(err, app.ErrStickerNotAvailable):
		writeError(w, http.StatusForbidden, err.Error())

	case errors.Is(err, app.ErrConversationFull):
		writeError(w, http.StatusConflict, err.Error())

	default:
		log.Error().Err(err).Msg(fallback)
		writeError(w, http.StatusInternalServerError, "internal error")
	}
}

func uuidPtrToString(value *uuid.UUID) *string {
	if value == nil {
		return nil
	}
	str := value.String()
	return &str
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
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
