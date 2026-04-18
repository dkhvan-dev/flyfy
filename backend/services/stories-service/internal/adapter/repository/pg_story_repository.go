package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/stories-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/stories-service/internal/domain/model"
)

type PGStoryRepository struct {
	pool *pgxpool.Pool
}

func NewPGStoryRepository(pool *pgxpool.Pool) *PGStoryRepository {
	return &PGStoryRepository{pool: pool}
}

func (r *PGStoryRepository) CreateStory(ctx context.Context, story *model.Story) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const storyQuery = `
		INSERT INTO stories (
			id, slug, author_user_id, title, excerpt, content, category, status,
			cover_file_id, place_name, place_country_code, tags, view_count,
			like_count, comment_count, share_count, published_at, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8,
			$9, $10, $11, $12, $13,
			$14, $15, $16, $17, $18, $19
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
		story.Tags,
		story.ViewCount,
		story.LikeCount,
		story.CommentCount,
		story.ShareCount,
		story.PublishedAt,
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
			tags = $11,
			published_at = $12,
			updated_at = $13
		WHERE id = $1 AND deleted_at IS NULL
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
		story.Tags,
		story.PublishedAt,
		story.UpdatedAt,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("update story: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
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
			cover_file_id, place_name, place_country_code, tags, view_count,
			like_count, comment_count, share_count, published_at, created_at, updated_at, deleted_at
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
			cover_file_id, place_name, place_country_code, tags, view_count,
			like_count, comment_count, share_count, published_at, created_at, updated_at, deleted_at
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

	if !filter.IncludeDeleted {
		clauses = append(clauses, "deleted_at IS NULL")
	}
	if filter.OnlyPublished {
		args = append(args, string(enum.StoryStatusPublished))
		clauses = append(clauses, fmt.Sprintf("status = $%d", len(args)))
	}
	if filter.AuthorUserID != nil && *filter.AuthorUserID != uuid.Nil {
		args = append(args, *filter.AuthorUserID)
		clauses = append(clauses, fmt.Sprintf("author_user_id = $%d", len(args)))
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

	orderBy := "published_at DESC NULLS LAST, created_at DESC"
	switch filter.Sort {
	case "popular":
		orderBy = "view_count DESC, published_at DESC NULLS LAST, created_at DESC"
	case "discussed":
		orderBy = "comment_count DESC, published_at DESC NULLS LAST, created_at DESC"
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
			cover_file_id, place_name, place_country_code, tags, view_count,
			like_count, comment_count, share_count, published_at, created_at, updated_at, deleted_at
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

func (r *PGStoryRepository) GetCommentByID(ctx context.Context, storyID uuid.UUID, commentID uuid.UUID) (*model.StoryComment, error) {
	const query = `
		SELECT id, story_id, author_user_id, body, created_at, updated_at, deleted_at
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
			SELECT id, story_id, author_user_id, body, created_at, updated_at, deleted_at
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
		item         model.Story
		categoryRaw  string
		statusRaw    string
		coverFileID  *uuid.UUID
		placeName    *string
		placeCountry *string
		publishedAt  *time.Time
		deletedAt    *time.Time
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
		&item.Tags,
		&item.ViewCount,
		&item.LikeCount,
		&item.CommentCount,
		&item.ShareCount,
		&publishedAt,
		&item.CreatedAt,
		&item.UpdatedAt,
		&deletedAt,
	); err != nil {
		return nil, err
	}

	item.Category = enum.StoryCategory(categoryRaw)
	item.Status = enum.StoryStatus(statusRaw)
	item.CoverFileID = coverFileID
	item.PlaceName = placeName
	item.PlaceCountryCode = placeCountry
	item.PublishedAt = publishedAt
	item.DeletedAt = deletedAt

	return &item, nil
}

func scanComment(scanner interface{ Scan(dest ...any) error }) (*model.StoryComment, error) {
	var item model.StoryComment
	if err := scanner.Scan(
		&item.ID,
		&item.StoryID,
		&item.AuthorUserID,
		&item.Body,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.DeletedAt,
	); err != nil {
		return nil, err
	}
	return &item, nil
}
