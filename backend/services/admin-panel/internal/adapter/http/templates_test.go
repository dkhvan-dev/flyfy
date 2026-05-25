package http

import (
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
