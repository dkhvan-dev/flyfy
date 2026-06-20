package http

import (
	"net/http"
	"strconv"
	"strings"
	"time"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func (s *Server) OperationsDashboard(w http.ResponseWriter, r *http.Request) {
	filters := parseOperationsDomainFilter(r)
	useCase, err := s.operationsUseCase()
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/index", "operations.title", "operations", NewOperationsDomainListViewData(model.OperationDomainPage{}, filters), publicError(localeFromContext(r.Context()), err))
		return
	}
	page, err := useCase.ListDomains(r.Context(), staffFromContext(r.Context()), app.OperationsDomainListInput{
		Page:   filters.Page,
		Size:   filters.Size,
		Search: filters.Search,
	})
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/index", "operations.title", "operations", NewOperationsDomainListViewData(model.OperationDomainPage{}, filters), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "operations/index", "operations.title", "operations", NewOperationsDomainListViewData(page, filters), "")
}

func (s *Server) OperationDomainDetail(w http.ResponseWriter, r *http.Request) {
	code := r.PathValue("domainCode")
	activeTab := normalizeOperationsTab(r.URL.Query().Get("tab"))
	filters := parseOperationsResourceFilter(r)
	useCase, err := s.operationsUseCase()
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/domain", "operations.domainTitle", "operations", NewOperationsDomainDetailViewData(app.OperationsDomainDetailPage{}, activeTab, filters), publicError(localeFromContext(r.Context()), err))
		return
	}
	page, err := useCase.GetDomainDetail(r.Context(), staffFromContext(r.Context()), code, operationsDomainDetailInput(filters))
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/domain", "operations.domainTitle", "operations", NewOperationsDomainDetailViewData(app.OperationsDomainDetailPage{}, activeTab, filters), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "operations/domain", "operations.domainTitle", "operations", NewOperationsDomainDetailViewData(page, activeTab, filters), "")
}

func (s *Server) UpdateOperationDomain(w http.ResponseWriter, r *http.Request) {
	useCase, err := s.operationsUseCase()
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/domain", "operations.domainTitle", "operations", NewOperationsDomainDetailViewData(app.OperationsDomainDetailPage{}, OperationsTabDomain, OperationsResourceFilterViewData{}), publicError(localeFromContext(r.Context()), err))
		return
	}
	input := model.OperationDomainInput{
		Code:        firstNonEmpty(r.Form.Get("code"), r.PathValue("domainCode")),
		Description: r.Form.Get("description"),
		RequestID:   requestIDFromContext(r.Context()),
	}
	domain, err := useCase.SaveDomain(r.Context(), staffFromContext(r.Context()), input)
	if err != nil {
		page, _ := useCase.GetDomainDetail(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), app.OperationsDomainDetailInput{})
		s.renderPage(w, errorStatus(err), r, "operations/domain", "operations.domainTitle", "operations", NewOperationsDomainDetailViewData(page, OperationsTabDomain, OperationsResourceFilterViewData{}), publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(operationsDomainURL(domain.Code), "operations.domainSaved"), http.StatusSeeOther)
}

func (s *Server) NewOperationFeatureFlagPage(w http.ResponseWriter, r *http.Request) {
	useCase, err := s.operationsUseCase()
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/feature_flag_form", "operations.featureFlagNewTitle", "operations", NewOperationsFeatureFlagFormViewData(app.OperationsFeatureFlagDetailPage{}, true), publicError(localeFromContext(r.Context()), err))
		return
	}
	domainPage, err := useCase.GetDomainDetail(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), app.OperationsDomainDetailInput{})
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/feature_flag_form", "operations.featureFlagNewTitle", "operations", NewOperationsFeatureFlagFormViewData(app.OperationsFeatureFlagDetailPage{}, true), publicError(localeFromContext(r.Context()), err))
		return
	}
	flag := model.OperationFeatureFlag{
		DomainCode:      domainPage.Domain.Code,
		Type:            "TOGGLE",
		ActionStartDate: time.Now().UTC().Truncate(time.Minute),
	}
	data := NewOperationsFeatureFlagFormViewData(app.OperationsFeatureFlagDetailPage{Domain: domainPage.Domain, Flag: flag}, true)
	s.renderPage(w, http.StatusOK, r, "operations/feature_flag_form", "operations.featureFlagNewTitle", "operations", data, "")
}

func (s *Server) CreateOperationFeatureFlag(w http.ResponseWriter, r *http.Request) {
	s.saveOperationFeatureFlag(w, r, true)
}

func (s *Server) OperationFeatureFlagDetail(w http.ResponseWriter, r *http.Request) {
	useCase, err := s.operationsUseCase()
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/feature_flag_form", "operations.featureFlagTitle", "operations", NewOperationsFeatureFlagFormViewData(app.OperationsFeatureFlagDetailPage{}, false), publicError(localeFromContext(r.Context()), err))
		return
	}
	page, err := useCase.GetFeatureFlagDetail(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), r.PathValue("flagCode"))
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/feature_flag_form", "operations.featureFlagTitle", "operations", NewOperationsFeatureFlagFormViewData(app.OperationsFeatureFlagDetailPage{}, false), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "operations/feature_flag_form", "operations.featureFlagTitle", "operations", NewOperationsFeatureFlagFormViewData(page, false), "")
}

func (s *Server) OperationFeatureFlagHistory(w http.ResponseWriter, r *http.Request) {
	filters := parseOperationsHistoryPaginationFilter(r)
	useCase, err := s.operationsUseCase()
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/feature_flag_history", "operations.history", "operations", NewOperationsFeatureFlagHistoryViewData(app.OperationsFeatureFlagDetailPage{}, filters), publicError(localeFromContext(r.Context()), err))
		return
	}
	page, err := useCase.GetFeatureFlagHistory(
		r.Context(),
		staffFromContext(r.Context()),
		r.PathValue("domainCode"),
		r.PathValue("flagCode"),
		model.OperationFeatureFlagHistoryFilter{
			Page:   filters.Page,
			Size:   filters.Size,
			Cursor: filters.Cursor,
		},
	)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/feature_flag_history", "operations.history", "operations", NewOperationsFeatureFlagHistoryViewData(app.OperationsFeatureFlagDetailPage{}, filters), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "operations/feature_flag_history", "operations.history", "operations", NewOperationsFeatureFlagHistoryViewData(page, filters), "")
}

func (s *Server) UpdateOperationFeatureFlag(w http.ResponseWriter, r *http.Request) {
	s.saveOperationFeatureFlag(w, r, false)
}

func (s *Server) ArchiveOperationFeatureFlag(w http.ResponseWriter, r *http.Request) {
	useCase, err := s.operationsUseCase()
	if err == nil {
		err = useCase.ArchiveFeatureFlag(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), r.PathValue("flagCode"), requestIDFromContext(r.Context()))
	}
	if err != nil {
		s.OperationFeatureFlagDetail(w, r)
		return
	}
	http.Redirect(w, r, redirectWithFlash(operationFeatureFlagURL(r.PathValue("domainCode"), r.PathValue("flagCode")), "operations.featureFlagSaved"), http.StatusSeeOther)
}

func (s *Server) RecoverOperationFeatureFlag(w http.ResponseWriter, r *http.Request) {
	useCase, err := s.operationsUseCase()
	if err == nil {
		_, err = useCase.RecoverFeatureFlag(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), r.PathValue("flagCode"), requestIDFromContext(r.Context()))
	}
	if err != nil {
		s.OperationFeatureFlagDetail(w, r)
		return
	}
	http.Redirect(w, r, redirectWithFlash(operationFeatureFlagURL(r.PathValue("domainCode"), r.PathValue("flagCode")), "operations.featureFlagSaved"), http.StatusSeeOther)
}

func (s *Server) NewOperationTechBreakPage(w http.ResponseWriter, r *http.Request) {
	useCase, err := s.operationsUseCase()
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/tech_break_form", "operations.techBreakNewTitle", "operations", NewOperationsTechBreakFormViewData(app.OperationsTechBreakDetailPage{}, true), publicError(localeFromContext(r.Context()), err))
		return
	}
	domainPage, err := useCase.GetDomainDetail(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), app.OperationsDomainDetailInput{})
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/tech_break_form", "operations.techBreakNewTitle", "operations", NewOperationsTechBreakFormViewData(app.OperationsTechBreakDetailPage{}, true), publicError(localeFromContext(r.Context()), err))
		return
	}
	item := model.OperationTechBreak{
		DomainCode:      domainPage.Domain.Code,
		ActionStartDate: time.Now().UTC().Truncate(time.Minute),
	}
	data := NewOperationsTechBreakFormViewData(app.OperationsTechBreakDetailPage{Domain: domainPage.Domain, Break: item, Scopes: domainPage.Scopes}, true)
	s.renderPage(w, http.StatusOK, r, "operations/tech_break_form", "operations.techBreakNewTitle", "operations", data, "")
}

func (s *Server) CreateOperationTechBreak(w http.ResponseWriter, r *http.Request) {
	s.saveOperationTechBreak(w, r, 0)
}

func (s *Server) OperationTechBreakDetail(w http.ResponseWriter, r *http.Request) {
	id, ok := parsePathInt64(w, r, "techBreakID")
	if !ok {
		return
	}
	useCase, err := s.operationsUseCase()
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/tech_break_form", "operations.techBreakTitle", "operations", NewOperationsTechBreakFormViewData(app.OperationsTechBreakDetailPage{}, false), publicError(localeFromContext(r.Context()), err))
		return
	}
	page, err := useCase.GetTechBreakDetail(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), id)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/tech_break_form", "operations.techBreakTitle", "operations", NewOperationsTechBreakFormViewData(app.OperationsTechBreakDetailPage{}, false), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "operations/tech_break_form", "operations.techBreakTitle", "operations", NewOperationsTechBreakFormViewData(page, false), "")
}

func (s *Server) UpdateOperationTechBreak(w http.ResponseWriter, r *http.Request) {
	id, ok := parsePathInt64(w, r, "techBreakID")
	if !ok {
		return
	}
	s.saveOperationTechBreak(w, r, id)
}

func (s *Server) ArchiveOperationTechBreak(w http.ResponseWriter, r *http.Request) {
	id, ok := parsePathInt64(w, r, "techBreakID")
	if !ok {
		return
	}
	useCase, err := s.operationsUseCase()
	if err == nil {
		err = useCase.ArchiveTechBreak(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), id, requestIDFromContext(r.Context()))
	}
	if err != nil {
		s.OperationTechBreakDetail(w, r)
		return
	}
	http.Redirect(w, r, redirectWithFlash(operationsDomainURL(r.PathValue("domainCode"))+"?tab="+OperationsTabTechBreaks, "operations.techBreakSaved"), http.StatusSeeOther)
}

func (s *Server) NewOperationScopePage(w http.ResponseWriter, r *http.Request) {
	useCase, err := s.operationsUseCase()
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/scope_form", "operations.scopeNewTitle", "operations", NewOperationsScopeFormViewData(app.OperationsScopeDetailPage{}, true), publicError(localeFromContext(r.Context()), err))
		return
	}
	domainPage, err := useCase.GetDomainDetail(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), app.OperationsDomainDetailInput{})
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/scope_form", "operations.scopeNewTitle", "operations", NewOperationsScopeFormViewData(app.OperationsScopeDetailPage{}, true), publicError(localeFromContext(r.Context()), err))
		return
	}
	data := NewOperationsScopeFormViewData(app.OperationsScopeDetailPage{Domain: domainPage.Domain, Scope: model.OperationTechBreakScope{DomainCode: domainPage.Domain.Code}}, true)
	s.renderPage(w, http.StatusOK, r, "operations/scope_form", "operations.scopeNewTitle", "operations", data, "")
}

func (s *Server) CreateOperationScope(w http.ResponseWriter, r *http.Request) {
	s.saveOperationScope(w, r, 0)
}

func (s *Server) OperationScopeDetail(w http.ResponseWriter, r *http.Request) {
	id, ok := parsePathInt64(w, r, "scopeID")
	if !ok {
		return
	}
	useCase, err := s.operationsUseCase()
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/scope_form", "operations.scopeTitle", "operations", NewOperationsScopeFormViewData(app.OperationsScopeDetailPage{}, false), publicError(localeFromContext(r.Context()), err))
		return
	}
	page, err := useCase.GetScopeDetail(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), id)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "operations/scope_form", "operations.scopeTitle", "operations", NewOperationsScopeFormViewData(app.OperationsScopeDetailPage{}, false), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "operations/scope_form", "operations.scopeTitle", "operations", NewOperationsScopeFormViewData(page, false), "")
}

func (s *Server) UpdateOperationScope(w http.ResponseWriter, r *http.Request) {
	id, ok := parsePathInt64(w, r, "scopeID")
	if !ok {
		return
	}
	s.saveOperationScope(w, r, id)
}

func (s *Server) ArchiveOperationScope(w http.ResponseWriter, r *http.Request) {
	id, ok := parsePathInt64(w, r, "scopeID")
	if !ok {
		return
	}
	useCase, err := s.operationsUseCase()
	if err == nil {
		err = useCase.ArchiveScope(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), id, requestIDFromContext(r.Context()))
	}
	if err != nil {
		s.OperationScopeDetail(w, r)
		return
	}
	http.Redirect(w, r, redirectWithFlash(operationsDomainURL(r.PathValue("domainCode"))+"?tab="+OperationsTabScopes, "operations.scopeSaved"), http.StatusSeeOther)
}

func (s *Server) saveOperationFeatureFlag(w http.ResponseWriter, r *http.Request, isNew bool) {
	useCase, err := s.operationsUseCase()
	if err != nil {
		title := "operations.featureFlagTitle"
		if isNew {
			title = "operations.featureFlagNewTitle"
		}
		s.renderPage(w, errorStatus(err), r, "operations/feature_flag_form", title, "operations", NewOperationsFeatureFlagFormViewData(app.OperationsFeatureFlagDetailPage{}, isNew), publicError(localeFromContext(r.Context()), err))
		return
	}
	input, err := parseOperationFeatureFlagForm(r, r.PathValue("domainCode"), r.PathValue("flagCode"), isNew)
	var saved model.OperationFeatureFlag
	if err == nil {
		saved, err = useCase.SaveFeatureFlag(r.Context(), staffFromContext(r.Context()), input)
	}
	if err != nil {
		domainPage, _ := useCase.GetDomainDetail(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), app.OperationsDomainDetailInput{})
		flag := model.OperationFeatureFlag{
			DomainCode:      input.DomainCode,
			Code:            input.Code,
			Name:            input.Name,
			Group:           input.Group,
			Type:            input.Type,
			Enabled:         input.Enabled,
			ActionStartDate: input.ActionStartDate,
			ActionEndDate:   input.ActionEndDate,
			Value:           input.Value,
		}
		data := NewOperationsFeatureFlagFormViewData(app.OperationsFeatureFlagDetailPage{Domain: domainPage.Domain, Flag: flag}, isNew)
		title := "operations.featureFlagTitle"
		if isNew {
			title = "operations.featureFlagNewTitle"
		}
		s.renderPage(w, errorStatus(err), r, "operations/feature_flag_form", title, "operations", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(operationFeatureFlagURL(saved.DomainCode, saved.Code), "operations.featureFlagSaved"), http.StatusSeeOther)
}

func (s *Server) saveOperationTechBreak(w http.ResponseWriter, r *http.Request, id int64) {
	useCase, err := s.operationsUseCase()
	if err != nil {
		title := "operations.techBreakTitle"
		if id == 0 {
			title = "operations.techBreakNewTitle"
		}
		s.renderPage(w, errorStatus(err), r, "operations/tech_break_form", title, "operations", NewOperationsTechBreakFormViewData(app.OperationsTechBreakDetailPage{}, id == 0), publicError(localeFromContext(r.Context()), err))
		return
	}
	input, err := parseOperationTechBreakForm(r, r.PathValue("domainCode"), id)
	var saved model.OperationTechBreak
	if err == nil {
		saved, err = useCase.SaveTechBreak(r.Context(), staffFromContext(r.Context()), input)
	}
	if err != nil {
		domainPage, _ := useCase.GetDomainDetail(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), app.OperationsDomainDetailInput{})
		data := NewOperationsTechBreakFormViewData(app.OperationsTechBreakDetailPage{Domain: domainPage.Domain, Break: model.OperationTechBreak{
			ID:               id,
			DomainCode:       input.DomainCode,
			Name:             input.Name,
			ActionStartDate:  input.ActionStartDate,
			ActionEndDate:    input.ActionEndDate,
			ExcludeEmails:    input.ExcludeEmails,
			ExcludeNicknames: input.ExcludeNicknames,
			ScopeCodes:       input.ScopeCodes,
		}, Scopes: domainPage.Scopes}, id == 0)
		title := "operations.techBreakTitle"
		if id == 0 {
			title = "operations.techBreakNewTitle"
		}
		s.renderPage(w, errorStatus(err), r, "operations/tech_break_form", title, "operations", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(operationTechBreakURL(saved.DomainCode, saved.ID), "operations.techBreakSaved"), http.StatusSeeOther)
}

func (s *Server) saveOperationScope(w http.ResponseWriter, r *http.Request, id int64) {
	useCase, err := s.operationsUseCase()
	if err != nil {
		title := "operations.scopeTitle"
		if id == 0 {
			title = "operations.scopeNewTitle"
		}
		s.renderPage(w, errorStatus(err), r, "operations/scope_form", title, "operations", NewOperationsScopeFormViewData(app.OperationsScopeDetailPage{}, id == 0), publicError(localeFromContext(r.Context()), err))
		return
	}
	input := model.OperationTechBreakScopeInput{
		ID:         id,
		DomainCode: r.PathValue("domainCode"),
		Code:       r.Form.Get("code"),
		Name:       r.Form.Get("name"),
		RequestID:  requestIDFromContext(r.Context()),
	}
	var saved model.OperationTechBreakScope
	if err == nil {
		saved, err = useCase.SaveScope(r.Context(), staffFromContext(r.Context()), input)
	}
	if err != nil {
		domainPage, _ := useCase.GetDomainDetail(r.Context(), staffFromContext(r.Context()), r.PathValue("domainCode"), app.OperationsDomainDetailInput{})
		data := NewOperationsScopeFormViewData(app.OperationsScopeDetailPage{Domain: domainPage.Domain, Scope: model.OperationTechBreakScope{
			ID:         id,
			DomainCode: input.DomainCode,
			Code:       input.Code,
			Name:       input.Name,
		}}, id == 0)
		title := "operations.scopeTitle"
		if id == 0 {
			title = "operations.scopeNewTitle"
		}
		s.renderPage(w, errorStatus(err), r, "operations/scope_form", title, "operations", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(operationScopeURL(saved.DomainCode, saved.ID), "operations.scopeSaved"), http.StatusSeeOther)
}

func (s *Server) operationsUseCase() (*app.OperationsUseCase, error) {
	if s == nil || s.operations == nil {
		return nil, app.ErrIntegrationNotReady
	}
	return s.operations, nil
}

func parseOperationsDomainFilter(r *http.Request) OperationsDomainFilterViewData {
	query := r.URL.Query()
	return OperationsDomainFilterViewData{
		Search: strings.TrimSpace(query.Get("q")),
		Page:   positiveQueryInt(query.Get("page"), 0),
		Size:   positiveQueryInt(query.Get("size"), 20),
	}
}

func parseOperationsResourceFilter(r *http.Request) OperationsResourceFilterViewData {
	query := r.URL.Query()
	inArchive, _ := strconv.ParseBool(query.Get("in_archive"))
	actionStartDate, _ := parseOptionalQueryDate(query.Get("action_start_date"), false)
	actionEndDate, _ := parseOptionalQueryDate(query.Get("action_end_date"), true)
	return OperationsResourceFilterViewData{
		Search:          strings.TrimSpace(query.Get("q")),
		Group:           strings.TrimSpace(query.Get("group")),
		ActionStartDate: actionStartDate,
		ActionEndDate:   actionEndDate,
		InArchive:       inArchive,
		Page:            positiveQueryInt(query.Get("page"), 0),
		Size:            positiveQueryInt(query.Get("size"), 20),
	}
}

func parseOperationsHistoryPaginationFilter(r *http.Request) OperationsHistoryPaginationFilterViewData {
	query := r.URL.Query()
	return OperationsHistoryPaginationFilterViewData{
		Page:   positiveQueryInt(query.Get("page"), 0),
		Size:   positiveQueryInt(query.Get("size"), 20),
		Cursor: strings.TrimSpace(query.Get("cursor")),
	}
}

func operationsDomainDetailInput(filters OperationsResourceFilterViewData) app.OperationsDomainDetailInput {
	return app.OperationsDomainDetailInput{
		FeatureFlags: model.OperationFeatureFlagFilter{
			Page:            filters.Page,
			Size:            filters.Size,
			Search:          filters.Search,
			Group:           filters.Group,
			ActionStartDate: filters.ActionStartDate,
			ActionEndDate:   filters.ActionEndDate,
			InArchive:       filters.InArchive,
		},
		TechBreaks: model.OperationTechBreakFilter{
			Page:            filters.Page,
			Size:            filters.Size,
			Search:          filters.Search,
			ActionStartDate: filters.ActionStartDate,
			ActionEndDate:   filters.ActionEndDate,
		},
	}
}

func parseOperationFeatureFlagForm(r *http.Request, domainCode string, existingCode string, isNew bool) (model.OperationFeatureFlagInput, error) {
	start, err := parseRequiredOperationTime(r.Form.Get("action_start_date"))
	if err != nil {
		return model.OperationFeatureFlagInput{}, err
	}
	end, err := parseOptionalTimeFormValue(r.Form.Get("action_end_date"))
	if err != nil {
		return model.OperationFeatureFlagInput{}, err
	}
	flagType := strings.ToUpper(strings.TrimSpace(r.Form.Get("type")))
	value, err := parseOperationFeatureValue(flagType, r.Form["value"])
	if err != nil {
		return model.OperationFeatureFlagInput{}, err
	}
	code := r.Form.Get("code")
	if !isNew {
		code = firstNonEmpty(code, existingCode)
	}
	return model.OperationFeatureFlagInput{
		ExistingCode:    existingCode,
		DomainCode:      domainCode,
		Code:            code,
		Name:            r.Form.Get("name"),
		Group:           r.Form.Get("group"),
		Type:            flagType,
		Enabled:         checkboxValue(r.Form.Get("enabled")),
		ActionStartDate: start,
		ActionEndDate:   end,
		Value:           value,
		RequestID:       requestIDFromContext(r.Context()),
	}, nil
}

func parseOperationTechBreakForm(r *http.Request, domainCode string, id int64) (model.OperationTechBreakInput, error) {
	start, err := parseRequiredOperationTime(r.Form.Get("action_start_date"))
	if err != nil {
		return model.OperationTechBreakInput{}, err
	}
	end, err := parseOptionalTimeFormValue(r.Form.Get("action_end_date"))
	if err != nil {
		return model.OperationTechBreakInput{}, err
	}
	return model.OperationTechBreakInput{
		ID:               id,
		DomainCode:       domainCode,
		Name:             r.Form.Get("name"),
		ActionStartDate:  start,
		ActionEndDate:    end,
		ExcludeEmails:    splitListInput(r.Form.Get("exclude_emails")),
		ExcludeNicknames: splitListInput(r.Form.Get("exclude_nicknames")),
		ScopeCodes:       cleanOperationFormValues(r.Form["scope_codes"]),
		RequestID:        requestIDFromContext(r.Context()),
	}, nil
}

func parseRequiredOperationTime(raw string) (time.Time, error) {
	value, err := parseFlexibleTime(raw)
	if err != nil {
		return time.Time{}, err
	}
	if value.IsZero() {
		return time.Time{}, app.ErrInvalidInput
	}
	return value, nil
}

func parseOptionalTimeFormValue(raw string) (*time.Time, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}
	value, err := parseFlexibleTime(raw)
	if err != nil {
		return nil, err
	}
	return &value, nil
}

func parseOperationFeatureValue(flagType string, rawValues []string) ([]any, error) {
	if flagType == "TOGGLE" {
		return nil, nil
	}
	parts := cleanOperationFormValues(rawValues)
	values := make([]any, 0, len(parts))
	for _, part := range parts {
		if flagType == "ARRAY_INTEGER" {
			parsed, err := strconv.Atoi(part)
			if err != nil {
				return nil, app.ErrInvalidInput
			}
			values = append(values, parsed)
			continue
		}
		values = append(values, part)
	}
	return values, nil
}

func splitListInput(raw string) []string {
	raw = strings.ReplaceAll(raw, "\r\n", "\n")
	raw = strings.ReplaceAll(raw, "\r", "\n")
	var out []string
	for _, line := range strings.Split(raw, "\n") {
		for _, part := range strings.Split(line, ",") {
			part = strings.TrimSpace(part)
			if part != "" {
				out = append(out, part)
			}
		}
	}
	return out
}

func cleanOperationFormValues(values []string) []string {
	out := make([]string, 0, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value != "" {
			out = append(out, value)
		}
	}
	return out
}

func checkboxValue(raw string) bool {
	raw = strings.ToLower(strings.TrimSpace(raw))
	return raw == "on" || raw == "true" || raw == "1" || raw == "yes"
}

func positiveQueryInt(raw string, fallback int) int {
	if strings.TrimSpace(raw) == "" {
		return fallback
	}
	value, err := strconv.Atoi(strings.TrimSpace(raw))
	if err != nil || value < 0 {
		return fallback
	}
	return value
}

func parsePathInt64(w http.ResponseWriter, r *http.Request, key string) (int64, bool) {
	value, err := strconv.ParseInt(strings.TrimSpace(r.PathValue(key)), 10, 64)
	if err != nil || value <= 0 {
		http.Error(w, translate(localeFromContext(r.Context()), "error.invalidID"), http.StatusBadRequest)
		return 0, false
	}
	return value, true
}
