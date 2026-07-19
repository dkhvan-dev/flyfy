package collection

import (
	"strings"
	"unicode"
	"unicode/utf8"

	"golang.org/x/text/cases"
	"golang.org/x/text/unicode/norm"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	TitleNormalizationVersion = "COLLECTION_TITLE_NORMALIZATION_V1"
	MaxTitleCodePoints        = 80
	MaxDisplayTitleBytes      = 320
	MaxNormalizedTitleBytes   = 512
)

type NormalizedTitle struct {
	Display string
	Key     string
}

// NormalizeTitle is the only authoritative collection-title normalization
// path. Changing these semantics requires a collision-audited migration.
func NormalizeTitle(raw string) (NormalizedTitle, error) {
	if !utf8.ValidString(raw) {
		return NormalizedTitle{}, domain.ErrCollectionTitleInvalid
	}

	trimmed := strings.TrimSpace(raw)
	if !validTitleText(trimmed) {
		return NormalizedTitle{}, domain.ErrCollectionTitleInvalid
	}

	display := norm.NFC.String(trimmed)
	if !validTitleText(display) {
		return NormalizedTitle{}, domain.ErrCollectionTitleInvalid
	}

	key := norm.NFKC.String(display)
	key = cases.Fold().String(key)
	key = collapseUnicodeWhitespace(key)
	if key == "" || !utf8.ValidString(key) || len(key) > MaxNormalizedTitleBytes {
		return NormalizedTitle{}, domain.ErrCollectionTitleInvalid
	}

	return NormalizedTitle{Display: display, Key: key}, nil
}

func validTitleText(value string) bool {
	if value == "" || value != strings.TrimSpace(value) ||
		utf8.RuneCountInString(value) > MaxTitleCodePoints || len(value) > MaxDisplayTitleBytes {
		return false
	}
	for _, codePoint := range value {
		if unicode.IsControl(codePoint) || isBidiControl(codePoint) || isForbiddenFormat(codePoint) {
			return false
		}
	}
	return true
}

func collapseUnicodeWhitespace(value string) string {
	var builder strings.Builder
	builder.Grow(len(value))
	pendingSpace := false
	for _, codePoint := range value {
		if unicode.IsSpace(codePoint) {
			if builder.Len() > 0 {
				pendingSpace = true
			}
			continue
		}
		if pendingSpace {
			builder.WriteByte(' ')
			pendingSpace = false
		}
		builder.WriteRune(codePoint)
	}
	return builder.String()
}

func isForbiddenFormat(codePoint rune) bool {
	// ZWJ is explicitly allowed for emoji sequences. Variation selectors are
	// combining marks rather than Cf and therefore remain allowed.
	return codePoint != '\u200d' && unicode.Is(unicode.Cf, codePoint)
}

func isBidiControl(codePoint rune) bool {
	switch {
	case codePoint == '\u061c', codePoint == '\u200e', codePoint == '\u200f':
		return true
	case codePoint >= '\u202a' && codePoint <= '\u202e':
		return true
	case codePoint >= '\u2066' && codePoint <= '\u2069':
		return true
	default:
		return false
	}
}
