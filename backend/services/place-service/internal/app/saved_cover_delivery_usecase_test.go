package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestSavedAttractionCoverDeliveryReturnsValidatedURLForCurrentPublicCover(t *testing.T) {
	attractionID := uuid.New()
	fileID := uuid.New()
	repo := &savedCoverRepositoryStub{snapshot: &model.SavedAttractionCoverSnapshot{
		ID:                 attractionID,
		Status:             enum.StatusPublished,
		ProjectionRevision: 42,
		FileID:             fileID,
	}}
	files := &savedCoverFileManagerStub{
		downloadURL: "https://media.example.test/cover?signature=short-lived",
	}
	useCase := NewSavedAttractionCoverDeliveryUseCase(repo, files)

	got, err := useCase.CreatePublicSavedAttractionCoverDownloadURL(
		context.Background(),
		attractionID,
		42,
	)
	if err != nil || got != files.downloadURL {
		t.Fatalf("CreatePublicSavedAttractionCoverDownloadURL() = %q, %v", got, err)
	}
	if repo.calls != 1 || files.calls != 1 || files.fileID != fileID {
		t.Fatalf("repository/file calls/file ID = %d/%d/%s", repo.calls, files.calls, files.fileID)
	}
}

func TestSavedAttractionCoverDeliveryRejectsDeniedOrStaleStateBeforeFileManager(t *testing.T) {
	attractionID := uuid.New()
	now := time.Now()
	tests := []struct {
		name     string
		snapshot *model.SavedAttractionCoverSnapshot
	}{
		{name: "missing"},
		{name: "stale revision", snapshot: savedCoverSnapshot(attractionID, 41, uuid.New())},
		{name: "draft", snapshot: func() *model.SavedAttractionCoverSnapshot {
			snapshot := savedCoverSnapshot(attractionID, 42, uuid.New())
			snapshot.Status = enum.StatusDraft
			return snapshot
		}()},
		{name: "deleted", snapshot: func() *model.SavedAttractionCoverSnapshot {
			snapshot := savedCoverSnapshot(attractionID, 42, uuid.New())
			snapshot.DeletedAt = &now
			return snapshot
		}()},
		{name: "different target", snapshot: savedCoverSnapshot(uuid.New(), 42, uuid.New())},
		{name: "external only", snapshot: &model.SavedAttractionCoverSnapshot{
			ID:                 attractionID,
			Status:             enum.StatusPublished,
			ProjectionRevision: 42,
			ExternalURL:        "https://external.example.test/cover.jpg",
		}},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			repo := &savedCoverRepositoryStub{snapshot: test.snapshot}
			files := &savedCoverFileManagerStub{}
			useCase := NewSavedAttractionCoverDeliveryUseCase(repo, files)

			_, err := useCase.CreatePublicSavedAttractionCoverDownloadURL(
				context.Background(),
				attractionID,
				42,
			)
			if !errors.Is(err, ErrPublicSavedAttractionCoverNotFound) {
				t.Fatalf("error = %v, want neutral not found", err)
			}
			if repo.calls != 1 || files.calls != 0 {
				t.Fatalf("repository/file calls = %d/%d, want 1/0", repo.calls, files.calls)
			}
		})
	}
}

func TestSavedAttractionCoverDeliveryRejectsInvalidInputBeforeRepository(t *testing.T) {
	repo := &savedCoverRepositoryStub{}
	files := &savedCoverFileManagerStub{}
	useCase := NewSavedAttractionCoverDeliveryUseCase(repo, files)

	for _, input := range []struct {
		id       uuid.UUID
		revision uint64
	}{
		{id: uuid.Nil, revision: 1},
		{id: uuid.New(), revision: 0},
	} {
		_, err := useCase.CreatePublicSavedAttractionCoverDownloadURL(
			context.Background(),
			input.id,
			input.revision,
		)
		if !errors.Is(err, ErrPublicSavedAttractionCoverNotFound) {
			t.Fatalf("error = %v, want neutral not found", err)
		}
	}
	if repo.calls != 0 || files.calls != 0 {
		t.Fatalf("invalid input repository/file calls = %d/%d, want 0/0", repo.calls, files.calls)
	}
}

func TestSavedAttractionCoverDeliveryRejectsMaliciousFileManagerURL(t *testing.T) {
	attractionID := uuid.New()
	repo := &savedCoverRepositoryStub{snapshot: savedCoverSnapshot(attractionID, 42, uuid.New())}
	files := &savedCoverFileManagerStub{
		downloadURL: "https://media.example.test/cover?token=%0d%0aLocation%3a%20https://attacker.test",
	}
	useCase := NewSavedAttractionCoverDeliveryUseCase(repo, files)

	_, err := useCase.CreatePublicSavedAttractionCoverDownloadURL(
		context.Background(),
		attractionID,
		42,
	)
	if !errors.Is(err, ErrPublicSavedAttractionCoverBadGateway) {
		t.Fatalf("error = %v, want bad gateway", err)
	}
	if files.calls != 1 {
		t.Fatalf("file-manager calls = %d, want 1", files.calls)
	}
}

func TestSavedAttractionCoverDeliveryClassifiesDependencyFailures(t *testing.T) {
	attractionID := uuid.New()
	tests := []struct {
		name    string
		fileErr error
		wantErr error
	}{
		{name: "missing file", fileErr: ErrSavedCoverFileNotFound, wantErr: ErrPublicSavedAttractionCoverNotFound},
		{name: "unavailable", fileErr: ErrSavedCoverFileManagerUnavailable, wantErr: ErrPublicSavedAttractionCoverUnavailable},
		{name: "bad response", fileErr: ErrSavedCoverFileManagerBadResponse, wantErr: ErrPublicSavedAttractionCoverBadGateway},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			useCase := NewSavedAttractionCoverDeliveryUseCase(
				&savedCoverRepositoryStub{snapshot: savedCoverSnapshot(attractionID, 42, uuid.New())},
				&savedCoverFileManagerStub{err: test.fileErr},
			)
			_, err := useCase.CreatePublicSavedAttractionCoverDownloadURL(
				context.Background(),
				attractionID,
				42,
			)
			if !errors.Is(err, test.wantErr) {
				t.Fatalf("error = %v, want %v", err, test.wantErr)
			}
		})
	}
}

func savedCoverSnapshot(
	attractionID uuid.UUID,
	revision uint64,
	fileID uuid.UUID,
) *model.SavedAttractionCoverSnapshot {
	return &model.SavedAttractionCoverSnapshot{
		ID:                 attractionID,
		Status:             enum.StatusPublished,
		ProjectionRevision: revision,
		FileID:             fileID,
	}
}

type savedCoverRepositoryStub struct {
	snapshot *model.SavedAttractionCoverSnapshot
	err      error
	calls    int
}

func (s *savedCoverRepositoryStub) GetSavedAttractionCoverSnapshot(
	context.Context,
	uuid.UUID,
) (*model.SavedAttractionCoverSnapshot, error) {
	s.calls++
	return s.snapshot, s.err
}

type savedCoverFileManagerStub struct {
	downloadURL string
	err         error
	fileID      uuid.UUID
	calls       int
}

func (s *savedCoverFileManagerStub) CreateDownloadURL(
	_ context.Context,
	fileID uuid.UUID,
) (string, error) {
	s.calls++
	s.fileID = fileID
	return s.downloadURL, s.err
}
