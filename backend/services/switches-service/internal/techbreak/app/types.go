package app

import "time"

type TechBreakUpsertRequest struct {
	DomainCode       string
	Name             string
	ActionStartDate  time.Time
	ActionEndDate    *time.Time
	ExcludeEmails    []string
	ExcludeNicknames []string
	ScopeCodes       []string
}

type TechBreakSearchRequest struct {
	Page            int
	Size            int
	OrderBy         string
	Direction       string
	DomainCode      string
	ActionStartDate *time.Time
	ActionEndDate   *time.Time
	Search          string
}

type TechBreakCheckRequest struct {
	DomainCode string
	Nickname   string
	Email      string
	ScopeCodes []string
}

type TechBreakResponse struct {
	ID               int64            `json:"id"`
	CreatedAt        time.Time        `json:"createdAt"`
	CreatedBy        string           `json:"createdBy"`
	UpdatedAt        *time.Time       `json:"updatedAt,omitempty"`
	UpdatedBy        string           `json:"updatedBy,omitempty"`
	Name             string           `json:"name"`
	Enabled          bool             `json:"enabled"`
	ActionStartDate  time.Time        `json:"actionStartDate"`
	ActionEndDate    *time.Time       `json:"actionEndDate,omitempty"`
	ExcludeEmails    []string         `json:"excludeEmails"`
	ExcludeNicknames []string         `json:"excludeNicknames"`
	Scopes           []TechBreakScope `json:"scopes"`
}

type TechBreakDetail struct {
	ID               int64
	CreatedAt        time.Time
	CreatedBy        string
	UpdatedAt        *time.Time
	UpdatedBy        string
	Name             string
	Enabled          bool
	ActionStartDate  time.Time
	ActionEndDate    *time.Time
	ExcludeEmails    []string
	ExcludeNicknames []string
	ScopeCodes       []string
	Scopes           []TechBreakScope
}

func (d TechBreakDetail) ToResponse() TechBreakResponse {
	return TechBreakResponse{
		ID:               d.ID,
		CreatedAt:        d.CreatedAt,
		CreatedBy:        d.CreatedBy,
		UpdatedAt:        d.UpdatedAt,
		UpdatedBy:        d.UpdatedBy,
		Name:             d.Name,
		Enabled:          d.Enabled,
		ActionStartDate:  d.ActionStartDate,
		ActionEndDate:    d.ActionEndDate,
		ExcludeEmails:    d.ExcludeEmails,
		ExcludeNicknames: d.ExcludeNicknames,
		Scopes:           d.Scopes,
	}
}

type TechBreakScope struct {
	ID         int64      `json:"id"`
	DomainCode string     `json:"-"`
	CreatedAt  time.Time  `json:"createdAt"`
	CreatedBy  string     `json:"createdBy"`
	UpdatedAt  *time.Time `json:"updatedAt,omitempty"`
	UpdatedBy  string     `json:"updatedBy,omitempty"`
	Code       string     `json:"code"`
	Name       string     `json:"name"`
}

type TechBreakScopeCreateRequest struct {
	DomainCode string
	Code       string
	Name       string
}

type TechBreakScopeUpdateRequest struct {
	DomainCode string
	Name       string
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
	Content       []T   `json:"content"`
	Page          int   `json:"page"`
	Size          int   `json:"size"`
	TotalElements int64 `json:"totalElements"`
	TotalPages    int   `json:"totalPages"`
}
