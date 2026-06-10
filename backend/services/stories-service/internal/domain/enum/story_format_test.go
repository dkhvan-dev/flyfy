package enum

import "testing"

func TestStoryFormatIsValid(t *testing.T) {
	tests := map[StoryFormat]bool{
		StoryFormatStory:      true,
		StoryFormatGuide:      true,
		StoryFormatPhotoEssay: true,
		StoryFormatArticle:    true,
		StoryFormatCulinary:   true,
		StoryFormat("TRIP"):   false,
		StoryFormat(""):       false,
	}

	for format, expected := range tests {
		t.Run(string(format), func(t *testing.T) {
			if got := format.IsValid(); got != expected {
				t.Fatalf("IsValid() = %v, want %v", got, expected)
			}
		})
	}
}

func TestNormalizeStoryFormat(t *testing.T) {
	tests := map[StoryFormat]StoryFormat{
		StoryFormat(""):                 StoryFormatStory,
		StoryFormat(" guide "):          StoryFormatGuide,
		StoryFormat("photo_essay"):      StoryFormatPhotoEssay,
		StoryFormat("ARTICLE"):          StoryFormatArticle,
		StoryFormat("culinary"):         StoryFormatCulinary,
		StoryFormat("unsupported_kind"): StoryFormat("UNSUPPORTED_KIND"),
	}

	for input, expected := range tests {
		t.Run(string(input), func(t *testing.T) {
			if got := NormalizeStoryFormat(input); got != expected {
				t.Fatalf("NormalizeStoryFormat() = %q, want %q", got, expected)
			}
		})
	}
}
