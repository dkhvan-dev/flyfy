package http

import "context"

type contextKey string

const (
	contextKeyRequestID contextKey = "request_id"
	contextKeyUserID    contextKey = "user_id"
	contextKeySubject   contextKey = "subject"
	contextKeyRoles     contextKey = "roles"
)

func withRequestID(ctx context.Context, requestID string) context.Context {
	return context.WithValue(ctx, contextKeyRequestID, requestID)
}

func RequestIDFromContext(ctx context.Context) string {
	value, _ := ctx.Value(contextKeyRequestID).(string)
	return value
}

func withUserID(ctx context.Context, userID string) context.Context {
	return context.WithValue(ctx, contextKeyUserID, userID)
}

func UserIDFromContext(ctx context.Context) string {
	value, _ := ctx.Value(contextKeyUserID).(string)
	return value
}

func withSubject(ctx context.Context, subject string) context.Context {
	return context.WithValue(ctx, contextKeySubject, subject)
}

func SubjectFromContext(ctx context.Context) string {
	value, _ := ctx.Value(contextKeySubject).(string)
	return value
}

func withRoles(ctx context.Context, roles []string) context.Context {
	return context.WithValue(ctx, contextKeyRoles, roles)
}

func RolesFromContext(ctx context.Context) []string {
	value, _ := ctx.Value(contextKeyRoles).([]string)
	return value
}
