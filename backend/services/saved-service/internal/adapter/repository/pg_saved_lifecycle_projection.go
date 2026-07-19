package repository

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5"

	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const updateSavedLifecycleSourceRevisionSQL = `
UPDATE saved_content_projections
SET source_revision = $3,
    updated_at = GREATEST(updated_at, $4),
    reconciliation_next_attempt_at = NULL,
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL
WHERE entity_type = $1
  AND entity_id = $2`

const applySavedLifecyclePublicProjectionSQL = `
UPDATE saved_content_projections
SET projection_revision = @projection_revision,
    visibility_revision = @visibility_revision,
    visibility_status = 'PUBLIC',
    visibility_validated_at = @visibility_validated_at,
    source_default_locale = @source_default_locale,
    title_en = @title_en,
    title_ru = @title_ru,
    title_kk = @title_kk,
    subtitle_en = @subtitle_en,
    subtitle_ru = @subtitle_ru,
    subtitle_kk = @subtitle_kk,
    city_en = @city_en,
    city_ru = @city_ru,
    city_kk = @city_kk,
    country_en = @country_en,
    country_ru = @country_ru,
    country_kk = @country_kk,
    display_location_en = @display_location_en,
    display_location_ru = @display_location_ru,
    display_location_kk = @display_location_kk,
    search_document_version = @projection_revision,
    normalized_search_document_en = @search_document_en,
    normalized_search_document_ru = @search_document_ru,
    normalized_search_document_kk = @search_document_kk,
    media_reference = @media_reference,
    media_reference_revision = @media_reference_revision,
    media_valid_until = @media_valid_until,
    rating_value = @rating_value,
    rating_count = @rating_count,
    rating_scale_max = @rating_scale_max,
    price_summary = CAST(@price_summary AS JSONB),
    availability_summary = CAST(@availability_summary AS JSONB),
    summary_as_of = @summary_as_of,
    summary_valid_until = @summary_valid_until,
    canonical_detail_route = @canonical_detail_route,
    updated_at = GREATEST(updated_at, @processed_at),
    reconciliation_fail_closed_at = NULL,
    reconciliation_fail_closed_reason = NULL,
    reconciliation_next_attempt_at = NULL,
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL
WHERE entity_type = @entity_type
  AND entity_id = @entity_id`

const applySavedLifecyclePublicVisibilitySQL = `
UPDATE saved_content_projections
SET visibility_revision = $3,
    visibility_status = 'PUBLIC',
    visibility_validated_at = $4,
    updated_at = GREATEST(updated_at, $5),
    reconciliation_next_attempt_at = NULL,
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL
WHERE entity_type = $1
  AND entity_id = $2
  AND visibility_status = 'PUBLIC'`

const applySavedLifecycleDenySQL = `
UPDATE saved_content_projections
SET projection_revision = $3,
    visibility_revision = $4,
    visibility_status = $5,
    visibility_validated_at = $6,
    source_default_locale = NULL,
    title_en = NULL,
    title_ru = NULL,
    title_kk = NULL,
    subtitle_en = NULL,
    subtitle_ru = NULL,
    subtitle_kk = NULL,
    city_en = NULL,
    city_ru = NULL,
    city_kk = NULL,
    country_en = NULL,
    country_ru = NULL,
    country_kk = NULL,
    display_location_en = NULL,
    display_location_ru = NULL,
    display_location_kk = NULL,
    search_document_version = $3,
    normalized_search_document_en = NULL,
    normalized_search_document_ru = NULL,
    normalized_search_document_kk = NULL,
    media_reference = NULL,
    media_reference_revision = NULL,
    media_valid_until = NULL,
    rating_value = NULL,
    rating_count = NULL,
    rating_scale_max = NULL,
    price_summary = NULL,
    availability_summary = NULL,
    summary_as_of = NULL,
    summary_valid_until = NULL,
    canonical_detail_route = NULL,
    updated_at = GREATEST(updated_at, $7),
    reconciliation_fail_closed_at = NULL,
    reconciliation_fail_closed_reason = NULL,
    reconciliation_next_attempt_at = NULL,
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL
WHERE entity_type = $1
  AND entity_id = $2`

const applySavedLifecycleDenyProjectionRevisionSQL = `
UPDATE saved_content_projections
SET projection_revision = $3,
    search_document_version = $3,
    updated_at = GREATEST(updated_at, $4),
    reconciliation_fail_closed_at = NULL,
    reconciliation_fail_closed_reason = NULL,
    reconciliation_next_attempt_at = NULL,
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL
WHERE entity_type = $1
  AND entity_id = $2
  AND visibility_status <> 'PUBLIC'`

type savedLifecycleDecision struct {
	sourceApplied         bool
	projectionApplied     bool
	visibilityApplied     bool
	projectionRevision    uint64
	visibilityRevision    uint64
	visibility            domain.VisibilityStatus
	visibilityValidatedAt time.Time
}

func decideSavedLifecycleProjection(
	event savedlifecycle.Event,
	state savedLifecycleProjectionState,
) (savedLifecycleDecision, error) {
	decision := savedLifecycleDecision{
		sourceApplied:         event.Revisions.Source > state.sourceRevision,
		projectionRevision:    state.projectionRevision,
		visibilityRevision:    state.visibilityRevision,
		visibility:            state.visibility,
		visibilityValidatedAt: state.visibilityValidatedAt,
	}

	if event.Revisions.Visibility == state.visibilityRevision && event.Visibility != state.visibility {
		return savedLifecycleDecision{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeRevisionConflict,
		)
	}

	if event.Revisions.Visibility > state.visibilityRevision {
		switch event.Visibility {
		case domain.VisibilityPublic:
			canRestoreWithPayload := event.PublicProjection != nil &&
				event.Revisions.Projection >= state.projectionRevision
			if state.visibility == domain.VisibilityPublic || canRestoreWithPayload {
				decision.visibilityApplied = true
			}
		default:
			decision.visibilityApplied = true
		}
	}
	if decision.visibilityApplied {
		decision.visibilityRevision = event.Revisions.Visibility
		decision.visibility = event.Visibility
		decision.visibilityValidatedAt = event.OccurredAt.UTC()
	}

	if event.Visibility == domain.VisibilityPublic {
		// A visibility-only deny purges bytes without advancing the projection
		// revision, so a newer PUBLIC visibility may rehydrate that same revision.
		restoresPurgedPayload := decision.visibilityApplied &&
			(state.failClosed || state.visibility != domain.VisibilityPublic) &&
			event.Revisions.Projection == state.projectionRevision
		canApplyPayload := event.PublicProjection != nil &&
			event.Revisions.Visibility >= state.visibilityRevision &&
			decision.visibility == domain.VisibilityPublic &&
			(event.Revisions.Projection > state.projectionRevision || restoresPurgedPayload)
		if canApplyPayload {
			decision.projectionApplied = true
			decision.projectionRevision = event.Revisions.Projection
			if event.OccurredAt.After(decision.visibilityValidatedAt) {
				decision.visibilityValidatedAt = event.OccurredAt.UTC()
			}
		}
	} else if decision.visibility != domain.VisibilityPublic &&
		event.Revisions.Projection > state.projectionRevision {
		decision.projectionApplied = true
		decision.projectionRevision = event.Revisions.Projection
	}

	return decision, nil
}

func (d savedLifecycleDecision) outcome(
	event savedlifecycle.Event,
	state savedLifecycleProjectionState,
) savedlifecycle.Outcome {
	outcome := savedlifecycle.Outcome{
		SourceApplied:     d.sourceApplied,
		ProjectionApplied: d.projectionApplied,
		VisibilityApplied: d.visibilityApplied,
	}
	switch {
	case d.projectionApplied || d.visibilityApplied:
		outcome.Code = savedlifecycle.OutcomeApplied
	case d.sourceApplied:
		outcome.Code = savedlifecycle.OutcomeAppliedSourceOnly
	case event.Visibility == domain.VisibilityPublic &&
		event.PublicProjection == nil && state.visibility != domain.VisibilityPublic:
		outcome.Code = savedlifecycle.OutcomeIgnoredPublicPayloadAbsent
	default:
		outcome.Code = savedlifecycle.OutcomeIgnoredStaleRevision
	}
	return outcome
}

func applySavedLifecycleDecision(
	ctx context.Context,
	tx pgx.Tx,
	event savedlifecycle.Event,
	state savedLifecycleProjectionState,
	decision savedLifecycleDecision,
	processedAt time.Time,
) error {
	if decision.sourceApplied {
		if err := execSavedLifecycleUpdate(
			ctx,
			tx,
			updateSavedLifecycleSourceRevisionSQL,
			string(event.Target.EntityType()),
			event.Target.EntityID(),
			int64(event.Revisions.Source),
			processedAt.UTC(),
		); err != nil {
			return err
		}
	}

	switch {
	case decision.visibilityApplied && decision.visibility != domain.VisibilityPublic:
		return execSavedLifecycleUpdate(
			ctx,
			tx,
			applySavedLifecycleDenySQL,
			string(event.Target.EntityType()),
			event.Target.EntityID(),
			int64(decision.projectionRevision),
			int64(decision.visibilityRevision),
			string(decision.visibility),
			decision.visibilityValidatedAt.UTC(),
			processedAt.UTC(),
		)
	case decision.projectionApplied && decision.visibility == domain.VisibilityPublic:
		arguments, err := savedLifecyclePublicProjectionArguments(event, decision, processedAt)
		if err != nil {
			return err
		}
		return execSavedLifecycleNamedUpdate(ctx, tx, applySavedLifecyclePublicProjectionSQL, arguments)
	case decision.visibilityApplied:
		return execSavedLifecycleUpdate(
			ctx,
			tx,
			applySavedLifecyclePublicVisibilitySQL,
			string(event.Target.EntityType()),
			event.Target.EntityID(),
			int64(decision.visibilityRevision),
			decision.visibilityValidatedAt.UTC(),
			processedAt.UTC(),
		)
	case decision.projectionApplied:
		return execSavedLifecycleUpdate(
			ctx,
			tx,
			applySavedLifecycleDenyProjectionRevisionSQL,
			string(event.Target.EntityType()),
			event.Target.EntityID(),
			int64(decision.projectionRevision),
			processedAt.UTC(),
		)
	default:
		_ = state
		return nil
	}
}

func execSavedLifecycleUpdate(
	ctx context.Context,
	tx pgx.Tx,
	query string,
	arguments ...any,
) error {
	tag, err := tx.Exec(ctx, query, arguments...)
	if err != nil {
		return mapSavedLifecyclePGError(err)
	}
	if tag.RowsAffected() != 1 {
		return savedlifecycle.NewPermanentError(savedlifecycle.ErrorCodePersistenceInvariant)
	}
	return nil
}

func execSavedLifecycleNamedUpdate(
	ctx context.Context,
	tx pgx.Tx,
	query string,
	arguments pgx.NamedArgs,
) error {
	tag, err := tx.Exec(ctx, query, arguments)
	if err != nil {
		return mapSavedLifecyclePGError(err)
	}
	if tag.RowsAffected() != 1 {
		return savedlifecycle.NewPermanentError(savedlifecycle.ErrorCodePersistenceInvariant)
	}
	return nil
}

func savedLifecyclePublicProjectionArguments(
	event savedlifecycle.Event,
	decision savedLifecycleDecision,
	processedAt time.Time,
) (pgx.NamedArgs, error) {
	projection := event.PublicProjection
	if projection == nil || decision.visibility != domain.VisibilityPublic ||
		decision.visibilityValidatedAt.IsZero() {
		return nil, savedlifecycle.NewPermanentError(savedlifecycle.ErrorCodePersistenceInvariant)
	}

	priceSummary, err := encodeSavedLifecycleSummary(projection.Localized, true)
	if err != nil {
		return nil, err
	}
	availabilitySummary, err := encodeSavedLifecycleSummary(projection.Localized, false)
	if err != nil {
		return nil, err
	}

	arguments := pgx.NamedArgs{
		"entity_type":             string(event.Target.EntityType()),
		"entity_id":               event.Target.EntityID(),
		"projection_revision":     int64(decision.projectionRevision),
		"visibility_revision":     int64(decision.visibilityRevision),
		"visibility_validated_at": decision.visibilityValidatedAt.UTC(),
		"source_default_locale":   string(projection.SourceDefaultLocale),
		"title_en":                localizedSavedLifecycleField(projection.Localized.EN, func(v *savedlifecycle.LocalizedProjection) string { return v.Title }),
		"title_ru":                localizedSavedLifecycleField(projection.Localized.RU, func(v *savedlifecycle.LocalizedProjection) string { return v.Title }),
		"title_kk":                localizedSavedLifecycleField(projection.Localized.KK, func(v *savedlifecycle.LocalizedProjection) string { return v.Title }),
		"subtitle_en":             localizedSavedLifecycleField(projection.Localized.EN, func(v *savedlifecycle.LocalizedProjection) string { return v.Subtitle }),
		"subtitle_ru":             localizedSavedLifecycleField(projection.Localized.RU, func(v *savedlifecycle.LocalizedProjection) string { return v.Subtitle }),
		"subtitle_kk":             localizedSavedLifecycleField(projection.Localized.KK, func(v *savedlifecycle.LocalizedProjection) string { return v.Subtitle }),
		"city_en":                 localizedSavedLifecycleField(projection.Localized.EN, func(v *savedlifecycle.LocalizedProjection) string { return v.City }),
		"city_ru":                 localizedSavedLifecycleField(projection.Localized.RU, func(v *savedlifecycle.LocalizedProjection) string { return v.City }),
		"city_kk":                 localizedSavedLifecycleField(projection.Localized.KK, func(v *savedlifecycle.LocalizedProjection) string { return v.City }),
		"country_en":              localizedSavedLifecycleField(projection.Localized.EN, func(v *savedlifecycle.LocalizedProjection) string { return v.Country }),
		"country_ru":              localizedSavedLifecycleField(projection.Localized.RU, func(v *savedlifecycle.LocalizedProjection) string { return v.Country }),
		"country_kk":              localizedSavedLifecycleField(projection.Localized.KK, func(v *savedlifecycle.LocalizedProjection) string { return v.Country }),
		"display_location_en":     localizedSavedLifecycleField(projection.Localized.EN, func(v *savedlifecycle.LocalizedProjection) string { return v.DisplayLocation }),
		"display_location_ru":     localizedSavedLifecycleField(projection.Localized.RU, func(v *savedlifecycle.LocalizedProjection) string { return v.DisplayLocation }),
		"display_location_kk":     localizedSavedLifecycleField(projection.Localized.KK, func(v *savedlifecycle.LocalizedProjection) string { return v.DisplayLocation }),
		"search_document_en":      optionalSavedLifecycleText(projection.SearchDocument(savedlifecycle.LocaleEN)),
		"search_document_ru":      optionalSavedLifecycleText(projection.SearchDocument(savedlifecycle.LocaleRU)),
		"search_document_kk":      optionalSavedLifecycleText(projection.SearchDocument(savedlifecycle.LocaleKK)),
		"price_summary":           priceSummary,
		"availability_summary":    availabilitySummary,
		"summary_as_of":           optionalSavedLifecycleTime(projection.AsOf),
		"summary_valid_until":     optionalSavedLifecycleTime(projection.ValidUntil),
		"canonical_detail_route":  projection.CanonicalDetailRoute,
		"processed_at":            processedAt.UTC(),
	}

	if projection.Rating != nil {
		arguments["rating_value"] = projection.Rating.Value
		arguments["rating_count"] = int64(projection.Rating.ReviewCount)
		arguments["rating_scale_max"] = projection.Rating.ScaleMax
	} else {
		arguments["rating_value"] = nil
		arguments["rating_count"] = nil
		arguments["rating_scale_max"] = nil
	}
	if projection.Media != nil &&
		projection.Media.ValidUntil.After(processedAt.UTC()) &&
		projection.Media.ValidUntil.After(decision.visibilityValidatedAt) &&
		!projection.Media.ValidUntil.After(decision.visibilityValidatedAt.Add(15*time.Minute)) {
		arguments["media_reference"] = projection.Media.OpaqueReference
		arguments["media_reference_revision"] = int64(projection.Media.ReferenceRevision)
		arguments["media_valid_until"] = projection.Media.ValidUntil.UTC()
	} else {
		arguments["media_reference"] = nil
		arguments["media_reference_revision"] = nil
		arguments["media_valid_until"] = nil
	}
	return arguments, nil
}

func localizedSavedLifecycleField(
	localized *savedlifecycle.LocalizedProjection,
	selectValue func(*savedlifecycle.LocalizedProjection) string,
) any {
	if localized == nil {
		return nil
	}
	value := selectValue(localized)
	if value == "" {
		return nil
	}
	return value
}

func optionalSavedLifecycleText(value *string) any {
	if value == nil || *value == "" {
		return nil
	}
	return *value
}

func optionalSavedLifecycleTime(value *time.Time) any {
	if value == nil {
		return nil
	}
	return value.UTC()
}

func encodeSavedLifecycleSummary(
	localized savedlifecycle.LocalizedProjections,
	price bool,
) (any, error) {
	selectValue := func(value *savedlifecycle.LocalizedProjection) string {
		if price {
			return value.PriceSummary
		}
		return value.AvailabilitySummary
	}
	payload := struct {
		EN *string `json:"en,omitempty"`
		RU *string `json:"ru,omitempty"`
		KK *string `json:"kk,omitempty"`
	}{
		EN: savedLifecycleSummaryValue(localized.EN, selectValue),
		RU: savedLifecycleSummaryValue(localized.RU, selectValue),
		KK: savedLifecycleSummaryValue(localized.KK, selectValue),
	}
	if payload.EN == nil && payload.RU == nil && payload.KK == nil {
		return nil, nil
	}
	encoded, err := json.Marshal(payload)
	if err != nil || len(encoded) > 16_384 {
		return nil, savedlifecycle.NewPermanentError(savedlifecycle.ErrorCodeInvalidPublicProjection)
	}
	return string(encoded), nil
}

func savedLifecycleSummaryValue(
	localized *savedlifecycle.LocalizedProjection,
	selectValue func(*savedlifecycle.LocalizedProjection) string,
) *string {
	if localized == nil {
		return nil
	}
	value := selectValue(localized)
	if value == "" {
		return nil
	}
	return &value
}
