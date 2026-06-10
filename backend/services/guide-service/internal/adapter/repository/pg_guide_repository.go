package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
	"kz/inflap/backend/services/guide-service/internal/domain/port"
)

type PGGuideRepository struct {
	pool *pgxpool.Pool
}

func NewPGGuideRepository(pool *pgxpool.Pool) *PGGuideRepository {
	return &PGGuideRepository{pool: pool}
}

func (r *PGGuideRepository) CreateGuideProfile(ctx context.Context, profile *model.GuideProfile) error {
	const query = `
		INSERT INTO guide_profiles (
			id, user_id, type, status, headline, about, experience_years,
			base_city_id, is_private_guide_available, is_activity_host_available,
			is_excursion_guide_available, rating_avg, reviews_count,
			status_reason, status_changed_at, status_changed_by,
			created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7,
			$8, $9, $10,
			$11, $12, $13,
			$14, $15, $16,
			$17, $18
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		profile.ID,
		profile.UserID,
		string(profile.Type),
		string(profile.Status),
		profile.Headline,
		profile.About,
		profile.ExperienceYears,
		profile.BaseCityID,
		profile.IsPrivateGuideAvailable,
		profile.IsActivityHostAvailable,
		profile.IsExcursionGuideAvailable,
		profile.RatingAvg,
		profile.ReviewsCount,
		profile.StatusReason,
		profile.StatusChangedAt,
		profile.StatusChangedBy,
		profile.CreatedAt,
		profile.UpdatedAt,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert guide profile: %w", err)
	}

	return nil
}

func (r *PGGuideRepository) GetGuideProfileByID(ctx context.Context, id uuid.UUID) (*model.GuideProfile, error) {
	const query = `
		SELECT
			id, user_id, type, status, headline, about, experience_years,
			base_city_id, is_private_guide_available, is_activity_host_available,
			is_excursion_guide_available, rating_avg, reviews_count,
			status_reason, status_changed_at, status_changed_by,
			created_at, updated_at
		FROM guide_profiles
		WHERE id = $1
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, id)

	var (
		item      model.GuideProfile
		typeRaw   string
		statusRaw string
	)

	err := row.Scan(
		&item.ID,
		&item.UserID,
		&typeRaw,
		&statusRaw,
		&item.Headline,
		&item.About,
		&item.ExperienceYears,
		&item.BaseCityID,
		&item.IsPrivateGuideAvailable,
		&item.IsActivityHostAvailable,
		&item.IsExcursionGuideAvailable,
		&item.RatingAvg,
		&item.ReviewsCount,
		&item.StatusReason,
		&item.StatusChangedAt,
		&item.StatusChangedBy,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select guide profile by id: %w", err)
	}

	item.Type = enum.GuideType(typeRaw)
	item.Status = enum.GuideStatus(statusRaw)

	return &item, nil
}

func (r *PGGuideRepository) GetGuideProfileByUserID(ctx context.Context, userID uuid.UUID) (*model.GuideProfile, error) {
	const query = `
		SELECT
			id, user_id, type, status, headline, about, experience_years,
			base_city_id, is_private_guide_available, is_activity_host_available,
			is_excursion_guide_available, rating_avg, reviews_count,
			status_reason, status_changed_at, status_changed_by,
			created_at, updated_at
		FROM guide_profiles
		WHERE user_id = $1
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, userID)

	var (
		item      model.GuideProfile
		typeRaw   string
		statusRaw string
	)

	err := row.Scan(
		&item.ID,
		&item.UserID,
		&typeRaw,
		&statusRaw,
		&item.Headline,
		&item.About,
		&item.ExperienceYears,
		&item.BaseCityID,
		&item.IsPrivateGuideAvailable,
		&item.IsActivityHostAvailable,
		&item.IsExcursionGuideAvailable,
		&item.RatingAvg,
		&item.ReviewsCount,
		&item.StatusReason,
		&item.StatusChangedAt,
		&item.StatusChangedBy,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select guide profile by user id: %w", err)
	}

	item.Type = enum.GuideType(typeRaw)
	item.Status = enum.GuideStatus(statusRaw)

	return &item, nil
}

func (r *PGGuideRepository) UpdateGuideProfile(ctx context.Context, profile *model.GuideProfile) error {
	const query = `
		UPDATE guide_profiles
		SET
			type = $2,
			status = $3,
			headline = $4,
			about = $5,
			experience_years = $6,
			base_city_id = $7,
			is_private_guide_available = $8,
			is_activity_host_available = $9,
			is_excursion_guide_available = $10,
			rating_avg = $11,
			reviews_count = $12,
			status_reason = $13,
			status_changed_at = $14,
			status_changed_by = $15,
			updated_at = $16
		WHERE id = $1
	`

	tag, err := r.pool.Exec(
		ctx,
		query,
		profile.ID,
		string(profile.Type),
		string(profile.Status),
		profile.Headline,
		profile.About,
		profile.ExperienceYears,
		profile.BaseCityID,
		profile.IsPrivateGuideAvailable,
		profile.IsActivityHostAvailable,
		profile.IsExcursionGuideAvailable,
		profile.RatingAvg,
		profile.ReviewsCount,
		profile.StatusReason,
		profile.StatusChangedAt,
		profile.StatusChangedBy,
		profile.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update guide profile: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}

func (r *PGGuideRepository) UpdateGuideRatingSnapshot(ctx context.Context, guideProfileID uuid.UUID, ratingAvg float64, reviewsCount int) error {
	const query = `
		UPDATE guide_profiles
		SET rating_avg = $2,
			reviews_count = $3,
			updated_at = NOW()
		WHERE id = $1
	`
	tag, err := r.pool.Exec(ctx, query, guideProfileID, ratingAvg, reviewsCount)
	if err != nil {
		return fmt.Errorf("update guide rating snapshot: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PGGuideRepository) CreateVerificationRequest(ctx context.Context, req *model.GuideVerificationRequest) error {
	const query = `
		INSERT INTO guide_verification_requests (
			id, guide_profile_id, status, comment, review_comment,
			submitted_at, reviewed_at, reviewed_by, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5,
			$6, $7, $8, $9, $10
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		req.ID,
		req.GuideProfileID,
		string(req.Status),
		req.Comment,
		req.ReviewComment,
		req.SubmittedAt,
		req.ReviewedAt,
		req.ReviewedBy,
		req.CreatedAt,
		req.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert verification request: %w", err)
	}

	return nil
}

func (r *PGGuideRepository) GetVerificationRequestByID(ctx context.Context, id uuid.UUID) (*model.GuideVerificationRequest, error) {
	const query = `
		SELECT
			id, guide_profile_id, status, comment, review_comment,
			submitted_at, reviewed_at, reviewed_by, created_at, updated_at
		FROM guide_verification_requests
		WHERE id = $1
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, id)

	var (
		item      model.GuideVerificationRequest
		statusRaw string
	)

	err := row.Scan(
		&item.ID,
		&item.GuideProfileID,
		&statusRaw,
		&item.Comment,
		&item.ReviewComment,
		&item.SubmittedAt,
		&item.ReviewedAt,
		&item.ReviewedBy,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select verification request by id: %w", err)
	}

	item.Status = enum.VerificationRequestStatus(statusRaw)
	return &item, nil
}

func (r *PGGuideRepository) GetLatestVerificationRequestByGuideProfileID(
	ctx context.Context,
	guideProfileID uuid.UUID,
) (*model.GuideVerificationRequest, error) {
	const query = `
		SELECT
			id, guide_profile_id, status, comment, review_comment,
			submitted_at, reviewed_at, reviewed_by, created_at, updated_at
		FROM guide_verification_requests
		WHERE guide_profile_id = $1
		ORDER BY created_at DESC
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, guideProfileID)

	var (
		item      model.GuideVerificationRequest
		statusRaw string
	)

	err := row.Scan(
		&item.ID,
		&item.GuideProfileID,
		&statusRaw,
		&item.Comment,
		&item.ReviewComment,
		&item.SubmittedAt,
		&item.ReviewedAt,
		&item.ReviewedBy,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select latest verification request: %w", err)
	}

	item.Status = enum.VerificationRequestStatus(statusRaw)
	return &item, nil
}

func (r *PGGuideRepository) UpdateVerificationRequest(ctx context.Context, req *model.GuideVerificationRequest) error {
	const query = `
		UPDATE guide_verification_requests
		SET
			status = $2,
			comment = $3,
			review_comment = $4,
			submitted_at = $5,
			reviewed_at = $6,
			reviewed_by = $7,
			updated_at = $8
		WHERE id = $1
	`

	tag, err := r.pool.Exec(
		ctx,
		query,
		req.ID,
		string(req.Status),
		req.Comment,
		req.ReviewComment,
		req.SubmittedAt,
		req.ReviewedAt,
		req.ReviewedBy,
		req.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update verification request: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}

func (r *PGGuideRepository) AddGuideDocument(ctx context.Context, doc *model.GuideDocument) error {
	const query = `
		INSERT INTO guide_documents (
			id, verification_request_id, file_id, document_type, created_at
		) VALUES (
			$1, $2, $3, $4, $5
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		doc.ID,
		doc.VerificationRequestID,
		doc.FileID,
		doc.DocumentType,
		doc.CreatedAt,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert guide document: %w", err)
	}

	return nil
}

func (r *PGGuideRepository) ListGuideDocumentsByVerificationRequestID(
	ctx context.Context,
	verificationRequestID uuid.UUID,
) ([]*model.GuideDocument, error) {
	const query = `
		SELECT
			id, verification_request_id, file_id, document_type, created_at
		FROM guide_documents
		WHERE verification_request_id = $1
		ORDER BY created_at ASC
	`

	rows, err := r.pool.Query(ctx, query, verificationRequestID)
	if err != nil {
		return nil, fmt.Errorf("query guide documents: %w", err)
	}
	defer rows.Close()

	var result []*model.GuideDocument
	for rows.Next() {
		var item model.GuideDocument
		if err = rows.Scan(
			&item.ID,
			&item.VerificationRequestID,
			&item.FileID,
			&item.DocumentType,
			&item.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan guide document: %w", err)
		}
		result = append(result, &item)
	}

	return result, rows.Err()
}

func (r *PGGuideRepository) AddGuideLanguage(ctx context.Context, language *model.GuideLanguage) error {
	const query = `
		INSERT INTO guide_languages (
			id, guide_profile_id, language_code, proficiency_level, created_at
		) VALUES (
			$1, $2, $3, $4, $5
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		language.ID,
		language.GuideProfileID,
		language.LanguageCode,
		language.ProficiencyLevel,
		language.CreatedAt,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert guide language: %w", err)
	}

	return nil
}

func (r *PGGuideRepository) ReplaceGuideLanguages(
	ctx context.Context,
	guideProfileID uuid.UUID,
	items []*model.GuideLanguage,
) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if _, err = tx.Exec(ctx, `DELETE FROM guide_languages WHERE guide_profile_id = $1`, guideProfileID); err != nil {
		return fmt.Errorf("delete guide languages: %w", err)
	}

	const insertQuery = `
		INSERT INTO guide_languages (
			id, guide_profile_id, language_code, proficiency_level, created_at
		) VALUES ($1, $2, $3, $4, $5)
	`
	for _, item := range items {
		if _, err = tx.Exec(
			ctx,
			insertQuery,
			item.ID,
			item.GuideProfileID,
			item.LanguageCode,
			item.ProficiencyLevel,
			item.CreatedAt,
		); err != nil {
			return fmt.Errorf("insert guide language in tx: %w", err)
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}

	return nil
}

func (r *PGGuideRepository) ListGuideLanguages(ctx context.Context, guideProfileID uuid.UUID) ([]*model.GuideLanguage, error) {
	const query = `
		SELECT
			id, guide_profile_id, language_code, proficiency_level, created_at
		FROM guide_languages
		WHERE guide_profile_id = $1
		ORDER BY created_at ASC
	`

	rows, err := r.pool.Query(ctx, query, guideProfileID)
	if err != nil {
		return nil, fmt.Errorf("query guide languages: %w", err)
	}
	defer rows.Close()

	var result []*model.GuideLanguage
	for rows.Next() {
		var item model.GuideLanguage
		if err = rows.Scan(
			&item.ID,
			&item.GuideProfileID,
			&item.LanguageCode,
			&item.ProficiencyLevel,
			&item.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan guide language: %w", err)
		}
		result = append(result, &item)
	}

	return result, rows.Err()
}

func (r *PGGuideRepository) ListGuideLanguagesByProfileIDs(
	ctx context.Context,
	guideProfileIDs []uuid.UUID,
) (map[uuid.UUID][]*model.GuideLanguage, error) {
	if len(guideProfileIDs) == 0 {
		return map[uuid.UUID][]*model.GuideLanguage{}, nil
	}

	placeholders, args := uuidPlaceholders(guideProfileIDs)
	query := fmt.Sprintf(`
		SELECT
			id, guide_profile_id, language_code, proficiency_level, created_at
		FROM guide_languages
		WHERE guide_profile_id IN (%s)
		ORDER BY guide_profile_id ASC, created_at ASC
	`, placeholders)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query guide languages by profile ids: %w", err)
	}
	defer rows.Close()

	result := make(map[uuid.UUID][]*model.GuideLanguage, len(guideProfileIDs))
	for rows.Next() {
		var item model.GuideLanguage
		if err = rows.Scan(
			&item.ID,
			&item.GuideProfileID,
			&item.LanguageCode,
			&item.ProficiencyLevel,
			&item.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan guide language: %w", err)
		}
		result[item.GuideProfileID] = append(result[item.GuideProfileID], &item)
	}

	return result, rows.Err()
}

func (r *PGGuideRepository) AddGuideSpecialization(ctx context.Context, specialization *model.GuideSpecialization) error {
	const query = `
		INSERT INTO guide_specializations (
			id, guide_profile_id, specialization_code, created_at
		) VALUES (
			$1, $2, $3, $4
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		specialization.ID,
		specialization.GuideProfileID,
		specialization.SpecializationCode,
		specialization.CreatedAt,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert guide specialization: %w", err)
	}

	return nil
}

func (r *PGGuideRepository) ReplaceGuideSpecializations(
	ctx context.Context,
	guideProfileID uuid.UUID,
	items []*model.GuideSpecialization,
) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if _, err = tx.Exec(ctx, `DELETE FROM guide_specializations WHERE guide_profile_id = $1`, guideProfileID); err != nil {
		return fmt.Errorf("delete guide specializations: %w", err)
	}

	const insertQuery = `
		INSERT INTO guide_specializations (
			id, guide_profile_id, specialization_code, created_at
		) VALUES ($1, $2, $3, $4)
	`
	for _, item := range items {
		if _, err = tx.Exec(
			ctx,
			insertQuery,
			item.ID,
			item.GuideProfileID,
			item.SpecializationCode,
			item.CreatedAt,
		); err != nil {
			return fmt.Errorf("insert guide specialization in tx: %w", err)
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}

	return nil
}

func (r *PGGuideRepository) ListGuideSpecializations(ctx context.Context, guideProfileID uuid.UUID) ([]*model.GuideSpecialization, error) {
	const query = `
		SELECT
			id, guide_profile_id, specialization_code, created_at
		FROM guide_specializations
		WHERE guide_profile_id = $1
		ORDER BY created_at ASC
	`

	rows, err := r.pool.Query(ctx, query, guideProfileID)
	if err != nil {
		return nil, fmt.Errorf("query guide specializations: %w", err)
	}
	defer rows.Close()

	var result []*model.GuideSpecialization
	for rows.Next() {
		var item model.GuideSpecialization
		if err = rows.Scan(
			&item.ID,
			&item.GuideProfileID,
			&item.SpecializationCode,
			&item.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan guide specialization: %w", err)
		}
		result = append(result, &item)
	}

	return result, rows.Err()
}

func (r *PGGuideRepository) ListGuideSpecializationsByProfileIDs(
	ctx context.Context,
	guideProfileIDs []uuid.UUID,
) (map[uuid.UUID][]*model.GuideSpecialization, error) {
	if len(guideProfileIDs) == 0 {
		return map[uuid.UUID][]*model.GuideSpecialization{}, nil
	}

	placeholders, args := uuidPlaceholders(guideProfileIDs)
	query := fmt.Sprintf(`
		SELECT
			id, guide_profile_id, specialization_code, created_at
		FROM guide_specializations
		WHERE guide_profile_id IN (%s)
		ORDER BY guide_profile_id ASC, created_at ASC
	`, placeholders)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query guide specializations by profile ids: %w", err)
	}
	defer rows.Close()

	result := make(map[uuid.UUID][]*model.GuideSpecialization, len(guideProfileIDs))
	for rows.Next() {
		var item model.GuideSpecialization
		if err = rows.Scan(
			&item.ID,
			&item.GuideProfileID,
			&item.SpecializationCode,
			&item.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan guide specialization: %w", err)
		}
		result[item.GuideProfileID] = append(result[item.GuideProfileID], &item)
	}

	return result, rows.Err()
}

func (r *PGGuideRepository) ListPublicGuideProfiles(
	ctx context.Context,
	filter port.PublicGuideListFilter,
) (port.PublicGuideListResult, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	if filter.Sort == "" {
		filter.Sort = port.PublicGuideSortRatingDesc
	}

	where, args := buildPublicGuideWhere(filter)
	whereClause := strings.Join(where, "\n\t\t\tAND ")

	countQuery := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM guide_profiles gp
		WHERE %s
	`, whereClause)

	var total int
	if err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&total); err != nil {
		return port.PublicGuideListResult{}, fmt.Errorf("count public guide profiles: %w", err)
	}
	if total == 0 {
		return port.PublicGuideListResult{Items: []*model.GuideProfile{}, Total: 0}, nil
	}

	queryArgs := append([]any{}, args...)
	limitRef := fmt.Sprintf("$%d", len(queryArgs)+1)
	queryArgs = append(queryArgs, filter.Limit)
	offsetRef := fmt.Sprintf("$%d", len(queryArgs)+1)
	queryArgs = append(queryArgs, filter.Offset)

	query := fmt.Sprintf(`
		SELECT
			gp.id, gp.user_id, gp.type, gp.status, gp.headline, gp.about, gp.experience_years,
			gp.base_city_id, gp.is_private_guide_available, gp.is_activity_host_available,
			gp.is_excursion_guide_available, gp.rating_avg, gp.reviews_count,
			gp.status_reason, gp.status_changed_at, gp.status_changed_by,
			gp.created_at, gp.updated_at
		FROM guide_profiles gp
		WHERE %s
		ORDER BY %s
		LIMIT %s OFFSET %s
	`, whereClause, publicGuideOrderBy(filter.Sort), limitRef, offsetRef)

	rows, err := r.pool.Query(ctx, query, queryArgs...)
	if err != nil {
		return port.PublicGuideListResult{}, fmt.Errorf("query public guide profiles: %w", err)
	}
	defer rows.Close()

	var result []*model.GuideProfile
	for rows.Next() {
		var (
			item      model.GuideProfile
			typeRaw   string
			statusRaw string
		)

		if err = rows.Scan(
			&item.ID,
			&item.UserID,
			&typeRaw,
			&statusRaw,
			&item.Headline,
			&item.About,
			&item.ExperienceYears,
			&item.BaseCityID,
			&item.IsPrivateGuideAvailable,
			&item.IsActivityHostAvailable,
			&item.IsExcursionGuideAvailable,
			&item.RatingAvg,
			&item.ReviewsCount,
			&item.StatusReason,
			&item.StatusChangedAt,
			&item.StatusChangedBy,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			return port.PublicGuideListResult{}, fmt.Errorf("scan public guide profile: %w", err)
		}

		item.Type = enum.GuideType(typeRaw)
		item.Status = enum.GuideStatus(statusRaw)
		result = append(result, &item)
	}

	if err = rows.Err(); err != nil {
		return port.PublicGuideListResult{}, err
	}

	return port.PublicGuideListResult{
		Items: result,
		Total: total,
	}, nil
}

func (r *PGGuideRepository) ListPublicGuideFilterOptions(
	ctx context.Context,
) (port.PublicGuideFilterOptions, error) {
	languages, err := r.listDistinctPublicGuideCodes(ctx, `
		SELECT DISTINCT LOWER(gl.language_code)
		FROM guide_languages gl
		JOIN guide_profiles gp ON gp.id = gl.guide_profile_id
		WHERE gp.status = $1
			AND TRIM(gl.language_code) <> ''
		ORDER BY 1
	`)
	if err != nil {
		return port.PublicGuideFilterOptions{}, fmt.Errorf("list public guide language options: %w", err)
	}

	specializations, err := r.listDistinctPublicGuideCodes(ctx, `
		SELECT DISTINCT LOWER(gs.specialization_code)
		FROM guide_specializations gs
		JOIN guide_profiles gp ON gp.id = gs.guide_profile_id
		WHERE gp.status = $1
			AND TRIM(gs.specialization_code) <> ''
		ORDER BY 1
	`)
	if err != nil {
		return port.PublicGuideFilterOptions{}, fmt.Errorf("list public guide specialization options: %w", err)
	}

	return port.PublicGuideFilterOptions{
		LanguageCodes:       languages,
		SpecializationCodes: specializations,
	}, nil
}

func (r *PGGuideRepository) listDistinctPublicGuideCodes(
	ctx context.Context,
	query string,
) ([]string, error) {
	rows, err := r.pool.Query(ctx, query, string(enum.GuideStatusActive))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]string, 0)
	for rows.Next() {
		var code string
		if err = rows.Scan(&code); err != nil {
			return nil, fmt.Errorf("scan public guide option code: %w", err)
		}
		code = strings.TrimSpace(strings.ToLower(code))
		if code == "" {
			continue
		}
		result = append(result, code)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}

	return result, nil
}

func buildPublicGuideWhere(filter port.PublicGuideListFilter) ([]string, []any) {
	where := []string{"gp.status = $1"}
	args := []any{string(enum.GuideStatusActive)}
	addArg := func(value any) string {
		args = append(args, value)
		return fmt.Sprintf("$%d", len(args))
	}

	if query := strings.TrimSpace(strings.ToLower(filter.Query)); query != "" {
		searchTerm := addArg("%" + query + "%")
		normalizedCodeQuery := strings.ReplaceAll(query, " ", "_")
		codeSearchTerm := searchTerm
		if normalizedCodeQuery != query {
			codeSearchTerm = addArg("%" + normalizedCodeQuery + "%")
		}
		where = append(where, fmt.Sprintf(`(
				gp.headline ILIKE %s
				OR gp.about ILIKE %s
				OR EXISTS (
					SELECT 1
					FROM guide_languages gl_search
					WHERE gl_search.guide_profile_id = gp.id
						AND LOWER(gl_search.language_code) LIKE %s
				)
				OR EXISTS (
					SELECT 1
					FROM guide_specializations gs_search
					WHERE gs_search.guide_profile_id = gp.id
						AND LOWER(gs_search.specialization_code) LIKE %s
				)
			)`, searchTerm, searchTerm, codeSearchTerm, codeSearchTerm))
	}

	if len(filter.UserIDs) > 0 {
		placeholder := addArg(filter.UserIDs)
		where = append(where, fmt.Sprintf("gp.user_id = ANY(%s)", placeholder))
	} else if len(filter.CountryCodes) > 0 {
		where = append(where, "FALSE")
	}

	if len(filter.LanguageCodes) > 0 {
		placeholder := addArg(filter.LanguageCodes)
		where = append(where, fmt.Sprintf(`EXISTS (
				SELECT 1
				FROM guide_languages gl_filter
				WHERE gl_filter.guide_profile_id = gp.id
					AND LOWER(gl_filter.language_code) = ANY(%s)
			)`, placeholder))
	}

	if len(filter.SpecializationCodes) > 0 {
		placeholder := addArg(filter.SpecializationCodes)
		where = append(where, fmt.Sprintf(`EXISTS (
				SELECT 1
				FROM guide_specializations gs_filter
				WHERE gs_filter.guide_profile_id = gp.id
					AND LOWER(gs_filter.specialization_code) = ANY(%s)
			)`, placeholder))
	}

	if filter.MinRating != nil {
		where = append(where, fmt.Sprintf("gp.rating_avg >= %s", addArg(*filter.MinRating)))
	}

	if filter.MinExperienceYears != nil {
		where = append(where, fmt.Sprintf("gp.experience_years >= %s", addArg(*filter.MinExperienceYears)))
	}

	return where, args
}

func publicGuideOrderBy(sort port.PublicGuideSort) string {
	switch sort {
	case port.PublicGuideSortRatingAsc:
		return "gp.rating_avg ASC, gp.reviews_count DESC, gp.created_at DESC, gp.id ASC"
	case port.PublicGuideSortExperienceDesc:
		return "gp.experience_years DESC, gp.rating_avg DESC, gp.reviews_count DESC, gp.id ASC"
	case port.PublicGuideSortExperienceAsc:
		return "gp.experience_years ASC, gp.rating_avg DESC, gp.reviews_count DESC, gp.id ASC"
	case port.PublicGuideSortNewestDesc:
		return "gp.created_at DESC, gp.id ASC"
	case port.PublicGuideSortNewestAsc:
		return "gp.created_at ASC, gp.id ASC"
	default:
		return "gp.rating_avg DESC, gp.reviews_count DESC, gp.created_at DESC, gp.id ASC"
	}
}

func uuidPlaceholders(ids []uuid.UUID) (string, []any) {
	placeholders := make([]string, 0, len(ids))
	args := make([]any, 0, len(ids))
	for _, id := range ids {
		placeholders = append(placeholders, fmt.Sprintf("$%d", len(args)+1))
		args = append(args, id)
	}
	return strings.Join(placeholders, ", "), args
}

func (r *PGGuideRepository) ListVerificationRequestsByStatuses(
	ctx context.Context,
	statuses []enum.VerificationRequestStatus,
	limit int,
	offset int,
) ([]*model.GuideVerificationRequest, error) {
	if len(statuses) == 0 {
		statuses = []enum.VerificationRequestStatus{
			enum.VerificationRequestStatusSubmitted,
			enum.VerificationRequestStatusUnderReview,
		}
	}

	rawStatuses := make([]string, 0, len(statuses))
	for _, s := range statuses {
		rawStatuses = append(rawStatuses, string(s))
	}

	const query = `
		SELECT
			id, guide_profile_id, status, comment, review_comment,
			submitted_at, reviewed_at, reviewed_by, created_at, updated_at
		FROM guide_verification_requests
		WHERE status = ANY($1)
		ORDER BY created_at ASC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.pool.Query(ctx, query, rawStatuses, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("query verification requests by statuses: %w", err)
	}
	defer rows.Close()

	var result []*model.GuideVerificationRequest
	for rows.Next() {
		var (
			item      model.GuideVerificationRequest
			statusRaw string
		)

		if err = rows.Scan(
			&item.ID,
			&item.GuideProfileID,
			&statusRaw,
			&item.Comment,
			&item.ReviewComment,
			&item.SubmittedAt,
			&item.ReviewedAt,
			&item.ReviewedBy,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan verification request queue item: %w", err)
		}

		item.Status = enum.VerificationRequestStatus(statusRaw)
		result = append(result, &item)
	}

	return result, rows.Err()
}
