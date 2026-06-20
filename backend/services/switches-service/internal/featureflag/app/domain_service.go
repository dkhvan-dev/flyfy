package app

import (
	"context"
	"strings"
)

type DomainService struct {
	repo DomainRepository
}

func NewDomainService(repo DomainRepository) *DomainService {
	return &DomainService{repo: repo}
}

func (s *DomainService) Create(
	ctx context.Context,
	request DomainCreateRequest,
	actor string,
) (DomainResponse, error) {
	if err := ValidateDomainCreate(request); err != nil {
		return DomainResponse{}, err
	}
	request.Code = strings.ToUpper(strings.TrimSpace(request.Code))
	return s.repo.CreateDomain(ctx, request, actor)
}

func (s *DomainService) Update(
	ctx context.Context,
	id int64,
	request DomainUpdateRequest,
	actor string,
) (DomainResponse, error) {
	if err := ValidateDomainCreate(DomainCreateRequest(request)); err != nil {
		return DomainResponse{}, err
	}
	request.Code = strings.ToUpper(strings.TrimSpace(request.Code))
	return s.repo.UpdateDomain(ctx, id, request, actor)
}

func (s *DomainService) FindByID(ctx context.Context, id int64) (DomainResponse, error) {
	domain, err := s.repo.GetDomainByID(ctx, id)
	if err != nil {
		return DomainResponse{}, err
	}
	if domain == nil {
		return DomainResponse{}, NotFound(ErrDomainNotFound)
	}
	return *domain, nil
}

func (s *DomainService) Search(ctx context.Context, request DomainSearchRequest) (Page[DomainResponse], error) {
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
	return s.repo.FindDomains(ctx, request)
}
