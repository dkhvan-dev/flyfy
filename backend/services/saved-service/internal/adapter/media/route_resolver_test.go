package media

import (
	"errors"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestRouteResolverBuildsOnlyVerifiedDomainRoutes(t *testing.T) {
	resolver, err := NewRouteResolver("https://api.inflap.example")
	if err != nil {
		t.Fatalf("NewRouteResolver() error = %v", err)
	}
	activityID := uuid.NewString()
	attractionID := uuid.NewString()
	guideID := uuid.NewString()
	avatarID := uuid.NewString()
	postID := uuid.NewString()
	postCoverID := uuid.NewString()
	tests := []struct {
		entityType domain.EntityType
		entityID   string
		opaque     string
		want       string
	}{
		{
			entityType: domain.EntityTypeActivity,
			entityID:   activityID,
			opaque:     "/api/v1/activities/" + activityID + "/cover?saved_revision=41",
			want:       "https://api.inflap.example/api/v1/activities/" + activityID + "/cover?saved_revision=41",
		},
		{
			entityType: domain.EntityTypeAttraction,
			entityID:   attractionID,
			opaque:     "attraction-cover:" + attractionID + ":41",
			want:       "https://api.inflap.example/api/v1/places/" + attractionID + "/saved-cover?saved_revision=41",
		},
		{
			entityType: domain.EntityTypeGuide,
			entityID:   guideID,
			opaque:     "guide-avatar:" + guideID + ":" + avatarID + ":41",
			want:       "https://api.inflap.example/api/v1/guides/public/by-user/" + guideID + "/saved-avatar?saved_revision=41",
		},
		{
			entityType: domain.EntityTypePost,
			entityID:   postID,
			opaque:     "post-cover:" + postID + ":" + postCoverID + ":41",
			want:       "https://api.inflap.example/api/v1/public/files/" + postCoverID + "/content?saved_revision=41",
		},
	}
	for _, test := range tests {
		target, targetErr := domain.NewSavedTarget(test.entityType, test.entityID)
		if targetErr != nil {
			t.Fatalf("NewSavedTarget() error = %v", targetErr)
		}
		resolved, resolveErr := resolver.Resolve(Reference{
			Target: target, OpaqueReference: test.opaque, ReferenceRevision: 41,
		})
		if resolveErr != nil || resolved != test.want {
			t.Errorf("Resolve(%s) = (%q, %v), want %q", test.entityType, resolved, resolveErr, test.want)
		}
	}
}

func TestRouteResolverRejectsStaleMismatchedAndInjectedReferences(t *testing.T) {
	resolver, err := NewRouteResolver("https://api.inflap.example")
	if err != nil {
		t.Fatalf("NewRouteResolver() error = %v", err)
	}
	activityID := uuid.NewString()
	target, err := domain.NewSavedTarget(domain.EntityTypeActivity, activityID)
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	for _, opaque := range []string{
		"/api/v1/activities/" + activityID + "/cover?saved_revision=40",
		"/api/v1/activities/" + activityID + "/cover?saved_revision=41&redirect=https://evil.example",
		"https://evil.example/api/v1/activities/" + activityID + "/cover?saved_revision=41",
		"/api/v1/activities/" + uuid.NewString() + "/cover?saved_revision=41",
		"/api/v1/activities/" + activityID + "/cover?saved_revision=041",
	} {
		if _, err := resolver.Resolve(Reference{
			Target: target, OpaqueReference: opaque, ReferenceRevision: 41,
		}); !errors.Is(err, ErrInvalidReference) {
			t.Errorf("Resolve(%q) error = %v", opaque, err)
		}
	}
}

func TestNewRouteResolverRejectsNonOrigin(t *testing.T) {
	for _, origin := range []string{
		"", "api.inflap.example", "https://user@api.inflap.example", "https://api.inflap.example/base",
	} {
		if _, err := NewRouteResolver(origin); !errors.Is(err, ErrInvalidOrigin) {
			t.Errorf("NewRouteResolver(%q) error = %v", origin, err)
		}
	}
}
