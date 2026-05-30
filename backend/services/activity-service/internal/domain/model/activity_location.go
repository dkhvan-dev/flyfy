package model

import (
	"errors"
	"strings"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
)

var (
	ErrInvalidLocationFormat = errors.New("invalid activity location format")
)

type ActivityLocation struct {
	Format      enum.ActivityFormat
	CountryCode *string
	CityID      *string
	CityName    *string
	AddressText *string
	Latitude    *float64
	Longitude   *float64
	MapURL      *string
	MeetingURL  *string
}

func NewActivityLocation(
	format enum.ActivityFormat,
	countryCode *string,
	cityID *string,
	cityName *string,
	addressText *string,
	latitude *float64,
	longitude *float64,
	mapURL *string,
	meetingURL *string,
) (*ActivityLocation, error) {
	item := &ActivityLocation{
		Format:      format,
		CountryCode: NormalizeOptionalString(countryCode),
		CityID:      NormalizeOptionalString(cityID),
		CityName:    NormalizeOptionalString(cityName),
		AddressText: NormalizeOptionalString(addressText),
		Latitude:    latitude,
		Longitude:   longitude,
		MapURL:      NormalizeOptionalString(mapURL),
		MeetingURL:  NormalizeOptionalString(meetingURL),
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

func (l *ActivityLocation) Validate() error {
	if !l.Format.IsValid() {
		return ErrInvalidLocationFormat
	}

	switch l.Format {
	case enum.ActivityFormatOnline:
		if l.MeetingURL == nil || strings.TrimSpace(*l.MeetingURL) == "" {
			return ErrInvalidMeetingURL
		}
	case enum.ActivityFormatOffline:
		if l.CountryCode == nil &&
			l.CityID == nil &&
			l.CityName == nil &&
			l.AddressText == nil &&
			l.MapURL == nil {
			return ErrInvalidOfflineLocation
		}
	case enum.ActivityFormatHybrid:
		if (l.MeetingURL == nil || strings.TrimSpace(*l.MeetingURL) == "") &&
			l.CountryCode == nil &&
			l.CityID == nil &&
			l.CityName == nil &&
			l.AddressText == nil &&
			l.MapURL == nil {
			return ErrInvalidOfflineLocation
		}
	}

	return nil
}

func (l *ActivityLocation) IsOnlineAvailable() bool {
	return l.MeetingURL != nil && strings.TrimSpace(*l.MeetingURL) != ""
}

func (l *ActivityLocation) IsOfflineAvailable() bool {
	return l.CountryCode != nil ||
		l.CityID != nil ||
		l.CityName != nil ||
		l.AddressText != nil ||
		l.MapURL != nil
}
