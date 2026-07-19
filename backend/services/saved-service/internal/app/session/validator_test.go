package session

import (
	"errors"
	"testing"
)

func TestValidateInput(t *testing.T) {
	t.Parallel()

	const (
		subject    = "f4b3b8f7-c75d-4f8a-b89b-ad2b50113b98"
		generation = "a387fd94-d8f4-4434-9d3e-edf8db0a614e"
	)

	tests := []struct {
		name       string
		subject    string
		generation string
		wantErr    error
	}{
		{name: "valid", subject: subject, generation: generation},
		{name: "empty subject", generation: generation, wantErr: ErrInvalidSubject},
		{name: "nil subject", subject: "00000000-0000-0000-0000-000000000000", generation: generation, wantErr: ErrInvalidSubject},
		{name: "uppercase subject", subject: "F4B3B8F7-C75D-4F8A-B89B-AD2B50113B98", generation: generation, wantErr: ErrInvalidSubject},
		{name: "compact subject", subject: "f4b3b8f7c75d4f8ab89bad2b50113b98", generation: generation, wantErr: ErrInvalidSubject},
		{name: "foreign subject format", subject: "{f4b3b8f7-c75d-4f8a-b89b-ad2b50113b98}", generation: generation, wantErr: ErrInvalidSubject},
		{name: "empty generation", subject: subject, wantErr: ErrInvalidSessionGeneration},
		{name: "nil generation", subject: subject, generation: "00000000-0000-0000-0000-000000000000", wantErr: ErrInvalidSessionGeneration},
		{name: "uppercase generation", subject: subject, generation: "A387FD94-D8F4-4434-9D3E-EDF8DB0A614E", wantErr: ErrInvalidSessionGeneration},
		{name: "generation with whitespace", subject: subject, generation: " a387fd94-d8f4-4434-9d3e-edf8db0a614e", wantErr: ErrInvalidSessionGeneration},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			err := ValidateInput(tt.subject, tt.generation)
			if !errors.Is(err, tt.wantErr) {
				t.Fatalf("ValidateInput() error = %v, want %v", err, tt.wantErr)
			}
		})
	}
}

func TestContractViolationIsClassifiedAsDependencyUnavailable(t *testing.T) {
	t.Parallel()

	if !errors.Is(ErrContractViolation, ErrDependencyUnavailable) {
		t.Fatal("ErrContractViolation must fail closed as ErrDependencyUnavailable")
	}
}
