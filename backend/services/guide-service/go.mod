module kz/inflap/backend/services/guide-service

go 1.26

require (
	github.com/google/uuid v1.6.0
	github.com/jackc/pgx/v5 v5.8.0
	github.com/nats-io/nats.go v1.51.0
	github.com/rs/zerolog v1.34.0
	github.com/sethvargo/go-envconfig v1.3.0
	google.golang.org/grpc v1.79.2
	google.golang.org/protobuf v1.36.10
	kz/inflap/backend/pkg/natstransport v0.0.0
	kz/inflap/backend/pkg/serviceauth v0.0.0
	kz/inflap/backend/pkg/transportauth v0.0.0
	kz/inflap/proto v0.0.0-00010101000000-000000000000
)

require (
	github.com/go-jose/go-jose/v4 v4.1.3 // indirect
	github.com/jackc/pgpassfile v1.0.0 // indirect
	github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
	github.com/jackc/puddle/v2 v2.2.2 // indirect
	github.com/klauspost/compress v1.18.5 // indirect
	github.com/mattn/go-colorable v0.1.13 // indirect
	github.com/mattn/go-isatty v0.0.19 // indirect
	github.com/nats-io/nkeys v0.4.15 // indirect
	github.com/nats-io/nuid v1.0.1 // indirect
	golang.org/x/crypto v0.49.0 // indirect
	golang.org/x/net v0.51.0 // indirect
	golang.org/x/sync v0.20.0 // indirect
	golang.org/x/sys v0.42.0 // indirect
	golang.org/x/text v0.35.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20251202230838-ff82c1b0f217 // indirect
)

replace kz/inflap/proto => ../../../proto

replace kz/inflap/backend/pkg/natstransport => ../../pkg/natstransport

replace kz/inflap/backend/pkg/serviceauth => ../../pkg/serviceauth

replace kz/inflap/backend/pkg/transportauth => ../../pkg/transportauth
