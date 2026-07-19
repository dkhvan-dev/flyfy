package savedsearch

import (
	"slices"
	"strings"
	"unicode"
	"unicode/utf8"

	"golang.org/x/text/cases"
	"golang.org/x/text/language"
	"golang.org/x/text/unicode/norm"
)

// SearchTerm is the privacy-safe repository input. Its fields are private so
// adapters cannot accidentally receive or retain the submitted raw query.
type SearchTerm struct {
	normalized string
	tokens     []string
}

func Normalize(raw string) (SearchTerm, error) {
	if raw == "" || !utf8.ValidString(raw) || utf8.RuneCountInString(raw) > MaxSearchCodePoints {
		return SearchTerm{}, ErrInvalidQuery
	}
	for _, char := range raw {
		if unicode.IsControl(char) && !unicode.IsSpace(char) {
			return SearchTerm{}, ErrInvalidQuery
		}
	}

	// Caser may be stateful and must not be shared by concurrent requests. The
	// input is bounded, so a request-local caser keeps this path simple and safe.
	canonical := cases.Lower(language.Und).String(norm.NFKC.String(raw))
	var normalized strings.Builder
	normalized.Grow(len(canonical))
	pendingSeparator := false
	for _, char := range canonical {
		if unicode.IsLetter(char) || unicode.IsNumber(char) {
			if pendingSeparator && normalized.Len() > 0 {
				normalized.WriteByte(' ')
			}
			normalized.WriteRune(char)
			pendingSeparator = false
			continue
		}
		pendingSeparator = normalized.Len() > 0
	}

	value := normalized.String()
	if value == "" || utf8.RuneCountInString(value) > MaxSearchCodePoints {
		return SearchTerm{}, ErrInvalidQuery
	}
	tokens := strings.Fields(value)
	if len(tokens) == 0 || len(tokens) > MaxSearchTokens {
		return SearchTerm{}, ErrInvalidQuery
	}
	return SearchTerm{normalized: value, tokens: tokens}, nil
}

func (t SearchTerm) Normalized() string {
	return t.normalized
}

func (t SearchTerm) Tokens() []string {
	return slices.Clone(t.tokens)
}

func (t SearchTerm) validate() error {
	if t.normalized == "" || len(t.tokens) == 0 || len(t.tokens) > MaxSearchTokens ||
		utf8.RuneCountInString(t.normalized) > MaxSearchCodePoints ||
		!slices.Equal(strings.Fields(t.normalized), t.tokens) {
		return ErrInvalidQuery
	}
	for _, char := range t.normalized {
		if char != ' ' && !unicode.IsLetter(char) && !unicode.IsNumber(char) {
			return ErrInvalidQuery
		}
	}
	return nil
}
