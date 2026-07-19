package operation

import (
	"bytes"
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSetTargetCollectionsCanonicalizesDesiredSetOrder(t *testing.T) {
	t.Parallel()

	first := uuid.MustParse("11111111-1111-4111-8111-111111111111")
	second := uuid.MustParse("22222222-2222-4222-8222-222222222222")
	request := validSetTargetCollectionsSemantic(t)
	request.DesiredCollectionIDs = []uuid.UUID{second, first}

	ring := mustOperationKeyRing(t)
	left, err := ring.SignCollection(request)
	if err != nil {
		t.Fatalf("SignCollection() error = %v", err)
	}
	request.DesiredCollectionIDs = []uuid.UUID{first, second}
	right, err := ring.SignCollection(request)
	if err != nil {
		t.Fatalf("SignCollection(permuted) error = %v", err)
	}
	if !bytes.Equal(left.Bytes(), right.Bytes()) {
		t.Fatal("desired-set permutation changed semantic HMAC")
	}
	if got := request.DesiredCollectionIDs; got[0] != first || got[1] != second {
		t.Fatalf("canonicalization mutated caller slice: %v", got)
	}
}

func TestCollectionSemanticHMACBindsEveryUserIntentField(t *testing.T) {
	t.Parallel()

	ring := mustOperationKeyRing(t)
	base := validSetTargetCollectionsSemantic(t)
	signed, err := ring.SignCollection(base)
	if err != nil {
		t.Fatalf("SignCollection() error = %v", err)
	}

	changedVersion := base
	changedVersion.ExpectedDependentMembershipVersion++
	if ring.VerifyCollection(signed.KeyVersion, changedVersion, signed.Bytes()) {
		t.Fatal("changed dependent membership version verified")
	}
	changedTitle := base
	copyOfNewCollection := *base.NewCollection
	copyOfNewCollection.Title = "Summer trips"
	changedTitle.NewCollection = &copyOfNewCollection
	if ring.VerifyCollection(signed.KeyVersion, changedTitle, signed.Bytes()) {
		t.Fatal("changed inline collection title verified")
	}
	changedTarget := base
	changedTarget.Target = mustSavedTarget(t, domain.EntityTypeActivity, "different-target")
	if ring.VerifyCollection(signed.KeyVersion, changedTarget, signed.Bytes()) {
		t.Fatal("changed target verified")
	}
}

func TestCollectionCanonicalRejectsInvalidShapes(t *testing.T) {
	t.Parallel()

	ring := mustOperationKeyRing(t)
	duplicate := uuid.MustParse("11111111-1111-4111-8111-111111111111")
	tests := []struct {
		name    string
		request CollectionSemanticRequest
		want    error
	}{
		{
			name: "duplicate desired collection",
			request: func() CollectionSemanticRequest {
				request := validSetTargetCollectionsSemantic(t)
				request.DesiredCollectionIDs = []uuid.UUID{duplicate, duplicate}
				return request
			}(),
			want: domain.ErrMutationStale,
		},
		{
			name: "absent relationship carries a generation",
			request: func() CollectionSemanticRequest {
				request := validSetTargetCollectionsSemantic(t)
				request.ExpectedRelationship = ExpectedRelationship{
					State: ExpectedRelationshipAbsent, Generation: uuid.New(),
				}
				return request
			}(),
			want: domain.ErrMutationStale,
		},
		{
			name: "blank title",
			request: CreateCollectionSemanticRequest{
				ClientCreationID: uuid.New(), Title: " ",
			},
			want: domain.ErrCollectionTitleInvalid,
		},
		{
			name: "zero rename version",
			request: RenameCollectionSemanticRequest{
				CollectionID: uuid.New(), Title: "Trips",
			},
			want: domain.ErrMutationStale,
		},
		{
			name: "zero delete lifecycle version",
			request: DeleteCollectionSemanticRequest{
				CollectionID: uuid.New(), ExpectedMetadataVersion: 1,
			},
			want: domain.ErrMutationStale,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if _, err := ring.SignCollection(test.request); !errors.Is(err, test.want) {
				t.Fatalf("SignCollection() error = %v, want %v", err, test.want)
			}
		})
	}
}

func TestTargetSemanticHMACRejectsCollectionKinds(t *testing.T) {
	t.Parallel()

	ring := mustOperationKeyRing(t)
	target := mustSavedTarget(t, domain.EntityTypeAttraction, "target")
	if _, err := ring.Sign(domain.OperationKindCreateCollection, target); !errors.Is(err, domain.ErrMutationStale) {
		t.Fatalf("Sign(collection kind as target) error = %v, want stale", err)
	}
}

func TestServiceBeginCollectionConvergesAndRejectsChangedSemantics(t *testing.T) {
	t.Parallel()

	now := testServerNow()
	store := newMutexOperationStore()
	service := mustOperationService(t, store, mustOperationKeyRing(t), now)
	request := validBeginCollectionRequest(t)

	first, err := service.BeginCollection(context.Background(), request)
	if err != nil {
		t.Fatalf("BeginCollection() error = %v", err)
	}
	second, err := service.BeginCollection(context.Background(), request)
	if err != nil {
		t.Fatalf("BeginCollection(replay) error = %v", err)
	}
	if first.Outcome != BeginOutcomeNewlyAcceptedPending || second.Outcome != BeginOutcomeExistingPending ||
		first.Receipt != second.Receipt || first.Receipt.Kind() != domain.OperationKindSetTargetCollections {
		t.Fatalf("collection begin outcomes = %q/%q, receipts %p/%p", first.Outcome, second.Outcome, first.Receipt, second.Receipt)
	}

	changed := request
	semantic := request.SemanticRequest.(SetTargetCollectionsSemanticRequest)
	semantic.ExpectedDependentMembershipVersion++
	changed.SemanticRequest = semantic
	if _, err := service.BeginCollection(context.Background(), changed); !errors.Is(err, domain.ErrReplayMismatch) {
		t.Fatalf("BeginCollection(changed semantics) error = %v, want replay mismatch", err)
	}
}

func validSetTargetCollectionsSemantic(t *testing.T) SetTargetCollectionsSemanticRequest {
	t.Helper()
	return SetTargetCollectionsSemanticRequest{
		Target: mustSavedTarget(t, domain.EntityTypeAttraction, "canonical-target"),
		ExpectedRelationship: ExpectedRelationship{
			State:      ExpectedRelationshipActive,
			Generation: uuid.MustParse("33333333-3333-4333-8333-333333333333"),
			Version:    7,
		},
		ExpectedDependentMembershipVersion: 4,
		DesiredCollectionIDs: []uuid.UUID{
			uuid.MustParse("11111111-1111-4111-8111-111111111111"),
			uuid.MustParse("22222222-2222-4222-8222-222222222222"),
		},
		NewCollection: &NewCollectionSemanticRequest{
			ClientCreationID: uuid.MustParse("44444444-4444-4444-8444-444444444444"),
			Title:            "City favorites",
		},
	}
}

func validBeginCollectionRequest(t *testing.T) BeginCollectionRequest {
	t.Helper()
	return BeginCollectionRequest{
		OperationID:            uuid.MustParse("55555555-5555-4555-8555-555555555555"),
		SubjectID:              uuid.MustParse("66666666-6666-4666-8666-666666666666"),
		SessionGeneration:      uuid.MustParse("77777777-7777-4777-8777-777777777777"),
		IdempotencyKey:         "0123456789abcdefghijklmnopqrstuv",
		SemanticRequest:        validSetTargetCollectionsSemantic(t),
		SourceSurface:          domain.SourceSurfaceSavedCollection,
		AcceptedPolicyRevision: 9,
	}
}
