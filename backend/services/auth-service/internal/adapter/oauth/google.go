package oauth

import (
	"context"
	"errors"
	"strings"

	"github.com/rs/zerolog"
	"google.golang.org/api/idtoken"

	"kz/inflap/backend/services/auth-service/internal/domain/model"
)

// GoogleVerifier implements port.OAuthVerifier for Google Sign-In.
type GoogleVerifier struct {
	clientID  string
	logger    zerolog.Logger
	validator googleTokenValidator
}

func NewGoogleVerifier(clientID string, logger zerolog.Logger) *GoogleVerifier {
	return newGoogleVerifierWithValidator(clientID, logger, realGoogleTokenValidator{})
}

func newGoogleVerifierWithValidator(clientID string, logger zerolog.Logger, validator googleTokenValidator) *GoogleVerifier {
	return &GoogleVerifier{
		clientID:  strings.TrimSpace(clientID),
		logger:    logger.With().Str("component", "google_oauth").Logger(),
		validator: validator,
	}
}

// Verify validates a Google ID Token and extracts user info.
func (v *GoogleVerifier) Verify(ctx context.Context, idToken string) (*model.OAuthUserInfo, error) {
	token := strings.TrimSpace(idToken)
	if token == "" {
		return nil, model.ErrOAuthFailed
	}

	if v.clientID == "" {
		v.logger.Error().Msg("google oauth client id is not configured")
		return nil, model.ErrOAuthFailed
	}

	payload, err := v.validator.Validate(ctx, token, v.clientID)
	if err != nil {
		v.logger.Warn().Err(err).Msg("google oauth token verification failed")
		return nil, model.ErrOAuthFailed
	}

	providerID := strings.TrimSpace(payload.Subject)
	if providerID == "" {
		return nil, model.ErrOAuthProviderID
	}

	return &model.OAuthUserInfo{
		ProviderID: providerID,
		Email:      strings.TrimSpace(payload.Email),
		Name:       strings.TrimSpace(payload.Name),
	}, nil
}

type googleTokenValidator interface {
	Validate(ctx context.Context, idToken string, audience string) (*googleTokenPayload, error)
}

type googleTokenPayload struct {
	Subject string
	Email   string
	Name    string
}

type realGoogleTokenValidator struct{}

func (realGoogleTokenValidator) Validate(ctx context.Context, idTokenValue string, audience string) (*googleTokenPayload, error) {
	payload, err := idtoken.Validate(ctx, idTokenValue, audience)
	if err != nil {
		return nil, err
	}
	if payload == nil {
		return nil, errors.New("google id token payload is empty")
	}

	return &googleTokenPayload{
		Subject: payload.Subject,
		Email:   stringClaim(payload.Claims, "email"),
		Name:    stringClaim(payload.Claims, "name"),
	}, nil
}

func stringClaim(claims map[string]any, key string) string {
	value, ok := claims[key].(string)
	if !ok {
		return ""
	}
	return value
}
