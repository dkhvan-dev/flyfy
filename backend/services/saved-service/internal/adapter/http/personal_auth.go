package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"unicode"

	"github.com/google/uuid"
)

const (
	HeaderAuthSubject       = "X-Auth-Subject"
	HeaderUserID            = "X-User-Id"
	HeaderSessionGeneration = "X-Session-Generation"
	HeaderRequestID         = "X-Request-Id"
)

var ErrInvalidPersonalAuthDependencies = errors.New("invalid personal auth dependencies")

type GatewayAuthorizer interface {
	AuthorizeGateway(ctx context.Context, authorizationHeader string) error
}

type PersonalPrincipal struct {
	Subject           uuid.UUID
	UserID            uuid.UUID
	SessionGeneration uuid.UUID
	RequestID         string
}

type principalContextKey struct{}

type PersonalAuthMiddleware struct {
	authorizer GatewayAuthorizer
}

func NewPersonalAuthMiddleware(authorizer GatewayAuthorizer) (*PersonalAuthMiddleware, error) {
	if authorizer == nil {
		return nil, ErrInvalidPersonalAuthDependencies
	}
	return &PersonalAuthMiddleware{authorizer: authorizer}, nil
}

func (m *PersonalAuthMiddleware) Wrap(next http.Handler) http.Handler {
	if m == nil || m.authorizer == nil || next == nil {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			writePersonalAuthError(w, r, "UNAUTHENTICATED")
		})
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if err := m.authorizer.AuthorizeGateway(r.Context(), r.Header.Get("Authorization")); err != nil {
			writePersonalAuthError(w, r, "UNAUTHENTICATED")
			return
		}

		principal, err := principalFromTrustedHeaders(r.Header)
		if err != nil {
			writePersonalAuthError(w, r, "UNAUTHENTICATED")
			return
		}
		ctx := context.WithValue(r.Context(), principalContextKey{}, principal)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func PersonalPrincipalFromContext(ctx context.Context) (PersonalPrincipal, bool) {
	principal, ok := ctx.Value(principalContextKey{}).(PersonalPrincipal)
	return principal, ok
}

func principalFromTrustedHeaders(header http.Header) (PersonalPrincipal, error) {
	subject := header.Get(HeaderAuthSubject)
	requestID := header.Get(HeaderRequestID)
	subjectID, subjectErr := parseCanonicalNonZeroUUID(subject)
	userID, userErr := uuid.Parse(header.Get(HeaderUserID))
	sessionGeneration, sessionErr := uuid.Parse(header.Get(HeaderSessionGeneration))
	if subjectErr != nil ||
		requestID == "" || requestID != strings.TrimSpace(requestID) || len(requestID) > 128 || containsControl(requestID) ||
		userErr != nil || userID == uuid.Nil || userID.String() != header.Get(HeaderUserID) ||
		sessionErr != nil || sessionGeneration == uuid.Nil || sessionGeneration.String() != header.Get(HeaderSessionGeneration) {
		return PersonalPrincipal{}, errors.New("invalid trusted personal identity headers")
	}
	return PersonalPrincipal{
		Subject:           subjectID,
		UserID:            userID,
		SessionGeneration: sessionGeneration,
		RequestID:         requestID,
	}, nil
}

func parseCanonicalNonZeroUUID(value string) (uuid.UUID, error) {
	parsed, err := uuid.Parse(value)
	if err != nil || parsed == uuid.Nil || parsed.String() != value {
		return uuid.Nil, errors.New("invalid canonical UUID")
	}
	return parsed, nil
}

func containsControl(value string) bool {
	return strings.IndexFunc(value, unicode.IsControl) >= 0
}

func writePersonalAuthError(w http.ResponseWriter, r *http.Request, code string) {
	requestID := r.Header.Get(HeaderRequestID)
	if requestID == "" || requestID != strings.TrimSpace(requestID) || len(requestID) > 128 || containsControl(requestID) {
		requestID = uuid.NewString()
	}
	w.Header().Set("Cache-Control", "private, no-store")
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Language", effectiveErrorLocale(r.Header.Get("Accept-Language")))
	w.Header().Set("Pragma", "no-cache")
	w.Header().Set("Vary", "Authorization, Accept-Language")
	w.Header().Set("WWW-Authenticate", "Bearer")
	w.Header().Set(HeaderRequestID, requestID)
	w.WriteHeader(http.StatusUnauthorized)
	response := map[string]any{"code": code, "retryable": false, "request_id": requestID}
	_ = json.NewEncoder(w).Encode(response)
}

func effectiveErrorLocale(acceptLanguage string) string {
	for _, candidate := range strings.Split(acceptLanguage, ",") {
		languageRange := strings.TrimSpace(strings.SplitN(candidate, ";", 2)[0])
		primary := strings.ToLower(strings.SplitN(languageRange, "-", 2)[0])
		switch primary {
		case "en", "ru", "kk":
			return primary
		}
	}
	return "ru"
}
