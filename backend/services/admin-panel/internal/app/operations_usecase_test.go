package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestOperationsUseCaseMergesDomainsFromFeatureFlagsAndTechBreaks(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 6, 19, 18, 0, 0, 0, time.UTC)
	flags := &operationsFeatureFlagClientStub{
		domains: model.OperationDomainPage{
			Content: []model.OperationDomain{
				{
					FeatureFlagServiceID: 10,
					Code:                 "CORE",
					Description:          "Core team",
					CreatedBy:            "admin-a",
					CreatedAt:            now.Add(-2 * time.Hour),
					UpdatedAt:            operationsTimePtr(now.Add(-time.Hour)),
					FeatureFlagGroups:    []string{"authorization", "onboarding"},
				},
				{
					FeatureFlagServiceID: 11,
					Code:                 "LOYALTY",
					Description:          "Loyalty",
					CreatedBy:            "admin-b",
					CreatedAt:            now.Add(-30 * time.Minute),
				},
			},
			TotalElements: 2,
		},
	}
	breaks := &operationsTechBreakClientStub{
		domains: model.OperationDomainPage{
			Content: []model.OperationDomain{
				{
					TechBreakServiceID:         20,
					Code:                       "CORE",
					Description:                "Core team",
					CreatedBy:                  "admin-c",
					CreatedAt:                  now.Add(-90 * time.Minute),
					FeatureFlagGroups:          []string{"onboarding", "payments"},
					TechBreakScopeDescriptions: []string{"mobile clients"},
				},
				{
					TechBreakServiceID: 21,
					Code:               "SUPPORT",
					Description:        "Support",
					CreatedBy:          "admin-d",
					CreatedAt:          now.Add(-10 * time.Minute),
				},
			},
			TotalElements: 2,
		},
	}
	useCase := NewOperationsUseCase(flags, breaks, nil)

	page, err := useCase.ListDomains(context.Background(), operationsSuperAdmin(), OperationsDomainListInput{Size: 50})
	if err != nil {
		t.Fatalf("ListDomains() error = %v", err)
	}
	if len(page.Content) != 3 {
		t.Fatalf("merged domain count = %d, want 3: %#v", len(page.Content), page.Content)
	}
	core := page.Content[0]
	if core.Code != "CORE" || core.FeatureFlagServiceID != 10 || core.TechBreakServiceID != 20 {
		t.Fatalf("CORE merge = %#v, want both service ids on a single row", core)
	}
	if got := core.FeatureFlagGroups; len(got) != 3 || got[0] != "authorization" || got[1] != "onboarding" || got[2] != "payments" {
		t.Fatalf("merged feature flag groups = %#v, want unique stable groups", got)
	}
	if page.TotalElements != 3 {
		t.Fatalf("TotalElements = %d, want merged total 3", page.TotalElements)
	}
}

func TestOperationsUseCaseRequiresSuperAdmin(t *testing.T) {
	t.Parallel()

	useCase := NewOperationsUseCase(&operationsFeatureFlagClientStub{}, &operationsTechBreakClientStub{}, nil)
	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "moderator@inflap.local",
		DisplayName: "Moderator",
		Status:      enum.StaffStatusActive,
		Roles:       []enum.StaffRole{enum.StaffRoleAdmin},
	}

	_, err := useCase.ListDomains(context.Background(), actor, OperationsDomainListInput{Size: 20})
	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("ListDomains() error = %v, want ErrPermissionDenied", err)
	}
}

func TestOperationsUseCasePassesFeatureFlagTypeToHistory(t *testing.T) {
	t.Parallel()

	domain := model.OperationDomain{Code: "ONBOARDING", Description: "Onboarding"}
	flag := model.OperationFeatureFlag{
		DomainCode: "ONBOARDING",
		Code:       "SKIP_SENDING_EMAIL_OTP",
		Type:       "ARRAY_STRING",
	}
	flags := &operationsFeatureFlagClientStub{
		domain: &domain,
		flag:   &flag,
	}
	breaks := &operationsTechBreakClientStub{domain: &domain}
	useCase := NewOperationsUseCase(flags, breaks, nil)

	if _, err := useCase.GetFeatureFlagHistory(
		context.Background(),
		operationsSuperAdmin(),
		"ONBOARDING",
		"SKIP_SENDING_EMAIL_OTP",
		model.OperationFeatureFlagHistoryFilter{Size: 20},
	); err != nil {
		t.Fatalf("GetFeatureFlagHistory() error = %v", err)
	}
	if got := flags.lastHistoryFilter.Type; got != "ARRAY_STRING" {
		t.Fatalf("history filter type = %q, want ARRAY_STRING", got)
	}
}

func TestOperationsUseCaseFeatureFlagDetailDoesNotLoadHistory(t *testing.T) {
	t.Parallel()

	domain := model.OperationDomain{Code: "CORE", Description: "Core"}
	flag := model.OperationFeatureFlag{
		DomainCode: "CORE",
		Code:       "NEED_CHECK_AUTH_PASSWORD",
		Type:       "TOGGLE",
	}
	flags := &operationsFeatureFlagClientStub{
		domain: &domain,
		flag:   &flag,
	}
	breaks := &operationsTechBreakClientStub{domain: &domain}
	useCase := NewOperationsUseCase(flags, breaks, nil)

	page, err := useCase.GetFeatureFlagDetail(
		context.Background(),
		operationsSuperAdmin(),
		"CORE",
		"NEED_CHECK_AUTH_PASSWORD",
	)
	if err != nil {
		t.Fatalf("GetFeatureFlagDetail() error = %v", err)
	}
	if page.Flag.Code != flag.Code {
		t.Fatalf("detail flag code = %q, want %q", page.Flag.Code, flag.Code)
	}
	if flags.historyCalls != 0 {
		t.Fatalf("GetFeatureFlagDetail loaded history %d times, want 0", flags.historyCalls)
	}
}

func operationsSuperAdmin() *model.StaffUser {
	return &model.StaffUser{
		ID:          uuid.New(),
		Email:       "superadmin@inflap.local",
		DisplayName: "Super Admin",
		Status:      enum.StaffStatusActive,
		Roles:       []enum.StaffRole{enum.StaffRoleSuperAdmin},
	}
}

type operationsFeatureFlagClientStub struct {
	domains model.OperationDomainPage
	flags   model.OperationPage[model.OperationFeatureFlag]
	history model.OperationPage[model.OperationFeatureFlagHistory]
	domain  *model.OperationDomain
	flag    *model.OperationFeatureFlag

	lastHistoryFilter model.OperationFeatureFlagHistoryFilter
	historyCalls      int
}

func (c *operationsFeatureFlagClientStub) ListDomains(context.Context, model.OperationDomainFilter) (model.OperationDomainPage, error) {
	return c.domains, nil
}

func (c *operationsFeatureFlagClientStub) FindDomain(context.Context, string) (*model.OperationDomain, error) {
	return c.domain, nil
}

func (c *operationsFeatureFlagClientStub) UpsertDomain(context.Context, model.OperationDomainInput) (model.OperationDomain, error) {
	return model.OperationDomain{}, nil
}

func (c *operationsFeatureFlagClientStub) ListFeatureFlags(context.Context, model.OperationFeatureFlagFilter) (model.OperationPage[model.OperationFeatureFlag], error) {
	return c.flags, nil
}

func (c *operationsFeatureFlagClientStub) GetFeatureFlag(context.Context, string, string) (model.OperationFeatureFlag, error) {
	if c.flag != nil {
		return *c.flag, nil
	}
	return model.OperationFeatureFlag{}, nil
}

func (c *operationsFeatureFlagClientStub) UpsertFeatureFlag(context.Context, model.OperationFeatureFlagInput) (model.OperationFeatureFlag, error) {
	return model.OperationFeatureFlag{}, nil
}

func (c *operationsFeatureFlagClientStub) ArchiveFeatureFlag(context.Context, string, string) error {
	return nil
}

func (c *operationsFeatureFlagClientStub) RecoverFeatureFlag(context.Context, string, string) (model.OperationFeatureFlag, error) {
	return model.OperationFeatureFlag{}, nil
}

func (c *operationsFeatureFlagClientStub) ListFeatureFlagHistory(_ context.Context, filter model.OperationFeatureFlagHistoryFilter) (model.OperationPage[model.OperationFeatureFlagHistory], error) {
	c.historyCalls++
	c.lastHistoryFilter = filter
	return c.history, nil
}

type operationsTechBreakClientStub struct {
	domains model.OperationDomainPage
	breaks  model.OperationPage[model.OperationTechBreak]
	scopes  []model.OperationTechBreakScope
	domain  *model.OperationDomain
	tech    *model.OperationTechBreak
	scope   *model.OperationTechBreakScope
}

func (c *operationsTechBreakClientStub) ListDomains(context.Context, model.OperationDomainFilter) (model.OperationDomainPage, error) {
	return c.domains, nil
}

func (c *operationsTechBreakClientStub) FindDomain(context.Context, string) (*model.OperationDomain, error) {
	return c.domain, nil
}

func (c *operationsTechBreakClientStub) UpsertDomain(context.Context, model.OperationDomainInput) (model.OperationDomain, error) {
	return model.OperationDomain{}, nil
}

func (c *operationsTechBreakClientStub) ListTechBreaks(context.Context, model.OperationTechBreakFilter) (model.OperationPage[model.OperationTechBreak], error) {
	return c.breaks, nil
}

func (c *operationsTechBreakClientStub) GetTechBreak(context.Context, int64, string) (model.OperationTechBreak, error) {
	if c.tech != nil {
		return *c.tech, nil
	}
	return model.OperationTechBreak{}, nil
}

func (c *operationsTechBreakClientStub) UpsertTechBreak(context.Context, model.OperationTechBreakInput) (model.OperationTechBreak, error) {
	return model.OperationTechBreak{}, nil
}

func (c *operationsTechBreakClientStub) ArchiveTechBreak(context.Context, int64, string) error {
	return nil
}

func (c *operationsTechBreakClientStub) ListScopes(context.Context, string) ([]model.OperationTechBreakScope, error) {
	return c.scopes, nil
}

func (c *operationsTechBreakClientStub) GetScope(context.Context, int64, string) (model.OperationTechBreakScope, error) {
	if c.scope != nil {
		return *c.scope, nil
	}
	return model.OperationTechBreakScope{}, nil
}

func (c *operationsTechBreakClientStub) UpsertScope(context.Context, model.OperationTechBreakScopeInput) (model.OperationTechBreakScope, error) {
	return model.OperationTechBreakScope{}, nil
}

func (c *operationsTechBreakClientStub) ArchiveScope(context.Context, int64, string) error {
	return nil
}

func operationsTimePtr(value time.Time) *time.Time {
	return &value
}
