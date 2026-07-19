package metrics

import (
	"bufio"
	"io"
	"net"
	"net/http"
	"time"

	"github.com/google/uuid"
)

const (
	headerRequestID   = "X-Request-Id"
	headerOperationID = "Operation-Id"
)

type HTTPObservation struct {
	Route       string
	Method      string
	Status      int
	StatusClass string
	Duration    time.Duration
	RequestID   string
	OperationID string
}

type HTTPObserver interface {
	ObserveSavedHTTP(HTTPObservation)
}

type HTTPObserverFunc func(HTTPObservation)

func (function HTTPObserverFunc) ObserveSavedHTTP(observation HTTPObservation) {
	if function != nil {
		function(observation)
	}
}

var allowedHTTPPatterns = map[string]string{
	"GET /health":  "/health",
	"GET /ready":   "/ready",
	"GET /metrics": "/metrics",

	"GET /v1/users/me/saved-items":                                      "/v1/users/me/saved-items",
	"POST /v1/users/me/saved-items/query":                               "/v1/users/me/saved-items/query",
	"POST /v1/users/me/saved-items/status:batch":                        "/v1/users/me/saved-items/status:batch",
	"GET /v1/users/me/saved-items/capabilities":                         "/v1/users/me/saved-items/capabilities",
	"PUT /v1/users/me/saved-items/{entityType}/{entityKey}":             "/v1/users/me/saved-items/{entityType}/{entityKey}",
	"DELETE /v1/users/me/saved-items/{entityType}/{entityKey}":          "/v1/users/me/saved-items/{entityType}/{entityKey}",
	"GET /v1/users/me/saved-items/{entityType}/{entityKey}/collections": "/v1/users/me/saved-items/{entityType}/{entityKey}/collections",
	"PUT /v1/users/me/saved-items/{entityType}/{entityKey}/collections": "/v1/users/me/saved-items/{entityType}/{entityKey}/collections",
	"GET /v1/users/me/saved-operations/{operationId}":                   "/v1/users/me/saved-operations/{operationId}",

	"GET /v1/users/me/saved-collections":                   "/v1/users/me/saved-collections",
	"POST /v1/users/me/saved-collections":                  "/v1/users/me/saved-collections",
	"GET /v1/users/me/saved-collections/{collectionId}":    "/v1/users/me/saved-collections/{collectionId}",
	"PATCH /v1/users/me/saved-collections/{collectionId}":  "/v1/users/me/saved-collections/{collectionId}",
	"DELETE /v1/users/me/saved-collections/{collectionId}": "/v1/users/me/saved-collections/{collectionId}",

	"POST /internal/v1/compliance/saved-subject-purges":              "/internal/v1/compliance/saved-subject-purges",
	"GET /internal/v1/compliance/saved-subject-purges/{operationId}": "/internal/v1/compliance/saved-subject-purges/{operationId}",
}

// Wrap records bounded HTTP telemetry after the wrapped handler returns. Route
// labels can only come from the fixed request.Pattern allowlist above.
func (metrics *Metrics) Wrap(next http.Handler) http.Handler {
	return metrics.WrapObserved(next, nil)
}

// WrapObserved records metrics and emits the same normalized, privacy-safe
// request dimensions to an optional structured access-log observer.
func (metrics *Metrics) WrapObserved(next http.Handler, observer HTTPObserver) http.Handler {
	if next == nil {
		next = http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			http.Error(writer, "service unavailable", http.StatusServiceUnavailable)
		})
	}
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		startedAt := time.Now()
		recorder := &statusResponseWriter{ResponseWriter: writer, status: http.StatusOK}
		if request == nil {
			http.Error(recorder, "bad request", http.StatusBadRequest)
			duration := time.Since(startedAt)
			metrics.observeHTTP("", "", recorder.status, duration)
			observeHTTP(observer, HTTPObservation{
				Route:       unknownLabel,
				Method:      unknownLabel,
				Status:      recorder.status,
				StatusClass: normalizeStatusClass(recorder.status),
				Duration:    duration,
			})
			return
		}

		defer func() {
			panicValue := recover()
			status := recorder.status
			if panicValue != nil {
				status = http.StatusInternalServerError
			}
			duration := time.Since(startedAt)
			route := normalizeRoute(request.Pattern)
			method := normalizeMethod(request.Method)
			metrics.observeHTTP(request.Pattern, request.Method, status, duration)
			observeHTTP(observer, HTTPObservation{
				Route:       route,
				Method:      method,
				Status:      normalizeHTTPStatus(status),
				StatusClass: normalizeStatusClass(status),
				Duration:    duration,
				RequestID:   canonicalUUIDHeader(recorder.Header(), request.Header, headerRequestID),
				OperationID: canonicalUUIDHeader(nil, request.Header, headerOperationID),
			})
			if panicValue != nil {
				panic(panicValue)
			}
		}()
		next.ServeHTTP(recorder, request)
	})
}

func observeHTTP(observer HTTPObserver, observation HTTPObservation) {
	if observer == nil {
		return
	}
	defer func() { _ = recover() }()
	observer.ObserveSavedHTTP(observation)
}

func canonicalUUIDHeader(response, request http.Header, name string) string {
	value := ""
	if response != nil {
		value = response.Get(name)
	}
	if value == "" && request != nil {
		value = request.Get(name)
	}
	parsed, err := uuid.Parse(value)
	if err != nil || parsed == uuid.Nil || parsed.String() != value {
		return ""
	}
	return value
}

func normalizeHTTPStatus(status int) int {
	if status < 100 || status > 599 {
		return 0
	}
	return status
}

func (metrics *Metrics) observeHTTP(pattern, method string, status int, duration time.Duration) {
	if metrics == nil {
		return
	}
	key := httpKey{
		Route:       normalizeRoute(pattern),
		Method:      normalizeMethod(method),
		StatusClass: normalizeStatusClass(status),
	}
	seconds := duration.Seconds()
	if seconds < 0 {
		seconds = 0
	}

	metrics.mu.Lock()
	defer metrics.mu.Unlock()
	metrics.initializeLocked()
	addMapCounter(metrics.httpRequests, key, 1)
	if status >= http.StatusBadRequest && status <= 599 {
		addMapCounter(metrics.httpErrors, key, 1)
	}
	observeHistogram(metrics.httpDurations, key, seconds, httpDurationBuckets)
}

func normalizeRoute(pattern string) string {
	if route, allowed := allowedHTTPPatterns[pattern]; allowed {
		return route
	}
	return unknownLabel
}

func normalizeMethod(method string) string {
	switch method {
	case http.MethodGet,
		http.MethodHead,
		http.MethodPost,
		http.MethodPut,
		http.MethodPatch,
		http.MethodDelete,
		http.MethodOptions:
		return method
	default:
		return unknownLabel
	}
}

func normalizeStatusClass(status int) string {
	switch {
	case status >= 100 && status <= 199:
		return "1xx"
	case status >= 200 && status <= 299:
		return "2xx"
	case status >= 300 && status <= 399:
		return "3xx"
	case status >= 400 && status <= 499:
		return "4xx"
	case status >= 500 && status <= 599:
		return "5xx"
	default:
		return unknownLabel
	}
}

type statusResponseWriter struct {
	http.ResponseWriter
	status      int
	wroteHeader bool
}

func (writer *statusResponseWriter) WriteHeader(status int) {
	if writer.wroteHeader {
		return
	}
	writer.status = status
	writer.wroteHeader = true
	writer.ResponseWriter.WriteHeader(status)
}

func (writer *statusResponseWriter) Write(payload []byte) (int, error) {
	if !writer.wroteHeader {
		writer.WriteHeader(http.StatusOK)
	}
	return writer.ResponseWriter.Write(payload)
}

func (writer *statusResponseWriter) ReadFrom(reader io.Reader) (int64, error) {
	if !writer.wroteHeader {
		writer.WriteHeader(http.StatusOK)
	}
	if readerFrom, ok := writer.ResponseWriter.(io.ReaderFrom); ok {
		return readerFrom.ReadFrom(reader)
	}
	return io.Copy(struct{ io.Writer }{Writer: writer.ResponseWriter}, reader)
}

func (writer *statusResponseWriter) Flush() {
	if !writer.wroteHeader {
		writer.WriteHeader(http.StatusOK)
	}
	_ = http.NewResponseController(writer.ResponseWriter).Flush()
}

func (writer *statusResponseWriter) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	return http.NewResponseController(writer.ResponseWriter).Hijack()
}

func (writer *statusResponseWriter) Push(target string, options *http.PushOptions) error {
	pusher, ok := writer.ResponseWriter.(http.Pusher)
	if !ok {
		return http.ErrNotSupported
	}
	return pusher.Push(target, options)
}

func (writer *statusResponseWriter) Unwrap() http.ResponseWriter {
	return writer.ResponseWriter
}
