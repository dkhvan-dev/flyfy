package http

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/app"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
	"kz/inflap/backend/services/activity-service/internal/transport/dto"
)

func (h *Handler) SaveActivityReviews(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	actorUserID, err := resolveActorUserID(r.Context(), h.actorResolver)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return
	}

	var req dto.SaveActivityReviewsRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	result, err := h.activityUC.SaveActivityReviews(r.Context(), app.SaveActivityReviewsInput{
		ActorUserID:     actorUserID,
		ActivityID:      activityID,
		ActivityReview:  toActivityReviewMutationInput(req.ActivityReview),
		OrganizerReview: toActivityReviewMutationInput(req.OrganizerReview),
	})
	if err != nil {
		h.writeAppError(w, err, "failed to save activity reviews")
		return
	}

	writeJSON(w, http.StatusOK, toActivityReviewsResponse(result))
}

func (h *Handler) ListActivityReviews(w http.ResponseWriter, r *http.Request) {
	filter := port.ActivityReviewFilter{}
	if !applyActivityReviewCommonQuery(w, r, &filter.ActivityID, &filter.HostUserID, &filter.Sort) {
		return
	}
	h.writeActivityReviews(w, r, filter)
}

func (h *Handler) ListActivityReviewsByActivityID(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	h.writeActivityReviews(w, r, port.ActivityReviewFilter{ActivityID: &activityID})
}

func (h *Handler) writeActivityReviews(w http.ResponseWriter, r *http.Request, filter port.ActivityReviewFilter) {
	requestedLimit := activityReviewRequestedLimit(r)
	filter.Limit = requestedLimit + 1
	filter.Offset = parseIntOrDefault(r.URL.Query().Get("offset"), 0)
	items, err := h.activityUC.ListActivityReviews(r.Context(), filter)
	if err != nil {
		h.writeAppError(w, err, "failed to list activity reviews")
		return
	}
	writeJSON(w, http.StatusOK, toActivityReviewListResponse(items, requestedLimit))
}

func (h *Handler) ListActivityOrganizerReviews(w http.ResponseWriter, r *http.Request) {
	filter := port.ActivityOrganizerReviewFilter{}
	if !applyActivityReviewCommonQuery(w, r, &filter.ActivityID, &filter.HostUserID, &filter.Sort) {
		return
	}
	h.writeActivityOrganizerReviews(w, r, filter)
}

func (h *Handler) ListActivityOrganizerReviewsByActivityID(w http.ResponseWriter, r *http.Request, activityID uuid.UUID) {
	h.writeActivityOrganizerReviews(w, r, port.ActivityOrganizerReviewFilter{ActivityID: &activityID})
}

func (h *Handler) writeActivityOrganizerReviews(w http.ResponseWriter, r *http.Request, filter port.ActivityOrganizerReviewFilter) {
	requestedLimit := activityReviewRequestedLimit(r)
	filter.Limit = requestedLimit + 1
	filter.Offset = parseIntOrDefault(r.URL.Query().Get("offset"), 0)
	items, err := h.activityUC.ListActivityOrganizerReviews(r.Context(), filter)
	if err != nil {
		h.writeAppError(w, err, "failed to list activity organizer reviews")
		return
	}
	writeJSON(w, http.StatusOK, toActivityOrganizerReviewListResponse(items, requestedLimit))
}

func applyActivityReviewCommonQuery(
	w http.ResponseWriter,
	r *http.Request,
	activityID **uuid.UUID,
	hostUserID **uuid.UUID,
	sort *port.ActivityReviewSort,
) bool {
	if rawActivityID := strings.TrimSpace(r.URL.Query().Get("activityId")); rawActivityID != "" {
		parsed, err := uuid.Parse(rawActivityID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid activity id")
			return false
		}
		*activityID = &parsed
	}
	if rawHostUserID := strings.TrimSpace(r.URL.Query().Get("hostUserId")); rawHostUserID != "" {
		parsed, err := uuid.Parse(rawHostUserID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid host user id")
			return false
		}
		*hostUserID = &parsed
	}
	if rawSort := strings.TrimSpace(r.URL.Query().Get("sort")); rawSort != "" {
		switch port.ActivityReviewSort(rawSort) {
		case port.ActivityReviewSortLatest, port.ActivityReviewSortRatingDesc:
			*sort = port.ActivityReviewSort(rawSort)
		default:
			writeError(w, http.StatusBadRequest, "invalid activity review sort")
			return false
		}
	}
	return true
}

func activityReviewRequestedLimit(r *http.Request) int {
	requestedLimit := parseIntOrDefault(r.URL.Query().Get("limit"), 20)
	if requestedLimit <= 0 {
		return 20
	}
	if requestedLimit > 100 {
		return 100
	}
	return requestedLimit
}

func toActivityReviewMutationInput(req *dto.ActivityReviewMutationRequest) *app.ActivityReviewMutationInput {
	if req == nil {
		return nil
	}
	return &app.ActivityReviewMutationInput{
		Rating:  req.Rating,
		Comment: req.Comment,
		Delete:  req.Delete,
	}
}

func toActivityReviewsResponse(result *app.ActivityReviewsResult) dto.ActivityReviewsResponse {
	if result == nil {
		return dto.ActivityReviewsResponse{}
	}
	return dto.ActivityReviewsResponse{
		ActivityReview:  toActivityReviewResponse(result.ActivityReview),
		OrganizerReview: toActivityOrganizerReviewResponse(result.OrganizerReview),
	}
}

func toActivityReviewListResponse(items []*model.ActivityReview, requestedLimit int) dto.ActivityReviewListResponse {
	hasMore := len(items) > requestedLimit
	if hasMore {
		items = items[:requestedLimit]
	}

	result := make([]dto.ActivityReviewResponse, 0, len(items))
	for _, item := range items {
		response := toActivityReviewResponse(item)
		if response == nil {
			continue
		}
		result = append(result, *response)
	}
	return dto.ActivityReviewListResponse{Items: result, HasMore: hasMore}
}

func toActivityOrganizerReviewListResponse(
	items []*model.ActivityOrganizerReview,
	requestedLimit int,
) dto.ActivityOrganizerReviewListResponse {
	hasMore := len(items) > requestedLimit
	if hasMore {
		items = items[:requestedLimit]
	}

	result := make([]dto.ActivityOrganizerReviewResponse, 0, len(items))
	for _, item := range items {
		response := toActivityOrganizerReviewResponse(item)
		if response == nil {
			continue
		}
		result = append(result, *response)
	}
	return dto.ActivityOrganizerReviewListResponse{Items: result, HasMore: hasMore}
}

func toActivityReviewResponse(item *model.ActivityReview) *dto.ActivityReviewResponse {
	if item == nil {
		return nil
	}
	return &dto.ActivityReviewResponse{
		ID:            item.ID.String(),
		ParticipantID: item.ParticipantID.String(),
		ActivityID:    item.ActivityID.String(),
		HostUserID:    item.HostUserID.String(),
		AuthorUserID:  item.AuthorUserID.String(),
		Author:        toActivityReviewAuthorResponse(item.Author, item.AuthorUserID),
		Rating:        item.Rating,
		Comment:       item.Comment,
		SourceLabel:   "ACTIVITY",
		CreatedAt:     item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:     item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toActivityOrganizerReviewResponse(item *model.ActivityOrganizerReview) *dto.ActivityOrganizerReviewResponse {
	if item == nil {
		return nil
	}
	return &dto.ActivityOrganizerReviewResponse{
		ID:            item.ID.String(),
		ParticipantID: item.ParticipantID.String(),
		ActivityID:    item.ActivityID.String(),
		HostUserID:    item.HostUserID.String(),
		AuthorUserID:  item.AuthorUserID.String(),
		Author:        toActivityReviewAuthorResponse(item.Author, item.AuthorUserID),
		Rating:        item.Rating,
		Comment:       item.Comment,
		SourceLabel:   "ACTIVITY_ORGANIZER",
		CreatedAt:     item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:     item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toActivityReviewAuthorResponse(
	author model.ActivityReviewAuthor,
	fallbackUserID uuid.UUID,
) dto.ActivityReviewAuthorResponse {
	userID := author.UserID
	if userID == uuid.Nil {
		userID = fallbackUserID
	}
	return dto.ActivityReviewAuthorResponse{
		UserID:       userID.String(),
		Nickname:     author.Nickname,
		AvatarFileID: formatOptionalUUID(author.AvatarFileID),
	}
}
