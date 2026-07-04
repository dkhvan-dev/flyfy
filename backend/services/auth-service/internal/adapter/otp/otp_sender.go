package otp

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/mail"
	"strings"
	"time"

	"github.com/rs/zerolog"

	"kz/inflap/backend/services/auth-service/internal/domain/port"
)

const DefaultDevEmailOTPSenderAddress = "Inflap <onboarding@resend.dev>"
const defaultEmailProviderTimeout = 8 * time.Second
const defaultResendBaseURL = "https://api.resend.com"

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

// LogEmailOTPSender implements email OTP delivery for development. It keeps
// the use-case wired through a sender port while real provider credentials are
// still intentionally kept out of source code.
type LogEmailOTPSender struct {
	from   string
	logger zerolog.Logger
}

type EmailSenderConfig struct {
	FromAddress   string
	ResendAPIKey  string
	ResendBaseURL string
	ResendTimeout time.Duration
}

func NewEmailOTPSender(cfg EmailSenderConfig, logger zerolog.Logger) port.EmailOTPSender {
	if cfg.ResendTimeout <= 0 {
		cfg.ResendTimeout = defaultEmailProviderTimeout
	}

	if strings.TrimSpace(cfg.ResendAPIKey) == "" {
		return NewLogEmailOTPSender(cfg.FromAddress, logger)
	}

	return NewResendEmailOTPSender(cfg, logger)
}

func NewLogEmailOTPSender(from string, logger zerolog.Logger) *LogEmailOTPSender {
	from = strings.TrimSpace(from)
	if from == "" {
		from = DefaultDevEmailOTPSenderAddress
	}
	return &LogEmailOTPSender{
		from:   from,
		logger: logger.With().Str("component", "email_otp_sender").Logger(),
	}
}

func (s *LogEmailOTPSender) SendEmailOTP(_ context.Context, email, code string) error {
	s.logger.Info().
		Str("from", s.from).
		Str("email", maskEmailForLog(email)).
		Str("code", code).
		Msg("email OTP code (dev mode — would be sent via email in production)")
	return nil
}

type ResendEmailOTPSender struct {
	from       string
	apiKey     string
	baseURL    string
	timeout    time.Duration
	httpClient *http.Client
	logger     zerolog.Logger
}

func NewResendEmailOTPSender(cfg EmailSenderConfig, logger zerolog.Logger) *ResendEmailOTPSender {
	from := strings.TrimSpace(cfg.FromAddress)
	if from == "" {
		from = DefaultDevEmailOTPSenderAddress
	}
	baseURL := strings.TrimSpace(cfg.ResendBaseURL)
	if baseURL == "" {
		baseURL = defaultResendBaseURL
	}
	timeout := cfg.ResendTimeout
	if timeout <= 0 {
		timeout = defaultEmailProviderTimeout
	}
	return &ResendEmailOTPSender{
		from:       from,
		apiKey:     strings.TrimSpace(cfg.ResendAPIKey),
		baseURL:    strings.TrimRight(baseURL, "/"),
		timeout:    timeout,
		httpClient: &http.Client{Timeout: timeout},
		logger:     logger.With().Str("component", "email_otp_sender").Str("provider", "resend").Logger(),
	}
}

func (s *ResendEmailOTPSender) SendEmailOTP(ctx context.Context, email, code string) error {
	from, err := mail.ParseAddress(s.from)
	if err != nil {
		return fmt.Errorf("parsing sender address: %w", err)
	}
	to, err := mail.ParseAddress(strings.TrimSpace(email))
	if err != nil {
		return fmt.Errorf("parsing recipient address: %w", err)
	}

	ctx, cancel := context.WithTimeout(ctx, s.timeout)
	defer cancel()

	payload := resendSendEmailRequest{
		From:    strings.TrimSpace(s.from),
		To:      []string{to.Address},
		Subject: "Inflap verification code",
		Text:    buildEmailOTPText(code),
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("encoding Resend email payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.baseURL+"/emails", bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("creating Resend email request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+s.apiKey)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("sending email via Resend: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		responseBody, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		responseText := strings.TrimSpace(string(responseBody))
		if responseText == "" {
			responseText = http.StatusText(resp.StatusCode)
		}
		return fmt.Errorf("sending email via Resend: status %d: %s", resp.StatusCode, responseText)
	}

	var sent struct {
		ID string `json:"id"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&sent); err != nil && err != io.EOF {
		return fmt.Errorf("decoding Resend email response: %w", err)
	}

	s.logger.Info().
		Str("from", from.Address).
		Str("email", maskEmailForLog(to.Address)).
		Str("message_id", sent.ID).
		Msg("email OTP sent")
	return nil
}

type resendSendEmailRequest struct {
	From    string   `json:"from"`
	To      []string `json:"to"`
	Subject string   `json:"subject"`
	Text    string   `json:"text"`
}

func buildEmailOTPText(code string) string {
	return "Your Inflap verification code: " + strings.TrimSpace(code) + "\n\n" +
		"If you did not request this code, you can ignore this email.\n"
}

func maskEmailForLog(email string) string {
	email = strings.TrimSpace(email)
	parts := strings.Split(email, "@")
	if len(parts) != 2 || parts[0] == "" || parts[1] == "" {
		return "***"
	}
	if len(parts[0]) == 1 {
		return parts[0] + "***@" + parts[1]
	}
	return parts[0][:2] + "***@" + parts[1]
}
