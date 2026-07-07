package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"kz/inflap/backend/pkg/transportauth"
)

type Config struct {
	App          AppConfig
	HTTP         HTTPConfig
	DB           DBConfig
	Chat         ChatConfig
	Notification NotificationConfig
	UserContext  UserContextConfig
	Security     SecurityConfig
	MTLS         transportauth.EnvConfig
}

type AppConfig struct {
	Name string
}

type HTTPConfig struct {
	Port            int
	InternalTLSPort int
	ReadTimeout     time.Duration
	WriteTimeout    time.Duration
	IdleTimeout     time.Duration
}

type DBConfig struct {
	URL string
}

type ChatConfig struct {
	ServiceURL     string
	Timeout        time.Duration
	SupportSubject string
}

type NotificationConfig struct {
	ServiceURL       string
	Timeout          time.Duration
	OperatorUserIDs  []string
	SLAAlertInterval time.Duration
}

type UserContextConfig struct {
	UserServiceURL         string
	GuideServiceURL        string
	Timeout                time.Duration
	SegmentRefreshInterval time.Duration
}

type SecurityConfig struct {
	InternalServiceToken string
}

func (c DBConfig) Enabled() bool {
	return c.URL != ""
}

func (c ChatConfig) Enabled() bool {
	return c.ServiceURL != "" && c.SupportSubject != ""
}

func (c NotificationConfig) Enabled() bool {
	return c.ServiceURL != ""
}

func (c NotificationConfig) OperatorAlertsEnabled() bool {
	return c.Enabled() && len(c.OperatorUserIDs) > 0
}

func (c UserContextConfig) Enabled() bool {
	return strings.TrimSpace(c.UserServiceURL) != ""
}

func (c HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", c.Port)
}

func (c HTTPConfig) InternalTLSAddress() string {
	return fmt.Sprintf(":%d", c.InternalTLSPort)
}

func Load() (Config, error) {
	port, err := envInt("SUPPORT_SERVICE_HTTP_PORT", 8100)
	if err != nil {
		return Config{}, err
	}
	internalTLSPort, err := envOptionalPort("INTERNAL_HTTP_TLS_PORT", 0)
	if err != nil {
		return Config{}, err
	}
	readTimeout, err := envDuration("SUPPORT_SERVICE_HTTP_READ_TIMEOUT", 5*time.Second)
	if err != nil {
		return Config{}, err
	}
	writeTimeout, err := envDuration("SUPPORT_SERVICE_HTTP_WRITE_TIMEOUT", 10*time.Second)
	if err != nil {
		return Config{}, err
	}
	idleTimeout, err := envDuration("SUPPORT_SERVICE_HTTP_IDLE_TIMEOUT", 60*time.Second)
	if err != nil {
		return Config{}, err
	}
	databaseURL := os.Getenv("SUPPORT_SERVICE_DATABASE_URL")
	chatTimeout, err := envDuration("SUPPORT_SERVICE_CHAT_SERVICE_TIMEOUT", 5*time.Second)
	if err != nil {
		return Config{}, err
	}
	notificationTimeout, err := envDuration("SUPPORT_SERVICE_NOTIFICATION_SERVICE_TIMEOUT", 3*time.Second)
	if err != nil {
		return Config{}, err
	}
	slaAlertInterval, err := envDuration("SUPPORT_SERVICE_SLA_ALERT_INTERVAL", time.Minute)
	if err != nil {
		return Config{}, err
	}
	userContextTimeout, err := envDuration("SUPPORT_SERVICE_USER_CONTEXT_TIMEOUT", 3*time.Second)
	if err != nil {
		return Config{}, err
	}
	segmentRefreshInterval, err := envDuration("SUPPORT_SERVICE_SEGMENT_REFRESH_INTERVAL", 5*time.Minute)
	if err != nil {
		return Config{}, err
	}

	return Config{
		App: AppConfig{Name: "support-service"},
		HTTP: HTTPConfig{
			Port:            port,
			InternalTLSPort: internalTLSPort,
			ReadTimeout:     readTimeout,
			WriteTimeout:    writeTimeout,
			IdleTimeout:     idleTimeout,
		},
		DB: DBConfig{URL: databaseURL},
		Chat: ChatConfig{
			ServiceURL:     os.Getenv("SUPPORT_SERVICE_CHAT_SERVICE_URL"),
			Timeout:        chatTimeout,
			SupportSubject: os.Getenv("SUPPORT_SERVICE_CHAT_SUPPORT_SUBJECT"),
		},
		Notification: NotificationConfig{
			ServiceURL:       notificationServiceURL(),
			Timeout:          notificationTimeout,
			OperatorUserIDs:  splitCSV(os.Getenv("SUPPORT_SERVICE_OPERATOR_NOTIFICATION_USER_IDS")),
			SLAAlertInterval: slaAlertInterval,
		},
		UserContext: UserContextConfig{
			UserServiceURL:         os.Getenv("SUPPORT_SERVICE_USER_SERVICE_URL"),
			GuideServiceURL:        os.Getenv("SUPPORT_SERVICE_GUIDE_SERVICE_URL"),
			Timeout:                userContextTimeout,
			SegmentRefreshInterval: segmentRefreshInterval,
		},
		Security: SecurityConfig{
			InternalServiceToken: os.Getenv("SUPPORT_SERVICE_INTERNAL_SERVICE_TOKEN"),
		},
		MTLS: loadMTLSConfig(),
	}, nil
}

func loadMTLSConfig() transportauth.EnvConfig {
	return transportauth.EnvConfig{
		Mode:             envString("MTLS_MODE", "disabled"),
		CACertPath:       os.Getenv("MTLS_CA_CERT_PATH"),
		ServerCertPath:   os.Getenv("MTLS_SERVER_CERT_PATH"),
		ServerKeyPath:    os.Getenv("MTLS_SERVER_KEY_PATH"),
		ClientCertPath:   os.Getenv("MTLS_CLIENT_CERT_PATH"),
		ClientKeyPath:    os.Getenv("MTLS_CLIENT_KEY_PATH"),
		ServerName:       os.Getenv("MTLS_SERVER_NAME"),
		AllowedSPIFFEIDs: os.Getenv("MTLS_ALLOWED_SPIFFE_IDS"),
		AllowedDNSNames:  os.Getenv("MTLS_ALLOWED_DNS_NAMES"),
	}
}

func envString(name string, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func envInt(name string, fallback int) (int, error) {
	value := os.Getenv(name)
	if value == "" {
		return fallback, nil
	}
	parsed, err := strconv.Atoi(value)
	if err != nil || parsed <= 0 || parsed > 65535 {
		return 0, fmt.Errorf("invalid %s", name)
	}
	return parsed, nil
}

func envOptionalPort(name string, fallback int) (int, error) {
	value := os.Getenv(name)
	if value == "" {
		return fallback, nil
	}
	parsed, err := strconv.Atoi(value)
	if err != nil || parsed < 0 || parsed > 65535 {
		return 0, fmt.Errorf("invalid %s", name)
	}
	return parsed, nil
}

func notificationServiceURL() string {
	if value := os.Getenv("SUPPORT_SERVICE_NOTIFICATION_SERVICE_URL"); value != "" {
		return value
	}
	return os.Getenv("NOTIFICATION_SERVICE_HTTP_URL")
}

func splitCSV(raw string) []string {
	if raw == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	seen := make(map[string]struct{}, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		if _, ok := seen[part]; ok {
			continue
		}
		seen[part] = struct{}{}
		out = append(out, part)
	}
	return out
}

func envDuration(name string, fallback time.Duration) (time.Duration, error) {
	value := os.Getenv(name)
	if value == "" {
		return fallback, nil
	}
	parsed, err := time.ParseDuration(value)
	if err != nil || parsed <= 0 {
		return 0, fmt.Errorf("invalid %s", name)
	}
	return parsed, nil
}
