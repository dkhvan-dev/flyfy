package repository

import (
	"encoding/json"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/stories-service/internal/domain/enum"
	"kz/inflap/backend/services/stories-service/internal/domain/model"
	"kz/inflap/backend/services/stories-service/internal/domain/port"
)

func TestStoryListOrderBySupportsSortDirections(t *testing.T) {
	tests := map[string]string{
		"latest":         "published_at DESC NULLS LAST, created_at DESC",
		"latest_desc":    "published_at DESC NULLS LAST, created_at DESC",
		"latest_asc":     "published_at ASC NULLS LAST, created_at ASC",
		"popular":        "view_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"popular_desc":   "view_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"popular_asc":    "view_count ASC, published_at ASC NULLS LAST, created_at ASC",
		"discussed":      "comment_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"discussed_desc": "comment_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"discussed_asc":  "comment_count ASC, published_at ASC NULLS LAST, created_at ASC",
		"unknown":        "published_at DESC NULLS LAST, created_at DESC",
	}

	for sort, expected := range tests {
		t.Run(sort, func(t *testing.T) {
			if got := storyListOrderBy(sort); got != expected {
				t.Fatalf("order by mismatch\nexpected: %s\nactual:   %s", expected, got)
			}
		})
	}
}

func TestAppendRelatedStoryOrderByScoresSmartSignals(t *testing.T) {
	category := enum.StoryCategoryGuide
	format := enum.StoryFormatGuide
	authorID := uuid.New()

	args, orderBy := appendRelatedStoryOrderBy(nil, model.StoryListFilter{
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
	sourceBytes, err := os.ReadFile("pg_story_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)

	for _, needle := range []string{
		"place_city_id",
		"story.PlaceCityID",
		"filter.PlaceCityID",
		"item.PlaceCityID",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("repository source must contain %q", needle)
		}
	}

	migrationBytes, err := os.ReadFile("../../../migrations/004_story_place_city_id.up.sql")
	if err != nil {
		t.Fatalf("read place city migration: %v", err)
	}
	migration := string(migrationBytes)
	for _, needle := range []string{
		"ADD COLUMN IF NOT EXISTS place_city_id",
		"idx_stories_place_city_published",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("migration must contain %q", needle)
		}
	}
}

func TestScanStoryNormalizesContentEngineDefaults(t *testing.T) {
	now := time.Now().UTC()
	storyID := uuid.New()
	authorID := uuid.New()

	item, err := scanStory(stubScanner{
		values: []any{
			storyID,
			"my-story",
			authorID,
			"Title",
			"Excerpt",
			"Legacy content",
			"JOURNAL",
			"DRAFT",
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
		t.Fatalf("scan story: %v", err)
	}

	if item.Format != enum.StoryFormatStory {
		t.Fatalf("Format = %q, want %q", item.Format, enum.StoryFormatStory)
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

func TestScanStoryReadsContentEngineFields(t *testing.T) {
	now := time.Now().UTC()
	lastAutosavedAt := now.Add(time.Minute)
	archivedAt := now.Add(time.Hour)
	storyID := uuid.New()
	authorID := uuid.New()
	contentBlocks := json.RawMessage(`[{"id":"block-1","type":"paragraph","text":"Hello"}]`)

	item, err := scanStory(stubScanner{
		values: []any{
			storyID,
			"my-guide",
			authorID,
			"Title",
			"Excerpt",
			"Legacy content",
			"GUIDE",
			"PUBLISHED",
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
		t.Fatalf("scan story: %v", err)
	}

	if item.Format != enum.StoryFormatGuide {
		t.Fatalf("Format = %q, want %q", item.Format, enum.StoryFormatGuide)
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
	sourceBytes, err := os.ReadFile("pg_story_repository.go")
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
		"last_autosaved_at",
		"archived_at",
		"moderation_status",
		"story.Format",
		"story.ContentSchemaVersion",
		"story.ContentBlocks",
		"story.ContentPlainText",
		"story.Revision",
		"story.LastAutosavedAt",
		"story.ArchivedAt",
		"story.ModerationStatus",
		"item.Format",
		"item.ContentSchemaVersion",
		"item.ContentBlocks",
		"item.ContentPlainText",
		"item.Revision",
		"item.LastAutosavedAt",
		"item.ArchivedAt",
		"item.ModerationStatus",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("repository source must contain %q", needle)
		}
	}
}

func TestRepositoryUpdateStoryUsesRevisionGuard(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_story_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)

	for _, needle := range []string{
		"validateStoryUpdateRevision(story)",
		"revision = revision + 1",
		"WHERE id = $1 AND revision = $22 AND deleted_at IS NULL",
		"return storyUpdateRowsAffectedError(tag.RowsAffected())",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("repository update must contain %q", needle)
		}
	}
}

func TestValidateStoryUpdateRevisionFailsClosedForMissingRevision(t *testing.T) {
	tests := map[string]int64{
		"zero":     0,
		"negative": -1,
	}

	for name, revision := range tests {
		t.Run(name, func(t *testing.T) {
			err := validateStoryUpdateRevision(&model.Story{Revision: revision})
			if !errors.Is(err, port.ErrStoryRevisionConflict) {
				t.Fatalf("validateStoryUpdateRevision error = %v, want %v", err, port.ErrStoryRevisionConflict)
			}
		})
	}
}

func TestValidateStoryUpdateRevisionAcceptsPositiveRevision(t *testing.T) {
	if err := validateStoryUpdateRevision(&model.Story{Revision: 1}); err != nil {
		t.Fatalf("validateStoryUpdateRevision returned error: %v", err)
	}
}

func TestStoryUpdateRowsAffectedErrorMapsZeroRowsToRevisionConflict(t *testing.T) {
	err := storyUpdateRowsAffectedError(0)
	if !errors.Is(err, port.ErrStoryRevisionConflict) {
		t.Fatalf("storyUpdateRowsAffectedError(0) = %v, want %v", err, port.ErrStoryRevisionConflict)
	}

	if err := storyUpdateRowsAffectedError(1); err != nil {
		t.Fatalf("storyUpdateRowsAffectedError(1) returned error: %v", err)
	}
}

func TestPublicStoryVisibilityClausesMatchFeedIndexPredicate(t *testing.T) {
	args, clauses := appendPublicStoryVisibilityClauses([]any{"author-id"}, []string{"author_user_id = $1"})

	if len(args) != 3 {
		t.Fatalf("args length = %d, want 3", len(args))
	}
	if args[1] != string(enum.StoryStatusPublished) {
		t.Fatalf("status arg = %v, want %s", args[1], enum.StoryStatusPublished)
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

func TestRepositoryListAndCountSupportArchivedStatusFilters(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_story_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)
	countStart := strings.Index(source, "func (r *PGStoryRepository) CountStories")
	if countStart < 0 {
		t.Fatal("repository source must define CountStories")
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
		t.Fatal("ListStories and CountStories must both apply filter.ExcludeArchived")
	}
	for _, needle := range []string{
		"filter.ExcludeArchived",
		"archived_at IS NULL",
		"filter.Formats",
		"format = ANY($",
	} {
		if !strings.Contains(countSource, needle) {
			t.Fatalf("CountStories source must contain %q", needle)
		}
	}
}

func TestRepositoryAvoidsWrappedCountryAndCityPredicates(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_story_repository.go")
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

func TestArchivedStatusMigrationExpandsStoryStatusCheck(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/006_story_archived_status.up.sql")
	if err != nil {
		t.Fatalf("read archived status migration: %v", err)
	}
	upSQL := string(up)
	if !strings.Contains(upSQL, "ARCHIVED") || !strings.Contains(upSQL, "chk_stories_status") {
		t.Fatalf("archived status migration must update chk_stories_status with ARCHIVED")
	}
	for _, needle := range []string{
		"NOT VALID",
		"VALIDATE CONSTRAINT",
		"RENAME CONSTRAINT",
		"chk_stories_status_expanded",
	} {
		if !strings.Contains(upSQL, needle) {
			t.Fatalf("archived status up migration must contain %q", needle)
		}
	}
	if strings.Index(upSQL, "VALIDATE CONSTRAINT") > strings.Index(upSQL, "DROP CONSTRAINT") {
		t.Fatalf("archived status up migration should validate expanded constraint before dropping old constraint:\n%s", upSQL)
	}
}

func TestArchivedStatusDownMigrationRestoresLegacyCheckSafely(t *testing.T) {
	down, err := os.ReadFile("../../../migrations/006_story_archived_status.down.sql")
	if err != nil {
		t.Fatalf("read archived status down migration: %v", err)
	}
	downSQL := string(down)
	for _, needle := range []string{
		"UPDATE stories",
		"WHERE status = 'ARCHIVED'",
		"NOT VALID",
		"VALIDATE CONSTRAINT",
		"RENAME CONSTRAINT",
		"chk_stories_status_legacy",
	} {
		if !strings.Contains(downSQL, needle) {
			t.Fatalf("archived status down migration must contain %q", needle)
		}
	}
	if strings.Index(downSQL, "UPDATE stories") > strings.Index(downSQL, "ADD CONSTRAINT") {
		t.Fatalf("archived status down migration should convert archived rows before adding legacy check:\n%s", downSQL)
	}
	if strings.Index(downSQL, "VALIDATE CONSTRAINT") > strings.Index(downSQL, "DROP CONSTRAINT") {
		t.Fatalf("archived status down migration should validate legacy constraint before dropping expanded constraint:\n%s", downSQL)
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
