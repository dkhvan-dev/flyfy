package savedsearch

import (
	"errors"
	"strings"
	"testing"
)

func TestNormalizeIsUnicodeAwareAndTokenBounded(t *testing.T) {
	t.Parallel()

	term, err := Normalize("  ＭＵＳＥＵＭ—МУЗЕЙ / ҚАЛА\u00a0Cafe\u0301  ")
	if err != nil {
		t.Fatalf("Normalize() error = %v", err)
	}
	if got, want := term.Normalized(), "museum музей қала café"; got != want {
		t.Fatal("Unicode normalization fixture mismatch")
	}
	if got, want := term.Tokens(), []string{"museum", "музей", "қала", "café"}; !equalStrings(got, want) {
		t.Fatal("Unicode tokenization fixture mismatch")
	}

	tokens := term.Tokens()
	tokens[0] = "mutated"
	if term.Tokens()[0] != "museum" {
		t.Fatal("Tokens() exposed mutable internal state")
	}
}

func TestNormalizeRejectsUnsafeOrUnboundedQueries(t *testing.T) {
	t.Parallel()

	tooManyTokens := strings.TrimSpace(strings.Repeat("a ", MaxSearchTokens+1))
	for name, raw := range map[string]string{
		"empty":            "",
		"punctuation_only": " / — ",
		"control":          "museum\x00city",
		"code_points":      strings.Repeat("қ", MaxSearchCodePoints+1),
		"tokens":           tooManyTokens,
		"invalid_utf8":     string([]byte{0xff, 0xfe}),
	} {
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			if _, err := Normalize(raw); !errors.Is(err, ErrInvalidQuery) {
				t.Fatalf("invalid search fixture error = %v, want %v", err, ErrInvalidQuery)
			}
		})
	}
}

func TestNormalizeTreatsUncomposedMarksLikePostgresAlnumBoundaries(t *testing.T) {
	t.Parallel()

	term, err := Normalize("Музе\u0301й Қала\u0301")
	if err != nil {
		t.Fatalf("Normalize() error = %v", err)
	}
	if term.Normalized() != "музе й қала" {
		t.Fatal("uncomposed mark boundary fixture mismatch")
	}
}

func equalStrings(left, right []string) bool {
	if len(left) != len(right) {
		return false
	}
	for index := range left {
		if left[index] != right[index] {
			return false
		}
	}
	return true
}
