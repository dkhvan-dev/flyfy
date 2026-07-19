package savedcollection

import (
	"bytes"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestLimitsValidation(t *testing.T) {
	limits := (Limits{}).WithDefaults()
	if err := limits.Validate(); err != nil {
		t.Fatalf("default limits: %v", err)
	}
	invalid := limits
	invalid.MaxMembershipsPerCollection = invalid.MaxMembershipsPerOwner + 1
	if !errors.Is(invalid.Validate(), ErrInvalidCommand) {
		t.Fatalf("invalid nested quota error = %v", invalid.Validate())
	}
}

func TestNormalizeStoredTitle(t *testing.T) {
	normalized, err := NormalizeStoredTitle("  Планы   Алматы  ")
	if err != nil {
		t.Fatalf("NormalizeStoredTitle() error = %v", err)
	}
	if normalized.Display != "Планы   Алматы" || normalized.Key != "планы алматы" {
		t.Fatalf("normalized title = %+v", normalized)
	}
	if _, err := NormalizeStoredTitle("\u202ehidden"); !errors.Is(err, domain.ErrCollectionTitleInvalid) {
		t.Fatalf("bidi title error = %v", err)
	}
	if _, err := NormalizeStoredTitle(strings.Repeat("a", 81)); !errors.Is(err, domain.ErrCollectionTitleInvalid) {
		t.Fatalf("long title error = %v", err)
	}
}

func TestDesiredSetValidation(t *testing.T) {
	target, err := domain.NewSavedTarget(domain.EntityTypeAttraction, uuid.NewString())
	if err != nil {
		t.Fatal(err)
	}
	collectionID := uuid.New()
	desired := DesiredSet{
		Target:               target,
		ExpectedRelationship: ExpectedRelationship{State: ExpectedRelationshipAbsent},
		DesiredCollectionIDs: []uuid.UUID{collectionID, collectionID},
	}
	if !errors.Is(desired.Validate(DefaultMaxDesiredCollectionIDs), ErrInvalidCommand) {
		t.Fatalf("duplicate IDs error = %v", desired.Validate(DefaultMaxDesiredCollectionIDs))
	}
	desired.DesiredCollectionIDs = []uuid.UUID{collectionID}
	desired.ExpectedDependentMembershipVersion = 1
	if !errors.Is(desired.Validate(DefaultMaxDesiredCollectionIDs), ErrInvalidCommand) {
		t.Fatalf("absent nonzero dependent version error = %v", desired.Validate(DefaultMaxDesiredCollectionIDs))
	}
}

func TestPrepareProjectionShellCommandValidation(t *testing.T) {
	now := time.Now().UTC()
	target, err := domain.NewSavedTarget(domain.EntityTypeAttraction, uuid.NewString())
	if err != nil {
		t.Fatal(err)
	}
	command := PrepareProjectionShellCommand{
		Identity: MutationIdentity{
			SubjectID: uuid.New(), SessionGeneration: uuid.New(), OperationID: uuid.New(),
			Kind:                  domain.OperationKindSetTargetCollections,
			SemanticRequestHMAC:   bytes.Repeat([]byte{0x51}, semanticRequestHMACBytes),
			RequestHMACKeyVersion: 1,
		},
		Target: target, SourceService: "place-service", ServerNow: now,
		ShellExpiresAt: now.Add(15 * time.Minute),
	}
	if err := command.Validate(now.Add(10 * time.Second)); err != nil {
		t.Fatalf("valid PrepareProjectionShellCommand: %v", err)
	}
	command.SourceService = "Place_Service"
	if !errors.Is(command.Validate(now.Add(10*time.Second)), ErrInvalidCommand) {
		t.Fatalf("invalid source service error = %v", command.Validate(now.Add(10*time.Second)))
	}
}

func TestRejectPendingCommandRejectsForeignOperationKind(t *testing.T) {
	command := RejectPendingCommand{
		Identity: MutationIdentity{
			SubjectID: uuid.New(), SessionGeneration: uuid.New(), OperationID: uuid.New(),
			Kind:                  domain.OperationKindSave,
			SemanticRequestHMAC:   bytes.Repeat([]byte{0x52}, semanticRequestHMACBytes),
			RequestHMACKeyVersion: 1,
		},
		Cause: domain.ErrTargetUnavailable, RefreshScope: domain.RefreshScopeNone,
		ServerNow: time.Now().UTC(),
	}
	if !errors.Is(command.Validate(), ErrInvalidCommand) {
		t.Fatalf("foreign operation kind error = %v", command.Validate())
	}
}

func TestMutationIdentityMatchesConstantContract(t *testing.T) {
	now := time.Now().UTC()
	hmac := bytes.Repeat([]byte{0x4a}, 32)
	receipt, err := domain.NewPendingOperation(
		uuid.New(),
		uuid.New(),
		uuid.New(),
		domain.OperationKindCreateCollection,
		"SkpKSkpKSkpKSkpKSkpKSA",
		hmac,
		1,
		domain.SourceSurfaceSavedAll,
		1,
		now,
		now.Add(10*time.Second),
	)
	if err != nil {
		t.Fatalf("NewPendingOperation() error = %v", err)
	}
	identity := MutationIdentity{
		SubjectID:             receipt.SubjectID(),
		SessionGeneration:     receipt.SessionGeneration(),
		OperationID:           receipt.OperationID(),
		Kind:                  receipt.Kind(),
		SemanticRequestHMAC:   hmac,
		RequestHMACKeyVersion: 1,
	}
	if !identity.Matches(receipt) {
		t.Fatal("matching identity was rejected")
	}
	identity.SemanticRequestHMAC = bytes.Repeat([]byte{0x4b}, 32)
	if identity.Matches(receipt) {
		t.Fatal("mismatched HMAC was accepted")
	}
}
