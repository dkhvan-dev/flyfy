module kz/inflap/backend/services/routing-service

go 1.26

require (
	github.com/redis/go-redis/v9 v9.18.0
	github.com/rs/zerolog v1.35.0
	github.com/sethvargo/go-envconfig v1.3.0
	golang.org/x/text v0.35.0
	kz/inflap/backend/pkg/transportauth v0.0.0
)

require (
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/mattn/go-colorable v0.1.14 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	go.uber.org/atomic v1.11.0 // indirect
	golang.org/x/net v0.48.0 // indirect
	golang.org/x/sys v0.42.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20251202230838-ff82c1b0f217 // indirect
	google.golang.org/grpc v1.79.2 // indirect
	google.golang.org/protobuf v1.36.10 // indirect
)

replace kz/inflap/backend/pkg/transportauth => ../../pkg/transportauth
