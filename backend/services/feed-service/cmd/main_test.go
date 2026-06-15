package main

import (
	"testing"
	"time"

	"kz/inflap/backend/services/feed-service/internal/config"
)

func TestFeedRankingPolicyFromConfigMapsFeedRankingKnobs(t *testing.T) {
	cfg := config.FeedConfig{
		RankingExperimentKey:               "rank-v2",
		RankingPostInterestWeight:          1.2,
		RankingCommunityInterestWeight:     0.4,
		RankingCityAffinityWeight:          0.3,
		RankingCountryAffinityWeight:       0.2,
		RankingCategoryAffinityWeight:      0.5,
		RankingTagAffinityWeight:           0.6,
		RankingMaxBoostHours:               48,
		RankingMaxPenaltyHours:             240,
		RankingInterestFreshnessDelay:      10 * time.Minute,
		RankingNotInterestedPenalty:        7 * 24 * time.Hour,
		RankingRecentCommunityEventWindow:  12 * time.Hour,
		RankingRecentCommunityPenaltyHours: 4,
		RankingMaxPostsPerCommunityPerPage: 2,
		RankingMaxPostsPerCategoryPerPage:  6,
		RankingMaxPostsPerAuthorPerPage:    4,
		RankingColdStartMaxBoostHours:      3,
		RankingColdStartEngagementWeight:   0.75,
		CuratedMaxConversionBlocksPerPage:  1,
		CuratedMaxOfficialNewsCardsPerPage: 0,
		CuratedMaxProfileCardsPerPage:      1,
	}

	policy := feedRankingPolicyFromConfig(cfg)
	curatedPolicy := feedCuratedBlockPolicyFromConfig(cfg)

	if policy.ExperimentKey != "rank-v2" ||
		policy.PostInterestWeight != 1.2 ||
		policy.CommunityInterestWeight != 0.4 ||
		policy.CityAffinityWeight != 0.3 ||
		policy.CountryAffinityWeight != 0.2 ||
		policy.CategoryAffinityWeight != 0.5 ||
		policy.TagAffinityWeight != 0.6 ||
		policy.MaxBoostHours != 48 ||
		policy.MaxPenaltyHours != 240 ||
		policy.InterestFreshnessDelay != 10*time.Minute ||
		policy.NotInterestedPenalty != 7*24*time.Hour ||
		policy.RecentCommunityEventWindow != 12*time.Hour ||
		policy.RecentCommunityPenaltyHours != 4 ||
		policy.MaxPostsPerCommunityPerPage != 2 ||
		policy.MaxPostsPerCategoryPerPage != 6 ||
		policy.MaxPostsPerAuthorPerPage != 4 ||
		policy.ColdStartMaxBoostHours != 3 ||
		policy.ColdStartEngagementWeight != 0.75 {
		t.Fatalf("policy did not map feed config: %+v", policy)
	}
	if curatedPolicy.MaxConversionBlocksPerPage != 1 ||
		curatedPolicy.MaxOfficialNewsCardsPerPage != 0 ||
		curatedPolicy.MaxProfileCardsPerPage != 1 {
		t.Fatalf("curated policy did not map feed config: %+v", curatedPolicy)
	}
}
