package source

import (
	"context"
	"errors"
	"testing"

	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type routingResolver struct {
	calls  int
	result func(domain.SavedTarget) appsource.Resolution
}

func (r *routingResolver) Resolve(
	_ context.Context,
	target domain.SavedTarget,
) (appsource.Resolution, error) {
	r.calls++
	return r.result(target), nil
}

func TestRouterRoutesSupportedTypes(t *testing.T) {
	t.Parallel()

	attraction := validRoutingResolver()
	activity := validRoutingResolver()
	user := validRoutingResolver()
	post := validRoutingResolver()
	router, err := NewRouter(map[domain.EntityType]appsource.Resolver{
		domain.EntityTypeAttraction: attraction,
		domain.EntityTypeActivity:   activity,
		domain.EntityTypeUser:       user,
		domain.EntityTypePost:       post,
	})
	if err != nil {
		t.Fatalf("NewRouter() error = %v", err)
	}

	for _, test := range []struct {
		entityType domain.EntityType
		entityID   string
		wantCalls  [4]int
	}{
		{domain.EntityTypeAttraction, testAttractionID, [4]int{1, 0, 0, 0}},
		{domain.EntityTypeActivity, testActivityID, [4]int{1, 1, 0, 0}},
		{domain.EntityTypeUser, testGuideID, [4]int{1, 1, 1, 0}},
		{domain.EntityTypePost, testPostID, [4]int{1, 1, 1, 1}},
	} {
		result, resolveErr := router.Resolve(
			context.Background(),
			mustTestTarget(t, test.entityType, test.entityID),
		)
		if resolveErr != nil || result.Target.EntityType() != test.entityType {
			t.Fatalf("Resolve(%s) = (%#v, %v)", test.entityType, result, resolveErr)
		}
		gotCalls := [4]int{attraction.calls, activity.calls, user.calls, post.calls}
		if gotCalls != test.wantCalls {
			t.Fatalf("calls after %s = %v, want %v", test.entityType, gotCalls, test.wantCalls)
		}
	}
}

func TestRouterRejectsIncompleteOrUnknownConfiguration(t *testing.T) {
	t.Parallel()

	valid := validRoutingResolver()
	for _, resolvers := range []map[domain.EntityType]appsource.Resolver{
		{
			domain.EntityTypeAttraction: valid,
			domain.EntityTypeActivity:   valid,
		},
		{
			domain.EntityTypeAttraction:    valid,
			domain.EntityTypeActivity:      valid,
			domain.EntityTypeUser:          valid,
			domain.EntityTypePost:          valid,
			domain.EntityTypeGuide:         valid,
			domain.EntityType("EXCURSION"): valid,
		},
	} {
		if _, err := NewRouter(resolvers); !errors.Is(err, ErrInvalidResolverConfiguration) {
			t.Fatalf("NewRouter() error = %v, want invalid configuration", err)
		}
	}
}

func TestRouterFailsClosedOnInvalidResolverResult(t *testing.T) {
	t.Parallel()

	invalid := &routingResolver{result: func(target domain.SavedTarget) appsource.Resolution {
		return appsource.Resolution{
			Target:           target,
			Eligible:         false,
			Visibility:       domain.VisibilityUnavailable,
			PublicProjection: &appsource.PublicCardProjection{},
			Revisions: appsource.Revisions{
				Source: 1, Projection: 1, Visibility: 1,
			},
			ValidatedAt: testNow,
		}
	}}
	router, err := NewRouter(map[domain.EntityType]appsource.Resolver{
		domain.EntityTypeAttraction: invalid,
		domain.EntityTypeActivity:   validRoutingResolver(),
		domain.EntityTypeUser:       validRoutingResolver(),
		domain.EntityTypePost:       validRoutingResolver(),
	})
	if err != nil {
		t.Fatalf("NewRouter() error = %v", err)
	}
	result, err := router.Resolve(
		context.Background(),
		mustTestTarget(t, domain.EntityTypeAttraction, testAttractionID),
	)
	if !errors.Is(err, domain.ErrDependencyUnavailable) || result.PublicProjection != nil {
		t.Fatalf("Resolve() = (%#v, %v), want fail-closed", result, err)
	}
}

func validRoutingResolver() *routingResolver {
	return &routingResolver{result: func(target domain.SavedTarget) appsource.Resolution {
		return appsource.Resolution{
			Target:           target,
			Eligible:         true,
			Visibility:       domain.VisibilityPublic,
			PublicProjection: &appsource.PublicCardProjection{},
			Revisions: appsource.Revisions{
				Source: 1, Projection: 1, Visibility: 1,
			},
			ValidatedAt: testNow,
		}
	}}
}
