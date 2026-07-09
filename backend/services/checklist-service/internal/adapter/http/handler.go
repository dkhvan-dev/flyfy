package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"kz/inflap/backend/services/checklist-service/internal/app"
	"kz/inflap/backend/services/checklist-service/internal/domain/model"
)

type Handler struct {
	uc *app.ChecklistUseCase
}

func NewHandler(uc *app.ChecklistUseCase) *Handler {
	return &Handler{uc: uc}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("POST /v1/checklists/trip-preview", h.TripPreview)
	mux.HandleFunc("GET /v1/checklists/trips", h.ListTripChecklists)
	mux.HandleFunc("POST /v1/checklists/trips", h.GetOrCreateTripChecklist)
	mux.HandleFunc("GET /v1/checklists/trips/{tripID}/reminders", h.ListTripChecklistReminders)
	mux.HandleFunc("PATCH /v1/checklists/trips/{tripID}/items/{itemID}", h.UpdateChecklistItemStatus)
	mux.HandleFunc("PATCH /v1/checklists/trips/{tripID}/items/{itemID}/assignment", h.SetChecklistItemAssignment)
	mux.HandleFunc("POST /v1/checklists/trips/{tripID}/items/{itemID}/feedback", h.SubmitChecklistItemFeedback)
	mux.HandleFunc("POST /v1/checklists/trips/{tripID}/custom-items", h.CreateCustomChecklistItem)
	mux.HandleFunc("PATCH /v1/checklists/trips/{tripID}/custom-items/{itemID}", h.UpdateCustomChecklistItem)
	mux.HandleFunc("PATCH /v1/checklists/trips/{tripID}/custom-items/{itemID}/status", h.UpdateCustomChecklistItemStatus)
	mux.HandleFunc("PATCH /v1/checklists/trips/{tripID}/custom-items/{itemID}/assignment", h.SetCustomChecklistItemAssignment)
	mux.HandleFunc("DELETE /v1/checklists/trips/{tripID}/custom-items/{itemID}", h.DeleteCustomChecklistItem)
	mux.HandleFunc("GET /v1/checklists/personal-templates", h.ListPersonalChecklistTemplates)
	mux.HandleFunc("POST /v1/checklists/trips/{tripID}/personal-templates/apply", h.ApplyPersonalChecklistTemplates)
	mux.HandleFunc("GET /v1/checklists/carry-items/search", h.SearchCarryItems)
	mux.HandleFunc("GET /v1/admin/checklists/feedback", h.ListAdminChecklistFeedback)
	mux.HandleFunc("GET /", h.NotFound)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) NotFound(w http.ResponseWriter, _ *http.Request) {
	writeError(w, http.StatusNotFound, "checklist.route_not_found", "Route not found")
}

func (h *Handler) TripPreview(w http.ResponseWriter, r *http.Request) {
	req, startAt, endAt, ok := h.parseTripPreviewRequest(w, r)
	if !ok {
		return
	}

	lang := parseLang(r, req.TravelerProfile.PreferredLanguage)
	checklist, err := h.uc.GenerateTripChecklist(tripPreviewInput(req, startAt, endAt, strings.TrimSpace(req.UserID), lang))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "checklist.technical", "Checklist generation failed")
		return
	}

	writeJSON(w, http.StatusOK, mapTripChecklist(checklist, lang))
}

func (h *Handler) GetOrCreateTripChecklist(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	req, startAt, endAt, ok := h.parseTripPreviewRequest(w, r)
	if !ok {
		return
	}

	lang := parseLang(r, req.TravelerProfile.PreferredLanguage)
	checklist, err := h.uc.GetOrCreateTripChecklist(
		r.Context(),
		tripPreviewInput(req, startAt, endAt, userID, lang),
	)
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, mapTripChecklist(checklist, lang))
}

func (h *Handler) ListTripChecklists(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	checklists, err := h.uc.ListTripChecklists(r.Context(), app.ListTripChecklistsInput{
		UserID: userID,
		Limit:  limit,
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	resp := make([]tripChecklistSummaryResponse, len(checklists))
	for i, checklist := range checklists {
		resp[i] = mapTripChecklistSummary(checklist)
	}
	writeJSON(w, http.StatusOK, map[string][]tripChecklistSummaryResponse{"items": resp})
}

func (h *Handler) UpdateChecklistItemStatus(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	var req updateChecklistItemStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "checklist.invalid_json", "Invalid JSON body")
		return
	}

	lang := parseLang(r, "")
	checklist, err := h.uc.UpdateChecklistItemStatus(r.Context(), app.UpdateChecklistItemStatusInput{
		UserID: userID,
		TripID: strings.TrimSpace(r.PathValue("tripID")),
		ItemID: strings.TrimSpace(r.PathValue("itemID")),
		Status: req.Status,
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, mapTripChecklist(checklist, lang))
}

func (h *Handler) SetChecklistItemAssignment(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	var req setChecklistItemAssignmentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "checklist.invalid_json", "Invalid JSON body")
		return
	}

	lang := parseLang(r, "")
	checklist, err := h.uc.SetChecklistItemAssignment(r.Context(), app.SetChecklistItemAssignmentInput{
		UserID:     userID,
		TripID:     strings.TrimSpace(r.PathValue("tripID")),
		ItemID:     strings.TrimSpace(r.PathValue("itemID")),
		AssignToMe: req.AssignToMe,
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, mapTripChecklist(checklist, lang))
}

func (h *Handler) ListTripChecklistReminders(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	lang := parseLang(r, "")
	reminders, err := h.uc.ListTripChecklistReminders(r.Context(), app.ListTripChecklistRemindersInput{
		UserID: userID,
		TripID: strings.TrimSpace(r.PathValue("tripID")),
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	resp := make([]checklistReminderResponse, len(reminders))
	for i, reminder := range reminders {
		resp[i] = mapChecklistReminder(reminder, lang)
	}
	writeJSON(w, http.StatusOK, map[string][]checklistReminderResponse{"items": resp})
}

func (h *Handler) SubmitChecklistItemFeedback(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	var req submitChecklistItemFeedbackRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "checklist.invalid_json", "Invalid JSON body")
		return
	}

	feedback, err := h.uc.SubmitChecklistItemFeedback(r.Context(), app.SubmitChecklistItemFeedbackInput{
		UserID:       userID,
		TripID:       strings.TrimSpace(r.PathValue("tripID")),
		ItemID:       strings.TrimSpace(r.PathValue("itemID")),
		FeedbackType: req.Type,
		Comment:      req.Comment,
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, mapChecklistItemFeedback(feedback))
}

func (h *Handler) CreateCustomChecklistItem(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	var req customChecklistItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "checklist.invalid_json", "Invalid JSON body")
		return
	}

	lang := parseLang(r, "")
	checklist, err := h.uc.CreateCustomChecklistItem(r.Context(), app.CreateCustomChecklistItemInput{
		UserID:        userID,
		TripID:        strings.TrimSpace(r.PathValue("tripID")),
		Title:         req.Title,
		Note:          req.Note,
		Category:      req.Category,
		Priority:      req.Priority,
		ReuseInFuture: req.ReuseInFuture,
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, mapTripChecklist(checklist, lang))
}

func (h *Handler) UpdateCustomChecklistItem(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	var req customChecklistItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "checklist.invalid_json", "Invalid JSON body")
		return
	}

	lang := parseLang(r, "")
	checklist, err := h.uc.UpdateCustomChecklistItem(r.Context(), app.UpdateCustomChecklistItemInput{
		UserID:        userID,
		TripID:        strings.TrimSpace(r.PathValue("tripID")),
		ItemID:        strings.TrimSpace(r.PathValue("itemID")),
		Title:         req.Title,
		Note:          req.Note,
		Category:      req.Category,
		Priority:      req.Priority,
		ReuseInFuture: req.ReuseInFuture,
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, mapTripChecklist(checklist, lang))
}

func (h *Handler) UpdateCustomChecklistItemStatus(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	var req updateChecklistItemStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "checklist.invalid_json", "Invalid JSON body")
		return
	}

	lang := parseLang(r, "")
	checklist, err := h.uc.UpdateCustomChecklistItemStatus(r.Context(), app.UpdateCustomChecklistItemStatusInput{
		UserID: userID,
		TripID: strings.TrimSpace(r.PathValue("tripID")),
		ItemID: strings.TrimSpace(r.PathValue("itemID")),
		Status: req.Status,
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, mapTripChecklist(checklist, lang))
}

func (h *Handler) SetCustomChecklistItemAssignment(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	var req setChecklistItemAssignmentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "checklist.invalid_json", "Invalid JSON body")
		return
	}

	lang := parseLang(r, "")
	checklist, err := h.uc.SetCustomChecklistItemAssignment(r.Context(), app.SetCustomChecklistItemAssignmentInput{
		UserID:     userID,
		TripID:     strings.TrimSpace(r.PathValue("tripID")),
		ItemID:     strings.TrimSpace(r.PathValue("itemID")),
		AssignToMe: req.AssignToMe,
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, mapTripChecklist(checklist, lang))
}

func (h *Handler) DeleteCustomChecklistItem(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	lang := parseLang(r, "")
	checklist, err := h.uc.DeleteCustomChecklistItem(r.Context(), app.DeleteCustomChecklistItemInput{
		UserID: userID,
		TripID: strings.TrimSpace(r.PathValue("tripID")),
		ItemID: strings.TrimSpace(r.PathValue("itemID")),
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, mapTripChecklist(checklist, lang))
}

func (h *Handler) ListPersonalChecklistTemplates(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	templates, err := h.uc.ListPersonalChecklistTemplates(r.Context(), app.ListPersonalChecklistTemplatesInput{
		UserID:     userID,
		ActiveOnly: true,
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	resp := make([]personalChecklistTemplateResponse, len(templates))
	for i, template := range templates {
		resp[i] = mapPersonalChecklistTemplate(template)
	}
	writeJSON(w, http.StatusOK, map[string][]personalChecklistTemplateResponse{"items": resp})
}

func (h *Handler) ApplyPersonalChecklistTemplates(w http.ResponseWriter, r *http.Request) {
	userID := trustedUserID(r)
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
		return
	}

	var req applyPersonalChecklistTemplatesRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "checklist.invalid_json", "Invalid JSON body")
		return
	}

	lang := parseLang(r, "")
	checklist, err := h.uc.ApplyPersonalChecklistTemplates(r.Context(), app.ApplyPersonalChecklistTemplatesInput{
		UserID:      userID,
		TripID:      strings.TrimSpace(r.PathValue("tripID")),
		TemplateIDs: req.TemplateIDs,
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, mapTripChecklist(checklist, lang))
}

func (h *Handler) ListAdminChecklistFeedback(w http.ResponseWriter, r *http.Request) {
	if !hasAnyRole(trustedUserRoles(r), "ADMIN", "MODERATOR") {
		writeError(w, http.StatusForbidden, "checklist.admin_required", "Admin or moderator role required")
		return
	}

	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	feedbackType := model.ChecklistFeedbackType(strings.TrimSpace(r.URL.Query().Get("type")))
	entries, err := h.uc.ListChecklistItemFeedback(r.Context(), app.ListChecklistItemFeedbackInput{
		FeedbackType: feedbackType,
		Limit:        limit,
	})
	if err != nil {
		writeChecklistAppError(w, err)
		return
	}

	resp := make([]checklistItemFeedbackResponse, len(entries))
	for i, entry := range entries {
		resp[i] = mapChecklistItemFeedback(entry)
	}
	writeJSON(w, http.StatusOK, map[string][]checklistItemFeedbackResponse{"items": resp})
}

func (h *Handler) SearchCarryItems(w http.ResponseWriter, r *http.Request) {
	lang := parseLang(r, "")
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	matches := h.uc.SearchCarryItems(app.SearchCarryItemsInput{
		Query:         r.URL.Query().Get("q"),
		TransportMode: model.TransportMode(strings.ToLower(strings.TrimSpace(r.URL.Query().Get("transportMode")))),
		PreferredLang: lang,
		Limit:         limit,
	})

	resp := make([]carryItemResponse, len(matches))
	for i, match := range matches {
		resp[i] = mapCarryItem(match, lang)
	}
	writeJSON(w, http.StatusOK, map[string][]carryItemResponse{"items": resp})
}

type tripPreviewRequest struct {
	UserID          string             `json:"userId"`
	TripID          string             `json:"tripId"`
	Destination     destinationRequest `json:"destination"`
	StartAt         string             `json:"startAt"`
	EndAt           string             `json:"endAt"`
	TransportModes  []string           `json:"transportModes"`
	ActivitySlugs   []string           `json:"activitySlugs"`
	TravelerProfile struct {
		HasChildren            bool   `json:"hasChildren"`
		CitizenshipCountryCode string `json:"citizenshipCountryCode"`
		PreferredLanguage      string `json:"preferredLanguage"`
	} `json:"travelerProfile"`
}

type updateChecklistItemStatusRequest struct {
	Status model.ChecklistItemStatus `json:"status"`
}

type customChecklistItemRequest struct {
	UserID        string                  `json:"userId"`
	Title         string                  `json:"title"`
	Note          string                  `json:"note"`
	Category      model.ChecklistCategory `json:"category"`
	Priority      model.ChecklistPriority `json:"priority"`
	ReuseInFuture bool                    `json:"reuseInFuture"`
}

type setChecklistItemAssignmentRequest struct {
	AssignToMe bool `json:"assignToMe"`
}

type applyPersonalChecklistTemplatesRequest struct {
	TemplateIDs []string `json:"templateIds"`
}

type submitChecklistItemFeedbackRequest struct {
	Type    model.ChecklistFeedbackType `json:"type"`
	Comment string                      `json:"comment"`
}

type destinationRequest struct {
	CountryCode string `json:"countryCode"`
	CityName    string `json:"cityName"`
	CityID      string `json:"cityId"`
}

func (d destinationRequest) toModel() model.TripDestination {
	return model.TripDestination{
		CountryCode: strings.ToUpper(strings.TrimSpace(d.CountryCode)),
		CityName:    strings.TrimSpace(d.CityName),
		CityID:      strings.TrimSpace(d.CityID),
	}
}

type tripChecklistResponse struct {
	InstanceID       string                          `json:"instanceId,omitempty"`
	UserID           string                          `json:"userId,omitempty"`
	TripID           string                          `json:"tripId"`
	Items            []checklistItemResponse         `json:"items"`
	CustomItems      []customChecklistItemResponse   `json:"customItems"`
	Readiness        model.ReadinessSummary          `json:"readiness"`
	PersonalProgress model.PersonalChecklistProgress `json:"personalProgress"`
	SeasonalProfile  *seasonalProfileResponse        `json:"seasonalProfile,omitempty"`
	TrustNotice      trustNoticeResponse             `json:"trustNotice"`
	GeneratedAt      time.Time                       `json:"generatedAt"`
	UpdatedAt        time.Time                       `json:"updatedAt,omitempty"`
}

type tripChecklistSummaryResponse struct {
	InstanceID     string                 `json:"instanceId,omitempty"`
	UserID         string                 `json:"userId,omitempty"`
	TripID         string                 `json:"tripId"`
	Destination    model.TripDestination  `json:"destination"`
	StartAt        time.Time              `json:"startAt"`
	EndAt          time.Time              `json:"endAt"`
	TransportModes []model.TransportMode  `json:"transportModes"`
	ActivitySlugs  []string               `json:"activitySlugs"`
	HasChildren    bool                   `json:"hasChildren"`
	Readiness      model.ReadinessSummary `json:"readiness"`
	ItemCount      int                    `json:"itemCount"`
	GeneratedAt    time.Time              `json:"generatedAt"`
	UpdatedAt      time.Time              `json:"updatedAt,omitempty"`
}

type checklistItemResponse struct {
	ID                       string                    `json:"id"`
	Category                 model.ChecklistCategory   `json:"category"`
	Priority                 model.ChecklistPriority   `json:"priority"`
	Status                   model.ChecklistItemStatus `json:"status"`
	AssignedUserID           string                    `json:"assignedUserId,omitempty"`
	Title                    string                    `json:"title"`
	Reason                   string                    `json:"reason"`
	TrustLevel               model.TrustLevel          `json:"trustLevel"`
	Source                   model.Source              `json:"source"`
	RequiresUserConfirmation bool                      `json:"requiresUserConfirmation"`
	DeadlineAt               *time.Time                `json:"deadlineAt,omitempty"`
}

type customChecklistItemResponse struct {
	ID                 string                    `json:"id"`
	Title              string                    `json:"title"`
	Note               string                    `json:"note"`
	Category           model.ChecklistCategory   `json:"category"`
	Priority           model.ChecklistPriority   `json:"priority"`
	Status             model.ChecklistItemStatus `json:"status"`
	AssignedUserID     string                    `json:"assignedUserId,omitempty"`
	ReuseInFuture      bool                      `json:"reuseInFuture"`
	PersonalTemplateID string                    `json:"personalTemplateId,omitempty"`
	CreatedAt          time.Time                 `json:"createdAt"`
	UpdatedAt          time.Time                 `json:"updatedAt"`
}

type seasonalProfileResponse struct {
	Destination         model.TripDestination   `json:"destination"`
	Month               int                     `json:"month"`
	TemperatureBand     model.TemperatureBand   `json:"temperatureBand"`
	PrecipitationBand   model.PrecipitationBand `json:"precipitationBand"`
	SkyBand             model.SkyBand           `json:"skyBand"`
	RiskTags            []string                `json:"riskTags"`
	PackingImplications []string                `json:"packingImplications"`
	Source              model.Source            `json:"source"`
}

type trustNoticeResponse struct {
	Code    string `json:"code"`
	Title   string `json:"title"`
	Message string `json:"message"`
}

type carryItemResponse struct {
	ItemSlug             string            `json:"itemSlug"`
	CarryOn              model.CarryPolicy `json:"carryOn"`
	CheckedBaggage       model.CarryPolicy `json:"checkedBaggage"`
	RequiresAirlineCheck bool              `json:"requiresAirlineCheck"`
	ConditionSummary     string            `json:"conditionSummary"`
	Source               model.Source      `json:"source"`
}

type checklistItemFeedbackResponse struct {
	ID                  string                      `json:"id"`
	ChecklistInstanceID string                      `json:"checklistInstanceId"`
	UserID              string                      `json:"userId"`
	TripID              string                      `json:"tripId"`
	ItemID              string                      `json:"itemId"`
	Type                model.ChecklistFeedbackType `json:"type"`
	Comment             string                      `json:"comment"`
	CreatedAt           time.Time                   `json:"createdAt"`
}

type checklistReminderResponse struct {
	ID         string                        `json:"id"`
	OffsetDays int                           `json:"offsetDays"`
	DueAt      time.Time                     `json:"dueAt"`
	Status     model.ChecklistReminderStatus `json:"status"`
	Title      string                        `json:"title"`
	Message    string                        `json:"message"`
}

type personalChecklistTemplateResponse struct {
	ID        string                  `json:"id"`
	Title     string                  `json:"title"`
	Note      string                  `json:"note"`
	Category  model.ChecklistCategory `json:"category"`
	Priority  model.ChecklistPriority `json:"priority"`
	IsActive  bool                    `json:"isActive"`
	CreatedAt time.Time               `json:"createdAt"`
	UpdatedAt time.Time               `json:"updatedAt"`
}

func mapTripChecklist(checklist model.TripChecklist, lang string) tripChecklistResponse {
	items := make([]checklistItemResponse, len(checklist.Items))
	for i, item := range checklist.Items {
		items[i] = checklistItemResponse{
			ID:                       item.ID,
			Category:                 item.Category,
			Priority:                 item.Priority,
			Status:                   item.Status,
			AssignedUserID:           item.AssignedUserID,
			Title:                    item.Title.Get(lang),
			Reason:                   item.Reason.Get(lang),
			TrustLevel:               item.TrustLevel,
			Source:                   item.Source,
			RequiresUserConfirmation: item.RequiresUserConfirmation,
			DeadlineAt:               item.DeadlineAt,
		}
	}
	customItems := make([]customChecklistItemResponse, len(checklist.CustomItems))
	for i, item := range checklist.CustomItems {
		customItems[i] = mapCustomChecklistItem(item)
	}

	return tripChecklistResponse{
		InstanceID:       checklist.InstanceID,
		UserID:           checklist.UserID,
		TripID:           checklist.TripID,
		Items:            items,
		CustomItems:      customItems,
		Readiness:        checklist.Readiness,
		PersonalProgress: checklist.PersonalProgress,
		SeasonalProfile:  mapSeasonalProfile(checklist.SeasonalProfile, lang),
		TrustNotice: trustNoticeResponse{
			Code:    checklist.TrustNotice.Code,
			Title:   checklist.TrustNotice.Title.Get(lang),
			Message: checklist.TrustNotice.Message.Get(lang),
		},
		GeneratedAt: checklist.GeneratedAt,
		UpdatedAt:   checklist.UpdatedAt,
	}
}

func mapTripChecklistSummary(checklist model.TripChecklist) tripChecklistSummaryResponse {
	return tripChecklistSummaryResponse{
		InstanceID:     checklist.InstanceID,
		UserID:         checklist.UserID,
		TripID:         checklist.TripID,
		Destination:    checklist.Destination,
		StartAt:        checklist.StartAt,
		EndAt:          checklist.EndAt,
		TransportModes: append([]model.TransportMode(nil), checklist.TransportModes...),
		ActivitySlugs:  append([]string(nil), checklist.ActivitySlugs...),
		HasChildren:    checklist.TravelerProfile.HasChildren,
		Readiness:      checklist.Readiness,
		ItemCount:      len(checklist.Items) + len(checklist.CustomItems),
		GeneratedAt:    checklist.GeneratedAt,
		UpdatedAt:      checklist.UpdatedAt,
	}
}

func mapCustomChecklistItem(item model.CustomChecklistItem) customChecklistItemResponse {
	return customChecklistItemResponse{
		ID:                 item.ID,
		Title:              item.Title,
		Note:               item.Note,
		Category:           item.Category,
		Priority:           item.Priority,
		Status:             item.Status,
		AssignedUserID:     item.AssignedUserID,
		ReuseInFuture:      item.ReuseInFuture,
		PersonalTemplateID: item.PersonalTemplateID,
		CreatedAt:          item.CreatedAt,
		UpdatedAt:          item.UpdatedAt,
	}
}

func mapSeasonalProfile(profile *model.SeasonalProfile, lang string) *seasonalProfileResponse {
	if profile == nil {
		return nil
	}

	implications := make([]string, len(profile.PackingImplications))
	for i, implication := range profile.PackingImplications {
		implications[i] = implication.Get(lang)
	}

	return &seasonalProfileResponse{
		Destination:         profile.Destination,
		Month:               int(profile.Month),
		TemperatureBand:     profile.TemperatureBand,
		PrecipitationBand:   profile.PrecipitationBand,
		SkyBand:             profile.SkyBand,
		RiskTags:            profile.RiskTags,
		PackingImplications: implications,
		Source:              profile.Source,
	}
}

func mapCarryItem(match app.CarryItemMatch, lang string) carryItemResponse {
	return carryItemResponse{
		ItemSlug:             match.ItemSlug,
		CarryOn:              match.CarryOn,
		CheckedBaggage:       match.CheckedBaggage,
		RequiresAirlineCheck: match.RequiresAirlineCheck,
		ConditionSummary:     match.ConditionSummary.Get(lang),
		Source:               match.Source,
	}
}

func mapChecklistItemFeedback(feedback model.ChecklistItemFeedback) checklistItemFeedbackResponse {
	return checklistItemFeedbackResponse{
		ID:                  feedback.ID,
		ChecklistInstanceID: feedback.ChecklistInstanceID,
		UserID:              feedback.UserID,
		TripID:              feedback.TripID,
		ItemID:              feedback.ItemID,
		Type:                feedback.FeedbackType,
		Comment:             feedback.Comment,
		CreatedAt:           feedback.CreatedAt,
	}
}

func mapChecklistReminder(reminder model.ChecklistReminder, lang string) checklistReminderResponse {
	return checklistReminderResponse{
		ID:         reminder.ID,
		OffsetDays: reminder.OffsetDays,
		DueAt:      reminder.DueAt,
		Status:     reminder.Status,
		Title:      reminder.Title.Get(lang),
		Message:    reminder.Message.Get(lang),
	}
}

func mapPersonalChecklistTemplate(template model.PersonalChecklistTemplate) personalChecklistTemplateResponse {
	return personalChecklistTemplateResponse{
		ID:        template.ID,
		Title:     template.Title,
		Note:      template.Note,
		Category:  template.Category,
		Priority:  template.Priority,
		IsActive:  template.IsActive,
		CreatedAt: template.CreatedAt,
		UpdatedAt: template.UpdatedAt,
	}
}

func mapTransportModes(values []string) []model.TransportMode {
	out := make([]model.TransportMode, 0, len(values))
	for _, value := range values {
		normalized := strings.ToLower(strings.TrimSpace(value))
		if normalized == "" {
			continue
		}
		out = append(out, model.TransportMode(normalized))
	}
	return out
}

func parseLang(r *http.Request, fallback string) string {
	if lang := normalizeLang(r.URL.Query().Get("lang")); lang != "" {
		return lang
	}
	if lang := normalizeLang(fallback); lang != "" {
		return lang
	}
	if lang := normalizeLang(r.Header.Get("X-Language")); lang != "" {
		return lang
	}
	if lang := normalizeLang(r.Header.Get("Accept-Language")); lang != "" {
		return lang
	}
	return "ru"
}

func normalizeLang(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	switch {
	case strings.HasPrefix(value, "en"):
		return "en"
	case strings.HasPrefix(value, "kk"):
		return "kk"
	case strings.HasPrefix(value, "ru"):
		return "ru"
	default:
		return ""
	}
}

func (h *Handler) parseTripPreviewRequest(
	w http.ResponseWriter,
	r *http.Request,
) (tripPreviewRequest, time.Time, time.Time, bool) {
	var req tripPreviewRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "checklist.invalid_json", "Invalid JSON body")
		return tripPreviewRequest{}, time.Time{}, time.Time{}, false
	}

	startAt, err := time.Parse(time.RFC3339, strings.TrimSpace(req.StartAt))
	if err != nil {
		writeError(w, http.StatusBadRequest, "checklist.invalid_start_at", "startAt must be RFC3339")
		return tripPreviewRequest{}, time.Time{}, time.Time{}, false
	}
	endAt, err := time.Parse(time.RFC3339, strings.TrimSpace(req.EndAt))
	if err != nil {
		writeError(w, http.StatusBadRequest, "checklist.invalid_end_at", "endAt must be RFC3339")
		return tripPreviewRequest{}, time.Time{}, time.Time{}, false
	}
	if endAt.Before(startAt) {
		writeError(w, http.StatusBadRequest, "checklist.invalid_dates", "endAt must be after startAt")
		return tripPreviewRequest{}, time.Time{}, time.Time{}, false
	}

	return req, startAt, endAt, true
}

func tripPreviewInput(
	req tripPreviewRequest,
	startAt time.Time,
	endAt time.Time,
	userID string,
	lang string,
) app.GenerateTripChecklistInput {
	return app.GenerateTripChecklistInput{
		UserID:         strings.TrimSpace(userID),
		TripID:         strings.TrimSpace(req.TripID),
		Destination:    req.Destination.toModel(),
		StartAt:        startAt,
		EndAt:          endAt,
		TransportModes: mapTransportModes(req.TransportModes),
		ActivitySlugs:  req.ActivitySlugs,
		TravelerProfile: model.TravelerProfile{
			HasChildren:            req.TravelerProfile.HasChildren,
			CitizenshipCountryCode: strings.ToUpper(strings.TrimSpace(req.TravelerProfile.CitizenshipCountryCode)),
			PreferredLanguage:      lang,
		},
	}
}

func trustedUserID(r *http.Request) string {
	return strings.TrimSpace(r.Header.Get("X-User-Id"))
}

func trustedUserRoles(r *http.Request) []string {
	raw := strings.TrimSpace(r.Header.Get("X-User-Roles"))
	if raw == "" {
		return nil
	}
	parts := strings.FieldsFunc(raw, func(r rune) bool {
		return r == ',' || r == ' ' || r == ';'
	})
	roles := make([]string, 0, len(parts))
	for _, part := range parts {
		role := strings.ToUpper(strings.TrimSpace(part))
		if role != "" {
			roles = append(roles, role)
		}
	}
	return roles
}

func hasAnyRole(userRoles []string, allowed ...string) bool {
	allowedSet := make(map[string]struct{}, len(allowed))
	for _, role := range allowed {
		allowedSet[strings.ToUpper(strings.TrimSpace(role))] = struct{}{}
	}
	for _, role := range userRoles {
		if _, ok := allowedSet[strings.ToUpper(strings.TrimSpace(role))]; ok {
			return true
		}
	}
	return false
}

func writeChecklistAppError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, app.ErrChecklistUserRequired):
		writeError(w, http.StatusUnauthorized, "checklist.authentication_required", "Authentication required")
	case errors.Is(err, app.ErrChecklistTripRequired):
		writeError(w, http.StatusBadRequest, "checklist.trip_required", "tripId is required")
	case errors.Is(err, app.ErrInvalidChecklistItemStatus):
		writeError(w, http.StatusBadRequest, "checklist.invalid_item_status", "Invalid checklist item status")
	case errors.Is(err, app.ErrInvalidChecklistFeedback):
		writeError(w, http.StatusBadRequest, "checklist.invalid_feedback", "Invalid checklist feedback")
	case errors.Is(err, app.ErrInvalidCustomChecklistItem):
		writeError(w, http.StatusBadRequest, "checklist.invalid_custom_item", "Invalid custom checklist item")
	case errors.Is(err, app.ErrChecklistAssignmentForbidden):
		writeError(w, http.StatusForbidden, "checklist.assignment_forbidden", "Checklist item assignment is forbidden")
	case errors.Is(err, app.ErrCustomChecklistItemNotFound):
		writeError(w, http.StatusNotFound, "checklist.custom_item_not_found", "Custom checklist item not found")
	case errors.Is(err, app.ErrChecklistNotFound), errors.Is(err, app.ErrChecklistItemNotFound):
		writeError(w, http.StatusNotFound, "checklist.not_found", "Checklist item not found")
	default:
		writeError(w, http.StatusInternalServerError, "checklist.technical", "Checklist operation failed")
	}
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, code string, message string) {
	writeJSON(w, status, map[string]string{
		"code":    code,
		"error":   message,
		"message": message,
		"kind":    "business",
	})
}
