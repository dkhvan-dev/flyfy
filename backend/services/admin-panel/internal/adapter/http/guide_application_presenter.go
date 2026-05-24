package http

import (
	"fmt"
	"html/template"
	"strings"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

var guideTypeNames = map[string]map[string]string{
	"INDEPENDENT":    {localeEN: "Independent guide", localeRU: "Независимый гид"},
	"LOCAL_EXPERT":   {localeEN: "Local expert", localeRU: "Локальный эксперт"},
	"OPERATOR_GUIDE": {localeEN: "Operator guide", localeRU: "Гид оператора"},
}

var guideLanguageProficiencyNames = map[string]map[string]string{
	"BASIC":        {localeEN: "basic", localeRU: "базовый"},
	"INTERMEDIATE": {localeEN: "intermediate", localeRU: "средний"},
	"ADVANCED":     {localeEN: "advanced", localeRU: "продвинутый"},
	"NATIVE":       {localeEN: "native", localeRU: "родной"},
}

var guideSpecializationNames = map[string]map[string]string{
	"adventure-sports":   {localeEN: "Adventure & sports", localeRU: "Приключения и спорт"},
	"architecture":       {localeEN: "Architecture", localeRU: "Архитектура"},
	"city-walks":         {localeEN: "Walks & city", localeRU: "Прогулки и город"},
	"culture-art":        {localeEN: "Culture & art", localeRU: "Культура и искусство"},
	"family-kids":        {localeEN: "Family & kids", localeRU: "Семья и дети"},
	"food-drinks":        {localeEN: "Food & drinks", localeRU: "Еда и напитки"},
	"history":            {localeEN: "History", localeRU: "История"},
	"mountain-routes":    {localeEN: "Mountain routes", localeRU: "Горные маршруты"},
	"nature-outdoor":     {localeEN: "Nature & outdoor", localeRU: "Природа и активный отдых"},
	"photo-walk":         {localeEN: "Photo walk", localeRU: "Фотопрогулка"},
	"workshops-learning": {localeEN: "Workshops & learning", localeRU: "Мастер-классы и обучение"},
}

var guideDocumentTypeNames = map[string]map[string]string{
	"IDENTITY_DOCUMENT":                {localeEN: "Identity document", localeRU: "Удостоверение личности"},
	"PASSPORT":                         {localeEN: "Passport", localeRU: "Паспорт"},
	"PROFESSIONAL_CERTIFICATE":         {localeEN: "Professional certificate", localeRU: "Профессиональный сертификат"},
	"PROFESSIONAL_DOCUMENT":            {localeEN: "Professional document", localeRU: "Профессиональный документ"},
	"PROFESSIONAL_LICENSE":             {localeEN: "Professional license", localeRU: "Профессиональная лицензия"},
	"FIRST_AID_CERTIFICATE":            {localeEN: "First aid certificate", localeRU: "Сертификат первой помощи"},
	"LANGUAGE_PROFICIENCY_CERTIFICATE": {localeEN: "Language certificate", localeRU: "Сертификат языка"},
}

func guideApplicationPrimaryText(item *model.GuideApplicationModerationItem) string {
	if item == nil {
		return "-"
	}
	if value := strings.TrimSpace(item.GuideDisplayName); value != "" {
		return value
	}
	if value := guideApplicationFullNameText(item); value != "" {
		return value
	}
	return "-"
}

func guideApplicationFullNameText(item *model.GuideApplicationModerationItem) string {
	if item == nil {
		return ""
	}
	firstName := strings.TrimSpace(item.FirstName)
	lastName := strings.TrimSpace(item.LastName)
	switch {
	case firstName != "" && lastName != "":
		return lastName + " " + firstName
	case firstName != "":
		return firstName
	case lastName != "":
		return lastName
	default:
		return ""
	}
}

func guideApplicationTypeText(locale string, item *model.GuideApplicationModerationItem) string {
	if item == nil {
		return "-"
	}
	raw := strings.ToUpper(strings.TrimSpace(item.Type))
	if raw == "" {
		return "-"
	}
	if names, ok := guideTypeNames[raw]; ok {
		return localizedValue(locale, names)
	}
	return humanizeCityID(strings.ToLower(raw))
}

func guideApplicationLocationText(locale string, item *model.GuideApplicationModerationItem) string {
	if item == nil {
		return "-"
	}
	parts := make([]string, 0, 2)
	if cityID := strings.TrimSpace(item.BaseCityID); cityID != "" && !isUUIDString(cityID) {
		parts = append(parts, displayReferenceCityName(locale, cityID))
	} else if city := displayCityName(locale, item.BaseCityName); city != "" {
		parts = append(parts, city)
	}
	country := displayCountryName(locale, item.CountryCode)
	if country == "" {
		country = displayCountryNameFromValue(locale, item.BaseCityName)
	}
	if country != "" && !containsLocalizedPart(parts, country) {
		parts = append(parts, country)
	}
	if len(parts) == 0 {
		return "-"
	}
	return strings.Join(parts, ", ")
}

func isUUIDString(value string) bool {
	value = strings.TrimSpace(value)
	if len(value) != 36 {
		return false
	}
	for i, r := range value {
		switch i {
		case 8, 13, 18, 23:
			if r != '-' {
				return false
			}
		default:
			if (r < '0' || r > '9') && (r < 'a' || r > 'f') && (r < 'A' || r > 'F') {
				return false
			}
		}
	}
	return true
}

func displayCountryNameFromValue(locale string, value string) string {
	_, after, ok := strings.Cut(strings.TrimSpace(value), ",")
	if !ok {
		return ""
	}
	country := strings.ToLower(strings.TrimSpace(after))
	if country == "" {
		return ""
	}
	for _, names := range countryNames {
		for _, name := range names {
			if strings.EqualFold(strings.TrimSpace(name), country) {
				return localizedValue(locale, names)
			}
		}
	}
	return strings.TrimSpace(after)
}

func containsLocalizedPart(parts []string, value string) bool {
	normalized := strings.ToLower(strings.TrimSpace(value))
	if normalized == "" {
		return false
	}
	for _, part := range parts {
		if strings.EqualFold(strings.TrimSpace(part), normalized) {
			return true
		}
	}
	return false
}

func guideApplicationExperienceText(locale string, item *model.GuideApplicationModerationItem) string {
	if item == nil || item.ExperienceYears <= 0 {
		return "-"
	}
	if normalizeLocaleOrDefault(locale) == localeRU {
		return fmt.Sprintf("%d лет опыта", item.ExperienceYears)
	}
	if item.ExperienceYears == 1 {
		return "1 year of experience"
	}
	return fmt.Sprintf("%d years of experience", item.ExperienceYears)
}

func guideApplicationRatingText(locale string, item *model.GuideApplicationModerationItem) string {
	if item == nil || item.ReviewsCount <= 0 {
		return translate(locale, "guide.rating.noReviews")
	}
	if normalizeLocaleOrDefault(locale) == localeRU {
		return fmt.Sprintf("%.1f · %s", item.RatingAvg, russianReviewCountText(item.ReviewsCount))
	}
	if item.ReviewsCount == 1 {
		return fmt.Sprintf("%.1f · 1 review", item.RatingAvg)
	}
	return fmt.Sprintf("%.1f · %d reviews", item.RatingAvg, item.ReviewsCount)
}

func russianReviewCountText(count int) string {
	mod10 := count % 10
	mod100 := count % 100
	switch {
	case mod10 == 1 && mod100 != 11:
		return fmt.Sprintf("%d отзыв", count)
	case mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14):
		return fmt.Sprintf("%d отзыва", count)
	default:
		return fmt.Sprintf("%d отзывов", count)
	}
}

func guideApplicationLanguageList(locale string, item *model.GuideApplicationModerationItem) []string {
	if item == nil {
		return nil
	}
	values := make([]string, 0, len(item.Languages))
	seen := make(map[string]struct{}, len(item.Languages))
	for _, language := range item.Languages {
		code := strings.ToLower(strings.TrimSpace(language.LanguageCode))
		if code == "" {
			continue
		}
		proficiency := strings.ToUpper(strings.TrimSpace(language.ProficiencyLevel))
		key := code + ":" + proficiency
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		name := localizedValue(locale, languageNames[code])
		if name == "" {
			name = strings.ToUpper(code)
		}
		level := localizedValue(locale, guideLanguageProficiencyNames[proficiency])
		if level == "" {
			level = humanizeCityID(strings.ToLower(proficiency))
		}
		if level != "" {
			values = append(values, name+" - "+level)
		} else {
			values = append(values, name)
		}
	}
	return values
}

func guideApplicationSpecializationList(locale string, item *model.GuideApplicationModerationItem) []string {
	if item == nil {
		return nil
	}
	values := make([]string, 0, len(item.Specializations))
	seen := make(map[string]struct{}, len(item.Specializations))
	for _, raw := range item.Specializations {
		code := strings.ToLower(strings.TrimSpace(raw))
		if code == "" {
			continue
		}
		if _, exists := seen[code]; exists {
			continue
		}
		seen[code] = struct{}{}
		if names, ok := guideSpecializationNames[code]; ok {
			values = append(values, localizedValue(locale, names))
			continue
		}
		values = append(values, humanizeCityID(code))
	}
	return values
}

func guideApplicationDocumentTypeText(locale string, documentType string) string {
	raw := strings.ToUpper(strings.TrimSpace(documentType))
	if raw == "" {
		return "-"
	}
	if names, ok := guideDocumentTypeNames[raw]; ok {
		return localizedValue(locale, names)
	}
	return humanizeCityID(strings.ToLower(raw))
}

func guideApplicationDocumentURL(caseID any, document model.GuideApplicationDocument) template.URL {
	caseUUID := uuidFromTemplateValue(caseID)
	if caseUUID == uuid.Nil || document.ID == uuid.Nil {
		return ""
	}
	return template.URL("/admin/moderation/guides/" + caseUUID.String() + "/documents/" + document.ID.String())
}

func guideApplicationServiceList(locale string, item *model.GuideApplicationModerationItem) []string {
	if item == nil {
		return nil
	}
	values := make([]string, 0, 3)
	if item.IsPrivateGuideAvailable {
		values = append(values, translate(locale, "guide.service.private"))
	}
	if item.IsExcursionGuideAvailable {
		values = append(values, translate(locale, "guide.service.excursion"))
	}
	if item.IsActivityHostAvailable {
		values = append(values, translate(locale, "guide.service.activity"))
	}
	return values
}

func guideApplicationDecisionLocked(item *model.GuideApplicationModerationItem) bool {
	if item == nil {
		return false
	}
	if guideApplicationCanRevoke(item) {
		return false
	}
	status := strings.ToUpper(strings.TrimSpace(item.Status))
	guideStatus := strings.ToUpper(strings.TrimSpace(item.GuideStatus))
	return status == "APPROVED" ||
		status == "REJECTED" ||
		status == "REVOKED" ||
		guideStatus == "ACTIVE" ||
		guideStatus == "REJECTED" ||
		guideStatus == "SUSPENDED" ||
		guideStatus == "REVOKED"
}

func guideApplicationCanRevoke(item *model.GuideApplicationModerationItem) bool {
	if item == nil {
		return false
	}
	status := strings.ToUpper(strings.TrimSpace(item.Status))
	guideStatus := strings.ToUpper(strings.TrimSpace(item.GuideStatus))
	return status == "APPROVED" && guideStatus == "ACTIVE"
}

type moderationReasonOption struct {
	Code  string
	Label string
}

func moderationReasonCodeOptions(locale string) []moderationReasonOption {
	codes := []string{
		"policy_violation",
		"unsafe_behavior",
		"fraud_or_misrepresentation",
		"document_or_identity_issue",
		"spam_or_abuse",
		"off_platform_contact",
		"quality_standards",
	}
	out := make([]moderationReasonOption, 0, len(codes))
	for _, code := range codes {
		out = append(out, moderationReasonOption{
			Code:  code,
			Label: translate(locale, "reason."+code),
		})
	}
	return out
}

func uuidFromTemplateValue(value any) uuid.UUID {
	switch typed := value.(type) {
	case uuid.UUID:
		return typed
	case *uuid.UUID:
		if typed == nil {
			return uuid.Nil
		}
		return *typed
	case string:
		parsed, err := uuid.Parse(strings.TrimSpace(typed))
		if err != nil {
			return uuid.Nil
		}
		return parsed
	default:
		return uuid.Nil
	}
}
