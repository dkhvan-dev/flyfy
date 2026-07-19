package config

import (
	"context"
	"testing"
	"time"
)

func TestLoadIncludesValidatedSavedServiceDefaults(t *testing.T) {
	t.Setenv("TOKEN_SERVICE_ID", "api-gateway")
	t.Setenv("TOKEN_SERVICE_SECRET", "secret")
	setValidPlatformPolicyDevelopmentEnv(t)
	t.Setenv("SAVED_SERVICE_URL", "http://saved-service:8102")
	t.Setenv("SAVED_SERVICE_REQUEST_TIMEOUT", "10s")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.SavedService.URL != "http://saved-service:8102" {
		t.Fatalf("saved-service URL = %q", cfg.SavedService.URL)
	}
	if cfg.SavedService.RequestTimeout != 10*time.Second {
		t.Fatalf("saved-service timeout = %s, want 10s", cfg.SavedService.RequestTimeout)
	}
	if cfg.PlatformPolicy.BaseURL != "http://switches-service:8096" {
		t.Fatalf("platform policy base URL = %q", cfg.PlatformPolicy.BaseURL)
	}
	if cfg.PlatformPolicy.HTTPTimeout != 750*time.Millisecond || cfg.PlatformPolicy.RefreshTimeout != time.Second {
		t.Fatalf(
			"platform policy timeouts = HTTP %s, refresh %s",
			cfg.PlatformPolicy.HTTPTimeout,
			cfg.PlatformPolicy.RefreshTimeout,
		)
	}
}

func TestLoadRejectsInvalidSavedServiceConfig(t *testing.T) {
	tests := map[string]struct {
		url     string
		timeout string
	}{
		"relative URL":       {url: "saved-service:8102", timeout: "10s"},
		"unsupported scheme": {url: "ftp://saved-service:8102", timeout: "10s"},
		"URL credentials":    {url: "http://user:password@saved-service:8102", timeout: "10s"},
		"URL path":           {url: "http://saved-service:8102/v1", timeout: "10s"},
		"URL query":          {url: "http://saved-service:8102?tenant=private", timeout: "10s"},
		"zero timeout":       {url: "http://saved-service:8102", timeout: "0s"},
		"timeout above max":  {url: "http://saved-service:8102", timeout: "31s"},
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			t.Setenv("TOKEN_SERVICE_ID", "api-gateway")
			t.Setenv("TOKEN_SERVICE_SECRET", "secret")
			setValidPlatformPolicyDevelopmentEnv(t)
			t.Setenv("SAVED_SERVICE_URL", tc.url)
			t.Setenv("SAVED_SERVICE_REQUEST_TIMEOUT", tc.timeout)

			if _, err := Load(context.Background()); err == nil {
				t.Fatal("Load error = nil, want invalid saved-service config error")
			}
		})
	}
}

func TestLoadIncludesUserRouteDownstreamDefault(t *testing.T) {
	t.Setenv("TOKEN_SERVICE_ID", "api-gateway")
	t.Setenv("TOKEN_SERVICE_SECRET", "secret")
	setValidPlatformPolicyDevelopmentEnv(t)

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.Downstreams.UserRouteService != "http://user-route-service:8096" {
		t.Fatalf("user route downstream = %q", cfg.Downstreams.UserRouteService)
	}
}

func TestLoadIncludesSearchDownstreamDefault(t *testing.T) {
	t.Setenv("TOKEN_SERVICE_ID", "api-gateway")
	t.Setenv("TOKEN_SERVICE_SECRET", "secret")
	setValidPlatformPolicyDevelopmentEnv(t)

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.Downstreams.SearchService != "http://search-service:8101" {
		t.Fatalf("search downstream = %q", cfg.Downstreams.SearchService)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("TOKEN_SERVICE_ID", "api-gateway")
	t.Setenv("TOKEN_SERVICE_SECRET", "secret")
	setValidPlatformPolicyDevelopmentEnv(t)
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/api-gateway/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/api-gateway/client-key.pem")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	transport := cfg.MTLS.ClientConfig("token-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ClientCertPath != "/run/mtls/api-gateway/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/api-gateway/client-key.pem" ||
		transport.ServerName != "token-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}
}

func TestLoadAcceptsProductionPlatformPolicyOverHTTPS(t *testing.T) {
	t.Setenv("APP_ENV", "production")
	t.Setenv("TOKEN_SERVICE_ID", "api-gateway")
	t.Setenv("TOKEN_SERVICE_SECRET", "secret")
	t.Setenv("PLATFORM_POLICY_BASE_URL", "https://switches-service:9443")
	t.Setenv("PLATFORM_POLICY_INTERNAL_SERVICE_TOKEN", "policy-secret")
	t.Setenv("PLATFORM_POLICY_ALLOW_INSECURE_HTTP", "false")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.PlatformPolicy.BaseURL != "https://switches-service:9443" {
		t.Fatalf("platform policy base URL = %q", cfg.PlatformPolicy.BaseURL)
	}
}

func TestLoadRejectsUnsafePlatformPolicyConfig(t *testing.T) {
	tests := map[string]struct {
		environment       string
		baseURL           string
		token             string
		allowInsecureHTTP string
		httpTimeout       string
		refreshTimeout    string
		maxResponseBytes  string
	}{
		"production plaintext HTTP": {
			environment:       "production",
			baseURL:           "http://switches-service:8096",
			token:             "policy-secret",
			allowInsecureHTTP: "true",
			httpTimeout:       "750ms",
			refreshTimeout:    "1s",
			maxResponseBytes:  "4096",
		},
		"development HTTP without opt-in": {
			environment:       "development",
			baseURL:           "http://switches-service:8096",
			token:             "policy-secret",
			allowInsecureHTTP: "false",
			httpTimeout:       "750ms",
			refreshTimeout:    "1s",
			maxResponseBytes:  "4096",
		},
		"staging plaintext HTTP": {
			environment:       "staging",
			baseURL:           "http://switches-service:8096",
			token:             "policy-secret",
			allowInsecureHTTP: "true",
			httpTimeout:       "750ms",
			refreshTimeout:    "1s",
			maxResponseBytes:  "4096",
		},
		"URL credentials": {
			environment:       "development",
			baseURL:           "https://user:password@switches-service:9443",
			token:             "policy-secret",
			allowInsecureHTTP: "false",
			httpTimeout:       "750ms",
			refreshTimeout:    "1s",
			maxResponseBytes:  "4096",
		},
		"URL path": {
			environment:       "development",
			baseURL:           "https://switches-service:9443/internal",
			token:             "policy-secret",
			allowInsecureHTTP: "false",
			httpTimeout:       "750ms",
			refreshTimeout:    "1s",
			maxResponseBytes:  "4096",
		},
		"missing token": {
			environment:       "development",
			baseURL:           "https://switches-service:9443",
			token:             "",
			allowInsecureHTTP: "false",
			httpTimeout:       "750ms",
			refreshTimeout:    "1s",
			maxResponseBytes:  "4096",
		},
		"HTTP timeout exceeds refresh": {
			environment:       "development",
			baseURL:           "https://switches-service:9443",
			token:             "policy-secret",
			allowInsecureHTTP: "false",
			httpTimeout:       "2s",
			refreshTimeout:    "1s",
			maxResponseBytes:  "4096",
		},
		"refresh consumes Saved deadline": {
			environment:       "development",
			baseURL:           "https://switches-service:9443",
			token:             "policy-secret",
			allowInsecureHTTP: "false",
			httpTimeout:       "750ms",
			refreshTimeout:    "10s",
			maxResponseBytes:  "4096",
		},
		"oversized response limit": {
			environment:       "development",
			baseURL:           "https://switches-service:9443",
			token:             "policy-secret",
			allowInsecureHTTP: "false",
			httpTimeout:       "750ms",
			refreshTimeout:    "1s",
			maxResponseBytes:  "65537",
		},
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			t.Setenv("APP_ENV", tc.environment)
			t.Setenv("TOKEN_SERVICE_ID", "api-gateway")
			t.Setenv("TOKEN_SERVICE_SECRET", "secret")
			t.Setenv("PLATFORM_POLICY_BASE_URL", tc.baseURL)
			t.Setenv("PLATFORM_POLICY_INTERNAL_SERVICE_TOKEN", tc.token)
			t.Setenv("PLATFORM_POLICY_ALLOW_INSECURE_HTTP", tc.allowInsecureHTTP)
			t.Setenv("PLATFORM_POLICY_HTTP_TIMEOUT", tc.httpTimeout)
			t.Setenv("PLATFORM_POLICY_REFRESH_TIMEOUT", tc.refreshTimeout)
			t.Setenv("PLATFORM_POLICY_MAX_RESPONSE_BYTES", tc.maxResponseBytes)

			if _, err := Load(context.Background()); err == nil {
				t.Fatal("Load error = nil, want unsafe platform policy config rejection")
			}
		})
	}
}

func setValidPlatformPolicyDevelopmentEnv(t *testing.T) {
	t.Helper()
	t.Setenv("PLATFORM_POLICY_BASE_URL", "http://switches-service:8096")
	t.Setenv("PLATFORM_POLICY_INTERNAL_SERVICE_TOKEN", "policy-secret")
	t.Setenv("PLATFORM_POLICY_ALLOW_INSECURE_HTTP", "true")
}
