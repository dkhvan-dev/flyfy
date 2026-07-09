package provider

import (
	"testing"

	"kz/inflap/backend/services/notification-service/internal/domain/model"
)

func TestAndroidChannelIDRoutesLegacyChecklistPayloadsToSystemChannel(t *testing.T) {
	channelID := androidChannelID(model.Delivery{
		Category: "checklist",
		Payload: model.NotificationPayload{
			Data: map[string]string{"checklistTripId": "trip-bali-jan"},
		},
	})

	if channelID != "inflap_system" {
		t.Fatalf("channelID = %q, want inflap_system", channelID)
	}
}
