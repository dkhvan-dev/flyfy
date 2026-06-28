package http

import (
	"bytes"
	"encoding/json"
	"html"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestRendererRendersCoreTemplates(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "moderator@inflap.local",
		DisplayName: "Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionFraudReview,
		},
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
		PlaceNames:       []string{"Kok-Tobe", "Cathedral"},
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
		"auth/login":           LoginViewData{Email: "moderator@inflap.local"},
		"auth/change_password": nil,
		"dashboard/index":      NewDashboardViewData([]*model.ModerationCase{queueCase}, nil, nil, nil),
		"feed_quality/index": NewFeedQualityDashboardViewData(app.FeedQualityDashboardPage{
			Metrics: []model.FeedQualityMetric{{
				Surface:            "home",
				Tab:                "for_you",
				BlockType:          "post_card",
				Action:             "conversion",
				RankingExperiment:  "rank-v2",
				CandidateSource:    "social",
				PostProfile:        "event_announcement_v1",
				CommunityID:        "00000000-0000-4000-8000-000000000222",
				EventCount:         12,
				UniqueViewers:      7,
				ConversionCount:    4,
				HideCount:          1,
				NotInterestedCount: 2,
				ReportCount:        3,
			}},
			ExperimentSummaries: []app.FeedQualityExperimentSummary{{
				Experiment: "rank-v2",
				Totals: model.FeedQualityMetric{
					EventCount:      12,
					ImpressionCount: 20,
					ClickCount:      8,
					DwellCount:      5,
					AvgDwellMs:      4200,
					ConversionCount: 4,
					HideCount:       1,
					ReportCount:     3,
				},
			}},
			Totals: model.FeedQualityMetric{
				EventCount:         12,
				UniqueViewers:      7,
				ConversionCount:    4,
				HideCount:          1,
				NotInterestedCount: 2,
				ReportCount:        3,
			},
		}, FeedQualityFilterViewData{Surface: "home", Window: "7d"}),
		"communities/index": NewCommunityPlatformViewData(model.CommunityPlatformCatalog{
			PostProfiles: []model.CommunityPostProfile{{
				Key:                  "quick_post_v1",
				PostKind:             "QUICK_POST",
				ComposerPreset:       "quick_post",
				RenderPreset:         "quick_post_card",
				ModerationMode:       "PUBLISH_FIRST",
				ActivityCreationMode: "DISABLED",
			}},
			Blueprints: []model.CommunityBlueprint{{
				ID:                    uuid.MustParse("00000000-0000-4000-8000-000000000014"),
				Key:                   "football",
				Category:              "sports",
				DefaultPostProfileKey: "event_announcement_v1",
				TitleI18n: map[string]string{
					"en": "Football",
					"ru": "Футбол",
					"kk": "Футбол",
				},
				DescriptionI18n:       map[string]string{"en": "Games and meetups"},
				AllowedScopeTypes:     []string{"CITY"},
				RolloutPolicy:         "ELIGIBLE_HUBS",
				DefaultModerationMode: "TRUSTED_PUBLISH_ELSE_REVIEW",
				Status:                "ACTIVE",
			}},
			GeoHubs: []model.CommunityGeoHub{{
				CountryCode:      "VN",
				CityID:           "da-nang",
				HubTier:          "REGIONAL",
				CommunityEnabled: true,
				Reason:           "tourist_demand",
				Priority:         30,
				CanMaterialize:   true,
				EffectiveCountry: "VN",
				EffectiveCityID:  "da-nang",
				CreatedBy:        "seed",
			}},
			Instances: []model.CommunityInstance{{
				ID:          uuid.MustParse("00000000-0000-4000-8000-000000000111"),
				CommunityID: uuidPtr(uuid.MustParse("00000000-0000-4000-8000-000000000222")),
				BlueprintID: uuid.MustParse("00000000-0000-4000-8000-000000000014"),
				Slug:        "football-vn-da-nang",
				CountryCode: "VN",
				CityID:      stringPtr("da-nang"),
				ScopeType:   "CITY",
				TitleI18n:   map[string]string{"en": "Football · Da Nang"},
				Status:      "ACTIVE",
			}},
		}, CommunityPlatformFilterViewData{
			CountryCode: "VN",
			CityID:      "da-nang",
			ScopeType:   "CITY",
			Search:      "foot",
			Limit:       25,
			Offset:      5,
		}),
		"communities/form": NewCommunityFormViewData(CommunityFormInput{
			Slug:        "football-vn-da-nang",
			Topic:       "SPORTS",
			CountryCode: "VN",
			CityID:      "da-nang",
			TitleI18n: map[string]string{
				"ru": "Футбол",
				"en": "Football",
				"kk": "Футбол",
			},
			DescriptionI18n: map[string]string{
				"ru": "Игры в Дананге",
				"en": "Games in Da Nang",
				"kk": "Дананг ойындары",
			},
		}),
		"moderation/queue": NewQueueViewData([]*model.ModerationCase{queueCase}, QueueFilterViewData{
			Status: excursionQueueStatusActive,
			City:   "Almaty",
			Search: "Kok",
			Signal: "new_guide",
			Risk:   string(model.ModerationRiskFilterHigh),
			Sort:   string(model.ModerationQueueSortRiskDesc),
			Query:  "status=active&city=Almaty&q=Kok&signal=new_guide&risk=high&sort=risk_desc",
		}),
		"fraud/blocks": NewFraudBlockListViewData(model.FraudBlockTargetActivity, []model.FraudBlock{
			{
				ID:           uuid.New(),
				Action:       "ACTIVITY_CREATE",
				SubjectType:  "ACTIVITY",
				SubjectID:    &excursionID,
				Decision:     "REVIEW",
				RiskScore:    72,
				Reasons:      []string{"ACTIVITY_CREATE_VELOCITY"},
				ReviewStatus: "OPEN",
				CreatedAt:    now,
			},
		}),
		"staff/index":      StaffListViewData{Staff: []*model.StaffUser{staff}},
		"audit/index":      AuditViewData{Events: []*model.AuditEvent{}},
		"navigation/index": NewAdminNavigationPageViewData(staff),
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
			if !strings.Contains(recorder.Body.String(), "Inflap") {
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
			if name == "feed_quality/index" {
				body := html.UnescapeString(recorder.Body.String())
				for _, expected := range []string{
					"Feed quality",
					"Feed section",
					"All feed sections",
					"Home feed",
					"For you",
					"Post card",
					"Community",
					"00000000",
					"Conversion click",
					"Ranking experiment",
					"Rank V2",
					"Candidate source",
					"Friends and follows",
					"Event announcement",
					"Impressions",
					"Avg. dwell",
					"Engagement",
					"Negative feedback",
					"Reports",
					"Report rate",
					"Dwell rate",
					"Subscribe rate",
					"Click Δ vs control",
					"Conversion Δ vs control",
					"Negative Δ vs control",
					"Ranking experiment comparison",
					"Compare ranking variants by conversion and negative feedback before changing weights.",
				} {
					if !strings.Contains(body, expected) {
						t.Fatalf("feed quality dashboard did not render %q: %s", expected, body)
					}
				}
				for _, forbidden := range []string{
					">Surface<",
					">home<",
					">for_you<",
					">post_card<",
					">conversion<",
					">event_announcement_v1<",
					">social<",
				} {
					if strings.Contains(body, forbidden) {
						t.Fatalf("feed quality dashboard rendered raw code %q: %s", forbidden, body)
					}
				}
				lowerBody := strings.ToLower(body)
				for _, forbidden := range []string{"watch start", "buffering"} {
					if strings.Contains(lowerBody, forbidden) {
						t.Fatalf("feed quality dashboard must not render video-specific metrics: %s", body)
					}
				}
			}
			if name == "communities/index" {
				body := html.UnescapeString(recorder.Body.String())
				for _, expected := range []string{
					"Community platform",
					"Create a single community",
					"Generate communities from templates",
					`data-location-filter-form`,
					`data-country-filter-input`,
					`data-city-filter-input`,
					`name="country_code" value="VN" data-country-filter-value`,
					`name="city_id" value="da-nang" data-city-filter-value`,
					`name="scope_type"`,
					`name="q" value="foot"`,
					`name="limit" value="25" min="1" max="500"`,
					`data-table-search`,
					`data-table-filter`,
					"Football",
					"Da Nang",
					"Quick post",
					`href="/admin/communities/00000000-0000-4000-8000-000000000222/edit"`,
					"/admin/communities/materialize",
					`data-modal-open="community-post-profiles-dialog"`,
					`data-modal-open="community-blueprints-dialog"`,
					`data-modal-open="community-geo-hubs-dialog"`,
					`data-modal-open="community-instances-dialog"`,
					`data-paginated-table`,
				} {
					if !strings.Contains(body, expected) {
						t.Fatalf("community platform did not render %q: %s", expected, body)
					}
				}
				for _, forbidden := range []string{
					">quick_post_v1<",
					">quick_post<",
					">quick_post_card<",
					">PUBLISH_FIRST<",
					">REGIONAL<",
					">tourist_demand<",
					">CITY<",
					">sports<",
					"football-vn-da-nang ·",
				} {
					if strings.Contains(body, forbidden) {
						t.Fatalf("community platform rendered raw code %q: %s", forbidden, body)
					}
				}
				filterIndex := strings.Index(body, `class="filters card"`)
				metricsIndex := strings.Index(body, `class="community-resource-grid"`)
				materializeIndex := strings.Index(body, "Generate communities from templates")
				if filterIndex < 0 || metricsIndex < 0 || materializeIndex < 0 {
					t.Fatalf("community platform missing expected section markers: %s", body)
				}
				if !(filterIndex < metricsIndex && metricsIndex < materializeIndex) {
					t.Fatalf("community platform section order = filter:%d metrics:%d materialize:%d, want filters before metrics before materialize", filterIndex, metricsIndex, materializeIndex)
				}
			}
			if name == "communities/form" {
				body := html.UnescapeString(recorder.Body.String())
				for _, expected := range []string{
					`enctype="multipart/form-data"`,
					`<select name="slug"`,
					`data-location-filter-form`,
					`data-country-filter-input`,
					`data-city-filter-input`,
					`name="country_code" value="VN" data-country-filter-value`,
					`name="city_id" value="da-nang" data-city-filter-value`,
					`type="file" name="avatar_image"`,
					`type="file" name="cover_image"`,
					"football-vn-da-nang",
					"Da Nang",
				} {
					if !strings.Contains(body, expected) {
						t.Fatalf("community form did not render %q: %s", expected, body)
					}
				}
				for _, forbidden := range []string{
					`name="avatar_file_id"`,
					`name="cover_file_id"`,
				} {
					if strings.Contains(body, forbidden) {
						t.Fatalf("community form still exposes raw file id input %q: %s", forbidden, body)
					}
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
					`/admin/moderation/excursions/fraud-blocks`,
					`/admin/moderation/excursions/sync?status=active&amp;city=Almaty&amp;q=Kok&amp;signal=new_guide&amp;risk=high&amp;sort=risk_desc`,
					`/admin/moderation/excursions`,
				} {
					if !strings.Contains(recorder.Body.String(), expected) {
						t.Fatalf("moderation queue did not render filter control %q: %s", expected, recorder.Body.String())
					}
				}
			}
			if name == "fraud/blocks" {
				body := html.UnescapeString(recorder.Body.String())
				for _, expected := range []string{
					"Anti-fraud blocks",
					"ACTIVITY_CREATE",
					"ACTIVITY_CREATE_VELOCITY",
					"False positive",
					"Escalate",
					"Confirm fraud",
				} {
					if !strings.Contains(body, expected) {
						t.Fatalf("fraud blocks page did not render %q: %s", expected, body)
					}
				}
				if strings.Contains(body, "Approve") {
					t.Fatalf("fraud blocks page must not render direct publish/approve action: %s", body)
				}
			}
		})
	}
}

func TestRendererRendersOperationsViewsWithoutLegacyScopeValueField(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Date(2026, 6, 19, 15, 0, 0, 0, time.UTC)
	domain := model.OperationDomain{
		FeatureFlagServiceID: 1,
		TechBreakServiceID:   2,
		Code:                 "CORE",
		Description:          "Core команда",
		CreatedBy:            "admin@inflap.local",
		CreatedAt:            now,
		UpdatedAt:            &now,
		UpdatedBy:            "ops@inflap.local",
		FeatureFlagGroups:    []string{"onboarding"},
	}
	flag := model.OperationFeatureFlag{
		DomainCode:      "CORE",
		Code:            "NEED_CHECK_AUTH_PASSWORD",
		Name:            "Проверка пароля при авторизации",
		Group:           "onboarding",
		Type:            "TOGGLE",
		Enabled:         false,
		ActionStartDate: now,
		CreatedAt:       now,
		CreatedBy:       "admin@inflap.local",
	}
	techBreak := model.OperationTechBreak{
		ID:              7,
		DomainCode:      "CORE",
		Name:            "core tech break",
		Enabled:         true,
		ActionStartDate: now,
		ActionEndDate:   &now,
		CreatedAt:       now,
		CreatedBy:       "admin@inflap.local",
	}
	scope := model.OperationTechBreakScope{
		ID:         8,
		DomainCode: "CORE",
		Code:       "CORE_TEST",
		Name:       "для теста scope",
		CreatedAt:  now,
		CreatedBy:  "admin@inflap.local",
	}
	pageData := PageData{
		Title:     "Операции",
		Locale:    localeRU,
		Path:      "/admin/operations",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
	}

	pageData.Data = NewOperationsDomainListViewData(model.OperationDomainPage{
		Content:       []model.OperationDomain{domain},
		Page:          0,
		Size:          20,
		TotalElements: 1,
		TotalPages:    1,
	}, OperationsDomainFilterViewData{Search: "core", Size: 20})
	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "operations/index", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("operations index status = %d, body: %s", recorder.Code, recorder.Body.String())
	}
	body := html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		"Операции",
		"Домены",
		"CORE",
		"Core команда",
		`href="/admin/operations/domains/CORE"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("operations index did not render %q: %s", expected, body)
		}
	}

	pageData.Path = "/admin/operations/domains/CORE"
	pageData.Data = NewOperationsDomainDetailViewData(app.OperationsDomainDetailPage{
		Domain: domain,
		FeatureFlags: model.OperationPage[model.OperationFeatureFlag]{
			Content: []model.OperationFeatureFlag{flag},
		},
		TechBreaks: model.OperationPage[model.OperationTechBreak]{
			Content: []model.OperationTechBreak{techBreak},
		},
		Scopes: []model.OperationTechBreakScope{scope},
	}, OperationsTabScopes, OperationsResourceFilterViewData{Size: 20})
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "operations/domain", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("operations domain status = %d, body: %s", recorder.Code, recorder.Body.String())
	}
	body = html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		"Домен: Core команда",
		"Фича флаги",
		"Тех. перерывы",
		"Scope'ы тех. перерывов",
		"CORE_TEST",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("operations domain did not render %q: %s", expected, body)
		}
	}
	if strings.Contains(body, "Поддерживает значения") {
		t.Fatalf("operations scope tab rendered unsupported legacy field: %s", body)
	}

	pageData.Data = NewOperationsDomainDetailViewData(app.OperationsDomainDetailPage{
		Domain: domain,
		FeatureFlags: model.OperationPage[model.OperationFeatureFlag]{
			Content: []model.OperationFeatureFlag{flag},
		},
		TechBreaks: model.OperationPage[model.OperationTechBreak]{
			Content: []model.OperationTechBreak{techBreak},
		},
		Scopes: []model.OperationTechBreakScope{scope},
	}, OperationsTabDomain, OperationsResourceFilterViewData{Size: 20})
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "operations/domain", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("operations domain tab status = %d, body: %s", recorder.Code, recorder.Body.String())
	}
	body = html.UnescapeString(recorder.Body.String())
	for _, legacy := range []string{"Категории значений тех. перерывов", "transfer_type"} {
		if strings.Contains(body, legacy) {
			t.Fatalf("operations domain rendered legacy tech break value category %q: %s", legacy, body)
		}
	}

	pageData.Data = NewOperationsDomainDetailViewData(app.OperationsDomainDetailPage{
		Domain: domain,
		FeatureFlags: model.OperationPage[model.OperationFeatureFlag]{
			Content: []model.OperationFeatureFlag{flag},
		},
		TechBreaks: model.OperationPage[model.OperationTechBreak]{
			Content: []model.OperationTechBreak{techBreak},
		},
		Scopes: []model.OperationTechBreakScope{scope},
	}, OperationsTabFeatureFlags, OperationsResourceFilterViewData{Size: 20})
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "operations/domain", pageData)
	if !strings.Contains(html.UnescapeString(recorder.Body.String()), "NEED_CHECK_AUTH_PASSWORD") {
		t.Fatalf("operations feature flag tab did not render flag: %s", recorder.Body.String())
	}

	arrayFlag := flag
	arrayFlag.Type = "ARRAY_STRING"
	arrayFlag.Value = []any{"ios", "android"}
	pageData.Data = NewOperationsFeatureFlagFormViewData(app.OperationsFeatureFlagDetailPage{
		Domain: domain,
		Flag:   arrayFlag,
	}, false)
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "operations/feature_flag_form", pageData)
	body = html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		`list="feature-flag-groups"`,
		`<option value="onboarding"></option>`,
		`data-feature-flag-values`,
		`name="value" value="ios"`,
		`name="value" value="android"`,
		"Добавить значение",
		`/admin/operations/domains/CORE/feature-flags/NEED_CHECK_AUTH_PASSWORD/history`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("operations feature flag form did not render %q: %s", expected, body)
		}
	}
	if strings.Contains(body, "Дата изменения") {
		t.Fatalf("operations feature flag form must not render inline history table: %s", body)
	}
	if strings.Contains(body, `<textarea name="value"`) {
		t.Fatalf("operations feature flag form must not render raw value textarea: %s", body)
	}

	pageData.Data = NewOperationsFeatureFlagHistoryViewData(app.OperationsFeatureFlagDetailPage{
		Domain: domain,
		Flag:   arrayFlag,
		History: model.OperationPage[model.OperationFeatureFlagHistory]{
			Content: []model.OperationFeatureFlagHistory{
				{
					UpdatedAt:       now,
					UpdatedBy:       "u00026321",
					Name:            "Проверка пароля при авторизации",
					Group:           "onboarding",
					Enabled:         true,
					ActionStartDate: now,
					InArchive:       false,
					Value:           []any{"ios"},
				},
			},
			Page:          1,
			Size:          20,
			TotalElements: 41,
			TotalPages:    3,
		},
	}, OperationsHistoryPaginationFilterViewData{Page: 1, Size: 20})
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "operations/feature_flag_history", pageData)
	body = html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		"История изменений",
		"Дата изменения",
		"u00026321",
		`/admin/operations/domains/CORE/feature-flags/NEED_CHECK_AUTH_PASSWORD`,
		`page=0`,
		`page=2`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("operations feature flag history did not render %q: %s", expected, body)
		}
	}

	pageData.Data = NewOperationsDomainDetailViewData(app.OperationsDomainDetailPage{
		Domain: domain,
		FeatureFlags: model.OperationPage[model.OperationFeatureFlag]{
			Content: []model.OperationFeatureFlag{flag},
		},
		TechBreaks: model.OperationPage[model.OperationTechBreak]{
			Content: []model.OperationTechBreak{techBreak},
		},
		Scopes: []model.OperationTechBreakScope{scope},
	}, OperationsTabTechBreaks, OperationsResourceFilterViewData{Size: 20})
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "operations/domain", pageData)
	if !strings.Contains(html.UnescapeString(recorder.Body.String()), "core tech break") {
		t.Fatalf("operations tech break tab did not render break: %s", recorder.Body.String())
	}

	techBreak.ScopeCodes = []string{"CORE_TEST"}
	pageData.Data = NewOperationsTechBreakFormViewData(app.OperationsTechBreakDetailPage{
		Domain: domain,
		Break:  techBreak,
		Scopes: []model.OperationTechBreakScope{scope},
	}, false)
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "operations/tech_break_form", pageData)
	body = html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		`<select name="scope_codes"`,
		`<option value="CORE_TEST" selected>CORE_TEST · для теста scope</option>`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("operations tech break form did not render %q: %s", expected, body)
		}
	}
	for _, forbidden := range []string{
		`type="checkbox" name="scope_codes"`,
		`<textarea name="value"`,
	} {
		if strings.Contains(body, forbidden) {
			t.Fatalf("operations tech break form rendered forbidden control %q: %s", forbidden, body)
		}
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
	topbar := renderedTopbar(body)
	if strings.Contains(topbar, `href="/admin/audit"`) {
		t.Fatalf("audit nav link rendered without audit.read permission: %s", topbar)
	}
	if strings.Contains(topbar, `href="/admin/users"`) {
		t.Fatalf("users nav link rendered in compact topbar: %s", topbar)
	}
	if strings.Contains(topbar, `href="/admin/moderation/excursions"`) {
		t.Fatalf("moderation queue link rendered in compact topbar: %s", topbar)
	}
	if !strings.Contains(topbar, `href="/admin/navigation"`) {
		t.Fatalf("sections link is missing from compact topbar: %s", topbar)
	}
	if !strings.Contains(topbar, `href="/admin/me"`) {
		t.Fatalf("own profile link is missing from topbar: %s", topbar)
	}

	staff.Permissions = append(staff.Permissions, enum.PermissionAuditRead)
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "dashboard/index", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	topbar = renderedTopbar(recorder.Body.String())
	if strings.Contains(topbar, `href="/admin/audit"`) {
		t.Fatalf("audit nav link rendered in compact topbar: %s", topbar)
	}

	staff.Permissions = append(staff.Permissions, enum.PermissionUsersRead)
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "dashboard/index", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	topbar = renderedTopbar(recorder.Body.String())
	if strings.Contains(topbar, `href="/admin/users"`) {
		t.Fatalf("users nav link rendered in compact topbar: %s", topbar)
	}

	pageData.Path = "/admin/navigation"
	pageData.ActiveNav = "navigation"
	pageData.Data = NewAdminNavigationPageViewData(staff)
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "navigation/index", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body = recorder.Body.String()
	for _, expected := range []string{
		`href="/admin/moderation/excursions"`,
		`href="/admin/users"`,
		`href="/admin/audit"`,
		`href="/admin/staff"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("navigation page did not render %q: %s", expected, body)
		}
	}
}

func renderedTopbar(body string) string {
	start := strings.Index(body, `<header class="topbar">`)
	end := strings.Index(body, `</header>`)
	if start < 0 || end < start {
		return body
	}
	return body[start : end+len(`</header>`)]
}

func TestRendererRendersUserModerationViews(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	now := time.Date(2026, 5, 30, 8, 0, 0, 0, time.UTC)
	userID := uuid.New()
	caseID := uuid.New()
	restrictionID := uuid.New()
	staff := adminTemplateActor()
	staff.Permissions = append(staff.Permissions,
		enum.PermissionUsersRead,
		enum.PermissionUsersModerate,
		enum.PermissionUsersRestrict,
	)
	pageData := PageData{
		Title:     "Users",
		Locale:    localeEN,
		Path:      "/admin/users",
		Staff:     staff,
		CSRFToken: "csrf-token",
		Data: NewAdminUsersListViewData(model.AdminUserListPage{
			Items: []model.AdminUserListItem{
				{
					UserID:                  userID,
					Nickname:                "Aruzhan Traveler",
					MaskedPhone:             "+7******67",
					MaskedEmail:             "a***@***",
					CountryCode:             "KZ",
					Roles:                   []string{"traveler", "guide"},
					AccountStatus:           "ACTIVE",
					GuideStatus:             "VERIFIED",
					OpenModerationCaseCount: 1,
					ActiveRestrictionCount:  1,
					CreatedAt:               now,
					LastActiveAt:            &now,
				},
			},
			NextPageToken: "cursor-2",
		}, AdminUsersFilterViewData{Search: "aru", Status: "ACTIVE", Role: "GUIDE", CountryCode: "KZ", PageSize: 25}, staff),
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "users/index", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body := html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		"Aruzhan Traveler",
		"+7******67",
		"a***@***",
		"Open cases",
		"Restrictions",
		`data-country-filter-form`,
		`type="hidden" name="country" value="KZ" data-country-filter-value`,
		`type="search" data-country-filter-input value="Kazakhstan"`,
		`data-country-filter-suggestions role="listbox" hidden`,
		`type="button" class="filter-suggestion" data-country-filter-option`,
		`<select name="role">`,
		`<option value="GUIDE" selected>Guide</option>`,
		`href="/admin/users/` + userID.String() + `"`,
		`country=KZ`,
		`role=GUIDE`,
		`page_token=cursor-2`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("users list did not render %q: %s", expected, body)
		}
	}
	if strings.Contains(body, `name="role" value="GUIDE"`) {
		t.Fatalf("users list still renders manual role input: %s", body)
	}
	if strings.Contains(body, `name="city"`) {
		t.Fatalf("users list country filter must not render city filter controls: %s", body)
	}
	if strings.Contains(body, "+77001234567") || strings.Contains(body, "aruzhan@example.com") {
		t.Fatalf("users list rendered unmasked identity data: %s", body)
	}

	pageData.Title = "User detail"
	pageData.Path = "/admin/users/" + userID.String()
	pageData.Data = NewAdminUserDetailViewData(model.AdminUserDetailPage{
		User: model.AdminUserDetail{
			UserID:                  userID,
			Nickname:                "Aruzhan Traveler",
			MaskedPhone:             "+7******67",
			MaskedEmail:             "a***@***",
			CountryCode:             "KZ",
			Roles:                   []string{"traveler", "guide"},
			AccountStatus:           "ACTIVE",
			GuideStatus:             "VERIFIED",
			OpenModerationCaseCount: 1,
			ActiveRestrictionCount:  1,
			CreatedAt:               now,
			UpdatedAt:               now,
			LastActiveAt:            &now,
		},
		ModerationCases: []model.UserModerationCase{
			{
				ID:           caseID,
				TargetUserID: userID,
				Source:       model.UserModerationSourceStaff,
				ReasonCode:   "policy_violation",
				Priority:     model.UserModerationPriorityHigh,
				Status:       model.UserModerationStatusOpen,
				StaffComment: "Needs manual review",
				CreatedAt:    now,
				UpdatedAt:    now,
			},
		},
		ActiveRestrictions: []model.UserManualRestriction{
			{
				ID:               restrictionID,
				UserID:           userID,
				RestrictionCode:  model.UserRestrictionActivityCreation,
				Status:           model.UserRestrictionStatusActive,
				ReasonCode:       "policy_violation",
				StaffComment:     "Temporary hold",
				CreatedByStaffID: staff.ID,
				CreatedAt:        now,
			},
		},
	}, staff)

	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "users/detail", pageData)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	body = html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		"Aruzhan Traveler",
		"Kazakhstan (KZ)",
		"policy_violation",
		"Needs manual review",
		"Temporary hold",
		`action="/admin/users/` + userID.String() + `/moderation-cases"`,
		`<select name="reason_code" required>`,
		`value="unsafe_behavior"`,
		`action="/admin/users/` + userID.String() + `/moderation-cases/` + caseID.String() + `/resolve"`,
		`action="/admin/users/` + userID.String() + `/restrictions"`,
		`action="/admin/users/` + userID.String() + `/restrictions/` + restrictionID.String() + `/lift"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("user detail did not render %q: %s", expected, body)
		}
	}
	if strings.Contains(body, "+77001234567") || strings.Contains(body, "aruzhan@example.com") {
		t.Fatalf("user detail rendered unmasked identity data: %s", body)
	}
	if strings.Contains(body, `name="reason_code" required placeholder`) {
		t.Fatalf("user detail rendered manual reason input for moderation case: %s", body)
	}
}

func TestRendererRendersTrustAppealViews(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	now := time.Date(2026, 6, 12, 8, 0, 0, 0, time.UTC)
	appealID := uuid.New()
	userID := uuid.New()
	restrictionID := uuid.New()
	staff := adminTemplateActor()
	staff.Permissions = append(staff.Permissions,
		enum.PermissionUsersRead,
		enum.PermissionUsersRestrict,
	)
	item := model.TrustRestrictionAppeal{
		ID:              appealID,
		RestrictionID:   restrictionID,
		UserID:          userID,
		RestrictionCode: model.UserRestrictionChat,
		Status:          model.TrustRestrictionAppealStatusOpen,
		ReasonCode:      "false_positive",
		UserMessage:     "This was a safety contact for the trip group.",
		CreatedAt:       now,
		UpdatedAt:       now,
	}
	filters := TrustAppealFilterViewData{
		Status:   string(model.TrustRestrictionAppealStatusOpen),
		Search:   "false",
		PageSize: 25,
		Query:    "page_size=25&q=false",
	}
	pageData := PageData{
		Title:     "Trust appeals",
		Locale:    localeEN,
		Path:      "/admin/trust/appeals",
		Staff:     staff,
		CSRFToken: "csrf-token",
		Data: NewTrustAppealListViewData(model.TrustRestrictionAppealListPage{
			Items:         []model.TrustRestrictionAppeal{item},
			NextPageToken: "cursor-2",
		}, filters, staff),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "trust/appeals", pageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		"Restriction appeals",
		"false_positive",
		"This was a safety contact",
		`href="/admin/trust/appeals/` + appealID.String() + `?page_size=25&q=false"`,
		`href="/admin/users/` + userID.String() + `"`,
		`page_token=cursor-2`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("trust appeal queue did not render %q: %s", expected, body)
		}
	}

	pageData.Title = "Trust appeal"
	pageData.Path = "/admin/trust/appeals/" + appealID.String() + "?page_size=25&q=false"
	pageData.Data = NewTrustAppealDetailViewData(item, filters, staff)
	rendered.Reset()
	if err = renderer.templates.ExecuteTemplate(&rendered, "trust/appeal_detail", pageData); err != nil {
		t.Fatalf("ExecuteTemplate detail returned error: %v", err)
	}
	body = html.UnescapeString(rendered.String())
	for _, expected := range []string{
		"This was a safety contact for the trip group.",
		`action="/admin/trust/appeals/` + appealID.String() + `/approve?page_size=25&q=false"`,
		`action="/admin/trust/appeals/` + appealID.String() + `/reject?page_size=25&q=false"`,
		`name="staff_comment" rows="3" required`,
		`name="idempotency_key"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("trust appeal detail did not render %q: %s", expected, body)
		}
	}
}

func TestRendererRendersPlaceEditFormWithOptionalValues(t *testing.T) {
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
	onSiteMin := 90
	onSiteMax := 150
	driveMin := 180
	driveMax := 240
	feeAmount := 1000.0
	item := &model.AdminPlace{
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
		VisitInfo: model.PlaceVisitInfo{
			PriceNote:     "Билет и экосбор отдельно",
			TimeOnSite:    &model.PlaceVisitDuration{MinMinutes: &onSiteMin, MaxMinutes: &onSiteMax, Note: "Без трека к реке"},
			CarTravelTime: &model.PlaceVisitDuration{MinMinutes: &driveMin, MaxMinutes: &driveMax, Note: "От Алматы"},
			RoadCondition: "PAVED",
			FeeDetails: []model.PlaceFeeDetail{
				{Title: "Вход", Description: "Базовый билет", Amount: &feeAmount, Currency: "KZT", Unit: "PERSON", IsApproximate: true, SortOrder: 10},
			},
			FeeItems: []model.PlaceFeeDetail{
				{Type: "ENTRANCE", Title: "Вход в парк", MinAmount: &feeAmount, MaxAmount: &feeAmount, Currency: "KZT", Unit: "PERSON", Required: true, IsApproximate: true, Note: "Цена может меняться", SortOrder: 10},
			},
			AccessOptions: []model.PlaceAccessOption{
				{TransportType: "CAR", DurationMinMinutes: &driveMin, DurationMaxMinutes: &driveMax, RouteHint: "Трасса на Кеген", RoadCondition: "PAVED", ParkingNote: "Парковка у входа", SortOrder: 10},
			},
			PracticalNotes: []model.PlacePracticalNote{
				{NoteType: "WEATHER", Title: "Жара", Body: "Летом мало тени", Priority: "IMPORTANT", SortOrder: 10},
			},
			RecommendedItems: []model.PlaceRecommendedItem{
				{ItemType: "WATER", Title: "Вода", Note: "Минимум 1 литр", Importance: "REQUIRED", SortOrder: 10},
			},
		},
		Translations: map[string]model.PlaceTranslation{
			localeRU: {
				Title:       "Большое Алматинское озеро",
				Description: "Горное озеро рядом с Алматы.",
			},
		},
		Media: []model.AdminPlaceMedia{
			{
				FileID:    uuid.New(),
				MediaType: "IMAGE",
				Position:  0,
			},
		},
	}
	pageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + item.ID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(item, model.PlaceInput{}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/form", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	if !strings.Contains(body, "Большое Алматинское озеро") ||
		!strings.Contains(body, "/admin/place-media/") {
		t.Fatalf("place edit form did not render useful content: %s", body)
	}
	for _, expected := range []string{
		`<select name="country_code" required data-place-country-select>`,
		`<select name="city_id" required data-place-city-select>`,
		`<select name="price_currency">`,
		`name="location_source_url" value="https://www.openstreetmap.org/" placeholder="https://maps..." data-map-url-input`,
		`name="latitude" value="43.243534" inputmode="decimal" data-latitude-input`,
		`name="longitude" value="76.904129" inputmode="decimal" data-longitude-input`,
		`href="/admin/places/` + item.ID.String() + `/visit-info/edit"`,
		`type="checkbox" name="access_cities" value="KZ:almaty"`,
		`type="checkbox" name="departure_cities" value="KZ:almaty"`,
		`data-place-media-form`,
		`data-confirm-form="mediaManage"`,
		`name="media_action" value="manage" data-media-action-input`,
		`data-media-card`,
		`name="media_ids"`,
		`data-media-move="up"`,
		`data-media-move="down"`,
		`data-media-delete`,
		`data-media-delete-fields`,
		`data-place-media-input`,
		`data-place-media-preview hidden`,
		`data-place-media-preview-list`,
		`data-place-media-count`,
		`data-place-media-manage-submit disabled`,
		`data-place-media-append-submit disabled`,
		`data-place-media-replace-submit disabled`,
		`data-media-action="append"`,
		`data-media-action="replace"`,
		`id="decision-confirmation-dialog"`,
		`Проверьте выбранные изображения и их порядок перед сохранением.`,
		`data-required-locale="ru"`,
		`Обязательное поле.`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("place edit form did not render expected control %q: %s", expected, body)
		}
	}
	for _, unexpected := range []string{
		`name="visit_price_note"`,
		`name="visit_fee_detail_title_0"`,
		`name="visit_access_route_hint_0"`,
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("place edit form still renders visit-info field %q: %s", unexpected, body)
		}
	}
}

func TestRendererRendersPlaceVisitInfoFormWithAllLocales(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	minOnSite := 90
	maxOnSite := 150
	feeAmount := 1000.0
	priceCurrency := "KZT"
	item := &model.AdminPlace{
		ID:            uuid.New(),
		DefaultLocale: localeRU,
		Title:         "Чарынский каньон",
		PriceCurrency: &priceCurrency,
		VisitInfo: model.PlaceVisitInfo{
			BestTime:            "MORNING",
			OpeningHoursLocales: map[string]string{"ru": "Ежедневно 09:00-18:00", "en": "Daily 09:00-18:00", "kk": "Күн сайын 09:00-18:00"},
			PriceNoteLocales:    map[string]string{"ru": "Билет и экосбор отдельно", "en": "Ticket and eco fee are paid separately", "kk": "Билет пен экоалым бөлек төленеді"},
			TimeOnSite: &model.PlaceVisitDuration{
				MinMinutes:  &minOnSite,
				MaxMinutes:  &maxOnSite,
				NoteLocales: map[string]string{"ru": "Без трека к реке", "en": "Without the river trail", "kk": "Өзен соқпағынсыз"},
			},
			FeeDetails: []model.PlaceFeeDetail{
				{
					TitleLocales:       map[string]string{"ru": "Вход", "en": "Admission", "kk": "Кіру"},
					DescriptionLocales: map[string]string{"ru": "Базовый билет", "en": "Base ticket", "kk": "Негізгі билет"},
					Amount:             &feeAmount,
					Currency:           "KZT",
					Unit:               "PERSON",
					IsApproximate:      true,
					SortOrder:          10,
				},
			},
			FeeItems: []model.PlaceFeeDetail{
				{
					Type:          "ENTRANCE",
					TitleLocales:  map[string]string{"ru": "Вход в парк", "en": "Park admission", "kk": "Паркке кіру"},
					MinAmount:     &feeAmount,
					MaxAmount:     &feeAmount,
					Currency:      "KZT",
					Unit:          "PERSON",
					Required:      true,
					IsApproximate: true,
					SortOrder:     10,
				},
			},
			RoadCondition: "PAVED",
			AccessOptions: []model.PlaceAccessOption{
				{TransportType: "CAR", RoadCondition: "PAVED", SortOrder: 10},
			},
			PracticalNotes: []model.PlacePracticalNote{
				{NoteType: "GENERAL", Priority: "IMPORTANT", SortOrder: 10},
			},
			RecommendedItems: []model.PlaceRecommendedItem{
				{
					ItemType:     "WATER",
					TitleLocales: map[string]string{"ru": "Вода", "en": "Water", "kk": "Су"},
					NoteLocales:  map[string]string{"ru": "Минимум 1 литр", "en": "At least 1 liter", "kk": "Кемінде 1 литр"},
					Importance:   "REQUIRED",
					Season:       "SUMMER",
					SortOrder:    10,
				},
				{
					ItemType:     "SHOES",
					TitleLocales: map[string]string{"ru": "Удобная обувь", "en": "Comfortable shoes", "kk": "Ыңғайлы аяқ киім"},
					Importance:   "REQUIRED",
					SortOrder:    20,
				},
			},
		},
	}
	pageData := PageData{
		Title:     "Visit information",
		Locale:    localeRU,
		Path:      "/admin/places/" + item.ID.String() + "/visit-info/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data: NewPlaceVisitInfoFormViewData(item, "", model.PlaceVisitReferenceCatalog{
			Categories: map[string][]model.PlaceVisitReferenceValue{
				"best_time":                   {model.PlaceVisitReferenceValue{Code: "MORNING", Label: "Утро", Labels: map[string]string{"ru": "Утро", "en": "Morning", "kk": "Таң"}, SortOrder: 10, Active: true}},
				"fee_type":                    {model.PlaceVisitReferenceValue{Code: "ENTRANCE", Label: "Вход", Labels: map[string]string{"ru": "Вход", "en": "Entrance", "kk": "Кіру"}, SortOrder: 10, Active: true}},
				"fee_unit":                    {model.PlaceVisitReferenceValue{Code: "PERSON", Label: "Человек", Labels: map[string]string{"ru": "Человек", "en": "Person", "kk": "Адам"}, SortOrder: 10, Active: true}},
				"road_condition":              {model.PlaceVisitReferenceValue{Code: "PAVED", Label: "Асфальтированная дорога", Labels: map[string]string{"ru": "Асфальтированная дорога", "en": "Paved road", "kk": "Асфальт жол"}, SortOrder: 10, Active: true}},
				"transport_type":              {model.PlaceVisitReferenceValue{Code: "CAR", Label: "Автомобиль", Labels: map[string]string{"ru": "Автомобиль", "en": "Car", "kk": "Автокөлік"}, SortOrder: 10, Active: true}},
				"practical_note_type":         {model.PlaceVisitReferenceValue{Code: "GENERAL", Label: "Общее", Labels: map[string]string{"ru": "Общее", "en": "General", "kk": "Жалпы"}, SortOrder: 10, Active: true}},
				"practical_note_priority":     {model.PlaceVisitReferenceValue{Code: "IMPORTANT", Label: "Важно", Labels: map[string]string{"ru": "Важно", "en": "Important", "kk": "Маңызды"}, SortOrder: 10, Active: true}},
				"recommended_item_type":       {model.PlaceVisitReferenceValue{Code: "WATER", Label: "Вода", Labels: map[string]string{"ru": "Вода", "en": "Water", "kk": "Су"}, SortOrder: 10, Active: true}},
				"recommended_item_importance": {model.PlaceVisitReferenceValue{Code: "REQUIRED", Label: "Обязательно", Labels: map[string]string{"ru": "Обязательно", "en": "Required", "kk": "Міндетті"}, SortOrder: 10, Active: true}},
				"season":                      {model.PlaceVisitReferenceValue{Code: "SUMMER", Label: "Лето", Labels: map[string]string{"ru": "Лето", "en": "Summer", "kk": "Жаз"}, SortOrder: 10, Active: true}},
			},
		}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/visit_info_form", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		`action="/admin/places/` + item.ID.String() + `/visit-info"`,
		`name="visit_opening_hours_ru"`,
		`<select name="visit_best_time">`,
		`<option value="MORNING" selected>Утро</option>`,
		`value="Ежедневно 09:00-18:00"`,
		`name="visit_opening_hours_en"`,
		`value="Daily 09:00-18:00"`,
		`name="visit_opening_hours_kk"`,
		`value="Күн сайын 09:00-18:00"`,
		`name="visit_price_note_en"`,
		`Ticket and eco fee are paid separately`,
		`name="visit_time_on_site_note_kk"`,
		`value="Өзен соқпағынсыз"`,
		`name="visit_fee_detail_title_en_0" value="Admission"`,
		`name="visit_fee_detail_description_kk_0" value="Негізгі билет"`,
		`<select name="visit_fee_item_type_0">`,
		`<option value="ENTRANCE" selected>Вход</option>`,
		`<select name="visit_fee_item_unit_0">`,
		`<option value="PERSON" selected>Человек</option>`,
		`<select name="visit_access_transport_type_0">`,
		`<option value="CAR" selected>Автомобиль</option>`,
		`<select name="visit_access_road_condition_0">`,
		`<option value="PAVED" selected>Асфальтированная дорога</option>`,
		`<select name="visit_practical_priority_0">`,
		`<option value="IMPORTANT" selected>Важно</option>`,
		`<select name="visit_recommended_item_type_0">`,
		`<option value="WATER" selected>Вода</option>`,
		`<select name="visit_recommended_season_0">`,
		`<option value="SUMMER" selected>Лето</option>`,
		`data-visit-currency="KZT"`,
		`data-visit-default-currency="KZT"`,
		`data-visit-currency="KZT"><span>Валюта</span><strong>KZT</strong>`,
		`data-visit-repeat-row="recommended-item"`,
		`href="/admin/places/` + item.ID.String() + `/edit"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("visit-info form missing %q in body: %s", expected, body)
		}
	}
	for _, unexpected := range []string{
		`name="visit_fee_detail_currency_0"`,
		`name="visit_fee_item_currency_0"`,
		`<input name="visit_best_time"`,
		`<input name="visit_fee_item_type_0"`,
		`<input name="visit_recommended_item_type_0"`,
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("visit-info form renders editable currency field %q: %s", unexpected, body)
		}
	}
}

func TestRendererRendersPlaceVisitInfoFormWithLocalizedPlaceTitle(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	item := &model.AdminPlace{
		ID:            uuid.New(),
		DefaultLocale: localeRU,
		Title:         "Русское название",
		Translations: map[string]model.PlaceTranslation{
			localeEN: {Title: "English title"},
			localeRU: {Title: "Русское название"},
		},
	}
	pageData := PageData{
		Title:     "Visit information",
		Locale:    localeEN,
		Path:      "/admin/places/" + item.ID.String() + "/visit-info/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceVisitInfoFormViewData(item, ""),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/visit_info_form", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	if !strings.Contains(body, "English title") {
		t.Fatalf("visit-info form missing localized place title: %s", body)
	}
	if strings.Contains(body, ">Русское название<") {
		t.Fatalf("visit-info form rendered default title instead of locale title: %s", body)
	}
}

func TestRendererRendersPlaceVisitInfoDynamicRowControls(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	item := &model.AdminPlace{ID: uuid.New(), DefaultLocale: localeRU, Title: "Чарынский каньон"}
	pageData := PageData{
		Title:     "Visit information",
		Locale:    localeRU,
		Path:      "/admin/places/" + item.ID.String() + "/visit-info/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceVisitInfoFormViewData(item, ""),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/visit_info_form", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		`data-visit-repeat-section="fee-detail"`,
		`data-visit-repeat-section="fee-item"`,
		`data-visit-repeat-section="access-option"`,
		`data-visit-repeat-section="practical-note"`,
		`data-visit-repeat-section="recommended-item"`,
		`data-visit-info-modal="fee-detail"`,
		`data-visit-info-modal="fee-item"`,
		`data-visit-info-modal="access-option"`,
		`data-visit-info-modal="practical-note"`,
		`data-visit-info-modal="recommended-item"`,
		`action="/admin/places/` + item.ID.String() + `/visit-info/fee-details"`,
		`action="/admin/places/` + item.ID.String() + `/visit-info/fee-items"`,
		`action="/admin/places/` + item.ID.String() + `/visit-info/access-options"`,
		`action="/admin/places/` + item.ID.String() + `/visit-info/practical-notes"`,
		`action="/admin/places/` + item.ID.String() + `/visit-info/recommended-items"`,
		`data-visit-repeat-add="fee-item"`,
		`data-visit-repeat-template="access-option"`,
		`data-visit-repeat-remove`,
		`name="visit_fee_item_title_ru___INDEX__"`,
		`name="visit_access_route_hint_ru___INDEX__"`,
		`name="visit_practical_body_en___INDEX__"`,
		`name="visit_recommended_note_kk___INDEX__"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("visit-info dynamic form missing %q in body: %s", expected, body)
		}
	}
}

func TestRendererPreservesPlaceListFiltersAcrossEditNavigation(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	filters := placeListQuery(url.Values{
		"country":  {"PH"},
		"city":     {"cebu-city"},
		"q":        {"magellan"},
		"category": {"ARCHITECTURE"},
		"status":   {"PUBLISHED"},
		"page":     {"2"},
	})
	expectedQuery := "category=ARCHITECTURE&city=cebu-city&country=PH&page=2&q=magellan&status=PUBLISHED"
	if filters.ReturnQuery != expectedQuery {
		t.Fatalf("ReturnQuery = %q, want %q", filters.ReturnQuery, expectedQuery)
	}

	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?" + expectedQuery,
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Крест Магеллана",
				CountryCode:   "PH",
				CityID:        "cebu-city",
				Category:      "ARCHITECTURE",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 50, filters),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	expectedEditURL := "/admin/places/" + itemID.String() + "/edit?" + expectedQuery
	if !strings.Contains(listBody, `href="`+expectedEditURL+`"`) {
		t.Fatalf("place list did not preserve filters in edit link %q: %s", expectedEditURL, listBody)
	}

	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      expectedEditURL,
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data: NewPlaceFormViewData(&model.AdminPlace{
			ID:            itemID,
			DefaultLocale: localeRU,
			Title:         "Крест Магеллана",
			CountryCode:   "PH",
			CityID:        "cebu-city",
			Category:      "ARCHITECTURE",
			Status:        "PUBLISHED",
		}, model.PlaceInput{}, placeListURL(filters.ReturnQuery)),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	expectedBackURL := "/admin/places?" + expectedQuery
	if !strings.Contains(editBody, `href="`+expectedBackURL+`"`) {
		t.Fatalf("place edit form did not preserve filters in back link %q: %s", expectedBackURL, editBody)
	}
	expectedSubmitURL := "/admin/places/" + itemID.String() + "?" + expectedQuery
	if !strings.Contains(editBody, `action="`+expectedSubmitURL+`"`) {
		t.Fatalf("place edit form did not preserve filters in submit action %q: %s", expectedSubmitURL, editBody)
	}
	expectedMediaURL := "/admin/places/" + itemID.String() + "/media?" + expectedQuery
	if !strings.Contains(editBody, `action="`+expectedMediaURL+`"`) {
		t.Fatalf("place edit form did not preserve filters in media action %q: %s", expectedMediaURL, editBody)
	}
}

func TestRendererRendersModerationQueueLocationComboboxFilters(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	filters := QueueFilterViewData{
		Status:      excursionQueueStatusAll,
		CountryCode: "KZ",
		CityID:      "almaty",
		Query:       "city=almaty&country=KZ&status=all",
	}
	cases := []struct {
		name string
		data QueueViewData
	}{
		{name: "excursions", data: NewQueueViewData(nil, filters)},
		{name: "activities", data: NewActivityQueueViewData(nil, filters)},
		{name: "guides", data: NewGuideApplicationQueueViewData(nil, filters)},
		{name: "chats", data: NewChatMessageQueueViewData(nil, filters)},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			pageData := PageData{
				Title:     "Moderation",
				Locale:    localeRU,
				Path:      tc.data.FilterAction + "?" + filters.Query,
				Staff:     adminTemplateActor(),
				CSRFToken: "csrf-token",
				Data:      tc.data,
			}

			var rendered bytes.Buffer
			if err = renderer.templates.ExecuteTemplate(&rendered, "moderation/queue", pageData); err != nil {
				t.Fatalf("ExecuteTemplate returned error: %v", err)
			}
			body := html.UnescapeString(rendered.String())
			for _, expected := range []string{
				`data-location-filter-form`,
				`type="hidden" name="country" value="KZ" data-country-filter-value`,
				`type="search" data-country-filter-input value="Казахстан"`,
				`data-country-filter-suggestions role="listbox" hidden`,
				`type="button" class="filter-suggestion" data-country-filter-option`,
				`type="hidden" name="city" value="almaty" data-city-filter-value`,
				`type="search" data-city-filter-input value="Алматы"`,
				`data-city-filter-suggestions role="listbox" hidden`,
				`type="button" class="filter-suggestion" data-city-filter-option`,
				`action="` + tc.data.SyncAction + `?city=almaty&country=KZ&status=all"`,
			} {
				if !strings.Contains(body, expected) {
					t.Fatalf("%s queue did not render location filter control %q: %s", tc.name, expected, body)
				}
			}
			if strings.Contains(body, `placeholder="Город"`) {
				t.Fatalf("%s queue still renders legacy free-form city input: %s", tc.name, body)
			}
		})
	}
}

func TestRendererLocalizesDashboardModerationContext(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Now().UTC()
	activityID := uuid.New()
	activitySnapshot, err := json.Marshal(model.ActivityModerationItem{
		ID:          activityID,
		Title:       "Evening city walk",
		CountryCode: stringPtr("KZ"),
		CityName:    stringPtr("Almaty, Kazakhstan"),
		CreatedAt:   now,
		UpdatedAt:   now,
	})
	if err != nil {
		t.Fatalf("json.Marshal activity snapshot returned error: %v", err)
	}
	chatID := uuid.New()
	chatSnapshot, err := json.Marshal(model.ChatMessageModerationItem{
		ID:                    chatID,
		ConversationTitle:     "Trip safety",
		ConversationType:      "activity",
		SenderDisplayName:     "Aruzhan",
		Content:               "Can we move to another messenger?",
		ModerationReasonCodes: []string{"TRUST_POLICY_UNAVAILABLE", "off_platform_contact"},
		CreatedAt:             now,
		UpdatedAt:             now,
	})
	if err != nil {
		t.Fatalf("json.Marshal chat snapshot returned error: %v", err)
	}
	data := NewDashboardViewData(
		nil,
		[]*model.ModerationCase{{
			ID:         uuid.New(),
			TargetType: model.ModerationTargetActivity,
			TargetID:   activityID,
			Status:     enum.ModerationCaseStatusOpen,
			Priority:   10,
			Snapshot:   activitySnapshot,
			OpenedAt:   now,
		}},
		nil,
		[]*model.ModerationCase{{
			ID:         uuid.New(),
			TargetType: model.ModerationTargetChatMessage,
			TargetID:   chatID,
			Status:     enum.ModerationCaseStatusOpen,
			Priority:   90,
			Snapshot:   chatSnapshot,
			OpenedAt:   now,
		}},
	)
	pageData := PageData{
		Title:     "Панель",
		Locale:    localeRU,
		Path:      "/admin",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      data,
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "dashboard/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		"Evening city walk",
		"Алматы, Казахстан",
		"Проверка доверия недоступна",
		"Увод коммуникации за пределы платформы",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("dashboard did not render localized moderation context %q: %s", expected, body)
		}
	}
	for _, unexpected := range []string{
		"Almaty, Kazakhstan",
		"reason.TRUST_POLICY_UNAVAILABLE",
		"TRUST_POLICY_UNAVAILABLE",
		"off_platform_contact",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("dashboard rendered raw moderation context %q: %s", unexpected, body)
		}
	}
}

func TestRendererRendersDashboardSupportSection(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Date(2026, 6, 27, 11, 0, 0, 0, time.UTC)
	staff := adminTemplateActor()
	staff.Permissions = []enum.Permission{enum.PermissionSupportRead}
	data := NewDashboardViewDataWithSupport(nil, nil, nil, nil, []model.SupportTicket{{
		ID:                   "support-dashboard-ticket",
		Status:               model.SupportTicketStatusWaitingSupport,
		Priority:             model.SupportTicketPriorityHigh,
		UserNicknameSnapshot: "akashimo",
		LastMessagePreview:   "Не проходит оплата",
		LastMessageAt:        now,
		CreatedAt:            now,
		UpdatedAt:            now,
	}}, staff, localeRU)
	pageData := PageData{
		Title:     "Панель",
		Locale:    localeRU,
		Path:      "/admin",
		Staff:     staff,
		CSRFToken: "csrf-token",
		Data:      data,
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "dashboard/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		"Обращения в поддержку",
		"akashimo",
		"Не проходит оплата",
		"Ждет поддержку",
		"/admin/support/tickets?status=waiting_support",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("dashboard did not render support section content %q: %s", expected, body)
		}
	}
}

func TestRendererRendersModerationQueueSignalDropdownFilters(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	filters := QueueFilterViewData{
		Status: excursionQueueStatusActive,
		Signal: "TRUST_POLICY_UNAVAILABLE",
		Query:  "signal=TRUST_POLICY_UNAVAILABLE",
	}
	cases := []struct {
		name          string
		data          QueueViewData
		expectedLabel string
	}{
		{name: "excursions", data: NewQueueViewData(nil, filters), expectedLabel: "Проверка доверия недоступна"},
		{name: "activities", data: NewActivityQueueViewData(nil, filters), expectedLabel: "Проверка доверия недоступна"},
		{name: "guides", data: NewGuideApplicationQueueViewData(nil, QueueFilterViewData{Status: excursionQueueStatusActive, Signal: "new_guide", Query: "signal=new_guide"}), expectedLabel: "Новый гид"},
		{name: "chats", data: NewChatMessageQueueViewData(nil, filters), expectedLabel: "Проверка доверия недоступна"},
		{name: "post reports", data: NewPostReportQueueViewData(nil, QueueFilterViewData{Status: excursionQueueStatusActive, Signal: "spam", Query: "signal=spam"}), expectedLabel: "Спам"},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			pageData := PageData{
				Title:     "Moderation",
				Locale:    localeRU,
				Path:      tc.data.FilterAction,
				Staff:     adminTemplateActor(),
				CSRFToken: "csrf-token",
				Data:      tc.data,
			}

			var rendered bytes.Buffer
			if err = renderer.templates.ExecuteTemplate(&rendered, "moderation/queue", pageData); err != nil {
				t.Fatalf("ExecuteTemplate returned error: %v", err)
			}
			body := html.UnescapeString(rendered.String())
			for _, expected := range []string{
				`<select name="signal">`,
				`<option value=""`,
				`>Все сигналы</option>`,
				tc.expectedLabel,
			} {
				if !strings.Contains(body, expected) {
					t.Fatalf("%s queue did not render signal dropdown %q: %s", tc.name, expected, body)
				}
			}
			if strings.Contains(body, `type="search" name="signal"`) {
				t.Fatalf("%s queue still renders manual signal input: %s", tc.name, body)
			}
		})
	}
}

func TestRendererRendersChatMessageDetailSpecialContentAndAttachments(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Now().UTC()
	cases := []struct {
		name       string
		message    *model.ChatMessageModerationItem
		expected   []string
		unexpected []string
	}{
		{
			name: "sticker message",
			message: &model.ChatMessageModerationItem{
				ID:                uuid.New(),
				ConversationTitle: "Trip safety",
				ConversationType:  "activity",
				SenderDisplayName: "Aruzhan",
				Type:              "sticker",
				SentAt:            now,
				CreatedAt:         now,
				UpdatedAt:         now,
			},
			expected: []string{
				`data-chat-message-kind`,
				"Стикер",
			},
			unexpected: []string{
				`<p class="preline">-</p>`,
			},
		},
		{
			name: "emoji message",
			message: &model.ChatMessageModerationItem{
				ID:                uuid.New(),
				ConversationTitle: "Trip safety",
				ConversationType:  "activity",
				SenderDisplayName: "Aruzhan",
				Type:              "emoji",
				SentAt:            now,
				CreatedAt:         now,
				UpdatedAt:         now,
			},
			expected: []string{
				`data-chat-message-kind`,
				"Emoji",
			},
			unexpected: []string{
				`<p class="preline">-</p>`,
			},
		},
		{
			name: "file message with content",
			message: &model.ChatMessageModerationItem{
				ID:                uuid.New(),
				ConversationTitle: "Trip safety",
				ConversationType:  "activity",
				SenderDisplayName: "Aruzhan",
				Type:              "file",
				Content:           "Посмотри вложения перед решением",
				FileIDs:           []string{"file-chat-1", "file-chat-2"},
				SentAt:            now,
				CreatedAt:         now,
				UpdatedAt:         now,
			},
			expected: []string{
				"Посмотри вложения перед решением",
				`data-chat-attachment-id="file-chat-1"`,
				`data-chat-attachment-id="file-chat-2"`,
				"file-chat-1",
				"file-chat-2",
			},
		},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			caseID := uuid.New()
			pageData := PageData{
				Title:     "Moderation detail",
				Locale:    localeRU,
				Path:      "/admin/moderation/chats/" + caseID.String(),
				Staff:     adminTemplateActor(),
				CSRFToken: "csrf-token",
				Data: NewCaseDetailViewData(&app.ModerationCaseDetail{
					Case: &model.ModerationCase{
						ID:         caseID,
						TargetType: model.ModerationTargetChatMessage,
						TargetID:   tc.message.ID,
						Status:     enum.ModerationCaseStatusOpen,
						OpenedAt:   now,
					},
					ChatMessage: tc.message,
				}, ""),
			}

			var rendered bytes.Buffer
			if err = renderer.templates.ExecuteTemplate(&rendered, "moderation/detail", pageData); err != nil {
				t.Fatalf("ExecuteTemplate detail returned error: %v", err)
			}
			body := html.UnescapeString(rendered.String())
			for _, expected := range tc.expected {
				if !strings.Contains(body, expected) {
					t.Fatalf("%s detail did not render expected content %q: %s", tc.name, expected, body)
				}
			}
			for _, unexpected := range tc.unexpected {
				if strings.Contains(body, unexpected) {
					t.Fatalf("%s detail rendered unexpected placeholder %q: %s", tc.name, unexpected, body)
				}
			}
		})
	}
}

func TestRendererRendersModerationQueueHostPersonNames(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	now := time.Now().UTC()
	chatID := uuid.New()
	chatSnapshot, err := json.Marshal(model.ChatMessageModerationItem{
		ID:                chatID,
		ConversationType:  "direct",
		SenderDisplayName: "Аружан Тулегенова",
		Type:              "text",
		Content:           "Проверочное сообщение",
		CreatedAt:         now,
		UpdatedAt:         now,
		SentAt:            now,
	})
	if err != nil {
		t.Fatalf("json.Marshal chat snapshot returned error: %v", err)
	}
	activityID := uuid.New()
	activitySnapshot, err := json.Marshal(model.ActivityModerationItem{
		ID:              activityID,
		HostDisplayName: "@nomad_aru",
		HostFullName:    "Аружан Тулегенова",
		Title:           "Вечерняя прогулка",
		StartAt:         now,
		EndAt:           now.Add(time.Hour),
		CreatedAt:       now,
		UpdatedAt:       now,
	})
	if err != nil {
		t.Fatalf("json.Marshal activity snapshot returned error: %v", err)
	}

	chatBody := renderModerationQueueForTest(t, renderer, NewChatMessageQueueViewData([]*model.ModerationCase{{
		ID:         uuid.New(),
		TargetType: model.ModerationTargetChatMessage,
		TargetID:   chatID,
		Status:     enum.ModerationCaseStatusOpen,
		Snapshot:   chatSnapshot,
		OpenedAt:   now,
	}}))
	chatHostCell := moderationQueueHostCell(t, chatBody, "Аружан Тулегенова")
	if strings.Contains(chatHostCell, "Личный чат") || strings.Contains(chatHostCell, "Direct chat") {
		t.Fatalf("chat sender cell should not render conversation type: %s", chatHostCell)
	}

	activityBody := renderModerationQueueForTest(t, renderer, NewActivityQueueViewData([]*model.ModerationCase{{
		ID:         uuid.New(),
		TargetType: model.ModerationTargetActivity,
		TargetID:   activityID,
		Status:     enum.ModerationCaseStatusOpen,
		Snapshot:   activitySnapshot,
		OpenedAt:   now,
	}}))
	activityHostCell := moderationQueueHostCell(t, activityBody, "@nomad_aru")
	if !strings.Contains(activityHostCell, "Аружан Тулегенова") {
		t.Fatalf("activity organizer cell should render full name under nickname: %s", activityHostCell)
	}
}

func renderModerationQueueForTest(t *testing.T, renderer *Renderer, data QueueViewData) string {
	t.Helper()

	pageData := PageData{
		Title:     "Moderation queue",
		Locale:    localeRU,
		Path:      data.FilterAction,
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      data,
	}
	var rendered bytes.Buffer
	if err := renderer.templates.ExecuteTemplate(&rendered, "moderation/queue", pageData); err != nil {
		t.Fatalf("ExecuteTemplate queue returned error: %v", err)
	}
	return html.UnescapeString(rendered.String())
}

func moderationQueueHostCell(t *testing.T, body string, primary string) string {
	t.Helper()

	needle := "<strong>" + primary + "</strong>"
	needleIndex := strings.Index(body, needle)
	if needleIndex < 0 {
		t.Fatalf("queue did not render host primary %q: %s", primary, body)
	}
	start := strings.LastIndex(body[:needleIndex], "<td>")
	if start < 0 {
		t.Fatalf("queue host primary %q was not inside a table cell: %s", primary, body)
	}
	end := strings.Index(body[needleIndex:], "</td>")
	if end < 0 {
		t.Fatalf("queue host primary %q table cell was not closed: %s", primary, body)
	}
	return body[start : needleIndex+end+len("</td>")]
}

func TestRendererPreservesModerationQueueFiltersAcrossDetailNavigation(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	now := time.Now().UTC()
	returnQuery := "city=almaty&country=KZ&status=all"
	filters := QueueFilterViewData{
		Status:      excursionQueueStatusAll,
		CountryCode: "KZ",
		CityID:      "almaty",
		Query:       returnQuery,
	}
	type detailCase struct {
		name              string
		queueData         QueueViewData
		detailData        CaseDetailViewData
		expectedDetailURL string
		expectedQueueURL  string
		expectedApprove   string
	}
	excursionCaseID := uuid.New()
	excursionID := uuid.New()
	activityCaseID := uuid.New()
	activityID := uuid.New()
	cases := []detailCase{
		{
			name: "excursions",
			queueData: NewQueueViewData([]*model.ModerationCase{
				{
					ID:         excursionCaseID,
					TargetType: model.ModerationTargetExcursion,
					TargetID:   excursionID,
					Status:     enum.ModerationCaseStatusOpen,
					OpenedAt:   now,
				},
			}, filters),
			detailData: NewCaseDetailViewData(
				&app.ModerationCaseDetail{
					Case: &model.ModerationCase{
						ID:         excursionCaseID,
						TargetType: model.ModerationTargetExcursion,
						TargetID:   excursionID,
						Status:     enum.ModerationCaseStatusOpen,
						OpenedAt:   now,
					},
					Excursion: &model.ExcursionModerationItem{
						ID:              excursionID,
						Title:           "Big Almaty Lake",
						Status:          "PENDING_REVIEW",
						Visibility:      "PUBLIC",
						CountryCode:     "KZ",
						DepartureCityID: "almaty",
						CreatedAt:       now,
						UpdatedAt:       now,
					},
				},
				returnQuery,
			),
			expectedDetailURL: "/admin/moderation/excursions/" + excursionCaseID.String() + "?" + returnQuery,
			expectedQueueURL:  "/admin/moderation/excursions?" + returnQuery,
			expectedApprove:   "/admin/moderation/excursions/" + excursionCaseID.String() + "/approve?" + returnQuery,
		},
		{
			name: "activities",
			queueData: NewActivityQueueViewData([]*model.ModerationCase{
				{
					ID:         activityCaseID,
					TargetType: model.ModerationTargetActivity,
					TargetID:   activityID,
					Status:     enum.ModerationCaseStatusOpen,
					OpenedAt:   now,
				},
			}, filters),
			detailData: NewCaseDetailViewData(
				&app.ModerationCaseDetail{
					Case: &model.ModerationCase{
						ID:         activityCaseID,
						TargetType: model.ModerationTargetActivity,
						TargetID:   activityID,
						Status:     enum.ModerationCaseStatusOpen,
						OpenedAt:   now,
					},
					Activity: &model.ActivityModerationItem{
						ID:                  activityID,
						Title:               "Evening city walk",
						Status:              "FLAGGED",
						CountryCode:         stringPtr("KZ"),
						CityID:              stringPtr("almaty"),
						ModerationRiskScore: 60,
						StartAt:             now,
						EndAt:               now.Add(time.Hour),
						CreatedAt:           now,
						UpdatedAt:           now,
					},
				},
				returnQuery,
			),
			expectedDetailURL: "/admin/moderation/activities/" + activityCaseID.String() + "?" + returnQuery,
			expectedQueueURL:  "/admin/moderation/activities?" + returnQuery,
			expectedApprove:   "/admin/moderation/activities/" + activityCaseID.String() + "/approve?" + returnQuery,
		},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			queuePageData := PageData{
				Title:     "Moderation queue",
				Locale:    localeRU,
				Path:      tc.queueData.FilterAction + "?" + returnQuery,
				Staff:     adminTemplateActor(),
				CSRFToken: "csrf-token",
				Data:      tc.queueData,
			}
			var queueRendered bytes.Buffer
			if err = renderer.templates.ExecuteTemplate(&queueRendered, "moderation/queue", queuePageData); err != nil {
				t.Fatalf("ExecuteTemplate queue returned error: %v", err)
			}
			queueBody := html.UnescapeString(queueRendered.String())
			if !strings.Contains(queueBody, `href="`+tc.expectedDetailURL+`"`) {
				t.Fatalf("%s queue did not preserve filters in detail link %q: %s", tc.name, tc.expectedDetailURL, queueBody)
			}

			detailPageData := PageData{
				Title:     "Moderation detail",
				Locale:    localeRU,
				Path:      tc.expectedDetailURL,
				Staff:     adminTemplateActor(),
				CSRFToken: "csrf-token",
				Data:      tc.detailData,
			}
			var detailRendered bytes.Buffer
			if err = renderer.templates.ExecuteTemplate(&detailRendered, "moderation/detail", detailPageData); err != nil {
				t.Fatalf("ExecuteTemplate detail returned error: %v", err)
			}
			detailBody := html.UnescapeString(detailRendered.String())
			if !strings.Contains(detailBody, `href="`+tc.expectedQueueURL+`"`) {
				t.Fatalf("%s detail did not preserve filters in back link %q: %s", tc.name, tc.expectedQueueURL, detailBody)
			}
			if !strings.Contains(detailBody, `action="`+tc.expectedApprove+`"`) {
				t.Fatalf("%s detail did not preserve filters in approve action %q: %s", tc.name, tc.expectedApprove, detailBody)
			}
		})
	}
}

func TestRendererRendersPlaceCreateFormWithUploadPreview(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:     "Create place",
		Locale:    localeEN,
		Path:      "/admin/places/new",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(nil, model.PlaceInput{}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/form", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := rendered.String()
	for _, expected := range []string{
		`data-place-form data-place-media-form`,
		`name="media_images" type="file"`,
		`data-place-media-input`,
		`data-place-media-preview hidden`,
		`data-place-media-preview-list`,
		`data-place-media-count`,
		`Check selected images and their order before saving.`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("place create form did not render media preview control %q: %s", expected, body)
		}
	}
}

func TestRendererRendersPlaceFormCityLinksScopedToCountry(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:     "Create place",
		Locale:    localeRU,
		Path:      "/admin/places/new",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data: NewPlaceFormViewData(nil, model.PlaceInput{
			CountryCode: "VN",
			CityID:      "hanoi",
		}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/form", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		`name="country_code" required data-place-country-select`,
		`name="city_id" required data-place-city-select`,
		`data-place-city-link-option data-country="VN"`,
		`type="checkbox" name="access_cities" value="VN:hanoi"`,
		`type="checkbox" name="departure_cities" value="VN:hanoi"`,
		`Ханой, Вьетнам`,
		`data-place-city-link-option hidden data-country="KZ"`,
		`type="checkbox" name="access_cities" value="KZ:almaty" disabled`,
		`type="checkbox" name="departure_cities" value="KZ:almaty" disabled`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("place form did not scope city link option %q: %s", expected, body)
		}
	}
}

func TestRendererRendersPhilippinesPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=PH&city=cebu-city",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "PH",
			CityID:      "cebu-city",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="PH" data-country-filter-value`,
		`Филиппины`,
		`type="hidden" name="city" value="cebu-city" data-city-filter-value`,
		`Себу`,
		`Себу, Филиппины`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Philippines place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">PH<") || strings.Contains(listBody, ">cebu-city<") {
		t.Fatalf("Philippines place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Крест Магеллана",
		Description:   "Историческое место Себу.",
		CountryCode:   "PH",
		CityID:        "cebu-city",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "PH", CityID: "cebu-city"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "PH", CityID: "cebu-city"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Philippines place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersIndonesiaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=ID&city=ubud",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "ID",
			CityID:      "ubud",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="ID" data-country-filter-value`,
		`Индонезия`,
		`type="hidden" name="city" value="ubud" data-city-filter-value`,
		`Убуд`,
		`Убуд, Индонезия`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Indonesia place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">ID<") || strings.Contains(listBody, ">ubud<") {
		t.Fatalf("Indonesia place list still renders raw codes: %s", listBody)
	}
	if !strings.Contains(listBody, `data-country="ID" data-value="bali"`) {
		t.Fatalf("Indonesia place list should render Bali as a regional filter option: %s", listBody)
	}
	if strings.Contains(listBody, `data-country="ID" data-value="jakarta"`) {
		t.Fatalf("Indonesia place list should not render empty Jakarta city filter: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Священный лес обезьян Убуда",
		Description:   "Лесной заповедник с макаками и храмами.",
		CountryCode:   "ID",
		CityID:        "ubud",
		Category:      "PARK",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "ID", CityID: "ubud"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "ID", CityID: "ubud"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Indonesia place form did not render localized reference %q: %s", expected, editBody)
		}
	}
	if strings.Contains(editBody, `value="bali" data-country="ID"`) {
		t.Fatalf("Indonesia place form must not offer Bali as a concrete place city: %s", editBody)
	}
}

func TestRendererRendersMaldivesPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=MV&city=maafushi",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "MV",
			CityID:      "maafushi",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="MV" data-country-filter-value`,
		`Мальдивы`,
		`type="hidden" name="city" value="maafushi" data-city-filter-value`,
		`Маафуши`,
		`Маафуши, Мальдивы`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Maldives place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">MV<") || strings.Contains(listBody, ">maafushi<") {
		t.Fatalf("Maldives place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Bikini Beach Маафуши",
		Description:   "Главная туристическая пляжная зона Маафуши.",
		CountryCode:   "MV",
		CityID:        "maafushi",
		Category:      "BEACH",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "MV", CityID: "maafushi"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "MV", CityID: "maafushi"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Maldives place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersGeorgiaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=GE&city=stepantsminda",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "GE",
			CityID:      "stepantsminda",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="GE" data-country-filter-value`,
		`Грузия`,
		`type="hidden" name="city" value="stepantsminda" data-city-filter-value`,
		`Степанцминда (Казбеги)`,
		`Степанцминда (Казбеги), Грузия`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Georgia place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">GE<") || strings.Contains(listBody, ">stepantsminda<") {
		t.Fatalf("Georgia place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Троицкая церковь Гергети",
		Description:   "Горная церковь над Степанцминдой.",
		CountryCode:   "GE",
		CityID:        "stepantsminda",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "GE", CityID: "tbilisi"},
			{CountryCode: "GE", CityID: "stepantsminda"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "GE", CityID: "tbilisi"},
			{CountryCode: "GE", CityID: "stepantsminda"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Georgia place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersArmeniaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=AM&city=vagharshapat",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "AM",
			CityID:      "vagharshapat",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="AM" data-country-filter-value`,
		`Армения`,
		`type="hidden" name="city" value="vagharshapat" data-city-filter-value`,
		`Вагаршапат (Эчмиадзин)`,
		`Вагаршапат (Эчмиадзин), Армения`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Armenia place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AM<") || strings.Contains(listBody, ">vagharshapat<") {
		t.Fatalf("Armenia place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Кафедральный собор Эчмиадзин",
		Description:   "Духовный центр Армянской апостольской церкви.",
		CountryCode:   "AM",
		CityID:        "vagharshapat",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "AM", CityID: "yerevan"},
			{CountryCode: "AM", CityID: "vagharshapat"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "AM", CityID: "yerevan"},
			{CountryCode: "AM", CityID: "vagharshapat"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Armenia place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersChinaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=CN&city=xian",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "CN",
			CityID:      "xian",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="CN" data-country-filter-value`,
		`Китай`,
		`type="hidden" name="city" value="xian" data-city-filter-value`,
		`Сиань`,
		`Сиань, Китай`,
		`data-country="CN" data-value="hainan"`,
		`Хайнань`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("China place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">CN<") || strings.Contains(listBody, ">xian<") {
		t.Fatalf("China place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Терракотовая армия",
		Description:   "Музейный комплекс первого императора Цинь.",
		CountryCode:   "CN",
		CityID:        "xian",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "CN", CityID: "beijing"},
			{CountryCode: "CN", CityID: "xian"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "CN", CityID: "beijing"},
			{CountryCode: "CN", CityID: "xian"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("China place form did not render localized reference %q: %s", expected, editBody)
		}
	}
	if strings.Contains(editBody, `value="hainan" data-country="CN"`) {
		t.Fatalf("China place form must not offer Hainan as a concrete place city: %s", editBody)
	}
}

func TestRendererRendersSouthKoreaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=KR&city=gyeongju",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "KR",
			CityID:      "gyeongju",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="KR" data-country-filter-value`,
		`Южная Корея`,
		`type="hidden" name="city" value="gyeongju" data-city-filter-value`,
		`Кёнджу`,
		`Кёнджу, Южная Корея`,
		`Храм`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("South Korea place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">KR<") || strings.Contains(listBody, ">gyeongju<") {
		t.Fatalf("South Korea place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Храм Пульгукса",
		Description:   "Главный буддийский храм Кёнджу.",
		CountryCode:   "KR",
		CityID:        "gyeongju",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "KR", CityID: "busan"},
			{CountryCode: "KR", CityID: "gyeongju"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "KR", CityID: "busan"},
			{CountryCode: "KR", CityID: "gyeongju"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("South Korea place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersJapanPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=JP&city=kyoto",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "JP",
			CityID:      "kyoto",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="JP" data-country-filter-value`,
		`Япония`,
		`type="hidden" name="city" value="kyoto" data-city-filter-value`,
		`Киото`,
		`Киото, Япония`,
		`Храм`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Japan place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">JP<") || strings.Contains(listBody, ">kyoto<") {
		t.Fatalf("Japan place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Храм Киёмидзу-дэра",
		Description:   "Исторический храм на востоке Киото.",
		CountryCode:   "JP",
		CityID:        "kyoto",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "JP", CityID: "osaka"},
			{CountryCode: "JP", CityID: "kyoto"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "JP", CityID: "osaka"},
			{CountryCode: "JP", CityID: "kyoto"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Japan place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersUAEPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=AE&city=dubai",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "AE",
			CityID:      "dubai",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="AE" data-country-filter-value`,
		`ОАЭ`,
		`type="hidden" name="city" value="dubai" data-city-filter-value`,
		`Дубай`,
		`Дубай, ОАЭ`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("UAE place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AE<") || strings.Contains(listBody, ">dubai<") {
		t.Fatalf("UAE place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Бурдж-Халифа",
		Description:   "Главная смотровая башня Дубая.",
		CountryCode:   "AE",
		CityID:        "dubai",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "AE", CityID: "dubai"},
			{CountryCode: "AE", CityID: "abu-dhabi"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "AE", CityID: "dubai"},
			{CountryCode: "AE", CityID: "abu-dhabi"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("UAE place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersTurkeyPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=TR&city=istanbul",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "TR",
			CityID:      "istanbul",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="TR" data-country-filter-value`,
		`Турция`,
		`type="hidden" name="city" value="istanbul" data-city-filter-value`,
		`Стамбул`,
		`Стамбул, Турция`,
		`Храм`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Turkey place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">TR<") || strings.Contains(listBody, ">istanbul<") {
		t.Fatalf("Turkey place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Айя-София",
		Description:   "Историческая мечеть и архитектурная икона Стамбула.",
		CountryCode:   "TR",
		CityID:        "istanbul",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "TR", CityID: "istanbul"},
			{CountryCode: "TR", CityID: "cappadocia"},
			{CountryCode: "TR", CityID: "antalya"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "TR", CityID: "istanbul"},
			{CountryCode: "TR", CityID: "cappadocia"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Turkey place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersEgyptPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=EG&city=giza",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "EG",
			CityID:      "giza",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="EG" data-country-filter-value`,
		`Египет`,
		`type="hidden" name="city" value="giza" data-city-filter-value`,
		`Гиза`,
		`Гиза, Египет`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Egypt place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">EG<") || strings.Contains(listBody, ">giza<") {
		t.Fatalf("Egypt place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Пирамиды Гизы",
		Description:   "Главный археологический комплекс Египта.",
		CountryCode:   "EG",
		CityID:        "giza",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "EG", CityID: "cairo"},
			{CountryCode: "EG", CityID: "luxor"},
			{CountryCode: "EG", CityID: "sharm-el-sheikh"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "EG", CityID: "cairo"},
			{CountryCode: "EG", CityID: "hurghada"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Egypt place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersMalaysiaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=MY&city=george-town",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "MY",
			CityID:      "george-town",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="MY" data-country-filter-value`,
		`Малайзия`,
		`type="hidden" name="city" value="george-town" data-city-filter-value`,
		`Джорджтаун`,
		`Джорджтаун, Малайзия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Malaysia place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">MY<") || strings.Contains(listBody, ">george-town<") {
		t.Fatalf("Malaysia place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Джорджтаун",
		Description:   "Исторический центр Пенанга.",
		CountryCode:   "MY",
		CityID:        "george-town",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "MY", CityID: "penang"},
			{CountryCode: "MY", CityID: "langkawi"},
			{CountryCode: "MY", CityID: "kuala-lumpur"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "MY", CityID: "penang"},
			{CountryCode: "MY", CityID: "kuala-lumpur"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Malaysia place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSriLankaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=LK&city=sigiriya",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "LK",
			CityID:      "sigiriya",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="LK" data-country-filter-value`,
		`Шри-Ланка`,
		`type="hidden" name="city" value="sigiriya" data-city-filter-value`,
		`Сигирия`,
		`Сигирия, Шри-Ланка`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Sri Lanka place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">LK<") || strings.Contains(listBody, ">sigiriya<") {
		t.Fatalf("Sri Lanka place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Сигирия",
		Description:   "Скальная крепость в культурном треугольнике.",
		CountryCode:   "LK",
		CityID:        "sigiriya",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "LK", CityID: "kandy"},
			{CountryCode: "LK", CityID: "dambulla"},
			{CountryCode: "LK", CityID: "colombo"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "LK", CityID: "colombo"},
			{CountryCode: "LK", CityID: "kandy"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Sri Lanka place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersMontenegroPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=ME&city=kotor",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "ME",
			CityID:      "kotor",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="ME" data-country-filter-value`,
		`Черногория`,
		`type="hidden" name="city" value="kotor" data-city-filter-value`,
		`Котор`,
		`Котор, Черногория`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Montenegro place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">ME<") || strings.Contains(listBody, ">kotor<") {
		t.Fatalf("Montenegro place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Старый город Котор",
		Description:   "Исторический город в Боко-Которской бухте.",
		CountryCode:   "ME",
		CityID:        "kotor",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "ME", CityID: "perast"},
			{CountryCode: "ME", CityID: "tivat"},
			{CountryCode: "ME", CityID: "podgorica"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "ME", CityID: "podgorica"},
			{CountryCode: "ME", CityID: "budva"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Montenegro place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersIndiaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=IN&city=delhi",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "IN",
			CityID:      "delhi",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="IN" data-country-filter-value`,
		`Индия`,
		`type="hidden" name="city" value="delhi" data-city-filter-value`,
		`Дели`,
		`Дели, Индия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("India place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">IN<") || strings.Contains(listBody, ">delhi<") {
		t.Fatalf("India place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Красный форт",
		Description:   "Исторический форт в Старом Дели.",
		CountryCode:   "IN",
		CityID:        "delhi",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "IN", CityID: "agra"},
			{CountryCode: "IN", CityID: "jaipur"},
			{CountryCode: "IN", CityID: "varanasi"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "IN", CityID: "mumbai"},
			{CountryCode: "IN", CityID: "goa"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("India place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersMaltaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=MT&city=valletta",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "MT",
			CityID:      "valletta",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="MT" data-country-filter-value`,
		`Мальта`,
		`type="hidden" name="city" value="valletta" data-city-filter-value`,
		`Валлетта`,
		`Валлетта, Мальта`,
		`Храм`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Malta place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">MT<") || strings.Contains(listBody, ">valletta<") {
		t.Fatalf("Malta place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Собор Святого Иоанна",
		Description:   "Барочный собор в Валлетте.",
		CountryCode:   "MT",
		CityID:        "valletta",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "MT", CityID: "sliema"},
			{CountryCode: "MT", CityID: "mdina"},
			{CountryCode: "MT", CityID: "gozo"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "MT", CityID: "st-julians"},
			{CountryCode: "MT", CityID: "marsaxlokk"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Malta place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersCyprusPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=CY&city=paphos",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "CY",
			CityID:      "paphos",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="CY" data-country-filter-value`,
		`Кипр`,
		`type="hidden" name="city" value="paphos" data-city-filter-value`,
		`Пафос`,
		`Пафос, Кипр`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Cyprus place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">CY<") || strings.Contains(listBody, ">paphos<") {
		t.Fatalf("Cyprus place list still renders raw codes: %s", listBody)
	}

	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Археологический парк Пафоса",
		Description:   "Археологический комплекс с мозаиками и античными памятниками.",
		CountryCode:   "CY",
		CityID:        "paphos",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "CY", CityID: "coral-bay"},
			{CountryCode: "CY", CityID: "polis"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "CY", CityID: "ayia-napa"},
			{CountryCode: "CY", CityID: "limassol"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Cyprus place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSeychellesPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=SC&city=victoria",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "SC",
			CityID:      "victoria",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="SC" data-country-filter-value`,
		`Сейшелы`,
		`type="hidden" name="city" value="victoria" data-city-filter-value`,
		`Виктория`,
		`Виктория, Сейшелы`,
		`Парк`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Seychelles place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">SC<") || strings.Contains(listBody, ">victoria<") {
		t.Fatalf("Seychelles place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "SCR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Национальный ботанический сад Сейшел",
		Description:   "Сад в Виктории с эндемичными растениями и гигантскими черепахами.",
		CountryCode:   "SC",
		CityID:        "victoria",
		Category:      "PARK",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "SC", CityID: "beau-vallon"},
			{CountryCode: "SC", CityID: "eden-island"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "SC", CityID: "la-digue"},
			{CountryCode: "SC", CityID: "praslin"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Seychelles place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersPolandPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=PL&city=warsaw",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "PL",
			CityID:      "warsaw",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="PL" data-country-filter-value`,
		`Польша`,
		`type="hidden" name="city" value="warsaw" data-city-filter-value`,
		`Варшава`,
		`Варшава, Польша`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Poland place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">PL<") || strings.Contains(listBody, ">warsaw<") {
		t.Fatalf("Poland place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "PLN"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Старый город Варшавы",
		Description:   "Исторический центр Варшавы с площадями, крепостными стенами и Королевским замком.",
		CountryCode:   "PL",
		CityID:        "warsaw",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "PL", CityID: "krakow"},
			{CountryCode: "PL", CityID: "gdansk"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "PL", CityID: "wroclaw"},
			{CountryCode: "PL", CityID: "poznan"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Poland place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersMexicoPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=MX&city=mexico-city",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "MX",
			CityID:      "mexico-city",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="MX" data-country-filter-value`,
		`Мексика`,
		`type="hidden" name="city" value="mexico-city" data-city-filter-value`,
		`Мехико`,
		`Мехико, Мексика`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Mexico place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">MX<") || strings.Contains(listBody, ">mexico-city<") {
		t.Fatalf("Mexico place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "MXN"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Исторический центр Мехико",
		Description:   "Главная историческая зона столицы с площадью Сокало, собором и музеями.",
		CountryCode:   "MX",
		CityID:        "mexico-city",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "MX", CityID: "teotihuacan"},
			{CountryCode: "MX", CityID: "puebla"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "MX", CityID: "cancun"},
			{CountryCode: "MX", CityID: "guadalajara"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Mexico place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersBrazilPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=BR&city=rio-de-janeiro",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "BR",
			CityID:      "rio-de-janeiro",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="BR" data-country-filter-value`,
		`Бразилия`,
		`type="hidden" name="city" value="rio-de-janeiro" data-city-filter-value`,
		`Рио-де-Жанейро`,
		`Рио-де-Жанейро, Бразилия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Brazil place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">BR<") || strings.Contains(listBody, ">rio-de-janeiro<") {
		t.Fatalf("Brazil place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "BRL"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Христос-Искупитель",
		Description:   "Главный символ Рио-де-Жанейро с видом на город, бухту и пляжи.",
		CountryCode:   "BR",
		CityID:        "rio-de-janeiro",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "BR", CityID: "petropolis"},
			{CountryCode: "BR", CityID: "paraty"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "BR", CityID: "sao-paulo"},
			{CountryCode: "BR", CityID: "salvador"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Brazil place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersArgentinaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=AR&city=buenos-aires",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "AR",
			CityID:      "buenos-aires",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="AR" data-country-filter-value`,
		`Аргентина`,
		`type="hidden" name="city" value="buenos-aires" data-city-filter-value`,
		`Буэнос-Айрес`,
		`Буэнос-Айрес, Аргентина`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Argentina place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AR<") || strings.Contains(listBody, ">buenos-aires<") {
		t.Fatalf("Argentina place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "ARS"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Театр Колон",
		Description:   "Историческая опера Буэнос-Айреса и одна из главных культурных сцен страны.",
		CountryCode:   "AR",
		CityID:        "buenos-aires",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "AR", CityID: "tigre"},
			{CountryCode: "AR", CityID: "la-plata"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "AR", CityID: "mendoza"},
			{CountryCode: "AR", CityID: "bariloche"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Argentina place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSwitzerlandPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=CH&city=zurich",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "CH",
			CityID:      "zurich",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="CH" data-country-filter-value`,
		`Швейцария`,
		`type="hidden" name="city" value="zurich" data-city-filter-value`,
		`Цюрих`,
		`Цюрих, Швейцария`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Switzerland place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">CH<") || strings.Contains(listBody, ">zurich<") {
		t.Fatalf("Switzerland place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "CHF"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Кунстхаус Цюрих",
		Description:   "Один из ключевых художественных музеев Швейцарии.",
		CountryCode:   "CH",
		CityID:        "zurich",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "CH", CityID: "lucerne"},
			{CountryCode: "CH", CityID: "basel"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "CH", CityID: "geneva"},
			{CountryCode: "CH", CityID: "zermatt"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Switzerland place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSwedenPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=SE&city=stockholm",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "SE",
			CityID:      "stockholm",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="SE" data-country-filter-value`,
		`Швеция`,
		`type="hidden" name="city" value="stockholm" data-city-filter-value`,
		`Стокгольм`,
		`Стокгольм, Швеция`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Sweden place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">SE<") || strings.Contains(listBody, ">stockholm<") {
		t.Fatalf("Sweden place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "SEK"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Музей Васа",
		Description:   "Морской музей с историческим кораблем XVII века.",
		CountryCode:   "SE",
		CityID:        "stockholm",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "SE", CityID: "uppsala"},
			{CountryCode: "SE", CityID: "sigtuna"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "SE", CityID: "gothenburg"},
			{CountryCode: "SE", CityID: "malmo"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Sweden place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersCzechiaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=CZ&city=prague",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "CZ",
			CityID:      "prague",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="CZ" data-country-filter-value`,
		`Чехия`,
		`type="hidden" name="city" value="prague" data-city-filter-value`,
		`Прага`,
		`Прага, Чехия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Czechia place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">CZ<") || strings.Contains(listBody, ">prague<") {
		t.Fatalf("Czechia place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "CZK"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Пражский Град",
		Description:   "Крупнейший исторический комплекс Праги.",
		CountryCode:   "CZ",
		CityID:        "prague",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "CZ", CityID: "karlstejn"},
			{CountryCode: "CZ", CityID: "kutna-hora"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "CZ", CityID: "brno"},
			{CountryCode: "CZ", CityID: "plzen"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Czechia place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersFrancePlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=FR&city=paris",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Эйфелева башня",
				CountryCode:   "FR",
				CityID:        "paris",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "FR",
			CityID:      "paris",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="FR" data-country-filter-value`,
		`Франция`,
		`type="hidden" name="city" value="paris" data-city-filter-value`,
		`Париж`,
		`Париж, Франция`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("France place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">FR<") || strings.Contains(listBody, ">paris<") {
		t.Fatalf("France place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Эйфелева башня",
		Description:   "Главная архитектурная доминанта Парижа.",
		CountryCode:   "FR",
		CityID:        "paris",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "FR", CityID: "versailles"},
			{CountryCode: "FR", CityID: "fontainebleau"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "FR", CityID: "lyon"},
			{CountryCode: "FR", CityID: "nice"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="FR" selected>Франция</option>`,
		`<option value="paris" data-country="FR" selected>Париж</option>`,
		`<option value="versailles" data-country="FR" >Версаль</option>`,
		`type="checkbox" name="access_cities" value="FR:versailles" checked`,
		`type="checkbox" name="departure_cities" value="FR:lyon" checked`,
		`Париж, Франция`,
		`<option value="EUR" selected>Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("France place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersUnitedKingdomPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=GB&city=london",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Тауэр",
				CountryCode:   "GB",
				CityID:        "london",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "GB",
			CityID:      "london",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="GB" data-country-filter-value`,
		`Великобритания`,
		`type="hidden" name="city" value="london" data-city-filter-value`,
		`Лондон`,
		`Лондон, Великобритания`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("United Kingdom place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">GB<") || strings.Contains(listBody, ">london<") {
		t.Fatalf("United Kingdom place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "GBP"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Тауэр",
		Description:   "Историческая крепость в Лондоне.",
		CountryCode:   "GB",
		CityID:        "london",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "GB", CityID: "windsor"},
			{CountryCode: "GB", CityID: "oxford"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "GB", CityID: "manchester"},
			{CountryCode: "GB", CityID: "edinburgh"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="GB" selected>Великобритания</option>`,
		`<option value="london" data-country="GB" selected>Лондон</option>`,
		`<option value="windsor" data-country="GB" >Виндзор</option>`,
		`type="checkbox" name="access_cities" value="GB:windsor" checked`,
		`type="checkbox" name="departure_cities" value="GB:manchester" checked`,
		`Лондон, Великобритания`,
		`<option value="GBP" selected>Британский фунт</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("United Kingdom place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersUzbekistanPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=UZ&city=tashkent",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Чорсу",
				CountryCode:   "UZ",
				CityID:        "tashkent",
				Category:      "MARKET",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "UZ",
			CityID:      "tashkent",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="UZ" data-country-filter-value`,
		`Узбекистан`,
		`type="hidden" name="city" value="tashkent" data-city-filter-value`,
		`Ташкент`,
		`Ташкент, Узбекистан`,
		`Рынок`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Uzbekistan place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">UZ<") || strings.Contains(listBody, ">tashkent<") {
		t.Fatalf("Uzbekistan place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "UZS"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Чорсу",
		Description:   "Исторический рынок в старом Ташкенте.",
		CountryCode:   "UZ",
		CityID:        "tashkent",
		Category:      "MARKET",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "UZ", CityID: "samarkand"},
			{CountryCode: "UZ", CityID: "bukhara"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "UZ", CityID: "tashkent"},
			{CountryCode: "UZ", CityID: "fergana"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="UZ" selected>Узбекистан</option>`,
		`<option value="tashkent" data-country="UZ" selected>Ташкент</option>`,
		`<option value="samarkand" data-country="UZ" >Самарканд</option>`,
		`type="checkbox" name="access_cities" value="UZ:samarkand" checked`,
		`type="checkbox" name="departure_cities" value="UZ:fergana" checked`,
		`Ташкент, Узбекистан`,
		`<option value="UZS" selected>Узбекский сум</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Uzbekistan place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersKyrgyzstanPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=KG&city=bishkek",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Ала-Тоо",
				CountryCode:   "KG",
				CityID:        "bishkek",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "KG",
			CityID:      "bishkek",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="KG" data-country-filter-value`,
		`Кыргызстан`,
		`type="hidden" name="city" value="bishkek" data-city-filter-value`,
		`Бишкек`,
		`Бишкек, Кыргызстан`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Kyrgyzstan place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">KG<") || strings.Contains(listBody, ">bishkek<") {
		t.Fatalf("Kyrgyzstan place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "KGS"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Ала-Тоо",
		Description:   "Главная площадь Бишкека.",
		CountryCode:   "KG",
		CityID:        "bishkek",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "KG", CityID: "karakol"},
			{CountryCode: "KG", CityID: "osh"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "KG", CityID: "bishkek"},
			{CountryCode: "KG", CityID: "cholpon-ata"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="KG" selected>Кыргызстан</option>`,
		`<option value="bishkek" data-country="KG" selected>Бишкек</option>`,
		`<option value="karakol" data-country="KG" >Каракол</option>`,
		`type="checkbox" name="access_cities" value="KG:karakol" checked`,
		`type="checkbox" name="departure_cities" value="KG:cholpon-ata" checked`,
		`Бишкек, Кыргызстан`,
		`<option value="KGS" selected>Киргизский сом</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Kyrgyzstan place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersAzerbaijanPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=AZ&city=baku",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Ичери-шехер",
				CountryCode:   "AZ",
				CityID:        "baku",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "AZ",
			CityID:      "baku",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="AZ" data-country-filter-value`,
		`Азербайджан`,
		`type="hidden" name="city" value="baku" data-city-filter-value`,
		`Баку`,
		`Баку, Азербайджан`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Azerbaijan place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AZ<") || strings.Contains(listBody, ">baku<") {
		t.Fatalf("Azerbaijan place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "AZN"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Ичери-шехер",
		Description:   "Старый город Баку.",
		CountryCode:   "AZ",
		CityID:        "baku",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "AZ", CityID: "gabala"},
			{CountryCode: "AZ", CityID: "sheki"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "AZ", CityID: "baku"},
			{CountryCode: "AZ", CityID: "shahdag"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="AZ" selected>Азербайджан</option>`,
		`<option value="baku" data-country="AZ" selected>Баку</option>`,
		`<option value="gabala" data-country="AZ" >Габала</option>`,
		`type="checkbox" name="access_cities" value="AZ:gabala" checked`,
		`type="checkbox" name="departure_cities" value="AZ:shahdag" checked`,
		`Баку, Азербайджан`,
		`<option value="AZN" selected>Азербайджанский манат</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Azerbaijan place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersTajikistanPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=TJ&city=dushanbe",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Парк Рудаки",
				CountryCode:   "TJ",
				CityID:        "dushanbe",
				Category:      "PARK",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "TJ",
			CityID:      "dushanbe",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="TJ" data-country-filter-value`,
		`Таджикистан`,
		`type="hidden" name="city" value="dushanbe" data-city-filter-value`,
		`Душанбе`,
		`Душанбе, Таджикистан`,
		`Парк`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Tajikistan place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">TJ<") || strings.Contains(listBody, ">dushanbe<") {
		t.Fatalf("Tajikistan place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "TJS"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Парк Рудаки",
		Description:   "Центральный парк Душанбе.",
		CountryCode:   "TJ",
		CityID:        "dushanbe",
		Category:      "PARK",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "TJ", CityID: "hisor"},
			{CountryCode: "TJ", CityID: "varzob"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "TJ", CityID: "dushanbe"},
			{CountryCode: "TJ", CityID: "iskanderkul"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="TJ" selected>Таджикистан</option>`,
		`<option value="dushanbe" data-country="TJ" selected>Душанбе</option>`,
		`<option value="hisor" data-country="TJ" >Гиссар</option>`,
		`type="checkbox" name="access_cities" value="TJ:hisor" checked`,
		`type="checkbox" name="departure_cities" value="TJ:iskanderkul" checked`,
		`Душанбе, Таджикистан`,
		`<option value="TJS" selected>Таджикский сомони</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Tajikistan place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersMongoliaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=MN&city=ulaanbaatar",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Национальный музей Чингисхана",
				CountryCode:   "MN",
				CityID:        "ulaanbaatar",
				Category:      "MUSEUM",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "MN",
			CityID:      "ulaanbaatar",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="MN" data-country-filter-value`,
		`Монголия`,
		`type="hidden" name="city" value="ulaanbaatar" data-city-filter-value`,
		`Улан-Батор`,
		`Улан-Батор, Монголия`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Mongolia place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">MN<") || strings.Contains(listBody, ">ulaanbaatar<") {
		t.Fatalf("Mongolia place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "MNT"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Национальный музей Чингисхана",
		Description:   "Современный музей истории монгольских государств.",
		CountryCode:   "MN",
		CityID:        "ulaanbaatar",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "MN", CityID: "gorkhi-terelj"},
			{CountryCode: "MN", CityID: "khustai"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "MN", CityID: "ulaanbaatar"},
			{CountryCode: "MN", CityID: "kharkhorin"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="MN" selected>Монголия</option>`,
		`<option value="ulaanbaatar" data-country="MN" selected>Улан-Батор</option>`,
		`<option value="gorkhi-terelj" data-country="MN" >Горхи-Тэрэлж</option>`,
		`type="checkbox" name="access_cities" value="MN:gorkhi-terelj" checked`,
		`type="checkbox" name="departure_cities" value="MN:kharkhorin" checked`,
		`Улан-Батор, Монголия`,
		`<option value="MNT" selected>Монгольский тугрик</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Mongolia place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersIcelandPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=IS&city=reykjavik",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Перлан — Чудеса Исландии",
				CountryCode:   "IS",
				CityID:        "reykjavik",
				Category:      "MUSEUM",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "IS",
			CityID:      "reykjavik",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="IS" data-country-filter-value`,
		`Исландия`,
		`type="hidden" name="city" value="reykjavik" data-city-filter-value`,
		`Рейкьявик`,
		`Рейкьявик, Исландия`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Iceland place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">IS<") || strings.Contains(listBody, ">reykjavik<") {
		t.Fatalf("Iceland place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "ISK"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Перлан — Чудеса Исландии",
		Description:   "Интерактивный музей природы Исландии и обзорная площадка.",
		CountryCode:   "IS",
		CityID:        "reykjavik",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "IS", CityID: "reykjavik"},
			{CountryCode: "IS", CityID: "thingvellir"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "IS", CityID: "reykjavik"},
			{CountryCode: "IS", CityID: "akureyri"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="IS" selected>Исландия</option>`,
		`<option value="reykjavik" data-country="IS" selected>Рейкьявик</option>`,
		`<option value="thingvellir" data-country="IS" >Тингведлир</option>`,
		`type="checkbox" name="access_cities" value="IS:thingvellir" checked`,
		`type="checkbox" name="departure_cities" value="IS:akureyri" checked`,
		`Рейкьявик, Исландия`,
		`<option value="ISK" selected>Исландская крона</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Iceland place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersIrelandPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=IE&city=dublin",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Тринити-колледж и Келлская книга",
				CountryCode:   "IE",
				CityID:        "dublin",
				Category:      "MUSEUM",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "IE",
			CityID:      "dublin",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="IE" data-country-filter-value`,
		`Ирландия`,
		`type="hidden" name="city" value="dublin" data-city-filter-value`,
		`Дублин`,
		`Дублин, Ирландия`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Ireland place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">IE<") || strings.Contains(listBody, ">dublin<") {
		t.Fatalf("Ireland place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Тринити-колледж и Келлская книга",
		Description:   "Исторический кампус и библиотека с одной из главных рукописей Ирландии.",
		CountryCode:   "IE",
		CityID:        "dublin",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "IE", CityID: "dublin"},
			{CountryCode: "IE", CityID: "glendalough"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "IE", CityID: "dublin"},
			{CountryCode: "IE", CityID: "galway"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="IE" selected>Ирландия</option>`,
		`<option value="dublin" data-country="IE" selected>Дублин</option>`,
		`<option value="glendalough" data-country="IE" >Глендалох</option>`,
		`type="checkbox" name="access_cities" value="IE:glendalough" checked`,
		`type="checkbox" name="departure_cities" value="IE:galway" checked`,
		`Дублин, Ирландия`,
		`<option value="EUR" selected>Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Ireland place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersNetherlandsPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=NL&city=amsterdam",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Рейксмюсеум",
				CountryCode:   "NL",
				CityID:        "amsterdam",
				Category:      "MUSEUM",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "NL",
			CityID:      "amsterdam",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="NL" data-country-filter-value`,
		`Нидерланды`,
		`type="hidden" name="city" value="amsterdam" data-city-filter-value`,
		`Амстердам`,
		`Амстердам, Нидерланды`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Netherlands place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">NL<") || strings.Contains(listBody, ">amsterdam<") {
		t.Fatalf("Netherlands place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Рейксмюсеум",
		Description:   "Главный художественный музей Нидерландов на Музейной площади.",
		CountryCode:   "NL",
		CityID:        "amsterdam",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "NL", CityID: "amsterdam"},
			{CountryCode: "NL", CityID: "zaanse-schans"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "NL", CityID: "amsterdam"},
			{CountryCode: "NL", CityID: "rotterdam"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="NL" selected>Нидерланды</option>`,
		`<option value="amsterdam" data-country="NL" selected>Амстердам</option>`,
		`<option value="zaanse-schans" data-country="NL" >Зансе-Сханс</option>`,
		`type="checkbox" name="access_cities" value="NL:zaanse-schans" checked`,
		`type="checkbox" name="departure_cities" value="NL:rotterdam" checked`,
		`Амстердам, Нидерланды`,
		`<option value="EUR" selected>Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Netherlands place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersBelarusPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=BY&city=minsk",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Национальная библиотека Беларуси",
				CountryCode:   "BY",
				CityID:        "minsk",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "BY",
			CityID:      "minsk",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="BY" data-country-filter-value`,
		`Беларусь`,
		`type="hidden" name="city" value="minsk" data-city-filter-value`,
		`Минск`,
		`Минск, Беларусь`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Belarus place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">BY<") || strings.Contains(listBody, ">minsk<") {
		t.Fatalf("Belarus place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "BYN"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Национальная библиотека Беларуси",
		Description:   "Современный символ Минска со смотровой площадкой и музеем книги.",
		CountryCode:   "BY",
		CityID:        "minsk",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "BY", CityID: "minsk"},
			{CountryCode: "BY", CityID: "mir"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "BY", CityID: "minsk"},
			{CountryCode: "BY", CityID: "brest"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="BY" selected>Беларусь</option>`,
		`<option value="minsk" data-country="BY" selected>Минск</option>`,
		`<option value="mir" data-country="BY" >Мир</option>`,
		`type="checkbox" name="access_cities" value="BY:mir" checked`,
		`type="checkbox" name="departure_cities" value="BY:brest" checked`,
		`Минск, Беларусь`,
		`<option value="BYN" selected>Белорусский рубль</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Belarus place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSerbiaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=RS&city=belgrade",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Белградская крепость",
				CountryCode:   "RS",
				CityID:        "belgrade",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "RS",
			CityID:      "belgrade",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="RS" data-country-filter-value`,
		`Сербия`,
		`type="hidden" name="city" value="belgrade" data-city-filter-value`,
		`Белград`,
		`Белград, Сербия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Serbia place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">RS<") || strings.Contains(listBody, ">belgrade<") {
		t.Fatalf("Serbia place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "RSD"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Белградская крепость",
		Description:   "Историческая крепость и парк Калемегдан в центре Белграда.",
		CountryCode:   "RS",
		CityID:        "belgrade",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "RS", CityID: "belgrade"},
			{CountryCode: "RS", CityID: "novi-sad"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "RS", CityID: "belgrade"},
			{CountryCode: "RS", CityID: "nis"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="RS" selected>Сербия</option>`,
		`<option value="belgrade" data-country="RS" selected>Белград</option>`,
		`<option value="novi-sad" data-country="RS" >Нови-Сад</option>`,
		`type="checkbox" name="access_cities" value="RS:novi-sad" checked`,
		`type="checkbox" name="departure_cities" value="RS:nis" checked`,
		`Белград, Сербия`,
		`<option value="RSD" selected>Сербский динар</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Serbia place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersGreecePlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=GR&city=athens",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Афинский Акрополь",
				CountryCode:   "GR",
				CityID:        "athens",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "GR",
			CityID:      "athens",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="GR" data-country-filter-value`,
		`Греция`,
		`type="hidden" name="city" value="athens" data-city-filter-value`,
		`Афины`,
		`Афины, Греция`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Greece place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">GR<") || strings.Contains(listBody, ">athens<") {
		t.Fatalf("Greece place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Афинский Акрополь",
		Description:   "Классический археологический символ Афин и всей Греции.",
		CountryCode:   "GR",
		CityID:        "athens",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "GR", CityID: "athens"},
			{CountryCode: "GR", CityID: "santorini"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "GR", CityID: "athens"},
			{CountryCode: "GR", CityID: "thessaloniki"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="GR" selected>Греция</option>`,
		`<option value="athens" data-country="GR" selected>Афины</option>`,
		`<option value="santorini" data-country="GR" >Санторини</option>`,
		`type="checkbox" name="access_cities" value="GR:santorini" checked`,
		`type="checkbox" name="departure_cities" value="GR:thessaloniki" checked`,
		`Афины, Греция`,
		`<option value="EUR" selected>Евро</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Greece place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersNewZealandPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=NZ&city=auckland",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Скай Тауэр",
				CountryCode:   "NZ",
				CityID:        "auckland",
				Category:      "ENTERTAINMENT",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "NZ",
			CityID:      "auckland",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="NZ" data-country-filter-value`,
		`Новая Зеландия`,
		`type="hidden" name="city" value="auckland" data-city-filter-value`,
		`Окленд`,
		`Окленд, Новая Зеландия`,
		`Развлечения`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("New Zealand place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">NZ<") || strings.Contains(listBody, ">auckland<") {
		t.Fatalf("New Zealand place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "NZD"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Скай Тауэр",
		Description:   "Обзорная башня в центре Окленда.",
		CountryCode:   "NZ",
		CityID:        "auckland",
		Category:      "ENTERTAINMENT",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "NZ", CityID: "auckland"},
			{CountryCode: "NZ", CityID: "queenstown"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "NZ", CityID: "auckland"},
			{CountryCode: "NZ", CityID: "wellington"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate edit returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="NZ" selected>Новая Зеландия</option>`,
		`<option value="auckland" data-country="NZ" selected>Окленд</option>`,
		`<option value="queenstown" data-country="NZ" >Квинстаун</option>`,
		`type="checkbox" name="access_cities" value="NZ:queenstown" checked`,
		`type="checkbox" name="departure_cities" value="NZ:wellington" checked`,
		`Окленд, Новая Зеландия`,
		`<option value="NZD" selected>Новозеландский доллар</option>`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("New Zealand place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersUkrainePlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=UA&city=kyiv",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "София Киевская",
				CountryCode:   "UA",
				CityID:        "kyiv",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "UA",
			CityID:      "kyiv",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="UA" data-country-filter-value`,
		`Украина`,
		`type="hidden" name="city" value="kyiv" data-city-filter-value`,
		`Киев`,
		`Киев, Украина`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Ukraine place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">UA<") || strings.Contains(listBody, ">kyiv<") {
		t.Fatalf("Ukraine place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "UAH"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "София Киевская",
		Description:   "Исторический собор и музейный комплекс в центре Киева.",
		CountryCode:   "UA",
		CityID:        "kyiv",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "UA", CityID: "kyiv"},
			{CountryCode: "UA", CityID: "lviv"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "UA", CityID: "kyiv"},
			{CountryCode: "UA", CityID: "odesa"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate form returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="UA" selected>Украина</option>`,
		`<option value="kyiv" data-country="UA" selected>Киев</option>`,
		`<option value="UAH" selected>Украинская гривна</option>`,
		`Киев, Украина`,
		`Львов, Украина`,
		`Одесса, Украина`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Ukraine place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersUnitedStatesPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=US&city=new-york",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Статуя Свободы",
				CountryCode:   "US",
				CityID:        "new-york",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "US",
			CityID:      "new-york",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="US" data-country-filter-value`,
		`США`,
		`type="hidden" name="city" value="new-york" data-city-filter-value`,
		`Нью-Йорк`,
		`Нью-Йорк, США`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("United States place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">US<") || strings.Contains(listBody, ">new-york<") {
		t.Fatalf("United States place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "USD"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Статуя Свободы",
		Description:   "Один из главных символов Нью-Йорка и США.",
		CountryCode:   "US",
		CityID:        "new-york",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "US", CityID: "new-york"},
			{CountryCode: "US", CityID: "washington-dc"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "US", CityID: "new-york"},
			{CountryCode: "US", CityID: "boston"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate form returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="US" selected>США</option>`,
		`<option value="new-york" data-country="US" selected>Нью-Йорк</option>`,
		`<option value="USD" selected>Доллар США</option>`,
		`Нью-Йорк, США`,
		`Вашингтон, США`,
		`Бостон, США`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("United States place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSingaporePlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=SG&city=singapore",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Сады у залива",
				CountryCode:   "SG",
				CityID:        "singapore",
				Category:      "PARK",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "SG",
			CityID:      "singapore",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="SG" data-country-filter-value`,
		`Сингапур`,
		`type="hidden" name="city" value="singapore" data-city-filter-value`,
		`Сингапур, Сингапур`,
		`Парк`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Singapore place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">SG<") || strings.Contains(listBody, ">singapore<") {
		t.Fatalf("Singapore place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "SGD"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Сады у залива",
		Description:   "Большой парк и теплицы в районе Marina Bay.",
		CountryCode:   "SG",
		CityID:        "singapore",
		Category:      "PARK",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "SG", CityID: "singapore"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "SG", CityID: "singapore"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate form returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="SG" selected>Сингапур</option>`,
		`<option value="singapore" data-country="SG" selected>Сингапур</option>`,
		`<option value="SGD" selected>Сингапурский доллар</option>`,
		`Сингапур, Сингапур`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Singapore place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersDenmarkPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=DK&city=copenhagen",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Сады Тиволи",
				CountryCode:   "DK",
				CityID:        "copenhagen",
				Category:      "ENTERTAINMENT",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "DK",
			CityID:      "copenhagen",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="DK" data-country-filter-value`,
		`Дания`,
		`type="hidden" name="city" value="copenhagen" data-city-filter-value`,
		`Копенгаген, Дания`,
		`Развлечения`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Denmark place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">DK<") || strings.Contains(listBody, ">copenhagen<") {
		t.Fatalf("Denmark place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "DKK"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Сады Тиволи",
		Description:   "Исторический парк развлечений в центре Копенгагена.",
		CountryCode:   "DK",
		CityID:        "copenhagen",
		Category:      "ENTERTAINMENT",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "DK", CityID: "copenhagen"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "DK", CityID: "copenhagen"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate form returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="DK" selected>Дания</option>`,
		`<option value="copenhagen" data-country="DK" selected>Копенгаген</option>`,
		`<option value="DKK" selected>Датская крона</option>`,
		`Копенгаген, Дания`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Denmark place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersFinlandPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=FI&city=helsinki",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Суоменлинна",
				CountryCode:   "FI",
				CityID:        "helsinki",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "FI",
			CityID:      "helsinki",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="FI" data-country-filter-value`,
		`Финляндия`,
		`type="hidden" name="city" value="helsinki" data-city-filter-value`,
		`Хельсинки, Финляндия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Finland place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">FI<") || strings.Contains(listBody, ">helsinki<") {
		t.Fatalf("Finland place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Суоменлинна",
		Description:   "Морская крепость на островах у Хельсинки.",
		CountryCode:   "FI",
		CityID:        "helsinki",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "FI", CityID: "helsinki"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "FI", CityID: "helsinki"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate form returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="FI" selected>Финляндия</option>`,
		`<option value="helsinki" data-country="FI" selected>Хельсинки</option>`,
		`<option value="EUR" selected>Евро</option>`,
		`Хельсинки, Финляндия`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Finland place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersCanadaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=CA&city=toronto",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Си-Эн Тауэр",
				CountryCode:   "CA",
				CityID:        "toronto",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "CA",
			CityID:      "toronto",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="CA" data-country-filter-value`,
		`Канада`,
		`type="hidden" name="city" value="toronto" data-city-filter-value`,
		`Торонто, Канада`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Canada place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">CA<") || strings.Contains(listBody, ">toronto<") {
		t.Fatalf("Canada place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "CAD"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Си-Эн Тауэр",
		Description:   "Смотровая башня и символ Торонто.",
		CountryCode:   "CA",
		CityID:        "toronto",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "CA", CityID: "toronto"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "CA", CityID: "toronto"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate form returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="CA" selected>Канада</option>`,
		`<option value="toronto" data-country="CA" selected>Торонто</option>`,
		`<option value="CAD" selected>Канадский доллар</option>`,
		`Торонто, Канада`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Canada place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersEstoniaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=EE&city=tallinn",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:            itemID,
				DefaultLocale: localeRU,
				Title:         "Старый город Таллина",
				CountryCode:   "EE",
				CityID:        "tallinn",
				Category:      "ARCHITECTURE",
				Source:        "IMPORT",
				Status:        "PUBLISHED",
				UpdatedAt:     time.Now().UTC(),
			},
		}, 1, PlaceFilterViewData{
			CountryCode: "EE",
			CityID:      "tallinn",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="EE" data-country-filter-value`,
		`Эстония`,
		`type="hidden" name="city" value="tallinn" data-city-filter-value`,
		`Таллин, Эстония`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Estonia place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">EE<") || strings.Contains(listBody, ">tallinn<") {
		t.Fatalf("Estonia place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Старый город Таллина",
		Description:   "Исторический центр столицы Эстонии.",
		CountryCode:   "EE",
		CityID:        "tallinn",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "EE", CityID: "tallinn"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "EE", CityID: "tallinn"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
		t.Fatalf("ExecuteTemplate form returned error: %v", err)
	}
	editBody := html.UnescapeString(editRendered.String())
	for _, expected := range []string{
		`<option value="EE" selected>Эстония</option>`,
		`<option value="tallinn" data-country="EE" selected>Таллин</option>`,
		`<option value="EUR" selected>Евро</option>`,
		`Таллин, Эстония`,
	} {
		if !strings.Contains(editBody, expected) {
			t.Fatalf("Estonia place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersAbkhaziaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=AB&city=sukhum",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "AB",
			CityID:      "sukhum",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="AB" data-country-filter-value`,
		`Абхазия`,
		`type="hidden" name="city" value="sukhum" data-city-filter-value`,
		`Сухум`,
		`Сухум, Абхазия`,
		`Парк`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Abkhazia place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AB<") || strings.Contains(listBody, ">sukhum<") {
		t.Fatalf("Abkhazia place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "RUB"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Сухумский ботанический сад",
		Description:   "Исторический ботанический сад в центре Сухума.",
		CountryCode:   "AB",
		CityID:        "sukhum",
		Category:      "PARK",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "AB", CityID: "gagra"},
			{CountryCode: "AB", CityID: "new-athos"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "AB", CityID: "pitsunda"},
			{CountryCode: "AB", CityID: "lake-ritsa"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Abkhazia place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersCubaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=CU&city=havana",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "CU",
			CityID:      "havana",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="CU" data-country-filter-value`,
		`Куба`,
		`type="hidden" name="city" value="havana" data-city-filter-value`,
		`Гавана`,
		`Гавана, Куба`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Cuba place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">CU<") || strings.Contains(listBody, ">havana<") {
		t.Fatalf("Cuba place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "CUP"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Старая Гавана",
		Description:   "Исторический центр столицы Кубы.",
		CountryCode:   "CU",
		CityID:        "havana",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "CU", CityID: "varadero"},
			{CountryCode: "CU", CityID: "vinales"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "CU", CityID: "havana"},
			{CountryCode: "CU", CityID: "trinidad"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Cuba place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersMoroccoPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=MA&city=marrakech",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "MA",
			CityID:      "marrakech",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="MA" data-country-filter-value`,
		`Марокко`,
		`type="hidden" name="city" value="marrakech" data-city-filter-value`,
		`Марракеш`,
		`Марракеш, Марокко`,
		`Рынок`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Morocco place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">MA<") || strings.Contains(listBody, ">marrakech<") {
		t.Fatalf("Morocco place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "MAD"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Медина Марракеша",
		Description:   "Исторический центр Марракеша.",
		CountryCode:   "MA",
		CityID:        "marrakech",
		Category:      "MARKET",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "MA", CityID: "agafay"},
			{CountryCode: "MA", CityID: "ourika"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "MA", CityID: "marrakech"},
			{CountryCode: "MA", CityID: "casablanca"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Morocco place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersPortugalPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=PT&city=lisbon",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "PT",
			CityID:      "lisbon",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="PT" data-country-filter-value`,
		`Португалия`,
		`type="hidden" name="city" value="lisbon" data-city-filter-value`,
		`Лиссабон`,
		`Лиссабон, Португалия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Portugal place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">PT<") || strings.Contains(listBody, ">lisbon<") {
		t.Fatalf("Portugal place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Монастырь Жеронимуш",
		Description:   "Один из главных памятников Лиссабона.",
		CountryCode:   "PT",
		CityID:        "lisbon",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "PT", CityID: "sintra"},
			{CountryCode: "PT", CityID: "cascais"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "PT", CityID: "lisbon"},
			{CountryCode: "PT", CityID: "porto"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Portugal place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersItalyPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=IT&city=florence",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "IT",
			CityID:      "florence",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="IT" data-country-filter-value`,
		`Италия`,
		`type="hidden" name="city" value="florence" data-city-filter-value`,
		`Флоренция`,
		`Флоренция, Италия`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Italy place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">IT<") || strings.Contains(listBody, ">florence<") {
		t.Fatalf("Italy place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Галерея Уффици",
		Description:   "Один из главных художественных музеев Флоренции.",
		CountryCode:   "IT",
		CityID:        "florence",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "IT", CityID: "pisa"},
			{CountryCode: "IT", CityID: "siena"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "IT", CityID: "florence"},
			{CountryCode: "IT", CityID: "rome"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Italy place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersSpainPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=ES&city=barcelona",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "ES",
			CityID:      "barcelona",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="ES" data-country-filter-value`,
		`Испания`,
		`type="hidden" name="city" value="barcelona" data-city-filter-value`,
		`Барселона`,
		`Барселона, Испания`,
		`Храм`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Spain place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">ES<") || strings.Contains(listBody, ">barcelona<") {
		t.Fatalf("Spain place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Саграда Фамилия",
		Description:   "Главный храм Барселоны и один из символов Испании.",
		CountryCode:   "ES",
		CityID:        "barcelona",
		Category:      "TEMPLE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "ES", CityID: "girona"},
			{CountryCode: "ES", CityID: "costa-brava"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "ES", CityID: "barcelona"},
			{CountryCode: "ES", CityID: "salou"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Spain place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersLuxembourgPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=LU&city=luxembourg-city",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "LU",
			CityID:      "luxembourg-city",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="LU" data-country-filter-value`,
		`Люксембург`,
		`type="hidden" name="city" value="luxembourg-city" data-city-filter-value`,
		`Люксембург, Люксембург`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Luxembourg place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">LU<") || strings.Contains(listBody, ">luxembourg-city<") {
		t.Fatalf("Luxembourg place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Казематы Бок",
		Description:   "Подземные укрепления Люксембурга.",
		CountryCode:   "LU",
		CityID:        "luxembourg-city",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "LU", CityID: "vianden"},
			{CountryCode: "LU", CityID: "echternach"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "LU", CityID: "luxembourg-city"},
			{CountryCode: "LU", CityID: "esch-sur-alzette"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Luxembourg place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersGermanyPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=DE&city=berlin",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "DE",
			CityID:      "berlin",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="DE" data-country-filter-value`,
		`Германия`,
		`type="hidden" name="city" value="berlin" data-city-filter-value`,
		`Берлин`,
		`Берлин, Германия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Germany place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">DE<") || strings.Contains(listBody, ">berlin<") {
		t.Fatalf("Germany place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Бранденбургские ворота",
		Description:   "Исторический символ Берлина.",
		CountryCode:   "DE",
		CityID:        "berlin",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "DE", CityID: "potsdam"},
			{CountryCode: "DE", CityID: "hamburg"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "DE", CityID: "berlin"},
			{CountryCode: "DE", CityID: "munich"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Germany place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersAustriaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=AT&city=vienna",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "AT",
			CityID:      "vienna",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="AT" data-country-filter-value`,
		`Австрия`,
		`type="hidden" name="city" value="vienna" data-city-filter-value`,
		`Вена`,
		`Вена, Австрия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Austria place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AT<") || strings.Contains(listBody, ">vienna<") {
		t.Fatalf("Austria place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "EUR"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Дворец Шёнбрунн",
		Description:   "Императорский дворец и парк в Вене.",
		CountryCode:   "AT",
		CityID:        "vienna",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "AT", CityID: "salzburg"},
			{CountryCode: "AT", CityID: "innsbruck"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "AT", CityID: "vienna"},
			{CountryCode: "AT", CityID: "graz"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Austria place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersAustraliaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=AU&city=sydney",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "AU",
			CityID:      "sydney",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="AU" data-country-filter-value`,
		`Австралия`,
		`type="hidden" name="city" value="sydney" data-city-filter-value`,
		`Сидней`,
		`Сидней, Австралия`,
		`Архитектура`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Australia place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">AU<") || strings.Contains(listBody, ">sydney<") {
		t.Fatalf("Australia place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "AUD"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Сиднейская опера",
		Description:   "Знаковый концертный комплекс на гавани Сиднея.",
		CountryCode:   "AU",
		CityID:        "sydney",
		Category:      "ARCHITECTURE",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "AU", CityID: "blue-mountains"},
			{CountryCode: "AU", CityID: "canberra"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "AU", CityID: "sydney"},
			{CountryCode: "AU", CityID: "melbourne"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Australia place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersTanzaniaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=TZ&city=dar-es-salaam",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "TZ",
			CityID:      "dar-es-salaam",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="TZ" data-country-filter-value`,
		`Танзания`,
		`type="hidden" name="city" value="dar-es-salaam" data-city-filter-value`,
		`Дар-эс-Салам`,
		`Дар-эс-Салам, Танзания`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Tanzania place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">TZ<") || strings.Contains(listBody, ">dar-es-salaam<") {
		t.Fatalf("Tanzania place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "TZS"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Национальный музей Танзании",
		Description:   "Главный музей Дар-эс-Салама о стране, истории и культуре.",
		CountryCode:   "TZ",
		CityID:        "dar-es-salaam",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "TZ", CityID: "zanzibar-city"},
			{CountryCode: "TZ", CityID: "arusha"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "TZ", CityID: "dar-es-salaam"},
			{CountryCode: "TZ", CityID: "stone-town"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Tanzania place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersKenyaPlaceReferencesLocalized(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	itemID := uuid.New()
	listPageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?country=KE&city=nairobi",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{
			CountryCode: "KE",
			CityID:      "nairobi",
		}),
	}

	var listRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&listRendered, "places/index", listPageData); err != nil {
		t.Fatalf("ExecuteTemplate list returned error: %v", err)
	}
	listBody := html.UnescapeString(listRendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="KE" data-country-filter-value`,
		`Кения`,
		`type="hidden" name="city" value="nairobi" data-city-filter-value`,
		`Найроби`,
		`Найроби, Кения`,
		`Музей`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("Kenya place list did not render localized reference %q: %s", expected, listBody)
		}
	}
	if strings.Contains(listBody, ">KE<") || strings.Contains(listBody, ">nairobi<") {
		t.Fatalf("Kenya place list still renders raw codes: %s", listBody)
	}

	priceCurrency := "KES"
	editItem := &model.AdminPlace{
		ID:            itemID,
		DefaultLocale: localeRU,
		Title:         "Национальный музей Найроби",
		Description:   "Главный музей Кении о культуре, природе и истории страны.",
		CountryCode:   "KE",
		CityID:        "nairobi",
		Category:      "MUSEUM",
		Status:        "PUBLISHED",
		PriceCurrency: &priceCurrency,
		AccessCities: []model.PlaceCityLink{
			{CountryCode: "KE", CityID: "mombasa"},
			{CountryCode: "KE", CityID: "masai-mara"},
		},
		DepartureCities: []model.PlaceCityLink{
			{CountryCode: "KE", CityID: "nairobi"},
			{CountryCode: "KE", CityID: "diani"},
		},
	}
	editPageData := PageData{
		Title:     "Edit place",
		Locale:    localeRU,
		Path:      "/admin/places/" + itemID.String() + "/edit",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data:      NewPlaceFormViewData(editItem, model.PlaceInput{}),
	}

	var editRendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&editRendered, "places/form", editPageData); err != nil {
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
			t.Fatalf("Kenya place form did not render localized reference %q: %s", expected, editBody)
		}
	}
}

func TestRendererRendersPlaceListCountryCitySearchFilters(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData(nil, 0, PlaceFilterViewData{
			CountryCode: "KZ",
			CityID:      "almaty",
		}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		`type="hidden" name="country" value="KZ" data-country-filter-value`,
		`type="search" data-country-filter-input`,
		`data-country-filter-suggestions role="listbox" hidden`,
		`type="button" class="filter-suggestion" data-country-filter-option`,
		`data-value="KZ"`,
		`data-label="Казахстан"`,
		`data-search="KZ Kazakhstan Казахстан`,
		`Казахстан`,
		`type="hidden" name="city" value="almaty" data-city-filter-value`,
		`type="search" data-city-filter-input`,
		`data-city-filter-suggestions role="listbox" hidden`,
		`type="button" class="filter-suggestion" data-city-filter-option`,
		`data-city-filter-group`,
		`data-country="KZ" data-value="almaty"`,
		`data-label="Алматы"`,
		`data-search="KZ:almaty almaty Алматы`,
		`Алматы`,
		`Все страны`,
		`Все города`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("place list did not render searchable filter %q: %s", expected, body)
		}
	}
	for _, unexpected := range []string{
		`<select name="country"`,
		`<select name="city"`,
		`list="place-country-filter-options"`,
		`list="place-city-filter-options"`,
		`<datalist`,
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("place list still renders dropdown filter %q: %s", unexpected, body)
		}
	}
}

func TestRendererHidesPlaceCityFilterUntilCountrySelected(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places",
		Staff:  adminTemplateActor(),
		Data:   NewPlaceListViewData(nil, 0, PlaceFilterViewData{}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	if !strings.Contains(body, `data-city-filter-group hidden`) {
		t.Fatalf("city filter group should be hidden before country selection: %s", body)
	}
	if !strings.Contains(body, `data-city-filter-input value="" placeholder="Все города" autocomplete="off" autocorrect="off" spellcheck="false" aria-autocomplete="none" aria-expanded="false" aria-controls="place-city-filter-suggestions" disabled`) {
		t.Fatalf("city filter input should be disabled before country selection: %s", body)
	}
}

func TestRendererRendersPlaceCountryBackfillActionWhenCountrySelected(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places",
		Staff:  superAdminTemplateActor(),
		Data: NewPlaceListViewData(nil, 0, PlaceFilterViewData{
			CountryCode: "KZ",
		}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		`method="post" action="/admin/places/media/backfill"`,
		`name="country" value="KZ"`,
		`Запустить backfill по стране`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("place list did not render country backfill action %q: %s", expected, body)
		}
	}
}

func TestRendererHidesPlaceCountryBackfillActionForNonSuperAdmin(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData(nil, 0, PlaceFilterViewData{
			CountryCode: "KZ",
		}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	if strings.Contains(body, `/admin/places/media/backfill`) {
		t.Fatalf("place list rendered country backfill action for non-superadmin: %s", body)
	}
}

func TestRendererHidesPlaceCountryBackfillActionUntilCountrySelected(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places",
		Staff:  adminTemplateActor(),
		Data:   NewPlaceListViewData(nil, 0, PlaceFilterViewData{}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	if strings.Contains(body, `/admin/places/media/backfill`) {
		t.Fatalf("place list rendered country backfill action without a country filter: %s", body)
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

func TestAdminJSKeepsPlaceUploadPreviewCaptionsReadable(t *testing.T) {
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

func TestAdminJSPlaceFilterDoesNotAutoSelectSearchSuggestions(t *testing.T) {
	t.Parallel()

	content, err := embeddedFiles.ReadFile("static/js/admin.js")
	if err != nil {
		t.Fatalf("ReadFile returned error: %v", err)
	}
	js := string(content)
	for _, unexpected := range []string{
		"search.split(/\\s+/).includes(query)",
		"applyExactCountry(false)",
		"applyExactCountry(true)",
		"applyExactCity(false)",
		"applyExactCity(true)",
	} {
		if strings.Contains(js, unexpected) {
			t.Fatalf("admin place filter should not auto-select search suggestions, found %q", unexpected)
		}
	}
	for _, expected := range []string{
		"selectCountry",
		"selectCity",
		"renderSuggestions(countryInput, countrySuggestions, countryOptions)",
		"renderSuggestions(cityInput, citySuggestions, cityOptions, cityBelongsToSelectedCountry)",
	} {
		if !strings.Contains(js, expected) {
			t.Fatalf("admin place filter should keep explicit suggestion selection behavior, missing %q", expected)
		}
	}
}

func TestAdminJSInitializesSupportRoutingComboboxesUnderCSP(t *testing.T) {
	t.Parallel()

	content, err := embeddedFiles.ReadFile("static/js/admin.js")
	if err != nil {
		t.Fatalf("ReadFile returned error: %v", err)
	}
	js := string(content)
	for _, expected := range []string{
		`document.querySelectorAll("[data-support-agent-staff-combobox]")`,
		`document.querySelectorAll("[data-support-agent-timezone-combobox]")`,
		`[data-support-agent-timezone-option]`,
		`replace(/ё/g, "е")`,
		`input.reportValidity();`,
	} {
		if !strings.Contains(js, expected) {
			t.Fatalf("admin js must initialize support routing comboboxes under strict CSP, missing %q", expected)
		}
	}
}

func TestAdminJSPaginatedTablesKeepTotalPagesInClickHandlerScope(t *testing.T) {
	t.Parallel()

	content, err := embeddedFiles.ReadFile("static/js/admin.js")
	if err != nil {
		t.Fatalf("ReadFile returned error: %v", err)
	}
	js := string(content)
	if !strings.Contains(js, "let totalPages = 1;") {
		t.Fatalf("paginated tables should keep totalPages in the outer click-handler closure")
	}
	if strings.Contains(js, "const totalPages = Math.max(1, Math.ceil(visibleRows.length / pageSize));") {
		t.Fatalf("totalPages must not be scoped only to renderPage")
	}
	if !strings.Contains(js, "totalPages = Math.max(1, Math.ceil(visibleRows.length / pageSize));") {
		t.Fatalf("renderPage should refresh the outer totalPages value")
	}
}

func TestAdminJSFeatureFlagArrayValuesStayControlledByType(t *testing.T) {
	t.Parallel()

	content, err := embeddedFiles.ReadFile("static/js/admin.js")
	if err != nil {
		t.Fatalf("ReadFile returned error: %v", err)
	}
	js := string(content)
	for _, expected := range []string{
		`document.querySelectorAll("[data-feature-flag-values]")`,
		`event.preventDefault();`,
		`clearRows();`,
		`input.disabled = Boolean(typeSelect && typeSelect.value === "TOGGLE");`,
		`typeSelect.addEventListener("change", sync);`,
	} {
		if !strings.Contains(js, expected) {
			t.Fatalf("feature flag array value JS is missing %q", expected)
		}
	}
	featureFlagInit := strings.Index(js, `document.querySelectorAll("[data-feature-flag-values]")`)
	confirmationDialogEarlyReturn := strings.Index(js, "if (!dialog) {\n    return;\n  }")
	if confirmationDialogEarlyReturn >= 0 && confirmationDialogEarlyReturn < featureFlagInit {
		t.Fatal("feature flag array value JS must not be skipped when the moderation confirmation dialog is absent")
	}
}

func TestAdminJSConfirmsVisitInfoRepeatRowDeletion(t *testing.T) {
	t.Parallel()

	content, err := embeddedFiles.ReadFile("static/js/admin.js")
	if err != nil {
		t.Fatalf("ReadFile returned error: %v", err)
	}
	js := string(content)
	for _, expected := range []string{
		`const confirmRemoveText = locale === "ru" ? "Удалить этот пункт?" : "Delete this item?";`,
		`if (!window.confirm(confirmRemoveText)) {`,
		`row.remove();`,
	} {
		if !strings.Contains(js, expected) {
			t.Fatalf("visit-info repeat row deletion should require confirmation, missing %q", expected)
		}
	}
	confirmIndex := strings.Index(js, `if (!window.confirm(confirmRemoveText)) {`)
	removeIndex := strings.Index(js, `row.remove();`)
	if confirmIndex < 0 || removeIndex < 0 || confirmIndex > removeIndex {
		t.Fatal("visit-info repeat row confirmation must run before row.remove()")
	}
}

func TestAdminJSInitializesMeetingMapsWithMapLibre(t *testing.T) {
	t.Parallel()

	content, err := embeddedFiles.ReadFile("static/js/admin.js")
	if err != nil {
		t.Fatalf("ReadFile returned error: %v", err)
	}
	js := string(content)
	for _, expected := range []string{
		"/admin/static/vendor/maplibre/maplibre-gl.js",
		"/admin/static/vendor/maplibre/maplibre-gl.css",
		"https://tiles.openfreemap.org/styles/liberty",
		"[data-meeting-map]",
		"new maplibregl.Map",
		"new maplibregl.Marker",
		"new maplibregl.NavigationControl",
	} {
		if !strings.Contains(js, expected) {
			t.Fatalf("admin js should initialize meeting maps with MapLibre, missing %q", expected)
		}
	}
	if strings.Contains(js, "unpkg.com") || strings.Contains(js, "cdn.jsdelivr.net") {
		t.Fatalf("admin js should not load MapLibre from public CDN under strict admin CSP: %s", js)
	}
}

func TestRendererEmbedsLocalMapLibreAssets(t *testing.T) {
	t.Parallel()

	for _, path := range []string{
		"static/vendor/maplibre/maplibre-gl.js",
		"static/vendor/maplibre/maplibre-gl.css",
	} {
		content, err := embeddedFiles.ReadFile(path)
		if err != nil {
			t.Fatalf("MapLibre asset %q should be embedded: %v", path, err)
		}
		if len(content) == 0 {
			t.Fatalf("MapLibre asset %q should not be empty", path)
		}
	}
}

func TestRendererEmbedsAdminBrandIconAssets(t *testing.T) {
	t.Parallel()

	for _, path := range []string{
		"static/favicon.ico",
		"static/apple-touch-icon.png",
	} {
		content, err := embeddedFiles.ReadFile(path)
		if err != nil {
			t.Fatalf("admin brand icon asset %q should be embedded: %v", path, err)
		}
		if len(content) == 0 {
			t.Fatalf("admin brand icon asset %q should not be empty", path)
		}
	}

	base, err := embeddedFiles.ReadFile("templates/base.html")
	if err != nil {
		t.Fatalf("read embedded base template: %v", err)
	}
	body := string(base)
	for _, expected := range []string{
		`<link rel="icon" href="/admin/static/favicon.ico" sizes="any">`,
		`<link rel="apple-touch-icon" href="/admin/static/apple-touch-icon.png">`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("base template should expose admin brand icon link %q", expected)
		}
	}
}

func TestRendererRendersPlaceListLocalizedRows(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	itemID := uuid.New()
	pageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
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
		}, 1, PlaceFilterViewData{}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		"Орал, Казахстан",
		"Музей",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("place list row did not render localized value %q: %s", expected, body)
		}
	}
	if strings.Contains(body, "Основной язык:") ||
		strings.Contains(body, "Источник:") ||
		strings.Contains(body, "en · IMPORT") ||
		strings.Contains(body, ">museum<") ||
		strings.Contains(body, ">oral<") {
		t.Fatalf("place list row still renders raw codes: %s", body)
	}
}

func TestRendererRendersPlaceListPagination(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	pageData := PageData{
		Title:  "Places",
		Locale: localeRU,
		Path:   "/admin/places?page=2&q=lake",
		Staff:  adminTemplateActor(),
		Data: NewPlaceListViewData([]model.AdminPlace{
			{
				ID:        uuid.New(),
				Title:     "Lake",
				CityID:    "almaty",
				Category:  "NATURE",
				Status:    "PUBLISHED",
				UpdatedAt: time.Now().UTC(),
			},
		}, 60, PlaceFilterViewData{
			Search: "lake",
			Page:   2,
			Query:  "q=lake",
		}),
	}

	var rendered bytes.Buffer
	if err = renderer.templates.ExecuteTemplate(&rendered, "places/index", pageData); err != nil {
		t.Fatalf("ExecuteTemplate returned error: %v", err)
	}
	body := html.UnescapeString(rendered.String())
	for _, expected := range []string{
		"Показано 26-50 из 60",
		`href="/admin/places?page=1&q=lake"`,
		`href="/admin/places?page=3&q=lake"`,
		`class="pagination-page" href="/admin/places?page=1&q=lake">1</a>`,
		`class="pagination-page is-current" aria-current="page">2</span>`,
		`class="pagination-page" href="/admin/places?page=3&q=lake">3</a>`,
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
					PlaceNames:            []string{"Big Almaty Lake", "Medeu"},
					DurationMinutes:       150,
					MaxGroupSize:          8,
					LanguageCodes:         []string{"ru", "en"},
					MeetingPoint:          "Главный вход Медеу",
					MeetingPointByLocale: map[string]string{
						"ru": "Локализованная точка встречи",
					},
					Latitude:      floatPtr(43.157036),
					Longitude:     floatPtr(77.058482),
					MapURL:        stringPtr("https://inflap.app/map?lat=43.157036&lon=77.058482&title=Medeu"),
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
							PlaceName:          "Big Almaty Lake",
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
		t.Fatal("moderation detail did not render route place names")
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
		"Карта точки встречи",
		`data-meeting-map`,
		`data-map-style-url="https://tiles.openfreemap.org/styles/liberty"`,
		`data-lat="43.1570360"`,
		`data-lon="77.0584820"`,
		`data-map-title="Локализованная точка встречи"`,
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
		"Карта точки встречи",
		`data-meeting-map`,
		`data-map-style-url="https://tiles.openfreemap.org/styles/liberty"`,
		`data-lat="43.2435000"`,
		`data-lon="76.9041000"`,
		`data-map-title="Dostyk Plaza"`,
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
	documentDownloadURL := "http://file-manager-minio:9000/inflap-files/guide_verification_doc/2026/04/13/fbc1a575-b630-47b2-b071-f8ec43694947.jpg?X-Amz-Signature=test"
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
					PlaceNamesByLocale: map[string][]string{
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
		Email:       "moderator@inflap.local",
		DisplayName: "Нурланова Айгерим Сапаровна",
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
	for _, expected := range []string{
		`name="last_name"`,
		`name="first_name"`,
		`name="middle_name"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("staff create template did not render %q: %s", expected, body)
		}
	}
	if strings.Contains(body, `name="display_name"`) {
		t.Fatalf("staff create template still renders display_name: %s", body)
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
		`name="last_name"`,
		`value="Нурланова"`,
		`name="first_name"`,
		`value="Айгерим"`,
		`name="middle_name"`,
		`value="Сапаровна"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("staff edit template did not render %q: %s", expected, body)
		}
	}
	if strings.Contains(body, `name="display_name"`) {
		t.Fatalf("staff edit template still renders display_name: %s", body)
	}
}

func TestStaffDisplayNameFromFormBuildsRequiredFullName(t *testing.T) {
	t.Parallel()

	form := url.Values{}
	form.Set("last_name", "  Нурланова ")
	form.Set("first_name", " Айгерим ")
	form.Set("middle_name", " Сапаровна ")

	displayName, ok := staffDisplayNameFromForm(form)
	if !ok {
		t.Fatal("staffDisplayNameFromForm() returned ok=false")
	}
	if displayName != "Нурланова Айгерим Сапаровна" {
		t.Fatalf("displayName = %q", displayName)
	}

	form.Del("last_name")
	if _, ok = staffDisplayNameFromForm(form); ok {
		t.Fatal("staffDisplayNameFromForm() accepted missing last_name")
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
		Email:       "moderator@inflap.local",
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
				ActorEmail:       "moderator@inflap.local",
				Action:           "admin.login.succeeded",
				EntityType:       "staff_session",
				CreatedAt:        baseTime,
			},
			{
				ActorStaffID:     &staffID,
				ActorDisplayName: "Aruzhan Ops",
				ActorEmail:       "moderator@inflap.local",
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
		"moderator@inflap.local",
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
		Email:       "admin@inflap.local",
		DisplayName: "Admin",
		Status:      enum.StaffStatusActive,
		Roles:       []enum.StaffRole{enum.StaffRoleAdmin},
		Permissions: []enum.Permission{enum.PermissionStaffManage},
	}
}

func superAdminTemplateActor() *model.StaffUser {
	staff := adminTemplateActor()
	staff.Roles = []enum.StaffRole{enum.StaffRoleSuperAdmin}
	staff.Permissions = append(staff.Permissions, enum.PermissionPlaceManage)
	return staff
}

func intPtr(value int) *int {
	return &value
}

func floatPtr(value float64) *float64 {
	return &value
}

func stringPtr(value string) *string {
	return &value
}

func uuidPtr(value uuid.UUID) *uuid.UUID {
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
