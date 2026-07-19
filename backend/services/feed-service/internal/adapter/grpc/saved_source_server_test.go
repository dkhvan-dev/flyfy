package grpc

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/feed-service/internal/app"
	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

type savedPostGRPCRepositoryStub struct {
	post *model.Post
}

func (stub savedPostGRPCRepositoryStub) GetPostByID(
	context.Context,
	uuid.UUID,
) (*model.Post, error) {
	return stub.post, nil
}

type savedPostAuthorizerStub struct {
	token string
	roles []string
	calls int
}

func (stub *savedPostAuthorizerStub) ValidateBearer(
	_ context.Context,
	token string,
	roles []string,
) (*serviceauth.Claims, error) {
	stub.calls++
	stub.token = token
	stub.roles = append([]string(nil), roles...)
	return &serviceauth.Claims{Subject: "saved-service"}, nil
}

func TestSavedPostSourceServerReturnsAuthenticatedPublicProjection(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 18, 12, 0, 0, 0, time.UTC)
	postID := uuid.MustParse("81ec585b-8eeb-4ff9-b5bd-80fdfbfaa9de")
	coverID := uuid.MustParse("301d2c5e-cd67-45e9-9c6f-6323b5016254")
	authorizer := &savedPostAuthorizerStub{}
	server := NewSavedPostSourceServer(
		app.NewSavedPostSourceUseCase(
			savedPostGRPCRepositoryStub{post: &model.Post{
				ID:               postID,
				Title:            "Almaty weekend",
				Excerpt:          "A compact itinerary",
				Status:           enum.PostStatusPublished,
				MediaStatus:      enum.PostMediaStatusReady,
				ModerationStatus: enum.ModerationStatusApproved,
				Revision:         11,
				CoverFileID:      &coverID,
				CreatedAt:        now.Add(-time.Hour),
				UpdatedAt:        now,
			}},
			app.WithSavedPostSourceClock(func() time.Time { return now }),
		),
		authorizer,
	)
	ctx := metadata.NewIncomingContext(
		context.Background(),
		metadata.Pairs("authorization", "Bearer saved-token"),
	)

	response, err := server.ResolveSaveEligibility(ctx, &contentv1.ResolveSaveEligibilityRequest{
		Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_POST,
			EntityId:   postID.String(),
		},
	})
	if err != nil {
		t.Fatalf("ResolveSaveEligibility() error = %v", err)
	}
	if authorizer.calls != 1 || authorizer.token != "Bearer saved-token" ||
		len(authorizer.roles) != 1 || authorizer.roles[0] != savedPostSourceResolveRole {
		t.Fatalf("authorizer call = %d/%q/%v", authorizer.calls, authorizer.token, authorizer.roles)
	}
	if response.GetEligibility() != contentv1.SaveEligibility_SAVE_ELIGIBILITY_ELIGIBLE ||
		response.GetVisibility() != contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC ||
		response.GetTarget().GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_POST ||
		response.GetRevisions().GetSourceRevision() != 11 {
		t.Fatalf("response contract = %#v", response)
	}
	projection := response.GetPublicProjection()
	if projection.GetCanonicalDetailRoute() != "/posts/"+postID.String() ||
		projection.GetEn().GetTitle() != "Almaty weekend" ||
		projection.GetRu().GetTitle() != "Almaty weekend" ||
		projection.GetKk().GetTitle() != "Almaty weekend" ||
		projection.GetMedia().GetOpaqueReference() !=
			"post-cover:"+postID.String()+":"+coverID.String()+":11" {
		t.Fatalf("projection contract = %#v", projection)
	}
}

func TestSavedPostSourceServerRejectsUnauthenticatedAndNonPostTargets(t *testing.T) {
	t.Parallel()

	postID := uuid.MustParse("81ec585b-8eeb-4ff9-b5bd-80fdfbfaa9de")
	authorizer := &savedPostAuthorizerStub{}
	server := NewSavedPostSourceServer(app.NewSavedPostSourceUseCase(savedPostGRPCRepositoryStub{}), authorizer)
	request := &contentv1.ResolveSaveEligibilityRequest{Target: &contentv1.SavedTarget{
		EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_POST,
		EntityId:   postID.String(),
	}}

	if _, err := server.ResolveSaveEligibility(context.Background(), request); status.Code(err) != codes.Unauthenticated {
		t.Fatalf("missing token error = %v, want Unauthenticated", err)
	}
	ctx := metadata.NewIncomingContext(
		context.Background(),
		metadata.Pairs("authorization", "Bearer saved-token"),
	)
	request.Target.EntityType = contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY
	if _, err := server.ResolveSaveEligibility(ctx, request); status.Code(err) != codes.InvalidArgument {
		t.Fatalf("non-post target error = %v, want InvalidArgument", err)
	}
}
