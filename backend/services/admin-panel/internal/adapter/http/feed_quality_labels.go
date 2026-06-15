package http

import "strings"

var feedQualitySurfaceLabelKeys = map[string]string{
	"home":    "feedQuality.surface.home",
	"content": "feedQuality.surface.content",
}

var feedQualityBlockTypeLabelKeys = map[string]string{
	"activity_card":         "feedQuality.blockType.activityCard",
	"attraction_card":       "feedQuality.blockType.attractionCard",
	"guide_card":            "feedQuality.blockType.guideCard",
	"official_news_card":    "feedQuality.blockType.officialNewsCard",
	"profile_card":          "feedQuality.blockType.profileCard",
	"stories_tray":          "feedQuality.blockType.storiesTray",
	"post_card":             "feedQuality.blockType.postCard",
	"suggested_communities": "feedQuality.blockType.suggestedCommunities",
	"tour_card":             "feedQuality.blockType.tourCard",
}

var feedQualityActionLabelKeys = map[string]string{
	"click":          "feedQuality.action.click",
	"conversion":     "feedQuality.action.conversion",
	"hide":           "feedQuality.action.hide",
	"impression":     "feedQuality.action.impression",
	"not_interested": "feedQuality.action.notInterested",
}

func feedQualitySurfaceText(locale string, value any) string {
	return feedQualityCodeText(locale, value, feedQualitySurfaceLabelKeys)
}

func feedQualityBlockTypeText(locale string, value any) string {
	return feedQualityCodeText(locale, value, feedQualityBlockTypeLabelKeys)
}

func feedQualityActionText(locale string, value any) string {
	return feedQualityCodeText(locale, value, feedQualityActionLabelKeys)
}

func feedQualityCodeText(locale string, value any, labelKeys map[string]string) string {
	raw := strings.ToLower(strings.TrimSpace(toString(value)))
	if raw == "" {
		return "-"
	}
	if key := labelKeys[raw]; key != "" {
		translated := translate(locale, key)
		if translated != key {
			return translated
		}
	}
	return readableFeedQualityCode(raw)
}

func readableFeedQualityCode(value string) string {
	normalized := strings.NewReplacer("_", " ", "-", " ").Replace(value)
	words := strings.Fields(normalized)
	if len(words) == 0 {
		return "-"
	}
	for index, word := range words {
		words[index] = strings.ToUpper(word[:1]) + word[1:]
	}
	return strings.Join(words, " ")
}
