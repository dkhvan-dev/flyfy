package app

import (
	"context"
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
	"kz/inflap/backend/services/guide-service/internal/domain/port"
)

const (
	savedGuideTitleMaxRunes           = 200
	savedGuideSubtitleMaxRunes        = 280
	savedGuideCountryMaxRunes         = 2
	savedGuideDisplayLocationMaxRunes = 72
	savedGuideMediaTTL                = 5 * time.Minute
)

var (
	ErrSavedSourceUnavailable              = errors.New("saved guide source unavailable")
	ErrSavedGuideMediaReferenceUnavailable = errors.New("saved guide media reference unavailable")
)

type SavedGuideAvatarReference struct {
	GuideUserID  uuid.UUID
	AvatarFileID uuid.UUID
	Revision     uint64
}

type SavedGuideUserSnapshot struct {
	UserID           uuid.UUID
	AccountStatus    string
	IsDeleted        bool
	FirstName        *string
	LastName         *string
	Nickname         *string
	AvatarFileID     *uuid.UUID
	CountryCode      *string
	Locale           string
	AccountUpdatedAt time.Time
	ProfileUpdatedAt time.Time
}

type SavedGuideUserSource interface {
	GetSavedGuideUserSnapshot(
		ctx context.Context,
		userID uuid.UUID,
	) (*SavedGuideUserSnapshot, error)
}

type SavedGuideVisibility string

const (
	SavedGuideVisibilityPublic      SavedGuideVisibility = "PUBLIC"
	SavedGuideVisibilityUnavailable SavedGuideVisibility = "UNAVAILABLE"
	SavedGuideVisibilityDeleted     SavedGuideVisibility = "DELETED"
)

type SavedGuideLocalizedProjection struct {
	Title           string
	Subtitle        string
	Country         string
	DisplayLocation string
}

type SavedGuideRatingSummary struct {
	Value       float64
	ReviewCount uint64
	ScaleMax    float64
}

type SavedGuideMediaReference struct {
	OpaqueReference   string
	ReferenceRevision uint64
	ValidUntil        time.Time
}

type SavedGuidePublicProjection struct {
	SourceDefaultLocale  string
	Localized            map[string]SavedGuideLocalizedProjection
	Rating               *SavedGuideRatingSummary
	AsOf                 *time.Time
	CanonicalDetailRoute string
	Media                *SavedGuideMediaReference
}

type SavedGuideResolution struct {
	Eligible           bool
	Visibility         SavedGuideVisibility
	SourceRevision     uint64
	ProjectionRevision uint64
	VisibilityRevision uint64
	ValidatedAt        time.Time
	PublicProjection   *SavedGuidePublicProjection
}

type SavedGuideSourceUseCase struct {
	repo       port.SavedSourceRepository
	userSource SavedGuideUserSource
	now        func() time.Time
}

type SavedGuideSourceOption func(*SavedGuideSourceUseCase)

func WithSavedGuideSourceClock(now func() time.Time) SavedGuideSourceOption {
	return func(useCase *SavedGuideSourceUseCase) {
		if now != nil {
			useCase.now = now
		}
	}
}

func NewSavedGuideSourceUseCase(
	repo port.SavedSourceRepository,
	userSource SavedGuideUserSource,
	options ...SavedGuideSourceOption,
) *SavedGuideSourceUseCase {
	useCase := &SavedGuideSourceUseCase{
		repo:       repo,
		userSource: userSource,
		now:        time.Now,
	}
	for _, option := range options {
		if option != nil {
			option(useCase)
		}
	}
	return useCase
}

func (u *SavedGuideSourceUseCase) ResolveGuide(
	ctx context.Context,
	userID uuid.UUID,
) (*SavedGuideResolution, error) {
	if userID == uuid.Nil {
		return nil, ErrInvalidGuideUserID
	}
	if u == nil || u.repo == nil || u.now == nil {
		return nil, ErrSavedSourceUnavailable
	}

	snapshot, err := u.repo.GetSavedSourceGuide(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("%w: load guide snapshot: %v", ErrSavedSourceUnavailable, err)
	}
	if snapshot == nil || snapshot.Profile == nil {
		return nil, ErrGuideProfileNotFound
	}
	profile := snapshot.Profile
	if profile.UserID != userID || profile.ID == uuid.Nil {
		return nil, fmt.Errorf("%w: repository returned a different guide", ErrSavedSourceUnavailable)
	}
	if err := profile.Validate(); err != nil {
		return nil, fmt.Errorf("%w: invalid guide profile", ErrSavedSourceUnavailable)
	}
	if math.IsNaN(profile.RatingAvg) || math.IsInf(profile.RatingAvg, 0) {
		return nil, fmt.Errorf("%w: invalid guide rating", ErrSavedSourceUnavailable)
	}

	profileRevision, ok := savedGuideRevision(profile.UpdatedAt)
	if !ok {
		return nil, fmt.Errorf("%w: guide revision is unavailable", ErrSavedSourceUnavailable)
	}
	verificationRevision, verificationOK := savedGuideVerificationRevision(snapshot)
	if !verificationOK {
		return nil, fmt.Errorf("%w: verification revision is unavailable", ErrSavedSourceUnavailable)
	}
	baseRevision := maxSavedGuideRevision(
		profileRevision,
		verificationRevision,
		snapshot.SourceRevision,
	)
	projectionRevision := snapshot.ProjectionRevision
	if projectionRevision == 0 {
		projectionRevision = profileRevision
	}
	visibilityRevision := snapshot.VisibilityRevision
	if visibilityRevision == 0 {
		visibilityRevision = baseRevision
	}

	validatedAt := u.now().UTC()
	if validatedAt.IsZero() {
		return nil, fmt.Errorf("%w: validation time is unavailable", ErrSavedSourceUnavailable)
	}
	resolution := &SavedGuideResolution{
		Visibility:         SavedGuideVisibilityUnavailable,
		SourceRevision:     baseRevision,
		ProjectionRevision: projectionRevision,
		VisibilityRevision: visibilityRevision,
		ValidatedAt:        validatedAt,
	}
	if snapshot.LifecycleVisibility == model.SavedLifecycleVisibilityDeleted {
		resolution.Visibility = SavedGuideVisibilityDeleted
		return resolution, nil
	}
	if snapshot.LifecycleVisibility != model.SavedLifecycleVisibilityPublic {
		return resolution, nil
	}

	if profile.Status != enum.GuideStatusActive ||
		snapshot.LatestVerificationStatus == nil ||
		*snapshot.LatestVerificationStatus != enum.VerificationRequestStatusApproved {
		return resolution, nil
	}
	if u.userSource == nil {
		return nil, ErrSavedSourceUnavailable
	}

	userSnapshot, err := u.userSource.GetSavedGuideUserSnapshot(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrUserNotFound) {
			return resolution, nil
		}
		return nil, fmt.Errorf("%w: load public guide identity: %v", ErrSavedSourceUnavailable, err)
	}
	if userSnapshot == nil || userSnapshot.UserID != userID {
		return nil, fmt.Errorf("%w: invalid public guide identity", ErrSavedSourceUnavailable)
	}
	accountRevision, accountOK := savedGuideRevision(userSnapshot.AccountUpdatedAt)
	profileUserRevision, userProfileOK := savedGuideRevision(userSnapshot.ProfileUpdatedAt)
	if !accountOK || !userProfileOK {
		return nil, fmt.Errorf("%w: user revisions are unavailable", ErrSavedSourceUnavailable)
	}

	resolution.SourceRevision = maxSavedGuideRevision(
		resolution.SourceRevision,
		accountRevision,
		profileUserRevision,
	)
	resolution.ProjectionRevision = maxSavedGuideRevision(
		resolution.ProjectionRevision,
		profileUserRevision,
	)
	resolution.VisibilityRevision = maxSavedGuideRevision(
		resolution.VisibilityRevision,
		accountRevision,
	)
	if userSnapshot.IsDeleted || strings.TrimSpace(userSnapshot.AccountStatus) != "ACTIVE" {
		return resolution, nil
	}

	mediaReferenceActive := snapshot.MediaReferenceActive &&
		snapshot.ExternalAvatarFileID != nil &&
		userSnapshot.AvatarFileID != nil &&
		*snapshot.ExternalAvatarFileID == *userSnapshot.AvatarFileID
	mediaReferenceRevision := snapshot.MediaReferenceRevision
	projection, projectionOK := savedGuideProjection(
		profile,
		userSnapshot,
		mediaReferenceRevision,
		mediaReferenceActive,
		validatedAt,
	)
	if !projectionOK {
		return resolution, nil
	}
	resolution.Eligible = true
	resolution.Visibility = SavedGuideVisibilityPublic
	resolution.PublicProjection = projection
	return resolution, nil
}

// ResolveCurrentGuideAvatarReference validates an opaque reference at the
// Guide-owned side of a media delivery boundary. It returns the current file
// identifier, never a fetchable URL; the authenticated media/file layer owns
// short-lived URL issuance after this check succeeds. An optional expected
// revision binds the lookup to the media reference revision encoded in the
// opaque token, not to the independently evolving Saved projection revision.
func (u *SavedGuideSourceUseCase) ResolveCurrentGuideAvatarReference(
	ctx context.Context,
	opaqueReference string,
	expectedReferenceRevision ...uint64,
) (uuid.UUID, error) {
	if len(expectedReferenceRevision) > 1 ||
		(len(expectedReferenceRevision) == 1 && expectedReferenceRevision[0] == 0) {
		return uuid.Nil, ErrSavedGuideMediaReferenceUnavailable
	}
	reference, err := ParseSavedGuideAvatarReference(opaqueReference)
	if err != nil {
		return uuid.Nil, ErrSavedGuideMediaReferenceUnavailable
	}
	if len(expectedReferenceRevision) == 1 &&
		reference.Revision != expectedReferenceRevision[0] {
		return uuid.Nil, ErrSavedGuideMediaReferenceUnavailable
	}

	resolution, err := u.ResolveGuide(ctx, reference.GuideUserID)
	if err != nil {
		if errors.Is(err, ErrGuideProfileNotFound) {
			return uuid.Nil, ErrSavedGuideMediaReferenceUnavailable
		}
		return uuid.Nil, err
	}
	if resolution == nil || !resolution.Eligible ||
		resolution.Visibility != SavedGuideVisibilityPublic ||
		resolution.PublicProjection == nil || resolution.PublicProjection.Media == nil {
		return uuid.Nil, ErrSavedGuideMediaReferenceUnavailable
	}
	media := resolution.PublicProjection.Media
	currentReference, err := ParseSavedGuideAvatarReference(media.OpaqueReference)
	if err != nil || media.OpaqueReference != opaqueReference ||
		media.ReferenceRevision != reference.Revision ||
		currentReference != reference ||
		!media.ValidUntil.After(resolution.ValidatedAt) {
		return uuid.Nil, ErrSavedGuideMediaReferenceUnavailable
	}

	return reference.AvatarFileID, nil
}

func ParseSavedGuideAvatarReference(value string) (SavedGuideAvatarReference, error) {
	if value == "" || value != strings.TrimSpace(value) {
		return SavedGuideAvatarReference{}, ErrSavedGuideMediaReferenceUnavailable
	}
	parts := strings.Split(value, ":")
	if len(parts) != 4 || parts[0] != "guide-avatar" {
		return SavedGuideAvatarReference{}, ErrSavedGuideMediaReferenceUnavailable
	}

	guideUserID, err := uuid.Parse(parts[1])
	if err != nil || guideUserID == uuid.Nil || guideUserID.String() != parts[1] {
		return SavedGuideAvatarReference{}, ErrSavedGuideMediaReferenceUnavailable
	}
	avatarFileID, err := uuid.Parse(parts[2])
	if err != nil || avatarFileID == uuid.Nil || avatarFileID.String() != parts[2] {
		return SavedGuideAvatarReference{}, ErrSavedGuideMediaReferenceUnavailable
	}
	revision, err := strconv.ParseUint(parts[3], 10, 64)
	if err != nil || revision == 0 || strconv.FormatUint(revision, 10) != parts[3] {
		return SavedGuideAvatarReference{}, ErrSavedGuideMediaReferenceUnavailable
	}

	return SavedGuideAvatarReference{
		GuideUserID:  guideUserID,
		AvatarFileID: avatarFileID,
		Revision:     revision,
	}, nil
}

func savedGuideVerificationRevision(snapshot *model.SavedGuideSnapshot) (uint64, bool) {
	if snapshot.LatestVerificationStatus == nil && snapshot.LatestVerificationUpdatedAt == nil {
		return 0, true
	}
	if snapshot.LatestVerificationStatus == nil || snapshot.LatestVerificationUpdatedAt == nil ||
		!snapshot.LatestVerificationStatus.IsValid() {
		return 0, false
	}
	return savedGuideRevision(*snapshot.LatestVerificationUpdatedAt)
}

func savedGuideProjection(
	profile *model.GuideProfile,
	user *SavedGuideUserSnapshot,
	mediaReferenceRevision uint64,
	mediaReferenceActive bool,
	validatedAt time.Time,
) (*SavedGuidePublicProjection, bool) {
	locale, ok := normalizeSavedGuideLocale(user.Locale)
	if !ok {
		return nil, false
	}

	title := savedGuideDisplayName(user)
	if title == "" {
		title = boundedSavedGuideText(savedGuideOptionalString(profile.Headline), savedGuideTitleMaxRunes)
	}
	if title == "" {
		return nil, false
	}
	subtitle := boundedSavedGuideText(savedGuideOptionalString(profile.Headline), savedGuideSubtitleMaxRunes)
	if strings.EqualFold(title, subtitle) {
		subtitle = ""
	}
	country := ""
	if user.CountryCode != nil {
		candidate := strings.ToUpper(strings.TrimSpace(*user.CountryCode))
		if isSavedGuideCountryCode(candidate) {
			country = candidate
		}
	}

	projection := &SavedGuidePublicProjection{
		SourceDefaultLocale: locale,
		Localized: map[string]SavedGuideLocalizedProjection{
			locale: {
				Title:           title,
				Subtitle:        subtitle,
				Country:         country,
				DisplayLocation: boundedSavedGuideText(country, savedGuideDisplayLocationMaxRunes),
			},
		},
		CanonicalDetailRoute: "/users/" + profile.UserID.String() + "/profile",
	}
	if profile.ReviewsCount > 0 &&
		profile.RatingAvg >= 0 && profile.RatingAvg <= 5 &&
		!math.IsNaN(profile.RatingAvg) && !math.IsInf(profile.RatingAvg, 0) {
		asOf := profile.UpdatedAt.UTC()
		projection.AsOf = &asOf
		projection.Rating = &SavedGuideRatingSummary{
			Value:       profile.RatingAvg,
			ReviewCount: uint64(profile.ReviewsCount),
			ScaleMax:    5,
		}
	}
	if mediaReferenceActive && mediaReferenceRevision > 0 &&
		user.AvatarFileID != nil && *user.AvatarFileID != uuid.Nil {
		projection.Media = &SavedGuideMediaReference{
			OpaqueReference: fmt.Sprintf(
				"guide-avatar:%s:%s:%d",
				profile.UserID,
				*user.AvatarFileID,
				mediaReferenceRevision,
			),
			ReferenceRevision: mediaReferenceRevision,
			ValidUntil:        validatedAt.Add(savedGuideMediaTTL),
		}
	}
	return projection, true
}

func savedGuideDisplayName(user *SavedGuideUserSnapshot) string {
	if user == nil {
		return ""
	}
	if user.Nickname != nil {
		if nickname := boundedSavedGuideText(*user.Nickname, savedGuideTitleMaxRunes); nickname != "" {
			return nickname
		}
	}
	parts := make([]string, 0, 2)
	for _, value := range []*string{user.FirstName, user.LastName} {
		if value == nil {
			continue
		}
		if part := boundedSavedGuideText(*value, savedGuideTitleMaxRunes); part != "" {
			parts = append(parts, part)
		}
	}
	return boundedSavedGuideText(strings.Join(parts, " "), savedGuideTitleMaxRunes)
}

func normalizeSavedGuideLocale(value string) (string, bool) {
	value = strings.ToLower(strings.TrimSpace(value))
	switch value {
	case "en", "ru", "kk":
		return value, true
	default:
		return "", false
	}
}

func savedGuideRevision(value time.Time) (uint64, bool) {
	if value.IsZero() {
		return 0, false
	}
	microseconds := value.UTC().UnixMicro()
	if microseconds <= 0 {
		return 0, false
	}
	return uint64(microseconds), true
}

func maxSavedGuideRevision(values ...uint64) uint64 {
	var result uint64
	for _, value := range values {
		if value > result {
			result = value
		}
	}
	return result
}

func boundedSavedGuideText(value string, maxRunes int) string {
	for _, valueRune := range value {
		if unicode.IsControl(valueRune) {
			return ""
		}
	}
	value = strings.Join(strings.Fields(value), " ")
	if value == "" || maxRunes <= 0 {
		return ""
	}
	if utf8.RuneCountInString(value) <= maxRunes {
		return value
	}
	return strings.TrimSpace(string([]rune(value)[:maxRunes]))
}

func isSavedGuideCountryCode(value string) bool {
	if len(value) != savedGuideCountryMaxRunes || utf8.RuneCountInString(value) != savedGuideCountryMaxRunes {
		return false
	}
	for _, valueByte := range []byte(value) {
		if valueByte < 'A' || valueByte > 'Z' {
			return false
		}
	}
	return true
}

func savedGuideOptionalString(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}
