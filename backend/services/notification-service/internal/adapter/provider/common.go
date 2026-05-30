package provider

import (
	"strconv"
	"time"
)

func retryAfter(raw string) time.Duration {
	if raw == "" {
		return 0
	}
	seconds, err := strconv.Atoi(raw)
	if err == nil && seconds > 0 {
		return time.Duration(seconds) * time.Second
	}
	if when, err := time.Parse(time.RFC1123, raw); err == nil {
		return time.Until(when)
	}
	return 0
}
