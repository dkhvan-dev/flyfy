package enum

type AttractionCategory string

const (
	CategoryNature        AttractionCategory = "NATURE"
	CategoryArchitecture  AttractionCategory = "ARCHITECTURE"
	CategoryMuseum        AttractionCategory = "MUSEUM"
	CategoryBeach         AttractionCategory = "BEACH"
	CategoryPark          AttractionCategory = "PARK"
	CategoryTemple        AttractionCategory = "TEMPLE"
	CategoryEntertainment AttractionCategory = "ENTERTAINMENT"
	CategoryFood          AttractionCategory = "FOOD"
	CategoryMarket        AttractionCategory = "MARKET"
	CategoryShopping      AttractionCategory = "SHOPPING"
	CategoryOther         AttractionCategory = "OTHER"
)

var validCategories = map[AttractionCategory]bool{
	CategoryNature:        true,
	CategoryArchitecture:  true,
	CategoryMuseum:        true,
	CategoryBeach:         true,
	CategoryPark:          true,
	CategoryTemple:        true,
	CategoryEntertainment: true,
	CategoryFood:          true,
	CategoryMarket:        true,
	CategoryShopping:      true,
	CategoryOther:         true,
}

func (c AttractionCategory) IsValid() bool {
	return validCategories[c]
}

func (c AttractionCategory) String() string {
	return string(c)
}
