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

var feedQualityTabLabelKeys = map[string]string{
	"activities":    "community.tab.activities",
	"announcements": "community.tab.announcements",
	"articles":      "community.tab.articles",
	"discussions":   "community.tab.discussions",
	"discover":      "feedQuality.tab.discover",
	"following":     "feedQuality.tab.following",
	"for_you":       "feedQuality.tab.forYou",
	"listings":      "community.tab.listings",
	"nearby":        "feedQuality.tab.nearby",
	"questions":     "community.tab.questions",
	"trending":      "feedQuality.tab.trending",
	"trip_plans":    "community.tab.trip_plans",
}

var feedQualityActionLabelKeys = map[string]string{
	"click":          "feedQuality.action.click",
	"comment":        "feedQuality.action.comment",
	"conversion":     "feedQuality.action.conversion",
	"dwell":          "feedQuality.action.dwell",
	"hide":           "feedQuality.action.hide",
	"impression":     "feedQuality.action.impression",
	"like":           "feedQuality.action.like",
	"not_interested": "feedQuality.action.notInterested",
	"share":          "feedQuality.action.share",
	"subscribe":      "feedQuality.action.subscribe",
}

var feedQualityPostProfileLabelKeys = map[string]string{
	"article_v1":            "community.postProfile.article_v1",
	"event_announcement_v1": "community.postProfile.event_announcement_v1",
	"listing_v1":            "community.postProfile.listing_v1",
	"question_answer_v1":    "community.postProfile.question_answer_v1",
	"quick_post_v1":         "community.postProfile.quick_post_v1",
	"trip_plan_v1":          "community.postProfile.trip_plan_v1",
}

var feedQualityExperimentLabelKeys = map[string]string{
	"control": "feedQuality.rankingExperiment.control",
}

var feedQualityCandidateSourceLabelKeys = map[string]string{
	"cold_start": "feedQuality.candidateSource.coldStart",
	"followed":   "feedQuality.candidateSource.followed",
	"following":  "feedQuality.candidateSource.following",
	"geo":        "feedQuality.candidateSource.geo",
	"global":     "feedQuality.candidateSource.global",
	"interest":   "feedQuality.candidateSource.interest",
	"popular":    "feedQuality.candidateSource.popular",
	"social":     "feedQuality.candidateSource.social",
}

func feedQualitySurfaceText(locale string, value any) string {
	return feedQualityCodeText(locale, value, feedQualitySurfaceLabelKeys)
}

func feedQualityBlockTypeText(locale string, value any) string {
	return feedQualityCodeText(locale, value, feedQualityBlockTypeLabelKeys)
}

func feedQualityTabText(locale string, value any) string {
	return feedQualityCodeText(locale, value, feedQualityTabLabelKeys)
}

func feedQualityActionText(locale string, value any) string {
	return feedQualityCodeText(locale, value, feedQualityActionLabelKeys)
}

func feedQualityPostProfileText(locale string, value any) string {
	return feedQualityCodeText(locale, value, feedQualityPostProfileLabelKeys)
}

func feedQualityExperimentText(locale string, value any) string {
	return feedQualityCodeText(locale, value, feedQualityExperimentLabelKeys)
}

func feedQualityCandidateSourceText(locale string, value any) string {
	return feedQualityCodeText(locale, value, feedQualityCandidateSourceLabelKeys)
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
