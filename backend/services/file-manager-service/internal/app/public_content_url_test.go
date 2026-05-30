package app

import (
	"testing"
	"time"
)

func TestBuildPublicObjectURLEscapesObjectKeySegments(t *testing.T) {
	got, err := buildPublicObjectURL(
		"https://cdn.inflap.test/inflap-files/",
		"activity media/2026/05/28/image one.jpg",
	)
	if err != nil {
		t.Fatalf("buildPublicObjectURL() error = %v", err)
	}

	const want = "https://cdn.inflap.test/inflap-files/activity%20media/2026/05/28/image%20one.jpg"
	if got != want {
		t.Fatalf("url = %q, want %q", got, want)
	}
}

func TestPublicContentCacheControlUsesImmutablePublicCaching(t *testing.T) {
	got := publicContentCacheControl(2 * time.Hour)
	const want = "public, max-age=7200, immutable"
	if got != want {
		t.Fatalf("cache control = %q, want %q", got, want)
	}
}
