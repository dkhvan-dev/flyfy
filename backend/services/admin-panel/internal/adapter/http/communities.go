package http

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func (s *Server) CommunityPlatformPage(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	filters := parseCommunityPlatformFilters(r)
	locale := localeFromContext(r.Context())
	data := NewCommunityPlatformViewData(model.CommunityPlatformCatalog{}, filters, locale)
	if staff == nil || !staff.HasRole(enum.StaffRoleSuperAdmin) {
		s.renderPage(w, http.StatusForbidden, r, "communities/index", "community.platformTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrPermissionDenied))
		return
	}
	if s.communities == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "communities/index", "community.platformTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	catalog, err := s.communities.CommunityPlatformCatalog(r.Context(), staff, app.CommunityPlatformCatalogInput{
		CountryCode: filters.CountryCode,
		CityID:      filters.CityID,
		ScopeType:   filters.ScopeType,
		Search:      filters.Search,
		Limit:       filters.Limit,
		Offset:      filters.Offset,
	})
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "communities/index", "community.platformTitle", "communities", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "communities/index", "community.platformTitle", "communities", NewCommunityPlatformViewData(catalog, filters, locale), "")
}

func (s *Server) NewCommunityPage(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	data := NewCommunityFormViewData(CommunityFormInput{})
	if staff == nil || !staff.HasRole(enum.StaffRoleSuperAdmin) {
		s.renderPage(w, http.StatusForbidden, r, "communities/form", "community.createTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrPermissionDenied))
		return
	}
	if s.communities == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "communities/form", "community.createTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	s.renderPage(w, http.StatusOK, r, "communities/form", "community.createTitle", "communities", data, "")
}

func (s *Server) CreateCommunity(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	appInput, formInput, err := parseCommunityForm(r)
	data := NewCommunityFormViewData(formInput)
	if err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "communities/form", "community.createTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	if s.communities == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "communities/form", "community.createTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	avatarUpload, coverUpload, err := parseCommunityImages(r)
	if err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "communities/form", "community.createTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	appInput.RequestID = requestIDFromContext(r.Context())
	created, err := s.communities.CreateCommunity(r.Context(), staff, appInput)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "communities/form", "community.createTitle", "communities", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	if avatarUpload != nil || coverUpload != nil {
		if avatarUpload != nil {
			uploaded, uploadErr := s.communities.UploadCommunityImage(r.Context(), staff, created.ID, *avatarUpload)
			if uploadErr != nil {
				s.renderPage(w, errorStatus(uploadErr), r, "communities/form", "community.createTitle", "communities", data, publicError(localeFromContext(r.Context()), uploadErr))
				return
			}
			appInput.AvatarFileID = &uploaded.ID
		}
		if coverUpload != nil {
			uploaded, uploadErr := s.communities.UploadCommunityImage(r.Context(), staff, created.ID, *coverUpload)
			if uploadErr != nil {
				s.renderPage(w, errorStatus(uploadErr), r, "communities/form", "community.createTitle", "communities", data, publicError(localeFromContext(r.Context()), uploadErr))
				return
			}
			appInput.CoverFileID = &uploaded.ID
		}
		if _, err = s.communities.UpdateCommunity(r.Context(), staff, created.ID, appInput); err != nil {
			s.renderPage(w, errorStatus(err), r, "communities/form", "community.createTitle", "communities", data, publicError(localeFromContext(r.Context()), err))
			return
		}
	}
	http.Redirect(w, r, redirectWithFlash("/admin/communities/new", "community.created"), http.StatusSeeOther)
}

func (s *Server) EditCommunityPage(w http.ResponseWriter, r *http.Request) {
	communityID, ok := parsePathUUID(w, r, "communityID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	data := NewCommunityFormViewData(CommunityFormInput{}, &model.AdminCommunity{ID: communityID})
	if staff == nil || !staff.HasRole(enum.StaffRoleSuperAdmin) {
		s.renderPage(w, http.StatusForbidden, r, "communities/form", "community.editTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrPermissionDenied))
		return
	}
	if s.communities == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "communities/form", "community.editTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	item, err := s.communities.GetCommunity(r.Context(), staff, communityID)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "communities/form", "community.editTitle", "communities", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	s.renderPage(w, http.StatusOK, r, "communities/form", "community.editTitle", "communities", NewCommunityFormViewData(CommunityFormInput{}, &item), "")
}

func (s *Server) UpdateCommunity(w http.ResponseWriter, r *http.Request) {
	communityID, ok := parsePathUUID(w, r, "communityID")
	if !ok {
		return
	}
	staff := staffFromContext(r.Context())
	appInput, formInput, err := parseCommunityForm(r)
	data := NewCommunityFormViewData(formInput, &model.AdminCommunity{ID: communityID})
	if err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "communities/form", "community.editTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	if s.communities == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "communities/form", "community.editTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	existing, err := s.communities.GetCommunity(r.Context(), staff, communityID)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "communities/form", "community.editTitle", "communities", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	appInput.AvatarFileID = existing.AvatarFileID
	appInput.CoverFileID = existing.CoverFileID
	avatarUpload, coverUpload, err := parseCommunityImages(r)
	if err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "communities/form", "community.editTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	if avatarUpload != nil {
		uploaded, uploadErr := s.communities.UploadCommunityImage(r.Context(), staff, communityID, *avatarUpload)
		if uploadErr != nil {
			s.renderPage(w, errorStatus(uploadErr), r, "communities/form", "community.editTitle", "communities", data, publicError(localeFromContext(r.Context()), uploadErr))
			return
		}
		appInput.AvatarFileID = &uploaded.ID
	}
	if coverUpload != nil {
		uploaded, uploadErr := s.communities.UploadCommunityImage(r.Context(), staff, communityID, *coverUpload)
		if uploadErr != nil {
			s.renderPage(w, errorStatus(uploadErr), r, "communities/form", "community.editTitle", "communities", data, publicError(localeFromContext(r.Context()), uploadErr))
			return
		}
		appInput.CoverFileID = &uploaded.ID
	}
	appInput.RequestID = requestIDFromContext(r.Context())
	updated, err := s.communities.UpdateCommunity(r.Context(), staff, communityID, appInput)
	if err != nil {
		s.renderPage(w, errorStatus(err), r, "communities/form", "community.editTitle", "communities", NewCommunityFormViewData(formInput, &existing), publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash("/admin/communities/"+updated.ID.String()+"/edit", "community.updated"), http.StatusSeeOther)
}

func (s *Server) MaterializeCommunityInstances(w http.ResponseWriter, r *http.Request) {
	staff := staffFromContext(r.Context())
	input, filters, err := parseMaterializeCommunityInstancesForm(r)
	data := NewCommunityPlatformViewData(model.CommunityPlatformCatalog{}, filters, localeFromContext(r.Context()))
	if err != nil {
		s.renderPage(w, http.StatusBadRequest, r, "communities/index", "community.platformTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrInvalidInput))
		return
	}
	if staff == nil || !staff.HasRole(enum.StaffRoleSuperAdmin) {
		s.renderPage(w, http.StatusForbidden, r, "communities/index", "community.platformTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrPermissionDenied))
		return
	}
	if s.communities == nil {
		s.renderPage(w, http.StatusServiceUnavailable, r, "communities/index", "community.platformTitle", "communities", data, publicError(localeFromContext(r.Context()), app.ErrIntegrationNotReady))
		return
	}
	input.RequestID = requestIDFromContext(r.Context())
	if _, err = s.communities.MaterializeCommunityInstances(r.Context(), staff, input); err != nil {
		s.renderPage(w, errorStatus(err), r, "communities/index", "community.platformTitle", "communities", data, publicError(localeFromContext(r.Context()), err))
		return
	}
	http.Redirect(w, r, redirectWithFlash("/admin/communities", "community.instancesMaterialized"), http.StatusSeeOther)
}

func parseCommunityForm(r *http.Request) (app.CreateCommunityAdminInput, CommunityFormInput, error) {
	if err := parseRequestForm(r); err != nil {
		return app.CreateCommunityAdminInput{}, CommunityFormInput{}, err
	}
	form := CommunityFormInput{
		Slug:            strings.TrimSpace(r.Form.Get("slug")),
		TitleI18n:       localizedTextFormValues(r, "title"),
		DescriptionI18n: localizedTextFormValues(r, "description"),
		RulesTextI18n:   localizedTextFormValues(r, "rules"),
		Topic:           strings.TrimSpace(r.Form.Get("topic")),
		CityID:          strings.TrimSpace(r.Form.Get("city_id")),
		CountryCode:     strings.TrimSpace(r.Form.Get("country_code")),
		Visibility:      strings.TrimSpace(r.Form.Get("visibility")),
		PostingPolicy:   strings.TrimSpace(r.Form.Get("posting_policy")),
		Status:          strings.TrimSpace(r.Form.Get("status")),
	}
	return app.CreateCommunityAdminInput{
		Slug:            form.Slug,
		TitleI18n:       cloneFormTextMap(form.TitleI18n),
		DescriptionI18n: cloneFormTextMap(form.DescriptionI18n),
		RulesI18n:       localizedRulesFormValues(form.RulesTextI18n),
		Topic:           form.Topic,
		CityID:          optionalString(form.CityID),
		CountryCode:     optionalString(form.CountryCode),
		Visibility:      form.Visibility,
		PostingPolicy:   form.PostingPolicy,
		Status:          form.Status,
	}, form, nil
}

func parseCommunityImages(r *http.Request) (*app.CommunityImageUploadInput, *app.CommunityImageUploadInput, error) {
	if err := parseRequestForm(r); err != nil {
		return nil, nil, err
	}
	if r.MultipartForm == nil {
		return nil, nil, nil
	}
	avatar, err := readCommunityImageFromForm(r, "avatar_image")
	if err != nil {
		return nil, nil, err
	}
	cover, err := readCommunityImageFromForm(r, "cover_image")
	if err != nil {
		return nil, nil, err
	}
	return avatar, cover, nil
}

func readCommunityImageFromForm(r *http.Request, field string) (*app.CommunityImageUploadInput, error) {
	headers := r.MultipartForm.File[field]
	if len(headers) == 0 || headers[0] == nil {
		return nil, nil
	}
	if len(headers) > 1 {
		return nil, app.ErrInvalidInput
	}
	image, err := readPlaceImage(headers[0])
	if err != nil {
		return nil, err
	}
	return &app.CommunityImageUploadInput{
		FileName:    image.FileName,
		ContentType: image.ContentType,
		Content:     image.Content,
		Metadata:    requestMetadata(r),
	}, nil
}

func parseCommunityPlatformFilters(r *http.Request) CommunityPlatformFilterViewData {
	query := r.URL.Query()
	filters := CommunityPlatformFilterViewData{
		CountryCode: firstNonEmpty(query.Get("country_code"), query.Get("country")),
		CityID:      firstNonEmpty(query.Get("city_id"), query.Get("city")),
		ScopeType:   query.Get("scope_type"),
		Search:      query.Get("q"),
		Limit:       parseCommunityInt(query.Get("limit"), 50),
		Offset:      parseCommunityInt(query.Get("offset"), 0),
	}
	return normalizeCommunityPlatformFilters(filters)
}

func parseMaterializeCommunityInstancesForm(r *http.Request) (app.MaterializeCommunityInstancesInput, CommunityPlatformFilterViewData, error) {
	if err := parseRequestForm(r); err != nil {
		return app.MaterializeCommunityInstancesInput{}, CommunityPlatformFilterViewData{}, err
	}
	filters := normalizeCommunityPlatformFilters(CommunityPlatformFilterViewData{
		CountryCode: r.Form.Get("country_code"),
		CityID:      r.Form.Get("city_id"),
		ScopeType:   r.Form.Get("scope_type"),
		Limit:       50,
	})
	var blueprintID uuid.UUID
	if raw := strings.TrimSpace(r.Form.Get("blueprint_id")); raw != "" {
		parsed, err := uuid.Parse(raw)
		if err != nil {
			return app.MaterializeCommunityInstancesInput{}, filters, err
		}
		blueprintID = parsed
	}
	return app.MaterializeCommunityInstancesInput{
		BlueprintID: blueprintID,
		CountryCode: filters.CountryCode,
		CityID:      filters.CityID,
		ScopeType:   filters.ScopeType,
		Limit:       parseCommunityInt(r.Form.Get("limit"), 5000),
	}, filters, nil
}

func parseCommunityInt(raw string, fallback int) int {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return fallback
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		return fallback
	}
	return value
}

func localizedTextFormValues(r *http.Request, prefix string) map[string]string {
	out := make(map[string]string, len(communityFormLocales))
	for _, locale := range communityFormLocales {
		out[locale] = strings.TrimSpace(r.Form.Get(prefix + "_" + locale))
	}
	return out
}

func localizedRulesFormValues(input map[string]string) map[string][]string {
	out := make(map[string][]string, len(communityFormLocales))
	for _, locale := range communityFormLocales {
		out[locale] = splitLines(input[locale])
	}
	return out
}

func cloneFormTextMap(input map[string]string) map[string]string {
	out := make(map[string]string, len(input))
	for key, value := range input {
		out[key] = strings.TrimSpace(value)
	}
	return out
}

func splitLines(value string) []string {
	lines := strings.Split(value, "\n")
	out := make([]string, 0, len(lines))
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" {
			out = append(out, line)
		}
	}
	return out
}
