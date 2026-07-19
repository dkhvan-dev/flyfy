package collection

import (
	"errors"
	"strings"
	"testing"
	"unicode/utf8"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestNormalizeTitleProducesStableDisplayAndKey(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name        string
		raw         string
		wantDisplay string
		wantKey     string
	}{
		{
			name:        "trim collapse and full case fold",
			raw:         "  Straße\u00a0\u2003TRIPS  ",
			wantDisplay: "Straße\u00a0\u2003TRIPS",
			wantKey:     "strasse trips",
		},
		{
			name:        "NFC display",
			raw:         "Cafe\u0301",
			wantDisplay: "Café",
			wantKey:     "café",
		},
		{
			name:        "NFKC compatibility key",
			raw:         "ＦｌｙＦｙ",
			wantDisplay: "ＦｌｙＦｙ",
			wantKey:     "flyfy",
		},
		{
			name:        "ZWJ emoji sequence remains valid",
			raw:         "Family 👨‍👩‍👧‍👦",
			wantDisplay: "Family 👨‍👩‍👧‍👦",
			wantKey:     "family 👨‍👩‍👧‍👦",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got, err := NormalizeTitle(test.raw)
			if err != nil {
				t.Fatalf("NormalizeTitle() error = %v", err)
			}
			if got.Display != test.wantDisplay || got.Key != test.wantKey {
				t.Fatalf("NormalizeTitle() = %#v, want display=%q key=%q", got, test.wantDisplay, test.wantKey)
			}
		})
	}
}

func TestNormalizeTitleRejectsUnsafeOrUnboundedText(t *testing.T) {
	t.Parallel()

	invalidUTF8 := string([]byte{0xff})
	tests := []struct {
		name string
		raw  string
	}{
		{name: "empty", raw: "   "},
		{name: "invalid utf8", raw: invalidUTF8},
		{name: "line break", raw: "First\nSecond"},
		{name: "C1 control", raw: "Trip\u0085Name"},
		{name: "bidi override", raw: "Trip\u202eName"},
		{name: "zero width space", raw: "Trip\u200bName"},
		{name: "zero width non joiner", raw: "Trip\u200cName"},
		{name: "word joiner", raw: "Trip\u2060Name"},
		{name: "too many code points", raw: strings.Repeat("a", MaxTitleCodePoints+1)},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if _, err := NormalizeTitle(test.raw); !errors.Is(err, domain.ErrCollectionTitleInvalid) {
				t.Fatalf("NormalizeTitle() error = %v, want title invalid", err)
			}
		})
	}
}

func TestNormalizeTitleDoesNotSplitOrCountBytesAsCodePoints(t *testing.T) {
	t.Parallel()

	raw := strings.Repeat("Қ", MaxTitleCodePoints)
	if utf8.RuneCountInString(raw) != MaxTitleCodePoints || len(raw) <= MaxTitleCodePoints {
		t.Fatal("test input does not distinguish code points from bytes")
	}
	if _, err := NormalizeTitle(raw); err != nil {
		t.Fatalf("NormalizeTitle(80 multibyte code points) error = %v", err)
	}
}
