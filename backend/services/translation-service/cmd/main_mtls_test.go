package main

import (
	"crypto/tls"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/translation-service/internal/config"
)

func TestValidateTranslationServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateTranslationServiceMTLSPort(config.Config{}, nil); err != nil {
		t.Fatalf("validateTranslationServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateTranslationServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateTranslationServiceMTLSPort(
		config.Config{HTTP: config.HTTPConfig{Port: 8094}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateTranslationServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateTranslationServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateTranslationServiceMTLSPort(
		config.Config{HTTP: config.HTTPConfig{Port: 8094, InternalTLSPort: 8094}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateTranslationServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestNewInternalTranslationMTLSServerUsesDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalTranslationMTLSServer(config.Config{
		HTTP: config.HTTPConfig{
			Port:            8094,
			InternalTLSPort: 9497,
			ReadTimeout:     2 * time.Second,
			WriteTimeout:    3 * time.Second,
			IdleTimeout:     4 * time.Second,
		},
	}, http.NewServeMux(), tlsConfig)

	if server == nil {
		t.Fatal("newInternalTranslationMTLSServer() = nil, want server")
	}
	if server.Addr != ":9497" {
		t.Fatalf("server addr = %q, want :9497", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
	if server.ReadTimeout != 2*time.Second || server.WriteTimeout != 3*time.Second || server.IdleTimeout != 4*time.Second {
		t.Fatalf("server timeouts = %s/%s/%s, want 2s/3s/4s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}

func TestNewServiceAuthJWKSHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newServiceAuthJWKSHTTPClient(config.Config{
		Security: config.SecurityConfig{
			ServiceAuthJWKSURL: "http://token-service:8081/.well-known/jwks.json",
		},
	})
	if err != nil {
		t.Fatalf("newServiceAuthJWKSHTTPClient() error = %v", err)
	}
	if client.Transport != nil {
		t.Fatalf("client transport = %#v, want nil default transport for disabled mTLS", client.Transport)
	}
}

func TestNewServiceAuthJWKSHTTPClientRequiresClientCertificateWhenMTLSEnforced(t *testing.T) {
	t.Parallel()

	_, err := newServiceAuthJWKSHTTPClient(config.Config{
		Security: config.SecurityConfig{
			ServiceAuthJWKSURL: "https://token-service:9481/.well-known/jwks.json",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newServiceAuthJWKSHTTPClient() error = nil, want missing client certificate error")
	}
	if !strings.Contains(err.Error(), "MTLS_CLIENT_CERT_PATH") {
		t.Fatalf("error = %q, want missing client certificate context", err)
	}
}

func TestNewServiceAuthJWKSHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newServiceAuthJWKSHTTPClient(config.Config{
		Security: config.SecurityConfig{
			ServiceAuthJWKSURL: "https://token-service:9481/.well-known/jwks.json",
		},
		MTLS: transportauth.EnvConfig{
			Mode:           "enforce",
			ClientCertPath: "/missing/client.crt",
			ClientKeyPath:  "/missing/client.key",
		},
	})
	if err == nil {
		t.Fatal("newServiceAuthJWKSHTTPClient() error = nil, want missing CA error")
	}
}

func TestTranslationServiceClientCertificateIsWiredInTestDeployment(t *testing.T) {
	t.Parallel()

	compose := readTestDeploymentFile(t, "../../../../infra/test/docker-compose.test.yml")
	translationService := textSection(t, compose, "\n  translation-service:\n", "\nnetworks:\n")
	for _, expected := range []string{
		"MTLS_CLIENT_CERT_PATH: /opt/inflap/secrets/mtls/translation-service/client.crt",
		"MTLS_CLIENT_KEY_PATH: /opt/inflap/secrets/mtls/translation-service/client.key",
		"\n      - egress\n",
	} {
		if !strings.Contains(translationService, expected) {
			t.Fatalf("translation-service test Compose config must contain %q", expected)
		}
	}
	tokenService := textSection(t, compose, "\n  token-service:\n", "\n  auth-service:\n")
	for _, expected := range []string{
		"spiffe://inflap/test/translation-service",
		"support-service,translation-service,user-service",
	} {
		if !strings.Contains(tokenService, expected) {
			t.Fatalf("token-service test mTLS allowlist must contain %q", expected)
		}
	}

	preflight := readTestDeploymentFile(t, "../../../../infra/test/scripts/preflight-mtls-certs.sh")
	clientServices := textSection(t, preflight, "client_services=(\n", ")\n\nseconds=")
	if !strings.Contains(clientServices, "\n  translation-service\n") {
		t.Fatal("mTLS preflight must validate the translation-service client certificate")
	}

	workflow := readTestDeploymentFile(t, "../../../../.github/workflows/deploy-test.yml")
	for _, expected := range []string{
		"MTLS_MODE='${MTLS_MODE}'",
		"MTLS_CERT_GROUP_ID='${MTLS_CERT_GROUP_ID}'",
		"MTLS_SECRETS_DIR='${MTLS_SECRETS_DIR}'",
		"MTLS_CA_CERT_PATH='${MTLS_CA_CERT_PATH}'",
	} {
		if !strings.Contains(workflow, expected) {
			t.Fatalf("deploy workflow must require %q", expected)
		}
	}
}

func readTestDeploymentFile(t *testing.T, path string) string {
	t.Helper()

	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read deployment file %s: %v", path, err)
	}
	return string(content)
}

func textSection(t *testing.T, content string, startMarker string, endMarker string) string {
	t.Helper()

	start := strings.Index(content, startMarker)
	if start < 0 {
		t.Fatalf("deployment section start %q was not found", startMarker)
	}
	start += len(startMarker)
	end := strings.Index(content[start:], endMarker)
	if end < 0 {
		t.Fatalf("deployment section end %q was not found", endMarker)
	}
	return content[start : start+end]
}
