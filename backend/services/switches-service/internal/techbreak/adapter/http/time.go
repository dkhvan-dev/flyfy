package http

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

type localTime struct {
	time.Time
}

func (t *localTime) UnmarshalJSON(data []byte) error {
	var raw string
	if err := json.Unmarshal(data, &raw); err != nil {
		return err
	}
	parsed, err := parseLocalTime(raw)
	if err != nil {
		return err
	}
	t.Time = parsed
	return nil
}

func parseLocalTime(raw string) (time.Time, error) {
	value := strings.TrimSpace(raw)
	if value == "" {
		return time.Time{}, nil
	}
	layouts := []string{time.RFC3339, "2006-01-02T15:04:05", "2006-01-02 15:04:05"}
	for _, layout := range layouts {
		parsed, err := time.Parse(layout, value)
		if err == nil {
			return parsed, nil
		}
	}
	return time.Time{}, fmt.Errorf("invalid date-time %q", raw)
}

func parseOptionalLocalTime(raw string) (*time.Time, error) {
	if strings.TrimSpace(raw) == "" {
		return nil, nil
	}
	parsed, err := parseLocalTime(raw)
	if err != nil {
		return nil, err
	}
	return &parsed, nil
}

func localTimePtr(value *localTime) *time.Time {
	if value == nil {
		return nil
	}
	return &value.Time
}
