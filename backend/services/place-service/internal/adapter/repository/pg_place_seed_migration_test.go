package repository

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestPlaceSeedMigrationsDoNotWriteObsoleteTranslationHighlightsColumn(t *testing.T) {
	entries, err := os.ReadDir(filepath.Join("..", "..", "..", "migrations"))
	if err != nil {
		t.Fatalf("read migrations directory: %v", err)
	}

	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || !strings.HasSuffix(name, ".up.sql") {
			continue
		}

		upSQL := readMigration(t, name)
		if strings.Contains(upSQL, "highlights") {
			t.Fatalf("%s must not write obsolete place_translations.highlights column", name)
		}
	}
}

func TestPlaceSeedMigrationsPopulateRequiredAuthorUserID(t *testing.T) {
	entries, err := os.ReadDir(filepath.Join("..", "..", "..", "migrations"))
	if err != nil {
		t.Fatalf("read migrations directory: %v", err)
	}

	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || !strings.HasSuffix(name, ".up.sql") {
			continue
		}

		upSQL := readMigration(t, name)
		if strings.Contains(upSQL, "INSERT INTO places (") && !strings.Contains(upSQL, "author_user_id") {
			t.Fatalf("%s must populate required places.author_user_id column", name)
		}
	}
}

func TestPlaceSeedMigrationsPopulateEntryPriceFloors(t *testing.T) {
	entries, err := os.ReadDir(filepath.Join("..", "..", "..", "migrations"))
	if err != nil {
		t.Fatalf("read migrations directory: %v", err)
	}

	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() ||
			!strings.HasSuffix(name, "_places.up.sql") ||
			!strings.Contains(name, "_seed_") {
			continue
		}

		upSQL := readMigration(t, name)
		if !strings.Contains(upSQL, "INSERT INTO places (") {
			continue
		}
		if !strings.Contains(upSQL, "price_amount") {
			t.Fatalf("%s must populate places.price_amount for imported entry-price floors", name)
		}
		if strings.Contains(upSQL, "NULL::numeric") || strings.Contains(upSQL, "NULL::varchar(3)") {
			t.Fatalf("%s must not seed unknown place prices for imported places", name)
		}
		if strings.Contains(upSQL, "ON CONFLICT (id) DO UPDATE") &&
			!strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
			t.Fatalf("%s must update places.price_amount on seed conflict", name)
		}
	}
}

func TestPlaceSeedMigrationsUseCurrentCityLinkKindColumn(t *testing.T) {
	entries, err := os.ReadDir(filepath.Join("..", "..", "..", "migrations"))
	if err != nil {
		t.Fatalf("read migrations directory: %v", err)
	}

	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || !strings.HasSuffix(name, ".up.sql") {
			continue
		}

		upSQL := readMigration(t, name)
		if strings.Contains(upSQL, "link_type") {
			t.Fatalf("%s must use place_city_links.kind, not obsolete link_type", name)
		}
	}
}

func TestPlaceCityLinksSortOrderCompatibilityMigrationRunsBeforeSortOrderSeeds(t *testing.T) {
	const compatMigration = "084_place_city_links_sort_order_compat.up.sql"
	if compatMigration >= "085_seed_hiking_place_enrichment.up.sql" {
		t.Fatalf("%s must sort before 085 seed migrations that write place_city_links.sort_order", compatMigration)
	}

	upSQL := readMigration(t, compatMigration)
	requiredFragments := []string{
		"ALTER TABLE place_city_links",
		"ADD COLUMN IF NOT EXISTS sort_order",
		"UPDATE place_city_links",
		"CREATE OR REPLACE FUNCTION sync_place_city_links_sort_order",
		"CREATE TRIGGER trg_place_city_links_sort_order_sync",
		"NEW.country_code",
		"SELECT p.country_code",
		"NEW.position := NEW.sort_order",
		"NEW.sort_order := NEW.position",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("%s must contain %q", compatMigration, fragment)
		}
	}
}

func TestPlaceSeedMigrationsDoNotUseRemovedPlaceTablesOrMediaColumns(t *testing.T) {
	entries, err := os.ReadDir(filepath.Join("..", "..", "..", "migrations"))
	if err != nil {
		t.Fatalf("read migrations directory: %v", err)
	}

	removedFragments := []string{
		"place_locations",
		"\n    url,",
		"\n    alt_text,",
		"media_type = EXCLUDED.media_type,\n    url = EXCLUDED.url",
		"position = EXCLUDED.position,\n    position = EXCLUDED.position",
		"NOW(),\nFROM ",
	}

	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || (!strings.HasSuffix(name, ".up.sql") && !strings.HasSuffix(name, ".down.sql")) {
			continue
		}

		sql := readMigration(t, name)
		for _, fragment := range removedFragments {
			if strings.Contains(sql, fragment) {
				t.Fatalf("%s must not use removed place schema fragment %q", name, fragment)
			}
		}
	}
}

func TestKazakhstanOutdoorRouteTitleMigrationMakesListTitlesReadable(t *testing.T) {
	upSQL := readMigration(t, "140_rename_kazakhstan_outdoor_route_titles.up.sql")
	downSQL := readMigration(t, "140_rename_kazakhstan_outdoor_route_titles.down.sql")

	requiredFragments := []string{
		"seed_kazakhstan_outdoor_route_titles",
		"UPDATE place_translations",
		"p.country_code = 'KZ'",
		"p.tags @> ARRAY[readable.slug]::text[]",
		"'talgar-peak-base-trail'",
		"'Пик Талгар: базовые виды'",
		"'second-kolsai-lake-trek'",
		"'Второе Кольсайское озеро'",
		"'big-almaty-peak-trail'",
		"'Большой Алматинский пик'",
		"'tamgaly-tas-climber-path'",
		"'Тамгалы-Тас: скалолазная тропа'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("readable Kazakhstan outdoor title migration must contain %q", fragment)
		}
	}

	for _, fragment := range []string{
		"old_title",
		"UPDATE place_translations",
		"p.country_code = 'KZ'",
		"p.tags @> ARRAY[readable.slug]::text[]",
	} {
		if !strings.Contains(downSQL, fragment) {
			t.Fatalf("readable Kazakhstan outdoor title rollback must contain %q", fragment)
		}
	}
}

func TestPaidPlaceFeeDetailsMigrationAddsDisplayOnlyVisitInfo(t *testing.T) {
	upSQL := readMigration(t, "142_seed_paid_place_fee_details.up.sql")
	downSQL := readMigration(t, "142_seed_paid_place_fee_details.down.sql")

	requiredUpFragments := []string{
		"jsonb_set",
		"'{feeDetails}'",
		"price_amount IS NOT NULL",
		"price_amount > 0",
		"price_currency IS NOT NULL",
		"NOT (visit_info ? 'feeDetails')",
		"'isApproximate', true",
		"'sortOrder', 10",
	}
	for _, fragment := range requiredUpFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("142 fee details migration must contain %q", fragment)
		}
	}

	for _, forbidden := range []string{"source_url", "sourceUrl", "wiki", "wikipedia", "commons.wikimedia"} {
		if strings.Contains(strings.ToLower(upSQL), strings.ToLower(forbidden)) {
			t.Fatalf("142 fee details migration must not store source fragment %q", forbidden)
		}
	}

	if !strings.Contains(downSQL, "visit_info - 'feeDetails'") {
		t.Fatalf("142 fee details down migration must remove seeded feeDetails")
	}
}

func TestKazakhstan2026FeeDetailsMigrationUsesSpecificDisplayPrices(t *testing.T) {
	upSQL := readMigration(t, "143_update_kazakhstan_2026_fee_details.up.sql")
	downSQL := readMigration(t, "143_update_kazakhstan_2026_fee_details.down.sql")

	requiredUpFragments := []string{
		"p.country_code = 'KZ'",
		"seed_kazakhstan_oopt_fee_patterns",
		"'ile-alatau'",
		"'charyn'",
		"'kolsai'",
		"'altyn-emel'",
		"'burabay'",
		"'bayanaul'",
		"'katon-karagay'",
		"'aksu-jabagly'",
		"'ООПТ-сбор за посетителя'",
		"'Въезд легкового автомобиля'",
		"650",
		"1300",
		"865",
		"7000",
		"11250",
		"21625",
		"'Вход бесплатный'",
		"'Билет на смотровую площадку'",
		"'Билет на сеанс катания'",
		"'Канатная дорога или ски-пасс'",
	}
	for _, fragment := range requiredUpFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("143 Kazakhstan fee details migration must contain %q", fragment)
		}
	}

	for _, forbidden := range []string{
		"source_url",
		"sourceUrl",
		"wiki",
		"wikipedia",
		"commons.wikimedia",
		"transport, parking, guides",
		"транспорт, парковка, гиды",
		"Примерная стартовая стоимость доступа",
		"Доступ к природной территории",
		"Natural area access",
		"Ориентир по тарифу 2026 за 1 человека в сутки",
		"2026 tariff reference per person per day",
		"2026 тарифі бойынша 1 адамға тәулігіне бағдар",
	} {
		if strings.Contains(strings.ToLower(upSQL), strings.ToLower(forbidden)) {
			t.Fatalf("143 Kazakhstan fee details migration must not contain generic/source fragment %q", forbidden)
		}
	}

	for _, fragment := range []string{
		"visit_info - 'feeDetails'",
		"p.country_code = 'KZ'",
		"sortOrder",
		"BETWEEN 1000 AND 1399",
	} {
		if !strings.Contains(downSQL, fragment) {
			t.Fatalf("143 Kazakhstan fee details rollback must contain %q", fragment)
		}
	}
}

func TestKazakhstanRemainingRouteTitleMigrationCleansLegacyAndReferenceTitles(t *testing.T) {
	upSQL := readMigration(t, "141_rename_remaining_kazakhstan_route_titles.up.sql")
	downSQL := readMigration(t, "141_rename_remaining_kazakhstan_route_titles.down.sql")

	requiredFragments := []string{
		"seed_kazakhstan_remaining_route_titles",
		"UPDATE place_translations",
		"p.country_code = 'KZ'",
		"p.tags && remaining.match_tags",
		"'rocky-trail'",
		"'Актау: скальная тропа'",
		"'kolsai-sary-bulak-pass-trek'",
		"'Перевал Сары-Булак у Кольсая'",
		"'imantau-shalkar-lakes-trail'",
		"'Озера Имантау-Шалкар'",
		"'west-altai-nature-reserve-trails'",
		"'Западно-Алтайский заповедник: тропы'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("remaining Kazakhstan route title migration must contain %q", fragment)
		}
	}

	for _, fragment := range []string{
		"old_title",
		"UPDATE place_translations",
		"p.country_code = 'KZ'",
		"p.tags && remaining.match_tags",
	} {
		if !strings.Contains(downSQL, fragment) {
			t.Fatalf("remaining Kazakhstan route title rollback must contain %q", fragment)
		}
	}
}

func TestKazakhstanCityPlacesSeedMigrationCoversMustVisitCityAnchors(t *testing.T) {
	upSQL := readMigration(t, "009_seed_kazakhstan_city_places.up.sql")
	downSQL := readMigration(t, "009_seed_kazakhstan_city_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_city_links",
		"WITH seed_locations",
		"source = 'IMPORT'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("up migration must contain %q", fragment)
		}
	}

	requiredCities := []string{
		"almaty",
		"astana",
		"shymkent",
		"turkestan",
		"karaganda",
		"atyrau",
		"aktau",
		"pavlodar",
		"ust-kamenogorsk",
		"semey",
		"kostanay",
		"kyzylorda",
		"oral",
		"aktobe",
		"kokshetau",
	}
	for _, cityID := range requiredCities {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("up migration must seed places for city_id %q", cityID)
		}
	}

	requiredPlaces := []string{
		"Kok Tobe Hill and Cable Car",
		"Central Park Almaty",
		"Fantasy World Almaty",
		"Almaty Zoo",
		"Green Bazaar",
		"Barakholka Market",
		"Khan Shatyr",
		"Nur Alem Future Energy Museum",
		"Astana Botanical Garden",
		"Shymkent Citadel",
		"Shymkent Zoo",
		"Shymkent Dendropark",
		"Karavansaray Turkistan",
		"KarLag Museum",
		"Atyrau Bridges and Embankment",
		"Aktau Rocky Trail",
		"Mashkhur Jusup Kopeyev Mosque",
		"East Kazakhstan Ethnographic Museum-Reserve",
		"Abai Museum-Reserve",
		"Kostanay Regional Museum of Local History",
		"West Kazakhstan Museum of Local History",
		"Korkyt Ata Memorial",
		"Nur Gasyr Mosque",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("up migration must include curated place %q", title)
		}
	}

	for _, placeID := range []string{
		"2eeacb52-12ef-4499-b229-05e52a199d22",
		"6acdc04c-67b9-4e86-a43f-160738c3dda3",
		"3c070f18-a92c-4d5c-868c-dd4bda71ce95",
		"396f6629-a240-4845-8a5d-2fa33fc42b1b",
		"8a7b975e-9a4e-434e-a7e2-d721c41bda93",
		"ce5ca032-073b-4e4a-93d9-825a4e495574",
		"bc934181-e9d9-4daa-9909-5f87a3169159",
		"33192bba-1776-48e6-918b-198e81b17eae",
		"39759c2a-e2f1-4f2f-b354-d5c29f40fcc9",
		"abede8f2-87db-4f12-bc3e-64e815a1f97e",
		"a752e044-c458-4926-bdd1-76638b74b1c1",
		"1ede5116-b919-493e-9c58-b0027eb5f93b",
		"12e77265-9e9d-4d11-9c6d-acb8aac48f4b",
		"adece1ed-0d63-48e5-b54e-d49cad52a391",
		"9ed105cc-3f78-437a-ad1b-137422f3c8e6",
		"92f6c2cc-1b44-4900-a764-c1daab90024d",
		"d3951503-5e02-41ec-b886-dfc7cce1f925",
		"f1bfab8a-c217-4fe3-b4ba-c65c3fea9a9e",
		"0e06eed4-e871-4f78-919c-a11322eda453",
		"b8847588-a922-42cf-94a2-ffcbf043922a",
		"788b2836-0bbb-40bc-8a14-9548f47979ab",
		"877a0a46-da12-4f4c-be9c-a12a2032f93a",
		"1d3163c5-fa93-484f-b917-f721a8f1ae27",
		"09cdcef4-cb4d-4206-8a7a-2200270401ec",
		"1f32c9d1-d41d-4428-a853-fabe168aadef",
		"25f2452e-9943-463f-a135-27a72df7015d",
		"7344289b-c411-4ad5-ab27-268c06ef3cbb",
		"c7d8a58e-ee75-44cb-93f8-6f93f9a8a929",
		"b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60",
		"90742f2d-6b54-4676-930c-97bc59b60a64",
		"1ab18d1c-be18-4cfc-a5df-4494a4c12aed",
		"e895297e-6ecd-454e-89a5-88e341ccad4f",
		"0ce9cd13-dfc9-481b-821f-78ccaafb48bc",
		"eb123ce9-2da4-4b75-a0cd-d419699c166f",
		"3050b34f-5ecf-4ed3-8438-d6cc8deee7ff",
	} {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("up migration must include place id %s", placeID)
		}
		if !strings.Contains(downSQL, placeID) {
			t.Fatalf("down migration must delete place id %s", placeID)
		}
	}
}

func TestKazakhstanCityPlaceMediaSeedMigrationCoversEveryCityPlace(t *testing.T) {
	upSQL := readMigration(t, "010_seed_kazakhstan_city_place_media.up.sql")
	downSQL := readMigration(t, "010_seed_kazakhstan_city_place_media.down.sql")

	requiredFragments := []string{
		"INSERT INTO place_media",
		"external_url",
		"source_url",
		"credit",
		"license",
		"ON CONFLICT (id) DO UPDATE",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("up media migration must contain %q", fragment)
		}
	}

	for _, placeID := range kazakhstanCityPlaceIDs {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("up media migration must include media for place id %s", placeID)
		}
	}

	for _, mediaID := range kazakhstanCityMediaIDs {
		if !strings.Contains(upSQL, mediaID) {
			t.Fatalf("up media migration must include media id %s", mediaID)
		}
		if !strings.Contains(downSQL, mediaID) {
			t.Fatalf("down media migration must delete media id %s", mediaID)
		}
	}
}

func TestRussiaCityPlacesSeedMigrationCoversProductionAnchors(t *testing.T) {
	upSQL := readMigration(t, "011_seed_russia_city_places.up.sql")
	downSQL := readMigration(t, "011_seed_russia_city_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"WITH seed_locations",
		"'RU'",
		"source = 'IMPORT'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Russia up migration must contain %q", fragment)
		}
	}

	requiredCities := []string{
		"moscow",
		"saint-petersburg",
		"kazan",
		"sochi",
		"nizhny-novgorod",
		"yekaterinburg",
		"vladivostok",
		"kaliningrad",
		"volgograd",
	}
	for _, cityID := range requiredCities {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Russia up migration must seed places for city_id %q", cityID)
		}
	}

	requiredPlaces := []string{
		"Red Square",
		"Tretyakov Gallery",
		"Gorky Park Moscow",
		"State Hermitage Museum",
		"Peterhof Museum-Reserve",
		"Kazan Kremlin",
		"Sochi Arboretum",
		"Nizhny Novgorod Kremlin",
		"Yeltsin Center",
		"Russky Bridge",
		"Koenigsberg Cathedral",
		"Mamayev Kurgan",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Russia up migration must include curated place %q", title)
		}
	}

	for _, placeID := range russiaCityPlaceIDs {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("Russia up migration must include place id %s", placeID)
		}
		if !strings.Contains(downSQL, placeID) {
			t.Fatalf("Russia down migration must delete place id %s", placeID)
		}
	}
	for _, mediaID := range russiaCityMediaIDs {
		if !strings.Contains(upSQL, mediaID) {
			t.Fatalf("Russia up migration must include media id %s", mediaID)
		}
		if !strings.Contains(downSQL, mediaID) {
			t.Fatalf("Russia down migration must delete media id %s", mediaID)
		}
	}
}

func TestVietnamCityPlacesSeedMigrationCoversProductionAnchors(t *testing.T) {
	upSQL := readMigration(t, "012_seed_vietnam_city_places.up.sql")
	downSQL := readMigration(t, "012_seed_vietnam_city_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"WITH seed_locations",
		"'VN'",
		"source = 'IMPORT'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Vietnam up migration must contain %q", fragment)
		}
	}

	requiredCities := []string{
		"hanoi",
		"ha-long",
		"ninh-binh",
		"hue",
		"da-nang",
		"hoi-an",
		"ho-chi-minh-city",
		"nha-trang",
		"phu-quoc",
		"sa-pa",
		"can-tho",
		"da-lat",
	}
	for _, cityID := range requiredCities {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Vietnam up migration must seed places for city_id %q", cityID)
		}
	}

	requiredPlaces := []string{
		"Hoan Kiem Lake",
		"Temple of Literature",
		"Vietnam Museum of Ethnology",
		"Ha Long Bay",
		"Trang An Scenic Landscape Complex",
		"Imperial City of Hue",
		"Marble Mountains",
		"Golden Bridge",
		"Hoi An Ancient Town",
		"War Remnants Museum",
		"Ben Thanh Market",
		"Independence Palace",
		"Po Nagar Cham Towers",
		"VinWonders Nha Trang",
		"Phu Quoc National Park",
		"Fansipan",
		"Cai Rang Floating Market",
		"Crazy House Da Lat",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Vietnam up migration must include curated place %q", title)
		}
	}

	for _, placeID := range vietnamCityPlaceIDs {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("Vietnam up migration must include place id %s", placeID)
		}
		if !strings.Contains(downSQL, placeID) {
			t.Fatalf("Vietnam down migration must delete place id %s", placeID)
		}
	}
	for _, mediaID := range vietnamCityMediaIDs {
		if !strings.Contains(upSQL, mediaID) {
			t.Fatalf("Vietnam up migration must include media id %s", mediaID)
		}
		if !strings.Contains(downSQL, mediaID) {
			t.Fatalf("Vietnam down migration must delete media id %s", mediaID)
		}
	}
}

func TestPhuQuocPlacesSeedMigrationCoversRequestedAnchors(t *testing.T) {
	upSQL := readMigration(t, "013_seed_phu_quoc_places.up.sql")
	downSQL := readMigration(t, "013_seed_phu_quoc_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"WITH seed_locations",
		"'VN'",
		"'phu-quoc'",
		"source = 'IMPORT'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Phu Quoc up migration must contain %q", fragment)
		}
	}

	requiredPlaces := []string{
		"Starfish Beach",
		"VinWonders Phu Quoc",
		"SunWorld Hon Thom",
		"Suoi Tranh Waterfall",
		"Khem Beach",
		"Kiss of the Sea show",
		"Ice Jungle",
		"Prison History Museum",
		"Kingkong Mart",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Phu Quoc up migration must include requested place %q", title)
		}
	}

	for _, placeID := range phuQuocPlaceIDs {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("Phu Quoc up migration must include place id %s", placeID)
		}
		if !strings.Contains(downSQL, placeID) {
			t.Fatalf("Phu Quoc down migration must delete place id %s", placeID)
		}
	}
	for _, mediaID := range phuQuocMediaIDs {
		if !strings.Contains(upSQL, mediaID) {
			t.Fatalf("Phu Quoc up migration must include media id %s", mediaID)
		}
		if !strings.Contains(downSQL, mediaID) {
			t.Fatalf("Phu Quoc down migration must delete media id %s", mediaID)
		}
	}
}

func TestDaNangPlacesSeedMigrationCoversRequestedAnchors(t *testing.T) {
	upSQL := readMigration(t, "014_seed_da_nang_places.up.sql")
	downSQL := readMigration(t, "014_seed_da_nang_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"WITH seed_locations",
		"'VN'",
		"'da-nang'",
		"source = 'IMPORT'",
		"Ba Na Hills Golden Bridge",
		"Ba Na Hills: Золотой мост",
		"Ba Na Hills: Алтын көпір",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Da Nang up migration must contain %q", fragment)
		}
	}

	requiredPlaces := []string{
		"Wonder Park Da Nang",
		"Mikazuki Water Park 365",
		"Chùa Linh Ứng",
		"Art in Paradise Danang 3D Museum",
		"Sun Wheel",
		"Dragon Bridge",
		"Vincom Plaza Da Nang",
		"GO! Da Nang",
		"Lotte Mart Da Nang",
		"Han Market",
		"Con Market",
		"Helio Night Market",
		"Bac My An Market",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Da Nang up migration must include requested place %q", title)
		}
	}

	for _, placeID := range daNangPlaceIDs {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("Da Nang up migration must include place id %s", placeID)
		}
		if !strings.Contains(downSQL, placeID) {
			t.Fatalf("Da Nang down migration must delete place id %s", placeID)
		}
	}
	for _, mediaID := range daNangMediaIDs {
		if !strings.Contains(upSQL, mediaID) {
			t.Fatalf("Da Nang up migration must include media id %s", mediaID)
		}
		if !strings.Contains(downSQL, mediaID) {
			t.Fatalf("Da Nang down migration must delete media id %s", mediaID)
		}
	}
}

func TestHoiAnPlacesSeedMigrationCoversRequestedAnchors(t *testing.T) {
	upSQL := readMigration(t, "015_seed_hoi_an_places.up.sql")
	downSQL := readMigration(t, "015_seed_hoi_an_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"WITH seed_locations",
		"'VN'",
		"'hoi-an'",
		"source = 'IMPORT'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Hoi An up migration must contain %q", fragment)
		}
	}

	requiredPlaces := []string{
		"Cam Thanh Coconut Village",
		"Precious Heritage Art Gallery Museum",
		"Hoi An Memories Land",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Hoi An up migration must include requested place %q", title)
		}
	}

	for _, placeID := range hoiAnPlaceIDs {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("Hoi An up migration must include place id %s", placeID)
		}
		if !strings.Contains(downSQL, placeID) {
			t.Fatalf("Hoi An down migration must delete place id %s", placeID)
		}
	}
	for _, mediaID := range hoiAnMediaIDs {
		if !strings.Contains(upSQL, mediaID) {
			t.Fatalf("Hoi An up migration must include media id %s", mediaID)
		}
		if !strings.Contains(downSQL, mediaID) {
			t.Fatalf("Hoi An down migration must delete media id %s", mediaID)
		}
	}
}

func TestNhaTrangPlacesSeedMigrationCoversRequestedAnchors(t *testing.T) {
	upSQL := readMigration(t, "016_seed_nha_trang_places.up.sql")
	downSQL := readMigration(t, "016_seed_nha_trang_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"WITH seed_locations",
		"'VN'",
		"'nha-trang'",
		"source = 'IMPORT'",
		"Тямские башни Понагар",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Nha Trang up migration must contain %q", fragment)
		}
	}

	requiredPlaces := []string{
		"Nha Trang Night Market",
		"Vincom Plaza Nha Trang",
		"GO! Nha Trang",
		"Big C Nha Trang",
		"Chợ Đầm Market",
		"AB Central Square",
		"Lotte Mart Nha Trang",
		"Gold Coast Shopping Mall",
		"National Oceanographic Museum",
		"Long Sơn Pagoda",
		"Ba Ho Waterfall",
		"Nha Trang Beach",
		"Dốc Lết Beach",
		"Bãi Dài Beach",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Nha Trang up migration must include requested place %q", title)
		}
	}

	for _, placeID := range nhaTrangPlaceIDs {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("Nha Trang up migration must include place id %s", placeID)
		}
		if !strings.Contains(downSQL, placeID) {
			t.Fatalf("Nha Trang down migration must delete place id %s", placeID)
		}
	}
	for _, mediaID := range nhaTrangMediaIDs {
		if !strings.Contains(upSQL, mediaID) {
			t.Fatalf("Nha Trang up migration must include media id %s", mediaID)
		}
		if !strings.Contains(downSQL, mediaID) {
			t.Fatalf("Nha Trang down migration must delete media id %s", mediaID)
		}
	}
}

func TestHanoiPlacesSeedMigrationCoversRequestedAnchors(t *testing.T) {
	upSQL := readMigration(t, "017_seed_hanoi_places.up.sql")
	downSQL := readMigration(t, "017_seed_hanoi_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"WITH seed_locations",
		"'VN'",
		"'hanoi'",
		"source = 'IMPORT'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Hanoi up migration must contain %q", fragment)
		}
	}

	requiredPlaces := []string{
		"Hỏa Lò Prison",
		"Ho Chi Minh Mausoleum",
		"St. Joseph''s Cathedral",
		"Hanoi Train Street",
		"Lotte Observation Deck Hanoi",
		"Imperial Citadel of Thang Long",
		"Ho Chi Minh Museum",
		"One Pillar Pagoda",
		"Hanoi Old Quarter",
		"Long Bien Bridge",
		"Dong Xuan Market",
		"Tran Quoc Pagoda",
		"Thang Long Water Puppet Theatre",
		"Vietnamese Women''s Museum",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Hanoi up migration must include requested place %q", title)
		}
	}

	for _, placeID := range hanoiPlaceIDs {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("Hanoi up migration must include place id %s", placeID)
		}
		if !strings.Contains(downSQL, placeID) {
			t.Fatalf("Hanoi down migration must delete place id %s", placeID)
		}
	}
	for _, mediaID := range hanoiMediaIDs {
		if !strings.Contains(upSQL, mediaID) {
			t.Fatalf("Hanoi up migration must include media id %s", mediaID)
		}
		if !strings.Contains(downSQL, mediaID) {
			t.Fatalf("Hanoi down migration must delete media id %s", mediaID)
		}
	}
}

func TestVietnamPriorityPlacesSeedMigrationCoversProductionAnchors(t *testing.T) {
	upSQL := readMigration(t, "018_seed_vietnam_priority_places.up.sql")
	downSQL := readMigration(t, "018_seed_vietnam_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"WITH seed_locations",
		"'VN'",
		"source = 'IMPORT'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Vietnam priority up migration must contain %q", fragment)
		}
	}
	if strings.Contains(upSQL, "ON COMMIT DROP") {
		t.Fatalf("Vietnam priority up migration must not use ON COMMIT DROP because psql-based migrator runs statements in autocommit mode")
	}
	if !strings.Contains(upSQL, "DROP TABLE IF EXISTS seed_vietnam_priority_places") {
		t.Fatalf("Vietnam priority up migration must explicitly drop the seed temp table after using it")
	}

	requiredCities := []string{
		"ha-long",
		"ninh-binh",
		"sa-pa",
		"hue",
		"ho-chi-minh-city",
		"da-lat",
		"can-tho",
		"phan-thiet",
	}
	for _, cityID := range requiredCities {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Vietnam priority up migration must seed places for city_id %q", cityID)
		}
	}

	requiredPlaces := []string{
		"Sung Sot Cave",
		"Titop Island",
		"Bai Tu Long Bay",
		"Sun World Ha Long",
		"Bai Chay Beach",
		"Tam Coc - Bich Dong",
		"Mua Cave Viewpoint",
		"Hoa Lu Ancient Capital",
		"Bai Dinh Pagoda",
		"Cuc Phuong National Park",
		"Muong Hoa Valley",
		"Cat Cat Village",
		"Silver Waterfall",
		"O Quy Ho Pass",
		"Sapa Stone Church",
		"Thien Mu Pagoda",
		"Tomb of Minh Mang",
		"Tomb of Tu Duc",
		"Tomb of Khai Dinh",
		"Perfume River",
		"Dong Ba Market",
		"Cu Chi Tunnels",
		"Saigon Central Post Office",
		"Notre-Dame Cathedral Basilica of Saigon",
		"Bitexco Financial Tower Skydeck",
		"Jade Emperor Pagoda",
		"Bui Vien Walking Street",
		"Datanla Waterfall",
		"Linh Phuoc Pagoda",
		"Pongour Waterfall",
		"Xuan Huong Lake",
		"Da Lat Railway Station",
		"Da Lat Night Market",
		"Ninh Kieu Wharf",
		"Son Islet",
		"Binh Thuy Ancient House",
		"Ong Temple Can Tho",
		"Can Tho Museum",
		"White Sand Dunes Mui Ne",
		"Red Sand Dunes Mui Ne",
		"Fairy Stream Mui Ne",
		"Mui Ne Fishing Village",
		"Mui Ne Beach",
		"Po Sah Inu Cham Towers",
		"Ta Cu Mountain",
		"Ke Ga Lighthouse",
		"Phan Thiet Central Market",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Vietnam priority up migration must include curated place %q", title)
		}
	}

	for _, placeID := range vietnamPriorityPlaceIDs {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("Vietnam priority up migration must include place id %s", placeID)
		}
		if !strings.Contains(downSQL, placeID) {
			t.Fatalf("Vietnam priority down migration must delete place id %s", placeID)
		}
	}
	for _, mediaID := range vietnamPriorityMediaIDs {
		if !strings.Contains(upSQL, mediaID) {
			t.Fatalf("Vietnam priority up migration must include media id %s", mediaID)
		}
		if !strings.Contains(downSQL, mediaID) {
			t.Fatalf("Vietnam priority down migration must delete media id %s", mediaID)
		}
	}
}

func TestMarketCategoryMigrationRetagsKnownMarketPlaces(t *testing.T) {
	upSQL := readMigration(t, "019_place_market_category.up.sql")
	downSQL := readMigration(t, "019_place_market_category.down.sql")

	requiredUpFragments := []string{
		"DROP CONSTRAINT IF EXISTS chk_places_category",
		"ADD CONSTRAINT chk_places_category",
		"'MARKET', 'SHOPPING'",
		"UPDATE places",
		"category = 'MARKET'",
		"updated_at = NOW()",
		"source = 'IMPORT'",
	}
	for _, fragment := range requiredUpFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("market category up migration must contain %q", fragment)
		}
	}

	marketPlaceIDs := []string{
		"ce5ca032-073b-4e4a-93d9-825a4e495574", // Green Bazaar
		"bc934181-e9d9-4daa-9909-5f87a3169159", // Barakholka Market
		"8b507042-be77-4e72-a530-78a6ccbf8979", // Ben Thanh Market
		"b0f6561c-68a2-4dad-ae5a-80ae3edfc53c", // Cai Rang Floating Market
		"072f60d2-ef0d-4eae-aa77-51ff1eee274f", // Han Market
		"58b1ccbc-6671-4112-a6b4-551767360a11", // Con Market
		"aa81bb79-cabb-477a-ac05-45b863d6df8e", // Helio Night Market
		"262204b6-09c5-4914-85cf-06a878cd8668", // Bac My An Market
		"b789d8ae-3f3f-41e3-88b2-e553cd978947", // Nha Trang Night Market
		"0425d348-b915-4c47-9dfe-a3edb8186be5", // Cho Dam Market
		"587038b0-d882-4220-b65e-005b54d99344", // Dong Xuan Market
		"8302674f-7fbc-4f13-8ce1-9c46a08e311e", // Dong Ba Market
		"9becd171-75b3-4488-b2bb-a8256d3ef7dc", // Da Lat Night Market
		"627c04c6-16f7-4a8d-abc9-189a32d7b656", // Phan Thiet Central Market
	}
	for _, placeID := range marketPlaceIDs {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("market category up migration must update place id %s", placeID)
		}
		if !strings.Contains(downSQL, placeID) {
			t.Fatalf("market category down migration must restore place id %s", placeID)
		}
	}
	for _, category := range []string{"'FOOD'", "'SHOPPING'"} {
		if !strings.Contains(downSQL, category) {
			t.Fatalf("market category down migration must restore previous category %s", category)
		}
	}
	for _, fragment := range []string{
		"DROP CONSTRAINT IF EXISTS chk_places_category",
		"ADD CONSTRAINT chk_places_category",
		"WHERE category = 'MARKET'",
	} {
		if !strings.Contains(downSQL, fragment) {
			t.Fatalf("market category down migration must contain %q", fragment)
		}
	}
}

func TestThailandPriorityPlacesSeedMigrationCoversTouristClusters(t *testing.T) {
	upSQL := readMigration(t, "020_seed_thailand_priority_places.up.sql")
	downSQL := readMigration(t, "020_seed_thailand_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"WITH seed_locations",
		"'TH'",
		"source = 'IMPORT'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Thailand up migration must contain %q", fragment)
		}
	}

	requiredCities := []string{
		"bangkok",
		"ayutthaya",
		"pattaya",
		"phuket",
		"krabi",
		"phang-nga",
		"chiang-mai",
		"chiang-rai",
		"pai",
		"koh-samui",
		"koh-phangan",
		"koh-tao",
		"hua-hin",
	}
	for _, cityID := range requiredCities {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Thailand up migration must seed places for city_id %q", cityID)
		}
	}

	requiredPlaces := []string{
		"Grand Palace",
		"Chatuchak Weekend Market",
		"Ayutthaya Historical Park",
		"Sanctuary of Truth",
		"Phuket Big Buddha",
		"Railay Beach",
		"James Bond Island",
		"Wat Phra That Doi Suthep",
		"Wat Rong Khun",
		"Pai Canyon",
		"Big Buddha Temple",
		"Koh Nang Yuan",
		"Hua Hin Night Market",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Thailand up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'TEMPLE'", "'MUSEUM'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Thailand up migration must include category %s", category)
		}
	}

	for _, placeID := range thailandPriorityPlaceIDs {
		if !strings.Contains(upSQL, placeID) {
			t.Fatalf("Thailand up migration must include place id %s", placeID)
		}
		if !strings.Contains(downSQL, placeID) {
			t.Fatalf("Thailand down migration must delete place id %s", placeID)
		}
	}
	for _, mediaID := range thailandPriorityMediaIDs {
		if !strings.Contains(upSQL, mediaID) {
			t.Fatalf("Thailand up migration must include media id %s", mediaID)
		}
		if !strings.Contains(downSQL, mediaID) {
			t.Fatalf("Thailand down migration must delete media id %s", mediaID)
		}
	}
}

func TestPhilippinesPriorityPlacesSeedMigrationCoversTouristClusters(t *testing.T) {
	upSQL := readMigration(t, "022_seed_philippines_priority_places.up.sql")
	downSQL := readMigration(t, "022_seed_philippines_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_philippines_resolved_places AS",
		"'PH'",
		"source = 'IMPORT'",
		"md5('ph-place:'",
		"md5('ph-media:'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Philippines up migration must contain %q", fragment)
		}
	}

	if strings.Contains(upSQL, "ON COMMIT DROP") {
		t.Fatalf("Philippines up migration must not use ON COMMIT DROP because psql-based migrator runs statements in autocommit mode")
	}
	if !strings.Contains(upSQL, "DROP TABLE IF EXISTS seed_philippines_resolved_places") {
		t.Fatalf("Philippines up migration must explicitly drop the resolved seed temp table after using it")
	}

	requiredCities := []string{
		"manila",
		"makati",
		"taguig",
		"tagaytay",
		"cebu-city",
		"mactan",
		"bohol",
		"puerto-princesa",
		"el-nido",
		"coron",
		"boracay",
		"iloilo",
		"bacolod",
		"davao",
		"siargao",
		"cagayan-de-oro",
		"camiguin",
		"baguio",
		"vigan",
		"banaue",
		"sagada",
		"la-union",
		"pagudpud",
	}
	for _, cityID := range requiredCities {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Philippines up migration must seed places for city_id %q", cityID)
		}
	}

	requiredPlaces := []string{
		"Intramuros",
		"SM Mall of Asia",
		"Sky Ranch Tagaytay",
		"Magellan''s Cross",
		"Carbon Market",
		"Chocolate Hills",
		"Puerto Princesa Subterranean River National Park",
		"Big Lagoon",
		"Kayangan Lake",
		"White Beach",
		"D''Talipapa Market",
		"Iloilo River Esplanade",
		"The Ruins",
		"Roxas Night Market",
		"Cloud 9 Siargao",
		"Camiguin White Island",
		"Burnham Park",
		"Calle Crisologo",
		"Banaue Rice Terraces",
		"Sagada Hanging Coffins",
		"San Juan Surf Beach",
		"Bangui Windmills",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Philippines up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'TEMPLE'", "'MUSEUM'", "'ENTERTAINMENT'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Philippines up migration must include category %s", category)
		}
	}

	for _, slug := range []string{
		"intramuros",
		"puerto-princesa-underground-river",
		"white-beach-boracay",
		"cloud-9-siargao",
		"banaue-rice-terraces",
	} {
		if !strings.Contains(upSQL, "'"+slug+"'") {
			t.Fatalf("Philippines up migration must include slug %q", slug)
		}
		if !strings.Contains(downSQL, "'"+slug+"'") {
			t.Fatalf("Philippines down migration must delete slug %q", slug)
		}
	}
	if !strings.Contains(downSQL, "md5('ph-place:'") || !strings.Contains(downSQL, "md5('ph-media:'") {
		t.Fatalf("Philippines down migration must compute deterministic place and media ids")
	}
}

func TestIndonesiaPriorityPlacesSeedMigrationCoversTouristClusters(t *testing.T) {
	upSQL := readMigration(t, "023_seed_indonesia_priority_places.up.sql")
	downSQL := readMigration(t, "023_seed_indonesia_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_indonesia_resolved_places AS",
		"'ID'",
		"source = 'IMPORT'",
		"md5('id-bali-place:'",
		"md5('id-bali-media:'",
		"indonesia-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Indonesia up migration must contain %q", fragment)
		}
	}

	if strings.Contains(upSQL, "ON COMMIT DROP") {
		t.Fatalf("Indonesia up migration must not use ON COMMIT DROP because psql-based migrator runs statements in autocommit mode")
	}
	if !strings.Contains(upSQL, "DROP TABLE IF EXISTS seed_indonesia_resolved_places") {
		t.Fatalf("Indonesia up migration must explicitly drop the resolved seed temp table after using it")
	}

	requiredCities := []string{
		"denpasar",
		"kuta",
		"legian",
		"seminyak",
		"canggu",
		"sanur",
		"nusa-dua",
		"jimbaran",
		"uluwatu",
		"ubud",
		"gianyar",
		"sukawati",
		"tegallalang",
		"tampaksiring",
		"bedugul",
		"tabanan",
		"jatiluwih",
		"lovina",
		"singaraja",
		"munduk",
		"amed",
		"candidasa",
		"sidemen",
		"karangasem",
		"kintamani",
		"gilimanuk",
		"nusa-penida",
		"nusa-lembongan",
	}
	for _, cityID := range requiredCities {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Indonesia up migration must seed places for city_id %q", cityID)
		}
	}

	requiredPlaces := []string{
		"Bajra Sandhi Monument",
		"Waterbom Bali",
		"Beachwalk Shopping Center",
		"Kuta Art Market",
		"Seminyak Beach",
		"Love Anchor Market",
		"Sindhu Night Market",
		"Museum Pasifika",
		"Jimbaran Bay Seafood Sunset",
		"Uluwatu Temple",
		"Garuda Wisnu Kencana Cultural Park",
		"Sacred Monkey Forest Sanctuary",
		"Ubud Art Market",
		"Tegenungan Waterfall",
		"Bali Safari and Marine Park",
		"Tegalalang Rice Terrace",
		"Tirta Empul Temple",
		"Ulun Danu Beratan Temple",
		"Tanah Lot",
		"Jatiluwih Rice Terraces",
		"Sekumpul Waterfall",
		"West Bali National Park",
		"Tirta Gangga Water Palace",
		"Besakih Temple",
		"Mount Batur",
		"Kelingking Beach",
		"Devil''s Tears",
	}
	for _, title := range requiredPlaces {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Indonesia up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'TEMPLE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Indonesia up migration must include category %s", category)
		}
	}

	for _, slug := range []string{
		"bajra-sandhi-monument",
		"kuta-beach",
		"sacred-monkey-forest-ubud",
		"tanah-lot",
		"mount-batur",
		"kelingking-beach",
		"devils-tears",
	} {
		if !strings.Contains(upSQL, "'"+slug+"'") {
			t.Fatalf("Indonesia up migration must include slug %q", slug)
		}
	}
	if !strings.Contains(downSQL, "indonesia-seed-v1") || !strings.Contains(downSQL, "country_code = 'ID'") {
		t.Fatalf("Indonesia down migration must remove only tagged Indonesia seed places")
	}
}

func TestIndonesiaBaliExtendedPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "025_seed_indonesia_bali_extended_places.up.sql")
	downSQL := readMigration(t, "025_seed_indonesia_bali_extended_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_indonesia_bali_extended_resolved AS",
		"'ID'",
		"indonesia-bali-extended-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("extended Bali up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"denpasar",
		"kuta",
		"legian",
		"seminyak",
		"canggu",
		"sanur",
		"nusa-dua",
		"jimbaran",
		"uluwatu",
		"ubud",
		"gianyar",
		"sukawati",
		"tegallalang",
		"bedugul",
		"tabanan",
		"lovina",
		"singaraja",
		"munduk",
		"amed",
		"karangasem",
		"kintamani",
		"nusa-penida",
		"nusa-lembongan",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("extended Bali up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Discovery Shopping Mall",
		"Berawa Beach",
		"Petitenget Beach",
		"Puja Mandala",
		"Batuan Temple",
		"Tibumana Waterfall",
		"The Blooms Garden Bali",
		"Lovina Dolphin Statue",
		"Tukad Cepung Waterfall",
		"Atuh Beach",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("extended Bali up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'TEMPLE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("extended Bali up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['indonesia', 'bali', city_id") {
		t.Fatalf("extended Bali up migration must tag every place with the Bali region")
	}
	if !strings.Contains(downSQL, "indonesia-bali-extended-seed-v1") || !strings.Contains(downSQL, "country_code = 'ID'") {
		t.Fatalf("extended Bali down migration must remove only tagged Indonesia Bali seed places")
	}
}

func TestMaldivesPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "026_seed_maldives_priority_places.up.sql")
	downSQL := readMigration(t, "026_seed_maldives_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_maldives_resolved_places AS",
		"'MV'",
		"maldives-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Maldives up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"male",
		"hulhumale",
		"villingili",
		"maafushi",
		"gulhi",
		"guraidhoo",
		"dhiffushi",
		"thulusdhoo",
		"himmafushi",
		"huraa",
		"fulidhoo",
		"vaadhoo",
		"rasdhoo",
		"ukulhas",
		"dhigurah",
		"maamigili",
		"dharavandhoo",
		"baa-atoll",
		"addu-city",
		"fuvahmulah",
		"gan",
		"utheemu",
		"isdhoo",
		"lhaviyani-atoll",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Maldives up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"National Museum of Maldives",
		"Male Fish Market",
		"Hulhumale Beach",
		"Maafushi Bikini Beach",
		"Thulusdhoo Cokes Surf Break",
		"Hanifaru Bay",
		"Addu Nature Park",
		"Fuvahmulah Tiger Shark Point",
		"Vaadhoo Sea of Stars",
		"Utheemu Ganduvaru",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Maldives up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Maldives up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['maldives', city_id") {
		t.Fatalf("Maldives up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "maldives-seed-v1") || !strings.Contains(downSQL, "country_code = 'MV'") {
		t.Fatalf("Maldives down migration must remove only tagged Maldives seed places")
	}
}

func TestGeorgiaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "027_seed_georgia_priority_places.up.sql")
	downSQL := readMigration(t, "027_seed_georgia_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_georgia_resolved_places AS",
		"'GE'",
		"georgia-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Georgia up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"tbilisi",
		"mtskheta",
		"batumi",
		"kobuleti",
		"kutaisi",
		"tskaltubo",
		"martvili",
		"stepantsminda",
		"gudauri",
		"telavi",
		"sighnaghi",
		"borjomi",
		"bakuriani",
		"gori",
		"uplistsikhe",
		"vardzia",
		"mestia",
		"ushguli",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Georgia up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Narikala Fortress",
		"Dry Bridge Market",
		"Tbilisi Mall",
		"Svetitskhoveli Cathedral",
		"Batumi Boulevard",
		"Batumi Botanical Garden",
		"Kobuleti Beach",
		"Bagrati Cathedral",
		"Prometheus Cave",
		"Martvili Canyon",
		"Gergeti Trinity Church",
		"Gudauri Ski Resort",
		"Telavi Bazaar",
		"Sighnaghi Old Town",
		"Borjomi Central Park",
		"Uplistsikhe Cave Town",
		"Vardzia Cave Monastery",
		"Svaneti Museum of History and Ethnography",
		"Ushguli Village",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Georgia up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Georgia up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['georgia', city_id") {
		t.Fatalf("Georgia up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "georgia-seed-v1") || !strings.Contains(downSQL, "country_code = 'GE'") {
		t.Fatalf("Georgia down migration must remove only tagged Georgia seed places")
	}
}

func TestArmeniaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "028_seed_armenia_priority_places.up.sql")
	downSQL := readMigration(t, "028_seed_armenia_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_armenia_resolved_places AS",
		"'AM'",
		"armenia-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Armenia up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"yerevan",
		"vagharshapat",
		"garni",
		"geghard",
		"sevan",
		"dilijan",
		"tsaghkadzor",
		"gyumri",
		"vanadzor",
		"alaverdi",
		"stepanavan",
		"areni",
		"jermuk",
		"goris",
		"tatev",
		"khndzoresk",
		"kapan",
		"meghri",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Armenia up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Republic Square",
		"Cascade Complex",
		"Vernissage Market",
		"Yerevan Mall",
		"Etchmiadzin Cathedral",
		"Garni Temple",
		"Geghard Monastery",
		"Sevanavank Monastery",
		"Lake Sevan Public Beach",
		"Dilijan National Park",
		"Tsaghkadzor Ropeway",
		"Black Fortress",
		"Haghpat Monastery",
		"Sanahin Monastery",
		"Areni Wine Village",
		"Noravank Monastery",
		"Jermuk Waterfall",
		"Wings of Tatev",
		"Khndzoresk Swinging Bridge",
		"Meghri Fortress",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Armenia up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Armenia up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['armenia', city_id") {
		t.Fatalf("Armenia up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "armenia-seed-v1") || !strings.Contains(downSQL, "country_code = 'AM'") {
		t.Fatalf("Armenia down migration must remove only tagged Armenia seed places")
	}
}

func TestChinaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "029_seed_china_priority_places.up.sql")
	downSQL := readMigration(t, "029_seed_china_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_china_resolved_places AS",
		"'CN'",
		"china-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("China up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"beijing",
		"shanghai",
		"hangzhou",
		"suzhou",
		"nanjing",
		"xian",
		"chengdu",
		"chongqing",
		"guangzhou",
		"shenzhen",
		"sanya",
		"xiamen",
		"qingdao",
		"guilin",
		"yangshuo",
		"zhangjiajie",
		"huangshan",
		"lijiang",
		"dali",
		"kunming",
		"luoyang",
		"dengfeng",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("China up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Forbidden City",
		"Mutianyu Great Wall",
		"Summer Palace",
		"The Bund",
		"Yu Garden",
		"West Lake",
		"Humble Administrator Garden",
		"Confucius Temple Qinhuai Scenic Area",
		"Terracotta Army",
		"Giant Wild Goose Pagoda",
		"Chengdu Research Base of Giant Panda Breeding",
		"Kuanzhai Alley",
		"Hongya Cave",
		"Canton Tower",
		"Window of the World",
		"Yalong Bay",
		"Gulangyu Island",
		"Tsingtao Beer Museum",
		"Li River",
		"Zhangjiajie National Forest Park",
		"Yellow Mountain",
		"Lijiang Old Town",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("China up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("China up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['china', city_id") {
		t.Fatalf("China up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "china-seed-v1") || !strings.Contains(downSQL, "country_code = 'CN'") {
		t.Fatalf("China down migration must remove only tagged China seed places")
	}
}

func TestChinaHainanExtendedPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "030_seed_china_hainan_extended_places.up.sql")
	downSQL := readMigration(t, "030_seed_china_hainan_extended_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_china_hainan_resolved_places AS",
		"'CN'",
		"china-hainan-seed-v1",
		"array_append",
		"array_remove",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL+downSQL, fragment) {
			t.Fatalf("Hainan migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{"haikou", "sanya", "wanning", "lingshui", "qionghai", "danzhou", "wenchang"} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Hainan up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Haikou Qilou Old Street",
		"Hainan Museum",
		"Holiday Beach",
		"Mission Hills Haikou",
		"Dadonghai Beach",
		"Luhuitou Park",
		"Yalong Bay Tropical Paradise Forest Park",
		"Riyue Bay",
		"Shimei Bay",
		"Xinglong Tropical Botanical Garden",
		"Boundary Island",
		"Nanwan Monkey Island",
		"Hainan Ocean Paradise",
		"Boao Forum for Asia Permanent Site",
		"Yudai Beach",
		"Wenchang Space Launch Site",
		"Ocean Flower Island",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Hainan up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Hainan up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['china', 'hainan', city_id") {
		t.Fatalf("Hainan up migration must tag every new place with the Hainan region")
	}
	if !strings.Contains(downSQL, "china-hainan-seed-v1") || !strings.Contains(downSQL, "country_code = 'CN'") {
		t.Fatalf("Hainan down migration must remove only tagged Hainan seed places")
	}
}

func TestSouthKoreaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "031_seed_south_korea_priority_places.up.sql")
	downSQL := readMigration(t, "031_seed_south_korea_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_south_korea_resolved_places AS",
		"'KR'",
		"south-korea-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("South Korea up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"seoul",
		"incheon",
		"suwon",
		"yongin",
		"paju",
		"busan",
		"gyeongju",
		"daegu",
		"jeju",
		"seogwipo",
		"sokcho",
		"yangyang",
		"gangneung",
		"chuncheon",
		"pyeongchang",
		"goseong",
		"cheorwon",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("South Korea up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Gyeongbokgung Palace",
		"Starfield COEX Mall",
		"Gwangjang Market",
		"Songdo Central Park",
		"Suwon Hwaseong Fortress",
		"Everland",
		"Imjingak Peace Park",
		"Haeundae Beach",
		"Jagalchi Fish Market",
		"Bulguksa Temple",
		"Donggung Palace and Wolji Pond",
		"Seomun Market",
		"Hallasan National Park",
		"Seongsan Ilchulbong Sunrise Peak",
		"Dongmun Traditional Market",
		"Seoraksan National Park",
		"Sokcho Tourist and Fishery Market",
		"Gyeongpo Beach",
		"Nami Island",
		"LEGOLAND Korea Resort",
		"Alpensia Resort",
		"DMZ Museum",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("South Korea up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("South Korea up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['south-korea', city_id") {
		t.Fatalf("South Korea up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "south-korea-seed-v1") || !strings.Contains(downSQL, "country_code = 'KR'") {
		t.Fatalf("South Korea down migration must remove only tagged South Korea seed places")
	}
}

func TestJapanPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "032_seed_japan_priority_places.up.sql")
	downSQL := readMigration(t, "032_seed_japan_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_japan_resolved_places AS",
		"'JP'",
		"japan-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Japan up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"tokyo",
		"yokohama",
		"kamakura",
		"nikko",
		"hakone",
		"fujikawaguchiko",
		"osaka",
		"kyoto",
		"nara",
		"kobe",
		"himeji",
		"wakayama",
		"nagoya",
		"kanazawa",
		"takayama",
		"shirakawa-go",
		"matsumoto",
		"sapporo",
		"otaru",
		"hakodate",
		"furano",
		"asahikawa",
		"sendai",
		"aomori",
		"fukuoka",
		"hiroshima",
		"hatsukaichi",
		"nagasaki",
		"kumamoto",
		"beppu",
		"kagoshima",
		"naha",
		"onna",
		"ishigaki",
		"takamatsu",
		"matsuyama",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Japan up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Senso-ji Temple",
		"Shibuya Scramble Crossing",
		"Toyosu Market",
		"Tokyo Disneyland",
		"Yokohama Chinatown",
		"Kotoku-in Great Buddha",
		"Nikko Toshogu Shrine",
		"Lake Kawaguchiko",
		"Kiyomizu-dera Temple",
		"Fushimi Inari Taisha",
		"Universal Studios Japan",
		"Dotonbori",
		"Nara Park",
		"Himeji Castle",
		"Toyota Commemorative Museum",
		"Kenrokuen Garden",
		"Shirakawa-go Ogimachi Village",
		"Matsumoto Castle",
		"Sapporo Odori Park",
		"Otaru Canal",
		"Hakodate Morning Market",
		"Aoiike Blue Pond",
		"Sendai Castle Site",
		"Hiroshima Peace Memorial Park",
		"Itsukushima Shrine",
		"Fukuoka Tower",
		"Nagasaki Peace Park",
		"Kumamoto Castle",
		"Beppu Jigoku Meguri",
		"Shuri Castle Park",
		"Manza Beach",
		"Shiroyama Observatory",
		"Ritsurin Garden",
		"Dogo Onsen Honkan",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Japan up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Japan up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['japan', city_id") {
		t.Fatalf("Japan up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "japan-seed-v1") || !strings.Contains(downSQL, "country_code = 'JP'") {
		t.Fatalf("Japan down migration must remove only tagged Japan seed places")
	}
}

func TestUAEPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "033_seed_uae_priority_places.up.sql")
	downSQL := readMigration(t, "033_seed_uae_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_uae_resolved_places AS",
		"'AE'",
		"uae-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("UAE up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"dubai",
		"abu-dhabi",
		"al-ain",
		"sharjah",
		"ajman",
		"ras-al-khaimah",
		"fujairah",
		"umm-al-quwain",
		"hatta",
		"khor-fakkan",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("UAE up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Burj Khalifa",
		"The Dubai Mall",
		"Gold Souk",
		"Jumeirah Beach",
		"Dubai Miracle Garden",
		"Museum of the Future",
		"Hatta Wadi Hub",
		"Sheikh Zayed Grand Mosque",
		"Louvre Abu Dhabi",
		"Ferrari World Yas Island",
		"Qasr Al Watan",
		"Al Ain Oasis",
		"Al Jahili Fort",
		"Sharjah Museum of Islamic Civilization",
		"Al Noor Island",
		"Blue Souk",
		"Ajman Museum",
		"Jebel Jais",
		"Dhayah Fort",
		"Fujairah Fort",
		"Al Bidya Mosque",
		"Umm Al Quwain Fort and Museum",
		"Dreamland Aqua Park",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("UAE up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("UAE up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['uae', city_id") {
		t.Fatalf("UAE up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "uae-seed-v1") || !strings.Contains(downSQL, "country_code = 'AE'") {
		t.Fatalf("UAE down migration must remove only tagged UAE seed places")
	}
}

func TestTurkeyPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "034_seed_turkey_priority_places.up.sql")
	downSQL := readMigration(t, "034_seed_turkey_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_turkey_resolved_places AS",
		"'TR'",
		"turkey-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Turkey up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"istanbul",
		"princes-islands",
		"antalya",
		"alanya",
		"side",
		"belek",
		"kemer",
		"kas",
		"izmir",
		"selcuk",
		"cesme",
		"bodrum",
		"marmaris",
		"fethiye",
		"oludeniz",
		"pamukkale",
		"goreme",
		"nevsehir",
		"urgup",
		"uchisar",
		"avanos",
		"ankara",
		"konya",
		"trabzon",
		"rize",
		"uzungol",
		"artvin",
		"mardin",
		"sanliurfa",
		"gaziantep",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Turkey up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Hagia Sophia",
		"Topkapi Palace",
		"Grand Bazaar",
		"Galata Tower",
		"Princes' Islands",
		"Kaleici Old Town",
		"Konyaalti Beach",
		"Duden Waterfalls",
		"Aspendos Theatre",
		"Side Ancient City",
		"The Land of Legends",
		"Alanya Castle",
		"Ephesus Ancient City",
		"Kemeralti Bazaar",
		"Pamukkale Travertines",
		"Bodrum Castle",
		"Oludeniz Blue Lagoon",
		"Saklikent Canyon",
		"Goreme Open Air Museum",
		"Uchisar Castle",
		"Derinkuyu Underground City",
		"Anitkabir",
		"Museum of Anatolian Civilizations",
		"Mevlana Museum",
		"Sumela Monastery",
		"Uzungol",
		"Ayder Plateau",
		"Mardin Old Town",
		"Gobeklitepe",
		"Zeugma Mosaic Museum",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Turkey up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Turkey up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['turkey', city_id") {
		t.Fatalf("Turkey up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "turkey-seed-v1") || !strings.Contains(downSQL, "country_code = 'TR'") {
		t.Fatalf("Turkey down migration must remove only tagged Turkey seed places")
	}
}

func TestEgyptPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "035_seed_egypt_priority_places.up.sql")
	downSQL := readMigration(t, "035_seed_egypt_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_egypt_resolved_places AS",
		"'EG'",
		"egypt-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Egypt up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"cairo",
		"giza",
		"alexandria",
		"north-coast",
		"port-said",
		"suez",
		"ain-sokhna",
		"luxor",
		"aswan",
		"abu-simbel",
		"hurghada",
		"el-gouna",
		"marsa-alam",
		"sharm-el-sheikh",
		"dahab",
		"saint-catherine",
		"siwa",
		"fayoum",
		"bahariya-oasis",
		"white-desert",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Egypt up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Pyramids of Giza",
		"Great Sphinx of Giza",
		"Grand Egyptian Museum",
		"Egyptian Museum",
		"Khan El Khalili Bazaar",
		"Citadel of Qaitbay",
		"Bibliotheca Alexandrina",
		"Karnak Temple",
		"Valley of the Kings",
		"Luxor Temple",
		"Philae Temple",
		"Abu Simbel Temples",
		"Giftun Islands",
		"El Gouna Marina",
		"Ras Mohammed National Park",
		"Blue Hole Dahab",
		"Saint Catherine Monastery",
		"Siwa Oasis",
		"Wadi El Hitan",
		"White Desert National Park",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Egypt up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Egypt up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['egypt', city_id") {
		t.Fatalf("Egypt up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "egypt-seed-v1") || !strings.Contains(downSQL, "country_code = 'EG'") {
		t.Fatalf("Egypt down migration must remove only tagged Egypt seed places")
	}
}

func TestMalaysiaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "036_seed_malaysia_priority_places.up.sql")
	downSQL := readMigration(t, "036_seed_malaysia_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_malaysia_resolved_places AS",
		"'MY'",
		"malaysia-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Malaysia up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"kuala-lumpur",
		"putrajaya",
		"selangor",
		"george-town",
		"penang",
		"langkawi",
		"melaka",
		"ipoh",
		"cameron-highlands",
		"kota-kinabalu",
		"sandakan",
		"semporna",
		"kuching",
		"miri",
		"johor-bahru",
		"desaru",
		"tioman",
		"perhentian-islands",
		"redang",
		"kuala-terengganu",
		"kuantan",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Malaysia up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Petronas Twin Towers",
		"Batu Caves",
		"Putrajaya Mosque",
		"George Town UNESCO Heritage Core",
		"Penang Hill",
		"Langkawi Sky Bridge",
		"Jonker Street Night Market",
		"A Famosa",
		"Kellie's Castle",
		"Cameron BOH Tea Centre",
		"Kinabalu Park",
		"Sepilok Orangutan Rehabilitation Centre",
		"Sipadan Island",
		"Sarawak Cultural Village",
		"Gunung Mulu National Park",
		"LEGOLAND Malaysia",
		"Desaru Coast Adventure Waterpark",
		"Tioman Island",
		"Perhentian Islands",
		"Redang Island",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Malaysia up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Malaysia up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['malaysia', city_id") {
		t.Fatalf("Malaysia up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "malaysia-seed-v1") || !strings.Contains(downSQL, "country_code = 'MY'") {
		t.Fatalf("Malaysia down migration must remove only tagged Malaysia seed places")
	}
}

func TestSriLankaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "037_seed_sri_lanka_priority_places.up.sql")
	downSQL := readMigration(t, "037_seed_sri_lanka_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_sri_lanka_resolved_places AS",
		"'LK'",
		"sri-lanka-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Sri Lanka up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"colombo",
		"negombo",
		"mount-lavinia",
		"kandy",
		"sigiriya",
		"dambulla",
		"anuradhapura",
		"polonnaruwa",
		"galle",
		"unawatuna",
		"mirissa",
		"bentota",
		"hikkaduwa",
		"ella",
		"nuwara-eliya",
		"haputale",
		"adams-peak",
		"yala",
		"udawalawe",
		"wilpattu",
		"trincomalee",
		"arugam-bay",
		"jaffna",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Sri Lanka up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Sigiriya Rock Fortress",
		"Temple of the Sacred Tooth Relic",
		"Dambulla Cave Temple",
		"Ancient City of Anuradhapura",
		"Polonnaruwa Ancient City",
		"Galle Fort",
		"Pettah Market",
		"Gangaramaya Temple",
		"Colombo National Museum",
		"Yala National Park",
		"Udawalawe National Park",
		"Nine Arches Bridge",
		"Little Adam's Peak",
		"Nuwara Eliya Tea Country",
		"Mirissa Beach",
		"Unawatuna Beach",
		"Bentota Beach",
		"Hikkaduwa Coral Sanctuary",
		"Arugam Bay",
		"Jaffna Fort",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Sri Lanka up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Sri Lanka up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['sri-lanka', city_id") {
		t.Fatalf("Sri Lanka up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "sri-lanka-seed-v1") || !strings.Contains(downSQL, "country_code = 'LK'") {
		t.Fatalf("Sri Lanka down migration must remove only tagged Sri Lanka seed places")
	}
}

func TestMontenegroPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "038_seed_montenegro_priority_places.up.sql")
	downSQL := readMigration(t, "038_seed_montenegro_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_montenegro_resolved_places AS",
		"'ME'",
		"montenegro-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Montenegro up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"podgorica",
		"cetinje",
		"lovcen",
		"virpazar",
		"ostrog",
		"niksic",
		"kotor",
		"perast",
		"tivat",
		"herceg-novi",
		"risan",
		"budva",
		"becici",
		"sveti-stefan",
		"petrovac",
		"bar",
		"ulcinj",
		"ada-bojana",
		"zabljak",
		"durmitor",
		"kolasin",
		"biogradska-gora",
		"plav",
		"gusinje",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Montenegro up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Kotor Old Town",
		"Bay of Kotor",
		"Our Lady of the Rocks",
		"Porto Montenegro",
		"Budva Old Town",
		"Sveti Stefan",
		"Mogren Beach",
		"Jaz Beach",
		"Kotor Cable Car",
		"Lovcen National Park",
		"Njegos Mausoleum",
		"Ostrog Monastery",
		"Lake Skadar National Park",
		"Durmitor National Park",
		"Black Lake",
		"Tara Bridge",
		"Biogradska Gora National Park",
		"Prokletije National Park",
		"Old Bar",
		"Ulcinj Old Town",
		"Velika Plaza",
		"Ada Bojana",
		"Mall of Montenegro",
		"Cetinje Monastery",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Montenegro up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Montenegro up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['montenegro', city_id") {
		t.Fatalf("Montenegro up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "montenegro-seed-v1") || !strings.Contains(downSQL, "country_code = 'ME'") {
		t.Fatalf("Montenegro down migration must remove only tagged Montenegro seed places")
	}
}

func TestIndiaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "039_seed_india_priority_places.up.sql")
	downSQL := readMigration(t, "039_seed_india_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_india_resolved_places AS",
		"'IN'",
		"'INR'",
		"india-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("India up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"delhi",
		"agra",
		"jaipur",
		"varanasi",
		"amritsar",
		"mumbai",
		"goa",
		"udaipur",
		"jodhpur",
		"ahmedabad",
		"pune",
		"bengaluru",
		"chennai",
		"kochi",
		"mysuru",
		"hyderabad",
		"hampi",
		"munnar",
		"alappuzha",
		"kovalam",
		"kolkata",
		"darjeeling",
		"shillong",
		"guwahati",
		"gangtok",
		"rishikesh",
		"haridwar",
		"manali",
		"leh",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("India up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Taj Mahal",
		"Agra Fort",
		"Red Fort",
		"Qutub Minar",
		"Humayun's Tomb",
		"India Gate",
		"Jama Masjid",
		"Chandni Chowk",
		"Jaipur City Palace",
		"Hawa Mahal",
		"Amber Fort",
		"Jantar Mantar Jaipur",
		"Varanasi Ghats",
		"Kashi Vishwanath Temple",
		"Golden Temple",
		"Gateway of India",
		"Chhatrapati Shivaji Maharaj Terminus",
		"Elephanta Caves",
		"Colaba Causeway",
		"Baga Beach",
		"Anjuna Flea Market",
		"Dudhsagar Falls",
		"City Palace Udaipur",
		"Mehrangarh Fort",
		"Sabarmati Ashram",
		"Mysore Palace",
		"Hampi Group of Monuments",
		"Charminar",
		"Fort Kochi",
		"Alleppey Backwaters",
		"Victoria Memorial",
		"Darjeeling Himalayan Railway",
		"Umiam Lake",
		"Kamakhya Temple",
		"Rishikesh Ganga Aarti",
		"Manali Mall Road",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("India up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("India up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['india', city_id") {
		t.Fatalf("India up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "india-seed-v1") || !strings.Contains(downSQL, "country_code = 'IN'") {
		t.Fatalf("India down migration must remove only tagged India seed places")
	}
}

func TestMaltaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "040_seed_malta_priority_places.up.sql")
	downSQL := readMigration(t, "040_seed_malta_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_malta_resolved_places AS",
		"'MT'",
		"'EUR'",
		"malta-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Malta up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"valletta",
		"sliema",
		"st-julians",
		"birgu",
		"mdina",
		"rabat-malta",
		"mosta",
		"dingli",
		"mellieha",
		"st-pauls-bay",
		"marsaxlokk",
		"birzebbuga",
		"qrendi",
		"paola",
		"tarxien",
		"gozo",
		"victoria-gozo",
		"xaghra",
		"xlendi",
		"marsalforn",
		"comino",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Malta up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"St John's Co-Cathedral",
		"Upper Barrakka Gardens",
		"Grand Master's Palace",
		"National Museum of Archaeology",
		"Valletta Waterfront",
		"The Point Shopping Mall",
		"Spinola Bay",
		"Paceville",
		"Fort St Angelo",
		"Mdina Silent City",
		"St Paul's Catacombs",
		"Mosta Rotunda",
		"Dingli Cliffs",
		"Golden Bay",
		"Popeye Village",
		"Malta National Aquarium",
		"Marsaxlokk Fish Market",
		"Blue Grotto",
		"Hagar Qim Temples",
		"Mnajdra Temples",
		"Hypogeum of Hal Saflieni",
		"Tarxien Temples",
		"Ggantija Temples",
		"The Citadel Gozo",
		"Ramla Bay",
		"Dwejra Bay",
		"Blue Lagoon",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Malta up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Malta up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['malta', city_id") {
		t.Fatalf("Malta up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "malta-seed-v1") || !strings.Contains(downSQL, "country_code = 'MT'") {
		t.Fatalf("Malta down migration must remove only tagged Malta seed places")
	}
}

func TestCyprusPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "041_seed_cyprus_priority_places.up.sql")
	downSQL := readMigration(t, "041_seed_cyprus_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_cyprus_resolved_places AS",
		"'CY'",
		"'EUR'",
		"cyprus-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Cyprus up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"nicosia",
		"limassol",
		"larnaca",
		"paphos",
		"ayia-napa",
		"protaras",
		"paralimni",
		"famagusta",
		"kyrenia",
		"troodos",
		"platres",
		"kakopetria",
		"omodos",
		"polis",
		"latchi",
		"coral-bay",
		"peyia",
		"kourion",
		"choirokoitia",
		"agros",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Cyprus up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Paphos Archaeological Park",
		"Tombs of the Kings",
		"Aphrodite's Rock",
		"Kato Paphos Harbour",
		"Nissi Beach",
		"Cape Greco",
		"Fig Tree Bay",
		"Larnaca Salt Lake",
		"Church of Saint Lazarus",
		"Finikoudes Beach",
		"Limassol Marina",
		"Limassol Castle",
		"Kourion Archaeological Site",
		"Kolossi Castle",
		"Troodos Mountains",
		"Kykkos Monastery",
		"Omodos Village",
		"Ledra Street",
		"Cyprus Museum",
		"Buyuk Han",
		"Famagusta Walled City",
		"Kyrenia Harbour",
		"Bellapais Abbey",
		"Choirokoitia",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Cyprus up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Cyprus up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['cyprus', city_id") {
		t.Fatalf("Cyprus up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "cyprus-seed-v1") || !strings.Contains(downSQL, "country_code = 'CY'") {
		t.Fatalf("Cyprus down migration must remove only tagged Cyprus seed places")
	}
}

func TestSeychellesPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "042_seed_seychelles_priority_places.up.sql")
	downSQL := readMigration(t, "042_seed_seychelles_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_seychelles_resolved_places AS",
		"'SC'",
		"'SCR'",
		"seychelles-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Seychelles up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"victoria",
		"beau-vallon",
		"eden-island",
		"port-glaud",
		"anse-royale",
		"takamaka",
		"mahe",
		"praslin",
		"baie-sainte-anne",
		"grand-anse-praslin",
		"la-digue",
		"anse-reunion",
		"la-passe",
		"curieuse-island",
		"cousin-island",
		"silhouette-island",
		"sainte-anne-island",
		"moyenne-island",
		"cerf-island",
		"felicite-island",
		"ile-cocos",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Seychelles up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Sir Selwyn Selwyn-Clarke Market",
		"Seychelles National Botanical Garden",
		"Seychelles National Museum of History",
		"Beau Vallon Beach",
		"Morne Seychellois National Park",
		"Copolia Trail",
		"Mission Lodge",
		"Eden Plaza",
		"Anse Royale Beach",
		"Jardin du Roi Spice Garden",
		"Anse Intendance",
		"Vallee de Mai Nature Reserve",
		"Anse Lazio",
		"Anse Georgette",
		"Curieuse Marine National Park",
		"Cousin Island Special Reserve",
		"L'Union Estate",
		"Anse Source d'Argent",
		"Grand Anse La Digue",
		"Anse Cocos",
		"Nid d'Aigle",
		"Ile Cocos Marine National Park",
		"Sainte Anne Marine National Park",
		"Moyenne Island National Park",
		"Silhouette National Park",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Seychelles up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Seychelles up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['seychelles', city_id") {
		t.Fatalf("Seychelles up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "seychelles-seed-v1") || !strings.Contains(downSQL, "country_code = 'SC'") {
		t.Fatalf("Seychelles down migration must remove only tagged Seychelles seed places")
	}
}

func TestPolandPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "043_seed_poland_priority_places.up.sql")
	downSQL := readMigration(t, "043_seed_poland_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_poland_resolved_places AS",
		"'PL'",
		"'PLN'",
		"poland-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Poland up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"warsaw",
		"krakow",
		"wieliczka",
		"oswiecim",
		"zakopane",
		"gdansk",
		"sopot",
		"gdynia",
		"malbork",
		"torun",
		"wroclaw",
		"poznan",
		"lodz",
		"katowice",
		"chorzow",
		"lublin",
		"bialowieza",
		"bialystok",
		"czestochowa",
		"zamosc",
		"szczecin",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Poland up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Warsaw Old Town",
		"Royal Castle in Warsaw",
		"Lazienki Park",
		"POLIN Museum",
		"Palace of Culture and Science",
		"Hala Koszyki",
		"Zlote Tarasy",
		"Krakow Main Market Square",
		"Wawel Royal Castle",
		"Kazimierz",
		"Wieliczka Salt Mine",
		"Auschwitz-Birkenau Memorial and Museum",
		"Morskie Oko",
		"Gdansk Old Town",
		"European Solidarity Centre",
		"Sopot Pier",
		"Malbork Castle",
		"Torun Old Town",
		"Wroclaw Market Square",
		"Centennial Hall",
		"Poznan Old Market Square",
		"Manufaktura Lodz",
		"Nikiszowiec",
		"Jasna Gora Monastery",
		"Bialowieza National Park",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Poland up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Poland up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['poland', city_id") {
		t.Fatalf("Poland up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "poland-seed-v1") || !strings.Contains(downSQL, "country_code = 'PL'") {
		t.Fatalf("Poland down migration must remove only tagged Poland seed places")
	}
}

func TestMexicoPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "044_seed_mexico_priority_places.up.sql")
	downSQL := readMigration(t, "044_seed_mexico_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_mexico_resolved_places AS",
		"'MX'",
		"'MXN'",
		"mexico-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Mexico up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"mexico-city",
		"teotihuacan",
		"puebla",
		"cholula",
		"cancun",
		"isla-mujeres",
		"playa-del-carmen",
		"tulum",
		"cozumel",
		"merida",
		"valladolid",
		"chichen-itza",
		"uxmal",
		"los-cabos",
		"cabo-san-lucas",
		"la-paz-mexico",
		"puerto-vallarta",
		"sayulita",
		"mazatlan",
		"acapulco",
		"guadalajara",
		"tequila",
		"guanajuato",
		"san-miguel-de-allende",
		"queretaro",
		"oaxaca",
		"monte-alban",
		"san-cristobal-de-las-casas",
		"palenque",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Mexico up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Mexico City Historic Center",
		"Palacio de Bellas Artes",
		"Chapultepec Park",
		"National Museum of Anthropology",
		"Frida Kahlo Museum",
		"Xochimilco",
		"Teotihuacan",
		"Puebla Historic Center",
		"Chichen Itza",
		"Tulum Archaeological Zone",
		"Cancun Hotel Zone Beaches",
		"Isla Mujeres Playa Norte",
		"Xcaret Park",
		"Cozumel Reefs",
		"Uxmal",
		"Merida Historic Center",
		"Los Cabos Arch",
		"Balandra Beach",
		"Puerto Vallarta Malecon",
		"Guadalajara Cathedral",
		"Tequila Town",
		"Guanajuato Historic Center",
		"San Miguel de Allende",
		"Oaxaca Historic Center",
		"Monte Alban",
		"Palenque Archaeological Zone",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Mexico up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Mexico up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['mexico', city_id") {
		t.Fatalf("Mexico up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "mexico-seed-v1") || !strings.Contains(downSQL, "country_code = 'MX'") {
		t.Fatalf("Mexico down migration must remove only tagged Mexico seed places")
	}
}

func TestBrazilPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "045_seed_brazil_priority_places.up.sql")
	downSQL := readMigration(t, "045_seed_brazil_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_brazil_resolved_places AS",
		"'BR'",
		"'BRL'",
		"brazil-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Brazil up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"rio-de-janeiro",
		"petropolis",
		"paraty",
		"buzios",
		"angra-dos-reis",
		"sao-paulo",
		"santos",
		"curitiba",
		"florianopolis",
		"foz-do-iguacu",
		"gramado",
		"porto-alegre",
		"salvador",
		"recife",
		"olinda",
		"porto-de-galinhas",
		"natal",
		"pipa",
		"fortaleza",
		"jericoacoara",
		"sao-luis",
		"lencois-maranhenses",
		"manaus",
		"belem",
		"brasilia",
		"bonito",
		"pantanal",
		"cuiaba",
		"chapada-dos-veadeiros",
		"ouro-preto",
		"belo-horizonte",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Brazil up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Christ the Redeemer",
		"Sugarloaf Mountain",
		"Ipanema Beach",
		"Copacabana Beach",
		"Museum of Tomorrow",
		"Ibirapuera Park",
		"MASP",
		"Municipal Market of Sao Paulo",
		"Iguazu Falls",
		"Botanical Garden of Curitiba",
		"Joaquina Beach",
		"Pelourinho",
		"Mercado Modelo Salvador",
		"Recife Antigo",
		"Olinda Historic Center",
		"Porto de Galinhas Natural Pools",
		"Jericoacoara National Park",
		"Lencois Maranhenses National Park",
		"Amazon Theatre",
		"Ver-o-Peso Market",
		"Brasilia Cathedral",
		"Bonito Blue Lake Cave",
		"Pantanal",
		"Ouro Preto Historic Center",
		"Inhotim",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Brazil up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Brazil up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['brazil', city_id") {
		t.Fatalf("Brazil up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "brazil-seed-v1") || !strings.Contains(downSQL, "country_code = 'BR'") {
		t.Fatalf("Brazil down migration must remove only tagged Brazil seed places")
	}
}

func TestArgentinaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "059_seed_argentina_priority_places.up.sql")
	downSQL := readMigration(t, "059_seed_argentina_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_argentina_resolved_places AS",
		"'AR'",
		"'ARS'",
		"argentina-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Argentina up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"buenos-aires",
		"la-plata",
		"tigre",
		"mar-del-plata",
		"bariloche",
		"el-calafate",
		"el-chalten",
		"ushuaia",
		"puerto-madryn",
		"peninsula-valdes",
		"puerto-iguazu",
		"iguazu-falls",
		"posadas",
		"corrientes",
		"esteros-del-ibera",
		"rosario",
		"salta",
		"jujuy",
		"purmamarca",
		"tilcara",
		"humahuaca",
		"cafayate",
		"tucuman",
		"mendoza",
		"san-rafael",
		"uspallata",
		"aconcagua",
		"cordoba-argentina",
		"villa-carlos-paz",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Argentina up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Teatro Colon",
		"Recoleta Cemetery",
		"Caminito La Boca",
		"San Telmo Market",
		"Puerto Madero Waterfront",
		"Tigre Delta",
		"Mar del Plata Central Beach",
		"Perito Moreno Glacier",
		"Mount Fitz Roy",
		"Nahuel Huapi National Park",
		"End of the World Train",
		"Peninsula Valdes",
		"Iguazu Falls",
		"Ibera Wetlands",
		"Independence Park Rosario",
		"Salta Cathedral",
		"Quebrada de Humahuaca",
		"Hill of Seven Colors",
		"Cafayate Wineries",
		"'Aconcagua Provincial Park'",
		"Mendoza Wine Route",
		"Atuel Canyon",
		"Cordoba Jesuit Block",
		"Villa Carlos Paz Cuckoo Clock",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Argentina up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Argentina up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['argentina', city_id") {
		t.Fatalf("Argentina up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "argentina-seed-v1") || !strings.Contains(downSQL, "country_code = 'AR'") {
		t.Fatalf("Argentina down migration must remove only tagged Argentina seed places")
	}
}

func TestSwitzerlandPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "060_seed_switzerland_priority_places.up.sql")
	downSQL := readMigration(t, "060_seed_switzerland_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_switzerland_resolved_places AS",
		"'CH'",
		"'CHF'",
		"switzerland-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Switzerland up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"zurich",
		"lucerne",
		"basel",
		"schaffhausen",
		"bern",
		"interlaken",
		"grindelwald",
		"lauterbrunnen",
		"jungfraujoch",
		"thun",
		"geneva",
		"lausanne",
		"montreux",
		"vevey",
		"gruyeres",
		"zermatt",
		"lugano",
		"locarno",
		"bellinzona",
		"ascona",
		"st-moritz",
		"davos",
		"chur",
		"swiss-national-park",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Switzerland up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Kunsthaus Zurich",
		"Lake Zurich Promenade",
		"Chapel Bridge",
		"Lion Monument",
		"Rhine Falls",
		"Basel Minster",
		"Bern Old City",
		"Zytglogge Clock Tower",
		"Jungfraujoch Top of Europe",
		"Grindelwald-First",
		"Lauterbrunnen Valley",
		"Lake Thun",
		"Jet d Eau",
		"Palais des Nations",
		"Olympic Museum",
		"Chillon Castle",
		"Chaplins World",
		"Gruyeres Castle",
		"Matterhorn",
		"Gornergrat Railway",
		"Lake Lugano",
		"Monte San Salvatore",
		"Three Castles of Bellinzona",
		"St Moritz Lake",
		"Swiss National Park",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Switzerland up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Switzerland up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['switzerland', city_id") {
		t.Fatalf("Switzerland up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "switzerland-seed-v1") || !strings.Contains(downSQL, "country_code = 'CH'") {
		t.Fatalf("Switzerland down migration must remove only tagged Switzerland seed places")
	}
}

func TestSwedenPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "061_seed_sweden_priority_places.up.sql")
	downSQL := readMigration(t, "061_seed_sweden_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_sweden_resolved_places AS",
		"'SE'",
		"'SEK'",
		"sweden-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Sweden up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"stockholm",
		"uppsala",
		"sigtuna",
		"drottningholm",
		"gothenburg",
		"malmo",
		"lund",
		"helsingborg",
		"kiruna",
		"abisko",
		"jukkasjarvi",
		"lulea",
		"umea",
		"visby",
		"kalmar",
		"vaxjo",
		"karlskrona",
		"oland",
		"orebro",
		"linkoping",
		"norrkoping",
		"vasteras",
		"jonkoping",
		"falun",
		"mora",
		"are",
		"ostersund",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Sweden up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Vasa Museum",
		"Stockholm Old Town Gamla Stan",
		"Skansen Open-Air Museum",
		"ABBA The Museum",
		"Fotografiska Stockholm",
		"Drottningholm Palace",
		"Uppsala Cathedral",
		"Liseberg Amusement Park",
		"Universeum",
		"Feskekorka",
		"Turning Torso",
		"Malmo Saluhall",
		"Lund Cathedral",
		"Karnan Helsingborg",
		"Kiruna Church",
		"Abisko National Park",
		"ICEHOTEL Jukkasjarvi",
		"Gammelstad Church Town",
		"Visby City Wall",
		"Kalmar Castle",
		"Karlskrona Naval Museum",
		"Borgholm Castle",
		"Orebro Castle",
		"Falun Copper Mine",
		"Vasa Ski Museum",
		"Are Ski Resort",
		"Jamtli Museum",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Sweden up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Sweden up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['sweden', city_id") {
		t.Fatalf("Sweden up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "sweden-seed-v1") || !strings.Contains(downSQL, "country_code = 'SE'") {
		t.Fatalf("Sweden down migration must remove only tagged Sweden seed places")
	}
}

func TestCzechiaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "062_seed_czechia_priority_places.up.sql")
	downSQL := readMigration(t, "062_seed_czechia_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_czechia_resolved_places AS",
		"'CZ'",
		"'CZK'",
		"czechia-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Czechia up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"prague",
		"karlstejn",
		"kutna-hora",
		"brno",
		"lednice-valtice",
		"mikulov",
		"moravian-karst",
		"cesky-krumlov",
		"ceske-budejovice",
		"sumava",
		"telc",
		"trebic",
		"karlovy-vary",
		"marianske-lazne",
		"plzen",
		"litomysl",
		"olomouc",
		"ostrava",
		"liberec",
		"hradec-kralove",
		"pardubice",
		"bohemian-switzerland",
		"cesky-raj",
		"krkonose",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Czechia up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Prague Castle",
		"Charles Bridge",
		"Old Town Square",
		"Prague Astronomical Clock",
		"St Vitus Cathedral",
		"Prague Zoo",
		"Karlstejn Castle",
		"St Barbara Cathedral",
		"Sedlec Ossuary",
		"Spilberk Castle",
		"Villa Tugendhat",
		"Lednice Castle",
		"Punkva Caves",
		"Cesky Krumlov Castle",
		"Cesky Krumlov Old Town",
		"Mill Colonnade Karlovy Vary",
		"Hot Spring Colonnade",
		"Pilsner Urquell Brewery",
		"Holy Trinity Column Olomouc",
		"Lower Vitkovice",
		"Jested Tower",
		"Pravcicka Gate",
		"Prachov Rocks",
		"Snezka Mountain",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Czechia up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Czechia up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['czechia', city_id") {
		t.Fatalf("Czechia up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "czechia-seed-v1") || !strings.Contains(downSQL, "country_code = 'CZ'") {
		t.Fatalf("Czechia down migration must remove only tagged Czechia seed places")
	}
}

func TestFrancePriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "063_seed_france_priority_places.up.sql")
	downSQL := readMigration(t, "063_seed_france_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_france_resolved_places AS",
		"'FR'",
		"'EUR'",
		"france-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("France up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"paris",
		"versailles",
		"fontainebleau",
		"disneyland-paris",
		"loire-valley",
		"mont-saint-michel",
		"normandy",
		"saint-malo",
		"rennes",
		"nantes",
		"bordeaux",
		"dordogne",
		"toulouse",
		"carcassonne",
		"montpellier",
		"biarritz",
		"lourdes",
		"pyrenees",
		"lyon",
		"dijon",
		"beaune",
		"strasbourg",
		"colmar",
		"reims",
		"lille",
		"nice",
		"cannes",
		"antibes",
		"saint-tropez",
		"marseille",
		"aix-en-provence",
		"avignon",
		"arles",
		"verdon",
		"chamonix",
		"annecy",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("France up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Eiffel Tower",
		"Louvre Museum",
		"Notre-Dame Cathedral",
		"Luxembourg Gardens",
		"Palace of Versailles",
		"Disneyland Paris",
		"Mont Saint-Michel Abbey",
		"Omaha Beach",
		"Chambord Castle",
		"Chenonceau Castle",
		"Nice Promenade des Anglais",
		"Palais des Festivals Cannes",
		"Old Port of Marseille",
		"Mucem Marseille",
		"Palais des Papes Avignon",
		"Calanques National Park",
		"Verdon Gorge",
		"Aiguille du Midi",
		"Annecy Old Town",
		"Basilica of Notre-Dame de Fourviere",
		"Les Halles de Lyon Paul Bocuse",
		"La Cite du Vin",
		"Place de la Bourse Bordeaux",
		"Dune du Pilat",
		"Carcassonne Medieval City",
		"Strasbourg Cathedral",
		"Colmar Old Town",
		"Reims Cathedral",
		"Lille Grand Place",
		"Hospices de Beaune",
		"Lourdes Sanctuary",
		"Biarritz Grande Plage",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("France up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("France up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['france', city_id") {
		t.Fatalf("France up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "france-seed-v1") || !strings.Contains(downSQL, "country_code = 'FR'") {
		t.Fatalf("France down migration must remove only tagged France seed places")
	}
}

func TestUnitedKingdomPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "064_seed_united_kingdom_priority_places.up.sql")
	downSQL := readMigration(t, "064_seed_united_kingdom_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_united_kingdom_resolved_places AS",
		"'GB'",
		"'GBP'",
		"united-kingdom-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("United Kingdom up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"london",
		"windsor",
		"oxford",
		"cambridge",
		"bath",
		"bristol",
		"cotswolds",
		"stonehenge",
		"salisbury",
		"brighton",
		"canterbury",
		"bournemouth",
		"jurassic-coast",
		"cornwall",
		"devon",
		"stratford-upon-avon",
		"york",
		"manchester",
		"liverpool",
		"birmingham",
		"lake-district",
		"peak-district",
		"newcastle",
		"leeds",
		"edinburgh",
		"glasgow",
		"inverness",
		"highlands",
		"isle-of-skye",
		"loch-ness",
		"aberdeen",
		"st-andrews",
		"cardiff",
		"snowdonia",
		"conwy",
		"pembrokeshire",
		"belfast",
		"giants-causeway",
		"derry",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("United Kingdom up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Big Ben and Palace of Westminster",
		"Tower of London",
		"British Museum",
		"Hyde Park",
		"Borough Market",
		"Camden Market",
		"Westfield London",
		"Warner Bros Studio Tour London",
		"Windsor Castle",
		"Stonehenge",
		"Roman Baths",
		"Oxford University and Bodleian Library",
		"King''s College Chapel Cambridge",
		"Brighton Palace Pier",
		"Canterbury Cathedral",
		"Jurassic Coast",
		"Eden Project",
		"York Minster",
		"National Railway Museum York",
		"Science and Industry Museum Manchester",
		"Liverpool Albert Dock",
		"The Beatles Story",
		"Bullring Birmingham",
		"Lake District National Park",
		"Peak District National Park",
		"Edinburgh Castle",
		"National Museum of Scotland",
		"Arthur''s Seat",
		"Kelvingrove Art Gallery and Museum",
		"Loch Ness",
		"Old Man of Storr",
		"Eilean Donan Castle",
		"Cardiff Castle",
		"Eryri Snowdonia National Park",
		"Conwy Castle",
		"Pembrokeshire Coast National Park",
		"Titanic Belfast",
		"Giant''s Causeway",
		"Derry City Walls",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("United Kingdom up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("United Kingdom up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['united-kingdom', city_id") {
		t.Fatalf("United Kingdom up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "united-kingdom-seed-v1") || !strings.Contains(downSQL, "country_code = 'GB'") {
		t.Fatalf("United Kingdom down migration must remove only tagged United Kingdom seed places")
	}
}

func TestUzbekistanPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "065_seed_uzbekistan_priority_places.up.sql")
	downSQL := readMigration(t, "065_seed_uzbekistan_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_uzbekistan_resolved_places AS",
		"'UZ'",
		"'UZS'",
		"uzbekistan-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Uzbekistan up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"tashkent",
		"samarkand",
		"bukhara",
		"khiva",
		"urgench",
		"nukus",
		"muynak",
		"aral-sea",
		"fergana",
		"margilan",
		"kokand",
		"rishtan",
		"andijan",
		"namangan",
		"chimgan",
		"charvak",
		"shahrisabz",
		"termez",
		"navoi",
		"nurata",
		"zaamin",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Uzbekistan up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Amir Timur Square",
		"Chorsu Bazaar",
		"Hazrati Imam Complex",
		"Tashkent Metro",
		"Magic City Tashkent",
		"Tashkent City Mall",
		"Central Asian Plov Center",
		"Chimgan Mountains",
		"Charvak Reservoir Beaches",
		"Registan Square",
		"Shah-i-Zinda",
		"Bibi-Khanym Mosque",
		"Siab Bazaar",
		"Gur-e-Amir Mausoleum",
		"Ark of Bukhara",
		"Poi Kalyan Complex",
		"Lyabi-Hauz",
		"Chor Minor",
		"Bukhara Trading Domes",
		"Itchan Kala",
		"Kalta Minor Minaret",
		"Kunya-Ark Citadel",
		"Juma Mosque Khiva",
		"Savitsky Museum",
		"Moynaq Ship Cemetery",
		"Aral Sea",
		"Margilan Yodgorlik Silk Factory",
		"Palace of Khudayar Khan",
		"Rishtan Ceramic Workshops",
		"Babur Literary Museum",
		"Namangan Flowers Garden",
		"Ak-Saray Palace",
		"Termez Archaeological Museum",
		"Fayaztepa Buddhist Monastery",
		"Sarmishsay Petroglyphs",
		"Nuratau Mountains",
		"Zaamin National Park",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Uzbekistan up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Uzbekistan up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['uzbekistan', city_id") {
		t.Fatalf("Uzbekistan up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "uzbekistan-seed-v1") || !strings.Contains(downSQL, "country_code = 'UZ'") {
		t.Fatalf("Uzbekistan down migration must remove only tagged Uzbekistan seed places")
	}
}

func TestKyrgyzstanPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "066_seed_kyrgyzstan_priority_places.up.sql")
	downSQL := readMigration(t, "066_seed_kyrgyzstan_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kyrgyzstan_resolved_places AS",
		"'KG'",
		"'KGS'",
		"kyrgyzstan-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Kyrgyzstan up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"bishkek",
		"ala-archa",
		"tokmok",
		"chunkurchak",
		"issyk-ata",
		"cholpon-ata",
		"balykchy",
		"karakol",
		"jeti-oguz",
		"barskoon",
		"skazka-canyon",
		"bokonbaevo",
		"tamga",
		"kaji-say",
		"naryn",
		"kochkor",
		"song-kul",
		"tash-rabat",
		"kel-suu",
		"at-bashy",
		"osh",
		"uzgen",
		"jalal-abad",
		"arslanbob",
		"sary-chelek",
		"talas",
		"toktogul",
		"suusamyr",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Kyrgyzstan up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Ala-Too Square",
		"State History Museum Bishkek",
		"Osh Bazaar Bishkek",
		"Dordoi Bazaar",
		"Bishkek Park Mall",
		"Supara Ethno Complex",
		"Ala Archa National Park",
		"Burana Tower",
		"Chunkurchak Gorge",
		"Issyk-Ata Gorge",
		"Issyk-Kul Lake",
		"Rukh Ordo Cultural Center",
		"Cholpon-Ata Petroglyphs",
		"Kaji-Say Beach",
		"Holy Trinity Cathedral Karakol",
		"Dungan Mosque Karakol",
		"Jeti-Oguz Rocks",
		"Barskoon Waterfalls",
		"Skazka Fairy Tale Canyon",
		"Song-Kul Lake",
		"Tash Rabat Caravanserai",
		"Kel-Suu Lake",
		"Kochkor Felt Workshops",
		"Sulaiman-Too Sacred Mountain",
		"Jayma Bazaar Osh",
		"Uzgen Minaret",
		"Arslanbob Walnut Forest",
		"Sary-Chelek Biosphere Reserve",
		"Manas Ordo Complex",
		"Toktogul Reservoir",
		"Suusamyr Valley",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Kyrgyzstan up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Kyrgyzstan up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['kyrgyzstan', city_id") {
		t.Fatalf("Kyrgyzstan up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "kyrgyzstan-seed-v1") || !strings.Contains(downSQL, "country_code = 'KG'") {
		t.Fatalf("Kyrgyzstan down migration must remove only tagged Kyrgyzstan seed places")
	}
}

func TestAzerbaijanPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "067_seed_azerbaijan_priority_places.up.sql")
	downSQL := readMigration(t, "067_seed_azerbaijan_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_azerbaijan_resolved_places AS",
		"'AZ'",
		"'AZN'",
		"azerbaijan-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Azerbaijan up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"baku",
		"absheron",
		"gobustan",
		"mud-volcanoes",
		"shamakhi",
		"lahij",
		"quba",
		"qusar",
		"shahdag",
		"khinalig",
		"gabala",
		"sheki",
		"ganja",
		"goygol",
		"naftalan",
		"mingachevir",
		"lankaran",
		"astara",
		"masalli",
		"lerik",
		"hirkan",
		"gizil-agaj",
		"nakhchivan",
		"ordubad",
		"julfa",
		"batabat",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Azerbaijan up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Icherisheher Old City",
		"Maiden Tower Baku",
		"Palace of the Shirvanshahs",
		"Heydar Aliyev Center",
		"Azerbaijan Carpet Museum",
		"Baku Boulevard",
		"Port Baku Mall",
		"Taza Bazaar Baku",
		"Ateshgah Fire Temple",
		"Yanar Dag Burning Mountain",
		"Bilgah Beach",
		"Gobustan Rock Art Cultural Landscape",
		"Gobustan Mud Volcanoes",
		"Juma Mosque Shamakhi",
		"Lahij Copper Craft Quarter",
		"Shahdag Mountain Resort",
		"Khinalig Village",
		"Sheki Khan Palace",
		"Sheki Caravanserai",
		"Sheki Halva Workshop",
		"Gabala Tufandag Mountain Resort",
		"Gabaland Amusement Park",
		"Nohur Lake",
		"Nizami Mausoleum",
		"Goygol National Park",
		"Naftalan Oil Spa",
		"Mingachevir Reservoir",
		"Hirkan National Park",
		"Yanar Bulag",
		"Gizil-Agaj National Park",
		"Momine Khatun Mausoleum",
		"Alinja Castle",
		"Batabat Lake",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Azerbaijan up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Azerbaijan up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['azerbaijan', city_id") {
		t.Fatalf("Azerbaijan up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "azerbaijan-seed-v1") || !strings.Contains(downSQL, "country_code = 'AZ'") {
		t.Fatalf("Azerbaijan down migration must remove only tagged Azerbaijan seed places")
	}
}

func TestTajikistanPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "068_seed_tajikistan_priority_places.up.sql")
	downSQL := readMigration(t, "068_seed_tajikistan_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_tajikistan_resolved_places AS",
		"'TJ'",
		"'TJS'",
		"tajikistan-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Tajikistan up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"dushanbe",
		"hisor",
		"varzob",
		"safed-dara",
		"norak",
		"khujand",
		"guliston-qayraqqum",
		"istaravshan",
		"panjakent",
		"sarazm",
		"seven-lakes",
		"fann-mountains",
		"iskanderkul",
		"khorog",
		"garm-chashma",
		"ishkashim",
		"wakhan-valley",
		"yamchun",
		"langar",
		"bulunkul",
		"karakul",
		"murghab",
		"pamir-highway",
		"bokhtar",
		"vose-hulbuk",
		"kulob",
		"sari-khosor",
		"dusti",
		"shahrituz",
		"nosiri-khusrav",
		"qubodiyon",
		"muminobod",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Tajikistan up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Rudaki Park",
		"National Museum of Tajikistan",
		"Kokhi Navruz",
		"Mehrgon Bazaar",
		"Siyoma Mall",
		"Hisor Fortress",
		"Safed-Dara Ski Resort",
		"Nurek Reservoir",
		"Khujand Fortress Historical Complex",
		"Panjshanbe Bazaar",
		"Kok-Gumbaz Mosque Istaravshan",
		"Ancient Panjakent",
		"Proto-urban Site of Sarazm",
		"Seven Lakes Haft Kul",
		"Iskanderkul Lake",
		"Pamir Botanical Garden",
		"Khorog Bazaar",
		"Garm Chashma Hot Spring",
		"Wakhan Valley Road",
		"Yamchun Fortress",
		"Bibi Fatima Hot Springs",
		"Langar Petroglyphs",
		"Lake Karakul",
		"Pamir Highway Khorog to Murghab",
		"Ajina-Teppa Buddhist Monastery",
		"Hulbuk Fortress",
		"Mir Sayyid Ali Hamadani Mausoleum",
		"Tigrovaya Balka Nature Reserve",
		"Khoja Mashhad Mausoleum and Madrasa",
		"Chiluchor Chashma Springs",
		"Takhti Sangin Oxus Temple",
		"Childukhtaron Mountain",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Tajikistan up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Tajikistan up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['tajikistan', city_id") {
		t.Fatalf("Tajikistan up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "tajikistan-seed-v1") || !strings.Contains(downSQL, "country_code = 'TJ'") {
		t.Fatalf("Tajikistan down migration must remove only tagged Tajikistan seed places")
	}
}

func TestMongoliaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "069_seed_mongolia_priority_places.up.sql")
	downSQL := readMigration(t, "069_seed_mongolia_priority_places.down.sql")

	for _, fragment := range []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_mongolia_resolved_places AS",
		"'MN'",
		"'MNT'",
		"mongolia-seed-v1",
	} {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Mongolia up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"ulaanbaatar",
		"gorkhi-terelj",
		"tsonjin-boldog",
		"khustai",
		"kharkhorin",
		"orkhon-valley",
		"tuvkhun",
		"tsetserleg",
		"khorgo-terkhiin-tsagaan-nuur",
		"murun",
		"khuvsgul",
		"amarbayasgalant",
		"dalanzadgad",
		"yolyn-am",
		"khongoryn-els",
		"bayanzag",
		"tsagaan-suvarga",
		"baga-gazriin-chuluu",
		"sainshand",
		"khamaryn-khiid",
		"ulgii",
		"altai-tavan-bogd",
		"darkhan",
		"erdenet",
		"choibalsan",
		"khalkh-gol",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Mongolia up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Chinggis Khaan National Museum",
		"Gandantegchinlen Monastery",
		"Sukhbaatar Square",
		"Zaisan Memorial",
		"National Museum of Mongolia",
		"Choijin Lama Temple Museum",
		"Bogd Khaan Palace Museum",
		"Narantuul Market",
		"Shangri-La Mall Ulaanbaatar",
		"Gorkhi-Terelj National Park",
		"Chinggis Khaan Statue Complex",
		"Khustai National Park",
		"Erdene Zuu Monastery",
		"Karakorum Museum",
		"Orkhon Valley Cultural Landscape",
		"Tuvkhun Monastery",
		"Khorgo-Terkhiin Tsagaan Nuur National Park",
		"Khuvsgul Lake National Park",
		"Amarbayasgalant Monastery",
		"Yolyn Am Gorge",
		"Khongoryn Els Sand Dunes",
		"Bayanzag Flaming Cliffs",
		"Tsagaan Suvarga White Stupa",
		"Baga Gazriin Chuluu",
		"Khamaryn Khiid Monastery",
		"Altai Tavan Bogd National Park",
		"Khalkh Gol Memorial Complex",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Mongolia up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Mongolia up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Mongolia up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['mongolia', city_id") {
		t.Fatalf("Mongolia up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "mongolia-seed-v1") || !strings.Contains(downSQL, "country_code = 'MN'") {
		t.Fatalf("Mongolia down migration must remove only tagged Mongolia seed places")
	}
}

func TestIcelandPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "070_seed_iceland_priority_places.up.sql")
	downSQL := readMigration(t, "070_seed_iceland_priority_places.down.sql")

	for _, fragment := range []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_iceland_resolved_places AS",
		"'IS'",
		"'ISK'",
		"iceland-seed-v1",
	} {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Iceland up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"reykjavik",
		"kopavogur",
		"seltjarnarnes",
		"hafnarfjordur",
		"gardabaer",
		"mosfellsbaer",
		"thingvellir",
		"geysir",
		"gullfoss",
		"selfoss",
		"hveragerdi",
		"vik",
		"skogar",
		"seljalandsfoss",
		"jokulsarlon",
		"skaftafell",
		"snaefellsnes",
		"borgarnes",
		"stykkisholmur",
		"isafjordur",
		"latrabjarg",
		"akureyri",
		"husavik",
		"myvatn",
		"dettifoss",
		"egilsstadir",
		"seydisfjordur",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Iceland up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Hallgrimskirkja",
		"Harpa Concert Hall and Conference Centre",
		"Perlan - Wonders of Iceland",
		"Kolaportid Flea Market",
		"Sky Lagoon",
		"Thingvellir National Park",
		"Geysir Geothermal Area",
		"Gullfoss Waterfall",
		"Seljalandsfoss Waterfall",
		"Reynisfjara Black Sand Beach",
		"Jokulsarlon Glacier Lagoon",
		"Snaefellsjokull National Park",
		"Kirkjufell Mountain",
		"Dynjandi Waterfall",
		"Latrabjarg Cliffs",
		"Akureyri Church",
		"Husavik Whale Museum",
		"Lake Myvatn",
		"Dettifoss Waterfall",
		"Seydisfjordur Rainbow Street",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Iceland up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'", "'BEACH'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Iceland up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Iceland up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['iceland', city_id") {
		t.Fatalf("Iceland up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "iceland-seed-v1") || !strings.Contains(downSQL, "country_code = 'IS'") {
		t.Fatalf("Iceland down migration must remove only tagged Iceland seed places")
	}
}

func TestIrelandPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "071_seed_ireland_priority_places.up.sql")
	downSQL := readMigration(t, "071_seed_ireland_priority_places.down.sql")

	for _, fragment := range []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_ireland_resolved_places AS",
		"'IE'",
		"'EUR'",
		"ireland-seed-v1",
	} {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Ireland up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"dublin",
		"howth",
		"dun-laoghaire",
		"bray",
		"glendalough",
		"galway",
		"cliffs-of-moher",
		"burren",
		"connemara",
		"aran-islands",
		"westport",
		"achill",
		"cork",
		"cobh",
		"blarney",
		"kinsale",
		"killarney",
		"ring-of-kerry",
		"dingle",
		"waterford",
		"kilkenny",
		"cashel",
		"limerick",
		"sligo",
		"donegal",
		"letterkenny",
		"wexford",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Ireland up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Guinness Storehouse",
		"Book of Kells Experience, Trinity College Dublin",
		"Dublin Castle",
		"Kilmainham Gaol Museum",
		"Temple Bar Food Market",
		"Howth Cliff Path Loop",
		"Glendalough Monastic Site",
		"Cliffs of Moher",
		"Connemara National Park",
		"Galway Latin Quarter",
		"Keem Bay",
		"English Market Cork",
		"Blarney Castle and Gardens",
		"Killarney National Park",
		"Ring of Kerry",
		"Dingle Peninsula",
		"Waterford Viking Triangle",
		"Kilkenny Castle",
		"Rock of Cashel",
		"Slieve League Cliffs",
		"Hook Lighthouse",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Ireland up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'", "'BEACH'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Ireland up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Ireland up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['ireland', city_id") {
		t.Fatalf("Ireland up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "ireland-seed-v1") || !strings.Contains(downSQL, "country_code = 'IE'") {
		t.Fatalf("Ireland down migration must remove only tagged Ireland seed places")
	}
}

func TestNetherlandsPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "072_seed_netherlands_priority_places.up.sql")
	downSQL := readMigration(t, "072_seed_netherlands_priority_places.down.sql")

	for _, fragment := range []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_netherlands_resolved_places AS",
		"'NL'",
		"'EUR'",
		"netherlands-seed-v1",
	} {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Netherlands up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"amsterdam",
		"haarlem",
		"zaandam",
		"zaanse-schans",
		"volendam",
		"marken",
		"alkmaar",
		"zandvoort",
		"texel",
		"rotterdam",
		"the-hague",
		"scheveningen",
		"delft",
		"leiden",
		"utrecht",
		"gouda",
		"kinderdijk",
		"giethoorn",
		"groningen",
		"leeuwarden",
		"maastricht",
		"valkenburg",
		"eindhoven",
		"den-bosch",
		"kaatsheuvel",
		"arnhem",
		"hoge-veluwe",
		"nijmegen",
		"middelburg",
		"domburg",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Netherlands up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Rijksmuseum",
		"Van Gogh Museum",
		"Anne Frank House",
		"Canal Ring Amsterdam",
		"Vondelpark",
		"Albert Cuyp Market",
		"ARTIS Amsterdam Royal Zoo",
		"NEMO Science Museum",
		"Zaanse Schans",
		"Zandvoort Beach",
		"Texel Lighthouse",
		"Markthal Rotterdam",
		"Cube Houses Rotterdam",
		"Erasmus Bridge",
		"Mauritshuis",
		"Peace Palace",
		"Scheveningen Beach",
		"Royal Delft",
		"Dom Tower Utrecht",
		"Kinderdijk Windmills",
		"Giethoorn",
		"Efteling",
		"Van Abbemuseum",
		"Hoge Veluwe National Park",
		"Kroller-Muller Museum",
		"Vrijthof Maastricht",
		"Groninger Museum",
		"Fries Museum",
		"Domburg Beach",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Netherlands up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'", "'BEACH'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Netherlands up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Netherlands up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['netherlands', city_id") {
		t.Fatalf("Netherlands up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "netherlands-seed-v1") || !strings.Contains(downSQL, "country_code = 'NL'") {
		t.Fatalf("Netherlands down migration must remove only tagged Netherlands seed places")
	}
}

func TestBelarusPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "073_seed_belarus_priority_places.up.sql")
	downSQL := readMigration(t, "073_seed_belarus_priority_places.down.sql")

	for _, fragment := range []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_belarus_resolved_places AS",
		"'BY'",
		"'BYN'",
		"belarus-seed-v1",
	} {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Belarus up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"minsk",
		"mir",
		"nesvizh",
		"brest",
		"belovezhskaya-pushcha",
		"grodno",
		"lida",
		"pinsk",
		"vitebsk",
		"polotsk",
		"mogilev",
		"gomel",
		"braslav",
		"naroch",
		"dudutki",
		"sula",
		"silichi",
		"logoisk",
		"zaslavl",
		"khatyn",
		"stalin-line",
		"pripyatsky",
		"turov",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Belarus up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"National Library of Belarus",
		"Komarovsky Market",
		"Gorky Park Minsk",
		"Victory Square Minsk",
		"Trinity Suburb",
		"Dana Mall",
		"Mir Castle",
		"Nesvizh Palace",
		"Brest Fortress",
		"Belovezhskaya Pushcha National Park",
		"Grodno Old Castle",
		"Kalozha Church",
		"Lida Castle",
		"Saint Sophia Cathedral Polotsk",
		"Marc Chagall Art Center",
		"Gomel Palace and Park Ensemble",
		"Mogilev City Hall",
		"Braslav Lakes National Park",
		"Naroch National Park",
		"Dudutki Museum",
		"Sula History Park",
		"Silichi Ski Resort",
		"Stalin Line Historical Complex",
		"Pripyatsky National Park",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Belarus up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'", "'BEACH'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Belarus up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Belarus up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['belarus', city_id") {
		t.Fatalf("Belarus up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "belarus-seed-v1") || !strings.Contains(downSQL, "country_code = 'BY'") {
		t.Fatalf("Belarus down migration must remove only tagged Belarus seed places")
	}
}

func TestAbkhaziaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "046_seed_abkhazia_priority_places.up.sql")
	downSQL := readMigration(t, "046_seed_abkhazia_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_abkhazia_resolved_places AS",
		"'AB'",
		"'RUB'",
		"abkhazia-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Abkhazia up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"sukhum",
		"gagra",
		"pitsunda",
		"new-athos",
		"gudauta",
		"lake-ritsa",
		"tkvarcheli",
		"ochamchira",
		"gali",
		"otap",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Abkhazia up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Sukhum Botanical Garden",
		"Sukhum Monkey Nursery",
		"Abkhazian State Museum",
		"Gagra Colonnade",
		"Oldenburg Prince Castle",
		"Pitsunda Cathedral",
		"Lake Ritsa",
		"Blue Lake",
		"New Athos Cave",
		"New Athos Monastery",
		"Anakopia Fortress",
		"Lykhny Church",
		"Gegsky Waterfall",
		"Abrskil Cave",
		"Mokva Cathedral",
		"Tkvarcheli Akarmara",
		"Gali Market",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Abkhazia up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Abkhazia up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['abkhazia', city_id") {
		t.Fatalf("Abkhazia up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "abkhazia-seed-v1") || !strings.Contains(downSQL, "country_code = 'AB'") {
		t.Fatalf("Abkhazia down migration must remove only tagged Abkhazia seed places")
	}
}

func TestCubaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "047_seed_cuba_priority_places.up.sql")
	downSQL := readMigration(t, "047_seed_cuba_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_cuba_resolved_places AS",
		"'CU'",
		"'CUP'",
		"cuba-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Cuba up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"havana",
		"vinales",
		"varadero",
		"matanzas",
		"playa-larga",
		"cayo-coco",
		"cayo-guillermo",
		"cayo-santa-maria",
		"trinidad",
		"cienfuegos",
		"santa-clara",
		"camaguey",
		"santiago-de-cuba",
		"holguin",
		"guardalavaca",
		"baracoa",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Cuba up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Old Havana",
		"El Malecon",
		"El Capitolio",
		"Museum of the Revolution",
		"Fabrica de Arte Cubano",
		"San Jose Artisans Market",
		"Vinales Valley",
		"Varadero Beach",
		"Josone Park",
		"Bellamar Caves",
		"Bay of Pigs Museum",
		"Cayo Coco Beach",
		"Playa Pilar",
		"Cayo Santa Maria Beach",
		"Trinidad Historic Center",
		"Valle de los Ingenios",
		"Cienfuegos Historic Center",
		"Che Guevara Mausoleum",
		"Camaguey Historic Center",
		"Castillo del Morro",
		"Loma de la Cruz",
		"Guardalavaca Beach",
		"El Yunque",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Cuba up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Cuba up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['cuba', city_id") {
		t.Fatalf("Cuba up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "cuba-seed-v1") || !strings.Contains(downSQL, "country_code = 'CU'") {
		t.Fatalf("Cuba down migration must remove only tagged Cuba seed places")
	}
}

func TestMoroccoPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "048_seed_morocco_priority_places.up.sql")
	downSQL := readMigration(t, "048_seed_morocco_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_morocco_resolved_places AS",
		"'MA'",
		"'MAD'",
		"morocco-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Morocco up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"casablanca",
		"rabat",
		"tangier",
		"chefchaouen",
		"tetouan",
		"asilah",
		"marrakech",
		"ourika",
		"agafay",
		"lalla-takerkoust",
		"imlil",
		"ouzoud",
		"azilal",
		"fes",
		"meknes",
		"volubilis",
		"ifrane",
		"agadir",
		"essaouira",
		"taghazout",
		"ouarzazate",
		"merzouga",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Morocco up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Hassan II Mosque",
		"Morocco Mall",
		"Hassan Tower and Mohammed V Mausoleum",
		"Kasbah of the Oudayas",
		"Chefchaouen Medina",
		"Jemaa el-Fna Square",
		"Jardin Majorelle",
		"Agafay Desert",
		"Fes el-Bali Medina",
		"Chouara Tanneries",
		"Bab Mansour",
		"Archaeological Site of Volubilis",
		"Ifrane National Park",
		"Agadir Beach and Corniche",
		"Souk El Had",
		"Medina of Essaouira",
		"Taghazout Beach",
		"Ksar Ait Ben Haddou",
		"Atlas Studios",
		"Erg Chebbi Dunes",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Morocco up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Morocco up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['morocco', city_id") {
		t.Fatalf("Morocco up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "morocco-seed-v1") || !strings.Contains(downSQL, "country_code = 'MA'") {
		t.Fatalf("Morocco down migration must remove only tagged Morocco seed places")
	}
}

func TestPortugalPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "049_seed_portugal_priority_places.up.sql")
	downSQL := readMigration(t, "049_seed_portugal_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_portugal_resolved_places AS",
		"'PT'",
		"'EUR'",
		"portugal-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Portugal up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"lisbon",
		"sintra",
		"cascais",
		"setubal",
		"porto",
		"vila-nova-de-gaia",
		"braga",
		"guimaraes",
		"viana-do-castelo",
		"douro-valley",
		"coimbra",
		"aveiro",
		"nazare",
		"obidos",
		"fatima",
		"evora",
		"faro",
		"albufeira",
		"lagoa",
		"lagos",
		"portimao",
		"tavira",
		"sagres",
		"vilamoura",
		"funchal",
		"madeira",
		"ponta-delgada",
		"sao-miguel",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Portugal up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Jeronimos Monastery",
		"Belem Tower",
		"Time Out Market Lisboa",
		"Pena Palace",
		"Quinta da Regaleira",
		"Ribeira District",
		"Livraria Lello",
		"Mercado do Bolhao",
		"Bom Jesus do Monte",
		"University of Coimbra",
		"Praia da Nazare",
		"Sanctuary of Fatima",
		"Roman Temple of Evora",
		"Benagil Cave",
		"Ponta da Piedade",
		"Praia da Rocha",
		"Ria Formosa Natural Park",
		"Mercado dos Lavradores",
		"Cabo Girao Skywalk",
		"Sete Cidades",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Portugal up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Portugal up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['portugal', city_id") {
		t.Fatalf("Portugal up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "portugal-seed-v1") || !strings.Contains(downSQL, "country_code = 'PT'") {
		t.Fatalf("Portugal down migration must remove only tagged Portugal seed places")
	}
}

func TestPortugalExtendedPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "056_seed_portugal_extended_places.up.sql")
	downSQL := readMigration(t, "056_seed_portugal_extended_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_portugal_extended_resolved_places AS",
		"'PT'",
		"'EUR'",
		"portugal-extended-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Portugal extended up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"lisbon",
		"sintra",
		"cascais",
		"setubal",
		"porto",
		"vila-nova-de-gaia",
		"braga",
		"guimaraes",
		"douro-valley",
		"aveiro",
		"tomar",
		"batalha",
		"alcobaca",
		"peniche",
		"berlengas",
		"serra-da-estrela",
		"monsaraz",
		"comporta",
		"sesimbra",
		"peneda-geres",
		"faro",
		"albufeira",
		"lagos",
		"portimao",
		"tavira",
		"sagres",
		"loule",
		"carvoeiro",
		"porto-santo",
		"terceira",
		"pico",
		"faial",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Portugal extended up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Lisbon Zoo",
		"Feira da Ladra",
		"Praia Grande",
		"Mercado da Vila Cascais",
		"Convent of Christ",
		"Batalha Monastery",
		"Alcobaca Monastery",
		"Santa Clara-a-Velha Monastery",
		"Berlengas Nature Reserve",
		"Serra da Estrela Natural Park",
		"Monsaraz Castle",
		"Almendres Cromlech",
		"Dark Sky Alqueva Observatory",
		"Comporta Beach",
		"Arrabida Beaches",
		"Peneda-Geres National Park",
		"Crystal Palace Gardens",
		"SEA LIFE Porto",
		"Beira-Rio Market",
		"Bom Jesus Funicular",
		"Guimaraes Cable Car",
		"Douro Historical Train",
		"Costa Nova",
		"Loule Market",
		"Algarve International Sand Sculpture Festival",
		"Praia de Faro",
		"Lagos Zoo",
		"Algarve International Circuit",
		"Praia do Barril",
		"Seven Hanging Valleys Trail",
		"Loriga River Beach",
		"Bread Museum",
		"Porto Santo Beach",
		"Algar do Carvao",
		"Mount Pico",
		"Capelinhos Volcano",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Portugal extended up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Portugal extended up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['portugal', city_id") {
		t.Fatalf("Portugal extended up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "portugal-extended-seed-v1") || !strings.Contains(downSQL, "country_code = 'PT'") {
		t.Fatalf("Portugal extended down migration must remove only tagged Portugal seed places")
	}
}

func TestItalyPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "057_seed_italy_priority_places.up.sql")
	downSQL := readMigration(t, "057_seed_italy_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_italy_resolved_places AS",
		"'IT'",
		"'EUR'",
		"italy-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Italy up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"rome",
		"florence",
		"pisa",
		"siena",
		"lucca",
		"tivoli",
		"castelli-romani",
		"ostia",
		"milan",
		"venice",
		"verona",
		"lake-garda",
		"lake-como",
		"naples",
		"amalfi-coast",
		"capri",
		"pompeii",
		"mount-vesuvius",
		"sorrento",
		"palermo",
		"catania",
		"agrigento",
		"bari",
		"polignano-a-mare",
		"alberobello",
		"matera",
		"tropea",
		"reggio-calabria",
		"sardinia",
		"cagliari",
		"la-maddalena",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Italy up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Colosseum",
		"Campo dei Fiori Market",
		"Villa Borghese",
		"Uffizi Gallery",
		"San Lorenzo Market",
		"Leaning Tower of Pisa",
		"San Rossore Estate",
		"Verona Arena",
		"Gardaland Resort",
		"Rialto Market",
		"Milan Cathedral",
		"Mercato Centrale Milano",
		"Lake Como Bellagio",
		"Naples National Archaeological Museum",
		"Amalfi Cathedral",
		"Blue Grotto",
		"Pompeii Archaeological Park",
		"Mount Vesuvius Gran Cono",
		"Ballaro Market",
		"Mount Etna",
		"Bari Old Town",
		"Trulli of Alberobello",
		"Sassi of Matera",
		"Tropea Old Town",
		"La Maddalena Archipelago National Park",
		"Poetto Beach",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Italy up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Italy up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['italy', city_id") {
		t.Fatalf("Italy up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "italy-seed-v1") || !strings.Contains(downSQL, "country_code = 'IT'") {
		t.Fatalf("Italy down migration must remove only tagged Italy seed places")
	}
}

func TestSpainPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "058_seed_spain_priority_places.up.sql")
	downSQL := readMigration(t, "058_seed_spain_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_spain_resolved_places AS",
		"'ES'",
		"'EUR'",
		"spain-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Spain up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"madrid",
		"barcelona",
		"toledo",
		"segovia",
		"el-escorial",
		"aranjuez",
		"girona",
		"figueres",
		"montserrat",
		"costa-brava",
		"salou",
		"valencia",
		"alicante",
		"benidorm",
		"murcia",
		"mallorca",
		"ibiza",
		"menorca",
		"seville",
		"cordoba",
		"granada",
		"malaga",
		"marbella",
		"ronda",
		"cadiz",
		"tarifa",
		"tenerife",
		"gran-canaria",
		"lanzarote",
		"fuerteventura",
		"bilbao",
		"san-sebastian",
		"pamplona",
		"santander",
		"asturias",
		"santiago-de-compostela",
		"a-coruna",
		"zaragoza",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Spain up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Prado Museum",
		"Royal Palace of Madrid",
		"El Rastro Market",
		"Retiro Park",
		"Sagrada Familia",
		"La Boqueria Market",
		"Park Guell",
		"PortAventura World",
		"Alhambra",
		"Seville Cathedral",
		"Royal Alcazar of Seville",
		"Cordoba Mosque-Cathedral",
		"Malaga Picasso Museum",
		"La Malagueta Beach",
		"City of Arts and Sciences",
		"Central Market of Valencia",
		"Benidorm Levante Beach",
		"Palma Cathedral",
		"Ibiza Dalt Vila",
		"Teide National Park",
		"Maspalomas Dunes",
		"Guggenheim Museum Bilbao",
		"La Concha Beach",
		"Santiago de Compostela Cathedral",
		"Basilica del Pilar",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Spain up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Spain up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['spain', city_id") {
		t.Fatalf("Spain up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "spain-seed-v1") || !strings.Contains(downSQL, "country_code = 'ES'") {
		t.Fatalf("Spain down migration must remove only tagged Spain seed places")
	}
}

func TestLuxembourgPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "050_seed_luxembourg_priority_places.up.sql")
	downSQL := readMigration(t, "050_seed_luxembourg_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_luxembourg_resolved_places AS",
		"'LU'",
		"'EUR'",
		"luxembourg-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Luxembourg up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"luxembourg-city",
		"kirchberg",
		"clervaux",
		"vianden",
		"bourscheid",
		"wiltz",
		"esch-sur-sure",
		"diekirch",
		"ettelbruck",
		"echternach",
		"mullerthal",
		"berdorf",
		"beaufort",
		"larochette",
		"esch-sur-alzette",
		"belval",
		"differdange",
		"dudelange",
		"remich",
		"grevenmacher",
		"schengen",
		"mondorf-les-bains",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Luxembourg up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Bock Casemates",
		"Chemin de la Corniche",
		"Grand Ducal Palace",
		"Notre-Dame Cathedral",
		"MUDAM Luxembourg",
		"Vianden Castle",
		"Clervaux Castle",
		"The Family of Man",
		"Bourscheid Castle",
		"Echternach Abbey",
		"Mullerthal Trail",
		"Schiessentumpel Waterfall",
		"Beaufort Castle",
		"Larochette Castle",
		"Belval Blast Furnaces",
		"Rockhal",
		"Minett Park Fond-de-Gras",
		"Moselle Wine Route",
		"Schengen European Museum",
		"Mondorf Domaine Thermal",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Luxembourg up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Luxembourg up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['luxembourg', city_id") {
		t.Fatalf("Luxembourg up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "luxembourg-seed-v1") || !strings.Contains(downSQL, "country_code = 'LU'") {
		t.Fatalf("Luxembourg down migration must remove only tagged Luxembourg seed places")
	}
}

func TestGermanyPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "051_seed_germany_priority_places.up.sql")
	downSQL := readMigration(t, "051_seed_germany_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_germany_resolved_places AS",
		"'DE'",
		"'EUR'",
		"germany-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Germany up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"berlin",
		"potsdam",
		"hamburg",
		"bremen",
		"lubeck",
		"sylt",
		"rugen",
		"hannover",
		"wolfsburg",
		"munich",
		"nuremberg",
		"rothenburg-ob-der-tauber",
		"fussen",
		"garmisch-partenkirchen",
		"berchtesgaden",
		"rust",
		"cologne",
		"dusseldorf",
		"bonn",
		"frankfurt",
		"mainz",
		"koblenz",
		"trier",
		"heidelberg",
		"stuttgart",
		"baden-baden",
		"freiburg",
		"dresden",
		"leipzig",
		"weimar",
		"erfurt",
		"goslar",
		"wernigerode",
		"oberhausen",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Germany up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Brandenburg Gate",
		"Museum Island",
		"East Side Gallery",
		"Sanssouci Palace",
		"Miniatur Wunderland",
		"Hamburg Fish Market",
		"Neuschwanstein Castle",
		"Marienplatz",
		"Nuremberg Castle",
		"Europa-Park",
		"Cologne Cathedral",
		"Konigsallee",
		"Romerberg",
		"Heidelberg Castle",
		"Dresden Frauenkirche",
		"Zwinger Palace",
		"Monument to the Battle of the Nations",
		"Baden-Baden Kurhaus",
		"Black Forest Scenic Route",
		"Zugspitze",
		"Rugen Chalk Cliffs",
		"Sylt Westerland Beach",
		"Autostadt Wolfsburg",
		"Trier Porta Nigra",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Germany up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Germany up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['germany', city_id") {
		t.Fatalf("Germany up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "germany-seed-v1") || !strings.Contains(downSQL, "country_code = 'DE'") {
		t.Fatalf("Germany down migration must remove only tagged Germany seed places")
	}
}

func TestAustriaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "052_seed_austria_priority_places.up.sql")
	downSQL := readMigration(t, "052_seed_austria_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_austria_resolved_places AS",
		"'AT'",
		"'EUR'",
		"austria-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Austria up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"vienna",
		"klosterneuburg",
		"laxenburg",
		"voesendorf",
		"petronell-carnuntum",
		"hinterbruehl",
		"melk",
		"wachau",
		"krems",
		"duernstein",
		"goettweig",
		"salzburg",
		"hallstatt",
		"st-wolfgang",
		"bad-ischl",
		"zell-am-see",
		"kaprun",
		"innsbruck",
		"mayrhofen",
		"kitzbuhel",
		"solden",
		"bregenz",
		"graz",
		"klagenfurt",
		"villach",
		"eisenstadt",
		"linz",
		"wels",
		"st-polten",
		"grossglockner",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Austria up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Schonbrunn Palace",
		"Hofburg Vienna",
		"St Stephens Cathedral",
		"Belvedere Museum",
		"Vienna Prater and Giant Ferris Wheel",
		"Naschmarkt",
		"Melk Abbey",
		"Wachau Valley",
		"Hohensalzburg Fortress",
		"Mirabell Palace and Gardens",
		"Hallstatt Skywalk",
		"Salzwelten Hallstatt Salt Mine",
		"Golden Roof",
		"Nordkette",
		"Swarovski Crystal Worlds",
		"Graz Schlossberg",
		"Kunsthaus Graz",
		"Lake Worthersee",
		"Minimundus",
		"Grossglockner High Alpine Road",
		"Ars Electronica Center",
		"Linz Main Square",
		"Esterhazy Palace",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Austria up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Austria up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['austria', city_id") {
		t.Fatalf("Austria up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "austria-seed-v1") || !strings.Contains(downSQL, "country_code = 'AT'") {
		t.Fatalf("Austria down migration must remove only tagged Austria seed places")
	}
}

func TestAustraliaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "053_seed_australia_priority_places.up.sql")
	downSQL := readMigration(t, "053_seed_australia_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_australia_resolved_places AS",
		"'AU'",
		"'AUD'",
		"australia-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Australia up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"sydney",
		"blue-mountains",
		"canberra",
		"byron-bay",
		"melbourne",
		"great-ocean-road",
		"phillip-island",
		"hobart",
		"launceston",
		"brisbane",
		"gold-coast",
		"sunshine-coast",
		"noosa",
		"cairns",
		"port-douglas",
		"kuranda",
		"airlie-beach",
		"whitsundays",
		"adelaide",
		"barossa-valley",
		"kangaroo-island",
		"darwin",
		"kakadu",
		"alice-springs",
		"uluru",
		"perth",
		"fremantle",
		"rottnest-island",
		"margaret-river",
		"broome",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Australia up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Sydney Opera House",
		"Sydney Harbour Bridge",
		"Bondi Beach",
		"Blue Mountains Three Sisters",
		"Australian War Memorial",
		"Federation Square",
		"Queen Victoria Market",
		"Twelve Apostles",
		"Penguin Parade",
		"Salamanca Market",
		"South Bank Parklands",
		"Surfers Paradise Beach",
		"Great Barrier Reef",
		"Kuranda Scenic Railway",
		"Adelaide Central Market",
		"Uluru",
		"Kakadu Ubirr",
		"Kings Park and Botanic Garden",
		"Fremantle Markets",
		"Rottnest Island",
		"Cable Beach",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Australia up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Australia up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['australia', city_id") {
		t.Fatalf("Australia up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "australia-seed-v1") || !strings.Contains(downSQL, "country_code = 'AU'") {
		t.Fatalf("Australia down migration must remove only tagged Australia seed places")
	}
}

func TestTanzaniaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "054_seed_tanzania_priority_places.up.sql")
	downSQL := readMigration(t, "054_seed_tanzania_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_tanzania_resolved_places AS",
		"'TZ'",
		"'TZS'",
		"tanzania-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Tanzania up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"dar-es-salaam",
		"bagamoyo",
		"tanga",
		"pangani",
		"saadani",
		"mafia-island",
		"zanzibar-city",
		"stone-town",
		"nungwi",
		"kendwa",
		"paje",
		"jambiani",
		"jozani",
		"mnemba",
		"arusha",
		"moshi",
		"kilimanjaro",
		"mount-meru",
		"serengeti",
		"ngorongoro",
		"tarangire",
		"lake-manyara",
		"karatu",
		"dodoma",
		"morogoro",
		"mikumi",
		"ruaha",
		"nyerere",
		"iringa",
		"udzungwa",
		"mbeya",
		"kitulo",
		"mwanza",
		"rubondo-island",
		"kigoma",
		"gombe",
		"mahale",
		"tabora",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Tanzania up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Serengeti National Park",
		"Ngorongoro Crater",
		"Mount Kilimanjaro",
		"Tarangire National Park",
		"Lake Manyara National Park",
		"Stone Town",
		"Nungwi Beach",
		"Jozani Forest",
		"Forodhani Night Market",
		"National Museum of Tanzania",
		"Kariakoo Market",
		"Village Museum",
		"Ruaha National Park",
		"Nyerere National Park",
		"Mikumi National Park",
		"Udzungwa Mountains National Park",
		"Saanane Island National Park",
		"Gombe Stream National Park",
		"Mahale Mountains National Park",
		"Rubondo Island National Park",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Tanzania up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Tanzania up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['tanzania', city_id") {
		t.Fatalf("Tanzania up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "tanzania-seed-v1") || !strings.Contains(downSQL, "country_code = 'TZ'") {
		t.Fatalf("Tanzania down migration must remove only tagged Tanzania seed places")
	}
}

func TestKenyaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "055_seed_kenya_priority_places.up.sql")
	downSQL := readMigration(t, "055_seed_kenya_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kenya_resolved_places AS",
		"'KE'",
		"'KES'",
		"kenya-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Kenya up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"nairobi",
		"karen",
		"langata",
		"kiambu",
		"naivasha",
		"mount-kenya",
		"aberdares",
		"nyeri",
		"masai-mara",
		"narok",
		"nakuru",
		"lake-nakuru",
		"lake-naivasha",
		"hells-gate",
		"lake-elementaita",
		"lake-bogoria",
		"lake-baringo",
		"eldoret",
		"kericho",
		"mombasa",
		"diani",
		"malindi",
		"watamu",
		"lamu",
		"kilifi",
		"shimoni",
		"kisite-mpunguti",
		"amboseli",
		"tsavo-east",
		"tsavo-west",
		"samburu",
		"nanyuki",
		"laikipia",
		"ol-pejeta",
		"meru",
		"marsabit",
		"lake-turkana",
		"kisumu",
		"lake-victoria",
		"kakamega",
		"kitale",
		"rusinga-island",
		"ndere-island",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Kenya up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Nairobi National Park",
		"Nairobi National Museum",
		"Karen Blixen Museum",
		"Giraffe Centre",
		"Masai Mara National Reserve",
		"Lake Nakuru National Park",
		"Hell''s Gate National Park",
		"Amboseli National Park",
		"Tsavo East National Park",
		"Tsavo West National Park",
		"Samburu National Reserve",
		"Mount Kenya National Park",
		"Fort Jesus",
		"Diani Beach",
		"Watamu Marine National Park",
		"Lamu Old Town",
		"Kisite-Mpunguti Marine Park",
		"Kisumu Impala Sanctuary",
		"Kakamega Forest",
		"Ndere Island National Park",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Kenya up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Kenya up migration must include category %s", category)
		}
	}

	if !strings.Contains(upSQL, "ARRAY['kenya', city_id") {
		t.Fatalf("Kenya up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "kenya-seed-v1") || !strings.Contains(downSQL, "country_code = 'KE'") {
		t.Fatalf("Kenya down migration must remove only tagged Kenya seed places")
	}
}

func TestSerbiaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "074_seed_serbia_priority_places.up.sql")
	downSQL := readMigration(t, "074_seed_serbia_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_serbia_resolved_places AS",
		"'RS'",
		"'RSD'",
		"serbia-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Serbia up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"belgrade",
		"zemun",
		"avala",
		"novi-sad",
		"petrovaradin",
		"sremski-karlovci",
		"subotica",
		"palic",
		"fruska-gora",
		"zrenjanin",
		"nis",
		"sokobanja",
		"zajecar",
		"felix-romuliana",
		"djerdap",
		"golubac",
		"lepenski-vir",
		"devils-town",
		"leskovac",
		"zlatibor",
		"tara",
		"mokra-gora",
		"uvac",
		"kopaonik",
		"studenica",
		"zica",
		"novi-pazar",
		"kragujevac",
		"topola",
		"cacak",
		"ovcar-kablar",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Serbia up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Belgrade Fortress",
		"Knez Mihailova Street",
		"Skadarlija",
		"Nikola Tesla Museum",
		"Saint Sava Temple",
		"Ada Ciganlija",
		"Usce Shopping Center",
		"Zeleni Venac Market",
		"Petrovaradin Fortress",
		"Novi Sad Synagogue",
		"Subotica City Hall",
		"Lake Palic",
		"Fruska Gora National Park",
		"Nis Fortress",
		"Skull Tower",
		"Felix Romuliana",
		"Golubac Fortress",
		"Djerdap National Park",
		"Lepenski Vir",
		"Devils Town",
		"Zlatibor Mountain",
		"Tara National Park",
		"Sargan Eight Railway",
		"Drvengrad",
		"Uvac Special Nature Reserve",
		"Kopaonik National Park",
		"Studenica Monastery",
		"Zica Monastery",
		"Oplenac Royal Mausoleum",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Serbia up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'", "'BEACH'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Serbia up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Serbia up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['serbia', city_id") {
		t.Fatalf("Serbia up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "serbia-seed-v1") || !strings.Contains(downSQL, "country_code = 'RS'") {
		t.Fatalf("Serbia down migration must remove only tagged Serbia seed places")
	}
}

func TestGreecePriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "075_seed_greece_priority_places.up.sql")
	downSQL := readMigration(t, "075_seed_greece_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_greece_resolved_places AS",
		"'GR'",
		"'EUR'",
		"greece-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Greece up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"athens",
		"piraeus",
		"glyfada",
		"cape-sounion",
		"thessaloniki",
		"meteora",
		"kalambaka",
		"delphi",
		"arachova",
		"olympus",
		"litochoro",
		"volos",
		"pelion",
		"halkidiki",
		"santorini",
		"oia",
		"fira",
		"mykonos",
		"delos",
		"heraklion",
		"chania",
		"rethymno",
		"agios-nikolaos",
		"elafonisi",
		"rhodes",
		"lindos",
		"corfu",
		"paleokastritsa",
		"zakynthos",
		"naxos",
		"paros",
		"nafplio",
		"mycenae",
		"epidaurus",
		"olympia",
		"patras",
		"kalamata",
		"monemvasia",
		"mystras",
		"mani",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Greece up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Acropolis of Athens",
		"Acropolis Museum",
		"National Archaeological Museum Athens",
		"Monastiraki Flea Market",
		"Stavros Niarchos Foundation Cultural Center",
		"Temple of Poseidon Sounion",
		"White Tower of Thessaloniki",
		"Modiano Market",
		"Meteora Monasteries",
		"Archaeological Site of Delphi",
		"Mount Olympus National Park",
		"Navagio Beach",
		"Palace of Knossos",
		"Balos Lagoon",
		"Old Town of Rhodes",
		"Corfu Old Town",
		"Santorini Caldera",
		"Mykonos Windmills",
		"Delos Archaeological Site",
		"Ancient Mycenae",
		"Ancient Theatre of Epidaurus",
		"Ancient Olympia",
		"Palamidi Fortress",
		"Monemvasia Castle Town",
		"Mystras",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Greece up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'TEMPLE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Greece up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Greece up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['greece', city_id") {
		t.Fatalf("Greece up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "greece-seed-v1") || !strings.Contains(downSQL, "country_code = 'GR'") {
		t.Fatalf("Greece down migration must remove only tagged Greece seed places")
	}
}

func TestNewZealandPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "076_seed_new_zealand_priority_places.up.sql")
	downSQL := readMigration(t, "076_seed_new_zealand_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_new_zealand_resolved_places AS",
		"'NZ'",
		"'NZD'",
		"new-zealand-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("New Zealand up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"auckland",
		"waiheke-island",
		"waitakere-ranges",
		"rotorua",
		"taupo",
		"waitomo",
		"matamata",
		"tauranga",
		"mount-maunganui",
		"tongariro",
		"napier",
		"wellington",
		"christchurch",
		"kaikoura",
		"nelson",
		"abel-tasman",
		"dunedin",
		"otago-peninsula",
		"queenstown",
		"arrowtown",
		"wanaka",
		"tekapo",
		"aoraki-mount-cook",
		"fiordland",
		"milford-sound",
		"franz-josef",
		"fox-glacier",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("New Zealand up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Sky Tower Auckland",
		"Auckland War Memorial Museum",
		"Waiheke Island",
		"Auckland Night Markets",
		"Westfield Newmarket",
		"Piha Beach",
		"Te Puia",
		"Wai-O-Tapu Thermal Wonderland",
		"Hobbiton Movie Set",
		"Waitomo Glowworm Caves",
		"Huka Falls",
		"Tongariro Alpine Crossing",
		"Te Papa Tongarewa",
		"Wellington Cable Car",
		"Wellington Night Market",
		"Christchurch Botanic Gardens",
		"Canterbury Museum",
		"Kaikoura Whale Watching",
		"Abel Tasman National Park",
		"Dunedin Railway Station",
		"Larnach Castle",
		"Skyline Queenstown",
		"Milford Sound",
		"Aoraki Mount Cook National Park",
		"Franz Josef Glacier",
		"Lake Tekapo",
		"Wanaka Lakefront",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("New Zealand up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("New Zealand up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("New Zealand up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['new-zealand', city_id") {
		t.Fatalf("New Zealand up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "new-zealand-seed-v1") || !strings.Contains(downSQL, "country_code = 'NZ'") {
		t.Fatalf("New Zealand down migration must remove only tagged New Zealand seed places")
	}
}

func TestUkrainePriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "077_seed_ukraine_priority_places.up.sql")
	downSQL := readMigration(t, "077_seed_ukraine_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_ukraine_resolved_places AS",
		"'UA'",
		"'UAH'",
		"ukraine-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Ukraine up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"kyiv",
		"lviv",
		"odesa",
		"vinnytsia",
		"cherkasy",
		"uman",
		"poltava",
		"chernivtsi",
		"ivano-frankivsk",
		"yaremche",
		"bukovel",
		"uzhhorod",
		"mukachevo",
		"kamianets-podilskyi",
		"bilhorod-dnistrovskyi",
		"kharkiv",
		"dnipro",
		"zaporizhzhia",
		"sumy",
		"chernihiv",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Ukraine up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Saint Sophia Cathedral Kyiv",
		"Kyiv Pechersk Lavra",
		"Golden Gate Kyiv",
		"National Museum of the History of Ukraine",
		"Ocean Plaza Kyiv",
		"Besarabsky Market",
		"Rynok Square Lviv",
		"Lviv National Opera",
		"Lviv High Castle Park",
		"Privoz Market Odesa",
		"Odesa Opera and Ballet Theater",
		"Arcadia Beach",
		"Sofiyivka Park Uman",
		"Kamianets-Podilskyi Castle",
		"Residence of Bukovinian and Dalmatian Metropolitans",
		"Probiy Waterfall",
		"Bukovel Resort",
		"Palanok Castle",
		"Derzhprom Kharkiv",
		"Taras Shevchenko Park Dnipro",
		"Khortytsia Island",
		"Pyatnytska Church Chernihiv",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Ukraine up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Ukraine up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Ukraine up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['ukraine', city_id") {
		t.Fatalf("Ukraine up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "ukraine-seed-v1") || !strings.Contains(downSQL, "country_code = 'UA'") {
		t.Fatalf("Ukraine down migration must remove only tagged Ukraine seed places")
	}
}

func TestUnitedStatesPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "078_seed_united_states_priority_places.up.sql")
	downSQL := readMigration(t, "078_seed_united_states_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_united_states_resolved_places AS",
		"'US'",
		"'USD'",
		"united-states-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("United States up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"new-york",
		"washington-dc",
		"boston",
		"philadelphia",
		"niagara-falls",
		"chicago",
		"los-angeles",
		"san-francisco",
		"san-diego",
		"las-vegas",
		"seattle",
		"portland",
		"miami",
		"orlando",
		"new-orleans",
		"austin",
		"dallas",
		"houston",
		"san-antonio",
		"grand-canyon",
		"yellowstone",
		"yosemite",
		"zion",
		"rocky-mountain",
		"honolulu",
		"maui",
		"anchorage",
		"denali",
		"nashville",
		"atlanta",
		"charleston",
		"savannah",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("United States up migration must seed place for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Statue of Liberty and Ellis Island",
		"Central Park",
		"National Mall and Memorial Parks",
		"Freedom Trail Boston",
		"Independence Hall and Liberty Bell",
		"Niagara Falls State Park",
		"Millennium Park Chicago",
		"Griffith Observatory",
		"Golden Gate Bridge",
		"San Diego Zoo",
		"Fountains of Bellagio",
		"Pike Place Market",
		"Walt Disney World Resort",
		"French Quarter New Orleans",
		"Space Center Houston",
		"The Alamo",
		"Grand Canyon South Rim",
		"Old Faithful Yellowstone",
		"Yosemite Valley",
		"Zion Canyon Scenic Drive",
		"Waikiki Beach",
		"Denali National Park",
		"Grand Ole Opry",
		"Georgia Aquarium",
		"Forsyth Park Savannah",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("United States up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("United States up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("United States up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['united-states', city_id") {
		t.Fatalf("United States up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "united-states-seed-v1") || !strings.Contains(downSQL, "country_code = 'US'") {
		t.Fatalf("United States down migration must remove only tagged United States seed places")
	}
}

func TestSingaporePriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "079_seed_singapore_priority_places.up.sql")
	downSQL := readMigration(t, "079_seed_singapore_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_singapore_resolved_places AS",
		"'SG'",
		"'SGD'",
		"singapore-seed-v1",
		"'singapore'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Singapore up migration must contain %q", fragment)
		}
	}

	for _, title := range []string{
		"Gardens by the Bay",
		"Marina Bay Sands",
		"Merlion Park",
		"ArtScience Museum",
		"National Gallery Singapore",
		"Lau Pa Sat",
		"Universal Studios Singapore",
		"Singapore Oceanarium",
		"Adventure Cove Waterpark",
		"Siloso Beach",
		"Fort Siloso",
		"Buddha Tooth Relic Temple and Museum",
		"Sri Mariamman Temple",
		"Tekka Centre",
		"Sultan Mosque",
		"Haji Lane",
		"Singapore Botanic Gardens",
		"Singapore Zoo",
		"Night Safari",
		"Bird Paradise",
		"Jewel Changi Airport",
		"East Coast Park",
		"MacRitchie Reservoir Park",
		"Newton Food Centre",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Singapore up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'FOOD'", "'TEMPLE'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Singapore up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Singapore up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['singapore', city_id") {
		t.Fatalf("Singapore up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "singapore-seed-v1") || !strings.Contains(downSQL, "country_code = 'SG'") {
		t.Fatalf("Singapore down migration must remove only tagged Singapore seed places")
	}
}

func TestDenmarkPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "080_seed_denmark_priority_places.up.sql")
	downSQL := readMigration(t, "080_seed_denmark_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_denmark_resolved_places AS",
		"'DK'",
		"'DKK'",
		"denmark-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Denmark up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"copenhagen",
		"aarhus",
		"odense",
		"aalborg",
		"billund",
		"skagen",
		"ribe",
		"esbjerg",
		"roskilde",
		"helsingor",
		"hillerod",
		"mons-klint",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Denmark up migration must seed places for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Tivoli Gardens",
		"Nyhavn",
		"The Little Mermaid",
		"SMK - National Gallery of Denmark",
		"TorvehallerneKBH",
		"ARoS Aarhus Art Museum",
		"Den Gamle By",
		"Moesgaard Museum",
		"LEGOLAND Billund Resort",
		"LEGO House",
		"H. C. Andersen House",
		"Egeskov Castle",
		"Skagen Grenen",
		"Ribe Viking Center",
		"Roskilde Cathedral",
		"Kronborg Castle",
		"Frederiksborg Castle",
		"Mons Klint",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Denmark up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'FOOD'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Denmark up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Denmark up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['denmark', city_id") {
		t.Fatalf("Denmark up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "denmark-seed-v1") || !strings.Contains(downSQL, "country_code = 'DK'") {
		t.Fatalf("Denmark down migration must remove only tagged Denmark seed places")
	}
}

func TestFinlandPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "081_seed_finland_priority_places.up.sql")
	downSQL := readMigration(t, "081_seed_finland_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_finland_resolved_places AS",
		"'FI'",
		"'EUR'",
		"finland-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Finland up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"helsinki",
		"espoo",
		"vantaa",
		"turku",
		"naantali",
		"tampere",
		"porvoo",
		"savonlinna",
		"kuopio",
		"jyvaskyla",
		"lappeenranta",
		"lahti",
		"rovaniemi",
		"levi",
		"saariselka",
		"inari",
		"kilpisjarvi",
		"oulu",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Finland up migration must seed places for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Suomenlinna Sea Fortress",
		"Helsinki Cathedral",
		"Temppeliaukio Church",
		"Oodi Central Library",
		"Market Square Helsinki",
		"Linnanmaki",
		"Nuuksio National Park",
		"Turku Castle",
		"Moominworld",
		"Vapriikki Museum Centre",
		"Pyynikki Observation Tower",
		"Porvoo Old Town",
		"Olavinlinna Castle",
		"Puijo Tower",
		"Santa Claus Village",
		"Arktikum",
		"Levi Ski Resort",
		"Siida Sami Museum",
		"Oulu Market Hall",
		"Nallikari Beach",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Finland up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'FOOD'", "'TEMPLE'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Finland up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Finland up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['finland', city_id") {
		t.Fatalf("Finland up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "finland-seed-v1") || !strings.Contains(downSQL, "country_code = 'FI'") {
		t.Fatalf("Finland down migration must remove only tagged Finland seed places")
	}
}

func TestCanadaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "082_seed_canada_priority_places.up.sql")
	downSQL := readMigration(t, "082_seed_canada_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_canada_resolved_places AS",
		"'CA'",
		"'CAD'",
		"canada-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Canada up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"toronto",
		"niagara-falls-ca",
		"ottawa",
		"montreal",
		"quebec-city",
		"vancouver",
		"victoria",
		"whistler",
		"banff",
		"jasper",
		"calgary",
		"edmonton",
		"winnipeg",
		"saskatoon",
		"regina",
		"halifax",
		"charlottetown",
		"st-johns",
		"whitehorse",
		"yellowknife",
		"churchill",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Canada up migration must seed places for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"CN Tower",
		"Niagara Falls",
		"Parliament Hill",
		"Notre-Dame Basilica of Montreal",
		"Old Quebec",
		"Stanley Park",
		"Granville Island Public Market",
		"Butchart Gardens",
		"Banff Gondola",
		"Lake Louise",
		"West Edmonton Mall",
		"The Forks",
		"Royal Saskatchewan Museum",
		"Halifax Citadel",
		"Green Gables Heritage Place",
		"Signal Hill",
		"Northern Lights in Yellowknife",
		"Polar Bears of Churchill",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Canada up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'FOOD'", "'TEMPLE'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Canada up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Canada up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['canada', city_id") {
		t.Fatalf("Canada up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "canada-seed-v1") || !strings.Contains(downSQL, "country_code = 'CA'") {
		t.Fatalf("Canada down migration must remove only tagged Canada seed places")
	}
}

func TestEstoniaPriorityPlacesSeedMigrationCoversTouristBreadth(t *testing.T) {
	upSQL := readMigration(t, "083_seed_estonia_priority_places.up.sql")
	downSQL := readMigration(t, "083_seed_estonia_priority_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_estonia_resolved_places AS",
		"'EE'",
		"'EUR'",
		"estonia-seed-v1",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("Estonia up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"tallinn",
		"tartu",
		"parnu",
		"haapsalu",
		"kuressaare",
		"saaremaa",
		"hiiumaa",
		"narva",
		"narva-joesuu",
		"lahemaa",
		"rakvere",
		"otepaa",
		"viljandi",
		"vorumaa",
		"soomaa",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("Estonia up migration must seed places for city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Tallinn Old Town",
		"Seaplane Harbour",
		"Kadriorg Park",
		"Kumu Art Museum",
		"Balti Jaama Turg",
		"Telliskivi Creative City",
		"Tartu Town Hall Square",
		"Estonian National Museum",
		"AHHAA Science Centre",
		"Parnu Beach",
		"Kuressaare Castle",
		"Kaali Meteorite Crater",
		"Narva Castle",
		"Lahemaa National Park",
		"Viru Bog Nature Trail",
		"Rakvere Castle",
		"Soomaa National Park",
		"Viljandi Castle Ruins",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Estonia up migration must include curated place %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'ARCHITECTURE'", "'MUSEUM'", "'ENTERTAINMENT'", "'PARK'", "'NATURE'", "'FOOD'", "'TEMPLE'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Estonia up migration must include category %s", category)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("Estonia up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "ARRAY['estonia', city_id") {
		t.Fatalf("Estonia up migration must tag every place with the country destination and city")
	}
	if !strings.Contains(downSQL, "estonia-seed-v1") || !strings.Contains(downSQL, "country_code = 'EE'") {
		t.Fatalf("Estonia down migration must remove only tagged Estonia seed places")
	}
}

func TestHikingPlaceEnrichmentSeedMigrationCoversHubDayHikes(t *testing.T) {
	upSQL := readMigration(t, "085_seed_hiking_place_enrichment.up.sql")
	downSQL := readMigration(t, "085_seed_hiking_place_enrichment.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_hiking_enrichment_resolved_places AS",
		"hiking-enrichment-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("hiking enrichment up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"shymkent",
		"karaganda",
		"balkhash",
		"aktau",
		"ust-kamenogorsk",
		"kokshetau",
		"bishkek",
		"karakol",
		"tashkent",
		"tbilisi",
		"yerevan",
		"dubai",
		"ras-al-khaimah",
		"sochi",
		"antalya",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("hiking enrichment up migration must seed places linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Gorelnik Waterfalls",
		"Furmanov Peak",
		"Aksai Skete",
		"Kara-Kungey Ridge",
		"Kok-Zhailau Plateau",
		"Butakovka Gorge",
		"Kimasar Gorge",
		"Sayram-Ugam National Park",
		"Bektau-Ata",
		"Karkaraly National Park",
		"Sherkala Mountain",
		"Altyn Arashan",
		"Ala-Kul Lake Trek",
		"Greater Chimgan Trail",
		"Tbilisi National Park",
		"Azat Reservoir Trail",
		"Hatta Mountain Trails",
		"Jebel Jais Hiking Trails",
		"Agura Waterfalls",
		"Lycian Way near Goynuk Canyon",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("hiking enrichment up migration must include curated hiking place %q", title)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("hiking enrichment up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("hiking enrichment up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(downSQL, "hiking-enrichment-v1") {
		t.Fatalf("hiking enrichment down migration must remove only tagged hiking enrichment places")
	}
}

func TestKazakhstanHikingDepthSeedMigrationCoversAdditionalRegionalRoutes(t *testing.T) {
	upSQL := readMigration(t, "086_seed_kazakhstan_hiking_depth.up.sql")
	downSQL := readMigration(t, "086_seed_kazakhstan_hiking_depth.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_hiking_depth_resolved_places AS",
		"kazakhstan-hiking-depth-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan hiking depth up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"shymkent",
		"pavlodar",
		"astana",
		"kokshetau",
		"aktau",
		"ust-kamenogorsk",
		"taldykorgan",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan hiking depth up migration must seed places linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Turgen Gorge",
		"Bear Falls in Turgen Gorge",
		"Issyk Lake Trail",
		"Assy Plateau",
		"Kaskelen Gorge",
		"Monakhov Gorge",
		"Tuyuksu Glacier Trail",
		"Tamgaly-Tas Rocks",
		"Aksu Canyon",
		"Ugam Gorge",
		"Akbet Peak",
		"Konyr-Aulie Cave",
		"Buiratau National Park",
		"Okzhetpes Rock",
		"Torysh Valley",
		"Tuzbair Salt Flat",
		"Airakty-Shomanai Valley",
		"Zhygylgan Fault",
		"Sibiny Lakes",
		"Rakhmanov Springs Trails",
		"Burkhan-Bulak Waterfall",
		"Dzungarian Alatau National Park",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan hiking depth up migration must include additional hiking place %q", title)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan hiking depth up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan hiking depth up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-hiking-depth-v1") {
		t.Fatalf("kazakhstan hiking depth down migration must remove only tagged Kazakhstan hiking depth places")
	}
}

func TestReferenceGapHikingSeedMigrationCoversPreviouslyUnseededCityHubs(t *testing.T) {
	upSQL := readMigration(t, "087_seed_reference_gap_hiking_places.up.sql")
	downSQL := readMigration(t, "087_seed_reference_gap_hiking_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_reference_gap_hiking_resolved_places AS",
		"reference-gap-hiking-v1",
		"'hiking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("reference gap hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"petropavlovsk",
		"spb",
		"novosibirsk",
		"omsk",
		"namadgut",
		"khargush",
		"zorkul",
		"ak-baital",
		"rangkul",
		"danghara",
		"khovaling",
		"farkhor",
		"ashgabat",
		"ijevan",
		"chisinau",
		"vung-tau",
		"cat-ba",
		"ha-giang",
		"phong-nha",
		"urumqi",
		"new-delhi",
		"lazio-coast",
		"elche",
		"calpe",
		"jakarta",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("reference gap hiking up migration must cover previously unseeded city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Imantau-Shalkar Lakes Trail",
		"Duderhof Heights",
		"Berd Rocks Trail",
		"Bird Harbor Nature Trail",
		"Namadgut Fortress Viewpoint Trail",
		"Khargush Pass Lakes Trail",
		"Zorkul Lake Shore Trail",
		"Ak-Baital Pass Viewpoint",
		"Rangkul Lakes Viewpoint Trail",
		"Danghara Foothill Trail",
		"Khovaling Ridge Trail",
		"Panj River Floodplain Trail",
		"Kopet Dag Foothills Trail",
		"Ijevan Dendropark Forest Trail",
		"Codru Forest Reserve Trail",
		"Vung Tau Big Mountain Trail",
		"Ngu Lam Peak Trail",
		"Ma Pi Leng Pass Trail",
		"Phong Nha Botanical Garden Trail",
		"Heavenly Lake Tianshan Trail",
		"Aravalli Biodiversity Park Trail",
		"Circeo National Park Trail",
		"Clot de Galvany Trail",
		"Penon de Ifach Trail",
		"Angke Kapuk Mangrove Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("reference gap hiking up migration must include hiking place %q", title)
		}
	}

	if strings.Contains(upSQL, "Lastiver Caves and Waterfall") {
		t.Fatalf("reference gap hiking up migration must avoid duplicating already seeded Lastiver place")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("reference gap hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(downSQL, "reference-gap-hiking-v1") {
		t.Fatalf("reference gap hiking down migration must remove only tagged reference gap hiking places")
	}
}

func TestKazakhstanRegionalHikingSeedMigrationCoversWeakRegionalHubs(t *testing.T) {
	upSQL := readMigration(t, "088_seed_kazakhstan_regional_hiking_places.up.sql")
	downSQL := readMigration(t, "088_seed_kazakhstan_regional_hiking_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_regional_hiking_resolved_places AS",
		"kazakhstan-regional-hiking-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan regional hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"aktobe",
		"taraz",
		"semey",
		"atyrau",
		"kostanay",
		"kyzylorda",
		"oral",
		"turkestan",
		"zhezkazgan",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan regional hiking up migration must seed places linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Kargaly Reservoir Shore Trail",
		"Aksu-Zhabagly Foothill Trail",
		"Semey Pine Belt Trail",
		"Akzhaiyk Delta Eco Trail",
		"Naurzum Pine and Lake Trail",
		"Kamyslybas Lake Shore Trail",
		"Ural River Floodplain Trail",
		"Karatau Foothill Trail",
		"Ulytau Akmeshit Ridge Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan regional hiking up migration must include regional hiking place %q", title)
		}
	}

	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan regional hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan regional hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-regional-hiking-v1") {
		t.Fatalf("kazakhstan regional hiking down migration must remove only tagged Kazakhstan regional hiking places")
	}
}

func TestKazakhstanExtendedHikingSeedMigrationAddsMoreRouteLevelPlaces(t *testing.T) {
	upSQL := readMigration(t, "090_seed_kazakhstan_extended_hiking_routes.up.sql")
	downSQL := readMigration(t, "090_seed_kazakhstan_extended_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_extended_hiking_resolved_places AS",
		"kazakhstan-extended-hiking-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan extended hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
		"ust-kamenogorsk",
		"shymkent",
		"karaganda",
		"kokshetau",
		"aktau",
		"atyrau",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan extended hiking up migration must seed places linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Big Almaty Peak Trail",
		"Mynzhylky Plateau Trail",
		"Bogdanovich Glacier View Trail",
		"Butakovka Waterfall Trail",
		"Kairak Waterfall Trail",
		"Second Kolsai Lake Trek",
		"Kaindy Lake Viewpoint Trail",
		"Aktogay Canyon Trail",
		"Aktau Mountains Red Gorge Trail",
		"Katutau Volcanic Hills Trail",
		"Kokkol Waterfall Trail",
		"Markakol Shore Trail",
		"Kiin-Kerish Valley Trail",
		"Kora Gorge Trail",
		"Sayram-Su Lake Trail",
		"Mashat Gorge Trail",
		"Shaitankol Lake Trail",
		"Aksoran Peak Trail",
		"Zerenda Lake Forest Trail",
		"Sinyukha Peak Trail",
		"Kapamsay Canyon Trail",
		"Karagiye Depression Rim Trail",
		"Saura Canyon and Lake Trail",
		"Inder Salt Lake Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan extended hiking up migration must include route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Furmanov Peak",
		"Kara-Kungey Ridge",
		"Karkaraly National Park",
		"Dzungarian Alatau National Park",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan extended hiking up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan extended hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan extended hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-extended-hiking-v1") {
		t.Fatalf("kazakhstan extended hiking down migration must remove only tagged Kazakhstan extended hiking places")
	}
}

func TestKazakhstanAdditionalHikingSeedMigrationAddsRemainingRouteLevelPlaces(t *testing.T) {
	upSQL := readMigration(t, "092_seed_kazakhstan_additional_hiking_routes.up.sql")
	downSQL := readMigration(t, "092_seed_kazakhstan_additional_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_additional_hiking_resolved_places AS",
		"kazakhstan-additional-hiking-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan additional hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
		"ust-kamenogorsk",
		"shymkent",
		"taraz",
		"karaganda",
		"kokshetau",
		"aktau",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan additional hiking up migration must seed places linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Ayusai Waterfalls Trail",
		"Prohodnoye Gorge Trail",
		"Left Talgar Gorge Trail",
		"Talgar Peak Base Trail",
		"Bartogai Reservoir View Trail",
		"Ketmen Ridge Trail",
		"Tekeli Gorge Trail",
		"Eskeldy Gorge Trail",
		"Yazevoe Lake Trail",
		"Ivanov Ridge Trail",
		"Radon Lake Trail",
		"Sairam Peak Base Trail",
		"Boraldai Gorge Trail",
		"Kyzylkol Lake Trail",
		"Kent Mountains Trail",
		"Begazy Granite Trail",
		"Zhumbaktas Shore Trail",
		"Bokty Mountain View Trail",
		"Boszhira Fang View Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan additional hiking up migration must include route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Butakovka Waterfall Trail",
		"Second Kolsai Lake Trek",
		"Kora Gorge Trail",
		"Torysh Valley",
		"Tuzbair Salt Flat",
		"Bolektau Viewpoint",
		"Bozzhyra Valley",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan additional hiking up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan additional hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan additional hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-additional-hiking-v1") {
		t.Fatalf("kazakhstan additional hiking down migration must remove only tagged Kazakhstan additional hiking places")
	}
}

func TestEuropeCaucasusHikingRoutesSeedMigrationAddsRouteLevelCoverage(t *testing.T) {
	upSQL := readMigration(t, "093_seed_europe_caucasus_hiking_routes.up.sql")
	downSQL := readMigration(t, "093_seed_europe_caucasus_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_europe_caucasus_hiking_resolved_places AS",
		"europe-caucasus-hiking-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("europe caucasus hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"stepantsminda",
		"gudauri",
		"chakvistavi",
		"dilijan",
		"garni",
		"khndzoresk",
		"shamakhi",
		"goygol",
		"hirkan",
		"moscow",
		"spb",
		"sochi",
		"yekaterinburg",
		"kazan",
		"braslav",
		"naroch",
		"belovezhskaya-pushcha",
		"pripyatsky",
		"yaremche",
		"bukovel",
		"uzhhorod",
		"interlaken",
		"innsbruck",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("europe caucasus hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Gergeti Glacier Trail",
		"Juta to Chaukhi Lake Trail",
		"Mtirala Tsablnari Waterfall Loop",
		"Parz Lake to Gosh Lake Trail",
		"Mount Dimats Trail",
		"Azat Gorge Basalt Trail",
		"Old Khndzoresk Cave Trail",
		"Candy Cane Mountains Trail",
		"Goygol Lake Shore Trail",
		"Khanbulan Lake Forest Trail",
		"Losiny Ostrov Ecological Trail",
		"Komarovo Shore Eco Trail",
		"Eagle Rocks and Matsesta Springs Trail",
		"Seven Brothers Rocks Trail",
		"Blue Lakes Forest Loop",
		"Slobodka Ridge Lakes View Trail",
		"Blue Lakes Eco Trail",
		"Tsarskaya Polyana Forest Trail",
		"Pripyat Floodplain Boardwalk Trail",
		"Makovytsia Mountain Trail",
		"Hoverla Ascent from Zarosliak",
		"Synyak Mountain Trail",
		"Borzhava Ridge to Velykyi Verkh Trail",
		"Eiger Trail",
		"Nockspitze Saile Summit Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("europe caucasus hiking up migration must include route-level hiking place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Gergeti Trinity Church",
		"Juta and Chaukhi Massif",
		"Mtirala National Park",
		"Dilijan National Park",
		"Lake Parz",
		"Symphony of Stones",
		"Goygol National Park",
		"Hirkan National Park",
		"Duderhof Heights",
		"Agura Waterfalls",
		"Braslav Lakes National Park",
		"Naroch National Park",
		"Pripyatsky National Park",
		"Dovbush Trail",
		"Family Park in Bukovel",
		"Nordkette",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("europe caucasus hiking up migration must avoid duplicating existing broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("europe caucasus hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("europe caucasus hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(downSQL, "europe-caucasus-hiking-v1") {
		t.Fatalf("europe caucasus hiking down migration must remove only tagged route-level places")
	}
}

func TestEuropeCaucasusGapHikingRoutesSeedMigrationAddsMissingHubCoverage(t *testing.T) {
	upSQL := readMigration(t, "106_seed_europe_caucasus_gap_hiking_routes.up.sql")
	downSQL := readMigration(t, "106_seed_europe_caucasus_gap_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_europe_caucasus_gap_hiking_resolved_places AS",
		"europe-caucasus-gap-hiking-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("europe caucasus gap hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"lake-ritsa",
		"mestia",
		"ushguli",
		"artanish",
		"jermuk",
		"quba",
		"grossglockner",
		"swiss-national-park",
		"troodos",
		"bohemian-switzerland",
		"garmisch-partenkirchen",
		"mons-klint",
		"kilpisjarvi",
		"chamonix",
		"lake-district",
		"litochoro",
		"glendalough",
		"snaefellsnes",
		"amalfi-coast",
		"durmitor",
		"dingli",
		"hoge-veluwe",
		"zakopane",
		"madeira",
		"tara",
		"are",
		"cappadocia",
		"chernivtsi",
		"sintra",
		"howth",
		"mullerthal",
		"lahemaa",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("europe caucasus gap hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Yupshara Canyon Forest Trail",
		"Mestia Glacier Valley Trail",
		"Shkhara Valley View Trail",
		"Artanish Peninsula Ridge Walk",
		"Arpa Canyon Resort Trail",
		"Tengealti Canyon Trail",
		"Pasterze Glacier View Trail",
		"Trupchun Valley Wildlife Trail",
		"Troodos Cedar Ridge Trail",
		"Elbe Sandstone Forest Trail",
		"Reintal Gorge Approach Trail",
		"Klinteskoven Cliff Forest Trail",
		"Kilpisjarvi Fell Ridge Trail",
		"Lac Blanc Trail",
		"Catbells Ridge Walk",
		"Prionia Forest Ascent Trail",
		"Spinc and Glenealo Valley Trail",
		"Snaefellsnes Coastal Lava Walk",
		"Path of the Gods Trail",
		"Durmitor Lake Forest Loop",
		"Malta Western Clifftop Walk",
		"Veluwe Sand Drift Trail",
		"Tatra Lake Approach Trail",
		"Pico Ruivo Trail",
		"Banjska Stena Viewpoint Trail",
		"Areskutan Summit Trail",
		"Red Valley Loop Trail",
		"Tsetsyno Ridge Forest Trail",
		"Sintra Cabo da Roca Cliff Walk",
		"Howth Cliff Loop Walk",
		"Mullerthal Schiessentumpel Trail",
		"Lahemaa Viru Bog Boardwalk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("europe caucasus gap hiking up migration must include route-level hiking place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Ritsa Relict National Park",
		"Chalaadi Glacier",
		"Ushguli Village",
		"Sevanavank Monastery",
		"Jermuk Waterfall",
		"Khinalig to Galakhudat Trail",
		"Khinalig Village",
		"Val Trupchun",
		"Artemis Trail",
		"Partnach Gorge",
		"Enipeas Gorge",
		"Black Lake",
		"Dingli Cliffs",
		"Hoge Veluwe National Park",
		"Morskie Oko",
		"Gergeti Trinity Church",
		"Juta and Chaukhi Massif",
		"Lake Parz",
		"Symphony of Stones",
		"Goygol National Park",
		"Hirkan National Park",
		"Nordkette",
		"Meteora Monasteries",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("europe caucasus gap hiking up migration must avoid duplicating existing broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("europe caucasus gap hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("europe caucasus gap hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("europe caucasus gap hiking up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "europe-caucasus-gap-hiking-v1") {
		t.Fatalf("europe caucasus gap hiking down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanRemainingOutdoorRoutesSeedMigrationAddsMoreRouteChoices(t *testing.T) {
	upSQL := readMigration(t, "105_seed_kazakhstan_remaining_outdoor_routes.up.sql")
	downSQL := readMigration(t, "105_seed_kazakhstan_remaining_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_remaining_outdoor_routes_resolved_places AS",
		"kazakhstan-remaining-outdoor-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan remaining outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"ust-kamenogorsk",
		"pavlodar",
		"kokshetau",
		"balkhash",
		"karaganda",
		"kyzylorda",
		"aktobe",
		"oral",
		"aktau",
		"shymkent",
		"turkestan",
		"taraz",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan remaining outdoor routes up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Temirlik Canyon Trail",
		"Bestamak Canyon Rim Trail",
		"First Kolsai Shore Loop",
		"Turgusun Waterfall Forest Trail",
		"Bukhtarma Shore Pine Trail",
		"Chernovaya Uba Forest Trail",
		"Sabyndykol Pine Shore Loop",
		"Birzhankol Granite Trail",
		"Sandyktau Forest Ridge Walk",
		"Shortandy Lake Shore Walk",
		"Karatal Delta Reed Walk",
		"Aksu-Ayuly Steppe Ridge Walk",
		"Kambash Lake Dune Walk",
		"Syrdarya Tugai Walk",
		"Karagaily Mugodzhary Ridge Trail",
		"Bokei Orda Pine Belt Walk",
		"Akkespe Chalk Cliffs Walk",
		"Karaman-Ata Ravine Walk",
		"Kelte-Mashat Canyon Walk",
		"Akmechet Cave Steppe Walk",
		"Zhanatas Karatau Ridge Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan remaining outdoor routes up migration must include additional route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Furmanov Peak",
		"Kara-Kungey Ridge",
		"Kok-Zhailau Plateau",
		"Turgen Gorge",
		"Second Kolsai Lake Trek",
		"Kaindy Lake Viewpoint Trail",
		"Charyn Moon Canyon Trail",
		"Aigaikum Singing Dune Walk",
		"Lineyskie Belki Trail",
		"Maral Lake Altai Trail",
		"West Altai Cedar Loop",
		"Zhasybai Lake Shore Trail",
		"Zhasybai to Toraigyr Traverse",
		"Burabay Green Cape Trail",
		"Balkhash Reed Islands Walk",
		"Karkaraly National Park",
		"Mugodzhary Hills Trail",
		"Kushum River Floodplain Walk",
		"Senek Dune Field Walk",
		"Shakpak-Ata Canyon Walk",
		"Mashat Gorge Trail",
		"Karatau Foothill Trail",
		"Merke Gorge Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan remaining outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan remaining outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan remaining outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan remaining outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-remaining-outdoor-routes-v1") {
		t.Fatalf("kazakhstan remaining outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanFurtherOutdoorRoutesSeedMigrationAddsMoreCountryCoverage(t *testing.T) {
	upSQL := readMigration(t, "107_seed_kazakhstan_further_outdoor_routes.up.sql")
	downSQL := readMigration(t, "107_seed_kazakhstan_further_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_further_outdoor_routes_resolved_places AS",
		"kazakhstan-further-outdoor-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan further outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
		"ust-kamenogorsk",
		"kostanay",
		"karaganda",
		"aktobe",
		"taraz",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan further outdoor routes up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Pioneer Peak Ridge Trail",
		"Sovetov Peak View Trail",
		"Third Kolsai Lake Trek",
		"Boguty Red Mountains Trail",
		"Akkainar-Zhartas Petroglyph Walk",
		"Bayan-Zhurek Petroglyph Ridge Walk",
		"Akbaur Cave Hill Walk",
		"Sarykopa Steppe Lake Walk",
		"Koktinkoli Lake Steppe Walk",
		"Zhamanshin Crater Rim Walk",
		"Kyrshabakty Gorge Fossil Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan further outdoor routes up migration must include additional country route %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Furmanov Peak",
		"Kara-Kungey Ridge",
		"Kok-Zhailau Plateau",
		"Big Almaty Peak Trail",
		"Tourist Peak Approach Trail",
		"Ozerny Peak Moraine Trail",
		"First Kolsai Shore Loop",
		"Second Kolsai Lake Trek",
		"Tamgaly-Tas Rocks",
		"Bektau-Ata",
		"Aksoran Peak Trail",
		"Kyzylkol Lake Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan further outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan further outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan further outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan further outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-further-outdoor-routes-v1") {
		t.Fatalf("kazakhstan further outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanFinalOutdoorRoutesSeedMigrationAddsRemainingStrongChoices(t *testing.T) {
	upSQL := readMigration(t, "109_seed_kazakhstan_final_outdoor_routes.up.sql")
	downSQL := readMigration(t, "109_seed_kazakhstan_final_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_final_outdoor_routes_resolved_places AS",
		"kazakhstan-final-outdoor-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan final outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
		"ust-kamenogorsk",
		"semey",
		"astana",
		"kokshetau",
		"petropavlovsk",
		"aktau",
		"shymkent",
		"turkestan",
		"taraz",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan final outdoor routes up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Ushkonyr Plateau Ridge Walk",
		"Eshkiolmes Petroglyph Hill Walk",
		"Kapal-Arasan Foothill Walk",
		"Shyngystau Ridge Steppe Trail",
		"Ulba River Foothill Trail",
		"Syrymbet Ridge Forest Walk",
		"Akkol Lake Pine Walk",
		"Kapkansor Salt Flat Walk",
		"Oytau Chalk Hills Trail",
		"Karzhantau Ridge View Trail",
		"Kelinshektau Ridge Trail",
		"Tekturmas Hill Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan final outdoor routes up migration must include remaining strong outdoor route %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Gorelnik Waterfalls",
		"Furmanov Peak",
		"Aksai Skete",
		"Kara-Kungey Ridge",
		"Kok-Zhailau Plateau",
		"Big Almaty Peak Trail",
		"Tourist Peak Approach Trail",
		"Ozerny Peak Moraine Trail",
		"Third Kolsai Lake Trek",
		"Konyr-Aulie Cave",
		"Airakty-Shomanai Valley",
		"Kokkol Waterfall Trail",
		"Zerenda Lake Forest Trail",
		"Karagiye Depression Rim Trail",
		"Akbet Peak",
		"Ereymentau Granite Ridge Trail",
		"Burabay Green Cape Trail",
		"Korgalzhyn Reedbed Birding Trail",
		"Torysh Valley",
		"Sherkala Mountain",
		"Karynzharyk Depression View Trail",
		"Zhygylgan Rim Walk",
		"Tuzbair Sunrise Cliffs Trail",
		"Tamshaly Canyon",
		"Aksu-Zhabagly Nature Reserve",
		"Burgulyuk Gorge",
		"Sayram-Su Lake Trail",
		"Akzhaiyk Delta Eco Trail",
		"Kazygurt Mountain Pilgrim Trail",
		"Ulytau Aulietau Summit Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan final outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan final outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan final outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan final outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-final-outdoor-routes-v1") {
		t.Fatalf("kazakhstan final outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanNicheOutdoorRoutesSeedMigrationAddsLastUsefulGaps(t *testing.T) {
	upSQL := readMigration(t, "112_seed_kazakhstan_niche_outdoor_routes.up.sql")
	downSQL := readMigration(t, "112_seed_kazakhstan_niche_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_niche_outdoor_routes_resolved_places AS",
		"kazakhstan-niche-outdoor-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan niche outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"karaganda",
		"aktobe",
		"atyrau",
		"aktau",
		"kyzylorda",
		"shymkent",
		"turkestan",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan niche outdoor routes up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Big Shymbulak Falls Trail",
		"Four Brothers Rocks Trail",
		"Uzun-Kargaly Waterfall Trail",
		"Chukotka Ridge Trail",
		"Kyzyl Kent Monastery Trail",
		"Aktolagay Chalk Plateau Trail",
		"Kendirli Bay Spit Walk",
		"Greater Barsuki Dune Walk",
		"Imankara Cave Hill Trail",
		"Sauskandyk Petroglyph Gorge Trail",
		"Boraldaytau Rock Art Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan niche outdoor routes up migration must include useful niche outdoor route %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Mynzhylky Plateau Trail",
		"Tuyuksu Glacier Trail",
		"Kairak Waterfall Trail",
		"Kaskelen Gorge",
		"Mokhnatka Mountain Trail",
		"Monakhov Gorge",
		"Shymbulak Talgar Pass View Walk",
		"Burkhan-Bulak Waterfall",
		"Lepsy River Valley Trail",
		"Naizatas Rock Trail",
		"Granite Labyrinth Loop near Bektauata",
		"Bektau-Ata",
		"Beket-Ata Plateau Walk",
		"Barsa-Kelmes Desert Edge Trail",
		"Kent Mountains Trail",
		"Ulytau Akmeshit Ridge Trail",
		"Ulytau Edige Peak Trail",
		"Arpa-Uzen Petroglyph Ridge Trail",
		"Kokala Clay Hills Trail",
		"Kiin-Kerish Valley Trail",
		"Kapamsay Canyon Trail",
		"Torysh Valley",
		"Bozzhyra Valley",
		"Shakpak-Ata Canyon Walk",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan niche outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan niche outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan niche outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan niche outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-niche-outdoor-routes-v1") {
		t.Fatalf("kazakhstan niche outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanAdditionalLocalOutdoorRoutesSeedMigrationAddsMoreUsefulPlaces(t *testing.T) {
	upSQL := readMigration(t, "116_seed_kazakhstan_additional_local_outdoor_routes.up.sql")
	downSQL := readMigration(t, "116_seed_kazakhstan_additional_local_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_additional_local_outdoor_routes_resolved_places AS",
		"kazakhstan-additional-local-outdoor-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan additional local outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
		"semey",
		"ust-kamenogorsk",
		"kokshetau",
		"petropavlovsk",
		"aktobe",
		"kyzylorda",
		"shymkent",
		"taraz",
		"balkhash",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan additional local outdoor routes up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Kokbulak Forest Trail",
		"Panorama Peak Trail",
		"Besshatyr Mounds Steppe Walk",
		"Tuzkol Salt Lake Shore Walk",
		"Koksu River Gorge Trail",
		"Tarbagatai Manrak Ridge Trail",
		"Imantau Lake Hills Trail",
		"Donyztau Escarpment Walk",
		"Kamystybas Lake Shore Trail",
		"Kaskasu Juniper Trail",
		"Daubaba Canyon Trail",
		"Irgiz-Turgay Steppe Walk",
		"Mynaral Balkhash Shore Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan additional local outdoor routes up migration must include useful local outdoor route %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Gorelnik Waterfalls",
		"Furmanov Peak",
		"Aksai Skete",
		"Kara-Kungey Ridge",
		"Kok-Zhailau Plateau",
		"Butakovka Gorge",
		"Kimasar Gorge",
		"Kumbel Peak",
		"Prohodnoye Gorge Trail",
		"Prohodnaya River Waterfall Trail",
		"Left Talgar Gorge Trail",
		"Talgar Peak Base Trail",
		"Ketmen Ridge Trail",
		"Tekeli Gorge Trail",
		"Yazevoe Lake Trail",
		"Karagiye Depression Rim Trail",
		"Saura Canyon and Lake Trail",
		"Zerenda Lake Forest Trail",
		"Aksoran Peak Trail",
		"Sairam Peak Base Trail",
		"Bokty Mountain View Trail",
		"Boszhira Fang View Trail",
		"Ushkonyr Plateau Ridge Walk",
		"Karzhantau Ridge View Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan additional local outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan additional local outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan additional local outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan additional local outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-additional-local-outdoor-routes-v1") {
		t.Fatalf("kazakhstan additional local outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanLastOutdoorRouteGapsSeedMigrationAddsOnlyNonDuplicateRoutes(t *testing.T) {
	upSQL := readMigration(t, "117_seed_kazakhstan_last_outdoor_route_gaps.up.sql")
	downSQL := readMigration(t, "117_seed_kazakhstan_last_outdoor_route_gaps.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_last_outdoor_route_gaps_resolved_places AS",
		"kazakhstan-last-outdoor-route-gaps-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan last outdoor route gaps up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"karaganda",
		"taldykorgan",
		"balkhash",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan last outdoor route gaps up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Charyn Ash Grove Walk",
		"Sogety Plateau Ridge Walk",
		"Baceen Lake Stone Trail",
		"Saryesik-Atyrau Desert Edge Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan last outdoor route gaps up migration must include useful non-duplicate route %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Bestamak Canyon Rim Trail",
		"Boguty Red Mountains Trail",
		"Bartogai Reservoir View Trail",
		"Shaitankol Lake Trail",
		"Shaitankol Ridge Walk",
		"Lepsy River Valley Trail",
		"Akbet Peak",
		"Sabyndykol Pine Shore Loop",
		"Zhasybai to Toraigyr Traverse",
		"Kent Mountains Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan last outdoor route gaps up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan last outdoor route gaps up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan last outdoor route gaps up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan last outdoor route gaps up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-last-outdoor-route-gaps-v1") {
		t.Fatalf("kazakhstan last outdoor route gaps down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanMoreOutdoorGapPlacesSeedMigrationAddsDistinctPlaces(t *testing.T) {
	upSQL := readMigration(t, "118_seed_kazakhstan_more_outdoor_gap_places.up.sql")
	downSQL := readMigration(t, "118_seed_kazakhstan_more_outdoor_gap_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_more_outdoor_gap_places_resolved_places AS",
		"kazakhstan-more-outdoor-gap-places-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan more outdoor gap places up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
		"aktau",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan more outdoor gap places up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Kosbastau Oasis Walk",
		"Zhasylkol Lake Trail",
		"Aktogay Canyon Rim Walk",
		"Zhalanashkol Wind Steppe Walk",
		"Ybyqty Sai Canyon Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan more outdoor gap places up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Gorelnik Waterfalls",
		"Furmanov Peak",
		"Aksai Skete",
		"Kara-Kungey Ridge",
		"Kok-Zhailau Plateau",
		"Tamgaly-Tas Rocks",
		"Tamgaly-Tas Climber Path",
		"Bolektau Viewpoint",
		"Zhumbaktas Shore Trail",
		"Korgalzhyn Reedbed Birding Trail",
		"Buiratau National Park",
		"Buiratau Stone Ridge Walk",
		"Kokkol Waterfall Trail",
		"Burkhan-Bulak Waterfall",
		"Lepsy River Valley Trail",
		"Kapamsay Canyon Trail",
		"Zhygylgan Rim Walk",
		"Tuzbair Sunrise Cliffs Trail",
		"Saura Canyon and Lake Trail",
		"Kokala Clay Hills Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan more outdoor gap places up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan more outdoor gap places up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan more outdoor gap places up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan more outdoor gap places up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-more-outdoor-gap-places-v1") {
		t.Fatalf("kazakhstan more outdoor gap places down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanAdditionalOutdoorGapPlacesSeedMigrationAddsNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "119_seed_kazakhstan_additional_outdoor_gap_places.up.sql")
	downSQL := readMigration(t, "119_seed_kazakhstan_additional_outdoor_gap_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_additional_outdoor_gap_places_resolved_places AS",
		"kazakhstan-additional-outdoor-gap-places-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan additional outdoor gap places up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"kokshetau",
		"pavlodar",
		"ust-kamenogorsk",
		"atyrau",
		"kyzylorda",
		"taldykorgan",
		"almaty",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan additional outdoor gap places up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Kenesary Cave Pine Walk",
		"Peak of Courage Toraygir Trail",
		"Gromotukha Gorge Forest Trail",
		"Akkergeshen Chalk Plateau Walk",
		"Kokaral Aral Shore Walk",
		"Tekes River Meadow Trail",
		"Shalkode High Pasture Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan additional outdoor gap places up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Aigaikum Singing Dune Walk",
		"Boguty Red Mountains Trail",
		"Titov Lake Trail",
		"Karagiye Depression Rim Trail",
		"Besshatyr Mounds Steppe Walk",
		"Koksu River Gorge Trail",
		"Imantau-Shalkar Lakes Trail",
		"Akbet Peak",
		"Naizatas Rock Trail",
		"Sairam Peak Base Trail",
		"Kaskasu Juniper Trail",
		"Akbaur Cave Hill Walk",
		"Ulba River Foothill Trail",
		"Austrian Road Katon-Karagay Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan additional outdoor gap places up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan additional outdoor gap places up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan additional outdoor gap places up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan additional outdoor gap places up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-additional-outdoor-gap-places-v1") {
		t.Fatalf("kazakhstan additional outdoor gap places down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanRemoteOutdoorGapRoutesSeedMigrationAddsNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "120_seed_kazakhstan_remote_outdoor_gap_routes.up.sql")
	downSQL := readMigration(t, "120_seed_kazakhstan_remote_outdoor_gap_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_remote_outdoor_gap_routes_resolved_places AS",
		"kazakhstan-remote-outdoor-gap-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan remote outdoor gap routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"karaganda",
		"semey",
		"ust-kamenogorsk",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan remote outdoor gap routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Komissarovka Forester House Walk",
		"Kyzyl-Kensh Palace Valley Trail",
		"Sauyr Muztau Foothill Trail",
		"Tarbagatai Wild Fruit Ridge Trail",
		"Zaysan Lake Steppe Shore Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan remote outdoor gap routes up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Shaitankol Lake Trail",
		"Kent Mountains Trail",
		"Baceen Lake Stone Trail",
		"Karkaraly Three Caves Trail",
		"Pashennoye Lake Forest Trail",
		"Tarbagatai Manrak Ridge Trail",
		"Kiin-Kerish Valley Trail",
		"Markakol Shore Trail",
		"Zhamanshin Crater Rim Walk",
		"Eshkiolmes Petroglyph Hill Walk",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan remote outdoor gap routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan remote outdoor gap routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan remote outdoor gap routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan remote outdoor gap routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-remote-outdoor-gap-routes-v1") {
		t.Fatalf("kazakhstan remote outdoor gap routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanAlmatyOutdoorGapRoutesSeedMigrationAddsNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "121_seed_kazakhstan_almaty_outdoor_gap_routes.up.sql")
	downSQL := readMigration(t, "121_seed_kazakhstan_almaty_outdoor_gap_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_almaty_outdoor_gap_routes_resolved_places AS",
		"kazakhstan-almaty-outdoor-gap-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
		"'walking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan almaty outdoor gap routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan almaty outdoor gap routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Alma-Arasan Spring Valley Walk",
		"Aksai Skete Gorge Walk",
		"Gorelnik Waterfalls Trail",
		"Furmanov Peak Ridge Trail",
		"Kara-Kungey Ridge Trail",
		"Kumbel Peak Ridge Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan almaty outdoor gap routes up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Prohodnaya River Waterfall Trail",
		"Kok-Zhailau Waterfall Trail",
		"Butakovka Waterfall Trail",
		"Turgen Gorge",
		"Bear Falls in Turgen Gorge",
		"Big Almaty Peak Trail",
		"Mynzhylky Plateau Trail",
		"Kairak Waterfall Trail",
		"Ketmen Ridge Trail",
		"Aksu Canyon",
		"Aksoran Peak Trail",
		"Kyzylarai Cedar Valley Walk",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan almaty outdoor gap routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan almaty outdoor gap routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan almaty outdoor gap routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan almaty outdoor gap routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-almaty-outdoor-gap-routes-v1") {
		t.Fatalf("kazakhstan almaty outdoor gap routes down migration must remove only tagged route-level places")
	}
}

func TestGlobalSubagentOutdoorRoutesSeedMigrationAddsNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "122_seed_global_subagent_outdoor_routes.up.sql")
	downSQL := readMigration(t, "122_seed_global_subagent_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_global_subagent_outdoor_routes_resolved_places AS",
		"global-subagent-outdoor-routes-v1",
		"'hiking'",
		"'trekking'",
		"'walking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("global subagent outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, countryCode := range []string{
		"US",
		"CA",
		"BR",
		"AR",
		"KE",
		"TZ",
		"AU",
		"NZ",
		"MA",
		"EG",
		"TR",
		"GE",
		"GR",
		"GB",
		"IS",
		"FR",
		"KR",
		"CN",
		"IN",
		"MY",
		"LK",
	} {
		if !strings.Contains(upSQL, "'"+countryCode+"'") {
			t.Fatalf("global subagent outdoor routes up migration must seed country_code %q", countryCode)
		}
	}

	for _, cityID := range []string{
		"los-angeles",
		"seattle",
		"vancouver",
		"toronto",
		"rio-de-janeiro",
		"ushuaia",
		"nairobi",
		"arusha",
		"perth",
		"adelaide",
		"christchurch",
		"wellington",
		"queenstown",
		"tetouan",
		"ouarzazate",
		"dahab",
		"fethiye",
		"keda",
		"athens",
		"snowdonia",
		"skaftafell",
		"marseille",
		"seoul",
		"seogwipo",
		"nanjing",
		"shillong",
		"mumbai",
		"kuching",
		"haputale",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("global subagent outdoor routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Runyon Canyon Loop",
		"Discovery Park Loop Trail",
		"Grouse Grind Trail",
		"Scarborough Bluffs Trail",
		"Pedra da Gavea Trail",
		"Martial Glacier Trail",
		"Oloolua Nature Trail",
		"Lake Duluti Forest Walk",
		"Bold Park Zamia Trail",
		"Morialta Falls Plateau Hike",
		"Rapaki Track",
		"Red Rocks Coastal Walk",
		"Queenstown Hill Time Walk",
		"Jebel Musa Ridge Trail",
		"Dades Monkey Fingers Walk",
		"Abu Galum to Blue Hole Coastal Trail",
		"Kayakoy to Oludeniz Lycian Way Trail",
		"Machakhela Arched Bridges Trail",
		"Hymettus Kaisariani Forest Trail",
		"Cwm Idwal and Llyn Idwal Walk",
		"Svartifoss Skaftafell Loop",
		"Calanques Port-Miou to En-Vau Trail",
		"Inwangsan Fortress Wall Trail",
		"Jeju Olle Route 7 Coastal Walk",
		"Purple Mountain Greenway Trail",
		"Nongriat Double-Decker Root Bridge Trail",
		"Kanheri Caves Forest Trail",
		"Bako Telok Pandan Kecil Trail",
		"Bambarakanda to Lanka Ella Falls Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("global subagent outdoor routes up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Quarry Rock Trail",
		"Karura Waterfall Loop",
		"Ngurdoto Crater View Trail",
		"Mount Victoria Lookout Walk",
		"Ben Lomond Track",
		"Blue Hole Dahab",
		"Sinai Sunrise Steps Trail",
		"Bukhansan Baegundae Trail",
		"Mount Meru",
		"Dois Irmaos Trail",
		"Howth Cliff Path Loop",
		"Reykjadalur Hot Spring River",
		"Morne Blanc Trail",
		"Dingli Cliffs",
		"Ait Bouguemez Valley",
		"Oludeniz Blue Lagoon",
		"Bambarakanda Falls",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("global subagent outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("global subagent outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("global subagent outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("global subagent outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "global-subagent-outdoor-routes-v1") {
		t.Fatalf("global subagent outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanExtraLocalOutdoorGapRoutesSeedMigrationAddsMoreNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "123_seed_kazakhstan_extra_local_outdoor_gap_routes.up.sql")
	downSQL := readMigration(t, "123_seed_kazakhstan_extra_local_outdoor_gap_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_extra_local_outdoor_gap_routes_resolved_places AS",
		"kazakhstan-extra-local-outdoor-gap-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
		"'walking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan extra local outdoor gap routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"ust-kamenogorsk",
		"kokshetau",
		"pavlodar",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan extra local outdoor gap routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Terisbutak Gorge Descent Trail",
		"Kamenskiy Ridge Ak-Kain Traverse",
		"Tuyuk-Su Crag Approach Walk",
		"Upper Butakovka Falls Trail",
		"Kara-Koba River Valley Trail",
		"Burabay Climber Rocks Walk",
		"Bayanaul Stone Head Ridge Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan extra local outdoor gap routes up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Kok-Zhailau Waterfall Trail",
		"Kamenskoye Plateau Trail",
		"Tuyuksu Glacier Trail",
		"Titov Lake Trail",
		"Butakovka Waterfall Trail",
		"West Altai Cedar Loop",
		"Ridder Stone Bowl Forest Trail",
		"Okzhetpes Rock",
		"Borovushka Forest Loop",
		"Kempirtas Rock Trail",
		"Naizatas Rock Trail",
		"Zhasybai to Toraigyr Traverse",
		"Konyr-Aulie Cave",
		"Akbet Peak",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan extra local outdoor gap routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan extra local outdoor gap routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan extra local outdoor gap routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan extra local outdoor gap routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-extra-local-outdoor-gap-routes-v1") {
		t.Fatalf("kazakhstan extra local outdoor gap routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanAdditionalHikingGapRoutesSeedMigrationAddsRemainingCountryPlaces(t *testing.T) {
	upSQL := readMigration(t, "124_seed_kazakhstan_additional_hiking_gap_routes.up.sql")
	downSQL := readMigration(t, "124_seed_kazakhstan_additional_hiking_gap_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_additional_hiking_gap_routes_resolved_places AS",
		"kazakhstan-additional-hiking-gap-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
		"'walking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan additional hiking gap routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"semey",
		"shymkent",
		"taraz",
		"kokshetau",
		"karaganda",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan additional hiking gap routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Kishi Turgen Gorge Walk",
		"Kolsai Sary-Bulak Pass Trek",
		"Charyn Tazbas Tract Walk",
		"Ulken Buguty Hills Walk",
		"Ashutas Clay Hills Walk",
		"Karalma Gorge Trail",
		"Zhabagly Plateau Walk",
		"Aiyrtau Rock Ridge Walk",
		"Tasmola Stone Ridge Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan additional hiking gap routes up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Bear Falls Turgen",
		"Kairak Waterfall Trail",
		"Issyk Lake Trail",
		"Aktogay Canyon Trail",
		"Karagiye Depression Rim Trail",
		"Karynzharyk Depression View Trail",
		"Kiin-Kerish Valley Trail",
		"Mashat Gorge Trail",
		"Korgalzhyn Reedbed Birding Trail",
		"Kyzylkol Lake Trail",
		"Baldybrek Canyon Trail",
		"Buiratau Stone Ridge Walk",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan additional hiking gap routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan additional hiking gap routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan additional hiking gap routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan additional hiking gap routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-additional-hiking-gap-routes-v1") {
		t.Fatalf("kazakhstan additional hiking gap routes down migration must remove only tagged route-level places")
	}
}

func TestGlobalSubagentAdditionalOutdoorRoutesSeedMigrationAddsMoreCityHubRoutes(t *testing.T) {
	upSQL := readMigration(t, "125_seed_global_subagent_additional_outdoor_routes.up.sql")
	downSQL := readMigration(t, "125_seed_global_subagent_additional_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_global_subagent_additional_outdoor_routes_resolved_places AS",
		"global-subagent-additional-outdoor-routes-v1",
		"'hiking'",
		"'walking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("global subagent additional outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"ottawa",
		"madeira",
		"guadalajara",
		"san-cristobal-de-las-casas",
		"ras-al-khaimah",
		"mestia",
		"catania",
		"belem",
		"byron-bay",
		"launceston",
		"rottnest-island",
		"dhigurah",
		"fethiye",
		"zermatt",
		"chimgan",
		"beau-vallon",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("global subagent additional outdoor routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Mer Bleue Bog Boardwalk",
		"Ponta de Sao Lourenco Trail",
		"Barranca de Huentitan Trail",
		"Huitepec Cloud Forest Trail",
		"Wadi Shawka Dam Loop",
		"Hatsvali Zuruldi Ridge Trail",
		"Sartorius Craters Trail",
		"Utinga State Park Trail",
		"Cape Byron Walking Track",
		"Cataract Gorge Basin Loop",
		"Wadjemup Bidi Coastal Trail",
		"Dhigurah Sandbank Walk",
		"Butterfly Valley Faralya View Trail",
		"Riffelsee Gornergrat Panorama Trail",
		"Chimgan Gulkam Gorge Trail",
		"Dans Gallas Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("global subagent additional outdoor routes up migration must include non-duplicate route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Rideau Canal",
		"Pico do Arieiro",
		"Guadalajara Cathedral",
		"Sumidero Canyon",
		"Jebel Jais",
		"Koruldi Lakes",
		"Mount Etna",
		"Mangal das Garcas",
		"Cape Byron Lighthouse",
		"'Cataract Gorge',",
		"Thomson Bay Rottnest Island",
		"Dhigurah Long Beach",
		"Saklikent Canyon",
		"Five Lakes Trail",
		"Greater Chimgan Trail",
		"Anse Major Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("global subagent additional outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("global subagent additional outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("global subagent additional outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("global subagent additional outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "global-subagent-additional-outdoor-routes-v1") {
		t.Fatalf("global subagent additional outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanExtraOutdoorGapRoutesSeedMigrationAddsMoreNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "126_seed_kazakhstan_extra_outdoor_gap_routes.up.sql")
	downSQL := readMigration(t, "126_seed_kazakhstan_extra_outdoor_gap_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_extra_outdoor_gap_routes_resolved_places AS",
		"kazakhstan-extra-outdoor-gap-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan extra outdoor gap routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
		"shymkent",
		"taraz",
		"ust-kamenogorsk",
		"semey",
		"aktau",
		"kyzylorda",
		"karaganda",
		"kokshetau",
		"aktobe",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan extra outdoor gap routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Right Talgar Valley Trail",
		"Bartogay Reservoir Shore Walk",
		"Ketpen Ridge Foothill Trail",
		"Kaskabulak Gorge Trail",
		"Kshi-Kaindy Gorge Trail",
		"Zhabaglysu River Trail",
		"Yazevoye Lake Shore Trail",
		"Koktau Ridge Sibiny Walk",
		"Urkashar Ridge Trail",
		"Saura Lake Shore Walk",
		"Kelinshiktau Ridge Walk",
		"Karkaraly Komsomol Peak Trail",
		"Jeke Batyr Ridge Walk",
		"Katarkol Pine Shore Walk",
		"Kokzhide Sands Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan extra outdoor gap routes up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Left Talgar Gorge Trail",
		"Ushkonyr Plateau Ridge Walk",
		"Kora Gorge Trail",
		"Burkhan-Bulak Waterfall",
		"Tarbagatai Manrak Ridge Trail",
		"Airakty-Shomanai Valley",
		"Kyzylkup Rainbow Hills Trail",
		"Kokkol Waterfall Trail",
		"Shaitankol Ridge Walk",
		"Bolektau Viewpoint",
		"Naurzum Pine Lake Birding Trail",
		"Zhygylgan Rim Walk",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan extra outdoor gap routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan extra outdoor gap routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan extra outdoor gap routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan extra outdoor gap routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-extra-outdoor-gap-routes-v1") {
		t.Fatalf("kazakhstan extra outdoor gap routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanLastHiddenOutdoorRoutesSeedMigrationAddsMoreNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "127_seed_kazakhstan_last_hidden_outdoor_routes.up.sql")
	downSQL := readMigration(t, "127_seed_kazakhstan_last_hidden_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_last_hidden_outdoor_routes_resolved_places AS",
		"kazakhstan-last-hidden-outdoor-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan last hidden outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
		"semey",
		"ust-kamenogorsk",
		"kokshetau",
		"petropavlovsk",
		"aktau",
		"zhezkazgan",
		"taraz",
		"turkestan",
		"shymkent",
		"kostanay",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan last hidden outdoor routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Kazachka Waterfall Trail",
		"Amangeldy Peak Approach Trail",
		"Kokpekty River Gorge Trail",
		"Keregetas Rocks Walk",
		"Shilikty Valley Heritage Walk",
		"Shalkar-Imantau Shore Walk",
		"Kokshetau Blue Bay Forest Walk",
		"Sherkala North Ridge Walk",
		"Baskamyr Steppe Valley Walk",
		"Berkara Gorge Trail",
		"Borolday Petroglyph Gorge Walk",
		"Turgay Geoglyph Steppe Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan last hidden outdoor routes up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Kiin-Kerish Mars Valley Walk",
		"Tuzbair Sunrise Cliffs Trail",
		"Akkergeshen Chalk Plateau Walk",
		"Akmechet Cave Steppe Walk",
		"Assy Plateau",
		"Bektau-Ata",
		"Tamshaly Canyon",
		"Sinyukha Peak Trail",
		"Imantau Lake Hills Trail",
		"Ulytau Aulietau Summit Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan last hidden outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan last hidden outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan last hidden outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan last hidden outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-last-hidden-outdoor-routes-v1") {
		t.Fatalf("kazakhstan last hidden outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanFinalMicrogapOutdoorRoutesSeedMigrationAddsMoreNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "128_seed_kazakhstan_final_microgap_outdoor_routes.up.sql")
	downSQL := readMigration(t, "128_seed_kazakhstan_final_microgap_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_final_microgap_outdoor_routes_resolved_places AS",
		"kazakhstan-final-microgap-outdoor-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan final microgap outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
		"shymkent",
		"kostanay",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan final microgap outdoor routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Qotyrbulaq Forest Valley Walk",
		"Kuigensai Moraine Lakes Trail",
		"Narynkol Khan Tengri View Walk",
		"Bayankol Glacier Valley Trail",
		"Ketmen Pass Caravan Trail",
		"Upper Aksu Gorge View Trail",
		"Tersek-Karagay Pine Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan final microgap outdoor routes up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Gorelnik Waterfalls Trail",
		"Kazachka Waterfall Trail",
		"Mynzhylky Plateau Trail",
		"Alpengrad High Camp Trail",
		"Tuzkol Salt Lake Shore Walk",
		"Ketpen Ridge Foothill Trail",
		"Aksu Canyon",
		"Naurzum Pine and Lake Trail",
		"Naurzum Pine Lake Birding Trail",
		"Akbet Peak",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan final microgap outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan final microgap outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan final microgap outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan final microgap outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-final-microgap-outdoor-routes-v1") {
		t.Fatalf("kazakhstan final microgap outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanLastCityNatureMicroRoutesSeedMigrationAddsMoreNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "129_seed_kazakhstan_last_city_nature_micro_routes.up.sql")
	downSQL := readMigration(t, "129_seed_kazakhstan_last_city_nature_micro_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_last_city_nature_micro_routes_resolved_places AS",
		"kazakhstan-last-city-nature-micro-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan last city nature micro routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"kokshetau",
		"petropavlovsk",
		"turkestan",
		"kyzylorda",
		"oral",
		"kostanay",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan last city nature micro routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Bukpa Hill City Trail",
		"Arykbalyk Lake Forest Trail",
		"Tutybulak Cave Tugai Walk",
		"Daryalyktakyr Takyr Plain Walk",
		"Ural-Chagan Riverbank Walk",
		"Karatomar Reservoir Shore Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan last city nature micro routes up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Bear Falls in Turgen Gorge",
		"Kaskelen Gorge",
		"Monakhov Gorge",
		"Big Shymbulak Falls Trail",
		"Burkhan-Bulak Waterfall",
		"Aktau Mountains Red Gorge Trail",
		"Katutau Volcanic Hills Trail",
		"Besshatyr Mounds Steppe Walk",
		"Korgalzhyn Reedbed Birding Trail",
		"Irgiz-Turgay Steppe Walk",
		"Semey Irtysh Island Trail",
		"Tersek-Karagay Pine Walk",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan last city nature micro routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan last city nature micro routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan last city nature micro routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan last city nature micro routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-last-city-nature-micro-routes-v1") {
		t.Fatalf("kazakhstan last city nature micro routes down migration must remove only tagged route-level places")
	}
}

func TestGlobalNearCompletionOutdoorRoutesSeedMigrationClosesHighSignalHubGaps(t *testing.T) {
	upSQL := readMigration(t, "130_seed_global_near_completion_outdoor_routes.up.sql")
	downSQL := readMigration(t, "130_seed_global_near_completion_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_global_near_completion_outdoor_routes_resolved_places AS",
		"global-near-completion-outdoor-routes-v1",
		"'hiking'",
		"'walking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("global near completion outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, countryCode := range []string{
		"'IN'",
		"'KG'",
		"'CY'",
		"'MN'",
		"'TJ'",
		"'AE'",
		"'UZ'",
	} {
		if !strings.Contains(upSQL, countryCode) {
			t.Fatalf("global near completion outdoor routes up migration must include country_code %q", countryCode)
		}
	}

	for _, cityID := range []string{
		"delhi",
		"osh",
		"nicosia",
		"paphos",
		"murun",
		"tsetserleg",
		"ishkashim",
		"kulob",
		"ajman",
		"sharjah",
		"umm-al-quwain",
		"tashkent",
		"aral-sea",
		"urgench",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("global near completion outdoor routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Sanjay Van Ridge Forest Trail",
		"Sulaiman-Too Southern Slope Walk",
		"Athalassa Forest Park Loop",
		"Akamas Aphrodite Trail",
		"Uushgiin Uver Deer Stones Walk",
		"Taikhar Rock Steppe Loop",
		"Ishkashim Panj River Terrace Walk",
		"Dashti-Jum Reserve Ridge Trail",
		"Al Zorah Mangrove Lagoon Walk",
		"Mleiha Fossil Rock Trail",
		"Umm Al Quwain Mangrove Lagoon Walk",
		"Ankhor Canal Green Walk",
		"Aral Sea Ustyurt Cliff Walk",
		"Kyzyl-Kala Fortress Steppe Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("global near completion outdoor routes up migration must include useful non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Sulaiman-Too Sacred Mountain",
		"Al Zorah Nature Reserve",
		"Mangrove Beach Umm Al Quwain",
		"Wakhan Valley Road",
		"Childukhtaron Ridge Trail",
		"Toprak-Kala Desert Loop Trail",
		"Sudochye Lake Ustyurt Birding Trail",
		"Moynaq Aral Seabed Dune Walk",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("global near completion outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("global near completion outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("global near completion outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("global near completion outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "global-near-completion-outdoor-routes-v1") {
		t.Fatalf("global near completion outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanAdditionalVerifiedOutdoorRoutesSeedMigrationAddsRemainingNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "131_seed_kazakhstan_additional_verified_outdoor_routes.up.sql")
	downSQL := readMigration(t, "131_seed_kazakhstan_additional_verified_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_additional_verified_outdoor_routes_resolved_places AS",
		"kazakhstan-additional-verified-outdoor-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
		"'birdwatching'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan additional verified outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"astana",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan additional verified outdoor routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Chinturgen Moss Spruce Forest Walk",
		"Charyn Valley of Castles Walk",
		"Kurtogay Canyon View Walk",
		"Tengiz Lake Flamingo Shore Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan additional verified outdoor routes up migration must include remaining non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Temirlik Canyon Trail",
		"Bestamak Canyon Rim Trail",
		"Charyn Ash Grove Walk",
		"Charyn Tazbas Tract Walk",
		"Korgalzhyn Reedbed Birding Trail",
		"Prohodnoye Gorge Trail",
		"Bear Falls in Turgen Gorge",
		"Kairak Waterfall Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan additional verified outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan additional verified outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan additional verified outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan additional verified outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-additional-verified-outdoor-routes-v1") {
		t.Fatalf("kazakhstan additional verified outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanAdditionalMicroOutdoorRoutesSeedMigrationAddsMoreNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "132_seed_kazakhstan_additional_micro_outdoor_routes.up.sql")
	downSQL := readMigration(t, "132_seed_kazakhstan_additional_micro_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_additional_micro_outdoor_routes_resolved_places AS",
		"kazakhstan-additional-micro-outdoor-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
		"'free-entry'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan additional micro outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"kostanay",
		"pavlodar",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan additional micro outdoor routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Medeu Dam Stairs Walk",
		"Kok Tobe Footpath Ascent",
		"Esentai River Green Walk",
		"Sayran Lake Loop Walk",
		"Tobol River Embankment Walk",
		"Irtysh River Embankment Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan additional micro outdoor routes up migration must include non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Medeu Alpine Skating Rink",
		"Medeu Terrenkur Health Trail",
		"Kok Tobe Hill and Cable Car",
		"Central Park Almaty",
		"First President Park",
		"Almaty Botanical Garden",
		"Karatomar Reservoir Shore Walk",
		"Ubagan River Valley Walk",
		"Semey Irtysh Island Trail",
	} {
		if strings.Contains(upSQL, "'"+duplicateTitle+"'") {
			t.Fatalf("kazakhstan additional micro outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan additional micro outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan additional micro outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan additional micro outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-additional-micro-outdoor-routes-v1") {
		t.Fatalf("kazakhstan additional micro outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanRemainingCitySteppeMicroRoutesSeedMigrationAddsLastNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "135_seed_kazakhstan_remaining_city_steppe_micro_routes.up.sql")
	downSQL := readMigration(t, "135_seed_kazakhstan_remaining_city_steppe_micro_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_remaining_city_steppe_micro_routes_resolved_places AS",
		"kazakhstan-remaining-city-steppe-micro-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
		"'free-entry'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan remaining city steppe micro routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"taraz",
		"shymkent",
		"aktobe",
		"astana",
		"almaty",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan remaining city steppe micro routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Talas Riverbank Walk",
		"Badam River Green Walk",
		"Sazdy Reservoir Shore Walk",
		"Yesil Riverside Walk",
		"Kapchagay Reservoir Shore Walk",
		"Zhambyl Massif Steppe Ridge Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan remaining city steppe micro routes up migration must include non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Tekturmas Hill Walk",
		"Syrdarya Tugai Walk",
		"Astana Botanical Garden",
		"Tobol River Embankment Walk",
		"Irtysh River Embankment Walk",
		"Bartogai Reservoir View Trail",
		"Tamgaly-Tas Rocks",
	} {
		if strings.Contains(upSQL, "'"+duplicateTitle+"'") {
			t.Fatalf("kazakhstan remaining city steppe micro routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan remaining city steppe micro routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan remaining city steppe micro routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan remaining city steppe micro routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-remaining-city-steppe-micro-routes-v1") {
		t.Fatalf("kazakhstan remaining city steppe micro routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanMoreVerifiedHikingRoutesSeedMigrationAddsNextNonDuplicateLayer(t *testing.T) {
	upSQL := readMigration(t, "136_seed_kazakhstan_more_verified_hiking_routes.up.sql")
	downSQL := readMigration(t, "136_seed_kazakhstan_more_verified_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_more_verified_hiking_routes_resolved_places AS",
		"kazakhstan-more-verified-hiking-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
		"'free-entry'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan more verified hiking routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"shymkent",
		"turkestan",
		"aktau",
		"kyzylorda",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan more verified hiking routes up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Maralsay Gorge Trail",
		"Prosveshchenets Pass Trail",
		"Pogrebetsky Glacier View Trail",
		"Tuyuk-Su Gate Moraine Walk",
		"Butakovka Pass Forest Trail",
		"Kumbel Pass Ridge Walk",
		"Kyrkkyz Ridge Trail",
		"Ordabasy Hill Steppe Walk",
		"Kenderli-Kayasan Cliff Walk",
		"Syrdarya Delta Reed Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan more verified hiking routes up migration must include non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Waterfalls Trail",
		"Furmanov Peak Ridge Trail",
		"Aksai Skete Gorge Walk",
		"Kara-Kungey Ridge Trail",
		"Medeu Terrenkur Health Trail",
		"Medeu Dam Stairs Walk",
		"Kaskelen Gorge",
		"Kora Gorge Trail",
		"Kokzhide Sands Walk",
	} {
		if strings.Contains(upSQL, "'"+duplicateTitle+"'") {
			t.Fatalf("kazakhstan more verified hiking routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan more verified hiking routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan more verified hiking routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan more verified hiking routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-more-verified-hiking-routes-v1") {
		t.Fatalf("kazakhstan more verified hiking routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanWeakHubOutdoorDepthSeedMigrationAddsNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "137_seed_kazakhstan_weak_hub_outdoor_depth.up.sql")
	downSQL := readMigration(t, "137_seed_kazakhstan_weak_hub_outdoor_depth.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_weak_hub_outdoor_depth_resolved_places AS",
		"kazakhstan-weak-hub-outdoor-depth-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
		"'free-entry'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan weak hub outdoor depth up migration must contain %q", fragment)
		}
	}
	assertMigrationDoesNotSeedExternalWikimediaMedia(t, upSQL, "kazakhstan weak hub outdoor depth")

	for _, cityID := range []string{
		"petropavlovsk",
		"aktobe",
		"atyrau",
		"kostanay",
		"kyzylorda",
		"oral",
		"balkhash",
		"zhezkazgan",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan weak hub outdoor depth up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Sergeyev Reservoir Shore Walk",
		"Shalkarteniz Salt Flat Walk",
		"Kigach Delta Reed Walk",
		"Aksuat Lake Reed Walk",
		"Aral Karakum Dune Walk",
		"Aralsor Salt Lake Walk",
		"Tokrau Dry Delta Walk",
		"Karsakpai Steppe Heritage Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan weak hub outdoor depth up migration must include non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Syrymbet Ridge Forest Walk",
		"Aiyrtau Rock Ridge Walk",
		"Imantau Lake Pine Shore Walk",
		"Aktolagay Chalk Plateau Walk",
		"Aktolagay Chalk Plateau Trail",
		"Imankara Cave Hill Trail",
		"Tersek-Karagai Pine Forest Walk",
		"Tersek-Karagay Pine Walk",
		"Kambash Lake Shore Walk",
		"Kambash Lake Dune Walk",
		"Kamyslybas Lake Shore Trail",
		"Ural River Floodplain Island Walk",
		"Shalkar Lake Shore Walk",
		"Kushum River Floodplain Walk",
		"Akzhaiyk Reserve Boardwalk Trail",
		"Inder Salt Dome View Walk",
		"Naurzum Pine Lake Birding Trail",
		"Barsa-Kelmes Desert Edge Trail",
		"Syrdarya Delta Reed Walk",
		"Bektau-Ata Cave Summit Trail",
		"Granite Labyrinth Loop near Bektauata",
		"Aulie Cave Granite Trail",
		"Ulytau Aulietau Summit Trail",
		"Terekty Aulie Petroglyph Trail",
	} {
		if strings.Contains(upSQL, "'"+duplicateTitle+"'") {
			t.Fatalf("kazakhstan weak hub outdoor depth up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan weak hub outdoor depth up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan weak hub outdoor depth up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan weak hub outdoor depth up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-weak-hub-outdoor-depth-v1") {
		t.Fatalf("kazakhstan weak hub outdoor depth down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanSouthSoutheastOutdoorDepthSeedMigrationAddsNonDuplicatePlaces(t *testing.T) {
	upSQL := readMigration(t, "138_seed_kazakhstan_south_southeast_outdoor_depth.up.sql")
	downSQL := readMigration(t, "138_seed_kazakhstan_south_southeast_outdoor_depth.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_south_southeast_outdoor_depth_resolved_places AS",
		"kazakhstan-south-southeast-outdoor-depth-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'walking'",
		"'free-entry'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan south southeast outdoor depth up migration must contain %q", fragment)
		}
	}
	assertMigrationDoesNotSeedExternalWikimediaMedia(t, upSQL, "kazakhstan south southeast outdoor depth")

	for _, cityID := range []string{
		"almaty",
		"shymkent",
		"taldykorgan",
		"taraz",
		"turkestan",
		"kyzylorda",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan south southeast outdoor depth up migration must seed place linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Baum Grove Walk",
		"Sayramsu Lake Trail",
		"Makpal Lake Route",
		"Kaskasu-Susingen Lake Route",
		"Saryaygyr Gorge Trail",
		"Ptichiy Bazar View Trail",
		"Boztorgay Stream Walk",
		"Shumsky Glacier View Trail",
		"Sarkand Forest Walk",
		"Sievers Apple Forest Eco Trail",
		"Teris-Ashybulak Reservoir Shore Walk",
		"Moiynkum Desert Edge Walk",
		"Aksumbe Karatau Tower View Walk",
		"Aralkum Desert View Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan south southeast outdoor depth up migration must include non-duplicate place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Issyk Lake Trail",
		"Assy Plateau",
		"Bear Falls Turgen",
		"Kairak Waterfall Trail",
		"Bogdanovich Glacier View Trail",
		"Burkhan-Bulak Waterfall Trail",
		"Tekeli Gorge Trail",
		"Sazanata Gorge Trail",
		"Dzungarian Alatau National Park",
		"Zhasylkol Lake Trail",
		"Left Talgar Gorge Trail",
		"Prohodnoye Gorge Trail",
		"Mynzhylky Plateau Trail",
		"Aral Karakum Dune Walk",
	} {
		if strings.Contains(upSQL, "'"+duplicateTitle+"'") {
			t.Fatalf("kazakhstan south southeast outdoor depth up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan south southeast outdoor depth up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan south southeast outdoor depth up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan south southeast outdoor depth up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-south-southeast-outdoor-depth-v1") {
		t.Fatalf("kazakhstan south southeast outdoor depth down migration must remove only tagged route-level places")
	}
}

func TestRemoveSeededWikimediaPlaceMediaMigrationDeletesOnlyPlaceholderExternalMedia(t *testing.T) {
	upSQL := readMigration(t, "139_remove_seeded_wikimedia_place_media.up.sql")
	downSQL := readMigration(t, "139_remove_seeded_wikimedia_place_media.down.sql")

	requiredFragments := []string{
		"DELETE FROM place_media",
		"file_id = '00000000-0000-0000-0000-000000000000'::uuid",
		"commons.wikimedia.org",
		"upload.wikimedia.org",
		"wikipedia.org",
		"external_url",
		"source_url",
		"credit",
		"license",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("remove seeded wikimedia place media up migration must contain %q", fragment)
		}
	}
	if strings.Contains(upSQL, "DELETE FROM places") {
		t.Fatalf("remove seeded wikimedia place media up migration must not delete places")
	}
	if !strings.Contains(downSQL, "Intentionally no-op") {
		t.Fatalf("remove seeded wikimedia place media down migration must document that deleted external media is not restored")
	}
}

func assertMigrationDoesNotSeedExternalWikimediaMedia(t *testing.T, sql string, migrationName string) {
	t.Helper()

	for _, forbiddenFragment := range []string{
		"INSERT INTO place_media",
		"commons.wikimedia.org",
		"upload.wikimedia.org",
		"wikipedia.org",
		"Wikimedia Commons contributors",
		"See Wikimedia Commons source page",
		"media_url",
		"media_source_url",
	} {
		if strings.Contains(sql, forbiddenFragment) {
			t.Fatalf("%s migration must not seed external Wiki/Wikimedia media, found %q", migrationName, forbiddenFragment)
		}
	}
}

func TestGlobalAdditionalOutdoorRoutePlacesSeedMigrationAddsMoreNonDuplicateRoutes(t *testing.T) {
	upSQL := readMigration(t, "133_seed_global_additional_outdoor_route_places.up.sql")
	downSQL := readMigration(t, "133_seed_global_additional_outdoor_route_places.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_global_additional_outdoor_route_places_resolved_places AS",
		"global-additional-outdoor-route-places-v1",
		"'hiking'",
		"'walking'",
		"'free-entry'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("global additional outdoor route places up migration must contain %q", fragment)
		}
	}

	for _, countryCode := range []string{
		"'US'",
		"'MX'",
		"'SC'",
		"'GE'",
		"'CZ'",
		"'EE'",
		"'FI'",
		"'LU'",
		"'FR'",
		"'AU'",
		"'NZ'",
		"'JP'",
		"'KR'",
		"'CN'",
		"'MY'",
	} {
		if !strings.Contains(upSQL, countryCode) {
			t.Fatalf("global additional outdoor route places up migration must include country_code %q", countryCode)
		}
	}

	for _, cityID := range []string{
		"new-york",
		"washington-dc",
		"portland",
		"san-diego",
		"cozumel",
		"mahe",
		"tbilisi",
		"bohemian-switzerland",
		"lahemaa",
		"kilpisjarvi",
		"berdorf",
		"marseille",
		"kakadu",
		"waitakere-ranges",
		"nikko",
		"jeju",
		"zhangjiajie",
		"kuching",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("global additional outdoor route places up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Inwood Hill Park Forest Trail",
		"Theodore Roosevelt Island Loop Trail",
		"Forest Park Wildwood Trail Segment",
		"Torrey Pines Beach Trail Loop",
		"Punta Sur Lagoon Boardwalk",
		"Morne Seychellois Summit Trail",
		"Kojori to Udzo Monastery Ridge Trail",
		"Gabriela Sandstone Balcony Trail",
		"Oandu Beaver Forest Trail",
		"Kilpisjarvi Border Fell Walk",
		"Berdorf Wanterbaach Rock Trail",
		"Sugiton Belvedere Trail",
		"Nawurlandja Lookout Walk",
		"Mercer Bay Loop Track",
		"Kanmangafuchi Abyss Riverside Walk",
		"Hallasan Eorimok Trail",
		"Huangshi Village Loop Trail",
		"Mount Santubong Summit Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("global additional outdoor route places up migration must include route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Central Park",
		"National Mall and Memorial Parks",
		"Washington Park Portland",
		"La Jolla Cove",
		"Cozumel Reefs",
		"Morne Seychellois National Park",
		"Tbilisi National Park",
		"Bohemian Switzerland National Park",
		"Lahemaa National Park",
		"Three-Country Cairn",
		"Mullerthal Trail",
		"Calanques National Park",
		"Kakadu Ubirr",
		"Waitakere Ranges Regional Park",
		"Nikko Toshogu Shrine",
		"Hallasan National Park",
		"Zhangjiajie National Forest Park",
		"Bako National Park",
	} {
		if strings.Contains(upSQL, "'"+duplicateTitle+"'") {
			t.Fatalf("global additional outdoor route places up migration must avoid duplicating existing broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("global additional outdoor route places up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("global additional outdoor route places up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("global additional outdoor route places up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "global-additional-outdoor-route-places-v1") {
		t.Fatalf("global additional outdoor route places down migration must remove only tagged route-level places")
	}
}

func TestEuropeMenaAdditionalCityWalkRoutesSeedMigrationAddsAgentVerifiedPlaces(t *testing.T) {
	upSQL := readMigration(t, "134_seed_europe_mena_additional_city_walk_routes.up.sql")
	downSQL := readMigration(t, "134_seed_europe_mena_additional_city_walk_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_europe_mena_additional_city_walk_routes_resolved_places AS",
		"europe-mena-additional-city-walk-routes-v1",
		"'hiking'",
		"'walking'",
		"'free-entry'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("europe mena additional city walk routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"paris",
		"london",
		"berlin",
		"barcelona",
		"prague",
		"lisbon",
		"dubai",
		"amsterdam",
		"helsinki",
		"stockholm",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("europe mena additional city walk routes up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Coulee Verte Rene-Dumont Walk",
		"Parkland Walk",
		"Havelhoehenweg Grunewald Trail",
		"Carretera de les Aigues Walk",
		"Divoka Sarka Valley Trail",
		"Monsanto Forest Park Loop",
		"Palm Jumeirah Boardwalk",
		"Amsterdamse Bos Walking Loop",
		"Paloheina Central Park Trail",
		"Nackareservatet Hellasgarden Loop",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("europe mena additional city walk routes up migration must include route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Appian Way Regional Park",
		"Larnaca Salt Lake",
		"Luxembourg Gardens",
		"Hyde Park",
		"Tiergarten",
		"Park Guell",
		"Stromovka Park",
		"Parque Eduardo VII",
		"Palm Jumeirah",
		"Vondelpark Outer Loop Walk",
		"Esplanadi Park",
		"Djurgarden Waterfront Forest Walk",
	} {
		if strings.Contains(upSQL, "'"+duplicateTitle+"'") {
			t.Fatalf("europe mena additional city walk routes up migration must avoid duplicating existing broad or route place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("europe mena additional city walk routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("europe mena additional city walk routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("europe mena additional city walk routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "europe-mena-additional-city-walk-routes-v1") {
		t.Fatalf("europe mena additional city walk routes down migration must remove only tagged route-level places")
	}
}

func TestEuropeMiddleEastCityHubOutdoorRoutesSeedMigrationAddsUncoveredHubs(t *testing.T) {
	upSQL := readMigration(t, "113_seed_europe_middle_east_city_hub_outdoor_routes.up.sql")
	downSQL := readMigration(t, "113_seed_europe_middle_east_city_hub_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_europe_middle_east_city_hub_outdoor_routes_resolved_places AS",
		"europe-middle-east-city-hub-outdoor-routes-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("europe middle east city hub outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"abu-dhabi",
		"dubai",
		"sevan",
		"gobustan",
		"gabala",
		"borjomi",
		"chania",
		"santorini",
		"meteora",
		"montserrat",
		"lake-garda",
		"lake-como",
		"setubal",
		"istanbul",
		"cairo",
		"fruska-gora",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("europe middle east city hub outdoor routes up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Jubail Mangrove Boardwalk",
		"Ras Al Khor Flamingo Boardwalk",
		"Sevan Peninsula Monastery Walk",
		"Gobustan Mud Volcanoes Ridge Walk",
		"Tufandag Mountain Ridge Trail",
		"Likani to Lomismta Trail",
		"Samaria Gorge Trail",
		"Santorini Fira to Oia Caldera Walk",
		"Meteora Monastery Ridge Walk",
		"Montserrat Sant Jeroni Trail",
		"Busatte Tempesta Trail",
		"Greenway del Lago di Como Walk",
		"Arrabida Coastal Ridge Trail",
		"Belgrad Forest Neset Suyu Trail",
		"Wadi Degla Canyon Trail",
		"Fruska Gora Iriski Venac Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("europe middle east city hub outdoor routes up migration must include uncovered hub route %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Jubail Mangrove Park",
		"Ras Al Khor Wildlife Sanctuary",
		"Lake Sevan",
		"Sevanavank Monastery",
		"Lake Sevan Public Beach",
		"Gobustan Rock Art Cultural Landscape",
		"Gabala Tufandag Mountain Resort",
		"Nohur Lake",
		"Borjomi Central Park",
		"Borjomi-Kharagauli National Park",
		"Old Venetian Harbor Chania",
		"Balos Lagoon",
		"Santorini Caldera",
		"Oia Sunset",
		"Fira Old Port",
		"Meteora Monasteries",
		"Kalambaka Old Town",
		"Santa Maria de Montserrat Abbey",
		"Montserrat Natural Park",
		"Gardaland Resort",
		"Scaliger Castle of Sirmione",
		"Jamaica Beach",
		"Lake Como Bellagio",
		"Villa Melzi Gardens",
		"Villa Carlotta",
		"Arrabida Natural Park",
		"Praia de Galapinhos",
		"Gulhane Park",
		"Princes' Islands",
		"Al Azhar Park",
		"Cairo Food Walk",
		"Fruska Gora National Park",
		"Novo Hopovo Monastery",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("europe middle east city hub outdoor routes up migration must avoid duplicating broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("europe middle east city hub outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("europe middle east city hub outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("europe middle east city hub outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "europe-middle-east-city-hub-outdoor-routes-v1") {
		t.Fatalf("europe middle east city hub outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestAsiaOceaniaCentralAsiaCityHubOutdoorRoutesSeedMigrationAddsUncoveredHubs(t *testing.T) {
	upSQL := readMigration(t, "114_seed_asia_oceania_central_asia_city_hub_outdoor_routes.up.sql")
	downSQL := readMigration(t, "114_seed_asia_oceania_central_asia_city_hub_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_asia_oceania_central_asia_city_hub_outdoor_routes_resolved_places AS",
		"asia-oceania-central-asia-city-hub-outdoor-routes-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("asia oceania central asia city hub outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"balykchy",
		"varzob",
		"wakhan-valley",
		"khuvsgul",
		"altai-tavan-bogd",
		"gold-coast",
		"waiheke-island",
		"waitakere-ranges",
		"huangshan",
		"lijiang",
		"hakone",
		"jeju",
		"pai",
		"miri",
		"sigiriya",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("asia oceania central asia city hub outdoor routes up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Balykchy Lakeside Promenade Walk",
		"Varzob Riverside Mountain Trail",
		"Wakhan Valley Panj River Walk",
		"Khuvsgul West Shore Forest Trail",
		"Malchin Peak Base Trail",
		"Burleigh Head Oceanview Circuit",
		"Te Ara Hura Coastal Walk",
		"Kitekite Falls Track",
		"Xihai Grand Canyon Trail",
		"Haba Snow Mountain High Trail",
		"Hakone Old Tokaido Cedar Avenue Walk",
		"Hallasan Seongpanak Trail",
		"Pai Red Ridge Loop",
		"Lambir Hills Latak Waterfall Trail",
		"Pidurangala Sunrise Rock Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("asia oceania central asia city hub outdoor routes up migration must include uncovered hub route %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Balykchy Lakefront",
		"Varzob Gorge",
		"Varzob Waterfall Trail",
		"Wakhan Valley Road",
		"Khuvsgul Lake National Park",
		"Khuvsgul East Shore Trail",
		"Altai Tavan Bogd National Park",
		"Potanin Glacier Base Trail",
		"Burleigh Head National Park",
		"Waiheke Island",
		"Piha Beach",
		"Waitakere Ranges Regional Park",
		"Yellow Mountain",
		"Tiger Leaping Gorge",
		"Lake Ashi",
		"Hallasan National Park",
		"Pai Canyon",
		"Lambir Hills National Park",
		"Pidurangala Rock",
		"Sigiriya Rock Fortress",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("asia oceania central asia city hub outdoor routes up migration must avoid duplicating broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("asia oceania central asia city hub outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("asia oceania central asia city hub outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("asia oceania central asia city hub outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "asia-oceania-central-asia-city-hub-outdoor-routes-v1") {
		t.Fatalf("asia oceania central asia city hub outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestAmericasAfricaIslandCityHubOutdoorRoutesSeedMigrationAddsUncoveredHubs(t *testing.T) {
	upSQL := readMigration(t, "115_seed_americas_africa_island_city_hub_outdoor_routes.up.sql")
	downSQL := readMigration(t, "115_seed_americas_africa_island_city_hub_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_americas_africa_island_city_hub_outdoor_routes_resolved_places AS",
		"americas-africa-island-city-hub-outdoor-routes-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("americas africa island city hub outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"san-francisco",
		"las-vegas",
		"calgary",
		"manaus",
		"sao-paulo",
		"mendoza",
		"salta",
		"cayo-guillermo",
		"sharm-el-sheikh",
		"nairobi",
		"arusha",
		"dar-es-salaam",
		"morogoro",
		"tangier",
		"marrakech",
		"darwin",
		"melbourne",
		"sunshine-coast",
		"tekapo",
		"tauranga",
		"dublin",
		"reykjavik",
		"valletta",
		"limassol",
		"victoria",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("americas africa island city hub outdoor routes up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Lands End Trail",
		"Calico Tanks Trail",
		"Nose Hill Prairie Loop",
		"MUSA Forest Tower Trail",
		"Cantareira Pedra Grande Trail",
		"Cerro Arco Summit Trail",
		"Salta Hill Stairs Trail",
		"Cayo Guillermo Dune Coastal Walk",
		"Ras Mohammed Mangrove Boardwalk",
		"Karura Waterfall Loop",
		"Ngurdoto Crater View Trail",
		"Pugu Hills Forest Trail",
		"Uluguru Bondwa Peak Trail",
		"Tangier Atlantic Woodland Coastal Walk",
		"Marrakech Stone Desert Ridge Walk",
		"East Point Mangrove Boardwalk",
		"1000 Steps Kokoda Track Memorial Walk",
		"Mount Coolum Summit Track",
		"Mount John Summit Track",
		"Papamoa Hills Track",
		"Ticknock Fairy Castle Loop",
		"Mount Esja Trail",
		"Victoria Lines Trail",
		"Cape Aspro Coastal Trail",
		"Trois Freres Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("americas africa island city hub outdoor routes up migration must include uncovered hub route %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Golden Gate Bridge",
		"Golden Gate Park",
		"Red Rock Canyon National Conservation Area",
		"Princes Island Park",
		"MUSA Manaus",
		"Meeting of Waters Manaus",
		"Ibirapuera Park",
		"MASP Brazil",
		"Mendoza Wine Route",
		"General San Martin Park",
		"Cerro San Bernardo",
		"Playa Pilar",
		"Pilar Dunes",
		"Ras Mohammed National Park",
		"Colored Canyon Trail",
		"Karura Forest",
		"Ngong Hills",
		"Arusha National Park",
		"Mount Meru Momella Gate Day Hike",
		"Mbudya Island",
		"Bongoyo Island Marine Reserve",
		"Uluguru Mountains",
		"Udzungwa Mwanihana Trail",
		"Cap Spartel",
		"Hercules Caves",
		"Perdicaris Park",
		"Agafay Desert",
		"Setti Fatma Waterfalls Trail",
		"Toubkal Refuge Trail",
		"Mindil Beach Sunset Market",
		"Darwin Waterfront Wave Lagoon",
		"Royal Botanic Gardens Melbourne",
		"St Kilda Beach",
		"Noosa National Park",
		"Noosa Headland Coastal Walk",
		"Lake Tekapo",
		"Sealy Tarns Track",
		"Tauranga Waterfront",
		"Mauao Summit Track",
		"Howth Cliff Loop Walk",
		"Derrybawn Woodland Trail",
		"Snaefellsnes Coastal Lava Walk",
		"Arnarstapi to Hellnar Coastal Walk",
		"Malta Western Clifftop Walk",
		"Dingli Cliffs",
		"Cape Greco",
		"Troodos Cedar Ridge Trail",
		"Atalanti Trail",
		"Morne Blanc Trail",
		"Copolia Trail",
		"Mare aux Cochons Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("americas africa island city hub outdoor routes up migration must avoid duplicating broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("americas africa island city hub outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("americas africa island city hub outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("americas africa island city hub outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "americas-africa-island-city-hub-outdoor-routes-v1") {
		t.Fatalf("americas africa island city hub outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestAmericasAfricaHikingRoutesSeedMigrationAddsRouteLevelCoverage(t *testing.T) {
	upSQL := readMigration(t, "094_seed_americas_africa_hiking_routes.up.sql")
	downSQL := readMigration(t, "094_seed_americas_africa_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_americas_africa_hiking_resolved_places AS",
		"americas-africa-hiking-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("americas africa hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"yosemite",
		"grand-canyon",
		"rocky-mountain",
		"zion",
		"seattle",
		"banff",
		"jasper",
		"whistler",
		"mexico-city",
		"puebla",
		"oaxaca",
		"rio-de-janeiro",
		"florianopolis",
		"chapada-dos-veadeiros",
		"el-chalten",
		"bariloche",
		"ushuaia",
		"trinidad",
		"dahab",
		"imlil",
		"ouarzazate",
		"chefchaouen",
		"aberdares",
		"udzungwa",
		"mount-meru",
		"mahe",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("americas africa hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Mist Trail to Vernal and Nevada Falls",
		"Bright Angel Trail Day Hike",
		"Sky Pond Trail",
		"Observation Point Trail via East Mesa",
		"Rattlesnake Ledge Trail",
		"Plain of Six Glaciers Trail",
		"Johnston Canyon to Ink Pots Trail",
		"Valley of the Five Lakes Trail",
		"Garibaldi Lake Trail",
		"Nevado de Toluca Crater Lakes Trail",
		"Iztaccihuatl Paso de Cortes Trail",
		"Sierra Norte Pueblos Mancomunados Trail",
		"Pedra Bonita Trail",
		"Dois Irmaos Trail",
		"Lagoinha do Leste Trail",
		"Mirante da Janela Trail",
		"Laguna Torre Trail",
		"Cerro Llao Llao Trail",
		"Laguna Esmeralda Trail",
		"Guanayara Trail",
		"Colored Canyon Trail",
		"Toubkal Refuge Trail",
		"Jebel Saghro Bab n'Ali Trail",
		"Talassemtane Forest Trail",
		"Elephant Hill Trail",
		"Udzungwa Mwanihana Trail",
		"Mount Meru Momella Gate Day Hike",
		"Mare aux Cochons Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("americas africa hiking up migration must include route-level hiking place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Yosemite National Park",
		"Yosemite Valley",
		"Grand Canyon South Rim",
		"Rocky Mountain National Park",
		"Emerald Lake Trail",
		"Zion National Park",
		"The Narrows Zion",
		"Angels Landing",
		"Lake Louise",
		"Maligne Lake",
		"Whistler Blackcomb",
		"Hierve el Agua",
		"Sumidero Canyon",
		"Tijuca National Park",
		"Sugarloaf Mountain",
		"Laguna de los Tres",
		"Cerro Campanario",
		"Topes de Collantes",
		"Gabal El Medawara Trail",
		"Gebel Dakrur Trail",
		"Akchour Waterfalls",
		"Paradise Valley",
		"Sanje Waterfall",
		"Materuni Waterfalls and Coffee Tour",
		"Morne Blanc Trail",
		"Anse Major Trail",
		"Copolia Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("americas africa hiking up migration must avoid duplicating existing broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("americas africa hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("americas africa hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(downSQL, "americas-africa-hiking-v1") {
		t.Fatalf("americas africa hiking down migration must remove only tagged route-level places")
	}
}

func TestAmericasAfricaGapHikingRoutesSeedMigrationAddsMissingRouteCoverage(t *testing.T) {
	upSQL := readMigration(t, "108_seed_americas_africa_gap_hiking_routes.up.sql")
	downSQL := readMigration(t, "108_seed_americas_africa_gap_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_americas_africa_gap_hiking_resolved_places AS",
		"americas-africa-gap-hiking-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("americas africa gap hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"yellowstone",
		"denali",
		"anchorage",
		"maui",
		"honolulu",
		"vancouver",
		"victoria",
		"st-johns",
		"whitehorse",
		"monterrey",
		"puerto-vallarta",
		"tulum",
		"foz-do-iguacu",
		"lencois-maranhenses",
		"bonito",
		"cuiaba",
		"el-calafate",
		"aconcagua",
		"purmamarca",
		"vinales",
		"baracoa",
		"saint-catherine",
		"fayoum",
		"ourika",
		"mount-kenya",
		"hells-gate",
		"kilimanjaro",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("americas africa gap hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Fairy Falls and Grand Prismatic Overlook Trail",
		"Horseshoe Lake Trail",
		"Powerline Pass Trail",
		"Sliding Sands Trail",
		"Makapuu Point Lighthouse Trail",
		"Quarry Rock Trail",
		"Mount Finlayson Trail",
		"North Head Trail",
		"Grey Mountain Ridge Trail",
		"Cerro de la Silla Trail",
		"Boca de Tomatlan to Las Animas Trail",
		"Muyil Sian Ka'an Boardwalk Trail",
		"Macuco Trail Iguazu",
		"Lagoa Bonita Dune Trail",
		"Boca da Onca Waterfall Trail",
		"Veu de Noiva Waterfall Trail",
		"Glacier Balcony Boardwalk Trail",
		"Laguna de Horcones Trail",
		"Purmamarca Colorados Loop",
		"Los Aquaticos Trail",
		"El Yunque Summit Trail",
		"Sinai Sunrise Steps Trail",
		"Magic Lake Dune Walk",
		"Setti Fatma Waterfalls Trail",
		"Naro Moru River Trail",
		"Hell's Gate Gorge Walk",
		"Marangu Mandara Hut Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("americas africa gap hiking up migration must include route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Yellowstone National Park",
		"Grand Prismatic Spring",
		"Denali National Park",
		"Chugach State Park",
		"Flattop Mountain and Glen Alps",
		"Haleakala National Park",
		"Diamond Head State Monument",
		"Stanley Park",
		"Signal Hill",
		"Miles Canyon",
		"Chipinque Park",
		"Sian Kaan Biosphere Reserve",
		"Iguazu Falls",
		"Lencois Maranhenses National Park",
		"Chapada dos Guimaraes",
		"Perito Moreno Glacier",
		"'Aconcagua Provincial Park'",
		"Paseo de los Colorados",
		"Vinales Valley",
		"Mount Sinai",
		"Wadi El Rayan",
		"Ourika Valley",
		"Mount Kenya National Park",
		"Hell''s Gate National Park",
		"Mount Kilimanjaro",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("americas africa gap hiking up migration must avoid duplicating existing broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("americas africa gap hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("americas africa gap hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("americas africa gap hiking up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "americas-africa-gap-hiking-v1") {
		t.Fatalf("americas africa gap hiking down migration must remove only tagged route-level places")
	}
}

func TestOceaniaRemainingAsiaHikingRoutesSeedMigrationAddsRouteLevelCoverage(t *testing.T) {
	upSQL := readMigration(t, "095_seed_oceania_asia_hiking_routes.up.sql")
	downSQL := readMigration(t, "095_seed_oceania_asia_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_oceania_asia_hiking_resolved_places AS",
		"oceania-asia-hiking-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("oceania asia hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"blue-mountains",
		"sydney",
		"canberra",
		"hobart",
		"noosa",
		"auckland",
		"mount-maunganui",
		"queenstown",
		"fiordland",
		"wellington",
		"hanoi",
		"da-lat",
		"hue",
		"chiang-mai",
		"krabi",
		"cebu-city",
		"sagada",
		"kintamani",
		"munduk",
		"penang",
		"kota-kinabalu",
		"singapore",
		"kandy",
		"kyoto",
		"sokcho",
		"yangshuo",
		"manali",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("oceania asia hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Grand Canyon Track",
		"Bondi to Coogee Coastal Walk",
		"Mount Ainslie Summit Trail",
		"kunanyi Organ Pipes Track",
		"Noosa Headland Coastal Walk",
		"Rangitoto Summit Track",
		"Mauao Summit Track",
		"Ben Lomond Track",
		"Key Summit Track",
		"Mount Victoria Lookout Walk",
		"Ba Vi Summit Trail",
		"Lang Biang Peak Trail",
		"Bach Ma Hai Vong Dai Trail",
		"Monk's Trail to Wat Pha Lat",
		"Railay Viewpoint and Lagoon Trail",
		"Osmena Peak Trail",
		"Marlboro Hills Blue Soil Trail",
		"Mount Abang Trail",
		"Tamblingan Forest Loop Trail",
		"Penang Hill Heritage Trail",
		"Sosodikon Hill Trail",
		"Southern Ridges Walk",
		"MacRitchie TreeTop Walk Loop",
		"Riverston Pitawala Pathana Trail",
		"Fushimi Inari Summit Trail",
		"Seoraksan Ulsanbawi Rock Trail",
		"Yulong River Karst Walking Trail",
		"Bhrigu Lake Trek",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("oceania asia hiking up migration must include route-level hiking place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Bondi Beach",
		"Noosa National Park",
		"Mount Maunganui Beach",
		"Fiordland National Park",
		"Kew Mae Pan Nature Trail",
		"Dragon Crest Mountain Trail",
		"Mount Batur",
		"Lake Tamblingan",
		"Kinabalu Park",
		"MacRitchie Reservoir Park",
		"Knuckles Mini World's End Trail",
		"Fushimi Inari Taisha",
		"Seoraksan National Park",
		"Yulong River Scenic Area",
		"Cat Cat Village",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("oceania asia hiking up migration must avoid duplicating existing broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("oceania asia hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("oceania asia hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(downSQL, "oceania-asia-hiking-v1") {
		t.Fatalf("oceania asia hiking down migration must remove only tagged route-level places")
	}
}

func TestAsiaOceaniaGapHikingRoutesSeedMigrationAddsRemainingRouteCoverage(t *testing.T) {
	upSQL := readMigration(t, "110_seed_asia_oceania_gap_hiking_routes.up.sql")
	downSQL := readMigration(t, "110_seed_asia_oceania_gap_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_asia_oceania_gap_hiking_resolved_places AS",
		"asia-oceania-gap-hiking-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("asia oceania gap hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"sa-pa",
		"ninh-binh",
		"phuket",
		"koh-tao",
		"banaue",
		"coron",
		"bohol",
		"nusa-penida",
		"sidemen",
		"jatiluwih",
		"fuvahmulah",
		"hulhumale",
		"hangzhou",
		"zhangjiajie",
		"kamakura",
		"nikko",
		"busan",
		"kuala-lumpur",
		"ella",
		"rishikesh",
		"leh",
		"kakadu",
		"aoraki-mount-cook",
		"cameron-highlands",
		"langkawi",
		"great-ocean-road",
		"cairns",
		"al-ain",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("asia oceania gap hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Y Linh Ho to Lao Chai Valley Trail",
		"Cuc Phuong Ancient Tree Trail",
		"Black Rock Viewpoint Trail",
		"John-Suwan Viewpoint Trail",
		"Batad Rice Terraces Trail",
		"Tapyas Sunset Stair Trail",
		"Bohol Karst Hills View Trail",
		"Kelingking Cliff View Trail",
		"Sidemen Rice Terrace Walk",
		"Jatiluwih Subak Terrace Loop",
		"Fuvahmulah Lake-to-Beach Nature Walk",
		"Hulhumale Eastern Beach Coastal Walk",
		"Nine Creeks and Longjing Trail",
		"Golden Whip Stream Trail",
		"Daibutsu Hiking Trail",
		"Senjogahara Marshland Trail",
		"Igidae Coastal Walk",
		"Bukit Gasing Forest Trail",
		"Ella Mini Adams Ridge Walk",
		"Neer Garh Waterfall Trail",
		"Sham Valley Day Trek",
		"Ubirr Rock Art Walk",
		"Sealy Tarns Track",
		"Cameron Highlands Boardwalk Trail",
		"Gunung Raya Summit Trail",
		"Wreck Beach Steps Walk",
		"Red Arrow Circuit",
		"Jebel Hafit Foothill Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("asia oceania gap hiking up migration must include gap route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Muong Hoa Valley",
		"Cat Cat Village",
		"Cuc Phuong National Park",
		"Ma Pi Leng Pass Trail",
		"Ko Nang Yuan",
		"Chocolate Hills",
		"Mount Tapyas",
		"Kelingking Beach",
		"Sidemen Rice Terraces",
		"Jatiluwih Rice Terraces",
		"Thoondu Beach",
		"Fuvahmulah Tiger Shark Point",
		"Hulhumale Beach",
		"West Lake",
		"Zhangjiajie National Forest Park",
		"Nikko Toshogu Shrine",
		"Haeundae Beach",
		"Little Adam's Peak",
		"Laxman Jhula",
		"Leh Palace",
		"Kakadu Ubirr",
		"Hooker Valley Track",
		"Mossy Forest Eco Park",
		"Langkawi Sky Bridge",
		"Tongariro Alpine Crossing",
		"Caledonia Waterfall Trail",
		"Jebel Hafit Desert Park",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("asia oceania gap hiking up migration must avoid duplicating existing broad or route place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("asia oceania gap hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("asia oceania gap hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("asia oceania gap hiking up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "asia-oceania-gap-hiking-v1") {
		t.Fatalf("asia oceania gap hiking down migration must remove only tagged route-level places")
	}
}

func TestEuropeCaucasusMiddleEastGapHikingRoutesSeedMigrationAddsRemainingRouteCoverage(t *testing.T) {
	upSQL := readMigration(t, "111_seed_europe_caucasus_middle_east_gap_hiking_routes.up.sql")
	downSQL := readMigration(t, "111_seed_europe_caucasus_middle_east_gap_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_europe_caucasus_middle_east_gap_hiking_resolved_places AS",
		"europe-caucasus-middle-east-gap-hiking-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("europe caucasus middle east gap hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"gudauri",
		"mestia",
		"dilijan",
		"jermuk",
		"quba",
		"hatta",
		"ras-al-khaimah",
		"fujairah",
		"rize",
		"cappadocia",
		"kemer",
		"troodos",
		"litochoro",
		"interlaken",
		"grossglockner",
		"chamonix",
		"lake-district",
		"amalfi-coast",
		"calpe",
		"madeira",
		"glendalough",
		"snaefellsnes",
		"zakopane",
		"durmitor",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("europe caucasus middle east gap hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Truso Valley Trail",
		"Mestia to Zhabeshi Trail",
		"Jukhtak Monastery Forest Trail",
		"Jermuk to Gndevank Canyon Trail",
		"Afurja Waterfall Trail",
		"Hatta Sign Hill Trail",
		"Wadi Shah Stairway to Heaven Trail",
		"Wadi Abadilah Trail",
		"Avusor Plateau Trail",
		"Love Valley to Uchisar Trail",
		"Olympos to Cirali Lycian Way Walk",
		"Atalanti Trail",
		"Gortsia to Petrostrouga Trail",
		"Hardergrat Trail",
		"Gamsgrubenweg Panorama Trail",
		"Grand Balcon Nord Trail",
		"Helvellyn Striding Edge Walk",
		"Punta Campanella Trail",
		"Sierra de Bernia Circular Trail",
		"Levada do Caldeirao Verde Trail",
		"Derrybawn Woodland Trail",
		"Arnarstapi to Hellnar Coastal Walk",
		"Dolina Pieciu Stawow Trail",
		"Bobotov Kuk Summit Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("europe caucasus middle east gap hiking up migration must include gap route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Juta to Chaukhi Lake Trail",
		"Gudauri Ski Resort",
		"Mestia Glacier Valley Trail",
		"Chalaadi Glacier",
		"Koruldi Lakes",
		"Parz Lake to Gosh Lake Trail",
		"Mount Dimats Trail",
		"Lake Parz",
		"Arpa Canyon Resort Trail",
		"Jermuk Waterfall",
		"Gndevank Monastery",
		"Tengealti Canyon Trail",
		"Red Settlement Quba",
		"Hatta Mountain Trails",
		"Hatta Wadi Hub",
		"Jebel Jais Hiking Trails",
		"Wadi Wurayah Trail",
		"Kackar Pokut Plateau Trail",
		"Ayder Plateau",
		"Red Valley Loop Trail",
		"Lycian Way near Goynuk Canyon",
		"Phaselis Ancient City",
		"Troodos Cedar Ridge Trail",
		"Artemis Trail",
		"Prionia Forest Ascent Trail",
		"Enipeas Gorge",
		"Eiger Trail",
		"Harder Kulm",
		"Pasterze Glacier View Trail",
		"Grossglockner High Alpine Road",
		"Lac Blanc Trail",
		"Aiguille du Midi",
		"Catbells Ridge Walk",
		"Lake District National Park",
		"Path of the Gods Trail",
		"Valle delle Ferriere",
		"Penon de Ifach Trail",
		"Pico Ruivo Trail",
		"Pico do Arieiro",
		"Spinc and Glenealo Valley Trail",
		"Snaefellsnes Coastal Lava Walk",
		"Snaefellsjokull National Park",
		"Tatra Lake Approach Trail",
		"Morskie Oko",
		"Durmitor Lake Forest Loop",
		"Durmitor National Park",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("europe caucasus middle east gap hiking up migration must avoid duplicating existing broad or route place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("europe caucasus middle east gap hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("europe caucasus middle east gap hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("europe caucasus middle east gap hiking up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "europe-caucasus-middle-east-gap-hiking-v1") {
		t.Fatalf("europe caucasus middle east gap hiking down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanMoreHikingRoutesSeedMigrationAddsRouteLevelCoverage(t *testing.T) {
	upSQL := readMigration(t, "096_seed_kazakhstan_more_hiking_routes.up.sql")
	downSQL := readMigration(t, "096_seed_kazakhstan_more_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_more_hiking_resolved_places AS",
		"kazakhstan-more-hiking-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan more hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"ust-kamenogorsk",
		"pavlodar",
		"karaganda",
		"balkhash",
		"kokshetau",
		"aktau",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan more hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Mokhnatka Mountain Trail",
		"Titov Lake Trail",
		"Kamenskoye Plateau Trail",
		"Kok-Zhailau Waterfall Trail",
		"Medeu Terrenkur Health Trail",
		"Manshuk Mametova Lake Trail",
		"Esik Waterfall Trail",
		"Oi-Qaragai Forest Ridge Trail",
		"Lineyskie Belki Trail",
		"Poperechnoye Lake Trail",
		"Zhasybai Lake Shore Trail",
		"Toraigyr Lake View Trail",
		"Abylai Khan Meadow Trail",
		"Kyzyltas Ridge Trail",
		"Karynzharyk Depression View Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan more hiking up migration must include route-level hiking place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Gorelnik Waterfalls",
		"Furmanov Peak",
		"Aksai Skete",
		"Kara-Kungey Ridge",
		"Kok-Zhailau Plateau",
		"Butakovka Gorge",
		"Kimasar Gorge",
		"Kumbel Peak",
		"Turgen Gorge",
		"Bear Falls in Turgen Gorge",
		"Issyk Lake Trail",
		"Tuyuksu Glacier Trail",
		"Big Almaty Peak Trail",
		"Mynzhylky Plateau Trail",
		"Bogdanovich Glacier View Trail",
		"Akbet Peak",
		"Konyr-Aulie Cave",
		"West Altai Nature Reserve Trails",
		"Karkaraly National Park",
		"Bektau-Ata",
		"Sherkala Mountain",
		"Torysh Valley",
		"Tuzbair Salt Flat",
		"Airakty-Shomanai Valley",
		"Bokty Mountain View Trail",
		"Boszhira Fang View Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan more hiking up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan more hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan more hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan more hiking up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-more-hiking-v1") {
		t.Fatalf("kazakhstan more hiking down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanHighlandNatureWalksSeedMigrationAddsExtraRouteDepth(t *testing.T) {
	upSQL := readMigration(t, "098_seed_kazakhstan_highland_nature_walks.up.sql")
	downSQL := readMigration(t, "098_seed_kazakhstan_highland_nature_walks.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_highland_nature_walks_resolved_places AS",
		"kazakhstan-highland-nature-walks-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan highland nature walks up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"shymkent",
		"taraz",
		"astana",
		"kokshetau",
		"aktau",
		"atyrau",
		"balkhash",
		"zhezkazgan",
		"kostanay",
		"semey",
		"oral",
		"turkestan",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan highland nature walks up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Bukreev Peak Trail",
		"Japanese Road Trail",
		"Kim-Asar Waterfall Trail",
		"Batan Meadows Trail",
		"Sazanata Gorge Trail",
		"Merke Gorge Trail",
		"Korgalzhyn Reedbed Birding Trail",
		"Zheke-Batyr Mountain Trail",
		"Kyzylkup Rainbow Hills Trail",
		"Sultan-Epe Valley Walk",
		"Akkegershin Chalk Canyon Trail",
		"Aulie Cave Granite Trail",
		"Terekty Aulie Petroglyph Trail",
		"Ubagan River Valley Walk",
		"Semey Irtysh Island Trail",
		"Kushum River Floodplain Walk",
		"Arpa-Uzen Petroglyph Ridge Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan highland nature walks up migration must include extra route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Burgulyuk Gorge",
		"Kaskasu Gorge",
		"Mashat Gorge Trail",
		"Tamshaly Canyon",
		"Bektau-Ata",
		"Konyr-Aulie Cave",
		"Saryarka Steppe and Lakes",
		"Ulytau Reserve-Museum",
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Furmanov Peak",
		"Kara-Kungey Ridge",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan highland nature walks up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan highland nature walks up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan highland nature walks up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan highland nature walks up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-highland-nature-walks-v1") {
		t.Fatalf("kazakhstan highland nature walks down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanExtraOutdoorRoutesSeedMigrationAddsMoreRouteDepth(t *testing.T) {
	upSQL := readMigration(t, "100_seed_kazakhstan_extra_outdoor_routes.up.sql")
	downSQL := readMigration(t, "100_seed_kazakhstan_extra_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_extra_outdoor_routes_resolved_places AS",
		"kazakhstan-extra-outdoor-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan extra outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
		"ust-kamenogorsk",
		"pavlodar",
		"karaganda",
		"kokshetau",
		"astana",
		"aktau",
		"atyrau",
		"kyzylorda",
		"aktobe",
		"taraz",
		"shymkent",
		"zhezkazgan",
		"balkhash",
		"oral",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan extra outdoor routes up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Abai Peak Classic Trail",
		"Three Brothers Rocks Trail",
		"Charyn Moon Canyon Trail",
		"Aigaikum Singing Dune Walk",
		"Basshi Steppe Eco Trail",
		"Lepsy River Valley Trail",
		"Austrian Road Katon-Karagay Trail",
		"Belukha Base View Trail",
		"Berel Valley Heritage Walk",
		"Kempirtas Rock Trail",
		"Auliebulak Spring Trail",
		"Bugyly Mountains Trail",
		"Karkaraly Three Caves Trail",
		"Pashennoye Lake Forest Trail",
		"Burabay Green Cape Trail",
		"Ereymentau Granite Ridge Trail",
		"Shakpak-Ata Canyon Walk",
		"Kokala Clay Hills Trail",
		"Beket-Ata Plateau Walk",
		"Akzhaiyk Reserve Boardwalk Trail",
		"Barsa-Kelmes Desert Edge Trail",
		"Mugodzhary Hills Trail",
		"Koksay Gorge Trail",
		"Baldybrek Canyon Trail",
		"Ulytau Aulietau Summit Trail",
		"Balkhash Reed Islands Walk",
		"Shalkar Lake Shore Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan extra outdoor routes up migration must include route-level hiking place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Gorelnik Waterfalls",
		"Furmanov Peak",
		"Aksai Skete",
		"Kara-Kungey Ridge",
		"Kok-Zhailau Plateau",
		"Butakovka Gorge",
		"Monakhov Gorge",
		"Torysh Valley",
		"Sherkala Mountain",
		"Bektau-Ata",
		"Korgalzhyn Reedbed Birding Trail",
		"Ulytau Akmeshit Ridge Trail",
		"Bukreev Peak Trail",
		"Japanese Road Trail",
		"Kim-Asar Waterfall Trail",
		"Batan Meadows Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan extra outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan extra outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan extra outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan extra outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-extra-outdoor-routes-v1") {
		t.Fatalf("kazakhstan extra outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanMoreOutdoorDepthSeedMigrationAddsAdditionalRouteChoices(t *testing.T) {
	upSQL := readMigration(t, "102_seed_kazakhstan_more_outdoor_depth.up.sql")
	downSQL := readMigration(t, "102_seed_kazakhstan_more_outdoor_depth.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_more_outdoor_depth_resolved_places AS",
		"kazakhstan-more-outdoor-depth-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan more outdoor depth up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"ust-kamenogorsk",
		"pavlodar",
		"kokshetau",
		"aktau",
		"balkhash",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan more outdoor depth up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Alpengrad High Camp Trail",
		"Mayakovsky Peak View Trail",
		"Tourist Peak Approach Trail",
		"Ozerny Peak Moraine Trail",
		"Shukur Gorge Hut Trail",
		"Kimasar Pass Ridge Trail",
		"Prohodnaya River Waterfall Trail",
		"Karash Ridge Turgen Trail",
		"Besqaynar Forest Trail",
		"Tamgaly-Tas Climber Path",
		"Maral Lake Altai Trail",
		"Kokkol Mine Heritage Trail",
		"Sarymsakty Ridge Trail",
		"Zhasybai to Toraigyr Traverse",
		"Naizatas Rock Trail",
		"Borovushka Forest Loop",
		"Senek Dune Field Walk",
		"Tuyesu Sands Trail",
		"Bozjira Western Escarpment Walk",
		"Granite Labyrinth Loop near Bektauata",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan more outdoor depth up migration must include additional route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Gorelnik Waterfalls",
		"Furmanov Peak",
		"Aksai Skete",
		"Kara-Kungey Ridge",
		"Kok-Zhailau Plateau",
		"Big Almaty Peak Trail",
		"Mynzhylky Plateau Trail",
		"Tuyuksu Glacier Trail",
		"Prohodnoye Gorge Trail",
		"Left Talgar Gorge Trail",
		"Talgar Peak Base Trail",
		"Tamgaly-Tas Rocks",
		"Bektau-Ata",
		"Zhasybai Lake Shore Trail",
		"Toraigyr Lake View Trail",
		"Bozzhyra Valley",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan more outdoor depth up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan more outdoor depth up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan more outdoor depth up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan more outdoor depth up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-more-outdoor-depth-v1") {
		t.Fatalf("kazakhstan more outdoor depth down migration must remove only tagged route-level places")
	}
}

func TestKazakhstanHiddenOutdoorRoutesSeedMigrationAddsMoreLocalChoices(t *testing.T) {
	upSQL := readMigration(t, "104_seed_kazakhstan_hidden_outdoor_routes.up.sql")
	downSQL := readMigration(t, "104_seed_kazakhstan_hidden_outdoor_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kazakhstan_hidden_outdoor_routes_resolved_places AS",
		"kazakhstan-hidden-outdoor-routes-v1",
		"'KZ'",
		"'KZT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kazakhstan hidden outdoor routes up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"almaty",
		"taldykorgan",
		"ust-kamenogorsk",
		"semey",
		"karaganda",
		"astana",
		"zhezkazgan",
		"kostanay",
		"aktau",
		"atyrau",
		"aktobe",
		"oral",
		"shymkent",
		"turkestan",
		"taraz",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kazakhstan hidden outdoor routes up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Cosmostation Ridge Walk",
		"Molodezhny Peak Approach Trail",
		"Karlytau Glacier View Trail",
		"Shymbulak Talgar Pass View Walk",
		"Turgen Wild Apple Ridge Trail",
		"Kaskelen Upper Meadows Trail",
		"Upper Kora Cascades Trail",
		"Zhetysu Dzungarian Fir Belt Trail",
		"Ridder Stone Bowl Forest Trail",
		"West Altai Cedar Loop",
		"Sibins Hidden Lake Loop",
		"Kiin-Kerish Mars Valley Walk",
		"Shaitankol Ridge Walk",
		"Kyzylarai Cedar Valley Walk",
		"Buiratau Stone Ridge Walk",
		"Ulytau Edige Peak Trail",
		"Naurzum Pine Lake Birding Trail",
		"Zhygylgan Rim Walk",
		"Tuzbair Sunrise Cliffs Trail",
		"Torysh Stone Field Walk",
		"Inder Salt Dome View Walk",
		"Kargaly Reservoir Ridge Walk",
		"Chagan Riverbank Forest Walk",
		"Tulkibas Juniper Foothill Trail",
		"Kazygurt Mountain Pilgrim Trail",
		"Karatau Arystanbab Steppe Ridge Walk",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kazakhstan hidden outdoor routes up migration must include local outdoor route %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Alma-Arasan Gorge",
		"Gorelnik Gorge",
		"Gorelnik Waterfalls",
		"Furmanov Peak",
		"Aksai Skete",
		"Kara-Kungey Ridge",
		"Kok-Zhailau Plateau",
		"Butakovka Gorge",
		"Kimasar Gorge",
		"Kumbel Peak",
		"Turgen Gorge",
		"Kaskelen Gorge",
		"Burkhan-Bulak Waterfall",
		"Dzungarian Alatau National Park",
		"Yazevoe Lake Trail",
		"Ivanov Ridge Trail",
		"Markakol Shore Trail",
		"West Altai Nature Reserve Trails",
		"Sibiny Lakes",
		"Karkaraly National Park",
		"Kent Mountains Trail",
		"Aksoran Peak Trail",
		"Buiratau National Park",
		"Ulytau Akmeshit Ridge Trail",
		"Ulytau Aulietau Summit Trail",
		"Naurzum Nature Reserve",
		"Zhygylgan Fault",
		"Tuzbair Salt Flat",
		"Torysh Valley",
		"Inder Salt Lake Trail",
		"Koksay Gorge Trail",
		"Sairam Peak Base Trail",
		"Kaskasu Gorge",
		"Karatau Foothill Trail",
		"Merke Gorge Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kazakhstan hidden outdoor routes up migration must avoid duplicating existing place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kazakhstan hidden outdoor routes up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kazakhstan hidden outdoor routes up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kazakhstan hidden outdoor routes up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kazakhstan-hidden-outdoor-routes-v1") {
		t.Fatalf("kazakhstan hidden outdoor routes down migration must remove only tagged route-level places")
	}
}

func TestTajikistanGapHikingRoutesSeedMigrationAddsRouteCoverage(t *testing.T) {
	upSQL := readMigration(t, "101_seed_tajikistan_gap_hiking_routes.up.sql")
	downSQL := readMigration(t, "101_seed_tajikistan_gap_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_tajikistan_gap_hiking_resolved_places AS",
		"tajikistan-gap-hiking-v1",
		"'TJ'",
		"'TJS'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("tajikistan gap hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"khujand",
		"hisor",
		"safed-dara",
		"norak",
		"guliston-qayraqqum",
		"istaravshan",
		"panjakent",
		"sarazm",
		"panjrud",
		"seven-lakes",
		"fann-mountains",
		"kulikalon",
		"alauddin",
		"iskanderkul",
		"garm-chashma",
		"jelondy",
		"yamchun",
		"vrang",
		"langar",
		"bulunkul",
		"karakul",
		"bokhtar",
		"vakhsh",
		"vose-hulbuk",
		"sari-khosor",
		"dusti",
		"shahrituz",
		"nosiri-khusrav",
		"qubodiyon",
		"muminobod",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("tajikistan gap hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Mogol-Tau Foothill Trail",
		"Hisor Range Foothill Trail",
		"Safed-Dara Ridge Trail",
		"Nurek Ridge View Trail",
		"Qayraqqum North Shore Trail",
		"Mug Teppa Ridge Walk",
		"Panjakent Zeravshan Bend Walk",
		"Zeravshan River Terrace Trail",
		"Panjrud Valley Rudaki Trail",
		"Haft Kul Lake-to-Lake Trail",
		"Artuch Basin Trail",
		"Chukurak Pass View Trail",
		"Alauddin to Mutnye Lakes Trail",
		"Snake Lake and Waterfall Trail",
		"Garm Chashma Ridge View Trail",
		"Jelondy Valley Walk",
		"Yamchun to Bibi Fatima Trail",
		"Vrang Wakhan Terrace Trail",
		"Langar Ridge Petroglyph Trail",
		"Bulunkul-Yashilkul Shore Trail",
		"Karakul Shore Ridge Trail",
		"Bokhtar Tugai Nature Walk",
		"Vakhsh River Floodplain Trail",
		"Khoja Mumin Salt Mountain Trail",
		"Sari Khosor Upper Gorge Trail",
		"Tigrovaya Balka Southern Tugai Trail",
		"Kyzylsu Tugai Trail",
		"Chiluchor Chashma Ridge Walk",
		"Takhti Sangin Oxus Riverbank Trail",
		"Childukhtaron Ridge Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("tajikistan gap hiking up migration must include route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Hisor Fortress",
		"Safed-Dara Ski Resort",
		"Nurek Reservoir",
		"Kayrakkum Reservoir Tajik Sea",
		"Mug Teppa Fortress",
		"Ancient Panjakent",
		"Proto-urban Site of Sarazm",
		"Rudaki Mausoleum",
		"Seven Lakes Haft Kul",
		"Fann Mountains",
		"Kulikalon Lakes",
		"Alauddin Lakes",
		"Iskanderkul Lake",
		"Garm Chashma Hot Spring",
		"Jelondy Hot Springs",
		"Yamchun Fortress",
		"Bibi Fatima Hot Springs",
		"Vrang Buddhist Stupa",
		"Langar Petroglyphs",
		"Yashilkul and Bulunkul Lakes",
		"Lake Karakul",
		"Ajina-Teppa Buddhist Monastery",
		"Hulbuk Fortress",
		"Sari Khosor Waterfall",
		"Tigrovaya Balka Nature Reserve",
		"Khoja Mashhad Mausoleum and Madrasa",
		"Chiluchor Chashma Springs",
		"Takhti Sangin Oxus Temple",
		"Childukhtaron Mountain",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("tajikistan gap hiking up migration must avoid duplicating existing broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("tajikistan gap hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("tajikistan gap hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("tajikistan gap hiking up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "tajikistan-gap-hiking-v1") {
		t.Fatalf("tajikistan gap hiking down migration must remove only tagged route-level places")
	}
}

func TestMongoliaGapHikingRoutesSeedMigrationAddsRouteCoverage(t *testing.T) {
	upSQL := readMigration(t, "103_seed_mongolia_gap_hiking_routes.up.sql")
	downSQL := readMigration(t, "103_seed_mongolia_gap_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_mongolia_gap_hiking_resolved_places AS",
		"mongolia-gap-hiking-v1",
		"'MN'",
		"'MNT'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("mongolia gap hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"tsonjin-boldog",
		"zuunmod",
		"khustai",
		"kharkhorin",
		"orkhon-valley",
		"tuvkhun",
		"tsenkher",
		"amarbayasgalant",
		"dalanzadgad",
		"yolyn-am",
		"khongoryn-els",
		"bayanzag",
		"tsagaan-suvarga",
		"baga-gazriin-chuluu",
		"sainshand",
		"khamaryn-khiid",
		"khermen-tsav",
		"darkhan",
		"erdenet",
		"choibalsan",
		"khalkh-gol",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("mongolia gap hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Tuul River Steppe Trail",
		"Manzushir Forest Ridge Trail",
		"Khustai Takhi Steppe Trail",
		"Karakorum Riverbank Heritage Trail",
		"Orkhon Waterfall Rim Trail",
		"Tuvkhun Forest Ascent Trail",
		"Tsenkher River Valley Walk",
		"Amarbayasgalant Valley Ridge Trail",
		"Dalan Bulag Desert Steppe Trail",
		"Yolyn Am Ice Gorge Trail",
		"Singing Dune Ridge Climb",
		"Bayanzag Cliffs Rim Trail",
		"Tsagaan Suvarga Escarpment Trail",
		"Baga Gazriin Rock Labyrinth Trail",
		"Khamar Steppe Viewpoint Trail",
		"Shambhala Desert Energy Trail",
		"Khermen Tsav Rim Trail",
		"Darkhan Kharaa River Trail",
		"Bayan-Undur Hill Trail",
		"Kherlen Riverbank Steppe Trail",
		"Khalkh Gol Riverbank Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("mongolia gap hiking up migration must include route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Chinggis Khaan Statue Complex",
		"Manzushir Monastery",
		"Khustai National Park",
		"Orkhon Valley Cultural Landscape",
		"Erdene Zuu Monastery",
		"Ancient Karakorum Ruins",
		"Karakorum Museum",
		"Tuvkhun Monastery",
		"Orkhon Waterfall Ulaan Tsutgalan",
		"Tsenkher Hot Springs",
		"Amarbayasgalant Monastery",
		"Gobi Gurvansaikhan National Park",
		"Yolyn Am Gorge",
		"Khongoryn Els Sand Dunes",
		"Bayanzag Flaming Cliffs",
		"Tsagaan Suvarga White Stupa",
		"Baga Gazriin Chuluu",
		"Khamaryn Khiid Monastery",
		"Khermen Tsav Canyon",
		"Khalkh Gol Memorial Complex",
		"Bogd Khan Tsetsee Gun Trail",
		"Mongol Olle Terelj Route",
		"Khorgo Volcano Crater Trail",
		"Khuvsgul East Shore Trail",
		"Potanin Glacier Base Trail",
		"Onon-Balj Valley Trail",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("mongolia gap hiking up migration must avoid duplicating existing broad or route place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("mongolia gap hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("mongolia gap hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("mongolia gap hiking up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "mongolia-gap-hiking-v1") {
		t.Fatalf("mongolia gap hiking down migration must remove only tagged route-level places")
	}
}

func TestKyrgyzstanUzbekistanGapHikingRoutesSeedMigrationAddsRouteCoverage(t *testing.T) {
	upSQL := readMigration(t, "099_seed_kyrgyzstan_uzbekistan_gap_hiking_routes.up.sql")
	downSQL := readMigration(t, "099_seed_kyrgyzstan_uzbekistan_gap_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_kyrgyzstan_uzbekistan_gap_hiking_resolved_places AS",
		"kyrgyzstan-uzbekistan-gap-hiking-v1",
		"'KG'",
		"'UZ'",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("kyrgyzstan uzbekistan gap hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"ala-archa",
		"chunkurchak",
		"issyk-ata",
		"jeti-oguz",
		"barskoon",
		"skazka-canyon",
		"bokonbaevo",
		"tamga",
		"kaji-say",
		"song-kul",
		"tash-rabat",
		"kel-suu",
		"at-bashy",
		"jalal-abad",
		"arslanbob",
		"sary-chelek",
		"toktogul",
		"suusamyr",
		"bukhara",
		"khiva",
		"urgench",
		"nukus",
		"muynak",
		"margilan",
		"kokand",
		"rishtan",
		"andijan",
		"namangan",
		"charvak",
		"termez",
		"zaamin",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("kyrgyzstan uzbekistan gap hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Ak-Sai Waterfall Trail",
		"Chunkurchak Ridge Viewpoint Trail",
		"Issyk-Ata Waterfall Gorge Trail",
		"Telety Valley Day Hike",
		"Barskoon Upper Cascade Trail",
		"Skazka Canyon Ridge Loop",
		"Shatyly Panorama Trail",
		"Tamga Gorge Petroglyph Trail",
		"Kaji-Say Shoreline Ridge Walk",
		"Song-Kul Shore Pasture Loop",
		"Chatyr-Kul Pass View Trail",
		"Kel-Suu Canyon Shore Trail",
		"At-Bashy Ridge View Trail",
		"Kara-Alma Walnut Forest Trail",
		"Small Arslanbob Waterfall Loop",
		"Arkyt to Sary-Chelek Lake Trail",
		"Toktogul Shore Ridge Trail",
		"Too-Ashuu Ridge Walk",
		"Tudakul Lake Shore Birding Trail",
		"Toprak-Kala Desert Loop Trail",
		"Sudochye Lake Ustyurt Birding Trail",
		"Moynaq Aral Seabed Dune Walk",
		"Yazyavan Sands Eco Trail",
		"Kokand Foothill Steppe Trail",
		"Sokh River Foothill Trail",
		"Andijan Reservoir Shore Trail",
		"Papsay Gorge Foothill Trail",
		"Charvak Ridge View Trail",
		"Surkhan River Tugai Trail",
		"Supa Plateau Juniper Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("kyrgyzstan uzbekistan gap hiking up migration must include route-level place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Ala Archa National Park",
		"Chunkurchak Gorge",
		"Issyk-Ata Gorge",
		"Jeti-Oguz Rocks",
		"Barskoon Waterfalls",
		"Skazka Fairy Tale Canyon",
		"Song-Kul Lake",
		"Tash Rabat Caravanserai",
		"Kel-Suu Lake",
		"Arslanbob Walnut Forest",
		"Arslanbob Waterfalls",
		"Sary-Chelek Biosphere Reserve",
		"Toktogul Reservoir",
		"Suusamyr Valley",
		"Ark of Bukhara",
		"Itchan Kala",
		"Ayaz-Kala Fortress",
		"Moynaq Ship Cemetery",
		"Charvak Reservoir Beaches",
		"Zaamin National Park",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("kyrgyzstan uzbekistan gap hiking up migration must avoid duplicating existing broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("kyrgyzstan uzbekistan gap hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("kyrgyzstan uzbekistan gap hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(upSQL, "price_currency = EXCLUDED.price_currency") {
		t.Fatalf("kyrgyzstan uzbekistan gap hiking up migration must update places.price_currency on seed conflict")
	}
	if !strings.Contains(downSQL, "kyrgyzstan-uzbekistan-gap-hiking-v1") {
		t.Fatalf("kyrgyzstan uzbekistan gap hiking down migration must remove only tagged route-level places")
	}
}

func TestAsiaMiddleEastHikingRoutesSeedMigrationAddsRouteLevelCoverage(t *testing.T) {
	upSQL := readMigration(t, "091_seed_asia_middle_east_hiking_routes.up.sql")
	downSQL := readMigration(t, "091_seed_asia_middle_east_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_asia_middle_east_hiking_resolved_places AS",
		"asia-me-hiking-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("asia middle east hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"khor-fakkan",
		"fujairah",
		"fayoum",
		"siwa",
		"pune",
		"bengaluru",
		"munnar",
		"guangzhou",
		"shenzhen",
		"tokyo",
		"seoul",
		"krabi",
		"chiang-mai",
		"camiguin",
		"baguio",
		"selangor",
		"kandy",
		"rize",
		"byurakan",
		"khinalig",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("asia middle east hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Al Rabi Hiking Trail",
		"Wadi Wurayah Trail",
		"Gabal El Medawara Trail",
		"Gebel Dakrur Trail",
		"Sinhagad Fort Trek",
		"Nandi Hills Sunrise Trail",
		"Meesapulimala Day Trek",
		"Baiyun Mountain Trail",
		"Wutong Mountain Trail",
		"Mount Takao Trail",
		"Bukhansan Baegundae Trail",
		"Dragon Crest Mountain Trail",
		"Kew Mae Pan Nature Trail",
		"Mount Hibok-Hibok Trail",
		"Mount Ulap Trail",
		"Broga Hill Trail",
		"Knuckles Mini World's End Trail",
		"Kackar Pokut Plateau Trail",
		"Mount Aragats Kari Lake Trail",
		"Khinalig to Galakhudat Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("asia middle east hiking up migration must include route-level hiking place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Khor Fakkan Beach",
		"Wadi El Hitan",
		"Eravikulam National Park",
		"Doi Inthanon National Park",
		"Camiguin White Island",
		"Ayder Plateau",
		"Khinalig Village",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("asia middle east hiking up migration must avoid duplicating existing broad place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("asia middle east hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("asia middle east hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(downSQL, "asia-me-hiking-v1") {
		t.Fatalf("asia middle east hiking down migration must remove only tagged route-level places")
	}
}

func TestCentralAsiaMongoliaHikingRoutesSeedMigrationAddsRouteLevelCoverage(t *testing.T) {
	upSQL := readMigration(t, "089_seed_central_asia_mongolia_hiking_routes.up.sql")
	downSQL := readMigration(t, "089_seed_central_asia_mongolia_hiking_routes.down.sql")

	requiredFragments := []string{
		"INSERT INTO places",
		"INSERT INTO place_translations",
		"INSERT INTO place_media",
		"INSERT INTO place_city_links",
		"CREATE TEMP TABLE seed_central_asia_mongolia_hiking_resolved_places AS",
		"central-asia-mongolia-hiking-v1",
		"'hiking'",
		"'trekking'",
	}
	for _, fragment := range requiredFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("central asia mongolia hiking up migration must contain %q", fragment)
		}
	}

	for _, cityID := range []string{
		"kochkor",
		"naryn",
		"talas",
		"tokmok",
		"cholpon-ata",
		"uzgen",
		"samarkand",
		"navoi",
		"nurata",
		"fergana",
		"shahrisabz",
		"dushanbe",
		"murghab",
		"khorog",
		"baljuvon",
		"ulaanbaatar",
		"gorkhi-terelj",
		"khorgo-terkhiin-tsagaan-nuur",
		"khatgal",
		"ulgii",
		"binder",
	} {
		if !strings.Contains(upSQL, "'"+cityID+"'") {
			t.Fatalf("central asia mongolia hiking up migration must seed route linked to city_id %q", cityID)
		}
	}

	for _, title := range []string{
		"Kol-Ukok Lake Trek",
		"Eki-Naryn Valley Trail",
		"Besh-Tash Lake Trail",
		"Konorchek Canyon Trail",
		"Grigorievka Gorge Trail",
		"Kara-Shoro Nature Park Trail",
		"Aman-Kutan Gorge Trail",
		"Sarmishsay Gorge Petroglyph Trail",
		"Aydarkul Desert Shore Trail",
		"Fergana Valley Foothill Trail",
		"Gissar Range Foothill Trail",
		"Varzob Waterfall Trail",
		"Pshart Valley Trail",
		"Jizeu Valley Trail",
		"Baljuvon Valley Trail",
		"Bogd Khan Tsetsee Gun Trail",
		"Mongol Olle Terelj Route",
		"Khorgo Volcano Crater Trail",
		"Khuvsgul East Shore Trail",
		"Potanin Glacier Base Trail",
		"Onon-Balj Valley Trail",
	} {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("central asia mongolia hiking up migration must include route-level hiking place %q", title)
		}
	}

	for _, duplicateTitle := range []string{
		"Ala Archa National Park",
		"Sulaiman-Too Sacred Mountain",
		"Fann Mountains",
		"Khorgo-Terkhiin Tsagaan Nuur National Park",
	} {
		if strings.Contains(upSQL, duplicateTitle) {
			t.Fatalf("central asia mongolia hiking up migration must avoid duplicating broad seed place %q", duplicateTitle)
		}
	}
	if strings.Contains(upSQL, "highlights") {
		t.Fatalf("central asia mongolia hiking up migration must not write obsolete place_translations.highlights column")
	}
	if !strings.Contains(upSQL, "price_amount = EXCLUDED.price_amount") {
		t.Fatalf("central asia mongolia hiking up migration must update places.price_amount on seed conflict")
	}
	if !strings.Contains(downSQL, "central-asia-mongolia-hiking-v1") {
		t.Fatalf("central asia mongolia hiking down migration must remove only tagged route-level places")
	}
}

var thailandPriorityPlaceIDs = []string{
	"60000000-0000-4000-8000-000000000001",
	"60000000-0000-4000-8000-000000000002",
	"60000000-0000-4000-8000-000000000003",
	"60000000-0000-4000-8000-000000000004",
	"60000000-0000-4000-8000-000000000005",
	"60000000-0000-4000-8000-000000000006",
	"60000000-0000-4000-8000-000000000007",
	"60000000-0000-4000-8000-000000000008",
	"60000000-0000-4000-8000-000000000009",
	"60000000-0000-4000-8000-000000000010",
	"60000000-0000-4000-8000-000000000011",
	"60000000-0000-4000-8000-000000000012",
	"60000000-0000-4000-8000-000000000013",
	"60000000-0000-4000-8000-000000000014",
	"60000000-0000-4000-8000-000000000015",
	"60000000-0000-4000-8000-000000000016",
	"60000000-0000-4000-8000-000000000017",
	"60000000-0000-4000-8000-000000000018",
	"60000000-0000-4000-8000-000000000019",
	"60000000-0000-4000-8000-000000000020",
	"60000000-0000-4000-8000-000000000021",
	"60000000-0000-4000-8000-000000000022",
	"60000000-0000-4000-8000-000000000023",
	"60000000-0000-4000-8000-000000000024",
	"60000000-0000-4000-8000-000000000025",
	"60000000-0000-4000-8000-000000000026",
	"60000000-0000-4000-8000-000000000027",
	"60000000-0000-4000-8000-000000000028",
	"60000000-0000-4000-8000-000000000029",
	"60000000-0000-4000-8000-000000000030",
	"60000000-0000-4000-8000-000000000031",
	"60000000-0000-4000-8000-000000000032",
	"60000000-0000-4000-8000-000000000033",
	"60000000-0000-4000-8000-000000000034",
	"60000000-0000-4000-8000-000000000035",
	"60000000-0000-4000-8000-000000000036",
	"60000000-0000-4000-8000-000000000037",
	"60000000-0000-4000-8000-000000000038",
	"60000000-0000-4000-8000-000000000039",
	"60000000-0000-4000-8000-000000000040",
	"60000000-0000-4000-8000-000000000041",
	"60000000-0000-4000-8000-000000000042",
	"60000000-0000-4000-8000-000000000043",
	"60000000-0000-4000-8000-000000000044",
	"60000000-0000-4000-8000-000000000045",
	"60000000-0000-4000-8000-000000000046",
	"60000000-0000-4000-8000-000000000047",
	"60000000-0000-4000-8000-000000000048",
	"60000000-0000-4000-8000-000000000049",
	"60000000-0000-4000-8000-000000000050",
	"60000000-0000-4000-8000-000000000051",
	"60000000-0000-4000-8000-000000000052",
	"60000000-0000-4000-8000-000000000053",
	"60000000-0000-4000-8000-000000000054",
	"60000000-0000-4000-8000-000000000055",
	"60000000-0000-4000-8000-000000000056",
}

var thailandPriorityMediaIDs = []string{
	"61000000-0000-4000-8000-000000000001",
	"61000000-0000-4000-8000-000000000002",
	"61000000-0000-4000-8000-000000000003",
	"61000000-0000-4000-8000-000000000004",
	"61000000-0000-4000-8000-000000000005",
	"61000000-0000-4000-8000-000000000006",
	"61000000-0000-4000-8000-000000000007",
	"61000000-0000-4000-8000-000000000008",
	"61000000-0000-4000-8000-000000000009",
	"61000000-0000-4000-8000-000000000010",
	"61000000-0000-4000-8000-000000000011",
	"61000000-0000-4000-8000-000000000012",
	"61000000-0000-4000-8000-000000000013",
	"61000000-0000-4000-8000-000000000014",
	"61000000-0000-4000-8000-000000000015",
	"61000000-0000-4000-8000-000000000016",
	"61000000-0000-4000-8000-000000000017",
	"61000000-0000-4000-8000-000000000018",
	"61000000-0000-4000-8000-000000000019",
	"61000000-0000-4000-8000-000000000020",
	"61000000-0000-4000-8000-000000000021",
	"61000000-0000-4000-8000-000000000022",
	"61000000-0000-4000-8000-000000000023",
	"61000000-0000-4000-8000-000000000024",
	"61000000-0000-4000-8000-000000000025",
	"61000000-0000-4000-8000-000000000026",
	"61000000-0000-4000-8000-000000000027",
	"61000000-0000-4000-8000-000000000028",
	"61000000-0000-4000-8000-000000000029",
	"61000000-0000-4000-8000-000000000030",
	"61000000-0000-4000-8000-000000000031",
	"61000000-0000-4000-8000-000000000032",
	"61000000-0000-4000-8000-000000000033",
	"61000000-0000-4000-8000-000000000034",
	"61000000-0000-4000-8000-000000000035",
	"61000000-0000-4000-8000-000000000036",
	"61000000-0000-4000-8000-000000000037",
	"61000000-0000-4000-8000-000000000038",
	"61000000-0000-4000-8000-000000000039",
	"61000000-0000-4000-8000-000000000040",
	"61000000-0000-4000-8000-000000000041",
	"61000000-0000-4000-8000-000000000042",
	"61000000-0000-4000-8000-000000000043",
	"61000000-0000-4000-8000-000000000044",
	"61000000-0000-4000-8000-000000000045",
	"61000000-0000-4000-8000-000000000046",
	"61000000-0000-4000-8000-000000000047",
	"61000000-0000-4000-8000-000000000048",
	"61000000-0000-4000-8000-000000000049",
	"61000000-0000-4000-8000-000000000050",
	"61000000-0000-4000-8000-000000000051",
	"61000000-0000-4000-8000-000000000052",
	"61000000-0000-4000-8000-000000000053",
	"61000000-0000-4000-8000-000000000054",
	"61000000-0000-4000-8000-000000000055",
	"61000000-0000-4000-8000-000000000056",
}

var kazakhstanCityPlaceIDs = []string{
	"2eeacb52-12ef-4499-b229-05e52a199d22",
	"6acdc04c-67b9-4e86-a43f-160738c3dda3",
	"3c070f18-a92c-4d5c-868c-dd4bda71ce95",
	"396f6629-a240-4845-8a5d-2fa33fc42b1b",
	"8a7b975e-9a4e-434e-a7e2-d721c41bda93",
	"ce5ca032-073b-4e4a-93d9-825a4e495574",
	"bc934181-e9d9-4daa-9909-5f87a3169159",
	"33192bba-1776-48e6-918b-198e81b17eae",
	"39759c2a-e2f1-4f2f-b354-d5c29f40fcc9",
	"abede8f2-87db-4f12-bc3e-64e815a1f97e",
	"a752e044-c458-4926-bdd1-76638b74b1c1",
	"1ede5116-b919-493e-9c58-b0027eb5f93b",
	"12e77265-9e9d-4d11-9c6d-acb8aac48f4b",
	"adece1ed-0d63-48e5-b54e-d49cad52a391",
	"9ed105cc-3f78-437a-ad1b-137422f3c8e6",
	"92f6c2cc-1b44-4900-a764-c1daab90024d",
	"d3951503-5e02-41ec-b886-dfc7cce1f925",
	"f1bfab8a-c217-4fe3-b4ba-c65c3fea9a9e",
	"0e06eed4-e871-4f78-919c-a11322eda453",
	"b8847588-a922-42cf-94a2-ffcbf043922a",
	"788b2836-0bbb-40bc-8a14-9548f47979ab",
	"877a0a46-da12-4f4c-be9c-a12a2032f93a",
	"1d3163c5-fa93-484f-b917-f721a8f1ae27",
	"09cdcef4-cb4d-4206-8a7a-2200270401ec",
	"1f32c9d1-d41d-4428-a853-fabe168aadef",
	"25f2452e-9943-463f-a135-27a72df7015d",
	"7344289b-c411-4ad5-ab27-268c06ef3cbb",
	"c7d8a58e-ee75-44cb-93f8-6f93f9a8a929",
	"b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60",
	"90742f2d-6b54-4676-930c-97bc59b60a64",
	"1ab18d1c-be18-4cfc-a5df-4494a4c12aed",
	"e895297e-6ecd-454e-89a5-88e341ccad4f",
	"0ce9cd13-dfc9-481b-821f-78ccaafb48bc",
	"eb123ce9-2da4-4b75-a0cd-d419699c166f",
	"3050b34f-5ecf-4ed3-8438-d6cc8deee7ff",
}

var kazakhstanCityMediaIDs = []string{
	"11000000-0000-4000-8000-000000000001",
	"11000000-0000-4000-8000-000000000002",
	"11000000-0000-4000-8000-000000000003",
	"11000000-0000-4000-8000-000000000004",
	"11000000-0000-4000-8000-000000000005",
	"11000000-0000-4000-8000-000000000006",
	"11000000-0000-4000-8000-000000000007",
	"11000000-0000-4000-8000-000000000008",
	"11000000-0000-4000-8000-000000000009",
	"11000000-0000-4000-8000-000000000010",
	"11000000-0000-4000-8000-000000000011",
	"11000000-0000-4000-8000-000000000012",
	"11000000-0000-4000-8000-000000000013",
	"11000000-0000-4000-8000-000000000014",
	"11000000-0000-4000-8000-000000000015",
	"11000000-0000-4000-8000-000000000016",
	"11000000-0000-4000-8000-000000000017",
	"11000000-0000-4000-8000-000000000018",
	"11000000-0000-4000-8000-000000000019",
	"11000000-0000-4000-8000-000000000020",
	"11000000-0000-4000-8000-000000000021",
	"11000000-0000-4000-8000-000000000022",
	"11000000-0000-4000-8000-000000000023",
	"11000000-0000-4000-8000-000000000024",
	"11000000-0000-4000-8000-000000000025",
	"11000000-0000-4000-8000-000000000026",
	"11000000-0000-4000-8000-000000000027",
	"11000000-0000-4000-8000-000000000028",
	"11000000-0000-4000-8000-000000000029",
	"11000000-0000-4000-8000-000000000030",
	"11000000-0000-4000-8000-000000000031",
	"11000000-0000-4000-8000-000000000032",
	"11000000-0000-4000-8000-000000000033",
	"11000000-0000-4000-8000-000000000034",
	"11000000-0000-4000-8000-000000000035",
}

var russiaCityPlaceIDs = []string{
	"5d5ebfed-9a11-4b17-8710-85e08c8eb9bd",
	"e7891871-76f9-443e-8bef-176277bdd3be",
	"de526545-792c-4c0e-86fe-f837f5085761",
	"38ea9d41-97be-4d8f-b094-cf5531df72c2",
	"e8a575ba-7601-4dff-b166-91a6ced0c519",
	"fc20e31e-1fe7-4945-bb6e-1bd5b9b24a7e",
	"d751994b-5412-4a5c-8d35-883a676c3932",
	"8c3f6b2e-5300-4dda-803c-6925926eea0d",
	"e7adb0e1-4533-4717-a651-8aa4dfa25b16",
	"c719ca75-9b21-45e9-b34e-51bfaad2b1eb",
	"0523f916-2f45-4ccc-9bbc-f55aae4db530",
	"bc9dffeb-7a16-4ee7-8e23-4c2a65dabe6b",
	"0950a134-fee3-4dbf-93f3-d226c816872e",
	"918a79bf-7734-4c69-b7e0-794db0c557d0",
	"22976b07-8e74-49ae-88c3-4a7bde1284c9",
	"60dd38a5-6c88-47f3-9399-0c475d0a0750",
	"8485cd1c-d85f-416b-a1f1-6b6463ef0714",
	"cf5d37e3-9fb7-4bf1-b8f1-73098af22c48",
}

var russiaCityMediaIDs = []string{
	"33000000-0000-4000-8000-000000000001",
	"33000000-0000-4000-8000-000000000002",
	"33000000-0000-4000-8000-000000000003",
	"33000000-0000-4000-8000-000000000004",
	"33000000-0000-4000-8000-000000000005",
	"33000000-0000-4000-8000-000000000006",
	"33000000-0000-4000-8000-000000000007",
	"33000000-0000-4000-8000-000000000008",
	"33000000-0000-4000-8000-000000000009",
	"33000000-0000-4000-8000-000000000010",
	"33000000-0000-4000-8000-000000000011",
	"33000000-0000-4000-8000-000000000012",
	"33000000-0000-4000-8000-000000000013",
	"33000000-0000-4000-8000-000000000014",
	"33000000-0000-4000-8000-000000000015",
	"33000000-0000-4000-8000-000000000016",
	"33000000-0000-4000-8000-000000000017",
	"33000000-0000-4000-8000-000000000018",
}

var vietnamCityPlaceIDs = []string{
	"e4f055be-5d5f-4f63-845f-e3220caff0fb",
	"19bdd927-5df2-4593-b1d8-c7fe71968675",
	"e142d319-5e4c-45b6-b5b2-ac79792b854d",
	"95481324-fb23-4a34-bb2c-1def1a1d8777",
	"60ce09ec-1579-4951-91fa-9918a49a7773",
	"79d877e2-c392-4d27-b500-c8abc645e2c3",
	"ab83611c-6360-4ede-9aa2-6dad96f6cdc4",
	"0d3d4f26-f5e0-4f82-a7a8-850046edae00",
	"98791410-4cf9-444d-818d-463fc10728fa",
	"b95d8c30-4a45-475b-b51f-8346e6795017",
	"8b507042-be77-4e72-a530-78a6ccbf8979",
	"583e0a5e-08b8-47fc-9627-33423c11ae8c",
	"fdedb547-0ae0-4fe8-a413-dec8f9d9f154",
	"89a209fe-1216-46e5-b8e2-bf18bd9e687a",
	"f2b54b44-acbc-40a7-b3e3-4f963d306f42",
	"54117429-8b9c-400d-83ed-b344b3ed8a52",
	"b0f6561c-68a2-4dad-ae5a-80ae3edfc53c",
	"4a6b839b-1252-46bf-b4bc-f93b13d29dc0",
}

var vietnamCityMediaIDs = []string{
	"44000000-0000-4000-8000-000000000001",
	"44000000-0000-4000-8000-000000000002",
	"44000000-0000-4000-8000-000000000003",
	"44000000-0000-4000-8000-000000000004",
	"44000000-0000-4000-8000-000000000005",
	"44000000-0000-4000-8000-000000000006",
	"44000000-0000-4000-8000-000000000007",
	"44000000-0000-4000-8000-000000000008",
	"44000000-0000-4000-8000-000000000009",
	"44000000-0000-4000-8000-000000000010",
	"44000000-0000-4000-8000-000000000011",
	"44000000-0000-4000-8000-000000000012",
	"44000000-0000-4000-8000-000000000013",
	"44000000-0000-4000-8000-000000000014",
	"44000000-0000-4000-8000-000000000015",
	"44000000-0000-4000-8000-000000000016",
	"44000000-0000-4000-8000-000000000017",
	"44000000-0000-4000-8000-000000000018",
}

var phuQuocPlaceIDs = []string{
	"1e717005-4895-4c39-bcbf-5f44cf27d7b4",
	"b581361f-03b8-4cbd-aa9f-059c76a3a9f8",
	"68c2a8e2-47b1-4216-9e9c-46c325018dcb",
	"6af2d076-d948-4469-96d0-0dbf3be6c493",
	"8c93e281-d815-4956-b3cc-183e42c1fbc2",
	"0ab67113-f0f5-4e9a-8dc1-c11912282dc9",
	"a7d39ceb-dee2-4cad-af7c-e1390d68d821",
	"fa67cf61-f366-4d8c-a9cd-bd684d3503dd",
	"dfba89d0-99fb-4a55-aa9a-e9bc6a22a6d0",
}

var phuQuocMediaIDs = []string{
	"45000000-0000-4000-8000-000000000001",
	"45000000-0000-4000-8000-000000000002",
	"45000000-0000-4000-8000-000000000003",
	"45000000-0000-4000-8000-000000000004",
	"45000000-0000-4000-8000-000000000005",
	"45000000-0000-4000-8000-000000000006",
	"45000000-0000-4000-8000-000000000007",
	"45000000-0000-4000-8000-000000000008",
	"45000000-0000-4000-8000-000000000009",
}

var daNangPlaceIDs = []string{
	"c6e51c2f-97dc-4990-8795-a083ee0b265c",
	"3cb82c60-2819-422b-997e-93fb23bfe6ce",
	"03db0318-9e27-4262-bdb3-1f7204998d3a",
	"9346a24c-4be7-4e7c-95bc-b232b19c8b8c",
	"c4d8a4a5-6a97-4aa6-8855-fc538c75c870",
	"5841aaeb-c597-4b89-992d-26a844dd2054",
	"df554637-6f18-49c8-b4b2-8fcedd82962b",
	"c64903fe-b7ab-4812-9124-8ca7d67a2bfb",
	"c9860c73-dfb2-41b2-87f4-01f92f8f3fb0",
	"072f60d2-ef0d-4eae-aa77-51ff1eee274f",
	"58b1ccbc-6671-4112-a6b4-551767360a11",
	"aa81bb79-cabb-477a-ac05-45b863d6df8e",
	"262204b6-09c5-4914-85cf-06a878cd8668",
}

var daNangMediaIDs = []string{
	"46000000-0000-4000-8000-000000000001",
	"46000000-0000-4000-8000-000000000002",
	"46000000-0000-4000-8000-000000000003",
	"46000000-0000-4000-8000-000000000004",
	"46000000-0000-4000-8000-000000000005",
	"46000000-0000-4000-8000-000000000006",
	"46000000-0000-4000-8000-000000000007",
	"46000000-0000-4000-8000-000000000008",
	"46000000-0000-4000-8000-000000000009",
	"46000000-0000-4000-8000-000000000010",
	"46000000-0000-4000-8000-000000000011",
	"46000000-0000-4000-8000-000000000012",
	"46000000-0000-4000-8000-000000000013",
}

var hoiAnPlaceIDs = []string{
	"a3de94cc-f3f7-4a2c-a3c2-3019e723cae8",
	"5bf15e75-29bc-427a-b404-27c14c351405",
	"355accac-cc7e-4272-b475-d31f9fd77a42",
}

var hoiAnMediaIDs = []string{
	"47000000-0000-4000-8000-000000000001",
	"47000000-0000-4000-8000-000000000002",
	"47000000-0000-4000-8000-000000000003",
}

var nhaTrangPlaceIDs = []string{
	"b789d8ae-3f3f-41e3-88b2-e553cd978947",
	"4257b4a9-5a58-4c6b-b0a6-70e5d5307618",
	"24dced8d-8032-477f-abf6-9816d08701bc",
	"0425d348-b915-4c47-9dfe-a3edb8186be5",
	"07040179-73c0-400c-867a-9c97d70bc818",
	"cc3df3f7-e3c4-43c9-855e-9c98957d6f8d",
	"2065e87e-6cd2-4146-9d5b-64b67d8d39fb",
	"a708528c-04c0-452f-ba7f-0729f576aa52",
	"aca1444b-ef1c-4795-8c6f-a454b285567c",
	"b1d53f6d-bfa4-4a3e-8c32-7e46a0c76c08",
	"d2a9f71a-f62c-4b94-b862-8f61955100e3",
	"c78fd68a-17e6-486a-9ac4-c2923a76127b",
	"0b67cda1-5fe1-45e0-94a3-89a2ad43efbf",
}

var nhaTrangMediaIDs = []string{
	"48000000-0000-4000-8000-000000000001",
	"48000000-0000-4000-8000-000000000002",
	"48000000-0000-4000-8000-000000000003",
	"48000000-0000-4000-8000-000000000004",
	"48000000-0000-4000-8000-000000000005",
	"48000000-0000-4000-8000-000000000006",
	"48000000-0000-4000-8000-000000000007",
	"48000000-0000-4000-8000-000000000008",
	"48000000-0000-4000-8000-000000000009",
	"48000000-0000-4000-8000-000000000010",
	"48000000-0000-4000-8000-000000000011",
	"48000000-0000-4000-8000-000000000012",
	"48000000-0000-4000-8000-000000000013",
}

var hanoiPlaceIDs = []string{
	"0429c1dd-586e-4eef-a18f-3b00b55472d0",
	"a1a5bd3d-7ede-4986-9eda-ba9b190a4e6e",
	"9487d156-5a4c-4a93-a359-629a34bf0bd1",
	"0f06fb99-6e0a-4f47-a62a-e6ac62c932a3",
	"71849380-f17f-49f8-bc6a-2bb051011fb8",
	"fa6e73e1-48aa-48cf-9b26-3bc6f953db84",
	"6790557c-eeea-4a09-9f2c-58b3cc7cc7af",
	"74174fa1-4e3c-49bf-ad92-da03c5f3a840",
	"0298b36d-ebb3-4c20-9371-38575e36bac5",
	"4613a547-498e-4781-bdbc-ae3d75dd27b8",
	"587038b0-d882-4220-b65e-005b54d99344",
	"1000f102-63ac-4d09-9d4e-81bde627a01c",
	"2c1910d7-1a31-4768-a4da-fb3e937b3d16",
	"0a73723a-d901-4b73-aaba-655eb0c8b9d9",
}

var hanoiMediaIDs = []string{
	"49000000-0000-4000-8000-000000000001",
	"49000000-0000-4000-8000-000000000002",
	"49000000-0000-4000-8000-000000000003",
	"49000000-0000-4000-8000-000000000004",
	"49000000-0000-4000-8000-000000000005",
	"49000000-0000-4000-8000-000000000006",
	"49000000-0000-4000-8000-000000000007",
	"49000000-0000-4000-8000-000000000008",
	"49000000-0000-4000-8000-000000000009",
	"49000000-0000-4000-8000-000000000010",
	"49000000-0000-4000-8000-000000000011",
	"49000000-0000-4000-8000-000000000012",
	"49000000-0000-4000-8000-000000000013",
	"49000000-0000-4000-8000-000000000014",
}

var vietnamPriorityPlaceIDs = []string{
	"50cffc30-8f22-4c9f-a521-227fdb855854",
	"068b2c8d-f1b8-4eaa-8382-c8bc9460551f",
	"3a8f1a1f-1578-4041-8f17-98578e57523d",
	"7d3c444d-8149-41af-9c56-a638b4c0177e",
	"a0feacec-c1bb-42b3-8bc4-bc17f65b3a86",
	"1a02110b-516c-4b0a-b37f-9b211faf18db",
	"0875c8ea-cd32-45af-99ec-1b11083ce7ca",
	"8e566a6c-dba3-42b4-b279-87f7451992e6",
	"eeb92596-d1fc-4a2a-b68d-e9056a9f5c9a",
	"2870c7d1-306c-43f4-a7ab-ab8b0d977be3",
	"2ac7d4d5-fdcc-4f8a-b266-e389b0070ac3",
	"de6a1063-c64a-4a03-8509-12e619fdf91f",
	"db5ea0d7-7665-4e9a-a2bf-598e49f92f26",
	"051a79f2-dc58-4331-b0e7-eaf2dfe05f20",
	"b05b276c-a167-40c0-8889-aab43a23daaf",
	"78369fbb-7ddb-43a5-a651-541de4aba1f0",
	"bd8693af-fcdd-4906-815d-081fe511fcc3",
	"4539231b-4db3-4081-814d-d134ce2d47fd",
	"04a331f6-90bd-40db-b94f-83c684eb5e59",
	"c049918a-7ea1-4012-9717-4605fd26ae64",
	"8302674f-7fbc-4f13-8ce1-9c46a08e311e",
	"351a6e3e-8cd8-46d0-be36-c8eb00addc39",
	"ce3f9b65-d150-4e4a-8b4f-73e9c33656bc",
	"5b391e30-13eb-4b87-ba2e-0357f3001b11",
	"41606913-cc18-49c6-bafa-7b3d86105a06",
	"60850d97-4f5e-4b98-96ad-7e41e09e75a7",
	"d7a8e30e-2634-434d-8d32-44000738570b",
	"7ceed1a6-7c1c-464c-be77-f7acf2c93fbf",
	"5465a4c9-157f-4f3e-90b9-91d83effeafb",
	"47077c61-67f3-4795-ad9a-8ce9241229b2",
	"e60e5b78-cc7a-492c-8bd2-194ee93424ac",
	"d523f07d-8580-430c-aca2-5cc8bed25418",
	"9becd171-75b3-4488-b2bb-a8256d3ef7dc",
	"92b78b65-7a0e-49a8-9762-473266cd3273",
	"8079371e-0054-4de3-ba54-b6adcd31ac32",
	"eca0e123-5a96-40ee-8798-eb52388c7fdc",
	"1c286d4c-7c97-4ea7-84d1-685adfff457e",
	"3f5cffb0-c452-4cbe-a778-ed70365ed160",
	"ce273330-4881-47ed-971e-982bed13a498",
	"54e204ef-89b1-46a7-a14f-3f6af48ac12c",
	"ee688ac8-af05-4c03-919b-73716f52611c",
	"552694aa-b64a-484f-99ef-7d3f2dc83ca2",
	"93d14027-cf08-4631-aabd-229908d654f3",
	"151b87d9-027f-4a67-8135-1008c74259d4",
	"1616f288-edb9-4517-bfec-ae268d32494e",
	"baee7642-c803-4c95-a461-2d8b22f89404",
	"627c04c6-16f7-4a8d-abc9-189a32d7b656",
}

var vietnamPriorityMediaIDs = []string{
	"50000000-0000-4000-8000-000000000001",
	"50000000-0000-4000-8000-000000000002",
	"50000000-0000-4000-8000-000000000003",
	"50000000-0000-4000-8000-000000000004",
	"50000000-0000-4000-8000-000000000005",
	"50000000-0000-4000-8000-000000000006",
	"50000000-0000-4000-8000-000000000007",
	"50000000-0000-4000-8000-000000000008",
	"50000000-0000-4000-8000-000000000009",
	"50000000-0000-4000-8000-000000000010",
	"50000000-0000-4000-8000-000000000011",
	"50000000-0000-4000-8000-000000000012",
	"50000000-0000-4000-8000-000000000013",
	"50000000-0000-4000-8000-000000000014",
	"50000000-0000-4000-8000-000000000015",
	"50000000-0000-4000-8000-000000000016",
	"50000000-0000-4000-8000-000000000017",
	"50000000-0000-4000-8000-000000000018",
	"50000000-0000-4000-8000-000000000019",
	"50000000-0000-4000-8000-000000000020",
	"50000000-0000-4000-8000-000000000021",
	"50000000-0000-4000-8000-000000000022",
	"50000000-0000-4000-8000-000000000023",
	"50000000-0000-4000-8000-000000000024",
	"50000000-0000-4000-8000-000000000025",
	"50000000-0000-4000-8000-000000000026",
	"50000000-0000-4000-8000-000000000027",
	"50000000-0000-4000-8000-000000000028",
	"50000000-0000-4000-8000-000000000029",
	"50000000-0000-4000-8000-000000000030",
	"50000000-0000-4000-8000-000000000031",
	"50000000-0000-4000-8000-000000000032",
	"50000000-0000-4000-8000-000000000033",
	"50000000-0000-4000-8000-000000000034",
	"50000000-0000-4000-8000-000000000035",
	"50000000-0000-4000-8000-000000000036",
	"50000000-0000-4000-8000-000000000037",
	"50000000-0000-4000-8000-000000000038",
	"50000000-0000-4000-8000-000000000039",
	"50000000-0000-4000-8000-000000000040",
	"50000000-0000-4000-8000-000000000041",
	"50000000-0000-4000-8000-000000000042",
	"50000000-0000-4000-8000-000000000043",
	"50000000-0000-4000-8000-000000000044",
	"50000000-0000-4000-8000-000000000045",
	"50000000-0000-4000-8000-000000000046",
	"50000000-0000-4000-8000-000000000047",
}

func readMigration(t *testing.T, filename string) string {
	t.Helper()

	content, err := os.ReadFile(filepath.Join("..", "..", "..", "migrations", filename))
	if err != nil {
		t.Fatalf("read migration %s: %v", filename, err)
	}

	return string(content)
}
