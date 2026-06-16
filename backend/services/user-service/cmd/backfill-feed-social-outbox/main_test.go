package main

import (
	"os"
	"strings"
	"testing"
)

func TestBackfillCommandEnqueuesExistingSocialEdgesIdempotently(t *testing.T) {
	source, err := os.ReadFile("main.go")
	if err != nil {
		t.Fatalf("read backfill command source: %v", err)
	}
	code := string(source)
	for _, needle := range []string{
		"repository.NewPGUserRepository(pool)",
		"BackfillFeedSocialOutbox(ctx, time.Now().UTC())",
	} {
		if !strings.Contains(code, needle) {
			t.Fatalf("backfill command must contain %q", needle)
		}
	}
}

func TestBackfillCommandIsPackagedForOneShotRollout(t *testing.T) {
	dockerfile, err := os.ReadFile("../../Dockerfile")
	if err != nil {
		t.Fatalf("read user-service Dockerfile: %v", err)
	}
	dockerfileText := string(dockerfile)
	for _, needle := range []string{
		"go build -o user-service-backfill-feed-social-outbox ./cmd/backfill-feed-social-outbox",
		"COPY --from=builder /app/backend/services/user-service/user-service-backfill-feed-social-outbox /opt/app/user-service-backfill-feed-social-outbox",
	} {
		if !strings.Contains(dockerfileText, needle) {
			t.Fatalf("Dockerfile must package backfill command %q", needle)
		}
	}

	makefile, err := os.ReadFile("../../Makefile")
	if err != nil {
		t.Fatalf("read user-service Makefile: %v", err)
	}
	makefileText := string(makefile)
	for _, needle := range []string{
		"build-backfill-feed-social-outbox:",
		"backfill-feed-social-outbox:",
		"go run ./cmd/backfill-feed-social-outbox",
		"backfill-feed-social-outbox-drain:",
		"go run ./cmd/backfill-feed-social-outbox -drain",
	} {
		if !strings.Contains(makefileText, needle) {
			t.Fatalf("Makefile must expose backfill command %q", needle)
		}
	}
}

func TestBackfillCommandCanDrainOutboxForOneShotReadModelSync(t *testing.T) {
	source, err := os.ReadFile("main.go")
	if err != nil {
		t.Fatalf("read backfill command source: %v", err)
	}
	code := string(source)
	for _, needle := range []string{
		"drain := flag.Bool(\"drain\"",
		"maxDrainBatches := flag.Int(\"max-drain-batches\"",
		"0 means drain until the outbox is empty",
		"drainFeedSocialOutbox",
		"app.NewUserSocialOutboxWorker",
		"feedserviceadapter.New",
		"worker.ProcessOnce",
		"drained_events",
	} {
		if !strings.Contains(code, needle) {
			t.Fatalf("backfill command must contain drain support %q", needle)
		}
	}
}

func TestBackfillDrainCanRunUntilOutboxIsEmpty(t *testing.T) {
	source, err := os.ReadFile("main.go")
	if err != nil {
		t.Fatalf("read backfill command source: %v", err)
	}
	code := string(source)
	for _, needle := range []string{
		"maxDrainBatches < 0",
		"if maxBatches > 0 && batches >= maxBatches",
		"stats.Fetched == 0",
	} {
		if !strings.Contains(code, needle) {
			t.Fatalf("backfill drain loop must contain %q", needle)
		}
	}
}
