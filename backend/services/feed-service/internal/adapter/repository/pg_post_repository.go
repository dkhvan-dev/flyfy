package repository

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

type PGPostRepository struct {
	pool                *pgxpool.Pool
	feedRankingPolicy   FeedRankingPolicy
	postPublishCooldown time.Duration
}

func NewPGPostRepository(pool *pgxpool.Pool) *PGPostRepository {
	return &PGPostRepository{
		pool:                pool,
		feedRankingPolicy:   DefaultFeedRankingPolicy(),
		postPublishCooldown: 5 * time.Minute,
	}
}

func (r *PGPostRepository) WithFeedRankingPolicy(policy FeedRankingPolicy) *PGPostRepository {
	r.feedRankingPolicy = policy.normalized()
	return r
}

func (r *PGPostRepository) WithPostPublishCooldown(cooldown time.Duration) *PGPostRepository {
	if cooldown > 0 {
		r.postPublishCooldown = cooldown
	}
	return r
}

func (r *PGPostRepository) CreatePost(ctx context.Context, post *model.Post) error {
	normalizePostContentEngineFields(post)

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)
	if post.Status == enum.PostStatusPublished && post.PublishedAt != nil {
		if err = reservePostPublishCooldownTx(ctx, tx, post.AuthorUserID, post.ID, r.postPublishCooldown); err != nil {
			return err
		}
	}

	const postQuery = `
		INSERT INTO posts (
			id, slug, author_user_id, title, excerpt, content, category, status,
			media_status, community_id, community_instance_id, post_kind, post_profile_key, post_profile_version,
			structured_data, moderation_mode, source_activity_id, activity_creation_status, activity_creation_error,
			cover_file_id, place_name, place_country_code, place_city_id, tags,
			view_count, like_count, comment_count, share_count, published_at,
			format, content_schema_version, content_blocks, content_plain_text,
			revision, expires_at, last_autosaved_at, archived_at, moderation_status,
			created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8,
			$9, $10, $11, $12, $13, $14,
			$15, $16, $17, $18, $19,
			$20, $21, $22, $23, $24,
			$25, $26, $27, $28, $29,
			$30, $31, $32, $33,
			$34, $35, $36, $37, $38,
			$39, $40
		)
	`

	if _, err = tx.Exec(
		ctx,
		postQuery,
		post.ID,
		post.Slug,
		post.AuthorUserID,
		post.Title,
		post.Excerpt,
		post.Content,
		string(post.Category),
		string(post.Status),
		string(post.MediaStatus),
		post.CommunityID,
		post.CommunityInstanceID,
		string(post.PostKind),
		string(post.PostProfileKey),
		post.PostProfileVersion,
		post.StructuredData,
		string(post.ModerationMode),
		post.SourceActivityID,
		activityCreationStatusString(post.ActivityCreationStatus),
		post.ActivityCreationError,
		post.CoverFileID,
		post.PlaceName,
		post.PlaceCountryCode,
		post.PlaceCityID,
		post.Tags,
		post.ViewCount,
		post.LikeCount,
		post.CommentCount,
		post.ShareCount,
		post.PublishedAt,
		string(post.Format),
		post.ContentSchemaVersion,
		post.ContentBlocks,
		post.ContentPlainText,
		post.Revision,
		post.ExpiresAt,
		post.LastAutosavedAt,
		post.ArchivedAt,
		string(post.ModerationStatus),
		post.CreatedAt,
		post.UpdatedAt,
	); err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert post: %w", err)
	}

	const sketchQuery = `
		INSERT INTO post_view_sketches (post_id, registers, updated_at)
		VALUES ($1, $2, NOW())
	`
	if _, err = tx.Exec(ctx, sketchQuery, post.ID, post.ViewHLL); err != nil {
		return fmt.Errorf("insert post view sketch: %w", err)
	}
	if err = replacePostMediaTx(ctx, tx, post); err != nil {
		return err
	}
	if err = applyCommunityPostCountDeltas(ctx, tx, postCommunityPostCountDeltas(nil, post)); err != nil {
		return err
	}
	if err = syncPostFeedItemTx(ctx, tx, post); err != nil {
		return err
	}
	if err = enqueuePostFeedProjectionForPostTx(ctx, tx, post); err != nil {
		return err
	}
	if err = enqueuePostActivityIntentForPostTx(ctx, tx, post); err != nil {
		return err
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit post create tx: %w", err)
	}

	return nil
}

func (r *PGPostRepository) UpdatePost(ctx context.Context, post *model.Post) error {
	if err := validatePostUpdateRevision(post); err != nil {
		return err
	}

	normalizePostContentEngineFields(post)

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin update post tx: %w", err)
	}
	defer tx.Rollback(ctx)

	previousPost, err := lockPostForCommunityPostCount(ctx, tx, post.ID, post.Revision)
	if err != nil {
		return err
	}
	if previousPost.Status != enum.PostStatusPublished &&
		previousPost.PublishedAt == nil &&
		post.Status == enum.PostStatusPublished &&
		post.PublishedAt != nil {
		if err = reservePostPublishCooldownTx(ctx, tx, post.AuthorUserID, post.ID, r.postPublishCooldown); err != nil {
			return err
		}
	}

	const query = `
		UPDATE posts
		SET
			slug = $2,
			title = $3,
			excerpt = $4,
			content = $5,
			category = $6,
			status = $7,
			media_status = $8,
			community_id = $9,
			community_instance_id = $10,
			post_kind = $11,
			post_profile_key = $12,
			post_profile_version = $13,
			structured_data = $14,
			moderation_mode = $15,
			source_activity_id = $16,
			activity_creation_status = $17,
			activity_creation_error = $18,
			cover_file_id = $19,
			place_name = $20,
			place_country_code = $21,
			place_city_id = $22,
			tags = $23,
			published_at = $24,
			updated_at = $25,
			format = $26,
			content_schema_version = $27,
			content_blocks = $28,
			content_plain_text = $29,
			revision = revision + 1,
			last_autosaved_at = $30,
			archived_at = $31,
			moderation_status = $32,
			expires_at = $33
		WHERE id = $1 AND revision = $34 AND deleted_at IS NULL
	`

	tag, err := tx.Exec(
		ctx,
		query,
		post.ID,
		post.Slug,
		post.Title,
		post.Excerpt,
		post.Content,
		string(post.Category),
		string(post.Status),
		string(post.MediaStatus),
		post.CommunityID,
		post.CommunityInstanceID,
		string(post.PostKind),
		string(post.PostProfileKey),
		post.PostProfileVersion,
		post.StructuredData,
		string(post.ModerationMode),
		post.SourceActivityID,
		activityCreationStatusString(post.ActivityCreationStatus),
		post.ActivityCreationError,
		post.CoverFileID,
		post.PlaceName,
		post.PlaceCountryCode,
		post.PlaceCityID,
		post.Tags,
		post.PublishedAt,
		post.UpdatedAt,
		string(post.Format),
		post.ContentSchemaVersion,
		post.ContentBlocks,
		post.ContentPlainText,
		post.LastAutosavedAt,
		post.ArchivedAt,
		string(post.ModerationStatus),
		post.ExpiresAt,
		post.Revision,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("update post: %w", err)
	}
	if err = postUpdateRowsAffectedError(tag.RowsAffected()); err != nil {
		return err
	}
	if err = replacePostMediaTx(ctx, tx, post); err != nil {
		return err
	}
	if err = applyCommunityPostCountDeltas(ctx, tx, postCommunityPostCountDeltas(previousPost, post)); err != nil {
		return err
	}
	if err = syncPostFeedItemTx(ctx, tx, post); err != nil {
		return err
	}
	if err = enqueuePostFeedProjectionForPostTx(ctx, tx, post); err != nil {
		return err
	}
	if err = enqueuePostActivityIntentForPostTx(ctx, tx, post); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit update post tx: %w", err)
	}
	return nil
}

func (r *PGPostRepository) ReviewCommunityPost(ctx context.Context, post *model.Post, decision *model.PostModerationDecision) error {
	if err := validatePostUpdateRevision(post); err != nil {
		return err
	}
	if decision == nil {
		return fmt.Errorf("moderation decision is required")
	}

	normalizePostContentEngineFields(post)

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	previousPost, err := lockPostForCommunityPostCount(ctx, tx, post.ID, post.Revision)
	if err != nil {
		return err
	}

	const updateQuery = `
		UPDATE posts
		SET
			slug = $2,
			title = $3,
			excerpt = $4,
			content = $5,
			category = $6,
			status = $7,
			community_id = $8,
			community_instance_id = $9,
			post_kind = $10,
			post_profile_key = $11,
			post_profile_version = $12,
			structured_data = $13,
			moderation_mode = $14,
			source_activity_id = $15,
			activity_creation_status = $16,
			activity_creation_error = $17,
			cover_file_id = $18,
			place_name = $19,
			place_country_code = $20,
			place_city_id = $21,
			tags = $22,
			published_at = $23,
			updated_at = $24,
			format = $25,
			content_schema_version = $26,
			content_blocks = $27,
			content_plain_text = $28,
			revision = revision + 1,
			last_autosaved_at = $29,
			archived_at = $30,
			moderation_status = $31,
			expires_at = $32
		WHERE id = $1 AND revision = $33 AND deleted_at IS NULL
	`

	tag, err := tx.Exec(
		ctx,
		updateQuery,
		post.ID,
		post.Slug,
		post.Title,
		post.Excerpt,
		post.Content,
		string(post.Category),
		string(post.Status),
		post.CommunityID,
		post.CommunityInstanceID,
		string(post.PostKind),
		string(post.PostProfileKey),
		post.PostProfileVersion,
		post.StructuredData,
		string(post.ModerationMode),
		post.SourceActivityID,
		activityCreationStatusString(post.ActivityCreationStatus),
		post.ActivityCreationError,
		post.CoverFileID,
		post.PlaceName,
		post.PlaceCountryCode,
		post.PlaceCityID,
		post.Tags,
		post.PublishedAt,
		post.UpdatedAt,
		string(post.Format),
		post.ContentSchemaVersion,
		post.ContentBlocks,
		post.ContentPlainText,
		post.LastAutosavedAt,
		post.ArchivedAt,
		string(post.ModerationStatus),
		post.ExpiresAt,
		post.Revision,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("update post during community review: %w", err)
	}
	if err = postUpdateRowsAffectedError(tag.RowsAffected()); err != nil {
		return err
	}
	if err = applyCommunityPostCountDeltas(ctx, tx, postCommunityPostCountDeltas(previousPost, post)); err != nil {
		return err
	}
	if err = syncPostFeedItemTx(ctx, tx, post); err != nil {
		return err
	}
	if err = enqueuePostFeedProjectionForPostTx(ctx, tx, post); err != nil {
		return err
	}
	if err = enqueuePostActivityIntentForPostTx(ctx, tx, post); err != nil {
		return err
	}

	const decisionQuery = `
		INSERT INTO post_community_moderation_decisions (
			id, post_id, community_id, moderator_user_id, decision,
			previous_status, next_status, post_revision, reason, created_at
		) VALUES (
			$1, $2, $3, $4, $5,
			$6, $7, $8, $9, $10
		)
	`
	if _, err = tx.Exec(
		ctx,
		decisionQuery,
		decision.ID,
		decision.PostID,
		decision.CommunityID,
		decision.ModeratorUserID,
		string(decision.Decision),
		string(decision.PreviousStatus),
		string(decision.NextStatus),
		decision.PostRevision,
		decision.Reason,
		decision.CreatedAt,
	); err != nil {
		return fmt.Errorf("insert community post moderation decision: %w", err)
	}

	if err = insertPostModerationOutboxTx(ctx, tx, postModerationOutboxEvent{
		EventType:     postModerationOutboxEventPostReviewed,
		AggregateType: postModerationOutboxAggregatePost,
		AggregateID:   decision.PostID,
		CommunityID:   &decision.CommunityID,
		PostID:        &decision.PostID,
		ActorUserID:   decision.ModeratorUserID,
		Payload: map[string]any{
			"decisionId":     decision.ID,
			"decision":       decision.Decision,
			"previousStatus": decision.PreviousStatus,
			"nextStatus":     decision.NextStatus,
			"postRevision":   decision.PostRevision,
			"reason":         decision.Reason,
		},
		CreatedAt: decision.CreatedAt,
	}); err != nil {
		return fmt.Errorf("insert community post moderation outbox event: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit community post review tx: %w", err)
	}
	return nil
}

func (r *PGPostRepository) ListCommunityPostModerationDecisions(ctx context.Context, filter model.PostModerationDecisionListFilter) ([]*model.PostModerationDecision, error) {
	limit := filter.Limit
	if limit <= 0 {
		limit = 20
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	const query = `
		SELECT
			id, post_id, community_id, moderator_user_id, decision,
			previous_status, next_status, post_revision, reason, created_at
		FROM post_community_moderation_decisions
		WHERE post_id = $1 AND community_id = $2
		ORDER BY created_at DESC
		LIMIT $3 OFFSET $4
	`
	rows, err := r.pool.Query(ctx, query, filter.PostID, filter.CommunityID, limit, filter.Offset)
	if err != nil {
		return nil, fmt.Errorf("query community post moderation decisions: %w", err)
	}
	defer rows.Close()

	items := make([]*model.PostModerationDecision, 0)
	for rows.Next() {
		item, scanErr := scanPostModerationDecision(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan community post moderation decision: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) CreatePostReport(ctx context.Context, report *model.PostReport, autoHideThreshold int) (*model.PostReportSubmissionResult, error) {
	if report == nil || report.ID == uuid.Nil || report.PostID == uuid.Nil || report.ReporterUserID == uuid.Nil || report.AuthorUserID == uuid.Nil {
		return nil, fmt.Errorf("post report is invalid")
	}
	if !report.Reason.IsValid() || !report.Status.IsValid() {
		return nil, fmt.Errorf("post report status or reason is invalid")
	}
	if autoHideThreshold <= 0 {
		autoHideThreshold = 3
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin post report tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const insertQuery = `
		INSERT INTO post_reports (
			id, post_id, community_id, reporter_user_id, author_user_id,
			reason, details, status, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5,
			$6, $7, $8, $9, $10
		)
		ON CONFLICT (post_id, reporter_user_id) WHERE status = 'OPEN'
		DO NOTHING
		RETURNING
			id, post_id, community_id, reporter_user_id, author_user_id,
			reason, details, status, resolved_by_user_id, resolution_note,
			created_at, updated_at, resolved_at
	`
	storedReport, err := scanPostReport(tx.QueryRow(
		ctx,
		insertQuery,
		report.ID,
		report.PostID,
		report.CommunityID,
		report.ReporterUserID,
		report.AuthorUserID,
		string(report.Reason),
		report.Details,
		string(report.Status),
		report.CreatedAt,
		report.UpdatedAt,
	))
	insertedReport := true
	if err != nil {
		if !errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("insert post report: %w", classifyPGError(err))
		}
		insertedReport = false
		const existingReportQuery = `
			SELECT
				id, post_id, community_id, reporter_user_id, author_user_id,
				reason, details, status, resolved_by_user_id, resolution_note,
				created_at, updated_at, resolved_at
			FROM post_reports
			WHERE post_id = $1 AND reporter_user_id = $2 AND status = $3
			LIMIT 1
		`
		storedReport, err = scanPostReport(tx.QueryRow(
			ctx,
			existingReportQuery,
			report.PostID,
			report.ReporterUserID,
			string(enum.PostReportStatusOpen),
		))
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return nil, ErrNotFound
			}
			return nil, fmt.Errorf("select existing post report: %w", err)
		}
	}

	if insertedReport {
		if err = insertPostModerationOutboxTx(ctx, tx, postModerationOutboxEvent{
			EventType:     postModerationOutboxEventReportCreated,
			AggregateType: postModerationOutboxAggregatePostReport,
			AggregateID:   storedReport.ID,
			CommunityID:   storedReport.CommunityID,
			PostID:        &storedReport.PostID,
			ActorUserID:   storedReport.ReporterUserID,
			Payload: map[string]any{
				"reportId":       storedReport.ID,
				"postId":         storedReport.PostID,
				"communityId":    storedReport.CommunityID,
				"reporterUserId": storedReport.ReporterUserID,
				"authorUserId":   storedReport.AuthorUserID,
				"reason":         storedReport.Reason,
				"details":        storedReport.Details,
			},
			CreatedAt: storedReport.CreatedAt,
		}); err != nil {
			return nil, fmt.Errorf("insert post report created outbox event: %w", err)
		}
	}

	var openCount int
	if err = tx.QueryRow(
		ctx,
		`SELECT COUNT(*) FROM post_reports WHERE post_id = $1 AND status = $2`,
		report.PostID,
		string(enum.PostReportStatusOpen),
	).Scan(&openCount); err != nil {
		return nil, fmt.Errorf("count open post reports: %w", err)
	}

	post, err := scanPost(tx.QueryRow(
		ctx,
		`SELECT
			id, slug, author_user_id, title, excerpt, content, category, status,
			community_id, community_instance_id, post_kind, post_profile_key, post_profile_version,
			structured_data, moderation_mode, source_activity_id, activity_creation_status, activity_creation_error,
			cover_file_id, place_name, place_country_code, place_city_id, tags,
			view_count, like_count, comment_count, share_count, published_at, expires_at,
			created_at, updated_at, deleted_at,
			format, content_schema_version, content_blocks, content_plain_text,
			revision, last_autosaved_at, archived_at, moderation_status, media_status
		FROM posts
		WHERE id = $1 AND deleted_at IS NULL
		FOR UPDATE`,
		report.PostID,
	))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("lock post for report: %w", err)
	}

	autoHidden := false
	if insertedReport &&
		openCount >= autoHideThreshold &&
		post.ModerationStatus != enum.ModerationStatusHidden &&
		post.ModerationStatus != enum.ModerationStatusRejected {
		const updateQuery = `
			UPDATE posts
			SET
				moderation_status = $2,
				revision = revision + 1,
				updated_at = NOW()
			WHERE id = $1 AND deleted_at IS NULL
			RETURNING revision, updated_at
		`
		if err = tx.QueryRow(
			ctx,
			updateQuery,
			post.ID,
			string(enum.ModerationStatusHidden),
		).Scan(&post.Revision, &post.UpdatedAt); err != nil {
			return nil, fmt.Errorf("auto-hide reported post: %w", err)
		}
		post.ModerationStatus = enum.ModerationStatusHidden
		autoHidden = true
		if err = deletePostFeedItemTx(ctx, tx, post.ID); err != nil {
			return nil, err
		}
		if err = enqueuePostFeedProjectionDeleteTx(ctx, tx, post.ID, post.Revision, post.UpdatedAt); err != nil {
			return nil, err
		}

		if err = insertPostModerationOutboxTx(ctx, tx, postModerationOutboxEvent{
			EventType:     postModerationOutboxEventReportAutoHidden,
			AggregateType: postModerationOutboxAggregatePost,
			AggregateID:   post.ID,
			CommunityID:   post.CommunityID,
			PostID:        &post.ID,
			ActorUserID:   storedReport.ReporterUserID,
			Payload: map[string]any{
				"reportId":         storedReport.ID,
				"postId":           post.ID,
				"communityId":      post.CommunityID,
				"openReportsCount": openCount,
				"threshold":        autoHideThreshold,
				"moderationStatus": post.ModerationStatus,
				"postRevision":     post.Revision,
			},
			CreatedAt: post.UpdatedAt,
		}); err != nil {
			return nil, fmt.Errorf("insert post report auto-hide outbox event: %w", err)
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit post report tx: %w", err)
	}

	return &model.PostReportSubmissionResult{
		Report:           storedReport,
		Post:             post,
		OpenReportsCount: openCount,
		AutoHidden:       autoHidden,
	}, nil
}

func (r *PGPostRepository) ListCommunityPostReports(ctx context.Context, filter model.PostReportListFilter) ([]*model.PostReport, error) {
	limit := filter.Limit
	if limit <= 0 {
		limit = 20
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	args := []any{}
	clauses := []string{}
	if filter.CommunityID != uuid.Nil {
		args = append(args, filter.CommunityID)
		clauses = append(clauses, fmt.Sprintf("community_id = $%d", len(args)))
	}
	if filter.Status != nil {
		args = append(args, string(*filter.Status))
		clauses = append(clauses, fmt.Sprintf("status = $%d", len(args)))
	}
	if len(clauses) == 0 {
		clauses = append(clauses, "TRUE")
	}
	args = append(args, limit, filter.Offset)
	limitPos := len(args) - 1
	offsetPos := len(args)

	query := fmt.Sprintf(`
		SELECT
			id, post_id, community_id, reporter_user_id, author_user_id,
			reason, details, status, resolved_by_user_id, resolution_note,
			created_at, updated_at, resolved_at
		FROM post_reports
		WHERE %s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d
	`, strings.Join(clauses, " AND "), limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query post reports: %w", err)
	}
	defer rows.Close()

	items := make([]*model.PostReport, 0)
	for rows.Next() {
		item, scanErr := scanPostReport(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan post report: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) GetPostReport(ctx context.Context, reportID uuid.UUID) (*model.PostReport, error) {
	if reportID == uuid.Nil {
		return nil, port.ErrPostReportNotFound
	}
	row := r.pool.QueryRow(ctx, `
		SELECT
			id, post_id, community_id, reporter_user_id, author_user_id,
			reason, details, status, resolved_by_user_id, resolution_note,
			created_at, updated_at, resolved_at
		FROM post_reports
		WHERE id = $1
	`, reportID)
	item, err := scanPostReport(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, port.ErrPostReportNotFound
		}
		return nil, fmt.Errorf("get post report: %w", err)
	}
	return item, nil
}

func (r *PGPostRepository) ResolvePostReport(ctx context.Context, resolution *model.PostReportResolution) (*model.PostReport, error) {
	if resolution == nil ||
		resolution.ReportID == uuid.Nil ||
		resolution.ResolvedByUserID == uuid.Nil ||
		!resolution.Status.IsValid() ||
		resolution.Status == enum.PostReportStatusOpen {
		return nil, fmt.Errorf("post report resolution is invalid")
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin post report resolution tx: %w", err)
	}
	defer tx.Rollback(ctx)

	selectQuery := `
		SELECT
			id, post_id, community_id, reporter_user_id, author_user_id,
			reason, details, status, resolved_by_user_id, resolution_note,
			created_at, updated_at, resolved_at
		FROM post_reports
		WHERE id = $1
	`
	selectArgs := []any{resolution.ReportID}
	if resolution.CommunityID != uuid.Nil {
		selectArgs = append(selectArgs, resolution.CommunityID)
		selectQuery += fmt.Sprintf(" AND community_id = $%d", len(selectArgs))
	}
	selectQuery += `
		FOR UPDATE
	`
	report, err := scanPostReport(tx.QueryRow(ctx, selectQuery, selectArgs...))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, port.ErrPostReportNotFound
		}
		return nil, fmt.Errorf("lock post report: %w", err)
	}
	if report.Status != enum.PostReportStatusOpen {
		return nil, port.ErrPostReportAlreadyResolved
	}

	updateQuery := `
		UPDATE post_reports
		SET
			status = $2,
			resolved_by_user_id = $3,
			resolution_note = $4,
			resolved_at = $5,
			updated_at = $5
		WHERE id = $1
	`
	updateArgs := []any{
		resolution.ReportID,
		string(resolution.Status),
		resolution.ResolvedByUserID,
		resolution.ResolutionNote,
		resolution.ResolvedAt,
	}
	if resolution.CommunityID != uuid.Nil {
		updateArgs = append(updateArgs, resolution.CommunityID)
		updateQuery += fmt.Sprintf(" AND community_id = $%d", len(updateArgs))
	}
	updateArgs = append(updateArgs, string(enum.PostReportStatusOpen))
	updateQuery += fmt.Sprintf(" AND status = $%d", len(updateArgs))
	updateQuery += `
		RETURNING
			id, post_id, community_id, reporter_user_id, author_user_id,
			reason, details, status, resolved_by_user_id, resolution_note,
			created_at, updated_at, resolved_at
	`
	resolved, err := scanPostReport(tx.QueryRow(ctx, updateQuery, updateArgs...))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, port.ErrPostReportAlreadyResolved
		}
		return nil, fmt.Errorf("update post report resolution: %w", err)
	}

	if err = insertPostModerationOutboxTx(ctx, tx, postModerationOutboxEvent{
		EventType:     postModerationOutboxEventReportResolved,
		AggregateType: postModerationOutboxAggregatePostReport,
		AggregateID:   resolved.ID,
		CommunityID:   resolved.CommunityID,
		PostID:        &resolved.PostID,
		ActorUserID:   resolution.ResolvedByUserID,
		Payload: map[string]any{
			"reportId":         resolved.ID,
			"postId":           resolved.PostID,
			"communityId":      resolved.CommunityID,
			"status":           resolved.Status,
			"resolvedByUserId": resolution.ResolvedByUserID,
			"resolutionNote":   resolved.ResolutionNote,
		},
		CreatedAt: resolution.ResolvedAt,
	}); err != nil {
		return nil, fmt.Errorf("insert post report resolved outbox event: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit post report resolution tx: %w", err)
	}

	return resolved, nil
}

func (r *PGPostRepository) ListDuePostModerationOutboxEvents(
	ctx context.Context,
	limit int,
	now time.Time,
) ([]model.PostModerationOutboxEvent, error) {
	if limit <= 0 {
		limit = 50
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	rows, err := r.pool.Query(ctx, `
		WITH due AS (
			SELECT id
			FROM post_moderation_outbox
			WHERE status = 'PENDING'
			  AND next_attempt_at <= $1
			ORDER BY created_at ASC, id ASC
			LIMIT $2
			FOR UPDATE SKIP LOCKED
		)
		UPDATE post_moderation_outbox AS outbox
		SET next_attempt_at = $1 + INTERVAL '30 seconds'
		FROM due
		WHERE outbox.id = due.id
		RETURNING outbox.id, outbox.event_type, outbox.aggregate_type, outbox.aggregate_id,
		          outbox.community_id, outbox.post_id, outbox.actor_user_id, outbox.payload,
		          outbox.status, outbox.attempt_count, outbox.next_attempt_at, outbox.last_error,
		          outbox.created_at, outbox.delivered_at
	`, now, limit)
	if err != nil {
		return nil, fmt.Errorf("list due post moderation outbox events: %w", err)
	}
	defer rows.Close()

	items := make([]model.PostModerationOutboxEvent, 0)
	for rows.Next() {
		item, scanErr := scanPostModerationOutboxEvent(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan post moderation outbox event: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) MarkPostModerationOutboxDelivered(ctx context.Context, eventID uuid.UUID, deliveredAt time.Time) error {
	if deliveredAt.IsZero() {
		deliveredAt = time.Now().UTC()
	}
	if _, err := r.pool.Exec(ctx, `
		UPDATE post_moderation_outbox
		SET status = 'DELIVERED',
		    delivered_at = $2,
		    last_error = ''
		WHERE id = $1
		  AND status <> 'DELIVERED'
	`, eventID, deliveredAt); err != nil {
		return fmt.Errorf("mark post moderation outbox delivered: %w", err)
	}
	return nil
}

func (r *PGPostRepository) MarkPostModerationOutboxFailed(ctx context.Context, eventID uuid.UUID, reason string, nextAttemptAt time.Time) error {
	if nextAttemptAt.IsZero() {
		nextAttemptAt = time.Now().UTC().Add(time.Second)
	}
	if _, err := r.pool.Exec(ctx, `
		UPDATE post_moderation_outbox
		SET attempt_count = attempt_count + 1,
		    status = CASE WHEN attempt_count + 1 >= 20 THEN 'DEAD' ELSE 'PENDING' END,
		    last_error = $2,
		    next_attempt_at = $3
		WHERE id = $1
		  AND status = 'PENDING'
	`, eventID, strings.TrimSpace(reason), nextAttemptAt); err != nil {
		return fmt.Errorf("mark post moderation outbox failed: %w", err)
	}
	return nil
}

func (r *PGPostRepository) SoftDeletePost(ctx context.Context, postID uuid.UUID, authorUserID uuid.UUID) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin soft delete post tx: %w", err)
	}
	defer tx.Rollback(ctx)

	previousPost, err := lockOwnedPostForCommunityPostCount(ctx, tx, postID, authorUserID)
	if err != nil {
		return err
	}

	const query = `
		UPDATE posts
		SET deleted_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND author_user_id = $2 AND deleted_at IS NULL
	`

	tag, err := tx.Exec(ctx, query, postID, authorUserID)
	if err != nil {
		return fmt.Errorf("soft delete post: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	deletedPost := *previousPost
	deletedAt := time.Now().UTC()
	deletedPost.DeletedAt = &deletedAt
	deletedPost.UpdatedAt = deletedAt
	if err = applyCommunityPostCountDeltas(ctx, tx, postCommunityPostCountDeltas(previousPost, &deletedPost)); err != nil {
		return err
	}
	if err = deletePostFeedItemTx(ctx, tx, postID); err != nil {
		return err
	}
	if err = enqueuePostFeedProjectionDeleteTx(ctx, tx, postID, previousPost.Revision, deletedAt); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit soft delete post tx: %w", err)
	}
	return nil
}

func lockPostForCommunityPostCount(ctx context.Context, tx communityTx, postID uuid.UUID, revision int64) (*model.Post, error) {
	const query = `
		SELECT community_id, status, archived_at, deleted_at, moderation_status, expires_at
		FROM posts
		WHERE id = $1 AND revision = $2 AND deleted_at IS NULL
		FOR UPDATE
	`
	post, err := scanPostPostCountState(tx.QueryRow(ctx, query, postID, revision))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, port.ErrPostRevisionConflict
	}
	if err != nil {
		return nil, fmt.Errorf("lock post for community post count: %w", err)
	}
	return post, nil
}

func lockOwnedPostForCommunityPostCount(ctx context.Context, tx communityTx, postID uuid.UUID, authorUserID uuid.UUID) (*model.Post, error) {
	const query = `
		SELECT community_id, status, archived_at, deleted_at, moderation_status, expires_at
		FROM posts
		WHERE id = $1 AND author_user_id = $2 AND deleted_at IS NULL
		FOR UPDATE
	`
	post, err := scanPostPostCountState(tx.QueryRow(ctx, query, postID, authorUserID))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("lock owned post for community post count: %w", err)
	}
	return post, nil
}

func scanPostPostCountState(scanner interface{ Scan(dest ...any) error }) (*model.Post, error) {
	var (
		post            model.Post
		statusRaw       string
		moderationRaw   string
		archivedAtValue sql.NullTime
		deletedAtValue  sql.NullTime
		expiresAtValue  sql.NullTime
	)
	if err := scanner.Scan(
		&post.CommunityID,
		&statusRaw,
		&archivedAtValue,
		&deletedAtValue,
		&moderationRaw,
		&expiresAtValue,
	); err != nil {
		return nil, err
	}
	post.Status = enum.PostStatus(strings.ToUpper(strings.TrimSpace(statusRaw)))
	post.ModerationStatus = enum.NormalizeModerationStatus(enum.ModerationStatus(moderationRaw))
	if archivedAtValue.Valid {
		post.ArchivedAt = &archivedAtValue.Time
	}
	if deletedAtValue.Valid {
		post.DeletedAt = &deletedAtValue.Time
	}
	if expiresAtValue.Valid {
		post.ExpiresAt = &expiresAtValue.Time
	}
	return &post, nil
}

func postCommunityPostCountDeltas(previous *model.Post, next *model.Post) map[uuid.UUID]int {
	deltas := make(map[uuid.UUID]int, 2)
	if communityID, ok := countableCommunityPost(previous); ok {
		deltas[communityID]--
	}
	if communityID, ok := countableCommunityPost(next); ok {
		deltas[communityID]++
	}
	for communityID, delta := range deltas {
		if delta == 0 {
			delete(deltas, communityID)
		}
	}
	return deltas
}

func countableCommunityPost(post *model.Post) (uuid.UUID, bool) {
	if post == nil ||
		post.CommunityID == nil ||
		*post.CommunityID == uuid.Nil ||
		!post.IsPubliclyVisible() {
		return uuid.Nil, false
	}
	return *post.CommunityID, true
}

func applyCommunityPostCountDeltas(ctx context.Context, tx communityTx, deltas map[uuid.UUID]int) error {
	communityIDs := make([]uuid.UUID, 0, len(deltas))
	for communityID := range deltas {
		communityIDs = append(communityIDs, communityID)
	}
	sort.Slice(communityIDs, func(i, j int) bool {
		return communityIDs[i].String() < communityIDs[j].String()
	})

	for _, communityID := range communityIDs {
		delta := deltas[communityID]
		if delta == 0 {
			continue
		}
		if _, err := incrementCommunityPostCount(ctx, tx, communityID, delta); err != nil {
			return err
		}
	}
	return nil
}

func incrementCommunityPostCount(ctx context.Context, tx communityTx, communityID uuid.UUID, delta int) (int, error) {
	var count int
	if err := tx.QueryRow(
		ctx,
		`UPDATE communities
		 SET post_count = GREATEST(post_count + $2, 0), updated_at = NOW()
		 WHERE id = $1
		 RETURNING post_count`,
		communityID,
		delta,
	).Scan(&count); err != nil {
		return 0, fmt.Errorf("update community post count: %w", err)
	}
	return count, nil
}

func (r *PGPostRepository) GetPostByID(ctx context.Context, postID uuid.UUID) (*model.Post, error) {
	const query = `
			SELECT
				id, slug, author_user_id, title, excerpt, content, category, status,
				community_id, community_instance_id, post_kind, post_profile_key, post_profile_version,
				structured_data, moderation_mode, source_activity_id, activity_creation_status, activity_creation_error,
				cover_file_id, place_name, place_country_code, place_city_id, tags, view_count,
				like_count, comment_count, share_count, published_at, expires_at, created_at, updated_at, deleted_at,
				format, content_schema_version, content_blocks, content_plain_text, revision,
				last_autosaved_at, archived_at, moderation_status, media_status
		FROM posts
		WHERE id = $1
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, postID)
	item, err := scanPost(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select post by id: %w", err)
	}

	return item, nil
}

func (r *PGPostRepository) GetPostBySlug(ctx context.Context, slug string) (*model.Post, error) {
	const query = `
			SELECT
				id, slug, author_user_id, title, excerpt, content, category, status,
				community_id, community_instance_id, post_kind, post_profile_key, post_profile_version,
				structured_data, moderation_mode, source_activity_id, activity_creation_status, activity_creation_error,
				cover_file_id, place_name, place_country_code, place_city_id, tags, view_count,
				like_count, comment_count, share_count, published_at, expires_at, created_at, updated_at, deleted_at,
				format, content_schema_version, content_blocks, content_plain_text, revision,
				last_autosaved_at, archived_at, moderation_status, media_status
		FROM posts
		WHERE slug = $1 AND deleted_at IS NULL
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, strings.TrimSpace(slug))
	item, err := scanPost(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select post by slug: %w", err)
	}

	return item, nil
}

func (r *PGPostRepository) ListPosts(ctx context.Context, filter model.PostListFilter) ([]*model.Post, error) {
	args := make([]any, 0, 12)
	clauses := []string{"1=1"}

	if filter.OnlyPublished {
		args, clauses = appendPublicPostVisibilityClauses(args, clauses)
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
	if len(filter.ModerationStatuses) > 0 {
		raw := make([]string, 0, len(filter.ModerationStatuses))
		for _, status := range filter.ModerationStatuses {
			raw = append(raw, string(status))
		}
		args = append(args, raw)
		clauses = append(clauses, fmt.Sprintf("COALESCE(moderation_status, 'NOT_REQUIRED') = ANY($%d)", len(args)))
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
	if filter.ExcludePostID != nil && *filter.ExcludePostID != uuid.Nil {
		args = append(args, *filter.ExcludePostID)
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
	if len(filter.CommunityIDs) > 0 {
		args = append(args, filter.CommunityIDs)
		clauses = append(clauses, fmt.Sprintf("community_id = ANY($%d)", len(args)))
	}
	if filter.OnlyCommunityPosts {
		clauses = append(clauses, "community_id IS NOT NULL")
	}
	if filter.FollowedByUserID != nil && *filter.FollowedByUserID != uuid.Nil {
		args = append(args, *filter.FollowedByUserID)
		userIDPos := len(args)
		args = append(args, string(enum.CommunityMembershipStatusActive))
		statusPos := len(args)
		clauses = append(
			clauses,
			"community_id IS NOT NULL",
			fmt.Sprintf(
				"EXISTS (SELECT 1 FROM community_memberships scm WHERE scm.community_id = posts.community_id AND scm.user_id = $%d AND scm.status = $%d)",
				userIDPos,
				statusPos,
			),
		)
	}
	if filter.ExcludeFollowedByUserID != nil && *filter.ExcludeFollowedByUserID != uuid.Nil {
		args = append(args, *filter.ExcludeFollowedByUserID)
		userIDPos := len(args)
		args = append(args, string(enum.CommunityMembershipStatusActive))
		statusPos := len(args)
		clauses = append(
			clauses,
			fmt.Sprintf(
				"(community_id IS NULL OR NOT EXISTS (SELECT 1 FROM community_memberships scm WHERE scm.community_id = posts.community_id AND scm.user_id = $%d AND scm.status = $%d))",
				userIDPos,
				statusPos,
			),
		)
	}
	if filter.FeedCursorPublishedAt != nil && filter.FeedCursorPostID != nil && *filter.FeedCursorPostID != uuid.Nil {
		args = append(args, filter.FeedCursorPublishedAt.UTC())
		publishedAtPos := len(args)
		args = append(args, *filter.FeedCursorPostID)
		postIDPos := len(args)
		clauses = append(
			clauses,
			fmt.Sprintf("(COALESCE(published_at, created_at) < $%d OR (COALESCE(published_at, created_at) = $%d AND id < $%d))", publishedAtPos, publishedAtPos, postIDPos),
		)
	}

	orderBy := ""
	if filter.Sort == "related" {
		args, orderBy = appendRelatedPostOrderBy(args, filter)
	} else {
		orderBy = postListOrderBy(filter.Sort)
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
				community_id, community_instance_id, post_kind, post_profile_key, post_profile_version,
				structured_data, moderation_mode, source_activity_id, activity_creation_status, activity_creation_error,
				cover_file_id, place_name, place_country_code, place_city_id, tags, view_count,
				like_count, comment_count, share_count, published_at, expires_at, created_at, updated_at, deleted_at,
				format, content_schema_version, content_blocks, content_plain_text, revision,
				last_autosaved_at, archived_at, moderation_status, media_status
		FROM posts
		WHERE %s
		ORDER BY %s
		LIMIT $%d OFFSET $%d
	`, strings.Join(clauses, " AND "), orderBy, limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query posts: %w", err)
	}
	defer rows.Close()

	items := make([]*model.Post, 0)
	for rows.Next() {
		item, scanErr := scanPost(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan post list: %w", scanErr)
		}
		items = append(items, item)
	}

	return items, rows.Err()
}

func (r *PGPostRepository) CountPosts(ctx context.Context, filter model.PostListFilter) (int, error) {
	args := make([]any, 0, 10)
	clauses := []string{"1=1"}

	if filter.OnlyPublished {
		args, clauses = appendPublicPostVisibilityClauses(args, clauses)
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
	if len(filter.ModerationStatuses) > 0 {
		raw := make([]string, 0, len(filter.ModerationStatuses))
		for _, status := range filter.ModerationStatuses {
			raw = append(raw, string(status))
		}
		args = append(args, raw)
		clauses = append(clauses, fmt.Sprintf("COALESCE(moderation_status, 'NOT_REQUIRED') = ANY($%d)", len(args)))
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
	if filter.ExcludePostID != nil && *filter.ExcludePostID != uuid.Nil {
		args = append(args, *filter.ExcludePostID)
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
	if len(filter.CommunityIDs) > 0 {
		args = append(args, filter.CommunityIDs)
		clauses = append(clauses, fmt.Sprintf("community_id = ANY($%d)", len(args)))
	}
	if filter.OnlyCommunityPosts {
		clauses = append(clauses, "community_id IS NOT NULL")
	}
	if filter.FollowedByUserID != nil && *filter.FollowedByUserID != uuid.Nil {
		args = append(args, *filter.FollowedByUserID)
		userIDPos := len(args)
		args = append(args, string(enum.CommunityMembershipStatusActive))
		statusPos := len(args)
		clauses = append(
			clauses,
			"community_id IS NOT NULL",
			fmt.Sprintf(
				"EXISTS (SELECT 1 FROM community_memberships scm WHERE scm.community_id = posts.community_id AND scm.user_id = $%d AND scm.status = $%d)",
				userIDPos,
				statusPos,
			),
		)
	}
	if filter.ExcludeFollowedByUserID != nil && *filter.ExcludeFollowedByUserID != uuid.Nil {
		args = append(args, *filter.ExcludeFollowedByUserID)
		userIDPos := len(args)
		args = append(args, string(enum.CommunityMembershipStatusActive))
		statusPos := len(args)
		clauses = append(
			clauses,
			fmt.Sprintf(
				"(community_id IS NULL OR NOT EXISTS (SELECT 1 FROM community_memberships scm WHERE scm.community_id = posts.community_id AND scm.user_id = $%d AND scm.status = $%d))",
				userIDPos,
				statusPos,
			),
		)
	}

	var count int64
	query := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM posts
		WHERE %s
	`, strings.Join(clauses, " AND "))

	if err := r.pool.QueryRow(ctx, query, args...).Scan(&count); err != nil {
		return 0, fmt.Errorf("count posts: %w", err)
	}

	return int(count), nil
}

func (r *PGPostRepository) CountPublishedPostsByAuthorID(ctx context.Context, authorUserID uuid.UUID) (int, error) {
	var count int64
	args, clauses := appendPublicPostVisibilityClauses(
		[]any{authorUserID},
		[]string{"author_user_id = $1"},
	)

	query := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM posts
		WHERE %s
	`, strings.Join(clauses, " AND "))

	err := r.pool.QueryRow(ctx, query, args...).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("count published posts by author: %w", err)
	}

	return int(count), nil
}

func (r *PGPostRepository) CountPostsPublishedByAuthorSince(ctx context.Context, authorUserID uuid.UUID, since time.Time) (int, error) {
	var count int64
	err := r.pool.QueryRow(
		ctx,
		`
			SELECT COUNT(*)
			FROM posts
			WHERE author_user_id = $1
				AND published_at >= $2
		`,
		authorUserID,
		since.UTC(),
	).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("count recent published posts by author: %w", err)
	}
	return int(count), nil
}

func (r *PGPostRepository) OldestPostPublishedAtByAuthorSince(ctx context.Context, authorUserID uuid.UUID, since time.Time) (*time.Time, error) {
	var oldest sql.NullTime
	err := r.pool.QueryRow(
		ctx,
		`
			SELECT MIN(published_at)
			FROM posts
			WHERE author_user_id = $1
				AND published_at >= $2
		`,
		authorUserID,
		since.UTC(),
	).Scan(&oldest)
	if err != nil {
		return nil, fmt.Errorf("get oldest recent published post by author: %w", err)
	}
	if !oldest.Valid {
		return nil, nil
	}
	value := oldest.Time.UTC()
	return &value, nil
}

func (r *PGPostRepository) PostPublishCooldownUntil(
	ctx context.Context,
	authorUserID uuid.UUID,
) (*time.Time, error) {
	var nextAvailableAt time.Time
	err := r.pool.QueryRow(ctx, `
		SELECT next_available_at
		FROM post_publish_cooldowns
		WHERE author_user_id = $1
	`, authorUserID).Scan(&nextAvailableAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get post publish cooldown: %w", err)
	}
	next := nextAvailableAt.UTC()
	return &next, nil
}

func reservePostPublishCooldownTx(
	ctx context.Context,
	tx pgx.Tx,
	authorUserID uuid.UUID,
	postID uuid.UUID,
	cooldown time.Duration,
) error {
	if authorUserID == uuid.Nil || postID == uuid.Nil {
		return fmt.Errorf("post publish cooldown identifiers are required")
	}
	if cooldown <= 0 {
		cooldown = 5 * time.Minute
	}
	cooldownSeconds := int64((cooldown + time.Second - time.Nanosecond) / time.Second)

	insertTag, err := tx.Exec(ctx, `
		INSERT INTO post_publish_cooldowns (
			author_user_id,
			last_post_id,
			last_published_at,
			next_available_at,
			updated_at
		)
		VALUES (
			$1,
			$2,
			clock_timestamp(),
			clock_timestamp() + make_interval(secs => $3::double precision),
			clock_timestamp()
		)
		ON CONFLICT (author_user_id) DO NOTHING
	`, authorUserID, postID, cooldownSeconds)
	if err != nil {
		return fmt.Errorf("insert post publish cooldown: %w", err)
	}
	if insertTag.RowsAffected() == 1 {
		return nil
	}

	var nextAvailableAt time.Time
	err = tx.QueryRow(ctx, `
		UPDATE post_publish_cooldowns
		SET last_post_id = $2,
			last_published_at = clock_timestamp(),
			next_available_at = clock_timestamp() + make_interval(secs => $3::double precision),
			updated_at = clock_timestamp()
		WHERE author_user_id = $1
			AND next_available_at <= clock_timestamp()
		RETURNING next_available_at
	`, authorUserID, postID, cooldownSeconds).Scan(&nextAvailableAt)
	if err == nil {
		return nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return fmt.Errorf("refresh post publish cooldown: %w", err)
	}

	err = tx.QueryRow(ctx, `
		SELECT next_available_at
		FROM post_publish_cooldowns
		WHERE author_user_id = $1
	`, authorUserID).Scan(&nextAvailableAt)
	if err != nil {
		return fmt.Errorf("read active post publish cooldown: %w", err)
	}
	return &port.PostPublishCooldownError{NextAvailableAt: nextAvailableAt.UTC()}
}

func appendPublicPostVisibilityClauses(args []any, clauses []string) ([]any, []string) {
	args = append(args, string(enum.PostStatusPublished))
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
		"COALESCE(media_status, 'READY') = 'READY'",
		"(expires_at IS NULL OR expires_at > NOW())",
	)
	return args, clauses
}

func postListOrderBy(sort string) string {
	switch sort {
	case "latest_asc":
		return "COALESCE(published_at, created_at) ASC, id ASC"
	case "popular", "popular_desc":
		return "view_count DESC, published_at DESC NULLS LAST, created_at DESC"
	case "popular_asc":
		return "view_count ASC, published_at ASC NULLS LAST, created_at ASC"
	case "discussed", "discussed_desc":
		return "comment_count DESC, published_at DESC NULLS LAST, created_at DESC"
	case "discussed_asc":
		return "comment_count ASC, published_at ASC NULLS LAST, created_at ASC"
	case "latest", "latest_desc":
		return "COALESCE(published_at, created_at) DESC, id DESC"
	default:
		return "COALESCE(published_at, created_at) DESC, id DESC"
	}
}

func appendRelatedPostOrderBy(args []any, filter model.PostListFilter) ([]any, string) {
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
		return args, postListOrderBy("popular_desc")
	}

	return args, fmt.Sprintf(
		"(%s) DESC, view_count DESC, like_count DESC, comment_count DESC, published_at DESC NULLS LAST, created_at DESC",
		strings.Join(scoreParts, " + "),
	)
}

func (r *PGPostRepository) LikePost(ctx context.Context, postID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin like tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const insertQuery = `
		INSERT INTO post_likes (post_id, user_id, created_at)
		VALUES ($1, $2, NOW())
		ON CONFLICT (post_id, user_id) DO NOTHING
	`
	tag, err := tx.Exec(ctx, insertQuery, postID, userID)
	if err != nil {
		return false, 0, fmt.Errorf("insert post like: %w", err)
	}

	changed := tag.RowsAffected() > 0
	if changed {
		if _, err = tx.Exec(ctx, `UPDATE posts SET like_count = like_count + 1 WHERE id = $1`, postID); err != nil {
			return false, 0, fmt.Errorf("increment like count: %w", err)
		}
	}

	var likeCount int
	if err = tx.QueryRow(ctx, `SELECT like_count FROM posts WHERE id = $1`, postID).Scan(&likeCount); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, 0, ErrNotFound
		}
		return false, 0, fmt.Errorf("select post like count: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return false, 0, fmt.Errorf("commit like tx: %w", err)
	}

	return changed, likeCount, nil
}

func (r *PGPostRepository) UnlikePost(ctx context.Context, postID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin unlike tx: %w", err)
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(ctx, `DELETE FROM post_likes WHERE post_id = $1 AND user_id = $2`, postID, userID)
	if err != nil {
		return false, 0, fmt.Errorf("delete post like: %w", err)
	}

	changed := tag.RowsAffected() > 0
	if changed {
		if _, err = tx.Exec(ctx, `UPDATE posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = $1`, postID); err != nil {
			return false, 0, fmt.Errorf("decrement like count: %w", err)
		}
	}

	var likeCount int
	if err = tx.QueryRow(ctx, `SELECT like_count FROM posts WHERE id = $1`, postID).Scan(&likeCount); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, 0, ErrNotFound
		}
		return false, 0, fmt.Errorf("select post like count after unlike: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return false, 0, fmt.Errorf("commit unlike tx: %w", err)
	}

	return changed, likeCount, nil
}

func (r *PGPostRepository) HasPostLike(ctx context.Context, postID uuid.UUID, userID uuid.UUID) (bool, error) {
	var exists bool
	if err := r.pool.QueryRow(
		ctx,
		`SELECT EXISTS(SELECT 1 FROM post_likes WHERE post_id = $1 AND user_id = $2)`,
		postID,
		userID,
	).Scan(&exists); err != nil {
		return false, fmt.Errorf("check post like exists: %w", err)
	}

	return exists, nil
}

func (r *PGPostRepository) ListPostLikesByUser(ctx context.Context, postIDs []uuid.UUID, userID uuid.UUID) (map[uuid.UUID]bool, error) {
	if len(postIDs) == 0 || userID == uuid.Nil {
		return map[uuid.UUID]bool{}, nil
	}

	rows, err := r.pool.Query(
		ctx,
		`SELECT post_id FROM post_likes WHERE user_id = $1 AND post_id = ANY($2)`,
		userID,
		postIDs,
	)
	if err != nil {
		return nil, fmt.Errorf("list post likes by user: %w", err)
	}
	defer rows.Close()

	liked := make(map[uuid.UUID]bool, len(postIDs))
	for rows.Next() {
		var postID uuid.UUID
		if err = rows.Scan(&postID); err != nil {
			return nil, fmt.Errorf("scan post like: %w", err)
		}
		liked[postID] = true
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate post likes: %w", err)
	}

	return liked, nil
}

func (r *PGPostRepository) TrackPostView(ctx context.Context, postID uuid.UUID, viewerUserID uuid.UUID) (bool, int, error) {
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
			FROM posts s
			JOIN post_view_sketches v ON v.post_id = s.id
			WHERE s.id = $1 AND s.deleted_at IS NULL
			FOR UPDATE
		`,
		postID,
	).Scan(&currentCount, &registers); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, 0, ErrNotFound
		}
		return false, 0, fmt.Errorf("select post view sketch: %w", err)
	}

	hll, err := model.HyperLogLogFromBytes(registers)
	if err != nil {
		return false, 0, fmt.Errorf("decode post hll: %w", err)
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
		`UPDATE post_view_sketches SET registers = $2, updated_at = NOW() WHERE post_id = $1`,
		postID,
		hll.Bytes(),
	); err != nil {
		return false, 0, fmt.Errorf("update post view sketch: %w", err)
	}

	if _, err = tx.Exec(ctx, `UPDATE posts SET view_count = $2 WHERE id = $1`, postID, nextCount); err != nil {
		return false, 0, fmt.Errorf("update post view count: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return false, 0, fmt.Errorf("commit view tx: %w", err)
	}

	return true, nextCount, nil
}

func (r *PGPostRepository) MarkPostSeen(ctx context.Context, postID uuid.UUID, viewerUserID uuid.UUID, seenAt time.Time) (time.Time, error) {
	if seenAt.IsZero() {
		seenAt = time.Now().UTC().Truncate(time.Second)
	}
	seenAt = seenAt.UTC()

	var storedSeenAt time.Time
	if err := r.pool.QueryRow(
		ctx,
		`
			WITH inserted AS (
				INSERT INTO post_seen (post_id, viewer_user_id, seen_at)
				VALUES ($1, $2, $3)
				ON CONFLICT (post_id, viewer_user_id) DO NOTHING
				RETURNING seen_at
			)
			SELECT seen_at FROM inserted
			UNION ALL
			SELECT seen_at
			FROM post_seen
			WHERE post_id = $1 AND viewer_user_id = $2
			LIMIT 1
		`,
		postID,
		viewerUserID,
		seenAt,
	).Scan(&storedSeenAt); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return time.Time{}, ErrNotFound
		}
		return time.Time{}, fmt.Errorf("mark post seen: %w", err)
	}

	return storedSeenAt.UTC(), nil
}

func (r *PGPostRepository) ListPostSeenByUser(ctx context.Context, postIDs []uuid.UUID, userID uuid.UUID) (map[uuid.UUID]time.Time, error) {
	if len(postIDs) == 0 || userID == uuid.Nil {
		return map[uuid.UUID]time.Time{}, nil
	}

	rows, err := r.pool.Query(
		ctx,
		`SELECT post_id, seen_at FROM post_seen WHERE viewer_user_id = $1 AND post_id = ANY($2)`,
		userID,
		postIDs,
	)
	if err != nil {
		return nil, fmt.Errorf("list post seen by user: %w", err)
	}
	defer rows.Close()

	seen := make(map[uuid.UUID]time.Time, len(postIDs))
	for rows.Next() {
		var (
			postID uuid.UUID
			seenAt time.Time
		)
		if err = rows.Scan(&postID, &seenAt); err != nil {
			return nil, fmt.Errorf("scan post seen marker: %w", err)
		}
		seen[postID] = seenAt.UTC()
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate post seen markers: %w", err)
	}

	return seen, nil
}

func (r *PGPostRepository) IncrementShareCount(ctx context.Context, postID uuid.UUID) (int, error) {
	var count int
	if err := r.pool.QueryRow(
		ctx,
		`UPDATE posts SET share_count = share_count + 1 WHERE id = $1 AND deleted_at IS NULL RETURNING share_count`,
		postID,
	).Scan(&count); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, ErrNotFound
		}
		return 0, fmt.Errorf("increment share count: %w", err)
	}

	return count, nil
}

func (r *PGPostRepository) CreateComment(ctx context.Context, comment *model.PostComment, rateLimitAfter time.Time) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin comment tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if _, err = tx.Exec(
		ctx,
		`SELECT pg_advisory_xact_lock(hashtext($1::text), hashtext($2::text))`,
		comment.PostID,
		comment.AuthorUserID,
	); err != nil {
		return fmt.Errorf("lock comment author window: %w", err)
	}

	latestComment, err := getLatestActiveCommentByAuthor(ctx, tx, comment.PostID, comment.AuthorUserID)
	if err != nil {
		return err
	}
	if latestComment != nil && latestComment.CreatedAt.After(rateLimitAfter) {
		return port.ErrPostCommentRateLimited
	}

	const query = `
		INSERT INTO post_comments (id, post_id, author_user_id, body, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	if _, err = tx.Exec(
		ctx,
		query,
		comment.ID,
		comment.PostID,
		comment.AuthorUserID,
		comment.Body,
		comment.CreatedAt,
		comment.UpdatedAt,
	); err != nil {
		return fmt.Errorf("insert post comment: %w", err)
	}

	if _, err = tx.Exec(ctx, `UPDATE posts SET comment_count = comment_count + 1 WHERE id = $1`, comment.PostID); err != nil {
		return fmt.Errorf("increment post comment count: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit create comment tx: %w", err)
	}

	return nil
}

func (r *PGPostRepository) UpdateComment(ctx context.Context, comment *model.PostComment) error {
	const query = `
		UPDATE post_comments
		SET body = $3, updated_at = $4
		WHERE post_id = $1 AND id = $2 AND deleted_at IS NULL
	`

	tag, err := r.pool.Exec(ctx, query, comment.PostID, comment.ID, comment.Body, comment.UpdatedAt)
	if err != nil {
		return fmt.Errorf("update post comment: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}

func (r *PGPostRepository) GetLatestActiveCommentByAuthor(ctx context.Context, postID uuid.UUID, authorUserID uuid.UUID) (*model.PostComment, error) {
	return getLatestActiveCommentByAuthor(ctx, r.pool, postID, authorUserID)
}

type commentRowQuerier interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func getLatestActiveCommentByAuthor(ctx context.Context, querier commentRowQuerier, postID uuid.UUID, authorUserID uuid.UUID) (*model.PostComment, error) {
	const query = `
		SELECT id, post_id, author_user_id, body, like_count, created_at, updated_at, deleted_at
		FROM post_comments
		WHERE post_id = $1 AND author_user_id = $2 AND deleted_at IS NULL
		ORDER BY created_at DESC
		LIMIT 1
	`

	row := querier.QueryRow(ctx, query, postID, authorUserID)
	comment, err := scanComment(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select latest active comment by author: %w", err)
	}

	return comment, nil
}

func (r *PGPostRepository) GetCommentByID(ctx context.Context, postID uuid.UUID, commentID uuid.UUID) (*model.PostComment, error) {
	const query = `
		SELECT id, post_id, author_user_id, body, like_count, created_at, updated_at, deleted_at
		FROM post_comments
		WHERE post_id = $1 AND id = $2
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, postID, commentID)
	comment, err := scanComment(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select post comment by id: %w", err)
	}

	return comment, nil
}

func (r *PGPostRepository) ListComments(ctx context.Context, postID uuid.UUID, limit int, offset int) ([]*model.PostComment, error) {
	rows, err := r.pool.Query(
		ctx,
		`
			SELECT id, post_id, author_user_id, body, like_count, created_at, updated_at, deleted_at
			FROM post_comments
			WHERE post_id = $1 AND deleted_at IS NULL
			ORDER BY created_at DESC
			LIMIT $2 OFFSET $3
		`,
		postID,
		limit,
		offset,
	)
	if err != nil {
		return nil, fmt.Errorf("query post comments: %w", err)
	}
	defer rows.Close()

	items := make([]*model.PostComment, 0)
	for rows.Next() {
		item, scanErr := scanComment(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan post comment list: %w", scanErr)
		}
		items = append(items, item)
	}

	return items, rows.Err()
}

func (r *PGPostRepository) LikeComment(ctx context.Context, postID uuid.UUID, commentID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin comment like tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const insertQuery = `
		INSERT INTO post_comment_likes (comment_id, user_id, created_at)
		SELECT $2, $3, NOW()
		WHERE EXISTS (
			SELECT 1
			FROM post_comments
			WHERE post_id = $1 AND id = $2 AND deleted_at IS NULL
		)
		ON CONFLICT (comment_id, user_id) DO NOTHING
	`
	tag, err := tx.Exec(ctx, insertQuery, postID, commentID, userID)
	if err != nil {
		return false, 0, fmt.Errorf("insert comment like: %w", err)
	}

	changed := tag.RowsAffected() > 0
	if changed {
		if _, err = tx.Exec(ctx, `UPDATE post_comments SET like_count = like_count + 1 WHERE post_id = $1 AND id = $2 AND deleted_at IS NULL`, postID, commentID); err != nil {
			return false, 0, fmt.Errorf("increment comment like count: %w", err)
		}
	}

	var likeCount int
	if err = tx.QueryRow(ctx, `SELECT like_count FROM post_comments WHERE post_id = $1 AND id = $2 AND deleted_at IS NULL`, postID, commentID).Scan(&likeCount); err != nil {
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

func (r *PGPostRepository) UnlikeComment(ctx context.Context, postID uuid.UUID, commentID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin comment unlike tx: %w", err)
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(
		ctx,
		`
			DELETE FROM post_comment_likes
			WHERE comment_id = $2 AND user_id = $3
			  AND EXISTS (
				SELECT 1
				FROM post_comments
				WHERE post_id = $1 AND id = $2 AND deleted_at IS NULL
			  )
		`,
		postID,
		commentID,
		userID,
	)
	if err != nil {
		return false, 0, fmt.Errorf("delete comment like: %w", err)
	}

	changed := tag.RowsAffected() > 0
	if changed {
		if _, err = tx.Exec(ctx, `UPDATE post_comments SET like_count = GREATEST(like_count - 1, 0) WHERE post_id = $1 AND id = $2 AND deleted_at IS NULL`, postID, commentID); err != nil {
			return false, 0, fmt.Errorf("decrement comment like count: %w", err)
		}
	}

	var likeCount int
	if err = tx.QueryRow(ctx, `SELECT like_count FROM post_comments WHERE post_id = $1 AND id = $2 AND deleted_at IS NULL`, postID, commentID).Scan(&likeCount); err != nil {
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

func (r *PGPostRepository) HasCommentLike(ctx context.Context, commentID uuid.UUID, userID uuid.UUID) (bool, error) {
	var exists bool
	if err := r.pool.QueryRow(
		ctx,
		`SELECT EXISTS(SELECT 1 FROM post_comment_likes WHERE comment_id = $1 AND user_id = $2)`,
		commentID,
		userID,
	).Scan(&exists); err != nil {
		return false, fmt.Errorf("check comment like exists: %w", err)
	}

	return exists, nil
}

func (r *PGPostRepository) DeleteComment(ctx context.Context, postID uuid.UUID, commentID uuid.UUID) (bool, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, fmt.Errorf("begin delete comment tx: %w", err)
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(
		ctx,
		`UPDATE post_comments SET deleted_at = NOW(), updated_at = NOW() WHERE post_id = $1 AND id = $2 AND deleted_at IS NULL`,
		postID,
		commentID,
	)
	if err != nil {
		return false, fmt.Errorf("soft delete post comment: %w", err)
	}

	changed := tag.RowsAffected() > 0
	if changed {
		if _, err = tx.Exec(ctx, `UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = $1`, postID); err != nil {
			return false, fmt.Errorf("decrement post comment count: %w", err)
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return false, fmt.Errorf("commit delete comment tx: %w", err)
	}

	return changed, nil
}

func scanPost(scanner interface{ Scan(dest ...any) error }) (*model.Post, error) {
	var (
		item                  model.Post
		categoryRaw           string
		statusRaw             string
		communityID           *uuid.UUID
		communityInstanceID   *uuid.UUID
		postKindRaw           sql.NullString
		postProfileKeyRaw     sql.NullString
		postProfileVersionRaw sql.NullInt32
		structuredDataRaw     []byte
		moderationModeRaw     sql.NullString
		sourceActivityID      *uuid.UUID
		activityStatusRaw     sql.NullString
		activityErrorRaw      sql.NullString
		coverFileID           *uuid.UUID
		placeName             *string
		placeCountry          *string
		placeCityID           *string
		publishedAt           *time.Time
		deletedAt             *time.Time
		formatRaw             sql.NullString
		schemaVersionRaw      sql.NullInt32
		contentBlocksRaw      []byte
		contentPlainText      sql.NullString
		revisionRaw           sql.NullInt64
		lastAutosavedAt       *time.Time
		archivedAt            *time.Time
		moderationRaw         sql.NullString
		mediaStatusRaw        sql.NullString
		expiresAt             *time.Time
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
		&communityID,
		&communityInstanceID,
		&postKindRaw,
		&postProfileKeyRaw,
		&postProfileVersionRaw,
		&structuredDataRaw,
		&moderationModeRaw,
		&sourceActivityID,
		&activityStatusRaw,
		&activityErrorRaw,
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
		&expiresAt,
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
		&mediaStatusRaw,
	); err != nil {
		return nil, err
	}

	item.Category = enum.PostCategory(categoryRaw)
	item.Status = enum.PostStatus(statusRaw)
	item.Format = enum.NormalizePostFormat(enum.PostFormat(formatRaw.String))
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
	item.CommunityID = communityID
	item.CommunityInstanceID = communityInstanceID
	item.PostKind = enum.PostKind(strings.ToUpper(strings.TrimSpace(postKindRaw.String)))
	if !postKindRaw.Valid || !item.PostKind.IsValid() {
		return nil, fmt.Errorf("scan post: invalid post kind %q", postKindRaw.String)
	}
	postProfileKey := strings.TrimSpace(postProfileKeyRaw.String)
	if !postProfileKeyRaw.Valid || postProfileKey == "" {
		return nil, fmt.Errorf("scan post: invalid post profile key %q", postProfileKeyRaw.String)
	}
	item.PostProfileKey = enum.NormalizePostProfileKey(enum.PostProfileKey(postProfileKey))
	if !item.PostProfileKey.IsValid() {
		return nil, fmt.Errorf("scan post: invalid post profile key %q", postProfileKeyRaw.String)
	}
	item.PostProfileVersion = int(postProfileVersionRaw.Int32)
	if !postProfileVersionRaw.Valid || item.PostProfileVersion <= 0 {
		return nil, fmt.Errorf("scan post: invalid post profile version %d", item.PostProfileVersion)
	}
	if len(structuredDataRaw) > 0 {
		item.StructuredData = json.RawMessage(append([]byte(nil), structuredDataRaw...))
	}
	if len(item.StructuredData) == 0 {
		item.StructuredData = json.RawMessage(`{}`)
	}
	item.ModerationMode = enum.ModerationMode(strings.ToUpper(strings.TrimSpace(moderationModeRaw.String)))
	if !moderationModeRaw.Valid || !item.ModerationMode.IsValid() {
		return nil, fmt.Errorf("scan post: invalid moderation mode %q", moderationModeRaw.String)
	}
	item.SourceActivityID = sourceActivityID
	if activityStatusRaw.Valid && strings.TrimSpace(activityStatusRaw.String) != "" {
		status := enum.ActivityCreationStatus(strings.ToUpper(strings.TrimSpace(activityStatusRaw.String)))
		if status.IsValid() {
			item.ActivityCreationStatus = &status
		}
	}
	if activityErrorRaw.Valid && strings.TrimSpace(activityErrorRaw.String) != "" {
		value := strings.TrimSpace(activityErrorRaw.String)
		item.ActivityCreationError = &value
	}
	item.PlaceName = placeName
	item.PlaceCountryCode = placeCountry
	item.PlaceCityID = placeCityID
	item.PublishedAt = publishedAt
	item.ExpiresAt = expiresAt
	item.LastAutosavedAt = lastAutosavedAt
	item.ArchivedAt = archivedAt
	item.DeletedAt = deletedAt
	item.ModerationStatus = enum.NormalizeModerationStatus(enum.ModerationStatus(moderationRaw.String))
	item.MediaStatus = enum.NormalizePostMediaStatus(enum.PostMediaStatus(mediaStatusRaw.String))

	return &item, nil
}

const (
	postModerationOutboxEventPostReviewed     = "post_moderation.reviewed"
	postModerationOutboxEventReportCreated    = "post_report.created"
	postModerationOutboxEventReportAutoHidden = "post_report.auto_hidden"
	postModerationOutboxEventReportResolved   = "post_report.resolved"

	postModerationOutboxAggregatePost       = "POST"
	postModerationOutboxAggregatePostReport = "POST_REPORT"
)

type postModerationOutboxEvent struct {
	EventType     string
	AggregateType string
	AggregateID   uuid.UUID
	CommunityID   *uuid.UUID
	PostID        *uuid.UUID
	ActorUserID   uuid.UUID
	Payload       any
	CreatedAt     time.Time
}

func insertPostModerationOutboxTx(ctx context.Context, tx pgx.Tx, event postModerationOutboxEvent) error {
	if event.EventType == "" ||
		event.AggregateType == "" ||
		event.AggregateID == uuid.Nil ||
		event.ActorUserID == uuid.Nil {
		return fmt.Errorf("post moderation outbox event is invalid")
	}
	createdAt := event.CreatedAt
	if createdAt.IsZero() {
		createdAt = time.Now().UTC()
	}

	payload := []byte(`{}`)
	if event.Payload != nil {
		encoded, err := json.Marshal(event.Payload)
		if err != nil {
			return fmt.Errorf("marshal post moderation outbox payload: %w", err)
		}
		payload = encoded
	}

	const query = `
		INSERT INTO post_moderation_outbox (
			id, event_type, aggregate_type, aggregate_id, community_id, post_id,
			actor_user_id, payload, status, next_attempt_at, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, 'PENDING', $9, $9
		)
	`
	if _, err := tx.Exec(
		ctx,
		query,
		uuid.New(),
		event.EventType,
		event.AggregateType,
		event.AggregateID,
		event.CommunityID,
		event.PostID,
		event.ActorUserID,
		payload,
		createdAt,
	); err != nil {
		return fmt.Errorf("insert post moderation outbox event: %w", err)
	}

	return nil
}

func scanPostModerationOutboxEvent(scanner interface{ Scan(dest ...any) error }) (model.PostModerationOutboxEvent, error) {
	var (
		item      model.PostModerationOutboxEvent
		statusRaw string
	)
	if err := scanner.Scan(
		&item.ID,
		&item.EventType,
		&item.AggregateType,
		&item.AggregateID,
		&item.CommunityID,
		&item.PostID,
		&item.ActorUserID,
		&item.Payload,
		&statusRaw,
		&item.AttemptCount,
		&item.NextAttemptAt,
		&item.LastError,
		&item.CreatedAt,
		&item.DeliveredAt,
	); err != nil {
		return model.PostModerationOutboxEvent{}, err
	}
	item.Status = model.PostModerationOutboxStatus(statusRaw)
	return item, nil
}

func scanPostModerationDecision(scanner interface{ Scan(dest ...any) error }) (*model.PostModerationDecision, error) {
	var (
		item              model.PostModerationDecision
		decisionRaw       string
		previousStatusRaw string
		nextStatusRaw     string
	)
	if err := scanner.Scan(
		&item.ID,
		&item.PostID,
		&item.CommunityID,
		&item.ModeratorUserID,
		&decisionRaw,
		&previousStatusRaw,
		&nextStatusRaw,
		&item.PostRevision,
		&item.Reason,
		&item.CreatedAt,
	); err != nil {
		return nil, err
	}
	item.Decision = enum.NormalizePostModerationDecision(enum.PostModerationDecision(decisionRaw))
	item.PreviousStatus = enum.NormalizeModerationStatus(enum.ModerationStatus(previousStatusRaw))
	item.NextStatus = enum.NormalizeModerationStatus(enum.ModerationStatus(nextStatusRaw))
	return &item, nil
}

func scanPostReport(scanner interface{ Scan(dest ...any) error }) (*model.PostReport, error) {
	var (
		item      model.PostReport
		reasonRaw string
		statusRaw string
	)
	if err := scanner.Scan(
		&item.ID,
		&item.PostID,
		&item.CommunityID,
		&item.ReporterUserID,
		&item.AuthorUserID,
		&reasonRaw,
		&item.Details,
		&statusRaw,
		&item.ResolvedByUserID,
		&item.ResolutionNote,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.ResolvedAt,
	); err != nil {
		return nil, err
	}
	item.Reason = enum.NormalizePostReportReason(enum.PostReportReason(reasonRaw))
	item.Status = enum.NormalizePostReportStatus(enum.PostReportStatus(statusRaw))
	return &item, nil
}

func normalizePostContentEngineFields(post *model.Post) {
	if post == nil {
		return
	}

	post.Format = enum.NormalizePostFormat(post.Format)
	if post.ContentSchemaVersion <= 0 {
		post.ContentSchemaVersion = 1
	}
	if post.Revision <= 0 {
		post.Revision = 1
	}
	post.ModerationStatus = enum.NormalizeModerationStatus(post.ModerationStatus)
	post.MediaStatus = enum.NormalizePostMediaStatus(post.MediaStatus)
	postKind := strings.ToUpper(strings.TrimSpace(string(post.PostKind)))
	if postKind != "" {
		post.PostKind = enum.PostKind(postKind)
	}
	postProfileKey := strings.TrimSpace(string(post.PostProfileKey))
	if postProfileKey != "" {
		post.PostProfileKey = enum.NormalizePostProfileKey(enum.PostProfileKey(postProfileKey))
	}
	moderationMode := strings.ToUpper(strings.TrimSpace(string(post.ModerationMode)))
	if moderationMode != "" {
		post.ModerationMode = enum.ModerationMode(moderationMode)
	}
	if len(bytes.TrimSpace(post.StructuredData)) == 0 {
		post.StructuredData = json.RawMessage(`{}`)
	}
}

func activityCreationStatusString(status *enum.ActivityCreationStatus) *string {
	if status == nil {
		return nil
	}
	value := strings.ToUpper(strings.TrimSpace(string(*status)))
	if value == "" {
		return nil
	}
	return &value
}

func replacePostMediaTx(ctx context.Context, tx pgx.Tx, post *model.Post) error {
	if post == nil || post.Media == nil {
		return nil
	}

	if _, err := tx.Exec(ctx, `DELETE FROM post_media WHERE post_id = $1`, post.ID); err != nil {
		return fmt.Errorf("delete post media: %w", err)
	}
	if len(post.Media) == 0 {
		return nil
	}

	const query = `
		INSERT INTO post_media (
			post_id, file_id, media_type, position, is_primary, caption, alt_text,
			width, height, duration_ms, thumbnail_file_id, processing_status,
			created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7,
			$8, $9, $10, $11, $12,
			NOW(), NOW()
		)
	`
	for _, item := range post.Media {
		if item.PostID == uuid.Nil {
			item.PostID = post.ID
		}
		if !item.MediaType.IsValid() {
			return fmt.Errorf("post media type is invalid")
		}
		if !item.ProcessingStatus.IsValid() {
			return fmt.Errorf("post media processing status is invalid")
		}
		if _, err := tx.Exec(
			ctx,
			query,
			item.PostID,
			item.FileID,
			string(item.MediaType),
			item.Position,
			item.IsPrimary,
			item.Caption,
			item.AltText,
			item.Width,
			item.Height,
			item.DurationMS,
			item.ThumbnailFileID,
			string(item.ProcessingStatus),
		); err != nil {
			return fmt.Errorf("insert post media: %w", err)
		}
	}

	return nil
}

func validatePostUpdateRevision(post *model.Post) error {
	if post == nil || post.Revision <= 0 {
		return port.ErrPostRevisionConflict
	}
	return nil
}

func postUpdateRowsAffectedError(rowsAffected int64) error {
	if rowsAffected == 0 {
		return port.ErrPostRevisionConflict
	}
	return nil
}

func scanComment(scanner interface{ Scan(dest ...any) error }) (*model.PostComment, error) {
	var item model.PostComment
	if err := scanner.Scan(
		&item.ID,
		&item.PostID,
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
