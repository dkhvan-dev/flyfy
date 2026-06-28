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

func TestParsePlaceFormLeavesVisitPlanningDetailsForDedicatedPage(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("default_locale", "ru")
	values.Set("title_ru", "Чарынский каньон")
	values.Set("description_ru", "Каньон.")
	values.Set("country_code", "KZ")
	values.Set("city_id", "almaty")
	values.Set("category", "NATURE")
	values.Set("status", "PUBLISHED")
	values.Set("visit_price_note", "Билет и экосбор отдельно")
	values.Set("visit_time_on_site_min", "90")
	values.Set("visit_time_on_site_max", "150")
	values.Set("visit_time_on_site_note", "Без трека к реке")
	values.Set("visit_car_travel_time_min", "180")
	values.Set("visit_car_travel_time_max", "240")
	values.Set("visit_car_travel_time_note", "От Алматы")
	values.Set("visit_road_condition", "PAVED")
	values.Set("visit_fee_detail_title_0", "Вход")
	values.Set("visit_fee_detail_description_0", "Базовый билет")
	values.Set("visit_fee_detail_amount_0", "1000")
	values.Set("visit_fee_detail_currency_0", "KZT")
	values.Set("visit_fee_detail_unit_0", "PERSON")
	values.Set("visit_fee_detail_approximate_0", "true")
	values.Set("visit_fee_item_type_0", "ENTRANCE")
	values.Set("visit_fee_item_title_0", "Вход в парк")
	values.Set("visit_fee_item_min_amount_0", "1000")
	values.Set("visit_fee_item_max_amount_0", "1000")
	values.Set("visit_fee_item_currency_0", "KZT")
	values.Set("visit_fee_item_unit_0", "PERSON")
	values.Set("visit_fee_item_required_0", "true")
	values.Set("visit_fee_item_approximate_0", "true")
	values.Set("visit_fee_item_note_0", "Цена может меняться")
	values.Set("visit_access_transport_type_0", "CAR")
	values.Set("visit_access_min_minutes_0", "180")
	values.Set("visit_access_max_minutes_0", "240")
	values.Set("visit_access_route_hint_0", "Трасса на Кеген")
	values.Set("visit_access_road_condition_0", "PAVED")
	values.Set("visit_access_parking_note_0", "Парковка у входа")
	values.Set("visit_practical_note_type_0", "WEATHER")
	values.Set("visit_practical_title_0", "Жара")
	values.Set("visit_practical_body_0", "Летом мало тени")
	values.Set("visit_practical_priority_0", "IMPORTANT")
	values.Set("visit_recommended_item_type_0", "WATER")
	values.Set("visit_recommended_title_0", "Вода")
	values.Set("visit_recommended_note_0", "Минимум 1 литр")
	values.Set("visit_recommended_importance_0", "REQUIRED")
	request := httptest.NewRequest(http.MethodPost, "/admin/places", strings.NewReader(values.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	input, _, err := parsePlaceForm(request)
	if err != nil {
		t.Fatalf("parsePlaceForm returned error: %v", err)
	}
	if input.VisitInfo != nil {
		t.Fatalf("VisitInfo = %+v, want dedicated visit-info page to own these fields", input.VisitInfo)
	}
}

func TestParsePlaceVisitInfoFormReadsAllLocales(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("visit_opening_hours_ru", "Ежедневно 09:00-18:00")
	values.Set("visit_opening_hours_en", "Daily 09:00-18:00")
	values.Set("visit_opening_hours_kk", "Күн сайын 09:00-18:00")
	values.Set("visit_price_note_ru", "Билет и экосбор отдельно")
	values.Set("visit_price_note_en", "Ticket and eco fee are paid separately")
	values.Set("visit_price_note_kk", "Билет пен экоалым бөлек төленеді")
	values.Set("visit_time_on_site_min", "90")
	values.Set("visit_time_on_site_max", "150")
	values.Set("visit_time_on_site_note_ru", "Без трека к реке")
	values.Set("visit_time_on_site_note_en", "Without the river trail")
	values.Set("visit_time_on_site_note_kk", "Өзен соқпағынсыз")
	values.Set("visit_fee_detail_title_ru_0", "Вход")
	values.Set("visit_fee_detail_title_en_0", "Admission")
	values.Set("visit_fee_detail_title_kk_0", "Кіру")
	values.Set("visit_fee_detail_description_ru_0", "Базовый билет")
	values.Set("visit_fee_detail_description_en_0", "Base ticket")
	values.Set("visit_fee_detail_description_kk_0", "Негізгі билет")
	values.Set("visit_fee_detail_amount_0", "1000")
	values.Set("visit_fee_detail_currency_0", "KZT")
	values.Set("visit_fee_detail_unit_0", "PERSON")
	values.Set("visit_access_transport_type_0", "CAR")
	values.Set("visit_access_route_hint_ru_0", "Трасса на Кеген")
	values.Set("visit_access_route_hint_en_0", "Kegen highway")
	values.Set("visit_access_route_hint_kk_0", "Кеген тас жолы")
	values.Set("visit_practical_note_type_0", "WEATHER")
	values.Set("visit_practical_title_ru_0", "Жара")
	values.Set("visit_practical_title_en_0", "Heat")
	values.Set("visit_practical_title_kk_0", "Ыстық")
	values.Set("visit_practical_body_ru_0", "Летом мало тени")
	values.Set("visit_practical_body_en_0", "There is little shade in summer")
	values.Set("visit_practical_body_kk_0", "Жазда көлеңке аз")
	values.Set("visit_recommended_item_type_0", "WATER")
	values.Set("visit_recommended_title_ru_0", "Вода")
	values.Set("visit_recommended_title_en_0", "Water")
	values.Set("visit_recommended_title_kk_0", "Су")
	values.Set("visit_recommended_note_ru_0", "Минимум 1 литр")
	values.Set("visit_recommended_note_en_0", "At least 1 liter")
	values.Set("visit_recommended_note_kk_0", "Кемінде 1 литр")
	request := httptest.NewRequest(http.MethodPost, "/admin/places/id/visit-info", strings.NewReader(values.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	info, err := parsePlaceVisitInfoForm(request)
	if err != nil {
		t.Fatalf("parsePlaceVisitInfoForm returned error: %v", err)
	}
	if got := info.OpeningHoursLocales["en"]; got != "Daily 09:00-18:00" {
		t.Fatalf("OpeningHoursLocales.en = %q", got)
	}
	if got := info.PriceNoteLocales["kk"]; got != "Билет пен экоалым бөлек төленеді" {
		t.Fatalf("PriceNoteLocales.kk = %q", got)
	}
	if info.TimeOnSite == nil || info.TimeOnSite.NoteLocales["kk"] != "Өзен соқпағынсыз" {
		t.Fatalf("TimeOnSite localized note = %#v", info.TimeOnSite)
	}
	if len(info.FeeDetails) != 1 || info.FeeDetails[0].TitleLocales["en"] != "Admission" || info.FeeDetails[0].DescriptionLocales["kk"] != "Негізгі билет" {
		t.Fatalf("FeeDetails localized text = %#v", info.FeeDetails)
	}
	if len(info.AccessOptions) != 1 || info.AccessOptions[0].RouteHintLocales["kk"] != "Кеген тас жолы" {
		t.Fatalf("AccessOptions localized text = %#v", info.AccessOptions)
	}
	if len(info.PracticalNotes) != 1 || info.PracticalNotes[0].TitleLocales["en"] != "Heat" || info.PracticalNotes[0].BodyLocales["kk"] != "Жазда көлеңке аз" {
		t.Fatalf("PracticalNotes localized text = %#v", info.PracticalNotes)
	}
	if len(info.RecommendedItems) != 1 || info.RecommendedItems[0].TitleLocales["kk"] != "Су" || info.RecommendedItems[0].NoteLocales["en"] != "At least 1 liter" {
		t.Fatalf("RecommendedItems localized text = %#v", info.RecommendedItems)
	}
}

func TestParsePlaceVisitInfoFormIgnoresCurrencyOnlyRows(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("visit_fee_detail_currency_0", "USD")
	values.Set("visit_fee_item_currency_0", "EUR")
	request := httptest.NewRequest(http.MethodPost, "/admin/places/id/visit-info", strings.NewReader(values.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	info, err := parsePlaceVisitInfoForm(request)
	if err != nil {
		t.Fatalf("parsePlaceVisitInfoForm returned error: %v", err)
	}
	if len(info.FeeDetails) != 0 {
		t.Fatalf("FeeDetails = %#v, want currency-only rows ignored", info.FeeDetails)
	}
	if len(info.FeeItems) != 0 {
		t.Fatalf("FeeItems = %#v, want currency-only rows ignored", info.FeeItems)
	}
}

func TestParsePlaceVisitInfoFormReadsDynamicallyAddedRows(t *testing.T) {
	t.Parallel()

	values := url.Values{}
	values.Set("visit_fee_detail_title_en_8", "Late access")
	values.Set("visit_fee_detail_amount_8", "25")
	values.Set("visit_fee_detail_unit_8", "PERSON")
	values.Set("visit_fee_item_type_8", "PARKING")
	values.Set("visit_fee_item_title_ru_8", "Парковка")
	values.Set("visit_fee_item_min_amount_8", "10")
	values.Set("visit_fee_item_unit_8", "CAR")
	values.Set("visit_access_transport_type_8", "TAXI")
	values.Set("visit_access_route_hint_en_8", "Taxi drop-off point")
	values.Set("visit_access_min_minutes_8", "15")
	values.Set("visit_practical_note_type_8", "PAYMENT")
	values.Set("visit_practical_title_en_8", "Cash desk")
	values.Set("visit_practical_body_en_8", "Keep the receipt")
	values.Set("visit_practical_priority_8", "INFO")
	values.Set("visit_recommended_item_type_8", "CASH")
	values.Set("visit_recommended_title_kk_8", "Қолма-қол ақша")
	values.Set("visit_recommended_importance_8", "RECOMMENDED")
	request := httptest.NewRequest(http.MethodPost, "/admin/places/id/visit-info", strings.NewReader(values.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	info, err := parsePlaceVisitInfoForm(request)
	if err != nil {
		t.Fatalf("parsePlaceVisitInfoForm returned error: %v", err)
	}
	if len(info.FeeDetails) != 1 || info.FeeDetails[0].TitleLocales["en"] != "Late access" {
		t.Fatalf("FeeDetails = %#v, want dynamically added index 8 row", info.FeeDetails)
	}
	if len(info.FeeItems) != 1 || info.FeeItems[0].Type != "PARKING" || info.FeeItems[0].TitleLocales["ru"] != "Парковка" {
		t.Fatalf("FeeItems = %#v, want dynamically added index 8 row", info.FeeItems)
	}
	if len(info.AccessOptions) != 1 || info.AccessOptions[0].TransportType != "TAXI" || info.AccessOptions[0].RouteHintLocales["en"] != "Taxi drop-off point" {
		t.Fatalf("AccessOptions = %#v, want dynamically added index 8 row", info.AccessOptions)
	}
	if len(info.PracticalNotes) != 1 || info.PracticalNotes[0].BodyLocales["en"] != "Keep the receipt" {
		t.Fatalf("PracticalNotes = %#v, want dynamically added index 8 row", info.PracticalNotes)
	}
	if len(info.RecommendedItems) != 1 || info.RecommendedItems[0].ItemType != "CASH" || info.RecommendedItems[0].TitleLocales["kk"] != "Қолма-қол ақша" {
		t.Fatalf("RecommendedItems = %#v, want dynamically added index 8 row", info.RecommendedItems)
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
