module kz/inflap/backend/services/currency-service

go 1.26

require (
	github.com/rs/zerolog v1.35.0
	github.com/sethvargo/go-envconfig v1.3.0
	kz/inflap/backend/pkg/switches v0.0.0
)

require (
	github.com/mattn/go-colorable v0.1.14 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	golang.org/x/sys v0.29.0 // indirect
)

replace kz/inflap/backend/pkg/switches => ../../pkg/switches
