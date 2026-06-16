package main

import (
	"testing"
	"time"

	"kz/inflap/backend/services/feed-service/internal/config"
)

func TestFeedRankingPolicyFromConfigMapsFeedRankingKnobs(t *testing.T) {
	cfg := config.FeedConfig{
		RankingExperimentKey:                     "rank-v2",
		RankingExperimentVariants:                "control=75,rank-v2=25",
		RankingPostInterestWeight:                1.2,
		RankingCommunityInterestWeight:           0.4,
		RankingPostProfileAffinityWeight:         0.25,
		RankingCityAffinityWeight:                0.3,
		RankingCountryAffinityWeight:             0.2,
		RankingCategoryAffinityWeight:            0.5,
		RankingTagAffinityWeight:                 0.6,
		RankingAuthorAffinityWeight:              0.45,
		RankingMaxBoostHours:                     48,
		RankingMaxPenaltyHours:                   240,
		RankingInterestFreshnessDelay:            10 * time.Minute,
		RankingNotInterestedPenalty:              7 * 24 * time.Hour,
		RankingRecentPostImpressionWindow:        6 * time.Hour,
		RankingRecentPostImpressionPenaltyHours:  18,
		RankingRecentCommunityEventWindow:        12 * time.Hour,
		RankingRecentCommunityPenaltyHours:       4,
		RankingCommunityMembershipBoostHours:     5,
		RankingSocialFriendBoostHours:            31,
		RankingSocialFollowingBoostHours:         17,
		RankingCurrentCityBoostHours:             12,
		RankingCurrentCountryBoostHours:          6,
		RankingExplorationFreshnessWindow:        5 * time.Hour,
		RankingExplorationLowViewThreshold:       7,
		RankingExplorationMaxBoostHours:          11,
		RankingQualityPenaltyWindow:              8 * time.Hour,
		RankingQualityMinNegativeEvents:          2,
		RankingQualityNegativePenaltyHours:       13,
		RankingQualityMaxPenaltyHours:            39,
		RankingMaxPostsPerCommunityPerPage:       2,
		RankingMaxPostsPerCategoryPerPage:        6,
		RankingMaxPostsPerAuthorPerPage:          4,
		RankingMaxPostsPerProfilePerPage:         7,
		RankingColdStartMaxBoostHours:            3,
		RankingColdStartEngagementWeight:         0.75,
		RankingEngagementMaxBoostHours:           9,
		RankingEngagementWeight:                  0.65,
		RankingEngagementFreshnessWindow:         12 * time.Hour,
		RankingNegativeInterestDecayWindow:       10 * 24 * time.Hour,
		RankingNegativeInterestMinWeight:         0.25,
		RankingDirectNegativeFeedbackDecayWindow: 36 * time.Hour,
		CuratedMaxConversionBlocksPerPage:        1,
		CuratedMaxOfficialNewsCardsPerPage:       0,
		CuratedMaxProfileCardsPerPage:            1,
	}

	policy := feedRankingPolicyFromConfig(cfg)
	curatedPolicy := feedCuratedBlockPolicyFromConfig(cfg)

	if policy.ExperimentKey != "rank-v2" ||
		policy.PostInterestWeight != 1.2 ||
		policy.CommunityInterestWeight != 0.4 ||
		policy.PostProfileAffinityWeight != 0.25 ||
		policy.CityAffinityWeight != 0.3 ||
		policy.CountryAffinityWeight != 0.2 ||
		policy.CategoryAffinityWeight != 0.5 ||
		policy.TagAffinityWeight != 0.6 ||
		policy.AuthorAffinityWeight != 0.45 ||
		policy.MaxBoostHours != 48 ||
		policy.MaxPenaltyHours != 240 ||
		policy.InterestFreshnessDelay != 10*time.Minute ||
		policy.NotInterestedPenalty != 7*24*time.Hour ||
		policy.RecentPostImpressionWindow != 6*time.Hour ||
		policy.RecentPostImpressionPenaltyHours != 18 ||
		policy.RecentCommunityEventWindow != 12*time.Hour ||
		policy.RecentCommunityPenaltyHours != 4 ||
		policy.CommunityMembershipBoostHours != 5 ||
		policy.SocialFriendBoostHours != 31 ||
		policy.SocialFollowingBoostHours != 17 ||
		policy.CurrentCityBoostHours != 12 ||
		policy.CurrentCountryBoostHours != 6 ||
		policy.ExplorationFreshnessWindow != 5*time.Hour ||
		policy.ExplorationLowViewThreshold != 7 ||
		policy.ExplorationMaxBoostHours != 11 ||
		policy.QualityPenaltyWindow != 8*time.Hour ||
		policy.QualityMinNegativeEvents != 2 ||
		policy.QualityNegativePenaltyHours != 13 ||
		policy.QualityMaxPenaltyHours != 39 ||
		policy.MaxPostsPerCommunityPerPage != 2 ||
		policy.MaxPostsPerCategoryPerPage != 6 ||
		policy.MaxPostsPerAuthorPerPage != 4 ||
		policy.MaxPostsPerProfilePerPage != 7 ||
		policy.ColdStartMaxBoostHours != 3 ||
		policy.ColdStartEngagementWeight != 0.75 ||
		policy.EngagementMaxBoostHours != 9 ||
		policy.EngagementWeight != 0.65 ||
		policy.EngagementFreshnessWindow != 12*time.Hour ||
		policy.NegativeInterestDecayWindow != 10*24*time.Hour ||
		policy.NegativeInterestMinWeight != 0.25 ||
		policy.DirectNegativeFeedbackDecayWindow != 36*time.Hour {
		t.Fatalf("policy did not map feed config: %+v", policy)
	}
	if curatedPolicy.MaxConversionBlocksPerPage != 1 ||
		curatedPolicy.MaxOfficialNewsCardsPerPage != 0 ||
		curatedPolicy.MaxProfileCardsPerPage != 1 {
		t.Fatalf("curated policy did not map feed config: %+v", curatedPolicy)
	}
}
