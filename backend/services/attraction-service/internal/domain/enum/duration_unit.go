package enum

type DurationUnit string

const (
	DurationHours DurationUnit = "HOURS"
	DurationDays  DurationUnit = "DAYS"
)

func (d DurationUnit) IsValid() bool {
	return d == DurationHours || d == DurationDays
}

func (d DurationUnit) String() string {
	return string(d)
}
