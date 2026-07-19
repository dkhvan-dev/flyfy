package cursor

import (
	"bytes"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestCursorRoundTripAndPrivacy(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	codec := testCodec(t, []Key{{ID: 7, Secret: bytes.Repeat([]byte{7}, 32)}}, 7, now)
	fingerprinter := testFingerprinter(t)
	entityType := domain.EntityTypeActivity
	scope, err := fingerprinter.Fingerprint(Scope{EntityType: &entityType, Search: "almaty", Locale: LocaleRU})
	if err != nil {
		t.Fatalf("Fingerprint() error = %v", err)
	}
	rank := int64(3)
	itemID := uuid.MustParse("00000000-0000-0000-0000-000000000042")
	token, err := codec.Encode(EncodeInput{
		Subject:          "user-42",
		ScopeFingerprint: scope,
		Locale:           LocaleRU,
		Position: Position{
			SavedAt:   now.Add(-time.Minute),
			ItemID:    itemID,
			MatchRank: &rank,
		},
	})
	if err != nil {
		t.Fatalf("Encode() error = %v", err)
	}
	for _, secret := range []string{"user-42", "almaty", itemID.String()} {
		if strings.Contains(token, secret) {
			t.Fatalf("opaque cursor exposed plaintext %q", secret)
		}
	}

	position, err := codec.Decode(token, DecodeExpectation{Subject: "user-42", ScopeFingerprint: scope, Locale: LocaleRU})
	if err != nil {
		t.Fatalf("Decode() error = %v", err)
	}
	if position.ItemID != itemID || !position.SavedAt.Equal(now.Add(-time.Minute)) || position.MatchRank == nil || *position.MatchRank != rank {
		t.Fatalf("Decode() position = %#v", position)
	}
}

func TestCursorRejectsAllInvalidBindingsWithOneError(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	codec := testCodec(t, []Key{{ID: 1, Secret: bytes.Repeat([]byte{1}, 32)}}, 1, now)
	fingerprinter := testFingerprinter(t)
	scope, _ := fingerprinter.Fingerprint(Scope{Locale: LocaleEN})
	token, err := codec.Encode(EncodeInput{
		Subject:          "owner",
		ScopeFingerprint: scope,
		Locale:           LocaleEN,
		Position:         Position{SavedAt: now.Add(-time.Second), ItemID: uuid.New()},
	})
	if err != nil {
		t.Fatalf("Encode() error = %v", err)
	}
	otherScope, _ := fingerprinter.Fingerprint(Scope{Search: "other", Locale: LocaleEN})
	tampered := token[:len(token)-1] + differentBase64Rune(token[len(token)-1])

	tests := []struct {
		name     string
		token    string
		expected DecodeExpectation
		now      time.Time
	}{
		{name: "tampered", token: tampered, expected: DecodeExpectation{Subject: "owner", ScopeFingerprint: scope, Locale: LocaleEN}, now: now},
		{name: "wrong owner", token: token, expected: DecodeExpectation{Subject: "other", ScopeFingerprint: scope, Locale: LocaleEN}, now: now},
		{name: "wrong scope", token: token, expected: DecodeExpectation{Subject: "owner", ScopeFingerprint: otherScope, Locale: LocaleEN}, now: now},
		{name: "wrong locale", token: token, expected: DecodeExpectation{Subject: "owner", ScopeFingerprint: scope, Locale: LocaleKK}, now: now},
		{name: "expired", token: token, expected: DecodeExpectation{Subject: "owner", ScopeFingerprint: scope, Locale: LocaleEN}, now: now.Add(16 * time.Minute)},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			codec.now = func() time.Time { return test.now }
			_, err := codec.Decode(test.token, test.expected)
			if !errors.Is(err, ErrInvalidCursor) {
				t.Fatalf("Decode() error = %v, want neutral invalid cursor", err)
			}
		})
	}
}

func TestCursorKeyRotationOverlap(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	oldKey := Key{ID: 1, Secret: bytes.Repeat([]byte{1}, 32)}
	newKey := Key{ID: 2, Secret: bytes.Repeat([]byte{2}, 32)}
	oldCodec := testCodec(t, []Key{oldKey}, oldKey.ID, now)
	scope := [scopeFingerprintBytes]byte{1, 2, 3}
	token, err := oldCodec.Encode(EncodeInput{
		Subject:          "owner",
		ScopeFingerprint: scope,
		Locale:           LocaleKK,
		Position:         Position{SavedAt: now.Add(-time.Second), ItemID: uuid.New()},
	})
	if err != nil {
		t.Fatalf("old Encode() error = %v", err)
	}

	rotated := testCodec(t, []Key{oldKey, newKey}, newKey.ID, now)
	if _, err := rotated.Decode(token, DecodeExpectation{Subject: "owner", ScopeFingerprint: scope, Locale: LocaleKK}); err != nil {
		t.Fatalf("rotated Decode(old token) error = %v", err)
	}
}

func TestScopeFingerprintIsBoundedAndUnambiguous(t *testing.T) {
	t.Parallel()

	fingerprinter := testFingerprinter(t)
	left, err := fingerprinter.Fingerprint(Scope{Search: "ab", Locale: LocaleEN})
	if err != nil {
		t.Fatalf("Fingerprint(left) error = %v", err)
	}
	right, err := fingerprinter.Fingerprint(Scope{Search: "a", Locale: LocaleEN})
	if err != nil {
		t.Fatalf("Fingerprint(right) error = %v", err)
	}
	if left == right {
		t.Fatal("different scopes produced the same fingerprint")
	}

	collectionID := uuid.New()
	if _, err := fingerprinter.Fingerprint(Scope{CollectionID: &collectionID, Uncollected: true, Locale: LocaleEN}); !errors.Is(err, ErrInvalidScope) {
		t.Fatalf("Fingerprint(mutually exclusive scope) error = %v", err)
	}
	if _, err := fingerprinter.Fingerprint(Scope{Search: strings.Repeat("я", 201), Locale: LocaleRU}); !errors.Is(err, ErrInvalidScope) {
		t.Fatalf("Fingerprint(oversized search) error = %v", err)
	}
}

func testCodec(t *testing.T, keys []Key, current uint32, now time.Time) *Codec {
	t.Helper()
	codec, err := NewCodec(keys, current, 15*time.Minute)
	if err != nil {
		t.Fatalf("NewCodec() error = %v", err)
	}
	codec.now = func() time.Time { return now }
	codec.random = bytes.NewReader(bytes.Repeat([]byte{9}, 128))
	return codec
}

func testFingerprinter(t *testing.T) *Fingerprinter {
	t.Helper()
	fingerprinter, err := NewFingerprinter(bytes.Repeat([]byte{3}, 32))
	if err != nil {
		t.Fatalf("NewFingerprinter() error = %v", err)
	}
	return fingerprinter
}

func differentBase64Rune(current byte) string {
	if current == 'A' {
		return "B"
	}
	return "A"
}
