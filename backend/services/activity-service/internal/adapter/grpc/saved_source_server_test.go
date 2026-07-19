package grpc

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/activity-service/internal/app"
	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

type savedSourceGRPCRepositoryStub struct {
	activity *model.Activity
	media    []*model.ActivityMedia
	err      error
}

func (s *savedSourceGRPCRepositoryStub) GetSavedSourceActivity(
	_ context.Context,
	activityID uuid.UUID,
) (*model.Activity, []*model.ActivityMedia, error) {
	if s.err != nil {
		return nil, nil, s.err
	}
	if s.activity == nil || s.activity.ID != activityID {
		return nil, nil, nil
	}
	return s.activity, s.media, nil
}

type savedSourceAuthorizerStub struct {
	requiredRoles []string
}

func (s *savedSourceAuthorizerStub) ValidateBearer(
	_ context.Context,
	authHeader string,
	requiredRoles []string,
) (*serviceauth.Claims, error) {
	s.requiredRoles = append([]string(nil), requiredRoles...)
	switch authHeader {
	case "Bearer valid-saved-service-token":
		return &serviceauth.Claims{
			Subject: "saved-service",
			Type:    "service",
			Roles:   []string{savedSourceResolveRole},
		}, nil
	case "Bearer wrong-role-token":
		return nil, serviceauth.ErrForbiddenService
	case "Bearer auth-outage":
		return nil, errors.New("jwks offline")
	default:
		return nil, serviceauth.ErrInvalidServiceJWT
	}
}

func TestResolveSaveEligibilityReturnsExactPublicActivityProjection(t *testing.T) {
	t.Parallel()

	validatedAt := time.Date(2026, time.July, 16, 5, 45, 0, 0, time.UTC)
	item := savedSourceGRPCTestActivity()
	lineageID := uuid.New()
	item.SourceActivityID = &lineageID
	item.Translations["en"] = model.ActivityLocalizedCopy{
		Title:       "City walk",
		Description: "A public walk",
	}
	repo := &savedSourceGRPCRepositoryStub{
		activity: item,
		media:    []*model.ActivityMedia{{ActivityID: item.ID, FileID: uuid.New(), IsCover: true}},
	}
	authorizer := &savedSourceAuthorizerStub{}
	server := NewServer(nil, nil, nil, nil, WithSavedSource(
		app.NewSavedSourceUseCase(repo, app.WithSavedSourceClock(func() time.Time {
			return validatedAt
		})),
		authorizer,
	))
	req := savedSourceRequest(item.ID.String())

	response, err := server.ResolveSaveEligibility(savedSourceAuthenticatedContext(), req)
	if err != nil {
		t.Fatalf("ResolveSaveEligibility() error = %v", err)
	}
	if response.GetTarget().GetEntityType() != req.GetTarget().GetEntityType() ||
		response.GetTarget().GetEntityId() != req.GetTarget().GetEntityId() {
		t.Fatalf("response target = %+v, want exact request target %+v", response.GetTarget(), req.GetTarget())
	}
	if response.GetTarget().GetEntityId() == lineageID.String() {
		t.Fatal("response used source_activity_id as an alias")
	}
	if response.GetEligibility() != contentv1.SaveEligibility_SAVE_ELIGIBILITY_ELIGIBLE ||
		response.GetVisibility() != contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC {
		t.Fatalf("eligibility/visibility = %s/%s", response.GetEligibility(), response.GetVisibility())
	}
	revisions := response.GetRevisions()
	if revisions.GetSourceRevision() != item.SavedSourceRevision ||
		revisions.GetProjectionRevision() != item.SavedProjectionRevision ||
		revisions.GetVisibilityRevision() != item.SavedVisibilityRevision {
		t.Fatalf(
			"revisions = %+v, want %d/%d/%d",
			revisions,
			item.SavedSourceRevision,
			item.SavedProjectionRevision,
			item.SavedVisibilityRevision,
		)
	}
	if response.GetValidatedAt() == nil || !response.GetValidatedAt().AsTime().Equal(validatedAt) {
		t.Fatalf("validatedAt = %v, want %v", response.GetValidatedAt(), validatedAt)
	}
	projection := response.GetPublicProjection()
	if projection == nil || projection.GetSourceDefaultLocale() != contentv1.SavedLocale_SAVED_LOCALE_RU {
		t.Fatalf("public projection = %+v", projection)
	}
	if projection.GetRu() == nil || projection.GetEn() == nil || projection.GetKk() != nil {
		t.Fatalf("localized projections ru/en/kk = %v/%v/%v", projection.GetRu(), projection.GetEn(), projection.GetKk())
	}
	if projection.GetCanonicalDetailRoute() != "/activities/"+item.ID.String() {
		t.Fatalf("detail route = %q", projection.GetCanonicalDetailRoute())
	}
	if projection.GetMedia() == nil || projection.GetMedia().GetReferenceRevision() != item.SavedProjectionRevision {
		t.Fatalf("media = %+v", projection.GetMedia())
	}
	if len(authorizer.requiredRoles) != 1 || authorizer.requiredRoles[0] != savedSourceResolveRole {
		t.Fatalf("required roles = %#v, want %q", authorizer.requiredRoles, savedSourceResolveRole)
	}
}

func TestResolveSaveEligibilityRejectsNonCanonicalTargetIdentity(t *testing.T) {
	t.Parallel()

	item := savedSourceGRPCTestActivity()
	server := savedSourceGRPCTestServer(&savedSourceGRPCRepositoryStub{activity: item})
	tests := []struct {
		name string
		req  *contentv1.ResolveSaveEligibilityRequest
		code codes.Code
	}{
		{name: "nil request", req: nil, code: codes.InvalidArgument},
		{name: "missing target", req: &contentv1.ResolveSaveEligibilityRequest{}, code: codes.InvalidArgument},
		{
			name: "wrong type",
			req: &contentv1.ResolveSaveEligibilityRequest{Target: &contentv1.SavedTarget{
				EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION,
				EntityId:   item.ID.String(),
			}},
			code: codes.InvalidArgument,
		},
		{
			name: "uppercase uuid",
			req: &contentv1.ResolveSaveEligibilityRequest{Target: &contentv1.SavedTarget{
				EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY,
				EntityId:   strings.ToUpper(item.ID.String()),
			}},
			code: codes.InvalidArgument,
		},
		{
			name: "uuid with whitespace",
			req: &contentv1.ResolveSaveEligibilityRequest{Target: &contentv1.SavedTarget{
				EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY,
				EntityId:   " " + item.ID.String(),
			}},
			code: codes.InvalidArgument,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := server.ResolveSaveEligibility(savedSourceAuthenticatedContext(), test.req)
			if status.Code(err) != test.code {
				t.Fatalf("status code = %s, want %s (error %v)", status.Code(err), test.code, err)
			}
		})
	}
}

func TestResolveSaveEligibilityDoesNotTreatSourceActivityIDAsAlias(t *testing.T) {
	t.Parallel()

	item := savedSourceGRPCTestActivity()
	lineageID := uuid.New()
	item.SourceActivityID = &lineageID
	server := savedSourceGRPCTestServer(&savedSourceGRPCRepositoryStub{activity: item})

	_, err := server.ResolveSaveEligibility(
		savedSourceAuthenticatedContext(),
		savedSourceRequest(lineageID.String()),
	)
	if status.Code(err) != codes.NotFound {
		t.Fatalf("status code = %s, want NotFound (error %v)", status.Code(err), err)
	}
}

func TestResolveSaveEligibilityReturnsPayloadFreeDenials(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		visibility enum.ActivityVisibility
		want       contentv1.SavedTargetVisibility
	}{
		{name: "private", visibility: enum.ActivityVisibilityPrivate, want: contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PRIVATE},
		{name: "unlisted", visibility: enum.ActivityVisibilityUnlisted, want: contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_RESTRICTED},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			item := savedSourceGRPCTestActivity()
			item.Visibility = test.visibility
			server := savedSourceGRPCTestServer(&savedSourceGRPCRepositoryStub{
				activity: item,
				media:    []*model.ActivityMedia{{ActivityID: item.ID, FileID: uuid.New()}},
			})
			response, err := server.ResolveSaveEligibility(
				savedSourceAuthenticatedContext(),
				savedSourceRequest(item.ID.String()),
			)
			if err != nil {
				t.Fatalf("ResolveSaveEligibility() error = %v", err)
			}
			if response.GetEligibility() != contentv1.SaveEligibility_SAVE_ELIGIBILITY_INELIGIBLE ||
				response.GetVisibility() != test.want ||
				response.GetPublicProjection() != nil {
				t.Fatalf("denial response = %+v", response)
			}
		})
	}
}

func TestResolveSaveEligibilityMapsMissingAndOutage(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	tests := []struct {
		name string
		repo *savedSourceGRPCRepositoryStub
		want codes.Code
	}{
		{name: "missing", repo: &savedSourceGRPCRepositoryStub{}, want: codes.NotFound},
		{name: "source outage", repo: &savedSourceGRPCRepositoryStub{err: errors.New("database offline")}, want: codes.Unavailable},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			server := savedSourceGRPCTestServer(test.repo)
			_, err := server.ResolveSaveEligibility(
				savedSourceAuthenticatedContext(),
				savedSourceRequest(activityID.String()),
			)
			if status.Code(err) != test.want {
				t.Fatalf("status code = %s, want %s (error %v)", status.Code(err), test.want, err)
			}
		})
	}
}

func TestResolveSaveEligibilityRequiresSavedServiceRole(t *testing.T) {
	t.Parallel()

	item := savedSourceGRPCTestActivity()
	authorizer := &savedSourceAuthorizerStub{}
	server := NewServer(nil, nil, nil, nil, WithSavedSource(
		app.NewSavedSourceUseCase(&savedSourceGRPCRepositoryStub{activity: item}),
		authorizer,
	))
	tests := []struct {
		name string
		ctx  context.Context
		want codes.Code
	}{
		{name: "missing bearer", ctx: context.Background(), want: codes.Unauthenticated},
		{name: "legacy static token is not accepted", ctx: metadata.NewIncomingContext(context.Background(), metadata.Pairs("x-internal-service-token", "legacy")), want: codes.Unauthenticated},
		{name: "wrong role", ctx: metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer wrong-role-token")), want: codes.PermissionDenied},
		{name: "auth dependency outage", ctx: metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer auth-outage")), want: codes.Unavailable},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := server.ResolveSaveEligibility(test.ctx, savedSourceRequest(item.ID.String()))
			if status.Code(err) != test.want {
				t.Fatalf("status code = %s, want %s (error %v)", status.Code(err), test.want, err)
			}
		})
	}
}

func savedSourceGRPCTestServer(repo app.SavedSourceRepository) *Server {
	return NewServer(nil, nil, nil, nil, WithSavedSource(
		app.NewSavedSourceUseCase(repo),
		&savedSourceAuthorizerStub{},
	))
}

func savedSourceAuthenticatedContext() context.Context {
	return metadata.NewIncomingContext(
		context.Background(),
		metadata.Pairs("authorization", "Bearer valid-saved-service-token"),
	)
}

func savedSourceRequest(activityID string) *contentv1.ResolveSaveEligibilityRequest {
	return &contentv1.ResolveSaveEligibilityRequest{
		Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY,
			EntityId:   activityID,
		},
	}
}

func savedSourceGRPCTestActivity() *model.Activity {
	now := time.Date(2026, time.July, 16, 4, 0, 0, 0, time.UTC)
	publishedAt := now.Add(-time.Hour)
	city := "Almaty"
	return &model.Activity{
		ID:                      uuid.New(),
		HostUserID:              uuid.New(),
		Title:                   "Городская прогулка",
		Description:             "Открытая прогулка по городу",
		Translations:            model.ActivityTranslations{"ru": {Title: "Городская прогулка", Description: "Открытая прогулка по городу"}},
		SourceLanguage:          "ru",
		Status:                  enum.ActivityStatusEnrollmentOpen,
		Visibility:              enum.ActivityVisibilityPublic,
		ModerationStatus:        enum.ActivityModerationStatusApproved,
		PublishedAt:             &publishedAt,
		CityName:                &city,
		Revision:                41,
		SavedSourceRevision:     410,
		SavedProjectionRevision: 411,
		SavedVisibilityRevision: 412,
		StartAt:                 now.Add(24 * time.Hour),
		EndAt:                   now.Add(26 * time.Hour),
	}
}
