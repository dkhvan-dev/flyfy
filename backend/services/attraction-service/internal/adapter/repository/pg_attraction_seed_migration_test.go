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

func TestVietnamCityAttractionsSeedMigrationCoversProductionAnchors(t *testing.T) {
	upSQL := readMigration(t, "012_seed_vietnam_city_attractions.up.sql")
	downSQL := readMigration(t, "012_seed_vietnam_city_attractions.down.sql")

	requiredFragments := []string{
		"INSERT INTO attractions",
		"INSERT INTO attraction_translations",
		"INSERT INTO attraction_media",
		"INSERT INTO attraction_city_links",
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
			t.Fatalf("Vietnam up migration must seed attractions for city_id %q", cityID)
		}
	}

	requiredAttractions := []string{
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
	for _, title := range requiredAttractions {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Vietnam up migration must include curated attraction %q", title)
		}
	}

	for _, attractionID := range vietnamCityAttractionIDs {
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("Vietnam up migration must include attraction id %s", attractionID)
		}
		if !strings.Contains(downSQL, attractionID) {
			t.Fatalf("Vietnam down migration must delete attraction id %s", attractionID)
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

func TestPhuQuocAttractionsSeedMigrationCoversRequestedAnchors(t *testing.T) {
	upSQL := readMigration(t, "013_seed_phu_quoc_attractions.up.sql")
	downSQL := readMigration(t, "013_seed_phu_quoc_attractions.down.sql")

	requiredFragments := []string{
		"INSERT INTO attractions",
		"INSERT INTO attraction_translations",
		"INSERT INTO attraction_media",
		"INSERT INTO attraction_city_links",
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

	requiredAttractions := []string{
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
	for _, title := range requiredAttractions {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Phu Quoc up migration must include requested attraction %q", title)
		}
	}

	for _, attractionID := range phuQuocAttractionIDs {
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("Phu Quoc up migration must include attraction id %s", attractionID)
		}
		if !strings.Contains(downSQL, attractionID) {
			t.Fatalf("Phu Quoc down migration must delete attraction id %s", attractionID)
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

func TestDaNangAttractionsSeedMigrationCoversRequestedAnchors(t *testing.T) {
	upSQL := readMigration(t, "014_seed_da_nang_attractions.up.sql")
	downSQL := readMigration(t, "014_seed_da_nang_attractions.down.sql")

	requiredFragments := []string{
		"INSERT INTO attractions",
		"INSERT INTO attraction_translations",
		"INSERT INTO attraction_media",
		"INSERT INTO attraction_city_links",
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

	requiredAttractions := []string{
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
	for _, title := range requiredAttractions {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Da Nang up migration must include requested attraction %q", title)
		}
	}

	for _, attractionID := range daNangAttractionIDs {
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("Da Nang up migration must include attraction id %s", attractionID)
		}
		if !strings.Contains(downSQL, attractionID) {
			t.Fatalf("Da Nang down migration must delete attraction id %s", attractionID)
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

func TestHoiAnAttractionsSeedMigrationCoversRequestedAnchors(t *testing.T) {
	upSQL := readMigration(t, "015_seed_hoi_an_attractions.up.sql")
	downSQL := readMigration(t, "015_seed_hoi_an_attractions.down.sql")

	requiredFragments := []string{
		"INSERT INTO attractions",
		"INSERT INTO attraction_translations",
		"INSERT INTO attraction_media",
		"INSERT INTO attraction_city_links",
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

	requiredAttractions := []string{
		"Cam Thanh Coconut Village",
		"Precious Heritage Art Gallery Museum",
		"Hoi An Memories Land",
	}
	for _, title := range requiredAttractions {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Hoi An up migration must include requested attraction %q", title)
		}
	}

	for _, attractionID := range hoiAnAttractionIDs {
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("Hoi An up migration must include attraction id %s", attractionID)
		}
		if !strings.Contains(downSQL, attractionID) {
			t.Fatalf("Hoi An down migration must delete attraction id %s", attractionID)
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

func TestNhaTrangAttractionsSeedMigrationCoversRequestedAnchors(t *testing.T) {
	upSQL := readMigration(t, "016_seed_nha_trang_attractions.up.sql")
	downSQL := readMigration(t, "016_seed_nha_trang_attractions.down.sql")

	requiredFragments := []string{
		"INSERT INTO attractions",
		"INSERT INTO attraction_translations",
		"INSERT INTO attraction_media",
		"INSERT INTO attraction_city_links",
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

	requiredAttractions := []string{
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
	for _, title := range requiredAttractions {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Nha Trang up migration must include requested attraction %q", title)
		}
	}

	for _, attractionID := range nhaTrangAttractionIDs {
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("Nha Trang up migration must include attraction id %s", attractionID)
		}
		if !strings.Contains(downSQL, attractionID) {
			t.Fatalf("Nha Trang down migration must delete attraction id %s", attractionID)
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

func TestHanoiAttractionsSeedMigrationCoversRequestedAnchors(t *testing.T) {
	upSQL := readMigration(t, "017_seed_hanoi_attractions.up.sql")
	downSQL := readMigration(t, "017_seed_hanoi_attractions.down.sql")

	requiredFragments := []string{
		"INSERT INTO attractions",
		"INSERT INTO attraction_translations",
		"INSERT INTO attraction_media",
		"INSERT INTO attraction_city_links",
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

	requiredAttractions := []string{
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
	for _, title := range requiredAttractions {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Hanoi up migration must include requested attraction %q", title)
		}
	}

	for _, attractionID := range hanoiAttractionIDs {
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("Hanoi up migration must include attraction id %s", attractionID)
		}
		if !strings.Contains(downSQL, attractionID) {
			t.Fatalf("Hanoi down migration must delete attraction id %s", attractionID)
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

func TestVietnamPriorityAttractionsSeedMigrationCoversProductionAnchors(t *testing.T) {
	upSQL := readMigration(t, "018_seed_vietnam_priority_attractions.up.sql")
	downSQL := readMigration(t, "018_seed_vietnam_priority_attractions.down.sql")

	requiredFragments := []string{
		"INSERT INTO attractions",
		"INSERT INTO attraction_translations",
		"INSERT INTO attraction_media",
		"INSERT INTO attraction_city_links",
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
	if !strings.Contains(upSQL, "DROP TABLE IF EXISTS seed_vietnam_priority_attractions") {
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
			t.Fatalf("Vietnam priority up migration must seed attractions for city_id %q", cityID)
		}
	}

	requiredAttractions := []string{
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
	for _, title := range requiredAttractions {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Vietnam priority up migration must include curated attraction %q", title)
		}
	}

	for _, attractionID := range vietnamPriorityAttractionIDs {
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("Vietnam priority up migration must include attraction id %s", attractionID)
		}
		if !strings.Contains(downSQL, attractionID) {
			t.Fatalf("Vietnam priority down migration must delete attraction id %s", attractionID)
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

func TestMarketCategoryMigrationRetagsKnownMarketAttractions(t *testing.T) {
	upSQL := readMigration(t, "019_attraction_market_category.up.sql")
	downSQL := readMigration(t, "019_attraction_market_category.down.sql")

	requiredUpFragments := []string{
		"DROP CONSTRAINT IF EXISTS chk_attractions_category",
		"ADD CONSTRAINT chk_attractions_category",
		"'MARKET', 'SHOPPING'",
		"UPDATE attractions",
		"category = 'MARKET'",
		"updated_at = NOW()",
		"source = 'IMPORT'",
	}
	for _, fragment := range requiredUpFragments {
		if !strings.Contains(upSQL, fragment) {
			t.Fatalf("market category up migration must contain %q", fragment)
		}
	}

	marketAttractionIDs := []string{
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
	for _, attractionID := range marketAttractionIDs {
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("market category up migration must update attraction id %s", attractionID)
		}
		if !strings.Contains(downSQL, attractionID) {
			t.Fatalf("market category down migration must restore attraction id %s", attractionID)
		}
	}
	for _, category := range []string{"'FOOD'", "'SHOPPING'"} {
		if !strings.Contains(downSQL, category) {
			t.Fatalf("market category down migration must restore previous category %s", category)
		}
	}
	for _, fragment := range []string{
		"DROP CONSTRAINT IF EXISTS chk_attractions_category",
		"ADD CONSTRAINT chk_attractions_category",
		"WHERE category = 'MARKET'",
	} {
		if !strings.Contains(downSQL, fragment) {
			t.Fatalf("market category down migration must contain %q", fragment)
		}
	}
}

func TestThailandPriorityAttractionsSeedMigrationCoversTouristClusters(t *testing.T) {
	upSQL := readMigration(t, "020_seed_thailand_priority_attractions.up.sql")
	downSQL := readMigration(t, "020_seed_thailand_priority_attractions.down.sql")

	requiredFragments := []string{
		"INSERT INTO attractions",
		"INSERT INTO attraction_translations",
		"INSERT INTO attraction_media",
		"INSERT INTO attraction_city_links",
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
			t.Fatalf("Thailand up migration must seed attractions for city_id %q", cityID)
		}
	}

	requiredAttractions := []string{
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
	for _, title := range requiredAttractions {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Thailand up migration must include curated attraction %q", title)
		}
	}

	for _, category := range []string{"'MARKET'", "'SHOPPING'", "'BEACH'", "'TEMPLE'", "'MUSEUM'"} {
		if !strings.Contains(upSQL, category) {
			t.Fatalf("Thailand up migration must include category %s", category)
		}
	}

	for _, attractionID := range thailandPriorityAttractionIDs {
		if !strings.Contains(upSQL, attractionID) {
			t.Fatalf("Thailand up migration must include attraction id %s", attractionID)
		}
		if !strings.Contains(downSQL, attractionID) {
			t.Fatalf("Thailand down migration must delete attraction id %s", attractionID)
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

func TestPhilippinesPriorityAttractionsSeedMigrationCoversTouristClusters(t *testing.T) {
	upSQL := readMigration(t, "022_seed_philippines_priority_attractions.up.sql")
	downSQL := readMigration(t, "022_seed_philippines_priority_attractions.down.sql")

	requiredFragments := []string{
		"INSERT INTO attractions",
		"INSERT INTO attraction_translations",
		"INSERT INTO attraction_media",
		"INSERT INTO attraction_city_links",
		"CREATE TEMP TABLE seed_philippines_resolved_attractions AS",
		"'PH'",
		"source = 'IMPORT'",
		"md5('ph-attraction:'",
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
	if !strings.Contains(upSQL, "DROP TABLE IF EXISTS seed_philippines_resolved_attractions") {
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
			t.Fatalf("Philippines up migration must seed attractions for city_id %q", cityID)
		}
	}

	requiredAttractions := []string{
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
	for _, title := range requiredAttractions {
		if !strings.Contains(upSQL, title) {
			t.Fatalf("Philippines up migration must include curated attraction %q", title)
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
	if !strings.Contains(downSQL, "md5('ph-attraction:'") || !strings.Contains(downSQL, "md5('ph-media:'") {
		t.Fatalf("Philippines down migration must compute deterministic attraction and media ids")
	}
}

var thailandPriorityAttractionIDs = []string{
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

var vietnamCityAttractionIDs = []string{
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

var phuQuocAttractionIDs = []string{
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

var daNangAttractionIDs = []string{
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

var hoiAnAttractionIDs = []string{
	"a3de94cc-f3f7-4a2c-a3c2-3019e723cae8",
	"5bf15e75-29bc-427a-b404-27c14c351405",
	"355accac-cc7e-4272-b475-d31f9fd77a42",
}

var hoiAnMediaIDs = []string{
	"47000000-0000-4000-8000-000000000001",
	"47000000-0000-4000-8000-000000000002",
	"47000000-0000-4000-8000-000000000003",
}

var nhaTrangAttractionIDs = []string{
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

var hanoiAttractionIDs = []string{
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

var vietnamPriorityAttractionIDs = []string{
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
