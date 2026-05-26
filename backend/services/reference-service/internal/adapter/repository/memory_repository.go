package repository

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"sort"
	"strings"
	"unicode"

	"golang.org/x/text/unicode/norm"

	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/internal/domain/model"
)

// MemoryRepository holds all reference data in memory with pre-built search indexes.
type MemoryRepository struct {
	countries  []model.Country
	cities     []model.City
	currencies []model.Currency
	timezones  []model.Timezone

	countryByCode   map[string]*model.Country
	citiesByCountry map[string][]model.City
	currencyByCode  map[string]*model.Currency
	cityByID        map[string]*model.City

	// search indexes: normalized tokens → items
	countrySearchTokens  []searchEntry[model.Country]
	citySearchTokens     []searchEntry[model.City]
	currencySearchTokens []searchEntry[model.Currency]
}

type searchEntry[T any] struct {
	normalized string
	item       *T
}

func NewMemoryRepository(dataFS fs.FS) (*MemoryRepository, error) {
	repo := &MemoryRepository{
		countryByCode:   make(map[string]*model.Country),
		citiesByCountry: make(map[string][]model.City),
		currencyByCode:  make(map[string]*model.Currency),
		cityByID:        make(map[string]*model.City),
	}

	if err := repo.loadCountries(dataFS); err != nil {
		return nil, fmt.Errorf("load countries: %w", err)
	}
	if err := repo.loadCities(dataFS); err != nil {
		return nil, fmt.Errorf("load cities: %w", err)
	}
	if err := repo.loadCurrencies(dataFS); err != nil {
		return nil, fmt.Errorf("load currencies: %w", err)
	}
	if err := repo.loadTimezones(dataFS); err != nil {
		return nil, fmt.Errorf("load timezones: %w", err)
	}

	repo.buildSearchIndexes()

	return repo, nil
}

func (r *MemoryRepository) loadCountries(dataFS fs.FS) error {
	data, err := fs.ReadFile(dataFS, "countries.json")
	if err != nil {
		return err
	}
	if err := json.Unmarshal(data, &r.countries); err != nil {
		return err
	}
	for i := range r.countries {
		r.countryByCode[r.countries[i].Code] = &r.countries[i]
	}
	return nil
}

func (r *MemoryRepository) loadCities(dataFS fs.FS) error {
	data, err := fs.ReadFile(dataFS, "cities.json")
	if err != nil {
		return err
	}
	if err := json.Unmarshal(data, &r.cities); err != nil {
		return err
	}
	for i := range r.cities {
		city := &r.cities[i]
		r.cityByID[city.ID] = city
		r.citiesByCountry[city.CountryCode] = append(r.citiesByCountry[city.CountryCode], r.cities[i])
	}
	// Sort cities within each country by population descending.
	for code := range r.citiesByCountry {
		cities := r.citiesByCountry[code]
		sort.Slice(cities, func(i, j int) bool {
			return cities[i].Population > cities[j].Population
		})
		r.citiesByCountry[code] = cities
	}
	return nil
}

func (r *MemoryRepository) loadCurrencies(dataFS fs.FS) error {
	data, err := fs.ReadFile(dataFS, "currencies.json")
	if err != nil {
		return err
	}
	if err := json.Unmarshal(data, &r.currencies); err != nil {
		return err
	}
	for i := range r.currencies {
		r.currencyByCode[r.currencies[i].Code] = &r.currencies[i]
	}
	return nil
}

func (r *MemoryRepository) loadTimezones(dataFS fs.FS) error {
	data, err := fs.ReadFile(dataFS, "timezones.json")
	if err != nil {
		return err
	}
	if err := json.Unmarshal(data, &r.timezones); err != nil {
		return err
	}
	return nil
}

func (r *MemoryRepository) buildSearchIndexes() {
	for i := range r.countries {
		c := &r.countries[i]
		for _, token := range localizedTokens(c.Name) {
			r.countrySearchTokens = append(r.countrySearchTokens, searchEntry[model.Country]{normalized: token, item: c})
		}
		// Also index by country code.
		r.countrySearchTokens = append(r.countrySearchTokens, searchEntry[model.Country]{normalized: normalize(c.Code), item: c})
	}

	for i := range r.cities {
		c := &r.cities[i]
		for _, token := range localizedTokens(c.Name) {
			r.citySearchTokens = append(r.citySearchTokens, searchEntry[model.City]{normalized: token, item: c})
		}
	}

	for i := range r.currencies {
		c := &r.currencies[i]
		for _, token := range localizedTokens(c.Name) {
			r.currencySearchTokens = append(r.currencySearchTokens, searchEntry[model.Currency]{normalized: token, item: c})
		}
		r.currencySearchTokens = append(r.currencySearchTokens, searchEntry[model.Currency]{normalized: normalize(c.Code), item: c})
		r.currencySearchTokens = append(r.currencySearchTokens, searchEntry[model.Currency]{normalized: normalize(c.Symbol), item: c})
	}
}

// --- Query methods ---

func (r *MemoryRepository) AllCountries() []model.Country {
	return r.countries
}

func (r *MemoryRepository) CountryByCode(code string) *model.Country {
	return r.countryByCode[strings.ToUpper(code)]
}

func (r *MemoryRepository) AllCities() []model.City {
	return r.cities
}

func (r *MemoryRepository) CitiesByCountry(countryCode string) []model.City {
	return r.citiesByCountry[strings.ToUpper(countryCode)]
}

func (r *MemoryRepository) CityByID(id string) *model.City {
	return r.cityByID[id]
}

func (r *MemoryRepository) AllCurrencies() []model.Currency {
	return r.currencies
}

func (r *MemoryRepository) AllTimezones() []model.Timezone {
	return r.timezones
}

func (r *MemoryRepository) CurrencyByCode(code string) *model.Currency {
	return r.currencyByCode[strings.ToUpper(code)]
}

func (r *MemoryRepository) CurrencyByCountry(countryCode string) *model.Currency {
	c := r.countryByCode[strings.ToUpper(countryCode)]
	if c == nil {
		return nil
	}
	return r.currencyByCode[c.CurrencyCode]
}

// --- Search methods ---

type SearchResult[T any] struct {
	Item  *T
	Score int // lower = better match (0 = prefix, 1 = contains)
}

func (r *MemoryRepository) SearchCountries(query string, limit int) []model.Country {
	return collectSearch(r.countrySearchTokens, query, limit)
}

func (r *MemoryRepository) SearchCities(query string, countryCode string, limit int) []model.City {
	results := searchEntries(r.citySearchTokens, query)

	if countryCode != "" {
		upper := strings.ToUpper(countryCode)
		filtered := results[:0]
		for _, sr := range results {
			if sr.Item.CountryCode == upper {
				filtered = append(filtered, sr)
			}
		}
		results = filtered
	}

	// Deduplicate by city ID, keep best score.
	seen := make(map[string]bool, len(results))
	deduped := make([]SearchResult[model.City], 0, len(results))
	for _, sr := range results {
		if !seen[sr.Item.ID] {
			seen[sr.Item.ID] = true
			deduped = append(deduped, sr)
		}
	}

	// Sort: by score ascending, then by population descending.
	sort.Slice(deduped, func(i, j int) bool {
		if deduped[i].Score != deduped[j].Score {
			return deduped[i].Score < deduped[j].Score
		}
		return deduped[i].Item.Population > deduped[j].Item.Population
	})

	if limit > 0 && len(deduped) > limit {
		deduped = deduped[:limit]
	}

	out := make([]model.City, len(deduped))
	for i, sr := range deduped {
		out[i] = *sr.Item
	}
	return out
}

func (r *MemoryRepository) SearchCurrencies(query string, limit int) []model.Currency {
	return collectSearch(r.currencySearchTokens, query, limit)
}

// --- Helpers ---

func collectSearch[T any](entries []searchEntry[T], query string, limit int) []T {
	results := searchEntries(entries, query)

	// Deduplicate.
	type key = string
	seen := make(map[*T]bool, len(results))
	deduped := make([]SearchResult[T], 0, len(results))
	for _, sr := range results {
		if !seen[sr.Item] {
			seen[sr.Item] = true
			deduped = append(deduped, sr)
		}
	}

	sort.Slice(deduped, func(i, j int) bool {
		return deduped[i].Score < deduped[j].Score
	})

	if limit > 0 && len(deduped) > limit {
		deduped = deduped[:limit]
	}

	out := make([]T, len(deduped))
	for i, sr := range deduped {
		out[i] = *sr.Item
	}
	return out
}

func searchEntries[T any](entries []searchEntry[T], query string) []SearchResult[T] {
	q := normalize(query)
	if q == "" {
		return nil
	}

	var results []SearchResult[T]
	for _, e := range entries {
		if strings.HasPrefix(e.normalized, q) {
			results = append(results, SearchResult[T]{Item: e.item, Score: 0})
		} else if strings.Contains(e.normalized, q) {
			results = append(results, SearchResult[T]{Item: e.item, Score: 1})
		}
	}
	return results
}

func localizedTokens(name model.LocalizedName) []string {
	tokens := make([]string, 0, 6)
	for _, val := range []string{name.En, name.Ru, name.Kk} {
		n := normalize(val)
		if n != "" {
			tokens = append(tokens, n)
		}
		// Also index individual words for multi-word names.
		words := strings.Fields(n)
		if len(words) > 1 {
			for _, w := range words {
				tokens = append(tokens, w)
			}
		}
	}
	return tokens
}

// normalize converts a string to lowercase NFD form with no diacritics,
// supporting both Latin and Cyrillic scripts.
func normalize(s string) string {
	s = strings.TrimSpace(s)
	s = strings.ToLower(s)
	// NFC normalization for consistent Cyrillic/Latin handling.
	s = norm.NFC.String(s)
	// Remove common diacritics from Latin characters.
	var b strings.Builder
	b.Grow(len(s))
	for _, r := range s {
		if unicode.Is(unicode.Mn, r) {
			continue // skip combining marks
		}
		if r == '\'' || r == '’' || r == '`' || r == 'ʼ' {
			continue
		}
		if unicode.IsPunct(r) || unicode.IsSymbol(r) {
			b.WriteRune(' ')
			continue
		}
		b.WriteRune(r)
	}
	return strings.Join(strings.Fields(b.String()), " ")
}
