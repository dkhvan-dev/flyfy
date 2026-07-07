package app

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"kz/inflap/backend/services/search-service/internal/domain/model"
)

var ErrUnsupportedSearchEvent = errors.New("unsupported search event")

type SearchEventRepository interface {
	RecordSearchEvent(ctx context.Context, event model.SearchEvent) error
}

type SearchEventUseCase struct {
	repo SearchEventRepository
}

func NewSearchEventUseCase(repo SearchEventRepository) *SearchEventUseCase {
	return &SearchEventUseCase{repo: repo}
}

type TrackSearchEventInput struct {
	EventType       string
	SearchSessionID string
	Query           string
	Scope           string
	Domain          string
	EntityID        string
	ResultPosition  int
	Locale          string
	RequestID       string
	UserID          string
	AnonymousID     string
	Metadata        map[string]any
}

func (u *SearchEventUseCase) TrackEvent(ctx context.Context, input TrackSearchEventInput) error {
	eventType := strings.TrimSpace(input.EventType)
	if !IsKnownSearchEvent(eventType) {
		return fmt.Errorf("%w: %s", ErrUnsupportedSearchEvent, eventType)
	}

	scope, err := parseOptionalEventScope(input.Scope)
	if err != nil {
		return err
	}
	domain, err := parseOptionalEventDomain(input.Domain)
	if err != nil {
		return err
	}

	event := model.SearchEvent{
		EventType:       eventType,
		SearchSessionID: strings.TrimSpace(input.SearchSessionID),
		QueryHash:       hashSearchDiagnostic(input.Query),
		QueryLength:     len([]rune(strings.TrimSpace(input.Query))),
		UserIDHash:      hashSearchDiagnostic(input.UserID),
		AnonymousIDHash: hashSearchDiagnostic(input.AnonymousID),
		Scope:           scope,
		Domain:          domain,
		EntityID:        strings.TrimSpace(input.EntityID),
		ResultPosition:  input.ResultPosition,
		Locale:          normalizeLocale(input.Locale),
		RequestID:       strings.TrimSpace(input.RequestID),
		Metadata:        sanitizeEventMetadata(input.Metadata),
		CreatedAt:       time.Now().UTC(),
	}

	return u.repo.RecordSearchEvent(ctx, event)
}

func IsKnownSearchEvent(eventType string) bool {
	switch strings.TrimSpace(eventType) {
	case "search_started",
		"suggestion_clicked",
		"search_submitted",
		"result_clicked",
		"filter_changed",
		"zero_results",
		"search_failed":
		return true
	default:
		return false
	}
}

func parseOptionalEventScope(value string) (model.Scope, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return model.ScopeGlobal, nil
	}
	return model.ParseScope(value)
}

func parseOptionalEventDomain(value string) (*model.Domain, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil, nil
	}
	domain, err := model.ParseDomain(value)
	if err != nil {
		return nil, err
	}
	return &domain, nil
}

func hashSearchDiagnostic(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return ""
	}
	sum := sha256.Sum256([]byte(value))
	return hex.EncodeToString(sum[:])
}

func sanitizeEventMetadata(metadata map[string]any) map[string]any {
	if len(metadata) == 0 {
		return nil
	}
	result := make(map[string]any, len(metadata))
	for key, value := range metadata {
		key = strings.TrimSpace(key)
		if key == "" {
			continue
		}
		result[key] = value
	}
	return result
}
