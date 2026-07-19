package app

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

type savedSourceRepositoryStub struct {
	activity          *model.Activity
	media             []*model.ActivityMedia
	err               error
	requestedActivity uuid.UUID
}

func (s *savedSourceRepositoryStub) GetSavedSourceActivity(
	_ context.Context,
	activityID uuid.UUID,
) (*model.Activity, []*model.ActivityMedia, error) {
	s.requestedActivity = activityID
	return s.activity, s.media, s.err
}

func TestResolveSavedSourcePublicActivityBuildsBoundedProjection(t *testing.T) {
	t.Parallel()

	validatedAt := time.Date(2026, time.July, 16, 10, 30, 0, 0, time.FixedZone("test", 6*60*60))
	item := savedSourceTestActivity()
	item.SourceActivityID = uuidPtr(uuid.New())
	item.Translations = model.ActivityTranslations{
		"ru": {
			Title:       strings.Repeat("я", savedSourceTitleMaxRunes+20),
			Description: strings.Repeat("д", savedSourceSubtitleMaxRunes+20),
		},
		"en": {Title: "Mountain walk", Description: "A public trail walk"},
	}
	fileID := uuid.New()
	repo := &savedSourceRepositoryStub{
		activity: item,
		media: []*model.ActivityMedia{{
			ActivityID: item.ID,
			FileID:     fileID,
			IsCover:    true,
		}},
	}
	useCase := NewSavedSourceUseCase(repo, WithSavedSourceClock(func() time.Time {
		return validatedAt
	}))

	result, err := useCase.ResolveActivity(context.Background(), item.ID)
	if err != nil {
		t.Fatalf("ResolveActivity() error = %v", err)
	}
	if repo.requestedActivity != item.ID {
		t.Fatalf("repository activity id = %s, want canonical %s", repo.requestedActivity, item.ID)
	}
	if !result.Eligible || result.Visibility != SavedSourceVisibilityPublic {
		t.Fatalf("eligibility/visibility = %v/%s, want eligible/public", result.Eligible, result.Visibility)
	}
	if result.SourceRevision != item.SavedSourceRevision ||
		result.ProjectionRevision != item.SavedProjectionRevision ||
		result.VisibilityRevision != item.SavedVisibilityRevision {
		t.Fatalf(
			"revisions = %d/%d/%d, want %d/%d/%d",
			result.SourceRevision,
			result.ProjectionRevision,
			result.VisibilityRevision,
			item.SavedSourceRevision,
			item.SavedProjectionRevision,
			item.SavedVisibilityRevision,
		)
	}
	if !result.ValidatedAt.Equal(validatedAt.UTC()) || result.ValidatedAt.Location() != time.UTC {
		t.Fatalf("validatedAt = %v, want server UTC %v", result.ValidatedAt, validatedAt.UTC())
	}

	projection := result.PublicProjection
	if projection == nil {
		t.Fatal("public projection is nil")
	}
	if projection.SourceDefaultLocale != "ru" {
		t.Fatalf("source locale = %q, want ru", projection.SourceDefaultLocale)
	}
	if _, exists := projection.Localized["kk"]; exists {
		t.Fatal("projection fabricated a missing kk translation")
	}
	if utf8.RuneCountInString(projection.Localized["ru"].Title) != savedSourceTitleMaxRunes {
		t.Fatalf("ru title rune count = %d, want %d", utf8.RuneCountInString(projection.Localized["ru"].Title), savedSourceTitleMaxRunes)
	}
	if utf8.RuneCountInString(projection.Localized["ru"].Subtitle) != savedSourceSubtitleMaxRunes {
		t.Fatalf("ru subtitle rune count = %d, want %d", utf8.RuneCountInString(projection.Localized["ru"].Subtitle), savedSourceSubtitleMaxRunes)
	}
	if projection.Localized["ru"].City != "Almaty" || projection.Localized["ru"].DisplayLocation == "" {
		t.Fatalf("source location = %+v, want bounded source-locale location", projection.Localized["ru"])
	}
	if projection.Localized["ru"].Country != "" ||
		projection.Localized["en"].City != "" ||
		projection.Localized["en"].Country != "" ||
		projection.Localized["en"].DisplayLocation != "" {
		t.Fatal("projection fabricated localized city/country/location data")
	}
	if projection.CanonicalDetailRoute != "/activities/"+item.ID.String() {
		t.Fatalf("detail route = %q", projection.CanonicalDetailRoute)
	}
	if projection.Media == nil {
		t.Fatal("public media reference is nil")
	}
	if projection.Media.ReferenceRevision != item.SavedProjectionRevision ||
		!strings.Contains(projection.Media.OpaqueReference, "saved_revision=102") ||
		strings.Contains(projection.Media.OpaqueReference, fileID.String()) {
		t.Fatalf("media reference = %+v", projection.Media)
	}
	if !projection.Media.ValidUntil.Equal(validatedAt.UTC().Add(savedSourceMediaTTL)) {
		t.Fatalf("media validUntil = %v", projection.Media.ValidUntil)
	}
}

func TestResolveSavedSourceNonPublicActivitiesReturnNoPayload(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		mutate     func(*model.Activity)
		visibility SavedSourceVisibility
	}{
		{
			name: "private",
			mutate: func(item *model.Activity) {
				item.Visibility = enum.ActivityVisibilityPrivate
			},
			visibility: SavedSourceVisibilityPrivate,
		},
		{
			name: "unlisted",
			mutate: func(item *model.Activity) {
				item.Visibility = enum.ActivityVisibilityUnlisted
			},
			visibility: SavedSourceVisibilityRestricted,
		},
		{
			name: "cancelled",
			mutate: func(item *model.Activity) {
				item.Status = enum.ActivityStatusCancelled
			},
			visibility: SavedSourceVisibilityUnavailable,
		},
		{
			name: "archived",
			mutate: func(item *model.Activity) {
				item.Status = enum.ActivityStatusArchived
			},
			visibility: SavedSourceVisibilityDeleted,
		},
		{
			name: "moderation rejected",
			mutate: func(item *model.Activity) {
				item.ModerationStatus = enum.ActivityModerationStatusRejected
			},
			visibility: SavedSourceVisibilityRestricted,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()

			item := savedSourceTestActivity()
			test.mutate(item)
			repo := &savedSourceRepositoryStub{
				activity: item,
				media:    []*model.ActivityMedia{{ActivityID: item.ID, FileID: uuid.New()}},
			}
			result, err := NewSavedSourceUseCase(repo).ResolveActivity(context.Background(), item.ID)
			if err != nil {
				t.Fatalf("ResolveActivity() error = %v", err)
			}
			if result.Eligible || result.Visibility != test.visibility {
				t.Fatalf("eligibility/visibility = %v/%s, want false/%s", result.Eligible, result.Visibility, test.visibility)
			}
			if result.PublicProjection != nil {
				t.Fatalf("non-public projection = %+v, want nil", result.PublicProjection)
			}
			if result.SourceRevision != item.SavedSourceRevision ||
				result.ProjectionRevision != item.SavedProjectionRevision ||
				result.VisibilityRevision != item.SavedVisibilityRevision {
				t.Fatalf(
					"revisions = %d/%d/%d, want %d/%d/%d",
					result.SourceRevision,
					result.ProjectionRevision,
					result.VisibilityRevision,
					item.SavedSourceRevision,
					item.SavedProjectionRevision,
					item.SavedVisibilityRevision,
				)
			}
		})
	}
}

func TestResolveSavedSourceFailsClosedForMissingInvalidOrUnavailableSource(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	tests := []struct {
		name string
		repo *savedSourceRepositoryStub
		want error
	}{
		{name: "missing", repo: &savedSourceRepositoryStub{}, want: ErrActivityNotFound},
		{name: "repository outage", repo: &savedSourceRepositoryStub{err: errors.New("database offline")}, want: ErrSavedSourceUnavailable},
		{name: "zero revision", repo: &savedSourceRepositoryStub{activity: func() *model.Activity {
			item := savedSourceTestActivity()
			item.ID = activityID
			item.Revision = 0
			return item
		}()}, want: ErrSavedSourceUnavailable},
		{name: "different aggregate", repo: &savedSourceRepositoryStub{activity: savedSourceTestActivity()}, want: ErrSavedSourceUnavailable},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			_, err := NewSavedSourceUseCase(test.repo).ResolveActivity(context.Background(), activityID)
			if !errors.Is(err, test.want) {
				t.Fatalf("ResolveActivity() error = %v, want %v", err, test.want)
			}
		})
	}
}

func savedSourceTestActivity() *model.Activity {
	now := time.Date(2026, time.July, 16, 4, 0, 0, 0, time.UTC)
	publishedAt := now.Add(-time.Hour)
	city := "Almaty"
	address := "Dostyk Avenue 1"
	return &model.Activity{
		ID:                      uuid.New(),
		HostUserID:              uuid.New(),
		Title:                   "Mountain walk",
		Description:             "A public trail walk near the city",
		SourceLanguage:          "ru",
		Translations:            model.ActivityTranslations{"ru": {Title: "Прогулка в горах", Description: "Открытая прогулка по маршруту"}},
		Status:                  enum.ActivityStatusEnrollmentOpen,
		Visibility:              enum.ActivityVisibilityPublic,
		ModerationStatus:        enum.ActivityModerationStatusApproved,
		CityName:                &city,
		AddressText:             &address,
		PublishedAt:             &publishedAt,
		Revision:                23,
		SavedSourceRevision:     101,
		SavedProjectionRevision: 102,
		SavedVisibilityRevision: 103,
		RegistrationDeadline:    now.Add(23 * time.Hour),
		StartAt:                 now.Add(24 * time.Hour),
		EndAt:                   now.Add(26 * time.Hour),
	}
}

func uuidPtr(value uuid.UUID) *uuid.UUID {
	return &value
}
