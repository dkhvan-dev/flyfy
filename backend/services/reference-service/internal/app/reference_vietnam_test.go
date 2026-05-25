package app

import (
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/data"
	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/internal/adapter/repository"
)

func TestReferenceUseCaseIncludesVietnamCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("VN")
	if country == nil {
		t.Fatal("expected Vietnam country reference")
	}
	if country.Name.Ru != "Вьетнам" {
		t.Fatalf("Vietnam Russian name = %q, want Вьетнам", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("VN")
	if currency == nil {
		t.Fatal("expected Vietnamese dong currency by country")
	}
	if currency.Code != "VND" {
		t.Fatalf("Vietnam currency = %q, want VND", currency.Code)
	}

	cities := uc.ListCities("VN")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
		"ho-chi-minh-city",
		"hanoi",
		"da-nang",
		"ha-long",
		"ninh-binh",
		"hue",
		"hoi-an",
		"nha-trang",
		"phu-quoc",
		"sa-pa",
		"can-tho",
		"da-lat",
		"phan-thiet",
		"vung-tau",
		"cat-ba",
		"ha-giang",
		"phong-nha",
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Vietnam city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("phan thiet", "VN", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "phan-thiet" {
		t.Fatalf("search phan thiet in Vietnam = %#v, want phan-thiet first", searchResults)
	}
}

func TestReferenceUseCaseIncludesThailandCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("TH")
	if country == nil {
		t.Fatal("expected Thailand country reference")
	}
	if country.Name.Ru != "Таиланд" {
		t.Fatalf("Thailand Russian name = %q, want Таиланд", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("TH")
	if currency == nil {
		t.Fatal("expected Thai baht currency by country")
	}
	if currency.Code != "THB" {
		t.Fatalf("Thailand currency = %q, want THB", currency.Code)
	}

	cities := uc.ListCities("TH")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Thailand city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("koh samui", "TH", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "koh-samui" {
		t.Fatalf("search koh samui in Thailand = %#v, want koh-samui first", searchResults)
	}
}

func TestReferenceUseCaseIncludesPhilippinesCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("PH")
	if country == nil {
		t.Fatal("expected Philippines country reference")
	}
	if country.Name.Ru != "Филиппины" {
		t.Fatalf("Philippines Russian name = %q, want Филиппины", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("PH")
	if currency == nil {
		t.Fatal("expected Philippine peso currency by country")
	}
	if currency.Code != "PHP" {
		t.Fatalf("Philippines currency = %q, want PHP", currency.Code)
	}

	cities := uc.ListCities("PH")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
		"manila",
		"makati",
		"taguig",
		"tagaytay",
		"cebu-city",
		"mactan",
		"bohol",
		"boracay",
		"iloilo",
		"bacolod",
		"puerto-princesa",
		"el-nido",
		"coron",
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
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Philippines city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("puerto princesa", "PH", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "puerto-princesa" {
		t.Fatalf("search puerto princesa in Philippines = %#v, want puerto-princesa first", searchResults)
	}
}

func TestReferenceUseCaseIncludesIndonesiaCountryCurrencyAndTouristHubs(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("ID")
	if country == nil {
		t.Fatal("expected Indonesia country reference")
	}
	if country.Name.Ru != "Индонезия" {
		t.Fatalf("Indonesia Russian name = %q, want Индонезия", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("ID")
	if currency == nil {
		t.Fatal("expected Indonesian rupiah currency by country")
	}
	if currency.Code != "IDR" {
		t.Fatalf("Indonesia currency = %q, want IDR", currency.Code)
	}

	cities := uc.ListCities("ID")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
		"bali",
		"denpasar",
		"kuta",
		"seminyak",
		"canggu",
		"sanur",
		"nusa-dua",
		"jimbaran",
		"uluwatu",
		"ubud",
		"gianyar",
		"tegallalang",
		"tampaksiring",
		"bedugul",
		"tabanan",
		"lovina",
		"singaraja",
		"munduk",
		"amed",
		"candidasa",
		"sidemen",
		"karangasem",
		"kintamani",
		"nusa-penida",
		"nusa-lembongan",
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Indonesia city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("nusa penida", "ID", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "nusa-penida" {
		t.Fatalf("search nusa penida in Indonesia = %#v, want nusa-penida first", searchResults)
	}
}

func TestReferenceUseCaseIncludesMaldivesCountryCurrencyAndTouristIslands(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("MV")
	if country == nil {
		t.Fatal("expected Maldives country reference")
	}
	if country.Name.Ru != "Мальдивы" {
		t.Fatalf("Maldives Russian name = %q, want Мальдивы", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("MV")
	if currency == nil {
		t.Fatal("expected Maldivian rufiyaa currency by country")
	}
	if currency.Code != "MVR" {
		t.Fatalf("Maldives currency = %q, want MVR", currency.Code)
	}

	cities := uc.ListCities("MV")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Maldives city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("maafushi", "MV", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "maafushi" {
		t.Fatalf("search maafushi in Maldives = %#v, want maafushi first", searchResults)
	}
}

func TestReferenceUseCaseIncludesGeorgiaCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("GE")
	if country == nil {
		t.Fatal("expected Georgia country reference")
	}
	if country.Name.Ru != "Грузия" {
		t.Fatalf("Georgia Russian name = %q, want Грузия", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("GE")
	if currency == nil {
		t.Fatal("expected Georgian lari currency by country")
	}
	if currency.Code != "GEL" {
		t.Fatalf("Georgia currency = %q, want GEL", currency.Code)
	}

	cities := uc.ListCities("GE")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Georgia city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("kazbegi", "GE", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "stepantsminda" {
		t.Fatalf("search kazbegi in Georgia = %#v, want stepantsminda first", searchResults)
	}
}

func TestReferenceUseCaseIncludesArmeniaCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("AM")
	if country == nil {
		t.Fatal("expected Armenia country reference")
	}
	if country.Name.Ru != "Армения" {
		t.Fatalf("Armenia Russian name = %q, want Армения", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("AM")
	if currency == nil {
		t.Fatal("expected Armenian dram currency by country")
	}
	if currency.Code != "AMD" {
		t.Fatalf("Armenia currency = %q, want AMD", currency.Code)
	}

	cities := uc.ListCities("AM")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
		"jermuk",
		"goris",
		"tatev",
		"khndzoresk",
		"kapan",
		"meghri",
		"areni",
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Armenia city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("echmiadzin", "AM", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "vagharshapat" {
		t.Fatalf("search echmiadzin in Armenia = %#v, want vagharshapat first", searchResults)
	}
}

func TestReferenceUseCaseIncludesChinaCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("CN")
	if country == nil {
		t.Fatal("expected China country reference")
	}
	if country.Name.Ru != "Китай" {
		t.Fatalf("China Russian name = %q, want Китай", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("CN")
	if currency == nil {
		t.Fatal("expected Chinese yuan currency by country")
	}
	if currency.Code != "CNY" {
		t.Fatalf("China currency = %q, want CNY", currency.Code)
	}

	cities := uc.ListCities("CN")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
		"beijing",
		"shanghai",
		"guangzhou",
		"shenzhen",
		"hangzhou",
		"suzhou",
		"nanjing",
		"xian",
		"chengdu",
		"chongqing",
		"hainan",
		"haikou",
		"sanya",
		"wanning",
		"lingshui",
		"qionghai",
		"danzhou",
		"wenchang",
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("China city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("zhangjiajie", "CN", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "zhangjiajie" {
		t.Fatalf("search zhangjiajie in China = %#v, want zhangjiajie first", searchResults)
	}

	searchResults = uc.SearchCities("hainan", "CN", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "hainan" {
		t.Fatalf("search hainan in China = %#v, want hainan first", searchResults)
	}
}

func TestReferenceUseCaseIncludesSouthKoreaCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("KR")
	if country == nil {
		t.Fatal("expected South Korea country reference")
	}
	if country.Name.Ru != "Южная Корея" {
		t.Fatalf("South Korea Russian name = %q, want Южная Корея", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("KR")
	if currency == nil {
		t.Fatal("expected South Korean won currency by country")
	}
	if currency.Code != "KRW" {
		t.Fatalf("South Korea currency = %q, want KRW", currency.Code)
	}

	cities := uc.ListCities("KR")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
		"seoul",
		"incheon",
		"suwon",
		"yongin",
		"paju",
		"gapyeong",
		"busan",
		"gyeongju",
		"daegu",
		"jeju",
		"seogwipo",
		"sokcho",
		"gangneung",
		"chuncheon",
		"pyeongchang",
		"goseong",
		"cheorwon",
		"yangyang",
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("South Korea city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("gyeongju", "KR", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "gyeongju" {
		t.Fatalf("search gyeongju in South Korea = %#v, want gyeongju first", searchResults)
	}
}

func TestReferenceUseCaseIncludesJapanCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("JP")
	if country == nil {
		t.Fatal("expected Japan country reference")
	}
	if country.Name.Ru != "Япония" {
		t.Fatalf("Japan Russian name = %q, want Япония", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("JP")
	if currency == nil {
		t.Fatal("expected Japanese yen currency by country")
	}
	if currency.Code != "JPY" {
		t.Fatalf("Japan currency = %q, want JPY", currency.Code)
	}

	cities := uc.ListCities("JP")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Japan city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("fujikawaguchiko", "JP", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "fujikawaguchiko" {
		t.Fatalf("search fujikawaguchiko in Japan = %#v, want fujikawaguchiko first", searchResults)
	}
}

func TestReferenceUseCaseIncludesUAECountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("AE")
	if country == nil {
		t.Fatal("expected UAE country reference")
	}
	if country.Name.Ru != "ОАЭ" {
		t.Fatalf("UAE Russian name = %q, want ОАЭ", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("AE")
	if currency == nil {
		t.Fatal("expected UAE dirham currency by country")
	}
	if currency.Code != "AED" {
		t.Fatalf("UAE currency = %q, want AED", currency.Code)
	}

	cities := uc.ListCities("AE")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("UAE city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("ras al khaimah", "AE", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "ras-al-khaimah" {
		t.Fatalf("search ras al khaimah in UAE = %#v, want ras-al-khaimah first", searchResults)
	}
}
