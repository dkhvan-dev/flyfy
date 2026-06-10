package http

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/stories-service/internal/app"
	"kz/inflap/backend/services/stories-service/internal/domain/enum"
	"kz/inflap/backend/services/stories-service/internal/domain/model"
	"kz/inflap/backend/services/stories-service/internal/domain/port"
)

func TestCreateStoryRequiresAuthentication(t *testing.T) {
	h := newStoryHTTPTestHarness(t)

	rec := h.doJSON(http.MethodPost, "/v1/stories", "", map[string]any{
		"title": "Draft",
	})

	assertErrorResponse(t, rec, http.StatusUnauthorized, map[string]string{
		"code": "missing_authenticated_subject",
		"kind": "business",
	})
}

func TestCreateDraftAcceptsStructuredContentAndReturnsContentEngineFields(t *testing.T) {
	h := newStoryHTTPTestHarness(t)

	rec := h.doJSON(http.MethodPost, "/v1/stories", storyHTTPSubjectOwner, map[string]any{
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

func TestCreateDraftLogsSafeStructuredCounterWithoutContent(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	logs := captureStoryHTTPLogs(t)

	rec := h.doJSON(http.MethodPost, "/v1/stories", storyHTTPSubjectOwner, map[string]any{
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
	if !containsAny(output, `"metric":"stories_draft_created_total"`) {
		t.Fatalf("logs = %s, want draft created counter", output)
	}
	if !containsAny(output, `"request_id":"req-test"`) {
		t.Fatalf("logs = %s, want request id", output)
	}
	if containsAny(output, "secret draft body", "contentBlocks", "content_plain_text", "plainText") {
		t.Fatalf("draft log leaked content payload: %s", output)
	}
}

func TestCreateStoryRejectsClientArchivedStatus(t *testing.T) {
	h := newStoryHTTPTestHarness(t)

	rec := h.doJSON(http.MethodPost, "/v1/stories", storyHTTPSubjectOwner, map[string]any{
		"title":  "Archived by client",
		"status": "ARCHIVED",
	})

	assertErrorResponse(t, rec, http.StatusBadRequest, map[string]string{
		"code": "invalid_story_status",
		"kind": "business",
	})
}

func TestPublishStoryReturnsFieldErrorsForValidation(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	storyID := uuid.New()
	h.seedStory(&model.Story{
		ID:               storyID,
		AuthorUserID:     h.ownerID,
		Status:           enum.StoryStatusDraft,
		ModerationStatus: enum.ModerationStatusNotRequired,
		Revision:         1,
	})

	rec := h.doJSON(http.MethodPost, "/v1/stories/"+storyID.String()+"/publish", storyHTTPSubjectOwner, map[string]any{
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
	if body.Code != "story_validation_failed" || body.Kind != "business" {
		t.Fatalf("error code/kind = %s/%s, want story_validation_failed/business", body.Code, body.Kind)
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
	h := newStoryHTTPTestHarness(t)
	logs := captureStoryHTTPLogs(t)
	storyID := uuid.New()
	h.seedStory(&model.Story{
		ID:               storyID,
		AuthorUserID:     h.ownerID,
		Status:           enum.StoryStatusDraft,
		ModerationStatus: enum.ModerationStatusNotRequired,
		Revision:         1,
	})

	rec := h.doJSON(http.MethodPost, "/v1/stories/"+storyID.String()+"/publish", storyHTTPSubjectOwner, map[string]any{
		"revision": 1,
	})

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusBadRequest, rec.Body.String())
	}

	output := logs.String()
	for _, want := range []string{
		`"metric":"stories_publish_validation_failure_total"`,
		`"metric":"stories_media_validation_failure_total"`,
		`"field":"title"`,
		`"field":"coverFileId"`,
		`"field":"content"`,
		`"request_id":"req-test"`,
		`"story_id":"` + storyID.String() + `"`,
	} {
		if !strings.Contains(output, want) {
			t.Fatalf("logs = %s, want %s", output, want)
		}
	}
	if containsAny(output, "contentBlocks", "blocks", "text", "content_plain_text", "plainText") {
		t.Fatalf("publish validation log leaked content payload: %s", output)
	}
}

func TestListStoriesReturnsPaginationMetadataAndTotal(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	h.seedStory(&model.Story{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "One", Status: enum.StoryStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})
	h.seedStory(&model.Story{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Two", Status: enum.StoryStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})

	rec := h.doJSON(http.MethodGet, "/v1/stories?limit=1&offset=0", "", nil)

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

func TestListStoriesFiltersByMaterialFormat(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	h.seedStory(&model.Story{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Guide", Format: enum.StoryFormatGuide, Status: enum.StoryStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})
	h.seedStory(&model.Story{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Article", Format: enum.StoryFormatArticle, Status: enum.StoryStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})

	rec := h.doJSON(http.MethodGet, "/v1/stories?format=GUIDE", "", nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var body struct {
		Items []map[string]any `json:"items"`
		Total int              `json:"total"`
	}
	decodeJSONResponse(t, rec, &body)
	if len(body.Items) != 1 || body.Total != 1 {
		t.Fatalf("filtered response = %+v, want one GUIDE story", body)
	}
	if body.Items[0]["format"] != "GUIDE" {
		t.Fatalf("format = %#v, want GUIDE", body.Items[0]["format"])
	}
}

func TestListMyStoriesFiltersArchivedStatus(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	h.seedStory(&model.Story{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Draft", Status: enum.StoryStatusDraft, ModerationStatus: enum.ModerationStatusNotRequired, Revision: 1})
	archivedAt := time.Now().UTC()
	archivedID := uuid.New()
	h.seedStory(&model.Story{ID: archivedID, AuthorUserID: h.ownerID, Title: "Archived", Status: enum.StoryStatusPublished, ModerationStatus: enum.ModerationStatusApproved, ArchivedAt: &archivedAt, Revision: 1})

	rec := h.doJSON(http.MethodGet, "/v1/stories/mine?status=ARCHIVED", storyHTTPSubjectOwner, nil)

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
		t.Fatalf("archived list response = %+v, want only archived story %s", body, archivedID)
	}
	if body.Items[0].Status != "ARCHIVED" {
		t.Fatalf("archived story status = %q, want ARCHIVED", body.Items[0].Status)
	}
}

func TestListMyStoriesPublishedFilterExcludesArchivedStories(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	activeID := uuid.New()
	h.seedStory(&model.Story{ID: activeID, AuthorUserID: h.ownerID, Title: "Active", Status: enum.StoryStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})
	archivedAt := time.Now().UTC()
	h.seedStory(&model.Story{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Archived", Status: enum.StoryStatusPublished, ModerationStatus: enum.ModerationStatusApproved, ArchivedAt: &archivedAt, Revision: 1})

	rec := h.doJSON(http.MethodGet, "/v1/stories/mine?status=PUBLISHED", storyHTTPSubjectOwner, nil)

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
		t.Fatalf("published owner list = %+v, want only active story %s", body, activeID)
	}
}

func TestListMyStoriesDefaultExcludesArchivedFromItemsTotalAndHasMore(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	firstID := uuid.New()
	secondID := uuid.New()
	h.seedStory(&model.Story{ID: firstID, AuthorUserID: h.ownerID, Title: "First active", Status: enum.StoryStatusPublished, ModerationStatus: enum.ModerationStatusApproved, Revision: 1})
	h.seedStory(&model.Story{ID: secondID, AuthorUserID: h.ownerID, Title: "Second active", Status: enum.StoryStatusDraft, ModerationStatus: enum.ModerationStatusNotRequired, Revision: 1})
	archivedAt := time.Now().UTC()
	h.seedStory(&model.Story{ID: uuid.New(), AuthorUserID: h.ownerID, Title: "Archived", Status: enum.StoryStatusPublished, ModerationStatus: enum.ModerationStatusApproved, ArchivedAt: &archivedAt, Revision: 1})

	rec := h.doJSON(http.MethodGet, "/v1/stories/mine?limit=2&offset=0", storyHTTPSubjectOwner, nil)

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

func TestArchiveStorySetsArchivedAt(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	storyID := h.mustCreatePublishableDraft(t)

	rec := h.doJSON(http.MethodPost, "/v1/stories/"+storyID.String()+"/archive", storyHTTPSubjectOwner, map[string]any{
		"revision": 1,
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
	if body.ID != storyID.String() || body.ArchivedAt == nil || body.Revision != 2 {
		t.Fatalf("archive response = %+v, want archived story revision 2", body)
	}
	if body.Status != "ARCHIVED" {
		t.Fatalf("archive response status = %q, want ARCHIVED", body.Status)
	}
}

func TestAutosaveStoryRequiresRevisionAndSetsLastAutosavedAt(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	storyID := h.mustCreateDraft(t, storyHTTPSubjectOwner, "Autosave me")

	rec := h.doJSON(http.MethodPost, "/v1/stories/"+storyID.String()+"/autosave", storyHTTPSubjectOwner, map[string]any{
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
	h := newStoryHTTPTestHarness(t)
	storyID := h.mustCreateDraft(t, storyHTTPSubjectOwner, "Autosave logging")
	logs := captureStoryHTTPLogs(t)

	successRec := h.doJSON(http.MethodPost, "/v1/stories/"+storyID.String()+"/autosave", storyHTTPSubjectOwner, map[string]any{
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

	failureRec := h.doJSON(http.MethodPost, "/v1/stories/"+storyID.String()+"/autosave", storyHTTPSubjectOwner, map[string]any{
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
		`"metric":"stories_autosave_success_total"`,
		`"metric":"stories_autosave_failure_total"`,
		`"metric":"stories_revision_conflict_total"`,
		`"operation":"autosave"`,
		`"request_id":"req-test"`,
		`"story_id":"` + storyID.String() + `"`,
	} {
		if !strings.Contains(output, want) {
			t.Fatalf("logs = %s, want %s", output, want)
		}
	}
	if containsAny(output, "autosave secret body", "stale autosave body", "contentBlocks", "content_plain_text", "plainText") {
		t.Fatalf("autosave log leaked content payload: %s", output)
	}
}

func TestPatchStoryPreservesOmittedFields(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	storyID := h.mustCreatePublishableDraft(t)
	original := h.repo.mustGet(storyID)

	rec := h.doJSON(http.MethodPatch, "/v1/stories/"+storyID.String(), storyHTTPSubjectOwner, map[string]any{
		"revision": 1,
		"title":    "Retitled",
	})

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	updated := h.repo.mustGet(storyID)
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

func TestPatchStoryRejectsClientArchivedStatus(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	storyID := h.mustCreateDraft(t, storyHTTPSubjectOwner, "Patch archived")

	rec := h.doJSON(http.MethodPatch, "/v1/stories/"+storyID.String(), storyHTTPSubjectOwner, map[string]any{
		"revision": 1,
		"status":   "ARCHIVED",
	})

	assertErrorResponse(t, rec, http.StatusBadRequest, map[string]string{
		"code": "invalid_story_status",
		"kind": "business",
	})
}

func TestAutosaveStoryPreservesOmittedFieldsAndModeration(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	storyID := h.mustCreatePublishableDraft(t)
	story := h.repo.mustGet(storyID)
	story.ModerationStatus = enum.ModerationStatusRejected
	h.seedStory(story)

	rec := h.doJSON(http.MethodPost, "/v1/stories/"+storyID.String()+"/autosave", storyHTTPSubjectOwner, map[string]any{
		"revision": 1,
		"title":    "Autosaved title",
	})

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	updated := h.repo.mustGet(storyID)
	if updated.ModerationStatus != enum.ModerationStatusRejected {
		t.Fatalf("ModerationStatus = %q, want REJECTED", updated.ModerationStatus)
	}
	if updated.Category != story.Category ||
		updated.CoverFileID == nil ||
		*updated.CoverFileID != *story.CoverFileID ||
		updated.PlaceName == nil ||
		*updated.PlaceName != *story.PlaceName ||
		string(updated.ContentBlocks) != string(story.ContentBlocks) ||
		updated.Status != story.Status ||
		strings.Join(updated.Tags, ",") != strings.Join(story.Tags, ",") {
		t.Fatalf("autosave did not preserve omitted fields\noriginal=%+v\nupdated=%+v", story, updated)
	}
}

func TestAutosaveStoryRejectsClientArchivedStatus(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	storyID := h.mustCreateDraft(t, storyHTTPSubjectOwner, "Autosave archived")

	rec := h.doJSON(http.MethodPost, "/v1/stories/"+storyID.String()+"/autosave", storyHTTPSubjectOwner, map[string]any{
		"revision": 1,
		"status":   "ARCHIVED",
	})

	assertErrorResponse(t, rec, http.StatusBadRequest, map[string]string{
		"code": "invalid_story_status",
		"kind": "business",
	})
}

func TestUpdateStoryMapsRevisionConflictToConflict(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	storyID := h.mustCreateDraft(t, storyHTTPSubjectOwner, "Original")

	rec := h.doJSON(http.MethodPatch, "/v1/stories/"+storyID.String(), storyHTTPSubjectOwner, map[string]any{
		"revision": 99,
		"title":    "Stale update",
	})

	assertErrorResponse(t, rec, http.StatusConflict, map[string]string{
		"code": "story_revision_conflict",
		"kind": "business",
	})
}

func TestPublicStoryDetailHidesDraftsFromNonOwners(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	storyID := h.mustCreateDraft(t, storyHTTPSubjectOwner, "Private draft")

	publicRec := h.doJSON(http.MethodGet, "/v1/stories/"+storyID.String(), storyHTTPSubjectOther, nil)
	assertErrorResponse(t, publicRec, http.StatusNotFound, map[string]string{
		"code": "story_not_found",
		"kind": "business",
	})

	ownerRec := h.doJSON(http.MethodGet, "/v1/stories/"+storyID.String(), storyHTTPSubjectOwner, nil)
	if ownerRec.Code != http.StatusOK {
		t.Fatalf("owner status = %d, want %d; body: %s", ownerRec.Code, http.StatusOK, ownerRec.Body.String())
	}
}

func TestPublicStoryDetailRanksRelatedStoriesByRelevance(t *testing.T) {
	h := newStoryHTTPTestHarness(t)
	authorID := h.ownerID
	otherAuthorID := h.otherID
	now := time.Now().UTC()

	targetID := uuid.New()
	h.seedStory(&model.Story{
		ID:               targetID,
		Slug:             "almaty-food-guide",
		AuthorUserID:     authorID,
		Title:            "Almaty Food Guide",
		Format:           enum.StoryFormatGuide,
		Category:         enum.StoryCategoryGuide,
		Status:           enum.StoryStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		PlaceName:        storyHTTPStringPtr("Almaty"),
		PlaceCountryCode: storyHTTPStringPtr("KZ"),
		PlaceCityID:      storyHTTPStringPtr("almaty"),
		Tags:             []string{"food", "almaty"},
		ViewCount:        20,
		PublishedAt:      &now,
		CreatedAt:        now,
		Revision:         1,
	})

	h.seedStory(&model.Story{
		ID:               uuid.New(),
		Slug:             "almaty-photo-walk",
		AuthorUserID:     otherAuthorID,
		Title:            "Almaty Photo Walk",
		Format:           enum.StoryFormatPhotoEssay,
		Category:         enum.StoryCategoryPhotoEssay,
		Status:           enum.StoryStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		PlaceName:        storyHTTPStringPtr("Almaty"),
		PlaceCountryCode: storyHTTPStringPtr("KZ"),
		PlaceCityID:      storyHTTPStringPtr("almaty"),
		Tags:             []string{"mountains"},
		ViewCount:        1,
		PublishedAt:      storyHTTPTimePtr(now.Add(-72 * time.Hour)),
		CreatedAt:        now.Add(-72 * time.Hour),
		Revision:         1,
	})
	h.seedStory(&model.Story{
		ID:               uuid.New(),
		Slug:             "astana-food-guide",
		AuthorUserID:     otherAuthorID,
		Title:            "Astana Food Guide",
		Format:           enum.StoryFormatGuide,
		Category:         enum.StoryCategoryGuide,
		Status:           enum.StoryStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		PlaceName:        storyHTTPStringPtr("Astana"),
		PlaceCountryCode: storyHTTPStringPtr("KZ"),
		PlaceCityID:      storyHTTPStringPtr("astana"),
		Tags:             []string{"food"},
		ViewCount:        5,
		PublishedAt:      storyHTTPTimePtr(now.Add(-48 * time.Hour)),
		CreatedAt:        now.Add(-48 * time.Hour),
		Revision:         1,
	})
	h.seedStory(&model.Story{
		ID:               uuid.New(),
		Slug:             "popular-unrelated",
		AuthorUserID:     otherAuthorID,
		Title:            "Popular Unrelated",
		Format:           enum.StoryFormatArticle,
		Category:         enum.StoryCategoryJournal,
		Status:           enum.StoryStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		PlaceName:        storyHTTPStringPtr("Berlin"),
		PlaceCountryCode: storyHTTPStringPtr("DE"),
		PlaceCityID:      storyHTTPStringPtr("berlin"),
		Tags:             []string{"nightlife"},
		ViewCount:        10000,
		PublishedAt:      storyHTTPTimePtr(now.Add(-24 * time.Hour)),
		CreatedAt:        now.Add(-24 * time.Hour),
		Revision:         1,
	})

	rec := h.doJSON(http.MethodGet, "/v1/public/stories/almaty-food-guide", "", nil)
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
		t.Fatalf("related = %+v, want at least two relevant stories", body.Related)
	}
	if body.Related[0].Slug != "almaty-photo-walk" {
		t.Fatalf("first related slug = %q, want same-city story", body.Related[0].Slug)
	}
	if body.Related[1].Slug != "astana-food-guide" {
		t.Fatalf("second related slug = %q, want same-theme tagged story", body.Related[1].Slug)
	}
	for _, related := range body.Related {
		if related.Slug == "almaty-food-guide" {
			t.Fatalf("related includes the current story: %+v", body.Related)
		}
	}
}

const (
	storyHTTPSubjectOwner = "owner-subject"
	storyHTTPSubjectOther = "other-subject"
)

type storyHTTPTestHarness struct {
	mux     *http.ServeMux
	repo    *storyHTTPMemoryRepository
	ownerID uuid.UUID
	otherID uuid.UUID
}

func newStoryHTTPTestHarness(t *testing.T) *storyHTTPTestHarness {
	t.Helper()

	ownerID := uuid.New()
	otherID := uuid.New()
	repo := newStoryHTTPMemoryRepository()
	users := &storyHTTPUserClient{
		subjects: map[string]uuid.UUID{
			storyHTTPSubjectOwner: ownerID,
			storyHTTPSubjectOther: otherID,
		},
	}

	mux := http.NewServeMux()
	NewHandler(app.NewStoryUseCase(repo, users, "https://stories.test")).Register(mux)

	return &storyHTTPTestHarness{
		mux:     mux,
		repo:    repo,
		ownerID: ownerID,
		otherID: otherID,
	}
}

func (h *storyHTTPTestHarness) doJSON(method string, path string, subject string, payload any) *httptest.ResponseRecorder {
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

func captureStoryHTTPLogs(t *testing.T) *bytes.Buffer {
	t.Helper()

	var buf bytes.Buffer
	previous := log.Logger
	log.Logger = zerolog.New(&buf)
	t.Cleanup(func() {
		log.Logger = previous
	})
	return &buf
}

func (h *storyHTTPTestHarness) mustCreateDraft(t *testing.T, subject string, title string) uuid.UUID {
	t.Helper()
	rec := h.doJSON(http.MethodPost, "/v1/stories", subject, map[string]any{"title": title})
	if rec.Code != http.StatusCreated {
		t.Fatalf("create draft status = %d, want %d; body: %s", rec.Code, http.StatusCreated, rec.Body.String())
	}
	var body struct {
		ID string `json:"id"`
	}
	decodeJSONResponse(t, rec, &body)
	storyID, err := uuid.Parse(body.ID)
	if err != nil {
		t.Fatalf("parse created story id %q: %v", body.ID, err)
	}
	return storyID
}

func (h *storyHTTPTestHarness) mustCreatePublishableDraft(t *testing.T) uuid.UUID {
	t.Helper()
	coverID := uuid.New()
	placeName := "Almaty"
	rec := h.doJSON(http.MethodPost, "/v1/stories", storyHTTPSubjectOwner, map[string]any{
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
	storyID, err := uuid.Parse(body.ID)
	if err != nil {
		t.Fatalf("parse created story id %q: %v", body.ID, err)
	}
	return storyID
}

func (h *storyHTTPTestHarness) seedStory(story *model.Story) {
	h.repo.seed(story)
}

func decodeJSONResponse(t *testing.T, rec *httptest.ResponseRecorder, target any) {
	t.Helper()
	if err := json.Unmarshal(rec.Body.Bytes(), target); err != nil {
		t.Fatalf("decode response: %v; body: %s", err, rec.Body.String())
	}
}

func storyHTTPStringPtr(value string) *string {
	return &value
}

func storyHTTPTimePtr(value time.Time) *time.Time {
	return &value
}

type storyHTTPUserClient struct {
	subjects map[string]uuid.UUID
}

func (c *storyHTTPUserClient) ResolveUserIDBySubject(_ context.Context, subject string) (uuid.UUID, error) {
	userID, ok := c.subjects[subject]
	if !ok {
		return uuid.Nil, app.ErrUserNotFound
	}
	return userID, nil
}

func (c *storyHTTPUserClient) GetPublicUserProfiles(
	_ context.Context,
	userIDs []uuid.UUID,
) (map[uuid.UUID]app.PublicUserProfile, error) {
	profiles := make(map[uuid.UUID]app.PublicUserProfile, len(userIDs))
	for _, userID := range userIDs {
		profiles[userID] = app.PublicUserProfile{UserID: userID, Locale: "en", Timezone: "Asia/Almaty"}
	}
	return profiles, nil
}

type storyHTTPMemoryRepository struct {
	mu      sync.Mutex
	stories map[uuid.UUID]*model.Story
	likes   map[uuid.UUID]map[uuid.UUID]bool
}

func newStoryHTTPMemoryRepository() *storyHTTPMemoryRepository {
	return &storyHTTPMemoryRepository{
		stories: make(map[uuid.UUID]*model.Story),
		likes:   make(map[uuid.UUID]map[uuid.UUID]bool),
	}
}

func (r *storyHTTPMemoryRepository) seed(story *model.Story) {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now().UTC()
	copy := cloneHTTPStory(story)
	if copy.Slug == "" {
		copy.Slug = strings.ToLower(strings.ReplaceAll(copy.Title, " ", "-")) + "-" + copy.ID.String()[:8]
	}
	if copy.CreatedAt.IsZero() {
		copy.CreatedAt = now
	}
	if copy.UpdatedAt.IsZero() {
		copy.UpdatedAt = now
	}
	if copy.PublishedAt == nil && copy.Status == enum.StoryStatusPublished {
		copy.PublishedAt = &now
	}
	r.stories[copy.ID] = copy
}

func (r *storyHTTPMemoryRepository) CreateStory(_ context.Context, story *model.Story) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.stories[story.ID] = cloneHTTPStory(story)
	return nil
}

func (r *storyHTTPMemoryRepository) UpdateStory(_ context.Context, story *model.Story) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing := r.stories[story.ID]
	if existing == nil || existing.DeletedAt != nil {
		return nil
	}
	if story.Revision != existing.Revision {
		return port.ErrStoryRevisionConflict
	}

	next := cloneHTTPStory(story)
	next.Revision = existing.Revision + 1
	r.stories[story.ID] = next
	return nil
}

func (r *storyHTTPMemoryRepository) SoftDeleteStory(_ context.Context, storyID uuid.UUID, authorUserID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	story := r.stories[storyID]
	if story == nil || story.AuthorUserID != authorUserID {
		return errors.New("not found")
	}
	now := time.Now().UTC()
	story.DeletedAt = &now
	return nil
}

func (r *storyHTTPMemoryRepository) GetStoryByID(_ context.Context, storyID uuid.UUID) (*model.Story, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	return cloneHTTPStory(r.stories[storyID]), nil
}

func (r *storyHTTPMemoryRepository) mustGet(storyID uuid.UUID) *model.Story {
	r.mu.Lock()
	defer r.mu.Unlock()

	return cloneHTTPStory(r.stories[storyID])
}

func (r *storyHTTPMemoryRepository) GetStoryBySlug(_ context.Context, slug string) (*model.Story, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, story := range r.stories {
		if story.Slug == slug {
			return cloneHTTPStory(story), nil
		}
	}
	return nil, nil
}

func (r *storyHTTPMemoryRepository) ListStories(_ context.Context, filter model.StoryListFilter) ([]*model.Story, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	matches := make([]*model.Story, 0, len(r.stories))
	for _, story := range r.stories {
		if !storyMatchesHTTPFilter(story, filter) {
			continue
		}
		matches = append(matches, cloneHTTPStory(story))
	}
	sort.Slice(matches, func(i, j int) bool {
		if filter.Sort == "related" {
			leftScore := storyHTTPRelatedScore(matches[i], filter)
			rightScore := storyHTTPRelatedScore(matches[j], filter)
			if leftScore != rightScore {
				return leftScore > rightScore
			}
			if matches[i].ViewCount != matches[j].ViewCount {
				return matches[i].ViewCount > matches[j].ViewCount
			}
		}
		return storyHTTPComparableTime(matches[i]).After(storyHTTPComparableTime(matches[j]))
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

func (r *storyHTTPMemoryRepository) CountStories(_ context.Context, filter model.StoryListFilter) (int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	total := 0
	for _, story := range r.stories {
		if storyMatchesHTTPFilter(story, filter) {
			total++
		}
	}
	return total, nil
}

func (r *storyHTTPMemoryRepository) CountPublishedStoriesByAuthorID(_ context.Context, authorUserID uuid.UUID) (int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	total := 0
	for _, story := range r.stories {
		if story.AuthorUserID == authorUserID && story.IsPubliclyVisible() {
			total++
		}
	}
	return total, nil
}

func (r *storyHTTPMemoryRepository) HasStoryLike(_ context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.likes[storyID][userID], nil
}

func (r *storyHTTPMemoryRepository) LikeStory(_ context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	return false, 0, nil
}

func (r *storyHTTPMemoryRepository) UnlikeStory(_ context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	return false, 0, nil
}

func (r *storyHTTPMemoryRepository) TrackStoryView(_ context.Context, storyID uuid.UUID, viewerUserID uuid.UUID) (bool, int, error) {
	return false, 0, nil
}

func (r *storyHTTPMemoryRepository) IncrementShareCount(_ context.Context, storyID uuid.UUID) (int, error) {
	return 0, nil
}

func (r *storyHTTPMemoryRepository) CreateComment(_ context.Context, comment *model.StoryComment) error {
	return nil
}

func (r *storyHTTPMemoryRepository) UpdateComment(_ context.Context, comment *model.StoryComment) error {
	return nil
}

func (r *storyHTTPMemoryRepository) GetLatestActiveCommentByAuthor(_ context.Context, storyID uuid.UUID, authorUserID uuid.UUID) (*model.StoryComment, error) {
	return nil, nil
}

func (r *storyHTTPMemoryRepository) GetCommentByID(_ context.Context, storyID uuid.UUID, commentID uuid.UUID) (*model.StoryComment, error) {
	return nil, nil
}

func (r *storyHTTPMemoryRepository) ListComments(_ context.Context, storyID uuid.UUID, limit int, offset int) ([]*model.StoryComment, error) {
	return []*model.StoryComment{}, nil
}

func (r *storyHTTPMemoryRepository) DeleteComment(_ context.Context, storyID uuid.UUID, commentID uuid.UUID) (bool, error) {
	return false, nil
}

func (r *storyHTTPMemoryRepository) LikeComment(_ context.Context, storyID uuid.UUID, commentID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	return false, 0, nil
}

func (r *storyHTTPMemoryRepository) UnlikeComment(_ context.Context, storyID uuid.UUID, commentID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	return false, 0, nil
}

func (r *storyHTTPMemoryRepository) HasCommentLike(_ context.Context, commentID uuid.UUID, userID uuid.UUID) (bool, error) {
	return false, nil
}

func storyMatchesHTTPFilter(story *model.Story, filter model.StoryListFilter) bool {
	if story == nil {
		return false
	}
	if filter.OnlyPublished && !story.IsPubliclyVisible() {
		return false
	}
	if !filter.IncludeDeleted && story.DeletedAt != nil {
		return false
	}
	if filter.ExcludeStoryID != nil && story.ID == *filter.ExcludeStoryID {
		return false
	}
	if filter.AuthorUserID != nil && story.AuthorUserID != *filter.AuthorUserID {
		return false
	}
	if !filter.IncludeDrafts && story.Status == enum.StoryStatusDraft {
		return false
	}
	if filter.Status != nil && story.Status != *filter.Status {
		return false
	}
	if filter.ArchivedOnly && story.ArchivedAt == nil {
		return false
	}
	if filter.ExcludeArchived && story.ArchivedAt != nil {
		return false
	}
	if len(filter.Formats) > 0 {
		matched := false
		for _, format := range filter.Formats {
			if story.Format == format {
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
			if story.Category == category {
				matched = true
				break
			}
		}
		if !matched {
			return false
		}
	}
	if value := strings.ToUpper(strings.TrimSpace(filter.PlaceCountryCode)); value != "" &&
		(story.PlaceCountryCode == nil || strings.ToUpper(strings.TrimSpace(*story.PlaceCountryCode)) != value) {
		return false
	}
	if value := strings.TrimSpace(filter.PlaceCityID); value != "" &&
		(story.PlaceCityID == nil || strings.TrimSpace(*story.PlaceCityID) != value) {
		return false
	}
	return true
}

func storyHTTPRelatedScore(story *model.Story, filter model.StoryListFilter) int {
	if story == nil {
		return 0
	}
	score := 0
	if value := strings.TrimSpace(filter.RelatedToCityID); value != "" &&
		story.PlaceCityID != nil &&
		strings.TrimSpace(*story.PlaceCityID) == value {
		score += 80
	}
	if value := strings.ToUpper(strings.TrimSpace(filter.RelatedToCountry)); value != "" &&
		story.PlaceCountryCode != nil &&
		strings.ToUpper(strings.TrimSpace(*story.PlaceCountryCode)) == value {
		score += 36
	}
	if filter.RelatedToCategory != nil && story.Category == *filter.RelatedToCategory {
		score += 32
	}
	if filter.RelatedToFormat != nil && story.Format == *filter.RelatedToFormat {
		score += 24
	}
	if filter.RelatedToAuthor != nil && story.AuthorUserID == *filter.RelatedToAuthor {
		score += 12
	}
	if storyHTTPHasRelatedTag(story.Tags, filter.RelatedToTags) {
		score += 18
	}
	return score
}

func storyHTTPHasRelatedTag(storyTags []string, relatedTags []string) bool {
	if len(storyTags) == 0 || len(relatedTags) == 0 {
		return false
	}
	seen := make(map[string]struct{}, len(storyTags))
	for _, tag := range storyTags {
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

func storyHTTPComparableTime(story *model.Story) time.Time {
	if story == nil {
		return time.Time{}
	}
	if story.PublishedAt != nil {
		return *story.PublishedAt
	}
	return story.CreatedAt
}

func cloneHTTPStory(story *model.Story) *model.Story {
	if story == nil {
		return nil
	}
	copy := *story
	if story.ContentBlocks != nil {
		copy.ContentBlocks = append([]byte(nil), story.ContentBlocks...)
	}
	if story.Tags != nil {
		copy.Tags = append([]string(nil), story.Tags...)
	}
	return &copy
}
