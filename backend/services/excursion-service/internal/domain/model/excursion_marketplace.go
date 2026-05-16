package model

import (
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
)

type ExcursionProductCard struct {
	ID           uuid.UUID
	CanonicalKey string

	LandmarkID   *uuid.UUID
	LandmarkName *string

	Title        string
	Summary      string
	Description  string
	Translations ExcursionTranslations
	CategorySlug string

	Status     enum.ExcursionStatus
	Visibility enum.ExcursionVisibility

	DurationMinutes int
	CountryCode     *string
	CityName        *string
	Latitude        *float64
	Longitude       *float64
	MapURL          *string
	CoverFileID     *uuid.UUID

	MinPriceAmount       *float64
	Currency             *string
	OffersCount          int
	PublishedOffersCount int
	NextAvailableAt      *time.Time

	CreatedAt time.Time
	UpdatedAt time.Time
}

type ExcursionOffer struct {
	ID                uuid.UUID
	ProductID         uuid.UUID
	LegacyExcursionID *uuid.UUID

	GuideProfileID       uuid.UUID
	GuideUserID          uuid.UUID
	GuideRatingAvg       float64
	GuideReviewsCount    int
	GuideExperienceYears int
	GuideDisplayName     string
	GuideSearchText      string

	Title        string
	Summary      string
	Description  string
	Translations ExcursionTranslations

	Status     enum.ExcursionStatus
	Visibility enum.ExcursionVisibility

	DurationMinutes int
	MaxGroupSize    int
	MeetingPoint    string
	Latitude        *float64
	Longitude       *float64
	MapURL          *string

	PriceAmount float64
	Currency    string
	CoverFileID *uuid.UUID

	PublishedAt *time.Time
	DeletedAt   *time.Time
	Revision    int
	CreatedAt   time.Time
	UpdatedAt   time.Time
}
