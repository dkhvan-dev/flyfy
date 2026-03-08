package http

import "context"

type contextKey string

const (
	contextKeyRequestID contextKey = "request_id"
	contextKeyUserID    contextKey = "user_id"
	contextKeyUserRoles contextKey = "user_roles"
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
