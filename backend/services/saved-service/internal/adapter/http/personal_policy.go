package http

import (
	"context"
	"errors"
	"net/http"

	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

var ErrInvalidPersonalPolicyDependencies = errors.New("invalid personal policy dependencies")

type PersonalPolicyGuard interface {
	Guard(context.Context) (saveditem.PolicyGrant, error)
}

type PersonalPolicyMiddleware struct {
	guard PersonalPolicyGuard
}

func NewPersonalPolicyMiddleware(guard PersonalPolicyGuard) (*PersonalPolicyMiddleware, error) {
	if guard == nil {
		return nil, ErrInvalidPersonalPolicyDependencies
	}
	return &PersonalPolicyMiddleware{guard: guard}, nil
}

func (m *PersonalPolicyMiddleware) Wrap(next http.Handler) http.Handler {
	if m == nil || m.guard == nil || next == nil {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			writeDomainError(w, r, domain.ErrDependencyUnavailable)
		})
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		grant, err := m.guard.Guard(r.Context())
		if err != nil {
			writeDomainError(w, r, err)
			return
		}
		if grant.Revision == 0 {
			writeDomainError(w, r, domain.ErrDependencyUnavailable)
			return
		}
		next.ServeHTTP(w, r)
	})
}
