package config

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/url"
	"strconv"
	"strings"
	"time"
	"unicode"

	"kz/inflap/backend/pkg/platformpolicy"
)

const (
	GatewaySubject = "api-gateway"
	GatewayRole    = "saved:proxy"

	developmentServiceSecret = "development-only-saved-service-secret"
	developmentPolicyToken   = "development-only-platform-policy-token"
	developmentInternalToken = "development-only-internal-service-token"
)

type SecretValue struct {
	value string
}

func (secret *SecretValue) EnvDecode(_ context.Context, value string) error {
	if secret == nil {
		return errors.New("secret destination is unavailable")
	}
	secret.value = value
	return nil
}

func NewSecretValue(value string) SecretValue {
	return SecretValue{value: value}
}

func (secret SecretValue) Value() string {
	return secret.value
}

func (secret SecretValue) IsEmpty() bool {
	return secret.value == ""
}

func (SecretValue) String() string {
	return "[redacted]"
}

func (secret SecretValue) GoString() string {
	return secret.String()
}

type TokenServiceConfig struct {
	Target        string        `env:"TOKEN_SERVICE_GRPC_TARGET, default="`
	ServerName    string        `env:"TOKEN_SERVICE_TLS_SERVER_NAME, default="`
	ServiceID     string        `env:"TOKEN_SERVICE_ID, default=saved-service"`
	ServiceSecret SecretValue   `env:"TOKEN_SERVICE_SECRET, default="`
	CallTimeout   time.Duration `env:"TOKEN_SERVICE_CALL_TIMEOUT, default=2s"`
	RefreshBefore time.Duration `env:"TOKEN_SERVICE_REFRESH_BEFORE, default=5m"`
}

func (TokenServiceConfig) String() string {
	return "TokenServiceConfig{secret=redacted}"
}

func (cfg TokenServiceConfig) GoString() string {
	return cfg.String()
}

type GatewayAuthConfig struct {
	Issuer            string        `env:"GATEWAY_AUTH_ISSUER, default="`
	JWKSURL           string        `env:"GATEWAY_AUTH_JWKS_URL, default="`
	ExpectedSubject   string        `env:"GATEWAY_AUTH_EXPECTED_SUBJECT, default=api-gateway"`
	RequiredRole      string        `env:"GATEWAY_AUTH_REQUIRED_ROLE, default=saved:proxy"`
	JWKSCacheTTL      time.Duration `env:"GATEWAY_AUTH_JWKS_CACHE_TTL, default=5m"`
	HTTPTimeout       time.Duration `env:"GATEWAY_AUTH_HTTP_TIMEOUT, default=2s"`
	AllowInsecureHTTP bool          `env:"GATEWAY_AUTH_ALLOW_INSECURE_HTTP, default=false"`
}

type SourceConfig struct {
	AttractionTarget     string `env:"ATTRACTION_SOURCE_GRPC_TARGET, default="`
	AttractionServerName string `env:"ATTRACTION_SOURCE_TLS_SERVER_NAME, default="`
	ActivityTarget       string `env:"ACTIVITY_SOURCE_GRPC_TARGET, default="`
	ActivityServerName   string `env:"ACTIVITY_SOURCE_TLS_SERVER_NAME, default="`
	UserTarget           string `env:"USER_SOURCE_GRPC_TARGET, default="`
	UserServerName       string `env:"USER_SOURCE_TLS_SERVER_NAME, default="`
	PostTarget           string `env:"POST_SOURCE_GRPC_TARGET, default="`
	PostServerName       string `env:"POST_SOURCE_TLS_SERVER_NAME, default="`
}

type InternalAuthConfig struct {
	ServiceToken SecretValue `env:"INTERNAL_SERVICE_TOKEN, default="`
}

func (InternalAuthConfig) String() string {
	return "InternalAuthConfig{token=redacted}"
}

func (cfg InternalAuthConfig) GoString() string {
	return cfg.String()
}

type UserAccessConfig struct {
	BaseURL           string        `env:"CHAT_SERVICE_INTERNAL_HTTP_URL, default="`
	HTTPTimeout       time.Duration `env:"USER_ACCESS_HTTP_TIMEOUT, default=750ms"`
	MaxResponseBytes  int64         `env:"USER_ACCESS_MAX_RESPONSE_BYTES, default=16384"`
	AllowInsecureHTTP bool          `env:"USER_ACCESS_ALLOW_INSECURE_HTTP, default=false"`
}

type PlatformPolicyConfig struct {
	BaseURL              string        `env:"PLATFORM_POLICY_BASE_URL, default="`
	InternalServiceToken SecretValue   `env:"PLATFORM_POLICY_INTERNAL_SERVICE_TOKEN, default="`
	HTTPTimeout          time.Duration `env:"PLATFORM_POLICY_HTTP_TIMEOUT, default=750ms"`
	RefreshTimeout       time.Duration `env:"PLATFORM_POLICY_REFRESH_TIMEOUT, default=1s"`
	MaxResponseBytes     int64         `env:"PLATFORM_POLICY_MAX_RESPONSE_BYTES, default=4096"`
	AllowInsecureHTTP    bool          `env:"PLATFORM_POLICY_ALLOW_INSECURE_HTTP, default=false"`
}

func (PlatformPolicyConfig) String() string {
	return "PlatformPolicyConfig{token=redacted}"
}

func (cfg PlatformPolicyConfig) GoString() string {
	return cfg.String()
}

type DependencyTimeoutConfig struct {
	GRPCConnect time.Duration `env:"DEPENDENCY_GRPC_CONNECT_TIMEOUT, default=2s"`
	SourceRPC   time.Duration `env:"SOURCE_RPC_TIMEOUT, default=2s"`
	SessionRPC  time.Duration `env:"SESSION_RPC_TIMEOUT, default=2s"`
}

func (c *Config) applyDevelopmentDefaults() {
	if c == nil || !c.App.IsDevelopmentLike() {
		return
	}
	if c.TokenService.Target == "" {
		c.TokenService.Target = "dns:///token-service:50051"
	}
	if c.TokenService.ServerName == "" {
		c.TokenService.ServerName = "token-service"
	}
	if c.TokenService.ServiceSecret.IsEmpty() {
		c.TokenService.ServiceSecret = NewSecretValue(developmentServiceSecret)
	}
	if c.GatewayAuth.Issuer == "" {
		c.GatewayAuth.Issuer = "tourism-inflap/token-service"
	}
	if c.GatewayAuth.JWKSURL == "" {
		c.GatewayAuth.JWKSURL = "http://token-service:8081/.well-known/jwks.json"
		c.GatewayAuth.AllowInsecureHTTP = true
	}
	if c.Sources.AttractionTarget == "" {
		c.Sources.AttractionTarget = "dns:///place-service:9099"
	}
	if c.Sources.AttractionServerName == "" {
		c.Sources.AttractionServerName = "place-service"
	}
	if c.Sources.ActivityTarget == "" {
		c.Sources.ActivityTarget = "dns:///activity-service:9096"
	}
	if c.Sources.ActivityServerName == "" {
		c.Sources.ActivityServerName = "activity-service"
	}
	if c.Sources.UserTarget == "" {
		c.Sources.UserTarget = "dns:///user-service:9094"
	}
	if c.Sources.UserServerName == "" {
		c.Sources.UserServerName = "user-service"
	}
	if c.Sources.PostTarget == "" {
		c.Sources.PostTarget = "dns:///feed-service:9098"
	}
	if c.Sources.PostServerName == "" {
		c.Sources.PostServerName = "feed-service"
	}
	if c.InternalAuth.ServiceToken.IsEmpty() {
		c.InternalAuth.ServiceToken = NewSecretValue(developmentInternalToken)
	}
	if c.UserAccess.BaseURL == "" {
		c.UserAccess.BaseURL = "http://chat-service:8088"
		c.UserAccess.AllowInsecureHTTP = true
	}
	if c.PlatformPolicy.BaseURL == "" {
		c.PlatformPolicy.BaseURL = "http://switches-service:8096"
		c.PlatformPolicy.AllowInsecureHTTP = true
	}
	if c.PlatformPolicy.InternalServiceToken.IsEmpty() {
		c.PlatformPolicy.InternalServiceToken = NewSecretValue(developmentPolicyToken)
	}
	if c.NATS.URL == "" {
		c.NATS.URL = developmentNATSURL
	}
	c.Crypto.applyDevelopmentDefaults()
}

func validateDependencies(cfg Config) error {
	secureEnvironment := cfg.App.IsSecureEnvironment()

	if strings.TrimSpace(cfg.TokenService.ServiceID) != serviceName {
		return fmt.Errorf("TOKEN_SERVICE_ID must be %q", serviceName)
	}
	if err := validateSecret("TOKEN_SERVICE_SECRET", cfg.TokenService.ServiceSecret, secureEnvironment); err != nil {
		return err
	}
	if err := validateGRPCEndpoint(
		"TOKEN_SERVICE_GRPC_TARGET",
		cfg.TokenService.Target,
		cfg.TokenService.ServerName,
		secureEnvironment,
	); err != nil {
		return err
	}
	if cfg.TokenService.CallTimeout <= 0 || cfg.TokenService.CallTimeout > 5*time.Second {
		return fmt.Errorf("TOKEN_SERVICE_CALL_TIMEOUT must be within (0, 5s]")
	}
	if cfg.TokenService.RefreshBefore <= 0 || cfg.TokenService.RefreshBefore > 30*time.Minute {
		return fmt.Errorf("TOKEN_SERVICE_REFRESH_BEFORE must be within (0, 30m]")
	}

	if strings.TrimSpace(cfg.GatewayAuth.Issuer) == "" {
		return fmt.Errorf("GATEWAY_AUTH_ISSUER is required")
	}
	if cfg.GatewayAuth.Issuer != strings.TrimSpace(cfg.GatewayAuth.Issuer) ||
		len(cfg.GatewayAuth.Issuer) > 256 ||
		strings.IndexFunc(cfg.GatewayAuth.Issuer, unicode.IsControl) >= 0 {
		return fmt.Errorf("GATEWAY_AUTH_ISSUER is invalid")
	}
	if cfg.GatewayAuth.ExpectedSubject != GatewaySubject {
		return fmt.Errorf("GATEWAY_AUTH_EXPECTED_SUBJECT must be %q", GatewaySubject)
	}
	if cfg.GatewayAuth.RequiredRole != GatewayRole {
		return fmt.Errorf("GATEWAY_AUTH_REQUIRED_ROLE must be %q", GatewayRole)
	}
	if cfg.GatewayAuth.JWKSCacheTTL <= 0 || cfg.GatewayAuth.JWKSCacheTTL > time.Hour {
		return fmt.Errorf("GATEWAY_AUTH_JWKS_CACHE_TTL must be within (0, 1h]")
	}
	if cfg.GatewayAuth.HTTPTimeout <= 0 || cfg.GatewayAuth.HTTPTimeout > 5*time.Second {
		return fmt.Errorf("GATEWAY_AUTH_HTTP_TIMEOUT must be within (0, 5s]")
	}
	if _, err := validateHTTPURL(
		"GATEWAY_AUTH_JWKS_URL",
		cfg.GatewayAuth.JWKSURL,
		cfg.GatewayAuth.AllowInsecureHTTP,
		secureEnvironment,
		false,
	); err != nil {
		return err
	}

	sourceEndpoints := []struct {
		name       string
		target     string
		serverName string
	}{
		{name: "ATTRACTION_SOURCE_GRPC_TARGET", target: cfg.Sources.AttractionTarget, serverName: cfg.Sources.AttractionServerName},
		{name: "ACTIVITY_SOURCE_GRPC_TARGET", target: cfg.Sources.ActivityTarget, serverName: cfg.Sources.ActivityServerName},
		{name: "USER_SOURCE_GRPC_TARGET", target: cfg.Sources.UserTarget, serverName: cfg.Sources.UserServerName},
		{name: "POST_SOURCE_GRPC_TARGET", target: cfg.Sources.PostTarget, serverName: cfg.Sources.PostServerName},
	}

	if err := validateSecret("INTERNAL_SERVICE_TOKEN", cfg.InternalAuth.ServiceToken, secureEnvironment); err != nil {
		return err
	}
	if _, err := validateHTTPURL(
		"CHAT_SERVICE_INTERNAL_HTTP_URL",
		cfg.UserAccess.BaseURL,
		cfg.UserAccess.AllowInsecureHTTP,
		secureEnvironment,
		true,
	); err != nil {
		return err
	}
	if cfg.UserAccess.HTTPTimeout <= 0 || cfg.UserAccess.HTTPTimeout > 2*time.Second {
		return fmt.Errorf("USER_ACCESS_HTTP_TIMEOUT must be within (0, 2s]")
	}
	if cfg.UserAccess.MaxResponseBytes < 1 || cfg.UserAccess.MaxResponseBytes > 16*1024 {
		return fmt.Errorf("USER_ACCESS_MAX_RESPONSE_BYTES must be within [1, 16384]")
	}
	seenTargets := make(map[string]struct{}, len(sourceEndpoints))
	for _, endpoint := range sourceEndpoints {
		if err := validateGRPCEndpoint(endpoint.name, endpoint.target, endpoint.serverName, secureEnvironment); err != nil {
			return err
		}
		normalizedTarget := strings.ToLower(strings.TrimSpace(endpoint.target))
		if _, duplicate := seenTargets[normalizedTarget]; duplicate {
			return fmt.Errorf("Saved source gRPC targets must be unique")
		}
		seenTargets[normalizedTarget] = struct{}{}
	}

	if err := validateSecret(
		"PLATFORM_POLICY_INTERNAL_SERVICE_TOKEN",
		cfg.PlatformPolicy.InternalServiceToken,
		secureEnvironment,
	); err != nil {
		return err
	}
	if _, err := validateHTTPURL(
		"PLATFORM_POLICY_BASE_URL",
		cfg.PlatformPolicy.BaseURL,
		cfg.PlatformPolicy.AllowInsecureHTTP,
		secureEnvironment,
		true,
	); err != nil {
		return err
	}
	if cfg.PlatformPolicy.HTTPTimeout <= 0 || cfg.PlatformPolicy.HTTPTimeout > platformpolicy.MaximumHTTPTimeout {
		return fmt.Errorf("PLATFORM_POLICY_HTTP_TIMEOUT must be within (0, %s]", platformpolicy.MaximumHTTPTimeout)
	}
	if cfg.PlatformPolicy.RefreshTimeout <= 0 || cfg.PlatformPolicy.RefreshTimeout > platformpolicy.MaximumRefreshTimeout {
		return fmt.Errorf("PLATFORM_POLICY_REFRESH_TIMEOUT must be within (0, %s]", platformpolicy.MaximumRefreshTimeout)
	}
	if cfg.PlatformPolicy.HTTPTimeout >= cfg.PlatformPolicy.RefreshTimeout {
		return fmt.Errorf("PLATFORM_POLICY_HTTP_TIMEOUT must be shorter than PLATFORM_POLICY_REFRESH_TIMEOUT")
	}
	if cfg.PlatformPolicy.MaxResponseBytes < 1 || cfg.PlatformPolicy.MaxResponseBytes > platformpolicy.MaximumResponseBytes {
		return fmt.Errorf("PLATFORM_POLICY_MAX_RESPONSE_BYTES must be within [1, %d]", platformpolicy.MaximumResponseBytes)
	}

	if cfg.Dependencies.GRPCConnect <= 0 || cfg.Dependencies.GRPCConnect > 10*time.Second {
		return fmt.Errorf("DEPENDENCY_GRPC_CONNECT_TIMEOUT must be within (0, 10s]")
	}
	if cfg.Dependencies.SourceRPC <= 0 || cfg.Dependencies.SourceRPC > 2*time.Second {
		return fmt.Errorf("SOURCE_RPC_TIMEOUT must be within (0, 2s]")
	}
	if cfg.Dependencies.SessionRPC <= 0 || cfg.Dependencies.SessionRPC > 2*time.Second {
		return fmt.Errorf("SESSION_RPC_TIMEOUT must be within (0, 2s]")
	}

	return nil
}

func validateSecret(name string, secret SecretValue, secureEnvironment bool) error {
	value := secret.Value()
	if value == "" || value != strings.TrimSpace(value) || strings.IndexFunc(value, unicode.IsControl) >= 0 {
		return fmt.Errorf("%s must be a non-empty secret without surrounding whitespace or control characters", name)
	}
	if len(value) > 4096 {
		return fmt.Errorf("%s is too large", name)
	}
	minimumLength := 16
	if secureEnvironment {
		minimumLength = 32
	}
	if len(value) < minimumLength {
		return fmt.Errorf("%s is too short", name)
	}
	if secureEnvironment && (value == developmentServiceSecret || value == developmentPolicyToken ||
		value == developmentInternalToken || isPlaceholderSecret(value)) {
		return fmt.Errorf("%s must not use a development or placeholder value", name)
	}
	return nil
}

func isPlaceholderSecret(value string) bool {
	normalized := strings.ToLower(strings.TrimSpace(value))
	switch normalized {
	case "changeme", "change-me", "replace-me", "placeholder", "secret", "password":
		return true
	default:
		return strings.Contains(normalized, "your-secret") || strings.Contains(normalized, "replace_this")
	}
}

func validateGRPCEndpoint(name, rawTarget, serverName string, secureEnvironment bool) error {
	host, err := grpcTargetHost(rawTarget)
	if err != nil {
		return fmt.Errorf("%s must be a safe host:port or dns:///host:port target", name)
	}
	if secureEnvironment && isUnsafeProductionHost(host) {
		return fmt.Errorf("%s must not use a loopback or unspecified host in staging or production", name)
	}
	if err := validateTLSServerName(serverName, secureEnvironment); err != nil {
		return fmt.Errorf("%s TLS server name is invalid", name)
	}
	return nil
}

func grpcTargetHost(rawTarget string) (string, error) {
	target := strings.TrimSpace(rawTarget)
	if target == "" || target != rawTarget || strings.IndexFunc(target, unicode.IsControl) >= 0 {
		return "", errors.New("invalid gRPC target")
	}
	endpoint := target
	if strings.HasPrefix(strings.ToLower(target), "dns:///") {
		endpoint = target[len("dns:///"):]
	} else if strings.Contains(target, "://") {
		return "", errors.New("unsupported gRPC resolver scheme")
	}
	if strings.ContainsAny(endpoint, "/?#@") {
		return "", errors.New("invalid gRPC target suffix")
	}
	host, portText, err := net.SplitHostPort(endpoint)
	if err != nil || host == "" {
		return "", errors.New("invalid gRPC target authority")
	}
	port, err := strconv.Atoi(portText)
	if err != nil || !isValidPort(port) {
		return "", errors.New("invalid gRPC target port")
	}
	if host == "*" {
		return "", errors.New("wildcard gRPC target is forbidden")
	}
	return strings.Trim(host, "[]"), nil
}

func validateTLSServerName(serverName string, secureEnvironment bool) error {
	serverName = strings.TrimSpace(serverName)
	if serverName == "" || strings.IndexFunc(serverName, unicode.IsControl) >= 0 ||
		strings.ContainsAny(serverName, "/:@?#*") || len(serverName) > 253 {
		return errors.New("invalid TLS server name")
	}
	if secureEnvironment && isUnsafeProductionHost(serverName) {
		return errors.New("unsafe TLS server name")
	}
	if net.ParseIP(serverName) != nil {
		return nil
	}
	for _, label := range strings.Split(serverName, ".") {
		if label == "" || len(label) > 63 || label[0] == '-' || label[len(label)-1] == '-' {
			return errors.New("invalid DNS label")
		}
		for _, character := range label {
			if (character < 'a' || character > 'z') &&
				(character < 'A' || character > 'Z') &&
				(character < '0' || character > '9') && character != '-' {
				return errors.New("invalid DNS character")
			}
		}
	}
	return nil
}

func validateHTTPURL(
	name string,
	rawURL string,
	allowInsecureHTTP bool,
	secureEnvironment bool,
	requireOriginOnly bool,
) (*url.URL, error) {
	parsed, err := url.ParseRequestURI(strings.TrimSpace(rawURL))
	if err != nil || parsed == nil || !parsed.IsAbs() || parsed.Host == "" || parsed.Hostname() == "" {
		return nil, fmt.Errorf("%s must be an absolute HTTP(S) URL", name)
	}
	if parsed.User != nil || parsed.Fragment != "" || parsed.RawQuery != "" || parsed.ForceQuery {
		return nil, fmt.Errorf("%s must not contain user info, query, or fragment", name)
	}
	if requireOriginOnly && parsed.Path != "" && parsed.Path != "/" {
		return nil, fmt.Errorf("%s must be an origin without a path", name)
	}
	if !requireOriginOnly && (parsed.Path == "" || parsed.Path == "/") {
		return nil, fmt.Errorf("%s must include the JWKS path", name)
	}
	switch strings.ToLower(parsed.Scheme) {
	case "https":
		if allowInsecureHTTP && secureEnvironment {
			return nil, fmt.Errorf("%s forbids insecure HTTP opt-in in staging and production", name)
		}
	case "http":
		if secureEnvironment || !allowInsecureHTTP {
			return nil, fmt.Errorf("%s plaintext HTTP is limited to development/test with explicit opt-in", name)
		}
	default:
		return nil, fmt.Errorf("%s must use HTTP or HTTPS", name)
	}
	if secureEnvironment && isUnsafeProductionHost(parsed.Hostname()) {
		return nil, fmt.Errorf("%s must not use a loopback or unspecified host in staging or production", name)
	}
	return parsed, nil
}

func isUnsafeProductionHost(host string) bool {
	host = strings.Trim(strings.ToLower(strings.TrimSpace(host)), "[]")
	if host == "localhost" || strings.HasSuffix(host, ".localhost") {
		return true
	}
	if address := net.ParseIP(host); address != nil {
		return address.IsLoopback() || address.IsUnspecified() ||
			address.IsLinkLocalUnicast() || address.IsLinkLocalMulticast() || address.IsMulticast()
	}
	return false
}
