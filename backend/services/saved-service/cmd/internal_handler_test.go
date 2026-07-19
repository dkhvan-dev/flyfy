package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
	"kz/inflap/backend/services/saved-service/internal/config"
)

func TestInternalApplicationHandlerKeepsComplianceRouteOffPublicHandler(t *testing.T) {
	t.Parallel()

	publicCalls := 0
	public := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		publicCalls++
		w.WriteHeader(http.StatusNotFound)
	})
	useCase := &mainSubjectPurgeStub{job: validMainSubjectPurgeJob()}
	cfg := &config.Config{Compliance: config.ComplianceConfig{
		AllowedCallerSPIFFEID: "spiffe://inflap/test/user-service",
	}}
	internal, err := newInternalApplicationHandler(cfg, public, useCase)
	if err != nil {
		t.Fatal(err)
	}

	publicRequest := httptest.NewRequest(
		http.MethodPost,
		"/internal/v1/compliance/saved-subject-purges",
		strings.NewReader(mainSubjectPurgeBody),
	)
	publicRecorder := httptest.NewRecorder()
	public.ServeHTTP(publicRecorder, publicRequest)
	if publicRecorder.Code != http.StatusNotFound || useCase.calls != 0 {
		t.Fatalf("public status=%d purge_calls=%d", publicRecorder.Code, useCase.calls)
	}

	internalRequest := verifiedMainInternalRequest(mainSubjectPurgeBody)
	internalRecorder := httptest.NewRecorder()
	internal.ServeHTTP(internalRecorder, internalRequest)
	if internalRecorder.Code != http.StatusAccepted || useCase.calls != 1 || publicCalls != 1 {
		t.Fatalf(
			"internal status=%d purge_calls=%d public_calls=%d body=%s",
			internalRecorder.Code,
			useCase.calls,
			publicCalls,
			internalRecorder.Body.String(),
		)
	}
}

const mainSubjectPurgeBody = `{"operation_id":"77777777-7777-4777-8777-777777777777","subject":"subject","owner_user_id":"88888888-8888-4888-8888-888888888888","writes_fenced":true}`

func verifiedMainInternalRequest(body string) *http.Request {
	request := httptest.NewRequest(
		http.MethodPost,
		"/internal/v1/compliance/saved-subject-purges",
		strings.NewReader(body),
	)
	identity, _ := url.Parse("spiffe://inflap/test/user-service")
	request.TLS = &tls.ConnectionState{
		HandshakeComplete: true,
		VerifiedChains: [][]*x509.Certificate{{{
			URIs: []*url.URL{identity},
		}}},
	}
	return request
}

func validMainSubjectPurgeJob() savedmaintenance.SubjectPurgeJob {
	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	next := now.Add(time.Minute)
	return savedmaintenance.SubjectPurgeJob{
		OperationID:   uuid.MustParse("77777777-7777-4777-8777-777777777777"),
		Subject:       "subject",
		OwnerUserID:   uuid.MustParse("88888888-8888-4888-8888-888888888888"),
		Phase:         savedmaintenance.SubjectPurgePhaseOutbox,
		NextAttemptAt: &next,
		CreatedAt:     now,
		UpdatedAt:     now,
	}
}

type mainSubjectPurgeStub struct {
	job   savedmaintenance.SubjectPurgeJob
	calls int
}

func (stub *mainSubjectPurgeStub) StartSubjectPurge(
	context.Context,
	savedmaintenance.SubjectPurgeStart,
) (savedmaintenance.SubjectPurgeJob, error) {
	stub.calls++
	return stub.job, nil
}

func (stub *mainSubjectPurgeStub) SubjectPurge(
	context.Context,
	uuid.UUID,
) (savedmaintenance.SubjectPurgeJob, error) {
	return stub.job, nil
}
