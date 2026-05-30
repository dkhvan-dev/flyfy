package grpc

import "context"

type contextKey string

const (
	contextKeyRequestID contextKey = "request_id"
	contextKeySubject   contextKey = "subject"
	contextKeyService   contextKey = "service_name"
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

func RequestIDFromContext(ctx context.Context) string {
	value, _ := ctx.Value(contextKeyRequestID).(string)
	return value
}

func SubjectFromContext(ctx context.Context) string {
	value, _ := ctx.Value(contextKeySubject).(string)
	return value
}

func ServiceFromContext(ctx context.Context) string {
	value, _ := ctx.Value(contextKeyService).(string)
	return value
}
