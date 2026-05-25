package http

import (
	"net/url"
	"regexp"
	"strconv"
	"strings"
)

var coordinatePairPattern = regexp.MustCompile(`(?i)(?:@|=|/|,|\s)([-+]?\d{1,2}(?:\.\d+)?),\s*([-+]?\d{1,3}(?:\.\d+)?)`)

func coordinatesFromMapURL(raw string) (*float64, *float64, bool) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil, false
	}

	parsed, err := url.Parse(raw)
	if err != nil {
		return coordinatesFromCoordinatePair(raw)
	}

	query := parsed.Query()
	if lat, lon, ok := coordinatesFromQueryPair(query, "mlat", "mlon", false); ok {
		return lat, lon, true
	}
	if lat, lon, ok := coordinatesFromQueryPair(query, "lat", "lon", false); ok {
		return lat, lon, true
	}
	if lat, lon, ok := coordinatesFromQueryPair(query, "latitude", "longitude", false); ok {
		return lat, lon, true
	}
	if lat, lon, ok := coordinatesFromQueryPair(query, "ll", "ll", true); ok {
		return lat, lon, true
	}
	if lat, lon, ok := coordinatesFromQueryPair(query, "m", "m", true); ok {
		return lat, lon, true
	}

	for _, key := range []string{"q", "query", "center"} {
		if lat, lon, ok := coordinatesFromCoordinatePair(query.Get(key)); ok {
			return lat, lon, true
		}
	}

	if lat, lon, ok := coordinatesFromOSMFragment(parsed.Fragment); ok {
		return lat, lon, true
	}
	if lat, lon, ok := coordinatesFromCoordinatePair(parsed.Path); ok {
		return lat, lon, true
	}
	if lat, lon, ok := coordinatesFromCoordinatePair(parsed.Fragment); ok {
		return lat, lon, true
	}
	return coordinatesFromCoordinatePair(raw)
}

func coordinatesFromQueryPair(values url.Values, latKey string, lonKey string, reversed bool) (*float64, *float64, bool) {
	if latKey == lonKey {
		return coordinatesFromDelimitedPair(values.Get(latKey), reversed)
	}
	return coordinatesFromValues(values.Get(latKey), values.Get(lonKey), reversed)
}

func coordinatesFromDelimitedPair(raw string, reversed bool) (*float64, *float64, bool) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil, false
	}
	raw = strings.ReplaceAll(raw, "%2C", ",")
	raw = strings.ReplaceAll(raw, "%2c", ",")
	parts := strings.Split(raw, ",")
	if len(parts) < 2 {
		return nil, nil, false
	}
	return coordinatesFromValues(parts[0], parts[1], reversed)
}

func coordinatesFromOSMFragment(fragment string) (*float64, *float64, bool) {
	fragment = strings.TrimSpace(fragment)
	if fragment == "" {
		return nil, nil, false
	}
	for _, part := range strings.Split(fragment, "&") {
		if !strings.HasPrefix(part, "map=") {
			continue
		}
		segments := strings.Split(strings.TrimPrefix(part, "map="), "/")
		if len(segments) < 3 {
			return nil, nil, false
		}
		return coordinatesFromValues(segments[1], segments[2], false)
	}
	return nil, nil, false
}

func coordinatesFromCoordinatePair(raw string) (*float64, *float64, bool) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil, false
	}
	if unescaped, err := url.QueryUnescape(raw); err == nil {
		raw = unescaped
	}
	if lat, lon, ok := coordinatesFromDelimitedPair(raw, false); ok {
		return lat, lon, true
	}
	matches := coordinatePairPattern.FindStringSubmatch(raw)
	if len(matches) != 3 {
		return nil, nil, false
	}
	return coordinatesFromValues(matches[1], matches[2], false)
}

func coordinatesFromValues(first string, second string, reversed bool) (*float64, *float64, bool) {
	firstValue, err := parseCoordinateValue(first)
	if err != nil {
		return nil, nil, false
	}
	secondValue, err := parseCoordinateValue(second)
	if err != nil {
		return nil, nil, false
	}
	lat, lon := firstValue, secondValue
	if reversed {
		lat, lon = secondValue, firstValue
	}
	if !validCoordinates(lat, lon) {
		return nil, nil, false
	}
	return &lat, &lon, true
}

func parseCoordinateValue(raw string) (float64, error) {
	value := strings.TrimSpace(raw)
	for _, separator := range []string{"/", "?", "&", "#", " "} {
		if index := strings.Index(value, separator); index >= 0 {
			value = value[:index]
		}
	}
	return strconv.ParseFloat(value, 64)
}

func validCoordinates(lat float64, lon float64) bool {
	return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180
}
