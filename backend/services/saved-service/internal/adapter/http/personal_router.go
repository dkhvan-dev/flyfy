package http

import (
	"errors"
	"net/http"

	"kz/inflap/backend/services/saved-service/internal/app/productrollout"
)

var ErrInvalidPersonalRouterDependencies = errors.New("invalid personal router dependencies")

type PersonalRouteRegistrar interface {
	Register(*http.ServeMux) error
}

func NewPersonalRouter(
	authorizer GatewayAuthorizer,
	policyGuard PersonalPolicyGuard,
	registrars ...PersonalRouteRegistrar,
) (http.Handler, error) {
	return newPersonalRouter(authorizer, policyGuard, nil, registrars...)
}

func NewPersonalRouterWithRollout(
	authorizer GatewayAuthorizer,
	policyGuard PersonalPolicyGuard,
	rolloutGate productrollout.Gate,
	registrars ...PersonalRouteRegistrar,
) (http.Handler, error) {
	if rolloutGate == nil {
		return nil, ErrInvalidPersonalRouterDependencies
	}
	return newPersonalRouter(authorizer, policyGuard, rolloutGate, registrars...)
}

func newPersonalRouter(
	authorizer GatewayAuthorizer,
	policyGuard PersonalPolicyGuard,
	rolloutGate productrollout.Gate,
	registrars ...PersonalRouteRegistrar,
) (http.Handler, error) {
	if authorizer == nil || policyGuard == nil || len(registrars) == 0 {
		return nil, ErrInvalidPersonalRouterDependencies
	}
	mux := http.NewServeMux()
	for _, registrar := range registrars {
		if registrar == nil {
			return nil, ErrInvalidPersonalRouterDependencies
		}
		if err := registrar.Register(mux); err != nil {
			return nil, err
		}
	}
	mux.HandleFunc("/v1/users/me/", writeNotFound)

	policy, err := NewPersonalPolicyMiddleware(policyGuard)
	if err != nil {
		return nil, err
	}
	auth, err := NewPersonalAuthMiddleware(authorizer)
	if err != nil {
		return nil, err
	}
	var routed http.Handler = mux
	if rolloutGate != nil {
		rollout, rolloutErr := NewProductRolloutMiddleware(rolloutGate)
		if rolloutErr != nil {
			return nil, rolloutErr
		}
		routed = rollout.Wrap(routed)
	}
	return auth.Wrap(policy.Wrap(routed)), nil
}
