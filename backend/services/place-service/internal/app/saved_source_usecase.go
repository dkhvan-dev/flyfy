package app

import (
	"context"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

const (
	savedSourceTitleMaxRunes           = 200
	savedSourceSubtitleMaxRunes        = 280
	savedSourceCityMaxRunes            = 64
	savedSourceCountryMaxRunes         = 2
	savedSourceDisplayLocationMaxRunes = 72
	savedSourceMediaTTL                = 5 * time.Minute
)

var (
	ErrSavedSourceUnavailable = errors.New("saved attraction source unavailable")
	ErrAttractionNotFound     = errors.New("attraction not found")
)

type SavedSourceVisibility string

const (
	SavedSourceVisibilityPublic      SavedSourceVisibility = "PUBLIC"
	SavedSourceVisibilityUnavailable SavedSourceVisibility = "UNAVAILABLE"
	SavedSourceVisibilityDeleted     SavedSourceVisibility = "DELETED"
	SavedSourceVisibilityRestricted  SavedSourceVisibility = "RESTRICTED"
)

type SavedSourceRepository interface {
	GetSavedSourceAttraction(
		ctx context.Context,
		attractionID uuid.UUID,
	) (*model.SavedAttractionSnapshot, error)
}

type SavedSourceLocalizedProjection struct {
	Title           string
	Subtitle        string
	City            string
	Country         string
	DisplayLocation string
}

type SavedSourceRatingSummary struct {
	Value       float64
	ReviewCount uint64
	ScaleMax    float64
}

type SavedSourceMediaReference struct {
	OpaqueReference   string
	ReferenceRevision uint64
	ValidUntil        time.Time
}

type SavedSourcePublicProjection struct {
	SourceDefaultLocale  string
	Localized            map[string]SavedSourceLocalizedProjection
	Rating               *SavedSourceRatingSummary
	AsOf                 *time.Time
	CanonicalDetailRoute string
	Media                *SavedSourceMediaReference
}

type SavedSourceResolution struct {
	Eligible           bool
	Visibility         SavedSourceVisibility
	SourceRevision     uint64
	ProjectionRevision uint64
	VisibilityRevision uint64
	ValidatedAt        time.Time
	PublicProjection   *SavedSourcePublicProjection
}

type SavedSourceUseCase struct {
	repo SavedSourceRepository
	now  func() time.Time
}

type SavedSourceUseCaseOption func(*SavedSourceUseCase)

func WithSavedSourceClock(now func() time.Time) SavedSourceUseCaseOption {
	return func(useCase *SavedSourceUseCase) {
		if now != nil {
			useCase.now = now
		}
	}
}

func NewSavedSourceUseCase(
	repo SavedSourceRepository,
	options ...SavedSourceUseCaseOption,
) *SavedSourceUseCase {
	useCase := &SavedSourceUseCase{
		repo: repo,
		now:  time.Now,
	}
	for _, option := range options {
		if option != nil {
			option(useCase)
		}
	}
	return useCase
}

func (u *SavedSourceUseCase) ResolveAttraction(
	ctx context.Context,
	attractionID uuid.UUID,
) (*SavedSourceResolution, error) {
	if attractionID == uuid.Nil {
		return nil, ErrInvalidPlaceID
	}
	if u == nil || u.repo == nil || u.now == nil {
		return nil, ErrSavedSourceUnavailable
	}

	snapshot, err := u.repo.GetSavedSourceAttraction(ctx, attractionID)
	if err != nil {
		return nil, fmt.Errorf("%w: load attraction snapshot: %w", ErrSavedSourceUnavailable, err)
	}
	if snapshot == nil {
		return nil, ErrAttractionNotFound
	}
	if snapshot.ID != attractionID {
		return nil, fmt.Errorf("%w: repository returned a different attraction", ErrSavedSourceUnavailable)
	}
	if snapshot.SourceRevision == 0 ||
		snapshot.ProjectionRevision == 0 ||
		snapshot.VisibilityRevision == 0 {
		return nil, fmt.Errorf("%w: source revisions must be positive", ErrSavedSourceUnavailable)
	}

	validatedAt := u.now().UTC()
	if validatedAt.IsZero() {
		return nil, fmt.Errorf("%w: validation time is unavailable", ErrSavedSourceUnavailable)
	}
	resolution := &SavedSourceResolution{
		Visibility:         savedAttractionVisibility(snapshot),
		SourceRevision:     snapshot.SourceRevision,
		ProjectionRevision: snapshot.ProjectionRevision,
		VisibilityRevision: snapshot.VisibilityRevision,
		ValidatedAt:        validatedAt,
	}
	if resolution.Visibility != SavedSourceVisibilityPublic {
		return resolution, nil
	}

	projection, ok := savedAttractionPublicProjection(snapshot, validatedAt)
	if !ok {
		resolution.Visibility = SavedSourceVisibilityUnavailable
		return resolution, nil
	}
	resolution.Eligible = true
	resolution.PublicProjection = projection
	return resolution, nil
}

func savedAttractionVisibility(snapshot *model.SavedAttractionSnapshot) SavedSourceVisibility {
	if snapshot == nil {
		return SavedSourceVisibilityUnavailable
	}
	if snapshot.DeletedAt != nil {
		return SavedSourceVisibilityDeleted
	}
	if snapshot.Status != enum.StatusPublished {
		return SavedSourceVisibilityRestricted
	}
	return SavedSourceVisibilityPublic
}

func savedAttractionPublicProjection(
	snapshot *model.SavedAttractionSnapshot,
	validatedAt time.Time,
) (*SavedSourcePublicProjection, bool) {
	defaultLocale, ok := normalizePlaceLocale(snapshot.DefaultLocale)
	if !ok {
		return nil, false
	}

	localized := make(map[string]SavedSourceLocalizedProjection, 3)
	for _, locale := range []string{"en", "ru", "kk"} {
		translation, exists := snapshot.Translations[locale]
		if !exists {
			continue
		}
		if translation.PlaceID != uuid.Nil && translation.PlaceID != snapshot.ID {
			return nil, false
		}
		if normalized, localeOK := normalizePlaceLocale(translation.Locale); !localeOK || normalized != locale {
			return nil, false
		}

		title := boundedSavedSourceText(translation.Title, savedSourceTitleMaxRunes)
		if title == "" {
			continue
		}
		city := boundedSavedSourceText(snapshot.CityID, savedSourceCityMaxRunes)
		country := boundedSavedSourceText(snapshot.CountryCode, savedSourceCountryMaxRunes)
		localized[locale] = SavedSourceLocalizedProjection{
			Title:           title,
			Subtitle:        boundedSavedSourceText(translation.Description, savedSourceSubtitleMaxRunes),
			City:            city,
			Country:         country,
			DisplayLocation: savedSourceDisplayLocation(city, country),
		}
	}
	if _, exists := localized[defaultLocale]; !exists {
		return nil, false
	}

	projection := &SavedSourcePublicProjection{
		SourceDefaultLocale:  defaultLocale,
		Localized:            localized,
		CanonicalDetailRoute: "/places/" + snapshot.ID.String(),
	}
	if snapshot.ReviewCount > 0 &&
		snapshot.Rating >= 0 && snapshot.Rating <= 5 &&
		!math.IsNaN(snapshot.Rating) && !math.IsInf(snapshot.Rating, 0) {
		asOf := validatedAt
		projection.AsOf = &asOf
		projection.Rating = &SavedSourceRatingSummary{
			Value:       snapshot.Rating,
			ReviewCount: uint64(snapshot.ReviewCount),
			ScaleMax:    5,
		}
	}
	if hasSavedAttractionCover(snapshot.Media) {
		projection.Media = &SavedSourceMediaReference{
			OpaqueReference: fmt.Sprintf(
				"attraction-cover:%s:%d",
				snapshot.ID,
				snapshot.ProjectionRevision,
			),
			ReferenceRevision: snapshot.ProjectionRevision,
			ValidUntil:        validatedAt.Add(savedSourceMediaTTL),
		}
	}
	return projection, true
}

func hasSavedAttractionCover(media []model.PlaceMedia) bool {
	for _, item := range media {
		if item.MediaType != enum.MediaPhoto {
			continue
		}
		if item.FileID != uuid.Nil {
			return true
		}
		if _, err := validatePublicSavedCoverExternalURL(item.ExternalURL); err == nil {
			return true
		}
	}
	return false
}

func savedSourceDisplayLocation(city, country string) string {
	parts := make([]string, 0, 2)
	if city != "" {
		parts = append(parts, city)
	}
	if country != "" && !strings.EqualFold(city, country) {
		parts = append(parts, country)
	}
	return boundedSavedSourceText(
		strings.Join(parts, ", "),
		savedSourceDisplayLocationMaxRunes,
	)
}

func boundedSavedSourceText(value string, maxRunes int) string {
	value = strings.Join(strings.Fields(value), " ")
	if value == "" || maxRunes <= 0 {
		return ""
	}
	if utf8.RuneCountInString(value) <= maxRunes {
		return value
	}
	return strings.TrimSpace(string([]rune(value)[:maxRunes]))
}
