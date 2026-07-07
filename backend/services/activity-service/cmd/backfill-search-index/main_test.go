package main

import (
	"os"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/activity-service/internal/config"
)

func TestActivitySearchBackfillCommandUsesDomainBackfillUseCase(t *testing.T) {
	source, err := os.ReadFile("main.go")
	if err != nil {
		t.Fatalf("read search backfill command source: %v", err)
	}
	code := string(source)
	for _, needle := range []string{
		"flag.Bool(\"dry-run\"",
		"flag.Int(\"batch-size\"",
		"flag.Int(\"limit\"",
		"flag.Bool(\"delete-stale\"",
		"repository.NewPGActivityRepository(pool)",
		"searchindexadapter.New(",
		"app.BackfillActivitySearchIndex(",
		"dry_run",
		"delete_stale",
	} {
		if !strings.Contains(code, needle) {
			t.Fatalf("activity search backfill command must contain %q", needle)
		}
	}
}

func TestActivitySearchBackfillHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newSearchIndexHTTPClient(&config.Config{
		SearchService: config.SearchServiceConfig{
			HTTPURL: "http://search-service:8101",
			Timeout: 250 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newSearchIndexHTTPClient() error = %v", err)
	}
	if client.Timeout != 250*time.Millisecond {
		t.Fatalf("client timeout = %s, want 250ms", client.Timeout)
	}
	if client.Transport != nil {
		t.Fatalf("client transport = %#v, want nil default transport for disabled mTLS", client.Transport)
	}
}

func TestActivitySearchBackfillHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newSearchIndexHTTPClient(&config.Config{
		SearchService: config.SearchServiceConfig{
			HTTPURL: "https://search-service:8101",
			Timeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newSearchIndexHTTPClient() error = nil, want missing CA error")
	}
}

func TestActivitySearchBackfillCommandIsPackagedForOneShotRollout(t *testing.T) {
	dockerfile, err := os.ReadFile("../../Dockerfile")
	if err != nil {
		t.Fatalf("read activity-service Dockerfile: %v", err)
	}
	dockerfileText := string(dockerfile)
	for _, needle := range []string{
		"go build -ldflags=\"-s -w\" -o /bin/activity-service-backfill-search-index ./cmd/backfill-search-index",
		"COPY --from=builder /bin/activity-service-backfill-search-index /app/activity-service-backfill-search-index",
	} {
		if !strings.Contains(dockerfileText, needle) {
			t.Fatalf("Dockerfile must package activity search backfill command %q", needle)
		}
	}

	makefile, err := os.ReadFile("../../Makefile")
	if err != nil {
		t.Fatalf("read activity-service Makefile: %v", err)
	}
	makefileText := string(makefile)
	for _, needle := range []string{
		"build-backfill-search-index:",
		"backfill-search-index:",
		"go run ./cmd/backfill-search-index",
	} {
		if !strings.Contains(makefileText, needle) {
			t.Fatalf("Makefile must expose activity search backfill command %q", needle)
		}
	}
}

func TestActivitySearchBackfillCommandIsAvailableInComposeProfiles(t *testing.T) {
	for _, path := range []string{
		"../../../../../deploy/docker-compose.yml",
		"../../../../../infra/test/docker-compose.test.yml",
	} {
		compose, err := os.ReadFile(path)
		if err != nil {
			t.Fatalf("read compose file %s: %v", path, err)
		}
		composeText := string(compose)
		for _, needle := range []string{
			"activity-search-backfill:",
			"profiles:",
			"search-backfill",
			"/app/activity-service-backfill-search-index",
		} {
			if !strings.Contains(composeText, needle) {
				t.Fatalf("%s must expose activity search backfill profile service %q", path, needle)
			}
		}
	}
}
