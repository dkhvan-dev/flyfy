package http

import "context"

type contextKey string

const (
	contextKeyRequestID contextKey = "request_id"
	contextKeyUserID    contextKey = "user_id"
	contextKeyUserRoles contextKey = "user_roles"
	contextKeySubject   contextKey = "auth_subject"
	contextKeyInternal  contextKey = "internal_call"
)

func withRequestID(ctx context.Context, requestID string) context.Context {
	return context.WithValue(ctx, contextKeyRequestID, requestID)
}

func withUserID(ctx context.Context, userID string) context.Context {
	return context.WithValue(ctx, contextKeyUserID, userID)
}

func withUserRoles(ctx context.Context, roles []string) context.Context {
	return context.WithValue(ctx, contextKeyUserRoles, roles)
}

func withSubject(ctx context.Context, subject string) context.Context {
	return context.WithValue(ctx, contextKeySubject, subject)
}

func withInternalCall(ctx context.Context) context.Context {
	return context.WithValue(ctx, contextKeyInternal, true)
}

func RequestIDFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeyRequestID).(string)
	return v
}

func UserIDFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeyUserID).(string)
	return v
}

func UserRolesFromContext(ctx context.Context) []string {
	v, _ := ctx.Value(contextKeyUserRoles).([]string)
	return v
}

func SubjectFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeySubject).(string)
	return v
}

func InternalCallFromContext(ctx context.Context) bool {
	v, _ := ctx.Value(contextKeyInternal).(bool)
	return v
}
