package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/config"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

type Server struct {
	cfg        *config.Config
	renderer   *Renderer
	auth       *app.AuthUseCase
	staff      *app.StaffUseCase
	moderation *app.ModerationUseCase
	audit      *app.AuditUseCase
	readiness  func(context.Context) error
}

func NewServer(
	cfg *config.Config,
	renderer *Renderer,
	auth *app.AuthUseCase,
	staff *app.StaffUseCase,
	moderation *app.ModerationUseCase,
	audit *app.AuditUseCase,
) *Server {
	return &Server{cfg: cfg, renderer: renderer, auth: auth, staff: staff, moderation: moderation, audit: audit}
}

func (s *Server) SetReadinessCheck(check func(context.Context) error) {
	s.readiness = check
}

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.Handle("GET /admin/static/", http.StripPrefix("/admin/static/", s.renderer.StaticHandler()))
	mux.HandleFunc("GET /health", s.Health)
	mux.HandleFunc("GET /ready", s.Ready)
	mux.HandleFunc("GET /admin/login", s.LoginPage)
	mux.HandleFunc("POST /admin/login", s.Login)
	mux.HandleFunc("POST /admin/logout", s.Logout)
	mux.HandleFunc("GET /admin/password/change", s.ChangePasswordPage)
	mux.HandleFunc("POST /admin/password/change", s.ChangePassword)
	mux.HandleFunc("GET /admin", s.Dashboard)
	mux.HandleFunc("GET /admin/moderation/excursions", s.ExcursionQueue)
	mux.HandleFunc("GET /admin/moderation/excursions/history", s.ExcursionHistory)
	mux.HandleFunc("GET /admin/moderation/excursions/{caseID}", s.ExcursionCase)
	mux.HandleFunc("POST /admin/moderation/excursions/sync", s.SyncExcursionQueue)
	mux.HandleFunc("POST /admin/moderation/excursions/{caseID}/approve", s.ApproveExcursion)
	mux.HandleFunc("POST /admin/moderation/excursions/{caseID}/reject", s.RejectExcursion)
	mux.HandleFunc("GET /admin/staff", s.StaffList)
	mux.HandleFunc("POST /admin/staff", s.CreateStaff)
	mux.HandleFunc("GET /admin/staff/{staffID}/edit", s.EditStaffPage)
	mux.HandleFunc("POST /admin/staff/{staffID}", s.UpdateStaffProfile)
	mux.HandleFunc("POST /admin/staff/{staffID}/status", s.ChangeStaffStatus)
	mux.HandleFunc("POST /admin/staff/{staffID}/password/regenerate", s.RegenerateStaffPassword)
	mux.HandleFunc("GET /admin/audit", s.AuditLog)

	var handler http.Handler = mux
	handler = s.sessionMiddleware(handler)
	handler = s.localeMiddleware(handler)
	handler = loggingMiddleware(handler)
	handler = securityHeadersMiddleware(handler)
	handler = requestIDMiddleware(s.cfg, handler)
	return handler
}

func (s *Server) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (s *Server) Ready(w http.ResponseWriter, r *http.Request) {
	if s.readiness != nil {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		if err := s.readiness(ctx); err != nil {
			writeJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "not_ready"})
			return
		}
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

func (s *Server) LoginPage(w http.ResponseWriter, r *http.Request) {
	locale := localeFromContext(r.Context())
	s.render(w, http.StatusOK, "auth/login", PageData{
		Title:  translate(locale, "login.title"),
		Locale: locale,
		Path:   r.URL.Path,
		Data:   LoginViewData{},
	})
}

func (s *Server) Login(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		s.renderLoginError(w, r, "error.invalidLoginForm", "")
		return
	}
	email := strings.TrimSpace(r.Form.Get("email"))
	result, err := s.auth.Login(r.Context(), email, r.Form.Get("password"), requestMetadata(r))
	if err != nil {
		s.renderLoginError(w, r, "error.invalidCredentials", email)
		return
	}
	s.setSessionCookies(w, result.SessionToken, result.CSRFToken)
	if result.Staff.RequiresPasswordChange() {
		http.Redirect(w, r, "/admin/password/change", http.StatusSeeOther)
		return
	}
	http.Redirect(w, r, "/admin", http.StatusSeeOther)
}

func (s *Server) Logout(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	session := sessionFromContext(r.Context())
	if staff != nil && session != nil {
		_ = s.auth.Logout(r.Context(), session.ID, staff.ID, requestMetadata(r))
	}
	s.clearSessionCookies(w)
	http.Redirect(w, r, "/admin/login", http.StatusSeeOther)
}

func (s *Server) ChangePasswordPage(w http.ResponseWriter, r *http.Request) {
	s.renderPage(w, http.StatusOK, r, "auth/change_password", "password.changeTitle", "staff", nil, "")
}

func (s *Server) ChangePassword(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	password := r.Form.Get("password")
	confirm := r.Form.Get("confirm_password")
	requireCurrentPassword := staff != nil && !staff.RequiresPasswordChange()
	if password == "" || password != confirm {
		s.renderPage(w, http.StatusBadRequest, r, "auth/change_password", "password.changeTitle", "staff", nil, translate(localeFromContext(r.Context()), "error.passwordsDoNotMatch"))
		return
	}
	if err := s.auth.ChangePassword(r.Context(), staff.ID, r.Form.Get("current_password"), password, requireCurrentPassword, requestMetadata(r)); err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "auth/change_password", "password.changeTitle", "staff", nil, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.clearSessionCookies(w)
	http.Redirect(w, r, "/admin/login", http.StatusSeeOther)
}

func (s *Server) Dashboard(w http.ResponseWriter, r *http.Request) {
	s.renderPage(w, http.StatusOK, r, "dashboard/index", "dashboard.title", "dashboard", nil, "")
}

func (s *Server) SyncExcursionQueue(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	if err := s.moderation.SyncExcursionQueue(r.Context(), staff); err != nil {
		_, viewFilter := parseExcursionQueueFilter(r)
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.excursionQueue", "moderation", NewQueueViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	redirectURL := "/admin/moderation/excursions"
	if r.URL.RawQuery != "" {
		redirectURL += "?" + r.URL.RawQuery
	}
	http.Redirect(w, r, redirectWithFlash(redirectURL, "moderation.queueSynced"), http.StatusSeeOther)
}

func (s *Server) ExcursionQueue(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	_ = s.moderation.SyncExcursionQueue(r.Context(), staff)
	targetType := model.ModerationTargetExcursion
	filter, viewFilter := parseExcursionQueueFilter(r)
	filter.TargetType = &targetType
	filter.Limit = 100
	cases, err := s.moderation.ListQueue(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.excursionQueue", "moderation", NewQueueViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/queue", "moderation.excursionQueue", "moderation", NewQueueViewData(cases, viewFilter), "")
}

func (s *Server) ExcursionHistory(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	targetType := model.ModerationTargetExcursion
	filter, viewFilter := parseExcursionHistoryFilter(r)
	filter.TargetType = &targetType
	filter.Limit = 100
	cases, err := s.moderation.ListQueue(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.excursionHistory", "moderation", NewQueueHistoryViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/queue", "moderation.excursionHistory", "moderation", NewQueueHistoryViewData(cases, viewFilter), "")
}

func (s *Server) ExcursionCase(w http.ResponseWriter, r *http.Request) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	detail, err := s.moderation.GetCaseDetail(r.Context(), staff, caseID)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "moderation", CaseDetailViewData{}, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/detail", "moderation.caseTitle", "moderation", CaseDetailViewData{Detail: detail}, "")
}

func (s *Server) ApproveExcursion(w http.ResponseWriter, r *http.Request) {
	s.decideExcursion(w, r, enum.ModerationDecisionApprove)
}

func (s *Server) RejectExcursion(w http.ResponseWriter, r *http.Request) {
	s.decideExcursion(w, r, enum.ModerationDecisionReject)
}

func (s *Server) decideExcursion(w http.ResponseWriter, r *http.Request, decision enum.ModerationDecisionType) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	_, err := s.moderation.DecideExcursion(r.Context(), app.ModerationDecisionInput{
		Actor:           staff,
		CaseID:          caseID,
		Decision:        decision,
		ReasonCodes:     splitCSV(r.Form.Get("reason_codes")),
		PublicComment:   r.Form.Get("public_comment"),
		InternalComment: r.Form.Get("internal_comment"),
		IdempotencyKey:  r.Form.Get("idempotency_key"),
		RequestMetadata: requestMetadata(r),
	})
	if err != nil {
		viewData := CaseDetailViewData{}
		if detail, detailErr := s.moderation.GetCaseDetail(r.Context(), staff, caseID); detailErr == nil {
			viewData.Detail = detail
		}
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "moderation", viewData, publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash("/admin/moderation/excursions/"+caseID.String(), "moderation.decisionSaved"), http.StatusSeeOther)
}

func (s *Server) StaffList(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	items, err := s.staff.ListStaff(r.Context(), staff, 100, 0)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "staff/index", "staff.title", "staff", NewStaffListViewData(staff, nil), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "staff/index", "staff.title", "staff", NewStaffListViewData(staff, items), "")
}

func (s *Server) CreateStaff(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	result, err := s.staff.CreateStaff(r.Context(), staff, app.CreateStaffInput{
		ActorStaffID: staff.ID,
		Email:        r.Form.Get("email"),
		DisplayName:  r.Form.Get("display_name"),
		Roles:        parseRoles(r.Form["roles"]),
		Metadata:     requestMetadata(r),
	})
	if err != nil {
		items, _ := s.staff.ListStaff(r.Context(), staff, 100, 0)
		s.renderPage(w, errorStatus(err), r, "staff/index", "staff.title", "staff", NewStaffListViewData(staff, items), publicError(localeFromContext(r.Context()), err))
		return
	}
	items, _ := s.staff.ListStaff(r.Context(), staff, 100, 0)
	s.renderPageWithFlash(w, http.StatusCreated, r, "staff/index", "staff.title", "staff", NewStaffListViewData(staff, items, result.TemporaryPassword), "", "staff.created")
}

func (s *Server) EditStaffPage(w http.ResponseWriter, r *http.Request) {
	staffID, ok := parsePathUUID(w, r, "staffID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	target, err := s.staff.GetStaff(r.Context(), staff, staffID)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "staff/edit", "staff.editUser", "staff", NewStaffEditViewData(staff, nil), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "staff/edit", "staff.editUser", "staff", NewStaffEditViewData(staff, target), "")
}

func (s *Server) UpdateStaffProfile(w http.ResponseWriter, r *http.Request) {
	staffID, ok := parsePathUUID(w, r, "staffID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	err := s.staff.UpdateStaffProfile(r.Context(), staff, app.UpdateStaffProfileInput{
		StaffID:     staffID,
		DisplayName: r.Form.Get("display_name"),
		Roles:       parseRoles(r.Form["roles"]),
		Metadata:    requestMetadata(r),
	})
	if err != nil {
		s.renderStaffEditError(w, r, staff, staffID, err, "")
		return
	}
	http.Redirect(w, r, redirectWithFlash("/admin/staff/"+staffID.String()+"/edit", "staff.updated"), http.StatusSeeOther)
}

func (s *Server) ChangeStaffStatus(w http.ResponseWriter, r *http.Request) {
	staffID, ok := parsePathUUID(w, r, "staffID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	err := s.staff.ChangeStaffStatus(r.Context(), staff, app.ChangeStaffStatusInput{
		StaffID:  staffID,
		Status:   enum.StaffStatus(strings.ToUpper(strings.TrimSpace(r.Form.Get("status")))),
		Reason:   r.Form.Get("reason"),
		Metadata: requestMetadata(r),
	})
	if err != nil {
		s.renderStaffEditError(w, r, staff, staffID, err, "")
		return
	}
	http.Redirect(w, r, redirectWithFlash("/admin/staff/"+staffID.String()+"/edit", "staff.statusChanged"), http.StatusSeeOther)
}

func (s *Server) RegenerateStaffPassword(w http.ResponseWriter, r *http.Request) {
	staffID, ok := parsePathUUID(w, r, "staffID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	result, err := s.staff.RegenerateStaffPassword(r.Context(), staff, app.RegenerateStaffPasswordInput{
		StaffID:  staffID,
		Metadata: requestMetadata(r),
	})
	if err != nil {
		s.renderStaffEditError(w, r, staff, staffID, err, "")
		return
	}
	target, getErr := s.staff.GetStaff(r.Context(), staff, staffID)
	if getErr != nil {
		s.renderStaffEditError(w, r, staff, staffID, getErr, "")
		return
	}
	s.renderPageWithFlash(w, http.StatusOK, r, "staff/edit", "staff.editUser", "staff", NewStaffEditViewData(staff, target, result.TemporaryPassword), "", "staff.passwordRegenerated")
}

func (s *Server) renderStaffEditError(w http.ResponseWriter, r *http.Request, actor *model.StaffUser, staffID uuid.UUID, err error, temporaryPassword string) {
	var target *model.StaffUser
	if staffID != uuid.Nil {
		target, _ = s.staff.GetStaff(r.Context(), actor, staffID)
	}
	s.renderPage(w, errorStatus(err), r, "staff/edit", "staff.editUser", "staff", NewStaffEditViewData(actor, target, temporaryPassword), publicError(localeFromContext(r.Context()), err))
}

func (s *Server) AuditLog(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	events, err := s.audit.List(r.Context(), staff, model.AuditFilter{Limit: 100})
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "audit/index", "audit.title", "audit", NewAuditViewData(localeFromContext(r.Context()), nil), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "audit/index", "audit.title", "audit", NewAuditViewData(localeFromContext(r.Context()), events), "")
}

func (s *Server) renderLoginError(w http.ResponseWriter, r *http.Request, messageKey string, email string) {
	locale := localeFromContext(r.Context())
	s.render(w, http.StatusUnauthorized, "auth/login", PageData{
		Title:  translate(locale, "login.title"),
		Locale: locale,
		Path:   r.URL.Path,
		Error:  translate(locale, messageKey),
		Data:   LoginViewData{Email: email},
	})
}

func (s *Server) renderPage(w http.ResponseWriter, status int, r *http.Request, templateName string, titleKey string, activeNav string, data any, message string) {
	s.renderPageWithFlash(w, status, r, templateName, titleKey, activeNav, data, message, "")
}

func (s *Server) renderPageWithFlash(w http.ResponseWriter, status int, r *http.Request, templateName string, titleKey string, activeNav string, data any, message string, flashKey string) {
	locale := localeFromContext(r.Context())
	flash := flashMessage(locale, flashKey)
	if flash == "" {
		flash = flashMessageFromRequest(locale, r)
	}
	s.render(w, status, templateName, PageData{
		Title:     translate(locale, titleKey),
		Locale:    locale,
		Path:      r.URL.Path,
		Staff:     staffFromContext(r.Context()),
		CSRFToken: csrfTokenFromContext(r.Context()),
		Error:     message,
		Flash:     flash,
		ActiveNav: activeNav,
		Data:      data,
	})
}

func (s *Server) render(w http.ResponseWriter, status int, templateName string, data PageData) {
	s.renderer.Render(w, status, templateName, data)
}

func (s *Server) setSessionCookies(w http.ResponseWriter, sessionToken string, csrfToken string) {
	http.SetCookie(w, &http.Cookie{
		Name:     s.cfg.Security.SessionCookieName,
		Value:    sessionToken,
		Path:     "/admin",
		HttpOnly: true,
		Secure:   s.cfg.Security.CookieSecure,
		SameSite: http.SameSiteStrictMode,
		Expires:  time.Now().Add(s.cfg.Security.SessionAbsoluteTimeout),
	})
	http.SetCookie(w, &http.Cookie{
		Name:     s.cfg.Security.CSRFCookieName,
		Value:    csrfToken,
		Path:     "/admin",
		HttpOnly: false,
		Secure:   s.cfg.Security.CookieSecure,
		SameSite: http.SameSiteStrictMode,
		Expires:  time.Now().Add(s.cfg.Security.SessionAbsoluteTimeout),
	})
}

func (s *Server) clearSessionCookies(w http.ResponseWriter) {
	http.SetCookie(w, &http.Cookie{
		Name:     s.cfg.Security.SessionCookieName,
		Value:    "",
		Path:     "/admin",
		HttpOnly: true,
		Secure:   s.cfg.Security.CookieSecure,
		SameSite: http.SameSiteStrictMode,
		MaxAge:   -1,
	})
	http.SetCookie(w, &http.Cookie{
		Name:     s.cfg.Security.CSRFCookieName,
		Value:    "",
		Path:     "/admin",
		HttpOnly: false,
		Secure:   s.cfg.Security.CookieSecure,
		SameSite: http.SameSiteStrictMode,
		MaxAge:   -1,
	})
}

func parsePathUUID(w http.ResponseWriter, r *http.Request, key string) (uuid.UUID, bool) {
	value, err := uuid.Parse(strings.TrimSpace(r.PathValue(key)))
	if err != nil {
		http.Error(w, translate(localeFromContext(r.Context()), "error.invalidID"), http.StatusBadRequest)
		return uuid.Nil, false
	}
	return value, true
}

func parseRoles(values []string) []enum.StaffRole {
	out := make([]enum.StaffRole, 0, len(values))
	for _, value := range values {
		for _, part := range splitCSV(value) {
			out = append(out, enum.StaffRole(strings.ToUpper(strings.TrimSpace(part))))
		}
	}
	return out
}

func splitCSV(value string) []string {
	parts := strings.Split(value, ",")
	out := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			out = append(out, part)
		}
	}
	return out
}

func publicError(locale string, err error) string {
	if err == nil {
		return ""
	}
	if errors.Is(err, app.ErrPermissionDenied) {
		return translate(locale, "error.permissionDenied")
	}
	if errors.Is(err, app.ErrModerationCaseNotFound) {
		return translate(locale, "error.caseNotFound")
	}
	if errors.Is(err, app.ErrStaffNotFound) {
		return translate(locale, "error.staffNotFound")
	}
	if errors.Is(err, app.ErrDuplicateDecision) {
		return translate(locale, "error.duplicateDecision")
	}
	if errors.Is(err, app.ErrModerationCaseConflict) {
		return translate(locale, "error.caseConflict")
	}
	if errors.Is(err, app.ErrInvalidInput) {
		return translate(locale, "error.invalidInput")
	}
	return translate(locale, "error.generic")
}

func errorStatus(err error) int {
	switch {
	case errors.Is(err, app.ErrPermissionDenied):
		return http.StatusForbidden
	case errors.Is(err, app.ErrModerationCaseNotFound):
		return http.StatusNotFound
	case errors.Is(err, app.ErrStaffNotFound):
		return http.StatusNotFound
	case errors.Is(err, app.ErrModerationCaseConflict):
		return http.StatusConflict
	case errors.Is(err, app.ErrInvalidInput):
		return http.StatusBadRequest
	default:
		return http.StatusInternalServerError
	}
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
