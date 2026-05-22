package app

import (
	"context"
	"net/url"
	"regexp"
	"strings"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
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

func (s *PolicyService) ValidateActivityLocation(
	format enum.ActivityFormat,
	countryCode *string,
	cityID *string,
	cityName *string,
	addressText *string,
	latitude *float64,
	longitude *float64,
	mapURL *string,
	meetingURL *string,
) error {
	if !format.IsValid() {
		return model.ErrInvalidActivityFormat
	}

	hasOfflineFields := hasLocationText(countryCode) ||
		hasLocationText(cityID) ||
		hasLocationText(cityName) ||
		hasLocationText(addressText) ||
		hasLocationText(mapURL) ||
		latitude != nil ||
		longitude != nil
	hasMeetingURL := hasLocationText(meetingURL)

	if (latitude == nil) != (longitude == nil) {
		return ErrActivityLocationCoordinatesRequired
	}
	if latitude != nil && longitude != nil &&
		(*latitude < -90 || *latitude > 90 || *longitude < -180 || *longitude > 180) {
		return ErrActivityLocationCoordinatesInvalid
	}

	switch format {
	case enum.ActivityFormatOnline:
		if hasOfflineFields {
			return ErrActivityLocationOfflineFieldsForbidden
		}
		if !hasMeetingURL {
			return model.ErrInvalidMeetingURL
		}

	case enum.ActivityFormatOffline:
		if hasMeetingURL {
			return ErrActivityLocationMeetingURLForbidden
		}
		if err := validateOfflineActivityLocation(countryCode, cityID, cityName, latitude, longitude); err != nil {
			return err
		}

	case enum.ActivityFormatHybrid:
		if !hasMeetingURL && !hasOfflineFields {
			return model.ErrInvalidOfflineLocation
		}
		if hasOfflineFields {
			if err := validateOfflineActivityLocation(countryCode, cityID, cityName, latitude, longitude); err != nil {
				return err
			}
		}
	}

	return nil
}

func validateOfflineActivityLocation(
	countryCode *string,
	cityID *string,
	cityName *string,
	latitude *float64,
	longitude *float64,
) error {
	if !hasLocationText(countryCode) ||
		(!hasLocationText(cityID) && !hasLocationText(cityName)) {
		return ErrActivityLocationIncomplete
	}
	if latitude == nil || longitude == nil {
		return ErrActivityLocationCoordinatesRequired
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

func hasLocationText(raw *string) bool {
	return raw != nil && strings.TrimSpace(*raw) != ""
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
