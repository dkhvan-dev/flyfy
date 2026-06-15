package model

import (
	"fmt"
	"testing"
)

func TestHyperLogLogDeduplicatesValues(t *testing.T) {
	h := NewHyperLogLog()

	if !h.AddString("viewer-1") {
		t.Fatalf("expected first insert to update sketch")
	}
	if h.AddString("viewer-1") {
		t.Fatalf("expected duplicate insert to keep sketch unchanged")
	}
	if got := h.Count(); got != 1 {
		t.Fatalf("expected count=1, got %d", got)
	}
}

func TestHyperLogLogEstimateStaysReasonable(t *testing.T) {
	h := NewHyperLogLog()

	const total = 1000
	for i := 0; i < total; i++ {
		h.AddString(fmt.Sprintf("viewer-%d", i))
	}

	got := h.Count()
	if got < 900 || got > 1100 {
		t.Fatalf("expected estimate close to %d, got %d", total, got)
	}
}
