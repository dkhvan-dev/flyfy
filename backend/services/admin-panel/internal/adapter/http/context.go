package http

import (
	"context"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type contextKey string

const (
	contextKeyStaff     contextKey = "staff"
	contextKeySession   contextKey = "session"
	contextKeyCSRFToken contextKey = "csrf_token"
	contextKeyRequestID contextKey = "request_id"
	contextKeyLocale    contextKey = "locale"
)

func withStaff(ctx context.Context, staff *model.StaffUser) context.Context {
	return context.WithValue(ctx, contextKeyStaff, staff)
}

func staffFromContext(ctx context.Context) *model.StaffUser {
	value, _ := ctx.Value(contextKeyStaff).(*model.StaffUser)
	return value
}

func withSession(ctx context.Context, session *model.StaffSession) context.Context {
	return context.WithValue(ctx, contextKeySession, session)
}

func sessionFromContext(ctx context.Context) *model.StaffSession {
	value, _ := ctx.Value(contextKeySession).(*model.StaffSession)
	return value
}

func withCSRFToken(ctx context.Context, token string) context.Context {
	return context.WithValue(ctx, contextKeyCSRFToken, token)
}

func csrfTokenFromContext(ctx context.Context) string {
	value, _ := ctx.Value(contextKeyCSRFToken).(string)
	return value
}

func withRequestID(ctx context.Context, requestID string) context.Context {
	return context.WithValue(ctx, contextKeyRequestID, requestID)
}

func requestIDFromContext(ctx context.Context) string {
	value, _ := ctx.Value(contextKeyRequestID).(string)
	return value
}

func withLocale(ctx context.Context, locale string) context.Context {
	return context.WithValue(ctx, contextKeyLocale, locale)
}

func localeFromContext(ctx context.Context) string {
	value, _ := ctx.Value(contextKeyLocale).(string)
	if locale, ok := normalizeLocale(value); ok {
		return locale
	}
	return defaultLocale
}
