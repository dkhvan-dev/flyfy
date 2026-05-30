package model

import (
	"testing"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
)

func TestActivityLocationAcceptsCityIDAsOfflineLocation(t *testing.T) {
	cityID := "almaty"

	location, err := NewActivityLocation(
		enum.ActivityFormatOffline,
		nil,
		&cityID,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
	)

	if err != nil {
		t.Fatalf("NewActivityLocation() error = %v", err)
	}
	if location.CityID == nil || *location.CityID != cityID {
		t.Fatalf("CityID = %v, want %v", location.CityID, cityID)
	}
}
