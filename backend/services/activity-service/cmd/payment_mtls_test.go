package main

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/activity-service/internal/config"
)

func TestNewPaymentServiceClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newPaymentServiceClient(&config.Config{
		Payment: config.PaymentServiceConfig{
			HTTPURL: "http://payment-service:8091",
		},
	})
	if err != nil {
		t.Fatalf("newPaymentServiceClient() error = %v", err)
	}
	if client == nil {
		t.Fatal("newPaymentServiceClient() = nil, want client")
	}
}

func TestNewPaymentServiceClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newPaymentServiceClient(&config.Config{
		Payment: config.PaymentServiceConfig{
			HTTPURL: "https://payment-service:9441",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newPaymentServiceClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize payment-service mTLS transport") {
		t.Fatalf("error = %q, want payment-service mTLS context", err)
	}
}
