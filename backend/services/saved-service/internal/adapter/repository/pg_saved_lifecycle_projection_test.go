package repository

import (
	"crypto/sha256"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestDecideSavedLifecycleProjectionAppliesIndependentRevisions(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	state := savedLifecycleProjectionState{
		sourceService:         "activity-service",
		sourceRevision:        10,
		projectionRevision:    5,
		visibilityRevision:    10,
		visibility:            domain.VisibilityPublic,
		visibilityValidatedAt: now.Add(-time.Minute),
	}
	event := repositoryLifecycleEvent(t, domain.EntityTypeActivity, now, 9, 6, 10, domain.VisibilityPublic, true)
	decision, err := decideSavedLifecycleProjection(event, state)
	if err != nil {
		t.Fatalf("decideSavedLifecycleProjection() error = %v", err)
	}
	if decision.sourceApplied || !decision.projectionApplied || decision.visibilityApplied ||
		decision.projectionRevision != 6 || decision.visibilityRevision != 10 {
		t.Fatalf("independent projection decision = %+v", decision)
	}
}

func TestDecideSavedLifecycleProjectionNeverRestoresFromStaleVisibility(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	state := savedLifecycleProjectionState{
		sourceService:         "activity-service",
		sourceRevision:        10,
		projectionRevision:    10,
		visibilityRevision:    10,
		visibility:            domain.VisibilityPrivate,
		visibilityValidatedAt: now,
	}
	event := repositoryLifecycleEvent(t, domain.EntityTypeActivity, now, 11, 11, 9, domain.VisibilityPublic, true)
	decision, err := decideSavedLifecycleProjection(event, state)
	if err != nil {
		t.Fatalf("decideSavedLifecycleProjection() error = %v", err)
	}
	if !decision.sourceApplied || decision.projectionApplied || decision.visibilityApplied ||
		decision.visibility != domain.VisibilityPrivate {
		t.Fatalf("stale PUBLIC decision = %+v", decision)
	}
	if outcome := decision.outcome(event, state); outcome.Code != savedlifecycle.OutcomeAppliedSourceOnly {
		t.Fatalf("outcome = %+v", outcome)
	}
}

func TestDecideSavedLifecycleProjectionRestoresPurgedEqualProjectionRevision(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	state := savedLifecycleProjectionState{
		sourceService:         "activity-service",
		sourceRevision:        5,
		projectionRevision:    5,
		visibilityRevision:    6,
		visibility:            domain.VisibilityPrivate,
		visibilityValidatedAt: now.Add(-time.Minute),
	}
	event := repositoryLifecycleEvent(
		t,
		domain.EntityTypeActivity,
		now,
		6,
		5,
		7,
		domain.VisibilityPublic,
		true,
	)
	decision, err := decideSavedLifecycleProjection(event, state)
	if err != nil {
		t.Fatalf("decideSavedLifecycleProjection() error = %v", err)
	}
	if !decision.sourceApplied || !decision.projectionApplied || !decision.visibilityApplied ||
		decision.projectionRevision != 5 || decision.visibilityRevision != 7 ||
		decision.visibility != domain.VisibilityPublic {
		t.Fatalf("equal-revision restore decision = %+v", decision)
	}
}

func TestDecideSavedLifecycleProjectionRequiresVisibilityAdvanceForEqualFailClosedRecovery(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	event := repositoryLifecycleEvent(
		t,
		domain.EntityTypeGuide,
		now,
		7,
		7,
		7,
		domain.VisibilityPublic,
		true,
	)
	baseState := savedLifecycleProjectionState{
		sourceService:         "guide-service",
		sourceRevision:        7,
		projectionRevision:    7,
		visibilityRevision:    7,
		visibility:            domain.VisibilityPublic,
		visibilityValidatedAt: now.Add(-time.Minute),
	}

	ordinary, err := decideSavedLifecycleProjection(event, baseState)
	if err != nil {
		t.Fatalf("decide ordinary equal revision: %v", err)
	}
	if ordinary.projectionApplied || ordinary.visibilityApplied || ordinary.sourceApplied {
		t.Fatalf("ordinary equal PUBLIC rewrote payload: %+v", ordinary)
	}

	failClosedState := baseState
	failClosedState.failClosed = true
	equalFailClosed, err := decideSavedLifecycleProjection(event, failClosedState)
	if err != nil {
		t.Fatalf("decide fail-closed equal revision: %v", err)
	}
	if equalFailClosed.projectionApplied || equalFailClosed.visibilityApplied ||
		equalFailClosed.sourceApplied {
		t.Fatalf("equal fail-closed PUBLIC rewrote payload: %+v", equalFailClosed)
	}

	advancedVisibility := repositoryLifecycleEvent(
		t,
		domain.EntityTypeGuide,
		now.Add(time.Second),
		8,
		7,
		8,
		domain.VisibilityPublic,
		true,
	)
	recovery, err := decideSavedLifecycleProjection(advancedVisibility, failClosedState)
	if err != nil {
		t.Fatalf("decide fail-closed visibility advance: %v", err)
	}
	if !recovery.projectionApplied || !recovery.visibilityApplied ||
		!recovery.sourceApplied || recovery.projectionRevision != 7 ||
		recovery.visibilityRevision != 8 {
		t.Fatalf("fail-closed visibility recovery decision = %+v", recovery)
	}
}

func TestSavedLifecycleAuthoritativeUpdatesResetQuarantineState(t *testing.T) {
	t.Parallel()

	for name, query := range map[string]string{
		"source":            updateSavedLifecycleSourceRevisionSQL,
		"public_projection": applySavedLifecyclePublicProjectionSQL,
		"public_visibility": applySavedLifecyclePublicVisibilitySQL,
		"deny":              applySavedLifecycleDenySQL,
		"deny_projection":   applySavedLifecycleDenyProjectionRevisionSQL,
	} {
		upper := strings.ToUpper(query)
		for _, fragment := range []string{
			"RECONCILIATION_FAILURE_COUNT = 0",
			"RECONCILIATION_FAILURE_KIND = NULL",
			"RECONCILIATION_QUARANTINED_AT = NULL",
			"RECONCILIATION_QUARANTINE_REASON = NULL",
		} {
			if !strings.Contains(upper, fragment) {
				t.Errorf("%s update does not reset %q", name, fragment)
			}
		}
	}
}

func TestDecideSavedLifecycleProjectionDenyPurgesWithNewVisibility(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	state := savedLifecycleProjectionState{
		sourceService:         "activity-service",
		sourceRevision:        5,
		projectionRevision:    5,
		visibilityRevision:    5,
		visibility:            domain.VisibilityPublic,
		visibilityValidatedAt: now.Add(-time.Minute),
	}
	event := repositoryLifecycleEvent(t, domain.EntityTypeActivity, now, 6, 4, 6, domain.VisibilityPrivate, false)
	decision, err := decideSavedLifecycleProjection(event, state)
	if err != nil {
		t.Fatalf("decideSavedLifecycleProjection() error = %v", err)
	}
	if !decision.sourceApplied || decision.projectionApplied || !decision.visibilityApplied ||
		decision.projectionRevision != 5 || decision.visibility != domain.VisibilityPrivate {
		t.Fatalf("deny decision = %+v", decision)
	}
}

func TestDecideSavedLifecycleProjectionRejectsEqualRevisionConflict(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	state := savedLifecycleProjectionState{
		sourceService:         "activity-service",
		sourceRevision:        5,
		projectionRevision:    5,
		visibilityRevision:    5,
		visibility:            domain.VisibilityPrivate,
		visibilityValidatedAt: now,
	}
	event := repositoryLifecycleEvent(t, domain.EntityTypeActivity, now, 6, 6, 5, domain.VisibilityPublic, true)
	_, err := decideSavedLifecycleProjection(event, state)
	var permanent *savedlifecycle.PermanentError
	if !errors.As(err, &permanent) || permanent.Code != savedlifecycle.ErrorCodeRevisionConflict {
		t.Fatalf("error = %v, want revision conflict", err)
	}
}

func TestSavedLifecyclePublicProjectionArgumentsDropsExpiredMedia(t *testing.T) {
	t.Parallel()

	processedAt := time.Now().UTC().Truncate(time.Microsecond)
	event := repositoryLifecycleEvent(
		t,
		domain.EntityTypeActivity,
		processedAt.Add(-20*time.Minute),
		1,
		1,
		1,
		domain.VisibilityPublic,
		true,
	)
	decision := savedLifecycleDecision{
		projectionApplied:     true,
		projectionRevision:    1,
		visibilityRevision:    1,
		visibility:            domain.VisibilityPublic,
		visibilityValidatedAt: event.OccurredAt,
	}
	arguments, err := savedLifecyclePublicProjectionArguments(event, decision, processedAt)
	if err != nil {
		t.Fatalf("savedLifecyclePublicProjectionArguments() error = %v", err)
	}
	if arguments["media_reference"] != nil || arguments["media_reference_revision"] != nil ||
		arguments["media_valid_until"] != nil {
		t.Fatalf("expired media was retained: %+v", arguments)
	}
}

func repositoryLifecycleEvent(
	t testing.TB,
	entityType domain.EntityType,
	occurredAt time.Time,
	sourceRevision uint64,
	projectionRevision uint64,
	visibilityRevision uint64,
	visibility domain.VisibilityStatus,
	withProjection bool,
) savedlifecycle.Event {
	t.Helper()
	contract := repositoryLifecycleContract(t, entityType)
	targetID := uuid.NewString()
	target, err := domain.NewSavedTarget(entityType, targetID)
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	return repositoryLifecycleEventForTarget(
		t,
		contract,
		target,
		occurredAt,
		sourceRevision,
		projectionRevision,
		visibilityRevision,
		visibility,
		withProjection,
	)
}

func repositoryLifecycleEventForTarget(
	t testing.TB,
	contract savedlifecycle.SubjectContract,
	target domain.SavedTarget,
	occurredAt time.Time,
	sourceRevision uint64,
	projectionRevision uint64,
	visibilityRevision uint64,
	visibility domain.VisibilityStatus,
	withProjection bool,
) savedlifecycle.Event {
	t.Helper()
	kind := savedlifecycle.EventUpdated
	if visibility != domain.VisibilityPublic {
		kind = savedlifecycle.EventVisibilityChanged
	}
	event := savedlifecycle.Event{
		EventID:       uuid.New(),
		Subject:       contract.Subject,
		SourceService: contract.SourceService,
		SchemaVersion: contract.SchemaVersion,
		Kind:          kind,
		Target:        target,
		Revisions: savedlifecycle.Revisions{
			Source:     sourceRevision,
			Projection: projectionRevision,
			Visibility: visibilityRevision,
		},
		OccurredAt:          occurredAt.UTC(),
		Visibility:          visibility,
		EnvelopeFingerprint: sha256.Sum256([]byte(uuid.NewString())),
	}
	if withProjection {
		route := "/activities/" + target.EntityID()
		switch target.EntityType() {
		case domain.EntityTypeAttraction:
			route = "/places/" + target.EntityID()
		case domain.EntityTypeGuide:
			route = "/users/" + target.EntityID() + "/profile"
		}
		event.PublicProjection = &savedlifecycle.PublicProjection{
			SourceDefaultLocale: savedlifecycle.LocaleEN,
			Localized: savedlifecycle.LocalizedProjections{
				EN: &savedlifecycle.LocalizedProjection{
					Title:           "Public title",
					Subtitle:        "Public subtitle",
					City:            "Almaty",
					Country:         "Kazakhstan",
					DisplayLocation: "Almaty, Kazakhstan",
				},
			},
			CanonicalDetailRoute: route,
			Media: &savedlifecycle.MediaReference{
				OpaqueReference:   "media/" + target.EntityID(),
				ReferenceRevision: projectionRevision,
				ValidUntil:        occurredAt.UTC().Add(10 * time.Minute),
			},
		}
	}
	return event
}

func repositoryLifecycleContract(
	t testing.TB,
	entityType domain.EntityType,
) savedlifecycle.SubjectContract {
	t.Helper()
	for _, contract := range savedlifecycle.SubjectContracts() {
		if contract.EntityType == entityType {
			return contract
		}
	}
	t.Fatalf("missing lifecycle contract for %s", entityType)
	return savedlifecycle.SubjectContract{}
}
