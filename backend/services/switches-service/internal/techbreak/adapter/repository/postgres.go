package repository

import (
	"context"
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

	"kz/inflap/backend/services/switches-service/internal/techbreak/app"
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
	if !ok {
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

func (r *PGRepository) Create(
	ctx context.Context,
	request app.TechBreakUpsertRequest,
	scopes []app.TechBreakScope,
	enabled bool,
	actor string,
) (app.TechBreakResponse, error) {
	table := techBreakTable(request.DomainCode)
	query := fmt.Sprintf(`
		INSERT INTO %s
		    (name, enabled, created_by, action_start_date, action_end_date,
		     exclude_emails, exclude_nicknames, scope_codes)
		VALUES ($1, $2, $3, $4, $5, $6::text[], $7::text[], $8::text[])
		RETURNING id, created_at, created_by, updated_at, updated_by, name, enabled,
		          action_start_date, action_end_date, exclude_emails, exclude_nicknames, scope_codes
	`, table)
	detail, err := scanTechBreak(r.db.QueryRow(ctx, query,
		request.Name,
		enabled,
		actor,
		app.TruncateToMinute(request.ActionStartDate),
		app.TruncatePtrToMinute(request.ActionEndDate),
		request.ExcludeEmails,
		request.ExcludeNicknames,
		request.ScopeCodes,
	), request.DomainCode, scopes)
	if err != nil {
		return app.TechBreakResponse{}, err
	}
	_ = r.notifyCacheInvalidation(ctx)
	return detail.ToResponse(), nil
}

func (r *PGRepository) Update(
	ctx context.Context,
	id int64,
	request app.TechBreakUpsertRequest,
	scopes []app.TechBreakScope,
	enabled bool,
	actor string,
) (*app.TechBreakResponse, error) {
	table := techBreakTable(request.DomainCode)
	query := fmt.Sprintf(`
		UPDATE %s
		SET updated_at = now(),
		    updated_by = $2,
		    name = $3,
		    enabled = $4,
		    action_start_date = $5,
		    action_end_date = $6,
		    exclude_emails = $7::text[],
		    exclude_nicknames = $8::text[],
		    scope_codes = $9::text[]
		WHERE id = $1
		  AND (
		    name IS DISTINCT FROM $3 OR
		    action_start_date IS DISTINCT FROM $5 OR
		    action_end_date IS DISTINCT FROM $6 OR
		    exclude_emails IS DISTINCT FROM $7::text[] OR
		    exclude_nicknames IS DISTINCT FROM $8::text[] OR
		    scope_codes IS DISTINCT FROM $9::text[]
		  )
		RETURNING id, created_at, created_by, updated_at, updated_by, name, enabled,
		          action_start_date, action_end_date, exclude_emails, exclude_nicknames, scope_codes
	`, table)
	detail, err := scanTechBreak(r.db.QueryRow(ctx, query,
		id,
		actor,
		request.Name,
		enabled,
		app.TruncateToMinute(request.ActionStartDate),
		app.TruncatePtrToMinute(request.ActionEndDate),
		request.ExcludeEmails,
		request.ExcludeNicknames,
		request.ScopeCodes,
	), request.DomainCode, scopes)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	_ = r.notifyCacheInvalidation(ctx)
	response := detail.ToResponse()
	return &response, nil
}

func (r *PGRepository) GetByID(ctx context.Context, id int64, domainCode string, scopes []app.TechBreakScope) (*app.TechBreakResponse, error) {
	table := techBreakTable(domainCode)
	query := fmt.Sprintf(`
		SELECT id, created_at, created_by, updated_at, updated_by, name, enabled,
		       action_start_date, action_end_date, exclude_emails, exclude_nicknames, scope_codes
		FROM %s
		WHERE id = $1
		LIMIT 1
	`, table)
	detail, err := scanTechBreak(r.db.QueryRow(ctx, query, id), domainCode, scopes)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	response := detail.ToResponse()
	return &response, nil
}

func (r *PGRepository) FindAll(ctx context.Context, request app.TechBreakSearchRequest, scopes []app.TechBreakScope) (app.Page[app.TechBreakResponse], error) {
	table := techBreakTable(request.DomainCode)
	where := techBreakFilters(request)
	args := append([]any{}, where.args...)
	orderBy := safeOrderBy(request.OrderBy, techBreakOrderColumns, "created_at")
	direction := safeDirection(request.Direction)
	args = append(args, request.Size, request.Page*request.Size)
	query := fmt.Sprintf(`
		SELECT id, created_at, created_by, updated_at, updated_by, name, enabled,
		       action_start_date, action_end_date, exclude_emails, exclude_nicknames, scope_codes
		FROM %s
		%s
		ORDER BY %s %s
		LIMIT $%d OFFSET $%d
	`, table, where.sql, orderBy, direction, len(args)-1, len(args))
	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return app.Page[app.TechBreakResponse]{}, err
	}
	defer rows.Close()
	items := make([]app.TechBreakResponse, 0)
	for rows.Next() {
		detail, scanErr := scanTechBreak(rows, request.DomainCode, scopes)
		if scanErr != nil {
			return app.Page[app.TechBreakResponse]{}, scanErr
		}
		items = append(items, detail.ToResponse())
	}
	if err = rows.Err(); err != nil {
		return app.Page[app.TechBreakResponse]{}, err
	}
	total, err := r.count(ctx, fmt.Sprintf("SELECT count(id) FROM %s %s", table, where.sql), where.args...)
	if err != nil {
		return app.Page[app.TechBreakResponse]{}, err
	}
	return pageOf(items, request.Page, request.Size, total), nil
}

func (r *PGRepository) Delete(ctx context.Context, id int64, domainCode string) (bool, error) {
	table := techBreakTable(domainCode)
	tag, err := r.db.Exec(ctx, fmt.Sprintf("DELETE FROM %s WHERE id = $1", table), id)
	if err != nil {
		return false, err
	}
	deleted := tag.RowsAffected() > 0
	if deleted {
		_ = r.notifyCacheInvalidation(ctx)
	}
	return deleted, nil
}

func (r *PGRepository) ExistsByName(ctx context.Context, name string, domainCode string, excludeID *int64) (bool, error) {
	table := techBreakTable(domainCode)
	args := []any{name}
	condition := "name = $1"
	if excludeID != nil {
		args = append(args, *excludeID)
		condition += " AND id <> $2"
	}
	var exists bool
	query := fmt.Sprintf("SELECT EXISTS(SELECT 1 FROM %s WHERE %s)", table, condition)
	if err := r.db.QueryRow(ctx, query, args...).Scan(&exists); err != nil {
		return false, err
	}
	return exists, nil
}

func (r *PGRepository) HasActive(ctx context.Context, request app.TechBreakCheckRequest) (bool, error) {
	table := techBreakTable(request.DomainCode)
	query := fmt.Sprintf(`
		SELECT EXISTS(
			SELECT 1
			FROM %s
			WHERE enabled IS TRUE
			  AND action_start_date <= date_trunc('minute', now())
			  AND (action_end_date IS NULL OR action_end_date > date_trunc('minute', now()))
			  AND (
			    (
			      cardinality($1::text[]) > 0
			      AND (cardinality(scope_codes) = 0 OR scope_codes && $1::text[])
			    )
			    OR (
			      cardinality($1::text[]) = 0
			      AND cardinality(scope_codes) = 0
			    )
			  )
			  AND ($2 = '' OR NOT (exclude_emails @> ARRAY[$2]::text[]))
			  AND ($3 = '' OR NOT (exclude_nicknames @> ARRAY[$3]::text[]))
			LIMIT 1
		)
	`, table)
	var exists bool
	if err := r.db.QueryRow(ctx, query, request.ScopeCodes, strings.TrimSpace(request.Email), strings.TrimSpace(request.Nickname)).Scan(&exists); err != nil {
		return false, err
	}
	return exists, nil
}

func (r *PGRepository) ExistsActiveByScope(ctx context.Context, domainCode string, scopeCode string) (bool, error) {
	table := techBreakTable(domainCode)
	query := fmt.Sprintf(`
		SELECT EXISTS(
			SELECT 1
			FROM %s
			WHERE $1 = ANY(scope_codes)
			  AND (enabled IS TRUE OR action_start_date >= date_trunc('minute', now()))
		)
	`, table)
	var exists bool
	if err := r.db.QueryRow(ctx, query, scopeCode).Scan(&exists); err != nil {
		return false, err
	}
	return exists, nil
}

func (r *PGRepository) DeleteAllByScope(ctx context.Context, domainCode string, scopeCode string) error {
	table := techBreakTable(domainCode)
	tag, err := r.db.Exec(ctx, fmt.Sprintf("DELETE FROM %s WHERE $1 = ANY(scope_codes)", table), scopeCode)
	if err == nil && tag.RowsAffected() > 0 {
		_ = r.notifyCacheInvalidation(ctx)
	}
	return err
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

func (r *PGRepository) SwitchDueTechBreaks(
	ctx context.Context,
	domainCode string,
	now time.Time,
) ([]app.TechBreakResponse, error) {
	table := techBreakTable(domainCode)
	scopes, err := r.FindScopesByCodes(ctx, domainCode, nil)
	if err != nil {
		return nil, err
	}
	updated := make([]app.TechBreakResponse, 0)
	for _, query := range []string{
		techBreakSwitchQuery(table, "false", "t.enabled = true AND t.action_end_date <= $1"),
		techBreakSwitchQuery(table, "true", "t.enabled = false AND t.action_start_date = $1"),
	} {
		rows, err := r.db.Query(ctx, query, now)
		if err != nil {
			return nil, err
		}
		for rows.Next() {
			detail, scanErr := scanTechBreak(rows, domainCode, scopes)
			if scanErr != nil {
				rows.Close()
				return nil, scanErr
			}
			updated = append(updated, detail.ToResponse())
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

func (r *PGRepository) CreateScope(ctx context.Context, request app.TechBreakScopeCreateRequest, actor string) (app.TechBreakScope, error) {
	query := `
		INSERT INTO dict_tech_break_scopes(created_by, code, name, domain_code)
		VALUES ($1, $2, $3, $4)
		RETURNING id, domain_code, created_at, created_by, updated_at, updated_by, code, name
	`
	scope, err := scanScope(r.db.QueryRow(ctx, query, actor, request.Code, request.Name, request.DomainCode))
	if err != nil {
		if isUniqueViolation(err) {
			return app.TechBreakScope{}, app.Conflict(fmt.Errorf("Scope уже существует с кодом %s", request.Code))
		}
		return app.TechBreakScope{}, err
	}
	_ = r.notifyCacheInvalidation(ctx)
	return scope, nil
}

func (r *PGRepository) UpdateScope(ctx context.Context, id int64, request app.TechBreakScopeUpdateRequest, actor string) (app.TechBreakScope, error) {
	query := `
		UPDATE dict_tech_break_scopes
		SET updated_at = now(), updated_by = $2, name = $3
		WHERE id = $1 AND domain_code = $4
		RETURNING id, domain_code, created_at, created_by, updated_at, updated_by, code, name
	`
	scope, err := scanScope(r.db.QueryRow(ctx, query, id, actor, request.Name, request.DomainCode))
	if errors.Is(err, pgx.ErrNoRows) {
		return app.TechBreakScope{}, app.NotFound(app.ErrScopeNotFound)
	}
	if err == nil {
		_ = r.notifyCacheInvalidation(ctx)
	}
	return scope, err
}

func (r *PGRepository) GetScopeByID(ctx context.Context, id int64, domainCode string) (*app.TechBreakScope, error) {
	query := `
		SELECT id, domain_code, created_at, created_by, updated_at, updated_by, code, name
		FROM dict_tech_break_scopes
		WHERE id = $1 AND domain_code = $2
		LIMIT 1
	`
	scope, err := scanScope(r.db.QueryRow(ctx, query, id, domainCode))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &scope, nil
}

func (r *PGRepository) GetScopeByIDAnyDomain(ctx context.Context, id int64) (*app.TechBreakScope, error) {
	query := `
		SELECT id, domain_code, created_at, created_by, updated_at, updated_by, code, name
		FROM dict_tech_break_scopes
		WHERE id = $1
		LIMIT 1
	`
	scope, err := scanScope(r.db.QueryRow(ctx, query, id))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &scope, nil
}

func (r *PGRepository) FindScopes(ctx context.Context, domainCode string) ([]app.TechBreakScope, error) {
	return r.FindScopesByCodes(ctx, domainCode, nil)
}

func (r *PGRepository) DeleteScope(ctx context.Context, id int64) error {
	tag, err := r.db.Exec(ctx, "DELETE FROM dict_tech_break_scopes WHERE id = $1", id)
	if err == nil && tag.RowsAffected() > 0 {
		_ = r.notifyCacheInvalidation(ctx)
	}
	return err
}

func (r *PGRepository) ScopeExistsByCode(ctx context.Context, domainCode string, code string) (bool, error) {
	var exists bool
	err := r.db.QueryRow(ctx,
		"SELECT EXISTS(SELECT 1 FROM dict_tech_break_scopes WHERE domain_code = $1 AND code = $2)",
		domainCode,
		code,
	).Scan(&exists)
	return exists, err
}

func (r *PGRepository) FindScopesByCodes(ctx context.Context, domainCode string, codes []string) ([]app.TechBreakScope, error) {
	args := []any{domainCode}
	filter := "domain_code = $1"
	if len(codes) > 0 {
		args = append(args, codes)
		filter += " AND code = ANY($2::text[])"
	}
	rows, err := r.db.Query(ctx, `
		SELECT id, domain_code, created_at, created_by, updated_at, updated_by, code, name
		FROM dict_tech_break_scopes
		WHERE `+filter+`
		ORDER BY code
	`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	scopes := make([]app.TechBreakScope, 0)
	for rows.Next() {
		scope, scanErr := scanScope(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		scopes = append(scopes, scope)
	}
	return scopes, rows.Err()
}

func (r *PGRepository) DomainHasScopes(ctx context.Context, domainCode string) (bool, error) {
	var exists bool
	err := r.db.QueryRow(ctx,
		"SELECT EXISTS(SELECT 1 FROM dict_tech_break_scopes WHERE domain_code = $1)",
		domainCode,
	).Scan(&exists)
	return exists, err
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
		if _, err = repo.db.Exec(ctx, `CALL create_tech_breaks_table($1)`, request.Code); err != nil {
			return err
		}
		_ = repo.notifyCacheInvalidation(ctx)
		result = domain
		return nil
	})
	return result, err
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
	total, err := r.count(ctx, "SELECT count(id) FROM dict_domains "+where.sql, where.args...)
	if err != nil {
		return app.Page[app.DomainResponse]{}, err
	}
	return pageOf(items, request.Page, request.Size, total), nil
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

func techBreakFilters(request app.TechBreakSearchRequest) sqlWhere {
	parts := []string{"1=1"}
	args := make([]any, 0)
	if request.ActionStartDate != nil {
		args = append(args, app.TruncateToMinute(*request.ActionStartDate))
		parts = append(parts, fmt.Sprintf("action_start_date >= $%d", len(args)))
	}
	if request.ActionEndDate != nil {
		args = append(args, app.TruncateToMinute(*request.ActionEndDate))
		parts = append(parts, fmt.Sprintf("(action_end_date IS NOT NULL AND action_end_date <= $%d)", len(args)))
	}
	searchParts := make([]string, 0)
	for _, token := range strings.Fields(request.Search) {
		args = append(args, "%"+token+"%")
		searchParts = append(searchParts, fmt.Sprintf("name ILIKE $%d", len(args)))
	}
	if len(searchParts) > 0 {
		parts = append(parts, "("+strings.Join(searchParts, " OR ")+")")
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

func scanTechBreak(row pgx.Row, domainCode string, scopes []app.TechBreakScope) (app.TechBreakDetail, error) {
	var (
		result           app.TechBreakDetail
		updatedAt        pgtype.Timestamp
		updatedBy        pgtype.Text
		actionEndDate    pgtype.Timestamp
		excludeEmails    []string
		excludeNicknames []string
		scopeCodes       []string
	)
	err := row.Scan(
		&result.ID,
		&result.CreatedAt,
		&result.CreatedBy,
		&updatedAt,
		&updatedBy,
		&result.Name,
		&result.Enabled,
		&result.ActionStartDate,
		&actionEndDate,
		&excludeEmails,
		&excludeNicknames,
		&scopeCodes,
	)
	if err != nil {
		return app.TechBreakDetail{}, err
	}
	result.UpdatedAt = timestampPtr(updatedAt)
	result.UpdatedBy = textValue(updatedBy)
	result.ActionEndDate = timestampPtr(actionEndDate)
	result.ExcludeEmails = excludeEmails
	result.ExcludeNicknames = excludeNicknames
	result.ScopeCodes = scopeCodes
	result.Scopes = scopesByCodes(scopes, scopeCodes)
	_ = domainCode
	return result, nil
}

func techBreakSwitchQuery(table string, enabled string, condition string) string {
	return fmt.Sprintf(`
		UPDATE %s t
		SET enabled = %s,
		    updated_at = $1,
		    updated_by = 'system'
		WHERE %s
		RETURNING id, created_at, created_by, updated_at, updated_by, name, enabled,
		          action_start_date, action_end_date, exclude_emails, exclude_nicknames, scope_codes
	`, table, enabled, condition)
}

func scanScope(row pgx.Row) (app.TechBreakScope, error) {
	var (
		result    app.TechBreakScope
		updatedAt pgtype.Timestamp
		updatedBy pgtype.Text
	)
	err := row.Scan(
		&result.ID,
		&result.DomainCode,
		&result.CreatedAt,
		&result.CreatedBy,
		&updatedAt,
		&updatedBy,
		&result.Code,
		&result.Name,
	)
	if err != nil {
		return app.TechBreakScope{}, err
	}
	result.UpdatedAt = timestampPtr(updatedAt)
	result.UpdatedBy = textValue(updatedBy)
	return result, nil
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

func scopesByCodes(scopes []app.TechBreakScope, codes []string) []app.TechBreakScope {
	codeSet := make(map[string]struct{}, len(codes))
	for _, code := range codes {
		codeSet[code] = struct{}{}
	}
	result := make([]app.TechBreakScope, 0, len(codes))
	for _, scope := range scopes {
		if _, ok := codeSet[scope.Code]; ok {
			result = append(result, scope)
		}
	}
	return result
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

var techBreakOrderColumns = map[string]string{
	"id":                "id",
	"created_at":        "created_at",
	"createdat":         "created_at",
	"updated_at":        "updated_at",
	"updatedat":         "updated_at",
	"name":              "name",
	"enabled":           "enabled",
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
