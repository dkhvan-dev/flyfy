SERVICE_NAME=translation-service

.PHONY: run build test fmt vet docker-build

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

docker-build:
	docker build -f Dockerfile -t inflap/$(SERVICE_NAME):local .
