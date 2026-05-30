package oauth

import (
	"context"

	"github.com/rs/zerolog"

	"kz/inflap/backend/services/auth-service/internal/domain/model"
)

// GoogleVerifier implements port.OAuthVerifier for Google Sign-In.
// In development mode, it acts as a stub that trusts the ID token.
// In production, replace with real Google token verification using
// google.golang.org/api/oauth2 or manual JWKS validation.
type GoogleVerifier struct {
	clientID string
	logger   zerolog.Logger
}

func NewGoogleVerifier(clientID string, logger zerolog.Logger) *GoogleVerifier {
	return &GoogleVerifier{
		clientID: clientID,
		logger:   logger.With().Str("component", "google_oauth").Logger(),
	}
}

// Verify validates a Google ID Token and extracts user info.
// DEV MODE: accepts any token formatted as "google-<sub>".
// In production, this should verify the JWT against Google's JWKS.
func (v *GoogleVerifier) Verify(_ context.Context, idToken string) (*model.OAuthUserInfo, error) {
	// TODO: In production, verify the JWT:
	// 1. Fetch Google JWKS from https://www.googleapis.com/oauth2/v3/certs
	// 2. Verify signature, issuer (accounts.google.com), aud (clientID), exp
	// 3. Extract sub, email, name from claims

	v.logger.Warn().
		Str("token_prefix", truncate(idToken, 20)).
		Msg("⚠️  Google OAuth stub: accepting token without verification (dev mode)")

	// For development, return mock user info
	// In production, parse the real JWT claims
	return &model.OAuthUserInfo{
		ProviderID: "google_" + truncate(idToken, 32),
		Email:      "dev@google-stub.local",
		Name:       "Google Dev User",
	}, nil
}
