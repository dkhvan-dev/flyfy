package app

import (
	"context"
	"strings"
	"testing"
)

func TestRebuildFromJSONLinesUpsertsMatchingDocuments(t *testing.T) {
	repo := &fakeIndexRepository{}
	uc := NewRebuildUseCase(NewIndexingUseCase(repo))
	input := strings.NewReader(`
{"domain":"place","entityId":"place-1","locale":"ru","title":{"ru":"Алматы"},"countryCode":"KZ","cityId":"almaty","deepLink":"/places/place-1"}
{"domain":"guide","entityId":"guide-1","locale":"ru","title":{"ru":"Гид"},"countryCode":"KZ","deepLink":"/guides/guide-1"}
`)

	stats, err := uc.RebuildFromJSONLines(context.Background(), input, RebuildOptions{
		Domain:      "place",
		CountryCode: "kz",
		CityID:      " almaty ",
	})
	if err != nil {
		t.Fatalf("RebuildFromJSONLines returned error: %v", err)
	}
	if stats.Scanned != 2 || stats.Upserted != 1 || stats.Skipped != 1 {
		t.Fatalf("stats = %+v, want scanned 2 upserted 1 skipped 1", stats)
	}
	if repo.upsertCalls != 1 {
		t.Fatalf("upsert calls = %d, want 1", repo.upsertCalls)
	}
	if repo.lastDocument.Domain != "place" || repo.lastDocument.EntityID != "place-1" {
		t.Fatalf("last document = %+v", repo.lastDocument)
	}
}

func TestRebuildFromJSONLinesDryRunDoesNotUpsert(t *testing.T) {
	repo := &fakeIndexRepository{}
	uc := NewRebuildUseCase(NewIndexingUseCase(repo))
	input := strings.NewReader(`{"domain":"user","entityId":"user-1","title":{"en":"Ada"},"deepLink":"/users/user-1"}`)

	stats, err := uc.RebuildFromJSONLines(context.Background(), input, RebuildOptions{
		DryRun: true,
	})
	if err != nil {
		t.Fatalf("RebuildFromJSONLines returned error: %v", err)
	}
	if stats.Scanned != 1 || stats.Upserted != 0 || stats.Skipped != 0 || stats.DryRunValidated != 1 {
		t.Fatalf("stats = %+v", stats)
	}
	if repo.upsertCalls != 0 {
		t.Fatalf("upsert calls = %d, want 0", repo.upsertCalls)
	}
}
