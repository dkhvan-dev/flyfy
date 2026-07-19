package media

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	"kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestResolveCollectionThumbnailsSkipsInvalidCandidateWithoutUsingSecondItem(t *testing.T) {
	resolver, err := NewRouteResolver("https://api.inflap.example")
	if err != nil {
		t.Fatalf("NewRouteResolver() error = %v", err)
	}
	validCollectionID := uuid.New()
	invalidCollectionID := uuid.New()
	activityID := uuid.NewString()
	target, err := domain.NewSavedTarget(domain.EntityTypeActivity, activityID)
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	resolved, err := resolver.ResolveCollectionThumbnails(context.Background(), []savedcollection.ThumbnailRequest{
		{
			CollectionID: validCollectionID,
			Target:       target, OpaqueReference: "/api/v1/activities/" + activityID + "/cover?saved_revision=8",
			ReferenceRevision: 8,
		},
		{
			CollectionID: invalidCollectionID,
			Target:       target, OpaqueReference: "https://evil.example/image.jpg",
			ReferenceRevision: 8,
		},
	})
	if err != nil {
		t.Fatalf("ResolveCollectionThumbnails() error = %v", err)
	}
	if len(resolved) != 1 || resolved[validCollectionID] == "" {
		t.Fatalf("resolved = %#v", resolved)
	}
	if _, exists := resolved[invalidCollectionID]; exists {
		t.Fatalf("invalid first-item candidate received a fallback: %#v", resolved)
	}
}

func TestResolveItemImagesBuildsPublicRouteAndSkipsMalformedReference(t *testing.T) {
	resolver, err := NewRouteResolver("https://api.inflap.example")
	if err != nil {
		t.Fatalf("NewRouteResolver() error = %v", err)
	}
	validItemID := uuid.New()
	invalidItemID := uuid.New()
	guideID := uuid.NewString()
	fileID := uuid.NewString()
	target, err := domain.NewSavedTarget(domain.EntityTypeGuide, guideID)
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}

	resolved, err := resolver.ResolveItemImages(context.Background(), []savedquery.ImageRequest{
		{
			ItemID:            validItemID,
			Target:            target,
			OpaqueReference:   "guide-avatar:" + guideID + ":" + fileID + ":12",
			ReferenceRevision: 12,
		},
		{
			ItemID:            invalidItemID,
			Target:            target,
			OpaqueReference:   "https://evil.example/avatar.jpg",
			ReferenceRevision: 12,
		},
	})
	if err != nil {
		t.Fatalf("ResolveItemImages() error = %v", err)
	}
	want := "https://api.inflap.example/api/v1/guides/public/by-user/" + guideID +
		"/saved-avatar?saved_revision=12"
	if len(resolved) != 1 || resolved[validItemID] != want {
		t.Fatalf("resolved = %#v, want valid URL %q", resolved, want)
	}
	if _, exists := resolved[invalidItemID]; exists {
		t.Fatalf("malformed reference resolved: %#v", resolved)
	}
}
