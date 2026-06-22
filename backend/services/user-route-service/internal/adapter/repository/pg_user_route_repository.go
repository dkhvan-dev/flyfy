package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/user-route-service/internal/app"
	"kz/inflap/backend/services/user-route-service/internal/domain/model"
)

type PGUserRouteRepository struct {
	pool *pgxpool.Pool
}

func NewPGUserRouteRepository(pool *pgxpool.Pool) *PGUserRouteRepository {
	return &PGUserRouteRepository{pool: pool}
}

func (r *PGUserRouteRepository) SaveRoute(ctx context.Context, route model.UserRoute) error {
	return r.saveRoute(ctx, r.pool, route)
}

func (r *PGUserRouteRepository) CreateRouteCopy(
	ctx context.Context,
	sourceRouteID string,
	copyRoute model.UserRoute,
	copiedAt time.Time,
) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	if err := r.saveRoute(ctx, tx, copyRoute); err != nil {
		return err
	}
	tag, err := tx.Exec(ctx, `
		UPDATE user_routes
		SET copies_count = copies_count + 1,
		    updated_at = $2
		WHERE id = $1
	`, strings.TrimSpace(sourceRouteID), copiedAt.UTC())
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return tx.Commit(ctx)
}

type routeExecutor interface {
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
}

func (r *PGUserRouteRepository) saveRoute(ctx context.Context, exec routeExecutor, route model.UserRoute) error {
	route.Normalize()
	points, err := json.Marshal(route.Points)
	if err != nil {
		return fmt.Errorf("marshal route points: %w", err)
	}
	snapshot, err := json.Marshal(route.Snapshot)
	if err != nil {
		return fmt.Errorf("marshal route snapshot: %w", err)
	}
	_, err = exec.Exec(ctx, `
		INSERT INTO user_routes (
			id, owner_user_id, source_route_id, title, description, visibility,
			moderation_status, moderation_reason, moderated_by_user_id, moderated_at,
			profile, city_code, tags, points, snapshot, copies_count, views_count,
			created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14::jsonb, $15::jsonb, $16, $17, $18, $19)
		ON CONFLICT (id) DO UPDATE SET
			owner_user_id = EXCLUDED.owner_user_id,
			source_route_id = EXCLUDED.source_route_id,
			title = EXCLUDED.title,
			description = EXCLUDED.description,
			visibility = EXCLUDED.visibility,
			moderation_status = EXCLUDED.moderation_status,
			moderation_reason = EXCLUDED.moderation_reason,
			moderated_by_user_id = EXCLUDED.moderated_by_user_id,
			moderated_at = EXCLUDED.moderated_at,
			profile = EXCLUDED.profile,
			city_code = EXCLUDED.city_code,
			tags = EXCLUDED.tags,
			points = EXCLUDED.points,
			snapshot = EXCLUDED.snapshot,
			copies_count = EXCLUDED.copies_count,
			views_count = EXCLUDED.views_count,
			updated_at = EXCLUDED.updated_at
	`, route.ID, route.OwnerUserID, nullableString(route.SourceRouteID), route.Title, route.Description,
		string(route.Visibility), string(route.ModerationStatus), route.ModerationReason,
		nullableString(route.ModeratedByUserID), nullableTime(route.ModeratedAt),
		string(route.Profile), route.CityCode, route.Tags, string(points), string(snapshot),
		route.Stats.CopiesCount, route.Stats.ViewsCount, route.CreatedAt.UTC(), route.UpdatedAt.UTC())
	return err
}

func (r *PGUserRouteRepository) FindRouteByID(ctx context.Context, routeID string) (model.UserRoute, bool, error) {
	row := r.pool.QueryRow(ctx, routeSelectSQL()+` WHERE r.id = $1`, strings.TrimSpace(routeID))
	route, err := scanRoute(row)
	if err != nil {
		if err == pgx.ErrNoRows {
			return model.UserRoute{}, false, nil
		}
		return model.UserRoute{}, false, err
	}
	return route, true, nil
}

func (r *PGUserRouteRepository) ListRoutes(ctx context.Context, filter app.RouteListFilter) ([]model.UserRoute, error) {
	rows, err := r.pool.Query(ctx, routeSelectSQL()+listRoutesSQL(),
		strings.TrimSpace(filter.OwnerUserID), filter.PublicOnly, strings.ToLower(strings.TrimSpace(filter.CityCode)),
		strings.TrimSpace(filter.SavedByUserID), strings.TrimSpace(string(filter.ModerationStatus)),
		normalizeLimit(filter.Limit), normalizeOffset(filter.Offset))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	routes := make([]model.UserRoute, 0)
	for rows.Next() {
		route, err := scanRoute(rows)
		if err != nil {
			return nil, err
		}
		routes = append(routes, route)
	}
	return routes, rows.Err()
}

func listRoutesSQL() string {
	return `
		WHERE ($1 = '' OR r.owner_user_id = $1)
		  AND (NOT $2 OR (r.visibility = 'public' AND r.moderation_status = 'approved'))
		  AND ($3 = '' OR r.city_code = $3)
		  AND ($4 = '' OR EXISTS (
			SELECT 1 FROM user_route_saves s WHERE s.route_id = r.id AND s.user_id = $4
		  ))
		  AND ($5::text = '' OR r.moderation_status = $5)
		ORDER BY r.updated_at DESC, r.id ASC
		LIMIT $6 OFFSET $7
	`
}

func (r *PGUserRouteRepository) SaveRouteBookmark(ctx context.Context, userID string, routeID string, createdAt time.Time) error {
	_, err := r.pool.Exec(ctx, `
		INSERT INTO user_route_saves (user_id, route_id, created_at)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, route_id) DO NOTHING
	`, strings.TrimSpace(userID), strings.TrimSpace(routeID), createdAt.UTC())
	return err
}

func (r *PGUserRouteRepository) DeleteRouteBookmark(ctx context.Context, userID string, routeID string) error {
	_, err := r.pool.Exec(ctx, `
		DELETE FROM user_route_saves WHERE user_id = $1 AND route_id = $2
	`, strings.TrimSpace(userID), strings.TrimSpace(routeID))
	return err
}

func (r *PGUserRouteRepository) HasRouteBookmark(ctx context.Context, userID string, routeID string) (bool, error) {
	var exists bool
	err := r.pool.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM user_route_saves WHERE user_id = $1 AND route_id = $2
		)
	`, strings.TrimSpace(userID), strings.TrimSpace(routeID)).Scan(&exists)
	return exists, err
}

func (r *PGUserRouteRepository) CountRouteBookmarks(ctx context.Context, routeID string) (int, error) {
	var count int
	err := r.pool.QueryRow(ctx, `
		SELECT count(*)::int FROM user_route_saves WHERE route_id = $1
	`, strings.TrimSpace(routeID)).Scan(&count)
	return count, err
}

type rowScanner interface {
	Scan(dest ...any) error
}

func routeSelectSQL() string {
	return `
		SELECT r.id, r.owner_user_id, r.source_route_id, r.title, r.description,
		       r.visibility, r.moderation_status, r.moderation_reason, r.moderated_by_user_id, r.moderated_at,
		       r.profile, r.city_code, r.tags, r.points, r.snapshot,
		       COALESCE(saves.saves_count, 0)::int, r.copies_count, r.views_count,
		       r.created_at, r.updated_at
		FROM user_routes r
		LEFT JOIN (
			SELECT route_id, count(*) AS saves_count
			FROM user_route_saves
			GROUP BY route_id
		) saves ON saves.route_id = r.id`
}

func scanRoute(scanner rowScanner) (model.UserRoute, error) {
	var route model.UserRoute
	var sourceRouteID sql.NullString
	var visibility string
	var moderationStatus string
	var moderationReason string
	var moderatedByUserID sql.NullString
	var moderatedAt sql.NullTime
	var profile string
	var pointsRaw []byte
	var snapshotRaw []byte
	if err := scanner.Scan(
		&route.ID,
		&route.OwnerUserID,
		&sourceRouteID,
		&route.Title,
		&route.Description,
		&visibility,
		&moderationStatus,
		&moderationReason,
		&moderatedByUserID,
		&moderatedAt,
		&profile,
		&route.CityCode,
		&route.Tags,
		&pointsRaw,
		&snapshotRaw,
		&route.Stats.SavesCount,
		&route.Stats.CopiesCount,
		&route.Stats.ViewsCount,
		&route.CreatedAt,
		&route.UpdatedAt,
	); err != nil {
		return model.UserRoute{}, err
	}
	if sourceRouteID.Valid {
		route.SourceRouteID = &sourceRouteID.String
	}
	route.Visibility = model.RouteVisibility(visibility)
	route.ModerationStatus = model.RouteModerationStatus(moderationStatus)
	route.ModerationReason = moderationReason
	if moderatedByUserID.Valid {
		route.ModeratedByUserID = &moderatedByUserID.String
	}
	if moderatedAt.Valid {
		route.ModeratedAt = &moderatedAt.Time
	}
	route.Profile = model.RouteProfile(profile)
	if err := json.Unmarshal(pointsRaw, &route.Points); err != nil {
		return model.UserRoute{}, fmt.Errorf("unmarshal route points: %w", err)
	}
	if err := json.Unmarshal(snapshotRaw, &route.Snapshot); err != nil {
		return model.UserRoute{}, fmt.Errorf("unmarshal route snapshot: %w", err)
	}
	route.Normalize()
	return route, nil
}

func nullableString(value *string) any {
	if value == nil || strings.TrimSpace(*value) == "" {
		return nil
	}
	return strings.TrimSpace(*value)
}

func nullableTime(value *time.Time) any {
	if value == nil || value.IsZero() {
		return nil
	}
	return value.UTC()
}

func normalizeLimit(limit int) int {
	if limit <= 0 {
		return 20
	}
	if limit > 50 {
		return 50
	}
	return limit
}

func normalizeOffset(offset int) int {
	if offset < 0 {
		return 0
	}
	return offset
}
