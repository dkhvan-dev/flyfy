package http

import (
	"net"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/config"
)

const maxMultipartFormMemory = 64 << 20

func requestIDMiddleware(cfg *config.Config, next http.Handler) http.Handler {
	headerName := strings.TrimSpace(cfg.Security.RequestIDHeader)
	if headerName == "" {
		headerName = "X-Request-Id"
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := strings.TrimSpace(r.Header.Get(headerName))
		if requestID == "" {
			requestID = uuid.NewString()
		}
		w.Header().Set(headerName, requestID)
		next.ServeHTTP(w, r.WithContext(withRequestID(r.Context(), requestID)))
	})
}

func securityHeadersMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: https://upload.wikimedia.org https://commons.wikimedia.org; frame-ancestors 'none'; base-uri 'self'; form-action 'self'")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Referrer-Policy", "same-origin")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("Cache-Control", "no-store")
		next.ServeHTTP(w, r)
	})
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		next.ServeHTTP(rw, r)
		log.Info().
			Str("method", r.Method).
			Str("path", r.URL.Path).
			Int("status", rw.statusCode).
			Str("request_id", requestIDFromContext(r.Context())).
			Msg("admin request completed")
	})
}

func (s *Server) localeMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		locale := resolveLocale(r)
		if queryLocale, ok := normalizeLocale(r.URL.Query().Get("lang")); ok {
			http.SetCookie(w, &http.Cookie{
				Name:     localeCookieName,
				Value:    queryLocale,
				Path:     "/admin",
				HttpOnly: true,
				Secure:   s.cfg.Security.CookieSecure,
				SameSite: http.SameSiteStrictMode,
				MaxAge:   60 * 60 * 24 * 365,
			})
			locale = queryLocale
		}
		next.ServeHTTP(w, r.WithContext(withLocale(r.Context(), locale)))
	})
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(statusCode int) {
	rw.statusCode = statusCode
	rw.ResponseWriter.WriteHeader(statusCode)
}

func (s *Server) sessionMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if isPublicPath(r.URL.Path) {
			next.ServeHTTP(w, r)
			return
		}
		sessionCookie, err := r.Cookie(s.cfg.Security.SessionCookieName)
		if err != nil || strings.TrimSpace(sessionCookie.Value) == "" {
			http.Redirect(w, r, "/admin/login", http.StatusSeeOther)
			return
		}
		csrfCookie, err := r.Cookie(s.cfg.Security.CSRFCookieName)
		if err != nil || strings.TrimSpace(csrfCookie.Value) == "" {
			s.clearSessionCookies(w)
			http.Redirect(w, r, "/admin/login", http.StatusSeeOther)
			return
		}
		staff, session, err := s.auth.AuthenticateSession(r.Context(), sessionCookie.Value)
		if err != nil {
			s.clearSessionCookies(w)
			http.Redirect(w, r, "/admin/login", http.StatusSeeOther)
			return
		}
		if staff.RequiresPasswordChange() && !isPasswordResetAllowedPath(r.URL.Path) {
			http.Redirect(w, r, "/admin/password/change", http.StatusSeeOther)
			return
		}
		if isWriteMethod(r.Method) {
			if err = parseRequestForm(r); err != nil {
				http.Error(w, translate(localeFromContext(r.Context()), "error.invalidForm"), http.StatusBadRequest)
				return
			}
			formToken := strings.TrimSpace(r.Form.Get("csrf_token"))
			cookieToken := strings.TrimSpace(csrfCookie.Value)
			if formToken != cookieToken || !s.auth.ValidateCSRF(session, formToken) {
				http.Error(w, translate(localeFromContext(r.Context()), "error.invalidCSRF"), http.StatusForbidden)
				return
			}
		}
		ctx := withStaff(r.Context(), staff)
		ctx = withSession(ctx, session)
		ctx = withCSRFToken(ctx, strings.TrimSpace(csrfCookie.Value))
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func parseRequestForm(r *http.Request) error {
	if isMultipartRequest(r) {
		return r.ParseMultipartForm(maxMultipartFormMemory)
	}
	return r.ParseForm()
}

func isMultipartRequest(r *http.Request) bool {
	contentType := strings.ToLower(strings.TrimSpace(r.Header.Get("Content-Type")))
	return strings.HasPrefix(contentType, "multipart/")
}

func isPasswordResetAllowedPath(path string) bool {
	return path == "/admin/password/change" ||
		path == "/admin/logout" ||
		strings.HasPrefix(path, "/admin/static/")
}

func isPublicPath(path string) bool {
	return path == "/health" ||
		path == "/ready" ||
		path == "/admin/login" ||
		strings.HasPrefix(path, "/admin/static/")
}

func isWriteMethod(method string) bool {
	switch method {
	case http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete:
		return true
	default:
		return false
	}
}

func requestMetadata(r *http.Request) app.RequestMetadata {
	return app.RequestMetadata{
		RequestID: requestIDFromContext(r.Context()),
		IPAddress: clientIP(r),
		UserAgent: r.UserAgent(),
	}
}

func clientIP(r *http.Request) string {
	if forwarded := strings.TrimSpace(r.Header.Get("X-Forwarded-For")); forwarded != "" {
		parts := strings.Split(forwarded, ",")
		return strings.TrimSpace(parts[0])
	}
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err == nil {
		return host
	}
	return r.RemoteAddr
}
