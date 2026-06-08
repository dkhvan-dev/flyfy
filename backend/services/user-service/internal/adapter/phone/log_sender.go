package phone

import (
	"context"
	"strings"

	"github.com/rs/zerolog/log"
)

type LogSender struct {
	env string
}

func NewLogSender(env string) *LogSender {
	return &LogSender{env: strings.TrimSpace(env)}
}

func (s *LogSender) SendPhoneVerificationCode(
	ctx context.Context,
	phone string,
	code string,
) error {
	_ = code
	log.Ctx(ctx).Info().
		Str("phone", maskPhone(phone)).
		Str("env", s.env).
		Msg("development phone verification code generated")
	return nil
}

func maskPhone(phone string) string {
	phone = strings.TrimSpace(phone)
	if len(phone) <= 4 {
		return "****"
	}
	return phone[:len(phone)-4] + "****"
}
