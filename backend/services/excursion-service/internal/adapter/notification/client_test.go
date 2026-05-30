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

	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

func TestClientSendsExcursionNotificationToInternalEndpoint(t *testing.T) {
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

	client := New("http://notification.test", "internal-token", "excursion-service", time.Second)
	client.httpClient = &http.Client{Transport: transport}
	err := client.SendExcursionNotification(context.Background(), port.ExcursionNotificationInput{
		IdempotencyKey:   "excursion:test",
		RecipientUserIDs: []uuid.UUID{uuid.Nil, recipientID},
		Category:         "excursion",
		Priority:         "high",
		Title:            "Excursion cancelled",
		Body:             "Your excursion was cancelled.",
		DeepLink:         "/me/excursions",
		Data: map[string]string{
			"excursionEvent": "schedule_slot_cancelled",
		},
		CollapseKey: "excursion:slot:test:lifecycle",
		TTL:         24 * time.Hour,
	})
	if err != nil {
		t.Fatalf("SendExcursionNotification() error = %v", err)
	}

	if gotToken != "internal-token" || gotService != "excursion-service" {
		t.Fatalf("headers token/service = %q/%q", gotToken, gotService)
	}
	if gotPayload["sourceService"] != "excursion-service" ||
		gotPayload["idempotencyKey"] != "excursion:test" ||
		gotPayload["category"] != "excursion" ||
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
