package ws

import (
	"encoding/json"
	"sync"

	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/event"
)

type Hub struct {
	mu          sync.RWMutex
	connections map[string]*WSConn
	userChats   map[string][]string
}

func NewHub() *Hub {
	return &Hub{
		connections: make(map[string]*WSConn),
		userChats:   make(map[string][]string),
	}
}

func (h *Hub) Register(userID string, conn *WSConn, conversationIDs []string) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if old, ok := h.connections[userID]; ok {
		old.Close()
	}

	h.connections[userID] = conn
	h.userChats[userID] = conversationIDs
}

func (h *Hub) Unregister(userID string) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if conn, ok := h.connections[userID]; ok {
		conn.Close()
	}
	delete(h.connections, userID)
	delete(h.userChats, userID)
}

func (h *Hub) AddConversation(userID, conversationID string) {
	h.mu.Lock()
	defer h.mu.Unlock()

	chats := h.userChats[userID]
	for _, c := range chats {
		if c == conversationID {
			return
		}
	}
	h.userChats[userID] = append(chats, conversationID)
}

func (h *Hub) HandleEvent(evt event.Event) {
	convID := evt.ConversationID.String()

	data, err := json.Marshal(wsMessage{
		Type: evt.Type,
		Data: evt,
	})
	if err != nil {
		log.Error().Err(err).Msg("marshal ws event")
		return
	}

	h.mu.RLock()
	defer h.mu.RUnlock()

	for userID, chats := range h.userChats {
		for _, chatID := range chats {
			if chatID == convID {
				if conn, ok := h.connections[userID]; ok {
					conn.Send(data)
				}
				break
			}
		}
	}
}

type wsMessage struct {
	Type string `json:"type"`
	Data any    `json:"data"`
}
