package config

import (
	"fmt"
	"net/url"
	"strings"
	"unicode"
)

type PublicAPIConfig struct {
	Origin string `env:"SAVED_PUBLIC_API_ORIGIN, default=http://localhost:8080"`
}

func (cfg PublicAPIConfig) Validate(secureEnvironment bool) error {
	origin := strings.TrimSpace(cfg.Origin)
	if origin == "" || origin != cfg.Origin || len(origin) > 512 ||
		strings.IndexFunc(origin, unicode.IsControl) >= 0 {
		return fmt.Errorf("SAVED_PUBLIC_API_ORIGIN is invalid")
	}
	parsed, err := url.Parse(origin)
	if err != nil || parsed.Host == "" || parsed.User != nil || parsed.RawQuery != "" ||
		parsed.Fragment != "" || (parsed.Path != "" && parsed.Path != "/") ||
		(parsed.Scheme != "http" && parsed.Scheme != "https") {
		return fmt.Errorf("SAVED_PUBLIC_API_ORIGIN must be an HTTP(S) origin without path, credentials, query, or fragment")
	}
	if secureEnvironment && parsed.Scheme != "https" {
		return fmt.Errorf("SAVED_PUBLIC_API_ORIGIN must use HTTPS in staging and production")
	}
	return nil
}
