package main

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"io"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/sticker-service/internal/config"
)

type lottieTestAnimation struct {
	Version string           `json:"v"`
	FrameR  float64          `json:"fr"`
	In      float64          `json:"ip"`
	Out     float64          `json:"op"`
	Width   int              `json:"w"`
	Height  int              `json:"h"`
	Assets  []map[string]any `json:"assets"`
	Layers  []map[string]any `json:"layers"`
}

func TestDefaultTravelStickerDefinitionsAreValid(t *testing.T) {
	t.Parallel()

	defs := defaultStickerDefinitions()
	expectedKeys := expectedOfficialLottieStickerKeys()
	if len(defs) != len(expectedKeys) {
		t.Fatalf("expected %d official lottie stickers, got %d", len(expectedKeys), len(defs))
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
		if def.AssetPath == "" {
			t.Fatalf("sticker %q must be backed by an embedded tgs asset", def.Key)
		}
		if def.PackSlug != "inflap-official-lottie" {
			t.Fatalf("sticker %q pack = %q, want inflap-official-lottie", def.Key, def.PackSlug)
		}
		if def.GroupSlug != "official" {
			t.Fatalf("sticker %q group = %q, want official", def.Key, def.GroupSlug)
		}

		body, err := renderStickerAnimation(def)
		if err != nil {
			t.Fatalf("render %q: %v", def.Key, err)
		}
		if len(body) < 1024 {
			t.Fatalf("rendered sticker %q is suspiciously small: %d bytes", def.Key, len(body))
		}
		if len(body) > stickerTGSMaxBytes {
			t.Fatalf("rendered sticker %q is too large: %d bytes", def.Key, len(body))
		}

		img, err := decodeTGS(body)
		if err != nil {
			t.Fatalf("decode %q: %v", def.Key, err)
		}
		if len(img.Layers) == 0 {
			t.Fatalf("sticker %q should have lottie layers", def.Key)
		}
		if got := img.Width; got != def.Width {
			t.Fatalf("sticker %q width = %d, want %d", def.Key, got, def.Width)
		}
		if got := img.Height; got != def.Height {
			t.Fatalf("sticker %q height = %d, want %d", def.Key, got, def.Height)
		}
		if len(img.Assets) != 0 {
			if hasImageAssets(img) {
				t.Fatalf("sticker %q must not embed raster/image assets: %#v", def.Key, img.Assets)
			}
		}
	}

	for _, key := range expectedKeys {
		if _, ok := seen[key]; !ok {
			t.Fatalf("expected official lottie sticker %q", key)
		}
	}
}

func TestNewSeederFileManagerClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newSeederFileManagerClient(&config.Config{
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		FileManager: config.FileManagerConfig{
			BaseURL: "http://file-manager-service:8083",
			Timeout: 800 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newSeederFileManagerClient() error = %v", err)
	}
	if client == nil {
		t.Fatal("newSeederFileManagerClient() = nil, want client")
	}
}

func TestNewSeederFileManagerClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newSeederFileManagerClient(&config.Config{
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		FileManager: config.FileManagerConfig{
			BaseURL: "https://file-manager-service:9443",
			Timeout: 800 * time.Millisecond,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newSeederFileManagerClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize file-manager mTLS transport") {
		t.Fatalf("error = %q, want file-manager mTLS context", err)
	}
}

func TestDefaultStickerAnimationsUseTelegramTGSFormat(t *testing.T) {
	t.Parallel()

	if stickerContentType != "application/x-tgsticker" {
		t.Fatalf("stickerContentType = %q, want application/x-tgsticker", stickerContentType)
	}
	if stickerFileExt != "tgs" {
		t.Fatalf("stickerFileExt = %q, want tgs", stickerFileExt)
	}

	body, err := renderStickerAnimation(defaultStickerDefinitions()[0])
	if err != nil {
		t.Fatalf("render sticker: %v", err)
	}
	if len(body) > 64*1024 {
		t.Fatalf("telegram tgs sticker is too large: %d bytes", len(body))
	}
	if len(body) < 512 {
		t.Fatalf("telegram tgs sticker is suspiciously small: %d bytes", len(body))
	}

	animation, err := decodeTGS(body)
	if err != nil {
		t.Fatalf("decode tgs: %v", err)
	}
	if animation.FrameR <= 0 || animation.FrameR > 60 {
		t.Fatalf("frame rate = %.0f, want in (0, 60]", animation.FrameR)
	}
	if hasImageAssets(animation) {
		t.Fatalf("telegram tgs animation must not contain image assets: %#v", animation.Assets)
	}
	if !usesVectorOnlyLayers(animation) {
		t.Fatalf("telegram tgs animation must use vector shape layers only")
	}
	if !hasAnimatedVectorTransform(animation) {
		t.Fatalf("telegram tgs animation should contain animated vector values")
	}
	durationMS := (animation.Out - animation.In) / animation.FrameR * 1000
	if durationMS <= 0 || durationMS > 3000 {
		t.Fatalf("duration = %.0fms, want <= 3000ms", durationMS)
	}
}

func TestDefaultStickerAssetsAreVectorOnlyTelegramTGS(t *testing.T) {
	t.Parallel()

	for _, def := range defaultStickerDefinitions() {
		body, err := renderStickerAnimation(def)
		if err != nil {
			t.Fatalf("render %q: %v", def.Key, err)
		}
		if len(body) > stickerTGSMaxBytes {
			t.Fatalf("sticker %q exceeds telegram tgs limit: %d bytes", def.Key, len(body))
		}

		animation, err := decodeTGS(body)
		if err != nil {
			t.Fatalf("decode %q: %v", def.Key, err)
		}
		if hasImageAssets(animation) {
			t.Fatalf("sticker %q contains image assets: %#v", def.Key, animation.Assets)
		}
		if !usesVectorOnlyLayers(animation) {
			t.Fatalf("sticker %q must use vector/precomp lottie layers only", def.Key)
		}
		durationMS := (animation.Out - animation.In) / animation.FrameR * 1000
		if durationMS <= 0 || durationMS > 3000 {
			t.Fatalf("sticker %q duration = %.0fms, want <= 3000ms", def.Key, durationMS)
		}
	}
}

func TestHeartStickerDoesNotContainWhiteSolidBackground(t *testing.T) {
	t.Parallel()

	def := findDefaultStickerDefinition(t, "lottie-heart")
	body, err := renderStickerAnimation(def)
	if err != nil {
		t.Fatalf("render %q: %v", def.Key, err)
	}

	animation, err := decodeTGS(body)
	if err != nil {
		t.Fatalf("decode %q: %v", def.Key, err)
	}
	for _, layer := range animation.Layers {
		layerType, _ := layer["ty"].(float64)
		color, _ := layer["sc"].(string)
		name, _ := layer["nm"].(string)
		if int(layerType) == 1 && strings.EqualFold(color, "#ffffff") {
			t.Fatalf("heart sticker contains white solid background layer %q", name)
		}
	}
}

func TestOfficialStickerSetDoesNotIncludeRetiredBear(t *testing.T) {
	t.Parallel()

	for _, def := range defaultStickerDefinitions() {
		if def.Key == "lottie-bear" {
			t.Fatalf("retired sticker %q must not be included in the official catalog", def.Key)
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

	for _, key := range expectedOfficialLottieStickerKeys() {
		if _, ok := seen[key]; !ok {
			t.Fatalf("expected official lottie sticker %q", key)
		}
	}
}

func TestOfficialProductionGroupsAreDefined(t *testing.T) {
	t.Parallel()

	defs := defaultStickerDefinitions()
	groups := make(map[string]int)
	for _, def := range defs {
		if def.GroupSlug != "official" {
			t.Fatalf("sticker %q must be in single official group, got %q", def.Key, def.GroupSlug)
		}
		if def.GroupTitle["en"] == "" {
			t.Fatalf("sticker %q must define localized group title", def.Key)
		}
		if def.PackSlug != "inflap-official-lottie" {
			t.Fatalf("sticker %q must be in single official lottie pack, got %q", def.Key, def.PackSlug)
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

	if len(groups) != 1 || groups["official"] != len(expectedOfficialLottieStickerKeys()) {
		t.Fatalf("expected one official group with provided stickers, got %#v", groups)
	}
}

func TestDefaultStickerAnimationsAreLively(t *testing.T) {
	t.Parallel()

	for _, def := range defaultStickerDefinitions() {
		body, err := renderStickerAnimation(def)
		if err != nil {
			t.Fatalf("render %q: %v", def.Key, err)
		}

		img, err := decodeTGS(body)
		if err != nil {
			t.Fatalf("decode %q: %v", def.Key, err)
		}
		if !hasAnimatedVectorTransform(img) {
			t.Fatalf("sticker %q should contain animated vector transforms", def.Key)
		}
	}
}

func decodeTGS(body []byte) (lottieTestAnimation, error) {
	var animation lottieTestAnimation
	raw, err := decodeTGSRaw(body)
	if err != nil {
		return animation, err
	}
	if err = json.Unmarshal(raw, &animation); err != nil {
		return animation, err
	}
	return animation, nil
}

func decodeTGSRaw(body []byte) ([]byte, error) {
	reader, err := gzip.NewReader(bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	defer reader.Close()
	return io.ReadAll(reader)
}

func findDefaultStickerDefinition(t *testing.T, key string) stickerDefinition {
	t.Helper()

	for _, def := range defaultStickerDefinitions() {
		if def.Key == key {
			return def
		}
	}
	t.Fatalf("default sticker %q not found", key)
	return stickerDefinition{}
}

func expectedOfficialLottieStickerKeys() []string {
	return []string{
		"lottie-cat-love",
		"lottie-fire-flame",
		"lottie-flirting-dog",
		"lottie-jellyfish-greeting",
		"lottie-like-button",
		"lottie-sea-walk",
		"lottie-travel-character",
		"lottie-hundred-percent",
		"lottie-doge-drift",
		"lottie-ambulance",
		"lottie-angry-emoji",
		"lottie-cat-laugh",
		"lottie-sparkle-burst",
		"lottie-confetti",
		"lottie-happy-girl",
		"lottie-heart",
		"lottie-jellyfish-like",
		"lottie-jellyfish-love",
		"lottie-laugh-emoji",
		"lottie-mind-blown-emoji",
		"lottie-party-emoji",
		"lottie-pigeon",
		"lottie-robot",
		"lottie-smoothymon-clap",
	}
}

func hasImageAssets(animation lottieTestAnimation) bool {
	for _, asset := range animation.Assets {
		if _, ok := asset["p"]; ok {
			return true
		}
		if _, ok := asset["u"]; ok {
			return true
		}
	}
	return false
}

func hasAnimatedVectorTransform(animation lottieTestAnimation) bool {
	return containsAnimatedValue(animation.Layers) || containsAnimatedValue(animation.Assets)
}

func usesVectorOnlyLayers(animation lottieTestAnimation) bool {
	for _, layer := range animation.Layers {
		layerType, _ := layer["ty"].(float64)
		if layerType == 2 {
			return false
		}
	}
	return len(animation.Layers) > 0
}

func containsAnimatedValue(value any) bool {
	switch v := value.(type) {
	case []map[string]any:
		for _, item := range v {
			if containsAnimatedValue(item) {
				return true
			}
		}
	case []any:
		for _, item := range v {
			if containsAnimatedValue(item) {
				return true
			}
		}
	case map[string]any:
		if animated, _ := v["a"].(float64); animated == 1 {
			return true
		}
		for _, item := range v {
			if containsAnimatedValue(item) {
				return true
			}
		}
	}
	return false
}

func hasSmoothKeyframes(animation lottieTestAnimation) bool {
	for _, layer := range animation.Layers {
		ks, ok := layer["ks"].(map[string]any)
		if !ok {
			continue
		}
		for _, property := range []string{"p", "s", "r", "o"} {
			value, ok := ks[property].(map[string]any)
			if !ok {
				continue
			}
			keyframes, ok := value["k"].([]any)
			if !ok {
				continue
			}
			for _, raw := range keyframes {
				keyframe, ok := raw.(map[string]any)
				if !ok {
					continue
				}
				if _, hasIn := keyframe["i"]; !hasIn {
					continue
				}
				if _, hasOut := keyframe["o"]; hasOut {
					return true
				}
			}
		}
	}
	return false
}
