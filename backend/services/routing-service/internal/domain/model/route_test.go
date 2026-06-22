package model

import "testing"

func TestRoutePointValidationRejectsInvalidCoordinates(t *testing.T) {
	tests := []struct {
		name  string
		point RoutePoint
	}{
		{
			name:  "latitude below world bounds",
			point: RoutePoint{Latitude: -91, Longitude: 76.945},
		},
		{
			name:  "latitude above world bounds",
			point: RoutePoint{Latitude: 91, Longitude: 76.945},
		},
		{
			name:  "longitude below world bounds",
			point: RoutePoint{Latitude: 43.238, Longitude: -181},
		},
		{
			name:  "longitude above world bounds",
			point: RoutePoint{Latitude: 43.238, Longitude: 181},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := tt.point.Validate(); err == nil {
				t.Fatal("Validate() error = nil, want coordinate validation error")
			}
		})
	}
}

func TestRouteRequestValidationDefaultsProfileAndRequiresTwoPoints(t *testing.T) {
	req := RouteRequest{
		Mode: RouteModeWalking,
		Points: []RoutePoint{
			{Latitude: 43.238949, Longitude: 76.889709, Name: "Hotel"},
			{Latitude: 43.255058, Longitude: 76.912628, Name: "Kok Tobe"},
		},
	}

	if err := req.NormalizeAndValidate(); err != nil {
		t.Fatalf("NormalizeAndValidate() error = %v", err)
	}
	if req.Profile != RouteProfileTouristWalk {
		t.Fatalf("Profile = %q, want %q", req.Profile, RouteProfileTouristWalk)
	}
	if req.Points[0].Name != "Hotel" {
		t.Fatalf("point name was unexpectedly changed: %q", req.Points[0].Name)
	}

	req.Points = req.Points[:1]
	if err := req.NormalizeAndValidate(); err == nil {
		t.Fatal("NormalizeAndValidate() error = nil, want error for one-point route")
	}
}

func TestRouteProfilesExposeClientSafeMetadata(t *testing.T) {
	profiles := DefaultRouteProfiles()

	if len(profiles) != 7 {
		t.Fatalf("profile count = %d, want 7", len(profiles))
	}

	want := map[RouteProfile]RouteMode{
		RouteProfileTouristWalk: RouteModeWalking,
		RouteProfileFastWalk:    RouteModeWalking,
		RouteProfileBikeCity:    RouteModeCycling,
		RouteProfileCarStandard: RouteModeDriving,
		RouteProfileGuideRoute:  RouteModeWalking,
		RouteProfileDayPlan:     RouteModeWalking,
		RouteProfileTransit:     RouteModeTransit,
	}

	for _, profile := range profiles {
		if profile.ID == "" || profile.Label == "" || profile.Description == "" {
			t.Fatalf("profile has empty client metadata: %#v", profile)
		}
		if got, ok := want[profile.ID]; !ok || got != profile.Mode {
			t.Fatalf("profile %q mode = %q, want %q", profile.ID, profile.Mode, got)
		}
	}
}
