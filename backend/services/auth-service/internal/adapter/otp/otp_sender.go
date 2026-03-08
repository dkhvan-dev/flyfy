package otp

import (
	"context"

	"github.com/rs/zerolog"
)

// LogOTPSender implements port.OTPSender by logging the code.
// This is used in development mode. In production, replace with
// a real SMS provider (Twilio, MessageBird, etc.).
type LogOTPSender struct {
	logger zerolog.Logger
}

func NewLogOTPSender(logger zerolog.Logger) *LogOTPSender {
	return &LogOTPSender{
		logger: logger.With().Str("component", "otp_sender").Logger(),
	}
}

// Send logs the OTP code instead of actually sending an SMS.
func (s *LogOTPSender) Send(_ context.Context, phone, code string) error {
	s.logger.Info().
		Str("phone", phone).
		Str("code", code).
		Msg("📱 OTP code (dev mode — would be sent via SMS in production)")
	return nil
}
