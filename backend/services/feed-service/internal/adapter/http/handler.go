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

	"kz/inflap/backend/services/feed-service/internal/app"
	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
	"kz/inflap/backend/services/feed-service/internal/transport/dto"
)

type Handler struct {
	useCase *app.PostUseCase
}

func NewHandler(useCase *app.PostUseCase) *Handler {
	return &Handler{
		useCase: useCase,
	}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /internal/v1/feed/quality-metrics", h.ListAdminFeedQualityMetrics)
	mux.HandleFunc("POST /internal/v1/feed/social-events", h.ApplyInternalFeedSocialEvent)
	mux.HandleFunc("POST /internal/v1/communities", h.CreateAdminCommunity)
	mux.HandleFunc("GET /internal/v1/communities/{communityID}", h.GetAdminCommunity)
	mux.HandleFunc("PATCH /internal/v1/communities/{communityID}", h.UpdateAdminCommunity)
	mux.HandleFunc("GET /internal/v1/community-post-profiles", h.ListAdminCommunityPostProfiles)
	mux.HandleFunc("GET /internal/v1/community-blueprints", h.ListAdminCommunityBlueprints)
	mux.HandleFunc("GET /internal/v1/community-geo-hubs", h.ListAdminCommunityGeoHubs)
	mux.HandleFunc("GET /internal/v1/community-instances", h.ListAdminCommunityInstances)
	mux.HandleFunc("POST /internal/v1/community-instances/materialize", h.MaterializeAdminCommunityInstances)
	mux.HandleFunc("GET /internal/v1/moderation/community-posts", h.ListAdminCommunityModerationPosts)
	mux.HandleFunc("GET /internal/v1/moderation/community-posts/", h.handleAdminCommunityPostModerationActions)
	mux.HandleFunc("POST /internal/v1/moderation/community-posts/", h.handleAdminCommunityPostModerationActions)
	mux.HandleFunc("GET /internal/v1/moderation/post-reports", h.ListAdminPostReports)
	mux.HandleFunc("GET /internal/v1/moderation/post-reports/", h.handleAdminPostReportActions)
	mux.HandleFunc("POST /internal/v1/moderation/post-reports/", h.handleAdminPostReportActions)
	mux.HandleFunc("GET /v1/feed", h.GetFeed)
	mux.HandleFunc("POST /v1/feed/events", h.TrackFeedEvents)
	mux.HandleFunc("GET /v1/communities", h.ListCommunities)
	mux.HandleFunc("GET /v1/communities/", h.handleCommunityActions)
	mux.HandleFunc("POST /v1/communities/", h.handleCommunityActions)
	mux.HandleFunc("PATCH /v1/communities/", h.handleCommunityActions)
	mux.HandleFunc("DELETE /v1/communities/", h.handleCommunityActions)
	mux.HandleFunc("GET /v1/posts", h.ListPosts)
	mux.HandleFunc("POST /v1/posts", h.CreatePost)
	mux.HandleFunc("GET /v1/posts/create-eligibility", h.CheckPostCreateEligibility)
	mux.HandleFunc("GET /v1/posts/mine", h.ListMyPosts)
	mux.HandleFunc("GET /v1/stories/mine/active", h.ListMyActiveStories)
	mux.HandleFunc("GET /v1/stories/mine/archive", h.ListMyArchivedStories)
	mux.HandleFunc("POST /v1/stories", h.CreateStory)
	mux.HandleFunc("POST /v1/stories/", h.handleStoryActions)
	mux.HandleFunc("GET /v1/public/posts/", h.GetPublicPostBySlug)
	mux.HandleFunc("GET /v1/posts/", h.handlePostActions)
	mux.HandleFunc("POST /v1/posts/", h.handlePostActions)
	mux.HandleFunc("PATCH /v1/posts/", h.handlePostActions)
	mux.HandleFunc("DELETE /v1/posts/", h.handlePostActions)
}

func (h *Handler) ApplyInternalFeedSocialEvent(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusUnauthorized, errorCodeUnauthenticatedWriter)
		return
	}
	if r.Method != http.MethodPost {
		writeError(w, r, http.StatusMethodNotAllowed, errorCodeInvalidFeedEvent)
		return
	}

	var req applyFeedSocialEventRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil && !errors.Is(err, io.EOF) {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidFeedEvent)
		return
	}
	input, ok := req.toInput()
	if !ok {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidFeedEvent)
		return
	}
	if err := h.useCase.ApplyFeedSocialEvent(r.Context(), input); err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}
	writeJSON(w, http.StatusAccepted, map[string]any{"accepted": true})
}

func (h *Handler) ListAdminFeedQualityMetrics(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	since, ok := parseOptionalRFC3339Query(w, r, query.Get("since"))
	if !ok {
		return
	}
	until, ok := parseOptionalRFC3339Query(w, r, query.Get("until"))
	if !ok {
		return
	}
	limit := 0
	if strings.TrimSpace(query.Get("limit")) != "" {
		parsed, err := strconv.Atoi(strings.TrimSpace(query.Get("limit")))
		if err != nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidLimit)
			return
		}
		limit = parsed
	}

	metrics, err := h.useCase.ListFeedQualityMetrics(r.Context(), app.ListFeedQualityMetricsInput{
		Since:   since,
		Until:   until,
		Surface: query.Get("surface"),
		Limit:   limit,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	items := make([]feedQualityMetricResponse, 0, len(metrics))
	for _, metric := range metrics {
		items = append(items, feedQualityMetricResponse{
			Surface:            metric.Surface,
			Tab:                metric.Tab,
			BlockType:          metric.BlockType,
			RankingExperiment:  metric.RankingExperiment,
			CandidateSource:    metric.CandidateSource,
			PostProfile:        metric.PostProfile,
			CommunityID:        metric.CommunityID,
			Action:             metric.Action,
			EventCount:         metric.EventCount,
			UniqueViewers:      metric.UniqueViewers,
			ImpressionCount:    metric.ImpressionCount,
			ClickCount:         metric.ClickCount,
			DwellCount:         metric.DwellCount,
			AvgDwellMs:         metric.AvgDwellMs,
			LikeCount:          metric.LikeCount,
			CommentCount:       metric.CommentCount,
			ShareCount:         metric.ShareCount,
			SubscribeCount:     metric.SubscribeCount,
			ConversionCount:    metric.ConversionCount,
			HideCount:          metric.HideCount,
			NotInterestedCount: metric.NotInterestedCount,
			ReportCount:        metric.ReportCount,
		})
	}
	writeJSON(w, http.StatusOK, feedQualityMetricsResponse{Items: items})
}

type feedQualityMetricsResponse struct {
	Items []feedQualityMetricResponse `json:"items"`
}

type applyFeedSocialEventRequest struct {
	EventID         string `json:"eventId"`
	ViewerUserID    string `json:"viewerUserId"`
	TargetUserID    string `json:"targetUserId"`
	EdgeType        string `json:"edgeType"`
	Active          bool   `json:"active"`
	SourceUpdatedAt string `json:"sourceUpdatedAt"`
}

func (r applyFeedSocialEventRequest) toInput() (app.ApplyFeedSocialEventInput, bool) {
	eventID, err := uuid.Parse(strings.TrimSpace(r.EventID))
	if err != nil {
		return app.ApplyFeedSocialEventInput{}, false
	}
	viewerUserID, err := uuid.Parse(strings.TrimSpace(r.ViewerUserID))
	if err != nil {
		return app.ApplyFeedSocialEventInput{}, false
	}
	targetUserID, err := uuid.Parse(strings.TrimSpace(r.TargetUserID))
	if err != nil {
		return app.ApplyFeedSocialEventInput{}, false
	}
	sourceUpdatedAt := time.Time{}
	if raw := strings.TrimSpace(r.SourceUpdatedAt); raw != "" {
		parsed, parseErr := time.Parse(time.RFC3339Nano, raw)
		if parseErr != nil {
			return app.ApplyFeedSocialEventInput{}, false
		}
		sourceUpdatedAt = parsed
	}

	return app.ApplyFeedSocialEventInput{
		EventID:         eventID,
		ViewerUserID:    viewerUserID,
		TargetUserID:    targetUserID,
		EdgeType:        r.EdgeType,
		Active:          r.Active,
		SourceUpdatedAt: sourceUpdatedAt,
	}, true
}

type feedQualityMetricResponse struct {
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
}

func (h *Handler) GetFeed(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	limit := 20
	if strings.TrimSpace(query.Get("limit")) != "" {
		parsed, err := strconv.Atoi(strings.TrimSpace(query.Get("limit")))
		if err != nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidLimit)
			return
		}
		limit = parsed
	}

	page, err := h.useCase.BuildFeed(r.Context(), SubjectFromContext(r.Context()), app.BuildFeedInput{
		Surface:     query.Get("surface"),
		Tab:         query.Get("tab"),
		Cursor:      query.Get("cursor"),
		CountryCode: query.Get("countryCode"),
		CityID:      query.Get("cityId"),
		Limit:       limit,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toFeedResponse(page))
}

func (h *Handler) TrackFeedEvents(w http.ResponseWriter, r *http.Request) {
	var req dto.TrackFeedEventsRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	input, ok := feedEventsInputFromRequest(w, r, req)
	if !ok {
		return
	}
	accepted, err := h.useCase.TrackFeedEvents(r.Context(), SubjectFromContext(r.Context()), input)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusAccepted, dto.TrackFeedEventsResponse{Accepted: accepted})
}

func (h *Handler) ListCommunities(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListCommunities(r.Context(), SubjectFromContext(r.Context()), app.ListCommunitiesInput{
		Topic:           query.Get("topic"),
		CountryCode:     query.Get("countryCode"),
		CityID:          query.Get("cityId"),
		Search:          firstNonEmpty(query.Get("search"), query.Get("q")),
		ExcludeFollowed: parseQueryBool(query.Get("excludeFollowed")),
		OnlyFollowed:    parseQueryBool(query.Get("onlyFollowed")),
		Limit:           limit,
		Offset:          offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.CommunityListResponse{
		Items:  make([]*dto.CommunityResponse, 0, len(items)),
		Limit:  limit,
		Offset: offset,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toCommunityResponse(item))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) CreateAdminCommunity(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusForbidden, errorCodeCommunityModerationDenied)
		return
	}
	actorID, ok := h.adminActorID(w, r)
	if !ok {
		return
	}

	var req dto.CreateCommunityRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	avatarFileID, err := parseOptionalUUID(req.AvatarFileID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCoverFileID)
		return
	}
	coverFileID, err := parseOptionalUUID(req.CoverFileID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCoverFileID)
		return
	}

	item, err := h.useCase.CreateCommunity(r.Context(), app.CreateCommunityInput{
		Slug:             req.Slug,
		TitleI18n:        req.TitleI18n,
		DescriptionI18n:  req.DescriptionI18n,
		RulesI18n:        req.RulesI18n,
		Topic:            req.Topic,
		CityID:           req.CityID,
		CountryCode:      req.CountryCode,
		AvatarFileID:     avatarFileID,
		CoverFileID:      coverFileID,
		Visibility:       req.Visibility,
		PostingPolicy:    req.PostingPolicy,
		Status:           req.Status,
		CreatedByAdminID: actorID,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusCreated, toCommunityResponse(item))
}

func (h *Handler) GetAdminCommunity(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusForbidden, errorCodeCommunityModerationDenied)
		return
	}
	communityID, err := uuid.Parse(strings.TrimSpace(r.PathValue("communityID")))
	if err != nil || communityID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommunityID)
		return
	}
	item, err := h.useCase.GetAdminCommunity(r.Context(), communityID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toCommunityResponse(item))
}

func (h *Handler) UpdateAdminCommunity(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusForbidden, errorCodeCommunityModerationDenied)
		return
	}
	actorID, ok := h.adminActorID(w, r)
	if !ok {
		return
	}
	communityID, err := uuid.Parse(strings.TrimSpace(r.PathValue("communityID")))
	if err != nil || communityID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommunityID)
		return
	}

	var req dto.CreateCommunityRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}
	avatarFileID, err := parseOptionalUUID(req.AvatarFileID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCoverFileID)
		return
	}
	coverFileID, err := parseOptionalUUID(req.CoverFileID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCoverFileID)
		return
	}
	item, err := h.useCase.UpdateCommunity(r.Context(), app.UpdateCommunityInput{
		CommunityID:      communityID,
		Slug:             req.Slug,
		TitleI18n:        req.TitleI18n,
		DescriptionI18n:  req.DescriptionI18n,
		RulesI18n:        req.RulesI18n,
		Topic:            req.Topic,
		CityID:           req.CityID,
		CountryCode:      req.CountryCode,
		AvatarFileID:     avatarFileID,
		CoverFileID:      coverFileID,
		Visibility:       req.Visibility,
		PostingPolicy:    req.PostingPolicy,
		Status:           req.Status,
		UpdatedByAdminID: actorID,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toCommunityResponse(item))
}

func (h *Handler) adminActorID(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	actorID, err := uuid.Parse(strings.TrimSpace(UserIDFromContext(r.Context())))
	if err != nil || actorID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidUserID)
		return uuid.Nil, false
	}
	return actorID, true
}

func (h *Handler) ListAdminCommunityPostProfiles(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusForbidden, errorCodeCommunityModerationDenied)
		return
	}
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListCommunityPostProfiles(r.Context(), app.ListCommunityPostProfilesInput{
		PostKind: query.Get("postKind"),
		Limit:    limit,
		Offset:   offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.CommunityPostProfileListResponse{
		Items:  make([]*dto.CommunityPostProfileResponse, 0, len(items)),
		Limit:  limit,
		Offset: offset,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toCommunityPostProfileResponse(item))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListAdminCommunityBlueprints(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusForbidden, errorCodeCommunityModerationDenied)
		return
	}
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListCommunityBlueprints(r.Context(), app.ListCommunityBlueprintsInput{
		Category:      query.Get("category"),
		Search:        firstNonEmpty(query.Get("search"), query.Get("q")),
		PostProfile:   query.Get("postProfile"),
		RolloutPolicy: query.Get("rolloutPolicy"),
		Status:        query.Get("status"),
		Limit:         limit,
		Offset:        offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.CommunityBlueprintListResponse{
		Items:  make([]*dto.CommunityBlueprintResponse, 0, len(items)),
		Limit:  limit,
		Offset: offset,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toCommunityBlueprintResponse(item))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListAdminCommunityGeoHubs(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusForbidden, errorCodeCommunityModerationDenied)
		return
	}
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}
	var communityEnabled *bool
	if raw := strings.TrimSpace(query.Get("communityEnabled")); raw != "" {
		parsed := parseQueryBool(raw)
		communityEnabled = &parsed
	}

	items, err := h.useCase.ListCommunityGeoHubs(r.Context(), app.ListCommunityGeoHubsInput{
		CountryCode:      query.Get("countryCode"),
		CityID:           query.Get("cityId"),
		HubTier:          query.Get("hubTier"),
		CommunityEnabled: communityEnabled,
		IncludeAliasOnly: parseQueryBool(query.Get("includeAliasOnly")),
		Limit:            limit,
		Offset:           offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.CommunityGeoHubListResponse{
		Items:  make([]*dto.CommunityGeoHubResponse, 0, len(items)),
		Limit:  limit,
		Offset: offset,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toCommunityGeoHubResponse(item))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListAdminCommunityInstances(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusForbidden, errorCodeCommunityModerationDenied)
		return
	}
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}
	var blueprintID uuid.UUID
	if raw := strings.TrimSpace(query.Get("blueprintId")); raw != "" {
		parsed, err := uuid.Parse(raw)
		if err != nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
			return
		}
		blueprintID = parsed
	}

	items, err := h.useCase.ListCommunityInstances(r.Context(), app.ListCommunityInstancesInput{
		BlueprintID: blueprintID,
		CountryCode: query.Get("countryCode"),
		CityID:      query.Get("cityId"),
		ScopeType:   query.Get("scopeType"),
		Status:      query.Get("status"),
		Search:      firstNonEmpty(query.Get("search"), query.Get("q")),
		Limit:       limit,
		Offset:      offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.CommunityInstanceListResponse{
		Items:  make([]*dto.CommunityInstanceResponse, 0, len(items)),
		Limit:  limit,
		Offset: offset,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toCommunityInstanceResponse(item))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) MaterializeAdminCommunityInstances(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusForbidden, errorCodeCommunityModerationDenied)
		return
	}
	var req dto.MaterializeCommunityInstancesRequest
	if err := decodeOptionalBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	var blueprintID uuid.UUID
	if raw := strings.TrimSpace(req.BlueprintID); raw != "" {
		parsed, err := uuid.Parse(raw)
		if err != nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
			return
		}
		blueprintID = parsed
	}

	result, err := h.useCase.MaterializeCommunityInstances(r.Context(), app.MaterializeCommunityInstancesInput{
		BlueprintID: blueprintID,
		CountryCode: req.CountryCode,
		CityID:      req.CityID,
		ScopeType:   req.ScopeType,
		Limit:       req.Limit,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}
	if result == nil {
		result = &model.CommunityInstanceMaterializationResult{}
	}
	writeJSON(w, http.StatusOK, dto.MaterializeCommunityInstancesResponse{
		MaterializedCount: result.MaterializedCount,
	})
}

func (h *Handler) handleCommunityActions(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/communities/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, r, http.StatusNotFound, errorCodeNotFound)
		return
	}

	parts := strings.Split(path, "/")
	communityID, err := uuid.Parse(parts[0])
	if err != nil || communityID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommunityID)
		return
	}

	if len(parts) == 1 && r.Method == http.MethodGet {
		item, err := h.useCase.GetCommunity(r.Context(), SubjectFromContext(r.Context()), communityID)
		if err != nil {
			h.writeUseCaseError(w, r, err)
			return
		}
		writeJSON(w, http.StatusOK, toCommunityResponse(item))
		return
	}

	if len(parts) >= 3 && parts[1] == "moderation" && parts[2] == "posts" {
		h.handleCommunityModerationPostActions(w, r, communityID, parts[3:])
		return
	}

	if len(parts) >= 3 && parts[1] == "moderation" && parts[2] == "reports" {
		h.handleCommunityModerationReportActions(w, r, communityID, parts[3:])
		return
	}

	if len(parts) == 2 && parts[1] == "members" && r.Method == http.MethodGet {
		h.ListCommunityMembers(w, r, communityID)
		return
	}

	if len(parts) == 4 && parts[1] == "members" && parts[3] == "role-changes" && r.Method == http.MethodGet {
		userID, err := uuid.Parse(parts[2])
		if err != nil || userID == uuid.Nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidUserID)
			return
		}
		h.ListCommunityMemberRoleChanges(w, r, communityID, userID)
		return
	}

	if len(parts) == 4 && parts[1] == "members" && parts[3] == "role" && r.Method == http.MethodPatch {
		userID, err := uuid.Parse(parts[2])
		if err != nil || userID == uuid.Nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidUserID)
			return
		}
		h.UpdateCommunityMemberRole(w, r, communityID, userID)
		return
	}

	if len(parts) == 4 && parts[1] == "members" && parts[3] == "status" && r.Method == http.MethodPatch {
		userID, err := uuid.Parse(parts[2])
		if err != nil || userID == uuid.Nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidUserID)
			return
		}
		h.UpdateCommunityMemberStatus(w, r, communityID, userID)
		return
	}

	if len(parts) == 2 && parts[1] == "follow" {
		switch r.Method {
		case http.MethodPost:
			item, err := h.useCase.FollowCommunity(r.Context(), SubjectFromContext(r.Context()), communityID)
			if err != nil {
				h.writeUseCaseError(w, r, err)
				return
			}
			writeJSON(w, http.StatusOK, toCommunityResponse(item))
			return
		case http.MethodDelete:
			item, err := h.useCase.UnfollowCommunity(r.Context(), SubjectFromContext(r.Context()), communityID)
			if err != nil {
				h.writeUseCaseError(w, r, err)
				return
			}
			writeJSON(w, http.StatusOK, toCommunityResponse(item))
			return
		}
	}

	if len(parts) == 2 && parts[1] == "report" && r.Method == http.MethodPost {
		h.ReportCommunity(w, r, communityID)
		return
	}

	if len(parts) == 2 && parts[1] == "mute" {
		switch r.Method {
		case http.MethodPost:
			item, err := h.useCase.MuteCommunity(r.Context(), SubjectFromContext(r.Context()), communityID)
			if err != nil {
				h.writeUseCaseError(w, r, err)
				return
			}
			writeJSON(w, http.StatusOK, toCommunityResponse(item))
			return
		case http.MethodDelete:
			item, err := h.useCase.UnmuteCommunity(r.Context(), SubjectFromContext(r.Context()), communityID)
			if err != nil {
				h.writeUseCaseError(w, r, err)
				return
			}
			writeJSON(w, http.StatusOK, toCommunityResponse(item))
			return
		}
	}

	writeError(w, r, http.StatusNotFound, errorCodeNotFound)
}

func (h *Handler) ReportCommunity(w http.ResponseWriter, r *http.Request, communityID uuid.UUID) {
	var req dto.ReportCommunityRequest
	if err := decodeOptionalBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}
	result, err := h.useCase.SubmitCommunityReport(r.Context(), SubjectFromContext(r.Context()), app.SubmitCommunityReportInput{
		CommunityID: communityID,
		Reason:      req.Reason,
		Details:     req.Details,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, toCommunityReportSubmissionResponse(result))
}

func (h *Handler) UpdateCommunityMemberRole(w http.ResponseWriter, r *http.Request, communityID uuid.UUID, userID uuid.UUID) {
	var req dto.UpdateCommunityMemberRoleRequest
	if err := decodeOptionalBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	item, err := h.useCase.UpdateCommunityMemberRole(r.Context(), SubjectFromContext(r.Context()), app.UpdateCommunityMemberRoleInput{
		CommunityID: communityID,
		UserID:      userID,
		Role:        req.Role,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toCommunityMembershipResponse(item))
}

func (h *Handler) UpdateCommunityMemberStatus(w http.ResponseWriter, r *http.Request, communityID uuid.UUID, userID uuid.UUID) {
	var req dto.UpdateCommunityMemberStatusRequest
	if err := decodeOptionalBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	item, err := h.useCase.UpdateCommunityMemberStatus(r.Context(), SubjectFromContext(r.Context()), app.UpdateCommunityMemberStatusInput{
		CommunityID: communityID,
		UserID:      userID,
		Status:      req.Status,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toCommunityMembershipResponse(item))
}

func (h *Handler) ListCommunityMembers(w http.ResponseWriter, r *http.Request, communityID uuid.UUID) {
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListCommunityMembers(r.Context(), SubjectFromContext(r.Context()), app.ListCommunityMembersInput{
		CommunityID: communityID,
		Role:        query.Get("role"),
		Status:      query.Get("status"),
		Limit:       limit,
		Offset:      offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.CommunityMemberListResponse{
		Items:   make([]*dto.CommunityMemberResponse, 0, len(items)),
		Limit:   limit,
		Offset:  offset,
		HasMore: limit > 0 && len(items) == limit,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toCommunityMemberResponse(item))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListCommunityMemberRoleChanges(w http.ResponseWriter, r *http.Request, communityID uuid.UUID, userID uuid.UUID) {
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListCommunityMemberRoleChanges(
		r.Context(),
		SubjectFromContext(r.Context()),
		app.ListCommunityMemberRoleChangesInput{
			CommunityID: communityID,
			UserID:      userID,
			Limit:       limit,
			Offset:      offset,
		},
	)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.CommunityMemberRoleChangeListResponse{
		Items:   make([]*dto.CommunityMemberRoleChangeResponse, 0, len(items)),
		Limit:   limit,
		Offset:  offset,
		HasMore: limit > 0 && len(items) == limit,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toCommunityMemberRoleChangeResponse(item))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) handleCommunityModerationPostActions(w http.ResponseWriter, r *http.Request, communityID uuid.UUID, parts []string) {
	if len(parts) == 0 && r.Method == http.MethodGet {
		h.ListCommunityModerationPosts(w, r, communityID)
		return
	}

	if len(parts) == 2 && parts[1] == "decisions" && r.Method == http.MethodGet {
		postID, err := uuid.Parse(parts[0])
		if err != nil || postID == uuid.Nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidPostID)
			return
		}
		h.ListCommunityPostModerationDecisions(w, r, communityID, postID)
		return
	}

	if len(parts) == 2 && r.Method == http.MethodPost {
		postID, err := uuid.Parse(parts[0])
		if err != nil || postID == uuid.Nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidPostID)
			return
		}
		switch parts[1] {
		case "approve", "reject":
			h.ReviewCommunityPost(w, r, communityID, postID, parts[1])
			return
		}
	}

	writeError(w, r, http.StatusNotFound, errorCodeNotFound)
}

func (h *Handler) ListCommunityModerationPosts(w http.ResponseWriter, r *http.Request, communityID uuid.UUID) {
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListCommunityModerationPosts(r.Context(), SubjectFromContext(r.Context()), app.ListCommunityModerationPostsInput{
		CommunityID: communityID,
		Limit:       limit,
		Offset:      offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.CommunityModerationPostListResponse{
		Items:   make([]*dto.PostResponse, 0, len(items)),
		Limit:   limit,
		Offset:  offset,
		HasMore: limit > 0 && len(items) == limit,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toPostResponse(item, false))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ReviewCommunityPost(w http.ResponseWriter, r *http.Request, communityID uuid.UUID, postID uuid.UUID, decision string) {
	var req dto.ReviewCommunityPostRequest
	if err := decodeOptionalBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	item, err := h.useCase.ReviewCommunityPost(r.Context(), SubjectFromContext(r.Context()), postID, app.ReviewCommunityPostInput{
		CommunityID: communityID,
		Decision:    decision,
		Reason:      req.Reason,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toPostResponse(item, false))
}

func (h *Handler) ListCommunityPostModerationDecisions(w http.ResponseWriter, r *http.Request, communityID uuid.UUID, postID uuid.UUID) {
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListCommunityPostModerationDecisions(r.Context(), SubjectFromContext(r.Context()), app.ListCommunityPostModerationDecisionsInput{
		CommunityID: communityID,
		PostID:      postID,
		Limit:       limit,
		Offset:      offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.PostModerationDecisionListResponse{
		Items:   make([]*dto.PostModerationDecisionResponse, 0, len(items)),
		Limit:   limit,
		Offset:  offset,
		HasMore: limit > 0 && len(items) == limit,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toPostModerationDecisionResponse(item))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) handleCommunityModerationReportActions(w http.ResponseWriter, r *http.Request, communityID uuid.UUID, parts []string) {
	if len(parts) == 0 && r.Method == http.MethodGet {
		h.ListCommunityPostReports(w, r, communityID)
		return
	}

	if len(parts) == 2 && r.Method == http.MethodPost {
		reportID, err := uuid.Parse(parts[0])
		if err != nil || reportID == uuid.Nil {
			writeError(w, r, http.StatusBadRequest, errorCodeNotFound)
			return
		}
		switch parts[1] {
		case "review", "dismiss":
			h.ResolveCommunityPostReport(w, r, communityID, reportID, parts[1])
			return
		}
	}

	writeError(w, r, http.StatusNotFound, errorCodeNotFound)
}

func (h *Handler) ListCommunityPostReports(w http.ResponseWriter, r *http.Request, communityID uuid.UUID) {
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListCommunityPostReports(r.Context(), SubjectFromContext(r.Context()), app.ListCommunityPostReportsInput{
		CommunityID: communityID,
		Status:      query.Get("status"),
		Limit:       limit,
		Offset:      offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.PostReportListResponse{
		Items:   make([]*dto.PostReportResponse, 0, len(items)),
		Limit:   limit,
		Offset:  offset,
		HasMore: limit > 0 && len(items) == limit,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toPostReportResponse(item))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ResolveCommunityPostReport(w http.ResponseWriter, r *http.Request, communityID uuid.UUID, reportID uuid.UUID, decision string) {
	var req dto.ResolvePostReportRequest
	if err := decodeOptionalBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	item, err := h.useCase.ResolveCommunityPostReport(r.Context(), SubjectFromContext(r.Context()), app.ResolveCommunityPostReportInput{
		CommunityID:    communityID,
		ReportID:       reportID,
		Decision:       decision,
		ResolutionNote: req.ResolutionNote,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toPostReportResponse(item))
}

func (h *Handler) handleAdminPostReportActions(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/internal/v1/moderation/post-reports/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, r, http.StatusNotFound, errorCodeNotFound)
		return
	}
	parts := strings.Split(path, "/")
	reportID, err := uuid.Parse(parts[0])
	if err != nil || reportID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, errorCodeNotFound)
		return
	}
	if len(parts) == 1 && r.Method == http.MethodGet {
		h.GetAdminPostReport(w, r, reportID)
		return
	}
	if len(parts) == 2 && r.Method == http.MethodPost {
		switch parts[1] {
		case "review", "dismiss":
			h.ResolveAdminPostReport(w, r, reportID, parts[1])
			return
		}
	}
	writeError(w, r, http.StatusNotFound, errorCodeNotFound)
}

func (h *Handler) handleAdminCommunityPostModerationActions(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/internal/v1/moderation/community-posts/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, r, http.StatusNotFound, errorCodeNotFound)
		return
	}
	parts := strings.Split(path, "/")
	postID, err := uuid.Parse(parts[0])
	if err != nil || postID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidPostID)
		return
	}
	if len(parts) == 1 && r.Method == http.MethodGet {
		h.GetAdminCommunityModerationPost(w, r, postID)
		return
	}
	if len(parts) == 2 && r.Method == http.MethodPost {
		switch parts[1] {
		case "approve", "reject":
			h.ReviewAdminCommunityModerationPost(w, r, postID, parts[1])
			return
		}
	}
	writeError(w, r, http.StatusNotFound, errorCodeNotFound)
}

func (h *Handler) ListAdminPostReports(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusUnauthorized, errorCodeUnauthenticatedWriter)
		return
	}
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}
	items, err := h.useCase.ListAdminPostReports(r.Context(), app.ListAdminPostReportsInput{
		Status: query.Get("status"),
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}
	resp := &dto.PostReportListResponse{
		Items:   make([]*dto.PostReportResponse, 0, len(items)),
		Limit:   limit,
		Offset:  offset,
		HasMore: limit > 0 && len(items) == limit,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toPostReportResponse(item))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListAdminCommunityModerationPosts(w http.ResponseWriter, r *http.Request) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusUnauthorized, errorCodeUnauthenticatedWriter)
		return
	}
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}
	items, err := h.useCase.ListAdminCommunityModerationPosts(r.Context(), app.ListAdminCommunityModerationPostsInput{
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}
	resp := &dto.PostListResponse{
		Items:   make([]*dto.PostResponse, 0, len(items)),
		Limit:   limit,
		Offset:  offset,
		HasMore: limit > 0 && len(items) == limit,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toPostResponse(item, false))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) GetAdminCommunityModerationPost(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusUnauthorized, errorCodeUnauthenticatedWriter)
		return
	}
	item, err := h.useCase.GetAdminCommunityModerationPost(r.Context(), postID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toPostResponse(item, false))
}

func (h *Handler) ReviewAdminCommunityModerationPost(w http.ResponseWriter, r *http.Request, postID uuid.UUID, decision string) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusUnauthorized, errorCodeUnauthenticatedWriter)
		return
	}
	actorStaffID, err := uuid.Parse(UserIDFromContext(r.Context()))
	if err != nil || actorStaffID == uuid.Nil {
		writeError(w, r, http.StatusUnauthorized, errorCodeUnauthenticatedWriter)
		return
	}
	var req dto.ReviewCommunityPostRequest
	if err = decodeOptionalBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}
	item, err := h.useCase.ReviewAdminCommunityPost(r.Context(), app.ReviewAdminCommunityPostInput{
		PostID:       postID,
		ActorStaffID: actorStaffID,
		Decision:     decision,
		Reason:       req.Reason,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toPostResponse(item, false))
}

func (h *Handler) GetAdminPostReport(w http.ResponseWriter, r *http.Request, reportID uuid.UUID) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusUnauthorized, errorCodeUnauthenticatedWriter)
		return
	}
	item, err := h.useCase.GetAdminPostReport(r.Context(), reportID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toPostReportResponse(item))
}

func (h *Handler) ResolveAdminPostReport(w http.ResponseWriter, r *http.Request, reportID uuid.UUID, decision string) {
	if !InternalCallFromContext(r.Context()) {
		writeError(w, r, http.StatusUnauthorized, errorCodeUnauthenticatedWriter)
		return
	}
	actorStaffID, err := uuid.Parse(UserIDFromContext(r.Context()))
	if err != nil || actorStaffID == uuid.Nil {
		writeError(w, r, http.StatusUnauthorized, errorCodeUnauthenticatedWriter)
		return
	}
	var req dto.ResolvePostReportRequest
	if err = decodeOptionalBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}
	item, err := h.useCase.ResolveAdminPostReport(r.Context(), app.ResolveAdminPostReportInput{
		ReportID:       reportID,
		ActorStaffID:   actorStaffID,
		Decision:       decision,
		ResolutionNote: req.ResolutionNote,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toPostReportResponse(item))
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status": "ok",
	})
}

func (h *Handler) ListPosts(w http.ResponseWriter, r *http.Request) {
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
	var communityID *uuid.UUID
	if raw := strings.TrimSpace(query.Get("communityId")); raw != "" {
		parsed, err := uuid.Parse(raw)
		if err != nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommunityID)
			return
		}
		communityID = &parsed
	}

	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListPosts(r.Context(), SubjectFromContext(r.Context()), app.ListPostsInput{
		Search:           query.Get("search"),
		Format:           splitCSV(query.Get("format")),
		Category:         splitCSV(query.Get("category")),
		Status:           query.Get("status"),
		ModerationStatus: splitCSV(query.Get("moderationStatus")),
		Place:            query.Get("place"),
		CountryCode:      query.Get("countryCode"),
		CityID:           query.Get("cityId"),
		AuthorID:         authorID,
		CommunityID:      communityID,
		Sort:             query.Get("sort"),
		Limit:            limit,
		Offset:           offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	total, err := h.useCase.CountPosts(r.Context(), SubjectFromContext(r.Context()), app.ListPostsInput{
		Search:           query.Get("search"),
		Format:           splitCSV(query.Get("format")),
		Category:         splitCSV(query.Get("category")),
		Status:           query.Get("status"),
		ModerationStatus: splitCSV(query.Get("moderationStatus")),
		Place:            query.Get("place"),
		CountryCode:      query.Get("countryCode"),
		CityID:           query.Get("cityId"),
		AuthorID:         authorID,
		CommunityID:      communityID,
		Sort:             query.Get("sort"),
		Limit:            limit,
		Offset:           offset,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.PostListResponse{
		Items:   make([]*dto.PostResponse, 0, len(items)),
		Total:   total,
		Limit:   limit,
		Offset:  offset,
		HasMore: offset+len(items) < total,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toPostResponse(item, false))
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) ListMyPosts(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	var communityID *uuid.UUID
	if raw := strings.TrimSpace(query.Get("communityId")); raw != "" {
		parsed, err := uuid.Parse(raw)
		if err != nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommunityID)
			return
		}
		communityID = &parsed
	}
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListPosts(r.Context(), SubjectFromContext(r.Context()), app.ListPostsInput{
		Search:           query.Get("search"),
		Format:           splitCSV(query.Get("format")),
		Category:         splitCSV(query.Get("category")),
		Status:           query.Get("status"),
		ModerationStatus: splitCSV(query.Get("moderationStatus")),
		Place:            query.Get("place"),
		CountryCode:      query.Get("countryCode"),
		CityID:           query.Get("cityId"),
		CommunityID:      communityID,
		Sort:             query.Get("sort"),
		Limit:            limit,
		Offset:           offset,
		IncludeMine:      true,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	total, err := h.useCase.CountPosts(r.Context(), SubjectFromContext(r.Context()), app.ListPostsInput{
		Search:           query.Get("search"),
		Format:           splitCSV(query.Get("format")),
		Category:         splitCSV(query.Get("category")),
		Status:           query.Get("status"),
		ModerationStatus: splitCSV(query.Get("moderationStatus")),
		Place:            query.Get("place"),
		CountryCode:      query.Get("countryCode"),
		CityID:           query.Get("cityId"),
		CommunityID:      communityID,
		Sort:             query.Get("sort"),
		Limit:            limit,
		Offset:           offset,
		IncludeMine:      true,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.PostListResponse{
		Items:   make([]*dto.PostResponse, 0, len(items)),
		Total:   total,
		Limit:   limit,
		Offset:  offset,
		HasMore: offset+len(items) < total,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toPostResponse(item, false))
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) CheckPostCreateEligibility(w http.ResponseWriter, r *http.Request) {
	eligibility, err := h.useCase.CheckPostCreateEligibility(r.Context(), SubjectFromContext(r.Context()))
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	var nextAvailableAt *string
	if eligibility.NextAvailableAt != nil {
		formatted := eligibility.NextAvailableAt.UTC().Format(time.RFC3339)
		nextAvailableAt = &formatted
	}
	retryAfterSeconds := int64(0)
	if eligibility.RetryAfter > 0 {
		retryAfterSeconds = int64((eligibility.RetryAfter + time.Second - time.Nanosecond) / time.Second)
	}

	writeJSON(w, http.StatusOK, dto.PostCreateEligibilityResponse{
		CanCreate:         eligibility.CanCreate,
		Limit:             eligibility.Limit,
		Remaining:         eligibility.Remaining,
		WindowSeconds:     int64(eligibility.Window / time.Second),
		CooldownSeconds:   int64(eligibility.Cooldown / time.Second),
		BlockReason:       eligibility.BlockReason,
		RetryAfterSeconds: retryAfterSeconds,
		NextAvailableAt:   nextAvailableAt,
	})
}

func (h *Handler) CreatePost(w http.ResponseWriter, r *http.Request) {
	var req dto.CreatePostRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	coverFileID, err := parseOptionalUUID(req.CoverFileID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCoverFileID)
		return
	}
	communityID, err := parseOptionalUUID(req.CommunityID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommunityID)
		return
	}
	communityInstanceID, err := parseOptionalUUID(req.CommunityInstanceID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommunityID)
		return
	}
	expiresAt, ok := parseOptionalRFC3339Body(w, r, req.ExpiresAt)
	if !ok {
		return
	}

	item, err := h.useCase.CreatePost(r.Context(), SubjectFromContext(r.Context()), app.CreatePostInput{
		Title:               req.Title,
		Content:             req.Content,
		Format:              enum.PostFormat(req.Format),
		ContentBlocks:       req.ContentBlocks,
		Category:            enum.PostCategory(req.Category),
		Status:              enum.PostStatus(req.Status),
		CommunityID:         communityID,
		CommunityInstanceID: communityInstanceID,
		PostProfileKey:      enum.PostProfileKey(req.PostProfileKey),
		StructuredData:      req.StructuredData,
		CoverFileID:         coverFileID,
		PlaceName:           req.PlaceName,
		PlaceCountryCode:    req.PlaceCountryCode,
		PlaceCityID:         req.PlaceCityID,
		Tags:                req.Tags,
		ExpiresAt:           expiresAt,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	if item != nil && item.Post != nil && item.Post.Status == enum.PostStatusDraft {
		logPostMetric(r, postMetricDraftCreated, item.Post.ID)
	}
	writeJSON(w, http.StatusCreated, toPostResponse(item, true))
}

func (h *Handler) CreateStory(w http.ResponseWriter, r *http.Request) {
	var req dto.CreateStoryRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	mediaFileID, err := uuid.Parse(strings.TrimSpace(req.MediaFileID))
	if err != nil || mediaFileID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidPostMedia)
		return
	}
	coverFileID, err := uuid.Parse(strings.TrimSpace(req.CoverFileID))
	if err != nil || coverFileID == uuid.Nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCoverFileID)
		return
	}
	expiresAt, ok := parseOptionalRFC3339Body(w, r, req.ExpiresAt)
	if !ok {
		return
	}

	item, err := h.useCase.CreateStory(r.Context(), SubjectFromContext(r.Context()), app.CreateStoryInput{
		Caption:     req.Caption,
		MediaFileID: mediaFileID,
		CoverFileID: coverFileID,
		MediaType:   enum.PostMediaType(strings.ToUpper(strings.TrimSpace(req.MediaType))),
		ExpiresAt:   expiresAt,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusCreated, toStoryResponse(item))
}

func (h *Handler) ListMyArchivedStories(w http.ResponseWriter, r *http.Request) {
	h.listMyStories(w, r, true)
}

func (h *Handler) ListMyActiveStories(w http.ResponseWriter, r *http.Request) {
	h.listMyStories(w, r, false)
}

func (h *Handler) listMyStories(w http.ResponseWriter, r *http.Request, archived bool) {
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	input := app.ListStoriesInput{
		Limit:  limit,
		Offset: offset,
	}
	var (
		page *app.StoryListPage
		err  error
	)
	if archived {
		page, err = h.useCase.ListMyArchivedStories(r.Context(), SubjectFromContext(r.Context()), input)
	} else {
		page, err = h.useCase.ListMyActiveStories(r.Context(), SubjectFromContext(r.Context()), input)
	}
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := &dto.StoryListResponse{
		Items:   make([]*dto.StoryResponse, 0, len(page.Items)),
		Limit:   page.Limit,
		Offset:  page.Offset,
		HasMore: page.HasMore,
	}
	for _, item := range page.Items {
		resp.Items = append(resp.Items, toStoryResponse(item))
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) handleStoryActions(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/stories/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, r, http.StatusNotFound, errorCodeNotFound)
		return
	}

	parts := strings.Split(path, "/")
	storyID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidPostID)
		return
	}
	if len(parts) == 2 && parts[1] == "seen" && r.Method == http.MethodPost {
		h.MarkStorySeen(w, r, storyID)
		return
	}
	if len(parts) == 2 && parts[1] == "likes" && r.Method == http.MethodPost {
		h.LikeStory(w, r, storyID)
		return
	}

	writeError(w, r, http.StatusNotFound, errorCodeNotFound)
}

func (h *Handler) GetPublicPostBySlug(w http.ResponseWriter, r *http.Request) {
	h.getPublicPostBySlug(w, r, "/v1/public/posts/")
}

func (h *Handler) getPublicPostBySlug(w http.ResponseWriter, r *http.Request, prefix string) {
	path := strings.TrimPrefix(r.URL.Path, prefix)
	slug := strings.TrimSpace(strings.Trim(path, "/"))
	if slug == "" {
		writeError(w, r, http.StatusNotFound, errorCodeNotFound)
		return
	}

	detail, err := h.useCase.GetPostBySlug(r.Context(), slug, SubjectFromContext(r.Context()))
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toPostDetailResponse(detail))
}

func (h *Handler) handlePostActions(w http.ResponseWriter, r *http.Request) {
	h.handlePostActionsWithPrefix(w, r, "/v1/posts/")
}

func (h *Handler) handlePostActionsWithPrefix(w http.ResponseWriter, r *http.Request, prefix string) {
	path := strings.TrimPrefix(r.URL.Path, prefix)
	path = strings.Trim(path, "/")
	if path == "" || path == "mine" {
		writeError(w, r, http.StatusNotFound, errorCodeNotFound)
		return
	}

	parts := strings.Split(path, "/")
	if parts[0] == "users" {
		h.handlePostUserActions(w, r, parts)
		return
	}

	postID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidPostID)
		return
	}

	if len(parts) == 1 {
		h.handlePostRoot(w, r, postID)
		return
	}

	switch parts[1] {
	case "seen":
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.MarkPostSeen(w, r, postID)
			return
		}
	case "likes":
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.LikePost(w, r, postID)
			return
		}
		if len(parts) == 2 && r.Method == http.MethodDelete {
			h.UnlikePost(w, r, postID)
			return
		}
	case "comments":
		if len(parts) == 2 && r.Method == http.MethodGet {
			h.ListComments(w, r, postID)
			return
		}
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.CreateComment(w, r, postID)
			return
		}
		if len(parts) == 3 {
			commentID, parseErr := uuid.Parse(parts[2])
			if parseErr != nil {
				writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommentID)
				return
			}
			if r.Method == http.MethodPatch {
				h.UpdateComment(w, r, postID, commentID)
				return
			}
			if r.Method == http.MethodDelete {
				h.DeleteComment(w, r, postID, commentID)
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
				h.LikeComment(w, r, postID, commentID)
				return
			}
			if r.Method == http.MethodDelete {
				h.UnlikeComment(w, r, postID, commentID)
				return
			}
		}
	case "share":
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.SharePost(w, r, postID)
			return
		}
	case "report":
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.ReportPost(w, r, postID)
			return
		}
	case "autosave":
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.AutosavePost(w, r, postID)
			return
		}
	case "publish":
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.PublishPost(w, r, postID)
			return
		}
	case "archive":
		if len(parts) == 2 && r.Method == http.MethodPost {
			h.ArchivePost(w, r, postID)
			return
		}
	}

	writeError(w, r, http.StatusNotFound, errorCodeNotFound)
}

func (h *Handler) handlePostUserActions(w http.ResponseWriter, r *http.Request, parts []string) {
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

	count, err := h.useCase.CountPublishedPostsByAuthorID(r.Context(), authorID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.PublishedPostCountResponse{
		UserID:         authorID.String(),
		PublishedPosts: count,
	})
}

func (h *Handler) handlePostRoot(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	switch r.Method {
	case http.MethodGet:
		h.GetPostByID(w, r, postID)
	case http.MethodPatch:
		h.UpdatePost(w, r, postID)
	case http.MethodDelete:
		h.DeletePost(w, r, postID)
	default:
		writeError(w, r, http.StatusNotFound, errorCodeNotFound)
	}
}

func (h *Handler) GetPostByID(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	item, err := h.useCase.GetPostByID(r.Context(), SubjectFromContext(r.Context()), postID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toPostResponse(item, true))
}

func (h *Handler) UpdatePost(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	var req dto.UpdatePostRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	coverFileID, err := parseOptionalUUID(req.CoverFileID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCoverFileID)
		return
	}
	communityID, err := parseOptionalUUID(req.CommunityID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommunityID)
		return
	}
	communityInstanceID, err := parseOptionalUUID(req.CommunityInstanceID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommunityID)
		return
	}

	input := updatePostInputFromRequest(req, coverFileID, communityID, communityInstanceID)
	if req.Present["expiresAt"] {
		expiresAt, ok := parseOptionalRFC3339Body(w, r, req.ExpiresAt)
		if !ok {
			return
		}
		input.ExpiresAt = expiresAt
		input.ExpiresAtSet = true
	}

	item, err := h.useCase.UpdatePost(r.Context(), SubjectFromContext(r.Context()), postID, input)
	if err != nil {
		logPostUseCaseErrorMetrics(r, postID, postOperationPatch, err)
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toPostResponse(item, true))
}

func (h *Handler) AutosavePost(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	var req dto.UpdatePostRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	coverFileID, err := parseOptionalUUID(req.CoverFileID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCoverFileID)
		return
	}
	communityID, err := parseOptionalUUID(req.CommunityID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommunityID)
		return
	}
	communityInstanceID, err := parseOptionalUUID(req.CommunityInstanceID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidCommunityID)
		return
	}

	input := updatePostInputFromRequest(req, coverFileID, communityID, communityInstanceID)
	if req.Present["expiresAt"] {
		expiresAt, ok := parseOptionalRFC3339Body(w, r, req.ExpiresAt)
		if !ok {
			return
		}
		input.ExpiresAt = expiresAt
		input.ExpiresAtSet = true
	}

	item, err := h.useCase.AutosavePost(r.Context(), SubjectFromContext(r.Context()), postID, input)
	if err != nil {
		logPostUseCaseErrorMetrics(r, postID, postOperationAutosave, err)
		h.writeUseCaseError(w, r, err)
		return
	}

	logPostAutosaveSuccess(r, postID)
	writeJSON(w, http.StatusOK, toPostResponse(item, true))
}

func (h *Handler) PublishPost(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	var req dto.UpdatePostRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	item, err := h.useCase.PublishPost(r.Context(), SubjectFromContext(r.Context()), postID, req.Revision)
	if err != nil {
		logPostUseCaseErrorMetrics(r, postID, postOperationPublish, err)
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toPostResponse(item, true))
}

func (h *Handler) ArchivePost(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	var req dto.UpdatePostRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	item, err := h.useCase.ArchivePost(r.Context(), SubjectFromContext(r.Context()), postID, req.Revision)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toPostResponse(item, true))
}

func (h *Handler) DeletePost(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	if err := h.useCase.DeletePost(r.Context(), SubjectFromContext(r.Context()), postID); err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) MarkPostSeen(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	seenAt, err := h.useCase.MarkPostSeen(r.Context(), SubjectFromContext(r.Context()), postID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.PostSeenResponse{
		SeenAt: seenAt.UTC().Format(time.RFC3339),
	})
}

func (h *Handler) MarkStorySeen(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	seenAt, err := h.useCase.MarkStorySeen(r.Context(), SubjectFromContext(r.Context()), storyID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.PostSeenResponse{
		SeenAt: seenAt.UTC().Format(time.RFC3339),
	})
}

func markDeprecatedPostInteractionEndpoint(w http.ResponseWriter) {
	w.Header().Set("Deprecation", "true")
	w.Header().Add(
		"Link",
		`</docs/architecture/content-feed-platform-roadmap.md#phase-12-migration-and-deprecation>; rel="deprecation"`,
	)
}

func (h *Handler) LikePost(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	count, err := h.useCase.LikePost(r.Context(), SubjectFromContext(r.Context()), postID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.LikeResponse{Likes: count})
}

func (h *Handler) LikeStory(w http.ResponseWriter, r *http.Request, storyID uuid.UUID) {
	count, err := h.useCase.LikeStory(r.Context(), SubjectFromContext(r.Context()), storyID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.LikeResponse{Likes: count})
}

func (h *Handler) UnlikePost(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	count, err := h.useCase.UnlikePost(r.Context(), SubjectFromContext(r.Context()), postID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.LikeResponse{Likes: count})
}

func (h *Handler) ListComments(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	query := r.URL.Query()
	limit, offset, ok := parsePagination(w, r, query.Get("limit"), query.Get("offset"))
	if !ok {
		return
	}

	items, err := h.useCase.ListComments(r.Context(), SubjectFromContext(r.Context()), postID, limit, offset)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	resp := make([]*dto.PostCommentResponse, 0, len(items))
	for _, item := range items {
		resp = append(resp, toPostCommentResponse(item))
	}

	writeJSON(w, http.StatusOK, map[string]any{"items": resp})
}

func (h *Handler) CreateComment(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	var req dto.CreateCommentRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	item, err := h.useCase.CreateComment(r.Context(), SubjectFromContext(r.Context()), postID, req.Body)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusCreated, toPostCommentResponse(item))
}

func (h *Handler) UpdateComment(w http.ResponseWriter, r *http.Request, postID uuid.UUID, commentID uuid.UUID) {
	var req dto.UpdateCommentRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	item, err := h.useCase.UpdateComment(r.Context(), SubjectFromContext(r.Context()), postID, commentID, req.Body)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, toPostCommentResponse(item))
}

func (h *Handler) DeleteComment(w http.ResponseWriter, r *http.Request, postID uuid.UUID, commentID uuid.UUID) {
	if err := h.useCase.DeleteComment(r.Context(), SubjectFromContext(r.Context()), postID, commentID); err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) LikeComment(w http.ResponseWriter, r *http.Request, postID uuid.UUID, commentID uuid.UUID) {
	count, likedByMe, err := h.useCase.LikeComment(r.Context(), SubjectFromContext(r.Context()), postID, commentID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.CommentLikeResponse{
		Likes:     count,
		LikedByMe: likedByMe,
	})
}

func (h *Handler) UnlikeComment(w http.ResponseWriter, r *http.Request, postID uuid.UUID, commentID uuid.UUID) {
	count, likedByMe, err := h.useCase.UnlikeComment(r.Context(), SubjectFromContext(r.Context()), postID, commentID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.CommentLikeResponse{
		Likes:     count,
		LikedByMe: likedByMe,
	})
}

func (h *Handler) SharePost(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	shareURL, count, err := h.useCase.SharePost(r.Context(), postID)
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, dto.ShareResponse{
		ShareURL: shareURL,
		Shares:   count,
	})
}

func (h *Handler) ReportPost(w http.ResponseWriter, r *http.Request, postID uuid.UUID) {
	var req dto.ReportPostRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return
	}

	result, err := h.useCase.SubmitPostReport(r.Context(), SubjectFromContext(r.Context()), postID, app.SubmitPostReportInput{
		Reason:  req.Reason,
		Details: req.Details,
	})
	if err != nil {
		h.writeUseCaseError(w, r, err)
		return
	}

	writeJSON(w, http.StatusCreated, toPostReportSubmissionResponse(result))
}

func toPostResponse(item *app.PostView, includeContent bool) *dto.PostResponse {
	if item == nil || item.Post == nil {
		return nil
	}

	var coverFileID *string
	var coverImageURL *string
	if item.Post.CoverFileID != nil {
		v := item.Post.CoverFileID.String()
		coverFileID = &v
		url := publicFileContentURL(v)
		coverImageURL = &url
	}
	var communityID *string
	if item.Post.CommunityID != nil {
		v := item.Post.CommunityID.String()
		communityID = &v
	}

	var content *string
	if includeContent {
		v := item.Post.Content
		content = &v
	}

	var publishedAt *string
	if item.Post.PublishedAt != nil {
		v := item.Post.PublishedAt.UTC().Format(time.RFC3339)
		publishedAt = &v
	}

	var expiresAt *string
	if item.Post.ExpiresAt != nil {
		v := item.Post.ExpiresAt.UTC().Format(time.RFC3339)
		expiresAt = &v
	}

	var seenAt *string
	if item.SeenAt != nil {
		v := item.SeenAt.UTC().Format(time.RFC3339)
		seenAt = &v
	}

	var lastAutosavedAt *string
	if item.Post.LastAutosavedAt != nil {
		v := item.Post.LastAutosavedAt.UTC().Format(time.RFC3339)
		lastAutosavedAt = &v
	}

	var archivedAt *string
	if item.Post.ArchivedAt != nil {
		v := item.Post.ArchivedAt.UTC().Format(time.RFC3339)
		archivedAt = &v
	}
	var communityInstanceID *string
	if item.Post.CommunityInstanceID != nil {
		v := item.Post.CommunityInstanceID.String()
		communityInstanceID = &v
	}
	var sourceActivityID *string
	if item.Post.SourceActivityID != nil {
		v := item.Post.SourceActivityID.String()
		sourceActivityID = &v
	}
	var activityCreationStatus *string
	if item.Post.ActivityCreationStatus != nil {
		v := string(*item.Post.ActivityCreationStatus)
		activityCreationStatus = &v
	}

	return &dto.PostResponse{
		ID:                     item.Post.ID.String(),
		Slug:                   item.Post.Slug,
		Title:                  item.Post.Title,
		Excerpt:                item.Post.Excerpt,
		Content:                content,
		Format:                 string(item.Post.Format),
		ContentBlocks:          item.Post.ContentBlocks,
		ContentSchemaVersion:   item.Post.ContentSchemaVersion,
		Revision:               item.Post.Revision,
		CommunityID:            communityID,
		CommunityInstanceID:    communityInstanceID,
		PostKind:               string(item.Post.PostKind),
		PostProfileKey:         string(item.Post.PostProfileKey),
		PostProfileVersion:     item.Post.PostProfileVersion,
		StructuredData:         item.Post.StructuredData,
		ModerationMode:         string(item.Post.ModerationMode),
		ActivityCreationStatus: activityCreationStatus,
		SourceActivityID:       sourceActivityID,
		Category:               string(item.Post.Category),
		Status:                 postResponseStatus(item.Post),
		ModerationStatus:       string(item.Post.ModerationStatus),
		CoverFileID:            coverFileID,
		CoverImageURL:          coverImageURL,
		PlaceName:              item.Post.PlaceName,
		PlaceCountryCode:       item.Post.PlaceCountryCode,
		PlaceCityID:            item.Post.PlaceCityID,
		Tags:                   item.Post.Tags,
		Stats: dto.PostStatsResponse{
			Views:    item.Post.ViewCount,
			Likes:    item.Post.LikeCount,
			Comments: item.Post.CommentCount,
			Shares:   item.Post.ShareCount,
		},
		Author:          toAuthorResponse(item.Author),
		LikedByViewer:   item.LikedByViewer,
		Editable:        item.Editable,
		SeenByViewer:    item.SeenByViewer,
		SeenAt:          seenAt,
		ShareURL:        item.ShareURL,
		PublishedAt:     publishedAt,
		ExpiresAt:       expiresAt,
		LastAutosavedAt: lastAutosavedAt,
		ArchivedAt:      archivedAt,
		CreatedAt:       item.Post.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:       item.Post.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toStoryResponse(item *app.StoryView) *dto.StoryResponse {
	if item == nil || item.Story == nil {
		return nil
	}

	mediaFileID := item.Story.MediaFileID.String()
	coverFileID := item.Story.CoverFileID.String()
	var seenAt *string
	if item.SeenAt != nil {
		value := item.SeenAt.UTC().Format(time.RFC3339)
		seenAt = &value
	}

	return &dto.StoryResponse{
		ID:            item.Story.ID.String(),
		Caption:       item.Story.Caption,
		MediaFileID:   mediaFileID,
		MediaURL:      publicFileContentURL(mediaFileID),
		CoverFileID:   coverFileID,
		CoverImageURL: publicFileContentURL(coverFileID),
		MediaType:     string(item.Story.MediaType),
		Stats: dto.StoryStatsResponse{
			Views:   item.Story.ViewCount,
			Likes:   item.Story.LikeCount,
			Replies: item.Story.ReplyCount,
		},
		Author:       toAuthorResponse(item.Author),
		SeenByViewer: item.SeenByViewer,
		SeenAt:       seenAt,
		ShareURL:     item.ShareURL,
		ExpiresAt:    item.Story.ExpiresAt.UTC().Format(time.RFC3339),
		CreatedAt:    item.Story.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:    item.Story.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func publicFileContentURL(fileID string) string {
	return "/api/v1/public/files/" + fileID + "/content"
}

func toCommunityResponse(item *app.CommunityView) *dto.CommunityResponse {
	if item == nil || item.Community == nil {
		return nil
	}

	var avatarFileID *string
	if item.Community.AvatarFileID != nil {
		v := item.Community.AvatarFileID.String()
		avatarFileID = &v
	}
	var coverFileID *string
	if item.Community.CoverFileID != nil {
		v := item.Community.CoverFileID.String()
		coverFileID = &v
	}

	return &dto.CommunityResponse{
		ID:                     item.Community.ID.String(),
		Slug:                   item.Community.Slug,
		Title:                  item.Community.Title,
		TitleI18n:              cloneStringMap(item.Community.TitleI18n),
		Description:            item.Community.Description,
		DescriptionI18n:        cloneStringMap(item.Community.DescriptionI18n),
		Topic:                  item.Community.Topic,
		Rules:                  normalizeCommunityRules(item.Community.Rules),
		RulesI18n:              cloneStringSliceMap(item.Community.RulesI18n),
		CityID:                 item.Community.CityID,
		CountryCode:            item.Community.CountryCode,
		LanguageCode:           item.Community.LanguageCode,
		AvatarFileID:           avatarFileID,
		CoverFileID:            coverFileID,
		Visibility:             string(item.Community.Visibility),
		PostingPolicy:          string(item.Community.PostingPolicy),
		Status:                 string(item.Community.Status),
		DefaultPostProfileKey:  string(item.Community.DefaultPostProfileKey),
		AllowedPostProfileKeys: cloneStringSlice(item.Community.AllowedPostProfileKeys),
		EnabledTabs:            cloneStringSlice(item.Community.EnabledTabs),
		FollowerCount:          item.Community.FollowerCount,
		MembersCount:           item.Community.FollowerCount,
		PostCount:              item.Community.PostCount,
		FollowedByViewer:       item.FollowedByViewer,
		ViewerRole:             string(item.ViewerRole),
		ViewerCanModerate:      item.ViewerCanModerate,
		MutedByViewer:          item.MutedByViewer,
		ViewerTrustStatus:      item.ViewerTrustStatus,
		CreatedAt:              item.Community.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:              item.Community.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toCommunityPostProfileResponse(item *model.CommunityPostProfile) *dto.CommunityPostProfileResponse {
	if item == nil {
		return nil
	}
	return &dto.CommunityPostProfileResponse{
		Key:                  string(item.Key),
		Version:              item.Version,
		PostKind:             string(item.PostKind),
		ComposerPreset:       item.ComposerPreset,
		RenderPreset:         item.RenderPreset,
		Schema:               item.SchemaJSON,
		Validation:           item.ValidationJSON,
		ModerationMode:       string(item.ModerationMode),
		ActivityCreationMode: string(item.ActivityCreationMode),
		CreatedAt:            item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:            item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toCommunityBlueprintResponse(item *model.CommunityBlueprint) *dto.CommunityBlueprintResponse {
	if item == nil {
		return nil
	}
	return &dto.CommunityBlueprintResponse{
		ID:                     item.ID.String(),
		Key:                    item.Key,
		Category:               item.Category,
		DefaultPostProfileKey:  string(item.DefaultPostProfileKey),
		AllowedPostProfileKeys: cloneStringSlice(item.AllowedPostProfileKeys),
		EnabledTabs:            cloneStringSlice(item.EnabledTabs),
		SubcategoryKeys:        cloneStringSlice(item.SubcategoryKeys),
		PromotionSegmentKeys:   cloneStringSlice(item.PromotionSegmentKeys),
		TitleI18n:              cloneStringMap(item.TitleI18n),
		DescriptionI18n:        cloneStringMap(item.DescriptionI18n),
		RulesI18n:              cloneStringSliceMap(item.RulesI18n),
		IconKey:                item.IconKey,
		RolloutPolicy:          string(item.RolloutPolicy),
		AllowedScopeTypes:      communityScopeTypesToStrings(item.AllowedScopeTypes),
		DefaultModerationMode:  string(item.DefaultModerationMode),
		Status:                 string(item.Status),
		CreatedAt:              item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:              item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toCommunityGeoHubResponse(item *model.CommunityGeoHub) *dto.CommunityGeoHubResponse {
	if item == nil {
		return nil
	}
	return &dto.CommunityGeoHubResponse{
		CountryCode:       item.CountryCode,
		CityID:            item.CityID,
		HubTier:           string(item.HubTier),
		CommunityEnabled:  item.CommunityEnabled,
		ParentCountryCode: item.ParentCountryCode,
		ParentCityID:      item.ParentCityID,
		Reason:            item.Reason,
		Priority:          item.Priority,
		CanMaterialize:    item.CanMaterializeCommunity(),
		EffectiveCountry:  item.EffectiveCountryCode(),
		EffectiveCityID:   item.EffectiveCityID(),
		CreatedBy:         item.CreatedBy,
		UpdatedAt:         item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toCommunityInstanceResponse(item *model.CommunityInstance) *dto.CommunityInstanceResponse {
	if item == nil {
		return nil
	}
	var communityID *string
	if item.CommunityID != nil {
		value := item.CommunityID.String()
		communityID = &value
	}
	return &dto.CommunityInstanceResponse{
		ID:              item.ID.String(),
		CommunityID:     communityID,
		BlueprintID:     item.BlueprintID.String(),
		Slug:            item.Slug,
		CountryCode:     item.CountryCode,
		CityID:          item.CityID,
		ScopeType:       string(item.ScopeType),
		TitleI18n:       cloneStringMap(item.TitleI18n),
		DescriptionI18n: cloneStringMap(item.DescriptionI18n),
		RulesI18n:       cloneStringSliceMap(item.RulesI18n),
		Status:          string(item.Status),
		MemberCount:     item.MemberCount,
		PostCount:       item.PostCount,
		CreatedAt:       item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:       item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func communityScopeTypesToStrings(items []enum.CommunityScopeType) []string {
	if len(items) == 0 {
		return nil
	}
	values := make([]string, 0, len(items))
	for _, item := range items {
		values = append(values, string(item))
	}
	return values
}

func toCommunityReportSubmissionResponse(result *model.CommunityReportSubmissionResult) *dto.CommunityReportSubmissionResponse {
	if result == nil {
		return &dto.CommunityReportSubmissionResponse{}
	}
	return &dto.CommunityReportSubmissionResponse{
		Report:           toCommunityReportResponse(result.Report),
		OpenReportsCount: result.OpenReportsCount,
	}
}

func toCommunityReportResponse(report *model.CommunityReport) *dto.CommunityReportResponse {
	if report == nil {
		return nil
	}
	return &dto.CommunityReportResponse{
		ID:             report.ID.String(),
		CommunityID:    report.CommunityID.String(),
		ReporterUserID: report.ReporterUserID.String(),
		Reason:         string(report.Reason),
		Details:        report.Details,
		Status:         string(report.Status),
		CreatedAt:      report.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:      report.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func normalizeCommunityRules(raw []string) []string {
	if len(raw) == 0 {
		return nil
	}
	rules := make([]string, 0, len(raw))
	for _, rule := range raw {
		if trimmed := strings.TrimSpace(rule); trimmed != "" {
			rules = append(rules, trimmed)
		}
	}
	if len(rules) == 0 {
		return nil
	}
	return rules
}

func cloneStringMap(input map[string]string) map[string]string {
	if len(input) == 0 {
		return nil
	}
	out := make(map[string]string, len(input))
	for key, value := range input {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			out[key] = trimmed
		}
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

func cloneStringSlice(input []string) []string {
	if len(input) == 0 {
		return nil
	}
	out := make([]string, 0, len(input))
	for _, value := range input {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			out = append(out, trimmed)
		}
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

func cloneStringSliceMap(input map[string][]string) map[string][]string {
	if len(input) == 0 {
		return nil
	}
	out := make(map[string][]string, len(input))
	for key, values := range input {
		if normalized := normalizeCommunityRules(values); len(normalized) > 0 {
			out[key] = normalized
		}
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

func toCommunityMembershipResponse(item *model.CommunityMembership) *dto.CommunityMembershipResponse {
	if item == nil {
		return nil
	}
	return &dto.CommunityMembershipResponse{
		CommunityID: item.CommunityID.String(),
		UserID:      item.UserID.String(),
		Role:        string(item.Role),
		Status:      string(item.Status),
		CreatedAt:   item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:   item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toCommunityMemberResponse(item *app.CommunityMemberView) *dto.CommunityMemberResponse {
	if item == nil || item.Membership == nil {
		return nil
	}
	return &dto.CommunityMemberResponse{
		CommunityID: item.Membership.CommunityID.String(),
		UserID:      item.Membership.UserID.String(),
		Role:        string(item.Membership.Role),
		Status:      string(item.Membership.Status),
		User:        toAuthorResponse(item.User),
		CreatedAt:   item.Membership.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:   item.Membership.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toCommunityMemberRoleChangeResponse(item *app.CommunityMemberRoleChangeView) *dto.CommunityMemberRoleChangeResponse {
	if item == nil || item.Change == nil {
		return nil
	}
	return &dto.CommunityMemberRoleChangeResponse{
		ID:           item.Change.ID.String(),
		CommunityID:  item.Change.CommunityID.String(),
		TargetUserID: item.Change.TargetUserID.String(),
		ActorUserID:  item.Change.ActorUserID.String(),
		Actor:        toAuthorResponse(item.Actor),
		PreviousRole: string(item.Change.PreviousRole),
		NextRole:     string(item.Change.NextRole),
		CreatedAt:    item.Change.CreatedAt.UTC().Format(time.RFC3339),
	}
}

func toFeedResponse(page *app.FeedPage) *dto.FeedResponse {
	if page == nil {
		return &dto.FeedResponse{Items: []*dto.FeedBlockResponse{}}
	}

	resp := &dto.FeedResponse{
		Items: make([]*dto.FeedBlockResponse, 0, len(page.Items)),
	}
	if strings.TrimSpace(page.NextCursor) != "" {
		resp.NextCursor = &page.NextCursor
	}
	if rankingExperiment := strings.TrimSpace(page.Assignment.RankingExperiment); rankingExperiment != "" {
		resp.Assignment = &dto.FeedAssignmentResponse{RankingExperiment: rankingExperiment}
	}

	for _, item := range page.Items {
		resp.Items = append(resp.Items, &dto.FeedBlockResponse{
			ID:   item.ID,
			Type: item.Type,
			Data: toFeedBlockData(item),
		})
	}
	return resp
}

func toFeedBlockData(item app.FeedBlock) any {
	switch data := item.Data.(type) {
	case app.StoriesTrayFeedData:
		stories := make([]*dto.StoryResponse, 0, len(data.Stories))
		for _, story := range data.Stories {
			stories = append(stories, toStoryResponse(story))
		}
		return map[string]any{"stories": stories}
	case app.SuggestedCommunitiesFeedData:
		communities := make([]*dto.CommunityResponse, 0, len(data.Communities))
		for _, community := range data.Communities {
			communities = append(communities, toCommunityResponse(community))
		}
		return map[string]any{"communities": communities}
	case app.PostCardFeedData:
		result := map[string]any{"post": toPostResponse(data.Post, false)}
		if candidateSource := strings.TrimSpace(data.CandidateSource); candidateSource != "" {
			result["candidateSource"] = candidateSource
		}
		return result
	case app.ConversionFeedData:
		return map[string]any{
			"title":        data.Title,
			"subtitle":     data.Subtitle,
			"actionLabel":  data.ActionLabel,
			"entityType":   data.EntityType,
			"entityId":     data.EntityID,
			"route":        data.Route,
			"source":       data.Source,
			"semanticTags": append([]string(nil), data.SemanticTags...),
		}
	default:
		return map[string]any{}
	}
}

func postResponseStatus(post *model.Post) string {
	if post != nil && post.ArchivedAt != nil {
		return string(enum.PostStatusArchived)
	}
	if post == nil {
		return ""
	}
	return string(post.Status)
}

func toPostCommentResponse(item *app.PostCommentView) *dto.PostCommentResponse {
	if item == nil || item.Comment == nil {
		return nil
	}

	return &dto.PostCommentResponse{
		ID:        item.Comment.ID.String(),
		PostID:    item.Comment.PostID.String(),
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

func toPostModerationDecisionResponse(item *model.PostModerationDecision) *dto.PostModerationDecisionResponse {
	if item == nil {
		return nil
	}
	return &dto.PostModerationDecisionResponse{
		ID:              item.ID.String(),
		PostID:          item.PostID.String(),
		CommunityID:     item.CommunityID.String(),
		ModeratorUserID: item.ModeratorUserID.String(),
		Decision:        string(item.Decision),
		PreviousStatus:  string(item.PreviousStatus),
		NextStatus:      string(item.NextStatus),
		PostRevision:    item.PostRevision,
		Reason:          item.Reason,
		CreatedAt:       item.CreatedAt.Format(time.RFC3339),
	}
}

func toPostReportSubmissionResponse(item *app.PostReportView) *dto.PostReportSubmissionResponse {
	if item == nil {
		return nil
	}
	return &dto.PostReportSubmissionResponse{
		Report:           toPostReportResponse(item.Report),
		Post:             toPostResponse(&app.PostView{Post: item.Post}, false),
		OpenReportsCount: item.OpenReportsCount,
		AutoHidden:       item.AutoHidden,
	}
}

func toPostReportResponse(item *model.PostReport) *dto.PostReportResponse {
	if item == nil {
		return nil
	}
	return &dto.PostReportResponse{
		ID:               item.ID.String(),
		PostID:           item.PostID.String(),
		CommunityID:      uuidStringPtr(item.CommunityID),
		ReporterUserID:   item.ReporterUserID.String(),
		AuthorUserID:     item.AuthorUserID.String(),
		Reason:           string(item.Reason),
		Details:          item.Details,
		Status:           string(item.Status),
		ResolvedByUserID: uuidStringPtr(item.ResolvedByUserID),
		ResolutionNote:   item.ResolutionNote,
		CreatedAt:        item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:        item.UpdatedAt.UTC().Format(time.RFC3339),
		ResolvedAt:       timeStringPtr(item.ResolvedAt),
	}
}

func uuidStringPtr(value *uuid.UUID) *string {
	if value == nil {
		return nil
	}
	text := value.String()
	return &text
}

func timeStringPtr(value *time.Time) *string {
	if value == nil {
		return nil
	}
	text := value.UTC().Format(time.RFC3339)
	return &text
}

func toPostDetailResponse(detail *app.PostDetail) *dto.PostDetailResponse {
	if detail == nil {
		return nil
	}

	resp := &dto.PostDetailResponse{
		Post:     toPostResponse(detail.Post, true),
		Related:  make([]*dto.PostResponse, 0, len(detail.Related)),
		Comments: make([]*dto.PostCommentResponse, 0, len(detail.Comments)),
	}

	for _, item := range detail.Related {
		resp.Related = append(resp.Related, toPostResponse(item, false))
	}
	for _, item := range detail.Comments {
		resp.Comments = append(resp.Comments, toPostCommentResponse(item))
	}

	return resp
}

func toAuthorResponse(author app.PostAuthor) dto.AuthorResponse {
	var avatarFileID *string
	if author.AvatarFileID != nil {
		v := author.AvatarFileID.String()
		avatarFileID = &v
	}

	return dto.AuthorResponse{
		UserID:           author.UserID.String(),
		Nickname:         author.Nickname,
		AvatarFileID:     avatarFileID,
		CountryCode:      author.CountryCode,
		Locale:           author.Locale,
		Timezone:         author.Timezone,
		IsFriendOfViewer: author.IsFriendOfViewer,
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

func parseOptionalRFC3339Query(w http.ResponseWriter, r *http.Request, raw string) (time.Time, bool) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return time.Time{}, true
	}
	parsed, err := time.Parse(time.RFC3339, raw)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidFeedEvent)
		return time.Time{}, false
	}
	return parsed.UTC(), true
}

func parseOptionalRFC3339Body(w http.ResponseWriter, r *http.Request, raw *string) (*time.Time, bool) {
	if raw == nil {
		return nil, true
	}
	trimmed := strings.TrimSpace(*raw)
	if trimmed == "" {
		return nil, true
	}
	parsed, err := time.Parse(time.RFC3339, trimmed)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, errorCodeInvalidRequestBody)
		return nil, false
	}
	utc := parsed.UTC()
	return &utc, true
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

func feedEventsInputFromRequest(
	w http.ResponseWriter,
	r *http.Request,
	req dto.TrackFeedEventsRequest,
) (app.TrackFeedEventsInput, bool) {
	events := make([]app.FeedEventInput, 0, len(req.Events))
	for _, raw := range req.Events {
		eventID, err := uuid.Parse(strings.TrimSpace(raw.EventID))
		if err != nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidFeedEvent)
			return app.TrackFeedEventsInput{}, false
		}
		postID := uuid.Nil
		if raw.PostID != nil && strings.TrimSpace(*raw.PostID) != "" {
			parsed, parseErr := uuid.Parse(strings.TrimSpace(*raw.PostID))
			if parseErr != nil {
				writeError(w, r, http.StatusBadRequest, errorCodeInvalidFeedEvent)
				return app.TrackFeedEventsInput{}, false
			}
			postID = parsed
		}
		communityID, err := parseOptionalUUID(raw.CommunityID)
		if err != nil {
			writeError(w, r, http.StatusBadRequest, errorCodeInvalidFeedEvent)
			return app.TrackFeedEventsInput{}, false
		}
		occurredAt := time.Time{}
		if strings.TrimSpace(raw.OccurredAt) != "" {
			parsed, parseErr := time.Parse(time.RFC3339, strings.TrimSpace(raw.OccurredAt))
			if parseErr != nil {
				writeError(w, r, http.StatusBadRequest, errorCodeInvalidFeedEvent)
				return app.TrackFeedEventsInput{}, false
			}
			occurredAt = parsed
		}
		events = append(events, app.FeedEventInput{
			EventID:     eventID,
			EventType:   strings.TrimSpace(raw.Type),
			Surface:     raw.Surface,
			Tab:         raw.Tab,
			BlockID:     raw.BlockID,
			BlockType:   raw.BlockType,
			PostID:      postID,
			CommunityID: communityID,
			Rank:        raw.Rank,
			OccurredAt:  occurredAt,
			RequestID:   RequestIDFromContext(r.Context()),
			Metadata:    raw.Metadata,
		})
	}
	return app.TrackFeedEventsInput{Events: events}, true
}

func updatePostInputFromRequest(
	req dto.UpdatePostRequest,
	coverFileID *uuid.UUID,
	communityID *uuid.UUID,
	communityInstanceID *uuid.UUID,
) app.UpdatePostInput {
	input := app.UpdatePostInput{
		Title:                  req.Title,
		Content:                req.Content,
		ContentBlocks:          req.ContentBlocks,
		Revision:               req.Revision,
		CommunityID:            communityID,
		CommunityIDSet:         req.Present["communityId"],
		CommunityInstanceID:    communityInstanceID,
		CommunityInstanceIDSet: req.Present["communityInstanceId"],
		StructuredData:         req.StructuredData,
		CoverFileID:            coverFileID,
		CoverFileIDSet:         req.Present["coverFileId"],
		PlaceName:              req.PlaceName,
		PlaceNameSet:           req.Present["placeName"],
		PlaceCountryCode:       req.PlaceCountryCode,
		PlaceCountryCodeSet:    req.Present["placeCountryCode"],
		PlaceCityID:            req.PlaceCityID,
		PlaceCityIDSet:         req.Present["placeCityId"],
	}
	if req.Format != nil {
		format := enum.PostFormat(*req.Format)
		input.Format = &format
	}
	if req.PostProfileKey != nil {
		postProfileKey := enum.PostProfileKey(*req.PostProfileKey)
		input.PostProfileKey = &postProfileKey
	}
	if req.Category != nil {
		category := enum.PostCategory(*req.Category)
		input.Category = &category
	}
	if req.Status != nil {
		status := enum.PostStatus(*req.Status)
		input.Status = &status
	}
	if req.Tags != nil {
		input.Tags = append([]string(nil), (*req.Tags)...)
		input.TagsSet = true
	}
	return input
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

func decodeOptionalBody(r *http.Request, target any) error {
	if r.Body == nil {
		return nil
	}
	if err := json.NewDecoder(r.Body).Decode(target); err != nil {
		if errors.Is(err, io.EOF) {
			return nil
		}
		return errors.New("invalid request body")
	}
	return nil
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			return trimmed
		}
	}
	return ""
}

func parseQueryBool(value string) bool {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "1", "true", "t", "yes", "y", "on":
		return true
	default:
		return false
	}
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
