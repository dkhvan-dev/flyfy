package saveditem

import (
	"bytes"
	"errors"
	"math"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSaveCommandValidation(t *testing.T) {
	now := time.Now().UTC().Truncate(time.Microsecond)
	command := validSaveCommand(t, now)
	deadline := now.Add(10 * time.Second)

	if err := command.Validate(deadline); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
	if command.EffectiveMaxActiveSaves() != DefaultMaxActiveSaves {
		t.Fatalf("EffectiveMaxActiveSaves() = %d", command.EffectiveMaxActiveSaves())
	}

	tests := []struct {
		name   string
		mutate func(*SaveCommand)
	}{
		{name: "non v4 operation", mutate: func(value *SaveCommand) {
			value.Identity.OperationID = uuid.MustParse("00000000-0000-1000-8000-000000000001")
		}},
		{name: "short hmac", mutate: func(value *SaveCommand) { value.Identity.SemanticRequestHMAC = []byte("short") }},
		{name: "zero revision", mutate: func(value *SaveCommand) { value.Projection.VisibilityRevision = 0 }},
		{name: "missing default title", mutate: func(value *SaveCommand) { value.Projection.Title.EN = nil }},
		{name: "expired media", mutate: func(value *SaveCommand) { value.Projection.Media.ValidUntil = now }},
		{name: "media lease too long", mutate: func(value *SaveCommand) { value.Projection.Media.ValidUntil = now.Add(16 * time.Minute) }},
		{name: "invalid rating scale", mutate: func(value *SaveCommand) { value.Projection.Rating.ScaleMax = 0 }},
		{name: "rating overflow", mutate: func(value *SaveCommand) { value.Projection.Rating.Value = math.Inf(1) }},
		{name: "summary without lease", mutate: func(value *SaveCommand) { value.Projection.ValidUntil = nil }},
		{name: "shell before operation deadline", mutate: func(value *SaveCommand) { value.Projection.ShellExpiresAt = deadline }},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			candidate := validSaveCommand(t, now)
			test.mutate(&candidate)
			if err := candidate.Validate(deadline); !errors.Is(err, ErrInvalidCommand) {
				t.Fatalf("Validate() error = %v, want ErrInvalidCommand", err)
			}
		})
	}
}

func TestPersistableRejectionWhitelist(t *testing.T) {
	if !IsPersistableRejection(domain.ErrItemLimitReached) {
		t.Fatal("item limit must be persistable")
	}
	if IsPersistableRejection(domain.ErrOperationExpired) {
		t.Fatal("operation expiry is a lifecycle state, not a rejected outcome")
	}
	if IsPersistableRejection(domain.ErrRequestInProgress) {
		t.Fatal("in-progress is not terminal")
	}
}

func TestPrepareProjectionShellCommandValidation(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	target, err := domain.NewSavedTarget(domain.EntityTypeActivity, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	command := PrepareProjectionShellCommand{
		Identity: MutationIdentity{
			SubjectID:             uuid.New(),
			SessionGeneration:     uuid.New(),
			OperationID:           uuid.New(),
			Kind:                  domain.OperationKindSave,
			SemanticRequestHMAC:   bytes.Repeat([]byte{0x22}, 32),
			RequestHMACKeyVersion: 1,
		},
		Target:         target,
		SourceService:  "activity-service",
		ShellExpiresAt: now.Add(time.Hour),
		ServerNow:      now,
	}
	deadline := now.Add(15 * time.Second)
	if err := command.Validate(deadline); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
	command.ShellExpiresAt = deadline
	if err := command.Validate(deadline); !errors.Is(err, ErrInvalidCommand) {
		t.Fatalf("expired shell Validate() error = %v", err)
	}
	command.ShellExpiresAt = now.Add(time.Hour + time.Nanosecond)
	if err := command.Validate(deadline); !errors.Is(err, ErrInvalidCommand) {
		t.Fatalf("oversized shell Validate() error = %v", err)
	}
}

func TestRejectPendingCommandRejectsUnknownOperationKind(t *testing.T) {
	now := time.Now().UTC()
	command := RejectPendingCommand{
		Identity: MutationIdentity{
			SubjectID:             uuid.New(),
			SessionGeneration:     uuid.New(),
			OperationID:           uuid.New(),
			Kind:                  domain.OperationKind("UNKNOWN"),
			SemanticRequestHMAC:   bytes.Repeat([]byte{1}, 32),
			RequestHMACKeyVersion: 1,
		},
		Cause:        domain.ErrMutationStale,
		RefreshScope: domain.RefreshScopeNone,
		ServerNow:    now,
	}
	if err := command.Validate(); !errors.Is(err, ErrInvalidCommand) {
		t.Fatalf("Validate() error = %v, want ErrInvalidCommand", err)
	}
}

func validSaveCommand(t testing.TB, now time.Time) SaveCommand {
	t.Helper()
	target, err := domain.NewSavedTarget(domain.EntityTypeAttraction, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	titleEN := "National Museum"
	titleRU := "Национальный музей"
	searchEN := "national museum astana"
	priceEN := "from 20 USD"
	availabilityRU := "доступно сегодня"
	route := "/attractions/" + target.EntityID()
	asOf := now.Add(-time.Minute)
	validUntil := now.Add(time.Hour)
	return SaveCommand{
		Identity: MutationIdentity{
			SubjectID:             uuid.New(),
			SessionGeneration:     uuid.New(),
			OperationID:           uuid.New(),
			Kind:                  domain.OperationKindSave,
			SemanticRequestHMAC:   bytes.Repeat([]byte{0x61}, 32),
			RequestHMACKeyVersion: 1,
		},
		OwnerUserID: uuid.New(),
		Projection: PublicProjectionSnapshot{
			Target:                   target,
			SourceService:            "place-service",
			SourceRevision:           11,
			ProjectionRevision:       12,
			VisibilityRevision:       13,
			VisibilityValidatedAt:    now.Add(-time.Second),
			SourceDefaultLocale:      LocaleEN,
			Title:                    LocalizedText{EN: &titleEN, RU: &titleRU},
			SearchDocumentVersion:    2,
			NormalizedSearchDocument: LocalizedText{EN: &searchEN},
			Media: &MediaReference{
				OpaqueReference:   "media:place:cover:v19",
				ReferenceRevision: 19,
				ValidUntil:        now.Add(5 * time.Minute),
			},
			Rating:               &Rating{Value: 4.8, ReviewCount: 412, ScaleMax: 5},
			PriceSummary:         LocalizedText{EN: &priceEN},
			AvailabilitySummary:  LocalizedText{RU: &availabilityRU},
			AsOf:                 &asOf,
			ValidUntil:           &validUntil,
			CanonicalDetailRoute: &route,
			ShellExpiresAt:       now.Add(15 * time.Minute),
		},
		SavedItemID:               uuid.New(),
		StateGeneration:           uuid.New(),
		RelationshipAttributionID: uuid.New(),
		ActivatedOutboxEventID:    uuid.New(),
		ServerNow:                 now,
	}
}
