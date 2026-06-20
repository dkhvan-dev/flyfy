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

	request := httptest.NewRequest(http.MethodPost, "/admin/places/id/media", body)
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

func TestParsePlaceImagesReadsMultipleCarouselImages(t *testing.T) {
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

	request := httptest.NewRequest(http.MethodPost, "/admin/places/id/media", body)
	request.Header.Set("Content-Type", writer.FormDataContentType())

	images, err := parsePlaceImages(request)
	if err != nil {
		t.Fatalf("parsePlaceImages returned error: %v", err)
	}
	if len(images) != 2 {
		t.Fatalf("images count = %d, want 2", len(images))
	}
	if images[0].FileName != "first.jpg" || images[1].FileName != "second.webp" {
		t.Fatalf("images = %#v, want ordered uploaded files", images)
	}
}

func TestParsePlaceFormDerivesCoordinatesFromMapURL(t *testing.T) {
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
	request := httptest.NewRequest(http.MethodPost, "/admin/places", strings.NewReader(values.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	input, _, err := parsePlaceForm(request)
	if err != nil {
		t.Fatalf("parsePlaceForm returned error: %v", err)
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

func TestPlaceCityLinkOptionsHideCitiesOutsidePlaceCountry(t *testing.T) {
	t.Parallel()

	options := placeCityLinkOptions(nil, "VN")
	var foundVietnamCity bool
	for _, option := range options {
		if option.CountryCode == "VN" && option.CityID == "hanoi" {
			foundVietnamCity = true
			if option.Hidden {
				t.Fatalf("Vietnam city option should be visible for VN place: %#v", option)
			}
			continue
		}
		if option.CountryCode != "VN" && !option.Hidden {
			t.Fatalf("foreign city option should be hidden for VN place: %#v", option)
		}
	}
	if !foundVietnamCity {
		t.Fatalf("city options = %#v, want visible Hanoi option", options)
	}
}

func TestPlaceListQueryPreservesCountryAndCityFilters(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("q", " lake ")
	values.Set("country", " kz ")
	values.Set("city", " Almaty ")
	values.Set("page", "3")

	got := placeListQuery(values)

	if got.Search != "lake" || got.CountryCode != "KZ" || got.CityID != "almaty" || got.Page != 3 {
		t.Fatalf("filters = %#v, want normalized search/country/city/page", got)
	}
	if got.Query != "city=almaty&country=KZ&q=lake" {
		t.Fatalf("query = %q, want city=almaty&country=KZ&q=lake", got.Query)
	}
}

func TestPlaceListQueryIgnoresCityWithoutCountry(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("city", "almaty")

	got := placeListQuery(values)

	if got.CountryCode != "" || got.CityID != "" || got.Query != "" {
		t.Fatalf("filters = %#v, want city cleared until country is selected", got)
	}
}

func TestPlaceListQueryPreservesIndonesiaBaliRegionalFilter(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("country", "ID")
	values.Set("city", "bali")

	got := placeListQuery(values)

	if got.CountryCode != "ID" || got.CityID != "bali" || got.Query != "city=bali&country=ID" {
		t.Fatalf("filters = %#v, want Bali regional filter preserved for Indonesia", got)
	}
}

func TestPlaceListQueryDefaultsInvalidPage(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("page", "-2")

	got := placeListQuery(values)

	if got.Page != 1 {
		t.Fatalf("page = %d, want 1", got.Page)
	}
}

func TestPlaceReferenceOptionsIncludeRussiaCities(t *testing.T) {
	t.Parallel()

	countries := placeCountryOptions("RU")
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

	cities := placeCityOptions("moscow")
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

	if got := placeCityText(localeRU, "RU", "saint-petersburg"); got != "Санкт-Петербург, Россия" {
		t.Fatalf("city text = %q, want localized Russia city", got)
	}
}

func TestPlaceReferenceOptionsIncludeVietnamCitiesAndCurrency(t *testing.T) {
	t.Parallel()

	countries := placeCountryOptions("VN")
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

	cities := placeCityOptions("ho-chi-minh-city")
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

	if got := placeCityText(localeRU, "VN", "da-nang"); got != "Дананг, Вьетнам" {
		t.Fatalf("city text = %q, want localized Vietnam city", got)
	}
	if got := placeCityText(localeRU, "VN", "phan-thiet"); got != "Фантхьет, Вьетнам" {
		t.Fatalf("city text = %q, want localized Phan Thiet city", got)
	}
	if got := placeCurrencyText(localeRU, "VND"); got != "Вьетнамский донг" {
		t.Fatalf("currency text = %q, want localized Vietnamese dong", got)
	}
}

func TestPlaceReferenceOptionsIncludeThailandCitiesAndCurrency(t *testing.T) {
	t.Parallel()

	countries := placeCountryOptions("TH")
	var foundThailand bool
	for _, option := range countries {
		if option.Value == "TH" && option.Selected {
			foundThailand = true
			break
		}
	}
	if !foundThailand {
		t.Fatalf("country options = %#v, want selected TH option", countries)
	}

	cities := placeCityOptions("koh-samui")
	var foundKohSamui bool
	for _, option := range cities {
		if option.Value == "koh-samui" && option.CountryCode == "TH" && option.Selected {
			foundKohSamui = true
			break
		}
	}
	if !foundKohSamui {
		t.Fatalf("city options = %#v, want selected TH Koh Samui option", cities)
	}

	if got := placeCityText(localeRU, "TH", "phang-nga"); got != "Пхангнга, Таиланд" {
		t.Fatalf("city text = %q, want localized Phang Nga city", got)
	}
	if got := placeCurrencyText(localeRU, "THB"); got != "Тайский бат" {
		t.Fatalf("currency text = %q, want localized Thai baht", got)
	}
}

func TestPlaceReferenceOptionsIncludeMaldivesCitiesAndCurrency(t *testing.T) {
	t.Parallel()

	countries := placeCountryOptions("MV")
	var foundMaldives bool
	for _, option := range countries {
		if option.Value == "MV" && option.Selected {
			foundMaldives = true
			break
		}
	}
	if !foundMaldives {
		t.Fatalf("country options = %#v, want selected MV option", countries)
	}

	cities := placeCityOptions("maafushi")
	var foundMaafushi bool
	for _, option := range cities {
		if option.Value == "maafushi" && option.CountryCode == "MV" && option.Selected {
			foundMaafushi = true
			break
		}
	}
	if !foundMaafushi {
		t.Fatalf("city options = %#v, want selected MV Maafushi option", cities)
	}

	if got := placeCityText(localeRU, "MV", "hulhumale"); got != "Хулхумале, Мальдивы" {
		t.Fatalf("city text = %q, want localized Hulhumale city", got)
	}
	if got := placeCurrencyText(localeRU, "MVR"); got != "Мальдивская руфия" {
		t.Fatalf("currency text = %q, want localized Maldivian rufiyaa", got)
	}
}

func TestPlaceReferenceOptionsIncludeGeorgiaCitiesAndCurrency(t *testing.T) {
	t.Parallel()

	countries := placeCountryOptions("GE")
	var foundGeorgia bool
	for _, option := range countries {
		if option.Value == "GE" && option.Selected {
			foundGeorgia = true
			break
		}
	}
	if !foundGeorgia {
		t.Fatalf("country options = %#v, want selected GE option", countries)
	}

	cities := placeCityOptions("stepantsminda")
	var foundKazbegi bool
	for _, option := range cities {
		if option.Value == "stepantsminda" && option.CountryCode == "GE" && option.Selected {
			foundKazbegi = true
			break
		}
	}
	if !foundKazbegi {
		t.Fatalf("city options = %#v, want selected GE Stepantsminda/Kazbegi option", cities)
	}

	if got := placeCityText(localeRU, "GE", "stepantsminda"); got != "Степанцминда (Казбеги), Грузия" {
		t.Fatalf("city text = %q, want localized Stepantsminda/Kazbegi city", got)
	}
	if got := placeCurrencyText(localeRU, "GEL"); got != "Грузинский лари" {
		t.Fatalf("currency text = %q, want localized Georgian lari", got)
	}
}

func TestPlaceReferenceOptionsIncludeArmeniaCitiesAndCurrency(t *testing.T) {
	t.Parallel()

	countries := placeCountryOptions("AM")
	var foundArmenia bool
	for _, option := range countries {
		if option.Value == "AM" && option.Selected {
			foundArmenia = true
			break
		}
	}
	if !foundArmenia {
		t.Fatalf("country options = %#v, want selected AM option", countries)
	}

	cities := placeCityOptions("vagharshapat")
	var foundEchmiadzin bool
	for _, option := range cities {
		if option.Value == "vagharshapat" && option.CountryCode == "AM" && option.Selected {
			foundEchmiadzin = true
			break
		}
	}
	if !foundEchmiadzin {
		t.Fatalf("city options = %#v, want selected AM Vagharshapat/Echmiadzin option", cities)
	}

	if got := placeCityText(localeRU, "AM", "vagharshapat"); got != "Вагаршапат (Эчмиадзин), Армения" {
		t.Fatalf("city text = %q, want localized Vagharshapat/Echmiadzin city", got)
	}
	if got := placeCurrencyText(localeRU, "AMD"); got != "Армянский драм" {
		t.Fatalf("currency text = %q, want localized Armenian dram", got)
	}
}

func TestPlaceCategoryOptionsIncludeMarket(t *testing.T) {
	t.Parallel()

	options := placeCategoryOptions("MARKET")
	var foundMarket bool
	for _, option := range options {
		if option.Value == "MARKET" {
			foundMarket = true
			if !option.Selected {
				t.Fatalf("MARKET category option should be selected: %#v", option)
			}
			if option.LabelKey != "place.category.MARKET" {
				t.Fatalf("MARKET option label key = %q, want place.category.MARKET", option.LabelKey)
			}
		}
	}
	if !foundMarket {
		t.Fatalf("category options = %#v, want MARKET option", options)
	}
	if got := placeCategoryText(localeRU, "MARKET"); got != "Рынок" {
		t.Fatalf("Russian MARKET label = %q, want Рынок", got)
	}
	if got := placeCategoryText(localeEN, "MARKET"); got != "Market" {
		t.Fatalf("English MARKET label = %q, want Market", got)
	}
}

func TestPlaceCategoryTextLocalizesPlaceServiceCategories(t *testing.T) {
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
		if got := placeCategoryText(localeRU, category); got != want {
			t.Fatalf("placeCategoryText(%q) = %q, want %q", category, got, want)
		}
	}
}

func TestPlaceCategoryOptionsMatchPlaceServiceCategories(t *testing.T) {
	t.Parallel()

	got := placeCategoryOptions("MUSEUM")
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
			t.Fatalf("category options include unsupported place-service category %q: %#v", unexpected, got)
		}
	}
}
