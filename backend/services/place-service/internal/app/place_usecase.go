package app

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/url"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/adapter/repository"
	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
	"kz/inflap/backend/services/place-service/internal/domain/port"
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

	fallbackPlaceLocale = "en"

	placeListCacheVersionScope = "place:list"
)

// ---------------------------------------------------------------------------
// View types
// ---------------------------------------------------------------------------

type PlaceAuthor struct {
	UserID       uuid.UUID
	Nickname     *string
	AvatarFileID *uuid.UUID
}

type PlaceView struct {
	Place  *model.Place
	Author PlaceAuthor
}

type ReviewView struct {
	Review *model.PlaceReview
	Author PlaceAuthor
}

// ---------------------------------------------------------------------------
// Input types
// ---------------------------------------------------------------------------

type CreatePlaceInput struct {
	Title             string
	Description       string
	DefaultLocale     string
	Translations      map[string]PlaceTranslationInput
	CountryCode       string
	CityID            string
	AccessCities      []PlaceCityLinkInput
	DepartureCities   []PlaceCityLinkInput
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
	VisitInfo         *PlaceVisitInfoInput
}

type UpdatePlaceInput struct {
	Title             string
	Description       string
	DefaultLocale     string
	Translations      map[string]PlaceTranslationInput
	CountryCode       string
	CityID            string
	AccessCities      []PlaceCityLinkInput
	DepartureCities   []PlaceCityLinkInput
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
	VisitInfo         *PlaceVisitInfoInput
}

type ListPlacesInput struct {
	Search          string
	Locale          string
	Category        string
	CountryCode     string
	CityID          string
	RegionID        string
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

type PlaceTranslationInput struct {
	Title       string
	Description string
}

type PlaceCityLinkInput struct {
	CountryCode string
	CityID      string
}

type PlaceVisitInfoInput struct {
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

type PlaceUseCase struct {
	repo              port.PlaceRepository
	users             UserServiceClient
	cache             port.PlaceCache
	detailCacheTTL    time.Duration
	listCacheTTL      time.Duration
	adminAuthorUserID uuid.UUID
}

type PlaceUseCaseOption func(*PlaceUseCase)

var defaultAdminPlaceAuthorUserID = uuid.MustParse("00000000-0000-4000-8000-000000000001")

func WithAdminAuthorUserID(userID uuid.UUID) PlaceUseCaseOption {
	return func(u *PlaceUseCase) {
		if userID != uuid.Nil {
			u.adminAuthorUserID = userID
		}
	}
}

func WithPlaceCache(cache port.PlaceCache, detailTTL time.Duration, listTTL time.Duration) PlaceUseCaseOption {
	return func(u *PlaceUseCase) {
		u.cache = cache
		u.detailCacheTTL = detailTTL
		u.listCacheTTL = listTTL
	}
}

func NewPlaceUseCase(repo port.PlaceRepository, users UserServiceClient, options ...PlaceUseCaseOption) *PlaceUseCase {
	uc := &PlaceUseCase{
		repo:              repo,
		users:             users,
		adminAuthorUserID: defaultAdminPlaceAuthorUserID,
	}
	for _, option := range options {
		if option != nil {
			option(uc)
		}
	}
	return uc
}

func NormalizePlaceLocale(raw string) string {
	locale, ok := normalizePlaceLocale(raw)
	if !ok {
		return fallbackPlaceLocale
	}
	return locale
}

// ---------------------------------------------------------------------------
// Places CRUD
// ---------------------------------------------------------------------------

func (u *PlaceUseCase) CreatePlace(ctx context.Context, subject string, input CreatePlaceInput) (*PlaceView, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	return u.createPlace(ctx, authorUserID, enum.SourceUser, input)
}

func (u *PlaceUseCase) CreatePlaceByAdmin(ctx context.Context, input CreatePlaceInput) (*PlaceView, error) {
	return u.createPlace(ctx, u.adminAuthorUserID, enum.SourceImport, input)
}

func (u *PlaceUseCase) createPlace(ctx context.Context, authorUserID uuid.UUID, source enum.ContentSource, input CreatePlaceInput) (*PlaceView, error) {
	category := enum.PlaceCategory(strings.ToUpper(strings.TrimSpace(input.Category)))
	if !category.IsValid() {
		return nil, ErrInvalidCategory
	}

	status := enum.PlaceStatus(strings.ToUpper(strings.TrimSpace(input.Status)))
	if !status.IsValid() {
		return nil, ErrInvalidStatus
	}

	defaultLocale, translations, title, desc, err := normalizePlaceTranslations(
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
	accessCities, err := normalizePlaceCityLinks(countryCode, cityID, input.AccessCities, "ACCESS")
	if err != nil {
		return nil, err
	}
	departureCities, err := normalizePlaceCityLinks(countryCode, cityID, input.DepartureCities, "DEPARTURE")
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
	setPlaceCityLinkTimestamps(accessCities, now)
	setPlaceCityLinkTimestamps(departureCities, now)
	place := &model.Place{
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
		place.DurationUnit = &du
	}

	if err = u.repo.CreatePlace(ctx, place); err != nil {
		return nil, fmt.Errorf("create place: %w", err)
	}
	u.bumpPlaceCacheVersion(ctx, uuid.Nil)

	return u.toPlaceView(ctx, place)
}

func (u *PlaceUseCase) UpdatePlace(ctx context.Context, subject string, placeID uuid.UUID, input UpdatePlaceInput, roles []string) (*PlaceView, error) {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	place, err := u.repo.GetPlaceByID(ctx, placeID, "")
	if err != nil {
		return nil, fmt.Errorf("get place: %w", err)
	}
	if place == nil {
		return nil, ErrPlaceNotFound
	}

	if !place.IsOwnedBy(userID) && !hasRole(roles, "manager") {
		return nil, ErrAccessDenied
	}

	return u.updatePlaceRecord(ctx, place, input)
}

func (u *PlaceUseCase) UpdatePlaceByAdmin(ctx context.Context, placeID uuid.UUID, input UpdatePlaceInput) (*PlaceView, error) {
	place, err := u.repo.GetPlaceByID(ctx, placeID, "")
	if err != nil {
		return nil, fmt.Errorf("get place: %w", err)
	}
	if place == nil {
		return nil, ErrPlaceNotFound
	}
	return u.updatePlaceRecord(ctx, place, input)
}

func (u *PlaceUseCase) updatePlaceRecord(ctx context.Context, place *model.Place, input UpdatePlaceInput) (*PlaceView, error) {
	category := enum.PlaceCategory(strings.ToUpper(strings.TrimSpace(input.Category)))
	if !category.IsValid() {
		return nil, ErrInvalidCategory
	}

	status := enum.PlaceStatus(strings.ToUpper(strings.TrimSpace(input.Status)))
	if !status.IsValid() {
		return nil, ErrInvalidStatus
	}

	defaultLocale, translations, title, desc, err := normalizePlaceTranslations(
		input.DefaultLocale,
		input.Title,
		input.Description,
		input.Translations,
		place,
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
	accessCities, err := normalizePlaceCityLinks(countryCode, cityID, input.AccessCities, "ACCESS")
	if err != nil {
		return nil, err
	}
	departureCities, err := normalizePlaceCityLinks(countryCode, cityID, input.DepartureCities, "DEPARTURE")
	if err != nil {
		return nil, err
	}

	if err = validatePrice(input.PriceAmount, input.PriceCurrency); err != nil {
		return nil, err
	}
	if err = validateDuration(input.DurationValue, input.DurationUnit); err != nil {
		return nil, err
	}
	latitude := place.Latitude
	longitude := place.Longitude
	locationSourceURL := place.LocationSourceURL
	if input.Latitude != nil || input.Longitude != nil || strings.TrimSpace(input.LocationSourceURL) != "" {
		locationSourceURL, err = normalizeLocation(input.Latitude, input.Longitude, input.LocationSourceURL)
		if err != nil {
			return nil, err
		}
		latitude = input.Latitude
		longitude = input.Longitude
	}

	place.Title = title
	place.Description = desc
	place.DefaultLocale = defaultLocale
	place.Locale = defaultLocale
	place.Translations = translations
	place.CountryCode = countryCode
	place.CityID = cityID
	place.AccessCities = accessCities
	place.DepartureCities = departureCities
	place.Latitude = latitude
	place.Longitude = longitude
	place.LocationSourceURL = locationSourceURL
	place.Category = category
	place.PriceAmount = input.PriceAmount
	place.PriceCurrency = input.PriceCurrency
	place.DurationValue = input.DurationValue
	place.Spots = input.Spots
	place.Status = status
	place.Tags = normalizeTags(input.Tags)
	visitInfo, err := normalizeVisitInfo(input.VisitInfo, &place.VisitInfo)
	if err != nil {
		return nil, err
	}
	place.VisitInfo = visitInfo
	place.UpdatedAt = time.Now().UTC()
	setPlaceCityLinkTimestamps(place.AccessCities, place.UpdatedAt)
	setPlaceCityLinkTimestamps(place.DepartureCities, place.UpdatedAt)

	if input.DurationUnit != nil {
		du := enum.DurationUnit(strings.ToUpper(*input.DurationUnit))
		place.DurationUnit = &du
	} else {
		place.DurationUnit = nil
	}

	if err = u.repo.UpdatePlace(ctx, place); err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, ErrPlaceNotFound
		}
		return nil, fmt.Errorf("update place: %w", err)
	}
	u.bumpPlaceCacheVersion(ctx, place.ID)

	return u.toPlaceView(ctx, place)
}

func (u *PlaceUseCase) DeletePlace(ctx context.Context, subject string, placeID uuid.UUID, roles []string) error {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return err
	}

	place, err := u.repo.GetPlaceByID(ctx, placeID, "")
	if err != nil {
		return fmt.Errorf("get place: %w", err)
	}
	if place == nil {
		return ErrPlaceNotFound
	}

	if !place.IsOwnedBy(userID) && !hasRole(roles, "manager") {
		return ErrAccessDenied
	}

	if err = u.repo.SoftDeletePlace(ctx, placeID); err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return ErrPlaceNotFound
		}
		return fmt.Errorf("delete place: %w", err)
	}
	u.bumpPlaceCacheVersion(ctx, placeID)
	return nil
}

func (u *PlaceUseCase) RecoverPlace(ctx context.Context, placeID uuid.UUID, roles []string) (*PlaceView, error) {
	if !hasRole(roles, "manager") {
		return nil, ErrAccessDenied
	}

	if err := u.repo.RecoverPlace(ctx, placeID); err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, ErrPlaceNotFound
		}
		return nil, fmt.Errorf("recover place: %w", err)
	}
	u.bumpPlaceCacheVersion(ctx, placeID)

	place, err := u.repo.GetPlaceByID(ctx, placeID, "")
	if err != nil {
		return nil, fmt.Errorf("get recovered place: %w", err)
	}
	return u.toPlaceView(ctx, place)
}

func (u *PlaceUseCase) GetPlace(ctx context.Context, placeID uuid.UUID, locale string) (*PlaceView, error) {
	normalizedLocale := NormalizePlaceLocale(locale)
	detailCacheKey, detailCacheOK := u.placeDetailCacheKey(ctx, placeID, normalizedLocale)
	if detailCacheOK {
		cacheKey := detailCacheKey
		place, hit, err := u.cache.GetPlace(ctx, cacheKey)
		if err == nil && hit && place != nil {
			return u.toPlaceView(ctx, place)
		}
	}

	place, err := u.repo.GetPlaceByID(ctx, placeID, normalizedLocale)
	if err != nil {
		return nil, fmt.Errorf("get place: %w", err)
	}
	if place == nil {
		return nil, ErrPlaceNotFound
	}
	if detailCacheOK {
		_ = u.cache.SetPlace(ctx, detailCacheKey, place, u.detailCacheTTL)
	}
	return u.toPlaceView(ctx, place)
}

func (u *PlaceUseCase) ListPlaces(ctx context.Context, input ListPlacesInput) ([]*PlaceView, int, error) {
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
	regionID, err := normalizeOptionalCityID(input.RegionID)
	if err != nil {
		return nil, 0, err
	}
	if regionID == "" && countryCode == "ID" && cityID == "bali" {
		regionID = "bali"
		cityID = ""
	}
	if regionID == "" && countryCode == "CN" && cityID == "hainan" {
		regionID = "hainan"
		cityID = ""
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

	filter := model.PlaceListFilter{
		Search:          input.Search,
		Locale:          NormalizePlaceLocale(input.Locale),
		Category:        strings.ToUpper(strings.TrimSpace(input.Category)),
		CountryCode:     countryCode,
		CityID:          cityID,
		RegionID:        regionID,
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

	listCacheKey, listCacheOK := u.placeListCacheKey(ctx, filter)
	if listCacheOK {
		cacheKey := listCacheKey
		places, total, hit, cacheErr := u.cache.GetPlaceList(ctx, cacheKey)
		if cacheErr == nil && hit {
			return u.placesToViews(ctx, places, total)
		}
	}

	places, total, err := u.repo.ListPlaces(ctx, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("list places: %w", err)
	}

	if listCacheOK {
		_ = u.cache.SetPlaceList(ctx, listCacheKey, places, total, u.listCacheTTL)
	}

	return u.placesToViews(ctx, places, total)
}

func (u *PlaceUseCase) placesToViews(ctx context.Context, places []*model.Place, total int) ([]*PlaceView, int, error) {
	views := make([]*PlaceView, 0, len(places))
	for _, a := range places {
		v, vErr := u.toPlaceView(ctx, a)
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

func (u *PlaceUseCase) ReplacePlaceMedia(ctx context.Context, subject string, placeID uuid.UUID, media []ReplaceMediaInput, roles []string) error {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return err
	}

	place, err := u.repo.GetPlaceByID(ctx, placeID, "")
	if err != nil {
		return fmt.Errorf("get place: %w", err)
	}
	if place == nil {
		return ErrPlaceNotFound
	}
	if !place.IsOwnedBy(userID) && !hasRole(roles, "manager") {
		return ErrAccessDenied
	}

	return u.replacePlaceMedia(ctx, placeID, media)
}

func (u *PlaceUseCase) ReplacePlaceMediaByAdmin(ctx context.Context, placeID uuid.UUID, media []ReplaceMediaInput) error {
	place, err := u.repo.GetPlaceByID(ctx, placeID, "")
	if err != nil {
		return fmt.Errorf("get place: %w", err)
	}
	if place == nil {
		return ErrPlaceNotFound
	}
	return u.replacePlaceMedia(ctx, placeID, media)
}

func (u *PlaceUseCase) replacePlaceMedia(ctx context.Context, placeID uuid.UUID, media []ReplaceMediaInput) error {
	now := time.Now().UTC()
	models := make([]model.PlaceMedia, 0, len(media))
	for _, m := range media {
		mt, mediaErr := normalizeMediaType(m.MediaType)
		if mediaErr != nil {
			return mediaErr
		}
		models = append(models, model.PlaceMedia{
			ID:          uuid.New(),
			PlaceID:     placeID,
			FileID:      m.FileID,
			ExternalURL: strings.TrimSpace(m.ExternalURL),
			SourceURL:   strings.TrimSpace(m.SourceURL),
			Credit:      strings.TrimSpace(m.Credit),
			License:     strings.TrimSpace(m.License),
			MediaType:   mt,
			Position:    m.Position,
			CreatedAt:   now,
		})
	}

	if err := u.repo.ReplacePlaceMedia(ctx, placeID, models); err != nil {
		return err
	}
	u.bumpPlaceCacheVersion(ctx, placeID)
	return nil
}

// ---------------------------------------------------------------------------
// Reviews
// ---------------------------------------------------------------------------

func (u *PlaceUseCase) CreateReview(ctx context.Context, subject string, placeID uuid.UUID, input CreateReviewInput, media []ReplaceMediaInput) (*ReviewView, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	place, err := u.repo.GetPlaceByID(ctx, placeID, "")
	if err != nil {
		return nil, fmt.Errorf("get place: %w", err)
	}
	if place == nil {
		return nil, ErrPlaceNotFound
	}
	if place.IsDeleted() {
		return nil, ErrPlaceDeleted
	}
	if !place.IsPublished() {
		return nil, ErrPlaceNotPublished
	}
	if place.IsOwnedBy(authorUserID) {
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
	review := &model.PlaceReview{
		ID:           uuid.New(),
		PlaceID:      placeID,
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
	u.bumpPlaceCacheVersion(ctx, placeID)

	return u.toReviewView(ctx, review)
}

func (u *PlaceUseCase) DeleteReview(ctx context.Context, subject string, reviewID uuid.UUID) error {
	userID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return err
	}

	review, _ := u.repo.GetReviewByID(ctx, reviewID)
	if err = u.repo.SoftDeleteReview(ctx, reviewID, userID); err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return ErrReviewNotFound
		}
		return fmt.Errorf("delete review: %w", err)
	}
	if review != nil {
		u.bumpPlaceCacheVersion(ctx, review.PlaceID)
	} else {
		u.bumpPlaceListCacheVersion(ctx)
	}
	return nil
}

func (u *PlaceUseCase) RecalculateRating(ctx context.Context, placeID uuid.UUID) (float64, int, error) {
	if placeID == uuid.Nil {
		return 0, 0, ErrPlaceNotFound
	}
	rating, reviewCount, err := u.repo.RecalcRating(ctx, placeID)
	if err != nil {
		return 0, 0, fmt.Errorf("recalculate place rating: %w", err)
	}
	u.bumpPlaceCacheVersion(ctx, placeID)
	return rating, reviewCount, nil
}

type RatingSourceSnapshotInput struct {
	PlaceID     uuid.UUID
	Source      string
	RatingAvg   float64
	ReviewCount int
}

func (u *PlaceUseCase) ApplyRatingSourceSnapshot(ctx context.Context, input RatingSourceSnapshotInput) (float64, int, error) {
	if input.PlaceID == uuid.Nil {
		return 0, 0, ErrPlaceNotFound
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
		input.PlaceID,
		source,
		input.RatingAvg,
		input.ReviewCount,
	)
	if err != nil {
		return 0, 0, fmt.Errorf("apply place rating source snapshot: %w", err)
	}
	u.bumpPlaceCacheVersion(ctx, input.PlaceID)
	return rating, reviewCount, nil
}

func (u *PlaceUseCase) ListReviews(ctx context.Context, placeID uuid.UUID, limit, offset int) ([]*ReviewView, int, error) {
	if limit <= 0 {
		limit = defaultReviewLimit
	}
	if limit > maxListLimit {
		limit = maxListLimit
	}
	if offset < 0 {
		offset = 0
	}

	reviews, total, err := u.repo.ListReviews(ctx, placeID, limit, offset)
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

func (u *PlaceUseCase) GetMyReview(ctx context.Context, subject string, placeID uuid.UUID) (*ReviewView, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	place, err := u.repo.GetPlaceByID(ctx, placeID, "")
	if err != nil {
		return nil, fmt.Errorf("get place: %w", err)
	}
	if place == nil {
		return nil, ErrPlaceNotFound
	}

	review, err := u.repo.GetReviewByPlaceAndAuthor(ctx, placeID, authorUserID)
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

type placeListCacheKeyPayload struct {
	Search          string   `json:"search,omitempty"`
	Locale          string   `json:"locale,omitempty"`
	Category        string   `json:"category,omitempty"`
	CountryCode     string   `json:"countryCode,omitempty"`
	CityID          string   `json:"cityId,omitempty"`
	RegionID        string   `json:"regionId,omitempty"`
	AccessCityID    string   `json:"accessCityId,omitempty"`
	DepartureCityID string   `json:"departureCityId,omitempty"`
	PriceMin        *float64 `json:"priceMin,omitempty"`
	PriceMax        *float64 `json:"priceMax,omitempty"`
	DurationMin     *int     `json:"durationMin,omitempty"`
	DurationMax     *int     `json:"durationMax,omitempty"`
	DurationUnit    *string  `json:"durationUnit,omitempty"`
	SpotsMin        *int     `json:"spotsMin,omitempty"`
	MinRating       *float64 `json:"minRating,omitempty"`
	AuthorUserID    string   `json:"authorUserId,omitempty"`
	IncludeDeleted  bool     `json:"includeDeleted,omitempty"`
	Sort            string   `json:"sort,omitempty"`
	Limit           int      `json:"limit"`
	Offset          int      `json:"offset"`
}

func (u *PlaceUseCase) placeDetailCacheKey(ctx context.Context, placeID uuid.UUID, locale string) (string, bool) {
	if u.cache == nil || u.detailCacheTTL <= 0 || placeID == uuid.Nil {
		return "", false
	}
	version, err := u.cache.CurrentVersion(ctx, placeItemCacheVersionScope(placeID))
	if err != nil {
		return "", false
	}
	if version < 0 {
		version = 0
	}
	return fmt.Sprintf("place:v1:item:%s:%s:%d", placeID.String(), locale, version), true
}

func (u *PlaceUseCase) placeListCacheKey(ctx context.Context, filter model.PlaceListFilter) (string, bool) {
	if u.cache == nil || u.listCacheTTL <= 0 {
		return "", false
	}
	version, err := u.cache.CurrentVersion(ctx, placeListCacheVersionScope)
	if err != nil {
		return "", false
	}
	if version < 0 {
		version = 0
	}

	payload := placeListCacheKeyPayload{
		Search:          strings.TrimSpace(filter.Search),
		Locale:          filter.Locale,
		Category:        filter.Category,
		CountryCode:     filter.CountryCode,
		CityID:          filter.CityID,
		RegionID:        filter.RegionID,
		AccessCityID:    filter.AccessCityID,
		DepartureCityID: filter.DepartureCityID,
		PriceMin:        filter.PriceMin,
		PriceMax:        filter.PriceMax,
		DurationMin:     filter.DurationMin,
		DurationMax:     filter.DurationMax,
		SpotsMin:        filter.SpotsMin,
		MinRating:       filter.MinRating,
		IncludeDeleted:  filter.IncludeDeleted,
		Sort:            strings.TrimSpace(filter.Sort),
		Limit:           filter.Limit,
		Offset:          filter.Offset,
	}
	if filter.DurationUnit != nil {
		durationUnit := string(*filter.DurationUnit)
		payload.DurationUnit = &durationUnit
	}
	if filter.AuthorUserID != nil {
		payload.AuthorUserID = filter.AuthorUserID.String()
	}

	encoded, err := json.Marshal(payload)
	if err != nil {
		return "", false
	}
	sum := sha256.Sum256(encoded)
	return fmt.Sprintf("place:v1:list:%d:%s", version, hex.EncodeToString(sum[:16])), true
}

func (u *PlaceUseCase) bumpPlaceCacheVersion(ctx context.Context, placeID uuid.UUID) {
	if u.cache == nil {
		return
	}
	scopes := []string{placeListCacheVersionScope}
	if placeID != uuid.Nil {
		scopes = append(scopes, placeItemCacheVersionScope(placeID))
	}
	_ = u.cache.BumpVersion(ctx, scopes...)
}

func (u *PlaceUseCase) bumpPlaceListCacheVersion(ctx context.Context) {
	if u.cache == nil {
		return
	}
	_ = u.cache.BumpVersion(ctx, placeListCacheVersionScope)
}

func placeItemCacheVersionScope(placeID uuid.UUID) string {
	return "place:item:" + placeID.String()
}

func (u *PlaceUseCase) requireUserID(ctx context.Context, subject string) (uuid.UUID, error) {
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

func (u *PlaceUseCase) toPlaceView(ctx context.Context, place *model.Place) (*PlaceView, error) {
	author := PlaceAuthor{UserID: place.AuthorUserID}

	profiles, err := u.users.GetPublicUserProfiles(ctx, []uuid.UUID{place.AuthorUserID})
	if err == nil {
		if p, ok := profiles[place.AuthorUserID]; ok {
			author.Nickname = p.Nickname
			author.AvatarFileID = p.AvatarFileID
		}
	}

	return &PlaceView{
		Place:  place,
		Author: author,
	}, nil
}

func (u *PlaceUseCase) toReviewView(ctx context.Context, review *model.PlaceReview) (*ReviewView, error) {
	author := PlaceAuthor{UserID: review.AuthorUserID}

	profiles, err := u.users.GetPublicUserProfiles(ctx, []uuid.UUID{review.AuthorUserID})
	if err == nil {
		if p, ok := profiles[review.AuthorUserID]; ok {
			author.Nickname = p.Nickname
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

func normalizePlaceTranslations(
	rawDefaultLocale string,
	legacyTitle string,
	legacyDescription string,
	input map[string]PlaceTranslationInput,
	existing *model.Place,
) (string, map[string]model.PlaceTranslation, string, string, error) {
	defaultLocaleRaw := rawDefaultLocale
	if strings.TrimSpace(defaultLocaleRaw) == "" && existing != nil {
		defaultLocaleRaw = existing.DefaultLocale
	}

	defaultLocale, ok := normalizePlaceLocale(defaultLocaleRaw)
	if !ok {
		return "", nil, "", "", ErrInvalidLocale
	}

	translations := make(map[string]model.PlaceTranslation)
	if existing != nil {
		for locale, translation := range existing.Translations {
			normalizedLocale, localeOK := normalizePlaceLocale(locale)
			if !localeOK {
				continue
			}
			translation.Locale = normalizedLocale
			translations[normalizedLocale] = translation
		}
		if len(translations) == 0 && strings.TrimSpace(existing.Title) != "" {
			locale := NormalizePlaceLocale(existing.Locale)
			translations[locale] = model.PlaceTranslation{
				PlaceID:     existing.ID,
				Locale:      locale,
				Title:       strings.TrimSpace(existing.Title),
				Description: strings.TrimSpace(existing.Description),
			}
		}
	}

	for rawLocale, translationInput := range input {
		locale, localeOK := normalizePlaceLocale(rawLocale)
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

func normalizeTranslationInput(locale string, title string, description string) (model.PlaceTranslation, error) {
	title = strings.TrimSpace(title)
	if title == "" || utf8.RuneCountInString(title) > maxTitleChars {
		return model.PlaceTranslation{}, ErrInvalidTitle
	}

	return model.PlaceTranslation{
		Locale:      locale,
		Title:       title,
		Description: trimDescription(description),
	}, nil
}

func normalizePlaceLocale(raw string) (string, bool) {
	raw = strings.ToLower(strings.TrimSpace(raw))
	if raw == "" {
		return fallbackPlaceLocale, true
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

func normalizePlaceCityLinks(
	defaultCountryCode string,
	defaultCityID string,
	inputs []PlaceCityLinkInput,
	kind string,
) ([]model.PlaceCityLink, error) {
	if len(inputs) == 0 && defaultCityID != "" {
		inputs = []PlaceCityLinkInput{{CountryCode: defaultCountryCode, CityID: defaultCityID}}
	}
	seen := make(map[string]struct{}, len(inputs))
	result := make([]model.PlaceCityLink, 0, len(inputs))
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
		result = append(result, model.PlaceCityLink{
			Kind:        kind,
			CountryCode: normalizedCountryCode,
			CityID:      cityID,
			Position:    len(result),
		})
	}
	return result, nil
}

func setPlaceCityLinkTimestamps(items []model.PlaceCityLink, createdAt time.Time) {
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

func normalizeVisitInfo(input *PlaceVisitInfoInput, existing *model.PlaceVisitInfo) (model.PlaceVisitInfo, error) {
	if input == nil {
		if existing != nil {
			return *existing, nil
		}
		return model.PlaceVisitInfo{}, nil
	}

	nearbyIDs := make([]uuid.UUID, 0, len(input.NearbyIDs))
	for _, raw := range input.NearbyIDs {
		raw = strings.TrimSpace(raw)
		if raw == "" {
			continue
		}
		id, err := uuid.Parse(raw)
		if err != nil {
			return model.PlaceVisitInfo{}, ErrInvalidVisitInfo
		}
		nearbyIDs = append(nearbyIDs, id)
		if len(nearbyIDs) >= maxVisitInfoItems {
			break
		}
	}

	tips := normalizeLocalizedTips(input.LocalizedTips)

	return model.PlaceVisitInfo{
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
		locale, ok := normalizePlaceLocale(rawLocale)
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
