package model

import (
	"errors"
	"fmt"
	"strings"
)

type Domain string

const (
	DomainActivity    Domain = "activity"
	DomainExcursion   Domain = "excursion"
	DomainPlace       Domain = "place"
	DomainGuide       Domain = "guide"
	DomainCommunity   Domain = "community"
	DomainUser        Domain = "user"
	DomainHelpArticle Domain = "help_article"
)

type Scope string

const (
	ScopeGlobal      Scope = "global"
	ScopeActivity    Scope = "activity"
	ScopeExcursion   Scope = "excursion"
	ScopePlace       Scope = "place"
	ScopeGuide       Scope = "guide"
	ScopeCommunity   Scope = "community"
	ScopeUser        Scope = "user"
	ScopeHelpArticle Scope = "help_article"
)

var (
	ErrUnsupportedDomain   = errors.New("unsupported search domain")
	ErrUnsupportedScope    = errors.New("unsupported search scope")
	ErrScopeDomainMismatch = errors.New("search scope does not allow requested domain")
)

func AllSearchableDomains() []Domain {
	return []Domain{
		DomainActivity,
		DomainExcursion,
		DomainPlace,
		DomainGuide,
		DomainCommunity,
		DomainUser,
		DomainHelpArticle,
	}
}

func ParseDomain(raw string) (Domain, error) {
	value := strings.ToLower(strings.TrimSpace(raw))
	switch Domain(value) {
	case DomainActivity, DomainExcursion, DomainPlace, DomainGuide, DomainCommunity, DomainUser, DomainHelpArticle:
		return Domain(value), nil
	default:
		return "", fmt.Errorf("%w: %s", ErrUnsupportedDomain, value)
	}
}

func ParseScope(raw string) (Scope, error) {
	value := strings.ToLower(strings.TrimSpace(raw))
	if value == "" {
		return ScopeGlobal, nil
	}

	switch Scope(value) {
	case ScopeGlobal, ScopeActivity, ScopeExcursion, ScopePlace, ScopeGuide, ScopeCommunity, ScopeUser, ScopeHelpArticle:
		return Scope(value), nil
	default:
		return "", fmt.Errorf("%w: %s", ErrUnsupportedScope, value)
	}
}

func DomainsForScope(scope Scope, requested []Domain) ([]Domain, error) {
	if scope == ScopeGlobal {
		if len(requested) == 0 {
			return AllSearchableDomains(), nil
		}
		return dedupeDomains(requested), nil
	}

	scopeDomain, err := scopeDomain(scope)
	if err != nil {
		return nil, err
	}
	if len(requested) == 0 {
		return []Domain{scopeDomain}, nil
	}

	for _, domain := range requested {
		if domain != scopeDomain {
			return nil, fmt.Errorf("%w: scope=%s domain=%s", ErrScopeDomainMismatch, scope, domain)
		}
	}
	return []Domain{scopeDomain}, nil
}

func scopeDomain(scope Scope) (Domain, error) {
	switch scope {
	case ScopeActivity:
		return DomainActivity, nil
	case ScopeExcursion:
		return DomainExcursion, nil
	case ScopePlace:
		return DomainPlace, nil
	case ScopeGuide:
		return DomainGuide, nil
	case ScopeCommunity:
		return DomainCommunity, nil
	case ScopeUser:
		return DomainUser, nil
	case ScopeHelpArticle:
		return DomainHelpArticle, nil
	default:
		return "", fmt.Errorf("%w: %s", ErrUnsupportedScope, scope)
	}
}

func dedupeDomains(domains []Domain) []Domain {
	seen := make(map[Domain]struct{}, len(domains))
	result := make([]Domain, 0, len(domains))
	for _, domain := range domains {
		if _, ok := seen[domain]; ok {
			continue
		}
		seen[domain] = struct{}{}
		result = append(result, domain)
	}
	return result
}
