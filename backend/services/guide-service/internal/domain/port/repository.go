package port

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/model"
)

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

	AddGuideSpecialization(ctx context.Context, specialization *model.GuideSpecialization) error
	ReplaceGuideSpecializations(ctx context.Context, guideProfileID uuid.UUID, items []*model.GuideSpecialization) error
	ListGuideSpecializations(ctx context.Context, guideProfileID uuid.UUID) ([]*model.GuideSpecialization, error)

	ListPublicGuideProfiles(ctx context.Context, limit int, offset int) ([]*model.GuideProfile, error)

	ListVerificationRequestsByStatuses(
		ctx context.Context,
		statuses []enum.VerificationRequestStatus,
		limit int,
		offset int,
	) ([]*model.GuideVerificationRequest, error)
}
