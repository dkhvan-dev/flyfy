package repository

import (
	"context"
	"errors"
	"math"
	"time"

	"github.com/jackc/pgx/v5"

	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const lockSavedItemOperationSQL = `
SELECT ` + operationColumns + `
FROM saved_operations
WHERE subject = $1
  AND session_generation = $2
  AND operation_id = $3
FOR UPDATE`

const getSavedItemOperationSQL = `
SELECT ` + operationColumns + `
FROM saved_operations
WHERE subject = $1
  AND session_generation = $2
  AND operation_id = $3`

const updateSavedItemOperationTerminalSQL = `
UPDATE saved_operations
SET status = $4,
    outcome_code = $5,
    outcome_retryable = $6,
    refresh_scope = $7,
    observed_relationship_version = $8,
    observed_dependent_membership_version = $9,
    observed_collection_metadata_version = $10,
    observed_collection_lifecycle_version = $11,
    applied_relationship_generation = $12,
    applied_relationship_version = $13,
    applied_user_usage_version = $14,
    applied_dependent_membership_version = $15,
    applied_collection_id = $16,
    applied_collection_metadata_version = $17,
    applied_collection_lifecycle_version = $18,
    completed_at = $19,
    retention_expires_at = $20
WHERE subject = $1
  AND session_generation = $2
  AND operation_id = $3
  AND status = 'PENDING'
  AND semantic_request_hmac = $21
  AND request_hmac_key_version = $22
  AND (
      ($4 = 'EXPIRED' AND commit_deadline <= $19)
      OR ($4 IN ('SUCCEEDED', 'REJECTED') AND commit_deadline > $19)
  )
RETURNING ` + operationColumns

func lockSavedItemOperation(
	ctx context.Context,
	tx pgx.Tx,
	identity saveditemapp.MutationIdentity,
) (*domain.SavedOperation, error) {
	receipt, err := scanOperation(tx.QueryRow(
		ctx,
		lockSavedItemOperationSQL,
		identity.SubjectID.String(),
		identity.SessionGeneration.String(),
		identity.OperationID.String(),
	))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, saveditemapp.ErrOperationNotFound
	}
	if err != nil {
		return nil, mapSavedItemPGError(err)
	}
	if !identity.Matches(receipt) {
		return nil, domain.ErrReplayMismatch
	}
	return receipt, nil
}

func finishSavedItemOperation(
	ctx context.Context,
	tx pgx.Tx,
	receipt *domain.SavedOperation,
	identity saveditemapp.MutationIdentity,
) (*domain.SavedOperation, error) {
	state := receipt.PersistenceState()
	if state.Status == domain.OperationStatusPending || state.CompletedAt == nil ||
		state.RetentionExpiresAt == nil {
		return nil, saveditemapp.ErrDataInvariant
	}

	outcomeCode := string(state.Outcome)
	retryable := false
	if state.Status == domain.OperationStatusRejected {
		if state.Failure == nil || !saveditemapp.IsPersistableRejection(&domain.DomainError{
			Code:      state.Failure.Code,
			Retryable: state.Failure.Retryable,
		}) {
			return nil, saveditemapp.ErrDataInvariant
		}
		outcomeCode = string(state.Failure.Code)
		retryable = state.Failure.Retryable
	}

	observedRelationship, err := savedItemNullableInt64(state.Versions.ObservedRelationshipVersion)
	if err != nil {
		return nil, err
	}
	observedDependent, err := savedItemNullableInt64(state.Versions.ObservedDependentMembershipVersion)
	if err != nil {
		return nil, err
	}
	observedMetadata, err := savedItemNullableInt64(state.Versions.ObservedCollectionMetadataVersion)
	if err != nil {
		return nil, err
	}
	observedLifecycle, err := savedItemNullableInt64(state.Versions.ObservedCollectionLifecycleVersion)
	if err != nil {
		return nil, err
	}
	appliedUsage, err := savedItemNullableInt64(state.Versions.AppliedUserUsageVersion)
	if err != nil {
		return nil, err
	}
	appliedDependent, err := savedItemNullableInt64(state.Versions.AppliedDependentMembershipVersion)
	if err != nil {
		return nil, err
	}

	var appliedGeneration any
	var appliedRelationshipVersion any
	if state.Versions.AppliedRelationship != nil {
		if state.Versions.AppliedRelationship.Version > math.MaxInt64 {
			return nil, saveditemapp.ErrDataInvariant
		}
		appliedGeneration = state.Versions.AppliedRelationship.Generation.String()
		appliedRelationshipVersion = int64(state.Versions.AppliedRelationship.Version)
	}

	var appliedCollectionID any
	var appliedCollectionMetadata any
	var appliedCollectionLifecycle any
	if state.Versions.AppliedCollection != nil {
		if state.Versions.AppliedCollection.MetadataVersion > math.MaxInt64 ||
			state.Versions.AppliedCollection.LifecycleVersion > math.MaxInt64 {
			return nil, saveditemapp.ErrDataInvariant
		}
		appliedCollectionID = state.Versions.AppliedCollection.CollectionID.String()
		appliedCollectionMetadata = int64(state.Versions.AppliedCollection.MetadataVersion)
		appliedCollectionLifecycle = int64(state.Versions.AppliedCollection.LifecycleVersion)
	}

	updated, err := scanOperation(tx.QueryRow(
		ctx,
		updateSavedItemOperationTerminalSQL,
		identity.SubjectID.String(),
		identity.SessionGeneration.String(),
		identity.OperationID.String(),
		string(state.Status),
		outcomeCode,
		retryable,
		string(state.RefreshScope),
		observedRelationship,
		observedDependent,
		observedMetadata,
		observedLifecycle,
		appliedGeneration,
		appliedRelationshipVersion,
		appliedUsage,
		appliedDependent,
		appliedCollectionID,
		appliedCollectionMetadata,
		appliedCollectionLifecycle,
		state.CompletedAt.UTC(),
		state.RetentionExpiresAt.UTC(),
		identity.SemanticRequestHMAC,
		int64(identity.RequestHMACKeyVersion),
	))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, domain.ErrMutationStale
	}
	if err != nil {
		return nil, mapSavedItemPGError(err)
	}
	return updated, nil
}

func expireSavedItemOperation(
	ctx context.Context,
	tx pgx.Tx,
	receipt *domain.SavedOperation,
	identity saveditemapp.MutationIdentity,
	serverNow time.Time,
) (*domain.SavedOperation, error) {
	if err := receipt.Expire(serverNow); err != nil {
		return nil, err
	}
	return finishSavedItemOperation(ctx, tx, receipt, identity)
}

func savedItemNullableInt64(value *uint64) (any, error) {
	if value == nil {
		return nil, nil
	}
	if *value > math.MaxInt64 {
		return nil, saveditemapp.ErrDataInvariant
	}
	return int64(*value), nil
}

func (r *PGSavedItemRepository) RejectPending(
	ctx context.Context,
	command saveditemapp.RejectPendingCommand,
) (*domain.SavedOperation, error) {
	if err := command.Validate(); err != nil {
		return nil, err
	}
	command.Identity.SemanticRequestHMAC = append([]byte(nil), command.Identity.SemanticRequestHMAC...)
	tx, err := r.begin(ctx)
	if err != nil {
		return nil, err
	}
	defer rollbackSavedItemTx(tx)

	receipt, err := lockSavedItemOperation(ctx, tx, command.Identity)
	if err != nil {
		return nil, err
	}
	if receipt.Status() != domain.OperationStatusPending {
		if err := commitSavedItemTx(ctx, tx); err != nil {
			return nil, err
		}
		return receipt, nil
	}
	if !command.ServerNow.Before(receipt.CommitDeadline()) {
		receipt, err = expireSavedItemOperation(ctx, tx, receipt, command.Identity, command.ServerNow)
	} else {
		if command.ServerNow.Before(receipt.CreatedAt()) {
			return nil, saveditemapp.ErrInvalidCommand
		}
		if err = receipt.Reject(command.ServerNow, command.Cause, command.RefreshScope); err == nil {
			receipt, err = finishSavedItemOperation(ctx, tx, receipt, command.Identity)
		}
	}
	if err != nil {
		return nil, err
	}
	if err := commitSavedItemTx(ctx, tx); err != nil {
		return nil, err
	}
	return receipt, nil
}

func (r *PGSavedItemRepository) GetOperation(
	ctx context.Context,
	lookup saveditemapp.OperationLookup,
) (*domain.SavedOperation, error) {
	if err := lookup.Validate(); err != nil {
		return nil, err
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	if r == nil || r.pool == nil {
		return nil, saveditemapp.ErrRepositoryUnavailable
	}
	receipt, err := scanOperation(r.pool.QueryRow(
		ctx,
		getSavedItemOperationSQL,
		lookup.SubjectID.String(),
		lookup.SessionGeneration.String(),
		lookup.OperationID.String(),
	))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, saveditemapp.ErrOperationNotFound
	}
	if err != nil {
		return nil, mapSavedItemPGError(err)
	}
	if receipt.Status() != domain.OperationStatusPending ||
		lookup.ServerNow.Before(receipt.CommitDeadline()) {
		return receipt, nil
	}

	identity := saveditemapp.MutationIdentity{
		SubjectID:             receipt.SubjectID(),
		SessionGeneration:     receipt.SessionGeneration(),
		OperationID:           receipt.OperationID(),
		Kind:                  receipt.Kind(),
		SemanticRequestHMAC:   receipt.SemanticRequestHMAC(),
		RequestHMACKeyVersion: receipt.RequestHMACKeyVersion(),
	}
	tx, err := r.begin(ctx)
	if err != nil {
		return nil, err
	}
	defer rollbackSavedItemTx(tx)

	receipt, err = lockSavedItemOperation(ctx, tx, identity)
	if err != nil {
		return nil, err
	}
	if receipt.Status() == domain.OperationStatusPending {
		receipt, err = expireSavedItemOperation(ctx, tx, receipt, identity, lookup.ServerNow)
		if err != nil {
			return nil, err
		}
	}
	if err := commitSavedItemTx(ctx, tx); err != nil {
		return nil, err
	}
	return receipt, nil
}
