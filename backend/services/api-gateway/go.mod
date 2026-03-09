module github.com/dkhvan-dev/flyfy/backend/services/api-gateway

go 1.26

require (
	github.com/dkhvan-dev/flyfy/proto v0.0.0
	github.com/google/uuid v1.6.0
	github.com/rs/zerolog v1.34.0
	github.com/sethvargo/go-envconfig v1.3.0
	google.golang.org/grpc v1.79.2
)

require (
	github.com/mattn/go-colorable v0.1.13 // indirect
	github.com/mattn/go-isatty v0.0.19 // indirect
	golang.org/x/net v0.48.0 // indirect
	golang.org/x/sys v0.39.0 // indirect
	golang.org/x/text v0.32.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20251202230838-ff82c1b0f217 // indirect
	google.golang.org/protobuf v1.36.11 // indirect
)

replace github.com/dkhvan-dev/flyfy/proto => ../../../proto
