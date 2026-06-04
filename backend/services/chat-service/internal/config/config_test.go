package config

import (
	"context"
	"testing"
	"time"
)

func TestLoadNotificationServiceDefaults(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load error: %v", err)
	}
	if cfg.Notification.HTTPURL != "http://notification-service:8097" {
		t.Fatalf("Notification.HTTPURL = %q", cfg.Notification.HTTPURL)
	}
	if cfg.Notification.RequestTimeout != 3*time.Second {
		t.Fatalf("Notification.RequestTimeout = %s", cfg.Notification.RequestTimeout)
	}
}
