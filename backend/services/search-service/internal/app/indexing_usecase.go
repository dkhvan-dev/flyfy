package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"unicode"

	"golang.org/x/text/unicode/norm"

	"kz/inflap/backend/services/search-service/internal/domain/model"
)

const (
	defaultSearchVisibility       = "public"
	defaultSearchModerationStatus = "approved"
)

var (
	ErrInvalidSearchDocument = errors.New("invalid search document")
)

type IndexRepository interface {
	UpsertDocument(ctx context.Context, document model.SearchDocument) error
	DeleteDocument(ctx context.Context, domain model.Domain, entityID string, locale string) error
}

type IndexingUseCase struct {
	repo IndexRepository
}

func NewIndexingUseCase(repo IndexRepository) *IndexingUseCase {
	return &IndexingUseCase{repo: repo}
}

type IndexDocumentInput struct {
	Domain               string
	EntityID             string
	EntityVersion        int64
	Locale               string
	Title                map[string]string
	Subtitle             map[string]string
	Description          map[string]string
	Tags                 []string
	CategoryCodes        []string
	CityID               string
	CountryCode          string
	Latitude             *float64
	Longitude            *float64
	PriceMin             *float64
	PriceMax             *float64
	Currency             string
	Rating               *float64
	ReviewCount          int
	PopularityScore      float64
	FreshnessScore       float64
	TrustScore           float64
	AvailabilityStatus   string
	Visibility           string
	ModerationStatus     string
	OwnerUserID          string
	PreviewImageFileID   string
	DeepLink             string
	SearchText           string
	SearchTextNormalized string
	SearchVariants       []string
}

type DeleteDocumentInput struct {
	Domain   string
	EntityID string
	Locale   string
}

func (u *IndexingUseCase) UpsertDocument(ctx context.Context, input IndexDocumentInput) error {
	domain, err := model.ParseDomain(input.Domain)
	if err != nil {
		return err
	}

	document := model.SearchDocument{
		Domain:             domain,
		EntityID:           strings.TrimSpace(input.EntityID),
		EntityVersion:      input.EntityVersion,
		Locale:             normalizeLocale(input.Locale),
		Title:              trimMap(input.Title),
		Subtitle:           trimMap(input.Subtitle),
		Description:        trimMap(input.Description),
		Tags:               trimStrings(input.Tags),
		CategoryCodes:      trimStrings(input.CategoryCodes),
		CityID:             strings.TrimSpace(input.CityID),
		CountryCode:        strings.ToUpper(strings.TrimSpace(input.CountryCode)),
		Latitude:           input.Latitude,
		Longitude:          input.Longitude,
		PriceMin:           input.PriceMin,
		PriceMax:           input.PriceMax,
		Currency:           strings.ToUpper(strings.TrimSpace(input.Currency)),
		Rating:             input.Rating,
		ReviewCount:        input.ReviewCount,
		PopularityScore:    clampUnit(input.PopularityScore),
		FreshnessScore:     clampUnit(input.FreshnessScore),
		TrustScore:         clampUnit(input.TrustScore),
		AvailabilityStatus: strings.TrimSpace(input.AvailabilityStatus),
		Visibility:         defaultIfBlank(input.Visibility, defaultSearchVisibility),
		ModerationStatus:   defaultIfBlank(input.ModerationStatus, defaultSearchModerationStatus),
		OwnerUserID:        strings.TrimSpace(input.OwnerUserID),
		PreviewImageFileID: strings.TrimSpace(input.PreviewImageFileID),
		DeepLink:           strings.TrimSpace(input.DeepLink),
		SearchVariants:     trimStrings(input.SearchVariants),
	}
	if document.EntityVersion <= 0 {
		document.EntityVersion = 1
	}
	if document.EntityID == "" {
		return fmt.Errorf("%w: entity_id is required", ErrInvalidSearchDocument)
	}
	if document.DeepLink == "" {
		return fmt.Errorf("%w: deep_link is required", ErrInvalidSearchDocument)
	}

	document.SearchText = strings.TrimSpace(input.SearchText)
	if document.SearchText == "" {
		document.SearchText = buildSearchText(document)
	}
	document.SearchTextNormalized = normalizeSearchText(input.SearchTextNormalized)
	if document.SearchTextNormalized == "" {
		document.SearchTextNormalized = normalizeSearchText(document.SearchText)
	}
	if document.SearchTextNormalized == "" {
		return fmt.Errorf("%w: searchable text is required", ErrInvalidSearchDocument)
	}

	return u.repo.UpsertDocument(ctx, document)
}

func (u *IndexingUseCase) DeleteDocument(ctx context.Context, input DeleteDocumentInput) error {
	domain, err := model.ParseDomain(input.Domain)
	if err != nil {
		return err
	}
	entityID := strings.TrimSpace(input.EntityID)
	if entityID == "" {
		return fmt.Errorf("%w: entity_id is required", ErrInvalidSearchDocument)
	}
	return u.repo.DeleteDocument(ctx, domain, entityID, normalizeLocale(input.Locale))
}

func trimMap(values map[string]string) map[string]string {
	if len(values) == 0 {
		return nil
	}
	result := make(map[string]string, len(values))
	for key, value := range values {
		key = normalizeLocale(key)
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		result[key] = value
	}
	return result
}

func trimStrings(values []string) []string {
	if len(values) == 0 {
		return []string{}
	}
	result := make([]string, 0, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		result = append(result, value)
	}
	return result
}

func defaultIfBlank(value string, fallback string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return fallback
	}
	return value
}

func clampUnit(value float64) float64 {
	if value < 0 {
		return 0
	}
	if value > 1 {
		return 1
	}
	return value
}

func buildSearchText(document model.SearchDocument) string {
	parts := make([]string, 0, 8)
	appendMapValues := func(values map[string]string) {
		for _, value := range values {
			parts = append(parts, value)
		}
	}
	appendMapValues(document.Title)
	appendMapValues(document.Subtitle)
	appendMapValues(document.Description)
	parts = append(parts, document.Tags...)
	parts = append(parts, document.SearchVariants...)
	return strings.Join(parts, " ")
}

func normalizeSearchText(value string) string {
	normalized := normalizeSearchTextBase(value)
	return appendCyrillicLatinAliases(appendSearchAliases(normalized))
}

func normalizeSearchTextBase(value string) string {
	value = strings.ToLower(strings.TrimSpace(foldAccents(value)))
	if value == "" {
		return ""
	}
	var builder strings.Builder
	builder.Grow(len(value))
	lastWasSpace := true
	for _, r := range value {
		if unicode.IsSpace(r) {
			if !lastWasSpace {
				builder.WriteRune(' ')
				lastWasSpace = true
			}
			continue
		}
		builder.WriteRune(r)
		lastWasSpace = false
	}
	return strings.TrimSpace(builder.String())
}

func foldAccents(value string) string {
	if value == "" {
		return ""
	}
	decomposed := norm.NFD.String(value)
	var builder strings.Builder
	builder.Grow(len(decomposed))
	for _, r := range decomposed {
		if unicode.Is(unicode.Mn, r) {
			continue
		}
		builder.WriteRune(r)
	}
	return builder.String()
}

var searchAliasGroups = [][]string{
	{"алматы", "алмата", "almaty", "almty"},
}

func appendSearchAliases(normalized string) string {
	if normalized == "" {
		return ""
	}
	parts := strings.Fields(normalized)
	seen := make(map[string]struct{}, len(parts))
	for _, part := range parts {
		seen[part] = struct{}{}
	}

	for _, aliases := range searchAliasGroups {
		if !hasAnyAlias(seen, aliases) {
			continue
		}
		for _, alias := range aliases {
			alias = normalizeSearchTextBase(alias)
			if alias == "" {
				continue
			}
			if _, ok := seen[alias]; ok {
				continue
			}
			parts = append(parts, alias)
			seen[alias] = struct{}{}
		}
	}

	return strings.Join(parts, " ")
}

func appendCyrillicLatinAliases(normalized string) string {
	if normalized == "" {
		return ""
	}
	parts := strings.Fields(normalized)
	seen := make(map[string]struct{}, len(parts))
	for _, part := range parts {
		seen[part] = struct{}{}
	}

	for _, part := range parts {
		if !containsCyrillic(part) {
			continue
		}
		alias := transliterateCyrillicToLatin(part)
		if alias == "" || alias == part {
			continue
		}
		if _, ok := seen[alias]; ok {
			continue
		}
		parts = append(parts, alias)
		seen[alias] = struct{}{}
	}

	return strings.Join(parts, " ")
}

func containsCyrillic(value string) bool {
	for _, r := range value {
		if unicode.In(r, unicode.Cyrillic) {
			return true
		}
	}
	return false
}

func transliterateCyrillicToLatin(value string) string {
	var builder strings.Builder
	builder.Grow(len(value))
	for _, r := range value {
		if mapped, ok := cyrillicLatinMap[r]; ok {
			builder.WriteString(mapped)
			continue
		}
		if unicode.In(r, unicode.Cyrillic) {
			continue
		}
		builder.WriteRune(r)
	}
	return strings.TrimSpace(builder.String())
}

var cyrillicLatinMap = map[rune]string{
	'а': "a",
	'б': "b",
	'в': "v",
	'г': "g",
	'д': "d",
	'е': "e",
	'ё': "e",
	'ж': "zh",
	'з': "z",
	'и': "i",
	'й': "y",
	'к': "k",
	'л': "l",
	'м': "m",
	'н': "n",
	'о': "o",
	'п': "p",
	'р': "r",
	'с': "s",
	'т': "t",
	'у': "u",
	'ф': "f",
	'х': "h",
	'ц': "ts",
	'ч': "ch",
	'ш': "sh",
	'щ': "shch",
	'ъ': "",
	'ы': "y",
	'ь': "",
	'э': "e",
	'ю': "yu",
	'я': "ya",
	'ә': "a",
	'ғ': "g",
	'қ': "q",
	'ң': "ng",
	'ө': "o",
	'ұ': "u",
	'ү': "u",
	'һ': "h",
	'і': "i",
}

func hasAnyAlias(tokens map[string]struct{}, aliases []string) bool {
	for _, alias := range aliases {
		alias = normalizeSearchTextBase(alias)
		if _, ok := tokens[alias]; ok {
			return true
		}
	}
	return false
}
