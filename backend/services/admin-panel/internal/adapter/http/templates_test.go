package http

import (
	"bytes"
	"encoding/json"
	"html"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

func TestRendererRendersCoreTemplates(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "moderator@flyfy.local",
		DisplayName: "Moderator",
		Status:      enum.StaffStatusActive,
	}
	caseID := uuid.New()
	excursionID := uuid.New()
	now := time.Now().UTC()
	baseData := PageData{
		Title:     "Test",
		Locale:    localeEN,
		Path:      "/admin",
		Staff:     staff,
		CSRFToken: "csrf-token",
	}

	queueCase := &model.ModerationCase{
		ID:             caseID,
		TargetType:     model.ModerationTargetExcursion,
		TargetID:       excursionID,
		SourceService:  "excursion-service",
		SourceRevision: 1,
		Status:         enum.ModerationCaseStatusOpen,
		Priority:       42,
		OpenedAt:       now,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
	queueSnapshot, err := json.Marshal(model.ExcursionModerationItem{
		ID:               excursionID,
		Title:            "Kok-Tobe + Cathedral",
		AttractionNames:  []string{"Kok-Tobe", "Cathedral"},
		GuideDisplayName: "Moderator Guide",
		GuideNickname:    "@nomad_aru",
		GuideFirstName:   "Aruzhan",
		GuideLastName:    "Khan",
		CountryCode:      "KZ",
		DepartureCityID:  "almaty",
	})
	if err != nil {
		t.Fatalf("json.Marshal snapshot returned error: %v", err)
	}
	queueCase.Snapshot = queueSnapshot
	templates := map[string]any{
		"auth/login":           LoginViewData{Email: "moderator@flyfy.local"},
		"auth/change_password": nil,
		"dashboard/index":      NewDashboardViewData([]*model.ModerationCase{queueCase}, nil, nil, nil),
		"moderation/queue": NewQueueViewData([]*model.ModerationCase{queueCase}, QueueFilterViewData{
			Status: excursionQueueStatusActive,
			City:   "Almaty",
			Search: "Kok",
			Signal: "new_guide",
			Risk:   string(model.ModerationRiskFilterHigh),
			Sort:   string(model.ModerationQueueSortRiskDesc),
			Query:  "status=active&city=Almaty&q=Kok&signal=new_guide&risk=high&sort=risk_desc",
		}),
		"staff/index": StaffListViewData{Staff: []*model.StaffUser{staff}},
		"audit/index": AuditViewData{Events: []*model.AuditEvent{}},
	}

	for name, data := range templates {
		t.Run(name, func(t *testing.T) {
			pageData := baseData
			pageData.Data = data
			recorder := httptest.NewRecorder()
			renderer.Render(recorder, http.StatusOK, name, pageData)
			if recorder.Code != http.StatusOK {
				t.Fatalf("unexpected status: %d", recorder.Code)
			}
			if !strings.Contains(recorder.Body.String(), "FlyFy") {
				t.Fatalf("rendered template %s does not contain shell content", name)
			}
			if name == "dashboard/index" {
				body := html.UnescapeString(recorder.Body.String())
				if !strings.Contains(body, "Kok-Tobe + Cathedral") ||
					!strings.Contains(body, "View all") {
					t.Fatalf("dashboard did not render latest moderation context: %s", body)
				}
				if strings.Contains(body, `class="metric card"`) {
					t.Fatal("dashboard still renders legacy metric navigation cards")
				}
			}
			if name == "moderation/queue" {
				body := html.UnescapeString(recorder.Body.String())
				if !strings.Contains(body, "Kok-Tobe + Cathedral") ||
					!strings.Contains(body, "@nomad_aru") ||
					!strings.Contains(body, "Khan Aruzhan") ||
					!strings.Contains(body, "Almaty, Kazakhstan") {
					t.Fatalf("moderation queue did not render useful excursion context: %s", body)
				}
				if strings.Contains(body, excursionID.String()) {
					t.Fatal("moderation queue rendered raw target id")
				}
				for _, expected := range []string{
					`name="status"`,
					`name="city"`,
					`name="q"`,
					`name="signal"`,
					`name="risk"`,
					`name="sort"`,
					`/admin/moderation/excursions/sync?status=active&amp;city=Almaty&amp;q=Kok&amp;signal=new_guide&amp;risk=high&amp;sort=risk_desc`,
					`/admin/moderation/excursions`,
				} {
					if !strings.Contains(recorder.Body.String(), expected) {
						t.Fatalf("moderation queue did not render filter control %q: %s", expected, recorder.Body.String())
					}
				}
			}
		})
	}
}

func TestRendererTopbarHidesAuditWithoutPermissionAndLinksOwnProfile(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	staff := adminTemplateActor()
	staff.Permissions = []enum.Permission{enum.PermissionDashboardRead}
	pageData := PageData{
		Title:     "Dashboard",
		Locale:    localeEN,
		Path:      "/admin",
		Staff:     staff,
		CSRFToken: "csrf-token",
		Data:      NewDashboardViewData(nil, nil, nil, nil),
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "dashboard/index", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := recorder.Body.String()
	if strings.Contains(body, `href="/admin/audit"`) {
		t.Fatalf("audit nav link rendered without audit.read permission: %s", body)
	}
	if !strings.Contains(body, `href="/admin/me"`) {
		t.Fatalf("own profile link is missing from topbar: %s", body)
	}

	staff.Permissions = append(staff.Permissions, enum.PermissionAuditRead)
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "dashboard/index", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	if !strings.Contains(recorder.Body.String(), `href="/admin/audit"`) {
		t.Fatalf("audit nav link missing for staff with audit.read permission: %s", recorder.Body.String())
	}
}

func TestRendererRendersAttractionEditFormWithOptionalValues(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	priceCurrency := "KZT"
	durationUnit := "HOUR"
	durationValue := 2
	spots := 8
	latitude := 43.243534
	longitude := 76.904129
	item := &model.AdminAttraction{
		ID:                uuid.New(),
		DefaultLocale:     localeRU,
		Title:             "Большое Алматинское озеро",
		Description:       "Горное озеро рядом с Алматы.",
		CountryCode:       "KZ",
		CityID:            "almaty",
		Latitude:          &latitude,
		Longitude:         &longitude,
		LocationSourceURL: "https://www.openstreetmap.org/",
		Category:          "NATURE",
		PriceCurrency:     &priceCurrency,
		DurationValue:     &durationValue,
		DurationUnit:      &durationUnit,
		Spots:             &spots,
		Status:            "PUBLISHED",
		Translations: map[string]model.AttractionTranslation{
			localeRU: {
				Title:       "Большое Алматинское озеро",
				Description: "Горное озеро рядом с Алматы.",
			},
		},
		Media: []model.AdminAttractionMedia{
			{
				FileID:    uuid.New(),
				MediaType: "IMAGE",
				Position:  0,
			},
		},
	}
	pageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + item.ID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(item, model.AttractionInput{}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "attractions/form", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	if !strings.Contains(body, "Большое Алматинское озеро") ||
		!strings.Contains(body, "/admin/attraction-media/") {
		t.Fatalf("attraction edit form did not render useful content: %s", body)
	}
	for _, expected := range []string{
		`<select name="country_code" required data-attraction-country-select>`,
		`<select name="city_id" required data-attraction-city-select>`,
		`<select name="price_currency">`,
		`name="location_source_url" value="https://www.openstreetmap.org/" placeholder="https://maps..." data-map-url-input`,
		`name="latitude" value="43.243534" inputmode="decimal" data-latitude-input`,
		`name="longitude" value="76.904129" inputmode="decimal" data-longitude-input`,
		`type="checkbox" name="access_cities" value="KZ:almaty"`,
		`type="checkbox" name="departure_cities" value="KZ:almaty"`,
		`data-attraction-media-form`,
		`data-confirm-form="mediaManage"`,
		`name="media_action" value="manage" data-media-action-input`,
		`data-media-card`,
		`name="media_ids"`,
		`data-media-move="up"`,
		`data-media-move="down"`,
		`data-media-delete`,
		`data-media-delete-fields`,
		`data-attraction-media-input`,
		`data-attraction-media-preview hidden`,
		`data-attraction-media-preview-list`,
		`data-attraction-media-count`,
		`data-attraction-media-manage-submit disabled`,
		`data-attraction-media-append-submit disabled`,
		`data-attraction-media-replace-submit disabled`,
		`data-media-action="append"`,
		`data-media-action="replace"`,
		`id="decision-confirmation-dialog"`,
		`Проверьте выбранные изображения и их порядок перед сохранением.`,
		`data-required-locale="ru"`,
		`Обязательное поле.`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("attraction edit form did not render expected control %q: %s", expected, body)
		}
	}
}

func TestRendererRendersAttractionCreateFormWithUploadPreview(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:     "Create attraction",
		Locale:    localeEN,
		Path:      "/admin/attractions/new",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(nil, model.AttractionInput{}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "attractions/form", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := rendered.String()
	for _, expected := range []string{
		`data-attraction-form data-attraction-media-form`,
		`name="media_images" type="file"`,
		`data-attraction-media-input`,
		`data-attraction-media-preview hidden`,
		`data-attraction-media-preview-list`,
		`data-attraction-media-count`,
		`Check selected images and their order before saving.`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("attraction create form did not render media preview control %q: %s", expected, body)
		}
	}
}

func TestRendererRendersAttractionFormCityLinksScopedToCountry(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:     "Create attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/new",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data: NewAttractionFormViewData(nil, model.AttractionInput{
			CountryCode: "VN",
			CityID:      "hanoi",
		}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "attractions/form", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		`name="country_code" required data-attraction-country-select`,
		`name="city_id" required data-attraction-city-select`,
		`data-attraction-city-link-option data-country="VN"`,
		`type="checkbox" name="access_cities" value="VN:hanoi"`,
		`type="checkbox" name="departure_cities" value="VN:hanoi"`,
		`Ханой, Вьетнам`,
		`data-attraction-city-link-option hidden data-country="KZ"`,
		`type="checkbox" name="access_cities" value="KZ:almaty" disabled`,
		`type="checkbox" name="departure_cities" value="KZ:almaty" disabled`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("attraction form did not scope city link option %q: %s", expected, body)
		}
	}
}

func TestRendererRendersPhilippinesAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=PH&city=cebu-city",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Крест Магеллана",
				CountryCode:   "PH",
				CityID:        "cebu-city",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "PH",
			CityID:      "cebu-city",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="PH" selected`,
		`Филиппины`,
		`value="cebu-city" data-country="PH" selected`,
		`Себу`,
		`Себу, Филиппины`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Philippines attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">PH<") || strings.Contains(listBody, ">cebu-city<") {
		t.Fatalf("Philippines attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Крест Магеллана",
		Description:   "Историческая достопримечательность Себу.",
		CountryCode:   "PH",
		CityID:        "cebu-city",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "PH", CityID: "cebu-city"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "PH", CityID: "cebu-city"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="PH" selected>Филиппины</option>`,
		`<option value="cebu-city" data-country="PH" selected>Себу</option>`,
		`type="checkbox" name="access_cities" value="PH:cebu-city" checked`,
		`type="checkbox" name="departure_cities" value="PH:cebu-city" checked`,
		`Себу, Филиппины`,
		`<option value="PHP" >Филиппинское песо</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Philippines attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersIndonesiaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=ID&city=ubud",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Священный лес обезьян Убуда",
				CountryCode:   "ID",
				CityID:        "ubud",
				Category:      "PARK",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "ID",
			CityID:      "ubud",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="ID" selected`,
		`Индонезия`,
		`value="ubud" data-country="ID" selected`,
		`Убуд`,
		`Убуд, Индонезия`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Indonesia attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">ID<") || strings.Contains(listBody, ">ubud<") {
		t.Fatalf("Indonesia attraction list still renders raw codes: %s", listBody)
	}
	if !strings.Contains(listBody, `value="bali" data-country="ID"`) {
		t.Fatalf("Indonesia attraction list should render Bali as a regional filter option: %s", listBody)
	}
	if strings.Contains(listBody, `value="jakarta" data-country="ID"`) {
		t.Fatalf("Indonesia attraction list should not render empty Jakarta city filter: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Священный лес обезьян Убуда",
		Description:   "Лесной заповедник с макаками и храмами.",
		CountryCode:   "ID",
		CityID:        "ubud",
		Category:      "PARK",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "ID", CityID: "ubud"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "ID", CityID: "ubud"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="ID" selected>Индонезия</option>`,
		`<option value="ubud" data-country="ID" selected>Убуд</option>`,
		`<option value="gianyar" data-country="ID" >Гианьяр</option>`,
		`type="checkbox" name="access_cities" value="ID:ubud" checked`,
		`type="checkbox" name="departure_cities" value="ID:ubud" checked`,
		`Убуд, Индонезия`,
		`<option value="IDR" >Индонезийская рупия</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Indonesia attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
	if strings.Contains(editBody, `value="bali" data-country="ID"`) {
		t.Fatalf("Indonesia attraction form must not offer Bali as a concrete attraction city: %s", editBody)
	}
}

func TestRendererRendersMaldivesAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=MV&city=maafushi",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Bikini Beach Маафуши",
				CountryCode:   "MV",
				CityID:        "maafushi",
				Category:      "BEACH",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "MV",
			CityID:      "maafushi",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="MV" selected`,
		`Мальдивы`,
		`value="maafushi" data-country="MV" selected`,
		`Маафуши`,
		`Маафуши, Мальдивы`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Maldives attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">MV<") || strings.Contains(listBody, ">maafushi<") {
		t.Fatalf("Maldives attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Bikini Beach Маафуши",
		Description:   "Главная туристическая пляжная зона Маафуши.",
		CountryCode:   "MV",
		CityID:        "maafushi",
		Category:      "BEACH",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "MV", CityID: "maafushi"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "MV", CityID: "maafushi"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="MV" selected>Мальдивы</option>`,
		`<option value="maafushi" data-country="MV" selected>Маафуши</option>`,
		`<option value="hulhumale" data-country="MV" >Хулхумале</option>`,
		`type="checkbox" name="access_cities" value="MV:maafushi" checked`,
		`type="checkbox" name="departure_cities" value="MV:maafushi" checked`,
		`Маафуши, Мальдивы`,
		`<option value="MVR" >Мальдивская руфия</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Maldives attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersGeorgiaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=GE&city=stepantsminda",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Троицкая церковь Гергети",
				CountryCode:   "GE",
				CityID:        "stepantsminda",
				Category:      "TEMPLE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "GE",
			CityID:      "stepantsminda",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="GE" selected`,
		`Грузия`,
		`value="stepantsminda" data-country="GE" selected`,
		`Степанцминда (Казбеги)`,
		`Степанцминда (Казбеги), Грузия`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Georgia attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">GE<") || strings.Contains(listBody, ">stepantsminda<") {
		t.Fatalf("Georgia attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Троицкая церковь Гергети",
		Description:   "Горная церковь над Степанцминдой.",
		CountryCode:   "GE",
		CityID:        "stepantsminda",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "GE", CityID: "tbilisi"},
			{CountryCode: "GE", CityID: "stepantsminda"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "GE", CityID: "tbilisi"},
			{CountryCode: "GE", CityID: "stepantsminda"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="GE" selected>Грузия</option>`,
		`<option value="stepantsminda" data-country="GE" selected>Степанцминда (Казбеги)</option>`,
		`<option value="tbilisi" data-country="GE" >Тбилиси</option>`,
		`type="checkbox" name="access_cities" value="GE:tbilisi" checked`,
		`type="checkbox" name="departure_cities" value="GE:stepantsminda" checked`,
		`Степанцминда (Казбеги), Грузия`,
		`<option value="GEL" >Грузинский лари</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Georgia attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersArmeniaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=AM&city=vagharshapat",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Кафедральный собор Эчмиадзин",
				CountryCode:   "AM",
				CityID:        "vagharshapat",
				Category:      "TEMPLE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "AM",
			CityID:      "vagharshapat",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="AM" selected`,
		`Армения`,
		`value="vagharshapat" data-country="AM" selected`,
		`Вагаршапат (Эчмиадзин)`,
		`Вагаршапат (Эчмиадзин), Армения`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Armenia attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AM<") || strings.Contains(listBody, ">vagharshapat<") {
		t.Fatalf("Armenia attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Кафедральный собор Эчмиадзин",
		Description:   "Духовный центр Армянской апостольской церкви.",
		CountryCode:   "AM",
		CityID:        "vagharshapat",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "AM", CityID: "yerevan"},
			{CountryCode: "AM", CityID: "vagharshapat"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "AM", CityID: "yerevan"},
			{CountryCode: "AM", CityID: "vagharshapat"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="AM" selected>Армения</option>`,
		`<option value="vagharshapat" data-country="AM" selected>Вагаршапат (Эчмиадзин)</option>`,
		`<option value="yerevan" data-country="AM" >Ереван</option>`,
		`type="checkbox" name="access_cities" value="AM:yerevan" checked`,
		`type="checkbox" name="departure_cities" value="AM:vagharshapat" checked`,
		`Вагаршапат (Эчмиадзин), Армения`,
		`<option value="AMD" >Армянский драм</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Armenia attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersChinaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=CN&city=xian",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Терракотовая армия",
				CountryCode:   "CN",
				CityID:        "xian",
				Category:      "MUSEUM",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "CN",
			CityID:      "xian",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="CN" selected`,
		`Китай`,
		`value="xian" data-country="CN" selected`,
		`Сиань`,
		`Сиань, Китай`,
		`value="hainan" data-country="CN"`,
		`Хайнань`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("China attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">CN<") || strings.Contains(listBody, ">xian<") {
		t.Fatalf("China attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Терракотовая армия",
		Description:   "Музейный комплекс первого императора Цинь.",
		CountryCode:   "CN",
		CityID:        "xian",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "CN", CityID: "beijing"},
			{CountryCode: "CN", CityID: "xian"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "CN", CityID: "beijing"},
			{CountryCode: "CN", CityID: "xian"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="CN" selected>Китай</option>`,
		`<option value="xian" data-country="CN" selected>Сиань</option>`,
		`<option value="beijing" data-country="CN" >Пекин</option>`,
		`<option value="haikou" data-country="CN" >Хайкоу</option>`,
		`type="checkbox" name="access_cities" value="CN:beijing" checked`,
		`type="checkbox" name="departure_cities" value="CN:xian" checked`,
		`Сиань, Китай`,
		`<option value="CNY" >Китайский юань</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("China attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
	if strings.Contains(editBody, `value="hainan" data-country="CN"`) {
		t.Fatalf("China attraction form must not offer Hainan as a concrete attraction city: %s", editBody)
	}
}

func TestRendererRendersSouthKoreaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=KR&city=gyeongju",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Храм Пульгукса",
				CountryCode:   "KR",
				CityID:        "gyeongju",
				Category:      "TEMPLE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "KR",
			CityID:      "gyeongju",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="KR" selected`,
		`Южная Корея`,
		`value="gyeongju" data-country="KR" selected`,
		`Кёнджу`,
		`Кёнджу, Южная Корея`,
		`Храм`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("South Korea attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">KR<") || strings.Contains(listBody, ">gyeongju<") {
		t.Fatalf("South Korea attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Храм Пульгукса",
		Description:   "Главный буддийский храм Кёнджу.",
		CountryCode:   "KR",
		CityID:        "gyeongju",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "KR", CityID: "busan"},
			{CountryCode: "KR", CityID: "gyeongju"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "KR", CityID: "busan"},
			{CountryCode: "KR", CityID: "gyeongju"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="KR" selected>Южная Корея</option>`,
		`<option value="gyeongju" data-country="KR" selected>Кёнджу</option>`,
		`<option value="busan" data-country="KR" >Пусан</option>`,
		`type="checkbox" name="access_cities" value="KR:busan" checked`,
		`type="checkbox" name="departure_cities" value="KR:gyeongju" checked`,
		`Кёнджу, Южная Корея`,
		`<option value="KRW" >Южнокорейская вона</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("South Korea attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersJapanAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=JP&city=kyoto",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Храм Киёмидзу-дэра",
				CountryCode:   "JP",
				CityID:        "kyoto",
				Category:      "TEMPLE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "JP",
			CityID:      "kyoto",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="JP" selected`,
		`Япония`,
		`value="kyoto" data-country="JP" selected`,
		`Киото`,
		`Киото, Япония`,
		`Храм`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Japan attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">JP<") || strings.Contains(listBody, ">kyoto<") {
		t.Fatalf("Japan attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Храм Киёмидзу-дэра",
		Description:   "Исторический храм на востоке Киото.",
		CountryCode:   "JP",
		CityID:        "kyoto",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "JP", CityID: "osaka"},
			{CountryCode: "JP", CityID: "kyoto"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "JP", CityID: "osaka"},
			{CountryCode: "JP", CityID: "kyoto"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="JP" selected>Япония</option>`,
		`<option value="kyoto" data-country="JP" selected>Киото</option>`,
		`<option value="osaka" data-country="JP" >Осака</option>`,
		`type="checkbox" name="access_cities" value="JP:osaka" checked`,
		`type="checkbox" name="departure_cities" value="JP:kyoto" checked`,
		`Киото, Япония`,
		`<option value="JPY" >Японская иена</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Japan attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersUAEAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=AE&city=dubai",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Бурдж-Халифа",
				CountryCode:   "AE",
				CityID:        "dubai",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "AE",
			CityID:      "dubai",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="AE" selected`,
		`ОАЭ`,
		`value="dubai" data-country="AE" selected`,
		`Дубай`,
		`Дубай, ОАЭ`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("UAE attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AE<") || strings.Contains(listBody, ">dubai<") {
		t.Fatalf("UAE attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Бурдж-Халифа",
		Description:   "Главная смотровая башня Дубая.",
		CountryCode:   "AE",
		CityID:        "dubai",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "AE", CityID: "dubai"},
			{CountryCode: "AE", CityID: "abu-dhabi"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "AE", CityID: "dubai"},
			{CountryCode: "AE", CityID: "abu-dhabi"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="AE" selected>ОАЭ</option>`,
		`<option value="dubai" data-country="AE" selected>Дубай</option>`,
		`<option value="abu-dhabi" data-country="AE" >Абу-Даби</option>`,
		`type="checkbox" name="access_cities" value="AE:abu-dhabi" checked`,
		`type="checkbox" name="departure_cities" value="AE:dubai" checked`,
		`Дубай, ОАЭ`,
		`<option value="AED" >Дирхам ОАЭ</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("UAE attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersTurkeyAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=TR&city=istanbul",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Айя-София",
				CountryCode:   "TR",
				CityID:        "istanbul",
				Category:      "TEMPLE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "TR",
			CityID:      "istanbul",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="TR" selected`,
		`Турция`,
		`value="istanbul" data-country="TR" selected`,
		`Стамбул`,
		`Стамбул, Турция`,
		`Храм`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Turkey attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">TR<") || strings.Contains(listBody, ">istanbul<") {
		t.Fatalf("Turkey attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Айя-София",
		Description:   "Историческая мечеть и архитектурная икона Стамбула.",
		CountryCode:   "TR",
		CityID:        "istanbul",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "TR", CityID: "istanbul"},
			{CountryCode: "TR", CityID: "cappadocia"},
			{CountryCode: "TR", CityID: "antalya"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "TR", CityID: "istanbul"},
			{CountryCode: "TR", CityID: "cappadocia"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="TR" selected>Турция</option>`,
		`<option value="istanbul" data-country="TR" selected>Стамбул</option>`,
		`<option value="cappadocia" data-country="TR" >Каппадокия</option>`,
		`type="checkbox" name="access_cities" value="TR:antalya" checked`,
		`type="checkbox" name="departure_cities" value="TR:cappadocia" checked`,
		`Стамбул, Турция`,
		`<option value="TRY" >Турецкая лира</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Turkey attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersEgyptAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=EG&city=giza",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Пирамиды Гизы",
				CountryCode:   "EG",
				CityID:        "giza",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "EG",
			CityID:      "giza",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="EG" selected`,
		`Египет`,
		`value="giza" data-country="EG" selected`,
		`Гиза`,
		`Гиза, Египет`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Egypt attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">EG<") || strings.Contains(listBody, ">giza<") {
		t.Fatalf("Egypt attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Пирамиды Гизы",
		Description:   "Главный археологический комплекс Египта.",
		CountryCode:   "EG",
		CityID:        "giza",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "EG", CityID: "cairo"},
			{CountryCode: "EG", CityID: "luxor"},
			{CountryCode: "EG", CityID: "sharm-el-sheikh"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "EG", CityID: "cairo"},
			{CountryCode: "EG", CityID: "hurghada"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="EG" selected>Египет</option>`,
		`<option value="giza" data-country="EG" selected>Гиза</option>`,
		`<option value="luxor" data-country="EG" >Луксор</option>`,
		`type="checkbox" name="access_cities" value="EG:sharm-el-sheikh" checked`,
		`type="checkbox" name="departure_cities" value="EG:hurghada" checked`,
		`Гиза, Египет`,
		`<option value="EGP" >Египетский фунт</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Egypt attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersMalaysiaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=MY&city=george-town",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Джорджтаун",
				CountryCode:   "MY",
				CityID:        "george-town",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "MY",
			CityID:      "george-town",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="MY" selected`,
		`Малайзия`,
		`value="george-town" data-country="MY" selected`,
		`Джорджтаун`,
		`Джорджтаун, Малайзия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Malaysia attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">MY<") || strings.Contains(listBody, ">george-town<") {
		t.Fatalf("Malaysia attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Джорджтаун",
		Description:   "Исторический центр Пенанга.",
		CountryCode:   "MY",
		CityID:        "george-town",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "MY", CityID: "penang"},
			{CountryCode: "MY", CityID: "langkawi"},
			{CountryCode: "MY", CityID: "kuala-lumpur"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "MY", CityID: "penang"},
			{CountryCode: "MY", CityID: "kuala-lumpur"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="MY" selected>Малайзия</option>`,
		`<option value="george-town" data-country="MY" selected>Джорджтаун</option>`,
		`<option value="kota-kinabalu" data-country="MY" >Кота-Кинабалу</option>`,
		`type="checkbox" name="access_cities" value="MY:langkawi" checked`,
		`type="checkbox" name="departure_cities" value="MY:kuala-lumpur" checked`,
		`Джорджтаун, Малайзия`,
		`<option value="MYR" >Малайзийский ринггит</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Malaysia attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSriLankaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=LK&city=sigiriya",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Сигирия",
				CountryCode:   "LK",
				CityID:        "sigiriya",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "LK",
			CityID:      "sigiriya",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="LK" selected`,
		`Шри-Ланка`,
		`value="sigiriya" data-country="LK" selected`,
		`Сигирия`,
		`Сигирия, Шри-Ланка`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Sri Lanka attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">LK<") || strings.Contains(listBody, ">sigiriya<") {
		t.Fatalf("Sri Lanka attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Сигирия",
		Description:   "Скальная крепость в культурном треугольнике.",
		CountryCode:   "LK",
		CityID:        "sigiriya",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "LK", CityID: "kandy"},
			{CountryCode: "LK", CityID: "dambulla"},
			{CountryCode: "LK", CityID: "colombo"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "LK", CityID: "colombo"},
			{CountryCode: "LK", CityID: "kandy"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="LK" selected>Шри-Ланка</option>`,
		`<option value="sigiriya" data-country="LK" selected>Сигирия</option>`,
		`<option value="ella" data-country="LK" >Элла</option>`,
		`type="checkbox" name="access_cities" value="LK:kandy" checked`,
		`type="checkbox" name="departure_cities" value="LK:colombo" checked`,
		`Сигирия, Шри-Ланка`,
		`<option value="LKR" >Шри-ланкийская рупия</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Sri Lanka attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersMontenegroAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=ME&city=kotor",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Старый город Котор",
				CountryCode:   "ME",
				CityID:        "kotor",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "ME",
			CityID:      "kotor",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="ME" selected`,
		`Черногория`,
		`value="kotor" data-country="ME" selected`,
		`Котор`,
		`Котор, Черногория`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Montenegro attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">ME<") || strings.Contains(listBody, ">kotor<") {
		t.Fatalf("Montenegro attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Старый город Котор",
		Description:   "Исторический город в Боко-Которской бухте.",
		CountryCode:   "ME",
		CityID:        "kotor",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "ME", CityID: "perast"},
			{CountryCode: "ME", CityID: "tivat"},
			{CountryCode: "ME", CityID: "podgorica"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "ME", CityID: "podgorica"},
			{CountryCode: "ME", CityID: "budva"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="ME" selected>Черногория</option>`,
		`<option value="kotor" data-country="ME" selected>Котор</option>`,
		`<option value="budva" data-country="ME" >Будва</option>`,
		`type="checkbox" name="access_cities" value="ME:perast" checked`,
		`type="checkbox" name="departure_cities" value="ME:podgorica" checked`,
		`Котор, Черногория`,
		`<option value="EUR" >Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Montenegro attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersIndiaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=IN&city=delhi",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Красный форт",
				CountryCode:   "IN",
				CityID:        "delhi",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "IN",
			CityID:      "delhi",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="IN" selected`,
		`Индия`,
		`value="delhi" data-country="IN" selected`,
		`Дели`,
		`Дели, Индия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("India attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">IN<") || strings.Contains(listBody, ">delhi<") {
		t.Fatalf("India attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Красный форт",
		Description:   "Исторический форт в Старом Дели.",
		CountryCode:   "IN",
		CityID:        "delhi",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "IN", CityID: "agra"},
			{CountryCode: "IN", CityID: "jaipur"},
			{CountryCode: "IN", CityID: "varanasi"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "IN", CityID: "mumbai"},
			{CountryCode: "IN", CityID: "goa"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="IN" selected>Индия</option>`,
		`<option value="delhi" data-country="IN" selected>Дели</option>`,
		`<option value="goa" data-country="IN" >Гоа</option>`,
		`type="checkbox" name="access_cities" value="IN:agra" checked`,
		`type="checkbox" name="departure_cities" value="IN:mumbai" checked`,
		`Дели, Индия`,
		`<option value="INR" >Индийская рупия</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("India attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersMaltaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=MT&city=valletta",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Собор Святого Иоанна",
				CountryCode:   "MT",
				CityID:        "valletta",
				Category:      "TEMPLE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "MT",
			CityID:      "valletta",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="MT" selected`,
		`Мальта`,
		`value="valletta" data-country="MT" selected`,
		`Валлетта`,
		`Валлетта, Мальта`,
		`Храм`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Malta attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">MT<") || strings.Contains(listBody, ">valletta<") {
		t.Fatalf("Malta attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Собор Святого Иоанна",
		Description:   "Барочный собор в Валлетте.",
		CountryCode:   "MT",
		CityID:        "valletta",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "MT", CityID: "sliema"},
			{CountryCode: "MT", CityID: "mdina"},
			{CountryCode: "MT", CityID: "gozo"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "MT", CityID: "st-julians"},
			{CountryCode: "MT", CityID: "marsaxlokk"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="MT" selected>Мальта</option>`,
		`<option value="valletta" data-country="MT" selected>Валлетта</option>`,
		`<option value="gozo" data-country="MT" >Гозо</option>`,
		`type="checkbox" name="access_cities" value="MT:sliema" checked`,
		`type="checkbox" name="departure_cities" value="MT:st-julians" checked`,
		`Валлетта, Мальта`,
		`<option value="EUR" >Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Malta attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersCyprusAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=CY&city=paphos",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Археологический парк Пафоса",
				CountryCode:   "CY",
				CityID:        "paphos",
				Category:      "MUSEUM",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "CY",
			CityID:      "paphos",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="CY" selected`,
		`Кипр`,
		`value="paphos" data-country="CY" selected`,
		`Пафос`,
		`Пафос, Кипр`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Cyprus attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">CY<") || strings.Contains(listBody, ">paphos<") {
		t.Fatalf("Cyprus attraction list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Археологический парк Пафоса",
		Description:   "Археологический комплекс с мозаиками и античными памятниками.",
		CountryCode:   "CY",
		CityID:        "paphos",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "CY", CityID: "coral-bay"},
			{CountryCode: "CY", CityID: "polis"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "CY", CityID: "ayia-napa"},
			{CountryCode: "CY", CityID: "limassol"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="CY" selected>Кипр</option>`,
		`<option value="paphos" data-country="CY" selected>Пафос</option>`,
		`<option value="ayia-napa" data-country="CY" >Айя-Напа</option>`,
		`type="checkbox" name="access_cities" value="CY:coral-bay" checked`,
		`type="checkbox" name="departure_cities" value="CY:ayia-napa" checked`,
		`Пафос, Кипр`,
		`<option value="EUR" >Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Cyprus attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSeychellesAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=SC&city=victoria",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Национальный ботанический сад Сейшел",
				CountryCode:   "SC",
				CityID:        "victoria",
				Category:      "PARK",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "SC",
			CityID:      "victoria",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="SC" selected`,
		`Сейшелы`,
		`value="victoria" data-country="SC" selected`,
		`Виктория`,
		`Виктория, Сейшелы`,
		`Парк`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Seychelles attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">SC<") || strings.Contains(listBody, ">victoria<") {
		t.Fatalf("Seychelles attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "SCR"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Национальный ботанический сад Сейшел",
		Description:   "Сад в Виктории с эндемичными растениями и гигантскими черепахами.",
		CountryCode:   "SC",
		CityID:        "victoria",
		Category:      "PARK",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "SC", CityID: "beau-vallon"},
			{CountryCode: "SC", CityID: "eden-island"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "SC", CityID: "la-digue"},
			{CountryCode: "SC", CityID: "praslin"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="SC" selected>Сейшелы</option>`,
		`<option value="victoria" data-country="SC" selected>Виктория</option>`,
		`<option value="beau-vallon" data-country="SC" >Бо-Валлон</option>`,
		`type="checkbox" name="access_cities" value="SC:beau-vallon" checked`,
		`type="checkbox" name="departure_cities" value="SC:la-digue" checked`,
		`Виктория, Сейшелы`,
		`<option value="SCR" selected>Сейшельская рупия</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Seychelles attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersPolandAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=PL&city=warsaw",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Старый город Варшавы",
				CountryCode:   "PL",
				CityID:        "warsaw",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "PL",
			CityID:      "warsaw",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="PL" selected`,
		`Польша`,
		`value="warsaw" data-country="PL" selected`,
		`Варшава`,
		`Варшава, Польша`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Poland attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">PL<") || strings.Contains(listBody, ">warsaw<") {
		t.Fatalf("Poland attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "PLN"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Старый город Варшавы",
		Description:   "Исторический центр Варшавы с площадями, крепостными стенами и Королевским замком.",
		CountryCode:   "PL",
		CityID:        "warsaw",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "PL", CityID: "krakow"},
			{CountryCode: "PL", CityID: "gdansk"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "PL", CityID: "wroclaw"},
			{CountryCode: "PL", CityID: "poznan"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="PL" selected>Польша</option>`,
		`<option value="warsaw" data-country="PL" selected>Варшава</option>`,
		`<option value="krakow" data-country="PL" >Краков</option>`,
		`type="checkbox" name="access_cities" value="PL:krakow" checked`,
		`type="checkbox" name="departure_cities" value="PL:wroclaw" checked`,
		`Варшава, Польша`,
		`<option value="PLN" selected>Польский злотый</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Poland attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersMexicoAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=MX&city=mexico-city",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Исторический центр Мехико",
				CountryCode:   "MX",
				CityID:        "mexico-city",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "MX",
			CityID:      "mexico-city",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="MX" selected`,
		`Мексика`,
		`value="mexico-city" data-country="MX" selected`,
		`Мехико`,
		`Мехико, Мексика`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Mexico attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">MX<") || strings.Contains(listBody, ">mexico-city<") {
		t.Fatalf("Mexico attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "MXN"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Исторический центр Мехико",
		Description:   "Главная историческая зона столицы с площадью Сокало, собором и музеями.",
		CountryCode:   "MX",
		CityID:        "mexico-city",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "MX", CityID: "teotihuacan"},
			{CountryCode: "MX", CityID: "puebla"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "MX", CityID: "cancun"},
			{CountryCode: "MX", CityID: "guadalajara"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="MX" selected>Мексика</option>`,
		`<option value="mexico-city" data-country="MX" selected>Мехико</option>`,
		`<option value="teotihuacan" data-country="MX" >Теотиуакан</option>`,
		`type="checkbox" name="access_cities" value="MX:teotihuacan" checked`,
		`type="checkbox" name="departure_cities" value="MX:cancun" checked`,
		`Мехико, Мексика`,
		`<option value="MXN" selected>Мексиканский песо</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Mexico attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersBrazilAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=BR&city=rio-de-janeiro",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Христос-Искупитель",
				CountryCode:   "BR",
				CityID:        "rio-de-janeiro",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "BR",
			CityID:      "rio-de-janeiro",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="BR" selected`,
		`Бразилия`,
		`value="rio-de-janeiro" data-country="BR" selected`,
		`Рио-де-Жанейро`,
		`Рио-де-Жанейро, Бразилия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Brazil attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">BR<") || strings.Contains(listBody, ">rio-de-janeiro<") {
		t.Fatalf("Brazil attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "BRL"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Христос-Искупитель",
		Description:   "Главный символ Рио-де-Жанейро с видом на город, бухту и пляжи.",
		CountryCode:   "BR",
		CityID:        "rio-de-janeiro",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "BR", CityID: "petropolis"},
			{CountryCode: "BR", CityID: "paraty"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "BR", CityID: "sao-paulo"},
			{CountryCode: "BR", CityID: "salvador"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="BR" selected>Бразилия</option>`,
		`<option value="rio-de-janeiro" data-country="BR" selected>Рио-де-Жанейро</option>`,
		`<option value="petropolis" data-country="BR" >Петрополис</option>`,
		`type="checkbox" name="access_cities" value="BR:petropolis" checked`,
		`type="checkbox" name="departure_cities" value="BR:sao-paulo" checked`,
		`Рио-де-Жанейро, Бразилия`,
		`<option value="BRL" selected>Бразильский реал</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Brazil attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersArgentinaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=AR&city=buenos-aires",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Театр Колон",
				CountryCode:   "AR",
				CityID:        "buenos-aires",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "AR",
			CityID:      "buenos-aires",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="AR" selected`,
		`Аргентина`,
		`value="buenos-aires" data-country="AR" selected`,
		`Буэнос-Айрес`,
		`Буэнос-Айрес, Аргентина`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Argentina attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AR<") || strings.Contains(listBody, ">buenos-aires<") {
		t.Fatalf("Argentina attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "ARS"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Театр Колон",
		Description:   "Историческая опера Буэнос-Айреса и одна из главных культурных сцен страны.",
		CountryCode:   "AR",
		CityID:        "buenos-aires",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "AR", CityID: "tigre"},
			{CountryCode: "AR", CityID: "la-plata"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "AR", CityID: "mendoza"},
			{CountryCode: "AR", CityID: "bariloche"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="AR" selected>Аргентина</option>`,
		`<option value="buenos-aires" data-country="AR" selected>Буэнос-Айрес</option>`,
		`<option value="tigre" data-country="AR" >Тигре</option>`,
		`type="checkbox" name="access_cities" value="AR:tigre" checked`,
		`type="checkbox" name="departure_cities" value="AR:mendoza" checked`,
		`Буэнос-Айрес, Аргентина`,
		`<option value="ARS" selected>Аргентинский песо</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Argentina attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSwitzerlandAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=CH&city=zurich",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Кунстхаус Цюрих",
				CountryCode:   "CH",
				CityID:        "zurich",
				Category:      "MUSEUM",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "CH",
			CityID:      "zurich",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="CH" selected`,
		`Швейцария`,
		`value="zurich" data-country="CH" selected`,
		`Цюрих`,
		`Цюрих, Швейцария`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Switzerland attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">CH<") || strings.Contains(listBody, ">zurich<") {
		t.Fatalf("Switzerland attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "CHF"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Кунстхаус Цюрих",
		Description:   "Один из ключевых художественных музеев Швейцарии.",
		CountryCode:   "CH",
		CityID:        "zurich",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "CH", CityID: "lucerne"},
			{CountryCode: "CH", CityID: "basel"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "CH", CityID: "geneva"},
			{CountryCode: "CH", CityID: "zermatt"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="CH" selected>Швейцария</option>`,
		`<option value="zurich" data-country="CH" selected>Цюрих</option>`,
		`<option value="lucerne" data-country="CH" >Люцерн</option>`,
		`type="checkbox" name="access_cities" value="CH:lucerne" checked`,
		`type="checkbox" name="departure_cities" value="CH:geneva" checked`,
		`Цюрих, Швейцария`,
		`<option value="CHF" selected>Швейцарский франк</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Switzerland attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSwedenAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=SE&city=stockholm",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Музей Васа",
				CountryCode:   "SE",
				CityID:        "stockholm",
				Category:      "MUSEUM",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "SE",
			CityID:      "stockholm",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="SE" selected`,
		`Швеция`,
		`value="stockholm" data-country="SE" selected`,
		`Стокгольм`,
		`Стокгольм, Швеция`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Sweden attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">SE<") || strings.Contains(listBody, ">stockholm<") {
		t.Fatalf("Sweden attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "SEK"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Музей Васа",
		Description:   "Морской музей с историческим кораблем XVII века.",
		CountryCode:   "SE",
		CityID:        "stockholm",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "SE", CityID: "uppsala"},
			{CountryCode: "SE", CityID: "sigtuna"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "SE", CityID: "gothenburg"},
			{CountryCode: "SE", CityID: "malmo"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="SE" selected>Швеция</option>`,
		`<option value="stockholm" data-country="SE" selected>Стокгольм</option>`,
		`<option value="uppsala" data-country="SE" >Уппсала</option>`,
		`type="checkbox" name="access_cities" value="SE:uppsala" checked`,
		`type="checkbox" name="departure_cities" value="SE:gothenburg" checked`,
		`Стокгольм, Швеция`,
		`<option value="SEK" selected>Шведская крона</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Sweden attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersCzechiaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=CZ&city=prague",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Пражский Град",
				CountryCode:   "CZ",
				CityID:        "prague",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "CZ",
			CityID:      "prague",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="CZ" selected`,
		`Чехия`,
		`value="prague" data-country="CZ" selected`,
		`Прага`,
		`Прага, Чехия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Czechia attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">CZ<") || strings.Contains(listBody, ">prague<") {
		t.Fatalf("Czechia attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "CZK"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Пражский Град",
		Description:   "Крупнейший исторический комплекс Праги.",
		CountryCode:   "CZ",
		CityID:        "prague",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "CZ", CityID: "karlstejn"},
			{CountryCode: "CZ", CityID: "kutna-hora"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "CZ", CityID: "brno"},
			{CountryCode: "CZ", CityID: "plzen"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="CZ" selected>Чехия</option>`,
		`<option value="prague" data-country="CZ" selected>Прага</option>`,
		`<option value="karlstejn" data-country="CZ" >Карлштейн</option>`,
		`type="checkbox" name="access_cities" value="CZ:karlstejn" checked`,
		`type="checkbox" name="departure_cities" value="CZ:brno" checked`,
		`Прага, Чехия`,
		`<option value="CZK" selected>Чешская крона</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Czechia attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersAbkhaziaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=AB&city=sukhum",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Сухумский ботанический сад",
				CountryCode:   "AB",
				CityID:        "sukhum",
				Category:      "PARK",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "AB",
			CityID:      "sukhum",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="AB" selected`,
		`Абхазия`,
		`value="sukhum" data-country="AB" selected`,
		`Сухум`,
		`Сухум, Абхазия`,
		`Парк`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Abkhazia attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AB<") || strings.Contains(listBody, ">sukhum<") {
		t.Fatalf("Abkhazia attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "RUB"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Сухумский ботанический сад",
		Description:   "Исторический ботанический сад в центре Сухума.",
		CountryCode:   "AB",
		CityID:        "sukhum",
		Category:      "PARK",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "AB", CityID: "gagra"},
			{CountryCode: "AB", CityID: "new-athos"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "AB", CityID: "pitsunda"},
			{CountryCode: "AB", CityID: "lake-ritsa"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="AB" selected>Абхазия</option>`,
		`<option value="sukhum" data-country="AB" selected>Сухум</option>`,
		`<option value="gagra" data-country="AB" >Гагра</option>`,
		`type="checkbox" name="access_cities" value="AB:gagra" checked`,
		`type="checkbox" name="departure_cities" value="AB:pitsunda" checked`,
		`Сухум, Абхазия`,
		`<option value="RUB" selected>Российский рубль</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Abkhazia attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersCubaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=CU&city=havana",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Старая Гавана",
				CountryCode:   "CU",
				CityID:        "havana",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "CU",
			CityID:      "havana",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="CU" selected`,
		`Куба`,
		`value="havana" data-country="CU" selected`,
		`Гавана`,
		`Гавана, Куба`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Cuba attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">CU<") || strings.Contains(listBody, ">havana<") {
		t.Fatalf("Cuba attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "CUP"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Старая Гавана",
		Description:   "Исторический центр столицы Кубы.",
		CountryCode:   "CU",
		CityID:        "havana",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "CU", CityID: "varadero"},
			{CountryCode: "CU", CityID: "vinales"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "CU", CityID: "havana"},
			{CountryCode: "CU", CityID: "trinidad"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="CU" selected>Куба</option>`,
		`<option value="havana" data-country="CU" selected>Гавана</option>`,
		`<option value="varadero" data-country="CU" >Варадеро</option>`,
		`type="checkbox" name="access_cities" value="CU:varadero" checked`,
		`type="checkbox" name="departure_cities" value="CU:havana" checked`,
		`Гавана, Куба`,
		`<option value="CUP" selected>Кубинский песо</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Cuba attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersMoroccoAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=MA&city=marrakech",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Медина Марракеша",
				CountryCode:   "MA",
				CityID:        "marrakech",
				Category:      "MARKET",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "MA",
			CityID:      "marrakech",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="MA" selected`,
		`Марокко`,
		`value="marrakech" data-country="MA" selected`,
		`Марракеш`,
		`Марракеш, Марокко`,
		`Рынок`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Morocco attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">MA<") || strings.Contains(listBody, ">marrakech<") {
		t.Fatalf("Morocco attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "MAD"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Медина Марракеша",
		Description:   "Исторический центр Марракеша.",
		CountryCode:   "MA",
		CityID:        "marrakech",
		Category:      "MARKET",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "MA", CityID: "agafay"},
			{CountryCode: "MA", CityID: "ourika"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "MA", CityID: "marrakech"},
			{CountryCode: "MA", CityID: "casablanca"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="MA" selected>Марокко</option>`,
		`<option value="marrakech" data-country="MA" selected>Марракеш</option>`,
		`<option value="agafay" data-country="MA" >Агафай</option>`,
		`type="checkbox" name="access_cities" value="MA:agafay" checked`,
		`type="checkbox" name="departure_cities" value="MA:marrakech" checked`,
		`Марракеш, Марокко`,
		`<option value="MAD" selected>Марокканский дирхам</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Morocco attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersPortugalAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=PT&city=lisbon",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Монастырь Жеронимуш",
				CountryCode:   "PT",
				CityID:        "lisbon",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "PT",
			CityID:      "lisbon",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="PT" selected`,
		`Португалия`,
		`value="lisbon" data-country="PT" selected`,
		`Лиссабон`,
		`Лиссабон, Португалия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Portugal attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">PT<") || strings.Contains(listBody, ">lisbon<") {
		t.Fatalf("Portugal attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Монастырь Жеронимуш",
		Description:   "Один из главных памятников Лиссабона.",
		CountryCode:   "PT",
		CityID:        "lisbon",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "PT", CityID: "sintra"},
			{CountryCode: "PT", CityID: "cascais"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "PT", CityID: "lisbon"},
			{CountryCode: "PT", CityID: "porto"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="PT" selected>Португалия</option>`,
		`<option value="lisbon" data-country="PT" selected>Лиссабон</option>`,
		`<option value="sintra" data-country="PT" >Синтра</option>`,
		`<option value="tomar" data-country="PT" >Томар</option>`,
		`type="checkbox" name="access_cities" value="PT:sintra" checked`,
		`type="checkbox" name="departure_cities" value="PT:lisbon" checked`,
		`Лиссабон, Португалия`,
		`<option value="EUR" selected>Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Portugal attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersItalyAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=IT&city=florence",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Галерея Уффици",
				CountryCode:   "IT",
				CityID:        "florence",
				Category:      "MUSEUM",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "IT",
			CityID:      "florence",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="IT" selected`,
		`Италия`,
		`value="florence" data-country="IT" selected`,
		`Флоренция`,
		`Флоренция, Италия`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Italy attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">IT<") || strings.Contains(listBody, ">florence<") {
		t.Fatalf("Italy attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Галерея Уффици",
		Description:   "Один из главных художественных музеев Флоренции.",
		CountryCode:   "IT",
		CityID:        "florence",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "IT", CityID: "pisa"},
			{CountryCode: "IT", CityID: "siena"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "IT", CityID: "florence"},
			{CountryCode: "IT", CityID: "rome"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="IT" selected>Италия</option>`,
		`<option value="florence" data-country="IT" selected>Флоренция</option>`,
		`<option value="pisa" data-country="IT" >Пиза</option>`,
		`<option value="amalfi-coast" data-country="IT" >Амальфитанское побережье</option>`,
		`type="checkbox" name="access_cities" value="IT:pisa" checked`,
		`type="checkbox" name="departure_cities" value="IT:florence" checked`,
		`Флоренция, Италия`,
		`<option value="EUR" selected>Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Italy attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSpainAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=ES&city=barcelona",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Саграда Фамилия",
				CountryCode:   "ES",
				CityID:        "barcelona",
				Category:      "TEMPLE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "ES",
			CityID:      "barcelona",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="ES" selected`,
		`Испания`,
		`value="barcelona" data-country="ES" selected`,
		`Барселона`,
		`Барселона, Испания`,
		`Храм`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Spain attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">ES<") || strings.Contains(listBody, ">barcelona<") {
		t.Fatalf("Spain attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Саграда Фамилия",
		Description:   "Главный храм Барселоны и один из символов Испании.",
		CountryCode:   "ES",
		CityID:        "barcelona",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "ES", CityID: "girona"},
			{CountryCode: "ES", CityID: "costa-brava"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "ES", CityID: "barcelona"},
			{CountryCode: "ES", CityID: "salou"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="ES" selected>Испания</option>`,
		`<option value="barcelona" data-country="ES" selected>Барселона</option>`,
		`<option value="girona" data-country="ES" >Жирона</option>`,
		`<option value="costa-brava" data-country="ES" >Коста-Брава</option>`,
		`type="checkbox" name="access_cities" value="ES:girona" checked`,
		`type="checkbox" name="departure_cities" value="ES:barcelona" checked`,
		`Барселона, Испания`,
		`<option value="EUR" selected>Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Spain attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersLuxembourgAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=LU&city=luxembourg-city",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Казематы Бок",
				CountryCode:   "LU",
				CityID:        "luxembourg-city",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "LU",
			CityID:      "luxembourg-city",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="LU" selected`,
		`Люксембург`,
		`value="luxembourg-city" data-country="LU" selected`,
		`Люксембург, Люксембург`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Luxembourg attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">LU<") || strings.Contains(listBody, ">luxembourg-city<") {
		t.Fatalf("Luxembourg attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Казематы Бок",
		Description:   "Подземные укрепления Люксембурга.",
		CountryCode:   "LU",
		CityID:        "luxembourg-city",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "LU", CityID: "vianden"},
			{CountryCode: "LU", CityID: "echternach"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "LU", CityID: "luxembourg-city"},
			{CountryCode: "LU", CityID: "esch-sur-alzette"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="LU" selected>Люксембург</option>`,
		`<option value="luxembourg-city" data-country="LU" selected>Люксембург</option>`,
		`<option value="vianden" data-country="LU" >Вианден</option>`,
		`type="checkbox" name="access_cities" value="LU:vianden" checked`,
		`type="checkbox" name="departure_cities" value="LU:luxembourg-city" checked`,
		`Люксембург, Люксембург`,
		`<option value="EUR" selected>Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Luxembourg attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersGermanyAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=DE&city=berlin",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Бранденбургские ворота",
				CountryCode:   "DE",
				CityID:        "berlin",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "DE",
			CityID:      "berlin",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="DE" selected`,
		`Германия`,
		`value="berlin" data-country="DE" selected`,
		`Берлин`,
		`Берлин, Германия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Germany attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">DE<") || strings.Contains(listBody, ">berlin<") {
		t.Fatalf("Germany attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Бранденбургские ворота",
		Description:   "Исторический символ Берлина.",
		CountryCode:   "DE",
		CityID:        "berlin",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "DE", CityID: "potsdam"},
			{CountryCode: "DE", CityID: "hamburg"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "DE", CityID: "berlin"},
			{CountryCode: "DE", CityID: "munich"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="DE" selected>Германия</option>`,
		`<option value="berlin" data-country="DE" selected>Берлин</option>`,
		`<option value="potsdam" data-country="DE" >Потсдам</option>`,
		`type="checkbox" name="access_cities" value="DE:potsdam" checked`,
		`type="checkbox" name="departure_cities" value="DE:berlin" checked`,
		`Берлин, Германия`,
		`<option value="EUR" selected>Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Germany attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersAustriaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=AT&city=vienna",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Дворец Шёнбрунн",
				CountryCode:   "AT",
				CityID:        "vienna",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "AT",
			CityID:      "vienna",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="AT" selected`,
		`Австрия`,
		`value="vienna" data-country="AT" selected`,
		`Вена`,
		`Вена, Австрия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Austria attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AT<") || strings.Contains(listBody, ">vienna<") {
		t.Fatalf("Austria attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Дворец Шёнбрунн",
		Description:   "Императорский дворец и парк в Вене.",
		CountryCode:   "AT",
		CityID:        "vienna",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "AT", CityID: "salzburg"},
			{CountryCode: "AT", CityID: "innsbruck"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "AT", CityID: "vienna"},
			{CountryCode: "AT", CityID: "graz"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="AT" selected>Австрия</option>`,
		`<option value="vienna" data-country="AT" selected>Вена</option>`,
		`<option value="salzburg" data-country="AT" >Зальцбург</option>`,
		`type="checkbox" name="access_cities" value="AT:salzburg" checked`,
		`type="checkbox" name="departure_cities" value="AT:vienna" checked`,
		`Вена, Австрия`,
		`<option value="EUR" selected>Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Austria attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersAustraliaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=AU&city=sydney",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Сиднейская опера",
				CountryCode:   "AU",
				CityID:        "sydney",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "AU",
			CityID:      "sydney",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="AU" selected`,
		`Австралия`,
		`value="sydney" data-country="AU" selected`,
		`Сидней`,
		`Сидней, Австралия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Australia attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AU<") || strings.Contains(listBody, ">sydney<") {
		t.Fatalf("Australia attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "AUD"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Сиднейская опера",
		Description:   "Знаковый концертный комплекс на гавани Сиднея.",
		CountryCode:   "AU",
		CityID:        "sydney",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "AU", CityID: "blue-mountains"},
			{CountryCode: "AU", CityID: "canberra"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "AU", CityID: "sydney"},
			{CountryCode: "AU", CityID: "melbourne"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="AU" selected>Австралия</option>`,
		`<option value="sydney" data-country="AU" selected>Сидней</option>`,
		`<option value="blue-mountains" data-country="AU" >Голубые горы</option>`,
		`type="checkbox" name="access_cities" value="AU:blue-mountains" checked`,
		`type="checkbox" name="departure_cities" value="AU:sydney" checked`,
		`Сидней, Австралия`,
		`<option value="AUD" selected>Австралийский доллар</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Australia attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersTanzaniaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=TZ&city=dar-es-salaam",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Национальный музей Танзании",
				CountryCode:   "TZ",
				CityID:        "dar-es-salaam",
				Category:      "MUSEUM",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "TZ",
			CityID:      "dar-es-salaam",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="TZ" selected`,
		`Танзания`,
		`value="dar-es-salaam" data-country="TZ" selected`,
		`Дар-эс-Салам`,
		`Дар-эс-Салам, Танзания`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Tanzania attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">TZ<") || strings.Contains(listBody, ">dar-es-salaam<") {
		t.Fatalf("Tanzania attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "TZS"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Национальный музей Танзании",
		Description:   "Главный музей Дар-эс-Салама о стране, истории и культуре.",
		CountryCode:   "TZ",
		CityID:        "dar-es-salaam",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "TZ", CityID: "zanzibar-city"},
			{CountryCode: "TZ", CityID: "arusha"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "TZ", CityID: "dar-es-salaam"},
			{CountryCode: "TZ", CityID: "stone-town"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="TZ" selected>Танзания</option>`,
		`<option value="dar-es-salaam" data-country="TZ" selected>Дар-эс-Салам</option>`,
		`<option value="zanzibar-city" data-country="TZ" >Занзибар</option>`,
		`type="checkbox" name="access_cities" value="TZ:zanzibar-city" checked`,
		`type="checkbox" name="departure_cities" value="TZ:dar-es-salaam" checked`,
		`Дар-эс-Салам, Танзания`,
		`<option value="TZS" selected>Танзанийский шиллинг</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Tanzania attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersKenyaAttractionReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?country=KE&city=nairobi",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Национальный музей Найроби",
				CountryCode:   "KE",
				CityID:        "nairobi",
				Category:      "MUSEUM",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{
			CountryCode: "KE",
			CityID:      "nairobi",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "attractions/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`value="KE" selected`,
		`Кения`,
		`value="nairobi" data-country="KE" selected`,
		`Найроби`,
		`Найроби, Кения`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Kenya attraction list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">KE<") || strings.Contains(listBody, ">nairobi<") {
		t.Fatalf("Kenya attraction list still renders raw codes: %s", listBody)
	}

	priceCurrency := "KES"
	editItem := &model.AdminAttraction{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Национальный музей Найроби",
		Description:   "Главный музей Кении о культуре, природе и истории страны.",
		CountryCode:   "KE",
		CityID:        "nairobi",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.AttractionCityLink{
			{CountryCode: "KE", CityID: "mombasa"},
			{CountryCode: "KE", CityID: "masai-mara"},
		},
		DepartureCities: []model.AttractionCityLink{
			{CountryCode: "KE", CityID: "nairobi"},
			{CountryCode: "KE", CityID: "diani"},
		},
	}
	editPageData := PageData{
		Title:     "Edit attraction",
		Locale:    localeRU,
		Path:      "/admin/attractions/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewAttractionFormViewData(editItem, model.AttractionInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "attractions/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="KE" selected>Кения</option>`,
		`<option value="nairobi" data-country="KE" selected>Найроби</option>`,
		`<option value="mombasa" data-country="KE" >Момбаса</option>`,
		`type="checkbox" name="access_cities" value="KE:mombasa" checked`,
		`type="checkbox" name="departure_cities" value="KE:nairobi" checked`,
		`Найроби, Кения`,
		`<option value="KES" selected>Кенийский шиллинг</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Kenya attraction form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersAttractionListCountryCityDropdownFilters(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData(nil, 0, AttractionFilterViewData{
			CountryCode: "KZ",
			CityID:      "almaty",
		}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "attractions/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		`name="country"`,
		`data-country-filter`,
		`value="KZ" selected`,
		`Казахстан`,
		`name="city"`,
		`data-city-filter`,
		`data-city-filter-group`,
		`value="almaty" data-country="KZ" selected`,
		`Алматы`,
		`Все страны`,
		`Все города`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("attraction list did not render dropdown filter %q: %s", expected, body)
		}
	}
	if strings.Contains(body, `placeholder="almaty"`) {
		t.Fatalf("attraction list still renders free-form city input: %s", body)
	}
}

func TestRendererHidesAttractionCityFilterUntilCountrySelected(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions",
		Staff:  adminTemplateActor(),
		Data:   NewAttractionListViewData(nil, 0, AttractionFilterViewData{}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "attractions/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	if !strings.Contains(body, `data-city-filter-group hidden`) {
		t.Fatalf("city filter group should be hidden before country selection: %s", body)
	}
	if !strings.Contains(body, `data-city-filter disabled`) {
		t.Fatalf("city filter select should be disabled before country selection: %s", body)
	}
}

func TestAdminStylesKeepHiddenElementsInvisible(t *testing.T) {
	t.Parallel()

	content, err := embeddedFiles.ReadFile("static/css/admin.css")
	if err != nil {
		t.Fatalf("ReadFile returned error: %v", err)
	}
	css := string(content)
	if !strings.Contains(css, `[hidden]`) || !strings.Contains(css, `display: none !important`) {
		t.Fatalf("admin css must explicitly preserve hidden elements against display rules: %s", css)
	}
}

func TestAdminJSKeepsAttractionUploadPreviewCaptionsReadable(t *testing.T) {
	t.Parallel()

	content, err := embeddedFiles.ReadFile("static/js/admin.js")
	if err != nil {
		t.Fatalf("ReadFile returned error: %v", err)
	}
	js := string(content)
	for _, unexpected := range []string{
		"caption.textContent = index === 0 ? `#${index + 1} · ${coverLabel} · ${file.name}` : `#${index + 1} · ${file.name}`",
		"image.alt = file.name",
	} {
		if strings.Contains(js, unexpected) {
			t.Fatalf("admin js should not render uploaded file names as visible preview text: %s", unexpected)
		}
	}
	for _, expected := range []string{
		"caption.textContent = index === 0 ? `#${index + 1} · ${coverLabel}` : `#${index + 1}`",
		"caption.title = file.name",
	} {
		if !strings.Contains(js, expected) {
			t.Fatalf("admin js should keep preview captions short and preserve filename as metadata, missing %q", expected)
		}
	}
}

func TestRendererRendersAttractionListLocalizedRows(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	itemID := uuid.New()
	pageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:            itemID,
				DefaultLocale: localeEN,
				Title:         "Central Museum",
				CountryCode:   "KZ",
				CityID:        "oral",
				Category:      "museum",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, AttractionFilterViewData{}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "attractions/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		"Орал, Казахстан",
		"Музей",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("attraction list row did not render localized value %q: %s", expected, body)
		}
	}
	if strings.Contains(body, "Основной язык:") ||
		strings.Contains(body, "Источник:") ||
		strings.Contains(body, "en · IMPORT") ||
		strings.Contains(body, ">museum<") ||
		strings.Contains(body, ">oral<") {
		t.Fatalf("attraction list row still renders raw codes: %s", body)
	}
}

func TestRendererRendersAttractionListPagination(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:  "Attractions",
		Locale: localeRU,
		Path:   "/admin/attractions?page=2&q=lake",
		Staff:  adminTemplateActor(),
		Data: NewAttractionListViewData([]model.AdminAttraction{
			{
				ID:        uuid.New(),
				Title:     "Lake",
				CityID:    "almaty",
				Category:  "NATURE",
				Status:    "PUBLISHED",
				UpdatedAt: time.Now().UTC(),
			},
		}, 60, AttractionFilterViewData{
			Search: "lake",
			Page:   2,
			Query:  "q=lake",
		}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "attractions/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		"Показано 26-50 из 60",
		`href="/admin/attractions?page=1&q=lake"`,
		`href="/admin/attractions?page=3&q=lake"`,
		"Назад",
		"Вперед",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("pagination did not render %q: %s", expected, body)
		}
	}
}

func TestRendererRendersModerationDetail(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Now().UTC()
	caseID := uuid.New()
	excursionID := uuid.New()
	pageData := PageData{
		Title:     "Detail",
		Locale:    localeRU,
		Path:      "/admin/moderation/excursions/" + caseID.String(),
		CSRFToken: "csrf-token",
		Data: CaseDetailViewData{
			Detail: &app.ModerationCaseDetail{
				Case: &model.ModerationCase{
					ID:             caseID,
					TargetType:     model.ModerationTargetExcursion,
					TargetID:       excursionID,
					SourceRevision: 7,
					Status:         enum.ModerationCaseStatusOpen,
					Priority:       80,
					OpenedAt:       now,
				},
				Excursion: &model.ExcursionModerationItem{
					ID:                    excursionID,
					Title:                 "Big Almaty Lake",
					Summary:               "Compare guide offers for this route.",
					Description:           "Choose a guide, language, price, meeting point, and schedule before booking this route.",
					Status:                "PENDING_REVIEW",
					Visibility:            "PUBLIC",
					GuideUserID:           uuid.New(),
					GuideDisplayName:      "Guide",
					GuideTrustScore:       65,
					PublishRiskScore:      35,
					ModerationReasonCodes: []string{"new_guide"},
					LandmarkName:          "Big Almaty Lake",
					AttractionNames:       []string{"Big Almaty Lake", "Medeu"},
					DurationMinutes:       150,
					MaxGroupSize:          8,
					LanguageCodes:         []string{"ru", "en"},
					MeetingPoint:          "Главный вход Медеу",
					MeetingPointByLocale: map[string]string{
						"ru": "Локализованная точка встречи",
					},
					IncludedItems: []string{"transfer", "tickets"},
					IncludedItemsByLocale: map[string][]string{
						"ru": {"Трансфер", "Входные билеты"},
					},
					Itinerary: []model.ExcursionItineraryItem{
						{
							SortOrder:          0,
							StartOffsetMinutes: 0,
							DurationMinutes:    intPtr(15),
							Title:              "Meet at Medeu",
							Description:        "Group check-in.",
							Translations: map[string]model.ExcursionItineraryLocalizedCopy{
								"ru": {
									Title:       "Встреча у главного входа",
									Description: "Проверка группы и короткий инструктаж.",
								},
							},
						},
						{
							SortOrder:          1,
							StartOffsetMinutes: 30,
							DurationMinutes:    intPtr(60),
							AttractionName:     "Big Almaty Lake",
							Title:              "Walk to the viewpoint",
							Description:        "Scenic walk.",
							Translations: map[string]model.ExcursionItineraryLocalizedCopy{
								"ru": {
									Title:       "Подъем к смотровой точке",
									Description: "Остановка для фото и рассказа о маршруте.",
								},
							},
						},
					},
					CountryCode:     "KZ",
					DepartureCityID: "almaty",
					PriceAmount:     12000,
					Currency:        "KZT",
					Revision:        7,
					CreatedAt:       now,
					UpdatedAt:       now,
				},
				Decisions: []*model.ModerationDecision{
					{
						ID:              uuid.New(),
						CaseID:          caseID,
						DecisionType:    enum.ModerationDecisionReject,
						SourceRevision:  7,
						ReasonCodes:     []string{"missing_license"},
						PublicComment:   "Нужно добавить лицензию гида.",
						InternalComment: "Проверить документы перед повторной публикацией.",
						DecidedBy:       uuid.New(),
						DecidedByName:   "Иван Петров",
						ApplyStatus:     enum.ModerationApplyApplied,
						CreatedAt:       now,
					},
				},
			},
		},
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "moderation/detail", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	if !strings.Contains(recorder.Body.String(), "Big Almaty Lake") {
		t.Fatal("moderation detail did not render excursion content")
	}
	if !strings.Contains(recorder.Body.String(), "Кейс модерации") {
		t.Fatal("moderation detail did not render Russian labels")
	}
	if strings.Contains(recorder.Body.String(), ">KZ<") {
		t.Fatal("moderation detail rendered raw country code")
	}
	if !strings.Contains(recorder.Body.String(), "Алматы, Казахстан") {
		t.Fatal("moderation detail did not render localized city and country")
	}
	if !strings.Contains(recorder.Body.String(), "Big Almaty Lake, Medeu") {
		t.Fatal("moderation detail did not render route attraction names")
	}
	if strings.Contains(recorder.Body.String(), genericRouteSummary) {
		t.Fatal("moderation detail rendered generic route summary")
	}
	body := html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		`data-confirm-form="approve"`,
		`data-confirm-form="reject"`,
		`name="internal_comment" rows="3" required`,
		`name="public_comment" rows="3" required`,
		`id="decision-confirmation-dialog"`,
		"Подтвердить действие",
		"missing_license",
		"Нужно добавить лицензию гида.",
		"Проверить документы перед повторной публикацией.",
		"Иван Петров",
		"Маршрут и расписание",
		"2 ч 30 мин",
		"До 8 гостей",
		"Русский, Английский",
		"Локализованная точка встречи",
		"Встреча у главного входа",
		"Проверка группы и короткий инструктаж.",
		"00:30",
		"Подъем к смотровой точке",
		"Трансфер",
		"Входные билеты",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("moderation detail did not render %q: %s", expected, body)
		}
	}
	if strings.Contains(body, `Кем принято</th><th>Создано</th></tr></thead>`) && strings.Contains(body, `<td><code>`) {
		t.Fatal("moderation detail rendered decision actor as uuid instead of employee name")
	}
}

func TestRendererRendersActivityModerationReadableContext(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Now().UTC()
	caseID := uuid.New()
	activityID := uuid.New()
	hostID := uuid.MustParse("0980d6b0-00bc-4aed-ae88-4b753e10c113")
	pageData := PageData{
		Title:     "Activity detail",
		Locale:    localeRU,
		Path:      "/admin/moderation/activities/" + caseID.String(),
		CSRFToken: "csrf-token",
		Data: CaseDetailViewData{
			Detail: &app.ModerationCaseDetail{
				Case: &model.ModerationCase{
					ID:             caseID,
					TargetType:     model.ModerationTargetActivity,
					TargetID:       activityID,
					SourceRevision: 3,
					Status:         enum.ModerationCaseStatusOpen,
					Priority:       70,
					OpenedAt:       now,
				},
				Activity: &model.ActivityModerationItem{
					ID:                    activityID,
					HostUserID:            hostID,
					HostDisplayName:       "Aruzhan Nomad",
					Title:                 "Evening city walk",
					Description:           "Напишите мне в WhatsApp +77011234567 перед участием",
					Status:                "ENROLLMENT_OPEN",
					Visibility:            "PUBLIC",
					ModerationStatus:      "FLAGGED",
					ModerationRiskScore:   60,
					ModerationReasonCodes: []string{"external_contact"},
					CategorySlug:          "city-walks",
					SubcategorySlug:       stringPtr("photo-walk"),
					LanguageCode:          "ru",
					Timezone:              "Asia/Almaty",
					StartAt:               now.Add(2 * time.Hour),
					EndAt:                 now.Add(4 * time.Hour),
					CapacityType:          "UNLIMITED",
					PriceType:             "FREE",
					CountryCode:           stringPtr("KZ"),
					CityID:                stringPtr("almaty"),
					CityName:              stringPtr("Almaty, Kazakhstan"),
					AddressText:           stringPtr("Dostyk Plaza"),
					MapURL:                stringPtr("https://www.openstreetmap.org/?mlat=43.2435&mlon=76.9041#map=16/43.2435/76.9041"),
					Revision:              3,
					CreatedAt:             now,
					UpdatedAt:             now,
				},
			},
		},
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "moderation/detail", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		"Aruzhan Nomad",
		"Прогулки и город / Фотопрогулка",
		"Алматы, Казахстан",
		"Dostyk Plaza",
		"Открыть карту",
		`href="https://www.openstreetmap.org/?mlat=43.2435&mlon=76.9041#map=16/43.2435/76.9041"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("activity moderation detail did not render %q: %s", expected, body)
		}
	}
	for _, unexpected := range []string{
		"ID 0980d6b0",
		"Пользователь 0980d6b0",
		"city-walks",
		"photo-walk",
		"Almaty, Kazakhstan, Казахстан",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("activity moderation detail rendered technical value %q: %s", unexpected, body)
		}
	}
}

func TestRendererRendersGuideApplicationQueueReadableContext(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Now().UTC()
	caseID := uuid.New()
	applicationID := uuid.New()
	application := model.GuideApplicationModerationItem{
		ID:                        applicationID,
		GuideDisplayName:          "Aruzhan Nomad",
		FirstName:                 "Aruzhan",
		LastName:                  "Khan",
		Type:                      "LOCAL_EXPERT",
		Status:                    "SUBMITTED",
		GuideStatus:               "PENDING_REVIEW",
		Headline:                  "Горный гид по Алматы",
		ExperienceYears:           6,
		BaseCityID:                "almaty",
		BaseCityName:              "Almaty, Kazakhstan",
		IsExcursionGuideAvailable: true,
		Languages: []model.GuideApplicationLanguage{
			{LanguageCode: "ru", ProficiencyLevel: "NATIVE"},
			{LanguageCode: "en", ProficiencyLevel: "ADVANCED"},
		},
		Specializations: []string{"mountain-routes", "city-walks"},
		Documents: []model.GuideApplicationDocument{
			{FileID: uuid.New(), DocumentType: "IDENTITY_DOCUMENT"},
		},
		Revision:    7,
		SubmittedAt: &now,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	snapshot, err := json.Marshal(application)
	if err != nil {
		t.Fatalf("json.Marshal application returned error: %v", err)
	}
	pageData := PageData{
		Title:     "Guide applications",
		Locale:    localeRU,
		Path:      "/admin/moderation/guides",
		CSRFToken: "csrf-token",
		Data: NewGuideApplicationQueueViewData([]*model.ModerationCase{
			{
				ID:             caseID,
				TargetType:     model.ModerationTargetGuideApplication,
				TargetID:       applicationID,
				SourceService:  "guide-service",
				SourceRevision: 7,
				Status:         enum.ModerationCaseStatusOpen,
				Priority:       50,
				Snapshot:       snapshot,
				OpenedAt:       now,
				CreatedAt:      now,
				UpdatedAt:      now,
			},
		}),
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "moderation/queue", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		"Aruzhan Nomad",
		"Khan Aruzhan",
		"Горный гид по Алматы",
		"Алматы, Казахстан",
		"Локальный эксперт",
		"/admin/moderation/guides/" + caseID.String(),
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("guide application queue did not render %q: %s", expected, body)
		}
	}
	for _, unexpected := range []string{
		applicationID.String(),
		"LOCAL_EXPERT",
		"PENDING_REVIEW",
		"mountain-routes",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("guide application queue rendered technical value %q: %s", unexpected, body)
		}
	}
}

func TestRendererRendersGuideApplicationModerationReadableContext(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Now().UTC()
	caseID := uuid.New()
	applicationID := uuid.New()
	documentID := uuid.New()
	documentFileID := uuid.New()
	documentDownloadURL := "http://file-manager-minio:9000/flyfy-files/guide_verification_doc/2026/04/13/fbc1a575-b630-47b2-b071-f8ec43694947.jpg?X-Amz-Signature=test"
	pageData := PageData{
		Title:     "Guide application detail",
		Locale:    localeRU,
		Path:      "/admin/moderation/guides/" + caseID.String(),
		CSRFToken: "csrf-token",
		Data: CaseDetailViewData{
			Detail: &app.ModerationCaseDetail{
				Case: &model.ModerationCase{
					ID:             caseID,
					TargetType:     model.ModerationTargetGuideApplication,
					TargetID:       applicationID,
					SourceRevision: 7,
					Status:         enum.ModerationCaseStatusOpen,
					Priority:       50,
					OpenedAt:       now,
					CreatedAt:      now,
					UpdatedAt:      now,
				},
				GuideApplication: &model.GuideApplicationModerationItem{
					ID:                        applicationID,
					GuideDisplayName:          "Aruzhan Nomad",
					FirstName:                 "Aruzhan",
					LastName:                  "Khan",
					Type:                      "LOCAL_EXPERT",
					Status:                    "SUBMITTED",
					GuideStatus:               "PENDING_REVIEW",
					Headline:                  "Горный гид по Алматы",
					About:                     "Провожу безопасные маршруты по горам и городу.",
					ExperienceYears:           6,
					BaseCityID:                "almaty",
					BaseCityName:              "Almaty, Kazakhstan",
					IsPrivateGuideAvailable:   true,
					IsExcursionGuideAvailable: true,
					IsActivityHostAvailable:   false,
					RatingAvg:                 4.8,
					ReviewsCount:              24,
					Comment:                   "Хочу проводить авторские маршруты.",
					SubmittedAt:               &now,
					Languages: []model.GuideApplicationLanguage{
						{LanguageCode: "ru", ProficiencyLevel: "NATIVE"},
						{LanguageCode: "en", ProficiencyLevel: "ADVANCED"},
					},
					Specializations: []string{"mountain-routes", "city-walks"},
					Documents: []model.GuideApplicationDocument{
						{
							ID:           documentID,
							FileID:       documentFileID,
							DocumentType: "IDENTITY_DOCUMENT",
							DownloadURL:  documentDownloadURL,
							CreatedAt:    now,
						},
					},
					Revision:  7,
					CreatedAt: now,
					UpdatedAt: now,
				},
			},
		},
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "moderation/detail", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		"Aruzhan Nomad",
		"Khan Aruzhan",
		"Локальный эксперт",
		"Ожидает проверки",
		"Алматы, Казахстан",
		"6 лет опыта",
		"Русский - родной",
		"Английский - продвинутый",
		"Горные маршруты",
		"Прогулки и город",
		"Удостоверение личности",
		`href="/admin/moderation/guides/` + caseID.String() + `/documents/` + documentID.String() + `"`,
		`/admin/moderation/guides/` + caseID.String() + `/approve`,
		`/admin/moderation/guides/` + caseID.String() + `/reject`,
		`name="internal_comment" rows="3" required`,
		`name="public_comment" rows="3" required`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("guide application detail did not render %q: %s", expected, body)
		}
	}
	for _, unexpected := range []string{
		applicationID.String(),
		documentFileID.String(),
		documentDownloadURL,
		"file-manager-minio:9000",
		"LOCAL_EXPERT",
		"mountain-routes",
		"IDENTITY_DOCUMENT",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("guide application detail rendered technical value %q: %s", unexpected, body)
		}
	}
}

func TestRendererRendersGuideApplicationRatingWithoutReviews(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Now().UTC()
	caseID := uuid.New()
	applicationID := uuid.New()
	pageData := PageData{
		Title:     "Guide application",
		Locale:    localeRU,
		Path:      "/admin/moderation/guides/" + caseID.String(),
		CSRFToken: "csrf-token",
		Data: CaseDetailViewData{
			Detail: &app.ModerationCaseDetail{
				Case: &model.ModerationCase{
					ID:             caseID,
					TargetType:     model.ModerationTargetGuideApplication,
					TargetID:       applicationID,
					SourceRevision: 1,
					Status:         enum.ModerationCaseStatusOpen,
					Priority:       50,
					OpenedAt:       now,
					CreatedAt:      now,
					UpdatedAt:      now,
				},
				GuideApplication: &model.GuideApplicationModerationItem{
					ID:               applicationID,
					GuideDisplayName: "Aruzhan Nomad",
					Status:           "SUBMITTED",
					GuideStatus:      "PENDING_REVIEW",
					Type:             "LOCAL_EXPERT",
					RatingAvg:        5.0,
					ReviewsCount:     0,
					CreatedAt:        now,
					UpdatedAt:        now,
				},
			},
		},
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "moderation/detail", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := html.UnescapeString(recorder.Body.String())
	if !strings.Contains(body, "Нет отзывов") {
		t.Fatalf("guide application detail did not render empty rating state: %s", body)
	}
	if strings.Contains(body, "5.0 · 0") {
		t.Fatalf("guide application detail rendered misleading zero-review rating: %s", body)
	}
}

func TestRendererHidesDecisionFormsForRejectedActivity(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Now().UTC()
	caseID := uuid.New()
	activityID := uuid.New()
	pageData := PageData{
		Title:     "Activity detail",
		Locale:    localeRU,
		Path:      "/admin/moderation/activities/" + caseID.String(),
		CSRFToken: "csrf-token",
		Data: CaseDetailViewData{
			Detail: &app.ModerationCaseDetail{
				Case: &model.ModerationCase{
					ID:             caseID,
					TargetType:     model.ModerationTargetActivity,
					TargetID:       activityID,
					SourceRevision: 4,
					Status:         enum.ModerationCaseStatusRejected,
					Priority:       70,
					OpenedAt:       now,
					ResolvedAt:     &now,
					CreatedAt:      now,
					UpdatedAt:      now,
				},
				Activity: &model.ActivityModerationItem{
					ID:               activityID,
					HostDisplayName:  "Aruzhan Nomad",
					Title:            "Evening city walk",
					Description:      "External contact in description.",
					Status:           "CANCELLED",
					Visibility:       "PUBLIC",
					ModerationStatus: "REJECTED",
					CategorySlug:     "city-walks",
					LanguageCode:     "ru",
					Timezone:         "Asia/Almaty",
					StartAt:          now.Add(2 * time.Hour),
					EndAt:            now.Add(4 * time.Hour),
					CapacityType:     "UNLIMITED",
					PriceType:        "FREE",
					CityName:         stringPtr("Almaty, Kazakhstan"),
					Revision:         4,
					CreatedAt:        now,
					UpdatedAt:        now,
				},
			},
		},
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "moderation/detail", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := html.UnescapeString(recorder.Body.String())
	if !strings.Contains(body, "Решение уже принято") {
		t.Fatalf("rejected activity detail did not render locked decision copy: %s", body)
	}
	for _, unexpected := range []string{
		`data-confirm-form="approve"`,
		`data-confirm-form="reject"`,
		`name="public_comment"`,
		`name="internal_comment"`,
		`/admin/moderation/activities/` + caseID.String() + `/approve`,
		`/admin/moderation/activities/` + caseID.String() + `/reject`,
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("rejected activity detail rendered action control %q: %s", unexpected, body)
		}
	}
}

func TestRendererRendersActiveGuideListAndDropdownReasonCodes(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Now().UTC()
	guideProfileID := uuid.New()
	pageData := PageData{
		Title:     "Current guides",
		Locale:    localeRU,
		Path:      "/admin/moderation/guides/current",
		CSRFToken: "csrf-token",
		Data: GuideListViewData{
			Items: []model.GuideApplicationModerationItem{
				{
					GuideProfileID:            guideProfileID,
					GuideUserID:               uuid.New(),
					GuideDisplayName:          "@nomad_aru",
					FirstName:                 "Аружан",
					LastName:                  "Тулегенова",
					CountryCode:               "KZ",
					Type:                      "INDEPENDENT",
					GuideStatus:               "ACTIVE",
					Status:                    "APPROVED",
					Headline:                  "Горные маршруты Алматы",
					ExperienceYears:           8,
					BaseCityID:                "almaty",
					IsExcursionGuideAvailable: true,
					RatingAvg:                 4.9,
					ReviewsCount:              15,
					CreatedAt:                 now,
					UpdatedAt:                 now,
				},
			},
		},
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "guides/index", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		"Текущие гиды",
		"@nomad_aru",
		"Тулегенова Аружан",
		"Горные маршруты Алматы",
		`<button class="danger" type="button" data-modal-open="guide-revoke-dialog-` + guideProfileID.String() + `">Отозвать статус гида</button>`,
		`<dialog class="confirm-dialog revoke-dialog" id="guide-revoke-dialog-` + guideProfileID.String() + `"`,
		`/admin/moderation/guides/current/` + guideProfileID.String() + `/revoke`,
		`<select name="reason_codes" required>`,
		`value="unsafe_behavior"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("active guide list missing %q: %s", expected, body)
		}
	}
	if strings.Contains(body, `name="reason_codes" placeholder`) {
		t.Fatalf("active guide list rendered manual reason code input: %s", body)
	}
	dialogIndex := strings.Index(body, `<dialog class="confirm-dialog revoke-dialog" id="guide-revoke-dialog-`+guideProfileID.String()+`"`)
	formIndex := strings.Index(body, `<form method="post" action="/admin/moderation/guides/current/`+guideProfileID.String()+`/revoke"`)
	if dialogIndex == -1 || formIndex == -1 || formIndex < dialogIndex {
		t.Fatalf("active guide revoke form must be rendered inside the modal dialog: %s", body)
	}
}

func TestActivityPresenterLocalizesCityNameValues(t *testing.T) {
	t.Parallel()

	if got := displayCityName(localeEN, "Алматы"); got != "Almaty" {
		t.Fatalf("displayCityName(en, Алматы) = %q, want Almaty", got)
	}
	if got := displayCityName(localeRU, "Almaty"); got != "Алматы" {
		t.Fatalf("displayCityName(ru, Almaty) = %q, want Алматы", got)
	}
}

func TestRendererLocalizesExcursionLandmarkName(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Now().UTC()
	caseID := uuid.New()
	excursionID := uuid.New()
	pageData := PageData{
		Title:     "Detail",
		Locale:    localeRU,
		Path:      "/admin/moderation/excursions/" + caseID.String(),
		CSRFToken: "csrf-token",
		Data: CaseDetailViewData{
			Detail: &app.ModerationCaseDetail{
				Case: &model.ModerationCase{
					ID:             caseID,
					TargetType:     model.ModerationTargetExcursion,
					TargetID:       excursionID,
					SourceRevision: 2,
					Status:         enum.ModerationCaseStatusOpen,
					OpenedAt:       now,
				},
				Excursion: &model.ExcursionModerationItem{
					ID:           excursionID,
					Title:        "Medeu Alpine Skating Rink",
					Summary:      "Compare guide offers for Medeu Alpine Skating Rink.",
					Description:  "Choose a guide, language, price, meeting point, and included options before booking.",
					Status:       "PENDING_REVIEW",
					Visibility:   "PUBLIC",
					LandmarkName: "Medeu Alpine Skating Rink",
					ProductTranslations: map[string]model.ExcursionLocalizedCopy{
						"ru": {
							Title:       "Высокогорный каток Медеу",
							Description: "Высокогорный спортивный комплекс над Алматы с большим искусственным ледовым полем.",
						},
						"en": {Title: "Medeu Alpine Skating Rink"},
					},
					AttractionNamesByLocale: map[string][]string{
						"ru": {"Служебная точка маршрута"},
					},
					CountryCode:          "KZ",
					DepartureCityID:      "almaty",
					Currency:             "KZT",
					SubmittedForReviewAt: &now,
					CreatedAt:            now,
					UpdatedAt:            now,
				},
			},
		},
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "moderation/detail", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := html.UnescapeString(recorder.Body.String())
	if !strings.Contains(body, "Высокогорный каток Медеу") {
		t.Fatalf("moderation detail did not render localized landmark name: %s", body)
	}
	if strings.Contains(body, "<dd>Medeu Alpine Skating Rink</dd>") {
		t.Fatal("moderation detail rendered English landmark field in Russian locale")
	}
	if strings.Contains(body, "Сравните предложения гидов") || strings.Contains(body, "Compare guide offers") {
		t.Fatal("moderation detail rendered marketplace comparison copy for a single moderation case")
	}
	if !strings.Contains(body, "Заявка гида на публикацию экскурсии: Высокогорный каток Медеу.") {
		t.Fatal("moderation detail did not render moderation summary with localized landmark")
	}
	if !strings.Contains(body, "Высокогорный спортивный комплекс над Алматы") {
		t.Fatal("moderation detail did not render localized product description")
	}
}

func TestRendererRendersStaffManagementTemplates(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	staffID := uuid.New()
	staff := &model.StaffUser{
		ID:          staffID,
		Email:       "moderator@flyfy.local",
		DisplayName: "Moderator",
		Status:      enum.StaffStatusActive,
		Roles:       []enum.StaffRole{enum.StaffRoleExcursionModerator},
	}
	pageData := PageData{
		Title:     "Staff",
		Locale:    localeEN,
		Path:      "/admin/staff",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data: StaffListViewData{
			Staff:           []*model.StaffUser{staff},
			AssignableRoles: []enum.StaffRole{enum.StaffRoleAdmin, enum.StaffRoleExcursionModerator},
		},
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "staff/index", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := recorder.Body.String()
	if !strings.Contains(body, "/admin/staff/"+staffID.String()+"/edit") {
		t.Fatalf("staff list did not render edit link: %s", body)
	}
	if strings.Contains(body, `class="split"`) {
		t.Fatal("staff list still renders create form and list side by side")
	}
	if !strings.Contains(body, "Staff list") {
		t.Fatal("staff list section title is missing")
	}

	pageData.Path = "/admin/staff/" + staffID.String() + "/edit"
	pageData.Data = StaffEditViewData{
		Staff:           staff,
		AssignableRoles: []enum.StaffRole{enum.StaffRoleAdmin, enum.StaffRoleExcursionModerator},
		Statuses:        []enum.StaffStatus{enum.StaffStatusActive, enum.StaffStatusDisabled},
	}
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "staff/edit", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body = recorder.Body.String()
	for _, expected := range []string{
		`action="/admin/staff/` + staffID.String() + `"`,
		`action="/admin/staff/` + staffID.String() + `/status"`,
		`action="/admin/staff/` + staffID.String() + `/password/regenerate"`,
		`name="reason"`,
		`required`,
		`value="EXCURSION_MODERATOR" checked`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("staff edit template did not render %q: %s", expected, body)
		}
	}
}

func TestRendererRendersReadableAuditEvents(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	staffID := uuid.New()
	pageData := PageData{
		Title:     "Audit",
		Locale:    localeRU,
		Path:      "/admin/audit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data: NewAuditViewData(localeRU, []*model.AuditEvent{
			{
				ActorStaffID:     &staffID,
				ActorDisplayName: "Данияр Хван",
				ActorEmail:       "dkhvan.developer@gmail.com",
				Action:           "staff.updated",
				EntityType:       "staff_user",
				EntityID:         &staffID,
				RequestID:        "request-1234567890",
				BeforeJSON:       []byte(`{"email":"dkhvan.developer@gmail.com","displayName":"Old Name","status":"ACTIVE","roles":["SUPER_ADMIN"]}`),
				AfterJSON:        []byte(`{"email":"dkhvan.developer@gmail.com","displayName":"Данияр Хван","status":"ACTIVE","roles":["SUPER_ADMIN"]}`),
				CreatedAt:        time.Now().UTC(),
			},
		}),
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "audit/index", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		"Профиль сотрудника обновлен",
		"Данияр Хван",
		"dkhvan.developer@gmail.com",
		"Old Name -> Данияр Хван",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("audit template did not render readable value %q: %s", expected, body)
		}
	}
	if strings.Contains(body, "Запрос request") || strings.Contains(body, "request-1234567890") {
		t.Fatalf("audit template rendered request id in visible details: %s", body)
	}
	if strings.Contains(body, ">staff.updated<") {
		t.Fatalf("audit template rendered raw action: %s", body)
	}
	if strings.Contains(body, "<code>"+shortTemplateID(staffID)+"</code>") {
		t.Fatalf("audit template rendered raw actor uuid as primary content: %s", body)
	}
}

func TestRendererRendersStaffProfileWithOwnAuditHistory(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	staffID := uuid.New()
	caseID := uuid.New()
	baseTime := time.Date(2026, 5, 25, 12, 0, 0, 0, time.UTC)
	staff := &model.StaffUser{
		ID:          staffID,
		Email:       "moderator@flyfy.local",
		DisplayName: "Aruzhan Ops",
		Status:      enum.StaffStatusActive,
		Timezone:    "Asia/Tokyo",
		Roles:       []enum.StaffRole{enum.StaffRoleActivityModerator},
		Permissions: []enum.Permission{
			enum.PermissionDashboardRead,
			enum.PermissionModerationRead,
		},
		CreatedAt: baseTime,
		UpdatedAt: baseTime,
	}
	pageData := PageData{
		Title:     "My profile",
		Locale:    localeEN,
		Path:      "/admin/me",
		Staff:     staff,
		CSRFToken: "csrf-token",
		Data: NewStaffProfileViewData(localeEN, staff, []*model.AuditEvent{
			{
				ActorStaffID:     &staffID,
				ActorDisplayName: "Aruzhan Ops",
				ActorEmail:       "moderator@flyfy.local",
				Action:           "admin.login.succeeded",
				EntityType:       "staff_session",
				CreatedAt:        baseTime,
			},
			{
				ActorStaffID:     &staffID,
				ActorDisplayName: "Aruzhan Ops",
				ActorEmail:       "moderator@flyfy.local",
				Action:           "moderation.decision.applied",
				EntityType:       "moderation_case",
				EntityID:         &caseID,
				Metadata:         []byte(`{"decision":"APPROVED","targetType":"ACTIVITY"}`),
				CreatedAt:        baseTime,
			},
		}),
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "staff/profile", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		"Aruzhan Ops",
		"moderator@flyfy.local",
		"Activity moderator",
		"Sign-in succeeded",
		"Moderation case: Activity",
		"2026-05-25 21:00",
		"name=\"timezone\"",
		"value=\"Asia/Tokyo\" selected",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("staff profile did not render %q: %s", expected, body)
		}
	}
	if strings.Contains(body, "ID "+caseID.String()[:8]) {
		t.Fatalf("staff profile rendered technical moderation case id: %s", body)
	}
}

func adminTemplateActor() *model.StaffUser {
	return &model.StaffUser{
		ID:          uuid.New(),
		Email:       "admin@flyfy.local",
		DisplayName: "Admin",
		Status:      enum.StaffStatusActive,
		Roles:       []enum.StaffRole{enum.StaffRoleAdmin},
		Permissions: []enum.Permission{enum.PermissionStaffManage},
	}
}

func intPtr(value int) *int {
	return &value
}

func stringPtr(value string) *string {
	return &value
}

func TestFlashMessageFromRequestUsesWhitelistedLocalizedKeys(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest(http.MethodGet, "/admin/staff?flash=staff.updated", nil)
	if got := flashMessageFromRequest(localeRU, request); got != "Изменения сохранены." {
		t.Fatalf("flashMessageFromRequest() = %q", got)
	}

	request = httptest.NewRequest(http.MethodGet, "/admin/staff?flash=<script>alert(1)</script>", nil)
	if got := flashMessageFromRequest(localeRU, request); got != "" {
		t.Fatalf("flashMessageFromRequest() for unknown key = %q, want empty", got)
	}
}

func TestRedirectWithFlashPreservesExistingQuery(t *testing.T) {
	t.Parallel()

	got := redirectWithFlash("/admin/moderation/excursions?status=active&city=Almaty", "moderation.queueSynced")
	if got != "/admin/moderation/excursions?city=Almaty&flash=moderation.queueSynced&status=active" {
		t.Fatalf("redirectWithFlash() = %q", got)
	}
}

func TestLocaleResolution(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest(http.MethodGet, "/admin?lang=ru", nil)
	request.Header.Set("Accept-Language", "en-US,en;q=0.9")
	if got := resolveLocale(request); got != localeRU {
		t.Fatalf("resolveLocale() = %q, want %q", got, localeRU)
	}

	request = httptest.NewRequest(http.MethodGet, "/admin", nil)
	request.AddCookie(&http.Cookie{Name: localeCookieName, Value: "ru"})
	if got := resolveLocale(request); got != localeRU {
		t.Fatalf("resolveLocale() with cookie = %q, want %q", got, localeRU)
	}

	request = httptest.NewRequest(http.MethodGet, "/admin", nil)
	request.Header.Set("Accept-Language", "ru-KZ,ru;q=0.9,en;q=0.4")
	if got := resolveLocale(request); got != localeRU {
		t.Fatalf("resolveLocale() with Accept-Language = %q, want %q", got, localeRU)
	}
}

func TestAdminCSSWrapsModerationRouteText(t *testing.T) {
	t.Parallel()

	raw, err := embeddedFiles.ReadFile("static/css/admin.css")
	if err != nil {
		t.Fatalf("read embedded admin css: %v", err)
	}
	css := string(raw)
	for _, expected := range []string{
		".timeline-body",
		"min-width: 0;",
		"overflow-wrap: anywhere;",
	} {
		if !strings.Contains(css, expected) {
			t.Fatalf("admin css does not contain %q: %s", expected, css)
		}
	}
}

func TestExcursionMeetingPointTextUsesLocalizedValue(t *testing.T) {
	t.Parallel()

	withTranslation := &model.ExcursionModerationItem{
		MeetingPoint: "Medeu entrance",
		MeetingPointByLocale: map[string]string{
			"ru": "Главный вход Медеу",
		},
	}
	if got := excursionMeetingPointText(localeRU, withTranslation); got != "Главный вход Медеу" {
		t.Fatalf("excursionMeetingPointText() = %q, want localized meeting point", got)
	}

	seedValue := &model.ExcursionModerationItem{MeetingPoint: "Medeu entrance"}
	if got := excursionMeetingPointText(localeRU, seedValue); got != "Вход Медеу" {
		t.Fatalf("excursionMeetingPointText() = %q, want readable Russian fallback", got)
	}
}
