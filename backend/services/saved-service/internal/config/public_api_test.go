package config

import "testing"

func TestPublicAPIConfigValidate(t *testing.T) {
	tests := []struct {
		name      string
		origin    string
		secure    bool
		wantError bool
	}{
		{name: "development HTTP", origin: "http://localhost:8080"},
		{name: "production HTTPS", origin: "https://api.inflap.example", secure: true},
		{name: "production plaintext", origin: "http://api.inflap.example", secure: true, wantError: true},
		{name: "credentials", origin: "https://user:pass@api.inflap.example", wantError: true},
		{name: "path", origin: "https://api.inflap.example/api", wantError: true},
		{name: "query", origin: "https://api.inflap.example?redirect=evil", wantError: true},
		{name: "surrounding whitespace", origin: " https://api.inflap.example ", wantError: true},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			err := (PublicAPIConfig{Origin: test.origin}).Validate(test.secure)
			if (err != nil) != test.wantError {
				t.Fatalf("Validate() error = %v, wantError %v", err, test.wantError)
			}
		})
	}
}
