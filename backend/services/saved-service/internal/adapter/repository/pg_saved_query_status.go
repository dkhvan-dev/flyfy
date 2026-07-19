package repository

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const savedTargetStatusesSQL = `
WITH requested(entity_type, entity_id, ordinal) AS (
    SELECT entity_type, entity_id, ordinal
    FROM unnest($2::text[], $3::text[]) WITH ORDINALITY
         AS input(entity_type, entity_id, ordinal)
)
SELECT requested.entity_type,
       requested.entity_id,
       saved_items.id::text,
       saved_items.relationship_state,
       saved_items.state_generation::text,
       saved_items.relationship_version,
       saved_items.dependent_membership_version,
       CASE
           WHEN projections.reconciliation_fail_closed_at IS NULL
           THEN projections.visibility_status
           ELSE 'UNAVAILABLE'
       END,
       COALESCE(effective_memberships.count, 0)::bigint
FROM requested
LEFT JOIN saved_items
  ON saved_items.owner_user_id = $1::uuid
 AND saved_items.entity_type = requested.entity_type
 AND saved_items.entity_id = requested.entity_id
LEFT JOIN saved_content_projections AS projections
  ON projections.entity_type = saved_items.entity_type
 AND projections.entity_id = saved_items.entity_id
LEFT JOIN LATERAL (
    SELECT count(*)::bigint AS count
    FROM saved_collection_items AS memberships
    JOIN saved_collections AS collections
      ON collections.owner_user_id = memberships.owner_user_id
     AND collections.id = memberships.collection_id
     AND collections.lifecycle_state = 'ACTIVE'
    WHERE saved_items.relationship_state = 'ACTIVE'
      AND memberships.owner_user_id = saved_items.owner_user_id
      AND memberships.saved_item_id = saved_items.id
      AND memberships.membership_state = 'ACTIVE'
) AS effective_memberships ON TRUE
ORDER BY requested.ordinal`

func (r *PGSavedQueryRepository) GetStatus(
	ctx context.Context,
	query savedqueryapp.StatusQuery,
) (savedqueryapp.TargetStatus, error) {
	if ctx == nil || r == nil || r.pool == nil {
		return savedqueryapp.TargetStatus{}, savedqueryapp.ErrRepositoryUnavailable
	}
	if err := query.Validate(); err != nil {
		return savedqueryapp.TargetStatus{}, err
	}
	statuses, err := r.getStatuses(ctx, r.pool, query.OwnerUserID, []domain.SavedTarget{query.Target})
	if err != nil {
		return savedqueryapp.TargetStatus{}, err
	}
	if len(statuses) != 1 {
		return savedqueryapp.TargetStatus{}, savedqueryapp.ErrDataInvariant
	}
	return statuses[0], nil
}

func (r *PGSavedQueryRepository) BatchStatus(
	ctx context.Context,
	query savedqueryapp.BatchStatusQuery,
) ([]savedqueryapp.TargetStatus, error) {
	if ctx == nil || r == nil || r.pool == nil {
		return nil, savedqueryapp.ErrRepositoryUnavailable
	}
	if err := query.Validate(); err != nil {
		return nil, err
	}
	return r.getStatuses(ctx, r.pool, query.OwnerUserID, query.Targets)
}

func (r *PGSavedQueryRepository) getStatuses(
	ctx context.Context,
	executor savedQueryExecutor,
	ownerUserID uuid.UUID,
	targets []domain.SavedTarget,
) ([]savedqueryapp.TargetStatus, error) {
	entityTypes := make([]string, len(targets))
	entityIDs := make([]string, len(targets))
	for index, target := range targets {
		entityTypes[index] = string(target.EntityType())
		entityIDs[index] = target.EntityID()
	}

	rows, err := executor.Query(ctx, savedTargetStatusesSQL, ownerUserID.String(), entityTypes, entityIDs)
	if err != nil {
		return nil, mapSavedQueryPGError(err)
	}
	defer rows.Close()

	statuses := make([]savedqueryapp.TargetStatus, 0, len(targets))
	for rows.Next() {
		status, err := scanSavedTargetStatus(rows)
		if err != nil {
			return nil, err
		}
		statuses = append(statuses, status)
	}
	if err := rows.Err(); err != nil {
		return nil, mapSavedQueryPGError(err)
	}
	if len(statuses) != len(targets) {
		return nil, savedqueryapp.ErrDataInvariant
	}
	return statuses, nil
}

func scanSavedTargetStatus(scanner savedQueryScanner) (savedqueryapp.TargetStatus, error) {
	var entityType string
	var entityID string
	var savedItemID pgtype.Text
	var relationshipState pgtype.Text
	var generationText pgtype.Text
	var relationshipVersion pgtype.Int8
	var membershipVersion pgtype.Int8
	var visibilityStatus pgtype.Text
	var effectiveCollectionCount int64
	if err := scanner.Scan(
		&entityType,
		&entityID,
		&savedItemID,
		&relationshipState,
		&generationText,
		&relationshipVersion,
		&membershipVersion,
		&visibilityStatus,
		&effectiveCollectionCount,
	); err != nil {
		return savedqueryapp.TargetStatus{}, mapSavedQueryPGError(err)
	}

	target, err := domain.NewSavedTarget(domain.EntityType(entityType), entityID)
	if err != nil {
		return savedqueryapp.TargetStatus{}, savedqueryapp.ErrDataInvariant
	}
	if !savedItemID.Valid {
		if relationshipState.Valid || generationText.Valid || relationshipVersion.Valid || membershipVersion.Valid ||
			visibilityStatus.Valid || effectiveCollectionCount != 0 {
			return savedqueryapp.TargetStatus{}, savedqueryapp.ErrDataInvariant
		}
		return savedqueryapp.TargetStatus{
			Target:      target,
			SavedState:  savedqueryapp.SavedStateUnknown,
			Eligibility: savedqueryapp.EligibilityUnknown,
		}, nil
	}
	if !relationshipState.Valid || !generationText.Valid || !relationshipVersion.Valid ||
		!membershipVersion.Valid || !visibilityStatus.Valid || relationshipVersion.Int64 <= 0 ||
		membershipVersion.Int64 < 0 || effectiveCollectionCount < 0 ||
		effectiveCollectionCount > savedqueryapp.MaxEffectiveCollectionCount {
		return savedqueryapp.TargetStatus{}, savedqueryapp.ErrDataInvariant
	}
	if _, err := uuid.Parse(savedItemID.String); err != nil {
		return savedqueryapp.TargetStatus{}, savedqueryapp.ErrDataInvariant
	}
	generation, err := uuid.Parse(generationText.String)
	if err != nil || generation == uuid.Nil {
		return savedqueryapp.TargetStatus{}, savedqueryapp.ErrDataInvariant
	}
	visibility := domain.VisibilityStatus(visibilityStatus.String)
	if !visibility.IsValid() || (visibility == domain.VisibilityPrivate && target.EntityType() != domain.EntityTypeActivity) {
		return savedqueryapp.TargetStatus{}, savedqueryapp.ErrDataInvariant
	}
	resourceVersion, err := savedqueryapp.ComposeResourceVersion(
		uint64(relationshipVersion.Int64),
		uint64(membershipVersion.Int64),
	)
	if err != nil {
		return savedqueryapp.TargetStatus{}, err
	}

	status := savedqueryapp.TargetStatus{
		Target:                   target,
		EffectiveCollectionCount: uint32(effectiveCollectionCount),
		ResourceVersion:          resourceVersion,
	}
	switch domain.RelationshipState(relationshipState.String) {
	case domain.RelationshipStateActive:
		status.SavedState = savedqueryapp.SavedStateSaved
		status.RelationshipGeneration = &generation
		if visibility == domain.VisibilityPublic {
			status.Eligibility = savedqueryapp.EligibilityEligible
		} else {
			status.Eligibility = savedqueryapp.EligibilityReductionOnly
		}
	case domain.RelationshipStateRemoved:
		if effectiveCollectionCount != 0 {
			return savedqueryapp.TargetStatus{}, savedqueryapp.ErrDataInvariant
		}
		status.SavedState = savedqueryapp.SavedStateConfirmedUnsaved
		switch visibility {
		case domain.VisibilityPublic:
			status.Eligibility = savedqueryapp.EligibilityEligible
		case domain.VisibilityUnknown:
			status.Eligibility = savedqueryapp.EligibilityUnknown
		default:
			status.Eligibility = savedqueryapp.EligibilityIneligible
		}
	default:
		return savedqueryapp.TargetStatus{}, savedqueryapp.ErrDataInvariant
	}
	return status, nil
}

func isSavedQueryNotFound(err error) bool {
	return errors.Is(err, pgx.ErrNoRows)
}
