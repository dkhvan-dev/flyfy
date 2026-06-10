package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/stories-service/internal/domain/enum"
	"kz/inflap/backend/services/stories-service/internal/domain/model"
	"kz/inflap/backend/services/stories-service/internal/domain/port"
)

type PGStoryRepository struct {
	pool *pgxpool.Pool
}

func NewPGStoryRepository(pool *pgxpool.Pool) *PGStoryRepository {
	return &PGStoryRepository{pool: pool}
}

func (r *PGStoryRepository) CreateStory(ctx context.Context, story *model.Story) error {
	normalizeStoryContentEngineFields(story)

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const storyQuery = `
		INSERT INTO stories (
			id, slug, author_user_id, title, excerpt, content, category, status,
			cover_file_id, place_name, place_country_code, place_city_id, tags,
			view_count, like_count, comment_count, share_count, published_at,
			format, content_schema_version, content_blocks, content_plain_text,
			revision, last_autosaved_at, archived_at, moderation_status,
			created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8,
			$9, $10, $11, $12, $13,
			$14, $15, $16, $17, $18,
			$19, $20, $21, $22,
			$23, $24, $25, $26,
			$27, $28
		)
	`

	if _, err = tx.Exec(
		ctx,
		storyQuery,
		story.ID,
		story.Slug,
		story.AuthorUserID,
		story.Title,
		story.Excerpt,
		story.Content,
		string(story.Category),
		string(story.Status),
		story.CoverFileID,
		story.PlaceName,
		story.PlaceCountryCode,
		story.PlaceCityID,
		story.Tags,
		story.ViewCount,
		story.LikeCount,
		story.CommentCount,
		story.ShareCount,
		story.PublishedAt,
		string(story.Format),
		story.ContentSchemaVersion,
		story.ContentBlocks,
		story.ContentPlainText,
		story.Revision,
		story.LastAutosavedAt,
		story.ArchivedAt,
		string(story.ModerationStatus),
		story.CreatedAt,
		story.UpdatedAt,
	); err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert story: %w", err)
	}

	const sketchQuery = `
		INSERT INTO story_view_sketches (story_id, registers, updated_at)
		VALUES ($1, $2, NOW())
	`
	if _, err = tx.Exec(ctx, sketchQuery, story.ID, story.ViewHLL); err != nil {
		return fmt.Errorf("insert story view sketch: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit story create tx: %w", err)
	}

	return nil
}

func (r *PGStoryRepository) UpdateStory(ctx context.Context, story *model.Story) error {
	if err := validateStoryUpdateRevision(story); err != nil {
		return err
	}

	normalizeStoryContentEngineFields(story)

	const query = `
		UPDATE stories
		SET
			slug = $2,
			title = $3,
			excerpt = $4,
			content = $5,
			category = $6,
			status = $7,
			cover_file_id = $8,
			place_name = $9,
			place_country_code = $10,
			place_city_id = $11,
			tags = $12,
			published_at = $13,
			updated_at = $14,
			format = $15,
			content_schema_version = $16,
			content_blocks = $17,
			content_plain_text = $18,
			revision = revision + 1,
			last_autosaved_at = $19,
			archived_at = $20,
			moderation_status = $21
		WHERE id = $1 AND revision = $22 AND deleted_at IS NULL
	`

	tag, err := r.pool.Exec(
		ctx,
		query,
		story.ID,
		story.Slug,
		story.Title,
		story.Excerpt,
		story.Content,
		string(story.Category),
		string(story.Status),
		story.CoverFileID,
		story.PlaceName,
		story.PlaceCountryCode,
		story.PlaceCityID,
		story.Tags,
		story.PublishedAt,
		story.UpdatedAt,
		string(story.Format),
		story.ContentSchemaVersion,
		story.ContentBlocks,
		story.ContentPlainText,
		story.LastAutosavedAt,
		story.ArchivedAt,
		string(story.ModerationStatus),
		story.Revision,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("update story: %w", err)
	}
	return storyUpdateRowsAffectedError(tag.RowsAffected())
}

func (r *PGStoryRepository) SoftDeleteStory(ctx context.Context, storyID uuid.UUID, authorUserID uuid.UUID) error {
	const query = `
		UPDATE stories
		SET deleted_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND author_user_id = $2 AND deleted_at IS NULL
	`

	tag, err := r.pool.Exec(ctx, query, storyID, authorUserID)
	if err != nil {
		return fmt.Errorf("soft delete story: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}

func (r *PGStoryRepository) GetStoryByID(ctx context.Context, storyID uuid.UUID) (*model.Story, error) {
	const query = `
		SELECT
			id, slug, author_user_id, title, excerpt, content, category, status,
			cover_file_id, place_name, place_country_code, place_city_id, tags, view_count,
			like_count, comment_count, share_count, published_at, created_at, updated_at, deleted_at,
			format, content_schema_version, content_blocks, content_plain_text, revision,
			last_autosaved_at, archived_at, moderation_status
		FROM stories
		WHERE id = $1
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, storyID)
	item, err := scanStory(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select story by id: %w", err)
	}

	return item, nil
}

func (r *PGStoryRepository) GetStoryBySlug(ctx context.Context, slug string) (*model.Story, error) {
	const query = `
		SELECT
			id, slug, author_user_id, title, excerpt, content, category, status,
			cover_file_id, place_name, place_country_code, place_city_id, tags, view_count,
			like_count, comment_count, share_count, published_at, created_at, updated_at, deleted_at,
			format, content_schema_version, content_blocks, content_plain_text, revision,
			last_autosaved_at, archived_at, moderation_status
		FROM stories
		WHERE slug = $1 AND deleted_at IS NULL
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, strings.TrimSpace(slug))
	item, err := scanStory(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select story by slug: %w", err)
	}

	return item, nil
}

func (r *PGStoryRepository) ListStories(ctx context.Context, filter model.StoryListFilter) ([]*model.Story, error) {
	args := make([]any, 0, 12)
	clauses := []string{"1=1"}

	if filter.OnlyPublished {
		args, clauses = appendPublicStoryVisibilityClauses(args, clauses)
	} else if !filter.IncludeDeleted {
		clauses = append(clauses, "deleted_at IS NULL")
	}
	if filter.AuthorUserID != nil && *filter.AuthorUserID != uuid.Nil {
		args = append(args, *filter.AuthorUserID)
		clauses = append(clauses, fmt.Sprintf("author_user_id = $%d", len(args)))
	}
	if filter.Status != nil {
		args = append(args, string(*filter.Status))
		clauses = append(clauses, fmt.Sprintf("status = $%d", len(args)))
	}
	if filter.ArchivedOnly {
		clauses = append(clauses, "archived_at IS NOT NULL")
	}
	if filter.ExcludeArchived {
		clauses = append(clauses, "archived_at IS NULL")
	}
	if len(filter.Formats) > 0 {
		raw := make([]string, 0, len(filter.Formats))
		for _, format := range filter.Formats {
			raw = append(raw, string(format))
		}
		args = append(args, raw)
		clauses = append(clauses, fmt.Sprintf("format = ANY($%d)", len(args)))
	}
	if len(filter.Categories) > 0 {
		raw := make([]string, 0, len(filter.Categories))
		for _, category := range filter.Categories {
			raw = append(raw, string(category))
		}
		args = append(args, raw)
		clauses = append(clauses, fmt.Sprintf("category = ANY($%d)", len(args)))
	}
	if filter.ExcludeStoryID != nil && *filter.ExcludeStoryID != uuid.Nil {
		args = append(args, *filter.ExcludeStoryID)
		clauses = append(clauses, fmt.Sprintf("id <> $%d", len(args)))
	}
	if strings.TrimSpace(filter.Search) != "" {
		term := strings.TrimSpace(filter.Search)
		args = append(args, term)
		clauses = append(clauses, fmt.Sprintf("COALESCE(search_vector, ''::tsvector) @@ websearch_to_tsquery('simple', $%d)", len(args)))
	}
	if strings.TrimSpace(filter.PlaceQuery) != "" {
		term := "%" + strings.TrimSpace(filter.PlaceQuery) + "%"
		args = append(args, term)
		clauses = append(clauses, fmt.Sprintf("COALESCE(place_name, '') ILIKE $%d", len(args)))
	}
	if strings.TrimSpace(filter.PlaceCountryCode) != "" {
		args = append(args, strings.ToUpper(strings.TrimSpace(filter.PlaceCountryCode)))
		clauses = append(clauses, fmt.Sprintf("place_country_code = $%d", len(args)))
	}
	if strings.TrimSpace(filter.PlaceCityID) != "" {
		args = append(args, strings.TrimSpace(filter.PlaceCityID))
		clauses = append(clauses, fmt.Sprintf("place_city_id = $%d", len(args)))
	}

	orderBy := ""
	if filter.Sort == "related" {
		args, orderBy = appendRelatedStoryOrderBy(args, filter)
	} else {
		orderBy = storyListOrderBy(filter.Sort)
	}

	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	args = append(args, filter.Limit, filter.Offset)
	limitPos := len(args) - 1
	offsetPos := len(args)

	query := fmt.Sprintf(`
		SELECT
			id, slug, author_user_id, title, excerpt, content, category, status,
			cover_file_id, place_name, place_country_code, place_city_id, tags, view_count,
			like_count, comment_count, share_count, published_at, created_at, updated_at, deleted_at,
			format, content_schema_version, content_blocks, content_plain_text, revision,
			last_autosaved_at, archived_at, moderation_status
		FROM stories
		WHERE %s
		ORDER BY %s
		LIMIT $%d OFFSET $%d
	`, strings.Join(clauses, " AND "), orderBy, limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query stories: %w", err)
	}
	defer rows.Close()

	items := make([]*model.Story, 0)
	for rows.Next() {
		item, scanErr := scanStory(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan story list: %w", scanErr)
		}
		items = append(items, item)
	}

	return items, rows.Err()
}

func (r *PGStoryRepository) CountStories(ctx context.Context, filter model.StoryListFilter) (int, error) {
	args := make([]any, 0, 10)
	clauses := []string{"1=1"}

	if filter.OnlyPublished {
		args, clauses = appendPublicStoryVisibilityClauses(args, clauses)
	} else if !filter.IncludeDeleted {
		clauses = append(clauses, "deleted_at IS NULL")
	}
	if filter.AuthorUserID != nil && *filter.AuthorUserID != uuid.Nil {
		args = append(args, *filter.AuthorUserID)
		clauses = append(clauses, fmt.Sprintf("author_user_id = $%d", len(args)))
	}
	if filter.Status != nil {
		args = append(args, string(*filter.Status))
		clauses = append(clauses, fmt.Sprintf("status = $%d", len(args)))
	}
	if filter.ArchivedOnly {
		clauses = append(clauses, "archived_at IS NOT NULL")
	}
	if filter.ExcludeArchived {
		clauses = append(clauses, "archived_at IS NULL")
	}
	if len(filter.Formats) > 0 {
		raw := make([]string, 0, len(filter.Formats))
		for _, format := range filter.Formats {
			raw = append(raw, string(format))
		}
		args = append(args, raw)
		clauses = append(clauses, fmt.Sprintf("format = ANY($%d)", len(args)))
	}
	if len(filter.Categories) > 0 {
		raw := make([]string, 0, len(filter.Categories))
		for _, category := range filter.Categories {
			raw = append(raw, string(category))
		}
		args = append(args, raw)
		clauses = append(clauses, fmt.Sprintf("category = ANY($%d)", len(args)))
	}
	if filter.ExcludeStoryID != nil && *filter.ExcludeStoryID != uuid.Nil {
		args = append(args, *filter.ExcludeStoryID)
		clauses = append(clauses, fmt.Sprintf("id <> $%d", len(args)))
	}
	if strings.TrimSpace(filter.Search) != "" {
		term := strings.TrimSpace(filter.Search)
		args = append(args, term)
		clauses = append(clauses, fmt.Sprintf("COALESCE(search_vector, ''::tsvector) @@ websearch_to_tsquery('simple', $%d)", len(args)))
	}
	if strings.TrimSpace(filter.PlaceQuery) != "" {
		term := "%" + strings.TrimSpace(filter.PlaceQuery) + "%"
		args = append(args, term)
		clauses = append(clauses, fmt.Sprintf("COALESCE(place_name, '') ILIKE $%d", len(args)))
	}
	if strings.TrimSpace(filter.PlaceCountryCode) != "" {
		args = append(args, strings.ToUpper(strings.TrimSpace(filter.PlaceCountryCode)))
		clauses = append(clauses, fmt.Sprintf("place_country_code = $%d", len(args)))
	}
	if strings.TrimSpace(filter.PlaceCityID) != "" {
		args = append(args, strings.TrimSpace(filter.PlaceCityID))
		clauses = append(clauses, fmt.Sprintf("place_city_id = $%d", len(args)))
	}

	var count int64
	query := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM stories
		WHERE %s
	`, strings.Join(clauses, " AND "))

	if err := r.pool.QueryRow(ctx, query, args...).Scan(&count); err != nil {
		return 0, fmt.Errorf("count stories: %w", err)
	}

	return int(count), nil
}

func (r *PGStoryRepository) CountPublishedStoriesByAuthorID(ctx context.Context, authorUserID uuid.UUID) (int, error) {
	var count int64
	args, clauses := appendPublicStoryVisibilityClauses(
		[]any{authorUserID},
		[]string{"author_user_id = $1"},
	)

	query := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM stories
		WHERE %s
	`, strings.Join(clauses, " AND "))

	err := r.pool.QueryRow(ctx, query, args...).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("count published stories by author: %w", err)
	}

	return int(count), nil
}

func appendPublicStoryVisibilityClauses(args []any, clauses []string) ([]any, []string) {
	args = append(args, string(enum.StoryStatusPublished))
	statusPos := len(args)
	args = append(args, []string{
		string(enum.ModerationStatusNotRequired),
		string(enum.ModerationStatusApproved),
	})
	moderationPos := len(args)

	clauses = append(
		clauses,
		"deleted_at IS NULL",
		"archived_at IS NULL",
		fmt.Sprintf("status = $%d", statusPos),
		fmt.Sprintf("COALESCE(moderation_status, 'NOT_REQUIRED') = ANY($%d)", moderationPos),
	)
	return args, clauses
}

func storyListOrderBy(sort string) string {
	switch sort {
	case "latest_asc":
		return "published_at ASC NULLS LAST, created_at ASC"
	case "popular", "popular_desc":
		return "view_count DESC, published_at DESC NULLS LAST, created_at DESC"
	case "popular_asc":
		return "view_count ASC, published_at ASC NULLS LAST, created_at ASC"
	case "discussed", "discussed_desc":
		return "comment_count DESC, published_at DESC NULLS LAST, created_at DESC"
	case "discussed_asc":
		return "comment_count ASC, published_at ASC NULLS LAST, created_at ASC"
	case "latest", "latest_desc":
		return "published_at DESC NULLS LAST, created_at DESC"
	default:
		return "published_at DESC NULLS LAST, created_at DESC"
	}
}

func appendRelatedStoryOrderBy(args []any, filter model.StoryListFilter) ([]any, string) {
	scoreParts := make([]string, 0, 6)

	if value := strings.TrimSpace(filter.RelatedToCityID); value != "" {
		args = append(args, value)
		scoreParts = append(scoreParts, fmt.Sprintf("CASE WHEN place_city_id = $%d THEN 80 ELSE 0 END", len(args)))
	}
	if value := strings.ToUpper(strings.TrimSpace(filter.RelatedToCountry)); value != "" {
		args = append(args, value)
		scoreParts = append(scoreParts, fmt.Sprintf("CASE WHEN place_country_code = $%d THEN 36 ELSE 0 END", len(args)))
	}
	if filter.RelatedToCategory != nil && filter.RelatedToCategory.IsValid() {
		args = append(args, string(*filter.RelatedToCategory))
		scoreParts = append(scoreParts, fmt.Sprintf("CASE WHEN category = $%d THEN 32 ELSE 0 END", len(args)))
	}
	if filter.RelatedToFormat != nil && filter.RelatedToFormat.IsValid() {
		args = append(args, string(*filter.RelatedToFormat))
		scoreParts = append(scoreParts, fmt.Sprintf("CASE WHEN format = $%d THEN 24 ELSE 0 END", len(args)))
	}
	if filter.RelatedToAuthor != nil && *filter.RelatedToAuthor != uuid.Nil {
		args = append(args, *filter.RelatedToAuthor)
		scoreParts = append(scoreParts, fmt.Sprintf("CASE WHEN author_user_id = $%d THEN 12 ELSE 0 END", len(args)))
	}
	if len(filter.RelatedToTags) > 0 {
		args = append(args, filter.RelatedToTags)
		scoreParts = append(scoreParts, fmt.Sprintf("CASE WHEN ARRAY(SELECT lower(value) FROM unnest(COALESCE(tags, ARRAY[]::text[])) AS tag(value)) && $%d::text[] THEN 18 ELSE 0 END", len(args)))
	}

	if len(scoreParts) == 0 {
		return args, storyListOrderBy("popular_desc")
	}

	return args, fmt.Sprintf(
		"(%s) DESC, view_count DESC, like_count DESC, comment_count DESC, published_at DESC NULLS LAST, created_at DESC",
		strings.Join(scoreParts, " + "),
	)
}

func (r *PGStoryRepository) LikeStory(ctx context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin like tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const insertQuery = `
		INSERT INTO story_likes (story_id, user_id, created_at)
		VALUES ($1, $2, NOW())
		ON CONFLICT (story_id, user_id) DO NOTHING
	`
	tag, err := tx.Exec(ctx, insertQuery, storyID, userID)
	if err != nil {
		return false, 0, fmt.Errorf("insert story like: %w", err)
	}

	changed := tag.RowsAffected() > 0
	if changed {
		if _, err = tx.Exec(ctx, `UPDATE stories SET like_count = like_count + 1 WHERE id = $1`, storyID); err != nil {
			return false, 0, fmt.Errorf("increment like count: %w", err)
		}
	}

	var likeCount int
	if err = tx.QueryRow(ctx, `SELECT like_count FROM stories WHERE id = $1`, storyID).Scan(&likeCount); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, 0, ErrNotFound
		}
		return false, 0, fmt.Errorf("select story like count: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return false, 0, fmt.Errorf("commit like tx: %w", err)
	}

	return changed, likeCount, nil
}

func (r *PGStoryRepository) UnlikeStory(ctx context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin unlike tx: %w", err)
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(ctx, `DELETE FROM story_likes WHERE story_id = $1 AND user_id = $2`, storyID, userID)
	if err != nil {
		return false, 0, fmt.Errorf("delete story like: %w", err)
	}

	changed := tag.RowsAffected() > 0
	if changed {
		if _, err = tx.Exec(ctx, `UPDATE stories SET like_count = GREATEST(like_count - 1, 0) WHERE id = $1`, storyID); err != nil {
			return false, 0, fmt.Errorf("decrement like count: %w", err)
		}
	}

	var likeCount int
	if err = tx.QueryRow(ctx, `SELECT like_count FROM stories WHERE id = $1`, storyID).Scan(&likeCount); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, 0, ErrNotFound
		}
		return false, 0, fmt.Errorf("select story like count after unlike: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return false, 0, fmt.Errorf("commit unlike tx: %w", err)
	}

	return changed, likeCount, nil
}

func (r *PGStoryRepository) HasStoryLike(ctx context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, error) {
	var exists bool
	if err := r.pool.QueryRow(
		ctx,
		`SELECT EXISTS(SELECT 1 FROM story_likes WHERE story_id = $1 AND user_id = $2)`,
		storyID,
		userID,
	).Scan(&exists); err != nil {
		return false, fmt.Errorf("check story like exists: %w", err)
	}

	return exists, nil
}

func (r *PGStoryRepository) TrackStoryView(ctx context.Context, storyID uuid.UUID, viewerUserID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin view tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var (
		currentCount int
		registers    []byte
	)
	if err = tx.QueryRow(
		ctx,
		`
			SELECT s.view_count, v.registers
			FROM stories s
			JOIN story_view_sketches v ON v.story_id = s.id
			WHERE s.id = $1 AND s.deleted_at IS NULL
			FOR UPDATE
		`,
		storyID,
	).Scan(&currentCount, &registers); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, 0, ErrNotFound
		}
		return false, 0, fmt.Errorf("select story view sketch: %w", err)
	}

	hll, err := model.HyperLogLogFromBytes(registers)
	if err != nil {
		return false, 0, fmt.Errorf("decode story hll: %w", err)
	}

	changed := hll.AddString(viewerUserID.String())
	if !changed {
		if err = tx.Commit(ctx); err != nil {
			return false, 0, fmt.Errorf("commit unchanged view tx: %w", err)
		}
		return false, currentCount, nil
	}

	nextCount := int(hll.Count())
	if _, err = tx.Exec(
		ctx,
		`UPDATE story_view_sketches SET registers = $2, updated_at = NOW() WHERE story_id = $1`,
		storyID,
		hll.Bytes(),
	); err != nil {
		return false, 0, fmt.Errorf("update story view sketch: %w", err)
	}

	if _, err = tx.Exec(ctx, `UPDATE stories SET view_count = $2 WHERE id = $1`, storyID, nextCount); err != nil {
		return false, 0, fmt.Errorf("update story view count: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return false, 0, fmt.Errorf("commit view tx: %w", err)
	}

	return true, nextCount, nil
}

func (r *PGStoryRepository) IncrementShareCount(ctx context.Context, storyID uuid.UUID) (int, error) {
	var count int
	if err := r.pool.QueryRow(
		ctx,
		`UPDATE stories SET share_count = share_count + 1 WHERE id = $1 AND deleted_at IS NULL RETURNING share_count`,
		storyID,
	).Scan(&count); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, ErrNotFound
		}
		return 0, fmt.Errorf("increment share count: %w", err)
	}

	return count, nil
}

func (r *PGStoryRepository) CreateComment(ctx context.Context, comment *model.StoryComment) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin comment tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const query = `
		INSERT INTO story_comments (id, story_id, author_user_id, body, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	if _, err = tx.Exec(
		ctx,
		query,
		comment.ID,
		comment.StoryID,
		comment.AuthorUserID,
		comment.Body,
		comment.CreatedAt,
		comment.UpdatedAt,
	); err != nil {
		return fmt.Errorf("insert story comment: %w", err)
	}

	if _, err = tx.Exec(ctx, `UPDATE stories SET comment_count = comment_count + 1 WHERE id = $1`, comment.StoryID); err != nil {
		return fmt.Errorf("increment story comment count: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit create comment tx: %w", err)
	}

	return nil
}

func (r *PGStoryRepository) UpdateComment(ctx context.Context, comment *model.StoryComment) error {
	const query = `
		UPDATE story_comments
		SET body = $3, updated_at = $4
		WHERE story_id = $1 AND id = $2 AND deleted_at IS NULL
	`

	tag, err := r.pool.Exec(ctx, query, comment.StoryID, comment.ID, comment.Body, comment.UpdatedAt)
	if err != nil {
		return fmt.Errorf("update story comment: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}

func (r *PGStoryRepository) GetLatestActiveCommentByAuthor(ctx context.Context, storyID uuid.UUID, authorUserID uuid.UUID) (*model.StoryComment, error) {
	const query = `
		SELECT id, story_id, author_user_id, body, like_count, created_at, updated_at, deleted_at
		FROM story_comments
		WHERE story_id = $1 AND author_user_id = $2 AND deleted_at IS NULL
		ORDER BY created_at DESC
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, storyID, authorUserID)
	comment, err := scanComment(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select latest active comment by author: %w", err)
	}

	return comment, nil
}

func (r *PGStoryRepository) GetCommentByID(ctx context.Context, storyID uuid.UUID, commentID uuid.UUID) (*model.StoryComment, error) {
	const query = `
		SELECT id, story_id, author_user_id, body, like_count, created_at, updated_at, deleted_at
		FROM story_comments
		WHERE story_id = $1 AND id = $2
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, storyID, commentID)
	comment, err := scanComment(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select story comment by id: %w", err)
	}

	return comment, nil
}

func (r *PGStoryRepository) ListComments(ctx context.Context, storyID uuid.UUID, limit int, offset int) ([]*model.StoryComment, error) {
	rows, err := r.pool.Query(
		ctx,
		`
			SELECT id, story_id, author_user_id, body, like_count, created_at, updated_at, deleted_at
			FROM story_comments
			WHERE story_id = $1 AND deleted_at IS NULL
			ORDER BY created_at DESC
			LIMIT $2 OFFSET $3
		`,
		storyID,
		limit,
		offset,
	)
	if err != nil {
		return nil, fmt.Errorf("query story comments: %w", err)
	}
	defer rows.Close()

	items := make([]*model.StoryComment, 0)
	for rows.Next() {
		item, scanErr := scanComment(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan story comment list: %w", scanErr)
		}
		items = append(items, item)
	}

	return items, rows.Err()
}

func (r *PGStoryRepository) LikeComment(ctx context.Context, storyID uuid.UUID, commentID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin comment like tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const insertQuery = `
		INSERT INTO story_comment_likes (comment_id, user_id, created_at)
		SELECT $2, $3, NOW()
		WHERE EXISTS (
			SELECT 1
			FROM story_comments
			WHERE story_id = $1 AND id = $2 AND deleted_at IS NULL
		)
		ON CONFLICT (comment_id, user_id) DO NOTHING
	`
	tag, err := tx.Exec(ctx, insertQuery, storyID, commentID, userID)
	if err != nil {
		return false, 0, fmt.Errorf("insert comment like: %w", err)
	}

	changed := tag.RowsAffected() > 0
	if changed {
		if _, err = tx.Exec(ctx, `UPDATE story_comments SET like_count = like_count + 1 WHERE story_id = $1 AND id = $2 AND deleted_at IS NULL`, storyID, commentID); err != nil {
			return false, 0, fmt.Errorf("increment comment like count: %w", err)
		}
	}

	var likeCount int
	if err = tx.QueryRow(ctx, `SELECT like_count FROM story_comments WHERE story_id = $1 AND id = $2 AND deleted_at IS NULL`, storyID, commentID).Scan(&likeCount); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, 0, ErrNotFound
		}
		return false, 0, fmt.Errorf("select comment like count: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return false, 0, fmt.Errorf("commit comment like tx: %w", err)
	}

	return changed, likeCount, nil
}

func (r *PGStoryRepository) UnlikeComment(ctx context.Context, storyID uuid.UUID, commentID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin comment unlike tx: %w", err)
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(
		ctx,
		`
			DELETE FROM story_comment_likes
			WHERE comment_id = $2 AND user_id = $3
			  AND EXISTS (
				SELECT 1
				FROM story_comments
				WHERE story_id = $1 AND id = $2 AND deleted_at IS NULL
			  )
		`,
		storyID,
		commentID,
		userID,
	)
	if err != nil {
		return false, 0, fmt.Errorf("delete comment like: %w", err)
	}

	changed := tag.RowsAffected() > 0
	if changed {
		if _, err = tx.Exec(ctx, `UPDATE story_comments SET like_count = GREATEST(like_count - 1, 0) WHERE story_id = $1 AND id = $2 AND deleted_at IS NULL`, storyID, commentID); err != nil {
			return false, 0, fmt.Errorf("decrement comment like count: %w", err)
		}
	}

	var likeCount int
	if err = tx.QueryRow(ctx, `SELECT like_count FROM story_comments WHERE story_id = $1 AND id = $2 AND deleted_at IS NULL`, storyID, commentID).Scan(&likeCount); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, 0, ErrNotFound
		}
		return false, 0, fmt.Errorf("select comment like count after unlike: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return false, 0, fmt.Errorf("commit comment unlike tx: %w", err)
	}

	return changed, likeCount, nil
}

func (r *PGStoryRepository) HasCommentLike(ctx context.Context, commentID uuid.UUID, userID uuid.UUID) (bool, error) {
	var exists bool
	if err := r.pool.QueryRow(
		ctx,
		`SELECT EXISTS(SELECT 1 FROM story_comment_likes WHERE comment_id = $1 AND user_id = $2)`,
		commentID,
		userID,
	).Scan(&exists); err != nil {
		return false, fmt.Errorf("check comment like exists: %w", err)
	}

	return exists, nil
}

func (r *PGStoryRepository) DeleteComment(ctx context.Context, storyID uuid.UUID, commentID uuid.UUID) (bool, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, fmt.Errorf("begin delete comment tx: %w", err)
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(
		ctx,
		`UPDATE story_comments SET deleted_at = NOW(), updated_at = NOW() WHERE story_id = $1 AND id = $2 AND deleted_at IS NULL`,
		storyID,
		commentID,
	)
	if err != nil {
		return false, fmt.Errorf("soft delete story comment: %w", err)
	}

	changed := tag.RowsAffected() > 0
	if changed {
		if _, err = tx.Exec(ctx, `UPDATE stories SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = $1`, storyID); err != nil {
			return false, fmt.Errorf("decrement story comment count: %w", err)
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return false, fmt.Errorf("commit delete comment tx: %w", err)
	}

	return changed, nil
}

func scanStory(scanner interface{ Scan(dest ...any) error }) (*model.Story, error) {
	var (
		item             model.Story
		categoryRaw      string
		statusRaw        string
		coverFileID      *uuid.UUID
		placeName        *string
		placeCountry     *string
		placeCityID      *string
		publishedAt      *time.Time
		deletedAt        *time.Time
		formatRaw        sql.NullString
		schemaVersionRaw sql.NullInt32
		contentBlocksRaw []byte
		contentPlainText sql.NullString
		revisionRaw      sql.NullInt64
		lastAutosavedAt  *time.Time
		archivedAt       *time.Time
		moderationRaw    sql.NullString
	)

	if err := scanner.Scan(
		&item.ID,
		&item.Slug,
		&item.AuthorUserID,
		&item.Title,
		&item.Excerpt,
		&item.Content,
		&categoryRaw,
		&statusRaw,
		&coverFileID,
		&placeName,
		&placeCountry,
		&placeCityID,
		&item.Tags,
		&item.ViewCount,
		&item.LikeCount,
		&item.CommentCount,
		&item.ShareCount,
		&publishedAt,
		&item.CreatedAt,
		&item.UpdatedAt,
		&deletedAt,
		&formatRaw,
		&schemaVersionRaw,
		&contentBlocksRaw,
		&contentPlainText,
		&revisionRaw,
		&lastAutosavedAt,
		&archivedAt,
		&moderationRaw,
	); err != nil {
		return nil, err
	}

	item.Category = enum.StoryCategory(categoryRaw)
	item.Status = enum.StoryStatus(statusRaw)
	item.Format = enum.NormalizeStoryFormat(enum.StoryFormat(formatRaw.String))
	item.ContentSchemaVersion = int(schemaVersionRaw.Int32)
	if !schemaVersionRaw.Valid || item.ContentSchemaVersion <= 0 {
		item.ContentSchemaVersion = 1
	}
	if len(contentBlocksRaw) > 0 {
		item.ContentBlocks = json.RawMessage(append([]byte(nil), contentBlocksRaw...))
	}
	item.ContentPlainText = contentPlainText.String
	item.Revision = revisionRaw.Int64
	if !revisionRaw.Valid || item.Revision <= 0 {
		item.Revision = 1
	}
	item.CoverFileID = coverFileID
	item.PlaceName = placeName
	item.PlaceCountryCode = placeCountry
	item.PlaceCityID = placeCityID
	item.PublishedAt = publishedAt
	item.LastAutosavedAt = lastAutosavedAt
	item.ArchivedAt = archivedAt
	item.DeletedAt = deletedAt
	item.ModerationStatus = enum.NormalizeModerationStatus(enum.ModerationStatus(moderationRaw.String))

	return &item, nil
}

func normalizeStoryContentEngineFields(story *model.Story) {
	if story == nil {
		return
	}

	story.Format = enum.NormalizeStoryFormat(story.Format)
	if story.ContentSchemaVersion <= 0 {
		story.ContentSchemaVersion = 1
	}
	if story.Revision <= 0 {
		story.Revision = 1
	}
	story.ModerationStatus = enum.NormalizeModerationStatus(story.ModerationStatus)
}

func validateStoryUpdateRevision(story *model.Story) error {
	if story == nil || story.Revision <= 0 {
		return port.ErrStoryRevisionConflict
	}
	return nil
}

func storyUpdateRowsAffectedError(rowsAffected int64) error {
	if rowsAffected == 0 {
		return port.ErrStoryRevisionConflict
	}
	return nil
}

func scanComment(scanner interface{ Scan(dest ...any) error }) (*model.StoryComment, error) {
	var item model.StoryComment
	if err := scanner.Scan(
		&item.ID,
		&item.StoryID,
		&item.AuthorUserID,
		&item.Body,
		&item.LikeCount,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.DeletedAt,
	); err != nil {
		return nil, err
	}
	return &item, nil
}
