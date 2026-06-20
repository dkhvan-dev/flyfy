package app

import (
	"context"
	"strings"
	"time"
)

type FeatureFlagRepository interface {
	Create(ctx context.Context, request FeatureFlagCreateRequest, actor string) (FeatureFlagDetailResponse, error)
	Update(ctx context.Context, code string, request FeatureFlagUpdateRequest, actor string) (*FeatureFlagDetailResponse, error)
	GetByCode(ctx context.Context, code string, domainCode string) (*FeatureFlagDetailResponse, error)
	FindAll(ctx context.Context, request FeatureFlagSearchRequest) (Page[FeatureFlagDetailResponse], error)
	Delete(ctx context.Context, code string, domainCode string, actor string) (bool, error)
	ExistsByCode(ctx context.Context, code string, domainCode string) (bool, error)
	Recover(ctx context.Context, code string, domainCode string, actor string) (*FeatureFlagDetailResponse, error)
	GroupsByDomain(ctx context.Context, domainCode string) ([]string, error)
}

type FeatureFlagHistoryRepository interface {
	CreateHistory(ctx context.Context, request FeatureFlagHistoryCreateRequest, actor string) error
	FindHistory(ctx context.Context, request FeatureFlagHistorySearchRequest) (Page[FeatureFlagHistoryResponse], error)
}

type DomainRepository interface {
	CreateDomain(ctx context.Context, request DomainCreateRequest, actor string) (DomainResponse, error)
	UpdateDomain(ctx context.Context, id int64, request DomainUpdateRequest, actor string) (DomainResponse, error)
	GetDomainByID(ctx context.Context, id int64) (*DomainResponse, error)
	FindDomains(ctx context.Context, request DomainSearchRequest) (Page[DomainResponse], error)
}

type FeatureFlagSchedulerRepository interface {
	ListDomainCodes(ctx context.Context) ([]string, error)
	SwitchDueFeatureFlags(ctx context.Context, domainCode string, now time.Time) ([]FeatureFlagDetailResponse, error)
}

type AdvisoryLocker interface {
	TryAdvisoryLock(ctx context.Context, key int64) (bool, error)
	UnlockAdvisory(ctx context.Context, key int64) error
}

const featureFlagSchedulerLockKey int64 = 647391001

const maxPageSize = 100

type FeatureFlagService struct {
	repo        FeatureFlagRepository
	historyRepo FeatureFlagHistoryRepository
	cache       Cache[FeatureFlagDetailResponse]
	clock       Clock
}

func NewFeatureFlagService(
	repo FeatureFlagRepository,
	historyRepo FeatureFlagHistoryRepository,
	cache Cache[FeatureFlagDetailResponse],
	clock Clock,
) *FeatureFlagService {
	if cache == nil {
		cache = NewMemoryCache[FeatureFlagDetailResponse]()
	}
	if clock == nil {
		clock = NewSystemClock()
	}
	return &FeatureFlagService{repo: repo, historyRepo: historyRepo, cache: cache, clock: clock}
}

func (s *FeatureFlagService) Create(
	ctx context.Context,
	request FeatureFlagCreateRequest,
	actor string,
) (FeatureFlagDetailResponse, error) {
	request.DomainCode = strings.ToUpper(strings.TrimSpace(request.DomainCode))
	request.ActionStartDate = TruncateToMinute(request.ActionStartDate)
	request.ActionEndDate = TruncatePtrToMinute(request.ActionEndDate)
	request.Value = normalizeFeatureFlagRequestValue(request.Type, request.Enabled, request.Value)

	if err := ValidateFeatureFlagCreate(request, s.clock.Now()); err != nil {
		return FeatureFlagDetailResponse{}, err
	}

	exists, err := s.repo.ExistsByCode(ctx, request.Code, request.DomainCode)
	if err != nil {
		return FeatureFlagDetailResponse{}, err
	}
	if exists {
		return FeatureFlagDetailResponse{}, Conflict(ErrFeatureFlagAlreadyExists)
	}

	created, err := s.repo.Create(ctx, request, actor)
	if err != nil {
		return FeatureFlagDetailResponse{}, err
	}
	if err = s.historyRepo.CreateHistory(ctx, historyFromCreate(request), actor); err != nil {
		return FeatureFlagDetailResponse{}, err
	}
	s.cache.Put(featureFlagCacheKey(request.Code, request.DomainCode), created)
	return created, nil
}

func (s *FeatureFlagService) Update(
	ctx context.Context,
	code string,
	request FeatureFlagUpdateRequest,
	actor string,
) (FeatureFlagDetailResponse, error) {
	request.DomainCode = strings.ToUpper(strings.TrimSpace(request.DomainCode))
	request.ActionStartDate = TruncateToMinute(request.ActionStartDate)
	request.ActionEndDate = TruncatePtrToMinute(request.ActionEndDate)
	request.Value = normalizeFeatureFlagRequestValue(request.Type, request.Enabled, request.Value)

	if err := ValidateFeatureFlagUpdate(request, s.clock.Now()); err != nil {
		return FeatureFlagDetailResponse{}, err
	}

	updated, err := s.repo.Update(ctx, code, request, actor)
	if err != nil {
		return FeatureFlagDetailResponse{}, err
	}
	if updated != nil {
		if err = s.historyRepo.CreateHistory(ctx, historyFromUpdate(code, request), actor); err != nil {
			return FeatureFlagDetailResponse{}, err
		}
		s.cache.Put(featureFlagCacheKey(code, request.DomainCode), *updated)
		return *updated, nil
	}

	existing, err := s.repo.GetByCode(ctx, code, request.DomainCode)
	if err != nil {
		return FeatureFlagDetailResponse{}, err
	}
	if existing == nil {
		return FeatureFlagDetailResponse{}, NotFound(ErrFeatureFlagNotFound)
	}
	return *existing, nil
}

func (s *FeatureFlagService) FindByCode(
	ctx context.Context,
	code string,
	domainCode string,
) (FeatureFlagDetailResponse, error) {
	domainCode = strings.ToUpper(strings.TrimSpace(domainCode))
	cacheKey := featureFlagCacheKey(code, domainCode)
	if cached, ok := s.cache.Get(cacheKey); ok {
		return cached, nil
	}
	if s.cache.IsMissing(cacheKey) {
		return FeatureFlagDetailResponse{}, NotFound(ErrFeatureFlagNotFound)
	}
	found, err := s.repo.GetByCode(ctx, code, domainCode)
	if err != nil {
		return FeatureFlagDetailResponse{}, err
	}
	if found == nil {
		s.cache.PutMissing(cacheKey)
		return FeatureFlagDetailResponse{}, NotFound(ErrFeatureFlagNotFound)
	}
	s.cache.Put(cacheKey, *found)
	return *found, nil
}

func (s *FeatureFlagService) FindInternalByCode(
	ctx context.Context,
	code string,
	domainCode string,
) (FeatureFlagInternalDetailResponse, error) {
	detail, err := s.FindByCode(ctx, code, domainCode)
	if err != nil {
		return FeatureFlagInternalDetailResponse{}, err
	}
	return FeatureFlagInternalDetailResponse{
		Enabled: detail.Enabled,
		Type:    detail.Type,
		Value:   detail.Value,
	}, nil
}

func (s *FeatureFlagService) Search(
	ctx context.Context,
	request FeatureFlagSearchRequest,
) (Page[FeatureFlagDetailResponse], error) {
	request = normalizeFeatureFlagSearch(request)
	return s.repo.FindAll(ctx, request)
}

func (s *FeatureFlagService) Delete(
	ctx context.Context,
	code string,
	domainCode string,
	actor string,
) error {
	domainCode = strings.ToUpper(strings.TrimSpace(domainCode))
	deleted, err := s.repo.Delete(ctx, code, domainCode, actor)
	if err != nil {
		return err
	}
	if !deleted {
		return NotFound(ErrFeatureFlagNotFound)
	}
	s.cache.Delete(featureFlagCacheKey(code, domainCode))
	return nil
}

func (s *FeatureFlagService) Recover(
	ctx context.Context,
	code string,
	domainCode string,
	actor string,
) (FeatureFlagDetailResponse, error) {
	domainCode = strings.ToUpper(strings.TrimSpace(domainCode))
	exists, err := s.repo.ExistsByCode(ctx, code, domainCode)
	if err != nil {
		return FeatureFlagDetailResponse{}, err
	}
	if !exists {
		return FeatureFlagDetailResponse{}, NotFound(ErrFeatureFlagNotFound)
	}
	recovered, err := s.repo.Recover(ctx, code, domainCode, actor)
	if err != nil {
		return FeatureFlagDetailResponse{}, err
	}
	if recovered == nil {
		return FeatureFlagDetailResponse{}, NotFound(ErrFeatureFlagNotFound)
	}
	s.cache.Put(featureFlagCacheKey(code, domainCode), *recovered)
	return *recovered, nil
}

func (s *FeatureFlagService) ClearCache() {
	s.cache.Clear()
}

func (s *FeatureFlagService) SearchHistory(
	ctx context.Context,
	request FeatureFlagHistorySearchRequest,
) (Page[FeatureFlagHistoryResponse], error) {
	request.DomainCode = strings.ToUpper(strings.TrimSpace(request.DomainCode))
	if request.Page < 0 {
		request.Page = 0
	}
	if request.Size <= 0 {
		request.Size = 10
	}
	if request.Size > maxPageSize {
		request.Size = maxPageSize
	}
	if strings.TrimSpace(request.OrderBy) == "" {
		request.OrderBy = "created_at"
	}
	if strings.TrimSpace(request.Direction) == "" {
		request.Direction = "desc"
	}
	return s.historyRepo.FindHistory(ctx, request)
}

func (s *FeatureFlagService) SwitchDue(ctx context.Context) error {
	schedulerRepo, ok := s.repo.(FeatureFlagSchedulerRepository)
	if !ok {
		return nil
	}
	if locker, ok := s.repo.(AdvisoryLocker); ok {
		locked, err := locker.TryAdvisoryLock(ctx, featureFlagSchedulerLockKey)
		if err != nil {
			return err
		}
		if !locked {
			return nil
		}
		runErr := s.switchDueLocked(ctx, schedulerRepo)
		unlockErr := locker.UnlockAdvisory(ctx, featureFlagSchedulerLockKey)
		if runErr != nil {
			return runErr
		}
		return unlockErr
	}
	return s.switchDueLocked(ctx, schedulerRepo)
}

func (s *FeatureFlagService) switchDueLocked(ctx context.Context, schedulerRepo FeatureFlagSchedulerRepository) error {
	domainCodes, err := schedulerRepo.ListDomainCodes(ctx)
	if err != nil {
		return err
	}
	now := TruncateToMinute(s.clock.Now())
	for _, domainCode := range domainCodes {
		updatedFlags, err := schedulerRepo.SwitchDueFeatureFlags(ctx, domainCode, now)
		if err != nil {
			return err
		}
		for _, featureFlag := range updatedFlags {
			s.cache.Put(featureFlagCacheKey(featureFlag.Code, domainCode), featureFlag)
		}
	}
	return nil
}

func historyFromCreate(request FeatureFlagCreateRequest) FeatureFlagHistoryCreateRequest {
	return FeatureFlagHistoryCreateRequest{
		DomainCode:      request.DomainCode,
		Code:            request.Code,
		Name:            request.Name,
		Group:           request.Group,
		Type:            request.Type,
		Enabled:         request.Enabled,
		ActionStartDate: request.ActionStartDate,
		ActionEndDate:   request.ActionEndDate,
		Value:           request.Value,
	}
}

func historyFromUpdate(code string, request FeatureFlagUpdateRequest) FeatureFlagHistoryCreateRequest {
	return FeatureFlagHistoryCreateRequest{
		DomainCode:      request.DomainCode,
		Code:            code,
		Name:            request.Name,
		Group:           request.Group,
		Type:            request.Type,
		Enabled:         request.Enabled,
		ActionStartDate: request.ActionStartDate,
		ActionEndDate:   request.ActionEndDate,
		Value:           request.Value,
	}
}

func normalizeFeatureFlagRequestValue(flagType FeatureFlagType, enabled bool, value []any) []any {
	if flagType == FeatureFlagTypeToggle {
		return []any{enabled}
	}
	return value
}

func normalizeFeatureFlagSearch(request FeatureFlagSearchRequest) FeatureFlagSearchRequest {
	request.DomainCode = strings.ToUpper(strings.TrimSpace(request.DomainCode))
	if request.Page < 0 {
		request.Page = 0
	}
	if request.Size <= 0 {
		request.Size = 10
	}
	if request.Size > maxPageSize {
		request.Size = maxPageSize
	}
	if strings.TrimSpace(request.OrderBy) == "" {
		request.OrderBy = "created_at"
	}
	if strings.TrimSpace(request.Direction) == "" {
		request.Direction = "desc"
	}
	return request
}

func featureFlagCacheKey(code string, domainCode string) string {
	return "ff_" + strings.ToLower(strings.TrimSpace(code)) + "_" + strings.ToLower(strings.TrimSpace(domainCode))
}
