package otp

import (
	"io"
	"testing"

	"github.com/rs/zerolog"
)

func TestNewEmailOTPSenderFallsBackToLogSenderWhenSMTPPasswordMissing(t *testing.T) {
	sender := NewEmailOTPSender(EmailSenderConfig{
		FromAddress:  DefaultDevEmailOTPSenderAddress,
		SMTPHost:     "smtp.gmail.com",
		SMTPPort:     587,
		SMTPUsername: DefaultDevEmailOTPSenderAddress,
	}, zerolog.New(io.Discard))

	if _, ok := sender.(*LogEmailOTPSender); !ok {
		t.Fatalf("NewEmailOTPSender() = %T, want *LogEmailOTPSender without SMTP password", sender)
	}
}

func TestNewEmailOTPSenderUsesSMTPWhenConfigured(t *testing.T) {
	sender := NewEmailOTPSender(EmailSenderConfig{
		FromAddress:  "Inflap <dkhvan.developer@gmail.com>",
		SMTPHost:     "smtp.gmail.com",
		SMTPPort:     587,
		SMTPUsername: "dkhvan.developer@gmail.com",
		SMTPPassword: "app-password",
	}, zerolog.New(io.Discard))

	smtpSender, ok := sender.(*SMTPEmailOTPSender)
	if !ok {
		t.Fatalf("NewEmailOTPSender() = %T, want *SMTPEmailOTPSender with SMTP credentials", sender)
	}
	if smtpSender.from != "Inflap <dkhvan.developer@gmail.com>" {
		t.Fatalf("SMTP sender from = %q, want configured from address", smtpSender.from)
	}
}
