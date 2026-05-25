package app

import (
	"context"
	"errors"
	"fmt"
	"math"
	"net/url"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/port"
)

const (
	maxTitleChars      = 200
	maxDescChars       = 5000
	maxCommentChars    = 2000
	maxTags            = 10
	maxTagChars        = 32
	maxVisitInfoItems  = 8
	maxVisitInfoCode   = 48
	maxVisitInfoText   = 240
	defaultListLimit   = 20
	maxListLimit       = 100
	defaultReviewLimit = 20

	fallbackAttractionLocale = "en"
)

// ---------------------------------------------------------------------------
// View types
// ---------------------------------------------------------------------------

type AttractionAuthor struct {
	UserID       uuid.UUID
	DisplayName  *string
	AvatarFileID *uuid.UUID
}

type AttractionView struct {
	Attraction *model.Attraction
	Author     AttractionAuthor
}

type ReviewView struct {
	Review *model.AttractionReview
	Author AttractionAuthor
}

// ---------------------------------------------------------------------------
// Input types
// ---------------------------------------------------------------------------

type CreateAttractionInput struct {
	Title             string
	Description       string
	DefaultLocale     string
	Translations      map[string]AttractionTranslationInput
	CountryCode       string
	CityID            string
	AccessCities      []AttractionCityLinkInput
	DepartureCities   []AttractionCityLinkInput
	Latitude          *float64
	Longitude         *float64
	LocationSourceURL string
	Category          string
	PriceAmount       *float64
	PriceCurrency     *string
	DurationValue     *int
	DurationUnit      *string
	Rating            float64
	Spots             *int
	Status            string
	Tags              []string
	VisitInfo         *AttractionVisitInfoInput
}

type UpdateAttractionInput struct {
	Title             string
	Description       string
	DefaultLocale     string
	Translations      map[string]AttractionTranslationInput
	CountryCode       string
	CityID            string
	AccessCities      []AttractionCityLinkInput
	DepartureCities   []AttractionCityLinkInput
	Latitude          *float64
	Longitude         *float64
	LocationSourceURL string
	Category          string
	PriceAmount       *float64
	PriceCurrency     *string
	DurationValue     *int
	DurationUnit      *string
	Spots             *int
	Status            string
	Tags              []string
	VisitInfo         *AttractionVisitInfoInput
}

type ListAttractionsInput struct {
	Search          string
	Locale          string
	Category        string
	CountryCode     string
	CityID          string
	AccessCityID    string
	DepartureCityID string
	PriceMin        *float64
	PriceMax        *float64
	DurationMin     *int
	DurationMax     *int
	DurationUnit    *string
	SpotsMin        *int
	MinRating       *float64
	AuthorID        *uuid.UUID
	Sort            string
	Limit           int
	Offset          int
	IncludeDeleted  bool
}

type AttractionTranslationInput struct {
	Title       string
	Description string
}

type AttractionCityLinkInput struct {
	CountryCode string
	CityID      string
}

type AttractionVisitInfoInput struct {
	BestTime        string
	Accessibility   string
	BookingRequired *bool
	OpeningHours    string
	Amenities       []string
	Audience        []string
	SafetyNotes     []string
	NearbyIDs       []string
	LocalizedTips   map[string]string
}

type CreateReviewInput struct {
	Rating  float64
	Comment string
}

type ReplaceMediaInput struct {
	FileID      uuid.UUID
	ExternalURL string
	SourceURL   string
	Credit      string
	License     string
	MediaType   string
	Position    int
}

// ---------------------------------------------------------------------------
// Use case
// ---------------------------------------------------------------------------

type AttractionUseCase struct {
	repo              port.AttractionRepository
	users             UserServiceClient
	adminAuthorUserID uuid.UUID
}

type AttractionUseCaseOption func(*AttractionUseCase)

var defaultAdminAttractionAuthorUserID = uuid.MustParse("00000000-0000-4000-8000-000000000001")

func WithAdminAuthorUserID(userID uuid.UUID) AttractionUseCaseOption {
	return func(u *AttractionUseCase) {
		if userID != uuid.Nil {
			u.adminAuthorUserID = userID
		}
	}
}

func NewAttractionUseCase(repo port.AttractionRepository, users UserServiceClient, options ...AttractionUseCaseOption) *AttractionUseCase {
	uc := &AttractionUseCase{
		repo:              repo,
		users:             users,
		adminAuthorUserID: defaultAdminAttractionAuthorUserID,
	}
	for _, option := range options {
		if option != nil {
			option(uc)
		}
	}
	return uc
}

func NormalizeAttractionLocale(raw string) string {
	locale, ok := normalizeAttractionLocale(raw)
	if !ok {
		return fallbackAttractionLocale
	}
	return locale
}

// ---------------------------------------------------------------------------
// Attractions CRUD
// ---------------------------------------------------------------------------

func (u *AttractionUseCase) CreateAttraction(ctx context.Context, subject string, input CreateAttractionInput) (*AttractionView, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	return u.createAttraction(ctx, authorUserID, enum.SourceUser, input)
}

func (u *AttractionUseCase) CreateAttractionByAdmin(ctx context.Context, input CreateAttractionInput) (*AttractionView, error) {
	return u.createAttraction(ctx, u.adminAuthorUserID, enum.SourceImport, input)
}

func (u *AttractionUseCase) createAttraction(ctx context.Context, authorUserID uuid.UUID, source enum.ContentSource, input CreateAttractionInput) (*AttractionView, error) {
	category := enum.AttractionCategory(strings.ToUpper(strings.TrimSpace(input.Category)))
	if !category.IsValid() {
		return nil, ErrInvalidCategory
	}

	status := enum.AttractionStatus(strings.ToUpper(strings.TrimSpace(input.Status)))
	if !status.IsValid() {
		return nil, ErrInvalidStatus
	}

	defaultLocale, translations, title, desc, err := normalizeAttractionTranslations(
		input.DefaultLocale,
		input.Title,
		input.Description,
		input.Translations,
		nil,
	)
	if err != nil {
		return nil, err
	}

	countryCode, err := normalizeCountryCode(input.CountryCode)
	if err != nil {
		return nil, err
	}
	cityID, err := normalizeCityID(input.CityID)
	if err != nil {
		return nil, err
	}
	accessCities, err := normalizeAttractionCityLinks(countryCode, cityID, input.AccessCities, "ACCESS")
	if err != nil {
		return nil, err
	}
	departureCities, err := normalizeAttractionCityLinks(countryCode, cityID, input.DepartureCities, "DEPARTURE")
	if err != nil {
		return nil, err
	}

	if err = validatePrice(input.PriceAmount, input.PriceCurrency); err != nil {
		return nil, err
	}
	if err = validateDuration(input.DurationValue, input.DurationUnit); err != nil {
		return nil, err
	}
	locationSourceURL, err := normalizeLocation(input.Latitude, input.Longitude, input.LocationSourceURL)
	if err != nil {
		return nil, err
	}

	if input.Rating < 0 || input.Rating > 5.0 {
		input.Rating = 0
	}

	tags := normalizeTags(input.Tags)
	visitInfo, err := normalizeVisitInfo(input.VisitInfo, nil)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	setAttractionCityLinkTimestamps(accessCities, now)
	setAttractionCityLinkTimestamps(departureCities, now)
	attraction := &model.Attraction{
		ID:                uuid.New(),
		AuthorUserID:      authorUserID,
		DefaultLocale:     defaultLocale,
		Locale:            defaultLocale,
		Title:             title,
		Description:       desc,
		CountryCode:       countryCode,
		CityID:            cityID,
		AccessCities:      accessCities,
		DepartureCities:   departureCities,
		Latitude:          input.Latitude,
		Longitude:         input.Longitude,
		LocationSourceURL: locationSourceURL,
		Category:          category,
		PriceAmount:       input.PriceAmount,
		PriceCurrency:     input.PriceCurrency,
		DurationValue:     input.DurationValue,
		Rating:            input.Rating,
		Spots:             input.Spots,
		Source:            source,
		Status:            status,
		Tags:              tags,
		VisitInfo:         visitInfo,
		Translations:      translations,
		CreatedAt:         now,
		UpdatedAt:         now,
	}

	if input.DurationUnit != nil {
		du := enum.DurationUnit(strings.ToUpper(*input.DurationUnit))
		attraction.DurationUnit = &du
	}

	if err = u.repo.CreateAttraction(ctx, attraction); err != nil {
		return nil, fmt.Errorf("create attraction: %w", err)
	}

	return u.toAttractionView(ctx, attraction)
}

func (u *AttractionUseCase) UpdateAttraction(ctx context.Context, subject string, attractionID uuid.UUID, input UpdateAttractionInput, roles []string) (*AttractionView, error) {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	attraction, err := u.repo.GetAttractionByID(ctx, attractionID, "")
	if err != nil {
		return nil, fmt.Errorf("get attraction: %w", err)
	}
	if attraction == nil {
		return nil, ErrAttractionNotFound
	}

	if !attraction.IsOwnedBy(userID) && !hasRole(roles, "manager") {
		return nil, ErrAccessDenied
	}

	return u.updateAttractionRecord(ctx, attraction, input)
}

func (u *AttractionUseCase) UpdateAttractionByAdmin(ctx context.Context, attractionID uuid.UUID, input UpdateAttractionInput) (*AttractionView, error) {
	attraction, err := u.repo.GetAttractionByID(ctx, attractionID, "")
	if err != nil {
		return nil, fmt.Errorf("get attraction: %w", err)
	}
	if attraction == nil {
		return nil, ErrAttractionNotFound
	}
	return u.updateAttractionRecord(ctx, attraction, input)
}

func (u *AttractionUseCase) updateAttractionRecord(ctx context.Context, attraction *model.Attraction, input UpdateAttractionInput) (*AttractionView, error) {
	category := enum.AttractionCategory(strings.ToUpper(strings.TrimSpace(input.Category)))
	if !category.IsValid() {
		return nil, ErrInvalidCategory
	}

	status := enum.AttractionStatus(strings.ToUpper(strings.TrimSpace(input.Status)))
	if !status.IsValid() {
		return nil, ErrInvalidStatus
	}

	defaultLocale, translations, title, desc, err := normalizeAttractionTranslations(
		input.DefaultLocale,
		input.Title,
		input.Description,
		input.Translations,
		attraction,
	)
	if err != nil {
		return nil, err
	}

	countryCode, err := normalizeCountryCode(input.CountryCode)
	if err != nil {
		return nil, err
	}
	cityID, err := normalizeCityID(input.CityID)
	if err != nil {
		return nil, err
	}
	accessCities, err := normalizeAttractionCityLinks(countryCode, cityID, input.AccessCities, "ACCESS")
	if err != nil {
		return nil, err
	}
	departureCities, err := normalizeAttractionCityLinks(countryCode, cityID, input.DepartureCities, "DEPARTURE")
	if err != nil {
		return nil, err
	}

	if err = validatePrice(input.PriceAmount, input.PriceCurrency); err != nil {
		return nil, err
	}
	if err = validateDuration(input.DurationValue, input.DurationUnit); err != nil {
		return nil, err
	}
	latitude := attraction.Latitude
	longitude := attraction.Longitude
	locationSourceURL := attraction.LocationSourceURL
	if input.Latitude != nil || input.Longitude != nil || strings.TrimSpace(input.LocationSourceURL) != "" {
		locationSourceURL, err = normalizeLocation(input.Latitude, input.Longitude, input.LocationSourceURL)
		if err != nil {
			return nil, err
		}
		latitude = input.Latitude
		longitude = input.Longitude
	}

	attraction.Title = title
	attraction.Description = desc
	attraction.DefaultLocale = defaultLocale
	attraction.Locale = defaultLocale
	attraction.Translations = translations
	attraction.CountryCode = countryCode
	attraction.CityID = cityID
	attraction.AccessCities = accessCities
	attraction.DepartureCities = departureCities
	attraction.Latitude = latitude
	attraction.Longitude = longitude
	attraction.LocationSourceURL = locationSourceURL
	attraction.Category = category
	attraction.PriceAmount = input.PriceAmount
	attraction.PriceCurrency = input.PriceCurrency
	attraction.DurationValue = input.DurationValue
	attraction.Spots = input.Spots
	attraction.Status = status
	attraction.Tags = normalizeTags(input.Tags)
	visitInfo, err := normalizeVisitInfo(input.VisitInfo, &attraction.VisitInfo)
	if err != nil {
		return nil, err
	}
	attraction.VisitInfo = visitInfo
	attraction.UpdatedAt = time.Now().UTC()
	setAttractionCityLinkTimestamps(attraction.AccessCities, attraction.UpdatedAt)
	setAttractionCityLinkTimestamps(attraction.DepartureCities, attraction.UpdatedAt)

	if input.DurationUnit != nil {
		du := enum.DurationUnit(strings.ToUpper(*input.DurationUnit))
		attraction.DurationUnit = &du
	} else {
		attraction.DurationUnit = nil
	}

	if err = u.repo.UpdateAttraction(ctx, attraction); err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, ErrAttractionNotFound
		}
		return nil, fmt.Errorf("update attraction: %w", err)
	}

	return u.toAttractionView(ctx, attraction)
}

func (u *AttractionUseCase) DeleteAttraction(ctx context.Context, subject string, attractionID uuid.UUID, roles []string) error {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return err
	}

	attraction, err := u.repo.GetAttractionByID(ctx, attractionID, "")
	if err != nil {
		return fmt.Errorf("get attraction: %w", err)
	}
	if attraction == nil {
		return ErrAttractionNotFound
	}

	if !attraction.IsOwnedBy(userID) && !hasRole(roles, "manager") {
		return ErrAccessDenied
	}

	if err = u.repo.SoftDeleteAttraction(ctx, attractionID); err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return ErrAttractionNotFound
		}
		return fmt.Errorf("delete attraction: %w", err)
	}
	return nil
}

func (u *AttractionUseCase) RecoverAttraction(ctx context.Context, attractionID uuid.UUID, roles []string) (*AttractionView, error) {
	if !hasRole(roles, "manager") {
		return nil, ErrAccessDenied
	}

	if err := u.repo.RecoverAttraction(ctx, attractionID); err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, ErrAttractionNotFound
		}
		return nil, fmt.Errorf("recover attraction: %w", err)
	}

	attraction, err := u.repo.GetAttractionByID(ctx, attractionID, "")
	if err != nil {
		return nil, fmt.Errorf("get recovered attraction: %w", err)
	}
	return u.toAttractionView(ctx, attraction)
}

func (u *AttractionUseCase) GetAttraction(ctx context.Context, attractionID uuid.UUID, locale string) (*AttractionView, error) {
	attraction, err := u.repo.GetAttractionByID(ctx, attractionID, NormalizeAttractionLocale(locale))
	if err != nil {
		return nil, fmt.Errorf("get attraction: %w", err)
	}
	if attraction == nil {
		return nil, ErrAttractionNotFound
	}
	return u.toAttractionView(ctx, attraction)
}

func (u *AttractionUseCase) ListAttractions(ctx context.Context, input ListAttractionsInput) ([]*AttractionView, int, error) {
	if input.Limit <= 0 {
		input.Limit = defaultListLimit
	}
	if input.Limit > maxListLimit {
		input.Limit = maxListLimit
	}
	if input.Offset < 0 {
		input.Offset = 0
	}

	countryCode, err := normalizeCountryCode(input.CountryCode)
	if err != nil {
		return nil, 0, err
	}
	cityID, err := normalizeCityID(input.CityID)
	if err != nil {
		return nil, 0, err
	}
	accessCityID, err := normalizeOptionalCityID(input.AccessCityID)
	if err != nil {
		return nil, 0, err
	}
	departureCityID, err := normalizeOptionalCityID(input.DepartureCityID)
	if err != nil {
		return nil, 0, err
	}

	var durationUnit *enum.DurationUnit
	if input.DurationUnit != nil {
		du := enum.DurationUnit(strings.ToUpper(*input.DurationUnit))
		durationUnit = &du
	}

	filter := model.AttractionListFilter{
		Search:          input.Search,
		Locale:          NormalizeAttractionLocale(input.Locale),
		Category:        strings.ToUpper(strings.TrimSpace(input.Category)),
		CountryCode:     countryCode,
		CityID:          cityID,
		AccessCityID:    accessCityID,
		DepartureCityID: departureCityID,
		PriceMin:        input.PriceMin,
		PriceMax:        input.PriceMax,
		DurationMin:     input.DurationMin,
		DurationMax:     input.DurationMax,
		DurationUnit:    durationUnit,
		SpotsMin:        input.SpotsMin,
		MinRating:       input.MinRating,
		AuthorUserID:    input.AuthorID,
		IncludeDeleted:  input.IncludeDeleted,
		Sort:            input.Sort,
		Limit:           input.Limit,
		Offset:          input.Offset,
	}

	attractions, total, err := u.repo.ListAttractions(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("list attractions: %w", err)
	}

	views := make([]*AttractionView, 0, len(attractions))
	for _, a := range attractions {
		v, vErr := u.toAttractionView(ctx, a)
		if vErr != nil {
			return nil, 0, vErr
		}
		views = append(views, v)
	}

	return views, total, nil
}

// ---------------------------------------------------------------------------
// Media
// ---------------------------------------------------------------------------

func (u *AttractionUseCase) ReplaceAttractionMedia(ctx context.Context, subject string, attractionID uuid.UUID, media []ReplaceMediaInput, roles []string) error {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return err
	}

	attraction, err := u.repo.GetAttractionByID(ctx, attractionID, "")
	if err != nil {
		return fmt.Errorf("get attraction: %w", err)
	}
	if attraction == nil {
		return ErrAttractionNotFound
	}
	if !attraction.IsOwnedBy(userID) && !hasRole(roles, "manager") {
		return ErrAccessDenied
	}

	return u.replaceAttractionMedia(ctx, attractionID, media)
}

func (u *AttractionUseCase) ReplaceAttractionMediaByAdmin(ctx context.Context, attractionID uuid.UUID, media []ReplaceMediaInput) error {
	attraction, err := u.repo.GetAttractionByID(ctx, attractionID, "")
	if err != nil {
		return fmt.Errorf("get attraction: %w", err)
	}
	if attraction == nil {
		return ErrAttractionNotFound
	}
	return u.replaceAttractionMedia(ctx, attractionID, media)
}

func (u *AttractionUseCase) replaceAttractionMedia(ctx context.Context, attractionID uuid.UUID, media []ReplaceMediaInput) error {
	now := time.Now().UTC()
	models := make([]model.AttractionMedia, 0, len(media))
	for _, m := range media {
		mt, mediaErr := normalizeMediaType(m.MediaType)
		if mediaErr != nil {
			return mediaErr
		}
		models = append(models, model.AttractionMedia{
			ID:           uuid.New(),
			AttractionID: attractionID,
			FileID:       m.FileID,
			ExternalURL:  strings.TrimSpace(m.ExternalURL),
			SourceURL:    strings.TrimSpace(m.SourceURL),
			Credit:       strings.TrimSpace(m.Credit),
			License:      strings.TrimSpace(m.License),
			MediaType:    mt,
			Position:     m.Position,
			CreatedAt:    now,
		})
	}

	return u.repo.ReplaceAttractionMedia(ctx, attractionID, models)
}

// ---------------------------------------------------------------------------
// Reviews
// ---------------------------------------------------------------------------

func (u *AttractionUseCase) CreateReview(ctx context.Context, subject string, attractionID uuid.UUID, input CreateReviewInput, media []ReplaceMediaInput) (*ReviewView, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	attraction, err := u.repo.GetAttractionByID(ctx, attractionID, "")
	if err != nil {
		return nil, fmt.Errorf("get attraction: %w", err)
	}
	if attraction == nil {
		return nil, ErrAttractionNotFound
	}
	if attraction.IsDeleted() {
		return nil, ErrAttractionDeleted
	}
	if !attraction.IsPublished() {
		return nil, ErrAttractionNotPublished
	}
	if attraction.IsOwnedBy(authorUserID) {
		return nil, ErrCannotReviewOwn
	}

	if input.Rating < 1.0 || input.Rating > 5.0 {
		return nil, ErrInvalidRating
	}

	comment := strings.TrimSpace(input.Comment)
	if utf8.RuneCountInString(comment) > maxCommentChars {
		comment = string([]rune(comment)[:maxCommentChars])
	}

	now := time.Now().UTC()
	review := &model.AttractionReview{
		ID:           uuid.New(),
		AttractionID: attractionID,
		AuthorUserID: authorUserID,
		Rating:       input.Rating,
		Comment:      comment,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	reviewMedia := make([]model.ReviewMedia, 0, len(media))
	for _, m := range media {
		mt, mediaErr := normalizeMediaType(m.MediaType)
		if mediaErr != nil {
			return nil, mediaErr
		}
		reviewMedia = append(reviewMedia, model.ReviewMedia{
			ID:        uuid.New(),
			ReviewID:  review.ID,
			FileID:    m.FileID,
			MediaType: mt,
			Position:  m.Position,
			CreatedAt: now,
		})
	}
	review.Media = reviewMedia

	if err = u.repo.CreateReview(ctx, review); err != nil {
		if errors.Is(err, repository.ErrConflict) {
			return nil, ErrReviewConflict
		}
		return nil, fmt.Errorf("create review: %w", err)
	}

	return u.toReviewView(ctx, review)
}

func (u *AttractionUseCase) DeleteReview(ctx context.Context, subject string, reviewID uuid.UUID) error {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return err
	}

	if err = u.repo.SoftDeleteReview(ctx, reviewID, userID); err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return ErrReviewNotFound
		}
		return fmt.Errorf("delete review: %w", err)
	}
	return nil
}

func (u *AttractionUseCase) RecalculateRating(ctx context.Context, attractionID uuid.UUID) (float64, int, error) {
	if attractionID == uuid.Nil {
		return 0, 0, ErrAttractionNotFound
	}
	rating, reviewCount, err := u.repo.RecalcRating(ctx, attractionID)
	if err != nil {
		return 0, 0, fmt.Errorf("recalculate attraction rating: %w", err)
	}
	return rating, reviewCount, nil
}

type RatingSourceSnapshotInput struct {
	AttractionID uuid.UUID
	Source       string
	RatingAvg    float64
	ReviewCount  int
}

func (u *AttractionUseCase) ApplyRatingSourceSnapshot(ctx context.Context, input RatingSourceSnapshotInput) (float64, int, error) {
	if input.AttractionID == uuid.Nil {
		return 0, 0, ErrAttractionNotFound
	}
	source := strings.TrimSpace(input.Source)
	if source == "" || len(source) > 64 {
		return 0, 0, ErrInvalidRatingSource
	}
	if input.ReviewCount < 0 || input.RatingAvg > 5 {
		return 0, 0, ErrInvalidRatingSource
	}
	if input.ReviewCount == 0 {
		input.RatingAvg = 0
	} else if input.RatingAvg < 1 {
		return 0, 0, ErrInvalidRatingSource
	}

	rating, reviewCount, err := u.repo.ApplyRatingSourceSnapshot(
		ctx,
		input.AttractionID,
		source,
		input.RatingAvg,
		input.ReviewCount,
	)
	if err != nil {
		return 0, 0, fmt.Errorf("apply attraction rating source snapshot: %w", err)
	}
	return rating, reviewCount, nil
}

func (u *AttractionUseCase) ListReviews(ctx context.Context, attractionID uuid.UUID, limit, offset int) ([]*ReviewView, int, error) {
	if limit <= 0 {
		limit = defaultReviewLimit
	}
	if limit > maxListLimit {
		limit = maxListLimit
	}
	if offset < 0 {
		offset = 0
	}

	reviews, total, err := u.repo.ListReviews(ctx, attractionID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("list reviews: %w", err)
	}

	views := make([]*ReviewView, 0, len(reviews))
	for _, r := range reviews {
		v, vErr := u.toReviewView(ctx, r)
		if vErr != nil {
			return nil, 0, vErr
		}
		views = append(views, v)
	}

	return views, total, nil
}

func (u *AttractionUseCase) GetMyReview(ctx context.Context, subject string, attractionID uuid.UUID) (*ReviewView, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	attraction, err := u.repo.GetAttractionByID(ctx, attractionID, "")
	if err != nil {
		return nil, fmt.Errorf("get attraction: %w", err)
	}
	if attraction == nil {
		return nil, ErrAttractionNotFound
	}

	review, err := u.repo.GetReviewByAttractionAndAuthor(ctx, attractionID, authorUserID)
	if err != nil {
		return nil, fmt.Errorf("get my review: %w", err)
	}
	if review == nil {
		return nil, ErrReviewNotFound
	}

	return u.toReviewView(ctx, review)
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

func (u *AttractionUseCase) requireUserID(ctx context.Context, subject string) (uuid.UUID, error) {
	subject = strings.TrimSpace(subject)
	if subject == "" {
		return uuid.Nil, ErrUnauthenticated
	}
	userID, err := u.users.ResolveUserIDBySubject(ctx, subject)
	if err != nil {
		return uuid.Nil, fmt.Errorf("resolve user id: %w", err)
	}
	if userID == uuid.Nil {
		return uuid.Nil, ErrUserNotFound
	}
	return userID, nil
}

func (u *AttractionUseCase) toAttractionView(ctx context.Context, attraction *model.Attraction) (*AttractionView, error) {
	author := AttractionAuthor{UserID: attraction.AuthorUserID}

	profiles, err := u.users.GetPublicUserProfiles(ctx, []uuid.UUID{attraction.AuthorUserID})
	if err == nil {
		if p, ok := profiles[attraction.AuthorUserID]; ok {
			author.DisplayName = p.DisplayName
			author.AvatarFileID = p.AvatarFileID
		}
	}

	return &AttractionView{
		Attraction: attraction,
		Author:     author,
	}, nil
}

func (u *AttractionUseCase) toReviewView(ctx context.Context, review *model.AttractionReview) (*ReviewView, error) {
	author := AttractionAuthor{UserID: review.AuthorUserID}

	profiles, err := u.users.GetPublicUserProfiles(ctx, []uuid.UUID{review.AuthorUserID})
	if err == nil {
		if p, ok := profiles[review.AuthorUserID]; ok {
			author.DisplayName = p.DisplayName
			author.AvatarFileID = p.AvatarFileID
		}
	}

	return &ReviewView{
		Review: review,
		Author: author,
	}, nil
}

func validatePrice(amount *float64, currency *string) error {
	hasAmount := amount != nil
	hasCurrency := currency != nil && strings.TrimSpace(*currency) != ""
	if hasAmount != hasCurrency {
		return ErrInvalidPrice
	}
	return nil
}

func validateDuration(value *int, unit *string) error {
	hasValue := value != nil
	hasUnit := unit != nil && strings.TrimSpace(*unit) != ""
	if hasValue != hasUnit {
		return ErrInvalidDuration
	}
	if hasUnit {
		du := enum.DurationUnit(strings.ToUpper(*unit))
		if !du.IsValid() {
			return ErrInvalidDuration
		}
	}
	return nil
}

func normalizeLocation(latitude *float64, longitude *float64, sourceURL string) (string, error) {
	hasLatitude := latitude != nil
	hasLongitude := longitude != nil
	if hasLatitude != hasLongitude {
		return "", ErrInvalidLocation
	}

	sourceURL = strings.TrimSpace(sourceURL)
	if !hasLatitude {
		if sourceURL != "" {
			return "", ErrInvalidLocation
		}
		return "", nil
	}

	if math.IsNaN(*latitude) || math.IsInf(*latitude, 0) || *latitude < -90 || *latitude > 90 {
		return "", ErrInvalidLocation
	}
	if math.IsNaN(*longitude) || math.IsInf(*longitude, 0) || *longitude < -180 || *longitude > 180 {
		return "", ErrInvalidLocation
	}

	if sourceURL == "" {
		return "", nil
	}
	parsed, err := url.ParseRequestURI(sourceURL)
	if err != nil || parsed.Scheme != "https" || parsed.Host == "" {
		return "", ErrInvalidLocation
	}
	return sourceURL, nil
}

func normalizeAttractionTranslations(
	rawDefaultLocale string,
	legacyTitle string,
	legacyDescription string,
	input map[string]AttractionTranslationInput,
	existing *model.Attraction,
) (string, map[string]model.AttractionTranslation, string, string, error) {
	defaultLocaleRaw := rawDefaultLocale
	if strings.TrimSpace(defaultLocaleRaw) == "" && existing != nil {
		defaultLocaleRaw = existing.DefaultLocale
	}

	defaultLocale, ok := normalizeAttractionLocale(defaultLocaleRaw)
	if !ok {
		return "", nil, "", "", ErrInvalidLocale
	}

	translations := make(map[string]model.AttractionTranslation)
	if existing != nil {
		for locale, translation := range existing.Translations {
			normalizedLocale, localeOK := normalizeAttractionLocale(locale)
			if !localeOK {
				continue
			}
			translation.Locale = normalizedLocale
			translations[normalizedLocale] = translation
		}
		if len(translations) == 0 && strings.TrimSpace(existing.Title) != "" {
			locale := NormalizeAttractionLocale(existing.Locale)
			translations[locale] = model.AttractionTranslation{
				AttractionID: existing.ID,
				Locale:       locale,
				Title:        strings.TrimSpace(existing.Title),
				Description:  strings.TrimSpace(existing.Description),
			}
		}
	}

	for rawLocale, translationInput := range input {
		locale, localeOK := normalizeAttractionLocale(rawLocale)
		if !localeOK {
			return "", nil, "", "", ErrInvalidLocale
		}

		translation, err := normalizeTranslationInput(locale, translationInput.Title, translationInput.Description)
		if err != nil {
			return "", nil, "", "", err
		}
		translations[locale] = translation
	}

	if strings.TrimSpace(legacyTitle) != "" || strings.TrimSpace(legacyDescription) != "" || len(translations) == 0 {
		translation, err := normalizeTranslationInput(defaultLocale, legacyTitle, legacyDescription)
		if err != nil {
			return "", nil, "", "", err
		}
		if _, exists := translations[defaultLocale]; !exists || strings.TrimSpace(legacyTitle) != "" {
			translations[defaultLocale] = translation
		}
	}

	defaultTranslation, exists := translations[defaultLocale]
	if !exists {
		return "", nil, "", "", ErrInvalidTitle
	}
	if strings.TrimSpace(defaultTranslation.Title) == "" || utf8.RuneCountInString(defaultTranslation.Title) > maxTitleChars {
		return "", nil, "", "", ErrInvalidTitle
	}

	defaultTranslation.Locale = defaultLocale
	defaultTranslation.Title = strings.TrimSpace(defaultTranslation.Title)
	defaultTranslation.Description = trimDescription(defaultTranslation.Description)
	translations[defaultLocale] = defaultTranslation

	return defaultLocale, translations, defaultTranslation.Title, defaultTranslation.Description, nil
}

func normalizeTranslationInput(locale string, title string, description string) (model.AttractionTranslation, error) {
	title = strings.TrimSpace(title)
	if title == "" || utf8.RuneCountInString(title) > maxTitleChars {
		return model.AttractionTranslation{}, ErrInvalidTitle
	}

	return model.AttractionTranslation{
		Locale:      locale,
		Title:       title,
		Description: trimDescription(description),
	}, nil
}

func normalizeAttractionLocale(raw string) (string, bool) {
	raw = strings.ToLower(strings.TrimSpace(raw))
	if raw == "" {
		return fallbackAttractionLocale, true
	}
	raw = strings.ReplaceAll(raw, "_", "-")
	if idx := strings.Index(raw, "-"); idx > 0 {
		raw = raw[:idx]
	}
	switch raw {
	case "en", "ru", "kk":
		return raw, true
	default:
		return "", false
	}
}

func normalizeMediaType(raw string) (enum.MediaType, error) {
	mediaType := enum.MediaType(strings.ToUpper(strings.TrimSpace(raw)))
	if mediaType == "" {
		mediaType = enum.MediaPhoto
	}
	if !mediaType.IsValid() {
		return "", ErrInvalidMediaType
	}
	return mediaType, nil
}

func normalizeCountryCode(raw string) (string, error) {
	code := strings.ToUpper(strings.TrimSpace(raw))
	if code == "" {
		return "", nil
	}
	if len(code) != 2 {
		return "", ErrInvalidCountryCode
	}
	for _, r := range code {
		if r < 'A' || r > 'Z' {
			return "", ErrInvalidCountryCode
		}
	}
	return code, nil
}

func normalizeCityID(raw string) (string, error) {
	cityID := strings.ToLower(strings.TrimSpace(raw))
	if cityID == "" {
		return "", nil
	}
	if len(cityID) > 64 || cityID[0] == '-' || cityID[len(cityID)-1] == '-' {
		return "", ErrInvalidCityID
	}
	for _, r := range cityID {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '-' {
			continue
		}
		return "", ErrInvalidCityID
	}
	return cityID, nil
}

func normalizeOptionalCityID(raw string) (string, error) {
	if strings.TrimSpace(raw) == "" {
		return "", nil
	}
	return normalizeCityID(raw)
}

func normalizeAttractionCityLinks(
	defaultCountryCode string,
	defaultCityID string,
	inputs []AttractionCityLinkInput,
	kind string,
) ([]model.AttractionCityLink, error) {
	if len(inputs) == 0 && defaultCityID != "" {
		inputs = []AttractionCityLinkInput{{CountryCode: defaultCountryCode, CityID: defaultCityID}}
	}
	seen := make(map[string]struct{}, len(inputs))
	result := make([]model.AttractionCityLink, 0, len(inputs))
	for _, input := range inputs {
		countryCode := input.CountryCode
		if strings.TrimSpace(countryCode) == "" {
			countryCode = defaultCountryCode
		}
		normalizedCountryCode, err := normalizeCountryCode(countryCode)
		if err != nil {
			return nil, err
		}
		cityID, err := normalizeCityID(input.CityID)
		if err != nil {
			return nil, err
		}
		if cityID == "" {
			continue
		}
		key := normalizedCountryCode + ":" + cityID
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, model.AttractionCityLink{
			Kind:        kind,
			CountryCode: normalizedCountryCode,
			CityID:      cityID,
			Position:    len(result),
		})
	}
	return result, nil
}

func setAttractionCityLinkTimestamps(items []model.AttractionCityLink, createdAt time.Time) {
	for i := range items {
		items[i].CreatedAt = createdAt
	}
}

func trimDescription(description string) string {
	description = strings.TrimSpace(description)
	if utf8.RuneCountInString(description) > maxDescChars {
		return string([]rune(description)[:maxDescChars])
	}
	return description
}

func normalizeTags(tags []string) []string {
	seen := make(map[string]struct{})
	result := make([]string, 0, len(tags))
	for _, t := range tags {
		t = strings.TrimSpace(t)
		if t == "" {
			continue
		}
		if utf8.RuneCountInString(t) > maxTagChars {
			t = string([]rune(t)[:maxTagChars])
		}
		lower := strings.ToLower(t)
		if _, ok := seen[lower]; ok {
			continue
		}
		seen[lower] = struct{}{}
		result = append(result, t)
		if len(result) >= maxTags {
			break
		}
	}
	return result
}

func normalizeVisitInfo(input *AttractionVisitInfoInput, existing *model.AttractionVisitInfo) (model.AttractionVisitInfo, error) {
	if input == nil {
		if existing != nil {
			return *existing, nil
		}
		return model.AttractionVisitInfo{}, nil
	}

	nearbyIDs := make([]uuid.UUID, 0, len(input.NearbyIDs))
	for _, raw := range input.NearbyIDs {
		raw = strings.TrimSpace(raw)
		if raw == "" {
			continue
		}
		id, err := uuid.Parse(raw)
		if err != nil {
			return model.AttractionVisitInfo{}, ErrInvalidVisitInfo
		}
		nearbyIDs = append(nearbyIDs, id)
		if len(nearbyIDs) >= maxVisitInfoItems {
			break
		}
	}

	tips := normalizeLocalizedTips(input.LocalizedTips)

	return model.AttractionVisitInfo{
		BestTime:        normalizeVisitInfoCode(input.BestTime),
		Accessibility:   normalizeVisitInfoCode(input.Accessibility),
		BookingRequired: input.BookingRequired,
		OpeningHours:    normalizeVisitInfoCode(input.OpeningHours),
		Amenities:       normalizeVisitInfoCodes(input.Amenities),
		Audience:        normalizeVisitInfoCodes(input.Audience),
		SafetyNotes:     normalizeVisitInfoCodes(input.SafetyNotes),
		NearbyIDs:       nearbyIDs,
		LocalizedTips:   tips,
	}, nil
}

func normalizeVisitInfoCodes(values []string) []string {
	seen := make(map[string]struct{})
	result := make([]string, 0, len(values))
	for _, raw := range values {
		code := normalizeVisitInfoCode(raw)
		if code == "" {
			continue
		}
		if _, ok := seen[code]; ok {
			continue
		}
		seen[code] = struct{}{}
		result = append(result, code)
		if len(result) >= maxVisitInfoItems {
			break
		}
	}
	return result
}

func normalizeVisitInfoCode(raw string) string {
	code := strings.ToUpper(strings.TrimSpace(raw))
	code = strings.ReplaceAll(code, "-", "_")
	code = strings.ReplaceAll(code, " ", "_")
	if utf8.RuneCountInString(code) > maxVisitInfoCode {
		code = string([]rune(code)[:maxVisitInfoCode])
	}
	for _, r := range code {
		if (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '_' {
			continue
		}
		return ""
	}
	return code
}

func normalizeLocalizedTips(input map[string]string) map[string]string {
	if len(input) == 0 {
		return nil
	}

	result := make(map[string]string)
	for rawLocale, rawText := range input {
		locale, ok := normalizeAttractionLocale(rawLocale)
		if !ok {
			continue
		}
		text := strings.TrimSpace(rawText)
		if text == "" {
			continue
		}
		if utf8.RuneCountInString(text) > maxVisitInfoText {
			text = string([]rune(text)[:maxVisitInfoText])
		}
		result[locale] = text
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

func hasRole(roles []string, target string) bool {
	for _, r := range roles {
		if strings.EqualFold(r, target) {
			return true
		}
	}
	return false
}
