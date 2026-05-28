package http

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/stories-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/stories-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/stories-service/internal/transport/dto"
)

type Handler struct {
	useCase *app.StoryUseCase
}

func NewHandler(useCase *app.StoryUseCase) *Handler {
	return &Handler{useCase: useCase}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /v1/stories", h.ListStories)
	mux.HandleFunc("POST /v1/stories", h.CreateStory)
	mux.HandleFunc("GET /v1/stories/mine", h.ListMyStories)
	mux.HandleFunc("GET /v1/public/stories/", h.GetPublicStoryBySlug)
	mux.HandleFunc("GET /v1/stories/", h.handleStoryActions)
	mux.HandleFunc("POST /v1/stories/", h.handleStoryActions)
	mux.HandleFunc("PATCH /v1/stories/", h.handleStoryActions)
	mux.HandleFunc("DELETE /v1/stories/", h.handleStoryActions)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status": "ok",
	})
}

func (h *Handler) ListStories(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()

	var authorID *uuid.UUID
	if raw := strings.TrimSpace(query.Get("authorId")); raw != "" {
		parsed, err := uuid.Parse(raw)
		if err != nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidAuthorID)
			return
		}
		authorID = &parsed
	}

	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListStories(r.Context(), SubjectFromContext(r.Context()), app.ListStoriesInput{
		Search:      query.Get("search"),
		Category:    splitCSV(query.Get("category")),
		Place:       query.Get("place"),
		CountryCode: query.Get("countryCode"),
		CityID:      query.Get("cityId"),
		AuthorID:    authorID,
		Sort:        query.Get("sort"),
		Limit:       limit,
		Offset:      offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.StoryListResponse{
		Items: make([]*dto.StoryResponse, 0, len(items)),
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toStoryResponse(item, false))
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListMyStories(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListStories(r.Context(), SubjectFromContext(r.Context()), app.ListStoriesInput{
		Search:      query.Get("search"),
		Category:    splitCSV(query.Get("category")),
		Place:       query.Get("place"),
		CountryCode: query.Get("countryCode"),
		CityID:      query.Get("cityId"),
		Sort:        query.Get("sort"),
		Limit:       limit,
		Offset:      offset,
		IncludeMine: true,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.StoryListResponse{
		Items: make([]*dto.StoryResponse, 0, len(items)),
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toStoryResponse(item, false))
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) CreateStory(w http.ResponseWriter, r *http.Request) {
	var req dto.CreateStoryRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	coverFileID, err := parseOptionalUUID(req.CoverFileID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCoverFileID)
		return
	}

	item, err := h.useCase.CreateStory(r.Context(), SubjectFromContext(r.Context()), app.CreateStoryInput{
		Title:            req.Title,
		Content:          req.Content,
		Category:         enum.StoryCategory(req.Category),
		Status:           enum.StoryStatus(req.Status),
		CoverFileID:      coverFileID,
		PlaceName:        req.PlaceName,
		PlaceCountryCode: req.PlaceCountryCode,
		PlaceCityID:      req.PlaceCityID,
		Tags:             req.Tags,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusCreated, toStoryResponse(item, true))
}

func (h *Handler) GetPublicStoryBySlug(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/public/stories/")
	slug := strings.TrimSpace(strings.Trim(path, "/"))
	if slug == "" {
		writeError(w, r, http.StatusNotFound, errorCodeNotFound)
		return
	}

	detail, err := h.useCase.GetStoryBySlug(r.Context(), slug, SubjectFromContext(r.Context()))
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toStoryDetailResponse(detail))
}

func (h *Handler) handleStoryActions(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/stories/")
	path = strings.Trim(path, "/")
	if path == "" || path == "mine" {
		writeError(w, r, http.StatusNotFound, errorCodeNotFound)
		return
	}

	parts := strings.Split(path, "/")
	if parts[0] == "users" {
		h.handleStoryUserActions(w, r, parts)
		return
	}

	storyID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidStoryID)
		return
	}

	if len(parts) == 1 {
		h.handleStoryRoot(w, r, storyID)
		return
	}

	switch parts[1] {
	case "views":
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.TrackStoryView(w, r, storyID)
			return
		}
	case "likes":
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.LikeStory(w, r, storyID)
			return
		}
		if len(parts) == 2 && r.Method == http.MethodDelete {
			h.UnlikeStory(w, r, storyID)
			return
		}
	case "comments":
		if len(parts) == 2 && r.Method == http.MethodGet {
			h.ListComments(w, r, storyID)
			return
		}
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.CreateComment(w, r, storyID)
			return
		}
		if len(parts) == 3 {
			commentID, parseErr := uuid.Parse(parts[2])
			if parseErr != nil {
				writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommentID)
				return
			}
			if r.Method == http.MethodPatch {
				h.UpdateComment(w, r, storyID, commentID)
				return
			}
			if r.Method == http.MethodDelete {
				h.DeleteComment(w, r, storyID, commentID)
				return
			}
		}
		if len(parts) == 4 && parts[3] == "likes" {
			commentID, parseErr := uuid.Parse(parts[2])
			if parseErr != nil {
				writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommentID)
				return
			}
			if r.Method == http.MethodPost {
				h.LikeComment(w, r, storyID, commentID)
				return
			}
			if r.Method == http.MethodDelete {
				h.UnlikeComment(w, r, storyID, commentID)
				return
			}
		}
	case "share":
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.ShareStory(w, r, storyID)
			return
		}
	}

	writeError(w, r, http.StatusNotFound, errorCodeNotFound)
}

func (h *Handler) handleStoryUserActions(w http.ResponseWriter, r *http.Request, parts []string) {
	if r.Method != http.MethodGet ||
		len(parts) != 3 ||
		parts[2] != "published-count" {
		writeError(w, r, http.StatusNotFound, errorCodeNotFound)
		return
	}

	authorID, err := uuid.Parse(parts[1])
	if err != nil || authorID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidUserID)
		return
	}

	count, err := h.useCase.CountPublishedStoriesByAuthorID(r.Context(), authorID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.PublishedStoryCountResponse{
		UserID:           authorID.String(),
		PublishedStories: count,
	})
}

func (h *Handler) handleStoryRoot(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	switch r.Method {
	case http.MethodGet:
		h.GetStoryByID(w, r, storyID)
	case http.MethodPatch:
		h.UpdateStory(w, r, storyID)
	case http.MethodDelete:
		h.DeleteStory(w, r, storyID)
	default:
		writeError(w, r, http.StatusNotFound, errorCodeNotFound)
	}
}

func (h *Handler) GetStoryByID(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	item, err := h.useCase.GetStoryByID(r.Context(), SubjectFromContext(r.Context()), storyID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toStoryResponse(item, true))
}

func (h *Handler) UpdateStory(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	var req dto.UpdateStoryRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	coverFileID, err := parseOptionalUUID(req.CoverFileID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCoverFileID)
		return
	}

	item, err := h.useCase.UpdateStory(r.Context(), SubjectFromContext(r.Context()), storyID, app.UpdateStoryInput{
		Title:            req.Title,
		Content:          req.Content,
		Category:         enum.StoryCategory(req.Category),
		Status:           enum.StoryStatus(req.Status),
		CoverFileID:      coverFileID,
		PlaceName:        req.PlaceName,
		PlaceCountryCode: req.PlaceCountryCode,
		PlaceCityID:      req.PlaceCityID,
		Tags:             req.Tags,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toStoryResponse(item, true))
}

func (h *Handler) DeleteStory(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	if err := h.useCase.DeleteStory(r.Context(), SubjectFromContext(r.Context()), storyID); err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) TrackStoryView(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	count, err := h.useCase.TrackStoryView(r.Context(), SubjectFromContext(r.Context()), storyID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.ViewResponse{Views: count})
}

func (h *Handler) LikeStory(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	count, err := h.useCase.LikeStory(r.Context(), SubjectFromContext(r.Context()), storyID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.LikeResponse{Likes: count})
}

func (h *Handler) UnlikeStory(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	count, err := h.useCase.UnlikeStory(r.Context(), SubjectFromContext(r.Context()), storyID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.LikeResponse{Likes: count})
}

func (h *Handler) ListComments(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListComments(r.Context(), SubjectFromContext(r.Context()), storyID, limit, offset)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := make([]*dto.StoryCommentResponse, 0, len(items))
	for _, item := range items {
		resp = append(resp, toStoryCommentResponse(item))
	}

	writeJSON(w, http.StatusOK, map[string]any{"items": resp})
}

func (h *Handler) CreateComment(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	var req dto.CreateCommentRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	item, err := h.useCase.CreateComment(r.Context(), SubjectFromContext(r.Context()), storyID, req.Body)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusCreated, toStoryCommentResponse(item))
}

func (h *Handler) UpdateComment(w http.ResponseWriter, r *http.Request, storyID uuid.UUID, commentID uuid.UUID) {
	var req dto.UpdateCommentRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	item, err := h.useCase.UpdateComment(r.Context(), SubjectFromContext(r.Context()), storyID, commentID, req.Body)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toStoryCommentResponse(item))
}

func (h *Handler) DeleteComment(w http.ResponseWriter, r *http.Request, storyID uuid.UUID, commentID uuid.UUID) {
	if err := h.useCase.DeleteComment(r.Context(), SubjectFromContext(r.Context()), storyID, commentID); err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) LikeComment(w http.ResponseWriter, r *http.Request, storyID uuid.UUID, commentID uuid.UUID) {
	count, likedByMe, err := h.useCase.LikeComment(r.Context(), SubjectFromContext(r.Context()), storyID, commentID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.CommentLikeResponse{
		Likes:     count,
		LikedByMe: likedByMe,
	})
}

func (h *Handler) UnlikeComment(w http.ResponseWriter, r *http.Request, storyID uuid.UUID, commentID uuid.UUID) {
	count, likedByMe, err := h.useCase.UnlikeComment(r.Context(), SubjectFromContext(r.Context()), storyID, commentID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.CommentLikeResponse{
		Likes:     count,
		LikedByMe: likedByMe,
	})
}

func (h *Handler) ShareStory(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	shareURL, count, err := h.useCase.ShareStory(r.Context(), storyID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.ShareResponse{
		ShareURL: shareURL,
		Shares:   count,
	})
}

func toStoryResponse(item *app.StoryView, includeContent bool) *dto.StoryResponse {
	if item == nil || item.Story == nil {
		return nil
	}

	var coverFileID *string
	if item.Story.CoverFileID != nil {
		v := item.Story.CoverFileID.String()
		coverFileID = &v
	}

	var content *string
	if includeContent {
		v := item.Story.Content
		content = &v
	}

	var publishedAt *string
	if item.Story.PublishedAt != nil {
		v := item.Story.PublishedAt.UTC().Format(time.RFC3339)
		publishedAt = &v
	}

	return &dto.StoryResponse{
		ID:               item.Story.ID.String(),
		Slug:             item.Story.Slug,
		Title:            item.Story.Title,
		Excerpt:          item.Story.Excerpt,
		Content:          content,
		Category:         string(item.Story.Category),
		Status:           string(item.Story.Status),
		CoverFileID:      coverFileID,
		PlaceName:        item.Story.PlaceName,
		PlaceCountryCode: item.Story.PlaceCountryCode,
		PlaceCityID:      item.Story.PlaceCityID,
		Tags:             item.Story.Tags,
		Stats: dto.StoryStatsResponse{
			Views:    item.Story.ViewCount,
			Likes:    item.Story.LikeCount,
			Comments: item.Story.CommentCount,
			Shares:   item.Story.ShareCount,
		},
		Author:        toAuthorResponse(item.Author),
		LikedByViewer: item.LikedByViewer,
		ShareURL:      item.ShareURL,
		PublishedAt:   publishedAt,
		CreatedAt:     item.Story.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:     item.Story.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toStoryCommentResponse(item *app.StoryCommentView) *dto.StoryCommentResponse {
	if item == nil || item.Comment == nil {
		return nil
	}

	return &dto.StoryCommentResponse{
		ID:        item.Comment.ID.String(),
		StoryID:   item.Comment.StoryID.String(),
		Body:      item.Comment.Body,
		Editable:  item.Editable,
		Deletable: item.Deletable,
		Edited:    item.Comment.IsEdited(),
		Likes:     item.Comment.LikeCount,
		LikedByMe: item.LikedByViewer,
		ShareURL:  item.ShareURL,
		Author:    toAuthorResponse(item.Author),
		CreatedAt: item.Comment.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt: item.Comment.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toStoryDetailResponse(detail *app.StoryDetail) *dto.StoryDetailResponse {
	if detail == nil {
		return nil
	}

	resp := &dto.StoryDetailResponse{
		Story:    toStoryResponse(detail.Story, true),
		Related:  make([]*dto.StoryResponse, 0, len(detail.Related)),
		Comments: make([]*dto.StoryCommentResponse, 0, len(detail.Comments)),
	}

	for _, item := range detail.Related {
		resp.Related = append(resp.Related, toStoryResponse(item, false))
	}
	for _, item := range detail.Comments {
		resp.Comments = append(resp.Comments, toStoryCommentResponse(item))
	}

	return resp
}

func toAuthorResponse(author app.StoryAuthor) dto.AuthorResponse {
	var avatarFileID *string
	if author.AvatarFileID != nil {
		v := author.AvatarFileID.String()
		avatarFileID = &v
	}

	return dto.AuthorResponse{
		UserID:       author.UserID.String(),
		DisplayName:  author.DisplayName,
		AvatarFileID: avatarFileID,
		CountryCode:  author.CountryCode,
		Locale:       author.Locale,
		Timezone:     author.Timezone,
	}
}

func parsePagination(w http.ResponseWriter, r *http.Request, rawLimit string, rawOffset string) (int, int, bool) {
	limit := 20
	offset := 0

	if strings.TrimSpace(rawLimit) != "" {
		parsed, err := strconv.Atoi(strings.TrimSpace(rawLimit))
		if err != nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidLimit)
			return 0, 0, false
		}
		limit = parsed
	}

	if strings.TrimSpace(rawOffset) != "" {
		parsed, err := strconv.Atoi(strings.TrimSpace(rawOffset))
		if err != nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidOffset)
			return 0, 0, false
		}
		offset = parsed
	}

	return limit, offset, true
}

func parseOptionalUUID(raw *string) (*uuid.UUID, error) {
	if raw == nil || strings.TrimSpace(*raw) == "" {
		return nil, nil
	}

	parsed, err := uuid.Parse(strings.TrimSpace(*raw))
	if err != nil {
		return nil, err
	}
	return &parsed, nil
}

func decodeBody(r *http.Request, target any) error {
	if r.Body == nil {
		return errors.New("missing request body")
	}
	if err := json.NewDecoder(r.Body).Decode(target); err != nil {
		if errors.Is(err, io.EOF) {
			return errors.New("missing request body")
		}
		return errors.New("invalid request body")
	}
	return nil
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(statusCode int) {
	rw.statusCode = statusCode
	rw.ResponseWriter.WriteHeader(statusCode)
}
