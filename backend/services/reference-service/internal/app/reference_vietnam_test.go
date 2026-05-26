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

func TestReferenceUseCaseIncludesTurkeyCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("TR")
	if country == nil {
		t.Fatal("expected Turkey country reference")
	}
	if country.Name.Ru != "Турция" {
		t.Fatalf("Turkey Russian name = %q, want Турция", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("TR")
	if currency == nil {
		t.Fatal("expected Turkish lira currency by country")
	}
	if currency.Code != "TRY" {
		t.Fatalf("Turkey currency = %q, want TRY", currency.Code)
	}

	cities := uc.ListCities("TR")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
		"istanbul",
		"princes-islands",
		"ankara",
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
		"denizli",
		"cappadocia",
		"goreme",
		"nevsehir",
		"urgup",
		"uchisar",
		"avanos",
		"konya",
		"trabzon",
		"rize",
		"uzungol",
		"artvin",
		"mardin",
		"sanliurfa",
		"gaziantep",
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Turkey city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("pamukkale", "TR", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "pamukkale" {
		t.Fatalf("search pamukkale in Turkey = %#v, want pamukkale first", searchResults)
	}
}

func TestReferenceUseCaseIncludesEgyptCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("EG")
	if country == nil {
		t.Fatal("expected Egypt country reference")
	}
	if country.Name.Ru != "Египет" {
		t.Fatalf("Egypt Russian name = %q, want Египет", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("EG")
	if currency == nil {
		t.Fatal("expected Egyptian pound currency by country")
	}
	if currency.Code != "EGP" {
		t.Fatalf("Egypt currency = %q, want EGP", currency.Code)
	}

	cities := uc.ListCities("EG")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Egypt city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("sharm el sheikh", "EG", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "sharm-el-sheikh" {
		t.Fatalf("search sharm el sheikh in Egypt = %#v, want sharm-el-sheikh first", searchResults)
	}
}

func TestReferenceUseCaseIncludesMalaysiaCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("MY")
	if country == nil {
		t.Fatal("expected Malaysia country reference")
	}
	if country.Name.Ru != "Малайзия" {
		t.Fatalf("Malaysia Russian name = %q, want Малайзия", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("MY")
	if currency == nil {
		t.Fatal("expected Malaysian ringgit currency by country")
	}
	if currency.Code != "MYR" {
		t.Fatalf("Malaysia currency = %q, want MYR", currency.Code)
	}

	cities := uc.ListCities("MY")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Malaysia city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("george town", "MY", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "george-town" {
		t.Fatalf("search george town in Malaysia = %#v, want george-town first", searchResults)
	}
}

func TestReferenceUseCaseIncludesSriLankaCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("LK")
	if country == nil {
		t.Fatal("expected Sri Lanka country reference")
	}
	if country.Name.Ru != "Шри-Ланка" {
		t.Fatalf("Sri Lanka Russian name = %q, want Шри-Ланка", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("LK")
	if currency == nil {
		t.Fatal("expected Sri Lankan rupee currency by country")
	}
	if currency.Code != "LKR" {
		t.Fatalf("Sri Lanka currency = %q, want LKR", currency.Code)
	}

	cities := uc.ListCities("LK")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Sri Lanka city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("arugam bay", "LK", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "arugam-bay" {
		t.Fatalf("search arugam bay in Sri Lanka = %#v, want arugam-bay first", searchResults)
	}
}

func TestReferenceUseCaseIncludesMontenegroCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("ME")
	if country == nil {
		t.Fatal("expected Montenegro country reference")
	}
	if country.Name.Ru != "Черногория" {
		t.Fatalf("Montenegro Russian name = %q, want Черногория", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("ME")
	if currency == nil {
		t.Fatal("expected euro currency by country")
	}
	if currency.Code != "EUR" {
		t.Fatalf("Montenegro currency = %q, want EUR", currency.Code)
	}

	cities := uc.ListCities("ME")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Montenegro city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("sveti stefan", "ME", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "sveti-stefan" {
		t.Fatalf("search sveti stefan in Montenegro = %#v, want sveti-stefan first", searchResults)
	}
}

func TestReferenceUseCaseIncludesIndiaCountryCurrencyAndTouristCities(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("IN")
	if country == nil {
		t.Fatal("expected India country reference")
	}
	if country.Name.Ru != "Индия" {
		t.Fatalf("India Russian name = %q, want Индия", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("IN")
	if currency == nil {
		t.Fatal("expected Indian rupee currency by country")
	}
	if currency.Code != "INR" {
		t.Fatalf("India currency = %q, want INR", currency.Code)
	}

	cities := uc.ListCities("IN")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("India city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("rishikesh", "IN", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "rishikesh" {
		t.Fatalf("search rishikesh in India = %#v, want rishikesh first", searchResults)
	}
}

func TestReferenceUseCaseIncludesMaltaCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("MT")
	if country == nil {
		t.Fatal("expected Malta country reference")
	}
	if country.Name.Ru != "Мальта" {
		t.Fatalf("Malta Russian name = %q, want Мальта", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("MT")
	if currency == nil {
		t.Fatal("expected euro currency by country")
	}
	if currency.Code != "EUR" {
		t.Fatalf("Malta currency = %q, want EUR", currency.Code)
	}

	cities := uc.ListCities("MT")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Malta city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("st julians", "MT", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "st-julians" {
		t.Fatalf("search st julians in Malta = %#v, want st-julians first", searchResults)
	}
}

func TestReferenceUseCaseIncludesCyprusCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("CY")
	if country == nil {
		t.Fatal("expected Cyprus country reference")
	}
	if country.Name.Ru != "Кипр" {
		t.Fatalf("Cyprus Russian name = %q, want Кипр", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("CY")
	if currency == nil {
		t.Fatal("expected euro currency by country")
	}
	if currency.Code != "EUR" {
		t.Fatalf("Cyprus currency = %q, want EUR", currency.Code)
	}

	cities := uc.ListCities("CY")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Cyprus city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("ayia napa", "CY", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "ayia-napa" {
		t.Fatalf("search ayia napa in Cyprus = %#v, want ayia-napa first", searchResults)
	}
}

func TestReferenceUseCaseIncludesSeychellesCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("SC")
	if country == nil {
		t.Fatal("expected Seychelles country reference")
	}
	if country.Name.Ru != "Сейшелы" {
		t.Fatalf("Seychelles Russian name = %q, want Сейшелы", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("SC")
	if currency == nil {
		t.Fatal("expected Seychellois rupee currency by country")
	}
	if currency.Code != "SCR" {
		t.Fatalf("Seychelles currency = %q, want SCR", currency.Code)
	}

	cities := uc.ListCities("SC")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Seychelles city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("beau vallon", "SC", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "beau-vallon" {
		t.Fatalf("search beau vallon in Seychelles = %#v, want beau-vallon first", searchResults)
	}
}

func TestReferenceUseCaseIncludesPolandCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("PL")
	if country == nil {
		t.Fatal("expected Poland country reference")
	}
	if country.Name.Ru != "Польша" {
		t.Fatalf("Poland Russian name = %q, want Польша", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("PL")
	if currency == nil {
		t.Fatal("expected Polish zloty currency by country")
	}
	if currency.Code != "PLN" {
		t.Fatalf("Poland currency = %q, want PLN", currency.Code)
	}

	cities := uc.ListCities("PL")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Poland city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("wroclaw", "PL", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "wroclaw" {
		t.Fatalf("search wroclaw in Poland = %#v, want wroclaw first", searchResults)
	}
}

func TestReferenceUseCaseIncludesMexicoCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("MX")
	if country == nil {
		t.Fatal("expected Mexico country reference")
	}
	if country.Name.Ru != "Мексика" {
		t.Fatalf("Mexico Russian name = %q, want Мексика", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("MX")
	if currency == nil {
		t.Fatal("expected Mexican peso currency by country")
	}
	if currency.Code != "MXN" {
		t.Fatalf("Mexico currency = %q, want MXN", currency.Code)
	}

	cities := uc.ListCities("MX")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Mexico city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("mexico city", "MX", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "mexico-city" {
		t.Fatalf("search mexico city in Mexico = %#v, want mexico-city first", searchResults)
	}
}

func TestReferenceUseCaseIncludesBrazilCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("BR")
	if country == nil {
		t.Fatal("expected Brazil country reference")
	}
	if country.Name.Ru != "Бразилия" {
		t.Fatalf("Brazil Russian name = %q, want Бразилия", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("BR")
	if currency == nil {
		t.Fatal("expected Brazilian real currency by country")
	}
	if currency.Code != "BRL" {
		t.Fatalf("Brazil currency = %q, want BRL", currency.Code)
	}

	cities := uc.ListCities("BR")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Brazil city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("rio de janeiro", "BR", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "rio-de-janeiro" {
		t.Fatalf("search rio de janeiro in Brazil = %#v, want rio-de-janeiro first", searchResults)
	}
}

func TestReferenceUseCaseIncludesArgentinaCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("AR")
	if country == nil {
		t.Fatal("expected Argentina country reference")
	}
	if country.Name.Ru != "Аргентина" {
		t.Fatalf("Argentina Russian name = %q, want Аргентина", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("AR")
	if currency == nil {
		t.Fatal("expected Argentine peso currency by country")
	}
	if currency.Code != "ARS" {
		t.Fatalf("Argentina currency = %q, want ARS", currency.Code)
	}

	cities := uc.ListCities("AR")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Argentina city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("buenos aires", "AR", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "buenos-aires" {
		t.Fatalf("search buenos aires in Argentina = %#v, want buenos-aires first", searchResults)
	}
}

func TestReferenceUseCaseIncludesSwitzerlandCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("CH")
	if country == nil {
		t.Fatal("expected Switzerland country reference")
	}
	if country.Name.Ru != "Швейцария" {
		t.Fatalf("Switzerland Russian name = %q, want Швейцария", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("CH")
	if currency == nil {
		t.Fatal("expected Swiss franc currency by Switzerland country")
	}
	if currency.Code != "CHF" {
		t.Fatalf("Switzerland currency = %q, want CHF", currency.Code)
	}

	cities := uc.ListCities("CH")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Switzerland city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("zurich", "CH", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "zurich" {
		t.Fatalf("search zurich in Switzerland = %#v, want zurich first", searchResults)
	}
}

func TestReferenceUseCaseIncludesSwedenCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("SE")
	if country == nil {
		t.Fatal("expected Sweden country reference")
	}
	if country.Name.Ru != "Швеция" {
		t.Fatalf("Sweden Russian name = %q, want Швеция", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("SE")
	if currency == nil {
		t.Fatal("expected Swedish krona currency by Sweden country")
	}
	if currency.Code != "SEK" {
		t.Fatalf("Sweden currency = %q, want SEK", currency.Code)
	}

	cities := uc.ListCities("SE")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Sweden city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("stockholm", "SE", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "stockholm" {
		t.Fatalf("search stockholm in Sweden = %#v, want stockholm first", searchResults)
	}
}

func TestReferenceUseCaseIncludesAbkhaziaCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("AB")
	if country == nil {
		t.Fatal("expected Abkhazia country reference")
	}
	if country.Name.Ru != "Абхазия" {
		t.Fatalf("Abkhazia Russian name = %q, want Абхазия", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("AB")
	if currency == nil {
		t.Fatal("expected Russian ruble currency by Abkhazia country")
	}
	if currency.Code != "RUB" {
		t.Fatalf("Abkhazia currency = %q, want RUB", currency.Code)
	}

	cities := uc.ListCities("AB")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Abkhazia city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("sukhum", "AB", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "sukhum" {
		t.Fatalf("search sukhum in Abkhazia = %#v, want sukhum first", searchResults)
	}
}

func TestReferenceUseCaseIncludesCubaCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("CU")
	if country == nil {
		t.Fatal("expected Cuba country reference")
	}
	if country.Name.Ru != "Куба" {
		t.Fatalf("Cuba Russian name = %q, want Куба", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("CU")
	if currency == nil {
		t.Fatal("expected Cuban peso currency by Cuba country")
	}
	if currency.Code != "CUP" {
		t.Fatalf("Cuba currency = %q, want CUP", currency.Code)
	}

	cities := uc.ListCities("CU")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Cuba city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("havana", "CU", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "havana" {
		t.Fatalf("search havana in Cuba = %#v, want havana first", searchResults)
	}
}

func TestReferenceUseCaseIncludesMoroccoCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("MA")
	if country == nil {
		t.Fatal("expected Morocco country reference")
	}
	if country.Name.Ru != "Марокко" {
		t.Fatalf("Morocco Russian name = %q, want Марокко", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("MA")
	if currency == nil {
		t.Fatal("expected Moroccan dirham currency by Morocco country")
	}
	if currency.Code != "MAD" {
		t.Fatalf("Morocco currency = %q, want MAD", currency.Code)
	}

	cities := uc.ListCities("MA")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Morocco city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("marrakech", "MA", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "marrakech" {
		t.Fatalf("search marrakech in Morocco = %#v, want marrakech first", searchResults)
	}
}

func TestReferenceUseCaseIncludesPortugalCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("PT")
	if country == nil {
		t.Fatal("expected Portugal country reference")
	}
	if country.Name.Ru != "Португалия" {
		t.Fatalf("Portugal Russian name = %q, want Португалия", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("PT")
	if currency == nil {
		t.Fatal("expected euro currency by Portugal country")
	}
	if currency.Code != "EUR" {
		t.Fatalf("Portugal currency = %q, want EUR", currency.Code)
	}

	cities := uc.ListCities("PT")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
		"loule",
		"carvoeiro",
		"funchal",
		"madeira",
		"ponta-delgada",
		"sao-miguel",
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
		"porto-santo",
		"terceira",
		"pico",
		"faial",
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Portugal city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("lisbon", "PT", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "lisbon" {
		t.Fatalf("search lisbon in Portugal = %#v, want lisbon first", searchResults)
	}
}

func TestReferenceUseCaseIncludesItalyCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("IT")
	if country == nil {
		t.Fatal("expected Italy country reference")
	}
	if country.Name.Ru != "Италия" {
		t.Fatalf("Italy Russian name = %q, want Италия", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("IT")
	if currency == nil {
		t.Fatal("expected euro currency by Italy country")
	}
	if currency.Code != "EUR" {
		t.Fatalf("Italy currency = %q, want EUR", currency.Code)
	}

	cities := uc.ListCities("IT")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
		"rome",
		"milan",
		"venice",
		"florence",
		"pisa",
		"siena",
		"lucca",
		"tivoli",
		"castelli-romani",
		"ostia",
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Italy city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("florence", "IT", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "florence" {
		t.Fatalf("search florence in Italy = %#v, want florence first", searchResults)
	}
}

func TestReferenceUseCaseIncludesSpainCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("ES")
	if country == nil {
		t.Fatal("expected Spain country reference")
	}
	if country.Name.Ru != "Испания" {
		t.Fatalf("Spain Russian name = %q, want Испания", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("ES")
	if currency == nil {
		t.Fatal("expected euro currency by Spain country")
	}
	if currency.Code != "EUR" {
		t.Fatalf("Spain currency = %q, want EUR", currency.Code)
	}

	cities := uc.ListCities("ES")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Spain city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("barcelona", "ES", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "barcelona" {
		t.Fatalf("search barcelona in Spain = %#v, want barcelona first", searchResults)
	}
}

func TestReferenceUseCaseIncludesLuxembourgCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("LU")
	if country == nil {
		t.Fatal("expected Luxembourg country reference")
	}
	if country.Name.Ru != "Люксембург" {
		t.Fatalf("Luxembourg Russian name = %q, want Люксембург", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("LU")
	if currency == nil {
		t.Fatal("expected euro currency by Luxembourg country")
	}
	if currency.Code != "EUR" {
		t.Fatalf("Luxembourg currency = %q, want EUR", currency.Code)
	}

	cities := uc.ListCities("LU")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Luxembourg city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("luxembourg", "LU", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "luxembourg-city" {
		t.Fatalf("search luxembourg in Luxembourg = %#v, want luxembourg-city first", searchResults)
	}
}

func TestReferenceUseCaseIncludesGermanyCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("DE")
	if country == nil {
		t.Fatal("expected Germany country reference")
	}
	if country.Name.Ru != "Германия" {
		t.Fatalf("Germany Russian name = %q, want Германия", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("DE")
	if currency == nil {
		t.Fatal("expected euro currency by Germany country")
	}
	if currency.Code != "EUR" {
		t.Fatalf("Germany currency = %q, want EUR", currency.Code)
	}

	cities := uc.ListCities("DE")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Germany city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("berlin", "DE", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "berlin" {
		t.Fatalf("search berlin in Germany = %#v, want berlin first", searchResults)
	}
}

func TestReferenceUseCaseIncludesAustriaCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("AT")
	if country == nil {
		t.Fatal("expected Austria country reference")
	}
	if country.Name.Ru != "Австрия" {
		t.Fatalf("Austria Russian name = %q, want Австрия", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("AT")
	if currency == nil {
		t.Fatal("expected euro currency by Austria country")
	}
	if currency.Code != "EUR" {
		t.Fatalf("Austria currency = %q, want EUR", currency.Code)
	}

	cities := uc.ListCities("AT")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Austria city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("zell am see", "AT", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "zell-am-see" {
		t.Fatalf("search zell am see in Austria = %#v, want zell-am-see first", searchResults)
	}
}

func TestReferenceUseCaseIncludesAustraliaCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("AU")
	if country == nil {
		t.Fatal("expected Australia country reference")
	}
	if country.Name.Ru != "Австралия" {
		t.Fatalf("Australia Russian name = %q, want Австралия", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("AU")
	if currency == nil {
		t.Fatal("expected Australian dollar currency by Australia country")
	}
	if currency.Code != "AUD" {
		t.Fatalf("Australia currency = %q, want AUD", currency.Code)
	}

	cities := uc.ListCities("AU")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Australia city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("gold coast", "AU", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "gold-coast" {
		t.Fatalf("search gold coast in Australia = %#v, want gold-coast first", searchResults)
	}
}

func TestReferenceUseCaseIncludesTanzaniaCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("TZ")
	if country == nil {
		t.Fatal("expected Tanzania country reference")
	}
	if country.Name.Ru != "Танзания" {
		t.Fatalf("Tanzania Russian name = %q, want Танзания", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("TZ")
	if currency == nil {
		t.Fatal("expected Tanzanian shilling currency by Tanzania country")
	}
	if currency.Code != "TZS" {
		t.Fatalf("Tanzania currency = %q, want TZS", currency.Code)
	}

	cities := uc.ListCities("TZ")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Tanzania city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("dar es salaam", "TZ", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "dar-es-salaam" {
		t.Fatalf("search dar es salaam in Tanzania = %#v, want dar-es-salaam first", searchResults)
	}
}

func TestReferenceUseCaseIncludesKenyaCountryCurrencyAndTouristDestinations(t *testing.T) {
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		t.Fatalf("new reference repository: %v", err)
	}

	uc := NewReferenceUseCase(repo)

	country := uc.GetCountry("KE")
	if country == nil {
		t.Fatal("expected Kenya country reference")
	}
	if country.Name.Ru != "Кения" {
		t.Fatalf("Kenya Russian name = %q, want Кения", country.Name.Ru)
	}

	currency := uc.GetCurrencyByCountry("KE")
	if currency == nil {
		t.Fatal("expected Kenyan shilling currency by Kenya country")
	}
	if currency.Code != "KES" {
		t.Fatalf("Kenya currency = %q, want KES", currency.Code)
	}

	cities := uc.ListCities("KE")
	cityIDs := make(map[string]bool, len(cities))
	for _, city := range cities {
		cityIDs[city.ID] = true
	}
	requiredCityIDs := []string{
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
	}
	for _, cityID := range requiredCityIDs {
		if !cityIDs[cityID] {
			t.Fatalf("Kenya city references must include %q; got %#v", cityID, cityIDs)
		}
	}

	searchResults := uc.SearchCities("nairobi", "KE", 5)
	if len(searchResults) == 0 || searchResults[0].ID != "nairobi" {
		t.Fatalf("search nairobi in Kenya = %#v, want nairobi first", searchResults)
	}
}
