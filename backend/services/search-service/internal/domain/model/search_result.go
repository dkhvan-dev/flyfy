package model

type SearchResult struct {
	Domain   Domain
	EntityID string
	Title    string
	Subtitle string
	DeepLink string
	Score    float64
}
