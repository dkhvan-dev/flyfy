SERVICE_NAME=excursion-service

.PHONY: run build build-backfill-search-index backfill-search-index test tidy fmt vet docker-build

run:
	go run ./cmd

build:
	go build -o bin/$(SERVICE_NAME) ./cmd

build-backfill-search-index:
	go build -o bin/$(SERVICE_NAME)-backfill-search-index ./cmd/backfill-search-index

backfill-search-index:
	go run ./cmd/backfill-search-index

test:
	GOWORK=off go test ./...

tidy:
	GOWORK=off go mod tidy

fmt:
	go fmt ./...

vet:
	GOWORK=off go vet ./...
	
docker-build:
	docker build -t $(SERVICE_NAME):local -f Dockerfile ../../..
