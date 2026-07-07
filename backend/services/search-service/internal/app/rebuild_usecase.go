package app

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"strings"

	"kz/inflap/backend/services/search-service/internal/domain/model"
)

type RebuildUseCase struct {
	indexing *IndexingUseCase
}

func NewRebuildUseCase(indexing *IndexingUseCase) *RebuildUseCase {
	return &RebuildUseCase{indexing: indexing}
}

type RebuildOptions struct {
	Domain      string
	CountryCode string
	CityID      string
	DryRun      bool
}

type RebuildStats struct {
	Scanned         int
	Upserted        int
	Skipped         int
	DryRunValidated int
}

func (u *RebuildUseCase) RebuildFromJSONLines(
	ctx context.Context,
	reader io.Reader,
	options RebuildOptions,
) (RebuildStats, error) {
	if u == nil || u.indexing == nil {
		return RebuildStats{}, fmt.Errorf("indexing use case is required")
	}

	domainFilter, err := parseOptionalRebuildDomain(options.Domain)
	if err != nil {
		return RebuildStats{}, err
	}
	countryFilter := strings.ToUpper(strings.TrimSpace(options.CountryCode))
	cityFilter := strings.TrimSpace(options.CityID)

	scanner := bufio.NewScanner(reader)
	scanner.Buffer(make([]byte, 0, 64*1024), 4*1024*1024)

	stats := RebuildStats{}
	for scanner.Scan() {
		line := bytes.TrimSpace(scanner.Bytes())
		if len(line) == 0 {
			continue
		}
		stats.Scanned++

		var input IndexDocumentInput
		if err := json.Unmarshal(line, &input); err != nil {
			return stats, fmt.Errorf("decode rebuild line %d: %w", stats.Scanned, err)
		}
		if shouldSkipRebuildDocument(input, domainFilter, countryFilter, cityFilter) {
			stats.Skipped++
			continue
		}

		if options.DryRun {
			if err := NewIndexingUseCase(discardIndexRepository{}).UpsertDocument(ctx, input); err != nil {
				return stats, fmt.Errorf("validate rebuild line %d: %w", stats.Scanned, err)
			}
			stats.DryRunValidated++
			continue
		}

		if err := u.indexing.UpsertDocument(ctx, input); err != nil {
			return stats, fmt.Errorf("upsert rebuild line %d: %w", stats.Scanned, err)
		}
		stats.Upserted++
	}
	if err := scanner.Err(); err != nil {
		return stats, fmt.Errorf("scan rebuild input: %w", err)
	}

	return stats, nil
}

func parseOptionalRebuildDomain(value string) (*model.Domain, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil, nil
	}
	domain, err := model.ParseDomain(value)
	if err != nil {
		return nil, err
	}
	return &domain, nil
}

func shouldSkipRebuildDocument(
	input IndexDocumentInput,
	domainFilter *model.Domain,
	countryFilter string,
	cityFilter string,
) bool {
	if domainFilter != nil && strings.TrimSpace(input.Domain) != string(*domainFilter) {
		return true
	}
	if countryFilter != "" && strings.ToUpper(strings.TrimSpace(input.CountryCode)) != countryFilter {
		return true
	}
	if cityFilter != "" && strings.TrimSpace(input.CityID) != cityFilter {
		return true
	}
	return false
}

type discardIndexRepository struct{}

func (discardIndexRepository) UpsertDocument(context.Context, model.SearchDocument) error {
	return nil
}

func (discardIndexRepository) DeleteDocument(context.Context, model.Domain, string, string) error {
	return nil
}
