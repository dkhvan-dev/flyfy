package http

import "testing"

func TestParseOptionalReferenceCityIDAcceptsReferenceSlug(t *testing.T) {
	raw := "almaty"

	cityID, err := parseOptionalReferenceCityID(&raw)

	if err != nil {
		t.Fatalf("parseOptionalReferenceCityID() error = %v", err)
	}
	if cityID == nil || *cityID != raw {
		t.Fatalf("cityID = %v, want %q", cityID, raw)
	}
}

func TestParseOptionalReferenceCityIDRejectsInvalidCharacters(t *testing.T) {
	raw := "Алматы"

	if _, err := parseOptionalReferenceCityID(&raw); err == nil {
		t.Fatal("parseOptionalReferenceCityID() error = nil, want validation error")
	}
}
