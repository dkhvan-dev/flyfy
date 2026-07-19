package operation

import (
	"bytes"
	"encoding/binary"
	"testing"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestCanonicalSemanticRequestDeterministic(t *testing.T) {
	t.Parallel()

	target := mustSavedTarget(t, domain.EntityTypeActivity, "source|activity:42")
	first, err := canonicalSemanticRequest(domain.OperationKindSave, target)
	if err != nil {
		t.Fatalf("canonicalSemanticRequest() error = %v", err)
	}
	second, err := canonicalSemanticRequest(domain.OperationKindSave, target)
	if err != nil {
		t.Fatalf("canonicalSemanticRequest() second error = %v", err)
	}

	want := append([]byte("inflap.saved.semantic-request\x00"), 1, 1, 2, 0, 0, 0, 18)
	want = append(want, "source|activity:42"...)
	if !bytes.Equal(first, want) {
		t.Fatalf("canonicalSemanticRequest() = %x, want %x", first, want)
	}
	if !bytes.Equal(first, second) {
		t.Fatalf("canonical encoding is not deterministic: %x != %x", first, second)
	}
}

func TestCanonicalSemanticRequestDelimiterCollisionResistance(t *testing.T) {
	t.Parallel()

	firstID := "guide|segment:42/part"
	secondID := "guide|segment:42|part"
	firstTarget := mustSavedTarget(t, domain.EntityTypeGuide, firstID)
	secondTarget := mustSavedTarget(t, domain.EntityTypeGuide, secondID)

	first, err := canonicalSemanticRequest(domain.OperationKindUnsave, firstTarget)
	if err != nil {
		t.Fatalf("canonicalSemanticRequest(first) error = %v", err)
	}
	second, err := canonicalSemanticRequest(domain.OperationKindUnsave, secondTarget)
	if err != nil {
		t.Fatalf("canonicalSemanticRequest(second) error = %v", err)
	}
	if bytes.Equal(first, second) {
		t.Fatalf("delimiter-bearing IDs collided: %x", first)
	}

	lengthOffset := len("inflap.saved.semantic-request\x00") + 3
	encodedLength := binary.BigEndian.Uint32(first[lengthOffset : lengthOffset+semanticLengthBytes])
	if encodedLength != uint32(len(firstID)) {
		t.Fatalf("encoded entity ID length = %d, want %d", encodedLength, len(firstID))
	}
	if !bytes.Equal(first[lengthOffset+semanticLengthBytes:], []byte(firstID)) {
		t.Fatalf("entity ID was not encoded as one opaque field: %x", first)
	}

	differentKind, err := canonicalSemanticRequest(domain.OperationKindSave, firstTarget)
	if err != nil {
		t.Fatalf("canonicalSemanticRequest(different kind) error = %v", err)
	}
	if bytes.Equal(first, differentKind) {
		t.Fatal("different closed operation kinds produced the same encoding")
	}
}

func TestCanonicalSemanticRequestAssignsStablePostTypeCode(t *testing.T) {
	t.Parallel()

	target := mustSavedTarget(
		t,
		domain.EntityTypePost,
		"81ec585b-8eeb-4ff9-b5bd-80fdfbfaa9de",
	)
	canonical, err := canonicalSemanticRequest(domain.OperationKindSave, target)
	if err != nil {
		t.Fatalf("canonicalSemanticRequest() error = %v", err)
	}
	typeCodeOffset := len("inflap.saved.semantic-request\x00") + 2
	if got := canonical[typeCodeOffset]; got != 6 {
		t.Fatalf("POST entity type code = %d, want immutable code 6", got)
	}
}

func mustSavedTarget(t testing.TB, entityType domain.EntityType, entityID string) domain.SavedTarget {
	t.Helper()
	target, err := domain.NewSavedTarget(entityType, entityID)
	if err != nil {
		t.Fatalf("domain.NewSavedTarget() error = %v", err)
	}
	return target
}
