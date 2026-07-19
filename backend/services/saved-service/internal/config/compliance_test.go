package config

import "testing"

func TestComplianceConfigValidation(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		value  string
		secure bool
		valid  bool
	}{
		{name: "development", value: "spiffe://inflap/dev/user-service", valid: true},
		{name: "production", value: "spiffe://inflap/production/user-service", secure: true, valid: true},
		{name: "gateway forbidden", value: "spiffe://inflap/production/api-gateway", secure: true},
		{name: "development identity forbidden in production", value: "spiffe://inflap/dev/user-service", secure: true},
		{name: "query forbidden", value: "spiffe://inflap/production/user-service?role=admin", secure: true},
		{name: "http forbidden", value: "https://inflap/production/user-service", secure: true},
	}
	for _, test := range tests {
		test := test
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			err := (ComplianceConfig{AllowedCallerSPIFFEID: test.value}).Validate(test.secure)
			if (err == nil) != test.valid {
				t.Fatalf("Validate() error=%v valid=%v", err, test.valid)
			}
		})
	}
}
