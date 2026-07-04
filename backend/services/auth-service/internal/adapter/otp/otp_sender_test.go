package otp

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/rs/zerolog"
)

func TestNewEmailOTPSenderFallsBackToLogSenderWhenResendAPIKeyMissing(t *testing.T) {
	sender := NewEmailOTPSender(EmailSenderConfig{
		FromAddress: DefaultDevEmailOTPSenderAddress,
	}, zerolog.New(io.Discard))

	if _, ok := sender.(*LogEmailOTPSender); !ok {
		t.Fatalf("NewEmailOTPSender() = %T, want *LogEmailOTPSender without Resend API key", sender)
	}
}

func TestNewEmailOTPSenderUsesResendWhenConfigured(t *testing.T) {
	sender := NewEmailOTPSender(EmailSenderConfig{
		FromAddress:   "Inflap <onboarding@resend.dev>",
		ResendAPIKey:  "re_test_key",
		ResendBaseURL: "https://api.resend.com",
		ResendTimeout: time.Second,
	}, zerolog.New(io.Discard))

	resendSender, ok := sender.(*ResendEmailOTPSender)
	if !ok {
		t.Fatalf("NewEmailOTPSender() = %T, want *ResendEmailOTPSender with Resend API key", sender)
	}
	if resendSender.from != "Inflap <onboarding@resend.dev>" {
		t.Fatalf("Resend sender from = %q, want configured from address", resendSender.from)
	}
}

func TestResendEmailOTPSenderPostsVerificationEmail(t *testing.T) {
	var gotAuth string
	var gotContentType string
	var gotPayload struct {
		From    string   `json:"from"`
		To      []string `json:"to"`
		Subject string   `json:"subject"`
		Text    string   `json:"text"`
	}

	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodPost {
			t.Fatalf("method = %s, want POST", r.Method)
		}
		if r.URL.Path != "/emails" {
			t.Fatalf("path = %s, want /emails", r.URL.Path)
		}
		gotAuth = r.Header.Get("Authorization")
		gotContentType = r.Header.Get("Content-Type")
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode Resend payload: %v", err)
		}
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(strings.NewReader(`{"id":"email_123"}`)),
			Header:     make(http.Header),
		}, nil
	})

	sender := NewResendEmailOTPSender(EmailSenderConfig{
		FromAddress:   "Inflap <onboarding@resend.dev>",
		ResendAPIKey:  "re_test_key",
		ResendBaseURL: "https://api.resend.test",
		ResendTimeout: time.Second,
	}, zerolog.New(io.Discard))
	sender.httpClient = &http.Client{Transport: transport}

	if err := sender.SendEmailOTP(context.Background(), "traveler@example.com", "123456"); err != nil {
		t.Fatalf("SendEmailOTP() error = %v", err)
	}

	if gotAuth != "Bearer re_test_key" {
		t.Fatalf("Authorization header = %q, want Bearer token", gotAuth)
	}
	if gotContentType != "application/json" {
		t.Fatalf("Content-Type = %q, want application/json", gotContentType)
	}
	if gotPayload.From != "Inflap <onboarding@resend.dev>" {
		t.Fatalf("from = %q, want configured sender", gotPayload.From)
	}
	if len(gotPayload.To) != 1 || gotPayload.To[0] != "traveler@example.com" {
		t.Fatalf("to = %#v, want single recipient", gotPayload.To)
	}
	if gotPayload.Subject != "Inflap verification code" {
		t.Fatalf("subject = %q, want verification subject", gotPayload.Subject)
	}
	if !strings.Contains(gotPayload.Text, "123456") {
		t.Fatalf("text = %q, want OTP code", gotPayload.Text)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}
