package app

import "time"

type Clock interface {
	Now() time.Time
}

type ClockFunc func() time.Time

func (f ClockFunc) Now() time.Time {
	return f()
}

type systemClock struct{}

func NewSystemClock() Clock {
	return systemClock{}
}

func (systemClock) Now() time.Time {
	return time.Now()
}

func TruncateToMinute(value time.Time) time.Time {
	return value.Truncate(time.Minute)
}

func TruncatePtrToMinute(value *time.Time) *time.Time {
	if value == nil {
		return nil
	}
	truncated := TruncateToMinute(*value)
	return &truncated
}
