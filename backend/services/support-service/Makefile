SERVICE_NAME=support-service

.PHONY: run build build-backfill-search-index backfill-search-index test fmt vet docker-build

run:
	go run ./cmd

build:
	go build -o bin/$(SERVICE_NAME) ./cmd

build-backfill-search-index:
	go build -o bin/$(SERVICE_NAME)-backfill-search-index ./cmd/backfill-search-index

backfill-search-index:
	go run ./cmd/backfill-search-index

test:
	go test ./...

fmt:
	go fmt ./...

vet:
	go vet ./...

docker-build:
	docker build -f Dockerfile -t inflap/$(SERVICE_NAME):local .
