module kz/inflap/backend/services/currency-service

go 1.26

require (
	github.com/rs/zerolog v1.35.0
	github.com/sethvargo/go-envconfig v1.3.0
	kz/inflap/backend/pkg/switches v0.0.0
	kz/inflap/backend/pkg/transportauth v0.0.0
)

require (
	github.com/mattn/go-colorable v0.1.14 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	golang.org/x/net v0.48.0 // indirect
	golang.org/x/sys v0.39.0 // indirect
	golang.org/x/text v0.32.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20251202230838-ff82c1b0f217 // indirect
	google.golang.org/grpc v1.79.2 // indirect
	google.golang.org/protobuf v1.36.10 // indirect
)

replace kz/inflap/backend/pkg/switches => ../../pkg/switches

replace kz/inflap/backend/pkg/transportauth => ../../pkg/transportauth
