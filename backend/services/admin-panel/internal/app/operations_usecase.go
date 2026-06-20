package app

import (
	"context"
	"encoding/json"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

const (
	defaultOperationsPageSize = 20
	maxOperationsPageSize     = 200
	operationsRemotePageSize  = 500
)

type OperationsUseCase struct {
	featureFlags port.FeatureFlagAdminClient
	techBreaks   port.TechBreakAdminClient
	audit        port.AuditRepository
}

type OperationsDomainListInput struct {
	Page      int
	Size      int
	OrderBy   string
	Direction string
	Search    string
}

type OperationsDomainDetailInput struct {
	FeatureFlags model.OperationFeatureFlagFilter
	TechBreaks   model.OperationTechBreakFilter
}

type OperationsDomainDetailPage struct {
	Domain       model.OperationDomain
	FeatureFlags model.OperationPage[model.OperationFeatureFlag]
	TechBreaks   model.OperationPage[model.OperationTechBreak]
	Scopes       []model.OperationTechBreakScope
}

type OperationsFeatureFlagDetailPage struct {
	Domain  model.OperationDomain
	Flag    model.OperationFeatureFlag
	History model.OperationPage[model.OperationFeatureFlagHistory]
}

type OperationsTechBreakDetailPage struct {
	Domain model.OperationDomain
	Break  model.OperationTechBreak
	Scopes []model.OperationTechBreakScope
}

type OperationsScopeDetailPage struct {
	Domain model.OperationDomain
	Scope  model.OperationTechBreakScope
}

func NewOperationsUseCase(
	featureFlags port.FeatureFlagAdminClient,
	techBreaks port.TechBreakAdminClient,
	audit port.AuditRepository,
) *OperationsUseCase {
	return &OperationsUseCase{
		featureFlags: featureFlags,
		techBreaks:   techBreaks,
		audit:        audit,
	}
}

func (u *OperationsUseCase) ListDomains(
	ctx context.Context,
	actor *model.StaffUser,
	input OperationsDomainListInput,
) (model.OperationDomainPage, error) {
	if err := u.requireAccess(actor); err != nil {
		return model.OperationDomainPage{}, err
	}
	if err := u.requireClients(); err != nil {
		return model.OperationDomainPage{}, err
	}

	filter := model.OperationDomainFilter{
		Page:      0,
		Size:      operationsRemotePageSize,
		OrderBy:   strings.TrimSpace(input.OrderBy),
		Direction: strings.TrimSpace(input.Direction),
		Search:    strings.TrimSpace(input.Search),
	}
	featureDomains, err := u.featureFlags.ListDomains(ctx, filter)
	if err != nil {
		return model.OperationDomainPage{}, err
	}
	techDomains, err := u.techBreaks.ListDomains(ctx, filter)
	if err != nil {
		return model.OperationDomainPage{}, err
	}

	merged := mergeOperationDomains(featureDomains.Content, techDomains.Content)
	return operationDomainPage(merged, normalizeOperationsPage(input.Page), normalizeOperationsPageSize(input.Size)), nil
}

func (u *OperationsUseCase) GetDomainDetail(
	ctx context.Context,
	actor *model.StaffUser,
	code string,
	input OperationsDomainDetailInput,
) (OperationsDomainDetailPage, error) {
	if err := u.requireAccess(actor); err != nil {
		return OperationsDomainDetailPage{}, err
	}
	if err := u.requireClients(); err != nil {
		return OperationsDomainDetailPage{}, err
	}

	domain, err := u.findDomain(ctx, code)
	if err != nil {
		return OperationsDomainDetailPage{}, err
	}
	domainCode := normalizeOperationCode(domain.Code)

	featureFilter := input.FeatureFlags
	featureFilter.DomainCode = domainCode
	featureFilter.Page = normalizeOperationsPage(featureFilter.Page)
	featureFilter.Size = normalizeOperationsPageSize(featureFilter.Size)
	featureFlags, err := u.featureFlags.ListFeatureFlags(ctx, featureFilter)
	if err != nil {
		return OperationsDomainDetailPage{}, err
	}

	techFilter := input.TechBreaks
	techFilter.DomainCode = domainCode
	techFilter.Page = normalizeOperationsPage(techFilter.Page)
	techFilter.Size = normalizeOperationsPageSize(techFilter.Size)
	techBreaks, err := u.techBreaks.ListTechBreaks(ctx, techFilter)
	if err != nil {
		return OperationsDomainDetailPage{}, err
	}

	scopes, err := u.techBreaks.ListScopes(ctx, domainCode)
	if err != nil {
		return OperationsDomainDetailPage{}, err
	}

	return OperationsDomainDetailPage{
		Domain:       domain,
		FeatureFlags: featureFlags,
		TechBreaks:   techBreaks,
		Scopes:       scopes,
	}, nil
}

func (u *OperationsUseCase) SaveDomain(
	ctx context.Context,
	actor *model.StaffUser,
	input model.OperationDomainInput,
) (model.OperationDomain, error) {
	if err := u.requireAccess(actor); err != nil {
		return model.OperationDomain{}, err
	}
	if err := u.requireClients(); err != nil {
		return model.OperationDomain{}, err
	}
	input.Code = normalizeOperationCode(input.Code)
	input.Description = strings.TrimSpace(input.Description)
	input.Actor = actorIdentifier(actor)
	if input.Code == "" {
		return model.OperationDomain{}, ErrInvalidInput
	}
	if input.FeatureFlagServiceID == 0 || input.TechBreakServiceID == 0 {
		existing, _ := u.findDomain(ctx, input.Code)
		input.FeatureFlagServiceID = existing.FeatureFlagServiceID
		input.TechBreakServiceID = existing.TechBreakServiceID
	}

	featureDomain, err := u.featureFlags.UpsertDomain(ctx, input)
	if err != nil {
		return model.OperationDomain{}, err
	}
	techDomain, err := u.techBreaks.UpsertDomain(ctx, input)
	if err != nil {
		return model.OperationDomain{}, err
	}
	result := mergeOperationDomains([]model.OperationDomain{featureDomain}, []model.OperationDomain{techDomain})
	if len(result) == 0 {
		return model.OperationDomain{}, ErrOperationDomainNotFound
	}
	u.appendAudit(ctx, actor, "operations.domain.save", "operation_domain", input.RequestID, map[string]any{
		"code":        input.Code,
		"description": input.Description,
	})
	return result[0], nil
}

func (u *OperationsUseCase) GetFeatureFlagDetail(
	ctx context.Context,
	actor *model.StaffUser,
	domainCode string,
	code string,
) (OperationsFeatureFlagDetailPage, error) {
	if err := u.requireAccess(actor); err != nil {
		return OperationsFeatureFlagDetailPage{}, err
	}
	if err := u.requireClients(); err != nil {
		return OperationsFeatureFlagDetailPage{}, err
	}
	domain, flag, err := u.findFeatureFlag(ctx, domainCode, code)
	if err != nil {
		return OperationsFeatureFlagDetailPage{}, err
	}
	return OperationsFeatureFlagDetailPage{Domain: domain, Flag: flag}, nil
}

func (u *OperationsUseCase) GetFeatureFlagHistory(
	ctx context.Context,
	actor *model.StaffUser,
	domainCode string,
	code string,
	historyFilter model.OperationFeatureFlagHistoryFilter,
) (OperationsFeatureFlagDetailPage, error) {
	if err := u.requireAccess(actor); err != nil {
		return OperationsFeatureFlagDetailPage{}, err
	}
	if err := u.requireClients(); err != nil {
		return OperationsFeatureFlagDetailPage{}, err
	}
	domain, flag, err := u.findFeatureFlag(ctx, domainCode, code)
	if err != nil {
		return OperationsFeatureFlagDetailPage{}, err
	}
	historyFilter.DomainCode = domain.Code
	historyFilter.Code = normalizeOperationCode(code)
	historyFilter.Type = strings.ToUpper(strings.TrimSpace(flag.Type))
	historyFilter.Page = normalizeOperationsPage(historyFilter.Page)
	historyFilter.Size = normalizeOperationsPageSize(historyFilter.Size)
	history, err := u.featureFlags.ListFeatureFlagHistory(ctx, historyFilter)
	if err != nil {
		return OperationsFeatureFlagDetailPage{}, err
	}
	return OperationsFeatureFlagDetailPage{Domain: domain, Flag: flag, History: history}, nil
}

func (u *OperationsUseCase) findFeatureFlag(ctx context.Context, domainCode string, code string) (model.OperationDomain, model.OperationFeatureFlag, error) {
	domain, err := u.findDomain(ctx, domainCode)
	if err != nil {
		return model.OperationDomain{}, model.OperationFeatureFlag{}, err
	}
	flag, err := u.featureFlags.GetFeatureFlag(ctx, domain.Code, normalizeOperationCode(code))
	if err != nil {
		return model.OperationDomain{}, model.OperationFeatureFlag{}, err
	}
	return domain, flag, nil
}

func (u *OperationsUseCase) SaveFeatureFlag(
	ctx context.Context,
	actor *model.StaffUser,
	input model.OperationFeatureFlagInput,
) (model.OperationFeatureFlag, error) {
	if err := u.requireAccess(actor); err != nil {
		return model.OperationFeatureFlag{}, err
	}
	if err := u.requireClients(); err != nil {
		return model.OperationFeatureFlag{}, err
	}
	input.DomainCode = normalizeOperationCode(input.DomainCode)
	input.Code = normalizeOperationCode(input.Code)
	input.ExistingCode = normalizeOperationCode(input.ExistingCode)
	input.Name = strings.TrimSpace(input.Name)
	input.Group = strings.TrimSpace(input.Group)
	input.Type = strings.ToUpper(strings.TrimSpace(input.Type))
	input.Actor = actorIdentifier(actor)
	if input.DomainCode == "" || input.Code == "" || input.Name == "" || input.Group == "" || input.Type == "" || input.ActionStartDate.IsZero() {
		return model.OperationFeatureFlag{}, ErrInvalidInput
	}
	flag, err := u.featureFlags.UpsertFeatureFlag(ctx, input)
	if err != nil {
		return model.OperationFeatureFlag{}, err
	}
	action := "operations.feature_flag.create"
	if input.ExistingCode != "" {
		action = "operations.feature_flag.update"
	}
	u.appendAudit(ctx, actor, action, "operation_feature_flag", input.RequestID, map[string]any{
		"domainCode": input.DomainCode,
		"code":       input.Code,
	})
	return flag, nil
}

func (u *OperationsUseCase) ArchiveFeatureFlag(ctx context.Context, actor *model.StaffUser, domainCode string, code string, requestID string) error {
	if err := u.requireAccess(actor); err != nil {
		return err
	}
	if err := u.requireClients(); err != nil {
		return err
	}
	domainCode = normalizeOperationCode(domainCode)
	code = normalizeOperationCode(code)
	if domainCode == "" || code == "" {
		return ErrInvalidInput
	}
	if err := u.featureFlags.ArchiveFeatureFlag(ctx, domainCode, code); err != nil {
		return err
	}
	u.appendAudit(ctx, actor, "operations.feature_flag.archive", "operation_feature_flag", requestID, map[string]any{"domainCode": domainCode, "code": code})
	return nil
}

func (u *OperationsUseCase) RecoverFeatureFlag(ctx context.Context, actor *model.StaffUser, domainCode string, code string, requestID string) (model.OperationFeatureFlag, error) {
	if err := u.requireAccess(actor); err != nil {
		return model.OperationFeatureFlag{}, err
	}
	if err := u.requireClients(); err != nil {
		return model.OperationFeatureFlag{}, err
	}
	domainCode = normalizeOperationCode(domainCode)
	code = normalizeOperationCode(code)
	if domainCode == "" || code == "" {
		return model.OperationFeatureFlag{}, ErrInvalidInput
	}
	flag, err := u.featureFlags.RecoverFeatureFlag(ctx, domainCode, code)
	if err != nil {
		return model.OperationFeatureFlag{}, err
	}
	u.appendAudit(ctx, actor, "operations.feature_flag.recover", "operation_feature_flag", requestID, map[string]any{"domainCode": domainCode, "code": code})
	return flag, nil
}

func (u *OperationsUseCase) GetTechBreakDetail(ctx context.Context, actor *model.StaffUser, domainCode string, id int64) (OperationsTechBreakDetailPage, error) {
	if err := u.requireAccess(actor); err != nil {
		return OperationsTechBreakDetailPage{}, err
	}
	if err := u.requireClients(); err != nil {
		return OperationsTechBreakDetailPage{}, err
	}
	domain, err := u.findDomain(ctx, domainCode)
	if err != nil {
		return OperationsTechBreakDetailPage{}, err
	}
	item, err := u.techBreaks.GetTechBreak(ctx, id, domain.Code)
	if err != nil {
		return OperationsTechBreakDetailPage{}, err
	}
	scopes, err := u.techBreaks.ListScopes(ctx, domain.Code)
	if err != nil {
		return OperationsTechBreakDetailPage{}, err
	}
	return OperationsTechBreakDetailPage{Domain: domain, Break: item, Scopes: scopes}, nil
}

func (u *OperationsUseCase) SaveTechBreak(ctx context.Context, actor *model.StaffUser, input model.OperationTechBreakInput) (model.OperationTechBreak, error) {
	if err := u.requireAccess(actor); err != nil {
		return model.OperationTechBreak{}, err
	}
	if err := u.requireClients(); err != nil {
		return model.OperationTechBreak{}, err
	}
	input.DomainCode = normalizeOperationCode(input.DomainCode)
	input.Name = strings.TrimSpace(input.Name)
	input.Actor = actorIdentifier(actor)
	if input.DomainCode == "" || input.Name == "" || input.ActionStartDate.IsZero() {
		return model.OperationTechBreak{}, ErrInvalidInput
	}
	item, err := u.techBreaks.UpsertTechBreak(ctx, input)
	if err != nil {
		return model.OperationTechBreak{}, err
	}
	action := "operations.tech_break.create"
	if input.ID > 0 {
		action = "operations.tech_break.update"
	}
	u.appendAudit(ctx, actor, action, "operation_tech_break", input.RequestID, map[string]any{
		"domainCode": input.DomainCode,
		"id":         item.ID,
	})
	return item, nil
}

func (u *OperationsUseCase) ArchiveTechBreak(ctx context.Context, actor *model.StaffUser, domainCode string, id int64, requestID string) error {
	if err := u.requireAccess(actor); err != nil {
		return err
	}
	if err := u.requireClients(); err != nil {
		return err
	}
	domainCode = normalizeOperationCode(domainCode)
	if domainCode == "" || id <= 0 {
		return ErrInvalidInput
	}
	if err := u.techBreaks.ArchiveTechBreak(ctx, id, domainCode); err != nil {
		return err
	}
	u.appendAudit(ctx, actor, "operations.tech_break.archive", "operation_tech_break", requestID, map[string]any{"domainCode": domainCode, "id": id})
	return nil
}

func (u *OperationsUseCase) GetScopeDetail(ctx context.Context, actor *model.StaffUser, domainCode string, id int64) (OperationsScopeDetailPage, error) {
	if err := u.requireAccess(actor); err != nil {
		return OperationsScopeDetailPage{}, err
	}
	if err := u.requireClients(); err != nil {
		return OperationsScopeDetailPage{}, err
	}
	domain, err := u.findDomain(ctx, domainCode)
	if err != nil {
		return OperationsScopeDetailPage{}, err
	}
	scope, err := u.techBreaks.GetScope(ctx, id, domain.Code)
	if err != nil {
		return OperationsScopeDetailPage{}, err
	}
	return OperationsScopeDetailPage{Domain: domain, Scope: scope}, nil
}

func (u *OperationsUseCase) SaveScope(ctx context.Context, actor *model.StaffUser, input model.OperationTechBreakScopeInput) (model.OperationTechBreakScope, error) {
	if err := u.requireAccess(actor); err != nil {
		return model.OperationTechBreakScope{}, err
	}
	if err := u.requireClients(); err != nil {
		return model.OperationTechBreakScope{}, err
	}
	input.DomainCode = normalizeOperationCode(input.DomainCode)
	input.Code = normalizeOperationCode(input.Code)
	input.Name = strings.TrimSpace(input.Name)
	input.Actor = actorIdentifier(actor)
	if input.DomainCode == "" || input.Code == "" || input.Name == "" {
		return model.OperationTechBreakScope{}, ErrInvalidInput
	}
	scope, err := u.techBreaks.UpsertScope(ctx, input)
	if err != nil {
		return model.OperationTechBreakScope{}, err
	}
	action := "operations.tech_break_scope.create"
	if input.ID > 0 {
		action = "operations.tech_break_scope.update"
	}
	u.appendAudit(ctx, actor, action, "operation_tech_break_scope", input.RequestID, map[string]any{
		"domainCode": input.DomainCode,
		"id":         scope.ID,
		"code":       scope.Code,
	})
	return scope, nil
}

func (u *OperationsUseCase) ArchiveScope(ctx context.Context, actor *model.StaffUser, domainCode string, id int64, requestID string) error {
	if err := u.requireAccess(actor); err != nil {
		return err
	}
	if err := u.requireClients(); err != nil {
		return err
	}
	domainCode = normalizeOperationCode(domainCode)
	if domainCode == "" || id <= 0 {
		return ErrInvalidInput
	}
	if err := u.techBreaks.ArchiveScope(ctx, id, domainCode); err != nil {
		return err
	}
	u.appendAudit(ctx, actor, "operations.tech_break_scope.archive", "operation_tech_break_scope", requestID, map[string]any{"domainCode": domainCode, "id": id})
	return nil
}

func (u *OperationsUseCase) requireAccess(actor *model.StaffUser) error {
	if actor == nil || !actor.HasRole(enum.StaffRoleSuperAdmin) {
		return ErrPermissionDenied
	}
	return nil
}

func (u *OperationsUseCase) requireClients() error {
	if u == nil || u.featureFlags == nil || u.techBreaks == nil {
		return ErrIntegrationNotReady
	}
	return nil
}

func (u *OperationsUseCase) findDomain(ctx context.Context, code string) (model.OperationDomain, error) {
	code = normalizeOperationCode(code)
	if code == "" {
		return model.OperationDomain{}, ErrInvalidInput
	}
	featureDomain, err := u.featureFlags.FindDomain(ctx, code)
	if err != nil {
		return model.OperationDomain{}, err
	}
	techDomain, err := u.techBreaks.FindDomain(ctx, code)
	if err != nil {
		return model.OperationDomain{}, err
	}
	var sources []model.OperationDomain
	if featureDomain != nil {
		sources = append(sources, *featureDomain)
	}
	if techDomain != nil {
		sources = append(sources, *techDomain)
	}
	merged := mergeOperationDomains(sources, nil)
	if len(merged) == 0 {
		return model.OperationDomain{}, ErrOperationDomainNotFound
	}
	return merged[0], nil
}

func mergeOperationDomains(primary []model.OperationDomain, secondary []model.OperationDomain) []model.OperationDomain {
	byCode := make(map[string]model.OperationDomain, len(primary)+len(secondary))
	for _, source := range append(append([]model.OperationDomain{}, primary...), secondary...) {
		code := normalizeOperationCode(source.Code)
		if code == "" {
			continue
		}
		source.Code = code
		current := byCode[code]
		byCode[code] = mergeOperationDomain(current, source)
	}
	out := make([]model.OperationDomain, 0, len(byCode))
	for _, item := range byCode {
		out = append(out, item)
	}
	sort.Slice(out, func(i, j int) bool {
		return out[i].Code < out[j].Code
	})
	return out
}

func mergeOperationDomain(current model.OperationDomain, source model.OperationDomain) model.OperationDomain {
	if current.Code == "" {
		current = source
	} else {
		if source.FeatureFlagServiceID > 0 {
			current.FeatureFlagServiceID = source.FeatureFlagServiceID
		}
		if source.TechBreakServiceID > 0 {
			current.TechBreakServiceID = source.TechBreakServiceID
		}
		if strings.TrimSpace(current.Description) == "" {
			current.Description = strings.TrimSpace(source.Description)
		}
		if current.CreatedAt.IsZero() || (!source.CreatedAt.IsZero() && source.CreatedAt.Before(current.CreatedAt)) {
			current.CreatedAt = source.CreatedAt
			current.CreatedBy = source.CreatedBy
		}
		if source.UpdatedAt != nil && (current.UpdatedAt == nil || source.UpdatedAt.After(*current.UpdatedAt)) {
			current.UpdatedAt = source.UpdatedAt
			current.UpdatedBy = source.UpdatedBy
		}
		current.FeatureFlagGroups = appendUniqueStrings(current.FeatureFlagGroups, source.FeatureFlagGroups...)
		current.TechBreakScopeDescriptions = appendUniqueStrings(current.TechBreakScopeDescriptions, source.TechBreakScopeDescriptions...)
	}
	current.Code = normalizeOperationCode(current.Code)
	current.Description = strings.TrimSpace(current.Description)
	current.FeatureFlagGroups = appendUniqueStrings(nil, current.FeatureFlagGroups...)
	current.TechBreakScopeDescriptions = appendUniqueStrings(nil, current.TechBreakScopeDescriptions...)
	return current
}

func operationDomainPage(domains []model.OperationDomain, page int, size int) model.OperationDomainPage {
	total := len(domains)
	start := page * size
	if start > total {
		start = total
	}
	end := start + size
	if end > total {
		end = total
	}
	totalPages := 0
	if total > 0 {
		totalPages = (total + size - 1) / size
	}
	return model.OperationDomainPage{
		Content:       append([]model.OperationDomain(nil), domains[start:end]...),
		Page:          page,
		Size:          size,
		TotalElements: int64(total),
		TotalPages:    totalPages,
	}
}

func normalizeOperationsPage(page int) int {
	if page < 0 {
		return 0
	}
	return page
}

func normalizeOperationsPageSize(size int) int {
	if size <= 0 {
		return defaultOperationsPageSize
	}
	if size > maxOperationsPageSize {
		return maxOperationsPageSize
	}
	return size
}

func normalizeOperationCode(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}

func appendUniqueStrings(base []string, values ...string) []string {
	seen := make(map[string]struct{}, len(base)+len(values))
	out := make([]string, 0, len(base)+len(values))
	for _, value := range append(append([]string{}, base...), values...) {
		normalized := strings.TrimSpace(value)
		if normalized == "" {
			continue
		}
		key := strings.ToLower(normalized)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, normalized)
	}
	return out
}

func actorIdentifier(actor *model.StaffUser) string {
	if actor == nil {
		return "admin-panel"
	}
	if email := strings.TrimSpace(actor.Email); email != "" {
		return email
	}
	if actor.ID != uuid.Nil {
		return actor.ID.String()
	}
	return "admin-panel"
}

func (u *OperationsUseCase) appendAudit(
	ctx context.Context,
	actor *model.StaffUser,
	action string,
	entityType string,
	requestID string,
	after any,
) {
	if u == nil || u.audit == nil || actor == nil {
		return
	}
	payload, _ := json.Marshal(after)
	_ = u.audit.Append(ctx, &model.AuditEvent{
		ID:               uuid.New(),
		ActorStaffID:     &actor.ID,
		ActorDisplayName: actor.DisplayName,
		ActorEmail:       actor.Email,
		Action:           action,
		EntityType:       entityType,
		RequestID:        strings.TrimSpace(requestID),
		AfterJSON:        payload,
		CreatedAt:        time.Now().UTC(),
	})
}
