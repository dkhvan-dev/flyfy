package model

import (
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
)

type TourProductCard struct {
	ID           uuid.UUID
	CanonicalKey string

	LandmarkID   *uuid.UUID
	LandmarkName *string

	Title        string
	Summary      string
	Description  string
	Translations TourTranslations
	CategorySlug string

	Status     enum.TourStatus
	Visibility enum.TourVisibility

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

type TourOffer struct {
	ID           uuid.UUID
	ProductID    uuid.UUID
	LegacyTourID *uuid.UUID

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
	Translations TourTranslations

	Status     enum.TourStatus
	Visibility enum.TourVisibility

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
