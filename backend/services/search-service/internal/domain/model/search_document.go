package model

import "time"

type SearchDocument struct {
	Domain               Domain
	EntityID             string
	EntityVersion        int64
	Locale               string
	Title                map[string]string
	Subtitle             map[string]string
	Description          map[string]string
	Tags                 []string
	CategoryCodes        []string
	CityID               string
	CountryCode          string
	Latitude             *float64
	Longitude            *float64
	PriceMin             *float64
	PriceMax             *float64
	Currency             string
	Rating               *float64
	ReviewCount          int
	PopularityScore      float64
	FreshnessScore       float64
	TrustScore           float64
	AvailabilityStatus   string
	AvailableFrom        *time.Time
	AvailableTo          *time.Time
	Visibility           string
	ModerationStatus     string
	OwnerUserID          string
	PreviewImageFileID   string
	DeepLink             string
	SearchText           string
	SearchTextNormalized string
	SearchVariants       []string
}
