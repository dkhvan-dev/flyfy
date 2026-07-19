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

func TestGetPublicPlaceHidesDraftAndDeletedWhileAdminReadRemainsAvailable(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		status  enum.PlaceStatus
		deleted bool
		public  bool
	}{
		{name: "published", status: enum.StatusPublished, public: true},
		{name: "draft", status: enum.StatusDraft},
		{name: "deleted", status: enum.StatusPublished, deleted: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			placeID := uuid.New()
			place := &model.Place{
				ID:            placeID,
				AuthorUserID:  uuid.New(),
				Status:        test.status,
				DefaultLocale: "en",
			}
			if test.deleted {
				deletedAt := time.Now().UTC()
				place.DeletedAt = &deletedAt
			}
			repo := &adminPlaceRepoStub{created: place}
			useCase := NewPlaceUseCase(repo, &adminPlaceUserClientStub{})

			publicView, err := useCase.GetPublicPlace(context.Background(), placeID, "en")
			if test.public {
				if err != nil || publicView == nil || publicView.Place == nil {
					t.Fatalf("GetPublicPlace() = %#v, %v", publicView, err)
				}
			} else if !errors.Is(err, ErrPlaceNotFound) || publicView != nil {
				t.Fatalf("GetPublicPlace() = %#v, %v, want neutral not found", publicView, err)
			}

			adminView, adminErr := useCase.GetPlace(context.Background(), placeID, "en")
			if adminErr != nil || adminView == nil || adminView.Place == nil {
				t.Fatalf("GetPlace() = %#v, %v, want internal record", adminView, adminErr)
			}
		})
	}
}
