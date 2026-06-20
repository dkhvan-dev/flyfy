package model

import "time"

type OperationPage[T any] struct {
	Content       []T
	Page          int
	Size          int
	TotalElements int64
	TotalPages    int
	NextCursor    string
}

type OperationDomainPage struct {
	Content       []OperationDomain
	Page          int
	Size          int
	TotalElements int64
	TotalPages    int
}

type OperationDomain struct {
	FeatureFlagServiceID       int64
	TechBreakServiceID         int64
	Code                       string
	Description                string
	CreatedAt                  time.Time
	CreatedBy                  string
	UpdatedAt                  *time.Time
	UpdatedBy                  string
	FeatureFlagGroups          []string
	TechBreakScopeDescriptions []string
}

type OperationDomainFilter struct {
	Page      int
	Size      int
	OrderBy   string
	Direction string
	Search    string
}

type OperationDomainInput struct {
	FeatureFlagServiceID int64
	TechBreakServiceID   int64
	Code                 string
	Description          string
	Actor                string
	RequestID            string
}

type OperationFeatureFlag struct {
	DomainCode      string
	Code            string
	Name            string
	Group           string
	Type            string
	Enabled         bool
	ActionStartDate time.Time
	ActionEndDate   *time.Time
	InArchive       bool
	Value           []any
	CreatedAt       time.Time
	CreatedBy       string
	UpdatedAt       *time.Time
	UpdatedBy       string
}

type OperationFeatureFlagHistory struct {
	UpdatedAt       time.Time
	UpdatedBy       string
	Name            string
	Group           string
	Enabled         bool
	ActionStartDate time.Time
	ActionEndDate   *time.Time
	InArchive       bool
	Value           []any
}

type OperationFeatureFlagFilter struct {
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

type OperationFeatureFlagHistoryFilter struct {
	Page       int
	Size       int
	Cursor     string
	OrderBy    string
	Direction  string
	DomainCode string
	Code       string
	Type       string
}

type OperationFeatureFlagInput struct {
	ExistingCode    string
	DomainCode      string
	Code            string
	Name            string
	Group           string
	Type            string
	Enabled         bool
	ActionStartDate time.Time
	ActionEndDate   *time.Time
	Value           []any
	Actor           string
	RequestID       string
}

type OperationTechBreak struct {
	ID               int64
	DomainCode       string
	Name             string
	Enabled          bool
	ActionStartDate  time.Time
	ActionEndDate    *time.Time
	ExcludeEmails    []string
	ExcludeNicknames []string
	ScopeCodes       []string
	Scopes           []OperationTechBreakScope
	CreatedAt        time.Time
	CreatedBy        string
	UpdatedAt        *time.Time
	UpdatedBy        string
}

type OperationTechBreakFilter struct {
	Page            int
	Size            int
	OrderBy         string
	Direction       string
	DomainCode      string
	ActionStartDate *time.Time
	ActionEndDate   *time.Time
	Search          string
}

type OperationTechBreakInput struct {
	ID               int64
	DomainCode       string
	Name             string
	ActionStartDate  time.Time
	ActionEndDate    *time.Time
	ExcludeEmails    []string
	ExcludeNicknames []string
	ScopeCodes       []string
	Actor            string
	RequestID        string
}

type OperationTechBreakScope struct {
	ID         int64
	DomainCode string
	Code       string
	Name       string
	CreatedAt  time.Time
	CreatedBy  string
	UpdatedAt  *time.Time
	UpdatedBy  string
}

type OperationTechBreakScopeInput struct {
	ID         int64
	DomainCode string
	Code       string
	Name       string
	Actor      string
	RequestID  string
}
