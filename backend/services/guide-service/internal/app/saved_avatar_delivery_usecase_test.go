package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
)

func TestSavedGuideAvatarDeliveryReturnsValidatedURLAfterCurrentPublicChecks(t *testing.T) {
	delivery, _, _, files, userID, avatarFileID, revision := newSavedGuideAvatarDeliveryFixture()

	downloadURL, err := delivery.CreatePublicSavedGuideAvatarDownloadURL(
		context.Background(),
		userID,
		revision,
	)
	if err != nil {
		t.Fatalf("CreatePublicSavedGuideAvatarDownloadURL() error = %v", err)
	}
	if downloadURL != files.downloadURL {
		t.Fatalf("download URL = %q, want %q", downloadURL, files.downloadURL)
	}
	if files.calls != 1 || files.lastFileID != avatarFileID {
		t.Fatalf("file-manager calls/file ID = %d/%s, want 1/%s", files.calls, files.lastFileID, avatarFileID)
	}
}

func TestSavedGuideAvatarDeliveryRejectsStaleRevisionBeforeFileManager(t *testing.T) {
	delivery, _, _, files, userID, _, revision := newSavedGuideAvatarDeliveryFixture()

	_, err := delivery.CreatePublicSavedGuideAvatarDownloadURL(
		context.Background(),
		userID,
		revision-1,
	)
	if !errors.Is(err, ErrPublicSavedGuideAvatarNotFound) {
		t.Fatalf("CreatePublicSavedGuideAvatarDownloadURL() error = %v, want not found", err)
	}
	if files.calls != 0 {
		t.Fatalf("stale projection made %d file-manager calls, want 0", files.calls)
	}
}

func TestSavedGuideAvatarDeliveryDoesNotAcceptProjectionRevisionAsMediaRevision(t *testing.T) {
	delivery, _, _, files, userID, _, mediaRevision := newSavedGuideAvatarDeliveryFixture()
	projectionRevision := mediaRevision + 10_000

	_, err := delivery.CreatePublicSavedGuideAvatarDownloadURL(
		context.Background(),
		userID,
		projectionRevision,
	)
	if !errors.Is(err, ErrPublicSavedGuideAvatarNotFound) {
		t.Fatalf("CreatePublicSavedGuideAvatarDownloadURL() error = %v, want not found", err)
	}
	if files.calls != 0 {
		t.Fatalf("projection revision made %d file-manager calls, want 0", files.calls)
	}
}

func TestSavedGuideAvatarDeliveryRejectsNonPublicSourceBeforeFileManager(t *testing.T) {
	delivery, repo, _, files, userID, _, revision := newSavedGuideAvatarDeliveryFixture()
	repo.snapshot.LifecycleVisibility = model.SavedLifecycleVisibilityUnavailable

	_, err := delivery.CreatePublicSavedGuideAvatarDownloadURL(
		context.Background(),
		userID,
		revision,
	)
	if !errors.Is(err, ErrPublicSavedGuideAvatarNotFound) {
		t.Fatalf("CreatePublicSavedGuideAvatarDownloadURL() error = %v, want not found", err)
	}
	if files.calls != 0 {
		t.Fatalf("non-public source made %d file-manager calls, want 0", files.calls)
	}
}

func TestSavedGuideAvatarDeliveryAllowsProjectionChangeWhenAvatarReferenceIsCurrent(t *testing.T) {
	_, repo, users, files, userID, _, revision := newSavedGuideAvatarDeliveryFixture()
	firstSnapshot := *users.snapshot
	secondSnapshot := firstSnapshot
	secondSnapshot.ProfileUpdatedAt = secondSnapshot.ProfileUpdatedAt.Add(time.Second)
	source := NewSavedGuideSourceUseCase(
		repo,
		&sequencedSavedGuideUserSourceStub{snapshots: []*SavedGuideUserSnapshot{
			&firstSnapshot,
			&secondSnapshot,
		}},
	)
	delivery := NewSavedGuideAvatarDeliveryUseCase(source, files)

	downloadURL, err := delivery.CreatePublicSavedGuideAvatarDownloadURL(
		context.Background(),
		userID,
		revision,
	)
	if err != nil {
		t.Fatalf("CreatePublicSavedGuideAvatarDownloadURL() error = %v", err)
	}
	if downloadURL != files.downloadURL || files.calls != 1 {
		t.Fatalf(
			"changed projection URL/file calls = %q/%d, want %q/1",
			downloadURL,
			files.calls,
			files.downloadURL,
		)
	}
}

func TestSavedGuideAvatarDeliveryRechecksAccountApprovalAndAvatar(t *testing.T) {
	tests := []struct {
		name   string
		mutate func(*savedGuideRepositoryStub, *savedGuideUserSourceStub)
	}{
		{
			name: "inactive account",
			mutate: func(_ *savedGuideRepositoryStub, users *savedGuideUserSourceStub) {
				users.snapshot.AccountStatus = "BLOCKED"
			},
		},
		{
			name: "latest verification rejected",
			mutate: func(repo *savedGuideRepositoryStub, _ *savedGuideUserSourceStub) {
				rejected := enum.VerificationRequestStatusRejected
				repo.snapshot.LatestVerificationStatus = &rejected
			},
		},
		{
			name: "inactive avatar reference",
			mutate: func(repo *savedGuideRepositoryStub, _ *savedGuideUserSourceStub) {
				repo.snapshot.MediaReferenceActive = false
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			delivery, repo, users, files, userID, _, revision := newSavedGuideAvatarDeliveryFixture()
			test.mutate(repo, users)

			_, err := delivery.CreatePublicSavedGuideAvatarDownloadURL(
				context.Background(),
				userID,
				revision,
			)
			if !errors.Is(err, ErrPublicSavedGuideAvatarNotFound) {
				t.Fatalf("CreatePublicSavedGuideAvatarDownloadURL() error = %v, want not found", err)
			}
			if files.calls != 0 {
				t.Fatalf("denied source made %d file-manager calls, want 0", files.calls)
			}
		})
	}
}

func TestSavedGuideAvatarDeliveryRejectsInvalidFileManagerURL(t *testing.T) {
	delivery, _, _, files, userID, _, revision := newSavedGuideAvatarDeliveryFixture()
	files.downloadURL = "https://user:secret@media.example.test/avatar"

	_, err := delivery.CreatePublicSavedGuideAvatarDownloadURL(
		context.Background(),
		userID,
		revision,
	)
	if !errors.Is(err, ErrPublicSavedGuideAvatarUnavailable) {
		t.Fatalf("CreatePublicSavedGuideAvatarDownloadURL() error = %v, want unavailable", err)
	}
	if files.calls != 1 {
		t.Fatalf("file-manager calls = %d, want 1", files.calls)
	}
}

func newSavedGuideAvatarDeliveryFixture() (
	*SavedGuideAvatarDeliveryUseCase,
	*savedGuideRepositoryStub,
	*savedGuideUserSourceStub,
	*savedAvatarFileManagerStub,
	uuid.UUID,
	uuid.UUID,
	uint64,
) {
	userID := uuid.New()
	avatarFileID := uuid.New()
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	mediaRevision := uint64(now.UnixMicro())
	projectionRevision := mediaRevision + 10_000
	approved := enum.VerificationRequestStatusApproved
	nickname := "Aruzhan"
	repo := &savedGuideRepositoryStub{snapshot: &model.SavedGuideSnapshot{
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
		SourceRevision:              projectionRevision,
		ProjectionRevision:          projectionRevision,
		VisibilityRevision:          projectionRevision,
		LifecycleVisibility:         model.SavedLifecycleVisibilityPublic,
		MediaReferenceRevision:      mediaRevision,
		MediaReferenceActive:        true,
		ExternalAvatarFileID:        &avatarFileID,
	}}
	users := &savedGuideUserSourceStub{snapshot: &SavedGuideUserSnapshot{
		UserID:           userID,
		AccountStatus:    "ACTIVE",
		Nickname:         &nickname,
		AvatarFileID:     &avatarFileID,
		Locale:           "en",
		AccountUpdatedAt: now,
		ProfileUpdatedAt: now,
	}}
	files := &savedAvatarFileManagerStub{
		downloadURL: "https://media.example.test/avatar?signature=short-lived",
	}
	source := NewSavedGuideSourceUseCase(
		repo,
		users,
		WithSavedGuideSourceClock(func() time.Time { return now.Add(time.Minute) }),
	)
	return NewSavedGuideAvatarDeliveryUseCase(source, files),
		repo, users, files, userID, avatarFileID, mediaRevision
}

type savedAvatarFileManagerStub struct {
	downloadURL string
	err         error
	calls       int
	lastFileID  uuid.UUID
}

func (s *savedAvatarFileManagerStub) CreateDownloadURL(
	_ context.Context,
	fileID uuid.UUID,
) (string, error) {
	s.calls++
	s.lastFileID = fileID
	return s.downloadURL, s.err
}

type sequencedSavedGuideUserSourceStub struct {
	snapshots []*SavedGuideUserSnapshot
	calls     int
}

func (s *sequencedSavedGuideUserSourceStub) GetSavedGuideUserSnapshot(
	context.Context,
	uuid.UUID,
) (*SavedGuideUserSnapshot, error) {
	index := s.calls
	s.calls++
	if index >= len(s.snapshots) {
		index = len(s.snapshots) - 1
	}
	return s.snapshots[index], nil
}
