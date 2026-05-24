package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/enum"
)

var (
	ErrInvalidGuideProfileID         = errors.New("invalid guide profile id")
	ErrInvalidGuideProfileUserID     = errors.New("invalid guide profile user id")
	ErrInvalidGuideType              = errors.New("invalid guide type")
	ErrInvalidGuideStatus            = errors.New("invalid guide status")
	ErrInvalidExperienceYears        = errors.New("invalid experience years")
	ErrInvalidReviewsCount           = errors.New("invalid reviews count")
	ErrInvalidRatingAverage          = errors.New("invalid rating average")
	ErrGuideRevocationReasonRequired = errors.New("guide revocation reason is required")
)

type GuideProfile struct {
	ID                        uuid.UUID
	UserID                    uuid.UUID
	Type                      enum.GuideType
	Status                    enum.GuideStatus
	Headline                  *string
	About                     *string
	ExperienceYears           int
	BaseCityID                *uuid.UUID
	IsPrivateGuideAvailable   bool
	IsActivityHostAvailable   bool
	IsExcursionGuideAvailable bool
	RatingAvg                 float64
	ReviewsCount              int
	StatusReason              *string
	StatusChangedAt           *time.Time
	StatusChangedBy           *uuid.UUID
	CreatedAt                 time.Time
	UpdatedAt                 time.Time
}

type NewGuideProfileParams struct {
	UserID uuid.UUID
	Type   enum.GuideType
}

func NewGuideProfile(params NewGuideProfileParams) (*GuideProfile, error) {
	now := time.Now().UTC()

	profile := &GuideProfile{
		ID:                        uuid.New(),
		UserID:                    params.UserID,
		Type:                      params.Type,
		Status:                    enum.GuideStatusDraft,
		ExperienceYears:           0,
		IsPrivateGuideAvailable:   false,
		IsActivityHostAvailable:   false,
		IsExcursionGuideAvailable: false,
		RatingAvg:                 0,
		ReviewsCount:              0,
		CreatedAt:                 now,
		UpdatedAt:                 now,
	}

	if err := profile.Validate(); err != nil {
		return nil, err
	}

	return profile, nil
}

func (g *GuideProfile) Validate() error {
	if g.ID == uuid.Nil {
		return ErrInvalidGuideProfileID
	}
	if g.UserID == uuid.Nil {
		return ErrInvalidGuideProfileUserID
	}
	if !g.Type.IsValid() {
		return ErrInvalidGuideType
	}
	if !g.Status.IsValid() {
		return ErrInvalidGuideStatus
	}
	if g.ExperienceYears < 0 {
		return ErrInvalidExperienceYears
	}
	if g.ReviewsCount < 0 {
		return ErrInvalidReviewsCount
	}
	if g.RatingAvg < 0 || g.RatingAvg > 5 {
		return ErrInvalidRatingAverage
	}
	return nil
}

type UpdateGuideProfileParams struct {
	Headline                  *string
	About                     *string
	ExperienceYears           *int
	BaseCityID                *uuid.UUID
	IsPrivateGuideAvailable   *bool
	IsActivityHostAvailable   *bool
	IsExcursionGuideAvailable *bool
}

func (g *GuideProfile) ApplyUpdate(params UpdateGuideProfileParams) error {
	if g.ID == uuid.Nil {
		return ErrInvalidGuideProfileID
	}

	g.Headline = normalizeOptionalString(params.Headline)
	g.About = normalizeOptionalString(params.About)

	if params.ExperienceYears != nil {
		g.ExperienceYears = *params.ExperienceYears
	}
	g.BaseCityID = params.BaseCityID

	if params.IsPrivateGuideAvailable != nil {
		g.IsPrivateGuideAvailable = *params.IsPrivateGuideAvailable
	}
	if params.IsActivityHostAvailable != nil {
		g.IsActivityHostAvailable = *params.IsActivityHostAvailable
	}
	if params.IsExcursionGuideAvailable != nil {
		g.IsExcursionGuideAvailable = *params.IsExcursionGuideAvailable
	}

	g.UpdatedAt = time.Now().UTC()
	return g.Validate()
}

func (g *GuideProfile) SubmitForReview() error {
	if g.ID == uuid.Nil {
		return ErrInvalidGuideProfileID
	}
	g.Status = enum.GuideStatusPendingReview
	g.UpdatedAt = time.Now().UTC()
	return g.Validate()
}

func (g *GuideProfile) Activate() error {
	if g.ID == uuid.Nil {
		return ErrInvalidGuideProfileID
	}
	g.Status = enum.GuideStatusActive
	g.StatusReason = nil
	g.StatusChangedAt = nil
	g.StatusChangedBy = nil
	g.UpdatedAt = time.Now().UTC()
	return g.Validate()
}

func (g *GuideProfile) Reject() error {
	if g.ID == uuid.Nil {
		return ErrInvalidGuideProfileID
	}
	g.Status = enum.GuideStatusRejected
	g.UpdatedAt = time.Now().UTC()
	return g.Validate()
}

func (g *GuideProfile) Revoke(reason string, revokedBy *uuid.UUID) error {
	if g.ID == uuid.Nil {
		return ErrInvalidGuideProfileID
	}
	reason = strings.Join(strings.Fields(strings.TrimSpace(reason)), " ")
	if reason == "" {
		return ErrGuideRevocationReasonRequired
	}
	now := time.Now().UTC()
	g.Status = enum.GuideStatusRevoked
	g.StatusReason = &reason
	g.StatusChangedAt = &now
	g.StatusChangedBy = nil
	if revokedBy != nil && *revokedBy != uuid.Nil {
		g.StatusChangedBy = revokedBy
	}
	g.IsPrivateGuideAvailable = false
	g.IsActivityHostAvailable = false
	g.IsExcursionGuideAvailable = false
	g.UpdatedAt = now
	return g.Validate()
}
