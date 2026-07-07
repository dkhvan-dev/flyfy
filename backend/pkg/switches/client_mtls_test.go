package switches

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
)

func TestNewHTTPClientFailsFastWhenTransportAuthEnforceWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := NewHTTPClient(HTTPClientConfig{
		BaseURL: "https://switches-service:9446",
		Timeout: time.Second,
		TransportAuth: transportauth.Config{
			Mode: transportauth.ModeEnforce,
		},
	})
	if err == nil {
		t.Fatal("NewHTTPClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize switches mTLS transport") {
		t.Fatalf("error = %q, want switches mTLS context", err)
	}
}
