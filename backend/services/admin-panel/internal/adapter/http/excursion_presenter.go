package http

import (
	"fmt"
	"strings"
	"unicode"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

const (
	genericRouteSummary     = "Compare guide offers for this route."
	genericRouteDescription = "Choose a guide, language, price, meeting point, and schedule before booking this route."
)

var countryNames = map[string]map[string]string{
	"KZ": {localeEN: "Kazakhstan", localeRU: "Казахстан"},
	"KG": {localeEN: "Kyrgyzstan", localeRU: "Кыргызстан"},
	"UZ": {localeEN: "Uzbekistan", localeRU: "Узбекистан"},
	"RU": {localeEN: "Russian Federation", localeRU: "Российская Федерация"},
	"VN": {localeEN: "Vietnam", localeRU: "Вьетнам"},
	"TR": {localeEN: "Turkey", localeRU: "Турция"},
	"AE": {localeEN: "United Arab Emirates", localeRU: "ОАЭ"},
	"GE": {localeEN: "Georgia", localeRU: "Грузия"},
	"AZ": {localeEN: "Azerbaijan", localeRU: "Азербайджан"},
	"US": {localeEN: "United States", localeRU: "США"},
}

var cityNames = map[string]map[string]string{
	"aktau":            {localeEN: "Aktau", localeRU: "Актау"},
	"aktobe":           {localeEN: "Aktobe", localeRU: "Актобе"},
	"almaty":           {localeEN: "Almaty", localeRU: "Алматы"},
	"astana":           {localeEN: "Astana", localeRU: "Астана"},
	"atyrau":           {localeEN: "Atyrau", localeRU: "Атырау"},
	"balkhash":         {localeEN: "Balkhash", localeRU: "Балхаш"},
	"can-tho":          {localeEN: "Can Tho", localeRU: "Кантхо"},
	"cat-ba":           {localeEN: "Cat Ba", localeRU: "Катба"},
	"da-lat":           {localeEN: "Da Lat", localeRU: "Далат"},
	"da-nang":          {localeEN: "Da Nang", localeRU: "Дананг"},
	"ha-giang":         {localeEN: "Ha Giang", localeRU: "Хазянг"},
	"ha-long":          {localeEN: "Ha Long", localeRU: "Халонг"},
	"hanoi":            {localeEN: "Hanoi", localeRU: "Ханой"},
	"ho-chi-minh-city": {localeEN: "Ho Chi Minh City", localeRU: "Хошимин"},
	"hoi-an":           {localeEN: "Hoi An", localeRU: "Хойан"},
	"hue":              {localeEN: "Hue", localeRU: "Хюэ"},
	"karaganda":        {localeEN: "Karaganda", localeRU: "Караганда"},
	"kokshetau":        {localeEN: "Kokshetau", localeRU: "Кокшетау"},
	"kostanay":         {localeEN: "Kostanay", localeRU: "Костанай"},
	"kyzylorda":        {localeEN: "Kyzylorda", localeRU: "Кызылорда"},
	"kaliningrad":      {localeEN: "Kaliningrad", localeRU: "Калининград"},
	"kazan":            {localeEN: "Kazan", localeRU: "Казань"},
	"moscow":           {localeEN: "Moscow", localeRU: "Москва"},
	"nha-trang":        {localeEN: "Nha Trang", localeRU: "Нячанг"},
	"nizhny-novgorod":  {localeEN: "Nizhny Novgorod", localeRU: "Нижний Новгород"},
	"ninh-binh":        {localeEN: "Ninh Binh", localeRU: "Ниньбинь"},
	"oral":             {localeEN: "Oral", localeRU: "Орал"},
	"pavlodar":         {localeEN: "Pavlodar", localeRU: "Павлодар"},
	"petropavl":        {localeEN: "Petropavl", localeRU: "Петропавловск"},
	"petropavlovsk":    {localeEN: "Petropavlovsk", localeRU: "Петропавловск"},
	"phan-thiet":       {localeEN: "Phan Thiet", localeRU: "Фантхьет"},
	"phu-quoc":         {localeEN: "Phu Quoc", localeRU: "Фукуок"},
	"phong-nha":        {localeEN: "Phong Nha", localeRU: "Фонгня"},
	"sa-pa":            {localeEN: "Sa Pa", localeRU: "Сапа"},
	"saint-petersburg": {localeEN: "Saint Petersburg", localeRU: "Санкт-Петербург"},
	"semey":            {localeEN: "Semey", localeRU: "Семей"},
	"shymkent":         {localeEN: "Shymkent", localeRU: "Шымкент"},
	"sochi":            {localeEN: "Sochi", localeRU: "Сочи"},
	"taldykorgan":      {localeEN: "Taldykorgan", localeRU: "Талдыкорган"},
	"taraz":            {localeEN: "Taraz", localeRU: "Тараз"},
	"turkestan":        {localeEN: "Turkestan", localeRU: "Туркестан"},
	"turkistan":        {localeEN: "Turkistan", localeRU: "Туркестан"},
	"uralsk":           {localeEN: "Oral", localeRU: "Орал"},
	"ust-kamenogorsk":  {localeEN: "Ust-Kamenogorsk", localeRU: "Усть-Каменогорск"},
	"vladivostok":      {localeEN: "Vladivostok", localeRU: "Владивосток"},
	"volgograd":        {localeEN: "Volgograd", localeRU: "Волгоград"},
	"vung-tau":         {localeEN: "Vung Tau", localeRU: "Вунгтау"},
	"yekaterinburg":    {localeEN: "Yekaterinburg", localeRU: "Екатеринбург"},
	"zhezkazgan":       {localeEN: "Zhezkazgan", localeRU: "Жезказган"},
}

var languageNames = map[string]map[string]string{
	"en": {localeEN: "English", localeRU: "Английский"},
	"kk": {localeEN: "Kazakh", localeRU: "Казахский"},
	"ru": {localeEN: "Russian", localeRU: "Русский"},
}

var includedItemNames = map[string]map[string]string{
	"equipment": {localeEN: "Equipment", localeRU: "Снаряжение"},
	"food":      {localeEN: "Food", localeRU: "Питание"},
	"guide":     {localeEN: "Guide service", localeRU: "Услуги гида"},
	"photo":     {localeEN: "Photo support", localeRU: "Фотосопровождение"},
	"tickets":   {localeEN: "Tickets", localeRU: "Входные билеты"},
	"transport": {localeEN: "Transport", localeRU: "Транспорт"},
}

var meetingPointNames = map[string]map[string]string{
	"hotel pickup":        {localeEN: "Hotel pickup", localeRU: "Трансфер от отеля"},
	"main entrance":       {localeEN: "Main entrance", localeRU: "Главный вход"},
	"medeu entrance":      {localeEN: "Medeu entrance", localeRU: "Вход Медеу"},
	"medeu main entrance": {localeEN: "Medeu main entrance", localeRU: "Главный вход Медеу"},
	"visitor center":      {localeEN: "Visitor center", localeRU: "Визит-центр"},
}

func excursionTitleText(locale string, item *model.ExcursionModerationItem, fallback string) string {
	if item == nil {
		return strings.TrimSpace(fallback)
	}
	if title := localizedCopyTitle(locale, item.Translations); title != "" {
		return title
	}
	title := strings.TrimSpace(item.Title)
	productTitle := localizedCopyTitle(locale, item.ProductTranslations)
	if productTitle != "" && (title == "" || sameText(title, item.LandmarkName) || sameText(title, localizedCopyTitle(localeEN, item.ProductTranslations))) {
		return productTitle
	}
	if title != "" {
		return title
	}
	return strings.TrimSpace(fallback)
}

func excursionAttractionsText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return ""
	}
	if landmark := localizedLandmarkName(locale, item); landmark != "" {
		return landmark
	}
	names := localizedAttractionNames(locale, item)
	return strings.Join(names, ", ")
}

func excursionGuidePrimaryText(item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	if nickname := strings.TrimSpace(item.GuideNickname); nickname != "" {
		return nickname
	}
	if displayName := strings.TrimSpace(item.GuideDisplayName); displayName != "" {
		return displayName
	}
	if item.GuideUserID.String() != "00000000-0000-0000-0000-000000000000" {
		return "Guide " + shortString(item.GuideUserID.String())
	}
	return "-"
}

func excursionGuideFullNameText(item *model.ExcursionModerationItem) string {
	if item == nil {
		return ""
	}
	parts := make([]string, 0, 2)
	if lastName := strings.TrimSpace(item.GuideLastName); lastName != "" {
		parts = append(parts, lastName)
	}
	if firstName := strings.TrimSpace(item.GuideFirstName); firstName != "" {
		parts = append(parts, firstName)
	}
	fullName := strings.Join(parts, " ")
	if fullName != "" {
		return fullName
	}
	displayName := strings.TrimSpace(item.GuideDisplayName)
	nickname := strings.TrimSpace(item.GuideNickname)
	if displayName != "" && displayName != nickname {
		return displayName
	}
	return ""
}

func excursionLocationText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	parts := make([]string, 0, 2)
	if city := displayCityName(locale, item.CityName); city != "" {
		parts = append(parts, city)
	} else if city := displayReferenceCityName(locale, item.DepartureCityID); city != "" {
		parts = append(parts, city)
	}
	if country := displayCountryName(locale, item.CountryCode); country != "" {
		parts = append(parts, country)
	}
	if len(parts) == 0 {
		return "-"
	}
	return strings.Join(parts, ", ")
}

func excursionSummaryText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	if summary := localizedCopySummary(locale, item.Translations); summary != "" {
		return summary
	}
	summary := strings.TrimSpace(item.Summary)
	route := routeNameForCopy(locale, item)
	if isGeneratedSummary(summary) && route != "" {
		if productSummary := localizedCopySummary(locale, item.ProductTranslations); productSummary != "" {
			return productSummary
		}
		return moderationSummaryText(locale, route)
	}
	if summary != "" {
		return summary
	}
	if productSummary := localizedCopySummary(locale, item.ProductTranslations); productSummary != "" {
		return productSummary
	}
	if route != "" {
		return moderationSummaryText(locale, route)
	}
	return "-"
}

func excursionDescriptionText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	if description := localizedCopyDescription(locale, item.Translations); description != "" {
		return description
	}
	description := strings.TrimSpace(item.Description)
	route := routeNameForCopy(locale, item)
	routeStops := routeStopsForCopy(locale, item)
	if isGeneratedDescription(description) && route != "" {
		if productDescription := localizedCopyDescription(locale, item.ProductTranslations); productDescription != "" {
			return productDescription
		}
		return moderationDescriptionText(locale, routeStops)
	}
	if description != "" {
		return description
	}
	if productDescription := localizedCopyDescription(locale, item.ProductTranslations); productDescription != "" {
		return productDescription
	}
	if route != "" {
		return moderationDescriptionText(locale, routeStops)
	}
	return "-"
}

func excursionDurationText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	return durationMinutesText(locale, item.DurationMinutes)
}

func excursionMaxGroupText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil || item.MaxGroupSize <= 0 {
		return "-"
	}
	if normalizeLocaleOrDefault(locale) == localeRU {
		return fmt.Sprintf("До %d гостей", item.MaxGroupSize)
	}
	if item.MaxGroupSize == 1 {
		return "Up to 1 guest"
	}
	return fmt.Sprintf("Up to %d guests", item.MaxGroupSize)
}

func excursionLanguagesText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil || len(item.LanguageCodes) == 0 {
		return "-"
	}
	values := make([]string, 0, len(item.LanguageCodes))
	seen := make(map[string]struct{}, len(item.LanguageCodes))
	for _, code := range item.LanguageCodes {
		code = strings.ToLower(strings.TrimSpace(code))
		if code == "" {
			continue
		}
		if _, ok := seen[code]; ok {
			continue
		}
		seen[code] = struct{}{}
		if names, ok := languageNames[code]; ok {
			values = append(values, localizedValue(locale, names))
			continue
		}
		values = append(values, strings.ToUpper(code))
	}
	if len(values) == 0 {
		return "-"
	}
	return strings.Join(values, ", ")
}

func excursionMeetingPointText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	locale = normalizeLocaleOrDefault(locale)
	if value := strings.TrimSpace(item.MeetingPointByLocale[locale]); value != "" {
		return value
	}
	if locale != defaultLocale {
		if value := strings.TrimSpace(item.MeetingPointByLocale[defaultLocale]); value != "" {
			return value
		}
	}
	if value := strings.TrimSpace(item.MeetingPoint); value != "" {
		if names, ok := meetingPointNames[strings.ToLower(value)]; ok {
			return localizedValue(locale, names)
		}
		return value
	}
	return "-"
}

func excursionIncludedItems(locale string, item *model.ExcursionModerationItem) []string {
	if item == nil {
		return nil
	}
	locale = normalizeLocaleOrDefault(locale)
	if values := normalizedNameList(item.IncludedItemsByLocale[locale]); len(values) > 0 {
		return values
	}
	if locale != defaultLocale {
		if values := normalizedNameList(item.IncludedItemsByLocale[defaultLocale]); len(values) > 0 {
			return values
		}
	}
	result := make([]string, 0, len(item.IncludedItems))
	seen := make(map[string]struct{}, len(item.IncludedItems))
	for _, value := range item.IncludedItems {
		key := strings.ToLower(strings.TrimSpace(value))
		if key == "" {
			continue
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		if names, ok := includedItemNames[key]; ok {
			result = append(result, localizedValue(locale, names))
			continue
		}
		result = append(result, humanizeCityID(key))
	}
	return result
}

func itineraryTitleText(locale string, item model.ExcursionItineraryItem) string {
	if title := localizedItineraryTitle(locale, item.Translations); title != "" {
		return title
	}
	if title := strings.TrimSpace(item.Title); title != "" {
		return title
	}
	if name := strings.TrimSpace(item.AttractionName); name != "" {
		return name
	}
	return "-"
}

func itineraryDescriptionText(locale string, item model.ExcursionItineraryItem) string {
	if description := localizedItineraryDescription(locale, item.Translations); description != "" {
		return description
	}
	if description := strings.TrimSpace(item.Description); description != "" {
		return description
	}
	return ""
}

func itineraryAttractionText(item model.ExcursionItineraryItem) string {
	return strings.TrimSpace(item.AttractionName)
}

func itineraryStartText(offsetMinutes int) string {
	if offsetMinutes < 0 {
		offsetMinutes = 0
	}
	return fmt.Sprintf("%02d:%02d", offsetMinutes/60, offsetMinutes%60)
}

func itineraryDurationText(locale string, value *int) string {
	if value == nil {
		return ""
	}
	return durationMinutesText(locale, *value)
}

func itineraryTravelText(locale string, value *int) string {
	if value == nil || *value <= 0 {
		return ""
	}
	if normalizeLocaleOrDefault(locale) == localeRU {
		return "Переезд " + durationMinutesText(locale, *value)
	}
	return "Travel " + durationMinutesText(locale, *value)
}

func durationMinutesText(locale string, totalMinutes int) string {
	if totalMinutes <= 0 {
		return "-"
	}
	hours := totalMinutes / 60
	minutes := totalMinutes % 60
	if normalizeLocaleOrDefault(locale) == localeRU {
		switch {
		case hours > 0 && minutes > 0:
			return fmt.Sprintf("%d ч %d мин", hours, minutes)
		case hours > 0:
			return fmt.Sprintf("%d ч", hours)
		default:
			return fmt.Sprintf("%d мин", minutes)
		}
	}
	switch {
	case hours > 0 && minutes > 0:
		return fmt.Sprintf("%d h %d min", hours, minutes)
	case hours > 0:
		return fmt.Sprintf("%d h", hours)
	default:
		return fmt.Sprintf("%d min", minutes)
	}
}

func localizedItineraryTitle(locale string, items map[string]model.ExcursionItineraryLocalizedCopy) string {
	return localizedItineraryField(locale, items, func(item model.ExcursionItineraryLocalizedCopy) string {
		return item.Title
	})
}

func localizedItineraryDescription(locale string, items map[string]model.ExcursionItineraryLocalizedCopy) string {
	return localizedItineraryField(locale, items, func(item model.ExcursionItineraryLocalizedCopy) string {
		return item.Description
	})
}

func localizedItineraryField(locale string, items map[string]model.ExcursionItineraryLocalizedCopy, pick func(model.ExcursionItineraryLocalizedCopy) string) string {
	if len(items) == 0 {
		return ""
	}
	locale = normalizeLocaleOrDefault(locale)
	if value := strings.TrimSpace(pick(items[locale])); value != "" {
		return value
	}
	if locale != defaultLocale {
		if value := strings.TrimSpace(pick(items[defaultLocale])); value != "" {
			return value
		}
	}
	for _, item := range items {
		if value := strings.TrimSpace(pick(item)); value != "" {
			return value
		}
	}
	return ""
}

func moderationSummaryText(locale string, route string) string {
	if normalizeLocaleOrDefault(locale) == localeRU {
		return "Заявка гида на публикацию экскурсии: " + route + "."
	}
	return "Guide submission for publishing an excursion: " + route + "."
}

func moderationDescriptionText(locale string, route string) string {
	if normalizeLocaleOrDefault(locale) == localeRU {
		return "Экскурсия по направлению " + route + ". Проверьте программу, цену, место встречи и включенные услуги перед публикацией."
	}
	return "Excursion for " + route + ". Review the program, price, meeting point, and included items before publishing."
}

func routeNameForCopy(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return ""
	}
	if landmark := localizedLandmarkName(locale, item); landmark != "" {
		return landmark
	}
	names := localizedAttractionNames(locale, item)
	if len(names) > 0 {
		return strings.Join(names, " + ")
	}
	return ""
}

func routeStopsForCopy(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return ""
	}
	if landmark := localizedLandmarkName(locale, item); landmark != "" {
		return landmark
	}
	names := localizedAttractionNames(locale, item)
	if len(names) > 0 {
		return strings.Join(names, ", ")
	}
	return ""
}

func localizedLandmarkName(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return ""
	}
	if len(normalizedNameList(item.AttractionNames)) > 0 {
		return ""
	}
	if title := localizedCopyTitle(locale, item.ProductTranslations); title != "" {
		return title
	}
	return strings.TrimSpace(item.LandmarkName)
}

func localizedAttractionNames(locale string, item *model.ExcursionModerationItem) []string {
	if item == nil {
		return nil
	}
	locale = normalizeLocaleOrDefault(locale)
	if names := normalizedNameList(item.AttractionNamesByLocale[locale]); len(names) > 0 {
		return names
	}
	if locale != defaultLocale {
		if names := normalizedNameList(item.AttractionNamesByLocale[defaultLocale]); len(names) > 0 {
			return names
		}
	}
	for _, namesByLocale := range item.AttractionNamesByLocale {
		if names := normalizedNameList(namesByLocale); len(names) > 0 {
			return names
		}
	}
	return normalizedNameList(item.AttractionNames)
}

func localizedCopyTitle(locale string, items map[string]model.ExcursionLocalizedCopy) string {
	return localizedCopyField(locale, items, func(item model.ExcursionLocalizedCopy) string {
		return item.Title
	})
}

func localizedCopySummary(locale string, items map[string]model.ExcursionLocalizedCopy) string {
	return localizedCopyField(locale, items, func(item model.ExcursionLocalizedCopy) string {
		return item.Summary
	})
}

func localizedCopyDescription(locale string, items map[string]model.ExcursionLocalizedCopy) string {
	return localizedCopyField(locale, items, func(item model.ExcursionLocalizedCopy) string {
		return item.Description
	})
}

func localizedCopyField(locale string, items map[string]model.ExcursionLocalizedCopy, pick func(model.ExcursionLocalizedCopy) string) string {
	if len(items) == 0 {
		return ""
	}
	locale = normalizeLocaleOrDefault(locale)
	if value := strings.TrimSpace(pick(items[locale])); value != "" {
		return value
	}
	if locale != defaultLocale {
		if value := strings.TrimSpace(pick(items[defaultLocale])); value != "" {
			return value
		}
	}
	for _, item := range items {
		if value := strings.TrimSpace(pick(item)); value != "" {
			return value
		}
	}
	return ""
}

func isGeneratedSummary(value string) bool {
	value = strings.TrimSpace(value)
	return value == genericRouteSummary ||
		(strings.HasPrefix(value, "Compare guide offers for ") && strings.HasSuffix(value, "."))
}

func isGeneratedDescription(value string) bool {
	value = strings.TrimSpace(value)
	return value == genericRouteDescription ||
		strings.HasPrefix(value, "Choose a guide, language, price, meeting point")
}

func sameText(left string, right string) bool {
	return strings.EqualFold(strings.TrimSpace(left), strings.TrimSpace(right))
}

func normalizedNameList(values []string) []string {
	result := make([]string, 0, len(values))
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		name := strings.TrimSpace(value)
		key := strings.ToLower(name)
		if key == "" {
			continue
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, name)
	}
	return result
}

func displayCountryName(locale string, countryCode string) string {
	code := strings.ToUpper(strings.TrimSpace(countryCode))
	if code == "" {
		return ""
	}
	names, ok := countryNames[code]
	if !ok {
		return code
	}
	return localizedValue(locale, names)
}

func displayReferenceCityName(locale string, cityID string) string {
	id := strings.ToLower(strings.TrimSpace(cityID))
	if id == "" {
		return ""
	}
	if names, ok := cityNames[id]; ok {
		return localizedValue(locale, names)
	}
	return humanizeCityID(id)
}

func displayCityName(locale string, city string) string {
	name := strings.TrimSpace(city)
	if name == "" {
		return ""
	}
	if names, ok := localizedCityNamesForValue(name); ok {
		return localizedValue(locale, names)
	}
	return name
}

func localizedCityNamesForValue(value string) (map[string]string, bool) {
	key := strings.ToLower(strings.TrimSpace(value))
	if key == "" {
		return nil, false
	}
	if beforeComma, _, ok := strings.Cut(key, ","); ok {
		key = strings.TrimSpace(beforeComma)
	}
	if names, ok := cityNames[key]; ok {
		return names, true
	}
	for _, names := range cityNames {
		for _, name := range names {
			if strings.ToLower(strings.TrimSpace(name)) == key {
				return names, true
			}
		}
	}
	return nil, false
}

func humanizeCityID(value string) string {
	parts := strings.FieldsFunc(value, func(r rune) bool {
		return r == '-' || r == '_'
	})
	words := make([]string, 0, len(parts))
	for _, part := range parts {
		runes := []rune(part)
		if len(runes) == 0 {
			continue
		}
		runes[0] = unicode.ToUpper(runes[0])
		words = append(words, string(runes))
	}
	return strings.Join(words, " ")
}

func localizedValue(locale string, values map[string]string) string {
	locale = normalizeLocaleOrDefault(locale)
	if value := strings.TrimSpace(values[locale]); value != "" {
		return value
	}
	if value := strings.TrimSpace(values[defaultLocale]); value != "" {
		return value
	}
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			return trimmed
		}
	}
	return ""
}

func normalizeLocaleOrDefault(locale string) string {
	if normalized, ok := normalizeLocale(locale); ok {
		return normalized
	}
	return defaultLocale
}
