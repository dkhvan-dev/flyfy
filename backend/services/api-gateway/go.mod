module kz/inflap/backend/services/api-gateway

go 1.26

require (
	github.com/google/uuid v1.6.0
	github.com/redis/go-redis/v9 v9.18.0
	github.com/rs/zerolog v1.34.0
	github.com/sethvargo/go-envconfig v1.3.0
	google.golang.org/grpc v1.79.2
	google.golang.org/protobuf v1.36.11
	kz/inflap/backend/pkg/serviceauth v0.0.0
	kz/inflap/backend/pkg/transportauth v0.0.0
	kz/inflap/proto v0.0.0
)

require (
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/go-jose/go-jose/v4 v4.1.3 // indirect
	github.com/mattn/go-colorable v0.1.13 // indirect
	github.com/mattn/go-isatty v0.0.19 // indirect
	go.uber.org/atomic v1.11.0 // indirect
	golang.org/x/net v0.48.0 // indirect
	golang.org/x/sys v0.39.0 // indirect
	golang.org/x/text v0.32.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20251202230838-ff82c1b0f217 // indirect
)

replace kz/inflap/proto => ../../../proto

replace kz/inflap/backend/pkg/serviceauth => ../../pkg/serviceauth

replace kz/inflap/backend/pkg/transportauth => ../../pkg/transportauth
