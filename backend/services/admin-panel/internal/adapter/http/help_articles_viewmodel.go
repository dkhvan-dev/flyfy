package http

import (
	"strings"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type HelpArticleListViewData struct {
	Items         []HelpArticleRowView
	Filters       HelpArticleFilterViewData
	StatusOptions []SupportOptionView
	FilterAction  string
	ResetURL      string
	CreateURL     string
	CanEdit       bool
	CanPublish    bool
}

type HelpCategoryListViewData struct {
	Items             []HelpCategoryRowView
	Filters           HelpCategoryFilterViewData
	Input             HelpCategoryFormInput
	StatusOptions     []SupportOptionView
	FormStatusOptions []SupportOptionView
	FilterAction      string
	ResetURL          string
	SubmitURL         string
	CanEdit           bool
}

type HelpArticleFilterViewData struct {
	Status string
	Query  string
}

type HelpCategoryFilterViewData struct {
	Status string
	Query  string
}

type HelpArticleRowView struct {
	Item          model.HelpArticle
	Title         string
	ShortAnswer   string
	Category      string
	EditURL       string
	BadgeClass    string
	Tags          string
	Translations  string
	LastUpdatedBy string
}

type HelpCategoryRowView struct {
	Item       model.HelpCategory
	BadgeClass string
}

type HelpArticleFormViewData struct {
	IsEdit                  bool
	Input                   HelpArticleFormInput
	ListURL                 string
	SubmitURL               string
	StatusOptions           []SupportOptionView
	SurfaceOptions          []SupportOptionView
	QuestionTemplateOptions []SupportOptionView
	Events                  []HelpArticleEventView
	CanEdit                 bool
	CanPublish              bool
}

type HelpCategoryFormInput struct {
	CategoryID string
	Slug       string
	Status     string
	SortOrder  int
}

type HelpArticleFormInput struct {
	ArticleID                 string
	Slug                      string
	CategoryID                string
	Status                    string
	Tags                      string
	Surfaces                  []string
	QuestionTemplate          string
	IsPopular                 bool
	VisibilityUserStates      string
	VisibilityPaymentStatuses string
	RelatedArticleIDs         string
	ActionType                string
	ActionTarget              string
	ActionLabel               string
	EN                        HelpArticleLocaleInput
	RU                        HelpArticleLocaleInput
	KK                        HelpArticleLocaleInput
}

type HelpArticleLocaleInput struct {
	Title       string
	ShortAnswer string
	Body        string
}

type HelpArticleEventView struct {
	Item    model.HelpArticleEvent
	Payload []SupportKeyValueView
}

func NewHelpCategoryListViewData(items []model.HelpCategory, filters HelpCategoryFilterViewData, input HelpCategoryFormInput, staff *model.StaffUser) HelpCategoryListViewData {
	rows := make([]HelpCategoryRowView, 0, len(items))
	for _, item := range items {
		rows = append(rows, HelpCategoryRowView{
			Item:       item,
			BadgeClass: statusBadgeClass(string(item.Status)),
		})
	}
	if strings.TrimSpace(input.Status) == "" {
		input.Status = string(model.HelpArticleStatusPublished)
	}
	return HelpCategoryListViewData{
		Items:             rows,
		Filters:           filters,
		Input:             input,
		StatusOptions:     helpArticleStatusOptions(filters.Status),
		FormStatusOptions: helpCategoryFormStatusOptions(input.Status),
		FilterAction:      "/admin/help/categories",
		ResetURL:          "/admin/help/categories",
		SubmitURL:         "/admin/help/categories",
		CanEdit:           staffCanHelpContentEdit(staff),
	}
}

func NewHelpArticleListViewData(items []model.HelpArticle, categories []model.HelpCategory, filters HelpArticleFilterViewData, staff *model.StaffUser, locale string) HelpArticleListViewData {
	categoryTitles := helpCategoryTitleLookup(categories)
	rows := make([]HelpArticleRowView, 0, len(items))
	for _, item := range items {
		rows = append(rows, HelpArticleRowView{
			Item:         item,
			Title:        helpArticleTitle(item, locale),
			ShortAnswer:  helpArticleShortAnswer(item, locale),
			Category:     helpArticleCategoryLabel(item.CategoryID, categoryTitles),
			EditURL:      helpArticleEditURL(item.ID, filters.Query),
			BadgeClass:   statusBadgeClass(string(item.Status)),
			Tags:         strings.Join(item.Tags, ", "),
			Translations: helpArticleLocales(item.Translations),
		})
	}
	return HelpArticleListViewData{
		Items:         rows,
		Filters:       filters,
		StatusOptions: helpArticleStatusOptions(filters.Status),
		FilterAction:  "/admin/help/articles",
		ResetURL:      "/admin/help/articles",
		CreateURL:     "/admin/help/articles/new",
		CanEdit:       staffCanHelpContentEdit(staff),
		CanPublish:    staffCanHelpContentPublish(staff),
	}
}

func NewHelpArticleFormViewData(detail model.HelpArticleDetail, isEdit bool, staff *model.StaffUser) HelpArticleFormViewData {
	input := NewHelpArticleFormInput(detail.Article)
	listURL := "/admin/help/articles"
	submitURL := "/admin/help/articles"
	if isEdit {
		submitURL = helpArticleSaveURL(detail.Article.ID)
	}
	events := make([]HelpArticleEventView, 0, len(detail.Events))
	for _, event := range detail.Events {
		events = append(events, HelpArticleEventView{
			Item:    event,
			Payload: supportKeyValues(event.Payload),
		})
	}
	return HelpArticleFormViewData{
		IsEdit:                  isEdit,
		Input:                   input,
		ListURL:                 listURL,
		SubmitURL:               submitURL,
		StatusOptions:           helpArticleStatusOptions(input.Status),
		SurfaceOptions:          helpArticleSurfaceOptions(input.Surfaces),
		QuestionTemplateOptions: helpArticleQuestionTemplateOptions(input.QuestionTemplate),
		Events:                  events,
		CanEdit:                 staffCanHelpContentEdit(staff),
		CanPublish:              staffCanHelpContentPublish(staff),
	}
}

func NewHelpArticleFormInput(article model.HelpArticle) HelpArticleFormInput {
	status := string(article.Status)
	if status == "" {
		status = string(model.HelpArticleStatusDraft)
	}
	action := model.HelpArticleAction{}
	if len(article.Actions) > 0 {
		action = article.Actions[0]
	}
	return HelpArticleFormInput{
		ArticleID:                 article.ID,
		Slug:                      article.Slug,
		CategoryID:                article.CategoryID,
		Status:                    status,
		Tags:                      strings.Join(article.Tags, ", "),
		Surfaces:                  append([]string(nil), article.Surfaces...),
		IsPopular:                 helpArticleHasTag(article.Tags, popularHelpArticleTag),
		VisibilityUserStates:      strings.Join(article.Visibility.UserStates, ", "),
		VisibilityPaymentStatuses: strings.Join(article.Visibility.PaymentStatuses, ", "),
		RelatedArticleIDs:         strings.Join(article.RelatedArticleIDs, ", "),
		ActionType:                action.Type,
		ActionTarget:              action.Target,
		ActionLabel:               action.Label,
		EN:                        helpArticleLocaleInput(article.Translations, "en"),
		RU:                        helpArticleLocaleInput(article.Translations, "ru"),
		KK:                        helpArticleLocaleInput(article.Translations, "kk"),
	}
}

func helpArticleStatusOptions(selected string) []SupportOptionView {
	values := []string{"draft", "review", "published", "archived", "all"}
	return supportOptions("help.status.", values, selected)
}

func helpCategoryFormStatusOptions(selected string) []SupportOptionView {
	values := []string{"published", "draft", "review", "archived"}
	return supportOptions("help.status.", values, selected)
}

func helpArticleSurfaceOptions(selected []string) []SupportOptionView {
	values := []string{"help_center", "activity_details", "excursion_details", "place_details", "currency_converter"}
	selectedLookup := map[string]struct{}{}
	for _, value := range selected {
		selectedLookup[strings.TrimSpace(value)] = struct{}{}
	}
	options := make([]SupportOptionView, 0, len(values))
	for _, value := range values {
		_, isSelected := selectedLookup[value]
		options = append(options, SupportOptionView{
			Value:    value,
			LabelKey: "help.surface." + value,
			Selected: isSelected,
		})
	}
	return options
}

func helpArticleQuestionTemplateOptions(selected string) []SupportOptionView {
	values := []string{"", "support_request", "payments", "activities", "excursions", "places", "currency"}
	return supportOptions("help.questionTemplate.", values, selected)
}

func staffCanHelpContentEdit(staff *model.StaffUser) bool {
	return staff != nil && (staff.HasPermission(enum.PermissionHelpContentEdit) || staffCanHelpContentPublish(staff))
}

func staffCanHelpContentPublish(staff *model.StaffUser) bool {
	return staff != nil && staff.HasPermission(enum.PermissionHelpContentPublish)
}

func helpArticleTitle(article model.HelpArticle, preferredLocale string) string {
	for _, locale := range helpArticlePreferredLocales(preferredLocale) {
		if translation, ok := article.Translations[locale]; ok && strings.TrimSpace(translation.Title) != "" {
			return strings.TrimSpace(translation.Title)
		}
	}
	if strings.TrimSpace(article.Slug) != "" {
		return article.Slug
	}
	return article.ID
}

func helpArticleShortAnswer(article model.HelpArticle, preferredLocale string) string {
	for _, locale := range helpArticlePreferredLocales(preferredLocale) {
		if translation, ok := article.Translations[locale]; ok && strings.TrimSpace(translation.ShortAnswer) != "" {
			return strings.TrimSpace(translation.ShortAnswer)
		}
	}
	return "-"
}

func helpArticlePreferredLocales(preferredLocale string) []string {
	out := make([]string, 0, 3)
	seen := make(map[string]struct{}, 3)
	appendLocale := func(locale string) {
		normalized, ok := normalizeLocale(locale)
		if !ok {
			return
		}
		if _, exists := seen[normalized]; exists {
			return
		}
		seen[normalized] = struct{}{}
		out = append(out, normalized)
	}
	appendLocale(preferredLocale)
	appendLocale(localeRU)
	appendLocale(localeEN)
	return out
}

func helpCategoryTitleLookup(categories []model.HelpCategory) map[string]string {
	lookup := make(map[string]string, len(categories))
	for _, category := range categories {
		id := strings.TrimSpace(category.ID)
		title := strings.TrimSpace(category.Title)
		if id == "" || title == "" {
			continue
		}
		lookup[id] = title
	}
	return lookup
}

func helpArticleCategoryLabel(categoryID string, categoryTitles map[string]string) string {
	categoryID = strings.TrimSpace(categoryID)
	if categoryID == "" {
		return "-"
	}
	if title := strings.TrimSpace(categoryTitles[categoryID]); title != "" {
		return title
	}
	return categoryID
}

func helpArticleLocaleInput(translations map[string]model.HelpArticleTranslation, locale string) HelpArticleLocaleInput {
	translation := translations[locale]
	return HelpArticleLocaleInput{
		Title:       translation.Title,
		ShortAnswer: translation.ShortAnswer,
		Body:        translation.Body,
	}
}

func helpArticleLocales(translations map[string]model.HelpArticleTranslation) string {
	locales := make([]string, 0, 3)
	for _, locale := range []string{"en", "ru", "kk"} {
		if translation, ok := translations[locale]; ok && strings.TrimSpace(translation.Title) != "" {
			locales = append(locales, locale)
		}
	}
	if len(locales) == 0 {
		return "-"
	}
	return strings.Join(locales, ", ")
}

func statusBadgeClass(status string) string {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "published":
		return "badge badge-success"
	case "review":
		return "badge badge-warn"
	case "draft":
		return "badge badge-info"
	case "archived":
		return "badge"
	default:
		return "badge"
	}
}
