package repository

import (
	"fmt"
	"strconv"
	"strings"
	"time"
)

const maxFeedRankingExperimentKeyLength = 48

type FeedRankingPolicy struct {
	ExperimentKey               string
	PostInterestWeight          float64
	CommunityInterestWeight     float64
	CityAffinityWeight          float64
	CountryAffinityWeight       float64
	CategoryAffinityWeight      float64
	TagAffinityWeight           float64
	MaxBoostHours               int
	MaxPenaltyHours             int
	InterestFreshnessDelay      time.Duration
	NotInterestedPenalty        time.Duration
	RecentCommunityEventWindow  time.Duration
	RecentCommunityPenaltyHours int
	MaxPostsPerCommunityPerPage int
	MaxPostsPerCategoryPerPage  int
	MaxPostsPerAuthorPerPage    int
	ColdStartMaxBoostHours      int
	ColdStartEngagementWeight   float64
}

func DefaultFeedRankingPolicy() FeedRankingPolicy {
	return FeedRankingPolicy{
		ExperimentKey:               "control",
		PostInterestWeight:          1,
		CommunityInterestWeight:     0.35,
		CityAffinityWeight:          0.25,
		CountryAffinityWeight:       0.10,
		CategoryAffinityWeight:      0.20,
		TagAffinityWeight:           0.15,
		MaxBoostHours:               72,
		MaxPenaltyHours:             336,
		InterestFreshnessDelay:      5 * time.Minute,
		NotInterestedPenalty:        14 * 24 * time.Hour,
		RecentCommunityEventWindow:  24 * time.Hour,
		RecentCommunityPenaltyHours: 8,
		MaxPostsPerCommunityPerPage: 3,
		MaxPostsPerCategoryPerPage:  8,
		MaxPostsPerAuthorPerPage:    4,
		ColdStartMaxBoostHours:      6,
		ColdStartEngagementWeight:   1,
	}
}

func (p FeedRankingPolicy) normalized() FeedRankingPolicy {
	defaults := DefaultFeedRankingPolicy()

	p.ExperimentKey = normalizeFeedRankingExperimentKey(p.ExperimentKey, defaults.ExperimentKey)
	p.PostInterestWeight = normalizeFeedRankingWeight(p.PostInterestWeight, defaults.PostInterestWeight)
	p.CommunityInterestWeight = normalizeFeedRankingWeight(p.CommunityInterestWeight, defaults.CommunityInterestWeight)
	p.CityAffinityWeight = normalizeFeedRankingWeight(p.CityAffinityWeight, defaults.CityAffinityWeight)
	p.CountryAffinityWeight = normalizeFeedRankingWeight(p.CountryAffinityWeight, defaults.CountryAffinityWeight)
	p.CategoryAffinityWeight = normalizeFeedRankingWeight(p.CategoryAffinityWeight, defaults.CategoryAffinityWeight)
	p.TagAffinityWeight = normalizeFeedRankingWeight(p.TagAffinityWeight, defaults.TagAffinityWeight)
	p.MaxBoostHours = normalizeFeedRankingHours(p.MaxBoostHours, defaults.MaxBoostHours, 168)
	p.MaxPenaltyHours = normalizeFeedRankingHours(p.MaxPenaltyHours, defaults.MaxPenaltyHours, 720)
	p.InterestFreshnessDelay = normalizeFeedRankingDuration(p.InterestFreshnessDelay, defaults.InterestFreshnessDelay, 24*time.Hour)
	p.NotInterestedPenalty = normalizeFeedRankingDuration(p.NotInterestedPenalty, defaults.NotInterestedPenalty, 30*24*time.Hour)
	p.RecentCommunityEventWindow = normalizeFeedRankingDuration(p.RecentCommunityEventWindow, defaults.RecentCommunityEventWindow, 7*24*time.Hour)
	p.RecentCommunityPenaltyHours = normalizeFeedRankingHours(p.RecentCommunityPenaltyHours, defaults.RecentCommunityPenaltyHours, 72)
	p.MaxPostsPerCommunityPerPage = normalizeFeedRankingPageCap(p.MaxPostsPerCommunityPerPage, defaults.MaxPostsPerCommunityPerPage, 20)
	p.MaxPostsPerCategoryPerPage = normalizeFeedRankingPageCap(p.MaxPostsPerCategoryPerPage, defaults.MaxPostsPerCategoryPerPage, 50)
	p.MaxPostsPerAuthorPerPage = normalizeFeedRankingPageCap(p.MaxPostsPerAuthorPerPage, defaults.MaxPostsPerAuthorPerPage, 20)
	p.ColdStartMaxBoostHours = normalizeFeedRankingHours(p.ColdStartMaxBoostHours, defaults.ColdStartMaxBoostHours, 24)
	p.ColdStartEngagementWeight = normalizeFeedRankingWeight(p.ColdStartEngagementWeight, defaults.ColdStartEngagementWeight)

	return p
}

func (p FeedRankingPolicy) Normalized() FeedRankingPolicy {
	return p.normalized()
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
				SELECT SUM(tag_interest.score) AS score
				FROM post_feed_user_interests tag_interest
				WHERE tag_interest.viewer_user_id = $%d
				  AND tag_interest.entity_type = 'tag'
				  AND tag_interest.updated_at < NOW() - %s
				  AND tag_interest.entity_id IN (
					SELECT lower(post_tag.tag)
					FROM unnest(COALESCE(s.tags, ARRAY[]::text[])) AS post_tag(tag)
				  )
			) tag_interest ON TRUE
		`, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL, viewerUserIDPos, freshnessSQL)
}

func (p FeedRankingPolicy) viewerRankedAtExpression(viewerUserIDPos int) string {
	p = p.normalized()

	return fmt.Sprintf(`
			(
				CASE WHEN EXISTS (
					SELECT 1
					FROM post_feed_events negative
					WHERE negative.viewer_user_id = $%d
					  AND negative.post_id = fi.post_id
					  AND negative.event_type = 'not_interested'
				)
				THEN fi.rank_published_at - %s
				ELSE fi.rank_published_at
				END
				+ make_interval(hours => LEAST(%d, GREATEST(-%d,
					%s
				))::int)
				- %s
				+ %s
			)
		`,
		viewerUserIDPos,
		p.durationSQL(p.NotInterestedPenalty),
		p.MaxBoostHours,
		p.MaxPenaltyHours,
		p.personalizedScoreExpression(),
		p.recentCommunityDiversityPenaltyExpression(viewerUserIDPos),
		p.coldStartBoostExpression(viewerUserIDPos),
	)
}

func (p FeedRankingPolicy) personalizedScoreExpression() string {
	p = p.normalized()

	return strings.Join([]string{
		fmt.Sprintf("COALESCE(post_interest.score, 0) * %s", p.weightSQL(p.PostInterestWeight)),
		fmt.Sprintf("COALESCE(community_interest.score, 0) * %s", p.weightSQL(p.CommunityInterestWeight)),
		fmt.Sprintf("COALESCE(city_interest.score, 0) * %s", p.weightSQL(p.CityAffinityWeight)),
		fmt.Sprintf("COALESCE(country_interest.score, 0) * %s", p.weightSQL(p.CountryAffinityWeight)),
		fmt.Sprintf("COALESCE(category_interest.score, 0) * %s", p.weightSQL(p.CategoryAffinityWeight)),
		fmt.Sprintf("COALESCE(tag_interest.score, 0) * %s", p.weightSQL(p.TagAffinityWeight)),
	}, "\n\t\t\t\t\t+ ")
}

func (p FeedRankingPolicy) recentCommunityDiversityPenaltyExpression(viewerUserIDPos int) string {
	p = p.normalized()
	if p.RecentCommunityPenaltyHours <= 0 || p.RecentCommunityEventWindow <= 0 {
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
	if p.ColdStartMaxBoostHours <= 0 || p.ColdStartEngagementWeight <= 0 {
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

func normalizeFeedRankingDuration(value time.Duration, fallback time.Duration, max time.Duration) time.Duration {
	if value <= 0 || value > max {
		return fallback
	}
	return value
}
