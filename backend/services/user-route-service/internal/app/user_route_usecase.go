package app

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"kz/inflap/backend/services/user-route-service/internal/domain/model"
)

var (
	ErrUserRouteAuthRequired         = errors.New("user route authentication required")
	ErrUserRouteForbidden            = errors.New("user route forbidden")
	ErrUserRouteNotFound             = errors.New("user route not found")
	ErrUserRoutePersistenceFailed    = errors.New("user route persistence failed")
	ErrUserRouteInvalidDecision      = errors.New("user route moderation decision is invalid")
	ErrUserRouteReviewReasonRequired = errors.New("user route review reason is required")
)

type UserRouteRepository interface {
	SaveRoute(ctx context.Context, route model.UserRoute) error
	CreateRouteCopy(ctx context.Context, sourceRouteID string, copy model.UserRoute, copiedAt time.Time) error
	FindRouteByID(ctx context.Context, routeID string) (model.UserRoute, bool, error)
	ListRoutes(ctx context.Context, filter RouteListFilter) ([]model.UserRoute, error)
	SaveRouteBookmark(ctx context.Context, userID string, routeID string, createdAt time.Time) error
	DeleteRouteBookmark(ctx context.Context, userID string, routeID string) error
	HasRouteBookmark(ctx context.Context, userID string, routeID string) (bool, error)
	CountRouteBookmarks(ctx context.Context, routeID string) (int, error)
}

type RouteListFilter struct {
	OwnerUserID      string
	PublicOnly       bool
	SavedByUserID    string
	CityCode         string
	ModerationStatus model.RouteModerationStatus
	Limit            int
	Offset           int
}

type UserRouteUseCase struct {
	repo UserRouteRepository
	now  func() time.Time
}

type UserRouteUseCaseOption func(*UserRouteUseCase)

func WithClock(now func() time.Time) UserRouteUseCaseOption {
	return func(uc *UserRouteUseCase) {
		if now != nil {
			uc.now = now
		}
	}
}

func NewUserRouteUseCase(repo UserRouteRepository, opts ...UserRouteUseCaseOption) *UserRouteUseCase {
	uc := &UserRouteUseCase{
		repo: repo,
		now:  time.Now,
	}
	for _, opt := range opts {
		if opt != nil {
			opt(uc)
		}
	}
	return uc
}

type CreateRouteInput struct {
	ActorUserID string
	Title       string
	Description string
	Visibility  model.RouteVisibility
	Profile     model.RouteProfile
	CityCode    string
	Tags        []string
	Points      []model.UserRoutePoint
	Snapshot    model.RouteSnapshot
}

type UpdateRouteInput struct {
	ActorUserID string
	RouteID     string
	Title       *string
	Description *string
	Visibility  *model.RouteVisibility
	Profile     *model.RouteProfile
	CityCode    *string
	Tags        *[]string
	Points      *[]model.UserRoutePoint
	Snapshot    *model.RouteSnapshot
}

type GetRouteInput struct {
	ActorUserID string
	RouteID     string
}

type ListRoutesInput struct {
	ActorUserID   string
	OwnerUserID   string
	PublicOnly    bool
	SavedByUserID string
	CityCode      string
	Limit         int
	Offset        int
}

type SaveRouteInput struct {
	ActorUserID string
	RouteID     string
}

type CopyRouteInput struct {
	ActorUserID string
	RouteID     string
}

type ListAdminRoutesInput struct {
	ActorUserID      string
	OwnerUserID      string
	CityCode         string
	ModerationStatus model.RouteModerationStatus
	Limit            int
	Offset           int
}

type ReviewRouteInput struct {
	ActorUserID string
	RouteID     string
	Decision    string
	Reason      string
}

func (uc *UserRouteUseCase) CreateRoute(ctx context.Context, input CreateRouteInput) (model.UserRoute, error) {
	actorUserID := strings.TrimSpace(input.ActorUserID)
	if actorUserID == "" {
		return model.UserRoute{}, ErrUserRouteAuthRequired
	}

	now := uc.now().UTC()
	route := model.UserRoute{
		ID:               newRouteID(),
		OwnerUserID:      actorUserID,
		Title:            input.Title,
		Description:      input.Description,
		Visibility:       input.Visibility,
		ModerationStatus: moderationStatusForVisibility(input.Visibility, ""),
		Profile:          input.Profile,
		CityCode:         input.CityCode,
		Tags:             input.Tags,
		Points:           clonePoints(input.Points),
		Snapshot:         input.Snapshot,
		CreatedAt:        now,
		UpdatedAt:        now,
	}
	route.Normalize()
	if err := route.Validate(); err != nil {
		return model.UserRoute{}, err
	}
	if err := uc.repo.SaveRoute(ctx, route); err != nil {
		return model.UserRoute{}, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	return route, nil
}

func (uc *UserRouteUseCase) UpdateRoute(ctx context.Context, input UpdateRouteInput) (model.UserRoute, error) {
	actorUserID := strings.TrimSpace(input.ActorUserID)
	if actorUserID == "" {
		return model.UserRoute{}, ErrUserRouteAuthRequired
	}
	routeID := strings.TrimSpace(input.RouteID)
	if routeID == "" {
		return model.UserRoute{}, ErrUserRouteNotFound
	}
	route, ok, err := uc.repo.FindRouteByID(ctx, routeID)
	if err != nil {
		return model.UserRoute{}, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	if !ok {
		return model.UserRoute{}, ErrUserRouteNotFound
	}
	if !route.IsOwnedBy(actorUserID) {
		if !route.IsReadableBy(actorUserID) {
			return model.UserRoute{}, ErrUserRouteNotFound
		}
		return model.UserRoute{}, ErrUserRouteForbidden
	}

	if input.Title != nil {
		route.Title = *input.Title
	}
	if input.Description != nil {
		route.Description = *input.Description
	}
	if input.Visibility != nil {
		route.Visibility = *input.Visibility
	}
	if input.Profile != nil {
		route.Profile = *input.Profile
	}
	if input.CityCode != nil {
		route.CityCode = *input.CityCode
	}
	if input.Tags != nil {
		route.Tags = append([]string(nil), (*input.Tags)...)
	}
	if input.Points != nil {
		route.Points = clonePoints(*input.Points)
	}
	if input.Snapshot != nil {
		route.Snapshot = *input.Snapshot
	}
	route.ModerationStatus = moderationStatusForVisibility(route.Visibility, route.ModerationStatus)
	if route.ModerationStatus == model.RouteModerationStatusPending || route.ModerationStatus == model.RouteModerationStatusApproved {
		route.ModerationReason = ""
		route.ModeratedByUserID = nil
		route.ModeratedAt = nil
	}
	route.UpdatedAt = uc.now().UTC()
	route.Normalize()
	if err := route.Validate(); err != nil {
		return model.UserRoute{}, err
	}
	if err := uc.repo.SaveRoute(ctx, route); err != nil {
		return model.UserRoute{}, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	return uc.withViewerState(ctx, route, actorUserID)
}

func (uc *UserRouteUseCase) GetRoute(ctx context.Context, input GetRouteInput) (model.UserRoute, error) {
	route, err := uc.readableRoute(ctx, strings.TrimSpace(input.ActorUserID), strings.TrimSpace(input.RouteID))
	if err != nil {
		return model.UserRoute{}, err
	}
	return uc.withViewerState(ctx, route, input.ActorUserID)
}

func (uc *UserRouteUseCase) ListRoutes(ctx context.Context, input ListRoutesInput) ([]model.UserRoute, error) {
	filter := RouteListFilter{
		OwnerUserID:   strings.TrimSpace(input.OwnerUserID),
		PublicOnly:    input.PublicOnly,
		SavedByUserID: strings.TrimSpace(input.SavedByUserID),
		CityCode:      strings.ToLower(strings.TrimSpace(input.CityCode)),
		Limit:         normalizeLimit(input.Limit),
		Offset:        input.Offset,
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	routes, err := uc.repo.ListRoutes(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	actorUserID := strings.TrimSpace(input.ActorUserID)
	out := make([]model.UserRoute, 0, len(routes))
	for _, route := range routes {
		if !route.IsReadableBy(actorUserID) {
			continue
		}
		withState, err := uc.withViewerState(ctx, route, actorUserID)
		if err != nil {
			return nil, err
		}
		out = append(out, withState)
	}
	return out, nil
}

func (uc *UserRouteUseCase) ListAdminRoutes(ctx context.Context, input ListAdminRoutesInput) ([]model.UserRoute, error) {
	if strings.TrimSpace(input.ActorUserID) == "" {
		return nil, ErrUserRouteAuthRequired
	}
	filter := RouteListFilter{
		OwnerUserID:      strings.TrimSpace(input.OwnerUserID),
		CityCode:         strings.ToLower(strings.TrimSpace(input.CityCode)),
		ModerationStatus: model.NormalizeModerationStatus(input.ModerationStatus),
		Limit:            normalizeLimit(input.Limit),
		Offset:           input.Offset,
	}
	if input.ModerationStatus == "" {
		filter.ModerationStatus = ""
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	routes, err := uc.repo.ListRoutes(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	return routes, nil
}

func (uc *UserRouteUseCase) ReviewRoute(ctx context.Context, input ReviewRouteInput) (model.UserRoute, error) {
	actorUserID := strings.TrimSpace(input.ActorUserID)
	if actorUserID == "" {
		return model.UserRoute{}, ErrUserRouteAuthRequired
	}
	route, ok, err := uc.repo.FindRouteByID(ctx, strings.TrimSpace(input.RouteID))
	if err != nil {
		return model.UserRoute{}, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	if !ok {
		return model.UserRoute{}, ErrUserRouteNotFound
	}

	status, err := moderationStatusForDecision(input.Decision)
	if err != nil {
		return model.UserRoute{}, err
	}
	reason := strings.TrimSpace(input.Reason)
	if reason == "" && (status == model.RouteModerationStatusRejected || status == model.RouteModerationStatusHidden) {
		return model.UserRoute{}, ErrUserRouteReviewReasonRequired
	}

	now := uc.now().UTC()
	route.ModerationStatus = status
	route.ModerationReason = reason
	route.ModeratedByUserID = &actorUserID
	route.ModeratedAt = &now
	route.UpdatedAt = now
	route.Normalize()
	if err := route.Validate(); err != nil {
		return model.UserRoute{}, err
	}
	if err := uc.repo.SaveRoute(ctx, route); err != nil {
		return model.UserRoute{}, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	return uc.withViewerState(ctx, route, actorUserID)
}

func (uc *UserRouteUseCase) SaveRoute(ctx context.Context, input SaveRouteInput) (model.UserRoute, error) {
	actorUserID := strings.TrimSpace(input.ActorUserID)
	if actorUserID == "" {
		return model.UserRoute{}, ErrUserRouteAuthRequired
	}
	route, err := uc.readableRoute(ctx, actorUserID, strings.TrimSpace(input.RouteID))
	if err != nil {
		return model.UserRoute{}, err
	}
	if err := uc.repo.SaveRouteBookmark(ctx, actorUserID, route.ID, uc.now().UTC()); err != nil {
		return model.UserRoute{}, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	return uc.withViewerState(ctx, route, actorUserID)
}

func (uc *UserRouteUseCase) UnsaveRoute(ctx context.Context, input SaveRouteInput) (model.UserRoute, error) {
	actorUserID := strings.TrimSpace(input.ActorUserID)
	if actorUserID == "" {
		return model.UserRoute{}, ErrUserRouteAuthRequired
	}
	route, err := uc.readableRoute(ctx, actorUserID, strings.TrimSpace(input.RouteID))
	if err != nil {
		return model.UserRoute{}, err
	}
	if err := uc.repo.DeleteRouteBookmark(ctx, actorUserID, route.ID); err != nil {
		return model.UserRoute{}, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	return uc.withViewerState(ctx, route, actorUserID)
}

func (uc *UserRouteUseCase) CopyRoute(ctx context.Context, input CopyRouteInput) (model.UserRoute, error) {
	actorUserID := strings.TrimSpace(input.ActorUserID)
	if actorUserID == "" {
		return model.UserRoute{}, ErrUserRouteAuthRequired
	}
	source, err := uc.readableRoute(ctx, actorUserID, strings.TrimSpace(input.RouteID))
	if err != nil {
		return model.UserRoute{}, err
	}
	now := uc.now().UTC()
	sourceID := source.ID
	copy := source
	copy.ID = newRouteID()
	copy.OwnerUserID = actorUserID
	copy.SourceRouteID = &sourceID
	copy.Visibility = model.RouteVisibilityPrivate
	copy.Stats = model.UserRouteStats{}
	copy.SavedByMe = false
	copy.CreatedAt = now
	copy.UpdatedAt = now
	copy.Normalize()
	if err := copy.Validate(); err != nil {
		return model.UserRoute{}, err
	}
	if err := uc.repo.CreateRouteCopy(ctx, source.ID, copy, now); err != nil {
		return model.UserRoute{}, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	return copy, nil
}

func (uc *UserRouteUseCase) readableRoute(ctx context.Context, actorUserID string, routeID string) (model.UserRoute, error) {
	if routeID == "" {
		return model.UserRoute{}, ErrUserRouteNotFound
	}
	route, ok, err := uc.repo.FindRouteByID(ctx, routeID)
	if err != nil {
		return model.UserRoute{}, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	if !ok || !route.IsReadableBy(actorUserID) {
		return model.UserRoute{}, ErrUserRouteNotFound
	}
	return route, nil
}

func (uc *UserRouteUseCase) withViewerState(ctx context.Context, route model.UserRoute, actorUserID string) (model.UserRoute, error) {
	actorUserID = strings.TrimSpace(actorUserID)
	if actorUserID != "" {
		saved, err := uc.repo.HasRouteBookmark(ctx, actorUserID, route.ID)
		if err != nil {
			return model.UserRoute{}, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
		}
		route.SavedByMe = saved
	}
	saves, err := uc.repo.CountRouteBookmarks(ctx, route.ID)
	if err != nil {
		return model.UserRoute{}, fmt.Errorf("%w: %v", ErrUserRoutePersistenceFailed, err)
	}
	route.Stats.SavesCount = saves
	return route, nil
}

func normalizeLimit(limit int) int {
	if limit <= 0 {
		return 20
	}
	if limit > 50 {
		return 50
	}
	return limit
}

func clonePoints(points []model.UserRoutePoint) []model.UserRoutePoint {
	if len(points) == 0 {
		return nil
	}
	out := make([]model.UserRoutePoint, len(points))
	copy(out, points)
	return out
}

func moderationStatusForVisibility(
	visibility model.RouteVisibility,
	current model.RouteModerationStatus,
) model.RouteModerationStatus {
	if current == model.RouteModerationStatusHidden {
		return model.RouteModerationStatusHidden
	}
	if model.NormalizeVisibility(visibility) == model.RouteVisibilityPublic {
		return model.RouteModerationStatusPending
	}
	return model.RouteModerationStatusApproved
}

func moderationStatusForDecision(decision string) (model.RouteModerationStatus, error) {
	switch strings.ToLower(strings.TrimSpace(decision)) {
	case "approve", "approved":
		return model.RouteModerationStatusApproved, nil
	case "reject", "rejected":
		return model.RouteModerationStatusRejected, nil
	case "hide", "hidden":
		return model.RouteModerationStatusHidden, nil
	default:
		return "", ErrUserRouteInvalidDecision
	}
}

func newRouteID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return fmt.Sprintf("route-%d", time.Now().UnixNano())
	}
	return "route_" + hex.EncodeToString(raw[:])
}
