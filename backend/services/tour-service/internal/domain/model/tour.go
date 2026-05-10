package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
)

var (
	ErrInvalidTourID          = errors.New("invalid tour id")
	ErrInvalidGuideProfileID  = errors.New("invalid guide profile id")
	ErrInvalidGuideUserID     = errors.New("invalid guide user id")
	ErrInvalidTourTitle       = errors.New("invalid tour title")
	ErrInvalidTourSummary     = errors.New("invalid tour summary")
	ErrInvalidTourDescription = errors.New("invalid tour description")
	ErrInvalidTourCategory    = errors.New("invalid tour category")
	ErrInvalidTourStatus      = errors.New("invalid tour status")
	ErrInvalidTourVisibility  = errors.New("invalid tour visibility")
	ErrInvalidTourDuration    = errors.New("invalid tour duration")
	ErrInvalidTourGroupSize   = errors.New("invalid tour group size")
	ErrInvalidTourMeeting     = errors.New("invalid tour meeting point")
	ErrInvalidTourPrice       = errors.New("invalid tour price")
	ErrInvalidTourCurrency    = errors.New("invalid tour currency")
	ErrTourLanguageRequired   = errors.New("tour language is required")
	ErrTourItineraryRequired  = errors.New("tour itinerary is required")
	ErrTourAlreadyArchived    = errors.New("tour already archived")
)

const (
	minTourTitleLength       = 3
	maxTourTitleLength       = 160
	minTourSummaryLength     = 3
	maxTourSummaryLength     = 240
	minTourDescriptionLength = 20
	maxTourDurationMinutes   = 30 * 24 * 60
	minTourDurationMinutes   = 15
	minTourGroupSize         = 1
	maxTourGroupSize         = 100
	maxTourPrice             = 1000000
)

type Tour struct {
	ID             uuid.UUID
	GuideProfileID uuid.UUID
	GuideUserID    uuid.UUID

	LandmarkID   *uuid.UUID
	LandmarkName *string

	Title        string
	Summary      string
	Description  string
	CategorySlug string

	Status     enum.TourStatus
	Visibility enum.TourVisibility

	DurationMinutes int
	MaxGroupSize    int

	CountryCode  *string
	CityName     *string
	MeetingPoint string
	Latitude     *float64
	Longitude    *float64
	MapURL       *string

	PriceAmount float64
	Currency    string

	PublishedAt *time.Time
	DeletedAt   *time.Time
	Revision    int
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type NewTourParams struct {
	GuideProfileID uuid.UUID
	GuideUserID    uuid.UUID
	LandmarkID     *uuid.UUID
	LandmarkName   *string
	Title          string
	Summary        string
	Description    string
	CategorySlug   string
	Visibility     enum.TourVisibility

	DurationMinutes int
	MaxGroupSize    int

	CountryCode  *string
	CityName     *string
	MeetingPoint string
	Latitude     *float64
	Longitude    *float64
	MapURL       *string

	PriceAmount float64
	Currency    string
}

func NewTour(params NewTourParams) (*Tour, error) {
	now := time.Now().UTC()
	visibility := params.Visibility
	if strings.TrimSpace(string(visibility)) == "" {
		visibility = enum.TourVisibilityPublic
	}

	item := &Tour{
		ID:              uuid.New(),
		GuideProfileID:  params.GuideProfileID,
		GuideUserID:     params.GuideUserID,
		LandmarkID:      params.LandmarkID,
		LandmarkName:    NormalizeOptionalString(params.LandmarkName),
		Title:           strings.TrimSpace(params.Title),
		Summary:         strings.TrimSpace(params.Summary),
		Description:     strings.TrimSpace(params.Description),
		CategorySlug:    NormalizeSlug(params.CategorySlug),
		Status:          enum.TourStatusDraft,
		Visibility:      visibility,
		DurationMinutes: params.DurationMinutes,
		MaxGroupSize:    params.MaxGroupSize,
		CountryCode:     NormalizeOptionalString(params.CountryCode),
		CityName:        NormalizeOptionalString(params.CityName),
		MeetingPoint:    strings.TrimSpace(params.MeetingPoint),
		Latitude:        params.Latitude,
		Longitude:       params.Longitude,
		MapURL:          NormalizeOptionalString(params.MapURL),
		PriceAmount:     params.PriceAmount,
		Currency:        strings.ToUpper(strings.TrimSpace(params.Currency)),
		Revision:        1,
		CreatedAt:       now,
		UpdatedAt:       now,
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

type UpdateTourParams struct {
	LandmarkID   *uuid.UUID
	LandmarkName *string
	Title        string
	Summary      string
	Description  string
	CategorySlug string
	Visibility   enum.TourVisibility

	DurationMinutes int
	MaxGroupSize    int

	CountryCode  *string
	CityName     *string
	MeetingPoint string
	Latitude     *float64
	Longitude    *float64
	MapURL       *string

	PriceAmount float64
	Currency    string
}

func (t *Tour) ApplyUpdate(params UpdateTourParams) error {
	if t.Status == enum.TourStatusArchived || t.DeletedAt != nil {
		return ErrTourAlreadyArchived
	}

	t.LandmarkID = params.LandmarkID
	t.LandmarkName = NormalizeOptionalString(params.LandmarkName)
	t.Title = strings.TrimSpace(params.Title)
	t.Summary = strings.TrimSpace(params.Summary)
	t.Description = strings.TrimSpace(params.Description)
	t.CategorySlug = NormalizeSlug(params.CategorySlug)
	if strings.TrimSpace(string(params.Visibility)) == "" {
		t.Visibility = enum.TourVisibilityPublic
	} else {
		t.Visibility = params.Visibility
	}
	t.DurationMinutes = params.DurationMinutes
	t.MaxGroupSize = params.MaxGroupSize
	t.CountryCode = NormalizeOptionalString(params.CountryCode)
	t.CityName = NormalizeOptionalString(params.CityName)
	t.MeetingPoint = strings.TrimSpace(params.MeetingPoint)
	t.Latitude = params.Latitude
	t.Longitude = params.Longitude
	t.MapURL = NormalizeOptionalString(params.MapURL)
	t.PriceAmount = params.PriceAmount
	t.Currency = strings.ToUpper(strings.TrimSpace(params.Currency))
	t.Revision++
	t.UpdatedAt = time.Now().UTC()

	return t.Validate()
}

func (t *Tour) Validate() error {
	if t.ID == uuid.Nil {
		return ErrInvalidTourID
	}
	if t.GuideProfileID == uuid.Nil {
		return ErrInvalidGuideProfileID
	}
	if t.GuideUserID == uuid.Nil {
		return ErrInvalidGuideUserID
	}
	titleLen := len(strings.TrimSpace(t.Title))
	if titleLen < minTourTitleLength || titleLen > maxTourTitleLength {
		return ErrInvalidTourTitle
	}
	summaryLen := len(strings.TrimSpace(t.Summary))
	if summaryLen < minTourSummaryLength || summaryLen > maxTourSummaryLength {
		return ErrInvalidTourSummary
	}
	if len(strings.TrimSpace(t.Description)) < minTourDescriptionLength {
		return ErrInvalidTourDescription
	}
	if strings.TrimSpace(t.CategorySlug) == "" {
		return ErrInvalidTourCategory
	}
	if !t.Status.IsValid() {
		return ErrInvalidTourStatus
	}
	if !t.Visibility.IsValid() {
		return ErrInvalidTourVisibility
	}
	if t.DurationMinutes < minTourDurationMinutes || t.DurationMinutes > maxTourDurationMinutes {
		return ErrInvalidTourDuration
	}
	if t.MaxGroupSize < minTourGroupSize || t.MaxGroupSize > maxTourGroupSize {
		return ErrInvalidTourGroupSize
	}
	if strings.TrimSpace(t.MeetingPoint) == "" {
		return ErrInvalidTourMeeting
	}
	if t.PriceAmount < 0 || t.PriceAmount > maxTourPrice {
		return ErrInvalidTourPrice
	}
	if strings.TrimSpace(t.Currency) == "" {
		return ErrInvalidTourCurrency
	}

	return nil
}

type PublishTourParams struct {
	LanguageCodes []string
	Itinerary     []*TourItineraryItem
}

func (t *Tour) ValidatePublishable(params PublishTourParams) error {
	if err := t.Validate(); err != nil {
		return err
	}
	if len(normalizeLanguageCodes(params.LanguageCodes)) == 0 {
		return ErrTourLanguageRequired
	}
	if len(params.Itinerary) == 0 {
		return ErrTourItineraryRequired
	}

	for _, item := range params.Itinerary {
		if item == nil {
			return ErrTourItineraryRequired
		}
		candidate := *item
		if candidate.TourID != t.ID {
			candidate.TourID = t.ID
		}
		if err := candidate.Validate(); err != nil {
			return err
		}
	}

	return nil
}

func (t *Tour) Publish(params PublishTourParams) error {
	if t.Status == enum.TourStatusArchived || t.DeletedAt != nil {
		return ErrTourAlreadyArchived
	}
	if err := t.ValidatePublishable(params); err != nil {
		return err
	}
	if t.Status == enum.TourStatusPublished && t.PublishedAt != nil {
		return nil
	}

	now := time.Now().UTC()
	t.Status = enum.TourStatusPublished
	t.PublishedAt = &now
	t.DeletedAt = nil
	t.Revision++
	t.UpdatedAt = now
	return nil
}

func (t *Tour) Archive() error {
	if t.Status == enum.TourStatusArchived && t.DeletedAt != nil {
		return ErrTourAlreadyArchived
	}
	now := time.Now().UTC()
	t.Status = enum.TourStatusArchived
	t.DeletedAt = &now
	t.Revision++
	t.UpdatedAt = now
	return nil
}

func (t *Tour) IsPublished() bool {
	return t.Status == enum.TourStatusPublished && t.DeletedAt == nil
}

func (t *Tour) IsPubliclyReadable() bool {
	return t.IsPublished() && t.Visibility != enum.TourVisibilityPrivate
}

func (t *Tour) IsOwnedBy(userID uuid.UUID) bool {
	return userID != uuid.Nil && t.GuideUserID == userID
}

func normalizeLanguageCodes(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		code := strings.ToLower(strings.TrimSpace(value))
		if code == "" {
			continue
		}
		if _, ok := seen[code]; ok {
			continue
		}
		seen[code] = struct{}{}
		result = append(result, code)
	}
	return result
}
