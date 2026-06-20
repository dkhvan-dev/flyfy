package app

import (
	"context"
	"fmt"
	"strings"
	"time"
)

type TechBreakRepository interface {
	Create(ctx context.Context, request TechBreakUpsertRequest, scopes []TechBreakScope, enabled bool, actor string) (TechBreakResponse, error)
	Update(ctx context.Context, id int64, request TechBreakUpsertRequest, scopes []TechBreakScope, enabled bool, actor string) (*TechBreakResponse, error)
	GetByID(ctx context.Context, id int64, domainCode string, scopes []TechBreakScope) (*TechBreakResponse, error)
	FindAll(ctx context.Context, request TechBreakSearchRequest, scopes []TechBreakScope) (Page[TechBreakResponse], error)
	Delete(ctx context.Context, id int64, domainCode string) (bool, error)
	ExistsByName(ctx context.Context, name string, domainCode string, excludeID *int64) (bool, error)
	HasActive(ctx context.Context, request TechBreakCheckRequest) (bool, error)
	ExistsActiveByScope(ctx context.Context, domainCode string, scopeCode string) (bool, error)
	DeleteAllByScope(ctx context.Context, domainCode string, scopeCode string) error
}

type TechBreakScopeRepository interface {
	CreateScope(ctx context.Context, request TechBreakScopeCreateRequest, actor string) (TechBreakScope, error)
	UpdateScope(ctx context.Context, id int64, request TechBreakScopeUpdateRequest, actor string) (TechBreakScope, error)
	GetScopeByID(ctx context.Context, id int64, domainCode string) (*TechBreakScope, error)
	GetScopeByIDAnyDomain(ctx context.Context, id int64) (*TechBreakScope, error)
	FindScopes(ctx context.Context, domainCode string) ([]TechBreakScope, error)
	DeleteScope(ctx context.Context, id int64) error
	ScopeExistsByCode(ctx context.Context, domainCode string, code string) (bool, error)
	FindScopesByCodes(ctx context.Context, domainCode string, codes []string) ([]TechBreakScope, error)
	DomainHasScopes(ctx context.Context, domainCode string) (bool, error)
}

type DomainRepository interface {
	CreateDomain(ctx context.Context, request DomainCreateRequest, actor string) (DomainResponse, error)
	UpdateDomain(ctx context.Context, id int64, request DomainUpdateRequest, actor string) (DomainResponse, error)
	GetDomainByID(ctx context.Context, id int64) (*DomainResponse, error)
	FindDomains(ctx context.Context, request DomainSearchRequest) (Page[DomainResponse], error)
}

type TechBreakSchedulerRepository interface {
	ListDomainCodes(ctx context.Context) ([]string, error)
	SwitchDueTechBreaks(ctx context.Context, domainCode string, now time.Time) ([]TechBreakResponse, error)
}

type AdvisoryLocker interface {
	TryAdvisoryLock(ctx context.Context, key int64) (bool, error)
	UnlockAdvisory(ctx context.Context, key int64) error
}

const techBreakSchedulerLockKey int64 = 647391002

const maxPageSize = 100

type TechBreakService struct {
	repo      TechBreakRepository
	scopeRepo TechBreakScopeRepository
	cache     Cache[TechBreakResponse]
	clock     Clock
}

func NewTechBreakService(
	repo TechBreakRepository,
	scopeRepo TechBreakScopeRepository,
	cache Cache[TechBreakResponse],
	clock Clock,
) *TechBreakService {
	if cache == nil {
		cache = NewMemoryCache[TechBreakResponse]()
	}
	if clock == nil {
		clock = NewSystemClock()
	}
	return &TechBreakService{repo: repo, scopeRepo: scopeRepo, cache: cache, clock: clock}
}

func (s *TechBreakService) Create(
	ctx context.Context,
	request TechBreakUpsertRequest,
	actor string,
) (TechBreakResponse, error) {
	normalized, scopes, err := s.normalizeAndValidateUpsert(ctx, request, nil)
	if err != nil {
		return TechBreakResponse{}, err
	}
	enabled := ComputeTechBreakEnabled(normalized.ActionStartDate, normalized.ActionEndDate, s.clock.Now())
	created, err := s.repo.Create(ctx, normalized, scopes, enabled, actor)
	if err != nil {
		return TechBreakResponse{}, err
	}
	s.cache.Put(techBreakCacheKey(normalized.DomainCode, created.ID), created)
	return created, nil
}

func (s *TechBreakService) Update(
	ctx context.Context,
	id int64,
	request TechBreakUpsertRequest,
	actor string,
) (TechBreakResponse, error) {
	normalized, scopes, err := s.normalizeAndValidateUpsert(ctx, request, &id)
	if err != nil {
		return TechBreakResponse{}, err
	}
	enabled := ComputeTechBreakEnabled(normalized.ActionStartDate, normalized.ActionEndDate, s.clock.Now())
	updated, err := s.repo.Update(ctx, id, normalized, scopes, enabled, actor)
	if err != nil {
		return TechBreakResponse{}, err
	}
	if updated != nil {
		s.cache.Put(techBreakCacheKey(normalized.DomainCode, id), *updated)
		return *updated, nil
	}
	existing, err := s.repo.GetByID(ctx, id, normalized.DomainCode, scopes)
	if err != nil {
		return TechBreakResponse{}, err
	}
	if existing == nil {
		return TechBreakResponse{}, NotFound(ErrBreakNotFound)
	}
	return *existing, nil
}

func (s *TechBreakService) FindByID(ctx context.Context, id int64, domainCode string) (TechBreakResponse, error) {
	domainCode = strings.ToUpper(strings.TrimSpace(domainCode))
	cacheKey := techBreakCacheKey(domainCode, id)
	if cached, ok := s.cache.Get(cacheKey); ok {
		return cached, nil
	}
	scopes, err := s.scopeRepo.FindScopesByCodes(ctx, domainCode, nil)
	if err != nil {
		return TechBreakResponse{}, err
	}
	found, err := s.repo.GetByID(ctx, id, domainCode, scopes)
	if err != nil {
		return TechBreakResponse{}, err
	}
	if found == nil {
		return TechBreakResponse{}, NotFound(ErrBreakNotFound)
	}
	s.cache.Put(cacheKey, *found)
	return *found, nil
}

func (s *TechBreakService) Search(ctx context.Context, request TechBreakSearchRequest) (Page[TechBreakResponse], error) {
	request = normalizeTechBreakSearch(request)
	scopes, err := s.scopeRepo.FindScopesByCodes(ctx, request.DomainCode, nil)
	if err != nil {
		return Page[TechBreakResponse]{}, err
	}
	return s.repo.FindAll(ctx, request, scopes)
}

func (s *TechBreakService) Delete(ctx context.Context, id int64, domainCode string) error {
	domainCode = strings.ToUpper(strings.TrimSpace(domainCode))
	deleted, err := s.repo.Delete(ctx, id, domainCode)
	if err != nil {
		return err
	}
	if !deleted {
		return NotFound(ErrBreakNotFound)
	}
	s.cache.Delete(techBreakCacheKey(domainCode, id))
	return nil
}

func (s *TechBreakService) ClearCache() {
	s.cache.Clear()
}

func (s *TechBreakService) HasActive(ctx context.Context, request TechBreakCheckRequest) (bool, error) {
	request.DomainCode = strings.ToUpper(strings.TrimSpace(request.DomainCode))
	request.ScopeCodes = normalizeCodes(request.ScopeCodes)
	if err := ValidateTechBreakCheck(request); err != nil {
		return false, err
	}
	return s.repo.HasActive(ctx, request)
}

func (s *TechBreakService) SwitchDue(ctx context.Context) error {
	schedulerRepo, ok := s.repo.(TechBreakSchedulerRepository)
	if !ok {
		return nil
	}
	if locker, ok := s.repo.(AdvisoryLocker); ok {
		locked, err := locker.TryAdvisoryLock(ctx, techBreakSchedulerLockKey)
		if err != nil {
			return err
		}
		if !locked {
			return nil
		}
		runErr := s.switchDueLocked(ctx, schedulerRepo)
		unlockErr := locker.UnlockAdvisory(ctx, techBreakSchedulerLockKey)
		if runErr != nil {
			return runErr
		}
		return unlockErr
	}
	return s.switchDueLocked(ctx, schedulerRepo)
}

func (s *TechBreakService) switchDueLocked(ctx context.Context, schedulerRepo TechBreakSchedulerRepository) error {
	domainCodes, err := schedulerRepo.ListDomainCodes(ctx)
	if err != nil {
		return err
	}
	now := TruncateToMinute(s.clock.Now())
	for _, domainCode := range domainCodes {
		updatedBreaks, err := schedulerRepo.SwitchDueTechBreaks(ctx, domainCode, now)
		if err != nil {
			return err
		}
		for _, techBreak := range updatedBreaks {
			s.cache.Put(techBreakCacheKey(domainCode, techBreak.ID), techBreak)
		}
	}
	return nil
}

func (s *TechBreakService) normalizeAndValidateUpsert(
	ctx context.Context,
	request TechBreakUpsertRequest,
	id *int64,
) (TechBreakUpsertRequest, []TechBreakScope, error) {
	request.DomainCode = strings.ToUpper(strings.TrimSpace(request.DomainCode))
	request.ActionStartDate = TruncateToMinute(request.ActionStartDate)
	request.ActionEndDate = TruncatePtrToMinute(request.ActionEndDate)
	request.ScopeCodes = normalizeCodes(request.ScopeCodes)

	if err := ValidateTechBreakUpsert(request); err != nil {
		return TechBreakUpsertRequest{}, nil, err
	}

	scopes := []TechBreakScope{}
	if len(request.ScopeCodes) > 0 {
		var err error
		scopes, err = s.scopeRepo.FindScopesByCodes(ctx, request.DomainCode, request.ScopeCodes)
		if err != nil {
			return TechBreakUpsertRequest{}, nil, err
		}
	}

	hasScopes, err := s.scopeRepo.DomainHasScopes(ctx, request.DomainCode)
	if err != nil {
		return TechBreakUpsertRequest{}, nil, err
	}
	if len(request.ScopeCodes) > 0 && !hasScopes {
		return TechBreakUpsertRequest{}, nil, Conflict(ErrBreakScopesMustBeEmpty)
	}
	exists, err := s.repo.ExistsByName(ctx, request.Name, request.DomainCode, id)
	if err != nil {
		return TechBreakUpsertRequest{}, nil, err
	}
	if exists {
		return TechBreakUpsertRequest{}, nil, Conflict(ErrBreakWithSameNameAlreadyExist)
	}
	if len(request.ScopeCodes) > 0 && len(request.ScopeCodes) != len(scopes) {
		return TechBreakUpsertRequest{}, nil, Conflict(ErrScopeNotRelatedToDomain)
	}
	return request, scopes, nil
}

type TechBreakScopeService struct {
	repo      TechBreakScopeRepository
	breakRepo TechBreakRepository
}

func NewTechBreakScopeService(repo TechBreakScopeRepository, breakRepo TechBreakRepository) *TechBreakScopeService {
	return &TechBreakScopeService{repo: repo, breakRepo: breakRepo}
}

func (s *TechBreakScopeService) Create(
	ctx context.Context,
	request TechBreakScopeCreateRequest,
	actor string,
) (TechBreakScope, error) {
	request.DomainCode = strings.ToUpper(strings.TrimSpace(request.DomainCode))
	if err := ValidateTechBreakScopeCreate(request); err != nil {
		return TechBreakScope{}, err
	}
	exists, err := s.repo.ScopeExistsByCode(ctx, request.DomainCode, request.Code)
	if err != nil {
		return TechBreakScope{}, err
	}
	if exists {
		return TechBreakScope{}, Conflict(fmt.Errorf("Scope уже существует с кодом %s", request.Code))
	}
	return s.repo.CreateScope(ctx, request, actor)
}

func (s *TechBreakScopeService) Update(
	ctx context.Context,
	id int64,
	request TechBreakScopeUpdateRequest,
	actor string,
) (TechBreakScope, error) {
	request.DomainCode = strings.ToUpper(strings.TrimSpace(request.DomainCode))
	if strings.TrimSpace(request.DomainCode) == "" {
		return TechBreakScope{}, BadRequest("Не заполнен код домена/продукта")
	}
	if strings.TrimSpace(request.Name) == "" {
		return TechBreakScope{}, BadRequest("Не заполнено наименование")
	}
	return s.repo.UpdateScope(ctx, id, request, actor)
}

func (s *TechBreakScopeService) FindByID(ctx context.Context, id int64, domainCode string) (TechBreakScope, error) {
	domainCode = strings.ToUpper(strings.TrimSpace(domainCode))
	scope, err := s.repo.GetScopeByID(ctx, id, domainCode)
	if err != nil {
		return TechBreakScope{}, err
	}
	if scope == nil {
		return TechBreakScope{}, NotFound(ErrScopeNotFound)
	}
	return *scope, nil
}

func (s *TechBreakScopeService) FindAll(ctx context.Context, domainCode string) ([]TechBreakScope, error) {
	return s.repo.FindScopes(ctx, strings.ToUpper(strings.TrimSpace(domainCode)))
}

func (s *TechBreakScopeService) Delete(ctx context.Context, id int64) error {
	scope, err := s.repo.GetScopeByIDAnyDomain(ctx, id)
	if err != nil {
		return err
	}
	if scope == nil {
		return NotFound(ErrScopeNotFound)
	}
	active, err := s.breakRepo.ExistsActiveByScope(ctx, scope.DomainCode, scope.Code)
	if err != nil {
		return err
	}
	if active {
		return Conflict(ErrScopeHasActiveBreaks)
	}
	if err = s.repo.DeleteScope(ctx, id); err != nil {
		return err
	}
	if err = s.breakRepo.DeleteAllByScope(ctx, scope.DomainCode, scope.Code); err != nil {
		return err
	}
	return nil
}

func normalizeTechBreakSearch(request TechBreakSearchRequest) TechBreakSearchRequest {
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

func normalizeCodes(codes []string) []string {
	result := make([]string, 0, len(codes))
	seen := make(map[string]struct{}, len(codes))
	for _, code := range codes {
		normalized := strings.ToUpper(strings.TrimSpace(code))
		if normalized == "" {
			continue
		}
		if _, ok := seen[normalized]; ok {
			continue
		}
		seen[normalized] = struct{}{}
		result = append(result, normalized)
	}
	return result
}

func techBreakCacheKey(domainCode string, id int64) string {
	return fmt.Sprintf("techBreak_%s_%d", strings.ToLower(strings.TrimSpace(domainCode)), id)
}
