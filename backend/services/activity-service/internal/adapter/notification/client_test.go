package notification

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

func TestClientSendsActivityNotificationToInternalEndpoint(t *testing.T) {
	t.Parallel()

	recipientID := uuid.New()
	var gotToken string
	var gotService string
	var gotPayload map[string]any

	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotToken = r.Header.Get("X-Internal-Service-Token")
		gotService = r.Header.Get("X-Service-Name")
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode request body: %v", err)
		}
		if r.URL.String() != "http://notification.test/internal/v1/notifications/send" {
			t.Fatalf("url = %q", r.URL.String())
		}
		return &http.Response{
			StatusCode: http.StatusAccepted,
			Body:       io.NopCloser(bytes.NewReader(nil)),
			Header:     make(http.Header),
			Request:    r,
		}, nil
	})

	client := New("http://notification.test", "internal-token", "activity-service", time.Second)
	client.httpClient = &http.Client{Transport: transport}
	err := client.SendActivityNotification(context.Background(), port.ActivityNotificationInput{
		IdempotencyKey:   "activity:test",
		RecipientUserIDs: []uuid.UUID{uuid.Nil, recipientID},
		Category:         "activity",
		Priority:         "high",
		Title:            "Activity cancelled",
		Body:             "Trip was cancelled.",
		DeepLink:         "/activities/" + recipientID.String(),
		Data: map[string]string{
			"activityEvent": "activity_cancelled",
		},
		CollapseKey: "activity:test:lifecycle",
		TTL:         24 * time.Hour,
	})
	if err != nil {
		t.Fatalf("SendActivityNotification() error = %v", err)
	}

	if gotToken != "internal-token" || gotService != "activity-service" {
		t.Fatalf("headers token/service = %q/%q", gotToken, gotService)
	}
	if gotPayload["sourceService"] != "activity-service" ||
		gotPayload["idempotencyKey"] != "activity:test" ||
		gotPayload["category"] != "activity" ||
		gotPayload["priority"] != "high" ||
		gotPayload["ttlSeconds"] != float64(86400) {
		t.Fatalf("payload = %#v", gotPayload)
	}

	recipients, ok := gotPayload["recipientUserIds"].([]any)
	if !ok || len(recipients) != 1 || recipients[0] != recipientID.String() {
		t.Fatalf("recipientUserIds = %#v", gotPayload["recipientUserIds"])
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}
