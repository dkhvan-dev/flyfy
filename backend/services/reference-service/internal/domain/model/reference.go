package model

type LocalizedName struct {
	En string `json:"en"`
	Ru string `json:"ru"`
	Kk string `json:"kk"`
}

func (l LocalizedName) Get(lang string) string {
	switch lang {
	case "ru":
		return l.Ru
	case "kk":
		return l.Kk
	default:
		return l.En
	}
}

type Country struct {
	Code         string        `json:"code"`
	Code3        string        `json:"code3"`
	Numeric      string        `json:"numeric"`
	CurrencyCode string        `json:"currencyCode"`
	PhoneCode    string        `json:"phoneCode"`
	Name         LocalizedName `json:"name"`
	Capital      LocalizedName `json:"capital"`
}

type City struct {
	ID          string        `json:"id"`
	CountryCode string        `json:"countryCode"`
	Name        LocalizedName `json:"name"`
	Population  int           `json:"population"`
}

type Currency struct {
	Code     string        `json:"code"`
	Numeric  string        `json:"numeric"`
	Decimals int           `json:"decimals"`
	Symbol   string        `json:"symbol"`
	Name     LocalizedName `json:"name"`
}

type Timezone struct {
	ID        string        `json:"id"`
	UTCOffset string        `json:"utcOffset"`
	Name      LocalizedName `json:"name"`
}
