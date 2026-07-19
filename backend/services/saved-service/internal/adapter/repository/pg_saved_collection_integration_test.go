package repository

import (
	"context"
	"errors"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	savedcollectionapp "kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestPGSavedCollectionCRUDLifecycleAndReplay(t *testing.T) {
	pool, operationStore, repository := openSavedCollectionIntegration(t, nil)
	base := time.Now().UTC().Truncate(time.Microsecond).Add(731 * time.Nanosecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	clientCreationID := uuid.New()

	createIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindCreateCollection, 90, base,
	)
	create := savedcollectionapp.CreateCommand{
		Identity: createIdentity, OwnerUserID: owner, ClientCreationID: clientCreationID,
		Title: "Trip", ServerNow: base,
	}
	receipt, err := repository.Create(context.Background(), create)
	if err != nil {
		t.Fatalf("Create() error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)
	created := receipt.AppliedCollection()
	if created == nil || created.MetadataVersion != 1 || created.LifecycleVersion != 1 {
		t.Fatalf("created versions = %+v", created)
	}

	replayed, err := repository.Create(context.Background(), create)
	if err != nil || replayed.OperationID() != receipt.OperationID() {
		t.Fatalf("Create(replay) = (%v, %v)", replayed, err)
	}
	createAgainIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindCreateCollection, 91, base.Add(time.Second),
	)
	createAgain := create
	createAgain.Identity = createAgainIdentity
	createAgain.ServerNow = base.Add(time.Second)
	receipt, err = repository.Create(context.Background(), createAgain)
	if err != nil {
		t.Fatalf("Create(client id replay) error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeNoOp)
	if receipt.AppliedCollection().CollectionID != created.CollectionID {
		t.Fatalf("client id replay collection = %s, want %s", receipt.AppliedCollection().CollectionID, created.CollectionID)
	}

	mismatchIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindCreateCollection, 92, base.Add(2*time.Second),
	)
	mismatch := create
	mismatch.Identity = mismatchIdentity
	mismatch.Title = "Different"
	mismatch.ServerNow = base.Add(2 * time.Second)
	receipt, err = repository.Create(context.Background(), mismatch)
	if err != nil {
		t.Fatalf("Create(client id mismatch) error = %v", err)
	}
	assertRejectedOperation(t, receipt, domain.ErrorCodeReplayMismatch)

	conflictIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindCreateCollection, 93, base.Add(3*time.Second),
	)
	receipt, err = repository.Create(context.Background(), savedcollectionapp.CreateCommand{
		Identity: conflictIdentity, OwnerUserID: owner, ClientCreationID: uuid.New(),
		Title: "TRIP", ServerNow: base.Add(3 * time.Second),
	})
	if err != nil {
		t.Fatalf("Create(title conflict) error = %v", err)
	}
	assertRejectedOperation(t, receipt, domain.ErrorCodeCollectionTitleConflict)

	renameIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindRenameCollection, 94, base.Add(4*time.Second),
	)
	receipt, err = repository.Rename(context.Background(), savedcollectionapp.RenameCommand{
		Identity: renameIdentity, OwnerUserID: owner, CollectionID: created.CollectionID,
		ExpectedMetadataVersion: 1, Title: "Almaty", ServerNow: base.Add(4 * time.Second),
	})
	if err != nil {
		t.Fatalf("Rename() error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)
	if receipt.AppliedCollection().MetadataVersion != 2 || receipt.AppliedCollection().LifecycleVersion != 1 {
		t.Fatalf("renamed versions = %+v", receipt.AppliedCollection())
	}

	staleIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindRenameCollection, 95, base.Add(5*time.Second),
	)
	receipt, err = repository.Rename(context.Background(), savedcollectionapp.RenameCommand{
		Identity: staleIdentity, OwnerUserID: owner, CollectionID: created.CollectionID,
		ExpectedMetadataVersion: 1, Title: "Stale", ServerNow: base.Add(5 * time.Second),
	})
	if err != nil {
		t.Fatalf("Rename(stale) error = %v", err)
	}
	assertRejectedOperation(t, receipt, domain.ErrorCodeMutationStale)

	readAt := base.Add(6 * time.Second)
	record, err := repository.GetCollectionRecord(context.Background(), savedcollectionapp.GetQuery{
		OwnerUserID: owner, CollectionID: created.CollectionID, Locale: savedcollectionapp.LocaleEN, ReadAt: readAt,
	})
	if err != nil || record.Collection.Title != "Almaty" || record.Collection.Cover.Kind != savedcollectionapp.CoverKindGeneric {
		t.Fatalf("GetCollectionRecord() = (%+v, %v)", record, err)
	}

	deleteIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindDeleteCollection, 96, base.Add(6*time.Second),
	)
	receipt, err = repository.Delete(context.Background(), savedcollectionapp.DeleteCommand{
		Identity: deleteIdentity, OwnerUserID: owner, CollectionID: created.CollectionID,
		ExpectedMetadataVersion: 2, ExpectedLifecycleVersion: 1, ServerNow: base.Add(6 * time.Second),
	})
	if err != nil {
		t.Fatalf("Delete() error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)
	if receipt.AppliedCollection().MetadataVersion != 3 || receipt.AppliedCollection().LifecycleVersion != 2 {
		t.Fatalf("deleted versions = %+v", receipt.AppliedCollection())
	}
	_, err = repository.GetCollectionRecord(context.Background(), savedcollectionapp.GetQuery{
		OwnerUserID: owner, CollectionID: created.CollectionID, Locale: savedcollectionapp.LocaleEN, ReadAt: readAt,
	})
	if !errors.Is(err, domain.ErrCollectionNotFound) {
		t.Fatalf("deleted GetCollectionRecord() error = %v", err)
	}

	// Immutable operation replay never recreates a collection after a later delete.
	replayed, err = repository.Create(context.Background(), create)
	if err != nil || replayed.Outcome() != domain.OperationOutcomeApplied {
		t.Fatalf("old Create replay after delete = (%v, %v)", replayed, err)
	}
	assertCollectionCounts(t, pool, owner, 0, 0)
}

func TestPGSavedCollectionAssignsAlreadySavedActivity(t *testing.T) {
	pool, operationStore, collectionRepository := openSavedCollectionIntegration(t, nil)
	itemRepository, err := NewPGSavedItemRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedItemRepository() error = %v", err)
	}

	base := time.Now().UTC().Truncate(time.Microsecond).Add(731 * time.Nanosecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	target := integrationSavedTarget(t, domain.EntityTypeActivity)

	saveIdentity := createKernelOperation(
		t, operationStore, subject, session, domain.OperationKindSave, 130,
		base, base.Add(10*time.Second),
	)
	saveReceipt, err := itemRepository.Save(
		context.Background(),
		integrationSaveCommand(t, saveIdentity, owner, target, base, 1),
	)
	if err != nil {
		t.Fatalf("seed Save() error = %v", err)
	}
	assertOperationOutcome(t, saveReceipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)

	collectionAt := base.Add(time.Second)
	collectionID := createIntegrationCollection(
		t, collectionRepository, operationStore, subject, session, owner,
		"Activity plans", 131, collectionAt,
	)
	setAt := base.Add(2 * time.Second)
	setIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session,
		domain.OperationKindSetTargetCollections, 132, setAt,
	)
	desired := savedcollectionapp.DesiredSet{
		Target: target,
		ExpectedRelationship: savedcollectionapp.ExpectedRelationship{
			State:      savedcollectionapp.ExpectedRelationshipActive,
			Generation: saveReceipt.AppliedRelationship().Generation,
			Version:    saveReceipt.AppliedRelationship().Version,
		},
		ExpectedDependentMembershipVersion: 0,
		DesiredCollectionIDs:               []uuid.UUID{collectionID},
	}
	receipt, err := collectionRepository.ReplaceDesiredSet(
		context.Background(),
		savedcollectionapp.ReplaceDesiredSetCommand{
			Identity:    setIdentity,
			OwnerUserID: owner,
			Desired:     desired,
			ServerNow:   setAt,
		},
	)
	if err != nil {
		t.Fatalf("ReplaceDesiredSet(already saved Activity) error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)
	if receipt.AppliedRelationship() == nil ||
		receipt.AppliedRelationship().Version != saveReceipt.AppliedRelationship().Version ||
		receipt.AppliedDependentMembershipVersion() == nil ||
		*receipt.AppliedDependentMembershipVersion() != 1 {
		t.Fatalf(
			"assignment effects = relationship=%+v dependent=%v",
			receipt.AppliedRelationship(), receipt.AppliedDependentMembershipVersion(),
		)
	}
	assertCollectionCounts(t, pool, owner, 1, 1)
	assertCollectionItemCount(t, pool, collectionID, 1)
}

func TestPGSavedCollectionDesiredSetExpansionReductionInlineAndDelete(t *testing.T) {
	pool, operationStore, repository := openSavedCollectionIntegration(t, nil)
	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	first := createIntegrationCollection(t, repository, operationStore, subject, session, owner, "First", 101, base)
	second := createIntegrationCollection(t, repository, operationStore, subject, session, owner, "Second", 102, base.Add(time.Second))
	target := integrationSavedTarget(t, domain.EntityTypeAttraction)

	desired := savedcollectionapp.DesiredSet{
		Target: target,
		ExpectedRelationship: savedcollectionapp.ExpectedRelationship{
			State: savedcollectionapp.ExpectedRelationshipAbsent,
		},
		DesiredCollectionIDs: []uuid.UUID{first},
	}
	analysis, err := repository.AnalyzeDesiredSet(context.Background(), savedcollectionapp.AnalyzeDesiredSetQuery{
		OwnerUserID: owner, Desired: desired, ReadAt: base.Add(2 * time.Second),
	})
	if err != nil || analysis.Change != savedcollectionapp.DesiredSetExpansion {
		t.Fatalf("AnalyzeDesiredSet(expansion) = (%+v, %v)", analysis, err)
	}
	setIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindSetTargetCollections, 103, base.Add(2*time.Second),
	)
	setCommand := savedcollectionapp.ReplaceDesiredSetCommand{
		Identity: setIdentity, OwnerUserID: owner, Desired: desired, ServerNow: base.Add(2 * time.Second),
	}
	if _, err := repository.ReplaceDesiredSet(context.Background(), setCommand); !errors.Is(err, savedcollectionapp.ErrPublicEligibilityRequired) {
		t.Fatalf("ReplaceDesiredSet(without eligibility) error = %v", err)
	}
	assertOperationStatusInDatabase(t, pool, setIdentity.OperationID, domain.OperationStatusPending)
	setCommand.Eligibility = &savedcollectionapp.PublicEligibility{
		Projection: integrationCollectionProjection(t, target, setCommand.ServerNow, 1),
	}
	prepareCollectionProjectionShell(t, repository, setIdentity, setCommand.Eligibility.Projection)
	receipt, err := repository.ReplaceDesiredSet(context.Background(), setCommand)
	if err != nil {
		t.Fatalf("ReplaceDesiredSet(expansion) error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)
	if receipt.AppliedRelationship() == nil || *receipt.AppliedDependentMembershipVersion() != 1 {
		t.Fatalf("activation effects = relationship=%+v dependent=%v", receipt.AppliedRelationship(), receipt.AppliedDependentMembershipVersion())
	}
	generation := receipt.AppliedRelationship().Generation
	relationshipVersion := receipt.AppliedRelationship().Version
	assertCollectionCounts(t, pool, owner, 2, 1)
	assertTableCount(t, pool, "saved_outbox", 1)

	mixedAt := base.Add(3 * time.Second)
	mixedIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindSetTargetCollections, 104, mixedAt,
	)
	mixed := savedcollectionapp.ReplaceDesiredSetCommand{
		Identity: mixedIdentity, OwnerUserID: owner, ServerNow: mixedAt,
		Desired: savedcollectionapp.DesiredSet{
			Target: target,
			ExpectedRelationship: savedcollectionapp.ExpectedRelationship{
				State: savedcollectionapp.ExpectedRelationshipActive, Generation: generation, Version: relationshipVersion,
			},
			ExpectedDependentMembershipVersion: 1,
			DesiredCollectionIDs:               []uuid.UUID{second},
		},
		Eligibility: &savedcollectionapp.PublicEligibility{
			Projection: integrationCollectionProjection(t, target, mixedAt, 2),
		},
	}
	prepareCollectionProjectionShell(t, repository, mixedIdentity, mixed.Eligibility.Projection)
	receipt, err = repository.ReplaceDesiredSet(context.Background(), mixed)
	if err != nil {
		t.Fatalf("ReplaceDesiredSet(mixed) error = %v", err)
	}
	if *receipt.AppliedDependentMembershipVersion() != 2 || receipt.AppliedRelationship().Version != relationshipVersion {
		t.Fatalf("mixed effects = relationship=%+v dependent=%v", receipt.AppliedRelationship(), receipt.AppliedDependentMembershipVersion())
	}
	assertCollectionItemCount(t, pool, first, 0)
	assertCollectionItemCount(t, pool, second, 1)

	reductionAt := base.Add(4 * time.Second)
	reductionIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindSetTargetCollections, 105, reductionAt,
	)
	reduction := savedcollectionapp.ReplaceDesiredSetCommand{
		Identity: reductionIdentity, OwnerUserID: owner, ServerNow: reductionAt,
		Desired: savedcollectionapp.DesiredSet{
			Target: target,
			ExpectedRelationship: savedcollectionapp.ExpectedRelationship{
				State: savedcollectionapp.ExpectedRelationshipActive, Generation: generation, Version: relationshipVersion,
			},
			ExpectedDependentMembershipVersion: 2,
			DesiredCollectionIDs:               []uuid.UUID{},
		},
	}
	receipt, err = repository.ReplaceDesiredSet(context.Background(), reduction)
	if err != nil {
		t.Fatalf("ReplaceDesiredSet(reduction) error = %v", err)
	}
	if *receipt.AppliedDependentMembershipVersion() != 3 || receipt.AppliedRelationship().Version != relationshipVersion {
		t.Fatalf("reduction effects = relationship=%+v dependent=%v", receipt.AppliedRelationship(), receipt.AppliedDependentMembershipVersion())
	}
	assertCollectionCounts(t, pool, owner, 2, 0)
	assertTableCount(t, pool, "saved_outbox", 1)

	inlineAt := base.Add(5 * time.Second)
	inlineIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindSetTargetCollections, 106, inlineAt,
	)
	inline := savedcollectionapp.ReplaceDesiredSetCommand{
		Identity: inlineIdentity, OwnerUserID: owner, ServerNow: inlineAt,
		Desired: savedcollectionapp.DesiredSet{
			Target: target,
			ExpectedRelationship: savedcollectionapp.ExpectedRelationship{
				State: savedcollectionapp.ExpectedRelationshipActive, Generation: generation, Version: relationshipVersion,
			},
			ExpectedDependentMembershipVersion: 3,
			NewCollection: &savedcollectionapp.NewCollection{
				ClientCreationID: uuid.New(), Title: "Inline",
			},
		},
		Eligibility: &savedcollectionapp.PublicEligibility{
			Projection: integrationCollectionProjection(t, target, inlineAt, 3),
		},
	}
	prepareCollectionProjectionShell(t, repository, inlineIdentity, inline.Eligibility.Projection)
	receipt, err = repository.ReplaceDesiredSet(context.Background(), inline)
	if err != nil {
		t.Fatalf("ReplaceDesiredSet(inline) error = %v", err)
	}
	inlineVersion := receipt.AppliedCollection()
	if inlineVersion == nil || *receipt.AppliedDependentMembershipVersion() != 4 {
		t.Fatalf("inline effects = collection=%+v dependent=%v", inlineVersion, receipt.AppliedDependentMembershipVersion())
	}
	assertCollectionCounts(t, pool, owner, 3, 1)

	deleteAt := base.Add(6 * time.Second)
	deleteIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindDeleteCollection, 107, deleteAt,
	)
	receipt, err = repository.Delete(context.Background(), savedcollectionapp.DeleteCommand{
		Identity: deleteIdentity, OwnerUserID: owner, CollectionID: inlineVersion.CollectionID,
		ExpectedMetadataVersion:  inlineVersion.MetadataVersion,
		ExpectedLifecycleVersion: inlineVersion.LifecycleVersion,
		ServerNow:                deleteAt,
	})
	if err != nil {
		t.Fatalf("Delete(inline collection) error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)
	assertCollectionCounts(t, pool, owner, 2, 0)
	var relationshipState string
	var dependentVersion int64
	if err := pool.QueryRow(context.Background(), `
SELECT relationship_state, dependent_membership_version
FROM saved_items
WHERE owner_user_id = $1 AND entity_type = $2 AND entity_id = $3`,
		owner.String(), string(target.EntityType()), target.EntityID(),
	).Scan(&relationshipState, &dependentVersion); err != nil {
		t.Fatal(err)
	}
	if relationshipState != "ACTIVE" || dependentVersion != 4 {
		t.Fatalf("relationship after collection delete = %s v%d", relationshipState, dependentVersion)
	}
	var cleanupPending int
	if err := pool.QueryRow(context.Background(), `
SELECT count(*) FROM saved_collection_items
WHERE owner_user_id = $1 AND collection_id = $2 AND membership_state = 'ACTIVE'`,
		owner.String(), inlineVersion.CollectionID.String(),
	).Scan(&cleanupPending); err != nil {
		t.Fatal(err)
	}
	if cleanupPending != 1 {
		t.Fatalf("cleanup-pending child count = %d, want 1", cleanupPending)
	}
	snapshot, err := repository.GetTargetCollections(context.Background(), savedcollectionapp.TargetSnapshotQuery{
		OwnerUserID: owner, Target: target, ReadAt: deleteAt,
	})
	if err != nil || len(snapshot.EffectiveCollectionIDs) != 0 || snapshot.DependentMembershipVersion != 4 {
		t.Fatalf("target snapshot after delete = (%+v, %v)", snapshot, err)
	}
}

func TestPGSavedCollectionExpansionRequiresShellAndNewerDenyWins(t *testing.T) {
	pool, operationStore, repository := openSavedCollectionIntegration(t, nil)
	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	collectionID := createIntegrationCollection(
		t, repository, operationStore, subject, session, owner, "Visibility race", 108, base,
	)
	target := integrationSavedTarget(t, domain.EntityTypeAttraction)
	operationAt := base.Add(time.Second)
	identity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindSetTargetCollections, 109, operationAt,
	)
	staleProjection := integrationCollectionProjection(t, target, operationAt, 10)
	staleProjection.SourceRevision = 12
	staleProjection.ProjectionRevision = 12
	staleProjection.SearchDocumentVersion = 12
	command := savedcollectionapp.ReplaceDesiredSetCommand{
		Identity: identity, OwnerUserID: owner, ServerNow: operationAt,
		Desired: savedcollectionapp.DesiredSet{
			Target: target,
			ExpectedRelationship: savedcollectionapp.ExpectedRelationship{
				State: savedcollectionapp.ExpectedRelationshipAbsent,
			},
			DesiredCollectionIDs: []uuid.UUID{collectionID},
		},
		Eligibility: &savedcollectionapp.PublicEligibility{Projection: staleProjection},
	}

	if _, err := repository.ReplaceDesiredSet(context.Background(), command); !errors.Is(err, savedcollectionapp.ErrDataInvariant) {
		t.Fatalf("ReplaceDesiredSet(without prepared shell) error = %v", err)
	}
	assertOperationStatusInDatabase(t, pool, identity.OperationID, domain.OperationStatusPending)
	assertTargetProjectionCount(t, pool, target, 0)

	prepareCollectionProjectionShell(t, repository, identity, staleProjection)
	if _, err := pool.Exec(context.Background(), `
UPDATE saved_content_projections
SET source_revision = 11,
    projection_revision = 11,
    visibility_revision = 11,
    visibility_status = 'UNAVAILABLE',
    visibility_validated_at = $3,
    search_document_version = 11,
    updated_at = $3
WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()), target.EntityID(), operationAt.Add(time.Second)); err != nil {
		t.Fatalf("advance projection deny revision: %v", err)
	}

	receipt, err := repository.ReplaceDesiredSet(context.Background(), command)
	if err != nil {
		t.Fatalf("ReplaceDesiredSet(stale visibility eligibility) error = %v", err)
	}
	assertRejectedOperation(t, receipt, domain.ErrorCodeMutationStale)
	var sourceRevision int64
	var projectionRevision int64
	var visibilityRevision int64
	var visibilityStatus string
	if err := pool.QueryRow(context.Background(), `
SELECT source_revision, projection_revision, visibility_revision, visibility_status
FROM saved_content_projections
WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()), target.EntityID(),
	).Scan(&sourceRevision, &projectionRevision, &visibilityRevision, &visibilityStatus); err != nil {
		t.Fatal(err)
	}
	if sourceRevision != 11 || projectionRevision != 11 || visibilityRevision != 11 ||
		visibilityStatus != "UNAVAILABLE" {
		t.Fatalf("newer deny was overwritten: source=%d projection=%d visibility=%d status=%s",
			sourceRevision, projectionRevision, visibilityRevision, visibilityStatus)
	}
	assertTargetRelationshipCount(t, pool, owner, target, 0)
	assertCollectionItemCount(t, pool, collectionID, 0)
	assertCollectionCounts(t, pool, owner, 1, 0)
	assertTableCount(t, pool, "saved_outbox", 0)
}

func TestPGSavedCollectionConfiguredQuotasRejectAtomically(t *testing.T) {
	pool, operationStore, _ := openSavedCollectionIntegration(t, nil)
	repository, err := NewPGSavedCollectionRepository(pool, savedcollectionapp.Limits{
		MaxActiveCollections:        2,
		MaxMembershipsPerCollection: 1,
		MaxMembershipsPerOwner:      1,
		MaxDesiredCollectionIDs:     2,
		MaxActiveSaves:              10,
	}, nil)
	if err != nil {
		t.Fatal(err)
	}
	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	first := createIntegrationCollection(
		t, repository, operationStore, subject, session, owner, "Quota first", 110, base,
	)
	second := createIntegrationCollection(
		t, repository, operationStore, subject, session, owner, "Quota second", 111, base.Add(time.Second),
	)
	thirdIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindCreateCollection, 112, base.Add(2*time.Second),
	)
	receipt, err := repository.Create(context.Background(), savedcollectionapp.CreateCommand{
		Identity: thirdIdentity, OwnerUserID: owner, ClientCreationID: uuid.New(),
		Title: "Quota third", ServerNow: base.Add(2 * time.Second),
	})
	if err != nil {
		t.Fatalf("Create(over collection quota) error = %v", err)
	}
	assertRejectedOperation(t, receipt, domain.ErrorCodeCollectionLimitReached)

	firstTarget := integrationSavedTarget(t, domain.EntityTypeAttraction)
	receipt = replaceAbsentTargetForIntegration(
		t, repository, operationStore, subject, session, owner, firstTarget, first, 113, base.Add(3*time.Second),
	)
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)

	fullCollectionTarget := integrationSavedTarget(t, domain.EntityTypeGuide)
	receipt = replaceAbsentTargetForIntegration(
		t, repository, operationStore, subject, session, owner, fullCollectionTarget, first, 114, base.Add(4*time.Second),
	)
	assertRejectedOperation(t, receipt, domain.ErrorCodeCollectionItemLimitReached)

	ownerQuotaTarget := integrationSavedTarget(t, domain.EntityTypeGuide)
	receipt = replaceAbsentTargetForIntegration(
		t, repository, operationStore, subject, session, owner, ownerQuotaTarget, second, 115, base.Add(5*time.Second),
	)
	assertRejectedOperation(t, receipt, domain.ErrorCodeMembershipLimitReached)

	assertCollectionCounts(t, pool, owner, 2, 1)
	assertCollectionItemCount(t, pool, first, 1)
	assertCollectionItemCount(t, pool, second, 0)
	assertTargetRelationshipCount(t, pool, owner, firstTarget, 1)
	assertTargetRelationshipCount(t, pool, owner, fullCollectionTarget, 0)
	assertTargetRelationshipCount(t, pool, owner, ownerQuotaTarget, 0)
	assertTableCount(t, pool, "saved_outbox", 1)
}

func TestPGSavedCollectionDerivedCoverUsesOnlyFirstEffectiveMembership(t *testing.T) {
	pool, _, repository := openSavedCollectionIntegration(t, nil)
	base := time.Now().UTC().Truncate(time.Microsecond)
	owner := uuid.New()
	collectionID := seedDerivedCoverFixture(t, pool, owner, base)
	resolver := &integrationThumbnailResolver{resolved: map[uuid.UUID]string{
		collectionID: "https://media.example.test/public-cover.jpg",
	}}
	reader, err := savedcollectionapp.NewReadService(repository, resolver)
	if err != nil {
		t.Fatal(err)
	}
	collections, err := reader.List(context.Background(), savedcollectionapp.ListQuery{
		OwnerUserID: owner, Locale: savedcollectionapp.LocaleEN, ReadAt: base.Add(3 * time.Minute),
	})
	if err != nil {
		t.Fatalf("List(private first) error = %v", err)
	}
	if len(collections) != 1 || collections[0].Cover.Kind != savedcollectionapp.CoverKindGeneric ||
		len(resolver.requests) != 0 {
		t.Fatalf("private-first cover = %+v requests=%+v", collections, resolver.requests)
	}
	if _, err := pool.Exec(context.Background(), `
UPDATE saved_content_projections AS projection
SET source_revision = 2,
    projection_revision = 2,
    visibility_revision = 2,
    visibility_status = 'PUBLIC',
    visibility_validated_at = $2,
    source_default_locale = 'EN',
    title_en = 'No media first',
    search_document_version = 2,
    normalized_search_document_en = 'no media first',
    canonical_detail_route = '/activities/no-media',
    updated_at = $2
FROM saved_items AS saved
WHERE saved.owner_user_id = $1
  AND saved.id = (
      SELECT id FROM saved_items
      WHERE owner_user_id = $1
      ORDER BY saved_at DESC, id DESC
      LIMIT 1
  )
  AND projection.entity_type = saved.entity_type
  AND projection.entity_id = saved.entity_id`, owner.String(), base.Add(3*time.Minute)); err != nil {
		t.Fatalf("make first cover item PUBLIC without media: %v", err)
	}
	resolver.requests = nil
	collections, err = reader.List(context.Background(), savedcollectionapp.ListQuery{
		OwnerUserID: owner, Locale: savedcollectionapp.LocaleEN, ReadAt: base.Add(3*time.Minute + time.Second),
	})
	if err != nil {
		t.Fatalf("List(no-media first) error = %v", err)
	}
	if collections[0].Cover.Kind != savedcollectionapp.CoverKindGeneric || len(resolver.requests) != 0 {
		t.Fatalf("no-media-first cover = %+v requests=%+v", collections[0].Cover, resolver.requests)
	}

	if _, err := pool.Exec(context.Background(), `
UPDATE saved_collection_items
SET membership_state = 'REMOVED', membership_version = membership_version + 1,
    removal_reason = 'DESIRED_SET_REMOVAL', updated_at = $3, removed_at = $3,
    purge_eligible_at = $3::timestamptz + INTERVAL '14 days'
WHERE owner_user_id = $1 AND collection_id = $2
  AND saved_at_snapshot = (SELECT max(saved_at_snapshot) FROM saved_collection_items WHERE collection_id = $2);
UPDATE saved_collections
SET active_item_count = 1, items_version = items_version + 1, organized_at = $3, updated_at = $3
WHERE owner_user_id = $1 AND id = $2;
UPDATE saved_collection_usage
SET active_memberships_count = 1, usage_version = usage_version + 1, updated_at = $3
WHERE owner_user_id = $1`, owner.String(), collectionID.String(), base.Add(4*time.Minute)); err != nil {
		t.Fatalf("remove first fixture membership: %v", err)
	}
	resolver.requests = nil
	collections, err = reader.List(context.Background(), savedcollectionapp.ListQuery{
		OwnerUserID: owner, Locale: savedcollectionapp.LocaleEN, ReadAt: base.Add(20 * time.Minute),
	})
	if err != nil {
		t.Fatalf("List(public first with expired source lease) error = %v", err)
	}
	if collections[0].Cover.Kind != savedcollectionapp.CoverKindItem ||
		collections[0].Cover.ResolvedImageURL == nil || len(resolver.requests) != 1 ||
		resolver.requests[0].OpaqueReference != "opaque:public-cover" {
		t.Fatalf("public-first cover = %+v requests=%+v", collections[0].Cover, resolver.requests)
	}
}

func TestPGSavedCollectionConcurrentTitleConvergence(t *testing.T) {
	pool, operationStore, repository := openSavedCollectionIntegration(t, nil)
	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()

	const workers = 16
	commands := make([]savedcollectionapp.CreateCommand, workers)
	for index := range commands {
		identity := createCollectionKernelOperation(
			t, operationStore, subject, session, domain.OperationKindCreateCollection,
			byte(120+index), base,
		)
		commands[index] = savedcollectionapp.CreateCommand{
			Identity: identity, OwnerUserID: owner, ClientCreationID: uuid.New(),
			Title: "Race title", ServerNow: base,
		}
	}
	results := runConcurrentCollectionCreates(t, repository, commands)
	applied := 0
	conflicts := 0
	for _, result := range results {
		if result.err != nil {
			t.Fatalf("concurrent Create() error = %v", result.err)
		}
		if result.receipt.Outcome() == domain.OperationOutcomeApplied {
			applied++
		} else if result.receipt.Failure() != nil && result.receipt.Failure().Code == domain.ErrorCodeCollectionTitleConflict {
			conflicts++
		}
	}
	if applied != 1 || conflicts != workers-1 {
		t.Fatalf("create convergence = applied %d conflicts %d", applied, conflicts)
	}
	assertCollectionCounts(t, pool, owner, 1, 0)
}

func TestPGSavedCollectionConcurrentDesiredSetConvergence(t *testing.T) {
	pool, operationStore, repository := openSavedCollectionIntegration(t, nil)
	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	first := createIntegrationCollection(
		t, repository, operationStore, subject, session, owner, "First race", 140, base,
	)
	second := createIntegrationCollection(
		t, repository, operationStore, subject, session, owner, "Second race", 141, base,
	)
	target := integrationSavedTarget(t, domain.EntityTypeAttraction)
	commands := make([]savedcollectionapp.ReplaceDesiredSetCommand, 2)
	for index, collectionID := range []uuid.UUID{first, second} {
		operationAt := base.Add(time.Second)
		identity := createCollectionKernelOperation(
			t, operationStore, subject, session, domain.OperationKindSetTargetCollections,
			byte(142+index), operationAt,
		)
		projection := integrationCollectionProjection(t, target, operationAt, 1)
		commands[index] = savedcollectionapp.ReplaceDesiredSetCommand{
			Identity: identity, OwnerUserID: owner, ServerNow: operationAt,
			Desired: savedcollectionapp.DesiredSet{
				Target: target,
				ExpectedRelationship: savedcollectionapp.ExpectedRelationship{
					State: savedcollectionapp.ExpectedRelationshipAbsent,
				},
				DesiredCollectionIDs: []uuid.UUID{collectionID},
			},
			Eligibility: &savedcollectionapp.PublicEligibility{Projection: projection},
		}
		prepareCollectionProjectionShell(t, repository, identity, projection)
	}

	results := runConcurrentDesiredSetReplacements(t, repository, commands)
	applied := 0
	stale := 0
	for _, result := range results {
		if result.err != nil {
			t.Fatalf("concurrent ReplaceDesiredSet() error = %v", result.err)
		}
		if result.receipt.Status() == domain.OperationStatusSucceeded &&
			result.receipt.Outcome() == domain.OperationOutcomeApplied {
			applied++
			continue
		}
		if result.receipt.Status() == domain.OperationStatusRejected &&
			result.receipt.Failure() != nil &&
			result.receipt.Failure().Code == domain.ErrorCodeMutationStale {
			stale++
		}
	}
	if applied != 1 || stale != 1 {
		t.Fatalf("desired-set convergence = applied %d stale %d", applied, stale)
	}
	assertCollectionCounts(t, pool, owner, 2, 1)
	assertTargetRelationshipCount(t, pool, owner, target, 1)
	assertTableCount(t, pool, "saved_outbox", 1)
	var activeMemberships int
	if err := pool.QueryRow(context.Background(), `
SELECT count(*) FROM saved_collection_items
WHERE owner_user_id = $1 AND membership_state = 'ACTIVE'`, owner.String()).Scan(&activeMemberships); err != nil {
		t.Fatal(err)
	}
	if activeMemberships != 1 {
		t.Fatalf("active memberships = %d, want 1", activeMemberships)
	}
}

func TestPGSavedCollectionDesiredSetAndGlobalUnsaveConverge(t *testing.T) {
	pool, operationStore, repository := openSavedCollectionIntegration(t, nil)
	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	first := createIntegrationCollection(
		t, repository, operationStore, subject, session, owner, "Move from", 150, base,
	)
	second := createIntegrationCollection(
		t, repository, operationStore, subject, session, owner, "Move to", 151, base.Add(time.Second),
	)
	target := integrationSavedTarget(t, domain.EntityTypeAttraction)
	activation := replaceAbsentTargetForIntegration(
		t, repository, operationStore, subject, session, owner, target, first, 152, base.Add(2*time.Second),
	)
	generation := activation.AppliedRelationship().Generation
	relationshipVersion := activation.AppliedRelationship().Version

	concurrentAt := base.Add(3 * time.Second)
	desiredIdentity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindSetTargetCollections, 153, concurrentAt,
	)
	projection := integrationCollectionProjection(t, target, concurrentAt, 2)
	desiredCommand := savedcollectionapp.ReplaceDesiredSetCommand{
		Identity: desiredIdentity, OwnerUserID: owner, ServerNow: concurrentAt,
		Desired: savedcollectionapp.DesiredSet{
			Target: target,
			ExpectedRelationship: savedcollectionapp.ExpectedRelationship{
				State:      savedcollectionapp.ExpectedRelationshipActive,
				Generation: generation,
				Version:    relationshipVersion,
			},
			ExpectedDependentMembershipVersion: 1,
			DesiredCollectionIDs:               []uuid.UUID{second},
		},
		Eligibility: &savedcollectionapp.PublicEligibility{Projection: projection},
	}
	prepareCollectionProjectionShell(t, repository, desiredIdentity, projection)
	savedItemRepository, err := NewPGSavedItemRepository(pool)
	if err != nil {
		t.Fatal(err)
	}
	unsaveIdentity := createKernelOperation(
		t, operationStore, subject, session, domain.OperationKindUnsave, 154,
		concurrentAt, concurrentAt.Add(10*time.Second),
	)
	unsaveCommand := integrationUnsaveCommand(unsaveIdentity, owner, target, concurrentAt)

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	start := make(chan struct{})
	var desiredReceipt *domain.SavedOperation
	var desiredErr error
	var unsaveReceipt *domain.SavedOperation
	var unsaveErr error
	var ready sync.WaitGroup
	var done sync.WaitGroup
	ready.Add(2)
	done.Add(2)
	go func() {
		defer done.Done()
		ready.Done()
		<-start
		desiredReceipt, desiredErr = repository.ReplaceDesiredSet(ctx, desiredCommand)
	}()
	go func() {
		defer done.Done()
		ready.Done()
		<-start
		unsaveReceipt, unsaveErr = savedItemRepository.GlobalUnsave(ctx, unsaveCommand)
	}()
	ready.Wait()
	close(start)
	done.Wait()
	if desiredErr != nil || unsaveErr != nil {
		t.Fatalf("concurrent desired/unsave errors = (%v, %v)", desiredErr, unsaveErr)
	}
	assertOperationOutcome(t, unsaveReceipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)
	if desiredReceipt.Status() != domain.OperationStatusSucceeded {
		assertRejectedOperation(t, desiredReceipt, domain.ErrorCodeMutationStale)
	}
	var relationshipState string
	if err := pool.QueryRow(context.Background(), `
SELECT relationship_state FROM saved_items
WHERE owner_user_id = $1 AND entity_type = $2 AND entity_id = $3`,
		owner.String(), string(target.EntityType()), target.EntityID(),
	).Scan(&relationshipState); err != nil {
		t.Fatal(err)
	}
	if relationshipState != string(domain.RelationshipStateRemoved) {
		t.Fatalf("final relationship state = %s", relationshipState)
	}
	assertCollectionCounts(t, pool, owner, 2, 0)
	assertCollectionItemCount(t, pool, first, 0)
	assertCollectionItemCount(t, pool, second, 0)
	assertTableCount(t, pool, "saved_outbox", 2)
}

func TestPGSavedCollectionActivationOutboxFailureRollsBackEverything(t *testing.T) {
	pool, operationStore, repository := openSavedCollectionIntegration(t, nil)
	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	collectionID := createIntegrationCollection(
		t, repository, operationStore, subject, session, owner, "Atomic", 170, base,
	)
	inlineClientCreationID := uuid.New()

	seedTarget := integrationSavedTarget(t, domain.EntityTypeGuide)
	savedItemRepository, err := NewPGSavedItemRepository(pool)
	if err != nil {
		t.Fatal(err)
	}
	seedIdentity := createKernelOperation(
		t, operationStore, subject, session, domain.OperationKindSave, 171, base.Add(time.Second), base.Add(11*time.Second),
	)
	seedSave := integrationSaveCommand(t, seedIdentity, owner, seedTarget, base.Add(time.Second), 1)
	if _, err := savedItemRepository.Save(context.Background(), seedSave); err != nil {
		t.Fatalf("seed Save() error = %v", err)
	}
	conflictingOutboxID := seedSave.ActivatedOutboxEventID
	ids := &sequenceSavedCollectionIDs{values: []uuid.UUID{
		uuid.New(), uuid.New(), uuid.New(), uuid.New(), conflictingOutboxID,
	}}
	failingRepository, err := NewPGSavedCollectionRepository(pool, savedcollectionapp.Limits{}, ids)
	if err != nil {
		t.Fatal(err)
	}
	target := integrationSavedTarget(t, domain.EntityTypeAttraction)
	operationAt := base.Add(2 * time.Second)
	identity := createCollectionKernelOperation(
		t, operationStore, subject, session, domain.OperationKindSetTargetCollections, 172, operationAt,
	)
	outboxCommand := savedcollectionapp.ReplaceDesiredSetCommand{
		Identity: identity, OwnerUserID: owner, ServerNow: operationAt,
		Desired: savedcollectionapp.DesiredSet{
			Target:               target,
			ExpectedRelationship: savedcollectionapp.ExpectedRelationship{State: savedcollectionapp.ExpectedRelationshipAbsent},
			NewCollection: &savedcollectionapp.NewCollection{
				ClientCreationID: inlineClientCreationID,
				Title:            "Inline rollback",
			},
		},
		Eligibility: &savedcollectionapp.PublicEligibility{
			Projection: integrationCollectionProjection(t, target, operationAt, 1),
		},
	}
	prepareCollectionProjectionShell(t, failingRepository, identity, outboxCommand.Eligibility.Projection)
	_, err = failingRepository.ReplaceDesiredSet(context.Background(), outboxCommand)
	if !errors.Is(err, domain.ErrMutationStale) {
		t.Fatalf("ReplaceDesiredSet(outbox conflict) error = %v", err)
	}
	assertOperationStatusInDatabase(t, pool, identity.OperationID, domain.OperationStatusPending)
	var relationshipCount int
	if err := pool.QueryRow(context.Background(), `
SELECT count(*) FROM saved_items
WHERE owner_user_id = $1 AND entity_type = $2 AND entity_id = $3`,
		owner.String(), string(target.EntityType()), target.EntityID(),
	).Scan(&relationshipCount); err != nil {
		t.Fatal(err)
	}
	if relationshipCount != 0 {
		t.Fatalf("rolled-back relationship count = %d", relationshipCount)
	}
	assertCollectionItemCount(t, pool, collectionID, 0)
	assertCollectionCounts(t, pool, owner, 1, 0)
	assertTableCount(t, pool, "saved_outbox", 1)
	var inlineCount int
	if err := pool.QueryRow(context.Background(), `
SELECT count(*) FROM saved_collections
WHERE owner_user_id = $1 AND client_creation_id = $2`,
		owner.String(), inlineClientCreationID.String(),
	).Scan(&inlineCount); err != nil {
		t.Fatal(err)
	}
	if inlineCount != 0 {
		t.Fatalf("rolled-back inline collection count = %d", inlineCount)
	}
}

func TestPGSavedCollectionReadPlanUsesOwnerAndCoverIndexes(t *testing.T) {
	pool, _, _ := openSavedCollectionIntegration(t, nil)
	tx, err := pool.Begin(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	defer rollbackCollectionTx(tx)
	if _, err := tx.Exec(context.Background(), "SET LOCAL enable_seqscan = off"); err != nil {
		t.Fatal(err)
	}
	rows, err := tx.Query(
		context.Background(),
		"EXPLAIN (COSTS OFF) "+savedCollectionReadSelectSQL+listSavedCollectionsOrderSQL,
		uuid.NewString(),
	)
	if err != nil {
		t.Fatalf("EXPLAIN collection list: %v", err)
	}
	defer rows.Close()
	lines := make([]string, 0)
	for rows.Next() {
		var line string
		if err := rows.Scan(&line); err != nil {
			t.Fatal(err)
		}
		lines = append(lines, line)
	}
	plan := strings.Join(lines, "\n")
	for _, indexName := range []string{
		"idx_saved_collections_owner_organized",
		"idx_saved_collection_items_active_list",
	} {
		if !strings.Contains(plan, indexName) {
			t.Fatalf("query plan does not use %s:\n%s", indexName, plan)
		}
	}
}

func openSavedCollectionIntegration(
	t *testing.T,
	ids savedCollectionIDGenerator,
) (*pgxpool.Pool, *PGOperationStore, *PGSavedCollectionRepository) {
	t.Helper()
	pool, operationStore := openOperationStoreIntegration(t)
	repository, err := NewPGSavedCollectionRepository(pool, savedcollectionapp.Limits{}, ids)
	if err != nil {
		t.Fatalf("NewPGSavedCollectionRepository() error = %v", err)
	}
	t.Cleanup(func() { truncateSavedItemKernel(t, pool) })
	return pool, operationStore, repository
}

func createCollectionKernelOperation(
	t testing.TB,
	store *PGOperationStore,
	subject uuid.UUID,
	session uuid.UUID,
	kind domain.OperationKind,
	seed byte,
	createdAt time.Time,
) savedcollectionapp.MutationIdentity {
	t.Helper()
	identity := createKernelOperation(
		t, store, subject, session, kind, seed, createdAt, createdAt.Add(10*time.Second),
	)
	return savedcollectionapp.MutationIdentity{
		SubjectID:             identity.SubjectID,
		SessionGeneration:     identity.SessionGeneration,
		OperationID:           identity.OperationID,
		Kind:                  identity.Kind,
		SemanticRequestHMAC:   append([]byte(nil), identity.SemanticRequestHMAC...),
		RequestHMACKeyVersion: identity.RequestHMACKeyVersion,
	}
}

func createIntegrationCollection(
	t testing.TB,
	repository *PGSavedCollectionRepository,
	store *PGOperationStore,
	subject uuid.UUID,
	session uuid.UUID,
	owner uuid.UUID,
	title string,
	seed byte,
	serverNow time.Time,
) uuid.UUID {
	t.Helper()
	receipt, err := repository.Create(context.Background(), savedcollectionapp.CreateCommand{
		Identity: createCollectionKernelOperation(
			t, store, subject, session, domain.OperationKindCreateCollection, seed, serverNow,
		),
		OwnerUserID: owner, ClientCreationID: uuid.New(), Title: title, ServerNow: serverNow,
	})
	if err != nil {
		t.Fatalf("createIntegrationCollection(%q): %v", title, err)
	}
	if receipt.AppliedCollection() == nil {
		t.Fatalf("createIntegrationCollection(%q) has no applied collection", title)
	}
	return receipt.AppliedCollection().CollectionID
}

func integrationCollectionProjection(
	t testing.TB,
	target domain.SavedTarget,
	serverNow time.Time,
	revision uint64,
) saveditemapp.PublicProjectionSnapshot {
	t.Helper()
	return integrationSaveCommand(
		t,
		saveditemapp.MutationIdentity{},
		uuid.New(),
		target,
		serverNow,
		revision,
	).Projection
}

func prepareCollectionProjectionShell(
	t testing.TB,
	repository *PGSavedCollectionRepository,
	identity savedcollectionapp.MutationIdentity,
	projection saveditemapp.PublicProjectionSnapshot,
) {
	t.Helper()
	receipt, err := repository.PrepareProjectionShell(
		context.Background(),
		savedcollectionapp.PrepareProjectionShellCommand{
			Identity:       identity,
			Target:         projection.Target,
			SourceService:  projection.SourceService,
			ShellExpiresAt: projection.ShellExpiresAt,
			ServerNow:      projection.VisibilityValidatedAt.Add(time.Second),
		},
	)
	if err != nil {
		t.Fatalf("PrepareProjectionShell() error = %v", err)
	}
	if receipt == nil || receipt.Status() != domain.OperationStatusPending {
		t.Fatalf("PrepareProjectionShell() receipt = %+v", receipt)
	}
}

func replaceAbsentTargetForIntegration(
	t testing.TB,
	repository *PGSavedCollectionRepository,
	store *PGOperationStore,
	subject uuid.UUID,
	session uuid.UUID,
	owner uuid.UUID,
	target domain.SavedTarget,
	collectionID uuid.UUID,
	seed byte,
	serverNow time.Time,
) *domain.SavedOperation {
	t.Helper()
	identity := createCollectionKernelOperation(
		t, store, subject, session, domain.OperationKindSetTargetCollections, seed, serverNow,
	)
	projection := integrationCollectionProjection(t, target, serverNow, 1)
	prepareCollectionProjectionShell(t, repository, identity, projection)
	receipt, err := repository.ReplaceDesiredSet(
		context.Background(),
		savedcollectionapp.ReplaceDesiredSetCommand{
			Identity: identity, OwnerUserID: owner, ServerNow: serverNow,
			Desired: savedcollectionapp.DesiredSet{
				Target: target,
				ExpectedRelationship: savedcollectionapp.ExpectedRelationship{
					State: savedcollectionapp.ExpectedRelationshipAbsent,
				},
				DesiredCollectionIDs: []uuid.UUID{collectionID},
			},
			Eligibility: &savedcollectionapp.PublicEligibility{Projection: projection},
		},
	)
	if err != nil {
		t.Fatalf("ReplaceDesiredSet(absent target) error = %v", err)
	}
	return receipt
}

func assertTargetProjectionCount(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
	want int,
) {
	t.Helper()
	var count int
	if err := pool.QueryRow(context.Background(), `
SELECT count(*) FROM saved_content_projections
WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()), target.EntityID(),
	).Scan(&count); err != nil {
		t.Fatalf("read target projection count: %v", err)
	}
	if count != want {
		t.Fatalf("target projection count = %d, want %d", count, want)
	}
}

func assertTargetRelationshipCount(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	target domain.SavedTarget,
	want int,
) {
	t.Helper()
	var count int
	if err := pool.QueryRow(context.Background(), `
SELECT count(*) FROM saved_items
WHERE owner_user_id = $1 AND entity_type = $2 AND entity_id = $3`,
		owner.String(), string(target.EntityType()), target.EntityID(),
	).Scan(&count); err != nil {
		t.Fatalf("read target relationship count: %v", err)
	}
	if count != want {
		t.Fatalf("target relationship count = %d, want %d", count, want)
	}
}

func assertCollectionCounts(t testing.TB, pool *pgxpool.Pool, owner uuid.UUID, collections, memberships int64) {
	t.Helper()
	var activeCollections int64
	var activeMemberships int64
	if err := pool.QueryRow(context.Background(), `
SELECT active_collections_count, active_memberships_count
FROM saved_collection_usage
WHERE owner_user_id = $1`, owner.String()).Scan(&activeCollections, &activeMemberships); err != nil {
		t.Fatalf("read collection usage: %v", err)
	}
	if activeCollections != collections || activeMemberships != memberships {
		t.Fatalf("collection usage = (%d, %d), want (%d, %d)", activeCollections, activeMemberships, collections, memberships)
	}
}

func assertCollectionItemCount(t testing.TB, pool *pgxpool.Pool, collectionID uuid.UUID, want int64) {
	t.Helper()
	var count int64
	if err := pool.QueryRow(context.Background(), `
SELECT active_item_count FROM saved_collections WHERE id = $1`, collectionID.String()).Scan(&count); err != nil {
		t.Fatalf("read collection count: %v", err)
	}
	if count != want {
		t.Fatalf("collection %s active count = %d, want %d", collectionID, count, want)
	}
}

func assertOperationStatusInDatabase(
	t testing.TB,
	pool *pgxpool.Pool,
	operationID uuid.UUID,
	want domain.OperationStatus,
) {
	t.Helper()
	var status string
	if err := pool.QueryRow(context.Background(), `
SELECT status FROM saved_operations WHERE operation_id = $1`, operationID.String()).Scan(&status); err != nil {
		t.Fatalf("read operation status: %v", err)
	}
	if status != string(want) {
		t.Fatalf("operation status = %s, want %s", status, want)
	}
}

type integrationThumbnailResolver struct {
	resolved map[uuid.UUID]string
	requests []savedcollectionapp.ThumbnailRequest
}

func (resolver *integrationThumbnailResolver) ResolveCollectionThumbnails(
	_ context.Context,
	requests []savedcollectionapp.ThumbnailRequest,
) (map[uuid.UUID]string, error) {
	resolver.requests = append([]savedcollectionapp.ThumbnailRequest(nil), requests...)
	return resolver.resolved, nil
}

func seedDerivedCoverFixture(t testing.TB, pool *pgxpool.Pool, owner uuid.UUID, base time.Time) uuid.UUID {
	t.Helper()
	collectionID := uuid.New()
	clientCreationID := uuid.New()
	publicItemID := uuid.New()
	privateItemID := uuid.New()
	publicTarget := integrationSavedTarget(t, domain.EntityTypeAttraction)
	privateTarget := integrationSavedTarget(t, domain.EntityTypeActivity)
	publicSavedAt := base.Add(time.Minute)
	privateSavedAt := base.Add(2 * time.Minute)
	_, err := pool.Exec(context.Background(), `
INSERT INTO saved_content_projections (
    entity_type, entity_id, source_service, source_revision, projection_revision,
    visibility_revision, visibility_status, visibility_validated_at,
    source_default_locale, title_en, search_document_version,
    normalized_search_document_en, media_reference, media_reference_revision,
    media_valid_until, canonical_detail_route, ever_referenced, created_at, updated_at
) VALUES
    ($1, $2, 'place-service', 1, 1, 1, 'PUBLIC', $3, 'EN', 'Public first', 1,
     'public first', 'opaque:public-cover', 1, $4, '/attractions/public', TRUE, $3, $3),
    ($5, $6, 'activity-service', 1, 1, 1, 'PRIVATE', $3, NULL, NULL, 0,
     NULL, NULL, NULL, NULL, NULL, TRUE, $3, $3);
INSERT INTO saved_items (
    id, owner_user_id, entity_type, entity_id, relationship_state,
    state_generation, relationship_attribution_id, relationship_version,
    dependent_membership_version, saved_at, created_at, updated_at
) VALUES
    ($7, $9, $1, $2, 'ACTIVE', $10, $11, 1, 1, $12, $12, $12),
    ($8, $9, $5, $6, 'ACTIVE', $13, $14, 1, 1, $15, $15, $15);
INSERT INTO saved_collections (
    id, owner_user_id, client_creation_id, title, normalized_title_key,
    lifecycle_state, lifecycle_version, metadata_version, items_version,
    active_item_count, created_at, organized_at, updated_at
) VALUES ($16, $9, $17, 'Cover', 'cover', 'ACTIVE', 1, 1, 2, 2, $3, $15, $15);
INSERT INTO saved_collection_items (
    id, owner_user_id, collection_id, saved_item_id, membership_state,
    membership_version, saved_at_snapshot, added_at, updated_at
) VALUES
    ($18, $9, $16, $7, 'ACTIVE', 1, $12, $15, $15),
    ($19, $9, $16, $8, 'ACTIVE', 1, $15, $15, $15);
INSERT INTO saved_user_usage (
    owner_user_id, active_saved_items_count, usage_version, created_at, updated_at
) VALUES ($9, 2, 1, $3, $15);
INSERT INTO saved_collection_usage (
    owner_user_id, active_collections_count, active_memberships_count,
    usage_version, created_at, updated_at
) VALUES ($9, 1, 2, 1, $3, $15)`,
		string(publicTarget.EntityType()), publicTarget.EntityID(), base,
		base.Add(10*time.Minute), string(privateTarget.EntityType()), privateTarget.EntityID(),
		publicItemID.String(), privateItemID.String(), owner.String(), uuid.NewString(), uuid.NewString(),
		publicSavedAt, uuid.NewString(), uuid.NewString(), privateSavedAt,
		collectionID.String(), clientCreationID.String(), uuid.NewString(), uuid.NewString(),
	)
	if err != nil {
		t.Fatalf("seed derived cover fixture: %v", err)
	}
	return collectionID
}

type collectionCreateResult struct {
	receipt *domain.SavedOperation
	err     error
}

func runConcurrentCollectionCreates(
	t *testing.T,
	repository *PGSavedCollectionRepository,
	commands []savedcollectionapp.CreateCommand,
) []collectionCreateResult {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	start := make(chan struct{})
	results := make([]collectionCreateResult, len(commands))
	var ready sync.WaitGroup
	var done sync.WaitGroup
	ready.Add(len(commands))
	done.Add(len(commands))
	for index := range commands {
		go func(index int) {
			defer done.Done()
			ready.Done()
			<-start
			results[index].receipt, results[index].err = repository.Create(ctx, commands[index])
		}(index)
	}
	ready.Wait()
	close(start)
	done.Wait()
	return results
}

func runConcurrentDesiredSetReplacements(
	t *testing.T,
	repository *PGSavedCollectionRepository,
	commands []savedcollectionapp.ReplaceDesiredSetCommand,
) []collectionCreateResult {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	start := make(chan struct{})
	results := make([]collectionCreateResult, len(commands))
	var ready sync.WaitGroup
	var done sync.WaitGroup
	ready.Add(len(commands))
	done.Add(len(commands))
	for index := range commands {
		go func(index int) {
			defer done.Done()
			ready.Done()
			<-start
			results[index].receipt, results[index].err = repository.ReplaceDesiredSet(ctx, commands[index])
		}(index)
	}
	ready.Wait()
	close(start)
	done.Wait()
	return results
}

type sequenceSavedCollectionIDs struct {
	mu     sync.Mutex
	values []uuid.UUID
}

func (generator *sequenceSavedCollectionIDs) NewV4() uuid.UUID {
	generator.mu.Lock()
	defer generator.mu.Unlock()
	if len(generator.values) == 0 {
		return uuid.Nil
	}
	value := generator.values[0]
	generator.values = generator.values[1:]
	return value
}
