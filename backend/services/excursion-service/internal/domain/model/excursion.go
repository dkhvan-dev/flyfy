package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
)

var (
	ErrInvalidExcursionID                  = errors.New("invalid excursion id")
	ErrInvalidGuideProfileID               = errors.New("invalid guide profile id")
	ErrInvalidGuideUserID                  = errors.New("invalid guide user id")
	ErrInvalidExcursionTitle               = errors.New("invalid excursion title")
	ErrInvalidExcursionSummary             = errors.New("invalid excursion summary")
	ErrInvalidExcursionDescription         = errors.New("invalid excursion description")
	ErrInvalidExcursionCategory            = errors.New("invalid excursion category")
	ErrInvalidExcursionStatus              = errors.New("invalid excursion status")
	ErrInvalidExcursionVisibility          = errors.New("invalid excursion visibility")
	ErrInvalidExcursionDuration            = errors.New("invalid excursion duration")
	ErrInvalidExcursionGroupSize           = errors.New("invalid excursion group size")
	ErrInvalidExcursionMeeting             = errors.New("invalid excursion meeting point")
	ErrInvalidExcursionLocation            = errors.New("invalid excursion location")
	ErrInvalidExcursionPrice               = errors.New("invalid excursion price")
	ErrInvalidExcursionCurrency            = errors.New("invalid excursion currency")
	ErrExcursionLanguageRequired           = errors.New("excursion language is required")
	ErrExcursionItineraryRequired          = errors.New("excursion itinerary is required")
	ErrExcursionAlreadyArchived            = errors.New("excursion already archived")
	ErrExcursionGuideLandmarkAlreadyExists = errors.New("excursion already exists for this guide and attraction")
)

const (
	minExcursionTitleLength       = 3
	maxExcursionTitleLength       = 160
	minExcursionSummaryLength     = 3
	maxExcursionSummaryLength     = 240
	minExcursionDescriptionLength = 20
	maxExcursionDescriptionLength = 5000
	maxExcursionDurationMinutes   = 30 * 24 * 60
	minExcursionDurationMinutes   = 15
	minExcursionGroupSize         = 1
	maxExcursionGroupSize         = 100
	maxExcursionPrice             = 1000000
)

type ExcursionLocalizedCopy struct {
	Title       string `json:"title,omitempty"`
	Summary     string `json:"summary,omitempty"`
	Description string `json:"description,omitempty"`
}

type ExcursionTranslations map[string]ExcursionLocalizedCopy

type Excursion struct {
	ID                   uuid.UUID
	GuideProfileID       uuid.UUID
	GuideUserID          uuid.UUID
	GuideRatingAvg       float64
	GuideReviewsCount    int
	GuideExperienceYears int
	GuideDisplayName     string
	GuideSearchText      string

	LandmarkID   *uuid.UUID
	LandmarkName *string

	Title               string
	Summary             string
	Description         string
	Translations        ExcursionTranslations
	CategorySlug        string
	ProductTranslations ExcursionTranslations

	Status     enum.ExcursionStatus
	Visibility enum.ExcursionVisibility

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

type NewExcursionParams struct {
	GuideProfileID       uuid.UUID
	GuideUserID          uuid.UUID
	GuideRatingAvg       float64
	GuideReviewsCount    int
	GuideExperienceYears int
	GuideDisplayName     string
	GuideSearchText      string
	LandmarkID           *uuid.UUID
	LandmarkName         *string
	Title                string
	Summary              string
	Description          string
	Translations         ExcursionTranslations
	CategorySlug         string
	ProductTranslations  ExcursionTranslations
	Visibility           enum.ExcursionVisibility

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

func NewExcursion(params NewExcursionParams) (*Excursion, error) {
	now := time.Now().UTC()
	visibility := params.Visibility
	if strings.TrimSpace(string(visibility)) == "" {
		visibility = enum.ExcursionVisibilityPublic
	}

	item := &Excursion{
		ID:                   uuid.New(),
		GuideProfileID:       params.GuideProfileID,
		GuideUserID:          params.GuideUserID,
		GuideRatingAvg:       normalizeGuideRatingAvg(params.GuideRatingAvg),
		GuideReviewsCount:    normalizeNonNegativeInt(params.GuideReviewsCount),
		GuideExperienceYears: normalizeNonNegativeInt(params.GuideExperienceYears),
		GuideDisplayName:     normalizeGuideSnapshotText(params.GuideDisplayName),
		GuideSearchText:      normalizeGuideSnapshotText(params.GuideSearchText),
		LandmarkID:           params.LandmarkID,
		LandmarkName:         NormalizeOptionalString(params.LandmarkName),
		Title:                strings.TrimSpace(params.Title),
		Summary:              strings.TrimSpace(params.Summary),
		Description:          strings.TrimSpace(params.Description),
		Translations:         NormalizeExcursionTranslations(params.Translations),
		CategorySlug:         NormalizeSlug(params.CategorySlug),
		ProductTranslations:  NormalizeExcursionTranslations(params.ProductTranslations),
		Status:               enum.ExcursionStatusDraft,
		Visibility:           visibility,
		DurationMinutes:      params.DurationMinutes,
		MaxGroupSize:         params.MaxGroupSize,
		CountryCode:          NormalizeOptionalString(params.CountryCode),
		CityName:             NormalizeOptionalString(params.CityName),
		MeetingPoint:         strings.TrimSpace(params.MeetingPoint),
		Latitude:             params.Latitude,
		Longitude:            params.Longitude,
		MapURL:               NormalizeOptionalString(params.MapURL),
		PriceAmount:          params.PriceAmount,
		Currency:             strings.ToUpper(strings.TrimSpace(params.Currency)),
		Revision:             1,
		CreatedAt:            now,
		UpdatedAt:            now,
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

type UpdateExcursionParams struct {
	LandmarkID          *uuid.UUID
	LandmarkName        *string
	Title               string
	Summary             string
	Description         string
	Translations        ExcursionTranslations
	CategorySlug        string
	ProductTranslations ExcursionTranslations
	Visibility          enum.ExcursionVisibility

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

func (t *Excursion) ApplyUpdate(params UpdateExcursionParams) error {
	if t.DeletedAt != nil {
		return ErrExcursionAlreadyArchived
	}

	t.LandmarkID = params.LandmarkID
	t.LandmarkName = NormalizeOptionalString(params.LandmarkName)
	t.Title = strings.TrimSpace(params.Title)
	t.Summary = strings.TrimSpace(params.Summary)
	t.Description = strings.TrimSpace(params.Description)
	t.Translations = NormalizeExcursionTranslations(params.Translations)
	t.CategorySlug = NormalizeSlug(params.CategorySlug)
	t.ProductTranslations = NormalizeExcursionTranslations(params.ProductTranslations)
	if strings.TrimSpace(string(params.Visibility)) == "" {
		t.Visibility = enum.ExcursionVisibilityPublic
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

func (t *Excursion) ApplyGuideSnapshot(
	ratingAvg float64,
	reviewsCount int,
	experienceYears int,
	displayName string,
	searchText string,
) {
	t.GuideRatingAvg = normalizeGuideRatingAvg(ratingAvg)
	t.GuideReviewsCount = normalizeNonNegativeInt(reviewsCount)
	t.GuideExperienceYears = normalizeNonNegativeInt(experienceYears)
	t.GuideDisplayName = normalizeGuideSnapshotText(displayName)
	t.GuideSearchText = normalizeGuideSnapshotText(searchText)
}

func (t *Excursion) Validate() error {
	if t.ID == uuid.Nil {
		return ErrInvalidExcursionID
	}
	if t.GuideProfileID == uuid.Nil {
		return ErrInvalidGuideProfileID
	}
	if t.GuideUserID == uuid.Nil {
		return ErrInvalidGuideUserID
	}
	titleLen := len(strings.TrimSpace(t.Title))
	if titleLen < minExcursionTitleLength || titleLen > maxExcursionTitleLength {
		return ErrInvalidExcursionTitle
	}
	summaryLen := len(strings.TrimSpace(t.Summary))
	if summaryLen < minExcursionSummaryLength || summaryLen > maxExcursionSummaryLength {
		return ErrInvalidExcursionSummary
	}
	if len(strings.TrimSpace(t.Description)) < minExcursionDescriptionLength {
		return ErrInvalidExcursionDescription
	}
	if err := validateExcursionTranslations(t.Translations); err != nil {
		return err
	}
	if err := validateExcursionTranslations(t.ProductTranslations); err != nil {
		return err
	}
	if strings.TrimSpace(t.CategorySlug) == "" {
		return ErrInvalidExcursionCategory
	}
	if !t.Status.IsValid() {
		return ErrInvalidExcursionStatus
	}
	if !t.Visibility.IsValid() {
		return ErrInvalidExcursionVisibility
	}
	if t.DurationMinutes < minExcursionDurationMinutes || t.DurationMinutes > maxExcursionDurationMinutes {
		return ErrInvalidExcursionDuration
	}
	if t.MaxGroupSize < minExcursionGroupSize || t.MaxGroupSize > maxExcursionGroupSize {
		return ErrInvalidExcursionGroupSize
	}
	if strings.TrimSpace(t.MeetingPoint) == "" {
		return ErrInvalidExcursionMeeting
	}
	if err := validateExcursionLocation(t.CountryCode, t.CityName, t.Latitude, t.Longitude); err != nil {
		return err
	}
	if t.PriceAmount < 0 || t.PriceAmount > maxExcursionPrice {
		return ErrInvalidExcursionPrice
	}
	if strings.TrimSpace(t.Currency) == "" {
		return ErrInvalidExcursionCurrency
	}

	return nil
}

func validateExcursionLocation(
	countryCode *string,
	cityName *string,
	latitude *float64,
	longitude *float64,
) error {
	if countryCode == nil ||
		strings.TrimSpace(*countryCode) == "" ||
		cityName == nil ||
		strings.TrimSpace(*cityName) == "" {
		return ErrInvalidExcursionLocation
	}
	if latitude == nil || longitude == nil {
		return ErrInvalidExcursionLocation
	}
	if *latitude < -90 || *latitude > 90 || *longitude < -180 || *longitude > 180 {
		return ErrInvalidExcursionLocation
	}
	return nil
}

type PublishExcursionParams struct {
	LanguageCodes []string
	Itinerary     []*ExcursionItineraryItem
}

func (t *Excursion) ValidatePublishable(params PublishExcursionParams) error {
	if err := t.Validate(); err != nil {
		return err
	}
	if len(normalizeLanguageCodes(params.LanguageCodes)) == 0 {
		return ErrExcursionLanguageRequired
	}
	if len(params.Itinerary) == 0 {
		return ErrExcursionItineraryRequired
	}

	for _, item := range params.Itinerary {
		if item == nil {
			return ErrExcursionItineraryRequired
		}
		candidate := *item
		if candidate.ExcursionID != t.ID {
			candidate.ExcursionID = t.ID
		}
		if err := candidate.Validate(); err != nil {
			return err
		}
	}

	return nil
}

func (t *Excursion) Publish(params PublishExcursionParams) error {
	if t.DeletedAt != nil {
		return ErrExcursionAlreadyArchived
	}
	if err := t.ValidatePublishable(params); err != nil {
		return err
	}
	if t.Status == enum.ExcursionStatusPublished && t.PublishedAt != nil {
		return nil
	}

	now := time.Now().UTC()
	t.Status = enum.ExcursionStatusPublished
	t.PublishedAt = &now
	t.DeletedAt = nil
	t.Revision++
	t.UpdatedAt = now
	return nil
}

func (t *Excursion) MoveToArchive() error {
	if t.DeletedAt != nil {
		return ErrExcursionAlreadyArchived
	}
	if t.Status == enum.ExcursionStatusArchived {
		return nil
	}
	now := time.Now().UTC()
	t.Status = enum.ExcursionStatusArchived
	t.Revision++
	t.UpdatedAt = now
	return nil
}

func (t *Excursion) Archive() error {
	if t.Status == enum.ExcursionStatusArchived && t.DeletedAt != nil {
		return ErrExcursionAlreadyArchived
	}
	now := time.Now().UTC()
	t.Status = enum.ExcursionStatusArchived
	t.DeletedAt = &now
	t.Revision++
	t.UpdatedAt = now
	return nil
}

func (t *Excursion) IsPublished() bool {
	return t.Status == enum.ExcursionStatusPublished && t.DeletedAt == nil
}

func (t *Excursion) IsPubliclyReadable() bool {
	return t.IsPublished() && t.Visibility != enum.ExcursionVisibilityPrivate
}

func (t *Excursion) IsOwnedBy(userID uuid.UUID) bool {
	return userID != uuid.Nil && t.GuideUserID == userID
}

func normalizeGuideRatingAvg(value float64) float64 {
	if value < 0 {
		return 0
	}
	if value > 5 {
		return 5
	}
	return value
}

func normalizeNonNegativeInt(value int) int {
	if value < 0 {
		return 0
	}
	return value
}

func normalizeGuideSnapshotText(value string) string {
	return strings.Join(strings.Fields(strings.TrimSpace(value)), " ")
}

func NormalizeExcursionTranslations(input ExcursionTranslations) ExcursionTranslations {
	if len(input) == 0 {
		return nil
	}

	result := make(ExcursionTranslations, len(input))
	for locale, copy := range input {
		normalizedLocale := normalizeLocaleCode(locale)
		if normalizedLocale == "" {
			continue
		}
		normalizedCopy := ExcursionLocalizedCopy{
			Title:       strings.Join(strings.Fields(strings.TrimSpace(copy.Title)), " "),
			Summary:     strings.Join(strings.Fields(strings.TrimSpace(copy.Summary)), " "),
			Description: strings.TrimSpace(copy.Description),
		}
		if normalizedCopy.Title == "" && normalizedCopy.Summary == "" && normalizedCopy.Description == "" {
			continue
		}
		result[normalizedLocale] = normalizedCopy
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

func normalizeLocaleCode(value string) string {
	code := strings.ToLower(strings.TrimSpace(value))
	code = strings.ReplaceAll(code, "_", "-")
	return code
}

func validateExcursionTranslations(input ExcursionTranslations) error {
	for _, copy := range input {
		if titleLen := len(strings.TrimSpace(copy.Title)); titleLen > maxExcursionTitleLength {
			return ErrInvalidExcursionTitle
		}
		if summaryLen := len(strings.TrimSpace(copy.Summary)); summaryLen > maxExcursionSummaryLength {
			return ErrInvalidExcursionSummary
		}
		if descriptionLen := len(strings.TrimSpace(copy.Description)); descriptionLen > maxExcursionDescriptionLength {
			return ErrInvalidExcursionDescription
		}
	}
	return nil
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
