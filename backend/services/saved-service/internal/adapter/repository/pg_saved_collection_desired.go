package repository

import (
	"context"
	"errors"
	"math"
	"sort"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	savedcollectionapp "kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const selectSavedRelationshipForCollectionAnalysisSQL = `
SELECT id::text,
       relationship_state,
       state_generation::text,
       relationship_attribution_id::text,
       relationship_version,
       dependent_membership_version,
       saved_at,
       updated_at
FROM saved_items
WHERE owner_user_id = $1
  AND entity_type = $2
  AND entity_id = $3`

const selectSavedCollectionByClientCreationIDSQL = `
SELECT id::text,
       client_creation_id::text,
       title,
       normalized_title_key,
       lifecycle_state,
       lifecycle_version,
       metadata_version,
       items_version,
       active_item_count,
       created_at,
       organized_at,
       updated_at,
       deleted_at
FROM saved_collections
WHERE owner_user_id = $1
  AND client_creation_id = $2`

func (repository *PGSavedCollectionRepository) AnalyzeDesiredSet(
	ctx context.Context,
	query savedcollectionapp.AnalyzeDesiredSetQuery,
) (savedcollectionapp.DesiredSetAnalysis, error) {
	if repository == nil || repository.pool == nil {
		return savedcollectionapp.DesiredSetAnalysis{}, savedcollectionapp.ErrRepositoryUnavailable
	}
	if err := validateSavedCollectionContext(ctx); err != nil {
		return savedcollectionapp.DesiredSetAnalysis{}, err
	}
	if err := query.Validate(repository.limits.MaxDesiredCollectionIDs); err != nil {
		return savedcollectionapp.DesiredSetAnalysis{}, err
	}
	tx, err := repository.pool.BeginTx(ctx, pgx.TxOptions{
		IsoLevel:   pgx.RepeatableRead,
		AccessMode: pgx.ReadOnly,
	})
	if err != nil {
		return savedcollectionapp.DesiredSetAnalysis{}, mapSavedCollectionPGError(err)
	}
	defer rollbackCollectionTx(tx)

	relationship, found, err := scanSavedRelationship(tx.QueryRow(
		ctx,
		selectSavedRelationshipForCollectionAnalysisSQL,
		query.OwnerUserID.String(),
		string(query.Desired.Target.EntityType()),
		query.Desired.Target.EntityID(),
	))
	if err != nil {
		return savedcollectionapp.DesiredSetAnalysis{}, mapSavedCollectionPGError(err)
	}
	if err := verifyExpectedSavedRelationship(query.Desired, relationship, found); err != nil {
		return savedcollectionapp.DesiredSetAnalysis{}, err
	}
	current, err := effectiveTargetCollectionIDs(ctx, tx, query.OwnerUserID, relationship)
	if err != nil {
		return savedcollectionapp.DesiredSetAnalysis{}, err
	}
	desired := query.Desired.SortedCollectionIDs()
	if err := verifyDesiredCollectionsReadable(ctx, tx, query.OwnerUserID, desired); err != nil {
		return savedcollectionapp.DesiredSetAnalysis{}, err
	}
	createsInline := false
	if query.Desired.NewCollection != nil {
		inline, inlineFound, err := scanSavedCollectionState(tx.QueryRow(
			ctx,
			selectSavedCollectionByClientCreationIDSQL,
			query.OwnerUserID.String(),
			query.Desired.NewCollection.ClientCreationID.String(),
		))
		if err != nil {
			return savedcollectionapp.DesiredSetAnalysis{}, err
		}
		title, err := savedcollectionapp.NormalizeStoredTitle(query.Desired.NewCollection.Title)
		if err != nil {
			return savedcollectionapp.DesiredSetAnalysis{}, err
		}
		if inlineFound {
			if inline.lifecycle != savedcollectionapp.CollectionLifecycleActive {
				return savedcollectionapp.DesiredSetAnalysis{}, domain.ErrCollectionNotFound
			}
			if inline.title == nil || inline.normalizedTitle == nil ||
				*inline.title != title.Display || *inline.normalizedTitle != title.Key {
				return savedcollectionapp.DesiredSetAnalysis{}, domain.ErrReplayMismatch
			}
			desired = unionSortedUUIDs(desired, []uuid.UUID{inline.id})
		} else {
			createsInline = true
		}
	}
	change := classifyDesiredCollectionSet(current, desired, createsInline)
	snapshot := relationshipSnapshot(relationship, found)
	dependentVersion := uint64(0)
	if found {
		dependentVersion = relationship.dependentMembershipVersion
	}
	analysis := savedcollectionapp.DesiredSetAnalysis{
		Change:                     change,
		CurrentCollectionIDs:       append([]uuid.UUID(nil), current...),
		DesiredExistingIDs:         append([]uuid.UUID(nil), desired...),
		HasInlineCollection:        createsInline,
		Relationship:               snapshot,
		DependentMembershipVersion: dependentVersion,
	}
	if err := tx.Commit(ctx); err != nil {
		return savedcollectionapp.DesiredSetAnalysis{}, mapSavedCollectionPGError(err)
	}
	return analysis, nil
}

func (repository *PGSavedCollectionRepository) ReplaceDesiredSet(
	ctx context.Context,
	command savedcollectionapp.ReplaceDesiredSetCommand,
) (*domain.SavedOperation, error) {
	if err := command.ValidateIdentity(); err != nil {
		return nil, err
	}
	command.ServerNow = canonicalPostgresTimestamp(command.ServerNow)
	command.Identity.SemanticRequestHMAC = append([]byte(nil), command.Identity.SemanticRequestHMAC...)
	tx, err := repository.beginCollectionTx(ctx)
	if err != nil {
		return nil, err
	}
	defer rollbackCollectionTx(tx)

	receipt, err := lockSavedCollectionOperation(ctx, tx, command.Identity)
	if err != nil {
		return nil, err
	}
	if terminal, done, err := replayOrExpireSavedCollectionOperation(
		ctx, tx, receipt, command.Identity, command.ServerNow,
	); done || err != nil {
		return terminal, err
	}
	if command.ServerNow.Before(receipt.CreatedAt()) {
		return nil, savedcollectionapp.ErrInvalidCommand
	}
	if err := command.Validate(receipt.CommitDeadline(), repository.limits.MaxDesiredCollectionIDs); err != nil {
		if errors.Is(err, domain.ErrCollectionTitleInvalid) {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionTitleInvalid, domain.RefreshScopeNone,
			)
		}
		return nil, err
	}

	// A supplied eligibility result is written before personal-domain locks so
	// source deny events and projection revisions retain the shared lock order.
	if command.Eligibility != nil {
		err = writePreparedCollectionPublicProjection(
			ctx,
			tx,
			command.Eligibility.Projection,
			command.ServerNow,
		)
		if errors.Is(err, errSavedProjectionRevisionRollback) {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrMutationStale, domain.RefreshScopeNone,
			)
		}
		if err != nil {
			return nil, mapSavedCollectionPGError(err)
		}
	}
	if err := lockSavedCollectionOwner(ctx, tx, command.OwnerUserID); err != nil {
		return nil, err
	}
	relationship, found, err := lockSavedRelationship(
		ctx, tx, command.OwnerUserID, command.Desired.Target,
	)
	if err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	if err := verifyExpectedSavedRelationship(command.Desired, relationship, found); err != nil {
		return rejectSavedCollectionOperation(
			ctx, tx, receipt, command.Identity, command.ServerNow,
			domain.ErrMutationStale, domain.RefreshScopeNone,
		)
	}
	if found && command.ServerNow.Before(relationship.updatedAt) {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	current, err := effectiveTargetCollectionIDs(ctx, tx, command.OwnerUserID, relationship)
	if err != nil {
		return nil, err
	}

	desired := command.Desired.SortedCollectionIDs()
	var inlineState *savedCollectionState
	createsInline := false
	var inlineTitle savedcollectionapp.StoredTitle
	if command.Desired.NewCollection != nil {
		inlineTitle, err = savedcollectionapp.NormalizeStoredTitle(command.Desired.NewCollection.Title)
		if err != nil {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionTitleInvalid, domain.RefreshScopeNone,
			)
		}
		inline, inlineFound, err := scanSavedCollectionState(tx.QueryRow(
			ctx,
			selectSavedCollectionByClientCreationIDSQL,
			command.OwnerUserID.String(),
			command.Desired.NewCollection.ClientCreationID.String(),
		))
		if err != nil {
			return nil, err
		}
		if inlineFound {
			if inline.lifecycle != savedcollectionapp.CollectionLifecycleActive {
				return rejectSavedCollectionOperation(
					ctx, tx, receipt, command.Identity, command.ServerNow,
					domain.ErrCollectionNotFound, domain.RefreshScopeNone,
				)
			}
			if inline.title == nil || inline.normalizedTitle == nil ||
				*inline.title != inlineTitle.Display || *inline.normalizedTitle != inlineTitle.Key {
				return rejectSavedCollectionOperation(
					ctx, tx, receipt, command.Identity, command.ServerNow,
					domain.ErrReplayMismatch, domain.RefreshScopeNone,
				)
			}
			inlineState = &inline
			desired = unionSortedUUIDs(desired, []uuid.UUID{inline.id})
		} else {
			createsInline = true
		}
	}

	collectionIDsToLock := unionSortedUUIDs(current, desired)
	collections, err := lockSavedCollectionsByIDs(
		ctx, tx, command.OwnerUserID, collectionIDsToLock,
	)
	if err != nil {
		return nil, err
	}
	for _, collectionID := range collectionIDsToLock {
		state, exists := collections[collectionID]
		if !exists || state.lifecycle != savedcollectionapp.CollectionLifecycleActive {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionNotFound, domain.RefreshScopeNone,
			)
		}
		if command.ServerNow.Before(state.updatedAt) {
			return nil, savedcollectionapp.ErrDataInvariant
		}
	}
	if inlineState != nil {
		locked, exists := collections[inlineState.id]
		if !exists || locked.clientCreationID != inlineState.clientCreationID ||
			locked.lifecycle != savedcollectionapp.CollectionLifecycleActive ||
			locked.title == nil || locked.normalizedTitle == nil ||
			*locked.title != inlineTitle.Display || *locked.normalizedTitle != inlineTitle.Key {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionNotFound, domain.RefreshScopeNone,
			)
		}
		inlineState = &locked
	}

	change := classifyDesiredCollectionSet(current, desired, createsInline)
	activationRequired := (len(desired) > 0 || createsInline) &&
		(!found || relationship.state == domain.RelationshipStateRemoved)
	if activationRequired && command.Eligibility == nil {
		return nil, savedcollectionapp.ErrPublicEligibilityRequired
	}

	allMembershipCollectionIDs := collectionIDsToLock
	memberships := map[uuid.UUID]savedMembershipState{}
	if found {
		memberships, err = lockSavedMembershipsForTarget(
			ctx, tx, command.OwnerUserID, relationship.id, allMembershipCollectionIDs,
		)
		if err != nil {
			return nil, err
		}
	}
	currentSet := uuidSet(current)
	desiredSet := uuidSet(desired)
	removals, additions := collectionSetDifference(currentSet, desiredSet)
	var savedUserUsage savedUserUsageState
	if activationRequired {
		savedUserUsage, err = ensureAndLockSavedUserUsage(
			ctx, tx, command.OwnerUserID, command.ServerNow,
		)
		if err != nil {
			return nil, mapSavedCollectionPGError(err)
		}
		if uint64(savedUserUsage.activeCount) >= repository.limits.MaxActiveSaves {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrItemLimitReached, domain.RefreshScopeNone,
			)
		}
	}

	needsUsage := len(removals) > 0 || len(additions) > 0 || createsInline
	var collectionUsage savedCollectionUsageMutationState
	if needsUsage {
		collectionUsage, err = ensureAndLockSavedCollectionUsage(
			ctx, tx, command.OwnerUserID, command.ServerNow,
		)
		if err != nil {
			return nil, err
		}
	}
	var preparedInline *savedCollectionState
	if createsInline {
		if collectionUsage.activeCollections >= repository.limits.MaxActiveCollections {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionLimitReached, domain.RefreshScopeNone,
			)
		}
		conflict, err := activeSavedCollectionTitleConflict(
			ctx, tx, command.OwnerUserID, inlineTitle.Key, nil,
		)
		if err != nil {
			return nil, err
		}
		if conflict {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionTitleConflict, domain.RefreshScopeNone,
			)
		}
		created, err := repository.prepareInlineSavedCollection(command, inlineTitle)
		if err != nil {
			return nil, err
		}
		preparedInline = &created
		inlineState = &created
		collections[created.id] = created
		desired = unionSortedUUIDs(desired, []uuid.UUID{created.id})
		desiredSet[created.id] = struct{}{}
		additions = append(additions, created.id)
		sortUUIDs(additions)
	}

	for _, collectionID := range additions {
		state, exists := collections[collectionID]
		if !exists || state.activeItemCount >= repository.limits.MaxMembershipsPerCollection {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionItemLimitReached, domain.RefreshScopeNone,
			)
		}
	}
	finalMembershipCount, ok := applyCountDelta(
		collectionUsage.activeMemberships,
		len(additions)-len(removals),
	)
	if needsUsage && (!ok || finalMembershipCount > repository.limits.MaxMembershipsPerOwner) {
		return rejectSavedCollectionOperation(
			ctx, tx, receipt, command.Identity, command.ServerNow,
			domain.ErrMembershipLimitReached, domain.RefreshScopeNone,
		)
	}

	observedRelationshipVersion := uint64(0)
	observedDependentVersion := uint64(0)
	if found {
		observedRelationshipVersion = relationship.relationshipVersion
		observedDependentVersion = relationship.dependentMembershipVersion
	}
	if preparedInline != nil {
		if err := insertPreparedInlineSavedCollection(ctx, tx, command, *preparedInline); err != nil {
			mapped := mapSavedCollectionPGError(err)
			if errors.Is(mapped, domain.ErrCollectionTitleConflict) {
				return rejectSavedCollectionOperation(
					ctx, tx, receipt, command.Identity, command.ServerNow,
					domain.ErrCollectionTitleConflict, domain.RefreshScopeNone,
				)
			}
			return nil, mapped
		}
	}
	var userUsageVersion *uint64
	if activationRequired {
		activated, usageVersion, err := repository.activateSavedRelationshipForCollections(
			ctx, tx, command, found, savedUserUsage,
		)
		if err != nil {
			return nil, err
		}
		relationship = activated
		found = true
		userUsageVersion = &usageVersion
	} else if change.ExpandsCollections() {
		if err := markSavedProjectionReferenced(
			ctx, tx, command.Desired.Target, command.ServerNow,
		); err != nil {
			return nil, mapSavedCollectionPGError(err)
		}
	}

	for _, collectionID := range removals {
		membership, exists := memberships[collectionID]
		if !exists || membership.state != "ACTIVE" {
			return nil, savedcollectionapp.ErrDataInvariant
		}
		if err := removeSavedCollectionMembership(
			ctx, tx, command.OwnerUserID, collectionID, relationship, membership, command.ServerNow,
		); err != nil {
			return nil, err
		}
		updated, err := changeSavedCollectionItemCount(
			ctx, tx, command.OwnerUserID, collections[collectionID], -1, command.ServerNow,
		)
		if err != nil {
			return nil, err
		}
		collections[collectionID] = updated
	}
	for _, collectionID := range additions {
		var existing *savedMembershipState
		if membership, exists := memberships[collectionID]; exists {
			copy := membership
			existing = &copy
		}
		if err := addSavedCollectionMembership(
			ctx,
			tx,
			repository.ids,
			command.OwnerUserID,
			collectionID,
			relationship,
			existing,
			command.ServerNow,
		); err != nil {
			return nil, err
		}
		updated, err := changeSavedCollectionItemCount(
			ctx, tx, command.OwnerUserID, collections[collectionID], 1, command.ServerNow,
		)
		if err != nil {
			return nil, err
		}
		collections[collectionID] = updated
	}

	membershipsChanged := len(removals) > 0 || len(additions) > 0
	if membershipsChanged {
		relationship, err = incrementSavedRelationshipMembershipVersion(
			ctx, tx, command.OwnerUserID, relationship, command.ServerNow,
		)
		if err != nil {
			return nil, err
		}
	}
	if needsUsage {
		collectionDelta := int64(0)
		if createsInline {
			collectionDelta = 1
		}
		collectionUsage, err = changeSavedCollectionUsage(
			ctx,
			tx,
			command.OwnerUserID,
			collectionUsage,
			collectionDelta,
			int64(len(additions)-len(removals)),
			command.ServerNow,
		)
		if err != nil {
			return nil, err
		}
		if collectionUsage.activeMemberships != finalMembershipCount {
			return nil, savedcollectionapp.ErrDataInvariant
		}
	}

	outcome := domain.OperationOutcomeNoOp
	refreshScope := domain.RefreshScopeNone
	if activationRequired || membershipsChanged || createsInline {
		outcome = domain.OperationOutcomeApplied
		refreshScope = domain.RefreshScopeBoth
	}
	versions := domain.OperationVersionEffects{
		ObservedRelationshipVersion:        &observedRelationshipVersion,
		ObservedDependentMembershipVersion: &observedDependentVersion,
		AppliedUserUsageVersion:            userUsageVersion,
	}
	if found {
		versions.AppliedRelationship = &domain.AppliedRelationshipVersion{
			Generation: relationship.stateGeneration,
			Version:    relationship.relationshipVersion,
		}
		versions.AppliedDependentMembershipVersion = uint64Pointer(
			relationship.dependentMembershipVersion,
		)
	} else {
		zero := uint64(0)
		versions.AppliedDependentMembershipVersion = &zero
	}
	if inlineState != nil {
		versions.AppliedCollection = appliedCollectionVersion(*inlineState)
	}
	return succeedSavedCollectionOperation(
		ctx, tx, receipt, command.Identity, command.ServerNow,
		outcome, refreshScope, versions,
	)
}

func (repository *PGSavedCollectionRepository) prepareInlineSavedCollection(
	command savedcollectionapp.ReplaceDesiredSetCommand,
	title savedcollectionapp.StoredTitle,
) (savedCollectionState, error) {
	collectionID, err := newSavedCollectionUUID(repository.ids)
	if err != nil {
		return savedCollectionState{}, err
	}
	return savedCollectionState{
		id:               collectionID,
		clientCreationID: command.Desired.NewCollection.ClientCreationID,
		title:            stringPointer(title.Display),
		normalizedTitle:  stringPointer(title.Key),
		lifecycle:        savedcollectionapp.CollectionLifecycleActive,
		lifecycleVersion: 1,
		metadataVersion:  1,
		itemsVersion:     0,
		activeItemCount:  0,
		createdAt:        command.ServerNow.UTC(),
		organizedAt:      command.ServerNow.UTC(),
		updatedAt:        command.ServerNow.UTC(),
	}, nil
}

func insertPreparedInlineSavedCollection(
	ctx context.Context,
	tx pgx.Tx,
	command savedcollectionapp.ReplaceDesiredSetCommand,
	state savedCollectionState,
) error {
	if state.title == nil || state.normalizedTitle == nil {
		return savedcollectionapp.ErrDataInvariant
	}
	tag, err := tx.Exec(
		ctx,
		insertSavedCollectionSQL,
		state.id.String(),
		command.OwnerUserID.String(),
		state.clientCreationID.String(),
		*state.title,
		*state.normalizedTitle,
		command.ServerNow.UTC(),
	)
	if err != nil {
		return mapSavedCollectionPGError(err)
	}
	if tag.RowsAffected() != 1 {
		return savedcollectionapp.ErrDataInvariant
	}
	return nil
}

func (repository *PGSavedCollectionRepository) activateSavedRelationshipForCollections(
	ctx context.Context,
	tx pgx.Tx,
	command savedcollectionapp.ReplaceDesiredSetCommand,
	found bool,
	usage savedUserUsageState,
) (savedRelationshipState, uint64, error) {
	if command.Eligibility == nil {
		return savedRelationshipState{}, 0, savedcollectionapp.ErrPublicEligibilityRequired
	}
	savedItemID, err := newSavedCollectionUUID(repository.ids)
	if err != nil {
		return savedRelationshipState{}, 0, err
	}
	stateGeneration, err := newSavedCollectionUUID(repository.ids)
	if err != nil {
		return savedRelationshipState{}, 0, err
	}
	attributionID, err := newSavedCollectionUUID(repository.ids)
	if err != nil {
		return savedRelationshipState{}, 0, err
	}
	outboxEventID, err := newSavedCollectionUUID(repository.ids)
	if err != nil {
		return savedRelationshipState{}, 0, err
	}
	saveCommand := saveditemapp.SaveCommand{
		OwnerUserID:               command.OwnerUserID,
		Projection:                command.Eligibility.Projection,
		SavedItemID:               savedItemID,
		StateGeneration:           stateGeneration,
		RelationshipAttributionID: attributionID,
		ActivatedOutboxEventID:    outboxEventID,
		ServerNow:                 command.ServerNow,
	}
	var activated savedRelationshipState
	if found {
		activated, err = reactivateSavedRelationship(ctx, tx, saveCommand)
	} else {
		activated, err = insertSavedRelationship(ctx, tx, saveCommand)
	}
	if err != nil {
		return savedRelationshipState{}, 0, mapSavedCollectionPGError(err)
	}
	usage, err = changeSavedUserUsage(ctx, tx, command.OwnerUserID, usage, 1, command.ServerNow)
	if err != nil {
		return savedRelationshipState{}, 0, mapSavedCollectionPGError(err)
	}
	if err := markSavedProjectionReferenced(
		ctx, tx, command.Desired.Target, command.ServerNow,
	); err != nil {
		return savedRelationshipState{}, 0, mapSavedCollectionPGError(err)
	}
	if err := insertSavedItemOutbox(
		ctx,
		tx,
		outboxEventID,
		command.OwnerUserID,
		command.Desired.Target,
		activated,
		"SAVED_ITEM_ACTIVATED",
		command.ServerNow,
	); err != nil {
		return savedRelationshipState{}, 0, mapSavedCollectionPGError(err)
	}
	return activated, usage.version, nil
}

func verifyExpectedSavedRelationship(
	desired savedcollectionapp.DesiredSet,
	current savedRelationshipState,
	found bool,
) error {
	if !found {
		if desired.ExpectedRelationship.State != savedcollectionapp.ExpectedRelationshipAbsent ||
			desired.ExpectedDependentMembershipVersion != 0 {
			return domain.ErrMutationStale
		}
		return nil
	}
	expectedState := domain.RelationshipState("")
	switch desired.ExpectedRelationship.State {
	case savedcollectionapp.ExpectedRelationshipActive:
		expectedState = domain.RelationshipStateActive
	case savedcollectionapp.ExpectedRelationshipRemoved:
		expectedState = domain.RelationshipStateRemoved
	default:
		return domain.ErrMutationStale
	}
	if current.state != expectedState ||
		current.stateGeneration != desired.ExpectedRelationship.Generation ||
		current.relationshipVersion != desired.ExpectedRelationship.Version ||
		current.dependentMembershipVersion != desired.ExpectedDependentMembershipVersion {
		return domain.ErrMutationStale
	}
	return nil
}

func relationshipSnapshot(
	state savedRelationshipState,
	found bool,
) savedcollectionapp.RelationshipSnapshot {
	if !found {
		return savedcollectionapp.RelationshipSnapshot{State: savedcollectionapp.RelationshipSnapshotAbsent}
	}
	snapshot := savedcollectionapp.RelationshipSnapshot{
		Generation: state.stateGeneration,
		Version:    state.relationshipVersion,
	}
	if state.state == domain.RelationshipStateActive {
		snapshot.State = savedcollectionapp.RelationshipSnapshotActive
	} else {
		snapshot.State = savedcollectionapp.RelationshipSnapshotRemoved
	}
	return snapshot
}

func classifyDesiredCollectionSet(
	current []uuid.UUID,
	desired []uuid.UUID,
	createsInline bool,
) savedcollectionapp.DesiredSetChange {
	currentSet := uuidSet(current)
	desiredSet := uuidSet(desired)
	removals, additions := collectionSetDifference(currentSet, desiredSet)
	additionCount := len(additions)
	if createsInline {
		additionCount++
	}
	switch {
	case len(removals) == 0 && additionCount == 0:
		return savedcollectionapp.DesiredSetNoOp
	case len(removals) > 0 && additionCount == 0:
		return savedcollectionapp.DesiredSetReduction
	case len(removals) == 0 && additionCount > 0:
		return savedcollectionapp.DesiredSetExpansion
	default:
		return savedcollectionapp.DesiredSetMixed
	}
}

func verifyDesiredCollectionsReadable(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	collectionIDs []uuid.UUID,
) error {
	if len(collectionIDs) == 0 {
		return nil
	}
	var count int64
	err := tx.QueryRow(ctx, `
SELECT count(*)
FROM saved_collections
WHERE owner_user_id = $1
  AND id::text = ANY($2::text[])
  AND lifecycle_state = 'ACTIVE'`, ownerUserID.String(), uuidTexts(collectionIDs)).Scan(&count)
	if err != nil {
		return mapSavedCollectionPGError(err)
	}
	if count != int64(len(collectionIDs)) {
		return domain.ErrCollectionNotFound
	}
	return nil
}

func uuidSet(values []uuid.UUID) map[uuid.UUID]struct{} {
	result := make(map[uuid.UUID]struct{}, len(values))
	for _, value := range values {
		result[value] = struct{}{}
	}
	return result
}

func collectionSetDifference(
	current map[uuid.UUID]struct{},
	desired map[uuid.UUID]struct{},
) ([]uuid.UUID, []uuid.UUID) {
	removals := make([]uuid.UUID, 0)
	additions := make([]uuid.UUID, 0)
	for value := range current {
		if _, remains := desired[value]; !remains {
			removals = append(removals, value)
		}
	}
	for value := range desired {
		if _, alreadyPresent := current[value]; !alreadyPresent {
			additions = append(additions, value)
		}
	}
	sortUUIDs(removals)
	sortUUIDs(additions)
	return removals, additions
}

func sortUUIDs(values []uuid.UUID) {
	sort.Slice(values, func(left, right int) bool {
		return values[left].String() < values[right].String()
	})
}

func applyCountDelta(value uint64, delta int) (uint64, bool) {
	if delta >= 0 {
		addition := uint64(delta)
		if value > math.MaxUint64-addition {
			return 0, false
		}
		return value + addition, true
	}
	subtraction := uint64(-delta)
	if subtraction > value {
		return 0, false
	}
	return value - subtraction, true
}

func stringPointer(value string) *string {
	copy := value
	return &copy
}

func (repository *PGSavedCollectionRepository) RejectPending(
	ctx context.Context,
	command savedcollectionapp.RejectPendingCommand,
) (*domain.SavedOperation, error) {
	if err := command.Validate(); err != nil {
		return nil, err
	}
	command.Identity.SemanticRequestHMAC = append([]byte(nil), command.Identity.SemanticRequestHMAC...)
	tx, err := repository.beginCollectionTx(ctx)
	if err != nil {
		return nil, err
	}
	defer rollbackCollectionTx(tx)
	receipt, err := lockSavedCollectionOperation(ctx, tx, command.Identity)
	if err != nil {
		return nil, err
	}
	if terminal, done, err := replayOrExpireSavedCollectionOperation(
		ctx, tx, receipt, command.Identity, command.ServerNow,
	); done || err != nil {
		return terminal, err
	}
	return rejectSavedCollectionOperation(
		ctx,
		tx,
		receipt,
		command.Identity,
		command.ServerNow,
		command.Cause,
		command.RefreshScope,
	)
}
