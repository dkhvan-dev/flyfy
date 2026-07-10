package model

import "testing"

func TestNormalizeLanguageAcceptsSupportedLocaleVariants(t *testing.T) {
	tests := map[string]Language{
		"EN":      LanguageEnglish,
		"ru_RU":   LanguageRussian,
		"kk-Cyrl": LanguageKazakh,
		" kk ":    LanguageKazakh,
	}

	for input, want := range tests {
		got, ok := NormalizeLanguage(input)
		if !ok {
			t.Fatalf("NormalizeLanguage(%q) ok = false, want true", input)
		}
		if got != want {
			t.Fatalf("NormalizeLanguage(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestNormalizeLanguageRejectsUnsupportedLanguage(t *testing.T) {
	if got, ok := NormalizeLanguage("de"); ok || got != "" {
		t.Fatalf("NormalizeLanguage(de) = %q, %v; want unsupported", got, ok)
	}
}

func TestContentTypePolicyAllowsOnlyPublicTranslatableContent(t *testing.T) {
	for _, value := range []ContentType{
		ContentTypeAttraction,
		ContentTypeExcursion,
		ContentTypeActivity,
		ContentTypeGuideProfile,
		ContentTypeHelpArticle,
		ContentTypeAdminPublic,
	} {
		if !value.IsPublicTranslatable() {
			t.Fatalf("%s should be public translatable", value)
		}
	}

	for _, value := range []ContentType{"chat", "payment", "pii", "moderation_evidence", "legal"} {
		if value.IsPublicTranslatable() {
			t.Fatalf("%s must not be public translatable", value)
		}
	}
}
