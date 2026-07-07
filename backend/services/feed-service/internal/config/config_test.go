package config

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"
)

func TestFeedConfigExposesRankingPolicyEnvSurface(t *testing.T) {
	sourceBytes, err := os.ReadFile("config.go")
	if err != nil {
		t.Fatalf("read config source: %v", err)
	}
	source := string(sourceBytes)

	for _, needle := range []string{
		"FEED_RANKING_EXPERIMENT_KEY",
		"FEED_RANKING_EXPERIMENT_VARIANTS",
		"FEED_RANKING_EXPERIMENT_POLICIES",
		"FEED_RANKING_POST_INTEREST_WEIGHT",
		"FEED_RANKING_COMMUNITY_INTEREST_WEIGHT",
		"FEED_RANKING_POST_PROFILE_AFFINITY_WEIGHT",
		"FEED_RANKING_CITY_AFFINITY_WEIGHT",
		"FEED_RANKING_COUNTRY_AFFINITY_WEIGHT",
		"FEED_RANKING_CATEGORY_AFFINITY_WEIGHT",
		"FEED_RANKING_TAG_AFFINITY_WEIGHT",
		"FEED_RANKING_AUTHOR_AFFINITY_WEIGHT",
		"FEED_RANKING_MAX_BOOST_HOURS",
		"FEED_RANKING_MAX_PENALTY_HOURS",
		"FEED_RANKING_INTEREST_FRESHNESS_DELAY",
		"FEED_RANKING_NOT_INTERESTED_PENALTY",
		"FEED_RANKING_RECENT_POST_IMPRESSION_WINDOW",
		"FEED_RANKING_RECENT_POST_IMPRESSION_PENALTY_HOURS",
		"FEED_RANKING_RECENT_COMMUNITY_EVENT_WINDOW",
		"FEED_RANKING_RECENT_COMMUNITY_PENALTY_HOURS",
		"FEED_RANKING_COMMUNITY_MEMBERSHIP_BOOST_HOURS",
		"FEED_RANKING_SOCIAL_FRIEND_BOOST_HOURS",
		"FEED_RANKING_SOCIAL_FOLLOWING_BOOST_HOURS",
		"FEED_RANKING_CURRENT_CITY_BOOST_HOURS",
		"FEED_RANKING_CURRENT_COUNTRY_BOOST_HOURS",
		"FEED_RANKING_EXPLORATION_FRESHNESS_WINDOW",
		"FEED_RANKING_EXPLORATION_LOW_VIEW_THRESHOLD",
		"FEED_RANKING_EXPLORATION_MAX_BOOST_HOURS",
		"FEED_RANKING_QUALITY_PENALTY_WINDOW",
		"FEED_RANKING_QUALITY_MIN_NEGATIVE_EVENTS",
		"FEED_RANKING_QUALITY_NEGATIVE_PENALTY_HOURS",
		"FEED_RANKING_QUALITY_MAX_PENALTY_HOURS",
		"FEED_RANKING_COLD_START_MAX_BOOST_HOURS",
		"FEED_RANKING_COLD_START_ENGAGEMENT_WEIGHT",
		"FEED_RANKING_ENGAGEMENT_MAX_BOOST_HOURS",
		"FEED_RANKING_ENGAGEMENT_WEIGHT",
		"FEED_RANKING_ENGAGEMENT_FRESHNESS_WINDOW",
		"FEED_RANKING_NEGATIVE_INTEREST_DECAY_WINDOW",
		"FEED_RANKING_NEGATIVE_INTEREST_MIN_WEIGHT",
		"FEED_RANKING_DIRECT_NEGATIVE_FEEDBACK_DECAY_WINDOW",
		"FEED_RANKING_MAX_POSTS_PER_COMMUNITY_PER_PAGE",
		"FEED_RANKING_MAX_POSTS_PER_CATEGORY_PER_PAGE",
		"FEED_RANKING_MAX_POSTS_PER_AUTHOR_PER_PAGE",
		"FEED_RANKING_MAX_POSTS_PER_PROFILE_PER_PAGE",
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

func TestLoadParsesFeedRankingPolicyEnvOverrides(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "feed")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "feed_service")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("FEED_RANKING_EXPERIMENT_KEY", "rank-social-v2")
	t.Setenv("FEED_RANKING_EXPERIMENT_VARIANTS", "control=80,rank-social-v2=20")
	t.Setenv("FEED_RANKING_EXPERIMENT_POLICIES", "rank-social-v2:socialFriendBoostHours=34")
	t.Setenv("FEED_RANKING_POST_INTEREST_WEIGHT", "1.35")
	t.Setenv("FEED_RANKING_COMMUNITY_INTEREST_WEIGHT", "0.55")
	t.Setenv("FEED_RANKING_SOCIAL_FRIEND_BOOST_HOURS", "28")
	t.Setenv("FEED_RANKING_SOCIAL_FOLLOWING_BOOST_HOURS", "16")
	t.Setenv("FEED_RANKING_CURRENT_CITY_BOOST_HOURS", "22")
	t.Setenv("FEED_RANKING_EXPLORATION_FRESHNESS_WINDOW", "36h")
	t.Setenv("FEED_RANKING_QUALITY_NEGATIVE_PENALTY_HOURS", "48")
	t.Setenv("FEED_RANKING_MAX_POSTS_PER_COMMUNITY_PER_PAGE", "2")
	t.Setenv("FEED_RANKING_NEGATIVE_INTEREST_MIN_WEIGHT", "0.2")
	t.Setenv("FEED_RANKING_DIRECT_NEGATIVE_FEEDBACK_DECAY_WINDOW", "72h")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.Feed.RankingExperimentKey != "rank-social-v2" ||
		cfg.Feed.RankingExperimentVariants != "control=80,rank-social-v2=20" ||
		cfg.Feed.RankingExperimentPolicies != "rank-social-v2:socialFriendBoostHours=34" ||
		cfg.Feed.RankingPostInterestWeight != 1.35 ||
		cfg.Feed.RankingCommunityInterestWeight != 0.55 ||
		cfg.Feed.RankingSocialFriendBoostHours != 28 ||
		cfg.Feed.RankingSocialFollowingBoostHours != 16 ||
		cfg.Feed.RankingCurrentCityBoostHours != 22 ||
		cfg.Feed.RankingExplorationFreshnessWindow != 36*time.Hour ||
		cfg.Feed.RankingQualityNegativePenaltyHours != 48 ||
		cfg.Feed.RankingMaxPostsPerCommunityPerPage != 2 ||
		cfg.Feed.RankingNegativeInterestMinWeight != 0.2 ||
		cfg.Feed.RankingDirectNegativeFeedbackDecayWindow != 72*time.Hour {
		t.Fatalf("Feed ranking env overrides were not parsed: %+v", cfg.Feed)
	}
}

func TestLoadIncludesUserRouteDownstreamDefault(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "feed")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "feed_service")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.UserRoute.HTTPURL != "http://user-route-service:8096" {
		t.Fatalf("user route downstream = %q, want http://user-route-service:8096", cfg.UserRoute.HTTPURL)
	}
	if cfg.UserRoute.RequestTimeout != 3*time.Second {
		t.Fatalf("user route timeout = %v, want 3s", cfg.UserRoute.RequestTimeout)
	}
}

func TestLoadSearchServiceDefaults(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "feed")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "feed_service")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.SearchService.Enabled {
		t.Fatal("search indexing enabled by default, want disabled")
	}
	if cfg.SearchService.HTTPURL != "http://search-service:8101" {
		t.Fatalf("search service url = %q", cfg.SearchService.HTTPURL)
	}
	if cfg.SearchService.Timeout != 800*time.Millisecond {
		t.Fatalf("search service timeout = %s, want 800ms", cfg.SearchService.Timeout)
	}
}

func TestLoadSearchServiceConfigFromEnvironment(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "feed")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "feed_service")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("SEARCH_INDEXING_ENABLED", "true")
	t.Setenv("SEARCH_SERVICE_HTTP_URL", "http://search.test")
	t.Setenv("SEARCH_SERVICE_TIMEOUT", "250ms")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if !cfg.SearchService.Enabled {
		t.Fatal("search indexing disabled, want enabled")
	}
	if cfg.SearchService.HTTPURL != "http://search.test" {
		t.Fatalf("search service url = %q", cfg.SearchService.HTTPURL)
	}
	if cfg.SearchService.Timeout != 250*time.Millisecond {
		t.Fatalf("search service timeout = %s, want 250ms", cfg.SearchService.Timeout)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "feed")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "feed_service")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/feed-service/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/feed-service/client-key.pem")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	transport := cfg.MTLS.ClientConfig("search-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ClientCertPath != "/run/mtls/feed-service/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/feed-service/client-key.pem" ||
		transport.ServerName != "search-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}
}

func TestLoadInternalHTTPTLSPortFromEnvironment(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "feed")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "feed_service")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9487")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.HTTP.InternalTLSPort != 9487 {
		t.Fatalf("HTTP.InternalTLSPort = %d, want 9487", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9487" {
		t.Fatalf("HTTP.InternalTLSAddress() = %q, want :9487", cfg.HTTP.InternalTLSAddress())
	}
}
