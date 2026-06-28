package http

import (
	"net/http"
	"net/url"
	"strings"
	"unicode"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

const popularHelpArticleTag = "popular"

type helpArticleQuestionTemplate struct {
	Value      string
	CategoryID string
	Tags       []string
}

var helpArticleQuestionTemplates = []helpArticleQuestionTemplate{
	{Value: "support_request", CategoryID: "account", Tags: []string{"account", "support"}},
	{Value: "payments", CategoryID: "payments", Tags: []string{"payments", "refunds"}},
	{Value: "activities", CategoryID: "activities", Tags: []string{"activities"}},
	{Value: "excursions", CategoryID: "excursions", Tags: []string{"excursions", "guides"}},
	{Value: "places", CategoryID: "places", Tags: []string{"places"}},
	{Value: "currency", CategoryID: "currency", Tags: []string{"currency"}},
}

func (s *Server) HelpArticleList(w http.ResponseWriter, r *http.Request) {
	filter, viewFilter := parseHelpArticleFilter(r)
	staff := staffFromContext(r.Context())
	locale := localeFromContext(r.Context())
	data := NewHelpArticleListViewData(nil, nil, viewFilter, staff, locale)
	if s.support == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "help_articles/index", "help.title", "help_content", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	items, err := s.support.ListHelpArticles(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "help_articles/index", "help.title", "help_content", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	categories, err := s.support.ListHelpCategories(r.Context(), staff, model.HelpCategoryFilter{Locale: locale, Limit: 500})
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "help_articles/index", "help.title", "help_content", NewHelpArticleListViewData(items, nil, viewFilter, staff, locale), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "help_articles/index", "help.title", "help_content", NewHelpArticleListViewData(items, categories, viewFilter, staff, locale), "")
}

func (s *Server) HelpCategoryList(w http.ResponseWriter, r *http.Request) {
	filter, viewFilter := parseHelpCategoryFilter(r)
	input := HelpCategoryFormInput{Status: string(model.HelpArticleStatusPublished)}
	data := NewHelpCategoryListViewData(nil, viewFilter, input, staffFromContext(r.Context()))
	if s.support == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "help_categories/index", "help.categoriesTitle", "help_categories", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	items, err := s.support.ListHelpCategories(r.Context(), staffFromContext(r.Context()), filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "help_categories/index", "help.categoriesTitle", "help_categories", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "help_categories/index", "help.categoriesTitle", "help_categories", NewHelpCategoryListViewData(items, viewFilter, input, staffFromContext(r.Context())), "")
}

func (s *Server) SaveHelpCategory(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		s.renderHelpCategoryListError(w, r, app.ErrInvalidInput)
		return
	}
	if s.support == nil {
		s.renderHelpCategoryListError(w, r, app.ErrIntegrationNotReady)
		return
	}
	input := parseHelpCategoryUpsertInput(r)
	if _, err := s.support.UpsertHelpCategory(r.Context(), staffFromContext(r.Context()), input, requestMetadata(r)); err != nil {
		s.renderHelpCategoryListError(w, r, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash("/admin/help/categories", "help.categorySaved"), http.StatusSeeOther)
}

func (s *Server) HelpAnalyticsDashboard(w http.ResponseWriter, r *http.Request) {
	data := NewHelpAnalyticsDashboardViewData(model.HelpAnalyticsSummary{})
	if s.support == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "help_analytics/index", "help.analyticsTitle", "help_analytics", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	summary, err := s.support.GetHelpAnalytics(r.Context(), staffFromContext(r.Context()), parsePositiveInt(r.URL.Query().Get("limit"), 10))
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "help_analytics/index", "help.analyticsTitle", "help_analytics", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "help_analytics/index", "help.analyticsTitle", "help_analytics", NewHelpAnalyticsDashboardViewData(summary), "")
}

func (s *Server) renderHelpCategoryListError(w http.ResponseWriter, r *http.Request, err error) {
	filter, viewFilter := parseHelpCategoryFilter(r)
	input := parseHelpCategoryFormInput(r)
	var items []model.HelpCategory
	if s.support != nil {
		loaded, loadErr := s.support.ListHelpCategories(r.Context(), staffFromContext(r.Context()), filter)
		if loadErr == nil {
			items = loaded
		}
	}
	data := NewHelpCategoryListViewData(items, viewFilter, input, staffFromContext(r.Context()))
	s.renderPage(w, errorStatus(err), r, "help_categories/index", "help.categoriesTitle", "help_categories", data, publicError(localeFromContext(r.Context()), err))
}

func (s *Server) NewHelpArticlePage(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	data := NewHelpArticleFormViewData(model.HelpArticleDetail{}, false, staff)
	if !staffCanHelpContentEdit(staff) {
		s.renderPage(w, http.StatusForbidden, r, "help_articles/form", "help.createTitle", "help_content", data, publicError(localeFromContext(r.Context()), app.ErrPermissionDenied))
		return
	}
	s.renderPage(w, http.StatusOK, r, "help_articles/form", "help.createTitle", "help_content", data, "")
}

func (s *Server) EditHelpArticlePage(w http.ResponseWriter, r *http.Request) {
	articleID := helpArticleIDFromRequest(r)
	if s.support == nil {
		data := NewHelpArticleFormViewData(model.HelpArticleDetail{Article: model.HelpArticle{ID: articleID}}, true, staffFromContext(r.Context()))
		s.renderPage(w, http.StatusServiceUnavailable, r, "help_articles/form", "help.editTitle", "help_content", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	detail, err := s.support.GetHelpArticle(r.Context(), staffFromContext(r.Context()), articleID)
	if err != nil {
		data := NewHelpArticleFormViewData(model.HelpArticleDetail{Article: model.HelpArticle{ID: articleID}}, true, staffFromContext(r.Context()))
		s.renderPage(w, errorStatus(err), r, "help_articles/form", "help.editTitle", "help_content", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "help_articles/form", "help.editTitle", "help_content", NewHelpArticleFormViewData(detail, true, staffFromContext(r.Context())), "")
}

func (s *Server) CreateHelpArticle(w http.ResponseWriter, r *http.Request) {
	s.saveHelpArticle(w, r, "")
}

func (s *Server) SaveHelpArticle(w http.ResponseWriter, r *http.Request) {
	s.saveHelpArticle(w, r, helpArticleIDFromRequest(r))
}

func (s *Server) saveHelpArticle(w http.ResponseWriter, r *http.Request, articleID string) {
	if err := r.ParseForm(); err != nil {
		s.renderHelpArticleFormError(w, r, articleID, app.ErrInvalidInput)
		return
	}
	if s.support == nil {
		s.renderHelpArticleFormError(w, r, articleID, app.ErrIntegrationNotReady)
		return
	}
	input := parseHelpArticleUpsertInput(r, articleID)
	article, err := s.support.UpsertHelpArticle(r.Context(), staffFromContext(r.Context()), input, requestMetadata(r))
	if err != nil {
		s.renderHelpArticleFormError(w, r, input.ArticleID, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(helpArticleEditURL(article.ID, ""), "help.articleSaved"), http.StatusSeeOther)
}

func (s *Server) SubmitHelpArticleForReview(w http.ResponseWriter, r *http.Request) {
	s.helpArticleWorkflowAction(w, r, "submit_review")
}

func (s *Server) PublishHelpArticle(w http.ResponseWriter, r *http.Request) {
	s.helpArticleWorkflowAction(w, r, "publish")
}

func (s *Server) ArchiveHelpArticle(w http.ResponseWriter, r *http.Request) {
	s.helpArticleWorkflowAction(w, r, "archive")
}

func (s *Server) helpArticleWorkflowAction(w http.ResponseWriter, r *http.Request, action string) {
	articleID := helpArticleIDFromRequest(r)
	if s.support == nil {
		s.renderHelpArticleFormError(w, r, articleID, app.ErrIntegrationNotReady)
		return
	}
	var err error
	switch action {
	case "submit_review":
		_, err = s.support.SubmitHelpArticleForReview(r.Context(), staffFromContext(r.Context()), articleID, requestMetadata(r))
	case "publish":
		_, err = s.support.PublishHelpArticle(r.Context(), staffFromContext(r.Context()), articleID, requestMetadata(r))
	case "archive":
		_, err = s.support.ArchiveHelpArticle(r.Context(), staffFromContext(r.Context()), articleID, requestMetadata(r))
	default:
		err = app.ErrInvalidInput
	}
	if err != nil {
		s.renderHelpArticleFormError(w, r, articleID, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(helpArticleEditURL(articleID, ""), "help.article"+helpArticleFlashActionSuffix(action)), http.StatusSeeOther)
}

func (s *Server) renderHelpArticleFormError(w http.ResponseWriter, r *http.Request, articleID string, err error) {
	input := parseHelpArticleFormInput(r, articleID)
	data := NewHelpArticleFormViewData(model.HelpArticleDetail{Article: helpArticleFromFormInput(input)}, strings.TrimSpace(articleID) != "", staffFromContext(r.Context()))
	s.renderPage(w, errorStatus(err), r, "help_articles/form", "help.editTitle", "help_content", data, publicError(localeFromContext(r.Context()), err))
}

func parseHelpArticleFilter(r *http.Request) (model.HelpArticleFilter, HelpArticleFilterViewData) {
	query := r.URL.Query()
	status := strings.TrimSpace(query.Get("status"))
	if status == "" {
		status = "all"
	}
	filter := model.HelpArticleFilter{
		Status: model.HelpArticleStatus(status),
		Limit:  parsePositiveInt(query.Get("limit"), 100),
		Offset: parsePositiveInt(query.Get("offset"), 0),
	}
	if status == "all" {
		filter.Status = ""
	}
	return filter, HelpArticleFilterViewData{
		Status: status,
		Query:  helpArticleFilterQuery(status),
	}
}

func parseHelpCategoryFilter(r *http.Request) (model.HelpCategoryFilter, HelpCategoryFilterViewData) {
	query := r.URL.Query()
	status := strings.TrimSpace(query.Get("status"))
	if status == "" {
		status = "all"
	}
	filter := model.HelpCategoryFilter{
		Status: model.HelpArticleStatus(status),
		Limit:  parsePositiveInt(query.Get("limit"), 100),
		Offset: parsePositiveInt(query.Get("offset"), 0),
	}
	if status == "all" {
		filter.Status = ""
	}
	return filter, HelpCategoryFilterViewData{
		Status: status,
		Query:  helpCategoryFilterQuery(status),
	}
}

func helpCategoryFilterQuery(status string) string {
	values := url.Values{}
	if strings.TrimSpace(status) != "" {
		values.Set("status", strings.TrimSpace(status))
	}
	return values.Encode()
}

func helpArticleFilterQuery(status string) string {
	values := url.Values{}
	if strings.TrimSpace(status) != "" {
		values.Set("status", strings.TrimSpace(status))
	}
	return values.Encode()
}

func parseHelpCategoryUpsertInput(r *http.Request) model.HelpCategoryUpsertInput {
	input := parseHelpCategoryFormInput(r)
	return model.HelpCategoryUpsertInput{
		CategoryID: strings.TrimSpace(input.CategoryID),
		Slug:       strings.TrimSpace(input.Slug),
		Status:     model.HelpArticleStatus(input.Status),
		SortOrder:  input.SortOrder,
	}
}

func parseHelpCategoryFormInput(r *http.Request) HelpCategoryFormInput {
	status := strings.TrimSpace(r.Form.Get("status"))
	if status == "" {
		status = string(model.HelpArticleStatusPublished)
	}
	return HelpCategoryFormInput{
		CategoryID: strings.TrimSpace(r.Form.Get("category_id")),
		Slug:       strings.TrimSpace(r.Form.Get("slug")),
		Status:     status,
		SortOrder:  parsePositiveInt(r.Form.Get("sort_order"), 0),
	}
}

func parseHelpArticleUpsertInput(r *http.Request, articleID string) model.HelpArticleUpsertInput {
	input := parseHelpArticleFormInput(r, articleID)
	return model.HelpArticleUpsertInput{
		ArticleID:         input.ArticleID,
		Slug:              input.Slug,
		CategoryID:        input.CategoryID,
		Status:            model.HelpArticleStatus(input.Status),
		Tags:              splitCSV(input.Tags),
		Surfaces:          input.Surfaces,
		Visibility:        model.HelpArticleVisibility{UserStates: splitCSV(input.VisibilityUserStates), PaymentStatuses: splitCSV(input.VisibilityPaymentStatuses)},
		Translations:      helpArticleTranslationsFromInput(input),
		Actions:           helpArticleActionsFromInput(input),
		RelatedArticleIDs: splitCSV(input.RelatedArticleIDs),
	}
}

func parseHelpArticleFormInput(r *http.Request, articleID string) HelpArticleFormInput {
	en := parseHelpArticleLocaleInput(r, "en")
	ru := parseHelpArticleLocaleInput(r, "ru")
	kk := parseHelpArticleLocaleInput(r, "kk")
	slug := strings.TrimSpace(r.Form.Get("slug"))
	if slug == "" {
		slug = helpArticleSlugFromTitle(en.Title)
	}
	if strings.TrimSpace(articleID) == "" {
		articleID = slug
	}
	status := strings.TrimSpace(r.Form.Get("status"))
	if status == "" {
		status = string(model.HelpArticleStatusDraft)
	}
	input := HelpArticleFormInput{
		ArticleID:                 strings.TrimSpace(articleID),
		Slug:                      slug,
		CategoryID:                strings.TrimSpace(r.Form.Get("category_id")),
		Status:                    status,
		Tags:                      strings.TrimSpace(r.Form.Get("tags")),
		Surfaces:                  uniqueStrings(r.Form["surfaces"]),
		QuestionTemplate:          strings.TrimSpace(r.Form.Get("question_template")),
		IsPopular:                 checkboxEnabled(r.Form.Get("is_popular")),
		VisibilityUserStates:      strings.TrimSpace(r.Form.Get("visibility_user_states")),
		VisibilityPaymentStatuses: strings.TrimSpace(r.Form.Get("visibility_payment_statuses")),
		RelatedArticleIDs:         strings.TrimSpace(r.Form.Get("related_article_ids")),
		ActionType:                strings.TrimSpace(r.Form.Get("action_type")),
		ActionTarget:              strings.TrimSpace(r.Form.Get("action_target")),
		ActionLabel:               strings.TrimSpace(r.Form.Get("action_label")),
		EN:                        en,
		RU:                        ru,
		KK:                        kk,
	}
	return applyHelpArticleFormDefaults(input)
}

func parseHelpArticleLocaleInput(r *http.Request, locale string) HelpArticleLocaleInput {
	return HelpArticleLocaleInput{
		Title:       strings.TrimSpace(r.Form.Get("title_" + locale)),
		ShortAnswer: strings.TrimSpace(r.Form.Get("short_answer_" + locale)),
		Body:        strings.TrimSpace(r.Form.Get("body_" + locale)),
	}
}

func helpArticleTranslationsFromInput(input HelpArticleFormInput) map[string]model.HelpArticleTranslation {
	return map[string]model.HelpArticleTranslation{
		"en": {Title: input.EN.Title, ShortAnswer: input.EN.ShortAnswer, Body: input.EN.Body},
		"ru": {Title: input.RU.Title, ShortAnswer: input.RU.ShortAnswer, Body: input.RU.Body},
		"kk": {Title: input.KK.Title, ShortAnswer: input.KK.ShortAnswer, Body: input.KK.Body},
	}
}

func helpArticleActionsFromInput(input HelpArticleFormInput) []model.HelpArticleAction {
	if input.ActionType == "" && input.ActionTarget == "" && input.ActionLabel == "" {
		return nil
	}
	return []model.HelpArticleAction{{
		Type:   input.ActionType,
		Target: input.ActionTarget,
		Label:  input.ActionLabel,
	}}
}

func helpArticleFromFormInput(input HelpArticleFormInput) model.HelpArticle {
	return model.HelpArticle{
		ID:                input.ArticleID,
		Slug:              input.Slug,
		CategoryID:        input.CategoryID,
		Status:            model.HelpArticleStatus(input.Status),
		Tags:              splitCSV(input.Tags),
		Surfaces:          append([]string(nil), input.Surfaces...),
		Visibility:        model.HelpArticleVisibility{UserStates: splitCSV(input.VisibilityUserStates), PaymentStatuses: splitCSV(input.VisibilityPaymentStatuses)},
		Translations:      helpArticleTranslationsFromInput(input),
		Actions:           helpArticleActionsFromInput(input),
		RelatedArticleIDs: splitCSV(input.RelatedArticleIDs),
	}
}

func helpArticleIDFromRequest(r *http.Request) string {
	articleID := strings.TrimSpace(r.PathValue("articleID"))
	if articleID != "" {
		return articleID
	}
	path := strings.Trim(strings.TrimSpace(r.URL.Path), "/")
	parts := strings.Split(path, "/")
	for index, part := range parts {
		if part == "articles" && index+1 < len(parts) {
			next := strings.TrimSpace(parts[index+1])
			if next != "" && next != "new" {
				return next
			}
		}
	}
	return ""
}

func applyHelpArticleFormDefaults(input HelpArticleFormInput) HelpArticleFormInput {
	if template, ok := helpArticleQuestionTemplateByValue(input.QuestionTemplate); ok {
		if strings.TrimSpace(input.CategoryID) == "" {
			input.CategoryID = template.CategoryID
		}
		input.Tags = mergeCSVValues(input.Tags, template.Tags...)
	}
	if input.IsPopular {
		input.Tags = mergeCSVValues(input.Tags, popularHelpArticleTag)
		input.Surfaces = appendUniqueString(input.Surfaces, "help_center")
	}
	return input
}

func helpArticleQuestionTemplateByValue(value string) (helpArticleQuestionTemplate, bool) {
	value = strings.TrimSpace(value)
	if value == "" {
		return helpArticleQuestionTemplate{}, false
	}
	for _, template := range helpArticleQuestionTemplates {
		if template.Value == value {
			return template, true
		}
	}
	return helpArticleQuestionTemplate{}, false
}

func helpArticleHasTag(tags []string, target string) bool {
	target = strings.ToLower(strings.TrimSpace(target))
	for _, tag := range tags {
		if strings.ToLower(strings.TrimSpace(tag)) == target {
			return true
		}
	}
	return false
}

func helpArticleSlugFromTitle(title string) string {
	title = strings.ToLower(strings.TrimSpace(title))
	if title == "" {
		return ""
	}
	var builder strings.Builder
	lastDash := false
	for _, item := range title {
		if unicode.IsLetter(item) || unicode.IsDigit(item) {
			builder.WriteRune(item)
			lastDash = false
			continue
		}
		if !lastDash && builder.Len() > 0 {
			builder.WriteByte('-')
			lastDash = true
		}
	}
	return strings.Trim(builder.String(), "-")
}

func checkboxEnabled(value string) bool {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "1", "true", "on", "yes":
		return true
	default:
		return false
	}
}

func mergeCSVValues(csv string, values ...string) string {
	items := splitCSV(csv)
	items = append(items, values...)
	return strings.Join(uniqueStrings(items), ", ")
}

func uniqueStrings(values []string) []string {
	out := make([]string, 0, len(values))
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		key := strings.ToLower(value)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, value)
	}
	return out
}

func appendUniqueString(values []string, value string) []string {
	return uniqueStrings(append(append([]string(nil), values...), value))
}

func helpArticleSaveURL(articleID string) string {
	articleID = strings.TrimSpace(articleID)
	if articleID == "" {
		return "/admin/help/articles"
	}
	return "/admin/help/articles/" + url.PathEscape(articleID)
}

func helpArticleEditURL(articleID string, query string) string {
	path := "/admin/help/articles/" + url.PathEscape(strings.TrimSpace(articleID)) + "/edit"
	query = strings.TrimSpace(query)
	if query == "" {
		return path
	}
	return path + "?" + query
}

func helpArticleFlashActionSuffix(action string) string {
	switch action {
	case "submit_review":
		return "Submitted"
	case "publish":
		return "Published"
	case "archive":
		return "Archived"
	default:
		return "Saved"
	}
}
