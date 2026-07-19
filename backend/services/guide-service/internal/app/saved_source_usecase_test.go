package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
)

func TestSavedGuideSourcePublicProjectionUsesOnlySourceLocale(t *testing.T) {
	userID := uuid.New()
	profileUpdatedAt := time.Date(2026, 7, 10, 12, 0, 0, 0, time.UTC)
	verificationUpdatedAt := profileUpdatedAt.Add(time.Minute)
	accountUpdatedAt := profileUpdatedAt.Add(2 * time.Minute)
	userProfileUpdatedAt := profileUpdatedAt.Add(3 * time.Minute)
	validatedAt := profileUpdatedAt.Add(4 * time.Minute)
	headline := "Авторские прогулки по Алматы"
	nickname := "Аружан"
	country := "kz"
	avatarFileID := uuid.New()
	approved := enum.VerificationRequestStatusApproved

	useCase := NewSavedGuideSourceUseCase(
		&savedGuideRepositoryStub{snapshot: &model.SavedGuideSnapshot{
			Profile: &model.GuideProfile{
				ID:                        uuid.New(),
				UserID:                    userID,
				Type:                      enum.GuideTypeLocalExpert,
				Status:                    enum.GuideStatusActive,
				Headline:                  &headline,
				ExperienceYears:           7,
				IsExcursionGuideAvailable: true,
				RatingAvg:                 4.9,
				ReviewsCount:              42,
				CreatedAt:                 profileUpdatedAt.Add(-24 * time.Hour),
				UpdatedAt:                 profileUpdatedAt,
			},
			LatestVerificationStatus:    &approved,
			LatestVerificationUpdatedAt: &verificationUpdatedAt,
			SourceRevision:              uint64(verificationUpdatedAt.UnixMicro()),
			ProjectionRevision:          uint64(profileUpdatedAt.UnixMicro()),
			VisibilityRevision:          uint64(verificationUpdatedAt.UnixMicro()),
			LifecycleVisibility:         model.SavedLifecycleVisibilityPublic,
			MediaReferenceRevision:      uint64(userProfileUpdatedAt.UnixMicro()),
			MediaReferenceActive:        true,
			ExternalAvatarFileID:        &avatarFileID,
		}},
		&savedGuideUserSourceStub{snapshot: &SavedGuideUserSnapshot{
			UserID:           userID,
			AccountStatus:    "ACTIVE",
			Nickname:         &nickname,
			AvatarFileID:     &avatarFileID,
			CountryCode:      &country,
			Locale:           "ru",
			AccountUpdatedAt: accountUpdatedAt,
			ProfileUpdatedAt: userProfileUpdatedAt,
		}},
		WithSavedGuideSourceClock(func() time.Time { return validatedAt }),
	)

	resolution, err := useCase.ResolveGuide(context.Background(), userID)
	if err != nil {
		t.Fatalf("ResolveGuide() error = %v", err)
	}
	if !resolution.Eligible || resolution.Visibility != SavedGuideVisibilityPublic {
		t.Fatalf("resolution = %+v, want eligible PUBLIC", resolution)
	}
	if resolution.SourceRevision != uint64(userProfileUpdatedAt.UnixMicro()) ||
		resolution.ProjectionRevision != uint64(userProfileUpdatedAt.UnixMicro()) ||
		resolution.VisibilityRevision != uint64(accountUpdatedAt.UnixMicro()) {
		t.Fatalf("unexpected revisions: %+v", resolution)
	}
	projection := resolution.PublicProjection
	if projection == nil || projection.SourceDefaultLocale != "ru" {
		t.Fatalf("projection = %+v", projection)
	}
	localized, ok := projection.Localized["ru"]
	if !ok || localized.Title != nickname || localized.Subtitle != headline || localized.Country != "KZ" {
		t.Fatalf("localized projection = %+v", localized)
	}
	if _, exists := projection.Localized["en"]; exists {
		t.Fatal("EN projection was invented from RU source data")
	}
	if _, exists := projection.Localized["kk"]; exists {
		t.Fatal("KK projection was invented from RU source data")
	}
	if projection.CanonicalDetailRoute != "/users/"+userID.String()+"/profile" {
		t.Fatalf("detail route = %q", projection.CanonicalDetailRoute)
	}
	if projection.Rating == nil || projection.Rating.ReviewCount != 42 || projection.AsOf == nil {
		t.Fatalf("rating projection = %+v", projection)
	}
	mediaRevision := uint64(userProfileUpdatedAt.UnixMicro())
	if projection.Media == nil || projection.Media.ReferenceRevision != mediaRevision {
		t.Fatalf("media projection = %+v", projection.Media)
	}
	wantOpaqueReference := fmt.Sprintf(
		"guide-avatar:%s:%s:%d",
		userID,
		avatarFileID,
		mediaRevision,
	)
	if projection.Media.OpaqueReference != wantOpaqueReference ||
		strings.Contains(projection.Media.OpaqueReference, "://") {
		t.Fatalf("media reference = %q, want opaque %q", projection.Media.OpaqueReference, wantOpaqueReference)
	}
}

func TestSavedGuideAvatarReferenceIsOpaqueAndCurrentOnly(t *testing.T) {
	userID := uuid.New()
	avatarFileID := uuid.New()
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	mediaRevision := uint64(now.UnixMicro())
	approved := enum.VerificationRequestStatusApproved
	nickname := "Aruzhan"
	repo := &savedGuideRepositoryStub{snapshot: &model.SavedGuideSnapshot{
		Profile: &model.GuideProfile{
			ID: uuid.New(), UserID: userID, Type: enum.GuideTypeIndependent,
			Status:    enum.GuideStatusActive,
			CreatedAt: now.Add(-time.Hour), UpdatedAt: now,
		},
		LatestVerificationStatus:    &approved,
		LatestVerificationUpdatedAt: &now,
		SourceRevision:              mediaRevision,
		ProjectionRevision:          mediaRevision,
		VisibilityRevision:          mediaRevision,
		LifecycleVisibility:         model.SavedLifecycleVisibilityPublic,
		MediaReferenceRevision:      mediaRevision,
		MediaReferenceActive:        true,
		ExternalAvatarFileID:        &avatarFileID,
	}}
	userSource := &savedGuideUserSourceStub{snapshot: &SavedGuideUserSnapshot{
		UserID: userID, AccountStatus: "ACTIVE", Nickname: &nickname,
		AvatarFileID: &avatarFileID, Locale: "en",
		AccountUpdatedAt: now, ProfileUpdatedAt: now.Add(time.Second),
	}}
	useCase := NewSavedGuideSourceUseCase(
		repo,
		userSource,
		WithSavedGuideSourceClock(func() time.Time { return now.Add(2 * time.Second) }),
	)
	reference := fmt.Sprintf("guide-avatar:%s:%s:%d", userID, avatarFileID, mediaRevision)

	resolvedFileID, err := useCase.ResolveCurrentGuideAvatarReference(
		context.Background(),
		reference,
		mediaRevision,
	)
	if err != nil || resolvedFileID != avatarFileID {
		t.Fatalf("ResolveCurrentGuideAvatarReference() = %s, %v", resolvedFileID, err)
	}
	if _, err = useCase.ResolveCurrentGuideAvatarReference(
		context.Background(),
		reference,
		mediaRevision-1,
	); !errors.Is(err, ErrSavedGuideMediaReferenceUnavailable) {
		t.Fatalf("stale media reference revision resolved with error %v", err)
	}
	parsed, err := ParseSavedGuideAvatarReference(reference)
	if err != nil || parsed.GuideUserID != userID || parsed.AvatarFileID != avatarFileID ||
		parsed.Revision != mediaRevision || strings.Contains(reference, "://") {
		t.Fatalf("parsed opaque reference = %+v, %v", parsed, err)
	}

	invalidReferences := []string{
		"https://cdn.example.com/guide-avatar.jpg",
		strings.ToUpper(reference),
		reference + " ",
		fmt.Sprintf("guide-avatar:%s:%s:0", userID, avatarFileID),
		fmt.Sprintf("guide-avatar:%s:%s:%d", userID, avatarFileID, mediaRevision-1),
	}
	for _, invalidReference := range invalidReferences {
		if _, err = useCase.ResolveCurrentGuideAvatarReference(context.Background(), invalidReference); !errors.Is(err, ErrSavedGuideMediaReferenceUnavailable) {
			t.Fatalf("reference %q resolved with error %v", invalidReference, err)
		}
	}

	userSource.snapshot.AccountStatus = "BLOCKED"
	if _, err = useCase.ResolveCurrentGuideAvatarReference(context.Background(), reference); !errors.Is(err, ErrSavedGuideMediaReferenceUnavailable) {
		t.Fatalf("blocked user retained media reference: %v", err)
	}
	userSource.snapshot.AccountStatus = "ACTIVE"
	repo.snapshot.LifecycleVisibility = model.SavedLifecycleVisibilityUnavailable
	repo.snapshot.MediaReferenceActive = false
	if _, err = useCase.ResolveCurrentGuideAvatarReference(context.Background(), reference); !errors.Is(err, ErrSavedGuideMediaReferenceUnavailable) {
		t.Fatalf("deny lifecycle retained media reference: %v", err)
	}
}

func TestSavedGuideSourceDoesNotIssueAvatarBeforeMatchingReconciliation(t *testing.T) {
	userID := uuid.New()
	avatarFileID := uuid.New()
	staleAvatarFileID := uuid.New()
	now := time.Date(2026, 7, 10, 12, 0, 0, 0, time.UTC)
	approved := enum.VerificationRequestStatusApproved
	headline := "City guide"
	useCase := NewSavedGuideSourceUseCase(
		&savedGuideRepositoryStub{snapshot: &model.SavedGuideSnapshot{
			Profile: &model.GuideProfile{
				ID: uuid.New(), UserID: userID, Type: enum.GuideTypeIndependent,
				Status: enum.GuideStatusActive, Headline: &headline,
				CreatedAt: now.Add(-time.Hour), UpdatedAt: now,
			},
			LatestVerificationStatus:    &approved,
			LatestVerificationUpdatedAt: &now,
			SourceRevision:              uint64(now.UnixMicro()),
			ProjectionRevision:          uint64(now.UnixMicro()),
			VisibilityRevision:          uint64(now.UnixMicro()),
			LifecycleVisibility:         model.SavedLifecycleVisibilityPublic,
			MediaReferenceRevision:      uint64(now.UnixMicro()),
			MediaReferenceActive:        true,
			ExternalAvatarFileID:        &staleAvatarFileID,
		}},
		&savedGuideUserSourceStub{snapshot: &SavedGuideUserSnapshot{
			UserID: userID, AccountStatus: "ACTIVE", AvatarFileID: &avatarFileID,
			Locale: "en", AccountUpdatedAt: now, ProfileUpdatedAt: now.Add(time.Second),
		}},
		WithSavedGuideSourceClock(func() time.Time { return now.Add(2 * time.Second) }),
	)

	resolution, err := useCase.ResolveGuide(context.Background(), userID)
	if err != nil {
		t.Fatalf("ResolveGuide() error = %v", err)
	}
	if !resolution.Eligible || resolution.PublicProjection == nil {
		t.Fatalf("resolution = %+v, want public projection", resolution)
	}
	if resolution.PublicProjection.Media != nil {
		t.Fatalf("stale avatar reference was issued: %+v", resolution.PublicProjection.Media)
	}
}

func TestSavedGuideSourceDeletedLifecycleIsPayloadFree(t *testing.T) {
	userID := uuid.New()
	now := time.Date(2026, 7, 10, 12, 0, 0, 0, time.UTC)
	useCase := NewSavedGuideSourceUseCase(
		&savedGuideRepositoryStub{snapshot: &model.SavedGuideSnapshot{
			Profile: &model.GuideProfile{
				ID: uuid.New(), UserID: userID, Type: enum.GuideTypeIndependent,
				Status: enum.GuideStatusRevoked, CreatedAt: now.Add(-time.Hour), UpdatedAt: now,
			},
			SourceRevision:         uint64(now.UnixMicro()),
			ProjectionRevision:     uint64(now.UnixMicro()),
			VisibilityRevision:     uint64(now.UnixMicro()),
			LifecycleVisibility:    model.SavedLifecycleVisibilityDeleted,
			MediaReferenceRevision: uint64(now.UnixMicro()),
		}},
		&savedGuideUserSourceStub{err: errors.New("must not be called")},
		WithSavedGuideSourceClock(func() time.Time { return now.Add(time.Second) }),
	)

	resolution, err := useCase.ResolveGuide(context.Background(), userID)
	if err != nil {
		t.Fatalf("ResolveGuide() error = %v", err)
	}
	if resolution.Eligible || resolution.Visibility != SavedGuideVisibilityDeleted || resolution.PublicProjection != nil {
		t.Fatalf("resolution = %+v, want payload-free DELETED", resolution)
	}
}

func TestSavedGuideSourceNonPublicLifecycleIsPayloadFree(t *testing.T) {
	userID := uuid.New()
	now := time.Date(2026, 7, 10, 12, 0, 0, 0, time.UTC)
	approved := enum.VerificationRequestStatusApproved
	rejected := enum.VerificationRequestStatusRejected

	tests := []struct {
		name               string
		profileStatus      enum.GuideStatus
		verificationStatus *enum.VerificationRequestStatus
		userSnapshot       *SavedGuideUserSnapshot
	}{
		{name: "draft", profileStatus: enum.GuideStatusDraft, verificationStatus: nil},
		{name: "rejected", profileStatus: enum.GuideStatusRejected, verificationStatus: &rejected},
		{name: "suspended", profileStatus: enum.GuideStatusSuspended, verificationStatus: &approved},
		{name: "revoked", profileStatus: enum.GuideStatusRevoked, verificationStatus: &approved},
		{
			name:               "deleted user",
			profileStatus:      enum.GuideStatusActive,
			verificationStatus: &approved,
			userSnapshot: &SavedGuideUserSnapshot{
				UserID:           userID,
				AccountStatus:    "DELETED",
				IsDeleted:        true,
				Locale:           "en",
				AccountUpdatedAt: now.Add(time.Minute),
				ProfileUpdatedAt: now.Add(time.Minute),
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var verificationUpdatedAt *time.Time
			if tt.verificationStatus != nil {
				value := now.Add(30 * time.Second)
				verificationUpdatedAt = &value
			}
			useCase := NewSavedGuideSourceUseCase(
				&savedGuideRepositoryStub{snapshot: &model.SavedGuideSnapshot{
					Profile: &model.GuideProfile{
						ID:        uuid.New(),
						UserID:    userID,
						Type:      enum.GuideTypeIndependent,
						Status:    tt.profileStatus,
						RatingAvg: 5,
						CreatedAt: now.Add(-time.Hour),
						UpdatedAt: now,
					},
					LatestVerificationStatus:    tt.verificationStatus,
					LatestVerificationUpdatedAt: verificationUpdatedAt,
				}},
				&savedGuideUserSourceStub{snapshot: tt.userSnapshot},
				WithSavedGuideSourceClock(func() time.Time { return now.Add(time.Hour) }),
			)

			resolution, err := useCase.ResolveGuide(context.Background(), userID)
			if err != nil {
				t.Fatalf("ResolveGuide() error = %v", err)
			}
			if resolution.Eligible || resolution.Visibility != SavedGuideVisibilityUnavailable {
				t.Fatalf("resolution = %+v, want payload-free unavailable", resolution)
			}
			if resolution.PublicProjection != nil {
				t.Fatalf("non-public lifecycle leaked projection: %+v", resolution.PublicProjection)
			}
		})
	}
}

func TestSavedGuideSourceUnknownGuide(t *testing.T) {
	useCase := NewSavedGuideSourceUseCase(
		&savedGuideRepositoryStub{},
		&savedGuideUserSourceStub{},
	)
	_, err := useCase.ResolveGuide(context.Background(), uuid.New())
	if !errors.Is(err, ErrGuideProfileNotFound) {
		t.Fatalf("ResolveGuide() error = %v, want ErrGuideProfileNotFound", err)
	}
}

func TestSavedGuideSourceUnsupportedLocaleDoesNotInventProjection(t *testing.T) {
	userID := uuid.New()
	now := time.Date(2026, 7, 10, 12, 0, 0, 0, time.UTC)
	approved := enum.VerificationRequestStatusApproved
	useCase := NewSavedGuideSourceUseCase(
		&savedGuideRepositoryStub{snapshot: &model.SavedGuideSnapshot{
			Profile: &model.GuideProfile{
				ID:        uuid.New(),
				UserID:    userID,
				Type:      enum.GuideTypeIndependent,
				Status:    enum.GuideStatusActive,
				RatingAvg: 5,
				CreatedAt: now.Add(-time.Hour),
				UpdatedAt: now,
			},
			LatestVerificationStatus:    &approved,
			LatestVerificationUpdatedAt: &now,
		}},
		&savedGuideUserSourceStub{snapshot: &SavedGuideUserSnapshot{
			UserID:           userID,
			AccountStatus:    "ACTIVE",
			Locale:           "de",
			AccountUpdatedAt: now,
			ProfileUpdatedAt: now,
		}},
		WithSavedGuideSourceClock(func() time.Time { return now.Add(time.Minute) }),
	)

	resolution, err := useCase.ResolveGuide(context.Background(), userID)
	if err != nil {
		t.Fatalf("ResolveGuide() error = %v", err)
	}
	if resolution.Eligible || resolution.PublicProjection != nil {
		t.Fatalf("unsupported locale produced projection: %+v", resolution)
	}
}

type savedGuideRepositoryStub struct {
	snapshot *model.SavedGuideSnapshot
	err      error
}

func (s *savedGuideRepositoryStub) GetSavedSourceGuide(
	context.Context,
	uuid.UUID,
) (*model.SavedGuideSnapshot, error) {
	return s.snapshot, s.err
}

type savedGuideUserSourceStub struct {
	snapshot *SavedGuideUserSnapshot
	err      error
}

func (s *savedGuideUserSourceStub) GetSavedGuideUserSnapshot(
	context.Context,
	uuid.UUID,
) (*SavedGuideUserSnapshot, error) {
	return s.snapshot, s.err
}
