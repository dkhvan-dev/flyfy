package app

import (
	"context"
	"math"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"
)

const (
	DecisionValidity  = 20 * time.Second
	RenewalLeadTime   = 5 * time.Second
	MaxValidityWindow = 30 * time.Second
	MaxClockSkew      = 2 * time.Second
	MaxActorLength    = 200
	MaxReasonLength   = 1000
	MaxTicketLength   = 200
)

type State string

const (
	StateAvailable State = "AVAILABLE"
	StateLocked    State = "LOCKED"
)

func (state State) Valid() bool {
	return state == StateAvailable || state == StateLocked
}

type Decision struct {
	Revision   uint64    `json:"revision"`
	State      State     `json:"state"`
	IssuedAt   time.Time `json:"issued_at"`
	ValidUntil time.Time `json:"valid_until"`
}

type ChangeCommand struct {
	ExpectedRevision uint64
	State            State
	Actor            string
	Reason           string
	ChangeTicket     string
}

func (command ChangeCommand) normalized() ChangeCommand {
	command.Actor = strings.TrimSpace(command.Actor)
	command.Reason = strings.TrimSpace(command.Reason)
	command.ChangeTicket = strings.TrimSpace(command.ChangeTicket)
	return command
}

func (command ChangeCommand) valid() bool {
	return command.ExpectedRevision > 0 && command.ExpectedRevision <= math.MaxInt64 &&
		command.State.Valid() &&
		validBoundedText(command.Actor, MaxActorLength) &&
		validBoundedText(command.Reason, MaxReasonLength) &&
		validBoundedText(command.ChangeTicket, MaxTicketLength)
}

func validBoundedText(value string, maximum int) bool {
	if value == "" || !utf8.ValidString(value) || utf8.RuneCountInString(value) > maximum {
		return false
	}
	for _, character := range value {
		if unicode.IsControl(character) {
			return false
		}
	}
	return true
}

type Repository interface {
	ReadDecision(ctx context.Context) (Decision, error)
	ChangeState(ctx context.Context, command ChangeCommand) (Decision, error)
}

type Clock interface {
	Now() time.Time
}

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now() }
