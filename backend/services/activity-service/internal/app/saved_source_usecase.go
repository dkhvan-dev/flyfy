package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

const (
	savedSourceTitleMaxRunes           = 200
	savedSourceSubtitleMaxRunes        = 280
	savedSourceCityMaxRunes            = 120
	savedSourceDisplayLocationMaxRunes = 200
	savedSourceMediaTTL                = 5 * time.Minute
)

var ErrSavedSourceUnavailable = errors.New("saved source unavailable")

type SavedSourceVisibility string

const (
	SavedSourceVisibilityPublic      SavedSourceVisibility = "PUBLIC"
	SavedSourceVisibilityPrivate     SavedSourceVisibility = "PRIVATE"
	SavedSourceVisibilityUnavailable SavedSourceVisibility = "UNAVAILABLE"
	SavedSourceVisibilityDeleted     SavedSourceVisibility = "DELETED"
	SavedSourceVisibilityRestricted  SavedSourceVisibility = "RESTRICTED"
)

type SavedSourceRepository interface {
	GetSavedSourceActivity(
		ctx context.Context,
		activityID uuid.UUID,
	) (*model.Activity, []*model.ActivityMedia, error)
}

type SavedSourceLocalizedProjection struct {
	Title           string
	Subtitle        string
	City            string
	Country         string
	DisplayLocation string
}

type SavedSourceMediaReference struct {
	OpaqueReference   string
	ReferenceRevision uint64
	ValidUntil        time.Time
}

type SavedSourcePublicProjection struct {
	SourceDefaultLocale  string
	Localized            map[string]SavedSourceLocalizedProjection
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
	return func(u *SavedSourceUseCase) {
		if now != nil {
			u.now = now
		}
	}
}

func NewSavedSourceUseCase(
	repo SavedSourceRepository,
	opts ...SavedSourceUseCaseOption,
) *SavedSourceUseCase {
	u := &SavedSourceUseCase{
		repo: repo,
		now:  time.Now,
	}
	for _, opt := range opts {
		opt(u)
	}
	return u
}

func (u *SavedSourceUseCase) ResolveActivity(
	ctx context.Context,
	activityID uuid.UUID,
) (*SavedSourceResolution, error) {
	if activityID == uuid.Nil {
		return nil, ErrInvalidActivityID
	}
	if u == nil || u.repo == nil {
		return nil, ErrSavedSourceUnavailable
	}

	item, media, err := u.repo.GetSavedSourceActivity(ctx, activityID)
	if err != nil {
		return nil, fmt.Errorf("%w: load activity snapshot: %w", ErrSavedSourceUnavailable, err)
	}
	if item == nil {
		return nil, ErrActivityNotFound
	}
	if item.ID != activityID {
		return nil, fmt.Errorf("%w: repository returned a different activity", ErrSavedSourceUnavailable)
	}
	sourceRevision, projectionRevision, visibilityRevision, ok := SavedSourceRevisionVector(item)
	if !ok {
		return nil, fmt.Errorf("%w: activity Saved revisions must be positive", ErrSavedSourceUnavailable)
	}

	validatedAt := u.now().UTC()
	visibility, projection := ResolveSavedSourceSnapshot(item, media, validatedAt)
	result := &SavedSourceResolution{
		Visibility:         visibility,
		SourceRevision:     sourceRevision,
		ProjectionRevision: projectionRevision,
		VisibilityRevision: visibilityRevision,
		ValidatedAt:        validatedAt,
	}
	if result.Visibility != SavedSourceVisibilityPublic {
		return result, nil
	}
	result.Eligible = true
	result.PublicProjection = projection
	return result, nil
}

// ResolveSavedSourceSnapshot is shared by the synchronous resolver and the
// transactional lifecycle outbox so both surfaces apply identical visibility
// and projection rules.
func ResolveSavedSourceSnapshot(
	item *model.Activity,
	media []*model.ActivityMedia,
	validatedAt time.Time,
) (SavedSourceVisibility, *SavedSourcePublicProjection) {
	visibility := savedSourceActivityVisibility(item)
	if visibility != SavedSourceVisibilityPublic {
		return visibility, nil
	}
	projection, ok := savedSourcePublicProjection(item, media, validatedAt)
	if !ok {
		return SavedSourceVisibilityRestricted, nil
	}
	return SavedSourceVisibilityPublic, projection
}

func SavedSourceRevisionVector(item *model.Activity) (uint64, uint64, uint64, bool) {
	if item == nil || item.Revision <= 0 {
		return 0, 0, 0, false
	}
	fallback := uint64(item.Revision)
	sourceRevision := item.SavedSourceRevision
	if sourceRevision == 0 {
		sourceRevision = fallback
	}
	projectionRevision := item.SavedProjectionRevision
	if projectionRevision == 0 {
		projectionRevision = fallback
	}
	visibilityRevision := item.SavedVisibilityRevision
	if visibilityRevision == 0 {
		visibilityRevision = fallback
	}
	return sourceRevision, projectionRevision, visibilityRevision,
		sourceRevision > 0 && projectionRevision > 0 && visibilityRevision > 0
}

func savedSourceActivityVisibility(item *model.Activity) SavedSourceVisibility {
	if item == nil {
		return SavedSourceVisibilityUnavailable
	}
	switch item.Visibility {
	case enum.ActivityVisibilityPrivate:
		return SavedSourceVisibilityPrivate
	case enum.ActivityVisibilityUnlisted:
		return SavedSourceVisibilityRestricted
	case enum.ActivityVisibilityPublic:
	default:
		return SavedSourceVisibilityRestricted
	}

	if item.Status == enum.ActivityStatusArchived {
		return SavedSourceVisibilityDeleted
	}
	if item.Status == enum.ActivityStatusCancelled || item.CancelledAt != nil {
		return SavedSourceVisibilityUnavailable
	}
	if !isActivityPubliclyAccessible(item) {
		return SavedSourceVisibilityRestricted
	}
	return SavedSourceVisibilityPublic
}

func savedSourcePublicProjection(
	item *model.Activity,
	media []*model.ActivityMedia,
	validatedAt time.Time,
) (*SavedSourcePublicProjection, bool) {
	sourceLocale, ok := model.NormalizeActivityTranslationLanguage(item.SourceLanguage)
	if !ok {
		return nil, false
	}

	translations := model.NormalizeActivityTranslations(item.Translations)
	if sourceCopy, exists := translations[sourceLocale]; !exists || strings.TrimSpace(sourceCopy.Title) == "" {
		translations[sourceLocale] = model.ActivityLocalizedCopy{
			Title:       item.Title,
			Description: item.Description,
		}
	}

	localized := make(map[string]SavedSourceLocalizedProjection, len(translations))
	for _, locale := range model.SupportedActivityTranslationLanguages() {
		copy, exists := translations[locale]
		if !exists {
			continue
		}
		title := boundedSavedSourceText(copy.Title, savedSourceTitleMaxRunes)
		if title == "" {
			continue
		}
		projection := SavedSourceLocalizedProjection{
			Title:    title,
			Subtitle: boundedSavedSourceText(copy.Description, savedSourceSubtitleMaxRunes),
		}
		if locale == sourceLocale {
			projection.City = boundedSavedSourceText(
				model.ValueOrEmpty(item.CityName),
				savedSourceCityMaxRunes,
			)
			projection.DisplayLocation = savedSourceDisplayLocation(item)
		}
		localized[locale] = projection
	}
	if _, exists := localized[sourceLocale]; !exists {
		return nil, false
	}

	projection := &SavedSourcePublicProjection{
		SourceDefaultLocale:  sourceLocale,
		Localized:            localized,
		CanonicalDetailRoute: "/activities/" + item.ID.String(),
	}
	if hasSavedSourceMedia(media, item.ID) {
		_, projectionRevision, _, ok := SavedSourceRevisionVector(item)
		if !ok {
			return nil, false
		}
		projection.Media = &SavedSourceMediaReference{
			OpaqueReference: fmt.Sprintf(
				"/api/v1/activities/%s/cover?saved_revision=%d",
				item.ID,
				projectionRevision,
			),
			ReferenceRevision: projectionRevision,
			ValidUntil:        validatedAt.Add(savedSourceMediaTTL),
		}
	}
	return projection, true
}

func savedSourceDisplayLocation(item *model.Activity) string {
	parts := make([]string, 0, 2)
	for _, value := range []string{
		model.ValueOrEmpty(item.CityName),
		model.ValueOrEmpty(item.AddressText),
	} {
		value = boundedSavedSourceText(value, savedSourceDisplayLocationMaxRunes)
		if value == "" || containsFold(parts, value) {
			continue
		}
		parts = append(parts, value)
	}
	return boundedSavedSourceText(
		strings.Join(parts, ", "),
		savedSourceDisplayLocationMaxRunes,
	)
}

func containsFold(values []string, target string) bool {
	for _, value := range values {
		if strings.EqualFold(value, target) {
			return true
		}
	}
	return false
}

func hasSavedSourceMedia(items []*model.ActivityMedia, activityID uuid.UUID) bool {
	for _, item := range items {
		if item != nil && item.ActivityID == activityID && item.FileID != uuid.Nil {
			return true
		}
	}
	return false
}

func boundedSavedSourceText(value string, maxRunes int) string {
	value = strings.Join(strings.Fields(value), " ")
	if value == "" || maxRunes <= 0 {
		return ""
	}
	if utf8.RuneCountInString(value) <= maxRunes {
		return value
	}
	runes := []rune(value)
	return strings.TrimSpace(string(runes[:maxRunes]))
}
