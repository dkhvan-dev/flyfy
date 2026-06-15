package repository

import (
	"encoding/json"
	"os"
	"regexp"
	"sort"
	"strings"
	"testing"
)

func TestCommunityPlatformBaselineMigrationContainsGeoHubAndProfileSchema(t *testing.T) {
	raw, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read baseline migration: %v", err)
	}
	sql := string(raw)

	required := []string{
		"CREATE TABLE IF NOT EXISTS community_post_profiles",
		"CREATE TABLE IF NOT EXISTS community_blueprints",
		"CREATE TABLE IF NOT EXISTS community_geo_hubs",
		"CREATE TABLE IF NOT EXISTS community_geo_aliases",
		"CREATE TABLE IF NOT EXISTS community_blueprint_geo_coverage",
		"CREATE TABLE IF NOT EXISTS community_instances",
		"post_kind text DEFAULT 'ARTICLE'::text NOT NULL",
		"post_profile_key text DEFAULT 'article_v1'::text NOT NULL",
		"structured_data jsonb DEFAULT '{}'::jsonb NOT NULL",
		"activity_creation_status text",
		"CREATE TABLE IF NOT EXISTS post_activity_intents",
		"post_activity_intents_idempotency_key_key",
	}

	for _, snippet := range required {
		if !strings.Contains(sql, snippet) {
			t.Fatalf("baseline migration missing required community platform snippet %q", snippet)
		}
	}
}

func TestCommunityPlatformBaselineMigrationSeedsHubAliasesForLowTrafficCities(t *testing.T) {
	raw, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read baseline migration: %v", err)
	}
	sql := string(raw)

	required := []string{
		"('KZ', 'taldykorgan', 'KZ', 'almaty'",
		"('KZ', 'kapchagay', 'KZ', 'almaty'",
		"('KZ', 'konaev', 'KZ', 'almaty'",
		"('KZ', 'balkhash', 'KZ', 'almaty'",
		"('KZ', 'kokshetau', 'KZ', 'astana'",
		"('RU', 'omsk', 'RU', 'novosibirsk'",
		"('VN', 'cat-ba', 'VN', 'ha-long'",
		"('VN', 'phan-thiet', 'VN', 'nha-trang'",
	}

	for _, snippet := range required {
		if !strings.Contains(sql, snippet) {
			t.Fatalf("baseline migration missing low-traffic alias seed %q", snippet)
		}
	}
}

func TestCommunityPlatformBaselineMigrationSeedsConsolidatedBlueprintTaxonomy(t *testing.T) {
	raw, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read baseline migration: %v", err)
	}
	sql := string(raw)

	requiredKeys := []string{
		"languages",
		"housing",
		"transport",
		"work_services",
		"marketplace",
		"sports_training",
		"hobbies_workshops",
		"trips_companions",
		"pets",
		"city_life",
		"health_safety",
		"event_board",
		"local_news",
		"questions_answers",
	}

	for _, key := range requiredKeys {
		if !strings.Contains(sql, "'"+key+"'") {
			t.Fatalf("baseline migration missing community blueprint key %q", key)
		}
	}

	deprecatedKeys := []string{
		"language_english",
		"language_french",
		"car_rent",
		"bike_scooter_rent",
		"football",
		"pottery",
		"yoga",
		"pet_friendly_places",
		"vets_and_pet_services",
		"travel_tips",
	}
	for _, key := range deprecatedKeys {
		if strings.Contains(sql, "'"+key+"', '") {
			t.Fatalf("baseline migration still seeds granular community blueprint key %q", key)
		}
	}

	requiredContractSnippets := []string{
		"allowed_post_profile_keys text[]",
		"enabled_tabs text[]",
		"subcategory_keys text[]",
		"promotion_segment_keys text[]",
		"ARRAY['quick_post_v1','listing_v1','event_announcement_v1']::text[]",
		"ARRAY['english','french','spanish','chinese','other_languages']::text[]",
		"ARRAY['housing','long_term_rent','short_term_rent','roommates','real_estate']::text[]",
		"ARRAY['transport','car','bike_scooter','public_transport']::text[]",
	}
	for _, snippet := range requiredContractSnippets {
		if !strings.Contains(sql, snippet) {
			t.Fatalf("baseline migration missing consolidated blueprint contract snippet %q", snippet)
		}
	}
}

func TestCommunityPlatformBaselineMigrationSeedsMachineReadablePostProfileContracts(t *testing.T) {
	raw, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read baseline migration: %v", err)
	}

	profiles := extractSeededPostProfileContracts(t, string(raw))
	requiredProfiles := []string{
		"article_v1",
		"quick_post_v1",
		"listing_v1",
		"event_announcement_v1",
		"question_answer_v1",
		"trip_plan_v1",
	}
	for _, key := range requiredProfiles {
		contract, ok := profiles[key]
		if !ok {
			t.Fatalf("baseline migration missing post profile contract %q", key)
		}
		if contract.Schema.Kind == "" || contract.Schema.Version != 1 {
			t.Fatalf("post profile %q schema must declare kind and version, got %+v", key, contract.Schema)
		}
		if len(contract.Schema.Fields) == 0 {
			t.Fatalf("post profile %q schema must describe fields", key)
		}
		if len(contract.Validation.Required) == 0 {
			t.Fatalf("post profile %q validation must declare required fields", key)
		}
	}

	for _, key := range []string{"event_announcement_v1", "trip_plan_v1"} {
		contract := profiles[key]
		if contract.Schema.ActivityMapping == nil {
			t.Fatalf("post profile %q must define activityMapping for activity intent creation", key)
		}
		if strings.TrimSpace(contract.Schema.ActivityMapping.TitleField) == "" ||
			strings.TrimSpace(contract.Schema.ActivityMapping.StartAtField) == "" ||
			strings.TrimSpace(contract.Schema.ActivityMapping.LocationField) == "" {
			t.Fatalf("post profile %q activityMapping must map title/start/location fields, got %+v", key, contract.Schema.ActivityMapping)
		}
	}
}

func TestCommunityPlatformBaselineMigrationSeedsBlueprintGeoCoverage(t *testing.T) {
	raw, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read baseline migration: %v", err)
	}
	sql := string(raw)

	required := []string{
		"INSERT INTO community_blueprint_geo_coverage",
		"cb.allowed_scope_types @> ARRAY['CITY']::text[]",
		"gh.community_enabled = true",
		"gh.hub_tier <> 'ALIAS_ONLY'",
		"ON CONFLICT DO NOTHING",
	}
	for _, snippet := range required {
		if !strings.Contains(sql, snippet) {
			t.Fatalf("baseline migration missing blueprint geo coverage snippet %q", snippet)
		}
	}
}

type seededPostProfileContract struct {
	Schema     seededPostProfileSchema
	Validation seededPostProfileValidation
}

type seededPostProfileSchema struct {
	Kind            string                        `json:"kind"`
	Version         int                           `json:"version"`
	Fields          map[string]seededProfileField `json:"fields"`
	ActivityMapping *seededActivityMapping        `json:"activityMapping"`
}

type seededProfileField struct {
	Type string `json:"type"`
}

type seededActivityMapping struct {
	TitleField       string `json:"titleField"`
	DescriptionField string `json:"descriptionField"`
	StartAtField     string `json:"startAtField"`
	EndAtField       string `json:"endAtField"`
	LocationField    string `json:"locationField"`
	CapacityField    string `json:"capacityField"`
	PriceField       string `json:"priceField"`
}

type seededPostProfileValidation struct {
	Required []string `json:"required"`
}

func extractSeededPostProfileContracts(t *testing.T, sql string) map[string]seededPostProfileContract {
	t.Helper()

	re := regexp.MustCompile(`\('([^']+)',\s*1,\s*'[^']+',\s*'[^']+',\s*'[^']+',\s*'([^']+)'\:\:jsonb,\s*'([^']+)'\:\:jsonb,\s*'[^']+',\s*'[^']+'\)`)
	matches := re.FindAllStringSubmatch(sql, -1)
	if len(matches) == 0 {
		t.Fatalf("could not extract seeded post profile rows from baseline migration")
	}

	result := make(map[string]seededPostProfileContract, len(matches))
	for _, match := range matches {
		key := match[1]
		var schema seededPostProfileSchema
		if err := json.Unmarshal([]byte(match[2]), &schema); err != nil {
			t.Fatalf("post profile %q schema_json is not valid json: %v", key, err)
		}
		var validation seededPostProfileValidation
		if err := json.Unmarshal([]byte(match[3]), &validation); err != nil {
			t.Fatalf("post profile %q validation_json is not valid json: %v", key, err)
		}
		result[key] = seededPostProfileContract{
			Schema:     schema,
			Validation: validation,
		}
	}

	return result
}

func TestCommunityPlatformBaselineMigrationDoesNotSeedCountryCommunities(t *testing.T) {
	raw, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read baseline migration: %v", err)
	}
	sql := string(raw)
	forbidden := []string{
		"country_catalog(country_code, priority) AS (",
		"country_coverage AS (",
		"'COUNTRY'::text AS scope_type",
		"cb.allowed_scope_types @> ARRAY['COUNTRY']::text[]",
		"ARRAY['CITY','COUNTRY']",
		"ARRAY['COUNTRY','CITY']",
		"'COUNTRY_ONLY', ARRAY",
	}
	for _, snippet := range forbidden {
		if !strings.Contains(sql, snippet) {
			continue
		}
		t.Fatalf("baseline migration still seeds country-level community snippet %q", snippet)
	}
}

func TestCommunityPlatformBaselineMigrationSeedsPrimaryCityHubForEachCatalogCountry(t *testing.T) {
	raw, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read baseline migration: %v", err)
	}
	cityRaw, err := os.ReadFile("../../../../reference-service/data/cities.json")
	if err != nil {
		t.Fatalf("read reference cities catalog: %v", err)
	}

	var cities []struct {
		ID          string `json:"id"`
		CountryCode string `json:"countryCode"`
	}
	if err := json.Unmarshal(cityRaw, &cities); err != nil {
		t.Fatalf("parse reference cities catalog: %v", err)
	}

	primaryCityByCountry := make(map[string]string)
	for _, city := range cities {
		countryCode := strings.TrimSpace(city.CountryCode)
		if countryCode == "" || strings.TrimSpace(city.ID) == "" {
			continue
		}
		if _, exists := primaryCityByCountry[countryCode]; !exists {
			primaryCityByCountry[countryCode] = city.ID
		}
	}

	countries := make([]string, 0, len(primaryCityByCountry))
	for countryCode := range primaryCityByCountry {
		countries = append(countries, countryCode)
	}
	sort.Strings(countries)

	sql := string(raw)
	for _, countryCode := range countries {
		cityID := primaryCityByCountry[countryCode]
		snippet := "('" + countryCode + "', '" + cityID + "',"
		rowStart := strings.Index(sql, snippet)
		if rowStart < 0 {
			t.Fatalf("community_geo_hubs missing primary catalog city hub %s/%s", countryCode, cityID)
		}
		rowEnd := strings.Index(sql[rowStart:], "\n")
		if rowEnd < 0 {
			t.Fatalf("community_geo_hubs primary city row for %s/%s is malformed", countryCode, cityID)
		}
		row := sql[rowStart : rowStart+rowEnd]
		if !strings.Contains(row, "true") || strings.Contains(row, "'ALIAS_ONLY'") {
			t.Fatalf("primary catalog city %s/%s must be an enabled non-alias hub, row: %s", countryCode, cityID, row)
		}
	}
}

func TestCommunityPlatformBaselineMigrationSeedsSecondaryTouristAndMajorCityHubs(t *testing.T) {
	raw, err := os.ReadFile("../../../migrations/001_init.up.sql")
	if err != nil {
		t.Fatalf("read baseline migration: %v", err)
	}
	cityRaw, err := os.ReadFile("../../../../reference-service/data/cities.json")
	if err != nil {
		t.Fatalf("read reference cities catalog: %v", err)
	}

	var cities []struct {
		ID          string `json:"id"`
		CountryCode string `json:"countryCode"`
	}
	if err := json.Unmarshal(cityRaw, &cities); err != nil {
		t.Fatalf("parse reference cities catalog: %v", err)
	}
	catalogCities := make(map[string]bool, len(cities))
	for _, city := range cities {
		catalogCities[city.CountryCode+"/"+city.ID] = true
	}

	requiredHubs := []struct {
		countryCode string
		cityID      string
	}{
		{"KZ", "shymkent"},
		{"KZ", "aktau"},
		{"KZ", "turkestan"},
		{"RU", "spb"},
		{"RU", "yekaterinburg"},
		{"RU", "kazan"},
		{"RU", "sochi"},
		{"UZ", "samarkand"},
		{"UZ", "bukhara"},
		{"UZ", "khiva"},
		{"UZ", "fergana"},
		{"KG", "osh"},
		{"KG", "karakol"},
		{"KG", "cholpon-ata"},
		{"TJ", "khujand"},
		{"TJ", "panjakent"},
		{"TJ", "khorog"},
		{"GE", "kutaisi"},
		{"GE", "stepantsminda"},
		{"GE", "gudauri"},
		{"GE", "telavi"},
		{"GE", "borjomi"},
		{"GE", "kobuleti"},
		{"AZ", "ganja"},
		{"AZ", "sheki"},
		{"AZ", "gabala"},
		{"AM", "gyumri"},
		{"AM", "dilijan"},
		{"AM", "tsaghkadzor"},
		{"RS", "novi-sad"},
		{"RS", "nis"},
		{"GR", "thessaloniki"},
		{"GR", "rhodes"},
		{"TH", "phuket"},
		{"TH", "pattaya"},
		{"TH", "chiang-mai"},
		{"TH", "krabi"},
		{"PH", "cebu-city"},
		{"PH", "boracay"},
		{"VN", "ninh-binh"},
		{"VN", "hue"},
		{"VN", "hoi-an"},
		{"VN", "da-lat"},
		{"VN", "sa-pa"},
		{"EG", "luxor"},
		{"EG", "hurghada"},
		{"EG", "sharm-el-sheikh"},
		{"CN", "shanghai"},
		{"CN", "xian"},
		{"CN", "chengdu"},
		{"CN", "guilin"},
		{"KR", "busan"},
		{"KR", "jeju"},
		{"JP", "osaka"},
		{"JP", "kyoto"},
		{"JP", "nara"},
		{"IN", "jaipur"},
		{"IN", "varanasi"},
		{"IN", "goa"},
		{"US", "los-angeles"},
		{"US", "miami"},
		{"US", "san-francisco"},
		{"US", "las-vegas"},
		{"CA", "vancouver"},
		{"CA", "whistler"},
		{"GB", "edinburgh"},
		{"GB", "oxford"},
		{"GB", "cambridge"},
		{"DE", "munich"},
		{"DE", "hamburg"},
		{"AT", "salzburg"},
		{"AT", "innsbruck"},
		{"AU", "melbourne"},
		{"AU", "gold-coast"},
		{"NZ", "rotorua"},
		{"NZ", "queenstown"},
		{"TZ", "zanzibar-city"},
		{"TZ", "arusha"},
		{"KE", "mombasa"},
		{"FR", "nice"},
		{"FR", "lyon"},
		{"FR", "marseille"},
		{"IT", "milan"},
		{"IT", "venice"},
		{"IT", "florence"},
		{"ES", "barcelona"},
		{"ES", "valencia"},
		{"ES", "seville"},
		{"MY", "george-town"},
		{"MY", "langkawi"},
		{"ID", "bali"},
		{"ID", "denpasar"},
		{"PL", "krakow"},
		{"PL", "gdansk"},
		{"MX", "cancun"},
		{"MX", "playa-del-carmen"},
		{"BR", "sao-paulo"},
		{"CU", "varadero"},
		{"MA", "tangier"},
		{"MA", "marrakech"},
		{"PT", "porto"},
		{"LK", "kandy"},
		{"ME", "kotor"},
		{"ME", "budva"},
		{"CY", "limassol"},
		{"CY", "paphos"},
		{"CH", "geneva"},
		{"IE", "galway"},
		{"NL", "rotterdam"},
		{"SE", "gothenburg"},
		{"CZ", "cesky-krumlov"},
	}

	sql := string(raw)
	for _, hub := range requiredHubs {
		key := hub.countryCode + "/" + hub.cityID
		if !catalogCities[key] {
			t.Fatalf("required secondary hub %s is not present in reference cities catalog", key)
		}
		snippet := "('" + hub.countryCode + "', '" + hub.cityID + "',"
		rowStart := strings.Index(sql, snippet)
		if rowStart < 0 {
			t.Fatalf("community_geo_hubs missing secondary tourist/major hub %s", key)
		}
		rowEnd := strings.Index(sql[rowStart:], "\n")
		if rowEnd < 0 {
			t.Fatalf("community_geo_hubs secondary hub row for %s is malformed", key)
		}
		row := sql[rowStart : rowStart+rowEnd]
		if !strings.Contains(row, "true") || strings.Contains(row, "'ALIAS_ONLY'") {
			t.Fatalf("secondary tourist/major hub %s must be an enabled non-alias hub, row: %s", key, row)
		}
	}
}

func TestCommunityPlatformRepositoryExposesReadModels(t *testing.T) {
	portRaw, err := os.ReadFile("../../domain/port/repository.go")
	if err != nil {
		t.Fatalf("read repository port: %v", err)
	}
	repoRaw, err := os.ReadFile("pg_community_repository.go")
	if err != nil {
		t.Fatalf("read community repository: %v", err)
	}

	portSource := string(portRaw)
	repoSource := string(repoRaw)
	requiredPortMethods := []string{
		"ListCommunityPostProfiles(ctx context.Context, filter model.CommunityPostProfileListFilter)",
		"ListCommunityBlueprints(ctx context.Context, filter model.CommunityBlueprintListFilter)",
		"ListCommunityGeoHubs(ctx context.Context, filter model.CommunityGeoHubListFilter)",
		"ListCommunityInstances(ctx context.Context, filter model.CommunityInstanceListFilter)",
	}
	for _, snippet := range requiredPortMethods {
		if !strings.Contains(portSource, snippet) {
			t.Fatalf("repository port missing community platform method %q", snippet)
		}
	}

	requiredRepoMethods := []string{
		"func (r *PGPostRepository) ListCommunityPostProfiles",
		"func (r *PGPostRepository) ListCommunityBlueprints",
		"func (r *PGPostRepository) ListCommunityGeoHubs",
		"func (r *PGPostRepository) ListCommunityInstances",
		"FROM community_post_profiles",
		"FROM community_blueprints",
		"FROM community_geo_hubs",
		"FROM community_instances",
	}
	for _, snippet := range requiredRepoMethods {
		if !strings.Contains(repoSource, snippet) {
			t.Fatalf("community repository missing platform implementation snippet %q", snippet)
		}
	}
}

func TestCommunityPlatformMaterializationContract(t *testing.T) {
	portRaw, err := os.ReadFile("../../domain/port/repository.go")
	if err != nil {
		t.Fatalf("read repository port: %v", err)
	}
	repoRaw, err := os.ReadFile("pg_community_repository.go")
	if err != nil {
		t.Fatalf("read community repository: %v", err)
	}
	handlerRaw, err := os.ReadFile("../http/handler.go")
	if err != nil {
		t.Fatalf("read http handler: %v", err)
	}

	requiredPort := []string{
		"MaterializeCommunityInstances(ctx context.Context, filter model.CommunityInstanceMaterializationFilter)",
	}
	for _, snippet := range requiredPort {
		if !strings.Contains(string(portRaw), snippet) {
			t.Fatalf("repository port missing materialization snippet %q", snippet)
		}
	}

	repoSource := string(repoRaw)
	requiredRepo := []string{
		"func (r *PGPostRepository) MaterializeCommunityInstances",
		"INSERT INTO communities",
		"INSERT INTO community_instances",
		"community_blueprint_geo_coverage",
		"ON CONFLICT (id) DO UPDATE",
		"WHEN default_moderation_mode = 'TRUSTED_PUBLISH_ELSE_REVIEW' THEN 'MEMBERS_AFTER_MODERATION'",
	}
	for _, snippet := range requiredRepo {
		if !strings.Contains(repoSource, snippet) {
			t.Fatalf("community repository missing materialization snippet %q", snippet)
		}
	}
	if strings.Contains(repoSource, "WHEN default_moderation_mode = 'TRUSTED_PUBLISH_ELSE_REVIEW' THEN 'TRUSTED_MEMBERS'") {
		t.Fatal("trusted-publish-else-review blueprints must allow members to create posts and send them to moderation")
	}

	handlerSource := string(handlerRaw)
	requiredHTTP := []string{
		"POST /internal/v1/community-instances/materialize",
		"MaterializeAdminCommunityInstances",
	}
	for _, snippet := range requiredHTTP {
		if !strings.Contains(handlerSource, snippet) {
			t.Fatalf("http handler missing materialization snippet %q", snippet)
		}
	}
}

func TestCommunityPlatformMaterializationStoresBlueprintTitleWithoutLocationSuffix(t *testing.T) {
	repoRaw, err := os.ReadFile("pg_community_repository.go")
	if err != nil {
		t.Fatalf("read community repository: %v", err)
	}
	repoSource := string(repoRaw)

	forbidden := []string{
		"location_label",
		"concat_ws(' · '",
	}
	for _, snippet := range forbidden {
		if strings.Contains(repoSource, snippet) {
			t.Fatalf("community materialization must not persist location suffix in title_i18n; found %q", snippet)
		}
	}
	if !strings.Contains(repoSource, "title_i18n AS title_i18n") {
		t.Fatalf("community materialization must persist blueprint title_i18n directly")
	}
}
