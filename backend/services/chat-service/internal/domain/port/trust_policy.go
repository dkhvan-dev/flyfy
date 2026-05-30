package port

import "github.com/dkhvan-dev/flyfy/backend/pkg/trustpolicy"

type TrustPolicyDecision = trustpolicy.Decision

const (
	TrustPolicyAllow      = trustpolicy.DecisionAllow
	TrustPolicyDeny       = trustpolicy.DecisionDeny
	TrustPolicyReview     = trustpolicy.DecisionReview
	TrustPolicyQuarantine = trustpolicy.DecisionQuarantine
	TrustPolicyPending    = trustpolicy.DecisionPending
)

type TrustPolicyCheck = trustpolicy.Check

type TrustPolicyResult = trustpolicy.Result

type TrustPolicyClient = trustpolicy.PolicyClient
