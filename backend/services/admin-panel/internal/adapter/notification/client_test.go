package notification

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

func TestClientSendsInternalNotificationRequest(t *testing.T) {
	t.Parallel()

	recipientID := uuid.New()
	var gotPath string
	var gotHeaders http.Header
	var gotPayload map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.Path
		gotHeaders = r.Header.Clone()
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode request body: %v", err)
		}
		w.WriteHeader(http.StatusAccepted)
	}))
	t.Cleanup(server.Close)

	client := New(server.URL, "internal-token", "admin-panel", time.Second)
	err := client.SendUserNotification(t.Context(), port.UserNotificationInput{
		IdempotencyKey:   "admin:moderation:activity-approve:activity_approved",
		RecipientUserIDs: []uuid.UUID{uuid.Nil, recipientID},
		Category:         "activity",
		Priority:         "normal",
		Title:            "Activity approved",
		Body:             "Your activity is visible to travelers.",
		DeepLink:         "/activities/activity-id",
		Data: map[string]string{
			"adminEvent": "activity_approved",
			"targetType": "ACTIVITY",
		},
		CollapseKey: "admin:moderation:activity:activity-id",
		TTL:         6 * time.Hour,
	})

	if err != nil {
		t.Fatalf("SendUserNotification() error = %v", err)
	}
	if gotPath != "/internal/v1/notifications/send" {
		t.Fatalf("path = %q", gotPath)
	}
	if gotHeaders.Get("X-Internal-Service-Token") != "internal-token" {
		t.Fatalf("internal token header = %q", gotHeaders.Get("X-Internal-Service-Token"))
	}
	if gotHeaders.Get("X-Service-Name") != "admin-panel" {
		t.Fatalf("service name header = %q", gotHeaders.Get("X-Service-Name"))
	}
	if gotPayload["sourceService"] != "admin-panel" ||
		gotPayload["category"] != "activity" ||
		gotPayload["priority"] != "normal" ||
		gotPayload["ttlSeconds"] != float64((6*time.Hour).Seconds()) {
		t.Fatalf("payload = %#v", gotPayload)
	}
	recipients, ok := gotPayload["recipientUserIds"].([]any)
	if !ok || len(recipients) != 1 || recipients[0] != recipientID.String() {
		t.Fatalf("recipientUserIds = %#v, want only %s", gotPayload["recipientUserIds"], recipientID)
	}
	data, ok := gotPayload["data"].(map[string]any)
	if !ok || data["adminEvent"] != "activity_approved" || data["targetType"] != "ACTIVITY" {
		t.Fatalf("data = %#v", gotPayload["data"])
	}
}
