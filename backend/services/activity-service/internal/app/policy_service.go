package app

import (
	"context"
	"net/url"
	"regexp"
	"strings"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
	"github.com/google/uuid"
)

type PolicyService struct {
	repo port.ActivityRepository
}

func NewPolicyService(repo port.ActivityRepository) *PolicyService {
	return &PolicyService{repo: repo}
}

func (s *PolicyService) CheckCreateRateLimit(ctx context.Context, hostUserID uuid.UUID) error {
	oneHourAgo := time.Now().UTC().Add(-1 * time.Hour)

	count, err := s.repo.CountActivitiesCreatedSince(ctx, hostUserID, oneHourAgo)
	if err != nil {
		return err
	}

	if count >= 3 {
		return ErrActivityCreationRateLimited
	}

	return nil
}

func (s *PolicyService) ValidateURLs(ctx context.Context, urls ...*string) error {
	patterns, err := s.repo.ListActiveBlockedURLPatterns(ctx)
	if err != nil {
		return err
	}

	for _, raw := range urls {
		value := normalizeURL(raw)
		if value == "" {
			continue
		}

		for _, pattern := range patterns {
			if !pattern.IsActive {
				continue
			}
			if matchesBlockedPattern(value, pattern) {
				switch pattern.Action {
				case model.BlockedURLPatternActionBlock:
					return ErrBlockedURLDetected
				case model.BlockedURLPatternActionReview:
					continue
				}
			}
		}
	}

	return nil
}

func normalizeURL(raw *string) string {
	if raw == nil {
		return ""
	}

	value := strings.TrimSpace(*raw)
	if value == "" {
		return ""
	}

	return value
}

func matchesBlockedPattern(rawURL string, pattern *model.BlockedURLPattern) bool {
	rawURL = strings.TrimSpace(rawURL)
	patternValue := strings.TrimSpace(pattern.PatternValue)

	switch pattern.PatternType {
	case model.BlockedURLPatternTypeStartsWith:
		return strings.HasPrefix(strings.ToLower(rawURL), strings.ToLower(patternValue))

	case model.BlockedURLPatternTypeContains:
		return strings.Contains(strings.ToLower(rawURL), strings.ToLower(patternValue))

	case model.BlockedURLPatternTypeRegex:
		re, err := regexp.Compile(patternValue)
		if err != nil {
			return false
		}
		return re.MatchString(rawURL)

	case model.BlockedURLPatternTypeDomain:
		parsed, err := url.Parse(rawURL)
		if err != nil {
			return false
		}
		host := strings.ToLower(strings.TrimSpace(parsed.Hostname()))
		target := strings.ToLower(patternValue)
		return host == target || strings.HasSuffix(host, "."+target)

	default:
		return false
	}
}
