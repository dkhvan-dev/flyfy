package main

import (
	"bytes"
	"image/gif"
	"testing"
)

func TestDefaultTravelStickerDefinitionsAreValid(t *testing.T) {
	t.Parallel()

	defs := defaultStickerDefinitions()
	if len(defs) < 32 {
		t.Fatalf("expected at least 32 default stickers, got %d", len(defs))
	}

	seen := make(map[string]struct{}, len(defs))
	for _, def := range defs {
		if def.Key == "" {
			t.Fatal("sticker key must not be empty")
		}
		if _, ok := seen[def.Key]; ok {
			t.Fatalf("duplicate sticker key %q", def.Key)
		}
		seen[def.Key] = struct{}{}

		if def.Emoji == "" {
			t.Fatalf("sticker %q must have emoji metadata", def.Key)
		}
		if len(def.Keywords) < 3 {
			t.Fatalf("sticker %q should have searchable keywords", def.Key)
		}

		body, err := renderStickerAnimation(def)
		if err != nil {
			t.Fatalf("render %q: %v", def.Key, err)
		}
		if len(body) < 1024 {
			t.Fatalf("rendered sticker %q is suspiciously small: %d bytes", def.Key, len(body))
		}

		img, err := gif.DecodeAll(bytes.NewReader(body))
		if err != nil {
			t.Fatalf("decode %q: %v", def.Key, err)
		}
		if len(img.Image) < 2 {
			t.Fatalf("sticker %q should be animated, got %d frame(s)", def.Key, len(img.Image))
		}
		if got := img.Image[0].Bounds().Dx(); got != stickerCanvasSize {
			t.Fatalf("sticker %q width = %d, want %d", def.Key, got, stickerCanvasSize)
		}
		if got := img.Image[0].Bounds().Dy(); got != stickerCanvasSize {
			t.Fatalf("sticker %q height = %d, want %d", def.Key, got, stickerCanvasSize)
		}
	}
}

func TestExpandedOfficialStickerSetIncludesTravelChatMoments(t *testing.T) {
	t.Parallel()

	defs := defaultStickerDefinitions()
	seen := make(map[string]struct{}, len(defs))
	for _, def := range defs {
		seen[def.Key] = struct{}{}
	}

	for _, key := range []string{
		"lost-but-happy",
		"delayed-again",
		"beach-please",
		"mountain-call",
		"send-location",
		"travel-camera",
		"globe-mode",
		"camp-vibes",
	} {
		if _, ok := seen[key]; !ok {
			t.Fatalf("expected expanded official sticker %q", key)
		}
	}
}

func TestOfficialProductionGroupsAreDefined(t *testing.T) {
	t.Parallel()

	defs := defaultStickerDefinitions()
	groups := make(map[string]int)
	for _, def := range defs {
		if def.GroupSlug == "" {
			t.Fatalf("sticker %q must define a group slug", def.Key)
		}
		if def.GroupTitle["en"] == "" {
			t.Fatalf("sticker %q must define localized group title", def.Key)
		}
		if def.PackSlug == "" {
			t.Fatalf("sticker %q must define a pack slug", def.Key)
		}
		if def.PackTitle["en"] == "" {
			t.Fatalf("sticker %q must define localized pack title", def.Key)
		}
		if def.FallbackName == "" {
			t.Fatalf("sticker %q must define a fallback asset name", def.Key)
		}
		if def.DurationMS <= 0 || def.DurationMS > 3000 {
			t.Fatalf("sticker %q duration must be production safe, got %d", def.Key, def.DurationMS)
		}
		groups[def.GroupSlug]++
	}

	for _, slug := range []string{
		"travel",
		"emotions",
		"food",
		"weather",
		"transport",
		"planning",
		"guides",
		"local-culture",
		"bookings",
		"safety",
		"celebrations",
		"seasonal",
	} {
		if groups[slug] < 2 {
			t.Fatalf("expected at least 2 stickers for group %q, got %d", slug, groups[slug])
		}
	}
}

func TestDefaultStickerAnimationsAreLively(t *testing.T) {
	t.Parallel()

	for _, def := range defaultStickerDefinitions() {
		body, err := renderStickerAnimation(def)
		if err != nil {
			t.Fatalf("render %q: %v", def.Key, err)
		}

		img, err := gif.DecodeAll(bytes.NewReader(body))
		if err != nil {
			t.Fatalf("decode %q: %v", def.Key, err)
		}
		if len(img.Image) < 16 {
			t.Fatalf("sticker %q should have production-grade animation density, got %d frame(s)", def.Key, len(img.Image))
		}

		totalDelay := 0
		for _, delay := range img.Delay {
			if delay > 8 {
				t.Fatalf("sticker %q has sluggish frame delay %dcs, want <= 8cs", def.Key, delay)
			}
			totalDelay += delay
		}
		if totalDelay > 120 {
			t.Fatalf("sticker %q animation duration = %dcs, want <= 120cs", def.Key, totalDelay)
		}

		changed := maxChangedPixelRatio(img)
		if changed < 0.035 {
			t.Fatalf("sticker %q is visually too static: changed %.2f%% of pixels", def.Key, changed*100)
		}
	}
}

func maxChangedPixelRatio(img *gif.GIF) float64 {
	maxChanged := 0.0
	for frame := 1; frame < len(img.Image); frame++ {
		changed := changedPixelRatio(img, 0, frame)
		if changed > maxChanged {
			maxChanged = changed
		}
	}
	return maxChanged
}

func changedPixelRatio(img *gif.GIF, firstFrame int, secondFrame int) float64 {
	a := img.Image[firstFrame]
	b := img.Image[secondFrame]
	bounds := a.Bounds()
	if !bounds.Eq(b.Bounds()) {
		return 1
	}

	changed := 0
	total := bounds.Dx() * bounds.Dy()
	for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
		for x := bounds.Min.X; x < bounds.Max.X; x++ {
			if a.ColorIndexAt(x, y) != b.ColorIndexAt(x, y) {
				changed++
			}
		}
	}
	return float64(changed) / float64(total)
}
