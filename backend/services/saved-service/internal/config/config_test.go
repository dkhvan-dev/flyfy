package config

import (
	"context"
	"encoding/base64"
	"fmt"
	"strings"
	"testing"
	"time"
)

func TestLoadUsesSavedServiceDefaults(t *testing.T) {
	t.Setenv("APP_NAME", "saved-service")
	t.Setenv("APP_ENV", "development")
	t.Setenv("POSTGRES_PASSWORD", "test-only-password")
	t.Setenv("MTLS_MODE", "disabled")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "0")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if cfg.App.Name != "saved-service" {
		t.Fatalf("APP_NAME = %q, want saved-service", cfg.App.Name)
	}
	if cfg.HTTP.Port != 8102 {
		t.Fatalf("HTTP_PORT = %d, want 8102", cfg.HTTP.Port)
	}
	if cfg.HTTP.ReadHeaderTimeout != 5*time.Second {
		t.Fatalf("HTTP_READ_HEADER_TIMEOUT = %s, want 5s", cfg.HTTP.ReadHeaderTimeout)
	}
	if cfg.HTTP.ReadinessTimeout != 2*time.Second {
		t.Fatalf("READINESS_TIMEOUT = %s, want 2s", cfg.HTTP.ReadinessTimeout)
	}
	if cfg.DB.MaxConns < cfg.DB.MinConns {
		t.Fatalf("invalid pool bounds: %+v", cfg.DB)
	}
	if cfg.TokenService.Target == "" || cfg.Sources.AttractionTarget == "" ||
		cfg.Sources.ActivityTarget == "" || cfg.Sources.UserTarget == "" ||
		cfg.Sources.PostTarget == "" ||
		cfg.UserAccess.BaseURL == "" || cfg.InternalAuth.ServiceToken.IsEmpty() {
		t.Fatal("development dependency defaults must be complete")
	}
	if cfg.Crypto.OperationCurrentKey().Version == 0 || cfg.Crypto.CursorCurrentKey().Version == 0 {
		t.Fatal("development crypto defaults must be usable")
	}
	if cfg.Limits.MaxActiveSaves != 10_000 || cfg.Limits.MaxActiveCollections != 200 {
		t.Fatalf("unexpected owner limits: %+v", cfg.Limits)
	}
	if cfg.NATS.URL != developmentNATSURL || cfg.NATS.StreamReplicas != 1 {
		t.Fatalf("unexpected development NATS config: %+v", cfg.NATS)
	}
	if !cfg.Features.SavedItemsEnabled || cfg.Features.SearchEnabled || cfg.Features.CollectionsEnabled {
		t.Fatalf("unexpected staged Saved product flags: %+v", cfg.Features)
	}
}

func TestLoadRejectsInsecureProductionDatabaseTransport(t *testing.T) {
	t.Setenv("APP_NAME", "saved-service")
	t.Setenv("APP_ENV", "production")
	t.Setenv("POSTGRES_PASSWORD", "test-only-password")
	t.Setenv("POSTGRES_SSLMODE", "disable")
	t.Setenv("MTLS_MODE", "disabled")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "0")

	_, err := Load(context.Background())
	if err == nil || !strings.Contains(err.Error(), "POSTGRES_SSLMODE must be verify-full") {
		t.Fatalf("Load() error = %v, want production SSL validation error", err)
	}
}

func TestLoadRejectsUnsafeMTLSListenerConfiguration(t *testing.T) {
	t.Setenv("APP_NAME", "saved-service")
	t.Setenv("APP_ENV", "development")
	t.Setenv("POSTGRES_PASSWORD", "test-only-password")
	t.Setenv("MTLS_MODE", "disabled")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9502")

	_, err := Load(context.Background())
	if err == nil || !strings.Contains(err.Error(), "requires MTLS_MODE=enforce") {
		t.Fatalf("Load() error = %v, want mTLS listener validation error", err)
	}
}

func TestLoadRequiresPostgresPassword(t *testing.T) {
	t.Setenv("APP_NAME", "saved-service")
	t.Setenv("APP_ENV", "development")
	t.Setenv("POSTGRES_PASSWORD", "")
	t.Setenv("MTLS_MODE", "disabled")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "0")

	_, err := Load(context.Background())
	if err == nil || !strings.Contains(err.Error(), "password") {
		t.Fatalf("Load() error = %v, want missing PostgreSQL password error", err)
	}
}

func TestDBConfigDSNEscapesCredentials(t *testing.T) {
	dsn := DBConfig{
		Host:     "saved-postgres",
		Port:     5432,
		User:     "saved@example",
		Password: "p@ss word",
		Database: "saved_service_db",
		SSLMode:  "verify-full",
	}.DSN()

	if !strings.Contains(dsn, "saved%40example:p%40ss%20word@") {
		t.Fatalf("DSN does not escape credentials: %s", dsn)
	}
	if !strings.Contains(dsn, "sslmode=verify-full") {
		t.Fatalf("DSN does not include SSL mode: %s", dsn)
	}
}

func TestLoadAcceptsExplicitSecureProductionConfig(t *testing.T) {
	setValidProductionEnvironment(t)

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if !cfg.App.IsSecureEnvironment() {
		t.Fatal("production config must be classified as secure")
	}
	if cfg.GatewayAuth.ExpectedSubject != GatewaySubject || cfg.GatewayAuth.RequiredRole != GatewayRole {
		t.Fatalf("unexpected Gateway identity: %+v", cfg.GatewayAuth)
	}
}

func TestLoadRejectsDisabledProductionMTLS(t *testing.T) {
	setValidProductionEnvironment(t)
	t.Setenv("MTLS_MODE", "disabled")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "0")

	_, err := Load(context.Background())
	if err == nil || !strings.Contains(err.Error(), "MTLS_MODE must be enforce") {
		t.Fatalf("Load() error = %v, want production mTLS rejection", err)
	}
}

func TestLoadRejectsInsecureDependencyURLs(t *testing.T) {
	setValidProductionEnvironment(t)
	t.Setenv("GATEWAY_AUTH_JWKS_URL", "http://token-service:8081/.well-known/jwks.json")
	t.Setenv("GATEWAY_AUTH_ALLOW_INSECURE_HTTP", "true")

	_, err := Load(context.Background())
	if err == nil || !strings.Contains(err.Error(), "plaintext HTTP") {
		t.Fatalf("Load() error = %v, want insecure URL rejection", err)
	}
}

func TestLoadRejectsUnsafeGRPCTarget(t *testing.T) {
	setValidProductionEnvironment(t)
	t.Setenv("ACTIVITY_SOURCE_GRPC_TARGET", "dns:///127.0.0.1:9096")

	_, err := Load(context.Background())
	if err == nil || !strings.Contains(err.Error(), "loopback") {
		t.Fatalf("Load() error = %v, want unsafe target rejection", err)
	}
}

func TestLoadRejectsEmptyProductionSecret(t *testing.T) {
	setValidProductionEnvironment(t)
	t.Setenv("TOKEN_SERVICE_SECRET", "")

	_, err := Load(context.Background())
	if err == nil || !strings.Contains(err.Error(), "TOKEN_SERVICE_SECRET") {
		t.Fatalf("Load() error = %v, want missing secret rejection", err)
	}
}

func TestLoadRejectsMalformedAndDuplicateCryptoKeysWithoutDisclosure(t *testing.T) {
	t.Run("malformed", func(t *testing.T) {
		setValidProductionEnvironment(t)
		malformed := "not-a-valid-secret-value"
		t.Setenv("OPERATION_HMAC_CURRENT_KEY_BASE64", malformed)

		_, err := Load(context.Background())
		if err == nil || !strings.Contains(err.Error(), "base64") {
			t.Fatalf("Load() error = %v, want malformed base64 rejection", err)
		}
		if strings.Contains(err.Error(), malformed) {
			t.Fatalf("configuration error disclosed key material: %v", err)
		}
	})

	t.Run("duplicate version", func(t *testing.T) {
		setValidProductionEnvironment(t)
		previous := encodedTestKey(91)
		t.Setenv("OPERATION_HMAC_PREVIOUS_KEYS", "7:"+previous)

		_, err := Load(context.Background())
		if err == nil || !strings.Contains(err.Error(), "versions must be unique") {
			t.Fatalf("Load() error = %v, want duplicate version rejection", err)
		}
		if strings.Contains(err.Error(), previous) {
			t.Fatalf("configuration error disclosed key material: %v", err)
		}
	})

	t.Run("duplicate material", func(t *testing.T) {
		setValidProductionEnvironment(t)
		current := encodedTestKey(11)
		t.Setenv("OPERATION_HMAC_CURRENT_KEY_BASE64", current)
		t.Setenv("OPERATION_HMAC_PREVIOUS_KEYS", "6:"+current)

		_, err := Load(context.Background())
		if err == nil || !strings.Contains(err.Error(), "material must be unique") {
			t.Fatalf("Load() error = %v, want duplicate material rejection", err)
		}
		if strings.Contains(err.Error(), current) {
			t.Fatalf("configuration error disclosed key material: %v", err)
		}
	})
}

func TestConfigurationFormattingRedactsSecrets(t *testing.T) {
	setValidProductionEnvironment(t)
	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	formatted := fmt.Sprintf("%+v | %#v | %+v | %+v | %+v | %+v",
		cfg,
		cfg,
		cfg.Crypto,
		cfg.InternalAuth,
		cfg.PlatformPolicy,
		cfg.NATS,
	)
	for _, secret := range []string{
		"production-postgres-password",
		"production-saved-service-token-secret",
		"production-internal-service-token-value",
		"production-platform-policy-token-value",
		encodedTestKey(11),
		encodedTestKey(53),
		"/run/secrets/saved-nats.creds",
		"tls://nats.internal:4222",
	} {
		if strings.Contains(formatted, secret) {
			t.Fatalf("formatted configuration disclosed a secret: %s", formatted)
		}
	}
}

func setValidProductionEnvironment(t *testing.T) {
	t.Helper()
	t.Setenv("APP_NAME", "saved-service")
	t.Setenv("APP_ENV", "production")
	t.Setenv("SAVED_PUBLIC_API_ORIGIN", "https://api.inflap.example")
	t.Setenv("POSTGRES_PASSWORD", "production-postgres-password")
	t.Setenv("POSTGRES_SSLMODE", "verify-full")
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9442")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/secrets/ca.crt")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/secrets/saved-server.crt")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/secrets/saved-server.key")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/secrets/saved-client.crt")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/secrets/saved-client.key")
	t.Setenv("MTLS_MIN_VERSION", "1.3")
	t.Setenv("TOKEN_SERVICE_GRPC_TARGET", "dns:///token-service:50051")
	t.Setenv("TOKEN_SERVICE_TLS_SERVER_NAME", "token-service")
	t.Setenv("TOKEN_SERVICE_SECRET", "production-saved-service-token-secret")
	t.Setenv("GATEWAY_AUTH_ISSUER", "tourism-inflap/token-service")
	t.Setenv("GATEWAY_AUTH_JWKS_URL", "https://token-service:8443/.well-known/jwks.json")
	t.Setenv("GATEWAY_AUTH_ALLOW_INSECURE_HTTP", "false")
	t.Setenv("ATTRACTION_SOURCE_GRPC_TARGET", "dns:///place-service:9449")
	t.Setenv("ATTRACTION_SOURCE_TLS_SERVER_NAME", "place-service")
	t.Setenv("ACTIVITY_SOURCE_GRPC_TARGET", "dns:///activity-service:9446")
	t.Setenv("ACTIVITY_SOURCE_TLS_SERVER_NAME", "activity-service")
	t.Setenv("USER_SOURCE_GRPC_TARGET", "dns:///user-service:9444")
	t.Setenv("USER_SOURCE_TLS_SERVER_NAME", "user-service")
	t.Setenv("POST_SOURCE_GRPC_TARGET", "dns:///feed-service:9448")
	t.Setenv("POST_SOURCE_TLS_SERVER_NAME", "feed-service")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "production-internal-service-token-value")
	t.Setenv("CHAT_SERVICE_INTERNAL_HTTP_URL", "https://chat-service:9488")
	t.Setenv("USER_ACCESS_ALLOW_INSECURE_HTTP", "false")
	t.Setenv("PLATFORM_POLICY_BASE_URL", "https://switches-service:9440")
	t.Setenv("PLATFORM_POLICY_INTERNAL_SERVICE_TOKEN", "production-platform-policy-token-value")
	t.Setenv("PLATFORM_POLICY_ALLOW_INSECURE_HTTP", "false")
	t.Setenv("NATS_URL", "tls://nats.internal:4222")
	t.Setenv("NATS_CREDENTIALS_FILE", "/run/secrets/saved-nats.creds")
	t.Setenv("NATS_CA_CERT_PATH", "/run/secrets/nats-ca.crt")
	t.Setenv("NATS_CLIENT_CERT_PATH", "/run/secrets/saved-nats.crt")
	t.Setenv("NATS_CLIENT_KEY_PATH", "/run/secrets/saved-nats.key")
	t.Setenv("NATS_TLS_SERVER_NAME", "nats.internal")
	t.Setenv("SAVED_DOMAIN_STREAM_REPLICAS", "3")
	t.Setenv("SAVED_COMPLIANCE_ALLOWED_CALLER_SPIFFE_ID", "spiffe://inflap/production/user-service")
	t.Setenv("OPERATION_HMAC_CURRENT_VERSION", "7")
	t.Setenv("OPERATION_HMAC_CURRENT_KEY_BASE64", encodedTestKey(11))
	t.Setenv("OPERATION_HMAC_PREVIOUS_KEYS", "")
	t.Setenv("CURSOR_ACTIVE_KEY_ID", "9")
	t.Setenv("CURSOR_ACTIVE_KEY_BASE64", encodedTestKey(53))
	t.Setenv("CURSOR_PREVIOUS_KEYS", "")
}

func encodedTestKey(seed byte) string {
	key := make([]byte, 32)
	for index := range key {
		key[index] = seed + byte(index)
	}
	return base64.StdEncoding.EncodeToString(key)
}
