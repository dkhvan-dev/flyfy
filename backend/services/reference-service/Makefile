SERVICE_NAME=reference-service

.PHONY: run build test fmt vet tidy docker-build

run:
	go run ./cmd

build:
	go build -o bin/$(SERVICE_NAME) ./cmd

test:
	go test ./...

fmt:
	go fmt ./...

vet:
	go vet ./...

tidy:
	go mod tidy

docker-build:
	docker build -t $(SERVICE_NAME):local -f Dockerfile ../../../
