package repository

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strings"
	"sync"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/switches-service/internal/featureflag/app"
)

type dbRunner interface {
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

type PGRepository struct {
	pool  *pgxpool.Pool
	db    dbRunner
	locks sync.Map
}

const cacheInvalidationChannel = "switches_cache_invalidate"

func NewPGRepository(pool *pgxpool.Pool) *PGRepository {
	return &PGRepository{pool: pool, db: pool}
}

func (r *PGRepository) TryAdvisoryLock(ctx context.Context, key int64) (bool, error) {
	if _, loaded := r.locks.LoadOrStore(key, struct{}{}); loaded {
		return false, nil
	}
	conn, err := r.pool.Acquire(ctx)
	if err != nil {
		r.locks.Delete(key)
		return false, err
	}
	var locked bool
	if err = conn.QueryRow(ctx, "SELECT pg_try_advisory_lock($1)", key).Scan(&locked); err != nil {
		conn.Release()
		r.locks.Delete(key)
		return false, err
	}
	if !locked {
		conn.Release()
		r.locks.Delete(key)
		return false, nil
	}
	r.locks.Store(key, conn)
	return true, nil
}

func (r *PGRepository) UnlockAdvisory(ctx context.Context, key int64) error {
	value, ok := r.locks.LoadAndDelete(key)
	if !ok || value == nil {
		return nil
	}
	conn, ok := value.(*pgxpool.Conn)
	if !ok {
		return nil
	}
	defer conn.Release()
	unlockCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, err := conn.Exec(unlockCtx, "SELECT pg_advisory_unlock($1)", key)
	return err
}

func (r *PGRepository) withTx(ctx context.Context, fn func(repo *PGRepository) error) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	txRepo := &PGRepository{pool: r.pool, db: tx}
	if err = fn(txRepo); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}
	return nil
}

func (r *PGRepository) Create(ctx context.Context, request app.FeatureFlagCreateRequest, actor string) (app.FeatureFlagDetailResponse, error) {
	table := featureFlagTable(request.DomainCode)
	query := fmt.Sprintf(`
		INSERT INTO %s
		    (code, created_by, name, "group", "type", enabled, action_start_date, action_end_date, value)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING code, created_at, created_by, updated_at, updated_by, name, "group", "type",
		          enabled, action_start_date, action_end_date, value, is_deleted
	`, table)
	result, err := scanFeatureFlag(r.db.QueryRow(ctx, query,
		request.Code,
		actor,
		request.Name,
		request.Group,
		string(request.Type),
		request.Enabled,
		app.TruncateToMinute(request.ActionStartDate),
		app.TruncatePtrToMinute(request.ActionEndDate),
		app.FeatureFlagValueToStrings(request.Value),
	))
	if err != nil {
		return app.FeatureFlagDetailResponse{}, err
	}
	_ = r.notifyCacheInvalidation(ctx)
	return result, nil
}

func (r *PGRepository) Update(ctx context.Context, code string, request app.FeatureFlagUpdateRequest, actor string) (*app.FeatureFlagDetailResponse, error) {
	table := featureFlagTable(request.DomainCode)
	query := fmt.Sprintf(`
		UPDATE %s
		SET updated_at = now(),
		    updated_by = $2,
		    name = $3,
		    "group" = $4,
		    "type" = $5,
		    enabled = $6,
		    action_start_date = $7,
		    action_end_date = $8,
		    value = $9::text[]
		WHERE code = $1
		  AND (
		    name IS DISTINCT FROM $3 OR
		    "group" IS DISTINCT FROM $4 OR
		    "type" IS DISTINCT FROM $5 OR
		    enabled IS DISTINCT FROM $6 OR
		    action_start_date IS DISTINCT FROM $7 OR
		    action_end_date IS DISTINCT FROM $8 OR
		    value IS DISTINCT FROM $9::text[]
		  )
		RETURNING code, created_at, created_by, updated_at, updated_by, name, "group", "type",
		          enabled, action_start_date, action_end_date, value, is_deleted
	`, table)
	result, err := scanFeatureFlag(r.db.QueryRow(ctx, query,
		code,
		actor,
		request.Name,
		request.Group,
		string(request.Type),
		request.Enabled,
		app.TruncateToMinute(request.ActionStartDate),
		app.TruncatePtrToMinute(request.ActionEndDate),
		app.FeatureFlagValueToStrings(request.Value),
	))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	_ = r.notifyCacheInvalidation(ctx)
	return &result, nil
}

func (r *PGRepository) GetByCode(ctx context.Context, code string, domainCode string) (*app.FeatureFlagDetailResponse, error) {
	table := featureFlagTable(domainCode)
	query := fmt.Sprintf(`
		SELECT code, created_at, created_by, updated_at, updated_by, name, "group", "type",
		       enabled, action_start_date, action_end_date, value, is_deleted
		FROM %s
		WHERE code = $1
		LIMIT 1
	`, table)
	result, err := scanFeatureFlag(r.db.QueryRow(ctx, query, code))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &result, nil
}

func (r *PGRepository) FindAll(ctx context.Context, request app.FeatureFlagSearchRequest) (app.Page[app.FeatureFlagDetailResponse], error) {
	table := featureFlagTable(request.DomainCode)
	where := featureFlagFilters(request)
	args := append([]any{}, where.args...)
	orderBy := safeOrderBy(request.OrderBy, featureFlagOrderColumns, "created_at")
	direction := safeDirection(request.Direction)
	limit := request.Size
	offset := request.Page * request.Size
	args = append(args, limit, offset)
	query := fmt.Sprintf(`
		SELECT code, created_at, created_by, updated_at, updated_by, name, "group", "type",
		       enabled, action_start_date, action_end_date, value, is_deleted
		FROM %s
		%s
		ORDER BY %s %s
		LIMIT $%d OFFSET $%d
	`, table, where.sql, orderBy, direction, len(args)-1, len(args))
	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return app.Page[app.FeatureFlagDetailResponse]{}, fmt.Errorf("query feature flags: %w", err)
	}
	defer rows.Close()
	items := make([]app.FeatureFlagDetailResponse, 0)
	for rows.Next() {
		item, scanErr := scanFeatureFlag(rows)
		if scanErr != nil {
			return app.Page[app.FeatureFlagDetailResponse]{}, scanErr
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return app.Page[app.FeatureFlagDetailResponse]{}, err
	}
	total, err := r.count(ctx, fmt.Sprintf("SELECT count(code) FROM %s %s", table, where.sql), where.args...)
	if err != nil {
		return app.Page[app.FeatureFlagDetailResponse]{}, err
	}
	return pageOf(items, request.Page, request.Size, total), nil
}

func (r *PGRepository) Delete(ctx context.Context, code string, domainCode string, actor string) (bool, error) {
	deleted := false
	err := r.withTx(ctx, func(repo *PGRepository) error {
		table := featureFlagTable(domainCode)
		query := fmt.Sprintf(`
			UPDATE %s
			SET is_deleted = true,
			    enabled = false,
			    value = CASE WHEN "type" = 'TOGGLE' THEN '{false}' ELSE value END
			WHERE code = $1
		`, table)
		tag, err := repo.db.Exec(ctx, query, code)
		if err != nil {
			return err
		}
		deleted = tag.RowsAffected() > 0
		if deleted {
			if err := repo.insertDeleteHistory(ctx, code, domainCode, actor); err != nil {
				return err
			}
			_ = repo.notifyCacheInvalidation(ctx)
		}
		return nil
	})
	return deleted, err
}

func (r *PGRepository) ExistsByCode(ctx context.Context, code string, domainCode string) (bool, error) {
	table := featureFlagTable(domainCode)
	query := fmt.Sprintf(`SELECT EXISTS(SELECT 1 FROM %s WHERE code = $1)`, table)
	var exists bool
	if err := r.db.QueryRow(ctx, query, code).Scan(&exists); err != nil {
		return false, err
	}
	return exists, nil
}

func (r *PGRepository) Recover(ctx context.Context, code string, domainCode string, actor string) (*app.FeatureFlagDetailResponse, error) {
	var result *app.FeatureFlagDetailResponse
	err := r.withTx(ctx, func(repo *PGRepository) error {
		table := featureFlagTable(domainCode)
		if _, err := repo.db.Exec(ctx, fmt.Sprintf(`UPDATE %s SET is_deleted = false WHERE code = $1`, table), code); err != nil {
			return err
		}
		if err := repo.insertDeleteHistory(ctx, code, domainCode, actor); err != nil {
			return err
		}
		found, err := repo.GetByCode(ctx, code, domainCode)
		if err != nil {
			return err
		}
		result = found
		_ = repo.notifyCacheInvalidation(ctx)
		return nil
	})
	return result, err
}

func (r *PGRepository) GroupsByDomain(ctx context.Context, domainCode string) ([]string, error) {
	table := featureFlagTable(domainCode)
	rows, err := r.db.Query(ctx, fmt.Sprintf(`SELECT "group" FROM %s GROUP BY "group" ORDER BY "group"`, table))
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	groups := make([]string, 0)
	for rows.Next() {
		var group string
		if err = rows.Scan(&group); err != nil {
			return nil, err
		}
		groups = append(groups, group)
	}
	return groups, rows.Err()
}

func (r *PGRepository) groupsByDomains(ctx context.Context, domainCodes []string) (map[string][]string, error) {
	result := make(map[string][]string, len(domainCodes))
	parts := make([]string, 0, len(domainCodes))
	args := make([]any, 0, len(domainCodes))
	for _, code := range domainCodes {
		code = strings.ToUpper(strings.TrimSpace(code))
		if code == "" {
			continue
		}
		args = append(args, code)
		parts = append(parts, fmt.Sprintf(`SELECT $%d::text AS domain_code, "group" FROM %s GROUP BY "group"`, len(args), featureFlagTable(code)))
		result[code] = []string{}
	}
	if len(parts) == 0 {
		return result, nil
	}
	rows, err := r.db.Query(ctx, strings.Join(parts, " UNION ALL ")+" ORDER BY domain_code, \"group\"", args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var domainCode string
		var group string
		if err = rows.Scan(&domainCode, &group); err != nil {
			return nil, err
		}
		result[domainCode] = append(result[domainCode], group)
	}
	return result, rows.Err()
}

func (r *PGRepository) ListDomainCodes(ctx context.Context) ([]string, error) {
	rows, err := r.db.Query(ctx, "SELECT code FROM dict_domains ORDER BY code")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	codes := make([]string, 0)
	for rows.Next() {
		var code string
		if err = rows.Scan(&code); err != nil {
			return nil, err
		}
		codes = append(codes, code)
	}
	return codes, rows.Err()
}

func (r *PGRepository) SwitchDueFeatureFlags(
	ctx context.Context,
	domainCode string,
	now time.Time,
) ([]app.FeatureFlagDetailResponse, error) {
	table := featureFlagTable(domainCode)
	historyTable := featureFlagHistoryTable(domainCode)
	updated := make([]app.FeatureFlagDetailResponse, 0)
	for _, query := range []string{
		featureFlagSwitchQuery(table, historyTable, `enabled = false, value = '{false}', updated_at = $1, updated_by = 'system'`, `t.enabled = true AND t.action_end_date <= $1 AND t."type" = 'TOGGLE' AND is_deleted = false`),
		featureFlagSwitchQuery(table, historyTable, `enabled = false, updated_at = $1, updated_by = 'system'`, `t.enabled = true AND t.action_end_date <= $1 AND t."type" <> 'TOGGLE' AND is_deleted = false`),
		featureFlagSwitchQuery(table, historyTable, `enabled = true, value = '{true}', updated_at = $1, updated_by = 'system'`, `t.enabled = false AND t.action_start_date = $1 AND t."type" = 'TOGGLE' AND is_deleted = false`),
		featureFlagSwitchQuery(table, historyTable, `enabled = true, updated_at = $1, updated_by = 'system'`, `t.enabled = false AND t.action_start_date = $1 AND t."type" <> 'TOGGLE' AND is_deleted = false`),
	} {
		rows, err := r.db.Query(ctx, query, now)
		if err != nil {
			return nil, err
		}
		for rows.Next() {
			item, scanErr := scanFeatureFlag(rows)
			if scanErr != nil {
				rows.Close()
				return nil, scanErr
			}
			updated = append(updated, item)
		}
		if err = rows.Err(); err != nil {
			rows.Close()
			return nil, err
		}
		rows.Close()
	}
	if len(updated) > 0 {
		_ = r.notifyCacheInvalidation(ctx)
	}
	return updated, nil
}

func (r *PGRepository) CreateHistory(ctx context.Context, request app.FeatureFlagHistoryCreateRequest, actor string) error {
	table := featureFlagHistoryTable(request.DomainCode)
	query := fmt.Sprintf(`
		INSERT INTO %s
		    (code, updated_at, updated_by, name, "group", "type", enabled, action_start_date, action_end_date, value)
		VALUES ($1, date_trunc('minute', now()), $2, $3, $4, $5, $6, $7, $8, $9)
	`, table)
	_, err := r.db.Exec(ctx, query,
		request.Code,
		actor,
		request.Name,
		request.Group,
		string(request.Type),
		request.Enabled,
		app.TruncateToMinute(request.ActionStartDate),
		app.TruncatePtrToMinute(request.ActionEndDate),
		app.FeatureFlagValueToStrings(request.Value),
	)
	return err
}

func (r *PGRepository) FindHistory(ctx context.Context, request app.FeatureFlagHistorySearchRequest) (app.Page[app.FeatureFlagHistoryResponse], error) {
	table := featureFlagHistoryTable(request.DomainCode)
	orderBy := safeOrderBy(request.OrderBy, featureFlagHistoryOrderColumns, "created_at")
	direction := safeDirection(request.Direction)
	limit := request.Size + 1
	args := []any{request.Code, limit}
	cursorWhere := ""
	hasCursor := strings.TrimSpace(request.Cursor) != ""
	if hasCursor {
		if orderBy != "updated_at" {
			return app.Page[app.FeatureFlagHistoryResponse]{}, app.BadRequest("Cursor истории изменений поддерживает только сортировку по дате изменения")
		}
		cursor, err := decodeFeatureFlagHistoryCursor(request.Cursor)
		if err != nil {
			return app.Page[app.FeatureFlagHistoryResponse]{}, app.BadRequest("Некорректный cursor истории изменений")
		}
		args = append(args, cursor.UpdatedAt, cursor.ID)
		operator := "<"
		if direction == "ASC" {
			operator = ">"
		}
		cursorWhere = fmt.Sprintf(" AND (updated_at, id) %s ($3, $4)", operator)
	}
	query := fmt.Sprintf(`
		SELECT id, updated_at, updated_by, name, "group", "type", enabled, action_start_date, action_end_date, value, is_deleted
		FROM %s
		WHERE code = $1%s
		ORDER BY %s %s, id %s
		LIMIT $2
	`, table, cursorWhere, orderBy, direction, direction)
	if cursorWhere == "" && request.Page > 0 {
		args = append(args, request.Page*request.Size)
		query = fmt.Sprintf(`
			SELECT id, updated_at, updated_by, name, "group", "type", enabled, action_start_date, action_end_date, value, is_deleted
			FROM %s
			WHERE code = $1
			ORDER BY %s %s, id %s
			LIMIT $2 OFFSET $3
		`, table, orderBy, direction, direction)
	}
	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return app.Page[app.FeatureFlagHistoryResponse]{}, err
	}
	defer rows.Close()
	items := make([]app.FeatureFlagHistoryResponse, 0, request.Size+1)
	for rows.Next() {
		item, scanErr := scanFeatureFlagHistory(rows, request.FeatureFlagType)
		if scanErr != nil {
			return app.Page[app.FeatureFlagHistoryResponse]{}, scanErr
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return app.Page[app.FeatureFlagHistoryResponse]{}, err
	}
	nextCursor := ""
	if len(items) > request.Size {
		next := items[request.Size-1]
		nextCursor = encodeFeatureFlagHistoryCursor(next.UpdatedAt, next.ID)
		items = items[:request.Size]
	}
	total := int64(0)
	if !hasCursor {
		total, err = r.count(ctx, fmt.Sprintf(`SELECT count(code) FROM %s WHERE code = $1`, table), request.Code)
		if err != nil {
			return app.Page[app.FeatureFlagHistoryResponse]{}, err
		}
	}
	page := pageOf(items, request.Page, request.Size, total)
	page.NextCursor = nextCursor
	return page, nil
}

func (r *PGRepository) CreateDomain(ctx context.Context, request app.DomainCreateRequest, actor string) (app.DomainResponse, error) {
	var result app.DomainResponse
	err := r.withTx(ctx, func(repo *PGRepository) error {
		query := `
			INSERT INTO dict_domains(created_by, updated_at, updated_by, code, description)
			VALUES ($1, now(), $1, $2, $3)
			RETURNING id, created_at, created_by, updated_at, updated_by, code, description
		`
		domain, err := scanDomain(repo.db.QueryRow(ctx, query, actor, request.Code, request.Description))
		if err != nil {
			if isUniqueViolation(err) {
				return app.Conflict(app.ErrDomainAlreadyExists)
			}
			return err
		}
		if _, err = repo.db.Exec(ctx, `CALL create_feature_flags_table($1)`, request.Code); err != nil {
			return err
		}
		if _, err = repo.db.Exec(ctx, `CALL create_tech_breaks_table($1)`, request.Code); err != nil {
			return err
		}
		_ = repo.notifyCacheInvalidation(ctx)
		result = domain
		return nil
	})
	if err != nil {
		return app.DomainResponse{}, err
	}
	return result, nil
}

func (r *PGRepository) UpdateDomain(ctx context.Context, id int64, request app.DomainUpdateRequest, actor string) (app.DomainResponse, error) {
	var result app.DomainResponse
	err := r.withTx(ctx, func(repo *PGRepository) error {
		existing, err := repo.GetDomainByID(ctx, id)
		if err != nil {
			return err
		}
		if existing == nil {
			return app.NotFound(app.ErrDomainNotFound)
		}
		if existing.Code != request.Code {
			if _, err = repo.db.Exec(ctx,
				fmt.Sprintf(`ALTER TABLE IF EXISTS %s RENAME TO %s`, featureFlagTable(existing.Code), rawIdentifier(strings.ToLower(request.Code)+"_feature_flags")),
			); err != nil {
				return err
			}
			if _, err = repo.db.Exec(ctx,
				fmt.Sprintf(`ALTER TABLE IF EXISTS %s RENAME TO %s`, featureFlagHistoryTable(existing.Code), rawIdentifier(strings.ToLower(request.Code)+"_feature_flags_history")),
			); err != nil {
				return err
			}
			if _, err = repo.db.Exec(ctx,
				fmt.Sprintf(`ALTER TABLE IF EXISTS %s RENAME TO %s`, techBreakTable(existing.Code), rawIdentifier(strings.ToLower(request.Code)+"_tech_breaks")),
			); err != nil {
				return err
			}
		}
		query := `
			UPDATE dict_domains
			SET updated_at = now(), updated_by = $2, code = $3, description = $4
			WHERE id = $1
			RETURNING id, created_at, created_by, updated_at, updated_by, code, description
		`
		domain, err := scanDomain(repo.db.QueryRow(ctx, query, id, actor, request.Code, request.Description))
		if err != nil {
			if isUniqueViolation(err) {
				return app.Conflict(app.ErrDomainAlreadyExists)
			}
			return err
		}
		_ = repo.notifyCacheInvalidation(ctx)
		result = domain
		return nil
	})
	return result, err
}

func (r *PGRepository) GetDomainByID(ctx context.Context, id int64) (*app.DomainResponse, error) {
	query := `SELECT id, created_at, created_by, updated_at, updated_by, code, description FROM dict_domains WHERE id = $1 LIMIT 1`
	result, err := scanDomain(r.db.QueryRow(ctx, query, id))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	groups, _ := r.GroupsByDomain(ctx, result.Code)
	result.FeatureFlagGroups = groups
	return &result, nil
}

func (r *PGRepository) FindDomains(ctx context.Context, request app.DomainSearchRequest) (app.Page[app.DomainResponse], error) {
	where := domainFilters(request.Search)
	args := append([]any{}, where.args...)
	orderBy := safeOrderBy(request.OrderBy, domainOrderColumns, "created_at")
	direction := safeDirection(request.Direction)
	args = append(args, request.Size, request.Page*request.Size)
	query := fmt.Sprintf(`
		SELECT id, created_at, created_by, updated_at, updated_by, code, description
		FROM dict_domains
		%s
		ORDER BY %s %s
		LIMIT $%d OFFSET $%d
	`, where.sql, orderBy, direction, len(args)-1, len(args))
	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return app.Page[app.DomainResponse]{}, err
	}
	defer rows.Close()
	items := make([]app.DomainResponse, 0)
	for rows.Next() {
		item, scanErr := scanDomain(rows)
		if scanErr != nil {
			return app.Page[app.DomainResponse]{}, scanErr
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return app.Page[app.DomainResponse]{}, err
	}
	codes := make([]string, 0, len(items))
	for _, item := range items {
		codes = append(codes, item.Code)
	}
	groupsByDomain, err := r.groupsByDomains(ctx, codes)
	if err != nil {
		return app.Page[app.DomainResponse]{}, err
	}
	for i := range items {
		items[i].FeatureFlagGroups = groupsByDomain[items[i].Code]
	}
	total, err := r.count(ctx, "SELECT count(id) FROM dict_domains "+where.sql, where.args...)
	if err != nil {
		return app.Page[app.DomainResponse]{}, err
	}
	return pageOf(items, request.Page, request.Size, total), nil
}

func (r *PGRepository) insertDeleteHistory(ctx context.Context, code string, domainCode string, actor string) error {
	ffTable := featureFlagTable(domainCode)
	historyTable := featureFlagHistoryTable(domainCode)
	query := fmt.Sprintf(`
		INSERT INTO %s
		    (code, updated_at, updated_by, name, "group", "type", enabled, action_start_date, action_end_date, value, is_deleted)
		SELECT code, now(), $2, name, "group", "type", false, action_start_date, action_end_date, value, is_deleted
		FROM %s
		WHERE code = $1
	`, historyTable, ffTable)
	_, err := r.db.Exec(ctx, query, code, actor)
	return err
}

func (r *PGRepository) count(ctx context.Context, query string, args ...any) (int64, error) {
	var total int64
	if err := r.db.QueryRow(ctx, query, args...).Scan(&total); err != nil {
		return 0, err
	}
	return total, nil
}

func (r *PGRepository) notifyCacheInvalidation(ctx context.Context) error {
	_, err := r.db.Exec(ctx, "SELECT pg_notify($1, $2)", cacheInvalidationChannel, "all")
	return err
}

type sqlWhere struct {
	sql  string
	args []any
}

func featureFlagFilters(request app.FeatureFlagSearchRequest) sqlWhere {
	parts := []string{"is_deleted = $1"}
	args := []any{request.InArchive}
	if strings.TrimSpace(request.Group) != "" {
		args = append(args, request.Group)
		parts = append(parts, fmt.Sprintf(`"group" = $%d`, len(args)))
	}
	if request.ActionStartDate != nil {
		args = append(args, app.TruncateToMinute(*request.ActionStartDate))
		parts = append(parts, fmt.Sprintf("action_start_date >= $%d", len(args)))
	}
	if request.ActionEndDate != nil {
		args = append(args, app.TruncateToMinute(*request.ActionEndDate))
		parts = append(parts, fmt.Sprintf("(action_end_date IS NOT NULL AND action_end_date <= $%d)", len(args)))
	}
	for _, token := range strings.Fields(request.Search) {
		args = append(args, "%"+token+"%")
		parts = append(parts, fmt.Sprintf("(code ILIKE $%d OR name ILIKE $%d)", len(args), len(args)))
	}
	return sqlWhere{sql: "WHERE " + strings.Join(parts, " AND "), args: args}
}

func domainFilters(search string) sqlWhere {
	tokens := strings.Fields(search)
	if len(tokens) == 0 {
		return sqlWhere{}
	}
	parts := make([]string, 0, len(tokens))
	args := make([]any, 0, len(tokens))
	for _, token := range tokens {
		args = append(args, "%"+token+"%")
		parts = append(parts, fmt.Sprintf("(code ILIKE $%d OR description ILIKE $%d)", len(args), len(args)))
	}
	return sqlWhere{sql: "WHERE " + strings.Join(parts, " AND "), args: args}
}

func scanFeatureFlag(row pgx.Row) (app.FeatureFlagDetailResponse, error) {
	var (
		result        app.FeatureFlagDetailResponse
		updatedAt     pgtype.Timestamp
		updatedBy     pgtype.Text
		actionEndDate pgtype.Timestamp
		rawType       string
		rawValues     []string
	)
	err := row.Scan(
		&result.Code,
		&result.CreatedAt,
		&result.CreatedBy,
		&updatedAt,
		&updatedBy,
		&result.Name,
		&result.Group,
		&rawType,
		&result.Enabled,
		&result.ActionStartDate,
		&actionEndDate,
		&rawValues,
		&result.InArchive,
	)
	if err != nil {
		return app.FeatureFlagDetailResponse{}, err
	}
	result.UpdatedAt = timestampPtr(updatedAt)
	result.UpdatedBy = textValue(updatedBy)
	result.ActionEndDate = timestampPtr(actionEndDate)
	result.Type = app.FeatureFlagType(rawType)
	values, err := app.NormalizeFeatureFlagValue(result.Type, rawValues)
	if err != nil {
		return app.FeatureFlagDetailResponse{}, err
	}
	result.Value = values
	return result, nil
}

func featureFlagSwitchQuery(table string, historyTable string, setClause string, condition string) string {
	return fmt.Sprintf(`
		WITH updated AS (
			UPDATE %s t
			SET %s
			WHERE %s
			RETURNING code, created_at, created_by, updated_at, updated_by, name, "group", "type",
			          enabled, action_start_date, action_end_date, value, is_deleted
		),
		inserted AS (
			INSERT INTO %s
			    (code, updated_at, updated_by, name, "group", "type", enabled, action_start_date, action_end_date, value)
			SELECT code, $1, 'system', name, "group", "type", enabled, action_start_date, action_end_date, value
			FROM updated
		)
		SELECT code, created_at, created_by, updated_at, updated_by, name, "group", "type",
		       enabled, action_start_date, action_end_date, value, is_deleted
		FROM updated
	`, table, setClause, condition, historyTable)
}

func scanFeatureFlagHistory(row pgx.Row, flagType app.FeatureFlagType) (app.FeatureFlagHistoryResponse, error) {
	var (
		result        app.FeatureFlagHistoryResponse
		actionEndDate pgtype.Timestamp
		rawType       string
		rawValues     []string
	)
	err := row.Scan(
		&result.ID,
		&result.UpdatedAt,
		&result.UpdatedBy,
		&result.Name,
		&result.Group,
		&rawType,
		&result.Enabled,
		&result.ActionStartDate,
		&actionEndDate,
		&rawValues,
		&result.InArchive,
	)
	if err != nil {
		return app.FeatureFlagHistoryResponse{}, err
	}
	result.ActionEndDate = timestampPtr(actionEndDate)
	result.Type = app.FeatureFlagType(rawType)
	if flagType == "" {
		flagType = result.Type
	}
	values, err := app.NormalizeFeatureFlagValue(flagType, rawValues)
	if err != nil {
		return app.FeatureFlagHistoryResponse{}, err
	}
	result.Value = values
	return result, nil
}

type featureFlagHistoryCursor struct {
	UpdatedAt time.Time `json:"updatedAt"`
	ID        int64     `json:"id"`
}

func encodeFeatureFlagHistoryCursor(updatedAt time.Time, id int64) string {
	payload, err := json.Marshal(featureFlagHistoryCursor{
		UpdatedAt: updatedAt.UTC(),
		ID:        id,
	})
	if err != nil {
		return ""
	}
	return base64.RawURLEncoding.EncodeToString(payload)
}

func decodeFeatureFlagHistoryCursor(value string) (featureFlagHistoryCursor, error) {
	raw, err := base64.RawURLEncoding.DecodeString(strings.TrimSpace(value))
	if err != nil {
		return featureFlagHistoryCursor{}, err
	}
	var cursor featureFlagHistoryCursor
	if err = json.Unmarshal(raw, &cursor); err != nil {
		return featureFlagHistoryCursor{}, err
	}
	if cursor.UpdatedAt.IsZero() || cursor.ID <= 0 {
		return featureFlagHistoryCursor{}, fmt.Errorf("invalid feature flag history cursor")
	}
	return cursor, nil
}

func scanDomain(row pgx.Row) (app.DomainResponse, error) {
	var (
		result    app.DomainResponse
		updatedAt pgtype.Timestamp
		updatedBy pgtype.Text
	)
	err := row.Scan(
		&result.ID,
		&result.CreatedAt,
		&result.CreatedBy,
		&updatedAt,
		&updatedBy,
		&result.Code,
		&result.Description,
	)
	if err != nil {
		return app.DomainResponse{}, err
	}
	result.UpdatedAt = timestampPtr(updatedAt)
	result.UpdatedBy = textValue(updatedBy)
	result.FeatureFlagGroups = []string{}
	return result, nil
}

func pageOf[T any](items []T, page int, size int, total int64) app.Page[T] {
	totalPages := 0
	if size > 0 {
		totalPages = int(math.Ceil(float64(total) / float64(size)))
	}
	return app.Page[T]{
		Content:       items,
		Page:          page,
		Size:          size,
		TotalElements: total,
		TotalPages:    totalPages,
	}
}

func featureFlagTable(domainCode string) string {
	return rawIdentifier(strings.ToLower(strings.TrimSpace(domainCode)) + "_feature_flags")
}

func featureFlagHistoryTable(domainCode string) string {
	return rawIdentifier(strings.ToLower(strings.TrimSpace(domainCode)) + "_feature_flags_history")
}

func techBreakTable(domainCode string) string {
	return rawIdentifier(strings.ToLower(strings.TrimSpace(domainCode)) + "_tech_breaks")
}

func rawIdentifier(value string) string {
	return pgx.Identifier{value}.Sanitize()
}

func timestampPtr(value pgtype.Timestamp) *time.Time {
	if !value.Valid {
		return nil
	}
	return &value.Time
}

func textValue(value pgtype.Text) string {
	if !value.Valid {
		return ""
	}
	return value.String
}

func safeDirection(direction string) string {
	if strings.EqualFold(direction, "asc") {
		return "ASC"
	}
	return "DESC"
}

func safeOrderBy(value string, allowed map[string]string, fallback string) string {
	normalized := strings.ToLower(strings.TrimSpace(value))
	if column, ok := allowed[normalized]; ok {
		return column
	}
	return allowed[fallback]
}

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}

var featureFlagOrderColumns = map[string]string{
	"code":              "code",
	"created_at":        "created_at",
	"createdat":         "created_at",
	"updated_at":        "updated_at",
	"updatedat":         "updated_at",
	"name":              "name",
	"group":             `"group"`,
	"type":              `"type"`,
	"enabled":           "enabled",
	"action_start_date": "action_start_date",
	"actionstartdate":   "action_start_date",
	"action_end_date":   "action_end_date",
	"actionenddate":     "action_end_date",
}

var featureFlagHistoryOrderColumns = map[string]string{
	"created_at":        "updated_at",
	"createdat":         "updated_at",
	"updated_at":        "updated_at",
	"updatedat":         "updated_at",
	"action_start_date": "action_start_date",
	"actionstartdate":   "action_start_date",
	"action_end_date":   "action_end_date",
	"actionenddate":     "action_end_date",
}

var domainOrderColumns = map[string]string{
	"id":          "id",
	"created_at":  "created_at",
	"createdat":   "created_at",
	"updated_at":  "updated_at",
	"updatedat":   "updated_at",
	"code":        "code",
	"description": "description",
}
