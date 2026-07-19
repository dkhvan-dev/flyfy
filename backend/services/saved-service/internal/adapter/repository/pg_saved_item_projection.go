package repository

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"encoding/json"
	"errors"
	"math"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

var errSavedProjectionRevisionRollback = errors.New("saved projection revision rollback")

const lockSavedProjectionSQL = `
SELECT source_service,
       source_revision,
       projection_revision,
       visibility_revision,
       visibility_status,
       search_document_version,
       media_reference_revision,
       ever_referenced
FROM saved_content_projections
WHERE entity_type = $1
  AND entity_id = $2
FOR UPDATE`

const insertSavedProjectionSQL = `
INSERT INTO saved_content_projections (
    entity_type,
    entity_id,
    source_service,
    source_revision,
    projection_revision,
    visibility_revision,
    visibility_status,
    visibility_validated_at,
    source_default_locale,
    title_en,
    title_ru,
    title_kk,
    subtitle_en,
    subtitle_ru,
    subtitle_kk,
    city_en,
    city_ru,
    city_kk,
    country_en,
    country_ru,
    country_kk,
    display_location_en,
    display_location_ru,
    display_location_kk,
    search_document_version,
    normalized_search_document_en,
    normalized_search_document_ru,
    normalized_search_document_kk,
    media_reference,
    media_reference_revision,
    media_valid_until,
    rating_value,
    rating_count,
    rating_scale_max,
    price_summary,
    availability_summary,
    summary_as_of,
    summary_valid_until,
    canonical_detail_route,
    shell_expires_at,
    ever_referenced,
    gc_candidate_at,
    created_at,
    updated_at
) VALUES (
    $1, $2, $3, $4, $5, $6, 'PUBLIC', $7, $8,
    $9, $10, $11, $12, $13, $14, $15, $16, $17,
    $18, $19, $20, $21, $22, $23, $24, $25, $26, $27,
    $28, $29, $30, $31, $32, $33, $34::jsonb, $35::jsonb,
    $36, $37, $38, $39, FALSE, NULL, $40, $40
)
ON CONFLICT (entity_type, entity_id) DO NOTHING`

const updateSavedProjectionSQL = `
UPDATE saved_content_projections
SET source_revision = $3,
    projection_revision = $4,
    visibility_revision = $5,
    visibility_status = 'PUBLIC',
    visibility_validated_at = $6,
    source_default_locale = $7,
    title_en = $8,
    title_ru = $9,
    title_kk = $10,
    subtitle_en = $11,
    subtitle_ru = $12,
    subtitle_kk = $13,
    city_en = $14,
    city_ru = $15,
    city_kk = $16,
    country_en = $17,
    country_ru = $18,
    country_kk = $19,
    display_location_en = $20,
    display_location_ru = $21,
    display_location_kk = $22,
    search_document_version = $23,
    normalized_search_document_en = $24,
    normalized_search_document_ru = $25,
    normalized_search_document_kk = $26,
    media_reference = $27,
    media_reference_revision = $28,
    media_valid_until = $29,
    rating_value = $30,
    rating_count = $31,
    rating_scale_max = $32,
    price_summary = $33::jsonb,
    availability_summary = $34::jsonb,
    summary_as_of = $35,
    summary_valid_until = $36,
    canonical_detail_route = $37,
    updated_at = GREATEST(updated_at, $38)
WHERE entity_type = $1
  AND entity_id = $2`

const markSavedProjectionReferencedSQL = `
UPDATE saved_content_projections
SET ever_referenced = TRUE,
    shell_expires_at = NULL,
    gc_candidate_at = NULL,
    updated_at = GREATEST(updated_at, $3)
WHERE entity_type = $1
  AND entity_id = $2`

type savedProjectionState struct {
	sourceService          string
	sourceRevision         int64
	projectionRevision     int64
	visibilityRevision     int64
	visibilityStatus       string
	searchDocumentVersion  int64
	mediaReferenceRevision pgtype.Int8
	everReferenced         bool
}

func writeAuthoritativePublicProjection(
	ctx context.Context,
	tx pgx.Tx,
	snapshot saveditemapp.PublicProjectionSnapshot,
	serverNow time.Time,
) error {
	if _, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", savedProjectionLockKey(snapshot.Target)); err != nil {
		return mapSavedItemPGError(err)
	}

	state, found, err := lockSavedProjection(ctx, tx, snapshot.Target)
	if err != nil {
		return err
	}
	if !found {
		inserted, err := insertSavedProjection(ctx, tx, snapshot, serverNow)
		if err != nil {
			return err
		}
		if !inserted {
			state, found, err = lockSavedProjection(ctx, tx, snapshot.Target)
			if err != nil {
				return err
			}
			if !found {
				return saveditemapp.ErrDataInvariant
			}
		} else {
			state = savedProjectionState{
				sourceService:         snapshot.SourceService,
				sourceRevision:        int64(snapshot.SourceRevision),
				projectionRevision:    int64(snapshot.ProjectionRevision),
				visibilityRevision:    int64(snapshot.VisibilityRevision),
				visibilityStatus:      string(domain.VisibilityPublic),
				searchDocumentVersion: int64(snapshot.SearchDocumentVersion),
			}
		}
	}

	if state.sourceService != snapshot.SourceService ||
		uint64(state.sourceRevision) > snapshot.SourceRevision ||
		uint64(state.projectionRevision) > snapshot.ProjectionRevision ||
		uint64(state.visibilityRevision) > snapshot.VisibilityRevision ||
		uint64(state.searchDocumentVersion) > snapshot.SearchDocumentVersion ||
		(state.visibilityRevision == int64(snapshot.VisibilityRevision) &&
			state.visibilityStatus != string(domain.VisibilityPublic)) ||
		(state.mediaReferenceRevision.Valid && snapshot.Media != nil &&
			uint64(state.mediaReferenceRevision.Int64) > snapshot.Media.ReferenceRevision) ||
		(state.mediaReferenceRevision.Valid && snapshot.Media == nil &&
			state.projectionRevision == int64(snapshot.ProjectionRevision)) {
		return errSavedProjectionRevisionRollback
	}

	arguments, err := savedProjectionUpdateArguments(snapshot, serverNow)
	if err != nil {
		return err
	}
	tag, err := tx.Exec(ctx, updateSavedProjectionSQL, arguments...)
	if err != nil {
		return mapSavedItemPGError(err)
	}
	if tag.RowsAffected() != 1 {
		return saveditemapp.ErrDataInvariant
	}
	return nil
}

func lockSavedProjection(
	ctx context.Context,
	tx pgx.Tx,
	target domain.SavedTarget,
) (savedProjectionState, bool, error) {
	var state savedProjectionState
	err := tx.QueryRow(
		ctx,
		lockSavedProjectionSQL,
		string(target.EntityType()),
		target.EntityID(),
	).Scan(
		&state.sourceService,
		&state.sourceRevision,
		&state.projectionRevision,
		&state.visibilityRevision,
		&state.visibilityStatus,
		&state.searchDocumentVersion,
		&state.mediaReferenceRevision,
		&state.everReferenced,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return savedProjectionState{}, false, nil
	}
	if err != nil {
		return savedProjectionState{}, false, mapSavedItemPGError(err)
	}
	if state.sourceRevision < 0 || state.projectionRevision < 0 ||
		state.visibilityRevision < 0 || state.searchDocumentVersion < 0 ||
		(state.mediaReferenceRevision.Valid && state.mediaReferenceRevision.Int64 <= 0) {
		return savedProjectionState{}, false, saveditemapp.ErrDataInvariant
	}
	return state, true, nil
}

func insertSavedProjection(
	ctx context.Context,
	tx pgx.Tx,
	snapshot saveditemapp.PublicProjectionSnapshot,
	serverNow time.Time,
) (bool, error) {
	arguments, err := savedProjectionInsertArguments(snapshot, serverNow)
	if err != nil {
		return false, err
	}
	tag, err := tx.Exec(ctx, insertSavedProjectionSQL, arguments...)
	if err != nil {
		return false, mapSavedItemPGError(err)
	}
	return tag.RowsAffected() == 1, nil
}

func markSavedProjectionReferenced(
	ctx context.Context,
	tx pgx.Tx,
	target domain.SavedTarget,
	serverNow time.Time,
) error {
	tag, err := tx.Exec(
		ctx,
		markSavedProjectionReferencedSQL,
		string(target.EntityType()),
		target.EntityID(),
		serverNow.UTC(),
	)
	if err != nil {
		return mapSavedItemPGError(err)
	}
	if tag.RowsAffected() != 1 {
		return saveditemapp.ErrDataInvariant
	}
	return nil
}

func savedProjectionInsertArguments(
	snapshot saveditemapp.PublicProjectionSnapshot,
	serverNow time.Time,
) ([]any, error) {
	ratingValue, ratingCount, ratingScaleMax, err := savedProjectionRatingArguments(snapshot.Rating)
	if err != nil {
		return nil, err
	}
	priceSummary, err := encodeLocalizedSummary(snapshot.PriceSummary)
	if err != nil {
		return nil, err
	}
	availabilitySummary, err := encodeLocalizedSummary(snapshot.AvailabilitySummary)
	if err != nil {
		return nil, err
	}
	mediaReference, mediaRevision, mediaValidUntil := savedProjectionMediaArguments(snapshot.Media)
	return []any{
		string(snapshot.Target.EntityType()), snapshot.Target.EntityID(), snapshot.SourceService,
		int64(snapshot.SourceRevision), int64(snapshot.ProjectionRevision), int64(snapshot.VisibilityRevision),
		snapshot.VisibilityValidatedAt.UTC(), string(snapshot.SourceDefaultLocale),
		optionalText(snapshot.Title.EN), optionalText(snapshot.Title.RU), optionalText(snapshot.Title.KK),
		optionalText(snapshot.Subtitle.EN), optionalText(snapshot.Subtitle.RU), optionalText(snapshot.Subtitle.KK),
		optionalText(snapshot.City.EN), optionalText(snapshot.City.RU), optionalText(snapshot.City.KK),
		optionalText(snapshot.Country.EN), optionalText(snapshot.Country.RU), optionalText(snapshot.Country.KK),
		optionalText(snapshot.DisplayLocation.EN), optionalText(snapshot.DisplayLocation.RU), optionalText(snapshot.DisplayLocation.KK),
		int64(snapshot.SearchDocumentVersion),
		optionalText(snapshot.NormalizedSearchDocument.EN), optionalText(snapshot.NormalizedSearchDocument.RU), optionalText(snapshot.NormalizedSearchDocument.KK),
		mediaReference, mediaRevision, mediaValidUntil, ratingValue, ratingCount, ratingScaleMax,
		priceSummary, availabilitySummary,
		optionalTime(snapshot.AsOf), optionalTime(snapshot.ValidUntil),
		optionalText(snapshot.CanonicalDetailRoute), snapshot.ShellExpiresAt.UTC(), serverNow.UTC(),
	}, nil
}

func savedProjectionUpdateArguments(
	snapshot saveditemapp.PublicProjectionSnapshot,
	serverNow time.Time,
) ([]any, error) {
	ratingValue, ratingCount, ratingScaleMax, err := savedProjectionRatingArguments(snapshot.Rating)
	if err != nil {
		return nil, err
	}
	priceSummary, err := encodeLocalizedSummary(snapshot.PriceSummary)
	if err != nil {
		return nil, err
	}
	availabilitySummary, err := encodeLocalizedSummary(snapshot.AvailabilitySummary)
	if err != nil {
		return nil, err
	}
	mediaReference, mediaRevision, mediaValidUntil := savedProjectionMediaArguments(snapshot.Media)
	return []any{
		string(snapshot.Target.EntityType()), snapshot.Target.EntityID(),
		int64(snapshot.SourceRevision), int64(snapshot.ProjectionRevision), int64(snapshot.VisibilityRevision),
		snapshot.VisibilityValidatedAt.UTC(), string(snapshot.SourceDefaultLocale),
		optionalText(snapshot.Title.EN), optionalText(snapshot.Title.RU), optionalText(snapshot.Title.KK),
		optionalText(snapshot.Subtitle.EN), optionalText(snapshot.Subtitle.RU), optionalText(snapshot.Subtitle.KK),
		optionalText(snapshot.City.EN), optionalText(snapshot.City.RU), optionalText(snapshot.City.KK),
		optionalText(snapshot.Country.EN), optionalText(snapshot.Country.RU), optionalText(snapshot.Country.KK),
		optionalText(snapshot.DisplayLocation.EN), optionalText(snapshot.DisplayLocation.RU), optionalText(snapshot.DisplayLocation.KK),
		int64(snapshot.SearchDocumentVersion),
		optionalText(snapshot.NormalizedSearchDocument.EN), optionalText(snapshot.NormalizedSearchDocument.RU), optionalText(snapshot.NormalizedSearchDocument.KK),
		mediaReference, mediaRevision, mediaValidUntil, ratingValue, ratingCount, ratingScaleMax,
		priceSummary, availabilitySummary,
		optionalTime(snapshot.AsOf), optionalTime(snapshot.ValidUntil),
		optionalText(snapshot.CanonicalDetailRoute), serverNow.UTC(),
	}, nil
}

func savedProjectionRatingArguments(rating *saveditemapp.Rating) (any, any, any, error) {
	if rating == nil {
		return nil, nil, nil, nil
	}
	if rating.ReviewCount > math.MaxInt64 {
		return nil, nil, nil, saveditemapp.ErrInvalidCommand
	}
	return rating.Value, int64(rating.ReviewCount), rating.ScaleMax, nil
}

func optionalText(value *string) any {
	if value == nil {
		return nil
	}
	return *value
}

func savedProjectionMediaArguments(media *saveditemapp.MediaReference) (any, any, any) {
	if media == nil {
		return nil, nil, nil
	}
	return media.OpaqueReference, int64(media.ReferenceRevision), media.ValidUntil.UTC()
}

func encodeLocalizedSummary(value saveditemapp.LocalizedText) (any, error) {
	payload := struct {
		EN *string `json:"en,omitempty"`
		RU *string `json:"ru,omitempty"`
		KK *string `json:"kk,omitempty"`
	}{EN: value.EN, RU: value.RU, KK: value.KK}
	if payload.EN == nil && payload.RU == nil && payload.KK == nil {
		return nil, nil
	}
	encoded, err := json.Marshal(payload)
	if err != nil || len(encoded) > 16_384 {
		return nil, saveditemapp.ErrInvalidCommand
	}
	return string(encoded), nil
}

func optionalTime(value *time.Time) any {
	if value == nil {
		return nil
	}
	return value.UTC()
}

func savedProjectionLockKey(target domain.SavedTarget) int64 {
	digest := sha256.New()
	writeAdvisoryLockField(digest, []byte("saved-projection-v1"))
	writeAdvisoryLockField(digest, []byte(target.EntityType()))
	writeAdvisoryLockField(digest, []byte(target.EntityID()))
	sum := digest.Sum(nil)
	return int64(binary.BigEndian.Uint64(sum[:8]))
}
