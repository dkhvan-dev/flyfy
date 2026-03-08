package app_test

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"testing"

	"github.com/go-jose/go-jose/v4"
	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"github.com/dkhvan-dev/flyfy/token-service/internal/app"
	"github.com/dkhvan-dev/flyfy/token-service/internal/config"
	"github.com/dkhvan-dev/flyfy/token-service/internal/domain/model"
)

// --- Mock implementations ---

type mockKeyStore struct {
	keyID string
	key   *rsa.PrivateKey
}

func newMockKeyStore(t *testing.T) *mockKeyStore {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("generating RSA key: %v", err)
	}
	return &mockKeyStore{keyID: "test-key-1", key: key}
}

func (m *mockKeyStore) GetActiveKey(_ context.Context) (string, *rsa.PrivateKey, error) {
	return m.keyID, m.key, nil
}

func (m *mockKeyStore) GetPublicKeys(_ context.Context) ([]jose.JSONWebKey, error) {
	return []jose.JSONWebKey{{
		Key:       &m.key.PublicKey,
		KeyID:     m.keyID,
		Algorithm: string(jose.RS256),
		Use:       "sig",
	}}, nil
}

func (m *mockKeyStore) StoreKey(_ context.Context, keyID string, key *rsa.PrivateKey) error {
	m.keyID = keyID
	m.key = key
	return nil
}

func (m *mockKeyStore) DeactivateKey(_ context.Context, _ string) error { return nil }
func (m *mockKeyStore) DeleteExpiredKeys(_ context.Context, _ int) error { return nil }

type mockRevocationStore struct {
	revoked map[string]bool
}

func newMockRevocationStore() *mockRevocationStore {
	return &mockRevocationStore{revoked: make(map[string]bool)}
}

func (m *mockRevocationStore) Add(_ context.Context, jti string, _ int64) error {
	m.revoked[jti] = true
	return nil
}

func (m *mockRevocationStore) Exists(_ context.Context, jti string) (bool, error) {
	return m.revoked[jti], nil
}

type mockServiceAccountStore struct {
	accounts map[string]*model.ServiceAccount
}

func newMockServiceAccountStore() *mockServiceAccountStore {
	return &mockServiceAccountStore{
		accounts: map[string]*model.ServiceAccount{
			"auth-service": {
				ID:          uuid.New(),
				ServiceID:   "auth-service",
				SecretHash:  "hashed-secret",
				DisplayName: "Auth Service",
				IsActive:    true,
				Roles:       []string{"token:generate", "token:validate", "otp:send"},
			},
			"inactive-service": {
				ID:          uuid.New(),
				ServiceID:   "inactive-service",
				SecretHash:  "hashed-secret",
				DisplayName: "Inactive Service",
				IsActive:    false,
				Roles:       []string{"token:validate"},
			},
		},
	}
}

func (m *mockServiceAccountStore) GetByServiceID(_ context.Context, serviceID string) (*model.ServiceAccount, error) {
	acc, ok := m.accounts[serviceID]
	if !ok {
		return nil, model.ErrServiceNotFound
	}
	return acc, nil
}

func (m *mockServiceAccountStore) GetRoles(_ context.Context, accountID string) ([]string, error) {
	for _, acc := range m.accounts {
		if acc.ID.String() == accountID {
			return acc.Roles, nil
		}
	}
	return nil, nil
}

type mockPasswordVerifier struct{}

func (m *mockPasswordVerifier) Verify(hash, plaintext string) bool {
	// For tests: "hashed-secret" matches "correct-secret"
	return hash == "hashed-secret" && plaintext == "correct-secret"
}

func (m *mockPasswordVerifier) Hash(plaintext string) (string, error) {
	return "hashed-" + plaintext, nil
}

type mockAuditLogger struct {
	events []string
}

func (m *mockAuditLogger) LogServiceAuth(_ context.Context, callerID, action, result string, _ map[string]string) {
	m.events = append(m.events, callerID+":"+action+":"+result)
}

// --- Test setup ---

func setupUseCase(t *testing.T) (*app.TokenUseCase, *mockKeyStore, *mockRevocationStore, *mockAuditLogger) {
	t.Helper()
	keyStore := newMockKeyStore(t)
	revStore := newMockRevocationStore()
	svcStore := newMockServiceAccountStore()
	pwVerifier := &mockPasswordVerifier{}
	audit := &mockAuditLogger{}
	logger := zerolog.Nop()

	cfg := config.JWTConfig{
		Issuer:              "test-issuer",
		AccessTokenTTL:      900_000_000_000,  // 15 min in ns
		RefreshTokenTTL:     2_592_000_000_000_000, // 30 days in ns
		ServiceTokenTTL:     3_600_000_000_000, // 1h in ns
		RSAKeySize:          2048,
		MaxKeysInJWKS:       3,
	}

	uc := app.NewTokenUseCase(cfg, keyStore, revStore, svcStore, pwVerifier, audit, logger)
	return uc, keyStore, revStore, audit
}

// --- Tests ---

func TestGenerateUserTokens(t *testing.T) {
	uc, _, _, _ := setupUseCase(t)
	ctx := context.Background()

	pair, err := uc.GenerateUserTokens(ctx, model.UserClaims{
		UserID:      uuid.New(),
		Type:        model.TokenTypeUser,
		Role:        model.RoleTourist,
		Permissions: []string{"profile:read", "activities:join"},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if pair.AccessToken == "" {
		t.Error("access token is empty")
	}
	if pair.RefreshToken == "" {
		t.Error("refresh token is empty")
	}
	if pair.TokenType != "Bearer" {
		t.Errorf("expected token type 'Bearer', got %q", pair.TokenType)
	}
	if pair.ExpiresAt.IsZero() {
		t.Error("expires_at is zero")
	}
}

func TestValidateAccessToken(t *testing.T) {
	uc, _, _, _ := setupUseCase(t)
	ctx := context.Background()
	userID := uuid.New()

	// Generate
	pair, err := uc.GenerateUserTokens(ctx, model.UserClaims{
		UserID:      userID,
		Type:        model.TokenTypeUser,
		Role:        model.RoleGuide,
		Permissions: []string{"guide:manage"},
	})
	if err != nil {
		t.Fatalf("generate: %v", err)
	}

	// Validate
	claims, err := uc.ValidateAccessToken(ctx, pair.AccessToken)
	if err != nil {
		t.Fatalf("validate: %v", err)
	}

	if claims.Subject != userID.String() {
		t.Errorf("subject: got %q, want %q", claims.Subject, userID.String())
	}
	if claims.Type != model.TokenTypeUser {
		t.Errorf("type: got %q, want %q", claims.Type, model.TokenTypeUser)
	}
	if claims.Role != "guide" {
		t.Errorf("role: got %q, want 'guide'", claims.Role)
	}
}

func TestValidateAccessToken_RejectsRefreshToken(t *testing.T) {
	uc, _, _, _ := setupUseCase(t)
	ctx := context.Background()

	pair, _ := uc.GenerateUserTokens(ctx, model.UserClaims{
		UserID: uuid.New(),
		Type:   model.TokenTypeUser,
		Role:   model.RoleTourist,
	})

	// Try to validate refresh token as access token — should fail
	_, err := uc.ValidateAccessToken(ctx, pair.RefreshToken)
	if err != model.ErrTokenInvalid {
		t.Errorf("expected ErrTokenInvalid, got %v", err)
	}
}

func TestRevokeToken(t *testing.T) {
	uc, _, _, _ := setupUseCase(t)
	ctx := context.Background()
	userID := uuid.New()

	pair, _ := uc.GenerateUserTokens(ctx, model.UserClaims{
		UserID: userID,
		Type:   model.TokenTypeUser,
		Role:   model.RoleTourist,
	})

	// Validate first — should work
	claims, err := uc.ValidateAccessToken(ctx, pair.AccessToken)
	if err != nil {
		t.Fatalf("first validation failed: %v", err)
	}

	// Revoke
	if err := uc.Revoke(ctx, claims.JTI, claims.ExpiresAt.Unix(), "test_logout"); err != nil {
		t.Fatalf("revoke: %v", err)
	}

	// Validate again — should be revoked
	_, err = uc.ValidateAccessToken(ctx, pair.AccessToken)
	if err != model.ErrTokenRevoked {
		t.Errorf("expected ErrTokenRevoked, got %v", err)
	}
}

func TestGenerateServiceToken(t *testing.T) {
	uc, _, _, _ := setupUseCase(t)
	ctx := context.Background()

	svcToken, err := uc.GenerateServiceToken(ctx, model.ServiceClaims{
		ServiceID: "auth-service",
		Type:      model.TokenTypeService,
		Roles:     []string{"otp:send", "token:generate"},
	})
	if err != nil {
		t.Fatalf("generate service token: %v", err)
	}

	if svcToken.Token == "" {
		t.Error("service token is empty")
	}

	// Validate
	claims, err := uc.ValidateServiceToken(ctx, svcToken.Token)
	if err != nil {
		t.Fatalf("validate service token: %v", err)
	}

	if claims.Subject != "auth-service" {
		t.Errorf("subject: got %q, want 'auth-service'", claims.Subject)
	}
	if claims.Type != model.TokenTypeService {
		t.Errorf("type: got %q, want 'service'", claims.Type)
	}
	if len(claims.Roles) != 2 {
		t.Errorf("roles count: got %d, want 2", len(claims.Roles))
	}
}

func TestAuthenticateService_Success(t *testing.T) {
	uc, _, _, audit := setupUseCase(t)
	ctx := context.Background()

	token, err := uc.AuthenticateService(ctx, "auth-service", "correct-secret")
	if err != nil {
		t.Fatalf("authenticate: %v", err)
	}

	if token.Token == "" {
		t.Error("token is empty")
	}

	// Verify audit log
	found := false
	for _, e := range audit.events {
		if e == "auth-service:authenticate:granted" {
			found = true
		}
	}
	if !found {
		t.Errorf("expected audit event 'auth-service:authenticate:granted', got %v", audit.events)
	}
}

func TestAuthenticateService_BadCredentials(t *testing.T) {
	uc, _, _, _ := setupUseCase(t)
	ctx := context.Background()

	_, err := uc.AuthenticateService(ctx, "auth-service", "wrong-secret")
	if err != model.ErrInvalidCredentials {
		t.Errorf("expected ErrInvalidCredentials, got %v", err)
	}
}

func TestAuthenticateService_NotFound(t *testing.T) {
	uc, _, _, _ := setupUseCase(t)
	ctx := context.Background()

	_, err := uc.AuthenticateService(ctx, "nonexistent-service", "any-secret")
	if err != model.ErrServiceNotFound {
		t.Errorf("expected ErrServiceNotFound, got %v", err)
	}
}

func TestAuthenticateService_Inactive(t *testing.T) {
	uc, _, _, _ := setupUseCase(t)
	ctx := context.Background()

	_, err := uc.AuthenticateService(ctx, "inactive-service", "correct-secret")
	if err != model.ErrServiceInactive {
		t.Errorf("expected ErrServiceInactive, got %v", err)
	}
}

func TestKeyRotation(t *testing.T) {
	uc, keyStore, _, _ := setupUseCase(t)
	ctx := context.Background()

	oldKeyID, _, _ := keyStore.GetActiveKey(ctx)

	// Rotate keys
	if err := uc.RotateKeys(ctx); err != nil {
		t.Fatalf("rotate keys: %v", err)
	}

	newKeyID, _, _ := keyStore.GetActiveKey(ctx)
	if newKeyID == oldKeyID {
		t.Error("key ID should have changed after rotation")
	}

	// Old tokens should still validate (old public key is still in JWKS)
	pair, _ := uc.GenerateUserTokens(ctx, model.UserClaims{
		UserID: uuid.New(),
		Type:   model.TokenTypeUser,
		Role:   model.RoleTourist,
	})

	_, err := uc.ValidateAccessToken(ctx, pair.AccessToken)
	if err != nil {
		t.Errorf("token should validate after key rotation: %v", err)
	}
}

func TestGetJWKS(t *testing.T) {
	uc, _, _, _ := setupUseCase(t)
	ctx := context.Background()

	jwks, err := uc.GetJWKS(ctx)
	if err != nil {
		t.Fatalf("get JWKS: %v", err)
	}

	if len(jwks.Keys) == 0 {
		t.Error("JWKS should have at least one key")
	}

	for _, key := range jwks.Keys {
		if key.Algorithm != string(jose.RS256) {
			t.Errorf("expected RS256, got %s", key.Algorithm)
		}
		if key.Use != "sig" {
			t.Errorf("expected use=sig, got %s", key.Use)
		}
	}
}

func TestValidateToken_InvalidSignature(t *testing.T) {
	uc, _, _, _ := setupUseCase(t)
	ctx := context.Background()

	_, err := uc.ValidateAccessToken(ctx, "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ0ZXN0In0.invalid-sig")
	if err == nil {
		t.Error("expected error for invalid token")
	}
}

func TestValidateToken_Malformed(t *testing.T) {
	uc, _, _, _ := setupUseCase(t)
	ctx := context.Background()

	_, err := uc.ValidateAccessToken(ctx, "not-a-jwt")
	if err != model.ErrTokenMalformed {
		t.Errorf("expected ErrTokenMalformed, got %v", err)
	}
}