package repository

import (
	"os"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func TestDefaultFeedRankingPolicyDocumentsProductionSafeWeights(t *testing.T) {
	policy := DefaultFeedRankingPolicy()

	if policy.ExperimentKey != "control" {
		t.Fatalf("ExperimentKey = %q, want control", policy.ExperimentKey)
	}
	if policy.PostInterestWeight != 1 ||
		policy.CommunityInterestWeight != 0.35 ||
		policy.PostProfileAffinityWeight != 0.18 ||
		policy.CityAffinityWeight != 0.25 ||
		policy.CountryAffinityWeight != 0.10 ||
		policy.CategoryAffinityWeight != 0.20 ||
		policy.TagAffinityWeight != 0.15 ||
		policy.AuthorAffinityWeight != 0.30 {
		t.Fatalf("unexpected default interest weights: %+v", policy)
	}
	if policy.InterestFreshnessDelay != 5*time.Minute {
		t.Fatalf("InterestFreshnessDelay = %s, want 5m", policy.InterestFreshnessDelay)
	}
	if policy.NotInterestedPenalty != 14*24*time.Hour {
		t.Fatalf("NotInterestedPenalty = %s, want 336h", policy.NotInterestedPenalty)
	}
	if policy.RecentPostImpressionWindow != 48*time.Hour ||
		policy.RecentPostImpressionPenaltyHours != 72 {
		t.Fatalf("unexpected recent post impression fatigue policy: %+v", policy)
	}
	if policy.RecentCommunityEventWindow != 24*time.Hour ||
		policy.RecentCommunityPenaltyHours != 8 {
		t.Fatalf("unexpected diversity policy: %+v", policy)
	}
	if policy.CommunityMembershipBoostHours != 10 {
		t.Fatalf("CommunityMembershipBoostHours = %d, want 10", policy.CommunityMembershipBoostHours)
	}
	if policy.CurrentCityBoostHours != 14 ||
		policy.CurrentCountryBoostHours != 6 {
		t.Fatalf("unexpected current geo boost policy: %+v", policy)
	}
	if policy.ExplorationFreshnessWindow != 72*time.Hour ||
		policy.ExplorationLowViewThreshold != 25 ||
		policy.ExplorationMaxBoostHours != 18 {
		t.Fatalf("unexpected exploration policy: %+v", policy)
	}
	if policy.QualityPenaltyWindow != 7*24*time.Hour ||
		policy.QualityMinNegativeEvents != 3 ||
		policy.QualityNegativePenaltyHours != 24 ||
		policy.QualityMaxPenaltyHours != 168 {
		t.Fatalf("unexpected quality policy: %+v", policy)
	}
	if policy.MaxPostsPerCommunityPerPage != 3 ||
		policy.MaxPostsPerCategoryPerPage != 8 ||
		policy.MaxPostsPerAuthorPerPage != 4 ||
		policy.MaxPostsPerProfilePerPage != 10 {
		t.Fatalf("unexpected page diversity caps: %+v", policy)
	}
	if policy.ColdStartMaxBoostHours != 6 ||
		policy.ColdStartEngagementWeight != 1 {
		t.Fatalf("unexpected cold-start policy: %+v", policy)
	}
	if policy.EngagementMaxBoostHours != 12 ||
		policy.EngagementWeight != 0.5 ||
		policy.EngagementFreshnessWindow != 7*24*time.Hour {
		t.Fatalf("unexpected engagement policy: %+v", policy)
	}
	if policy.NegativeInterestDecayWindow != 30*24*time.Hour ||
		policy.NegativeInterestMinWeight != 0.15 {
		t.Fatalf("unexpected negative interest decay policy: %+v", policy)
	}
	if policy.DirectNegativeFeedbackDecayWindow != 14*24*time.Hour {
		t.Fatalf("DirectNegativeFeedbackDecayWindow = %s, want 336h", policy.DirectNegativeFeedbackDecayWindow)
	}
}

func TestFeedRankingPolicyAppliesRequestOverrideOverBaseline(t *testing.T) {
	base := DefaultFeedRankingPolicy()
	base.ExperimentKey = "control"
	base.PostInterestWeight = 1.1
	base.SocialFriendBoostHours = 12
	base.SocialFollowingBoostHours = 8
	base.CurrentCityBoostHours = 9
	base.DirectNegativeFeedbackDecayWindow = 48 * time.Hour

	postInterestWeight := 1.6
	socialFriendBoostHours := 34
	socialFollowingBoostHours := 21
	maxPostsPerAuthorPerPage := 2
	directNegativeDecayWindow := 72 * time.Hour
	policy := feedRankingPolicyWithOverride(base, &model.FeedRankingPolicyOverride{
		ExperimentKey:                     "rank-social-v2",
		PostInterestWeight:                &postInterestWeight,
		SocialFriendBoostHours:            &socialFriendBoostHours,
		SocialFollowingBoostHours:         &socialFollowingBoostHours,
		MaxPostsPerAuthorPerPage:          &maxPostsPerAuthorPerPage,
		DirectNegativeFeedbackDecayWindow: &directNegativeDecayWindow,
	})

	if policy.ExperimentKey != "rank-social-v2" {
		t.Fatalf("ExperimentKey = %q, want rank-social-v2", policy.ExperimentKey)
	}
	if policy.PostInterestWeight != 1.6 ||
		policy.SocialFriendBoostHours != 34 ||
		policy.SocialFollowingBoostHours != 21 ||
		policy.MaxPostsPerAuthorPerPage != 2 ||
		policy.DirectNegativeFeedbackDecayWindow != 72*time.Hour {
		t.Fatalf("override was not applied: %+v", policy)
	}
	if policy.CurrentCityBoostHours != 9 {
		t.Fatalf("CurrentCityBoostHours = %d, want unchanged baseline 9", policy.CurrentCityBoostHours)
	}
}

func TestFeedRankingPolicyNormalizesUnsafeExperimentInputs(t *testing.T) {
	policy := FeedRankingPolicy{
		ExperimentKey:                     strings.Repeat("x", 80),
		PostInterestWeight:                -1,
		CommunityInterestWeight:           -2,
		PostProfileAffinityWeight:         -3,
		CityAffinityWeight:                -4,
		CountryAffinityWeight:             -5,
		CategoryAffinityWeight:            -6,
		TagAffinityWeight:                 -7,
		AuthorAffinityWeight:              -8,
		MaxBoostHours:                     -1,
		MaxPenaltyHours:                   -1,
		InterestFreshnessDelay:            -1,
		NotInterestedPenalty:              -1,
		RecentPostImpressionWindow:        -1,
		RecentPostImpressionPenaltyHours:  -1,
		RecentCommunityEventWindow:        -1,
		RecentCommunityPenaltyHours:       -1,
		CommunityMembershipBoostHours:     -1,
		CurrentCityBoostHours:             -1,
		CurrentCountryBoostHours:          -1,
		ExplorationFreshnessWindow:        -1,
		ExplorationLowViewThreshold:       -1,
		ExplorationMaxBoostHours:          -1,
		QualityPenaltyWindow:              -1,
		QualityMinNegativeEvents:          -1,
		QualityNegativePenaltyHours:       -1,
		QualityMaxPenaltyHours:            -1,
		MaxPostsPerCommunityPerPage:       -1,
		MaxPostsPerCategoryPerPage:        -1,
		MaxPostsPerAuthorPerPage:          -1,
		MaxPostsPerProfilePerPage:         -1,
		ColdStartMaxBoostHours:            -1,
		ColdStartEngagementWeight:         -1,
		EngagementMaxBoostHours:           -1,
		EngagementWeight:                  -1,
		EngagementFreshnessWindow:         -1,
		NegativeInterestDecayWindow:       -1,
		NegativeInterestMinWeight:         -1,
		DirectNegativeFeedbackDecayWindow: -1,
	}

	normalized := policy.normalized()
	defaults := DefaultFeedRankingPolicy()

	if normalized.ExperimentKey != defaults.ExperimentKey {
		t.Fatalf("ExperimentKey = %q, want %q", normalized.ExperimentKey, defaults.ExperimentKey)
	}
	if normalized.PostInterestWeight != defaults.PostInterestWeight ||
		normalized.CommunityInterestWeight != defaults.CommunityInterestWeight ||
		normalized.PostProfileAffinityWeight != defaults.PostProfileAffinityWeight ||
		normalized.CityAffinityWeight != defaults.CityAffinityWeight ||
		normalized.CountryAffinityWeight != defaults.CountryAffinityWeight ||
		normalized.CategoryAffinityWeight != defaults.CategoryAffinityWeight ||
		normalized.TagAffinityWeight != defaults.TagAffinityWeight ||
		normalized.AuthorAffinityWeight != defaults.AuthorAffinityWeight {
		t.Fatalf("unsafe weights were not reset to defaults: %+v", normalized)
	}
	if normalized.MaxBoostHours != defaults.MaxBoostHours ||
		normalized.MaxPenaltyHours != defaults.MaxPenaltyHours ||
		normalized.InterestFreshnessDelay != defaults.InterestFreshnessDelay ||
		normalized.NotInterestedPenalty != defaults.NotInterestedPenalty ||
		normalized.RecentPostImpressionWindow != defaults.RecentPostImpressionWindow ||
		normalized.RecentPostImpressionPenaltyHours != defaults.RecentPostImpressionPenaltyHours {
		t.Fatalf("unsafe bounds were not reset to defaults: %+v", normalized)
	}
	if normalized.RecentCommunityEventWindow != defaults.RecentCommunityEventWindow ||
		normalized.RecentCommunityPenaltyHours != defaults.RecentCommunityPenaltyHours ||
		normalized.CommunityMembershipBoostHours != defaults.CommunityMembershipBoostHours ||
		normalized.CurrentCityBoostHours != defaults.CurrentCityBoostHours ||
		normalized.CurrentCountryBoostHours != defaults.CurrentCountryBoostHours ||
		normalized.ExplorationFreshnessWindow != defaults.ExplorationFreshnessWindow ||
		normalized.ExplorationLowViewThreshold != defaults.ExplorationLowViewThreshold ||
		normalized.ExplorationMaxBoostHours != defaults.ExplorationMaxBoostHours ||
		normalized.QualityPenaltyWindow != defaults.QualityPenaltyWindow ||
		normalized.QualityMinNegativeEvents != defaults.QualityMinNegativeEvents ||
		normalized.QualityNegativePenaltyHours != defaults.QualityNegativePenaltyHours ||
		normalized.QualityMaxPenaltyHours != defaults.QualityMaxPenaltyHours ||
		normalized.MaxPostsPerCommunityPerPage != defaults.MaxPostsPerCommunityPerPage ||
		normalized.MaxPostsPerCategoryPerPage != defaults.MaxPostsPerCategoryPerPage ||
		normalized.MaxPostsPerAuthorPerPage != defaults.MaxPostsPerAuthorPerPage ||
		normalized.MaxPostsPerProfilePerPage != defaults.MaxPostsPerProfilePerPage ||
		normalized.ColdStartMaxBoostHours != defaults.ColdStartMaxBoostHours ||
		normalized.ColdStartEngagementWeight != defaults.ColdStartEngagementWeight ||
		normalized.EngagementMaxBoostHours != defaults.EngagementMaxBoostHours ||
		normalized.EngagementWeight != defaults.EngagementWeight ||
		normalized.EngagementFreshnessWindow != defaults.EngagementFreshnessWindow ||
		normalized.NegativeInterestDecayWindow != defaults.NegativeInterestDecayWindow ||
		normalized.NegativeInterestMinWeight != defaults.NegativeInterestMinWeight ||
		normalized.DirectNegativeFeedbackDecayWindow != defaults.DirectNegativeFeedbackDecayWindow {
		t.Fatalf("unsafe diversity/cold-start values were not reset to defaults: %+v", normalized)
	}
}

func TestFeedRankingPolicyDecaysNegativeInterestScoresByAge(t *testing.T) {
	policy := DefaultFeedRankingPolicy()
	policy.NegativeInterestDecayWindow = 10 * 24 * time.Hour
	policy.NegativeInterestMinWeight = 0.25

	expr := policy.normalized().personalizedScoreExpression(3, 0, 0)

	for _, needle := range []string{
		"CASE WHEN COALESCE(post_interest.score, 0) < 0 THEN",
		"EXTRACT(EPOCH FROM (NOW() - COALESCE(post_interest.last_event_at, NOW())))",
		"/ 864000",
		"LEAST(1, GREATEST(0.25, 1 -",
		"ELSE COALESCE(post_interest.score, 0)",
		"CASE WHEN COALESCE(community_interest.score, 0) < 0 THEN",
		"CASE WHEN COALESCE(profile_interest.score, 0) < 0 THEN",
		"CASE WHEN COALESCE(author_interest.score, 0) < 0 THEN",
		"CASE WHEN COALESCE(category_interest.score, 0) < 0 THEN",
		"CASE WHEN COALESCE(tag_interest.score, 0) < 0 THEN",
	} {
		if !strings.Contains(expr, needle) {
			t.Fatalf("personalized score expression must contain negative interest decay %q\n%s", needle, expr)
		}
	}
}

func TestFeedRankingPolicyDecaysDirectNegativeFeedbackPenaltyByAge(t *testing.T) {
	policy := DefaultFeedRankingPolicy()
	policy.NotInterestedPenalty = 7 * 24 * time.Hour
	policy.DirectNegativeFeedbackDecayWindow = 3 * 24 * time.Hour

	expr := policy.normalized().viewerRankedAtExpression(2, 0, 0)

	for _, needle := range []string{
		"FROM post_feed_events negative",
		"negative.viewer_user_id = $2",
		"negative.post_id = fi.post_id",
		"negative.event_type IN ('not_interested', 'report')",
		"negative.received_at >= NOW() - make_interval(secs => 259200)",
		"MAX(negative.received_at)",
		"make_interval(secs => FLOOR(604800 * GREATEST(0, 1 -",
		"EXTRACT(EPOCH FROM (NOW() - COALESCE(",
		"/ 259200",
	} {
		if !strings.Contains(expr, needle) {
			t.Fatalf("viewer ranked-at expression must contain direct negative decay %q\n%s", needle, expr)
		}
	}
	if strings.Contains(expr, "THEN fi.rank_published_at - make_interval(secs => 604800)") {
		t.Fatalf("viewer ranked-at expression still uses non-decaying direct negative penalty:\n%s", expr)
	}
}

func TestFeedRankingPolicyBuildsConfigurablePageDiversityCaps(t *testing.T) {
	policy := DefaultFeedRankingPolicy()
	policy.MaxPostsPerCommunityPerPage = 2
	policy.MaxPostsPerCategoryPerPage = 5
	policy.MaxPostsPerAuthorPerPage = 3
	policy.MaxPostsPerProfilePerPage = 4

	if policy.normalized().MaxPostsPerCommunityPerPage != 2 ||
		policy.normalized().MaxPostsPerCategoryPerPage != 5 ||
		policy.normalized().MaxPostsPerAuthorPerPage != 3 ||
		policy.normalized().MaxPostsPerProfilePerPage != 4 {
		t.Fatalf("page diversity caps were not configurable: %+v", policy.normalized())
	}
}

func TestFeedRankingPolicyBuildsConfigurablePersonalizedScoreExpression(t *testing.T) {
	policy := DefaultFeedRankingPolicy()
	policy.CommunityInterestWeight = 0.42
	policy.PostProfileAffinityWeight = 0.22
	policy.TagAffinityWeight = 0.27
	policy.AuthorAffinityWeight = 0.33
	policy.EngagementWeight = 0.7
	policy.EngagementMaxBoostHours = 9
	policy.EngagementFreshnessWindow = 12 * time.Hour
	policy.CommunityMembershipBoostHours = 5
	policy.CurrentCityBoostHours = 13
	policy.CurrentCountryBoostHours = 4
	policy.ExplorationFreshnessWindow = 5 * time.Hour
	policy.ExplorationLowViewThreshold = 7
	policy.ExplorationMaxBoostHours = 11

	expr := policy.normalized().personalizedScoreExpression(3, 4, 5)

	for _, needle := range []string{
		"COALESCE(post_interest.score, 0)",
		"* 1",
		"COALESCE(community_interest.score, 0)",
		"* 0.42",
		"COALESCE(profile_interest.score, 0)",
		"* 0.22",
		"COALESCE(city_interest.score, 0)",
		"* 0.25",
		"COALESCE(country_interest.score, 0)",
		"* 0.1",
		"COALESCE(category_interest.score, 0)",
		"* 0.2",
		"COALESCE(tag_interest.score, 0)",
		"* 0.27",
		"COALESCE(author_interest.score, 0)",
		"* 0.33",
		"LEAST(9, GREATEST(0, FLOOR(",
		"LOG(2 + s.view_count + s.like_count * 2 + s.comment_count * 3 + s.share_count * 4) * 0.7",
		"EXTRACT(EPOCH FROM (NOW() - COALESCE(s.published_at, s.created_at)))",
		"/ 43200",
		"GREATEST(0, 1 -",
		"FROM community_memberships community_membership",
		"community_membership.community_id = fi.community_id",
		"community_membership.user_id = $3",
		"community_membership.status = 'ACTIVE'",
		"THEN 5",
		"LOWER(COALESCE(s.place_city_id, '')) = LOWER($4)",
		"THEN 13",
		"UPPER(COALESCE(s.place_country_code, '')) = UPPER($5)",
		"THEN 4",
		"COALESCE(s.published_at, s.created_at) >= NOW() - make_interval(secs => 18000)",
		"s.view_count <= 7",
		"LEAST(11, GREATEST(0, 11 - FLOOR((s.view_count::numeric / 7) * 11)))",
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
	policy.RecentPostImpressionWindow = 6 * time.Hour
	policy.RecentPostImpressionPenaltyHours = 18
	policy.QualityPenaltyWindow = 8 * time.Hour
	policy.QualityMinNegativeEvents = 2
	policy.QualityNegativePenaltyHours = 13
	policy.QualityMaxPenaltyHours = 39
	expr := policy.normalized().viewerRankedAtExpression(1, 0, 0)

	for _, needle := range []string{
		"FROM post_feed_events quality_negative",
		"quality_negative.post_id = fi.post_id",
		"quality_negative.event_type IN ('hide', 'not_interested', 'report')",
		"quality_negative.received_at >= NOW() - make_interval(secs => 28800)",
		">= 2",
		"LEAST(39, GREATEST(0,",
		"* 13",
		"FROM post_feed_events recent_post_impression",
		"recent_post_impression.viewer_user_id = $1",
		"recent_post_impression.post_id = fi.post_id",
		"recent_post_impression.event_type IN ('impression', 'click', 'dwell')",
		"recent_post_impression.occurred_at >= NOW() - make_interval(secs => 21600)",
		"make_interval(hours => 18)",
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

func TestFeedRankingPolicyAppliesOpenReportQualityPenalty(t *testing.T) {
	policy := DefaultFeedRankingPolicy()
	policy.QualityPenaltyWindow = 12 * time.Hour
	policy.QualityMinNegativeEvents = 2
	policy.QualityNegativePenaltyHours = 9
	policy.QualityMaxPenaltyHours = 54

	expr := policy.normalized().qualityPenaltyExpression()

	for _, needle := range []string{
		"FROM post_reports quality_report",
		"quality_report.post_id = fi.post_id",
		"quality_report.status = 'OPEN'",
		"quality_report.created_at >= NOW() - make_interval(secs => 43200)",
		"UNION ALL",
		"quality_signal",
		">= 2",
		"* 9",
		"LEAST(54, GREATEST(0,",
	} {
		if !strings.Contains(expr, needle) {
			t.Fatalf("quality penalty expression must contain report penalty %q\n%s", needle, expr)
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
		"feedEventMetadataWithRankingExperiment",
		"r.feedRankingPolicy.normalized().ExperimentKey",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateFeedEvents source must contain %q", needle)
		}
	}
}

func TestFeedEventProjectionDerivesCommunityNegativeInterestFromPostMetadata(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)

	for _, needle := range []string{
		"'community' AS entity_type",
		"NULLIF(metadata->>'communityId', '')",
		"score * 0.60 AS score",
		"WHERE NULLIF(metadata->>'communityId', '') IS NOT NULL",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("CreateFeedEvents source must derive community feedback from post metadata %q\n%s", needle, source)
		}
	}
}

func TestInterestCandidateSourceSuppressesFreshNegativeInterestMatches(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_feed_repository.go")
	if err != nil {
		t.Fatalf("read feed repository source: %v", err)
	}
	source := string(sourceBytes)

	for _, needle := range []string{
		"NOT EXISTS (",
		"FROM post_feed_user_interests negative_source_interest",
		"negative_source_interest.viewer_user_id = $%d",
		"negative_source_interest.score < 0",
		"negative_source_interest.last_event_at >= NOW() - %s",
		"policy.durationSQL(policy.DirectNegativeFeedbackDecayWindow)",
		"(negative_source_interest.entity_type = 'post' AND negative_source_interest.entity_id = fi.post_id::text)",
		"(negative_source_interest.entity_type = 'community' AND negative_source_interest.entity_id = %s::text)",
		"(negative_source_interest.entity_type = 'post_profile' AND negative_source_interest.entity_id = lower(s.post_profile_key))",
		"(negative_source_interest.entity_type = 'author' AND negative_source_interest.entity_id = s.author_user_id::text)",
		"(negative_source_interest.entity_type = 'category' AND negative_source_interest.entity_id = lower(s.category))",
		"negative_source_interest.entity_type = 'tag'",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("interest candidate source must suppress fresh negative interest matches %q\n%s", needle, source)
		}
	}
}
