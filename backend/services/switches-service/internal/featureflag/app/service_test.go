package app

import (
	"context"
	"errors"
	"testing"
	"time"
)

func TestFeatureFlagServiceCreatePersistsHistoryAndCachesDetail(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	repo := &fakeFeatureFlagRepo{now: now, flags: make(map[string]FeatureFlagDetailResponse)}
	cache := NewMemoryCache[FeatureFlagDetailResponse]()
	service := NewFeatureFlagService(repo, repo, cache, fixedClock(now))

	result, err := service.Create(context.Background(), FeatureFlagCreateRequest{
		DomainCode:      "ONBOARDING",
		Code:            "SKIP_EMAIL_OTP",
		Name:            "Skip email OTP",
		Group:           "General",
		Type:            FeatureFlagTypeArrayString,
		Enabled:         true,
		ActionStartDate: now,
		Value:           []any{"test@test.kz"},
	}, "tester")

	if err != nil {
		t.Fatalf("create feature flag: %v", err)
	}
	if result.Code != "SKIP_EMAIL_OTP" {
		t.Fatalf("unexpected code: %s", result.Code)
	}
	if repo.historyCreated != 1 {
		t.Fatalf("expected history row, got %d", repo.historyCreated)
	}
	if repo.lastHistory.Type != FeatureFlagTypeArrayString {
		t.Fatalf("history type = %q, want %q", repo.lastHistory.Type, FeatureFlagTypeArrayString)
	}
	cached, ok := cache.Get("ff_skip_email_otp_onboarding")
	if !ok || cached.Code != result.Code {
		t.Fatalf("expected cached result, got %#v / %v", cached, ok)
	}
}

func TestFeatureFlagServiceCreateDerivesToggleValueFromEnabled(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	repo := &fakeFeatureFlagRepo{now: now, flags: make(map[string]FeatureFlagDetailResponse)}
	service := NewFeatureFlagService(repo, repo, NewMemoryCache[FeatureFlagDetailResponse](), fixedClock(now))

	result, err := service.Create(context.Background(), FeatureFlagCreateRequest{
		DomainCode:      "ONBOARDING",
		Code:            "NEED_CHECK_PASSWORD",
		Name:            "Need check password",
		Group:           "General",
		Type:            FeatureFlagTypeToggle,
		Enabled:         true,
		ActionStartDate: now,
		Value:           []any{false},
	}, "tester")

	if err != nil {
		t.Fatalf("create toggle feature flag: %v", err)
	}
	if len(result.Value) != 1 || result.Value[0] != true {
		t.Fatalf("toggle value = %#v, want [true]", result.Value)
	}
	if len(repo.lastHistory.Value) != 1 || repo.lastHistory.Value[0] != true {
		t.Fatalf("history toggle value = %#v, want [true]", repo.lastHistory.Value)
	}
}

func TestFeatureFlagServiceDeleteArchivesAndEvictsCache(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	repo := &fakeFeatureFlagRepo{now: now, flags: make(map[string]FeatureFlagDetailResponse)}
	cache := NewMemoryCache[FeatureFlagDetailResponse]()
	service := NewFeatureFlagService(repo, repo, cache, fixedClock(now))
	cache.Put("ff_skip_email_otp_onboarding", FeatureFlagDetailResponse{Code: "SKIP_EMAIL_OTP"})
	repo.flags["ONBOARDING:SKIP_EMAIL_OTP"] = FeatureFlagDetailResponse{Code: "SKIP_EMAIL_OTP"}

	if err := service.Delete(context.Background(), "SKIP_EMAIL_OTP", "ONBOARDING", "tester"); err != nil {
		t.Fatalf("delete feature flag: %v", err)
	}

	if _, ok := cache.Get("ff_skip_email_otp_onboarding"); ok {
		t.Fatal("expected cache key to be evicted")
	}
	if repo.historyDeleted != 1 {
		t.Fatalf("expected delete history row, got %d", repo.historyDeleted)
	}
}

func TestFeatureFlagServiceFindByCodeCachesMissUntilTTL(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	clock := &mutableClock{now: now}
	repo := &fakeFeatureFlagRepo{now: now, flags: make(map[string]FeatureFlagDetailResponse)}
	cache := NewMemoryCacheWithClock[FeatureFlagDetailResponse](time.Minute, 10*time.Second, clock)
	service := NewFeatureFlagService(repo, repo, cache, clock)

	_, firstErr := service.FindByCode(context.Background(), "MISSING_FLAG", "ONBOARDING")
	_, secondErr := service.FindByCode(context.Background(), "MISSING_FLAG", "ONBOARDING")

	if firstErr == nil || secondErr == nil {
		t.Fatalf("expected cached misses to return not found errors, got %v / %v", firstErr, secondErr)
	}
	if repo.getByCodeCalls != 1 {
		t.Fatalf("expected one repository lookup while miss cache is fresh, got %d", repo.getByCodeCalls)
	}

	clock.now = clock.now.Add(11 * time.Second)
	_, thirdErr := service.FindByCode(context.Background(), "MISSING_FLAG", "ONBOARDING")
	if thirdErr == nil {
		t.Fatal("expected expired miss cache to still return not found after repository retry")
	}
	if repo.getByCodeCalls != 2 {
		t.Fatalf("expected repository lookup after miss ttl expiry, got %d", repo.getByCodeCalls)
	}
}

func TestFeatureFlagServiceClearCacheEvictsHitAndMiss(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	repo := &fakeFeatureFlagRepo{now: now, flags: make(map[string]FeatureFlagDetailResponse)}
	cache := NewMemoryCacheWithClock[FeatureFlagDetailResponse](time.Minute, time.Minute, fixedClock(now))
	service := NewFeatureFlagService(repo, repo, cache, fixedClock(now))
	cache.Put("ff_existing_onboarding", FeatureFlagDetailResponse{Code: "EXISTING"})
	cache.PutMissing("ff_missing_onboarding")

	service.ClearCache()

	if _, ok := cache.Get("ff_existing_onboarding"); ok {
		t.Fatal("expected cached feature flag hit to be evicted")
	}
	if cache.IsMissing("ff_missing_onboarding") {
		t.Fatal("expected cached feature flag miss to be evicted")
	}
}

func TestFeatureFlagServiceSwitchDueUsesAdvisoryLock(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	repo := &fakeFeatureFlagSchedulerRepo{
		fakeFeatureFlagRepo: fakeFeatureFlagRepo{now: now, flags: make(map[string]FeatureFlagDetailResponse)},
		lockAcquired:        false,
	}
	service := NewFeatureFlagService(repo, repo, NewMemoryCache[FeatureFlagDetailResponse](), fixedClock(now))

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

type fakeFeatureFlagRepo struct {
	now            time.Time
	flags          map[string]FeatureFlagDetailResponse
	historyCreated int
	historyDeleted int
	lastHistory    FeatureFlagHistoryCreateRequest
	getByCodeCalls int
}

func (r *fakeFeatureFlagRepo) ensure() {
	if r.flags == nil {
		r.flags = make(map[string]FeatureFlagDetailResponse)
	}
}

func (r *fakeFeatureFlagRepo) Create(_ context.Context, req FeatureFlagCreateRequest, actor string) (FeatureFlagDetailResponse, error) {
	r.ensure()
	detail := FeatureFlagDetailResponse{
		Code:            req.Code,
		CreatedAt:       r.now,
		CreatedBy:       actor,
		Name:            req.Name,
		Group:           req.Group,
		Type:            req.Type,
		Enabled:         req.Enabled,
		ActionStartDate: req.ActionStartDate,
		ActionEndDate:   req.ActionEndDate,
		Value:           req.Value,
	}
	r.flags[req.DomainCode+":"+req.Code] = detail
	return detail, nil
}

func (r *fakeFeatureFlagRepo) Update(_ context.Context, code string, req FeatureFlagUpdateRequest, actor string) (*FeatureFlagDetailResponse, error) {
	r.ensure()
	key := req.DomainCode + ":" + code
	existing, ok := r.flags[key]
	if !ok {
		return nil, nil
	}
	existing.UpdatedAt = ptrTime(r.now)
	existing.UpdatedBy = actor
	existing.Name = req.Name
	existing.Group = req.Group
	existing.Type = req.Type
	existing.Enabled = req.Enabled
	existing.ActionStartDate = req.ActionStartDate
	existing.ActionEndDate = req.ActionEndDate
	existing.Value = req.Value
	r.flags[key] = existing
	return &existing, nil
}

func (r *fakeFeatureFlagRepo) GetByCode(_ context.Context, code string, domainCode string) (*FeatureFlagDetailResponse, error) {
	r.ensure()
	r.getByCodeCalls++
	if detail, ok := r.flags[domainCode+":"+code]; ok {
		return &detail, nil
	}
	return nil, nil
}

func (r *fakeFeatureFlagRepo) FindAll(context.Context, FeatureFlagSearchRequest) (Page[FeatureFlagDetailResponse], error) {
	return Page[FeatureFlagDetailResponse]{}, nil
}

func (r *fakeFeatureFlagRepo) Delete(_ context.Context, code string, domainCode string, _ string) (bool, error) {
	r.ensure()
	key := domainCode + ":" + code
	if _, ok := r.flags[key]; !ok {
		return false, nil
	}
	delete(r.flags, key)
	r.historyDeleted++
	return true, nil
}

func (r *fakeFeatureFlagRepo) ExistsByCode(_ context.Context, code string, domainCode string) (bool, error) {
	r.ensure()
	_, ok := r.flags[domainCode+":"+code]
	return ok, nil
}

func (r *fakeFeatureFlagRepo) Recover(_ context.Context, code string, domainCode string, _ string) (*FeatureFlagDetailResponse, error) {
	r.ensure()
	if detail, ok := r.flags[domainCode+":"+code]; ok {
		return &detail, nil
	}
	return nil, nil
}

func (r *fakeFeatureFlagRepo) GroupsByDomain(context.Context, string) ([]string, error) {
	return []string{"General"}, nil
}

func (r *fakeFeatureFlagRepo) CreateHistory(_ context.Context, request FeatureFlagHistoryCreateRequest, _ string) error {
	r.lastHistory = request
	r.historyCreated++
	return nil
}

func (r *fakeFeatureFlagRepo) FindHistory(context.Context, FeatureFlagHistorySearchRequest) (Page[FeatureFlagHistoryResponse], error) {
	return Page[FeatureFlagHistoryResponse]{}, nil
}

func fixedClock(now time.Time) Clock {
	return ClockFunc(func() time.Time { return now })
}

type mutableClock struct {
	now time.Time
}

func (c *mutableClock) Now() time.Time {
	return c.now
}

func ptrTime(t time.Time) *time.Time {
	return &t
}

type fakeFeatureFlagSchedulerRepo struct {
	fakeFeatureFlagRepo
	lockAcquired bool
	switchCalls  int
	unlockCalls  int
}

func (r *fakeFeatureFlagSchedulerRepo) ListDomainCodes(context.Context) ([]string, error) {
	return []string{"ONBOARDING"}, nil
}

func (r *fakeFeatureFlagSchedulerRepo) SwitchDueFeatureFlags(context.Context, string, time.Time) ([]FeatureFlagDetailResponse, error) {
	r.switchCalls++
	return nil, nil
}

func (r *fakeFeatureFlagSchedulerRepo) TryAdvisoryLock(context.Context, int64) (bool, error) {
	return r.lockAcquired, nil
}

func (r *fakeFeatureFlagSchedulerRepo) UnlockAdvisory(context.Context, int64) error {
	r.unlockCalls++
	return nil
}

var _ FeatureFlagRepository = (*fakeFeatureFlagRepo)(nil)
var _ FeatureFlagHistoryRepository = (*fakeFeatureFlagRepo)(nil)
var _ FeatureFlagSchedulerRepository = (*fakeFeatureFlagSchedulerRepo)(nil)
var _ AdvisoryLocker = (*fakeFeatureFlagSchedulerRepo)(nil)
var _ = errors.Is
