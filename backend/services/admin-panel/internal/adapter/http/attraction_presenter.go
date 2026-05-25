package http

import (
	"fmt"
	"html/template"
	"net/url"
	"strconv"
	"strings"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

const attractionListPageSize = 25

var attractionCategoryNames = map[string]map[string]string{
	"NATURE":        {localeEN: "Nature", localeRU: "Природа"},
	"ARCHITECTURE":  {localeEN: "Architecture", localeRU: "Архитектура"},
	"MUSEUM":        {localeEN: "Museum", localeRU: "Музей"},
	"BEACH":         {localeEN: "Beach", localeRU: "Пляж"},
	"PARK":          {localeEN: "Park", localeRU: "Парк"},
	"TEMPLE":        {localeEN: "Temple", localeRU: "Храм"},
	"ENTERTAINMENT": {localeEN: "Entertainment", localeRU: "Развлечения"},
	"FOOD":          {localeEN: "Food", localeRU: "Еда"},
	"SHOPPING":      {localeEN: "Shopping", localeRU: "Шопинг"},
	"OTHER":         {localeEN: "Other", localeRU: "Другое"},
	"CULTURE":       {localeEN: "Culture", localeRU: "Культура"},
	"HISTORY":       {localeEN: "History", localeRU: "История"},
	"RELIGION":      {localeEN: "Religion", localeRU: "Религия"},
	"SPORT":         {localeEN: "Sport", localeRU: "Спорт"},
}

var attractionSourceNames = map[string]map[string]string{
	"USER":     {localeEN: "User", localeRU: "Пользователь"},
	"AI_AGENT": {localeEN: "AI agent", localeRU: "AI-агент"},
	"IMPORT":   {localeEN: "Import", localeRU: "Импорт"},
}

var attractionCountryValues = []string{"KZ", "RU"}

type attractionCityReference struct {
	CountryCode string
	CityID      string
}

var attractionCityValues = []attractionCityReference{
	{CountryCode: "KZ", CityID: "almaty"},
	{CountryCode: "KZ", CityID: "astana"},
	{CountryCode: "KZ", CityID: "shymkent"},
	{CountryCode: "KZ", CityID: "taldykorgan"},
	{CountryCode: "KZ", CityID: "aktau"},
	{CountryCode: "KZ", CityID: "aktobe"},
	{CountryCode: "KZ", CityID: "atyrau"},
	{CountryCode: "KZ", CityID: "balkhash"},
	{CountryCode: "KZ", CityID: "karaganda"},
	{CountryCode: "KZ", CityID: "kokshetau"},
	{CountryCode: "KZ", CityID: "kostanay"},
	{CountryCode: "KZ", CityID: "kyzylorda"},
	{CountryCode: "KZ", CityID: "oral"},
	{CountryCode: "KZ", CityID: "pavlodar"},
	{CountryCode: "KZ", CityID: "petropavlovsk"},
	{CountryCode: "KZ", CityID: "semey"},
	{CountryCode: "KZ", CityID: "taraz"},
	{CountryCode: "KZ", CityID: "turkestan"},
	{CountryCode: "KZ", CityID: "ust-kamenogorsk"},
	{CountryCode: "KZ", CityID: "zhezkazgan"},
	{CountryCode: "RU", CityID: "moscow"},
	{CountryCode: "RU", CityID: "saint-petersburg"},
	{CountryCode: "RU", CityID: "kazan"},
	{CountryCode: "RU", CityID: "sochi"},
	{CountryCode: "RU", CityID: "nizhny-novgorod"},
	{CountryCode: "RU", CityID: "yekaterinburg"},
	{CountryCode: "RU", CityID: "vladivostok"},
	{CountryCode: "RU", CityID: "kaliningrad"},
	{CountryCode: "RU", CityID: "volgograd"},
}

var attractionCurrencyValues = []string{"KZT", "USD", "EUR"}

func attractionInputFromItem(item *model.AdminAttraction) model.AttractionInput {
	if item == nil {
		return model.AttractionInput{DefaultLocale: "ru", CountryCode: "KZ", Status: "PUBLISHED", Category: "NATURE"}
	}
	visitInfo := item.VisitInfo
	return model.AttractionInput{
		Title:             item.Title,
		Description:       item.Description,
		DefaultLocale:     item.DefaultLocale,
		Translations:      item.Translations,
		CountryCode:       item.CountryCode,
		CityID:            item.CityID,
		AccessCities:      item.AccessCities,
		DepartureCities:   item.DepartureCities,
		Latitude:          item.Latitude,
		Longitude:         item.Longitude,
		LocationSourceURL: item.LocationSourceURL,
		Category:          item.Category,
		PriceAmount:       item.PriceAmount,
		PriceCurrency:     item.PriceCurrency,
		DurationValue:     item.DurationValue,
		DurationUnit:      item.DurationUnit,
		Spots:             item.Spots,
		Status:            item.Status,
		Tags:              item.Tags,
		VisitInfo:         &visitInfo,
	}
}

func attractionCategoryText(locale string, category string) string {
	raw := strings.TrimSpace(category)
	if raw == "" {
		return "-"
	}
	key := normalizeAttractionCode(raw)
	if names, ok := attractionCategoryNames[key]; ok {
		return localizedValue(locale, names)
	}
	return humanizeCityID(strings.ToLower(raw))
}

func attractionCityText(locale string, countryCode string, cityID string) string {
	city := displayReferenceCityName(locale, cityID)
	country := countryText(locale, countryCode)
	if city == "" && country == "" {
		return "-"
	}
	if city == "" {
		return country
	}
	if country == "" {
		return city
	}
	return city + ", " + country
}

func countryText(locale string, countryCode string) string {
	return displayCountryName(locale, countryCode)
}

func attractionCityNameText(locale string, cityID string) string {
	return displayReferenceCityName(locale, cityID)
}

func attractionCurrencyText(locale string, currency string) string {
	switch strings.ToUpper(strings.TrimSpace(currency)) {
	case "KZT":
		if locale == localeRU {
			return "Казахстанский тенге"
		}
		return "Kazakhstani tenge"
	case "USD":
		if locale == localeRU {
			return "Доллар США"
		}
		return "US dollar"
	case "EUR":
		if locale == localeRU {
			return "Евро"
		}
		return "Euro"
	default:
		return strings.ToUpper(strings.TrimSpace(currency))
	}
}

func localizedAttractionValue(locale string, values map[string]map[string]string, key string) string {
	if item, ok := values[key]; ok {
		if value := strings.TrimSpace(item[locale]); value != "" {
			return value
		}
		if value := strings.TrimSpace(item[localeEN]); value != "" {
			return value
		}
	}
	return strings.TrimSpace(key)
}

func attractionLocaleText(locale string, languageCode string) string {
	code := strings.ToLower(strings.TrimSpace(languageCode))
	if names, ok := languageNames[code]; ok {
		return localizedValue(locale, names)
	}
	if code == "" {
		return "-"
	}
	return strings.ToUpper(code)
}

func attractionSourceText(locale string, source string) string {
	raw := strings.TrimSpace(source)
	if raw == "" {
		return "-"
	}
	key := normalizeAttractionCode(raw)
	if names, ok := attractionSourceNames[key]; ok {
		return localizedValue(locale, names)
	}
	return humanizeCityID(strings.ToLower(raw))
}

func attractionListMetaText(locale string, item model.AdminAttraction) string {
	return fmt.Sprintf("%s: %s · %s: %s",
		translate(locale, "field.defaultLocale"),
		attractionLocaleText(locale, item.DefaultLocale),
		translate(locale, "field.source"),
		attractionSourceText(locale, item.Source),
	)
}

func normalizeAttractionCode(raw string) string {
	value := strings.TrimSpace(raw)
	value = strings.ReplaceAll(value, "-", "_")
	value = strings.ReplaceAll(value, " ", "_")
	return strings.ToUpper(value)
}

func attractionMediaURL(fileID uuid.UUID) template.URL {
	if fileID == uuid.Nil {
		return ""
	}
	return template.URL("/admin/attraction-media/" + fileID.String())
}

func attractionMediaImageURL(item model.AdminAttractionMedia) template.URL {
	if item.FileID != uuid.Nil {
		return attractionMediaURL(item.FileID)
	}
	externalURL := strings.TrimSpace(item.ExternalURL)
	if externalURL == "" {
		return ""
	}
	parsed, err := url.Parse(externalURL)
	if err != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		return ""
	}
	return template.URL(externalURL)
}

func attractionMediaPosition(position int) int {
	if position < 0 {
		return 1
	}
	return position + 1
}

func attractionTagsText(tags []string) string {
	return strings.Join(tags, ", ")
}

func attractionCityLinksText(items []model.AttractionCityLink) string {
	parts := make([]string, 0, len(items))
	for _, item := range items {
		if strings.TrimSpace(item.CityID) == "" {
			continue
		}
		if strings.TrimSpace(item.CountryCode) != "" {
			parts = append(parts, strings.ToUpper(strings.TrimSpace(item.CountryCode))+":"+strings.ToLower(strings.TrimSpace(item.CityID)))
			continue
		}
		parts = append(parts, strings.ToLower(strings.TrimSpace(item.CityID)))
	}
	return strings.Join(parts, ", ")
}

func attractionVisitInfoValue(item *model.AttractionVisitInfo, field string) string {
	if item == nil {
		return ""
	}
	switch field {
	case "bestTime":
		return item.BestTime
	case "accessibility":
		return item.Accessibility
	case "openingHours":
		return item.OpeningHours
	default:
		return ""
	}
}

func attractionOptionalStringEquals(value *string, expected string) bool {
	if value == nil {
		return strings.TrimSpace(expected) == ""
	}
	return strings.EqualFold(strings.TrimSpace(*value), strings.TrimSpace(expected))
}

func attractionTranslationTitle(input model.AttractionInput, locale string) string {
	if tr, ok := input.Translations[locale]; ok {
		return tr.Title
	}
	if locale == input.DefaultLocale {
		return input.Title
	}
	return ""
}

func attractionTranslationDescription(input model.AttractionInput, locale string) string {
	if tr, ok := input.Translations[locale]; ok {
		return tr.Description
	}
	if locale == input.DefaultLocale {
		return input.Description
	}
	return ""
}

func attractionCategoryOptions(selected string) []AttractionOptionView {
	values := []string{"NATURE", "ARCHITECTURE", "MUSEUM", "BEACH", "PARK", "TEMPLE", "ENTERTAINMENT", "FOOD", "SHOPPING", "OTHER"}
	return attractionOptions(values, "attraction.category.", selected)
}

func attractionStatusOptions(selected string) []AttractionOptionView {
	values := []string{"DRAFT", "PUBLISHED"}
	return attractionOptions(values, "attraction.status.", selected)
}

func attractionCountryOptions(selected string) []AttractionOptionView {
	selected = strings.ToUpper(strings.TrimSpace(selected))
	if selected == "" {
		selected = "KZ"
	}
	return attractionValueOptions(attractionCountryValues, selected, true)
}

func attractionCountryFilterOptions(selected string) []AttractionOptionView {
	selected = strings.ToUpper(strings.TrimSpace(selected))
	return attractionValueOptions(attractionCountryValues, selected, true)
}

func attractionCityOptions(selected string) []AttractionOptionView {
	selected = strings.ToLower(strings.TrimSpace(selected))
	seen := make(map[string]bool, len(attractionCityValues)+1)
	out := make([]AttractionOptionView, 0, len(attractionCityValues)+1)
	for _, item := range attractionCityValues {
		country := strings.ToUpper(strings.TrimSpace(item.CountryCode))
		cityID := strings.ToLower(strings.TrimSpace(item.CityID))
		if country == "" || cityID == "" || seen[country+":"+cityID] {
			continue
		}
		seen[country+":"+cityID] = true
		out = append(out, AttractionOptionView{
			Value:       cityID,
			LabelKey:    cityID,
			Selected:    selected == cityID,
			CountryCode: country,
		})
	}
	if selected != "" {
		var found bool
		for _, item := range out {
			if item.Value == selected {
				found = true
				break
			}
		}
		if !found {
			out = append(out, AttractionOptionView{
				Value:       selected,
				LabelKey:    selected,
				Selected:    true,
				CountryCode: "KZ",
			})
		}
	}
	return out
}

func attractionCurrencyOptions(selected *string) []AttractionOptionView {
	value := ""
	if selected != nil {
		value = strings.ToUpper(strings.TrimSpace(*selected))
	}
	return attractionValueOptions(attractionCurrencyValues, value, true)
}

func attractionValueOptions(values []string, selected string, uppercase bool) []AttractionOptionView {
	seen := make(map[string]bool, len(values)+1)
	out := make([]AttractionOptionView, 0, len(values)+1)
	for _, value := range values {
		normalized := strings.TrimSpace(value)
		if uppercase {
			normalized = strings.ToUpper(normalized)
		} else {
			normalized = strings.ToLower(normalized)
		}
		if normalized == "" || seen[normalized] {
			continue
		}
		seen[normalized] = true
		out = append(out, AttractionOptionView{
			Value:    normalized,
			LabelKey: normalized,
			Selected: selected == normalized,
		})
	}
	if selected != "" && !seen[selected] {
		out = append(out, AttractionOptionView{
			Value:    selected,
			LabelKey: selected,
			Selected: true,
		})
	}
	return out
}

func attractionLocaleOptions(selected string) []AttractionOptionView {
	values := []string{"ru", "en", "kk"}
	return attractionOptions(values, "attraction.locale.", selected)
}

func attractionOptions(values []string, prefix string, selected string) []AttractionOptionView {
	selected = strings.ToUpper(strings.TrimSpace(selected))
	if strings.HasPrefix(prefix, "attraction.locale.") {
		selected = strings.ToLower(strings.TrimSpace(selected))
		if selected == "" {
			selected = "ru"
		}
	}
	out := make([]AttractionOptionView, 0, len(values))
	for _, value := range values {
		compare := value
		if strings.HasPrefix(prefix, "attraction.category.") || strings.HasPrefix(prefix, "attraction.status.") {
			compare = strings.ToUpper(value)
		}
		out = append(out, AttractionOptionView{
			Value:    value,
			LabelKey: prefix + value,
			Selected: selected == compare || (selected == "" && value == "PUBLISHED"),
		})
	}
	return out
}

func attractionListQuery(r valuesReader) AttractionFilterViewData {
	search := strings.TrimSpace(r.Get("q"))
	category := strings.ToUpper(strings.TrimSpace(r.Get("category")))
	status := strings.ToUpper(strings.TrimSpace(r.Get("status")))
	countryCode := strings.ToUpper(strings.TrimSpace(r.Get("country")))
	cityID := strings.ToLower(strings.TrimSpace(r.Get("city")))
	page := parseAttractionListPage(r.Get("page"))
	if countryCode == "" {
		cityID = ""
	}
	values := url.Values{}
	setAttractionQuery(values, "q", search)
	setAttractionQuery(values, "category", category)
	setAttractionQuery(values, "status", status)
	setAttractionQuery(values, "country", countryCode)
	setAttractionQuery(values, "city", cityID)
	return AttractionFilterViewData{
		Search:      search,
		Category:    category,
		Status:      status,
		CountryCode: countryCode,
		CityID:      cityID,
		Page:        page,
		Query:       values.Encode(),
	}
}

func parseAttractionListPage(raw string) int {
	page, err := strconv.Atoi(strings.TrimSpace(raw))
	if err != nil || page < 1 {
		return 1
	}
	return page
}

func attractionPagination(total int, filters AttractionFilterViewData) AttractionPaginationViewData {
	page := filters.Page
	if page < 1 {
		page = 1
	}
	totalPages := 0
	if total > 0 {
		totalPages = (total + attractionListPageSize - 1) / attractionListPageSize
	}
	from := 0
	to := 0
	if total > 0 {
		from = (page-1)*attractionListPageSize + 1
		to = page * attractionListPageSize
		if to > total {
			to = total
		}
		if from > total {
			from = total
		}
	}
	return AttractionPaginationViewData{
		Page:          page,
		PageSize:      attractionListPageSize,
		Total:         total,
		TotalPages:    totalPages,
		From:          from,
		To:            to,
		HasPrevious:   page > 1,
		HasNext:       totalPages > 0 && page < totalPages,
		PreviousQuery: attractionPageQuery(filters.Query, page-1),
		NextQuery:     attractionPageQuery(filters.Query, page+1),
	}
}

func attractionPageQuery(baseQuery string, page int) string {
	if page < 1 {
		page = 1
	}
	values, err := url.ParseQuery(strings.TrimSpace(baseQuery))
	if err != nil {
		values = url.Values{}
	}
	values.Set("page", strconv.Itoa(page))
	return values.Encode()
}

func attractionPaginationSummary(locale string, pagination AttractionPaginationViewData) string {
	if locale == localeRU {
		return fmt.Sprintf("Показано %d-%d из %d", pagination.From, pagination.To, pagination.Total)
	}
	return fmt.Sprintf("Showing %d-%d of %d", pagination.From, pagination.To, pagination.Total)
}

func attractionCityLinkOptions(selected []model.AttractionCityLink, fallbackCountry string) []AttractionCityLinkOptionView {
	selectedMap := make(map[string]model.AttractionCityLink, len(selected))
	for _, item := range selected {
		country := strings.ToUpper(strings.TrimSpace(item.CountryCode))
		if country == "" {
			country = strings.ToUpper(strings.TrimSpace(fallbackCountry))
		}
		if country == "" {
			country = "KZ"
		}
		cityID := strings.ToLower(strings.TrimSpace(item.CityID))
		if cityID == "" {
			continue
		}
		selectedMap[country+":"+cityID] = model.AttractionCityLink{CountryCode: country, CityID: cityID}
	}

	out := make([]AttractionCityLinkOptionView, 0, len(attractionCityValues)+len(selectedMap))
	seen := make(map[string]bool, len(attractionCityValues)+len(selectedMap))
	for _, item := range attractionCityValues {
		country := strings.ToUpper(strings.TrimSpace(item.CountryCode))
		cityID := strings.ToLower(strings.TrimSpace(item.CityID))
		if country == "" || cityID == "" {
			continue
		}
		value := country + ":" + cityID
		_, selected := selectedMap[value]
		out = append(out, AttractionCityLinkOptionView{
			Value:       value,
			CountryCode: country,
			CityID:      cityID,
			Selected:    selected,
		})
		seen[value] = true
	}
	for value, item := range selectedMap {
		if seen[value] {
			continue
		}
		out = append(out, AttractionCityLinkOptionView{
			Value:       value,
			CountryCode: item.CountryCode,
			CityID:      item.CityID,
			Selected:    true,
		})
	}
	return out
}

type valuesReader interface {
	Get(string) string
}

func setAttractionQuery(values url.Values, key string, value string) {
	value = strings.TrimSpace(value)
	if value != "" {
		values.Set(key, value)
	}
}

func parseCityLinks(raw string, fallbackCountry string) []model.AttractionCityLink {
	return parseCityLinkValues([]string{raw}, fallbackCountry)
}

func parseCityLinkValues(values []string, fallbackCountry string) []model.AttractionCityLink {
	items := make([]string, 0, len(values))
	for _, value := range values {
		items = append(items, splitCSV(value)...)
	}
	out := make([]model.AttractionCityLink, 0, len(items))
	seen := make(map[string]bool, len(items))
	for _, item := range items {
		country := fallbackCountry
		city := item
		if strings.Contains(item, ":") {
			parts := strings.SplitN(item, ":", 2)
			country = parts[0]
			city = parts[1]
		}
		city = strings.ToLower(strings.TrimSpace(city))
		if city == "" {
			continue
		}
		country = strings.ToUpper(strings.TrimSpace(country))
		if country == "" {
			country = "KZ"
		}
		key := country + ":" + city
		if seen[key] {
			continue
		}
		seen[key] = true
		out = append(out, model.AttractionCityLink{
			CountryCode: country,
			CityID:      city,
		})
	}
	return out
}

func parseOptionalFloat(raw string) (*float64, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}
	var value float64
	if _, err := fmt.Sscanf(raw, "%f", &value); err != nil {
		return nil, err
	}
	return &value, nil
}

func parseOptionalInt(raw string) (*int, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}
	var value int
	if _, err := fmt.Sscanf(raw, "%d", &value); err != nil {
		return nil, err
	}
	return &value, nil
}
