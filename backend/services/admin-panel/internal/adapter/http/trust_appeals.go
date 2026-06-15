package http

import (
	"net/http"
	"strconv"
	"strings"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func (s *Server) TrustAppealQueue(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	filter, viewFilter, err := parseTrustAppealFilter(r)
	if err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "trust/appeals", "trust.appealsTitle", "trust", NewTrustAppealListViewData(model.TrustRestrictionAppealListPage{}, viewFilter, staff), publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	if s.trustAppeals == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "trust/appeals", "trust.appealsTitle", "trust", NewTrustAppealListViewData(model.TrustRestrictionAppealListPage{}, viewFilter, staff), publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	page, err := s.trustAppeals.ListRestrictionAppeals(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "trust/appeals", "trust.appealsTitle", "trust", NewTrustAppealListViewData(model.TrustRestrictionAppealListPage{}, viewFilter, staff), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "trust/appeals", "trust.appealsTitle", "trust", NewTrustAppealListViewData(page, viewFilter, staff), "")
}

func (s *Server) TrustAppealDetail(w http.ResponseWriter, r *http.Request) {
	appealID, ok := parsePathUUID(w, r, "appealID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	_, viewFilter, err := parseTrustAppealFilter(r)
	if err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "trust/appeal_detail", "trust.appealDetailTitle", "trust", NewTrustAppealDetailViewData(model.TrustRestrictionAppeal{}, viewFilter, staff), publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	if s.trustAppeals == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "trust/appeal_detail", "trust.appealDetailTitle", "trust", NewTrustAppealDetailViewData(model.TrustRestrictionAppeal{}, viewFilter, staff), publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	item, err := s.trustAppeals.GetRestrictionAppeal(r.Context(), staff, appealID, requestMetadata(r))
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "trust/appeal_detail", "trust.appealDetailTitle", "trust", NewTrustAppealDetailViewData(model.TrustRestrictionAppeal{}, viewFilter, staff), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "trust/appeal_detail", "trust.appealDetailTitle", "trust", NewTrustAppealDetailViewData(item, viewFilter, staff), "")
}

func (s *Server) ApproveTrustAppeal(w http.ResponseWriter, r *http.Request) {
	s.decideTrustAppeal(w, r, model.TrustRestrictionAppealDecisionApprove)
}

func (s *Server) RejectTrustAppeal(w http.ResponseWriter, r *http.Request) {
	s.decideTrustAppeal(w, r, model.TrustRestrictionAppealDecisionReject)
}

func (s *Server) decideTrustAppeal(w http.ResponseWriter, r *http.Request, decision model.TrustRestrictionAppealDecision) {
	appealID, ok := parsePathUUID(w, r, "appealID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	_, viewFilter, err := parseTrustAppealFilter(r)
	if err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "trust/appeal_detail", "trust.appealDetailTitle", "trust", NewTrustAppealDetailViewData(model.TrustRestrictionAppeal{}, viewFilter, staff), publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	if s.trustAppeals == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "trust/appeal_detail", "trust.appealDetailTitle", "trust", NewTrustAppealDetailViewData(model.TrustRestrictionAppeal{}, viewFilter, staff), publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	item, err := s.trustAppeals.DecideRestrictionAppeal(r.Context(), staff, model.TrustRestrictionAppealDecisionInput{
		AppealID:       appealID,
		Decision:       decision,
		ReasonCode:     r.Form.Get("reason_code"),
		StaffComment:   r.Form.Get("staff_comment"),
		IdempotencyKey: r.Form.Get("idempotency_key"),
	}, requestMetadata(r))
	if err != nil {
		viewData := NewTrustAppealDetailViewData(model.TrustRestrictionAppeal{ID: appealID}, viewFilter, staff)
		if existing, detailErr := s.trustAppeals.GetRestrictionAppeal(r.Context(), staff, appealID, requestMetadata(r)); detailErr == nil {
			viewData = NewTrustAppealDetailViewData(existing, viewFilter, staff)
		}
		s.renderPage(w, errorStatus(err), r, "trust/appeal_detail", "trust.appealDetailTitle", "trust", viewData, publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(trustAppealDetailURL(item.ID, viewFilter.Query), "trust.appealDecided"), http.StatusSeeOther)
}

func parseTrustAppealFilter(r *http.Request) (model.TrustRestrictionAppealFilter, TrustAppealFilterViewData, error) {
	query := r.URL.Query()
	pageSize := 0
	if raw := strings.TrimSpace(query.Get("page_size")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil {
			return model.TrustRestrictionAppealFilter{}, TrustAppealFilterViewData{}, err
		}
		pageSize = parsed
	}
	viewFilter := TrustAppealFilterViewData{
		Status:    strings.ToUpper(strings.TrimSpace(query.Get("status"))),
		Search:    strings.TrimSpace(query.Get("q")),
		PageSize:  pageSize,
		PageToken: strings.TrimSpace(query.Get("page_token")),
	}
	viewFilter = normalizeTrustAppealFilter(viewFilter)
	return model.TrustRestrictionAppealFilter{
		Status:    model.TrustRestrictionAppealStatus(viewFilter.Status),
		Query:     viewFilter.Search,
		PageSize:  viewFilter.PageSize,
		PageToken: viewFilter.PageToken,
	}, viewFilter, nil
}
