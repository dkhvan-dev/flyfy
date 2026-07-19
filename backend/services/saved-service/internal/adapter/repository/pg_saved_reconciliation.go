package repository

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	savedreconciliation "kz/inflap/backend/services/saved-service/internal/app/savedreconciliation"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	savedReconciliationRollbackTimeout = 2 * time.Second
	savedReconciliationConflictDelay   = time.Minute
)

type PGSavedReconciliationRepository struct {
	pool *pgxpool.Pool
}

var _ savedreconciliation.Repository = (*PGSavedReconciliationRepository)(nil)

func NewPGSavedReconciliationRepository(
	pool *pgxpool.Pool,
) (*PGSavedReconciliationRepository, error) {
	if pool == nil {
		return nil, savedreconciliation.ErrDataInvariant
	}
	return &PGSavedReconciliationRepository{pool: pool}, nil
}

func (r *PGSavedReconciliationRepository) ClaimNext(
	ctx context.Context,
	request savedreconciliation.ClaimRequest,
) (savedreconciliation.Claim, bool, error) {
	if ctx == nil || r == nil || r.pool == nil {
		return savedreconciliation.Claim{}, false, savedreconciliation.ErrDataInvariant
	}
	if err := ctx.Err(); err != nil {
		return savedreconciliation.Claim{}, false, err
	}
	if err := request.Validate(); err != nil {
		return savedreconciliation.Claim{}, false, err
	}

	tx, err := r.beginSavedReconciliationTx(ctx)
	if err != nil {
		return savedreconciliation.Claim{}, false, err
	}
	defer rollbackSavedReconciliationTx(ctx, tx)

	token := uuid.New()
	claim, found, err := scanSavedReconciliationClaim(tx.QueryRow(
		ctx,
		claimSavedReconciliationSQL,
		savedReconciliationDurationMicroseconds(request.StaleAfter),
		savedReconciliationDurationMicroseconds(request.LeaseDuration),
		token,
	), token)
	if err != nil {
		return savedreconciliation.Claim{}, false, err
	}
	if commitErr := commitSavedReconciliationTx(ctx, tx); commitErr != nil {
		return savedreconciliation.Claim{}, false, commitErr
	}
	if !found {
		return savedreconciliation.Claim{}, false, nil
	}
	if err = claim.Validate(); err != nil {
		return savedreconciliation.Claim{}, false, err
	}
	return claim, true, nil
}

func (r *PGSavedReconciliationRepository) Complete(
	ctx context.Context,
	request savedreconciliation.CompletionRequest,
) (savedreconciliation.CompletionResult, error) {
	if ctx == nil || r == nil || r.pool == nil {
		return savedreconciliation.CompletionResult{}, savedreconciliation.ErrDataInvariant
	}
	if err := ctx.Err(); err != nil {
		return savedreconciliation.CompletionResult{}, err
	}
	if err := request.Validate(); err != nil {
		return savedreconciliation.CompletionResult{}, err
	}

	tx, err := r.beginSavedReconciliationTx(ctx)
	if err != nil {
		return savedreconciliation.CompletionResult{}, err
	}
	defer rollbackSavedReconciliationTx(ctx, tx)

	locked, err := lockSavedReconciliationCompletionRow(ctx, tx, request.Claim)
	if err != nil {
		return savedreconciliation.CompletionResult{}, err
	}
	result := savedreconciliation.CompletionResult{
		Applied:   savedreconciliation.ApplyResult{Outcome: savedreconciliation.ApplyStale},
		LeaseLost: true,
	}
	var rowsAffected int64
	if locked {
		result, rowsAffected, err = completeSavedReconciliationClaim(ctx, tx, request)
		if err != nil {
			return savedreconciliation.CompletionResult{}, err
		}
	}
	if rowsAffected == 0 {
		if _, err = tx.Exec(
			ctx,
			releaseLostSavedReconciliationLeaseSQL,
			string(request.Claim.Candidate.Key.Target.EntityType()),
			request.Claim.Candidate.Key.Target.EntityID(),
			request.Claim.Token,
			savedReconciliationDurationMicroseconds(savedReconciliationConflictDelay),
		); err != nil {
			return savedreconciliation.CompletionResult{}, mapSavedReconciliationPGError(err)
		}
		result = savedreconciliation.CompletionResult{
			Applied:   savedreconciliation.ApplyResult{Outcome: savedreconciliation.ApplyStale},
			LeaseLost: true,
		}
	}
	if err = result.Validate(); err != nil {
		return savedreconciliation.CompletionResult{}, err
	}
	if err = commitSavedReconciliationTx(ctx, tx); err != nil {
		return savedreconciliation.CompletionResult{}, err
	}
	return result, nil
}

func lockSavedReconciliationCompletionRow(
	ctx context.Context,
	tx pgx.Tx,
	claim savedreconciliation.Claim,
) (bool, error) {
	var locked bool
	err := tx.QueryRow(
		ctx,
		lockSavedReconciliationCompletionRowSQL,
		string(claim.Candidate.Key.Target.EntityType()),
		claim.Candidate.Key.Target.EntityID(),
		claim.Token,
	).Scan(&locked)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, mapSavedReconciliationPGError(err)
	}
	return locked, nil
}

func (r *PGSavedReconciliationRepository) HasDue(
	ctx context.Context,
	request savedreconciliation.DueRequest,
) (bool, error) {
	if ctx == nil || r == nil || r.pool == nil {
		return false, savedreconciliation.ErrDataInvariant
	}
	if err := ctx.Err(); err != nil {
		return false, err
	}
	if err := request.Validate(); err != nil {
		return false, err
	}
	var hasDue bool
	err := r.pool.QueryRow(
		ctx,
		hasDueSavedReconciliationSQL,
		savedReconciliationDurationMicroseconds(request.StaleAfter),
	).Scan(&hasDue)
	if err != nil {
		return false, mapSavedReconciliationPGError(err)
	}
	return hasDue, nil
}

func (r *PGSavedReconciliationRepository) beginSavedReconciliationTx(
	ctx context.Context,
) (pgx.Tx, error) {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{
		IsoLevel:   pgx.ReadCommitted,
		AccessMode: pgx.ReadWrite,
	})
	if err != nil {
		return nil, mapSavedReconciliationPGError(err)
	}
	if _, err = tx.Exec(ctx, configureSavedReconciliationTxSQL); err != nil {
		rollbackSavedReconciliationTx(ctx, tx)
		return nil, mapSavedReconciliationPGError(err)
	}
	return tx, nil
}

func scanSavedReconciliationClaim(
	row pgx.Row,
	token uuid.UUID,
) (savedreconciliation.Claim, bool, error) {
	var entityType, entityID, sourceService, visibility string
	var sourceRevision, projectionRevision, visibilityRevision int64
	var failureCount int32
	var validatedAt, failClosedAt pgtype.Timestamptz
	var failureKind pgtype.Text
	var claimedAt, leaseExpiresAt time.Time
	err := row.Scan(
		&entityType,
		&entityID,
		&sourceService,
		&sourceRevision,
		&projectionRevision,
		&visibilityRevision,
		&visibility,
		&validatedAt,
		&failClosedAt,
		&failureCount,
		&failureKind,
		&claimedAt,
		&leaseExpiresAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return savedreconciliation.Claim{}, false, nil
	}
	if err != nil {
		return savedreconciliation.Claim{}, false, mapSavedReconciliationPGError(err)
	}
	if sourceRevision < 0 || projectionRevision < 0 || visibilityRevision < 0 || failureCount < 0 {
		return savedreconciliation.Claim{}, false, savedreconciliation.ErrDataInvariant
	}
	target, err := domain.NewSavedTarget(domain.EntityType(entityType), entityID)
	if err != nil {
		return savedreconciliation.Claim{}, false, savedreconciliation.ErrDataInvariant
	}
	key := savedreconciliation.CandidateKey{Target: target}
	if validatedAt.Valid {
		value := validatedAt.Time.UTC()
		key.VisibilityValidatedAt = &value
	}
	candidate := savedreconciliation.Candidate{
		Key:                key,
		SourceService:      sourceService,
		SourceRevision:     uint64(sourceRevision),
		ProjectionRevision: uint64(projectionRevision),
		VisibilityRevision: uint64(visibilityRevision),
		Visibility:         domain.VisibilityStatus(visibility),
	}
	if failClosedAt.Valid {
		value := failClosedAt.Time.UTC()
		candidate.FailClosedAt = &value
	}
	if err = candidate.Validate(); err != nil {
		return savedreconciliation.Claim{}, false, err
	}
	previousFailure, err := parseSavedReconciliationFailureKind(failureKind)
	if err != nil {
		return savedreconciliation.Claim{}, false, err
	}
	claim := savedreconciliation.Claim{
		Token:           token,
		Candidate:       candidate,
		ClaimedAt:       claimedAt.UTC(),
		LeaseExpiresAt:  leaseExpiresAt.UTC(),
		FailureCount:    int(failureCount),
		PreviousFailure: previousFailure,
	}
	if err = claim.Validate(); err != nil {
		return savedreconciliation.Claim{}, false, err
	}
	return claim, true, nil
}

type savedReconciliationMutationKind uint8

const (
	savedReconciliationNoop savedReconciliationMutationKind = iota + 1
	savedReconciliationPublic
	savedReconciliationDeny
	savedReconciliationFailClosed
	savedReconciliationMetadata
	savedReconciliationPublicMetadata
)

type savedReconciliationMutation struct {
	kind                  savedReconciliationMutationKind
	sourceRevision        uint64
	projectionRevision    uint64
	visibilityRevision    uint64
	visibility            domain.VisibilityStatus
	visibilityValidatedAt time.Time
	publicProjection      *saveditem.PublicProjectionSnapshot
	result                savedreconciliation.ApplyResult
}

func decideSavedReconciliationMutation(
	candidate savedreconciliation.Candidate,
	decision savedreconciliation.Decision,
) (savedReconciliationMutation, error) {
	currentValidatedAt := optionalReconciliationTime(candidate.Key.VisibilityValidatedAt)
	mutation := savedReconciliationMutation{
		kind:                  savedReconciliationNoop,
		sourceRevision:        candidate.SourceRevision,
		projectionRevision:    candidate.ProjectionRevision,
		visibilityRevision:    candidate.VisibilityRevision,
		visibility:            candidate.Visibility,
		visibilityValidatedAt: currentValidatedAt,
		result: savedreconciliation.ApplyResult{
			Outcome: savedreconciliation.ApplyNoChange,
		},
	}
	if decision.Kind == savedreconciliation.DecisionNoop {
		return mutation, nil
	}
	if decision.Kind == savedreconciliation.DecisionNotFound {
		if candidate.FailClosedAt != nil {
			return mutation, nil
		}
		mutation.kind = savedReconciliationFailClosed
		mutation.result.Outcome = savedreconciliation.ApplyDeny
		mutation.result.PayloadCleared = candidate.Visibility == domain.VisibilityPublic
		return mutation, nil
	}

	mutation.sourceRevision = maxReconciliationRevision(
		candidate.SourceRevision,
		decision.SourceRevision,
	)
	mutation.result.SourceAdvanced = mutation.sourceRevision > candidate.SourceRevision
	visibilityAccepted := false
	validationRefreshed := false
	if decision.VisibilityRevision > candidate.VisibilityRevision {
		visibilityAccepted = decision.Visibility != domain.VisibilityPublic ||
			candidate.Visibility == domain.VisibilityPublic ||
			decision.ProjectionRevision >= candidate.ProjectionRevision
	} else if decision.VisibilityRevision == candidate.VisibilityRevision &&
		decision.Visibility == candidate.Visibility {
		validationRefreshed = decision.ValidatedAt.After(currentValidatedAt)
	}
	if visibilityAccepted {
		mutation.visibility = decision.Visibility
		mutation.visibilityRevision = decision.VisibilityRevision
		mutation.visibilityValidatedAt = laterReconciliationTime(
			currentValidatedAt,
			decision.ValidatedAt,
		)
		mutation.result.VisibilityAdvanced = true
	} else if validationRefreshed {
		mutation.visibilityValidatedAt = decision.ValidatedAt.UTC()
	}

	publicProjectionAdvanced := decision.ProjectionRevision > candidate.ProjectionRevision
	restoresVisibilityDeniedPayload := candidate.Visibility != domain.VisibilityPublic &&
		visibilityAccepted &&
		decision.ProjectionRevision == candidate.ProjectionRevision
	restoresLocalFailClosedPayload := candidate.FailClosedAt != nil &&
		visibilityAccepted &&
		decision.ProjectionRevision == candidate.ProjectionRevision
	canApplyPublic := decision.Visibility == domain.VisibilityPublic &&
		mutation.visibility == domain.VisibilityPublic &&
		decision.VisibilityRevision >= candidate.VisibilityRevision &&
		decision.ProjectionRevision >= candidate.ProjectionRevision &&
		(publicProjectionAdvanced || restoresVisibilityDeniedPayload ||
			restoresLocalFailClosedPayload) &&
		(candidate.Visibility == domain.VisibilityPublic || visibilityAccepted)
	if canApplyPublic {
		mutation.kind = savedReconciliationPublic
		mutation.projectionRevision = decision.ProjectionRevision
		mutation.publicProjection = decision.PublicProjection
		mutation.result.Outcome = savedreconciliation.ApplyPublic
		mutation.result.ProjectionAdvanced = publicProjectionAdvanced
		return mutation, nil
	}
	refreshesPublicMediaLease := candidate.FailClosedAt == nil &&
		candidate.Visibility == domain.VisibilityPublic &&
		mutation.visibility == domain.VisibilityPublic &&
		decision.Visibility == domain.VisibilityPublic &&
		decision.ProjectionRevision == candidate.ProjectionRevision &&
		decision.PublicProjection != nil &&
		(visibilityAccepted || validationRefreshed)
	if refreshesPublicMediaLease {
		mutation.kind = savedReconciliationPublicMetadata
		mutation.publicProjection = decision.PublicProjection
		mutation.result.Outcome = savedreconciliation.ApplyMetadataOnly
		return mutation, nil
	}

	denyAccepted := mutation.visibility != domain.VisibilityPublic &&
		decision.Visibility != domain.VisibilityPublic
	if denyAccepted && decision.ProjectionRevision > candidate.ProjectionRevision {
		mutation.projectionRevision = decision.ProjectionRevision
		mutation.result.ProjectionAdvanced = true
	}
	if visibilityAccepted && mutation.visibility != domain.VisibilityPublic {
		mutation.kind = savedReconciliationDeny
		mutation.result.Outcome = savedreconciliation.ApplyDeny
		mutation.result.PayloadCleared = candidate.Visibility == domain.VisibilityPublic
		return mutation, nil
	}
	if denyAccepted && mutation.result.ProjectionAdvanced {
		mutation.kind = savedReconciliationDeny
		mutation.result.Outcome = savedreconciliation.ApplyDeny
		return mutation, nil
	}

	metadataChanged := mutation.result.SourceAdvanced ||
		mutation.result.VisibilityAdvanced || validationRefreshed
	if metadataChanged {
		mutation.kind = savedReconciliationMetadata
		mutation.result.Outcome = savedreconciliation.ApplyMetadataOnly
		return mutation, nil
	}
	if decision.SourceRevision < candidate.SourceRevision ||
		decision.ProjectionRevision < candidate.ProjectionRevision ||
		decision.VisibilityRevision < candidate.VisibilityRevision {
		mutation.result.Outcome = savedreconciliation.ApplyStale
	}
	return mutation, nil
}

func completeSavedReconciliationClaim(
	ctx context.Context,
	tx pgx.Tx,
	request savedreconciliation.CompletionRequest,
) (savedreconciliation.CompletionResult, int64, error) {
	if request.Failure != savedreconciliation.CompletionFailureNone {
		arguments := savedReconciliationCompletionArguments(request)
		arguments["next_attempt_delay_us"] = optionalSavedReconciliationDurationMicroseconds(
			request.NextAttemptDelay,
		)
		arguments["failure_kind"] = savedReconciliationFailureKind(request.Failure)
		arguments["quarantine"] = request.Quarantine
		arguments["quarantine_reason"] = savedReconciliationQuarantineReason(request.Failure)
		rowsAffected, err := execSavedReconciliationNamedUpdate(
			ctx,
			tx,
			completeSavedReconciliationFailureSQL,
			arguments,
		)
		return savedreconciliation.CompletionResult{
			Applied:        savedreconciliation.ApplyResult{Outcome: savedreconciliation.ApplyNoChange},
			RetryScheduled: !request.Quarantine,
			Quarantined:    request.Quarantine,
		}, rowsAffected, err
	}

	mutation, err := decideSavedReconciliationMutation(request.Claim.Candidate, request.Decision)
	if err != nil {
		return savedreconciliation.CompletionResult{}, 0, err
	}
	if err = mutation.result.Validate(); err != nil {
		return savedreconciliation.CompletionResult{}, 0, err
	}
	arguments := savedReconciliationCompletionArguments(request)
	arguments["source_revision"] = int64(mutation.sourceRevision)
	arguments["projection_revision"] = int64(mutation.projectionRevision)
	arguments["visibility_revision"] = int64(mutation.visibilityRevision)
	arguments["visibility"] = string(mutation.visibility)
	arguments["visibility_validated_at"] = optionalSavedReconciliationTimeValue(
		mutation.visibilityValidatedAt,
	)

	query := completeSavedReconciliationNoopSQL
	switch mutation.kind {
	case savedReconciliationNoop:
	case savedReconciliationPublic:
		query = applySavedReconciliationPublicSQL
		if err = addSavedReconciliationPublicArguments(
			arguments,
			mutation,
			request.Claim.ClaimedAt,
		); err != nil {
			return savedreconciliation.CompletionResult{}, 0, err
		}
	case savedReconciliationDeny:
		query = applySavedReconciliationDenySQL
	case savedReconciliationFailClosed:
		query = applySavedReconciliationFailClosedSQL
	case savedReconciliationMetadata:
		query = updateSavedReconciliationMetadataSQL
	case savedReconciliationPublicMetadata:
		query = refreshSavedReconciliationPublicMetadataSQL
		if err = addSavedReconciliationMediaArguments(
			arguments,
			mutation,
			request.Claim.ClaimedAt,
		); err != nil {
			return savedreconciliation.CompletionResult{}, 0, err
		}
	default:
		return savedreconciliation.CompletionResult{}, 0, savedreconciliation.ErrDataInvariant
	}
	rowsAffected, err := execSavedReconciliationNamedUpdate(ctx, tx, query, arguments)
	return savedreconciliation.CompletionResult{Applied: mutation.result}, rowsAffected, err
}

func savedReconciliationCompletionArguments(
	request savedreconciliation.CompletionRequest,
) pgx.NamedArgs {
	candidate := request.Claim.Candidate
	return pgx.NamedArgs{
		"entity_type":                      string(candidate.Key.Target.EntityType()),
		"entity_id":                        candidate.Key.Target.EntityID(),
		"lease_token":                      request.Claim.Token,
		"next_attempt_delay_us":            optionalSavedReconciliationDurationMicroseconds(request.NextAttemptDelay),
		"expected_source_service":          candidate.SourceService,
		"expected_source_revision":         int64(candidate.SourceRevision),
		"expected_projection_revision":     int64(candidate.ProjectionRevision),
		"expected_visibility_revision":     int64(candidate.VisibilityRevision),
		"expected_visibility":              string(candidate.Visibility),
		"expected_visibility_validated_at": optionalSavedReconciliationTime(candidate.Key.VisibilityValidatedAt),
		"expected_fail_closed_at":          optionalSavedReconciliationTime(candidate.FailClosedAt),
		"expected_failure_count":           request.Claim.FailureCount,
		"expected_failure_kind":            optionalSavedReconciliationFailureKind(request.Claim.PreviousFailure),
	}
}

func addSavedReconciliationPublicArguments(
	arguments pgx.NamedArgs,
	mutation savedReconciliationMutation,
	completedAt time.Time,
) error {
	projection := mutation.publicProjection
	if projection == nil || mutation.visibility != domain.VisibilityPublic ||
		mutation.visibilityValidatedAt.IsZero() {
		return savedreconciliation.ErrDataInvariant
	}
	priceSummary, err := encodeSavedReconciliationSummary(projection.PriceSummary)
	if err != nil {
		return err
	}
	availabilitySummary, err := encodeSavedReconciliationSummary(projection.AvailabilitySummary)
	if err != nil {
		return err
	}
	arguments["source_default_locale"] = string(projection.SourceDefaultLocale)
	arguments["title_en"] = optionalSavedReconciliationText(projection.Title.EN)
	arguments["title_ru"] = optionalSavedReconciliationText(projection.Title.RU)
	arguments["title_kk"] = optionalSavedReconciliationText(projection.Title.KK)
	arguments["subtitle_en"] = optionalSavedReconciliationText(projection.Subtitle.EN)
	arguments["subtitle_ru"] = optionalSavedReconciliationText(projection.Subtitle.RU)
	arguments["subtitle_kk"] = optionalSavedReconciliationText(projection.Subtitle.KK)
	arguments["city_en"] = optionalSavedReconciliationText(projection.City.EN)
	arguments["city_ru"] = optionalSavedReconciliationText(projection.City.RU)
	arguments["city_kk"] = optionalSavedReconciliationText(projection.City.KK)
	arguments["country_en"] = optionalSavedReconciliationText(projection.Country.EN)
	arguments["country_ru"] = optionalSavedReconciliationText(projection.Country.RU)
	arguments["country_kk"] = optionalSavedReconciliationText(projection.Country.KK)
	arguments["display_location_en"] = optionalSavedReconciliationText(projection.DisplayLocation.EN)
	arguments["display_location_ru"] = optionalSavedReconciliationText(projection.DisplayLocation.RU)
	arguments["display_location_kk"] = optionalSavedReconciliationText(projection.DisplayLocation.KK)
	arguments["search_document_en"] = optionalSavedReconciliationText(projection.NormalizedSearchDocument.EN)
	arguments["search_document_ru"] = optionalSavedReconciliationText(projection.NormalizedSearchDocument.RU)
	arguments["search_document_kk"] = optionalSavedReconciliationText(projection.NormalizedSearchDocument.KK)
	arguments["price_summary"] = priceSummary
	arguments["availability_summary"] = availabilitySummary
	arguments["summary_as_of"] = optionalSavedReconciliationTime(projection.AsOf)
	arguments["summary_valid_until"] = optionalSavedReconciliationTime(projection.ValidUntil)
	arguments["canonical_detail_route"] = optionalSavedReconciliationText(projection.CanonicalDetailRoute)
	if projection.Rating == nil {
		arguments["rating_value"] = nil
		arguments["rating_count"] = nil
		arguments["rating_scale_max"] = nil
	} else {
		arguments["rating_value"] = projection.Rating.Value
		arguments["rating_count"] = int64(projection.Rating.ReviewCount)
		arguments["rating_scale_max"] = projection.Rating.ScaleMax
	}
	return addSavedReconciliationMediaArguments(arguments, mutation, completedAt)
}

func addSavedReconciliationMediaArguments(
	arguments pgx.NamedArgs,
	mutation savedReconciliationMutation,
	completedAt time.Time,
) error {
	projection := mutation.publicProjection
	if projection == nil || mutation.visibility != domain.VisibilityPublic ||
		mutation.visibilityValidatedAt.IsZero() {
		return savedreconciliation.ErrDataInvariant
	}
	if projection.Media != nil &&
		projection.Media.ValidUntil.After(completedAt.UTC()) &&
		projection.Media.ValidUntil.After(mutation.visibilityValidatedAt) &&
		!projection.Media.ValidUntil.After(mutation.visibilityValidatedAt.Add(15*time.Minute)) {
		arguments["media_reference"] = projection.Media.OpaqueReference
		arguments["media_reference_revision"] = int64(projection.Media.ReferenceRevision)
		arguments["media_valid_until"] = projection.Media.ValidUntil.UTC()
	} else {
		arguments["media_reference"] = nil
		arguments["media_reference_revision"] = nil
		arguments["media_valid_until"] = nil
	}
	return nil
}

func savedReconciliationQuarantineReason(failure savedreconciliation.CompletionFailure) any {
	switch failure {
	case savedreconciliation.CompletionFailureInvariant:
		return "INVARIANT"
	case savedreconciliation.CompletionFailureUnsupported:
		return "UNSUPPORTED"
	default:
		return nil
	}
}

func savedReconciliationFailureKind(
	failure savedreconciliation.CompletionFailure,
) string {
	switch failure {
	case savedreconciliation.CompletionFailureTransient:
		return "TRANSIENT"
	case savedreconciliation.CompletionFailureInvariant:
		return "INVARIANT"
	case savedreconciliation.CompletionFailureUnsupported:
		return "UNSUPPORTED"
	default:
		return ""
	}
}

func optionalSavedReconciliationFailureKind(
	failure savedreconciliation.CompletionFailure,
) any {
	value := savedReconciliationFailureKind(failure)
	if value == "" {
		return nil
	}
	return value
}

func parseSavedReconciliationFailureKind(
	value pgtype.Text,
) (savedreconciliation.CompletionFailure, error) {
	if !value.Valid {
		return savedreconciliation.CompletionFailureNone, nil
	}
	switch value.String {
	case "TRANSIENT":
		return savedreconciliation.CompletionFailureTransient, nil
	case "INVARIANT":
		return savedreconciliation.CompletionFailureInvariant, nil
	case "UNSUPPORTED":
		return savedreconciliation.CompletionFailureUnsupported, nil
	default:
		return savedreconciliation.CompletionFailureNone, savedreconciliation.ErrDataInvariant
	}
}

func encodeSavedReconciliationSummary(value saveditem.LocalizedText) (any, error) {
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
		return nil, savedreconciliation.ErrDataInvariant
	}
	return string(encoded), nil
}

func optionalSavedReconciliationText(value *string) any {
	if value == nil || *value == "" {
		return nil
	}
	return *value
}

func optionalSavedReconciliationTime(value *time.Time) any {
	if value == nil {
		return nil
	}
	return value.UTC()
}

func optionalSavedReconciliationTimeValue(value time.Time) any {
	if value.IsZero() {
		return nil
	}
	return value.UTC()
}

func savedReconciliationDurationMicroseconds(value time.Duration) int64 {
	microseconds := value / time.Microsecond
	if value%time.Microsecond != 0 {
		microseconds++
	}
	return int64(microseconds)
}

func optionalSavedReconciliationDurationMicroseconds(value time.Duration) any {
	if value <= 0 {
		return nil
	}
	return savedReconciliationDurationMicroseconds(value)
}

func execSavedReconciliationNamedUpdate(
	ctx context.Context,
	tx pgx.Tx,
	query string,
	arguments pgx.NamedArgs,
) (int64, error) {
	tag, err := tx.Exec(ctx, query, arguments)
	if err != nil {
		return 0, mapSavedReconciliationPGError(err)
	}
	if tag.RowsAffected() > 1 {
		return 0, savedreconciliation.ErrDataInvariant
	}
	return tag.RowsAffected(), nil
}

func optionalReconciliationTime(value *time.Time) time.Time {
	if value == nil {
		return time.Time{}
	}
	return value.UTC()
}

func laterReconciliationTime(left, right time.Time) time.Time {
	if right.After(left) {
		return right.UTC()
	}
	return left.UTC()
}

func maxReconciliationRevision(left, right uint64) uint64 {
	if right > left {
		return right
	}
	return left
}

func commitSavedReconciliationTx(ctx context.Context, tx pgx.Tx) error {
	if err := tx.Commit(ctx); err != nil {
		if errors.Is(err, pgx.ErrTxCommitRollback) {
			return mapSavedReconciliationPGError(err)
		}
		return savedreconciliation.ErrCommitOutcomeUnknown
	}
	return nil
}

func rollbackSavedReconciliationTx(parent context.Context, tx pgx.Tx) {
	rollbackCtx, cancel := context.WithTimeout(
		context.WithoutCancel(parent),
		savedReconciliationRollbackTimeout,
	)
	defer cancel()
	_ = tx.Rollback(rollbackCtx)
}

func mapSavedReconciliationPGError(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}
	var postgresError *pgconn.PgError
	if errors.As(err, &postgresError) {
		switch postgresError.Code {
		case "22003", "22P02", "23502", "23503", "23505", "23514":
			return savedreconciliation.ErrDataInvariant
		}
	}
	return savedreconciliation.ErrRepositoryUnavailable
}
