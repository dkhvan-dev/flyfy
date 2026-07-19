package repository

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const savedUserMigrationIntegrationDSNEnv = "SAVED_SERVICE_REPOSITORY_TEST_DSN"

func TestSavedUserEntityMigrationCanonicalizesGuideRowsWithoutDataLoss(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv(savedUserMigrationIntegrationDSNEnv))
	if dsn == "" {
		t.Skipf("%s is not set", savedUserMigrationIntegrationDSNEnv)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	adminPool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect integration database: %v", err)
	}
	if err = adminPool.Ping(ctx); err != nil {
		adminPool.Close()
		t.Fatalf("ping integration database: %v", err)
	}

	schema := "saved_user_migration_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	quotedSchema := pgx.Identifier{schema}.Sanitize()
	if _, err = adminPool.Exec(ctx, "CREATE SCHEMA "+quotedSchema); err != nil {
		adminPool.Close()
		t.Fatalf("create isolated schema: %v", err)
	}
	poolConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		t.Fatalf("parse integration DSN: %v", err)
	}
	poolConfig.ConnConfig.RuntimeParams["search_path"] = quotedSchema
	poolConfig.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		t.Fatalf("connect isolated schema: %v", err)
	}
	t.Cleanup(func() {
		pool.Close()
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cleanupCancel()
		if _, cleanupErr := adminPool.Exec(cleanupCtx, "DROP SCHEMA "+quotedSchema+" CASCADE"); cleanupErr != nil {
			t.Errorf("drop isolated schema: %v", cleanupErr)
		}
		adminPool.Close()
	})

	for _, migration := range []string{
		"001_saved_core.up.sql",
		"002_saved_collections.up.sql",
		"003_saved_search.up.sql",
		"006_saved_reconciliation_scheduler.up.sql",
		"006b_saved_reconciliation_scheduler_contract.sql",
		"007_saved_entity_scope_expand.up.sql",
		"007a_saved_entity_scope_validate.up.sql",
		"007b_saved_entity_scope_contract.up.sql",
	} {
		applySavedUserMigrationInTransaction(t, pool, migration)
	}

	userID := uuid.New()
	avatarFileID := uuid.New()
	ownerUserID := uuid.New()
	savedItemID := uuid.New()
	now := time.Now().UTC().Truncate(time.Microsecond)
	guideReference := "guide-avatar:" + userID.String() + ":" + avatarFileID.String() + ":300"
	if _, err = pool.Exec(ctx, `
		INSERT INTO saved_content_projections (
			entity_type, entity_id, source_service,
			source_revision, projection_revision, visibility_revision,
			visibility_status, visibility_validated_at,
			source_default_locale, title_en,
			search_document_version, normalized_search_document_en,
			media_reference, media_reference_revision, media_valid_until,
			canonical_detail_route, ever_referenced, created_at, updated_at
		) VALUES (
			'GUIDE', $1, 'guide-service', 101, 102, 103,
			'PUBLIC', $2, 'EN', 'Guide profile', 300, 'guide profile', $3, 300, $4,
			$5, TRUE, $6, $2
		)`,
		userID.String(),
		now,
		guideReference,
		now.Add(5*time.Minute),
		"/users/"+userID.String()+"/profile",
		now.Add(-time.Hour),
	); err != nil {
		t.Fatalf("seed GUIDE projection: %v", err)
	}
	stateGeneration := uuid.New()
	attributionID := uuid.New()
	if _, err = pool.Exec(ctx, `
		INSERT INTO saved_items (
			id, owner_user_id, entity_type, entity_id,
			relationship_state, state_generation, relationship_attribution_id,
			relationship_version, saved_at, created_at, updated_at
		) VALUES ($1, $2, 'GUIDE', $3, 'ACTIVE', $4, $5, 1, $6, $7, $6)`,
		savedItemID,
		ownerUserID,
		userID.String(),
		stateGeneration,
		attributionID,
		now,
		now.Add(-time.Hour),
	); err != nil {
		t.Fatalf("seed GUIDE Saved item: %v", err)
	}
	if _, err = pool.Exec(ctx, `
		INSERT INTO saved_outbox (
			id, owner_user_id, saved_item_id, event_type,
			entity_type, entity_id, relationship_state,
			state_generation, relationship_attribution_id, relationship_version,
			created_at, updated_at
		) VALUES (
			$1, $2, $3, 'SAVED_ITEM_ACTIVATED',
			'GUIDE', $4, 'ACTIVE', $5, $6, 1, $7, $7
		)`,
		uuid.New(),
		ownerUserID,
		savedItemID,
		userID.String(),
		stateGeneration,
		attributionID,
		now,
	); err != nil {
		t.Fatalf("seed GUIDE outbox row: %v", err)
	}

	applySavedUserMigrationInTransaction(t, pool, "008_saved_user_entity.up.sql")

	var entityType string
	var sourceService string
	var sourceRevision int64
	var projectionRevision int64
	var visibilityRevision int64
	var mediaReference string
	var canonicalRoute string
	var nextAttemptAt time.Time
	var failureCount int
	if err = pool.QueryRow(ctx, `
		SELECT entity_type, source_service,
		       source_revision, projection_revision, visibility_revision,
		       media_reference, canonical_detail_route,
		       reconciliation_next_attempt_at, reconciliation_failure_count
		FROM saved_content_projections
		WHERE entity_id = $1`, userID.String()).Scan(
		&entityType,
		&sourceService,
		&sourceRevision,
		&projectionRevision,
		&visibilityRevision,
		&mediaReference,
		&canonicalRoute,
		&nextAttemptAt,
		&failureCount,
	); err != nil {
		t.Fatalf("read canonical USER projection: %v", err)
	}
	wantReference := "user-avatar:" + userID.String() + ":" + avatarFileID.String() + ":300"
	if entityType != "USER" || sourceService != "user-service" ||
		sourceRevision != 1 || projectionRevision != 1 || visibilityRevision != 1 ||
		mediaReference != wantReference ||
		canonicalRoute != "/users/"+userID.String()+"/profile" ||
		nextAttemptAt.IsZero() || failureCount != 0 {
		t.Fatalf(
			"canonical projection = type=%s source=%s revisions=%d/%d/%d media=%q route=%q next=%s failures=%d",
			entityType,
			sourceService,
			sourceRevision,
			projectionRevision,
			visibilityRevision,
			mediaReference,
			canonicalRoute,
			nextAttemptAt,
			failureCount,
		)
	}

	canonicalUserID := uuid.New()
	canonicalAvatarID := uuid.New()
	canonicalReference := "user-avatar:" + canonicalUserID.String() + ":" + canonicalAvatarID.String() + ":200"
	if _, err = pool.Exec(ctx, `
		INSERT INTO saved_content_projections (
			entity_type, entity_id, source_service,
			source_revision, projection_revision, visibility_revision,
			visibility_status, visibility_validated_at,
			source_default_locale, title_en,
			search_document_version, normalized_search_document_en,
			media_reference, media_reference_revision, media_valid_until,
			canonical_detail_route, ever_referenced, created_at, updated_at
		) VALUES (
			'USER', $1, 'user-service', 200, 200, 200,
			'PUBLIC', $2, 'EN', 'Current user profile', 200, 'current user profile', $3, 200, $4,
			$5, TRUE, $6, $2
		)`,
		canonicalUserID.String(),
		now,
		canonicalReference,
		now.Add(5*time.Minute),
		"/users/"+canonicalUserID.String()+"/profile",
		now.Add(-time.Hour),
	); err != nil {
		t.Fatalf("seed canonical USER projection: %v", err)
	}

	applySavedUserMigrationInTransaction(t, pool, "008b_saved_user_media_revision_repair.up.sql")
	applySavedUserMigrationInTransaction(t, pool, "008c_saved_user_search_revision_repair.up.sql")

	var repairedMediaFields int
	var repairedSearchDocumentVersion int64
	var repairedSearchDocuments int
	var repairScheduled bool
	if err = pool.QueryRow(ctx, `
		SELECT num_nonnulls(media_reference, media_reference_revision, media_valid_until),
		       search_document_version,
		       num_nonnulls(
		           normalized_search_document_en,
		           normalized_search_document_ru,
		           normalized_search_document_kk
		       ),
		       reconciliation_next_attempt_at <= CURRENT_TIMESTAMP
		FROM saved_content_projections
		WHERE entity_type = 'USER' AND entity_id = $1`, userID.String()).Scan(
		&repairedMediaFields,
		&repairedSearchDocumentVersion,
		&repairedSearchDocuments,
		&repairScheduled,
	); err != nil {
		t.Fatalf("read repaired legacy USER projection: %v", err)
	}
	if repairedMediaFields != 0 || repairedSearchDocumentVersion != 0 ||
		repairedSearchDocuments != 0 || !repairScheduled {
		t.Fatalf(
			"legacy USER fields = media:%d search-version:%d search-documents:%d scheduled:%t",
			repairedMediaFields,
			repairedSearchDocumentVersion,
			repairedSearchDocuments,
			repairScheduled,
		)
	}

	var preservedCanonicalReference string
	var preservedCanonicalRevision int64
	var preservedCanonicalSearchVersion int64
	var preservedCanonicalSearchDocument string
	if err = pool.QueryRow(ctx, `
		SELECT media_reference, media_reference_revision,
		       search_document_version, normalized_search_document_en
		FROM saved_content_projections
		WHERE entity_type = 'USER' AND entity_id = $1`, canonicalUserID.String()).Scan(
		&preservedCanonicalReference,
		&preservedCanonicalRevision,
		&preservedCanonicalSearchVersion,
		&preservedCanonicalSearchDocument,
	); err != nil {
		t.Fatalf("read canonical USER projection after repair: %v", err)
	}
	if preservedCanonicalReference != canonicalReference || preservedCanonicalRevision != 200 ||
		preservedCanonicalSearchVersion != 200 || preservedCanonicalSearchDocument != "current user profile" {
		t.Fatalf(
			"canonical USER projection = media:%q/%d search:%d/%q",
			preservedCanonicalReference,
			preservedCanonicalRevision,
			preservedCanonicalSearchVersion,
			preservedCanonicalSearchDocument,
		)
	}

	var preservedSavedItemCount int
	if err = pool.QueryRow(ctx, `
		SELECT count(*)
		FROM saved_items
		WHERE id = $1 AND owner_user_id = $2 AND entity_type = 'USER'
		  AND entity_id = $3 AND relationship_state = 'ACTIVE'`,
		savedItemID,
		ownerUserID,
		userID.String(),
	).Scan(&preservedSavedItemCount); err != nil {
		t.Fatalf("count preserved Saved item: %v", err)
	}
	if preservedSavedItemCount != 1 {
		t.Fatalf("preserved Saved item count = %d, want 1", preservedSavedItemCount)
	}

	target, err := domain.NewSavedTarget(domain.EntityTypeUser, userID.String())
	if err != nil {
		t.Fatalf("create canonical USER target: %v", err)
	}
	currentTitle := "Canonical user profile"
	currentSearchDocument := "canonical user profile"
	currentRoute := "/users/" + userID.String() + "/profile"
	currentRevision := uint64(200)
	currentNow := now.Add(time.Minute)
	currentProjection := saveditemapp.PublicProjectionSnapshot{
		Target:                   target,
		SourceService:            "user-service",
		SourceRevision:           currentRevision,
		ProjectionRevision:       currentRevision,
		VisibilityRevision:       currentRevision,
		VisibilityValidatedAt:    currentNow,
		SourceDefaultLocale:      saveditemapp.LocaleEN,
		Title:                    saveditemapp.LocalizedText{EN: &currentTitle},
		SearchDocumentVersion:    currentRevision,
		NormalizedSearchDocument: saveditemapp.LocalizedText{EN: &currentSearchDocument},
		Media: &saveditemapp.MediaReference{
			OpaqueReference:   "user-avatar:" + userID.String() + ":" + avatarFileID.String() + ":200",
			ReferenceRevision: currentRevision,
			ValidUntil:        currentNow.Add(5 * time.Minute),
		},
		CanonicalDetailRoute: &currentRoute,
		ShellExpiresAt:       currentNow.Add(15 * time.Minute),
	}
	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin canonical projection update: %v", err)
	}
	defer func() { _ = tx.Rollback(context.Background()) }()
	if err = writeAuthoritativePublicProjection(ctx, tx, currentProjection, currentNow); err != nil {
		t.Fatalf("write canonical projection after revision repair: %v", err)
	}
	if err = tx.Commit(ctx); err != nil {
		t.Fatalf("commit canonical projection update: %v", err)
	}

	var appliedSourceRevision int64
	var appliedProjectionRevision int64
	var appliedSearchRevision int64
	var appliedMediaRevision int64
	var appliedTitle string
	if err = pool.QueryRow(ctx, `
		SELECT source_revision, projection_revision,
		       search_document_version, media_reference_revision, title_en
		FROM saved_content_projections
		WHERE entity_type = 'USER' AND entity_id = $1`, userID.String()).Scan(
		&appliedSourceRevision,
		&appliedProjectionRevision,
		&appliedSearchRevision,
		&appliedMediaRevision,
		&appliedTitle,
	); err != nil {
		t.Fatalf("read canonical projection update: %v", err)
	}
	if appliedSourceRevision != int64(currentRevision) ||
		appliedProjectionRevision != int64(currentRevision) ||
		appliedSearchRevision != int64(currentRevision) ||
		appliedMediaRevision != int64(currentRevision) ||
		appliedTitle != currentTitle {
		t.Fatalf(
			"canonical projection update = source:%d projection:%d search:%d media:%d title:%q",
			appliedSourceRevision,
			appliedProjectionRevision,
			appliedSearchRevision,
			appliedMediaRevision,
			appliedTitle,
		)
	}

	for table, expectedUserRows := range map[string]int{
		"saved_content_projections": 2,
		"saved_items":               1,
		"saved_outbox":              1,
	} {
		var userRows int
		var guideRows int
		query := "SELECT count(*) FILTER (WHERE entity_type = 'USER'), " +
			"count(*) FILTER (WHERE entity_type = 'GUIDE') FROM " + pgx.Identifier{table}.Sanitize()
		if err = pool.QueryRow(ctx, query).Scan(&userRows, &guideRows); err != nil {
			t.Fatalf("count canonical rows in %s: %v", table, err)
		}
		if userRows != expectedUserRows || guideRows != 0 {
			t.Fatalf(
				"%s USER/GUIDE rows = %d/%d, want %d/0",
				table,
				userRows,
				guideRows,
				expectedUserRows,
			)
		}
	}
}

func applySavedUserMigrationInTransaction(
	t *testing.T,
	pool *pgxpool.Pool,
	migration string,
) {
	t.Helper()
	tx, err := pool.Begin(context.Background())
	if err != nil {
		t.Fatalf("begin migration %s: %v", migration, err)
	}
	defer func() { _ = tx.Rollback(context.Background()) }()
	if _, err = tx.Exec(context.Background(), readMigration(t, migration)); err != nil {
		t.Fatalf("apply migration %s: %v", migration, err)
	}
	if err = tx.Commit(context.Background()); err != nil {
		t.Fatalf("commit migration %s: %v", migration, err)
	}
}
