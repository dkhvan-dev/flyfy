package http

import (
	"context"
	stdhttp "net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/app"
	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
	"kz/inflap/backend/services/place-service/internal/domain/port"
)

func TestGetPlacePublicRouteHidesDraftAndDeletedRecords(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name      string
		status    enum.PlaceStatus
		deletedAt *time.Time
		wantCode  int
	}{
		{name: "published", status: enum.StatusPublished, wantCode: stdhttp.StatusOK},
		{name: "draft", status: enum.StatusDraft, wantCode: stdhttp.StatusNotFound},
		{
			name:      "deleted",
			status:    enum.StatusPublished,
			deletedAt: timePointer(time.Date(2026, time.July, 16, 9, 0, 0, 0, time.UTC)),
			wantCode:  stdhttp.StatusNotFound,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			placeID := uuid.New()
			handler := newPublicVisibilityTestHandler(&model.Place{
				ID:            placeID,
				AuthorUserID:  uuid.New(),
				DefaultLocale: "en",
				Locale:        "en",
				Title:         "Visibility test attraction",
				CountryCode:   "KZ",
				CityID:        "almaty",
				Category:      enum.CategoryNature,
				Source:        enum.SourceImport,
				Status:        test.status,
				CreatedAt:     time.Date(2026, time.July, 16, 8, 0, 0, 0, time.UTC),
				UpdatedAt:     time.Date(2026, time.July, 16, 8, 0, 0, 0, time.UTC),
				DeletedAt:     test.deletedAt,
			})
			mux := stdhttp.NewServeMux()
			handler.Register(mux)
			request := httptest.NewRequest(stdhttp.MethodGet, "/v1/places/"+placeID.String(), nil)
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != test.wantCode {
				t.Fatalf("status = %d, want %d: %s", response.Code, test.wantCode, response.Body.String())
			}
		})
	}
}

func TestGetPlaceInternalAdminRouteCanInspectDraft(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	handler := newPublicVisibilityTestHandler(&model.Place{
		ID:            placeID,
		AuthorUserID:  uuid.New(),
		DefaultLocale: "en",
		Locale:        "en",
		Title:         "Draft attraction",
		CountryCode:   "KZ",
		CityID:        "almaty",
		Category:      enum.CategoryNature,
		Source:        enum.SourceImport,
		Status:        enum.StatusDraft,
		CreatedAt:     time.Date(2026, time.July, 16, 8, 0, 0, 0, time.UTC),
		UpdatedAt:     time.Date(2026, time.July, 16, 8, 0, 0, 0, time.UTC),
	})
	mux := stdhttp.NewServeMux()
	handler.Register(mux)
	request := httptest.NewRequest(
		stdhttp.MethodGet,
		"/internal/v1/admin/places/"+placeID.String(),
		nil,
	)
	response := httptest.NewRecorder()

	mux.ServeHTTP(response, request)

	if response.Code != stdhttp.StatusOK {
		t.Fatalf("status = %d, want 200: %s", response.Code, response.Body.String())
	}
}

func newPublicVisibilityTestHandler(place *model.Place) *Handler {
	repository := &publicVisibilityRepository{place: place}
	users := &publicVisibilityUsers{}
	return NewHandler(app.NewPlaceUseCase(repository, users))
}

type publicVisibilityRepository struct {
	port.PlaceRepository
	place *model.Place
}

func (r *publicVisibilityRepository) GetPlaceByID(
	_ context.Context,
	id uuid.UUID,
	locale string,
) (*model.Place, error) {
	if r.place == nil || r.place.ID != id {
		return nil, nil
	}
	copy := *r.place
	copy.Locale = locale
	return &copy, nil
}

type publicVisibilityUsers struct {
	app.UserServiceClient
}

func (u *publicVisibilityUsers) GetPublicUserProfiles(
	_ context.Context,
	userIDs []uuid.UUID,
) (map[uuid.UUID]app.PublicUserProfile, error) {
	profiles := make(map[uuid.UUID]app.PublicUserProfile, len(userIDs))
	for _, userID := range userIDs {
		profiles[userID] = app.PublicUserProfile{UserID: userID}
	}
	return profiles, nil
}

func timePointer(value time.Time) *time.Time {
	return &value
}
