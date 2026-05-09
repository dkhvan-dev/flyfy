package repository

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
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
		SELECT id, pack_id, file_id, emoji, keywords, status, sort_order,
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
		SELECT id, pack_id, file_id, emoji, keywords, status, sort_order,
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

func (r *PGStickerRepository) listActiveStickersByPack(
	ctx context.Context,
	packID uuid.UUID,
) ([]*model.Sticker, error) {
	const query = `
		SELECT id, pack_id, file_id, emoji, keywords, status, sort_order,
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

	stickers := make([]*model.Sticker, 0)
	for rows.Next() {
		sticker, err := scanSticker(rows)
		if err != nil {
			return nil, err
		}
		stickers = append(stickers, sticker)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate stickers by pack: %w", err)
	}
	return stickers, nil
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

func scanSticker(row pgx.Row) (*model.Sticker, error) {
	var (
		sticker   model.Sticker
		statusRaw string
	)
	err := row.Scan(
		&sticker.ID,
		&sticker.PackID,
		&sticker.FileID,
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
	sticker.Status = enum.StickerStatus(statusRaw)
	return &sticker, nil
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
