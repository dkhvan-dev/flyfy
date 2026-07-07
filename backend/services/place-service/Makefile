SERVICE_NAME=place-service

.PHONY: run build build-backfill-search-index backfill-search-index test tidy fmt vet docker-build proto-tidy

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
