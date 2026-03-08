module github.com/dkhvan-dev/flyfy/backend/services/token-service

go 1.26

require (
	github.com/dkhvan-dev/flyfy/proto v0.0.0
	github.com/go-chi/chi/v5 v5.2.1
	github.com/go-jose/go-jose/v4 v4.0.5
	github.com/google/uuid v1.6.0
	github.com/jackc/pgx/v5 v5.7.4
	github.com/redis/go-redis/v9 v9.7.3
	github.com/rs/zerolog v1.33.0
	github.com/sethvargo/go-envconfig v1.1.1
	golang.org/x/crypto v0.32.0
	google.golang.org/grpc v1.70.0
	google.golang.org/protobuf v1.36.5
)

require (
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/jackc/pgpassfile v1.0.0 // indirect
	github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
	github.com/jackc/puddle/v2 v2.2.2 // indirect
	github.com/mattn/go-colorable v0.1.13 // indirect
	github.com/mattn/go-isatty v0.0.19 // indirect
	go.opentelemetry.io/otel v1.34.0 // indirect
	golang.org/x/net v0.32.0 // indirect
	golang.org/x/sync v0.10.0 // indirect
	golang.org/x/sys v0.29.0 // indirect
	golang.org/x/text v0.21.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20241202173237-19429a94021a // indirect
)

replace github.com/dkhvan-dev/flyfy/proto => ../../../proto
