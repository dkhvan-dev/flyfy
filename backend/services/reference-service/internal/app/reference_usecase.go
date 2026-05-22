package app

import (
	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/reference-service/internal/domain/model"
)

const defaultSearchLimit = 20

type ReferenceUseCase struct {
	repo *repository.MemoryRepository
}

func NewReferenceUseCase(repo *repository.MemoryRepository) *ReferenceUseCase {
	return &ReferenceUseCase{repo: repo}
}

// Countries

func (uc *ReferenceUseCase) ListCountries() []model.Country {
	return uc.repo.AllCountries()
}

func (uc *ReferenceUseCase) GetCountry(code string) *model.Country {
	return uc.repo.CountryByCode(code)
}

func (uc *ReferenceUseCase) SearchCountries(query string, limit int) []model.Country {
	if limit <= 0 {
		limit = defaultSearchLimit
	}
	return uc.repo.SearchCountries(query, limit)
}

// Cities

func (uc *ReferenceUseCase) ListCities(countryCode string) []model.City {
	if countryCode != "" {
		return uc.repo.CitiesByCountry(countryCode)
	}
	return uc.repo.AllCities()
}

func (uc *ReferenceUseCase) GetCity(id string) *model.City {
	return uc.repo.CityByID(id)
}

func (uc *ReferenceUseCase) SearchCities(query string, countryCode string, limit int) []model.City {
	if limit <= 0 {
		limit = defaultSearchLimit
	}
	return uc.repo.SearchCities(query, countryCode, limit)
}

// Currencies

func (uc *ReferenceUseCase) ListCurrencies() []model.Currency {
	return uc.repo.AllCurrencies()
}

func (uc *ReferenceUseCase) GetCurrency(code string) *model.Currency {
	return uc.repo.CurrencyByCode(code)
}

func (uc *ReferenceUseCase) GetCurrencyByCountry(countryCode string) *model.Currency {
	return uc.repo.CurrencyByCountry(countryCode)
}

func (uc *ReferenceUseCase) SearchCurrencies(query string, limit int) []model.Currency {
	if limit <= 0 {
		limit = defaultSearchLimit
	}
	return uc.repo.SearchCurrencies(query, limit)
}

// Timezones

func (uc *ReferenceUseCase) ListTimezones() []model.Timezone {
	return uc.repo.AllTimezones()
}
