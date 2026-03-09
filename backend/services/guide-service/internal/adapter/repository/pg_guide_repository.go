package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/model"
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
			is_tour_guide_available, rating_avg, reviews_count, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7,
			$8, $9, $10,
			$11, $12, $13, $14, $15
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
		profile.IsTourGuideAvailable,
		profile.RatingAvg,
		profile.ReviewsCount,
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
			is_tour_guide_available, rating_avg, reviews_count, created_at, updated_at
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
		&item.IsTourGuideAvailable,
		&item.RatingAvg,
		&item.ReviewsCount,
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
			is_tour_guide_available, rating_avg, reviews_count, created_at, updated_at
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
		&item.IsTourGuideAvailable,
		&item.RatingAvg,
		&item.ReviewsCount,
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
			is_tour_guide_available = $10,
			rating_avg = $11,
			reviews_count = $12,
			updated_at = $13
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
		profile.IsTourGuideAvailable,
		profile.RatingAvg,
		profile.ReviewsCount,
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

func (r *PGGuideRepository) ListPublicGuideProfiles(ctx context.Context, limit int, offset int) ([]*model.GuideProfile, error) {
	const query = `
		SELECT
			id, user_id, type, status, headline, about, experience_years,
			base_city_id, is_private_guide_available, is_activity_host_available,
			is_tour_guide_available, rating_avg, reviews_count, created_at, updated_at
		FROM guide_profiles
		WHERE status = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.pool.Query(ctx, query, string(enum.GuideStatusActive), limit, offset)
	if err != nil {
		return nil, fmt.Errorf("query public guide profiles: %w", err)
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
			&item.IsTourGuideAvailable,
			&item.RatingAvg,
			&item.ReviewsCount,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan public guide profile: %w", err)
		}

		item.Type = enum.GuideType(typeRaw)
		item.Status = enum.GuideStatus(statusRaw)
		result = append(result, &item)
	}

	return result, rows.Err()
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
