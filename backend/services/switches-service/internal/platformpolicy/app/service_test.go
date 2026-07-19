package app

import (
	"context"
	"errors"
	"testing"
	"time"
)

func TestServiceReadDecisionAlwaysUsesRepository(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 0, 0, 0, time.UTC)
	repository := &fakeRepository{decision: validDecision(now, 7, StateAvailable)}
	service := NewService(repository, fixedClock(now))

	for range 2 {
		decision, err := service.ReadDecision(context.Background())
		if err != nil {
			t.Fatalf("ReadDecision() error = %v", err)
		}
		if decision.Revision != 7 || decision.State != StateAvailable {
			t.Fatalf("ReadDecision() = %#v", decision)
		}
	}
	if repository.readCalls != 2 {
		t.Fatalf("repository reads = %d, want 2", repository.readCalls)
	}
}

func TestServiceReadDecisionFailsClosedForMalformedRepositoryState(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 0, 0, 0, time.UTC)
	repository := &fakeRepository{decision: validDecision(now, 0, StateAvailable)}
	service := NewService(repository, fixedClock(now))

	_, err := service.ReadDecision(context.Background())
	if !errors.Is(err, ErrUnavailable) {
		t.Fatalf("ReadDecision() error = %v, want ErrUnavailable", err)
	}
}

func TestServiceChangeStateNormalizesMetadata(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 0, 0, 0, time.UTC)
	repository := &fakeRepository{decision: validDecision(now, 8, StateLocked)}
	service := NewService(repository, fixedClock(now))

	decision, err := service.ChangeState(context.Background(), ChangeCommand{
		ExpectedRevision: 7,
		State:            StateLocked,
		Actor:            "  admin-subject  ",
		Reason:           "  Incident response  ",
		ChangeTicket:     "  INC-123  ",
	})
	if err != nil {
		t.Fatalf("ChangeState() error = %v", err)
	}
	if decision.Revision != 8 {
		t.Fatalf("revision = %d, want 8", decision.Revision)
	}
	if repository.lastCommand.Actor != "admin-subject" ||
		repository.lastCommand.Reason != "Incident response" ||
		repository.lastCommand.ChangeTicket != "INC-123" {
		t.Fatalf("normalized command = %#v", repository.lastCommand)
	}
}

func TestServiceChangeStateRejectsUnknownStateAndMissingAuditMetadata(t *testing.T) {
	t.Parallel()

	service := NewService(&fakeRepository{}, fixedClock(time.Now()))
	for _, command := range []ChangeCommand{
		{ExpectedRevision: 1, State: "available", Actor: "admin", Reason: "reason", ChangeTicket: "INC-1"},
		{ExpectedRevision: 1, State: StateLocked, Actor: "admin", Reason: " ", ChangeTicket: "INC-1"},
		{ExpectedRevision: 1, State: StateLocked, Actor: "admin", Reason: "reason", ChangeTicket: " "},
		{ExpectedRevision: 1, State: StateLocked, Actor: "admin", Reason: "bad\x00reason", ChangeTicket: "INC-1"},
	} {
		if _, err := service.ChangeState(context.Background(), command); !errors.Is(err, ErrInvalidCommand) {
			t.Fatalf("ChangeState(%#v) error = %v, want ErrInvalidCommand", command, err)
		}
	}
}

func TestServiceChangeStatePreservesSafeConflicts(t *testing.T) {
	t.Parallel()

	repository := &fakeRepository{err: ErrStateUnchanged}
	service := NewService(repository, fixedClock(time.Now()))
	_, err := service.ChangeState(context.Background(), ChangeCommand{
		ExpectedRevision: 1,
		State:            StateLocked,
		Actor:            "admin",
		Reason:           "reason",
		ChangeTicket:     "INC-1",
	})
	if !errors.Is(err, ErrStateUnchanged) {
		t.Fatalf("ChangeState() error = %v, want ErrStateUnchanged", err)
	}
}

type fakeRepository struct {
	decision    Decision
	err         error
	readCalls   int
	lastCommand ChangeCommand
}

func (repository *fakeRepository) ReadDecision(context.Context) (Decision, error) {
	repository.readCalls++
	return repository.decision, repository.err
}

func (repository *fakeRepository) ChangeState(_ context.Context, command ChangeCommand) (Decision, error) {
	repository.lastCommand = command
	return repository.decision, repository.err
}

type fixedClock time.Time

func (clock fixedClock) Now() time.Time { return time.Time(clock) }

func validDecision(now time.Time, revision uint64, state State) Decision {
	return Decision{
		Revision:   revision,
		State:      state,
		IssuedAt:   now.Add(-time.Second),
		ValidUntil: now.Add(19 * time.Second),
	}
}
