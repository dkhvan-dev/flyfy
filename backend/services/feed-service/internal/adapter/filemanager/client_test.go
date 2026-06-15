package filemanager

import (
	"errors"
	"testing"

	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/services/feed-service/internal/app"
)

func TestBindOrderMovesPrimaryLast(t *testing.T) {
	primaryID := uuid.New()
	imageID := uuid.New()
	galleryID := uuid.New()

	got := bindOrder([]uuid.UUID{primaryID, imageID, galleryID}, primaryID)

	want := []uuid.UUID{imageID, galleryID, primaryID}
	if len(got) != len(want) {
		t.Fatalf("bind order length = %d, want %d; got %v", len(got), len(want), got)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("bind order[%d] = %s, want %s; full order %v", i, got[i], want[i], got)
		}
	}
}

func TestPostMediaBindingUsesPostFileContract(t *testing.T) {
	if postOwnerType != "POST" {
		t.Fatalf("post owner type = %q, want POST", postOwnerType)
	}
	if postMediaPurpose != "POST_MEDIA" {
		t.Fatalf("post media purpose = %q, want POST_MEDIA", postMediaPurpose)
	}
}

func TestMapBindFileErrorMapsBusinessGRPCErrorsToInvalidPostMedia(t *testing.T) {
	for _, code := range []codes.Code{
		codes.InvalidArgument,
		codes.NotFound,
		codes.FailedPrecondition,
		codes.PermissionDenied,
		codes.Aborted,
	} {
		t.Run(code.String(), func(t *testing.T) {
			err := mapBindFileError(status.Error(code, "file_not_ready"))
			if !errors.Is(err, app.ErrInvalidPostMedia) {
				t.Fatalf("mapped error = %v, want %v", err, app.ErrInvalidPostMedia)
			}
		})
	}
}

func TestMapBindFileErrorLeavesTechnicalGRPCErrorsUnmapped(t *testing.T) {
	err := mapBindFileError(status.Error(codes.Unavailable, "transport unavailable"))
	if errors.Is(err, app.ErrInvalidPostMedia) {
		t.Fatalf("mapped technical error to business error: %v", err)
	}
}
