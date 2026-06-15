package config

import (
	"os"
	"strings"
	"testing"
)

func TestFeedConfigExposesRankingPolicyEnvSurface(t *testing.T) {
	sourceBytes, err := os.ReadFile("config.go")
	if err != nil {
		t.Fatalf("read config source: %v", err)
	}
	source := string(sourceBytes)

	for _, needle := range []string{
		"FEED_RANKING_EXPERIMENT_KEY",
		"FEED_RANKING_POST_INTEREST_WEIGHT",
		"FEED_RANKING_COMMUNITY_INTEREST_WEIGHT",
		"FEED_RANKING_CITY_AFFINITY_WEIGHT",
		"FEED_RANKING_COUNTRY_AFFINITY_WEIGHT",
		"FEED_RANKING_CATEGORY_AFFINITY_WEIGHT",
		"FEED_RANKING_TAG_AFFINITY_WEIGHT",
		"FEED_RANKING_MAX_BOOST_HOURS",
		"FEED_RANKING_MAX_PENALTY_HOURS",
		"FEED_RANKING_INTEREST_FRESHNESS_DELAY",
		"FEED_RANKING_NOT_INTERESTED_PENALTY",
		"FEED_RANKING_RECENT_COMMUNITY_EVENT_WINDOW",
		"FEED_RANKING_RECENT_COMMUNITY_PENALTY_HOURS",
		"FEED_RANKING_COLD_START_MAX_BOOST_HOURS",
		"FEED_RANKING_COLD_START_ENGAGEMENT_WEIGHT",
		"FEED_RANKING_MAX_POSTS_PER_COMMUNITY_PER_PAGE",
		"FEED_RANKING_MAX_POSTS_PER_CATEGORY_PER_PAGE",
		"FEED_RANKING_MAX_POSTS_PER_AUTHOR_PER_PAGE",
		"FEED_CURATED_MAX_CONVERSION_BLOCKS_PER_PAGE",
		"FEED_CURATED_MAX_OFFICIAL_NEWS_CARDS_PER_PAGE",
		"FEED_CURATED_MAX_PROFILE_CARDS_PER_PAGE",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("FeedConfig source must expose %q", needle)
		}
	}
}

func TestConfigDoesNotExposeLegacyStoryEnvSurface(t *testing.T) {
	sourceBytes, err := os.ReadFile("config.go")
	if err != nil {
		t.Fatalf("read config source: %v", err)
	}
	source := string(sourceBytes)

	for _, legacy := range []string{
		"FEED_RANKING_STORY_INTEREST_WEIGHT",
		"FEED_RANKING_MAX_STORIES_PER_COMMUNITY_PER_PAGE",
		"FEED_RANKING_MAX_STORIES_PER_CATEGORY_PER_PAGE",
		"FEED_RANKING_MAX_STORIES_PER_AUTHOR_PER_PAGE",
		"FEED_LEGACY_STORY_VIEW_ENDPOINT_ENABLED",
	} {
		if strings.Contains(source, legacy) {
			t.Fatalf("Config source must not expose legacy story env %q", legacy)
		}
	}
}
