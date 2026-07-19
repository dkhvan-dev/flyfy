package app

import (
	"context"
	"errors"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestSavedSourceResolveAttractionReturnsOnlySourceTranslations(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	now := time.Date(2026, time.July, 16, 10, 30, 0, 0, time.UTC)
	repo := &savedSourceRepositoryStub{
		snapshot: &model.SavedAttractionSnapshot{
			ID:                 attractionID,
			DefaultLocale:      "ru",
			CountryCode:        "KZ",
			CityID:             "almaty",
			Rating:             4.7,
			ReviewCount:        81,
			Status:             enum.StatusPublished,
			SourceRevision:     101,
			ProjectionRevision: 102,
			VisibilityRevision: 103,
			Translations: map[string]model.PlaceTranslation{
				"en": {
					PlaceID: attractionID,
					Locale:  "en",
					Title:   "Big Almaty Lake",
				},
				"ru": {
					PlaceID: attractionID,
					Locale:  "ru",
					Title:   "Большое Алматинское озеро",
				},
			},
			Media: []model.PlaceMedia{
				{
					PlaceID:   attractionID,
					FileID:    uuid.New(),
					MediaType: enum.MediaPhoto,
				},
			},
		},
	}
	useCase := NewSavedSourceUseCase(repo, WithSavedSourceClock(func() time.Time { return now }))

	resolution, err := useCase.ResolveAttraction(context.Background(), attractionID)
	if err != nil {
		t.Fatalf("ResolveAttraction() error = %v", err)
	}
	if !resolution.Eligible || resolution.Visibility != SavedSourceVisibilityPublic {
		t.Fatalf("resolution eligibility/visibility = %t/%s", resolution.Eligible, resolution.Visibility)
	}
	if resolution.SourceRevision != 101 ||
		resolution.ProjectionRevision != 102 ||
		resolution.VisibilityRevision != 103 {
		t.Fatalf("revisions = %d/%d/%d", resolution.SourceRevision, resolution.ProjectionRevision, resolution.VisibilityRevision)
	}
	projection := resolution.PublicProjection
	if projection == nil {
		t.Fatal("public projection is nil")
	}
	if projection.SourceDefaultLocale != "ru" {
		t.Fatalf("source default locale = %q, want ru", projection.SourceDefaultLocale)
	}
	if _, exists := projection.Localized["kk"]; exists {
		t.Fatal("missing kk translation was invented")
	}
	if projection.Localized["en"].Title != "Big Almaty Lake" ||
		projection.Localized["ru"].Title != "Большое Алматинское озеро" {
		t.Fatalf("localized projection = %#v", projection.Localized)
	}
	if projection.CanonicalDetailRoute != "/places/"+attractionID.String() {
		t.Fatalf("canonical route = %q", projection.CanonicalDetailRoute)
	}
	if projection.Rating == nil || projection.Rating.Value != 4.7 || projection.Rating.ReviewCount != 81 {
		t.Fatalf("rating = %#v", projection.Rating)
	}
	if projection.AsOf == nil || !projection.AsOf.Equal(now) {
		t.Fatalf("as-of = %v, want %s", projection.AsOf, now)
	}
	if projection.Media == nil ||
		projection.Media.OpaqueReference != "attraction-cover:"+attractionID.String()+":102" ||
		projection.Media.ReferenceRevision != 102 ||
		!projection.Media.ValidUntil.Equal(now.Add(savedSourceMediaTTL)) {
		t.Fatalf("media = %#v", projection.Media)
	}
}

func TestSavedSourceMediaReferenceIsOpaqueAndRevisionBound(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	fileID := uuid.New()
	now := time.Date(2026, time.July, 16, 10, 30, 0, 0, time.UTC)
	snapshot := publishedSavedAttraction(attractionID)
	snapshot.Media = []model.PlaceMedia{{
		PlaceID:   attractionID,
		FileID:    fileID,
		MediaType: enum.MediaPhoto,
	}}
	repo := &savedSourceRepositoryStub{snapshot: snapshot}
	useCase := NewSavedSourceUseCase(repo, WithSavedSourceClock(func() time.Time { return now }))

	publicResolution, err := useCase.ResolveAttraction(context.Background(), attractionID)
	if err != nil {
		t.Fatalf("ResolveAttraction() public error = %v", err)
	}
	if publicResolution.PublicProjection == nil || publicResolution.PublicProjection.Media == nil {
		t.Fatal("public attraction media reference is nil")
	}
	oldReference := publicResolution.PublicProjection.Media.OpaqueReference
	parsed, err := url.Parse(oldReference)
	if err != nil {
		t.Fatalf("parse opaque media reference: %v", err)
	}
	if parsed.Scheme == "http" || parsed.Scheme == "https" || parsed.Host != "" {
		t.Fatalf("opaque media reference became a fetchable URI: %q", oldReference)
	}
	if strings.Contains(oldReference, fileID.String()) {
		t.Fatalf("opaque media reference leaked file id: %q", oldReference)
	}
	if publicResolution.PublicProjection.Media.ReferenceRevision != snapshot.ProjectionRevision {
		t.Fatalf(
			"media reference revision = %d, want current projection revision %d",
			publicResolution.PublicProjection.Media.ReferenceRevision,
			snapshot.ProjectionRevision,
		)
	}

	// The database transition rotates projection_revision atomically. The source
	// resolver then emits no media while denied and a different token if restored.
	snapshot.Status = enum.StatusDraft
	snapshot.ProjectionRevision++
	snapshot.VisibilityRevision++
	deniedResolution, err := useCase.ResolveAttraction(context.Background(), attractionID)
	if err != nil {
		t.Fatalf("ResolveAttraction() denied error = %v", err)
	}
	if deniedResolution.PublicProjection != nil {
		t.Fatal("denied attraction retained projection/media")
	}

	snapshot.Status = enum.StatusPublished
	snapshot.ProjectionRevision++
	snapshot.VisibilityRevision++
	restoredResolution, err := useCase.ResolveAttraction(context.Background(), attractionID)
	if err != nil {
		t.Fatalf("ResolveAttraction() restored error = %v", err)
	}
	if restoredResolution.PublicProjection == nil || restoredResolution.PublicProjection.Media == nil {
		t.Fatal("restored attraction media reference is nil")
	}
	if restoredResolution.PublicProjection.Media.OpaqueReference == oldReference {
		t.Fatalf("stale media reference was reused after deny: %q", oldReference)
	}
	if restoredResolution.PublicProjection.Media.ReferenceRevision != snapshot.ProjectionRevision {
		t.Fatalf(
			"restored media reference revision = %d, want %d",
			restoredResolution.PublicProjection.Media.ReferenceRevision,
			snapshot.ProjectionRevision,
		)
	}
}

func TestSavedSourceResolveAttractionFailsClosedWithoutDefaultTranslation(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	repo := &savedSourceRepositoryStub{
		snapshot: publishedSavedAttraction(attractionID),
	}
	repo.snapshot.DefaultLocale = "kk"
	repo.snapshot.Translations = map[string]model.PlaceTranslation{
		"en": {PlaceID: attractionID, Locale: "en", Title: "Public title"},
	}

	resolution, err := NewSavedSourceUseCase(repo).ResolveAttraction(context.Background(), attractionID)
	if err != nil {
		t.Fatalf("ResolveAttraction() error = %v", err)
	}
	if resolution.Eligible || resolution.Visibility != SavedSourceVisibilityUnavailable {
		t.Fatalf("resolution = %#v, want payload-free unavailable", resolution)
	}
	if resolution.PublicProjection != nil {
		t.Fatal("unavailable resolution exposed a projection")
	}
}

func TestSavedSourceResolveAttractionReturnsPayloadFreeNonPublicStates(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		mutate     func(*model.SavedAttractionSnapshot)
		visibility SavedSourceVisibility
	}{
		{
			name: "draft",
			mutate: func(snapshot *model.SavedAttractionSnapshot) {
				snapshot.Status = enum.StatusDraft
			},
			visibility: SavedSourceVisibilityRestricted,
		},
		{
			name: "deleted",
			mutate: func(snapshot *model.SavedAttractionSnapshot) {
				deletedAt := time.Now().UTC()
				snapshot.DeletedAt = &deletedAt
			},
			visibility: SavedSourceVisibilityDeleted,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			attractionID := uuid.New()
			snapshot := publishedSavedAttraction(attractionID)
			test.mutate(snapshot)
			resolution, err := NewSavedSourceUseCase(
				&savedSourceRepositoryStub{snapshot: snapshot},
			).ResolveAttraction(context.Background(), attractionID)
			if err != nil {
				t.Fatalf("ResolveAttraction() error = %v", err)
			}
			if resolution.Eligible || resolution.Visibility != test.visibility {
				t.Fatalf("resolution = %#v", resolution)
			}
			if resolution.PublicProjection != nil {
				t.Fatal("non-public state exposed a projection")
			}
		})
	}
}

func TestSavedSourceResolveAttractionHandlesUnknownAndUnprovableState(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	_, err := NewSavedSourceUseCase(&savedSourceRepositoryStub{}).
		ResolveAttraction(context.Background(), attractionID)
	if !errors.Is(err, ErrAttractionNotFound) {
		t.Fatalf("unknown error = %v, want ErrAttractionNotFound", err)
	}

	invalidRevision := publishedSavedAttraction(attractionID)
	invalidRevision.VisibilityRevision = 0
	_, err = NewSavedSourceUseCase(&savedSourceRepositoryStub{snapshot: invalidRevision}).
		ResolveAttraction(context.Background(), attractionID)
	if !errors.Is(err, ErrSavedSourceUnavailable) {
		t.Fatalf("invalid revision error = %v, want ErrSavedSourceUnavailable", err)
	}

	_, err = NewSavedSourceUseCase(&savedSourceRepositoryStub{err: errors.New("database unavailable")}).
		ResolveAttraction(context.Background(), attractionID)
	if !errors.Is(err, ErrSavedSourceUnavailable) {
		t.Fatalf("repository error = %v, want ErrSavedSourceUnavailable", err)
	}
}

func publishedSavedAttraction(attractionID uuid.UUID) *model.SavedAttractionSnapshot {
	return &model.SavedAttractionSnapshot{
		ID:                 attractionID,
		DefaultLocale:      "en",
		CountryCode:        "KZ",
		CityID:             "almaty",
		Status:             enum.StatusPublished,
		SourceRevision:     1,
		ProjectionRevision: 2,
		VisibilityRevision: 3,
		Translations: map[string]model.PlaceTranslation{
			"en": {PlaceID: attractionID, Locale: "en", Title: "Public title"},
		},
	}
}

type savedSourceRepositoryStub struct {
	snapshot *model.SavedAttractionSnapshot
	err      error
}

func (r *savedSourceRepositoryStub) GetSavedSourceAttraction(
	_ context.Context,
	_ uuid.UUID,
) (*model.SavedAttractionSnapshot, error) {
	return r.snapshot, r.err
}
