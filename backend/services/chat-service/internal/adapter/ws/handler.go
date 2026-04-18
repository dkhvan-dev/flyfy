package ws

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/port"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

type WSHandler struct {
	hub       *Hub
	repo      port.ChatRepository
	messageUC *app.MessageUseCase
}

func NewWSHandler(hub *Hub, repo port.ChatRepository, messageUC *app.MessageUseCase) *WSHandler {
	return &WSHandler{hub: hub, repo: repo, messageUC: messageUC}
}

func (h *WSHandler) HandleUpgrade(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Error().Err(err).Msg("websocket upgrade failed")
		return
	}

	participants, err := h.repo.ListConversationsByUserID(r.Context(), port.ConversationFilter{
		UserID: &userID,
		Limit:  1000,
	})
	if err != nil {
		log.Error().Err(err).Msg("load user conversations for ws")
		_ = conn.Close()
		return
	}

	conversationIDs := make([]string, 0, len(participants))
	for _, c := range participants {
		conversationIDs = append(conversationIDs, c.ID.String())
	}

	wsConn := NewWSConn(conn, userID.String())
	h.hub.Register(userID.String(), wsConn, conversationIDs)

	go wsConn.WritePump()
	go wsConn.ReadPump(h.onMessage, h.onClose)
}

type clientMessage struct {
	Type string          `json:"type"`
	Data json.RawMessage `json:"data"`
}

type typingData struct {
	ConversationID string `json:"conversationId"`
}

func (h *WSHandler) onMessage(userID string, data []byte) {
	var msg clientMessage
	if err := json.Unmarshal(data, &msg); err != nil {
		return
	}

	uid, err := uuid.Parse(userID)
	if err != nil {
		return
	}

	switch msg.Type {
	case "typing":
		var td typingData
		if err := json.Unmarshal(msg.Data, &td); err != nil {
			return
		}
		convID, err := uuid.Parse(td.ConversationID)
		if err != nil {
			return
		}
		_ = h.messageUC.PublishTyping(context.Background(), convID, uid)
	}
}

func (h *WSHandler) onClose(userID string) {
	h.hub.Unregister(userID)
}
