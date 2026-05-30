package dto

import "kz/inflap/backend/services/reference-service/internal/domain/model"

type CountryResponse struct {
	Code         string `json:"code"`
	Code3        string `json:"code3"`
	Numeric      string `json:"numeric"`
	CurrencyCode string `json:"currencyCode"`
	PhoneCode    string `json:"phoneCode"`
	Name         string `json:"name"`
	Capital      string `json:"capital"`
}

type CityResponse struct {
	ID          string `json:"id"`
	CountryCode string `json:"countryCode"`
	Name        string `json:"name"`
	Population  int    `json:"population"`
}

type CurrencyResponse struct {
	Code     string `json:"code"`
	Numeric  string `json:"numeric"`
	Decimals int    `json:"decimals"`
	Symbol   string `json:"symbol"`
	Name     string `json:"name"`
}

type TimezoneResponse struct {
	ID        string `json:"id"`
	UTCOffset string `json:"utcOffset"`
	Name      string `json:"name"`
}

type CountryDetailResponse struct {
	Country  CountryResponse  `json:"country"`
	Currency CurrencyResponse `json:"currency"`
	Cities   []CityResponse   `json:"cities"`
}

func MapCountry(c model.Country, lang string) CountryResponse {
	return CountryResponse{
		Code:         c.Code,
		Code3:        c.Code3,
		Numeric:      c.Numeric,
		CurrencyCode: c.CurrencyCode,
		PhoneCode:    c.PhoneCode,
		Name:         c.Name.Get(lang),
		Capital:      c.Capital.Get(lang),
	}
}

func MapCountries(countries []model.Country, lang string) []CountryResponse {
	out := make([]CountryResponse, len(countries))
	for i, c := range countries {
		out[i] = MapCountry(c, lang)
	}
	return out
}

func MapCity(c model.City, lang string) CityResponse {
	return CityResponse{
		ID:          c.ID,
		CountryCode: c.CountryCode,
		Name:        c.Name.Get(lang),
		Population:  c.Population,
	}
}

func MapCities(cities []model.City, lang string) []CityResponse {
	out := make([]CityResponse, len(cities))
	for i, c := range cities {
		out[i] = MapCity(c, lang)
	}
	return out
}

func MapCurrency(c model.Currency, lang string) CurrencyResponse {
	return CurrencyResponse{
		Code:     c.Code,
		Numeric:  c.Numeric,
		Decimals: c.Decimals,
		Symbol:   c.Symbol,
		Name:     c.Name.Get(lang),
	}
}

func MapCurrencies(currencies []model.Currency, lang string) []CurrencyResponse {
	out := make([]CurrencyResponse, len(currencies))
	for i, c := range currencies {
		out[i] = MapCurrency(c, lang)
	}
	return out
}

func MapTimezone(t model.Timezone, lang string) TimezoneResponse {
	return TimezoneResponse{
		ID:        t.ID,
		UTCOffset: t.UTCOffset,
		Name:      t.Name.Get(lang),
	}
}

func MapTimezones(timezones []model.Timezone, lang string) []TimezoneResponse {
	out := make([]TimezoneResponse, len(timezones))
	for i, t := range timezones {
		out[i] = MapTimezone(t, lang)
	}
	return out
}
