package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
)

type PublicGuideSort string

const (
	PublicGuideSortRatingDesc     PublicGuideSort = "rating_desc"
	PublicGuideSortRatingAsc      PublicGuideSort = "rating_asc"
	PublicGuideSortExperienceDesc PublicGuideSort = "experience_desc"
	PublicGuideSortExperienceAsc  PublicGuideSort = "experience_asc"
	PublicGuideSortNewestDesc     PublicGuideSort = "newest_desc"
	PublicGuideSortNewestAsc      PublicGuideSort = "newest_asc"
)

type PublicGuideListFilter struct {
	Query               string
	CountryCodes        []string
	UserIDs             []uuid.UUID
	LanguageCodes       []string
	SpecializationCodes []string
	MinRating           *float64
	MinExperienceYears  *int
	Sort                PublicGuideSort
	Limit               int
	Offset              int
}

type PublicGuideListResult struct {
	Items []*model.GuideProfile
	Total int
}

type PublicGuideFilterOptions struct {
	LanguageCodes       []string
	SpecializationCodes []string
}

type GuideRepository interface {
	CreateGuideProfile(ctx context.Context, profile *model.GuideProfile) error
	GetGuideProfileByID(ctx context.Context, id uuid.UUID) (*model.GuideProfile, error)
	GetGuideProfileByUserID(ctx context.Context, userID uuid.UUID) (*model.GuideProfile, error)
	UpdateGuideProfile(ctx context.Context, profile *model.GuideProfile) error
	UpdateGuideRatingSnapshot(ctx context.Context, guideProfileID uuid.UUID, ratingAvg float64, reviewsCount int) error

	CreateVerificationRequest(ctx context.Context, req *model.GuideVerificationRequest) error
	GetVerificationRequestByID(ctx context.Context, id uuid.UUID) (*model.GuideVerificationRequest, error)
	GetLatestVerificationRequestByGuideProfileID(ctx context.Context, guideProfileID uuid.UUID) (*model.GuideVerificationRequest, error)
	UpdateVerificationRequest(ctx context.Context, req *model.GuideVerificationRequest) error

	AddGuideDocument(ctx context.Context, doc *model.GuideDocument) error
	ListGuideDocumentsByVerificationRequestID(ctx context.Context, verificationRequestID uuid.UUID) ([]*model.GuideDocument, error)

	AddGuideLanguage(ctx context.Context, language *model.GuideLanguage) error
	ReplaceGuideLanguages(ctx context.Context, guideProfileID uuid.UUID, items []*model.GuideLanguage) error
	ListGuideLanguages(ctx context.Context, guideProfileID uuid.UUID) ([]*model.GuideLanguage, error)
	ListGuideLanguagesByProfileIDs(ctx context.Context, guideProfileIDs []uuid.UUID) (map[uuid.UUID][]*model.GuideLanguage, error)

	AddGuideSpecialization(ctx context.Context, specialization *model.GuideSpecialization) error
	ReplaceGuideSpecializations(ctx context.Context, guideProfileID uuid.UUID, items []*model.GuideSpecialization) error
	ListGuideSpecializations(ctx context.Context, guideProfileID uuid.UUID) ([]*model.GuideSpecialization, error)
	ListGuideSpecializationsByProfileIDs(ctx context.Context, guideProfileIDs []uuid.UUID) (map[uuid.UUID][]*model.GuideSpecialization, error)

	ListPublicGuideProfiles(ctx context.Context, filter PublicGuideListFilter) (PublicGuideListResult, error)
	ListPublicGuideFilterOptions(ctx context.Context) (PublicGuideFilterOptions, error)

	ListVerificationRequestsByStatuses(
		ctx context.Context,
		statuses []enum.VerificationRequestStatus,
		limit int,
		offset int,
	) ([]*model.GuideVerificationRequest, error)
}

// SavedSourceRepository is intentionally narrower than GuideRepository so the
// Saved resolver cannot access verification documents or mutable Saved state.
type SavedSourceRepository interface {
	GetSavedSourceGuide(
		ctx context.Context,
		userID uuid.UUID,
	) (*model.SavedGuideSnapshot, error)
}

type SavedLifecycleOutboxRepository interface {
	ClaimSavedLifecycleOutbox(
		ctx context.Context,
		now time.Time,
		limit int,
		leaseDuration time.Duration,
	) ([]*model.SavedLifecycleOutboxMessage, error)
	MarkSavedLifecycleDelivered(
		ctx context.Context,
		eventID uuid.UUID,
		leaseToken uuid.UUID,
		deliveredAt time.Time,
		retention time.Duration,
	) error
	MarkSavedLifecycleFailed(
		ctx context.Context,
		eventID uuid.UUID,
		leaseToken uuid.UUID,
		failedAt time.Time,
		nextAttemptAt time.Time,
		errorCode string,
		dead bool,
		retention time.Duration,
	) error
	DeleteSavedLifecycleTerminal(ctx context.Context, now time.Time, limit int) (int64, error)
}

type SavedGuideUserReconciliationRepository interface {
	ClaimSavedGuideUserReconciliations(
		ctx context.Context,
		now time.Time,
		limit int,
		leaseDuration time.Duration,
	) ([]*model.SavedGuideUserReconcileLease, error)
	ApplySavedGuideExternalUserState(
		ctx context.Context,
		lease model.SavedGuideUserReconcileLease,
		state model.SavedGuideExternalUserState,
		nextReconcileAt time.Time,
	) error
	MarkSavedGuideUserReconcileFailed(
		ctx context.Context,
		lease model.SavedGuideUserReconcileLease,
		nextAttemptAt time.Time,
	) error
}
