package config

import (
	"context"
	"os"
	"testing"
	"time"
)

func TestLoadUsesResendEmailDefaults(t *testing.T) {
	unsetEnvForTest(t, "EMAIL_OTP_FROM_ADDRESS")
	unsetEnvForTest(t, "RESEND_API_KEY")
	unsetEnvForTest(t, "RESEND_BASE_URL")
	unsetEnvForTest(t, "RESEND_TIMEOUT")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.Email.OTPFromAddress != "Inflap <onboarding@resend.dev>" {
		t.Fatalf("OTPFromAddress = %q, want Resend dev sender", cfg.Email.OTPFromAddress)
	}
	if cfg.Email.ResendAPIKey != "" {
		t.Fatalf("ResendAPIKey = %q, want empty default", cfg.Email.ResendAPIKey)
	}
	if cfg.Email.ResendBaseURL != "https://api.resend.com" {
		t.Fatalf("ResendBaseURL = %q, want Resend API URL", cfg.Email.ResendBaseURL)
	}
	if cfg.Email.ResendTimeout != 8*time.Second {
		t.Fatalf("ResendTimeout = %s, want 8s", cfg.Email.ResendTimeout)
	}
}

func TestLoadAcceptsResendEmailOverrides(t *testing.T) {
	t.Setenv("EMAIL_OTP_FROM_ADDRESS", "Inflap <verified@example.com>")
	t.Setenv("RESEND_API_KEY", "re_test_key")
	t.Setenv("RESEND_BASE_URL", "https://api.resend.test")
	t.Setenv("RESEND_TIMEOUT", "3s")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.Email.OTPFromAddress != "Inflap <verified@example.com>" {
		t.Fatalf("OTPFromAddress = %q, want configured sender", cfg.Email.OTPFromAddress)
	}
	if cfg.Email.ResendAPIKey != "re_test_key" {
		t.Fatalf("ResendAPIKey = %q, want configured API key", cfg.Email.ResendAPIKey)
	}
	if cfg.Email.ResendBaseURL != "https://api.resend.test" {
		t.Fatalf("ResendBaseURL = %q, want configured base URL", cfg.Email.ResendBaseURL)
	}
	if cfg.Email.ResendTimeout != 3*time.Second {
		t.Fatalf("ResendTimeout = %s, want configured timeout", cfg.Email.ResendTimeout)
	}
}

func unsetEnvForTest(t *testing.T, key string) {
	t.Helper()

	value, ok := os.LookupEnv(key)
	if err := os.Unsetenv(key); err != nil {
		t.Fatalf("unset %s: %v", key, err)
	}
	t.Cleanup(func() {
		if ok {
			_ = os.Setenv(key, value)
			return
		}
		_ = os.Unsetenv(key)
	})
}
