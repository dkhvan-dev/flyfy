package app

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/go-jose/go-jose/v4"
	josejwt "github.com/go-jose/go-jose/v4/jwt"
	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"kz/inflap/backend/services/token-service/internal/config"
	"kz/inflap/backend/services/token-service/internal/domain/model"
	"kz/inflap/backend/services/token-service/internal/domain/port"
)

// jwtCustomClaims wraps standard + custom claims for JWT serialization.
type jwtCustomClaims struct {
	Type        model.TokenType `json:"type"`
	Role        string          `json:"role,omitempty"`
	Roles       []string        `json:"roles,omitempty"`
	Permissions []string        `json:"permissions,omitempty"`
	TokenKind   string          `json:"kind"`          // "access" | "refresh" | "service"
	SessionID   string          `json:"sid,omitempty"` // user tokens only
}

// TokenUseCase implements the core token business logic.
type TokenUseCase struct {
	cfg              config.JWTConfig
	sessionCfg       config.SessionConfig
	keyStore         port.KeyStore
	revStore         port.RevocationStore
	sessionStore     port.SessionStore
	revSessionCache  port.RevokedSessionCache
	sessionAudit     port.SessionAuditLogger
	svcStore         port.ServiceAccountStore
	passwordVerifier port.PasswordVerifier
	audit            port.AuditLogger
	logger           zerolog.Logger
}

// NewTokenUseCase wires the use case with all required ports.
func NewTokenUseCase(
	cfg config.JWTConfig,
	sessionCfg config.SessionConfig,
	keyStore port.KeyStore,
	revStore port.RevocationStore,
	sessionStore port.SessionStore,
	revSessionCache port.RevokedSessionCache,
	sessionAudit port.SessionAuditLogger,
	svcStore port.ServiceAccountStore,
	passwordVerifier port.PasswordVerifier,
	audit port.AuditLogger,
	logger zerolog.Logger,
) *TokenUseCase {
	return &TokenUseCase{
		cfg:              cfg,
		sessionCfg:       sessionCfg,
		keyStore:         keyStore,
		revStore:         revStore,
		sessionStore:     sessionStore,
		revSessionCache:  revSessionCache,
		sessionAudit:     sessionAudit,
		svcStore:         svcStore,
		passwordVerifier: passwordVerifier,
		audit:            audit,
		logger:           logger.With().Str("component", "token_usecase").Logger(),
	}
}

// --- TokenGenerator ---

// GenerateUserTokens issues a fresh access+refresh pair backed by a new user_session.
// Any existing active session for the user is revoked first (single-session enforcement).
// The previous session's refresh JTI is added to the revocation list and the session_id
// to the revoked-session cache so the old device receives 401 on its next call.
func (uc *TokenUseCase) GenerateUserTokens(
	ctx context.Context,
	claims model.UserClaims,
	device model.DeviceInfo,
) (*model.TokenPair, error) {
	now := time.Now()
	accessExp := now.Add(uc.cfg.AccessTokenTTL)
	refreshExp := now.Add(uc.cfg.RefreshTokenTTL)

	sessionID := uuid.New()
	accessJTI := uuid.New().String()
	refreshJTI := uuid.New().String()

	accessToken, err := uc.signUserToken(ctx, claims, sessionID.String(), accessJTI, "access", now, accessExp)
	if err != nil {
		return nil, err
	}
	refreshToken, err := uc.signUserToken(ctx, claims, sessionID.String(), refreshJTI, "refresh", now, refreshExp)
	if err != nil {
		return nil, err
	}

	newSess := &model.UserSession{
		ID:               sessionID,
		UserID:           claims.UserID,
		RefreshJTI:       refreshJTI,
		RefreshTokenHash: hashToken(refreshToken),
		RefreshIssuedAt:  now,
		RefreshExpiresAt: refreshExp,
		Device:           device,
		CreatedAt:        now,
		LastUsedAt:       now,
	}

	replaceReason := model.RevokeReasonNewLogin
	if !uc.sessionCfg.EnforceSingle {
		// We still create a new session, but no replacement is intended.
		// However the partial unique index forbids two active rows; the only
		// way to support multi-session is to drop the index. For now the
		// flag exists as a kill-switch only — we proceed as if Enforce=true.
		replaceReason = model.RevokeReasonNewLogin
	}

	replaced, err := uc.sessionStore.CreateActive(ctx, newSess, replaceReason)
	if err != nil {
		// On unique-violation race, treat as Internal — caller (auth-service) maps to 503.
		if errors.Is(err, model.ErrSessionConflict) {
			uc.logger.Error().Err(err).Str("user_id", claims.UserID.String()).Msg("session creation conflict")
			return nil, err
		}
		return nil, fmt.Errorf("creating session: %w", err)
	}

	// If we replaced a session, kill the old refresh JTI and broadcast revocation.
	if replaced != nil {
		if err := uc.revStore.Add(ctx, replaced.RefreshJTI, replaced.RefreshExpiresAt.Unix()); err != nil {
			uc.logger.Warn().Err(err).Str("jti", replaced.RefreshJTI).Msg("failed to revoke previous refresh JTI")
		}
		uc.markSessionRevokedInCache(ctx, replaced.ID)
		uc.sessionAudit.LogSessionEvent(ctx, claims.UserID, &replaced.ID, model.SessionEventReplaced,
			device.IPAddress, device.UserAgent, map[string]string{
				"new_session_id": sessionID.String(),
				"prev_device":    replaced.Device.DeviceID,
			})
	}

	uc.sessionAudit.LogSessionEvent(ctx, claims.UserID, &sessionID, model.SessionEventCreated,
		device.IPAddress, device.UserAgent, map[string]string{
			"platform": device.Platform,
		})

	uc.logger.Info().
		Str("user_id", claims.UserID.String()).
		Str("session_id", sessionID.String()).
		Bool("replaced_prior", replaced != nil).
		Msg("user token pair generated")

	return &model.TokenPair{
		AccessToken:      accessToken,
		RefreshToken:     refreshToken,
		ExpiresAt:        accessExp,
		RefreshExpiresAt: refreshExp,
		TokenType:        "Bearer",
		SessionID:        sessionID,
	}, nil
}

func (uc *TokenUseCase) GenerateServiceToken(ctx context.Context, claims model.ServiceClaims) (*model.ServiceToken, error) {
	now := time.Now()
	exp := now.Add(uc.cfg.ServiceTokenTTL)
	jti := uuid.New().String()

	token, err := uc.signToken(ctx, josejwt.Claims{
		Issuer:    uc.cfg.Issuer,
		Subject:   claims.ServiceID,
		IssuedAt:  josejwt.NewNumericDate(now),
		Expiry:    josejwt.NewNumericDate(exp),
		NotBefore: josejwt.NewNumericDate(now),
		ID:        jti,
	}, jwtCustomClaims{
		Type:      model.TokenTypeService,
		Roles:     claims.Roles,
		TokenKind: "service",
	})
	if err != nil {
		return nil, fmt.Errorf("signing service token: %w", err)
	}

	uc.logger.Info().
		Str("service_id", claims.ServiceID).
		Int("roles_count", len(claims.Roles)).
		Msg("service token generated")

	return &model.ServiceToken{Token: token, ExpiresAt: exp}, nil
}

// --- TokenValidator ---

func (uc *TokenUseCase) ValidateAccessToken(ctx context.Context, tokenStr string) (*model.ValidatedClaims, error) {
	claims, err := uc.parseAndVerify(ctx, tokenStr, "access")
	if err != nil {
		return nil, err
	}
	if err := uc.checkSessionAlive(ctx, claims, false); err != nil {
		return nil, err
	}
	return claims, nil
}

func (uc *TokenUseCase) ValidateRefreshToken(ctx context.Context, tokenStr string) (*model.ValidatedClaims, error) {
	claims, err := uc.parseAndVerify(ctx, tokenStr, "refresh")
	if err != nil {
		return nil, err
	}
	if err := uc.checkSessionAlive(ctx, claims, true); err != nil {
		return nil, err
	}
	return claims, nil
}

func (uc *TokenUseCase) ValidateServiceToken(ctx context.Context, tokenStr string) (*model.ValidatedClaims, error) {
	return uc.parseAndVerify(ctx, tokenStr, "service")
}

// --- TokenRefresher ---

// RefreshTokens validates the refresh token, applies reuse detection, rotates
// the session's refresh JTI/hash, and issues a new pair. The session_id stays
// the same — the device keeps "its" session.
func (uc *TokenUseCase) RefreshTokens(
	ctx context.Context,
	refreshToken string,
	device model.DeviceInfo,
) (*model.TokenPair, error) {
	claims, err := uc.parseAndVerify(ctx, refreshToken, "refresh")
	if err != nil {
		return nil, err
	}

	// Reuse detection: if the JTI is already in history, this refresh token
	// has been rotated before. Treat as token theft → revoke whole session.
	if histSessionID, found, hErr := uc.sessionStore.FindHistoricalRefreshJTI(ctx, claims.JTI); hErr == nil && found {
		_ = uc.sessionStore.Revoke(ctx, histSessionID, model.RevokeReasonTokenReuse)
		uc.markSessionRevokedInCache(ctx, histSessionID)
		uc.sessionAudit.LogSessionEvent(ctx, parseUserID(claims.Subject), &histSessionID,
			model.SessionEventTokenReuseDetected, device.IPAddress, device.UserAgent,
			map[string]string{"reused_jti": claims.JTI})
		uc.logger.Warn().
			Str("session_id", histSessionID.String()).
			Str("reused_jti", claims.JTI).
			Msg("refresh token reuse detected — session revoked")
		return nil, model.ErrTokenReuseDetect
	}

	// Look up the active session for this refresh JTI.
	session, err := uc.sessionStore.GetActiveByRefreshJTI(ctx, claims.JTI)
	if err != nil {
		if errors.Is(err, model.ErrSessionNotFound) {
			return nil, model.ErrTokenRevoked
		}
		return nil, fmt.Errorf("loading session: %w", err)
	}

	// Inactivity check.
	if uc.sessionCfg.InactivityTTL > 0 && time.Since(session.LastUsedAt) > uc.sessionCfg.InactivityTTL {
		_ = uc.sessionStore.Revoke(ctx, session.ID, model.RevokeReasonInactivityExpired)
		uc.markSessionRevokedInCache(ctx, session.ID)
		uc.sessionAudit.LogSessionEvent(ctx, session.UserID, &session.ID, model.SessionEventInactivityExpired,
			device.IPAddress, device.UserAgent, nil)
		return nil, model.ErrSessionExpired
	}

	now := time.Now()
	accessExp := now.Add(uc.cfg.AccessTokenTTL)
	refreshExp := now.Add(uc.cfg.RefreshTokenTTL)

	newAccessJTI := uuid.New().String()
	newRefreshJTI := uuid.New().String()

	// Re-sign with the same role/permissions stored in the session's UserClaims.
	userClaims := model.UserClaims{
		UserID:      session.UserID,
		Type:        model.TokenTypeUser,
		Role:        model.UserRole(claims.Role),
		Permissions: claims.Permissions,
	}

	newAccess, err := uc.signUserToken(ctx, userClaims, session.ID.String(), newAccessJTI, "access", now, accessExp)
	if err != nil {
		return nil, err
	}
	newRefresh, err := uc.signUserToken(ctx, userClaims, session.ID.String(), newRefreshJTI, "refresh", now, refreshExp)
	if err != nil {
		return nil, err
	}

	prev := port.RotatePrev{
		RefreshJTI:       session.RefreshJTI,
		RefreshTokenHash: session.RefreshTokenHash,
		IssuedAt:         session.RefreshIssuedAt,
	}
	next := port.RotateNext{
		RefreshJTI:       newRefreshJTI,
		RefreshTokenHash: hashToken(newRefresh),
		IssuedAt:         now,
		ExpiresAt:        refreshExp,
		Device:           device,
		RotatedAt:        now,
	}
	if err := uc.sessionStore.RotateRefresh(ctx, session.ID, prev, next); err != nil {
		if errors.Is(err, model.ErrSessionNotFound) {
			// Session got revoked between our load and rotate — treat as revoked.
			return nil, model.ErrTokenRevoked
		}
		return nil, fmt.Errorf("rotating session refresh: %w", err)
	}

	// Add the previous refresh JTI to the global deny-list (defence in depth).
	if err := uc.revStore.Add(ctx, prev.RefreshJTI, session.RefreshExpiresAt.Unix()); err != nil {
		uc.logger.Warn().Err(err).Str("jti", prev.RefreshJTI).Msg("failed to revoke previous refresh JTI on rotate")
	}

	uc.sessionAudit.LogSessionEvent(ctx, session.UserID, &session.ID, model.SessionEventRefreshed,
		device.IPAddress, device.UserAgent, nil)

	return &model.TokenPair{
		AccessToken:      newAccess,
		RefreshToken:     newRefresh,
		ExpiresAt:        accessExp,
		RefreshExpiresAt: refreshExp,
		TokenType:        "Bearer",
		SessionID:        session.ID,
	}, nil
}

// --- TokenRevoker ---

// Revoke invalidates a single JTI in the deny-list (legacy; kept for compatibility
// with auth-service.Logout that revokes by JTI). Prefer LogoutSession for new code.
func (uc *TokenUseCase) Revoke(ctx context.Context, jti string, expiresAt int64, reason string) error {
	if err := uc.revStore.Add(ctx, jti, expiresAt); err != nil {
		return fmt.Errorf("adding to revocation list: %w", err)
	}
	uc.logger.Info().Str("jti", jti).Str("reason", reason).Msg("token revoked")
	return nil
}

func (uc *TokenUseCase) IsRevoked(ctx context.Context, jti string) (bool, error) {
	return uc.revStore.Exists(ctx, jti)
}

// --- SessionManager ---

func (uc *TokenUseCase) LogoutSession(ctx context.Context, sessionID uuid.UUID, reason string) error {
	session, err := uc.sessionStore.GetByID(ctx, sessionID)
	if err != nil {
		if errors.Is(err, model.ErrSessionNotFound) {
			return nil
		}
		return fmt.Errorf("loading session: %w", err)
	}
	if session.RevokedAt != nil {
		return nil
	}

	if err := uc.sessionStore.Revoke(ctx, sessionID, reason); err != nil {
		return fmt.Errorf("revoking session: %w", err)
	}

	if err := uc.revStore.Add(ctx, session.RefreshJTI, session.RefreshExpiresAt.Unix()); err != nil {
		uc.logger.Warn().Err(err).Str("jti", session.RefreshJTI).Msg("failed to deny-list refresh on logout")
	}

	uc.markSessionRevokedInCache(ctx, sessionID)

	event := model.SessionEventLogout
	if reason == model.RevokeReasonAdmin {
		event = model.SessionEventAdminRevoke
	}
	uc.sessionAudit.LogSessionEvent(ctx, session.UserID, &sessionID, event, "", "", map[string]string{"reason": reason})

	return nil
}

func (uc *TokenUseCase) ListUserSessions(ctx context.Context, userID uuid.UUID) ([]*model.UserSession, error) {
	return uc.sessionStore.ListByUserID(ctx, userID, 50)
}

func (uc *TokenUseCase) RevokeAllUserSessions(ctx context.Context, userID uuid.UUID, reason string) (int, error) {
	sessions, err := uc.sessionStore.ListByUserID(ctx, userID, 200)
	if err != nil {
		return 0, fmt.Errorf("listing user sessions: %w", err)
	}

	count, err := uc.sessionStore.RevokeAllForUser(ctx, userID, reason)
	if err != nil {
		return 0, fmt.Errorf("revoking all sessions: %w", err)
	}

	// Push every previously-active session_id and refresh JTI to the deny-list / cache.
	for _, sess := range sessions {
		if sess.RevokedAt != nil {
			continue
		}
		if rerr := uc.revStore.Add(ctx, sess.RefreshJTI, sess.RefreshExpiresAt.Unix()); rerr != nil {
			uc.logger.Warn().Err(rerr).Str("jti", sess.RefreshJTI).Msg("failed to deny-list refresh in mass revoke")
		}
		uc.markSessionRevokedInCache(ctx, sess.ID)
	}

	uc.sessionAudit.LogSessionEvent(ctx, userID, nil, model.SessionEventAdminRevoke, "", "",
		map[string]string{"reason": reason, "revoked_count": fmt.Sprintf("%d", count)})

	return count, nil
}

// --- ServiceAuthenticator ---

func (uc *TokenUseCase) AuthenticateService(ctx context.Context, serviceID, serviceSecret string) (*model.ServiceToken, error) {
	account, err := uc.svcStore.GetByServiceID(ctx, serviceID)
	if err != nil {
		uc.audit.LogServiceAuth(ctx, serviceID, "authenticate", "not_found", nil)
		return nil, model.ErrServiceNotFound
	}

	if !account.IsActive {
		uc.audit.LogServiceAuth(ctx, serviceID, "authenticate", "inactive", nil)
		return nil, model.ErrServiceInactive
	}

	if !uc.passwordVerifier.Verify(account.SecretHash, serviceSecret) {
		uc.audit.LogServiceAuth(ctx, serviceID, "authenticate", "bad_credentials", nil)
		return nil, model.ErrInvalidCredentials
	}

	token, err := uc.GenerateServiceToken(ctx, model.ServiceClaims{
		ServiceID: account.ServiceID,
		Type:      model.TokenTypeService,
		Roles:     account.Roles,
	})
	if err != nil {
		return nil, err
	}

	uc.audit.LogServiceAuth(ctx, serviceID, "authenticate", "granted", map[string]string{
		"roles_count": fmt.Sprintf("%d", len(account.Roles)),
	})
	return token, nil
}

// --- KeyManager ---

func (uc *TokenUseCase) RotateKeys(ctx context.Context) error {
	key, err := rsa.GenerateKey(rand.Reader, uc.cfg.RSAKeySize)
	if err != nil {
		return fmt.Errorf("generating RSA key: %w", err)
	}

	keyID := fmt.Sprintf("key-%s", uuid.New().String()[:8])

	if err := uc.keyStore.StoreKey(ctx, keyID, key); err != nil {
		return fmt.Errorf("storing new key: %w", err)
	}

	if err := uc.keyStore.DeleteExpiredKeys(ctx, uc.cfg.MaxKeysInJWKS); err != nil {
		uc.logger.Warn().Err(err).Msg("failed to clean up old keys")
	}

	uc.logger.Info().Str("key_id", keyID).Msg("key rotation completed")
	return nil
}

func (uc *TokenUseCase) GetJWKS(ctx context.Context) (*jose.JSONWebKeySet, error) {
	keys, err := uc.keyStore.GetPublicKeys(ctx)
	if err != nil {
		return nil, fmt.Errorf("fetching public keys: %w", err)
	}
	return &jose.JSONWebKeySet{Keys: keys}, nil
}

// --- Internal helpers ---

func (uc *TokenUseCase) signUserToken(
	ctx context.Context,
	claims model.UserClaims,
	sessionID, jti, kind string,
	now, exp time.Time,
) (string, error) {
	std := josejwt.Claims{
		Issuer:    uc.cfg.Issuer,
		Subject:   claims.UserID.String(),
		IssuedAt:  josejwt.NewNumericDate(now),
		Expiry:    josejwt.NewNumericDate(exp),
		NotBefore: josejwt.NewNumericDate(now),
		ID:        jti,
	}
	custom := jwtCustomClaims{
		Type:        model.TokenTypeUser,
		Role:        string(claims.Role),
		TokenKind:   kind,
		SessionID:   sessionID,
		Permissions: claims.Permissions,
	}
	if kind == "refresh" {
		// Permissions are not needed in refresh tokens — they are re-derived on access issuance.
		custom.Permissions = nil
	}
	tok, err := uc.signToken(ctx, std, custom)
	if err != nil {
		return "", fmt.Errorf("signing %s token: %w", kind, err)
	}
	return tok, nil
}

// signToken creates a signed JWT string using the active RSA key.
func (uc *TokenUseCase) signToken(ctx context.Context, stdClaims josejwt.Claims, custom jwtCustomClaims) (string, error) {
	keyID, privateKey, err := uc.keyStore.GetActiveKey(ctx)
	if err != nil {
		return "", fmt.Errorf("getting active key: %w", err)
	}

	signerOpts := (&jose.SignerOptions{}).
		WithType("JWT").
		WithHeader("kid", keyID)

	signer, err := jose.NewSigner(
		jose.SigningKey{Algorithm: jose.RS256, Key: privateKey},
		signerOpts,
	)
	if err != nil {
		return "", fmt.Errorf("creating signer: %w", err)
	}

	token, err := josejwt.Signed(signer).
		Claims(stdClaims).
		Claims(custom).
		Serialize()
	if err != nil {
		return "", fmt.Errorf("serializing token: %w", err)
	}
	return token, nil
}

// parseAndVerify parses the token, validates signature/expiry/kind, and checks
// the JTI deny-list. It does NOT touch the session store — callers do that next.
func (uc *TokenUseCase) parseAndVerify(ctx context.Context, tokenStr string, expectedKind string) (*model.ValidatedClaims, error) {
	tok, err := josejwt.ParseSigned(tokenStr, []jose.SignatureAlgorithm{jose.RS256})
	if err != nil {
		return nil, model.ErrTokenMalformed
	}

	pubKeys, err := uc.keyStore.GetPublicKeys(ctx)
	if err != nil {
		return nil, fmt.Errorf("fetching public keys: %w", err)
	}

	var stdClaims josejwt.Claims
	var custom jwtCustomClaims
	verified := false
	for _, jwk := range pubKeys {
		if err := tok.Claims(jwk.Key, &stdClaims, &custom); err == nil {
			verified = true
			break
		}
	}
	if !verified {
		return nil, model.ErrInvalidSignature
	}

	if err := stdClaims.Validate(josejwt.Expected{Issuer: uc.cfg.Issuer, Time: time.Now()}); err != nil {
		return nil, model.ErrTokenExpired
	}

	if custom.TokenKind != expectedKind {
		return nil, model.ErrTokenInvalid
	}

	if stdClaims.ID != "" {
		revoked, err := uc.revStore.Exists(ctx, stdClaims.ID)
		if err != nil {
			uc.logger.Warn().Err(err).Str("jti", stdClaims.ID).Msg("revocation check failed")
		}
		if revoked {
			return nil, model.ErrTokenRevoked
		}
	}

	return &model.ValidatedClaims{
		Subject:     stdClaims.Subject,
		UserID:      userIDForValidatedClaims(custom.Type, stdClaims.Subject),
		Type:        custom.Type,
		Role:        custom.Role,
		Roles:       custom.Roles,
		Permissions: custom.Permissions,
		JTI:         stdClaims.ID,
		SessionID:   custom.SessionID,
		IssuedAt:    stdClaims.IssuedAt.Time(),
		ExpiresAt:   stdClaims.Expiry.Time(),
	}, nil
}

// checkSessionAlive verifies that the session_id (sid claim) is still active.
// For access tokens we trust the Redis cache only (fast path) — DB lookups happen
// only at refresh time. For refresh tokens we always hit the DB (authoritative).
func (uc *TokenUseCase) checkSessionAlive(ctx context.Context, claims *model.ValidatedClaims, isRefresh bool) error {
	if claims.SessionID == "" {
		// Tokens issued before sessions were introduced have no sid; allow them.
		return nil
	}
	sid, err := uuid.Parse(claims.SessionID)
	if err != nil {
		return model.ErrTokenInvalid
	}

	revoked, cacheErr := uc.revSessionCache.IsRevoked(ctx, sid)
	if cacheErr != nil {
		uc.logger.Warn().Err(cacheErr).Msg("session-revoked cache lookup failed")
	}
	if revoked {
		return model.ErrTokenRevoked
	}

	if !isRefresh {
		return nil
	}

	// Refresh path — authoritative DB check.
	session, err := uc.sessionStore.GetByID(ctx, sid)
	if err != nil {
		if errors.Is(err, model.ErrSessionNotFound) {
			return model.ErrTokenRevoked
		}
		return err
	}
	if session.RevokedAt != nil {
		// Eagerly populate the cache so the next access call is fast.
		uc.markSessionRevokedInCache(ctx, sid)
		return model.ErrTokenRevoked
	}
	return nil
}

func (uc *TokenUseCase) markSessionRevokedInCache(ctx context.Context, sessionID uuid.UUID) {
	ttl := uc.cfg.AccessTokenTTL + uc.sessionCfg.RevokedCacheTTLBuffer
	if err := uc.revSessionCache.MarkRevoked(ctx, sessionID, ttl); err != nil {
		uc.logger.Warn().Err(err).Str("session_id", sessionID.String()).Msg("failed to mark session revoked in cache")
	}
}

func hashToken(tok string) string {
	h := sha256.Sum256([]byte(tok))
	return hex.EncodeToString(h[:])
}

func parseUserID(s string) uuid.UUID {
	uid, err := uuid.Parse(s)
	if err != nil {
		return uuid.Nil
	}
	return uid
}

func userIDForValidatedClaims(tokenType model.TokenType, subject string) string {
	if tokenType != model.TokenTypeUser {
		return ""
	}
	return subject
}
