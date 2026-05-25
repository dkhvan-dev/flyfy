package http

import (
	"math"
	"testing"
)

func TestCoordinatesFromMapURLSupportsCommonProviders(t *testing.T) {
	t.Parallel()

	cases := map[string]struct {
		url  string
		lat  float64
		long float64
	}{
		"openstreetmap query": {
			url:  "https://www.openstreetmap.org/?mlat=43.24353420852949&mlon=76.90412855566406#map=16/43.24353420852949/76.90412855566406",
			lat:  43.24353420852949,
			long: 76.90412855566406,
		},
		"openstreetmap fragment": {
			url:  "https://www.openstreetmap.org/#map=16/43.2435342/76.9041286",
			lat:  43.2435342,
			long: 76.9041286,
		},
		"google maps place": {
			url:  "https://www.google.com/maps/place/Medeu/@43.157036,77.058482,17z",
			lat:  43.157036,
			long: 77.058482,
		},
		"google maps query": {
			url:  "https://maps.google.com/?q=43.157036,77.058482",
			lat:  43.157036,
			long: 77.058482,
		},
		"yandex maps ll": {
			url:  "https://yandex.kz/maps/?ll=76.9041286%2C43.2435342&z=16",
			lat:  43.2435342,
			long: 76.9041286,
		},
		"two gis m": {
			url:  "https://2gis.kz/almaty?m=76.9041286,43.2435342/16",
			lat:  43.2435342,
			long: 76.9041286,
		},
	}

	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			lat, long, ok := coordinatesFromMapURL(tc.url)
			if !ok || lat == nil || long == nil {
				t.Fatalf("coordinatesFromMapURL(%q) did not parse coordinates", tc.url)
			}
			if math.Abs(*lat-tc.lat) > 0.0000001 || math.Abs(*long-tc.long) > 0.0000001 {
				t.Fatalf("coordinates = %v,%v, want %v,%v", *lat, *long, tc.lat, tc.long)
			}
		})
	}
}
