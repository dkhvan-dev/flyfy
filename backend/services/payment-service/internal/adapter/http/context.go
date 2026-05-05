package http

import "context"

type contextKey string

const (
	contextKeyUserID    contextKey = "user_id"
	contextKeyRoles     contextKey = "roles"
	contextKeySubject   contextKey = "subject"
	contextKeyRequestID contextKey = "request_id"
	contextKeyInternal  contextKey = "internal"
)

func UserIDFromContext(ctx context.Context) string {
	if v, ok := ctx.Value(contextKeyUserID).(string); ok {
		return v
	}
	return ""
}

func IsInternalFromContext(ctx context.Context) bool {
	if v, ok := ctx.Value(contextKeyInternal).(bool); ok {
		return v
	}
	return false
}

func withContextValue(ctx context.Context, key contextKey, value any) context.Context {
	return context.WithValue(ctx, key, value)
}
