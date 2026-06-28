package repository

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
	"unicode"
)

// The visit_info v2 contract changes openingHours from a string to an object.
// The migration must convert every existing string value so reads keep working.
func TestVisitInfoV2MigrationConvertsOpeningHours(t *testing.T) {
	up := readMigration(t, "144_visit_info_v2.up.sql")

	if !strings.Contains(up, "jsonb_typeof(visit_info -> 'openingHours') = 'string'") {
		t.Fatalf("up migration must target only string openingHours values")
	}
	if !strings.Contains(up, "'{openingHours}'") || !strings.Contains(up, "jsonb_set(") {
		t.Fatalf("up migration must rewrite the openingHours key")
	}
	if !strings.Contains(up, "'summary'") || !strings.Contains(up, "jsonb_build_object") {
		t.Fatalf("up migration must build an openingHours object with a summary")
	}

	down := readMigration(t, "144_visit_info_v2.down.sql")
	if !strings.Contains(down, `"CHECK_CURRENT"`) {
		t.Fatalf("down migration must restore the legacy CHECK_CURRENT sentinel")
	}
}

func TestVisitPlanningTablesMigrationContract(t *testing.T) {
	up := readMigration(t, "146_place_visit_planning_tables.up.sql")

	for _, table := range []string{
		"place_visit_info",
		"place_fee_items",
		"place_access_options",
		"place_practical_notes",
		"place_recommended_items",
	} {
		if !strings.Contains(up, "CREATE TABLE IF NOT EXISTS "+table) {
			t.Fatalf("up migration must create %s", table)
		}
		if !strings.Contains(up, "REFERENCES places(id) ON DELETE CASCADE") {
			t.Fatalf("up migration must cascade-delete rows tied to places")
		}
	}
	for _, fragment := range []string{
		"fee_type",
		"amount_min",
		"amount_max",
		"is_required",
		"transport_type",
		"requires_4x4",
		"note_type",
		"importance",
		"last_verified_at",
		"sort_order",
	} {
		if !strings.Contains(up, fragment) {
			t.Fatalf("up migration missing %s", fragment)
		}
	}

	down := readMigration(t, "146_place_visit_planning_tables.down.sql")
	for _, table := range []string{
		"place_recommended_items",
		"place_practical_notes",
		"place_access_options",
		"place_fee_items",
		"place_visit_info",
	} {
		if !strings.Contains(down, "DROP TABLE IF EXISTS "+table) {
			t.Fatalf("down migration must drop %s", table)
		}
	}
}

func TestPlaceVisitReferenceValuesMigrationContract(t *testing.T) {
	up := readMigration(t, "213_place_visit_reference_values.up.sql")

	for _, fragment := range []string{
		"CREATE TABLE IF NOT EXISTS place_visit_reference_values",
		"CREATE TABLE IF NOT EXISTS place_visit_reference_translations",
		"PRIMARY KEY (category, code)",
		"REFERENCES place_visit_reference_values(category, code) ON DELETE CASCADE",
		"place_visit_reference_values_active_idx",
		"'fee_type'",
		"'fee_unit'",
		"'road_condition'",
		"'transport_type'",
		"'best_time'",
		"'practical_note_type'",
		"'practical_note_priority'",
		"'recommended_item_type'",
		"'recommended_item_importance'",
		"'season'",
		"'ENTRANCE'",
		"'PERSON'",
		"'PAVED'",
		"'CAR'",
		"'MORNING'",
		"'REQUIRED'",
		"'WATER'",
		"'SUMMER'",
		"'ru'",
		"'en'",
		"'kk'",
	} {
		if !strings.Contains(up, fragment) {
			t.Fatalf("213 visit reference migration must contain %q", fragment)
		}
	}

	down := readMigration(t, "213_place_visit_reference_values.down.sql")
	for _, table := range []string{
		"place_visit_reference_translations",
		"place_visit_reference_values",
	} {
		if !strings.Contains(down, "DROP TABLE IF EXISTS "+table) {
			t.Fatalf("213 rollback must drop %s", table)
		}
	}
}

func TestKazakhstanVisitPlanningSeedMigrationUsesWorkbookDataWithoutSources(t *testing.T) {
	up := readMigration(t, "147_seed_kazakhstan_visit_planning_from_workbook.up.sql")

	for _, fragment := range []string{
		"seed_kazakhstan_visit_planning",
		"place_translations",
		"pt.title = seed.title_ru",
		"p.country_code = 'KZ'",
		"'feeItems'",
		"'accessOptions'",
		"'practicalNotes'",
		"'recommendedItems'",
		"'priceNote'",
		"Чарынский каньон",
		"Большое Алматинское озеро",
		"Горный курорт Шымбулак",
		"Вода",
		"Powerbank",
		"Наличные",
	} {
		if !strings.Contains(up, fragment) {
			t.Fatalf("147 Kazakhstan visit planning migration must contain %q", fragment)
		}
	}
	for _, forbidden := range []string{
		"http://",
		"https://",
		"Источник / обоснование",
		"source",
		"sourceUrl",
	} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("147 Kazakhstan visit planning migration must not persist source fragment %q", forbidden)
		}
	}

	down := readMigration(t, "147_seed_kazakhstan_visit_planning_from_workbook.down.sql")
	if !strings.Contains(down, "seed_kazakhstan_visit_planning_rollback") {
		t.Fatalf("147 rollback must use an explicit matched-title rollback table")
	}
}

func TestKazakhstanVisitPlanningSeedMigrationRequiresThreeLocaleLocalizedText(t *testing.T) {
	up := readMigration(t, "147_seed_kazakhstan_visit_planning_from_workbook.up.sql")
	jsonLiterals := regexp.MustCompile(`'(\{[^\n]+\})'::jsonb`).FindAllStringSubmatch(up, -1)
	if len(jsonLiterals) == 0 {
		t.Fatal("147 Kazakhstan visit planning migration must contain JSONB visit_info literals")
	}

	for i, match := range jsonLiterals {
		rawJSON := strings.ReplaceAll(match[1], "''", "'")
		if !strings.HasPrefix(rawJSON, `{"`) && rawJSON != "{}" {
			continue
		}

		var payload map[string]any
		if err := json.Unmarshal([]byte(rawJSON), &payload); err != nil {
			t.Fatalf("visit_info JSON literal %d is invalid: %v", i+1, err)
		}
		if missing := missingLocalizedTextLocales(payload, fmt.Sprintf("visit_info[%d]", i+1)); len(missing) > 0 {
			t.Fatalf("147 Kazakhstan visit planning migration contains incomplete or mixed localized text: %s", strings.Join(missing[:min(len(missing), 12)], "; "))
		}
	}
}

func TestNonKazakhstanVisitPlanningPlaceholderMigrationContract(t *testing.T) {
	up := readMigration(t, "148_seed_non_kazakhstan_visit_planning_placeholders.up.sql")

	for _, fragment := range []string{
		"p.country_code <> 'KZ'",
		"'practicalNotes'",
		"'recommendedItems'",
		"'priceNote'",
		"'TEMPORARY_PLACEHOLDER'",
		"Проверьте актуальные часы, цену и правила посещения перед поездкой",
	} {
		if !strings.Contains(up, fragment) {
			t.Fatalf("148 placeholder migration must contain %q", fragment)
		}
	}
	for _, forbidden := range []string{"http://", "https://", "sourceUrl"} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("148 placeholder migration must not persist source fragment %q", forbidden)
		}
	}

	down := readMigration(t, "148_seed_non_kazakhstan_visit_planning_placeholders.down.sql")
	if !strings.Contains(down, "TEMPORARY_PLACEHOLDER") {
		t.Fatalf("148 rollback must remove only temporary placeholder data")
	}
}

func TestTalgarPeakVisitPlanningLocalePatchMigrationContract(t *testing.T) {
	up := readMigration(t, "149_patch_talgar_peak_visit_planning_locales.up.sql")

	for _, fragment := range []string{
		"talgar-peak-base-trail",
		"UPDATE places p",
		"visit_info = jsonb_strip_nulls",
		"place_visit_info",
		"place_fee_items",
		"place_access_options",
		"place_practical_notes",
		"place_recommended_items",
		"6-10+ h on foot; full day",
		"30-90 min to trailhead",
		"Бастау нүктесіне дейін 30-90 мин",
	} {
		if !strings.Contains(up, fragment) {
			t.Fatalf("149 Talgar Peak locale patch migration must contain %q", fragment)
		}
	}
	if strings.Contains(up, "6–10+ ч пешком") && !strings.Contains(up, `"en"`) {
		t.Fatalf("149 Talgar Peak locale patch must not write Russian-only visit planning text")
	}
	if strings.Contains(up, "ON COMMIT DROP") {
		t.Fatalf("149 Talgar Peak locale patch must not use ON COMMIT DROP because psql -f runs migration statements in autocommit mode")
	}
	if !strings.Contains(up, "DROP TABLE seed_talgar_peak_visit_planning") {
		t.Fatalf("149 Talgar Peak locale patch must explicitly drop the temporary seed table after all statements")
	}
	jsonLiterals := regexp.MustCompile(`(?s)\$\$(\{.*?\})\$\$::jsonb`).FindAllStringSubmatch(up, -1)
	if len(jsonLiterals) != 1 {
		t.Fatalf("149 Talgar Peak locale patch must contain exactly one dollar-quoted JSONB payload, got %d", len(jsonLiterals))
	}
	var payload map[string]any
	if err := json.Unmarshal([]byte(jsonLiterals[0][1]), &payload); err != nil {
		t.Fatalf("149 Talgar Peak visit_info JSON is invalid: %v", err)
	}
	if missing := missingLocalizedTextLocales(payload, "talgar_peak.visit_info"); len(missing) > 0 {
		t.Fatalf("149 Talgar Peak locale patch contains incomplete or mixed localized text: %s", strings.Join(missing, "; "))
	}

	down := readMigration(t, "149_patch_talgar_peak_visit_planning_locales.down.sql")
	if !strings.Contains(down, "Intentionally left irreversible") {
		t.Fatalf("149 rollback must explicitly document why localized data patch is not reverted")
	}
}

func TestRussiaVisitPlanningSeedMigrationUsesWorkbookDataWithoutSources(t *testing.T) {
	up := readMigration(t, "150_seed_russia_visit_planning_from_workbook.up.sql")

	for _, fragment := range []string{
		"seed_russia_visit_planning",
		"place_translations",
		"pt.title = seed.title_ru",
		"p.country_code = 'RU'",
		"'feeItems'",
		"'accessOptions'",
		"'practicalNotes'",
		"'recommendedItems'",
		"'priceNote'",
		"Красная площадь",
		"Мамаев курган",
		"Дудергофские высоты",
		"Экотропа Лосиного Острова",
		"Лесная петля Голубых озер",
		"Тропа Орлиные скалы и Мацеста",
		"Power bank",
		"Қолма-қол ақша",
	} {
		if !strings.Contains(up, fragment) {
			t.Fatalf("150 Russia visit planning migration must contain %q", fragment)
		}
	}
	for _, forbidden := range []string{
		"http://",
		"https://",
		"Источник",
		"source",
		"sourceUrl",
		"ON COMMIT DROP",
	} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("150 Russia visit planning migration must not contain forbidden fragment %q", forbidden)
		}
	}
	if !strings.Contains(up, "DROP TABLE seed_russia_visit_planning") {
		t.Fatalf("150 Russia visit planning migration must explicitly drop the temporary seed table after all statements")
	}

	down := readMigration(t, "150_seed_russia_visit_planning_from_workbook.down.sql")
	if !strings.Contains(down, "Intentionally left irreversible") {
		t.Fatalf("150 rollback must explicitly document why the country-specific visit planning overlay is not reverted")
	}
}

func TestRussiaVisitPlanningSeedMigrationRequiresValidLocalizedJSON(t *testing.T) {
	up := readMigration(t, "150_seed_russia_visit_planning_from_workbook.up.sql")
	jsonLiterals := regexp.MustCompile(`(?s)\$\$(\{.*?\})\$\$::jsonb`).FindAllStringSubmatch(up, -1)
	if len(jsonLiterals) != 27 {
		t.Fatalf("150 Russia visit planning migration must contain 27 dollar-quoted JSONB payloads, got %d", len(jsonLiterals))
	}

	for i, match := range jsonLiterals {
		var payload map[string]any
		if err := json.Unmarshal([]byte(match[1]), &payload); err != nil {
			t.Fatalf("Russia visit_info JSON literal %d is invalid: %v", i+1, err)
		}
		if missing := missingLocalizedTextLocales(payload, fmt.Sprintf("russia.visit_info[%d]", i+1)); len(missing) > 0 {
			t.Fatalf("150 Russia visit planning migration contains incomplete or mixed localized text: %s", strings.Join(missing[:min(len(missing), 12)], "; "))
		}
	}
}

func TestDenmarkVisitPlanningSeedMigrationUsesWorkbookDataWithoutSources(t *testing.T) {
	up := readMigration(t, "151_seed_denmark_visit_planning_from_workbook.up.sql")

	for _, fragment := range []string{
		"seed_denmark_visit_planning",
		"place_translations",
		"pt.title = seed.title_ru",
		"p.country_code = 'DK'",
		"'feeItems'",
		"'accessOptions'",
		"'practicalNotes'",
		"'recommendedItems'",
		"'priceNote'",
		"Сады Тиволи",
		"Пляжный парк Амагер",
		"TorvehallerneKBH",
		"LEGOLAND Billund Resort",
		"Мёнс-Клинт",
		"GeoCenter Møns Klint",
		"Замок Кронборг",
		"Роскилльский собор",
		"Power bank",
		"Қолма-қол ақша",
	} {
		if !strings.Contains(up, fragment) {
			t.Fatalf("151 Denmark visit planning migration must contain %q", fragment)
		}
	}
	for _, forbidden := range []string{
		"http://",
		"https://",
		"Источник",
		"source",
		"sourceUrl",
		"ON COMMIT DROP",
	} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("151 Denmark visit planning migration must not contain forbidden fragment %q", forbidden)
		}
	}
	if !strings.Contains(up, "DROP TABLE seed_denmark_visit_planning") {
		t.Fatalf("151 Denmark visit planning migration must explicitly drop the temporary seed table after all statements")
	}

	down := readMigration(t, "151_seed_denmark_visit_planning_from_workbook.down.sql")
	if !strings.Contains(down, "Intentionally left irreversible") {
		t.Fatalf("151 rollback must explicitly document why the country-specific visit planning overlay is not reverted")
	}
}

func TestDenmarkVisitPlanningSeedMigrationRequiresValidLocalizedJSON(t *testing.T) {
	up := readMigration(t, "151_seed_denmark_visit_planning_from_workbook.up.sql")
	jsonLiterals := regexp.MustCompile(`(?s)\$\$(\{.*?\})\$\$::jsonb`).FindAllStringSubmatch(up, -1)
	if len(jsonLiterals) != 93 {
		t.Fatalf("151 Denmark visit planning migration must contain 93 dollar-quoted JSONB payloads, got %d", len(jsonLiterals))
	}

	for i, match := range jsonLiterals {
		var payload map[string]any
		if err := json.Unmarshal([]byte(match[1]), &payload); err != nil {
			t.Fatalf("Denmark visit_info JSON literal %d is invalid: %v", i+1, err)
		}
		if missing := missingLocalizedTextLocales(payload, fmt.Sprintf("denmark.visit_info[%d]", i+1)); len(missing) > 0 {
			t.Fatalf("151 Denmark visit planning migration contains incomplete or mixed localized text: %s", strings.Join(missing[:min(len(missing), 12)], "; "))
		}
	}
}

func TestSingaporeVisitPlanningSeedMigrationUsesWorkbookDataWithoutSources(t *testing.T) {
	up := readMigration(t, "152_seed_singapore_visit_planning_from_workbook.up.sql")

	for _, fragment := range []string{
		"seed_singapore_visit_planning",
		"place_translations",
		"pt.title = seed.title_ru",
		"p.country_code = 'SG'",
		"'feeItems'",
		"'accessOptions'",
		"'practicalNotes'",
		"'recommendedItems'",
		"'priceNote'",
		"Сады у залива",
		"Пулау-Убин",
		"Облачный лес",
		"Universal Studios Singapore",
		"Сингапурский зоопарк",
		"Changi Experience Studio",
		"Парк Ист-Кост",
		"Прогулка Southern Ridges",
		"Power bank",
		"Қолма-қол ақша",
	} {
		if !strings.Contains(up, fragment) {
			t.Fatalf("152 Singapore visit planning migration must contain %q", fragment)
		}
	}
	for _, forbidden := range []string{
		"http://",
		"https://",
		"Источник",
		"source",
		"sourceUrl",
		"ON COMMIT DROP",
	} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("152 Singapore visit planning migration must not contain forbidden fragment %q", forbidden)
		}
	}
	if !strings.Contains(up, "DROP TABLE seed_singapore_visit_planning") {
		t.Fatalf("152 Singapore visit planning migration must explicitly drop the temporary seed table after all statements")
	}

	down := readMigration(t, "152_seed_singapore_visit_planning_from_workbook.down.sql")
	if !strings.Contains(down, "Intentionally left irreversible") {
		t.Fatalf("152 rollback must explicitly document why the country-specific visit planning overlay is not reverted")
	}
}

func TestSingaporeVisitPlanningSeedMigrationRequiresValidLocalizedJSON(t *testing.T) {
	up := readMigration(t, "152_seed_singapore_visit_planning_from_workbook.up.sql")
	jsonLiterals := regexp.MustCompile(`(?s)\$\$(\{.*?\})\$\$::jsonb`).FindAllStringSubmatch(up, -1)
	if len(jsonLiterals) != 79 {
		t.Fatalf("152 Singapore visit planning migration must contain 79 dollar-quoted JSONB payloads, got %d", len(jsonLiterals))
	}

	for i, match := range jsonLiterals {
		var payload map[string]any
		if err := json.Unmarshal([]byte(match[1]), &payload); err != nil {
			t.Fatalf("Singapore visit_info JSON literal %d is invalid: %v", i+1, err)
		}
		if missing := missingLocalizedTextLocales(payload, fmt.Sprintf("singapore.visit_info[%d]", i+1)); len(missing) > 0 {
			t.Fatalf("152 Singapore visit planning migration contains incomplete or mixed localized text: %s", strings.Join(missing[:min(len(missing), 12)], "; "))
		}
	}
}

func TestUnitedStatesVisitPlanningSeedMigrationUsesWorkbookDataWithoutSources(t *testing.T) {
	up := readMigration(t, "153_seed_united_states_visit_planning_from_workbook.up.sql")

	for _, fragment := range []string{
		"seed_united_states_visit_planning",
		"place_translations",
		"pt.title = seed.title_ru",
		"p.country_code = 'US'",
		"'feeItems'",
		"'accessOptions'",
		"'practicalNotes'",
		"'recommendedItems'",
		"'priceNote'",
		"Chelsea Market",
		"Статуя Свободы и остров Эллис",
		"Пирс и пляж Санта-Моники",
		"Государственный парк Waianapanapa",
		"Тропа Powerline Pass",
		"Остров Алькатрас",
		"Universal Studios Hollywood",
		"Аквариум Ниагары",
		"Power bank",
		"Қолма-қол ақша",
	} {
		if !strings.Contains(up, fragment) {
			t.Fatalf("153 United States visit planning migration must contain %q", fragment)
		}
	}
	for _, forbidden := range []string{
		"http://",
		"https://",
		"Источник",
		"source",
		"sourceUrl",
		"ON COMMIT DROP",
	} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("153 United States visit planning migration must not contain forbidden fragment %q", forbidden)
		}
	}
	if !strings.Contains(up, "DROP TABLE seed_united_states_visit_planning") {
		t.Fatalf("153 United States visit planning migration must explicitly drop the temporary seed table after all statements")
	}

	down := readMigration(t, "153_seed_united_states_visit_planning_from_workbook.down.sql")
	if !strings.Contains(down, "Intentionally left irreversible") {
		t.Fatalf("153 rollback must explicitly document why the country-specific visit planning overlay is not reverted")
	}
}

func TestUnitedStatesVisitPlanningSeedMigrationRequiresValidLocalizedJSON(t *testing.T) {
	up := readMigration(t, "153_seed_united_states_visit_planning_from_workbook.up.sql")
	jsonLiterals := regexp.MustCompile(`(?s)\$\$(\{.*?\})\$\$::jsonb`).FindAllStringSubmatch(up, -1)
	if len(jsonLiterals) != 168 {
		t.Fatalf("153 United States visit planning migration must contain 168 dollar-quoted JSONB payloads, got %d", len(jsonLiterals))
	}

	for i, match := range jsonLiterals {
		var payload map[string]any
		if err := json.Unmarshal([]byte(match[1]), &payload); err != nil {
			t.Fatalf("United States visit_info JSON literal %d is invalid: %v", i+1, err)
		}
		if missing := missingLocalizedTextLocales(payload, fmt.Sprintf("united_states.visit_info[%d]", i+1)); len(missing) > 0 {
			t.Fatalf("153 United States visit planning migration contains incomplete or mixed localized text: %s", strings.Join(missing[:min(len(missing), 12)], "; "))
		}
	}
}

func TestWorkbookVisitPlanningSeedMigrationsContract(t *testing.T) {
	specs := readWorkbookVisitPlanningMigrationSpecs(t)
	if len(specs) != 59 {
		t.Fatalf("expected 59 workbook visit-planning migrations, got %d", len(specs))
	}

	totalPayloads := 0
	totalWorkbookRows := 0
	for _, spec := range specs {
		totalPayloads += spec.JSONPayloadCount
		totalWorkbookRows += spec.WorkbookRowCount
		spec := spec
		t.Run(spec.CountryCode+"_"+spec.CountryName, func(t *testing.T) {
			up := readMigration(t, spec.Migration)

			for _, fragment := range []string{
				"CREATE TEMP TABLE " + spec.TempTable,
				"place_translations",
				"pt.title = seed.title_ru",
				"p.country_code = '" + spec.CountryCode + "'",
				"p.source = 'IMPORT'",
				"'feeItems'",
				"'accessOptions'",
				"'practicalNotes'",
				"'recommendedItems'",
				"'priceNote'",
			} {
				if !strings.Contains(up, fragment) {
					t.Fatalf("%s must contain %q", spec.Migration, fragment)
				}
			}
			expectedMatchGuard := "missing or ambiguous place matches"
			if spec.CountryCode == "ID" {
				expectedMatchGuard = "missing place matches"
				if !strings.Contains(up, "legacy exact-title duplicates") || !strings.Contains(up, "WHERE match_count = 0") {
					t.Fatalf("%s must document and guard the Indonesia duplicate-title matching policy", spec.Migration)
				}
			}
			if !strings.Contains(up, expectedMatchGuard) {
				t.Fatalf("%s must contain %q", spec.Migration, expectedMatchGuard)
			}
			for _, title := range spec.ExpectedTitles {
				if !strings.Contains(up, title) {
					t.Fatalf("%s must contain expected workbook title %q", spec.Migration, title)
				}
			}
			for _, forbidden := range []string{
				"http://",
				"https://",
				"sourceUrl",
				"Источник / обоснование",
				"ON COMMIT DROP",
			} {
				if strings.Contains(up, forbidden) {
					t.Fatalf("%s must not contain forbidden workbook/source fragment %q", spec.Migration, forbidden)
				}
			}
			if !strings.Contains(up, "DROP TABLE "+spec.TempTable) {
				t.Fatalf("%s must explicitly drop the temporary seed table", spec.Migration)
			}

			jsonLiterals := regexp.MustCompile(`(?s)\$\$(\{.*?\})\$\$::jsonb`).FindAllStringSubmatch(up, -1)
			if len(jsonLiterals) != spec.JSONPayloadCount {
				t.Fatalf("%s must contain %d dollar-quoted JSONB payloads, got %d", spec.Migration, spec.JSONPayloadCount, len(jsonLiterals))
			}

			for i, match := range jsonLiterals {
				var payload map[string]any
				if err := json.Unmarshal([]byte(match[1]), &payload); err != nil {
					t.Fatalf("%s visit_info JSON literal %d is invalid: %v", spec.Migration, i+1, err)
				}
				if missing := missingLocalizedTextLocales(payload, fmt.Sprintf("%s.visit_info[%d]", spec.CountryCode, i+1)); len(missing) > 0 {
					t.Fatalf("%s contains incomplete or mixed localized text: %s", spec.Migration, strings.Join(missing[:min(len(missing), 12)], "; "))
				}
				if fallback := russianFallbackKazakhText(payload, fmt.Sprintf("%s.visit_info[%d]", spec.CountryCode, i+1)); len(fallback) > 0 {
					t.Fatalf("%s contains Russian fallback in Kazakh text: %s", spec.Migration, strings.Join(fallback[:min(len(fallback), 12)], "; "))
				}
			}

			down := readMigration(t, spec.DownMigration)
			if !strings.Contains(down, "Intentionally left irreversible") {
				t.Fatalf("%s rollback must explicitly document why the country-specific visit planning overlay is not reverted", spec.DownMigration)
			}
		})
	}

	if totalWorkbookRows != 6013 {
		t.Fatalf("expected 6013 workbook attraction rows, got %d", totalWorkbookRows)
	}
	if totalPayloads != 6009 {
		t.Fatalf("expected 6009 unique workbook visit-planning payloads after duplicate-title collapse, got %d", totalPayloads)
	}
}

type workbookVisitPlanningMigrationSpec struct {
	Migration                string   `json:"migration"`
	DownMigration            string   `json:"downMigration"`
	CountryCode              string   `json:"countryCode"`
	CountryName              string   `json:"countryName"`
	TempTable                string   `json:"tempTable"`
	JSONPayloadCount         int      `json:"jsonPayloadCount"`
	WorkbookRowCount         int      `json:"workbookRowCount"`
	ExpectedTitles           []string `json:"expectedTitles"`
	DuplicateTitlesCollapsed []string `json:"duplicateTitlesCollapsed"`
}

func readWorkbookVisitPlanningMigrationSpecs(t *testing.T) []workbookVisitPlanningMigrationSpec {
	t.Helper()

	content, err := os.ReadFile(filepath.Join("testdata", "visit_planning_workbook_migrations.json"))
	if err != nil {
		t.Fatalf("read workbook visit planning migration specs: %v", err)
	}
	var specs []workbookVisitPlanningMigrationSpec
	if err := json.Unmarshal(content, &specs); err != nil {
		t.Fatalf("parse workbook visit planning migration specs: %v", err)
	}
	return specs
}

func russianFallbackKazakhText(value any, path string) []string {
	switch typed := value.(type) {
	case map[string]any:
		if ru, ok := typed["ru"].(string); ok {
			if kk, ok := typed["kk"].(string); ok && strings.TrimSpace(ru) != "" && strings.TrimSpace(ru) == strings.TrimSpace(kk) {
				return []string{fmt.Sprintf("%s has Russian fallback Kazakh text", path)}
			}
		}

		var result []string
		for key, child := range typed {
			result = append(result, russianFallbackKazakhText(child, path+"."+key)...)
		}
		return result
	case []any:
		var result []string
		for index, child := range typed {
			result = append(result, russianFallbackKazakhText(child, fmt.Sprintf("%s[%d]", path, index))...)
		}
		return result
	default:
		return nil
	}
}

func missingLocalizedTextLocales(value any, path string) []string {
	switch typed := value.(type) {
	case map[string]any:
		if _, ok := typed["ru"]; ok {
			missing := make([]string, 0, 3)
			for _, locale := range []string{"ru", "en", "kk"} {
				if !hasNonBlankLocalizedValue(typed[locale]) {
					missing = append(missing, locale)
				}
			}
			if len(missing) > 0 {
				return []string{fmt.Sprintf("%s missing %s", path, strings.Join(missing, ","))}
			}
			if hasCyrillicText(typed["en"]) {
				return []string{fmt.Sprintf("%s has Cyrillic English text", path)}
			}
			if hasUntranslatedKazakhText(typed["kk"]) {
				return []string{fmt.Sprintf("%s has untranslated Kazakh text", path)}
			}
		}

		var result []string
		for key, child := range typed {
			result = append(result, missingLocalizedTextLocales(child, path+"."+key)...)
		}
		return result
	case []any:
		var result []string
		for index, child := range typed {
			result = append(result, missingLocalizedTextLocales(child, fmt.Sprintf("%s[%d]", path, index))...)
		}
		return result
	default:
		return nil
	}
}

func hasNonBlankLocalizedValue(value any) bool {
	text, ok := value.(string)
	return ok && strings.TrimSpace(text) != ""
}

func hasCyrillicText(value any) bool {
	text, ok := value.(string)
	if !ok {
		return false
	}
	return regexp.MustCompile(`[А-Яа-яЁёӘәҒғҚқҢңӨөҰұҮүҺһІі]`).MatchString(text)
}

func hasUntranslatedKazakhText(value any) bool {
	text, ok := value.(string)
	if !ok {
		return false
	}

	lower := strings.ToLower(text)
	for _, fragment := range []string{
		"обысағ",
		"фактисағ",
		"историсағ",
		"круглосутосағ",
		"лусағше",
		"опласағ",
		"тосағки",
	} {
		if strings.Contains(lower, fragment) {
			return true
		}
	}

	untranslatedTokens := map[string]struct{}{
		"аттракционы":   {},
		"вещи":          {},
		"вокруг":        {},
		"возможны":      {},
		"горных":        {},
		"графикам":      {},
		"день":          {},
		"для":           {},
		"до":            {},
		"доступу":       {},
		"жара":          {},
		"закрыт":        {},
		"заявке":        {},
		"зоны":          {},
		"из":            {},
		"канатка":       {},
		"летом":         {},
		"маршрутам":     {},
		"нижней":        {},
		"нужен":         {},
		"общественные":  {},
		"обычно":        {},
		"опыт":          {},
		"от":            {},
		"отдельно":      {},
		"павильоны":     {},
		"пересадкой":    {},
		"по":            {},
		"погоде":        {},
		"разрешению":    {},
		"реконструкцию": {},
		"сағасть":       {},
		"световой":      {},
		"сезону":        {},
		"своим":         {},
		"станции":       {},
		"территория":    {},
		"только":        {},
		"экстремальная": {},
	}

	for _, token := range strings.FieldsFunc(lower, func(r rune) bool {
		return !unicode.IsLetter(r)
	}) {
		if _, ok := untranslatedTokens[token]; ok {
			return true
		}
	}
	return false
}
