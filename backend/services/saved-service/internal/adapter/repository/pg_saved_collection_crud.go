package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"

	savedcollectionapp "kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const insertSavedCollectionSQL = `
INSERT INTO saved_collections (
    id,
    owner_user_id,
    client_creation_id,
    title,
    normalized_title_key,
    lifecycle_state,
    lifecycle_version,
    metadata_version,
    items_version,
    active_item_count,
    created_at,
    organized_at,
    updated_at
) VALUES (
    $1, $2, $3, $4, $5, 'ACTIVE', 1, 1, 0, 0, $6, $6, $6
)`

const renameSavedCollectionSQL = `
UPDATE saved_collections
SET title = $3,
    normalized_title_key = $4,
    metadata_version = metadata_version + 1,
    organized_at = $5,
    updated_at = $5
WHERE owner_user_id = $1
  AND id = $2
  AND lifecycle_state = 'ACTIVE'
  AND metadata_version = $6
RETURNING metadata_version, lifecycle_version, organized_at, updated_at`

const deleteSavedCollectionSQL = `
UPDATE saved_collections
SET title = NULL,
    normalized_title_key = NULL,
    lifecycle_state = 'DELETED',
    lifecycle_version = lifecycle_version + 1,
    metadata_version = metadata_version + 1,
    active_item_count = 0,
    updated_at = $3,
    deleted_at = $3,
    purge_eligible_at = $3::timestamptz + INTERVAL '14 days'
WHERE owner_user_id = $1
  AND id = $2
  AND lifecycle_state = 'ACTIVE'
  AND metadata_version = $4
  AND lifecycle_version = $5
RETURNING metadata_version, lifecycle_version, updated_at, deleted_at`

func (repository *PGSavedCollectionRepository) Create(
	ctx context.Context,
	command savedcollectionapp.CreateCommand,
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
	if err := command.Validate(receipt.CommitDeadline()); err != nil {
		if errors.Is(err, domain.ErrCollectionTitleInvalid) {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionTitleInvalid, domain.RefreshScopeNone,
			)
		}
		return nil, err
	}
	if err := lockSavedCollectionOwner(ctx, tx, command.OwnerUserID); err != nil {
		return nil, err
	}
	title, err := savedcollectionapp.NormalizeStoredTitle(command.Title)
	if err != nil {
		return rejectSavedCollectionOperation(
			ctx, tx, receipt, command.Identity, command.ServerNow,
			domain.ErrCollectionTitleInvalid, domain.RefreshScopeNone,
		)
	}
	existing, found, err := lockSavedCollectionByClientCreationID(
		ctx, tx, command.OwnerUserID, command.ClientCreationID,
	)
	if err != nil {
		return nil, err
	}
	usage, err := ensureAndLockSavedCollectionUsage(ctx, tx, command.OwnerUserID, command.ServerNow)
	if err != nil {
		return nil, err
	}
	if found {
		if usage.activeCollections == 0 {
			return nil, savedcollectionapp.ErrDataInvariant
		}
		if existing.lifecycle != savedcollectionapp.CollectionLifecycleActive {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionNotFound, domain.RefreshScopeNone,
			)
		}
		if existing.title == nil || existing.normalizedTitle == nil ||
			*existing.title != title.Display || *existing.normalizedTitle != title.Key {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrReplayMismatch, domain.RefreshScopeNone,
			)
		}
		return succeedSavedCollectionOperation(
			ctx,
			tx,
			receipt,
			command.Identity,
			command.ServerNow,
			domain.OperationOutcomeNoOp,
			domain.RefreshScopeCollections,
			domain.OperationVersionEffects{
				AppliedCollection: appliedCollectionVersion(existing),
			},
		)
	}

	if usage.activeCollections >= repository.limits.MaxActiveCollections {
		return rejectSavedCollectionOperation(
			ctx, tx, receipt, command.Identity, command.ServerNow,
			domain.ErrCollectionLimitReached, domain.RefreshScopeNone,
		)
	}
	conflict, err := activeSavedCollectionTitleConflict(
		ctx, tx, command.OwnerUserID, title.Key, nil,
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
	collectionID, err := newSavedCollectionUUID(repository.ids)
	if err != nil {
		return nil, err
	}
	tag, err := tx.Exec(
		ctx,
		insertSavedCollectionSQL,
		collectionID.String(),
		command.OwnerUserID.String(),
		command.ClientCreationID.String(),
		title.Display,
		title.Key,
		command.ServerNow.UTC(),
	)
	if err != nil {
		mapped := mapSavedCollectionPGError(err)
		if errors.Is(mapped, domain.ErrCollectionTitleConflict) {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionTitleConflict, domain.RefreshScopeNone,
			)
		}
		return nil, mapped
	}
	if tag.RowsAffected() != 1 {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	usage, err = changeSavedCollectionUsage(
		ctx, tx, command.OwnerUserID, usage, 1, 0, command.ServerNow,
	)
	if err != nil {
		return nil, err
	}
	_ = usage
	return succeedSavedCollectionOperation(
		ctx,
		tx,
		receipt,
		command.Identity,
		command.ServerNow,
		domain.OperationOutcomeApplied,
		domain.RefreshScopeCollections,
		domain.OperationVersionEffects{
			AppliedCollection: &domain.AppliedCollectionVersion{
				CollectionID:     collectionID,
				MetadataVersion:  1,
				LifecycleVersion: 1,
			},
		},
	)
}

func (repository *PGSavedCollectionRepository) Rename(
	ctx context.Context,
	command savedcollectionapp.RenameCommand,
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
	if err := command.Validate(receipt.CommitDeadline()); err != nil {
		if errors.Is(err, domain.ErrCollectionTitleInvalid) {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionTitleInvalid, domain.RefreshScopeNone,
			)
		}
		return nil, err
	}
	if err := lockSavedCollectionOwner(ctx, tx, command.OwnerUserID); err != nil {
		return nil, err
	}
	collection, found, err := lockSavedCollectionByID(ctx, tx, command.OwnerUserID, command.CollectionID)
	if err != nil {
		return nil, err
	}
	if !found || collection.lifecycle != savedcollectionapp.CollectionLifecycleActive {
		return rejectSavedCollectionOperation(
			ctx, tx, receipt, command.Identity, command.ServerNow,
			domain.ErrCollectionNotFound, domain.RefreshScopeNone,
		)
	}
	if command.ServerNow.Before(collection.updatedAt) || command.ServerNow.Before(collection.organizedAt) {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	if collection.metadataVersion != command.ExpectedMetadataVersion {
		return rejectSavedCollectionOperation(
			ctx, tx, receipt, command.Identity, command.ServerNow,
			domain.ErrMutationStale, domain.RefreshScopeNone,
		)
	}
	title, err := savedcollectionapp.NormalizeStoredTitle(command.Title)
	if err != nil {
		return rejectSavedCollectionOperation(
			ctx, tx, receipt, command.Identity, command.ServerNow,
			domain.ErrCollectionTitleInvalid, domain.RefreshScopeNone,
		)
	}
	if collection.title == nil || collection.normalizedTitle == nil {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	observedMetadata := collection.metadataVersion
	if *collection.title == title.Display && *collection.normalizedTitle == title.Key {
		return succeedSavedCollectionOperation(
			ctx, tx, receipt, command.Identity, command.ServerNow,
			domain.OperationOutcomeNoOp, domain.RefreshScopeCollections,
			domain.OperationVersionEffects{
				ObservedCollectionMetadataVersion: &observedMetadata,
				AppliedCollection:                 appliedCollectionVersion(collection),
			},
		)
	}
	conflict, err := activeSavedCollectionTitleConflict(
		ctx, tx, command.OwnerUserID, title.Key, &command.CollectionID,
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
	var metadataVersion int64
	var lifecycleVersion int64
	var organizedAt time.Time
	var updatedAt time.Time
	err = tx.QueryRow(
		ctx,
		renameSavedCollectionSQL,
		command.OwnerUserID.String(),
		command.CollectionID.String(),
		title.Display,
		title.Key,
		command.ServerNow.UTC(),
		int64(command.ExpectedMetadataVersion),
	).Scan(&metadataVersion, &lifecycleVersion, &organizedAt, &updatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, domain.ErrMutationStale
	}
	if err != nil {
		mapped := mapSavedCollectionPGError(err)
		if errors.Is(mapped, domain.ErrCollectionTitleConflict) {
			return rejectSavedCollectionOperation(
				ctx, tx, receipt, command.Identity, command.ServerNow,
				domain.ErrCollectionTitleConflict, domain.RefreshScopeNone,
			)
		}
		return nil, mapped
	}
	if metadataVersion != int64(collection.metadataVersion)+1 ||
		lifecycleVersion != int64(collection.lifecycleVersion) ||
		!organizedAt.Equal(command.ServerNow) || !updatedAt.Equal(command.ServerNow) {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	return succeedSavedCollectionOperation(
		ctx, tx, receipt, command.Identity, command.ServerNow,
		domain.OperationOutcomeApplied, domain.RefreshScopeCollections,
		domain.OperationVersionEffects{
			ObservedCollectionMetadataVersion: &observedMetadata,
			AppliedCollection: &domain.AppliedCollectionVersion{
				CollectionID:     collection.id,
				MetadataVersion:  uint64(metadataVersion),
				LifecycleVersion: uint64(lifecycleVersion),
			},
		},
	)
}

func (repository *PGSavedCollectionRepository) Delete(
	ctx context.Context,
	command savedcollectionapp.DeleteCommand,
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
	if err := command.Validate(receipt.CommitDeadline()); err != nil {
		return nil, err
	}
	if err := lockSavedCollectionOwner(ctx, tx, command.OwnerUserID); err != nil {
		return nil, err
	}
	collection, found, err := lockSavedCollectionByID(ctx, tx, command.OwnerUserID, command.CollectionID)
	if err != nil {
		return nil, err
	}
	if !found || collection.lifecycle != savedcollectionapp.CollectionLifecycleActive {
		return rejectSavedCollectionOperation(
			ctx, tx, receipt, command.Identity, command.ServerNow,
			domain.ErrCollectionNotFound, domain.RefreshScopeNone,
		)
	}
	if command.ServerNow.Before(collection.updatedAt) {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	if collection.metadataVersion != command.ExpectedMetadataVersion ||
		collection.lifecycleVersion != command.ExpectedLifecycleVersion {
		return rejectSavedCollectionOperation(
			ctx, tx, receipt, command.Identity, command.ServerNow,
			domain.ErrMutationStale, domain.RefreshScopeNone,
		)
	}
	usage, found, err := lockExistingSavedCollectionUsage(ctx, tx, command.OwnerUserID)
	if err != nil {
		return nil, err
	}
	if !found || usage.activeCollections == 0 || collection.activeItemCount > usage.activeMemberships {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	var metadataVersion int64
	var lifecycleVersion int64
	var updatedAt time.Time
	var deletedAt time.Time
	err = tx.QueryRow(
		ctx,
		deleteSavedCollectionSQL,
		command.OwnerUserID.String(),
		command.CollectionID.String(),
		command.ServerNow.UTC(),
		int64(command.ExpectedMetadataVersion),
		int64(command.ExpectedLifecycleVersion),
	).Scan(&metadataVersion, &lifecycleVersion, &updatedAt, &deletedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, domain.ErrMutationStale
	}
	if err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	if metadataVersion != int64(collection.metadataVersion)+1 ||
		lifecycleVersion != int64(collection.lifecycleVersion)+1 ||
		!updatedAt.Equal(command.ServerNow) || !deletedAt.Equal(command.ServerNow) {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	usage, err = changeSavedCollectionUsage(
		ctx,
		tx,
		command.OwnerUserID,
		usage,
		-1,
		-int64(collection.activeItemCount),
		command.ServerNow,
	)
	if err != nil {
		return nil, err
	}
	_ = usage
	observedMetadata := collection.metadataVersion
	observedLifecycle := collection.lifecycleVersion
	return succeedSavedCollectionOperation(
		ctx, tx, receipt, command.Identity, command.ServerNow,
		domain.OperationOutcomeApplied, domain.RefreshScopeBoth,
		domain.OperationVersionEffects{
			ObservedCollectionMetadataVersion:  &observedMetadata,
			ObservedCollectionLifecycleVersion: &observedLifecycle,
			AppliedCollection: &domain.AppliedCollectionVersion{
				CollectionID:     collection.id,
				MetadataVersion:  uint64(metadataVersion),
				LifecycleVersion: uint64(lifecycleVersion),
			},
		},
	)
}

func succeedSavedCollectionOperation(
	ctx context.Context,
	tx pgx.Tx,
	receipt *domain.SavedOperation,
	identity savedcollectionapp.MutationIdentity,
	serverNow time.Time,
	outcome domain.OperationOutcome,
	refreshScope domain.RefreshScope,
	versions domain.OperationVersionEffects,
) (*domain.SavedOperation, error) {
	if err := receipt.Succeed(serverNow, outcome, refreshScope, versions); err != nil {
		return nil, err
	}
	terminal, err := finishSavedCollectionOperation(ctx, tx, receipt, identity)
	if err != nil {
		return nil, err
	}
	if err := commitCollectionTx(ctx, tx); err != nil {
		return nil, err
	}
	return terminal, nil
}

func appliedCollectionVersion(state savedCollectionState) *domain.AppliedCollectionVersion {
	return &domain.AppliedCollectionVersion{
		CollectionID:     state.id,
		MetadataVersion:  state.metadataVersion,
		LifecycleVersion: state.lifecycleVersion,
	}
}
