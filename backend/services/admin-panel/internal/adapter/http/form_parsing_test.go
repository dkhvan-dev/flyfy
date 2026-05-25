package http

import (
	"bytes"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

func TestParseRequestFormReadsCSRFFromMultipart(t *testing.T) {
	t.Parallel()

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	if err := writer.WriteField("csrf_token", "csrf-token"); err != nil {
		t.Fatalf("WriteField returned error: %v", err)
	}
	part, err := writer.CreateFormFile("media_images", "photo.jpg")
	if err != nil {
		t.Fatalf("CreateFormFile returned error: %v", err)
	}
	if _, err = part.Write([]byte{0xff, 0xd8, 0xff, 0xdb}); err != nil {
		t.Fatalf("Write returned error: %v", err)
	}
	if err = writer.Close(); err != nil {
		t.Fatalf("Close returned error: %v", err)
	}

	request := httptest.NewRequest(http.MethodPost, "/admin/attractions/id/media", body)
	request.Header.Set("Content-Type", writer.FormDataContentType())

	if err = parseRequestForm(request); err != nil {
		t.Fatalf("parseRequestForm returned error: %v", err)
	}
	if got := request.Form.Get("csrf_token"); got != "csrf-token" {
		t.Fatalf("csrf_token = %q, want csrf-token", got)
	}
	if request.MultipartForm == nil || len(request.MultipartForm.File["media_images"]) != 1 {
		t.Fatalf("multipart files were not parsed: %#v", request.MultipartForm)
	}
}

func TestParseAttractionImagesReadsMultipleCarouselImages(t *testing.T) {
	t.Parallel()

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	for _, fileName := range []string{"first.jpg", "second.webp"} {
		part, err := writer.CreateFormFile("media_images", fileName)
		if err != nil {
			t.Fatalf("CreateFormFile returned error: %v", err)
		}
		content := []byte{0xff, 0xd8, 0xff, 0xdb}
		if fileName == "second.webp" {
			content = []byte("RIFFxxxxWEBPVP8 ")
		}
		if _, err = part.Write(content); err != nil {
			t.Fatalf("Write returned error: %v", err)
		}
	}
	if err := writer.Close(); err != nil {
		t.Fatalf("Close returned error: %v", err)
	}

	request := httptest.NewRequest(http.MethodPost, "/admin/attractions/id/media", body)
	request.Header.Set("Content-Type", writer.FormDataContentType())

	images, err := parseAttractionImages(request)
	if err != nil {
		t.Fatalf("parseAttractionImages returned error: %v", err)
	}
	if len(images) != 2 {
		t.Fatalf("images count = %d, want 2", len(images))
	}
	if images[0].FileName != "first.jpg" || images[1].FileName != "second.webp" {
		t.Fatalf("images = %#v, want ordered uploaded files", images)
	}
}

func TestParseAttractionFormDerivesCoordinatesFromMapURL(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("default_locale", "ru")
	values.Set("title_ru", "Большое Алматинское озеро")
	values.Set("description_ru", "Горное озеро рядом с Алматы.")
	values.Set("country_code", "KZ")
	values.Set("city_id", "almaty")
	values.Set("category", "NATURE")
	values.Set("status", "PUBLISHED")
	values.Set("location_source_url", "https://www.openstreetmap.org/?mlat=43.24353420852949&mlon=76.90412855566406#map=16/43.24353420852949/76.90412855566406")
	request := httptest.NewRequest(http.MethodPost, "/admin/attractions", strings.NewReader(values.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	input, _, err := parseAttractionForm(request)
	if err != nil {
		t.Fatalf("parseAttractionForm returned error: %v", err)
	}
	if input.Latitude == nil || input.Longitude == nil {
		t.Fatalf("coordinates were not derived from location_source_url: %#v", input)
	}
	if *input.Latitude != 43.24353420852949 || *input.Longitude != 76.90412855566406 {
		t.Fatalf("coordinates = %v,%v, want OSM mlat/mlon values", *input.Latitude, *input.Longitude)
	}
}

func TestParseCityLinkValuesReadsCheckboxValues(t *testing.T) {
	t.Parallel()

	got := parseCityLinkValues([]string{"KZ:almaty", "KZ:taldykorgan", "KZ:almaty"}, "KZ")
	if len(got) != 2 {
		t.Fatalf("city links count = %d, want 2: %#v", len(got), got)
	}
	if got[0].CountryCode != "KZ" || got[0].CityID != "almaty" ||
		got[1].CountryCode != "KZ" || got[1].CityID != "taldykorgan" {
		t.Fatalf("city links = %#v, want normalized ordered values", got)
	}
}

func TestParseCityLinkValuesDropsCitiesOutsideSelectedCountry(t *testing.T) {
	t.Parallel()

	got := parseCityLinkValues([]string{"VN:hanoi", "KZ:almaty", "ha-long"}, "VN")
	if len(got) != 2 {
		t.Fatalf("city links count = %d, want only VN links: %#v", len(got), got)
	}
	if got[0].CountryCode != "VN" || got[0].CityID != "hanoi" ||
		got[1].CountryCode != "VN" || got[1].CityID != "ha-long" {
		t.Fatalf("city links = %#v, want foreign explicit countries removed and fallback country applied", got)
	}
}

func TestAttractionCityLinkOptionsHideCitiesOutsideAttractionCountry(t *testing.T) {
	t.Parallel()

	options := attractionCityLinkOptions(nil, "VN")
	var foundVietnamCity bool
	for _, option := range options {
		if option.CountryCode == "VN" && option.CityID == "hanoi" {
			foundVietnamCity = true
			if option.Hidden {
				t.Fatalf("Vietnam city option should be visible for VN attraction: %#v", option)
			}
			continue
		}
		if option.CountryCode != "VN" && !option.Hidden {
			t.Fatalf("foreign city option should be hidden for VN attraction: %#v", option)
		}
	}
	if !foundVietnamCity {
		t.Fatalf("city options = %#v, want visible Hanoi option", options)
	}
}

func TestAttractionListQueryPreservesCountryAndCityFilters(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("q", " lake ")
	values.Set("country", " kz ")
	values.Set("city", " Almaty ")
	values.Set("page", "3")

	got := attractionListQuery(values)

	if got.Search != "lake" || got.CountryCode != "KZ" || got.CityID != "almaty" || got.Page != 3 {
		t.Fatalf("filters = %#v, want normalized search/country/city/page", got)
	}
	if got.Query != "city=almaty&country=KZ&q=lake" {
		t.Fatalf("query = %q, want city=almaty&country=KZ&q=lake", got.Query)
	}
}

func TestAttractionListQueryIgnoresCityWithoutCountry(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("city", "almaty")

	got := attractionListQuery(values)

	if got.CountryCode != "" || got.CityID != "" || got.Query != "" {
		t.Fatalf("filters = %#v, want city cleared until country is selected", got)
	}
}

func TestAttractionListQueryDefaultsInvalidPage(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("page", "-2")

	got := attractionListQuery(values)

	if got.Page != 1 {
		t.Fatalf("page = %d, want 1", got.Page)
	}
}

func TestAttractionReferenceOptionsIncludeRussianFederationCities(t *testing.T) {
	t.Parallel()

	countries := attractionCountryOptions("RU")
	var foundRussia bool
	for _, option := range countries {
		if option.Value == "RU" && option.Selected {
			foundRussia = true
			break
		}
	}
	if !foundRussia {
		t.Fatalf("country options = %#v, want selected RU option", countries)
	}

	cities := attractionCityOptions("moscow")
	var foundMoscow bool
	for _, option := range cities {
		if option.Value == "moscow" && option.CountryCode == "RU" && option.Selected {
			foundMoscow = true
			break
		}
	}
	if !foundMoscow {
		t.Fatalf("city options = %#v, want selected RU Moscow option", cities)
	}

	if got := attractionCityText(localeRU, "RU", "saint-petersburg"); got != "Санкт-Петербург, Российская Федерация" {
		t.Fatalf("city text = %q, want localized Russian Federation city", got)
	}
}

func TestAttractionReferenceOptionsIncludeVietnamCitiesAndCurrency(t *testing.T) {
	t.Parallel()

	countries := attractionCountryOptions("VN")
	var foundVietnam bool
	for _, option := range countries {
		if option.Value == "VN" && option.Selected {
			foundVietnam = true
			break
		}
	}
	if !foundVietnam {
		t.Fatalf("country options = %#v, want selected VN option", countries)
	}

	cities := attractionCityOptions("ho-chi-minh-city")
	var foundHoChiMinhCity bool
	for _, option := range cities {
		if option.Value == "ho-chi-minh-city" && option.CountryCode == "VN" && option.Selected {
			foundHoChiMinhCity = true
			break
		}
	}
	if !foundHoChiMinhCity {
		t.Fatalf("city options = %#v, want selected VN Ho Chi Minh City option", cities)
	}

	if got := attractionCityText(localeRU, "VN", "da-nang"); got != "Дананг, Вьетнам" {
		t.Fatalf("city text = %q, want localized Vietnam city", got)
	}
	if got := attractionCityText(localeRU, "VN", "phan-thiet"); got != "Фантхьет, Вьетнам" {
		t.Fatalf("city text = %q, want localized Phan Thiet city", got)
	}
	if got := attractionCurrencyText(localeRU, "VND"); got != "Вьетнамский донг" {
		t.Fatalf("currency text = %q, want localized Vietnamese dong", got)
	}
}

func TestAttractionCategoryOptionsIncludeMarket(t *testing.T) {
	t.Parallel()

	options := attractionCategoryOptions("MARKET")
	var foundMarket bool
	for _, option := range options {
		if option.Value == "MARKET" {
			foundMarket = true
			if !option.Selected {
				t.Fatalf("MARKET category option should be selected: %#v", option)
			}
			if option.LabelKey != "attraction.category.MARKET" {
				t.Fatalf("MARKET option label key = %q, want attraction.category.MARKET", option.LabelKey)
			}
		}
	}
	if !foundMarket {
		t.Fatalf("category options = %#v, want MARKET option", options)
	}
	if got := attractionCategoryText(localeRU, "MARKET"); got != "Рынок" {
		t.Fatalf("Russian MARKET label = %q, want Рынок", got)
	}
	if got := attractionCategoryText(localeEN, "MARKET"); got != "Market" {
		t.Fatalf("English MARKET label = %q, want Market", got)
	}
}

func TestAttractionCategoryTextLocalizesAttractionServiceCategories(t *testing.T) {
	t.Parallel()

	cases := map[string]string{
		"NATURE":        "Природа",
		"ARCHITECTURE":  "Архитектура",
		"MUSEUM":        "Музей",
		"BEACH":         "Пляж",
		"PARK":          "Парк",
		"TEMPLE":        "Храм",
		"ENTERTAINMENT": "Развлечения",
		"FOOD":          "Еда",
		"SHOPPING":      "Шопинг",
		"OTHER":         "Другое",
	}
	for category, want := range cases {
		if got := attractionCategoryText(localeRU, category); got != want {
			t.Fatalf("attractionCategoryText(%q) = %q, want %q", category, got, want)
		}
	}
}

func TestAttractionCategoryOptionsMatchAttractionServiceCategories(t *testing.T) {
	t.Parallel()

	got := attractionCategoryOptions("MUSEUM")
	values := make(map[string]bool, len(got))
	for _, item := range got {
		values[item.Value] = true
		if item.Value == "MUSEUM" && !item.Selected {
			t.Fatal("MUSEUM option should preserve selected state")
		}
	}
	for _, want := range []string{"NATURE", "ARCHITECTURE", "MUSEUM", "BEACH", "PARK", "TEMPLE", "ENTERTAINMENT", "FOOD", "SHOPPING", "OTHER"} {
		if !values[want] {
			t.Fatalf("category options missing %q: %#v", want, got)
		}
	}
	for _, unexpected := range []string{"CULTURE", "HISTORY", "RELIGION", "SPORT"} {
		if values[unexpected] {
			t.Fatalf("category options include unsupported attraction-service category %q: %#v", unexpected, got)
		}
	}
}
