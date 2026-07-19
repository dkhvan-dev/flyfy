package config

import (
	"fmt"
	"net/url"
	"strings"
	"unicode"
)

type ComplianceConfig struct {
	AllowedCallerSPIFFEID string `env:"SAVED_COMPLIANCE_ALLOWED_CALLER_SPIFFE_ID, default=spiffe://inflap/dev/user-service"`
}

func (config ComplianceConfig) Validate(secureEnvironment bool) error {
	identity := config.AllowedCallerSPIFFEID
	parsed, err := url.Parse(identity)
	if err != nil || identity == "" || identity != strings.TrimSpace(identity) ||
		len(identity) > 512 || strings.IndexFunc(identity, unicode.IsControl) >= 0 ||
		parsed.Scheme != "spiffe" || parsed.Host == "" || parsed.User != nil ||
		parsed.RawQuery != "" || parsed.Fragment != "" ||
		!strings.HasSuffix(parsed.EscapedPath(), "/user-service") {
		return fmt.Errorf("SAVED_COMPLIANCE_ALLOWED_CALLER_SPIFFE_ID must be a valid user-service SPIFFE ID")
	}
	if secureEnvironment && strings.Contains(strings.ToLower(identity), "/dev/") {
		return fmt.Errorf("SAVED_COMPLIANCE_ALLOWED_CALLER_SPIFFE_ID must not use a development identity in staging or production")
	}
	return nil
}
