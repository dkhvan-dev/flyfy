package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/guide-service/internal/config"
)

func TestNewFraudEvaluatorKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	evaluator, err := newFraudEvaluator(&config.Config{
		AntiFraud: config.AntiFraudConfig{
			Enabled:              true,
			BaseURL:              "http://anti-fraud-service:8096",
			InternalServiceToken: "internal-token",
			SignalHashKey:        "hash-key",
		},
	})
	if err != nil {
		t.Fatalf("newFraudEvaluator() error = %v", err)
	}
	if evaluator == nil {
		t.Fatal("newFraudEvaluator() = nil, want evaluator")
	}
}

func TestNewFraudEvaluatorFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newFraudEvaluator(&config.Config{
		AntiFraud: config.AntiFraudConfig{
			Enabled:              true,
			BaseURL:              "http://anti-fraud-service:8096",
			InternalServiceToken: "internal-token",
			SignalHashKey:        "hash-key",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newFraudEvaluator() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize anti-fraud mTLS transport") {
		t.Fatalf("error = %q, want anti-fraud mTLS context", err)
	}
}
