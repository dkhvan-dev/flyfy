package otp

import (
	"bytes"
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"net/mail"
	"net/smtp"
	"strconv"
	"strings"
	"time"

	"github.com/rs/zerolog"

	"kz/inflap/backend/services/auth-service/internal/domain/port"
)

const DefaultDevEmailOTPSenderAddress = "dkhvan.developer@gmail.com"
const defaultEmailSMTPTimeout = 8 * time.Second

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
// the use-case wired through a sender port while real SMTP/provider credentials
// are still intentionally kept out of source code.
type LogEmailOTPSender struct {
	from   string
	logger zerolog.Logger
}

type EmailSenderConfig struct {
	FromAddress  string
	SMTPHost     string
	SMTPPort     int
	SMTPUsername string
	SMTPPassword string
	SMTPTimeout  time.Duration
}

func NewEmailOTPSender(cfg EmailSenderConfig, logger zerolog.Logger) port.EmailOTPSender {
	if cfg.SMTPPort == 0 {
		cfg.SMTPPort = 587
	}
	if cfg.SMTPTimeout <= 0 {
		cfg.SMTPTimeout = defaultEmailSMTPTimeout
	}

	if strings.TrimSpace(cfg.SMTPHost) == "" ||
		strings.TrimSpace(cfg.SMTPUsername) == "" ||
		strings.TrimSpace(cfg.SMTPPassword) == "" {
		return NewLogEmailOTPSender(cfg.FromAddress, logger)
	}

	return NewSMTPEmailOTPSender(cfg, logger)
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

type SMTPEmailOTPSender struct {
	from     string
	host     string
	port     int
	username string
	password string
	timeout  time.Duration
	logger   zerolog.Logger
}

func NewSMTPEmailOTPSender(cfg EmailSenderConfig, logger zerolog.Logger) *SMTPEmailOTPSender {
	from := strings.TrimSpace(cfg.FromAddress)
	if from == "" {
		from = DefaultDevEmailOTPSenderAddress
	}
	port := cfg.SMTPPort
	if port == 0 {
		port = 587
	}
	timeout := cfg.SMTPTimeout
	if timeout <= 0 {
		timeout = defaultEmailSMTPTimeout
	}
	return &SMTPEmailOTPSender{
		from:     from,
		host:     strings.TrimSpace(cfg.SMTPHost),
		port:     port,
		username: strings.TrimSpace(cfg.SMTPUsername),
		password: strings.TrimSpace(cfg.SMTPPassword),
		timeout:  timeout,
		logger:   logger.With().Str("component", "email_otp_sender").Logger(),
	}
}

func (s *SMTPEmailOTPSender) SendEmailOTP(ctx context.Context, email, code string) error {
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

	addr := net.JoinHostPort(s.host, strconv.Itoa(s.port))
	dialer := net.Dialer{Timeout: s.timeout}
	conn, err := dialer.DialContext(ctx, "tcp", addr)
	if err != nil {
		return fmt.Errorf("connecting to SMTP server: %w", err)
	}
	defer conn.Close()
	if deadline, ok := ctx.Deadline(); ok {
		if err := conn.SetDeadline(deadline); err != nil {
			return fmt.Errorf("setting SMTP connection deadline: %w", err)
		}
	}

	client, err := smtp.NewClient(conn, s.host)
	if err != nil {
		return fmt.Errorf("creating SMTP client: %w", err)
	}
	defer client.Close()

	if ok, _ := client.Extension("STARTTLS"); ok {
		tlsConfig := &tls.Config{ServerName: s.host, MinVersion: tls.VersionTLS12}
		if err := client.StartTLS(tlsConfig); err != nil {
			return fmt.Errorf("starting SMTP TLS: %w", err)
		}
	}

	auth := smtp.PlainAuth("", s.username, s.password, s.host)
	if err := client.Auth(auth); err != nil {
		return fmt.Errorf("authenticating SMTP client: %w", err)
	}
	if err := client.Mail(from.Address); err != nil {
		return fmt.Errorf("setting SMTP sender: %w", err)
	}
	if err := client.Rcpt(to.Address); err != nil {
		return fmt.Errorf("setting SMTP recipient: %w", err)
	}

	writer, err := client.Data()
	if err != nil {
		return fmt.Errorf("opening SMTP data writer: %w", err)
	}
	if _, err := writer.Write(buildEmailOTPMessage(from.String(), to.String(), code)); err != nil {
		_ = writer.Close()
		return fmt.Errorf("writing SMTP message: %w", err)
	}
	if err := writer.Close(); err != nil {
		return fmt.Errorf("closing SMTP message writer: %w", err)
	}
	if err := client.Quit(); err != nil {
		return fmt.Errorf("quitting SMTP client: %w", err)
	}

	s.logger.Info().
		Str("from", from.Address).
		Str("email", maskEmailForLog(to.Address)).
		Msg("email OTP sent")
	return nil
}

func buildEmailOTPMessage(from, to, code string) []byte {
	var buf bytes.Buffer
	buf.WriteString("From: " + from + "\r\n")
	buf.WriteString("To: " + to + "\r\n")
	buf.WriteString("Subject: Inflap verification code\r\n")
	buf.WriteString("MIME-Version: 1.0\r\n")
	buf.WriteString("Content-Type: text/plain; charset=UTF-8\r\n")
	buf.WriteString("\r\n")
	buf.WriteString("Your Inflap verification code: " + strings.TrimSpace(code) + "\r\n")
	buf.WriteString("\r\n")
	buf.WriteString("If you did not request this code, you can ignore this email.\r\n")
	return buf.Bytes()
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
