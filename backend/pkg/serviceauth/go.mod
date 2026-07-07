module kz/inflap/backend/pkg/serviceauth

go 1.26

require (
	github.com/go-jose/go-jose/v4 v4.1.3
	google.golang.org/grpc v1.79.2
	google.golang.org/protobuf v1.36.10
	kz/inflap/backend/pkg/transportauth v0.0.0
	kz/inflap/proto v0.0.0-00010101000000-000000000000
)

require (
	golang.org/x/net v0.48.0 // indirect
	golang.org/x/sys v0.39.0 // indirect
	golang.org/x/text v0.32.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20251202230838-ff82c1b0f217 // indirect
)

replace kz/inflap/proto => ../../../proto

replace kz/inflap/backend/pkg/transportauth => ../transportauth
