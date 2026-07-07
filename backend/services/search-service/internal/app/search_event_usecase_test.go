package app

import (
	"context"
	"testing"

	"kz/inflap/backend/services/search-service/internal/domain/model"
)

func TestSearchEventUseCaseStoresOnlyPrivacySafeDiagnostics(t *testing.T) {
	repo := &fakeSearchEventRepository{}
	uc := NewSearchEventUseCase(repo)

	err := uc.TrackEvent(context.Background(), TrackSearchEventInput{
		EventType:       "result_clicked",
		SearchSessionID: "session-1",
		Query:           "ada@example.com private trip",
		Scope:           "global",
		Domain:          "user",
		EntityID:        "user-1",
		ResultPosition:  3,
		Locale:          "RU",
		RequestID:       "request-1",
		UserID:          "user-private-id",
	})
	if err != nil {
		t.Fatalf("TrackEvent returned error: %v", err)
	}
	if repo.calls != 1 {
		t.Fatalf("repository calls = %d, want 1", repo.calls)
	}
	event := repo.lastEvent
	if event.EventType != "result_clicked" ||
		event.SearchSessionID != "session-1" ||
		event.Scope != model.ScopeGlobal ||
		event.Domain == nil ||
		*event.Domain != model.DomainUser ||
		event.EntityID != "user-1" ||
		event.ResultPosition != 3 ||
		event.Locale != "ru" ||
		event.RequestID != "request-1" {
		t.Fatalf("event = %+v", event)
	}
	if event.QueryHash == "" || event.UserIDHash == "" {
		t.Fatalf("hashes must be populated: %+v", event)
	}
	if event.QueryHash == "ada@example.com private trip" || event.UserIDHash == "user-private-id" {
		t.Fatalf("raw private values were stored: %+v", event)
	}
	if event.QueryLength != len([]rune("ada@example.com private trip")) {
		t.Fatalf("query length = %d", event.QueryLength)
	}
}

func TestSearchEventUseCaseRejectsUnsupportedEventType(t *testing.T) {
	repo := &fakeSearchEventRepository{}
	uc := NewSearchEventUseCase(repo)

	err := uc.TrackEvent(context.Background(), TrackSearchEventInput{EventType: "unknown"})
	if err == nil {
		t.Fatal("TrackEvent returned nil, want error")
	}
	if repo.calls != 0 {
		t.Fatalf("repository calls = %d, want 0", repo.calls)
	}
}

type fakeSearchEventRepository struct {
	calls     int
	lastEvent model.SearchEvent
}

func (r *fakeSearchEventRepository) RecordSearchEvent(_ context.Context, event model.SearchEvent) error {
	r.calls++
	r.lastEvent = event
	return nil
}
