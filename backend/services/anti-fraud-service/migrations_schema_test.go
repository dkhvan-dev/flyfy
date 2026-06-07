package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestMigrationsAllowLongRiskEventIdempotencyKeys(t *testing.T) {
	entries, err := os.ReadDir("migrations")
	if err != nil {
		t.Fatalf("read migrations: %v", err)
	}

	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".up.sql") {
			continue
		}
		body, err := os.ReadFile(filepath.Join("migrations", entry.Name()))
		if err != nil {
			t.Fatalf("read migration %s: %v", entry.Name(), err)
		}
		normalized := strings.Join(strings.Fields(strings.ToLower(string(body))), " ")
		if strings.Contains(normalized, "alter table risk_events") &&
			strings.Contains(normalized, "alter column idempotency_key") &&
			strings.Contains(normalized, "type text") {
			return
		}
	}

	t.Fatal("missing migration expanding risk_events.idempotency_key to text")
}
