package oauth

import (
	"context"
	"errors"
	"testing"

	"github.com/rs/zerolog"
)

func TestGoogleVerifierValidatesTokenAgainstConfiguredClientID(t *testing.T) {
	validator := &fakeGoogleTokenValidator{
		payload: &googleTokenPayload{
			Subject: "google-subject-123",
			Email:   "traveler@example.com",
			Name:    "Traveler",
		},
	}
	verifier := newGoogleVerifierWithValidator("web-client-id.apps.googleusercontent.com", zerolog.Nop(), validator)

	info, err := verifier.Verify(context.Background(), "real-google-id-token")
	if err != nil {
		t.Fatalf("Verify returned error: %v", err)
	}

	if validator.gotToken != "real-google-id-token" {
		t.Fatalf("token = %q, want real-google-id-token", validator.gotToken)
	}
	if validator.gotAudience != "web-client-id.apps.googleusercontent.com" {
		t.Fatalf("audience = %q, want backend web client id", validator.gotAudience)
	}
	if info.ProviderID != "google-subject-123" {
		t.Fatalf("provider id = %q, want subject", info.ProviderID)
	}
	if info.Email != "traveler@example.com" {
		t.Fatalf("email = %q, want traveler@example.com", info.Email)
	}
	if info.Name != "Traveler" {
		t.Fatalf("name = %q, want Traveler", info.Name)
	}
}

func TestGoogleVerifierRejectsInvalidTokens(t *testing.T) {
	verifier := newGoogleVerifierWithValidator(
		"web-client-id.apps.googleusercontent.com",
		zerolog.Nop(),
		&fakeGoogleTokenValidator{err: errors.New("invalid signature")},
	)

	if _, err := verifier.Verify(context.Background(), "tampered-token"); err == nil {
		t.Fatal("Verify accepted an invalid Google token")
	}
}

func TestGoogleVerifierRequiresConfiguredClientID(t *testing.T) {
	verifier := newGoogleVerifierWithValidator("", zerolog.Nop(), &fakeGoogleTokenValidator{})

	if _, err := verifier.Verify(context.Background(), "real-google-id-token"); err == nil {
		t.Fatal("Verify accepted token without configured Google client id")
	}
}

type fakeGoogleTokenValidator struct {
	payload *googleTokenPayload
	err     error

	gotToken    string
	gotAudience string
}

func (v *fakeGoogleTokenValidator) Validate(_ context.Context, idToken string, audience string) (*googleTokenPayload, error) {
	v.gotToken = idToken
	v.gotAudience = audience
	if v.err != nil {
		return nil, v.err
	}
	return v.payload, nil
}
