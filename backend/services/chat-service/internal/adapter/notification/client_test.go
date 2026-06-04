package notification

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/chat-service/internal/domain/port"
)

func TestSendChatMessageNotificationCallsInternalNotificationEndpoint(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	messageID := uuid.New()
	senderID := uuid.New()
	recipientID := uuid.New()

	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodPost || r.URL.Path != "/internal/v1/notifications/send" {
			t.Fatalf("unexpected request %s %s", r.Method, r.URL.Path)
		}
		if got := r.Header.Get("X-Internal-Service-Token"); got != "internal-token" {
			t.Fatalf("X-Internal-Service-Token = %q", got)
		}
		if got := r.Header.Get("X-Service-Name"); got != "chat-service" {
			t.Fatalf("X-Service-Name = %q", got)
		}
		if got := r.Header.Get("Idempotency-Key"); got != "chat-message-123" {
			t.Fatalf("Idempotency-Key = %q", got)
		}

		var req map[string]any
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		if req["idempotencyKey"] != "chat-message-123" ||
			req["sourceService"] != "chat-service" ||
			req["category"] != "chat" ||
			req["priority"] != "normal" ||
			req["title"] != "Aigerim" ||
			req["body"] != "Meet near the north gate" ||
			req["deepLink"] != "/chats/"+conversationID.String() ||
			req["collapseKey"] != "chat:"+conversationID.String() ||
			req["ttlSeconds"] != float64(86400) {
			t.Fatalf("unexpected request body: %+v", req)
		}
		recipients, ok := req["recipientUserIds"].([]any)
		if !ok || len(recipients) != 1 || recipients[0] != recipientID.String() {
			t.Fatalf("recipientUserIds = %+v, want %s", req["recipientUserIds"], recipientID)
		}
		data, ok := req["data"].(map[string]any)
		if !ok {
			t.Fatalf("data = %+v, want object", req["data"])
		}
		if data["type"] != "chat_message" ||
			data["conversationId"] != conversationID.String() ||
			data["messageId"] != messageID.String() ||
			data["senderUserId"] != senderID.String() ||
			data["chatType"] != "group" ||
			data["messageType"] != "text" {
			t.Fatalf("unexpected data payload: %+v", data)
		}

		return jsonResponse(http.StatusAccepted, map[string]any{
			"requestId": uuid.NewString(),
			"status":    "accepted",
		}), nil
	})

	client := NewClient(
		"https://notification-service.local",
		"internal-token",
		"chat-service",
		&http.Client{Transport: transport},
	)

	err := client.SendChatMessageNotification(t.Context(), port.ChatNotification{
		IdempotencyKey:    "chat-message-123",
		ConversationID:    conversationID,
		MessageID:         messageID,
		SenderUserID:      senderID,
		SenderDisplayName: "Aigerim",
		ConversationType:  "group",
		MessageType:       "text",
		Body:              "Meet near the north gate",
		RecipientUserIDs:  []uuid.UUID{recipientID},
	})
	if err != nil {
		t.Fatalf("SendChatMessageNotification error: %v", err)
	}
}

func TestSendChatMessageNotificationIncludesReactionEventData(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	messageID := uuid.New()
	actorID := uuid.New()
	recipientID := uuid.New()

	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		var req map[string]any
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		if req["body"] != "Reacted 👍 to your message" {
			t.Fatalf("body = %q", req["body"])
		}
		data, ok := req["data"].(map[string]any)
		if !ok {
			t.Fatalf("data = %+v, want object", req["data"])
		}
		if data["type"] != "chat_reaction" ||
			data["reactionEmoji"] != "👍" ||
			data["actorUserId"] != actorID.String() ||
			data["conversationId"] != conversationID.String() ||
			data["messageId"] != messageID.String() {
			t.Fatalf("unexpected data payload: %+v", data)
		}

		return jsonResponse(http.StatusAccepted, map[string]any{
			"requestId": uuid.NewString(),
			"status":    "accepted",
		}), nil
	})

	client := NewClient(
		"https://notification-service.local",
		"internal-token",
		"chat-service",
		&http.Client{Transport: transport},
	)

	err := client.SendChatMessageNotification(t.Context(), port.ChatNotification{
		IdempotencyKey:    "chat-reaction-123",
		EventType:         "chat_reaction",
		ConversationID:    conversationID,
		MessageID:         messageID,
		SenderUserID:      actorID,
		SenderDisplayName: "Aigerim",
		ConversationType:  "group",
		MessageType:       "text",
		ReactionEmoji:     "👍",
		Body:              "Reacted 👍 to your message",
		RecipientUserIDs:  []uuid.UUID{recipientID},
	})
	if err != nil {
		t.Fatalf("SendChatMessageNotification error: %v", err)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}

func jsonResponse(status int, payload any) *http.Response {
	builder := new(strings.Builder)
	_ = json.NewEncoder(builder).Encode(payload)

	return &http.Response{
		StatusCode: status,
		Header:     http.Header{"Content-Type": []string{"application/json"}},
		Body:       io.NopCloser(strings.NewReader(builder.String())),
	}
}
