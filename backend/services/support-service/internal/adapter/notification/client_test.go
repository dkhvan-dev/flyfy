package notification

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"testing"
	"time"

	"kz/inflap/backend/services/support-service/internal/app"
)

func TestClientSendsSupportOperatorNotificationToInternalEndpoint(t *testing.T) {
	t.Parallel()

	operatorID := "11111111-1111-4111-8111-111111111111"
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

	client := New("http://notification.test", "internal-token", "support-service", []string{"", operatorID}, time.Second)
	client.httpClient = &http.Client{Transport: transport}

	err := client.NotifySupportOperators(context.Background(), app.SupportOperatorNotificationInput{
		IdempotencyKey: "support:ticket:ticket-1:sla_breached",
		Category:       "support",
		Priority:       "high",
		Title:          "Support SLA breached",
		Body:           "SLA breached for payment support ticket.",
		DeepLink:       "/admin/support/tickets/ticket-1",
		Data:           map[string]string{"event": "support_ticket_sla_breached"},
		CollapseKey:    "support:ticket:ticket-1:sla",
		TTL:            24 * time.Hour,
	})
	if err != nil {
		t.Fatalf("NotifySupportOperators returned error: %v", err)
	}

	if gotToken != "internal-token" || gotService != "support-service" {
		t.Fatalf("headers token/service = %q/%q", gotToken, gotService)
	}
	if gotPayload["sourceService"] != "support-service" ||
		gotPayload["idempotencyKey"] != "support:ticket:ticket-1:sla_breached" ||
		gotPayload["category"] != "support" ||
		gotPayload["priority"] != "high" ||
		gotPayload["ttlSeconds"] != float64(86400) {
		t.Fatalf("payload = %#v", gotPayload)
	}
	recipients, ok := gotPayload["recipientUserIds"].([]any)
	if !ok || len(recipients) != 1 || recipients[0] != operatorID {
		t.Fatalf("recipientUserIds = %#v", gotPayload["recipientUserIds"])
	}
}

func TestClientSendsSupportUserNotificationToSpecificUser(t *testing.T) {
	t.Parallel()

	userID := "22222222-2222-4222-8222-222222222222"
	operatorID := "11111111-1111-4111-8111-111111111111"
	var gotPayload map[string]any

	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode request body: %v", err)
		}
		if r.Header.Get("X-Internal-Service-Token") != "internal-token" ||
			r.Header.Get("X-Service-Name") != "support-service" {
			t.Fatalf("headers token/service = %q/%q", r.Header.Get("X-Internal-Service-Token"), r.Header.Get("X-Service-Name"))
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

	client := New("http://notification.test", "internal-token", "support-service", []string{operatorID}, time.Second)
	client.httpClient = &http.Client{Transport: transport}

	err := client.NotifySupportUser(context.Background(), userID, app.SupportUserNotificationInput{
		IdempotencyKey: "support:ticket:ticket-1:reply:chat-message-456",
		Category:       "support",
		Priority:       "normal",
		Title:          "Support replied",
		Body:           "Support replied to your ticket.",
		DeepLink:       "/help/support",
		Data:           map[string]string{"event": "support_ticket_replied", "ticketId": "ticket-1"},
		CollapseKey:    "support:ticket:ticket-1",
		TTL:            24 * time.Hour,
	})
	if err != nil {
		t.Fatalf("NotifySupportUser returned error: %v", err)
	}

	recipients, ok := gotPayload["recipientUserIds"].([]any)
	if !ok || len(recipients) != 1 || recipients[0] != userID {
		t.Fatalf("recipientUserIds = %#v", gotPayload["recipientUserIds"])
	}
	if recipients[0] == operatorID {
		t.Fatalf("user notification was sent to operator id")
	}
	if gotPayload["sourceService"] != "support-service" ||
		gotPayload["idempotencyKey"] != "support:ticket:ticket-1:reply:chat-message-456" ||
		gotPayload["deepLink"] != "/help/support" ||
		gotPayload["ttlSeconds"] != float64(86400) {
		t.Fatalf("payload = %#v", gotPayload)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}
