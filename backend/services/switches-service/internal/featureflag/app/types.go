package app

import "time"

type FeatureFlagType string

const (
	FeatureFlagTypeToggle       FeatureFlagType = "TOGGLE"
	FeatureFlagTypeArrayString  FeatureFlagType = "ARRAY_STRING"
	FeatureFlagTypeArrayInteger FeatureFlagType = "ARRAY_INTEGER"
)

type FeatureFlagCreateRequest struct {
	DomainCode      string
	Code            string
	Name            string
	Group           string
	Type            FeatureFlagType
	ActionStartDate time.Time
	ActionEndDate   *time.Time
	Enabled         bool
	Value           []any
}

type FeatureFlagUpdateRequest struct {
	DomainCode      string
	Name            string
	Group           string
	Type            FeatureFlagType
	ActionStartDate time.Time
	ActionEndDate   *time.Time
	Enabled         bool
	Value           []any
}

type FeatureFlagSearchRequest struct {
	Page            int
	Size            int
	OrderBy         string
	Direction       string
	DomainCode      string
	Group           string
	ActionStartDate *time.Time
	ActionEndDate   *time.Time
	Search          string
	InArchive       bool
}

type FeatureFlagDetailResponse struct {
	Code            string          `json:"code"`
	CreatedAt       time.Time       `json:"createdAt"`
	CreatedBy       string          `json:"createdBy"`
	UpdatedAt       *time.Time      `json:"updatedAt,omitempty"`
	UpdatedBy       string          `json:"updatedBy,omitempty"`
	Name            string          `json:"name"`
	Group           string          `json:"group"`
	Type            FeatureFlagType `json:"type"`
	Enabled         bool            `json:"enabled"`
	ActionStartDate time.Time       `json:"actionStartDate"`
	ActionEndDate   *time.Time      `json:"actionEndDate,omitempty"`
	InArchive       bool            `json:"inArchive"`
	Value           []any           `json:"value"`
}

type FeatureFlagInternalDetailResponse struct {
	Enabled bool            `json:"enabled"`
	Type    FeatureFlagType `json:"type"`
	Value   []any           `json:"value"`
}

type FeatureFlagHistoryCreateRequest struct {
	DomainCode      string
	Code            string
	Name            string
	Group           string
	Type            FeatureFlagType
	Enabled         bool
	ActionStartDate time.Time
	ActionEndDate   *time.Time
	Value           []any
	IsDeleted       bool
}

type FeatureFlagHistorySearchRequest struct {
	Page            int
	Size            int
	Cursor          string
	OrderBy         string
	Direction       string
	Code            string
	DomainCode      string
	FeatureFlagType FeatureFlagType
}

type FeatureFlagHistoryResponse struct {
	ID              int64           `json:"-"`
	UpdatedAt       time.Time       `json:"updatedAt"`
	UpdatedBy       string          `json:"updatedBy"`
	Name            string          `json:"name"`
	Group           string          `json:"group"`
	Type            FeatureFlagType `json:"type"`
	Enabled         bool            `json:"enabled"`
	ActionStartDate time.Time       `json:"actionStartDate"`
	ActionEndDate   *time.Time      `json:"actionEndDate,omitempty"`
	InArchive       bool            `json:"inArchive"`
	Value           []any           `json:"value"`
}

type DomainCreateRequest struct {
	Code        string
	Description string
}

type DomainUpdateRequest struct {
	Code        string
	Description string
}

type DomainSearchRequest struct {
	Page      int
	Size      int
	OrderBy   string
	Direction string
	Search    string
}

type DomainResponse struct {
	ID                int64      `json:"id"`
	CreatedAt         time.Time  `json:"createdAt"`
	CreatedBy         string     `json:"createdBy"`
	UpdatedAt         *time.Time `json:"updatedAt,omitempty"`
	UpdatedBy         string     `json:"updatedBy,omitempty"`
	Code              string     `json:"code"`
	Description       string     `json:"description"`
	FeatureFlagGroups []string   `json:"featureFlagGroups"`
}

type Page[T any] struct {
	Content       []T    `json:"content"`
	Page          int    `json:"page"`
	Size          int    `json:"size"`
	TotalElements int64  `json:"totalElements"`
	TotalPages    int    `json:"totalPages"`
	NextCursor    string `json:"nextCursor,omitempty"`
}
