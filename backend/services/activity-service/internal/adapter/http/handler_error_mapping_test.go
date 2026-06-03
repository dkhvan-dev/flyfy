package http

import (
	"errors"
	nethttp "net/http"
	"net/http/httptest"
	"testing"

	"kz/inflap/backend/services/activity-service/internal/app"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

func TestWriteAppErrorMapsStateConflictsToHTTP409(t *testing.T) {
	t.Parallel()

	cases := []struct {
		name string
		err  error
	}{
		{name: "already joined", err: app.ErrAlreadyJoined},
		{name: "activity full", err: app.ErrActivityFull},
		{name: "not completable", err: app.ErrActivityNotCompletable},
		{name: "price change forbidden", err: app.ErrPriceChangeForbidden},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			recorder := httptest.NewRecorder()
			(&Handler{}).writeAppError(recorder, tc.err, "fallback")

			if recorder.Code != nethttp.StatusConflict {
				t.Fatalf("status = %d, want %d", recorder.Code, nethttp.StatusConflict)
			}
		})
	}
}

func TestWriteAppErrorMapsForbiddenActivityActionsToHTTP403(t *testing.T) {
	t.Parallel()

	cases := []struct {
		name string
		err  error
	}{
		{name: "invalid actor ownership", err: app.ErrInvalidActorUserID},
		{name: "duplicate by non author", err: model.ErrOnlyAuthorCanDuplicate},
		{name: "wrapped duplicate by non author", err: errors.Join(model.ErrOnlyAuthorCanDuplicate)},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			recorder := httptest.NewRecorder()
			(&Handler{}).writeAppError(recorder, tc.err, "fallback")

			if recorder.Code != nethttp.StatusForbidden {
				t.Fatalf("status = %d, want %d", recorder.Code, nethttp.StatusForbidden)
			}
		})
	}
}
