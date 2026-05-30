package http

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/transport/dto"
)

func (h *Handler) ListAdminFlaggedActivities(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.requireActivityModerator(w, r, false); !ok {
		return
	}
	limit := parsePositiveInt(r.URL.Query().Get("limit"), 100)
	offset := parsePositiveInt(r.URL.Query().Get("offset"), 0)
	items, err := h.activityUC.ListFlaggedForModeration(r.Context(), limit, offset)
	if err != nil {
		h.writeAppError(w, err, "failed to list activity moderation queue")
		return
	}
	resp := dto.AdminActivityModerationListResponse{
		Items: make([]dto.AdminActivityModerationResponse, 0, len(items)),
	}
	for _, item := range items {
		view, buildErr := h.toAdminActivityModerationResponse(r.Context(), item)
		if buildErr != nil {
			writeError(w, http.StatusInternalServerError, "failed to build activity moderation response")
			return
		}
		resp.Items = append(resp.Items, view)
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) handleAdminActivityRoutes(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/admin/activities/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}
	parts := strings.Split(path, "/")
	activityID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid activity id")
		return
	}
	if len(parts) == 1 && r.Method == http.MethodGet {
		h.GetAdminActivity(w, r, activityID)
		return
	}
	if len(parts) == 3 && parts[1] == "moderation" && r.Method == http.MethodPost {
		switch parts[2] {
		case "approve":
			h.ApproveAdminActivityModeration(w, r, activityID)
			return
		case "reject":
			h.RejectAdminActivityModeration(w, r, activityID)
			return
		}
	}
	writeError(w, http.StatusNotFound, "not found")
}

func (h *Handler) GetAdminActivity(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	if _, ok := h.requireActivityModerator(w, r, false); !ok {
		return
	}
	item, err := h.activityUC.GetActivityByID(r.Context(), activityID)
	if err != nil {
		h.writeAppError(w, err, "failed to get activity")
		return
	}
	resp, err := h.toAdminActivityModerationResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity moderation response")
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ApproveAdminActivityModeration(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorID, ok := h.requireActivityModerator(w, r, true)
	if !ok {
		return
	}
	item, err := h.activityUC.ApproveModeration(r.Context(), activityID, actorID)
	if err != nil {
		h.writeAppError(w, err, "failed to approve activity moderation")
		return
	}
	resp, err := h.toAdminActivityModerationResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity moderation response")
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) RejectAdminActivityModeration(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorID, ok := h.requireActivityModerator(w, r, true)
	if !ok {
		return
	}
	var req dto.RejectActivityModerationRequest
	if r.Body != nil && r.Body != http.NoBody {
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid request body")
			return
		}
	}
	item, err := h.activityUC.RejectModeration(r.Context(), activityID, actorID, req.PublicComment)
	if err != nil {
		h.writeAppError(w, err, "failed to reject activity moderation")
		return
	}
	resp, err := h.toAdminActivityModerationResponse(r.Context(), item)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build activity moderation response")
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) requireActivityModerator(w http.ResponseWriter, r *http.Request, requireActor bool) (uuid.UUID, bool) {
	if h.internalToken != "" {
		token := strings.TrimSpace(r.Header.Get("X-Internal-Service-Token"))
		if token == "" {
			token = bearerToken(r.Header.Get("Authorization"))
		}
		if token != h.internalToken {
			writeError(w, http.StatusForbidden, "invalid internal service token")
			return uuid.Nil, false
		}
	}
	if !hasAnyRole(RolesFromContext(r.Context()), "SUPER_ADMIN", "ADMIN", "MODERATION_LEAD", "ACTIVITY_MODERATOR") {
		writeError(w, http.StatusForbidden, "activity moderation permission required")
		return uuid.Nil, false
	}
	actorID, err := uuid.Parse(UserIDFromContext(r.Context()))
	if err != nil || actorID == uuid.Nil {
		if !requireActor {
			return uuid.Nil, true
		}
		writeError(w, http.StatusUnauthorized, "missing admin actor")
		return uuid.Nil, false
	}
	return actorID, true
}

func (h *Handler) toAdminActivityModerationResponse(ctx context.Context, item *model.Activity) (dto.AdminActivityModerationResponse, error) {
	base, err := h.toActivityResponse(ctx, item)
	if err != nil {
		return dto.AdminActivityModerationResponse{}, err
	}
	hostDisplayName := ""
	if resolver, ok := h.actorResolver.(interface {
		DisplayNameForUserID(context.Context, uuid.UUID) (string, error)
	}); ok {
		hostDisplayName, _ = resolver.DisplayNameForUserID(ctx, item.HostUserID)
	}
	category, subcategory := activityModerationTaxonomyLabels(item)
	return dto.AdminActivityModerationResponse{
		ActivityResponse:         base,
		ModerationRiskScore:      item.ModerationRiskScore,
		ModerationReasonCodes:    item.ModerationReasonCodes,
		ModerationTriggeredAt:    formatOptionalTime(item.ModerationTriggeredAt),
		ModerationReviewedAt:     formatOptionalTime(item.ModerationReviewedAt),
		AuthorCountryCode:        item.AuthorCountryCode,
		AuthorCityID:             item.AuthorCityID,
		AuthorCityName:           item.AuthorCityName,
		AuthorLocationCapturedAt: formatOptionalTime(item.AuthorLocationCapturedAt),
		HostDisplayName:          strings.TrimSpace(hostDisplayName),
		CategoryName:             category.Name,
		CategoryNameRu:           category.NameRu,
		CategoryNameKk:           category.NameKk,
		SubcategoryName:          subcategory.Name,
		SubcategoryNameRu:        subcategory.NameRu,
		SubcategoryNameKk:        subcategory.NameKk,
	}, nil
}

func activityModerationTaxonomyLabels(item *model.Activity) (model.ActivityCategory, model.ActivityTaxonomyItem) {
	if item == nil {
		return model.ActivityCategory{}, model.ActivityTaxonomyItem{}
	}
	categorySlug := model.NormalizeActivityCategorySlug(item.CategorySlug)
	var category model.ActivityCategory
	for _, candidate := range model.ListActivityCategories() {
		if candidate.Slug == categorySlug {
			category = candidate
			break
		}
	}
	if category.Slug == "" || item.SubcategorySlug == nil {
		return category, model.ActivityTaxonomyItem{}
	}
	subcategorySlug := strings.ToLower(strings.TrimSpace(*item.SubcategorySlug))
	if subcategorySlug == "" {
		return category, model.ActivityTaxonomyItem{}
	}
	for _, candidate := range category.Subcategories {
		if strings.ToLower(strings.TrimSpace(candidate.Slug)) == subcategorySlug {
			return category, candidate
		}
	}
	return category, model.ActivityTaxonomyItem{}
}

func hasAnyRole(actual []string, allowed ...string) bool {
	seen := make(map[string]struct{}, len(actual))
	for _, role := range actual {
		seen[strings.ToUpper(strings.TrimSpace(role))] = struct{}{}
	}
	for _, role := range allowed {
		if _, ok := seen[strings.ToUpper(strings.TrimSpace(role))]; ok {
			return true
		}
	}
	return false
}

func bearerToken(raw string) string {
	raw = strings.TrimSpace(raw)
	if len(raw) > 7 && strings.EqualFold(raw[:7], "Bearer ") {
		return strings.TrimSpace(raw[7:])
	}
	return ""
}

func parsePositiveInt(raw string, fallback int) int {
	value, err := strconv.Atoi(strings.TrimSpace(raw))
	if err != nil || value < 0 {
		return fallback
	}
	return value
}
