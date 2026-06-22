package app

import (
	"context"
	"sort"
	"strings"
	"sync"
	"time"

	"kz/inflap/backend/services/user-route-service/internal/domain/model"
)

type MemoryUserRouteRepository struct {
	mu     sync.RWMutex
	routes map[string]model.UserRoute
	saves  map[string]time.Time
}

func NewMemoryUserRouteRepository() *MemoryUserRouteRepository {
	return &MemoryUserRouteRepository{
		routes: make(map[string]model.UserRoute),
		saves:  make(map[string]time.Time),
	}
}

func (r *MemoryUserRouteRepository) SaveRoute(_ context.Context, route model.UserRoute) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.routes[route.ID] = cloneRoute(route)
	return nil
}

func (r *MemoryUserRouteRepository) CreateRouteCopy(
	_ context.Context,
	sourceRouteID string,
	copyRoute model.UserRoute,
	copiedAt time.Time,
) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	source, ok := r.routes[strings.TrimSpace(sourceRouteID)]
	if ok {
		source.Stats.CopiesCount++
		source.UpdatedAt = copiedAt.UTC()
		r.routes[source.ID] = cloneRoute(source)
	}
	r.routes[copyRoute.ID] = cloneRoute(copyRoute)
	return nil
}

func (r *MemoryUserRouteRepository) FindRouteByID(_ context.Context, routeID string) (model.UserRoute, bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	route, ok := r.routes[strings.TrimSpace(routeID)]
	if !ok {
		return model.UserRoute{}, false, nil
	}
	return cloneRoute(route), true, nil
}

func (r *MemoryUserRouteRepository) ListRoutes(_ context.Context, filter RouteListFilter) ([]model.UserRoute, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	routes := make([]model.UserRoute, 0, len(r.routes))
	for _, route := range r.routes {
		if filter.OwnerUserID != "" && route.OwnerUserID != filter.OwnerUserID {
			continue
		}
		if filter.PublicOnly && route.Visibility != model.RouteVisibilityPublic {
			continue
		}
		if filter.PublicOnly && route.ModerationStatus != model.RouteModerationStatusApproved {
			continue
		}
		if filter.CityCode != "" && route.CityCode != filter.CityCode {
			continue
		}
		if filter.ModerationStatus != "" && route.ModerationStatus != filter.ModerationStatus {
			continue
		}
		if filter.SavedByUserID != "" {
			if _, ok := r.saves[routeSaveKey(filter.SavedByUserID, route.ID)]; !ok {
				continue
			}
		}
		routes = append(routes, cloneRoute(route))
	}
	sort.SliceStable(routes, func(i, j int) bool {
		if !routes[i].UpdatedAt.Equal(routes[j].UpdatedAt) {
			return routes[i].UpdatedAt.After(routes[j].UpdatedAt)
		}
		return routes[i].ID < routes[j].ID
	})
	start := filter.Offset
	if start > len(routes) {
		return []model.UserRoute{}, nil
	}
	end := start + normalizeLimit(filter.Limit)
	if end > len(routes) {
		end = len(routes)
	}
	return routes[start:end], nil
}

func (r *MemoryUserRouteRepository) SaveRouteBookmark(_ context.Context, userID string, routeID string, createdAt time.Time) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.saves[routeSaveKey(userID, routeID)] = createdAt.UTC()
	return nil
}

func (r *MemoryUserRouteRepository) DeleteRouteBookmark(_ context.Context, userID string, routeID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.saves, routeSaveKey(userID, routeID))
	return nil
}

func (r *MemoryUserRouteRepository) HasRouteBookmark(_ context.Context, userID string, routeID string) (bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	_, ok := r.saves[routeSaveKey(userID, routeID)]
	return ok, nil
}

func (r *MemoryUserRouteRepository) CountRouteBookmarks(_ context.Context, routeID string) (int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	routeID = strings.TrimSpace(routeID)
	count := 0
	for key := range r.saves {
		if strings.HasSuffix(key, "\x00"+routeID) {
			count++
		}
	}
	return count, nil
}

func (r *MemoryUserRouteRepository) RouteCount() int {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.routes)
}

func cloneRoute(route model.UserRoute) model.UserRoute {
	route.Points = append([]model.UserRoutePoint(nil), route.Points...)
	route.Tags = append([]string(nil), route.Tags...)
	if route.SourceRouteID != nil {
		sourceID := *route.SourceRouteID
		route.SourceRouteID = &sourceID
	}
	if route.ModeratedByUserID != nil {
		moderatedBy := *route.ModeratedByUserID
		route.ModeratedByUserID = &moderatedBy
	}
	if route.ModeratedAt != nil {
		moderatedAt := *route.ModeratedAt
		route.ModeratedAt = &moderatedAt
	}
	return route
}

func routeSaveKey(userID string, routeID string) string {
	return strings.TrimSpace(userID) + "\x00" + strings.TrimSpace(routeID)
}
