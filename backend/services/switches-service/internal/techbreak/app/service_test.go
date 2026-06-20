package app

import (
	"context"
	"testing"
	"time"
)

func TestTechBreakServiceCreateComputesEnabledCachesAndValidatesScopes(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	repo := &fakeTechBreakRepo{
		now: now,
		scopes: map[string][]TechBreakScope{
			"CORE": {{ID: 1, Code: "EMAIL_OTP", Name: "Email OTP"}},
		},
	}
	cache := NewMemoryCache[TechBreakResponse]()
	service := NewTechBreakService(repo, repo, cache, fixedClock(now))

	result, err := service.Create(context.Background(), TechBreakUpsertRequest{
		DomainCode:      "CORE",
		Name:            "Core outage",
		ActionStartDate: now.Add(-time.Minute),
		ScopeCodes:      []string{"EMAIL_OTP"},
	}, "tester")

	if err != nil {
		t.Fatalf("create tech break: %v", err)
	}
	if !result.Enabled {
		t.Fatal("expected current tech break to be enabled")
	}
	cached, ok := cache.Get("techBreak_core_1")
	if !ok || cached.ID != result.ID {
		t.Fatalf("expected cached tech break, got %#v / %v", cached, ok)
	}
}

func TestTechBreakServiceCreateRejectsUnknownScope(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	repo := &fakeTechBreakRepo{
		now: now,
		scopes: map[string][]TechBreakScope{
			"CORE": {{ID: 1, Code: "EMAIL_OTP", Name: "Email OTP"}},
		},
	}
	service := NewTechBreakService(repo, repo, NewMemoryCache[TechBreakResponse](), fixedClock(now))

	_, err := service.Create(context.Background(), TechBreakUpsertRequest{
		DomainCode:      "CORE",
		Name:            "Core outage",
		ActionStartDate: now,
		ScopeCodes:      []string{"PHONE_OTP"},
	}, "tester")

	if err == nil || err.Error() != "Scope не найден, либо не принадлежит вашему домену/продукту" {
		t.Fatalf("expected unknown scope error, got %v", err)
	}
}

func TestTechBreakServiceHasActiveDelegatesToRepositoryPredicate(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	repo := &fakeTechBreakRepo{now: now, hasActive: true}
	service := NewTechBreakService(repo, repo, NewMemoryCache[TechBreakResponse](), fixedClock(now))

	active, err := service.HasActive(context.Background(), TechBreakCheckRequest{
		DomainCode: "activity",
		Email:      "user@example.com",
		ScopeCodes: []string{"modify_activity"},
	})

	if err != nil {
		t.Fatalf("has active tech break: %v", err)
	}
	if !active {
		t.Fatal("expected repository predicate result to be returned")
	}
	if repo.hasActiveCalls != 1 {
		t.Fatalf("expected one repository predicate call, got %d", repo.hasActiveCalls)
	}
	if got := repo.lastCheck.ScopeCodes; len(got) != 1 || got[0] != "MODIFY_ACTIVITY" {
		t.Fatalf("expected scope codes to be normalized before repository call, got %#v", got)
	}
}

func TestTechBreakServiceClearCacheEvictsHitAndMiss(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	repo := &fakeTechBreakRepo{now: now}
	cache := NewMemoryCacheWithClock[TechBreakResponse](time.Minute, time.Minute, fixedClock(now))
	service := NewTechBreakService(repo, repo, cache, fixedClock(now))
	cache.Put("techBreak_core_1", TechBreakResponse{ID: 1})
	cache.PutMissing("techBreak_core_2")

	service.ClearCache()

	if _, ok := cache.Get("techBreak_core_1"); ok {
		t.Fatal("expected cached tech break hit to be evicted")
	}
	if cache.IsMissing("techBreak_core_2") {
		t.Fatal("expected cached tech break miss to be evicted")
	}
}

func TestTechBreakServiceSwitchDueUsesAdvisoryLock(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	repo := &fakeTechBreakRepo{now: now, lockAcquired: false}
	service := NewTechBreakService(repo, repo, NewMemoryCache[TechBreakResponse](), fixedClock(now))

	if err := service.SwitchDue(context.Background()); err != nil {
		t.Fatalf("switch due with busy lock: %v", err)
	}
	if repo.switchCalls != 0 {
		t.Fatalf("scheduler must skip work when advisory lock is busy, got %d calls", repo.switchCalls)
	}

	repo.lockAcquired = true
	if err := service.SwitchDue(context.Background()); err != nil {
		t.Fatalf("switch due with acquired lock: %v", err)
	}
	if repo.switchCalls != 1 {
		t.Fatalf("scheduler must run exactly once after lock acquisition, got %d calls", repo.switchCalls)
	}
	if repo.unlockCalls != 1 {
		t.Fatalf("scheduler must release advisory lock, got %d unlock calls", repo.unlockCalls)
	}
}

type fakeTechBreakRepo struct {
	now            time.Time
	nextID         int64
	breaks         map[string]TechBreakDetail
	scopes         map[string][]TechBreakScope
	hasActive      bool
	hasActiveCalls int
	lastCheck      TechBreakCheckRequest
	lockAcquired   bool
	switchCalls    int
	unlockCalls    int
}

func (r *fakeTechBreakRepo) ensure() {
	if r.breaks == nil {
		r.breaks = make(map[string]TechBreakDetail)
	}
	if r.nextID == 0 {
		r.nextID = 1
	}
}

func (r *fakeTechBreakRepo) Create(_ context.Context, req TechBreakUpsertRequest, scopes []TechBreakScope, enabled bool, actor string) (TechBreakResponse, error) {
	r.ensure()
	id := r.nextID
	r.nextID++
	detail := TechBreakDetail{
		ID:               id,
		CreatedAt:        r.now,
		CreatedBy:        actor,
		Name:             req.Name,
		Enabled:          enabled,
		ActionStartDate:  req.ActionStartDate,
		ActionEndDate:    req.ActionEndDate,
		ExcludeEmails:    req.ExcludeEmails,
		ExcludeNicknames: req.ExcludeNicknames,
		ScopeCodes:       req.ScopeCodes,
		Scopes:           scopes,
	}
	r.breaks[req.DomainCode+":1"] = detail
	return detail.ToResponse(), nil
}

func (r *fakeTechBreakRepo) Update(context.Context, int64, TechBreakUpsertRequest, []TechBreakScope, bool, string) (*TechBreakResponse, error) {
	return nil, nil
}

func (r *fakeTechBreakRepo) GetByID(_ context.Context, id int64, domainCode string, _ []TechBreakScope) (*TechBreakResponse, error) {
	r.ensure()
	if detail, ok := r.breaks[domainCode+":1"]; ok && detail.ID == id {
		resp := detail.ToResponse()
		return &resp, nil
	}
	return nil, nil
}

func (r *fakeTechBreakRepo) FindAll(context.Context, TechBreakSearchRequest, []TechBreakScope) (Page[TechBreakResponse], error) {
	return Page[TechBreakResponse]{}, nil
}

func (r *fakeTechBreakRepo) Delete(context.Context, int64, string) (bool, error) {
	return true, nil
}

func (r *fakeTechBreakRepo) ExistsByName(context.Context, string, string, *int64) (bool, error) {
	return false, nil
}

func (r *fakeTechBreakRepo) HasActive(_ context.Context, request TechBreakCheckRequest) (bool, error) {
	r.hasActiveCalls++
	r.lastCheck = request
	return r.hasActive, nil
}

func (r *fakeTechBreakRepo) ExistsActiveByScope(context.Context, string, string) (bool, error) {
	return false, nil
}

func (r *fakeTechBreakRepo) DeleteAllByScope(context.Context, string, string) error {
	return nil
}

func (r *fakeTechBreakRepo) FindScopesByCodes(_ context.Context, domainCode string, codes []string) ([]TechBreakScope, error) {
	all := r.scopes[domainCode]
	if len(codes) == 0 {
		return all, nil
	}
	codeSet := make(map[string]struct{}, len(codes))
	for _, code := range codes {
		codeSet[code] = struct{}{}
	}
	result := make([]TechBreakScope, 0, len(codes))
	for _, scope := range all {
		if _, ok := codeSet[scope.Code]; ok {
			result = append(result, scope)
		}
	}
	return result, nil
}

func (r *fakeTechBreakRepo) DomainHasScopes(_ context.Context, domainCode string) (bool, error) {
	return len(r.scopes[domainCode]) > 0, nil
}

func (r *fakeTechBreakRepo) CreateScope(_ context.Context, request TechBreakScopeCreateRequest, actor string) (TechBreakScope, error) {
	return TechBreakScope{ID: 1, DomainCode: request.DomainCode, Code: request.Code, Name: request.Name, CreatedBy: actor}, nil
}

func (r *fakeTechBreakRepo) UpdateScope(_ context.Context, id int64, request TechBreakScopeUpdateRequest, actor string) (TechBreakScope, error) {
	return TechBreakScope{ID: id, DomainCode: request.DomainCode, Name: request.Name, UpdatedBy: actor}, nil
}

func (r *fakeTechBreakRepo) GetScopeByID(_ context.Context, id int64, domainCode string) (*TechBreakScope, error) {
	for _, scope := range r.scopes[domainCode] {
		if scope.ID == id {
			return &scope, nil
		}
	}
	return nil, nil
}

func (r *fakeTechBreakRepo) GetScopeByIDAnyDomain(_ context.Context, id int64) (*TechBreakScope, error) {
	for domainCode, scopes := range r.scopes {
		for _, scope := range scopes {
			if scope.ID == id {
				scope.DomainCode = domainCode
				return &scope, nil
			}
		}
	}
	return nil, nil
}

func (r *fakeTechBreakRepo) FindScopes(_ context.Context, domainCode string) ([]TechBreakScope, error) {
	return r.scopes[domainCode], nil
}

func (r *fakeTechBreakRepo) DeleteScope(context.Context, int64) error {
	return nil
}

func (r *fakeTechBreakRepo) ScopeExistsByCode(_ context.Context, domainCode string, code string) (bool, error) {
	for _, scope := range r.scopes[domainCode] {
		if scope.Code == code {
			return true, nil
		}
	}
	return false, nil
}

func (r *fakeTechBreakRepo) ListDomainCodes(context.Context) ([]string, error) {
	return []string{"ACTIVITY"}, nil
}

func (r *fakeTechBreakRepo) SwitchDueTechBreaks(context.Context, string, time.Time) ([]TechBreakResponse, error) {
	r.switchCalls++
	return nil, nil
}

func (r *fakeTechBreakRepo) TryAdvisoryLock(context.Context, int64) (bool, error) {
	return r.lockAcquired, nil
}

func (r *fakeTechBreakRepo) UnlockAdvisory(context.Context, int64) error {
	r.unlockCalls++
	return nil
}

func fixedClock(now time.Time) Clock {
	return ClockFunc(func() time.Time { return now })
}

var _ TechBreakRepository = (*fakeTechBreakRepo)(nil)
var _ TechBreakScopeRepository = (*fakeTechBreakRepo)(nil)
var _ TechBreakSchedulerRepository = (*fakeTechBreakRepo)(nil)
var _ AdvisoryLocker = (*fakeTechBreakRepo)(nil)
