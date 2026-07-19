package savedlifecycle

import (
	"crypto/sha256"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSubjectContractsAreCanonicalAndClosed(t *testing.T) {
	t.Parallel()

	contracts := SubjectContracts()
	if len(contracts) != 3 {
		t.Fatalf("contract count = %d, want 3", len(contracts))
	}
	want := map[string]domain.EntityType{
		ActivitySubjectV1:   domain.EntityTypeActivity,
		AttractionSubjectV1: domain.EntityTypeAttraction,
		GuideSubjectV1:      domain.EntityTypeGuide,
	}
	for _, contract := range contracts {
		if contract.SchemaVersion != SchemaVersionV1 || want[contract.Subject] != contract.EntityType {
			t.Fatalf("unexpected subject contract: %+v", contract)
		}
		delete(want, contract.Subject)
	}
	if len(want) != 0 {
		t.Fatalf("missing subject contracts: %v", want)
	}
	for _, rejected := range []string{
		"content.saved.lifecycle.v1.attraction",
		"saved.source.excursion.lifecycle.v1",
		"saved.source.>",
	} {
		if _, ok := ContractForSubject(rejected); ok {
			t.Fatalf("legacy/unsupported subject %q was accepted", rejected)
		}
	}
}

func TestEventValidateVisibilityAndProjectionInvariants(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	public := validLifecycleEvent(t, domain.EntityTypeActivity, now)
	if err := public.Validate(now); err != nil {
		t.Fatalf("valid PUBLIC event rejected: %v", err)
	}

	publicWithoutPayload := public
	publicWithoutPayload.PublicProjection = nil
	publicWithoutPayload.EnvelopeFingerprint = sha256.Sum256([]byte("public-without-payload"))
	if err := publicWithoutPayload.Validate(now); err != nil {
		t.Fatalf("PUBLIC event without optional payload rejected: %v", err)
	}

	privateActivity := public
	privateActivity.Kind = EventVisibilityChanged
	privateActivity.Visibility = domain.VisibilityPrivate
	privateActivity.PublicProjection = nil
	privateActivity.EnvelopeFingerprint = sha256.Sum256([]byte("private-activity"))
	if err := privateActivity.Validate(now); err != nil {
		t.Fatalf("PRIVATE Activity event rejected: %v", err)
	}

	privateAttraction := validLifecycleEvent(t, domain.EntityTypeAttraction, now)
	privateAttraction.Kind = EventVisibilityChanged
	privateAttraction.Visibility = domain.VisibilityPrivate
	privateAttraction.PublicProjection = nil
	privateAttraction.EnvelopeFingerprint = sha256.Sum256([]byte("private-attraction"))
	assertPermanentCode(t, privateAttraction.Validate(now), ErrorCodeInvalidKindVisibility)

	denyWithPayload := privateActivity
	denyWithPayload.PublicProjection = public.PublicProjection
	denyWithPayload.EnvelopeFingerprint = sha256.Sum256([]byte("deny-payload"))
	assertPermanentCode(t, denyWithPayload.Validate(now), ErrorCodePayloadForbidden)

	kindMismatch := public
	kindMismatch.Kind = EventDeleted
	kindMismatch.EnvelopeFingerprint = sha256.Sum256([]byte("kind-mismatch"))
	assertPermanentCode(t, kindMismatch.Validate(now), ErrorCodeInvalidKindVisibility)
}

func TestPublicProjectionRequiresCanonicalCompletePayload(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	event := validLifecycleEvent(t, domain.EntityTypeGuide, now)
	projection := *event.PublicProjection
	projection.CanonicalDetailRoute = "/activities/" + uuid.NewString()
	event.PublicProjection = &projection
	assertPermanentCode(t, event.Validate(now), ErrorCodeInvalidPublicProjection)

	event = validLifecycleEvent(t, domain.EntityTypeGuide, now)
	opaqueTarget, err := domain.NewSavedTarget(domain.EntityTypeGuide, "guide:opaque:canonical")
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	event.Target = opaqueTarget
	if err = event.Validate(now); err != nil {
		t.Fatalf("opaque canonical target was parsed by Saved: %v", err)
	}

	event = validLifecycleEvent(t, domain.EntityTypeGuide, now)
	projection = *event.PublicProjection
	projection.Localized = LocalizedProjections{EN: &LocalizedProjection{Title: "Guide"}}
	projection.SourceDefaultLocale = LocaleKK
	event.PublicProjection = &projection
	assertPermanentCode(t, event.Validate(now), ErrorCodeInvalidPublicProjection)

	event = validLifecycleEvent(t, domain.EntityTypeGuide, now)
	projection = *event.PublicProjection
	projection.Localized.EN = &LocalizedProjection{Title: " Guide "}
	event.PublicProjection = &projection
	assertPermanentCode(t, event.Validate(now), ErrorCodeInvalidPublicProjection)

	event = validLifecycleEvent(t, domain.EntityTypeGuide, now)
	projection = *event.PublicProjection
	projection.Localized.EN.PriceSummary = "From 100"
	event.PublicProjection = &projection
	assertPermanentCode(t, event.Validate(now), ErrorCodeInvalidPublicProjection)
}

func TestEventValidateRejectsFutureTimestampButAllowsDelayedDelivery(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	delayed := validLifecycleEvent(t, domain.EntityTypeActivity, now.Add(-10*24*time.Hour))
	if err := delayed.Validate(now); err != nil {
		t.Fatalf("delayed retained event rejected: %v", err)
	}

	future := validLifecycleEvent(t, domain.EntityTypeActivity, now.Add(6*time.Second))
	assertPermanentCode(t, future.Validate(now), ErrorCodeInvalidTimestamp)
}

func TestPublicProjectionSearchDocumentIsStableAndLocalized(t *testing.T) {
	t.Parallel()

	projection := PublicProjection{Localized: LocalizedProjections{
		EN: &LocalizedProjection{
			Title:           "  Café", // Invalid as a contract value, but normalization itself is deterministic.
			Subtitle:        "WALKING   TOUR",
			DisplayLocation: "Almaty",
		},
	}}
	document := projection.SearchDocument(LocaleEN)
	if document == nil || *document != "café walking tour almaty" {
		t.Fatalf("search document = %v", document)
	}
	if projection.SearchDocument(LocaleKK) != nil {
		t.Fatal("missing locale produced a search document")
	}
}

func validLifecycleEvent(
	t testing.TB,
	entityType domain.EntityType,
	occurredAt time.Time,
) Event {
	t.Helper()
	contract := contractForEntityType(t, entityType)
	targetID := uuid.NewString()
	target, err := domain.NewSavedTarget(entityType, targetID)
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	route := "/activities/" + targetID
	switch entityType {
	case domain.EntityTypeAttraction:
		route = "/places/" + targetID
	case domain.EntityTypeGuide:
		route = "/users/" + targetID + "/profile"
	}
	return Event{
		EventID:       uuid.New(),
		Subject:       contract.Subject,
		SourceService: contract.SourceService,
		SchemaVersion: contract.SchemaVersion,
		Kind:          EventUpdated,
		Target:        target,
		Revisions: Revisions{
			Source:     1,
			Projection: 1,
			Visibility: 1,
		},
		OccurredAt: occurredAt.UTC(),
		Visibility: domain.VisibilityPublic,
		PublicProjection: &PublicProjection{
			SourceDefaultLocale: LocaleEN,
			Localized: LocalizedProjections{
				EN: &LocalizedProjection{Title: "Public title", City: "Almaty"},
			},
			CanonicalDetailRoute: route,
		},
		EnvelopeFingerprint: sha256.Sum256([]byte(uuid.NewString())),
	}
}

func contractForEntityType(t testing.TB, entityType domain.EntityType) SubjectContract {
	t.Helper()
	for _, contract := range SubjectContracts() {
		if contract.EntityType == entityType {
			return contract
		}
	}
	t.Fatalf("no lifecycle contract for %s", entityType)
	return SubjectContract{}
}

func assertPermanentCode(t testing.TB, err error, code ErrorCode) {
	t.Helper()
	if err == nil || !IsPermanent(err) {
		t.Fatalf("error = %v, want permanent %s", err, code)
	}
	var permanent *PermanentError
	if !errors.As(err, &permanent) || permanent.Code != code {
		t.Fatalf("error = %v, want code %s", err, code)
	}
}
