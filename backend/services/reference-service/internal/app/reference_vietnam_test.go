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
