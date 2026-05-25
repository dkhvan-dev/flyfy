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
