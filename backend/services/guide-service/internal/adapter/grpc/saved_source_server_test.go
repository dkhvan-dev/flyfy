package grpc

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/services/guide-service/internal/app"
	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

func TestResolveSavedGuideRejectsMalformedCanonicalID(t *testing.T) {
	server := NewServer(nil, WithSavedSource(app.NewSavedGuideSourceUseCase(
		&grpcSavedGuideRepositoryStub{},
		&grpcSavedGuideUserSourceStub{},
	)))
	ctx := withSavedSourceCaller(context.Background(), "saved-service")

	for _, rawID := range []string{
		"",
		" " + uuid.NewString(),
		strings.ToUpper(uuid.NewString()),
		uuid.Nil.String(),
		"not-a-uuid",
	} {
		t.Run(rawID, func(t *testing.T) {
			_, err := server.ResolveSaveEligibility(ctx, savedGuideRequest(rawID))
			if status.Code(err) != codes.InvalidArgument {
				t.Fatalf("ResolveSaveEligibility() code = %s, want InvalidArgument", status.Code(err))
			}
		})
	}
}

func TestResolveSavedGuideRequiresInterceptorAuthorization(t *testing.T) {
	server := NewServer(nil, WithSavedSource(app.NewSavedGuideSourceUseCase(
		&grpcSavedGuideRepositoryStub{},
		&grpcSavedGuideUserSourceStub{},
	)))
	_, err := server.ResolveSaveEligibility(context.Background(), savedGuideRequest(uuid.NewString()))
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("ResolveSaveEligibility() code = %s, want Unauthenticated", status.Code(err))
	}
}

func TestResolveSavedGuideUnknownTarget(t *testing.T) {
	server := NewServer(nil, WithSavedSource(app.NewSavedGuideSourceUseCase(
		&grpcSavedGuideRepositoryStub{},
		&grpcSavedGuideUserSourceStub{},
	)))
	ctx := withSavedSourceCaller(context.Background(), "saved-service")
	_, err := server.ResolveSaveEligibility(ctx, savedGuideRequest(uuid.NewString()))
	if status.Code(err) != codes.NotFound {
		t.Fatalf("ResolveSaveEligibility() code = %s, want NotFound", status.Code(err))
	}
}

func TestResolveSavedGuidePublicResponsePreservesCanonicalTargetAndLocale(t *testing.T) {
	userID := uuid.New()
	now := time.Date(2026, 7, 10, 12, 0, 0, 0, time.UTC)
	approved := enum.VerificationRequestStatusApproved
	nickname := "Aruzhan"
	avatarFileID := uuid.New()
	mediaRevision := uint64(now.UnixMicro())
	server := NewServer(nil, WithSavedSource(app.NewSavedGuideSourceUseCase(
		&grpcSavedGuideRepositoryStub{snapshot: &model.SavedGuideSnapshot{
			Profile: &model.GuideProfile{
				ID:        uuid.New(),
				UserID:    userID,
				Type:      enum.GuideTypeLocalExpert,
				Status:    enum.GuideStatusActive,
				RatingAvg: 5,
				CreatedAt: now.Add(-time.Hour),
				UpdatedAt: now,
			},
			LatestVerificationStatus:    &approved,
			LatestVerificationUpdatedAt: &now,
			SourceRevision:              mediaRevision,
			ProjectionRevision:          mediaRevision,
			VisibilityRevision:          mediaRevision,
			LifecycleVisibility:         model.SavedLifecycleVisibilityPublic,
			MediaReferenceRevision:      mediaRevision,
			MediaReferenceActive:        true,
			ExternalAvatarFileID:        &avatarFileID,
		}},
		&grpcSavedGuideUserSourceStub{snapshot: &app.SavedGuideUserSnapshot{
			UserID:           userID,
			AccountStatus:    "ACTIVE",
			Nickname:         &nickname,
			AvatarFileID:     &avatarFileID,
			Locale:           "en",
			AccountUpdatedAt: now,
			ProfileUpdatedAt: now,
		}},
		app.WithSavedGuideSourceClock(func() time.Time { return now.Add(time.Minute) }),
	)))

	ctx := withSavedSourceCaller(context.Background(), "saved-service")
	response, err := server.ResolveSaveEligibility(ctx, savedGuideRequest(userID.String()))
	if err != nil {
		t.Fatalf("ResolveSaveEligibility() error = %v", err)
	}
	if response.GetTarget().GetEntityId() != userID.String() ||
		response.GetTarget().GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_GUIDE {
		t.Fatalf("target = %+v", response.GetTarget())
	}
	if response.GetEligibility() != contentv1.SaveEligibility_SAVE_ELIGIBILITY_ELIGIBLE ||
		response.GetVisibility() != contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC {
		t.Fatalf("response = %+v", response)
	}
	projection := response.GetPublicProjection()
	if projection == nil || projection.GetEn().GetTitle() != nickname ||
		projection.GetRu() != nil || projection.GetKk() != nil {
		t.Fatalf("projection = %+v", projection)
	}
	wantMediaReference := fmt.Sprintf("guide-avatar:%s:%s:%d", userID, avatarFileID, mediaRevision)
	if projection.GetMedia().GetOpaqueReference() != wantMediaReference ||
		strings.Contains(projection.GetMedia().GetOpaqueReference(), "://") {
		t.Fatalf("wire media reference = %+v, want opaque %q", projection.GetMedia(), wantMediaReference)
	}
}

func TestResolveSavedGuideDeletedResponseIsPayloadFree(t *testing.T) {
	userID := uuid.New()
	now := time.Date(2026, 7, 10, 12, 0, 0, 0, time.UTC)
	server := NewServer(nil, WithSavedSource(app.NewSavedGuideSourceUseCase(
		&grpcSavedGuideRepositoryStub{snapshot: &model.SavedGuideSnapshot{
			Profile: &model.GuideProfile{
				ID: uuid.New(), UserID: userID, Type: enum.GuideTypeIndependent,
				Status: enum.GuideStatusRevoked, CreatedAt: now.Add(-time.Hour), UpdatedAt: now,
			},
			SourceRevision:         uint64(now.UnixMicro()),
			ProjectionRevision:     uint64(now.UnixMicro()),
			VisibilityRevision:     uint64(now.UnixMicro()),
			LifecycleVisibility:    model.SavedLifecycleVisibilityDeleted,
			MediaReferenceRevision: uint64(now.UnixMicro()),
		}},
		&grpcSavedGuideUserSourceStub{},
		app.WithSavedGuideSourceClock(func() time.Time { return now.Add(time.Minute) }),
	)))

	response, err := server.ResolveSaveEligibility(
		withSavedSourceCaller(context.Background(), "saved-service"),
		savedGuideRequest(userID.String()),
	)
	if err != nil {
		t.Fatalf("ResolveSaveEligibility() error = %v", err)
	}
	if response.GetEligibility() != contentv1.SaveEligibility_SAVE_ELIGIBILITY_INELIGIBLE ||
		response.GetVisibility() != contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_DELETED ||
		response.GetPublicProjection() != nil {
		t.Fatalf("deleted response = %+v", response)
	}
}

func savedGuideRequest(rawID string) *contentv1.ResolveSaveEligibilityRequest {
	return &contentv1.ResolveSaveEligibilityRequest{
		Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_GUIDE,
			EntityId:   rawID,
		},
	}
}

type grpcSavedGuideRepositoryStub struct {
	snapshot *model.SavedGuideSnapshot
	err      error
}

func (s *grpcSavedGuideRepositoryStub) GetSavedSourceGuide(
	context.Context,
	uuid.UUID,
) (*model.SavedGuideSnapshot, error) {
	return s.snapshot, s.err
}

type grpcSavedGuideUserSourceStub struct {
	snapshot *app.SavedGuideUserSnapshot
	err      error
}

func (s *grpcSavedGuideUserSourceStub) GetSavedGuideUserSnapshot(
	context.Context,
	uuid.UUID,
) (*app.SavedGuideUserSnapshot, error) {
	return s.snapshot, s.err
}
