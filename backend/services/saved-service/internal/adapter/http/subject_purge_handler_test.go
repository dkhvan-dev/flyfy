package http

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
)

func TestSubjectPurgeHandlerRequiresVerifiedMTLS(t *testing.T) {
	t.Parallel()

	useCase := &stubSubjectPurgeUseCase{}
	mux := newSubjectPurgeTestMux(t, useCase)
	request := httptest.NewRequest(
		http.MethodPost,
		"/internal/v1/compliance/saved-subject-purges",
		strings.NewReader(validSubjectPurgeBody),
	)
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusForbidden || useCase.startCalls != 0 {
		t.Fatalf("status=%d calls=%d body=%s", recorder.Code, useCase.startCalls, recorder.Body.String())
	}
}

func TestSubjectPurgeHandlerStartsFencedResumablePurgeWithoutEchoingIdentity(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	next := now.Add(time.Minute)
	useCase := &stubSubjectPurgeUseCase{job: savedmaintenance.SubjectPurgeJob{
		OperationID:   uuid.MustParse("77777777-7777-4777-8777-777777777777"),
		Subject:       "auth-subject-sensitive",
		OwnerUserID:   uuid.MustParse("88888888-8888-4888-8888-888888888888"),
		Phase:         savedmaintenance.SubjectPurgePhaseOutbox,
		NextAttemptAt: &next,
		CreatedAt:     now,
		UpdatedAt:     now,
	}}
	mux := newSubjectPurgeTestMux(t, useCase)
	request := verifiedMTLSRequest(
		http.MethodPost,
		"/internal/v1/compliance/saved-subject-purges",
		validSubjectPurgeBody,
	)
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusAccepted || useCase.startCalls != 1 ||
		!useCase.start.WritesFenced || useCase.start.Subject != "auth-subject-sensitive" {
		t.Fatalf("status=%d calls=%d start=%#v body=%s", recorder.Code, useCase.startCalls, useCase.start, recorder.Body.String())
	}
	for _, secret := range []string{"auth-subject-sensitive", "88888888-8888-4888-8888-888888888888"} {
		if strings.Contains(recorder.Body.String(), secret) {
			t.Fatalf("response echoed private identity %q: %s", secret, recorder.Body.String())
		}
	}
}

func TestSubjectPurgeHandlerRejectsMissingFenceAndUnknownFields(t *testing.T) {
	t.Parallel()

	useCase := &stubSubjectPurgeUseCase{err: savedmaintenance.ErrInvalidSubjectPurge}
	mux := newSubjectPurgeTestMux(t, useCase)
	bodies := []string{
		`{"operation_id":"77777777-7777-4777-8777-777777777777","subject":"subject","owner_user_id":"88888888-8888-4888-8888-888888888888","writes_fenced":false}`,
		`{"operation_id":"77777777-7777-4777-8777-777777777777","subject":"subject","owner_user_id":"88888888-8888-4888-8888-888888888888","writes_fenced":true,"force":true}`,
	}
	for _, body := range bodies {
		request := verifiedMTLSRequest(
			http.MethodPost,
			"/internal/v1/compliance/saved-subject-purges",
			body,
		)
		recorder := httptest.NewRecorder()
		mux.ServeHTTP(recorder, request)
		if recorder.Code != http.StatusBadRequest {
			t.Errorf("status=%d body=%s", recorder.Code, recorder.Body.String())
		}
	}
}

func TestSubjectPurgeHandlerReturnsNeutralNotFound(t *testing.T) {
	t.Parallel()

	useCase := &stubSubjectPurgeUseCase{err: savedmaintenance.ErrSubjectPurgeNotFound}
	mux := newSubjectPurgeTestMux(t, useCase)
	request := verifiedMTLSRequest(
		http.MethodGet,
		"/internal/v1/compliance/saved-subject-purges/77777777-7777-4777-8777-777777777777",
		"",
	)
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusNotFound || strings.Contains(recorder.Body.String(), "subject") {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
}

const validSubjectPurgeBody = `{"operation_id":"77777777-7777-4777-8777-777777777777","subject":"auth-subject-sensitive","owner_user_id":"88888888-8888-4888-8888-888888888888","writes_fenced":true}`

func newSubjectPurgeTestMux(t *testing.T, useCase SubjectPurgeUseCase) *http.ServeMux {
	t.Helper()
	handler, err := NewSubjectPurgeHandler(useCase, "spiffe://inflap/test/user-service")
	if err != nil {
		t.Fatal(err)
	}
	mux := http.NewServeMux()
	if err := handler.Register(mux); err != nil {
		t.Fatal(err)
	}
	return mux
}

func verifiedMTLSRequest(method, path, body string) *http.Request {
	request := httptest.NewRequest(method, path, strings.NewReader(body))
	identity, _ := url.Parse("spiffe://inflap/test/user-service")
	certificate := &x509.Certificate{URIs: []*url.URL{identity}}
	request.TLS = &tls.ConnectionState{
		HandshakeComplete: true,
		VerifiedChains:    [][]*x509.Certificate{{certificate}},
	}
	return request
}

type stubSubjectPurgeUseCase struct {
	job        savedmaintenance.SubjectPurgeJob
	err        error
	start      savedmaintenance.SubjectPurgeStart
	startCalls int
}

func (stub *stubSubjectPurgeUseCase) StartSubjectPurge(
	_ context.Context,
	start savedmaintenance.SubjectPurgeStart,
) (savedmaintenance.SubjectPurgeJob, error) {
	stub.startCalls++
	stub.start = start
	return stub.job, stub.err
}

func (stub *stubSubjectPurgeUseCase) SubjectPurge(
	context.Context,
	uuid.UUID,
) (savedmaintenance.SubjectPurgeJob, error) {
	return stub.job, stub.err
}

var _ SubjectPurgeUseCase = (*stubSubjectPurgeUseCase)(nil)
