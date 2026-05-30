module kz/inflap/backend/services/token-service

go 1.26

require (
	github.com/go-chi/chi/v5 v5.2.1
	github.com/go-jose/go-jose/v4 v4.1.3
	github.com/google/uuid v1.6.0
	github.com/jackc/pgx/v5 v5.7.4
	github.com/redis/go-redis/v9 v9.7.3
	github.com/rs/zerolog v1.33.0
	github.com/sethvargo/go-envconfig v1.1.1
	golang.org/x/crypto v0.46.0
	google.golang.org/grpc v1.79.2
	google.golang.org/protobuf v1.36.10
	kz/inflap/proto v0.0.0
)

require (
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/jackc/pgpassfile v1.0.0 // indirect
	github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
	github.com/jackc/puddle/v2 v2.2.2 // indirect
	github.com/mattn/go-colorable v0.1.13 // indirect
	github.com/mattn/go-isatty v0.0.19 // indirect
	github.com/stretchr/testify v1.11.1 // indirect
	golang.org/x/net v0.48.0 // indirect
	golang.org/x/sync v0.19.0 // indirect
	golang.org/x/sys v0.39.0 // indirect
	golang.org/x/text v0.32.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20251202230838-ff82c1b0f217 // indirect
)

replace kz/inflap/proto => ../../../proto
