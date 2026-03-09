package http

import (
	"context"
	"strings"
)

type contextKey string

const (
	contextKeyUserID  contextKey = "user_id"
	contextKeySubject contextKey = "subject"
	contextKeyRole    contextKey = "role"
)

func UserIDFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeyUserID).(string)
	return strings.TrimSpace(v)
}

func SubjectFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeySubject).(string)
	return strings.TrimSpace(v)
}

func RoleFromContext(ctx context.Context) string {
	v, _ := ctx.Value(contextKeyRole).(string)
	return strings.TrimSpace(v)
}

func withUserID(ctx context.Context, userID string) context.Context {
	return context.WithValue(ctx, contextKeyUserID, strings.TrimSpace(userID))
}

func withSubject(ctx context.Context, subject string) context.Context {
	return context.WithValue(ctx, contextKeySubject, strings.TrimSpace(subject))
}

func withRole(ctx context.Context, role string) context.Context {
	return context.WithValue(ctx, contextKeyRole, strings.TrimSpace(role))
}
