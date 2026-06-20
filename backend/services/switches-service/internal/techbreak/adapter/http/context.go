package http

import "context"

type contextKey string

const (
	userIDKey    contextKey = "user_id"
	subjectKey   contextKey = "subject"
	rolesKey     contextKey = "roles"
	requestIDKey contextKey = "request_id"
)

func withUserID(ctx context.Context, userID string) context.Context {
	return context.WithValue(ctx, userIDKey, userID)
}

func withSubject(ctx context.Context, subject string) context.Context {
	return context.WithValue(ctx, subjectKey, subject)
}

func withRoles(ctx context.Context, roles []string) context.Context {
	return context.WithValue(ctx, rolesKey, roles)
}

func withRequestID(ctx context.Context, requestID string) context.Context {
	return context.WithValue(ctx, requestIDKey, requestID)
}

func SubjectFromContext(ctx context.Context) string {
	value, _ := ctx.Value(subjectKey).(string)
	return value
}

func RequestIDFromContext(ctx context.Context) string {
	value, _ := ctx.Value(requestIDKey).(string)
	return value
}

func RolesFromContext(ctx context.Context) []string {
	value, _ := ctx.Value(rolesKey).([]string)
	return value
}
