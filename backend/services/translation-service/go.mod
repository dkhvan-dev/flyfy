module kz/inflap/backend/services/translation-service

go 1.26

require (
	github.com/jackc/pgx/v5 v5.8.0
	github.com/rs/zerolog v1.35.1
	github.com/sethvargo/go-envconfig v1.3.0
	kz/inflap/backend/pkg/serviceauth v0.0.0-00010101000000-000000000000
	kz/inflap/backend/pkg/transportauth v0.0.0
)

require (
	github.com/go-jose/go-jose/v4 v4.1.3 // indirect
	github.com/jackc/pgpassfile v1.0.0 // indirect
	github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
	github.com/jackc/puddle/v2 v2.2.2 // indirect
	github.com/mattn/go-colorable v0.1.14 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	golang.org/x/net v0.48.0 // indirect
	golang.org/x/sync v0.19.0 // indirect
	golang.org/x/sys v0.39.0 // indirect
	golang.org/x/text v0.32.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20251202230838-ff82c1b0f217 // indirect
	google.golang.org/grpc v1.79.2 // indirect
	google.golang.org/protobuf v1.36.10 // indirect
	kz/inflap/proto v0.0.0-00010101000000-000000000000 // indirect
)

replace kz/inflap/backend/pkg/transportauth => ../../pkg/transportauth

replace kz/inflap/backend/pkg/serviceauth => ../../pkg/serviceauth

replace kz/inflap/proto => ../../../proto
