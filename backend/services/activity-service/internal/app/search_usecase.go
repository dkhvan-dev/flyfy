package app

import (
	"context"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

type SearchUseCase struct {
	repo port.ActivityRepository
}

func NewSearchUseCase(repo port.ActivityRepository) *SearchUseCase {
	return &SearchUseCase{repo: repo}
}

type SearchActivitiesInput struct {
	HostUserID   *uuid.UUID
	Statuses     []string
	CategorySlug *string
	CountryCode  *string
	CityName     *string
	LanguageCode *string
	Query        *string
	Limit        int
	Offset       int
}

func (u *SearchUseCase) SearchActivities(ctx context.Context, input SearchActivitiesInput) ([]*model.Activity, error) {
	filter := port.ActivityFilter{
		HostUserID:   input.HostUserID,
		Statuses:     normalizeStatuses(input.Statuses),
		CategorySlug: model.NormalizeOptionalString(input.CategorySlug),
		CountryCode:  model.NormalizeOptionalString(input.CountryCode),
		CityName:     model.NormalizeOptionalString(input.CityName),
		LanguageCode: model.NormalizeOptionalString(input.LanguageCode),
		SearchQuery:  model.NormalizeOptionalString(input.Query),
		Limit:        input.Limit,
		Offset:       input.Offset,
	}

	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	items, err := u.repo.ListActivities(ctx, filter)
	if err != nil {
		return nil, err
	}

	return items, nil
}

func normalizeStatuses(statuses []string) []string {
	result := make([]string, 0, len(statuses))
	seen := make(map[string]struct{}, len(statuses))

	for _, status := range statuses {
		status = strings.TrimSpace(status)
		if status == "" {
			continue
		}
		if _, exists := seen[status]; exists {
			continue
		}
		seen[status] = struct{}{}
		result = append(result, status)
	}

	return result
}
