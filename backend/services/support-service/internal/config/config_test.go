package config

import (
	"testing"
	"time"
)

func TestLoadUsesProductionSafeDefaults(t *testing.T) {
	t.Setenv("SUPPORT_SERVICE_HTTP_PORT", "")
	t.Setenv("SUPPORT_SERVICE_HTTP_READ_TIMEOUT", "")
	t.Setenv("SUPPORT_SERVICE_HTTP_WRITE_TIMEOUT", "")
	t.Setenv("SUPPORT_SERVICE_HTTP_IDLE_TIMEOUT", "")
	t.Setenv("SUPPORT_SERVICE_DATABASE_URL", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.App.Name != "support-service" {
		t.Fatalf("app name = %q", cfg.App.Name)
	}
	if cfg.HTTP.Port != 8100 {
		t.Fatalf("port = %d, want 8100", cfg.HTTP.Port)
	}
	if cfg.HTTP.Address() != ":8100" {
		t.Fatalf("address = %q, want :8100", cfg.HTTP.Address())
	}
	if cfg.HTTP.ReadTimeout != 5*time.Second {
		t.Fatalf("read timeout = %s, want 5s", cfg.HTTP.ReadTimeout)
	}
	if cfg.DB.Enabled() {
		t.Fatalf("database should be disabled by default, got %#v", cfg.DB)
	}
	if cfg.UserContext.Enabled() {
		t.Fatalf("user context resolver should be disabled by default, got %#v", cfg.UserContext)
	}
}

func TestLoadParsesEnvironmentOverrides(t *testing.T) {
	t.Setenv("SUPPORT_SERVICE_HTTP_PORT", "8197")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9197")
	t.Setenv("SUPPORT_SERVICE_HTTP_READ_TIMEOUT", "3s")
	t.Setenv("SUPPORT_SERVICE_HTTP_WRITE_TIMEOUT", "4s")
	t.Setenv("SUPPORT_SERVICE_HTTP_IDLE_TIMEOUT", "30s")
	t.Setenv("SUPPORT_SERVICE_DATABASE_URL", "postgres://support-service.local/support?sslmode=disable")
	t.Setenv("SUPPORT_SERVICE_NOTIFICATION_SERVICE_URL", "http://notification-service:8097")
	t.Setenv("SUPPORT_SERVICE_NOTIFICATION_SERVICE_TIMEOUT", "2s")
	t.Setenv("SUPPORT_SERVICE_OPERATOR_NOTIFICATION_USER_IDS", "11111111-1111-4111-8111-111111111111, 22222222-2222-4222-8222-222222222222")
	t.Setenv("SUPPORT_SERVICE_SLA_ALERT_INTERVAL", "45s")
	t.Setenv("SUPPORT_SERVICE_USER_SERVICE_URL", "http://user-service:8084")
	t.Setenv("SUPPORT_SERVICE_GUIDE_SERVICE_URL", "http://guide-service:8085")
	t.Setenv("SUPPORT_SERVICE_USER_CONTEXT_TIMEOUT", "1500ms")
	t.Setenv("SUPPORT_SERVICE_SEGMENT_REFRESH_INTERVAL", "2m")
	t.Setenv("SUPPORT_SERVICE_SEARCH_INDEXING_ENABLED", "true")
	t.Setenv("SEARCH_SERVICE_HTTP_URL", "http://search-service:8101")
	t.Setenv("SEARCH_SERVICE_TIMEOUT", "900ms")
	t.Setenv("TOKEN_SERVICE_GRPC_TARGET", "dns:///token-service:50051")
	t.Setenv("TOKEN_SERVICE_ID", "support-service")
	t.Setenv("TOKEN_SERVICE_SECRET", "support-secret")
	t.Setenv("TOKEN_SERVICE_CALL_TIMEOUT", "2500ms")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.HTTP.Port != 8197 {
		t.Fatalf("port = %d, want 8197", cfg.HTTP.Port)
	}
	if cfg.HTTP.InternalTLSPort != 9197 {
		t.Fatalf("internal TLS port = %d, want 9197", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9197" {
		t.Fatalf("internal TLS address = %q, want :9197", cfg.HTTP.InternalTLSAddress())
	}
	if cfg.HTTP.ReadTimeout != 3*time.Second {
		t.Fatalf("read timeout = %s, want 3s", cfg.HTTP.ReadTimeout)
	}
	if cfg.HTTP.WriteTimeout != 4*time.Second {
		t.Fatalf("write timeout = %s, want 4s", cfg.HTTP.WriteTimeout)
	}
	if cfg.HTTP.IdleTimeout != 30*time.Second {
		t.Fatalf("idle timeout = %s, want 30s", cfg.HTTP.IdleTimeout)
	}
	if !cfg.DB.Enabled() {
		t.Fatal("database should be enabled when SUPPORT_SERVICE_DATABASE_URL is set")
	}
	if cfg.DB.URL != "postgres://support-service.local/support?sslmode=disable" {
		t.Fatalf("database url = %q", cfg.DB.URL)
	}
	if !cfg.Notification.Enabled() {
		t.Fatalf("notification config should be enabled: %#v", cfg.Notification)
	}
	if cfg.Notification.ServiceURL != "http://notification-service:8097" || cfg.Notification.Timeout != 2*time.Second {
		t.Fatalf("notification config = %#v", cfg.Notification)
	}
	if len(cfg.Notification.OperatorUserIDs) != 2 || cfg.Notification.OperatorUserIDs[0] != "11111111-1111-4111-8111-111111111111" {
		t.Fatalf("operator ids = %#v", cfg.Notification.OperatorUserIDs)
	}
	if cfg.Notification.SLAAlertInterval != 45*time.Second {
		t.Fatalf("SLA alert interval = %s", cfg.Notification.SLAAlertInterval)
	}
	if !cfg.UserContext.Enabled() ||
		cfg.UserContext.UserServiceURL != "http://user-service:8084" ||
		cfg.UserContext.GuideServiceURL != "http://guide-service:8085" ||
		cfg.UserContext.Timeout != 1500*time.Millisecond ||
		cfg.UserContext.SegmentRefreshInterval != 2*time.Minute {
		t.Fatalf("user context config = %#v", cfg.UserContext)
	}
	if !cfg.SearchService.Enabled ||
		cfg.SearchService.HTTPURL != "http://search-service:8101" ||
		cfg.SearchService.Timeout != 900*time.Millisecond {
		t.Fatalf("search service config = %#v", cfg.SearchService)
	}
	if !cfg.TokenService.Enabled() ||
		cfg.TokenService.Target != "dns:///token-service:50051" ||
		cfg.TokenService.ServiceID != "support-service" ||
		cfg.TokenService.ServiceSecret != "support-secret" ||
		cfg.TokenService.CallTimeout != 2500*time.Millisecond {
		t.Fatalf("token service config = %#v", cfg.TokenService)
	}
}

func TestNotificationConfigEnabledDoesNotRequireOperatorRecipients(t *testing.T) {
	cfg := NotificationConfig{
		ServiceURL:      "http://notification-service:8097",
		OperatorUserIDs: nil,
	}

	if !cfg.Enabled() {
		t.Fatal("notification config should be enabled for user notifications when service url is set")
	}
	if cfg.OperatorAlertsEnabled() {
		t.Fatal("operator alerts should be disabled without operator recipients")
	}
}

func TestLoadRejectsInvalidPort(t *testing.T) {
	t.Setenv("SUPPORT_SERVICE_HTTP_PORT", "not-a-port")

	_, err := Load()
	if err == nil {
		t.Fatal("expected invalid port error")
	}
}

func TestLoadAllowsDisabledInternalTLSPort(t *testing.T) {
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "0")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.HTTP.InternalTLSPort != 0 {
		t.Fatalf("internal TLS port = %d, want 0", cfg.HTTP.InternalTLSPort)
	}
}
