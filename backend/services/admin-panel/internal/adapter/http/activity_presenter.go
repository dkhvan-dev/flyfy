package http

import (
	"fmt"
	"strings"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

var activityCategoryNames = map[string]map[string]string{
	"food-drinks":         {localeEN: "Food & Drinks", localeRU: "Еда и напитки"},
	"social-nightlife":    {localeEN: "Social & Nightlife", localeRU: "Общение и ночная жизнь"},
	"culture-art":         {localeEN: "Culture & Art", localeRU: "Культура и искусство"},
	"city-walks":          {localeEN: "Walks & City", localeRU: "Прогулки и город"},
	"nature-outdoor":      {localeEN: "Nature & Outdoor", localeRU: "Природа и активный отдых"},
	"adventure-sports":    {localeEN: "Nature & Outdoor", localeRU: "Природа и активный отдых"},
	"sports-wellness":     {localeEN: "Sports & Wellness", localeRU: "Спорт и здоровье"},
	"health-wellness":     {localeEN: "Sports & Wellness", localeRU: "Спорт и здоровье"},
	"workshops-learning":  {localeEN: "Workshops & Learning", localeRU: "Мастер-классы и обучение"},
	"games-entertainment": {localeEN: "Games & Entertainment", localeRU: "Игры и развлечения"},
	"family-kids":         {localeEN: "Family & Kids", localeRU: "Семья и дети"},
	"other":               {localeEN: "Other", localeRU: "Другое"},
}

var activitySubcategoryNames = map[string]map[string]string{
	"coffee-meetup":     {localeEN: "Coffee meetup", localeRU: "Кофе-встреча"},
	"food-tasting":      {localeEN: "Food tasting", localeRU: "Дегустация"},
	"dinner-club":       {localeEN: "Dinner club", localeRU: "Ужин-клуб"},
	"bar-hop":           {localeEN: "Bar hop", localeRU: "Бар-хоппинг"},
	"social-meetup":     {localeEN: "Social meetup", localeRU: "Встреча для общения"},
	"speed-friending":   {localeEN: "Speed friending", localeRU: "Быстрые знакомства"},
	"networking":        {localeEN: "Networking", localeRU: "Нетворкинг"},
	"party-night":       {localeEN: "Party night", localeRU: "Вечеринка"},
	"museum-gallery":    {localeEN: "Museum or gallery", localeRU: "Музей или галерея"},
	"live-music":        {localeEN: "Live music", localeRU: "Живая музыка"},
	"theatre-cinema":    {localeEN: "Theatre or cinema", localeRU: "Театр или кино"},
	"local-culture":     {localeEN: "Local culture", localeRU: "Локальная культура"},
	"city-walk":         {localeEN: "City walk", localeRU: "Городская прогулка"},
	"photo-walk":        {localeEN: "Photo walk", localeRU: "Фотопрогулка"},
	"architecture":      {localeEN: "Architecture", localeRU: "Архитектура"},
	"hidden-gems":       {localeEN: "Hidden gems", localeRU: "Неочевидные места"},
	"hiking":            {localeEN: "Hiking", localeRU: "Хайкинг"},
	"park-picnic":       {localeEN: "Park or picnic", localeRU: "Парк или пикник"},
	"camping":           {localeEN: "Camping", localeRU: "Кемпинг"},
	"day-trip":          {localeEN: "Day trip", localeRU: "Поездка на день"},
	"yoga-meditation":   {localeEN: "Yoga or meditation", localeRU: "Йога или медитация"},
	"running":           {localeEN: "Running", localeRU: "Бег"},
	"fitness":           {localeEN: "Fitness", localeRU: "Фитнес"},
	"dance":             {localeEN: "Dance", localeRU: "Танцы"},
	"creative-workshop": {localeEN: "Creative workshop", localeRU: "Творческий мастер-класс"},
	"language-practice": {localeEN: "Language practice", localeRU: "Языковая практика"},
	"lecture-talk":      {localeEN: "Lecture or talk", localeRU: "Лекция или встреча"},
	"cooking-class":     {localeEN: "Cooking class", localeRU: "Кулинарный мастер-класс"},
	"quiz-trivia":       {localeEN: "Quiz or trivia", localeRU: "Квиз"},
	"board-games":       {localeEN: "Board games", localeRU: "Настольные игры"},
	"karaoke":           {localeEN: "Karaoke", localeRU: "Караоке"},
	"escape-room":       {localeEN: "Escape room", localeRU: "Квест"},
	"family-walk":       {localeEN: "Family walk", localeRU: "Семейная прогулка"},
	"kids-workshop":     {localeEN: "Kids workshop", localeRU: "Детский мастер-класс"},
	"kids-education":    {localeEN: "Kids education", localeRU: "Детское обучение"},
	"family-show":       {localeEN: "Family show", localeRU: "Семейное шоу"},
	"community-event":   {localeEN: "Community event", localeRU: "Событие сообщества"},
	"special-event":     {localeEN: "Special event", localeRU: "Особое событие"},
}

func activityLocationText(locale string, item *model.ActivityModerationItem) string {
	if item == nil {
		return "-"
	}
	parts := make([]string, 0, 3)
	if city := displayReferenceCityName(locale, stringValue(item.CityID)); city != "" {
		parts = append(parts, city)
	} else if city := displayCityName(locale, stringValue(item.CityName)); city != "" {
		parts = append(parts, city)
	}
	if country := displayCountryName(locale, stringValue(item.CountryCode)); country != "" {
		parts = append(parts, country)
	}
	if len(parts) == 0 && strings.TrimSpace(stringValue(item.AddressText)) != "" {
		parts = append(parts, strings.TrimSpace(stringValue(item.AddressText)))
	}
	if len(parts) == 0 {
		return "-"
	}
	return strings.Join(parts, ", ")
}

func activityScheduleText(locale string, item *model.ActivityModerationItem) string {
	if item == nil {
		return "-"
	}
	start := formatTemplateTime(item.StartAt)
	end := formatTemplateTime(item.EndAt)
	if start == "-" && end == "-" {
		return "-"
	}
	if end == "-" {
		return start
	}
	return start + " - " + end
}

func activityDurationText(locale string, item *model.ActivityModerationItem) string {
	if item == nil || item.EndAt.IsZero() || item.StartAt.IsZero() || !item.EndAt.After(item.StartAt) {
		return "-"
	}
	return durationMinutesText(locale, int(item.EndAt.Sub(item.StartAt).Minutes()))
}

func activityCapacityText(locale string, item *model.ActivityModerationItem) string {
	if item == nil {
		return "-"
	}
	if strings.EqualFold(item.CapacityType, "UNLIMITED") {
		if normalizeLocaleOrDefault(locale) == localeRU {
			return "Без ограничения"
		}
		return "Unlimited"
	}
	if item.MaxParticipants == nil {
		return "-"
	}
	if item.MinParticipants != nil && *item.MinParticipants > 0 {
		return fmt.Sprintf("%d-%d", *item.MinParticipants, *item.MaxParticipants)
	}
	return fmt.Sprintf("%d", *item.MaxParticipants)
}

func activityPriceText(locale string, item *model.ActivityModerationItem) string {
	if item == nil {
		return "-"
	}
	if strings.EqualFold(item.PriceType, "FREE") {
		return translate(locale, "status.FREE")
	}
	if item.PriceAmount == nil {
		return "-"
	}
	return fmt.Sprintf("%.2f %s", *item.PriceAmount, strings.TrimSpace(stringValue(item.Currency)))
}

func activityMeetingText(item *model.ActivityModerationItem) string {
	if item == nil {
		return "-"
	}
	if value := strings.TrimSpace(stringValue(item.AddressText)); value != "" {
		return value
	}
	if value := strings.TrimSpace(stringValue(item.MeetingURL)); value != "" {
		return value
	}
	return "-"
}

func activityMapURL(item *model.ActivityModerationItem) string {
	if item == nil {
		return ""
	}
	if value := safeExternalURL(stringValue(item.MapURL)); value != "" {
		return value
	}
	if item.Latitude == nil || item.Longitude == nil {
		return ""
	}
	lat := *item.Latitude
	lon := *item.Longitude
	return fmt.Sprintf(
		"https://www.openstreetmap.org/?mlat=%.7f&mlon=%.7f#map=16/%.7f/%.7f",
		lat,
		lon,
		lat,
		lon,
	)
}

func safeExternalURL(value string) string {
	value = strings.TrimSpace(value)
	lower := strings.ToLower(value)
	if strings.HasPrefix(lower, "https://") || strings.HasPrefix(lower, "http://") {
		return value
	}
	return ""
}

func activityDecisionLocked(item *model.ActivityModerationItem) bool {
	if item == nil {
		return false
	}
	moderationStatus := strings.ToUpper(strings.TrimSpace(item.ModerationStatus))
	status := strings.ToUpper(strings.TrimSpace(item.Status))
	return moderationStatus == "REJECTED" || status == "CANCELLED"
}

func activityCategoryText(locale string, item *model.ActivityModerationItem) string {
	if item == nil {
		return "-"
	}
	parts := make([]string, 0, 2)
	if category := activityCategoryName(locale, item); category != "" {
		parts = append(parts, category)
	}
	if item.SubcategorySlug != nil && strings.TrimSpace(*item.SubcategorySlug) != "" {
		if subcategory := activitySubcategoryName(locale, item); subcategory != "" {
			parts = append(parts, subcategory)
		}
	}
	value := strings.Join(parts, " / ")
	if strings.TrimSpace(value) == "" {
		return "-"
	}
	return value
}

func activityCategoryName(locale string, item *model.ActivityModerationItem) string {
	if item == nil {
		return ""
	}
	if value := localizedActivityTaxonomyName(
		locale,
		item.CategoryName,
		item.CategoryNameRu,
		item.CategoryNameKk,
	); value != "" {
		return value
	}
	slug := strings.ToLower(strings.TrimSpace(item.CategorySlug))
	if names, ok := activityCategoryNames[slug]; ok {
		return localizedValue(locale, names)
	}
	return humanizeActivityTaxonomySlug(slug)
}

func activitySubcategoryName(locale string, item *model.ActivityModerationItem) string {
	if item == nil || item.SubcategorySlug == nil {
		return ""
	}
	if value := localizedActivityTaxonomyName(
		locale,
		item.SubcategoryName,
		item.SubcategoryNameRu,
		item.SubcategoryNameKk,
	); value != "" {
		return value
	}
	slug := strings.ToLower(strings.TrimSpace(*item.SubcategorySlug))
	if names, ok := activitySubcategoryNames[slug]; ok {
		return localizedValue(locale, names)
	}
	return humanizeActivityTaxonomySlug(slug)
}

func localizedActivityTaxonomyName(locale string, name string, nameRu string, _ string) string {
	switch normalizeLocaleOrDefault(locale) {
	case localeRU:
		if value := strings.TrimSpace(nameRu); value != "" {
			return value
		}
	default:
		if value := strings.TrimSpace(name); value != "" {
			return value
		}
	}
	if value := strings.TrimSpace(name); value != "" {
		return value
	}
	return strings.TrimSpace(nameRu)
}

func humanizeActivityTaxonomySlug(slug string) string {
	slug = strings.TrimSpace(slug)
	if slug == "" {
		return ""
	}
	return humanizeCityID(slug)
}

func activityModerationTriggeredAt(item *model.ActivityModerationItem) any {
	if item == nil || item.ModerationTriggeredAt == nil {
		return nil
	}
	return item.ModerationTriggeredAt
}

func stringValue(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}
