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
