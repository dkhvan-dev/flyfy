package grpc

import "context"

type contextKey string

const (
	contextKeyRequestID   contextKey = "request_id"
	contextKeySubject     contextKey = "subject"
	contextKeyService     contextKey = "service_name"
	contextKeySavedCaller contextKey = "saved_source_caller"
)

func withRequestID(ctx context.Context, requestID string) context.Context {
	return context.WithValue(ctx, contextKeyRequestID, requestID)
}

func withSubject(ctx context.Context, subject string) context.Context {
	return context.WithValue(ctx, contextKeySubject, subject)
}

func withService(ctx context.Context, service string) context.Context {
	return context.WithValue(ctx, contextKeyService, service)
}

func withSavedSourceCaller(ctx context.Context, caller string) context.Context {
	return context.WithValue(ctx, contextKeySavedCaller, caller)
}

func RequestIDFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeyRequestID).(string)
	return v
}

func SubjectFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeySubject).(string)
	return v
}

func ServiceFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeyService).(string)
	return v
}

func savedSourceCallerFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeySavedCaller).(string)
	return v
}
