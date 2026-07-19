package app_test

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/go-jose/go-jose/v4"
	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"kz/inflap/backend/services/token-service/internal/app"
	"kz/inflap/backend/services/token-service/internal/config"
	"kz/inflap/backend/services/token-service/internal/domain/model"
	"kz/inflap/backend/services/token-service/internal/domain/port"
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

func (m *mockKeyStore) DeactivateKey(_ context.Context, _ string) error  { return nil }
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

type mockSessionRevocationNotifier struct {
	events []port.SessionRevocationNotification
}

func (m *mockSessionRevocationNotifier) NotifySessionRevoked(
	_ context.Context,
	event port.SessionRevocationNotification,
) error {
	m.events = append(m.events, event)
	return nil
}

// --- Session port mocks ---

type mockSessionStore struct {
	mu          sync.Mutex
	byID        map[uuid.UUID]*model.UserSession
	history     map[string]uuid.UUID
	validateErr error
}

func newMockSessionStore() *mockSessionStore {
	return &mockSessionStore{
		byID:    make(map[uuid.UUID]*model.UserSession),
		history: make(map[string]uuid.UUID),
	}
}

func (m *mockSessionStore) CreateActive(_ context.Context, sess *model.UserSession, reason string) (*model.UserSession, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	var replaced *model.UserSession
	for _, s := range m.byID {
		if s.UserID == sess.UserID && s.RevokedAt == nil {
			now := time.Now()
			s.RevokedAt = &now
			s.RevokeReason = reason
			cp := *s
			replaced = &cp
		}
	}
	cp := *sess
	m.byID[sess.ID] = &cp
	return replaced, nil
}

func (m *mockSessionStore) GetByID(_ context.Context, id uuid.UUID) (*model.UserSession, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	s, ok := m.byID[id]
	if !ok {
		return nil, model.ErrSessionNotFound
	}
	cp := *s
	return &cp, nil
}

func (m *mockSessionStore) GetActiveByUserID(_ context.Context, userID uuid.UUID) (*model.UserSession, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	for _, s := range m.byID {
		if s.UserID == userID && s.RevokedAt == nil {
			cp := *s
			return &cp, nil
		}
	}
	return nil, model.ErrSessionNotFound
}

func (m *mockSessionStore) GetActiveByRefreshJTI(_ context.Context, jti string) (*model.UserSession, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	for _, s := range m.byID {
		if s.RefreshJTI == jti && s.RevokedAt == nil {
			cp := *s
			return &cp, nil
		}
	}
	return nil, model.ErrSessionNotFound
}

func (m *mockSessionStore) IsCurrentSessionGeneration(
	_ context.Context,
	userID, generation uuid.UUID,
	now time.Time,
	inactivityTTL time.Duration,
) (bool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.validateErr != nil {
		return false, m.validateErr
	}

	activeCount := 0
	var candidate *model.UserSession
	for _, session := range m.byID {
		if session.UserID != userID || session.RevokedAt != nil {
			continue
		}
		activeCount++
		if session.ID == generation {
			candidate = session
		}
	}
	if activeCount != 1 || candidate == nil {
		return false, nil
	}
	if !candidate.RefreshExpiresAt.After(now) {
		return false, nil
	}
	if inactivityTTL > 0 && candidate.LastUsedAt.Before(now.Add(-inactivityTTL)) {
		return false, nil
	}
	return true, nil
}

func (m *mockSessionStore) RotateRefresh(_ context.Context, sessionID uuid.UUID, prev port.RotatePrev, next port.RotateNext) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	s, ok := m.byID[sessionID]
	if !ok || s.RevokedAt != nil || s.RefreshJTI != prev.RefreshJTI {
		return model.ErrSessionNotFound
	}
	m.history[prev.RefreshJTI] = sessionID
	s.RefreshJTI = next.RefreshJTI
	s.RefreshTokenHash = next.RefreshTokenHash
	s.RefreshIssuedAt = next.IssuedAt
	s.RefreshExpiresAt = next.ExpiresAt
	s.LastRefreshedAt = &next.RotatedAt
	s.LastUsedAt = next.RotatedAt
	return nil
}

func (m *mockSessionStore) Revoke(_ context.Context, id uuid.UUID, reason string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	s, ok := m.byID[id]
	if !ok || s.RevokedAt != nil {
		return nil
	}
	now := time.Now()
	s.RevokedAt = &now
	s.RevokeReason = reason
	return nil
}

func (m *mockSessionStore) RevokeAllForUser(_ context.Context, userID uuid.UUID, reason string) (int, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	n := 0
	for _, s := range m.byID {
		if s.UserID == userID && s.RevokedAt == nil {
			now := time.Now()
			s.RevokedAt = &now
			s.RevokeReason = reason
			n++
		}
	}
	return n, nil
}

func (m *mockSessionStore) TouchLastUsed(_ context.Context, id uuid.UUID, at time.Time) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if s, ok := m.byID[id]; ok && s.RevokedAt == nil {
		s.LastUsedAt = at
	}
	return nil
}

func (m *mockSessionStore) FindHistoricalRefreshJTI(_ context.Context, jti string) (uuid.UUID, bool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	id, ok := m.history[jti]
	return id, ok, nil
}

func (m *mockSessionStore) ListByUserID(_ context.Context, userID uuid.UUID, _ int) ([]*model.UserSession, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	var out []*model.UserSession
	for _, s := range m.byID {
		if s.UserID == userID {
			cp := *s
			out = append(out, &cp)
		}
	}
	return out, nil
}

type mockRevokedSessionCache struct {
	mu      sync.Mutex
	revoked map[uuid.UUID]bool
}

func newMockRevokedSessionCache() *mockRevokedSessionCache {
	return &mockRevokedSessionCache{revoked: make(map[uuid.UUID]bool)}
}

func (m *mockRevokedSessionCache) MarkRevoked(_ context.Context, id uuid.UUID, _ time.Duration) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.revoked[id] = true
	return nil
}

func (m *mockRevokedSessionCache) IsRevoked(_ context.Context, id uuid.UUID) (bool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.revoked[id], nil
}

type mockSessionAuditLogger struct{}

func (m *mockSessionAuditLogger) LogSessionEvent(_ context.Context, _ uuid.UUID, _ *uuid.UUID, _ string, _, _ string, _ map[string]string) {
}

// --- Test setup ---

type useCaseFixture struct {
	useCase      *app.TokenUseCase
	keyStore     *mockKeyStore
	revStore     *mockRevocationStore
	sessionStore *mockSessionStore
	audit        *mockAuditLogger
}

func newUseCaseFixture(t *testing.T, opts ...app.Option) *useCaseFixture {
	t.Helper()
	keyStore := newMockKeyStore(t)
	revStore := newMockRevocationStore()
	sessionStore := newMockSessionStore()
	revSessionCache := newMockRevokedSessionCache()
	sessionAudit := &mockSessionAuditLogger{}
	svcStore := newMockServiceAccountStore()
	pwVerifier := &mockPasswordVerifier{}
	audit := &mockAuditLogger{}
	logger := zerolog.Nop()

	cfg := config.JWTConfig{
		Issuer:          "test-issuer",
		AccessTokenTTL:  900_000_000_000,       // 15 min in ns
		RefreshTokenTTL: 2_592_000_000_000_000, // 30 days in ns
		ServiceTokenTTL: 3_600_000_000_000,     // 1h in ns
		RSAKeySize:      2048,
		MaxKeysInJWKS:   3,
	}
	sessionCfg := config.SessionConfig{
		InactivityTTL:         365 * 24 * time.Hour,
		EnforceSingle:         true,
		RevokedCacheTTLBuffer: 10 * time.Minute,
	}

	uc := app.NewTokenUseCase(cfg, sessionCfg, keyStore, revStore, sessionStore, revSessionCache, sessionAudit, svcStore, pwVerifier, audit, logger, opts...)
	return &useCaseFixture{
		useCase:      uc,
		keyStore:     keyStore,
		revStore:     revStore,
		sessionStore: sessionStore,
		audit:        audit,
	}
}

func setupUseCase(t *testing.T, opts ...app.Option) (*app.TokenUseCase, *mockKeyStore, *mockRevocationStore, *mockAuditLogger) {
	t.Helper()
	fixture := newUseCaseFixture(t, opts...)
	return fixture.useCase, fixture.keyStore, fixture.revStore, fixture.audit
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
	}, model.DeviceInfo{})
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

func TestGenerateUserTokensNotifiesRevokedPriorSession(t *testing.T) {
	notifier := &mockSessionRevocationNotifier{}
	uc, _, _, _ := setupUseCase(t, app.WithSessionRevocationNotifier(notifier))
	ctx := context.Background()
	userID := uuid.New()
	claims := model.UserClaims{
		UserID: userID,
		Type:   model.TokenTypeUser,
		Role:   model.RoleTourist,
	}

	first, err := uc.GenerateUserTokens(ctx, claims, model.DeviceInfo{DeviceID: "first-device"})
	if err != nil {
		t.Fatalf("first GenerateUserTokens returned error: %v", err)
	}
	second, err := uc.GenerateUserTokens(ctx, claims, model.DeviceInfo{DeviceID: "second-device"})
	if err != nil {
		t.Fatalf("second GenerateUserTokens returned error: %v", err)
	}

	if first.SessionID == second.SessionID {
		t.Fatalf("expected second login to create a new session")
	}
	if len(notifier.events) != 1 {
		t.Fatalf("expected one prior-session revocation notification, got %d", len(notifier.events))
	}
	event := notifier.events[0]
	if event.UserID != userID {
		t.Fatalf("expected user id %s, got %s", userID, event.UserID)
	}
	if event.SessionID != first.SessionID {
		t.Fatalf("expected revoked prior session %s, got %s", first.SessionID, event.SessionID)
	}
	if event.Reason != model.RevokeReasonNewLogin {
		t.Fatalf("expected revoke reason %q, got %q", model.RevokeReasonNewLogin, event.Reason)
	}
}

func TestValidateUserSessionGenerationRefreshAndReplacement(t *testing.T) {
	fixture := newUseCaseFixture(t)
	ctx := context.Background()
	userID := uuid.New()
	claims := model.UserClaims{
		UserID: userID,
		Type:   model.TokenTypeUser,
		Role:   model.RoleTourist,
	}

	first, err := fixture.useCase.GenerateUserTokens(ctx, claims, model.DeviceInfo{})
	if err != nil {
		t.Fatalf("GenerateUserTokens() first error = %v", err)
	}
	assertSessionGenerationValidity(t, fixture.useCase, userID, first.SessionID, true)

	refreshed, err := fixture.useCase.RefreshTokens(ctx, first.RefreshToken, model.DeviceInfo{})
	if err != nil {
		t.Fatalf("RefreshTokens() error = %v", err)
	}
	if refreshed.SessionID != first.SessionID {
		t.Fatalf("RefreshTokens() session = %s, want stable %s", refreshed.SessionID, first.SessionID)
	}
	assertSessionGenerationValidity(t, fixture.useCase, userID, first.SessionID, true)

	second, err := fixture.useCase.GenerateUserTokens(ctx, claims, model.DeviceInfo{})
	if err != nil {
		t.Fatalf("GenerateUserTokens() replacement error = %v", err)
	}
	assertSessionGenerationValidity(t, fixture.useCase, userID, first.SessionID, false)
	assertSessionGenerationValidity(t, fixture.useCase, userID, second.SessionID, true)
	assertSessionGenerationValidity(t, fixture.useCase, uuid.New(), second.SessionID, false)
	assertSessionGenerationValidity(t, fixture.useCase, userID, uuid.New(), false)
}

func TestValidateUserSessionGenerationRevokedAndExpired(t *testing.T) {
	fixture := newUseCaseFixture(t)
	ctx := context.Background()
	userID := uuid.New()
	claims := model.UserClaims{UserID: userID, Type: model.TokenTypeUser, Role: model.RoleTourist}

	revoked, err := fixture.useCase.GenerateUserTokens(ctx, claims, model.DeviceInfo{})
	if err != nil {
		t.Fatalf("GenerateUserTokens() revoked fixture error = %v", err)
	}
	if err := fixture.useCase.LogoutSession(ctx, revoked.SessionID, model.RevokeReasonUserLogout); err != nil {
		t.Fatalf("LogoutSession() error = %v", err)
	}
	assertSessionGenerationValidity(t, fixture.useCase, userID, revoked.SessionID, false)

	expired, err := fixture.useCase.GenerateUserTokens(ctx, claims, model.DeviceInfo{})
	if err != nil {
		t.Fatalf("GenerateUserTokens() expired fixture error = %v", err)
	}
	fixture.sessionStore.mu.Lock()
	fixture.sessionStore.byID[expired.SessionID].RefreshExpiresAt = time.Now().Add(-time.Second)
	fixture.sessionStore.mu.Unlock()
	assertSessionGenerationValidity(t, fixture.useCase, userID, expired.SessionID, false)

	inactive, err := fixture.useCase.GenerateUserTokens(ctx, claims, model.DeviceInfo{})
	if err != nil {
		t.Fatalf("GenerateUserTokens() inactive fixture error = %v", err)
	}
	fixture.sessionStore.mu.Lock()
	fixture.sessionStore.byID[inactive.SessionID].LastUsedAt = time.Now().Add(-366 * 24 * time.Hour)
	fixture.sessionStore.mu.Unlock()
	assertSessionGenerationValidity(t, fixture.useCase, userID, inactive.SessionID, false)
}

func TestValidateUserSessionGenerationStoreFailureFailsClosed(t *testing.T) {
	fixture := newUseCaseFixture(t)
	fixture.sessionStore.validateErr = errors.New("storage unavailable")

	valid, err := fixture.useCase.ValidateUserSessionGeneration(t.Context(), uuid.New(), uuid.New())
	if err == nil {
		t.Fatal("ValidateUserSessionGeneration() error = nil, want dependency error")
	}
	if valid {
		t.Fatal("ValidateUserSessionGeneration() valid = true on dependency failure")
	}
}

func assertSessionGenerationValidity(
	t *testing.T,
	useCase *app.TokenUseCase,
	userID, generation uuid.UUID,
	want bool,
) {
	t.Helper()
	got, err := useCase.ValidateUserSessionGeneration(t.Context(), userID, generation)
	if err != nil {
		t.Fatalf("ValidateUserSessionGeneration() error = %v", err)
	}
	if got != want {
		t.Fatalf("ValidateUserSessionGeneration() = %v, want %v", got, want)
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
	}, model.DeviceInfo{})
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
	}, model.DeviceInfo{})

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
	}, model.DeviceInfo{})

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
	}, model.DeviceInfo{})

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
