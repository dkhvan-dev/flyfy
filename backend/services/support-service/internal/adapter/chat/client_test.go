package chat

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"kz/inflap/backend/services/support-service/internal/app"
)

func TestClientSendSupportMessageUsesChatServiceMessageEndpoint(t *testing.T) {
	var capturedPath string
	var capturedHeaders http.Header
	var capturedBody map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		capturedPath = r.URL.Path
		capturedHeaders = r.Header.Clone()
		if err := json.NewDecoder(r.Body).Decode(&capturedBody); err != nil {
			t.Fatalf("decode request body: %v", err)
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		_, _ = w.Write([]byte(`{"id":"message-123"}`))
	}))
	defer server.Close()

	client := NewClient(server.URL, time.Second, "internal-token", "support-auth-subject")
	result, err := client.SendSupportMessage(context.Background(), app.SupportChatMessageInput{
		ConversationID:   "conversation-123",
		ActorID:          "agent-1",
		ActorDisplayName: "Айгерим",
		Message:          "Здравствуйте! Мы уже проверяем ваш вопрос.",
		FileIDs:          []string{"file-1", "", "file-2", "file-1"},
		ClientMessageID:  "11111111-1111-4111-8111-111111111111",
	})
	if err != nil {
		t.Fatalf("SendSupportMessage returned error: %v", err)
	}

	if result.MessageID != "message-123" {
		t.Fatalf("message id = %q, want message-123", result.MessageID)
	}
	if capturedPath != "/v1/conversations/conversation-123/messages" {
		t.Fatalf("path = %q", capturedPath)
	}
	if capturedHeaders.Get("X-Auth-Subject") != "support-auth-subject" {
		t.Fatalf("X-Auth-Subject = %q", capturedHeaders.Get("X-Auth-Subject"))
	}
	if capturedHeaders.Get("X-Internal-Service-Token") != "internal-token" {
		t.Fatalf("internal token header = %q", capturedHeaders.Get("X-Internal-Service-Token"))
	}
	if capturedHeaders.Get("X-User-Roles") != "SUPPORT_AGENT,SUPPORT_ADMIN" {
		t.Fatalf("X-User-Roles = %q", capturedHeaders.Get("X-User-Roles"))
	}
	if capturedBody["type"] != "file" || capturedBody["content"] != "Здравствуйте! Мы уже проверяем ваш вопрос." {
		t.Fatalf("body = %#v", capturedBody)
	}
	if capturedBody["senderDisplayName"] != "Айгерим" {
		t.Fatalf("senderDisplayName = %#v", capturedBody["senderDisplayName"])
	}
	fileIDs, ok := capturedBody["fileIds"].([]any)
	if !ok || len(fileIDs) != 2 || fileIDs[0] != "file-1" || fileIDs[1] != "file-2" {
		t.Fatalf("fileIds = %#v", capturedBody["fileIds"])
	}
	if capturedBody["clientMessageId"] != "11111111-1111-4111-8111-111111111111" {
		t.Fatalf("clientMessageId = %#v", capturedBody["clientMessageId"])
	}
}

func TestClientEnsureSupportConversationCreatesDirectChat(t *testing.T) {
	var capturedPath string
	var capturedHeaders http.Header
	var capturedBody map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		capturedPath = r.URL.Path
		capturedHeaders = r.Header.Clone()
		if err := json.NewDecoder(r.Body).Decode(&capturedBody); err != nil {
			t.Fatalf("decode request body: %v", err)
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		_, _ = w.Write([]byte(`{"id":"conversation-created"}`))
	}))
	defer server.Close()

	client := NewClient(server.URL, time.Second, "internal-token", "support-auth-subject")
	result, err := client.EnsureSupportConversation(context.Background(), "user-123")
	if err != nil {
		t.Fatalf("EnsureSupportConversation returned error: %v", err)
	}

	if result.ConversationID != "conversation-created" {
		t.Fatalf("conversation id = %q, want conversation-created", result.ConversationID)
	}
	if capturedPath != "/v1/conversations" {
		t.Fatalf("path = %q", capturedPath)
	}
	if capturedHeaders.Get("X-Auth-Subject") != "support-auth-subject" {
		t.Fatalf("X-Auth-Subject = %q", capturedHeaders.Get("X-Auth-Subject"))
	}
	if capturedBody["type"] != "direct" {
		t.Fatalf("type = %#v", capturedBody["type"])
	}
	participantIDs, ok := capturedBody["participantUserIds"].([]any)
	if !ok || len(participantIDs) != 1 || participantIDs[0] != "user-123" {
		t.Fatalf("participantUserIds = %#v", capturedBody["participantUserIds"])
	}
}
