package port

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/model"
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

type GuideRepository interface {
	CreateGuideProfile(ctx context.Context, profile *model.GuideProfile) error
	GetGuideProfileByID(ctx context.Context, id uuid.UUID) (*model.GuideProfile, error)
	GetGuideProfileByUserID(ctx context.Context, userID uuid.UUID) (*model.GuideProfile, error)
	UpdateGuideProfile(ctx context.Context, profile *model.GuideProfile) error

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

	ListVerificationRequestsByStatuses(
		ctx context.Context,
		statuses []enum.VerificationRequestStatus,
		limit int,
		offset int,
	) ([]*model.GuideVerificationRequest, error)
}
