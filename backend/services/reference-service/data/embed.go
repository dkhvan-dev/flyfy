package data

import "embed"

//go:embed countries.json cities.json currencies.json timezones.json
var FS embed.FS
