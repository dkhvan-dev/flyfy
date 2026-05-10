package repository

import (
	"context"
	"fmt"
	"regexp"
	"strconv"
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/model"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

func TestUpdateTourUsesContiguousPlaceholders(t *testing.T) {
	item, err := model.NewTour(model.NewTourParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.TourVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewTour() error = %v", err)
	}

	err = updateTour(context.Background(), placeholderCheckingExecutor{}, item)
	if err != nil {
		t.Fatalf("updateTour() error = %v", err)
	}
}

type placeholderCheckingExecutor struct{}

func (placeholderCheckingExecutor) Exec(_ context.Context, query string, arguments ...any) (pgconn.CommandTag, error) {
	if err := validateContiguousPlaceholders(query, len(arguments)); err != nil {
		return pgconn.CommandTag{}, err
	}
	return pgconn.NewCommandTag("UPDATE 1"), nil
}

func (placeholderCheckingExecutor) QueryRow(context.Context, string, ...any) pgx.Row {
	return nil
}

func validateContiguousPlaceholders(query string, argCount int) error {
	matches := regexp.MustCompile(`\$(\d+)`).FindAllStringSubmatch(query, -1)
	seen := make(map[int]struct{}, len(matches))
	maxPlaceholder := 0
	for _, match := range matches {
		value, err := strconv.Atoi(match[1])
		if err != nil {
			return err
		}
		seen[value] = struct{}{}
		if value > maxPlaceholder {
			maxPlaceholder = value
		}
	}
	if maxPlaceholder != argCount {
		return fmt.Errorf("max placeholder = %d, args = %d", maxPlaceholder, argCount)
	}
	for index := 1; index <= maxPlaceholder; index++ {
		if _, ok := seen[index]; !ok {
			return fmt.Errorf("placeholder $%d is not used", index)
		}
	}
	return nil
}
