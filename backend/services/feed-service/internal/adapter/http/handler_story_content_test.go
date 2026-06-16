package http

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"slices"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/feed-service/internal/app"
	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

func TestCreatePostRequiresAuthentication(t *testing.T) {
	h := newPostHTTPTestHarness(t)

	rec := h.doJSON(http.MethodPost, "/v1/posts", "", map[string]any{
		"title": "Draft",
	})

	assertErrorResponse(t, rec, http.StatusUnauthorized, map[string]string{
		"code": "missing_authenticated_subject",
		"kind": "business",
	})
}

func TestCommunityResponseIncludesDefaultPostProfileKey(t *testing.T) {
	community := &model.Community{
		ID:                    uuid.New(),
		Slug:                  "da-nang-chat",
		Title:                 "Da Nang chat",
		Description:           "Fast local posts.",
		Topic:                 "CITY_LIFE",
		LanguageCode:          "ru",
		Visibility:            enum.CommunityVisibilityPublic,
		PostingPolicy:         enum.CommunityPostingPolicyOpenMembers,
		Status:                enum.CommunityStatusActive,
		DefaultPostProfileKey: enum.PostProfileQuickPostV1,
		AllowedPostProfileKeys: []string{
			string(enum.PostProfileQuickPostV1),
			string(enum.PostProfileListingV1),
		},
		EnabledTabs: []string{"discussions", "listings"},
		CreatedAt:   time.Date(2026, 6, 13, 8, 0, 0, 0, time.UTC),
		UpdatedAt:   time.Date(2026, 6, 13, 8, 0, 0, 0, time.UTC),
	}

	response := toCommunityResponse(&app.CommunityView{Community: community})

	if response.DefaultPostProfileKey != string(enum.PostProfileQuickPostV1) {
		t.Fatalf("DefaultPostProfileKey = %q, want %q", response.DefaultPostProfileKey, enum.PostProfileQuickPostV1)
	}
	if got, want := response.AllowedPostProfileKeys, community.AllowedPostProfileKeys; !slices.Equal(got, want) {
		t.Fatalf("AllowedPostProfileKeys = %#v, want %#v", got, want)
	}
	if got, want := response.EnabledTabs, community.EnabledTabs; !slices.Equal(got, want) {
		t.Fatalf("EnabledTabs = %#v, want %#v", got, want)
	}
}

func TestCreateDraftAcceptsStructuredContentAndReturnsContentEngineFields(t *testing.T) {
	h := newPostHTTPTestHarness(t)

	rec := h.doJSON(http.MethodPost, "/v1/posts", postHTTPSubjectOwner, map[string]any{
		"title":                "Mountain notes",
		"format":               "GUIDE",
		"category":             "GUIDE",
		"contentSchemaVersion": 1,
		"contentBlocks": map[string]any{
			"version": 1,
			"blocks": []map[string]any{{
				"id":   "p1",
				"type": "paragraph",
				"text": "Fresh route from Medeu.",
			}},
		},
		"tags": []string{"Almaty"},
	})

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusCreated, rec.Body.String())
	}

	var body map[string]any
	decodeJSONResponse(t, rec, &body)
	if body["format"] != "GUIDE" {
		t.Fatalf("format = %#v, want GUIDE; body: %#v", body["format"], body)
	}
	if body["contentSchemaVersion"] != float64(1) {
		t.Fatalf("contentSchemaVersion = %#v, want 1", body["contentSchemaVersion"])
	}
	if body["revision"] != float64(1) {
		t.Fatalf("revision = %#v, want 1", body["revision"])
	}
	if body["moderationStatus"] != "NOT_REQUIRED" {
		t.Fatalf("moderationStatus = %#v, want NOT_REQUIRED", body["moderationStatus"])
	}
	if _, ok := body["contentBlocks"].(map[string]any); !ok {
		t.Fatalf("contentBlocks missing or not an object: %#v", body["contentBlocks"])
	}
	if _, ok := body["contentPlainText"]; ok {
		t.Fatalf("contentPlainText should not be exposed by default: %#v", body)
	}
}

func TestPostRoutesCreateAndReadEditorContent(t *testing.T) {
	h := newPostHTTPTestHarness(t)

	createRec := h.doJSON(http.MethodPost, "/v1/posts", postHTTPSubjectOwner, map[string]any{
		"title":    "Post from editor",
		"format":   "ARTICLE",
		"category": "JOURNAL",
	})
	if createRec.Code != http.StatusCreated {
		t.Fatalf("create status = %d, want %d; body: %s", createRec.Code, http.StatusCreated, createRec.Body.String())
	}
	var created struct {
		ID     string `json:"id"`
		Format string `json:"format"`
		Title  string `json:"title"`
	}
	decodeJSONResponse(t, createRec, &created)
	if created.Format != "ARTICLE" || created.Title != "Post from editor" {
		t.Fatalf("created post = %+v, want article post response", created)
	}

	getRec := h.doJSON(http.MethodGet, "/v1/posts/"+created.ID, postHTTPSubjectOwner, nil)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get status = %d, want %d; body: %s", getRec.Code, http.StatusOK, getRec.Body.String())
	}
	var fetched struct {
		ID string `json:"id"`
	}
	decodeJSONResponse(t, getRec, &fetched)
	if fetched.ID != created.ID {
		t.Fatalf("fetched id = %q, want %q", fetched.ID, created.ID)
	}
}

func TestLikeStoryRouteReturnsUpdatedLikeCount(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	storyID := uuid.New()
	fileID := uuid.New()
	now := time.Now().UTC().Truncate(time.Second)
	if err := h.repo.CreateStory(context.Background(), &model.Story{
		ID:           storyID,
		AuthorUserID: h.ownerID,
		Caption:      "Morning route",
		MediaFileID:  fileID,
		CoverFileID:  fileID,
		MediaType:    enum.StoryMediaTypeImage,
		ExpiresAt:    now.Add(time.Hour),
		CreatedAt:    now,
		UpdatedAt:    now,
	}); err != nil {
		t.Fatalf("seed story: %v", err)
	}

	rec := h.doJSON(http.MethodPost, "/v1/stories/"+storyID.String()+"/likes", postHTTPSubjectOther, nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		Likes int `json:"likes"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.Likes != 1 {
		t.Fatalf("likes = %d, want 1", body.Likes)
	}

	secondRec := h.doJSON(http.MethodPost, "/v1/stories/"+storyID.String()+"/likes", postHTTPSubjectOther, nil)
	if secondRec.Code != http.StatusOK {
		t.Fatalf("second status = %d, want %d; body: %s", secondRec.Code, http.StatusOK, secondRec.Body.String())
	}
	decodeJSONResponse(t, secondRec, &body)
	if body.Likes != 1 {
		t.Fatalf("second likes = %d, want idempotent count 1", body.Likes)
	}
}

func TestListMyArchivedStoriesReturnsExpiredOwnedStories(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	now := time.Now().UTC().Truncate(time.Second)
	ownerArchivedID := uuid.New()
	activeOwnerID := uuid.New()
	otherArchivedID := uuid.New()
	fileID := uuid.New()

	for _, story := range []*model.Story{
		{
			ID:           ownerArchivedID,
			AuthorUserID: h.ownerID,
			Caption:      "Archived owner story",
			MediaFileID:  fileID,
			CoverFileID:  fileID,
			MediaType:    enum.StoryMediaTypeImage,
			ExpiresAt:    now.Add(-time.Minute),
			CreatedAt:    now.Add(-25 * time.Hour),
			UpdatedAt:    now.Add(-25 * time.Hour),
		},
		{
			ID:           activeOwnerID,
			AuthorUserID: h.ownerID,
			Caption:      "Active owner story",
			MediaFileID:  fileID,
			CoverFileID:  fileID,
			MediaType:    enum.StoryMediaTypeImage,
			ExpiresAt:    now.Add(time.Hour),
			CreatedAt:    now,
			UpdatedAt:    now,
		},
		{
			ID:           otherArchivedID,
			AuthorUserID: h.otherID,
			Caption:      "Archived other story",
			MediaFileID:  fileID,
			CoverFileID:  fileID,
			MediaType:    enum.StoryMediaTypeImage,
			ExpiresAt:    now.Add(-time.Minute),
			CreatedAt:    now.Add(-25 * time.Hour),
			UpdatedAt:    now.Add(-25 * time.Hour),
		},
	} {
		if err := h.repo.CreateStory(context.Background(), story); err != nil {
			t.Fatalf("seed story: %v", err)
		}
	}

	rec := h.doJSON(http.MethodGet, "/v1/stories/mine/archive?limit=20&offset=0", postHTTPSubjectOwner, nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		Items []struct {
			ID string `json:"id"`
		} `json:"items"`
		Limit   int  `json:"limit"`
		Offset  int  `json:"offset"`
		HasMore bool `json:"hasMore"`
	}
	decodeJSONResponse(t, rec, &body)

	if len(body.Items) != 1 || body.Items[0].ID != ownerArchivedID.String() {
		t.Fatalf("archived story ids = %+v, want only %s", body.Items, ownerArchivedID)
	}
	if body.Limit != 20 || body.Offset != 0 || body.HasMore {
		t.Fatalf("pagination = limit %d offset %d hasMore %v, want 20/0/false", body.Limit, body.Offset, body.HasMore)
	}
}

func TestListMyActiveStoriesReturnsUnexpiredOwnedStories(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	now := time.Now().UTC().Truncate(time.Second)
	ownerActiveID := uuid.New()
	expiredOwnerID := uuid.New()
	otherActiveID := uuid.New()
	fileID := uuid.New()

	for _, story := range []*model.Story{
		{
			ID:           ownerActiveID,
			AuthorUserID: h.ownerID,
			Caption:      "Active owner story",
			MediaFileID:  fileID,
			CoverFileID:  fileID,
			MediaType:    enum.StoryMediaTypeImage,
			ExpiresAt:    now.Add(time.Hour),
			CreatedAt:    now,
			UpdatedAt:    now,
		},
		{
			ID:           expiredOwnerID,
			AuthorUserID: h.ownerID,
			Caption:      "Expired owner story",
			MediaFileID:  fileID,
			CoverFileID:  fileID,
			MediaType:    enum.StoryMediaTypeImage,
			ExpiresAt:    now.Add(-time.Minute),
			CreatedAt:    now.Add(-25 * time.Hour),
			UpdatedAt:    now.Add(-25 * time.Hour),
		},
		{
			ID:           otherActiveID,
			AuthorUserID: h.otherID,
			Caption:      "Active other story",
			MediaFileID:  fileID,
			CoverFileID:  fileID,
			MediaType:    enum.StoryMediaTypeImage,
			ExpiresAt:    now.Add(time.Hour),
			CreatedAt:    now,
			UpdatedAt:    now,
		},
	} {
		if err := h.repo.CreateStory(context.Background(), story); err != nil {
			t.Fatalf("seed story: %v", err)
		}
	}

	rec := h.doJSON(http.MethodGet, "/v1/stories/mine/active?limit=20&offset=0", postHTTPSubjectOwner, nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		Items []struct {
			ID string `json:"id"`
		} `json:"items"`
		Limit   int  `json:"limit"`
		Offset  int  `json:"offset"`
		HasMore bool `json:"hasMore"`
	}
	decodeJSONResponse(t, rec, &body)

	if len(body.Items) != 1 || body.Items[0].ID != ownerActiveID.String() {
		t.Fatalf("active story ids = %+v, want only %s", body.Items, ownerActiveID)
	}
	if body.Limit != 20 || body.Offset != 0 || body.HasMore {
		t.Fatalf("pagination = limit %d offset %d hasMore %v, want 20/0/false", body.Limit, body.Offset, body.HasMore)
	}
}

func TestCreateDraftLogsSafeStructuredCounterWithoutContent(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	logs := capturePostHTTPLogs(t)

	rec := h.doJSON(http.MethodPost, "/v1/posts", postHTTPSubjectOwner, map[string]any{
		"title": "Safe draft",
		"contentBlocks": map[string]any{
			"version": 1,
			"blocks": []map[string]any{{
				"id":   "p1",
				"type": "paragraph",
				"text": "secret draft body should never be logged",
			}},
		},
	})

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusCreated, rec.Body.String())
	}

	output := logs.String()
	if !containsAny(output, `"metric":"posts_draft_created_total"`) {
		t.Fatalf("logs = %s, want draft created counter", output)
	}
	if !containsAny(output, `"request_id":"req-test"`) {
		t.Fatalf("logs = %s, want request id", output)
	}
	if containsAny(output, "secret draft body", "contentBlocks", "content_plain_text", "plainText") {
		t.Fatalf("draft log leaked content payload: %s", output)
	}
}

func TestListPostsFiltersByCommunityID(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	targetCommunityID := uuid.New()
	otherCommunityID := uuid.New()
	targetPostID := uuid.New()
	otherCommunityPostID := uuid.New()
	standalonePostID := uuid.New()

	h.seedCommunity(postHTTPCommunity(targetCommunityID))
	h.seedCommunity(postHTTPCommunity(otherCommunityID))
	h.seedPost(&model.Post{
		ID:               targetPostID,
		AuthorUserID:     h.ownerID,
		Title:            "Target community post",
		CommunityID:      &targetCommunityID,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		Revision:         1,
	})
	h.seedPost(&model.Post{
		ID:               otherCommunityPostID,
		AuthorUserID:     h.ownerID,
		Title:            "Other community post",
		CommunityID:      &otherCommunityID,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		Revision:         1,
	})
	h.seedPost(&model.Post{
		ID:               standalonePostID,
		AuthorUserID:     h.ownerID,
		Title:            "Standalone post",
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusNotRequired,
		Revision:         1,
	})

	rec := h.doJSON(http.MethodGet, "/v1/posts?communityId="+targetCommunityID.String()+"&limit=20&offset=0", "", nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		Items []struct {
			ID          string `json:"id"`
			CommunityID string `json:"communityId"`
		} `json:"items"`
		Total   int  `json:"total"`
		HasMore bool `json:"hasMore"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 {
		t.Fatalf("items length = %d, want 1; body: %+v", len(body.Items), body)
	}
	if body.Items[0].ID != targetPostID.String() || body.Items[0].CommunityID != targetCommunityID.String() {
		t.Fatalf("post = %+v, want target post %s in community %s", body.Items[0], targetPostID, targetCommunityID)
	}
	if body.Total != 1 || body.HasMore {
		t.Fatalf("pagination = total %d hasMore %v, want total=1 hasMore=false", body.Total, body.HasMore)
	}
}

func TestMarkPostSeenPersistsViewerScopedState(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := uuid.New()
	expiresAt := time.Now().UTC().Add(24 * time.Hour).Truncate(time.Second)
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.ownerID,
		Title:            "Seen contract",
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusNotRequired,
		Revision:         1,
		ExpiresAt:        &expiresAt,
	})

	rec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/seen", postHTTPSubjectOther, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	assertCurrentPostInteractionHeaders(t, rec)
	var firstSeen struct {
		SeenAt string `json:"seenAt"`
	}
	decodeJSONResponse(t, rec, &firstSeen)
	if _, err := time.Parse(time.RFC3339, firstSeen.SeenAt); err != nil {
		t.Fatalf("seenAt = %q, want RFC3339 timestamp: %v", firstSeen.SeenAt, err)
	}

	secondRec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/seen", postHTTPSubjectOther, nil)
	if secondRec.Code != http.StatusOK {
		t.Fatalf("second status = %d, want %d; body: %s", secondRec.Code, http.StatusOK, secondRec.Body.String())
	}
	assertCurrentPostInteractionHeaders(t, secondRec)
	var secondSeen struct {
		SeenAt string `json:"seenAt"`
	}
	decodeJSONResponse(t, secondRec, &secondSeen)
	if secondSeen.SeenAt != firstSeen.SeenAt {
		t.Fatalf("second seenAt = %q, want first seenAt %q", secondSeen.SeenAt, firstSeen.SeenAt)
	}

	detailRec := h.doJSON(http.MethodGet, "/v1/posts/"+postID.String(), postHTTPSubjectOther, nil)
	if detailRec.Code != http.StatusOK {
		t.Fatalf("detail status = %d, want %d; body: %s", detailRec.Code, http.StatusOK, detailRec.Body.String())
	}
	var detail struct {
		SeenByViewer bool    `json:"seenByViewer"`
		SeenAt       *string `json:"seenAt"`
		ExpiresAt    *string `json:"expiresAt"`
	}
	decodeJSONResponse(t, detailRec, &detail)
	if !detail.SeenByViewer {
		t.Fatal("seenByViewer = false, want true")
	}
	if detail.SeenAt == nil || *detail.SeenAt != firstSeen.SeenAt {
		t.Fatalf("seenAt = %v, want %q", detail.SeenAt, firstSeen.SeenAt)
	}
	if detail.ExpiresAt == nil || *detail.ExpiresAt != expiresAt.Format(time.RFC3339) {
		t.Fatalf("expiresAt = %v, want %q", detail.ExpiresAt, expiresAt.Format(time.RFC3339))
	}
}

func TestListAdminFeedQualityMetricsReturnsReadOnlyAggregates(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New().String()
	h.repo.feedQualityMetrics = []model.FeedQualityMetric{
		{
			Surface:            "home",
			Tab:                "for_you",
			BlockType:          model.FeedBlockTypePostCard,
			RankingExperiment:  "rank-v2",
			CandidateSource:    model.PostCandidateSourceSocial,
			PostProfile:        string(enum.PostProfileQuickPostV1),
			CommunityID:        communityID,
			Action:             "conversion",
			EventCount:         12,
			UniqueViewers:      7,
			ImpressionCount:    20,
			ClickCount:         8,
			DwellCount:         5,
			AvgDwellMs:         4200,
			LikeCount:          3,
			CommentCount:       2,
			ShareCount:         1,
			SubscribeCount:     4,
			ConversionCount:    4,
			HideCount:          1,
			NotInterestedCount: 2,
			ReportCount:        3,
		},
	}

	rec := h.doInternalJSON(
		http.MethodGet,
		"/internal/v1/feed/quality-metrics?since=2026-05-01T00:00:00Z&until=2026-05-08T00:00:00Z&surface=home&limit=500",
		uuid.New(),
		nil,
	)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		Items []struct {
			Surface            string `json:"surface"`
			Tab                string `json:"tab"`
			BlockType          string `json:"blockType"`
			RankingExperiment  string `json:"rankingExperiment"`
			CandidateSource    string `json:"candidateSource"`
			PostProfile        string `json:"postProfile"`
			CommunityID        string `json:"communityId"`
			Action             string `json:"action"`
			EventCount         int64  `json:"eventCount"`
			UniqueViewers      int64  `json:"uniqueViewers"`
			ImpressionCount    int64  `json:"impressionCount"`
			ClickCount         int64  `json:"clickCount"`
			DwellCount         int64  `json:"dwellCount"`
			AvgDwellMs         int64  `json:"avgDwellMs"`
			LikeCount          int64  `json:"likeCount"`
			CommentCount       int64  `json:"commentCount"`
			ShareCount         int64  `json:"shareCount"`
			SubscribeCount     int64  `json:"subscribeCount"`
			ConversionCount    int64  `json:"conversionCount"`
			HideCount          int64  `json:"hideCount"`
			NotInterestedCount int64  `json:"notInterestedCount"`
			ReportCount        int64  `json:"reportCount"`
		} `json:"items"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 {
		t.Fatalf("items length = %d, want 1; body: %+v", len(body.Items), body)
	}
	item := body.Items[0]
	if item.Surface != "home" ||
		item.Tab != "for_you" ||
		item.BlockType != model.FeedBlockTypePostCard ||
		item.RankingExperiment != "rank-v2" ||
		item.CandidateSource != model.PostCandidateSourceSocial ||
		item.PostProfile != string(enum.PostProfileQuickPostV1) ||
		item.CommunityID != communityID ||
		item.Action != "conversion" ||
		item.EventCount != 12 ||
		item.UniqueViewers != 7 ||
		item.ImpressionCount != 20 ||
		item.ClickCount != 8 ||
		item.DwellCount != 5 ||
		item.AvgDwellMs != 4200 ||
		item.LikeCount != 3 ||
		item.CommentCount != 2 ||
		item.ShareCount != 1 ||
		item.SubscribeCount != 4 ||
		item.ConversionCount != 4 ||
		item.HideCount != 1 ||
		item.NotInterestedCount != 2 ||
		item.ReportCount != 3 {
		t.Fatalf("metric item = %+v, want seeded aggregate", item)
	}
}

func TestApplyInternalFeedSocialEventStoresReadModelEdge(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	viewerID := uuid.New()
	targetID := uuid.New()
	eventID := uuid.New()

	rec := h.doInternalJSON(http.MethodPost, "/internal/v1/feed/social-events", uuid.New(), map[string]any{
		"eventId":         eventID.String(),
		"viewerUserId":    viewerID.String(),
		"targetUserId":    targetID.String(),
		"edgeType":        model.FeedSocialEdgeTypeFollowing,
		"active":          true,
		"sourceUpdatedAt": "2026-06-15T10:30:00Z",
	})
	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusAccepted, rec.Body.String())
	}

	edges, err := h.repo.ListFeedSocialEdges(context.Background(), viewerID, []uuid.UUID{targetID})
	if err != nil {
		t.Fatalf("ListFeedSocialEdges returned error: %v", err)
	}
	if !edges[targetID].Following {
		t.Fatalf("following edge missing: %#v", edges)
	}
}

func TestTrackPostViewLegacyEndpointRemoved(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := uuid.New()
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.ownerID,
		Title:            "View contract",
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusNotRequired,
		Revision:         1,
	})

	rec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/views", postHTTPSubjectOther, nil)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusNotFound, rec.Body.String())
	}
	assertErrorResponse(t, rec, http.StatusNotFound, map[string]string{
		"code": "not_found",
		"kind": "business",
	})
}

func assertDeprecatedPostInteractionHeaders(t *testing.T, rec *httptest.ResponseRecorder) {
	t.Helper()

	if got := rec.Header().Get("Deprecation"); got != "true" {
		t.Fatalf("Deprecation header = %q, want true", got)
	}
	link := rec.Header().Get("Link")
	if !strings.Contains(link, `rel="deprecation"`) ||
		!strings.Contains(link, "/docs/architecture/content-feed-platform-roadmap.md#phase-12-migration-and-deprecation") {
		t.Fatalf("Link header = %q, want roadmap deprecation link", link)
	}
}

func assertCurrentPostInteractionHeaders(t *testing.T, rec *httptest.ResponseRecorder) {
	t.Helper()

	if got := rec.Header().Get("Deprecation"); got != "" {
		t.Fatalf("Deprecation header = %q, want empty for current endpoint", got)
	}
	if got := rec.Header().Get("Link"); strings.Contains(got, `rel="deprecation"`) {
		t.Fatalf("Link header = %q, want no deprecation link for current endpoint", got)
	}
}

func TestExpiredPostIsHiddenFromPublicReadsAndFeed(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	expiredAt := time.Now().UTC().Add(-time.Minute).Truncate(time.Second)
	postID := uuid.New()
	h.seedPost(&model.Post{
		ID:               postID,
		Slug:             "expired-post",
		AuthorUserID:     h.ownerID,
		Title:            "Expired post",
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusNotRequired,
		Revision:         1,
		ExpiresAt:        &expiredAt,
	})

	listRec := h.doJSON(http.MethodGet, "/v1/posts?limit=20&offset=0", postHTTPSubjectOther, nil)
	if listRec.Code != http.StatusOK {
		t.Fatalf("list status = %d, want %d; body: %s", listRec.Code, http.StatusOK, listRec.Body.String())
	}
	var listBody struct {
		Items []struct {
			ID string `json:"id"`
		} `json:"items"`
		Total int `json:"total"`
	}
	decodeJSONResponse(t, listRec, &listBody)
	if len(listBody.Items) != 0 || listBody.Total != 0 {
		t.Fatalf("list body = %+v, want no expired posts", listBody)
	}

	detailRec := h.doJSON(http.MethodGet, "/v1/public/posts/expired-post", postHTTPSubjectOther, nil)
	assertErrorResponse(t, detailRec, http.StatusNotFound, map[string]string{
		"code": "post_not_found",
		"kind": "business",
	})

	feedRec := h.doJSON(http.MethodGet, "/v1/feed?limit=10", postHTTPSubjectOther, nil)
	if feedRec.Code != http.StatusOK {
		t.Fatalf("feed status = %d, want %d; body: %s", feedRec.Code, http.StatusOK, feedRec.Body.String())
	}
	if strings.Contains(feedRec.Body.String(), postID.String()) {
		t.Fatalf("feed body contains expired post %s: %s", postID, feedRec.Body.String())
	}
}

func TestGetFeedRejectsMalformedCursor(t *testing.T) {
	h := newPostHTTPTestHarness(t)

	rec := h.doJSON(http.MethodGet, "/v1/feed?cursor=not-a-valid-feed-cursor", "", nil)

	assertErrorResponse(t, rec, http.StatusBadRequest, map[string]string{
		"code": "invalid_feed_cursor",
		"kind": "business",
	})
}

func TestFeedResponseIncludesRankingExperimentAssignment(t *testing.T) {
	resp := toFeedResponse(&app.FeedPage{
		Assignment: app.FeedExperimentAssignment{
			RankingExperiment: "rank-v2",
		},
	})

	if resp.Assignment == nil {
		t.Fatal("assignment is nil, want ranking experiment assignment")
	}
	if resp.Assignment.RankingExperiment != "rank-v2" {
		t.Fatalf("ranking experiment = %q, want rank-v2", resp.Assignment.RankingExperiment)
	}
}

func TestFeedResponseSerializesConversionBlockMetadata(t *testing.T) {
	resp := toFeedResponse(&app.FeedPage{
		Items: []app.FeedBlock{{
			ID:   "guide:featured",
			Type: model.FeedBlockTypeGuideCard,
			Data: app.ConversionFeedData{
				Title:        "Featured local guide",
				Subtitle:     "Plan the trip with a verified local expert.",
				ActionLabel:  "Open guide",
				EntityType:   "guide",
				EntityID:     "featured",
				Route:        "/guides/featured",
				Source:       "content_for_you_guide_conversion",
				SemanticTags: []string{"guide", "local_expert"},
			},
		}},
	})
	if len(resp.Items) != 1 {
		t.Fatalf("items = %d, want one conversion block", len(resp.Items))
	}
	data, ok := resp.Items[0].Data.(map[string]any)
	if !ok {
		t.Fatalf("data = %#v, want json map", resp.Items[0].Data)
	}
	for key, want := range map[string]any{
		"title":       "Featured local guide",
		"actionLabel": "Open guide",
		"entityType":  "guide",
		"entityId":    "featured",
		"route":       "/guides/featured",
		"source":      "content_for_you_guide_conversion",
	} {
		if got := data[key]; got != want {
			t.Fatalf("data[%s] = %v, want %v", key, got, want)
		}
	}
	tags, ok := data["semanticTags"].([]string)
	if !ok || len(tags) != 2 || tags[0] != "guide" || tags[1] != "local_expert" {
		t.Fatalf("semanticTags = %#v, want stable tags", data["semanticTags"])
	}
}

func TestTrackFeedEventsAcceptsViewerScopedBatch(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := uuid.New()
	eventID := uuid.New()

	rec := h.doJSON(http.MethodPost, "/v1/feed/events", postHTTPSubjectOther, map[string]any{
		"events": []map[string]any{{
			"eventId":    eventID.String(),
			"type":       "impression",
			"surface":    "content",
			"tab":        "for_you",
			"blockId":    "post:" + postID.String(),
			"blockType":  "post_card",
			"postId":     postID.String(),
			"rank":       4,
			"occurredAt": "2026-06-12T09:30:00Z",
			"metadata": map[string]any{
				"sessionId": "session-1",
			},
		}},
	})

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusAccepted, rec.Body.String())
	}
	var body struct {
		Accepted int `json:"accepted"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.Accepted != 1 {
		t.Fatalf("accepted = %d, want 1", body.Accepted)
	}
	if len(h.repo.feedEvents) != 1 {
		t.Fatalf("feed events = %d, want 1", len(h.repo.feedEvents))
	}
	event := h.repo.feedEvents[0]
	if event.EventID != eventID ||
		event.ViewerUserID == nil ||
		*event.ViewerUserID != h.otherID ||
		event.EventType != model.FeedEventTypeImpression ||
		event.BlockID != "post:"+postID.String() ||
		event.PostID == nil ||
		*event.PostID != postID ||
		event.Rank != 4 {
		t.Fatalf("feed event mismatch: %+v", event)
	}
}

func TestTrackFeedEventsAcceptsHomeEntityConversionClick(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	eventID := uuid.New()

	rec := h.doJSON(http.MethodPost, "/v1/feed/events", postHTTPSubjectOther, map[string]any{
		"events": []map[string]any{{
			"eventId":    eventID.String(),
			"type":       "click",
			"surface":    "home",
			"tab":        "for_you",
			"blockId":    "home:recommended_activities",
			"blockType":  "activity_card",
			"rank":       2,
			"occurredAt": "2026-06-12T11:00:00Z",
			"metadata": map[string]any{
				"action":     "conversion",
				"entityType": "activity",
				"entityId":   "activity-1",
				"source":     "home_recommended_activities",
			},
		}},
	})

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusAccepted, rec.Body.String())
	}
	var body struct {
		Accepted int `json:"accepted"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.Accepted != 1 {
		t.Fatalf("accepted = %d, want 1", body.Accepted)
	}
	if len(h.repo.feedEvents) != 1 {
		t.Fatalf("feed events = %d, want 1", len(h.repo.feedEvents))
	}
	event := h.repo.feedEvents[0]
	if event.EventID != eventID ||
		event.ViewerUserID == nil ||
		*event.ViewerUserID != h.otherID ||
		event.EventType != model.FeedEventTypeClick ||
		event.BlockID != "home:recommended_activities" ||
		event.BlockType != model.FeedBlockTypeActivityCard ||
		event.PostID != nil ||
		event.Rank != 2 {
		t.Fatalf("feed event mismatch: %+v", event)
	}
	if got := event.Metadata["entityId"]; got != "activity-1" {
		t.Fatalf("metadata entityId = %v, want activity-1", got)
	}
}

func TestTrackFeedEventsRejectsLegacyMobileEventTypeField(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := uuid.New()
	eventID := uuid.New()

	rec := h.doJSON(http.MethodPost, "/v1/feed/events", postHTTPSubjectOther, map[string]any{
		"events": []map[string]any{{
			"eventId":   eventID.String(),
			"eventType": "not_interested",
			"surface":   "content",
			"tab":       "for_you",
			"blockId":   "post:" + postID.String(),
			"blockType": "post_card",
			"postId":    postID.String(),
			"rank":      7,
		}},
	})

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusBadRequest, rec.Body.String())
	}
	if len(h.repo.feedEvents) != 0 {
		t.Fatalf("feed events = %d, want 0", len(h.repo.feedEvents))
	}
}

func TestCreatePostRejectsClientArchivedStatus(t *testing.T) {
	h := newPostHTTPTestHarness(t)

	rec := h.doJSON(http.MethodPost, "/v1/posts", postHTTPSubjectOwner, map[string]any{
		"title":  "Archived by client",
		"status": "ARCHIVED",
	})

	assertErrorResponse(t, rec, http.StatusBadRequest, map[string]string{
		"code": "invalid_post_status",
		"kind": "business",
	})
}

func TestPublishPostReturnsFieldErrorsForValidation(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := uuid.New()
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.ownerID,
		Status:           enum.PostStatusDraft,
		ModerationStatus: enum.ModerationStatusNotRequired,
		Revision:         1,
	})

	rec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/publish", postHTTPSubjectOwner, map[string]any{
		"revision": 1,
	})

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusBadRequest, rec.Body.String())
	}

	var body struct {
		Code   string            `json:"code"`
		Kind   string            `json:"kind"`
		Fields map[string]string `json:"fields"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.Code != "post_validation_failed" || body.Kind != "business" {
		t.Fatalf("error code/kind = %s/%s, want post_validation_failed/business", body.Code, body.Kind)
	}
	wantFields := map[string]string{
		"title":         "required_for_publish",
		"category":      "required_for_publish",
		"placeName":     "required_for_publish",
		"coverFileId":   "required_for_publish",
		"contentBlocks": "required_for_publish",
	}
	if len(body.Fields) != len(wantFields) {
		t.Fatalf("fields = %#v, want %#v", body.Fields, wantFields)
	}
	for field, wantCode := range wantFields {
		if body.Fields[field] != wantCode {
			t.Fatalf("fields[%s] = %q, want %q; all fields: %#v", field, body.Fields[field], wantCode, body.Fields)
		}
	}
}

func TestPublishValidationLogsSafeFieldAndMediaCounters(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	logs := capturePostHTTPLogs(t)
	postID := uuid.New()
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.ownerID,
		Status:           enum.PostStatusDraft,
		ModerationStatus: enum.ModerationStatusNotRequired,
		Revision:         1,
	})

	rec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/publish", postHTTPSubjectOwner, map[string]any{
		"revision": 1,
	})

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusBadRequest, rec.Body.String())
	}

	output := logs.String()
	for _, want := range []string{
		`"metric":"posts_publish_validation_failure_total"`,
		`"metric":"posts_media_validation_failure_total"`,
		`"field":"title"`,
		`"field":"coverFileId"`,
		`"field":"content"`,
		`"request_id":"req-test"`,
		`"post_id":"` + postID.String() + `"`,
	} {
		if !strings.Contains(output, want) {
			t.Fatalf("logs = %s, want %s", output, want)
		}
	}
	if containsAny(output, "contentBlocks", "blocks", "text", "content_plain_text", "plainText") {
		t.Fatalf("publish validation log leaked content payload: %s", output)
	}
}

func TestListPostsReturnsPaginationMetadataAndTotal(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	h.seedPost(&model.Post{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "One", Status: enum.PostStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})
	h.seedPost(&model.Post{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Two", Status: enum.PostStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})

	rec := h.doJSON(http.MethodGet, "/v1/posts?limit=1&offset=0", "", nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		Items   []map[string]any `json:"items"`
		Total   int              `json:"total"`
		Limit   int              `json:"limit"`
		Offset  int              `json:"offset"`
		HasMore bool             `json:"hasMore"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 || body.Total != 2 || body.Limit != 1 || body.Offset != 0 || !body.HasMore {
		t.Fatalf("pagination response = %+v, want 1 item total=2 limit=1 offset=0 hasMore=true", body)
	}
}

func TestListPostsFiltersByMaterialFormat(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	h.seedPost(&model.Post{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Guide", Format: enum.PostFormatGuide, Status: enum.PostStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})
	h.seedPost(&model.Post{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Article", Format: enum.PostFormatArticle, Status: enum.PostStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})

	rec := h.doJSON(http.MethodGet, "/v1/posts?format=GUIDE", "", nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		Items []map[string]any `json:"items"`
		Total int              `json:"total"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 || body.Total != 1 {
		t.Fatalf("filtered response = %+v, want one GUIDE post", body)
	}
	if body.Items[0]["format"] != "GUIDE" {
		t.Fatalf("format = %#v, want GUIDE", body.Items[0]["format"])
	}
}

func TestListCommunitiesIncludesViewerModerationCapabilities(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleModerator))

	rec := h.doJSON(http.MethodGet, "/v1/communities?limit=10&offset=0", postHTTPSubjectOwner, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		Items []struct {
			ID                string `json:"id"`
			ViewerRole        string `json:"viewerRole"`
			ViewerCanModerate bool   `json:"viewerCanModerate"`
		} `json:"items"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 {
		t.Fatalf("items = %d, want 1; body: %s", len(body.Items), rec.Body.String())
	}
	if body.Items[0].ID != communityID.String() {
		t.Fatalf("community id = %q, want %s", body.Items[0].ID, communityID)
	}
	if body.Items[0].ViewerRole != string(enum.CommunityMembershipRoleModerator) {
		t.Fatalf("viewerRole = %q, want MODERATOR; body: %s", body.Items[0].ViewerRole, rec.Body.String())
	}
	if !body.Items[0].ViewerCanModerate {
		t.Fatalf("viewerCanModerate = false, want true; body: %s", rec.Body.String())
	}
}

func TestListCommunitiesIncludesCommunityRules(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	community := postHTTPCommunity(communityID)
	community.Rules = []string{
		"Share travel advice from personal experience.",
		"Keep commercial offers transparent.",
	}
	h.seedCommunity(community)

	rec := h.doJSON(http.MethodGet, "/v1/communities?limit=10&offset=0", postHTTPSubjectOwner, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		Items []struct {
			ID    string   `json:"id"`
			Rules []string `json:"rules"`
		} `json:"items"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 {
		t.Fatalf("items = %d, want 1; body: %s", len(body.Items), rec.Body.String())
	}
	if body.Items[0].ID != communityID.String() {
		t.Fatalf("community id = %q, want %s", body.Items[0].ID, communityID)
	}
	if !slices.Equal(community.Rules, body.Items[0].Rules) {
		t.Fatalf("rules = %#v, want %#v; body: %s", body.Items[0].Rules, community.Rules, rec.Body.String())
	}
}

func TestCommunityAdminUpdatesMemberRole(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleAdmin))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.otherID, enum.CommunityMembershipRoleMember))

	rec := h.doJSON(
		http.MethodPatch,
		"/v1/communities/"+communityID.String()+"/members/"+h.otherID.String()+"/role",
		postHTTPSubjectOwner,
		map[string]any{"role": "MODERATOR"},
	)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		CommunityID string `json:"communityId"`
		UserID      string `json:"userId"`
		Role        string `json:"role"`
		Status      string `json:"status"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.CommunityID != communityID.String() || body.UserID != h.otherID.String() {
		t.Fatalf("membership ids = %+v, want community/user", body)
	}
	if body.Role != string(enum.CommunityMembershipRoleModerator) || body.Status != string(enum.CommunityMembershipStatusActive) {
		t.Fatalf("membership response = %+v, want MODERATOR ACTIVE", body)
	}

	membership, err := h.repo.GetCommunityMembership(context.Background(), communityID, h.otherID)
	if err != nil {
		t.Fatalf("get updated membership: %v", err)
	}
	if membership == nil || membership.Role != enum.CommunityMembershipRoleModerator {
		t.Fatalf("stored membership = %+v, want moderator", membership)
	}
}

func TestCommunityAdminRoleChangeWritesAuditTrail(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleAdmin))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.otherID, enum.CommunityMembershipRoleMember))

	rec := h.doJSON(
		http.MethodPatch,
		"/v1/communities/"+communityID.String()+"/members/"+h.otherID.String()+"/role",
		postHTTPSubjectOwner,
		map[string]any{"role": "MODERATOR"},
	)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	changes := h.repo.listRoleChangesForTarget(communityID, h.otherID)
	if len(changes) != 1 {
		t.Fatalf("audit changes = %d, want 1", len(changes))
	}
	change := changes[0]
	if change.CommunityID != communityID ||
		change.TargetUserID != h.otherID ||
		change.ActorUserID != h.ownerID ||
		change.PreviousRole != enum.CommunityMembershipRoleMember ||
		change.NextRole != enum.CommunityMembershipRoleModerator {
		t.Fatalf("audit change = %+v, want actor/target previous MEMBER next MODERATOR", change)
	}
}

func TestCommunityAdminUpdatesMemberStatusAndWritesAuditTrail(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	community := postHTTPCommunity(communityID)
	community.FollowerCount = 1
	h.seedCommunity(community)
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleAdmin))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.otherID, enum.CommunityMembershipRoleMember))

	rec := h.doJSON(
		http.MethodPatch,
		"/v1/communities/"+communityID.String()+"/members/"+h.otherID.String()+"/status",
		postHTTPSubjectOwner,
		map[string]any{"status": "BANNED"},
	)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		CommunityID string `json:"communityId"`
		UserID      string `json:"userId"`
		Role        string `json:"role"`
		Status      string `json:"status"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.CommunityID != communityID.String() ||
		body.UserID != h.otherID.String() ||
		body.Role != string(enum.CommunityMembershipRoleMember) ||
		body.Status != string(enum.CommunityMembershipStatusBanned) {
		t.Fatalf("membership response = %+v, want banned member", body)
	}

	membership, err := h.repo.GetCommunityMembership(context.Background(), communityID, h.otherID)
	if err != nil {
		t.Fatalf("get updated membership: %v", err)
	}
	if membership == nil || membership.Status != enum.CommunityMembershipStatusBanned {
		t.Fatalf("stored membership = %+v, want banned", membership)
	}
	updatedCommunity, err := h.repo.GetCommunityByID(context.Background(), communityID)
	if err != nil {
		t.Fatalf("get community: %v", err)
	}
	if updatedCommunity == nil || updatedCommunity.FollowerCount != 0 {
		t.Fatalf("follower count = %+v, want 0 after active member ban", updatedCommunity)
	}
	changes := h.repo.listStatusChangesForTarget(communityID, h.otherID)
	if len(changes) != 1 {
		t.Fatalf("status audit changes = %d, want 1", len(changes))
	}
	change := changes[0]
	if change.CommunityID != communityID ||
		change.TargetUserID != h.otherID ||
		change.ActorUserID != h.ownerID ||
		change.PreviousStatus != enum.CommunityMembershipStatusActive ||
		change.NextStatus != enum.CommunityMembershipStatusBanned {
		t.Fatalf("status audit change = %+v, want ACTIVE -> BANNED by owner", change)
	}
}

func TestCommunityModeratorCannotUpdateMemberStatus(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleModerator))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.otherID, enum.CommunityMembershipRoleMember))

	rec := h.doJSON(
		http.MethodPatch,
		"/v1/communities/"+communityID.String()+"/members/"+h.otherID.String()+"/status",
		postHTTPSubjectOwner,
		map[string]any{"status": "BANNED"},
	)

	assertErrorResponse(t, rec, http.StatusForbidden, map[string]string{
		"code": "community_member_management_denied",
		"kind": "business",
	})
}

func TestCommunityAdminListsMemberRoleChanges(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleAdmin))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.otherID, enum.CommunityMembershipRoleMember))

	updateRec := h.doJSON(
		http.MethodPatch,
		"/v1/communities/"+communityID.String()+"/members/"+h.otherID.String()+"/role",
		postHTTPSubjectOwner,
		map[string]any{"role": "MODERATOR"},
	)
	if updateRec.Code != http.StatusOK {
		t.Fatalf("update status = %d, want %d; body: %s", updateRec.Code, http.StatusOK, updateRec.Body.String())
	}

	rec := h.doJSON(
		http.MethodGet,
		"/v1/communities/"+communityID.String()+"/members/"+h.otherID.String()+"/role-changes?limit=10&offset=0",
		postHTTPSubjectOwner,
		nil,
	)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		Items []struct {
			CommunityID  string `json:"communityId"`
			TargetUserID string `json:"targetUserId"`
			ActorUserID  string `json:"actorUserId"`
			Actor        struct {
				UserID string `json:"userId"`
			} `json:"actor"`
			PreviousRole string `json:"previousRole"`
			NextRole     string `json:"nextRole"`
			CreatedAt    string `json:"createdAt"`
		} `json:"items"`
		Limit   int  `json:"limit"`
		Offset  int  `json:"offset"`
		HasMore bool `json:"hasMore"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.Limit != 10 || body.Offset != 0 || body.HasMore {
		t.Fatalf("pagination = limit:%d offset:%d hasMore:%v, want 10/0/false", body.Limit, body.Offset, body.HasMore)
	}
	if len(body.Items) != 1 {
		t.Fatalf("items = %d, want 1; body: %s", len(body.Items), rec.Body.String())
	}
	item := body.Items[0]
	if item.CommunityID != communityID.String() ||
		item.TargetUserID != h.otherID.String() ||
		item.ActorUserID != h.ownerID.String() ||
		item.Actor.UserID != h.ownerID.String() ||
		item.PreviousRole != string(enum.CommunityMembershipRoleMember) ||
		item.NextRole != string(enum.CommunityMembershipRoleModerator) ||
		item.CreatedAt == "" {
		t.Fatalf("role change item = %+v, want actor/target previous MEMBER next MODERATOR", item)
	}
}

func TestCommunityModeratorCannotListMemberRoleChanges(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleModerator))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.otherID, enum.CommunityMembershipRoleMember))

	rec := h.doJSON(
		http.MethodGet,
		"/v1/communities/"+communityID.String()+"/members/"+h.otherID.String()+"/role-changes?limit=10&offset=0",
		postHTTPSubjectOwner,
		nil,
	)

	assertErrorResponse(t, rec, http.StatusForbidden, map[string]string{
		"code": "community_member_management_denied",
		"kind": "business",
	})
}

func TestCommunityAdminUpdatesHiddenCommunityMemberRole(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	community := postHTTPCommunity(communityID)
	community.Visibility = enum.CommunityVisibilityHidden
	h.seedCommunity(community)
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleAdmin))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.otherID, enum.CommunityMembershipRoleMember))

	rec := h.doJSON(
		http.MethodPatch,
		"/v1/communities/"+communityID.String()+"/members/"+h.otherID.String()+"/role",
		postHTTPSubjectOwner,
		map[string]any{"role": "TRUSTED_MEMBER"},
	)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		Role string `json:"role"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.Role != string(enum.CommunityMembershipRoleTrustedMember) {
		t.Fatalf("role = %q, want TRUSTED_MEMBER", body.Role)
	}
}

func TestCommunityAdminListsActiveMembers(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	leftUserID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleAdmin))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.otherID, enum.CommunityMembershipRoleTrustedMember))
	leftMembership := postHTTPMembership(communityID, leftUserID, enum.CommunityMembershipRoleMember)
	leftMembership.Status = enum.CommunityMembershipStatusLeft
	h.seedCommunityMembership(leftMembership)

	rec := h.doJSON(http.MethodGet, "/v1/communities/"+communityID.String()+"/members?limit=10&offset=0", postHTTPSubjectOwner, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		Items []struct {
			CommunityID string `json:"communityId"`
			UserID      string `json:"userId"`
			Role        string `json:"role"`
			Status      string `json:"status"`
			User        struct {
				UserID string `json:"userId"`
			} `json:"user"`
		} `json:"items"`
		Limit   int  `json:"limit"`
		Offset  int  `json:"offset"`
		HasMore bool `json:"hasMore"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 2 {
		t.Fatalf("items = %d, want 2 active members; body: %s", len(body.Items), rec.Body.String())
	}
	byUserID := make(map[string]struct {
		Role   string
		Status string
		UserID string
	}, len(body.Items))
	for _, item := range body.Items {
		byUserID[item.UserID] = struct {
			Role   string
			Status string
			UserID string
		}{Role: item.Role, Status: item.Status, UserID: item.User.UserID}
		if item.CommunityID != communityID.String() {
			t.Fatalf("communityId = %q, want %s", item.CommunityID, communityID)
		}
	}
	if got := byUserID[h.ownerID.String()]; got.Role != string(enum.CommunityMembershipRoleAdmin) ||
		got.Status != string(enum.CommunityMembershipStatusActive) ||
		got.UserID != h.ownerID.String() {
		t.Fatalf("owner member = %+v, want active admin with user profile", got)
	}
	if got := byUserID[h.otherID.String()]; got.Role != string(enum.CommunityMembershipRoleTrustedMember) ||
		got.Status != string(enum.CommunityMembershipStatusActive) ||
		got.UserID != h.otherID.String() {
		t.Fatalf("other member = %+v, want active trusted member with user profile", got)
	}
	if _, ok := byUserID[leftUserID.String()]; ok {
		t.Fatalf("left member %s leaked into default active member list", leftUserID)
	}
	if body.Limit != 10 || body.Offset != 0 || body.HasMore {
		t.Fatalf("pagination response = %+v, want limit=10 offset=0 hasMore=false", body)
	}
}

func TestCommunityModeratorCannotListMembers(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleModerator))

	rec := h.doJSON(http.MethodGet, "/v1/communities/"+communityID.String()+"/members", postHTTPSubjectOwner, nil)

	assertErrorResponse(t, rec, http.StatusForbidden, map[string]string{
		"code": "community_member_management_denied",
		"kind": "business",
	})
}

func TestCommunityModeratorCannotUpdateMemberRole(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleModerator))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.otherID, enum.CommunityMembershipRoleMember))

	rec := h.doJSON(
		http.MethodPatch,
		"/v1/communities/"+communityID.String()+"/members/"+h.otherID.String()+"/role",
		postHTTPSubjectOwner,
		map[string]any{"role": "TRUSTED_MEMBER"},
	)

	assertErrorResponse(t, rec, http.StatusForbidden, map[string]string{
		"code": "community_role_change_denied",
		"kind": "business",
	})
}

func TestListCommunityModerationPostsReturnsPendingItemsForModerator(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleModerator))

	pendingID := uuid.New()
	h.seedPost(&model.Post{
		ID:               pendingID,
		AuthorUserID:     h.otherID,
		Title:            "Pending community post",
		CommunityID:      &communityID,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusPending,
		Revision:         1,
	})
	h.seedPost(&model.Post{
		ID:               uuid.New(),
		AuthorUserID:     h.otherID,
		Title:            "Approved community post",
		CommunityID:      &communityID,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		Revision:         1,
	})

	rec := h.doJSON(http.MethodGet, "/v1/communities/"+communityID.String()+"/moderation/posts?limit=20&offset=0", postHTTPSubjectOwner, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		Items []struct {
			ID               string `json:"id"`
			ModerationStatus string `json:"moderationStatus"`
		} `json:"items"`
		Limit   int  `json:"limit"`
		Offset  int  `json:"offset"`
		HasMore bool `json:"hasMore"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 || body.Items[0].ID != pendingID.String() || body.Items[0].ModerationStatus != "PENDING" {
		t.Fatalf("moderation queue response = %+v, want only pending post %s", body, pendingID)
	}
	if body.Limit != 20 || body.Offset != 0 || body.HasMore {
		t.Fatalf("pagination response = %+v, want limit=20 offset=0 hasMore=false", body)
	}
}

func TestReviewCommunityPostApprovesPendingPostForModerator(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	postID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleModerator))
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.otherID,
		Title:            "Pending community post",
		CommunityID:      &communityID,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusPending,
		Revision:         1,
	})

	rec := h.doJSON(http.MethodPost, "/v1/communities/"+communityID.String()+"/moderation/posts/"+postID.String()+"/approve", postHTTPSubjectOwner, map[string]any{
		"reason": "Good community fit",
	})

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		ID               string `json:"id"`
		ModerationStatus string `json:"moderationStatus"`
		Revision         int64  `json:"revision"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.ID != postID.String() || body.ModerationStatus != "APPROVED" || body.Revision != 2 {
		t.Fatalf("review response = %+v, want approved post revision 2", body)
	}
	updated := h.repo.mustGet(postID)
	if updated.ModerationStatus != enum.ModerationStatusApproved || updated.Revision != 2 {
		t.Fatalf("stored post = %+v, want APPROVED revision 2", updated)
	}
	decision := h.repo.mustGetDecisionForPost(postID)
	if decision == nil || decision.Reason != "Good community fit" {
		t.Fatalf("moderation decision = %+v, want reason from request", decision)
	}
}

func TestReviewCommunityPostRejectsMemberRole(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	postID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleMember))
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.otherID,
		Title:            "Pending community post",
		CommunityID:      &communityID,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusPending,
		Revision:         1,
	})

	rec := h.doJSON(http.MethodPost, "/v1/communities/"+communityID.String()+"/moderation/posts/"+postID.String()+"/reject", postHTTPSubjectOwner, nil)

	assertErrorResponse(t, rec, http.StatusForbidden, map[string]string{
		"code": "community_moderation_denied",
		"kind": "business",
	})
	unchanged := h.repo.mustGet(postID)
	if unchanged.ModerationStatus != enum.ModerationStatusPending || unchanged.Revision != 1 {
		t.Fatalf("post changed despite denied moderation: %+v", unchanged)
	}
}

func TestListCommunityPostModerationDecisionsReturnsAuditHipostForModerator(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	postID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleModerator))
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.otherID,
		Title:            "Reviewed community post",
		CommunityID:      &communityID,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusRejected,
		Revision:         2,
	})
	h.seedModerationDecision(&model.PostModerationDecision{
		ID:              uuid.New(),
		PostID:          postID,
		CommunityID:     communityID,
		ModeratorUserID: h.ownerID,
		Decision:        enum.PostModerationDecisionReject,
		PreviousStatus:  enum.ModerationStatusPending,
		NextStatus:      enum.ModerationStatusRejected,
		PostRevision:    1,
		Reason:          "Off-topic",
		CreatedAt:       time.Now().UTC(),
	})

	rec := h.doJSON(http.MethodGet, "/v1/communities/"+communityID.String()+"/moderation/posts/"+postID.String()+"/decisions?limit=10&offset=0", postHTTPSubjectOwner, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		Items []struct {
			PostID          string `json:"postId"`
			CommunityID     string `json:"communityId"`
			ModeratorUserID string `json:"moderatorUserId"`
			Decision        string `json:"decision"`
			PreviousStatus  string `json:"previousStatus"`
			NextStatus      string `json:"nextStatus"`
			PostRevision    int64  `json:"postRevision"`
			Reason          string `json:"reason"`
			CreatedAt       string `json:"createdAt"`
		} `json:"items"`
		Limit   int  `json:"limit"`
		Offset  int  `json:"offset"`
		HasMore bool `json:"hasMore"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 {
		t.Fatalf("items length = %d, want 1", len(body.Items))
	}
	item := body.Items[0]
	if item.PostID != postID.String() ||
		item.CommunityID != communityID.String() ||
		item.ModeratorUserID != h.ownerID.String() ||
		item.Decision != "REJECT" ||
		item.PreviousStatus != "PENDING" ||
		item.NextStatus != "REJECTED" ||
		item.PostRevision != 1 ||
		item.Reason != "Off-topic" ||
		item.CreatedAt == "" {
		t.Fatalf("decision response item = %+v", item)
	}
	if body.Limit != 10 || body.Offset != 0 || body.HasMore {
		t.Fatalf("pagination response = %+v, want limit=10 offset=0 hasMore=false", body)
	}
}

func TestReportPostCreatesModerationCase(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	postID := uuid.New()
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.ownerID,
		Title:            "Unsafe post",
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		CommunityID:      &communityID,
		MediaStatus:      enum.PostMediaStatusReady,
		Revision:         1,
	})

	rec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/report", postHTTPSubjectOther, map[string]any{
		"reason":  "SPAM",
		"details": "Repeated scam links",
	})

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d body = %s, want 201", rec.Code, rec.Body.String())
	}
	var body struct {
		Report struct {
			ID             string `json:"id"`
			PostID         string `json:"postId"`
			CommunityID    string `json:"communityId"`
			ReporterUserID string `json:"reporterUserId"`
			Reason         string `json:"reason"`
			Details        string `json:"details"`
			Status         string `json:"status"`
		} `json:"report"`
		OpenReportsCount int  `json:"openReportsCount"`
		AutoHidden       bool `json:"autoHidden"`
		Post             struct {
			ID               string `json:"id"`
			ModerationStatus string `json:"moderationStatus"`
		} `json:"post"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.Report.ID == "" ||
		body.Report.PostID != postID.String() ||
		body.Report.CommunityID != communityID.String() ||
		body.Report.ReporterUserID != h.otherID.String() ||
		body.Report.Reason != "SPAM" ||
		body.Report.Details != "Repeated scam links" ||
		body.Report.Status != "OPEN" {
		t.Fatalf("report response = %+v, want created open report", body.Report)
	}
	if body.OpenReportsCount != 1 || body.AutoHidden {
		t.Fatalf("report moderation fields = count %d autoHidden %v, want 1/false", body.OpenReportsCount, body.AutoHidden)
	}
	if body.Post.ID != postID.String() || body.Post.ModerationStatus != "APPROVED" {
		t.Fatalf("post response = %+v, want approved post", body.Post)
	}
}

func TestReportCommunityCreatesModerationCase(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))

	rec := h.doJSON(http.MethodPost, "/v1/communities/"+communityID.String()+"/report", postHTTPSubjectOther, map[string]any{
		"reason":  "HARASSMENT",
		"details": "Unsafe community rules",
	})

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d body = %s, want 201", rec.Code, rec.Body.String())
	}
	var body struct {
		Report struct {
			ID             string `json:"id"`
			CommunityID    string `json:"communityId"`
			ReporterUserID string `json:"reporterUserId"`
			Reason         string `json:"reason"`
			Details        string `json:"details"`
			Status         string `json:"status"`
		} `json:"report"`
		OpenReportsCount int `json:"openReportsCount"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.Report.ID == "" ||
		body.Report.CommunityID != communityID.String() ||
		body.Report.ReporterUserID != h.otherID.String() ||
		body.Report.Reason != "HARASSMENT" ||
		body.Report.Details != "Unsafe community rules" ||
		body.Report.Status != "OPEN" {
		t.Fatalf("community report response = %+v, want created open report", body.Report)
	}
	if body.OpenReportsCount != 1 {
		t.Fatalf("open reports count = %d, want 1", body.OpenReportsCount)
	}
}

func TestMuteCommunityUpdatesViewerState(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))

	muteRec := h.doJSON(http.MethodPost, "/v1/communities/"+communityID.String()+"/mute", postHTTPSubjectOther, nil)
	if muteRec.Code != http.StatusOK {
		t.Fatalf("mute status = %d body = %s, want 200", muteRec.Code, muteRec.Body.String())
	}
	var muted struct {
		ID                string `json:"id"`
		FollowedByViewer  bool   `json:"followedByViewer"`
		MutedByViewer     bool   `json:"mutedByViewer"`
		ViewerTrustStatus string `json:"viewerTrustStatus"`
	}
	decodeJSONResponse(t, muteRec, &muted)
	if muted.ID != communityID.String() || muted.FollowedByViewer || !muted.MutedByViewer || muted.ViewerTrustStatus != "MUTED" {
		t.Fatalf("muted community response = %+v, want muted viewer state", muted)
	}

	unmuteRec := h.doJSON(http.MethodDelete, "/v1/communities/"+communityID.String()+"/mute", postHTTPSubjectOther, nil)
	if unmuteRec.Code != http.StatusOK {
		t.Fatalf("unmute status = %d body = %s, want 200", unmuteRec.Code, unmuteRec.Body.String())
	}
	var unmuted struct {
		ID                string `json:"id"`
		FollowedByViewer  bool   `json:"followedByViewer"`
		MutedByViewer     bool   `json:"mutedByViewer"`
		ViewerTrustStatus string `json:"viewerTrustStatus"`
	}
	decodeJSONResponse(t, unmuteRec, &unmuted)
	if unmuted.ID != communityID.String() || unmuted.FollowedByViewer || unmuted.MutedByViewer || unmuted.ViewerTrustStatus != "ACTIVE" {
		t.Fatalf("unmuted community response = %+v, want active unmuted viewer state without auto-follow", unmuted)
	}
}

func TestListCommunityPostReportsReturnsOpenReportsForModerator(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	postID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleModerator))
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.otherID,
		Title:            "Reported post",
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		CommunityID:      &communityID,
		MediaStatus:      enum.PostMediaStatusReady,
		Revision:         1,
	})
	now := time.Now().UTC()
	h.seedPostReport(&model.PostReport{
		ID:             uuid.New(),
		PostID:         postID,
		CommunityID:    &communityID,
		ReporterUserID: h.ownerID,
		AuthorUserID:   h.otherID,
		Reason:         enum.PostReportReasonHarassment,
		Details:        "Abusive language",
		Status:         enum.PostReportStatusOpen,
		CreatedAt:      now,
		UpdatedAt:      now,
	})

	rec := h.doJSON(http.MethodGet, "/v1/communities/"+communityID.String()+"/moderation/reports?status=open&limit=10&offset=0", postHTTPSubjectOwner, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d body = %s, want 200", rec.Code, rec.Body.String())
	}
	var body struct {
		Items []struct {
			PostID string `json:"postId"`
			Reason string `json:"reason"`
			Status string `json:"status"`
		} `json:"items"`
		Limit int `json:"limit"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 || body.Items[0].PostID != postID.String() || body.Items[0].Reason != "HARASSMENT" || body.Items[0].Status != "OPEN" {
		t.Fatalf("report queue response = %+v, want open harassment report", body)
	}
	if body.Limit != 10 {
		t.Fatalf("limit = %d, want 10", body.Limit)
	}
}

func TestDismissCommunityPostReportResolvesForModerator(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	postID := uuid.New()
	reportID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedCommunityMembership(postHTTPMembership(communityID, h.ownerID, enum.CommunityMembershipRoleModerator))
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.otherID,
		Title:            "Reported post",
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		CommunityID:      &communityID,
		MediaStatus:      enum.PostMediaStatusReady,
		Revision:         1,
	})
	h.seedPostReport(&model.PostReport{
		ID:             reportID,
		PostID:         postID,
		CommunityID:    &communityID,
		ReporterUserID: h.ownerID,
		AuthorUserID:   h.otherID,
		Reason:         enum.PostReportReasonHarassment,
		Details:        "Abusive language",
		Status:         enum.PostReportStatusOpen,
		CreatedAt:      time.Now().UTC(),
		UpdatedAt:      time.Now().UTC(),
	})

	rec := h.doJSON(
		http.MethodPost,
		"/v1/communities/"+communityID.String()+"/moderation/reports/"+reportID.String()+"/dismiss",
		postHTTPSubjectOwner,
		map[string]string{"resolutionNote": "No policy violation"},
	)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d body = %s, want 200", rec.Code, rec.Body.String())
	}
	var body struct {
		ID               string  `json:"id"`
		Status           string  `json:"status"`
		ResolvedByUserID *string `json:"resolvedByUserId"`
		ResolutionNote   string  `json:"resolutionNote"`
		ResolvedAt       *string `json:"resolvedAt"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.ID != reportID.String() ||
		body.Status != "DISMISSED" ||
		body.ResolvedByUserID == nil ||
		*body.ResolvedByUserID != h.ownerID.String() ||
		body.ResolutionNote != "No policy violation" ||
		body.ResolvedAt == nil {
		t.Fatalf("resolved report response = %+v, want dismissed report resolved by moderator", body)
	}
}

func TestListAdminPostReportsRequiresInternalCall(t *testing.T) {
	h := newPostHTTPTestHarness(t)

	rec := h.doJSON(http.MethodGet, "/internal/v1/moderation/post-reports?status=open&limit=10&offset=0", "", nil)

	assertErrorResponse(t, rec, http.StatusUnauthorized, map[string]string{
		"code": "missing_authenticated_subject",
		"kind": "business",
	})
}

func TestListAdminCommunityModerationPostsListsPendingWithoutMembership(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	pendingID := uuid.New()
	staffID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedPost(&model.Post{
		ID:               pendingID,
		AuthorUserID:     h.ownerID,
		Title:            "Community post for admin review",
		Excerpt:          "Fresh post waiting for moderation.",
		Format:           enum.PostFormatPost,
		Category:         enum.PostCategoryJournal,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusPending,
		CommunityID:      &communityID,
		Revision:         1,
		CreatedAt:        time.Now().UTC(),
		UpdatedAt:        time.Now().UTC(),
	})
	h.seedPost(&model.Post{
		ID:               uuid.New(),
		AuthorUserID:     h.ownerID,
		Title:            "Already approved community post",
		Format:           enum.PostFormatPost,
		Category:         enum.PostCategoryJournal,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		CommunityID:      &communityID,
		Revision:         1,
		CreatedAt:        time.Now().UTC(),
		UpdatedAt:        time.Now().UTC(),
	})

	rec := h.doInternalJSON(http.MethodGet, "/internal/v1/moderation/community-posts?limit=10&offset=0", staffID, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		Items []struct {
			ID               string  `json:"id"`
			CommunityID      *string `json:"communityId"`
			ModerationStatus string  `json:"moderationStatus"`
		} `json:"items"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 ||
		body.Items[0].ID != pendingID.String() ||
		body.Items[0].CommunityID == nil ||
		*body.Items[0].CommunityID != communityID.String() ||
		body.Items[0].ModerationStatus != "PENDING" {
		t.Fatalf("admin community post list = %+v, want pending post %s", body.Items, pendingID)
	}
}

func TestApproveAdminCommunityModerationPostApprovesWithoutMembership(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	postID := uuid.New()
	staffID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.ownerID,
		Title:            "Community post for admin approval",
		Excerpt:          "Fresh post waiting for moderation.",
		Format:           enum.PostFormatPost,
		Category:         enum.PostCategoryJournal,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusPending,
		CommunityID:      &communityID,
		Revision:         1,
		CreatedAt:        time.Now().UTC(),
		UpdatedAt:        time.Now().UTC(),
	})

	rec := h.doInternalJSON(
		http.MethodPost,
		"/internal/v1/moderation/community-posts/"+postID.String()+"/approve",
		staffID,
		map[string]any{"reason": "Fits community rules."},
	)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		ID               string `json:"id"`
		ModerationStatus string `json:"moderationStatus"`
		Revision         int64  `json:"revision"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.ID != postID.String() || body.ModerationStatus != "APPROVED" || body.Revision != 2 {
		t.Fatalf("admin community post review = %+v, want approved post revision 2", body)
	}
	decision := h.repo.mustGetDecisionForPost(postID)
	if decision == nil || decision.ModeratorUserID != staffID || decision.Reason != "Fits community rules." {
		t.Fatalf("moderation decision = %+v, want staff decision with reason", decision)
	}
}

func TestDismissAdminPostReportResolvesWithoutCommunityMembership(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	reportID := uuid.New()
	postID := uuid.New()
	staffID := uuid.New()
	h.seedCommunity(postHTTPCommunity(communityID))
	h.seedPost(&model.Post{
		ID:               postID,
		AuthorUserID:     h.ownerID,
		Title:            "Reported post",
		Excerpt:          "Needs review",
		Format:           enum.PostFormatPost,
		Category:         enum.PostCategoryJournal,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		CommunityID:      &communityID,
		Revision:         1,
		CreatedAt:        time.Now().UTC(),
		UpdatedAt:        time.Now().UTC(),
	})
	h.seedPostReport(&model.PostReport{
		ID:             reportID,
		PostID:         postID,
		CommunityID:    &communityID,
		ReporterUserID: h.otherID,
		AuthorUserID:   h.ownerID,
		Reason:         enum.PostReportReasonHarassment,
		Details:        "Threatening language.",
		Status:         enum.PostReportStatusOpen,
		CreatedAt:      time.Now().UTC(),
		UpdatedAt:      time.Now().UTC(),
	})

	listRec := h.doInternalJSON(http.MethodGet, "/internal/v1/moderation/post-reports?status=open&limit=10&offset=0", staffID, nil)

	if listRec.Code != http.StatusOK {
		t.Fatalf("list status = %d, want %d; body: %s", listRec.Code, http.StatusOK, listRec.Body.String())
	}
	var listBody struct {
		Items []struct {
			ID          string  `json:"id"`
			CommunityID *string `json:"communityId"`
		} `json:"items"`
	}
	decodeJSONResponse(t, listRec, &listBody)
	if len(listBody.Items) != 1 || listBody.Items[0].ID != reportID.String() {
		t.Fatalf("admin report list = %+v, want report %s", listBody.Items, reportID)
	}

	resolveRec := h.doInternalJSON(
		http.MethodPost,
		"/internal/v1/moderation/post-reports/"+reportID.String()+"/dismiss",
		staffID,
		map[string]any{"resolutionNote": "No policy violation after admin review."},
	)

	if resolveRec.Code != http.StatusOK {
		t.Fatalf("resolve status = %d, want %d; body: %s", resolveRec.Code, http.StatusOK, resolveRec.Body.String())
	}
	var body struct {
		ID               string  `json:"id"`
		Status           string  `json:"status"`
		ResolvedByUserID *string `json:"resolvedByUserId"`
		ResolutionNote   string  `json:"resolutionNote"`
	}
	decodeJSONResponse(t, resolveRec, &body)
	if body.ID != reportID.String() ||
		body.Status != "DISMISSED" ||
		body.ResolvedByUserID == nil ||
		*body.ResolvedByUserID != staffID.String() ||
		body.ResolutionNote != "No policy violation after admin review." {
		t.Fatalf("admin resolved report response = %+v, want dismissed by staff", body)
	}
}

func TestListMyPostsFiltersArchivedStatus(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	h.seedPost(&model.Post{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Draft", Status: enum.PostStatusDraft, ModerationStatus: enum.ModerationStatusNotRequired, Revision: 1})
	archivedAt := time.Now().UTC()
	archivedID := uuid.New()
	h.seedPost(&model.Post{ID: archivedID, AuthorUserID: h.ownerID, Title: "Archived", Status: enum.PostStatusPublished, ModerationStatus: enum.ModerationStatusApproved, ArchivedAt: &archivedAt, Revision: 1})

	rec := h.doJSON(http.MethodGet, "/v1/posts/mine?status=ARCHIVED", postHTTPSubjectOwner, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		Items []struct {
			ID         string  `json:"id"`
			Status     string  `json:"status"`
			ArchivedAt *string `json:"archivedAt"`
		} `json:"items"`
		Total int `json:"total"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 || body.Total != 1 || body.Items[0].ID != archivedID.String() || body.Items[0].ArchivedAt == nil {
		t.Fatalf("archived list response = %+v, want only archived post %s", body, archivedID)
	}
	if body.Items[0].Status != "ARCHIVED" {
		t.Fatalf("archived post status = %q, want ARCHIVED", body.Items[0].Status)
	}
}

func TestListMyPostsPublishedFilterExcludesArchivedPosts(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	activeID := uuid.New()
	h.seedPost(&model.Post{ID: activeID, AuthorUserID: h.ownerID, Title: "Active", Status: enum.PostStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})
	archivedAt := time.Now().UTC()
	h.seedPost(&model.Post{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Archived", Status: enum.PostStatusPublished, ModerationStatus: enum.ModerationStatusApproved, ArchivedAt: &archivedAt, Revision: 1})

	rec := h.doJSON(http.MethodGet, "/v1/posts/mine?status=PUBLISHED", postHTTPSubjectOwner, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		Items []struct {
			ID string `json:"id"`
		} `json:"items"`
		Total int `json:"total"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 || body.Total != 1 || body.Items[0].ID != activeID.String() {
		t.Fatalf("published owner list = %+v, want only active post %s", body, activeID)
	}
}

func TestListMyPostsFiltersCommunityAndModerationStatus(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	communityID := uuid.New()
	otherCommunityID := uuid.New()
	pendingID := uuid.New()
	h.seedPost(&model.Post{
		ID:               pendingID,
		AuthorUserID:     h.ownerID,
		CommunityID:      &communityID,
		Title:            "Pending community post",
		Format:           enum.PostFormatArticle,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusPending,
		Revision:         1,
	})
	h.seedPost(&model.Post{
		ID:               uuid.New(),
		AuthorUserID:     h.ownerID,
		CommunityID:      &otherCommunityID,
		Title:            "Other community post",
		Format:           enum.PostFormatArticle,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusPending,
		Revision:         1,
	})
	h.seedPost(&model.Post{
		ID:               uuid.New(),
		AuthorUserID:     h.ownerID,
		CommunityID:      &communityID,
		Title:            "Approved community post",
		Format:           enum.PostFormatArticle,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		Revision:         1,
	})

	rec := h.doJSON(
		http.MethodGet,
		"/v1/posts/mine?communityId="+communityID.String()+"&moderationStatus=PENDING",
		postHTTPSubjectOwner,
		nil,
	)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		Items []struct {
			ID               string `json:"id"`
			CommunityID      string `json:"communityId"`
			ModerationStatus string `json:"moderationStatus"`
		} `json:"items"`
		Total int `json:"total"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 || body.Total != 1 {
		t.Fatalf("mine community list = %+v, want one pending post", body)
	}
	if body.Items[0].ID != pendingID.String() ||
		body.Items[0].CommunityID != communityID.String() ||
		body.Items[0].ModerationStatus != "PENDING" {
		t.Fatalf("mine community item = %+v, want pending %s", body.Items[0], pendingID)
	}
}

func TestListMyPostsDefaultExcludesArchivedFromItemsTotalAndHasMore(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	firstID := uuid.New()
	secondID := uuid.New()
	h.seedPost(&model.Post{ID: firstID, AuthorUserID: h.ownerID, Title: "First active", Status: enum.PostStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})
	h.seedPost(&model.Post{ID: secondID, AuthorUserID: h.ownerID, Title: "Second active", Status: enum.PostStatusDraft, ModerationStatus: enum.ModerationStatusNotRequired, Revision: 1})
	archivedAt := time.Now().UTC()
	h.seedPost(&model.Post{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Archived", Status: enum.PostStatusPublished, ModerationStatus: enum.ModerationStatusApproved, ArchivedAt: &archivedAt, Revision: 1})

	rec := h.doJSON(http.MethodGet, "/v1/posts/mine?limit=2&offset=0", postHTTPSubjectOwner, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		Items []struct {
			ID     string `json:"id"`
			Status string `json:"status"`
		} `json:"items"`
		Total   int  `json:"total"`
		Limit   int  `json:"limit"`
		Offset  int  `json:"offset"`
		HasMore bool `json:"hasMore"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 2 || body.Total != 2 || body.Limit != 2 || body.Offset != 0 || body.HasMore {
		t.Fatalf("mine active list = %+v, want 2 active items total=2 limit=2 offset=0 hasMore=false", body)
	}
	for _, item := range body.Items {
		if item.Status == "ARCHIVED" {
			t.Fatalf("active mine list exposed archived item: %+v", body)
		}
	}
}

func TestArchivePostSetsArchivedAt(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := h.mustCreatePublishableDraft(t)
	post := h.repo.mustGet(postID)

	rec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/archive", postHTTPSubjectOwner, map[string]any{
		"revision": post.Revision,
	})

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		ID         string  `json:"id"`
		Status     string  `json:"status"`
		ArchivedAt *string `json:"archivedAt"`
		Revision   int64   `json:"revision"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.ID != postID.String() || body.ArchivedAt == nil || body.Revision != post.Revision+1 {
		t.Fatalf("archive response = %+v, want archived post revision %d", body, post.Revision+1)
	}
	if body.Status != "ARCHIVED" {
		t.Fatalf("archive response status = %q, want ARCHIVED", body.Status)
	}
}

func TestAutosavePostRequiresRevisionAndSetsLastAutosavedAt(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := h.mustCreateDraft(t, postHTTPSubjectOwner, "Autosave me")

	rec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/autosave", postHTTPSubjectOwner, map[string]any{
		"revision": 1,
		"title":    "Autosaved",
		"contentBlocks": map[string]any{
			"version": 1,
			"blocks": []map[string]any{{
				"id":   "p1",
				"type": "paragraph",
				"text": "Autosaved content",
			}},
		},
	})

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		Title           string  `json:"title"`
		LastAutosavedAt *string `json:"lastAutosavedAt"`
		Revision        int64   `json:"revision"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.Title != "Autosaved" || body.LastAutosavedAt == nil || body.Revision != 2 {
		t.Fatalf("autosave response = %+v, want title Autosaved, lastAutosavedAt, revision 2", body)
	}
}

func TestAutosaveLogsSafeSuccessFailureAndRevisionConflictCounters(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := h.mustCreateDraft(t, postHTTPSubjectOwner, "Autosave logging")
	logs := capturePostHTTPLogs(t)

	successRec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/autosave", postHTTPSubjectOwner, map[string]any{
		"revision": 1,
		"title":    "Autosave safe",
		"contentBlocks": map[string]any{
			"version": 1,
			"blocks": []map[string]any{{
				"id":   "p1",
				"type": "paragraph",
				"text": "autosave secret body should never be logged",
			}},
		},
	})
	if successRec.Code != http.StatusOK {
		t.Fatalf("success status = %d, want %d; body: %s", successRec.Code, http.StatusOK, successRec.Body.String())
	}

	failureRec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/autosave", postHTTPSubjectOwner, map[string]any{
		"revision": 1,
		"title":    "Stale autosave",
		"contentBlocks": map[string]any{
			"version": 1,
			"blocks": []map[string]any{{
				"id":   "p1",
				"type": "paragraph",
				"text": "stale autosave body should never be logged",
			}},
		},
	})
	if failureRec.Code != http.StatusConflict {
		t.Fatalf("failure status = %d, want %d; body: %s", failureRec.Code, http.StatusConflict, failureRec.Body.String())
	}

	output := logs.String()
	for _, want := range []string{
		`"metric":"posts_autosave_success_total"`,
		`"metric":"posts_autosave_failure_total"`,
		`"metric":"posts_revision_conflict_total"`,
		`"operation":"autosave"`,
		`"request_id":"req-test"`,
		`"post_id":"` + postID.String() + `"`,
	} {
		if !strings.Contains(output, want) {
			t.Fatalf("logs = %s, want %s", output, want)
		}
	}
	if containsAny(output, "autosave secret body", "stale autosave body", "contentBlocks", "content_plain_text", "plainText") {
		t.Fatalf("autosave log leaked content payload: %s", output)
	}
}

func TestPatchPostPreservesOmittedFields(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := h.mustCreatePublishableDraft(t)
	original := h.repo.mustGet(postID)

	rec := h.doJSON(http.MethodPatch, "/v1/posts/"+postID.String(), postHTTPSubjectOwner, map[string]any{
		"revision": original.Revision,
		"title":    "Retitled",
	})

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	updated := h.repo.mustGet(postID)
	if updated.Title != "Retitled" {
		t.Fatalf("Title = %q, want Retitled", updated.Title)
	}
	if updated.Category != original.Category ||
		updated.CoverFileID == nil ||
		*updated.CoverFileID != *original.CoverFileID ||
		updated.PlaceName == nil ||
		*updated.PlaceName != *original.PlaceName ||
		string(updated.ContentBlocks) != string(original.ContentBlocks) ||
		updated.Status != original.Status ||
		updated.ModerationStatus != original.ModerationStatus ||
		strings.Join(updated.Tags, ",") != strings.Join(original.Tags, ",") {
		t.Fatalf("partial patch did not preserve fields\noriginal=%+v\nupdated=%+v", original, updated)
	}
	if updated.Slug == original.Slug {
		t.Fatalf("Slug = %q, want retitle to rebuild slug", updated.Slug)
	}
}

func TestPatchPostRejectsClientArchivedStatus(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := h.mustCreateDraft(t, postHTTPSubjectOwner, "Patch archived")

	rec := h.doJSON(http.MethodPatch, "/v1/posts/"+postID.String(), postHTTPSubjectOwner, map[string]any{
		"revision": 1,
		"status":   "ARCHIVED",
	})

	assertErrorResponse(t, rec, http.StatusBadRequest, map[string]string{
		"code": "invalid_post_status",
		"kind": "business",
	})
}

func TestAutosavePostPreservesOmittedFieldsAndModeration(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := h.mustCreatePublishableDraft(t)
	post := h.repo.mustGet(postID)
	post.ModerationStatus = enum.ModerationStatusRejected
	h.seedPost(post)

	rec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/autosave", postHTTPSubjectOwner, map[string]any{
		"revision": post.Revision,
		"title":    "Autosaved title",
	})

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	updated := h.repo.mustGet(postID)
	if updated.ModerationStatus != enum.ModerationStatusRejected {
		t.Fatalf("ModerationStatus = %q, want REJECTED", updated.ModerationStatus)
	}
	if updated.Category != post.Category ||
		updated.CoverFileID == nil ||
		*updated.CoverFileID != *post.CoverFileID ||
		updated.PlaceName == nil ||
		*updated.PlaceName != *post.PlaceName ||
		string(updated.ContentBlocks) != string(post.ContentBlocks) ||
		updated.Status != post.Status ||
		strings.Join(updated.Tags, ",") != strings.Join(post.Tags, ",") {
		t.Fatalf("autosave did not preserve omitted fields\noriginal=%+v\nupdated=%+v", post, updated)
	}
}

func TestAutosavePostRejectsClientArchivedStatus(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := h.mustCreateDraft(t, postHTTPSubjectOwner, "Autosave archived")

	rec := h.doJSON(http.MethodPost, "/v1/posts/"+postID.String()+"/autosave", postHTTPSubjectOwner, map[string]any{
		"revision": 1,
		"status":   "ARCHIVED",
	})

	assertErrorResponse(t, rec, http.StatusBadRequest, map[string]string{
		"code": "invalid_post_status",
		"kind": "business",
	})
}

func TestUpdatePostMapsRevisionConflictToConflict(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := h.mustCreateDraft(t, postHTTPSubjectOwner, "Original")

	rec := h.doJSON(http.MethodPatch, "/v1/posts/"+postID.String(), postHTTPSubjectOwner, map[string]any{
		"revision": 99,
		"title":    "Stale update",
	})

	assertErrorResponse(t, rec, http.StatusConflict, map[string]string{
		"code": "post_revision_conflict",
		"kind": "business",
	})
}

func TestPublicPostDetailHidesDraftsFromNonOwners(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	postID := h.mustCreateDraft(t, postHTTPSubjectOwner, "Private draft")

	publicRec := h.doJSON(http.MethodGet, "/v1/posts/"+postID.String(), postHTTPSubjectOther, nil)
	assertErrorResponse(t, publicRec, http.StatusNotFound, map[string]string{
		"code": "post_not_found",
		"kind": "business",
	})

	ownerRec := h.doJSON(http.MethodGet, "/v1/posts/"+postID.String(), postHTTPSubjectOwner, nil)
	if ownerRec.Code != http.StatusOK {
		t.Fatalf("owner status = %d, want %d; body: %s", ownerRec.Code, http.StatusOK, ownerRec.Body.String())
	}
}

func TestPublicPostDetailRanksRelatedPostsByRelevance(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	authorID := h.ownerID
	otherAuthorID := h.otherID
	now := time.Now().UTC()

	targetID := uuid.New()
	h.seedPost(&model.Post{
		ID:               targetID,
		Slug:             "almaty-food-guide",
		AuthorUserID:     authorID,
		Title:            "Almaty Food Guide",
		Format:           enum.PostFormatGuide,
		Category:         enum.PostCategoryGuide,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		PlaceName:        postHTTPStringPtr("Almaty"),
		PlaceCountryCode: postHTTPStringPtr("KZ"),
		PlaceCityID:      postHTTPStringPtr("almaty"),
		Tags:             []string{"food", "almaty"},
		ViewCount:        20,
		PublishedAt:      &now,
		CreatedAt:        now,
		Revision:         1,
	})

	h.seedPost(&model.Post{
		ID:               uuid.New(),
		Slug:             "almaty-photo-walk",
		AuthorUserID:     otherAuthorID,
		Title:            "Almaty Photo Walk",
		Format:           enum.PostFormatPhotoEssay,
		Category:         enum.PostCategoryPhotoEssay,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		PlaceName:        postHTTPStringPtr("Almaty"),
		PlaceCountryCode: postHTTPStringPtr("KZ"),
		PlaceCityID:      postHTTPStringPtr("almaty"),
		Tags:             []string{"mountains"},
		ViewCount:        1,
		PublishedAt:      postHTTPTimePtr(now.Add(-72 * time.Hour)),
		CreatedAt:        now.Add(-72 * time.Hour),
		Revision:         1,
	})
	h.seedPost(&model.Post{
		ID:               uuid.New(),
		Slug:             "astana-food-guide",
		AuthorUserID:     otherAuthorID,
		Title:            "Astana Food Guide",
		Format:           enum.PostFormatGuide,
		Category:         enum.PostCategoryGuide,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		PlaceName:        postHTTPStringPtr("Astana"),
		PlaceCountryCode: postHTTPStringPtr("KZ"),
		PlaceCityID:      postHTTPStringPtr("astana"),
		Tags:             []string{"food"},
		ViewCount:        5,
		PublishedAt:      postHTTPTimePtr(now.Add(-48 * time.Hour)),
		CreatedAt:        now.Add(-48 * time.Hour),
		Revision:         1,
	})
	h.seedPost(&model.Post{
		ID:               uuid.New(),
		Slug:             "popular-unrelated",
		AuthorUserID:     otherAuthorID,
		Title:            "Popular Unrelated",
		Format:           enum.PostFormatArticle,
		Category:         enum.PostCategoryJournal,
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		PlaceName:        postHTTPStringPtr("Berlin"),
		PlaceCountryCode: postHTTPStringPtr("DE"),
		PlaceCityID:      postHTTPStringPtr("berlin"),
		Tags:             []string{"nightlife"},
		ViewCount:        10000,
		PublishedAt:      postHTTPTimePtr(now.Add(-24 * time.Hour)),
		CreatedAt:        now.Add(-24 * time.Hour),
		Revision:         1,
	})

	rec := h.doJSON(http.MethodGet, "/v1/public/posts/almaty-food-guide", "", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		Related []struct {
			Slug string `json:"slug"`
		} `json:"related"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Related) < 2 {
		t.Fatalf("related = %+v, want at least two relevant posts", body.Related)
	}
	if body.Related[0].Slug != "almaty-photo-walk" {
		t.Fatalf("first related slug = %q, want same-city post", body.Related[0].Slug)
	}
	if body.Related[1].Slug != "astana-food-guide" {
		t.Fatalf("second related slug = %q, want same-theme tagged post", body.Related[1].Slug)
	}
	for _, related := range body.Related {
		if related.Slug == "almaty-food-guide" {
			t.Fatalf("related includes the current post: %+v", body.Related)
		}
	}
}

func TestToPostResponseIncludesPublicCoverImageURL(t *testing.T) {
	coverFileID := uuid.New()
	authorID := uuid.New()
	now := time.Now().UTC()

	resp := toPostResponse(&app.PostView{
		Post: &model.Post{
			ID:                   uuid.New(),
			Slug:                 "cover-post",
			AuthorUserID:         authorID,
			Title:                "Cover Post",
			Format:               enum.PostFormatGuide,
			ContentSchemaVersion: model.PostDocumentVersion,
			Category:             enum.PostCategoryGuide,
			Status:               enum.PostStatusPublished,
			ModerationStatus:     enum.ModerationStatusNotRequired,
			CoverFileID:          &coverFileID,
			CreatedAt:            now,
			UpdatedAt:            now,
		},
		Author: app.PostAuthor{UserID: authorID},
	}, false)

	if resp.CoverImageURL == nil {
		t.Fatal("CoverImageURL is nil, want public file URL")
	}
	want := "/api/v1/public/files/" + coverFileID.String() + "/content"
	if *resp.CoverImageURL != want {
		t.Fatalf("CoverImageURL = %q, want %q", *resp.CoverImageURL, want)
	}
}

const (
	postHTTPSubjectOwner = "owner-subject"
	postHTTPSubjectOther = "other-subject"
)

func TestPostCreateEligibilityEndpointReportsRateLimit(t *testing.T) {
	h := newPostHTTPTestHarness(t)
	const postCreateLimit = 10
	for i := 0; i < postCreateLimit; i++ {
		rec := h.doJSON(http.MethodPost, "/v1/posts", postHTTPSubjectOwner, map[string]any{
			"title": "Draft",
		})
		if rec.Code != http.StatusCreated {
			t.Fatalf("create post %d status = %d, want %d; body: %s", i, rec.Code, http.StatusCreated, rec.Body.String())
		}
	}

	rec := h.doJSON(http.MethodGet, "/v1/posts/create-eligibility", postHTTPSubjectOwner, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("eligibility status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	var body struct {
		CanCreate         bool    `json:"canCreate"`
		Limit             int     `json:"limit"`
		Remaining         int     `json:"remaining"`
		WindowSeconds     int64   `json:"windowSeconds"`
		RetryAfterSeconds int64   `json:"retryAfterSeconds"`
		NextAvailableAt   *string `json:"nextAvailableAt"`
	}
	decodeJSONResponse(t, rec, &body)
	if body.CanCreate {
		t.Fatal("canCreate = true, want false")
	}
	if body.Limit != postCreateLimit || body.Remaining != 0 {
		t.Fatalf("limit/remaining = %d/%d, want %d/0", body.Limit, body.Remaining, postCreateLimit)
	}
	if body.WindowSeconds <= 0 || body.RetryAfterSeconds <= 0 || body.NextAvailableAt == nil {
		t.Fatalf("eligibility timing = %+v, want positive retry metadata", body)
	}
}

type postHTTPTestHarness struct {
	mux     *http.ServeMux
	handler *Handler
	repo    *postHTTPMemoryRepository
	ownerID uuid.UUID
	otherID uuid.UUID
}

func newPostHTTPTestHarness(t *testing.T) *postHTTPTestHarness {
	t.Helper()

	ownerID := uuid.New()
	otherID := uuid.New()
	repo := newPostHTTPMemoryRepository()
	users := &postHTTPUserClient{
		subjects: map[string]uuid.UUID{
			postHTTPSubjectOwner: ownerID,
			postHTTPSubjectOther: otherID,
		},
	}

	mux := http.NewServeMux()
	handler := NewHandler(app.NewPostUseCase(repo, users, "https://posts.test"))
	handler.Register(mux)

	return &postHTTPTestHarness{
		mux:     mux,
		handler: handler,
		repo:    repo,
		ownerID: ownerID,
		otherID: otherID,
	}
}

func (h *postHTTPTestHarness) doJSON(method string, path string, subject string, payload any) *httptest.ResponseRecorder {
	var body *bytes.Reader
	if payload == nil {
		body = bytes.NewReader(nil)
	} else {
		data, err := json.Marshal(payload)
		if err != nil {
			panic(err)
		}
		body = bytes.NewReader(data)
	}

	req := httptest.NewRequest(method, path, body)
	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Accept-Language", "en")
	if subject != "" {
		req = req.WithContext(withSubject(req.Context(), subject))
	}
	req = req.WithContext(withRequestID(req.Context(), "req-test"))

	rec := httptest.NewRecorder()
	h.mux.ServeHTTP(rec, req)
	return rec
}

func (h *postHTTPTestHarness) doInternalJSON(method string, path string, staffID uuid.UUID, payload any) *httptest.ResponseRecorder {
	var body *bytes.Reader
	if payload == nil {
		body = bytes.NewReader(nil)
	} else {
		data, err := json.Marshal(payload)
		if err != nil {
			panic(err)
		}
		body = bytes.NewReader(data)
	}

	req := httptest.NewRequest(method, path, body)
	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Accept-Language", "en")
	ctx := withRequestID(req.Context(), "req-test")
	ctx = withInternalCall(ctx)
	ctx = withUserID(ctx, staffID.String())
	ctx = withSubject(ctx, "admin-panel:"+staffID.String())
	req = req.WithContext(ctx)

	rec := httptest.NewRecorder()
	h.mux.ServeHTTP(rec, req)
	return rec
}

func capturePostHTTPLogs(t *testing.T) *bytes.Buffer {
	t.Helper()

	var buf bytes.Buffer
	previous := log.Logger
	log.Logger = zerolog.New(&buf)
	t.Cleanup(func() {
		log.Logger = previous
	})
	return &buf
}

func (h *postHTTPTestHarness) mustCreateDraft(t *testing.T, subject string, title string) uuid.UUID {
	t.Helper()
	rec := h.doJSON(http.MethodPost, "/v1/posts", subject, map[string]any{"title": title})
	if rec.Code != http.StatusCreated {
		t.Fatalf("create draft status = %d, want %d; body: %s", rec.Code, http.StatusCreated, rec.Body.String())
	}
	var body struct {
		ID string `json:"id"`
	}
	decodeJSONResponse(t, rec, &body)
	postID, err := uuid.Parse(body.ID)
	if err != nil {
		t.Fatalf("parse created post id %q: %v", body.ID, err)
	}
	return postID
}

func (h *postHTTPTestHarness) mustCreatePublishableDraft(t *testing.T) uuid.UUID {
	t.Helper()
	coverID := uuid.New()
	placeName := "Almaty"
	rec := h.doJSON(http.MethodPost, "/v1/posts", postHTTPSubjectOwner, map[string]any{
		"title":       "Publishable",
		"category":    "GUIDE",
		"coverFileId": coverID.String(),
		"placeName":   placeName,
		"contentBlocks": map[string]any{
			"version": 1,
			"blocks": []map[string]any{{
				"id":   "p1",
				"type": "paragraph",
				"text": "Ready for readers.",
			}},
		},
	})
	if rec.Code != http.StatusCreated {
		t.Fatalf("create publishable draft status = %d, want %d; body: %s", rec.Code, http.StatusCreated, rec.Body.String())
	}
	var body struct {
		ID string `json:"id"`
	}
	decodeJSONResponse(t, rec, &body)
	postID, err := uuid.Parse(body.ID)
	if err != nil {
		t.Fatalf("parse created post id %q: %v", body.ID, err)
	}
	return postID
}

func (h *postHTTPTestHarness) seedPost(post *model.Post) {
	if post != nil && post.Format == "" {
		post.Format = enum.PostFormatArticle
	}
	h.repo.seed(post)
}

func (h *postHTTPTestHarness) seedCommunity(community *model.Community) {
	h.repo.seedCommunity(community)
}

func (h *postHTTPTestHarness) seedCommunityMembership(membership *model.CommunityMembership) {
	h.repo.seedCommunityMembership(membership)
}

func (h *postHTTPTestHarness) seedModerationDecision(decision *model.PostModerationDecision) {
	h.repo.seedModerationDecision(decision)
}

func (h *postHTTPTestHarness) seedPostReport(report *model.PostReport) {
	h.repo.seedPostReport(report)
}

func decodeJSONResponse(t *testing.T, rec *httptest.ResponseRecorder, target any) {
	t.Helper()
	if err := json.Unmarshal(rec.Body.Bytes(), target); err != nil {
		t.Fatalf("decode response: %v; body: %s", err, rec.Body.String())
	}
}

func postHTTPStringPtr(value string) *string {
	return &value
}

func postHTTPTimePtr(value time.Time) *time.Time {
	return &value
}

func postHTTPCommunity(communityID uuid.UUID) *model.Community {
	now := time.Now().UTC()
	return &model.Community{
		ID:            communityID,
		Slug:          "community-" + communityID.String()[:8],
		Title:         "Community",
		Topic:         "TRAVEL",
		LanguageCode:  "en",
		Visibility:    enum.CommunityVisibilityPublic,
		PostingPolicy: enum.CommunityPostingPolicyMembersAfterModeration,
		Status:        enum.CommunityStatusActive,
		CreatedAt:     now,
		UpdatedAt:     now,
	}
}

func postHTTPMembership(communityID uuid.UUID, userID uuid.UUID, role enum.CommunityMembershipRole) *model.CommunityMembership {
	now := time.Now().UTC()
	return &model.CommunityMembership{
		CommunityID: communityID,
		UserID:      userID,
		Role:        role,
		Status:      enum.CommunityMembershipStatusActive,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
}

type postHTTPUserClient struct {
	subjects map[string]uuid.UUID
}

func (c *postHTTPUserClient) ResolveUserIDBySubject(_ context.Context, subject string) (uuid.UUID, error) {
	userID, ok := c.subjects[subject]
	if !ok {
		return uuid.Nil, app.ErrUserNotFound
	}
	return userID, nil
}

func (c *postHTTPUserClient) GetPublicUserProfiles(
	_ context.Context,
	userIDs []uuid.UUID,
) (map[uuid.UUID]app.PublicUserProfile, error) {
	profiles := make(map[uuid.UUID]app.PublicUserProfile, len(userIDs))
	for _, userID := range userIDs {
		profiles[userID] = app.PublicUserProfile{UserID: userID, Locale: "en", Timezone: "Asia/Almaty"}
	}
	return profiles, nil
}

func (c *postHTTPUserClient) FilterFriendUserIDs(
	context.Context,
	uuid.UUID,
	[]uuid.UUID,
) (map[uuid.UUID]bool, error) {
	return map[uuid.UUID]bool{}, nil
}

func (c *postHTTPUserClient) FilterFollowingUserIDs(
	context.Context,
	uuid.UUID,
	[]uuid.UUID,
) (map[uuid.UUID]bool, error) {
	return map[uuid.UUID]bool{}, nil
}

type postHTTPMemoryRepository struct {
	mu                 sync.Mutex
	posts              map[uuid.UUID]*model.Post
	stories            map[uuid.UUID]*model.Story
	communities        map[uuid.UUID]*model.Community
	memberships        map[uuid.UUID]map[uuid.UUID]*model.CommunityMembership
	decisions          map[uuid.UUID]*model.PostModerationDecision
	reports            map[uuid.UUID]*model.PostReport
	communityReports   map[uuid.UUID]*model.CommunityReport
	roleChanges        []*model.CommunityMemberRoleChange
	statusChanges      []*model.CommunityMemberStatusChange
	feedEvents         []model.FeedEvent
	feedQualityMetrics []model.FeedQualityMetric
	feedSocialEdges    map[uuid.UUID]model.FeedSocialEdge
	follows            map[uuid.UUID]map[uuid.UUID]bool
	likes              map[uuid.UUID]map[uuid.UUID]bool
	storyLikes         map[uuid.UUID]map[uuid.UUID]bool
	seen               map[uuid.UUID]map[uuid.UUID]time.Time
	storySeen          map[uuid.UUID]map[uuid.UUID]time.Time
}

func newPostHTTPMemoryRepository() *postHTTPMemoryRepository {
	return &postHTTPMemoryRepository{
		posts:              make(map[uuid.UUID]*model.Post),
		stories:            make(map[uuid.UUID]*model.Story),
		communities:        make(map[uuid.UUID]*model.Community),
		memberships:        make(map[uuid.UUID]map[uuid.UUID]*model.CommunityMembership),
		decisions:          make(map[uuid.UUID]*model.PostModerationDecision),
		reports:            make(map[uuid.UUID]*model.PostReport),
		communityReports:   make(map[uuid.UUID]*model.CommunityReport),
		roleChanges:        make([]*model.CommunityMemberRoleChange, 0),
		statusChanges:      make([]*model.CommunityMemberStatusChange, 0),
		feedEvents:         make([]model.FeedEvent, 0),
		feedQualityMetrics: make([]model.FeedQualityMetric, 0),
		feedSocialEdges:    make(map[uuid.UUID]model.FeedSocialEdge),
		follows:            make(map[uuid.UUID]map[uuid.UUID]bool),
		likes:              make(map[uuid.UUID]map[uuid.UUID]bool),
		storyLikes:         make(map[uuid.UUID]map[uuid.UUID]bool),
		seen:               make(map[uuid.UUID]map[uuid.UUID]time.Time),
		storySeen:          make(map[uuid.UUID]map[uuid.UUID]time.Time),
	}
}

func (r *postHTTPMemoryRepository) seed(post *model.Post) {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now().UTC()
	copy := cloneHTTPPost(post)
	if copy.Slug == "" {
		copy.Slug = strings.ToLower(strings.ReplaceAll(copy.Title, " ", "-")) + "-" + copy.ID.String()[:8]
	}
	if copy.CreatedAt.IsZero() {
		copy.CreatedAt = now
	}
	if copy.UpdatedAt.IsZero() {
		copy.UpdatedAt = now
	}
	if copy.PublishedAt == nil && copy.Status == enum.PostStatusPublished {
		copy.PublishedAt = &now
	}
	r.posts[copy.ID] = copy
}

func (r *postHTTPMemoryRepository) seedCommunity(community *model.Community) {
	r.mu.Lock()
	defer r.mu.Unlock()

	copy := cloneHTTPCommunity(community)
	r.communities[copy.ID] = copy
}

func (r *postHTTPMemoryRepository) seedCommunityMembership(membership *model.CommunityMembership) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.memberships[membership.CommunityID] == nil {
		r.memberships[membership.CommunityID] = make(map[uuid.UUID]*model.CommunityMembership)
	}
	copy := *membership
	r.memberships[membership.CommunityID][membership.UserID] = &copy
}

func (r *postHTTPMemoryRepository) seedModerationDecision(decision *model.PostModerationDecision) {
	r.mu.Lock()
	defer r.mu.Unlock()

	copy := *decision
	r.decisions[decision.ID] = &copy
}

func (r *postHTTPMemoryRepository) seedPostReport(report *model.PostReport) {
	r.mu.Lock()
	defer r.mu.Unlock()

	copy := *report
	if copy.CreatedAt.IsZero() {
		copy.CreatedAt = time.Now().UTC()
	}
	if copy.UpdatedAt.IsZero() {
		copy.UpdatedAt = copy.CreatedAt
	}
	r.reports[report.ID] = &copy
}

func (r *postHTTPMemoryRepository) listRoleChangesForTarget(communityID uuid.UUID, targetUserID uuid.UUID) []*model.CommunityMemberRoleChange {
	r.mu.Lock()
	defer r.mu.Unlock()

	changes := make([]*model.CommunityMemberRoleChange, 0)
	for _, change := range r.roleChanges {
		if change.CommunityID != communityID || change.TargetUserID != targetUserID {
			continue
		}
		copy := *change
		changes = append(changes, &copy)
	}
	return changes
}

func (r *postHTTPMemoryRepository) listStatusChangesForTarget(communityID uuid.UUID, targetUserID uuid.UUID) []*model.CommunityMemberStatusChange {
	r.mu.Lock()
	defer r.mu.Unlock()

	changes := make([]*model.CommunityMemberStatusChange, 0)
	for _, change := range r.statusChanges {
		if change.CommunityID != communityID || change.TargetUserID != targetUserID {
			continue
		}
		copy := *change
		changes = append(changes, &copy)
	}
	return changes
}

func (r *postHTTPMemoryRepository) CreatePost(_ context.Context, post *model.Post) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.posts[post.ID] = cloneHTTPPost(post)
	return nil
}

func (r *postHTTPMemoryRepository) CreateStory(_ context.Context, story *model.Story) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.stories[story.ID] = cloneHTTPStory(story)
	return nil
}

func (r *postHTTPMemoryRepository) UpdatePost(_ context.Context, post *model.Post) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing := r.posts[post.ID]
	if existing == nil || existing.DeletedAt != nil {
		return nil
	}
	if post.Revision != existing.Revision {
		return port.ErrPostRevisionConflict
	}

	next := cloneHTTPPost(post)
	next.Revision = existing.Revision + 1
	r.posts[post.ID] = next
	return nil
}

func (r *postHTTPMemoryRepository) ReviewCommunityPost(_ context.Context, post *model.Post, decision *model.PostModerationDecision) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing := r.posts[post.ID]
	if existing == nil || existing.DeletedAt != nil {
		return nil
	}
	if post.Revision != existing.Revision {
		return port.ErrPostRevisionConflict
	}

	next := cloneHTTPPost(post)
	next.Revision = existing.Revision + 1
	r.posts[post.ID] = next
	decisionCopy := *decision
	r.decisions[decision.ID] = &decisionCopy
	return nil
}

func (r *postHTTPMemoryRepository) ListCommunityPostModerationDecisions(_ context.Context, filter model.PostModerationDecisionListFilter) ([]*model.PostModerationDecision, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	items := make([]*model.PostModerationDecision, 0, len(r.decisions))
	for _, decision := range r.decisions {
		if decision.PostID != filter.PostID || decision.CommunityID != filter.CommunityID {
			continue
		}
		copy := *decision
		items = append(items, &copy)
	}
	sort.Slice(items, func(i, j int) bool {
		return items[i].CreatedAt.After(items[j].CreatedAt)
	})
	if filter.Offset >= len(items) {
		return []*model.PostModerationDecision{}, nil
	}
	end := filter.Offset + filter.Limit
	if filter.Limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[filter.Offset:end], nil
}

func (r *postHTTPMemoryRepository) CreatePostReport(_ context.Context, report *model.PostReport, autoHideThreshold int) (*model.PostReportSubmissionResult, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, existing := range r.reports {
		if existing.PostID == report.PostID &&
			existing.ReporterUserID == report.ReporterUserID &&
			existing.Status == enum.PostReportStatusOpen {
			return r.postReportSubmissionResultLocked(existing, autoHideThreshold), nil
		}
	}

	copy := *report
	if copy.CreatedAt.IsZero() {
		copy.CreatedAt = time.Now().UTC()
	}
	if copy.UpdatedAt.IsZero() {
		copy.UpdatedAt = copy.CreatedAt
	}
	r.reports[copy.ID] = &copy

	return r.postReportSubmissionResultLocked(&copy, autoHideThreshold), nil
}

func (r *postHTTPMemoryRepository) postReportSubmissionResultLocked(report *model.PostReport, autoHideThreshold int) *model.PostReportSubmissionResult {
	openCount := 0
	for _, item := range r.reports {
		if item.PostID == report.PostID && item.Status == enum.PostReportStatusOpen {
			openCount++
		}
	}

	post := r.posts[report.PostID]
	autoHidden := false
	if post != nil &&
		autoHideThreshold > 0 &&
		openCount >= autoHideThreshold &&
		post.ModerationStatus != enum.ModerationStatusHidden &&
		post.ModerationStatus != enum.ModerationStatusRejected {
		post.ModerationStatus = enum.ModerationStatusHidden
		post.Revision++
		post.UpdatedAt = time.Now().UTC()
		autoHidden = true
	}

	reportCopy := *report
	var postCopy *model.Post
	if post != nil {
		postCopy = cloneHTTPPost(post)
	}
	return &model.PostReportSubmissionResult{
		Report:           &reportCopy,
		Post:             postCopy,
		OpenReportsCount: openCount,
		AutoHidden:       autoHidden,
	}
}

func (r *postHTTPMemoryRepository) ListCommunityPostReports(_ context.Context, filter model.PostReportListFilter) ([]*model.PostReport, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	items := make([]*model.PostReport, 0, len(r.reports))
	for _, report := range r.reports {
		if filter.CommunityID != uuid.Nil &&
			(report.CommunityID == nil || *report.CommunityID != filter.CommunityID) {
			continue
		}
		if filter.Status != nil && report.Status != *filter.Status {
			continue
		}
		copy := *report
		items = append(items, &copy)
	}
	sort.Slice(items, func(i, j int) bool {
		return items[i].CreatedAt.After(items[j].CreatedAt)
	})
	if filter.Offset >= len(items) {
		return []*model.PostReport{}, nil
	}
	end := filter.Offset + filter.Limit
	if filter.Limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[filter.Offset:end], nil
}

func (r *postHTTPMemoryRepository) GetPostReport(_ context.Context, reportID uuid.UUID) (*model.PostReport, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	report := r.reports[reportID]
	if report == nil {
		return nil, port.ErrPostReportNotFound
	}
	copy := *report
	return &copy, nil
}

func (r *postHTTPMemoryRepository) ResolvePostReport(_ context.Context, resolution *model.PostReportResolution) (*model.PostReport, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	report := r.reports[resolution.ReportID]
	if report == nil ||
		(resolution.CommunityID != uuid.Nil &&
			(report.CommunityID == nil || *report.CommunityID != resolution.CommunityID)) {
		return nil, port.ErrPostReportNotFound
	}
	if report.Status != enum.PostReportStatusOpen {
		return nil, port.ErrPostReportAlreadyResolved
	}
	report.Status = resolution.Status
	report.ResolvedByUserID = &resolution.ResolvedByUserID
	report.ResolutionNote = resolution.ResolutionNote
	report.UpdatedAt = resolution.ResolvedAt
	report.ResolvedAt = &resolution.ResolvedAt

	copy := *report
	return &copy, nil
}

func (r *postHTTPMemoryRepository) SoftDeletePost(_ context.Context, postID uuid.UUID, authorUserID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	post := r.posts[postID]
	if post == nil || post.AuthorUserID != authorUserID {
		return errors.New("not found")
	}
	now := time.Now().UTC()
	post.DeletedAt = &now
	return nil
}

func (r *postHTTPMemoryRepository) GetPostByID(_ context.Context, postID uuid.UUID) (*model.Post, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	return cloneHTTPPost(r.posts[postID]), nil
}

func (r *postHTTPMemoryRepository) mustGet(postID uuid.UUID) *model.Post {
	r.mu.Lock()
	defer r.mu.Unlock()

	return cloneHTTPPost(r.posts[postID])
}

func (r *postHTTPMemoryRepository) mustGetDecisionForPost(postID uuid.UUID) *model.PostModerationDecision {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, decision := range r.decisions {
		if decision.PostID == postID {
			copy := *decision
			return &copy
		}
	}
	return nil
}

func (r *postHTTPMemoryRepository) GetPostBySlug(_ context.Context, slug string) (*model.Post, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, post := range r.posts {
		if post.Slug == slug {
			return cloneHTTPPost(post), nil
		}
	}
	return nil, nil
}

func (r *postHTTPMemoryRepository) ListPosts(_ context.Context, filter model.PostListFilter) ([]*model.Post, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	matches := make([]*model.Post, 0, len(r.posts))
	for _, post := range r.posts {
		if !postMatchesHTTPFilter(post, filter) {
			continue
		}
		matches = append(matches, cloneHTTPPost(post))
	}
	sort.Slice(matches, func(i, j int) bool {
		if filter.Sort == "related" {
			leftScore := postHTTPRelatedScore(matches[i], filter)
			rightScore := postHTTPRelatedScore(matches[j], filter)
			if leftScore != rightScore {
				return leftScore > rightScore
			}
			if matches[i].ViewCount != matches[j].ViewCount {
				return matches[i].ViewCount > matches[j].ViewCount
			}
		}
		return postHTTPComparableTime(matches[i]).After(postHTTPComparableTime(matches[j]))
	})

	if filter.Offset >= len(matches) {
		return []*model.Post{}, nil
	}
	end := filter.Offset + filter.Limit
	if filter.Limit <= 0 || end > len(matches) {
		end = len(matches)
	}
	return matches[filter.Offset:end], nil
}

func (r *postHTTPMemoryRepository) ListFeedPosts(ctx context.Context, filter model.PostListFilter) ([]*model.Post, error) {
	return r.ListPosts(ctx, filter)
}

func (r *postHTTPMemoryRepository) ListStories(_ context.Context, filter model.StoryListFilter) ([]*model.Story, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now().UTC()
	matches := make([]*model.Story, 0, len(r.stories))
	for _, story := range r.stories {
		if story == nil || story.DeletedAt != nil {
			continue
		}
		isExpired := !story.ExpiresAt.After(now)
		if filter.OnlyExpired && !isExpired {
			continue
		}
		if !filter.IncludeExpired && isExpired {
			continue
		}
		if filter.StoryID != nil && story.ID != *filter.StoryID {
			continue
		}
		if filter.AuthorUserID != nil && story.AuthorUserID != *filter.AuthorUserID {
			continue
		}
		matches = append(matches, cloneHTTPStory(story))
	}
	sort.Slice(matches, func(i, j int) bool {
		if filter.ViewerUserID != nil {
			leftSeen := !r.storySeen[matches[i].ID][*filter.ViewerUserID].IsZero()
			rightSeen := !r.storySeen[matches[j].ID][*filter.ViewerUserID].IsZero()
			if leftSeen != rightSeen {
				return !leftSeen && rightSeen
			}
		}
		if !matches[i].CreatedAt.Equal(matches[j].CreatedAt) {
			return matches[i].CreatedAt.After(matches[j].CreatedAt)
		}
		return matches[i].ID.String() > matches[j].ID.String()
	})
	if filter.Offset >= len(matches) {
		return []*model.Story{}, nil
	}
	end := filter.Offset + filter.Limit
	if filter.Limit <= 0 || end > len(matches) {
		end = len(matches)
	}
	return matches[filter.Offset:end], nil
}

func (r *postHTTPMemoryRepository) CreateFeedEvents(_ context.Context, events []model.FeedEvent) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.feedEvents = append(r.feedEvents, events...)
	return nil
}

func (r *postHTTPMemoryRepository) ListFeedUserInterests(_ context.Context, _ model.FeedUserInterestListFilter) ([]model.FeedUserInterest, error) {
	return []model.FeedUserInterest{}, nil
}

func (r *postHTTPMemoryRepository) ListFeedQualityMetrics(_ context.Context, _ model.FeedQualityMetricsFilter) ([]model.FeedQualityMetric, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	return append([]model.FeedQualityMetric(nil), r.feedQualityMetrics...), nil
}

func (r *postHTTPMemoryRepository) CountPosts(_ context.Context, filter model.PostListFilter) (int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	total := 0
	for _, post := range r.posts {
		if postMatchesHTTPFilter(post, filter) {
			total++
		}
	}
	return total, nil
}

func (r *postHTTPMemoryRepository) CountPublishedPostsByAuthorID(_ context.Context, authorUserID uuid.UUID) (int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	total := 0
	for _, post := range r.posts {
		if post.AuthorUserID == authorUserID && post.IsPubliclyVisible() {
			total++
		}
	}
	return total, nil
}

func (r *postHTTPMemoryRepository) CountPostsCreatedByAuthorSince(_ context.Context, authorUserID uuid.UUID, since time.Time) (int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	total := 0
	for _, post := range r.posts {
		if post.AuthorUserID == authorUserID &&
			post.DeletedAt == nil &&
			!post.CreatedAt.Before(since) {
			total++
		}
	}
	return total, nil
}

func (r *postHTTPMemoryRepository) OldestPostCreatedAtByAuthorSince(_ context.Context, authorUserID uuid.UUID, since time.Time) (*time.Time, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	var oldest *time.Time
	for _, post := range r.posts {
		if post.AuthorUserID != authorUserID ||
			post.DeletedAt != nil ||
			post.CreatedAt.Before(since) {
			continue
		}
		createdAt := post.CreatedAt.UTC()
		if oldest == nil || createdAt.Before(*oldest) {
			oldest = &createdAt
		}
	}
	if oldest == nil {
		return nil, nil
	}
	value := *oldest
	return &value, nil
}

func (r *postHTTPMemoryRepository) ListCommunities(_ context.Context, filter model.CommunityListFilter) ([]*model.Community, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	items := make([]*model.Community, 0, len(r.communities))
	for _, community := range r.communities {
		if filter.PublicOnly && !community.IsPubliclyVisible() {
			continue
		}
		items = append(items, cloneHTTPCommunity(community))
	}
	if filter.Offset >= len(items) {
		return []*model.Community{}, nil
	}
	end := filter.Offset + filter.Limit
	if filter.Limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[filter.Offset:end], nil
}

func (r *postHTTPMemoryRepository) CreateCommunity(_ context.Context, community *model.Community) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if community == nil {
		return nil
	}
	copy := cloneHTTPCommunity(community)
	r.communities[copy.ID] = copy
	return nil
}

func (r *postHTTPMemoryRepository) UpdateCommunity(_ context.Context, community *model.Community) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if community == nil {
		return nil
	}
	copy := cloneHTTPCommunity(community)
	r.communities[copy.ID] = copy
	return nil
}

func (r *postHTTPMemoryRepository) GetCommunityByID(_ context.Context, communityID uuid.UUID) (*model.Community, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	return cloneHTTPCommunity(r.communities[communityID]), nil
}

func (r *postHTTPMemoryRepository) GetCommunityBySlug(_ context.Context, slug string) (*model.Community, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	for _, community := range r.communities {
		if community.Slug == slug {
			return cloneHTTPCommunity(community), nil
		}
	}
	return nil, nil
}

func (r *postHTTPMemoryRepository) ListCommunityPostProfiles(_ context.Context, filter model.CommunityPostProfileListFilter) ([]*model.CommunityPostProfile, error) {
	profiles := []*model.CommunityPostProfile{
		postHTTPCommunityPostProfile(enum.PostProfileArticleV1, enum.PostKindArticle, enum.ModerationModePremoderation, enum.ActivityCreationModeDisabled, nil),
		postHTTPCommunityPostProfile(enum.PostProfileQuickPostV1, enum.PostKindQuickPost, enum.ModerationModePublishFirst, enum.ActivityCreationModeDisabled, []string{"body"}),
		postHTTPCommunityPostProfile(enum.PostProfileListingV1, enum.PostKindListing, enum.ModerationModePublishFirstWithRiskHold, enum.ActivityCreationModeDisabled, []string{"title", "body", "location"}),
		postHTTPCommunityPostProfile(enum.PostProfileEventAnnouncementV1, enum.PostKindEventAnnouncement, enum.ModerationModeTrustedPublishElseReview, enum.ActivityCreationModeRequired, []string{"title", "starts_at", "location"}),
		postHTTPCommunityPostProfile(enum.PostProfileQuestionAnswerV1, enum.PostKindQuestionAnswer, enum.ModerationModePublishFirst, enum.ActivityCreationModeDisabled, []string{"question"}),
		postHTTPCommunityPostProfile(enum.PostProfileTripPlanV1, enum.PostKindTripPlan, enum.ModerationModePublishFirstWithRiskHold, enum.ActivityCreationModeOptional, []string{"title", "route", "starts_at", "meeting_point"}),
	}
	items := make([]*model.CommunityPostProfile, 0, len(profiles))
	for _, profile := range profiles {
		if filter.PostKind != "" && string(profile.PostKind) != filter.PostKind {
			continue
		}
		copy := *profile
		copy.SchemaJSON = append(json.RawMessage(nil), profile.SchemaJSON...)
		copy.ValidationJSON = append(json.RawMessage(nil), profile.ValidationJSON...)
		items = append(items, &copy)
	}
	return items, nil
}

func postHTTPCommunityPostProfile(
	key enum.PostProfileKey,
	kind enum.PostKind,
	moderationMode enum.ModerationMode,
	activityMode enum.ActivityCreationMode,
	required []string,
) *model.CommunityPostProfile {
	validationJSON, err := json.Marshal(struct {
		Required []string `json:"required"`
	}{Required: required})
	if err != nil {
		panic(err)
	}
	return &model.CommunityPostProfile{
		Key:                  key,
		Version:              1,
		PostKind:             kind,
		ModerationMode:       moderationMode,
		ActivityCreationMode: activityMode,
		ValidationJSON:       validationJSON,
	}
}

func (r *postHTTPMemoryRepository) ListCommunityBlueprints(_ context.Context, _ model.CommunityBlueprintListFilter) ([]*model.CommunityBlueprint, error) {
	return []*model.CommunityBlueprint{}, nil
}

func (r *postHTTPMemoryRepository) ListCommunityGeoHubs(_ context.Context, _ model.CommunityGeoHubListFilter) ([]*model.CommunityGeoHub, error) {
	return []*model.CommunityGeoHub{}, nil
}

func (r *postHTTPMemoryRepository) ListCommunityInstances(_ context.Context, _ model.CommunityInstanceListFilter) ([]*model.CommunityInstance, error) {
	return []*model.CommunityInstance{}, nil
}

func (r *postHTTPMemoryRepository) MaterializeCommunityInstances(_ context.Context, _ model.CommunityInstanceMaterializationFilter) (*model.CommunityInstanceMaterializationResult, error) {
	return &model.CommunityInstanceMaterializationResult{}, nil
}

func (r *postHTTPMemoryRepository) CreateCommunityReport(_ context.Context, report *model.CommunityReport) (*model.CommunityReportSubmissionResult, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if report == nil || r.communities[report.CommunityID] == nil {
		return nil, nil
	}
	for _, existing := range r.communityReports {
		if existing.CommunityID == report.CommunityID &&
			existing.ReporterUserID == report.ReporterUserID &&
			existing.Status == enum.PostReportStatusOpen {
			copy := *existing
			copy.Reason = report.Reason
			copy.Details = report.Details
			copy.UpdatedAt = time.Now().UTC()
			r.communityReports[existing.ID] = &copy
			return &model.CommunityReportSubmissionResult{
				Report:           &copy,
				OpenReportsCount: r.openCommunityReportsCountLocked(report.CommunityID),
			}, nil
		}
	}
	copy := *report
	if copy.CreatedAt.IsZero() {
		copy.CreatedAt = time.Now().UTC()
	}
	if copy.UpdatedAt.IsZero() {
		copy.UpdatedAt = copy.CreatedAt
	}
	r.communityReports[copy.ID] = &copy
	return &model.CommunityReportSubmissionResult{
		Report:           &copy,
		OpenReportsCount: r.openCommunityReportsCountLocked(copy.CommunityID),
	}, nil
}

func (r *postHTTPMemoryRepository) openCommunityReportsCountLocked(communityID uuid.UUID) int {
	count := 0
	for _, report := range r.communityReports {
		if report.CommunityID == communityID && report.Status == enum.PostReportStatusOpen {
			count++
		}
	}
	return count
}

func (r *postHTTPMemoryRepository) SetCommunityMuted(_ context.Context, communityID uuid.UUID, userID uuid.UUID, muted bool) (*model.CommunityMembership, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.communities[communityID] == nil {
		return nil, nil
	}
	if r.memberships[communityID] == nil {
		r.memberships[communityID] = make(map[uuid.UUID]*model.CommunityMembership)
	}
	current := r.memberships[communityID][userID]
	if current == nil && r.follows[communityID][userID] {
		current = &model.CommunityMembership{
			CommunityID: communityID,
			UserID:      userID,
			Role:        enum.CommunityMembershipRoleMember,
			Status:      enum.CommunityMembershipStatusActive,
			CreatedAt:   time.Now().UTC(),
			UpdatedAt:   time.Now().UTC(),
		}
	}

	nextStatus := enum.CommunityMembershipStatusLeft
	if muted {
		nextStatus = enum.CommunityMembershipStatusMuted
	}
	if current != nil && current.Status == enum.CommunityMembershipStatusBanned {
		nextStatus = enum.CommunityMembershipStatusBanned
	}

	if current == nil {
		if !muted {
			return nil, nil
		}
		current = &model.CommunityMembership{
			CommunityID: communityID,
			UserID:      userID,
			Role:        enum.CommunityMembershipRoleMember,
			Status:      nextStatus,
			CreatedAt:   time.Now().UTC(),
			UpdatedAt:   time.Now().UTC(),
		}
		r.memberships[communityID][userID] = current
		return cloneHTTPMembership(current), nil
	}

	previous := current.Status
	if previous != nextStatus {
		current.Status = nextStatus
		current.UpdatedAt = time.Now().UTC()
		if delta := communityMembershipStatusFollowerDelta(previous, nextStatus); delta != 0 {
			r.communities[communityID].FollowerCount += delta
			if r.communities[communityID].FollowerCount < 0 {
				r.communities[communityID].FollowerCount = 0
			}
		}
		if r.follows[communityID] == nil {
			r.follows[communityID] = make(map[uuid.UUID]bool)
		}
		r.follows[communityID][userID] = nextStatus == enum.CommunityMembershipStatusActive
		r.statusChanges = append(r.statusChanges, &model.CommunityMemberStatusChange{
			ID:             uuid.New(),
			CommunityID:    communityID,
			TargetUserID:   userID,
			ActorUserID:    userID,
			PreviousStatus: previous,
			NextStatus:     nextStatus,
			CreatedAt:      time.Now().UTC(),
		})
	}
	return cloneHTTPMembership(current), nil
}

func (r *postHTTPMemoryRepository) FollowCommunity(_ context.Context, communityID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.communities[communityID] == nil {
		return false, 0, nil
	}
	if r.follows[communityID] == nil {
		r.follows[communityID] = make(map[uuid.UUID]bool)
	}
	if r.follows[communityID][userID] {
		return false, r.communities[communityID].FollowerCount, nil
	}
	r.follows[communityID][userID] = true
	r.communities[communityID].FollowerCount++
	return true, r.communities[communityID].FollowerCount, nil
}

func (r *postHTTPMemoryRepository) UnfollowCommunity(_ context.Context, communityID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.communities[communityID] == nil || !r.follows[communityID][userID] {
		if r.communities[communityID] == nil {
			return false, 0, nil
		}
		return false, r.communities[communityID].FollowerCount, nil
	}
	r.follows[communityID][userID] = false
	if r.communities[communityID].FollowerCount > 0 {
		r.communities[communityID].FollowerCount--
	}
	return true, r.communities[communityID].FollowerCount, nil
}

func (r *postHTTPMemoryRepository) ListFollowedCommunityIDs(_ context.Context, userID uuid.UUID, communityIDs []uuid.UUID) (map[uuid.UUID]bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	result := make(map[uuid.UUID]bool, len(communityIDs))
	for _, communityID := range communityIDs {
		if r.follows[communityID][userID] {
			result[communityID] = true
		}
	}
	return result, nil
}

func (r *postHTTPMemoryRepository) ListUserCommunityIDs(_ context.Context, userID uuid.UUID, limit int, offset int) ([]uuid.UUID, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	result := make([]uuid.UUID, 0)
	for communityID, followers := range r.follows {
		if followers[userID] {
			result = append(result, communityID)
		}
	}
	if offset >= len(result) {
		return []uuid.UUID{}, nil
	}
	end := offset + limit
	if limit <= 0 || end > len(result) {
		end = len(result)
	}
	return result[offset:end], nil
}

func (r *postHTTPMemoryRepository) GetCommunityMembership(_ context.Context, communityID uuid.UUID, userID uuid.UUID) (*model.CommunityMembership, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if membership := r.memberships[communityID][userID]; membership != nil {
		copy := *membership
		return &copy, nil
	}
	if !r.follows[communityID][userID] {
		return nil, nil
	}
	return &model.CommunityMembership{
		CommunityID: communityID,
		UserID:      userID,
		Role:        enum.CommunityMembershipRoleMember,
		Status:      enum.CommunityMembershipStatusActive,
	}, nil
}

func (r *postHTTPMemoryRepository) ListCommunityMemberships(_ context.Context, filter model.CommunityMemberListFilter) ([]*model.CommunityMembership, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	items := make([]*model.CommunityMembership, 0, len(r.memberships[filter.CommunityID]))
	for _, membership := range r.memberships[filter.CommunityID] {
		if filter.Role != nil && membership.Role != *filter.Role {
			continue
		}
		if filter.Status != nil && membership.Status != *filter.Status {
			continue
		}
		copy := *membership
		items = append(items, &copy)
	}
	sort.Slice(items, func(i, j int) bool {
		leftPriority := postHTTPCommunityRolePriority(items[i].Role)
		rightPriority := postHTTPCommunityRolePriority(items[j].Role)
		if leftPriority != rightPriority {
			return leftPriority < rightPriority
		}
		if !items[i].CreatedAt.Equal(items[j].CreatedAt) {
			return items[i].CreatedAt.After(items[j].CreatedAt)
		}
		return items[i].UserID.String() < items[j].UserID.String()
	})
	if filter.Offset >= len(items) {
		return []*model.CommunityMembership{}, nil
	}
	end := filter.Offset + filter.Limit
	if filter.Limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[filter.Offset:end], nil
}

func (r *postHTTPMemoryRepository) ListCommunityMemberRoleChanges(_ context.Context, filter model.CommunityMemberRoleChangeListFilter) ([]*model.CommunityMemberRoleChange, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	items := make([]*model.CommunityMemberRoleChange, 0)
	for _, change := range r.roleChanges {
		if change.CommunityID != filter.CommunityID || change.TargetUserID != filter.TargetUserID {
			continue
		}
		copy := *change
		items = append(items, &copy)
	}
	sort.Slice(items, func(i, j int) bool {
		if !items[i].CreatedAt.Equal(items[j].CreatedAt) {
			return items[i].CreatedAt.After(items[j].CreatedAt)
		}
		return items[i].ID.String() > items[j].ID.String()
	})
	if filter.Offset >= len(items) {
		return []*model.CommunityMemberRoleChange{}, nil
	}
	end := filter.Offset + filter.Limit
	if filter.Limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[filter.Offset:end], nil
}

func (r *postHTTPMemoryRepository) UpdateCommunityMembershipRole(
	_ context.Context,
	communityID uuid.UUID,
	userID uuid.UUID,
	actorUserID uuid.UUID,
	role enum.CommunityMembershipRole,
) (*model.CommunityMembership, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	membership := r.memberships[communityID][userID]
	if membership == nil || membership.Status != enum.CommunityMembershipStatusActive {
		return nil, nil
	}
	previousRole := membership.Role
	copy := *membership
	copy.Role = role
	copy.UpdatedAt = time.Now().UTC()
	r.memberships[communityID][userID] = &copy
	if previousRole != role {
		r.roleChanges = append(r.roleChanges, &model.CommunityMemberRoleChange{
			ID:           uuid.New(),
			CommunityID:  communityID,
			TargetUserID: userID,
			ActorUserID:  actorUserID,
			PreviousRole: previousRole,
			NextRole:     role,
			CreatedAt:    copy.UpdatedAt,
		})
	}
	return &copy, nil
}

func (r *postHTTPMemoryRepository) UpdateCommunityMembershipStatus(
	_ context.Context,
	communityID uuid.UUID,
	userID uuid.UUID,
	actorUserID uuid.UUID,
	status enum.CommunityMembershipStatus,
) (*model.CommunityMembership, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	membership := r.memberships[communityID][userID]
	if membership == nil {
		return nil, nil
	}
	previousStatus := membership.Status
	copy := *membership
	copy.Status = status
	copy.UpdatedAt = time.Now().UTC()
	r.memberships[communityID][userID] = &copy
	if delta := postHTTPMembershipStatusFollowerDelta(previousStatus, status); delta != 0 && r.communities[communityID] != nil {
		r.communities[communityID].FollowerCount += delta
		if r.communities[communityID].FollowerCount < 0 {
			r.communities[communityID].FollowerCount = 0
		}
	}
	if previousStatus != status {
		r.statusChanges = append(r.statusChanges, &model.CommunityMemberStatusChange{
			ID:             uuid.New(),
			CommunityID:    communityID,
			TargetUserID:   userID,
			ActorUserID:    actorUserID,
			PreviousStatus: previousStatus,
			NextStatus:     status,
			CreatedAt:      copy.UpdatedAt,
		})
	}
	return &copy, nil
}

func postHTTPMembershipStatusFollowerDelta(previous enum.CommunityMembershipStatus, next enum.CommunityMembershipStatus) int {
	previousActive := previous == enum.CommunityMembershipStatusActive
	nextActive := next == enum.CommunityMembershipStatusActive
	switch {
	case previousActive && !nextActive:
		return -1
	case !previousActive && nextActive:
		return 1
	default:
		return 0
	}
}

func (r *postHTTPMemoryRepository) HasPostLike(_ context.Context, postID uuid.UUID, userID uuid.UUID) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.likes[postID][userID], nil
}

func (r *postHTTPMemoryRepository) ListPostLikesByUser(_ context.Context, postIDs []uuid.UUID, userID uuid.UUID) (map[uuid.UUID]bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	result := make(map[uuid.UUID]bool, len(postIDs))
	for _, postID := range postIDs {
		if r.likes[postID][userID] {
			result[postID] = true
		}
	}
	return result, nil
}

func (r *postHTTPMemoryRepository) ListFeedSocialEdges(
	_ context.Context,
	viewerUserID uuid.UUID,
	targetUserIDs []uuid.UUID,
) (map[uuid.UUID]model.FeedSocialEdgeSet, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	result := make(map[uuid.UUID]model.FeedSocialEdgeSet, len(targetUserIDs))
	targets := make(map[uuid.UUID]struct{}, len(targetUserIDs))
	for _, targetUserID := range targetUserIDs {
		targets[targetUserID] = struct{}{}
	}
	for _, edge := range r.feedSocialEdges {
		if edge.ViewerUserID != viewerUserID {
			continue
		}
		if _, ok := targets[edge.TargetUserID]; !ok {
			continue
		}
		set := result[edge.TargetUserID]
		switch edge.EdgeType {
		case model.FeedSocialEdgeTypeFriend:
			set.Friend = true
		case model.FeedSocialEdgeTypeFollowing:
			set.Following = true
		}
		result[edge.TargetUserID] = set
	}
	return result, nil
}

func (r *postHTTPMemoryRepository) UpsertFeedSocialEdge(_ context.Context, edge model.FeedSocialEdge) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.feedSocialEdges[feedHTTPSocialEdgeKey(edge.ViewerUserID, edge.TargetUserID, edge.EdgeType)] = edge
	return true, nil
}

func (r *postHTTPMemoryRepository) DeleteFeedSocialEdge(
	_ context.Context,
	viewerUserID uuid.UUID,
	targetUserID uuid.UUID,
	edgeType string,
	_ time.Time,
) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := feedHTTPSocialEdgeKey(viewerUserID, targetUserID, edgeType)
	_, existed := r.feedSocialEdges[key]
	delete(r.feedSocialEdges, key)
	return existed, nil
}

func feedHTTPSocialEdgeKey(viewerUserID uuid.UUID, targetUserID uuid.UUID, edgeType string) uuid.UUID {
	return uuid.NewSHA1(uuid.NameSpaceOID, []byte(viewerUserID.String()+":"+targetUserID.String()+":"+edgeType))
}

func (r *postHTTPMemoryRepository) LikePost(_ context.Context, postID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	return false, 0, nil
}

func (r *postHTTPMemoryRepository) UnlikePost(_ context.Context, postID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	return false, 0, nil
}

func (r *postHTTPMemoryRepository) TrackPostView(_ context.Context, postID uuid.UUID, viewerUserID uuid.UUID) (bool, int, error) {
	return false, 0, nil
}

func (r *postHTTPMemoryRepository) MarkPostSeen(_ context.Context, postID uuid.UUID, viewerUserID uuid.UUID, seenAt time.Time) (time.Time, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.posts[postID] == nil {
		return time.Time{}, errors.New("not found")
	}
	if r.seen[postID] == nil {
		r.seen[postID] = make(map[uuid.UUID]time.Time)
	}
	if existing := r.seen[postID][viewerUserID]; !existing.IsZero() {
		return existing, nil
	}
	if seenAt.IsZero() {
		seenAt = time.Now().UTC().Truncate(time.Second)
	}
	seenAt = seenAt.UTC().Truncate(time.Second)
	r.seen[postID][viewerUserID] = seenAt
	return seenAt, nil
}

func (r *postHTTPMemoryRepository) MarkStorySeen(_ context.Context, storyID uuid.UUID, viewerUserID uuid.UUID, seenAt time.Time) (time.Time, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.stories[storyID] == nil {
		return time.Time{}, errors.New("not found")
	}
	if r.storySeen[storyID] == nil {
		r.storySeen[storyID] = make(map[uuid.UUID]time.Time)
	}
	if existing := r.storySeen[storyID][viewerUserID]; !existing.IsZero() {
		return existing, nil
	}
	if seenAt.IsZero() {
		seenAt = time.Now().UTC().Truncate(time.Second)
	}
	seenAt = seenAt.UTC().Truncate(time.Second)
	r.storySeen[storyID][viewerUserID] = seenAt
	return seenAt, nil
}

func (r *postHTTPMemoryRepository) LikeStory(_ context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	story := r.stories[storyID]
	if story == nil || story.DeletedAt != nil {
		return false, 0, errors.New("not found")
	}
	if r.storyLikes[storyID] == nil {
		r.storyLikes[storyID] = make(map[uuid.UUID]bool)
	}
	if r.storyLikes[storyID][userID] {
		return false, story.LikeCount, nil
	}
	r.storyLikes[storyID][userID] = true
	story.LikeCount++
	return true, story.LikeCount, nil
}

func (r *postHTTPMemoryRepository) ListPostSeenByUser(_ context.Context, postIDs []uuid.UUID, userID uuid.UUID) (map[uuid.UUID]time.Time, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	result := make(map[uuid.UUID]time.Time, len(postIDs))
	for _, postID := range postIDs {
		if seenAt := r.seen[postID][userID]; !seenAt.IsZero() {
			result[postID] = seenAt
		}
	}
	return result, nil
}

func (r *postHTTPMemoryRepository) ListStorySeenByUser(_ context.Context, storyIDs []uuid.UUID, userID uuid.UUID) (map[uuid.UUID]time.Time, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	result := make(map[uuid.UUID]time.Time, len(storyIDs))
	for _, storyID := range storyIDs {
		if seenAt := r.storySeen[storyID][userID]; !seenAt.IsZero() {
			result[storyID] = seenAt
		}
	}
	return result, nil
}

func (r *postHTTPMemoryRepository) IncrementShareCount(_ context.Context, postID uuid.UUID) (int, error) {
	return 0, nil
}

func (r *postHTTPMemoryRepository) CreateComment(_ context.Context, comment *model.PostComment, _ time.Time) error {
	return nil
}

func (r *postHTTPMemoryRepository) UpdateComment(_ context.Context, comment *model.PostComment) error {
	return nil
}

func (r *postHTTPMemoryRepository) GetLatestActiveCommentByAuthor(_ context.Context, postID uuid.UUID, authorUserID uuid.UUID) (*model.PostComment, error) {
	return nil, nil
}

func (r *postHTTPMemoryRepository) GetCommentByID(_ context.Context, postID uuid.UUID, commentID uuid.UUID) (*model.PostComment, error) {
	return nil, nil
}

func (r *postHTTPMemoryRepository) ListComments(_ context.Context, postID uuid.UUID, limit int, offset int) ([]*model.PostComment, error) {
	return []*model.PostComment{}, nil
}

func (r *postHTTPMemoryRepository) DeleteComment(_ context.Context, postID uuid.UUID, commentID uuid.UUID) (bool, error) {
	return false, nil
}

func (r *postHTTPMemoryRepository) LikeComment(_ context.Context, postID uuid.UUID, commentID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	return false, 0, nil
}

func (r *postHTTPMemoryRepository) UnlikeComment(_ context.Context, postID uuid.UUID, commentID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	return false, 0, nil
}

func (r *postHTTPMemoryRepository) HasCommentLike(_ context.Context, commentID uuid.UUID, userID uuid.UUID) (bool, error) {
	return false, nil
}

func postMatchesHTTPFilter(post *model.Post, filter model.PostListFilter) bool {
	if post == nil {
		return false
	}
	if filter.OnlyPublished && !post.IsPubliclyVisible() {
		return false
	}
	if !filter.IncludeDeleted && post.DeletedAt != nil {
		return false
	}
	if filter.ExcludePostID != nil && post.ID == *filter.ExcludePostID {
		return false
	}
	if filter.AuthorUserID != nil && post.AuthorUserID != *filter.AuthorUserID {
		return false
	}
	if len(filter.CommunityIDs) > 0 {
		if post.CommunityID == nil {
			return false
		}
		matched := false
		for _, communityID := range filter.CommunityIDs {
			if *post.CommunityID == communityID {
				matched = true
				break
			}
		}
		if !matched {
			return false
		}
	}
	if !filter.IncludeDrafts && post.Status == enum.PostStatusDraft {
		return false
	}
	if filter.Status != nil && post.Status != *filter.Status {
		return false
	}
	if len(filter.ModerationStatuses) > 0 {
		matched := false
		for _, status := range filter.ModerationStatuses {
			if post.ModerationStatus == status {
				matched = true
				break
			}
		}
		if !matched {
			return false
		}
	}
	if filter.ArchivedOnly && post.ArchivedAt == nil {
		return false
	}
	if filter.ExcludeArchived && post.ArchivedAt != nil {
		return false
	}
	if len(filter.Formats) > 0 {
		matched := false
		for _, format := range filter.Formats {
			if post.Format == format {
				matched = true
				break
			}
		}
		if !matched {
			return false
		}
	}
	if len(filter.Categories) > 0 {
		matched := false
		for _, category := range filter.Categories {
			if post.Category == category {
				matched = true
				break
			}
		}
		if !matched {
			return false
		}
	}
	if value := strings.ToUpper(strings.TrimSpace(filter.PlaceCountryCode)); value != "" &&
		(post.PlaceCountryCode == nil || strings.ToUpper(strings.TrimSpace(*post.PlaceCountryCode)) != value) {
		return false
	}
	if value := strings.TrimSpace(filter.PlaceCityID); value != "" &&
		(post.PlaceCityID == nil || strings.TrimSpace(*post.PlaceCityID) != value) {
		return false
	}
	return true
}

func postHTTPRelatedScore(post *model.Post, filter model.PostListFilter) int {
	if post == nil {
		return 0
	}
	score := 0
	if value := strings.TrimSpace(filter.RelatedToCityID); value != "" &&
		post.PlaceCityID != nil &&
		strings.TrimSpace(*post.PlaceCityID) == value {
		score += 80
	}
	if value := strings.ToUpper(strings.TrimSpace(filter.RelatedToCountry)); value != "" &&
		post.PlaceCountryCode != nil &&
		strings.ToUpper(strings.TrimSpace(*post.PlaceCountryCode)) == value {
		score += 36
	}
	if filter.RelatedToCategory != nil && post.Category == *filter.RelatedToCategory {
		score += 32
	}
	if filter.RelatedToFormat != nil && post.Format == *filter.RelatedToFormat {
		score += 24
	}
	if filter.RelatedToAuthor != nil && post.AuthorUserID == *filter.RelatedToAuthor {
		score += 12
	}
	if postHTTPHasRelatedTag(post.Tags, filter.RelatedToTags) {
		score += 18
	}
	return score
}

func postHTTPHasRelatedTag(postTags []string, relatedTags []string) bool {
	if len(postTags) == 0 || len(relatedTags) == 0 {
		return false
	}
	seen := make(map[string]struct{}, len(postTags))
	for _, tag := range postTags {
		normalized := strings.ToLower(strings.TrimSpace(tag))
		if normalized != "" {
			seen[normalized] = struct{}{}
		}
	}
	for _, tag := range relatedTags {
		if _, ok := seen[strings.ToLower(strings.TrimSpace(tag))]; ok {
			return true
		}
	}
	return false
}

func postHTTPComparableTime(post *model.Post) time.Time {
	if post == nil {
		return time.Time{}
	}
	if post.PublishedAt != nil {
		return *post.PublishedAt
	}
	return post.CreatedAt
}

func cloneHTTPPost(post *model.Post) *model.Post {
	if post == nil {
		return nil
	}
	copy := *post
	if post.ContentBlocks != nil {
		copy.ContentBlocks = append([]byte(nil), post.ContentBlocks...)
	}
	if post.Tags != nil {
		copy.Tags = append([]string(nil), post.Tags...)
	}
	if post.Media != nil {
		copy.Media = append([]model.PostMedia(nil), post.Media...)
	}
	return &copy
}

func cloneHTTPStory(story *model.Story) *model.Story {
	if story == nil {
		return nil
	}
	copy := *story
	return &copy
}

func cloneHTTPCommunity(community *model.Community) *model.Community {
	if community == nil {
		return nil
	}
	copy := *community
	copy.Rules = append([]string(nil), community.Rules...)
	copy.TitleI18n = cloneHTTPStringMap(community.TitleI18n)
	copy.DescriptionI18n = cloneHTTPStringMap(community.DescriptionI18n)
	copy.RulesI18n = cloneHTTPStringSliceMap(community.RulesI18n)
	return &copy
}

func cloneHTTPStringMap(input map[string]string) map[string]string {
	if input == nil {
		return nil
	}
	out := make(map[string]string, len(input))
	for key, value := range input {
		out[key] = value
	}
	return out
}

func cloneHTTPStringSliceMap(input map[string][]string) map[string][]string {
	if input == nil {
		return nil
	}
	out := make(map[string][]string, len(input))
	for key, values := range input {
		out[key] = append([]string(nil), values...)
	}
	return out
}

func cloneHTTPMembership(membership *model.CommunityMembership) *model.CommunityMembership {
	if membership == nil {
		return nil
	}
	copy := *membership
	return &copy
}

func communityMembershipStatusFollowerDelta(previous enum.CommunityMembershipStatus, next enum.CommunityMembershipStatus) int {
	previousActive := previous == enum.CommunityMembershipStatusActive
	nextActive := next == enum.CommunityMembershipStatusActive
	switch {
	case previousActive && !nextActive:
		return -1
	case !previousActive && nextActive:
		return 1
	default:
		return 0
	}
}

func postHTTPCommunityRolePriority(role enum.CommunityMembershipRole) int {
	switch role {
	case enum.CommunityMembershipRoleAdmin:
		return 0
	case enum.CommunityMembershipRoleModerator:
		return 1
	case enum.CommunityMembershipRoleTrustedMember:
		return 2
	default:
		return 3
	}
}
