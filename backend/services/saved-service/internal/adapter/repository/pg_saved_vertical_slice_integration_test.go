package repository

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	httpadapter "kz/inflap/backend/services/saved-service/internal/adapter/http"
	"kz/inflap/backend/services/saved-service/internal/app/operation"
	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSavedVerticalSliceSaveReplayStatusAndGlobalUnsave(t *testing.T) {
	pool, operationStore, repository := openSavedItemKernelIntegration(t)
	truncateSavedItemKernel(t, pool)

	keyRing, err := operation.NewHMACKeyRing(operation.HMACKeyConfig{
		Version: 1,
		Secret:  bytes.Repeat([]byte{0x5a}, 32),
	})
	if err != nil {
		t.Fatalf("NewHMACKeyRing() error = %v", err)
	}
	now := time.Now().UTC().Truncate(time.Microsecond)
	clock := verticalSliceClock{now: now}
	operationService, err := operation.NewService(operationStore, keyRing, clock)
	if err != nil {
		t.Fatalf("operation.NewService() error = %v", err)
	}
	targetID := uuid.New()
	target, err := domain.NewSavedTarget(domain.EntityTypeAttraction, targetID.String())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	resolver := &verticalSliceResolver{resolution: appsource.Resolution{
		Target:      target,
		Eligible:    true,
		Visibility:  domain.VisibilityPublic,
		Revisions:   appsource.Revisions{Source: 1, Projection: 1, Visibility: 1},
		ValidatedAt: now,
		PublicProjection: &appsource.PublicCardProjection{
			SourceDefaultLocale: appsource.LocaleRU,
			Localized: map[appsource.Locale]appsource.LocalizedCardProjection{
				appsource.LocaleEN: {Title: "Museum"},
				appsource.LocaleRU: {Title: "Музей"},
				appsource.LocaleKK: {Title: "Мұражай"},
			},
			CanonicalDetailRoute: "/places/" + targetID.String(),
		},
	}}
	policy := &verticalSlicePolicy{revision: 4}
	service, err := saveditem.NewService(saveditem.ServiceConfig{
		OperationBeginner: operationService,
		Repository:        repository,
		SourceResolver:    resolver,
		SessionValidator:  verticalSliceSessionValidator{},
		PolicyGate:        policy,
		Clock:             clock,
		MaxActiveSaves:    10_000,
	})
	if err != nil {
		t.Fatalf("saveditem.NewService() error = %v", err)
	}
	mutationHandler, err := httpadapter.NewSavedItemMutationHandler(service, clock)
	if err != nil {
		t.Fatalf("NewSavedItemMutationHandler() error = %v", err)
	}
	operationHandler, err := httpadapter.NewOperationHandler(repository, clock)
	if err != nil {
		t.Fatalf("NewOperationHandler() error = %v", err)
	}
	personalRouter, err := httpadapter.NewPersonalRouter(
		verticalSliceGatewayAuthorizer{},
		policy,
		mutationHandler,
		operationHandler,
	)
	if err != nil {
		t.Fatalf("NewPersonalRouter() error = %v", err)
	}

	subject := uuid.New()
	owner := uuid.New()
	session := uuid.New()
	saveOperationID := uuid.New()
	saveKey := base64.RawURLEncoding.EncodeToString(bytes.Repeat([]byte{0x11}, 16))
	saveRequest := verticalSliceMutationRequest(
		http.MethodPut,
		target,
		subject,
		owner,
		session,
		saveOperationID,
		saveKey,
	)
	firstSave := httptest.NewRecorder()
	personalRouter.ServeHTTP(firstSave, saveRequest)
	assertVerticalOperationResponse(t, firstSave, http.StatusOK, domain.OperationOutcomeApplied)
	if resolver.calls.Load() != 1 {
		t.Fatalf("source calls after first save = %d", resolver.calls.Load())
	}
	assertVerticalRelationshipState(t, pool, owner, target, domain.RelationshipStateActive)

	replayedSave := httptest.NewRecorder()
	personalRouter.ServeHTTP(replayedSave, verticalSliceMutationRequest(
		http.MethodPut,
		target,
		subject,
		owner,
		session,
		saveOperationID,
		saveKey,
	))
	assertVerticalOperationResponse(t, replayedSave, http.StatusOK, domain.OperationOutcomeApplied)
	if resolver.calls.Load() != 1 {
		t.Fatalf("same-key replay repeated source RPC: calls=%d", resolver.calls.Load())
	}

	statusRequest := verticalSliceTrustedRequest(
		http.MethodGet,
		"/v1/users/me/saved-operations/"+saveOperationID.String(),
		subject,
		owner,
		session,
	)
	statusResponse := httptest.NewRecorder()
	personalRouter.ServeHTTP(statusResponse, statusRequest)
	assertVerticalOperationResponse(t, statusResponse, http.StatusOK, domain.OperationOutcomeApplied)

	unsaveResponse := httptest.NewRecorder()
	personalRouter.ServeHTTP(unsaveResponse, verticalSliceMutationRequest(
		http.MethodDelete,
		target,
		subject,
		owner,
		session,
		uuid.New(),
		base64.RawURLEncoding.EncodeToString(bytes.Repeat([]byte{0x22}, 16)),
	))
	assertVerticalOperationResponse(t, unsaveResponse, http.StatusOK, domain.OperationOutcomeApplied)
	if resolver.calls.Load() != 1 {
		t.Fatalf("global unsave called source: calls=%d", resolver.calls.Load())
	}
	assertVerticalRelationshipState(t, pool, owner, target, domain.RelationshipStateRemoved)
}

func verticalSliceMutationRequest(
	method string,
	target domain.SavedTarget,
	subject uuid.UUID,
	owner uuid.UUID,
	session uuid.UUID,
	operationID uuid.UUID,
	idempotencyKey string,
) *http.Request {
	request := verticalSliceTrustedRequest(
		method,
		"/v1/users/me/saved-items/"+string(target.EntityType())+"/"+target.EntityID(),
		subject,
		owner,
		session,
	)
	request.Header.Set(httpadapter.HeaderOperationID, operationID.String())
	request.Header.Set(httpadapter.HeaderIdempotencyKey, idempotencyKey)
	request.Header.Set(httpadapter.HeaderSourceSurface, string(domain.SourceSurfaceDetail))
	return request
}

func verticalSliceTrustedRequest(
	method string,
	path string,
	subject uuid.UUID,
	owner uuid.UUID,
	session uuid.UUID,
) *http.Request {
	request := httptest.NewRequest(method, path, nil)
	request.Header.Set("Authorization", "Bearer gateway-service-jwt")
	request.Header.Set(httpadapter.HeaderAuthSubject, subject.String())
	request.Header.Set(httpadapter.HeaderUserID, owner.String())
	request.Header.Set(httpadapter.HeaderSessionGeneration, session.String())
	request.Header.Set(httpadapter.HeaderRequestID, uuid.NewString())
	request.Header.Set("Accept-Language", "ru")
	return request
}

func assertVerticalOperationResponse(
	t *testing.T,
	recorder *httptest.ResponseRecorder,
	status int,
	outcome domain.OperationOutcome,
) {
	t.Helper()
	if recorder.Code != status {
		t.Fatalf("status = %d, want %d; body=%s", recorder.Code, status, recorder.Body.String())
	}
	var response struct {
		Outcome domain.OperationOutcome `json:"operation_outcome"`
	}
	if err := json.NewDecoder(recorder.Body).Decode(&response); err != nil {
		t.Fatalf("decode operation response: %v", err)
	}
	if response.Outcome != outcome {
		t.Fatalf("operation outcome = %s, want %s", response.Outcome, outcome)
	}
}

func assertVerticalRelationshipState(
	t *testing.T,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	target domain.SavedTarget,
	want domain.RelationshipState,
) {
	t.Helper()
	var state string
	err := pool.QueryRow(
		context.Background(),
		`SELECT relationship_state
           FROM saved_items
          WHERE owner_user_id = $1 AND entity_type = $2 AND entity_id = $3`,
		owner.String(),
		string(target.EntityType()),
		target.EntityID(),
	).Scan(&state)
	if err != nil {
		t.Fatalf("read relationship state: %v", err)
	}
	if state != string(want) {
		t.Fatalf("relationship state = %s, want %s", state, want)
	}
}

type verticalSliceClock struct{ now time.Time }

func (clock verticalSliceClock) Now() time.Time { return clock.now }

type verticalSliceResolver struct {
	resolution appsource.Resolution
	calls      atomic.Int32
}

func (resolver *verticalSliceResolver) Resolve(context.Context, domain.SavedTarget) (appsource.Resolution, error) {
	resolver.calls.Add(1)
	return resolver.resolution, nil
}

type verticalSliceSessionValidator struct{}

func (verticalSliceSessionValidator) Validate(context.Context, string, string) (bool, error) {
	return true, nil
}

type verticalSlicePolicy struct{ revision uint64 }

func (policy *verticalSlicePolicy) Guard(context.Context) (saveditem.PolicyGrant, error) {
	return saveditem.PolicyGrant{Revision: policy.revision}, nil
}

func (*verticalSlicePolicy) ValidateCommit(context.Context, uint64) error { return nil }

type verticalSliceGatewayAuthorizer struct{}

func (verticalSliceGatewayAuthorizer) AuthorizeGateway(context.Context, string) error { return nil }
