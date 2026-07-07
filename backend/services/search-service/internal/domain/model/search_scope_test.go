package model

import (
	"errors"
	"testing"
)

func TestDomainsForScopeGlobalAllowsOnlySearchableDomains(t *testing.T) {
	domains, err := DomainsForScope(ScopeGlobal, nil)
	if err != nil {
		t.Fatalf("DomainsForScope returned error: %v", err)
	}

	want := []Domain{
		DomainActivity,
		DomainExcursion,
		DomainPlace,
		DomainGuide,
		DomainCommunity,
		DomainUser,
	}
	if len(domains) != len(want) {
		t.Fatalf("domains length = %d, want %d: %#v", len(domains), len(want), domains)
	}
	for i := range want {
		if domains[i] != want[i] {
			t.Fatalf("domains[%d] = %q, want %q", i, domains[i], want[i])
		}
	}
}

func TestDomainsForScopeRejectsOutOfScopeDomains(t *testing.T) {
	tests := []string{"route", "routes", "checklist", "checklists", "chat", "chats"}

	for _, raw := range tests {
		t.Run(raw, func(t *testing.T) {
			_, err := ParseDomain(raw)
			if !errors.Is(err, ErrUnsupportedDomain) {
				t.Fatalf("ParseDomain(%q) error = %v, want ErrUnsupportedDomain", raw, err)
			}
		})
	}
}

func TestDomainsForScopeEntityScopeRejectsOtherDomains(t *testing.T) {
	_, err := DomainsForScope(ScopeActivity, []Domain{DomainActivity, DomainPlace})
	if !errors.Is(err, ErrScopeDomainMismatch) {
		t.Fatalf("DomainsForScope error = %v, want ErrScopeDomainMismatch", err)
	}
}

func TestDomainsForScopeEntityScopeDefaultsToItsDomain(t *testing.T) {
	domains, err := DomainsForScope(ScopeGuide, nil)
	if err != nil {
		t.Fatalf("DomainsForScope returned error: %v", err)
	}
	if len(domains) != 1 || domains[0] != DomainGuide {
		t.Fatalf("domains = %#v, want guide only", domains)
	}
}

func TestParseScopeRejectsUnsupportedScope(t *testing.T) {
	_, err := ParseScope("routes")
	if !errors.Is(err, ErrUnsupportedScope) {
		t.Fatalf("ParseScope error = %v, want ErrUnsupportedScope", err)
	}
}
