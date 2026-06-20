package app

import (
	"testing"
	"time"
)

func TestValidateTechBreakUpsertRejectsInvalidDateRange(t *testing.T) {
	start := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	req := TechBreakUpsertRequest{
		DomainCode:      "CORE",
		Name:            "Core outage",
		ActionStartDate: start,
		ActionEndDate:   &start,
	}

	err := ValidateTechBreakUpsert(req)

	if err == nil || err.Error() != "Дата начала действия не может быть позже или равной дате окончания" {
		t.Fatalf("expected invalid date validation error, got %v", err)
	}
}

func TestComputeTechBreakEnabledMatchesSourceRules(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 59, 0, time.UTC)
	start := now.Add(-time.Minute)
	end := now.Add(time.Minute)

	if !ComputeTechBreakEnabled(start, &end, now) {
		t.Fatal("expected current tech break to be enabled")
	}

	futureStart := now.Add(time.Minute)
	if ComputeTechBreakEnabled(futureStart, nil, now) {
		t.Fatal("expected future tech break to be disabled")
	}

	pastEnd := now.Add(-time.Minute)
	if ComputeTechBreakEnabled(start, &pastEnd, now) {
		t.Fatal("expected expired tech break to be disabled")
	}
}

func TestActiveBreakMatchesRequestFilters(t *testing.T) {
	breaks := []TechBreakDetail{
		{
			ID:               1,
			Enabled:          true,
			ExcludeEmails:    []string{"skip@test.kz"},
			ExcludeNicknames: []string{"skipNick"},
			ScopeCodes:       []string{"EMAIL_OTP"},
		},
	}

	if ActiveBreakMatches(breaks[0], TechBreakCheckRequest{
		DomainCode: "CORE",
		Email:      "skip@test.kz",
		ScopeCodes: []string{"EMAIL_OTP"},
	}) {
		t.Fatal("excluded email must bypass active break")
	}

	if !ActiveBreakMatches(breaks[0], TechBreakCheckRequest{
		DomainCode: "CORE",
		Email:      "user@test.kz",
		ScopeCodes: []string{"EMAIL_OTP"},
	}) {
		t.Fatal("matching scope must hit active break")
	}

	if ActiveBreakMatches(breaks[0], TechBreakCheckRequest{
		DomainCode: "CORE",
		Email:      "user@test.kz",
		ScopeCodes: []string{"PHONE_OTP"},
	}) {
		t.Fatal("non-matching scope must not hit active break")
	}
}
