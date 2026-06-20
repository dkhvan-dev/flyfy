package main

import "testing"

func TestHandleCacheInvalidationClearsBothCaches(t *testing.T) {
	feature := &fakeCacheInvalidator{}
	tech := &fakeCacheInvalidator{}

	handleCacheInvalidation("all", feature, tech)

	if feature.clears != 1 {
		t.Fatalf("feature cache clears = %d, want 1", feature.clears)
	}
	if tech.clears != 1 {
		t.Fatalf("tech break cache clears = %d, want 1", tech.clears)
	}
}

func TestHandleCacheInvalidationIgnoresUnknownPayload(t *testing.T) {
	feature := &fakeCacheInvalidator{}
	tech := &fakeCacheInvalidator{}

	handleCacheInvalidation("unknown", feature, tech)

	if feature.clears != 0 {
		t.Fatalf("feature cache clears = %d, want 0", feature.clears)
	}
	if tech.clears != 0 {
		t.Fatalf("tech break cache clears = %d, want 0", tech.clears)
	}
}

type fakeCacheInvalidator struct {
	clears int
}

func (i *fakeCacheInvalidator) ClearCache() {
	i.clears++
}
