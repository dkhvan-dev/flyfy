package app

import (
	"errors"
	"testing"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
)

func TestActivityLocationPolicyRejectsLatitudeWithoutLongitude(t *testing.T) {
	policy := NewPolicyService(nil)
	lat := 43.238949
	country := "KZ"
	city := "Almaty"

	err := policy.ValidateActivityLocation(enum.ActivityFormatOffline, &country, nil, &city, nil, &lat, nil, nil, nil)

	if !errors.Is(err, ErrActivityLocationCoordinatesRequired) {
		t.Fatalf("error = %v, want %v", err, ErrActivityLocationCoordinatesRequired)
	}
}

func TestActivityLocationPolicyRejectsCoordinatesOutOfRange(t *testing.T) {
	policy := NewPolicyService(nil)
	lat := 91.0
	lng := 76.889709
	country := "KZ"
	city := "Almaty"

	err := policy.ValidateActivityLocation(enum.ActivityFormatOffline, &country, nil, &city, nil, &lat, &lng, nil, nil)

	if !errors.Is(err, ErrActivityLocationCoordinatesInvalid) {
		t.Fatalf("error = %v, want %v", err, ErrActivityLocationCoordinatesInvalid)
	}
}

func TestActivityLocationPolicyRejectsOnlineActivityWithOfflineLocation(t *testing.T) {
	policy := NewPolicyService(nil)
	meetingURL := "https://meet.example.com/session"
	country := "KZ"

	err := policy.ValidateActivityLocation(enum.ActivityFormatOnline, &country, nil, nil, nil, nil, nil, nil, &meetingURL)

	if !errors.Is(err, ErrActivityLocationOfflineFieldsForbidden) {
		t.Fatalf("error = %v, want %v", err, ErrActivityLocationOfflineFieldsForbidden)
	}
}

func TestActivityLocationPolicyRejectsOfflineActivityWithMeetingURL(t *testing.T) {
	policy := NewPolicyService(nil)
	lat := 43.238949
	lng := 76.889709
	country := "KZ"
	city := "Almaty"
	meetingURL := "https://meet.example.com/session"

	err := policy.ValidateActivityLocation(enum.ActivityFormatOffline, &country, nil, &city, nil, &lat, &lng, nil, &meetingURL)

	if !errors.Is(err, ErrActivityLocationMeetingURLForbidden) {
		t.Fatalf("error = %v, want %v", err, ErrActivityLocationMeetingURLForbidden)
	}
}

func TestActivityLocationPolicyAcceptsHybridWithOnlineAndCompleteOfflineLocation(t *testing.T) {
	policy := NewPolicyService(nil)
	lat := 43.238949
	lng := 76.889709
	country := "KZ"
	city := "Almaty"
	meetingURL := "https://meet.example.com/session"

	err := policy.ValidateActivityLocation(enum.ActivityFormatHybrid, &country, nil, &city, nil, &lat, &lng, nil, &meetingURL)

	if err != nil {
		t.Fatalf("ValidateActivityLocation() error = %v", err)
	}
}
