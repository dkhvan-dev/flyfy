package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func (r *PGPostRepository) CreateStory(ctx context.Context, story *model.Story) error {
	if story == nil {
		return fmt.Errorf("story is required")
	}
	const query = `
		INSERT INTO stories (
			id, author_user_id, caption, media_file_id, cover_file_id, media_type,
			view_count, like_count, reply_count, expires_at, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10, $11, $12
		)
	`
	if _, err := r.pool.Exec(
		ctx,
		query,
		story.ID,
		story.AuthorUserID,
		story.Caption,
		story.MediaFileID,
		story.CoverFileID,
		string(story.MediaType),
		story.ViewCount,
		story.LikeCount,
		story.ReplyCount,
		story.ExpiresAt,
		story.CreatedAt,
		story.UpdatedAt,
	); err != nil {
		return fmt.Errorf("insert story: %w", classifyPGError(err))
	}
	return nil
}

func (r *PGPostRepository) ListStories(ctx context.Context, filter model.StoryListFilter) ([]*model.Story, error) {
	args := make([]any, 0, 8)
	clauses := []string{"stories.deleted_at IS NULL"}
	if filter.OnlyExpired {
		clauses = append(clauses, "stories.expires_at <= NOW()")
	} else if !filter.IncludeExpired {
		clauses = append(clauses, "stories.expires_at > NOW()")
	}
	if filter.StoryID != nil && *filter.StoryID != uuid.Nil {
		args = append(args, *filter.StoryID)
		clauses = append(clauses, fmt.Sprintf("stories.id = $%d", len(args)))
	}
	if filter.AuthorUserID != nil && *filter.AuthorUserID != uuid.Nil {
		args = append(args, *filter.AuthorUserID)
		clauses = append(clauses, fmt.Sprintf("stories.author_user_id = $%d", len(args)))
	}

	viewerUserIDPos := 0
	seenJoin := ""
	seenOrder := ""
	if filter.ViewerUserID != nil && *filter.ViewerUserID != uuid.Nil {
		args = append(args, *filter.ViewerUserID)
		viewerUserIDPos = len(args)
		seenJoin = fmt.Sprintf(`
			LEFT JOIN story_seen seen
			  ON seen.story_id = stories.id
			 AND seen.viewer_user_id = $%d
		`, viewerUserIDPos)
		seenOrder = "CASE WHEN seen.seen_at IS NULL THEN 0 ELSE 1 END ASC,"
	}

	limit := filter.Limit
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	offset := filter.Offset
	if offset < 0 {
		offset = 0
	}
	args = append(args, limit, offset)
	limitPos := len(args) - 1
	offsetPos := len(args)

	query := fmt.Sprintf(`
		SELECT
			stories.id,
			stories.author_user_id,
			stories.caption,
			stories.media_file_id,
			stories.cover_file_id,
			stories.media_type,
			stories.view_count,
			stories.like_count,
			stories.reply_count,
			stories.expires_at,
			stories.created_at,
			stories.updated_at,
			stories.deleted_at
		FROM stories
		%s
		WHERE %s
		ORDER BY %s stories.created_at DESC, stories.id DESC
		LIMIT $%d OFFSET $%d
	`, seenJoin, strings.Join(clauses, " AND "), seenOrder, limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query stories: %w", err)
	}
	defer rows.Close()

	items := make([]*model.Story, 0)
	for rows.Next() {
		item, scanErr := scanStory(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan story: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) MarkStorySeen(ctx context.Context, storyID uuid.UUID, viewerUserID uuid.UUID, seenAt time.Time) (time.Time, error) {
	var storedSeenAt time.Time
	err := r.pool.QueryRow(ctx, `
		INSERT INTO story_seen (story_id, viewer_user_id, seen_at)
		VALUES ($1, $2, $3)
		ON CONFLICT (story_id, viewer_user_id)
		DO UPDATE SET seen_at = GREATEST(story_seen.seen_at, EXCLUDED.seen_at)
		RETURNING seen_at
	`, storyID, viewerUserID, seenAt.UTC()).Scan(&storedSeenAt)
	if err != nil {
		return time.Time{}, fmt.Errorf("upsert story seen marker: %w", err)
	}
	return storedSeenAt.UTC(), nil
}

func (r *PGPostRepository) ListStorySeenByUser(ctx context.Context, storyIDs []uuid.UUID, userID uuid.UUID) (map[uuid.UUID]time.Time, error) {
	result := make(map[uuid.UUID]time.Time)
	if len(storyIDs) == 0 || userID == uuid.Nil {
		return result, nil
	}
	rows, err := r.pool.Query(ctx, `
		SELECT story_id, seen_at
		FROM story_seen
		WHERE viewer_user_id = $1 AND story_id = ANY($2)
	`, userID, storyIDs)
	if err != nil {
		return nil, fmt.Errorf("query story seen markers: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var storyID uuid.UUID
		var seenAt time.Time
		if err = rows.Scan(&storyID, &seenAt); err != nil {
			return nil, fmt.Errorf("scan story seen marker: %w", err)
		}
		result[storyID] = seenAt.UTC()
	}
	return result, rows.Err()
}

func (r *PGPostRepository) LikeStory(ctx context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin story like tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const insertQuery = `
		INSERT INTO story_likes (story_id, user_id, created_at)
		VALUES ($1, $2, NOW())
		ON CONFLICT (story_id, user_id) DO NOTHING
	`
	tag, err := tx.Exec(ctx, insertQuery, storyID, userID)
	if err != nil {
		return false, 0, fmt.Errorf("insert story like: %w", classifyPGError(err))
	}

	changed := tag.RowsAffected() > 0
	if changed {
		if _, err = tx.Exec(ctx, `UPDATE stories SET like_count = like_count + 1 WHERE id = $1`, storyID); err != nil {
			return false, 0, fmt.Errorf("increment story like count: %w", classifyPGError(err))
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
		return false, 0, fmt.Errorf("commit story like tx: %w", err)
	}

	return changed, likeCount, nil
}

func scanStory(scanner interface{ Scan(dest ...any) error }) (*model.Story, error) {
	var item model.Story
	var mediaTypeRaw string
	if err := scanner.Scan(
		&item.ID,
		&item.AuthorUserID,
		&item.Caption,
		&item.MediaFileID,
		&item.CoverFileID,
		&mediaTypeRaw,
		&item.ViewCount,
		&item.LikeCount,
		&item.ReplyCount,
		&item.ExpiresAt,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.DeletedAt,
	); err != nil {
		return nil, err
	}
	item.MediaType = enum.StoryMediaType(mediaTypeRaw)
	return &item, nil
}
