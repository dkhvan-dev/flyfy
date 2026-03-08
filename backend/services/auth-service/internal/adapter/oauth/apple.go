package oauth

import (
	"context"

	"github.com/rs/zerolog"

	"github.com/dkhvan-dev/flyfy/backend/services/auth-service/internal/domain/model"
)

// AppleVerifier implements port.OAuthVerifier for Apple Sign-In.
// In development mode, it acts as a stub that trusts the ID token.
// In production, replace with real Apple token verification using
// Apple's JWKS endpoint: https://appleid.apple.com/auth/keys
type AppleVerifier struct {
	teamID   string
	bundleID string
	logger   zerolog.Logger
}

func NewAppleVerifier(teamID, bundleID string, logger zerolog.Logger) *AppleVerifier {
	return &AppleVerifier{
		teamID:   teamID,
		bundleID: bundleID,
		logger:   logger.With().Str("component", "apple_oauth").Logger(),
	}
}

// Verify validates an Apple ID Token and extracts user info.
// DEV MODE: accepts any token as valid.
// In production, this should:
// 1. Fetch Apple JWKS from https://appleid.apple.com/auth/keys
// 2. Verify RS256 signature
// 3. Verify issuer (https://appleid.apple.com), aud (bundleID), exp
// 4. Extract sub, email from claims
func (v *AppleVerifier) Verify(_ context.Context, idToken string) (*model.OAuthUserInfo, error) {
	v.logger.Warn().
		Str("token_prefix", truncate(idToken, 20)).
		Msg("⚠️  Apple OAuth stub: accepting token without verification (dev mode)")

	return &model.OAuthUserInfo{
		ProviderID: "apple_" + truncate(idToken, 32),
		Email:      "dev@apple-stub.local",
		Name:       "Apple Dev User",
	}, nil
}
