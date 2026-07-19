package http

import (
	"encoding/json"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestMapOperationResultEmitsOnlyPublicReceiptFields(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newHTTPTestOperation(t, now, domain.OperationKindSetTargetCollections)
	membershipVersion := uint64(8)
	if err := receipt.Succeed(now.Add(time.Second), domain.OperationOutcomeApplied, domain.RefreshScopeBoth, domain.OperationVersionEffects{
		AppliedRelationship: &domain.AppliedRelationshipVersion{
			Generation: uuid.MustParse("55555555-5555-4555-8555-555555555555"),
			Version:    3,
		},
		AppliedDependentMembershipVersion: &membershipVersion,
		AppliedCollection: &domain.AppliedCollectionVersion{
			CollectionID:     uuid.MustParse("66666666-6666-4666-8666-666666666666"),
			MetadataVersion:  1,
			LifecycleVersion: 1,
		},
	}); err != nil {
		t.Fatalf("Succeed() error = %v", err)
	}

	mapped, err := mapOperationResult(receipt, map[string]any{"resource_kind": "TARGET_COLLECTIONS"})
	if err != nil {
		t.Fatalf("mapOperationResult() error = %v", err)
	}
	encoded, err := json.Marshal(mapped)
	if err != nil {
		t.Fatalf("json.Marshal() error = %v", err)
	}
	payload := string(encoded)
	for _, required := range []string{
		`"operation_status":"SUCCEEDED"`,
		`"operation_outcome":"APPLIED"`,
		`"refresh_scope":"BOTH"`,
		`"dependent_membership_version":8`,
		`"collection_id":"66666666-6666-4666-8666-666666666666"`,
		`"resource_kind":"TARGET_COLLECTIONS"`,
	} {
		if !strings.Contains(payload, required) {
			t.Errorf("response is missing %s: %s", required, payload)
		}
	}
	for _, forbidden := range []string{
		"semantic_request_hmac",
		"idempotency_key",
		"session_generation",
		"subject",
		strings.Repeat("h", 32),
	} {
		if strings.Contains(payload, forbidden) {
			t.Errorf("response leaks %q: %s", forbidden, payload)
		}
	}
}

func TestMapOperationResultMapsRejectedFailureOnly(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newHTTPTestOperation(t, now, domain.OperationKindCreateCollection)
	if err := receipt.Reject(now.Add(time.Second), domain.ErrCollectionTitleConflict, domain.RefreshScopeCollections); err != nil {
		t.Fatalf("Reject() error = %v", err)
	}
	mapped, err := mapOperationResult(receipt, nil)
	if err != nil {
		t.Fatalf("mapOperationResult() error = %v", err)
	}
	if mapped.OperationError == nil || mapped.OperationError.Code != domain.ErrorCodeCollectionTitleConflict || mapped.OperationError.Retryable {
		t.Fatalf("operation error = %#v", mapped.OperationError)
	}
	if mapped.ResultRecordedAt != now.Add(time.Second) {
		t.Fatalf("result_recorded_at = %v", mapped.ResultRecordedAt)
	}
}

func TestMapOperationResultUsesAcceptanceTimeForPending(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newHTTPTestOperation(t, now, domain.OperationKindSave)
	mapped, err := mapOperationResult(receipt, nil)
	if err != nil {
		t.Fatalf("mapOperationResult() error = %v", err)
	}
	if mapped.ResultRecordedAt != now || mapped.OperationError != nil || mapped.OperationOutcome != domain.OperationOutcomePending {
		t.Fatalf("pending response = %#v", mapped)
	}
}

func newHTTPTestOperation(t *testing.T, now time.Time, kind domain.OperationKind) *domain.SavedOperation {
	t.Helper()
	receipt, err := domain.NewPendingOperation(
		uuid.MustParse("11111111-1111-4111-8111-111111111111"),
		uuid.MustParse("22222222-2222-4222-8222-222222222222"),
		uuid.MustParse("33333333-3333-4333-8333-333333333333"),
		kind,
		"0123456789abcdefghijklmnopqrstuv",
		[]byte(strings.Repeat("h", 32)),
		1,
		domain.SourceSurfaceSavedCollection,
		7,
		now,
		now.Add(10*time.Second),
	)
	if err != nil {
		t.Fatalf("NewPendingOperation() error = %v", err)
	}
	return receipt
}
