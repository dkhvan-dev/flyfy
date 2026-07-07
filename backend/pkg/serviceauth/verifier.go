package serviceauth

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/go-jose/go-jose/v4"
	josejwt "github.com/go-jose/go-jose/v4/jwt"
)

const (
	tokenTypeService = "service"
	tokenKindService = "service"
)

type VerifierConfig struct {
	Issuer   string
	JWKSURL  string
	CacheTTL time.Duration
	Client   *http.Client
}

type Claims struct {
	Subject     string
	Type        string
	Role        string
	Roles       []string
	Permissions []string
	JTI         string
	IssuedAt    time.Time
	ExpiresAt   time.Time
}

type JWTVerifier struct {
	issuer   string
	jwksURL  string
	cacheTTL time.Duration
	client   *http.Client

	mu        sync.RWMutex
	cached    *jose.JSONWebKeySet
	expiresAt time.Time
}

type customClaims struct {
	Type        string   `json:"type"`
	Role        string   `json:"role,omitempty"`
	Roles       []string `json:"roles,omitempty"`
	Permissions []string `json:"permissions,omitempty"`
	TokenKind   string   `json:"kind"`
}

func NewJWTVerifier(cfg VerifierConfig) (*JWTVerifier, error) {
	issuer := strings.TrimSpace(cfg.Issuer)
	if issuer == "" {
		return nil, fmt.Errorf("serviceauth verifier issuer is required")
	}
	jwksURL := strings.TrimSpace(cfg.JWKSURL)
	if jwksURL == "" {
		return nil, fmt.Errorf("serviceauth verifier JWKS URL is required")
	}
	cacheTTL := cfg.CacheTTL
	if cacheTTL <= 0 {
		cacheTTL = 5 * time.Minute
	}
	client := cfg.Client
	if client == nil {
		client = &http.Client{Timeout: 3 * time.Second}
	}
	return &JWTVerifier{
		issuer:   issuer,
		jwksURL:  jwksURL,
		cacheTTL: cacheTTL,
		client:   client,
	}, nil
}

func (v *JWTVerifier) ValidateBearer(ctx context.Context, authHeader string, requiredRoles []string) (*Claims, error) {
	token, err := ExtractBearerToken(authHeader)
	if err != nil {
		return nil, err
	}
	return v.ValidateServiceToken(ctx, token, requiredRoles)
}

func (v *JWTVerifier) ValidateServiceToken(ctx context.Context, token string, requiredRoles []string) (*Claims, error) {
	if v == nil {
		return nil, fmt.Errorf("serviceauth verifier is nil")
	}
	token = strings.TrimSpace(token)
	if token == "" {
		return nil, ErrMissingBearerToken
	}

	signed, err := josejwt.ParseSigned(token, []jose.SignatureAlgorithm{jose.RS256})
	if err != nil {
		return nil, fmt.Errorf("%w: parse signed jwt", ErrInvalidBearerToken)
	}

	jwks, err := v.getJWKS(ctx)
	if err != nil {
		return nil, err
	}

	var stdClaims josejwt.Claims
	var custom customClaims
	verified := false
	for _, key := range jwks.Keys {
		if err := signed.Claims(key.Key, &stdClaims, &custom); err == nil {
			verified = true
			break
		}
	}
	if !verified {
		return nil, fmt.Errorf("%w: signature verification failed", ErrInvalidServiceJWT)
	}

	if err := stdClaims.Validate(josejwt.Expected{Issuer: v.issuer, Time: time.Now()}); err != nil {
		return nil, fmt.Errorf("%w: claims validation failed", ErrInvalidServiceJWT)
	}
	if custom.Type != tokenTypeService || custom.TokenKind != tokenKindService {
		return nil, fmt.Errorf("%w: expected service token", ErrForbiddenService)
	}
	if !hasAllRoles(custom.Roles, requiredRoles) {
		return nil, fmt.Errorf("%w: missing service role", ErrForbiddenService)
	}

	return &Claims{
		Subject:     stdClaims.Subject,
		Type:        custom.Type,
		Role:        custom.Role,
		Roles:       append([]string(nil), custom.Roles...),
		Permissions: append([]string(nil), custom.Permissions...),
		JTI:         stdClaims.ID,
		IssuedAt:    stdClaims.IssuedAt.Time(),
		ExpiresAt:   stdClaims.Expiry.Time(),
	}, nil
}

func ExtractBearerToken(authHeader string) (string, error) {
	authHeader = strings.TrimSpace(authHeader)
	if authHeader == "" {
		return "", ErrMissingBearerToken
	}
	const prefix = "Bearer "
	if len(authHeader) < len(prefix) || !strings.EqualFold(authHeader[:len(prefix)], prefix) {
		return "", fmt.Errorf("%w: expected Authorization: Bearer <token>", ErrInvalidBearerToken)
	}
	token := strings.TrimSpace(authHeader[len(prefix):])
	if token == "" {
		return "", ErrMissingBearerToken
	}
	return token, nil
}

func (v *JWTVerifier) getJWKS(ctx context.Context) (*jose.JSONWebKeySet, error) {
	now := time.Now()

	v.mu.RLock()
	cached := v.cached
	expiresAt := v.expiresAt
	v.mu.RUnlock()
	if cached != nil && now.Before(expiresAt) {
		return cached, nil
	}

	v.mu.Lock()
	defer v.mu.Unlock()
	if v.cached != nil && now.Before(v.expiresAt) {
		return v.cached, nil
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, v.jwksURL, nil)
	if err != nil {
		return nil, fmt.Errorf("build JWKS request: %w", err)
	}
	resp, err := v.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("fetch JWKS: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return nil, fmt.Errorf("fetch JWKS: status %d", resp.StatusCode)
	}

	var jwks jose.JSONWebKeySet
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return nil, fmt.Errorf("decode JWKS: %w", err)
	}
	if len(jwks.Keys) == 0 {
		return nil, fmt.Errorf("decode JWKS: no keys")
	}

	v.cached = &jwks
	v.expiresAt = now.Add(v.cacheTTL)
	return v.cached, nil
}

func hasAllRoles(actual []string, required []string) bool {
	if len(required) == 0 {
		return true
	}
	roleSet := make(map[string]struct{}, len(actual))
	for _, role := range actual {
		role = strings.TrimSpace(role)
		if role != "" {
			roleSet[role] = struct{}{}
		}
	}
	for _, role := range required {
		role = strings.TrimSpace(role)
		if role == "" {
			continue
		}
		if _, ok := roleSet[role]; !ok {
			return false
		}
	}
	return true
}
