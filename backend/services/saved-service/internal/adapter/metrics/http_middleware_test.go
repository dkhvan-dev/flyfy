package metrics

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHTTPMiddlewareUsesMatchedAllowlistedPatternOnly(t *testing.T) {
	registry := New()
	personalMux := http.NewServeMux()
	personalMux.HandleFunc(
		"DELETE /v1/users/me/saved-items/{entityType}/{entityKey}",
		func(writer http.ResponseWriter, _ *http.Request) {
			writer.WriteHeader(http.StatusUnprocessableEntity)
			_, _ = writer.Write([]byte("rejected"))
		},
	)
	mux := http.NewServeMux()
	mux.Handle("/v1/users/me/", personalMux)
	handler := registry.Wrap(mux)

	entityID := "99999999-9999-4999-8999-999999999999"
	rawQuery := "private-search-user-123"
	request := httptest.NewRequest(
		http.MethodDelete,
		"/v1/users/me/saved-items/ACTIVITY/"+entityID+"?query="+rawQuery,
		nil,
	)
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status = %d, want 422", recorder.Code)
	}

	unknownID := "owner-777-private-resource"
	unknownRecorder := httptest.NewRecorder()
	handler.ServeHTTP(
		unknownRecorder,
		httptest.NewRequest(http.MethodGet, "/not-allowlisted/"+unknownID+"?q="+rawQuery, nil),
	)
	if unknownRecorder.Code != http.StatusNotFound {
		t.Fatalf("unknown status = %d, want 404", unknownRecorder.Code)
	}

	body := scrape(t, registry)
	assertContains(t, body,
		`saved_http_requests_total{route="/v1/users/me/saved-items/{entityType}/{entityKey}",method="DELETE",status_class="4xx"} 1`,
		`saved_http_errors_total{route="/v1/users/me/saved-items/{entityType}/{entityKey}",method="DELETE",status_class="4xx"} 1`,
		`saved_http_requests_total{route="UNKNOWN",method="GET",status_class="4xx"} 1`,
		`# TYPE saved_http_request_duration_seconds histogram`,
	)
	assertNotContains(t, body, entityID, rawQuery, unknownID, "ACTIVITY/99999999")
}

func TestHTTPMiddlewareNormalizesMethodAndRecordsPanicsAsErrors(t *testing.T) {
	registry := New()
	methodHandler := registry.Wrap(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		request.Pattern = "GET /health"
		writer.WriteHeader(http.StatusNoContent)
	}))
	methodRecorder := httptest.NewRecorder()
	methodHandler.ServeHTTP(methodRecorder, httptest.NewRequest("PRIVATE-METHOD-123", "/health", nil))

	mux := http.NewServeMux()
	mux.HandleFunc("GET /ready", func(http.ResponseWriter, *http.Request) {
		panic("private panic payload owner-123")
	})
	panicHandler := registry.Wrap(mux)
	func() {
		defer func() {
			if recover() == nil {
				t.Fatal("handler panic was not propagated")
			}
		}()
		panicHandler.ServeHTTP(
			httptest.NewRecorder(),
			httptest.NewRequest(http.MethodGet, "/ready", nil),
		)
	}()

	body := scrape(t, registry)
	assertContains(t, body,
		`saved_http_requests_total{route="/health",method="UNKNOWN",status_class="2xx"} 1`,
		`saved_http_requests_total{route="/ready",method="GET",status_class="5xx"} 1`,
		`saved_http_errors_total{route="/ready",method="GET",status_class="5xx"} 1`,
	)
	assertNotContains(t, body, "PRIVATE-METHOD-123", "private panic payload", "owner-123")
}

func TestHTTPMiddlewarePreservesStreamingAndFirstStatus(t *testing.T) {
	registry := New()
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusAccepted)
		writer.WriteHeader(http.StatusInternalServerError)
		_, _ = io.Copy(writer, strings.NewReader("ok"))
		writer.(http.Flusher).Flush()
	})
	recorder := httptest.NewRecorder()
	registry.Wrap(mux).ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/health", nil))
	if recorder.Code != http.StatusAccepted || recorder.Body.String() != "ok" || !recorder.Flushed {
		t.Fatalf("status=%d body=%q flushed=%v", recorder.Code, recorder.Body.String(), recorder.Flushed)
	}

	body := scrape(t, registry)
	assertContains(t, body,
		`saved_http_requests_total{route="/health",method="GET",status_class="2xx"} 1`,
	)
}

func TestHTTPMiddlewareHandlesNilDependencyAndRequestWithoutPanic(t *testing.T) {
	registry := New()
	nilDependencyRecorder := httptest.NewRecorder()
	registry.Wrap(nil).ServeHTTP(
		nilDependencyRecorder,
		httptest.NewRequest(http.MethodGet, "/private-owner-123", nil),
	)
	if nilDependencyRecorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("nil dependency status = %d, want 503", nilDependencyRecorder.Code)
	}

	nilRequestRecorder := httptest.NewRecorder()
	registry.Wrap(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("nil request reached wrapped handler")
	})).ServeHTTP(nilRequestRecorder, nil)
	if nilRequestRecorder.Code != http.StatusBadRequest {
		t.Fatalf("nil request status = %d, want 400", nilRequestRecorder.Code)
	}

	body := scrape(t, registry)
	assertContains(t, body,
		`saved_http_requests_total{route="UNKNOWN",method="GET",status_class="5xx"} 1`,
		`saved_http_requests_total{route="UNKNOWN",method="UNKNOWN",status_class="4xx"} 1`,
	)
	assertNotContains(t, body, "private-owner-123")
}

func TestHTTPObserverReceivesOnlyNormalizedIdentifiersAndRoute(t *testing.T) {
	registry := New()
	var observations []HTTPObservation
	mux := http.NewServeMux()
	mux.HandleFunc(
		"PUT /v1/users/me/saved-items/{entityType}/{entityKey}",
		func(writer http.ResponseWriter, request *http.Request) {
			writer.Header().Set(headerRequestID, request.Header.Get(headerRequestID))
			writer.WriteHeader(http.StatusAccepted)
		},
	)
	handler := registry.WrapObserved(mux, HTTPObserverFunc(func(observation HTTPObservation) {
		observations = append(observations, observation)
	}))

	requestID := "11111111-1111-4111-8111-111111111111"
	operationID := "22222222-2222-4222-8222-222222222222"
	request := httptest.NewRequest(
		http.MethodPut,
		"/v1/users/me/saved-items/ACTIVITY/private-target?q=private-query",
		nil,
	)
	request.Header.Set(headerRequestID, requestID)
	request.Header.Set(headerOperationID, operationID)
	handler.ServeHTTP(httptest.NewRecorder(), request)

	if len(observations) != 1 {
		t.Fatalf("observations = %d, want 1", len(observations))
	}
	got := observations[0]
	if got.Route != "/v1/users/me/saved-items/{entityType}/{entityKey}" ||
		got.Method != http.MethodPut || got.Status != http.StatusAccepted ||
		got.StatusClass != "2xx" || got.RequestID != requestID ||
		got.OperationID != operationID || got.Duration < 0 {
		t.Fatalf("observation = %#v", got)
	}

	request = httptest.NewRequest(http.MethodGet, "/private-owner-id?q=raw-query", nil)
	request.Header.Set(headerRequestID, "private-owner-id")
	request.Header.Set(headerOperationID, "private-operation-id")
	handler.ServeHTTP(httptest.NewRecorder(), request)
	got = observations[1]
	if got.Route != unknownLabel || got.RequestID != "" || got.OperationID != "" {
		t.Fatalf("untrusted observation = %#v", got)
	}
}

func TestHTTPObserverPanicDoesNotOwnRequestLiveness(t *testing.T) {
	registry := New()
	handler := registry.WrapObserved(
		http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			request.Pattern = "GET /health"
			writer.WriteHeader(http.StatusNoContent)
		}),
		HTTPObserverFunc(func(HTTPObservation) { panic("observer failure") }),
	)
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/health", nil))
	if recorder.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want 204", recorder.Code)
	}
}
