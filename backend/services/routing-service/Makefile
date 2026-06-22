SERVICE_NAME=routing-service

.PHONY: run build test fmt vet tidy docker-build

run:
	GOWORK=off go run ./cmd

build:
	GOWORK=off go build -o bin/$(SERVICE_NAME) ./cmd

test:
	GOWORK=off go test ./...

fmt:
	go fmt ./...

vet:
	GOWORK=off go vet ./...

tidy:
	GOWORK=off go mod tidy

docker-build:
	docker build -t $(SERVICE_NAME):local -f Dockerfile ../../../
