package enum

import "testing"

func TestPostFormatIsValid(t *testing.T) {
	tests := map[PostFormat]bool{
		PostFormatPost:       true,
		PostFormatGuide:      true,
		PostFormatPhotoEssay: true,
		PostFormatArticle:    true,
		PostFormatCulinary:   true,
		PostFormat("TRIP"):   false,
		PostFormat(""):       false,
	}

	for format, expected := range tests {
		t.Run(string(format), func(t *testing.T) {
			if got := format.IsValid(); got != expected {
				t.Fatalf("IsValid() = %v, want %v", got, expected)
			}
		})
	}
}

func TestNormalizePostFormat(t *testing.T) {
	tests := map[PostFormat]PostFormat{
		PostFormat(""):                 PostFormatArticle,
		PostFormat(" guide "):          PostFormatGuide,
		PostFormat("photo_essay"):      PostFormatPhotoEssay,
		PostFormat("ARTICLE"):          PostFormatArticle,
		PostFormat("culinary"):         PostFormatCulinary,
		PostFormat("unsupported_kind"): PostFormat("UNSUPPORTED_KIND"),
	}

	for input, expected := range tests {
		t.Run(string(input), func(t *testing.T) {
			if got := NormalizePostFormat(input); got != expected {
				t.Fatalf("NormalizePostFormat() = %q, want %q", got, expected)
			}
		})
	}
}
