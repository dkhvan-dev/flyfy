package http

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"kz/inflap/backend/services/checklist-service/data"
	"kz/inflap/backend/services/checklist-service/internal/app"
)

func TestTripChecklistEndpointsPersistProgressForAuthenticatedUser(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := []byte(`{
		"userId": "body-user-must-be-ignored",
		"tripId": "tokyo-july",
		"destination": {"countryCode": "JP", "cityName": "Tokyo"},
		"startAt": "2026-07-11T10:00:00Z",
		"endAt": "2026-07-18T10:00:00Z",
		"transportModes": ["flight"],
		"activitySlugs": ["hiking"],
		"travelerProfile": {"preferredLanguage": "en"}
	}`)

	createReq := httptest.NewRequest(http.MethodPost, "/v1/checklists/trips?lang=en", bytes.NewReader(body))
	createReq.Header.Set("X-User-Id", "user-42")
	createRec := httptest.NewRecorder()
	mux.ServeHTTP(createRec, createReq)

	if createRec.Code != http.StatusOK {
		t.Fatalf("expected create 200, got %d with body %s", createRec.Code, createRec.Body.String())
	}
	var created map[string]any
	if err := json.Unmarshal(createRec.Body.Bytes(), &created); err != nil {
		t.Fatalf("decode create response: %v", err)
	}
	if created["instanceId"] == "" {
		t.Fatalf("expected instanceId in response, got %#v", created)
	}
	if created["userId"] != "user-42" {
		t.Fatalf("expected trusted header user id, got %#v", created["userId"])
	}

	patchReq := httptest.NewRequest(
		http.MethodPatch,
		"/v1/checklists/trips/tokyo-july/items/documents.passport_id",
		bytes.NewReader([]byte(`{"status":"done"}`)),
	)
	patchReq.Header.Set("X-User-Id", "user-42")
	patchRec := httptest.NewRecorder()
	mux.ServeHTTP(patchRec, patchReq)

	if patchRec.Code != http.StatusOK {
		t.Fatalf("expected patch 200, got %d with body %s", patchRec.Code, patchRec.Body.String())
	}
	var updated map[string]any
	if err := json.Unmarshal(patchRec.Body.Bytes(), &updated); err != nil {
		t.Fatalf("decode patch response: %v", err)
	}
	if responseItemStatus(updated["items"].([]any), "documents.passport_id") != "done" {
		t.Fatalf("expected persisted passport status done, got %#v", updated["items"])
	}

	reloadReq := httptest.NewRequest(http.MethodPost, "/v1/checklists/trips?lang=en", bytes.NewReader(body))
	reloadReq.Header.Set("X-User-Id", "user-42")
	reloadRec := httptest.NewRecorder()
	mux.ServeHTTP(reloadRec, reloadReq)

	if reloadRec.Code != http.StatusOK {
		t.Fatalf("expected reload 200, got %d with body %s", reloadRec.Code, reloadRec.Body.String())
	}
	var reloaded map[string]any
	if err := json.Unmarshal(reloadRec.Body.Bytes(), &reloaded); err != nil {
		t.Fatalf("decode reload response: %v", err)
	}
	if responseItemStatus(reloaded["items"].([]any), "documents.passport_id") != "done" {
		t.Fatalf("expected status to survive reload, got %#v", reloaded["items"])
	}
}

func TestListTripChecklistsReturnsAuthenticatedUserSummaries(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	createChecklist := func(userID string, body []byte) {
		t.Helper()
		req := httptest.NewRequest(http.MethodPost, "/v1/checklists/trips?lang=en", bytes.NewReader(body))
		req.Header.Set("X-User-Id", userID)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("expected create 200, got %d with body %s", rec.Code, rec.Body.String())
		}
	}

	createChecklist("user-42", []byte(`{
		"userId": "body-user-must-be-ignored",
		"tripId": "quick-prep:tr:istanbul:2026-07-10",
		"destination": {"countryCode": "TR", "cityName": "Istanbul", "cityId": "istanbul"},
		"startAt": "2026-07-10T09:00:00Z",
		"endAt": "2026-07-17T18:00:00Z",
		"transportModes": ["flight"],
		"activitySlugs": ["culture"],
		"travelerProfile": {"hasChildren": true, "preferredLanguage": "ru"}
	}`))
	createChecklist("user-99", []byte(`{
		"tripId": "quick-prep:kz:almaty:2026-07-01",
		"destination": {"countryCode": "KZ", "cityName": "Almaty", "cityId": "almaty"},
		"startAt": "2026-07-01T09:00:00Z",
		"endAt": "2026-07-08T18:00:00Z",
		"transportModes": ["flight"],
		"activitySlugs": ["hiking"],
		"travelerProfile": {"preferredLanguage": "ru"}
	}`))

	listReq := httptest.NewRequest(http.MethodGet, "/v1/checklists/trips?lang=ru&limit=20", nil)
	listReq.Header.Set("X-User-Id", "user-42")
	listRec := httptest.NewRecorder()
	mux.ServeHTTP(listRec, listReq)

	if listRec.Code != http.StatusOK {
		t.Fatalf("expected list 200, got %d with body %s", listRec.Code, listRec.Body.String())
	}
	var response map[string][]map[string]any
	if err := json.Unmarshal(listRec.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode list response: %v", err)
	}
	items := response["items"]
	if len(items) != 1 {
		t.Fatalf("expected only authenticated user's checklist, got %#v", items)
	}
	item := items[0]
	if item["userId"] != "user-42" || item["tripId"] != "quick-prep:tr:istanbul:2026-07-10" {
		t.Fatalf("unexpected checklist summary identity: %#v", item)
	}
	destination, ok := item["destination"].(map[string]any)
	if !ok {
		t.Fatalf("expected destination object, got %#v", item["destination"])
	}
	if destination["countryCode"] != "TR" || destination["cityName"] != "Istanbul" || destination["cityId"] != "istanbul" {
		t.Fatalf("unexpected destination in summary: %#v", destination)
	}
	if item["startAt"] != "2026-07-10T09:00:00Z" || item["endAt"] != "2026-07-17T18:00:00Z" {
		t.Fatalf("unexpected dates in summary: %#v", item)
	}
	if item["hasChildren"] != true {
		t.Fatalf("expected hasChildren to survive list summary, got %#v", item["hasChildren"])
	}
	if transportModes := item["transportModes"].([]any); len(transportModes) != 1 || transportModes[0] != "flight" {
		t.Fatalf("unexpected transportModes: %#v", item["transportModes"])
	}
	if activitySlugs := item["activitySlugs"].([]any); len(activitySlugs) != 1 || activitySlugs[0] != "culture" {
		t.Fatalf("unexpected activitySlugs: %#v", item["activitySlugs"])
	}
	if item["itemCount"].(float64) == 0 {
		t.Fatalf("expected non-zero itemCount in summary, got %#v", item)
	}
	readiness, ok := item["readiness"].(map[string]any)
	if !ok || readiness["status"] == "" {
		t.Fatalf("expected readiness summary, got %#v", item["readiness"])
	}
}

func TestChecklistItemFeedbackEndpointUsesAuthenticatedUser(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := []byte(`{
		"userId": "body-user-must-be-ignored",
		"tripId": "tokyo-july",
		"destination": {"countryCode": "JP", "cityName": "Tokyo"},
		"startAt": "2026-07-11T10:00:00Z",
		"endAt": "2026-07-18T10:00:00Z",
		"transportModes": ["flight"],
		"activitySlugs": ["hiking"],
		"travelerProfile": {"preferredLanguage": "en"}
	}`)

	createReq := httptest.NewRequest(http.MethodPost, "/v1/checklists/trips?lang=en", bytes.NewReader(body))
	createReq.Header.Set("X-User-Id", "user-42")
	createRec := httptest.NewRecorder()
	mux.ServeHTTP(createRec, createReq)

	if createRec.Code != http.StatusOK {
		t.Fatalf("expected create 200, got %d with body %s", createRec.Code, createRec.Body.String())
	}

	feedbackReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/checklists/trips/tokyo-july/items/documents.passport_id/feedback?lang=en",
		bytes.NewReader([]byte(`{"type":"add_next_time","comment":"Remember a passport cover next time"}`)),
	)
	feedbackReq.Header.Set("X-User-Id", "user-42")
	feedbackRec := httptest.NewRecorder()
	mux.ServeHTTP(feedbackRec, feedbackReq)

	if feedbackRec.Code != http.StatusCreated {
		t.Fatalf("expected feedback 201, got %d with body %s", feedbackRec.Code, feedbackRec.Body.String())
	}
	var feedback map[string]any
	if err := json.Unmarshal(feedbackRec.Body.Bytes(), &feedback); err != nil {
		t.Fatalf("decode feedback response: %v", err)
	}
	if feedback["userId"] != "user-42" || feedback["type"] != "add_next_time" {
		t.Fatalf("expected trusted feedback response, got %#v", feedback)
	}
	if feedback["comment"] != "Remember a passport cover next time" {
		t.Fatalf("expected feedback comment in response, got %#v", feedback)
	}
}

func TestChecklistItemFeedbackEndpointRejectsInvalidType(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/checklists/trips/trip-1/items/documents.passport_id/feedback",
		bytes.NewReader([]byte(`{"type":"maybe"}`)),
	)
	req.Header.Set("X-User-Id", "user-42")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected invalid feedback 400, got %d with body %s", rec.Code, rec.Body.String())
	}
}

func TestDispatchChecklistNotificationsEndpointRejectsDispatchRequests(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodPost,
		"/internal/v1/checklists/notifications/dispatch",
		bytes.NewReader(nil),
	)
	req.Header.Set("X-Internal-Service-Token", "secret-token")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("expected removed dispatch endpoint 405, got %d with body %s", rec.Code, rec.Body.String())
	}
}

func TestCreateCustomChecklistItemRequiresAuth(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/checklists/trips/tokyo-july/custom-items",
		bytes.NewReader([]byte(`{"title":"Camera charger","category":"custom","priority":"recommended"}`)),
	)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected custom item create 401 without auth, got %d with body %s", rec.Code, rec.Body.String())
	}
}

func TestCreateCustomChecklistItemReturnsUpdatedChecklistWithPersonalProgress(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	created := createHTTPChecklist(t, mux, "user-42", "tokyo-july")
	initialScore := responseReadinessScore(t, created)

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/checklists/trips/tokyo-july/custom-items?lang=en",
		bytes.NewReader([]byte(`{"title":" Camera charger ","note":" USB-C ","category":"custom","priority":"recommended","reuseInFuture":true}`)),
	)
	req.Header.Set("X-User-Id", "user-42")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected custom item create 200, got %d with body %s", rec.Code, rec.Body.String())
	}
	var resp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode custom item create response: %v", err)
	}
	if responseReadinessScore(t, resp) != initialScore {
		t.Fatalf("expected system readiness to remain %d, got %#v", initialScore, resp["readiness"])
	}
	progress := resp["personalProgress"].(map[string]any)
	if progress["total"] != float64(1) || progress["done"] != float64(0) || progress["percent"] != float64(0) {
		t.Fatalf("unexpected personal progress: %#v", progress)
	}
	items := resp["customItems"].([]any)
	if len(items) != 1 {
		t.Fatalf("expected one custom item, got %#v", items)
	}
	item := items[0].(map[string]any)
	if item["title"] != "Camera charger" || item["note"] != "USB-C" || item["status"] != "open" {
		t.Fatalf("unexpected custom item response: %#v", item)
	}
	if item["reuseInFuture"] != true || item["personalTemplateId"] == "" {
		t.Fatalf("expected reusable item linked to template, got %#v", item)
	}
}

func TestUpdateCustomChecklistItemStatusReturnsUpdatedPersonalProgress(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)
	createHTTPChecklist(t, mux, "user-42", "tokyo-july")
	itemID := createHTTPCustomItem(t, mux, "user-42", "tokyo-july")

	req := httptest.NewRequest(
		http.MethodPatch,
		"/v1/checklists/trips/tokyo-july/custom-items/"+itemID+"/status?lang=en",
		bytes.NewReader([]byte(`{"status":"done"}`)),
	)
	req.Header.Set("X-User-Id", "user-42")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected custom item status 200, got %d with body %s", rec.Code, rec.Body.String())
	}
	var resp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode custom item status response: %v", err)
	}
	progress := resp["personalProgress"].(map[string]any)
	if progress["total"] != float64(1) || progress["done"] != float64(1) || progress["percent"] != float64(100) {
		t.Fatalf("unexpected personal progress after status update: %#v", progress)
	}
	if responseCustomItemStatus(resp["customItems"].([]any), itemID) != "done" {
		t.Fatalf("expected custom item done, got %#v", resp["customItems"])
	}
}

func TestDeleteCustomChecklistItemReturnsUpdatedChecklist(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)
	createHTTPChecklist(t, mux, "user-42", "tokyo-july")
	itemID := createHTTPCustomItem(t, mux, "user-42", "tokyo-july")

	req := httptest.NewRequest(
		http.MethodDelete,
		"/v1/checklists/trips/tokyo-july/custom-items/"+itemID+"?lang=en",
		nil,
	)
	req.Header.Set("X-User-Id", "user-42")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected custom item delete 200, got %d with body %s", rec.Code, rec.Body.String())
	}
	var resp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode custom item delete response: %v", err)
	}
	if len(resp["customItems"].([]any)) != 0 {
		t.Fatalf("expected no custom items after delete, got %#v", resp["customItems"])
	}
	progress := resp["personalProgress"].(map[string]any)
	if progress["total"] != float64(0) || progress["done"] != float64(0) || progress["percent"] != float64(0) {
		t.Fatalf("unexpected personal progress after delete: %#v", progress)
	}
}

func TestCreateCustomChecklistItemIgnoresBodyUserID(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)
	createHTTPChecklist(t, mux, "trusted-user", "tokyo-july")

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/checklists/trips/tokyo-july/custom-items?lang=en",
		bytes.NewReader([]byte(`{"userId":"body-user-must-be-ignored","title":"Camera charger","category":"custom","priority":"recommended"}`)),
	)
	req.Header.Set("X-User-Id", "trusted-user")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected custom item create 200, got %d with body %s", rec.Code, rec.Body.String())
	}

	trustedChecklist := createHTTPChecklist(t, mux, "trusted-user", "tokyo-july")
	if len(trustedChecklist["customItems"].([]any)) != 1 {
		t.Fatalf("expected trusted user to own custom item, got %#v", trustedChecklist["customItems"])
	}
	bodyUserChecklist := createHTTPChecklist(t, mux, "body-user-must-be-ignored", "tokyo-july")
	if len(bodyUserChecklist["customItems"].([]any)) != 0 {
		t.Fatalf("body user from JSON must not own custom item, got %#v", bodyUserChecklist["customItems"])
	}
}

func TestChecklistAssignmentAndReminderEndpoints(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := []byte(`{
		"tripId": "tokyo-july",
		"destination": {"countryCode": "JP", "cityName": "Tokyo"},
		"startAt": "2026-07-11T10:00:00Z",
		"endAt": "2026-07-18T10:00:00Z",
		"transportModes": ["flight"],
		"activitySlugs": ["hiking"],
		"travelerProfile": {"preferredLanguage": "en"}
	}`)
	createReq := httptest.NewRequest(http.MethodPost, "/v1/checklists/trips?lang=en", bytes.NewReader(body))
	createReq.Header.Set("X-User-Id", "user-42")
	createRec := httptest.NewRecorder()
	mux.ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusOK {
		t.Fatalf("expected create 200, got %d with body %s", createRec.Code, createRec.Body.String())
	}

	assignReq := httptest.NewRequest(
		http.MethodPatch,
		"/v1/checklists/trips/tokyo-july/items/documents.passport_id/assignment?lang=en",
		bytes.NewReader([]byte(`{"assignToMe":true}`)),
	)
	assignReq.Header.Set("X-User-Id", "user-42")
	assignRec := httptest.NewRecorder()
	mux.ServeHTTP(assignRec, assignReq)
	if assignRec.Code != http.StatusOK {
		t.Fatalf("expected assignment 200, got %d with body %s", assignRec.Code, assignRec.Body.String())
	}
	var assigned map[string]any
	if err := json.Unmarshal(assignRec.Body.Bytes(), &assigned); err != nil {
		t.Fatalf("decode assignment response: %v", err)
	}
	if responseItemAssignedUser(assigned["items"].([]any), "documents.passport_id") != "user-42" {
		t.Fatalf("expected item assigned to trusted user, got %#v", assigned["items"])
	}

	remindersReq := httptest.NewRequest(http.MethodGet, "/v1/checklists/trips/tokyo-july/reminders?lang=en", nil)
	remindersReq.Header.Set("X-User-Id", "user-42")
	remindersRec := httptest.NewRecorder()
	mux.ServeHTTP(remindersRec, remindersReq)
	if remindersRec.Code != http.StatusOK {
		t.Fatalf("expected reminders 200, got %d with body %s", remindersRec.Code, remindersRec.Body.String())
	}
	var reminders map[string][]map[string]any
	if err := json.Unmarshal(remindersRec.Body.Bytes(), &reminders); err != nil {
		t.Fatalf("decode reminders response: %v", err)
	}
	if len(reminders["items"]) != 5 || reminders["items"][0]["offsetDays"] != float64(30) {
		t.Fatalf("expected five reminder milestones, got %#v", reminders)
	}
}

func TestAdminChecklistFeedbackEndpointRequiresModeratorRole(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := []byte(`{
		"tripId": "tokyo-july",
		"destination": {"countryCode": "JP", "cityName": "Tokyo"},
		"startAt": "2026-07-11T10:00:00Z",
		"endAt": "2026-07-18T10:00:00Z",
		"transportModes": ["flight"],
		"activitySlugs": ["hiking"]
	}`)
	createReq := httptest.NewRequest(http.MethodPost, "/v1/checklists/trips", bytes.NewReader(body))
	createReq.Header.Set("X-User-Id", "user-42")
	createRec := httptest.NewRecorder()
	mux.ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusOK {
		t.Fatalf("expected create 200, got %d with body %s", createRec.Code, createRec.Body.String())
	}

	feedbackReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/checklists/trips/tokyo-july/items/documents.passport_id/feedback",
		bytes.NewReader([]byte(`{"type":"helpful","comment":"Useful"}`)),
	)
	feedbackReq.Header.Set("X-User-Id", "user-42")
	feedbackRec := httptest.NewRecorder()
	mux.ServeHTTP(feedbackRec, feedbackReq)
	if feedbackRec.Code != http.StatusCreated {
		t.Fatalf("expected feedback 201, got %d with body %s", feedbackRec.Code, feedbackRec.Body.String())
	}

	forbiddenReq := httptest.NewRequest(http.MethodGet, "/v1/admin/checklists/feedback", nil)
	forbiddenReq.Header.Set("X-User-Id", "admin-1")
	forbiddenRec := httptest.NewRecorder()
	mux.ServeHTTP(forbiddenRec, forbiddenReq)
	if forbiddenRec.Code != http.StatusForbidden {
		t.Fatalf("expected admin feedback 403 without role, got %d", forbiddenRec.Code)
	}

	adminReq := httptest.NewRequest(http.MethodGet, "/v1/admin/checklists/feedback?type=helpful", nil)
	adminReq.Header.Set("X-User-Id", "admin-1")
	adminReq.Header.Set("X-User-Roles", "MODERATOR")
	adminRec := httptest.NewRecorder()
	mux.ServeHTTP(adminRec, adminReq)
	if adminRec.Code != http.StatusOK {
		t.Fatalf("expected admin feedback 200, got %d with body %s", adminRec.Code, adminRec.Body.String())
	}
	var resp map[string][]map[string]any
	if err := json.Unmarshal(adminRec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode admin feedback response: %v", err)
	}
	if len(resp["items"]) != 1 || resp["items"][0]["type"] != "helpful" {
		t.Fatalf("expected one helpful feedback item, got %#v", resp)
	}
}

func TestTripPreviewEndpointReturnsReadinessAndLocalizedItems(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := []byte(`{
		"tripId": "tokyo-july",
		"destination": {"countryCode": "JP", "cityName": "Tokyo"},
		"startAt": "2026-07-11T10:00:00Z",
		"endAt": "2026-07-18T10:00:00Z",
		"transportModes": ["flight"],
		"activitySlugs": ["hiking"],
		"travelerProfile": {"preferredLanguage": "ru"}
	}`)

	req := httptest.NewRequest(http.MethodPost, "/v1/checklists/trip-preview?lang=ru", bytes.NewReader(body))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d with body %s", rec.Code, rec.Body.String())
	}

	var resp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	readiness := resp["readiness"].(map[string]any)
	if readiness["status"] != "not_ready" {
		t.Fatalf("expected not_ready readiness, got %#v", readiness)
	}
	if resp["trustNotice"].(map[string]any)["code"] != "official_source_required" {
		t.Fatalf("expected official source notice, got %#v", resp["trustNotice"])
	}

	items := resp["items"].([]any)
	if len(items) == 0 {
		t.Fatal("expected checklist items")
	}
	if !responseHasItem(items, "weather.tokyo_july_rain_heat", "Защита от жары и дождя") {
		t.Fatalf("expected localized Tokyo weather item, got %#v", items)
	}
}

func TestTripPreviewEndpointUsesCitizenshipForInternationalDocuments(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := []byte(`{
		"tripId": "domestic-almaty",
		"destination": {"countryCode": "KZ", "cityName": "Almaty"},
		"startAt": "2026-07-11T10:00:00Z",
		"endAt": "2026-07-18T10:00:00Z",
		"transportModes": ["flight"],
		"activitySlugs": ["hiking"],
		"travelerProfile": {"citizenshipCountryCode": "KZ", "preferredLanguage": "ru"}
	}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/checklists/trip-preview?lang=ru", bytes.NewReader(body))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d with body %s", rec.Code, rec.Body.String())
	}

	var resp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if status := responseItemStatus(resp["items"].([]any), "documents.travel_insurance"); status != "" {
		t.Fatalf("domestic checklist should not include travel insurance, got status %q in %#v", status, resp["items"])
	}
}

func TestCarryItemSearchEndpointReturnsPolicy(t *testing.T) {
	handler := NewHandler(app.NewChecklistUseCase(app.NewMemoryChecklistRepository(data.DefaultCatalogSeed())))
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodGet, "/v1/checklists/carry-items/search?q=power%20bank&transportMode=flight&lang=en", nil)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d with body %s", rec.Code, rec.Body.String())
	}

	var resp map[string][]map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	items := resp["items"]
	if len(items) != 1 {
		t.Fatalf("expected one item, got %#v", items)
	}
	if items[0]["checkedBaggage"] != "prohibited" {
		t.Fatalf("expected prohibited checked baggage, got %#v", items[0])
	}
	if items[0]["source"].(map[string]any)["confidence"] != "high" {
		t.Fatalf("expected high confidence source, got %#v", items[0]["source"])
	}
}

func responseHasItem(items []any, id string, title string) bool {
	for _, raw := range items {
		item, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		if item["id"] == id && item["title"] == title {
			return true
		}
	}
	return false
}

func responseItemStatus(items []any, id string) string {
	for _, raw := range items {
		item, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		if item["id"] == id {
			status, _ := item["status"].(string)
			return status
		}
	}
	return ""
}

func responseItemAssignedUser(items []any, id string) string {
	for _, raw := range items {
		item, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		if item["id"] == id {
			assignedUserID, _ := item["assignedUserId"].(string)
			return assignedUserID
		}
	}
	return ""
}

func createHTTPChecklist(t *testing.T, mux *http.ServeMux, userID string, tripID string) map[string]any {
	t.Helper()

	body := []byte(`{
		"tripId": "` + tripID + `",
		"destination": {"countryCode": "JP", "cityName": "Tokyo"},
		"startAt": "2026-07-11T10:00:00Z",
		"endAt": "2026-07-18T10:00:00Z",
		"transportModes": ["flight"],
		"activitySlugs": ["hiking"],
		"travelerProfile": {"preferredLanguage": "en"}
	}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/checklists/trips?lang=en", bytes.NewReader(body))
	req.Header.Set("X-User-Id", userID)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected checklist create 200, got %d with body %s", rec.Code, rec.Body.String())
	}
	var resp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode checklist response: %v", err)
	}
	return resp
}

func createHTTPCustomItem(t *testing.T, mux *http.ServeMux, userID string, tripID string) string {
	t.Helper()

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/checklists/trips/"+tripID+"/custom-items?lang=en",
		bytes.NewReader([]byte(`{"title":"Camera charger","category":"custom","priority":"recommended"}`)),
	)
	req.Header.Set("X-User-Id", userID)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected custom item create 200, got %d with body %s", rec.Code, rec.Body.String())
	}
	var resp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode custom item response: %v", err)
	}
	items := resp["customItems"].([]any)
	if len(items) != 1 {
		t.Fatalf("expected one custom item, got %#v", items)
	}
	itemID, _ := items[0].(map[string]any)["id"].(string)
	if itemID == "" {
		t.Fatalf("expected custom item id, got %#v", items[0])
	}
	return itemID
}

func responseReadinessScore(t *testing.T, resp map[string]any) int {
	t.Helper()

	readiness, ok := resp["readiness"].(map[string]any)
	if !ok {
		t.Fatalf("expected readiness object, got %#v", resp["readiness"])
	}
	score, ok := readiness["score"].(float64)
	if !ok {
		t.Fatalf("expected readiness score, got %#v", readiness)
	}
	return int(score)
}

func responseCustomItemStatus(items []any, id string) string {
	for _, raw := range items {
		item, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		if item["id"] == id {
			status, _ := item["status"].(string)
			return status
		}
	}
	return ""
}
