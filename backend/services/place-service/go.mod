module kz/inflap/backend/services/place-service

go 1.26

require (
	github.com/google/uuid v1.6.0
	github.com/jackc/pgx/v5 v5.8.0
	github.com/nats-io/nats.go v1.51.0
	github.com/redis/go-redis/v9 v9.18.0
	github.com/rs/zerolog v1.35.1
	github.com/sethvargo/go-envconfig v1.3.0
	google.golang.org/grpc v1.80.0
	google.golang.org/protobuf v1.36.11
	kz/inflap/backend/pkg/natstransport v0.0.0
	kz/inflap/backend/pkg/serviceauth v0.0.0
	kz/inflap/backend/pkg/switches v0.0.0
	kz/inflap/backend/pkg/transportauth v0.0.0
	kz/inflap/proto v0.0.0-00010101000000-000000000000
)

require (
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/go-jose/go-jose/v4 v4.1.3 // indirect
	github.com/jackc/pgpassfile v1.0.0 // indirect
	github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
	github.com/jackc/puddle/v2 v2.2.2 // indirect
	github.com/klauspost/compress v1.18.5 // indirect
	github.com/mattn/go-colorable v0.1.14 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	github.com/nats-io/nkeys v0.4.15 // indirect
	github.com/nats-io/nuid v1.0.1 // indirect
	go.uber.org/atomic v1.11.0 // indirect
	golang.org/x/crypto v0.49.0 // indirect
	golang.org/x/net v0.51.0 // indirect
	golang.org/x/sync v0.20.0 // indirect
	golang.org/x/sys v0.42.0 // indirect
	golang.org/x/text v0.35.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20260120221211-b8f7ae30c516 // indirect
)

replace kz/inflap/proto => ../../../proto

replace kz/inflap/backend/pkg/natstransport => ../../pkg/natstransport

replace kz/inflap/backend/pkg/serviceauth => ../../pkg/serviceauth

replace kz/inflap/backend/pkg/switches => ../../pkg/switches

replace kz/inflap/backend/pkg/transportauth => ../../pkg/transportauth
