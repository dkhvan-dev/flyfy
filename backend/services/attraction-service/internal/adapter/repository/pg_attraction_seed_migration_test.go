package repository

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestKazakhstanCityAttractionsSeedMigrationCoversMustVisitCityAnchors(t *testing.T) {
	upSQL := readMigration(t, "009_seed_kazakhstan_city_attractions.up.sql")
	downSQL := readMigration(t, "009_seed_kazakhstan_city_attractions.down.sql")

	requiredFragments := []string{
		"INSERT INTO attractions",
		"INSERT INTO attraction_translations",
		"INSERT INTO attraction_city_links",
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
			t.Fatalf("up migration must seed attractions for city_id %q", cityID)
		}
	}

	requiredAttractions := []string{
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
	for _, title := range requiredAttractions {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("up migration must include curated attraction %q", title)
		}
	}

	for _, attractionID := range []string{
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
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("up migration must include attraction id %s", attractionID)
		}
		if !strings.Contains(downSQL, attractionID) {
			t.Fatalf("down migration must delete attraction id %s", attractionID)
		}
	}
}

func TestKazakhstanCityAttractionMediaSeedMigrationCoversEveryCityAttraction(t *testing.T) {
	upSQL := readMigration(t, "010_seed_kazakhstan_city_attraction_media.up.sql")
	downSQL := readMigration(t, "010_seed_kazakhstan_city_attraction_media.down.sql")

	requiredFragments := []string{
		"INSERT INTO attraction_media",
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

	for _, attractionID := range kazakhstanCityAttractionIDs {
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("up media migration must include media for attraction id %s", attractionID)
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

func TestRussiaCityAttractionsSeedMigrationCoversProductionAnchors(t *testing.T) {
	upSQL := readMigration(t, "011_seed_russia_city_attractions.up.sql")
	downSQL := readMigration(t, "011_seed_russia_city_attractions.down.sql")

	requiredFragments := []string{
		"INSERT INTO attractions",
		"INSERT INTO attraction_translations",
		"INSERT INTO attraction_media",
		"INSERT INTO attraction_city_links",
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
			t.Fatalf("Russia up migration must seed attractions for city_id %q", cityID)
		}
	}

	requiredAttractions := []string{
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
	for _, title := range requiredAttractions {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Russia up migration must include curated attraction %q", title)
		}
	}

	for _, attractionID := range russiaCityAttractionIDs {
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("Russia up migration must include attraction id %s", attractionID)
		}
		if !strings.Contains(downSQL, attractionID) {
			t.Fatalf("Russia down migration must delete attraction id %s", attractionID)
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

var kazakhstanCityAttractionIDs = []string{
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

var russiaCityAttractionIDs = []string{
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

func readMigration(t *testing.T, filename string) string {
	t.Helper()

	content, err := os.ReadFile(filepath.Join("..", "..", "..", "migrations", filename))
	if err != nil {
		t.Fatalf("read migration %s: %v", filename, err)
	}

	return string(content)
}
