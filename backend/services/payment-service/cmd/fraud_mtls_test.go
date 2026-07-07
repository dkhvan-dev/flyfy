package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/payment-service/internal/config"
)

func TestNewFraudDecisionPortKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	evaluator, err := newFraudDecisionPort(&config.Config{
		AntiFraud: config.AntiFraudConfig{
			Enabled:              true,
			BaseURL:              "http://anti-fraud-service:8096",
			InternalServiceToken: "internal-token",
		},
	})
	if err != nil {
		t.Fatalf("newFraudDecisionPort() error = %v", err)
	}
	if evaluator == nil {
		t.Fatal("newFraudDecisionPort() = nil, want evaluator")
	}
}

func TestNewFraudDecisionPortFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newFraudDecisionPort(&config.Config{
		AntiFraud: config.AntiFraudConfig{
			Enabled:              true,
			BaseURL:              "http://anti-fraud-service:8096",
			InternalServiceToken: "internal-token",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newFraudDecisionPort() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize anti-fraud mTLS transport") {
		t.Fatalf("error = %q, want anti-fraud mTLS context", err)
	}
}
