package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"kz/inflap/backend/services/checklist-service/internal/domain/model"
)

func TestGenerateTripChecklistAddsSeasonalActivityAndRestrictionItems(t *testing.T) {
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)

	startAt := time.Date(2026, time.January, 12, 10, 0, 0, 0, time.UTC)
	result, err := uc.GenerateTripChecklist(GenerateTripChecklistInput{
		UserID:      "user-1",
		TripID:      "trip-bali-jan",
		Destination: model.TripDestination{CountryCode: "ID", CityName: "Bali"},
		StartAt:     startAt,
		EndAt:       startAt.AddDate(0, 0, 7),
		TransportModes: []model.TransportMode{
			model.TransportModeFlight,
		},
		ActivitySlugs: []string{"beach", "hiking"},
		TravelerProfile: model.TravelerProfile{
			HasChildren:       true,
			PreferredLanguage: "ru",
		},
	})
	if err != nil {
		t.Fatalf("GenerateTripChecklist returned error: %v", err)
	}

	assertHasItem(t, result.Items, "documents.passport", model.ChecklistPriorityCritical)
	assertHasItem(t, result.Items, "documents.child_documents", model.ChecklistPriorityCritical)
	assertHasItem(t, result.Items, "weather.bali_january_rain_kit", model.ChecklistPriorityImportant)
	assertHasItem(t, result.Items, "activity.hiking_daypack", model.ChecklistPriorityEssential)
	assertHasItem(t, result.Items, "baggage.power_bank_carry_on", model.ChecklistPriorityRecommended)

	if result.SeasonalProfile == nil {
		t.Fatal("expected seasonal profile")
	}
	if result.SeasonalProfile.PrecipitationBand != model.PrecipitationRainy {
		t.Fatalf("expected rainy precipitation band, got %q", result.SeasonalProfile.PrecipitationBand)
	}
	if result.Readiness.Status != model.ReadinessStatusNotReady {
		t.Fatalf("expected not_ready status while critical self-checks are open, got %q", result.Readiness.Status)
	}
	if result.Readiness.Score >= 60 {
		t.Fatalf("expected critical open items to cap score below 60, got %d", result.Readiness.Score)
	}
	if len(result.Readiness.Blockers) == 0 {
		t.Fatal("expected readiness blockers")
	}
	if result.TrustNotice.Code != "official_source_required" {
		t.Fatalf("expected official source trust notice, got %q", result.TrustNotice.Code)
	}
}

func TestGenerateTripChecklistUsesCitizenshipForInternationalDocuments(t *testing.T) {
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)
	startAt := time.Date(2026, time.May, 15, 10, 0, 0, 0, time.UTC)

	domestic, err := uc.GenerateTripChecklist(GenerateTripChecklistInput{
		UserID:      "user-1",
		TripID:      "trip-almaty",
		Destination: model.TripDestination{CountryCode: "KZ", CityName: "Almaty"},
		StartAt:     startAt,
		EndAt:       startAt.AddDate(0, 0, 4),
		TravelerProfile: model.TravelerProfile{
			CitizenshipCountryCode: "KZ",
			PreferredLanguage:      "ru",
		},
	})
	if err != nil {
		t.Fatalf("GenerateTripChecklist domestic returned error: %v", err)
	}
	assertNoItem(t, domestic.Items, "documents.travel_insurance")

	international, err := uc.GenerateTripChecklist(GenerateTripChecklistInput{
		UserID:      "user-1",
		TripID:      "trip-istanbul",
		Destination: model.TripDestination{CountryCode: "TR", CityName: "Istanbul"},
		StartAt:     startAt,
		EndAt:       startAt.AddDate(0, 0, 4),
		TravelerProfile: model.TravelerProfile{
			CitizenshipCountryCode: "KZ",
			PreferredLanguage:      "ru",
		},
	})
	if err != nil {
		t.Fatalf("GenerateTripChecklist international returned error: %v", err)
	}
	assertHasItem(t, international.Items, "documents.travel_insurance", model.ChecklistPriorityEssential)
}

func TestCalculateReadinessTreatsCriticalItemsAsHardGates(t *testing.T) {
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)

	items := []model.ChecklistItem{
		{ID: "passport", Priority: model.ChecklistPriorityCritical, Status: model.ChecklistItemDone},
		{ID: "visa", Priority: model.ChecklistPriorityCritical, Status: model.ChecklistItemOpen, RequiresUserConfirmation: true},
		{ID: "rain", Priority: model.ChecklistPriorityImportant, Status: model.ChecklistItemDone},
		{ID: "neck_pillow", Priority: model.ChecklistPriorityOptional, Status: model.ChecklistItemOpen},
	}

	readiness := uc.CalculateReadiness(items, time.Date(2026, time.June, 1, 12, 0, 0, 0, time.UTC))

	if readiness.Status != model.ReadinessStatusNotReady {
		t.Fatalf("expected not_ready, got %q", readiness.Status)
	}
	if readiness.Score != 50 {
		t.Fatalf("expected score capped at 50 with an open critical gate, got %d", readiness.Score)
	}
	if len(readiness.Blockers) != 1 || readiness.Blockers[0].ItemID != "visa" {
		t.Fatalf("expected visa blocker, got %#v", readiness.Blockers)
	}
}

func TestSearchCarryItemReturnsCautiousOfficialSourceGuidance(t *testing.T) {
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)

	matches := uc.SearchCarryItems(SearchCarryItemsInput{
		Query:         "power bank 20000",
		TransportMode: model.TransportModeFlight,
		PreferredLang: "en",
		Limit:         5,
	})

	if len(matches) != 1 {
		t.Fatalf("expected one match, got %d", len(matches))
	}

	match := matches[0]
	if match.ItemSlug != "power_bank" {
		t.Fatalf("expected power_bank match, got %q", match.ItemSlug)
	}
	if match.CheckedBaggage != model.CarryPolicyProhibited {
		t.Fatalf("expected checked baggage prohibited, got %q", match.CheckedBaggage)
	}
	if match.CarryOn != model.CarryPolicyAllowedWithConditions {
		t.Fatalf("expected carry-on allowed with conditions, got %q", match.CarryOn)
	}
	if match.Source.URL == "" || match.Source.Confidence != model.SourceConfidenceHigh {
		t.Fatalf("expected high-confidence official source, got %#v", match.Source)
	}
	if !match.RequiresAirlineCheck {
		t.Fatal("expected airline check flag for battery capacity")
	}
}

func TestSearchCarryItemMatchesUserFriendlyRussianQueries(t *testing.T) {
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)

	tests := map[string]string{
		"повербанк":  "power_bank",
		"повер банк": "power_bank",
		"повер":      "power_bank",
		"виза":       "travel_visa",
	}

	for query, expectedSlug := range tests {
		t.Run(query, func(t *testing.T) {
			matches := uc.SearchCarryItems(SearchCarryItemsInput{
				Query:         query,
				TransportMode: model.TransportModeFlight,
				PreferredLang: "ru",
				Limit:         5,
			})

			if len(matches) == 0 {
				t.Fatalf("expected match for %q", query)
			}
			if matches[0].ItemSlug != expectedSlug {
				t.Fatalf("expected %q for query %q, got %q", expectedSlug, query, matches[0].ItemSlug)
			}
		})
	}
}

func TestDispatchDueChecklistNotificationsDoesNotSendAutomaticChecklistPushes(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, time.January, 9, 8, 0, 0, 0, time.UTC)
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(
		repo,
		WithChecklistClock(func() time.Time { return now }),
	)

	startAt := time.Date(2026, time.January, 12, 10, 0, 0, 0, time.UTC)
	_, err := uc.GetOrCreateTripChecklist(ctx, GenerateTripChecklistInput{
		UserID:      "11111111-1111-1111-1111-111111111111",
		TripID:      "trip-bali-jan",
		Destination: model.TripDestination{CountryCode: "ID", CityName: "Bali"},
		StartAt:     startAt,
		EndAt:       startAt.AddDate(0, 0, 7),
		TransportModes: []model.TransportMode{
			model.TransportModeFlight,
		},
		ActivitySlugs: []string{"hiking"},
		TravelerProfile: model.TravelerProfile{
			PreferredLanguage: "ru",
		},
	})
	if err != nil {
		t.Fatalf("GetOrCreateTripChecklist returned error: %v", err)
	}

	result, err := uc.DispatchDueChecklistNotifications(ctx, DispatchChecklistNotificationsInput{
		Limit:             10,
		PreferredLanguage: "ru",
	})
	if err != nil {
		t.Fatalf("DispatchDueChecklistNotifications returned error: %v", err)
	}
	if result.Scanned != 1 || result.Sent != 0 || result.Skipped != 1 {
		t.Fatalf("unexpected dispatch result: %#v", result)
	}
}

func TestDispatchDueChecklistNotificationsSkipsReadyTrips(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, time.January, 9, 8, 0, 0, 0, time.UTC)
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(
		repo,
		WithChecklistClock(func() time.Time { return now }),
	)

	checklist := createTestTripChecklist(
		t,
		ctx,
		uc,
		"22222222-2222-2222-2222-222222222222",
		"trip-ready",
	)
	for _, item := range checklist.Items {
		if _, err := uc.UpdateChecklistItemStatus(ctx, UpdateChecklistItemStatusInput{
			UserID: "22222222-2222-2222-2222-222222222222",
			TripID: "trip-ready",
			ItemID: item.ID,
			Status: model.ChecklistItemDone,
		}); err != nil {
			t.Fatalf("UpdateChecklistItemStatus returned error: %v", err)
		}
	}

	result, err := uc.DispatchDueChecklistNotifications(ctx, DispatchChecklistNotificationsInput{
		Limit:             10,
		PreferredLanguage: "en",
	})
	if err != nil {
		t.Fatalf("DispatchDueChecklistNotifications returned error: %v", err)
	}
	if result.Scanned != 1 || result.Sent != 0 || result.Skipped != 1 {
		t.Fatalf("unexpected dispatch result: %#v", result)
	}
}

func TestCreateCustomChecklistItemAddsPersonalProgressWithoutChangingSystemReadiness(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)

	checklist := createTestTripChecklist(t, ctx, uc, "user-42", "trip-1")
	systemReadinessScore := checklist.Readiness.Score

	updated, err := uc.CreateCustomChecklistItem(ctx, CreateCustomChecklistItemInput{
		UserID:   "user-42",
		TripID:   "trip-1",
		Title:    " Camera charger ",
		Note:     " USB-C ",
		Category: model.ChecklistCategoryCustom,
		Priority: model.ChecklistPriorityRecommended,
	})
	if err != nil {
		t.Fatalf("CreateCustomChecklistItem returned error: %v", err)
	}
	if updated.Readiness.Score != systemReadinessScore {
		t.Fatalf("system readiness changed from %d to %d", systemReadinessScore, updated.Readiness.Score)
	}
	if len(updated.CustomItems) != 1 {
		t.Fatalf("expected one custom item, got %#v", updated.CustomItems)
	}
	customItem := updated.CustomItems[0]
	if customItem.UserID != "user-42" || customItem.TripID != "trip-1" || customItem.Title != "Camera charger" {
		t.Fatalf("unexpected custom item: %#v", customItem)
	}
	if customItem.Note != "USB-C" || customItem.Status != model.ChecklistItemOpen {
		t.Fatalf("expected trimmed open custom item, got %#v", customItem)
	}
	if updated.PersonalProgress.Total != 1 || updated.PersonalProgress.Done != 0 || updated.PersonalProgress.Percent != 0 {
		t.Fatalf("unexpected personal progress after create: %#v", updated.PersonalProgress)
	}

	done, err := uc.UpdateCustomChecklistItemStatus(ctx, UpdateCustomChecklistItemStatusInput{
		UserID: "user-42",
		TripID: "trip-1",
		ItemID: customItem.ID,
		Status: model.ChecklistItemDone,
	})
	if err != nil {
		t.Fatalf("UpdateCustomChecklistItemStatus returned error: %v", err)
	}
	if done.Readiness.Score != systemReadinessScore {
		t.Fatalf("system readiness changed after custom status update from %d to %d", systemReadinessScore, done.Readiness.Score)
	}
	if done.PersonalProgress.Total != 1 || done.PersonalProgress.Done != 1 || done.PersonalProgress.Percent != 100 {
		t.Fatalf("unexpected personal progress after done: %#v", done.PersonalProgress)
	}
	if len(done.CustomItems) != 1 || done.CustomItems[0].Status != model.ChecklistItemDone {
		t.Fatalf("expected custom item marked done, got %#v", done.CustomItems)
	}
}

func TestUpdateCustomChecklistItemCanToggleReuseTemplate(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)
	createTestTripChecklist(t, ctx, uc, "user-42", "trip-1")

	created, err := uc.CreateCustomChecklistItem(ctx, CreateCustomChecklistItemInput{
		UserID:   "user-42",
		TripID:   "trip-1",
		Title:    "Medication",
		Category: model.ChecklistCategoryHealth,
		Priority: model.ChecklistPriorityImportant,
	})
	if err != nil {
		t.Fatalf("CreateCustomChecklistItem returned error: %v", err)
	}
	itemID := created.CustomItems[0].ID

	withTemplate, err := uc.UpdateCustomChecklistItem(ctx, UpdateCustomChecklistItemInput{
		UserID:        "user-42",
		TripID:        "trip-1",
		ItemID:        itemID,
		Title:         "Medication",
		Note:          "Prescription",
		Category:      model.ChecklistCategoryHealth,
		Priority:      model.ChecklistPriorityImportant,
		ReuseInFuture: true,
	})
	if err != nil {
		t.Fatalf("UpdateCustomChecklistItem returned error: %v", err)
	}
	if len(withTemplate.CustomItems) != 1 {
		t.Fatalf("expected one custom item, got %#v", withTemplate.CustomItems)
	}
	templateID := withTemplate.CustomItems[0].PersonalTemplateID
	if !withTemplate.CustomItems[0].ReuseInFuture || templateID == "" {
		t.Fatalf("expected linked reusable template, got %#v", withTemplate.CustomItems[0])
	}
	templates, err := uc.ListPersonalChecklistTemplates(ctx, ListPersonalChecklistTemplatesInput{
		UserID:     "user-42",
		ActiveOnly: true,
	})
	if err != nil {
		t.Fatalf("ListPersonalChecklistTemplates returned error: %v", err)
	}
	if len(templates) != 1 || templates[0].ID != templateID || templates[0].Title != "Medication" {
		t.Fatalf("expected active medication template, got %#v", templates)
	}

	withoutTemplate, err := uc.UpdateCustomChecklistItem(ctx, UpdateCustomChecklistItemInput{
		UserID:        "user-42",
		TripID:        "trip-1",
		ItemID:        itemID,
		Title:         "Medication",
		Note:          "Prescription",
		Category:      model.ChecklistCategoryHealth,
		Priority:      model.ChecklistPriorityImportant,
		ReuseInFuture: false,
	})
	if err != nil {
		t.Fatalf("UpdateCustomChecklistItem disabling reuse returned error: %v", err)
	}
	if withoutTemplate.CustomItems[0].ReuseInFuture || withoutTemplate.CustomItems[0].PersonalTemplateID != "" {
		t.Fatalf("expected template detached after reuse disabled, got %#v", withoutTemplate.CustomItems[0])
	}
	templates, err = uc.ListPersonalChecklistTemplates(ctx, ListPersonalChecklistTemplatesInput{
		UserID:     "user-42",
		ActiveOnly: true,
	})
	if err != nil {
		t.Fatalf("ListPersonalChecklistTemplates after disable returned error: %v", err)
	}
	if len(templates) != 0 {
		t.Fatalf("expected no active templates after reuse disabled, got %#v", templates)
	}
}

func TestDeleteCustomChecklistItemSoftDeletesAndRecalculatesPersonalProgress(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)
	createTestTripChecklist(t, ctx, uc, "user-42", "trip-1")

	created, err := uc.CreateCustomChecklistItem(ctx, CreateCustomChecklistItemInput{
		UserID:   "user-42",
		TripID:   "trip-1",
		Title:    "Gift",
		Category: model.ChecklistCategoryCustom,
		Priority: model.ChecklistPriorityOptional,
	})
	if err != nil {
		t.Fatalf("CreateCustomChecklistItem returned error: %v", err)
	}

	deleted, err := uc.DeleteCustomChecklistItem(ctx, DeleteCustomChecklistItemInput{
		UserID: "user-42",
		TripID: "trip-1",
		ItemID: created.CustomItems[0].ID,
	})
	if err != nil {
		t.Fatalf("DeleteCustomChecklistItem returned error: %v", err)
	}
	if len(deleted.CustomItems) != 0 {
		t.Fatalf("expected no active custom items after delete, got %#v", deleted.CustomItems)
	}
	if deleted.PersonalProgress.Total != 0 || deleted.PersonalProgress.Done != 0 || deleted.PersonalProgress.Percent != 0 {
		t.Fatalf("unexpected personal progress after delete: %#v", deleted.PersonalProgress)
	}
}

func TestUpdateCustomChecklistItemStatusUsesAuthenticatedOwner(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)
	createTestTripChecklist(t, ctx, uc, "user-42", "trip-1")

	created, err := uc.CreateCustomChecklistItem(ctx, CreateCustomChecklistItemInput{
		UserID:   "user-42",
		TripID:   "trip-1",
		Title:    "Camera charger",
		Category: model.ChecklistCategoryCustom,
		Priority: model.ChecklistPriorityRecommended,
	})
	if err != nil {
		t.Fatalf("CreateCustomChecklistItem returned error: %v", err)
	}
	itemID := created.CustomItems[0].ID

	_, err = uc.UpdateCustomChecklistItemStatus(ctx, UpdateCustomChecklistItemStatusInput{
		UserID: "user-99",
		TripID: "trip-1",
		ItemID: itemID,
		Status: model.ChecklistItemDone,
	})
	if !errors.Is(err, ErrCustomChecklistItemNotFound) {
		t.Fatalf("expected ErrCustomChecklistItemNotFound for another user, got %v", err)
	}

	reloaded, err := uc.GetOrCreateTripChecklist(ctx, GenerateTripChecklistInput{
		UserID:      "user-42",
		TripID:      "trip-1",
		Destination: model.TripDestination{CountryCode: "ID", CityName: "Bali"},
		StartAt:     time.Date(2026, time.January, 12, 10, 0, 0, 0, time.UTC),
		EndAt:       time.Date(2026, time.January, 19, 10, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("GetOrCreateTripChecklist returned error: %v", err)
	}
	if len(reloaded.CustomItems) != 1 || reloaded.CustomItems[0].Status != model.ChecklistItemOpen {
		t.Fatalf("expected original owner item to remain open, got %#v", reloaded.CustomItems)
	}
}

func assertHasItem(t *testing.T, items []model.ChecklistItem, id string, priority model.ChecklistPriority) {
	t.Helper()
	for _, item := range items {
		if item.ID == id {
			if item.Priority != priority {
				t.Fatalf("item %q priority = %q, want %q", id, item.Priority, priority)
			}
			return
		}
	}
	t.Fatalf("expected item %q in checklist; got %#v", id, items)
}

func assertNoItem(t *testing.T, items []model.ChecklistItem, id string) {
	t.Helper()
	for _, item := range items {
		if item.ID == id {
			t.Fatalf("did not expect item %q in checklist; got %#v", id, items)
		}
	}
}

func createTestTripChecklist(
	t *testing.T,
	ctx context.Context,
	uc *ChecklistUseCase,
	userID string,
	tripID string,
) model.TripChecklist {
	t.Helper()

	startAt := time.Date(2026, time.January, 12, 10, 0, 0, 0, time.UTC)
	checklist, err := uc.GetOrCreateTripChecklist(ctx, GenerateTripChecklistInput{
		UserID:      userID,
		TripID:      tripID,
		Destination: model.TripDestination{CountryCode: "ID", CityName: "Bali"},
		StartAt:     startAt,
		EndAt:       startAt.AddDate(0, 0, 7),
		TransportModes: []model.TransportMode{
			model.TransportModeFlight,
		},
		ActivitySlugs: []string{"beach", "hiking"},
		TravelerProfile: model.TravelerProfile{
			HasChildren:       true,
			PreferredLanguage: "en",
		},
	})
	if err != nil {
		t.Fatalf("GetOrCreateTripChecklist returned error: %v", err)
	}
	return checklist
}

func seedTestCatalog() model.CatalogSeed {
	return model.CatalogSeed{
		Templates: []model.ChecklistTemplate{
			{
				ID:                       "documents.passport",
				Category:                 model.ChecklistCategoryDocuments,
				Priority:                 model.ChecklistPriorityCritical,
				Title:                    model.LocalizedText{EN: "Passport / ID", RU: "Паспорт / ID", KK: "Паспорт / ID"},
				Reason:                   model.LocalizedText{EN: "Confirm the document before travel.", RU: "Проверьте документ перед поездкой.", KK: "Сапар алдында құжатты тексеріңіз."},
				TrustLevel:               model.TrustLevelOfficialLinkRequired,
				RequiresUserConfirmation: true,
				AppliesTo:                model.RuleCondition{Always: true},
			},
			{
				ID:                       "documents.child_documents",
				Category:                 model.ChecklistCategoryDocuments,
				Priority:                 model.ChecklistPriorityCritical,
				Title:                    model.LocalizedText{EN: "Child travel documents", RU: "Документы ребенка", KK: "Баланың құжаттары"},
				Reason:                   model.LocalizedText{EN: "Children can need extra documents.", RU: "Для детей могут понадобиться дополнительные документы.", KK: "Балаларға қосымша құжаттар қажет болуы мүмкін."},
				TrustLevel:               model.TrustLevelOfficialLinkRequired,
				RequiresUserConfirmation: true,
				AppliesTo:                model.RuleCondition{TravelerHasChildren: true},
			},
			{
				ID:         "documents.travel_insurance",
				Category:   model.ChecklistCategoryDocuments,
				Priority:   model.ChecklistPriorityEssential,
				Title:      model.LocalizedText{EN: "Travel insurance", RU: "Туристическая страховка", KK: "Саяхат сақтандыруы"},
				Reason:     model.LocalizedText{EN: "Keep policy contacts offline.", RU: "Сохраните контакты полиса офлайн.", KK: "Полис байланыстарын офлайн сақтаңыз."},
				TrustLevel: model.TrustLevelGeneralAdvisory,
				AppliesTo:  model.RuleCondition{InternationalTrip: true},
			},
			{
				ID:         "weather.bali_january_rain_kit",
				Category:   model.ChecklistCategoryWeather,
				Priority:   model.ChecklistPriorityImportant,
				Title:      model.LocalizedText{EN: "Rain kit", RU: "Защита от дождя", KK: "Жаңбырдан қорғаныс"},
				Reason:     model.LocalizedText{EN: "January is rainy and humid in Bali.", RU: "В январе на Бали дождливо и влажно.", KK: "Қаңтарда Балиде жаңбырлы әрі ылғалды."},
				TrustLevel: model.TrustLevelVerifiedCurated,
				AppliesTo:  model.RuleCondition{CountryCode: "ID", CityName: "Bali", Month: time.January},
			},
			{
				ID:         "activity.hiking_daypack",
				Category:   model.ChecklistCategoryActivity,
				Priority:   model.ChecklistPriorityEssential,
				Title:      model.LocalizedText{EN: "Hiking daypack", RU: "Рюкзак для хайкинга", KK: "Жаяу серуен рюкзагы"},
				Reason:     model.LocalizedText{EN: "Keep water, layers, and first aid together.", RU: "Вода, слои одежды и аптечка должны быть под рукой.", KK: "Су, киім қабаттары және дәрі қобдишасы бірге болсын."},
				TrustLevel: model.TrustLevelGeneralAdvisory,
				AppliesTo:  model.RuleCondition{ActivitySlug: "hiking"},
			},
			{
				ID:         "baggage.power_bank_carry_on",
				Category:   model.ChecklistCategoryBaggage,
				Priority:   model.ChecklistPriorityRecommended,
				Title:      model.LocalizedText{EN: "Power bank in carry-on", RU: "Power bank в ручную кладь", KK: "Power bank қол жүгінде"},
				Reason:     model.LocalizedText{EN: "Spare lithium batteries and power banks belong in carry-on baggage.", RU: "Запасные литиевые батареи и power bank перевозятся в ручной клади.", KK: "Қосымша литий батареялары мен power bank қол жүгінде болуы керек."},
				TrustLevel: model.TrustLevelVerifiedCurated,
				Source: model.Source{
					Name:       "FAA PackSafe",
					URL:        "https://www.faa.gov/hazmat/packsafe/lithium-batteries",
					Type:       model.SourceTypeOfficialAuthority,
					Confidence: model.SourceConfidenceHigh,
				},
				AppliesTo: model.RuleCondition{TransportMode: model.TransportModeFlight},
			},
		},
		SeasonalProfiles: []model.SeasonalProfile{
			{
				Destination:       model.TripDestination{CountryCode: "ID", CityName: "Bali"},
				Month:             time.January,
				TemperatureBand:   model.TemperatureHot,
				PrecipitationBand: model.PrecipitationRainy,
				SkyBand:           model.SkyMixed,
				RiskTags:          []string{"humid", "high_uv"},
				PackingImplications: []model.LocalizedText{
					{EN: "Light breathable clothes", RU: "Легкая дышащая одежда", KK: "Жеңіл демалатын киім"},
					{EN: "Compact rain protection", RU: "Компактная защита от дождя", KK: "Ықшам жаңбыр қорғанысы"},
				},
				Source: model.Source{
					Name:       "Curated climate profile",
					URL:        "https://climateknowledgeportal.worldbank.org/download-data",
					Type:       model.SourceTypeOpenData,
					Confidence: model.SourceConfidenceMedium,
				},
			},
		},
		CarryRules: []model.CarryRule{
			{
				ItemSlug:             "power_bank",
				Aliases:              []string{"power bank", "portable charger", "battery pack", "повербанк"},
				TransportMode:        model.TransportModeFlight,
				CarryOn:              model.CarryPolicyAllowedWithConditions,
				CheckedBaggage:       model.CarryPolicyProhibited,
				RequiresAirlineCheck: true,
				ConditionSummary:     model.LocalizedText{EN: "Carry-on only. Check airline capacity limits.", RU: "Только ручная кладь. Проверьте лимиты емкости у авиакомпании.", KK: "Тек қол жүгінде. Сыйымдылық лимитін әуе компаниясынан тексеріңіз."},
				Source: model.Source{
					Name:       "FAA PackSafe",
					URL:        "https://www.faa.gov/hazmat/packsafe/lithium-batteries",
					Type:       model.SourceTypeOfficialAuthority,
					Confidence: model.SourceConfidenceHigh,
				},
			},
			{
				ItemSlug:       "travel_visa",
				Aliases:        []string{"visa", "entry visa", "travel visa", "виза"},
				TransportMode:  model.TransportModeFlight,
				CarryOn:        model.CarryPolicyAllowed,
				CheckedBaggage: model.CarryPolicyCheckAuthority,
				ConditionSummary: model.LocalizedText{
					EN: "Keep travel documents in carry-on and confirm entry requirements.",
					RU: "Документы держите в ручной клади и проверьте требования въезда.",
					KK: "Құжаттарды қол жүгінде ұстаңыз және кіру талаптарын тексеріңіз.",
				},
				Source: model.Source{
					Name:       "Official entry self-check",
					URL:        "https://www.iatatravelcentre.com/",
					Type:       model.SourceTypeOfficialAuthority,
					Confidence: model.SourceConfidenceMedium,
				},
			},
		},
	}
}
