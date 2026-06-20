package enum

type PlaceCategory string

const (
	CategoryNature        PlaceCategory = "NATURE"
	CategoryArchitecture  PlaceCategory = "ARCHITECTURE"
	CategoryMuseum        PlaceCategory = "MUSEUM"
	CategoryBeach         PlaceCategory = "BEACH"
	CategoryPark          PlaceCategory = "PARK"
	CategoryTemple        PlaceCategory = "TEMPLE"
	CategoryEntertainment PlaceCategory = "ENTERTAINMENT"
	CategoryFood          PlaceCategory = "FOOD"
	CategoryMarket        PlaceCategory = "MARKET"
	CategoryShopping      PlaceCategory = "SHOPPING"
	CategoryOther         PlaceCategory = "OTHER"
)

var validCategories = map[PlaceCategory]bool{
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

func (c PlaceCategory) IsValid() bool {
	return validCategories[c]
}

func (c PlaceCategory) String() string {
	return string(c)
}
