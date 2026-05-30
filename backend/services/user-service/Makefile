SERVICE_NAME=user-service
PROTO_MODULE=kz/inflap/proto

.PHONY: run build test tidy fmt vet docker-build

run:
	go run ./cmd

build:
	go build -o bin/$(SERVICE_NAME) ./cmd

test:
	go test ./...

tidy:
	go mod tidy

fmt:
	go fmt ./...

vet:
	go vet ./...

docker-build:
	docker build -t $(SERVICE_NAME):local -f Dockerfile .

proto-tidy:
	cd ../../../proto && go mod tidy