package repository

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/port"
)

type dbRunner interface {
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

type PGStickerRepository struct {
	pool *pgxpool.Pool
	db   dbRunner
}

func NewPGStickerRepository(pool *pgxpool.Pool) *PGStickerRepository {
	return &PGStickerRepository{pool: pool, db: pool}
}

func (r *PGStickerRepository) WithTx(ctx context.Context, fn func(repo port.StickerRepository) error) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	txRepo := &PGStickerRepository{pool: r.pool, db: tx}
	if err = fn(txRepo); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}
	return nil
}

func (r *PGStickerRepository) ListDefaultPacks(ctx context.Context) ([]*model.StickerPackWithStickers, error) {
	const query = `
		SELECT id, slug, type, visibility, status, owner_user_id,
		       title, description, cover_sticker_id, sort_order,
		       created_by_user_id, created_at, updated_at
		FROM sticker_packs
		WHERE type = 'SYSTEM'
		  AND visibility = 'PUBLIC'
		  AND status = 'ACTIVE'
		ORDER BY sort_order ASC, created_at ASC
	`
	packs, err := r.listPacks(ctx, query)
	if err != nil {
		return nil, err
	}
	return r.attachStickers(ctx, packs)
}

func (r *PGStickerRepository) ListOfficialGroups(ctx context.Context) ([]*model.StickerGroup, error) {
	const query = `
		SELECT g.id, g.slug, g.title, g.display_order, g.status, g.created_at, g.updated_at
		FROM sticker_groups g
		WHERE g.status = 'ACTIVE'
		  AND EXISTS (
		    SELECT 1
		    FROM sticker_packs p
		    WHERE p.group_id = g.id
		      AND p.type = 'SYSTEM'
		      AND p.is_official = TRUE
		      AND p.visibility = 'PUBLIC'
		      AND p.status = 'ACTIVE'
		  )
		ORDER BY g.display_order ASC, g.created_at ASC
	`
	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("query official sticker groups: %w", err)
	}
	defer rows.Close()

	groups := make([]*model.StickerGroup, 0)
	for rows.Next() {
		group, err := scanGroup(rows)
		if err != nil {
			return nil, err
		}
		groups = append(groups, group)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate official sticker groups: %w", err)
	}
	return groups, nil
}

func (r *PGStickerRepository) ListActivePacksByGroup(
	ctx context.Context,
	groupID uuid.UUID,
) ([]*model.StickerPack, error) {
	const query = `
		SELECT id, group_id, slug, type, visibility, status, is_official, version,
		       owner_user_id, title, description, cover_sticker_id, thumbnail_file_id,
		       sort_order, published_at, created_by_user_id, created_at, updated_at
		FROM sticker_packs
		WHERE group_id = $1
		  AND type = 'SYSTEM'
		  AND is_official = TRUE
		  AND visibility = 'PUBLIC'
		  AND status = 'ACTIVE'
		ORDER BY sort_order ASC, created_at ASC
	`
	rows, err := r.db.Query(ctx, query, groupID)
	if err != nil {
		return nil, fmt.Errorf("query active sticker packs by group: %w", err)
	}
	defer rows.Close()

	packs := make([]*model.StickerPack, 0)
	for rows.Next() {
		pack, err := scanCatalogPack(rows)
		if err != nil {
			return nil, err
		}
		packs = append(packs, pack)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate active sticker packs by group: %w", err)
	}
	return packs, nil
}

func (r *PGStickerRepository) CatalogVersion(ctx context.Context) (port.CatalogVersion, error) {
	const query = `
		WITH catalog_updates AS (
		    SELECT updated_at FROM sticker_groups
		    UNION ALL
		    SELECT updated_at FROM sticker_packs
		    UNION ALL
		    SELECT updated_at FROM stickers
		)
		SELECT
		    COALESCE(EXTRACT(EPOCH FROM MAX(updated_at))::BIGINT, 0),
		    COALESCE(MAX(updated_at), to_timestamp(0))
		FROM catalog_updates
	`
	var version port.CatalogVersion
	if err := r.db.QueryRow(ctx, query).Scan(&version.Version, &version.UpdatedAt); err != nil {
		return port.CatalogVersion{}, fmt.Errorf("query sticker catalog version: %w", err)
	}
	return version, nil
}

func (r *PGStickerRepository) ListUserPacks(
	ctx context.Context,
	userID uuid.UUID,
) ([]*model.StickerPackWithStickers, error) {
	const query = `
		SELECT p.id, p.slug, p.type, p.visibility, p.status, p.owner_user_id,
		       p.title, p.description, p.cover_sticker_id, p.sort_order,
		       p.created_by_user_id, p.created_at, p.updated_at
		FROM sticker_packs p
		LEFT JOIN user_sticker_packs usp
		  ON usp.pack_id = p.id
		 AND usp.user_id = $1
		 AND usp.removed_at IS NULL
		WHERE p.status = 'ACTIVE'
		  AND (
		    p.owner_user_id = $1
		    OR usp.pack_id IS NOT NULL
		  )
		ORDER BY p.type DESC, p.sort_order ASC, p.created_at ASC
	`
	packs, err := r.listPacks(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	return r.attachStickers(ctx, packs)
}

func (r *PGStickerRepository) GetPackByID(ctx context.Context, packID uuid.UUID) (*model.StickerPack, error) {
	const query = `
		SELECT id, slug, type, visibility, status, owner_user_id,
		       title, description, cover_sticker_id, sort_order,
		       created_by_user_id, created_at, updated_at
		FROM sticker_packs
		WHERE id = $1
		LIMIT 1
	`
	return scanPack(r.db.QueryRow(ctx, query, packID))
}

func (r *PGStickerRepository) GetStickerByID(ctx context.Context, stickerID uuid.UUID) (*model.Sticker, error) {
	const query = `
		SELECT id, pack_id, slug, file_id, fallback_file_id, preview_file_id,
		       content_type, width, height, duration_ms, size_bytes, checksum,
		       emoji, keywords, status, sort_order,
		       created_by_user_id, created_at, updated_at
		FROM stickers
		WHERE id = $1
		LIMIT 1
	`
	return scanSticker(r.db.QueryRow(ctx, query, stickerID))
}

func (r *PGStickerRepository) GetStickerByPackAndFile(
	ctx context.Context,
	packID uuid.UUID,
	fileID uuid.UUID,
) (*model.Sticker, error) {
	const query = `
		SELECT id, pack_id, slug, file_id, fallback_file_id, preview_file_id,
		       content_type, width, height, duration_ms, size_bytes, checksum,
		       emoji, keywords, status, sort_order,
		       created_by_user_id, created_at, updated_at
		FROM stickers
		WHERE pack_id = $1
		  AND file_id = $2
		  AND status <> 'DELETED'
		LIMIT 1
	`
	return scanSticker(r.db.QueryRow(ctx, query, packID, fileID))
}

func (r *PGStickerRepository) EnsureCustomPack(ctx context.Context, userID uuid.UUID) (*model.StickerPack, error) {
	const selectQuery = `
		SELECT id, slug, type, visibility, status, owner_user_id,
		       title, description, cover_sticker_id, sort_order,
		       created_by_user_id, created_at, updated_at
		FROM sticker_packs
		WHERE type = 'USER_CUSTOM'
		  AND owner_user_id = $1
		  AND status <> 'DELETED'
		LIMIT 1
	`
	existing, err := scanPack(r.db.QueryRow(ctx, selectQuery, userID))
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return existing, nil
	}

	pack, err := model.NewStickerPack(model.NewStickerPackParams{
		Slug:            "custom-" + userID.String(),
		Type:            enum.PackTypeUserCustom,
		Visibility:      enum.PackVisibilityPrivate,
		Status:          enum.PackStatusActive,
		OwnerUserID:     &userID,
		Title:           map[string]string{"en": "My stickers", "ru": "Мои стикеры", "kk": "Менің стикерлерім"},
		CreatedByUserID: &userID,
	})
	if err != nil {
		return nil, err
	}

	const insertQuery = `
		INSERT INTO sticker_packs (
			id, slug, type, visibility, status, owner_user_id,
			title, description, cover_sticker_id, sort_order,
			created_by_user_id, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10,
			$11, $12, $13
		)
		ON CONFLICT (slug) DO NOTHING
	`
	if _, err = r.db.Exec(
		ctx,
		insertQuery,
		pack.ID,
		pack.Slug,
		string(pack.Type),
		string(pack.Visibility),
		string(pack.Status),
		pack.OwnerUserID,
		mustJSON(pack.Title),
		nullableJSON(pack.Description),
		pack.CoverStickerID,
		pack.SortOrder,
		pack.CreatedByUserID,
		pack.CreatedAt,
		pack.UpdatedAt,
	); err != nil {
		return nil, fmt.Errorf("insert custom sticker pack: %w", err)
	}

	return scanPack(r.db.QueryRow(ctx, selectQuery, userID))
}

func (r *PGStickerRepository) InstallPack(ctx context.Context, userID, packID uuid.UUID, source string) error {
	const query = `
		INSERT INTO user_sticker_packs (user_id, pack_id, source, installed_at, removed_at)
		VALUES ($1, $2, $3, NOW(), NULL)
		ON CONFLICT (user_id, pack_id)
		DO UPDATE SET source = EXCLUDED.source,
		              installed_at = COALESCE(user_sticker_packs.installed_at, NOW()),
		              removed_at = NULL
	`
	if _, err := r.db.Exec(ctx, query, userID, packID, source); err != nil {
		return fmt.Errorf("install sticker pack: %w", err)
	}
	return nil
}

func (r *PGStickerRepository) RemovePack(ctx context.Context, userID, packID uuid.UUID) error {
	const query = `
		UPDATE user_sticker_packs
		SET removed_at = NOW()
		WHERE user_id = $1
		  AND pack_id = $2
		  AND removed_at IS NULL
	`
	if _, err := r.db.Exec(ctx, query, userID, packID); err != nil {
		return fmt.Errorf("remove sticker pack: %w", err)
	}
	return nil
}

func (r *PGStickerRepository) CreateUploadSession(ctx context.Context, session *model.UploadSession) error {
	const query = `
		INSERT INTO sticker_upload_sessions (
			id, user_id, pack_id, file_id, status, idempotency_key, expires_at, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8
		)
	`
	if _, err := r.db.Exec(
		ctx,
		query,
		session.ID,
		session.UserID,
		session.PackID,
		session.FileID,
		string(session.Status),
		session.IdempotencyKey,
		session.ExpiresAt,
		session.CreatedAt,
	); err != nil {
		return fmt.Errorf("insert sticker upload session: %w", err)
	}
	return nil
}

func (r *PGStickerRepository) GetUploadSessionForUpdate(
	ctx context.Context,
	sessionID uuid.UUID,
) (*model.UploadSession, error) {
	const query = `
		SELECT id, user_id, pack_id, file_id, status, idempotency_key, expires_at, created_at
		FROM sticker_upload_sessions
		WHERE id = $1
		FOR UPDATE
	`
	return scanUploadSession(r.db.QueryRow(ctx, query, sessionID))
}

func (r *PGStickerRepository) CreateSticker(ctx context.Context, sticker *model.Sticker) error {
	const query = `
		INSERT INTO stickers (
			id, pack_id, file_id, emoji, keywords, status, sort_order,
			created_by_user_id, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7,
			$8, $9, $10
		)
	`
	if _, err := r.db.Exec(
		ctx,
		query,
		sticker.ID,
		sticker.PackID,
		sticker.FileID,
		sticker.Emoji,
		sticker.Keywords,
		string(sticker.Status),
		sticker.SortOrder,
		sticker.CreatedByUserID,
		sticker.CreatedAt,
		sticker.UpdatedAt,
	); err != nil {
		return fmt.Errorf("insert sticker: %w", err)
	}
	return nil
}

func (r *PGStickerRepository) UserHasPackAccess(ctx context.Context, userID, packID uuid.UUID) (bool, error) {
	const query = `
		SELECT EXISTS (
			SELECT 1
			FROM sticker_packs p
			LEFT JOIN user_sticker_packs usp
			  ON usp.pack_id = p.id
			 AND usp.user_id = $1
			 AND usp.removed_at IS NULL
			WHERE p.id = $2
			  AND p.status = 'ACTIVE'
			  AND (
			    (p.type = 'SYSTEM' AND p.visibility = 'PUBLIC')
			    OR p.owner_user_id = $1
			    OR usp.pack_id IS NOT NULL
			  )
		)
	`
	var allowed bool
	if err := r.db.QueryRow(ctx, query, userID, packID).Scan(&allowed); err != nil {
		return false, fmt.Errorf("check sticker pack access: %w", err)
	}
	return allowed, nil
}

func (r *PGStickerRepository) listPacks(
	ctx context.Context,
	query string,
	args ...any,
) ([]*model.StickerPack, error) {
	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query sticker packs: %w", err)
	}
	defer rows.Close()

	packs := make([]*model.StickerPack, 0)
	for rows.Next() {
		pack, err := scanPack(rows)
		if err != nil {
			return nil, err
		}
		packs = append(packs, pack)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate sticker packs: %w", err)
	}
	return packs, nil
}

func (r *PGStickerRepository) attachStickers(
	ctx context.Context,
	packs []*model.StickerPack,
) ([]*model.StickerPackWithStickers, error) {
	result := make([]*model.StickerPackWithStickers, 0, len(packs))
	for _, pack := range packs {
		stickers, err := r.listActiveStickersByPack(ctx, pack.ID)
		if err != nil {
			return nil, err
		}
		result = append(result, &model.StickerPackWithStickers{
			Pack:     pack,
			Stickers: stickers,
		})
	}
	return result, nil
}

func (r *PGStickerRepository) ListActiveStickersByPack(
	ctx context.Context,
	packID uuid.UUID,
	limit int,
	offset int,
) ([]*model.Sticker, error) {
	const query = `
		SELECT id, pack_id, slug, file_id, fallback_file_id, preview_file_id,
		       content_type, width, height, duration_ms, size_bytes, checksum,
		       emoji, keywords, status, sort_order,
		       created_by_user_id, created_at, updated_at
		FROM stickers
		WHERE pack_id = $1
		  AND status = 'ACTIVE'
		ORDER BY sort_order ASC, created_at ASC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.db.Query(ctx, query, packID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("query active stickers by pack: %w", err)
	}
	defer rows.Close()

	return scanStickers(rows, "iterate active stickers by pack")
}

func (r *PGStickerRepository) SearchOfficialStickers(
	ctx context.Context,
	queryText string,
	limit int,
	offset int,
) ([]*model.Sticker, error) {
	const query = `
		SELECT s.id, s.pack_id, s.slug, s.file_id, s.fallback_file_id, s.preview_file_id,
		       s.content_type, s.width, s.height, s.duration_ms, s.size_bytes, s.checksum,
		       s.emoji, s.keywords, s.status, s.sort_order,
		       s.created_by_user_id, s.created_at, s.updated_at
		FROM stickers s
		JOIN sticker_packs p ON p.id = s.pack_id
		WHERE s.status = 'ACTIVE'
		  AND p.type = 'SYSTEM'
		  AND p.is_official = TRUE
		  AND p.visibility = 'PUBLIC'
		  AND p.status = 'ACTIVE'
		  AND (
		    s.slug ILIKE '%' || $1 || '%'
		    OR COALESCE(s.emoji, '') ILIKE '%' || $1 || '%'
		    OR EXISTS (
		      SELECT 1
		      FROM unnest(s.keywords) keyword
		      WHERE keyword ILIKE '%' || $1 || '%'
		    )
		  )
		ORDER BY p.sort_order ASC, s.sort_order ASC, s.created_at ASC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.db.Query(ctx, query, queryText, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("search official stickers: %w", err)
	}
	defer rows.Close()

	return scanStickers(rows, "iterate official sticker search results")
}

func (r *PGStickerRepository) RecordStickerUsage(
	ctx context.Context,
	userID uuid.UUID,
	stickerID uuid.UUID,
) error {
	const query = `
		INSERT INTO sticker_recent_usage (
			user_id, sticker_id, use_count, last_used_at, created_at, updated_at
		)
		VALUES ($1, $2, 1, NOW(), NOW(), NOW())
		ON CONFLICT (user_id, sticker_id)
		DO UPDATE SET
			use_count = sticker_recent_usage.use_count + 1,
			last_used_at = NOW(),
			updated_at = NOW()
	`
	if _, err := r.db.Exec(ctx, query, userID, stickerID); err != nil {
		return fmt.Errorf("record sticker usage: %w", err)
	}
	return nil
}

func (r *PGStickerRepository) ListRecentStickers(
	ctx context.Context,
	userID uuid.UUID,
	limit int,
) ([]*model.Sticker, error) {
	const query = `
		SELECT s.id, s.pack_id, s.slug, s.file_id, s.fallback_file_id, s.preview_file_id,
		       s.content_type, s.width, s.height, s.duration_ms, s.size_bytes, s.checksum,
		       s.emoji, s.keywords, s.status, s.sort_order,
		       s.created_by_user_id, s.created_at, s.updated_at
		FROM sticker_recent_usage ru
		JOIN stickers s ON s.id = ru.sticker_id
		JOIN sticker_packs p ON p.id = s.pack_id
		LEFT JOIN user_sticker_packs usp
		  ON usp.pack_id = p.id
		 AND usp.user_id = $1
		 AND usp.removed_at IS NULL
		WHERE ru.user_id = $1
		  AND s.status = 'ACTIVE'
		  AND p.status = 'ACTIVE'
		  AND (
		    (p.type = 'SYSTEM' AND p.visibility = 'PUBLIC')
		    OR p.owner_user_id = $1
		    OR usp.pack_id IS NOT NULL
		  )
		ORDER BY ru.last_used_at DESC
		LIMIT $2
	`
	rows, err := r.db.Query(ctx, query, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("query recent stickers: %w", err)
	}
	defer rows.Close()

	return scanStickers(rows, "iterate recent stickers")
}

func (r *PGStickerRepository) listActiveStickersByPack(
	ctx context.Context,
	packID uuid.UUID,
) ([]*model.Sticker, error) {
	const query = `
		SELECT id, pack_id, slug, file_id, fallback_file_id, preview_file_id,
		       content_type, width, height, duration_ms, size_bytes, checksum,
		       emoji, keywords, status, sort_order,
		       created_by_user_id, created_at, updated_at
		FROM stickers
		WHERE pack_id = $1
		  AND status = 'ACTIVE'
		ORDER BY sort_order ASC, created_at ASC
	`
	rows, err := r.db.Query(ctx, query, packID)
	if err != nil {
		return nil, fmt.Errorf("query stickers by pack: %w", err)
	}
	defer rows.Close()

	return scanStickers(rows, "iterate stickers by pack")
}

func scanPack(row pgx.Row) (*model.StickerPack, error) {
	var (
		pack           model.StickerPack
		typeRaw        string
		visibilityRaw  string
		statusRaw      string
		titleRaw       []byte
		descriptionRaw []byte
	)
	err := row.Scan(
		&pack.ID,
		&pack.Slug,
		&typeRaw,
		&visibilityRaw,
		&statusRaw,
		&pack.OwnerUserID,
		&titleRaw,
		&descriptionRaw,
		&pack.CoverStickerID,
		&pack.SortOrder,
		&pack.CreatedByUserID,
		&pack.CreatedAt,
		&pack.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("scan sticker pack: %w", err)
	}

	pack.Type = enum.PackType(typeRaw)
	pack.Visibility = enum.PackVisibility(visibilityRaw)
	pack.Status = enum.PackStatus(statusRaw)
	pack.Title = decodeLocalizedText(titleRaw)
	pack.Description = decodeLocalizedText(descriptionRaw)
	return &pack, nil
}

func scanCatalogPack(row pgx.Row) (*model.StickerPack, error) {
	var (
		pack           model.StickerPack
		typeRaw        string
		visibilityRaw  string
		statusRaw      string
		titleRaw       []byte
		descriptionRaw []byte
	)
	err := row.Scan(
		&pack.ID,
		&pack.GroupID,
		&pack.Slug,
		&typeRaw,
		&visibilityRaw,
		&statusRaw,
		&pack.IsOfficial,
		&pack.Version,
		&pack.OwnerUserID,
		&titleRaw,
		&descriptionRaw,
		&pack.CoverStickerID,
		&pack.ThumbnailFileID,
		&pack.SortOrder,
		&pack.PublishedAt,
		&pack.CreatedByUserID,
		&pack.CreatedAt,
		&pack.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("scan catalog sticker pack: %w", err)
	}

	pack.Type = enum.PackType(typeRaw)
	pack.Visibility = enum.PackVisibility(visibilityRaw)
	pack.Status = enum.PackStatus(statusRaw)
	pack.Title = decodeLocalizedText(titleRaw)
	pack.Description = decodeLocalizedText(descriptionRaw)
	return &pack, nil
}

func scanGroup(row pgx.Row) (*model.StickerGroup, error) {
	var (
		group     model.StickerGroup
		statusRaw string
		titleRaw  []byte
	)
	err := row.Scan(
		&group.ID,
		&group.Slug,
		&titleRaw,
		&group.DisplayOrder,
		&statusRaw,
		&group.CreatedAt,
		&group.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("scan sticker group: %w", err)
	}
	group.Status = enum.PackStatus(statusRaw)
	group.Title = decodeLocalizedText(titleRaw)
	return &group, nil
}

func scanSticker(row pgx.Row) (*model.Sticker, error) {
	var (
		sticker     model.Sticker
		statusRaw   string
		slug        pgtype.Text
		contentType pgtype.Text
		width       pgtype.Int4
		height      pgtype.Int4
		durationMS  pgtype.Int4
		sizeBytes   pgtype.Int8
		checksum    pgtype.Text
	)
	err := row.Scan(
		&sticker.ID,
		&sticker.PackID,
		&slug,
		&sticker.FileID,
		&sticker.FallbackFileID,
		&sticker.PreviewFileID,
		&contentType,
		&width,
		&height,
		&durationMS,
		&sizeBytes,
		&checksum,
		&sticker.Emoji,
		&sticker.Keywords,
		&statusRaw,
		&sticker.SortOrder,
		&sticker.CreatedByUserID,
		&sticker.CreatedAt,
		&sticker.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("scan sticker: %w", err)
	}
	if slug.Valid {
		sticker.Slug = slug.String
	}
	if contentType.Valid {
		sticker.ContentType = contentType.String
	}
	if width.Valid {
		sticker.Width = int(width.Int32)
	}
	if height.Valid {
		sticker.Height = int(height.Int32)
	}
	if durationMS.Valid {
		sticker.DurationMS = int(durationMS.Int32)
	}
	if sizeBytes.Valid {
		sticker.SizeBytes = sizeBytes.Int64
	}
	if checksum.Valid {
		sticker.Checksum = checksum.String
	}
	sticker.Status = enum.StickerStatus(statusRaw)
	return &sticker, nil
}

func scanStickers(rows pgx.Rows, iterateContext string) ([]*model.Sticker, error) {
	stickers := make([]*model.Sticker, 0)
	for rows.Next() {
		sticker, err := scanSticker(rows)
		if err != nil {
			return nil, err
		}
		stickers = append(stickers, sticker)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("%s: %w", iterateContext, err)
	}
	return stickers, nil
}

func scanUploadSession(row pgx.Row) (*model.UploadSession, error) {
	var (
		session   model.UploadSession
		statusRaw string
	)
	err := row.Scan(
		&session.ID,
		&session.UserID,
		&session.PackID,
		&session.FileID,
		&statusRaw,
		&session.IdempotencyKey,
		&session.ExpiresAt,
		&session.CreatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("scan sticker upload session: %w", err)
	}
	session.Status = enum.UploadSessionStatus(statusRaw)
	return &session, nil
}

func mustJSON(values map[string]string) []byte {
	payload, err := json.Marshal(values)
	if err != nil {
		return []byte("{}")
	}
	return payload
}

func nullableJSON(values map[string]string) any {
	if len(values) == 0 {
		return nil
	}
	return mustJSON(values)
}

func decodeLocalizedText(payload []byte) map[string]string {
	if len(payload) == 0 {
		return nil
	}
	var result map[string]string
	if err := json.Unmarshal(payload, &result); err != nil {
		return nil
	}
	return result
}
