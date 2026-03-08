package repository

import (
	"context"

	"github.com/rs/zerolog"
)

// ZerologAuditLogger implements port.AuditLogger using zerolog.
type ZerologAuditLogger struct {
	logger zerolog.Logger
}

func NewZerologAuditLogger(logger zerolog.Logger) *ZerologAuditLogger {
	return &ZerologAuditLogger{
		logger: logger.With().Str("component", "audit").Logger(),
	}
}

// LogServiceAuth logs a service authentication attempt.
func (a *ZerologAuditLogger) LogServiceAuth(
	_ context.Context,
	callerID, targetAction, result string,
	metadata map[string]string,
) {
	event := a.logger.Info().
		Str("caller_id", callerID).
		Str("action", targetAction).
		Str("result", result)

	for k, v := range metadata {
		event = event.Str(k, v)
	}

	event.Msg("service auth event")
}
