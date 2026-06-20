package app

import (
	"testing"
	"time"
)

func TestValidateFeatureFlagCreateRejectsEnabledFutureStart(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 45, 0, time.UTC)
	req := FeatureFlagCreateRequest{
		DomainCode:      "ONBOARDING",
		Code:            "SKIP_EMAIL_OTP",
		Name:            "Skip email OTP",
		Group:           "General",
		Type:            FeatureFlagTypeToggle,
		Enabled:         true,
		ActionStartDate: now.Add(time.Hour),
		Value:           []any{},
	}

	err := ValidateFeatureFlagCreate(req, now)

	if err == nil || err.Error() != "Нельзя включать флаг с будущей датой начала действия. Планировщик сам включит флаг в указанную дату и время!" {
		t.Fatalf("expected future enabled validation error, got %v", err)
	}
}

func TestValidateFeatureFlagCreateRequiresValueForArrayType(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	req := FeatureFlagCreateRequest{
		DomainCode:      "PAYMENT",
		Code:            "SKIP_PAYMENT",
		Name:            "Skip payment",
		Group:           "General",
		Type:            FeatureFlagTypeArrayString,
		Enabled:         false,
		ActionStartDate: now,
		Value:           []any{},
	}

	err := ValidateFeatureFlagCreate(req, now)

	if err == nil || err.Error() != "Не заполнен список значений" {
		t.Fatalf("expected required value validation error, got %v", err)
	}
}

func TestValidateFeatureFlagCreateRejectsWrongValueType(t *testing.T) {
	now := time.Date(2026, 1, 10, 15, 30, 0, 0, time.UTC)
	req := FeatureFlagCreateRequest{
		DomainCode:      "CORE",
		Code:            "ALLOWED_USERS",
		Name:            "Allowed users",
		Group:           "General",
		Type:            FeatureFlagTypeArrayInteger,
		Enabled:         false,
		ActionStartDate: now,
		Value:           []any{"not-int"},
	}

	err := ValidateFeatureFlagCreate(req, now)

	if err == nil || err.Error() != "Тип данных значения флага должен быть в соответствии с типом фича флага" {
		t.Fatalf("expected wrong value type validation error, got %v", err)
	}
}

func TestNormalizeFeatureFlagValueConvertsIntegersAndBooleans(t *testing.T) {
	ints, err := NormalizeFeatureFlagValue(FeatureFlagTypeArrayInteger, []string{"10", "20"})
	if err != nil {
		t.Fatalf("normalize integer values: %v", err)
	}
	if ints[0].(int) != 10 || ints[1].(int) != 20 {
		t.Fatalf("unexpected integer values: %#v", ints)
	}

	toggles, err := NormalizeFeatureFlagValue(FeatureFlagTypeToggle, []string{"true"})
	if err != nil {
		t.Fatalf("normalize toggle values: %v", err)
	}
	if toggles[0].(bool) != true {
		t.Fatalf("unexpected toggle value: %#v", toggles)
	}
}
