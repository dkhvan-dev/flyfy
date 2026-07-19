package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/enum"
	"kz/inflap/backend/services/user-service/internal/domain/model"
	"kz/inflap/backend/services/user-service/internal/domain/port"
)

const (
	savedUserTitleMaxRunes           = 200
	savedUserSubtitleMaxRunes        = 280
	savedUserDisplayLocationMaxRunes = 72
	savedUserMediaTTL                = 5 * time.Minute
)

var (
	ErrInvalidSavedUserID         = errors.New("invalid saved user id")
	ErrSavedUserNotFound          = errors.New("saved user not found")
	ErrSavedUserSourceUnavailable = errors.New("saved user source unavailable")
)

type SavedUserVisibility string

const (
	SavedUserVisibilityPublic      SavedUserVisibility = "PUBLIC"
	SavedUserVisibilityUnavailable SavedUserVisibility = "UNAVAILABLE"
	SavedUserVisibilityDeleted     SavedUserVisibility = "DELETED"
	SavedUserVisibilityRestricted  SavedUserVisibility = "RESTRICTED"
)

type SavedUserLocalizedProjection struct {
	Title           string
	Subtitle        string
	Country         string
	DisplayLocation string
}

type SavedUserMediaReference struct {
	OpaqueReference   string
	ReferenceRevision uint64
	ValidUntil        time.Time
}

type SavedUserPublicProjection struct {
	SourceDefaultLocale  string
	Localized            map[string]SavedUserLocalizedProjection
	CanonicalDetailRoute string
	Media                *SavedUserMediaReference
}

type SavedUserResolution struct {
	Eligible           bool
	Visibility         SavedUserVisibility
	SourceRevision     uint64
	ProjectionRevision uint64
	VisibilityRevision uint64
	ValidatedAt        time.Time
	PublicProjection   *SavedUserPublicProjection
}

type SavedUserSourceUseCase struct {
	repository port.UserRepository
	now        func() time.Time
}

type SavedUserSourceOption func(*SavedUserSourceUseCase)

func WithSavedUserSourceClock(now func() time.Time) SavedUserSourceOption {
	return func(useCase *SavedUserSourceUseCase) {
		if now != nil {
			useCase.now = now
		}
	}
}

func NewSavedUserSourceUseCase(
	repository port.UserRepository,
	options ...SavedUserSourceOption,
) *SavedUserSourceUseCase {
	useCase := &SavedUserSourceUseCase{repository: repository, now: time.Now}
	for _, option := range options {
		if option != nil {
			option(useCase)
		}
	}
	return useCase
}

func (useCase *SavedUserSourceUseCase) ResolveUser(
	ctx context.Context,
	userID uuid.UUID,
) (*SavedUserResolution, error) {
	if userID == uuid.Nil {
		return nil, ErrInvalidSavedUserID
	}
	if useCase == nil || useCase.repository == nil || useCase.now == nil || ctx == nil {
		return nil, ErrSavedUserSourceUnavailable
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}

	user, err := useCase.repository.GetUserByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("%w: load account: %v", ErrSavedUserSourceUnavailable, err)
	}
	if user == nil {
		return nil, ErrSavedUserNotFound
	}
	if user.ID != userID || !user.Status.IsValid() {
		return nil, fmt.Errorf("%w: invalid account snapshot", ErrSavedUserSourceUnavailable)
	}

	accountRevision, ok := savedUserRevision(user.UpdatedAt)
	if !ok {
		accountRevision, ok = savedUserRevision(user.CreatedAt)
	}
	if !ok {
		return nil, fmt.Errorf("%w: account revision is unavailable", ErrSavedUserSourceUnavailable)
	}
	validatedAt := useCase.now().UTC()
	if validatedAt.IsZero() {
		return nil, fmt.Errorf("%w: validation time is unavailable", ErrSavedUserSourceUnavailable)
	}
	resolution := &SavedUserResolution{
		Visibility:         SavedUserVisibilityUnavailable,
		SourceRevision:     accountRevision,
		ProjectionRevision: accountRevision,
		VisibilityRevision: accountRevision,
		ValidatedAt:        validatedAt,
	}
	if user.IsDeleted || user.Status == enum.UserStatusDeleted {
		resolution.Visibility = SavedUserVisibilityDeleted
		return resolution, nil
	}
	if user.Status == enum.UserStatusBlocked {
		resolution.Visibility = SavedUserVisibilityRestricted
		return resolution, nil
	}
	if user.Status != enum.UserStatusActive {
		return resolution, nil
	}

	profile, err := useCase.repository.GetProfileByUserID(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrUserNotFound) {
			return nil, ErrSavedUserNotFound
		}
		return nil, fmt.Errorf("%w: load profile: %v", ErrSavedUserSourceUnavailable, err)
	}
	if profile == nil || profile.UserID != userID {
		return nil, fmt.Errorf("%w: invalid profile snapshot", ErrSavedUserSourceUnavailable)
	}
	profileRevision, ok := savedUserRevision(profile.UpdatedAt)
	if !ok {
		return nil, fmt.Errorf("%w: profile revision is unavailable", ErrSavedUserSourceUnavailable)
	}
	resolution.SourceRevision = maxSavedUserRevision(accountRevision, profileRevision)
	resolution.ProjectionRevision = profileRevision

	projection, ok := savedUserProjection(profile, profileRevision, validatedAt)
	if !ok {
		return nil, fmt.Errorf("%w: public projection is unavailable", ErrSavedUserSourceUnavailable)
	}
	resolution.Eligible = true
	resolution.Visibility = SavedUserVisibilityPublic
	resolution.PublicProjection = projection
	return resolution, nil
}

func savedUserProjection(
	profile *model.UserProfile,
	profileRevision uint64,
	validatedAt time.Time,
) (*SavedUserPublicProjection, bool) {
	if profile == nil || profile.UserID == uuid.Nil || profileRevision == 0 || validatedAt.IsZero() {
		return nil, false
	}
	defaultLocale := normalizeSavedUserLocale(profile.Locale)
	name := savedUserDisplayName(profile)
	nickname := boundedSavedUserText(optionalSavedUserText(profile.Nickname), savedUserSubtitleMaxRunes)
	country := normalizedSavedUserCountry(profile.CountryCode)

	localized := make(map[string]SavedUserLocalizedProjection, 3)
	for _, locale := range []string{"en", "ru", "kk"} {
		title := name
		if title == "" {
			title = genericSavedUserTitle(locale)
		}
		subtitle := nickname
		if strings.EqualFold(title, subtitle) {
			subtitle = ""
		}
		localized[locale] = SavedUserLocalizedProjection{
			Title:           title,
			Subtitle:        subtitle,
			Country:         country,
			DisplayLocation: boundedSavedUserText(country, savedUserDisplayLocationMaxRunes),
		}
	}

	projection := &SavedUserPublicProjection{
		SourceDefaultLocale:  defaultLocale,
		Localized:            localized,
		CanonicalDetailRoute: "/users/" + profile.UserID.String() + "/profile",
	}
	if profile.AvatarFileID != nil && *profile.AvatarFileID != uuid.Nil {
		projection.Media = &SavedUserMediaReference{
			OpaqueReference: fmt.Sprintf(
				"user-avatar:%s:%s:%d",
				profile.UserID,
				*profile.AvatarFileID,
				profileRevision,
			),
			ReferenceRevision: profileRevision,
			ValidUntil:        validatedAt.Add(savedUserMediaTTL),
		}
	}
	return projection, true
}

func savedUserDisplayName(profile *model.UserProfile) string {
	if profile == nil {
		return ""
	}
	parts := make([]string, 0, 2)
	for _, value := range []*string{profile.FirstName, profile.LastName} {
		part := boundedSavedUserText(optionalSavedUserText(value), savedUserTitleMaxRunes)
		if part != "" {
			parts = append(parts, part)
		}
	}
	if fullName := boundedSavedUserText(strings.Join(parts, " "), savedUserTitleMaxRunes); fullName != "" {
		return fullName
	}
	return boundedSavedUserText(optionalSavedUserText(profile.Nickname), savedUserTitleMaxRunes)
}

func normalizeSavedUserLocale(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "en":
		return "en"
	case "kk":
		return "kk"
	default:
		return "ru"
	}
}

func normalizedSavedUserCountry(value *string) string {
	if value == nil {
		return ""
	}
	country := strings.ToUpper(strings.TrimSpace(*value))
	if len(country) != 2 {
		return ""
	}
	for _, character := range country {
		if character < 'A' || character > 'Z' {
			return ""
		}
	}
	return country
}

func genericSavedUserTitle(locale string) string {
	switch locale {
	case "en":
		return "Traveler"
	case "kk":
		return "Саяхатшы"
	default:
		return "Путешественник"
	}
}

func optionalSavedUserText(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}

func boundedSavedUserText(value string, maxRunes int) string {
	value = strings.TrimSpace(value)
	if value == "" || maxRunes <= 0 || !utf8.ValidString(value) ||
		strings.IndexFunc(value, unicode.IsControl) >= 0 {
		return ""
	}
	runes := []rune(value)
	if len(runes) > maxRunes {
		value = strings.TrimSpace(string(runes[:maxRunes]))
	}
	return value
}

func savedUserRevision(value time.Time) (uint64, bool) {
	if value.IsZero() {
		return 0, false
	}
	microseconds := value.UTC().UnixMicro()
	if microseconds <= 0 {
		return 0, false
	}
	return uint64(microseconds), true
}

func maxSavedUserRevision(values ...uint64) uint64 {
	var result uint64
	for _, value := range values {
		if value > result {
			result = value
		}
	}
	return result
}
