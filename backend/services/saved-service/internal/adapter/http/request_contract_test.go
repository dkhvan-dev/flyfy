package http

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestParseMutationIdentity(t *testing.T) {
	t.Parallel()

	header := make(http.Header)
	header.Set(HeaderOperationID, "00000000-0000-4000-8000-000000000042")
	header.Set(HeaderIdempotencyKey, "MDEyMzQ1Njc4OWFiY2RlZg")
	identity, err := ParseMutationIdentity(header)
	if err != nil {
		t.Fatalf("ParseMutationIdentity() error = %v", err)
	}
	if identity.OperationID.Version() != 4 || identity.IdempotencyKey != "MDEyMzQ1Njc4OWFiY2RlZg" {
		t.Fatalf("identity = %#v", identity)
	}
}

func TestParseMutationIdentityRejectsInvalidValues(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name        string
		operationID string
		key         string
	}{
		{name: "non-v4 UUID", operationID: uuid.MustParse("00000000-0000-1000-8000-000000000042").String(), key: "MDEyMzQ1Njc4OWFiY2RlZg"},
		{name: "short key", operationID: uuid.NewString(), key: "c2hvcnQ"},
		{name: "padded key", operationID: uuid.NewString(), key: "MDEyMzQ1Njc4OWFiY2RlZg=="},
		{name: "non-base64url key", operationID: uuid.NewString(), key: "MDEyMzQ1Njc4OWFiY2RlZy*"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			header := make(http.Header)
			header.Set(HeaderOperationID, test.operationID)
			header.Set(HeaderIdempotencyKey, test.key)
			if _, err := ParseMutationIdentity(header); !errors.Is(err, ErrInvalidMutationIdentity) {
				t.Fatalf("ParseMutationIdentity() error = %v", err)
			}
		})
	}
}

func TestParseMutationIdentityRejectsDuplicateHeaders(t *testing.T) {
	t.Parallel()

	header := make(http.Header)
	header.Add(HeaderOperationID, uuid.NewString())
	header.Add(HeaderOperationID, uuid.NewString())
	header.Set(HeaderIdempotencyKey, "MDEyMzQ1Njc4OWFiY2RlZg")
	if _, err := ParseMutationIdentity(header); !errors.Is(err, ErrInvalidMutationIdentity) {
		t.Fatalf("ParseMutationIdentity() error = %v", err)
	}
}

func TestParseSourceSurface(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name      string
		values    []string
		want      domain.SourceSurface
		wantError bool
	}{
		{name: "missing defaults to unknown", want: domain.SourceSurfaceUnknown},
		{name: "card", values: []string{"CARD"}, want: domain.SourceSurfaceCard},
		{name: "arbitrary label", values: []string{"HOME_PROMO_42"}, wantError: true},
		{name: "surrounding whitespace", values: []string{" CARD "}, wantError: true},
		{name: "duplicate", values: []string{"CARD", "DETAIL"}, wantError: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			header := make(http.Header)
			for _, value := range test.values {
				header.Add(HeaderSourceSurface, value)
			}
			got, err := ParseSourceSurface(header)
			if (err != nil) != test.wantError || (!test.wantError && got != test.want) {
				t.Fatalf("ParseSourceSurface() = %q, %v; want %q, error=%t", got, err, test.want, test.wantError)
			}
		})
	}
}

func TestParseSavedTargetPathPreservesOpaqueIdentity(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest(http.MethodPut, "/", nil)
	request.SetPathValue("entityType", "ACTIVITY")
	request.SetPathValue("entityKey", "source:activity:42")
	target, err := ParseSavedTargetPath(request)
	if err != nil {
		t.Fatalf("ParseSavedTargetPath() error = %v", err)
	}
	if target.EntityType() != domain.EntityTypeActivity || target.EntityID() != "source:activity:42" {
		t.Fatalf("target = %q/%q", target.EntityType(), target.EntityID())
	}

	request.SetPathValue("entityKey", " source:activity:42 ")
	if _, err := ParseSavedTargetPath(request); !errors.Is(err, domain.ErrTargetUnavailable) {
		t.Fatalf("ParseSavedTargetPath(trimmed identity) error = %v", err)
	}
}

func TestDecodeBoundedJSONIsStrictAndBounded(t *testing.T) {
	t.Parallel()

	type body struct {
		Value string `json:"value"`
	}
	tests := []struct {
		name    string
		payload string
		limit   int64
		wantErr bool
	}{
		{name: "valid", payload: `{"value":"ok"}`, limit: 64},
		{name: "unknown field", payload: `{"value":"ok","extra":true}`, limit: 64, wantErr: true},
		{name: "multiple documents", payload: `{"value":"ok"}{"value":"again"}`, limit: 64, wantErr: true},
		{name: "oversized", payload: `{"value":"` + strings.Repeat("x", 80) + `"}`, limit: 32, wantErr: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(test.payload))
			recorder := httptest.NewRecorder()
			var destination body
			err := DecodeBoundedJSON(recorder, request, test.limit, &destination)
			if (err != nil) != test.wantErr {
				t.Fatalf("DecodeBoundedJSON() error = %v, wantErr %t", err, test.wantErr)
			}
		})
	}
}
