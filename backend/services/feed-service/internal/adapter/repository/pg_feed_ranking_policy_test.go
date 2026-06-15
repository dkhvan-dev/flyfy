package repository

import (
	"os"
	"strings"
	"testing"
	"time"
)

func TestDefaultFeedRankingPolicyDocumentsProductionSafeWeights(t *testing.T) {
	policy := DefaultFeedRankingPolicy()

	if policy.ExperimentKey != "control" {
		t.Fatalf("ExperimentKey = %q, want control", policy.ExperimentKey)
	}
	if policy.PostInterestWeight != 1 ||
		policy.CommunityInterestWeight != 0.35 ||
		policy.CityAffinityWeight != 0.25 ||
		policy.CountryAffinityWeight != 0.10 ||
		policy.CategoryAffinityWeight != 0.20 ||
		policy.TagAffinityWeight != 0.15 {
		t.Fatalf("unexpected default interest weights: %+v", policy)
	}
	if policy.InterestFreshnessDelay != 5*time.Minute {
		t.Fatalf("InterestFreshnessDelay = %s, want 5m", policy.InterestFreshnessDelay)
	}
	if policy.NotInterestedPenalty != 14*24*time.Hour {
		t.Fatalf("NotInterestedPenalty = %s, want 336h", policy.NotInterestedPenalty)
	}
	if policy.RecentCommunityEventWindow != 24*time.Hour ||
		policy.RecentCommunityPenaltyHours != 8 {
		t.Fatalf("unexpected diversity policy: %+v", policy)
	}
	if policy.MaxPostsPerCommunityPerPage != 3 ||
		policy.MaxPostsPerCategoryPerPage != 8 ||
		policy.MaxPostsPerAuthorPerPage != 4 {
		t.Fatalf("unexpected page diversity caps: %+v", policy)
	}
	if policy.ColdStartMaxBoostHours != 6 ||
		policy.ColdStartEngagementWeight != 1 {
		t.Fatalf("unexpected cold-start policy: %+v", policy)
	}
}

func TestFeedRankingPolicyNormalizesUnsafeExperimentInputs(t *testing.T) {
	policy := FeedRankingPolicy{
		ExperimentKey:               strings.Repeat("x", 80),
		PostInterestWeight:          -1,
		CommunityInterestWeight:     -2,
		CityAffinityWeight:          -3,
		CountryAffinityWeight:       -4,
		CategoryAffinityWeight:      -5,
		TagAffinityWeight:           -6,
		MaxBoostHours:               -1,
		MaxPenaltyHours:             -1,
		InterestFreshnessDelay:      -1,
		NotInterestedPenalty:        -1,
		RecentCommunityEventWindow:  -1,
		RecentCommunityPenaltyHours: -1,
		MaxPostsPerCommunityPerPage: -1,
		MaxPostsPerCategoryPerPage:  -1,
		MaxPostsPerAuthorPerPage:    -1,
		ColdStartMaxBoostHours:      -1,
		ColdStartEngagementWeight:   -1,
	}

	normalized := policy.normalized()
	defaults := DefaultFeedRankingPolicy()

	if normalized.ExperimentKey != defaults.ExperimentKey {
		t.Fatalf("ExperimentKey = %q, want %q", normalized.ExperimentKey, defaults.ExperimentKey)
	}
	if normalized.PostInterestWeight != defaults.PostInterestWeight ||
		normalized.CommunityInterestWeight != defaults.CommunityInterestWeight ||
		normalized.CityAffinityWeight != defaults.CityAffinityWeight ||
		normalized.CountryAffinityWeight != defaults.CountryAffinityWeight ||
		normalized.CategoryAffinityWeight != defaults.CategoryAffinityWeight ||
		normalized.TagAffinityWeight != defaults.TagAffinityWeight {
		t.Fatalf("unsafe weights were not reset to defaults: %+v", normalized)
	}
	if normalized.MaxBoostHours != defaults.MaxBoostHours ||
		normalized.MaxPenaltyHours != defaults.MaxPenaltyHours ||
		normalized.InterestFreshnessDelay != defaults.InterestFreshnessDelay ||
		normalized.NotInterestedPenalty != defaults.NotInterestedPenalty {
		t.Fatalf("unsafe bounds were not reset to defaults: %+v", normalized)
	}
	if normalized.RecentCommunityEventWindow != defaults.RecentCommunityEventWindow ||
		normalized.RecentCommunityPenaltyHours != defaults.RecentCommunityPenaltyHours ||
		normalized.MaxPostsPerCommunityPerPage != defaults.MaxPostsPerCommunityPerPage ||
		normalized.MaxPostsPerCategoryPerPage != defaults.MaxPostsPerCategoryPerPage ||
		normalized.MaxPostsPerAuthorPerPage != defaults.MaxPostsPerAuthorPerPage ||
		normalized.ColdStartMaxBoostHours != defaults.ColdStartMaxBoostHours ||
		normalized.ColdStartEngagementWeight != defaults.ColdStartEngagementWeight {
		t.Fatalf("unsafe diversity/cold-start values were not reset to defaults: %+v", normalized)
	}
}

func TestFeedRankingPolicyBuildsConfigurablePageDiversityCaps(t *testing.T) {
	policy := DefaultFeedRankingPolicy()
	policy.MaxPostsPerCommunityPerPage = 2
	policy.MaxPostsPerCategoryPerPage = 5
	policy.MaxPostsPerAuthorPerPage = 3

	if policy.normalized().MaxPostsPerCommunityPerPage != 2 ||
		policy.normalized().MaxPostsPerCategoryPerPage != 5 ||
		policy.normalized().MaxPostsPerAuthorPerPage != 3 {
		t.Fatalf("page diversity caps were not configurable: %+v", policy.normalized())
	}
}

func TestFeedRankingPolicyBuildsConfigurablePersonalizedScoreExpression(t *testing.T) {
	policy := DefaultFeedRankingPolicy()
	policy.CommunityInterestWeight = 0.42
	policy.TagAffinityWeight = 0.27

	expr := policy.normalized().personalizedScoreExpression()

	for _, needle := range []string{
		"COALESCE(post_interest.score, 0) * 1",
		"COALESCE(community_interest.score, 0) * 0.42",
		"COALESCE(city_interest.score, 0) * 0.25",
		"COALESCE(country_interest.score, 0) * 0.1",
		"COALESCE(category_interest.score, 0) * 0.2",
		"COALESCE(tag_interest.score, 0) * 0.27",
	} {
		if !strings.Contains(expr, needle) {
			t.Fatalf("personalized score expression must contain %q\n%s", needle, expr)
		}
	}
	if strings.Contains(expr, "* 0.35") || strings.Contains(expr, "* 0.15") {
		t.Fatalf("personalized score expression still contains old hardcoded weights:\n%s", expr)
	}
}

func TestFeedRankingPolicyAddsDiversityAndColdStartAdjustments(t *testing.T) {
	policy := DefaultFeedRankingPolicy()
	expr := policy.normalized().viewerRankedAtExpression(1)

	for _, needle := range []string{
		"FROM post_feed_events recent_community_event",
		"recent_community_event.community_id = fi.community_id",
		"recent_community_event.event_type IN ('impression', 'click')",
		"recent_community_event.occurred_at >= NOW() - make_interval(secs => 86400)",
		"make_interval(hours => 8)",
		"FROM post_feed_user_interests cold_start_interest_probe",
		"cold_start_interest_probe.viewer_user_id = $1",
		"LOG(2 + s.view_count + s.like_count * 2 + s.comment_count * 3)",
		"LEAST(6, GREATEST(0, FLOOR(",
	} {
		if !strings.Contains(expr, needle) {
			t.Fatalf("viewer ranked-at expression must contain %q\n%s", needle, expr)
		}
	}
}

func TestFeedRankingPolicyTagsProjectedInterestsWithExperimentKey(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)

	for _, needle := range []string{
		"'rankingExperiment', NULLIF($16::text, '')",
		"r.feedRankingPolicy.normalized().ExperimentKey",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateFeedEvents source must contain %q", needle)
		}
	}
}
