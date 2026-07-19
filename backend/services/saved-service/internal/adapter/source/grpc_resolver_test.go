package source

import (
	"context"
	"errors"
	"math"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

const (
	testAttractionID = "00f26a72-9b6b-4af1-90d6-6b9bd30465be"
	testActivityID   = "2e10ad76-b95c-46c8-ac94-34cb1743a965"
	testGuideID      = "5ce1653a-a4c5-4601-bcea-1b35d172fc71"
	testPostID       = "81ec585b-8eeb-4ff9-b5bd-80fdfbfaa9de"
	otherTargetID    = "b2ac0728-8ad1-42f9-af95-cdd939fd887b"
)

var testNow = time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)

type fakeSavedSourceRPC struct {
	resolve func(
		context.Context,
		*contentv1.ResolveSaveEligibilityRequest,
		...grpc.CallOption,
	) (*contentv1.ResolveSaveEligibilityResponse, error)
}

func (f *fakeSavedSourceRPC) ResolveSaveEligibility(
	ctx context.Context,
	request *contentv1.ResolveSaveEligibilityRequest,
	options ...grpc.CallOption,
) (*contentv1.ResolveSaveEligibilityResponse, error) {
	return f.resolve(ctx, request, options...)
}

func TestGRPCResolverMapsBoundedPublicProjection(t *testing.T) {
	t.Parallel()

	response := validPublicResponse(domain.EntityTypeAttraction, testAttractionID, testNow)
	response.PublicProjection.Ru = &contentv1.SavedLocalizedCardProjection{
		Title:               "Медеу",
		Subtitle:            "Высокогорный каток",
		City:                "Алматы",
		Country:             "Казахстан",
		DisplayLocation:     "Медеуский район",
		PriceSummary:        "от 2 000 KZT",
		AvailabilitySummary: "доступно сегодня",
	}
	response.PublicProjection.Rating = &contentv1.SavedRatingSummary{
		Value:       4.8,
		ReviewCount: 412,
		ScaleMax:    5,
	}
	response.PublicProjection.AsOf = timestamppb.New(testNow.Add(-time.Minute))
	response.PublicProjection.ValidUntil = timestamppb.New(testNow.Add(10 * time.Minute))
	response.PublicProjection.Media = &contentv1.SavedMediaReference{
		OpaqueReference:   "attraction-cover:opaque:19",
		ReferenceRevision: 19,
		ValidUntil:        timestamppb.New(testNow.Add(5 * time.Minute)),
	}

	client := &fakeSavedSourceRPC{resolve: func(
		ctx context.Context,
		request *contentv1.ResolveSaveEligibilityRequest,
		_ ...grpc.CallOption,
	) (*contentv1.ResolveSaveEligibilityResponse, error) {
		deadline, ok := ctx.Deadline()
		if !ok || time.Until(deadline) > maxResolveTimeout+100*time.Millisecond {
			t.Fatalf("resolver call deadline = %v, want at most %v", deadline, maxResolveTimeout)
		}
		if request.GetTarget().GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION ||
			request.GetTarget().GetEntityId() != testAttractionID {
			t.Fatalf("request target = %#v", request.GetTarget())
		}
		return response, nil
	}}
	resolver := mustTestResolver(t, domain.EntityTypeAttraction, client, maxResolveTimeout)
	target := mustTestTarget(t, domain.EntityTypeAttraction, testAttractionID)

	result, err := resolver.Resolve(context.Background(), target)
	if err != nil {
		t.Fatalf("Resolve() error = %v", err)
	}
	if !result.Eligible || result.Visibility != domain.VisibilityPublic ||
		result.Target.EntityID() != testAttractionID || result.PublicProjection == nil {
		t.Fatalf("Resolve() result = %#v", result)
	}
	projection := result.PublicProjection
	if projection.SourceDefaultLocale != appsource.LocaleEN ||
		projection.CanonicalDetailRoute != "/places/"+testAttractionID ||
		projection.Localized[appsource.LocaleRU].Title != "Медеу" ||
		projection.Rating == nil || projection.Rating.Value != 4.8 ||
		projection.AsOf == nil || projection.ValidUntil == nil ||
		projection.Media == nil || projection.Media.ReferenceRevision != 19 {
		t.Fatalf("mapped projection = %#v", projection)
	}
}

func TestGRPCResolverMapsPostTargetAndCanonicalRoute(t *testing.T) {
	t.Parallel()

	response := validPublicResponse(domain.EntityTypePost, testPostID, testNow)
	response.PublicProjection.Media = &contentv1.SavedMediaReference{
		OpaqueReference:   "post-cover:" + testPostID + ":301d2c5e-cd67-45e9-9c6f-6323b5016254:17",
		ReferenceRevision: 17,
		ValidUntil:        timestamppb.New(testNow.Add(5 * time.Minute)),
	}
	client := &fakeSavedSourceRPC{resolve: func(
		_ context.Context,
		request *contentv1.ResolveSaveEligibilityRequest,
		_ ...grpc.CallOption,
	) (*contentv1.ResolveSaveEligibilityResponse, error) {
		if request.GetTarget().GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_POST ||
			request.GetTarget().GetEntityId() != testPostID {
			t.Fatalf("post request target = %#v", request.GetTarget())
		}
		return response, nil
	}}

	result, err := mustTestResolver(t, domain.EntityTypePost, client, maxResolveTimeout).Resolve(
		context.Background(),
		mustTestTarget(t, domain.EntityTypePost, testPostID),
	)
	if err != nil {
		t.Fatalf("Resolve(POST) error = %v", err)
	}
	if !result.Eligible || result.PublicProjection == nil ||
		result.PublicProjection.CanonicalDetailRoute != "/posts/"+testPostID ||
		result.PublicProjection.Media == nil ||
		result.PublicProjection.Media.ReferenceRevision != 17 {
		t.Fatalf("Resolve(POST) result = %#v", result)
	}
}

func TestGRPCResolverRejectsMalformedEligibilityMatrices(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		mutate func(*contentv1.ResolveSaveEligibilityResponse)
	}{
		{
			name: "eligible private",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.Visibility = contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PRIVATE
				response.PublicProjection = nil
			},
		},
		{
			name: "ineligible public",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.Eligibility = contentv1.SaveEligibility_SAVE_ELIGIBILITY_INELIGIBLE
			},
		},
		{
			name: "non-public payload",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.Eligibility = contentv1.SaveEligibility_SAVE_ELIGIBILITY_INELIGIBLE
				response.Visibility = contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE
			},
		},
		{
			name: "public without projection",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection = nil
			},
		},
		{
			name: "unspecified eligibility",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.Eligibility = contentv1.SaveEligibility_SAVE_ELIGIBILITY_UNSPECIFIED
				response.Visibility = contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE
				response.PublicProjection = nil
			},
		},
		{
			name: "unspecified visibility",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.Visibility = contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNSPECIFIED
			},
		},
		{
			name: "zero revision",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.Revisions.ProjectionRevision = 0
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			response := proto.Clone(
				validPublicResponse(domain.EntityTypeActivity, testActivityID, testNow),
			).(*contentv1.ResolveSaveEligibilityResponse)
			test.mutate(response)
			resolver := resolverReturning(t, domain.EntityTypeActivity, response)

			result, err := resolver.Resolve(
				context.Background(),
				mustTestTarget(t, domain.EntityTypeActivity, testActivityID),
			)
			if !errors.Is(err, domain.ErrDependencyUnavailable) {
				t.Fatalf("Resolve() error = %v, want dependency unavailable", err)
			}
			if result.PublicProjection != nil {
				t.Fatalf("malformed response leaked projection: %#v", result.PublicProjection)
			}
		})
	}
}

func TestGRPCResolverRejectsTargetAndRouteSubstitution(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		mutate func(*contentv1.ResolveSaveEligibilityResponse)
	}{
		{
			name: "entity id substitution",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.Target.EntityId = otherTargetID
			},
		},
		{
			name: "entity type substitution",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.Target.EntityType = contentv1.SavedEntityType_SAVED_ENTITY_TYPE_GUIDE
			},
		},
		{
			name: "route target substitution",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.CanonicalDetailRoute = "/activities/" + otherTargetID
			},
		},
		{
			name: "route query",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.CanonicalDetailRoute += "?source=saved"
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			response := validPublicResponse(domain.EntityTypeActivity, testActivityID, testNow)
			test.mutate(response)
			resolver := resolverReturning(t, domain.EntityTypeActivity, response)
			result, err := resolver.Resolve(
				context.Background(),
				mustTestTarget(t, domain.EntityTypeActivity, testActivityID),
			)
			if !errors.Is(err, domain.ErrDependencyUnavailable) || result.PublicProjection != nil {
				t.Fatalf("Resolve() = (%#v, %v), want fail-closed", result, err)
			}
		})
	}
}

func TestGRPCResolverAcceptsPayloadFreePrivateActivity(t *testing.T) {
	t.Parallel()

	response := validDenyResponse(
		domain.EntityTypeActivity,
		testActivityID,
		contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PRIVATE,
		testNow,
	)
	result, err := resolverReturning(t, domain.EntityTypeActivity, response).Resolve(
		context.Background(),
		mustTestTarget(t, domain.EntityTypeActivity, testActivityID),
	)
	if err != nil {
		t.Fatalf("Resolve() error = %v", err)
	}
	if result.Eligible || result.Visibility != domain.VisibilityPrivate || result.PublicProjection != nil {
		t.Fatalf("private Activity result = %#v", result)
	}
}

func TestGRPCResolverRejectsPrivateNonActivity(t *testing.T) {
	t.Parallel()

	for _, test := range []struct {
		entityType domain.EntityType
		entityID   string
	}{
		{domain.EntityTypeAttraction, testAttractionID},
		{domain.EntityTypeGuide, testGuideID},
	} {
		test := test
		t.Run(string(test.entityType), func(t *testing.T) {
			t.Parallel()
			response := validDenyResponse(
				test.entityType,
				test.entityID,
				contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PRIVATE,
				testNow,
			)
			result, err := resolverReturning(t, test.entityType, response).Resolve(
				context.Background(),
				mustTestTarget(t, test.entityType, test.entityID),
			)
			if !errors.Is(err, domain.ErrDependencyUnavailable) || result.PublicProjection != nil {
				t.Fatalf("Resolve() = (%#v, %v), want fail-closed", result, err)
			}
		})
	}
}

func TestGRPCResolverRejectsInvalidTimestampsAndExpiredPayloads(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		mutate func(*contentv1.ResolveSaveEligibilityResponse)
	}{
		{
			name: "future validation",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.ValidatedAt = timestamppb.New(testNow.Add(maxFutureClockSkew + time.Second))
			},
		},
		{
			name: "stale validation",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.ValidatedAt = timestamppb.New(testNow.Add(-maxValidationAge - time.Second))
			},
		},
		{
			name: "expired dynamic summary",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.En.PriceSummary = "from 20 USD"
				response.PublicProjection.AsOf = timestamppb.New(testNow.Add(-time.Hour))
				response.PublicProjection.ValidUntil = timestamppb.New(testNow.Add(-time.Second))
			},
		},
		{
			name: "summary missing as of",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.En.AvailabilitySummary = "available"
				response.PublicProjection.ValidUntil = timestamppb.New(testNow.Add(time.Hour))
			},
		},
		{
			name: "expired media",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.Media = &contentv1.SavedMediaReference{
					OpaqueReference:   "opaque:cover:8",
					ReferenceRevision: 8,
					ValidUntil:        timestamppb.New(testNow.Add(-time.Second)),
				}
			},
		},
		{
			name: "unbounded media lease",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.Media = &contentv1.SavedMediaReference{
					OpaqueReference:   "opaque:cover:8",
					ReferenceRevision: 8,
					ValidUntil:        timestamppb.New(testNow.Add(maxMediaLease + time.Second)),
				}
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			response := validPublicResponse(domain.EntityTypeGuide, testGuideID, testNow)
			test.mutate(response)
			result, err := resolverReturning(t, domain.EntityTypeGuide, response).Resolve(
				context.Background(),
				mustTestTarget(t, domain.EntityTypeGuide, testGuideID),
			)
			if !errors.Is(err, domain.ErrDependencyUnavailable) || result.PublicProjection != nil {
				t.Fatalf("Resolve() = (%#v, %v), want fail-closed", result, err)
			}
		})
	}
}

func TestGRPCResolverRejectsMalformedLocaleRatingAndProjectionBounds(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		mutate func(*contentv1.ResolveSaveEligibilityResponse)
	}{
		{
			name: "missing localized title",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.En.Title = ""
			},
		},
		{
			name: "unknown default locale",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.SourceDefaultLocale = contentv1.SavedLocale(99)
			},
		},
		{
			name: "default locale payload absent",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.SourceDefaultLocale = contentv1.SavedLocale_SAVED_LOCALE_RU
			},
		},
		{
			name: "oversized title",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.En.Title = strings.Repeat("a", maxTitleBytes+1)
			},
		},
		{
			name: "rating missing as of",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.Rating = &contentv1.SavedRatingSummary{Value: 4, ScaleMax: 5}
			},
		},
		{
			name: "non-finite rating",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.Rating = &contentv1.SavedRatingSummary{
					Value: math.NaN(), ScaleMax: 5,
				}
				response.PublicProjection.AsOf = timestamppb.New(testNow)
			},
		},
		{
			name: "rating above scale",
			mutate: func(response *contentv1.ResolveSaveEligibilityResponse) {
				response.PublicProjection.Rating = &contentv1.SavedRatingSummary{Value: 6, ScaleMax: 5}
				response.PublicProjection.AsOf = timestamppb.New(testNow)
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			response := validPublicResponse(domain.EntityTypeAttraction, testAttractionID, testNow)
			test.mutate(response)
			result, err := resolverReturning(t, domain.EntityTypeAttraction, response).Resolve(
				context.Background(),
				mustTestTarget(t, domain.EntityTypeAttraction, testAttractionID),
			)
			if !errors.Is(err, domain.ErrDependencyUnavailable) || result.PublicProjection != nil {
				t.Fatalf("Resolve() = (%#v, %v), want fail-closed", result, err)
			}
		})
	}
}

func TestGRPCResolverClassifiesRPCFailuresWithoutLeakingDetails(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		rpcErr  error
		wantErr error
	}{
		{name: "not found", rpcErr: status.Error(codes.NotFound, "target "+testGuideID+" missing"), wantErr: domain.ErrTargetUnavailable},
		{name: "invalid canonical target", rpcErr: status.Error(codes.InvalidArgument, "bad "+testGuideID), wantErr: domain.ErrTargetUnavailable},
		{name: "unavailable", rpcErr: status.Error(codes.Unavailable, "database at secret-host failed"), wantErr: domain.ErrDependencyUnavailable},
		{name: "deadline", rpcErr: status.Error(codes.DeadlineExceeded, "upstream timeout"), wantErr: domain.ErrDependencyUnavailable},
		{name: "remote cancellation", rpcErr: status.Error(codes.Canceled, "source canceled"), wantErr: domain.ErrDependencyUnavailable},
		{name: "unknown", rpcErr: status.Error(codes.Unknown, "raw source failure"), wantErr: domain.ErrDependencyUnavailable},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			client := &fakeSavedSourceRPC{resolve: func(
				context.Context,
				*contentv1.ResolveSaveEligibilityRequest,
				...grpc.CallOption,
			) (*contentv1.ResolveSaveEligibilityResponse, error) {
				return nil, test.rpcErr
			}}
			resolver := mustTestResolver(t, domain.EntityTypeGuide, client, maxResolveTimeout)
			_, err := resolver.Resolve(
				context.Background(),
				mustTestTarget(t, domain.EntityTypeGuide, testGuideID),
			)
			if !errors.Is(err, test.wantErr) {
				t.Fatalf("Resolve() error = %v, want %v", err, test.wantErr)
			}
			if err.Error() != test.wantErr.Error() {
				t.Fatalf("error leaked transport details: %q", err)
			}
		})
	}
}

func TestGRPCResolverPropagatesCancellationAndBoundsDeadline(t *testing.T) {
	t.Parallel()

	t.Run("caller cancellation", func(t *testing.T) {
		var calls atomic.Int32
		client := &fakeSavedSourceRPC{resolve: func(
			context.Context,
			*contentv1.ResolveSaveEligibilityRequest,
			...grpc.CallOption,
		) (*contentv1.ResolveSaveEligibilityResponse, error) {
			calls.Add(1)
			return nil, nil
		}}
		resolver := mustTestResolver(t, domain.EntityTypeActivity, client, maxResolveTimeout)
		ctx, cancel := context.WithCancel(context.Background())
		cancel()
		_, err := resolver.Resolve(ctx, mustTestTarget(t, domain.EntityTypeActivity, testActivityID))
		if !errors.Is(err, context.Canceled) || calls.Load() != 0 {
			t.Fatalf("Resolve() = (%v, calls=%d), want canceled before RPC", err, calls.Load())
		}
	})

	t.Run("resolver deadline", func(t *testing.T) {
		client := &fakeSavedSourceRPC{resolve: func(
			ctx context.Context,
			_ *contentv1.ResolveSaveEligibilityRequest,
			_ ...grpc.CallOption,
		) (*contentv1.ResolveSaveEligibilityResponse, error) {
			<-ctx.Done()
			return nil, status.FromContextError(ctx.Err()).Err()
		}}
		resolver := mustTestResolver(t, domain.EntityTypeActivity, client, 20*time.Millisecond)
		startedAt := time.Now()
		_, err := resolver.Resolve(
			context.Background(),
			mustTestTarget(t, domain.EntityTypeActivity, testActivityID),
		)
		if !errors.Is(err, domain.ErrDependencyUnavailable) {
			t.Fatalf("Resolve() error = %v, want dependency unavailable", err)
		}
		if elapsed := time.Since(startedAt); elapsed > time.Second {
			t.Fatalf("resolver deadline took %v", elapsed)
		}
	})

	t.Run("earlier parent deadline", func(t *testing.T) {
		deadlineSeen := make(chan time.Time, 1)
		client := &fakeSavedSourceRPC{resolve: func(
			ctx context.Context,
			_ *contentv1.ResolveSaveEligibilityRequest,
			_ ...grpc.CallOption,
		) (*contentv1.ResolveSaveEligibilityResponse, error) {
			deadline, ok := ctx.Deadline()
			if !ok {
				t.Fatal("RPC context has no deadline")
			}
			deadlineSeen <- deadline
			<-ctx.Done()
			return nil, status.FromContextError(ctx.Err()).Err()
		}}
		resolver := mustTestResolver(t, domain.EntityTypeActivity, client, maxResolveTimeout)
		ctx, cancel := context.WithTimeout(context.Background(), 40*time.Millisecond)
		parentDeadline, _ := ctx.Deadline()
		defer cancel()
		_, err := resolver.Resolve(ctx, mustTestTarget(t, domain.EntityTypeActivity, testActivityID))
		if !errors.Is(err, domain.ErrDependencyUnavailable) {
			t.Fatalf("Resolve() error = %v, want dependency unavailable", err)
		}
		if got := <-deadlineSeen; !got.Equal(parentDeadline) {
			t.Fatalf("RPC deadline = %v, want parent %v", got, parentDeadline)
		}
	})
}

func resolverReturning(
	t testing.TB,
	entityType domain.EntityType,
	response *contentv1.ResolveSaveEligibilityResponse,
) *GRPCResolver {
	t.Helper()
	return mustTestResolver(t, entityType, &fakeSavedSourceRPC{resolve: func(
		context.Context,
		*contentv1.ResolveSaveEligibilityRequest,
		...grpc.CallOption,
	) (*contentv1.ResolveSaveEligibilityResponse, error) {
		return response, nil
	}}, maxResolveTimeout)
}

func mustTestResolver(
	t testing.TB,
	entityType domain.EntityType,
	client savedSourceRPC,
	timeout time.Duration,
) *GRPCResolver {
	t.Helper()
	resolver, err := newGRPCResolver(entityType, client, timeout, func() time.Time { return testNow })
	if err != nil {
		t.Fatalf("newGRPCResolver() error = %v", err)
	}
	return resolver
}

func mustTestTarget(
	t testing.TB,
	entityType domain.EntityType,
	entityID string,
) domain.SavedTarget {
	t.Helper()
	target, err := domain.NewSavedTarget(entityType, entityID)
	if err != nil {
		t.Fatalf("domain.NewSavedTarget() error = %v", err)
	}
	return target
}

func validPublicResponse(
	entityType domain.EntityType,
	entityID string,
	now time.Time,
) *contentv1.ResolveSaveEligibilityResponse {
	protoType, _ := toProtoEntityType(entityType)
	return &contentv1.ResolveSaveEligibilityResponse{
		Target: &contentv1.SavedTarget{
			EntityType: protoType,
			EntityId:   entityID,
		},
		Eligibility: contentv1.SaveEligibility_SAVE_ELIGIBILITY_ELIGIBLE,
		Visibility:  contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC,
		Revisions: &contentv1.SavedSourceRevisions{
			SourceRevision:     10,
			ProjectionRevision: 11,
			VisibilityRevision: 12,
		},
		ValidatedAt: timestamppb.New(now),
		PublicProjection: &contentv1.SavedPublicCardProjection{
			SourceDefaultLocale:  contentv1.SavedLocale_SAVED_LOCALE_EN,
			En:                   &contentv1.SavedLocalizedCardProjection{Title: "Public title"},
			CanonicalDetailRoute: testRoute(entityType, entityID),
		},
	}
}

func validDenyResponse(
	entityType domain.EntityType,
	entityID string,
	visibility contentv1.SavedTargetVisibility,
	now time.Time,
) *contentv1.ResolveSaveEligibilityResponse {
	protoType, _ := toProtoEntityType(entityType)
	return &contentv1.ResolveSaveEligibilityResponse{
		Target:      &contentv1.SavedTarget{EntityType: protoType, EntityId: entityID},
		Eligibility: contentv1.SaveEligibility_SAVE_ELIGIBILITY_INELIGIBLE,
		Visibility:  visibility,
		Revisions: &contentv1.SavedSourceRevisions{
			SourceRevision: 1, ProjectionRevision: 1, VisibilityRevision: 1,
		},
		ValidatedAt: timestamppb.New(now),
	}
}

func testRoute(entityType domain.EntityType, entityID string) string {
	switch entityType {
	case domain.EntityTypeAttraction:
		return "/places/" + entityID
	case domain.EntityTypeActivity:
		return "/activities/" + entityID
	case domain.EntityTypeGuide:
		return "/users/" + entityID + "/profile"
	case domain.EntityTypeUser:
		return "/users/" + entityID + "/profile"
	case domain.EntityTypePost:
		return "/posts/" + entityID
	default:
		return ""
	}
}
