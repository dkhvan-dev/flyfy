package repository

import (
	"encoding/json"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

func readRepositorySources(t *testing.T, paths ...string) string {
	t.Helper()
	var builder strings.Builder
	for _, path := range paths {
		sourceBytes, err := os.ReadFile(path)
		if err != nil {
			t.Fatalf("read repository source %s: %v", path, err)
		}
		builder.Write(sourceBytes)
		builder.WriteByte('\n')
	}
	return builder.String()
}

func TestPostPublishCooldownSchemaAndRepositoryAreAtomic(t *testing.T) {
	baselineBytes, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read baseline migration: %v", err)
	}
	indexBytes, err := os.ReadFile("../../../migrations/003_post_publish_rate_limit_index.up.sql")
	if err != nil {
		t.Fatalf("read publish rate index migration: %v", err)
	}
	cooldownBytes, err := os.ReadFile("../../../migrations/004_post_publish_cooldowns.up.sql")
	if err != nil {
		t.Fatalf("read publish cooldown migration: %v", err)
	}
	repositoryBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read post repository: %v", err)
	}

	baseline := string(baselineBytes)
	indexMigration := string(indexBytes)
	cooldownMigration := string(cooldownBytes)
	repository := string(repositoryBytes)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS post_publish_cooldowns",
		"author_user_id uuid PRIMARY KEY",
		"next_available_at timestamp with time zone NOT NULL",
		"idx_posts_author_published_rate_limit",
	} {
		if !strings.Contains(baseline, needle) {
			t.Fatalf("baseline migration must contain %q", needle)
		}
	}
	if !strings.Contains(indexMigration, "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_author_published_rate_limit") {
		t.Fatal("publish rate index must be created concurrently")
	}
	for _, needle := range []string{
		"published_at + INTERVAL '5 minutes'",
		"published_at > NOW() - INTERVAL '5 minutes'",
		"ON CONFLICT (author_user_id) DO NOTHING",
	} {
		if !strings.Contains(cooldownMigration, needle) {
			t.Fatalf("cooldown migration must contain %q", needle)
		}
	}
	for _, needle := range []string{
		"reservePostPublishCooldownTx(ctx, tx",
		"ON CONFLICT (author_user_id) DO NOTHING",
		"UPDATE post_publish_cooldowns",
		"AND next_available_at <= clock_timestamp()",
		"return &port.PostPublishCooldownError",
	} {
		if !strings.Contains(repository, needle) {
			t.Fatalf("repository must contain %q", needle)
		}
	}
}

func TestPostListOrderBySupportsSortDirections(t *testing.T) {
	tests := map[string]string{
		"latest":         "COALESCE(published_at, created_at) DESC, id DESC",
		"latest_desc":    "COALESCE(published_at, created_at) DESC, id DESC",
		"latest_asc":     "COALESCE(published_at, created_at) ASC, id ASC",
		"popular":        "view_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"popular_desc":   "view_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"popular_asc":    "view_count ASC, published_at ASC NULLS LAST, created_at ASC",
		"discussed":      "comment_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"discussed_desc": "comment_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"discussed_asc":  "comment_count ASC, published_at ASC NULLS LAST, created_at ASC",
		"unknown":        "COALESCE(published_at, created_at) DESC, id DESC",
	}

	for sort, expected := range tests {
		t.Run(sort, func(t *testing.T) {
			if got := postListOrderBy(sort); got != expected {
				t.Fatalf("order by mismatch\nexpected: %s\nactual:   %s", expected, got)
			}
		})
	}
}

func TestAppendRelatedPostOrderByScoresSmartSignals(t *testing.T) {
	category := enum.PostCategoryGuide
	format := enum.PostFormatGuide
	authorID := uuid.New()

	args, orderBy := appendRelatedPostOrderBy(nil, model.PostListFilter{
		RelatedToCityID:   "almaty",
		RelatedToCountry:  "kz",
		RelatedToCategory: &category,
		RelatedToFormat:   &format,
		RelatedToAuthor:   &authorID,
		RelatedToTags:     []string{"food", "almaty"},
	})

	if len(args) != 6 {
		t.Fatalf("args = %v, want six related score args", args)
	}
	for _, needle := range []string{
		"place_city_id = $1",
		"place_country_code = $2",
		"category = $3",
		"format = $4",
		"author_user_id = $5",
		"unnest(COALESCE(tags, ARRAY[]::text[]))",
		"&& $6",
		"view_count DESC",
		"published_at DESC NULLS LAST",
	} {
		if !strings.Contains(orderBy, needle) {
			t.Fatalf("orderBy = %q, want %q", orderBy, needle)
		}
	}
}

func TestRepositoryPersistsAndFiltersPlaceCityID(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)

	for _, needle := range []string{
		"place_city_id",
		"post.PlaceCityID",
		"filter.PlaceCityID",
		"item.PlaceCityID",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("repository source must contain %q", needle)
		}
	}

	migrationBytes, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read place city migration: %v", err)
	}
	migration := string(migrationBytes)
	for _, needle := range []string{
		"place_city_id text",
		"idx_posts_place_city_published",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("migration must contain %q", needle)
		}
	}
}

func TestScanPostNormalizesContentEngineDefaults(t *testing.T) {
	now := time.Now().UTC()
	postID := uuid.New()
	authorID := uuid.New()

	item, err := scanPost(stubScanner{
		values: []any{
			postID,
			"my-post",
			authorID,
			"Title",
			"Excerpt",
			"Legacy content",
			"JOURNAL",
			"DRAFT",
			nil,
			nil,
			"ARTICLE",
			"article_v1",
			int64(1),
			json.RawMessage(`{}`),
			"PREMODERATION",
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			[]string{"travel"},
			0,
			0,
			0,
			0,
			nil,
			nil,
			now,
			now,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
		},
	})
	if err != nil {
		t.Fatalf("scan post: %v", err)
	}

	if item.Format != enum.PostFormatArticle {
		t.Fatalf("Format = %q, want %q", item.Format, enum.PostFormatArticle)
	}
	if item.ContentSchemaVersion != 1 {
		t.Fatalf("ContentSchemaVersion = %d, want 1", item.ContentSchemaVersion)
	}
	if item.ContentBlocks != nil {
		t.Fatalf("ContentBlocks = %s, want nil", string(item.ContentBlocks))
	}
	if item.ContentPlainText != "" {
		t.Fatalf("ContentPlainText = %q, want empty", item.ContentPlainText)
	}
	if item.Revision != 1 {
		t.Fatalf("Revision = %d, want 1", item.Revision)
	}
	if item.LastAutosavedAt != nil {
		t.Fatalf("LastAutosavedAt = %v, want nil", item.LastAutosavedAt)
	}
	if item.ArchivedAt != nil {
		t.Fatalf("ArchivedAt = %v, want nil", item.ArchivedAt)
	}
	if item.ModerationStatus != enum.ModerationStatusNotRequired {
		t.Fatalf("ModerationStatus = %q, want %q", item.ModerationStatus, enum.ModerationStatusNotRequired)
	}
}

func TestNormalizePostContentEngineFieldsDoesNotInferContractFromProfileKey(t *testing.T) {
	post := &model.Post{
		PostProfileKey:     enum.PostProfileTripPlanV1,
		PostProfileVersion: 1,
		StructuredData:     json.RawMessage(`{}`),
	}

	normalizePostContentEngineFields(post)

	if post.PostKind == enum.PostKindTripPlan {
		t.Fatal("PostKind was inferred from PostProfileKey; repository must require usecase/profile contract to provide it")
	}
	if post.ModerationMode == enum.ModerationModePublishFirstWithRiskHold {
		t.Fatal("ModerationMode was inferred from PostProfileKey; repository must require usecase/profile contract to provide it")
	}
}

func TestScanPostRejectsInvalidContractFields(t *testing.T) {
	now := time.Now().UTC()
	postID := uuid.New()
	authorID := uuid.New()

	_, err := scanPost(stubScanner{
		values: []any{
			postID,
			"my-post",
			authorID,
			"Title",
			"Excerpt",
			"Content",
			"JOURNAL",
			"DRAFT",
			nil,
			nil,
			"",
			"trip_plan_v1",
			int64(1),
			json.RawMessage(`{}`),
			"",
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			[]string{"travel"},
			0,
			0,
			0,
			0,
			nil,
			nil,
			now,
			now,
			nil,
			"POST",
			int64(1),
			json.RawMessage(`{}`),
			"Content",
			int64(1),
			nil,
			nil,
			"NOT_REQUIRED",
			"READY",
		},
	})
	if err == nil {
		t.Fatal("scanPost must reject rows with missing post_kind/moderation_mode instead of applying legacy fallback")
	}
	if !strings.Contains(err.Error(), "invalid post kind") {
		t.Fatalf("scanPost error = %v, want invalid post kind", err)
	}
}

func TestScanPostReadsContentEngineFields(t *testing.T) {
	now := time.Now().UTC()
	lastAutosavedAt := now.Add(time.Minute)
	archivedAt := now.Add(time.Hour)
	expiresAt := now.Add(24 * time.Hour)
	postID := uuid.New()
	authorID := uuid.New()
	contentBlocks := json.RawMessage(`[{"id":"block-1","type":"paragraph","text":"Hello"}]`)

	item, err := scanPost(stubScanner{
		values: []any{
			postID,
			"my-guide",
			authorID,
			"Title",
			"Excerpt",
			"Legacy content",
			"GUIDE",
			"PUBLISHED",
			nil,
			nil,
			"ARTICLE",
			"article_v1",
			int64(1),
			json.RawMessage(`{}`),
			"PREMODERATION",
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			[]string{"travel"},
			10,
			2,
			1,
			3,
			now,
			expiresAt,
			now,
			now,
			nil,
			"GUIDE",
			2,
			contentBlocks,
			"Hello",
			int64(12),
			lastAutosavedAt,
			archivedAt,
			"APPROVED",
		},
	})
	if err != nil {
		t.Fatalf("scan post: %v", err)
	}

	if item.Format != enum.PostFormatGuide {
		t.Fatalf("Format = %q, want %q", item.Format, enum.PostFormatGuide)
	}
	if item.ContentSchemaVersion != 2 {
		t.Fatalf("ContentSchemaVersion = %d, want 2", item.ContentSchemaVersion)
	}
	if string(item.ContentBlocks) != string(contentBlocks) {
		t.Fatalf("ContentBlocks = %s, want %s", item.ContentBlocks, contentBlocks)
	}
	if item.ContentPlainText != "Hello" {
		t.Fatalf("ContentPlainText = %q, want Hello", item.ContentPlainText)
	}
	if item.Revision != 12 {
		t.Fatalf("Revision = %d, want 12", item.Revision)
	}
	if item.ExpiresAt == nil || !item.ExpiresAt.Equal(expiresAt) {
		t.Fatalf("ExpiresAt = %v, want %v", item.ExpiresAt, expiresAt)
	}
	if item.LastAutosavedAt == nil || !item.LastAutosavedAt.Equal(lastAutosavedAt) {
		t.Fatalf("LastAutosavedAt = %v, want %v", item.LastAutosavedAt, lastAutosavedAt)
	}
	if item.ArchivedAt == nil || !item.ArchivedAt.Equal(archivedAt) {
		t.Fatalf("ArchivedAt = %v, want %v", item.ArchivedAt, archivedAt)
	}
	if item.ModerationStatus != enum.ModerationStatusApproved {
		t.Fatalf("ModerationStatus = %q, want %q", item.ModerationStatus, enum.ModerationStatusApproved)
	}
}

func TestRepositoryPersistsContentEngineColumns(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)

	for _, needle := range []string{
		"format",
		"content_schema_version",
		"content_blocks",
		"content_plain_text",
		"revision",
		"expires_at",
		"last_autosaved_at",
		"archived_at",
		"moderation_status",
		"post.Format",
		"post.ContentSchemaVersion",
		"post.ContentBlocks",
		"post.ContentPlainText",
		"post.Revision",
		"post.ExpiresAt",
		"post.LastAutosavedAt",
		"post.ArchivedAt",
		"post.ModerationStatus",
		"item.Format",
		"item.ContentSchemaVersion",
		"item.ContentBlocks",
		"item.ContentPlainText",
		"item.Revision",
		"item.ExpiresAt",
		"item.LastAutosavedAt",
		"item.ArchivedAt",
		"item.ModerationStatus",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("repository source must contain %q", needle)
		}
	}
}

func TestRepositoryUpdatePostUsesRevisionGuard(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)

	for _, needle := range []string{
		"validatePostUpdateRevision(post)",
		"begin update post tx",
		"revision = revision + 1",
		"WHERE id = $1 AND revision = $34 AND deleted_at IS NULL",
		"postUpdateRowsAffectedError(tag.RowsAffected())",
		"commit update post tx",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("repository update must contain %q", needle)
		}
	}
}

func TestRepositoryReviewCommunityPostUpdatesAndAuditsInTransaction(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) ReviewCommunityPost",
		"begin tx",
		"UPDATE posts",
		"revision = revision + 1",
		"WHERE id = $1 AND revision = $33 AND deleted_at IS NULL",
		"INSERT INTO post_community_moderation_decisions",
		"decision.PostRevision",
		"post_moderation.reviewed",
		"insertPostModerationOutboxTx",
		"commit community post review tx",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ReviewCommunityPost source must contain %q", needle)
		}
	}
}

func TestRepositoryCreatePostReportDedupesAndAutoHidesInTransaction(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) CreatePostReport",
		"begin post report tx",
		"INSERT INTO post_reports",
		"ON CONFLICT (post_id, reporter_user_id) WHERE status = 'OPEN'",
		"DO NOTHING",
		"COUNT(*)",
		"FOR UPDATE",
		"insertedReport &&",
		"moderation_status = $2",
		"revision = revision + 1",
		"post_report.created",
		"post_report.auto_hidden",
		"insertPostModerationOutboxTx",
		"commit post report tx",
		"scanPostReport",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreatePostReport source must contain %q", needle)
		}
	}

	migrationBytes, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read post reports migration: %v", err)
	}
	migration := string(migrationBytes)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS post_reports",
		"post_reports_open_report_unique",
		"status = 'OPEN'",
		"idx_post_reports_community_status_created",
		"idx_post_reports_post_status",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("post reports migration must contain %q", needle)
		}
	}
}

func TestRepositoryCreateCommunityReportDedupesOpenReportInTransaction(t *testing.T) {
	source := readRepositorySources(t, "pg_community_repository.go")
	for _, needle := range []string{
		"func (r *PGPostRepository) CreateCommunityReport",
		"begin create community report tx",
		"INSERT INTO community_reports",
		"ON CONFLICT (community_id, reporter_user_id) WHERE status = 'OPEN'",
		"DO UPDATE SET",
		"countOpenCommunityReports",
		"commit create community report tx",
		"scanCommunityReport",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateCommunityReport source must contain %q", needle)
		}
	}

	migrationBytes, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read community reports migration: %v", err)
	}
	migration := string(migrationBytes)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS community_reports",
		"community_reports_open_report_unique",
		"status = 'OPEN'",
		"idx_community_reports_community_status_created",
		"idx_community_reports_reporter_created",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("community reports migration must contain %q", needle)
		}
	}
}

func TestRepositorySetCommunityMutedAuditsAndAdjustsFollowerCount(t *testing.T) {
	source := readRepositorySources(t, "pg_community_repository.go")
	for _, needle := range []string{
		"func (r *PGPostRepository) SetCommunityMuted",
		"begin set community muted tx",
		"FOR UPDATE",
		"CommunityMembershipStatusMuted",
		"CommunityMembershipStatusLeft",
		"INSERT INTO community_memberships",
		"UPDATE community_memberships",
		"membershipStatusFollowerDelta",
		"incrementCommunityFollowerCount",
		"INSERT INTO community_member_status_changes",
		"commit set community muted tx",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("SetCommunityMuted source must contain %q", needle)
		}
	}
}

func TestRepositoryResolvePostReportClosesOpenReportInTransaction(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) ResolvePostReport",
		"begin post report resolution tx",
		"FOR UPDATE",
		"report.Status !=",
		"enum.PostReportStatusOpen",
		"UPDATE post_reports",
		"resolved_by_user_id = $",
		"resolution_note = $",
		"resolved_at = $",
		"AND status = $",
		"post_report.resolved",
		"insertPostModerationOutboxTx",
		"commit post report resolution tx",
		"scanPostReport",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ResolvePostReport source must contain %q", needle)
		}
	}
}

func TestRepositoryPostModerationOutboxMigrationSupportsAuditAndDispatch(t *testing.T) {
	migrationBytes, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read post moderation outbox migration: %v", err)
	}
	migration := string(migrationBytes)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS post_moderation_outbox",
		"event_type text NOT NULL",
		"aggregate_type text NOT NULL",
		"actor_user_id uuid NOT NULL",
		"payload jsonb DEFAULT '{}'::jsonb NOT NULL",
		"status text DEFAULT 'PENDING'::text NOT NULL",
		"post_moderation_outbox_event_type_check",
		"post_moderation.reviewed",
		"post_report.created",
		"post_report.auto_hidden",
		"post_report.resolved",
		"idx_post_moderation_outbox_due",
		"idx_post_moderation_outbox_aggregate",
		"idx_post_moderation_outbox_community_created",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("post moderation outbox migration must contain %q", needle)
		}
	}
}

func TestRepositoryPostModerationOutboxDispatcherMethodsUseSkipLockedAndStatusTransitions(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) ListDuePostModerationOutboxEvents",
		"FROM post_moderation_outbox",
		"FOR UPDATE SKIP LOCKED",
		"scanPostModerationOutboxEvent",
		"func (r *PGPostRepository) MarkPostModerationOutboxDelivered",
		"status = 'DELIVERED'",
		"delivered_at = $2",
		"func (r *PGPostRepository) MarkPostModerationOutboxFailed",
		"attempt_count = attempt_count + 1",
		"status = CASE WHEN attempt_count + 1 >= 20 THEN 'DEAD' ELSE 'PENDING' END",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("post moderation outbox repository source must contain %q", needle)
		}
	}
}

func TestFeedEventsMigrationCreatesIdempotentAppendOnlyLog(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read feed events migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS post_feed_events",
		"event_id uuid NOT NULL",
		"viewer_user_id uuid",
		"event_type text NOT NULL",
		"surface text NOT NULL",
		"tab text NOT NULL",
		"block_id text NOT NULL",
		"block_type text NOT NULL",
		"post_id uuid",
		"community_id uuid",
		"metadata jsonb DEFAULT '{}'::jsonb NOT NULL",
		"post_feed_events_event_id_unique",
		"post_feed_events_event_type_check",
		"idx_post_feed_events_viewer_received",
		"idx_post_feed_events_post_type_received",
		"idx_post_feed_events_surface_type_received",
		"idx_post_feed_events_viewer_post_hide",
		"not_interested",
		"'report'",
		"like",
		"comment",
		"share",
		"dwell",
		"subscribe",
		"idx_post_feed_events_viewer_post_negative",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("feed events migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read feed events rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS post_feed_events") {
		t.Fatalf("rollback migration must drop post_feed_events")
	}
}

func TestFeedEventTypesRepairMigrationExtendsExistingConstraint(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/002_extend_post_feed_event_types.up.sql")
	if err != nil {
		t.Fatalf("read feed event types repair migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"ALTER TABLE post_feed_events",
		"DROP CONSTRAINT IF EXISTS post_feed_events_event_type_check",
		"ADD CONSTRAINT post_feed_events_event_type_check",
		"'impression'::text",
		"'click'::text",
		"'dwell'::text",
		"'like'::text",
		"'comment'::text",
		"'share'::text",
		"'subscribe'::text",
		"'hide'::text",
		"'not_interested'::text",
		"'report'::text",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("feed event types repair migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/002_extend_post_feed_event_types.down.sql")
	if err != nil {
		t.Fatalf("read feed event types repair rollback migration: %v", err)
	}
	rollback := string(down)
	for _, needle := range []string{
		"DROP CONSTRAINT IF EXISTS post_feed_events_event_type_check",
		"ADD CONSTRAINT post_feed_events_event_type_check",
		"'impression'::text",
		"'click'::text",
		"'dwell'::text",
	} {
		if !strings.Contains(rollback, needle) {
			t.Fatalf("feed event types repair rollback migration must contain %q", needle)
		}
	}
}

func TestFeedEntityConversionBlockTypesMigrationExtendsConstraint(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read feed entity block types migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"post_feed_events_block_type_check",
		"post_feed_events_block_type_check",
		"'activity_card'",
		"'place_card'",
		"'tour_card'",
		"'guide_card'",
		"'profile_card'",
		"'my_subscriptions'",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("feed entity block types migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read feed entity block types rollback migration: %v", err)
	}
	rollback := string(down)
	for _, needle := range []string{
		"DROP TABLE IF EXISTS post_feed_events",
	} {
		if !strings.Contains(rollback, needle) {
			t.Fatalf("feed entity block types rollback migration must contain %q", needle)
		}
	}
}

func TestFeedOfficialBlockTypesMigrationExtendsConstraint(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read feed discovery block types migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"post_feed_events_block_type_check",
		"post_feed_events_block_type_check",
		"'official_news_card'",
		"'profile_card'",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("feed discovery block types migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read feed discovery block types rollback migration: %v", err)
	}
	rollback := string(down)
	for _, needle := range []string{
		"DROP TABLE IF EXISTS post_feed_events",
	} {
		if !strings.Contains(rollback, needle) {
			t.Fatalf("feed discovery block types rollback migration must contain %q", needle)
		}
	}
	for _, forbidden := range []string{"'official_news_card'"} {
		if strings.Contains(rollback, forbidden) {
			t.Fatalf("feed discovery rollback must remove %q", forbidden)
		}
	}
}

func TestCommunityRulesPersistenceContract(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read community rules migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"rules text[] DEFAULT '{}'::text[] NOT NULL",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("community rules migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read community rules rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS communities") {
		t.Fatalf("community rules rollback migration must drop communities table")
	}

	source := readRepositorySources(t, "pg_community_repository.go")
	for _, needle := range []string{
		"follower_count, post_count, rules, title_i18n, description_i18n, rules_i18n",
		"&rules",
		"item.Rules = normalizeCommunityRules(rules)",
		"item.RulesI18n = normalizeCommunityRulesI18n(rulesI18nRaw, item.Rules)",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("community repository source must contain %q", needle)
		}
	}
}

func TestRepositoryCreateFeedEventsInsertsBatchIdempotently(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) CreateFeedEvents",
		"INSERT INTO post_feed_events",
		"ON CONFLICT (event_id) DO NOTHING",
		"pgx.Batch",
		"json.Marshal(feedEventMetadataWithRankingExperiment",
		"send feed event batch",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateFeedEvents source must contain %q", needle)
		}
	}
}

func TestRepositoryCreateFeedEventsProjectsReportAsStrongNegativeSignal(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"WHEN event_type = 'report' THEN -6.0000",
		"CASE WHEN event_type IN ('hide', 'report') THEN 1 ELSE 0 END AS hide_count",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateFeedEvents source must contain %q", needle)
		}
	}
}

func TestFeedUserInterestsMigrationCreatesViewerInterestReadModel(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read feed user interests migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS post_feed_user_interests",
		"viewer_user_id uuid NOT NULL",
		"entity_type text NOT NULL",
		"entity_id text NOT NULL",
		"score numeric(10,4) DEFAULT 0 NOT NULL",
		"impression_count bigint DEFAULT 0 NOT NULL",
		"click_count bigint DEFAULT 0 NOT NULL",
		"conversion_count bigint DEFAULT 0 NOT NULL",
		"hide_count bigint DEFAULT 0 NOT NULL",
		"not_interested_count bigint DEFAULT 0 NOT NULL",
		"PRIMARY KEY (viewer_user_id, entity_type, entity_id)",
		"post_feed_user_interests_entity_type_check",
		"idx_post_feed_user_interests_viewer_score",
		"idx_post_feed_user_interests_entity_score",
		"'activity'",
		"'place'",
		"'post'",
		"'author'",
		"'post_profile'",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("feed user interests migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read feed user interests rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS post_feed_user_interests") {
		t.Fatalf("rollback migration must drop post_feed_user_interests")
	}
}

func TestCommunityAffinityMigrationCreatesViewerScopedVisitAggregate(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/005_post_feed_community_affinities.up.sql")
	if err != nil {
		t.Fatalf("read community affinity migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS post_feed_user_community_affinities",
		"PRIMARY KEY (viewer_user_id, community_id)",
		"meaningful_visit_count integer DEFAULT 0 NOT NULL",
		"distinct_visit_day_count integer DEFAULT 0 NOT NULL",
		"first_visit_at timestamp with time zone NOT NULL",
		"last_visit_at timestamp with time zone NOT NULL",
		"last_visit_day date NOT NULL",
		"FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE",
		"idx_post_feed_user_community_affinities_recent",
		"DROP CONSTRAINT IF EXISTS post_feed_events_block_type_check",
		"'community_card'::text",
		"'attraction_card'::text",
		"VALIDATE CONSTRAINT post_feed_events_block_type_check",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("community affinity migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/005_post_feed_community_affinities.down.sql")
	if err != nil {
		t.Fatalf("read community affinity rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS post_feed_user_community_affinities") {
		t.Fatalf("community affinity rollback must drop aggregate table")
	}
}

func TestFeedSocialEdgesMigrationCreatesViewerScopedReadModel(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read feed social edges migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS post_feed_social_edges",
		"viewer_user_id uuid NOT NULL",
		"target_user_id uuid NOT NULL",
		"edge_type text NOT NULL",
		"active boolean DEFAULT true NOT NULL",
		"source_event_id uuid",
		"source_updated_at timestamp with time zone DEFAULT now() NOT NULL",
		"PRIMARY KEY (viewer_user_id, target_user_id, edge_type)",
		"post_feed_social_edges_self_check",
		"post_feed_social_edges_edge_type_check",
		"idx_post_feed_social_edges_viewer_type",
		"idx_post_feed_social_edges_target",
		"'friend'",
		"'following'",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("feed social edges migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read feed social edges rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS post_feed_social_edges") {
		t.Fatalf("rollback migration must drop post_feed_social_edges")
	}
}

func TestFeedSocialRepositoryIgnoresStaleAndNoopEvents(t *testing.T) {
	source, err := os.ReadFile("pg_feed_social_repository.go")
	if err != nil {
		t.Fatalf("read feed social repository source: %v", err)
	}
	sql := string(source)
	for _, needle := range []string{
		"post_feed_social_edges.source_updated_at < EXCLUDED.source_updated_at",
		"post_feed_social_edges.source_updated_at = EXCLUDED.source_updated_at",
		"post_feed_social_edges.active IS DISTINCT FROM true",
		"post_feed_social_edges.active IS DISTINCT FROM false",
		"post_feed_social_edges.source_event_id IS DISTINCT FROM EXCLUDED.source_event_id",
	} {
		if !strings.Contains(sql, needle) {
			t.Fatalf("feed social repository SQL must contain %q", needle)
		}
	}
}

func TestFeedInterestAffinityTypesMigrationExtendsConstraint(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read feed interest affinity types migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"post_feed_user_interests_entity_type_check",
		"post_feed_user_interests_entity_type_check",
		"'city'",
		"'country'",
		"'category'",
		"'tag'",
		"'post_profile'",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("feed interest affinity types migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read feed interest affinity types rollback migration: %v", err)
	}
	rollback := string(down)
	for _, needle := range []string{
		"DROP TABLE IF EXISTS post_feed_user_interests",
	} {
		if !strings.Contains(rollback, needle) {
			t.Fatalf("feed interest affinity types rollback migration must contain %q", needle)
		}
	}
}

func TestRepositoryCreateFeedEventsProjectsInterestSignalsOnlyForInsertedEvents(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"WITH inserted_feed_event AS",
		"ON CONFLICT (event_id) DO NOTHING",
		"RETURNING viewer_user_id, event_type, post_id, occurred_at, received_at, metadata",
		"INSERT INTO post_feed_user_interests",
		"metadata->>'entityType'",
		"metadata->>'entityId'",
		"metadata->>'action' = 'conversion'",
		"conversion_count",
		"ON CONFLICT (viewer_user_id, entity_type, entity_id) DO UPDATE",
		"LEAST(100, GREATEST(-100, post_feed_user_interests.score + EXCLUDED.score))",
		"post_feed_user_interests.metadata || EXCLUDED.metadata",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateFeedEvents interest projection source must contain %q", needle)
		}
	}
}

func TestRepositoryCreateFeedEventsAggregatesOnlyMeaningfulCommunityVisits(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"community_visit_signal AS",
		"metadata->>'source' = 'community_profile_visit'",
		"metadata->>'entityType' = 'community'",
		"(metadata->>'dwellMs')::bigint >= $17::bigint",
		"INSERT INTO post_feed_user_community_affinities",
		"meaningful_visit_count",
		"distinct_visit_day_count",
		"post_feed_user_community_affinities.first_visit_at + make_interval(secs => $19::int)",
		"post_feed_user_community_affinities.last_visit_at + make_interval(secs => $18::int)",
		"FROM upserted_community_affinity accepted_community_visit",
		"WHEN event_type = 'click' AND metadata->>'entityType' = 'community' THEN 0.0000",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateFeedEvents meaningful community visit projection must contain %q", needle)
		}
	}
}

func TestRepositoryCreateFeedEventsProjectsDerivedAffinitySignals(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"derived_interest_signal AS",
		"metadata->>'cityId'",
		"metadata->>'countryCode'",
		"COALESCE(NULLIF(metadata->>'categorySlug', ''), NULLIF(metadata->>'category', ''))",
		"JOIN posts event_post ON event_post.id = signal.post_id",
		"'author' AS entity_type",
		"event_post.author_user_id::text",
		"score * 0.55",
		"jsonb_array_elements_text(signal.metadata->'tags')",
		"'city'",
		"'country'",
		"'category'",
		"'author'",
		"'tag'",
		"score * 0.45",
		"score * 0.25",
		"score * 0.35",
		"score * 0.20",
		"parentEntityType",
		"parentEntityId",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateFeedEvents derived affinity projection source must contain %q", needle)
		}
	}
}

func TestRepositoryCreateFeedEventsProjectsSemanticTagSignals(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"jsonb_array_elements_text(signal.metadata->'tags')",
		"jsonb_array_elements_text(signal.metadata->'semanticTags')",
		"jsonb_array_elements_text(signal.metadata->'interestTags')",
		"jsonb_array_elements_text(signal.metadata->'guideSpecialties')",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateFeedEvents semantic tag projection source must contain %q", needle)
		}
	}
}

func TestRepositoryCreateFeedEventsProjectsRicherSemanticMappings(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"COALESCE(NULLIF(metadata->>'profileUserId', ''), NULLIF(metadata->>'profileId', ''))",
		"jsonb_array_elements_text(signal.metadata->'postTags')",
		"jsonb_array_elements_text(signal.metadata->'placeTags')",
		"jsonb_array_elements_text(signal.metadata->'seasonalTags')",
		"jsonb_array_elements_text(signal.metadata->'localIntentTags')",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateFeedEvents richer semantic mapping source must contain %q", needle)
		}
	}
}

func TestRepositoryCreateFeedEventsProjectsPostProfileAffinitySignals(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"'post_profile' AS entity_type",
		"COALESCE(NULLIF(signal.metadata->>'postProfileKey', ''), NULLIF(profile_post.post_profile_key, ''))",
		"JOIN posts profile_post ON profile_post.id = signal.post_id",
		"score * 0.30",
		"'post_profile'",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateFeedEvents post profile affinity source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsBoostsLocalSocialEdgesWithoutUserServiceReadPath(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_ranking_policy.go")
	if err != nil {
		t.Fatalf("read feed ranking policy source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"post_feed_social_edges social_friend",
		"social_friend.viewer_user_id = $%d",
		"social_friend.target_user_id = s.author_user_id",
		"social_friend.edge_type = 'friend'",
		"social_friend.active = true",
		"post_feed_social_edges social_following",
		"social_following.edge_type = 'following'",
		"social_following.active = true",
		"SocialFriendBoostHours",
		"SocialFollowingBoostHours",
		"socialEdgeScoreExpression",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("feed ranking policy social source must contain %q", needle)
		}
	}
}

func TestRepositoryListsViewerInterestsForRanking(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) ListFeedUserInterests",
		"FROM post_feed_user_interests",
		"viewer_user_id = $1",
		"entity_type = ANY",
		"ORDER BY score DESC, last_event_at DESC",
		"scanFeedUserInterest",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedUserInterests source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedQualityMetricsAggregatesSafeDashboardCounters(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) ListFeedQualityMetrics",
		"WITH grouped_events AS",
		"report_metrics AS",
		"FROM post_feed_events",
		"LEFT JOIN posts quality_post",
		"tab",
		"COALESCE(NULLIF(post_feed_events.metadata->>'rankingExperiment', ''), 'control') AS ranking_experiment",
		"COALESCE(NULLIF(post_feed_events.metadata->>'candidateSource', ''), '') AS candidate_source",
		"COALESCE(NULLIF(post_feed_events.metadata->>'postProfileKey', ''), NULLIF(quality_post.post_profile_key, ''), '') AS post_profile",
		"COALESCE(COALESCE(post_feed_events.community_id, quality_post.community_id)::text, '') AS community_id",
		"COALESCE(NULLIF(post_feed_events.metadata->>'action', ''), post_feed_events.event_type) AS action",
		"COUNT(DISTINCT post_feed_events.viewer_user_id) FILTER",
		"impression_count",
		"click_count",
		"dwell_count",
		"avg_dwell_ms",
		"like_count",
		"comment_count",
		"share_count",
		"subscribe_count",
		"conversion_count",
		"hide_count",
		"not_interested_count",
		"COUNT(*) FILTER (WHERE post_feed_events.event_type = 'report') AS feed_report_count",
		"post_reports",
		"grouped_events.feed_report_count + COALESCE(report_metrics.report_count, 0) AS report_count",
		"GROUP BY 1, 2, 3, 4, 5, 6, 7, 8",
		"report_metrics.candidate_source = grouped_events.candidate_source",
		"report_metrics.community_id = grouped_events.community_id",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedQualityMetrics source must contain %q", needle)
		}
	}
}

func TestFeedReadModelMigrationCreatesProjectedItems(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read post feed items migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS post_feed_items",
		"post_id uuid NOT NULL",
		"author_user_id uuid NOT NULL",
		"community_id uuid",
		"is_visible boolean DEFAULT false NOT NULL",
		"published_at timestamp with time zone NOT NULL",
		"rank_published_at timestamp with time zone NOT NULL",
		"post_revision bigint NOT NULL",
		"idx_post_feed_items_latest",
		"idx_post_feed_items_community_latest",
		"is_visible = true",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("post feed items migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read post feed items rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS post_feed_items") {
		t.Fatalf("rollback migration must drop post_feed_items")
	}
}

func TestFeedProjectionOutboxMigrationCreatesAsyncProjectorBoundary(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read post feed projection outbox migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS post_feed_projection_outbox",
		"event_type text NOT NULL",
		"post_id uuid NOT NULL",
		"post_revision bigint NOT NULL",
		"payload jsonb DEFAULT '{}'::jsonb NOT NULL",
		"post_feed_projection_outbox_unique_event",
		"post_feed_projection_outbox_event_type_check",
		"post_feed_projection_outbox_status_check",
		"idx_post_feed_projection_outbox_due",
		"idx_post_feed_projection_outbox_post_created",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("post feed projection outbox migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read post feed projection outbox rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS post_feed_projection_outbox") {
		t.Fatalf("rollback migration must drop post_feed_projection_outbox")
	}
}

func TestPostActivityIntentMigrationCreatesAsyncActivityBoundary(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read post activity intent migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS post_activity_intents",
		"event_type text NOT NULL",
		"idempotency_key text NOT NULL",
		"activity_creation_requested",
		"post_activity_intents_idempotency_key_key",
		"idx_post_activity_intents_due",
		"idx_post_activity_intents_post_created",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("post activity intent migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read post activity intent rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS post_activity_intents") {
		t.Fatalf("rollback migration must drop post_activity_intents")
	}
}

func TestRepositoryListFeedPostsUsesReadModelJoin(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) ListFeedPosts",
		"FROM post_feed_items fi",
		"JOIN posts s ON s.id = fi.post_id",
		"fi.is_visible = TRUE",
		"fi.rank_published_at",
		"fi.post_id",
		"scanPost(feedPostScanner",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsCanDisablePersonalizedRanking(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"if !filter.DisablePersonalizedRanking",
		"rankingViewerUserIDPos = 0",
		"policy.viewerRankedAtExpression(rankingViewerUserIDPos",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("non-personalized feed ranking source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsMatchesFollowingByCommunityInstance(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"LEFT JOIN community_instances ci ON ci.id = s.community_instance_id",
		`effectiveCommunityIDExpression := "COALESCE(fi.community_id, s.community_id, ci.community_id)"`,
		"m.community_id = %s",
		"%s AS community_id",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts following source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsLeavesDiversityToCursorAwareMixer(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"WITH ranked_feed_candidates AS",
		"FROM ranked_feed_candidates",
		"ORDER BY feed_ranked_at DESC, id DESC",
		"LIMIT $%d OFFSET $%d",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts cursor source must contain %q", needle)
		}
	}
	for _, forbidden := range []string{
		"ROW_NUMBER() OVER (PARTITION BY",
		"community_row_number <=",
		"category_row_number <=",
		"author_row_number <=",
		"profile_row_number <=",
	} {
		if strings.Contains(source, forbidden) {
			t.Fatalf("ListFeedPosts must not pre-filter candidates with %q", forbidden)
		}
	}
}

func TestRepositoryListFeedPostsExcludesViewerOwnedForYouCandidatesBeforePagination(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		`candidateSource := strings.TrimSpace(filter.CandidateSource)`,
		`candidateSource != model.PostCandidateSourceFollowing`,
		`s.author_user_id <> $%d`,
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts viewer-owned filter must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsExcludesViewerHiddenPosts(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"filter.ViewerUserID",
		"NOT EXISTS",
		"FROM post_feed_events hidden",
		"hidden.viewer_user_id",
		"hidden.post_id = fi.post_id",
		"hidden.event_type IN ('hide', 'report')",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsExcludesViewerMutedCommunities(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"FROM community_memberships muted_community",
		"muted_community.community_id",
		"muted_community.user_id",
		"muted_community.status = 'MUTED'",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsDownranksViewerNegativeFeedback(t *testing.T) {
	source := readRepositorySources(t, "pg_feed_repository.go", "pg_feed_ranking_policy.go")
	for _, needle := range []string{
		"feed_ranked_at",
		"FeedRankedAt",
		"FROM post_feed_events negative",
		"negative.viewer_user_id",
		"negative.post_id = fi.post_id",
		"negative.event_type IN ('not_interested', 'report')",
		"directNegativeFeedbackPenaltyExpression",
		"DirectNegativeFeedbackDecayWindow",
		"negative.received_at >= NOW() -",
		"feedPostScanner",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsAppliesBoundedViewerInterestRanking(t *testing.T) {
	source := readRepositorySources(t, "pg_feed_repository.go", "pg_feed_ranking_policy.go")
	for _, needle := range []string{
		"LEFT JOIN post_feed_user_interests post_interest",
		"post_interest.viewer_user_id",
		"post_interest.entity_type = 'post'",
		"post_interest.entity_id = fi.post_id::text",
		"LEFT JOIN post_feed_user_interests community_interest",
		"community_interest.entity_type = 'community'",
		"community_interest.entity_id = COALESCE(fi.community_id, s.community_id, ci.community_id)::text",
		"LEFT JOIN post_feed_user_community_affinities frequent_community_affinity",
		"LEFT JOIN post_feed_user_interests profile_interest",
		"profile_interest.entity_type = 'post_profile'",
		"profile_interest.entity_id = lower(s.post_profile_key)",
		"LEFT JOIN post_feed_user_interests author_interest",
		"author_interest.entity_type = 'author'",
		"author_interest.entity_id = s.author_user_id::text",
		`p.interestScoreExpression("post_interest")`,
		`p.communityInterestScoreExpression("community_interest")`,
		"p.frequentCommunityAffinityScoreExpression()",
		`p.interestScoreExpression("profile_interest")`,
		`p.interestScoreExpression("author_interest")`,
		`p.interestScoreExpression("city_interest")`,
		`p.interestScoreExpression("country_interest")`,
		`p.interestScoreExpression("category_interest")`,
		`p.interestScoreExpression("tag_interest")`,
		"NegativeInterestDecayWindow",
		"NegativeInterestMinWeight",
		"LEAST(%d, GREATEST(-%d",
		"make_interval(hours =>",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts personalized ranking source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsKeepsPersonalizedCursorOnRankExpression(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"feedRankJoins",
		"feedRankedAtExpression",
		"FeedCursorPublishedAt",
		"%s < $%d",
		"(%s = $%d AND fi.post_id < $%d)",
		"feed_ranked_at",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts cursor/ranking source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsUsesStableInterestSnapshot(t *testing.T) {
	source := readRepositorySources(t, "pg_feed_repository.go", "pg_feed_ranking_policy.go")
	for _, needle := range []string{
		"freshnessSQL := p.durationSQL(p.InterestFreshnessDelay)",
		"post_interest.updated_at < NOW() - %s",
		"community_interest.updated_at < NOW() - %s",
		"author_interest.updated_at < NOW() - %s",
		"city_interest.updated_at < NOW() - %s",
		"country_interest.updated_at < NOW() - %s",
		"category_interest.updated_at < NOW() - %s",
		"tag_interest.updated_at < NOW() - %s",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts stable interest snapshot source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsMapsAffinityInterestsToPostAttributes(t *testing.T) {
	source := readRepositorySources(t, "pg_feed_repository.go", "pg_feed_ranking_policy.go")
	for _, needle := range []string{
		"LEFT JOIN post_feed_user_interests city_interest",
		"city_interest.entity_type = 'city'",
		"city_interest.entity_id = lower(s.place_city_id)",
		"LEFT JOIN post_feed_user_interests country_interest",
		"country_interest.entity_type = 'country'",
		"country_interest.entity_id = lower(s.place_country_code)",
		"LEFT JOIN post_feed_user_interests category_interest",
		"category_interest.entity_type = 'category'",
		"category_interest.entity_id = lower(s.category)",
		"LEFT JOIN post_feed_user_interests profile_interest",
		"profile_interest.entity_type = 'post_profile'",
		"profile_interest.entity_id = lower(s.post_profile_key)",
		"LEFT JOIN post_feed_user_interests author_interest",
		"author_interest.entity_type = 'author'",
		"author_interest.entity_id = s.author_user_id::text",
		"LEFT JOIN LATERAL",
		"FROM post_feed_user_interests tag_interest",
		"tag_interest.entity_type = 'tag'",
		"unnest(COALESCE(s.tags, ARRAY[]::text[]))",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts affinity mapping source must contain %q", needle)
		}
	}
}

func TestRepositoryListFeedPostsAppliesExplicitCandidateSourceFilters(t *testing.T) {
	source := readRepositorySources(t, "pg_feed_repository.go")
	for _, needle := range []string{
		"filter.CandidateSource",
		"case model.PostCandidateSourceSocial",
		"FROM post_feed_social_edges source_social",
		"source_social.target_user_id = s.author_user_id",
		"source_social.edge_type IN ('friend', 'following')",
		"case model.PostCandidateSourceSystem",
		"s.post_profile_key = 'article_v1'",
		"official_updates",
		"travel_alerts",
		"local_news",
		"case model.PostCandidateSourceGeo",
		"COALESCE(s.place_city_id, ci.city_id, '')",
		"COALESCE(s.place_country_code, ci.country_code, '')",
		"case model.PostCandidateSourceInterest",
		"FROM post_feed_user_interests source_interest",
		"source_interest.score > 0",
		"source_interest.score >= %s",
		"source_interest.entity_type = 'post_profile'",
		"source_interest.entity_type = 'tag'",
		"FROM post_feed_user_community_affinities frequent_source_community",
		"frequent_source_community.meaningful_visit_count >= %d",
		"frequent_source_community.distinct_visit_day_count >= %d",
		"case model.PostCandidateSourceColdStart",
		"FROM post_feed_user_interests cold_start_source_interest",
		"NOT EXISTS",
		"cold_start_source_interest.score > 0",
		"filter.ColdStartRandomSeed > 0",
		"hashtextextended(fi.post_id::text",
		"coldStartRandomRankWindowSeconds",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListFeedPosts candidate source filter must contain %q", needle)
		}
	}
}

func TestRepositoryProjectsPostFeedItemsInPostWriteTransactions(t *testing.T) {
	postSourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read post repository source: %v", err)
	}
	feedSourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	postSource := string(postSourceBytes)
	feedSource := string(feedSourceBytes)
	for _, needle := range []string{
		"upsertPostFeedItemTx(ctx, tx, post)",
		"syncPostFeedItemTx(ctx, tx, post)",
		"deletePostFeedItemTx(ctx, tx, post.ID)",
	} {
		if !strings.Contains(postSource+feedSource, needle) {
			t.Fatalf("feed projection source must contain %q", needle)
		}
	}
}

func TestRepositoryEnqueuesPostFeedProjectionOutboxInPostWriteTransactions(t *testing.T) {
	postSourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read post repository source: %v", err)
	}
	feedSourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(postSourceBytes) + string(feedSourceBytes)
	for _, needle := range []string{
		"enqueuePostFeedProjectionForPostTx(ctx, tx, post)",
		"enqueuePostFeedProjectionDeleteTx(ctx, tx, post.ID, post.Revision",
		"enqueuePostFeedProjectionDeleteTx(ctx, tx, postID, deletedPost.Revision",
		"INSERT INTO post_feed_projection_outbox",
		"ON CONFLICT (post_id, post_revision, event_type) DO NOTHING",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("feed projection outbox source must contain %q", needle)
		}
	}
}

func TestRepositoryPostFeedProjectionOutboxMethodsUseSkipLockedAndStatusTransitions(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) ListDuePostFeedProjectionEvents",
		"FROM post_feed_projection_outbox",
		"FOR UPDATE SKIP LOCKED",
		"scanPostFeedProjectionOutboxEvent",
		"func (r *PGPostRepository) ProjectPostFeedItem",
		"func (r *PGPostRepository) MarkPostFeedProjectionOutboxDelivered",
		"status = 'DELIVERED'",
		"func (r *PGPostRepository) MarkPostFeedProjectionOutboxFailed",
		"attempt_count = attempt_count + 1",
		"status = CASE WHEN attempt_count + 1 >= 20 THEN 'DEAD' ELSE 'PENDING' END",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("post feed projection outbox source must contain %q", needle)
		}
	}
}

func TestRepositoryUpdateCommunityMembershipRoleAuditsInTransaction(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_community_repository.go")
	if err != nil {
		t.Fatalf("read community repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) UpdateCommunityMembershipRole",
		"begin update community membership role tx",
		"FOR UPDATE",
		"INSERT INTO community_member_role_changes",
		"actorUserID",
		"previous_role",
		"next_role",
		"commit update community membership role tx",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("UpdateCommunityMembershipRole source must contain %q", needle)
		}
	}
}

func TestRepositoryFollowCommunityDoesNotReactivateMutedMembership(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_community_repository.go")
	if err != nil {
		t.Fatalf("read community repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) FollowCommunity",
		"enum.CommunityMembershipStatusMuted",
		"commit restricted follow community tx",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("FollowCommunity source must contain %q", needle)
		}
	}
}

func TestFeedKeysetIndexesMigrationMatchesListPostsCursorSort(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read feed keyset index migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"idx_posts_feed_latest_keyset",
		"idx_posts_feed_community_latest_keyset",
		"idx_community_memberships_user_status_community",
		"COALESCE(published_at, created_at)",
		"archived_at IS NULL",
		"deleted_at IS NULL",
		"community_id IS NOT NULL",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("feed keyset index migration must contain %q", needle)
		}
	}
}

func TestRepositoryCreateCommentEnforcesRateLimitInsideTransaction(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read post repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) CreateComment",
		"begin comment tx",
		"pg_advisory_xact_lock",
		"GetLatestActiveCommentByAuthor",
		"port.ErrPostCommentRateLimited",
		"insert post comment",
		"increment post comment count",
		"commit create comment tx",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateComment source must contain %q", needle)
		}
	}
}

func TestRepositoryUpdateCommunityMembershipStatusAuditsAndUpdatesFollowerCountInTransaction(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_community_repository.go")
	if err != nil {
		t.Fatalf("read community repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) UpdateCommunityMembershipStatus",
		"begin update community membership status tx",
		"lockActiveCommunityFollowerCount",
		"FOR UPDATE",
		"membershipStatusFollowerDelta",
		"incrementCommunityFollowerCount",
		"INSERT INTO community_member_status_changes",
		"previous_status",
		"next_status",
		"commit update community membership status tx",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("UpdateCommunityMembershipStatus source must contain %q", needle)
		}
	}
}

func TestCommunityModerationDecisionsMigrationCreatesAuditTable(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read moderation decisions migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS post_community_moderation_decisions",
		"moderator_user_id uuid NOT NULL",
		"previous_status text NOT NULL",
		"next_status text NOT NULL",
		"post_revision bigint NOT NULL",
		"chk_post_community_moderation_decisions_decision",
		"idx_post_community_moderation_decisions_post_created",
		"idx_post_community_moderation_decisions_moderator_created",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("moderation decisions migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read moderation decisions rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS post_community_moderation_decisions") {
		t.Fatalf("rollback migration must drop post_community_moderation_decisions")
	}
}

func TestCommunityMemberStatusChangesMigrationCreatesAuditTable(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read member status changes migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS community_member_status_changes",
		"community_id uuid NOT NULL",
		"target_user_id uuid NOT NULL",
		"actor_user_id uuid NOT NULL",
		"previous_status text NOT NULL",
		"next_status text NOT NULL",
		"chk_community_member_status_changes_previous_status",
		"idx_community_member_status_changes_target_created",
		"idx_community_member_status_changes_actor_created",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("member status changes migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read member status changes rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS community_member_status_changes") {
		t.Fatalf("rollback migration must drop community_member_status_changes")
	}
}

func TestCommunityMemberRoleChangesMigrationCreatesAuditTable(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read member role changes migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS community_member_role_changes",
		"community_id uuid NOT NULL",
		"target_user_id uuid NOT NULL",
		"actor_user_id uuid NOT NULL",
		"previous_role text NOT NULL",
		"next_role text NOT NULL",
		"chk_community_member_role_changes_previous_role",
		"idx_community_member_role_changes_target_created",
		"idx_community_member_role_changes_actor_created",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("member role changes migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read member role changes rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS community_member_role_changes") {
		t.Fatalf("rollback migration must drop community_member_role_changes")
	}
}

func TestRepositoryListsCommunityMemberRoleChangesByTarget(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_community_repository.go")
	if err != nil {
		t.Fatalf("read community repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) ListCommunityMemberRoleChanges",
		"FROM community_member_role_changes",
		"WHERE community_id = $1 AND target_user_id = $2",
		"ORDER BY created_at DESC",
		"LIMIT $3 OFFSET $4",
		"scanCommunityMemberRoleChange",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListCommunityMemberRoleChanges source must contain %q", needle)
		}
	}
}

func TestRepositoryListsCommunityPostModerationDecisionsByPostAndCommunity(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"func (r *PGPostRepository) ListCommunityPostModerationDecisions",
		"FROM post_community_moderation_decisions",
		"WHERE post_id = $1 AND community_id = $2",
		"ORDER BY created_at DESC",
		"LIMIT $3 OFFSET $4",
		"scanPostModerationDecision",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("ListCommunityPostModerationDecisions source must contain %q", needle)
		}
	}
}

func TestScanPostModerationDecisionReadsAuditFields(t *testing.T) {
	now := time.Now().UTC()
	decisionID := uuid.New()
	postID := uuid.New()
	communityID := uuid.New()
	moderatorID := uuid.New()

	item, err := scanPostModerationDecision(stubScanner{
		values: []any{
			decisionID,
			postID,
			communityID,
			moderatorID,
			"REJECT",
			"PENDING",
			"REJECTED",
			int64(12),
			"Off-topic",
			now,
		},
	})
	if err != nil {
		t.Fatalf("scan moderation decision: %v", err)
	}
	if item.ID != decisionID ||
		item.PostID != postID ||
		item.CommunityID != communityID ||
		item.ModeratorUserID != moderatorID ||
		item.Decision != enum.PostModerationDecisionReject ||
		item.PreviousStatus != enum.ModerationStatusPending ||
		item.NextStatus != enum.ModerationStatusRejected ||
		item.PostRevision != 12 ||
		item.Reason != "Off-topic" ||
		!item.CreatedAt.Equal(now) {
		t.Fatalf("scanned moderation decision mismatch: %+v", item)
	}
}

func TestValidatePostUpdateRevisionFailsClosedForMissingRevision(t *testing.T) {
	tests := map[string]int64{
		"zero":     0,
		"negative": -1,
	}

	for name, revision := range tests {
		t.Run(name, func(t *testing.T) {
			err := validatePostUpdateRevision(&model.Post{Revision: revision})
			if !errors.Is(err, port.ErrPostRevisionConflict) {
				t.Fatalf("validatePostUpdateRevision error = %v, want %v", err, port.ErrPostRevisionConflict)
			}
		})
	}
}

func TestValidatePostUpdateRevisionAcceptsPositiveRevision(t *testing.T) {
	if err := validatePostUpdateRevision(&model.Post{Revision: 1}); err != nil {
		t.Fatalf("validatePostUpdateRevision returned error: %v", err)
	}
}

func TestPostUpdateRowsAffectedErrorMapsZeroRowsToRevisionConflict(t *testing.T) {
	err := postUpdateRowsAffectedError(0)
	if !errors.Is(err, port.ErrPostRevisionConflict) {
		t.Fatalf("postUpdateRowsAffectedError(0) = %v, want %v", err, port.ErrPostRevisionConflict)
	}

	if err := postUpdateRowsAffectedError(1); err != nil {
		t.Fatalf("postUpdateRowsAffectedError(1) returned error: %v", err)
	}
}

func TestPublicPostVisibilityClausesMatchFeedIndexPredicate(t *testing.T) {
	args, clauses := appendPublicPostVisibilityClauses([]any{"author-id"}, []string{"author_user_id = $1"})

	if len(args) != 3 {
		t.Fatalf("args length = %d, want 3", len(args))
	}
	if args[1] != string(enum.PostStatusPublished) {
		t.Fatalf("status arg = %v, want %s", args[1], enum.PostStatusPublished)
	}
	moderationStatuses, ok := args[2].([]string)
	if !ok {
		t.Fatalf("moderation arg has type %T, want []string", args[2])
	}
	wantModerationStatuses := []string{
		string(enum.ModerationStatusNotRequired),
		string(enum.ModerationStatusApproved),
	}
	if len(moderationStatuses) != len(wantModerationStatuses) {
		t.Fatalf("moderation statuses = %v, want %v", moderationStatuses, wantModerationStatuses)
	}
	for i, want := range wantModerationStatuses {
		if moderationStatuses[i] != want {
			t.Fatalf("moderation statuses = %v, want %v", moderationStatuses, wantModerationStatuses)
		}
	}

	wantClauses := []string{
		"author_user_id = $1",
		"deleted_at IS NULL",
		"archived_at IS NULL",
		"status = $2",
		"COALESCE(moderation_status, 'NOT_REQUIRED') = ANY($3)",
		"COALESCE(media_status, 'READY') = 'READY'",
		"(expires_at IS NULL OR expires_at > NOW())",
	}
	if len(clauses) != len(wantClauses) {
		t.Fatalf("clauses = %v, want %v", clauses, wantClauses)
	}
	for i, want := range wantClauses {
		if clauses[i] != want {
			t.Fatalf("clauses = %v, want %v", clauses, wantClauses)
		}
	}
}

func TestPostCommunityPostCountDeltas(t *testing.T) {
	communityID := uuid.New()
	otherCommunityID := uuid.New()
	now := time.Now().UTC()

	visiblePost := func(communityID *uuid.UUID) *model.Post {
		return &model.Post{
			ID:               uuid.New(),
			CommunityID:      communityID,
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusApproved,
			PublishedAt:      &now,
		}
	}
	pendingPost := func(communityID *uuid.UUID) *model.Post {
		post := visiblePost(communityID)
		post.ModerationStatus = enum.ModerationStatusPending
		return post
	}
	archivedPost := func(communityID *uuid.UUID) *model.Post {
		post := visiblePost(communityID)
		post.ArchivedAt = &now
		return post
	}

	tests := map[string]struct {
		previous *model.Post
		next     *model.Post
		want     map[uuid.UUID]int
	}{
		"visible_community_post_created": {
			next: visiblePost(&communityID),
			want: map[uuid.UUID]int{communityID: 1},
		},
		"pending_community_post_created": {
			next: pendingPost(&communityID),
			want: map[uuid.UUID]int{},
		},
		"pending_post_approved": {
			previous: pendingPost(&communityID),
			next:     visiblePost(&communityID),
			want:     map[uuid.UUID]int{communityID: 1},
		},
		"visible_post_archived": {
			previous: visiblePost(&communityID),
			next:     archivedPost(&communityID),
			want:     map[uuid.UUID]int{communityID: -1},
		},
		"visible_post_moved_between_communities": {
			previous: visiblePost(&communityID),
			next:     visiblePost(&otherCommunityID),
			want: map[uuid.UUID]int{
				communityID:      -1,
				otherCommunityID: 1,
			},
		},
		"personal_post_ignored": {
			next: visiblePost(nil),
			want: map[uuid.UUID]int{},
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			got := postCommunityPostCountDeltas(tt.previous, tt.next)
			if len(got) != len(tt.want) {
				t.Fatalf("deltas = %v, want %v", got, tt.want)
			}
			for communityID, want := range tt.want {
				if got[communityID] != want {
					t.Fatalf("deltas = %v, want %v", got, tt.want)
				}
			}
		})
	}
}

func TestRepositoryMaintainsCommunityPostCountInPostTransactions(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)
	for _, needle := range []string{
		"postCommunityPostCountDeltas(nil, post)",
		"lockPostForCommunityPostCount(ctx, tx, post.ID, post.Revision)",
		"postCommunityPostCountDeltas(previousPost, post)",
		"lockOwnedPostForCommunityPostCount(ctx, tx, postID, authorUserID)",
		"applyCommunityPostCountDeltas(ctx, tx,",
		"incrementCommunityPostCount",
		"sort.Slice",
		"FOR UPDATE",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("repository source must contain %q", needle)
		}
	}
}

func TestRepositoryListAndCountSupportArchivedStatusFilters(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)
	countStart := strings.Index(source, "func (r *PGPostRepository) CountPosts")
	if countStart < 0 {
		t.Fatal("repository source must define CountPosts")
	}
	countSource := source[countStart:]

	for _, needle := range []string{
		"filter.ExcludeArchived",
		"archived_at IS NULL",
		"filter.ArchivedOnly",
		"archived_at IS NOT NULL",
		"filter.Formats",
		"format = ANY($",
		"status = $",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("repository source must contain %q", needle)
		}
	}
	if strings.Count(source, "if filter.ExcludeArchived") < 2 {
		t.Fatal("ListPosts and CountPosts must both apply filter.ExcludeArchived")
	}
	for _, needle := range []string{
		"filter.ExcludeArchived",
		"archived_at IS NULL",
		"filter.Formats",
		"format = ANY($",
	} {
		if !strings.Contains(countSource, needle) {
			t.Fatalf("CountPosts source must contain %q", needle)
		}
	}
}

func TestRepositoryAvoidsWrappedCountryAndCityPredicates(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_post_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)

	for _, forbidden := range []string{
		"UPPER(COALESCE(place_country_code",
		"LOWER(COALESCE(place_city_id",
	} {
		if strings.Contains(source, forbidden) {
			t.Fatalf("repository hot predicate should not contain %q", forbidden)
		}
	}
	for _, needle := range []string{
		"place_country_code = $",
		"place_city_id = $",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("repository source must contain index-friendly predicate %q", needle)
		}
	}
}

func TestArchivedStatusMigrationExpandsPostStatusCheck(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read archived status migration: %v", err)
	}
	upSQL := string(up)
	if !strings.Contains(upSQL, "ARCHIVED") || !strings.Contains(upSQL, "chk_posts_status") {
		t.Fatalf("archived status migration must update chk_posts_status with ARCHIVED")
	}
	for _, needle := range []string{
		"chk_posts_status",
		"'ARCHIVED'::text",
	} {
		if !strings.Contains(upSQL, needle) {
			t.Fatalf("baseline migration must contain archived post status contract %q", needle)
		}
	}
}

func TestArchivedStatusDownMigrationDropsPostsTable(t *testing.T) {
	down, err := os.ReadFile("../../../migrations/001_init.down.sql")
	if err != nil {
		t.Fatalf("read archived status down migration: %v", err)
	}
	downSQL := string(down)
	for _, needle := range []string{
		"DROP TABLE IF EXISTS posts",
	} {
		if !strings.Contains(downSQL, needle) {
			t.Fatalf("baseline down migration must contain %q", needle)
		}
	}
}

type stubScanner struct {
	values []any
}

func (s stubScanner) Scan(dest ...any) error {
	for i := range dest {
		if i >= len(s.values) {
			return nil
		}
		if err := assignScanValue(dest[i], s.values[i]); err != nil {
			return err
		}
	}
	return nil
}

func assignScanValue(dest any, value any) error {
	if value == nil {
		return nil
	}

	switch d := dest.(type) {
	case *uuid.UUID:
		*d = value.(uuid.UUID)
	case *string:
		*d = value.(string)
	case **string:
		v := value.(string)
		*d = &v
	case *[]string:
		*d = value.([]string)
	case *int:
		*d = value.(int)
	case *int64:
		*d = value.(int64)
	case *[]byte:
		switch v := value.(type) {
		case []byte:
			*d = append((*d)[:0], v...)
		case json.RawMessage:
			*d = append((*d)[:0], v...)
		}
	case *json.RawMessage:
		*d = append((*d)[:0], value.(json.RawMessage)...)
	case *time.Time:
		*d = value.(time.Time)
	case **time.Time:
		v := value.(time.Time)
		*d = &v
	case **uuid.UUID:
		v := value.(uuid.UUID)
		*d = &v
	default:
		if scanner, ok := dest.(interface{ Scan(any) error }); ok {
			return scanner.Scan(value)
		}
	}
	return nil
}
