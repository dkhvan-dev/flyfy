package http

import (
	"fmt"
	"strings"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

const adminMeetingMapStyleURL = "https://tiles.openfreemap.org/styles/liberty"

type meetingMapViewData struct {
	Latitude  float64
	Longitude float64
	StyleURL  string
	Title     string
	Address   string
	SourceURL string
}

func activityMeetingMap(_ string, item *model.ActivityModerationItem) *meetingMapViewData {
	if item == nil {
		return nil
	}
	sourceURL := safeExternalURL(stringValue(item.MapURL))
	if sourceURL == "" {
		sourceURL = safeExternalURL(stringValue(item.MeetingURL))
	}
	address := normalizeMeetingMapText(activityMeetingText(item))
	title := address
	if title == "" {
		title = normalizeMeetingMapText(item.Title)
	}
	return meetingMapFromLocation(item.Latitude, item.Longitude, sourceURL, title, address)
}

func excursionMeetingMap(locale string, item *model.ExcursionModerationItem) *meetingMapViewData {
	if item == nil {
		return nil
	}
	sourceURL := safeExternalURL(stringValue(item.MapURL))
	address := normalizeMeetingMapText(excursionMeetingPointText(locale, item))
	title := address
	if title == "" {
		title = normalizeMeetingMapText(excursionTitleText(locale, item, ""))
	}
	return meetingMapFromLocation(item.Latitude, item.Longitude, sourceURL, title, address)
}

func meetingMapFromLocation(
	latitude *float64,
	longitude *float64,
	sourceURL string,
	title string,
	address string,
) *meetingMapViewData {
	lat, lon, ok := meetingMapCoordinates(latitude, longitude, sourceURL)
	if !ok {
		return nil
	}
	return &meetingMapViewData{
		Latitude:  lat,
		Longitude: lon,
		StyleURL:  adminMeetingMapStyleURL,
		Title:     title,
		Address:   address,
		SourceURL: sourceURL,
	}
}

func meetingMapCoordinates(latitude *float64, longitude *float64, sourceURL string) (float64, float64, bool) {
	if latitude != nil && longitude != nil && validCoordinates(*latitude, *longitude) {
		return *latitude, *longitude, true
	}
	parsedLatitude, parsedLongitude, ok := coordinatesFromMapURL(sourceURL)
	if !ok || parsedLatitude == nil || parsedLongitude == nil {
		return 0, 0, false
	}
	if !validCoordinates(*parsedLatitude, *parsedLongitude) {
		return 0, 0, false
	}
	return *parsedLatitude, *parsedLongitude, true
}

func normalizeMeetingMapText(value string) string {
	value = strings.TrimSpace(value)
	if value == "" || value == "-" {
		return ""
	}
	return value
}

func meetingMapCoordinateText(lat float64, lon float64) string {
	return fmt.Sprintf("%.6f, %.6f", lat, lon)
}
