package policy

import (
	"context"
	"fmt"
	"strings"
	"testing"

	"kz/inflap/backend/pkg/platformpolicy"
)

func TestInternalTokenHeaderProviderUsesRequiredHeader(t *testing.T) {
	provider, err := NewInternalTokenHeaderProvider("test-platform-policy-secret")
	if err != nil {
		t.Fatalf("NewInternalTokenHeaderProvider() error = %v", err)
	}
	header, err := provider.TokenHeader(context.Background())
	if err != nil {
		t.Fatalf("TokenHeader() error = %v", err)
	}
	if header.Name != platformpolicy.HeaderInternalServiceToken ||
		header.Value != "test-platform-policy-secret" {
		t.Fatalf("TokenHeader() = %#v", header)
	}
	if formatted := fmt.Sprintf("%+v %#v", provider, provider); strings.Contains(formatted, header.Value) {
		t.Fatalf("provider formatting disclosed token: %s", formatted)
	}
}

func TestInternalTokenHeaderProviderRejectsAmbiguousToken(t *testing.T) {
	for _, token := range []string{"", " token", "token\n"} {
		if _, err := NewInternalTokenHeaderProvider(token); err == nil {
			t.Fatalf("NewInternalTokenHeaderProvider(%q) succeeded", token)
		}
	}
}
