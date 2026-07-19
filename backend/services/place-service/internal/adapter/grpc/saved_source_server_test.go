package grpc

import (
	"context"
	"errors"
	"slices"
	"strings"
	"testing"

	"github.com/google/uuid"
	gogrpc "google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/place-service/internal/app"
	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

func TestSavedSourceServerResolvesCanonicalPublicAttraction(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	repository := &grpcSavedSourceRepositoryStub{
		snapshot: grpcPublishedAttraction(attractionID),
	}
	repository.snapshot.Media = []model.PlaceMedia{{
		PlaceID:   attractionID,
		FileID:    uuid.New(),
		MediaType: enum.MediaPhoto,
	}}
	authorizer := &grpcSavedSourceAuthorizerStub{
		claims: &serviceauth.Claims{Subject: "saved-service"},
	}
	server := NewSavedSourceServer(app.NewSavedSourceUseCase(repository), authorizer)
	requestTarget := &contentv1.SavedTarget{
		EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION,
		EntityId:   attractionID.String(),
	}

	response, err := server.ResolveSaveEligibility(
		authorizedSavedSourceContext(),
		&contentv1.ResolveSaveEligibilityRequest{Target: requestTarget},
	)
	if err != nil {
		t.Fatalf("ResolveSaveEligibility() error = %v", err)
	}
	if response.GetTarget().GetEntityType() != requestTarget.GetEntityType() ||
		response.GetTarget().GetEntityId() != requestTarget.GetEntityId() {
		t.Fatalf("response target = %#v, want exact request target", response.GetTarget())
	}
	if response.GetEligibility() != contentv1.SaveEligibility_SAVE_ELIGIBILITY_ELIGIBLE ||
		response.GetVisibility() != contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC {
		t.Fatalf("eligibility/visibility = %s/%s", response.GetEligibility(), response.GetVisibility())
	}
	if response.GetRevisions().GetSourceRevision() != 11 ||
		response.GetRevisions().GetProjectionRevision() != 12 ||
		response.GetRevisions().GetVisibilityRevision() != 13 {
		t.Fatalf("revisions = %#v", response.GetRevisions())
	}
	if response.GetPublicProjection() == nil ||
		response.GetPublicProjection().GetEn().GetTitle() != "Public attraction" ||
		response.GetPublicProjection().GetRu() != nil ||
		response.GetPublicProjection().GetKk() != nil {
		t.Fatalf("public projection = %#v", response.GetPublicProjection())
	}
	media := response.GetPublicProjection().GetMedia()
	wantOpaqueReference := "attraction-cover:" + attractionID.String() + ":12"
	if media == nil ||
		media.GetOpaqueReference() != wantOpaqueReference ||
		media.GetReferenceRevision() != 12 ||
		strings.HasPrefix(media.GetOpaqueReference(), "http://") ||
		strings.HasPrefix(media.GetOpaqueReference(), "https://") {
		t.Fatalf("opaque media reference = %#v, want token %q", media, wantOpaqueReference)
	}
	if !slices.Equal(authorizer.requiredRoles, []string{SavedSourceResolveRole}) {
		t.Fatalf("required roles = %#v", authorizer.requiredRoles)
	}
}

func TestSavedSourceServerReturnsPayloadFreeRestrictedAttraction(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	snapshot := grpcPublishedAttraction(attractionID)
	snapshot.Status = enum.StatusDraft
	snapshot.Translations = map[string]model.PlaceTranslation{
		"en": {PlaceID: attractionID, Locale: "en", Title: "Hidden draft"},
	}
	server := NewSavedSourceServer(
		app.NewSavedSourceUseCase(&grpcSavedSourceRepositoryStub{snapshot: snapshot}),
		&grpcSavedSourceAuthorizerStub{claims: &serviceauth.Claims{Subject: "saved-service"}},
	)

	response, err := server.ResolveSaveEligibility(
		authorizedSavedSourceContext(),
		&contentv1.ResolveSaveEligibilityRequest{Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION,
			EntityId:   attractionID.String(),
		}},
	)
	if err != nil {
		t.Fatalf("ResolveSaveEligibility() error = %v", err)
	}
	if response.GetEligibility() != contentv1.SaveEligibility_SAVE_ELIGIBILITY_INELIGIBLE ||
		response.GetVisibility() != contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_RESTRICTED {
		t.Fatalf("response eligibility/visibility = %s/%s", response.GetEligibility(), response.GetVisibility())
	}
	if response.GetPublicProjection() != nil {
		t.Fatal("restricted attraction exposed public projection")
	}
}

func TestSavedSourceServerRejectsMalformedOrNonAttractionTargets(t *testing.T) {
	t.Parallel()

	canonicalID := uuid.New().String()
	tests := []struct {
		name   string
		target *contentv1.SavedTarget
	}{
		{name: "missing target"},
		{
			name: "wrong entity type",
			target: &contentv1.SavedTarget{
				EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY,
				EntityId:   canonicalID,
			},
		},
		{
			name: "surrounding whitespace",
			target: &contentv1.SavedTarget{
				EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION,
				EntityId:   " " + canonicalID,
			},
		},
		{
			name: "uppercase non canonical",
			target: &contentv1.SavedTarget{
				EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION,
				EntityId:   "AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA",
			},
		},
		{
			name: "nil uuid",
			target: &contentv1.SavedTarget{
				EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION,
				EntityId:   uuid.Nil.String(),
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			repository := &grpcSavedSourceRepositoryStub{}
			server := NewSavedSourceServer(
				app.NewSavedSourceUseCase(repository),
				&grpcSavedSourceAuthorizerStub{claims: &serviceauth.Claims{Subject: "saved-service"}},
			)
			_, err := server.ResolveSaveEligibility(
				authorizedSavedSourceContext(),
				&contentv1.ResolveSaveEligibilityRequest{Target: test.target},
			)
			if status.Code(err) != codes.InvalidArgument {
				t.Fatalf("code = %s, want InvalidArgument; err = %v", status.Code(err), err)
			}
			if repository.calls != 0 {
				t.Fatalf("repository calls = %d, want 0", repository.calls)
			}
		})
	}
}

func TestSavedSourceServerMapsUnknownToNeutralNotFound(t *testing.T) {
	t.Parallel()

	server := NewSavedSourceServer(
		app.NewSavedSourceUseCase(&grpcSavedSourceRepositoryStub{}),
		&grpcSavedSourceAuthorizerStub{claims: &serviceauth.Claims{Subject: "saved-service"}},
	)
	_, err := server.ResolveSaveEligibility(
		authorizedSavedSourceContext(),
		&contentv1.ResolveSaveEligibilityRequest{Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION,
			EntityId:   uuid.NewString(),
		}},
	)
	if status.Code(err) != codes.NotFound || status.Convert(err).Message() != "saved target unavailable" {
		t.Fatalf("error = %v, want neutral NotFound", err)
	}
}

func TestSavedSourceServerEnforcesServiceJWTAndLeastPrivilegeRole(t *testing.T) {
	t.Parallel()

	request := &contentv1.ResolveSaveEligibilityRequest{Target: &contentv1.SavedTarget{
		EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION,
		EntityId:   uuid.NewString(),
	}}
	tests := []struct {
		name       string
		ctx        context.Context
		authorizer ServiceAuthorizer
		wantCode   codes.Code
	}{
		{
			name:       "missing metadata",
			ctx:        context.Background(),
			authorizer: &grpcSavedSourceAuthorizerStub{claims: &serviceauth.Claims{Subject: "saved-service"}},
			wantCode:   codes.Unauthenticated,
		},
		{
			name: "forbidden role",
			ctx:  authorizedSavedSourceContext(),
			authorizer: &grpcSavedSourceAuthorizerStub{
				err: serviceauth.ErrForbiddenService,
			},
			wantCode: codes.PermissionDenied,
		},
		{
			name:       "auth dependency unavailable",
			ctx:        authorizedSavedSourceContext(),
			authorizer: &grpcSavedSourceAuthorizerStub{err: errors.New("jwks unavailable")},
			wantCode:   codes.Unavailable,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			server := NewSavedSourceServer(
				app.NewSavedSourceUseCase(&grpcSavedSourceRepositoryStub{}),
				test.authorizer,
			)
			_, err := server.ResolveSaveEligibility(test.ctx, request)
			if status.Code(err) != test.wantCode {
				t.Fatalf("code = %s, want %s; err = %v", status.Code(err), test.wantCode, err)
			}
		})
	}
}

func TestRegisterSavedSourceServerRegistersOnlyInternalContract(t *testing.T) {
	t.Parallel()

	server := gogrpc.NewServer()
	RegisterSavedSourceServer(server, NewSavedSourceServer(nil, nil))
	serviceInfo := server.GetServiceInfo()
	if _, exists := serviceInfo["content.v1.SavedSourceService"]; !exists {
		t.Fatalf("registered services = %#v", serviceInfo)
	}
}

func authorizedSavedSourceContext() context.Context {
	return metadata.NewIncomingContext(
		context.Background(),
		metadata.Pairs("authorization", "Bearer service-token"),
	)
}

func grpcPublishedAttraction(attractionID uuid.UUID) *model.SavedAttractionSnapshot {
	return &model.SavedAttractionSnapshot{
		ID:            attractionID,
		DefaultLocale: "en",
		CountryCode:   "KZ",
		CityID:        "almaty",
		Rating:        4.5,
		ReviewCount:   10,
		Status:        enum.StatusPublished,
		Translations: map[string]model.PlaceTranslation{
			"en": {
				PlaceID: attractionID,
				Locale:  "en",
				Title:   "Public attraction",
			},
		},
		SourceRevision:     11,
		ProjectionRevision: 12,
		VisibilityRevision: 13,
	}
}

type grpcSavedSourceRepositoryStub struct {
	snapshot *model.SavedAttractionSnapshot
	err      error
	calls    int
}

func (r *grpcSavedSourceRepositoryStub) GetSavedSourceAttraction(
	_ context.Context,
	_ uuid.UUID,
) (*model.SavedAttractionSnapshot, error) {
	r.calls++
	return r.snapshot, r.err
}

type grpcSavedSourceAuthorizerStub struct {
	claims        *serviceauth.Claims
	err           error
	requiredRoles []string
}

func (a *grpcSavedSourceAuthorizerStub) ValidateBearer(
	_ context.Context,
	_ string,
	requiredRoles []string,
) (*serviceauth.Claims, error) {
	a.requiredRoles = append([]string(nil), requiredRoles...)
	return a.claims, a.err
}
