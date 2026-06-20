package http

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"mime/multipart"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/config"
	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type Server struct {
	cfg          *config.Config
	renderer     *Renderer
	auth         *app.AuthUseCase
	staff        *app.StaffUseCase
	moderation   *app.ModerationUseCase
	users        *app.UserModerationUseCase
	trustAppeals *app.TrustAppealUseCase
	audit        *app.AuditUseCase
	places       *app.PlaceContentUseCase
	communities  *app.CommunityAdminUseCase
	fraud        *app.FraudUseCase
	operations   *app.OperationsUseCase
	readiness    func(context.Context) error
}

func NewServer(
	cfg *config.Config,
	renderer *Renderer,
	auth *app.AuthUseCase,
	staff *app.StaffUseCase,
	moderation *app.ModerationUseCase,
	users *app.UserModerationUseCase,
	audit *app.AuditUseCase,
	places *app.PlaceContentUseCase,
	fraud *app.FraudUseCase,
) *Server {
	return &Server{
		cfg:        cfg,
		renderer:   renderer,
		auth:       auth,
		staff:      staff,
		moderation: moderation,
		users:      users,
		audit:      audit,
		places:     places,
		fraud:      fraud,
	}
}

func (s *Server) SetReadinessCheck(check func(context.Context) error) {
	s.readiness = check
}

func (s *Server) SetTrustAppealUseCase(useCase *app.TrustAppealUseCase) {
	s.trustAppeals = useCase
}

func (s *Server) SetCommunityAdminUseCase(useCase *app.CommunityAdminUseCase) {
	s.communities = useCase
}

func (s *Server) SetOperationsUseCase(useCase *app.OperationsUseCase) {
	s.operations = useCase
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
	mux.HandleFunc("GET /admin/navigation", s.AdminNavigation)
	mux.HandleFunc("GET /admin/feed-quality", s.FeedQualityDashboard)
	mux.HandleFunc("GET /admin/me", s.StaffProfile)
	mux.HandleFunc("POST /admin/me/timezone", s.UpdateOwnTimezone)
	mux.HandleFunc("GET /admin/users", s.AdminUserList)
	mux.HandleFunc("GET /admin/users/{userID}", s.AdminUserDetail)
	mux.HandleFunc("POST /admin/users/{userID}/moderation-cases", s.CreateUserModerationCase)
	mux.HandleFunc("POST /admin/users/{userID}/moderation-cases/{caseID}/resolve", s.ResolveUserModerationCase)
	mux.HandleFunc("POST /admin/users/{userID}/restrictions", s.CreateUserRestriction)
	mux.HandleFunc("POST /admin/users/{userID}/restrictions/{restrictionID}/lift", s.LiftUserRestriction)
	mux.HandleFunc("GET /admin/trust/appeals", s.TrustAppealQueue)
	mux.HandleFunc("GET /admin/trust/appeals/{appealID}", s.TrustAppealDetail)
	mux.HandleFunc("POST /admin/trust/appeals/{appealID}/approve", s.ApproveTrustAppeal)
	mux.HandleFunc("POST /admin/trust/appeals/{appealID}/reject", s.RejectTrustAppeal)
	mux.HandleFunc("GET /admin/moderation/excursions", s.ExcursionQueue)
	mux.HandleFunc("GET /admin/moderation/excursions/fraud-blocks", s.ExcursionFraudBlocks)
	mux.HandleFunc("POST /admin/moderation/excursions/fraud-blocks/{assessmentID}/confirm", s.ConfirmExcursionFraudBlock)
	mux.HandleFunc("POST /admin/moderation/excursions/fraud-blocks/{assessmentID}/false-positive", s.FalsePositiveExcursionFraudBlock)
	mux.HandleFunc("POST /admin/moderation/excursions/fraud-blocks/{assessmentID}/escalate", s.EscalateExcursionFraudBlock)
	mux.HandleFunc("GET /admin/moderation/excursions/history", s.ExcursionHistory)
	mux.HandleFunc("GET /admin/moderation/excursions/{caseID}", s.ExcursionCase)
	mux.HandleFunc("POST /admin/moderation/excursions/sync", s.SyncExcursionQueue)
	mux.HandleFunc("POST /admin/moderation/excursions/{caseID}/approve", s.ApproveExcursion)
	mux.HandleFunc("POST /admin/moderation/excursions/{caseID}/reject", s.RejectExcursion)
	mux.HandleFunc("GET /admin/moderation/activities", s.ActivityQueue)
	mux.HandleFunc("GET /admin/moderation/activities/fraud-blocks", s.ActivityFraudBlocks)
	mux.HandleFunc("POST /admin/moderation/activities/fraud-blocks/{assessmentID}/confirm", s.ConfirmActivityFraudBlock)
	mux.HandleFunc("POST /admin/moderation/activities/fraud-blocks/{assessmentID}/false-positive", s.FalsePositiveActivityFraudBlock)
	mux.HandleFunc("POST /admin/moderation/activities/fraud-blocks/{assessmentID}/escalate", s.EscalateActivityFraudBlock)
	mux.HandleFunc("GET /admin/moderation/activities/history", s.ActivityHistory)
	mux.HandleFunc("GET /admin/moderation/activities/{caseID}", s.ActivityCase)
	mux.HandleFunc("POST /admin/moderation/activities/sync", s.SyncActivityQueue)
	mux.HandleFunc("POST /admin/moderation/activities/{caseID}/approve", s.ApproveActivity)
	mux.HandleFunc("POST /admin/moderation/activities/{caseID}/reject", s.RejectActivity)
	mux.HandleFunc("GET /admin/moderation/chats", s.ChatMessageQueue)
	mux.HandleFunc("GET /admin/moderation/chats/history", s.ChatMessageHistory)
	mux.HandleFunc("GET /admin/moderation/chats/{caseID}", s.ChatMessageCase)
	mux.HandleFunc("POST /admin/moderation/chats/sync", s.SyncChatMessageQueue)
	mux.HandleFunc("POST /admin/moderation/chats/{caseID}/approve", s.ApproveChatMessage)
	mux.HandleFunc("POST /admin/moderation/chats/{caseID}/reject", s.RejectChatMessage)
	mux.HandleFunc("GET /admin/moderation/posts", s.PostReportQueue)
	mux.HandleFunc("GET /admin/moderation/posts/history", s.PostReportHistory)
	mux.HandleFunc("GET /admin/moderation/posts/{caseID}", s.PostReportCase)
	mux.HandleFunc("POST /admin/moderation/posts/sync", s.SyncPostReportQueue)
	mux.HandleFunc("POST /admin/moderation/posts/{caseID}/approve", s.ApprovePostReport)
	mux.HandleFunc("POST /admin/moderation/posts/{caseID}/reject", s.RejectPostReport)
	mux.HandleFunc("GET /admin/moderation/guides", s.GuideApplicationQueue)
	mux.HandleFunc("GET /admin/moderation/guides/fraud-blocks", s.GuideFraudBlocks)
	mux.HandleFunc("POST /admin/moderation/guides/fraud-blocks/{assessmentID}/confirm", s.ConfirmGuideFraudBlock)
	mux.HandleFunc("POST /admin/moderation/guides/fraud-blocks/{assessmentID}/false-positive", s.FalsePositiveGuideFraudBlock)
	mux.HandleFunc("POST /admin/moderation/guides/fraud-blocks/{assessmentID}/escalate", s.EscalateGuideFraudBlock)
	mux.HandleFunc("GET /admin/moderation/guides/current", s.ActiveGuideList)
	mux.HandleFunc("GET /admin/moderation/guides/history", s.GuideApplicationHistory)
	mux.HandleFunc("GET /admin/moderation/guides/{caseID}/documents/{documentID}", s.GuideApplicationDocument)
	mux.HandleFunc("GET /admin/moderation/guides/{caseID}", s.GuideApplicationCase)
	mux.HandleFunc("POST /admin/moderation/guides/sync", s.SyncGuideApplicationQueue)
	mux.HandleFunc("POST /admin/moderation/guides/current/{guideProfileID}/revoke", s.RevokeActiveGuide)
	mux.HandleFunc("POST /admin/moderation/guides/{caseID}/approve", s.ApproveGuideApplication)
	mux.HandleFunc("POST /admin/moderation/guides/{caseID}/reject", s.RejectGuideApplication)
	mux.HandleFunc("POST /admin/moderation/guides/{caseID}/revoke", s.RevokeGuideApplication)
	mux.HandleFunc("GET /admin/places", s.PlaceList)
	mux.HandleFunc("GET /admin/places/new", s.NewPlacePage)
	mux.HandleFunc("POST /admin/places", s.CreatePlace)
	mux.HandleFunc("GET /admin/place-media/{fileID}", s.PlaceMedia)
	mux.HandleFunc("GET /admin/places/{placeID}/edit", s.EditPlacePage)
	mux.HandleFunc("POST /admin/places/{placeID}", s.UpdatePlace)
	mux.HandleFunc("POST /admin/places/{placeID}/media", s.ReplacePlaceMedia)
	mux.HandleFunc("GET /admin/communities", s.CommunityPlatformPage)
	mux.HandleFunc("GET /admin/communities/new", s.NewCommunityPage)
	mux.HandleFunc("POST /admin/communities", s.CreateCommunity)
	mux.HandleFunc("GET /admin/communities/{communityID}/edit", s.EditCommunityPage)
	mux.HandleFunc("POST /admin/communities/{communityID}", s.UpdateCommunity)
	mux.HandleFunc("POST /admin/communities/materialize", s.MaterializeCommunityInstances)
	mux.HandleFunc("GET /admin/operations", s.OperationsDashboard)
	mux.HandleFunc("GET /admin/operations/domains/{domainCode}", s.OperationDomainDetail)
	mux.HandleFunc("POST /admin/operations/domains/{domainCode}", s.UpdateOperationDomain)
	mux.HandleFunc("GET /admin/operations/domains/{domainCode}/feature-flags/new", s.NewOperationFeatureFlagPage)
	mux.HandleFunc("POST /admin/operations/domains/{domainCode}/feature-flags", s.CreateOperationFeatureFlag)
	mux.HandleFunc("GET /admin/operations/domains/{domainCode}/feature-flags/{flagCode}/history", s.OperationFeatureFlagHistory)
	mux.HandleFunc("GET /admin/operations/domains/{domainCode}/feature-flags/{flagCode}", s.OperationFeatureFlagDetail)
	mux.HandleFunc("POST /admin/operations/domains/{domainCode}/feature-flags/{flagCode}", s.UpdateOperationFeatureFlag)
	mux.HandleFunc("POST /admin/operations/domains/{domainCode}/feature-flags/{flagCode}/archive", s.ArchiveOperationFeatureFlag)
	mux.HandleFunc("POST /admin/operations/domains/{domainCode}/feature-flags/{flagCode}/recover", s.RecoverOperationFeatureFlag)
	mux.HandleFunc("GET /admin/operations/domains/{domainCode}/tech-breaks/new", s.NewOperationTechBreakPage)
	mux.HandleFunc("POST /admin/operations/domains/{domainCode}/tech-breaks", s.CreateOperationTechBreak)
	mux.HandleFunc("GET /admin/operations/domains/{domainCode}/tech-breaks/{techBreakID}", s.OperationTechBreakDetail)
	mux.HandleFunc("POST /admin/operations/domains/{domainCode}/tech-breaks/{techBreakID}", s.UpdateOperationTechBreak)
	mux.HandleFunc("POST /admin/operations/domains/{domainCode}/tech-breaks/{techBreakID}/archive", s.ArchiveOperationTechBreak)
	mux.HandleFunc("GET /admin/operations/domains/{domainCode}/scopes/new", s.NewOperationScopePage)
	mux.HandleFunc("POST /admin/operations/domains/{domainCode}/scopes", s.CreateOperationScope)
	mux.HandleFunc("GET /admin/operations/domains/{domainCode}/scopes/{scopeID}", s.OperationScopeDetail)
	mux.HandleFunc("POST /admin/operations/domains/{domainCode}/scopes/{scopeID}", s.UpdateOperationScope)
	mux.HandleFunc("POST /admin/operations/domains/{domainCode}/scopes/{scopeID}/archive", s.ArchiveOperationScope)
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
		s.renderLoginError(w, http.StatusBadRequest, r, "error.invalidLoginForm", "")
		return
	}
	email := strings.TrimSpace(r.Form.Get("email"))
	result, err := s.auth.Login(r.Context(), email, r.Form.Get("password"), requestMetadata(r))
	if err != nil {
		status, messageKey := loginErrorResponse(err)
		s.renderLoginError(w, status, r, messageKey, email)
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
	staff := staffFromContext(r.Context())
	data, err := s.dashboardViewData(r.Context(), staff)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "dashboard/index", "dashboard.title", "dashboard", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "dashboard/index", "dashboard.title", "dashboard", data, "")
}

func (s *Server) AdminNavigation(w http.ResponseWriter, r *http.Request) {
	data := NewAdminNavigationPageViewData(staffFromContext(r.Context()))
	s.renderPage(w, http.StatusOK, r, "navigation/index", "navigation.title", "navigation", data, "")
}

func (s *Server) FeedQualityDashboard(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	filters := parseFeedQualityFilters(r)
	data := NewFeedQualityDashboardViewData(app.FeedQualityDashboardPage{}, filters)
	if s.moderation == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "feed_quality/index", "feedQuality.title", "feed_quality", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	page, err := s.moderation.FeedQualityDashboard(r.Context(), staff, feedQualityDashboardInput(filters, time.Now().UTC()))
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "feed_quality/index", "feedQuality.title", "feed_quality", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "feed_quality/index", "feedQuality.title", "feed_quality", NewFeedQualityDashboardViewData(page, filters), "")
}

func parseFeedQualityFilters(r *http.Request) FeedQualityFilterViewData {
	query := r.URL.Query()
	return normalizeFeedQualityFilterView(FeedQualityFilterViewData{
		Surface: query.Get("surface"),
		Window:  query.Get("window"),
	})
}

func feedQualityDashboardInput(filters FeedQualityFilterViewData, now time.Time) app.FeedQualityDashboardInput {
	if now.IsZero() {
		now = time.Now().UTC()
	}
	until := now.UTC()
	window := 7 * 24 * time.Hour
	switch filters.Window {
	case "24h":
		window = 24 * time.Hour
	case "30d":
		window = 30 * 24 * time.Hour
	}
	return app.FeedQualityDashboardInput{
		Since:   until.Add(-window),
		Until:   until,
		Surface: filters.Surface,
		Limit:   50,
	}
}

func (s *Server) AdminUserList(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	filter, viewFilter, err := parseAdminUsersListFilter(r)
	if err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "users/index", "users.title", "users", NewAdminUsersListViewData(model.AdminUserListPage{}, viewFilter, staff), publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	page, err := s.users.ListAdminUsers(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "users/index", "users.title", "users", NewAdminUsersListViewData(model.AdminUserListPage{}, viewFilter, staff), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "users/index", "users.title", "users", NewAdminUsersListViewData(page, viewFilter, staff), "")
}

func (s *Server) AdminUserDetail(w http.ResponseWriter, r *http.Request) {
	userID, ok := parsePathUUID(w, r, "userID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	page, err := s.users.GetAdminUserDetail(r.Context(), staff, userID, requestMetadata(r))
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "users/detail", "users.detailTitle", "users", NewAdminUserDetailViewData(model.AdminUserDetailPage{}, staff), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "users/detail", "users.detailTitle", "users", NewAdminUserDetailViewData(page, staff), "")
}

func (s *Server) CreateUserModerationCase(w http.ResponseWriter, r *http.Request) {
	userID, ok := parsePathUUID(w, r, "userID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	_, err := s.users.CreateUserModerationCase(r.Context(), staff, model.CreateUserModerationCaseParams{
		TargetUserID: userID,
		Source:       model.UserModerationSourceStaff,
		ReasonCode:   r.Form.Get("reason_code"),
		Priority:     model.UserModerationPriority(strings.ToUpper(strings.TrimSpace(r.Form.Get("priority")))),
		StaffComment: r.Form.Get("staff_comment"),
	}, requestMetadata(r))
	if err != nil {
		s.renderUserDetailError(w, r, userID, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(adminUserDetailURL(userID), "users.caseCreated"), http.StatusSeeOther)
}

func (s *Server) ResolveUserModerationCase(w http.ResponseWriter, r *http.Request) {
	userID, ok := parsePathUUID(w, r, "userID")
	if !ok {
		return
	}
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	_, err := s.users.ResolveUserModerationCase(r.Context(), staff, model.ResolveUserModerationCaseParams{
		CaseID:       caseID,
		Decision:     model.UserModerationDecision(strings.ToUpper(strings.TrimSpace(r.Form.Get("decision")))),
		ReasonCode:   r.Form.Get("reason_code"),
		StaffComment: r.Form.Get("staff_comment"),
	}, requestMetadata(r))
	if err != nil {
		s.renderUserDetailError(w, r, userID, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(adminUserDetailURL(userID), "users.caseResolved"), http.StatusSeeOther)
}

func (s *Server) CreateUserRestriction(w http.ResponseWriter, r *http.Request) {
	userID, ok := parsePathUUID(w, r, "userID")
	if !ok {
		return
	}
	caseID, err := parseOptionalUUIDForm(r, "case_id")
	if err != nil {
		s.renderUserDetailError(w, r, userID, app.ErrInvalidInput)
		return
	}
	expiresAt, err := parseOptionalTimeForm(r, "expires_at")
	if err != nil {
		s.renderUserDetailError(w, r, userID, app.ErrInvalidInput)
		return
	}
	staff := staffFromContext(r.Context())
	_, err = s.users.CreateUserRestriction(r.Context(), staff, model.CreateUserRestrictionParams{
		UserID:          userID,
		CaseID:          caseID,
		RestrictionCode: model.UserRestrictionCode(strings.ToUpper(strings.TrimSpace(r.Form.Get("restriction_code")))),
		ReasonCode:      r.Form.Get("reason_code"),
		StaffComment:    r.Form.Get("staff_comment"),
		ExpiresAt:       expiresAt,
	}, requestMetadata(r))
	if err != nil {
		s.renderUserDetailError(w, r, userID, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(adminUserDetailURL(userID), "users.restrictionCreated"), http.StatusSeeOther)
}

func (s *Server) LiftUserRestriction(w http.ResponseWriter, r *http.Request) {
	userID, ok := parsePathUUID(w, r, "userID")
	if !ok {
		return
	}
	restrictionID, ok := parsePathUUID(w, r, "restrictionID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	_, err := s.users.LiftUserRestriction(r.Context(), staff, model.LiftUserRestrictionParams{
		RestrictionID: restrictionID,
		ReasonCode:    r.Form.Get("reason_code"),
		StaffComment:  r.Form.Get("staff_comment"),
	}, requestMetadata(r))
	if err != nil {
		s.renderUserDetailError(w, r, userID, err)
		return
	}
	http.Redirect(w, r, redirectWithFlash(adminUserDetailURL(userID), "users.restrictionLifted"), http.StatusSeeOther)
}

func (s *Server) renderUserDetailError(w http.ResponseWriter, r *http.Request, userID uuid.UUID, err error) {
	staff := staffFromContext(r.Context())
	viewData := NewAdminUserDetailViewData(model.AdminUserDetailPage{}, staff)
	if userID != uuid.Nil {
		if page, detailErr := s.users.GetAdminUserDetail(r.Context(), staff, userID, requestMetadata(r)); detailErr == nil {
			viewData = NewAdminUserDetailViewData(page, staff)
		}
	}
	s.renderPage(w, errorStatus(err), r, "users/detail", "users.detailTitle", "users", viewData, publicError(localeFromContext(r.Context()), err))
}

func (s *Server) StaffProfile(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	events, err := s.audit.ListOwn(r.Context(), staff, model.AuditFilter{Limit: 50})
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "staff/profile", "staff.profileTitle", "profile", NewStaffProfileViewData(localeFromContext(r.Context()), staff, nil), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "staff/profile", "staff.profileTitle", "profile", NewStaffProfileViewData(localeFromContext(r.Context()), staff, events), "")
}

func (s *Server) UpdateOwnTimezone(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	if err := s.staff.UpdateOwnTimezone(r.Context(), staff, app.UpdateOwnTimezoneInput{
		Timezone: r.Form.Get("timezone"),
		Metadata: requestMetadata(r),
	}); err != nil {
		events, _ := s.audit.ListOwn(r.Context(), staff, model.AuditFilter{Limit: 50})
		s.renderPage(w, errorStatus(err), r, "staff/profile", "staff.profileTitle", "profile", NewStaffProfileViewData(localeFromContext(r.Context()), staff, events), publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash("/admin/me", "staff.timezoneUpdated"), http.StatusSeeOther)
}

func (s *Server) dashboardViewData(ctx context.Context, staff *model.StaffUser) (DashboardViewData, error) {
	if staff == nil || !staff.HasPermission(enum.PermissionModerationRead) {
		return NewDashboardViewData(nil, nil, nil, nil), nil
	}
	excursions, err := s.latestDashboardCases(ctx, staff, model.ModerationTargetExcursion)
	if err != nil {
		return NewDashboardViewData(nil, nil, nil, nil), err
	}
	activities, err := s.latestDashboardCases(ctx, staff, model.ModerationTargetActivity)
	if err != nil {
		return NewDashboardViewData(excursions, nil, nil, nil), err
	}
	guideApplications, err := s.latestDashboardCases(ctx, staff, model.ModerationTargetGuideApplication)
	if err != nil {
		return NewDashboardViewData(excursions, activities, nil, nil), err
	}
	chatMessages, err := s.latestDashboardCases(ctx, staff, model.ModerationTargetChatMessage)
	if err != nil {
		return NewDashboardViewData(excursions, activities, guideApplications, nil), err
	}
	return NewDashboardViewData(excursions, activities, guideApplications, chatMessages), nil
}

func (s *Server) latestDashboardCases(ctx context.Context, staff *model.StaffUser, targetType model.ModerationTargetType) ([]*model.ModerationCase, error) {
	filter := model.ModerationQueueFilter{
		TargetType: &targetType,
		Statuses:   activeModerationCaseStatuses,
		Sort:       model.ModerationQueueSortOpenedDesc,
		Limit:      5,
	}
	return s.moderation.ListQueue(ctx, staff, filter)
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
	returnQuery := moderationQueueReturnQuery(r)
	staff := staffFromContext(r.Context())
	detail, err := s.moderation.GetCaseDetail(r.Context(), staff, caseID)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "moderation", NewCaseDetailViewData(nil, returnQuery), publicError(localeFromContext(r.Context()), err))
		return
	}
	if detail.Case == nil || detail.Case.TargetType != model.ModerationTargetExcursion {
		s.renderPage(w, http.StatusNotFound, r, "moderation/detail", "moderation.caseTitle", "moderation", NewCaseDetailViewData(detail, returnQuery), publicError(localeFromContext(r.Context()), app.ErrModerationCaseNotFound))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/detail", "moderation.caseTitle", "moderation", NewCaseDetailViewData(detail, returnQuery), "")
}

func (s *Server) ApproveExcursion(w http.ResponseWriter, r *http.Request) {
	s.decideExcursion(w, r, enum.ModerationDecisionApprove)
}

func (s *Server) RejectExcursion(w http.ResponseWriter, r *http.Request) {
	s.decideExcursion(w, r, enum.ModerationDecisionReject)
}

func (s *Server) SyncActivityQueue(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	if err := s.moderation.SyncActivityQueue(r.Context(), staff); err != nil {
		_, viewFilter := parseExcursionQueueFilter(r)
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.activityQueue", "activities", NewActivityQueueViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	redirectURL := "/admin/moderation/activities"
	if r.URL.RawQuery != "" {
		redirectURL += "?" + r.URL.RawQuery
	}
	http.Redirect(w, r, redirectWithFlash(redirectURL, "moderation.queueSynced"), http.StatusSeeOther)
}

func (s *Server) ActivityQueue(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	_ = s.moderation.SyncActivityQueue(r.Context(), staff)
	targetType := model.ModerationTargetActivity
	filter, viewFilter := parseExcursionQueueFilter(r)
	filter.TargetType = &targetType
	filter.Limit = 100
	cases, err := s.moderation.ListQueue(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.activityQueue", "activities", NewActivityQueueViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/queue", "moderation.activityQueue", "activities", NewActivityQueueViewData(cases, viewFilter), "")
}

func (s *Server) ActivityHistory(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	targetType := model.ModerationTargetActivity
	filter, viewFilter := parseExcursionHistoryFilter(r)
	filter.TargetType = &targetType
	filter.Limit = 100
	cases, err := s.moderation.ListQueue(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.activityHistory", "activities", NewActivityHistoryViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/queue", "moderation.activityHistory", "activities", NewActivityHistoryViewData(cases, viewFilter), "")
}

func (s *Server) ActivityCase(w http.ResponseWriter, r *http.Request) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	returnQuery := moderationQueueReturnQuery(r)
	staff := staffFromContext(r.Context())
	detail, err := s.moderation.GetCaseDetail(r.Context(), staff, caseID)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "activities", NewCaseDetailViewData(nil, returnQuery), publicError(localeFromContext(r.Context()), err))
		return
	}
	if detail.Case == nil || detail.Case.TargetType != model.ModerationTargetActivity {
		s.renderPage(w, http.StatusNotFound, r, "moderation/detail", "moderation.caseTitle", "activities", NewCaseDetailViewData(detail, returnQuery), publicError(localeFromContext(r.Context()), app.ErrModerationCaseNotFound))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/detail", "moderation.caseTitle", "activities", NewCaseDetailViewData(detail, returnQuery), "")
}

func (s *Server) ApproveActivity(w http.ResponseWriter, r *http.Request) {
	s.decideActivity(w, r, enum.ModerationDecisionApprove)
}

func (s *Server) RejectActivity(w http.ResponseWriter, r *http.Request) {
	s.decideActivity(w, r, enum.ModerationDecisionReject)
}

func (s *Server) SyncChatMessageQueue(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	if err := s.moderation.SyncChatMessageQueue(r.Context(), staff); err != nil {
		_, viewFilter := parseExcursionQueueFilter(r)
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.chatQueue", "chats", NewChatMessageQueueViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	redirectURL := "/admin/moderation/chats"
	if r.URL.RawQuery != "" {
		redirectURL += "?" + r.URL.RawQuery
	}
	http.Redirect(w, r, redirectWithFlash(redirectURL, "moderation.queueSynced"), http.StatusSeeOther)
}

func (s *Server) ChatMessageQueue(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	_ = s.moderation.SyncChatMessageQueue(r.Context(), staff)
	targetType := model.ModerationTargetChatMessage
	filter, viewFilter := parseExcursionQueueFilter(r)
	filter.TargetType = &targetType
	filter.Limit = 100
	cases, err := s.moderation.ListQueue(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.chatQueue", "chats", NewChatMessageQueueViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/queue", "moderation.chatQueue", "chats", NewChatMessageQueueViewData(cases, viewFilter), "")
}

func (s *Server) ChatMessageHistory(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	targetType := model.ModerationTargetChatMessage
	filter, viewFilter := parseExcursionHistoryFilter(r)
	filter.TargetType = &targetType
	filter.Limit = 100
	cases, err := s.moderation.ListQueue(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.chatHistory", "chats", NewChatMessageHistoryViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/queue", "moderation.chatHistory", "chats", NewChatMessageHistoryViewData(cases, viewFilter), "")
}

func (s *Server) ChatMessageCase(w http.ResponseWriter, r *http.Request) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	returnQuery := moderationQueueReturnQuery(r)
	staff := staffFromContext(r.Context())
	detail, err := s.moderation.GetCaseDetail(r.Context(), staff, caseID)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "chats", NewCaseDetailViewData(nil, returnQuery), publicError(localeFromContext(r.Context()), err))
		return
	}
	if detail.Case == nil || detail.Case.TargetType != model.ModerationTargetChatMessage {
		s.renderPage(w, http.StatusNotFound, r, "moderation/detail", "moderation.caseTitle", "chats", NewCaseDetailViewData(detail, returnQuery), publicError(localeFromContext(r.Context()), app.ErrModerationCaseNotFound))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/detail", "moderation.caseTitle", "chats", NewCaseDetailViewData(detail, returnQuery), "")
}

func (s *Server) ApproveChatMessage(w http.ResponseWriter, r *http.Request) {
	s.decideChatMessage(w, r, enum.ModerationDecisionApprove)
}

func (s *Server) RejectChatMessage(w http.ResponseWriter, r *http.Request) {
	s.decideChatMessage(w, r, enum.ModerationDecisionReject)
}

func (s *Server) SyncPostReportQueue(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	if err := s.moderation.SyncPostReportQueue(r.Context(), staff); err != nil {
		_, viewFilter := parseExcursionQueueFilter(r)
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.postReportQueue", "posts", NewPostReportQueueViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	redirectURL := "/admin/moderation/posts"
	if r.URL.RawQuery != "" {
		redirectURL += "?" + r.URL.RawQuery
	}
	http.Redirect(w, r, redirectWithFlash(redirectURL, "moderation.queueSynced"), http.StatusSeeOther)
}

func (s *Server) PostReportQueue(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	_ = s.moderation.SyncPostReportQueue(r.Context(), staff)
	targetType := model.ModerationTargetPost
	filter, viewFilter := parseExcursionQueueFilter(r)
	filter.TargetType = &targetType
	filter.Limit = 100
	cases, err := s.moderation.ListQueue(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.postReportQueue", "posts", NewPostReportQueueViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/queue", "moderation.postReportQueue", "posts", NewPostReportQueueViewData(cases, viewFilter), "")
}

func (s *Server) PostReportHistory(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	targetType := model.ModerationTargetPost
	filter, viewFilter := parseExcursionHistoryFilter(r)
	filter.TargetType = &targetType
	filter.Limit = 100
	cases, err := s.moderation.ListQueue(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.postReportHistory", "posts", NewPostReportHistoryViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/queue", "moderation.postReportHistory", "posts", NewPostReportHistoryViewData(cases, viewFilter), "")
}

func (s *Server) PostReportCase(w http.ResponseWriter, r *http.Request) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	returnQuery := moderationQueueReturnQuery(r)
	staff := staffFromContext(r.Context())
	detail, err := s.moderation.GetCaseDetail(r.Context(), staff, caseID)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "posts", NewCaseDetailViewData(nil, returnQuery), publicError(localeFromContext(r.Context()), err))
		return
	}
	if detail.Case == nil || detail.Case.TargetType != model.ModerationTargetPost {
		s.renderPage(w, http.StatusNotFound, r, "moderation/detail", "moderation.caseTitle", "posts", NewCaseDetailViewData(detail, returnQuery), publicError(localeFromContext(r.Context()), app.ErrModerationCaseNotFound))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/detail", "moderation.caseTitle", "posts", NewCaseDetailViewData(detail, returnQuery), "")
}

func (s *Server) ApprovePostReport(w http.ResponseWriter, r *http.Request) {
	s.decidePostReport(w, r, enum.ModerationDecisionApprove)
}

func (s *Server) RejectPostReport(w http.ResponseWriter, r *http.Request) {
	s.decidePostReport(w, r, enum.ModerationDecisionReject)
}

func (s *Server) SyncGuideApplicationQueue(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	if err := s.moderation.SyncGuideApplicationQueue(r.Context(), staff); err != nil {
		_, viewFilter := parseExcursionQueueFilter(r)
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.guideApplicationQueue", "guides", NewGuideApplicationQueueViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	redirectURL := "/admin/moderation/guides"
	if r.URL.RawQuery != "" {
		redirectURL += "?" + r.URL.RawQuery
	}
	http.Redirect(w, r, redirectWithFlash(redirectURL, "moderation.queueSynced"), http.StatusSeeOther)
}

func (s *Server) GuideApplicationQueue(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	_ = s.moderation.SyncGuideApplicationQueue(r.Context(), staff)
	targetType := model.ModerationTargetGuideApplication
	filter, viewFilter := parseExcursionQueueFilter(r)
	filter.TargetType = &targetType
	filter.Limit = 100
	cases, err := s.moderation.ListQueue(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.guideApplicationQueue", "guides", NewGuideApplicationQueueViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/queue", "moderation.guideApplicationQueue", "guides", NewGuideApplicationQueueViewData(cases, viewFilter), "")
}

func (s *Server) ExcursionFraudBlocks(w http.ResponseWriter, r *http.Request) {
	s.renderFraudBlocks(w, r, model.FraudBlockTargetExcursion, "moderation")
}

func (s *Server) ActivityFraudBlocks(w http.ResponseWriter, r *http.Request) {
	s.renderFraudBlocks(w, r, model.FraudBlockTargetActivity, "activities")
}

func (s *Server) GuideFraudBlocks(w http.ResponseWriter, r *http.Request) {
	s.renderFraudBlocks(w, r, model.FraudBlockTargetGuideApplication, "guides")
}

func (s *Server) ConfirmExcursionFraudBlock(w http.ResponseWriter, r *http.Request) {
	s.reviewFraudBlock(w, r, model.FraudBlockTargetExcursion, model.FraudBlockReviewStatusConfirmedFraud, "moderation")
}

func (s *Server) FalsePositiveExcursionFraudBlock(w http.ResponseWriter, r *http.Request) {
	s.reviewFraudBlock(w, r, model.FraudBlockTargetExcursion, model.FraudBlockReviewStatusFalsePositive, "moderation")
}

func (s *Server) EscalateExcursionFraudBlock(w http.ResponseWriter, r *http.Request) {
	s.reviewFraudBlock(w, r, model.FraudBlockTargetExcursion, model.FraudBlockReviewStatusEscalated, "moderation")
}

func (s *Server) ConfirmActivityFraudBlock(w http.ResponseWriter, r *http.Request) {
	s.reviewFraudBlock(w, r, model.FraudBlockTargetActivity, model.FraudBlockReviewStatusConfirmedFraud, "activities")
}

func (s *Server) FalsePositiveActivityFraudBlock(w http.ResponseWriter, r *http.Request) {
	s.reviewFraudBlock(w, r, model.FraudBlockTargetActivity, model.FraudBlockReviewStatusFalsePositive, "activities")
}

func (s *Server) EscalateActivityFraudBlock(w http.ResponseWriter, r *http.Request) {
	s.reviewFraudBlock(w, r, model.FraudBlockTargetActivity, model.FraudBlockReviewStatusEscalated, "activities")
}

func (s *Server) ConfirmGuideFraudBlock(w http.ResponseWriter, r *http.Request) {
	s.reviewFraudBlock(w, r, model.FraudBlockTargetGuideApplication, model.FraudBlockReviewStatusConfirmedFraud, "guides")
}

func (s *Server) FalsePositiveGuideFraudBlock(w http.ResponseWriter, r *http.Request) {
	s.reviewFraudBlock(w, r, model.FraudBlockTargetGuideApplication, model.FraudBlockReviewStatusFalsePositive, "guides")
}

func (s *Server) EscalateGuideFraudBlock(w http.ResponseWriter, r *http.Request) {
	s.reviewFraudBlock(w, r, model.FraudBlockTargetGuideApplication, model.FraudBlockReviewStatusEscalated, "guides")
}

func (s *Server) renderFraudBlocks(w http.ResponseWriter, r *http.Request, target model.FraudBlockTarget, activeNav string) {
	staff := staffFromContext(r.Context())
	blocks, err := s.fraud.ListBlocks(r.Context(), staff, target, 100, 0)
	data := NewFraudBlockListViewData(target, blocks)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "fraud/blocks", "fraud.blocksTitle", activeNav, data, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "fraud/blocks", "fraud.blocksTitle", activeNav, data, "")
}

func (s *Server) reviewFraudBlock(w http.ResponseWriter, r *http.Request, target model.FraudBlockTarget, status model.FraudBlockReviewStatus, activeNav string) {
	assessmentID, ok := parsePathUUID(w, r, "assessmentID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	_, err := s.fraud.ReviewBlock(r.Context(), app.ReviewFraudBlockInput{
		Actor:           staff,
		AssessmentID:    assessmentID,
		Status:          status,
		ReasonCodes:     splitCSV(r.Form.Get("reason_codes")),
		InternalComment: r.Form.Get("internal_comment"),
		RequestMetadata: requestMetadata(r),
	})
	if err != nil {
		blocks, _ := s.fraud.ListBlocks(r.Context(), staff, target, 100, 0)
		s.renderPage(w, errorStatus(err), r, "fraud/blocks", "fraud.blocksTitle", activeNav, NewFraudBlockListViewData(target, blocks), publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(fraudBlockBaseURL(target), "fraud.blockReviewed"), http.StatusSeeOther)
}

func (s *Server) GuideApplicationHistory(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	targetType := model.ModerationTargetGuideApplication
	filter, viewFilter := parseExcursionHistoryFilter(r)
	filter.TargetType = &targetType
	filter.Limit = 100
	cases, err := s.moderation.ListQueue(r.Context(), staff, filter)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/queue", "moderation.guideApplicationHistory", "guides", NewGuideApplicationHistoryViewData(nil, viewFilter), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/queue", "moderation.guideApplicationHistory", "guides", NewGuideApplicationHistoryViewData(cases, viewFilter), "")
}

func (s *Server) ActiveGuideList(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	items, err := s.moderation.ListActiveGuides(r.Context(), staff, 100, 0)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "guides/index", "guides.currentTitle", "guides", NewGuideListViewData(nil), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "guides/index", "guides.currentTitle", "guides", NewGuideListViewData(items), "")
}

func (s *Server) GuideApplicationCase(w http.ResponseWriter, r *http.Request) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	returnQuery := moderationQueueReturnQuery(r)
	staff := staffFromContext(r.Context())
	detail, err := s.moderation.GetCaseDetail(r.Context(), staff, caseID)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "guides", NewCaseDetailViewData(nil, returnQuery), publicError(localeFromContext(r.Context()), err))
		return
	}
	if detail.Case == nil || detail.Case.TargetType != model.ModerationTargetGuideApplication {
		s.renderPage(w, http.StatusNotFound, r, "moderation/detail", "moderation.caseTitle", "guides", NewCaseDetailViewData(detail, returnQuery), publicError(localeFromContext(r.Context()), app.ErrModerationCaseNotFound))
		return
	}
	s.renderPage(w, http.StatusOK, r, "moderation/detail", "moderation.caseTitle", "guides", NewCaseDetailViewData(detail, returnQuery), "")
}

func (s *Server) GuideApplicationDocument(w http.ResponseWriter, r *http.Request) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	documentID, ok := parsePathUUID(w, r, "documentID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	detail, err := s.moderation.GetCaseDetail(r.Context(), staff, caseID)
	if err != nil {
		http.Error(w, publicError(localeFromContext(r.Context()), err), errorStatus(err))
		return
	}
	if detail.Case == nil || detail.Case.TargetType != model.ModerationTargetGuideApplication || detail.GuideApplication == nil {
		http.Error(w, publicError(localeFromContext(r.Context()), app.ErrModerationCaseNotFound), http.StatusNotFound)
		return
	}
	document, found := findGuideApplicationDocument(detail.GuideApplication.Documents, documentID)
	if !found || strings.TrimSpace(document.DownloadURL) == "" {
		http.Error(w, translate(localeFromContext(r.Context()), "error.documentNotFound"), http.StatusNotFound)
		return
	}
	if err = proxyGuideApplicationDocument(w, r, document); err != nil {
		http.Error(w, translate(localeFromContext(r.Context()), "error.documentUnavailable"), http.StatusBadGateway)
		return
	}
}

func (s *Server) ApproveGuideApplication(w http.ResponseWriter, r *http.Request) {
	s.decideGuideApplication(w, r, enum.ModerationDecisionApprove)
}

func (s *Server) RejectGuideApplication(w http.ResponseWriter, r *http.Request) {
	s.decideGuideApplication(w, r, enum.ModerationDecisionReject)
}

func (s *Server) RevokeGuideApplication(w http.ResponseWriter, r *http.Request) {
	s.decideGuideApplication(w, r, enum.ModerationDecisionRevoke)
}

func (s *Server) RevokeActiveGuide(w http.ResponseWriter, r *http.Request) {
	guideProfileID, ok := parsePathUUID(w, r, "guideProfileID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	_, err := s.moderation.RevokeActiveGuide(r.Context(), app.RevokeActiveGuideInput{
		Actor:           staff,
		GuideProfileID:  guideProfileID,
		ReasonCodes:     splitCSV(r.Form.Get("reason_codes")),
		PublicComment:   r.Form.Get("public_comment"),
		InternalComment: r.Form.Get("internal_comment"),
		IdempotencyKey:  r.Form.Get("idempotency_key"),
		RequestMetadata: requestMetadata(r),
	})
	if err != nil {
		items, _ := s.moderation.ListActiveGuides(r.Context(), staff, 100, 0)
		s.renderPage(w, errorStatus(err), r, "guides/index", "guides.currentTitle", "guides", NewGuideListViewData(items), publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash("/admin/moderation/guides/current", "moderation.decisionSaved"), http.StatusSeeOther)
}

func (s *Server) PlaceList(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	filters := placeListQuery(r.URL.Query())
	items, total, err := s.places.ListPlaces(r.Context(), staff, model.AdminPlaceFilter{
		Search:      filters.Search,
		Locale:      localeFromContext(r.Context()),
		Category:    filters.Category,
		CountryCode: filters.CountryCode,
		CityID:      filters.CityID,
		Status:      filters.Status,
		Limit:       placeListPageSize,
		Offset:      (filters.Page - 1) * placeListPageSize,
	})
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "places/index", "place.title", "places", NewPlaceListViewData(nil, 0, filters), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "places/index", "place.title", "places", NewPlaceListViewData(items, total, filters), "")
}

func (s *Server) NewPlacePage(w http.ResponseWriter, r *http.Request) {
	if staff := staffFromContext(r.Context()); staff == nil || !staff.HasPermission(enum.PermissionPlaceManage) {
		s.renderPage(w, http.StatusForbidden, r, "places/form", "place.createTitle", "places", NewPlaceFormViewData(nil, placeInputFromItem(nil)), publicError(localeFromContext(r.Context()), app.ErrPermissionDenied))
		return
	}
	data := NewPlaceFormViewData(nil, placeInputFromItem(nil))
	s.renderPage(w, http.StatusOK, r, "places/form", "place.createTitle", "places", data, "")
}

func (s *Server) CreatePlace(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	input, images, err := parsePlaceForm(r)
	if err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "places/form", "place.createTitle", "places", NewPlaceFormViewData(nil, input), publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	item, err := s.places.CreatePlace(r.Context(), staff, input, requestMetadata(r))
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "places/form", "place.createTitle", "places", NewPlaceFormViewData(nil, input), publicError(localeFromContext(r.Context()), err))
		return
	}
	if len(images) > 0 && item != nil {
		metadata := requestMetadata(r)
		for i := range images {
			images[i].Metadata = metadata
		}
		if err = s.places.ReplaceCarouselImages(r.Context(), staff, item.ID, images); err != nil {
			s.renderPage(w, errorStatus(err), r, "places/form", "place.editTitle", "places", NewPlaceFormViewData(item, input), publicError(localeFromContext(r.Context()), err))
			return
		}
	}
	http.Redirect(w, r, redirectWithFlash("/admin/places", "place.created"), http.StatusSeeOther)
}

func (s *Server) EditPlacePage(w http.ResponseWriter, r *http.Request) {
	placeID, ok := parsePathUUID(w, r, "placeID")
	if !ok {
		return
	}
	returnQuery := placeListQuery(r.URL.Query()).ReturnQuery
	listURL := placeListURL(returnQuery)
	staff := staffFromContext(r.Context())
	item, err := s.places.GetPlace(r.Context(), staff, placeID)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "places/form", "place.editTitle", "places", NewPlaceFormViewData(nil, model.PlaceInput{}, listURL), publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "places/form", "place.editTitle", "places", NewPlaceFormViewData(item, model.PlaceInput{}, listURL), "")
}

func (s *Server) UpdatePlace(w http.ResponseWriter, r *http.Request) {
	placeID, ok := parsePathUUID(w, r, "placeID")
	if !ok {
		return
	}
	returnQuery := placeListQuery(r.URL.Query()).ReturnQuery
	listURL := placeListURL(returnQuery)
	staff := staffFromContext(r.Context())
	input, _, err := parsePlaceForm(r)
	if err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "places/form", "place.editTitle", "places", NewPlaceFormViewData(&model.AdminPlace{ID: placeID}, input, listURL), publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	item, err := s.places.UpdatePlace(r.Context(), staff, placeID, input, requestMetadata(r))
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "places/form", "place.editTitle", "places", NewPlaceFormViewData(&model.AdminPlace{ID: placeID}, input, listURL), publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(placeEditURL(item.ID, returnQuery), "place.updated"), http.StatusSeeOther)
}

func (s *Server) ReplacePlaceMedia(w http.ResponseWriter, r *http.Request) {
	placeID, ok := parsePathUUID(w, r, "placeID")
	if !ok {
		return
	}
	returnQuery := placeListQuery(r.URL.Query()).ReturnQuery
	listURL := placeListURL(returnQuery)
	staff := staffFromContext(r.Context())
	if err := parseRequestForm(r); err != nil {
		item, _ := s.places.GetPlace(r.Context(), staff, placeID)
		s.renderPage(w, http.StatusBadRequest, r, "places/form", "place.editTitle", "places", NewPlaceFormViewData(item, model.PlaceInput{}, listURL), publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	images, err := parsePlaceImages(r)
	if err != nil {
		item, _ := s.places.GetPlace(r.Context(), staff, placeID)
		s.renderPage(w, http.StatusBadRequest, r, "places/form", "place.editTitle", "places", NewPlaceFormViewData(item, model.PlaceInput{}, listURL), publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	existingMediaIDs, err := parseUUIDValues(r.Form["media_ids"])
	if err != nil {
		item, _ := s.places.GetPlace(r.Context(), staff, placeID)
		s.renderPage(w, http.StatusBadRequest, r, "places/form", "place.editTitle", "places", NewPlaceFormViewData(item, model.PlaceInput{}, listURL), publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	deleteMediaIDs, err := parseUUIDValues(r.Form["delete_media_ids"])
	if err != nil {
		item, _ := s.places.GetPlace(r.Context(), staff, placeID)
		s.renderPage(w, http.StatusBadRequest, r, "places/form", "place.editTitle", "places", NewPlaceFormViewData(item, model.PlaceInput{}, listURL), publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	metadata := requestMetadata(r)
	for i := range images {
		images[i].Metadata = metadata
	}
	if err = s.places.UpdateCarouselImages(r.Context(), staff, placeID, app.PlaceMediaUpdateInput{
		Action:           app.PlaceMediaAction(r.Form.Get("media_action")),
		ExistingMediaIDs: existingMediaIDs,
		DeleteMediaIDs:   deleteMediaIDs,
		Uploads:          images,
		Metadata:         metadata,
	}); err != nil {
		item, _ := s.places.GetPlace(r.Context(), staff, placeID)
		s.renderPage(w, errorStatus(err), r, "places/form", "place.editTitle", "places", NewPlaceFormViewData(item, model.PlaceInput{}, listURL), publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(placeEditURL(placeID, returnQuery), "place.mediaUpdated"), http.StatusSeeOther)
}

func (s *Server) PlaceMedia(w http.ResponseWriter, r *http.Request) {
	fileID, ok := parsePathUUID(w, r, "fileID")
	if !ok {
		return
	}
	content, err := s.places.GetPublicImageContent(r.Context(), staffFromContext(r.Context()), fileID)
	if err != nil {
		http.Error(w, publicError(localeFromContext(r.Context()), err), errorStatus(err))
		return
	}
	w.Header().Set("Content-Type", content.ContentType)
	w.Header().Set("Cache-Control", "private, max-age=300")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(content.Content)
}

func (s *Server) decideExcursion(w http.ResponseWriter, r *http.Request, decision enum.ModerationDecisionType) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	returnQuery := moderationQueueReturnQuery(r)
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
		viewData := NewCaseDetailViewData(nil, returnQuery)
		if detail, detailErr := s.moderation.GetCaseDetail(r.Context(), staff, caseID); detailErr == nil {
			viewData = NewCaseDetailViewData(detail, returnQuery)
		}
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "moderation", viewData, publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(queueURLWithQuery("/admin/moderation/excursions/"+caseID.String(), returnQuery), "moderation.decisionSaved"), http.StatusSeeOther)
}

func (s *Server) decideActivity(w http.ResponseWriter, r *http.Request, decision enum.ModerationDecisionType) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	returnQuery := moderationQueueReturnQuery(r)
	staff := staffFromContext(r.Context())
	_, err := s.moderation.DecideActivity(r.Context(), app.ModerationDecisionInput{
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
		viewData := NewCaseDetailViewData(nil, returnQuery)
		if detail, detailErr := s.moderation.GetCaseDetail(r.Context(), staff, caseID); detailErr == nil {
			viewData = NewCaseDetailViewData(detail, returnQuery)
		}
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "activities", viewData, publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(queueURLWithQuery("/admin/moderation/activities/"+caseID.String(), returnQuery), "moderation.decisionSaved"), http.StatusSeeOther)
}

func (s *Server) decideChatMessage(w http.ResponseWriter, r *http.Request, decision enum.ModerationDecisionType) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	returnQuery := moderationQueueReturnQuery(r)
	staff := staffFromContext(r.Context())
	_, err := s.moderation.DecideChatMessage(r.Context(), app.ModerationDecisionInput{
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
		viewData := NewCaseDetailViewData(nil, returnQuery)
		if detail, detailErr := s.moderation.GetCaseDetail(r.Context(), staff, caseID); detailErr == nil {
			viewData = NewCaseDetailViewData(detail, returnQuery)
		}
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "chats", viewData, publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(queueURLWithQuery("/admin/moderation/chats/"+caseID.String(), returnQuery), "moderation.decisionSaved"), http.StatusSeeOther)
}

func (s *Server) decidePostReport(w http.ResponseWriter, r *http.Request, decision enum.ModerationDecisionType) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	returnQuery := moderationQueueReturnQuery(r)
	staff := staffFromContext(r.Context())
	_, err := s.moderation.DecidePostReport(r.Context(), app.ModerationDecisionInput{
		Actor:           staff,
		CaseID:          caseID,
		Decision:        decision,
		InternalComment: r.Form.Get("internal_comment"),
		IdempotencyKey:  r.Form.Get("idempotency_key"),
		RequestMetadata: requestMetadata(r),
	})
	if err != nil {
		viewData := NewCaseDetailViewData(nil, returnQuery)
		if detail, detailErr := s.moderation.GetCaseDetail(r.Context(), staff, caseID); detailErr == nil {
			viewData = NewCaseDetailViewData(detail, returnQuery)
		}
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "posts", viewData, publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(queueURLWithQuery("/admin/moderation/posts/"+caseID.String(), returnQuery), "moderation.decisionSaved"), http.StatusSeeOther)
}

func (s *Server) decideGuideApplication(w http.ResponseWriter, r *http.Request, decision enum.ModerationDecisionType) {
	caseID, ok := parsePathUUID(w, r, "caseID")
	if !ok {
		return
	}
	returnQuery := moderationQueueReturnQuery(r)
	staff := staffFromContext(r.Context())
	_, err := s.moderation.DecideGuideApplication(r.Context(), app.ModerationDecisionInput{
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
		viewData := NewCaseDetailViewData(nil, returnQuery)
		if detail, detailErr := s.moderation.GetCaseDetail(r.Context(), staff, caseID); detailErr == nil {
			viewData = NewCaseDetailViewData(detail, returnQuery)
		}
		s.renderPage(w, errorStatus(err), r, "moderation/detail", "moderation.caseTitle", "guides", viewData, publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash(queueURLWithQuery("/admin/moderation/guides/"+caseID.String(), returnQuery), "moderation.decisionSaved"), http.StatusSeeOther)
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

func (s *Server) renderLoginError(w http.ResponseWriter, status int, r *http.Request, messageKey string, email string) {
	locale := localeFromContext(r.Context())
	s.render(w, status, "auth/login", PageData{
		Title:  translate(locale, "login.title"),
		Locale: locale,
		Path:   r.URL.Path,
		Error:  translate(locale, messageKey),
		Data:   LoginViewData{Email: email},
	})
}

func loginErrorResponse(err error) (int, string) {
	switch {
	case errors.Is(err, app.ErrInvalidCredentials),
		errors.Is(err, app.ErrStaffDisabled),
		errors.Is(err, app.ErrStaffLocked):
		return http.StatusUnauthorized, "error.invalidCredentials"
	default:
		return http.StatusInternalServerError, "error.generic"
	}
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
		Title:            translate(locale, titleKey),
		Locale:           locale,
		Path:             r.URL.Path,
		Staff:            staffFromContext(r.Context()),
		CSRFToken:        csrfTokenFromContext(r.Context()),
		Error:            message,
		MaintenanceError: isMaintenanceErrorMessage(message),
		Flash:            flash,
		ActiveNav:        activeNav,
		Data:             data,
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

func parseAdminUsersListFilter(r *http.Request) (model.AdminUserListFilter, AdminUsersFilterViewData, error) {
	query := r.URL.Query()
	pageSize := 0
	if raw := strings.TrimSpace(query.Get("page_size")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil {
			return model.AdminUserListFilter{}, AdminUsersFilterViewData{}, err
		}
		pageSize = parsed
	}

	countryCode := firstNonEmpty(query.Get("country"), query.Get("country_code"))
	viewFilter := AdminUsersFilterViewData{
		Search:      strings.TrimSpace(query.Get("q")),
		Status:      strings.ToUpper(strings.TrimSpace(query.Get("status"))),
		Role:        strings.ToUpper(strings.TrimSpace(query.Get("role"))),
		CountryCode: strings.ToUpper(strings.TrimSpace(countryCode)),
		PageToken:   strings.TrimSpace(query.Get("page_token")),
		PageSize:    pageSize,
	}
	createdFrom, err := parseOptionalQueryDate(query.Get("created_from"), false)
	if err != nil {
		return model.AdminUserListFilter{}, viewFilter, err
	}
	createdTo, err := parseOptionalQueryDate(query.Get("created_to"), true)
	if err != nil {
		return model.AdminUserListFilter{}, viewFilter, err
	}
	lastActiveFrom, err := parseOptionalQueryDate(query.Get("last_active_from"), false)
	if err != nil {
		return model.AdminUserListFilter{}, viewFilter, err
	}
	lastActiveTo, err := parseOptionalQueryDate(query.Get("last_active_to"), true)
	if err != nil {
		return model.AdminUserListFilter{}, viewFilter, err
	}
	return model.AdminUserListFilter{
		PageSize:       pageSize,
		PageToken:      viewFilter.PageToken,
		Query:          viewFilter.Search,
		Status:         viewFilter.Status,
		Role:           viewFilter.Role,
		CountryCode:    viewFilter.CountryCode,
		CreatedFrom:    createdFrom,
		CreatedTo:      createdTo,
		LastActiveFrom: lastActiveFrom,
		LastActiveTo:   lastActiveTo,
	}, viewFilter, nil
}

func parseOptionalUUIDForm(r *http.Request, name string) (*uuid.UUID, error) {
	raw := strings.TrimSpace(r.Form.Get(name))
	if raw == "" {
		return nil, nil
	}
	value, err := uuid.Parse(raw)
	if err != nil {
		return nil, err
	}
	return &value, nil
}

func parseOptionalTimeForm(r *http.Request, name string) (*time.Time, error) {
	raw := strings.TrimSpace(r.Form.Get(name))
	if raw == "" {
		return nil, nil
	}
	value, err := parseFlexibleTime(raw)
	if err != nil {
		return nil, err
	}
	return &value, nil
}

func parseOptionalQueryDate(raw string, endOfDay bool) (*time.Time, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}
	value, err := parseFlexibleTime(raw)
	if err != nil {
		return nil, err
	}
	if endOfDay && len(raw) == len("2006-01-02") {
		value = value.Add(24*time.Hour - time.Nanosecond)
	}
	return &value, nil
}

func parseFlexibleTime(raw string) (time.Time, error) {
	for _, layout := range []string{time.RFC3339, "2006-01-02T15:04", "2006-01-02"} {
		if value, err := time.Parse(layout, raw); err == nil {
			return value.UTC(), nil
		}
	}
	return time.Time{}, app.ErrInvalidInput
}

func adminUserDetailURL(userID uuid.UUID) string {
	return "/admin/users/" + userID.String()
}

func parsePlaceForm(r *http.Request) (model.PlaceInput, []app.PlaceImageUploadInput, error) {
	if err := parseRequestForm(r); err != nil {
		return model.PlaceInput{}, nil, err
	}

	latitude, err := parseOptionalFloat(r.Form.Get("latitude"))
	if err != nil {
		return model.PlaceInput{}, nil, err
	}
	longitude, err := parseOptionalFloat(r.Form.Get("longitude"))
	if err != nil {
		return model.PlaceInput{}, nil, err
	}
	locationSourceURL := r.Form.Get("location_source_url")
	if (latitude == nil || longitude == nil) && strings.TrimSpace(locationSourceURL) != "" {
		if parsedLatitude, parsedLongitude, ok := coordinatesFromMapURL(locationSourceURL); ok {
			if latitude == nil {
				latitude = parsedLatitude
			}
			if longitude == nil {
				longitude = parsedLongitude
			}
		}
	}
	priceAmount, err := parseOptionalFloat(r.Form.Get("price_amount"))
	if err != nil {
		return model.PlaceInput{}, nil, err
	}
	durationValue, err := parseOptionalInt(r.Form.Get("duration_value"))
	if err != nil {
		return model.PlaceInput{}, nil, err
	}
	spots, err := parseOptionalInt(r.Form.Get("spots"))
	if err != nil {
		return model.PlaceInput{}, nil, err
	}

	defaultLocale := strings.TrimSpace(r.Form.Get("default_locale"))
	translations := map[string]model.PlaceTranslation{}
	for _, locale := range []string{"ru", "en", "kk"} {
		title := strings.TrimSpace(r.Form.Get("title_" + locale))
		description := strings.TrimSpace(r.Form.Get("description_" + locale))
		if title != "" || description != "" {
			translations[locale] = model.PlaceTranslation{
				Title:       title,
				Description: description,
			}
		}
	}
	defaultTranslation := translations[normalizeFormLocale(defaultLocale)]
	priceCurrency := optionalString(r.Form.Get("price_currency"))
	durationUnit := optionalString(r.Form.Get("duration_unit"))
	bookingRequired := optionalBool(r.Form.Get("booking_required"))
	visitInfo := &model.PlaceVisitInfo{
		BestTime:        strings.TrimSpace(r.Form.Get("visit_best_time")),
		Accessibility:   strings.TrimSpace(r.Form.Get("visit_accessibility")),
		BookingRequired: bookingRequired,
		OpeningHours:    strings.TrimSpace(r.Form.Get("visit_opening_hours")),
		Amenities:       splitCSV(r.Form.Get("visit_amenities")),
		Audience:        splitCSV(r.Form.Get("visit_audience")),
		SafetyNotes:     splitCSV(r.Form.Get("visit_safety_notes")),
	}
	input := model.PlaceInput{
		Title:             defaultTranslation.Title,
		Description:       defaultTranslation.Description,
		DefaultLocale:     defaultLocale,
		Translations:      translations,
		CountryCode:       r.Form.Get("country_code"),
		CityID:            r.Form.Get("city_id"),
		AccessCities:      parseCityLinkValues(r.Form["access_cities"], r.Form.Get("country_code")),
		DepartureCities:   parseCityLinkValues(r.Form["departure_cities"], r.Form.Get("country_code")),
		Latitude:          latitude,
		Longitude:         longitude,
		LocationSourceURL: locationSourceURL,
		Category:          r.Form.Get("category"),
		PriceAmount:       priceAmount,
		PriceCurrency:     priceCurrency,
		DurationValue:     durationValue,
		DurationUnit:      durationUnit,
		Spots:             spots,
		Status:            r.Form.Get("status"),
		Tags:              splitCSV(r.Form.Get("tags")),
		VisitInfo:         visitInfo,
	}
	images, err := parsePlaceImages(r)
	return input, images, err
}

func parsePlaceImages(r *http.Request) ([]app.PlaceImageUploadInput, error) {
	if err := parseRequestForm(r); err != nil {
		return nil, err
	}
	if r.MultipartForm == nil {
		return nil, nil
	}

	headers := make([]*multipart.FileHeader, 0)
	headers = append(headers, r.MultipartForm.File["media_images"]...)
	headers = append(headers, r.MultipartForm.File["cover_image"]...)
	if len(headers) == 0 {
		return nil, nil
	}
	if len(headers) > 10 {
		return nil, app.ErrInvalidInput
	}

	images := make([]app.PlaceImageUploadInput, 0, len(headers))
	for _, header := range headers {
		if header == nil {
			continue
		}
		image, err := readPlaceImage(header)
		if err != nil {
			return nil, err
		}
		images = append(images, image)
	}
	return images, nil
}

func readPlaceImage(header *multipart.FileHeader) (app.PlaceImageUploadInput, error) {
	file, err := header.Open()
	if err != nil {
		return app.PlaceImageUploadInput{}, err
	}
	defer file.Close()

	content, err := io.ReadAll(io.LimitReader(file, 25<<20))
	if err != nil {
		return app.PlaceImageUploadInput{}, err
	}
	if len(content) == 0 {
		return app.PlaceImageUploadInput{}, app.ErrInvalidInput
	}
	contentType := ""
	contentType = header.Header.Get("Content-Type")
	if strings.TrimSpace(contentType) == "" {
		contentType = http.DetectContentType(content)
	}
	return app.PlaceImageUploadInput{
		FileName:    header.Filename,
		ContentType: contentType,
		Content:     content,
	}, nil
}

func normalizeFormLocale(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "en", "kk":
		return strings.ToLower(strings.TrimSpace(raw))
	default:
		return "ru"
	}
}

func optionalString(raw string) *string {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil
	}
	return &raw
}

func optionalBool(raw string) *bool {
	raw = strings.ToLower(strings.TrimSpace(raw))
	if raw == "" {
		return nil
	}
	value := raw == "true" || raw == "1" || raw == "on" || raw == "yes"
	return &value
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

func parseUUIDValues(values []string) ([]uuid.UUID, error) {
	out := make([]uuid.UUID, 0, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		id, err := uuid.Parse(value)
		if err != nil {
			return nil, err
		}
		out = append(out, id)
	}
	return out, nil
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
	if errors.Is(err, app.ErrUserNotFound) {
		return translate(locale, "error.userNotFound")
	}
	if errors.Is(err, app.ErrPlaceNotFound) {
		return translate(locale, "error.placeNotFound")
	}
	if errors.Is(err, app.ErrOperationDomainNotFound) || errors.Is(err, app.ErrOperationResourceNotFound) {
		return translate(locale, "error.notFound")
	}
	if errors.Is(err, app.ErrIntegrationNotReady) {
		return translate(locale, "error.integrationNotReady")
	}
	if errors.Is(err, app.ErrTechnicalMaintenance) {
		return translate(locale, "error.maintenance")
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
	case errors.Is(err, app.ErrUserNotFound):
		return http.StatusNotFound
	case errors.Is(err, app.ErrPlaceNotFound):
		return http.StatusNotFound
	case errors.Is(err, app.ErrOperationDomainNotFound):
		return http.StatusNotFound
	case errors.Is(err, app.ErrOperationResourceNotFound):
		return http.StatusNotFound
	case errors.Is(err, app.ErrIntegrationNotReady):
		return http.StatusServiceUnavailable
	case errors.Is(err, app.ErrTechnicalMaintenance):
		return http.StatusServiceUnavailable
	case errors.Is(err, app.ErrDuplicateDecision):
		return http.StatusConflict
	case errors.Is(err, app.ErrModerationCaseConflict):
		return http.StatusConflict
	case errors.Is(err, app.ErrInvalidInput):
		return http.StatusBadRequest
	default:
		return http.StatusInternalServerError
	}
}

func isMaintenanceErrorMessage(message string) bool {
	message = strings.ToLower(strings.TrimSpace(message))
	return strings.Contains(message, "технические работы") ||
		strings.Contains(message, "maintenance")
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func findGuideApplicationDocument(documents []model.GuideApplicationDocument, documentID uuid.UUID) (model.GuideApplicationDocument, bool) {
	for _, document := range documents {
		if document.ID == documentID {
			return document, true
		}
	}
	return model.GuideApplicationDocument{}, false
}

func proxyGuideApplicationDocument(w http.ResponseWriter, r *http.Request, document model.GuideApplicationDocument) error {
	const maxDocumentSize = int64(25 << 20)
	downloadURL := safeExternalURL(document.DownloadURL)
	if downloadURL == "" {
		return errors.New("invalid document download url")
	}
	client := &http.Client{Timeout: 20 * time.Second}
	req, err := http.NewRequestWithContext(r.Context(), http.MethodGet, downloadURL, nil)
	if err != nil {
		return err
	}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return errors.New("document storage returned non-success status")
	}
	if resp.ContentLength > maxDocumentSize {
		return errors.New("document is too large")
	}
	contentType := strings.TrimSpace(resp.Header.Get("Content-Type"))
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Cache-Control", "private, no-store")
	w.Header().Set("Content-Disposition", `inline; filename="guide-document"`)
	if resp.ContentLength > 0 {
		w.Header().Set("Content-Length", resp.Header.Get("Content-Length"))
	}
	w.WriteHeader(http.StatusOK)
	_, err = io.Copy(w, io.LimitReader(resp.Body, maxDocumentSize))
	return err
}
