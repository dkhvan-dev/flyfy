package http

import (
	"context"
	"io"
	nethttp "net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/app"
	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

type activityVisibilityRepositoryStub struct {
	port.ActivityRepository

	activity         *model.Activity
	participant      *model.ActivityParticipant
	media            []*model.ActivityMedia
	tagCalls         int
	mediaCalls       int
	ratingCalls      int
	participantCalls int
}

func (s *activityVisibilityRepositoryStub) GetActivityByID(
	context.Context,
	uuid.UUID,
) (*model.Activity, error) {
	return s.activity, nil
}

func (s *activityVisibilityRepositoryStub) GetParticipantByActivityAndUser(
	context.Context,
	uuid.UUID,
	uuid.UUID,
) (*model.ActivityParticipant, error) {
	s.participantCalls++
	return s.participant, nil
}

func (s *activityVisibilityRepositoryStub) ListTagsByActivityID(
	context.Context,
	uuid.UUID,
) ([]string, error) {
	s.tagCalls++
	return []string{"walking"}, nil
}

func (s *activityVisibilityRepositoryStub) ListMediaByActivityID(
	context.Context,
	uuid.UUID,
) ([]*model.ActivityMedia, error) {
	s.mediaCalls++
	return s.media, nil
}

func (s *activityVisibilityRepositoryStub) GetActivityOrganizerRatingByHostUserID(
	context.Context,
	uuid.UUID,
) (float64, error) {
	s.ratingCalls++
	return 4.8, nil
}

type activityViewerResolverStub struct {
	userID uuid.UUID
}

func (s activityViewerResolverStub) ResolveUserIDBySubject(
	context.Context,
	string,
) (uuid.UUID, error) {
	return s.userID, nil
}

func (activityViewerResolverStub) ResolveRolesBySubject(context.Context, string) ([]string, error) {
	return nil, nil
}

type activityCoverFileManagerStub struct {
	downloadURL string
	calls       int
}

type activityCoverRoundTripper func(*nethttp.Request) (*nethttp.Response, error)

func (fn activityCoverRoundTripper) RoundTrip(request *nethttp.Request) (*nethttp.Response, error) {
	return fn(request)
}

func (*activityCoverFileManagerStub) ValidateActivityMediaFile(context.Context, uuid.UUID) error {
	return nil
}

func (*activityCoverFileManagerStub) BindActivityMediaToActivity(
	context.Context,
	uuid.UUID,
	uuid.UUID,
	uuid.UUID,
) error {
	return nil
}

func (s *activityCoverFileManagerStub) CreateDownloadURL(
	context.Context,
	uuid.UUID,
) (string, error) {
	s.calls++
	return s.downloadURL, nil
}

func TestGetActivityDetailHidesNonPublicActivityWithNeutralNotFound(t *testing.T) {
	t.Parallel()

	actorID := uuid.New()
	tests := []struct {
		name   string
		mutate func(*model.Activity)
	}{
		{
			name: "private",
			mutate: func(item *model.Activity) {
				item.Visibility = enum.ActivityVisibilityPrivate
			},
		},
		{
			name: "unlisted",
			mutate: func(item *model.Activity) {
				item.Visibility = enum.ActivityVisibilityUnlisted
			},
		},
		{
			name: "archived",
			mutate: func(item *model.Activity) {
				item.Status = enum.ActivityStatusArchived
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()

			item := activityVisibilityTestActivity()
			test.mutate(item)
			repo := &activityVisibilityRepositoryStub{
				activity: item,
				media:    []*model.ActivityMedia{{ActivityID: item.ID, FileID: uuid.New()}},
			}
			handler := newActivityVisibilityTestHandler(repo, actorID, nil)
			response := httptest.NewRecorder()
			handler.GetActivityByID(response, activityViewerRequest("/v1/activities/"+item.ID.String()), item.ID)

			missingRepo := &activityVisibilityRepositoryStub{}
			missingHandler := newActivityVisibilityTestHandler(missingRepo, actorID, nil)
			missingResponse := httptest.NewRecorder()
			missingHandler.GetActivityByID(
				missingResponse,
				activityViewerRequest("/v1/activities/"+item.ID.String()),
				item.ID,
			)

			if response.Code != nethttp.StatusNotFound || missingResponse.Code != nethttp.StatusNotFound {
				t.Fatalf("denied/missing status = %d/%d, want 404/404", response.Code, missingResponse.Code)
			}
			if response.Body.String() != missingResponse.Body.String() {
				t.Fatalf("denied body %q differs from missing body %q", response.Body.String(), missingResponse.Body.String())
			}
			if repo.tagCalls != 0 || repo.mediaCalls != 0 || repo.ratingCalls != 0 {
				t.Fatalf("denied detail loaded payload: tags/media/rating = %d/%d/%d", repo.tagCalls, repo.mediaCalls, repo.ratingCalls)
			}
		})
	}
}

func TestGetActivityDetailAllowsOwnerAndPublicViewer(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		visibility enum.ActivityVisibility
		owner      bool
	}{
		{name: "public viewer", visibility: enum.ActivityVisibilityPublic},
		{name: "private owner", visibility: enum.ActivityVisibilityPrivate, owner: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()

			actorID := uuid.New()
			item := activityVisibilityTestActivity()
			item.Visibility = test.visibility
			if test.owner {
				item.HostUserID = actorID
			}
			repo := &activityVisibilityRepositoryStub{
				activity: item,
				media:    []*model.ActivityMedia{{ActivityID: item.ID, FileID: uuid.New(), IsCover: true}},
			}
			handler := newActivityVisibilityTestHandler(repo, actorID, nil)
			response := httptest.NewRecorder()
			handler.GetActivityByID(response, activityViewerRequest("/v1/activities/"+item.ID.String()), item.ID)

			if response.Code != nethttp.StatusOK {
				t.Fatalf("status = %d, want 200; body = %s", response.Code, response.Body.String())
			}
			if repo.tagCalls != 1 || repo.mediaCalls != 1 || repo.ratingCalls != 1 {
				t.Fatalf("allowed detail payload calls tags/media/rating = %d/%d/%d", repo.tagCalls, repo.mediaCalls, repo.ratingCalls)
			}
		})
	}
}

func TestGetActivityCoverHidesPrivateMediaBeforeLookup(t *testing.T) {
	t.Parallel()

	actorID := uuid.New()
	item := activityVisibilityTestActivity()
	item.Visibility = enum.ActivityVisibilityPrivate
	repo := &activityVisibilityRepositoryStub{
		activity: item,
		media:    []*model.ActivityMedia{{ActivityID: item.ID, FileID: uuid.New(), IsCover: true}},
	}
	files := &activityCoverFileManagerStub{downloadURL: "http://unused.test"}
	handler := newActivityVisibilityTestHandler(repo, actorID, files)
	response := httptest.NewRecorder()
	handler.GetActivityCover(
		response,
		activityViewerRequest("/v1/activities/"+item.ID.String()+"/cover?revision=17"),
		item.ID,
	)
	missingHandler := newActivityVisibilityTestHandler(
		&activityVisibilityRepositoryStub{},
		actorID,
		files,
	)
	missingResponse := httptest.NewRecorder()
	missingHandler.GetActivityCover(
		missingResponse,
		activityViewerRequest("/v1/activities/"+item.ID.String()+"/cover?revision=17"),
		item.ID,
	)

	if response.Code != nethttp.StatusNotFound || missingResponse.Code != nethttp.StatusNotFound {
		t.Fatalf("denied/missing status = %d/%d, want 404/404", response.Code, missingResponse.Code)
	}
	if response.Body.String() != missingResponse.Body.String() {
		t.Fatalf("denied body %q differs from missing body %q", response.Body.String(), missingResponse.Body.String())
	}
	if repo.mediaCalls != 0 || files.calls != 0 {
		t.Fatalf("denied cover media/file calls = %d/%d, want 0/0", repo.mediaCalls, files.calls)
	}
}

func TestGetActivityCoverAllowsOwnerAndPublicViewerWithoutSharedCaching(t *testing.T) {
	t.Parallel()

	coverClient := &nethttp.Client{Transport: activityCoverRoundTripper(func(*nethttp.Request) (*nethttp.Response, error) {
		return &nethttp.Response{
			StatusCode: nethttp.StatusOK,
			Header:     nethttp.Header{"Content-Type": []string{"image/jpeg"}},
			Body:       io.NopCloser(strings.NewReader("image-bytes")),
		}, nil
	})}

	tests := []struct {
		name       string
		visibility enum.ActivityVisibility
		owner      bool
		anonymous  bool
		query      string
	}{
		{name: "anonymous public viewer", visibility: enum.ActivityVisibilityPublic, anonymous: true, query: "revision=17"},
		{name: "current public Saved reference", visibility: enum.ActivityVisibilityPublic, anonymous: true, query: "saved_revision=101"},
		{name: "private owner domain reference", visibility: enum.ActivityVisibilityPrivate, owner: true, query: "revision=17"},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			actorID := uuid.New()
			item := activityVisibilityTestActivity()
			item.Visibility = test.visibility
			if test.owner {
				item.HostUserID = actorID
			}
			repo := &activityVisibilityRepositoryStub{
				activity: item,
				media:    []*model.ActivityMedia{{ActivityID: item.ID, FileID: uuid.New(), IsCover: true}},
			}
			files := &activityCoverFileManagerStub{downloadURL: "https://media.internal.test/activity-cover"}
			handler := newActivityVisibilityTestHandler(repo, actorID, files)
			handler.coverHTTPClient = coverClient
			response := httptest.NewRecorder()
			target := "/v1/activities/" + item.ID.String() + "/cover?" + test.query
			request := activityViewerRequest(target)
			if test.anonymous {
				request = httptest.NewRequest(
					nethttp.MethodGet,
					target,
					nil,
				)
			}
			handler.GetActivityCover(
				response,
				request,
				item.ID,
			)

			if response.Code != nethttp.StatusOK || response.Body.String() != "image-bytes" {
				t.Fatalf("status/body = %d/%q, want 200/image-bytes", response.Code, response.Body.String())
			}
			if response.Header().Get("Cache-Control") != "private, no-store" {
				t.Fatalf("Cache-Control = %q, want private, no-store", response.Header().Get("Cache-Control"))
			}
			if repo.mediaCalls != 1 || files.calls != 1 {
				t.Fatalf("allowed cover media/file calls = %d/%d, want 1/1", repo.mediaCalls, files.calls)
			}
		})
	}
}

func TestGetActivityCoverRejectsStaleSavedMediaReference(t *testing.T) {
	t.Parallel()

	item := activityVisibilityTestActivity()
	repo := &activityVisibilityRepositoryStub{
		activity: item,
		media:    []*model.ActivityMedia{{ActivityID: item.ID, FileID: uuid.New(), IsCover: true}},
	}
	files := &activityCoverFileManagerStub{downloadURL: "http://unused.test"}
	handler := newActivityVisibilityTestHandler(repo, uuid.New(), files)
	response := httptest.NewRecorder()
	handler.GetActivityCover(
		response,
		activityViewerRequest("/v1/activities/"+item.ID.String()+"/cover?saved_revision=100"),
		item.ID,
	)

	if response.Code != nethttp.StatusNotFound || repo.mediaCalls != 0 || files.calls != 0 {
		t.Fatalf("stale reference status/media/file calls = %d/%d/%d, want 404/0/0", response.Code, repo.mediaCalls, files.calls)
	}
}

func TestGetActivityCoverRejectsCurrentSavedReferenceForNonPublicLifecycle(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		mutate func(*model.Activity)
	}{
		{
			name: "private",
			mutate: func(item *model.Activity) {
				item.Visibility = enum.ActivityVisibilityPrivate
			},
		},
		{
			name: "unavailable",
			mutate: func(item *model.Activity) {
				item.Status = enum.ActivityStatusCancelled
				now := item.UpdatedAt
				item.CancelledAt = &now
			},
		},
		{
			name: "deleted",
			mutate: func(item *model.Activity) {
				item.Status = enum.ActivityStatusArchived
			},
		},
		{
			name: "restricted",
			mutate: func(item *model.Activity) {
				item.ModerationStatus = enum.ActivityModerationStatusRejected
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			actorID := uuid.New()
			item := activityVisibilityTestActivity()
			item.HostUserID = actorID
			test.mutate(item)
			repo := &activityVisibilityRepositoryStub{
				activity: item,
				media:    []*model.ActivityMedia{{ActivityID: item.ID, FileID: uuid.New(), IsCover: true}},
			}
			files := &activityCoverFileManagerStub{downloadURL: "http://unused.test"}
			handler := newActivityVisibilityTestHandler(repo, actorID, files)
			response := httptest.NewRecorder()
			handler.GetActivityCover(
				response,
				activityViewerRequest("/v1/activities/"+item.ID.String()+"/cover?saved_revision=101"),
				item.ID,
			)

			if response.Code != nethttp.StatusNotFound || repo.mediaCalls != 0 || files.calls != 0 {
				t.Fatalf(
					"non-public Saved reference status/media/file calls = %d/%d/%d, want 404/0/0",
					response.Code,
					repo.mediaCalls,
					files.calls,
				)
			}
		})
	}
}

func newActivityVisibilityTestHandler(
	repo *activityVisibilityRepositoryStub,
	actorID uuid.UUID,
	files port.ActivityMediaFileManager,
) *Handler {
	return &Handler{
		activityUC:    app.NewActivityUseCase(repo),
		repo:          repo,
		fileManager:   files,
		actorResolver: activityViewerResolverStub{userID: actorID},
	}
}

func activityViewerRequest(target string) *nethttp.Request {
	request := httptest.NewRequest(nethttp.MethodGet, target, nil)
	return request.WithContext(withSubject(request.Context(), "viewer-subject"))
}

func activityVisibilityTestActivity() *model.Activity {
	now := time.Now().UTC()
	publishedAt := now.Add(-time.Hour)
	return &model.Activity{
		ID:                      uuid.New(),
		HostUserID:              uuid.New(),
		Title:                   "City walk",
		Description:             "A public city walking activity",
		SourceLanguage:          "en",
		Translations:            model.ActivityTranslations{"en": {Title: "City walk", Description: "A public city walking activity"}},
		Status:                  enum.ActivityStatusEnrollmentOpen,
		Visibility:              enum.ActivityVisibilityPublic,
		ModerationStatus:        enum.ActivityModerationStatusApproved,
		PublishedAt:             &publishedAt,
		Revision:                17,
		SavedSourceRevision:     100,
		SavedProjectionRevision: 101,
		SavedVisibilityRevision: 102,
		RegistrationDeadline:    now.Add(23 * time.Hour),
		StartAt:                 now.Add(24 * time.Hour),
		EndAt:                   now.Add(26 * time.Hour),
		CreatedAt:               now,
		UpdatedAt:               now,
	}
}
