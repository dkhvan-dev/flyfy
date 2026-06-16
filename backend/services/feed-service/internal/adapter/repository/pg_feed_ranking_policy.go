package repository

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

const maxFeedRankingExperimentKeyLength = 48

type FeedRankingPolicy struct {
	ExperimentKey                     string
	PostInterestWeight                float64
	CommunityInterestWeight           float64
	PostProfileAffinityWeight         float64
	CityAffinityWeight                float64
	CountryAffinityWeight             float64
	CategoryAffinityWeight            float64
	TagAffinityWeight                 float64
	AuthorAffinityWeight              float64
	MaxBoostHours                     int
	MaxPenaltyHours                   int
	InterestFreshnessDelay            time.Duration
	NotInterestedPenalty              time.Duration
	RecentPostImpressionWindow        time.Duration
	RecentPostImpressionPenaltyHours  int
	RecentCommunityEventWindow        time.Duration
	RecentCommunityPenaltyHours       int
	CommunityMembershipBoostHours     int
	SocialFriendBoostHours            int
	SocialFollowingBoostHours         int
	CurrentCityBoostHours             int
	CurrentCountryBoostHours          int
	ExplorationFreshnessWindow        time.Duration
	ExplorationLowViewThreshold       int
	ExplorationMaxBoostHours          int
	QualityPenaltyWindow              time.Duration
	QualityMinNegativeEvents          int
	QualityNegativePenaltyHours       int
	QualityMaxPenaltyHours            int
	MaxPostsPerCommunityPerPage       int
	MaxPostsPerCategoryPerPage        int
	MaxPostsPerAuthorPerPage          int
	MaxPostsPerProfilePerPage         int
	ColdStartMaxBoostHours            int
	ColdStartEngagementWeight         float64
	EngagementMaxBoostHours           int
	EngagementWeight                  float64
	EngagementFreshnessWindow         time.Duration
	NegativeInterestDecayWindow       time.Duration
	NegativeInterestMinWeight         float64
	DirectNegativeFeedbackDecayWindow time.Duration
}

func DefaultFeedRankingPolicy() FeedRankingPolicy {
	return FeedRankingPolicy{
		ExperimentKey:                     "control",
		PostInterestWeight:                1,
		CommunityInterestWeight:           0.35,
		PostProfileAffinityWeight:         0.18,
		CityAffinityWeight:                0.25,
		CountryAffinityWeight:             0.10,
		CategoryAffinityWeight:            0.20,
		TagAffinityWeight:                 0.15,
		AuthorAffinityWeight:              0.30,
		MaxBoostHours:                     72,
		MaxPenaltyHours:                   336,
		InterestFreshnessDelay:            5 * time.Minute,
		NotInterestedPenalty:              14 * 24 * time.Hour,
		RecentPostImpressionWindow:        48 * time.Hour,
		RecentPostImpressionPenaltyHours:  72,
		RecentCommunityEventWindow:        24 * time.Hour,
		RecentCommunityPenaltyHours:       8,
		CommunityMembershipBoostHours:     10,
		SocialFriendBoostHours:            18,
		SocialFollowingBoostHours:         10,
		CurrentCityBoostHours:             14,
		CurrentCountryBoostHours:          6,
		ExplorationFreshnessWindow:        72 * time.Hour,
		ExplorationLowViewThreshold:       25,
		ExplorationMaxBoostHours:          18,
		QualityPenaltyWindow:              7 * 24 * time.Hour,
		QualityMinNegativeEvents:          3,
		QualityNegativePenaltyHours:       24,
		QualityMaxPenaltyHours:            168,
		MaxPostsPerCommunityPerPage:       3,
		MaxPostsPerCategoryPerPage:        8,
		MaxPostsPerAuthorPerPage:          4,
		MaxPostsPerProfilePerPage:         10,
		ColdStartMaxBoostHours:            6,
		ColdStartEngagementWeight:         1,
		EngagementMaxBoostHours:           12,
		EngagementWeight:                  0.5,
		EngagementFreshnessWindow:         7 * 24 * time.Hour,
		NegativeInterestDecayWindow:       30 * 24 * time.Hour,
		NegativeInterestMinWeight:         0.15,
		DirectNegativeFeedbackDecayWindow: 14 * 24 * time.Hour,
	}
}

func (p FeedRankingPolicy) normalized() FeedRankingPolicy {
	defaults := DefaultFeedRankingPolicy()

	p.ExperimentKey = normalizeFeedRankingExperimentKey(p.ExperimentKey, defaults.ExperimentKey)
	p.PostInterestWeight = normalizeFeedRankingWeight(p.PostInterestWeight, defaults.PostInterestWeight)
	p.CommunityInterestWeight = normalizeFeedRankingWeight(p.CommunityInterestWeight, defaults.CommunityInterestWeight)
	p.PostProfileAffinityWeight = normalizeFeedRankingWeight(p.PostProfileAffinityWeight, defaults.PostProfileAffinityWeight)
	p.CityAffinityWeight = normalizeFeedRankingWeight(p.CityAffinityWeight, defaults.CityAffinityWeight)
	p.CountryAffinityWeight = normalizeFeedRankingWeight(p.CountryAffinityWeight, defaults.CountryAffinityWeight)
	p.CategoryAffinityWeight = normalizeFeedRankingWeight(p.CategoryAffinityWeight, defaults.CategoryAffinityWeight)
	p.TagAffinityWeight = normalizeFeedRankingWeight(p.TagAffinityWeight, defaults.TagAffinityWeight)
	p.AuthorAffinityWeight = normalizeFeedRankingWeight(p.AuthorAffinityWeight, defaults.AuthorAffinityWeight)
	p.MaxBoostHours = normalizeFeedRankingHours(p.MaxBoostHours, defaults.MaxBoostHours, 168)
	p.MaxPenaltyHours = normalizeFeedRankingHours(p.MaxPenaltyHours, defaults.MaxPenaltyHours, 720)
	p.InterestFreshnessDelay = normalizeFeedRankingDuration(p.InterestFreshnessDelay, defaults.InterestFreshnessDelay, 24*time.Hour)
	p.NotInterestedPenalty = normalizeFeedRankingDuration(p.NotInterestedPenalty, defaults.NotInterestedPenalty, 30*24*time.Hour)
	p.RecentPostImpressionWindow = normalizeFeedRankingDuration(p.RecentPostImpressionWindow, defaults.RecentPostImpressionWindow, 14*24*time.Hour)
	p.RecentPostImpressionPenaltyHours = normalizeFeedRankingHours(p.RecentPostImpressionPenaltyHours, defaults.RecentPostImpressionPenaltyHours, 720)
	p.RecentCommunityEventWindow = normalizeFeedRankingDuration(p.RecentCommunityEventWindow, defaults.RecentCommunityEventWindow, 7*24*time.Hour)
	p.RecentCommunityPenaltyHours = normalizeFeedRankingHours(p.RecentCommunityPenaltyHours, defaults.RecentCommunityPenaltyHours, 72)
	p.CommunityMembershipBoostHours = normalizeFeedRankingHours(p.CommunityMembershipBoostHours, defaults.CommunityMembershipBoostHours, 72)
	p.SocialFriendBoostHours = normalizeFeedRankingHours(p.SocialFriendBoostHours, defaults.SocialFriendBoostHours, 72)
	p.SocialFollowingBoostHours = normalizeFeedRankingHours(p.SocialFollowingBoostHours, defaults.SocialFollowingBoostHours, 72)
	p.CurrentCityBoostHours = normalizeFeedRankingHours(p.CurrentCityBoostHours, defaults.CurrentCityBoostHours, 72)
	p.CurrentCountryBoostHours = normalizeFeedRankingHours(p.CurrentCountryBoostHours, defaults.CurrentCountryBoostHours, 72)
	p.ExplorationFreshnessWindow = normalizeFeedRankingDuration(p.ExplorationFreshnessWindow, defaults.ExplorationFreshnessWindow, 14*24*time.Hour)
	p.ExplorationLowViewThreshold = normalizeFeedRankingPositiveInt(p.ExplorationLowViewThreshold, defaults.ExplorationLowViewThreshold, 100000)
	p.ExplorationMaxBoostHours = normalizeFeedRankingHours(p.ExplorationMaxBoostHours, defaults.ExplorationMaxBoostHours, 72)
	p.QualityPenaltyWindow = normalizeFeedRankingDuration(p.QualityPenaltyWindow, defaults.QualityPenaltyWindow, 30*24*time.Hour)
	p.QualityMinNegativeEvents = normalizeFeedRankingPositiveInt(p.QualityMinNegativeEvents, defaults.QualityMinNegativeEvents, 10000)
	p.QualityNegativePenaltyHours = normalizeFeedRankingHours(p.QualityNegativePenaltyHours, defaults.QualityNegativePenaltyHours, 720)
	p.QualityMaxPenaltyHours = normalizeFeedRankingHours(p.QualityMaxPenaltyHours, defaults.QualityMaxPenaltyHours, 720)
	p.MaxPostsPerCommunityPerPage = normalizeFeedRankingPageCap(p.MaxPostsPerCommunityPerPage, defaults.MaxPostsPerCommunityPerPage, 20)
	p.MaxPostsPerCategoryPerPage = normalizeFeedRankingPageCap(p.MaxPostsPerCategoryPerPage, defaults.MaxPostsPerCategoryPerPage, 50)
	p.MaxPostsPerAuthorPerPage = normalizeFeedRankingPageCap(p.MaxPostsPerAuthorPerPage, defaults.MaxPostsPerAuthorPerPage, 20)
	p.MaxPostsPerProfilePerPage = normalizeFeedRankingPageCap(p.MaxPostsPerProfilePerPage, defaults.MaxPostsPerProfilePerPage, 50)
	p.ColdStartMaxBoostHours = normalizeFeedRankingHours(p.ColdStartMaxBoostHours, defaults.ColdStartMaxBoostHours, 24)
	p.ColdStartEngagementWeight = normalizeFeedRankingWeight(p.ColdStartEngagementWeight, defaults.ColdStartEngagementWeight)
	p.EngagementMaxBoostHours = normalizeFeedRankingHours(p.EngagementMaxBoostHours, defaults.EngagementMaxBoostHours, 72)
	p.EngagementWeight = normalizeFeedRankingWeight(p.EngagementWeight, defaults.EngagementWeight)
	p.EngagementFreshnessWindow = normalizeFeedRankingDuration(p.EngagementFreshnessWindow, defaults.EngagementFreshnessWindow, 30*24*time.Hour)
	p.NegativeInterestDecayWindow = normalizeFeedRankingDuration(p.NegativeInterestDecayWindow, defaults.NegativeInterestDecayWindow, 90*24*time.Hour)
	p.NegativeInterestMinWeight = normalizeFeedRankingFraction(p.NegativeInterestMinWeight, defaults.NegativeInterestMinWeight)
	p.DirectNegativeFeedbackDecayWindow = normalizeFeedRankingDuration(p.DirectNegativeFeedbackDecayWindow, defaults.DirectNegativeFeedbackDecayWindow, 90*24*time.Hour)

	return p
}

func (p FeedRankingPolicy) Normalized() FeedRankingPolicy {
	return p.normalized()
}

func feedRankingPolicyWithOverride(base FeedRankingPolicy, override *model.FeedRankingPolicyOverride) FeedRankingPolicy {
	p := base.normalized()
	if override == nil {
		return p
	}
	p.ExperimentKey = normalizeFeedRankingExperimentKey(override.ExperimentKey, p.ExperimentKey)
	p.PostInterestWeight = feedRankingWeightOverride(override.PostInterestWeight, p.PostInterestWeight)
	p.CommunityInterestWeight = feedRankingWeightOverride(override.CommunityInterestWeight, p.CommunityInterestWeight)
	p.PostProfileAffinityWeight = feedRankingWeightOverride(override.PostProfileAffinityWeight, p.PostProfileAffinityWeight)
	p.CityAffinityWeight = feedRankingWeightOverride(override.CityAffinityWeight, p.CityAffinityWeight)
	p.CountryAffinityWeight = feedRankingWeightOverride(override.CountryAffinityWeight, p.CountryAffinityWeight)
	p.CategoryAffinityWeight = feedRankingWeightOverride(override.CategoryAffinityWeight, p.CategoryAffinityWeight)
	p.TagAffinityWeight = feedRankingWeightOverride(override.TagAffinityWeight, p.TagAffinityWeight)
	p.AuthorAffinityWeight = feedRankingWeightOverride(override.AuthorAffinityWeight, p.AuthorAffinityWeight)
	p.MaxBoostHours = feedRankingHoursOverride(override.MaxBoostHours, p.MaxBoostHours, 168)
	p.MaxPenaltyHours = feedRankingHoursOverride(override.MaxPenaltyHours, p.MaxPenaltyHours, 720)
	p.InterestFreshnessDelay = feedRankingDurationOverride(override.InterestFreshnessDelay, p.InterestFreshnessDelay, 24*time.Hour)
	p.NotInterestedPenalty = feedRankingDurationOverride(override.NotInterestedPenalty, p.NotInterestedPenalty, 30*24*time.Hour)
	p.RecentPostImpressionWindow = feedRankingDurationOverride(override.RecentPostImpressionWindow, p.RecentPostImpressionWindow, 14*24*time.Hour)
	p.RecentPostImpressionPenaltyHours = feedRankingHoursOverride(override.RecentPostImpressionPenaltyHours, p.RecentPostImpressionPenaltyHours, 720)
	p.RecentCommunityEventWindow = feedRankingDurationOverride(override.RecentCommunityEventWindow, p.RecentCommunityEventWindow, 7*24*time.Hour)
	p.RecentCommunityPenaltyHours = feedRankingHoursOverride(override.RecentCommunityPenaltyHours, p.RecentCommunityPenaltyHours, 72)
	p.CommunityMembershipBoostHours = feedRankingHoursOverride(override.CommunityMembershipBoostHours, p.CommunityMembershipBoostHours, 72)
	p.SocialFriendBoostHours = feedRankingHoursOverride(override.SocialFriendBoostHours, p.SocialFriendBoostHours, 72)
	p.SocialFollowingBoostHours = feedRankingHoursOverride(override.SocialFollowingBoostHours, p.SocialFollowingBoostHours, 72)
	p.CurrentCityBoostHours = feedRankingHoursOverride(override.CurrentCityBoostHours, p.CurrentCityBoostHours, 72)
	p.CurrentCountryBoostHours = feedRankingHoursOverride(override.CurrentCountryBoostHours, p.CurrentCountryBoostHours, 72)
	p.ExplorationFreshnessWindow = feedRankingDurationOverride(override.ExplorationFreshnessWindow, p.ExplorationFreshnessWindow, 14*24*time.Hour)
	p.ExplorationLowViewThreshold = feedRankingPositiveIntOverride(override.ExplorationLowViewThreshold, p.ExplorationLowViewThreshold, 100000)
	p.ExplorationMaxBoostHours = feedRankingHoursOverride(override.ExplorationMaxBoostHours, p.ExplorationMaxBoostHours, 72)
	p.QualityPenaltyWindow = feedRankingDurationOverride(override.QualityPenaltyWindow, p.QualityPenaltyWindow, 30*24*time.Hour)
	p.QualityMinNegativeEvents = feedRankingPositiveIntOverride(override.QualityMinNegativeEvents, p.QualityMinNegativeEvents, 10000)
	p.QualityNegativePenaltyHours = feedRankingHoursOverride(override.QualityNegativePenaltyHours, p.QualityNegativePenaltyHours, 720)
	p.QualityMaxPenaltyHours = feedRankingHoursOverride(override.QualityMaxPenaltyHours, p.QualityMaxPenaltyHours, 720)
	p.MaxPostsPerCommunityPerPage = feedRankingPageCapOverride(override.MaxPostsPerCommunityPerPage, p.MaxPostsPerCommunityPerPage, 20)
	p.MaxPostsPerCategoryPerPage = feedRankingPageCapOverride(override.MaxPostsPerCategoryPerPage, p.MaxPostsPerCategoryPerPage, 50)
	p.MaxPostsPerAuthorPerPage = feedRankingPageCapOverride(override.MaxPostsPerAuthorPerPage, p.MaxPostsPerAuthorPerPage, 20)
	p.MaxPostsPerProfilePerPage = feedRankingPageCapOverride(override.MaxPostsPerProfilePerPage, p.MaxPostsPerProfilePerPage, 50)
	p.ColdStartMaxBoostHours = feedRankingHoursOverride(override.ColdStartMaxBoostHours, p.ColdStartMaxBoostHours, 24)
	p.ColdStartEngagementWeight = feedRankingWeightOverride(override.ColdStartEngagementWeight, p.ColdStartEngagementWeight)
	p.EngagementMaxBoostHours = feedRankingHoursOverride(override.EngagementMaxBoostHours, p.EngagementMaxBoostHours, 72)
	p.EngagementWeight = feedRankingWeightOverride(override.EngagementWeight, p.EngagementWeight)
	p.EngagementFreshnessWindow = feedRankingDurationOverride(override.EngagementFreshnessWindow, p.EngagementFreshnessWindow, 30*24*time.Hour)
	p.NegativeInterestDecayWindow = feedRankingDurationOverride(override.NegativeInterestDecayWindow, p.NegativeInterestDecayWindow, 90*24*time.Hour)
	p.NegativeInterestMinWeight = feedRankingFractionOverride(override.NegativeInterestMinWeight, p.NegativeInterestMinWeight)
	p.DirectNegativeFeedbackDecayWindow = feedRankingDurationOverride(override.DirectNegativeFeedbackDecayWindow, p.DirectNegativeFeedbackDecayWindow, 90*24*time.Hour)
	return p
}

func feedRankingWeightOverride(value *float64, fallback float64) float64 {
	if value == nil {
		return fallback
	}
	return normalizeFeedRankingWeight(*value, fallback)
}

func feedRankingFractionOverride(value *float64, fallback float64) float64 {
	if value == nil {
		return fallback
	}
	return normalizeFeedRankingFraction(*value, fallback)
}

func feedRankingHoursOverride(value *int, fallback int, max int) int {
	if value == nil {
		return fallback
	}
	return normalizeFeedRankingHours(*value, fallback, max)
}

func feedRankingPageCapOverride(value *int, fallback int, max int) int {
	if value == nil {
		return fallback
	}
	return normalizeFeedRankingPageCap(*value, fallback, max)
}

func feedRankingPositiveIntOverride(value *int, fallback int, max int) int {
	if value == nil {
		return fallback
	}
	return normalizeFeedRankingPositiveInt(*value, fallback, max)
}

func feedRankingDurationOverride(value *time.Duration, fallback time.Duration, max time.Duration) time.Duration {
	if value == nil {
		return fallback
	}
	return normalizeFeedRankingDuration(*value, fallback, max)
}

func (p FeedRankingPolicy) feedRankJoinsExpression(viewerUserIDPos int) string {
	p = p.normalized()
	freshnessSQL := p.durationSQL(p.InterestFreshnessDelay)

	return fmt.Sprintf(`
			LEFT JOIN post_feed_user_interests post_interest
				ON post_interest.viewer_user_id = $%d
			   AND post_interest.entity_type = 'post'
			   AND post_interest.entity_id = fi.post_id::text
			   AND post_interest.updated_at < NOW() - %s
			LEFT JOIN post_feed_user_interests community_interest
				ON community_interest.viewer_user_id = $%d
			   AND community_interest.entity_type = 'community'
			   AND fi.community_id IS NOT NULL
			   AND community_interest.entity_id = fi.community_id::text
			   AND community_interest.updated_at < NOW() - %s
			LEFT JOIN post_feed_user_interests profile_interest
				ON profile_interest.viewer_user_id = $%d
			   AND profile_interest.entity_type = 'post_profile'
			   AND profile_interest.entity_id = lower(s.post_profile_key)
			   AND profile_interest.updated_at < NOW() - %s
			LEFT JOIN post_feed_user_interests author_interest
				ON author_interest.viewer_user_id = $%d
			   AND author_interest.entity_type = 'author'
			   AND author_interest.entity_id = s.author_user_id::text
			   AND author_interest.updated_at < NOW() - %s
			LEFT JOIN post_feed_user_interests city_interest
				ON city_interest.viewer_user_id = $%d
			   AND city_interest.entity_type = 'city'
			   AND city_interest.entity_id = lower(s.place_city_id)
			   AND city_interest.updated_at < NOW() - %s
			LEFT JOIN post_feed_user_interests country_interest
				ON country_interest.viewer_user_id = $%d
			   AND country_interest.entity_type = 'country'
			   AND country_interest.entity_id = lower(s.place_country_code)
			   AND country_interest.updated_at < NOW() - %s
			LEFT JOIN post_feed_user_interests category_interest
				ON category_interest.viewer_user_id = $%d
			   AND category_interest.entity_type = 'category'
			   AND category_interest.entity_id = lower(s.category)
			   AND category_interest.updated_at < NOW() - %s
			LEFT JOIN LATERAL (
				SELECT
					SUM(tag_interest.score) AS score,
					MAX(tag_interest.last_event_at) AS last_event_at
				FROM post_feed_user_interests tag_interest
				WHERE tag_interest.viewer_user_id = $%d
				  AND tag_interest.entity_type = 'tag'
				  AND tag_interest.updated_at < NOW() - %s
				  AND tag_interest.entity_id IN (
					SELECT lower(post_tag.tag)
					FROM unnest(COALESCE(s.tags, ARRAY[]::text[])) AS post_tag(tag)
				  )
			) tag_interest ON TRUE
			LEFT JOIN post_feed_social_edges social_friend
				ON social_friend.viewer_user_id = $%d
			   AND social_friend.target_user_id = s.author_user_id
			   AND social_friend.edge_type = 'friend'
			   AND social_friend.active = true
			LEFT JOIN post_feed_social_edges social_following
				ON social_following.viewer_user_id = $%d
			   AND social_following.target_user_id = s.author_user_id
			   AND social_following.edge_type = 'following'
			   AND social_following.active = true
		`, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL, viewerUserIDPos, viewerUserIDPos)
}

func (p FeedRankingPolicy) viewerRankedAtExpression(viewerUserIDPos int, currentCityIDPos int, currentCountryCodePos int) string {
	p = p.normalized()
	baseRankExpression := "fi.rank_published_at"

	return fmt.Sprintf(`
			(
				%s
				+ make_interval(hours => LEAST(%d, GREATEST(-%d,
					%s
				))::int)
				- %s
				- %s
				- %s
				- %s
				+ %s
			)
		`,
		baseRankExpression,
		p.MaxBoostHours,
		p.MaxPenaltyHours,
		p.personalizedScoreExpression(viewerUserIDPos, currentCityIDPos, currentCountryCodePos),
		p.directNegativeFeedbackPenaltyExpression(viewerUserIDPos),
		p.qualityPenaltyExpression(),
		p.recentPostImpressionPenaltyExpression(viewerUserIDPos),
		p.recentCommunityDiversityPenaltyExpression(viewerUserIDPos),
		p.coldStartBoostExpression(viewerUserIDPos),
	)
}

func (p FeedRankingPolicy) directNegativeFeedbackPenaltyExpression(viewerUserIDPos int) string {
	p = p.normalized()
	if viewerUserIDPos <= 0 || p.NotInterestedPenalty <= 0 || p.DirectNegativeFeedbackDecayWindow <= 0 {
		return "make_interval(secs => 0)"
	}
	penaltySeconds := int(p.NotInterestedPenalty.Seconds())
	decayWindowSeconds := int(p.DirectNegativeFeedbackDecayWindow.Seconds())
	if penaltySeconds <= 0 || decayWindowSeconds <= 0 {
		return "make_interval(secs => 0)"
	}

	return fmt.Sprintf(`COALESCE((
					SELECT make_interval(secs => FLOOR(%d * GREATEST(0, 1 -
						(EXTRACT(EPOCH FROM (NOW() - COALESCE(MAX(negative.received_at), NOW()))) / %d)
					))::int)
					FROM post_feed_events negative
					WHERE negative.viewer_user_id = $%d
					  AND negative.post_id = fi.post_id
					  AND negative.event_type IN ('not_interested', 'report')
					  AND negative.received_at >= NOW() - %s
				), make_interval(secs => 0))`,
		penaltySeconds,
		decayWindowSeconds,
		viewerUserIDPos,
		p.durationSQL(p.DirectNegativeFeedbackDecayWindow),
	)
}

func (p FeedRankingPolicy) personalizedScoreExpression(viewerUserIDPos int, currentCityIDPos int, currentCountryCodePos int) string {
	p = p.normalized()

	parts := make([]string, 0, 11)
	if viewerUserIDPos > 0 {
		parts = append(parts,
			fmt.Sprintf("%s * %s", p.interestScoreExpression("post_interest"), p.weightSQL(p.PostInterestWeight)),
			fmt.Sprintf("%s * %s", p.interestScoreExpression("community_interest"), p.weightSQL(p.CommunityInterestWeight)),
			fmt.Sprintf("%s * %s", p.interestScoreExpression("profile_interest"), p.weightSQL(p.PostProfileAffinityWeight)),
			fmt.Sprintf("%s * %s", p.interestScoreExpression("author_interest"), p.weightSQL(p.AuthorAffinityWeight)),
			fmt.Sprintf("%s * %s", p.interestScoreExpression("city_interest"), p.weightSQL(p.CityAffinityWeight)),
			fmt.Sprintf("%s * %s", p.interestScoreExpression("country_interest"), p.weightSQL(p.CountryAffinityWeight)),
			fmt.Sprintf("%s * %s", p.interestScoreExpression("category_interest"), p.weightSQL(p.CategoryAffinityWeight)),
			fmt.Sprintf("%s * %s", p.interestScoreExpression("tag_interest"), p.weightSQL(p.TagAffinityWeight)),
			p.communityMembershipScoreExpression(viewerUserIDPos),
			p.socialEdgeScoreExpression(viewerUserIDPos),
		)
	}
	parts = append(parts,
		p.currentGeoScoreExpression(currentCityIDPos, currentCountryCodePos),
		p.engagementScoreExpression(),
		p.explorationScoreExpression(),
	)

	return strings.Join(parts, "\n\t\t\t\t\t+ ")
}

func (p FeedRankingPolicy) interestScoreExpression(alias string) string {
	p = p.normalized()
	alias = strings.TrimSpace(alias)
	if alias == "" {
		return "0"
	}
	if p.NegativeInterestDecayWindow <= 0 || p.NegativeInterestMinWeight <= 0 {
		return fmt.Sprintf("COALESCE(%s.score, 0)", alias)
	}
	score := fmt.Sprintf("COALESCE(%s.score, 0)", alias)
	windowSeconds := int(p.NegativeInterestDecayWindow.Seconds())

	return fmt.Sprintf(`CASE WHEN %s < 0 THEN
					%s * LEAST(1, GREATEST(%s, 1 - (EXTRACT(EPOCH FROM (NOW() - COALESCE(%s.last_event_at, NOW()))) / %d)))
				ELSE %s
				END`, score, score, p.weightSQL(p.NegativeInterestMinWeight), alias, windowSeconds, score)
}

func (p FeedRankingPolicy) currentGeoScoreExpression(currentCityIDPos int, currentCountryCodePos int) string {
	p = p.normalized()

	parts := make([]string, 0, 2)
	if currentCityIDPos > 0 && p.CurrentCityBoostHours > 0 {
		parts = append(parts, fmt.Sprintf(`CASE WHEN LOWER(COALESCE(s.place_city_id, '')) = LOWER($%d)
				THEN %d
				ELSE 0
				END`, currentCityIDPos, p.CurrentCityBoostHours))
	}
	if currentCountryCodePos > 0 && p.CurrentCountryBoostHours > 0 {
		parts = append(parts, fmt.Sprintf(`CASE WHEN UPPER(COALESCE(s.place_country_code, '')) = UPPER($%d)
				THEN %d
				ELSE 0
				END`, currentCountryCodePos, p.CurrentCountryBoostHours))
	}
	if len(parts) == 0 {
		return "0"
	}
	return strings.Join(parts, "\n\t\t\t\t\t+ ")
}

func (p FeedRankingPolicy) communityMembershipScoreExpression(viewerUserIDPos int) string {
	p = p.normalized()
	if viewerUserIDPos <= 0 || p.CommunityMembershipBoostHours <= 0 {
		return "0"
	}

	return fmt.Sprintf(`CASE WHEN fi.community_id IS NOT NULL AND EXISTS (
					SELECT 1
					FROM community_memberships community_membership
					WHERE community_membership.community_id = fi.community_id
					  AND community_membership.user_id = $%d
					  AND community_membership.status = 'ACTIVE'
				)
				THEN %d
				ELSE 0
				END`, viewerUserIDPos, p.CommunityMembershipBoostHours)
}

func (p FeedRankingPolicy) socialEdgeScoreExpression(viewerUserIDPos int) string {
	p = p.normalized()
	if viewerUserIDPos <= 0 || (p.SocialFriendBoostHours <= 0 && p.SocialFollowingBoostHours <= 0) {
		return "0"
	}

	return fmt.Sprintf(`CASE WHEN social_friend.viewer_user_id IS NOT NULL
					THEN %d
					ELSE 0
				END
				+ CASE WHEN social_following.viewer_user_id IS NOT NULL
					THEN %d
					ELSE 0
				END`, p.SocialFriendBoostHours, p.SocialFollowingBoostHours)
}

func (p FeedRankingPolicy) engagementScoreExpression() string {
	p = p.normalized()
	if p.EngagementMaxBoostHours <= 0 || p.EngagementWeight <= 0 || p.EngagementFreshnessWindow <= 0 {
		return "0"
	}
	freshnessWindowSeconds := int(p.EngagementFreshnessWindow.Seconds())

	return fmt.Sprintf(`LEAST(%d, GREATEST(0, FLOOR(
					LOG(2 + s.view_count + s.like_count * 2 + s.comment_count * 3 + s.share_count * 4) * %s *
					GREATEST(0, 1 - (EXTRACT(EPOCH FROM (NOW() - COALESCE(s.published_at, s.created_at))) / %d))
				)))`, p.EngagementMaxBoostHours, p.weightSQL(p.EngagementWeight), freshnessWindowSeconds)
}

func (p FeedRankingPolicy) explorationScoreExpression() string {
	p = p.normalized()
	if p.ExplorationFreshnessWindow <= 0 || p.ExplorationLowViewThreshold <= 0 || p.ExplorationMaxBoostHours <= 0 {
		return "0"
	}

	return fmt.Sprintf(`CASE WHEN COALESCE(s.published_at, s.created_at) >= NOW() - %s
					AND s.view_count <= %d
				THEN LEAST(%d, GREATEST(0, %d - FLOOR((s.view_count::numeric / %d) * %d)))
				ELSE 0
				END`,
		p.durationSQL(p.ExplorationFreshnessWindow),
		p.ExplorationLowViewThreshold,
		p.ExplorationMaxBoostHours,
		p.ExplorationMaxBoostHours,
		p.ExplorationLowViewThreshold,
		p.ExplorationMaxBoostHours,
	)
}

func (p FeedRankingPolicy) qualityPenaltyExpression() string {
	p = p.normalized()
	if p.QualityPenaltyWindow <= 0 || p.QualityMinNegativeEvents <= 0 ||
		p.QualityNegativePenaltyHours <= 0 || p.QualityMaxPenaltyHours <= 0 {
		return "make_interval(secs => 0)"
	}

	negativeCountExpression := fmt.Sprintf(`(
					SELECT COUNT(*)
					FROM (
						SELECT quality_negative.id
						FROM post_feed_events quality_negative
						WHERE quality_negative.post_id = fi.post_id
						  AND quality_negative.event_type IN ('hide', 'not_interested', 'report')
						  AND quality_negative.received_at >= NOW() - %[1]s

						UNION ALL

						SELECT quality_report.id
						FROM post_reports quality_report
						WHERE quality_report.post_id = fi.post_id
						  AND quality_report.status = 'OPEN'
						  AND quality_report.created_at >= NOW() - %[1]s
					) quality_signal
				)`, p.durationSQL(p.QualityPenaltyWindow))

	return fmt.Sprintf(`CASE WHEN %s >= %d
				THEN make_interval(hours => LEAST(%d, GREATEST(0, %s * %d))::int)
				ELSE make_interval(secs => 0)
				END`,
		negativeCountExpression,
		p.QualityMinNegativeEvents,
		p.QualityMaxPenaltyHours,
		negativeCountExpression,
		p.QualityNegativePenaltyHours,
	)
}

func (p FeedRankingPolicy) recentPostImpressionPenaltyExpression(viewerUserIDPos int) string {
	p = p.normalized()
	if viewerUserIDPos <= 0 || p.RecentPostImpressionWindow <= 0 || p.RecentPostImpressionPenaltyHours <= 0 {
		return "make_interval(secs => 0)"
	}

	return fmt.Sprintf(`CASE WHEN EXISTS (
					SELECT 1
					FROM post_feed_events recent_post_impression
					WHERE recent_post_impression.viewer_user_id = $%d
					  AND recent_post_impression.post_id = fi.post_id
					  AND recent_post_impression.event_type IN ('impression', 'click', 'dwell')
					  AND recent_post_impression.occurred_at >= NOW() - %s
				)
				THEN make_interval(hours => %d)
				ELSE make_interval(secs => 0)
				END`, viewerUserIDPos, p.durationSQL(p.RecentPostImpressionWindow), p.RecentPostImpressionPenaltyHours)
}

func (p FeedRankingPolicy) recentCommunityDiversityPenaltyExpression(viewerUserIDPos int) string {
	p = p.normalized()
	if viewerUserIDPos <= 0 || p.RecentCommunityPenaltyHours <= 0 || p.RecentCommunityEventWindow <= 0 {
		return "make_interval(secs => 0)"
	}

	return fmt.Sprintf(`CASE WHEN fi.community_id IS NOT NULL AND EXISTS (
					SELECT 1
					FROM post_feed_events recent_community_event
					WHERE recent_community_event.viewer_user_id = $%d
					  AND recent_community_event.community_id = fi.community_id
					  AND recent_community_event.post_id <> fi.post_id
					  AND recent_community_event.event_type IN ('impression', 'click')
					  AND recent_community_event.occurred_at >= NOW() - %s
				)
				THEN make_interval(hours => %d)
				ELSE make_interval(secs => 0)
				END`, viewerUserIDPos, p.durationSQL(p.RecentCommunityEventWindow), p.RecentCommunityPenaltyHours)
}

func (p FeedRankingPolicy) coldStartBoostExpression(viewerUserIDPos int) string {
	p = p.normalized()
	if viewerUserIDPos <= 0 || p.ColdStartMaxBoostHours <= 0 || p.ColdStartEngagementWeight <= 0 {
		return "make_interval(secs => 0)"
	}

	return fmt.Sprintf(`CASE WHEN NOT EXISTS (
					SELECT 1
					FROM post_feed_user_interests cold_start_interest_probe
					WHERE cold_start_interest_probe.viewer_user_id = $%d
					  AND cold_start_interest_probe.updated_at < NOW() - %s
				)
				THEN make_interval(hours => LEAST(%d, GREATEST(0, FLOOR(
					LOG(2 + s.view_count + s.like_count * 2 + s.comment_count * 3) * %s
				)))::int)
				ELSE make_interval(secs => 0)
				END`, viewerUserIDPos, p.durationSQL(p.InterestFreshnessDelay), p.ColdStartMaxBoostHours, p.weightSQL(p.ColdStartEngagementWeight))
}

func (p FeedRankingPolicy) durationSQL(value time.Duration) string {
	seconds := int(value.Seconds())
	if seconds < 0 {
		seconds = 0
	}
	return fmt.Sprintf("make_interval(secs => %d)", seconds)
}

func (p FeedRankingPolicy) weightSQL(value float64) string {
	return strconv.FormatFloat(value, 'f', -1, 64)
}

func normalizeFeedRankingExperimentKey(value string, fallback string) string {
	value = strings.TrimSpace(value)
	if value == "" || len(value) > maxFeedRankingExperimentKeyLength {
		return fallback
	}
	for _, r := range value {
		switch {
		case r >= 'a' && r <= 'z':
		case r >= 'A' && r <= 'Z':
		case r >= '0' && r <= '9':
		case r == '-', r == '_', r == '.':
		default:
			return fallback
		}
	}
	return value
}

func normalizeFeedRankingWeight(value float64, fallback float64) float64 {
	if value <= 0 || value > 10 {
		return fallback
	}
	return value
}

func normalizeFeedRankingFraction(value float64, fallback float64) float64 {
	if value <= 0 || value > 1 {
		return fallback
	}
	return value
}

func normalizeFeedRankingHours(value int, fallback int, max int) int {
	if value <= 0 || value > max {
		return fallback
	}
	return value
}

func normalizeFeedRankingPageCap(value int, fallback int, max int) int {
	if value <= 0 || value > max {
		return fallback
	}
	return value
}

func normalizeFeedRankingPositiveInt(value int, fallback int, max int) int {
	if value <= 0 || value > max {
		return fallback
	}
	return value
}

func normalizeFeedRankingDuration(value time.Duration, fallback time.Duration, max time.Duration) time.Duration {
	if value <= 0 || value > max {
		return fallback
	}
	return value
}
